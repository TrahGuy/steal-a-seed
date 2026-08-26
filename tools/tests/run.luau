--!nocheck
-- Steal a Seed :: test runner
--
-- Runs a spec out of tools/tests/ against the CURRENT source on disk.
--
--==============================================================================
-- WHY THIS EXISTS AT ALL: STUDIO CACHES require()
--
-- A ModuleScript is evaluated ONCE per datamodel and the result is cached
-- forever. Rojo patches Source in place, so the instance is never replaced and
-- the cache is never invalidated -- which means that in an Edit session that has
-- ever required GameConfig, every later require returns the version from before
-- your edits, silently, with no warning and no way to tell from the value.
--
-- That is not a hypothetical: the first run of SpeedSpec died on
-- `ipairs(GameConfig.Speed.Anchors)` with "table expected, got nil" against a
-- file that plainly had the table in it, and the synced Source proved the sync
-- had worked. An hour of that is an hour spent debugging a cache.
--
-- Restarting Studio clears it. So does this, and this takes no seconds.
--
--==============================================================================
-- HOW
--
-- loadstring the module's own Source and give the chunk an environment where
-- `script` is the real instance and `require` is THIS function -- so the whole
-- dependency tree loads fresh, in order, with the tree's own relative paths
-- (`script.Parent:WaitForChild("X")`) resolving exactly as they normally do.
--
-- Memoised per run, because a module required twice must be the same table --
-- that is what require MEANS, and a spec that got two different GameConfigs
-- would be testing something no player will ever run.
--
--==============================================================================
-- RUN IT
--
--   python -m http.server 8731            (from the repo root)
--
--   -- Studio command bar, Edit mode (loadstring is disabled at runtime):
--   local run = loadstring(game:GetService("HttpService"):GetAsync(
--       "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--   print(run("SpeedSpec"))
--
-- EDIT MODE IS ENOUGH and is the point: no Play session, no map build, no
-- services starting, no DataStore. Anything that needs a live game is checked in
-- a playtest instead, and says so in the spec.
--==============================================================================

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BASE = "http://127.0.0.1:8731/"

return function(specName: string, base: string?)
	local root = base or BASE
	local cache: { [Instance]: any } = {}
	local loading: { [Instance]: boolean } = {}
	local freshRequire

	freshRequire = function(target: any): any
		if typeof(target) ~= "Instance" or not target:IsA("ModuleScript") then
			-- Not ours to fake. A spec that requires a service or a path outside
			-- the tree gets the real thing.
			return require(target)
		end
		if cache[target] ~= nil then
			return cache[target]
		end
		assert(not loading[target],
			"circular require through " .. target:GetFullName())
		loading[target] = true

		local chunk, err = loadstring(target.Source, "=" .. target.Name)
		assert(chunk, target:GetFullName() .. ": " .. tostring(err))

		local env = { script = target, require = freshRequire }
		setmetatable(env, { __index = getfenv(1) })
		setfenv(chunk, env)

		local value = chunk()
		loading[target] = nil
		cache[target] = value
		return value
	end

	--==========================================================================
	-- A SANITY CHECK ON THE CACHE ITSELF
	--
	-- If the fresh copy and the cached copy disagree about something the spec is
	-- about to assert on, the run is worth nothing and this is the only moment
	-- anybody would notice.
	--==========================================================================
	local fresh = freshRequire(ReplicatedStorage.SeedGame.Shared.GameConfig)
	local cached = require(ReplicatedStorage.SeedGame.Shared.GameConfig)
	local note = ""
	if fresh ~= cached and rawequal(fresh.Speed.Anchors, nil) ~= rawequal(cached.Speed.Anchors, nil) then
		note = "\n(studio's require cache was stale; the spec ran against disk)\n"
	end
	-- Referenced so the compiler cannot decide the comparison above is dead.
	local _ = ServerScriptService

	local source = HttpService:GetAsync(root .. "tools/tests/" .. specName .. ".luau", true)
	local chunk, err = loadstring(source, "=" .. specName)
	assert(chunk, specName .. ": " .. tostring(err))
	local env = { require = freshRequire }
	setmetatable(env, { __index = getfenv(1) })
	setfenv(chunk, env)
	return note .. chunk()
end
