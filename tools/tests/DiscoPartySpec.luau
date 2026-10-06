--!nocheck
--==============================================================================
-- Steal a Seed :: DiscoPartySpec (2026-10-04, the owner's DISCO ONLY brief)
--
-- Edit mode, no Play:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("DiscoPartySpec"))
--
-- The pure DISCO ONLY mini event ("party") gives everybody x1.5 MOVEMENT while
-- it runs. This spec holds the factor and where it is applied:
--
-- 1. THE FACTOR (GameConfig.miniEventSpeedFactor) off the event's published
--    attributes: 1.5 only while a party RUNS; 1 for no event, an ending one,
--    every other mode and an unknown id.
-- 2. THE ONE WRITER (the real CarryService.RefreshWalkSpeed, a stand-in
--    profile): exactly one x1.5 however often it recomputes; the weight, a
--    trap's slow and Walk Mode's ceiling still apply on top; a trap's hold, a
--    mill and the obby's fixed speed still win; never past MaxWalkSpeed; the
--    published carry multiplier and the Speed score untouched; the end is the
--    normal speed recomputed, not a number put back.
-- 3. THE WIRING: the event's state or mode changing recomputes everybody once,
--    skipping a body knocked flat; config and console words.
--
-- NOT here (Play, guarded throwaway store): the console's press, a real carry
-- and Pod 3, a respawn, a real ragdoll, the popover drawn. NOT anywhere in
-- Studio: other servers -- MiniEventSpec runs the shared record between
-- stand-in servers; real ones are a live check.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")

local ATTR = GameConfig.Attributes
local M = GameConfig.MiniEvent
local EV = M.Attributes
local MAX = GameConfig.Speed.MaxWalkSpeed
local CAP = GameConfig.WalkMode.CapStuds

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
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function near(a, b)
	return math.abs(a - b) <= 1e-6
end
local function sourceOf(parent, name)
	local node = parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return node.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

-- The event's attributes are read off Workspace itself: whatever this Studio
-- has there is put back at the end, whatever happens.
local saved = {}
for _, name in ipairs({ EV.State, EV.Mode }) do
	saved[name] = Workspace:GetAttribute(name)
end
local function event(state, mode)
	Workspace:SetAttribute(EV.Mode, mode)
	Workspace:SetAttribute(EV.State, state)
end

local fixture = Instance.new("Folder")
fixture.Name = "ZZDiscoPartySpec"
fixture.Archivable = false
fixture.Parent = Workspace

local ok, err = pcall(function()
	--==========================================================================
	say("1. The factor")
	--==========================================================================
	event(nil, nil)
	local none = GameConfig.miniEventSpeedFactor()
	event("running", "party")
	local party = GameConfig.miniEventSpeedFactor()
	local again = GameConfig.miniEventSpeedFactor()
	event("ending", "party")
	local ending = GameConfig.miniEventSpeedFactor()
	check(none == 1 and party == 1.5 and again == 1.5 and ending == 1,
		"x1.5 while a DISCO ONLY runs, read the same every time; x1 with no event and from the moment it is ENDING",
		string.format("%s %s %s %s", none, party, again, ending))
	local others = {}
	for _, id in ipairs({ "disco", "ticketdisco", "tickets", "rave" }) do
		event("running", id)
		table.insert(others, id .. "=" .. tostring(GameConfig.miniEventSpeedFactor()))
	end
	check(table.concat(others, " ") == "disco=1 ticketdisco=1 tickets=1 rave=1",
		"every other mode -- DISCO + MILL, TICKET DISCO, TICKET SHOWER ONLY -- and an unknown id move nobody faster",
		table.concat(others, " "))
	event(nil, nil)

	--==========================================================================
	say("2. The one writer of WalkSpeed")
	--==========================================================================
	local profile = { Speed = 1e6, WalkMode = false }
	local PlayerDataService = {
		Get = function()
			return profile
		end,
		IsReady = function()
			return true
		end,
		WalkModeOf = function()
			return profile.WalkMode == true
		end,
	}
	local outerRequire = require
	local chunk = assert(loadstring(Server.CarryService.Source, "=CarryService"))
	local parent = {}
	function parent:WaitForChild(name)
		if name == "PlayerDataService" then
			return { __standIn = PlayerDataService }
		end
		return Server:WaitForChild(name)
	end
	setfenv(chunk, setmetatable({
		script = { Name = "CarryService", Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	local CarryService = chunk()

	local character = Instance.new("Model")
	character.Name = "PartyBody"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Position = Vector3.new(4300, 900, 4300)
	root.Parent = character
	character.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	character.Parent = fixture
	local attrs = {}
	local player = {
		Name = "PartySpec",
		UserId = 5601,
		Parent = Players,
		Character = character,
		GetAttribute = function(_, k)
			return attrs[k]
		end,
		SetAttribute = function(_, k, v)
			attrs[k] = v
		end,
		FindFirstChildOfClass = function()
			return nil
		end,
	}
	local function speedNow()
		CarryService.RefreshWalkSpeed(player)
		return humanoid.WalkSpeed
	end

	local normal = speedNow()
	check(near(normal, GameConfig.walkSpeedFor(1e6)), string.format("a player with 1M Speed runs at %.1f", normal))
	event("running", "party")
	local boosted = speedNow()
	speedNow()
	speedNow()
	local thrice = speedNow()
	check(near(boosted, normal * 1.5) and near(thrice, normal * 1.5),
		string.format("in a party they run at exactly x1.5 (%.1f), and three more recomputes -- a repeated START, a "
			.. "respawn, a reopened UI -- leave it at x1.5, never x2.25", boosted), thrice)

	-- The weight: the same multiplier, on top of the boosted speed, and the
	-- published one is still the weight's alone.
	CarryService.TotalKg = function()
		return 4000
	end
	local weight = GameConfig.carryMultiplierFor(4000)
	local loadedParty = speedNow()
	local publishedParty = player:GetAttribute(ATTR.CarrySpeedMultiplier)
	event(nil, nil)
	local loadedNormal = speedNow()
	local publishedNormal = player:GetAttribute(ATTR.CarrySpeedMultiplier)
	check(weight < 1 and near(loadedParty, normal * 1.5 * weight) and near(loadedNormal, normal * weight)
			and publishedParty == weight and publishedNormal == weight,
		string.format("a heavy pod still slows a partygoer by its own x%.3f, and the carry multiplier everybody sees "
			.. "is the weight's alone", weight),
		string.format("%.2f / %.2f, published %s / %s", loadedParty, loadedNormal, tostring(publishedParty),
			tostring(publishedNormal)))
	CarryService.TotalKg = function()
		return 0
	end

	-- What still wins outright.
	event("running", "party")
	attrs[ATTR.Trapped] = true
	local rooted = speedNow()
	attrs[ATTR.Trapped] = nil
	attrs[ATTR.MillMounted] = true
	local mounted = speedNow()
	attrs[ATTR.MillMounted] = nil
	attrs[ObbyData.Attributes.Course] = true
	local course = speedNow()
	attrs[ObbyData.Attributes.Course] = nil
	check(rooted == 0 and mounted == 0 and near(course, ObbyData.WalkSpeed),
		"a trap's hold and a mill are still zero in a party, and the obby still runs at its one course speed",
		string.format("%s %s %s", rooted, mounted, course))

	-- What still applies on top.
	attrs[ATTR.TrapSlow] = 0.35
	local snared = speedNow()
	attrs[ATTR.TrapSlow] = nil
	attrs[ATTR.WalkMode] = true
	local walking = speedNow()
	attrs[ATTR.WalkMode] = nil
	check(near(snared, normal * 1.5 * 0.35) and near(walking, math.min(normal * 1.5, CAP)),
		string.format("a trap's slow takes its 35%% of the boosted speed (%.2f) and Walk Mode still caps at %d",
			snared, CAP), string.format("%.2f %.2f", snared, walking))

	-- Never past the engine's ceiling.
	profile.Speed = 1e15
	local top = speedNow()
	profile.Speed = 100e9
	local high = GameConfig.walkSpeedFor(100e9)
	local highParty = speedNow()
	check(near(top, MAX) and near(highParty, math.min(high * 1.5, MAX)),
		string.format("never past MaxWalkSpeed (%d): a player already at it stays there, one at %.0f reaches %.0f",
			MAX, high, highParty), string.format("%.2f %.2f", top, highParty))
	profile.Speed = 1e6

	-- The end, and every way to it.
	local scoreBefore = profile.Speed
	event("ending", "party")
	local afterEnd = speedNow()
	event("running", "party")
	speedNow()
	event(nil, nil)
	local afterExpiry = speedNow()
	event("running", "party")
	speedNow()
	event("running", "disco")
	local replaced = speedNow()
	check(near(afterEnd, normal) and near(afterExpiry, normal) and near(replaced, normal),
		"ENDING, the event gone and another mode taking over each recompute the normal speed exactly",
		string.format("%.2f %.2f %.2f vs %.2f", afterEnd, afterExpiry, replaced, normal))
	-- Not a number put back: the score moves WHILE the party runs, and the end
	-- answers with the new normal.
	event("running", "party")
	speedNow()
	profile.Speed = 1e9
	speedNow()
	event(nil, nil)
	local fresh = speedNow()
	check(near(fresh, GameConfig.walkSpeedFor(1e9)) and not near(fresh, normal),
		"the end recomputes from the truth of the moment (Speed earned during the party counts), never a saved WalkSpeed",
		string.format("%.2f", fresh))
	profile.Speed = scoreBefore
	check(profile.Speed == scoreBefore and profile.WalkMode == false,
		"the Speed score and the profile are never written by the factor")

	--==========================================================================
	say("3. Wiring and words")
	--==========================================================================
	local carrySrc = sourceOf(Server, "CarryService")
	local factorAt = string.find(carrySrc, "local party = GameConfig.miniEventSpeedFactor()", 1, true) or 0
	local obbyAt = string.find(carrySrc, "humanoid.WalkSpeed = ObbyData.WalkSpeed", 1, true) or 0
	local productAt = string.find(carrySrc, "local speed = base * multiplier", 1, true) or 0
	local slowAt = string.find(carrySrc, "speed *= slow", 1, true) or 0
	local _, factorCalls = string.gsub(carrySrc, "miniEventSpeedFactor%(%)", "")
	check(factorAt > obbyAt and obbyAt > 0 and productAt > factorAt and slowAt > productAt
			and string.find(carrySrc, "base = math.min(base * party, math.max(base, GameConfig.Speed.MaxWalkSpeed))", 1, true) ~= nil,
		"CarryService applies it once, to the earned speed, after the hold/mill/obby returns and before the weight "
			.. "(Pod 3's half in its place), a trap's slow and Walk Mode")
	check(factorCalls == 3
			and string.find(carrySrc, "for _, name in ipairs({ EVENT_ATTR.State, EVENT_ATTR.Mode }) do", 1, true) ~= nil
			and string.find(carrySrc, "workspace:GetAttributeChangedSignal(name)", 1, true) ~= nil
			and string.find(carrySrc, "task.defer(refreshAll)", 1, true) ~= nil
			and string.find(carrySrc, "if humanoid and not humanoid.PlatformStand then", 1, true) ~= nil
			and string.find(carrySrc, "pcall(CarryService.RefreshWalkSpeed, player)", 1, true) ~= nil,
		"the event's state or mode changing recomputes everybody once (deferred), skipping a body knocked flat")
	local charAddedAt = string.find(carrySrc, "local function onCharacterAdded", 1, true) or 0
	check(charAddedAt > 0 and string.find(carrySrc, "CarryService.RefreshWalkSpeed(player)", charAddedAt, true) ~= nil,
		"a new body (a respawn, a late joiner) recomputes on arrival and so reads the running party")
	-- Everybody gets it, dancing or not: the server's one writer never reads the
	-- dance opt-out or a client's effects setting, and neither does the factor.
	local configSrc = sourceOf(Shared, "GameConfig")
	local fnAt = string.find(configSrc, "function GameConfig.miniEventSpeedFactor(): number", 1, true) or 0
	local fnEnd = string.find(configSrc, "\nend\n", fnAt, true) or 0
	local fnBody = string.sub(configSrc, fnAt, fnEnd)
	local refreshAt = string.find(carrySrc, "function CarryService.RefreshWalkSpeed", 1, true) or 0
	local refreshBody = string.sub(carrySrc, refreshAt, string.find(carrySrc, "\nend\n", refreshAt, true) or 0)
	check(fnAt > 0 and fnEnd > fnAt and #refreshBody > 0
			and string.find(fnBody .. refreshBody, "DiscoDance", 1, true) == nil
			and string.find(fnBody .. refreshBody, "Quality", 1, true) == nil
			and string.find(fnBody .. refreshBody, "OnTreadmill", 1, true) == nil
			and string.find(fnBody, "workspace:GetAttribute(M.Attributes.State)", 1, true) ~= nil,
		"everybody gets it even with dancing or the effects switched off: only the event's state and mode decide")
	local treadSrc = sourceOf(Server, "TreadmillService")
	check(string.find(treadSrc, "miniEventSpeedFactor", 1, true) == nil
			and string.find(sourceOf(Server, "PlayerDataService"), "miniEventSpeedFactor", 1, true) == nil
			and string.find(sourceOf(Server, "MiniEventService"), "miniEventSpeedFactor", 1, true) == nil,
		"nothing that pays training or saves a profile reads the factor")
	local modes = M.Modes
	check(modes.party and modes.party.SpeedFactor == 1.5 and modes.party.Mill == false and modes.party.Tickets == false
			and modes.party.Disco == true and modes.disco.Mill == true and modes.disco.Name == "DISCO + MILL"
			and modes.ticketdisco.Mill == true and modes.tickets.Mill == false
			and modes.disco.SpeedFactor == nil and modes.ticketdisco.SpeedFactor == nil and modes.tickets.SpeedFactor == nil,
		"only the new \"party\" id carries a SpeedFactor; \"disco\" keeps its id and its mill under DISCO + MILL")
	check(GameConfig.BoostIcons.Words.Party == "Disco Party"
			and string.format(GameConfig.BoostIcons.Words.PartyEffect, 50) == "Up to +50% movement speed"
			and modes.party.Announce.Detail == "Up to +50% movement speed for everyone!"
			and modes.party.Announce.Icon == "disco" and GameConfig.SourceIcons.disco == "rbxassetid://129016824458756",
		"the popover's words are the owner's (\"Up to +50% movement speed\", 2026-10-04), on the configured Disco icon")
	-- "Up to" is the truth while the cap bites: somebody on the curve gains less.
	local fastest = GameConfig.walkSpeedFor(math.huge)
	check(fastest * modes.party.SpeedFactor > MAX and MAX / modes.party.SpeedFactor == 100,
		string.format("the cap stays %d (the owner's decision): a player above 100 gains less than +50%%, which is "
			.. "why the label says \"Up to\"", MAX))
end)

for name, value in pairs(saved) do
	Workspace:SetAttribute(name, value)
end
fixture:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nDiscoPartySpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
