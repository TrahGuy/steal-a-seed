--!strict
-- Steal a Seed :: EventsUI
--
-- THE EVENTS PANEL (2026-10-04, the owner's brief): the Roblox experience
-- events the owner has POSTED for this experience, and a way to ask Roblox for
-- a reminder. Its button is on the left rail beside Settings (in compact and
-- on a phone, under the Bag at the right edge); the panel opens in the middle
-- of the screen, in the inventory's look (MenuKit, BagLook).
--
--==============================================================================
-- WHAT IT SHOWS COMES FROM ROBLOX, AND ONLY FROM ROBLOX
--
-- SocialService:GetUpcomingExperienceEventsAsync on this client: every title,
-- subtitle, description, picture and time is that answer's (the localized
-- Display* fields first). Nothing is hardcoded -- no id, date, words or
-- picture -- so an event the owner posts tomorrow shows tomorrow, and one that
-- ends drops out. EventsModel turns the answer into what the panel says.
--
--   one event      its details at once
--   several        a compact row each, soonest first; a row opens its details
--                  in the same panel, and BACK (or B) returns to the list
--   none           "No events are posted right now."
--   loading        "Loading events..."
--   failed         after EventsModel's bounded retries: the reason, and RETRY
--
-- The list is asked for when the panel OPENS and its copy is older than
-- GameConfig.ExperienceEvents.CacheSeconds -- never at join, never twice at
-- once. Nothing waits on it: the game starts as it always did.
--
--==============================================================================
-- NOTIFY ME IS ROBLOX'S OWN PROMPT
--
-- For an event that has not started: GetEventRsvpStatusAsync says whether this
-- player already has the reminder (NOTIFICATIONS ON) or not (NOTIFY ME). The
-- button opens PromptRsvpToEventAsync -- the native prompt, where the player
-- also manages it -- and shows the status Roblox answers when it closes. It
-- waits (pressed once, then not again) while the prompt is up. A closed
-- prompt, a cancel or an error never shows NOTIFICATIONS ON: only Roblox's
-- answer does. Nothing is stored, nothing is decided for the player, and the
-- panel never says a push notification will arrive -- that is Roblox's and
-- the player's settings'.
--
-- LIVE NOW: an event under way shows that, and no reminder button. An ended or
-- unavailable event's button is grey and does nothing. The clock is read once
-- a second while the panel is open, so an event starting or ending while the
-- player looks changes there and then.
--
--==============================================================================
-- IT ONLY ADVERTISES
--
-- Nothing here starts, schedules or announces anything in the game: no Rain,
-- Thunderstorm, Disco, ticket drop or broadcast follows an event's times, and
-- no permission changes. It opens only when its button is pressed, takes its
-- turn on the OpenPanel mutex like the Shop and the Index, and PadFocus puts a
-- controller in and back out of it as for every centre panel.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local EventsModel = require(Shared:WaitForChild("EventsModel"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ATTR = GameConfig.Attributes
local RAIL = GameConfig.Rail
local CONFIG = GameConfig.ExperienceEvents
local LOOK = MenuKit.Look
local EV = MenuLayout.Events
local PANEL_NAME = "Events"
local BACK_NAME = "SeedEventsBack"

local WHITE = Color3.fromRGB(255, 255, 255)
local INK = LOOK.Ink

local Z = 6

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedEvents")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedEvents"
gui.ResetOnSpawn = false
gui.DisplayOrder = 32
gui.Parent = playerGui

--==============================================================================
-- THE RAIL BUTTON
--
-- There is no EVENTS artwork yet (GameConfig.Rail.EventsArt is ""), so it is
-- built the way the Index and Shop pictures are composed (the global UI pass,
-- 2026-10-04): the violet slab's thick ink outline, a picture in its upper part
-- -- a calendar drawn from frames (UIKit.calendarIcon), a TEMPORARY native
-- stand-in, never an emoji -- and its word under it in outlined white. Given an
-- approved picture, it becomes an ART button like Index and Shop.
--==============================================================================
local button: ImageButton
if RAIL.EventsArt ~= "" then
	button = UIKit.railButton(playerGui, { name = "EventsButton", art = RAIL.EventsArt, wide = false })
else
	button = UIKit.railButton(playerGui, {
		name = "EventsButton",
		face = RAIL.EventsFace,
		shade = RAIL.EventsShade,
		wide = false,
	})
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
	UIKit.calendarIcon(art, 3)
	-- The word under it, as "Index" and "Shop" stand under theirs.
	local word = UIKit.outlined(button, "Word", 11, WHITE, 1.5)
	word.AnchorPoint = Vector2.new(0.5, 1)
	word.Position = UDim2.new(0.5, 0, 1, -2)
	word.Size = UDim2.new(1, -4, 0.3, 0)
	word.TextScaled = true
	word.Text = "EVENTS"
	word.ZIndex = 6
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 12
	fit.MinTextSize = 7
	fit.Parent = word
end
button.Visible = false

-- From HudLayout: beside Settings on a desktop (and a TV), inside the rail's
-- own band; in compact under the Bag at the right edge; on a phone the first
-- square of the panel under the Bag (2026-10-05), standing in the frame
-- RailDrawerUI draws that panel in. There an open panel's corner can be under
-- it -- the Bag's panel takes the whole width -- so off a desktop it steps
-- aside while OpenPanel names a panel, and comes back when it closes.
local function placeButton()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = layout.events
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
-- THE FEED: Roblox's answers, cached and checked (EventsModel.feed)
--==============================================================================
local feed = EventsModel.feed({
	list = function(): any
		return SocialService:GetUpcomingExperienceEventsAsync()
	end,
	read = function(id: string): any
		return SocialService:GetEventRsvpStatusAsync(id)
	end,
	prompt = function(id: string): any
		return SocialService:PromptRsvpToEventAsync(id)
	end,
	now = function(): number
		return workspace:GetServerTimeNow()
	end,
	delay = function(seconds: number, fn: () -> ())
		task.delay(seconds, fn)
	end,
	spawn = function(fn: () -> ())
		task.spawn(fn)
	end,
	config = CONFIG,
})

-- The player's own zone (the device's) and language for every time shown.
local clock = EventsModel.clock(player.LocaleId)

local function now(): number
	return workspace:GetServerTimeNow()
end

--==============================================================================
-- THE PANEL
--==============================================================================
-- No approved EVENTS picture: the calendar drawn from frames stands beside the
-- title (UIKit.calendarIcon), a temporary native icon.
-- Its title in capitals, as every menu's is (the global UI pass, 2026-10-04).
local menu = MenuKit.modal(gui, PANEL_NAME, "EVENTS", nil, nil, function(holder: Frame, z: number)
	UIKit.calendarIcon(holder, z)
end)
-- This gui holds only the panel, so it takes the player's menu size whole.
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body
local close = modal.close

local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = modal.shell

-- BACK, in the header row after the title, while one of several events is open.
local back = MenuKit.button(body, "Back", Z, "< BACK", 15)
back.style("sky")
back.hit.Visible = false

--==============================================================================
-- A PICTURE: Roblox's thumbnail, FIT inside a 16:9 well -- never cropped or
-- stretched -- and what the well says when there is none or it never loads.
--==============================================================================
type Picture = { box: Frame, image: ImageLabel, note: TextLabel, shown: string }

local function pictureBox(parent: Instance, name: string, z: number): Picture
	local box = MenuKit.frame(parent, name, z, LOOK.Well, LOOK.WellTransparency, 8)
	MenuKit.keyline(box, LOOK.WellEdge, 1, 0.3)
	local image = Instance.new("ImageLabel")
	image.Name = "Picture"
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image.Active = false
	image.ZIndex = z + 2
	image.Parent = box
	UIKit.corner(image, 8)
	local note = MenuKit.text(box, "Note", 12, LOOK.Muted, z + 1)
	note.Size = UDim2.new(1, -8, 1, 0)
	note.Position = UDim2.fromOffset(4, 0)
	note.TextWrapped = true
	return { box = box, image = image, note = note, shown = "\0" }
end

local function showPicture(p: Picture, image: string?)
	local want = image or ""
	if p.shown == want then
		return
	end
	p.shown = want
	p.image.Image = want
	if want == "" then
		p.note.Text = "NO IMAGE"
		return
	end
	p.note.Text = ""
	UIKit.whenPictureLoads(p.image, function(loaded: boolean)
		-- A newer picture may have taken this box meanwhile.
		if p.shown == want then
			p.note.Text = if loaded then "" else "IMAGE UNAVAILABLE"
		end
	end)
end

--==============================================================================
-- A BADGE: a short state in a coloured pill, sized to its words
--==============================================================================
type Badge = { pill: Frame, word: TextLabel }

local function badgeIn(parent: Instance, z: number, size: number): Badge
	local pill = MenuKit.frame(parent, "Badge", z, WHITE, 0, 6)
	pill.AutomaticSize = Enum.AutomaticSize.X
	MenuKit.keyline(pill, INK, 1.5)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = pill
	local word = MenuKit.text(pill, "Word", size, WHITE, z + 1)
	word.AutomaticSize = Enum.AutomaticSize.X
	word.Size = UDim2.fromScale(0, 1)
	return { pill = pill, word = word }
end

local function paintBadge(b: Badge, phase: EventsModel.Phase, text: string)
	b.word.Text = text
	b.pill.BackgroundColor3 = if phase == "live" then LOOK.Live
		elseif phase == "upcoming" then LOOK.Soon
		else LOOK.Off
end

--==============================================================================
-- THE LIST: one compact row per event, soonest first
--==============================================================================
local list = Instance.new("ScrollingFrame")
list.Name = "EventList"
list.BackgroundColor3 = LOOK.Well
list.BackgroundTransparency = LOOK.WellTransparency
list.BorderSizePixel = 0
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = LOOK.WellEdge
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ElasticBehavior = Enum.ElasticBehavior.Always
list.Selectable = false
list.Visible = false
list.ZIndex = Z
list.Parent = body
UIKit.corner(list, 10)
MenuKit.keyline(list, LOOK.WellEdge, 1, 0.3)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, EV.ListInset)
	pad.PaddingRight = UDim.new(0, EV.ListInset + 4)
	pad.PaddingTop = UDim.new(0, EV.ListInset)
	pad.PaddingBottom = UDim.new(0, EV.ListInset)
	pad.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, EV.RowGap)
	layout.Parent = list
end

type Row = {
	face: TextButton,
	picture: Picture,
	title: TextLabel,
	badge: Badge,
	when: TextLabel,
	chevron: Frame,
}
local rows: { [string]: Row } = {}
local rowShape = { rowH = EV.RowTall, thumbW = 113, thumbH = 64 }

local openDetail: (string) -> ()

local function shapeRow(row: Row)
	local h, tw, th = rowShape.rowH, rowShape.thumbW, rowShape.thumbH
	row.face.Size = UDim2.new(1, 0, 0, h)
	row.picture.box.Position = UDim2.fromOffset(8, math.floor((h - th) / 2))
	row.picture.box.Size = UDim2.fromOffset(tw, th)
	local x = 8 + tw + 10
	local top = math.floor((h - 24 - 6 - 22) / 2)
	row.title.Position = UDim2.fromOffset(x, top)
	row.title.Size = UDim2.new(1, -x - 30, 0, 24)
	row.badge.pill.Position = UDim2.fromOffset(x, top + 30)
	row.badge.pill.Size = UDim2.fromOffset(0, 22)
	row.when.Position = UDim2.fromOffset(x, top + 30)
	row.when.Size = UDim2.new(1, -x - 30, 0, 22)
end

local function rowFor(e: EventsModel.Event): Row
	local made = rows[e.id]
	if made then
		return made
	end
	local face = Instance.new("TextButton")
	face.Name = "Event_" .. e.id
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.ZIndex = Z + 1
	face.Parent = list
	UIKit.corner(face, 9)
	MenuKit.cardFace(face)
	MenuKit.keyline(face, LOOK.CardEdge, 1, LOOK.CardEdgeTransparency)
	local picture = pictureBox(face, "Thumb", Z + 2)
	-- Dark type on the light card: plain, no outline.
	local title = MenuKit.text(face, "Title", 17, LOOK.Text, Z + 3)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = Z + 3
	local badge = badgeIn(face, Z + 3, 12)
	local when = MenuKit.body(face, "When", 13, LOOK.Muted, Z + 3)
	when.TextXAlignment = Enum.TextXAlignment.Left
	when.TextTruncate = Enum.TextTruncate.AtEnd
	local chevron = MenuKit.chevron(face, 12, LOOK.Muted, Z + 3)
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -10, 0.5, 0)
	chevron.Rotation = -90
	local row: Row = { face = face, picture = picture, title = title, badge = badge, when = when, chevron = chevron }
	rows[e.id] = row
	shapeRow(row)
	local scale = Instance.new("UIScale")
	scale.Parent = face
	UIKit.cardPop(face, scale, { hoverScale = 1.015, pressScale = 0.985, sound = false })
	local id = e.id
	MenuKit.tap(face, list, function()
		SoundKit.play("CardClick")
		openDetail(id)
	end)
	return row
end

local function paintRow(row: Row, e: EventsModel.Event, order: number, at: number)
	row.face.LayoutOrder = order
	row.face.Visible = true
	row.title.Text = e.title
	local phase = EventsModel.phase(e, at)
	paintBadge(row.badge, phase, EventsModel.badge(e, phase, at))
	showPicture(row.picture, e.image)
	-- The start, in the player's own time, after the badge.
	local badgeW = MenuKit.textWidth(row.badge.word.Text, 12) + 16
	local x = row.badge.pill.Position.X.Offset + badgeW + 8
	row.when.Position = UDim2.fromOffset(x, row.badge.pill.Position.Y.Offset)
	row.when.Size = UDim2.new(1, -x - 30, 0, 22)
	row.when.Text = if e.timed and phase == "upcoming"
		then clock.day(e.startsAt :: number) .. ", " .. clock.time(e.startsAt :: number) .. " (your time)"
		else ""
end

--==============================================================================
-- THE DETAILS: in the panel, over the list
--==============================================================================
local detail = MenuKit.frame(body, "Detail", Z + 2)
detail.Visible = false
local banner = pictureBox(detail, "Banner", Z + 3)
local detailBadge = badgeIn(detail, Z + 3, 14)
local detailWhen = MenuKit.body(detail, "When", 14, LOOK.Muted, Z + 3)
detailWhen.TextXAlignment = Enum.TextXAlignment.Left
detailWhen.TextYAlignment = Enum.TextYAlignment.Top
detailWhen.TextWrapped = true
detailWhen.TextScaled = true
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 14
	fit.MinTextSize = 10
	fit.Parent = detailWhen
end
local detailTitle = MenuKit.text(detail, "Title", 24, LOOK.Text, Z + 3)
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.TextScaled = true
detailTitle.ZIndex = Z + 3
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 24
	fit.MinTextSize = 13
	fit.Parent = detailTitle
end
local detailSubtitle = MenuKit.body(detail, "Subtitle", 15, LOOK.Text, Z + 3)
detailSubtitle.TextXAlignment = Enum.TextXAlignment.Left
detailSubtitle.TextTruncate = Enum.TextTruncate.AtEnd

local words = Instance.new("ScrollingFrame")
words.Name = "Words"
words.BackgroundTransparency = 1
words.BorderSizePixel = 0
words.ScrollingDirection = Enum.ScrollingDirection.Y
words.ScrollBarThickness = 5
words.ScrollBarImageColor3 = LOOK.WellEdge
words.CanvasSize = UDim2.new()
words.AutomaticCanvasSize = Enum.AutomaticSize.Y
words.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
-- A controller scrolls it with the stick once it is selected.
words.Selectable = true
words.SelectionImageObject = nil
words.ZIndex = Z + 3
words.Parent = detail
local wordsText = MenuKit.body(words, "Text", 15, LOOK.Text, Z + 4)
wordsText.Size = UDim2.new(1, -10, 0, 0)
wordsText.AutomaticSize = Enum.AutomaticSize.Y
wordsText.TextWrapped = true
wordsText.TextXAlignment = Enum.TextXAlignment.Left
wordsText.TextYAlignment = Enum.TextYAlignment.Top
-- Plain text: an event's words are shown as written, never read as markup.
wordsText.RichText = false

local note = MenuKit.body(detail, "Note", 13, LOOK.Premium, Z + 3)
note.TextXAlignment = Enum.TextXAlignment.Center
note.Visible = false

local action = MenuKit.button(detail, "Action", Z + 5, "NOTIFY ME", 16)

--==============================================================================
-- LOADING, NOTHING POSTED, AND A FAILED LOAD
--==============================================================================
local status = MenuKit.frame(body, "Status", Z + 1)
status.Visible = false
local statusText = MenuKit.body(status, "Message", 16, LOOK.Text, Z + 2)
statusText.AnchorPoint = Vector2.new(0.5, 0.5)
statusText.Position = UDim2.new(0.5, 0, 0.5, -26)
statusText.Size = UDim2.new(1, -24, 0, 44)
statusText.TextWrapped = true
local retry = MenuKit.button(status, "Retry", Z + 2, "RETRY", 16)
retry.style("go")
retry.hit.AnchorPoint = Vector2.new(0.5, 0)
retry.hit.Position = UDim2.new(0.5, 0, 0.5, 4)
retry.hit.Size = UDim2.fromOffset(160, 44)

--==============================================================================
-- STATE AND PAINTING
--==============================================================================
local open = false
-- The event whose details are open, while one of several is.
local selectedId: string? = nil
-- What the details show now, and the main block they fill.
local shownId: string? = nil
local shownSubtitle: boolean? = nil
local mainRect = MenuLayout.rect(0, 0, 0, 0)
local currentAction: EventsModel.Action? = nil

local relayout: () -> ()

local function shownEvent(): (EventsModel.Event?, boolean)
	local events = feed.events()
	if #events == 1 then
		return events[1], false
	end
	local id = selectedId
	if id then
		local e = feed.find(id)
		if e then
			return e, true
		end
	end
	return nil, false
end

local function layoutDetail(e: EventsModel.Event)
	local m = mainRect
	local d = MenuLayout.eventDetail(m.w, m.h, e.subtitle ~= nil)
	detail.Position = UDim2.fromOffset(m.x, m.y)
	detail.Size = UDim2.fromOffset(m.w, m.h)
	local function put(object: GuiObject, r: MenuLayout.Rect)
		object.Position = UDim2.fromOffset(r.x, r.y)
		object.Size = UDim2.fromOffset(r.w, r.h)
	end
	put(banner.box, d.banner)
	banner.box.Visible = d.banner.h > 0
	detailBadge.pill.Position = UDim2.fromOffset(d.badge.x, d.badge.y)
	detailBadge.pill.Size = UDim2.fromOffset(0, d.badge.h)
	put(detailWhen, d.when)
	put(detailTitle, d.title)
	local sub = d.subtitle
	detailSubtitle.Visible = sub ~= nil
	if sub then
		put(detailSubtitle, sub)
	end
	put(words, d.words)
	put(action.hit, d.action)
	-- A prompt's trouble, said on the line just above the button.
	note.Position = UDim2.fromOffset(d.words.x, d.action.y - 22)
	note.Size = UDim2.fromOffset(d.words.w, 18)
	words.Size = UDim2.fromOffset(d.words.w, if note.Visible then math.max(0, d.words.h - 22) else d.words.h)
	shownSubtitle = e.subtitle ~= nil
end

local function paintDetail(e: EventsModel.Event, at: number)
	if shownId ~= e.id or shownSubtitle ~= (e.subtitle ~= nil) then
		shownId = e.id
		words.CanvasPosition = Vector2.zero
		layoutDetail(e)
	end
	local phase = EventsModel.phase(e, at)
	paintBadge(detailBadge, phase, EventsModel.badge(e, phase, at))
	local span = EventsModel.when(e, clock)
	detailWhen.Text = if span then span .. "  (your local time)" else ""
	detailTitle.Text = e.title
	detailSubtitle.Text = e.subtitle or ""
	wordsText.Text = if e.description ~= "" then e.description else "No description posted."
	wordsText.TextColor3 = if e.description ~= "" then LOOK.Text else LOOK.Muted
	showPicture(banner, e.image)
	-- The reminder status is read for an event that has not started (Roblox
	-- refuses the read once it has), and again once it is old.
	if phase == "upcoming" then
		feed.readRsvp(e.id)
	end
	local a = EventsModel.action(phase, feed.rsvp(e.id), feed.pending(e.id))
	currentAction = a
	action.set(a.label)
	action.style(a.style)
	action.hit.Active = a.enabled
	action.hit.Selectable = a.enabled
	local said = if a.prompts then feed.note(e.id) else nil
	local hadNote = note.Visible
	note.Text = said or ""
	note.Visible = said ~= nil
	if hadNote ~= note.Visible then
		layoutDetail(e)
	end
end

local function setView(view: string)
	list.Visible = view == "list"
	detail.Visible = view == "detail"
	status.Visible = view == "status"
end

local function paint()
	local at = now()
	local state = feed.state()
	local events = feed.events()
	local e, canBack = shownEvent()
	back.hit.Visible = e ~= nil and canBack
	if #events == 0 then
		currentAction = nil
		shownId = nil
		if state == "failed" then
			statusText.Text = "Events could not be loaded right now."
			retry.hit.Visible = true
		elseif state == "ready" then
			statusText.Text = "No events are posted right now. Check back soon!"
			retry.hit.Visible = false
		else
			statusText.Text = "Loading events..."
			retry.hit.Visible = false
		end
		setView("status")
		padFirst.Value = if retry.hit.Visible then retry.hit else nil
		return
	end
	if e then
		setView("detail")
		paintDetail(e, at)
		padFirst.Value = if action.hit.Selectable then action.hit
			elseif back.hit.Visible then back.hit
			else words
		return
	end
	currentAction = nil
	shownId = nil
	setView("list")
	local seen: { [string]: boolean } = {}
	local first: GuiObject? = nil
	for i, item in ipairs(events) do
		local row = rowFor(item)
		paintRow(row, item, i, at)
		seen[item.id] = true
		if not first then
			first = row.face
		end
	end
	for id, row in pairs(rows) do
		if not seen[id] then
			row.face:Destroy()
			rows[id] = nil
		end
	end
	padFirst.Value = first
end

feed.changed(function()
	if open then
		paint()
	end
end)

--==============================================================================
-- OPENING AND LEAVING ONE EVENT'S DETAILS
--==============================================================================
local function closeDetail()
	local id = selectedId
	if not id then
		return
	end
	selectedId = nil
	MenuKit.unbind(BACK_NAME)
	paint()
	local row = rows[id]
	if row and MenuKit.onPad() then
		GuiService.SelectedObject = row.face
	end
end

openDetail = function(id: string)
	if not feed.find(id) then
		return
	end
	selectedId = id
	MenuKit.bindBack(BACK_NAME, closeDetail)
	paint()
	if MenuKit.onPad() then
		GuiService.SelectedObject = if action.hit.Selectable then action.hit else back.hit
	end
end

MenuKit.tap(back.hit, nil, function()
	SoundKit.play("CardClick")
	closeDetail()
end)

MenuKit.tap(action.hit, nil, function()
	local e = shownEvent()
	local a = currentAction
	if not (e and a and a.enabled and a.prompts) then
		return
	end
	-- The phase is read again at the press: an event that started a moment ago
	-- is LIVE NOW, and Roblox refuses its prompt.
	if EventsModel.phase(e, now()) ~= "upcoming" then
		paint()
		return
	end
	SoundKit.play("CardClick")
	feed.promptRsvp(e.id)
end)

MenuKit.tap(retry.hit, nil, function()
	SoundKit.play("CardClick")
	feed.refresh(true)
end)

--==============================================================================
-- THE CLOCK, ONCE A SECOND WHILE OPEN: countdowns, and an event starting or
-- ending while the player looks. Nothing runs while the panel is shut.
--==============================================================================
local tick: RBXScriptConnection? = nil
local lastTick = 0

local function startTick()
	if tick then
		return
	end
	lastTick = os.clock()
	tick = RunService.Heartbeat:Connect(function()
		local t = os.clock()
		if t - lastTick < CONFIG.TickSeconds then
			return
		end
		lastTick = t
		paint()
	end)
end

local function stopTick()
	local t = tick
	if t then
		t:Disconnect()
		tick = nil
	end
end

--==============================================================================
-- LAYOUT: MenuLayout's answer, applied (the gui's own units)
--==============================================================================
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

relayout = function()
	local k = UIKit.scaleOf(gui)
	local safe = gui.AbsoluteSize / k
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(gui))
	local camera = workspace.CurrentCamera
	local hudScale = if HudLayout.isTenFoot() and camera then HudLayout.tenFootScale(camera.ViewportSize) else 1
	local f = k / hudScale
	local p = MenuLayout.eventsPanel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		keyboardTop = keyboardTop(),
	}, RAIL.OutlineThickness)
	menu.place(p)
	local touch = MenuLayout.Config.Touch
	local rowY = math.floor((p.header - touch) / 2)
	local head = MenuLayout.eventsHeader(p, MenuKit.titleWidth(menu, p.short), true)
	local b = head.back
	if b then
		back.hit.Position = UDim2.fromOffset(b.x, rowY)
		back.hit.Size = UDim2.fromOffset(b.w, touch)
	end
	local main = MenuLayout.blocks(p).main
	mainRect = main
	list.Position = UDim2.fromOffset(main.x, main.y)
	list.Size = UDim2.fromOffset(main.w, main.h)
	status.Position = UDim2.fromOffset(main.x, main.y)
	status.Size = UDim2.fromOffset(main.w, main.h)
	local shape = MenuLayout.eventRows(p)
	if shape.rowH ~= rowShape.rowH or shape.thumbW ~= rowShape.thumbW then
		rowShape = shape
		for _, row in pairs(rows) do
			shapeRow(row)
		end
	end
	-- The details are laid out again on their next paint.
	shownId = nil
	UIKit.coverRail(playerGui, PANEL_NAME, open and p.covers)
	if open then
		paint()
	end
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
	task.defer(relayout)
end)
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
		-- Asked for only when the copy is stale; never twice at once.
		feed.refresh()
		startTick()
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		stopTick()
		selectedId = nil
		MenuKit.unbind(BACK_NAME)
	end
	relayout()
	paint()
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

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if open and holder ~= PANEL_NAME then
		setOpen(false)
	end
end)

gui.Destroying:Connect(function()
	stopTick()
	feed.destroy()
	UIKit.coverRail(playerGui, PANEL_NAME, false)
	MenuKit.unbind(BACK_NAME)
	if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
end)
