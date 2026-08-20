--!strict
-- Steal an Artifact :: MainHUD
--
-- The top-left readout: coins, artifacts, level. Exactly the three lines the
-- blueprint asks for and nothing else -- Phase 2 adds the carry card, Phase 4
-- the upgrade panel, and each of those is its own file.
--
--==============================================================================
-- THE HUD IS A MIRROR, NEVER A SOURCE
--
-- It draws what ProfileUpdated tells it and computes no totals of its own. A
-- client that adds coins locally "so it feels responsive" is a client that
-- disagrees with the server the first time a payout is refused -- and then the
-- player believes the wrong number.
--
-- BUILT IN CODE, not placed in StarterGui as a saved ScreenGui, for the same
-- reason the map is: an instance placed by hand lives only in the .rbxl.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ArtifactGame = ReplicatedStorage:WaitForChild("ArtifactGame")
local Shared = ArtifactGame:WaitForChild("Shared")
local Remotes = ArtifactGame:WaitForChild("Remotes")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ArtifactData = require(Shared:WaitForChild("ArtifactData"))

local INK = Color3.fromRGB(28, 24, 38)
local CREAM = Color3.fromRGB(252, 250, 244)
local GOLD = Color3.fromRGB(255, 205, 74)

--==============================================================================
-- CHROME
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ArtifactHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "Readout"
card.AnchorPoint = Vector2.new(0, 0)
card.Position = UDim2.fromOffset(14, 14)
card.Size = UDim2.fromOffset(224, 108)
card.BackgroundColor3 = CREAM
card.BorderSizePixel = 0
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = INK
stroke.Transparency = 0.15
stroke.Parent = card

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = card

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)
layout.Parent = card

-- ONE UIScale, driven off the viewport. A phone at 400px wide and a monitor at
-- 2560 are not the same screen, and a HUD authored for one is unreadable or
-- absurd on the other.
local scale = Instance.new("UIScale")
scale.Parent = card

local function fitToViewport()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local width = camera.ViewportSize.X
	scale.Scale = math.clamp(width / 1280, 0.85, 1.25)
end

local function row(name: string, order: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 26)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = ""
	label.Parent = card

	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 22
	cap.Parent = label
	return label
end

local coinsLabel = row("Coins", 1, GOLD)
local artifactsLabel = row("Artifacts", 2, INK)
local levelLabel = row("Level", 3, INK)

--==============================================================================
-- FORMATTING
--
-- A Secret artifact is worth 5,000,000 and a player will hold tens of millions,
-- so the readout has to survive eight digits in a 224px card. Below a million it
-- reads exactly, because "you have 12,400 coins" and "you have 12.4k coins" are
-- different promises when something costs 12,500.
--==============================================================================
local function comma(n: number): string
	local text = tostring(math.floor(n))
	local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function short(n: number): string
	if n < 1e6 then
		return comma(n)
	elseif n < 1e9 then
		return string.format("%.2fM", n / 1e6)
	end
	return string.format("%.2fB", n / 1e9)
end

--==============================================================================
-- STATE
--==============================================================================
local shown = { coins = 0, artifacts = 0, level = 1, experience = 0 }

local function paint()
	coinsLabel.Text = "$ " .. short(shown.coins)
	artifactsLabel.Text = "Artifacts: " .. comma(shown.artifacts)

	local needed = ArtifactData.Economy.ExperiencePerLevel * shown.level
	levelLabel.Text = string.format("Level %d  (%s/%s)",
		shown.level, comma(shown.experience), comma(needed))
end

-- A coin gain should be felt. One pulse on the label rather than a counter
-- animation: a rolling number is unreadable at exactly the moment the player
-- wants to read it.
local function pulse(label: TextLabel)
	label.TextTransparency = 0.45
	TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
end

local profileUpdated = Remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 30)
if profileUpdated and profileUpdated:IsA("RemoteEvent") then
	profileUpdated.OnClientEvent:Connect(function(view)
		if type(view) ~= "table" then
			return
		end
		local gainedCoins = (tonumber(view.coins) or 0) > shown.coins
		shown.coins = tonumber(view.coins) or shown.coins
		shown.artifacts = tonumber(view.artifactsCollected) or shown.artifacts
		shown.level = tonumber(view.level) or shown.level
		shown.experience = tonumber(view.experience) or shown.experience
		paint()
		if gainedCoins then
			pulse(coinsLabel)
		end
	end)
else
	warn("[Artifact/MainHUD] ProfileUpdated remote never appeared. The readout will stay at zero.")
end

--==============================================================================
-- BASE ASSIGNMENT
--
-- Phase 1 has no objective text yet, so this only logs. It is connected now so
-- that the remote has a consumer and a missing assignment shows up as a silent
-- log rather than as a player wondering why nothing happened.
--==============================================================================
local baseAssigned = Remotes:WaitForChild(GameConfig.Remotes.BaseAssigned, 30)
if baseAssigned and baseAssigned:IsA("RemoteEvent") then
	baseAssigned.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and payload.baseId then
			print(string.format("[Artifact/MainHUD] You own Base_%02d.", payload.baseId))
		end
	end)
end

paint()
fitToViewport()
local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToViewport)
end
