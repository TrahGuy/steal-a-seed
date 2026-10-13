--!strict
--==============================================================================
-- Steal a Seed :: PadScroll
--
-- THE RIGHT STICK SCROLLS AN OPEN MENU (2026-10-13; Michael's console
-- feedback, the owner's backlog item 3: "In menus the right stick should lock
-- for scrolling. I can see character is still looking around.")
--
-- The numbers and the choice, for PadStick.client (which binds the stick
-- above the camera while any panel is open, and scrolls with it):
--
--   rate     a stick's tilt to a scroll speed: nothing inside Deadzone, then
--            rising on a square from there to Speed at full tilt, so a light
--            push creeps and a full one runs
--   step     one frame of scrolling: the canvas moves by the rate, push up
--            to go up, and never past either end
--   pick     which list the stick scrolls: the nearest one around the
--            selected control that can scroll that way, else the panel's
--            biggest one that can -- or none
--
-- Pure apart from `limit` and `pick`, which read instances. PadStickSpec holds it.
--==============================================================================

local PadScroll = {}

-- A stick resting off-centre (most do, a little) scrolls nothing.
PadScroll.Deadzone = 0.22
-- Canvas pixels a second at full tilt.
PadScroll.Speed = 1100

-- One axis: -1..1 tilt to canvas pixels a second, the sign kept.
function PadScroll.rate(tilt: number): number
	if tilt ~= tilt then
		return 0
	end
	local a = math.abs(tilt)
	if a <= PadScroll.Deadzone then
		return 0
	end
	local t = math.min((a - PadScroll.Deadzone) / (1 - PadScroll.Deadzone), 1)
	return (if tilt > 0 then 1 else -1) * t * t * PadScroll.Speed
end

-- The canvas after `dt` seconds of `stick` (X right, Y up, as the engine
-- reports Thumbstick2), at `at`, between 0 and `limit` on each axis. Pushing
-- up scrolls up: the canvas's Y goes DOWN.
function PadScroll.step(at: Vector2, limit: Vector2, stick: Vector2, dt: number): Vector2
	local d = if dt == dt then math.clamp(dt, 0, 0.1) else 0
	local x = at.X + PadScroll.rate(stick.X) * d
	local y = at.Y - PadScroll.rate(stick.Y) * d
	return Vector2.new(math.clamp(x, 0, math.max(limit.X, 0)), math.clamp(y, 0, math.max(limit.Y, 0)))
end

-- How far a list can scroll on each axis: its canvas past its window, in the
-- canvas's own pixels -- 0 on an axis its ScrollingDirection does not scroll,
-- and 0 for the pixel or so a canvas that fits reports past its window.
function PadScroll.limit(list: ScrollingFrame): Vector2
	local canvas, window = list.AbsoluteCanvasSize, list.AbsoluteWindowSize
	-- AbsoluteCanvasSize is drawn pixels; the canvas position is the list's own.
	local k = if list.AbsoluteSize.Y > 0 and list.Size.Y.Scale == 0 and list.Size.Y.Offset > 0
		then list.AbsoluteSize.Y / list.Size.Y.Offset
		else 1
	local x = (canvas.X - window.X) / k
	local y = (canvas.Y - window.Y) / k
	local direction = list.ScrollingDirection
	if direction == Enum.ScrollingDirection.Y or x < 2 then
		x = 0
	end
	if direction == Enum.ScrollingDirection.X or y < 2 then
		y = 0
	end
	return Vector2.new(x, y)
end

-- The list `stick` scrolls in `panel`: the nearest list around `selected`
-- that can move the way the stick is pushed, else the panel's biggest such
-- list on screen; nil when nothing there can.
local function canGo(list: ScrollingFrame, stick: Vector2): boolean
	if not (list.ScrollingEnabled and list.Visible and list.AbsoluteSize.X > 0) then
		return false
	end
	local room = PadScroll.limit(list)
	local wantX = math.abs(stick.X) > PadScroll.Deadzone
	local wantY = math.abs(stick.Y) > PadScroll.Deadzone
	return (wantY and room.Y > 0) or (wantX and room.X > 0)
end

local function shown(object: GuiObject, root: Instance): boolean
	local node: Instance? = object
	while node and node ~= root do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("LayerCollector") and not node.Enabled then
			return false
		end
		node = node.Parent
	end
	return node == root
end

function PadScroll.pick(selected: GuiObject?, panel: Instance?, stick: Vector2): ScrollingFrame?
	if not panel then
		return nil
	end
	if selected and selected:IsDescendantOf(panel) then
		local node: Instance? = selected.Parent
		while node and node ~= panel do
			if node:IsA("ScrollingFrame") and canGo(node, stick) and shown(node, panel) then
				return node
			end
			node = node.Parent
		end
	end
	local best: ScrollingFrame? = nil
	local area = 0
	for _, d in ipairs(panel:GetDescendants()) do
		if d:IsA("ScrollingFrame") and canGo(d, stick) and shown(d, panel) then
			local size = d.AbsoluteSize.X * d.AbsoluteSize.Y
			if size > area then
				best, area = d, size
			end
		end
	end
	return best
end

return PadScroll
