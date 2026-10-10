--!strict
-- Steal a Seed :: SellService
--
--==============================================================================
-- TWO BOARDS AT MARIGOLD'S STALL
--
-- SELL ALL, off the left end of the stall: one sign, one prompt, one held press,
-- and a confirmation for the whole bag -- how many plants, how many pods, what
-- they pay -- before anything becomes cash (since 2026-09-24; it used to sell
-- on the hold). SELL ONE, off the right end: one sign, one tap, and a
-- confirmation for the ONE plant in the player's hands. The money
-- itself is not minted here -- EconomyService.SellHeld and EconomyService.SellOne
-- do that, because Rule 6 says cash mints in one file and a stall is not an
-- exception to it. This service owns the FURNITURE, the prompts and the server
-- half of the confirmation, nothing else.
--
--==============================================================================
-- WHY THIS IS ITS OWN SERVICE AND NOT A FEW LINES IN MapService
--
-- MapService builds the stall, so the sign would naturally go there -- and
-- MapService and ShopUI are the two files the shop pass is most likely to be
-- editing right now. A sign dropped into the middle of either is a merge
-- conflict waiting to happen over something that has no reason to live there.
--
-- So it goes where NestService already showed a prop with BEHAVIOUR can go: its
-- own service, finding the map's marker at Start and building beside it. The
-- map stays geometry; this stays a transaction.
--
--==============================================================================
-- SELL ONE IS A QUOTE, THEN AN ANSWER
--
-- The prompt fires on the SERVER -- ProximityPrompt.Triggered is a server
-- signal -- so the server is what looks in the player's hands, prices what it
-- finds through EconomyService.QuoteOne, and tells the client what it would
-- pay, with a token that names THIS quote for THIS Tool instance. The client
-- shows that and answers yes or no by token. Nothing the client sends decides
-- what is sold or for how much: the Tool was captured here when the quote was
-- made, the price is recomputed from that same Tool when the answer comes, and
-- a token can only name the quote it was minted for.
--
-- ONE QUOTE PER PLAYER. A new press replaces the old quote, so a stale panel's
-- token is refused. A quote is also forgotten on death, on leaving, on a no,
-- on ANY answer, and after QuoteSeconds -- and the sale itself re-checks that
-- the Tool is still in the player's hands and the player is still at the board.
-- Forgetting BEFORE selling is what makes a double tap or a replayed answer
-- find nothing to sell.
--
--==============================================================================
-- SAFE TO RE-RUN
--
-- Rule 10. MapService destroys and rebuilds SeedMap, and the plugin rebuilds it
-- in Edit whenever it goes missing, so this has to survive being started against
-- a map that already has a sign standing in it. It destroys its own first.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local SellService = {}

-- After EconomyService (55), which it calls, and after the map is long built.
SellService.Priority = 65

local SIGN_NAME = "SellAllSign"
local ONE_SIGN_NAME = "SellOneSign"
local SELL_ONE = GameConfig.SellOne

-- Studs. A board stands off either end of the 24-wide stall floor, clear of
-- the counter so a player reading it is not standing where Marigold serves:
-- SELL ALL off the left end, SELL ONE off the right, mirrored through the
-- stall's own frame so they move together when the stall does (it did on
-- 2026-10-10: GameConfig.Map.Stall, which holds these numbers now).
local STALL = GameConfig.Map.Stall
local SIDE_OFFSET = STALL.BoardSide
local FRONT_OFFSET = STALL.BoardFront

local POST_HEIGHT = 5.2
local BOARD_SIZE = Vector3.new(7.2, 3.0, 0.4)

local WOOD = Color3.fromRGB(120, 84, 52)
local BOARD_FACE = Color3.fromRGB(238, 226, 196)
local INK = Color3.fromRGB(58, 44, 32)
local COIN = Color3.fromRGB(250, 198, 48)

local connections: { RBXScriptConnection } = {}
local playerConns: { [Player]: RBXScriptConnection } = {}

--==============================================================================
-- THE QUOTE ON THE TABLE, PER PLAYER
--
-- `tool` is the exact instance the quote was made for. `board` is the sign it
-- was made at, for the reach check. `expires` is os.clock().
--==============================================================================
type Pending = {
	tool: Tool,
	token: number,
	price: number,
	speciesId: string,
	tier: number,
	board: BasePart,
	expires: number,
}
local pending: { [Player]: Pending } = {}
local nextToken = 0
local channel: RemoteEvent? = nil

--==============================================================================
-- THE SELL ALL QUOTE ON THE TABLE, PER PLAYER
--
-- `tools` is the exact set of Tool instances the count and the payout were
-- made from; the sale goes ahead only if the bag still holds exactly those and
-- they still pay exactly `total`. A second table rather than a field on
-- Pending, so SELL ONE's quote keeps the shape its own code and spec rely on --
-- but still ONE QUOTE PER PLAYER: making either quote drops the other.
--==============================================================================
type PendingAll = {
	token: number,
	tools: { [Tool]: boolean },
	count: number,
	total: number,
	board: BasePart,
	expires: number,
}
local pendingAll: { [Player]: PendingAll } = {}
local SELL_ALL = GameConfig.SellAll

local function log(message: string)
	print("[Seed/SellService] " .. message)
end

local function part(name: string, size: Vector3, cf: CFrame, color: Color3,
	parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Studs
	p.Parent = parent
	return p
end

--==============================================================================
-- LETTERED ON BOTH FACES
--
-- The same lesson the mill sign and the biome arches both landed on: a player
-- walking up from the road and a player leaving the stall are looking at
-- opposite sides of the same board, and a blank back reads as scenery.
--==============================================================================
local function face(board: BasePart, which: Enum.NormalId, titleText: string, subText: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face"
	gui.Face = which
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 64
	gui.AlwaysOnTop = false
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.52)
	title.Position = UDim2.fromScale(0, 0.06)
	title.Font = Enum.Font.GothamBlack
	title.Text = titleText
	title.TextColor3 = INK
	title.TextScaled = true
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.fromScale(1, 0.3)
	sub.Position = UDim2.fromScale(0, 0.6)
	sub.Font = Enum.Font.GothamMedium
	-- The price is stated rather than implied. A player who cannot work out
	-- what they are about to be paid will read any number as a bad deal.
	sub.Text = subText
	sub.TextColor3 = INK
	sub.TextScaled = true
	sub.TextTransparency = 0.25
	sub.Parent = gui
end

local function findStall(): BasePart?
	local map = Workspace:FindFirstChild("SeedMap")
	if not map then
		return nil
	end
	local floor = map:FindFirstChild("StallFloor", true)
	return if floor and floor:IsA("BasePart") then floor else nil
end

-- One board, the same furniture whichever end it stands at. `side` is -1 for
-- the left end of the stall (SELL ALL) and +1 for the right (SELL ONE).
local function build(stall: BasePart, name: string, side: number, titleText: string,
	subText: string): Model
	local model = Instance.new("Model")
	model.Name = name
	-- Parented up front so the ground cast below can exclude it; the parts are
	-- added after, so there is nothing to hit yet either way.
	model.Parent = stall.Parent

	--==========================================================================
	-- FACING THE PEOPLE, NOT THE STALL
	--
	-- Toward the point BoardFocus studs in front of the stall's middle (Map
	-- .Stall), so each board looks at the customers from its end, turned in a
	-- little. Until 2026-10-10 that point was the deck's centre, which stood
	-- exactly there while the stall stood mid-deck; the stall moved beside the
	-- road's approach, and the point moved with it.
	--==========================================================================
	local base = stall.CFrame * CFrame.new(side * SIDE_OFFSET, 0, FRONT_OFFSET)

	--==========================================================================
	-- CAST DOWN FOR THE FLOOR, DO NOT ASSUME THE STALL'S
	--
	-- The board stands BESIDE the stall, which means it is not standing ON it:
	-- taking the stall floor's top as the ground buried the post's foot three
	-- tenths of a stud in the deck. Same rule CarryService already follows for a
	-- dropped pod -- nothing falls in this game, so anything placed has to be
	-- placed correctly.
	--==========================================================================
	local probe = RaycastParams.new()
	probe.FilterType = Enum.RaycastFilterType.Exclude
	probe.FilterDescendantsInstances = { model }
	local hit = Workspace:Raycast(base.Position + Vector3.new(0, 24, 0),
		Vector3.new(0, -80, 0), probe)
	local floorY = if hit
		then hit.Position.Y
		else (stall.Position.Y + stall.Size.Y * 0.5)
	local ground = Vector3.new(base.Position.X, floorY, base.Position.Z)
	local focus = GameConfig.hubStallCFrame():PointToWorldSpace(Vector3.new(0, 0, STALL.BoardFocus))
	local towardCustomers = Vector3.new(focus.X, ground.Y, focus.Z) - ground
	if towardCustomers.Magnitude < 0.05 then
		towardCustomers = stall.CFrame.LookVector
	end
	local stand = CFrame.lookAt(ground, ground + towardCustomers.Unit)

	part("Post", Vector3.new(0.6, POST_HEIGHT, 0.6),
		stand * CFrame.new(0, POST_HEIGHT * 0.5, 0), WOOD, model)
	-- A foot, so the post reads as planted rather than dropped.
	part("Foot", Vector3.new(1.6, 0.4, 1.6), stand * CFrame.new(0, 0.2, 0), WOOD, model)

	local board = part("Board", BOARD_SIZE,
		stand * CFrame.new(0, POST_HEIGHT + BOARD_SIZE.Y * 0.4, 0), BOARD_FACE, model)
	board.TopSurface = Enum.SurfaceType.Smooth
	board.BottomSurface = Enum.SurfaceType.Smooth
	face(board, Enum.NormalId.Front, titleText, subText)
	face(board, Enum.NormalId.Back, titleText, subText)

	-- A coin on top. One saturated part is what makes it findable from the road
	-- without a billboard hanging in the sky.
	local coin = part("Coin", Vector3.new(1.5, 0.28, 1.5),
		stand * CFrame.new(0, POST_HEIGHT + BOARD_SIZE.Y + 0.35, 0), COIN, model)
	coin.Shape = Enum.PartType.Cylinder
	coin.CFrame = coin.CFrame * CFrame.Angles(0, 0, math.rad(90))

	model.PrimaryPart = board
	return model
end

local function attachPrompt(model: Model)
	local board = model.PrimaryPart
	if not board then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	-- Custom, so PromptUI draws it in the same chrome as every other prompt in
	-- the game rather than in Roblox's default grey.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Sell All"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	--==========================================================================
	-- HELD, AND LONGER THAN A POD
	--
	-- Taking a pod is 0.7s. This empties an entire bag and cannot be undone, so
	-- it asks for a moment more -- long enough that nobody sells a raid by
	-- walking past with E down, short enough that clearing junk is not a chore.
	--==========================================================================
	prompt.HoldDuration = 1.1
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = board

	--==========================================================================
	-- THE HOLD ASKS FOR A QUOTE; THE SALE WAITS FOR A YES
	--
	-- It used to sell right here, on the hold. Now the hold is the request and
	-- the panel is the decision: how many plants, how many pods, what they pay,
	-- and nothing sold until the player says yes to exactly that
	-- (SellService.QuoteAll / ConfirmAll below).
	--==========================================================================
	table.insert(connections, prompt.Triggered:Connect(function(player)
		local c = channel
		if c then
			c:FireClient(player, SELL_ONE.ServerAction, SellService.QuoteAll(player, board))
		end
	end))
end

--==============================================================================
-- SELL ONE
--==============================================================================
local function tell(player: Player, payload: { [string]: any })
	local c = channel
	if c then
		c:FireClient(player, SELL_ONE.ServerAction, payload)
	end
end

local function forget(player: Player)
	pending[player] = nil
	pendingAll[player] = nil
end

-- The Tool in the player's hands, if any. A Character holds one Tool at a time
-- -- equipping a second unequips the first -- so this is the whole answer.
local function heldTool(player: Player): Tool?
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	return tool
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
-- THE QUOTE
--
-- Called when the prompt fires. Looks in the hands, prices what it finds, and
-- returns the payload the client is told -- "quote" with a token, or "refused"
-- with the one line to show. Any older quote this player had is dropped first:
-- the panel that was open for it, if any, is not the panel the player is
-- looking at now.
--==============================================================================
function SellService.QuoteOne(player: Player, board: BasePart, now: number?): { [string]: any }
	pending[player] = nil
	-- One quote per player, whichever board made it.
	pendingAll[player] = nil
	local tool = heldTool(player)
	local quote, reason = EconomyService.QuoteOne(player, tool)
	if not quote then
		log(string.format("%s pressed sell-one with nothing to sell (%s)", player.Name, reason))
		-- An invite reward in the hands is said as such (2026-10-06): it IS a grown
		-- plant, so "hold a grown plant" would be the wrong advice.
		local text = if reason == "UNSELLABLE" then SELL_ONE.UnsellableText else SELL_ONE.EmptyHandsText
		return { phase = "refused", text = text, reason = reason }
	end
	nextToken += 1
	pending[player] = {
		tool = tool :: Tool,
		token = nextToken,
		price = quote.price,
		speciesId = quote.species.Id,
		tier = quote.tier,
		board = board,
		expires = (now or os.clock()) + SELL_ONE.QuoteSeconds,
	}
	log(string.format("%s was quoted %s for one %s (tier %d), token %d",
		player.Name, GameConfig.compact(quote.price), quote.species.Name, quote.tier, nextToken))
	return {
		phase = "quote",
		token = nextToken,
		speciesId = quote.species.Id,
		name = quote.species.Name,
		tier = quote.tier,
		price = quote.price,
	}
end

--==============================================================================
-- THE ANSWER
--
-- Returns what the client should be told, "cancelled" for a no (which needs no
-- reply), or nil for a request that names no quote of this player's -- a
-- stale panel, a replay or a forgery, all of which the client has already
-- closed on its own and none of which is worth a message.
--
-- THE QUOTE IS FORGOTTEN BEFORE ANYTHING ELSE HAPPENS. Whatever the checks
-- below decide, a second answer carrying this token finds nothing; that, and
-- SellOne having no yield between its last check and its last write, is the
-- whole defence against selling one plant twice.
--==============================================================================
function SellService.ConfirmOne(player: Player, payload: any, now: number?): { [string]: any }?
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
	pending[player] = nil

	if payload.accept ~= true then
		log(string.format("%s declined the sell-one quote, token %d", player.Name, token))
		return { phase = "cancelled", token = token }
	end
	if (now or os.clock()) > p.expires then
		return { phase = "refused", token = token, text = SELL_ONE.ExpiredText, reason = "EXPIRED" }
	end

	-- STILL AT THE BOARD. Measured to the board, not to where the player was
	-- when they pressed: a player who took the quote and walked to the road
	-- cannot sell from there.
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local board = p.board
	if not (root and root:IsA("BasePart") and board.Parent ~= nil
		and (root.Position - board.Position).Magnitude <= SELL_ONE.ReachStuds) then
		return { phase = "refused", token = token, text = SELL_ONE.TooFarText, reason = "TOO_FAR" }
	end

	-- THE SAME TOOL, STILL IN THE SAME HANDS. EconomyService checks the parent
	-- again on its own; this is only what the player is told when it fails.
	if p.tool.Parent ~= character then
		return { phase = "refused", token = token, text = SELL_ONE.ChangedText, reason = "CHANGED" }
	end

	local sold, reason = EconomyService.SellOne(player, p.tool)
	if not sold then
		return { phase = "refused", token = token, text = SELL_ONE.ChangedText, reason = reason }
	end
	-- The till, once. The same cue SELL ALL rings.
	SoundKit.emit("SellAll", board)
	log(string.format("%s sold one %s for %s, token %d",
		player.Name, sold.species.Name, GameConfig.compact(sold.price), token))
	return {
		phase = "sold",
		token = token,
		speciesId = sold.species.Id,
		name = sold.species.Name,
		tier = sold.tier,
		paid = sold.price,
	}
end

-- For a test that wants to look: the token of the quote this player has on
-- the table, if any.
function SellService.PendingFor(player: Player): number?
	local p = pending[player]
	return if p then p.token else nil
end

--==============================================================================
-- SELL ALL: THE QUOTE
--
-- Called when the SELL ALL hold completes. Counts what the stall would buy --
-- EconomyService.QuoteHeld, the same rule and the same prices the sale uses --
-- and returns the payload the client is told: "quoteAll" with a token, the
-- plant and pod counts and the payout, or "refused" when there is nothing to
-- sell. Any older quote this player had, from either board, is dropped first.
--
-- The payout is the sum. It says what the whole bag pays, not what any one
-- unhatched pod is worth -- the bag's own cards still read ??? for a pod.
--==============================================================================
function SellService.QuoteAll(player: Player, board: BasePart, now: number?): { [string]: any }
	pending[player] = nil
	pendingAll[player] = nil
	local quote = EconomyService.QuoteHeld(player)
	if #quote.tools == 0 then
		-- Only favourites left (2026-10-03): said as such, so a full bag that
		-- will not sell is not a mystery.
		if quote.kept > 0 then
			log(string.format("%s pressed sell-all with only %d favourite(s) left", player.Name, quote.kept))
			return { phase = "refused", text = SELL_ALL.FavouritesText, reason = "FAVOURITES", kept = quote.kept }
		end
		-- Only invite rewards left (2026-10-06): no stall buys one.
		if quote.locked > 0 then
			log(string.format("%s pressed sell-all with only %d invite reward(s) left", player.Name, quote.locked))
			return { phase = "refused", text = SELL_ALL.InviteOnlyText, reason = "UNSELLABLE" }
		end
		log(string.format("%s pressed sell-all with nothing to sell", player.Name))
		return { phase = "refused", text = SELL_ALL.EmptyText, reason = "EMPTY" }
	end
	nextToken += 1
	local set: { [Tool]: boolean } = {}
	for _, tool in ipairs(quote.tools) do
		set[tool] = true
	end
	pendingAll[player] = {
		token = nextToken,
		tools = set,
		count = #quote.tools,
		total = quote.total,
		board = board,
		expires = (now or os.clock()) + SELL_ONE.QuoteSeconds,
	}
	log(string.format("%s was quoted %s for %d plant(s) and %d pod(s), token %d",
		player.Name, GameConfig.compact(quote.total), quote.plants, quote.pods, nextToken))
	return {
		phase = "quoteAll",
		token = nextToken,
		plants = quote.plants,
		pods = quote.pods,
		total = quote.total,
		kept = quote.kept,
	}
end

--==============================================================================
-- SELL ALL: THE ANSWER
--
-- Same shape as ConfirmOne, and the same first move: the quote is FORGOTTEN
-- before anything is checked, so a double press or a replayed yes finds
-- nothing. Then: a no sells nothing; a yes must be in time, from the board,
-- and for EXACTLY the bag that was counted -- the same Tool instances, no more
-- and no fewer, still paying the same total. Anything else is "your bag
-- changed" and nothing is sold; the player presses the sign again for a fresh
-- count. Between the last check and the sale nothing yields, so the bag that
-- was checked is the bag that is sold.
--==============================================================================
function SellService.ConfirmAll(player: Player, payload: any, now: number?): { [string]: any }?
	if type(payload) ~= "table" then
		return nil
	end
	local token = validToken(payload.token)
	if not token then
		return nil
	end
	local p = pendingAll[player]
	if not p or p.token ~= token then
		return nil
	end
	pendingAll[player] = nil

	if payload.accept ~= true then
		log(string.format("%s declined the sell-all quote, token %d", player.Name, token))
		return { phase = "cancelled", token = token }
	end
	if (now or os.clock()) > p.expires then
		return { phase = "refused", token = token, text = SELL_ONE.ExpiredText, reason = "EXPIRED" }
	end

	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local board = p.board
	if not (root and root:IsA("BasePart") and board.Parent ~= nil
		and (root.Position - board.Position).Magnitude <= SELL_ONE.ReachStuds) then
		return { phase = "refused", token = token, text = SELL_ALL.TooFarText, reason = "TOO_FAR" }
	end

	local now_ = EconomyService.QuoteHeld(player)
	local same = #now_.tools == p.count and now_.total == p.total
	if same then
		for _, tool in ipairs(now_.tools) do
			if not p.tools[tool] then
				same = false
				break
			end
		end
	end
	if not same then
		return { phase = "refused", token = token, text = SELL_ALL.ChangedText, reason = "CHANGED" }
	end

	local sold, paid = EconomyService.SellHeld(player)
	if sold == 0 then
		return { phase = "refused", token = token, text = SELL_ALL.ChangedText, reason = "CHANGED" }
	end
	-- The till, recorded 2026-09-17: the same cue SELL ONE rings.
	SoundKit.emit("SellAll", board)
	log(string.format("%s sold all: %d item(s) for %s, token %d",
		player.Name, sold, GameConfig.compact(paid), token))
	return { phase = "soldAll", token = token, sold = sold, paid = paid }
end

-- For a test that wants to look: the token of this player's SELL ALL quote.
function SellService.PendingAllFor(player: Player): number?
	local p = pendingAll[player]
	return if p then p.token else nil
end

function SellService.Forget(player: Player)
	forget(player)
end

local function attachOnePrompt(model: Model)
	local board = model.PrimaryPart
	if not board then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellOnePrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = SELL_ONE.PromptText
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	-- No hold: this opens a confirmation, and the confirmation is the
	-- deliberate step. See GameConfig.SellOne.
	prompt.HoldDuration = SELL_ONE.PromptHold
	prompt.MaxActivationDistance = SELL_ONE.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = board

	table.insert(connections, prompt.Triggered:Connect(function(player)
		tell(player, SellService.QuoteOne(player, board))
	end))
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function SellService.Init()
	local map = Workspace:FindFirstChild("SeedMap")
	if map then
		for _, name in ipairs({ SIGN_NAME, ONE_SIGN_NAME }) do
			local existing = map:FindFirstChild(name, true)
			if existing then
				existing:Destroy()
			end
		end
	end
	table.clear(pending)
	table.clear(pendingAll)
end

function SellService.Start()
	local stall = findStall()
	if not stall then
		-- Not fatal: the hub is MapService's, and a map built without a stall is
		-- a MapService problem that should not stop the server booting.
		warn("[Seed/SellService] no StallFloor in the map; no sell boards built")
		return
	end
	local seconds = math.floor(SeedData.SellSeconds)
	local allSign = build(stall, SIGN_NAME, -1, "SELL ALL",
		string.format("your whole bag  ·  %ds of income each", seconds))
	attachPrompt(allSign)
	local oneSign = build(stall, ONE_SIGN_NAME, 1, "SELL ONE",
		string.format("the plant in your hands  ·  %ds of income", seconds))
	attachOnePrompt(oneSign)

	--==========================================================================
	-- THE ANSWERS COME BACK ON GameEvent
	--
	-- No new remote. The client sends the verb, a token and a yes or no; the
	-- token is the only thing that names a quote, and ConfirmOne treats every
	-- field as a claim.
	--==========================================================================
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
		table.insert(connections, found.OnServerEvent:Connect(
			function(player: Player, action: any, payload: any)
				if action ~= SELL_ONE.ClientAction then
					return
				end
				-- The token names the quote, and only one of the two tables can
				-- hold it: SELL ONE's, else SELL ALL's.
				local result = SellService.ConfirmOne(player, payload)
					or SellService.ConfirmAll(player, payload)
				if result and result.phase ~= "cancelled" then
					tell(player, result)
				end
			end))
	else
		warn("[Seed/SellService] No GameEvent remote; SELL ONE cannot be confirmed.")
	end

	-- A quote does not outlive the hands it was made for, or the player.
	local function watch(player: Player)
		playerConns[player] = player.CharacterRemoving:Connect(function()
			forget(player)
		end)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	table.insert(connections, Players.PlayerAdded:Connect(watch))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		forget(player)
		local c = playerConns[player]
		if c then
			c:Disconnect()
			playerConns[player] = nil
		end
	end))

	log(string.format("Ready. Sell-all and sell-one boards standing at the stall, %.0f studs from the deck's centre.",
		(allSign.PrimaryPart :: BasePart).Position.Magnitude))
end

function SellService.Stop()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, c in pairs(playerConns) do
		c:Disconnect()
	end
	table.clear(playerConns)
	table.clear(pending)
	table.clear(pendingAll)
	channel = nil
end

return SellService
