--!nocheck
--==============================================================================
-- Steal a Seed :: TutorialSpotlightSpec (the owner's spotlight brief, 2026-10-08)
--
-- The guide's pointing hand and its spotlight, held to every screen HudLayout
-- lays out: desktops, phones (Studio's 705 x 338 emulation with its notches and
-- home bar, real notched phones) and TVs (the ten-foot profile). Pure
-- arithmetic (TutorialSpotlight) on HudLayout's own rects, plus the wiring the
-- brief names, read from the scripts' source. Edit mode, no Play.
--
-- WHAT IS PROVED
--   1. the hand is the owner's one asset, and nothing else was added
--   2. on every listed screen, for TELEPORT, BIOMES, OBBY, SPEED and a hotbar
--      slot: the window lands on the target (whole, padded, never lighting a
--      neighbour), the hand stands outside it, on screen, its fingertip at the
--      window's edge at the top of a tap -- never covering the target -- and
--      the words beside it on screen, clear of both; the dim reaches every
--      corner, the notch and the topbar included
--   3. no spotlight in any NEVER case, and each one's single life per step
--   4. the wiring: the spotlight's gui over every HUD button, the three buttons'
--      D-pad keys while lit, the notice count, the server record path
--
-- NOT HERE (Play, or a real device): the touch thumbstick and jump under the
-- dim on a phone (the blockers never cover them -- placed only over buttons --
-- but no phone was in hand), a real controller's A and D-pad.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Spot = require(Shared:WaitForChild("TutorialSpotlight"))
local TutorialData = require(Shared:WaitForChild("TutorialData"))
local Notice = require(Shared:WaitForChild("Notice"))

local Client = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Server = ServerScriptService:WaitForChild("SeedGameServer")

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(instance)
	if instance == nil then
		return ""
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function count(src, needle)
	local n, at = 0, 1
	while true do
		local s, e = string.find(src, needle, at, true)
		if not s then
			return n
		end
		n += 1
		at = e + 1
	end
end

local FONT = Enum.Font.LuckiestGuy
local function textW(text, size)
	return TextService:GetTextSize(text, size, FONT, Vector2.new(4000, 400))
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE HAND IS THE OWNER'S ONE ASSET
	--==========================================================================
	say("-- the hand --")
	local spotSrc = sourceOf(Shared:FindFirstChild("TutorialSpotlight"))
	local uiSrc = sourceOf(Client:FindFirstChild("TutorialUI"))
	check(Spot.Hand.Image == "rbxassetid://77822355284810", "the hand is the owner's image 77822355284810",
		Spot.Hand.Image)
	local ids = {}
	for id in string.gmatch(spotSrc .. "\n" .. uiSrc, "rbxassetid://(%d+)") do
		ids[id] = true
	end
	local listed = {}
	for id in pairs(ids) do
		table.insert(listed, id)
	end
	table.sort(listed)
	-- 18518488457 is the trail's flowing-arrow texture, in TutorialUI since before
	-- this brief; the hand is the only id the brief added.
	check(#listed == 2 and ids["77822355284810"] and ids["18518488457"],
		"no other asset id: the hand, and the trail's arrows that were already there", table.concat(listed, ","))
	check(not has(uiSrc, "\\u{25B6}") and not has(uiSrc, "\\u{25BC}") and not has(uiSrc, "\\u{25C0}")
			and not has(uiSrc, "Instance.new(\"BillboardGui\")"),
		"the gold pointer glyph and the world's green finger billboard are gone (the hand replaced both)")
	check(Spot.Hand.Tip.X > 0.5 and Spot.Hand.Tip.X < 0.7 and Spot.Hand.Tip.Y >= 0 and Spot.Hand.Tip.Y < 0.05,
		"the fingertip is measured at the top of the drawn glove, right of centre (0.589, 0.013)",
		tostring(Spot.Hand.Tip))
	-- Turned, the fingertip leads the way it points.
	local up, right, down, left = Spot.tipOffset(0, 100), Spot.tipOffset(90, 100), Spot.tipOffset(180, 100),
		Spot.tipOffset(-90, 100)
	check(up.Y < -45 and right.X > 45 and down.Y > 45 and left.X < -45,
		"turned 0 / 90 / 180 / -90 degrees the fingertip points up, right, down and left",
		string.format("%s %s %s %s", tostring(up), tostring(right), tostring(down), tostring(left)))

	--==========================================================================
	-- 2. EVERY SCREEN, EVERY TARGET
	--==========================================================================
	say("\n-- the screens --")
	local TOPBAR, BAR_LEFT = 58, 208
	local function rect(x, y, w, h)
		return { x = x, y = y, w = w, h = h }
	end
	-- A screen: the whole of it (W x H, the spotlight gui), the HUD gui's origin
	-- inside it (the notch and the topbar), its safe size, and the TV scale.
	local function screen(tag, W, H, touch, left, bottom, phone)
		left, bottom = left or 0, bottom or 0
		local safe = Vector2.new(W - left * 2, H - TOPBAR - bottom)
		return {
			tag = tag,
			W = W,
			H = H,
			ox = left,
			oy = TOPBAR,
			k = 1,
			phone = phone,
			input = {
				safe = safe,
				touch = touch,
				keyboard = not touch,
				viewport = Vector2.new(W - left * 2, H - bottom),
				topbar = rect(BAR_LEFT, 0, W - left * 2 - BAR_LEFT, TOPBAR),
				insetTop = TOPBAR,
			},
		}
	end
	local cases = {}
	for _, d in ipairs({ { 1280, 720 }, { 1366, 768 }, { 1920, 1080 }, { 1009, 716 }, { 1024, 600 } }) do
		table.insert(cases, screen(string.format("desk %dx%d", d[1], d[2]), d[1], d[2], false))
	end
	-- Studio's phone emulation: a 705 x 338 viewport inside a 799 x 359 screen
	-- (47 of notch either side, 21 of home bar), measured 2026-09-28.
	table.insert(cases, screen("phone 705x338 (Studio, notched)", 799, 359, true, 47, 21, true))
	for _, d in ipairs({ { 640, 360 }, { 772, 360 } }) do
		table.insert(cases, screen(string.format("phone %dx%d", d[1], d[2]), d[1], d[2], true))
	end
	for _, d in ipairs({ { 874, 402, 62 }, { 956, 440, 62 }, { 896, 414, 48 }, { 844, 390, 47 } }) do
		table.insert(cases, screen(string.format("phone %dx%d notched", d[1], d[2]), d[1], d[2], true, d[3], 21))
	end
	for _, t in ipairs({ { 1920, 1080, 0 }, { 1280, 720, 36 }, { 3840, 2160, 0 } }) do
		local view = Vector2.new(t[1], t[2])
		local input = HudLayout.tenFootInput({
			safe = Vector2.new(t[1], t[2] - t[3]),
			touch = false,
			keyboard = false,
			viewport = view,
			topbar = rect(0, 0, 0, t[3]),
			insetTop = t[3],
		})
		table.insert(cases, { tag = string.format("TV %dx%d", t[1], t[2]), W = t[1], H = t[2], ox = 0, oy = t[3],
			k = HudLayout.tenFootScale(view), input = input })
	end

	-- A HUD rect (the HUD gui's units) in the spotlight gui's pixels.
	local function toSpot(c, r)
		return rect(r.x * c.k + c.ox, r.y * c.k + c.oy, r.w * c.k, r.h * c.k)
	end
	local function contains(outer, inner)
		return inner.x >= outer.x - 0.01 and inner.y >= outer.y - 0.01 and inner.x + inner.w <= outer.x + outer.w + 0.01
			and inner.y + inner.h <= outer.y + outer.h + 0.01
	end

	local problems, measured, perTarget = {}, 0, {}
	local phoneCase = nil
	for _, c in ipairs(cases) do
		local L = HudLayout.solve(c.input)
		local scr = rect(0, 0, c.W, c.H)
		local size = Spot.Hand.Size * (L.tutorialScale or 1) * c.k
		-- The targets the brief names, where this screen has them.
		local targets = {}
		local top = {}
		for _, name in ipairs({ "teleport", "biomes", "obby" }) do
			local r = L[name]
			if r and r.w > 0 and r.h > 0 then
				top[name] = toSpot(c, r)
			end
		end
		for name, r in pairs(top) do
			local others = {}
			for other, o in pairs(top) do
				if other ~= name then
					table.insert(others, o)
				end
			end
			table.insert(targets, { key = name, rect = r, others = others })
		end
		-- SPEED: CashUI's Speed label inside the cash corner (AnchorPoint 0,1 at
		-- the corner's foot; the label's foot SpeedBottom down from its top), its
		-- glyphs measured as the guide measures them.
		local style = L.cashStyle
		if L.cashRoot and style then
			local rootTop = L.cashRoot.y + L.cashRoot.h - style.Root.Y
			local glyphs = textW("1.06K", style.SpeedSize).X + 6
			local speed = rect(L.cashRoot.x + style.SpeedX, rootTop + style.SpeedBottom - style.SpeedSize - 4,
				glyphs, style.SpeedSize + 4)
			table.insert(targets, { key = "speed", rect = toSpot(c, speed), others = {} })
		end
		-- A hotbar slot: the strip's first.
		local okSlot, slot = pcall(HudLayout.slotRect, L, 1)
		if okSlot and slot and slot.w > 0 then
			table.insert(targets, { key = "slot", rect = toSpot(c, slot), others = {} })
		end

		for _, t in ipairs(targets) do
			measured += 1
			perTarget[t.key] = (perTarget[t.key] or 0) + 1
			local window = Spot.window(t.rect, t.others)
			local tag = c.tag .. " " .. t.key
			if not contains(window, t.rect) then
				table.insert(problems, tag .. ": the window misses its target")
			end
			for _, o in ipairs(t.others) do
				if Spot.overlaps(window, o) then
					table.insert(problems, tag .. ": the window lights a neighbouring button")
				end
			end
			if window.x - t.rect.x > -Spot.MinPad + 0.01 or window.y - t.rect.y > -Spot.MinPad + 0.01 then
				table.insert(problems, tag .. ": the window is not padded")
			end
			-- The dim (a stroke round the window) reaches the farthest corner.
			local farX = math.max(window.x, c.W - (window.x + window.w))
			local farY = math.max(window.y, c.H - (window.y + window.h))
			if math.max(c.W, c.H) * 1.5 < math.sqrt(farX * farX + farY * farY) then
				table.insert(problems, tag .. ": the dim does not reach a corner")
			end
			-- Garden and the Bag, kept off where a side lets it (2026-10-09: at a
			-- phone's left edge over the cash block, where the hand for SPEED stood).
			local avoid = { toSpot(c, L.garden), toSpot(c, L.bag) }
			local hand = Spot.handFor(window, scr, size, avoid)
			if not hand then
				table.insert(problems, tag .. ": no room for the hand")
			else
				if t.key == "speed" then
					for _, a in ipairs(avoid) do
						if Spot.overlaps(hand.rect, a) or Spot.overlaps(hand.tapped, a) then
							table.insert(problems, tag .. ": the hand stands on Garden or the Bag")
						end
					end
				end
				if not (Spot.inside(hand.rect, scr, Spot.Margin) and Spot.inside(hand.tapped, scr, Spot.Margin)) then
					table.insert(problems, tag .. ": the hand leaves the screen")
				end
				if Spot.overlaps(hand.rect, window) or Spot.overlaps(hand.tapped, window)
					or Spot.overlaps(hand.rect, t.rect) or Spot.overlaps(hand.tapped, t.rect) then
					table.insert(problems, tag .. ": the hand covers the target")
				end
				-- At the top of a tap the fingertip is Gap outside the window's edge,
				-- inside its span.
				local bob = Spot.Hand.Bob * (size / Spot.Hand.Size)
				local tip = hand.tip + hand.push * bob
				local edgeGap
				if hand.dir == "up" then
					edgeGap = tip.Y - (window.y + window.h)
				elseif hand.dir == "down" then
					edgeGap = window.y - tip.Y
				elseif hand.dir == "left" then
					edgeGap = tip.X - (window.x + window.w)
				else
					edgeGap = window.x - tip.X
				end
				local along = if hand.dir == "up" or hand.dir == "down" then tip.X else tip.Y
				local lo = if hand.dir == "up" or hand.dir == "down" then window.x else window.y
				local span = if hand.dir == "up" or hand.dir == "down" then window.w else window.h
				local wantGap = Spot.Hand.Gap * (size / Spot.Hand.Size)
				if math.abs(edgeGap - wantGap) > 0.5 or along < lo or along > lo + span then
					table.insert(problems, string.format("%s: the fingertip stops %.1f off the edge (want %.1f)", tag,
						edgeGap, wantGap))
				end
				-- The words: the lit target's own, with a controller's key line.
				local spec = Spot.Targets[t.key]
				local wordSize = math.floor(Spot.Words.Size * (L.tutorialScale or 1) * c.k + 0.5)
				local keySize = math.floor(Spot.Words.KeySize * (L.tutorialScale or 1) * c.k + 0.5)
				local a = textW(spec.words, wordSize)
				local b = if spec.key then textW(spec.key, keySize) else Vector2.zero
				local edge = math.ceil(6 * c.k)
				local w = math.max(a.X, b.X) + edge
				local h = a.Y + edge + (if spec.key then b.Y + 2 else 0)
				local at = Spot.wordsFor(hand, window, scr, w, h, avoid)
				local both = rect(math.min(hand.rect.x, hand.tapped.x), math.min(hand.rect.y, hand.tapped.y),
					hand.rect.w + math.abs(hand.tapped.x - hand.rect.x), hand.rect.h + math.abs(hand.tapped.y - hand.rect.y))
				if not Spot.inside(at, scr, 0) then
					table.insert(problems, tag .. ": the words leave the screen")
				elseif Spot.overlaps(at, window) or Spot.overlaps(at, both) then
					table.insert(problems, tag .. ": the words stand over the window or the hand")
				elseif t.key == "speed" and (Spot.overlaps(at, avoid[1]) or Spot.overlaps(at, avoid[2])) then
					table.insert(problems, tag .. ": the words stand on Garden or the Bag")
				end
			end
		end
		if c.phone then
			phoneCase = { tag = c.tag, n = #targets }
		end
	end
	check(#problems == 0, string.format("on %d screens (desktops, notched phones, TVs), %d target placements: every "
		.. "window lands on its target whole and lights no neighbour, the dim reaches every corner (the notch and the "
		.. "topbar too), the hand stands outside the window and on screen with its fingertip %g px off the window's "
		.. "edge at the top of a tap, never covering the target, and the words stand beside it, on screen, clear of "
		.. "both", #cases, measured, Spot.Hand.Gap), table.concat(problems, " | ", 1, math.min(#problems, 8)))
	check((perTarget.teleport or 0) == #cases and (perTarget.speed or 0) == #cases and (perTarget.slot or 0) == #cases
			and (perTarget.biomes or 0) >= #cases - 2 and (perTarget.obby or 0) >= #cases - 2,
		"TELEPORT, SPEED and a hotbar slot on every screen; BIOMES and OBBY wherever HudLayout gives them a rect",
		string.format("teleport %d speed %d slot %d biomes %d obby %d of %d", perTarget.teleport or 0,
			perTarget.speed or 0, perTarget.slot or 0, perTarget.biomes or 0, perTarget.obby or 0, #cases))
	check(phoneCase ~= nil and phoneCase.n >= 4, "including Studio's 705 x 338 phone, notch and home bar and all",
		phoneCase and phoneCase.n)
	-- The words keep off `avoid` too (2026-10-09): a button where they would
	-- stand, and they stand elsewhere beside the hand.
	do
		local scr = rect(0, 0, 800, 400)
		local window = rect(380, 300, 60, 40)
		local hand = Spot.handFor(window, scr, Spot.Hand.Size)
		local first = hand and Spot.wordsFor(hand, window, scr, 120, 30)
		local moved = hand and Spot.wordsFor(hand, window, scr, 120, 30, { first })
		check(hand ~= nil and first ~= nil and moved ~= nil and not Spot.overlaps(moved, first),
			"the hand's words keep off a button standing where they would go",
			first and moved and string.format("(%g,%g) -> (%g,%g)", first.x, first.y, moved.x, moved.y))
	end

	-- THE LOCKED CHEST'S WORDS (the owner's words, 2026-10-08): on every listed
	-- phone a notice's detail line (GothamBold 12, ActionToastUI's PHONE size)
	-- holds them in the two lines it allows, across the toast rect's width.
	local chestSrc = sourceOf(Client:FindFirstChild("BonusChestUI"))
	local lockedTitle, lockedDetail = string.match(chestSrc, 'LOCKED = { title = "([^"]+)", detail = "([^"]+)" }')
	local chestProblems, phonesMeasured = {}, 0
	for _, c in ipairs(cases) do
		if c.input.touch then
			phonesMeasured += 1
			local L = HudLayout.solve(c.input)
			local width = math.max(160, L.toast.w)
			local b = TextService:GetTextSize(lockedDetail or "", 12, Enum.Font.GothamBold, Vector2.new(width, 10000))
			if b.Y > 12 * 2.6 then
				table.insert(chestProblems, string.format("%s: %d px tall in %d px", c.tag, b.Y, width))
			end
		end
	end
	check(lockedTitle == "CHEST LOCKED" and lockedDetail == "Hatch your first plant to open it."
			and #chestProblems == 0 and phonesMeasured >= 6,
		string.format("the locked chest says \"Hatch your first plant to open it.\" and it fits a notice on all %d "
			.. "listed phones (two lines at the most, at the phone's size)", phonesMeasured),
		table.concat(chestProblems, "; "))

	-- A neighbour 5 px away (a phone's top row): the window stops halfway.
	local w2 = Spot.window(rect(100, 10, 51, 44), { rect(156, 10, 51, 44), rect(44, 10, 51, 44) })
	check(math.abs(w2.x - 97.5) < 0.01 and math.abs(w2.x + w2.w - 153.5) < 0.01 and w2.y == 2 and w2.h == 60,
		"a button 5 px from its neighbours is lit to 2.5 px either side and the full 8 above and below",
		string.format("%.1f..%.1f, %d..%d", w2.x, w2.x + w2.w, w2.y, w2.y + w2.h))

	--==========================================================================
	-- 3. THE NEVER LIST, AND ONE LIFE PER STEP
	--==========================================================================
	say("\n-- never, and once --")
	local clear = { guide = true, alive = true, safe = true, carrying = false, chased = false, panel = false,
		notice = false, moment = false, target = true }
	check(Spot.blocked(clear) == nil, "with nothing in the way it may show")
	local cases2 = {
		{ "guide", false, "guide", "the guide's words not up (hidden, skipped, asking to skip, covered)" },
		{ "alive", false, "dead", "dead or respawning" },
		{ "safe", false, "zone", "outside the Safe Zone" },
		{ "carrying", true, "carrying", "carrying a pod" },
		{ "chased", true, "chase", "during a chase (a guardian waking or chasing)" },
		{ "panel", true, "panel", "a panel open (OpenPanel, any modal, a reward moment)" },
		{ "notice", true, "notice", "a notice up" },
		{ "moment", true, "moment", "the guide's own celebration playing" },
		{ "target", false, "target", "the target hidden or with no rect" },
	}
	local wrong = {}
	for _, row in ipairs(cases2) do
		local f = table.clone(clear)
		f[row[1]] = row[2]
		if Spot.blocked(f) ~= row[3] then
			table.insert(wrong, row[1] .. " -> " .. tostring(Spot.blocked(f)))
		end
	end
	check(#wrong == 0, "NEVER shown: each case alone keeps it off, with its own reason", table.concat(wrong, ", "))

	local S = Spot.Settle
	local light = Spot.newLight()
	check(Spot.advance(light, "notice", false, 0) == nil and light.phase == "waiting",
		"a notice up: it waits, and is not spent")
	check(Spot.advance(light, nil, false, 1) == nil and Spot.advance(light, nil, false, 1 + S - 0.01) == nil
			and light.phase == "waiting",
		string.format("the notice gone, it still waits %.1f s with nothing in the way (the moments after a hatch "
			.. "bring notices in quick succession)", S))
	check(Spot.advance(light, nil, false, 1 + S) == "show" and light.phase == "showing", "then it shows")
	check(Spot.advance(light, nil, true, 2 + S) == "lift" and light.phase == "spent", "pressed: it lifts at once")
	check(Spot.advance(light, nil, false, 3 + S) == nil and light.phase == "spent", "and never shows again in that step")
	local restarted = Spot.newLight()
	Spot.advance(restarted, nil, false, 0)
	Spot.advance(restarted, "notice", false, S - 0.5)
	check(Spot.advance(restarted, nil, false, S) == nil and Spot.advance(restarted, nil, false, S + S) == "show",
		"a notice arriving during the quiet period starts it over")
	local dropped = Spot.newLight()
	Spot.advance(dropped, nil, false, 0)
	Spot.advance(dropped, nil, false, S)
	check(Spot.advance(dropped, "panel", false, S + 0.5) == "drop" and Spot.advance(dropped, nil, false, S + 9) == nil,
		"a NEVER coming true drops it at once, and it does not come back")
	local faded = Spot.newLight()
	Spot.advance(faded, nil, false, 10)
	Spot.advance(faded, nil, false, 10 + S)
	check(Spot.advance(faded, nil, false, 10 + S + Spot.FadeAfter - 0.01) == nil
			and Spot.advance(faded, nil, false, 10 + S + Spot.FadeAfter) == "fade",
		string.format("unpressed, the dim fades after %d s", Spot.FadeAfter))
	check(math.abs(Spot.Dim - 0.65) < 1e-6 and Spot.Pad == 8, "65% black, a window padded about 8 px")

	--==========================================================================
	-- 4. THE WIRING
	--==========================================================================
	say("\n-- the wiring --")
	-- The spotlight's gui: no screen insets, over every other gui's buttons.
	check(has(uiSrc, "spotGui.ScreenInsets = Enum.ScreenInsets.None") and has(uiSrc, "spotGui.IgnoreGuiInset = true")
			and has(uiSrc, "local SPOT_ORDER = 61"),
		"the dim's gui has no screen insets (it covers the notch and the topbar) and stands at 61")
	local highest, at = 0, ""
	for _, script in ipairs(Client:GetChildren()) do
		for n in string.gmatch(sourceOf(script), "DisplayOrder = (%d+)") do
			if tonumber(n) > highest and script.Name ~= "TutorialUI" then
				highest, at = tonumber(n), script.Name
			end
		end
	end
	local adminSrc = sourceOf(Server:FindFirstChild("AdminService"))
	for n in string.gmatch(adminSrc, "DisplayOrder = (%d+)") do
		if tonumber(n) > highest then
			highest, at = tonumber(n), "AdminService"
		end
	end
	check(highest < 61, "and every other gui with a button stands under it", string.format("highest %d (%s)", highest, at))
	check(has(uiSrc, "gui.DisplayOrder = SPOT_ORDER + 1") and has(uiSrc, "gui.DisplayOrder = GUIDE_ORDER"),
		"while the dim shows the guide's own gui stands over it -- the words and Skip guide -- and goes back after")
	check(has(uiSrc, "SeedBeginnerGuide = true") and has(uiSrc, "TouchGui = true")
			and has(uiSrc, "b.Selectable = false") and has(uiSrc, "(d:IsA(\"GuiButton\") or d:IsA(\"TextBox\"))"),
		"only buttons are blocked -- never Skip guide, never Roblox's touch controls -- so movement is never blocked")
	check(not has(uiSrc, "hole.Active = true") and has(uiSrc, "hole.Active = false") and has(uiSrc, "hand.Active = false"),
		"the dim and the hand take no input")
	-- Selection by PadFocus's rules, and the three D-pad keys.
	check(has(uiSrc, "if button and PadInput.active() then") and has(uiSrc, "anyAButtonDown()")
			and has(uiSrc, "GuiService.SelectedObject = button") and has(uiSrc, "button:SetAttribute(ATTR.GuideLit, true)"),
		"with a controller in hand the selection goes on the lit button once A is let go, marked GuideLit")
	local keysOk = true
	for name, key in pairs({ PlotTeleportUI = "DPadUp", BiomesButtonUI = "DPadLeft", ObbyButtonUI = "DPadRight" }) do
		local src = sourceOf(Client:FindFirstChild(name))
		keysOk = keysOk and has(src, "input.KeyCode == Enum.KeyCode." .. key .. " and button.Visible and button:GetAttribute(ATTR.GuideLit) == true")
			and has(src, "and GuiService.SelectedObject == button and not PadInput.panelOpen() then")
	end
	check(keysOk, "and each button's own D-pad key presses it while lit and selected: TELEPORT Up, BIOMES Left, OBBY Right")
	check(Spot.Targets.teleport.key == "A or D-PAD UP" and Spot.Targets.biomes.key == "A or D-PAD LEFT"
			and Spot.Targets.obby.key == "A or D-PAD RIGHT",
		"whose words name the key, written out (no arrow glyphs)")
	local arrows = {}
	local wordsOk = true
	for key, target in pairs(Spot.Targets) do
		for _, text in ipairs({ target.words, target.key or "" }) do
			-- U+2190..U+21FF arrows and U+25xx geometric shapes: none.
			if string.find(text, "\226\134") or string.find(text, "\226\135") or string.find(text, "\226\150")
				or string.find(text, "\226\151") then
				table.insert(arrows, key)
			end
		end
		local n = 0
		for w in string.gmatch(target.words, "%S+") do
			if w ~= "\u{00B7}" then
				n += 1
			end
		end
		wordsOk = wordsOk and n >= 2 and n <= 4
	end
	check(#arrows == 0, "and no arrow or shape glyph anywhere in them", table.concat(arrows, ","))
	check(wordsOk, "every spotlight's words are two to four words")
	-- Notices: the count the spotlight waits on.
	local toastSrc = sourceOf(Client:FindFirstChild("ActionToastUI"))
	check(has(toastSrc, "Notice.setShowing(standing)") and type(Notice.showing) == "function"
			and has(uiSrc, "facts.notice = Notice.showing() > 0"),
		"a notice up keeps it waiting: ActionToastUI says how many stand, on every screen")
	Notice.setShowing(2)
	local two = Notice.showing()
	Notice.setShowing(0)
	check(two == 2 and Notice.showing() == 0, "and the count reads back")
	-- The NEVER facts, from where the game keeps them.
	check(has(uiSrc, "facts.safe = player:GetAttribute(ATTR.InSafeZone) == true")
			and has(uiSrc, "facts.carrying = type(player:GetAttribute(ATTR.CarryingSpecies)) == \"string\"")
			and has(uiSrc, "ATTR.PursuedBy") and has(uiSrc, "ATTR.WakingBy")
			and has(uiSrc, "PadInput.panelOpen() or RewardMoments.busy(player, ATTR.OpenPanel)"),
		"the NEVER facts are read from the Safe Zone, the carry, the chase and the panels")
	-- World targets never dim: only the five HUD keys ever name a spotlight.
	local keysUsed = {}
	for key in string.gmatch(uiSrc, "pointAt%([^\n]-, \"([a-z]+)\"[,%)]") do
		keysUsed[key] = true
	end
	local named = {}
	for key in pairs(keysUsed) do
		table.insert(named, key)
	end
	table.sort(named)
	check(table.concat(named, ",") == "biomes,obby,slot,speed,teleport",
		"only HUD targets are ever spotlit (BIOMES, OBBY, a hotbar slot, SPEED, TELEPORT); world targets get the hand",
		table.concat(named, ","))
	check(has(uiSrc, "handOver(stand + Vector3.new(0, BELT_TIP, 0))") and has(uiSrc, "handOver(spot + Vector3.new(0, SOIL_TIP, 0))")
			and has(uiSrc, "\"HOLD HATCH\""),
		"the hand in the world: over the belt, over a free spot of soil, and HOLD HATCH over the pod")
	check(has(uiSrc, "PLOT.TeleportCooldownSeconds + COOL_MARGIN") and has(uiSrc, "ObbyData.LocalAttributes.EntranceAsked"),
		"step 7 lights TELEPORT only after the shared cooldown since OBBY was pressed")
	-- Found in the guarded Play (2026-10-08) and fixed there.
	check(has(uiSrc, "words.Position = UDim2.fromOffset(0, shift)")
			and has(uiSrc, "reach = layout.skip.y + layout.skip.h + wordsShift")
			and has(uiSrc, "makeRoom(h, wordsAt)"),
		"on a desktop the guide's banner steps down under a hand pointing up at the top row (and says how far)")
	check(has(uiSrc, "local left = x + w > view.X - 4"),
		"the world hand's words stand on its left where the right would run off the screen")
	check(has(uiSrc, "if pressedAt.biomes then") and has(uiSrc, "pressedAt[key] = os.clock()"),
		"a pressed button is not pointed at again in its step (BIOMES lands in the Safe Zone)")
	-- Step 4's words fit the desktop banner's one line.
	local bank = "Run back! Teleport won't work while you carry a pod."
	local bankW = textW(bank, 19).X
	check(has(uiSrc, "subline.Text = \"" .. bank .. "\"") and bankW <= 560,
		"step 4 says \"" .. bank .. "\", and it fits the desktop banner's 560 px", string.format("%.0f px", bankW))
	-- The server path: travel on a successful TeleportHome, after the hatch.
	local plotSrc = sourceOf(Server:FindFirstChild("PlotService"))
	local dataSrc = sourceOf(Server:FindFirstChild("PlayerDataService"))
	local _, homeAt = string.find(plotSrc, "function PlotService.TeleportHome", 1, true)
	local homeEnd = homeAt and string.find(plotSrc, "\nend\n", homeAt, true)
	local home = if homeAt and homeEnd then string.sub(plotSrc, homeAt, homeEnd) else ""
	local fireAt = string.find(home, "fire(onTeleportedHome, player, plot)", 1, true)
	local pivotAt = string.find(home, "character:PivotTo(target)", 1, true)
	check(fireAt ~= nil and pivotAt ~= nil and fireAt > pivotAt and count(plotSrc, "fire(onTeleportedHome") == 1,
		"PlotService tells only a SUCCESSFUL teleport home, after the move, and nothing else")
	check(has(dataSrc, "PlotService.OnTeleportedHome(function(player: Player)")
			and has(dataSrc, "PlayerDataService.RecordTutorial(player, \"travel\")"),
		"PlayerDataService records travel from it (TutorialData refuses it before the first loop is done)")
	check(TutorialData.Needs.travel == "place",
		"travel needs the first loop done: its last step is placing the first plant since the hatch moved before it (2026-10-09)")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw: " .. tostring(err))
end
return string.format("%s\nTutorialSpotlightSpec: %d passed, %d failed", table.concat(out, "\n"), pass, fail)
