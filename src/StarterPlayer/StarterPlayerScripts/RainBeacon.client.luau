--!strict
-- Steal a Seed :: RainBeacon (client)
--
-- The rain biome's beacon on this screen (2026-10-11, the owner's item 8;
-- Shared/RainBeacon, GameConfig.Weather.Beacon): while the biome is open (the
-- Weather State attribute "active") a tall, soft rain-blue column of light
-- stands over the bridge, built here for this client alone -- the server holds
-- no part of it, and nothing collides with it, finds it or touches it. A
-- player who joins while it is open sees it at once; otherwise it fades in and
-- out. Reduced FX (StatusText.reducedMotion, the game's one setting for both)
-- keeps it still and narrower, never gone.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local RainBeacon = require(Shared:WaitForChild("RainBeacon"))

local player = Players.LocalPlayer
local STATE = GameConfig.Weather.Attributes.State

-- A re-run of this script (Rojo in Play) hands the old copy's work over.
local playerScripts = player:WaitForChild("PlayerScripts")
local previous = playerScripts:FindFirstChild("RainBeaconCleanup")
if previous and previous:IsA("BindableEvent") then
	previous:Fire()
	previous:Destroy()
end
local cleanupEvent = Instance.new("BindableEvent")
cleanupEvent.Name = "RainBeaconCleanup"
cleanupEvent.Parent = playerScripts

local beacon: Model? = nil
-- A late joiner: at full at once.
local level = if RainBeacon.Shown(Workspace:GetAttribute(STATE)) then 1 else 0

local function step(dt: number)
	level = RainBeacon.Step(level, RainBeacon.Shown(Workspace:GetAttribute(STATE)), dt)
	if level > 0 and not beacon then
		beacon = RainBeacon.Build(Workspace)
	end
	local current = beacon
	if current then
		if level <= 0 then
			current:Destroy()
			beacon = nil
		else
			RainBeacon.Apply(current, level, os.clock(), StatusText.reducedMotion())
		end
	end
end

step(0)
local connection = RunService.Heartbeat:Connect(step)

local function cleanup()
	connection:Disconnect()
	local current = beacon
	if current then
		current:Destroy()
		beacon = nil
	end
	cleanupEvent:Destroy()
end
cleanupEvent.Event:Connect(cleanup)
script.Destroying:Connect(cleanup)
