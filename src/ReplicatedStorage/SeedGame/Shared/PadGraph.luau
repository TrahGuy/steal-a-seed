--!strict
--==============================================================================
-- Steal a Seed :: PadGraph
--
-- A CONTROLLER'S D-PAD THROUGH A PANEL, DECIDED RATHER THAN GUESSED
-- (2026-10-13; Michael's console feedback, the owner's backlog item 2: "shop
-- navigation on console is busted").
--
-- Left alone, the engine picks the next control by its own guess at what is
-- "nearest that way" -- and in a panel of buttons standing on buttons (a card's
-- face and its BUY), a scaled banner and a scrolling list, the guess skips rows
-- and jumps sideways. So a panel hands this its controls, and gets back four
-- written links for each (NextSelectionUp/Down/Left/Right):
--
--   rows     controls whose centres are within a few pixels of each other in Y
--            are one row, read top to bottom, each left to right
--   left /   the neighbours in the row; at either end, itself (the press stays
--   right    put rather than leaving the row)
--   up /     the control in the row above / below whose centre is nearest in X
--   down     (the left one on a tie); past the first or the last row, itself
--
-- And `scrollInto`, which brings a selected control inside its scrolling list
-- with a margin, so the list follows the selection.
--
-- Pure apart from `wire` and `scrollInto`, which read and write instances.
-- ShopPadSpec holds it.
--==============================================================================

local PadGraph = {}

export type Stop = { id: any, x: number, y: number }
export type Link = { up: any, down: any, left: any, right: any }
export type Links = { [any]: Link }

-- Rows within this many pixels of each other in Y are one row (PadFocus's rule).
PadGraph.RowTolerance = 6

--==============================================================================
-- ROWS: top to bottom, each left to right
--==============================================================================
function PadGraph.rows(stops: { Stop }, tolerance: number?): { { Stop } }
	local slack = tolerance or PadGraph.RowTolerance
	local sorted = table.clone(stops)
	table.sort(sorted, function(a: Stop, b: Stop): boolean
		if a.y ~= b.y then
			return a.y < b.y
		end
		return a.x < b.x
	end)
	local rows: { { Stop } } = {}
	local current: { Stop }? = nil
	local rowY = 0
	for _, stop in ipairs(sorted) do
		if current and math.abs(stop.y - rowY) <= slack then
			table.insert(current, stop)
		else
			current = { stop }
			rowY = stop.y
			table.insert(rows, current :: { Stop })
		end
	end
	for _, row in ipairs(rows) do
		table.sort(row, function(a: Stop, b: Stop): boolean
			return a.x < b.x
		end)
	end
	return rows
end

-- The stop in `row` whose centre is nearest `x`; the left one on a tie.
local function nearest(row: { Stop }, x: number): Stop
	local best = row[1]
	local gap = math.abs(best.x - x)
	for i = 2, #row do
		local d = math.abs(row[i].x - x)
		if d < gap - 1e-6 then
			best, gap = row[i], d
		end
	end
	return best
end

--==============================================================================
-- LINKS: every stop's four, from its rows
--==============================================================================
function PadGraph.links(rows: { { Stop } }): Links
	local out: Links = {}
	local live: { { Stop } } = {}
	for _, row in ipairs(rows) do
		if #row > 0 then
			table.insert(live, row)
		end
	end
	for r, row in ipairs(live) do
		local above = live[r - 1]
		local below = live[r + 1]
		for i, stop in ipairs(row) do
			out[stop.id] = {
				left = if i > 1 then row[i - 1].id else stop.id,
				right = if i < #row then row[i + 1].id else stop.id,
				up = if above then nearest(above, stop.x).id else stop.id,
				down = if below then nearest(below, stop.x).id else stop.id,
			}
		end
	end
	return out
end

-- Every stop reachable from `first` through the links.
function PadGraph.reach(links: Links, first: any): { [any]: boolean }
	local seen: { [any]: boolean } = {}
	local queue = { first }
	seen[first] = true
	local i = 1
	while i <= #queue do
		local link = links[queue[i]]
		i += 1
		if link then
			for _, nextId in ipairs({ link.up, link.down, link.left, link.right }) do
				if nextId ~= nil and not seen[nextId] then
					seen[nextId] = true
					table.insert(queue, nextId)
				end
			end
		end
	end
	return seen
end

--==============================================================================
-- ON INSTANCES
--
-- `wire`: GROUPS of controls, stacked top to bottom in the order given -- a
-- header, then a scrolling page -- each group's rows from its controls'
-- centres on the screen. A page's controls move together as it scrolls, so its
-- rows hold; but one scrolled up past the window stands higher on the screen
-- than the header, which is why the groups are never sorted together. The
-- links go into NextSelection*. Answers the rows, top first.
--
-- `scrollInto`: `object`, inside `scroller`, brought `margin` pixels inside
-- its visible window if it stands outside it. The canvas is in the list's own
-- units: the screen's pixels divided by what the list is drawn at, read off
-- its offset height (the Shop's list is sized in offsets) or 1.
--==============================================================================
function PadGraph.wire(groups: { { GuiObject } }, tolerance: number?): { { Stop } }
	local rows: { { Stop } } = {}
	for _, group in ipairs(groups) do
		local stops: { Stop } = {}
		for _, control in ipairs(group) do
			local at, size = control.AbsolutePosition, control.AbsoluteSize
			table.insert(stops, { id = control, x = at.X + size.X * 0.5, y = at.Y + size.Y * 0.5 })
		end
		for _, row in ipairs(PadGraph.rows(stops, tolerance)) do
			table.insert(rows, row)
		end
	end
	local links = PadGraph.links(rows)
	for _, group in ipairs(groups) do
		for _, control in ipairs(group) do
			local link = links[control]
			if link then
				control.NextSelectionUp = link.up
				control.NextSelectionDown = link.down
				control.NextSelectionLeft = link.left
				control.NextSelectionRight = link.right
			end
		end
	end
	return rows
end

function PadGraph.scrollInto(scroller: ScrollingFrame, object: GuiObject, margin: number?): boolean
	local room = margin or 12
	local offsetH = scroller.Size.Y.Offset
	local k = if offsetH > 0 and scroller.Size.Y.Scale == 0 and scroller.AbsoluteSize.Y > 0
		then scroller.AbsoluteSize.Y / offsetH
		else 1
	local top = scroller.AbsolutePosition.Y
	local bottom = top + scroller.AbsoluteWindowSize.Y
	local oTop = object.AbsolutePosition.Y
	local oBottom = oTop + object.AbsoluteSize.Y
	local at = scroller.CanvasPosition
	local want = at.Y
	if oTop < top + room * k then
		want = at.Y - (top + room * k - oTop) / k
	elseif oBottom > bottom - room * k then
		want = at.Y + (oBottom - (bottom - room * k)) / k
	end
	want = math.max(0, want)
	if math.abs(want - at.Y) < 0.5 then
		return false
	end
	scroller.CanvasPosition = Vector2.new(at.X, want)
	return true
end

return PadGraph
