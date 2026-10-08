--!nocheck
--==============================================================================
-- Steal a Seed :: MillOverclockSpec
--
-- OVERCLOCK IS HISTORY, AND AN OLD SAVE LOSES NOTHING (the owner's addendum,
-- 2026-10-06)
--
-- A tier-10 mill used to buy overclock levels: 400M x 2^level a second. Tiers
-- 11-14 -- the owner's own mills -- replaced them. On load, a tier-10 save with
-- levels becomes the LOWEST of tiers 11-14 paying at least what it did, once,
-- for nothing (ProfileSchema.convertOverclock, run by PlayerDataService):
--
--     levels 1-2 -> 11 Abyssal Trench    3-5 -> 12 Volcanic Forge
--     levels 6-7 -> 13 Frozen Aurora     8-10 -> 14 Event Horizon
--
-- and its overclock goes to 0. Below tier 10 the levels just go. Held here:
--
--   1. the conversion for every level 0-10, run twice (idempotent), through
--      the same JSON round trip a save takes, and below tier 10
--   2. the load: PlayerDataService converts, marks the save dirty and tells
--      the player once (MillNotice.client)
--   3. no overclock is for sale anywhere and the rate has no overclock factor
--   4. a tier-14 save loads and clamps
--   5. the board, through the real TreadmillService (its siblings stood in): a
--      tier-10 mill offers Abyssal Trench at its price and rate, a tier-14 one
--      says MAX, and the hold buys the tier, never an overclock
--
-- Never a real store: profiles are built in memory. Edit mode.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = game:GetService("ServerScriptService").SeedGameServer
local Scripts = game:GetService("StarterPlayer").StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local MillModel = require(Shared.MillModel)
local ProfileSchema = require(Server.ProfileSchema)

local TIERS = GameConfig.Mill.Tiers
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
-- A save as the store would hand it back: sanitised, encoded, decoded.
local function loaded(raw)
	return ProfileSchema.Sanitise(HttpService:JSONDecode(HttpService:JSONEncode(ProfileSchema.Sanitise(raw))))
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZMillOverclockSpec"
scratch.Archivable = false
scratch.Parent = Workspace

local ok, err = pcall(function()
	--==========================================================================
	say("1. The conversion, every level, twice")
	--==========================================================================
	local WANT = { [0] = 10, 11, 11, 12, 12, 12, 13, 13, 14, 14, 14 }
	local wrong, notLowest = {}, {}
	local line = {}
	for level = 0, 10 do
		local p = loaded({ MillTier = 10, MillOverclock = level, Speed = 5e9, Cash = 123 })
		local became = ProfileSchema.convertOverclock(p)
		local again = ProfileSchema.convertOverclock(p)
		local after = loaded(p)
		local want = WANT[level]
		if p.MillTier ~= want or p.MillOverclock ~= 0 or again ~= nil or after.MillTier ~= want
			or after.MillOverclock ~= 0 or (level > 0 and became ~= want) or (level == 0 and became ~= nil)
			or p.Speed ~= 5e9 or p.Cash ~= 123 then
			table.insert(wrong, string.format("L%d -> %s (again %s, reloaded %d/%d)", level, tostring(p.MillTier),
				tostring(again), after.MillTier, after.MillOverclock))
		end
		if level > 0 then
			local paid = 400e6 * 2 ^ level
			local below = TIERS[p.MillTier - 1]
			if TIERS[p.MillTier].speed < paid or (p.MillTier > 11 and below.speed >= paid) then
				table.insert(notLowest, "L" .. level)
			end
		end
		table.insert(line, string.format("L%d->%d", level, p.MillTier))
	end
	check(#wrong == 0, "a tier-10 save at levels 0-10 becomes 10/11/11/12/12/12/13/13/14/14/14, overclock 0, the "
		.. "rest of the save untouched -- and a second run, or a reload, changes nothing", table.concat(wrong, " | "))
	check(#notLowest == 0, "each is the LOWEST of tiers 11-14 paying at least 400M x 2^level", table.concat(notLowest, ", "))
	say("  (" .. table.concat(line, " ") .. ")")

	local low = loaded({ MillTier = 5, MillOverclock = 4 })
	local lowBecame = ProfileSchema.convertOverclock(low)
	local high = loaded({ MillTier = 12, MillOverclock = 3 })
	local highBecame = ProfileSchema.convertOverclock(high)
	check(lowBecame == nil and low.MillTier == 5 and low.MillOverclock == 0
			and highBecame == nil and high.MillTier == 12 and high.MillOverclock == 0,
		"below tier 10 the levels just go and the tier stays (5 stays 5); any other tier the same (12 stays 12)",
		string.format("%s %d %d | %s %d %d", tostring(lowBecame), low.MillTier, low.MillOverclock,
			tostring(highBecame), high.MillTier, high.MillOverclock))
	local junk = loaded({ MillTier = 10, MillOverclock = 1e9 })
	check(junk.MillOverclock == 10 and ProfileSchema.convertOverclock(junk) == 14,
		"a save claiming more levels than there were is held at ten, and becomes Event Horizon")
	check(ProfileSchema.Default().MillOverclock == 0 and ProfileSchema.convertOverclock(ProfileSchema.Default()) == nil,
		"a new save has no overclock and nothing to convert")

	--==========================================================================
	say("\n2. The load converts once, saves it and says so once")
	--==========================================================================
	local pds = sourceOf(Server, "PlayerDataService")
	local notice = sourceOf(Scripts, "MillNotice")
	check(string.find(pds, "local becameTier = ProfileSchema.convertOverclock(profile)", 1, true) ~= nil
			and string.find(pds, "dirty = status == \"new\" or offlineAdded > 0 or hadOverclock,", 1, true) ~= nil,
		"PlayerDataService converts on every load and marks the save dirty, so the normal save path keeps it")
	check(string.find(pds, "player:SetAttribute(GameConfig.Attributes.MillOverclockBecame, becameTier)", 1, true) ~= nil
			and ATTR.MillOverclockBecame == "MillOverclockBecame",
		"and marks the player with the tier it became")
	check(string.find(notice, 'title = string.format("Your Overclock became %s!", spec.name)', 1, true) ~= nil
			and string.find(notice, 'kind = "info"', 1, true) ~= nil and string.find(notice, "Notice.ready()", 1, true) ~= nil
			and string.find(notice, "if told then", 1, true) ~= nil,
		"MillNotice.client posts one info notice, \"Your Overclock became <tier name>!\", once the notices are up")

	--==========================================================================
	say("\n3. Nothing sells an overclock; nothing pays one")
	--==========================================================================
	local treadmill = sourceOf(Server, "TreadmillService")
	local debug = sourceOf(Server, "DebugService")
	local leftovers = {}
	for name, src in pairs({ TreadmillService = treadmill, PlayerDataService = pds, DebugService = debug }) do
		for _, token in ipairs({ 'kind = "overclock"', "SetMillOverclock", "overclockCostFor", "overclockMultiplierFor",
			"OverclockOf", "Overclock.Label", "Overclock.MaxLevel", "payload.overclock" }) do
			if string.find(src, token, 1, true) then
				table.insert(leftovers, name .. ":" .. token)
			end
		end
	end
	check(#leftovers == 0 and GameConfig.Mill.Overclock == nil and GameConfig.overclockCostFor == nil,
		"no buy path, no setter, no price list, no label and no debug level is left", table.concat(leftovers, ", "))
	check(GameConfig.trainingRateFor(10, { MillOverclock = 4 }) == 400e6
			and GameConfig.trainingRateFor(12, nil) == 15e9,
		"a tier-10 save still holding 4 levels trains at 400M/s until it loads; converted, at tier 12's 15B/s "
			.. "(above the 6.4B/s it had)")

	--==========================================================================
	say("\n4. A tier-14 save loads, and nothing past it does")
	--==========================================================================
	local t14 = loaded({ MillTier = 14 })
	local t99 = loaded({ MillTier = 99 })
	local t0 = loaded({ MillTier = 0 })
	local tFrac = loaded({ MillTier = 13.7 })
	check(t14.MillTier == 14 and t99.MillTier == 14 and t0.MillTier == 1 and tFrac.MillTier == 13,
		"tier 14 loads as 14; 99 clamps to 14, 0 to 1, 13.7 to 13",
		string.format("%d %d %d %d", t14.MillTier, t99.MillTier, t0.MillTier, tFrac.MillTier))

	--==========================================================================
	say("\n5. The board and the hold, through the real TreadmillService")
	--==========================================================================
	local PLOT = 961
	local player = { Name = "ZZOverclockSpecPlayer", UserId = 90000000961 }
	local attrs = {}
	function player:GetAttribute(k)
		return attrs[k]
	end
	function player:SetAttribute(k, v)
		attrs[k] = v
	end
	local profile = { MillTier = 10, MillOverclock = 4, Speed = 0, Cash = 0 }
	local fakePlayers = {}
	function fakePlayers:GetPlayers()
		return { player }
	end
	function fakePlayers:GetPlayerFromCharacter()
		return nil
	end
	local plot = { owner = player }
	function plot:GetAttribute(k)
		return if k == ATTR.PlotId then PLOT else nil
	end
	local PlotService = {
		PlotOf = function()
			return plot
		end,
		OwnerOf = function()
			return player
		end,
	}
	local PlayerDataService = {
		IsReady = function()
			return true
		end,
		Get = function()
			return profile
		end,
		AddCash = function(_, amount)
			profile.Cash += amount
			return true
		end,
		SetMillTier = function(_, tier)
			profile.MillTier = tier
			return true
		end,
		AddSpeed = function()
			return true
		end,
	}
	local fakeGame = {}
	function fakeGame:GetService(name)
		if name == "Players" then
			return fakePlayers
		end
		return game:GetService(name)
	end
	local chunk = assert(loadstring(Server.TreadmillService.Source, "=TreadmillService"))
	local siblings = { PlotService = PlotService, PlayerDataService = PlayerDataService,
		CarryService = { RefreshWalkSpeed = function() end },
		BonusChestService = { Multiplier = function()
			return 1
		end } }
	local parent = {}
	function parent:WaitForChild(name)
		assert(siblings[name] ~= nil, "unexpected sibling " .. name)
		return { __standIn = siblings[name] }
	end
	local outerRequire = require
	setfenv(chunk, setmetatable({
		game = fakeGame,
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

	-- A real mill and sign on a spec plot, far from the preview map.
	local mill, belt = MillModel.Build(10, CFrame.new(0, 0, 4200), scratch)
	mill:SetAttribute(ATTR.PlotId, PLOT)
	CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)
	local function boardText()
		task.wait()
		task.wait()
		for _, sign in ipairs(CollectionService:GetTagged(GameConfig.Tags.MillSign)) do
			if sign:GetAttribute(ATTR.PlotId) == PLOT and sign:IsDescendantOf(scratch) then
				local face = sign.Board:FindFirstChild("Face")
				local prompt = sign.Board:FindFirstChildOfClass("ProximityPrompt")
				return string.format("%s | %s | %s | %s", face.Title.Text, face.Step.Text, face.Rate.Text,
					face.Buy.Price.Text), prompt.Enabled
			end
		end
		return "no sign", nil
	end

	local step = Treadmill.NextStepFor(player)
	check(step.kind == "tier" and step.level == 11 and step.cost == 400e9,
		"a tier-10 save -- even one still holding levels -- is offered tier 11 for $400B, never an overclock",
		string.format("%s %s %s", tostring(step.kind), tostring(step.level), tostring(step.cost)))
	Treadmill.Rebuild(plot, 10)
	local text10, enabled10 = boardText()
	check(text10 == "UPGRADE | ABYSSAL TRENCH | BASE 400M/s  >  2.5B/s | $400B" and enabled10 == true,
		"its board: UPGRADE, ABYSSAL TRENCH, BASE 400M/s > 2.5B/s, $400B, the prompt live", text10)

	check(not Treadmill.Upgrade(player) and profile.MillTier == 10 and profile.Cash == 0,
		"with no cash the hold buys nothing and takes nothing")
	profile.Cash = 400e9
	check(Treadmill.Upgrade(player) and profile.MillTier == 11 and profile.Cash == 0 and profile.MillOverclock == 4,
		"with $400B it buys tier 11 -- the mill, not an overclock (the old levels are not even read)",
		string.format("tier %d cash %s", profile.MillTier, tostring(profile.Cash)))
	local rebuilt
	for _, b in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if b.Parent and b.Parent:GetAttribute(ATTR.PlotId) == PLOT then
			rebuilt = b.Parent
		end
	end
	check(rebuilt ~= nil and rebuilt:GetAttribute("MillTier") == 11 and rebuilt:GetAttribute("MillForm") == "abyssaltrench",
		"and the mill on the plot is rebuilt as the owner's Abyssal Trench",
		rebuilt and tostring(rebuilt:GetAttribute("MillForm")))

	profile.MillTier = 14
	profile.Cash = 1e15
	Treadmill.Rebuild(plot, 14)
	local text14, enabled14 = boardText()
	check(Treadmill.NextStepFor(player).kind == "max" and not Treadmill.Upgrade(player) and profile.Cash == 1e15
			and text14 == "UPGRADE | LEVEL 14  ·  MAX | EVENT HORIZON  ·  450B/s | MAX" and enabled14 == false,
		"at tier 14 there is nothing to buy: the board says MAX, the prompt is off, the hold takes nothing", text14)
	say("  (tier 10's board: " .. text10 .. ")")
	say("  (tier 14's board: " .. text14 .. ")")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

scratch:Destroy()
say(string.format("\nMillOverclockSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
