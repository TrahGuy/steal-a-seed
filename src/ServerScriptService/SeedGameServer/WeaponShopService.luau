--!strict
--==============================================================================
-- Steal a Seed :: WeaponShopService
--
-- Marigold's counter. Owns three things and nothing else:
--
--   1. the prompt on Marigold that opens the panel
--   2. buying, which is the only place cash moves for a weapon
--   3. which one weapon a player has out, and the Tool that IS that weapon
--
-- What it does NOT own is anything a bat or a trap DOES. That is CombatService,
-- which asks this file what a player is holding and never writes an answer.
-- Ownership and violence are two different problems and they change for two
-- different reasons.
--
--==============================================================================
-- THE CLIENT SENDS A VERB AND AN ID. IT DECIDES NOTHING.
--
-- Same rule as PlotUpgradeService, with one addition it cannot avoid: a shop
-- with seven shelves has to be told WHICH card was pressed, so an id crosses
-- the wire. Everything else is read on this side -- the price out of WeaponData,
-- the balance out of the profile, the sender off the engine stamp.
--
-- So the worst a modified client can do is name a weapon and ask. A name that
-- is not on the shelf is dropped. A name that is buys exactly what its own card
-- advertises, at exactly its own card's price, once.
--
--==============================================================================
-- A WEAPON TOOL IS INVISIBLE TO EVERY SYSTEM THAT SWEEPS THE BAG
--
-- It carries a `WeaponId` attribute and NO `SpeciesId`, which is the single
-- fact that keeps it out of three other services without a line being added to
-- any of them:
--
--   EconomyService.SellHeld   prices a Tool by its species; no species, no sale
--   CarryService.heldSnapshot saves a Tool by its species; no species, no row
--   PlantService.PlaceAt      plants a Tool by its species; no species, refused
--
-- That was checked rather than assumed. A bat cannot be sold at the stall, is
-- not written into the Held save, and cannot be planted in a bed.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local WeaponShopService = {}

-- After PlayerDataService (20) and the map (1). Sits beside PlotUpgradeService
-- (60), which is the other service that takes money for a permanent unlock.
WeaponShopService.Priority = 62

local W = GameConfig.Weapon
local ITEM_ATTR = WeaponModel.ItemAttribute
local PROMPT_NAME = "MarigoldShopPrompt"

local serviceConnections: { RBXScriptConnection } = {}
local toolConnections: { [Player]: { RBXScriptConnection } } = {}
local busy: { [Player]: boolean } = {}
local channel: RemoteEvent? = nil

local function log(message: string)
	print("[Seed/WeaponShopService] " .. message)
end

--==============================================================================
-- WHAT THEY OWN, AND WHAT THEY HAVE OUT
--
-- Read off the PROFILE, never off the Backpack. A Tool is a thing in the world
-- that a respawn destroys and a script can create; the profile is the record.
-- If the two ever disagree the profile is right, which is why `refreshTools`
-- below rebuilds the Tools from the profile rather than the other way round.
--==============================================================================
function WeaponShopService.Owns(player: Player, weaponId: string): boolean
	local profile = PlayerDataService.Get(player)
	return profile ~= nil and profile.Weapons[weaponId] == true
end

--==============================================================================
-- ONE SLOT PER CATEGORY
--
-- A player carries a bat AND a trap at once, and the two are separate saved
-- fields precisely so that choosing one cannot clear the other. Everything that
-- asks "what have they got out" asks per category.
--==============================================================================
WeaponShopService.Categories = { "bat", "trap" }

function WeaponShopService.EquippedId(player: Player, category: string): string?
	local id = PlayerDataService.LoadoutOf(player, category)
	if id == "" then
		return nil
	end
	--==========================================================================
	-- RE-CHECKED ON EVERY READ, NOT ONLY ON WRITE
	--
	-- The profile is sanitised on load and validated on write, so a slot naming
	-- something unowned should be impossible. "Should be impossible" is what
	-- this check costs one table lookup to stop being load-bearing.
	--==========================================================================
	if not WeaponShopService.Owns(player, id) then
		return nil
	end
	return id
end

--==============================================================================
-- WHAT COMBATSERVICE ASKS
--
-- The item a swing or a placement is FOR. It is resolved from the Tool actually
-- in the character's hands rather than from the profile, because "equipped in
-- the profile" and "out in front of you right now" are different questions --
-- a player can put a bat away without unequipping it, and a bat in the backpack
-- must not swing.
--==============================================================================
function WeaponShopService.HeldItem(player: Player): (WeaponData.Item?, Tool?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return nil, nil
	end
	local item = WeaponData.Get(tool:GetAttribute(ITEM_ATTR))
	if not item then
		return nil, nil
	end
	-- The Tool is a server-made object, but ownership is still re-checked: a
	-- Tool that outlived a refund, or one somebody found a way to parent in, is
	-- not a licence to swing it.
	if not WeaponShopService.Owns(player, item.Id) then
		return nil, nil
	end
	return item, tool
end

--==============================================================================
-- THE TOOLS, REBUILT FROM THE PROFILE
--
-- Up to two: whatever the bat slot names and whatever the trap slot names.
-- Both live in the Backpack at once, which is what "both remain available"
-- means -- selecting one is a hotbar action, not a shop action, so switching
-- weapons never touches the profile and never costs a round trip.
--
-- Rule 10 in miniature: safe to call at any moment, from any cause. It is the
-- handler for a purchase, an equip, a respawn and a profile arriving, and all
-- four are the same operation -- "make the world match the record" -- rather
-- than four subtly different ones that drift.
--==============================================================================
local function refreshTools(player: Player)
	if player.Parent ~= Players then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		-- Mid-respawn. CharacterAdded calls again once the new one exists.
		return
	end

	--== WHAT THE PROFILE SAYS THEY SHOULD HAVE ==--
	local want: { [string]: boolean } = {}
	local order: { string } = {}
	for _, category in ipairs(WeaponShopService.Categories) do
		local id = WeaponShopService.EquippedId(player, category)
		if id and WeaponData.Get(id) then
			want[id] = true
			table.insert(order, id)
		end
	end

	--==========================================================================
	-- A TOOL THAT IS ALREADY RIGHT IS LEFT ALONE
	--
	-- Not an optimisation. Destroying and rebuilding the Tool a player is
	-- HOLDING unequips them -- the new one lands in the Backpack -- so a naive
	-- rebuild on every profile event would knock the bat out of their hands
	-- several times a second while they stood there. It is also why switching
	-- from bat to trap does not disturb the bat: the bat is still wanted, so it
	-- is still there, and only the SELECTION moved.
	--==========================================================================
	local have: { [string]: boolean } = {}
	for _, container in ipairs({ backpack, player.Character }) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local id = tool:GetAttribute(ITEM_ATTR)
					if WeaponData.Get(id) then
						if want[id] and not have[id] then
							have[id] = true
						else
							-- Not wanted, or a duplicate of one already found.
							tool:Destroy()
						end
					end
				end
			end
		end
	end

	--== AND BUILD WHATEVER IS MISSING, IN SLOT ORDER ==--
	for _, id in ipairs(order) do
		if not have[id] then
			local item = WeaponData.Get(id)
			local ok, err = pcall(function()
				local tool = WeaponModel.BuildTool(item :: WeaponData.Item)
				tool.Parent = backpack
			end)
			if not ok then
				warn(string.format("[Seed/WeaponShopService] could not build %s for %s: %s",
					id, player.Name, tostring(err)))
			end
		end
	end
end

WeaponShopService.RefreshTools = refreshTools

--==============================================================================
-- BUYING
--
-- Charge, record, and only then let anything else happen. Same order and the
-- same reasoning as PlotUpgradeService: build-then-charge hands out a free one
-- every time the charge fails, and the charge is the step another service can
-- race by paying somebody in the same frame.
--
-- Neither step yields, so `busy` is belt-and-braces today and the thing that
-- saves this the first time somebody animates a purchase. `GrantWeapon` is the
-- other half: it returns false for an id already owned, so even a double click
-- that got past `busy` cannot take money twice for one weapon.
--==============================================================================
function WeaponShopService.TryBuy(player: Player, weaponId: any): boolean
	if busy[player] then
		return false
	end
	if not PlayerDataService.IsReady(player) then
		return false
	end
	local item = WeaponData.Get(weaponId)
	if not item then
		return false
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return false
	end
	if profile.Weapons[item.Id] then
		return false
	end
	if profile.Cash < item.Price then
		return false
	end

	busy[player] = true
	if not PlayerDataService.AddCash(player, -item.Price) then
		busy[player] = false
		return false
	end
	if not PlayerDataService.GrantWeapon(player, item.Id) then
		-- Somebody else granted it between the check and here. Give the money
		-- back; paid and not owned is the outcome that must never stand.
		PlayerDataService.AddCash(player, item.Price)
		busy[player] = false
		return false
	end
	busy[player] = false

	--==========================================================================
	-- WHAT YOU BUY, YOU HOLD
	--
	-- Equipping on purchase rather than leaving it on the shelf, because a
	-- purchase that changes nothing visible is indistinguishable from a
	-- purchase that failed -- and the panel's own EQUIPPED state is then the
	-- receipt. One tool at a time is the rule, so buying a trap does put the
	-- bat away; that is one click to undo and it is what "I bought this" means.
	--==========================================================================
	PlayerDataService.SetLoadout(player, item.Category, item.Id)
	refreshTools(player)

	--==========================================================================
	-- THE CUE IS FIRED HERE, ON THE PATH WHERE THE MONEY MOVED
	--
	-- The panel plays nothing on click. A click is a request, and a request
	-- refused for a reason only this side can see must not sound like a
	-- purchase. Emitted at the character rather than played on the client so
	-- the people standing around Marigold hear it too.
	--==========================================================================
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		SoundKit.emit("MillUpgrade", root)
	end

	log(string.format("%s bought %s for %s.", player.Name, item.Id,
		GameConfig.compact(item.Price)))
	if item.Category == "bat" then PlayerDataService.RecordTutorial(player, "buy") end
	return true
end

--==============================================================================
-- EQUIPPING INTO A SLOT
--
-- An item id goes into the slot ITS OWN CATEGORY names -- the client does not
-- get to say which drawer a bat belongs in. The empty string CLEARS a slot, and
-- that is the only case where the category argument is read, because "" names
-- no item and therefore no category of its own.
--
-- Refuses silently for anything not owned. The panel already knows what the
-- player owns, so reaching a "no" here means it sent something the panel would
-- not have sent.
--==============================================================================
local function isCategory(value: any): boolean
	return value == "bat" or value == "trap"
end

function WeaponShopService.TryEquip(player: Player, weaponId: any,
	category: any): boolean
	if not PlayerDataService.IsReady(player) then
		return false
	end
	--==========================================================================
	-- A NON-STRING IS A REFUSAL, NOT AN EMPTY STRING
	--
	-- This coerced anything that was not a string to "" -- and "" is a real,
	-- meaningful value here: it means put everything away. So sending a NUMBER
	-- unequipped the player. Caught in Play: two forged equips, one naming a
	-- weapon that does not exist and one sending 99, and the second one emptied
	-- their hands.
	--
	-- Harmless as exploits go and wrong as validation. Rule 4 is that every
	-- argument off the wire is a lie until checked, and "check it by converting
	-- it into a different valid command" is not checking it.
	--==========================================================================
	if type(weaponId) ~= "string" then
		return false
	end
	local slot: string
	if weaponId == "" then
		-- Clearing. The client must say WHICH slot, or "put it away" would be
		-- ambiguous the moment there are two of them.
		if not isCategory(category) then
			return false
		end
		slot = category
	else
		local item = WeaponData.Get(weaponId)
		if not item or not WeaponShopService.Owns(player, weaponId) then
			return false
		end
		-- DERIVED, never taken off the wire. A client that could name the slot
		-- could put a bat where the trap button looks for one.
		slot = item.Category
		if not isCategory(slot) then
			return false
		end
	end

	if not PlayerDataService.SetLoadout(player, slot, weaponId) then
		return false
	end
	refreshTools(player)
	return true
end

--==============================================================================
-- THE PROMPT ON MARIGOLD
--
-- Attached to her TORSO, not to the stall, because she walks -- FairyService
-- drives a real Humanoid around a wander box, so a prompt pinned to the
-- furniture would drift away from the person it belongs to.
--
-- OPENING IS A SERVER DECISION. The panel is presentation and could perfectly
-- well be opened by a client deciding it feels close enough; it is not, because
-- then "the shop is open" would be a claim a client makes rather than a fact,
-- and every later argument about range and duplicates would be arguing with a
-- client. The prompt fires, the server sends the verb, the panel opens.
--==============================================================================
local function findMarigold(): Model?
	for _, model in ipairs(CollectionService:GetTagged(GameConfig.Tags.Fairy)) do
		if model:IsA("Model") and model.Parent then
			return model
		end
	end
	return nil
end

local function attachPrompt(fairy: Model)
	-- Rule 10: a second Start against a map that already has one must not leave
	-- two prompts on the same shopkeeper.
	local old = fairy:FindFirstChild(PROMPT_NAME, true)
	if old then
		old:Destroy()
	end
	local anchor = fairy:FindFirstChild("Torso") or fairy.PrimaryPart
	if not (anchor and anchor:IsA("BasePart")) then
		warn("[Seed/WeaponShopService] Marigold has no Torso; no shop prompt built.")
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	-- Custom, so PromptUI draws it in the game's own chrome rather than
	-- Roblox's grey default -- the same as every other prompt in the world.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = W.PromptText
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = W.PromptHold
	prompt.MaxActivationDistance = W.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	table.insert(serviceConnections, prompt.Triggered:Connect(function(player)
		local ch = channel
		if not ch then
			return
		end
		--======================================================================
		-- THE PROFILE HAS TO BE THERE, OR THE PANEL OPENS EMPTY
		--
		-- Everything on a card -- owned, equipped, affordable -- comes off the
		-- profile packet. Opening before one has arrived would draw seven cards
		-- that all say BUY and all refuse, which reads as a broken shop rather
		-- than as a shop that is not ready.
		--======================================================================
		if not PlayerDataService.IsReady(player) then
			return
		end
		pcall(function()
			ch:FireClient(player, W.ShopAction, true)
		end)
	end))
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function forget(player: Player)
	busy[player] = nil
	local conns = toolConnections[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		toolConnections[player] = nil
	end
end

local function watch(player: Player)
	forget(player)
	local conns: { RBXScriptConnection } = {}
	--==========================================================================
	-- A RESPAWN DESTROYS THE BACKPACK AND EVERYTHING IN IT
	--
	-- So the weapon is not "kept" across a death; it is rebuilt, from the
	-- profile, on the other side. That is the same answer as the plot and the
	-- mill -- the record is what persists and the world is what is made to
	-- match it.
	--==========================================================================
	table.insert(conns, player.CharacterAdded:Connect(function()
		-- The Backpack arrives a moment after the character on a fresh spawn.
		task.defer(function()
			if player.Parent == Players then
				refreshTools(player)
			end
		end)
	end))
	toolConnections[player] = conns
	refreshTools(player)
end

function WeaponShopService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	for player in pairs(toolConnections) do
		forget(player)
	end
	table.clear(busy)
	channel = nil
end

function WeaponShopService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
		--======================================================================
		-- TWO MORE VERBS ON THE REMOTE THAT ALREADY EXISTS
		--
		-- GameEvent carries PlantAt, PickUp, PlotUpgrade and the mill's ladder,
		-- each connected by the service that owns it. A remote per verb buys
		-- nothing; the validation belongs next to the thing being validated,
		-- and that is here.
		--======================================================================
		table.insert(serviceConnections, found.OnServerEvent:Connect(
			function(player: Player, action: any, payload: any, extra: any)
				if action == W.BuyAction then
					if not WeaponShopService.TryBuy(player, payload) then
						-- A refusal changes nothing on screen, so it has to be
						-- said. No reason travels: the panel knows the price
						-- and the balance, so being told "no" is all it needs
						-- to make a noise about.
						pcall(function()
							(found :: RemoteEvent):FireClient(player, W.BuyAction, false)
						end)
					end
				elseif action == W.EquipAction then
					if not WeaponShopService.TryEquip(player, payload, extra) then
						pcall(function()
							(found :: RemoteEvent):FireClient(player, W.EquipAction, false)
						end)
					end
				end
			end))
	else
		warn("[Seed/WeaponShopService] No GameEvent remote. Nothing can be bought.")
	end

	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	table.insert(serviceConnections, Players.PlayerAdded:Connect(watch))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(forget))

	--==========================================================================
	-- AND WHEN A PROFILE LANDS
	--
	-- A player who joins owning a Comet Bat has to be handed one, and the only
	-- moment that is knowable is when their profile finishes loading.
	--
	-- A SHORT POLL RATHER THAN AN EVENT. PlayerDataService has no "profile
	-- arrived" signal, and adding a public listener API for a single caller is
	-- a maintenance cost with no second user. A profile lands within a couple of
	-- seconds of joining or it does not land at all, so this checks twice a
	-- second and stops -- bounded, cheap, and it cannot leave somebody
	-- empty-handed because a remote fired before this service started.
	--
	-- `refreshTools` is idempotent by construction: a Tool that is already
	-- wanted is left alone, so being called sixty times costs sixty table walks
	-- and changes nothing.
	--==========================================================================
	task.spawn(function()
		local deadline = os.clock() + 30
		while os.clock() < deadline do
			for _, player in ipairs(Players:GetPlayers()) do
				if PlayerDataService.IsReady(player) then
					refreshTools(player)
				end
			end
			task.wait(0.5)
		end
	end)

	local fairy = findMarigold()
	if fairy then
		attachPrompt(fairy)
	else
		warn("[Seed/WeaponShopService] no fairy in the map; Marigold has no shop prompt")
	end
	table.insert(serviceConnections,
		CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Fairy):Connect(function(m)
			if m:IsA("Model") then
				attachPrompt(m)
			end
		end))

	log(string.format("Ready. %d item(s) on Marigold's shelf; prompt at %.0f studs.",
		#WeaponData.Items, W.PromptDistance))
end

function WeaponShopService.Snapshot(): string
	local lines = { "WeaponShopService" }
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		local owned = 0
		if profile then
			for _ in pairs(profile.Weapons) do
				owned += 1
			end
		end
		local item = WeaponShopService.HeldItem(player)
		table.insert(lines, string.format("  %s: owns %d, bat %s, trap %s, holding %s",
			player.Name, owned,
			tostring(WeaponShopService.EquippedId(player, "bat") or "-"),
			tostring(WeaponShopService.EquippedId(player, "trap") or "-"),
			if item then item.Id else "-"))
	end
	return table.concat(lines, "\n")
end

return WeaponShopService
