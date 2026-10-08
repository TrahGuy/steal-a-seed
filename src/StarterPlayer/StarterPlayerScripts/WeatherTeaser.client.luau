--!strict
-- One 15 Hz cosmetic player for the world screen. No video decoding, per-frame
-- network traffic or instance creation, or gameplay. Streaming is retryable.
-- The screen's pictures are preloaded once when it binds, so the picture that
-- waits clear under the other is ready before its first fade.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("SeedGame"):WaitForChild("Shared")
local Teaser = require(Shared:WaitForChild("WeatherTeaser"))
local Config = require(Shared:WaitForChild("GameConfig"))
local player = Players.LocalPlayer
local owner = player:WaitForChild("PlayerScripts")
local previous = owner:FindFirstChild("WeatherTeaserCleanup")
if previous and previous:IsA("BindableEvent") then previous:Fire(); previous:Destroy() end
local cleanupEvent = Instance.new("BindableEvent")
cleanupEvent.Name = "WeatherTeaserCleanup"
cleanupEvent.Parent = owner

type Record = { state: Teaser.ScreenState?, pending: RBXScriptConnection?, paused: boolean?, preloaded: boolean? }
local records: { [Model]: Record } = {}
local connections: { RBXScriptConnection } = {}
local stopped = false
local function forget(model: Model)
	local record = records[model]
	if record and record.pending then record.pending:Disconnect() end
	records[model] = nil
end
local function track(instance: Instance)
	if not instance:IsA("Model") or records[instance] then return end
	local model = instance
	local record: Record = { state = nil, pending = nil, paused = nil, preloaded = nil }
	records[model] = record
	local function bind()
		local state = Teaser.Bind(model)
		record.state = state
		if state and record.pending then record.pending:Disconnect(); record.pending = nil end
		if state and not record.preloaded then
			record.preloaded = true
			local pictures = Teaser.Pictures(state)
			task.spawn(function()
				pcall(function() ContentProvider:PreloadAsync(pictures) end)
			end)
		end
	end
	record.pending = model.DescendantAdded:Connect(bind)
	bind()
end
local function cleanup()
	if stopped then return end
	stopped = true
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for model in pairs(records) do forget(model) end
	cleanupEvent:Destroy()
end
table.insert(connections, cleanupEvent.Event:Connect(cleanup))
table.insert(connections, script.Destroying:Connect(cleanup))
table.insert(connections, CollectionService:GetInstanceAddedSignal(Teaser.Tag):Connect(track))
table.insert(connections, CollectionService:GetInstanceRemovedSignal(Teaser.Tag):Connect(function(instance)
	if instance:IsA("Model") then forget(instance) end
end))
for _, model in ipairs(CollectionService:GetTagged(Teaser.Tag)) do track(model) end

local elapsed = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < Teaser.Interval then return end
	elapsed = 0
	local camera = workspace.CurrentCamera
	if not camera then return end
	local reduced = player:GetAttribute(Config.Afterimage.QualityAttribute) == "Off"
	for _, record in pairs(records) do
		local state = record.state
		if not state or not state.screen:IsDescendantOf(workspace) then continue end
		local offset = camera.CFrame.Position - state.screen.Position
		local visible = offset.Magnitude <= Teaser.Reach and state.screen.CFrame.LookVector:Dot(offset) > 0
		if not visible then continue end
		local _, onScreen = camera:WorldToViewportPoint(state.screen.Position)
		if not onScreen then continue end
		if reduced and record.paused == true then continue end
		Teaser.Paint(state, workspace:GetServerTimeNow(), reduced)
		record.paused = reduced
	end
end))
