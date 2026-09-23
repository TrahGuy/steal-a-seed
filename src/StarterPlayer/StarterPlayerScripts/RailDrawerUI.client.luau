--!strict
-- Steal a Seed :: RailDrawerUI
--
-- On a touch screen: the dock Index, Shop and Settings stand in down the left
-- edge, and the handle that shuts and opens it. Nothing else.
--
--==============================================================================
-- ONE OWNER PER CONTROL, AS EVERYWHERE ON THIS HUD
--
-- The three tiles are still IndexUI's, ShopUI's and SettingsUI's. Each builds,
-- shapes, places and answers its own button, and on a phone parents it into
-- UIKit.railDock -- one shared, transparent frame the size of the rail layer.
-- This script owns that frame's panel, the handle, and the one fact the dock
-- has: OPEN OR SHUT. Shutting slides the frame off the left edge, so the tiles
-- go with it and nobody moves anybody else's button.
--
-- Where it all sits is HudLayout's (THE PHONE'S SIDEBARS), reserved open or
-- shut, so shutting the dock moves nothing else on the HUD. On a desktop and in
-- compact there is no dock: the frame stays put and empty, and this draws
-- nothing.
--
--==============================================================================
-- IT STEPS ASIDE WHILE A CENTRE PANEL IS OPEN
--
-- The rail layer draws above every panel so its buttons stay pressable, and a
-- column of tiles 176 px tall would stand over the left edge of any panel --
-- the Bag's first card, the Shop's first shelf. So while OpenPanel names a
-- panel the dock and its handle are hidden, and they come back as they were,
-- open or shut, when it closes. Walk Mode, Garden and the Bag stay, as they do
-- in compact, and every panel's header already steps clear of them.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local DOCK = HudLayout.Config.Dock
local SLIDE_SECONDS = 0.16

local layer = UIKit.railLayer(playerGui)
local dock = UIKit.railDock(playerGui)

--==============================================================================
-- RE-RUN SAFE
--
-- The layer and the dock frame are shared and outlive this script, so a second
-- copy removes the first copy's panel and handle by name -- wherever they stand
-- -- rather than trusting the first copy to have tidied up.
--==============================================================================
for _, name in ipairs({ "DockPanel", "DockHandle" }) do
	local stale = layer:FindFirstChild(name, true)
	if stale then
		stale:Destroy()
	end
end

--==============================================================================
-- THE PANEL
--
-- Behind the tiles, in the frame that slides: the mockup's slim dark tray, a
-- little of the world showing through, and a thin teal edge. Not Active, so a
-- press between two tiles goes to the world, as a press beside a rail button
-- always has.
--==============================================================================
local panel = Instance.new("Frame")
panel.Name = "DockPanel"
panel.BackgroundColor3 = RAIL.DockFill
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel = 0
panel.Active = false
panel.ZIndex = 0
panel.Visible = false
panel.Parent = dock
UIKit.corner(panel, 14)
UIKit.stroke(panel, RAIL.DockEdge, 1.5, 0.15)

--==============================================================================
-- THE HANDLE
--
-- A 44 x 44 press -- the touch floor -- with the tab drawn 18 x 34 at its left
-- edge: on the dock's edge, level with the Shop tile, while the dock is open;
-- on the safe area's edge while it is shut. It reaches right from there and
-- never back over a tile, so it cannot steal the Shop's press. In the layer,
-- not in the frame, so it stays when the frame slides away.
--==============================================================================
local handle = Instance.new("TextButton")
handle.Name = "DockHandle"
handle.BackgroundTransparency = 1
handle.BorderSizePixel = 0
handle.AutoButtonColor = false
handle.Text = ""
handle.Visible = false
handle.Parent = layer
UIKit.clicks(handle)

local tab = Instance.new("Frame")
tab.Name = "Tab"
tab.AnchorPoint = Vector2.new(0, 0.5)
tab.Position = UDim2.fromScale(0, 0.5)
tab.Size = UDim2.fromOffset(DOCK.Handle.X, DOCK.Handle.Y)
tab.BackgroundColor3 = RAIL.DockFill
tab.BackgroundTransparency = 0.1
tab.BorderSizePixel = 0
tab.Active = false
tab.ZIndex = 1
tab.Parent = handle
UIKit.corner(tab, 8)
UIKit.stroke(tab, RAIL.DockEdge, 1.5, 0.15)

-- ASCII, in FredokaOne: the arrows and chevrons of Gotham's symbol range draw
-- as empty boxes in this engine.
local chevron = UIKit.outlined(tab, "Chevron", 16, RAIL.DockHandle, 1.5)
chevron.Font = Enum.Font.FredokaOne
chevron.Size = UDim2.fromScale(1, 1)
chevron.Position = UDim2.fromOffset(0, -1)
chevron.ZIndex = 2
chevron.Text = "<"

--==============================================================================
-- OPEN OR SHUT
--
-- The only state, and it lives here and on the frame as an attribute for
-- anybody who wants to read it -- nobody has to. Open by default, and kept
-- across respawns because nothing here resets on one.
--==============================================================================
local open = true
local slide: Tween? = nil

local function reduced(): boolean
	return player:GetAttribute("SeedAfterimageQuality") == "Off"
end

local function place(animate: boolean)
	if layer.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(layer))
	local rect, atEdge, atSafe = layout.dock, layout.handle, layout.handleShut
	local running = slide
	if running then
		slide = nil
		running:Cancel()
	end
	if not (layout.sidebar and rect and atEdge and atSafe) then
		-- No dock on this screen. The three buttons are back in the layer, and
		-- the frame waits, in place and empty, for a touch screen.
		panel.Visible = false
		handle.Visible = false
		dock.Position = UDim2.new()
		dock.Visible = true
		return
	end

	panel.Position = HudLayout.place(rect, Vector2.zero, layout.safe)
	panel.Size = UDim2.fromOffset(rect.w, rect.h)
	panel.Visible = true

	local away = player:GetAttribute(ATTR.OpenPanel) ~= nil
	local press = if open then atEdge else atSafe
	handle.Position = HudLayout.place(press, Vector2.zero, layout.safe)
	handle.Size = UDim2.fromOffset(press.w, press.h)
	handle.Visible = not away
	chevron.Text = if open then "<" else ">"
	dock:SetAttribute("Open", open)

	-- Shut is the whole dock and a gap off the left edge; then it is hidden,
	-- so nothing in it can be pressed while it is out of sight.
	local goal = if open then UDim2.new()
		else UDim2.fromOffset(-(rect.x + rect.w + HudLayout.Config.Gap), 0)
	if away then
		dock.Position = goal
		dock.Visible = false
		return
	end
	if animate and not reduced() then
		dock.Visible = true
		local tween = TweenService:Create(dock, TweenInfo.new(SLIDE_SECONDS,
			Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = goal })
		slide = tween
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and slide == tween then
				slide = nil
				dock.Visible = open
			end
		end)
		tween:Play()
	else
		dock.Position = goal
		dock.Visible = open
	end
end

handle.Activated:Connect(function()
	open = not open
	place(true)
end)

--==============================================================================
-- ASKED AGAIN WHEN THE SCREEN CHANGES SHAPE, AND WHEN A PANEL OPENS OR SHUTS
--
-- Both connections are on things that outlive this script -- the shared layer
-- and the player -- so they are dropped with this script's own handle, and a
-- re-run's new handle brings its own.
--==============================================================================
local relayout = layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	place(false)
end)
local panels = player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	place(false)
end)
handle.Destroying:Once(function()
	relayout:Disconnect()
	panels:Disconnect()
end)
place(false)
