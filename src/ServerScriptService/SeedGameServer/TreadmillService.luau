--!strict
-- Steal a Seed :: TreadmillService
--
-- THE FAUCET FOR SPEED. The same shape as EconomyService is for cash: this is
-- the only thing in the game that calls PlayerDataService.AddSpeed.
--
--==============================================================================
-- AND IT NEVER WRITES WalkSpeed
--
-- CarryService owns that property outright. This raises the Speed SCORE and
-- then asks CarryService to recompute, because WalkSpeed is the product of two
-- things -- the score and what you are carrying -- and a service that knows
-- only one of them will write the wrong number every time it is holding a pod.
--
--     Speed score  ->  GameConfig.walkSpeedFor  ->  x carry multiplier  ->  WalkSpeed
--                                                   ^ CarryService owns this whole line
--
--==============================================================================
-- OCCUPANCY IS ENOUGH. YOU DO NOT HAVE TO HOLD W.
--
-- Standing on the belt pays. Making the player hold a key to earn the slow
-- floor rate turns a background activity into a chore, and a chore is what
-- people auto-click rather than play around.
--
-- Tested by TRANSFORMING the root into the belt's own frame rather than by
-- Touched: the belt is a static part a player can stand on for ten minutes
-- without ever firing Touched again after the first frame, and a region check
-- is also immune to standing on somebody's head above it.
--
--==============================================================================
-- YOUR MILL, NOT THE NEAREST ONE
--
-- Matched on the PlotId the map already stamps on both the plot and the
-- treadmill. Six mills sit in a ring and the walk between two of them is short;
-- without this, the person whose plot you are standing next to pays for your
-- training.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local MILL = GameConfig.Treadmill
local LADDER = GameConfig.Mill
local ATTR = GameConfig.Attributes

local TreadmillService = {}
-- After CarryService (45), whose RefreshWalkSpeed this calls.
TreadmillService.Priority = 60

local TICK = MILL.TickSeconds
-- How far above the belt's top face still counts as standing on it. A root sits
-- about three studs up; the ceiling is generous enough for a jump and mean
-- enough to exclude somebody on the handrail.
local STAND_HEIGHT = 6.5
-- Lets a player earn while their toes are over the edge.
local EDGE_MARGIN = 1.2

local lastPaid: { [Player]: number } = {}
local granted: { [Player]: number } = {}

--==============================================================================
-- MOUNTING, WHICH IS THE OTHER HALF OF OCCUPANCY
--
-- The region test below answers "is this player on the belt right now". That is
-- the right question for PAYING and the wrong one for CATCHING: a player at 90
-- WalkSpeed crosses the whole deck between two ticks, so the faster they get the
-- harder their own mill is to stand on. Which is backwards -- speed is the thing
-- the mill SELLS, and buying more of it should not make the shop harder to reach.
--
-- So ENTRY is a Touched and OCCUPANCY stays a region test. The note at the top
-- of this file is about Touched being useless for occupancy -- a static part you
-- are standing on stops firing after the first frame -- and that is precisely
-- what makes it right here. It fires on ARRIVAL, once, however fast you arrived.
--
-- Mounting parks the player: zero WalkSpeed (asked of CarryService, never
-- written here) in the middle of their own belt, facing the console. Jump is
-- left completely alone, so the way off is the button every Roblox player
-- already presses without being told there is one.
--==============================================================================
--==============================================================================
-- THE REMOTE, AT FILE SCOPE
--
-- `bindSign` is written above Start() and closes over this, so it cannot be the
-- local Start() resolves -- a name referenced before its `local` is a GLOBAL in
-- Luau, and a global that is always nil is a refusal that never reaches anybody.
--==============================================================================
local upgradeChannel: RemoteEvent? = nil

local mounted: { [Player]: BasePart } = {}
local mountConns: { [Player]: { RBXScriptConnection } } = {}
--==============================================================================
-- AND A DISMOUNT HAS TO SURVIVE THE LANDING
--
-- You jump off the belt and land back on the belt. That is a fresh Touched, and
-- without this you are remounted before you are upright again -- a dismount
-- button that cannot dismount. Set on unmount, cleared only once the player is
-- genuinely off the thing.
--==============================================================================
local mountBlocked: { [Player]: boolean } = {}
local running = false
local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/TreadmillService] " .. message)
end

--==============================================================================
-- FINDING THE BELTS
--==============================================================================
local function beltFor(plotId: number): BasePart?
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") and belt.Parent then
			local id = belt.Parent:GetAttribute(ATTR.PlotId)
			if id == plotId then
				return belt
			end
		end
	end
	return nil
end

local function ownBeltOf(player: Player): BasePart?
	local plot = PlotService.PlotOf(player)
	local plotId = plot and plot:GetAttribute(ATTR.PlotId)
	return if type(plotId) == "number" then beltFor(plotId) else nil
end

local function standingOn(root: BasePart, belt: BasePart): boolean
	-- Into the belt's own frame, so a rotated mill is no different from an
	-- axis-aligned one. Six of these sit in a ring and every one is rotated.
	local local_ = belt.CFrame:PointToObjectSpace(root.Position)
	local half = belt.Size * 0.5
	if math.abs(local_.X) > half.X + EDGE_MARGIN then
		return false
	end
	if math.abs(local_.Z) > half.Z + EDGE_MARGIN then
		return false
	end
	local above = local_.Y - half.Y
	return above > -1 and above < STAND_HEIGHT
end

--==============================================================================
-- WHO IS EARNING, AND HOW FAST
--==============================================================================
function TreadmillService.RateFor(player: Player): number
	if not PlayerDataService.IsReady(player) then
		return 0
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	-- Alive. A ragdolled or dead player on the belt is not training.
	if not (humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")) then
		return 0
	end
	local plot = PlotService.PlotOf(player)
	if not plot or PlotService.OwnerOf(plot) ~= player then
		return 0
	end
	local plotId = plot:GetAttribute(ATTR.PlotId)
	if type(plotId) ~= "number" then
		return 0
	end
	local belt = beltFor(plotId)
	if not belt or not standingOn(root :: BasePart, belt) then
		return 0
	end
	return TreadmillService.RateForTier(TreadmillService.TierOf(player))
end

--==============================================================================
-- WHAT A TIER PAYS, AND WHICH TIER SOMEBODY HAS
--
-- Both read straight off the profile, which is the only place a mill tier
-- exists. There is no per-plot cache to go stale, and a player with no profile
-- yet is tier one rather than an error.
--==============================================================================
function TreadmillService.TierOf(player: Player): number
	local profile = PlayerDataService.Get(player)
	local tier = profile and tonumber(profile.MillTier) or LADDER.StartingTier
	return math.clamp(math.floor(tier), 1, #LADDER.Tiers)
end

function TreadmillService.RateForTier(tier: number): number
	local spec = LADDER.Tiers[math.clamp(math.floor(tier), 1, #LADDER.Tiers)]
	return if spec then spec.speed else MILL.SpeedPerSecond
end

--==============================================================================
-- HOW FAST THE SURFACE IS TRAVELLING
--
-- One number on the belt, and it is the whole of the feet problem. Ambience
-- scrolls the chevrons at it, spins the rollers off it, and SpeedFX divides it
-- by the sixteen studs a second Roblox authors its run cycle for to get the
-- animation speed. Belt and legs cannot disagree because there is only one
-- number for them to disagree about.
--
-- Set on a state CHANGE, not per tick: it is an attribute, and an attribute
-- written sixty times a second to six belts is replication for nothing.
--==============================================================================
local function setBeltSpeed(belt: BasePart, occupied: boolean, tier: number)
	local spec = LADDER.Tiers[math.clamp(tier, 1, #LADDER.Tiers)]
	local want = if occupied then (spec and spec.beltStuds or 13) else LADDER.IdleStuds
	if belt:GetAttribute("BeltSpeed") ~= want then
		belt:SetAttribute("BeltSpeed", want)
	end
end

--==============================================================================
-- GETTING ON AND GETTING OFF
--==============================================================================
function TreadmillService.Unmount(player: Player)
	if not mounted[player] then
		return
	end
	mounted[player] = nil
	for _, c in ipairs(mountConns[player] or {}) do
		c:Disconnect()
	end
	mountConns[player] = nil
	mountBlocked[player] = true
	player:SetAttribute(ATTR.MillMounted, nil)
	CarryService.RefreshWalkSpeed(player)
end

function TreadmillService.Mount(player: Player, belt: BasePart): boolean
	if mounted[player] or mountBlocked[player] then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootInstance = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and rootInstance and rootInstance:IsA("BasePart")) then
		return false
	end
	local root = rootInstance :: BasePart
	if humanoid.Health <= 0 then
		return false
	end

	mounted[player] = belt
	player:SetAttribute(ATTR.MillMounted, true)

	--==========================================================================
	-- STOOD IN THE MIDDLE, FACING THE CONSOLE
	--
	-- LookVector is a CFrame's -Z, and the console is at -Z in the mill's own
	-- frame -- so this is "face the instruments" without this service having to
	-- know which way any of the six mills in the ring is pointing.
	--
	-- The velocity is zeroed as well as the position. A player caught at a
	-- sprint still has that momentum in the assembly, and without this they are
	-- placed in the middle and immediately slide out of it.
	--==========================================================================
	local lift = belt.Size.Y * 0.5 + humanoid.HipHeight + root.Size.Y * 0.5
	local stand = belt.Position + Vector3.new(0, lift, 0)
	root.CFrame = CFrame.lookAt(stand, stand + belt.CFrame.LookVector)
	root.AssemblyLinearVelocity = Vector3.zero

	--==========================================================================
	-- ON THE BELT, NOT IN THE EAR
	--
	-- Positional and audible off the plot, because being caught by a mill is a
	-- thing that happens TO A PLACE. A 2D thump would tell the mounted player
	-- something they can already see and tell everybody else nothing.
	--==========================================================================
	SoundKit.emit("MillMount", belt)

	CarryService.RefreshWalkSpeed(player)

	local conns: { RBXScriptConnection } = {}
	table.insert(conns, humanoid.Jumping:Connect(function(active: boolean)
		if active then
			TreadmillService.Unmount(player)
		end
	end))
	table.insert(conns, humanoid.Died:Connect(function()
		TreadmillService.Unmount(player)
	end))
	mountConns[player] = conns
	return true
end

local function bindBelt(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local belt = instance :: BasePart
	table.insert(serviceConnections, belt.Touched:Connect(function(hit: BasePart)
		if not running then
			return
		end
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if not player then
			return
		end
		-- Your mill, not the nearest one. Same rule as the payout, for the same
		-- reason: six of these sit in a ring and the walk between two is short.
		if ownBeltOf(player) ~= belt then
			return
		end
		TreadmillService.Mount(player, belt)
	end))
end

--==============================================================================
-- THE TICK
--==============================================================================
local function payEveryone()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		--==================================================================
		-- Cheap because it only runs for somebody who just got off: one
		-- region test until they step clear, then never again.
		--==================================================================
		if mountBlocked[player] then
			local belt = ownBeltOf(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local still = belt ~= nil
				and root ~= nil
				and root:IsA("BasePart")
				and standingOn(root :: BasePart, belt :: BasePart)
			if not still then
				mountBlocked[player] = nil
			end
		end
		local rate = TreadmillService.RateFor(player)
		-- ON THE PLAYER, so it replicates to everybody. That is what lets each
		-- client play the run cycle on somebody else's character, and it is why
		-- this needs no remote.
		local on = rate > 0
		if (player:GetAttribute(ATTR.OnTreadmill) == true) ~= on then
			player:SetAttribute(ATTR.OnTreadmill, on or nil)
			--==============================================================
			-- THE BELT SPEEDS UP WHEN SOMEBODY IS ON IT
			--
			-- Written HERE, inside the state-change branch, so it costs one
			-- attribute write per step-on and one per step-off rather than
			-- one per tick per belt. Everything that moves on a mill reads
			-- this one number.
			--==============================================================
			local plot = PlotService.PlotOf(player)
			local plotId = plot and plot:GetAttribute(ATTR.PlotId)
			local belt = if type(plotId) == "number" then beltFor(plotId) else nil
			if belt then
				setBeltSpeed(belt, on, TreadmillService.TierOf(player))
			end
		end
		if rate > 0 then
			local since = lastPaid[player]
			lastPaid[player] = now
			if since then
				local dt = now - since
				-- Same hitch rule as the cash faucet: pay for time actually
				-- elapsed, but never a lump for a gap this long -- that gap
				-- means they stepped off and came back.
				if dt > 0 and dt < 30 then
					if PlayerDataService.AddSpeed(player, rate * dt) then
						granted[player] = (granted[player] or 0) + rate * dt
						-- CarryService owns WalkSpeed. Ask, do not write.
						CarryService.RefreshWalkSpeed(player)
					end
				end
			end
		else
			-- Off the belt. Clearing this is what stops a player who wandered
			-- away for a minute from being paid for the minute when they
			-- step back on.
			lastPaid[player] = nil
		end
	end
end

local function forget(player: Player)
	TreadmillService.Unmount(player)
	-- After the unmount, which sets it.
	mountBlocked[player] = nil
	mounted[player] = nil
	mountConns[player] = nil
	lastPaid[player] = nil
	granted[player] = nil
end

--==============================================================================
-- THE MILL A PLOT IS WEARING
--
-- MapService puts one on every plot at the starting tier, because it also runs
-- in Edit where nobody owns anything. The moment a plot is claimed -- and every
-- time its owner buys a step -- the geometry is thrown away and rebuilt at the
-- tier the profile says.
--
-- REBUILT, NOT PATCHED. Rule 10: the tiers differ in materials, in colours and
-- in which ornaments exist at all, and a function that tried to morph one into
-- another would be seven times the code and wrong the first time an ornament
-- was added. The mill is cheap to build; it is built again.
--==============================================================================
local function millModelFor(plotId: number): Model?
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		local model = belt.Parent
		if model and model:IsA("Model") and model:GetAttribute(ATTR.PlotId) == plotId then
			return model
		end
	end
	return nil
end

local function signFor(plotId: number): Model?
	for _, sign in ipairs(CollectionService:GetTagged(GameConfig.Tags.MillSign)) do
		if sign:IsA("Model") and sign:GetAttribute(ATTR.PlotId) == plotId then
			return sign
		end
	end
	return nil
end

--==============================================================================
-- WHAT THE BOARD SAYS
--
-- Current step, what it costs, and both rates -- because "Level 3 to Level 4"
-- means nothing on its own and the only question a player is actually asking is
-- how much faster it goes.
--
-- At the top there is no next step and no price. The button does not sit there
-- greyed out inviting a press: it says MAX and stops being a button, which is
-- the same rule the shop's SOON follows for the opposite reason.
--==============================================================================
--==============================================================================
-- WHOSE MILL IS THIS, AND WHAT TIER IS IT
--
-- Resolved from the plot rather than passed in, because the two callers cannot
-- both know: a rebuild knows the tier it just built, but the tag signal that
-- fires when a rebuilt sign appears knows only that a sign appeared.
--
-- That mattered. The rebuild refreshed the board and then CollectionService
-- delivered the added-signal a frame later, which refreshed it again at the
-- STARTING tier -- so a tier-7 mill sat beside a board still offering level 1
-- for ten thousand.
--==============================================================================
local function tierOnPlot(plotId: number): number
	for _, plot in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if plot:IsA("Model") and plot:GetAttribute(ATTR.PlotId) == plotId then
			local owner = PlotService.OwnerOf(plot)
			if owner then
				return TreadmillService.TierOf(owner)
			end
		end
	end
	return LADDER.StartingTier
end

local function refreshSign(plotId: number, tier: number)
	local sign = signFor(plotId)
	if not sign then
		return
	end
	local board = sign:FindFirstChild("Board")
	local face = board and board:FindFirstChild("Face")
	if not face then
		return
	end
	local step = face:FindFirstChild("Step") :: TextLabel?
	local rate = face:FindFirstChild("Rate") :: TextLabel?
	local buy = face:FindFirstChild("Buy") :: Frame?
	local price = buy and buy:FindFirstChild("Price") :: TextLabel?
	local prompt = board:FindFirstChildOfClass("ProximityPrompt")

	local here = LADDER.Tiers[tier]
	local next_ = LADDER.Tiers[tier + 1]

	if step then
		step.Text = if next_
			then string.format("LEVEL %d  >  LEVEL %d", tier, tier + 1)
			else string.format("LEVEL %d", tier)
	end
	if rate then
		rate.Text = if next_
			then string.format("%g/s  >  %g/s", here.speed, next_.speed)
			else string.format("%s  ·  %g/s", string.upper(here.name), here.speed)
	end
	if price then
		price.Text = if next_
			then "$" .. GameConfig.compact(next_.cost)
			else "MAX"
	end
	if buy then
		buy.BackgroundColor3 = if next_
			then Color3.fromRGB(214, 78, 66)
			else Color3.fromRGB(96, 100, 108)
	end
	if prompt then
		prompt.Enabled = next_ ~= nil
		prompt.ObjectText = here.name
	end
end

function TreadmillService.Rebuild(plot: Model, tier: number)
	local plotId = plot:GetAttribute(ATTR.PlotId)
	if type(plotId) ~= "number" then
		return
	end
	local existing = millModelFor(plotId)
	if not existing then
		return
	end
	local cf = existing:GetPivot()
	local parent = existing.Parent
	local sign = signFor(plotId)
	local signCF = sign and sign:GetPivot()
	existing:Destroy()

	local model, belt = MillModel.Build(tier, cf, parent)
	model.Name = string.format("%s%02d", GameConfig.Plot.TreadmillName, plotId)
	model:SetAttribute(ATTR.PlotId, plotId)
	CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)
	setBeltSpeed(belt, false, tier)

	-- The sign was inside the model, so it went with it. Same place, new board.
	local rebuiltSign = MillModel.BuildSign(
		signCF or (cf * CFrame.new(8.6, -0.6, -6)), model)
	rebuiltSign:SetAttribute(ATTR.PlotId, plotId)
	-- Deferred, so it lands after the tag signal that fires when the sign above
	-- appears. Both refresh from the profile now, so the order stopped mattering
	-- -- this just makes the last word the right one.
	task.defer(refreshSign, plotId, tier)
end

--==============================================================================
-- BUYING A STEP
--
-- Rule 3: the server owns the economy, so everything the client sends is a
-- claim. It sends nothing but the verb -- not a tier, not a price -- because
-- the only mill it could possibly be upgrading is the one on its own plot, and
-- both of those facts are things this side already knows.
--
-- Charged before it is built. If the cash is not there the mill does not
-- change; if the build somehow failed the player has still been charged, which
-- is why the build is last and cannot fail -- it is the same call the map makes
-- six times at boot.
--==============================================================================
function TreadmillService.Upgrade(player: Player): boolean
	if not PlayerDataService.IsReady(player) then
		return false
	end
	local plot = PlotService.PlotOf(player)
	if not plot or PlotService.OwnerOf(plot) ~= player then
		return false
	end
	local plotId = plot:GetAttribute(ATTR.PlotId)
	if type(plotId) ~= "number" then
		return false
	end
	local tier = TreadmillService.TierOf(player)
	local next_ = LADDER.Tiers[tier + 1]
	if not next_ then
		return false
	end
	local profile = PlayerDataService.Get(player)
	if not profile or profile.Cash < next_.cost then
		return false
	end
	if not PlayerDataService.AddCash(player, -next_.cost) then
		return false
	end
	if not PlayerDataService.SetMillTier(player, tier + 1) then
		-- Paid and not upgraded is the one outcome that must not stand.
		PlayerDataService.AddCash(player, next_.cost)
		return false
	end
	TreadmillService.Rebuild(plot, tier + 1)
	--==========================================================================
	-- THE WHOLE ROAD HEARS IT
	--
	-- On the new belt rather than on the buyer, and with the longest range of
	-- any cue in the game. A neighbour buying tier 6 is the most persuasive
	-- advertisement this game has and it costs nothing to let them hear it.
	--
	-- After the rebuild, because the mill it plays on is the one that was just
	-- built -- the old belt was destroyed two lines up and a Sound parented to it
	-- would go with it.
	--==========================================================================
	local newBelt = beltFor(plotId)
	if newBelt then
		SoundKit.emit("MillUpgrade", newBelt)
	end
	log(string.format("%s upgraded their mill to %d (%s, %g/s) for %d.",
		player.Name, tier + 1, next_.name, next_.speed, next_.cost))
	return true
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function TreadmillService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(lastPaid)
	table.clear(granted)
	table.clear(mounted)
	table.clear(mountBlocked)
	for _, conns in pairs(mountConns) do
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
	end
	table.clear(mountConns)
	-- Nobody is on a belt across a restart, and a stale attribute would leave a
	-- character running on the spot forever.
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute(ATTR.OnTreadmill, nil)
		-- Same reason: a stale mount would leave somebody parked at zero
		-- WalkSpeed across a restart with nothing left to release them.
		player:SetAttribute(ATTR.MillMounted, nil)
	end
end

function TreadmillService.Start()
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(forget))

	local mills = 0
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") then
			setBeltSpeed(belt, false, LADDER.StartingTier)
			bindBelt(belt)
			mills += 1
		end
	end
	--==========================================================================
	-- AND EVERY BELT BUILT AFTER THIS POINT
	--
	-- An upgrade destroys the mill and builds a new one, so the belt a player
	-- mounts is rarely the one that existed at startup. Binding only the
	-- starting six would mean the mount worked until the first time somebody
	-- bought something -- which is the worst possible moment to stop working.
	--==========================================================================
	table.insert(serviceConnections, CollectionService
		:GetInstanceAddedSignal(GameConfig.Tags.Treadmill)
		:Connect(bindBelt))

	--==========================================================================
	-- A RESPAWN IS A DISMOUNT
	--
	-- Died covers dying on the belt. This covers everything else that replaces a
	-- character -- /reset, a teleport, a manual LoadCharacter -- where the old
	-- humanoid's connections go with it and nothing would ever clear the flag.
	--==========================================================================
	local function watchRespawn(player: Player)
		table.insert(serviceConnections, player.CharacterRemoving:Connect(function()
			TreadmillService.Unmount(player)
			mountBlocked[player] = nil
		end))
	end
	for _, player in ipairs(Players:GetPlayers()) do
		watchRespawn(player)
	end
	table.insert(serviceConnections, Players.PlayerAdded:Connect(watchRespawn))

	--==========================================================================
	-- A CLAIMED PLOT GETS ITS OWNER'S MILL
	--
	-- The map built a starting one because it does not know who anybody is.
	-- This is where it finds out.
	--==========================================================================
	table.insert(serviceConnections, PlotService.OnAssigned(function(player, plot)
		local plotId = plot:GetAttribute(ATTR.PlotId)
		if type(plotId) ~= "number" then
			return
		end
		--======================================================================
		-- WAIT FOR THE PROFILE, OR BUILD THE WRONG MILL
		--
		-- A plot is handed out the moment somebody joins; the save is a
		-- DataStore round trip that finishes a second or two later. Reading the
		-- tier straight away therefore found no profile at all and quietly
		-- answered "tier 1" -- so a player who owned a Heartroot rejoined to a
		-- Compost Walk, and the sign offered to sell them level 2 again.
		--
		-- Same wait, same deadline and same reason as the one PlantService uses
		-- before it restores a bed.
		--======================================================================
		task.spawn(function()
			local deadline = os.clock() + 20
			while not PlayerDataService.IsReady(player) and os.clock() < deadline do
				task.wait(0.25)
			end
			if player.Parent ~= Players or PlotService.OwnerOf(plot) ~= player then
				return
			end
			local tier = TreadmillService.TierOf(player)
			if tier ~= LADDER.StartingTier then
				TreadmillService.Rebuild(plot, tier)
			else
				refreshSign(plotId, tier)
			end
		end)
	end))

	--==========================================================================
	-- THE SIGN IS THE PRIMARY WAY IN
	--
	-- A ProximityPrompt fires Triggered on the SERVER with the player who
	-- pressed it, so the world sign needs no remote at all -- and Style Custom
	-- means PromptUI draws it, which is what makes it a thumb-sized target on a
	-- phone rather than a keyboard hint.
	--
	-- Bound by tag so a rebuilt sign is picked up without anybody remembering
	-- to rebind it.
	--==========================================================================
	local function bindSign(instance: Instance)
		if not instance:IsA("Model") then
			return
		end
		local board = instance:FindFirstChild("Board")
		local prompt = board and board:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			return
		end
		table.insert(serviceConnections, prompt.Triggered:Connect(function(player)
			--==============================================================
			-- A REFUSAL IS THE ONE THING THE SIGN CANNOT SAY BY ITSELF
			--
			-- Success needs no message: the mill is rebuilt in front of you,
			-- the sign repaints, and MillUpgrade plays off the new belt. A
			-- REFUSAL changes nothing at all on screen, so holding a prompt
			-- with $40 short is indistinguishable from holding a prompt that
			-- is broken.
			--
			-- Sent back down the GameEvent remote that already exists and
			-- already carries this verb, as the verb plus false. Not a new
			-- remote, and not a reason -- the client is told that it did not
			-- happen, which is all it needs to make a noise about.
			--==============================================================
			if not TreadmillService.Upgrade(player) and upgradeChannel then
				upgradeChannel:FireClient(player, LADDER.Action, false)
			end
		end))
		local plotId = instance:GetAttribute(ATTR.PlotId)
		if type(plotId) == "number" then
			refreshSign(plotId, tierOnPlot(plotId))
		end
	end

	for _, sign in ipairs(CollectionService:GetTagged(GameConfig.Tags.MillSign)) do
		bindSign(sign)
	end
	table.insert(serviceConnections,
		CollectionService:GetInstanceAddedSignal(GameConfig.Tags.MillSign):Connect(bindSign))

	--==========================================================================
	-- THE ONE THING A CLIENT MAY ASK FOR
	--
	-- Same remote and the same shape of validation as PlantAt and PickUp: a verb
	-- and nothing else worth trusting.
	--==========================================================================
	local remotes = ReplicatedStorage:WaitForChild("SeedGame"):FindFirstChild("Remotes")
	local channel = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if channel and channel:IsA("RemoteEvent") then
		upgradeChannel = channel
		table.insert(serviceConnections, channel.OnServerEvent:Connect(
			function(player: Player, action: any)
				if action == LADDER.Action then
					TreadmillService.Upgrade(player)
				end
			end))
	else
		warn("[Seed/TreadmillService] No GameEvent remote. Mills cannot be upgraded.")
	end

	running = true
	task.spawn(function()
		while running do
			task.wait(TICK)
			local ok, err = pcall(payEveryone)
			if not ok then
				warn("[Seed/TreadmillService] pay tick failed: " .. tostring(err))
			end
		end
	end)

	log(string.format(
		"Ready. The only faucet for Speed. %d mill(s), %d tiers, +%g/sec at tier 1 up to +%g/sec at tier %d.",
		mills, #LADDER.Tiers, LADDER.Tiers[1].speed,
		LADDER.Tiers[#LADDER.Tiers].speed, #LADDER.Tiers))
end

function TreadmillService.Snapshot(): string
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		table.insert(rows, string.format("%s: %s, Speed %.0f (+%.0f this session)",
			player.Name,
			if TreadmillService.RateFor(player) > 0 then "ON the belt" else "off",
			profile and profile.Speed or 0, granted[player] or 0))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nobody training"
end

return TreadmillService
