--!strict
-- Steal a Seed :: InviteUI (2026-10-06, the owner's Invite a Friend)
--
-- THE INVITE BUTTON, ITS "!", THE INVITE PANEL, AND WHAT THE TRACK SAYS.
--
--   THE BUTTON  the owner's picture (GameConfig.Rail.StuddedInviteArt; measured
--               square, so every screen draws it, as Index), with
--               UIKit.railPicture where HudLayout puts INVITE (`invite`): the
--               rail's top row on a desktop and a TV; under the row in compact,
--               stepping aside while a centre panel is open, as EVENTS does, and
--               hidden where no spot clears; the FIRST square of the panel under
--               the Bag on a phone, in its scrolling canvas (a tap presses it, a
--               drag scrolls the panel).
--   THE "!"     not a red circle: a bold "!" in gold with a thick ink line
--               (GameConfig.Rail.InviteBadge), in the box HudLayout.inviteBadge
--               gives -- the size and the corner every badge has; on a phone's
--               panel the handle's smaller size, never cut by its edge -- and a small
--               wiggle every PulseEvery seconds while it shows (decoration: it
--               stands right without it, and never moves under reduced motion).
--               It shows while the server's InviteSeen is false -- never opened,
--               or a form given since the last open. Opening the panel takes it
--               off at once and tells the server (OpenedAction), which saves the
--               flag. On a phone's shut panel the handle wears it
--               (UIKit.dockBadge); scrolled so far it would be cut, the panel
--               pins it to its top edge (RailDrawerUI, PinAttribute) and this
--               one hides. invite_badge_pop only when it comes up for a
--               form given while playing: never on join, never for the first call.
--   THE PANEL   MenuKit's modal, the Shop's and the Index's sibling: INVITE
--               FRIENDS by the invite picture, the red close; MenuLayout
--               .invitePanel and .inviteBlocks over the studded baseplate. The
--               hero (this player's form turning and idling in a ViewportFrame;
--               Dustthorn as the goal at 0), the studded bar, NEXT or FINAL FORM
--               REACHED with the gold trim, the track of four cards (EARNED with
--               its tick and CLAIMED, NEXT with a breathing rim, LOCKED as a
--               silhouette; Heliothorn's gold rim always), INVITE FRIENDS
--               (InviteSend: Roblox's own dialog) and its line. Live while open:
--               the bar fills (a tick a friend, InviteSounds' rules), a form
--               given flips its card to CLAIMED with a burst. On the OpenPanel
--               mutex: B (PadFocus), the close, Escape and Backspace (bound only
--               while it is open) and the Roblox menu shut it. A controller starts
--               on INVITE FRIENDS; left and right walk the cards.
--   THE NOTICES what InviteService says (InviteNews), worded by
--               InviteRewards.notice: +1 INVITE ("<name> joined! 3/5") with
--               invite_friend_joined (another soon after is the same notice,
--               refreshed, silent); a friend who joined and did not count; the
--               invited friend's WELCOME! ("You joined from <name>'s invite")
--               with invite_welcome; PLANT STORAGE FULL. WHILE YOU WERE AWAY and
--               a form given are the reward card queue's (InviteRewardUI).
--
-- Every number it shows is the server's -- the InviteCount, InviteGranted and
-- InviteSeen attributes -- through InviteRewards: it never counts, never picks a
-- form of its own, never grants. Never pressed from a tool: INVITE FRIENDS opens
-- Roblox's real invite dialog.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SecretIdle = require(Shared:WaitForChild("SecretIdle"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local Notice = require(Shared:WaitForChild("Notice"))
local InviteRewards = require(Shared:WaitForChild("InviteRewards"))
local InviteSend = require(Shared:WaitForChild("InviteSend"))
local InviteSounds = require(Shared:WaitForChild("InviteSounds"))
local InviteNews = require(Shared:WaitForChild("InviteNews"))

local CONFIG = GameConfig.InviteRewards
if not CONFIG.Enabled then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local A = CONFIG.Attributes
local WORDS = CONFIG.Words
local PANEL = CONFIG.Panel
local ATTR = GameConfig.Attributes
local RAIL = GameConfig.Rail
local BANG = RAIL.InviteBadge
local CARD = GameConfig.Card
local LOOK = MenuKit.Look
local I = MenuLayout.Invite
local PANEL_NAME = "Invite"
local CLOSE_ACTION = "SeedInviteClose"
-- Raised while the phone panel shows INVITE's "!" pinned to its top edge.
local PIN = HudLayout.Config.Phone.Panel.PinAttribute

local WHITE = Color3.fromRGB(255, 255, 255)
-- ZIndexBehavior is GLOBAL on this ScreenGui: the modal's chrome is under 6.
local Z = 6

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedInvite")
if existing then
	existing:Destroy()
end
ContextActionService:UnbindAction(CLOSE_ACTION)

local gui = Instance.new("ScreenGui")
gui.Name = "SeedInvite"
gui.ResetOnSpawn = false
gui.DisplayOrder = 32
gui.Parent = playerGui

local state = {
	open = false,
	-- The "!": whether it shows, the forms given when it was last off (or when
	-- the numbers first came), whether they have come, and when.
	badgeShown = false,
	badgeBase = 0,
	badgeReady = false,
	readyAt = 0,
	-- The forms given when the panel was last opened here: the "!" stays off
	-- until a later one, before the server's flag arrives.
	openedAt = nil :: number?,
	-- The friends counted when the numbers last changed (the bar's ticks).
	lastCount = nil :: number?,
}

local channel: RemoteEvent? = nil
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 30)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 30) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	end
end)

-- The panel has shown this player their forms: the server saves the "!" off
-- (OpenedAction, InviteService.MarkSeen). Asked only while the flag is up.
local function markSeen()
	local remote = channel
	if remote and player:GetAttribute(A.Seen) ~= true then
		remote:FireServer(CONFIG.OpenedAction)
	end
end

local function hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end

-- A label that scales its words into its box, never under `min` drawn.
local function fitText(label: TextLabel, max: number, min: number)
	label.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = math.max(min, max)
	fit.MinTextSize = min
	fit.Parent = label
end

local function setFit(label: TextLabel, max: number)
	local fit = label:FindFirstChildOfClass("UITextSizeConstraint")
	if fit then
		fit.MaxTextSize = math.max(fit.MinTextSize, math.floor(max))
	end
end

local function place(object: GuiObject, r: MenuLayout.Rect)
	object.Position = UDim2.fromOffset(r.x, r.y)
	object.Size = UDim2.fromOffset(r.w, r.h)
end

--==============================================================================
-- THE BUTTON AND ITS "!"
--==============================================================================
-- INVITE on a plate until the picture has loaded here (UIKit.railFallback).
local button = UIKit.railButton(playerGui, { name = "InviteButton", art = RAIL.StuddedInviteArt,
	fallback = RAIL.Words.Invite })
button.Visible = false

local bang = Instance.new("TextLabel")
bang.Name = "InviteBadge"
bang.AnchorPoint = Vector2.new(0.5, 0.5)
bang.BackgroundTransparency = 1
bang.BorderSizePixel = 0
bang.Font = BANG.Font
bang.Text = BANG.Glyph
bang.TextColor3 = BANG.Fill
bang.TextScaled = true
bang.Active = false
bang.ZIndex = 8
bang.Visible = false
bang.Parent = button
do
	local ink = Instance.new("UIStroke")
	ink.Name = "Ink"
	ink.Color = BANG.Ink
	ink.Thickness = BANG.Stroke
	ink.LineJoinMode = Enum.LineJoinMode.Round
	ink.Parent = bang
end

-- From HudLayout, and the "!" in the box HudLayout.inviteBadge gives, relative
-- to the button. Off a desktop an open centre panel's corner can be under it,
-- so it steps aside while OpenPanel names one, as EVENTS does. An empty rect is
-- a screen with no clear spot for it: hidden there.
local function placeButton()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = layout.invite
	local away = layout.compact and player:GetAttribute(ATTR.OpenPanel) ~= nil
	if r.w <= 0 or r.h <= 0 or away then
		button.Visible = false
		return
	end
	UIKit.railShape(button, Vector2.new(r.w, r.h))
	UIKit.railPicture(button, RAIL.StuddedInviteArt, RAIL.StuddedInviteAspect)
	UIKit.placeRail(button, layout, r, playerGui)
	local b = HudLayout.inviteBadge(layout)
	bang.Position = UDim2.fromOffset(b.x - r.x + b.w / 2, b.y - r.y + b.h / 2)
	bang.Size = UDim2.fromOffset(b.w, math.floor(b.h * BANG.Scale))
	button.Visible = true
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(placeButton)
placeButton()

-- The owner's picture, proven: preloaded on the drawn ImageLabel itself (a
-- string id reports failure; the art box's hidden copy never loads), then
-- IsLoaded asked.
task.spawn(function()
	local box = button:FindFirstChild("PictureBox")
	local picture = box and box:FindFirstChild("Picture")
	if not (picture and picture:IsA("ImageLabel")) then
		return
	end
	pcall(function()
		ContentProvider:PreloadAsync({ picture })
	end)
	if not picture.IsLoaded then
		warn("[Seed/InviteUI] the INVITE picture did not load: " .. RAIL.StuddedInviteArt)
	end
end)

-- Whether the "!" shows: the server's flag, unless the panel was opened here
-- since the last form was given.
local function badgeWanted(): boolean
	local seen, granted = player:GetAttribute(A.Seen), player:GetAttribute(A.Granted)
	if seen == nil or type(granted) ~= "number" then
		return false
	end
	local opened = state.openedAt
	if opened ~= nil and granted <= opened then
		return false
	end
	return InviteRewards.badge(seen)
end

local badgeQueued = false
local function refreshBadge()
	-- Once a frame: a grant's InviteGranted and InviteSeen arrive together.
	if badgeQueued then
		return
	end
	badgeQueued = true
	task.defer(function()
		badgeQueued = false
		local granted = player:GetAttribute(A.Granted)
		-- A form given while the panel is open is seen as it lands -- the panel
		-- shows it -- so the "!" stays off, and the server is told.
		if state.open and type(granted) == "number" and (state.openedAt or -1) < granted then
			state.openedAt = granted
			markSeen()
		end
		local want = badgeWanted()
		if not state.badgeReady then
			if type(granted) == "number" and player:GetAttribute(A.Seen) ~= nil then
				state.badgeReady = true
				state.readyAt = os.clock()
				state.badgeBase = granted
			end
		elseif want and not state.badgeShown and type(granted) == "number" and granted > state.badgeBase
			and os.clock() - state.readyAt > BANG.QuietAfterJoin then
			-- Up for a form given while playing: its pop.
			InviteSounds.play("badge")
		end
		if not want and type(granted) == "number" then
			state.badgeBase = granted
		end
		state.badgeShown = want
		-- Pinned to the phone panel's top edge while it is scrolled (RailDrawerUI,
		-- HudLayout.invitePin): the panel shows it there, so not here as well.
		bang.Visible = want and player:GetAttribute(PIN) ~= true
		if not want then
			bang.Rotation = 0
		end
		-- The phone's shut panel wears it on its handle.
		UIKit.dockBadge("Invite", if want then "bang" else nil)
	end)
end

-- The wiggle: decoration, every PulseEvery seconds while it shows.
local function wiggle()
	local each = BANG.PulseSeconds / 4
	local info = TweenInfo.new(each, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for _, k in ipairs({ 1, -0.7, 0.35, 0 }) do
		if not bang.Visible then
			break
		end
		TweenService:Create(bang, info, { Rotation = BANG.PulseDegrees * k }):Play()
		task.wait(each)
	end
	bang.Rotation = 0
end
task.spawn(function()
	while gui.Parent do
		task.wait(BANG.PulseEvery)
		if bang.Visible and button.Visible and not StatusText.reducedMotion() then
			wiggle()
		end
	end
end)

--==============================================================================
-- THE PANEL
--==============================================================================
local menu = MenuKit.modal(gui, PANEL_NAME, WORDS.Title, RAIL.StuddedInviteArt, nil)
-- This gui holds only the panel, so it takes the player's menu size whole.
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body
local close = modal.close

-- A controller's selection starts on INVITE FRIENDS (PadFocus reads this).
local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = modal.shell

local plate = MenuKit.baseplate(body, Z - 1)
local page = Instance.new("ScrollingFrame")
page.Name = "InvitePage"
page.BackgroundTransparency = 1
page.BorderSizePixel = 0
page.ScrollingDirection = Enum.ScrollingDirection.Y
page.ScrollBarThickness = 5
page.ScrollBarImageColor3 = CONFIG.Cream
page.VerticalScrollBarInset = Enum.ScrollBarInset.None
page.CanvasSize = UDim2.new()
page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
page.Selectable = false
page.ZIndex = Z
page.Parent = body

local function viewport(parent: Instance, name: string, z: number): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = name
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.new(1, -4, 1, -4)
	view.BackgroundTransparency = 1
	view.Ambient = CARD.Ambient
	view.LightColor = CARD.LightColour
	view.LightDirection = CARD.LightDirection
	view.ZIndex = z
	view.Parent = parent
	return view
end

--==============================================================================
-- THE HERO: the form this player has (Dustthorn as the goal at 0)
--==============================================================================
local heroWell = MenuKit.frame(page, "HeroWell", Z + 1, LOOK.Window, 0, 10)
heroWell.ClipsDescendants = true
MenuKit.keyline(heroWell, CONFIG.Ink, 2)
local heroView = viewport(heroWell, "Form", Z + 2)

local heroName = UIKit.outlined(page, "FormName", 30, WHITE, 2.5)
heroName.TextXAlignment = Enum.TextXAlignment.Left
heroName.ZIndex = Z + 2
fitText(heroName, 38, PANEL.MinText)
local heroRarity = MenuKit.text(page, "Rarity", 18, WHITE, Z + 2)
heroRarity.TextXAlignment = Enum.TextXAlignment.Left
fitText(heroRarity, 22, PANEL.MinText)
local heroRarityFX = RarityFX.text(heroRarity, heroRarity:FindFirstChildOfClass("UIStroke"))
local heroIncome = MenuKit.text(page, "Income", 18, CONFIG.Income, Z + 2)
heroIncome.TextXAlignment = Enum.TextXAlignment.Left
MenuKit.keepInk(heroIncome)
fitText(heroIncome, 22, PANEL.MinText)
local heroTag = MenuKit.frame(page, "Unsellable", Z + 2, CONFIG.Ink, 0.1, 8)
MenuKit.keyline(heroTag, CONFIG.Cream, 1, 0.45)
do
	local word = MenuKit.text(heroTag, "Word", 12, CONFIG.Cream, Z + 3)
	word.Size = UDim2.new(1, -8, 1, 0)
	word.Position = UDim2.fromOffset(4, 0)
	fitText(word, 13, PANEL.TinyText)
	word.Text = WORDS.Unsellable
end

type Shown = {
	form: string?,
	model: Model?,
	rig: SecretIdle.Rig?,
	camera: Camera?,
	distance: number,
	focus: Vector3,
	framed: Vector2,
}
local hero: Shown = { form = nil, model = nil, rig = nil, camera = nil, distance = 0, focus = Vector3.zero,
	framed = Vector2.zero }

--==============================================================================
-- THE BAR: chunky and studded, the next form's colour, the count on top
--==============================================================================
local bar = MenuKit.frame(page, "Bar", Z + 1, CONFIG.Ink, 0, 9)
local barTrim = MenuKit.keyline(bar, CONFIG.Gold, 3)
barTrim.Enabled = false
local barTrack = MenuKit.frame(bar, "Track", Z + 2, LOOK.PlateEdge, 0, 6)
barTrack.Position = UDim2.fromOffset(4, 4)
barTrack.Size = UDim2.new(1, -8, 1, -8)
barTrack.ClipsDescendants = true
local fill = MenuKit.frame(barTrack, "Fill", Z + 3, WHITE, 0, 6)
fill.Size = UDim2.fromScale(0, 1)
fill.ClipsDescendants = true
local barText = UIKit.outlined(bar, "Count", 18, WHITE, 2)
barText.Size = UDim2.fromScale(1, 1)
barText.ZIndex = Z + 5
fitText(barText, 22, PANEL.MinText)
local studsFor = -1

local nextLine = MenuKit.text(page, "Next", 15, CONFIG.Cream, Z + 2)
nextLine.RichText = true
MenuKit.keepInk(nextLine)
fitText(nextLine, 17, PANEL.MinText)

-- The bar's raised studs, a fixed row the fill uncovers as it grows.
local function studBar(width: number)
	if width == studsFor then
		return
	end
	studsFor = width
	for _, child in ipairs(fill:GetChildren()) do
		if child.Name == "Stud" then
			child:Destroy()
		end
	end
	local pitch = PANEL.StudPitch
	for k = 0, math.floor(width / pitch) do
		local stud = MenuKit.frame(fill, "Stud", Z + 4, WHITE, PANEL.StudTransparency, math.ceil(PANEL.StudSize / 2))
		stud.AnchorPoint = Vector2.new(0.5, 0.5)
		stud.Position = UDim2.new(0, math.floor(pitch / 2) + k * pitch, 0.5, 0)
		stud.Size = UDim2.fromOffset(PANEL.StudSize, PANEL.StudSize)
	end
end

--==============================================================================
-- THE TRACK: four cards on a road, scrolling sideways where they do not fit
--==============================================================================
local track = Instance.new("ScrollingFrame")
track.Name = "Track"
track.BackgroundTransparency = 1
track.BorderSizePixel = 0
track.ScrollingDirection = Enum.ScrollingDirection.X
track.ScrollBarThickness = 0
track.ScrollBarImageColor3 = CONFIG.Cream
track.HorizontalScrollBarInset = Enum.ScrollBarInset.None
track.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
track.CanvasSize = UDim2.new()
track.Selectable = false
track.ZIndex = Z + 1
track.Parent = page

local road = MenuKit.frame(track, "Road", Z + 1, PANEL.Road, 0, 3)
local dashesFor = -1

type CardUI = {
	holder: Frame,
	face: TextButton,
	pop: UIScale,
	edge: UIStroke,
	tint: UIGradient,
	well: Frame,
	view: ViewportFrame,
	name: TextLabel,
	rarity: TextLabel,
	rarityFX: RarityFX.Handle,
	income: TextLabel,
	needs: TextLabel,
	tick: Frame,
	claimed: Frame,
	claimedPop: UIScale,
	shake: () -> (),
	form: string,
	model: Model?,
	framed: Vector2,
	state: string?,
}
local cardUIs: { CardUI } = {}
-- The track's numbers as last laid out, for scrolling a card into view.
local trackView = { window = 0, canvas = 0, cards = {} :: { MenuLayout.Rect } }

local function showCard(i: number)
	local r = trackView.cards[i]
	if not r or trackView.canvas <= trackView.window then
		return
	end
	local x = UIKit.scrollToShow(track.CanvasPosition.X, trackView.window, r.x, r.x + r.w, trackView.canvas)
	track.CanvasPosition = Vector2.new(x, 0)
end

for i = 1, InviteRewards.Count do
	local holder = MenuKit.frame(track, "Card_" .. i, Z + 2)
	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.Selectable = true
	face.ZIndex = Z + 2
	face.Parent = holder
	UIKit.corner(face, 9)
	local tint = MenuKit.cardFace(face)
	local edge = MenuKit.keyline(face, LOOK.CardEdge, 1.5, LOOK.CardEdgeTransparency)
	edge.LineJoinMode = Enum.LineJoinMode.Round
	local pop = Instance.new("UIScale")
	pop.Parent = face
	local well = MenuKit.frame(face, "Preview", Z + 3, LOOK.Window, 0, 7)
	well.ClipsDescendants = true
	local view = viewport(well, "Form", Z + 4)
	local name = MenuKit.text(face, "Name", 14, LOOK.Text, Z + 5)
	fitText(name, 15, PANEL.MinText)
	local rarity = MenuKit.text(face, "Rarity", 13, WHITE, Z + 5)
	fitText(rarity, 13, PANEL.TinyText)
	local rarityFX = RarityFX.text(rarity, rarity:FindFirstChildOfClass("UIStroke"))
	local income = MenuKit.body(face, "Income", 13, LOOK.Money, Z + 5)
	fitText(income, 13, PANEL.TinyText)
	local needs = MenuKit.body(face, "Needs", 12, LOOK.Muted, Z + 5)
	fitText(needs, 12, PANEL.TinyText)
	-- EARNED: a green tick, top right, and CLAIMED across the picture's foot.
	local tick = MenuKit.frame(face, "Tick", Z + 7, CONFIG.Tick, 0, 11)
	MenuKit.keyline(tick, LOOK.Ink, 1.5)
	do
		local mark = MenuKit.text(tick, "Mark", 14, WHITE, Z + 8)
		mark.Size = UDim2.fromScale(1, 1)
		fitText(mark, 16, PANEL.TinyText)
		mark.Text = "\u{2713}"
	end
	local claimed = MenuKit.frame(face, "Claimed", Z + 7, LOOK.Green, 0, 6)
	MenuKit.keyline(claimed, LOOK.Ink, 1.5)
	local claimedPop = Instance.new("UIScale")
	claimedPop.Parent = claimed
	do
		local word = MenuKit.text(claimed, "Word", 12, WHITE, Z + 8)
		word.Size = UDim2.fromScale(1, 1)
		fitText(word, 13, PANEL.TinyText)
		word.Text = WORDS.Claimed
	end
	local ui: CardUI = {
		holder = holder,
		face = face,
		pop = pop,
		edge = edge,
		tint = tint,
		well = well,
		view = view,
		name = name,
		rarity = rarity,
		rarityFX = rarityFX,
		income = income,
		needs = needs,
		tick = tick,
		claimed = claimed,
		claimedPop = claimedPop,
		shake = UIKit.shake(face),
		form = InviteRewards.formOfTier(i),
		model = nil,
		framed = Vector2.zero,
		state = nil,
	}
	cardUIs[i] = ui
	-- A card is a stop for a controller and does nothing but nod when pressed.
	MenuKit.tap(face, track, function()
		ui.shake()
	end)
	face.SelectionGained:Connect(function()
		showCard(i)
	end)
end
for i, ui in ipairs(cardUIs) do
	ui.face.NextSelectionLeft = if i > 1 then cardUIs[i - 1].face else nil
	ui.face.NextSelectionRight = if i < #cardUIs then cardUIs[i + 1].face else nil
end

--==============================================================================
-- THE BUTTON AND ITS LINE
--==============================================================================
local send = MenuKit.button(page, "InviteFriends", Z + 2, WORDS.Button, 20, { studs = true })
send.style("go")
padFirst.Value = send.hit
-- A tap presses it; a drag on a page that scrolls does not. Roblox's own invite
-- dialog -- never pressed from a tool.
MenuKit.tap(send.hit, page, function()
	InviteSend.prompt()
end)
local how = MenuKit.body(page, "How", 13, CONFIG.Cream, Z + 2)
MenuKit.keepInk(how)
fitText(how, 14, PANEL.MinText)
how.Text = WORDS.Rules[1]
-- THE RULES, ONE LINE AT A TIME (2026-10-08, the owner's brief): who counts,
-- the four plants, the returning friend's spin -- each short enough for a
-- phone's line (InviteRulesSpec), turning every RulesSeconds.
task.spawn(function()
	local at = 1
	while how.Parent do
		task.wait(CONFIG.RulesSeconds)
		at = at % #WORDS.Rules + 1
		how.Text = WORDS.Rules[at]
	end
end)

--==============================================================================
-- THE FORMS IN THEIR WINDOWS
--
-- Built when the panel first opens (and the hero again when the form changes),
-- framed the way the Index frames a plant (UIKit.framePlant), and framed again
-- when a window changes size. The hero turns (its camera goes round it) and
-- idles (SecretIdle, stepped here: a viewport copy is not in the Workspace, so
-- the world's animator leaves it alone); a card stands still.
--==============================================================================
local function frameIn(view: ViewportFrame, model: Model, form: string, share: number): (Camera?, number, Vector3)
	local old = view.CurrentCamera
	if old then
		old:Destroy()
	end
	local species = SeedData.Get(form) :: any
	local camera, distance, focus = UIKit.framePlant(view, model, if species then species.Form else nil, share)
	return camera, distance, focus
end

local function buildIn(view: ViewportFrame, form: string): Model?
	for _, child in ipairs(view:GetChildren()) do
		child:Destroy()
	end
	view.CurrentCamera = nil
	local species = SeedData.Get(form)
	if not species then
		return nil
	end
	local ok, model = pcall(CreatureModel.Build, species, SeedData.InviteTier, CreatureModel.STAGE_GROWN,
		CFrame.new(), view)
	return if ok and model then model else nil
end

local function buildHero(form: string)
	hero.form = form
	hero.model = buildIn(heroView, form)
	hero.rig = nil
	hero.camera = nil
	hero.framed = Vector2.zero
	local model = hero.model
	if model then
		local ok, rig = pcall(SecretIdle.Rig, model)
		hero.rig = if ok then rig else nil
		local camera, distance, focus = frameIn(heroView, model, form, PANEL.HeroFill)
		hero.camera, hero.distance, hero.focus = camera, distance, focus
		hero.framed = heroView.AbsoluteSize
	end
end

local function buildCards()
	for _, ui in ipairs(cardUIs) do
		if not ui.model then
			ui.model = buildIn(ui.view, ui.form)
			local model = ui.model
			if model then
				frameIn(ui.view, model, ui.form, PANEL.CardFill)
				ui.framed = ui.view.AbsoluteSize
			end
		end
	end
end

-- A window that changed size is framed again.
local function reframe()
	local model = hero.model
	local form = hero.form
	if model and form and heroView.AbsoluteSize ~= hero.framed and heroView.AbsoluteSize.X > 1 then
		local camera, distance, focus = frameIn(heroView, model, form, PANEL.HeroFill)
		hero.camera, hero.distance, hero.focus = camera, distance, focus
		hero.framed = heroView.AbsoluteSize
	end
	for _, ui in ipairs(cardUIs) do
		local m = ui.model
		if m and ui.view.AbsoluteSize ~= ui.framed and ui.view.AbsoluteSize.X > 1 then
			frameIn(ui.view, m, ui.form, PANEL.CardFill)
			ui.framed = ui.view.AbsoluteSize
		end
	end
end

--==============================================================================
-- PAINT: the server's two numbers, through InviteRewards
--==============================================================================
local function burst(ui: CardUI, colour: Color3)
	ui.claimedPop.Scale = 1
	if StatusText.reducedMotion() then
		return
	end
	local seconds = PANEL.BurstSeconds
	ui.pop.Scale = 1
	TweenService:Create(ui.pop, TweenInfo.new(seconds * 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = PANEL.PopScale }):Play()
	task.delay(seconds * 0.4, function()
		TweenService:Create(ui.pop, TweenInfo.new(seconds * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = 1 }):Play()
	end)
	ui.claimedPop.Scale = 0.3
	TweenService:Create(ui.claimedPop, TweenInfo.new(seconds * 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }):Play()
	for k = 1, PANEL.BurstSparks do
		local spark = MenuKit.frame(ui.face, "Spark", Z + 9, if k % 2 == 0 then CONFIG.Gold else colour, 0, 2)
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.Position = UDim2.fromScale(0.5, 0.3)
		spark.Size = UDim2.fromOffset(7, 7)
		spark.Rotation = 45
		local a = (k / PANEL.BurstSparks) * math.pi * 2
		local d = 34 + (k % 3) * 12
		TweenService:Create(spark, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(a) * d, 0.3, math.sin(a) * d),
			Size = UDim2.fromOffset(3, 3),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(seconds, function()
			spark:Destroy()
		end)
	end
end

local function paintCard(i: number, c: InviteRewards.Card, animate: boolean)
	local ui = cardUIs[i]
	local was = ui.state
	ui.state = c.state
	local earned = c.state == "earned"
	ui.name.Text = c.name
	ui.rarity.Text = string.upper(c.rarity)
	RarityFX.setText(ui.rarityFX, c.rarity, c.colour)
	ui.income.Text = c.incomeText
	-- Its milestone -- or "owned" when the wheel gave some and which milestone
	-- gave which is not known (InviteRewards.cards).
	ui.needs.Text = if c.won then WORDS.Owned else string.format(WORDS.Needs, c.at, InviteRewards.plural(c.at))
	ui.tick.Visible = earned
	ui.claimed.Visible = earned
	-- The rim: gold for the final form at every state; the next form's colour
	-- (breathing while the panel is open); an earned form's colour; else quiet.
	if c.gold then
		ui.edge.Color, ui.edge.Thickness, ui.edge.Transparency = CONFIG.Gold, 3, 0
	elseif c.state == "next" then
		ui.edge.Color, ui.edge.Thickness, ui.edge.Transparency = c.colour, 3, 0
	elseif earned then
		ui.edge.Color, ui.edge.Thickness, ui.edge.Transparency = c.colour, 2, 0
	else
		ui.edge.Color, ui.edge.Thickness, ui.edge.Transparency = LOOK.CardEdge, 1.5, LOOK.CardEdgeTransparency
	end
	MenuKit.cardTint(ui.tint, if c.state == "locked" then nil else c.colour)
	-- LOCKED: the same model as a dark silhouette; its words still shown.
	ui.view.ImageColor3 = if c.state == "locked" then CONFIG.Silhouette else WHITE
	if animate and was ~= nil and was ~= "earned" and earned then
		burst(ui, c.colour)
	end
end

local function paint(animate: boolean)
	local count, granted = player:GetAttribute(A.Count), player:GetAttribute(A.Granted)
	if type(count) ~= "number" or type(granted) ~= "number" then
		return
	end
	-- The plants owned, wherever they came from (the wheel too, 2026-10-08):
	-- the hero, NEXT and the cards name the plant each milestone really gives.
	local owned = InviteRewards.ownedSet(player:GetAttribute(A.Owned))
	local content = InviteRewards.content(count, granted, owned)
	local shown = content.shown
	if state.open and hero.form ~= shown.form then
		buildHero(shown.form)
	end
	heroName.Text = string.upper(shown.name)
	heroRarity.Text = string.upper(shown.rarity)
	RarityFX.setText(heroRarityFX, shown.rarity, shown.colour)
	heroIncome.Text = shown.incomeText
	fill.BackgroundColor3 = content.fill
	barTrim.Enabled = content.final
	barText.Text = content.barText
	local goal = UDim2.fromScale(content.fraction, 1)
	if animate and not StatusText.reducedMotion() then
		TweenService:Create(fill, TweenInfo.new(PANEL.StepSeconds * 2, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out), { Size = goal }):Play()
	else
		fill.Size = goal
	end
	if content.final then
		nextLine.Text = string.format('<font color="%s">%s</font>', hex(CONFIG.Gold), content.finalText or WORDS.Final)
	elseif content.next then
		local nxt = content.next :: InviteRewards.Reward
		nextLine.Text = string.format(WORDS.Next, nxt.name,
			string.format('<font color="%s">%s</font>', hex(nxt.colour), nxt.rarity), nxt.at,
			InviteRewards.plural(nxt.at))
	end
	-- A plant won on the wheel shows EARNED on its card (2026-10-08).
	for i, c in ipairs(InviteRewards.cards(count, granted, owned)) do
		paintCard(i, c, animate)
	end
end

--==============================================================================
-- LAYOUT: MenuLayout's answer, applied (the gui's own units)
--==============================================================================
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
	local p = MenuLayout.invitePanel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		-- A phone draws this gui smaller (UIKit.menuScaleFor): the panel keeps its room.
		fill = math.min(1, k),
	}, RAIL.OutlineThickness)
	menu.place(p)
	local main = MenuLayout.blocks(p).main
	place(plate, main)
	place(page, main)
	local b = MenuLayout.inviteBlocks(main.w, main.h, p.short)
	page.CanvasSize = UDim2.fromOffset(0, b.height)
	-- The hero.
	place(heroWell, b.picture)
	place(heroName, b.name)
	setFit(heroName, b.name.h)
	place(heroRarity, b.rarity)
	setFit(heroRarity, b.rarity.h)
	place(heroIncome, b.income)
	setFit(heroIncome, b.income.h)
	place(heroTag, b.tag)
	-- The bar and NEXT.
	place(bar, b.bar)
	setFit(barText, b.bar.h - 8)
	studBar(b.bar.w - 8)
	place(nextLine, b.nextLine)
	setFit(nextLine, b.nextLine.h)
	-- The track.
	place(track, b.track)
	track.CanvasSize = UDim2.fromOffset(b.trackCanvas, 0)
	track.ScrollBarThickness = if b.trackScrolls then I.ScrollBar else 0
	trackView.window, trackView.canvas, trackView.cards = b.track.w, b.trackCanvas, b.cards
	place(road, b.road)
	if b.road.w ~= dashesFor then
		dashesFor = b.road.w
		for _, child in ipairs(road:GetChildren()) do
			if child.Name == "Dash" then
				child:Destroy()
			end
		end
		local stride = PANEL.RoadDash + PANEL.RoadDashGap
		for x = PANEL.RoadDashGap, b.road.w - PANEL.RoadDash, stride do
			local dash = MenuKit.frame(road, "Dash", Z + 1, PANEL.RoadLine, 0, 1)
			dash.AnchorPoint = Vector2.new(0, 0.5)
			dash.Position = UDim2.new(0, x, 0.5, 0)
			dash.Size = UDim2.fromOffset(PANEL.RoadDash, 2)
		end
	end
	for i, ui in ipairs(cardUIs) do
		local r = b.cards[i]
		place(ui.holder, r)
		local c = MenuLayout.inviteCard(r.w, r.h, b.dense)
		place(ui.well, c.preview)
		place(ui.name, c.name)
		setFit(ui.name, c.name.h)
		place(ui.rarity, c.rarity)
		setFit(ui.rarity, c.rarity.h)
		place(ui.income, c.income)
		setFit(ui.income, c.income.h)
		place(ui.needs, c.needs)
		setFit(ui.needs, c.needs.h)
		place(ui.tick, c.tick)
		place(ui.claimed, c.claimed)
	end
	-- The button and its line (side by side, the line starts under the button).
	place(send.hit, b.button)
	setFit(send.label, if b.dense then 17 else 20)
	place(how, b.how)
	setFit(how, b.how.h)
	how.TextXAlignment = if b.split then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	UIKit.coverRail(playerGui, PANEL_NAME, state.open and p.covers)
	task.defer(reframe)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
UIKit.onMenuSize(relayout)
relayout()

--==============================================================================
-- WHILE OPEN: the hero turns and idles, the NEXT card's rim breathes
--==============================================================================
local stepping: RBXScriptConnection? = nil
local turn = 0

local function step(dt: number)
	if StatusText.reducedMotion() then
		return
	end
	turn += math.rad(CONFIG.TurnDegrees) * dt
	local camera = hero.camera
	if camera and camera.Parent then
		local out = CFrame.Angles(0, turn, 0):VectorToWorldSpace(CARD.CameraOffset.Unit)
		camera.CFrame = CFrame.lookAt(hero.focus + out * hero.distance, hero.focus)
	end
	local rig = hero.rig
	if rig then
		SecretIdle.Step(rig, os.clock())
	end
	local breath = 0.5 - 0.5 * math.cos(os.clock() * 2 * math.pi / CONFIG.PulseSeconds)
	for _, ui in ipairs(cardUIs) do
		if ui.state == "next" then
			ui.edge.Transparency = 0.6 * breath
		end
	end
end

--==============================================================================
-- OPEN AND SHUT
--==============================================================================
local function setOpen(want: boolean)
	if state.open == want then
		return
	end
	state.open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		-- The "!" comes off now; the server saves the flag.
		local granted = player:GetAttribute(A.Granted)
		state.openedAt = if type(granted) == "number" then granted else 0
		refreshBadge()
		markSeen()
		page.CanvasPosition = Vector2.zero
		relayout()
		buildCards()
		paint(false)
		-- The NEXT card (or the last) in view where the track scrolls.
		local tier = InviteRewards.shownTier(player:GetAttribute(A.Count), player:GetAttribute(A.Granted))
		track.CanvasPosition = Vector2.zero
		showCard(math.clamp(tier + 1, 1, InviteRewards.Count))
		RarityFX.setActive(heroRarityFX, true)
		for _, ui in ipairs(cardUIs) do
			RarityFX.setActive(ui.rarityFX, true)
		end
		if not stepping then
			stepping = RunService.RenderStepped:Connect(step)
		end
		-- Escape and Backspace, only while open: a lasting binding on Escape
		-- would eat the Roblox menu for the session. B is PadFocus's: it clears
		-- OpenPanel, which shuts this.
		ContextActionService:BindActionAtPriority(CLOSE_ACTION, function(_, inputState: Enum.UserInputState)
			if inputState == Enum.UserInputState.Begin then
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
		local running = stepping
		if running then
			running:Disconnect()
			stepping = nil
		end
		RarityFX.setActive(heroRarityFX, false)
		for _, ui in ipairs(cardUIs) do
			RarityFX.setActive(ui.rarityFX, false)
		end
		relayout()
	end
	modal.setOpen(want)
end

-- A tap presses it; a drag on a phone's scrolling panel under the Bag scrolls
-- and never presses it (MenuKit.tap).
MenuKit.tap(button, UIKit.railDockScroll(playerGui), function()
	setOpen(not state.open)
end)
-- INVITE's own press for Play tests, as OfflineUI's ClaimPressed is: the panel
-- opens or shuts. Never INVITE FRIENDS', which opens Roblox's real dialog.
local pressed = Instance.new("BindableEvent")
pressed.Name = "InvitePressed"
pressed.Parent = gui
pressed.Event:Connect(function()
	setOpen(not state.open)
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
	if state.open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then
		setOpen(false)
	end
end)

--==============================================================================
-- THE SERVER'S NUMBERS
--==============================================================================
local function onNumbers()
	local count = player:GetAttribute(A.Count)
	local before = state.lastCount
	if type(count) == "number" then
		state.lastCount = count
	end
	-- The bar filling while the panel is open: a tick a friend (the sign ticks
	-- for itself while the panel is shut -- InviteHub).
	if state.open and before and type(count) == "number" and count > before then
		for n = 1, math.min(count - before, CONFIG.TickRun) do
			task.delay((n - 1) * PANEL.StepSeconds, InviteSounds.play, "tick")
		end
	end
	paint(state.open)
	refreshBadge()
end
player:GetAttributeChangedSignal(A.Count):Connect(onNumbers)
player:GetAttributeChangedSignal(A.Granted):Connect(onNumbers)
player:GetAttributeChangedSignal(A.Owned):Connect(onNumbers)
player:GetAttributeChangedSignal(A.Seen):Connect(refreshBadge)
player:GetAttributeChangedSignal(PIN):Connect(refreshBadge)
onNumbers()

--==============================================================================
-- WHAT THE SERVER SAYS (InviteNews)
--
-- A notice posted before the toasts' renderer listens is dropped (Notice), and
-- a join's WELCOME! comes that early: each waits for it, up to a while.
--==============================================================================
local welcomed = false

local function say(post: Notice.Post, sound: string?)
	task.spawn(function()
		local waited = 0
		while not Notice.ready() and waited < 15 do
			waited += task.wait(0.25)
		end
		Notice.post(post)
		if sound then
			InviteSounds.play(sound)
		end
	end)
end

InviteNews.subscribe(function(payload: InviteNews.Payload)
	-- WHILE YOU WERE AWAY is the reward cards' queue's (InviteRewardUI): after
	-- the offline earnings card, before the cards.
	if payload.kind == "away" then
		return
	end
	-- +1 INVITE, the friend who joined and did not count, WELCOME!, a full Bag:
	-- the words are InviteRewards.notice's. A quick second +1 is the same notice
	-- refreshed (one key), and silent (InviteSounds).
	local words = InviteRewards.notice(payload)
	if not words then
		return
	end
	if payload.kind == "welcome" then
		if welcomed then
			return
		end
		welcomed = true
	end
	say({ kind = words.kind :: any, title = words.title, detail = words.detail, key = words.key,
		quiet = words.quiet }, words.sound)
end)

gui.Destroying:Connect(function()
	UIKit.coverRail(playerGui, PANEL_NAME, false)
	ContextActionService:UnbindAction(CLOSE_ACTION)
	local running = stepping
	if running then
		running:Disconnect()
	end
	if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
end)
