--[[
	Steal a Seed :: map builder plugin

	Adds a "Build Map" button to the Studio toolbar.

	WHY THIS EXISTS
		The map is built at runtime by MapService and is never saved into the
		place -- that is the project's core rule, and it is why the map is
		diffable in git and identical on every server.

		The cost is that the Edit workspace is always empty, and it gets emptier:
		stopping Play discards everything Play created, so the map a server just
		built goes with it. Correct, and confusing three times running.

		The documented fix was a line to paste into the command bar. A line you
		have to remember is a line you will not remember, so it is a button now.

	INSTALL
		Copy to %LOCALAPPDATA%\Roblox\Plugins\ and restart Studio.

	This file is source. The installed copy is a build artefact.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Selection = game:GetService("Selection")

local FOLDER = "SeedGameServer"
local MAP_FOLDER = "SeedMap"

local toolbar = plugin:CreateToolbar("Steal a Seed")

local function serverFolder()
	return ServerScriptService:FindFirstChild(FOLDER)
end

local function moduleIn(name)
	local folder = serverFolder()
	if not folder then
		return nil, string.format(
			"ServerScriptService.%s is missing. Is Rojo connected on port 34872?", FOLDER)
	end
	local module = folder:FindFirstChild(name)
	if not module or not module:IsA("ModuleScript") then
		return nil, string.format("%s.%s is missing.", FOLDER, name)
	end
	return module, nil
end

local function clearMap()
	local existing = workspace:FindFirstChild(MAP_FOLDER)
	if existing then
		existing:Destroy()
		return true
	end
	return false
end

--==============================================================================
-- BUILD
--==============================================================================
local buildButton = toolbar:CreateButton(
	"Build Map",
	-- No icon. The rbxasset paths guessed for these do not exist and Studio
	-- warns about it on every single load; a text button is better than a
	-- broken one plus a log line.
	"Rebuild the runtime map in Edit, exactly as a server would on boot",
	"")

buildButton.Click:Connect(function()
	buildButton:SetActive(false)

	local module, err = moduleIn("MapService")
	if not module then
		warn("[SeedMapBuilder] " .. err)
		return
	end

	local ok, result = pcall(function()
		return require(module)
	end)
	if not ok then
		warn("[SeedMapBuilder] MapService failed to load: " .. tostring(result))
		return
	end

	local started = os.clock()
	local built, buildErr = pcall(result.Init)
	if not built then
		warn("[SeedMapBuilder] MapService.Init() failed: " .. tostring(buildErr))
		return
	end

	local map = workspace:FindFirstChild(MAP_FOLDER)
	local parts = 0
	if map then
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		-- Belt and braces. MapService sets this itself; setting it here too means
		-- a map built by an OLDER MapService still cannot be saved into the
		-- place, which is the one thing that must never happen.
		map.Archivable = false
	end

	print(string.format(
		"[SeedMapBuilder] Built %s: %d parts in %.2fs. Archivable=false, so it cannot be saved.",
		MAP_FOLDER, parts, os.clock() - started))

	-- NESTS ARE NOT BUILT. NestService starts a tick loop and raises Humanoids
	-- that would walk around an Edit session forever with nothing to chase.
	-- Press Play for those.
end)

--==============================================================================
-- CLEAR
--==============================================================================
local clearButton = toolbar:CreateButton(
	"Clear Map",
	"Remove the map from the Edit workspace",
	"")

clearButton.Click:Connect(function()
	clearButton:SetActive(false)
	if clearMap() then
		print("[SeedMapBuilder] Cleared " .. MAP_FOLDER .. ".")
	else
		print("[SeedMapBuilder] Nothing to clear -- the workspace has no " .. MAP_FOLDER .. ".")
	end
end)
