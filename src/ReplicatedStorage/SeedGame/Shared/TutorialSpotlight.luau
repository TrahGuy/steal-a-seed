--!strict
--==============================================================================
-- Steal a Seed :: TutorialSpotlight (the owner's spotlight brief, 2026-10-08)
--
-- THE GUIDE'S POINTING HAND AND ITS SPOTLIGHT, AS ARITHMETIC. Numbers only: no
-- instances, no services, no clock of its own. TutorialUI draws from it, and
-- TutorialSpotlightSpec holds it to every screen HudLayout lays out -- desktops,
-- phones with their notch and topbar, TVs.
--
--   the hand     the owner's glove (Hand.Image, the ONE asset this uses), drawn
--                pointing UP. Turned to point down, left or right so that its
--                fingertip meets the lit window's edge and the hand never
--                covers the target; it taps toward the target about once a
--                second
--   the window   one real, rendered button's rect grown by Pad -- less on a side
--                where another button stands nearer, so a neighbour is never
--                half lit -- in a full-screen dim of Dim black
--   the words    two to four, beside the hand, never over the window
--   the rules    when one may show (blocked: the NEVER list) and each one's
--                single life per step (advance)
--
-- ONE SPACE FOR EVERY RECT: the spotlight gui's own pixels. That gui has no
-- screen insets -- the whole screen, the notch and the topbar included -- and no
-- UIScale, so a target's rect is its AbsolutePosition less the gui's own.
--==============================================================================

-- Only for the training goal's number, written the way the step title writes it.
local TutorialData = require(script.Parent:WaitForChild("TutorialData"))

local Spotlight = {}

export type Rect = { x: number, y: number, w: number, h: number }

--==============================================================================
-- THE HAND
--
-- The owner's upload 77822355284810 (2026-10-08; AssetTypeId 1, an Image of
-- the CrazyCozy Games group): a white cartoon glove pointing UP, green cuff.
-- IsLoaded in Studio Edit the same day; stored 1024 x 1024, its opaque pixels
-- x 212..814 and y 13..1012, the fingertip's top row x 592..615 at y 13 -- so
-- the tip is Tip of the way across and down the drawn square.
--==============================================================================
Spotlight.Hand = {
	Image = "rbxassetid://77822355284810",
	Tip = Vector2.new(0.589, 0.013),
	-- The drawn square's side at the guide's scale 1 (a desktop); a phone draws
	-- it at HudLayout's tutorialScale and a TV at its ten-foot scale on top.
	Size = 64,
	-- The tap: this far toward the target at its height, once every Period
	-- seconds -- "a short bob toward the target, about once a second".
	Bob = 6,
	Period = 1,
	-- How far outside the window's edge the fingertip stops at the top of a tap
	-- (at Size; it grows with the hand, as the tap does).
	Gap = 2,
}

-- How dark the screen goes around the window: 65% black.
Spotlight.Dim = 0.65
-- How far the window stands out from its button, and the least it ever does.
Spotlight.Pad = 8
Spotlight.MinPad = 2
Spotlight.Corner = 12
-- The gold ring on the window's edge, pulsing.
Spotlight.Ring = { Thickness = 3, Period = 1.1 }
-- Unpressed this long, the dim fades (the hand stays until the step moves on).
Spotlight.FadeAfter = 15
Spotlight.FadeSeconds = 0.35
-- Nothing in the way for this long before one shows. The moments after a hatch
-- bring a celebration, a reveal and a notice or two in quick succession, and a
-- spotlight shown and dropped a breath later is spent for nothing: measured in
-- Play on 2026-10-08, OBBY and TELEPORT both burned inside one second.
Spotlight.Settle = 1.5
-- Nothing of the hand or the words nearer the screen's edge than this.
Spotlight.Margin = 6
-- The words beside the hand, at the guide's scale 1.
Spotlight.Words = { Size = 24, KeySize = 15, Gap = 6, Lines = 2 }

--==============================================================================
-- WHAT EACH SPOTLIGHT SAYS
--
-- `words` beside the hand, always; `key` under them while a controller is in
-- hand: the button's own D-pad key -- written out, never an arrow glyph (the
-- HUD fonts draw most arrows as boxes). A press with A works on every lit
-- BUTTON, because the selection is put on it.
--==============================================================================
export type Target = { words: string, key: string? }

Spotlight.Targets = {
	speed = { words = "YOUR SPEED \u{00B7} GET " .. TutorialData.SpeedTargetText },
	biomes = { words = "TAP BIOMES", key = "A or D-PAD LEFT" },
	obby = { words = "TAP OBBY", key = "A or D-PAD RIGHT" },
	teleport = { words = "TAP TO GO HOME", key = "A or D-PAD UP" },
	slot = { words = "EQUIP YOUR POD", key = "PRESS A" },
} :: { [string]: Target }

--==============================================================================
-- THE WINDOW
--
-- `target` grown by Pad on every side -- except a side where another button
-- stands within Pad of it, which stops halfway to that neighbour (never under
-- MinPad), so the window lights one button and none of the next one's plate.
-- `others` are the other buttons' rects; ones that share no row or column with
-- the target are ignored.
--==============================================================================
function Spotlight.window(target: Rect, others: { Rect }?, pad: number?): Rect
	local p = pad or Spotlight.Pad
	local left, right, top, bottom = p, p, p, p
	local least = Spotlight.MinPad
	for _, o in ipairs(others or {}) do
		local rows = o.y < target.y + target.h and o.y + o.h > target.y
		local cols = o.x < target.x + target.w and o.x + o.w > target.x
		if rows then
			local gapR = o.x - (target.x + target.w)
			if gapR >= 0 then
				right = math.min(right, math.max(least, gapR / 2))
			end
			local gapL = target.x - (o.x + o.w)
			if gapL >= 0 then
				left = math.min(left, math.max(least, gapL / 2))
			end
		end
		if cols then
			local gapB = o.y - (target.y + target.h)
			if gapB >= 0 then
				bottom = math.min(bottom, math.max(least, gapB / 2))
			end
			local gapT = target.y - (o.y + o.h)
			if gapT >= 0 then
				top = math.min(top, math.max(least, gapT / 2))
			end
		end
	end
	return { x = target.x - left, y = target.y - top, w = target.w + left + right, h = target.h + top + bottom }
end

--==============================================================================
-- WHERE THE HAND GOES
--
-- `dir` is which way the finger points; the image is drawn pointing up and is
-- turned `rotation` degrees clockwise. `push` is one pixel toward the target:
-- a tap moves the whole hand Bob of them. `rect` is the drawn square at rest,
-- `tip` the fingertip at rest; `tapped` is the square at the top of a tap,
-- where the fingertip stops Gap outside the window's edge.
--==============================================================================
export type Hand = {
	dir: string,
	rotation: number,
	push: Vector2,
	rect: Rect,
	tapped: Rect,
	tip: Vector2,
	size: number,
}

local DIRS: { [string]: { rotation: number, push: Vector2 } } = {
	up = { rotation = 0, push = Vector2.new(0, -1) },
	right = { rotation = 90, push = Vector2.new(1, 0) },
	down = { rotation = 180, push = Vector2.new(0, 1) },
	left = { rotation = -90, push = Vector2.new(-1, 0) },
}
Spotlight.Dirs = DIRS

-- The fingertip's offset from the drawn square's centre, the square `size` on a
-- side and turned `rotation` degrees clockwise (screen y grows downward).
function Spotlight.tipOffset(rotation: number, size: number): Vector2
	local tip = Spotlight.Hand.Tip
	local dx, dy = (tip.X - 0.5) * size, (tip.Y - 0.5) * size
	local a = math.rad(rotation)
	local c, s = math.cos(a), math.sin(a)
	return Vector2.new(dx * c - dy * s, dx * s + dy * c)
end

local function shifted(r: Rect, by: Vector2): Rect
	return { x = r.x + by.X, y = r.y + by.Y, w = r.w, h = r.h }
end

function Spotlight.overlaps(a: Rect, b: Rect): boolean
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

function Spotlight.inside(r: Rect, screen: Rect, margin: number?): boolean
	local m = margin or 0
	return r.x >= screen.x + m - 0.01 and r.y >= screen.y + m - 0.01
		and r.x + r.w <= screen.x + screen.w - m + 0.01 and r.y + r.h <= screen.y + screen.h - m + 0.01
end

-- The hand for `dir`, slid along the window's edge as far as the screen needs
-- (its fingertip never leaving the window's span), or nil if it cannot stand
-- there on screen.
local function handAt(dir: string, window: Rect, screen: Rect, size: number): Hand?
	local H = Spotlight.Hand
	local d = DIRS[dir]
	-- The tap and the gap grow with the hand: the drawn square stands a little
	-- past the fingertip (Tip.Y of its side), and a fixed gap would let a big
	-- hand's square -- a TV's -- reach into the window.
	local scale = size / H.Size
	local bob, gap = H.Bob * scale, H.Gap * scale
	local cx, cy = window.x + window.w / 2, window.y + window.h / 2
	local touch: Vector2
	if dir == "up" then
		touch = Vector2.new(cx, window.y + window.h + gap)
	elseif dir == "down" then
		touch = Vector2.new(cx, window.y - gap)
	elseif dir == "left" then
		touch = Vector2.new(window.x + window.w + gap, cy)
	else
		touch = Vector2.new(window.x - gap, cy)
	end
	local offset = Spotlight.tipOffset(d.rotation, size)
	local centre = touch - d.push * bob - offset
	local rect: Rect = { x = centre.X - size / 2, y = centre.Y - size / 2, w = size, h = size }
	local m = Spotlight.Margin
	-- Slide along the edge back onto the screen.
	local slide = Vector2.zero
	if dir == "up" or dir == "down" then
		local lo, hi = screen.x + m, screen.x + screen.w - m
		if rect.x < lo then
			slide = Vector2.new(lo - rect.x, 0)
		elseif rect.x + rect.w > hi then
			slide = Vector2.new(hi - rect.x - rect.w, 0)
		end
		local tipX = touch.X + slide.X
		if tipX < window.x + 2 or tipX > window.x + window.w - 2 then
			return nil
		end
	else
		local lo, hi = screen.y + m, screen.y + screen.h - m
		if rect.y < lo then
			slide = Vector2.new(0, lo - rect.y)
		elseif rect.y + rect.h > hi then
			slide = Vector2.new(0, hi - rect.y - rect.h)
		end
		local tipY = touch.Y + slide.Y
		if tipY < window.y + 2 or tipY > window.y + window.h - 2 then
			return nil
		end
	end
	rect = shifted(rect, slide)
	local tapped = shifted(rect, d.push * bob)
	if not (Spotlight.inside(rect, screen, m) and Spotlight.inside(tapped, screen, m)) then
		return nil
	end
	if Spotlight.overlaps(rect, window) or Spotlight.overlaps(tapped, window) then
		return nil
	end
	return {
		dir = dir,
		rotation = d.rotation,
		push = d.push,
		rect = rect,
		tapped = tapped,
		tip = touch - d.push * bob + slide,
		size = size,
	}
end

--==============================================================================
-- THE HAND FOR A WINDOW
--
-- A target in the top half of the screen is pointed at from BELOW, pointing up
-- as drawn; one in the bottom half from above. Then from the side with the more
-- room, then the other. Nil only where no side has room -- the spec proves that
-- never happens for a real target on a listed screen.
--==============================================================================
function Spotlight.handFor(window: Rect, screen: Rect, size: number): Hand?
	local cx, cy = window.x + window.w / 2, window.y + window.h / 2
	local midX, midY = screen.x + screen.w / 2, screen.y + screen.h / 2
	local first, last = "up", "down"
	if cy > midY then
		first, last = "down", "up"
	end
	local near, far = "left", "right"
	if cx > midX then
		near, far = "right", "left"
	end
	for _, dir in ipairs({ first, near, far, last }) do
		local hand = handAt(dir, window, screen, size)
		if hand then
			return hand
		end
	end
	return nil
end

--==============================================================================
-- WHERE THE WORDS GO: beside the hand, never over the window or the hand
--
-- A hand pointing up or down has its words to one side, the side with the more
-- room first; a hand pointing sideways has them under it, else over it. `w` and
-- `h` are the words' own box. Clamped onto the screen as a last resort.
--==============================================================================
function Spotlight.wordsFor(hand: Hand, window: Rect, screen: Rect, w: number, h: number): Rect
	local gap = Spotlight.Words.Gap * (hand.size / Spotlight.Hand.Size)
	local m = Spotlight.Margin
	local r = hand.rect
	local both = {
		x = math.min(hand.rect.x, hand.tapped.x),
		y = math.min(hand.rect.y, hand.tapped.y),
		w = hand.rect.w + math.abs(hand.tapped.x - hand.rect.x),
		h = hand.rect.h + math.abs(hand.tapped.y - hand.rect.y),
	}
	local midY = r.y + r.h / 2 - h / 2
	local midX = r.x + r.w / 2 - w / 2
	local right: Rect = { x = both.x + both.w + gap, y = midY, w = w, h = h }
	local left: Rect = { x = both.x - gap - w, y = midY, w = w, h = h }
	local below: Rect = { x = midX, y = both.y + both.h + gap, w = w, h = h }
	local above: Rect = { x = midX, y = both.y - gap - h, w = w, h = h }
	local roomRight = screen.x + screen.w - (both.x + both.w)
	local roomLeft = both.x - screen.x
	local sides = if roomRight >= roomLeft then { right, left } else { left, right }
	local order: { Rect }
	if hand.dir == "up" or hand.dir == "down" then
		order = { sides[1], sides[2], if hand.dir == "up" then below else above }
	else
		order = { below, above, sides[1], sides[2] }
	end
	for _, spot in ipairs(order) do
		if Spotlight.inside(spot, screen, m) and not Spotlight.overlaps(spot, window)
			and not Spotlight.overlaps(spot, both) then
			return spot
		end
	end
	-- The last resort: the first choice, pulled onto the screen.
	local spot = order[1]
	local x = math.clamp(spot.x, screen.x + m, math.max(screen.x + m, screen.x + screen.w - m - w))
	local y = math.clamp(spot.y, screen.y + m, math.max(screen.y + m, screen.y + screen.h - m - h))
	return { x = x, y = y, w = w, h = h }
end

--==============================================================================
-- NEVER SHOWN, AND DROPPED AT ONCE IF IT BECOMES TRUE (the owner's list, in
-- order, plus the guide's own state): the first reason that holds, or nil when
-- the spotlight may show.
--
--   guide     the guide's words are not up: hidden, skipped, asking to skip,
--             or covered by the biome banner
--   dead      dead or respawning
--   zone      outside the Safe Zone
--   carrying  a pod in the arms
--   chase     a guardian waking for this player or chasing them
--   panel     a panel open (OpenPanel, any modal, a reward moment)
--   notice    a notice standing -- it waits until the notice has gone
--   moment    the guide's own celebration playing
--   target    the target hidden, or with no rect on this screen
--==============================================================================
export type Facts = {
	guide: boolean,
	alive: boolean,
	safe: boolean,
	carrying: boolean,
	chased: boolean,
	panel: boolean,
	notice: boolean,
	moment: boolean,
	target: boolean,
}

function Spotlight.blocked(f: Facts): string?
	if not f.guide then
		return "guide"
	end
	if not f.alive then
		return "dead"
	end
	if not f.safe then
		return "zone"
	end
	if f.carrying then
		return "carrying"
	end
	if f.chased then
		return "chase"
	end
	if f.panel then
		return "panel"
	end
	if f.notice then
		return "notice"
	end
	if f.moment then
		return "moment"
	end
	if not f.target then
		return "target"
	end
	return nil
end

--==============================================================================
-- ONE LIFE PER STEP
--
-- A spotlight waits until nothing has blocked it for Settle seconds, shows
-- ONCE, and is then spent for the rest of its step, whichever way it ended:
--
--   lift   its button was pressed (or, for SPEED, the screen was tapped)
--   drop   a NEVER came true -- it costs the player nothing; the hand stays
--   fade   FadeAfter seconds passed unpressed; the hand stays
--
-- TutorialUI makes a fresh Light for every target when the step changes, so
-- "the life of the step" is exactly as long as the step.
--==============================================================================
export type Light = { phase: string, shownAt: number, clearSince: number? }

function Spotlight.newLight(): Light
	return { phase = "waiting", shownAt = 0, clearSince = nil }
end

-- One tick: "show", "lift", "drop", "fade" or nil (nothing changed).
function Spotlight.advance(light: Light, blocked: string?, pressed: boolean, now: number): string?
	if light.phase == "waiting" then
		if blocked ~= nil then
			-- Anything in the way starts the quiet period over.
			light.clearSince = nil
			return nil
		end
		local since = light.clearSince
		if since == nil then
			since = now
			light.clearSince = now
		end
		if now - since >= Spotlight.Settle then
			light.phase = "showing"
			light.shownAt = now
			return "show"
		end
	elseif light.phase == "showing" then
		if pressed then
			light.phase = "spent"
			return "lift"
		end
		if blocked ~= nil then
			light.phase = "spent"
			return "drop"
		end
		if now - light.shownAt >= Spotlight.FadeAfter then
			light.phase = "spent"
			return "fade"
		end
	end
	return nil
end

return Spotlight
