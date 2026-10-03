--!strict
-- Steal a Seed :: WeatherUI
--
-- The Rain event's one HUD line (2026-10-02): "+25% INCOME · 2:59" -- a small
-- transparent StatusText line just over the hotbar's name band, in HudLayout's
-- `rain` rect, which exists only while the rain pays and which the toast line
-- steps up over. It reads WeatherService's attributes and nothing else, ticks
-- once a second while it shows, and does no per-frame work. Smaller on a
-- phone and in a small window, at the boost row's own scales.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local W = GameConfig.Weather
local ATTR = W.Attributes
local RAIN_INK = Color3.fromRGB(150, 196, 255)

local stale = playerGui:FindFirstChild("SeedWeatherUI")
if stale then
	stale:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "SeedWeatherUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 21
gui.Parent = playerGui
UIKit.tenFoot(gui)

local line = StatusText.new({
	name = "Rain",
	parent = gui,
	size = StatusText.Size.boost,
	tint = RAIN_INK,
	icon = "boost",
	detailSize = StatusText.Size.boostClock,
	detailFont = StatusText.ClockFont,
})
local head = string.format(W.Chip.Text, math.round((SeedData.Rain.IncomeFactor - 1) * 100)) .. " ·"

local function paying(): boolean
	local state = Workspace:GetAttribute(ATTR.State)
	return state == "opening" or state == "active"
end

local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local layout = HudLayout.solve(input)
	local phone = layout.sidebar and layout.columnTop ~= nil
	local k = if phone then StatusText.PhoneScale.boost
		elseif layout.compact or layout.sidebar then StatusText.SmallScale.boost
		else 1
	line.setScale(k)
	local r = layout.rain
	if not r then
		return
	end
	local s = line.size()
	line.frame.Position = UDim2.new(0.5, math.round(r.x + r.w / 2 - layout.safe.X / 2),
		0, math.round(r.y + (r.h - s.Y) / 2))
end

local function draw()
	if not paying() then
		line.hide(false)
		return
	end
	local endsAt = tonumber(Workspace:GetAttribute(ATTR.EndsAt)) or 0
	line.set(head, StatusText.clock(math.max(0, endsAt - Workspace:GetServerTimeNow())))
	if not line.isShown() then
		line.show()
	end
	place()
end

local ticker = 0
local function tick(want: boolean)
	ticker += 1
	if not want then
		return
	end
	local mine = ticker
	local function beat()
		if mine ~= ticker then
			return
		end
		draw()
		task.delay(1, beat)
	end
	beat()
end

local function onState()
	local on = paying()
	tick(on)
	if not on then
		line.hide(false)
	end
end
Workspace:GetAttributeChangedSignal(ATTR.State):Connect(onState)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
onState()
