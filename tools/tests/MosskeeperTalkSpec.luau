--!nocheck
--==============================================================================
-- Steal a Seed :: MosskeeperTalkSpec
--
-- The Mosskeeper's talk, rebuilt (2026-10-11, the owner's clip of a
-- Grow-a-Garden-style shop NPC): Shared/MosskeeperTalk driven directly, and
-- MosskeeperUI read for the rules only its source can show. Edit mode:
--
--   1. the replies: the owner's four, keys 1-4, written as the clip writes them
--   2. his lines: the greeting, his answers to a Give all from the server's own
--      payload, How to play's run, the counts -- all in plain ASCII, which
--      the comic face draws (the glyph rules)
--   3. the typing: none with Reduced Motion
--   4. the camera: behind the player's right shoulder, facing him
--   5. the replies' place on every screen: inside the HUD's free middle, clear
--      of every group, rows tall enough to tap on a touch screen, the widest
--      reply inside its row -- the 640-px phone included
--   6. the wiring, by source
--
-- Not here, seen in the guarded Play: the bubbles over the heads, the shot.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage.SeedGame.Shared
local EnchantedMistConfig = require(Shared.EnchantedMistConfig)
local EnchantedMistData = require(Shared.EnchantedMistData)
local HudLayout = require(Shared.HudLayout)
local Talk = require(Shared.MosskeeperTalk)
local UIKit = require(Shared.UIKit)

local CFG = EnchantedMistConfig.Mosskeeper
local TALK = CFG.Talk
local CAP = EnchantedMistData.CarryCap
local PER_POD = EnchantedMistData.BerriesPerPod

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
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-6)
end
local function r2s(r)
	return string.format("(%g,%g %gx%g)", r.x, r.y, r.w, r.h)
end
local function overlaps(a, b)
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

-- A screen as HudLayout.measure would describe it: a 58-px topbar, its free
-- span from 208 (HudLayoutSpec's numbers).
local TOPBAR = 58
local function screen(w, h, touch)
	return {
		safe = Vector2.new(w, h - TOPBAR),
		touch = touch == true,
		keyboard = touch ~= true,
		viewport = Vector2.new(w, h),
		topbar = { x = 208, y = 0, w = w - 208, h = TOPBAR },
		insetTop = TOPBAR,
	}
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The replies")
	--==========================================================================
	local options = Talk.options()
	local want = { { "give", "Give all Dewberries" }, { "odds", "Odds" }, { "howto", "How to play" },
		{ "bye", "Nevermind" } }
	local same = #options == 4
	for i, w in ipairs(want) do
		local o = options[i]
		same = same and o ~= nil and o.id == w[1] and o.text == w[2] and o.key == i
	end
	check(same, "the owner's four, in order, keys 1-4: Give all Dewberries, Odds, How to play, Nevermind")
	check(Talk.plain(options[1]) == "#1 [\"Give all Dewberries\"]" and Talk.plain(options[4]) == "#4 [\"Nevermind\"]",
		"written as the clip writes them: #1 [\"Give all Dewberries\"]", Talk.plain(options[1]))
	local label = Talk.label(options[2])
	local chosen = Talk.label(options[2], TALK.Look.Chosen)
	check(has(label, "<font color=\"#FFD640\">#2</font>") and has(label, "<font color=\"#FFFFFF\">[\"Odds\"]</font>")
			and has(chosen, "<font color=\"#96FFC4\">[\"Odds\"]</font>"),
		"in RichText: the number gold, the words white -- mint while chosen", label)

	--==========================================================================
	say("2. His lines")
	--==========================================================================
	check(Talk.greeting(true) == CFG.Lines.Active and Talk.greeting(false) == CFG.Lines.Inactive,
		"the greeting: the Mist running or waiting")
	local cases = {
		{ { phase = "given", delivered = 5, pods = 0, progress = 5 }, "5/10, five more for a pod!", true },
		{ { phase = "given", delivered = 1, pods = 0, progress = 9 }, "9/10, one more for a pod!", true },
		{ { phase = "given", delivered = 1, pods = 0, progress = 1 }, "1/10, nine more for a pod!", true },
		{ { phase = "given", delivered = 5, pods = 1, progress = 3 }, "Here's your Mysterious Pod!", true },
		{ { phase = "refused", reason = "BAG_FULL" }, "Make room in your Bag.", false },
		{ { phase = "refused", reason = "INACTIVE" }, "I'm waiting for Enchanted Mist...", false },
		{ { phase = "refused", reason = "EMPTY" }, "You have no Dewberries to give.", false },
		{ { phase = "refused", reason = "SOMETHING_NEW" }, "One moment...", false },
	}
	local answered, notes = true, {}
	for _, case in ipairs(cases) do
		local text, taken = Talk.answer(case[1])
		if text ~= case[2] or taken ~= case[3] then
			answered = false
			table.insert(notes, text .. " / " .. tostring(taken))
		end
	end
	check(answered, "his answers, from the server's own payload: \"5/10, five more for a pod!\", \"Here's your "
		.. "Mysterious Pod!\", \"Make room in your Bag.\", \"I'm waiting for Enchanted Mist...\"; anything unknown "
		.. "\"One moment...\"", table.concat(notes, "; "))
	local refused = 0
	for reason in pairs(TALK.Refused) do
		refused += 1
		local text, taken = Talk.answer({ phase = "refused", reason = reason })
		if text ~= TALK.Refused[reason] or taken then
			refused = -100
		end
	end
	check(refused >= 9, "every refusal the server can give has his own words", refused)
	local lines = Talk.howTo()
	check(#lines == 4 and has(lines[2], "carry " .. CAP .. " at a time") and has(lines[3], "Every " .. PER_POD .. " makes")
			and not has(table.concat(lines, " "), "{"),
		"How to play: his short run of four, the carry cap and the berries a pod filled in", lines[2])
	check(Talk.counts(3, 4) == "Carrying 3/5    Next pod 4/10" and Talk.counts(99, 99) == "Carrying 5/5    Next pod 9/10"
			and Talk.counts(-2, -2) == "Carrying 0/5    Next pod 0/10",
		"the counts under the replies, kept to their caps", Talk.counts(99, 99))
	-- THE GLYPH RULES: every word the talk can show is plain ASCII -- letters,
	-- digits and . , ! ' " # [ ] / : -- which the comic face draws (Comic Neue
	-- Angular since 2026-10-13, LuckiestGuy before). No em dash, no ellipsis
	-- character, no dingbat.
	local shown = { Talk.greeting(true), Talk.greeting(false), TALK.Given, TALK.GivenPod, TALK.Counts }
	for _, o in ipairs(options) do
		table.insert(shown, Talk.plain(o))
	end
	for _, text in pairs(TALK.Refused) do
		table.insert(shown, text)
	end
	for _, text in ipairs(lines) do
		table.insert(shown, text)
	end
	for _, word in ipairs(TALK.Numbers) do
		table.insert(shown, word)
	end
	local odd = {}
	for _, text in ipairs(shown) do
		if string.find(text, "[^\32-\126]") then
			table.insert(odd, text)
		end
	end
	check(#odd == 0, "every word it shows is plain ASCII, which the comic face draws (the glyph rules)",
		table.concat(odd, " | "))

	--==========================================================================
	say("3. The typing")
	--==========================================================================
	local line = "Make room in your Bag."
	local n0, d0 = Talk.typed(line, 0, false)
	local n1, d1 = Talk.typed(line, 5 / TALK.CharsPerSecond + 1e-6, false)
	local n2, d2 = Talk.typed(line, 10, false)
	local nr, dr = Talk.typed(line, 0, true)
	check(n0 == 0 and not d0 and n1 == 5 and not d1 and n2 == #line and d2 and nr == #line and dr,
		string.format("typed at %d a second, all of it once done; Reduced Motion: all of it at once", TALK.CharsPerSecond),
		string.format("%d %d %d %d", n0, n1, n2, nr))
	check(near(Talk.typeTime(line, false), #line / TALK.CharsPerSecond) and Talk.typeTime(line, true) == 0
			and near(Talk.readTime(line), TALK.ReadHold + #line * TALK.ReadPerChar),
		"its typing time (none with Reduced Motion) and its reading time")

	--==========================================================================
	say("4. The camera")
	--==========================================================================
	local C = TALK.Camera
	local root, him = Vector3.new(10, 3, 20), Vector3.new(10, 1, 5)
	local cf = Talk.shoulder(root, him)
	local forward = Vector3.new(0, 0, -1)
	local right = Vector3.new(1, 0, 0)
	local eye = cf.Position
	local looksAt = ((him + Vector3.new(0, C.LookUp, 0)) - eye).Unit
	check(near((eye - root):Dot(forward), -C.Back, 1e-4) and near(eye.Y - root.Y, C.Up, 1e-4)
			and near((eye - root):Dot(right), C.Side, 1e-4) and cf.LookVector:Dot(looksAt) > 0.9999,
		"behind the player's right shoulder (Back, Up, Side), looking at him plus LookUp", tostring(eye))
	local turned = Talk.shoulder(Vector3.new(0, 3, 0), Vector3.new(12, 0, 0))
	check(near((turned.Position - Vector3.new(0, 3, 0)):Dot(Vector3.new(1, 0, 0)), -C.Back, 1e-4)
			and near(turned.Position.Z, C.Side, 1e-4),
		"on the line from the player to him, whichever way that runs", tostring(turned.Position))
	local over = Talk.shoulder(Vector3.new(0, 3, 0), Vector3.new(0, 9, 0))
	check(over.Position == over.Position and over.LookVector == over.LookVector,
		"never NaN, even standing right under him")
	local beside = Talk.besidePoint(root, him)
	check(near((beside - him):Dot(right), TALK.Beside, 1e-4) and near(beside.Y - him.Y, TALK.BesideUp, 1e-4)
			and near((beside - him):Dot(forward), 0, 1e-4),
		"the replies start Beside studs right of him (the camera's side), BesideUp over his pivot", tostring(beside))
	-- What of him the replies keep clear of (the owner, 2026-10-12: "not over him").
	local BAR = CFG.Bar
	local pts = Talk.himPoints(CFrame.new(0, 4, 0), Vector3.new(2, 8, 2), Vector3.new(0, 1, 0), Vector3.xAxis, Vector3.yAxis)
	local span = Talk.spanOf({ Vector2.new(3, 9), Vector2.new(-1, 4), Vector2.new(2, -2) })
	check(#pts == 12 and near(pts[1].Y, 0, 1e-4) and near(pts[8].Y, 8, 1e-4)
			and near(pts[12].X, BAR.Width / 2, 1e-4) and near(pts[12].Y, 1 + BAR.Above + BAR.Height / 2, 1e-4)
			and near(pts[9].X, -BAR.Width / 2, 1e-4) and near(pts[9].Y, 1 + BAR.Above - BAR.Height / 2, 1e-4)
			and span ~= nil and span.x == -1 and span.y == -2 and span.w == 4 and span.h == 11 and Talk.spanOf({}) == nil,
		"him on screen: his body's eight corners and his bar's four (BAR.Width x BAR.Height facing the camera, "
			.. "BAR.Above over his base), and the least rect round them")
	-- The player and him apart on screen: him on the camera's axis, the player a
	-- body's width or more to the left of it (the first Play: they overlapped).
	local axis = cf.LookVector
	local function across(p)
		local d = p - eye
		return d:Dot(cf.RightVector) / d:Dot(axis)
	end
	local playerAt, himAt = across(root), across(him + Vector3.new(0, C.LookUp, 0))
	check(near(himAt, 0, 1e-4) and playerAt < -0.15,
		"in the shot he stands in the middle and the player clearly left of him",
		string.format("player %.3f, him %.3f", playerAt, himAt))
	check(Talk.ease(0) == 0 and Talk.ease(1) == 1 and near(Talk.ease(0.5), 0.5) and Talk.ease(-1) == 0 and Talk.ease(2) == 1,
		"eased on a smoothstep, held at both ends")

	--==========================================================================
	say("5. The replies' place")
	--==========================================================================
	local screens = {
		{ "1280x720 desktop", screen(1280, 720) },
		{ "1005x716 desktop (the owner's Studio)", screen(1005, 716) },
		{ "1920x1080 desktop", screen(1920, 1080) },
		{ "1000x609 desktop", screen(1000, 609) },
		{ "860x700 window", screen(860, 700) },
		{ "640x360 phone", screen(640, 360, true) },
		{ "705x338 phone (Studio's emulator)", screen(705, 338, true) },
		{ "640x480 touch", screen(640, 480, true) },
		{ "801x392 phone (the owner's)", screen(801, 392, true) },
		{ "844x390 phone", screen(844, 390, true) },
		{ "896x414 phone", screen(896, 414, true) },
	}
	local placeOk, placeNotes = true, {}
	local tapOk, keptHis, putAway, keptHim, overHim = true, 0, 0, 0, {}
	for _, case in ipairs(screens) do
		local tag, input = case[1], case[2]
		local L = HudLayout.solve(input)
		-- What the client blocks (MosskeeperUI.measureHud, TreadmillFunUI's
		-- recipe): HudLayout.occupiedButToast, the clock and ADMIN (less the
		-- inset: they stand in an inset-ignoring gui); and, soft, what comes and
		-- goes: the notices' line, the biome name, the chase warning, the boosts.
		-- Not a phone's REBIRTH: its dock is hidden while the talk is open.
		if L.sidebar then
			L.rebirth = HudLayout.rect(0, 0, 0, 0)
		end
		local blocked, soft = {}, {}
		local function add(list, r, lift)
			if r and r.w > 0 and r.h > 0 then
				table.insert(list, { x = r.x, y = r.y - (lift or 0), w = r.w, h = r.h })
			end
		end
		for _, r in ipairs(HudLayout.occupiedButToast(L)) do
			add(blocked, r)
		end
		local status, notice, boosts = HudLayout.statusRows(L, TOPBAR)
		add(blocked, L.clock, TOPBAR)
		add(blocked, L.admin, TOPBAR)
		add(soft, L.toast)
		add(soft, notice)
		add(soft, status)
		add(soft, boosts)
		local bounds = { x = 0, y = 0, w = input.safe.X, h = input.safe.Y }
		-- In the comic face, its ink by size, as MosskeeperUI measures (2026-10-13).
		local function widths(look)
			local widest = 0
			for _, o in ipairs(options) do
				local size = UIKit.comicBounds(Talk.plain(o), look.Type)
				widest = math.max(widest, size.X + UIKit.comicInk(look.Type) * 2 + 16)
			end
			return widest, UIKit.comicBounds(Talk.counts(5, 9), look.Counts).X + UIKit.comicInk(look.Counts) * 2 + 16
		end
		-- His line over his bar: the top middle of the shot.
		local his = { x = input.safe.X / 2 - 150, y = input.safe.Y * 0.1, w = 300, h = 56 }
		-- HIM in the shot, his bar and his body (as the 705 x 338 Play measured
		-- him, 2026-10-12): down the middle, from a quarter of the way down to
		-- three quarters, a third of the height wide. Never under the replies.
		local him = { x = input.safe.X / 2 - input.safe.Y * 0.175, y = input.safe.Y * 0.27, w = input.safe.Y * 0.35,
			h = input.safe.Y * 0.46 }
		-- Where a player's right side lands in the shot: a little right of the
		-- middle (on him); and the corners, to make it slide.
		for _, anchor in ipairs({ Vector2.new(input.safe.X * 0.52, input.safe.Y * 0.55),
			Vector2.new(input.safe.X, input.safe.Y), Vector2.new(0, 0) }) do
			local block = Talk.place(anchor, bounds, input.touch, widths, blocked, soft, his, #options, him)
			local bad = {}
			local M = TALK.Margin
			local widest = widths(block.look)
			local all = { block.counts }
			if not block.clear then
				table.insert(bad, "no clear spot")
			end
			for n, r in ipairs(block.rows) do
				table.insert(all, r)
				if r.w < widest - 1e-6 then
					table.insert(bad, "row " .. n .. " narrower than its words")
				end
				if input.touch and r.h < 19 then
					tapOk = false
					table.insert(bad, "row " .. n .. " under 19 px on a touch screen")
				end
				if n > 1 and r.y < block.rows[n - 1].y + block.rows[n - 1].h - 1e-6 then
					table.insert(bad, "rows overlap")
				end
			end
			local against = table.clone(blocked)
			if block.keepsHis then
				table.insert(against, his)
				keptHis += 1
			else
				putAway += 1
			end
			if block.keepsHim then
				table.insert(against, him)
				keptHim += 1
			elseif input.touch then
				table.insert(bad, "over him on a touch screen")
			else
				table.insert(overHim, tag)
			end
			if block.keepsSoft then
				for _, r in ipairs(soft) do
					table.insert(against, r)
				end
			elseif not input.touch then
				table.insert(bad, "over a passing row on a desktop")
			end
			for _, r in ipairs(all) do
				if r.x < M - 1e-6 or r.x + r.w > bounds.w - M + 1e-6 or r.y < M - 1e-6 or r.y + r.h > bounds.h - M + 1e-6 then
					table.insert(bad, "off the screen's margin " .. r2s(r))
				end
				for _, b in ipairs(against) do
					local grown = { x = b.x - (M - 1e-3), y = b.y - (M - 1e-3), w = b.w + 2 * (M - 1e-3),
						h = b.h + 2 * (M - 1e-3) }
					if overlaps(r, grown) then
						table.insert(bad, "within 8 px of " .. r2s(b))
						break
					end
				end
			end
			if #bad > 0 then
				placeOk = false
				table.insert(placeNotes, tag .. " at " .. tostring(anchor) .. ": " .. table.concat(bad, ", "))
			end
		end
	end
	check(placeOk, "on every screen, from any anchor: four rows and the counts at the nearest spot 8 px clear of the "
		.. "screen's edge, every part of the HUD, HIM on every touch screen (his body and bar; the owner, 2026-10-12) "
		.. "and his line (or his line put away while they show), the passing rows too but on a phone short of room, "
		.. "each row as wide as the widest reply, none over another -- the 640-px phone and the emulator's 705 x 338 too",
		table.concat(placeNotes, "; "))
	say(string.format("        his line kept on %d placements, put away on %d; clear of him on %d, over him on %d "
		.. "(a desktop window with no room clear of him: %s)", keptHis, putAway, keptHim, #overHim,
		table.concat(overHim, ", ")))
	-- THE OWNER'S REFERENCE (2026-10-12, a Grow a Garden phone): the replies' words about 4% of the screen's
	-- height, a row every 5.8%, his line about 3%; each row its whole tap target, never overlapping the next
	-- (the owner's call: exactly the reference, taps that small accepted; keys 1-4 and the D-pad still choose).
	local touchLook, tightLook = Talk.look(true), Talk.looks(true)[2]
	check(tapOk and touchLook.Row == 20 and tightLook.Row == 19 and touchLook.Type == 14 and tightLook.Type == 13
			and touchLook.Gap == 0 and tightLook.Gap == 0 and touchLook.Bubble == 11 and touchLook.Counts == 11
			and touchLook.Type / 360 >= 0.035 and touchLook.Type / 338 <= 0.045
			and touchLook.Row / 360 >= 0.05 and touchLook.Row / 338 <= 0.065,
		"a touch screen's replies exactly to the owner's reference: words about 4% of a phone's height (14 px), a "
			.. "row every 5.8% (20 px; 19 tight), his line about 3% (11 px), each row its whole tap target, none overlapping",
		string.format("type %d row %d bubble %d", touchLook.Type, touchLook.Row, touchLook.Bubble))
	check(has(StarterPlayer.StarterPlayerScripts.MosskeeperUI.Source,
			"reply.hit.Position = UDim2.fromOffset(r.x * k, r.y * k)\n\t\treply.hit.Size = UDim2.fromOffset(r.w * k, r.h * k)"),
		"each reply's tap target is exactly its row: no padding into the next")
	local cramped = Talk.place(Vector2.new(50, 50), { x = 0, y = 0, w = 200, h = 120 }, false, function()
		return 300, 200
	end, {}, {}, nil, 4)
	check(not cramped.clear and cramped.rows[1].x == TALK.Margin and cramped.look == TALK.Look.DesktopTight,
		"a screen with no room at all: the tight look at the margin, no error, said not clear", r2s(cramped.rows[1]))

	--==========================================================================
	say("6. The wiring")
	--==========================================================================
	local ui = StarterPlayer.StarterPlayerScripts.MosskeeperUI.Source
	-- REBIRTH (2026-10-12, item 18): a phone's stands in the dock RailDrawerUI
	-- hides while this talk's panel is open, so the replies may take its room.
	local drawer = StarterPlayer.StarterPlayerScripts.RailDrawerUI.Source
	local rebirthUI = StarterPlayer.StarterPlayerScripts.RebirthUI.Source
	check(has(ui, "if L.sidebar then\n\t\tL.rebirth = HudLayout.rect(0, 0, 0, 0)\n\tend")
			and has(ui, "player:SetAttribute(ATTR.OpenPanel, PANEL)")
			and has(drawer, "dock.Visible = player:GetAttribute(ATTR.OpenPanel) == nil")
			and has(rebirthUI, "hudButton.Parent = if layout.sidebar then UIKit.railDock(playerGui) else"),
		"a phone's REBIRTH is no room taken while the replies show: it stands in the dock, hidden while the talk "
			.. "is open")
	check(has(ui, "talkGui.IgnoreGuiInset = true") and has(ui, "talkGui.ScreenInsets = Enum.ScreenInsets.None")
			and has(ui, "camera:WorldToViewportPoint(MosskeeperTalk.besidePoint(")
			and has(ui, "measureGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets"),
		"the replies in a gui where a projected point is its own pixel, the HUD measured as the HUD's own guis are")
	check(has(ui, "if view.X >= talkGui.AbsoluteSize.X - 1 and view.Y >= talkGui.AbsoluteSize.Y - 1 then")
			and has(ui, "return Vector2.new(at.X, at.Y + measureGui.AbsoluteSize.Y - view.Y)")
			and has(ui, "return { x = point.X + origin.X - w / 2, y = point.Y + origin.Y - h, w = w, h = h }")
			and has(ui, "local him = himRect(camera, model, origin)")
			and has(ui, "MosskeeperTalk.place((Vector2.new(point.X, point.Y) + origin) / k,")
			and has(ui, "blocked, soft, if his then units(his) else nil, #OPTIONS, if him then units(him) else nil)"),
		"a projected point mapped onto the talk's screen where the viewport is only the safe area (the emulator's "
			.. "47 px, 2026-10-12), and the replies placed clear of him: his body and his bar")
	check(has(ui, "for _, r in ipairs(drawnBlocked(h)) do")
			and has(ui, "playerGui:GetGuiObjectsAtPosition(at.X + r.x + r.w * f.X, at.Y + r.y + r.h * f.Y)")
			and has(ui, "if drawnFor ~= h or os.clock() - drawnAt >= 0.5 then")
			and has(ui, "if o:IsDescendantOf(gui) or o:IsDescendantOf(talkGui) or o:IsDescendantOf(measureGui)"),
		"the replies keep clear of the HUD that draws now, read every half second -- the talk's open panel puts a "
			.. "phone's left column, panel row and Index away, and the replies may stand there (the 705 x 338 Play)")
	check(has(ui, "hit.Selectable = false") and has(ui, "reply.hit.Activated:Connect(function()\n\t\tpick(i)")
			and has(ui, "Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,")
			and has(ui, "Enum.KeyCode.ButtonA)") and has(ui, "UserInputService.InputBegan:Connect(function(input: InputObject)")
			and has(ui, "elseif input.KeyCode == Enum.KeyCode.DPadUp then -1"),
		"a click or a tap on a row, keys 1-4 (bound over the strip's), A, and the D-pad read through UserInputService")
	check(has(ui, "return Enum.ContextActionResult.Sink\n\t\tend, false, 3000, Enum.KeyCode.One"),
		"while he talks keys 1-4 and A are his: never a strip slot, never a jump")
	check(has(ui, "hisLabel.MaxVisibleGraphemes = if reduced() then -1 else 0")
			and has(ui, "hisLabel.MaxVisibleGraphemes = if done then -1 else n")
			and has(ui, "if now or not (f and camera and held) or f.reduced"),
		"Reduced Motion: no typing, no camera tween")
	check(has(ui, "humanoid.Died:Connect(function()\n\t\t\t\tsetOpen(false, true)")
			and has(ui, "player.CharacterRemoving:Connect(function()\n\t\t\tsetOpen(false, true)")
			and has(ui, "> CFG.CloseDistance then\n\t\t\t\tsetOpen(false, true)")
			and has(ui, "if option.id == \"bye\" then\n\t\tsetOpen(false)"),
		"death, respawn and walking off give the camera back at once; Nevermind eases it back")
	check(has(ui, "channel:FireServer(CFG.ClientAction)") and not has(ui, "FireServer(CFG.ClientAction,"),
		"a Give all sends no amount: the server decides everything")
	check(has(ui, "title = string.upper(W.Odds)") and not has(ui, "W.GiveAll") and not has(ui, "MainPage"),
		"no studded dialogue panel: the only panel is the odds cards")
	check(has(ui, "hisBoard.StudsOffsetWorldSpace = Vector3.new(0, BAR.Above + BAR.Height / 2 + TALK.OverBar, 0)")
			and has(ui, "board.AlwaysOnTop = true") and has(ui, "youBoard.Adornee = head"),
		"his line over his bar, the player's over their own head, always on top: nothing in the world hides them")
	check(has(ui, "params.RespectCanCollide = true") and has(ui, "local goal = unblocked(MosskeeperTalk.shoulder("),
		"nothing solid between the player and the shot: pulled in to it")
	check(has(ui, "\t-- The player's line takes his place (the clip): his comes back with his answer.\n\tsetHis(nil)\n\tsetYou(option.text)"),
		"the player's line takes his place, as in the clip")
	-- COMIC TYPE (2026-10-13, the owner: the NPC's dialogue in Comic Neue Angular).
	check(has(ui, "UIKit.comic(words)") and has(ui, "\tUIKit.comic(label)\n\tlabel.Size = UDim2.fromScale(1, 1)")
			and has(ui, "label.TextSize = look.Bubble * k\n\t\tUIKit.comic(label)")
			and has(ui, "reply.words.TextSize = look.Type * k\n\t\tUIKit.comic(reply.words)")
			and has(ui, "countsLabel.TextSize = look.Counts * k\n\tUIKit.comic(countsLabel)")
			and has(ui, "local size = UIKit.comicBounds(line.text, look.Bubble * k, look.BubbleWidth * k)")
			and has(ui, "local size = UIKit.comicBounds(MosskeeperTalk.plain(option), look.Type)")
			and has(ui, "task.spawn(UIKit.comicBounds, \"A\", TALK.Look.Desktop.Type)")
			and not has(ui, "LuckiestGuy") and not has(ui, "GetTextSize"),
		"every word of the talk -- his line, the player's, the replies, the counts -- in the comic face, its ink by "
			.. "its size, measured in that face, which loads from the start")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMosskeeperTalkSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
