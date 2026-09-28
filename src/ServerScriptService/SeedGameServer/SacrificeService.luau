--!strict
-- Steal a Seed :: SacrificeService
--
-- The free sacrifice pedestal in the hub (2026-09-28). One banked, unhatched
-- pod out of the player's own hands buys a short burst of ONLINE garden income.
-- The numbers are SeedData.Sacrifice; the place, the names and the verbs are
-- GameConfig.Sacrifice; this file keeps the promise.
--
--==============================================================================
-- A QUOTE, THEN A YES
--
-- The pedestal's prompt asks for a QUOTE: what would be given up and what it
-- buys. Nothing is taken until the player answers that quote with its token
-- and a yes, and the answer is checked again from the top -- every rule, at the
-- moment of the answer, against the same Tool the quote was made for. It is
-- SELL ONE's shape (SellService) for SELL ONE's reason: what is given up cannot
-- be given back.
--
-- ONE QUOTE PER PLAYER. A new press replaces the old one. A quote is forgotten
-- on ANY answer, before anything else happens -- which is what makes a double
-- tap, a replayed answer and two answers in one frame find nothing to take --
-- and on a death, a new body, leaving, and after QuoteSeconds.
--
-- NOTHING OFF THE WIRE IS BELIEVED. The prompt carries no arguments, and an
-- answer carries a token and a yes; the pod, its tier, the player's place and
-- the clock are all read here. A prompt fired from across the map is refused
-- by distance at the quote, not only at the answer.
--
--==============================================================================
-- THE POD, THE CLOCK AND THE BOOST CHANGE TOGETHER, OR NOT AT ALL
--
-- In one resumption, with no yield anywhere in it:
--
--   1. the cooldown and the boost's expiry are written to the profile. This is
--      the one step that can refuse, so it comes first: a refusal here has
--      consumed nothing;
--   2. the pod is taken out of the hands, and its one row comes off the saved
--      bag (CarryService.SyncHeldNow, the only call that may shrink that
--      record);
--   3. the saved bag is COUNTED. One pod fewer, and the Tool is destroyed.
--      Anything else, and the exchange is undone where it stands: the clock
--      goes back to what it was and the pod goes back into the hands.
--
-- The clock and the bag live in the same profile, so they reach the DataStore
-- in the same write or in none. A save that fails, or a server that dies before
-- its next save, takes back the pod's removal AND the clock AND the cash the
-- boost earned, together: the player rejoins holding the pod, with no cooldown
-- running. No order of failures leaves a pod gone with nothing for it, or a
-- boost running on a pod that came back.
--
-- That is SELL ONE's rule and not the Bonus Chest's. The chest saves before it
-- confirms because its claim costs nothing, so an unsaved cooldown would be a
-- free boost on every rejoin. Here the price sits in the same record as the
-- clock.
--
-- NOT SAVED MEANS NOT OFFERED. A temporary profile keeps nothing, and a bag
-- that has not been put back yet is not evidence of what the player owns; both
-- are refused before a quote is made.
--
--==============================================================================
-- WHAT IT REACHES
--
-- EconomyService.RateFor asks Multiplier and nothing else does, so the boost
-- reaches passive garden income while the player is in the server -- and not a
-- sale, the offline claim, a wheel prize, a Biome Harvest, a cash pack or a
-- refund. It ADDS to a running Bonus Chest income reward before the x2 pass
-- multiplies: +25% and +50% are +75%, and the pass makes that x3.5.
--
-- THE TWO TIMES ARE WALL-CLOCK, like the chest's: a boost and a cooldown both
-- run on while the player is away, and a player who rejoins inside either
-- finds what is left of it.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local PlantService = require(script.Parent:WaitForChild("PlantService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local CONFIG = GameConfig.Sacrifice
local BALANCE = SeedData.Sacrifice
local ATTR = CONFIG.Attributes

local SacrificeService = {}
-- After PlayerDataService (20), CarryService (45) and PlantService (50), whose
-- answers it asks for.
SacrificeService.Priority = 64

-- The two clocks, as fields so a spec can hold them still: the wall clock the
-- profile's two times are written in, and the one a quote runs out by.
SacrificeService.Now = function(): number
	return os.time()
end
SacrificeService.Clock = function(): number
	return os.clock()
end

--==============================================================================
-- THE QUOTE ON THE TABLE, PER PLAYER
--
-- `tool` is the exact instance the quote was made for, and `pedestal` the part
-- the reach is measured to. `expires` is SacrificeService.Clock().
--==============================================================================
type Pending = {
	tool: Tool,
	token: number,
	tier: number,
	pedestal: BasePart,
	expires: number,
}
local pending: { [Player]: Pending } = {}
local nextToken = 0
local channel: RemoteEvent? = nil
local connections: { RBXScriptConnection } = {}
local bodyConnections: { [Player]: { RBXScriptConnection } } = {}
local generation = 0

local function log(message: string)
	print("[Seed/SacrificeService] " .. message)
end

--==============================================================================
-- WHAT THE FAUCET ASKS
--==============================================================================
function SacrificeService.Multiplier(player: Player): number
	if not CONFIG.Enabled then
		return 1
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return 1
	end
	return SeedData.sacrificeMultiplier(profile.SacrificeEndsAt, SacrificeService.Now())
end

--==============================================================================
-- THE ATTRIBUTES THE PEDESTAL'S UI DRAWS FROM
--
-- Written only on a change, from the tick and after every sacrifice, so a boost
-- ending is an attribute going nil in the same second the faucet stops paying
-- it. The multiplier travels with the expiry because the client's GameConfig
-- cannot read SeedData, and a number typed twice is a number that drifts.
--==============================================================================
local function put(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function publish(player: Player)
	if player.Parent ~= Players then
		return
	end
	local profile = PlayerDataService.Get(player)
	if not profile or not CONFIG.Enabled then
		put(player, ATTR.NextAt, nil)
		put(player, ATTR.EndsAt, nil)
		put(player, ATTR.Multiplier, nil)
		return
	end
	local boost = SeedData.sacrificeMultiplier(profile.SacrificeEndsAt, SacrificeService.Now())
	put(player, ATTR.NextAt, profile.SacrificeNextAt)
	put(player, ATTR.EndsAt, if boost > 1 then profile.SacrificeEndsAt else nil)
	put(player, ATTR.Multiplier, if boost > 1 then boost else nil)
end

--==============================================================================
-- WHAT MAY BE OFFERED, AND BY WHOM
--
-- One rule for the quote and for the answer, so they cannot disagree. Returns a
-- reason code when it refuses, or nil and the pod's tier. The codes are what
-- SacrificeUI turns into words; nothing reads one to decide anything.
--
--   DISABLED       the pedestal is switched off
--   GONE           no player, no body, or a dead one: not a player action
--   NOT_READY      the profile has not loaded
--   NOT_SAVED      a temporary profile, which could never keep the exchange
--   BAG_NOT_READY  the saved bag has not been put back into this body yet
--   COOLDOWN       the pedestal is still recharging for this player
--   TOO_FAR        not beside the pedestal
--   CARRYING       a raided pod in the arms: loot, not yet banked
--   NOTHING_HELD   empty hands
--   NOT_A_POD      a bat, a trap, or anything else that is not a plant Tool
--   HATCHED        a grown plant
--   NOT_OWNED      a pod Tool the saved bag has no row for
--   NO_GARDEN      no plot of their own, or nothing grown on it to boost
--
-- The saved bag is the test of OWNED AND BANKED. A pod becomes a row there by
-- crossing the red line, by a purchase or by a wheel prize, and in no other
-- way; the pod welded to a raider is a Model CarryService holds, never a Tool.
--==============================================================================
local function heldTool(player: Player): Tool?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Tool") else nil
end

local function isSavedPod(row: any, id: string, tier: number): boolean
	return type(row) == "table" and row.Id == id and row.Hatched ~= true
		and math.floor(tonumber(row.Tier) or 0) == tier
end

-- How many unhatched rows of this species and tier the saved bag holds.
local function savedPods(profile: any, id: string, tier: number): number
	local n = 0
	if type(profile.Held) == "table" then
		for _, row in ipairs(profile.Held) do
			if isSavedPod(row, id, tier) then
				n += 1
			end
		end
	end
	return n
end

local function podIn(tool: Tool): (string?, number?, string?)
	local id = tool:GetAttribute("SpeciesId")
	local tier = tonumber(tool:GetAttribute(GameConfig.Attributes.CarryingKg))
	if type(id) ~= "string" or SeedData.Get(id) == nil or not tier or tier ~= tier
		or tier ~= math.floor(tier) or tier < 1 or tier > SeedData.TierCount then
		return nil, nil, "NOT_A_POD"
	end
	if tool:GetAttribute("Hatched") == true then
		return nil, nil, "HATCHED"
	end
	return id, tier, nil
end

local function eligible(player: Player, tool: Tool?, pedestal: BasePart,
	now: number): (string?, number?)
	if not CONFIG.Enabled then
		return "DISABLED", nil
	end
	if player.Parent ~= Players then
		return "GONE", nil
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (character and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")) then
		return "GONE", nil
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return "NOT_READY", nil
	end
	if not PlayerDataService.IsPersistent(player) then
		return "NOT_SAVED", nil
	end
	if not CarryService.IsHeldRestored(player) then
		return "BAG_NOT_READY", nil
	end
	if now < profile.SacrificeNextAt then
		return "COOLDOWN", nil
	end
	if pedestal.Parent == nil
		or (root.Position - pedestal.Position).Magnitude > CONFIG.ReachStuds then
		return "TOO_FAR", nil
	end
	if CarryService.IsCarrying(player) then
		return "CARRYING", nil
	end
	if not tool or tool.Parent ~= character then
		return "NOTHING_HELD", nil
	end
	local id, tier, why = podIn(tool)
	if not (id and tier) then
		return why or "NOT_A_POD", nil
	end
	if savedPods(profile, id, tier) < 1 then
		return "NOT_OWNED", nil
	end
	local plot = PlotService.PlotOf(player)
	if not plot or PlotService.OwnerOf(plot) ~= player or #PlantService.GrownIn(plot) == 0 then
		return "NO_GARDEN", nil
	end
	return nil, tier
end

local function refusal(player: Player, reason: string, token: number?): { [string]: any }
	local profile = PlayerDataService.Get(player)
	return {
		phase = "refused",
		reason = reason,
		token = token,
		nextAt = if profile and reason == "COOLDOWN" then profile.SacrificeNextAt else nil,
	}
end

--==============================================================================
-- THE QUOTE
--
-- What the player is told says the pod's SIZE and nothing else about it. The
-- species stays where it is, on the Tool: a pod is a question until it hatches,
-- and giving one up does not answer it.
--==============================================================================
function SacrificeService.Quote(player: Player, pedestal: BasePart): { [string]: any }
	pending[player] = nil
	local tool = heldTool(player)
	local reason, tier = eligible(player, tool, pedestal, SacrificeService.Now())
	if reason or not tier or not tool then
		return refusal(player, reason or "NOTHING_HELD", nil)
	end
	nextToken += 1
	pending[player] = {
		tool = tool,
		token = nextToken,
		tier = tier,
		pedestal = pedestal,
		expires = SacrificeService.Clock() + CONFIG.QuoteSeconds,
	}
	return {
		phase = "quote",
		token = nextToken,
		tier = tier,
		multiplier = BALANCE.Multiplier,
		seconds = BALANCE.DurationSeconds,
		cooldown = BALANCE.CooldownSeconds,
	}
end

-- Rule 4: a token off the wire is a claim until it is a real, finite, whole,
-- positive number. NaN passes every comparison and would index nothing.
local function validToken(value: any): number?
	if type(value) ~= "number" or value ~= value then
		return nil
	end
	if value < 1 or value > 1e12 or math.floor(value) ~= value then
		return nil
	end
	return value
end

--==============================================================================
-- THE ANSWER
--
-- Returns what the client should be told, or nil for an answer that names no
-- quote of this player's -- a stale panel, a replay, a forgery -- which the
-- client has already closed by itself and which is worth no message.
--==============================================================================
function SacrificeService.Confirm(player: Player, payload: any): { [string]: any }?
	if type(payload) ~= "table" then
		return nil
	end
	local token = validToken(payload.token)
	if not token then
		return nil
	end
	local p = pending[player]
	if not p or p.token ~= token then
		return nil
	end
	-- Forgotten before anything else: a second answer finds no quote.
	pending[player] = nil

	if payload.accept ~= true then
		return { phase = "cancelled", token = token }
	end
	if SacrificeService.Clock() > p.expires then
		return refusal(player, "EXPIRED", token)
	end
	-- The same Tool, still in the same hands. `eligible` asks again; this is
	-- only so the player is told the right thing.
	if p.tool.Parent == nil or p.tool.Parent ~= player.Character then
		return refusal(player, "CHANGED", token)
	end
	local now = SacrificeService.Now()
	local reason, tier = eligible(player, p.tool, p.pedestal, now)
	if reason or not tier then
		return refusal(player, reason or "CHANGED", token)
	end
	-- The size the panel showed is the size that is taken.
	if tier ~= p.tier then
		return refusal(player, "CHANGED", token)
	end
	local profile = PlayerDataService.Get(player)
	local character = player.Character
	local id = p.tool:GetAttribute("SpeciesId")
	if not profile or not character or type(id) ~= "string" then
		return refusal(player, "NOT_READY", token)
	end

	--==========================================================================
	-- NO YIELD FROM HERE TO THE RETURN
	--
	-- The pod is taken OUT OF THE HANDS before its row comes off, because the
	-- sync below records whatever the hands still hold -- and it is DESTROYED
	-- only once the count says the row is gone. Until then every step can be
	-- walked back: the clock to what it was, the pod to the hands.
	--==========================================================================
	local had = savedPods(profile, id, tier)
	local oldNextAt, oldEndsAt = profile.SacrificeNextAt, profile.SacrificeEndsAt
	local nextAt = now + BALANCE.CooldownSeconds
	local endsAt = now + BALANCE.DurationSeconds
	if not PlayerDataService.SetSacrifice(player, nextAt, endsAt) then
		-- Nothing was written, so nothing is taken.
		warn(string.format("[Seed/SacrificeService] %s: the profile refused the clock; nothing was taken.",
			player.Name))
		return refusal(player, "FAILED", token)
	end
	local tool = p.tool
	tool.Parent = nil
	-- SyncHeldNow is the rule -- the only call that may shrink the saved bag --
	-- and the count after it is the proof. pcall, so a throw in there still
	-- reaches the count rather than leaving a clock running on a kept pod.
	local synced, syncError = pcall(CarryService.SyncHeldNow, player, { tool })
	if not synced then
		warn(string.format("[Seed/SacrificeService] %s: the bag sync threw: %s", player.Name,
			tostring(syncError)))
	end
	local left = savedPods(profile, id, tier)
	if left > had - 1 then
		warn(string.format("[Seed/SacrificeService] %s: the saved bag still holds %d of that pod after "
			.. "the sync; taking the row off directly.", player.Name, left))
		local kept = {}
		local taken = false
		for _, row in ipairs(profile.Held) do
			if not taken and isSavedPod(row, id, tier) then
				taken = true
			else
				table.insert(kept, row)
			end
		end
		PlayerDataService.SetHeld(player, kept)
		left = savedPods(profile, id, tier)
	end
	if left ~= had - 1 then
		-- The record does not say "one pod fewer", so the exchange did not
		-- happen: a row left behind would hand the pod back at the next respawn
		-- beside its boost. Everything goes back where it was.
		warn(string.format("[Seed/SacrificeService] %s: the saved bag holds %d of that pod where %d were "
			.. "expected; the sacrifice was undone.", player.Name, left, had - 1))
		PlayerDataService.SetSacrifice(player, oldNextAt, oldEndsAt)
		tool.Parent = character
		publish(player)
		return refusal(player, "FAILED", token)
	end
	tool:Destroy()

	publish(player)
	log(string.format("%s gave up a %d tier pod: +%d%% garden income for %ds, next in %ds.",
		player.Name, tier, math.floor((BALANCE.Multiplier - 1) * 100 + 0.5), BALANCE.DurationSeconds,
		BALANCE.CooldownSeconds))
	return {
		phase = "sacrificed",
		token = token,
		tier = tier,
		multiplier = BALANCE.Multiplier,
		seconds = BALANCE.DurationSeconds,
		endsAt = endsAt,
		nextAt = nextAt,
	}
end

-- For a test that wants to look: the token of the quote on the table, if any.
function SacrificeService.PendingFor(player: Player): number?
	local p = pending[player]
	return if p then p.token else nil
end

function SacrificeService.Forget(player: Player)
	pending[player] = nil
end

-- The attributes, on demand: a spec reads what the tick would publish a second
-- later.
SacrificeService.Publish = publish

--==============================================================================
-- THE PEDESTAL ITSELF
--
-- Primitive parts in the hub's own blocky plastic. Built into its own folder,
-- not the map's, because MapService destroys and rebuilds SeedMap and must not
-- be able to take the pedestal with it. PERSISTENT under streaming, so a player
-- across the field never meets a prompt that has not streamed in.
--
-- TWO SIGNS, FRONT AND BACK. The pedestal stands on the deck's rim with its
-- front to the hub, which puts its back to the road -- and the road is where a
-- player carrying a pod home walks in from. So the same three lines are
-- lettered on both sides of the column, like the chest's board and the plot
-- plaques.
--
-- A sign's first two lines are the server's, read off SeedData. Its third is
-- each player's own -- READY, or the time left -- and SacrificeUI writes that
-- on its own copy of both.
--==============================================================================
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame,
	color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Studs
	p.Parent = parent
	return p
end

-- Outlined, in the face every other board in the hub is lettered in, so the
-- words hold against the wood from across the deck.
local function letter(parent: Instance, name: string, position: UDim2, size: UDim2,
	text: string, colour: Color3, font: Enum.Font): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = colour
	label.TextScaled = true
	label.Font = font
	label.Parent = parent
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.new(0, 0, 0)
	edge.Thickness = 2
	edge.Parent = label
	return label
end

-- One board and its three lines, lettered on the face `cf` looks out of.
local function board(model: Model, name: string, cf: CFrame): Part
	local sign = part(model, name, Vector3.new(5, 1.7, 0.3), cf, Color3.fromRGB(163, 119, 73),
		Enum.Material.Wood)
	sign.CanCollide = false
	sign.TopSurface = Enum.SurfaceType.Smooth
	sign.BottomSurface = Enum.SurfaceType.Smooth

	local face = Instance.new("SurfaceGui")
	face.Name = "Face"
	face.Face = Enum.NormalId.Front
	face.CanvasSize = Vector2.new(500, 170)
	-- Its own light, so it reads the same at night; gone beyond the hub.
	face.LightInfluence = 0
	face.MaxDistance = 90
	face.Active = false
	face.Parent = sign
	local gold = Color3.fromRGB(255, 214, 92)
	local cream = Color3.fromRGB(248, 235, 190)
	letter(face, "Title", UDim2.fromScale(0.04, 0.04), UDim2.fromScale(0.92, 0.34),
		"SACRIFICE A POD", gold, Enum.Font.LuckiestGuy)
	letter(face, "Offer", UDim2.fromScale(0.04, 0.4), UDim2.fromScale(0.92, 0.24),
		string.format("+%d%% GARDEN INCOME FOR %ds",
			math.floor((BALANCE.Multiplier - 1) * 100 + 0.5), BALANCE.DurationSeconds), cream,
		Enum.Font.GothamBold)
	-- Each player's own line. Empty here; SacrificeUI fills its own copy.
	letter(face, "Status", UDim2.fromScale(0.04, 0.66), UDim2.fromScale(0.92, 0.3), "", cream,
		Enum.Font.LuckiestGuy)
	return sign
end

local function build(): BasePart?
	local old = Workspace:FindFirstChild(CONFIG.FolderName)
	if old then
		old:Destroy()
	end
	if not CONFIG.Enabled then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = CONFIG.FolderName
	folder.Archivable = false
	local model = Instance.new("Model")
	model.Name = "SacrificePedestal"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = folder

	-- -Z is the pedestal's front: the side its sign faces.
	local origin = CFrame.new(CONFIG.Position) * CFrame.Angles(0, math.rad(CONFIG.FacingDegrees), 0)
	local stone = Color3.fromRGB(83, 83, 76)
	local moss = Color3.fromRGB(91, 151, 76)
	part(model, "Foot", Vector3.new(5, 0.5, 5), origin * CFrame.new(0, 0.25, 0), stone,
		Enum.Material.Slate)
	part(model, "Column", Vector3.new(3, 2.4, 3), origin * CFrame.new(0, 1.65, 0), stone,
		Enum.Material.Slate)
	local top = part(model, "OfferingBowl", Vector3.new(4.5, 0.5, 4.5),
		origin * CFrame.new(0, 3.1, 0), moss, Enum.Material.Grass)
	part(model, "Recess", Vector3.new(2.1, 0.15, 2.1), origin * CFrame.new(0, 3.42, 0),
		Color3.fromRGB(43, 65, 42), Enum.Material.Slate).CanCollide = false
	-- On the column's front, and turned about on its back.
	board(model, "Sign", origin * CFrame.new(0, 1.85, -1.68))
	board(model, "SignBack", origin * CFrame.new(0, 1.85, 1.68) * CFrame.Angles(0, math.pi, 0))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SacrificePrompt"
	-- Custom, so PromptUI draws it in the same chrome as every other prompt.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Sacrifice"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	-- Held a moment, like the chest's: walking past with E down is not a
	-- decision. The decision itself is the panel's.
	prompt.HoldDuration = CONFIG.PromptHoldSeconds
	prompt.MaxActivationDistance = CONFIG.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = top
	model.PrimaryPart = top

	table.insert(connections, prompt.Triggered:Connect(function(player: Player)
		local answer = SacrificeService.Quote(player, top)
		local remote = channel
		if remote and player.Parent == Players then
			remote:FireClient(player, CONFIG.ServerAction, answer)
		end
	end))

	folder.Parent = Workspace
	return top
end

--==============================================================================
-- A QUOTE DOES NOT OUTLIVE THE BODY IT WAS MADE FOR
--==============================================================================
local function release(player: Player)
	local held = bodyConnections[player]
	if held then
		for _, c in ipairs(held) do
			c:Disconnect()
		end
		bodyConnections[player] = nil
	end
end

local function watch(player: Player)
	release(player)
	local held: { RBXScriptConnection } = {}
	bodyConnections[player] = held
	local function body(character: Model)
		pending[player] = nil
		local humanoid = character:FindFirstChildOfClass("Humanoid")
			or character:WaitForChild("Humanoid", 5)
		if humanoid and humanoid:IsA("Humanoid") and bodyConnections[player] == held then
			table.insert(held, humanoid.Died:Connect(function()
				pending[player] = nil
			end))
		end
	end
	table.insert(held, player.CharacterAdded:Connect(function(character)
		task.spawn(body, character)
	end))
	table.insert(held, player.CharacterRemoving:Connect(function()
		pending[player] = nil
	end))
	if player.Character then
		task.spawn(body, player.Character)
	end
end

-- The watchers Start connects, by name, so a spec can put a stand-in player's
-- body under the same watch a real one gets.
SacrificeService.Watch = watch
SacrificeService.Unwatch = release

--==============================================================================
-- LIFECYCLE
--==============================================================================
function SacrificeService.Init()
	generation += 1
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for player in pairs(bodyConnections) do
		release(player)
	end
	table.clear(pending)
	channel = nil
end

function SacrificeService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil
	local remote = channel
	if remote then
		table.insert(connections, remote.OnServerEvent:Connect(
			function(player: Player, action: any, payload: any)
				if action ~= CONFIG.ClientAction then
					return
				end
				local answer = SacrificeService.Confirm(player, payload)
				if answer and answer.phase ~= "cancelled" and player.Parent == Players then
					remote:FireClient(player, CONFIG.ServerAction, answer)
				end
			end))
	else
		warn("[Seed/SacrificeService] No GameEvent remote; the pedestal cannot answer.")
	end

	table.insert(connections, Players.PlayerAdded:Connect(watch))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
		pending[player] = nil
		release(player)
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end

	local top = build()
	generation += 1
	local mine = generation
	task.spawn(function()
		while mine == generation do
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(publish, player)
			end
			task.wait(1)
		end
	end)

	if top then
		log(string.format("Ready. The pedestal stands at (%.0f, %.0f, %.0f): one banked pod for +%d%% "
			.. "garden income for %ds, every %ds.", top.Position.X, top.Position.Y, top.Position.Z,
			math.floor((BALANCE.Multiplier - 1) * 100 + 0.5), BALANCE.DurationSeconds,
			BALANCE.CooldownSeconds))
	else
		log("Ready. The pedestal is SWITCHED OFF (GameConfig.Sacrifice.Enabled = false).")
	end
end

function SacrificeService.Stop()
	SacrificeService.Init()
	local old = Workspace:FindFirstChild(CONFIG.FolderName)
	if old then
		old:Destroy()
	end
end

return SacrificeService
