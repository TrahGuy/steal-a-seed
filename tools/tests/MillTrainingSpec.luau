--!nocheck
--==============================================================================
-- Steal a Seed :: MillTrainingSpec
--
-- The mill pays ONE rate (2026-10-05, the owner's ask: the temporary,
-- rechargeable Training Rush is gone from the payout). The real
-- TreadmillService, its siblings stood in and its clock scripted, pays every
-- tick exactly
--
--     tier x rebirth  x  the Bonus Chest's training reward  x  the Disco Mill's 10  x  the tick
--
-- (an overclock factor sat after the tier until 2026-10-06; a save that still
-- carries overclock levels is paid its tier's rate alone)
--
-- for a fresh profile, a "rested" one, a "depleted" one and one carrying the
-- old saved charge fields alike, for longer than the old 90 s charge and 30 s
-- climb lasted; stepping off and on, a new body and a rejoin change nothing and
-- catch nothing up; the Disco Mill is exactly x10, never the old x40; Speed is
-- added once a tick; no Rush attribute is ever written; the old fields are
-- never read or written and the save no longer carries them. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("MillTrainingSpec"))
--
-- Not here, seen in Play instead: a real belt under a real character.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = game:GetService("ServerScriptService").SeedGameServer
local Scripts = game:GetService("StarterPlayer").StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local ProfileSchema = require(Server.ProfileSchema)

local M = GameConfig.MiniEvent
local DISCO = M.DiscoMill
local ATTR = GameConfig.Attributes

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
		say("  FAIL  " .. label .. (if detail ~= nil and detail ~= "" then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local s = parent:FindFirstChild(name, true)
	return if s then s.Source else ""
end
local function near(x, y)
	return math.abs(x - y) <= 1e-9 * math.max(1, math.abs(y))
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZMillTrainingSpec"
scratch.Archivable = false
scratch.Parent = Workspace
local savedAttrs = {}
for _, name in ipairs({ M.Attributes.State, M.Attributes.Mode, M.Attributes.EventId }) do
	savedAttrs[name] = Workspace:GetAttribute(name)
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. Nothing of the Rush is left to pay with")
	--==========================================================================
	local treadmill = sourceOf(Server, "TreadmillService")
	local fx = sourceOf(Scripts, "SpeedFX")
	local configSrc = sourceOf(Shared, "GameConfig")
	local schemaSrc = sourceOf(Server, "ProfileSchema")
	-- Live uses only (a comment may still say what was removed).
	local leftovers = {}
	for _, token in ipairs({ "consumeRush(", "decayRush(", "publishRush(", "restoredCharge(", "wasTraining[", "ramp[",
		"rampAt[", "TRAIN.", "LADDER.Training", "profile.TrainingCharge", "Attributes.TrainingRush", "ATTR.TrainingRush",
		"ATTR.TrainingCharge", "trainingRushBlend(", "trainingRushMultiplier(", "rushTag(" }) do
		for name, src in pairs({ TreadmillService = treadmill, SpeedFX = fx, ProfileSchema = schemaSrc }) do
			if string.find(src, token, 1, true) then
				table.insert(leftovers, name .. ":" .. token)
			end
		end
	end
	check(#leftovers == 0, "no ramp, charge, restore or publication remains in the mill, the +Speed pop or the save",
		table.concat(leftovers, ", "))
	check(GameConfig.Mill.Training == nil and GameConfig.trainingRushMultiplier == nil
		and GameConfig.trainingRushBlend == nil and ATTR.TrainingRush == nil and ATTR.TrainingCharge == nil
		and not string.find(configSrc, "trainingRushBlend", 1, true),
		"GameConfig has no Training block, no rush helpers and no Rush attribute names")
	check(string.find(treadmill, 'local paid = rate * BonusChestService.Multiplier(player, "training") * discoFactor * dt',
		1, true) ~= nil,
		"the one line that mints belt Speed: the rate x the chest's training reward x the Disco Mill x the tick")
	check(not string.find(fx, "rushTag", 1, true)
		and string.find(fx, 'label.Text = "+" .. GameConfig.compact(math.max(1, math.floor(amount + 0.5)))', 1, true) ~= nil,
		"the +Speed pop prints the amount alone -- no x4 tag")

	--==========================================================================
	say("2. The real TreadmillService, its clock scripted")
	--==========================================================================
	local riders = {}
	local profiles, chestMult, paid = {}, {}, {}
	local function fakePlayer(name, plotId, tier, overclock, extra)
		local attrs = {}
		local p = { Name = name, UserId = 7300 + #riders }
		function p:GetAttribute(k)
			return attrs[k]
		end
		function p:SetAttribute(k, v)
			attrs[k] = v
		end
		p._attrs = attrs
		local model = Instance.new("Model")
		model.Name = "ZZTrainee_" .. name
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Size = Vector3.new(2, 2, 1)
		root.Parent = model
		model.PrimaryPart = root
		Instance.new("Humanoid").Parent = model
		model.Parent = scratch
		p.Character = model
		p.plotId = plotId
		local profile = { MillTier = tier, MillOverclock = overclock, Speed = 0 }
		for k, v in pairs(extra or {}) do
			profile[k] = v
		end
		profiles[p] = profile
		table.insert(riders, p)
		return p
	end
	local fakePlayers = {}
	function fakePlayers:GetPlayers()
		return riders
	end
	function fakePlayers:GetPlayerFromCharacter(character)
		for _, p in ipairs(riders) do
			if p.Character == character then
				return p
			end
		end
		return nil
	end
	local plots = {}
	local function plotOf(player)
		local plot = plots[player.plotId]
		if not plot then
			plot = { id = player.plotId, owner = player }
			function plot:GetAttribute(k)
				return if k == ATTR.PlotId then self.id else nil
			end
			plots[player.plotId] = plot
		end
		plot.owner = player
		return plot
	end
	local PlotService = { PlotOf = plotOf, OwnerOf = function(plot)
		return plot.owner
	end }
	local writes = 0
	local PlayerDataService = {
		IsReady = function()
			return true
		end,
		Get = function(player)
			return profiles[player]
		end,
		AddSpeed = function(player, amount)
			table.insert(paid, { player = player, amount = amount })
			profiles[player].Speed += amount
			return true
		end,
	}
	local CarryService = { RefreshWalkSpeed = function() end }
	local BonusChestService = { Multiplier = function(player, kind)
		return if kind == "training" then (chestMult[player] or 1) else 1
	end }
	local fakeGame = {}
	function fakeGame:GetService(name)
		if name == "Players" then
			return fakePlayers
		end
		return game:GetService(name)
	end
	-- The clock the payout reads (os.clock); os.time stays real, so a "rested"
	-- saved stamp really is eight hours old.
	local clock = 1000
	local fakeOs = setmetatable({ clock = function()
		return clock
	end }, { __index = os })
	local module = Server.TreadmillService
	local chunk = assert(loadstring(module.Source, "=TreadmillService"))
	local siblings = { PlotService = PlotService, PlayerDataService = PlayerDataService,
		CarryService = CarryService, BonusChestService = BonusChestService }
	local parent = {}
	function parent:WaitForChild(name)
		assert(siblings[name] ~= nil, "unexpected sibling " .. name)
		return { __standIn = siblings[name] }
	end
	local outerRequire = require
	setfenv(chunk, setmetatable({
		game = fakeGame,
		os = fakeOs,
		script = { Name = "TreadmillService", Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	local Treadmill = chunk()
	Treadmill.Init()

	local function ownMill(id, x)
		local mill = Instance.new("Model")
		mill.Name = "ZZTrainMill" .. id
		mill:SetAttribute(ATTR.PlotId, id)
		local belt = Instance.new("Part")
		belt.Name = "Treadmill"
		belt.Anchored = true
		belt.Size = Vector3.new(8, 1.4, 16)
		belt.Position = Vector3.new(x, 1, 3400)
		belt.Parent = mill
		mill.Parent = scratch
		CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)
		return belt
	end
	local function standOn(p, belt)
		p.Character.HumanoidRootPart.CFrame = belt.CFrame * CFrame.new(0, belt.Size.Y / 2 + 1, 0)
	end
	local function stepOff(p)
		p.Character.HumanoidRootPart.CFrame = CFrame.new(p.Character.HumanoidRootPart.Position + Vector3.new(0, 0, 60))
	end
	local now = os.time()
	-- Six own-mill trainees, one charge story each, and a tier-5 one whose save
	-- still carries two overclock levels -- which pay nothing now.
	local fresh = fakePlayer("Fresh", 951, 1, 0)
	local rested = fakePlayer("Rested", 952, 1, 0, { TrainingCharge = 90, TrainingChargeAt = now - 8 * 3600 })
	local depleted = fakePlayer("Depleted", 953, 1, 0, { TrainingCharge = 0, TrainingChargeAt = now })
	local junk = fakePlayer("Junk", 954, 1, 0, { TrainingCharge = 1e9, TrainingChargeAt = -5 })
	local big = fakePlayer("Big", 955, 5, 2, { TrainingCharge = 90, TrainingChargeAt = now - 3600 })
	local chest = fakePlayer("Chest", 956, 1, 0, { TrainingCharge = 90, TrainingChargeAt = now - 3600 })
	chestMult[chest] = 1.25
	local belts = {}
	for i, p in ipairs({ fresh, rested, depleted, junk, big, chest }) do
		belts[p] = ownMill(p.plotId, 3400 + i * 40)
		standOn(p, belts[p])
	end
	local legacyBefore = HttpService:JSONEncode({ profiles[rested].TrainingCharge, profiles[rested].TrainingChargeAt,
		profiles[junk].TrainingCharge, profiles[big].TrainingChargeAt })

	local function tick(dt)
		clock += dt
		table.clear(paid)
		Treadmill.PayTick()
		local got, count = {}, {}
		for _, row in ipairs(paid) do
			got[row.player] = (got[row.player] or 0) + row.amount
			count[row.player] = (count[row.player] or 0) + 1
		end
		return got, count
	end

	--==========================================================================
	say("3. One rate, every tick, for longer than the old charge lasted")
	--==========================================================================
	tick(0) -- the first tick starts every clock; it pays nothing
	local wrong, once = {}, true
	local samples = {}
	for t = 1, 130 do
		local got, count = tick(1)
		for _, p in ipairs({ fresh, rested, depleted, junk, big, chest }) do
			local want = Treadmill.RateOf(p) * (chestMult[p] or 1) * 1
			if not near(got[p] or 0, want) then
				table.insert(wrong, string.format("%s@%d %.3f/%.3f", p.Name, t, got[p] or 0, want))
			end
			if (count[p] or 0) ~= 1 then
				once = false
			end
		end
		if t == 1 or t == 30 or t == 91 or t == 130 then
			table.insert(samples, string.format("t%d %s", t, tostring(got[fresh])))
		end
	end
	check(#wrong == 0, "130 one-second ticks: fresh, rested 8 h, depleted, nonsense-charged, old-overclock and chest-boosted "
		.. "trainees each earn their own rate every tick -- no climb, no plateau, no drop at 90 s ("
		.. table.concat(samples, ", ") .. ")", table.concat(wrong, ", "):sub(1, 400))
	check(once, "and each is handed Speed exactly once a tick")
	check(near(Treadmill.RateOf(fresh), GameConfig.trainingRateFor(1, nil)) and Treadmill.RateOf(fresh) == 20
		and near(Treadmill.RateOf(big), GameConfig.trainingRateFor(5, nil))
		and near(Treadmill.RateOf(big), GameConfig.Mill.Tiers[5].speed),
		string.format("the rate is the mill's own: tier 1 %s/s; tier 5 %s/s with two old overclock levels in its save "
			.. "-- the tier's rate, no overclock factor", tostring(Treadmill.RateOf(fresh)), tostring(Treadmill.RateOf(big))))
	local got = tick(1)
	check(near(got[chest] or 0, (got[fresh] or 0) * 1.25),
		"the Bonus Chest's +25% training reward applies once, on the same rate", string.format("%s vs %s",
			tostring(got[chest]), tostring(got[fresh])))
	got = tick(2.5)
	check(near(got[fresh] or 0, Treadmill.RateOf(fresh) * 2.5), "a longer tick pays its own length at the same rate",
		tostring(got[fresh]))

	--==========================================================================
	say("4. Stepping off, a new body and a rejoin change nothing and catch nothing up")
	--==========================================================================
	stepOff(fresh)
	for _ = 1, 20 do
		tick(1)
	end
	standOn(fresh, belts[fresh])
	local back1 = tick(1)
	local back2 = tick(1)
	check((back1[fresh] or 0) == 0 and near(back2[fresh] or 0, Treadmill.RateOf(fresh)),
		"twenty seconds off the belt: the first tick back starts its clock (nothing for the time away), the next pays "
			.. "the same rate as ever", string.format("%s then %s", tostring(back1[fresh]), tostring(back2[fresh])))
	-- A new body: the old character gone, a new one on the belt.
	local oldBody = depleted.Character
	local body = oldBody:Clone()
	body.Parent = scratch
	depleted.Character = body
	oldBody:Destroy()
	standOn(depleted, belts[depleted])
	tick(1)
	local respawned = tick(1)
	check(near(respawned[depleted] or 0, Treadmill.RateOf(depleted)), "after a respawn the same rate",
		tostring(respawned[depleted]))
	-- A rejoin: the server meets a NEW player with the same saved profile.
	local profile = profiles[rested]
	for i, p in ipairs(riders) do
		if p == rested then
			table.remove(riders, i)
			break
		end
	end
	local rejoined = fakePlayer("Rejoined", 952, 1, 0)
	profiles[rejoined] = profile
	standOn(rejoined, belts[rested])
	tick(1)
	local after = tick(1)
	check(near(after[rejoined] or 0, Treadmill.RateOf(rejoined)) and near(after[rejoined] or 0, 20),
		"after a rejoin (the old charge still in the record) the same 20/s, not a fresh x4", tostring(after[rejoined]))

	--==========================================================================
	say("5. The Disco Mill is exactly x10, never the old x40")
	--==========================================================================
	local W = Workspace
	local function event(state, mode, id)
		W:SetAttribute(M.Attributes.EventId, id)
		W:SetAttribute(M.Attributes.Mode, mode)
		W:SetAttribute(M.Attributes.State, state)
		Treadmill.SyncDiscoMill()
	end
	event("running", "ticketdisco", "spec0000train001")
	local rider = fakePlayer("Rider", 957, 1, 0, { TrainingCharge = 90, TrainingChargeAt = now - 8 * 3600 })
	local spot = Treadmill.MountDisco(rider)
	tick(1)
	local discoWrong = {}
	for t = 1, 40 do
		local g = tick(1)
		if not near(g[rider] or 0, Treadmill.RateOf(rider) * DISCO.Multiplier) then
			table.insert(discoWrong, string.format("t%d %s", t, tostring(g[rider])))
		end
	end
	check(spot ~= nil and #discoWrong == 0 and DISCO.Multiplier == 10,
		string.format("a fully 'rested' rider on the Disco Mill earns %s/s every tick for 40 s: x10 of their own %s, "
			.. "never x40", tostring(Treadmill.RateOf(rider) * DISCO.Multiplier), tostring(Treadmill.RateOf(rider))),
		table.concat(discoWrong, ", "))
	Treadmill.Unmount(rider)
	event(nil, nil, nil)

	--==========================================================================
	say("6. No Rush attribute, and the old fields are left as they were")
	--==========================================================================
	local stray = {}
	for _, p in ipairs(riders) do
		for k in pairs(p._attrs) do
			if string.find(k, "Training", 1, true) or string.find(k, "Rush", 1, true) then
				table.insert(stray, p.Name .. ":" .. k)
			end
		end
	end
	check(#stray == 0, "no player was ever given a TrainingRush or TrainingCharge attribute", table.concat(stray, ", "))
	local legacyAfter = HttpService:JSONEncode({ profile.TrainingCharge, profile.TrainingChargeAt,
		profiles[junk].TrainingCharge, profiles[big].TrainingChargeAt })
	check(legacyAfter == legacyBefore, "the mill never read or wrote an old record's charge fields", legacyAfter)

	for _, p in ipairs(riders) do
		Treadmill.Unmount(p)
	end
	for _, belt in pairs(belts) do
		CollectionService:RemoveTag(belt, GameConfig.Tags.Treadmill)
	end
	local disco = W:FindFirstChild(DISCO.ModelName)
	if disco then
		disco:Destroy()
	end

	--==========================================================================
	say("7. The save: an old record loads whole, its charge fields drop out")
	--==========================================================================
	local raw = ProfileSchema.Default()
	raw.Speed = 123456
	raw.MillTier = 6
	raw.MillOverclock = 3
	raw.TrainingCharge = 90
	raw.TrainingChargeAt = now - 999
	local round = ProfileSchema.Sanitise(HttpService:JSONDecode(HttpService:JSONEncode(ProfileSchema.Sanitise(raw))))
	local defaults = ProfileSchema.Default()
	check(round.Speed == 123456 and round.MillTier == 6 and round.MillOverclock == 3 and round.TrainingCharge == nil
		and round.TrainingChargeAt == nil and defaults.TrainingCharge == nil and defaults.TrainingChargeAt == nil,
		"Speed, mill tier and overclock come back exactly; neither field is in a new profile or a sanitised old one")
end)

for name, value in pairs(savedAttrs) do
	Workspace:SetAttribute(name, value)
end
scratch:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMillTrainingSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
