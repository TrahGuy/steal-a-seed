--!strict
-- Steal a Seed :: GuardianLabelUI
--
-- "POD LEFT BEHIND!" over a guardian, briefly, when its catch did not take a
-- secret pod (2026-10-01). The server says so by writing `LeftBehindAt` (its
-- clock) on the parent model; every client that sees the guardian draws the
-- words above its head for GameConfig.Secret.LeftBehind.Seconds. Outlined text,
-- no panel; it pops in unless the player asked for reduced motion.
--
-- It describes the POD. The thief is not forgotten: NestService keeps chasing.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))

local TAG = GameConfig.Tags.NestParent
local ATTRIBUTE = "LeftBehindAt"
local TEXT = GameConfig.Secret.LeftBehind.Text
local SECONDS = GameConfig.Secret.LeftBehind.Seconds
local OUTLINE = Color3.fromRGB(12, 10, 16)

local watched: { [Model]: RBXScriptConnection } = {}
local showing: { [Model]: BillboardGui } = {}

local function headOf(model: Model): BasePart?
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	return model.PrimaryPart
end

local function show(model: Model)
	local head = headOf(model)
	if not head then
		return
	end
	local old = showing[model]
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "LeftBehind"
	gui.Adornee = head
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(260, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y * 0.5 + 4, 0)
	gui.MaxDistance = 180
	gui.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Text = TEXT
	label.TextColor3 = Color3.fromRGB(255, 232, 120)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 2.5
	stroke.Parent = label
	local scale = Instance.new("UIScale")
	scale.Parent = label
	gui.Parent = head
	showing[model] = gui
	if StatusText.reducedMotion() then
		scale.Scale = 1
	else
		scale.Scale = 0.6
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	task.delay(SECONDS, function()
		if showing[model] ~= gui then
			return
		end
		showing[model] = nil
		local fade = TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1 })
		TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		fade:Play()
		fade.Completed:Wait()
		gui:Destroy()
	end)
end

local function watch(model: Instance)
	if not model:IsA("Model") or watched[model] then
		return
	end
	watched[model] = model:GetAttributeChangedSignal(ATTRIBUTE):Connect(function()
		if model:GetAttribute(ATTRIBUTE) ~= nil then
			show(model)
		end
	end)
end

local function forget(model: Instance)
	local c = watched[model :: any]
	if c then
		c:Disconnect()
		watched[model :: any] = nil
	end
end

for _, model in ipairs(CollectionService:GetTagged(TAG)) do
	watch(model)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(watch)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(forget)
