--!strict
--==============================================================================
-- Steal a Seed :: MenuKit (2026-10-03, the compact Index and Shop)
--
-- THE PIECES THE COMPACT MENUS ARE BUILT FROM, in the Bag's look
-- (GameConfig.BagLook -- bright since the owner's recolor of 2026-10-04: a
-- mint-to-cream shell, a leaf-green header and selection, green main actions,
-- sky-blue secondary ones, gold for owned, a coral close, dark type on the
-- light plates, white-to-mint cards). One copy, so the Index, the Shop, MY
-- PLANTS, EVENTS and the Bag cannot drift into separate styles. Where each
-- piece STANDS is MenuLayout's; this file only builds and paints.
--
--   modal      UIKit.modal in the Bag's theme, placed by a MenuLayout.Panel,
--              its header one short row (fixedHeader: never padded round a
--              rail button, because the panel never stands under one)
--   chooser    the biomes or the categories: a narrow sidebar column, or a
--              dropdown in the header whose list opens over the panel
--   search     a well with a magnifying glass and a clear button
--   segmented  All / Grown / Missing
--   button     a 44-px target round a plate: go (green), sky (secondary),
--              idle (quiet), done (gold), on, off (cannot press), live
--   tap        ONE PRESS, ONE ACTION: a finger that scrolls a list never
--              presses what it started on (PressGesture), a mouse click and a
--              controller's A each press once
--   bindBack   B steps back out of a sheet or a list before it closes the
--              panel (PadFocus's B is 2500; this is 3000)
--==============================================================================
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local PressGesture = require(Shared:WaitForChild("PressGesture"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))

local MenuKit = {}

local LOOK = GameConfig.BagLook
local HOT = GameConfig.Hotbar
local WHITE = Color3.fromRGB(255, 255, 255)

--==============================================================================
-- THE TOKENS (bright since 2026-10-04: GameConfig.BagLook says why)
--
-- `Text` and `Muted` are the words on the light plates -- the shell, a well, a
-- sheet, a card. `Cream` stays cream, for words on a dark plate: the count
-- pill, a dark display window. `Money` and `Premium` are amounts on a light
-- plate; `Green` and `Gold` are fills (a bar, a disc, a dot), too pale for
-- words on white.
--==============================================================================
MenuKit.Look = {
	Ink = LOOK.Ink,
	Text = LOOK.Text,
	Cream = LOOK.Cream,
	Muted = LOOK.Muted,
	Title = LOOK.Title,
	Well = LOOK.Well,
	WellTransparency = LOOK.WellTransparency,
	WellEdge = LOOK.WellEdge,
	Placeholder = LOOK.Placeholder,
	Sheet = LOOK.Sheet,
	SheetEdge = LOOK.SheetEdge,
	Mark = LOOK.CatMark,
	Bar = LOOK.BarTrack,
	Leaf = LOOK.Leaf,
	-- The menu cards: white to a breath of mint (MenuKit.cardFace) under a clean
	-- dark keyline. The Bag's tiles keep the hotbar's slate (InventoryTile).
	Card = LOOK.CardTop,
	CardTransparency = 0,
	CardEdge = LOOK.CardEdge,
	CardEdgeTransparency = LOOK.CardEdgeTransparency,
	CardHoverEdge = HOT.HoverEdgeTransparency,
	PreviewAmbient = HOT.PreviewAmbient,
	-- The dark display window an almanac plant stands in.
	Window = LOOK.Window,
	-- Fills: a grown check, a progress bar; a reward's gold, a waiting dot.
	Green = Color3.fromRGB(70, 184, 58),
	Gold = Color3.fromRGB(255, 206, 84),
	-- Amounts on a light plate.
	Money = LOOK.Money,
	Premium = LOOK.Premium,
	Speed = LOOK.Speed,
	-- LIVE NOW (the Events panel's badge and button): the rail badge's red.
	Live = GameConfig.Rail.Badge,
	-- STARTS IN ...: the go button's green.
	Soon = LOOK.ButtonBottom,
	-- Over, cancelled, not pressable: a grey that is not any state's colour.
	Off = Color3.fromRGB(122, 134, 128),
	-- The type (the global UI pass): sentences in the body face, names and
	-- labels in FredokaOne.
	BodyFont = LOOK.BodyFont,
	BodyBoldFont = LOOK.BodyBoldFont,
	LabelFont = LOOK.LabelFont,
	-- The studded plate a list of cards stands on (MenuKit.baseplate).
	Plate = LOOK.PlateFill,
	PlateEdge = LOOK.PlateEdge,
	PlateStud = LOOK.PlateStud,
	PlateStudShade = LOOK.PlateStudShade,
	PlatePitch = LOOK.PlatePitch,
	PlateStudSize = LOOK.PlateStudSize,
}
local L = MenuKit.Look

--==============================================================================
-- THE SLATE TOKENS: the same names in the old dark palette (GameConfig.SlateLook)
-- for what is HUD rather than menu -- the boost icons and their popover -- so
-- the recolor never reaches the HUD.
--==============================================================================
MenuKit.Slate = {
	Ink = GameConfig.SlateLook.Ink,
	Cream = GameConfig.SlateLook.Cream,
	Muted = GameConfig.SlateLook.Muted,
	Title = GameConfig.SlateLook.Title,
	Well = GameConfig.SlateLook.Well,
	Sheet = GameConfig.SlateLook.Sheet,
	SheetEdge = GameConfig.SlateLook.SheetEdge,
	Card = HOT.Plate,
	Gold = Color3.fromRGB(255, 206, 84),
}

-- The faces a button can wear: top, bottom, keyline, words. The same
-- functional colours on every surface (the global UI pass, 2026-10-04):
--   go       the main action -- buy, plant, equip: lively green
--   sky      secondary and navigation (BACK, REWARDS & ODDS, UNEQUIP ALL)
--   claim    a reward to take (CLAIM): warm gold, white words
--   done     owned, claimed, completed -- a state: gold, dark words
--   danger   close, remove, destroy (REMOVE, SACRIFICE, a reset): red
--   premium  a premium accent: violet
--   idle     quiet: pale, a dark keyline, dark words
--   on       chosen: leaf green (a tab, a category -- with its mark)
--   off      cannot be pressed: flat grey, still readable
--   live     LIVE NOW, shown on a button that does not press
--   dark     the old name of the secondary face; it is `sky` now
local SKY = { LOOK.SkyTop, LOOK.SkyBottom, LOOK.SkyEdge, WHITE }
local STYLES: { [string]: { Color3 } } = {
	go = { LOOK.ButtonTop, LOOK.ButtonBottom, LOOK.ButtonEdge, WHITE },
	sky = SKY,
	claim = { LOOK.ClaimTop, LOOK.ClaimBottom, LOOK.ClaimEdge, WHITE },
	idle = { LOOK.CatTop, LOOK.CatBottom, LOOK.CatEdge, LOOK.CatText },
	done = { LOOK.GoldTop, LOOK.GoldBottom, LOOK.GoldEdge, LOOK.GoldText },
	danger = { LOOK.DangerTop, LOOK.DangerBottom, LOOK.DangerEdge, WHITE },
	premium = { LOOK.PremiumTop, LOOK.PremiumBottom, LOOK.PremiumEdge, WHITE },
	dark = SKY,
	on = { LOOK.CatOnTop, LOOK.CatOnBottom, LOOK.CatOnEdge, LOOK.CatTextOn },
	-- A state shown on a button that does not press (2026-10-04, Events):
	-- LIVE NOW in red, and an ended or unavailable event in flat grey.
	live = { Color3.fromRGB(240, 96, 92), Color3.fromRGB(184, 48, 52), Color3.fromRGB(110, 20, 24), WHITE },
	off = { LOOK.OffTop, LOOK.OffBottom, LOOK.OffEdge, LOOK.OffText },
}
MenuKit.Styles = STYLES
-- Faces that never press: no pop, no studs.
local STILL: { [string]: boolean } = { off = true, live = true }
-- Faces that wear studs when a button asks for them: the actions.
local STUDDED: { [string]: boolean } = { go = true, sky = true, claim = true, danger = true, premium = true }

--==============================================================================
-- A FACE'S GRADIENT, WITH ITS FOOT
--
-- The lit face runs top to bottom, then a darker foot -- the bottom fifth,
-- the close button's three reds made general -- in the SAME gradient, so the
-- rounded corners stay exact and no extra frame stands at the edge.
--==============================================================================
function MenuKit.faceColours(top: Color3, bottom: Color3, edge: Color3): ColorSequence
	return UIKit.footColours(top, bottom, edge)
end

function MenuKit.keyline(parent: GuiObject, colour: Color3, thickness: number, transparency: number?): UIStroke
	local s = UIKit.stroke(parent, colour, thickness, transparency)
	-- Border: on a TextButton the default stroke outlines its (empty) text.
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

--==============================================================================
-- WORDS: PLAIN WHEN DARK, A THIN INK LINE WHEN LIGHT (2026-10-04, the
-- readability brief)
--
-- Every MenuKit label used to carry a 1-px ink stroke, and on the light plates
-- that put a dark outline round small dark letters -- the muddy, crowded type
-- in the owner's screenshots. Now a label's stroke (its child "Ink") follows
-- its colour: on for light words (white or cream on a coloured face, a dark
-- window), off for dark words on a light plate -- decided again whenever the
-- colour changes, so a label repainted from white to forest loses its line.
-- Only the "Ink" stroke is managed: a stroke another module owns (RarityFX's,
-- a heading's) is never touched.
--==============================================================================
function MenuKit.isLight(c: Color3): boolean
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B > 0.62
end

local function inkFor(label: TextLabel, thickness: number?)
	-- A rarity word (RarityFX gave it its "RarityLight") and a label that asked
	-- to keep its line (MenuKit.keepInk) are ALWAYS outlined: a Legendary gold on
	-- white needs it, and RarityFX tunes that line's colour itself.
	local kept = label:FindFirstChild("RarityLight") ~= nil or label:GetAttribute("InkKept") == true
	local light = kept or MenuKit.isLight(label.TextColor3)
	local s = label:FindFirstChild("Ink")
	if light and not s then
		local made = UIKit.stroke(label, L.Ink, thickness or 1.25)
		made.Name = "Ink"
		made.LineJoinMode = Enum.LineJoinMode.Round
		s = made
	end
	if s and s:IsA("UIStroke") then
		s.Enabled = light
	end
end

-- A label whose ink line stays on whatever its colour: a rarity or size word,
-- a coloured amount that must hold its edge. Answers the line.
function MenuKit.keepInk(label: TextLabel): UIStroke
	label:SetAttribute("InkKept", true)
	inkFor(label)
	return label:FindFirstChild("Ink") :: UIStroke
end

-- A label's colour, with its ink line put on or taken off to match.
function MenuKit.ink(label: TextLabel, colour: Color3)
	label.TextColor3 = colour
	inkFor(label)
end

local function newLabel(parent: Instance, name: string, size: number, colour: Color3?, z: number,
	font: Enum.Font): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Font = font
	l.TextSize = size
	l.TextColor3 = colour or L.Text
	l.Text = ""
	l.ZIndex = z
	l.Parent = parent
	inkFor(l)
	l:GetPropertyChangedSignal("TextColor3"):Connect(function()
		inkFor(l)
	end)
	return l
end

-- A name, a label, a card title: FredokaOne, dark type unless told.
function MenuKit.text(parent: Instance, name: string, size: number, colour: Color3?, z: number): TextLabel
	return newLabel(parent, name, size, colour, z, LOOK.LabelFont)
end

-- Sentences, benefits, amounts, help and status lines: the clean medium face.
function MenuKit.body(parent: Instance, name: string, size: number, colour: Color3?, z: number): TextLabel
	return newLabel(parent, name, size, colour, z, LOOK.BodyFont)
end

-- A large white heading with a heavy ink outline (a menu title's family).
function MenuKit.heading(parent: Instance, name: string, size: number, colour: Color3?, z: number): TextLabel
	local l = UIKit.outlined(parent, name, size, colour or L.Title, 2.5)
	l.ZIndex = z
	local s = l:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = L.Ink
		s.LineJoinMode = Enum.LineJoinMode.Round
	end
	return l
end

function MenuKit.textWidth(text: string, size: number, font: Enum.Font?): number
	return TextService:GetTextSize(text, size, font or Enum.Font.FredokaOne, Vector2.new(4000, 200)).X
end

function MenuKit.frame(parent: Instance, name: string, z: number, colour: Color3?, transparency: number?,
	radius: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = colour or L.Well
	f.BackgroundTransparency = if colour then (transparency or 0) else 1
	f.BorderSizePixel = 0
	f.Active = false
	f.ZIndex = z
	f.Parent = parent
	if radius then
		UIKit.corner(f, radius)
	end
	return f
end

--==============================================================================
-- THE BASEPLATE (2026-10-06): the studded plate a list of cards stands on --
-- the Shop's products, the Index's plants -- still while the list scrolls over
-- it. The plate's green, its studs raised as the rims' are (UIKit.studs), a
-- dark keyline round it. Never Active: a press lands on the card or the list.
--==============================================================================
function MenuKit.baseplate(parent: Instance, z: number): Frame
	local plate = Instance.new("Frame")
	plate.Name = "Baseplate"
	plate.BackgroundColor3 = L.Plate
	plate.BorderSizePixel = 0
	plate.Active = false
	plate.ZIndex = z
	plate.Parent = parent
	UIKit.corner(plate, 10)
	MenuKit.keyline(plate, L.PlateEdge, 1.5, 0)
	UIKit.studs(plate, {
		pitch = L.PlatePitch,
		size = L.PlateStudSize,
		face = L.PlateStud,
		shade = L.PlateStudShade,
		inset = 6,
		zIndex = z,
	})
	return plate
end

--==============================================================================
-- A MENU CARD'S FACE (the bright recolor, 2026-10-04)
--
-- White to a breath of mint, top to bottom (BagLook.CardTop / CardBottom), for
-- the cards of MY PLANTS, the almanac, the Shop and EVENTS. `cardTint` takes
-- BagLook.CardTint of a rarity's own colour (GameConfig.RarityColor) into the
-- TOP of the card, where the creature stands, and lets it fade out before the
-- words -- so the name and the rarity's own styled word (RarityFX) stay on
-- near-white. A static UIGradient: nothing moves.
--==============================================================================
function MenuKit.cardFace(face: GuiObject): UIGradient
	face.BackgroundTransparency = 0
	return UIKit.gradient(face, LOOK.CardTop, LOOK.CardBottom)
end

function MenuKit.cardTint(gradient: UIGradient, colour: Color3?)
	if not colour then
		gradient.Color = ColorSequence.new(LOOK.CardTop, LOOK.CardBottom)
		return
	end
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, LOOK.CardTop:Lerp(colour, LOOK.CardTint)),
		ColorSequenceKeypoint.new(0.5, LOOK.CardTop:Lerp(colour, LOOK.CardTint * 0.35)),
		ColorSequenceKeypoint.new(1, LOOK.CardBottom),
	})
end

--==============================================================================
-- A PICTURE THAT KEEPS ITS FALLBACK UNTIL IT HAS LOADED (UIKit.whenPictureLoads)
--
-- A picture that does not load leaves whatever stands beside it (its words)
-- and its fallback, if it has one -- never anything restored in its place --
-- and is REPORTED ONCE, by id, in the log. Only a picture actually on screen is
-- reported: one inside a closed panel may not load until it is shown, so it is
-- asked about again until it is shown, and then judged.
--==============================================================================
local reportedPictures: { [string]: boolean } = {}

local function shownNow(object: Instance): boolean
	local o: Instance? = object
	while o and o:IsA("GuiObject") do
		local g = o :: GuiObject
		if not g.Visible then
			return false
		end
		if g:IsA("CanvasGroup") and (g :: CanvasGroup).GroupTransparency >= 0.99 then
			return false
		end
		o = g.Parent
	end
	return o ~= nil and o:IsA("LayerCollector") and (o :: LayerCollector).Enabled
end

local function watchPicture(pic: ImageLabel, onLoaded: () -> ())
	UIKit.whenPictureLoads(pic, function(loaded: boolean)
		if loaded then
			onLoaded()
			return
		end
		if pic.Parent == nil or pic.IsLoaded then
			return
		end
		if shownNow(pic) then
			if not reportedPictures[pic.Image] then
				reportedPictures[pic.Image] = true
				warn("[Seed/MenuKit] a picture did not load: " .. pic.Image .. " (" .. pic:GetFullName() .. ")")
			end
		else
			task.delay(2, function()
				if pic.Parent and not pic.IsLoaded then
					watchPicture(pic, onLoaded)
				end
			end)
		end
	end)
end

function MenuKit.picture(parent: Instance, image: string, fallback: string?, z: number): Frame
	local holder = MenuKit.frame(parent, "Icon", z)
	local back: ImageLabel? = nil
	if fallback and fallback ~= "" and fallback ~= image then
		local f = Instance.new("ImageLabel")
		f.Name = "Fallback"
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundTransparency = 1
		f.Image = fallback
		f.ScaleType = Enum.ScaleType.Fit
		f.Active = false
		f.ZIndex = z
		f.Parent = holder
		back = f
	end
	local pic = Instance.new("ImageLabel")
	pic.Name = "Picture"
	pic.Size = UDim2.fromScale(1, 1)
	pic.BackgroundTransparency = 1
	pic.Image = image
	pic.ScaleType = Enum.ScaleType.Fit
	-- Never takes a press: whatever button it stands on does.
	pic.Active = false
	pic.ZIndex = z + 1
	pic.Parent = holder
	watchPicture(pic, function()
		local f = back
		if f then
			f.Visible = false
		end
	end)
	return holder
end

-- A small chevron pointing down, from two turned bars (no glyph to come out a box).
function MenuKit.chevron(parent: Instance, size: number, colour: Color3, z: number): Frame
	local box = MenuKit.frame(parent, "Chevron", z)
	box.Size = UDim2.fromOffset(size, size)
	for _, side in ipairs({ -1, 1 }) do
		local bar = MenuKit.frame(box, "Bar", z, colour, 0, 2)
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.fromScale(0.5 + side * 0.17, 0.5)
		bar.Size = UDim2.new(0.56, 0, 0, math.max(2, math.floor(size * 0.18)))
		bar.Rotation = side * -42
	end
	return box
end

--==============================================================================
-- THE MODAL
--==============================================================================
export type Modal = {
	modal: any,
	header: number,
	-- The row the title and the close button stand in, and the body (the
	-- whole shell: every other block is placed in shell coordinates).
	titleBar: Frame,
	body: Frame,
	icon: GuiObject?,
	place: (MenuLayout.Panel) -> (),
}

--==============================================================================
-- THE STUDDED RIM, FOR EVERY MENU (2026-10-04, the global UI art pass)
--
-- One theme for UIKit.modal, shared by MenuKit's menus and by the older panels
-- that build UIKit.modal themselves (Settings, Marigold, Sell, the wheel...):
-- the white studded rim with an ink rule, the clean mint body, the title on
-- the rim in white LuckiestGuy with a heavy ink line, and the red studded
-- close. `lift` is the overhang the title row stands in (MenuLayout's, by
-- screen); a panel UIKit lays out itself takes the tall one.
--==============================================================================
function MenuKit.rimTheme(lift: number?): UIKit.ModalTheme
	return {
		fill = LOOK.ShellTop,
		shade = LOOK.ShellBottom,
		outline = LOOK.Ink,
		rim = true,
		rimTop = LOOK.RimTop,
		rimBottom = LOOK.RimBottom,
		studs = {
			pitch = LOOK.StudPitch,
			size = LOOK.StudSize,
			face = LOOK.RimStud,
			shade = LOOK.RimStudShade,
			image = LOOK.RimStudImage,
		},
		lift = lift or MenuLayout.Config.LiftTall,
		headerRule = LOOK.Ink,
		titleStroke = LOOK.Ink,
		titleStrokeThickness = LOOK.TitleStroke,
		titleSize = LOOK.TitleSize,
		closeTop = LOOK.CloseTop,
		closeBottom = LOOK.CloseBottom,
		closeShade = LOOK.CloseShade,
		closeRadius = 11,
		closeStuds = {
			pitch = LOOK.CloseStudPitch,
			size = LOOK.CloseStudSize,
			face = LOOK.CloseStud,
			shade = LOOK.CloseStudShade,
		},
	}
end

-- `drawIcon` draws a native icon into the title's icon box (a menu with no
-- approved picture, e.g. EVENTS' calendar) when `iconImage` is nil.
function MenuKit.modal(gui: ScreenGui, name: string, title: string, iconImage: string?, iconFallback: string?,
	drawIcon: ((holder: Frame, z: number) -> ())?, stillWhenReduced: boolean?): Modal
	local modal = UIKit.modal(gui, {
		name = name,
		title = title,
		maxWidth = 4000,
		maxHeight = 4000,
		titleColour = LOOK.Title,
		fixedHeader = true,
		theme = MenuKit.rimTheme(),
		-- Opt-in (WHAT'S NEW): no open/shut pop under reduced motion.
		stillWhenReduced = stillWhenReduced,
	})
	-- The panel is sized by MenuLayout, which never asks for less than fits.
	local limit = modal.group:FindFirstChildOfClass("UISizeConstraint")
	if limit then
		limit.MinSize = Vector2.new(120, 120)
		limit.MaxSize = Vector2.new(10000, 10000)
	end
	-- Centre-anchored, so the open's pop (the modal's UIScale) grows from the
	-- middle of the panel, wherever MenuLayout put it.
	modal.group.AnchorPoint = Vector2.new(0.5, 0.5)
	local titleBar = modal.title.Parent :: Frame
	local body = modal.body :: Frame
	body.Position = UDim2.new()
	body.Size = UDim2.fromScale(1, 1)
	local icon: GuiObject? = nil
	if iconImage and iconImage ~= "" then
		local pic = MenuKit.picture(titleBar, iconImage, iconFallback, 4)
		pic.AnchorPoint = Vector2.new(0, 0.5)
		pic.Position = UDim2.new(0, 0, 0.5, 0)
		icon = pic
	elseif drawIcon then
		local holder = MenuKit.frame(titleBar, "Icon", 4)
		holder.AnchorPoint = Vector2.new(0, 0.5)
		holder.Position = UDim2.new(0, 0, 0.5, 0)
		drawIcon(holder, 5)
		icon = holder
	end
	-- The close button's own small press, as the Bag's has.
	do
		local plate = modal.close:FindFirstChild("Plate")
		if plate and plate:IsA("GuiObject") then
			local plateScale = Instance.new("UIScale")
			plateScale.Parent = plate
			UIKit.cardPop(modal.close, plateScale, { hoverScale = 1.06, pressScale = 0.94, sound = false })
		end
	end
	local banner = modal.shell:FindFirstChild("HeaderBanner") :: Frame?
	local rimBlocker = modal.shell:FindFirstChild("RimBlocker") :: GuiObject?
	local closePlate = modal.close:FindFirstChild("Plate") :: GuiObject?
	local outline = GameConfig.Rail.OutlineThickness
	local out: Modal
	out = {
		modal = modal,
		header = MenuLayout.Config.HeaderTall,
		titleBar = titleBar,
		body = body,
		icon = icon,
		place = function(p: MenuLayout.Panel)
			local r = p.rect
			modal.group.Position = UDim2.fromOffset(r.x + r.w / 2, r.y + r.h / 2)
			modal.group.Size = UDim2.fromOffset(r.w, r.h)
			out.header = p.header
			-- The shell starts `lift` under the panel's top; MenuLayout's blocks
			-- are in its coordinates, so nothing below the rim moves.
			modal.shell.Size = UDim2.new(1, -outline * 2, 1, -outline * 2 - p.lift)
			if rimBlocker then
				rimBlocker.Size = UDim2.new(1, 0, 0, p.lift + outline)
			end
			-- The title row's middle stands just under the rim's top edge.
			local centre = MenuKit.titleCentre(p.short)
			titleBar.Position = UDim2.fromOffset(p.pad, centre - MenuLayout.Config.Touch / 2)
			titleBar.Size = UDim2.new(1, -p.pad * 2, 0, MenuLayout.Config.Touch)
			if banner then
				banner.Size = UDim2.new(1, 0, 0, p.header)
			end
			local size = MenuKit.titleSize(p.short)
			modal.title.TextSize = size
			local iconSize = MenuKit.iconSize(p.short)
			local ic = icon
			if ic then
				ic.Size = UDim2.fromOffset(iconSize, iconSize)
			end
			if closePlate then
				local plateSize = if p.short then 34 else 38
				closePlate.Size = UDim2.fromOffset(plateSize, plateSize)
			end
			local titleX = if ic then iconSize + 4 else 0
			modal.title.Position = UDim2.new(0, titleX, 0.5, 0)
			modal.title.Size = UDim2.new(0, MenuKit.textWidth(modal.title.Text, size, Enum.Font.LuckiestGuy) + 8, 1, 0)
		end,
	}
	return out
end

-- The title row's measures by screen: its middle (under the rim's top edge),
-- the title's size and the icon's.
function MenuKit.titleCentre(short: boolean): number
	-- A short screen's lift is small (MenuLayout.LiftShort): its row sits
	-- lower, the close alone riding the rim, its keyline inside the panel.
	return if short then 14 else 8
end

function MenuKit.titleSize(short: boolean): number
	return if short then LOOK.TitleSizeShort else LOOK.TitleSize
end

function MenuKit.iconSize(short: boolean): number
	return if short then 28 else 34
end

-- The title's footprint in the header row (icon + words), for MenuLayout.pack.
function MenuKit.titleWidth(m: Modal, short: boolean): number
	local size = MenuKit.titleSize(short)
	local iconSize = MenuKit.iconSize(short)
	local words = MenuKit.textWidth(m.modal.title.Text, size, Enum.Font.LuckiestGuy) + 8
	return (if m.icon then iconSize + 4 else 0) + words
end

--==============================================================================
-- A BUTTON: a 44-px target (or whatever it is given) round a smaller plate
--==============================================================================
export type Button = {
	hit: TextButton,
	plate: Frame,
	tint: UIGradient,
	edge: UIStroke,
	label: TextLabel,
	studs: Frame?,
	style: (string) -> (),
	set: (string) -> (),
	face: () -> string,
}

export type ButtonOptions = {
	-- Raised studs on the action faces (go, sky, claim, danger, premium): for a
	-- primary call to action, never a row of small controls.
	studs: boolean?,
}

function MenuKit.button(parent: Instance, name: string, z: number, text: string?, textSize: number?,
	options: ButtonOptions?): Button
	local hit = Instance.new("TextButton")
	hit.Name = name
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.ZIndex = z
	hit.Parent = parent
	local plate = MenuKit.frame(hit, "Plate", z + 1, WHITE, 0, 10)
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.5)
	plate.Size = UDim2.new(1, 0, 1, -8)
	local tint = UIKit.gradient(plate, LOOK.CatTop, LOOK.CatBottom)
	local edge = MenuKit.keyline(plate, LOOK.CatEdge, 2)
	edge.LineJoinMode = Enum.LineJoinMode.Round
	local studs: Frame? = nil
	if options and options.studs then
		studs = UIKit.studs(plate, {
			pitch = LOOK.StudPitch,
			size = LOOK.StudSize,
			face = WHITE,
			shade = LOOK.Ink,
			inset = 6,
			insetTop = 4,
			insetBottom = 8,
			zIndex = z + 1,
		})
	end
	-- In the lit face, above the foot.
	local label = MenuKit.text(plate, "Label", textSize or 15, WHITE, z + 2)
	label.Size = UDim2.new(1, -10, 1 - LOOK.FootShare, 0)
	label.Position = UDim2.fromOffset(5, 1)
	label.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = textSize or 15
	fit.MinTextSize = 9
	fit.Parent = label
	label.Text = text or ""
	local current = "idle"
	local scale = Instance.new("UIScale")
	scale.Parent = plate
	UIKit.cardPop(hit, scale, {
		hoverScale = 1.04,
		pressScale = 0.95,
		sound = false,
		active = function(): boolean
			return not STILL[current]
		end,
	})
	local function style(id: string)
		current = if STYLES[id] then id else "idle"
		local s = STYLES[current]
		tint.Color = MenuKit.faceColours(s[1], s[2], s[3])
		edge.Color = s[3]
		label.TextColor3 = s[4]
		local field = studs
		if field then
			field.Visible = STUDDED[current] == true
			-- Opaque, in the face's own colours: a lighter top over a darker bevel,
			-- so a stud reads raised, never as a hole.
			UIKit.paintStuds(field, s[1]:Lerp(s[2], 0.45):Lerp(WHITE, 0.16), s[2]:Lerp(s[3], 0.3))
		end
	end
	style("idle")
	return {
		hit = hit,
		plate = plate,
		tint = tint,
		edge = edge,
		label = label,
		studs = studs,
		style = style,
		set = function(t: string)
			label.Text = t
		end,
		face = function(): string
			return current
		end,
	}
end

--==============================================================================
-- ONE PRESS, ONE ACTION
--
-- InventoryPanel's rule, for any button in a list that scrolls: a touch that
-- moves past PressGesture's slop, or under which the list moves, is a scroll
-- and never presses the button. A mouse click and a controller's A (Activated
-- with no press under way) press once. Answers a function that forgets the
-- press, for a list being rebuilt.
--==============================================================================
function MenuKit.tap(button: GuiButton, scroller: ScrollingFrame?, onTap: (by: string) -> (), exclude: GuiObject?)
	local press: PressGesture.Press? = nil
	local handled = false
	local lastEnded = 0
	local function canvas(): Vector2
		return if scroller then scroller.CanvasPosition else Vector2.zero
	end
	button.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		local by = if kind == Enum.UserInputType.Touch then "touch"
			elseif kind == Enum.UserInputType.MouseButton1 then "mouse"
			else nil
		if not by then
			return
		end
		-- A press on a button standing on this one (a card's BUY) is that button's.
		local other = exclude
		if other and other.Visible then
			local at, size = other.AbsolutePosition, other.AbsoluteSize
			local x, y = input.Position.X, input.Position.Y
			if x >= at.X and x <= at.X + size.X and y >= at.Y and y <= at.Y + size.Y then
				press = nil
				return
			end
		end
		press = PressGesture.begin(by, Vector2.new(input.Position.X, input.Position.Y), canvas(), os.clock(), false)
		handled = false
	end)
	button.InputChanged:Connect(function(input: InputObject)
		local p = press
		if not p or handled then
			return
		end
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseMovement then
			PressGesture.step(p, Vector2.new(input.Position.X, input.Position.Y), canvas(), os.clock())
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local p = press
		press = nil
		if not p then
			return
		end
		lastEnded = os.clock()
		if handled then
			return
		end
		handled = true
		-- A long hold on a tap target is still a tap: only a scroll is not.
		local state = PressGesture.step(p, Vector2.new(input.Position.X, input.Position.Y), canvas(), os.clock())
		if state == "scroll" then
			return
		end
		if p.by == "mouse" and (Vector2.new(input.Position.X, input.Position.Y) - p.at).Magnitude > PressGesture.Slop then
			return
		end
		onTap(p.by)
	end)
	button.Activated:Connect(function()
		local p = press
		if p then
			if handled then
				return
			end
			local state = PressGesture.step(p, nil, canvas(), os.clock())
			if state == "scroll" then
				return
			end
			handled = true
			onTap(p.by)
			return
		end
		-- No press under way: a controller's A or Enter, unless one just ended.
		if os.clock() - lastEnded < 0.15 then
			return
		end
		onTap("pad")
	end)
end

--==============================================================================
-- B, AND THE BUMPERS, WHILE A SHEET OR A LIST IS UP
--==============================================================================
function MenuKit.bindBack(name: string, fn: () -> ())
	ContextActionService:BindActionAtPriority(name, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			fn()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.ButtonB)
end

function MenuKit.unbind(name: string)
	ContextActionService:UnbindAction(name)
end

function MenuKit.bindBumpers(name: string, fn: (step: number) -> ())
	ContextActionService:BindActionAtPriority(name, function(_, state: Enum.UserInputState, input: InputObject)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		fn(if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1)
		return Enum.ContextActionResult.Sink
	end, false, 2600, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
end

function MenuKit.onPad(): boolean
	return UserInputService.GamepadEnabled and (UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil)
end

--==============================================================================
-- THE SEARCH BOX
--==============================================================================
export type Search = {
	frame: Frame,
	box: TextBox,
	clear: TextButton,
	changed: (fn: (string) -> ()) -> (),
	set: (string) -> (),
}

function MenuKit.search(parent: Instance, z: number, placeholder: string): Search
	local frame = MenuKit.frame(parent, "Search", z, L.Well, L.WellTransparency, 9)
	frame.Active = true
	MenuKit.keyline(frame, L.WellEdge, 1)
	local glass = MenuKit.frame(frame, "Glass", z + 1)
	glass.AnchorPoint = Vector2.new(0, 0.5)
	glass.Position = UDim2.new(0, 9, 0.5, 0)
	glass.Size = UDim2.fromOffset(14, 14)
	local ring = UIKit.piece(glass, "Ring", 0.42, 0.42, 0.66, 0.66, L.Placeholder, 0.5, nil, 1)
	ring.BackgroundTransparency = 1
	MenuKit.keyline(ring, L.Placeholder, 2)
	UIKit.piece(glass, "Handle", 0.80, 0.80, 0.16, 0.42, L.Placeholder, 0.5, -45, 1)
	for _, d in ipairs(glass:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = z + 1
		end
	end
	local box = Instance.new("TextBox")
	box.Name = "Box"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = LOOK.BodyFont
	box.TextSize = 15
	box.TextColor3 = L.Text
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = L.Placeholder
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.Text = ""
	box.Position = UDim2.fromOffset(28, 0)
	box.Size = UDim2.new(1, -28 - 8, 1, 0)
	box.ZIndex = z + 1
	box.Parent = frame
	local clear = Instance.new("TextButton")
	clear.Name = "Clear"
	clear.AnchorPoint = Vector2.new(1, 0.5)
	clear.Position = UDim2.new(1, 0, 0.5, 0)
	clear.Size = UDim2.new(0, 30, 1, 0)
	clear.BackgroundTransparency = 1
	clear.Font = Enum.Font.FredokaOne
	clear.TextSize = 13
	clear.TextColor3 = L.Placeholder
	-- U+2716, which the HUD's fonts carry (U+2715 draws as a box).
	clear.Text = "\u{2716}"
	clear.Visible = false
	clear.ZIndex = z + 2
	clear.Parent = frame
	local listeners: { (string) -> () } = {}
	local function fitBox()
		box.Size = UDim2.new(1, -28 - (if clear.Visible then 30 else 8), 1, 0)
	end
	box:GetPropertyChangedSignal("Text"):Connect(function()
		clear.Visible = box.Text ~= ""
		fitBox()
		for _, fn in ipairs(listeners) do
			fn(box.Text)
		end
	end)
	clear.Activated:Connect(function()
		SoundKit.play("CardClick")
		box.Text = ""
	end)
	return {
		frame = frame,
		box = box,
		clear = clear,
		changed = function(fn: (string) -> ())
			table.insert(listeners, fn)
		end,
		set = function(t: string)
			box.Text = t
		end,
	}
end

--==============================================================================
-- THE SEGMENTED SWITCH (All / Grown / Missing)
--==============================================================================
export type Segmented = {
	frame: Frame,
	buttons: { [string]: TextButton },
	set: (string) -> (),
	changed: (fn: (string) -> ()) -> (),
	value: () -> string,
}

function MenuKit.segmented(parent: Instance, z: number, ids: { string }, labels: { [string]: string }): Segmented
	local frame = MenuKit.frame(parent, "Filter", z, L.Well, L.WellTransparency, 9)
	frame.Active = true
	MenuKit.keyline(frame, L.WellEdge, 1)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = frame
	local current = ids[1]
	local buttons: { [string]: TextButton } = {}
	local plates: { [string]: Frame } = {}
	local words: { [string]: TextLabel } = {}
	local listeners: { (string) -> () } = {}
	local function paint()
		for _, id in ipairs(ids) do
			local on = id == current
			plates[id].Visible = on
			words[id].TextColor3 = if on then LOOK.CatTextOn else LOOK.CatText
		end
	end
	for i, id in ipairs(ids) do
		local b = Instance.new("TextButton")
		b.Name = "Seg" .. id
		b.LayoutOrder = i
		b.Size = UDim2.new(1 / #ids, 0, 1, 0)
		b.BackgroundTransparency = 1
		b.AutoButtonColor = false
		b.Text = ""
		b.ZIndex = z + 1
		b.Parent = frame
		local plate = MenuKit.frame(b, "On", z + 1, WHITE, 0, 7)
		plate.AnchorPoint = Vector2.new(0.5, 0.5)
		plate.Position = UDim2.fromScale(0.5, 0.5)
		plate.Size = UDim2.new(1, -6, 1, -6)
		UIKit.gradient(plate, LOOK.CatOnTop, LOOK.CatOnBottom)
		MenuKit.keyline(plate, LOOK.CatOnEdge, 1)
		local word = MenuKit.text(b, "Label", 14, LOOK.CatText, z + 2)
		word.Size = UDim2.new(1, -6, 1, 0)
		word.Position = UDim2.fromOffset(3, 0)
		word.TextScaled = true
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = 14
		fit.MinTextSize = 10
		fit.Parent = word
		word.Text = labels[id] or id
		buttons[id] = b
		plates[id] = plate
		words[id] = word
		b.Activated:Connect(function()
			if current ~= id then
				current = id
				SoundKit.play("CardClick")
				paint()
				for _, fn in ipairs(listeners) do
					fn(id)
				end
			end
		end)
	end
	paint()
	return {
		frame = frame,
		buttons = buttons,
		set = function(id: string)
			current = id
			paint()
		end,
		changed = function(fn: (string) -> ())
			table.insert(listeners, fn)
		end,
		value = function(): string
			return current
		end,
	}
end

--==============================================================================
-- THE CHOOSER: a sidebar column, or a dropdown and its list
--==============================================================================
export type ChooserItem = {
	id: string,
	label: string,
	-- An uploaded picture, or a glyph the item already used (the biomes' own).
	icon: string?,
	fallback: string?,
	glyph: string?,
	count: string?,
	-- A gold dot: something waits there (a harvest to claim).
	dot: boolean?,
}

export type Chooser = {
	setItems: ({ ChooserItem }) -> (),
	setSelected: (string) -> (),
	selected: () -> string?,
	-- The sidebar column (shown in sidebar mode), the dropdown button.
	column: Frame,
	dropdown: TextButton,
	setMode: (sidebar: boolean) -> (),
	layoutColumn: (rect: MenuLayout.Rect, rowH: number) -> (),
	layoutDropdown: (rect: MenuLayout.Rect) -> (),
	close: () -> (),
	isOpen: () -> boolean,
	rowFor: (string) -> GuiObject?,
	-- A line under the sidebar's rows and the list's (the Index's total).
	setFooter: (string?, number?) -> (),
}

type Row = {
	button: TextButton,
	tint: UIGradient,
	edge: UIStroke,
	mark: Frame,
	label: TextLabel,
	count: TextLabel,
	dot: Frame,
	icon: GuiObject?,
}

local function buildRow(parent: Instance, z: number, item: ChooserItem, order: number): Row
	local b = Instance.new("TextButton")
	b.Name = "Row" .. item.id
	b.LayoutOrder = order
	b.BackgroundColor3 = WHITE
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.ZIndex = z
	b.Parent = parent
	UIKit.corner(b, 9)
	local edge = MenuKit.keyline(b, LOOK.CatEdge, 1)
	local tint = UIKit.gradient(b, LOOK.CatTop, LOOK.CatBottom)
	local mark = MenuKit.frame(b, "Mark", z + 2, LOOK.CatMark, 0, 2)
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Position = UDim2.new(0, 3, 0.5, 0)
	mark.Size = UDim2.new(0, 3, 1, -14)
	mark.Visible = false
	local x = 10
	local icon: GuiObject? = nil
	if item.icon and item.icon ~= "" then
		local pic = MenuKit.picture(b, item.icon, item.fallback, z + 1)
		pic.AnchorPoint = Vector2.new(0, 0.5)
		pic.Position = UDim2.new(0, x, 0.5, 0)
		pic.Size = UDim2.fromOffset(20, 20)
		icon = pic
		x += 26
	elseif item.glyph and item.glyph ~= "" then
		local g = MenuKit.text(b, "Glyph", 15, WHITE, z + 1)
		g.AnchorPoint = Vector2.new(0, 0.5)
		g.Position = UDim2.new(0, x, 0.5, 0)
		g.Size = UDim2.fromOffset(20, 20)
		g.Text = item.glyph
		icon = g
		x += 26
	end
	local label = MenuKit.text(b, "Label", 15, LOOK.CatText, z + 1)
	label.Position = UDim2.fromOffset(x, 0)
	label.Size = UDim2.new(1, -x - 44, 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 15
	fit.MinTextSize = 10
	fit.Parent = label
	label.Text = item.label
	local count = MenuKit.text(b, "Count", 12, L.Cream, z + 2)
	count.AnchorPoint = Vector2.new(1, 0.5)
	count.Position = UDim2.new(1, -6, 0.5, 0)
	count.Size = UDim2.fromOffset(0, 18)
	count.AutomaticSize = Enum.AutomaticSize.X
	count.BackgroundColor3 = LOOK.Count
	count.BackgroundTransparency = LOOK.CountTransparency
	UIKit.corner(count, 9)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 5)
	pad.Parent = count
	local dot = MenuKit.frame(b, "Ready", z + 3, L.Gold, 0, 5)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -3, 0, 4)
	dot.Size = UDim2.fromOffset(10, 10)
	MenuKit.keyline(dot, L.Ink, 1.5)
	dot.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = b
	UIKit.cardPop(b, scale, { hoverScale = 1.03, pressScale = 0.97, sound = false })
	return { button = b, tint = tint, edge = edge, mark = mark, label = label, count = count, dot = dot, icon = icon }
end

local CAT_ON = ColorSequence.new(LOOK.CatOnTop, LOOK.CatOnBottom)
local CAT_OFF = ColorSequence.new(LOOK.CatTop, LOOK.CatBottom)

local function paintRow(row: Row, item: ChooserItem, on: boolean)
	row.tint.Color = if on then CAT_ON else CAT_OFF
	row.edge.Color = if on then LOOK.CatOnEdge else LOOK.CatEdge
	row.label.TextColor3 = if on then LOOK.CatTextOn else LOOK.CatText
	row.mark.Visible = on
	row.label.Text = item.label
	row.count.Text = item.count or ""
	row.count.Visible = (item.count or "") ~= ""
	row.dot.Visible = item.dot == true
end

function MenuKit.chooser(gui: ScreenGui, parent: Instance, z: number, onPick: (string) -> ()): Chooser
	local items: { ChooserItem } = {}
	local current: string? = nil
	local sidebarMode = false

	-- THE SIDEBAR COLUMN
	local column = MenuKit.frame(parent, "Sidebar", z)
	local columnList = Instance.new("UIListLayout")
	columnList.SortOrder = Enum.SortOrder.LayoutOrder
	columnList.Padding = UDim.new(0, 4)
	columnList.Parent = column
	local columnRows: { [string]: Row } = {}
	local footer = MenuKit.body(column, "Footer", 12, L.Muted, z + 1)
	footer.LayoutOrder = 1000
	footer.Size = UDim2.new(1, 0, 0, 30)
	footer.TextWrapped = true
	footer.TextXAlignment = Enum.TextXAlignment.Left
	footer.Visible = false
	local footerBar = MenuKit.frame(column, "FooterBar", z + 1, L.Bar, 0, 3)
	footerBar.LayoutOrder = 1001
	footerBar.Size = UDim2.new(1, -4, 0, 6)
	footerBar.Visible = false
	local footerFill = MenuKit.frame(footerBar, "Fill", z + 2, L.Green, 0, 3)
	footerFill.Size = UDim2.fromScale(0, 1)

	-- THE DROPDOWN BUTTON
	local dropdown = Instance.new("TextButton")
	dropdown.Name = "Dropdown"
	dropdown.BackgroundTransparency = 1
	dropdown.AutoButtonColor = false
	dropdown.Text = ""
	dropdown.ZIndex = z
	dropdown.Parent = parent
	local face = MenuKit.frame(dropdown, "Face", z + 1, WHITE, 0, 9)
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.new(1, 0, 1, -8)
	UIKit.gradient(face, LOOK.CatOnTop, LOOK.CatOnBottom)
	MenuKit.keyline(face, LOOK.CatOnEdge, 1)
	local faceGlyph = MenuKit.text(face, "Glyph", 15, WHITE, z + 2)
	faceGlyph.AnchorPoint = Vector2.new(0, 0.5)
	faceGlyph.Position = UDim2.new(0, 8, 0.5, 0)
	faceGlyph.Size = UDim2.fromOffset(20, 20)
	local facePic: GuiObject? = nil
	local faceLabel = MenuKit.text(face, "Label", 15, LOOK.CatTextOn, z + 2)
	faceLabel.TextXAlignment = Enum.TextXAlignment.Left
	faceLabel.TextScaled = true
	local faceFit = Instance.new("UITextSizeConstraint")
	faceFit.MaxTextSize = 15
	faceFit.MinTextSize = 10
	faceFit.Parent = faceLabel
	local chevron = MenuKit.chevron(face, 12, LOOK.CatTextOn, z + 2)
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -9, 0.5, 0)
	local faceDot = MenuKit.frame(dropdown, "Ready", z + 3, L.Gold, 0, 5)
	faceDot.AnchorPoint = Vector2.new(0.5, 0.5)
	faceDot.Position = UDim2.new(1, -3, 0, 7)
	faceDot.Size = UDim2.fromOffset(10, 10)
	MenuKit.keyline(faceDot, L.Ink, 1.5)
	faceDot.Visible = false
	UIKit.clicks(dropdown)

	-- THE LIST: over everything in the panel, with a backdrop that takes the
	-- outside tap (so it never reaches the panel's dimmer).
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "ChooserBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundTransparency = 1
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.Selectable = false
	backdrop.Visible = false
	backdrop.ZIndex = 84
	backdrop.Parent = gui
	local popup = Instance.new("ScrollingFrame")
	popup.Name = "ChooserList"
	popup.BackgroundColor3 = L.Sheet
	popup.BorderSizePixel = 0
	popup.ScrollBarThickness = 4
	popup.ScrollBarImageColor3 = L.WellEdge
	popup.CanvasSize = UDim2.new()
	popup.AutomaticCanvasSize = Enum.AutomaticSize.Y
	popup.Visible = false
	popup.ZIndex = 85
	popup.Selectable = false
	popup.SelectionGroup = true
	popup.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	popup.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	popup.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	popup.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	popup.Parent = gui
	UIKit.corner(popup, 10)
	MenuKit.keyline(popup, L.SheetEdge, 1.5, 0.15)
	local popupPad = Instance.new("UIPadding")
	popupPad.PaddingLeft = UDim.new(0, 6)
	popupPad.PaddingRight = UDim.new(0, 8)
	popupPad.PaddingTop = UDim.new(0, 6)
	popupPad.PaddingBottom = UDim.new(0, 6)
	popupPad.Parent = popup
	local popupList = Instance.new("UIListLayout")
	popupList.SortOrder = Enum.SortOrder.LayoutOrder
	popupList.Padding = UDim.new(0, 4)
	popupList.Parent = popup
	local popupRows: { [string]: Row } = {}
	local popupFooter = MenuKit.body(popup, "Footer", 12, L.Muted, 86)
	popupFooter.LayoutOrder = 1000
	popupFooter.Size = UDim2.new(1, 0, 0, 22)
	popupFooter.TextXAlignment = Enum.TextXAlignment.Left
	popupFooter.Visible = false

	local backName = "SeedMenuChooser" .. gui.Name
	local function close()
		if not popup.Visible then
			return
		end
		popup.Visible = false
		backdrop.Visible = false
		MenuKit.unbind(backName)
		local sel = GuiService.SelectedObject
		if sel and sel:IsDescendantOf(popup) then
			GuiService.SelectedObject = if dropdown.Visible then dropdown else nil
		end
	end

	local function pick(id: string)
		close()
		if current ~= id then
			current = id
			onPick(id)
		end
	end

	local function rowsIn(list: { [string]: Row }, holder: Instance, rowZ: number, height: number)
		for id, row in pairs(list) do
			local keep = false
			for _, item in ipairs(items) do
				if item.id == id then
					keep = true
				end
			end
			if not keep then
				row.button:Destroy()
				list[id] = nil
			end
		end
		for i, item in ipairs(items) do
			local row = list[item.id]
			if not row then
				local made = buildRow(holder, rowZ, item, i)
				list[item.id] = made
				row = made
				local id = item.id
				made.button.Activated:Connect(function()
					SoundKit.play("CardClick")
					pick(id)
				end)
			end
			local r = row :: Row
			r.button.LayoutOrder = i
			r.button.Size = UDim2.new(1, 0, 0, height)
			paintRow(r, item, item.id == current)
		end
	end

	local columnRowH = 44
	local function paint()
		rowsIn(columnRows, column, z + 1, columnRowH)
		rowsIn(popupRows, popup, 86, 40)
		local item: ChooserItem? = nil
		local otherDot = false
		for _, it in ipairs(items) do
			if it.id == current then
				item = it
			elseif it.dot then
				otherDot = true
			end
		end
		faceDot.Visible = otherDot or (item ~= nil and (item :: ChooserItem).dot == true)
		local x = 8
		-- The face's picture is kept while it shows the same image, so a repaint
		-- never makes it load again.
		local want = if item and item.icon and item.icon ~= "" then item.icon else nil
		local shown = facePic and facePic:GetAttribute("Image")
		if facePic and shown ~= want then
			facePic:Destroy()
			facePic = nil
		end
		faceGlyph.Visible = false
		if item then
			local it = item :: ChooserItem
			if it.icon and it.icon ~= "" then
				if not facePic then
					local p = MenuKit.picture(face, it.icon, it.fallback, z + 2)
					p.AnchorPoint = Vector2.new(0, 0.5)
					p.Position = UDim2.new(0, x, 0.5, 0)
					p.Size = UDim2.fromOffset(20, 20)
					p:SetAttribute("Image", it.icon)
					facePic = p
				end
				x += 26
			elseif it.glyph and it.glyph ~= "" then
				faceGlyph.Text = it.glyph
				faceGlyph.Visible = true
				x += 26
			end
			-- The name alone: its count is on the progress row, and a phone's
			-- dropdown is narrow.
			faceLabel.Text = it.label
		end
		faceLabel.Position = UDim2.fromOffset(x, 0)
		faceLabel.Size = UDim2.new(1, -x - 26, 1, 0)
	end

	local function open()
		if popup.Visible then
			close()
			return
		end
		local k = UIKit.scaleOf(gui)
		local at, size = dropdown.AbsolutePosition / k, dropdown.AbsoluteSize / k
		local screen = gui.AbsoluteSize / k
		local width = math.max(size.X, 200)
		local want = #items * 44 + 12 + (if popupFooter.Visible then 26 else 0)
		local top = at.Y + size.Y - 2
		local room = screen.Y - top - 8
		local height = math.min(want, math.max(120, room))
		if room < 120 then
			top = math.max(8, screen.Y - 8 - height)
		end
		popup.Position = UDim2.fromOffset(math.clamp(at.X, 8, math.max(8, screen.X - 8 - width)), top)
		popup.Size = UDim2.fromOffset(width, height)
		backdrop.Visible = true
		popup.Visible = true
		MenuKit.bindBack(backName, close)
		if MenuKit.onPad() then
			local row = current and popupRows[current :: string]
			GuiService.SelectedObject = if row then row.button else nil
		end
	end
	dropdown.Activated:Connect(open)
	backdrop.Activated:Connect(close)

	return {
		setItems = function(list: { ChooserItem })
			items = list
			paint()
		end,
		setSelected = function(id: string)
			current = id
			paint()
		end,
		selected = function(): string?
			return current
		end,
		column = column,
		dropdown = dropdown,
		setMode = function(sidebar: boolean)
			sidebarMode = sidebar
			column.Visible = sidebar
			dropdown.Visible = not sidebar
			if sidebar then
				close()
			end
		end,
		layoutColumn = function(rect: MenuLayout.Rect, rowH: number)
			column.Position = UDim2.fromOffset(rect.x, rect.y)
			column.Size = UDim2.fromOffset(rect.w, rect.h)
			if rowH ~= columnRowH then
				columnRowH = rowH
				paint()
			end
		end,
		layoutDropdown = function(rect: MenuLayout.Rect)
			dropdown.Position = UDim2.fromOffset(rect.x, rect.y)
			dropdown.Size = UDim2.fromOffset(rect.w, rect.h)
		end,
		close = close,
		isOpen = function(): boolean
			return popup.Visible
		end,
		rowFor = function(id: string): GuiObject?
			if sidebarMode then
				local row = columnRows[id]
				return if row then row.button else nil
			end
			return dropdown
		end,
		setFooter = function(text: string?, fill: number?)
			footer.Visible = text ~= nil
			popupFooter.Visible = text ~= nil
			footer.Text = text or ""
			popupFooter.Text = text or ""
			footerBar.Visible = text ~= nil and fill ~= nil
			footerFill.Size = UDim2.fromScale(math.clamp(fill or 0, 0, 1), 1)
		end,
	}
end

return MenuKit
