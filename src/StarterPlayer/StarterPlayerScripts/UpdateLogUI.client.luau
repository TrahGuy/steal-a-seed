--!strict
-- Steal a Seed :: UpdateLogUI (2026-10-05, the owner's WHAT'S NEW)
--
-- THE GAME'S RECENT CHANGES, FOR ANY PLAYER WHO ASKS.
--
--   THE BUTTON  a small rail slab (UIKit.railButton, the EVENTS button's family)
--               with a scroll drawn from frames (UIKit.scrollIcon -- a native
--               stand-in; there is no approved picture, an asset gap) and its
--               word, where HudLayout puts it (`updates`). A NEW dot -- the rail
--               badge's red -- while the newest entry is under
--               GameConfig.UpdateLog.NewDays old, until the panel is opened THIS
--               SESSION. Nothing is saved: a dot that stayed off after a rejoin
--               would need a profile field, which this deliberately does not add.
--   THE PANEL   MenuKit's rim-themed modal: WHAT'S NEW beside the scroll, the
--               red studded close; laid out by MenuLayout.updatesPanel --
--               between the rails on a desktop, covering the rail elsewhere
--               (UIKit.coverRail) -- and on the OpenPanel mutex like EVENTS, so
--               B (PadFocus), the close, the dimmer, Escape and Backspace (bound
--               only while it is open) and the Roblox menu opening all shut it.
--               One light card an entry (UpdateLog.shown), newest first: the date
--               and the title in the label face, the bullets in the plain dark
--               body face, the newest card's gold tag. It scrolls; a controller
--               scrolls it with the stick. No pop under reduced motion.
--
-- THE WORDS ARE Shared/UpdateLog's, the owner's to edit. No remote, no server.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local UpdateLog = require(Shared:WaitForChild("UpdateLog"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ATTR = GameConfig.Attributes
local RAIL = GameConfig.Rail
local LOG = GameConfig.UpdateLog
local U = MenuLayout.Updates
local LOOK = MenuKit.Look
local BAG = GameConfig.BagLook
local PANEL_NAME = "Updates"
local CLOSE_ACTION = "SeedUpdatesClose"

local WHITE = Color3.fromRGB(255, 255, 255)
local Z = 6

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedUpdates")
if existing then
	existing:Destroy()
end
ContextActionService:UnbindAction(CLOSE_ACTION)

local gui = Instance.new("ScreenGui")
gui.Name = "SeedUpdates"
gui.ResetOnSpawn = false
gui.DisplayOrder = 32
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "UpdatesButton",
	face = RAIL.UpdatesFace,
	shade = RAIL.UpdatesShade,
	wide = false,
})
do
	-- The picture: a square in the slab's upper part, whatever its size.
	local art = Instance.new("Frame")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0)
	art.Position = UDim2.fromScale(0.5, 0.1)
	art.Size = UDim2.fromScale(0.56, 0.56)
	art.BackgroundTransparency = 1
	art.Active = false
	art.ZIndex = 3
	art.Parent = button
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.Parent = art
	UIKit.scrollIcon(art, 3)
	-- The word under it, as EVENTS stands under its calendar -- 1 px in from each
	-- side, not 2: on a short phone's 34-px square of the panel under the Bag,
	-- UPDATES at its least 7 px is 31 wide (measured in Play, 2026-10-05).
	local word = UIKit.outlined(button, "Word", 11, WHITE, 1.5)
	word.AnchorPoint = Vector2.new(0.5, 1)
	word.Position = UDim2.new(0.5, 0, 1, -2)
	word.Size = UDim2.new(1, -2, 0.3, 0)
	word.TextScaled = true
	word.Text = RAIL.UpdatesWord
	word.ZIndex = 6
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 12
	fit.MinTextSize = 7
	fit.Parent = word
end
button.Visible = false

-- THE NEW DOT: the rail badge's red, a white ring, on the button's top-LEFT
-- corner -- on a phone the button stands just left of Garden, whose own badge
-- is tucked into Garden's top-left corner, and two red dots side by side would
-- read as one; drawn still (it never pulses), so reduced motion has nothing to do.
local dot = Instance.new("Frame")
dot.Name = "NewDot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromOffset(4, 4)
dot.Size = UDim2.fromOffset(RAIL.UpdatesDot, RAIL.UpdatesDot)
dot.BackgroundColor3 = RAIL.Badge
dot.BorderSizePixel = 0
dot.Active = false
dot.ZIndex = 8
dot.Visible = false
dot.Parent = button
UIKit.corner(dot, math.ceil(RAIL.UpdatesDot / 2))
UIKit.stroke(dot, WHITE, 2)

local seenThisSession = false
local function refreshDot()
	dot.Visible = UpdateLog.isNew(workspace:GetServerTimeNow()) and not seenThisSession
	-- The phone's shut panel wears it on its handle (2026-10-06).
	UIKit.dockBadge("Updates", if dot.Visible then "dot" else nil)
end
refreshDot()
-- The dot goes out by itself when the newest entry passes NewDays mid-session.
do
	local newest = UpdateLog.Entries[1]
	local day = newest and UpdateLog.dayOf(newest.date)
	if day then
		local left = (day :: number) + LOG.NewDays * 86400 - workspace:GetServerTimeNow()
		if left > 0 and left < 7 * 86400 then
			task.delay(left + 1, refreshDot)
		end
	end
end

-- From HudLayout: on a phone the middle square of the panel under the Bag
-- (2026-10-05), standing in the frame RailDrawerUI draws that panel in. Off a
-- desktop an open panel's corner can be under it, so it steps aside while
-- OpenPanel names a panel, as EVENTS does, and comes back. An empty rect is a
-- screen with no clear spot for it (HudLayout): hidden there.
local function placeButton()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = layout.updates
	local away = layout.compact and player:GetAttribute(ATTR.OpenPanel) ~= nil
	if r.w <= 0 or r.h <= 0 or away then
		button.Visible = false
		return
	end
	UIKit.railShape(button, Vector2.new(r.w, r.h))
	-- On a phone in the panel under the Bag's scrolling canvas (2026-10-06).
	UIKit.placeRail(button, layout, r, playerGui)
	button.Visible = true
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(placeButton)
placeButton()

--==============================================================================
-- THE PANEL
--==============================================================================
local menu = MenuKit.modal(gui, PANEL_NAME, "WHAT'S NEW", nil, nil, function(holder: Frame, z: number)
	UIKit.scrollIcon(holder, z)
end, true)
-- This gui holds only the panel, so it takes the player's menu size whole.
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body
local close = modal.close

local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = modal.shell

local list = Instance.new("ScrollingFrame")
list.Name = "UpdateList"
list.BackgroundColor3 = LOOK.Well
list.BackgroundTransparency = LOOK.WellTransparency
list.BorderSizePixel = 0
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ScrollBarThickness = U.ScrollBar
list.ScrollBarImageColor3 = LOOK.WellEdge
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
-- A controller scrolls it with the stick once it is selected (PadFirst).
list.Selectable = true
list.SelectionImageObject = nil
list.ZIndex = Z
list.Parent = body
UIKit.corner(list, 10)
MenuKit.keyline(list, LOOK.WellEdge, 1, 0.3)
padFirst.Value = list
local listLayout = Instance.new("UIListLayout")
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, U.ListInset)
	pad.PaddingRight = UDim.new(0, U.ListInset + U.ScrollBar)
	pad.PaddingTop = UDim.new(0, U.ListInset)
	pad.PaddingBottom = UDim.new(0, U.ListInset)
	pad.Parent = list
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, U.CardGap)
	listLayout.Parent = list
end

--==============================================================================
-- ONE CARD AN ENTRY: built once (the words ship with the place), newest first.
-- The engine sizes each card (AutomaticSize): the date's line -- the newest
-- card's tag at its right end -- the title's line, then a line a bullet, two
-- where a narrow screen wraps one rather than cut it short. Nothing is measured
-- here (MenuLayout.Updates says why).
--==============================================================================
local newestTag: TextLabel? = nil

local function buildCard(e: UpdateLog.Entry, order: number)
	local card = MenuKit.frame(list, "Update_" .. e.id, Z + 1, WHITE, 0, 9)
	card.LayoutOrder = order
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	MenuKit.cardFace(card)
	-- The newest card, subtly: a gold keyline and its tag.
	local newest = order == 1
	MenuKit.keyline(card, if newest then BAG.GoldEdge else LOOK.CardEdge, if newest then 1.5 else 1,
		if newest then 0 else LOOK.CardEdgeTransparency)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, U.CardInset)
	pad.PaddingRight = UDim.new(0, U.CardInset)
	pad.PaddingTop = UDim.new(0, U.CardInset)
	pad.PaddingBottom = UDim.new(0, U.CardInset)
	pad.Parent = card
	local rows = Instance.new("UIListLayout")
	rows.SortOrder = Enum.SortOrder.LayoutOrder
	rows.Parent = card

	-- Dark type on the light card: plain, no outline (the readability rules).
	local head = MenuKit.frame(card, "Head", Z + 2)
	head.LayoutOrder = 1
	head.Size = UDim2.new(1, 0, 0, U.DateH)
	local date = MenuKit.text(head, "Date", U.DateSize, LOOK.Muted, Z + 2)
	date.Size = UDim2.new(1, if newest then -(U.TagW + U.TagGap) else 0, 1, 0)
	date.TextXAlignment = Enum.TextXAlignment.Left
	date.TextTruncate = Enum.TextTruncate.AtEnd
	date.Text = e.date
	if newest then
		local tag = MenuKit.frame(head, "Tag", Z + 2, BAG.GoldTop, 0, 6)
		tag.AnchorPoint = Vector2.new(1, 0.5)
		tag.Position = UDim2.fromScale(1, 0.5)
		tag.Size = UDim2.fromOffset(U.TagW, U.TagH)
		MenuKit.keyline(tag, BAG.GoldEdge, 1.5)
		local word = MenuKit.text(tag, "Word", 12, BAG.GoldText, Z + 3)
		word.Size = UDim2.fromScale(1, 1)
		newestTag = word
	end
	local title = MenuKit.text(card, "Title", U.TitleSize, LOOK.Text, Z + 2)
	title.LayoutOrder = 2
	title.Size = UDim2.new(1, 0, 0, U.TitleH)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = e.title
	local gap = MenuKit.frame(card, "Gap", Z + 2)
	gap.LayoutOrder = 3
	gap.Size = UDim2.new(1, 0, 0, U.HeadGap)
	for i, line in ipairs(e.bullets) do
		local row = MenuKit.frame(card, "Row" .. i, Z + 2)
		row.LayoutOrder = 3 + i
		row.Size = UDim2.new(1, 0, 0, 0)
		row.AutomaticSize = Enum.AutomaticSize.Y
		local mark = MenuKit.frame(row, "Mark", Z + 2, LOOK.Muted, 0, 3)
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.fromOffset(math.floor(U.BulletIndent / 2) - 2, math.floor(U.BulletLine / 2))
		mark.Size = UDim2.fromOffset(6, 6)
		local text = MenuKit.body(row, "Bullet" .. i, U.BulletSize, LOOK.Text, Z + 2)
		text.Position = UDim2.fromOffset(U.BulletIndent, 0)
		text.Size = UDim2.new(1, -U.BulletIndent, 0, U.BulletLine)
		text.AutomaticSize = Enum.AutomaticSize.Y
		text.TextWrapped = true
		text.TextXAlignment = Enum.TextXAlignment.Left
		-- Plain text: the owner's words are shown as written, never as markup.
		text.RichText = false
		text.Text = line
	end
end

-- Until the engine has sized the cards, one line a bullet: what every screen
-- but the narrowest draws (UpdateLogSpec), so the panel rarely moves at all.
local lineCounts: { number } = {}
for i, e in ipairs(UpdateLog.shown()) do
	buildCard(e, i)
	table.insert(lineCounts, #e.bullets)
end
local estimate = MenuLayout.updatesContent(lineCounts)

-- The cards' height in the gui's own units: the list layout's, through the
-- list's own drawn-to-asked ratio, which holds under any UIScale (the menu size,
-- a TV, the panel's pop).
local function contentHeight(): number
	local drawn = list.AbsoluteSize.Y
	local asked = list.Size.Y.Offset
	if drawn < 1 or asked < 1 then
		return estimate
	end
	return listLayout.AbsoluteContentSize.Y * asked / drawn
end

local function paintTag()
	local tag = newestTag
	if tag then
		-- NEW while it is new; afterwards still the latest.
		tag.Text = if UpdateLog.isNew(workspace:GetServerTimeNow()) then "NEW" else "LATEST"
	end
end
paintTag()

--==============================================================================
-- LAYOUT: MenuLayout's answer, applied (the gui's own units)
--==============================================================================
local open = false

local function keyboardTop(): number?
	if not UserInputService.OnScreenKeyboardVisible then
		return nil
	end
	local ok, at = pcall(function()
		return UserInputService.OnScreenKeyboardPosition
	end)
	if not ok or typeof(at) ~= "Vector2" or at.Y <= 0 then
		return nil
	end
	return (at.Y - GuiService:GetGuiInset().Y) / UIKit.scaleOf(gui)
end

local function relayout()
	local k = UIKit.scaleOf(gui)
	local safe = gui.AbsoluteSize / k
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(gui))
	local camera = workspace.CurrentCamera
	local hudScale = if HudLayout.isTenFoot() and camera then HudLayout.tenFootScale(camera.ViewportSize) else 1
	local f = k / hudScale
	local p = MenuLayout.updatesPanel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		keyboardTop = keyboardTop(),
	}, RAIL.OutlineThickness, contentHeight())
	menu.place(p)
	local main = MenuLayout.blocks(p).main
	list.Position = UDim2.fromOffset(main.x, main.y)
	list.Size = UDim2.fromOffset(main.w, main.h)
	UIKit.coverRail(playerGui, PANEL_NAME, open and p.covers)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
-- The cards re-measured: a wrapped bullet, the face arriving. Only the height
-- follows the cards, never the width they wrap in, so this settles at once.
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(relayout)
UIKit.onMenuSize(relayout)
relayout()

--==============================================================================
-- OPEN AND SHUT
--==============================================================================
local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		seenThisSession = true
		refreshDot()
		paintTag()
		list.CanvasPosition = Vector2.zero
		-- Escape and Backspace, only while open: a lasting binding on Escape
		-- would eat the Roblox menu for the session (MarigoldShopUI's note).
		-- B is PadFocus's: it clears OpenPanel, which shuts this.
		ContextActionService:BindActionAtPriority(CLOSE_ACTION, function(_, state: Enum.UserInputState)
			if state == Enum.UserInputState.Begin then
				setOpen(false)
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, 3000, Enum.KeyCode.Escape, Enum.KeyCode.Backspace)
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		ContextActionService:UnbindAction(CLOSE_ACTION)
	end
	relayout()
	modal.setOpen(want)
end

-- A tap presses it; a drag on a phone's scrolling panel under the Bag scrolls
-- and never presses it (2026-10-06, MenuKit.tap).
MenuKit.tap(button, UIKit.railDockScroll(playerGui), function()
	setOpen(not open)
end)
close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)
-- The Roblox menu opening is a back gesture too (Escape may reach it first).
GuiService.MenuOpened:Connect(function()
	setOpen(false)
end)

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if open and holder ~= PANEL_NAME then
		setOpen(false)
	end
end)

gui.Destroying:Connect(function()
	UIKit.coverRail(playerGui, PANEL_NAME, false)
	ContextActionService:UnbindAction(CLOSE_ACTION)
	if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
end)
