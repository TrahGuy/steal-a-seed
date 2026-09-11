--!strict
--==============================================================================
-- Steal a Seed :: AlmanacClaimSpec
--
-- The Biome Harvest, end to end on the server: the almanac's arithmetic
-- (AlmanacData), the profile field that remembers a paid biome
-- (ProfileSchema's Mastery and PlayerDataService.RecordMastery), the two faucet
-- entry points (EconomyService.PayReward, TreadmillService.PayReward), and the
-- claim itself (AlmanacService.Claim), which pays a finished biome's BiomeData
-- cash and Speed exactly once. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("AlmanacClaimSpec"))
--
-- The real services, fresh-required. SaveService's Load, Save and Forget and
-- PlotService.SetDesiredLevel are stubbed, and MountStats mounts on a stand-in
-- Folder, the way LeaderstatsSpec does it: a Player cannot be made in Edit.
--
-- Not here, verified in Play instead: the GameEvent round trip, and the Index
-- repainting from the reply and from the next profile packet.
--==============================================================================
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local BiomeData = require(Shared.BiomeData)
local AlmanacData = require(Shared.AlmanacData)
local Server = game:GetService("ServerScriptService").SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local ProfileSchema = require(Server.ProfileSchema)
local PlayerDataService = require(Server.PlayerDataService)
local EconomyService = require(Server.EconomyService)
local TreadmillService = require(Server.TreadmillService)
local AlmanacService = require(Server.AlmanacService)

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string)
	if ok then
		pass += 1
	else
		table.insert(fails, label)
	end
end

local fixture = Instance.new("Folder")
fixture.Name = "AlmanacClaimSpecFixture"
fixture.Parent = ServerStorage

local saves: any = SaveService
local plots: any = PlotService
local data: any = PlayerDataService
local real = {
	Load = saves.Load,
	Save = saves.Save,
	Forget = saves.Forget,
	SetDesiredLevel = plots.SetDesiredLevel,
	MountStats = data.MountStats,
}

local answer: { status: string, raw: any } = { status = "ok", raw = nil }
saves.Load = function(_userId: number): (string, any)
	return answer.status, answer.raw
end
saves.Save = function(): boolean
	return true
end
saves.Forget = function() end
plots.SetDesiredLevel = function() end

local holders: { [any]: Folder } = {}
data.MountStats = function(holder: any, profile: any): any
	return real.MountStats(holders[holder] or holder, profile)
end

local function stand(name: string, userId: number, parent: Instance?): any
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local characterAdded = Instance.new("BindableEvent")
	characterAdded.Parent = holder
	local attrs: { [string]: any } = {}
	local p: any = {
		Name = name,
		UserId = userId,
		Parent = parent,
		CharacterAdded = characterAdded.Event,
	}
	function p.SetAttribute(_, k: string, v: any)
		attrs[k] = v
	end
	function p.GetAttribute(_, k: string): any
		return attrs[k]
	end
	function p.Kick() end
	holders[p] = holder
	return p
end

local joined: { any } = {}
local function join(name: string, userId: number, cash: number, speed: number): (any, any)
	local raw: any = ProfileSchema.Sanitise(nil)
	raw.Cash = cash
	raw.Speed = speed
	answer.status, answer.raw = "ok", raw
	local p = stand(name, userId, Players)
	data.Join(p)
	table.insert(joined, p)
	return p, data.Get(p)
end

local ok, err = pcall(function()
	--== 1. EVERY BIOME PAYS, AND FURTHER DOWN THE ROAD PAYS MORE =============
	local road = AlmanacData.Biomes()
	check(#road == 5 and #road == #BiomeData.Biomes, "five biomes on the road")
	local lastCash, lastSpeed = 0, 0
	for i, biome in ipairs(road) do
		check(biome.Order == i, biome.Id .. " sits at road position " .. i)
		local cash, speed = AlmanacData.Reward(biome.Id)
		check(cash == biome.MasteryCash and speed == biome.MasterySpeed,
			biome.Id .. ": Reward reads BiomeData")
		check(cash > lastCash and speed > lastSpeed,
			biome.Id .. ": pays more than the biome before it")
		lastCash, lastSpeed = cash, speed
	end
	local noCash, noSpeed = AlmanacData.Reward("nowhere")
	check(noCash == 0 and noSpeed == 0, "a biome that does not exist is worth nothing")

	--== 2. A SHELF IS ITS BIOME'S FIVE, COMMONEST FIRST ======================
	for _, biome in ipairs(road) do
		local shelf = AlmanacData.SpeciesIn(biome.Id)
		check(#shelf == 5 and #shelf == #SeedData.InBiome(biome.Id),
			biome.Id .. " shelves five species")
		local ordered, home = true, true
		for i, species in ipairs(shelf) do
			if species.Biome ~= biome.Id then
				home = false
			end
			if i > 1 then
				local before = shelf[i - 1]
				local ta = GameConfig.RarityTier[before.Rarity]
				local tb = GameConfig.RarityTier[species.Rarity]
				if ta > tb or (ta == tb and before.Name > species.Name) then
					ordered = false
				end
			end
		end
		check(home, biome.Id .. ": every species on the shelf lives there")
		check(ordered, biome.Id .. ": commonest first, then by name")
	end
	local green = AlmanacData.SpeciesIn("greenhollow")
	check(green[1].Id == "nubkin" and green[2].Id == "petalpip" and green[5].Id == "bellchime",
		"Greenhollow reads Nubkin, Petalpip ... Bellchime")

	--== 3. PROGRESS, AND WHERE A HARVEST STANDS ==============================
	local almanac: { [string]: boolean } = { nubkin = true, petalpip = true, dunebud = true }
	almanac.notaplant = true
	local grown, total = AlmanacData.Progress(almanac, "greenhollow")
	check(grown == 2 and total == 5, "two of Greenhollow's five grown")
	local all, every = AlmanacData.TotalProgress(almanac)
	check(all == 3 and every == #SeedData.Species and every == 25,
		"three of twenty-five in all, and an id that is not a plant is not counted")
	check(AlmanacData.ClaimState(almanac, {}, "greenhollow") == "locked", "an unfinished biome is locked")
	for _, species in ipairs(green) do
		almanac[species.Id] = true
	end
	check(AlmanacData.ClaimState(almanac, {}, "greenhollow") == "ready", "a finished biome is ready")
	check(AlmanacData.ClaimState(almanac, nil, "greenhollow") == "ready",
		"no mastery set reads as nothing claimed")
	check(AlmanacData.ClaimState(almanac, { greenhollow = true }, "greenhollow") == "claimed",
		"a paid biome is claimed")
	check(AlmanacData.ClaimState({}, { dustbowl = true }, "dustbowl") == "claimed",
		"claimed holds whatever the almanac says")
	check(AlmanacData.ClaimState(nil, nil, "greenhollow") == "locked", "no almanac is locked")
	check(AlmanacData.ClaimState(almanac, {}, nil) == "unknown"
		and AlmanacData.ClaimState(almanac, {}, 5) == "unknown"
		and AlmanacData.ClaimState(almanac, {}, "nowhere") == "unknown"
		and AlmanacData.ClaimState(almanac, {}, {}) == "unknown",
		"anything that is not a biome id is unknown")

	--== 4. THE PROFILE REMEMBERS, AND SANITISES WHAT IT REMEMBERS ============
	local fresh: any = ProfileSchema.Sanitise(nil)
	check(type(fresh.Mastery) == "table" and next(fresh.Mastery) == nil,
		"a new profile has claimed nothing")
	local mixed: any = { greenhollow = true, dustbowl = "yes", starbloom = false, nowhere = true }
	mixed[3] = true
	local raw: any = ProfileSchema.Sanitise(nil)
	raw.Mastery = mixed
	raw.Almanac = { nubkin = true }
	local clean: any = ProfileSchema.Sanitise(raw)
	check(clean.Mastery.greenhollow == true, "a paid biome survives a load")
	check(clean.Mastery.dustbowl == nil and clean.Mastery.starbloom == nil, "only true counts")
	check(clean.Mastery.nowhere == nil and clean.Mastery[3] == nil,
		"unknown and numeric ids are dropped")
	check(clean.Almanac.nubkin == true, "the almanac beside it is untouched")
	local legacy: any = ProfileSchema.Sanitise(nil)
	legacy.Mastery = nil
	check(type((ProfileSchema.Sanitise(legacy) :: any).Mastery) == "table",
		"a save from before the harvest loads an empty set")

	--== 5. RECORDED ONCE =====================================================
	local recorder, recorderProfile = join("Recorder", -801, 0, 0)
	check(data.IsReady(recorder), "the stand-in's profile loaded")
	check(data.RecordMastery(recorder, "nowhere") == false, "RecordMastery refuses an unknown biome")
	check(data.RecordMastery(recorder, "emberroot") == true, "RecordMastery records a biome the first time")
	check(data.RecordMastery(recorder, "emberroot") == false, "and refuses it the second")
	check(recorderProfile.Mastery.emberroot == true, "the profile holds it")
	local stranger = stand("Stranger", -802, Players)
	check(data.RecordMastery(stranger, "greenhollow") == false, "nobody without a profile records anything")

	--== 6. THE FAUCETS REFUSE NONSENSE =======================================
	check(EconomyService.PayReward(recorder, 0 / 0, "spec") == false
		and EconomyService.PayReward(recorder, -5, "spec") == false
		and EconomyService.PayReward(recorder, 0, "spec") == false,
		"EconomyService.PayReward refuses NaN, negative and zero")
	check(TreadmillService.PayReward(recorder, 0 / 0, "spec") == false
		and TreadmillService.PayReward(recorder, -5, "spec") == false
		and TreadmillService.PayReward(recorder, 0, "spec") == false,
		"TreadmillService.PayReward refuses NaN, negative and zero")
	check(recorderProfile.Cash == 0 and recorderProfile.Speed == 0, "and nothing moved")
	check(EconomyService.PayReward(stranger, 10, "spec") == false
		and TreadmillService.PayReward(stranger, 10, "spec") == false,
		"neither pays a player without a profile")

	--== 7. AN UNFINISHED BIOME IS REFUSED AND PAYS NOTHING ===================
	AlmanacService.Init()
	local harvester, profile = join("Harvester", -803, 1000, 500)
	local paid, why = AlmanacService.Claim(harvester, "greenhollow")
	check(not paid and why == "locked", "an unfinished biome is refused as locked (got " .. tostring(why) .. ")")
	check(profile.Cash == 1000 and profile.Speed == 500, "and pays nothing")
	check(profile.Mastery.greenhollow == nil, "and records nothing")

	--== 8. A FINISHED ONE PAYS EXACTLY ITS REWARD ============================
	for _, species in ipairs(green) do
		data.MarkSeen(harvester, species.Id)
	end
	AlmanacService.Init()
	local cash, speed = AlmanacData.Reward("greenhollow")
	paid, why = AlmanacService.Claim(harvester, "greenhollow")
	check(paid and why == "paid", "a finished biome is paid (got " .. tostring(why) .. ")")
	check(profile.Cash == 1000 + cash, "cash rose by exactly the biome's MasteryCash (" .. tostring(profile.Cash) .. ")")
	check(profile.Speed == 500 + speed, "Speed rose by exactly its MasterySpeed (" .. tostring(profile.Speed) .. ")")
	check(profile.Mastery.greenhollow == true, "and the biome is recorded as paid")

	--== 9. NOT TWICE =========================================================
	AlmanacService.Init()
	paid, why = AlmanacService.Claim(harvester, "greenhollow")
	check(not paid and why == "claimed", "a second claim is refused as claimed (got " .. tostring(why) .. ")")
	check(profile.Cash == 1000 + cash and profile.Speed == 500 + speed, "and pays nothing")

	--== 10. THE COOLDOWN =====================================================
	AlmanacService.Init()
	AlmanacService.Claim(harvester, "dustbowl")
	paid, why = AlmanacService.Claim(harvester, "dustbowl")
	check(not paid and why == "busy", "a second request inside the cooldown is refused unread (got " .. tostring(why) .. ")")
	check(profile.Mastery.dustbowl == nil, "a refused claim records nothing")

	--== 11. WHAT A CLIENT MIGHT SEND =========================================
	local unknownEverywhere = true
	local junk: { any } = { 5, "nowhere", {}, true, "" }
	for _, value in ipairs(junk) do
		AlmanacService.Init()
		local p, reason = AlmanacService.Claim(harvester, value)
		if p or reason ~= "unknown" then
			unknownEverywhere = false
		end
	end
	AlmanacService.Init()
	local pNil, reasonNil = AlmanacService.Claim(harvester, nil)
	check(unknownEverywhere and not pNil and reasonNil == "unknown", "anything that is not a biome id is unknown")
	check(profile.Cash == 1000 + cash and profile.Speed == 500 + speed, "and none of it pays")

	--== 12. NOBODY, AND GONE =================================================
	AlmanacService.Init()
	local pLoading, whyLoading = AlmanacService.Claim(stranger, "greenhollow")
	check(not pLoading and whyLoading == "loading", "a player with no profile is told it is loading")
	local gone = stand("Gone", -804, nil)
	local pGone, whyGone = AlmanacService.Claim(gone, "greenhollow")
	check(not pGone and whyGone == "gone", "a player who has left is gone")

	--== 13. A PAID BIOME SURVIVES THE SAVE ===================================
	local reloaded: any = ProfileSchema.Sanitise(profile)
	check(reloaded.Mastery.greenhollow == true and reloaded.Mastery.dustbowl == nil,
		"the Mastery set round-trips through Sanitise")
	check(AlmanacData.ClaimState(reloaded.Almanac, reloaded.Mastery, "greenhollow") == "claimed",
		"and a reloaded profile still reads the biome as claimed")
end)

for _, p in ipairs(joined) do
	pcall(data.Leave, p)
end
AlmanacService.Init()
saves.Load = real.Load
saves.Save = real.Save
saves.Forget = real.Forget
plots.SetDesiredLevel = real.SetDesiredLevel
data.MountStats = real.MountStats
fixture:Destroy()

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("AlmanacClaimSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("AlmanacClaimSpec: %d passed, 0 failed"):format(pass)
