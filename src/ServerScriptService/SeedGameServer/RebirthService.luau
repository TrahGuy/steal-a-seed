--!strict
--==============================================================================
-- Steal a Seed :: RebirthService (2026-10-08)
--
-- The owner: "rebirth first, cash and mill tier reset, plan it" / "we should
-- also do a fence upgrade every rebirth and a title above the name" / "use
-- your defaults".
--
-- THE ONLY THING THAT DOES A REBIRTH. Shared/Rebirth is the rulebook; this
-- reads the player's state, asks it, and acts:
--
--   THE SHRINE   built here, off the deck's north-east rim, Persistent. Its
--                prompt asks for a QUOTE -- the numbers RebirthUI's panel
--                shows, with a one-use token -- and nothing else.
--   THE CONFIRM  the panel's second press sends that token back. Checked
--                again from scratch (the quote is only a promise of what was
--                true), then, with no yield between the check and the last
--                write: all cash spent, the mill back to tier 1 and rebuilt,
--                the count up, the fence and the title redone. Then saved at
--                once. A token works once, a rebirth starts a cooldown and a
--                busy flag spans the save -- so no double rebirth from a double
--                press, a lagging client or a replayed packet.
--   KEPT         everything else: Speed, the plot's level, every plant, pods,
--                weapons, spin tickets, the Speed milestones, the Index, passes,
--                running boosts. Nothing here touches them.
--   THE FENCE    the plot OWNER's rebirths dress their fence: colours,
--                materials and caps nothing can touch. Never a board, a post
--                or the gap filler's size, place or collision.
--   THE TITLE    on the Head like OwnerTitleService's ADMIN; ADMIN on top when
--                a player has both.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Rebirth = require(Shared:WaitForChild("Rebirth"))
local FenceStyle = require(Shared:WaitForChild("FenceStyle"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))
local Notice = require(Shared:WaitForChild("Notice"))
local RebirthCelebration = require(Shared:WaitForChild("RebirthCelebration"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local StoreService = require(script.Parent:WaitForChild("StoreService"))

local CFG = GameConfig.Rebirth
local TITLE = CFG.Title
local ATTR = GameConfig.Attributes
local OFFLINE = GameConfig.OfflineEarnings.Attributes

local RebirthService = {}
-- After PlayerDataService, PlotService, TreadmillService, CarryService,
-- StoreService and OwnerTitleService (96), whose ADMIN this stacks under.
RebirthService.Priority = 97

-- What the outside world is, swappable by a spec.
RebirthService.Hooks = {
	now = os.time,
	clock = os.clock,
	-- Sends one answer to one player.
	reply = function(_player: Player, _payload: { [string]: any }) end,
	-- Sends one GameEvent message to one player: the celebration and the line
	-- for everybody else (2026-10-09).
	send = function(_player: Player, _action: string, _payload: { [string]: any }) end,
	-- Everybody in the server.
	players = function(): { Player }
		return Players:GetPlayers()
	end,
	-- How far the player's root is from the shrine, in studs (math.huge when
	-- there is no body or no shrine).
	distance = function(_player: Player): number
		return math.huge
	end,
}

type Quote = { token: number, at: number }
local quotes: { [Player]: Quote } = {}
local busy: { [Player]: boolean } = {}
local nextToken = 0
local shrineTop: BasePart? = nil
local connections: { RBXScriptConnection } = {}
local unsubscribe: { () -> () } = {}
local playerConnections: { [Player]: { RBXScriptConnection } } = {}

local function log(message: string)
	print("[Seed/RebirthService] " .. message)
end

local function rebirthsOf(player: Player?): number
	local profile = player and PlayerDataService.Get(player)
	return GameConfig.rebirthCount(profile and (profile :: any).Rebirths)
end

--==============================================================================
-- THE STATE A REBIRTH IS DECIDED ON, read fresh every time
--==============================================================================
function RebirthService.StateOf(player: Player): Rebirth.State
	local profile = PlayerDataService.Get(player) :: any
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local pursued = player:GetAttribute(ATTR.PursuedBy)
	local offline = tonumber(player:GetAttribute(OFFLINE.Cash))
	return {
		enabled = CFG.Enabled,
		ready = PlayerDataService.IsReady(player) and profile ~= nil,
		now = RebirthService.Hooks.now(),
		lastAt = if profile then GameConfig.rebirthCount(profile.RebirthAt) else 0,
		rebirths = if profile then GameConfig.rebirthCount(profile.Rebirths) else 0,
		cash = if profile then tonumber(profile.Cash) or 0 else 0,
		millTier = if profile then tonumber(profile.MillTier) or 1 else 1,
		dead = humanoid == nil or humanoid.Health <= 0,
		carrying = CarryService.IsCarrying(player),
		chased = pursued ~= nil and pursued ~= "" and pursued ~= 0,
		offline = offline ~= nil and offline > 0,
		busy = busy[player] == true or StoreService.Deciding(player),
	}
end

--==============================================================================
-- THE QUOTE: what the panel shows, and a token to confirm it with
--==============================================================================
function RebirthService.Quote(player: Player): { [string]: any }
	local state = RebirthService.StateOf(player)
	local why = Rebirth.check(state)
	nextToken += 1
	quotes[player] = { token = nextToken, at = RebirthService.Hooks.clock() }
	local n = state.rebirths
	local minTier, minName = Rebirth.millNeeded()
	return {
		verb = "quote",
		token = nextToken,
		ok = why == nil,
		why = why,
		words = if why then Rebirth.refusal(why, n) else nil,
		rebirths = n,
		price = Rebirth.nextPrice(n),
		cash = state.cash,
		millTier = state.millTier,
		millName = (GameConfig.Mill.Tiers[state.millTier] or GameConfig.Mill.Tiers[1]).name,
		minTier = minTier,
		minName = minName,
		training = Rebirth.training(n),
		income = Rebirth.income(n),
		nextTraining = Rebirth.training(n + 1),
		nextIncome = Rebirth.income(n + 1),
	}
end

--==============================================================================
-- THE OWNER'S FENCE (dressed by Shared/FenceStyle, which RebirthUI's preview
-- of the next tier uses too)
--==============================================================================
-- Dresses one plot's fence for an owner reborn `rebirths` times (0: the wood
-- it was built in). Only the boards' and posts' colour and material change;
-- the caps are new parts nothing can touch. Answers the tier it dressed.
function RebirthService.DressFence(plot: Model, rebirths: number): number
	local F = CFG.Fence
	local old = plot:FindFirstChild(F.FolderName)
	if old then
		old:Destroy()
	end
	local rails: { BasePart } = {}
	local posts: { BasePart } = {}
	for _, child in ipairs(plot:GetChildren()) do
		if child:IsA("BasePart") then
			if child.Name == "Rail" then
				table.insert(rails, child)
			elseif child.Name == "Post" then
				table.insert(posts, child)
			end
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = F.FolderName
	local tier, capped = FenceStyle.dress(rails, posts, folder, rebirths)
	plot:SetAttribute("FenceTier", tier)
	if capped then
		folder.Parent = plot
	else
		folder:Destroy()
	end
	return tier
end

local function dressOwnersFence(player: Player)
	local plot = PlotService.PlotOf(player)
	if plot and PlotService.OwnerOf(plot) == player then
		RebirthService.DressFence(plot, rebirthsOf(player))
	end
end

--==============================================================================
-- THE TITLE OVER THE NAME
--==============================================================================
local function clearTitle(character: Instance)
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Name == TITLE.Name then
			d:Destroy()
		end
	end
end

-- ADMIN sits over a rebirth title when a character has both, whichever was
-- built first (OwnerTitleService asks the same question).
local function restackAdmin(head: Instance)
	local admin = head:FindFirstChild(GameConfig.OwnerTitle.Name)
	if admin and admin:IsA("BillboardGui") then
		admin.SizeOffset = Vector2.new(0, GameConfig.ownerTitleLift(head:FindFirstChild(TITLE.Name) ~= nil))
	end
end

local function line(parent: Instance, name: string, text: string, colour: Color3, font: Enum.Font, size: number,
	position: UDim2, box: UDim2, thickness: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = box
	label.Font = font
	label.TextSize = size
	label.TextColor3 = colour
	label.Text = text
	label.Active = false
	label.Parent = parent
	local edge = Instance.new("UIStroke")
	edge.Color = FloatingSign.Outline
	edge.Thickness = thickness
	edge.Parent = label
	return label
end

-- Builds (or clears) a character's rebirth title. Answers it, or nil.
function RebirthService.ApplyTitle(player: Player, character: Instance): BillboardGui?
	clearTitle(character)
	local head = character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return nil
	end
	local n = rebirthsOf(player)
	-- The step's words with the numeral for where the count is inside it.
	local text, step = Rebirth.titleFor(n)
	if not (text and step) then
		restackAdmin(head)
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = TITLE.Name
	gui.Size = UDim2.fromOffset(TITLE.Size.X, TITLE.Size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, TITLE.Rise, 0)
	gui.SizeOffset = Vector2.new(0, TITLE.Lift)
	gui.MaxDistance = TITLE.MaxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Active = false
	gui.Adornee = head
	-- Six tenths for the words, four for REBIRTH N: room for both at 1 and at
	-- a phone's PhoneScale, where REBIRTH N keeps SubMinTextSize (OwnerTitleUI
	-- redraws the sizes there; this box splits the same way).
	local words = line(gui, "Words", text, step.Colour, Enum.Font.FredokaOne, TITLE.TextSize,
		UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.6), 3)
	line(gui, "Sub", string.format(TITLE.Sub, n), Color3.fromRGB(255, 244, 226), Enum.Font.GothamBold,
		TITLE.SubTextSize, UDim2.fromScale(0, 0.6), UDim2.fromScale(1, 0.4), 2)
	if step.Rainbow then
		-- The top of the ladder turns like ADMIN's (OwnerTitleUI; still for
		-- reduced motion).
		local fill = Instance.new("UIGradient")
		fill.Name = "Rainbow"
		fill.Color = WheelDraw.rainbow(0)
		fill.Parent = words
	end
	CollectionService:AddTag(gui, TITLE.Tag)
	gui.Parent = head
	restackAdmin(head)
	return gui
end

--==============================================================================
-- THE CELEBRATION, FOR EVERYBODY ELSE (2026-10-09, GameConfig.Rebirth
-- .Celebration)
--
-- The reborn player's own screen plays it from the "done" answer. Everybody
-- whose body is within Range of theirs is sent "celebrate" -- RebirthUI draws
-- the column, the orbs and the burst round that body and plays the fanfare
-- from it -- and everybody else in the server, near or not, reads one line in
-- the notice stack ("Pat reached REBIRTH 6 · BOTANIST II!", quiet: the moment
-- made its own sound). The reborn player gets no line: the card says it. Sends
-- only, nothing yields. Answers how many were shown it and how many were told.
--==============================================================================
local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

function RebirthService.Celebrate(player: Player, after: number): (number, number)
	local origin = rootPosition(player)
	local name = (player :: any).DisplayName
	if type(name) ~= "string" or name == "" then
		name = player.Name
	end
	local line = RebirthCelebration.serverLine(name, after)
	local seen, told = 0, 0
	for _, other in ipairs(RebirthService.Hooks.players()) do
		if other ~= player then
			if RebirthCelebration.near(origin, rootPosition(other), CFG.Celebration.Range) then
				RebirthService.Hooks.send(other, CFG.Action, {
					verb = "celebrate",
					userId = player.UserId,
					rebirths = after,
				})
				seen += 1
			end
			RebirthService.Hooks.send(other, Notice.ServerNotice, {
				title = line,
				key = string.format("rebirth:%d:%d", player.UserId, after),
				icon = "rebirth",
				quiet = true,
			})
			told += 1
		end
	end
	return seen, told
end

--==============================================================================
-- THE CONFIRM
--==============================================================================
local function refuse(player: Player, why: string, n: number)
	RebirthService.Hooks.reply(player, { verb = "refused", why = why, words = Rebirth.refusal(why, n) })
end

-- Answers true when the rebirth happened. The reply goes to the player either
-- way.
function RebirthService.Confirm(player: Player, payload: any): boolean
	local quote = quotes[player]
	local token = if type(payload) == "table" then payload.token else nil
	local n = rebirthsOf(player)
	if not quote or token ~= quote.token or RebirthService.Hooks.clock() - quote.at > CFG.QuoteSeconds then
		refuse(player, "QUOTE", n)
		return false
	end
	if RebirthService.Hooks.distance(player) > CFG.CloseDistance then
		refuse(player, "FAR", n)
		return false
	end
	local state = RebirthService.StateOf(player)
	local why = Rebirth.check(state)
	if why then
		refuse(player, why, n)
		return false
	end
	-- From here to the save nothing yields: the check above is still true.
	quotes[player] = nil
	busy[player] = true
	local profile = PlayerDataService.Get(player) :: any
	local spent = tonumber(profile.Cash) or 0
	-- Off the belt first, so the rebuilt mill never has a rider standing in it.
	TreadmillService.Unmount(player)
	PlayerDataService.AddCash(player, -spent)
	PlayerDataService.SetMillTier(player, 1)
	local plot = PlotService.PlotOf(player)
	if plot and PlotService.OwnerOf(plot) == player then
		TreadmillService.Rebuild(plot, 1)
	end
	local now = RebirthService.Hooks.now()
	PlayerDataService.UpdateRebirth(player, function(p: any)
		p.Rebirths = GameConfig.rebirthCount(p.Rebirths) + 1
		p.RebirthAt = now
		return true
	end)
	local after = rebirthsOf(player)
	dressOwnersFence(player)
	local character = player.Character
	if character then
		RebirthService.ApplyTitle(player, character)
	end
	log(string.format("%s was reborn: rebirth %d, spent %s; training x%s, income x%s.", player.Name, after,
		GameConfig.compact(spent), Rebirth.times(Rebirth.training(after)), Rebirth.times(Rebirth.income(after))))
	-- Saved at once, and the busy flag holds through it.
	local ok, saved = pcall(PlayerDataService.Save, player)
	busy[player] = nil
	RebirthService.Hooks.reply(player, {
		verb = "done",
		rebirths = after,
		training = Rebirth.training(after),
		income = Rebirth.income(after),
		saved = ok and saved == true,
	})
	-- Then everybody else (after the save, and nothing here yields): the
	-- celebration round this body for those near, one line for the server.
	local sent, seen, told = pcall(RebirthService.Celebrate, player, after)
	if sent then
		log(string.format("%s's celebration: shown to %d nearby, the line to %d.", player.Name, seen, told))
	else
		warn("[Seed/RebirthService] the celebration was not sent: " .. tostring(seen))
	end
	return true
end

--==============================================================================
-- THE SHRINE
--==============================================================================
local function block(model: Instance, name: string, size: Vector3, cframe: CFrame, colour: Color3,
	material: Enum.Material, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = cframe
	part.Color = colour
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function buildShrine(): BasePart?
	local old = Workspace:FindFirstChild(CFG.FolderName)
	if old then
		old:Destroy()
	end
	if not CFG.Enabled then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = CFG.FolderName
	folder.Archivable = false
	local model = Instance.new("Model")
	model.Name = "RebirthShrine"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = folder
	-- Facing the square: -Z, its front, looks at the hub's middle.
	local at = CFG.Position
	local origin = CFrame.lookAt(at, Vector3.new(0, at.Y, 0))
	local stone = Color3.fromRGB(96, 92, 104)
	local rose = CFG.Look.Band
	local deep = CFG.Look.Edge
	local cylinder = CFrame.Angles(0, 0, math.rad(90))
	block(model, "Base", Vector3.new(1, 11, 11), origin * CFrame.new(0, 0.5, 0) * cylinder, stone,
		Enum.Material.Slate, Enum.PartType.Cylinder)
	block(model, "Step", Vector3.new(1, 8, 8), origin * CFrame.new(0, 1.5, 0) * cylinder, deep,
		Enum.Material.Slate, Enum.PartType.Cylinder)
	block(model, "Column", Vector3.new(2.6, 3, 2.6), origin * CFrame.new(0, 3.5, 0), stone, Enum.Material.Slate)
	local top = block(model, "Altar", Vector3.new(4, 0.6, 4), origin * CFrame.new(0, 5.3, 0), deep, Enum.Material.Slate)
	-- Four short pillars on the step's rim, each lit by a small flame of the
	-- band's colour.
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local p = origin * CFrame.new(math.cos(a) * 3.3, 0, math.sin(a) * 3.3)
		block(model, "Pillar", Vector3.new(0.9, 3.4, 0.9), p * CFrame.new(0, 3.7, 0), stone, Enum.Material.Slate)
		local flame = block(model, "Flame", Vector3.new(0.7, 0.7, 0.7), p * CFrame.new(0, 5.7, 0), rose,
			Enum.Material.Neon, Enum.PartType.Ball)
		flame.CanCollide = false
		flame.CanQuery = false
	end
	-- The seed of a new life, glowing over the altar.
	local seed = block(model, "Seed", Vector3.new(2.2, 2.2, 2.2), origin * CFrame.new(0, 7.1, 0), rose,
		Enum.Material.Neon, Enum.PartType.Ball)
	seed.CanCollide = false
	seed.CanQuery = false
	local light = Instance.new("PointLight")
	light.Color = rose
	light.Range = 14
	light.Brightness = 1.4
	light.Shadows = false
	light.Parent = seed

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RebirthPrompt"
	-- Custom, so PromptUI draws it in the same chrome as every other prompt.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = CFG.Words.Prompt
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	-- Held a moment: walking past with E down is not a decision. The decision
	-- is the panel's, and it asks twice.
	prompt.HoldDuration = CFG.PromptHoldSeconds
	prompt.MaxActivationDistance = CFG.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = top
	model.PrimaryPart = top
	table.insert(connections, prompt.Triggered:Connect(function(player: Player)
		RebirthService.Hooks.reply(player, RebirthService.Quote(player))
	end))
	folder.Parent = Workspace
	return top
end

--==============================================================================
-- PLAYERS
--==============================================================================
local function watch(player: Player)
	local held: { RBXScriptConnection } = {}
	playerConnections[player] = held
	local function onCharacter(character: Model)
		-- Never waited for in Start: the Head comes a moment after the body.
		task.spawn(function()
			local head = character:WaitForChild("Head", 10)
			if head and character.Parent and player.Character == character then
				RebirthService.ApplyTitle(player, character)
			end
		end)
	end
	table.insert(held, player.CharacterAdded:Connect(onCharacter))
	-- The count arrives with the save, after the first body: the title and the
	-- fence follow it.
	table.insert(held, player:GetAttributeChangedSignal(CFG.Attributes.Rebirths):Connect(function()
		local character = player.Character
		if character then
			RebirthService.ApplyTitle(player, character)
		end
		dressOwnersFence(player)
	end))
	if player.Character then
		onCharacter(player.Character)
	end
end

local function forget(player: Player)
	quotes[player] = nil
	busy[player] = nil
	for _, c in ipairs(playerConnections[player] or {}) do
		c:Disconnect()
	end
	playerConnections[player] = nil
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function RebirthService.Init()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, stop in ipairs(unsubscribe) do
		stop()
	end
	table.clear(unsubscribe)
	for player in pairs(playerConnections) do
		forget(player)
	end
	table.clear(quotes)
	table.clear(busy)
	-- A re-run leaves no title behind.
	for _, gui in ipairs(CollectionService:GetTagged(TITLE.Tag)) do
		gui:Destroy()
	end
end

function RebirthService.Start()
	local folder = Shared.Parent:FindFirstChild("Remotes")
	local remote = folder and folder:FindFirstChild(GameConfig.Remotes.GameEvent)
	if remote and remote:IsA("RemoteEvent") then
		local channel = remote :: RemoteEvent
		RebirthService.Hooks.reply = function(player: Player, payload: { [string]: any })
			if player.Parent == Players then
				channel:FireClient(player, CFG.Action, payload)
			end
		end
		RebirthService.Hooks.send = function(player: Player, action: string, payload: { [string]: any })
			if player.Parent == Players then
				channel:FireClient(player, action, payload)
			end
		end
		table.insert(connections, channel.OnServerEvent:Connect(function(player: Player, action: any, verb: any,
			payload: any)
			if action == CFG.Action and verb == "confirm" then
				RebirthService.Confirm(player, payload)
			end
		end))
	else
		warn("[Seed/RebirthService] no GameEvent remote: rebirth is off.")
	end
	shrineTop = buildShrine()
	RebirthService.Hooks.distance = function(player: Player): number
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local altar = shrineTop
		if not (root and root:IsA("BasePart") and altar and altar.Parent) then
			return math.huge
		end
		return (root.Position - altar.Position).Magnitude
	end
	-- The fence follows the plot: dressed for its new owner, undressed when
	-- they leave, redressed whenever the plot is rebuilt at a new size.
	table.insert(unsubscribe, PlotService.OnAssigned(function(player: Player, plot: Model)
		RebirthService.DressFence(plot, rebirthsOf(player))
	end))
	table.insert(unsubscribe, PlotService.OnReleased(function(_player: Player, plot: Model)
		RebirthService.DressFence(plot, 0)
	end))
	table.insert(unsubscribe, PlotService.OnResized(function(_player: Player, plot: Model)
		local owner = PlotService.OwnerOf(plot)
		RebirthService.DressFence(plot, if owner then rebirthsOf(owner) else 0)
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	table.insert(connections, Players.PlayerAdded:Connect(watch))
	table.insert(connections, Players.PlayerRemoving:Connect(forget))
	log(string.format("Ready. Rebirth 1 costs %s and needs the %s mill; +%d%% training and +%d%% income each.",
		GameConfig.compact(Rebirth.priceFor(1)), select(2, Rebirth.millNeeded()), CFG.TrainingPer * 100,
		CFG.IncomePer * 100))
end

return RebirthService
