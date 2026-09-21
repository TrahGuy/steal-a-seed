--!nocheck
--==============================================================================
-- Steal a Seed :: SellOneSpec
--
-- SELL ONE's server half, driven end to end without a Play session: the REAL
-- EconomyService and the REAL SellService, loaded from their Source with the
-- services around them stood in (Players, PlayerDataService, CarryService,
-- PassService, PlotService, PlantService, SoundKit). The stand-ins only RECORD
-- what they are asked to do, so the order and count of those calls is the
-- evidence -- one AddCash, one SyncHeldNow, one Tool gone, per sale.
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SellOneSpec"))
--
-- The stand-in player has a real Model for a Character and a real container
-- for a Backpack, holding real Tool instances with the attributes CarryService
-- stamps on a plant, so parent checks and Destroy() are the engine's own.
--
-- Not here: the prompt, the remote and the panel, which need a client. The Play
-- notes in KB/HANDOFF cover those.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")

local SELL = GameConfig.SellOne

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

--==============================================================================
-- THE STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function count(name)
	local n = 0
	for _, t in ipairs(trace) do
		if t.name == name then
			n += 1
		end
	end
	return n
end
local function lastArgs(name)
	for i = #trace, 1, -1 do
		if trace[i].name == name then
			return trace[i].args
		end
	end
	return nil
end

local scratch = Instance.new("Folder")
scratch.Name = "SellOneSpecScratch"
scratch.Archivable = false
scratch.Parent = Workspace

-- A real Character and a real Backpack, so Tool.Parent means what it means.
local character = Instance.new("Model")
character.Name = "SpecSeller"
character.Parent = scratch
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Anchored = true
root.CanCollide = false
root.Size = Vector3.new(2, 2, 1)
root.CFrame = CFrame.new(0, 3, 4)
root.Parent = character

local backpack = Instance.new("Folder")
backpack.Name = "Backpack"
backpack.Parent = scratch

local fakePlayers = {}
local attrs = {}
local seller = { Name = "SpecSeller", UserId = 4243, Parent = fakePlayers, Character = character }
function seller:FindFirstChildOfClass(className)
	return if className == "Backpack" then backpack else nil
end
function seller:GetAttribute(name)
	return attrs[name]
end
function fakePlayers:GetPlayers()
	return { seller }
end

local MAX_CASH = GameConfig.Save.MaxCash or 1e15
local cash = 0
local PlayerDataService = {
	AddCash = function(player, amount)
		record("AddCash", player, amount)
		cash = math.clamp(cash + amount, 0, MAX_CASH)
		return cash
	end,
	IsReady = function()
		return true
	end,
	Get = function()
		return { Cash = cash }
	end,
	RecordTutorial = function() end,
}

local carrying = false
local CarryService = {
	IsCarrying = function()
		return carrying
	end,
	SyncHeldNow = function(player)
		record("SyncHeldNow", player)
	end,
}

local PassService = {
	-- The pass is ON for the whole spec, so a price that stays at the base
	-- rate proves the multiplier never reached it.
	CashMultiplier = function()
		return 2
	end,
}
local PlotService = {}
local PlantService = {}
local fakeSoundKit = {
	emit = function(name, at)
		record("Sound", name, at)
	end,
}

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end

-- Loads a real server module with its siblings replaced by stand-ins. Anything
-- it requires from Shared is the real thing, through the runner's fresh require,
-- unless `overrides` names that module.
local outerRequire = require
local function loadWith(module, siblings, overrides)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local env = setmetatable({
		game = fakeGame,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			if overrides and typeof(target) == "Instance" and overrides[target.Name] ~= nil then
				return overrides[target.Name]
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

--==============================================================================
-- FIXTURES
--==============================================================================
local function plantTool(id, tier, hatched, parent)
	local tool = Instance.new("Tool")
	local species = SeedData.Get(id)
	tool.Name = if hatched then species.Name else "???"
	tool:SetAttribute("SpeciesId", id)
	tool:SetAttribute(GameConfig.Attributes.CarryingKg, tier)
	tool:SetAttribute("Hatched", hatched)
	tool.Parent = parent
	return tool
end

local function weaponTool(name, parent)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool:SetAttribute("WeaponId", string.lower(name))
	tool.Parent = parent
	return tool
end

local function clearHands()
	for _, c in ipairs(character:GetChildren()) do
		if c:IsA("Tool") then
			c:Destroy()
		end
	end
	for _, c in ipairs(backpack:GetChildren()) do
		c:Destroy()
	end
end

local board = Instance.new("Part")
board.Name = "Board"
board.Anchored = true
board.CanCollide = false
board.Size = Vector3.new(7.2, 3, 0.4)
board.CFrame = CFrame.new(0, 7, 0)
board.Parent = scratch

local NEAR = CFrame.new(0, 3, 4)
local FAR = CFrame.new(0, 3, 4 + SELL.ReachStuds + 5)

--==============================================================================
-- 1. LOADING THE REAL THING
--==============================================================================
say("\n-- load --")
local EconomyService, SellService
local ok, err = pcall(function()
	EconomyService = loadWith(Server.EconomyService, {
		PlotService = PlotService,
		PlantService = PlantService,
		PlayerDataService = PlayerDataService,
		CarryService = CarryService,
		PassService = PassService,
	})
	SellService = loadWith(Server.SellService, {
		EconomyService = EconomyService,
	}, { SoundKit = fakeSoundKit })
end)
check(ok, "EconomyService and SellService load against the stand-ins", err)
check(type(EconomyService.QuoteOne) == "function" and type(EconomyService.SellOne) == "function",
	"EconomyService offers QuoteOne and SellOne beside SellHeld")
check(type(SellService.QuoteOne) == "function" and type(SellService.ConfirmOne) == "function",
	"SellService offers QuoteOne and ConfirmOne")

local function quote(now)
	return SellService.QuoteOne(seller, board, now)
end
local function confirm(payload, now)
	return SellService.ConfirmOne(seller, payload, now)
end

--==============================================================================
-- 2. WHAT IS REFUSED, AND WITH WHICH LINE
--==============================================================================
say("\n-- refusals --")
clearHands()
root.CFrame = NEAR
local r = quote()
check(r.phase == "refused" and r.text == SELL.EmptyHandsText, "empty hands: refused with the empty-hands line", r.text)
check(SellService.PendingFor(seller) == nil, "and no quote is left on the table")

weaponTool("Rootwood Bat", character)
r = quote()
check(r.phase == "refused" and r.text == SELL.EmptyHandsText, "a bat in hand: refused with the same line", r.reason)
clearHands()

weaponTool("Bramblejaw Trap", character)
r = quote()
check(r.phase == "refused" and r.text == SELL.EmptyHandsText, "a trap in hand: refused", r.reason)
clearHands()

plantTool("nubkin", 2, false, character)
r = quote()
check(r.phase == "refused" and r.reason == "UNHATCHED", "an unhatched pod in hand: refused as UNHATCHED", r.reason)
clearHands()

plantTool("nubkin", 2, true, backpack)
r = quote()
check(r.phase == "refused", "a grown plant in the BAG but not the hands: refused -- nothing is chosen for the player", r.reason)
clearHands()

carrying = true
plantTool("nubkin", 2, true, character)
r = quote()
check(r.phase == "refused" and r.reason == "CARRYING", "carrying a raid pod: refused even with a Tool somehow in hand", r.reason)
carrying = false
clearHands()

--==============================================================================
-- 3. THE QUOTE
--==============================================================================
say("\n-- the quote --")
local nub = plantTool("nubkin", 3, true, character)
local price = SeedData.SellPrice(SeedData.Get("nubkin"), 3)
r = quote(100)
check(r.phase == "quote", "a grown Nubkin in hand: quoted")
check(r.price == price, "at exactly SeedData.SellPrice for its species and tier", r.price)
check(r.price == SeedData.IncomePerSecond(SeedData.Get("nubkin"), 3) * SeedData.SellSeconds,
	"which is SellSeconds of the BASE rate -- the x2 pass never multiplied it", r.price)
check(r.speciesId == "nubkin" and r.tier == 3 and r.name == "Nubkin", "naming the species, tier and name")
check(type(r.token) == "number" and r.token >= 1 and SellService.PendingFor(seller) == r.token,
	"with a token that is the quote on the table", r.token)
check(nub.Parent == character and count("AddCash") == 0, "and nothing was sold or paid by quoting")
local firstToken = r.token

r = quote(100)
check(r.phase == "quote" and r.token ~= firstToken and SellService.PendingFor(seller) == r.token,
	"pressing again replaces the quote with a new token")
local stale = confirm({ token = firstToken, accept = true }, 101)
check(stale == nil and nub.Parent == character and count("AddCash") == 0,
	"the old token is refused silently and sells nothing")
local liveToken = r.token

--==============================================================================
-- 4. ANSWERS THAT MUST NOT SELL
--==============================================================================
say("\n-- answers that must not sell --")
for _, bad in ipairs({ "yes", 42, { token = "1", accept = true }, { token = 0 / 0, accept = true },
	{ token = 1.5, accept = true }, { token = -1, accept = true }, { token = 1e13, accept = true } }) do
	local res = confirm(bad, 101)
	check(res == nil, "a malformed answer is dropped: " .. tostring(if type(bad) == "table" then tostring(bad.token) else bad))
end
check(confirm(nil, 101) == nil, "a nil answer is dropped")
check(SellService.PendingFor(seller) == liveToken and nub.Parent == character, "and the live quote survives them")

local no = confirm({ token = liveToken, accept = false }, 101)
check(no ~= nil and no.phase == "cancelled", "a no is a cancel")
check(SellService.PendingFor(seller) == nil, "which forgets the quote")
check(nub.Parent == character and count("AddCash") == 0 and count("SyncHeldNow") == 0,
	"and changes nothing: plant kept, nothing paid, bag not re-synced")

r = quote(100)
local expired = confirm({ token = r.token, accept = true }, 100 + SELL.QuoteSeconds + 1)
check(expired ~= nil and expired.phase == "refused" and expired.reason == "EXPIRED" and expired.text == SELL.ExpiredText,
	"a yes after QuoteSeconds is refused as expired")
check(nub.Parent == character and count("AddCash") == 0, "with the plant kept")

r = quote(100)
root.CFrame = FAR
local far = confirm({ token = r.token, accept = true }, 101)
check(far ~= nil and far.phase == "refused" and far.reason == "TOO_FAR" and far.text == SELL.TooFarText,
	"a yes from beyond ReachStuds of the board is refused")
check(nub.Parent == character and count("AddCash") == 0, "with the plant kept")
root.CFrame = NEAR

r = quote(100)
nub.Parent = backpack
local moved = confirm({ token = r.token, accept = true }, 101)
check(moved ~= nil and moved.phase == "refused" and moved.reason == "CHANGED" and moved.text == SELL.ChangedText,
	"a yes after the plant was put away is refused as changed")
check(nub.Parent == backpack and count("AddCash") == 0, "and the plant stays in the bag, unsold")
nub.Parent = character

r = quote(100)
local twin = plantTool("nubkin", 3, true, character)
-- Two Tools cannot both be equipped in a real Character; this only proves the
-- quote is bound to an instance, not to "whatever is held". Put the quoted one
-- away and leave the twin in the hands.
nub.Parent = backpack
local swapped = confirm({ token = r.token, accept = true }, 101)
check(swapped ~= nil and swapped.phase == "refused" and swapped.reason == "CHANGED",
	"a yes after the hands changed to an IDENTICAL plant is refused -- no substitution")
check(twin.Parent == character and nub.Parent == backpack and count("AddCash") == 0,
	"and neither copy was sold")
twin:Destroy()
nub.Parent = character

r = quote(100)
SellService.Forget(seller)
local dead = confirm({ token = r.token, accept = true }, 101)
check(dead == nil and nub.Parent == character and count("AddCash") == 0,
	"death or leaving forgets the quote, so the yes finds nothing")

--==============================================================================
-- 5. THE SALE, EXACTLY ONE COPY
--==============================================================================
say("\n-- the sale --")
table.clear(trace)
cash = 1000
local keep = plantTool("nubkin", 3, true, backpack)
local keep2 = plantTool("petalpip", 1, true, backpack)
r = quote(100)
local sold = confirm({ token = r.token, accept = true }, 101)
check(sold ~= nil and sold.phase == "sold", "a yes sells")
check(sold and sold.paid == price and sold.name == "Nubkin" and sold.tier == 3 and sold.speciesId == "nubkin",
	"and reports the name, tier and the exact payout", sold and sold.paid)
check(nub.Parent == nil, "the quoted copy is gone")
check(keep.Parent == backpack and keep2.Parent == backpack,
	"the identical twin and the other plant in the bag are untouched")
check(count("AddCash") == 1 and lastArgs("AddCash")[2] == price, "paid exactly once, exactly the quote", count("AddCash"))
check(cash == 1000 + price, "onto the cash the player had", cash)
check(count("SyncHeldNow") == 1, "the bag was re-snapshotted once, through CarryService")
check(count("Sound") == 1 and lastArgs("Sound")[1] == "SellAll", "the till rang once, the SELL ALL cue")
check(SellService.PendingFor(seller) == nil, "and the quote is spent")

local again = confirm({ token = r.token, accept = true }, 101)
check(again == nil and count("AddCash") == 1, "the same yes again pays nothing")

-- Order inside SellOne: the Tool is gone and the bag re-synced before AddCash
-- runs, so a payment failure cannot leave a paid plant in the bag.
local order = {}
for _, t in ipairs(trace) do
	table.insert(order, t.name)
end
check(order[1] == "SyncHeldNow" and order[2] == "AddCash", "destroyed and re-synced before paid", table.concat(order, ","))

--==============================================================================
-- 6. RACING SELL ALL
--==============================================================================
say("\n-- racing SELL ALL --")
table.clear(trace)
clearHands()
local held = plantTool("spiretip", 2, true, character)
local bagged = plantTool("toadcap", 1, true, backpack)
local expectAll = SeedData.SellPrice(SeedData.Get("spiretip"), 2) + SeedData.SellPrice(SeedData.Get("toadcap"), 1)
r = quote(100)
local soldCount, paidAll = EconomyService.SellHeld(seller)
check(soldCount == 2 and paidAll == expectAll, "SELL ALL still buys the whole bag, hands included, at the same prices", paidAll)
check(held.Parent == nil and bagged.Parent == nil, "and both Tools are gone")
local late = confirm({ token = r.token, accept = true }, 101)
check(late ~= nil and late.phase == "refused", "a SELL ONE yes landing after SELL ALL is refused", late and late.reason)
check(count("AddCash") == 1 and lastArgs("AddCash")[2] == expectAll, "so the bag was paid once, by SELL ALL only")

--==============================================================================
-- 7. THE CAP, LIKE SELL ALL
--==============================================================================
say("\n-- the cap --")
table.clear(trace)
clearHands()
cash = MAX_CASH - 10
local rich = plantTool("nubkin", 7, true, character)
r = quote(100)
local capped = confirm({ token = r.token, accept = true }, 101)
check(capped ~= nil and capped.phase == "sold" and rich.Parent == nil, "a sale at the cap still completes")
check(cash == MAX_CASH, "and AddCash clamps it at MaxCash, as it does for SELL ALL", cash)

--==============================================================================
-- 8. EconomyService.SellOne ON ITS OWN
--==============================================================================
say("\n-- SellOne direct --")
table.clear(trace)
clearHands()
cash = 0
local direct = plantTool("dunebud", 4, true, character)
local q, why = EconomyService.QuoteOne(seller, direct)
check(q ~= nil and q.price == SeedData.SellPrice(SeedData.Get("dunebud"), 4) and why == "",
	"QuoteOne prices a held grown plant and touches nothing", why)
check(direct.Parent == character and count("AddCash") == 0, "quoting sold nothing")
local s1 = EconomyService.SellOne(seller, direct)
local s2, why2 = EconomyService.SellOne(seller, direct)
check(s1 ~= nil and s2 == nil, "selling the same instance twice sells once", why2)
check(count("AddCash") == 1 and count("SyncHeldNow") == 1, "one payment, one re-sync")
local nothing, whyNothing = EconomyService.SellOne(seller, nil)
check(nothing == nil and whyNothing == "NOTHING_HELD", "nothing in hand is NOTHING_HELD", whyNothing)

scratch:Destroy()

say("")
say(string.format("SellOneSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
