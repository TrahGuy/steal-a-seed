--!strict
-- Steal a Seed :: TreadmillService
--
-- THE FAUCET FOR SPEED. The same shape as EconomyService is for cash: every
-- Speed a player earns or buys goes through here -- the belt, the Biome Harvest
-- and a Robux Speed pack, the last two by PayReward. The debug console is the
-- one other caller of PlayerDataService.AddSpeed, and it is exempt by design.
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
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local BonusChestService = require(script.Parent:WaitForChild("BonusChestService"))
-- Sprout Dash's own training boost (2026-10-08), added to the chest's below.
local SproutDash = require(Shared:WaitForChild("SproutDash"))

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
-- ONE RATE (2026-10-05, the owner's ask)
--
-- The mill used to carry a TRAINING RUSH: a rested charge that paid up to 4x
-- while it lasted, climbed to it over thirty seconds, refilled off the belt and
-- dropped back to the base rate when it ran out. It is gone from the payout,
-- not only from the screen. A belt pays the mill's own rate -- tier and
-- rebirth -- times the boosts that are still real (the Bonus Chest's training
-- reward, the Disco Mill's x10), the same every tick: fresh or rested, on the
-- first tick or the hundredth, after stepping off, a respawn or a rejoin.
-- Nothing is charged, refilled, published or saved for it, and the charge an
-- old record still carries is dropped by ProfileSchema without ever being read.
--==============================================================================

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
--==============================================================================
-- THE DISCO MILL'S STATE (2026-10-04; see THE DISCO MILL below)
--==============================================================================
local DISCO = GameConfig.MiniEvent.DiscoMill
local EVENT = GameConfig.MiniEvent.Attributes
local EVENT_MODES: { [string]: any } = GameConfig.MiniEvent.Modes :: any
type Disco = { model: Model?, belt: BasePart?, eventId: string? }
local disco: Disco = { model = nil, belt = nil, eventId = nil }
local discoConns: { RBXScriptConnection } = {}
-- The spot (an index into DISCO.Spots) each player mounted on it stands on.
local discoSpot: { [Player]: number } = {}
-- Where each player was paid last tick: "own", "disco" or nil. Their own belt
-- spins only while they run on IT.
local paidOn: { [Player]: string } = {}
local fullToldAt: { [Player]: number } = {}
local serviceConnections: { RBXScriptConnection } = {}
-- PlotService.OnReleased hands back an unsubscribe function, not a connection,
-- so it is kept apart from the connections Init disconnects.
local releaseHook: (() -> ())? = nil

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

-- Over the belt at ANY height above it: what a dismount's block waits out. A
-- jump straight up rises 7.3 studs, past STAND_HEIGHT, so standingOn called the
-- top of the jump "off"; a 1 s tick that fell in that ~0.4 s cleared the block
-- and the landing's Touched remounted -- a dismount that did not stick (Play,
-- 2026-10-08: MillMounted nil at take-off, true again 0.67 s later). Off is off
-- the footprint, or below the belt.
local function overBelt(root: BasePart, belt: BasePart): boolean
	local local_ = belt.CFrame:PointToObjectSpace(root.Position)
	local half = belt.Size * 0.5
	return math.abs(local_.X) <= half.X + EDGE_MARGIN and math.abs(local_.Z) <= half.Z + EDGE_MARGIN
		and local_.Y - half.Y > -1
end

--==============================================================================
-- THE DISCO MILL, AS THE PAYOUT SEES IT (2026-10-04)
--
-- Up only while the mini event that built it is still RUNNING, in a disco
-- mode, with the same id: the moment it starts ending, or another event takes
-- its place, nobody on it is paid. Mounted only -- on a spot of their own --
-- and standing on its belt.
--==============================================================================
local function discoWanted(): string?
	if not DISCO.Enabled or Workspace:GetAttribute(EVENT.State) ~= "running" then
		return nil
	end
	-- A mode with a MILL (Ticket Disco, DISCO + MILL): the pure DISCO ONLY has
	-- the disco but no mill (2026-10-04), and Ticket Shower Only neither.
	local mode = EVENT_MODES[Workspace:GetAttribute(EVENT.Mode) or ""]
	if not (mode and mode.Mill == true) then
		return nil
	end
	local id = Workspace:GetAttribute(EVENT.EventId)
	return if type(id) == "string" and id ~= "" then id else nil
end

local function discoLive(): boolean
	local id = disco.eventId
	return disco.belt ~= nil and id ~= nil and discoWanted() == id
end

-- Riding their own mill: mounted, and not on the Disco Mill (Sprout Dash's
-- rule, 2026-10-08: a run counts only here, start to end).
function TreadmillService.OnOwnMill(player: Player): boolean
	return mounted[player] ~= nil and discoSpot[player] == nil
end

function TreadmillService.OnDiscoMill(player: Player): boolean
	local belt = disco.belt
	if not (belt and discoSpot[player] and mounted[player] == belt and discoLive()) then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and standingOn(root :: BasePart, belt)
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
	-- On the Disco Mill: their OWN rate, whoever's plot is nearest. Its x10 is
	-- not here but on the payout line, the one place it is composed.
	if TreadmillService.OnDiscoMill(player) then
		return TreadmillService.RateOf(player)
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
	return TreadmillService.RateOf(player)
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
-- THE RATE IS A PRODUCT, AND GameConfig OWNS THE PRODUCT
--
--     tier.speed  x  rebirth
--
-- Computed in GameConfig rather than here because the mill SIGN has to print
-- the same number the payout pays, and a rate derived in two places is a sign
-- that lies the first time either half is touched. (An overclock factor sat
-- between the two until 2026-10-06; tiers 11-14 replaced it.)
--==============================================================================
function TreadmillService.RateOf(player: Player): number
	return GameConfig.trainingRateFor(TreadmillService.TierOf(player), PlayerDataService.Get(player))
end

--==============================================================================
-- WHICH STEP IS NEXT, AND WHAT IT COSTS
--
-- Two answers, which is all the sign has to say: the ladder is finished, or
-- here is the next rung and here is its price.
--
-- There were more. Past tier 10 the same hold bought OVERCLOCK levels, and for
-- a while an overclock could be withheld until the player had a biome on
-- record. Both are history (GameConfig, OVERCLOCK WHICH IS HISTORY): every step
-- is a tier now, fourteen of them.
--==============================================================================
export type NextStep = {
	kind: string,       -- "tier" | "max"
	level: number?,     -- the tier being sold
	cost: number?,
}

function TreadmillService.NextStepFor(player: Player): NextStep
	local tier = TreadmillService.TierOf(player)
	local nextTier = LADDER.Tiers[tier + 1]
	if not nextTier then
		return { kind = "max" }
	end
	return {
		kind = "tier",
		level = tier + 1,
		cost = nextTier.cost,
	}
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
-- A TELEPORT TAKES YOU OFF (2026-10-08, the owner's report)
--
-- BIOMES and OBBY (PlotService.TeleportTo) move a mounted player without a
-- jump, and the zero WalkSpeed went with them: they landed at the road unable
-- to walk until they jumped. So a mount also ends when the player is moved
-- AWAY from the belt -- at once when a script moves the root (every teleport
-- writes its CFrame), and on the next tick for anything else. "Away" is well
-- clear of the belt's footprint, so a mill rebuilt at a new size under a
-- mounted player, which moves nobody, never counts.
--==============================================================================
local AWAY_STUDS = 12

local function awayFrom(root: BasePart, belt: BasePart): boolean
	if not belt.Parent then
		return true
	end
	local p = belt.CFrame:PointToObjectSpace(root.Position)
	local half = belt.Size * 0.5
	return math.abs(p.X) > half.X + AWAY_STUDS or math.abs(p.Z) > half.Z + AWAY_STUDS
		or math.abs(p.Y) > half.Y + STAND_HEIGHT + AWAY_STUDS
end

-- What ends a mount besides Unmount's own callers: a jump, a death, and a
-- script moving the root away. One list for Mount and for Rebuild.
local function watchMount(player: Player, humanoid: Humanoid, root: BasePart): { RBXScriptConnection }
	return {
		humanoid.Jumping:Connect(function(active: boolean)
			if active then
				TreadmillService.Unmount(player)
			end
		end),
		humanoid.Died:Connect(function()
			TreadmillService.Unmount(player)
		end),
		root:GetPropertyChangedSignal("CFrame"):Connect(function()
			local belt = mounted[player]
			if belt and awayFrom(root, belt) then
				TreadmillService.Unmount(player)
			end
		end),
	}
end

--==============================================================================
-- GETTING ON AND GETTING OFF
--==============================================================================
function TreadmillService.Unmount(player: Player)
	if not mounted[player] then
		return
	end
	mounted[player] = nil
	discoSpot[player] = nil
	for _, c in ipairs(mountConns[player] or {}) do
		c:Disconnect()
	end
	mountConns[player] = nil
	mountBlocked[player] = true
	player:SetAttribute(ATTR.MillMounted, nil)
	CarryService.RefreshWalkSpeed(player)
end

-- `spot`, for the Disco Mill: where on the belt to stand, in studs off its
-- middle along its own X and Z. Nil is the middle, as on every own mill.
function TreadmillService.Mount(player: Player, belt: BasePart, spot: Vector2?): boolean
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
	local stand = if spot then belt.CFrame:PointToWorldSpace(Vector3.new(spot.X, lift, spot.Y))
		else belt.Position + Vector3.new(0, lift, 0)
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

	mountConns[player] = watchMount(player, humanoid, root)
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
		-- Mounted but carried well away from the belt by anything a script's
		-- CFrame signal did not see (A TELEPORT TAKES YOU OFF, above).
		local ridden = mounted[player]
		if ridden then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not (root and root:IsA("BasePart")) or awayFrom(root :: BasePart, ridden) then
				TreadmillService.Unmount(player)
			end
		end
		--==================================================================
		-- Cheap because it only runs for somebody who just got off: one
		-- region test until they step clear, then never again.
		--==================================================================
		if mountBlocked[player] then
			local belt = ownBeltOf(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local discoBelt = disco.belt
			local still = root ~= nil
				and root:IsA("BasePart")
				and ((belt ~= nil and overBelt(root :: BasePart, belt :: BasePart))
					or (discoBelt ~= nil and overBelt(root :: BasePart, discoBelt :: BasePart)))
			if not still then
				mountBlocked[player] = nil
			end
		end
		local rate = TreadmillService.RateFor(player)
		local onDisco = rate > 0 and TreadmillService.OnDiscoMill(player)
		-- ON THE PLAYER, so it replicates to everybody. That is what lets each
		-- client play the run cycle on somebody else's character, and it is why
		-- this needs no remote.
		local on = rate > 0
		if (player:GetAttribute(ATTR.OnTreadmill) == true) ~= on then
			player:SetAttribute(ATTR.OnTreadmill, on or nil)
		end
		--==================================================================
		-- THE BELT SPEEDS UP WHEN SOMEBODY IS ON IT
		--
		-- Written only when where they are paid CHANGES, so it costs one
		-- attribute write per step-on and one per step-off rather than one
		-- per tick per belt. Everything that moves on a mill reads this one
		-- number. Their own belt runs only while they run on it -- not while
		-- they are on the Disco Mill (2026-10-04), whose belt is set below.
		--==================================================================
		local where = if not on then nil elseif onDisco then "disco" else "own"
		if paidOn[player] ~= where then
			paidOn[player] = where
			local plot = PlotService.PlotOf(player)
			local plotId = plot and plot:GetAttribute(ATTR.PlotId)
			local belt = if type(plotId) == "number" then beltFor(plotId) else nil
			if belt then
				setBeltSpeed(belt, where == "own", TreadmillService.TierOf(player))
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
					--==========================================================
					-- THE RATE IS A PRODUCT
					--
					--     tier x rebirth x chest x disco
					--
					-- The first two are `rate` (RateFor). The chest is the Bonus
					-- Chest's training reward (2026-09-27), 1 unless one is
					-- running. HERE because this is the only line that mints Speed
					-- from the belt: purchases, admin grants and WalkSpeed never
					-- pass it.
					--
					-- The Disco Mill (2026-10-04) is its last factor: x10 of
					-- everything before it -- tier, rebirth, chest --
					-- while they run on it, and 1 everywhere else. Composed here
					-- and nowhere else: the same tick, one AddSpeed. (The Training
					-- Rush that sat between rebirth and chest is gone: see ONE
					-- RATE at the top of this file.)
					--==========================================================
					local discoFactor = if onDisco then DISCO.Multiplier else 1
					-- Sprout Dash's +25% (2026-10-08, the owner's choice): its own
					-- source, so its percentage ADDS to the chest's or the wheel's.
					local sprout = PlayerDataService.Get(player)
					local training = BonusChestService.Multiplier(player, "training")
						+ SproutDash.bonusAt(sprout and (sprout :: any).SproutBoostEndsAt, os.time())
					local paid = rate * training * discoFactor * dt
					if PlayerDataService.AddSpeed(player, paid) then
						granted[player] = (granted[player] or 0) + paid
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
	-- The Disco Mill's belt runs while anybody is paid on it.
	local discoBelt = disco.belt
	if discoBelt then
		local busy = false
		for _, where in pairs(paidOn) do
			if where == "disco" then
				busy = true
				break
			end
		end
		local want = if busy then DISCO.BeltStuds else LADDER.IdleStuds
		if discoBelt:GetAttribute("BeltSpeed") ~= want then
			discoBelt:SetAttribute("BeltSpeed", want)
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
	discoSpot[player] = nil
	paidOn[player] = nil
	fullToldAt[player] = nil
end

--==============================================================================
-- THE DISCO MILL (2026-10-04, the owner's ask; GameConfig.MiniEvent.DiscoMill)
--
-- While a mode with a Mill runs (Ticket Disco, DISCO + MILL -- never the pure
-- DISCO ONLY or Ticket Shower Only: discoWanted), one giant shared treadmill
-- stands in front of the hub, west of the road to the biomes. Built here, on every server the event reaches, from the
-- Workspace attributes MiniEventService publishes -- the same state, id and
-- deadline as the rest of the event -- so a server that joins late builds it
-- for the time left, a late-joining player simply sees it, and a repeated
-- notice for the same id never builds a second one.
--
-- The top tier's mill (its rainbow bands) at DISCO.Scale, its deck sunk so the
-- belt is a short step up. Tagged Treadmill like every belt -- Ambience moves
-- it, SpeedFX matches the legs to it, a trap cannot be set on it -- but with
-- no PlotId and no sign, so nothing that serves a plot's own mill ever takes
-- it for one, and bindBelt's "your mill only" never mounts anybody on it.
--
-- Its own way on: a touch of its belt mounts the player on the first free
-- spot (DISCO.Spots) -- everybody runs at once, each on their own spot and
-- each paid their own training x DISCO.Multiplier (the payout line in
-- payEveryone). Every spot taken: the player is told so, at most every few
-- seconds. Off as off any mill: a jump, a death, a reset, leaving.
--
-- WHEN THE EVENT ENDS (or starts ending, or another takes its place) the pay
-- stops at once, everybody mounted on it is set down on the grass beside it,
-- on the road side, walking again, and it is taken down. Nobody else is
-- moved; nobody's own mill is touched.
--==============================================================================
local function setDown(player: Player, spot: number, model: Model?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) or humanoid.Health <= 0 then
		return
	end
	-- Clear of everything it is built from -- the top tier's wings reach past
	-- its deck -- on the road side.
	local half = 10 * DISCO.Scale
	if model then
		local _, size = model:GetBoundingBox()
		half = size.X / 2
	end
	local column, row = (spot - 1) % 3, (spot - 1) // 3
	local x = DISCO.At.X + half + DISCO.ExitOut + column * 4
	local z = DISCO.At.Z + (row - 1) * 8
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { character }
	if model then
		table.insert(ignore, model)
	end
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	local hit = Workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -80, 0), params)
	local ground = if hit then hit.Position.Y else GameConfig.Map.GroundY
	local stand = Vector3.new(x, ground + humanoid.HipHeight + (root :: BasePart).Size.Y * 0.5 + 0.2, z)
	local r = root :: BasePart
	r.CFrame = CFrame.lookAt(stand, stand + Vector3.new(0, 0, 1))
	r.AssemblyLinearVelocity = Vector3.zero
end

local function teardownDisco(why: string)
	local model = disco.model
	for _, c in ipairs(discoConns) do
		c:Disconnect()
	end
	table.clear(discoConns)
	local riders: { { player: Player, spot: number } } = {}
	for player, spot in pairs(discoSpot) do
		table.insert(riders, { player = player, spot = spot })
	end
	for _, rider in ipairs(riders) do
		TreadmillService.Unmount(rider.player)
		setDown(rider.player, rider.spot, model)
		-- Set down off the belt: nothing to land back on.
		mountBlocked[rider.player] = nil
	end
	for player, where in pairs(paidOn) do
		if where == "disco" then
			paidOn[player] = nil
		end
	end
	disco = { model = nil, belt = nil, eventId = nil }
	if model then
		model:Destroy()
		log(string.format("Disco Mill taken down (%s); %d rider(s) set down beside it.", why, #riders))
	end
end

local function discoMount(player: Player)
	local belt = disco.belt
	if not (belt and discoLive()) or mounted[player] or mountBlocked[player] then
		return
	end
	local taken: { [number]: boolean } = {}
	for _, spot in pairs(discoSpot) do
		taken[spot] = true
	end
	local free: number? = nil
	for i = 1, #DISCO.Spots do
		if not taken[i] then
			free = i
			break
		end
	end
	if not free then
		local now = os.clock()
		if upgradeChannel and now - (fullToldAt[player] or -math.huge) > 4 then
			fullToldAt[player] = now
			upgradeChannel:FireClient(player, DISCO.FullAction)
		end
		return
	end
	local s = DISCO.Spots[free]
	local half = belt.Size * 0.5
	if TreadmillService.Mount(player, belt, Vector2.new(s[1] * half.X, s[2] * half.Z)) then
		discoSpot[player] = free
	end
end

local function buildDisco(eventId: string)
	local at = DISCO.At
	local facing = CFrame.lookAt(Vector3.new(at.X, 0, at.Z), Vector3.new(at.X, 0, at.Z + 1))
	-- Built and scaled before it is parented, so nothing replicates half done.
	local holder = Instance.new("Folder")
	local model, belt = MillModel.Build(DISCO.Tier, facing, holder)
	model:ScaleTo(DISCO.Scale)
	-- The deck's foot DISCO.Sink under the ground (its pivot is the deck's centre).
	local deck = model.PrimaryPart
	local halfY = if deck then deck.Size.Y / 2 else 0.6 * DISCO.Scale
	model:PivotTo(CFrame.new(at.X, GameConfig.Map.GroundY - DISCO.Sink + halfY, at.Z) * facing.Rotation)
	-- The chevrons and bands wrap over the belt's length, which grew with it.
	for _, d in ipairs(model:GetDescendants()) do
		local span = d:GetAttribute("ChevronSpan")
		if type(span) == "number" then
			d:SetAttribute("ChevronSpan", span * DISCO.Scale)
		end
	end
	model.Name = DISCO.ModelName
	model.Archivable = false
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("DiscoMill", eventId)
	CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)
	belt:SetAttribute("BeltSpeed", LADDER.IdleStuds)

	-- Its name over the console end, readable from the hub.
	if deck then
		local board = Instance.new("BillboardGui")
		board.Name = "DiscoMillSign"
		board.Size = UDim2.fromOffset(240, 70)
		board.StudsOffsetWorldSpace = Vector3.new(0, 12, deck.Size.Z * 0.5)
		board.MaxDistance = 260
		board.LightInfluence = 0
		board.Parent = deck
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromScale(1, 0.6)
		title.Font = Enum.Font.LuckiestGuy
		title.TextScaled = true
		title.Text = "DISCO MILL"
		title.TextColor3 = Color3.fromRGB(255, 160, 232)
		title.Parent = board
		local edge = Instance.new("UIStroke")
		edge.Thickness = 2.5
		edge.Color = Color3.fromRGB(34, 18, 48)
		edge.Parent = title
		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.BackgroundTransparency = 1
		sub.Position = UDim2.fromScale(0, 0.6)
		sub.Size = UDim2.fromScale(1, 0.4)
		sub.Font = Enum.Font.FredokaOne
		sub.TextScaled = true
		sub.Text = string.format("\u{00D7}%d TRAINING", DISCO.Multiplier)
		sub.TextColor3 = Color3.fromRGB(120, 230, 255)
		sub.Parent = board
		local subEdge = Instance.new("UIStroke")
		subEdge.Thickness = 2
		subEdge.Color = Color3.fromRGB(34, 18, 48)
		subEdge.Parent = sub
	end

	model.Parent = Workspace
	holder:Destroy()
	disco = { model = model, belt = belt, eventId = eventId }
	table.insert(discoConns, belt.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if player then
			discoMount(player)
		end
	end))
	log(string.format("Disco Mill up for event %s: %d spots, x%d training.", string.sub(eventId, 1, 8),
		#DISCO.Spots, DISCO.Multiplier))
end

-- Brought in line with the event: built for a disco that runs, taken down for
-- one that stopped running, rebuilt for a new id. Safe to call any number of
-- times.
function TreadmillService.SyncDiscoMill()
	local want = discoWanted()
	local model = disco.model
	if want and disco.eventId == want and model and model.Parent then
		return
	end
	if model or next(discoSpot) ~= nil then
		teardownDisco(if want then "a new event" else "the event ended")
	end
	if want then
		local ok, err = pcall(buildDisco, want)
		if not ok then
			warn("[Seed/TreadmillService] the Disco Mill could not be built: " .. tostring(err))
			teardownDisco("the build failed")
		end
	end
end

function TreadmillService.DiscoMill(): Model?
	return disco.model
end

-- For the spec: the mount a touch of its belt makes, and the spot it gave.
function TreadmillService.MountDisco(player: Player): number?
	discoMount(player)
	return discoSpot[player]
end

-- For the spec: one pay tick, exactly the loop's.
TreadmillService.PayTick = payEveryone

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

--==============================================================================
-- THE SIGN READS THE SAME STEP THE PURCHASE USES
--
-- It printed the tier ladder directly and said "MAX" at seven, which was true
-- for about a week. Now it asks NextStepFor -- the one function that knows
-- whether there is a next tier at all -- so the board and the till can never
-- disagree about what is on sale.
--
-- Every number goes through GameConfig.compact, because a tier-14 mill pays
-- 450,000,000,000 a second and a sign that prints that is a sign nobody reads.
--==============================================================================
local function ownerOfPlotId(plotId: number): Player?
	-- PlotService maps a PLAYER to a plot and not the other way round, and six
	-- players is not a search worth an index for.
	for _, candidate in ipairs(Players:GetPlayers()) do
		local plot = PlotService.PlotOf(candidate)
		if plot and plot:GetAttribute(ATTR.PlotId) == plotId then
			return candidate
		end
	end
	return nil
end

--==============================================================================
-- CAN THE OWNER PAY FOR THE NEXT STEP, AND WHAT WAS THE BOARD LAST PAINTED AS
--
-- Green at cash >= the step's price -- the exact opposite of Upgrade's
-- `Cash < cost` refusal, on the raw (fractional) balance. The key is everything
-- the Buy plate's colour depends on, so the watcher below repaints a board only
-- when one of those has actually changed.
--==============================================================================
local millSignKey: { [number]: string } = {}
-- Bumped by Init and by each Start; the board watcher runs only while it holds
-- the newest value.
local millWatch = 0

local function millStateOf(plotId: number, tier: number): (string, boolean)
	local player = ownerOfPlotId(plotId)
	local step = if player then TreadmillService.NextStepFor(player) else nil
	local next_ = LADDER.Tiers[tier + 1]
	local cost: number? = if step and step.cost then step.cost
		elseif next_ then next_.cost
		else nil
	local sellable = if step then step.kind ~= "max" else next_ ~= nil
	local profile = if player then PlayerDataService.Get(player) else nil
	local affordable = sellable and profile ~= nil and cost ~= nil
		and (tonumber(profile.Cash) or 0) >= (cost :: number)
	local key = string.format("%s|%d|%s|%s|%s",
		if player then tostring(player.UserId) else "-", tier,
		if step then step.kind else "-",
		if step and step.level then tostring(step.level) else "-",
		tostring(affordable))
	return key, affordable
end

local function refreshSign(plotId: number, tier: number)
	local sign = signFor(plotId)
	if not sign then
		return
	end
	local board = sign:FindFirstChild("Board")
	if not board then
		return
	end
	--==========================================================================
	-- BOTH FACES, OR THE BACK ADVERTISES LAST HOUR'S PRICE
	--
	-- The board is lettered on both sides -- see MillModel, and the biome arches
	-- before it -- because the person walking up to it and the person standing
	-- on the belt are on opposite sides. Collected rather than named
	-- individually so that adding a third face, or dropping the back, changes
	-- nothing here.
	--==========================================================================
	local faces: { Instance } = {}
	for _, child in ipairs(board:GetChildren()) do
		if child:IsA("SurfaceGui") then
			table.insert(faces, child)
		end
	end
	if #faces == 0 then
		return
	end
	local prompt = board:FindFirstChildOfClass("ProximityPrompt")

	local here = LADDER.Tiers[tier]
	--==========================================================================
	-- THE SIGN BELONGS TO A PLOT, AND A PLOT MAY HAVE NOBODY ON IT
	--
	-- The rate is a fact about a PLAYER -- their tier and their rebirths -- and
	-- an empty plot has neither. It falls back to the tier's own rate then.
	--==========================================================================
	local player = ownerOfPlotId(plotId)
	local profile = if player then PlayerDataService.Get(player) else nil
	local next_ = LADDER.Tiers[tier + 1]
	local liveRate = if player
		then TreadmillService.RateOf(player)
		else GameConfig.trainingRateFor(tier, nil)

	--==========================================================================
	-- WORKED OUT ONCE, WRITTEN TO EVERY FACE
	--
	-- The board is lettered front and back, so the four strings are computed
	-- here and then applied in a loop. Computing them inside the loop would be
	-- the same tier lookup and the same rate arithmetic twice, and -- worse --
	-- two places for the two sides to start disagreeing.
	--
	-- THE STEP LINE NAMES THE MILL ON SALE (2026-10-06). It read "LEVEL 10 >
	-- LEVEL 11"; the owner's brief has a tier-10 board offer "UPGRADE ->
	-- Abyssal Trench", so it says what you are buying, at every tier. The name
	-- alone fits the 360-pixel face (ASTRAL SINGULARITY, the longest, measures
	-- 255 at this size); the level beside it would not.
	--==========================================================================
	local stepText = if next_
		then string.upper(next_.name)
		else string.format("LEVEL %d  ·  MAX", tier)

	--==========================================================================
	-- "BASE", BECAUSE BOTH NUMBERS ARE BASE RATES
	--
	-- The line is "what you have > what the upgrade gives", both before the
	-- boosts that come and go (a Bonus Chest's training reward, the Disco
	-- Mill). It was labelled when a level-1 mill popped +20 and then +80 under a
	-- sign that read 20/s > 100/s (2026-09-26) -- the Training Rush's x4, gone
	-- since 2026-10-05 -- and it stays labelled: the number is the mill's own
	-- rate, which is what BASE says. Both sides carry the owner's rebirths, as
	-- the payout does.
	--==========================================================================
	local rateText = if next_
		then string.format("BASE %s/s  >  %s/s",
			GameConfig.compact(liveRate), GameConfig.compact(GameConfig.trainingRateFor(tier + 1, profile)))
		else string.format("%s  ·  %s/s", string.upper(here.name), GameConfig.compact(liveRate))

	local priceText = if next_ then "$" .. GameConfig.compact(next_.cost) else "MAX"

	local sellable = next_ ~= nil
	--==========================================================================
	-- GREEN WHEN THE OWNER CAN PAY FOR IT
	--
	-- The same answer the plot board gives, for the same reason: red on every
	-- step for sale read as "can't afford" to a player who could. The watcher
	-- in Start repaints the board as the owner's cash moves.
	--==========================================================================
	local key, affordable = millStateOf(plotId, tier)
	millSignKey[plotId] = key
	local buyColour = if not sellable then Color3.fromRGB(96, 100, 108)
		elseif affordable then Color3.fromRGB(72, 170, 66)
		else Color3.fromRGB(214, 78, 66)

	for _, face in ipairs(faces) do
		local step = face:FindFirstChild("Step") :: TextLabel?
		local rate = face:FindFirstChild("Rate") :: TextLabel?
		local buy = face:FindFirstChild("Buy") :: Frame?
		local price = buy and buy:FindFirstChild("Price") :: TextLabel?
		if step then
			step.Text = stepText
		end
		if rate then
			rate.Text = rateText
		end
		if price then
			price.Text = priceText
		end
		if buy then
			buy.BackgroundColor3 = buyColour
		end
	end

	if prompt then
		prompt.Enabled = sellable
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

	local oldBelt = beltFor(plotId)
	local mountedPlayer: Player? = nil
	for p, b in pairs(mounted) do
		if b == oldBelt then
			mountedPlayer = p
			break
		end
	end

	local cf = existing:GetPivot()
	local parent = existing.Parent
	existing:Destroy()

	local model, belt = MillModel.Build(tier, cf, parent)
	model.Name = string.format("%s%02d", GameConfig.Plot.TreadmillName, plotId)
	model:SetAttribute(ATTR.PlotId, plotId)
	CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)

	if mountedPlayer and mountedPlayer.Parent == Players then
		mounted[mountedPlayer] = belt
		local character = mountedPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			for _, c in ipairs(mountConns[mountedPlayer] or {}) do
				c:Disconnect()
			end
			mountConns[mountedPlayer] = watchMount(mountedPlayer, humanoid, root :: BasePart)

			local on = TreadmillService.RateFor(mountedPlayer) > 0
			setBeltSpeed(belt, on, tier)
		else
			setBeltSpeed(belt, false, tier)
		end
	else
		setBeltSpeed(belt, false, tier)
	end

	--==========================================================================
	-- THE SIGN IS PLACED FROM THE MILL, NOT FROM THE OLD SIGN
	--
	-- This used to re-use `sign:GetPivot()` so the board went back "exactly where
	-- it stood". It did not: the sign's PrimaryPart is its POST, centred
	-- 2.6 * Scale above the base BuildSign expects, so each upgrade re-applied
	-- that offset and the sign rose 1.976 studs -- every time, for ever.
	--
	-- Deriving from the mill instead makes the placement idempotent: the mill's
	-- pivot is its Deck, built at the mill's own CFrame, so rebuilding the same
	-- tier a hundred times puts the sign in exactly the same place. It also
	-- means a save that already contains a floating sign is corrected by the
	-- next rebuild rather than inheriting the drift.
	--
	-- Where on the mill it stands depends on where the mill stands and on its
	-- tier (MillModel.SignBase). Beside a plot -- plot 6 -- the overhang of the
	-- tall tiers is softened the moment they are built (MillModel.Soften).
	--==========================================================================
	local beside = GameConfig.millStandsBeside(plotId)
	if beside then
		MillModel.Soften(model, GameConfig.millGateFor(cf, plotId), tier)
	end
	local rebuiltSign = MillModel.BuildSign(MillModel.SignBase(cf, tier, beside), model)
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
	--==========================================================================
	-- ONE INTERACTION, ONE LADDER
	--
	-- Past tier 10 the same hold used to buy an OVERCLOCK. Since 2026-10-06 it
	-- buys the next tier there too -- the owner's mills, 11 to 14 -- so every
	-- step is the branch below, and at 14 there is nothing left to sell.
	--==========================================================================
	if TreadmillService.NextStepFor(player).kind == "max" then
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
	log(string.format("%s upgraded their mill to %d (%s, %s/s) for %s.",
		player.Name, tier + 1, next_.name, GameConfig.compact(next_.speed), GameConfig.compact(next_.cost)))
	return true
end

--==============================================================================
-- A ONE-OFF GRANT
--
-- The Index's Biome Harvest pays Speed, and Speed is minted here, so the belt is
-- still the one file that explains a player's score. The CALLER decides the
-- grant is due and how big -- AlmanacService, off the profile and BiomeData --
-- and this pays it, counts it with the belt's own grants for Snapshot, and asks
-- CarryService to recompute WalkSpeed exactly as a belt tick does.
--==============================================================================
-- `source` rides through to PlayerDataService.AddSpeed: "admin" from the admin
-- console (a Speed milestone it crosses pays no prize), nil for earned Speed.
function TreadmillService.PayReward(player: Player, amount: number, reason: string, source: string?): boolean
	if player.Parent ~= Players or type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return false
	end
	if PlayerDataService.AddSpeed(player, amount, source) == nil then
		return false
	end
	granted[player] = (granted[player] or 0) + amount
	-- CarryService owns WalkSpeed. Ask, do not write.
	CarryService.RefreshWalkSpeed(player)
	log(string.format("%s was granted %s Speed for %s.",
		player.Name, GameConfig.compact(amount), reason))
	return true
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function TreadmillService.Init()
	running = false
	millWatch += 1
	table.clear(millSignKey)
	if releaseHook then
		releaseHook()
		releaseHook = nil
	end
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
	teardownDisco("a restart")
	table.clear(discoSpot)
	table.clear(paidOn)
	table.clear(fullToldAt)
	local stale = Workspace:FindFirstChild(DISCO.ModelName)
	if stale then
		stale:Destroy()
	end
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
		-- Same wait and same reason as the one PlantService uses before it
		-- restores a bed: for as long as the player stays, because a save has
		-- been measured at 38 s and a 20 s deadline left a returning tier-6
		-- player on a starting mill for the whole session.
		--
		-- AND BY WHAT IS STANDING THERE, not only by what the owner is. The old
		-- test rebuilt only for an owner above the starting tier, so a tier-1
		-- owner kept whatever mill the plot already had -- including one a
		-- previous owner left behind.
		--======================================================================
		task.spawn(function()
			local deadline = os.clock() + GameConfig.Plot.RestorePatienceSeconds
			while player.Parent == Players and not PlayerDataService.IsReady(player)
				and os.clock() < deadline do
				task.wait(0.25)
			end
			if player.Parent ~= Players or PlotService.OwnerOf(plot) ~= player then
				return
			end
			local tier = TreadmillService.TierOf(player)
			local mill = millModelFor(plotId)
			if tier ~= LADDER.StartingTier
				or (mill ~= nil and mill:GetAttribute("MillTier") ~= LADDER.StartingTier) then
				TreadmillService.Rebuild(plot, tier)
			else
				refreshSign(plotId, tier)
			end
		end)
	end))

	--==========================================================================
	-- A RELEASED PLOT GETS THE STARTING MILL BACK
	--
	-- The mill and its sign stand in the plots folder, beside the plot rather
	-- than in it, so PlotService's release -- which empties the plot and shrinks
	-- it to level 1 -- never touched them. An owner who left with a tier-6 mill
	-- left it standing on an "empty" plot beside a sign repainted to LEVEL 1,
	-- the next tier-1 owner inherited it, and one who left mid-run left the belt
	-- spinning. Reported 2026-09-26 as the base not resetting when its owner
	-- left.
	--
	-- Inside the release and synchronous, so it cannot land on a plot somebody
	-- else has been handed since; and safe to run twice -- a mill already at the
	-- starting tier is only told to idle and repaint. The owner's own mill is in
	-- their profile and comes back with them, on whichever plot they get.
	--==========================================================================
	releaseHook = PlotService.OnReleased(function(player, plot)
		local plotId = plot:GetAttribute(ATTR.PlotId)
		if type(plotId) ~= "number" then
			return
		end
		TreadmillService.Unmount(player)
		local mill = millModelFor(plotId)
		if mill and mill:GetAttribute("MillTier") ~= LADDER.StartingTier then
			TreadmillService.Rebuild(plot, LADDER.StartingTier)
		else
			local belt = beltFor(plotId)
			if belt then
				setBeltSpeed(belt, false, LADDER.StartingTier)
			end
			refreshSign(plotId, LADDER.StartingTier)
		end
	end)

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
	-- THE DISCO MILL follows the mini event's own attributes (MiniEventService
	-- writes the state last), once per change however many change together.
	local discoQueued = false
	local function discoSoon()
		if discoQueued then
			return
		end
		discoQueued = true
		task.defer(function()
			discoQueued = false
			TreadmillService.SyncDiscoMill()
		end)
	end
	for _, name in ipairs({ EVENT.State, EVENT.Mode, EVENT.EventId }) do
		table.insert(serviceConnections, Workspace:GetAttributeChangedSignal(name):Connect(discoSoon))
	end
	TreadmillService.SyncDiscoMill()
	task.spawn(function()
		while running do
			task.wait(TICK)
			local ok, err = pcall(payEveryone)
			if not ok then
				warn("[Seed/TreadmillService] pay tick failed: " .. tostring(err))
			end
		end
	end)

	--==========================================================================
	-- A BOARD FOLLOWS ITS OWNER'S CASH
	--
	-- The mill's twin of PlotUpgradeService's watcher: income, a purchase or an
	-- upgrade anywhere turns this board green or red within a quarter of a
	-- second, repainting only a board whose owner, tier, step or affordability
	-- changed. Its own generation, so a re-run never leaves two of these.
	--==========================================================================
	millWatch += 1
	local watching = millWatch
	task.spawn(function()
		while millWatch == watching do
			task.wait(0.25)
			if millWatch ~= watching then
				return
			end
			for _, sign in ipairs(CollectionService:GetTagged(GameConfig.Tags.MillSign)) do
				local plotId = sign:GetAttribute(ATTR.PlotId)
				if type(plotId) == "number" then
					local tier = tierOnPlot(plotId)
					if (millStateOf(plotId, tier)) ~= millSignKey[plotId] then
						refreshSign(plotId, tier)
					end
				end
			end
		end
	end)

	log(string.format(
		"Ready. The only faucet for Speed. %d mill(s), %d tiers, +%s/sec at tier 1 up to +%s/sec at tier %d, one rate (no rush).",
		mills, #LADDER.Tiers, GameConfig.compact(LADDER.Tiers[1].speed),
		GameConfig.compact(LADDER.Tiers[#LADDER.Tiers].speed), #LADDER.Tiers))
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
