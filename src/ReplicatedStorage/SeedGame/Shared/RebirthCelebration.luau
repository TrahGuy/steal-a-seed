--!strict
--==============================================================================
-- Steal a Seed :: RebirthCelebration (2026-10-09)
--
-- The rebirth celebration as arithmetic (GameConfig.Rebirth.Celebration): what
-- shows at every moment of its 3.5 seconds, the turn that ends facing the
-- camera, the orbs' ring, who else sees it, its words, and where its card
-- stands on a screen. Pure: no instance, no remote, no clock of its own.
-- Shared/RebirthFX draws it, RebirthService sends it, RebirthCelebrationSpec
-- checks it.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Rebirth = require(Shared:WaitForChild("Rebirth"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local CFG = GameConfig.Rebirth
local C = CFG.Celebration
local W = C.Words
local TAU = math.pi * 2

local RebirthCelebration = {}

export type Rect = { x: number, y: number, w: number, h: number }

-- Slow in, slow out: the spin and the orbs' rise.
function RebirthCelebration.ease(x: number): number
	x = math.clamp(x, 0, 1)
	if x < 0.5 then
		return 4 * x * x * x
	end
	local u = -2 * x + 2
	return 1 - u * u * u / 2
end

local function easeOut(x: number): number
	x = math.clamp(x, 0, 1)
	return 1 - (1 - x) * (1 - x)
end

--==============================================================================
-- THE TIMELINE: everything that shows at `t` seconds after the server's "done"
--==============================================================================
export type Frame = {
	t: number,
	reduced: boolean,
	-- The screen's white-gold flash, 0 (none) to 1 (its brightest).
	flash: number,
	-- The column of light: its height (0 to 1 of Column.Height) and opacity.
	column: number,
	columnAlpha: number,
	-- How far round the body's turn is, 0 to 1, eased; and whether the camera
	-- and the controls are held for it.
	spin: number,
	held: boolean,
	-- The orbs: how far round they have gone (radians, the turn's other way),
	-- how far up (0 the feet, 1 over the head) and their opacity.
	orbAngle: number,
	orbRise: number,
	orbAlpha: number,
	-- The card: up or not, its size against its fitted size, its opacity; the
	-- rays behind it (opacity, and their angle in degrees).
	popup: boolean,
	popScale: number,
	popAlpha: number,
	rays: number,
	rayAngle: number,
	-- The burst, the leaves and the sparkles have gone off (once, at SpinSeconds).
	burst: boolean,
	-- Over: every piece goes.
	done: boolean,
}

-- REDUCED FX: no spin, orbs, rays, flash, column or burst; the card is up from
-- the first moment at its own size, and fades at the end like every card.
function RebirthCelebration.at(t: number, reduced: boolean): Frame
	local f: Frame = {
		t = t,
		reduced = reduced,
		flash = 0,
		column = 0,
		columnAlpha = 0,
		spin = 0,
		held = false,
		orbAngle = 0,
		orbRise = 0,
		orbAlpha = 0,
		popup = false,
		popScale = 1,
		popAlpha = 0,
		rays = 0,
		rayAngle = 0,
		burst = false,
		done = t >= C.Seconds,
	}
	local from = if reduced then 0 else C.PopupAt
	if t >= from and t < C.Seconds then
		f.popup = true
		local fadeAt = C.Seconds - C.FadeSeconds
		f.popAlpha = if t <= fadeAt then 1 else math.clamp((C.Seconds - t) / C.FadeSeconds, 0, 1)
		if not reduced then
			-- 0.6 -> 1.08 -> 1 of its fitted size.
			local u = (t - from) / C.PopSeconds
			if u < 0.6 then
				f.popScale = 0.6 + 0.48 * easeOut(u / 0.6)
			elseif u < 1 then
				f.popScale = 1.08 - 0.08 * RebirthCelebration.ease((u - 0.6) / 0.4)
			end
			f.rays = math.clamp(u, 0, 1) * f.popAlpha
			f.rayAngle = ((t - from) * C.RaySpin) % 360
		end
	end
	if reduced then
		return f
	end
	f.flash = if t < C.FlashSeconds then 1 - easeOut(t / C.FlashSeconds) else 0
	local col = C.Column
	f.column = if t < col.RiseSeconds then easeOut(t / col.RiseSeconds) else 1
	f.columnAlpha = if t <= col.FadeFrom
		then 1
		else math.clamp(1 - (t - col.FadeFrom) / (col.FadeTo - col.FadeFrom), 0, 1)
	local p = RebirthCelebration.ease(t / C.SpinSeconds)
	f.spin = p
	f.held = t < C.SpinSeconds
	f.orbRise = p
	f.orbAngle = -C.Orbs.Turns * TAU * p
	f.orbAlpha = if t < C.SpinSeconds
		then math.clamp(t / 0.15, 0, 1)
		else math.clamp(1 - (t - C.SpinSeconds) / C.Orbs.FadeSeconds, 0, 1)
	f.burst = t >= C.SpinSeconds
	return f
end

--==============================================================================
-- THE TURN: SpinTurns round, then on by the shorter way to face the camera
--==============================================================================
-- The heading a look vector points along: CFrame.Angles(0, yaw, 0) looks along
-- it.
function RebirthCelebration.yaw(look: Vector3): number
	return math.atan2(-look.X, -look.Z)
end

-- An angle folded into (-pi, pi].
function RebirthCelebration.wrap(a: number): number
	local folded = (a + math.pi) % TAU - math.pi
	if folded <= -math.pi then
		folded += TAU
	end
	return folded
end

-- The whole turn, in radians: between SpinTurns - 1/2 and SpinTurns + 1/2 turns,
-- ending with the body looking along `faceYaw` (towards the camera).
function RebirthCelebration.turn(startYaw: number, faceYaw: number): number
	return C.SpinTurns * TAU + RebirthCelebration.wrap(faceYaw - startYaw)
end

-- Where orb `i` (1 to Orbs.Count) stands against the body's root at a frame:
-- the ring turns the body's turn the other way, from the feet to over the head.
function RebirthCelebration.orb(i: number, f: Frame): Vector3
	local O = C.Orbs
	local a = f.orbAngle + (i - 1) * TAU / O.Count
	local round = CFrame.Angles(0, a, 0):VectorToWorldSpace(Vector3.new(O.Radius, 0, 0))
	return round + Vector3.new(0, O.FromY + (O.ToY - O.FromY) * f.orbRise, 0)
end

--==============================================================================
-- WHO ELSE SEES IT
--==============================================================================
-- Whether a body at `b` is close enough to one at `a` to see the celebration
-- there: both known, at most `range` (Celebration.Range) apart.
function RebirthCelebration.near(a: Vector3?, b: Vector3?, range: number?): boolean
	if not a or not b then
		return false
	end
	return (a - b).Magnitude <= (range or C.Range)
end

--==============================================================================
-- THE WORDS
--==============================================================================
export type Words = {
	reborn: string,
	line: string,
	bonus: string,
	-- The title's colour, and whether it is the ladder's rainbow (GAIA).
	colour: Color3,
	rainbow: boolean,
}

-- The card's three lines for a count: REBORN!, "REBIRTH 6 · BOTANIST II" and
-- "x4 training · x2.5 income" (the server's numbers when it sent them).
function RebirthCelebration.words(rebirths: any, training: any, income: any): Words
	local n = Rebirth.count(rebirths)
	local title, step = Rebirth.titleFor(n)
	local function number(value: any, fallback: number): number
		local v = tonumber(value)
		return if v and v == v and v > 0 and v < math.huge then v else fallback
	end
	return {
		reborn = W.Reborn,
		line = if title then string.format(W.Line, n, title) else string.format(CFG.Words.Current, n),
		bonus = string.format(W.Bonus, Rebirth.times(number(training, Rebirth.training(n))),
			Rebirth.times(number(income, Rebirth.income(n)))),
		colour = if step then step.Colour else Color3.new(1, 1, 1),
		rainbow = step ~= nil and step.Rainbow == true,
	}
end

-- The one line everybody else in the server reads:
-- "Pat reached REBIRTH 6 · BOTANIST II!".
function RebirthCelebration.serverLine(name: string, rebirths: any): string
	local n = Rebirth.count(rebirths)
	local title = Rebirth.titleFor(n)
	return string.format(W.Server, name, n, title or "")
end

-- The particles' colour: the title's family's palette, Primary to Secondary
-- over each one's life (since the 100 titles, 2026-10-10), or the rainbow at
-- GAIA; the orbs' gold with no title.
function RebirthCelebration.tint(rebirths: any): ColorSequence
	local step = Rebirth.title(rebirths)
	local family = Rebirth.family(step)
	if (step and step.Rainbow) or (family and family.Rainbow) then
		return WheelDraw.rainbow(0)
	elseif family then
		return ColorSequence.new(family.Primary, family.Secondary)
	end
	return ColorSequence.new(if step then step.Colour else C.Orbs.Colour)
end

-- Whether a count wears the aura (Aura.From rebirths and up).
function RebirthCelebration.auraFor(rebirths: any): boolean
	return Rebirth.count(rebirths) >= C.Aura.From
end

--==============================================================================
-- THE ACCENT AT THE BURST (2026-10-10, the 100 titles; Celebration's Motes,
-- Pulse, Seedlight and Halo)
--==============================================================================
export type Accent = {
	-- Rebirth.change: "name", "rank" or "none".
	change: string,
	family: Rebirth.Family?,
	-- A prototype family's own accent on a new name: "Seedlight" or "Halo".
	signature: string?,
	-- How many of the common leaves and sparkles the burst throws (none under a
	-- signature), and whether the title over the head pulses (a rank only).
	leaves: number,
	sparkles: number,
	pulse: boolean,
}

-- What the burst throws for a rebirth to `rebirths` from `before` (one less
-- when left out): a new name its family's signature, or the full leaves and
-- sparkles in its palette; a rank only, Motes of them and the pulse.
function RebirthCelebration.accent(rebirths: any, before: any?): Accent
	local n = Rebirth.count(rebirths)
	local was = if before == nil then math.max(0, n - 1) else Rebirth.count(before)
	local change = Rebirth.change(was, n)
	local family = Rebirth.family(Rebirth.title(n))
	local a: Accent = {
		change = change,
		family = family,
		signature = nil,
		leaves = C.Leaves.Count,
		sparkles = C.Sparkles.Count,
		pulse = false,
	}
	if change == "rank" then
		a.leaves, a.sparkles, a.pulse = C.Motes.Leaves, C.Motes.Sparkles, true
	elseif change == "name" and family and family.Signature then
		a.signature, a.leaves, a.sparkles = family.Signature, 0, 0
	end
	return a
end

-- The title's pulse `u` seconds after the burst: its scale, 1 outside Pulse.
function RebirthCelebration.pulse(u: number): number
	local P = C.Pulse
	if u <= 0 or u >= P.Seconds then
		return 1
	end
	return 1 + (P.Scale - 1) * math.sin(math.pi * u / P.Seconds)
end

-- SEEDLIGHT: leaf `i` of `count`, `u` seconds after the burst. Its offset from
-- the head in CAMERA space (a billboard's StudsOffset: x right, y up), on an
-- arc Radius round it from the left shoulder over the top to the right, each
-- one Stagger after the last; and its opacity (0 before it sets off and once it
-- has landed).
function RebirthCelebration.seedlightLeaf(i: number, count: number, u: number): (Vector3, number)
	local S = C.Seedlight
	local start = (i - 1) * S.Stagger
	local p = math.clamp((u - start) / S.ArcSeconds, 0, 1)
	local a = math.rad(-80 + 160 * RebirthCelebration.ease(p))
	local at = Vector3.new(math.sin(a) * S.Radius, math.cos(a) * S.Radius * 0.75, 0)
	local alpha = if u < start then 0 elseif p < 0.15 then p / 0.15 elseif p > 0.8 then (1 - p) / 0.2 else 1
	return at, math.clamp(alpha, 0, 1)
end

-- WORLD TREE HALO: leaf `i` of `count`, `u` seconds after the burst. Its offset
-- from the head in the WORLD (an attachment's), round a ring Above it opening
-- from From to To studs in Seconds while it turns Turn of a circle; and its
-- opacity.
function RebirthCelebration.haloLeaf(i: number, count: number, u: number): (Vector3, number)
	local H = C.Halo
	local p = math.clamp(u / H.Seconds, 0, 1)
	local e = easeOut(p)
	local r = H.From + (H.To - H.From) * e
	local a = (i - 1) * TAU / math.max(1, count) + H.Turn * TAU * e
	local at = Vector3.new(math.cos(a) * r, H.Above + 0.4 * e, math.sin(a) * r)
	local alpha = if u <= 0 then 0 elseif p < 0.1 then p / 0.1 elseif p > 0.7 then (1 - p) / 0.3 else 1
	return at, math.clamp(alpha, 0, 1)
end

-- The halo's sunburst `u` seconds after the burst: its opacity, in and out over
-- RaysSeconds.
function RebirthCelebration.haloRays(u: number): number
	local H = C.Halo
	if u <= 0 or u >= H.RaysSeconds then
		return 0
	end
	return math.sin(math.pi * u / H.RaysSeconds)
end

--==============================================================================
-- THE AURA'S COLOURS AND WHO WEARS IT (2026-10-10)
--==============================================================================
-- The two wisps' colours for a count -- its family's Primary and Secondary --
-- and whether they wear the rainbow instead (GAIA); with how many accent
-- leaves go round it (the family's AuraAccents, at most two).
function RebirthCelebration.auraLook(rebirths: any): (Color3, Color3, boolean, number)
	local step = Rebirth.title(rebirths)
	local family = Rebirth.family(step)
	local rainbow = (step ~= nil and step.Rainbow == true) or (family ~= nil and family.Rainbow == true)
	local accents = math.clamp(math.floor(if family then family.AuraAccents or 0 else 0), 0, 2)
	if family then
		return family.Primary, family.Secondary, rainbow, accents
	end
	local colour = if step then step.Colour else C.Orbs.Colour
	return colour, colour, rainbow, accents
end

-- Accent leaf `i` of `count` round an aura at `now`: its offset in camera space
-- (once round every Accent.Seconds, the two half a turn apart, bobbing).
function RebirthCelebration.auraAccent(i: number, count: number, now: number): Vector3
	local A = C.Aura.Accent
	local a = (now / A.Seconds) * TAU + (i - 1) * TAU / math.max(1, count)
	return Vector3.new(math.cos(a) * A.Radius, A.Lift + math.sin(a * 2) * A.Bob, math.sin(a) * A.Radius)
end

-- Which of these distances (a viewer's camera to each aura's body) show their
-- aura: the `keep` nearest within `within`, by index; ties to the first.
function RebirthCelebration.nearest(distances: { number }, keep: number, within: number): { [number]: boolean }
	local order: { number } = {}
	for i, d in ipairs(distances) do
		if d == d and d <= within then
			table.insert(order, i)
		end
	end
	table.sort(order, function(a: number, b: number): boolean
		if distances[a] ~= distances[b] then
			return distances[a] < distances[b]
		end
		return a < b
	end)
	local shown: { [number]: boolean } = {}
	for k = 1, math.min(keep, #order) do
		shown[order[k]] = true
	end
	return shown
end

--==============================================================================
-- WHERE THE CARD STANDS
--
-- The upper middle of the safe area, clear of every HUD rect (HudLayout
-- .occupied) by Gap, its middle in the upper half; as large as fits up to its
-- own size -- a phone's menu size there (MenuSize.PhoneScale) -- and never under
-- MinScale. At each size and height the middle is tried first, then a step
-- either side, nearest first (a small phone's free gap between its corner
-- buttons is off the middle: 640 x 360 drew it at 0.61 centred, its words
-- under 12 px). Answers its rect and its scale against Popup.Size. With no
-- clear spot at any size it stands just under the top at MinScale: it passes
-- in seconds and takes no tap but its own.
--
-- `soft` (2026-10-09): rects it keeps off as well wherever it still draws at
-- Popup.Readable or larger -- the notices' line, the notices' only while one
-- passes (HudLayout.occupiedButToast). Under the phone's panel row keeping off
-- it drew 640 x 360's card at 0.63, its Bonus line under 12 px; there it gives
-- way, and only where that draws the card larger.
--==============================================================================
local function search(safe: Vector2, avoid: { Rect }, phone: boolean): (Rect, number)
	local P = C.Popup
	local base = P.Size
	local gap = P.Gap
	local sw, sh = safe.X, safe.Y
	local largest = math.min(if phone then GameConfig.MenuSize.PhoneScale else 1, (sw - gap * 2) / base.X,
		(sh - gap * 2) / base.Y)
	local function clear(r: Rect): boolean
		if r.x < gap or r.y < gap or r.x + r.w > sw - gap or r.y + r.h > sh - gap then
			return false
		end
		for _, a in ipairs(avoid) do
			if a.w > 0 and a.h > 0 and r.x < a.x + a.w + gap and a.x < r.x + r.w + gap
				and r.y < a.y + a.h + gap and a.y < r.y + r.h + gap then
				return false
			end
		end
		return true
	end
	local scale = largest
	while scale >= P.MinScale - 1e-9 do
		local w, h = math.floor(base.X * scale), math.floor(base.Y * scale)
		local middle = math.floor(sw / 2 - w / 2)
		-- The middle at any height first, then a step either side, never more
		-- than Shift of the width off it.
		local shift = 0
		while shift <= sw * P.Shift do
			for _, x in ipairs(if shift == 0 then { middle } else { middle - shift, middle + shift }) do
				local y = gap
				while y + h / 2 <= sh / 2 do
					local r = { x = x, y = y, w = w, h = h }
					if clear(r) then
						return r, w / base.X
					end
					y += 4
				end
			end
			shift += 8
		end
		scale -= P.Step
	end
	local s = math.min(largest, P.MinScale)
	local w, h = math.floor(base.X * s), math.floor(base.Y * s)
	return { x = math.floor(sw / 2 - w / 2), y = gap, w = w, h = h }, w / base.X
end

function RebirthCelebration.popup(safe: Vector2, avoid: { Rect }, phone: boolean, soft: { Rect }?): (Rect, number)
	local all = avoid
	if soft and #soft > 0 then
		all = table.clone(avoid)
		for _, r in ipairs(soft) do
			table.insert(all, r)
		end
	end
	local r, s = search(safe, all, phone)
	if soft and #soft > 0 and s < C.Popup.Readable - 1e-9 then
		local r2, s2 = search(safe, avoid, phone)
		if s2 > s + 1e-9 then
			return r2, s2
		end
	end
	return r, s
end

return RebirthCelebration
