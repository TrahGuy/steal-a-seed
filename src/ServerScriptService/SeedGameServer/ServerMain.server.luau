--!strict
-- Steal a Seed :: ServerMain
--
-- Requires every "*Service" ModuleScript beside it, runs Init() on all of them,
-- then Start() on all of them, ordered by an optional Priority.
--
-- ADDING A SERVICE IS DROPPING A FILE IN THIS FOLDER. No registry to update, no
-- require list to keep in step, and therefore no way to add a service and
-- forget to start it. That property is why this pattern is worth reproducing
-- verbatim from the previous project.
--
--==============================================================================
-- TWO PHASES, BECAUSE OF DEPENDENCY ORDER
--
-- Init() prepares a service's own state and may NOT assume any other service is
-- ready. Start() runs only after every Init() has finished, so by then it may.
-- That is what lets PlotService read the world MapService built without either
-- knowing which loaded first.
--
-- Priority orders services WITHIN a phase. Lower runs earlier.
--
-- EVERY CALL IS pcall'd. One service throwing in Init must not take the others
-- down with it -- a game with a broken shop is recoverable, a game where nobody
-- can spawn is not.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent
if not root then
	warn("[Seed] ServerMain has no parent folder. Aborting.")
	return
end

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

--==============================================================================
-- REMOTES
--
-- Created here, before any service starts, so no service has to WaitForChild on
-- a folder a sibling might create. Every name comes from GameConfig.Remotes --
-- creating one whose name is not in that table is not possible from here, which
-- is the point.
--==============================================================================
local remotes = SeedGame:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = SeedGame
end
for _, remoteName in pairs(GameConfig.Remotes) do
	if not remotes:FindFirstChild(remoteName) then
		local event = Instance.new("RemoteEvent")
		event.Name = remoteName
		event.Parent = remotes
	end
end

--==============================================================================
-- DISCOVER
--==============================================================================
type Entry = { name: string, priority: number, module: any }

local entries: { Entry } = {}

for _, child in ipairs(root:GetChildren()) do
	if child:IsA("ModuleScript") and string.sub(child.Name, -7) == "Service" then
		local ok, result = pcall(require, child)
		if not ok then
			warn(string.format("[Seed] Failed to require %s: %s", child.Name, tostring(result)))
		elseif typeof(result) ~= "table" then
			warn(string.format("[Seed] %s did not return a table. Skipped.", child.Name))
		else
			table.insert(entries, {
				name = child.Name,
				priority = tonumber(result.Priority) or 100,
				module = result,
			})
		end
	end
end

table.sort(entries, function(a: Entry, b: Entry): boolean
	if a.priority == b.priority then
		-- Alphabetical tiebreak, so a boot order that happens to work is at
		-- least the SAME order on every server rather than whatever
		-- GetChildren returned that time.
		return a.name < b.name
	end
	return a.priority < b.priority
end)

local function runPhase(phaseName: string)
	for _, entry in ipairs(entries) do
		local callback = entry.module[phaseName]
		if type(callback) == "function" then
			local started = os.clock()
			local ok, err = pcall(callback)
			if not ok then
				warn(string.format("[Seed] %s.%s() failed: %s", entry.name, phaseName, tostring(err)))
			elseif os.clock() - started > 1 then
				-- A service taking a second in Init is a service delaying every
				-- player's first spawn.
				warn(string.format("[Seed] %s.%s() took %.2fs.",
					entry.name, phaseName, os.clock() - started))
			end
		end
	end
end

runPhase("Init")
runPhase("Start")

--==============================================================================
-- BOOT REPORT
--
-- Says what loaded and, more usefully, what is WRONG. The MaxPlayers check is
-- here because it caught a real failure in a previous project: a 6-plot map on
-- a 60-player place, where nine of every ten joiners got no plot at all. It
-- cannot be fixed from a script -- Players.MaxPlayers is a place setting,
-- editable only in Game Settings -> Places -- so the only thing code can do is
-- refuse to be quiet about it.
--==============================================================================
local order = {}
for _, entry in ipairs(entries) do
	table.insert(order, entry.name)
end

print(string.format("[Seed] %s v%s (Phase %d) online -- %d service(s): %s",
	GameConfig.ProjectName, GameConfig.Version, GameConfig.Phase,
	#entries, #order > 0 and table.concat(order, ", ") or "none"))

if Players.MaxPlayers ~= GameConfig.MaxPlayers then
	warn(string.format(
		"[Seed] Players.MaxPlayers is %d but there are only %d plots. Joiner %d onwards gets " ..
		"no plot. Set it to %d in Game Settings -> Places.",
		Players.MaxPlayers, GameConfig.MaxPlots,
		GameConfig.MaxPlots + 1, GameConfig.MaxPlayers))
end
