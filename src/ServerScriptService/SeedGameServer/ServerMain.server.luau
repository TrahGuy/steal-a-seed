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

--==============================================================================
-- WHAT THE WEIGHT CURVE ACTUALLY DOES
--
-- Every pod rolls its own weight now, 1 to 10,000 kg, on one curve shared by
-- all five species. That curve IS the economy -- one exponent decides how often
-- anybody ever sees a heavy pod -- and it is exactly the kind of number that
-- drifts silently: nothing in the game would look broken if it quietly went
-- uniform and every nest started handing out five-figure creatures.
--
-- So it is measured at boot, over ten thousand real rolls, and printed. Read it
-- as: most pods are pocket change and a Divine one is a story. If 10,000 has
-- become common, or nothing exceeds 100, move SeedData's KG_CURVE. Do not
-- flatten it.
--
-- The heights underneath are the other half of the same claim -- that weight is
-- VISIBLE. They are measured off creatures actually BUILT and then thrown away,
-- not recomputed from the formula, so a builder that stopped honouring the
-- weight argument would show up here as four identical numbers rather than in a
-- screenshot three days later.
--==============================================================================
local ServerStorage = game:GetService("ServerStorage")

local function weightReport()
	local SeedData = require(Shared:WaitForChild("SeedData"))

	--== THE ROLL ==--
	-- A fixed seed, so two servers print the same histogram and a change in it is
	-- a change in the ODDS rather than in the luck of one boot.
	--
	-- This used to bucket by weight -- 10 kg, 110, 1,000 -- and after the tier
	-- change it was testing "is tier <= 10", which is true of all seven. It
	-- printed 100% in the first bucket and 0% everywhere else, which looks like a
	-- broken roll and was a broken RULER.
	local rng = Random.new(20260824)
	local SAMPLES = 10000
	local seen = {}
	for i = 1, SeedData.TierCount do
		seen[i] = 0
	end
	for _ = 1, SAMPLES do
		seen[SeedData.RollTier(rng)] += 1
	end
	local parts = {}
	for i, t in ipairs(SeedData.Tiers) do
		table.insert(parts, string.format("%s %.2f%%", t.name, seen[i] / SAMPLES * 100))
	end
	print(string.format("[Seed] tier roll, %d samples:  %s",
		SAMPLES, table.concat(parts, "  ")))

	--== THE SIZE ==--
	-- Nubkin and Bellchime specifically: the shortest frame and the tallest, so
	-- the pair brackets every other form. A Nubkin must stay shorter than a
	-- Bellchime at the SAME tier -- the form has to keep reading -- while both
	-- have to grow enormously across the ladder.
	local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
	local stash = Instance.new("Folder")
	stash.Name = "SeedTierCheck"
	stash.Parent = ServerStorage
	for _, id in ipairs({ "nubkin", "bellchime" }) do
		local species = SeedData.Get(id)
		if species then
			local cells = {}
			for _, tier in ipairs({ 1, 4, 7 }) do
				-- Built at the origin, so the base sits on y = 0 and the tallest
				-- corner of any part IS the finished height.
				local model = CreatureModel.BuildCreature(species, tier,
					CreatureModel.STAGE_GROWN, CFrame.new(), stash)
				local top = 0
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("BasePart") then
						local cf, size = d.CFrame, d.Size
						top = math.max(top, cf.Position.Y
							+ math.abs(cf.UpVector.Y) * size.Y * 0.5
							+ math.abs(cf.RightVector.Y) * size.X * 0.5
							+ math.abs(cf.LookVector.Y) * size.Z * 0.5)
					end
				end
				model:Destroy()
				table.insert(cells, string.format("%s %.1f", SeedData.TierName(tier), top))
			end
			print(string.format("[Seed] %-9s finished height:  %s",
				species.Name, table.concat(cells, "   |   ")))
		end
	end
	stash:Destroy()
end

-- pcall, because a boot report is a convenience and a server that cannot print
-- one is still a server people can play on.
local reported, reportErr = pcall(weightReport)
if not reported then
	warn("[Seed] weight report failed: " .. tostring(reportErr))
end
