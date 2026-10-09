--!nocheck
--==============================================================================
-- Steal a Seed :: BatHintSpec
--
-- The bat hint and the stall's SHOP word (2026-10-08, the owner: "change sell
-- to shop and add the hint"). Edit mode:
--
--   1. the rules: who owns a bat; who is told -- chased, no bat, never told,
--      past the guide's first loop (or the guide skipped)
--   2. the real BatHintService, loaded from its Source with PlayerDataService
--      and Players stood in: the first chase tells once, with the flag saved
--      first; a second chase, an unready profile and a bat owner hear nothing
--   3. the save: a new profile and an old one start untold, a told one stays
--      told, and a progress reset keeps it
--   4. the stall: the counter says SHOP, not SELL
--
-- Not here, seen in Play instead: the notice on screen.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local TutorialData = require(Shared:WaitForChild("TutorialData"))
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

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
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

-- A guide whose first loop is done, and one that has not started.
local function guide(done)
	local p = { Version = TutorialData.Version, Done = {}, Skipped = false, PodGrants = 0 }
	if done then
		for _, step in ipairs(TutorialData.Steps) do
			p.Done[step.Id] = true
		end
	end
	return p
end

--==============================================================================
-- Load the real service with its siblings stood in.
--==============================================================================
local module = Server:WaitForChild("BatHintService")
local profiles, ready, marked, told = {}, {}, {}, {}
local fakePlayers = {}
local function fakePlayer(name, attrs)
	local p = { Name = name, Parent = fakePlayers, _attrs = attrs or {} }
	function p:GetAttribute(k)
		return self._attrs[k]
	end
	return p
end
local PlayerDataService = {
	IsReady = function(player)
		return ready[player] == true
	end,
	Get = function(player)
		return profiles[player]
	end,
	MarkBatHintShown = function(player)
		local profile = profiles[player]
		if not profile or profile.BatHintShown == true then
			return false
		end
		profile.BatHintShown = true
		table.insert(marked, player.Name)
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
local parent = {}
function parent:WaitForChild(name)
	assert(name == "PlayerDataService", "unexpected sibling " .. name)
	return { __standIn = PlayerDataService }
end
local outerRequire = require
local chunk = assert(loadstring(module.Source, "=BatHintService"))
setfenv(chunk, setmetatable({
	game = fakeGame,
	script = { Name = "BatHintService", Parent = parent },
	require = function(target)
		if type(target) == "table" and target.__standIn ~= nil then
			return target.__standIn
		end
		return outerRequire(target)
	end,
}, { __index = getfenv(1) }))
local Hint = chunk()
Hint.Init()
Hint.SpecTell(function(player, payload)
	table.insert(told, { player = player.Name, payload = payload })
end)

local CHASED = "PursuedBy"

--==============================================================================
say("1. The rules")
--==============================================================================
check(not Hint.ownsBat({ Weapons = {} }) and Hint.ownsBat({ Weapons = { rootwood_bat = true } }),
	"no weapons: no bat; the Rootwood Bat: a bat")
check(not Hint.ownsBat({ Weapons = { bramblejaw_trap = true } }) and not Hint.ownsBat({ Weapons = { nosuch = true } })
		and not Hint.ownsBat(nil), "a trap alone, an unknown id, no profile: no bat")
local fresh = { Weapons = {}, BatHintShown = false, Tutorial = guide(true) }
check(Hint.due(fresh, 1), "chased, no bat, never told, past the guide's first loop: told")
check(not Hint.due(fresh, 0), "not chased: not told")
check(not Hint.due({ Weapons = {}, BatHintShown = true, Tutorial = guide(true) }, 1), "told before: never again")
check(not Hint.due({ Weapons = { rootwood_bat = true }, BatHintShown = false, Tutorial = guide(true) }, 1), "owns a bat: not told")
check(not Hint.due({ Weapons = {}, BatHintShown = false, Tutorial = guide(false) }, 1),
	"in the guide's first loop: not told (the guide's own raid)")
local skipped = guide(false)
skipped.Skipped = true
check(Hint.due({ Weapons = {}, BatHintShown = false, Tutorial = skipped }, 1), "the guide skipped: told")

--==============================================================================
say("2. The real service")
--==============================================================================
local a = fakePlayer("Ana", { [CHASED] = 1 })
profiles[a] = { Weapons = {}, BatHintShown = false, Tutorial = guide(true) }
ready[a] = true
check(Hint.Check(a) == true and #told == 1 and told[1].player == "Ana", "the first chase tells once")
local pay = told[1] and told[1].payload or {}
check(pay.title == "NO BAT YET?" and pay.detail == "Buy a bat at Marigold's stall to fight back!" and pay.key == "bathint",
	"in the owner's words: NO BAT YET? / Buy a bat at Marigold's stall to fight back!", pay.detail)
check(marked[1] == "Ana" and profiles[a].BatHintShown == true, "and the flag is saved with it")
check(Hint.Check(a) == false and #told == 1, "a second chase: nothing")
local b = fakePlayer("Ben", { [CHASED] = 2 })
profiles[b] = { Weapons = {}, BatHintShown = false, Tutorial = guide(true) }
ready[b] = false
check(Hint.Check(b) == false and #told == 1, "a profile not loaded yet: nothing (asked again on the next chase)")
local c = fakePlayer("Cai", { [CHASED] = 1 })
profiles[c] = { Weapons = { rootwood_bat = true }, BatHintShown = false, Tutorial = guide(true) }
ready[c] = true
check(Hint.Check(c) == false and #told == 1 and profiles[c].BatHintShown == false, "a bat owner: nothing, and nothing saved")

--==============================================================================
say("3. The save")
--==============================================================================
check(ProfileSchema.Default().BatHintShown == false, "a new profile starts untold")
local old = ProfileSchema.Default()
old.BatHintShown = nil
check(ProfileSchema.Sanitise(old).BatHintShown == false, "an old save with no field: untold")
local toldSave = ProfileSchema.Default()
toldSave.BatHintShown = true
check(ProfileSchema.Sanitise(toldSave).BatHintShown == true, "a told one stays told")
local pds = Server:FindFirstChild("PlayerDataService")
check(pds and has(pds.Source, "BatHintShown = profile.BatHintShown == true,"), "a progress reset keeps it")

--==============================================================================
say("4. The stall")
--==============================================================================
local map = Server:FindFirstChild("MapService")
check(map and has(map.Source, 't.Text = "SHOP"') and not has(map.Source, 't.Text = "SELL"'),
	"Marigold's counter says SHOP, not SELL")

say(string.format("\nBatHintSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
