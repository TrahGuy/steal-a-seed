--!strict
--==============================================================================
-- Steal a Seed :: TitleFX (2026-10-10, the owner's brief: Kenney leaves,
-- flowers and mist round the rebirth titles)
--
-- THE LAYER OF SMALL PICTURES ROUND A REBIRTH TITLE'S WORDS. Client only,
-- cosmetic only; OwnerTitleUI owns every layer and moves them all from its one
-- loop. GameConfig.TitleFX holds the art, the profiles and which ladder step
-- wears which.
--
--   profileFor   a ladder step (Rebirth.title) to its profile and how many
--                sprites -- nil for a step with none, or one whose art the
--                owner has not uploaded yet (every id "": all of them off)
--   pose         where sprite i of n stands at time t, in the title's own
--                pixels: one motion per profile (drift, outward, laurel,
--                mist), shared by every title that wears it
--   nearest      the titles that move: the MaxAnimated nearest this camera
--   attach       a transparent frame of ImageLabels under the words -- under
--                REBIRTH N too -- each hidden until its picture has loaded
--
-- Everything stays inside the title's band (its own height): ADMIN stands over
-- it and the player's name under it. The words and REBIRTH N stay on top, and
-- nothing here makes a light, a panel or anything opaque.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local TitleFX = {}

local FX = GameConfig.TitleFX
local TITLE = GameConfig.Rebirth.Title

export type Pose = {
	art: string,
	tint: Color3,
	-- The sprite's middle, in the title's pixels from its top left.
	x: number,
	y: number,
	size: number,
	rotation: number,
	transparency: number,
}

-- How far through its cycle sprite i of n is at time t (0..1): the n spread
-- evenly round the cycle, so they never all fade together.
local function cycle(seconds: number, t: number, i: number, n: number): number
	local u = t / seconds + (i - 1) / n
	return u - math.floor(u)
end

-- In over the first fifth of a cycle, out over the last third: smooth, never
-- a blink (no step is quicker than a fifth of the cycle).
local function envelope(u: number): number
	local function smooth(a: number): number
		local x = math.clamp(a, 0, 1)
		return x * x * (3 - 2 * x)
	end
	return smooth(u / 0.2) * smooth((1 - u) / 0.33)
end

-- A step's profile name, its profile and its sprite count; nil while the step
-- has none or any of its art is missing.
function TitleFX.profileFor(step: { Text: string }?): (string?, any?, number)
	local wants = if step then FX.Steps[step.Text] else nil
	if not wants then
		return nil, nil, 0
	end
	local profile = FX.Profiles[wants.Profile]
	if not profile or not TitleFX.ready(profile) then
		return nil, nil, 0
	end
	return wants.Profile, profile, math.clamp(wants.Count, 1, FX.MaxSprites)
end

-- Whether every picture a profile uses has an id.
function TitleFX.ready(profile: any): boolean
	for _, key in ipairs(profile.Art) do
		local id = FX.Art[key]
		if type(id) ~= "string" or id == "" then
			return false
		end
	end
	return true
end

--==============================================================================
-- WHERE A SPRITE STANDS
--
-- `box` is the title's size now (a phone's is smaller: everything scales by its
-- height), `words` the drawn width of its words. Sprites go to the words' left
-- and right in turn (odd left, even right), each its own phase.
--==============================================================================
function TitleFX.pose(profile: any, i: number, n: number, t: number, box: Vector2, words: number): Pose
	local k = box.Y / TITLE.Size.Y
	local mid = box.X / 2
	local half = words / 2
	local side = if i % 2 == 1 then -1 else 1
	-- Left and right go in pairs (1-2, 3-4, 5-6), each pair one picture and
	-- one tint, so neither side wears only one kind.
	local pair = (i - 1) // 2
	local art = profile.Art[(pair % #profile.Art) + 1]
	local tint = profile.Tints[(pair % #profile.Tints) + 1]
	local motion = profile.Motion
	-- The words' line is the band's top six tenths (RebirthService's split).
	local line = box.Y * 0.3
	if motion == "laurel" and i <= 2 then
		-- A sprig at each end, leaning out, swaying a few degrees.
		local size = profile.Size * k
		local sway = profile.Sway * math.sin(2 * math.pi * t / profile.Seconds + i)
		return {
			art = if side < 0 then "SprigLeft" else "SprigRight",
			tint = profile.Tints[1],
			x = mid + side * (half + 2 * k + size * 0.4),
			y = box.Y * 0.45,
			size = size,
			rotation = side * 12 + sway,
			transparency = profile.Transparency,
		}
	elseif motion == "mist" then
		-- Behind the lettering's left and right, never its middle; outer
		-- puffs for the third and fourth.
		local u = cycle(profile.Seconds, t, i, n)
		local outer = i > 2
		local size = math.min(profile.Size * k, box.Y)
		local wave = math.sin(2 * math.pi * u)
		return {
			art = art,
			tint = tint,
			x = mid + side * (half * (if outer then 0.92 else 0.55)) + profile.Drift * k * wave,
			y = box.Y * 0.5,
			size = size,
			rotation = profile.Turn * wave,
			transparency = math.clamp(profile.Transparency + profile.Breathe * math.cos(2 * math.pi * u), 0, 1),
		}
	end
	-- drift (nature), outward (bloom) and the laurel's loose leaves: out from
	-- the words' end and a little down, turning, fading in and out.
	local u = cycle(profile.Seconds, t, i, n)
	local size = (if motion == "laurel" then profile.LeafSize else profile.Size) * k
	local start = half + (if motion == "outward" then -4 else 4) * k
	if motion == "laurel" then
		-- Beyond the sprigs, and never a sprig's own picture.
		start = half + profile.Size * k + 2 * k
		art = profile.LeafArt
	end
	local x = mid + side * (start + u * profile.Travel * k)
	local y = line + (u - 0.3) * profile.Fall * k
	return {
		art = art,
		tint = tint,
		x = x,
		y = math.clamp(y, size / 2, box.Y - size / 2),
		size = size,
		rotation = side * (u - 0.5) * profile.Turn + (i * 37) % 360,
		transparency = 1 - (1 - profile.Transparency) * envelope(u),
	}
end

-- Which of `titles` move: the `max` nearest, each within `range`. Answers a set.
function TitleFX.nearest<T>(titles: { { key: T, distance: number } }, max: number, range: number): { [T]: boolean }
	local within = {}
	for _, entry in ipairs(titles) do
		if entry.distance <= range then
			table.insert(within, entry)
		end
	end
	table.sort(within, function(a, b)
		return a.distance < b.distance
	end)
	local out = {}
	for index = 1, math.min(max, #within) do
		out[within[index].key] = true
	end
	return out
end

--==============================================================================
-- THE LAYER ON A TITLE
--==============================================================================
export type Layer = {
	-- Poses every sprite at time t (os.clock) and shows the layer.
	step: (t: number) -> (),
	-- Hides it: Reduced FX, too far, not among the nearest, the title hidden.
	hide: () -> (),
	destroy: () -> (),
	frame: Frame,
}

function TitleFX.attach(gui: BillboardGui, profile: any, count: number): Layer
	-- A sprite out past the words' ends must not be cut at the box.
	pcall(function()
		(gui :: any).ClipsDescendants = false
	end)
	local frame = Instance.new("Frame")
	frame.Name = "TitleFX"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Active = false
	-- Under the words and REBIRTH N (theirs is the default 1).
	frame.ZIndex = 0
	frame.Visible = false
	frame.Parent = gui
	local made = os.clock()
	local sprites: { ImageLabel } = {}
	for i = 1, count do
		local label = Instance.new("ImageLabel")
		label.Name = "Sprite" .. i
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.ScaleType = Enum.ScaleType.Fit
		label.ZIndex = 0
		label.Active = false
		-- A sprite's picture never changes (its art is its index's), so it is
		-- set once, here, and fetched from now; clear until it has loaded.
		label.Image = FX.Art[TitleFX.pose(profile, i, count, 0, TITLE.Size, TITLE.Size.X / 2).art] or ""
		label.ImageTransparency = 1
		label.Parent = frame
		sprites[i] = label
	end
	local words = gui:FindFirstChild("Words")
	local shown = false
	local layer: Layer
	layer = {
		frame = frame,
		step = function(t: number)
			if not frame.Parent then
				return
			end
			local box = gui.AbsoluteSize
			if box.X <= 0 or box.Y <= 0 then
				local size = gui.Size
				box = Vector2.new(size.X.Offset, size.Y.Offset)
			end
			local width = if words and words:IsA("TextLabel") and words.TextBounds.X > 0
				then words.TextBounds.X
				else box.X * 0.6
			local settled = os.clock() - made >= FX.SettleSeconds
			for i, label in ipairs(sprites) do
				local pose = TitleFX.pose(profile, i, count, t, box, width)
				if label.ImageColor3 ~= pose.tint then
					label.ImageColor3 = pose.tint
				end
				label.Position = UDim2.fromOffset(pose.x, pose.y)
				label.Size = UDim2.fromOffset(pose.size, pose.size)
				label.Rotation = pose.rotation
				-- A picture that never loads stays clear: the words alone.
				label.ImageTransparency = if settled and label.IsLoaded then pose.transparency else 1
			end
			if not shown then
				shown = true
				frame.Visible = true
			end
		end,
		hide = function()
			if shown then
				shown = false
				frame.Visible = false
			end
		end,
		destroy = function()
			frame:Destroy()
			table.clear(sprites)
		end,
	}
	return layer
end

return TitleFX
