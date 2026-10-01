--!nocheck
--==============================================================================
-- Steal a Seed :: SacrificeSpec
--
-- The free sacrifice pedestal (2026-09-28), driven end to end without a Play
-- session. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SacrificeSpec"))
--
-- The REAL SacrificeService, CarryService, PlayerDataService, ProfileSchema,
-- BonusChestService and EconomyService, fresh-required: the pod's row comes off
-- the saved bag by the game's own rule, the boost reaches the faucet by the
-- game's own sum, and a rejoin reads the save through the game's own validator.
--
-- Stood in: SaveService's Load and Save -- an in-memory table, so no DataStore
-- is read or written and no real profile is touched -- the garden
-- (PlotService.PlotOf / OwnerOf, PlantService.GrownIn) and the x2 pass. Players
-- are stand-in tables with real signals, a real Backpack and a real body, the
-- way HeldRestoreSpec and AdminSpec build them; their pods are real Tools from
-- the real builders. Every stand-in joins a save that already exists, so none
-- is ever counted as a new player by anything.
--
-- The pedestal's two clocks are SacrificeService.Now and .Clock, held still
-- here and moved by hand.
--
-- Not here: the prompt being pressed, the remote round trip, the panel and the
-- boost row, which need a client -- the Play notes in KB/HANDOFF cover those --
-- and the DataStore itself.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local Server = ServerScriptService.SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local PlantService = require(Server.PlantService)
local ProfileSchema = require(Server.ProfileSchema)
local OfflineEarnings = require(Server.OfflineEarnings)
local PlayerDataService = require(Server.PlayerDataService)
local CarryService = require(Server.CarryService)
local PassService = require(Server.PassService)
local BonusChestService = require(Server.BonusChestService)
local SacrificeService = require(Server.SacrificeService)
local EconomyService = require(Server.EconomyService)
local Metrics = require(Server.Metrics)

local CONFIG = GameConfig.Sacrifice
local BALANCE = SeedData.Sacrifice
local ATTR = CONFIG.Attributes
local KG = GameConfig.Attributes.CarryingKg
local STAGE_GROWN = require(Shared.CreatureModel).STAGE_GROWN

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
-- One section throwing must not hide the ones after it.
local function section(title, fn)
	say("\n-- " .. title .. " --")
	local ran, why = pcall(fn)
	check(ran, title .. ": ran to its end", why)
end
local function sourceOf(instance)
	if instance == nil then
		return ""
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local fixture = Instance.new("Folder")
fixture.Name = "SacrificeSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

--==============================================================================
-- THE STAND-INS
--==============================================================================
local saves, plots, plants, data, carry = SaveService :: any, PlotService :: any, PlantService :: any,
	PlayerDataService :: any, CarryService :: any
local passes, sac, econ, metrics = PassService :: any, SacrificeService :: any, EconomyService :: any,
	Metrics :: any

-- THE SAVE, IN MEMORY. userId -> a copy of the last payload that landed.
local store = {}
local saveOk = true
local loadAs = {}
local function stubLoad(userId)
	if loadAs[userId] then
		return loadAs[userId], nil
	end
	-- Never "new": every stand-in has a save before it joins.
	assert(store[userId] ~= nil, "SacrificeSpec joined a stand-in with no seeded save")
	return "ok", deepCopy(store[userId])
end
local function stubSave(userId, payload)
	if not saveOk then
		return false
	end
	store[userId] = deepCopy(payload)
	return true
end
saves.Load = stubLoad
saves.Save = stubSave
saves.Forget = function() end

local plotFor, ownerFor, grownFor = {}, {}, {}
plots.PlotOf = function(player)
	return plotFor[player]
end
plots.OwnerOf = function(plot)
	return ownerFor[plot]
end
plots.SetDesiredLevel = function()
	return true
end
plants.GrownIn = function(plot)
	return grownFor[plot] or {}
end
plants.GardenRestored = function()
	return true
end
plants.CountIn = function(plot)
	return #(grownFor[plot] or {})
end
local passFor = {}
passes.CashMultiplier = function(player)
	return passFor[player] or 1
end
local holders = {}
local realMount = data.MountStats
data.MountStats = function(holder, profile)
	return realMount(holders[holder] or holder, profile)
end
-- The faucet's two courtesy calls, which are about the guide and the launch
-- analytics and not about income.
data.RecordTutorial = function() end
metrics.income = function() end

-- The two clocks, held still.
local wall = os.time()
local mono = 1000
sac.Now = function()
	return wall
end
sac.Clock = function()
	return mono
end

--==============================================================================
-- PLAYERS
--==============================================================================
local function standIn(name, userId)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local childAdded = Instance.new("BindableEvent")
	local characterAdded = Instance.new("BindableEvent")
	local characterRemoving = Instance.new("BindableEvent")
	local attrs = {}
	local p = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = nil,
		ChildAdded = childAdded.Event,
		CharacterAdded = characterAdded.Event,
		CharacterRemoving = characterRemoving.Event,
		_backpack = nil,
		_holder = holder,
		_fire = { childAdded = childAdded, characterAdded = characterAdded,
			characterRemoving = characterRemoving },
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.Kick() end
	function p.FindFirstChildOfClass(self, className)
		local backpack = self._backpack
		if className == "Backpack" and backpack and backpack.Parent then
			return backpack
		end
		return nil
	end
	function p.WaitForChild(_, childName)
		return holder:FindFirstChild(childName)
	end
	holders[p] = holder
	return p
end

local NEAR, FAR

local function newBackpack(p)
	local backpack = Instance.new("Backpack")
	backpack.Parent = p._holder
	p._backpack = backpack
	return backpack
end

local function newBody(p)
	local body = Instance.new("Model")
	body.Name = p.Name .. "Body"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = NEAR
	root.Parent = body
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = body
	body.Parent = p._holder
	p.Character = body
	-- Kept beside Character, so the spec can still count what is in the hands
	-- of a player whose Character it has taken away.
	p._body = body
	return body
end

local function seed(userId, shape)
	local raw = ProfileSchema.Sanitise(nil)
	for k, v in pairs(shape or {}) do
		raw[k] = v
	end
	store[userId] = deepCopy(raw)
end

-- Joined, alive, the saved bag put back and recording armed. `arm = false`
-- stops before the bag is restored.
local function enter(name, userId, arm)
	assert(saves.Load == stubLoad and saves.Save == stubSave, "the save stubs are not in place")
	local p = standIn(name, userId)
	data.Join(p)
	newBackpack(p)
	newBody(p)
	carry.WatchHeld(p)
	sac.Watch(p)
	if arm ~= false then
		carry.RestoreHeld(p)
		task.wait(0.3)
		-- A restored grown plant is put straight into the hands (GiveHatched
		-- equips unless it is asked to wait). Every player here starts with
		-- empty hands and chooses what to hold.
		for _, tool in ipairs(p._body:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = p._backpack
			end
		end
		task.wait()
	end
	return p
end

-- A garden of its own, earning `list`.
local function garden(p, list)
	local plot = Instance.new("Model")
	plot.Name = p.Name .. "Plot"
	plot.Parent = p._holder
	plotFor[p] = plot
	ownerFor[plot] = p
	grownFor[plot] = list
	return plot
end

local function isPlant(tool)
	return tool:IsA("Tool") and type(tool:GetAttribute("SpeciesId")) == "string"
end

local function toolsOf(p)
	local list = {}
	for _, container in ipairs({ p._backpack, p._body }) do
		if container and container.Parent then
			for _, tool in ipairs(container:GetChildren()) do
				if isPlant(tool) then
					table.insert(list, tool)
				end
			end
		end
	end
	return list
end

local function podTools(p, id, tier)
	local list = {}
	for _, tool in ipairs(toolsOf(p)) do
		if tool:GetAttribute("SpeciesId") == id and tool:GetAttribute(KG) == tier
			and tool:GetAttribute("Hatched") ~= true then
			table.insert(list, tool)
		end
	end
	return list
end

local function rowsOf(p, id, tier, hatched)
	local profile = data.Get(p)
	local n = 0
	for _, row in ipairs(profile and profile.Held or {}) do
		if (id == nil or row.Id == id) and (tier == nil or row.Tier == tier)
			and (hatched == nil or (row.Hatched == true) == hatched) then
			n += 1
		end
	end
	return n
end

local function emptyHands(p)
	for _, tool in ipairs(p._body:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Parent = p._backpack
		end
	end
end

-- Puts one banked pod of this kind in the hands and lets the bag settle.
local function hold(p, id, tier)
	emptyHands(p)
	local tool = nil
	for _, candidate in ipairs(podTools(p, id, tier)) do
		if candidate.Parent == p._backpack then
			tool = candidate
			break
		end
	end
	assert(tool, string.format("%s has no %s tier %d pod in the bag", p.Name, id, tier))
	tool.Parent = p.Character
	task.wait()
	return tool
end

local function destroyed(tool)
	return tool.Parent == nil and not pcall(function()
		tool.Parent = fixture
	end)
end

-- Everything a refusal must leave alone.
local function snapshot(p)
	local profile = data.Get(p)
	return {
		tools = #toolsOf(p),
		rows = if profile then #profile.Held else -1,
		nextAt = if profile then profile.SacrificeNextAt else -1,
		endsAt = if profile then profile.SacrificeEndsAt else -1,
		cash = if profile then profile.Cash else -1,
		boost = sac.Multiplier(p),
	}
end
local function same(a, b)
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false, string.format("%s was %s and is %s", k, tostring(v), tostring(b[k]))
		end
	end
	return true, nil
end

local top
local function quote(p)
	return sac.Quote(p, top)
end
local function yes(p, token)
	return sac.Confirm(p, { token = token, accept = true })
end

local BAG = {
	{ Id = "nubkin", Tier = 2, Hatched = false },
	{ Id = "nubkin", Tier = 2, Hatched = false },
	{ Id = "nubkin", Tier = 3, Hatched = false },
	{ Id = "petalpip", Tier = 1, Hatched = false },
	{ Id = "toadcap", Tier = 1, Hatched = false },
	{ Id = "toadcap", Tier = 1, Hatched = false },
	{ Id = "spiretip", Tier = 3, Hatched = true },
}
local GARDEN = {
	{ species = SeedData.Get("nubkin"), tier = 3 },
	{ species = SeedData.Get("novaorb"), tier = 4 },
}
local BASE = SeedData.IncomePerSecond(GARDEN[1].species, 3) + SeedData.IncomePerSecond(GARDEN[2].species, 4)

local giver

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE NUMBERS
	--==========================================================================
	section("the numbers", function()
		check(BALANCE.Multiplier == 1.5 and BALANCE.DurationSeconds == 45,
			"one pod buys +50% for 45 seconds, as asked",
			string.format("x%s for %ss", tostring(BALANCE.Multiplier), tostring(BALANCE.DurationSeconds)))
		check(BALANCE.CooldownSeconds == 180, "and the pedestal recharges for 3 minutes -- the proposed value, kept",
			BALANCE.CooldownSeconds)
		check(BALANCE.CooldownSeconds >= BALANCE.DurationSeconds,
			"the boost ends before the pedestal is ready again, so it can never stack on itself")
		check(SeedData.sacrificeMultiplier(100, 99) == 1.5 and SeedData.sacrificeMultiplier(100, 99.9) == 1.5,
			"sacrificeMultiplier: the boost, while now is before the expiry")
		check(SeedData.sacrificeMultiplier(100, 100) == 1 and SeedData.sacrificeMultiplier(100, 101) == 1,
			"and exactly 1 from the expiry on")
		check(SeedData.sacrificeMultiplier(nil, 5) == 1 and SeedData.sacrificeMultiplier(0 / 0, 5) == 1
				and SeedData.sacrificeMultiplier("soon", 5) == 1 and SeedData.sacrificeMultiplier({}, 5) == 1
				and SeedData.sacrificeMultiplier(0, 5) == 1,
			"nil, NaN, a word, a table and 0 for an expiry are all no boost")
		check(GameConfig.sacrificeBoostTitle(BALANCE.Multiplier) == "+50% GARDEN INCOME",
			"the boost row's words are read off the number", GameConfig.sacrificeBoostTitle(BALANCE.Multiplier))
		local c = CONFIG :: any
		check(c.Multiplier == nil and c.DurationSeconds == nil and c.CooldownSeconds == nil,
			"GameConfig holds the pedestal's names and SeedData its numbers: nothing is typed twice")
		check(CONFIG.PromptDistance <= CONFIG.ReachStuds,
			"anybody close enough to press the prompt is close enough to be answered")
		local keys = {}
		for k in pairs(CONFIG) do
			table.insert(keys, k)
		end
		table.sort(keys)
		-- FloatingWords (2026-09-30) is the words over the pedestal: display only.
		local floating = {}
		for k in pairs(CONFIG.FloatingWords or {}) do
			table.insert(floating, k)
		end
		table.sort(floating)
		check(table.concat(keys, ",") == "Attributes,ClientAction,Enabled,FacingDegrees,FloatingWords,FolderName,"
				.. "Notices,Position,PromptDistance,PromptHoldSeconds,QuoteSeconds,ReachStuds,ServerAction,SuccessTitle"
				and table.concat(floating, ",") == "Above,Colour,Height,NoteHeight,SubHeight,Text,Width",
			"the pedestal's config has no price, product or upgrade in it, and its floating words only words",
			table.concat(keys, ",") .. " / " .. table.concat(floating, ","))

		-- THE WORDS. NoticeSpec's two rules for a refusal's notice, held here for
		-- the pedestal's: HudLayoutSpec measures the same lines on every phone.
		local bad = {}
		local lines = { { "success", { title = CONFIG.SuccessTitle,
			detail = GameConfig.sacrificeOffer(BALANCE.Multiplier, BALANCE.DurationSeconds) .. "." } },
			{ "COOLDOWN's time", { title = CONFIG.Notices.COOLDOWN.title,
				detail = GameConfig.sacrificeReadyIn(BALANCE.CooldownSeconds) } } }
		for code, line in pairs(CONFIG.Notices) do
			table.insert(lines, { code, line })
		end
		for _, row in ipairs(lines) do
			local code, line = row[1], row[2]
			if type(line.title) ~= "string" or string.upper(line.title) ~= line.title or #line.title > 20
				or string.find(line.title, "[^%w %p]") then
				table.insert(bad, code .. " title")
			end
			if line.detail and (#line.detail > 48 or string.sub(line.detail, -1) ~= ".") then
				table.insert(bad, code .. " detail")
			end
		end
		table.sort(bad)
		check(#bad == 0, "every notice is a short upper-case headline and one short next step", table.concat(bad, ", "))
		check(CONFIG.Notices.COOLDOWN.detail == nil and GameConfig.sacrificeReadyIn(125.2) == "Ready in 2:06."
				and GameConfig.sacrificeReadyIn(-4) == "Ready in 0:00.",
			"the recharge notice says the time left, rounded up, never below zero", GameConfig.sacrificeReadyIn(125.2))
		check(GameConfig.sacrificeSpan(45) == "45 seconds" and GameConfig.sacrificeSpan(1) == "1 second"
				and GameConfig.sacrificeSpan(180) == "3 minutes" and GameConfig.sacrificeSpan(60) == "1 minute"
				and GameConfig.sacrificeSpan(150) == "2 min 30 s",
			"lengths of time are said plainly", GameConfig.sacrificeSpan(150))
		check(GameConfig.sacrificeOffer(BALANCE.Multiplier, BALANCE.DurationSeconds)
				== "+50% garden income for 45 seconds",
			"and the offer reads: +50% garden income for 45 seconds")
		for _, line in pairs(CONFIG.Notices) do
			local words = string.lower(line.title .. " " .. (line.detail or ""))
			check(not string.find(words, "sale", 1, true) and not string.find(words, "robux", 1, true)
					and not string.find(words, "buy", 1, true),
				"  " .. line.title .. ": promises nothing the pedestal does not do")
		end
	end)

	--==========================================================================
	-- 2. THE PEDESTAL
	--==========================================================================
	section("the pedestal", function()
		sac.Init()
		sac.Start()
		sac.Init()
		sac.Start()
		local count = 0
		for _, child in ipairs(Workspace:GetChildren()) do
			if child.Name == CONFIG.FolderName then
				count += 1
			end
		end
		check(count == 1, "starting twice leaves one pedestal, not two", count)
		local folder = Workspace:FindFirstChild(CONFIG.FolderName)
		local model = folder and folder:FindFirstChild("SacrificePedestal")
		check(folder ~= nil and folder.Archivable == false and model ~= nil and model:IsA("Model"),
			"it is built into its own folder, which is never saved into the place")
		check(model.ModelStreamingMode == Enum.ModelStreamingMode.Persistent,
			"and is persistent under streaming, so its prompt is there for a player across the field")
		local allThere, allAnchored = true, true
		for _, name in ipairs({ "Foot", "Column", "OfferingBowl", "Recess", "Sign", "SignBack" }) do
			local part = model:FindFirstChild(name)
			if not (part and part:IsA("BasePart")) then
				allThere = false
			elseif not part.Anchored then
				allAnchored = false
			end
		end
		check(allThere and allAnchored, "foot, column, bowl, recess and a sign front and back, all anchored")
		top = model.PrimaryPart
		check(top ~= nil and top.Name == "OfferingBowl", "the bowl is what reach is measured to")
		local foot = model.Foot
		check(math.abs((foot.Position.Y - foot.Size.Y / 2) - CONFIG.Position.Y) < 1e-3
				and math.abs(foot.Position.X - CONFIG.Position.X) < 1e-3
				and math.abs(foot.Position.Z - CONFIG.Position.Z) < 1e-3,
			"its foot stands on the deck at GameConfig's position", tostring(foot.Position))
		local lettered = true
		local why = nil
		for _, name in ipairs({ "Sign", "SignBack" }) do
			local face = model[name]:FindFirstChild("Face")
			if not (face and face:IsA("SurfaceGui") and face.Face == Enum.NormalId.Front
				and face.Title.Text == "SACRIFICE A POD"
				and face.Offer.Text == string.format("+%d%% GARDEN INCOME FOR %ds", 50, BALANCE.DurationSeconds)
				and face.Status.Text == "") then
				lettered, why = false, name .. "'s words"
			elseif face.LightInfluence ~= 0 or face.MaxDistance <= 0 then
				lettered, why = false, name .. " is lit by the world, or drawn at any distance"
			else
				for _, line in ipairs({ face.Title, face.Offer, face.Status }) do
					local edge = line:FindFirstChildOfClass("UIStroke")
					if not (edge and edge.Thickness >= 1.5 and line.TextScaled) then
						lettered, why = false, name .. "." .. line.Name .. " has no outline"
					end
				end
			end
		end
		check(lettered, "both signs say what is given and what it buys, outlined and self-lit, and leave each "
			.. "player's own line empty", why)
		local front, back = model.Sign.CFrame.LookVector, model.SignBack.CFrame.LookVector
		check(front:Dot(back) < -0.999, "the two signs face opposite ways", front:Dot(back))
		local toCentre = (Vector3.new(0, model.Sign.Position.Y, 0) - model.Sign.Position).Unit
		check(math.deg(math.acos(math.clamp(front:Dot(toCentre), -1, 1))) < 12,
			"the front one looks at the deck's centre, so the back one looks at the road",
			math.deg(math.acos(math.clamp(front:Dot(toCentre), -1, 1))))

		-- WHERE IT STANDS. The deck is a disc of GameConfig.Map.HubRadius about the
		-- origin; the prompts are where a Play survey found them on 2026-09-28
		-- (the chest's and the wheel's from their own config).
		local at = Vector3.new(CONFIG.Position.X, 0, CONFIG.Position.Z)
		local halfDiagonal = math.sqrt(2) * foot.Size.X / 2
		check(at.Magnitude + halfDiagonal <= GameConfig.Map.HubRadius - 1,
			"its whole foot is on the deck, clear of the rim", at.Magnitude + halfDiagonal)
		local WheelData = require(Shared.WheelData)
		local wheelAt = WheelData.Place.Position
		local others = {
			{ "the Bonus Chest", GameConfig.BonusChest.Position, GameConfig.BonusChest.PromptDistance },
			{ "the wheel", Vector3.new(wheelAt.X, 0, wheelAt.Z + 6.3), WheelData.Place.PromptDistance },
			{ "SELL ONE", Vector3.new(-15.5, 0, 20), GameConfig.SellOne.PromptDistance },
			{ "SELL ALL", Vector3.new(15.5, 0, 20), GameConfig.SellOne.PromptDistance },
			{ "Marigold", Vector3.new(-0.95, 0, 20.12), 11 },
		}
		local shared = {}
		for _, other in ipairs(others) do
			local apart = (Vector3.new(other[2].X, 0, other[2].Z) - at).Magnitude
			if apart <= other[3] + CONFIG.PromptDistance then
				table.insert(shared, string.format("%s (%.1f apart, reaches %d + %d)", other[1], apart, other[3],
					CONFIG.PromptDistance))
			end
		end
		check(#shared == 0, "no other prompt can be in range together with the pedestal's", table.concat(shared, ", "))
		check((at - Vector3.new(0, 0, 0)).Magnitude > 12, "and it is clear of the spawn in the deck's middle")
		local prompts = 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				prompts += 1
			end
		end
		local prompt = top:FindFirstChild("SacrificePrompt")
		check(prompts == 1 and prompt ~= nil and prompt.Style == Enum.ProximityPromptStyle.Custom
				and prompt.RequiresLineOfSight == false and prompt.ActionText == "Sacrifice",
			"one prompt, in the game's own chrome", prompts)
		-- The engine keeps both as single-precision numbers.
		check(math.abs(prompt.HoldDuration - CONFIG.PromptHoldSeconds) < 1e-4 and prompt.HoldDuration > 0
				and math.abs(prompt.MaxActivationDistance - CONFIG.PromptDistance) < 1e-4,
			"held a moment, and in range from GameConfig's distance",
			string.format("%s s, %s studs", tostring(prompt.HoldDuration), tostring(prompt.MaxActivationDistance)))
		local chestAt = GameConfig.BonusChest.Position
		local apart = (Vector3.new(chestAt.X, 0, chestAt.Z)
			- Vector3.new(CONFIG.Position.X, 0, CONFIG.Position.Z)).Magnitude
		check(apart > CONFIG.PromptDistance + GameConfig.BonusChest.PromptDistance,
			"the Bonus Chest's prompt and the pedestal's are never both in range", string.format("%.1f studs", apart))
		NEAR = CFrame.new(top.Position + Vector3.new(0, 0, -5))
		FAR = CFrame.new(top.Position + Vector3.new(0, 0, -(CONFIG.ReachStuds + 4)))
	end)
	assert(top, "no pedestal was built; nothing below can run")

	--==========================================================================
	-- 3. WHAT IS REFUSED, BEFORE ANY QUOTE IS MADE
	--==========================================================================
	section("refusals", function()
		seed(-7101, { Held = deepCopy(BAG), Cash = 1000 })
		giver = enter("SpecGiver", -7101)
		garden(giver, GARDEN)
		check(carry.IsHeldRestored(giver) and #toolsOf(giver) == #BAG and rowsOf(giver) == #BAG,
			"the giver is in: alive, the saved bag rebuilt and armed", #toolsOf(giver))
		local atStart = snapshot(giver)

		-- What the giver has is counted just before the offer and again after.
		local function refused(reason, label)
			local before = snapshot(giver)
			local r = quote(giver)
			check(r.phase == "refused" and r.reason == reason, label, r.reason or r.phase)
			local pendingNow = sac.PendingFor(giver)
			local kept, why = same(before, snapshot(giver))
			check(pendingNow == nil and kept, "  ...with no quote made and nothing changed", why or pendingNow)
		end

		refused("NOTHING_HELD", "empty hands, pods in the bag: nothing is chosen for the player")

		local bat = Instance.new("Tool")
		bat.Name = "Rootwood Bat"
		bat:SetAttribute("WeaponId", "rootwood")
		bat.Parent = giver.Character
		refused("NOT_A_POD", "a bat in the hands is not a pod")
		bat:Destroy()

		-- Made and offered in one resumption, so CarryService's own recording
		-- has not seen them: what the saved bag lists is the test of ownership.
		local function forged(id, tier, hatched)
			local tool = Instance.new("Tool")
			tool.Name = "???"
			tool:SetAttribute("SpeciesId", id)
			tool:SetAttribute(KG, tier)
			tool:SetAttribute("Hatched", hatched)
			tool.Parent = giver.Character
			return tool
		end
		for _, case in ipairs({
			{ "notaplant", 2, "a species that does not exist" },
			{ "nubkin", 0, "a tier of 0" },
			{ "nubkin", 2.5, "a tier of 2.5" },
			{ "nubkin", SeedData.TierCount + 1, "a tier past the last" },
			{ "nubkin", 0 / 0, "a tier that is not a number" },
			{ "nubkin", -2, "a negative tier" },
		}) do
			local tool = forged(case[1], case[2], false)
			refused("NOT_A_POD", "a Tool with " .. case[3] .. " is not a pod")
			tool:Destroy()
		end

		local stranger = forged("dunebud", 5, false)
		refused("NOT_OWNED", "a real pod the saved bag has no row for is not theirs to give")
		stranger:Destroy()
		task.wait()

		emptyHands(giver)
		local grown = nil
		for _, tool in ipairs(toolsOf(giver)) do
			if tool:GetAttribute("Hatched") == true then
				grown = tool
			end
		end
		grown.Parent = giver.Character
		task.wait()
		refused("HATCHED", "a grown plant is refused")
		emptyHands(giver)

		local pod = hold(giver, "petalpip", 1)
		local realCarrying = carry.IsCarrying
		carry.IsCarrying = function()
			return true
		end
		refused("CARRYING", "a raided pod in the arms -- loot not yet banked -- refuses the whole offer")
		carry.IsCarrying = realCarrying

		giver.Character.HumanoidRootPart.CFrame = FAR
		refused("TOO_FAR", "a prompt fired from beyond reach is refused at the quote")
		giver.Character.HumanoidRootPart.CFrame = NEAR
		local deadPedestal = Instance.new("Part")
		deadPedestal.Position = top.Position
		local r = sac.Quote(giver, deadPedestal)
		check(r.phase == "refused" and r.reason == "TOO_FAR" and sac.PendingFor(giver) == nil,
			"a pedestal that is not in the world is out of reach", r.reason)
		deadPedestal:Destroy()

		local plot = plotFor[giver]
		plotFor[giver] = nil
		refused("NO_GARDEN", "no plot: there is no garden to boost")
		plotFor[giver] = plot
		ownerFor[plot] = { Name = "SomebodyElse" }
		refused("NO_GARDEN", "a plot that is somebody else's")
		ownerFor[plot] = giver
		grownFor[plot] = {}
		refused("NO_GARDEN", "a garden with nothing grown in it: the pod would buy nothing")
		grownFor[plot] = GARDEN

		local humanoid = giver.Character:FindFirstChildOfClass("Humanoid")
		humanoid.Health = 0
		refused("GONE", "a dead body offers nothing")
		humanoid.Health = 100
		local body = giver.Character
		giver.Character = nil
		refused("GONE", "no body at all")
		giver.Character = body
		giver.Parent = nil
		refused("GONE", "a player who has left")
		giver.Parent = Players

		local unloaded = standIn("NeverLoaded", -7102)
		newBackpack(unloaded)
		newBody(unloaded)
		r = quote(unloaded)
		check(r.phase == "refused" and r.reason == "NOT_READY" and sac.PendingFor(unloaded) == nil,
			"a profile that has not loaded", r.reason)

		loadAs[-7103] = "unavailable"
		local temporary = enter("NoSaving", -7103)
		garden(temporary, GARDEN)
		carry.GivePod(temporary, "nubkin", 2)
		task.wait()
		local lent = podTools(temporary, "nubkin", 2)[1]
		lent.Parent = temporary.Character
		task.wait()
		r = quote(temporary)
		check(not data.IsPersistent(temporary) and r.phase == "refused" and r.reason == "NOT_SAVED"
				and sac.PendingFor(temporary) == nil and lent.Parent == temporary.Character,
			"a temporary profile, which could never keep the exchange, is refused and keeps its pod", r.reason)

		seed(-7104, { Held = { { Id = "nubkin", Tier = 2, Hatched = false } } })
		local early = enter("BagNotBack", -7104, false)
		garden(early, GARDEN)
		local loose = Instance.new("Tool")
		loose.Name = "???"
		loose:SetAttribute("SpeciesId", "nubkin")
		loose:SetAttribute(KG, 2)
		loose:SetAttribute("Hatched", false)
		loose.Parent = early.Character
		r = quote(early)
		check(not carry.IsHeldRestored(early) and r.phase == "refused" and r.reason == "BAG_NOT_READY"
				and sac.PendingFor(early) == nil,
			"before the saved bag has been put back, nothing in the hands is evidence of anything", r.reason)
		loose:Destroy()

		check(pod.Parent == giver.Character, "and through all of it the giver still holds the pod")
		task.wait()
		local kept, why = same(atStart, snapshot(giver))
		check(kept, "with the bag, the saved rows, the clocks and the cash they started with", why)
		emptyHands(giver)
	end)

	--==========================================================================
	-- 4. THE PEDESTAL SWITCHED OFF
	--==========================================================================
	section("switched off", function()
		local module = Server.SacrificeService
		local chunk, loadErr = loadstring(module.Source, "=SacrificeService")
		assert(chunk, tostring(loadErr))
		local off = setmetatable({
			Sacrifice = setmetatable({ Enabled = false, FolderName = "SeedSacrificePedestalOffSpec" },
				{ __index = CONFIG }),
		}, { __index = GameConfig })
		local outerRequire = require
		setfenv(chunk, setmetatable({
			script = module,
			require = function(target)
				if typeof(target) == "Instance" and target.Name == "GameConfig" then
					return off
				end
				return outerRequire(target)
			end,
		}, { __index = getfenv(1) }))
		local Off = chunk()
		Off.Init()
		Off.Start()
		check(Workspace:FindFirstChild("SeedSacrificePedestalOffSpec") == nil, "switched off, no pedestal is built")
		local pod = hold(giver, "petalpip", 1)
		local r = Off.Quote(giver, top)
		check(r.phase == "refused" and r.reason == "DISABLED" and Off.PendingFor(giver) == nil
				and pod.Parent == giver.Character,
			"an offer is refused as DISABLED", r.reason)
		local profile = data.Get(giver)
		local kept = profile.SacrificeEndsAt
		profile.SacrificeEndsAt = wall + 30
		check(Off.Multiplier(giver) == 1, "and a boost left running by an earlier build pays nothing")
		Off.Publish(giver)
		check(giver:GetAttribute(ATTR.EndsAt) == nil and giver:GetAttribute(ATTR.Multiplier) == nil
				and giver:GetAttribute(ATTR.NextAt) == nil,
			"and nothing is published for the HUD to draw")
		profile.SacrificeEndsAt = kept
		Off.Stop()
		emptyHands(giver)
	end)

	--==========================================================================
	-- 5. THE QUOTE
	--==========================================================================
	local function speciesFree(payload)
		for k, v in pairs(payload) do
			local key = string.lower(tostring(k))
			if string.find(key, "species", 1, true) or key == "id" or key == "name" or key == "rarity" then
				return false, "a field named " .. tostring(k)
			end
			if type(v) == "string" then
				for _, species in ipairs(SeedData.Species or {}) do
					if string.find(string.lower(v), string.lower(species.Id), 1, true)
						or string.find(string.lower(v), string.lower(species.Name), 1, true) then
						return false, tostring(k) .. " = " .. v
					end
				end
			end
		end
		return true, nil
	end

	section("the quote", function()
		local pod = hold(giver, "nubkin", 2)
		local before = snapshot(giver)
		local r = quote(giver)
		check(r.phase == "quote", "a banked, unhatched pod in its owner's hands is quoted", r.reason)
		check(r.tier == 2 and r.multiplier == BALANCE.Multiplier and r.seconds == BALANCE.DurationSeconds
				and r.cooldown == BALANCE.CooldownSeconds,
			"naming its size, what it buys, for how long, and the recharge")
		local allowed = { phase = true, token = true, tier = true, multiplier = true, seconds = true, cooldown = true }
		local extra = {}
		for k in pairs(r) do
			if not allowed[k] then
				table.insert(extra, tostring(k))
			end
		end
		local hidden, leak = speciesFree(r)
		check(#extra == 0 and hidden, "and NOTHING about what is inside it", leak or table.concat(extra, ","))
		check(type(r.token) == "number" and r.token >= 1 and sac.PendingFor(giver) == r.token,
			"with a token that is the quote on the table", r.token)
		local kept, why = same(before, snapshot(giver))
		check(kept and pod.Parent == giver.Character, "and quoting took nothing", why)

		local first = r.token
		r = quote(giver)
		check(r.phase == "quote" and r.token ~= first and sac.PendingFor(giver) == r.token,
			"pressing again replaces the quote with a new token")
		check(yes(giver, first) == nil and pod.Parent == giver.Character and sac.PendingFor(giver) == r.token,
			"the old token finds nothing, takes nothing, and leaves the live quote alone")
		kept, why = same(before, snapshot(giver))
		check(kept, "nothing changed", why)
	end)

	--==========================================================================
	-- 6. ANSWERS THAT MUST NOT TAKE THE POD
	--==========================================================================
	section("answers that must not sacrifice", function()
		local pod = podTools(giver, "nubkin", 2)[1]
		for _, candidate in ipairs(podTools(giver, "nubkin", 2)) do
			if candidate.Parent == giver.Character then
				pod = candidate
			end
		end
		local before = snapshot(giver)
		local live = sac.PendingFor(giver)
		for _, bad in ipairs({ "yes", 42, true, { token = "1", accept = true }, { token = 0 / 0, accept = true },
			{ token = 1.5, accept = true }, { token = -1, accept = true }, { token = 0, accept = true },
			{ token = 1e13, accept = true }, { token = math.huge, accept = true }, { accept = true }, {} }) do
			check(sac.Confirm(giver, bad) == nil, "a malformed answer is dropped: "
				.. tostring(if type(bad) == "table" then "token " .. tostring(bad.token) else bad))
		end
		check(sac.Confirm(giver, nil) == nil, "a nil answer is dropped")
		check(yes(giver, live + 1000) == nil and yes(giver, live - 1) == nil,
			"a token that is not this player's quote is dropped")
		local kept, why = same(before, snapshot(giver))
		check(sac.PendingFor(giver) == live and kept and pod.Parent == giver.Character,
			"and the live quote survives all of them, with nothing taken", why)

		for _, vague in ipairs({ "true", 1, "yes" }) do
			local r = quote(giver)
			local a = sac.Confirm(giver, { token = r.token, accept = vague })
			check(a ~= nil and a.phase == "cancelled" and pod.Parent == giver.Character,
				"only the boolean true is a yes: accept = " .. tostring(vague) .. " cancels")
		end

		local r = quote(giver)
		local no = sac.Confirm(giver, { token = r.token, accept = false })
		check(no ~= nil and no.phase == "cancelled" and sac.PendingFor(giver) == nil, "a no is a cancel, and forgets the quote")
		kept, why = same(before, snapshot(giver))
		check(kept and pod.Parent == giver.Character, "and changes nothing", why)
		check(yes(giver, r.token) == nil and pod.Parent == giver.Character, "a yes after the no finds nothing")

		r = quote(giver)
		mono += CONFIG.QuoteSeconds + 1
		local late = yes(giver, r.token)
		check(late ~= nil and late.phase == "refused" and late.reason == "EXPIRED",
			"a yes after QuoteSeconds is refused as expired", late and late.reason)
		kept, why = same(before, snapshot(giver))
		check(kept and pod.Parent == giver.Character and sac.PendingFor(giver) == nil, "with the pod kept", why)

		r = quote(giver)
		giver.Character.HumanoidRootPart.CFrame = FAR
		local far = yes(giver, r.token)
		check(far ~= nil and far.reason == "TOO_FAR", "a yes from beyond reach is refused", far and far.reason)
		giver.Character.HumanoidRootPart.CFrame = NEAR
		kept, why = same(before, snapshot(giver))
		check(kept and pod.Parent == giver.Character, "with the pod kept", why)

		r = quote(giver)
		pod.Parent = giver._backpack
		local away = yes(giver, r.token)
		check(away ~= nil and away.reason == "CHANGED", "a yes after the pod was put away is refused as changed",
			away and away.reason)
		check(pod.Parent == giver._backpack, "and the pod stays in the bag")
		task.wait()

		pod.Parent = giver.Character
		task.wait()
		r = quote(giver)
		local twin = nil
		for _, candidate in ipairs(podTools(giver, "nubkin", 2)) do
			if candidate ~= pod then
				twin = candidate
			end
		end
		pod.Parent = giver._backpack
		twin.Parent = giver.Character
		local swapped = yes(giver, r.token)
		check(swapped ~= nil and swapped.reason == "CHANGED",
			"a yes after the hands changed to an IDENTICAL pod is refused: no substitution", swapped and swapped.reason)
		check(twin.Parent == giver.Character and pod.Parent == giver._backpack and rowsOf(giver, "nubkin", 2, false) == 2,
			"and neither twin was taken")
		task.wait()
		twin.Parent = giver._backpack
		pod.Parent = giver.Character
		task.wait()

		-- The bag settles first, so nothing records the Tool while it says 3.
		r = quote(giver)
		pod:SetAttribute(KG, 3)
		local resized = yes(giver, r.token)
		pod:SetAttribute(KG, 2)
		check(resized ~= nil and resized.reason == "CHANGED" and pod.Parent == giver.Character,
			"a pod whose size changed after the panel showed it is refused: what was shown is what is taken",
			resized and resized.reason)
		kept, why = same(before, snapshot(giver))
		check(kept, "nothing changed", why)

		r = quote(giver)
		local humanoid = giver.Character:FindFirstChildOfClass("Humanoid")
		humanoid.Health = 0
		local dead = yes(giver, r.token)
		humanoid.Health = 100
		check(dead ~= nil and dead.reason == "GONE" and pod.Parent == giver.Character,
			"a yes from a body that has died is refused", dead and dead.reason)

		r = quote(giver)
		sac.Forget(giver)
		check(yes(giver, r.token) == nil and pod.Parent == giver.Character, "a forgotten quote cannot be answered")

		r = quote(giver)
		local plot = plotFor[giver]
		grownFor[plot] = {}
		local bare = yes(giver, r.token)
		grownFor[plot] = GARDEN
		check(bare ~= nil and bare.reason == "NO_GARDEN" and pod.Parent == giver.Character,
			"a garden emptied between the quote and the yes: refused, the pod kept", bare and bare.reason)
		kept, why = same(before, snapshot(giver))
		check(kept, "and after every one of those the giver has exactly what they started with", why)
	end)

	--==========================================================================
	-- 7. THE SACRIFICE
	--==========================================================================
	local trace = {}
	local watched = nil
	local realSetSacrifice, realSync, realSetHeld = data.SetSacrifice, carry.SyncHeldNow, data.SetHeld
	data.SetSacrifice = function(player, nextAt, endsAt)
		table.insert(trace, { name = "SetSacrifice", parent = watched and watched.Parent })
		return realSetSacrifice(player, nextAt, endsAt)
	end
	carry.SyncHeldNow = function(player, consumed)
		table.insert(trace, { name = "SyncHeldNow", parent = watched and watched.Parent,
			consumed = if consumed then #consumed else 0, first = consumed and consumed[1] })
		return realSync(player, consumed)
	end
	data.SetHeld = function(player, rows)
		table.insert(trace, { name = "SetHeld", rows = #rows })
		return realSetHeld(player, rows)
	end
	local function named(name)
		local list = {}
		for i, t in ipairs(trace) do
			if t.name == name then
				t.at = i
				table.insert(list, t)
			end
		end
		return list
	end

	local T0
	section("the sacrifice", function()
		local pod = nil
		for _, candidate in ipairs(podTools(giver, "nubkin", 2)) do
			if candidate.Parent == giver.Character then
				pod = candidate
			end
		end
		assert(pod, "the giver is not holding the nubkin pod")
		local twin = nil
		for _, candidate in ipairs(podTools(giver, "nubkin", 2)) do
			if candidate ~= pod then
				twin = candidate
			end
		end
		task.wait()
		wall = os.time()
		T0 = wall
		local before = snapshot(giver)
		local others = {}
		for _, tool in ipairs(toolsOf(giver)) do
			if tool ~= pod then
				others[tool] = tool.Parent
			end
		end
		local r = quote(giver)
		table.clear(trace)
		watched = pod
		local done = yes(giver, r.token)
		local sets, syncs, helds = named("SetSacrifice"), named("SyncHeldNow"), named("SetHeld")
		watched = nil

		check(done ~= nil and done.phase == "sacrificed", "a yes to a live quote sacrifices the pod", done and done.reason)
		check(done.token == r.token and done.tier == 2 and done.multiplier == BALANCE.Multiplier
				and done.seconds == BALANCE.DurationSeconds and done.endsAt == T0 + BALANCE.DurationSeconds
				and done.nextAt == T0 + BALANCE.CooldownSeconds,
			"and reports the size taken, the boost, when it ends and when the pedestal is ready again")
		local hidden, leak = speciesFree(done)
		check(hidden, "without saying what was inside", leak)

		check(destroyed(pod), "the pod is destroyed")
		check(rowsOf(giver, "nubkin", 2, false) == 1 and rowsOf(giver) == before.rows - 1,
			"exactly one row came off the saved bag: that pod's", rowsOf(giver))
		local untouched = true
		for tool, parent in pairs(others) do
			if tool.Parent ~= parent then
				untouched = false
			end
		end
		check(untouched and twin.Parent == giver._backpack and #toolsOf(giver) == before.tools - 1,
			"its identical twin and everything else in the bag are untouched", #toolsOf(giver))

		local profile = data.Get(giver)
		check(profile.SacrificeNextAt == T0 + BALANCE.CooldownSeconds
				and profile.SacrificeEndsAt == T0 + BALANCE.DurationSeconds,
			"the profile holds the cooldown and the boost's expiry, both counted from the same moment")
		check(sac.Multiplier(giver) == BALANCE.Multiplier, "the boost is running", sac.Multiplier(giver))
		check(giver:GetAttribute(ATTR.NextAt) == T0 + BALANCE.CooldownSeconds
				and giver:GetAttribute(ATTR.EndsAt) == T0 + BALANCE.DurationSeconds
				and giver:GetAttribute(ATTR.Multiplier) == BALANCE.Multiplier,
			"and all three attributes are published in the same resumption, for the sign and the boost row")
		check(profile.Cash == before.cash, "no cash changed hands: the reward is the boost and nothing else", profile.Cash)

		-- THE ORDER, from what each call saw.
		check(#sets == 1 and #syncs == 1, "the clock was written once and the bag re-synced once",
			string.format("%d / %d", #sets, #syncs))
		check(#sets == 1 and sets[1].parent == giver.Character,
			"the clock -- the one step that can refuse -- was written while the pod was still in the hands")
		check(#syncs == 1 and syncs[1].consumed == 1 and syncs[1].first == pod and syncs[1].parent == nil,
			"the pod was out of the hands when its row came off, and it was the only Tool named")
		check(#sets == 1 and #syncs == 1 and sets[1].at < syncs[1].at and #helds >= 1
				and helds[#helds].rows == before.rows - 1,
			"clock first, then the bag: written as one pod fewer", helds[#helds] and helds[#helds].rows)
		check(sac.PendingFor(giver) == nil, "and the quote is spent")

		-- The same yes again, in the same frame.
		local after = snapshot(giver)
		table.clear(trace)
		check(yes(giver, r.token) == nil and yes(giver, r.token) == nil, "the same yes again, twice, answers nothing")
		local kept, why = same(after, snapshot(giver))
		check(kept and #trace == 0, "and takes nothing: no second pod, no second clock, no write at all", why or #trace)
	end)

	--==========================================================================
	-- 8. WHAT THE BOOST REACHES
	--==========================================================================
	section("income", function()
		local profile = data.Get(giver)
		wall = T0 + 1
		check(econ.RateFor(giver) == BASE * 1.5, "garden income is x1.5 while the boost runs",
			string.format("%s of %s", tostring(econ.RateFor(giver)), tostring(BASE)))

		-- The client's mirror, off the attributes alone.
		check(GameConfig.sacrificeIncomeBoost(giver) == BALANCE.Multiplier and GameConfig.incomeMultiplier(giver) == 1.5,
			"and every client display multiplies by the same 1.5, read off the attributes",
			GameConfig.incomeMultiplier(giver))

		-- With the Bonus Chest's +25% income reward: the two ADD.
		data.SetChest(giver, os.time() + 600, "income", os.time() + 120)
		giver:SetAttribute(GameConfig.BonusChest.Attributes.Boost, "income")
		giver:SetAttribute(GameConfig.BonusChest.Attributes.EndsAt, os.time() + 120)
		check(BonusChestService.Multiplier(giver, "income") == 1.25, "with the chest's +25% income reward running")
		check(econ.RateFor(giver) == BASE * 1.75, "the two ADD: +25% and +50% are +75%, not the +87.5% a product would be",
			econ.RateFor(giver) / BASE)
		check(GameConfig.incomeMultiplier(giver) == 1.75, "and the displays agree", GameConfig.incomeMultiplier(giver))

		-- And the x2 pass multiplies their sum.
		passFor[giver] = 2
		giver:SetAttribute(GameConfig.Pass.MultiplierAttribute, 2)
		check(econ.RateFor(giver) == BASE * 3.5, "the x2 pass multiplies the sum: x3.5", econ.RateFor(giver) / BASE)
		check(GameConfig.incomeMultiplier(giver) == 3.5, "and the displays agree", GameConfig.incomeMultiplier(giver))

		-- The chest's TRAINING reward is not income and adds nothing here.
		data.SetChest(giver, os.time() + 600, "training", os.time() + 120)
		giver:SetAttribute(GameConfig.BonusChest.Attributes.Boost, "training")
		check(econ.RateFor(giver) == BASE * 1.5 * 2 and GameConfig.incomeMultiplier(giver) == 3,
			"the chest's training reward adds nothing to income: x1.5, x2 by the pass", econ.RateFor(giver) / BASE)
		check(BonusChestService.Multiplier(giver, "training") == 1.25,
			"and the pedestal adds nothing to training: the mill's boost is the chest's alone")

		-- SALES: the stall's prices, with the pass, the chest and the pedestal all on.
		data.SetChest(giver, os.time() + 600, "income", os.time() + 120)
		local expect = 0
		for _, tool in ipairs(toolsOf(giver)) do
			expect += SeedData.SellPrice(SeedData.Get(tool:GetAttribute("SpeciesId")), tool:GetAttribute(KG))
		end
		local held = econ.QuoteHeld(giver)
		check(held.total == expect and #held.tools == #toolsOf(giver),
			"SELL ALL quotes the bag at SeedData.SellPrice exactly: a sale carries no boost", held.total)
		local grown = nil
		for _, tool in ipairs(toolsOf(giver)) do
			if tool:GetAttribute("Hatched") == true then
				grown = tool
			end
		end
		emptyHands(giver)
		grown.Parent = giver.Character
		task.wait()
		local one = econ.QuoteOne(giver, grown)
		check(one ~= nil and one.price == SeedData.SellPrice(SeedData.Get("spiretip"), 3),
			"SELL ONE quotes the base price too", one and one.price)
		emptyHands(giver)
		task.wait()

		-- THE OFFLINE CLAIM: the pass, and nothing temporary.
		local cashBefore = profile.Cash
		profile.OfflineCash = 1000
		profile.OfflineSeconds = 600
		local paid, reason = econ.ClaimOffline(giver)
		check(paid == 2000 and reason == "OK" and profile.Cash == cashBefore + 2000,
			"an offline claim of 1,000 pays 2,000 under the pass -- not 3,500: no temporary boost reaches it", paid)
		local plantsRows = {
			{ SpeciesId = "nubkin", Tier = 3, Stage = STAGE_GROWN },
			{ SpeciesId = "novaorb", Tier = 4, Stage = STAGE_GROWN },
		}
		local now = os.time()
		local plain = { LastSeen = now - 7200, Plants = plantsRows, SacrificeEndsAt = 0, SacrificeNextAt = 0 }
		local boosted = { LastSeen = now - 7200, Plants = plantsRows, SacrificeEndsAt = now + 30,
			SacrificeNextAt = now + 165 }
		local a = OfflineEarnings.accrue(plain, now)
		local b = OfflineEarnings.accrue(boosted, now)
		check(a > 0 and a == b, "and time away is credited the same with a boost still on the clock", string.format("%s / %s", a, b))

		-- A ONE-OFF REWARD -- a Biome Harvest, a wheel prize -- pays its own amount.
		cashBefore = profile.Cash
		check(econ.PayReward(giver, 500, "spec") == true and profile.Cash == cashBefore + 500,
			"a one-off reward of 500 pays 500", profile.Cash - cashBefore)

		-- Nobody else's income moves.
		seed(-7105, { Held = {} })
		local neighbour = enter("Neighbour", -7105)
		garden(neighbour, GARDEN)
		check(econ.RateFor(neighbour) == BASE and sac.Multiplier(neighbour) == 1,
			"a neighbour with the same garden earns the base rate: the boost is the giver's alone")

		-- No garden, no income, boost or not.
		local plot = plotFor[giver]
		grownFor[plot] = {}
		check(econ.RateFor(giver) == 0, "an empty garden earns 0 whatever is running")
		grownFor[plot] = GARDEN

		passFor[giver] = nil
		giver:SetAttribute(GameConfig.Pass.MultiplierAttribute, nil)
		data.SetChest(giver, 0, "", 0)
		giver:SetAttribute(GameConfig.BonusChest.Attributes.Boost, nil)
		giver:SetAttribute(GameConfig.BonusChest.Attributes.EndsAt, nil)
		check(econ.RateFor(giver) == BASE * 1.5, "back to the pedestal alone: x1.5")
	end)

	--==========================================================================
	-- 9. THE FAUCET ITSELF, TICKING
	--
	-- A second copy of the real EconomyService whose Players is the giver, so
	-- its own tick pays them: the same siblings, the same profile.
	--==========================================================================
	section("the tick", function()
		local module = Server.EconomyService
		local chunk, loadErr = loadstring(module.Source, "=EconomyService")
		assert(chunk, tostring(loadErr))
		local fakePlayers = {
			PlayerRemoving = {
				Connect = function()
					return { Disconnect = function() end }
				end,
			},
		}
		function fakePlayers:GetPlayers()
			return { giver }
		end
		local fakeGame = {}
		function fakeGame:GetService(name)
			if name == "Players" then
				return fakePlayers
			end
			return game:GetService(name)
		end
		local siblings = {
			PlotService = PlotService, PlantService = PlantService, PlayerDataService = PlayerDataService,
			CarryService = CarryService, PassService = PassService, BonusChestService = BonusChestService,
			SacrificeService = SacrificeService, Metrics = Metrics,
		}
		local parent = {}
		function parent:WaitForChild(name)
			assert(siblings[name] ~= nil, "EconomyService asked for an unexpected sibling " .. name)
			return { __standIn = siblings[name] }
		end
		local outerRequire = require
		setfenv(chunk, setmetatable({
			game = fakeGame,
			script = { Name = "EconomyService", Parent = parent },
			require = function(target)
				if type(target) == "table" and target.__standIn ~= nil then
					return target.__standIn
				end
				return outerRequire(target)
			end,
		}, { __index = getfenv(1) }))
		local Ticking = chunk()

		local payments = {}
		local realAdd = data.AddCash
		data.AddCash = function(player, amount)
			table.insert(payments, { amount = amount, at = os.clock() })
			return realAdd(player, amount)
		end
		local plot = plotFor[giver]
		local function rates(from)
			local list = {}
			for i = from + 1, #payments do
				local dt = payments[i].at - payments[i - 1].at
				if i > 1 and dt > 0 then
					table.insert(list, payments[i].amount / dt)
				end
			end
			return list
		end
		local function allNear(list, want)
			if #list == 0 then
				return false, "no payment was timed"
			end
			for _, rate in ipairs(list) do
				if math.abs(rate - want) > want * 0.03 then
					return false, string.format("%.2f/s where %.2f/s was due", rate, want)
				end
			end
			return true, string.format("%d payment(s) near %.2f/s", #list, want)
		end

		wall = T0 + 2
		Ticking.Init()
		Ticking.Start()
		task.wait(3.4)
		local during = #payments
		local okDuring, noteDuring = allNear(rates(1), BASE * 1.5)
		check(during >= 2 and okDuring, "while the boost runs the tick pays the garden at x1.5", noteDuring)
		check(plot:GetAttribute(GameConfig.Attributes.GardenIncome) == BASE * 1.5
				and plot:GetAttribute(GameConfig.Attributes.GardenBoost) == 1.5,
			"and the gate sign shows that income and that boost",
			plot:GetAttribute(GameConfig.Attributes.GardenBoost))

		-- The boost ends between two ticks.
		wall = T0 + BALANCE.DurationSeconds
		task.wait(1.2)
		local mark = #payments
		task.wait(2.2)
		local okAfter, noteAfter = allNear(rates(mark), BASE)
		check(#payments - mark >= 1 and okAfter, "from the second it ends the tick pays the base rate again", noteAfter)
		check(plot:GetAttribute(GameConfig.Attributes.GardenIncome) == BASE
				and plot:GetAttribute(GameConfig.Attributes.GardenBoost) == nil,
			"and the sign drops the boost", plot:GetAttribute(GameConfig.Attributes.GardenBoost))
		Ticking.Init()
		task.wait(1.2)
		local stopped = #payments
		task.wait(1.2)
		check(#payments == stopped, "the spec's faucet is stopped")
		data.AddCash = realAdd
	end)

	--==========================================================================
	-- 10. THE BOOST ENDS, THE COOLDOWN ENDS
	--==========================================================================
	section("expiry", function()
		wall = T0 + BALANCE.DurationSeconds - 1
		sac.Publish(giver)
		check(sac.Multiplier(giver) == BALANCE.Multiplier and giver:GetAttribute(ATTR.EndsAt) ~= nil,
			"one second before its expiry the boost is still running")
		wall = T0 + BALANCE.DurationSeconds
		check(sac.Multiplier(giver) == 1 and econ.RateFor(giver) == BASE, "at its expiry it is over: x1, the base rate")
		sac.Publish(giver)
		check(giver:GetAttribute(ATTR.EndsAt) == nil and giver:GetAttribute(ATTR.Multiplier) == nil,
			"and the boost's two attributes are cleared, so the row leaves the HUD")
		check(giver:GetAttribute(ATTR.NextAt) == T0 + BALANCE.CooldownSeconds,
			"while the cooldown's stays, for the sign's countdown")

		local pod = hold(giver, "petalpip", 1)
		local before = snapshot(giver)
		wall = T0 + BALANCE.CooldownSeconds - 1
		local r = quote(giver)
		check(r.phase == "refused" and r.reason == "COOLDOWN" and r.nextAt == T0 + BALANCE.CooldownSeconds,
			"one second before the cooldown ends an offer is refused, and told when it opens", r.reason)
		local kept, why = same(before, snapshot(giver))
		check(sac.PendingFor(giver) == nil and kept and pod.Parent == giver.Character, "with the pod kept", why)

		wall = T0 + BALANCE.CooldownSeconds
		local a = quote(giver)
		local b = quote(giver)
		check(a.phase == "quote" and b.phase == "quote" and a.token ~= b.token,
			"at the cooldown's end the pedestal quotes again")
		local first = yes(giver, a.token)
		check(first == nil and pod.Parent == giver.Character, "of two quotes, a yes to the older takes nothing")
		local second = yes(giver, b.token)
		check(second ~= nil and second.phase == "sacrificed" and destroyed(pod)
				and rowsOf(giver) == before.rows - 1 and #toolsOf(giver) == before.tools - 1,
			"and a yes to the newer takes one pod -- one, between the two of them")
		local profile = data.Get(giver)
		check(profile.SacrificeNextAt == wall + BALANCE.CooldownSeconds
				and profile.SacrificeEndsAt == wall + BALANCE.DurationSeconds and sac.Multiplier(giver) == 1.5,
			"the second sacrifice starts a fresh boost and a fresh cooldown from its own moment")
		local again = hold(giver, "toadcap", 1)
		r = quote(giver)
		check(r.phase == "refused" and r.reason == "COOLDOWN" and again.Parent == giver.Character,
			"and a third offer straight after is refused: one boost at a time", r.reason)
		emptyHands(giver)
	end)

	--==========================================================================
	-- 11. RACING THE STALL
	--==========================================================================
	section("racing SELL ALL", function()
		seed(-7106, { Held = { { Id = "nubkin", Tier = 2, Hatched = false },
			{ Id = "toadcap", Tier = 1, Hatched = true } }, Cash = 0 })
		local seller = enter("SellsFirst", -7106)
		garden(seller, GARDEN)
		local pod = hold(seller, "nubkin", 2)
		local r = quote(seller)
		check(r.phase == "quote", "a quote is on the table")
		local expect = SeedData.SellPrice(SeedData.Get("nubkin"), 2) + SeedData.SellPrice(SeedData.Get("toadcap"), 1)
		local sold, paid = econ.SellHeld(seller)
		check(sold == 2 and paid == expect and destroyed(pod), "SELL ALL lands first and buys the bag, the quoted pod included")
		local late = yes(seller, r.token)
		local profile = data.Get(seller)
		check(late ~= nil and late.phase == "refused" and late.reason == "CHANGED",
			"the yes that arrives after it is refused", late and late.reason)
		check(profile.SacrificeNextAt == 0 and profile.SacrificeEndsAt == 0 and sac.Multiplier(seller) == 1
				and profile.Cash == expect and #profile.Held == 0,
			"so the pod was paid for once, by the stall, and bought no boost and no cooldown")
	end)

	--==========================================================================
	-- 12. WHEN A STEP INSIDE THE EXCHANGE FAILS
	--==========================================================================
	section("failures inside the exchange", function()
		-- The clock refuses.
		seed(-7107, { Held = { { Id = "nubkin", Tier = 2, Hatched = false } } })
		local a = enter("ClockRefuses", -7107)
		garden(a, GARDEN)
		local pod = hold(a, "nubkin", 2)
		local before = snapshot(a)
		local r = quote(a)
		local inner = data.SetSacrifice
		data.SetSacrifice = function()
			return false
		end
		table.clear(trace)
		local failed = yes(a, r.token)
		data.SetSacrifice = inner
		check(failed ~= nil and failed.phase == "refused" and failed.reason == "FAILED",
			"the profile refusing the clock is a refusal", failed and failed.reason)
		local kept, why = same(before, snapshot(a))
		check(kept and pod.Parent == a.Character and not destroyed(pod) and #named("SyncHeldNow") == 0,
			"and nothing was taken: the pod is in the hands and the bag was never touched", why)
		check(a:GetAttribute(ATTR.EndsAt) == nil and a:GetAttribute(ATTR.Multiplier) == nil,
			"and no boost was published")
		pod.Parent = a._backpack

		-- The bag's sync throws.
		seed(-7108, { Held = { { Id = "nubkin", Tier = 2, Hatched = false },
			{ Id = "nubkin", Tier = 2, Hatched = false } } })
		local b = enter("SyncThrows", -7108)
		garden(b, GARDEN)
		pod = hold(b, "nubkin", 2)
		before = snapshot(b)
		r = quote(b)
		local sync = carry.SyncHeldNow
		carry.SyncHeldNow = function()
			error("spec: the sync threw")
		end
		local done = yes(b, r.token)
		carry.SyncHeldNow = sync
		check(done ~= nil and done.phase == "sacrificed" and destroyed(pod),
			"a sync that throws does not strand the exchange: the pod is taken", done and done.reason)
		check(rowsOf(b, "nubkin", 2, false) == 1 and rowsOf(b) == before.rows - 1 and sac.Multiplier(b) == 1.5,
			"its row was taken off directly -- one row, not both twins -- and the boost runs", rowsOf(b))

		-- The bag will not give the row up at all.
		seed(-7109, { Held = { { Id = "nubkin", Tier = 2, Hatched = false } } })
		local c = enter("RowStays", -7109)
		garden(c, GARDEN)
		pod = hold(c, "nubkin", 2)
		before = snapshot(c)
		r = quote(c)
		sync = carry.SyncHeldNow
		local setHeld = data.SetHeld
		carry.SyncHeldNow = function() end
		data.SetHeld = function()
			return false
		end
		local undone = yes(c, r.token)
		carry.SyncHeldNow = sync
		data.SetHeld = setHeld
		check(undone ~= nil and undone.phase == "refused" and undone.reason == "FAILED",
			"a row that will not come off is a refusal", undone and undone.reason)
		kept, why = same(before, snapshot(c))
		check(kept, "and the exchange is undone: the clock is what it was, the saved bag whole, no boost", why)
		check(pod.Parent == c.Character and not destroyed(pod), "and the pod is back in the hands, not destroyed")
		check(c:GetAttribute(ATTR.EndsAt) == nil and c:GetAttribute(ATTR.Multiplier) == nil,
			"with no boost published")
		task.wait()
		check(rowsOf(c, "nubkin", 2, false) == 1, "and once the bag settles it still lists that pod exactly once",
			rowsOf(c, "nubkin", 2, false))
		local r2 = quote(c)
		check(r2.phase == "quote", "so the same pod can be offered again")
		sac.Forget(c)
	end)

	--==========================================================================
	-- 13. SAVED, AND REJOINED
	--==========================================================================
	local function rejoin(name, userId)
		local p = enter(name, userId)
		garden(p, GARDEN)
		return p
	end

	section("saved and rejoined", function()
		seed(-7201, { Held = { { Id = "nubkin", Tier = 2, Hatched = false },
			{ Id = "petalpip", Tier = 1, Hatched = false } }, Cash = 50 })
		local first = rejoin("SavesAndLeaves", -7201)
		wall = os.time()
		local t = wall
		local pod = hold(first, "nubkin", 2)
		local r = quote(first)
		local done = yes(first, r.token)
		check(done ~= nil and done.phase == "sacrificed", "a sacrifice, in a session that saves")
		check(store[-7201].SacrificeNextAt == 0 and #store[-7201].Held == 2,
			"nothing reaches the save by itself: the exchange is in memory until the next write")
		check(data.Save(first) == true, "the save lands")
		local saved = store[-7201]
		check(saved.SacrificeNextAt == t + BALANCE.CooldownSeconds and saved.SacrificeEndsAt == t + BALANCE.DurationSeconds
				and #saved.Held == 1 and saved.Held[1].Id == "petalpip",
			"and carries all three together: the cooldown, the expiry, and the bag without the pod")
		data.Leave(first)
		first.Parent = nil

		wall = t + 10
		local back = rejoin("SavesAndLeaves", -7201)
		local profile = data.Get(back)
		check(profile.SacrificeNextAt == t + BALANCE.CooldownSeconds
				and profile.SacrificeEndsAt == t + BALANCE.DurationSeconds,
			"rejoining ten seconds in, both clocks come back as they were saved: absolute times, not restarted")
		check(sac.Multiplier(back) == BALANCE.Multiplier and econ.RateFor(back) == BASE * 1.5,
			"the rest of the boost is still theirs", sac.Multiplier(back))
		sac.Publish(back)
		check(back:GetAttribute(ATTR.EndsAt) == t + BALANCE.DurationSeconds
				and back:GetAttribute(ATTR.Multiplier) == BALANCE.Multiplier
				and back:GetAttribute(ATTR.NextAt) == t + BALANCE.CooldownSeconds
				and GameConfig.sacrificeIncomeBoost(back) == BALANCE.Multiplier,
			"and it is published again with nothing asked, so the boost row and the sign are right after a rejoin")
		check(#toolsOf(back) == 1 and #podTools(back, "nubkin", 2) == 0 and #podTools(back, "petalpip", 1) == 1,
			"the rebuilt bag holds the other pod and NOT the one that was given", #toolsOf(back))
		hold(back, "petalpip", 1)
		r = quote(back)
		check(r.phase == "refused" and r.reason == "COOLDOWN" and r.nextAt == t + BALANCE.CooldownSeconds,
			"and the pedestal is still recharging: leaving did not reset it", r.reason)
		data.Leave(back)
		back.Parent = nil

		wall = t + BALANCE.DurationSeconds + 5
		local later = rejoin("SavesAndLeaves", -7201)
		sac.Publish(later)
		check(sac.Multiplier(later) == 1 and later:GetAttribute(ATTR.EndsAt) == nil and econ.RateFor(later) == BASE,
			"rejoining after the expiry: the boost ran out while they were away, and was not extended")
		hold(later, "petalpip", 1)
		check(quote(later).reason == "COOLDOWN", "with the cooldown still counting")
		wall = t + BALANCE.CooldownSeconds
		check(quote(later).phase == "quote", "and ready at the moment it would have been had they stayed")
		sac.Forget(later)
	end)

	section("a save that fails", function()
		seed(-7202, { Held = { { Id = "nubkin", Tier = 2, Hatched = false },
			{ Id = "petalpip", Tier = 1, Hatched = false } }, Cash = 50 })
		local unlucky = rejoin("SaveFails", -7202)
		wall = os.time()
		saveOk = false
		local pod = hold(unlucky, "nubkin", 2)
		local r = quote(unlucky)
		local done = yes(unlucky, r.token)
		check(done ~= nil and done.phase == "sacrificed" and destroyed(pod) and sac.Multiplier(unlucky) == 1.5,
			"in the session the sacrifice happens: the pod is gone and the boost runs")
		data.AddCash(unlucky, 900)
		check(data.Save(unlucky) == false, "the save fails")
		data.Leave(unlucky)
		unlucky.Parent = nil
		saveOk = true
		local saved = store[-7202]
		check(saved.SacrificeNextAt == 0 and saved.SacrificeEndsAt == 0 and #saved.Held == 2 and saved.Cash == 50,
			"and the save still holds the session before it, whole: both pods, no clock, the old cash")

		local back = rejoin("SaveFails", -7202)
		local profile = data.Get(back)
		sac.Publish(back)
		check(#podTools(back, "nubkin", 2) == 1 and #toolsOf(back) == 2 and rowsOf(back) == 2,
			"rejoining, the pod is back in the bag: the failed save did not consume it", #toolsOf(back))
		check(profile.SacrificeNextAt == 0 and profile.SacrificeEndsAt == 0 and sac.Multiplier(back) == 1
				and back:GetAttribute(ATTR.EndsAt) == nil and profile.Cash == 50,
			"and there is no boost, no cooldown, and none of the cash the boost earned: nothing was had for free")
		hold(back, "nubkin", 2)
		check(quote(back).phase == "quote", "the pod can be offered again")
		sac.Forget(back)
	end)

	--==========================================================================
	-- 14. WHAT A SAVE MAY SAY
	--==========================================================================
	section("the saved fields", function()
		local now = os.time()
		local fresh = ProfileSchema.Default()
		check(fresh.SacrificeNextAt == 0 and fresh.SacrificeEndsAt == 0,
			"a new profile: the pedestal is ready and nothing is running")
		local old = ProfileSchema.Sanitise({ Cash = 5 })
		check(old.SacrificeNextAt == 0 and old.SacrificeEndsAt == 0,
			"a save from before the pedestal has neither key, and reads as ready with nothing running")
		local kept = ProfileSchema.Sanitise({ SacrificeNextAt = now + 100, SacrificeEndsAt = now + 20 })
		check(kept.SacrificeNextAt == now + 100 and kept.SacrificeEndsAt == now + 20,
			"times a sacrifice could have written come back as written")
		local skewed = ProfileSchema.Sanitise({ SacrificeNextAt = now + 1e9, SacrificeEndsAt = now + 1e9 })
		check(skewed.SacrificeNextAt <= os.time() + BALANCE.CooldownSeconds
				and skewed.SacrificeEndsAt <= os.time() + BALANCE.DurationSeconds,
			"a time from a clock far ahead is cut to one cooldown and one boost from now: never a pedestal "
				.. "locked for years or a boost that lasts them",
			string.format("%d / %d", skewed.SacrificeNextAt - now, skewed.SacrificeEndsAt - now))
		local junk = ProfileSchema.Sanitise({ SacrificeNextAt = "soon", SacrificeEndsAt = 0 / 0 })
		local negative = ProfileSchema.Sanitise({ SacrificeNextAt = -50, SacrificeEndsAt = {} })
		check(junk.SacrificeNextAt == 0 and junk.SacrificeEndsAt == 0 and negative.SacrificeNextAt == 0
				and negative.SacrificeEndsAt == 0,
			"a word, NaN, a negative and a table all read as 0")
		local halves = ProfileSchema.Sanitise({ SacrificeNextAt = now + 10.7, SacrificeEndsAt = now + 3.2 })
		check(halves.SacrificeNextAt == now + 10 and halves.SacrificeEndsAt == now + 3, "and both are whole seconds")

		seed(-7203, { Held = { { Id = "nubkin", Tier = 2, Hatched = false } } })
		local wiped = rejoin("GetsReset", -7203)
		wall = os.time()
		hold(wiped, "nubkin", 2)
		local r = quote(wiped)
		yes(wiped, r.token)
		check(sac.Multiplier(wiped) == 1.5, "a boost is running")
		check(data.ResetProgress(wiped) == true, "an admin's progress reset")
		sac.Publish(wiped)
		local profile = data.Get(wiped)
		check(profile.SacrificeNextAt == 0 and profile.SacrificeEndsAt == 0 and sac.Multiplier(wiped) == 1
				and wiped:GetAttribute(ATTR.EndsAt) == nil,
			"clears both clocks with everything else, as it does the Bonus Chest's")
	end)

	--==========================================================================
	-- 15. DYING
	--==========================================================================
	local function respawn(p)
		local oldBody, oldPack = p.Character, p._backpack
		p._fire.characterRemoving:Fire(oldBody)
		task.wait()
		p.Character = nil
		oldBody:Destroy()
		oldPack:Destroy()
		local newPack = newBackpack(p)
		p._fire.childAdded:Fire(newPack)
		newBody(p)
		p._fire.characterAdded:Fire(p.Character)
		task.wait(0.6)
	end

	section("respawning", function()
		seed(-7204, { Held = { { Id = "nubkin", Tier = 2, Hatched = false },
			{ Id = "nubkin", Tier = 2, Hatched = false }, { Id = "petalpip", Tier = 1, Hatched = false } } })
		local mortal = rejoin("DiesALot", -7204)
		wall = os.time()
		local pod = hold(mortal, "nubkin", 2)
		local r = quote(mortal)
		check(r.phase == "quote" and sac.PendingFor(mortal) == r.token, "a quote is on the table")

		-- Two watchers forget a quote, and each is tried alone: the body that
		-- leaves, and the body that arrives.
		mortal._fire.characterRemoving:Fire(mortal.Character)
		task.wait()
		check(sac.PendingFor(mortal) == nil, "the body leaving forgets it")
		check(yes(mortal, r.token) == nil and pod.Parent == mortal.Character, "and its yes then finds nothing")
		-- CarryService stopped recording on the same signal; the bag is armed again.
		carry.RestoreHeld(mortal)
		task.wait(0.3)
		r = quote(mortal)
		check(r.phase == "quote" and sac.PendingFor(mortal) == r.token, "a second quote is on the table", r.reason)
		mortal._fire.characterAdded:Fire(mortal.Character)
		task.wait()
		check(sac.PendingFor(mortal) == nil, "a body arriving forgets it too")
		check(yes(mortal, r.token) == nil and pod.Parent == mortal.Character and rowsOf(mortal) == 3,
			"and its yes finds nothing: the pod is kept")
		task.wait(0.3)

		r = quote(mortal)
		check(r.phase == "quote" and sac.PendingFor(mortal) == r.token, "a third quote is on the table", r.reason)
		respawn(mortal)
		check(sac.PendingFor(mortal) == nil, "a whole death and respawn forgets it")
		check(carry.IsHeldRestored(mortal) and #toolsOf(mortal) == 3 and rowsOf(mortal) == 3 and destroyed(pod),
			"the new body gets the whole saved bag back, as new Tools", #toolsOf(mortal))
		hold(mortal, "nubkin", 2)
		local profile = data.Get(mortal)
		check(yes(mortal, r.token) == nil and #toolsOf(mortal) == 3 and rowsOf(mortal) == 3
				and profile.SacrificeNextAt == 0,
			"and the old yes, sent from the new body holding the same kind of pod, takes nothing")

		r = quote(mortal)
		local given = nil
		for _, candidate in ipairs(podTools(mortal, "nubkin", 2)) do
			if candidate.Parent == mortal.Character then
				given = candidate
			end
		end
		local done = yes(mortal, r.token)
		check(done ~= nil and done.phase == "sacrificed" and destroyed(given) and rowsOf(mortal) == 2,
			"a fresh quote from the new body sacrifices one pod")
		local t = wall
		respawn(mortal)
		check(#toolsOf(mortal) == 2 and #podTools(mortal, "nubkin", 2) == 1 and rowsOf(mortal) == 2,
			"dying straight after does NOT bring the pod back: the bag is rebuilt one pod short", #toolsOf(mortal))
		profile = data.Get(mortal)
		check(sac.Multiplier(mortal) == 1.5 and profile.SacrificeEndsAt == t + BALANCE.DurationSeconds
				and profile.SacrificeNextAt == t + BALANCE.CooldownSeconds,
			"and neither ends the boost nor resets the cooldown")
		hold(mortal, "nubkin", 2)
		check(quote(mortal).reason == "COOLDOWN", "so a second body is no second sacrifice")
		respawn(mortal)
		respawn(mortal)
		check(#toolsOf(mortal) == 2 and rowsOf(mortal) == 2, "two more deaths change nothing", #toolsOf(mortal))
	end)

	--==========================================================================
	-- 16. THE WIRING, AND WHAT STAYS OUT OF SCOPE
	--==========================================================================
	section("the wiring", function()
		local service = sourceOf(Server.SacrificeService)
		local economy = sourceOf(Server.EconomyService)
		local ui = sourceOf(StarterPlayer.StarterPlayerScripts:FindFirstChild("SacrificeUI"))
		local row = sourceOf(StarterPlayer.StarterPlayerScripts:FindFirstChild("BonusChestUI"))
		check(service ~= "" and economy ~= "" and ui ~= "" and row ~= "", "the four sources are there to read")

		-- Who asks for the boost: in code, with the comments taken out.
		local askers = {}
		for _, module in ipairs(Server:GetDescendants()) do
			if module:IsA("LuaSourceContainer") and module.Name ~= "SacrificeService" then
				local code = string.gsub(sourceOf(module), "%-%-[^\n]*", "")
				if string.find(code, "SacrificeService", 1, true) then
					table.insert(askers, module.Name)
				end
			end
		end
		table.sort(askers)
		check(table.concat(askers, ",") == "EconomyService",
			"EconomyService is the only server script whose code names the pedestal", table.concat(askers, ","))
		check(select(2, string.gsub(economy, "SacrificeService%.Multiplier", "")) == 1
				and select(2, string.gsub(economy, "temporaryBoost%(player%)", "")) == 2,
			"it asks in one place -- the sum of the temporary boosts -- used by the rate and the gate sign only")
		local function body(name)
			return string.match(economy, "function EconomyService%." .. name .. "%(.-\nend\n") or ""
		end
		local clean = true
		for _, name in ipairs({ "QuoteHeld", "SellHeld", "QuoteOne", "SellOne", "PayReward", "ClaimOffline" }) do
			local text = body(name)
			if text == "" or string.find(text, "temporaryBoost", 1, true) or string.find(text, "SacrificeService", 1, true)
				or string.find(text, "RateFor", 1, true) then
				clean = false
			end
		end
		check(clean, "no sale, one-off reward or offline claim reads the boost or the boosted rate")

		-- The remote: the engine's player, a token and a yes.
		check(string.find(service, "SacrificeService.Confirm(player, payload)", 1, true) ~= nil
				and string.find(service, "if action ~= CONFIG.ClientAction then", 1, true) ~= nil
				and string.find(service, "SacrificeService.Quote(player, top)", 1, true) ~= nil,
			"the prompt asks for a quote and the remote answers one, both for the engine's own player")
		check(select(2, string.gsub(ui, "FireServer%(", "")) == 1
				and string.find(ui, "channel:FireServer(CONFIG.ClientAction, { token = token, accept = accept })", 1, true) ~= nil,
			"the panel sends one verb: the token and a yes or a no, and nothing about the pod")

		-- No yield inside the exchange.
		local from = string.find(service, "NO YIELD FROM HERE TO THE RETURN", 1, true)
		local to = from and string.find(service, 'phase = "sacrificed"', from, true)
		local inside = if from and to then string.sub(service, from, to) else ""
		check(inside ~= "" and not string.find(inside, "task%.wait") and not string.find(inside, "[^%w]wait%(")
				and not string.find(inside, ":Wait%(") and not string.find(inside, "Async")
				and not string.find(inside, "PlayerDataService%.Save"),
			"between the last check and the last write the exchange never yields, and never saves by itself")

		-- Out of scope, and absent.
		local present = {}
		for _, word in ipairs({ "MarketplaceService", "ProcessReceipt", "PromptProductPurchase", "PromptGamePassPurchase",
			"DeveloperProduct", "Robux", "GuardianLuck" }) do
			if string.find(service, word, 1, true) or string.find(ui, word, 1, true) then
				table.insert(present, word)
			end
		end
		-- As a word of its own: the signs are lettered in LuckiestGuy.
		for _, text in ipairs({ service, ui }) do
			if string.find(text, "%f[%a][Ll]uck%f[%A]") then
				table.insert(present, "luck")
			end
		end
		check(#present == 0, "no purchase, product, paid upgrade or guardian luck anywhere in the pedestal",
			table.concat(present, ", "))

		-- The pod stays a question.
		-- The id is read off the Tool to find its row in the saved bag, and goes
		-- no further: no species is ever looked up into a variable or a field.
		check(not string.find(service, "local species", 1, true) and not string.find(service, "SeedData%.Get%b()%.")
				and not string.find(service, "%.Rarity") and not string.find(service, "RarityFor"),
			"the server never reads a species' name or rarity")
		check(string.find(service, '"%s gave up a %d tier pod: +%d%% garden income for %ds, next in %ds."', 1, true) ~= nil
				and string.find(service, "player.Name, tier, math.floor((BALANCE.Multiplier - 1) * 100 + 0.5)", 1, true) ~= nil,
			"and its log line names the player and the pod's size, not what was in it")
		check(not string.find(ui, "species%.Name") and not string.find(ui, "%.Rarity") and not string.find(ui, "RarityFor")
				and not string.find(ui, "DisplayName") and string.find(ui, '"UNHATCHED POD"', 1, true) ~= nil,
			"the panel names the pod UNHATCHED POD and never its species or rarity")
		check(string.find(ui, "CreatureModel.BuildPod(species, tier, CFrame.new(), parent)", 1, true) ~= nil,
			"and draws the shell with the builder the hotbar uses: the picture the player already has")

		-- Every reason the server can name has words, or is silent on purpose.
		local named = {}
		for code in string.gmatch(service, '"([A-Z][A-Z_]+)"') do
			named[code] = true
		end
		local SILENT = { GONE = true, DISABLED = true }
		local unworded, unused = {}, {}
		for code in pairs(named) do
			if not CONFIG.Notices[code] and not SILENT[code] then
				table.insert(unworded, code)
			end
		end
		for code in pairs(CONFIG.Notices) do
			if not named[code] then
				table.insert(unused, code)
			end
		end
		table.sort(unworded)
		table.sort(unused)
		check(next(named) ~= nil and #unworded == 0,
			"every reason the server names has a notice -- bar a body that is gone and a pedestal switched off",
			table.concat(unworded, ", "))
		check(#unused == 0, "and no notice is for a reason the server never gives", table.concat(unused, ", "))
		check(string.find(ui, "= CONFIG.Notices", 1, true) ~= nil
				and string.find(ui, "GameConfig.sacrificeReadyIn(", 1, true) ~= nil
				and string.find(ui, "title = CONFIG.SuccessTitle", 1, true) ~= nil
				and select(2, string.gsub(ui, "Notice%.post%(", "")) == 2,
			"the panel's two notices -- a refusal, a success -- are GameConfig's words through the shared renderer")

		-- Phone and controller, as far as source can say.
		check(string.find(ui, "padFirst.Value = keepButton.button", 1, true) ~= nil
				and string.find(ui, "Enum.KeyCode.ButtonB", 1, true) ~= nil,
			"on a controller the selection starts on KEEP POD, and B is a no")
		check(string.find(ui, "modal.setOpen(true)\n\tfit()", 1, true) ~= nil
				and string.find(ui, 'gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()\n\tif openToken then\n\t\tfit()', 1, true) ~= nil
				and string.find(ui, "UIKit.onMenuSize(fit)", 1, true) ~= nil,
			"the panel is fitted when it opens, and again when the screen or the menu size changes under it")

		-- THE PANEL FITS EVERY LISTED PHONE. The rows' two sizes are read out of
		-- the panel's own source and the room is UIKit.modal's own rule, so this
		-- is the arithmetic the panel does, for the screens HudLayoutSpec lists
		-- (safe heights: the viewport less the 58 of top bar, and a notch).
		local kit = sourceOf(Shared:FindFirstChild("UIKit"))
		check(string.find(kit, "local MODAL_CHROME = 82", 1, true) ~= nil
				and string.find(kit, "math.min(limit.MaxSize.Y, math.floor(screen * 0.86 / userScale)) - MODAL_CHROME", 1, true) ~= nil
				and string.find(kit, "contentHeight + MODAL_CHROME", 1, true) ~= nil
				and string.find(ui, "modal.contentRoom() >= contentOf(REGULAR)", 1, true) ~= nil
				and string.find(ui, "maxHeight = 340", 1, true) ~= nil,
			"UIKit.modal gives content 86% of the screen less 82 of chrome, and the panel asks it for that room")
		local function metrics(name)
			local row = string.match(ui, "local " .. name .. ": Metrics = {(.-)}")
			local m = {}
			for key, value in string.gmatch(row or "", "(%a+) = (%d+)") do
				m[key] = tonumber(value)
			end
			return m
		end
		local function contentOf(m)
			return (m.pod or 1e9) + (m.offer or 0) + (m.warn or 0) + (m.button or 0) + (m.gap or 0) * 3 + (m.margin or 0)
		end
		local regular, compact = metrics("REGULAR"), metrics("COMPACT")
		check(contentOf(regular) == 206 and contentOf(compact) == 154
				and (regular.button or 0) >= 44 and (compact.button or 0) >= 44,
			"the rows need 206 at full size and 154 at the closer one, with buttons 44 tall or more in both",
			string.format("%s / %s", tostring(contentOf(regular)), tostring(contentOf(compact))))
		local cut, closer = {}, {}
		for _, screen in ipairs({ { "772x360", 302 }, { "801x392", 334 }, { "896x414 notched", 335 },
			{ "874x402", 344 }, { "896x414", 356 }, { "956x440", 382 }, { "640x480", 422 }, { "1000x609", 551 },
			{ "1280x720", 662 } }) do
			for _, option in ipairs(GameConfig.MenuSize.Options) do
				-- The size the panel is drawn at: the chosen one, as far as its
				-- minimum still fits 86% of the screen (UIKit.modal's follow).
				local s = math.max(1, math.min(option.Scale, screen[2] * 0.86 / 240))
				local room = math.min(340, math.floor(screen[2] * 0.86 / s)) - 82
				local full = room >= contentOf(regular)
				local need = if full then contentOf(regular) else contentOf(compact)
				if need > room then
					table.insert(cut, string.format("%s at %s: %d in %d", screen[1], option.Id, need, room))
				end
				if not full and option.Scale == 1 then
					table.insert(closer, screen[1])
				end
			end
		end
		check(#cut == 0, "on every listed screen, at every menu size, the rows it picks fit the room it is given",
			table.concat(cut, "; "))
		check(table.concat(closer, ", ") == "772x360, 801x392",
			"the two shortest phones get the closer rows at the normal menu size; every other screen the full ones",
			table.concat(closer, ", "))
		check(string.find(row, "GameConfig.sacrificeIncomeBoost(player)", 1, true) ~= nil
				and string.find(row, "GameConfig.sacrificeBoostTitle(sacrifice)", 1, true) ~= nil
				and string.find(row, 'entryFor("sacrifice")', 1, true) ~= nil,
			"the boost row draws the pedestal's line beside the chest's, off the published attributes")
	end)
end)

--==============================================================================
-- PUT THE WORLD BACK
--==============================================================================
pcall(function()
	sac.Stop()
end)
local leftover = Workspace:FindFirstChild(CONFIG.FolderName)
fixture:Destroy()
say("\n-- afterwards --")
check(ok, "the spec ran to its end", err)
check(leftover == nil and Workspace:FindFirstChild("SacrificeSpecFixture") == nil,
	"the pedestal and the fixture are gone from the Edit place")

say("")
say(string.format("SacrificeSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
