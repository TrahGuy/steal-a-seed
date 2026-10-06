--!strict
--==============================================================================
-- Steal a Seed :: PressGesture (2026-10-03, the owner's compact Bag + free
-- hotbar)
--
-- WHAT A PRESS ON A TILE OR A SLOT MEANT, AS ARITHMETIC. Pure: positions and
-- times in, a word out. LoadoutUI feeds it the InputObject's raw Position (the
-- SeedLoadout ScreenGui does not ignore the inset, so input and AbsolutePosition
-- agree) and the grid's CanvasPosition; InventoryModelSpec drives every case.
--
--   touch   moving past Slop, or the canvas moving past CanvasSlop, is a SCROLL
--           -- never a tap, a long-press or a drag. Held LongPress seconds
--           without that is a LONG press (the menu), answered once by the
--           caller's task.delay, never by a frame hook. Anything else, a TAP.
--   mouse   DragAt pixels on something draggable starts a DRAG. A mouse never
--           long-presses: right-click is its menu. A scroll wheel turned during
--           the press is a scroll.
--   pad     always a tap.
--
-- Sticky: once a press is a scroll, a drag or a long press it stays one.
--==============================================================================
local PressGesture = {}

PressGesture.Slop = 10
PressGesture.CanvasSlop = 4
PressGesture.LongPress = 0.45
PressGesture.DragAt = 8

export type Press = {
	by: string, -- "touch" | "mouse" | "pad"
	at: Vector2,
	canvas: Vector2,
	started: number,
	draggable: boolean,
	state: string, -- "pressing" | "long" | "drag" | "scroll"
}

function PressGesture.begin(by: string, at: Vector2, canvas: Vector2, now: number, draggable: boolean): Press
	return {
		by = by,
		at = at,
		canvas = canvas,
		started = now,
		draggable = draggable,
		state = "pressing",
	}
end

-- The press as it stands, given where the pointer and the canvas are now.
function PressGesture.step(p: Press, at: Vector2?, canvas: Vector2?, now: number): string
	if p.state ~= "pressing" or p.by == "pad" then
		return p.state
	end
	local moved = if at then (at - p.at).Magnitude else 0
	local scrolled = if canvas then (canvas - p.canvas).Magnitude else 0
	if p.by == "touch" then
		if moved > PressGesture.Slop or scrolled > PressGesture.CanvasSlop then
			p.state = "scroll"
		elseif now - p.started >= PressGesture.LongPress then
			p.state = "long"
		end
	elseif p.by == "mouse" then
		if scrolled > PressGesture.CanvasSlop then
			p.state = "scroll"
		elseif p.draggable and moved >= PressGesture.DragAt then
			p.state = "drag"
		end
	end
	return p.state
end

-- The finger or the button came up: "tap" or "none" (a scroll, a long press
-- whose menu already opened, a drag the caller ends itself, or a mouse press
-- on something not draggable that wandered off).
function PressGesture.release(p: Press, at: Vector2?, canvas: Vector2?, now: number): string
	local state = PressGesture.step(p, at, canvas, now)
	if state ~= "pressing" then
		return "none"
	end
	if p.by == "mouse" and at and (at - p.at).Magnitude > PressGesture.Slop then
		return "none"
	end
	return "tap"
end

export type Rect = { x: number, y: number, w: number, h: number }

local function inside(pt: Vector2, r: Rect, tol: number): boolean
	return pt.X >= r.x - tol and pt.X <= r.x + r.w + tol and pt.Y >= r.y - tol and pt.Y <= r.y + r.h + tol
end

-- Where a drag let go: "slot" and its index (the fixed holders, `tol` pixels
-- wide so the gaps between them belong to a slot), else "bag" when it is over
-- the open panel or the Bag cell, else nil (cancel). A slot wins over the bag.
function PressGesture.dropTarget(pt: Vector2, slots: { Rect }, bag: { Rect }, tol: number): (string?, number?)
	local best: number? = nil
	local bestDistance = math.huge
	for index, r in ipairs(slots) do
		if r.w > 0 and inside(pt, r, tol) then
			local centre = Vector2.new(r.x + r.w / 2, r.y + r.h / 2)
			local d = (pt - centre).Magnitude
			if d < bestDistance then
				best, bestDistance = index, d
			end
		end
	end
	if best then
		return "slot", best
	end
	for _, r in ipairs(bag) do
		if r.w > 0 and inside(pt, r, 0) then
			return "bag", nil
		end
	end
	return nil, nil
end

return PressGesture
