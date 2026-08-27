--!strict
-- Steal a Seed :: BiomeGuideUI
--
-- A short advisory banner when the server observes this player entering a
-- non-starter biome. The client receives only a biome id and draws the trusted
-- shared data; it never decides whether entry is allowed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remoteInstance = SeedGame:WaitForChild("Remotes")
	:WaitForChild(GameConfig.Remotes.BiomeRecommendation)
if not remoteInstance:IsA("RemoteEvent") then
	warn("[Seed/BiomeGuideUI] BiomeRecommendation is not a RemoteEvent.")
	return
end
local recommendationRemote = remoteInstance :: RemoteEvent

local existing = playerGui:FindFirstChild("SeedBiomeGuide")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedBiomeGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 45
gui.Parent = playerGui

local HIDDEN = UDim2.new(0.5, 0, 0, -100)
local SHOWN = UDim2.new(0.5, 0, 0, 52)

local plate = Instance.new("Frame")
plate.Name = "Recommendation"
plate.AnchorPoint = Vector2.new(0.5, 0)
plate.Position = HIDDEN
plate.Size = UDim2.new(0.72, 0, 0, 84)
plate.BackgroundColor3 = Color3.new(1, 1, 1)
plate.BorderSizePixel = 0
plate.ClipsDescendants = true
plate.Visible = false
plate.Parent = gui
UIKit.corner(plate, 14)
local plateStroke = UIKit.stroke(plate, Color3.fromRGB(16, 13, 12), 3)
local plateGradient = UIKit.gradient(
	plate,
	Color3.fromRGB(83, 61, 45),
	Color3.fromRGB(35, 29, 30))

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(220, 84)
sizeConstraint.MaxSize = Vector2.new(520, 84)
sizeConstraint.Parent = plate

local stripe = Instance.new("Frame")
stripe.Name = "Accent"
stripe.Size = UDim2.new(0, 9, 1, 0)
stripe.BackgroundColor3 = Color3.fromRGB(255, 204, 70)
stripe.BorderSizePixel = 0
stripe.Parent = plate

local title = UIKit.outlined(plate, "BiomeName", 26, Color3.fromRGB(255, 220, 92), 2.5)
title.Position = UDim2.fromOffset(22, 5)
title.Size = UDim2.new(1, -34, 0, 34)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left

local titleCap = Instance.new("UITextSizeConstraint")
titleCap.MinTextSize = 16
titleCap.MaxTextSize = 28
titleCap.Parent = title

local recommendation = UIKit.outlined(plate, "RecommendedSpeed", 21,
	Color3.fromRGB(255, 255, 255), 2)
recommendation.Position = UDim2.fromOffset(22, 39)
recommendation.Size = UDim2.new(1, -34, 0, 25)
recommendation.TextScaled = true
recommendation.TextXAlignment = Enum.TextXAlignment.Left

local recommendationCap = Instance.new("UITextSizeConstraint")
recommendationCap.MinTextSize = 13
recommendationCap.MaxTextSize = 22
recommendationCap.Parent = recommendation

local note = Instance.new("TextLabel")
note.Name = "AccessNote"
note.Position = UDim2.fromOffset(22, 65)
note.Size = UDim2.new(1, -34, 0, 14)
note.BackgroundTransparency = 1
note.Font = Enum.Font.GothamBold
note.Text = "ADVISORY ONLY  •  EVERYONE MAY ENTER"
note.TextColor3 = Color3.fromRGB(234, 232, 226)
note.TextScaled = true
note.TextXAlignment = Enum.TextXAlignment.Left
note.Parent = plate

local noteCap = Instance.new("UITextSizeConstraint")
noteCap.MinTextSize = 9
noteCap.MaxTextSize = 12
noteCap.Parent = note

local animationToken = 0
local activeTween: Tween? = nil

local function playTween(position: UDim2, seconds: number, style: Enum.EasingStyle,
	direction: Enum.EasingDirection): Tween
	if activeTween then
		activeTween:Cancel()
	end
	local tween = TweenService:Create(
		plate,
		TweenInfo.new(seconds, style, direction),
		{ Position = position })
	activeTween = tween
	tween:Play()
	return tween
end

local function showBiome(biomeId: string)
	local biome = BiomeData.ById[biomeId]
	if not biome or biome.RecommendedSpeed <= 0 then
		return
	end

	animationToken += 1
	local token = animationToken
	title.Text = string.upper(biome.DisplayName) .. "  " .. biome.Mood
	recommendation.Text = "RECOMMENDED SPEED  "
		.. GameConfig.compact(biome.RecommendedSpeed)
	stripe.BackgroundColor3 = biome.AccentColor
	plateStroke.Color = Color3.fromRGB(16, 13, 12)
	plateGradient.Color = ColorSequence.new(
		biome.WallColor:Lerp(Color3.new(0, 0, 0), 0.18),
		biome.WallColor:Lerp(Color3.new(0, 0, 0), 0.62))

	plate.Position = HIDDEN
	plate.Visible = true
	playTween(SHOWN, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	task.delay(3.4, function()
		if token ~= animationToken then
			return
		end
		local tween = playTween(HIDDEN, 0.28, Enum.EasingStyle.Quad,
			Enum.EasingDirection.In)
		tween.Completed:Once(function()
			if token == animationToken then
				plate.Visible = false
				activeTween = nil
			end
		end)
	end)
end

recommendationRemote.OnClientEvent:Connect(function(biomeId: unknown)
	if type(biomeId) ~= "string" then
		return
	end
	showBiome(biomeId)
end)
