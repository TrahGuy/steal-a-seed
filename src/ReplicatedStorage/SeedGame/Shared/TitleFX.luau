--!strict
--==============================================================================
-- Steal a Seed :: TitleFX (2026-10-10, the owner's brief: Kenney leaves,
-- flowers and mist round the rebirth titles; livelier the same day: "rapid
-- animations, specially on gaia, a rapid rainbow color")
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
--                mist), shared by every title that wears it; a Rainbow
--                profile's sprites each flow through the hues
--   glint        where the white glint across the words is at time t, or nil
--                while it rests
--   twinkle      where twinkle j of the owner's sparkle sheet pops at time t
--                and which of its frames shows, or nil while it rests
--   nearest      the titles that move: the MaxAnimated nearest this camera
--   attach       a transparent frame of ImageLabels under the words -- under
--                REBIRTH N too -- each hidden until its picture has loaded,
--                with the glint and the twinkles over the words; over a head
--                (a BillboardGui) or, given a Place, beside a word in a list
--                (the Rebirth panel's "?" TITLES, RebirthUI)
--
-- Everything stays inside the title's band (its own height): ADMIN stands over
-- it and the player's name under it. Nothing here makes a light, a panel or
-- anything opaque, and nothing jumps in brightness: the glint sweeps, the
-- twinkles pop through their frames, the hues flow.
--==============================================================================
local ContentProvider = game:GetService("ContentProvider")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local TitleFX = {}

local FX = GameConfig.TitleFX
local TITLE = GameConfig.Rebirth.Title
local WHITE = Color3.fromRGB(255, 255, 255)

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

-- A steady pseudo-random 0..1 for a pair of numbers: the same twinkle at the
-- same moment lands in the same place on every screen and in the spec.
local function hash(a: number, b: number): number
	local x = math.sin(a * 12.9898 + b * 78.233) * 43758.5453
	return x - math.floor(x)
end

-- A Rainbow profile's hue for sprite i of n at time t, flowing a whole turn
-- every RainbowSeconds.
local function hue(i: number, n: number, t: number): Color3
	local h = (i - 1) / math.max(n, 1) + t / FX.RainbowSeconds
	return Color3.fromHSV(h - math.floor(h), 0.55, 1)
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
-- height), `words` the drawn width of its words and `centre` their middle
-- (the box's, where none is given: a head's words are centred). Sprites go to
-- the words' left and right in turn (odd left, even right), each its own phase.
--==============================================================================
function TitleFX.pose(profile: any, i: number, n: number, t: number, box: Vector2, words: number,
	centre: number?): Pose
	local k = box.Y / TITLE.Size.Y
	local mid = centre or box.X / 2
	local half = words / 2
	local side = if i % 2 == 1 then -1 else 1
	-- Left and right go in pairs (1-2, 3-4, 5-6), each pair one picture and
	-- one tint, so neither side wears only one kind.
	local pair = (i - 1) // 2
	local art = profile.Art[(pair % #profile.Art) + 1]
	local tint = if profile.Rainbow then hue(i, n, t) else profile.Tints[(pair % #profile.Tints) + 1]
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
	-- drift (nature), outward (bloom, GAIA) and the laurel's loose leaves: out
	-- from the words' end and a little down, turning, fading in and out.
	local u = cycle(profile.Seconds, t, i, n)
	local size = (if motion == "laurel" then profile.LeafSize else profile.Size) * k
	-- Its inner edge 2 px clear of the words: a petal started inside the last
	-- letter read as part of it on a pink title (seen in Play, 2026-10-10).
	local start = half + size / 2 + 2 * k
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

--==============================================================================
-- THE GLINT AND THE TWINKLES
--==============================================================================
-- Where the glint's band is at time t: the UIGradient's Offset.X, -1 (off the
-- words' left) to 1 (off their right) through a Sweep every Every seconds;
-- nil while it rests.
function TitleFX.glint(t: number): number?
	local G = FX.Glint
	local phase = t - math.floor(t / G.Every) * G.Every
	if phase >= G.Sweep then
		return nil
	end
	return -1 + 2 * phase / G.Sweep
end

export type Twinkle = { x: number, y: number, size: number, rotation: number, frame: number }

-- Twinkle j at time t: where it pops on the words and which of the sheet's
-- frames shows; nil while it rests. Each pop lands somewhere new.
function TitleFX.twinkle(j: number, t: number, box: Vector2, words: number, centre: number?): Twinkle?
	local T = FX.Twinkle
	local period = T.Pop + T.Rest[1] + (T.Rest[2] - T.Rest[1]) * hash(j, 0)
	local at = t + hash(j, 1) * period
	local round = math.floor(at / period)
	local u = at - round * period
	if u >= T.Pop then
		return nil
	end
	local k = box.Y / TITLE.Size.Y
	local mid = centre or box.X / 2
	local half = words / 2
	local size = T.Size * k * (0.8 + 0.4 * hash(j, round + 9))
	-- On the words' line, anywhere along them and a little past their ends.
	local top, bottom = size / 2, box.Y * 0.6
	return {
		x = mid + (hash(j, round * 2 + 3) * 2 - 1) * (half + 2 * k),
		y = top + hash(j, round * 2 + 4) * math.max(0, bottom - top),
		size = size,
		rotation = hash(j, round + 11) * 90,
		frame = T.Frames[math.min(#T.Frames, 1 + math.floor(u / T.Pop * #T.Frames))],
	}
end

-- Whether a picture has arrived on this client (ContentProvider's fetch, which
-- a label never drawn still gets; see attach).
function TitleFX.fetched(id: string): boolean
	if id == "" then
		return false
	end
	local ok, status = pcall(function()
		return ContentProvider:GetAssetFetchStatus(id)
	end)
	return ok and status == Enum.AssetFetchStatus.Success
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
	-- Poses every sprite at time t (os.clock) and shows the layer; `fade`
	-- (0..1) takes that much more of each sprite away (a LOCKED row's).
	step: (t: number, fade: number?) -> (),
	-- Hides it: Reduced FX, too far, not among the nearest, the title hidden.
	hide: () -> (),
	destroy: () -> (),
	frame: Frame,
}

-- Beside a word in a list rather than over a head: the frame's place and size
-- in its parent's units (`box`, the word's line), its ZIndex (under the
-- word's), the word's drawn width and middle, measured when stepped, the
-- furthest left a sprite's middle may go in the frame (the row's own edge),
-- and the word's label (for the glint over it).
export type Place = {
	at: UDim2,
	box: Vector2,
	z: number,
	words: () -> number,
	centre: () -> number,
	left: number,
	label: TextLabel?,
}

function TitleFX.attach(gui: GuiObject | BillboardGui, profile: any, count: number, place: Place?): Layer
	-- A sprite out past the words' ends must not be cut at the box.
	pcall(function()
		(gui :: any).ClipsDescendants = false
	end)
	local function newFrame(name: string, z: number): Frame
		local f = Instance.new("Frame")
		f.Name = name
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		f.Active = false
		if place then
			f.Position = place.at
			f.Size = UDim2.fromOffset(place.box.X, place.box.Y)
		else
			f.Size = UDim2.fromScale(1, 1)
		end
		f.ZIndex = z
		f.Visible = false
		f.Parent = gui
		return f
	end
	local wordsFound = if place then place.label else gui:FindFirstChild("Words")
	local words: TextLabel? = if wordsFound and wordsFound:IsA("TextLabel") then wordsFound else nil
	-- Under the words and REBIRTH N (theirs is the default 1 over a head).
	local frame = newFrame("TitleFX", if place then place.z else 0)
	-- The twinkles stand over the words: a sparkle on the lettering.
	local wordsZ = if words then words.ZIndex else 1
	local over = newFrame("TitleTwinkles", wordsZ + 1)
	local made = os.clock()
	local function label(parent: Instance, name: string, z: number): ImageLabel
		local l = Instance.new("ImageLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.BorderSizePixel = 0
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.ScaleType = Enum.ScaleType.Fit
		l.ZIndex = z
		l.Active = false
		l.ImageTransparency = 1
		l.Parent = parent
		return l
	end
	local sprites: { ImageLabel } = {}
	for i = 1, count do
		local l = label(frame, "Sprite" .. i, frame.ZIndex)
		-- A sprite's picture never changes (its art is its index's), so it is
		-- set once, here, and fetched from now; clear until it has loaded.
		l.Image = FX.Art[TitleFX.pose(profile, i, count, 0, TITLE.Size, TITLE.Size.X / 2).art] or ""
		sprites[i] = l
	end
	local T = FX.Twinkle
	local twinkles: { ImageLabel } = {}
	for j = 1, (profile.Twinkles or T.Count) do
		local l = label(over, "Twinkle" .. j, over.ZIndex)
		l.Image = T.Art
		l.ImageRectSize = Vector2.new(T.Cell, T.Cell)
		twinkles[j] = l
	end
	-- THE GLINT: the words again, white, seen only through a band of a
	-- UIGradient that sweeps across them -- over the words, never their outline.
	local glint: TextLabel? = nil
	local glintFill: UIGradient? = nil
	if words then
		local g = Instance.new("TextLabel")
		g.Name = "TitleGlint"
		g.BackgroundTransparency = 1
		g.Size = UDim2.fromScale(1, 1)
		g.Font = words.Font
		g.Text = words.Text
		g.TextSize = words.TextSize
		g.TextScaled = words.TextScaled
		g.TextXAlignment = words.TextXAlignment
		g.TextYAlignment = words.TextYAlignment
		g.TextColor3 = WHITE
		g.ZIndex = wordsZ + 1
		g.Active = false
		g.Visible = false
		g.Parent = words
		local G = FX.Glint
		local fill = Instance.new("UIGradient")
		fill.Rotation = G.Rotation
		fill.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5 - G.Width, 1),
			NumberSequenceKeypoint.new(0.5, G.Strength),
			NumberSequenceKeypoint.new(0.5 + G.Width, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		fill.Parent = g
		glint, glintFill = g, fill
	end
	-- LOADED IS THE FETCH'S WORD, NOT ISLOADED (seen in Play, 2026-10-10): a
	-- label kept clear is never drawn, so its IsLoaded never turns true, and a
	-- sprite waiting on it waited for ever. So the pictures are fetched here,
	-- off the frame (PreloadAsync on the labels themselves), and a sprite shows
	-- once ContentProvider says its picture arrived; one that failed never does.
	task.spawn(function()
		local all: { Instance } = {}
		for _, l in ipairs(sprites) do
			table.insert(all, l)
		end
		for _, l in ipairs(twinkles) do
			table.insert(all, l)
		end
		pcall(function()
			ContentProvider:PreloadAsync(all)
		end)
	end)
	local shown = false
	local layer: Layer
	layer = {
		frame = frame,
		step = function(t: number, fade: number?)
			if not frame.Parent then
				return
			end
			local box: Vector2
			local width: number
			local centre: number? = nil
			if place then
				box = place.box
				width = place.words()
				centre = place.centre()
			else
				box = (gui :: GuiObject).AbsoluteSize
				if box.X <= 0 or box.Y <= 0 then
					local size = (gui :: GuiObject).Size
					box = Vector2.new(size.X.Offset, size.Y.Offset)
				end
				width = if words and words.TextBounds.X > 0 then words.TextBounds.X else box.X * 0.6
			end
			local away = math.clamp(fade or 0, 0, 1)
			local settled = os.clock() - made >= FX.SettleSeconds
			for i, l in ipairs(sprites) do
				local pose = TitleFX.pose(profile, i, count, t, box, width, centre)
				if l.ImageColor3 ~= pose.tint then
					l.ImageColor3 = pose.tint
				end
				local x = if place then math.max(pose.x, place.left + pose.size / 2) else pose.x
				l.Position = UDim2.fromOffset(x, pose.y)
				l.Size = UDim2.fromOffset(pose.size, pose.size)
				l.Rotation = pose.rotation
				-- A picture that never loads stays clear: the words alone.
				l.ImageTransparency = if settled and TitleFX.fetched(l.Image)
					then pose.transparency + (1 - pose.transparency) * away
					else 1
			end
			local sparkleReady = settled and TitleFX.fetched(T.Art)
			for j, l in ipairs(twinkles) do
				local tw = if sparkleReady then TitleFX.twinkle(j, t, box, width, centre) else nil
				if tw then
					local cell = tw.frame - 1
					l.ImageRectOffset = Vector2.new((cell % 2) * T.Cell, (cell // 2) * T.Cell)
					l.Position = UDim2.fromOffset(tw.x, tw.y)
					l.Size = UDim2.fromOffset(tw.size, tw.size)
					l.Rotation = tw.rotation
					l.ImageColor3 = if profile.Rainbow then hue(j, #twinkles, t) else profile.Tints[1]:Lerp(WHITE, 0.55)
					l.ImageTransparency = away
				else
					l.ImageTransparency = 1
				end
			end
			local g, fill = glint, glintFill
			if g and fill and words then
				local offset = TitleFX.glint(t)
				if g.Text ~= words.Text then
					g.Text = words.Text
				end
				if g.TextSize ~= words.TextSize then
					g.TextSize = words.TextSize
				end
				g.Visible = offset ~= nil
				if offset then
					fill.Offset = Vector2.new(offset, 0)
					g.TextTransparency = away
				end
			end
			if not shown then
				shown = true
				frame.Visible = true
				over.Visible = true
			end
		end,
		hide = function()
			if shown then
				shown = false
				frame.Visible = false
				over.Visible = false
			end
			if glint then
				glint.Visible = false
			end
		end,
		destroy = function()
			frame:Destroy()
			over:Destroy()
			if glint then
				glint:Destroy()
			end
			table.clear(sprites)
			table.clear(twinkles)
		end,
	}
	return layer
end

return TitleFX
