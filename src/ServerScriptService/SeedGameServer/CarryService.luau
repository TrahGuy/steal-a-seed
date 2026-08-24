--!strict
-- Steal a Seed :: CarryService
--
-- Picking a pod up, carrying it home, and losing it when it goes wrong.
--
--==============================================================================
-- ONE POD. THAT IS THE WHOLE RULE.
--
-- An earlier build let you stack them and summed the weight. One is better, and
-- for a reason worth keeping: with a stack, a raid is an optimisation problem --
-- how many can I grab before it wakes. With one, it is a COMMITMENT. You picked
-- that pod, you are carrying that pod, and the walk home is about that pod.
--
-- It also makes the weight legible. A single number on your back, a single
-- number off your speed, and a player learns the whole economy by carrying two
-- different things.
--
--==============================================================================
-- GETTING CAUGHT COSTS YOU THE POD, NOT JUST THE WALK
--
-- Being ragdolled drops it. Any ragdoll, not just the parent's throw -- the
-- trigger is Humanoid.PlatformStand going true, so anything that ever knocks a
-- player down takes their cargo with it and no future system has to remember to
-- call anything.
--
-- That is what makes the parent frightening. The throw alone costs distance,
-- which is recoverable; losing the pod at the same time is what makes you creep
-- rather than sprint.
--
--==============================================================================
-- THIS SERVICE IS THE ONLY WRITER OF WalkSpeed
--
-- Base comes from the profile's Speed through GameConfig's curve, and carry
-- weight is the LAST multiplier applied to it. Something has to have the final
-- say or two systems fight over the property every frame, and the one holding
-- the last multiplier is the one that must own it. A future TreadmillService
-- raises the Speed SCORE and calls RefreshWalkSpeed; it never touches WalkSpeed.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(script.Parent:WaitForChild("CreatureModel"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local ATTR = GameConfig.Attributes

local CarryService = {}
-- After NestService (40), which owns the pods being taken.
CarryService.Priority = 45

export type Held = {
	species: SeedData.Species,
	-- What this pod weighs. Rolled where it spawned, carried through every drop
	-- and pick-up, and stamped on the Tool when it is banked. The species sheet
	-- has nothing to say about it.
	kg: number,
	model: Model,
	-- Which nest it came off, carried through a drop so that picking it back up
	-- can annoy the same parent again.
	fromNest: string?,
}

local carried: { [Player]: Held } = {}
local serviceConnections: { RBXScriptConnection } = {}
local perPlayer: { [Player]: { RBXScriptConnection } } = {}
local prompted: { [Model]: true } = {}
local running = false

-- How far above the head it floats. High enough to read across the road --
-- everybody can see what you are carrying, which is what makes a carrier a
-- target the moment PvP is switched on.
-- CARRY_HEIGHT used to be 3.0 and welded the pod to the HEAD, which floated it
-- above the skull like a halo -- readable at distance, but it made a raid look
-- like a delivery quest rather than somebody hauling something heavy.
--
-- The numbers now live in GameConfig.Carry because the CLIENT needs them too,
-- to aim the arms at the pod. Same values, one home.
-- A pod on the ground is fair game for anybody, and vanishes if nobody comes.
local LOOSE_LIFETIME = 45
-- How close you must be. The PROMPT is not a security boundary -- it is a
-- courtesy drawn on a client, and a client can call InputHoldBegin on a prompt
-- from anywhere -- so the server measures the distance itself.
local TAKE_RANGE = 11
-- Slack for latency: the client saw them in range a moment ago and the take
-- lands a moment later. Tight enough to stop a reach across the road.
local RANGE_SLACK = 5
-- How often the crossing is checked. Five times a second is finer than a player
-- can cross a line and notice.
local SAFE_CHECK_SECONDS = 0.2

local function log(message: string)
	print("[Seed/CarryService] " .. message)
end

--==============================================================================
-- STATE THE CLIENT CAN SEE
--
-- An ATTRIBUTE ON THE PLAYER, because attributes replicate on their own and the
-- prompt UI has to know instantly whether to draw itself. A remote would be a
-- round trip to answer a question the client asks every frame it renders a
-- prompt.
--==============================================================================
local function publish(player: Player)
	local held = carried[player]
	player:SetAttribute(ATTR.CarryingSpecies, if held then held.species.Id else nil)
	player:SetAttribute(ATTR.CarryingKg, if held then held.kg else nil)
end

function CarryService.IsCarrying(player: Player): boolean
	return carried[player] ~= nil
end

function CarryService.TotalKg(player: Player): number
	local held = carried[player]
	return if held then held.kg else 0
end

function CarryService.RefreshWalkSpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local profile = PlayerDataService.Get(player)
	local base = GameConfig.walkSpeedFor(if profile then profile.Speed else 0)
	humanoid.WalkSpeed = base * GameConfig.carryMultiplierFor(CarryService.TotalKg(player))
end

--==============================================================================
-- CARRYING
--==============================================================================
--==============================================================================
-- THE WEIGHT, ON THE THING
--
-- kg rather than the species name: weight is what the player is deciding about
-- while they run, and it is the number the carry multiplier and the payout both
-- come from. Rarity is already the pod's colour and size is already its bulk.
--
-- ONE definition, used by the raid carry AND by the banked Tool, so the thing
-- in your arms looks the same before and after the red line.
--==============================================================================
local function weightTag(handle: BasePart, kg: number)
	local existing = handle:FindFirstChild("CarryWeight")
	if existing then
		existing:Destroy()
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CarryWeight"
	billboard.Adornee = handle
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(96, 34)
	billboard.StudsOffset = Vector3.new(0, SeedData.PodDiameter(kg) * 0.5 + 1.1, 0)
	billboard.MaxDistance = 140
	billboard.Parent = handle

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(26, 24, 30)
	panel.BackgroundTransparency = 0.2
	panel.BorderSizePixel = 0
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(142, 196, 62)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = panel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(248, 246, 240)
	label.Text = string.format("%dKg", kg)
	label.Parent = panel
end

-- Where a pod sits relative to a HumanoidRootPart. One function, so the raid
-- carry and the banked Tool cannot drift into two different grips.
local function gripFor(kg: number): CFrame
	-- -Z is forward in a root's frame. Offset by the pod's OWN RADIUS, because
	-- pods are 1.3 to 10 studs across: a fixed offset either buries a heavy one
	-- in the ribs or leaves a light one hovering clear of the hands.
	return CFrame.new(0, GameConfig.Carry.GripDrop, -SeedData.GripForward(kg))
end

--==============================================================================
-- IT RIDES IN FRONT OF THE TORSO, IN BOTH ARMS
--
-- Welded to HumanoidRootPart, not the head. The root is the part that turns
-- with the body, so the pod stays in front of the player through every turn
-- instead of swinging with a head that looks around independently.
--
-- Offset by the pod's OWN RADIUS, because pods are 1.3 to 10 studs across now --
-- weight is rolled per pod and any species can be either -- so a fixed offset
-- either buries a heavy one in the ribs or leaves a light one hovering a stud
-- clear of the hands.
--==============================================================================
local function attachInFront(model: Model, root: BasePart, kg: number)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = true
			if d ~= primary then
				local w = Instance.new("WeldConstraint")
				w.Part0 = primary
				w.Part1 = d
				w.Parent = primary
			end
		end
	end
	local grip = gripFor(kg)
	primary.CFrame = root.CFrame * grip
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = primary
	weld.C0 = grip
	weld.Parent = primary
	weightTag(primary, kg)
end

--==============================================================================
-- PROMPTS
--
-- Style = Custom, so the look is drawn by PromptUI.client.luau rather than by
-- Roblox's default chrome. ActionText is still set because the client reads it
-- for the label, and ObjectText is deliberately EMPTY: the prompt shows "Take"
-- and a key, nothing else.
--==============================================================================
local function attachPrompt(pod: Model)
	if prompted[pod] or not pod:IsA("Model") then
		return
	end
	local primary = pod.PrimaryPart
	if not primary then
		return
	end
	prompted[pod] = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakePrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Take"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = GameConfig.Carry.TakeHoldSeconds
	prompt.MaxActivationDistance = TAKE_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary

	prompt.Triggered:Connect(function(player)
		CarryService.TryTake(player, pod)
	end)
end

--==============================================================================
-- DROPPED PODS SIT ON THE GROUND, NOT IN THE AIR
--
-- Pods are anchored, and a dropped one was placed at the player's ROOT
-- position -- which is about three studs up. It hung there. Nothing falls in
-- this game, so anything placed has to be placed correctly: cast down and put
-- its base on whatever it finds.
--==============================================================================
local function groundUnder(position: Vector3, ignore: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(position + Vector3.new(0, 4, 0),
		Vector3.new(0, -60, 0), params)
	if hit then
		return hit.Position
	end
	-- Nothing beneath. The field surface is the honest fallback -- better a pod
	-- on the floor of the world than one hanging where the player happened to be.
	return Vector3.new(position.X, GameConfig.Map.GroundY, position.Z)
end

-- A dropped pod becomes a loose pod anybody can take. Declared before TryTake
-- because taking one that then cannot be attached has to put it back.
-- `kg` travels with it. A dropped pod that fell back on the species sheet would
-- be a way to launder a 9,000 kg cube into a 2 kg one by dropping it, and the
-- player who picked it up would be robbed by the physics rather than by anyone.
local function spawnLoose(species: SeedData.Species, kg: number, at: CFrame,
	parent: Instance, fromNest: string?)
	local pod = CreatureModel.BuildPod(species, kg, at, parent)
	-- Loot, explicitly. This is the whole point of a loose pod.
	CollectionService:AddTag(pod, GameConfig.Tags.SeedPod)
	if fromNest then
		-- Not "NestId": that would make TryTake route it back through TakePod,
		-- which would look for a slot this pod no longer occupies. It only says
		-- WHICH PARENT TO ANNOY.
		pod:SetAttribute("FromNestId", fromNest)
	end
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = true
		end
	end
	attachPrompt(pod)
	task.delay(LOOSE_LIFETIME, function()
		if pod.Parent then
			pod:Destroy()
		end
	end)
end

--==============================================================================
-- VALIDATE EVERYTHING, THEN MUTATE. NOT THE OTHER WAY ROUND.
--
-- This used to call TakePod first and check for a Head afterwards, and TakePod
-- is not a query: it clears the nest slot, starts the wake timer and DESTROYS
-- the pod. So a player with no Head -- mid-respawn, or dying in the same frame
-- -- left the parent waking up over an empty slot with the pod gone and nobody
-- holding it. The prize evaporated.
--
-- Everything that can refuse is checked before anything is touched, and the one
-- step that still cannot be pre-checked -- attaching to the character -- puts
-- the species back on the ground rather than dropping it out of the world.
--==============================================================================
function CarryService.TryTake(player: Player, pod: Model): boolean
	if player.Parent ~= Players then
		return false
	end
	-- THE SERVER IS THE AUTHORITY. The client hides the prompt while you are
	-- carrying, and this refuses anyway: hiding a prompt is a courtesy, not a
	-- rule, and a rule enforced only on the client is not a rule.
	if carried[player] then
		return false
	end
	if not pod.Parent then
		return false
	end
	--==========================================================================
	-- A PLOT PLANT IS NOT LOOT
	--
	-- Checked here, at the top, with everything else that refuses -- above the
	-- line where the world starts changing. Reaching the take path at all would
	-- destroy the plant, set CarryingSpecies (the client's RUN alarm), and then
	-- clear it again the moment the safe-zone poll ran (SAFE) -- the full raid
	-- alarm, in the safe zone, for a pod the player carried home themselves.
	--
	-- TWO INDEPENDENT CHECKS, deliberately. The tag is the fact; the folder is
	-- WHERE THE THING LIVES, which no amount of tag drift can fake. A stale
	-- prompt on a plant must still refuse, and one of these will always catch it.
	--==========================================================================
	if CollectionService:HasTag(pod, GameConfig.Tags.Planted) then
		return false
	end
	if pod.Parent.Name == GameConfig.Plot.PlantsFolderName then
		return false
	end
	local anchor = pod.PrimaryPart
	if not anchor then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local head = character and character:FindFirstChild("Head")
	if not (humanoid and humanoid.Health > 0) then
		return false
	end
	if not (head and head:IsA("BasePart")) then
		return false
	end
	if (head.Position - anchor.Position).Magnitude > TAKE_RANGE + RANGE_SLACK then
		return false
	end

	--== EVERYTHING BELOW THIS LINE CHANGES THE WORLD ==--
	-- Read before the take: TakePod destroys the pod, and its attributes with it.
	-- The pod's own rolled weight, read here for the same reason the nest id is:
	-- TakePod destroys the model and its attributes go with it. Falling back to
	-- the species sheet would turn a 9,000 kg cube into a 2 kg one at the moment
	-- of pickup, which is the one moment the player is watching the number.
	local podKg = tonumber(pod:GetAttribute("Kg"))
	local nestId = pod:GetAttribute("NestId")
	local fromNest: string? = if type(nestId) == "string"
		then nestId
		else (if type(pod:GetAttribute("FromNestId")) == "string"
			then pod:GetAttribute("FromNestId") :: string
			else nil)

	local species: SeedData.Species?
	if pod:GetAttribute("NestId") then
		-- Nest-owned: NestService decides, because taking one is what wakes the
		-- parent, and it is the only thing that can lose the race between two
		-- players reaching for the same pod -- it checks pods[slot] ~= pod, so
		-- only one of them can win.
		species = NestService.TakePod(pod, player)
	else
		species = SeedData.Get(pod:GetAttribute("SpeciesId") or "")
		if species then
			pod:Destroy()
			-- Picking a dropped pod back up wakes the parent it came from. Being
			-- caught once must not make the rest of the raid free.
			--
			-- Uses the value read BEFORE the destroy: reading an attribute off a
			-- destroyed instance happens to work today and is not something to
			-- build on.
			if fromNest then
				NestService.Provoke(fromNest, player)
			end
		end
	end
	if not species then
		return false
	end

	local taken = species :: SeedData.Species
	local takenKg = math.clamp(podKg or taken.Kg, 1, GameConfig.Carry.MaxKg)
	local ok, err = pcall(function()
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local model = CreatureModel.BuildPod(taken, takenKg, root.CFrame, character)
		attachInFront(model, root, takenKg)
		-- CarriedPod ONLY. It used to inherit SeedPod from the builder as well,
		-- so the pod on your own head wore a Take prompt.
		CollectionService:AddTag(model, GameConfig.Tags.CarriedPod)
		carried[player] = {
			species = taken,
			kg = takenKg,
			model = model,
			fromNest = fromNest,
		}
	end)

	if not ok or not carried[player] then
		-- The pod is already out of the world and the parent may already be
		-- waking. Losing the species here would make a raid randomly worthless,
		-- so it goes back on the ground where anybody can pick it up.
		warn("[Seed/CarryService] could not attach " .. taken.Id .. ": " .. tostring(err))
		carried[player] = nil
		local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
		if map then
			spawnLoose(taken, takenKg,
				CFrame.new(anchor.Position + Vector3.new(0, 1, 0)), map)
		end
		return false
	end

	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return true
end

--==============================================================================
-- DROPPING
--
-- A dropped pod becomes a loose pod anybody can take. That is the PvP hook
-- waiting to be switched on: the moment a carrier can be made to drop, what
-- they are carrying stops being a prize and becomes a target.
--==============================================================================
function CarryService.Drop(player: Player, at: Vector3?): boolean
	local held = carried[player]
	if not held then
		return false
	end
	carried[player] = nil

	local where = at
	if not where then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		where = if root and root:IsA("BasePart") then root.Position else nil
	end
	if held.model.Parent then
		held.model:Destroy()
	end
	local map = workspace:FindFirstChild(GameConfig.Map.FolderName)
	if where and map then
		local character = player.Character
		-- Only the character. Excluding the map would exclude the ground, which
		-- is the one thing the cast is looking for.
		local ground = groundUnder(where, if character then { character } else {})
		spawnLoose(held.species, held.kg, CFrame.new(ground + Vector3.new(0, 0.05, 0)),
			map, held.fromNest)
	end

	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return true
end

--==============================================================================
-- CROSSING THE RED LINE BANKS IT
--
-- Reaching the safe zone is the moment a raid PAYS, and until now nothing
-- marked it -- you simply stopped being chased. Stepping over the line converts
-- the pod on your head into a Tool in your hotbar: it stops being a thing that
-- can be knocked out of your hands and becomes a thing you own.
--
-- That is also what finally makes the walk home mean something. Everything
-- between the nest and the line is at risk; everything past it is banked.
--
-- The test is MapService.IsInSafeZone, the same one the whole game uses, so the
-- line painted on the grass and the line the code checks are the same line.
--==============================================================================
local function bank(player: Player): boolean
	local held = carried[player]
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not (held and character and backpack) then
		return false
	end

	local species = held.species
	local kg = held.kg
	-- Built fresh as the Tool's handle rather than reusing the carried model:
	-- that one is welded to a head and unanchored, and a Tool wants a part named
	-- Handle that it owns outright.
	local pod = CreatureModel.BuildPod(species, kg, CFrame.new(), backpack)
	local handle = pod.PrimaryPart
	if not handle then
		pod:Destroy()
		return false
	end

	local tool = Instance.new("Tool")
	tool.Name = species.Name
	-- The WEIGHT band, not the form's drop tier: what the player wants off a
	-- tooltip is what this one is worth.
	tool.ToolTip = string.format("%s  -  %d kg", SeedData.RarityForKg(kg), kg)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("SpeciesId", species.Id)
	tool:SetAttribute(ATTR.CarryingKg, kg)

	handle.Name = "Handle"
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			d.CanQuery = false
			if d ~= handle then
				local w = Instance.new("WeldConstraint")
				w.Part0 = handle
				w.Part1 = d
				w.Parent = handle
				d.Parent = tool
			end
		end
	end
	handle.Parent = tool
	pod:Destroy()
	weightTag(handle, kg)

	--==========================================================================
	-- THE SAME GRIP AFTER THE LINE AS BEFORE IT
	--
	-- A Tool is welded to the right HAND by a weld Roblox makes on equip, which
	-- holds the pod out in one fist. That is a different game from the
	-- two-handed haul the raid uses, and a pod you own should not be carried
	-- differently from a pod you are stealing.
	--
	--==========================================================================
	-- THE ENGINE PARENTS THAT WELD TO THE HAND, NOT TO THE CHARACTER
	--
	-- Measured on a live equipped Tool in a real session:
	--
	--   joint "RightGrip" (Weld) parented to RightHand | Part0=RightHand  Part1=Handle
	--   joint "CarryWeld" (Weld) parented to Handle    | Part0=RootPart   Part1=Handle
	--
	-- BOTH of them, at once. This used to look for the hand weld with
	-- `character:FindFirstChild("RightGrip")`, which searches DIRECT CHILDREN
	-- only -- so it never found it, never destroyed it, and the pod ended up
	-- rigidly welded to the fist and to the root simultaneously. Measured 0.22
	-- studs from the right hand: over-constrained, with the hand winning.
	--
	-- Two fixes, because there were two ways to lose:
	--
	--   WHERE   scan the character's DESCENDANTS for anything jointed to this
	--           handle that is not ours, rather than guessing a parent.
	--   WHEN    the engine builds that weld asynchronously after Equipped fires,
	--           so one deferred destroy can also simply be early. A
	--           DescendantAdded watch stays live for as long as the tool is held
	--           and re-asserts the root weld if a hand weld turns up later.
	--==========================================================================
	local grip = gripFor(kg)

	local function fitToRoot(character: Model)
		if handle.Parent ~= tool then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		-- Anything holding this handle that we did not make.
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("JointInstance") and d.Name ~= "CarryWeld" and d.Part1 == handle then
				d:Destroy()
			end
		end
		if not handle:FindFirstChild("CarryWeld") then
			-- Placed before the weld exists, exactly as attachInFront does, so
			-- it arrives in front of the chest rather than snapping there.
			handle.CFrame = root.CFrame * grip
			local weld = Instance.new("Weld")
			weld.Name = "CarryWeld"
			weld.Part0 = root
			weld.Part1 = handle
			weld.C0 = grip
			weld.Parent = handle
		end
	end

	local watching: RBXScriptConnection? = nil

	table.insert(serviceConnections, tool.Equipped:Connect(function()
		local character = tool.Parent
		if not (character and character:IsA("Model")) then
			return
		end
		local model = character :: Model
		if watching then
			watching:Disconnect()
		end
		watching = model.DescendantAdded:Connect(function(d)
			-- Part0/Part1 are not necessarily assigned yet when this fires, so
			-- the test is deliberately loose and the real check happens inside
			-- fitToRoot a frame later.
			if d:IsA("JointInstance") and d.Name ~= "CarryWeld" then
				task.defer(fitToRoot, model)
			end
		end)
		fitToRoot(model)
		task.defer(fitToRoot, model)
	end))

	table.insert(serviceConnections, tool.Unequipped:Connect(function()
		if watching then
			watching:Disconnect()
			watching = nil
		end
	end))
	tool.Parent = backpack

	-- Consumed, not dropped: it is in the hotbar now, not on the floor.
	if held.model.Parent then
		held.model:Destroy()
	end
	carried[player] = nil
	publish(player)
	CarryService.RefreshWalkSpeed(player)
	-- Tell the client it MADE IT. Dropping and banking both end with
	-- CarryingSpecies going nil, so without this the alert has no way to tell a
	-- success from a mugging.
	player:SetAttribute(ATTR.BankedCount,
		(player:GetAttribute(ATTR.BankedCount) or 0) + 1)
	log(string.format("%s banked a %s (%d kg).", player.Name, species.Name, kg))
	return true
end

--==============================================================================
-- READ API, for PlantService
--==============================================================================
function CarryService.GetCarried(player: Player): Held?
	return carried[player]
end

-- Consumes the pod without dropping it. Planting is the only thing that should
-- take a carried pod off a player and leave nothing on the ground.
function CarryService.Consume(player: Player): SeedData.Species?
	local held = carried[player]
	if not held then
		return nil
	end
	carried[player] = nil
	if held.model.Parent then
		held.model:Destroy()
	end
	publish(player)
	CarryService.RefreshWalkSpeed(player)
	return held.species
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function forget(player: Player)
	local conns = perPlayer[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		perPlayer[player] = nil
	end
end

local function onCharacterAdded(player: Player, character: Model)
	-- A new body carries nothing: whatever the old one had is on the ground
	-- where it fell.
	carried[player] = nil
	publish(player)

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not (humanoid and humanoid:IsA("Humanoid")) then
		return
	end
	local conns = perPlayer[player] or {}
	perPlayer[player] = conns

	CarryService.RefreshWalkSpeed(player)

	--==========================================================================
	-- AND AGAIN WHEN THE PROFILE LANDS
	--
	-- The body spawns immediately. The profile is a DataStore round trip behind
	-- it, so the call above reads `nil` and falls back to walkSpeedFor(0) --
	-- BASE speed, 16 -- for a player whose saved score is worth eighty.
	--
	-- Nothing re-ran it. The only other callers of RefreshWalkSpeed are taking
	-- a pod, dropping one, banking one and earning on the mill, so a player who
	-- joined and just ran was stuck at base until they happened to touch a pod.
	-- Reported as "the speed I have doesn't work, I need to take pods to
	-- recover", and that is exactly what it was.
	--
	-- Same shape as PlantService's restore: wait for the profile rather than
	-- assume an order that is not guaranteed.
	--==========================================================================
	if not PlayerDataService.IsReady(player) then
		task.spawn(function()
			local deadline = os.clock() + 30
			while not PlayerDataService.IsReady(player) and os.clock() < deadline do
				task.wait(0.25)
			end
			-- Still this body? A respawn inside thirty seconds has already
			-- started a wait of its own, and two of them refreshing is one of
			-- them writing on behalf of a character that no longer exists.
			if player.Parent ~= Players or player.Character ~= character then
				return
			end
			if PlayerDataService.IsReady(player) then
				CarryService.RefreshWalkSpeed(player)
			end
		end)
	end

	-- RAGDOLLED MEANS DROPPED, and watching the PROPERTY rather than the event
	-- that caused it means every future knockdown gets this for free -- nothing
	-- has to remember to call Drop.
	table.insert(conns, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
		if humanoid.PlatformStand then
			local root = character:FindFirstChild("HumanoidRootPart")
			CarryService.Drop(player,
				if root and root:IsA("BasePart") then root.Position else nil)
		end
	end))

	table.insert(conns, humanoid.Died:Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart")
		CarryService.Drop(player,
			if root and root:IsA("BasePart") then root.Position else nil)
	end))
end

local function watch(player: Player)
	table.insert(serviceConnections, player.CharacterAdded:Connect(function(character)
		forget(player)
		onCharacterAdded(player, character)
	end))
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

function CarryService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	for player in pairs(perPlayer) do
		forget(player)
	end
	table.clear(carried)
	table.clear(prompted)
end

function CarryService.Start()
	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod:IsA("Model") then
			attachPrompt(pod)
		end
	end
	table.insert(serviceConnections,
		CollectionService:GetInstanceAddedSignal(GameConfig.Tags.SeedPod):Connect(function(pod)
			if pod:IsA("Model") then
				attachPrompt(pod)
			end
		end))
	table.insert(serviceConnections,
		CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.SeedPod):Connect(function(pod)
			prompted[pod :: Model] = nil
		end))

	table.insert(serviceConnections, Players.PlayerAdded:Connect(watch))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player)
		forget(player)
		carried[player] = nil
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end

	--== THE LINE ==--
	-- A poll rather than a Touched event on the stripe: the stripe is a thin
	-- non-collidable decal that a player at WalkSpeed 150 can cross between two
	-- frames without ever touching, and the safe zone is a REGION rather than a
	-- part.
	running = true
	task.spawn(function()
		while running do
			task.wait(SAFE_CHECK_SECONDS)
			for player in pairs(carried) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart")
					and MapService.IsInSafeZone(root.Position) then
					local ok, err = pcall(bank, player)
					if not ok then
						warn("[Seed/CarryService] banking failed: " .. tostring(err))
					end
				end
			end
		end
	end)

	log("Ready. One pod at a time, dropped when ragdolled, banked at the red line.")
end

function CarryService.Snapshot(): string
	local rows = {}
	for player, held in pairs(carried) do
		table.insert(rows, string.format("%s: %s %d kg -> %.1f%% speed",
			player.Name, held.species.Name, held.kg,
			GameConfig.carryMultiplierFor(held.kg) * 100))
	end
	return if #rows > 0 then table.concat(rows, " | ") else "nobody carrying"
end

return CarryService
