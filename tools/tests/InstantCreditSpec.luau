--!nocheck
--==============================================================================
-- Steal a Seed :: InstantCreditSpec
--
-- SAVED INSTANT HATCHES (2026-09-30). Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("InstantCreditSpec"))
--
-- A purchase of an instant hatch that finds nothing it can do -- the saved
-- record full, and its pod's wait already over -- is kept as one credit
-- (PlantService.InstantHatch). The owner's decision: "save one credit for that
-- purchase, acknowledge the receipt only after the credit is safely saved, and
-- make sure a duplicate receipt can't add a second credit. The credit should
-- only be used when an eligible hatch actually succeeds." The receipt, the
-- ledger and the spending are HatchStorageSpec's. This is the credit's own
-- storage, on the REAL modules:
--
--   ProfileSchema      the saved field: absent, junk, negative, fractional, huge
--   PlayerDataService  AddInstantCredits: whole numbers, never below zero, never
--                      past the cap, marked for saving; kept by a progress
--                      reset; written by a save and read back by the next join
--
-- The real PlayerDataService, joined through its own Join as AdminSpec does
-- it: SaveService's Load and Save answer from a table here, and the
-- leaderstats mount and the plot sizing are the only other stand-ins.
--
-- NOTHING IS BOUGHT AND NO SAVE IS OPENED.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local Server = game:GetService("ServerScriptService").SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local ProfileSchema = require(Server.ProfileSchema)
local PlayerDataService = require(Server.PlayerDataService)

local CAP = GameConfig.Save.MaxInstantCredits

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
local function sourceOf(instance)
	if instance == nil then
		return nil
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok then src else nil
end

local fixture = Instance.new("Folder")
fixture.Name = "InstantCreditSpecFixture"
fixture.Archivable = false
fixture.Parent = ServerStorage

--==============================================================================
-- THE STAND-INS
--==============================================================================
local real = {
	Load = SaveService.Load,
	Save = SaveService.Save,
	Forget = SaveService.Forget,
	SetDesiredLevel = PlotService.SetDesiredLevel,
	MountStats = PlayerDataService.MountStats,
}
-- userId -> what the last save wrote, and every write in order.
local stored = {}
local writes = {}
SaveService.Load = function(userId)
	local saved = stored[userId]
	if saved == nil then
		return "new", nil
	end
	return "ok", table.clone(saved)
end
SaveService.Save = function(userId, payload, release)
	stored[userId] = table.clone(payload)
	table.insert(writes, { userId = userId, credits = payload.InstantCredits, release = release == true })
	return true
end
SaveService.Forget = function() end
PlotService.SetDesiredLevel = function()
	return true
end
local holders = {}
PlayerDataService.MountStats = function(holder, profile)
	return real.MountStats(holders[holder] or holder, profile)
end

-- A player the real Join accepts (AdminSpec's).
local joined = {}
local function stand(name, userId)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local characterAdded = Instance.new("BindableEvent")
	characterAdded.Parent = holder
	local character = Instance.new("Model")
	character.Name = name .. "Body"
	character.Parent = holder
	local attrs = {}
	local p = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = character,
		CharacterAdded = characterAdded.Event,
		_holder = holder,
	}
	function p.SetAttribute(_, k, v)
		attrs[k] = v
	end
	function p.GetAttribute(_, k)
		return attrs[k]
	end
	function p.Kick() end
	function p.FindFirstChildOfClass()
		return nil
	end
	function p.WaitForChild(_, childName)
		return holder:FindFirstChild(childName)
	end
	holders[p] = holder
	return p
end

local function join(name, userId)
	local p = stand(name, userId)
	PlayerDataService.Join(p)
	local deadline = os.clock() + 5
	while not PlayerDataService.IsReady(p) and os.clock() < deadline do
		task.wait(0.05)
	end
	table.insert(joined, p)
	return p, PlayerDataService.Get(p)
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE CAP
	--==========================================================================
	say("-- the cap --")
	check(type(CAP) == "number" and CAP >= 1 and CAP == math.floor(CAP) and CAP <= 1e6,
		"the cap on saved Instant Hatches is a whole number a player cannot reach", CAP)

	--==========================================================================
	-- 2. THE SAVED FIELD
	--==========================================================================
	say("\n-- the saved field --")
	check(ProfileSchema.Default().InstantCredits == 0, "a new profile holds no credit")
	check(ProfileSchema.Sanitise(nil).InstantCredits == 0 and ProfileSchema.Sanitise({}).InstantCredits == 0,
		"an old save with no such field reads 0: it migrates by being absent")
	local cases = {
		{ 3, 3, "a whole number is kept" },
		{ 2.9, 2, "a fraction is rounded down" },
		{ -4, 0, "a negative number reads 0" },
		{ "5", 0, "a string reads 0" },
		{ 0 / 0, 0, "NaN reads 0" },
		{ math.huge, CAP, "infinity is held to the cap" },
		{ CAP + 7, CAP, "past the cap is held to the cap" },
	}
	for _, case in ipairs(cases) do
		local got = ProfileSchema.Sanitise({ InstantCredits = case[1] }).InstantCredits
		check(got == case[2], case[3], got)
	end
	check(ProfileSchema.Sanitise(ProfileSchema.Sanitise({ InstantCredits = 7 })).InstantCredits == 7,
		"a saved credit round-trips unchanged")

	--==========================================================================
	-- 3. THE WRITER, ON THE REAL PlayerDataService
	--==========================================================================
	say("\n-- the writer --")
	stored[9701] = ProfileSchema.Sanitise({ InstantCredits = 2, Cash = 500, Receipts = { "spec-r-1" } })
	local p, profile = join("CreditSaver", 9701)
	check(profile ~= nil and profile.InstantCredits == 2, "a saved credit is loaded with the profile",
		profile and profile.InstantCredits)
	check(PlayerDataService.IsPersistent(p), "(it loaded as a profile that can be saved)")
	if not profile then
		return
	end

	check(PlayerDataService.AddInstantCredits(p, 1) == 3 and profile.InstantCredits == 3, "one granted: 3 held")
	check(PlayerDataService.AddInstantCredits(p, -1) == 2 and profile.InstantCredits == 2, "one spent: 2 held")
	local refusals = { n = 8, 0, 0.5, -0.5, 0 / 0, "1", nil, math.huge, -math.huge }
	local allRefused = true
	for i = 1, refusals.n do
		if PlayerDataService.AddInstantCredits(p, refusals[i]) ~= nil then
			allRefused = false
		end
	end
	check(allRefused and profile.InstantCredits == 2,
		"a change that is nothing, not a whole number or not a number is refused, and changes nothing",
		profile.InstantCredits)
	check(PlayerDataService.AddInstantCredits(p, -3) == nil and profile.InstantCredits == 2,
		"spending more than is held is refused")
	check(PlayerDataService.AddInstantCredits(p, -2) == 0 and PlayerDataService.AddInstantCredits(p, -1) == nil
			and profile.InstantCredits == 0,
		"down to none, and not past it")
	check(PlayerDataService.AddInstantCredits(p, CAP) == CAP and PlayerDataService.AddInstantCredits(p, 1) == nil
			and profile.InstantCredits == CAP,
		"up to the cap, and not past it")
	check(PlayerDataService.AddInstantCredits(stand("NotLoaded", 9702), 1) == nil,
		"a player with no profile is refused")
	check(PlayerDataService.AddInstantCredits(p, 4 - CAP) == 4 and profile.InstantCredits == 4, "(four held)")

	--==========================================================================
	-- 4. SAVED, KEPT BY A RESET, AND READ BACK
	--==========================================================================
	say("\n-- saved, and read back --")
	local before = #writes
	check(PlayerDataService.Save(p) and #writes == before + 1 and writes[#writes].credits == 4,
		"a save writes the credits held", writes[#writes] and writes[#writes].credits)
	check(PlayerDataService.ResetProgress(p) and PlayerDataService.Get(p).InstantCredits == 4
			and PlayerDataService.Get(p).Cash == 0 and #PlayerDataService.Get(p).Receipts == 1,
		"an admin's progress reset keeps saved Instant Hatches, as it keeps bought spins and receipts",
		PlayerDataService.Get(p) and PlayerDataService.Get(p).InstantCredits)
	PlayerDataService.Leave(p)
	check(writes[#writes].credits == 4 and writes[#writes].release == true, "the leave save writes them")
	local back, backProfile = join("CreditSaver", 9701)
	check(backProfile ~= nil and backProfile.InstantCredits == 4, "and the next join reads them back",
		backProfile and backProfile.InstantCredits)
	PlayerDataService.Leave(back)

	--==========================================================================
	-- 5. WHAT THE SOURCE SAYS
	--==========================================================================
	say("\n-- the source --")
	local src = sourceOf(Server.PlayerDataService) or ""
	local body = string.match(src, "function PlayerDataService%.AddInstantCredits(.-)\nend\n") or ""
	check(string.find(body, "touch(player)", 1, true) ~= nil,
		"a change is marked for the autosave, as every other writer's is")
	local reset = string.match(src, "function PlayerDataService%.ResetProgress(.-)\nend\n") or ""
	check(string.find(reset, "InstantCredits = ", 1, true) ~= nil, "the reset names the credits among what it keeps")
end)

for _, p in ipairs(joined) do
	if PlayerDataService.IsReady(p) then
		pcall(PlayerDataService.Leave, p)
	end
end
SaveService.Load, SaveService.Save, SaveService.Forget = real.Load, real.Save, real.Forget
PlotService.SetDesiredLevel = real.SetDesiredLevel
PlayerDataService.MountStats = real.MountStats
fixture:Destroy()

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nInstantCreditSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
