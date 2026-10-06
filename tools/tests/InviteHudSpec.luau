--!nocheck
--==============================================================================
-- Steal a Seed :: InviteHudSpec
--
-- The INVITE button, its "!" and the phone's panel under the Bag (2026-10-06),
-- by the real HudLayout and the owner scripts' own source, in Edit:
--
--   1. INVITE on every listed screen: inside the safe area, clear of every
--      other group; the rail's top row on a desktop and a TV, under the row in
--      compact, the FIRST square of the panel under the Bag on a phone
--   2. the "!": the box and the corner every badge has (HudLayout.badges), on
--      the glass, clear of Index's badge
--   3. the phone's panel: INVITE, EVENTS, WHAT'S NEW, Settings down it; squares
--      never under MinTile -- the viewport scrolls instead; the handle; shut,
--      only the handle stands; the handle's badge on the glass
--   4. the "!" itself: plain ASCII, the gold and ink of GameConfig, drawn by
--      InviteUI from the server's flag, worn by the shut panel's handle; every
--      other badge still the red circle
--   5. the panel's scripts (moved here from HudLayoutSpec, 2026-10-06): the
--      handle, the slide, the scrolling canvas, a tap that never fires on a drag
--   6. the owner's picture: the one id, square, drawn by UIKit.railPicture
--
-- Not here, seen in Play instead: the picture loading, the wiggle, a real
-- phone. The emulator is not drivable from a tool.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)
local InviteRewards = require(Shared.InviteRewards)

local RAIL = GameConfig.Rail
local BANG = RAIL.InviteBadge
local CFG = HudLayout.Config
local PP = CFG.Phone.Panel
local rect = HudLayout.rect

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function r2s(r)
	return if r then string.format("(%g,%g %gx%g)", r.x, r.y, r.w, r.h) else "nil"
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function overlaps(a, b)
	return a.w > 0 and a.h > 0 and b.w > 0 and b.h > 0 and a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h
		and b.y < a.y + a.h
end
local function inside(r, safe, slack)
	slack = slack or 0
	return r.x >= -slack and r.y >= -slack and r.x + r.w <= safe.X + slack and r.y + r.h <= safe.Y + slack
end
local function within(r, box, slack)
	slack = slack or 0
	return r.x >= box.x - slack and r.y >= box.y - slack and r.x + r.w <= box.x + box.w + slack
		and r.y + r.h <= box.y + box.h + slack
end

-- HudLayoutSpec's screens: a 58-px topbar, notched phones' landscape insets.
local TOPBAR, BAR_LEFT = 58, 208
local function screen(w, h, opts)
	opts = opts or {}
	local left, right, bottom = opts.left or 0, opts.right or 0, opts.bottom or 0
	return {
		safe = Vector2.new(w - left - right, h - TOPBAR - bottom),
		touch = opts.touch == true,
		keyboard = opts.keyboard ~= false,
		viewport = Vector2.new(w, h),
		topbar = rect(BAR_LEFT, 0, w - BAR_LEFT, TOPBAR),
		insetTop = TOPBAR,
	}
end
local DESKS = { { 1280, 720 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 2560, 1440 }, { 1000, 609 } }
local PHONES = { { 640, 480 }, { 772, 360 }, { 874, 402 }, { 896, 414 }, { 956, 440 }, { 1000, 609 }, { 705, 338 },
	{ 640, 360 }, { 801, 392 } }
local NOTCHED = { { 874, 402, 62, 21, "iPhone 16 Pro" }, { 956, 440, 62, 21, "iPhone 16 Pro Max" },
	{ 896, 414, 48, 21, "iPhone 11" }, { 844, 390, 47, 21, "iPhone 12/13/14" } }
local cases = {}
for _, d in ipairs(DESKS) do
	table.insert(cases, { tag = string.format("%dx%d desktop", d[1], d[2]), input = screen(d[1], d[2]) })
end
table.insert(cases, { tag = "860x700 window", input = screen(860, 700, { touch = false }) })
table.insert(cases, { tag = "700x400 window", input = screen(700, 400, { touch = false }) })
local phones = {}
for _, p in ipairs(PHONES) do
	table.insert(phones, { tag = string.format("%dx%d emulated", p[1], p[2]),
		input = screen(p[1], p[2], { touch = true, keyboard = true }) })
	table.insert(phones, { tag = string.format("%dx%d phone", p[1], p[2]),
		input = screen(p[1], p[2], { touch = true, keyboard = false }) })
end
for _, p in ipairs(NOTCHED) do
	table.insert(phones, { tag = string.format("%dx%d %s", p[1], p[2], p[5]),
		input = screen(p[1], p[2], { touch = true, keyboard = false, left = p[3], right = p[3], bottom = p[4] }) })
end
for _, c in ipairs(phones) do
	table.insert(cases, c)
end
local function tvCase(w, h, inset)
	return HudLayout.tenFootInput({
		safe = Vector2.new(w, h - inset),
		touch = false,
		keyboard = false,
		viewport = Vector2.new(w, h),
		topbar = rect(0, 0, 0, inset),
		insetTop = inset,
	})
end
for _, t in ipairs({ { 1920, 1080, 0 }, { 1920, 1080, 58 }, { 3840, 2160, 0 }, { 1280, 720, 36 } }) do
	table.insert(cases, { tag = string.format("%dx%d TV (%d topbar)", t[1], t[2], t[3]), input = tvCase(t[1], t[2], t[3]),
		tv = true })
end

local BADGE = 26 + 2.5 * 2

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1 & 2. INVITE and its \"!\" on every listed screen --")
	local shown, hidden = 0, {}
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		local r = L.invite
		local tag = case.tag
		local problems = HudLayout.problems(L)
		check(#problems == 0, tag .. ": every group clear, INVITE included", table.concat(problems, "; "))
		if r.w <= 0 then
			table.insert(hidden, tag)
			check(not L.sidebar and L.compact, tag .. ": INVITE hidden only in a compact window with no clear spot")
			continue
		end
		shown += 1
		local b = HudLayout.inviteBadge(L)
		-- A desktop badge hangs 3.5 px into the topbar band, as Index's always has.
		local slack = if L.compact then 0.01 else 3.51
		local box = L.frame or rect(0, 0, L.safe.X, L.safe.Y)
		check(r.w == r.h and within(r, box) and within(b, box, slack),
			tag .. ": INVITE square, it and its \"!\" on the glass", r2s(r) .. " ! " .. r2s(b))
		local want = if L.sidebar then PP.HandleH else BADGE
		check(b.w == want and b.h == want,
			tag .. (if L.sidebar then ": the \"!\" box is the panel handle's badge size"
				else ": the \"!\" box is every badge's size"), r2s(b))
		local indexBadge = HudLayout.badges(L)
		check(L.sidebar or not overlaps(b, indexBadge), tag .. ": clear of Index's badge",
			r2s(b) .. " vs " .. r2s(indexBadge))
		if L.sidebar then
			-- A phone: the panel's first square, the badge tucked in its padding.
			local view = L.dockView
			check(view ~= nil and r.x >= view.x and r.x + r.w <= view.x + view.w and r.x == L.events.x
					and r.y < L.events.y and L.events.y < L.updates.y and L.updates.y < L.settings.y
					and r.x == L.settings.x,
				tag .. ": INVITE first down the panel, then EVENTS, WHAT'S NEW, Settings",
				r2s(r) .. " " .. r2s(L.events) .. " " .. r2s(L.settings))
			-- The glyph is Scale times its box's height with its ink line round it:
			-- with the canvas at its top, none of it above the viewport (Play at
			-- 705 x 338 showed the top cut), and the square's picture mostly clear.
			local glyphTop = b.y + b.h / 2 - math.floor(b.h * BANG.Scale) / 2 - BANG.Stroke
			check(view ~= nil and b.x + b.w == r.x + r.w + PP.Pad and b.x >= view.x
					and b.x + b.w <= view.x + view.w + 0.01 and glyphTop >= view.y and b.y + b.h <= r.y + r.h
					and b.w <= r.w * 0.66,
				tag .. ": the \"!\" on INVITE's top-right corner, inside the panel, its glyph never cut",
				r2s(b) .. string.format(" glyph top %g, viewport top %g", glyphTop, if view then view.y else -1))
			-- Scrolled (the owner, 2026-10-06): pinned to the panel's top edge in the
			-- very box INVITE's stands in at the top of the scroll, before its own
			-- glyph would be cut, with a press round it inside the viewport.
			local pinBox, pinFrom, press = HudLayout.invitePin(L)
			check(view ~= nil and pinBox.x == b.x and pinBox.y == b.y and pinBox.w == b.w and pinBox.h == b.h
					and pinFrom >= 0 and pinFrom <= glyphTop - view.y + 0.01 and within(press, view, 0.01)
					and press.x <= b.x and press.y <= b.y and press.x + press.w >= b.x + b.w
					and press.y + press.h >= b.y + b.h and press.w >= b.w + PP.PinPad and press.h >= b.h + PP.PinPad,
				tag .. ": scrolled, the \"!\" pinned in its own box at the panel's top edge, a press round it",
				r2s(pinBox) .. string.format(" pins past %g, press ", pinFrom) .. r2s(press))
		elseif L.compact then
			local hang = CFG.BadgeHang + 2.5
			check(b.x + b.w == r.x + r.w + hang and b.y == r.y - hang and r.y >= L.index.y + L.index.h,
				tag .. ": under the row, the \"!\" tucked into its top-right corner as compact badges are", r2s(b))
		else
			local W, S = RAIL.WideSize, RAIL.SquareSize
			-- The rail's top row at its right end (a TV's title-safe frame moves the
			-- whole rail; the same place in it).
			local want = rect(L.index.x + W.X - S.X, L.index.y, S.X, S.Y)
			check(r.x == want.x and r.y == want.y and r.w == want.w and b.x + b.w / 2 == r.x + r.w
					and b.y + b.h / 2 == r.y,
				tag .. ": the rail's top row at its right end, the \"!\" half off its top-right corner",
				r2s(r) .. " want " .. r2s(want))
			if not case.tv then
				check(L.index.x == RAIL.Inset and L.index.y == RAIL.Inset, tag .. ": the rail itself has not moved")
			end
		end
		if not L.sidebar then
			local _, never, none = HudLayout.invitePin(L)
			check(never == math.huge and none.w == 0, tag .. ": no panel, nothing pinned")
		end
	end
	say(string.format("  INVITE shown on %d of %d screens; hidden on: %s", shown, #cases,
		if #hidden > 0 then table.concat(hidden, ", ") else "none"))
	check(#hidden == 0, "INVITE has a place on every listed screen", table.concat(hidden, ", "))
	-- The owner (2026-10-06): the phone's smaller "!" is approved; desktops and TVs
	-- keep every badge's size where it fits there.
	local kept, desks = 0, 0
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		if not L.sidebar and L.invite.w > 0 then
			desks += 1
			local b = HudLayout.inviteBadge(L)
			local box = L.frame or rect(0, 0, L.safe.X, L.safe.Y)
			if b.w == BADGE and b.h == BADGE and within(b, box, if L.compact then 0.01 else 3.51) then
				kept += 1
			end
		end
	end
	local desk = HudLayout.solve(screen(1280, 720))
	say("  1280x720 desktop: INVITE " .. r2s(desk.invite) .. ", its \"!\" " .. r2s(HudLayout.inviteBadge(desk)))
	check(desks > 0 and kept == desks, string.format(
		"desktops, windows and TVs keep every badge's %g-px \"!\", on the glass: %d of %d", BADGE, kept, desks))

	--==========================================================================
	say("-- 3. the panel under the Bag (phones) --")
	local scrolls, still = {}, {}
	for _, case in ipairs(phones) do
		local L = HudLayout.solve(case.input)
		local tag = case.tag
		local view, h = L.dockView, L.handle
		check(L.sidebar and view ~= nil and h ~= nil and L.dockCanvas ~= nil, tag .. ": a panel, a viewport, a handle")
		if not (view and h) then
			continue
		end
		local tile = L.invite.w
		check(tile >= PP.MinTile and tile <= PP.Tile and L.events.w == tile and L.settings.w == tile,
			tag .. string.format(": squares of %d px, never under MinTile %d", tile, PP.MinTile))
		check(h.y + h.h + PP.HandleGap == view.y and h.x == view.x and h.w == view.w,
			tag .. ": the handle on the panel's top edge, the viewport under it", r2s(h) .. " " .. r2s(view))
		check(L.dockCanvas >= view.h and L.settings.y + L.settings.h + PP.Pad - view.y <= L.dockCanvas + 0.5,
			tag .. ": the canvas holds all four squares", string.format("canvas %g view %g", L.dockCanvas, view.h))
		if L.dockCanvas > view.h + 0.5 then
			table.insert(scrolls, tag)
		else
			table.insert(still, tag)
		end
		check(L.bag.y + L.bag.h <= h.y, tag .. ": the panel under the Bag", r2s(L.bag) .. " " .. r2s(h))
		-- Shut: only the handle.
		local shutInput = table.clone(case.input)
		shutInput.dockShut = true
		local S = HudLayout.solve(shutInput)
		check(S.dockShut == true and S.dock ~= nil and S.handle ~= nil and S.dock.x == S.handle.x
				and S.dock.y == S.handle.y and S.dock.w == S.handle.w and S.dock.h == S.handle.h
				and #HudLayout.problems(S) == 0,
			tag .. ": shut, the panel is only its handle, tucked under the Bag", r2s(S.dock))
		local hb = HudLayout.handleBadge(S)
		check(inside(hb, S.safe, 0.01) and overlaps(hb, S.handle), tag .. ": the handle's badge on its corner, on the glass",
			r2s(hb))
	end
	say("  the panel scrolls on: " .. (if #scrolls > 0 then table.concat(scrolls, ", ") else "none"))
	say("  all four squares at once on: " .. (if #still > 0 then table.concat(still, ", ") else "none"))
	check(#still > 0, "a tall phone shows all four with nothing to scroll")
	local plain = HudLayout.solve(screen(1280, 720))
	check(not plain.sidebar and plain.dockView == nil and plain.handle == nil,
		"no desktop gets the panel, a handle or a scroll")

	--==========================================================================
	say("-- 4. the \"!\" itself --")
	check(BANG.Glyph == "!" and #BANG.Glyph == 1 and string.byte(BANG.Glyph) == 33,
		"the glyph is a plain ASCII \"!\"")
	check(BANG.Font == Enum.Font.LuckiestGuy and BANG.Stroke >= 2.5 and BANG.Fill.R > 0.9 and BANG.Fill.G > 0.7
			and BANG.Fill.B < 0.4 and BANG.Ink.R < 0.2 and BANG.Ink.G < 0.2 and BANG.Ink.B < 0.2,
		"bright yellow-gold, a thick dark ink line, the game's display face")
	check(BANG.PulseEvery > BANG.PulseSeconds and BANG.PulseDegrees > 0 and BANG.PulseDegrees <= 20
			and BANG.QuietAfterJoin > 0,
		"a gentle wiggle every few seconds; quiet just after joining")
	check(InviteRewards.badge(nil) and InviteRewards.badge(false) and not InviteRewards.badge(true),
		"it shows for a never-opened player and after a new form; the panel opening clears it")
	local ui = sourceOf(StarterPlayer, "InviteUI")
	check(has(ui, "bang.Text = BANG.Glyph") and has(ui, "bang.TextColor3 = BANG.Fill") and has(ui, "ink.Color = BANG.Ink")
			and has(ui, "ink.Thickness = BANG.Stroke") and has(ui, "bang.Font = BANG.Font")
			and not has(ui, "UIKit.badge(") and has(ui, "bang.BackgroundTransparency = 1"),
		"InviteUI draws it from GameConfig: no circle, no plate, not the red badge")
	check(has(ui, "local b = HudLayout.inviteBadge(layout)")
			and has(ui, "bang.Position = UDim2.fromOffset(b.x - r.x + b.w / 2, b.y - r.y + b.h / 2)"),
		"placed in HudLayout's box, right with no animation")
	check(has(ui, "Rotation = BANG.PulseDegrees * k") and has(ui, "bang.Rotation = 0")
			and has(ui, "not StatusText.reducedMotion()"),
		"the wiggle only turns it, settles at 0, and stops under reduced motion")
	check(has(ui, "return InviteRewards.badge(seen)") and has(ui, "player:GetAttribute(A.Seen)")
			and has(ui, 'state.openedAt = if type(granted) == "number" then granted else 0')
			and has(ui, "remote:FireServer(CONFIG.OpenedAction)"),
		"from the server's flag; opening the panel takes it off and tells the server")
	check(has(ui, 'if state.open and type(granted) == "number" and (state.openedAt or -1) < granted then')
			and has(ui, "state.openedAt = granted\n\t\t\tmarkSeen()"),
		"a form given while the panel is open is seen as it lands: no \"!\", no pop, the server told")
	check(has(ui, 'UIKit.dockBadge("Invite", if want then "bang" else nil)'),
		"the phone's shut panel is told, so its handle wears the \"!\"")
	local drawer = sourceOf(StarterPlayer, "RailDrawerUI")
	check(has(drawer, "bang.Text = BADGE.Glyph") and has(drawer, "bang.TextColor3 = BADGE.Fill")
			and has(drawer, "dot.BackgroundColor3 = RAIL.Badge") and has(drawer, 'if value == "bang" then'),
		"the handle wears INVITE's \"!\" before any red dot")
	local index, garden = sourceOf(StarterPlayer, "IndexUI"), sourceOf(StarterPlayer, "GardenUI")
	local kit = sourceOf(Shared, "UIKit")
	local from = kit:find("function UIKit.badge", 1, true)
	local body = if from then kit:sub(from, (kit:find("\nend\n", from, true) or #kit)) else ""
	check(has(index, "UIKit.badge(button, RAIL.Badge)") and has(garden, "UIKit.badge(button, RAIL.Badge)")
			and has(body, "UIKit.corner(badge, 13)") and has(body, "badge.BackgroundColor3 = colour")
			and RAIL.Badge.R > 0.8 and RAIL.Badge.G < 0.4,
		"every other badge is still the red circle")

	--==========================================================================
	say("-- 5. the panel's scripts --")
	check(has(drawer, "UIKit.railDock(playerGui)") and has(drawer, "dock.Visible = player:GetAttribute(ATTR.OpenPanel) == nil")
			and has(drawer, "local view, hr = layout.dockView, layout.handle")
			and has(drawer, "player:SetAttribute(PP.ShutAttribute, not isShut())")
			and has(drawer, "TweenInfo.new(PP.Slide") and has(drawer, "GuiService.SelectedObject = handle")
			and not has(drawer, "IndexButton") and not has(drawer, "ShopButton") and not has(drawer, "SettingsButton")
			and not has(drawer, "EventsButton") and not has(drawer, "UpdatesButton") and not has(drawer, "InviteButton"),
		"RailDrawerUI owns the panel round the squares -- the handle, the shut state, its slide -- steps aside "
			.. "for a panel, and touches no square")
	check(PP.Slide > 0 and PP.Slide <= 0.3 and PP.ShutAttribute ~= nil,
		"a ~0.2 s slide; the shut state one client-local attribute")
	-- INVITE's "!" never scrolls away (the owner, 2026-10-06).
	check(has(drawer, 'topFade.Name = "DockFadeTop"')
			and has(drawer, "topFade.Visible = clip.Visible and scroll.CanvasPosition.Y > 1")
			and has(drawer, "local box, from, press = HudLayout.invitePin(layout)")
			and has(drawer, 'player:GetAttribute(INVITE_BADGE) == "bang"')
			and has(drawer, "and scroll.CanvasPosition.Y > pinFrom")
			and has(drawer, "player:SetAttribute(PP.PinAttribute, if up then true else nil)")
			and has(drawer, "pin.ZIndex = 22") and has(drawer, "topFade.ZIndex = 20")
			and has(drawer, "pinBang.Font = BADGE.Font") and has(drawer, "pinBang.TextColor3 = BADGE.Fill")
			and has(drawer, "ink.Thickness = BADGE.Stroke")
			and has(drawer, "pinBang.Size = UDim2.fromOffset(box.w, math.floor(box.h * BADGE.Scale))"),
		"scrolled so INVITE's \"!\" would be cut, the panel pins it to its top edge over a top fade, in INVITE's look")
	check(has(drawer, "pin.Activated:Connect(function()") and has(drawer, "{ CanvasPosition = Vector2.zero }")
			and has(drawer, "if not shut and lastShut ~= false then\n\t\tscroll.CanvasPosition = Vector2.zero"),
		"a tap on the pinned \"!\" scrolls to the top; the panel opens at the top on joining and after being shut")
	check(has(ui, "bang.Visible = want and player:GetAttribute(PIN) ~= true")
			and has(ui, "player:GetAttributeChangedSignal(PIN):Connect(refreshBadge)")
			and PP.PinAttribute ~= nil and PP.PinAttribute ~= PP.ShutAttribute and PP.PinPad > 0,
		"INVITE's own \"!\" hides while the panel shows it pinned")
	for _, name in ipairs({ "SettingsUI", "EventsUI", "UpdateLogUI", "InviteUI" }) do
		local src = sourceOf(StarterPlayer, name)
		check(has(src, "UIKit.placeRail(button, layout,")
				and has(src, "MenuKit.tap(button, UIKit.railDockScroll(playerGui), function()"),
			name .. ": its own square, in the panel's scrolling canvas on a phone; a tap presses it, a drag scrolls")
	end
	from = kit:find("function UIKit.railDockScroll", 1, true)
	body = if from then kit:sub(from, (kit:find("\nend\n", from, true) or #kit)) else ""
	check(has(body, "scroll.ScrollingDirection = Enum.ScrollingDirection.Y")
			and has(body, "scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y") and has(body, "scroll.ScrollBarThickness = 3"),
		"the panel's canvas scrolls up and down only, sized by its squares, a thin bar")
	from = kit:find("function UIKit.placeRail", 1, true)
	body = if from then kit:sub(from, (kit:find("\nend\n", from, true) or #kit)) else ""
	check(has(body, "button.Position = UDim2.fromOffset(r.x - view.x, r.y - view.y)")
			and has(body, "button.Parent = if layout.sidebar then UIKit.railDock(playerGui) else UIKit.railLayer(playerGui)"),
		"a square stands at its HudLayout place: in the canvas on a phone, in the rail layer elsewhere")

	--==========================================================================
	say("-- 6. the owner's picture --")
	check(RAIL.StuddedInviteArt == "rbxassetid://87744294855846" and RAIL.StuddedInviteAspect == 1,
		"INVITE's picture is the owner's one id, measured square (1024 x 1024)")
	check(has(ui, "UIKit.railPicture(button, RAIL.StuddedInviteArt, RAIL.StuddedInviteAspect)")
			and has(ui, "ContentProvider:PreloadAsync({ picture })") and has(ui, "if not picture.IsLoaded then"),
		"drawn whole by UIKit.railPicture on every screen, preloaded on the drawn ImageLabel itself")
end)

if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end
say(string.format("InviteHudSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
