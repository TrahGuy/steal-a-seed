--!nocheck
--==============================================================================
-- Steal a Seed :: InvitePanelSpec
--
-- The INVITE panel and the reward popup (2026-10-06), by MenuLayout's and
-- InviteRewards' own arithmetic and the scripts' source, in Edit:
--
--   THE PANEL
--   1. on every listed screen: inside the safe area, between the rails on a
--      desktop, covering the rail elsewhere, no sidebar and no chooser; the
--      title, its picture and the close in one row
--   2. the page: every block inside the column and clear of every other; the
--      track's four cards whole or scrolling sideways, never under CardMinW;
--      a finger-sized button; nothing scrolls up and down on a listed screen
--   3. every word fits at the smallest size it may be drawn
--   4. the states for 0, 1, 4, 5, 12, 20 and 50 friends
--   5. the wiring: one panel at a time, Escape only while open, a controller
--      on INVITE FRIENDS, the "!" cleared on open, nothing counted or granted
--
--   THE REWARD POPUP
--   6. each tier's card: words, rim, intensity, how long it stays
--   7. the queue: lowest first, each once, never over another reward moment
--   8. the card's place on every listed screen: clear of every HUD rect, the
--      upper middle, its words readable at the size it is drawn
--   9. the wiring: no dimmer, never modal, never the GUI selection, PLACE IT
--      as the Bag holds a plant
--
-- Not here, seen in Play instead: the panel and the card on screen, the
-- ViewportFrames, taps, a real invite (never pressed from a tool).
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)
local MenuLayout = require(Shared.MenuLayout)
local InviteRewards = require(Shared.InviteRewards)
local RewardMoments = require(Shared.RewardMoments)

local CONFIG = GameConfig.InviteRewards
local WORDS = CONFIG.Words
local POP = CONFIG.Popup
local PANEL = CONFIG.Panel
local RAIL = GameConfig.Rail
local LOOK = GameConfig.BagLook
local I = MenuLayout.Invite
local OUTLINE = RAIL.OutlineThickness
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
-- The code without its comments, for the checks about what RUNS.
local function code(src)
	return (src:gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", ""))
end
local function overlaps(a, b)
	return a.w > 0 and a.h > 0 and b.w > 0 and b.h > 0 and a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h
		and b.y < a.y + a.h
end
local function within(r, box)
	return r.x >= box.x - 0.01 and r.y >= box.y - 0.01 and r.x + r.w <= box.x + box.w + 0.01
		and r.y + r.h <= box.y + box.h + 0.01
end
local function width(text, size, font)
	return TextService:GetTextSize(text, size, font, Vector2.new(10000, 1000)).X
end

-- HudLayoutSpec's screens.
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
local cases = {}
for _, d in ipairs({ { 1280, 720 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 2560, 1440 }, { 1000, 609 } }) do
	table.insert(cases, { tag = string.format("%dx%d desktop", d[1], d[2]), input = screen(d[1], d[2]), desk = true })
end
table.insert(cases, { tag = "860x700 window", input = screen(860, 700, { touch = false }) })
table.insert(cases, { tag = "700x400 window", input = screen(700, 400, { touch = false }) })
for _, p in ipairs({ { 640, 480 }, { 772, 360 }, { 874, 402 }, { 896, 414 }, { 956, 440 }, { 1000, 609 }, { 705, 338 },
	{ 640, 360 }, { 801, 392 } }) do
	table.insert(cases, { tag = string.format("%dx%d phone", p[1], p[2]),
		input = screen(p[1], p[2], { touch = true, keyboard = false }) })
end
for _, p in ipairs({ { 874, 402, 62, "iPhone 16 Pro" }, { 956, 440, 62, "iPhone 16 Pro Max" },
	{ 896, 414, 48, "iPhone 11" }, { 844, 390, 47, "iPhone 12/13/14" } }) do
	table.insert(cases, { tag = string.format("%dx%d %s", p[1], p[2], p[4]),
		input = screen(p[1], p[2], { touch = true, keyboard = false, left = p[3], right = p[3], bottom = 21 }) })
end
for _, t in ipairs({ { 1920, 1080, 0 }, { 1280, 720, 36 }, { 3840, 2160, 0 } }) do
	table.insert(cases, { tag = string.format("%dx%d TV", t[1], t[2]), input = HudLayout.tenFootInput({
		safe = Vector2.new(t[1], t[2] - t[3]), touch = false, keyboard = false, viewport = Vector2.new(t[1], t[2]),
		topbar = rect(0, 0, 0, t[3]), insetTop = t[3] }), tv = true })
end

-- The longest of each kind of word the panel and the cards can show.
local NAMES, RARITIES, INCOMES, NEXTS = {}, {}, {}, {}
for tier = 1, InviteRewards.Count do
	local r = InviteRewards.reward(tier)
	table.insert(NAMES, r.name)
	table.insert(RARITIES, string.upper(r.rarity))
	table.insert(INCOMES, r.incomeText)
end
for _, n in ipairs({ 0, 1, 5, 10 }) do
	table.insert(NEXTS, InviteRewards.content(n, InviteRewards.tierFor(n)).nextText)
end
local function widest(list, size, font, upper)
	local best = 0
	for _, text in ipairs(list) do
		best = math.max(best, width(if upper then string.upper(text) else text, size, font))
	end
	return best
end

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1-3. the panel on every listed screen --")
	local arrangements = {}
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		local tag = case.tag
		local s = { safe = L.safe, compact = L.compact, railRight = L.railRight, rightLeft = L.rightLeft }
		local p = MenuLayout.invitePanel(s, OUTLINE)
		local r = p.rect
		local gap = MenuLayout.Config.EdgeGap
		check(r.x >= gap - 0.01 and r.y >= gap - 0.01 and r.x + r.w <= L.safe.X - gap + 0.01
				and r.y + r.h <= L.safe.Y - gap + 0.01 and not p.sidebar,
			tag .. ": the panel inside the safe area, no sidebar", r2s(r))
		if p.covers then
			check(L.compact or L.rightLeft - L.railRight < MenuLayout.Config.MinBetween + gap * 2,
				tag .. ": covers the rail only where there is no room between the rails")
		else
			check(r.x >= L.railRight and r.x + r.w <= L.rightLeft, tag .. ": between the rails", r2s(r))
		end
		-- The title, its picture and the close in one row.
		local titleSize = if p.short then LOOK.TitleSizeShort else LOOK.TitleSize
		local iconSize = if p.short then 28 else 34
		local row = iconSize + 4 + width(WORDS.Title, titleSize, Enum.Font.LuckiestGuy) + 8
		local room = p.shell.X - p.pad * 2 - MenuLayout.Config.Touch - MenuLayout.Config.Gap
		check(row <= room, tag .. ": INVITE FRIENDS, its picture and the close fit the header row",
			string.format("%d of %d", row, room))
		local main = MenuLayout.blocks(p).main
		local b = MenuLayout.invitePage(p)
		local page = rect(0, 0, main.w, b.height)
		local blocks = { picture = b.picture, name = b.name, rarity = b.rarity, income = b.income, tag = b.tag,
			bar = b.bar, nextLine = b.nextLine, track = b.track, button = b.button, how = b.how }
		local outside, clash = {}, {}
		for key, a in pairs(blocks) do
			if not within(a, page) then
				table.insert(outside, key .. r2s(a))
			end
			for other, c in pairs(blocks) do
				if key < other and overlaps(a, c) then
					table.insert(clash, key .. "/" .. other)
				end
			end
		end
		table.sort(clash)
		check(#outside == 0 and #clash == 0, tag .. ": every block inside the page, none over another",
			table.concat(outside, " ") .. " " .. table.concat(clash, " "))
		check(b.height <= main.h + 0.5, tag .. ": the whole page shows -- nothing scrolls up and down",
			string.format("page %d column %d", b.height, main.h))
		-- Dense, the rarity and the rate share a line: a gap between, or a word
		-- that fills its room runs into the rate ("LEGENDARY$25K/s", a phone).
		check(not b.dense or b.income.x - (b.rarity.x + b.rarity.w) >= I.GapShort,
			tag .. ": the rate stands a gap after the rarity word", r2s(b.rarity) .. " " .. r2s(b.income))
		-- The track.
		local cardW = b.cards[1].w
		local canvas = rect(0, 0, b.trackCanvas, b.track.h)
		local cardsOk = cardW >= I.CardMinW and cardW <= I.CardW
		for i, c in ipairs(b.cards) do
			cardsOk = cardsOk and within(c, canvas) and c.w == cardW and (i == 1 or c.x >= b.cards[i - 1].x + cardW)
		end
		check(cardsOk and b.trackScrolls == (b.cards[4].x + cardW > b.track.w + 0.5) and within(b.road, canvas),
			tag .. string.format(": four %d-px cards on their road, %s", cardW,
				if b.trackScrolls then "scrolling sideways" else "all in view"))
		check(b.button.h >= MenuLayout.Config.Touch and b.button.w >= 200,
			tag .. ": INVITE FRIENDS a full finger's target", r2s(b.button))
		local c = MenuLayout.inviteCard(cardW, b.cards[1].h, b.dense)
		local box = rect(0, 0, cardW, b.cards[1].h)
		local inner = { c.preview, c.name, c.rarity, c.income, c.needs }
		local cardOk = within(c.tick, c.preview) and within(c.claimed, c.preview)
		for k, a in ipairs(inner) do
			cardOk = cardOk and within(a, box) and a.h > 0
			for m = k + 1, #inner do
				cardOk = cardOk and not overlaps(a, inner[m])
			end
		end
		check(cardOk, tag .. ": a card's picture and four lines inside it, the tick and CLAIMED on the picture")
		-- 3. Every word at its smallest drawn size.
		local MIN, TINY = PANEL.MinText, PANEL.TinyText
		local tight = {}
		local function fits(label, need, space)
			if need > space + 0.5 then
				table.insert(tight, string.format("%s %d>%d", label, need, space))
			end
		end
		fits("hero name", widest(NAMES, MIN, Enum.Font.LuckiestGuy, true), b.name.w)
		fits("hero rarity", widest(RARITIES, MIN, LOOK.LabelFont), b.rarity.w)
		fits("hero income", widest(INCOMES, MIN, LOOK.LabelFont), b.income.w)
		fits("Unsellable", width(WORDS.Unsellable, TINY, LOOK.LabelFont), b.tag.w - 8)
		fits("NEXT", widest(NEXTS, MIN, LOOK.LabelFont), b.nextLine.w)
		fits("FINAL", width(WORDS.Final, MIN, LOOK.LabelFont), b.nextLine.w)
		fits("how", width(WORDS.How, MIN, LOOK.BodyFont), b.how.w)
		-- The rules, one line at a time under the button (2026-10-08): each must
		-- fit the same line, on every screen listed (the phones included).
		for i, rule in ipairs(WORDS.Rules) do
			fits("rule " .. i, width(rule, MIN, LOOK.BodyFont), b.how.w)
		end
		fits("button", width(WORDS.Button, 9, LOOK.LabelFont), b.button.w - 10)
		fits("card name", widest(NAMES, MIN, LOOK.LabelFont), c.name.w)
		fits("card rarity", widest(RARITIES, TINY, LOOK.LabelFont), c.rarity.w)
		fits("card income", widest(INCOMES, TINY, LOOK.BodyFont), c.income.w)
		fits("card needs", width(string.format(WORDS.Needs, 20, WORDS.Many), TINY, LOOK.BodyFont), c.needs.w)
		-- An owned card's line when the wheel gave some (InviteRewards.cards, 2026-10-08).
		fits("card owned", width(WORDS.Owned, TINY, LOOK.BodyFont), c.needs.w)
		fits("CLAIMED", width(WORDS.Claimed, TINY, LOOK.LabelFont), c.claimed.w)
		check(#tight == 0, tag .. ": every word fits at its smallest drawn size", table.concat(tight, "; "))
		local kind = (if b.split then "side by side" elseif b.dense then "dense" else "stacked")
			.. (if b.trackScrolls then ", track scrolls" else "")
		arrangements[kind] = (arrangements[kind] or 0) + 1
		say(string.format("    %s: panel %s, column %dx%d, %s", tag, r2s(r), main.w, main.h, kind))
	end
	local summary = {}
	for kind, n in pairs(arrangements) do
		table.insert(summary, string.format("%s x%d", kind, n))
	end
	table.sort(summary)
	say("  arrangements: " .. table.concat(summary, ", "))

	--==========================================================================
	say("-- 4. the states --")
	local want = {
		[0] = { "next,locked,locked,locked", "dustthorn", "0 / 1", "NEXT: Dustthorn (Epic) at 1 invite" },
		[1] = { "earned,next,locked,locked", "dustthorn", "1 / 5", "NEXT: Thornbrute (Legendary) at 5 invites" },
		[4] = { "earned,next,locked,locked", "dustthorn", "4 / 5", "NEXT: Thornbrute (Legendary) at 5 invites" },
		[5] = { "earned,earned,next,locked", "thornbrute", "5 / 10", "NEXT: Pharaothorn (Mythic) at 10 invites" },
		[12] = { "earned,earned,earned,next", "pharaothorn", "12 / 20", "NEXT: Heliothorn (Secret) at 20 invites" },
		[20] = { "earned,earned,earned,earned", "heliothorn", "20 / 20", nil },
		[50] = { "earned,earned,earned,earned", "heliothorn", "50 / 20", nil },
	}
	for _, n in ipairs({ 0, 1, 4, 5, 12, 20, 50 }) do
		local g = InviteRewards.tierFor(n)
		local list = {}
		for _, card in ipairs(InviteRewards.cards(n, g)) do
			table.insert(list, card.state)
		end
		local got = table.concat(list, ",")
		local content = InviteRewards.content(n, g)
		local w = want[n]
		local final = n >= 20
		check(got == w[1] and content.shown.form == w[2] and content.barText == w[3] and content.nextText == w[4]
				and content.final == final and (not final or (content.finalText == WORDS.Final and content.fraction == 1)),
			string.format("%d friend(s): cards %s, the hero %s, the bar %s, %s", n, w[1], w[2], w[3],
				w[4] or "FINAL FORM REACHED"),
			got .. " " .. content.shown.form .. " " .. content.barText .. " " .. tostring(content.nextText))
	end
	check(InviteRewards.cards(0, 0)[4].gold and InviteRewards.cards(20, 4)[4].gold
			and not InviteRewards.cards(20, 4)[3].gold,
		"Heliothorn's card gold-rimmed whether locked, next or earned")
	check(InviteRewards.content(12, 1).shown.form == "dustthorn" and InviteRewards.cards(12, 1)[2].state == "next",
		"never ahead of the grant: 12 friends with one form given shows the first, the second NEXT")

	--==========================================================================
	say("-- 5. the panel's wiring --")
	local ui = sourceOf(StarterPlayer, "InviteUI")
	local server = sourceOf(ServerScriptService, "InviteService")
	check(has(ui, "MenuKit.modal(gui, PANEL_NAME, WORDS.Title, RAIL.StuddedInviteArt, nil)")
			and has(ui, "MenuKit.baseplate(body, Z - 1)") and has(ui, "MenuLayout.invitePanel(")
			and has(ui, "MenuLayout.inviteBlocks(main.w, main.h, p.short)") and not has(ui, "MenuKit.chooser")
			and not has(ui, "MenuKit.segmented") and not has(ui, "MenuKit.search"),
		"the Shop's and the Index's sibling: MenuKit's modal by the invite picture, the baseplate, MenuLayout's "
			.. "rects -- and no chooser")
	check(has(ui, "player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)") and has(ui, "UIKit.coverRail(playerGui, PANEL_NAME")
			and has(ui, "if state.open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then"),
		"one panel at a time (OpenPanel), covering the rail where it takes the screen")
	check(has(ui, "Enum.KeyCode.Escape, Enum.KeyCode.Backspace)") and has(ui, "ContextActionService:UnbindAction(CLOSE_ACTION)")
			and has(ui, "padFirst.Value = send.hit") and has(ui, "ui.face.NextSelectionLeft")
			and has(ui, "face.SelectionGained:Connect(function()"),
		"Escape only while open; a controller starts on INVITE FRIENDS and walks the cards left and right")
	check(has(ui, "MenuKit.tap(send.hit, page, function()\n\tInviteSend.prompt()"),
		"INVITE FRIENDS asks Roblox's own dialog (InviteSend); a drag on the page never presses it")
	check(has(ui, "remote:FireServer(CONFIG.OpenedAction)") and has(server, "if action == CONFIG.OpenedAction then")
			and has(server, "InviteService.MarkSeen(player)") and has(server, "profile.InviteSeen = true"),
		"opening it clears the \"!\": the server's seen flag, through the save's own path")
	local fires = select(2, code(ui):gsub("FireServer%(", ""))
	check(fires == 1 and not has(ui, "Thresholds") and has(ui, "InviteRewards.content(count, granted, owned)")
			and has(ui, "InviteRewards.cards(count, granted, owned)")
			and has(ui, "InviteRewards.ownedSet(player:GetAttribute(A.Owned))"),
		"it counts and grants nothing: one call to the server (opened), every number InviteRewards' answer "
			.. "(the plants owned, the wheel's included, the server's attribute)")
	check(has(ui, 'ui.view.ImageColor3 = if c.state == "locked" then CONFIG.Silhouette else WHITE')
			and has(ui, "gui.Parent = playerGui"),
		"a LOCKED form is its own model as a dark silhouette; every ViewportFrame in the PlayerGui")

	--==========================================================================
	say("-- 6. the reward cards --")
	local ribbons, closes = {}, {}
	for tier = 1, InviteRewards.Count do
		local c = InviteRewards.popup(tier)
		table.insert(ribbons, c.ribbon)
		table.insert(closes, tostring(c.autoClose))
		local friends = if c.at == 1 then POP.Friend else POP.Friends
		check(c.line == string.format("Invite reward: %d %s \u{2022} Unsellable", c.at, friends),
			string.format("%s: \"%s\"", c.name, c.line))
		check(c.rim == (c.intensity.rim or GameConfig.RarityColor[c.rarity]) and c.colour == GameConfig.RarityColor[c.rarity],
			c.name .. ": the rim in its rarity's colour" .. (if c.intensity.rim then " -- gold for the Secret" else ""))
	end
	check(table.concat(ribbons, "|") == "NEW FORM UNLOCKED!|NEW FORM UNLOCKED!|NEW FORM UNLOCKED!|FINAL FORM!",
		"NEW FORM UNLOCKED! for three, FINAL FORM! for Heliothorn", table.concat(ribbons, "|"))
	check(table.concat(closes, ",") == "8,8,8,12", "closes itself after 8 s, Heliothorn's after 12", table.concat(closes, ","))
	local e, l, m, s = InviteRewards.popup(1).intensity, InviteRewards.popup(2).intensity, InviteRewards.popup(3).intensity,
		InviteRewards.popup(4).intensity
	check(e.rays > 0 and e.sparkles == 0 and not e.edge and e.confetti == 0, "Epic: rim and rays")
	check(l.sparkles > 0 and l.rays >= e.rays and not l.edge and l.confetti == 0, "Legendary: + sparkles round the form")
	check(m.rays > l.rays and m.sparkleSize > l.sparkleSize and m.edge and m.confetti == 0,
		"Mythic: brighter rays, larger sparkles, the short edge glow")
	check(s.confetti > 0 and s.burst > m.burst and s.burst > l.burst and s.rim == CONFIG.Gold and s.edge,
		"Secret: the gold rim, the longest burst, confetti")

	--==========================================================================
	say("-- 7. the queue --")
	local q = {}
	check(InviteRewards.enqueue(q, 3) and InviteRewards.enqueue(q, 1) and not InviteRewards.enqueue(q, 3)
			and not InviteRewards.enqueue(q, 0) and not InviteRewards.enqueue(q, 5),
		"each form given joins once; nonsense never does")
	check(InviteRewards.nextCard(q, true) == nil and #q == 2, "nothing while another moment or a panel is up")
	check(InviteRewards.nextCard(q, false) == 1 and InviteRewards.nextCard(q, false) == 3
			and InviteRewards.nextCard(q, false) == nil,
		"two forms at once: one card each, lowest first")
	local attrs = {}
	local who = {
		GetAttribute = function(_, k)
			return attrs[k]
		end,
		GetAttributes = function()
			return attrs
		end,
	}
	local open = GameConfig.Attributes.OpenPanel
	local idle = RewardMoments.busy(who, open)
	attrs[RewardMoments.Prefix .. "hatch"] = true
	local hatching = RewardMoments.busy(who, open)
	attrs[RewardMoments.Prefix .. "hatch"] = nil
	attrs[open] = "Invite"
	local panelUp = RewardMoments.busy(who, open)
	attrs[open] = nil
	attrs[RewardMoments.Prefix .. "offline"] = true
	local offline = RewardMoments.busy(who, open)
	check(not idle and hatching and panelUp and offline,
		"a card waits through a hatch reveal, the offline earnings and any open panel (the wheel's prize is one)")
	local hatch, offlineSrc = sourceOf(StarterPlayer, "HatchFX"), sourceOf(StarterPlayer, "OfflineUI")
	check(has(hatch, 'RewardMoments.begin("hatch"') and has(offlineSrc, 'RewardMoments.begin("offline")')
			and has(offlineSrc, 'RewardMoments.finish("offline")'),
		"the hatch reveal and the offline earnings card say when they are up")

	--==========================================================================
	say("-- 8. the card on every listed screen --")
	local P = MenuLayout.Popup
	for _, shape in ipairs({ "tall", "wide" }) do
		local B = MenuLayout.popupBlocks(shape)
		local card = rect(0, 0, B.size.X, B.size.Y)
		local blocks = { B.ribbon, B.stage, B.name, B.pill, B.income, B.line, B.place, B.later }
		local inCard = within(B.ring, B.later) and within(B.view, B.stage)
		for k, a in ipairs(blocks) do
			inCard = inCard and within(a, card)
			for n = k + 1, #blocks do
				inCard = inCard and not overlaps(a, blocks[n])
			end
		end
		check(inCard, "the " .. shape .. " card's ribbon, stage, words and buttons inside it, none over another")
	end
	local shapes = {}
	local lines = {}
	for tier = 1, InviteRewards.Count do
		table.insert(lines, InviteRewards.popup(tier).line)
	end
	local smallest, smallestTag = math.huge, ""
	local overToastOn = {}
	for _, case in ipairs(cases) do
		local L = HudLayout.solve(case.input)
		local r, scale, shape = MenuLayout.rewardPopup(L.safe, HudLayout.occupied(L), L.sidebar)
		-- With no place clear of the notices' line too, the line gives way
		-- (InviteRewardUI; 2026-10-09, a 640 x 360 phone under the panel's row).
		local overToast = r.w <= 0
		if overToast then
			r, scale, shape = MenuLayout.rewardPopup(L.safe, HudLayout.occupiedButToast(L), L.sidebar)
			table.insert(overToastOn, case.tag)
		end
		local B = MenuLayout.popupBlocks(shape)
		local tag = case.tag
		check(r.w > 0 and scale >= P.MinScale, tag .. ": the card has a place", r2s(r))
		if r.w <= 0 then
			continue
		end
		local clash = {}
		for _, a in ipairs(if overToast then HudLayout.occupiedButToast(L) else HudLayout.occupied(L)) do
			if overlaps(r, a) then
				table.insert(clash, r2s(a))
			end
		end
		check(#clash == 0 and r.x >= P.Gap and r.y >= P.Gap and r.x + r.w <= L.safe.X - P.Gap
				and r.y + r.h <= L.safe.Y - P.Gap,
			tag .. ": clear of every HUD rect, on the glass", table.concat(clash, " "))
		check(math.abs(r.x + r.w / 2 - L.safe.X / 2) <= 1 and r.y + r.h / 2 <= L.safe.Y * 0.62,
			tag .. ": centred, in the upper middle", r2s(r))
		if not L.sidebar then
			check(r.w <= L.safe.X * P.WidthShare + 1, tag .. ": no wider than 40% of the screen",
				string.format("%.0f%%", r.w / L.safe.X * 100))
		end
		-- Its words at the size they are drawn (the card scales whole; a word's
		-- smallest DRAWN size is its constraint's minimum).
		local tight = {}
		local function fits(label, text, font, minDrawn, space)
			local need = width(text, minDrawn, font)
			if need > space * scale + 0.5 then
				table.insert(tight, string.format("%s %d>%d", label, need, math.floor(space * scale)))
			end
		end
		for _, line in ipairs(lines) do
			fits("line", line, LOOK.BodyFont, 9, B.line.w)
		end
		fits("name", "PHARAOTHORN", Enum.Font.LuckiestGuy, 12, B.name.w)
		fits("ribbon", POP.Ribbon, Enum.Font.LuckiestGuy, 10, B.ribbon.w - 12)
		fits("pill", "LEGENDARY", LOOK.LabelFont, 9, B.pill.w - 10)
		fits("income", "$175K/s", LOOK.LabelFont, 10, B.income.w)
		check(#tight == 0, tag .. string.format(": every word readable at x%.2f", scale), table.concat(tight, "; "))
		if scale < smallest then
			smallest, smallestTag = scale, tag
		end
		shapes[shape] = (shapes[shape] or 0) + 1
		say(string.format("    %s: %s card %s at x%.2f, %.0f%% of the width, PLACE IT %d px tall", tag, shape, r2s(r),
			scale, r.w / L.safe.X * 100, math.floor(B.place.h * scale)))
	end
	say(string.format("  smallest card: x%.2f on %s; tall on %d screens, wide on %d", smallest, smallestTag,
		shapes.tall or 0, shapes.wide or 0))
	say("  over the notices' line (no place clear of it): " .. (if #overToastOn > 0 then table.concat(overToastOn, ", ")
		else "none"))
	do
		local only = true
		for _, tag in ipairs(overToastOn) do
			only = only and string.find(tag, "640x360", 1, true) ~= nil
		end
		check(only, "the card stands over the notices' line only where nothing else clears: the 640 x 360 phone",
			table.concat(overToastOn, ", "))
	end
	check((shapes.tall or 0) > 0 and cases[1].desk, "every desktop and TV the tall card; the wide one where it reads larger")

	--==========================================================================
	say("-- 9. the card's wiring --")
	local pop = sourceOf(StarterPlayer, "InviteRewardUI")
	local run = code(pop)
	check(has(pop, "local r, scale, shape = MenuLayout.rewardPopup(L.safe, HudLayout.occupied(L), L.sidebar)")
			and has(pop, "\tif r.w <= 0 then\n")
			and has(pop, "r, scale, shape = MenuLayout.rewardPopup(L.safe, HudLayout.occupiedButToast(L), L.sidebar)"),
		"the card keeps off the notices' line, and stands over it only where nothing else clears")
	check(not has(run, "Dimmer") and not has(run, "dimmer") and not has(run, "Modal = true")
			and has(run, "card.Active = false") and not has(run, "ModalEnabled"),
		"no dimmer, nothing modal: the card takes no press but its two buttons")
	check(not has(run, "SelectedObject") and not has(run, "Thumbstick") and not has(run, "KeyCode.Up")
			and not has(run, "KeyCode.Left") and not has(run, "KeyCode.W") and not has(run, "WalkSpeed")
			and not has(run, "CameraType"),
		"never the GUI selection, the arrows, the stick, the walk or the camera")
	check(has(pop, "Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.ButtonA)")
			and has(pop, "Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)") and has(pop, "\tbindKeys()\n")
			and has(pop, "\tunbindKeys()\n"),
		"Enter or A = PLACE IT, Escape or B = LATER, bound only while a card is up")
	check(has(pop, "humanoid:EquipTool(tool)") and has(pop, 'raise("CARRYING_POD")') and has(pop, "HatchRoll.sealed(tool)"),
		"PLACE IT holds the plant as the Bag does: never over a carried pod, never a sealed roll")
	check(has(pop, "InviteRewards.nextCard(queue, busy())") and has(pop, "return RewardMoments.busy(player, ATTR.OpenPanel)")
			and has(pop, 'closeWith("panel")') and has(pop, 'closeWith("auto")'),
		"the queue waits on every reward moment and panel; a panel opening takes a card down; untouched it goes")
	check(has(pop, "paint(c)\n\tif not placeCard() then") and has(pop, "if not still then\n\t\tenter(up, c)"),
		"painted and placed before any tween: the card is complete with no animation")
	check(has(pop, 'payload.kind == "granted" and InviteRewards.enqueue(queue, payload.tier)'),
		"a card only for a form the server says it gave")
	-- A Play at 705 x 338 (2026-10-06): sized to the gui, the glow stopped in a
	-- hard line at the notch strips and under the topbar's band.
	check(has(pop, "wholeGui.ScreenInsets = Enum.ScreenInsets.None")
			and has(pop, "edgeGlow(colour: Color3, seconds: number)\n\treachEdges()")
			and has(pop, "edges.Size = UDim2.new(1, left + right, 1, top + bottom)"),
		"the edge glow reaches past the gui's insets to the screen's own edges")
end)

if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end
say(string.format("InvitePanelSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
