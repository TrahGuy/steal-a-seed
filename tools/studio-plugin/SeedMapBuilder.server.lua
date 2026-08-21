--[[
	Steal a Seed :: map builder plugin

	Keeps the map present in the Edit workspace, and rebuilds it automatically
	the moment you stop a test.

	WHY THIS EXISTS
		The map is built at runtime by MapService and is never saved into the
		place. That is the project's core rule -- it is why the map is diffable
		in git, identical on every server, and survives losing the place file.

		Two consequences combine into something that looks like a fault:
		the Edit workspace has never contained the map, and stopping Play
		discards everything Play created, so the map a server just built goes
		with it. Correct, and confusing every single time.

		A manual button was the first fix and it was not enough: a button you
		have to press is a button you will forget. Plugins run in the EDIT
		datamodel, which suspends during Play and resumes on Stop -- so this
		notices the map is missing and puts it back, with no input at all.

	WHAT IT DOES NOT DO
		It never makes the map savable. MapService marks the folder
		Archivable = false and this sets it again, so a map built by an older
		MapService still cannot end up in the .rbxl.

		It does not build nests. NestService starts a tick loop and raises
		Humanoids that would wander an Edit session forever with nothing to
		chase, which is a worse problem than an empty plot. Press Play for those.

	INSTALL
		Copy to %LOCALAPPDATA%\Roblox\Plugins\ and restart Studio.
		This file is the source; the installed copy is a build artefact.
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local FOLDER = "SeedGameServer"
local MAP_FOLDER = "SeedMap"
local SETTING = "SeedAutoRebuild"
local POLL_SECONDS = 1

local toolbar = plugin:CreateToolbar("Steal a Seed")

-- Defaults ON, and remembered between sessions. The whole point is not having
-- to think about it.
local autoRebuild = plugin:GetSetting(SETTING)
if autoRebuild == nil then
	autoRebuild = true
end

local function mapService()
	local folder = ServerScriptService:FindFirstChild(FOLDER)
	if not folder then
		return nil, string.format(
			"ServerScriptService.%s is missing. Is Rojo connected on port 34872?", FOLDER)
	end
	local module = folder:FindFirstChild("MapService")
	if not module or not module:IsA("ModuleScript") then
		return nil, FOLDER .. ".MapService is missing."
	end
	local ok, result = pcall(require, module)
	if not ok then
		return nil, "MapService failed to load: " .. tostring(result)
	end
	return result, nil
end

local function buildMap(quiet: boolean?): boolean
	local service, err = mapService()
	if not service then
		if not quiet then
			warn("[SeedMapBuilder] " .. tostring(err))
		end
		return false
	end

	local started = os.clock()
	local ok, buildErr = pcall(service.Init)
	if not ok then
		warn("[SeedMapBuilder] MapService.Init() failed: " .. tostring(buildErr))
		return false
	end

	local map = workspace:FindFirstChild(MAP_FOLDER)
	local parts = 0
	if map then
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		-- Belt and braces. MapService sets this itself; setting it again means a
		-- map built by an OLDER MapService still cannot be saved into the place,
		-- which is the one thing that must never happen.
		map.Archivable = false
	end
	print(string.format("[SeedMapBuilder] Built %s: %d parts in %.2fs. Archivable=false.",
		MAP_FOLDER, parts, os.clock() - started))
	return true
end

--==============================================================================
-- BUTTONS
--==============================================================================
local buildButton = toolbar:CreateButton(
	"Build Map",
	"Rebuild the runtime map in Edit, exactly as a server would on boot",
	"")

buildButton.Click:Connect(function()
	buildButton:SetActive(false)
	buildMap()
end)

local clearButton = toolbar:CreateButton(
	"Clear Map",
	"Remove the map from the Edit workspace, and stop rebuilding it",
	"")

clearButton.Click:Connect(function()
	clearButton:SetActive(false)
	local existing = workspace:FindFirstChild(MAP_FOLDER)
	if existing then
		existing:Destroy()
	end
	-- Clearing has to STICK. With auto-rebuild on, the map would reappear within
	-- a second and the button would look broken -- so clearing turns it off, and
	-- says so rather than silently changing a setting.
	autoRebuild = false
	plugin:SetSetting(SETTING, false)
	print("[SeedMapBuilder] Cleared " .. MAP_FOLDER
		.. ", and auto-rebuild is now OFF. Use Build Map to turn it back on.")
end)

--==============================================================================
-- AUTO REBUILD
--
-- Plugins run in the Edit datamodel, which is suspended for the duration of a
-- Play session and resumes when it ends. So this loop simply does not run while
-- testing, and the first tick after Stop is what puts the map back.
--==============================================================================
buildButton.Click:Connect(function()
	if not autoRebuild then
		autoRebuild = true
		plugin:SetSetting(SETTING, true)
		print("[SeedMapBuilder] Auto-rebuild is back ON.")
	end
end)

task.spawn(function()
	while true do
		task.wait(POLL_SECONDS)
		if autoRebuild
			and RunService:IsEdit()
			and not workspace:FindFirstChild(MAP_FOLDER)
			and ServerScriptService:FindFirstChild(FOLDER) then
			-- Quiet: a missing MapService here means Rojo is not connected yet,
			-- which is not worth a warning once per second.
			buildMap(true)
		end
	end
end)

print("[SeedMapBuilder] Ready. Auto-rebuild is "
	.. (if autoRebuild then "ON" else "OFF") .. ".")
