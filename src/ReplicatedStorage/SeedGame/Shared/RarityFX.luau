--!strict
--==============================================================================
-- Steal a Seed :: RarityFX (2026-10-03, the owner's inventory pass)
--
-- HOW THE THREE RAREST READ IN THE BAG AND ON THE STRIP: Mythic, Divine and
-- Secret, by the ids GameConfig.Rarities already has. Since 2026-10-10 the
-- other five have a STILL edge from here too (THE OTHER FIVE, below), on a
-- grown plant's card only. Anything whose rarity is not yet the player's to
-- know (a sealed pod) gets nothing from here and keeps its plain look.
--
--   text   the rarity WORD: its colours through a UIGradient on the label, a
--          slow light crossing it; Secret's is the toast's silver italic with
--          a light keyline. Item names are never handed in.
--   edge   a frame laid exactly on a card's border with its own thin stroke: a
--          small light that travels round the card (the stroke's UIGradient
--          turns, its transparency lit only near one end). The card's own
--          stroke carries the rarity's colour at rest -- that is the caller's.
--
-- ONE CLOCK, AND IT IS NOT THIS FILE'S. Nothing here connects to anything or
-- loops: `step` is called by the strip's existing cooldown tick (LoadoutUI),
-- at most every StepSeconds, and moves only the handles that are RUNNING --
-- switched on by their owner (on screen, Bag open), animated (a style, motion
-- allowed) and, where a gate is given, under a visible gate. Each step writes
-- one number or one shared Vector2 per handle: nothing is built per frame.
--
-- REDUCED MOTION (StatusText.reducedMotion: the game's REDUCED FX or Roblox's
-- own setting) draws the same colours still -- the word a two-tone, the edge
-- its colour and no light -- and nothing runs.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))

local RarityFX = {}

local FX: any = GameConfig.RarityFX
local WHITE = Color3.fromRGB(255, 255, 255)
local ZERO = Vector2.new(0, 0)

export type Style = {
	id: string,
	text: ColorSequence,
	still: ColorSequence,
	outline: Color3,
	outlineTransparency: number,
	halo: boolean,
	italic: boolean,
	edge: Color3,
	glint: ColorSequence,
	glintFade: NumberSequence,
}

export type Handle = {
	kind: string, -- "text" | "edge"
	gradient: UIGradient,
	rarity: string?,
	on: boolean,
	animated: boolean,
	gate: GuiObject?,
	-- text
	label: TextLabel?,
	keyline: UIStroke?,
	halo: TextLabel?,
	plainFont: Font?,
	plainKeyline: Color3?,
	plainKeylineTransparency: number?,
	-- edge
	frame: Frame?,
	stroke: UIStroke?,
	corner: UICorner?,
}

--==============================================================================
-- THE STYLES, built once
--==============================================================================
local styles: { [string]: Style } = {}

local function key(t: number, c: Color3): ColorSequenceKeypoint
	return ColorSequenceKeypoint.new(t, c)
end

for _, id in ipairs({ "Mythic", "Divine", "Secret" }) do
	local s = FX[id]
	if s then
		-- The word at rest is `Text`; a light crosses it. Secret's light has a
		-- band of its own in front of it (its `Dark`: silver on black letters).
		local text = if s.Dark
			then ColorSequence.new({
				key(0, s.Text), key(0.36, s.Text), key(0.44, s.Dark), key(0.5, s.Glow),
				key(0.58, s.Text), key(1, s.Text),
			})
			else ColorSequence.new({
				key(0, s.Text), key(0.4, s.Text), key(0.5, s.Glow), key(0.6, s.Text), key(1, s.Text),
			})
		-- The edge's light: bright at the head, its tail behind, fading out by
		-- GlintSpan of the card; the rest of the overlay is clear.
		local span = FX.GlintSpan
		local glint = ColorSequence.new({
			key(0, s.Glint), key(span * 0.45, s.Tail), key(math.min(1, span * 1.2), s.Edge), key(1, s.Edge),
		})
		local glintFade = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(span * 0.5, 0.15),
			NumberSequenceKeypoint.new(span, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		styles[id] = {
			id = id,
			text = text,
			still = ColorSequence.new(s.StillTop, s.StillBottom),
			outline = s.Outline,
			outlineTransparency = s.OutlineTransparency or 0,
			halo = s.Halo == true,
			italic = s.Italic == true,
			edge = s.Edge,
			glint = glint,
			glintFade = glintFade,
		}
	end
end

-- The style for a rarity id, or nil: only the three, and only by their ids
-- ("Mythic", never "Mythical").
function RarityFX.style(rarity: string?): Style?
	return if rarity then styles[rarity] else nil
end

-- The card edge's colour at rest for a rarity, or nil for every other one.
function RarityFX.edgeColour(rarity: string?): Color3?
	local s = RarityFX.style(rarity)
	return if s then s.edge else nil
end

function RarityFX.still(): boolean
	return StatusText.reducedMotion()
end

--==============================================================================
-- RUNNING: switched on by the owner AND animated
--==============================================================================
local running: { [Handle]: boolean } = {}
-- Every handle alive, weakly, so a change of motion setting can be redrawn.
local all: { [Handle]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function reconsider(h: Handle)
	if h.on and h.animated then
		running[h] = true
	else
		running[h] = nil
	end
end

-- On screen and wanted (the Bag open and the tile in view; a slot shown).
function RarityFX.setActive(h: Handle, on: boolean)
	if h.on ~= on then
		h.on = on
		reconsider(h)
	end
end

-- A handle whose label or frame is going away for good.
function RarityFX.forget(h: Handle)
	running[h] = nil
	all[h] = nil
	h.on = false
end

function RarityFX.isRunning(h: Handle): boolean
	return running[h] == true
end

--==============================================================================
-- THE WORD
--==============================================================================
-- `keyline` the label's own outline, if it has one: Secret lightens it.
function RarityFX.text(label: TextLabel, keyline: UIStroke?): Handle
	local gradient = Instance.new("UIGradient")
	gradient.Name = "RarityLight"
	gradient.Enabled = false
	gradient.Parent = label
	local h: Handle = {
		kind = "text",
		gradient = gradient,
		rarity = nil,
		on = false,
		animated = false,
		gate = nil,
		label = label,
		keyline = keyline,
		plainFont = label.FontFace,
		plainKeyline = if keyline then keyline.Color else nil,
		plainKeylineTransparency = if keyline then keyline.Transparency else nil,
	}
	all[h] = true
	return h
end

-- The light keyline of a style that must not take the gradient (Secret's): a
-- twin of the word, one layer BEHIND it, as its child -- a parent's UIGradient
-- never reaches a child -- whose fill the word covers exactly and whose stroke
-- shows round it. Built the first time it is needed, then kept in step.
local function haloOf(h: Handle, label: TextLabel, style: Style): TextLabel
	local halo = h.halo
	if not halo then
		local made = Instance.new("TextLabel")
		made.Name = "RarityHalo"
		made.BackgroundTransparency = 1
		made.Size = UDim2.fromScale(1, 1)
		made.Active = false
		local edge = Instance.new("UIStroke")
		edge.LineJoinMode = Enum.LineJoinMode.Round
		edge.Thickness = 1.25
		edge.Parent = made
		made.Parent = label
		h.halo = made
		halo = made
	end
	local twin = halo :: TextLabel
	twin.Text = label.Text
	twin.FontFace = label.FontFace
	twin.TextSize = label.TextSize
	twin.TextScaled = label.TextScaled
	twin.TextWrapped = label.TextWrapped
	twin.TextTruncate = label.TextTruncate
	twin.TextXAlignment = label.TextXAlignment
	twin.TextYAlignment = label.TextYAlignment
	twin.TextColor3 = style.outline
	twin.ZIndex = math.max(1, label.ZIndex - 1)
	local edge = twin:FindFirstChildOfClass("UIStroke")
	if edge then
		edge.Color = style.outline
	end
	twin.Visible = true
	return twin
end

-- `rarity` nil (or a rarity with no style) puts the label back to plain, in
-- `plain` colour. Otherwise the label is white under its gradient.
function RarityFX.setText(h: Handle, rarity: string?, plain: Color3)
	local label = h.label :: TextLabel
	local s = RarityFX.style(rarity)
	h.rarity = if s then rarity else nil
	local keyline = h.keyline
	local halo = h.halo
	if halo and not (s and (s :: Style).halo) then
		halo.Visible = false
	end
	if not s then
		h.gradient.Enabled = false
		label.TextColor3 = plain
		if h.plainFont then
			label.FontFace = h.plainFont :: Font
		end
		if keyline then
			keyline.Color = h.plainKeyline or keyline.Color
			keyline.Transparency = h.plainKeylineTransparency or keyline.Transparency
		end
		h.animated = false
		reconsider(h)
		return
	end
	local style = s :: Style
	local still = RarityFX.still()
	label.TextColor3 = WHITE
	h.gradient.Enabled = true
	h.gradient.Color = if still then style.still else style.text
	h.gradient.Rotation = if still then 90 else 0
	h.gradient.Offset = ZERO
	if keyline then
		keyline.Color = style.outline
		-- A halo style's keyline is the twin's: the word's own would be tinted.
		keyline.Transparency = if style.halo then 1 else style.outlineTransparency
	end
	local font = h.plainFont
	if style.italic and font then
		label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy,
			Enum.FontStyle.Italic)
	elseif font then
		label.FontFace = font
	end
	if style.halo then
		haloOf(h, label, style)
	end
	h.animated = not still
	reconsider(h)
end

--==============================================================================
-- THE EDGE
--==============================================================================
-- An overlay on `button`'s border, at `zIndex`, with `radius` corners.
function RarityFX.edge(button: GuiObject, radius: number, zIndex: number): Handle
	local frame = Instance.new("Frame")
	frame.Name = "RarityEdge"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Visible = false
	frame.ZIndex = zIndex
	frame.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = FX.GlintThickness
	stroke.Color = WHITE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = frame
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Glint"
	gradient.Parent = stroke
	local h: Handle = {
		kind = "edge",
		gradient = gradient,
		rarity = nil,
		on = false,
		animated = false,
		gate = nil,
		frame = frame,
		stroke = stroke,
		corner = corner,
	}
	all[h] = true
	return h
end

function RarityFX.setRadius(h: Handle, radius: number)
	local corner = h.corner
	if corner then
		corner.CornerRadius = UDim.new(0, radius)
	end
end

-- `glint` false hides the travelling light (a state outranks it: in hand, a
-- target, a pending equip, a flash, restoring). Under reduced motion it never
-- shows: the card's own edge carries the colour, still.
function RarityFX.setEdge(h: Handle, rarity: string?, glint: boolean)
	local frame = h.frame :: Frame
	local s = RarityFX.style(rarity)
	h.rarity = if s then rarity else nil
	local show = s ~= nil and glint and not RarityFX.still()
	if s and show then
		local style = s :: Style
		h.gradient.Color = style.glint
		h.gradient.Transparency = style.glintFade
	end
	frame.Visible = show
	h.animated = show
	reconsider(h)
end

--==============================================================================
-- THE OTHER FIVE: A STILL EDGE (2026-10-10, the owner: "yes, add rarity edges")
--
-- Common to Legendary, on a GROWN plant's card only (GameConfig.RarityEdge):
-- the colour alone, never a light, so nothing here runs or steps. On the strip
-- it is the slot's own edge (HotbarCard); on a Bag tile and an Almanac card,
-- whose keyline stays, a band just inside it -- the ring below.
--==============================================================================
local EDGE: any = GameConfig.RarityEdge

-- A Common-to-Legendary rarity's still edge colour, or nil: the three rarest
-- have their own (edgeColour), and anything else has none.
function RarityFX.stillEdge(rarity: string?): Color3?
	return if rarity then EDGE.Colours[rarity] else nil
end

-- A band `thickness` px wide just inside `button`'s border, under its own
-- stroke (the keyline), at `zIndex`, following a `radius` corner. Hidden until
-- setRing gives it a colour. Its own stroke draws outside it, so the frame
-- stands `thickness` in from every side.
function RarityFX.ring(button: GuiObject, radius: number, zIndex: number, thickness: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = "RarityRing"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(1, -thickness * 2, 1, -thickness * 2)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Visible = false
	frame.ZIndex = zIndex
	frame.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, math.max(0, radius - thickness))
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = thickness
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Color = WHITE
	stroke.Parent = frame
	return frame
end

-- The ring in `colour`, or hidden for nil.
function RarityFX.setRing(ring: Frame, colour: Color3?)
	local stroke = ring:FindFirstChildOfClass("UIStroke")
	if colour and stroke then
		stroke.Color = colour
	end
	ring.Visible = colour ~= nil
end

--==============================================================================
-- THE STEP
--==============================================================================
local lastStep = -math.huge

-- Every handle alive drawn again for the current motion setting.
local function redrawAll()
	for h in pairs(all) do
		if h.kind == "text" and h.label then
			local label = h.label :: TextLabel
			RarityFX.setText(h, h.rarity, label.TextColor3)
		elseif h.kind == "edge" then
			RarityFX.setEdge(h, h.rarity, h.animated)
		end
	end
end

function RarityFX.step(now: number)
	if next(running) == nil or now - lastStep < FX.StepSeconds then
		return
	end
	lastStep = now
	-- Motion turned off while something runs: everything goes still, now.
	if RarityFX.still() then
		redrawAll()
		return
	end
	local phase = (now % FX.CycleSeconds) / FX.CycleSeconds
	local turn = phase * 360
	-- The word's light crosses from beyond the left edge to beyond the right,
	-- so it is over the letters for part of the cycle and the word rests.
	local sweep = Vector2.new(-1 + 2 * phase, 0)
	for h in pairs(running) do
		if h.gradient.Parent == nil then
			running[h] = nil
		else
			local gate = h.gate
			if gate == nil or gate.Visible then
				if h.kind == "edge" then
					h.gradient.Rotation = turn
				else
					h.gradient.Offset = sweep
				end
			end
		end
	end
end

-- How many handles a step would move (the specs' count).
function RarityFX.runningCount(): number
	local n = 0
	for _ in pairs(running) do
		n += 1
	end
	return n
end

return RarityFX
