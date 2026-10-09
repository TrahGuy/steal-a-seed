--!strict
--==============================================================================
-- Steal a Seed :: RewardSplash (2026-10-01, the owner's ask)
--
-- A reward the player has just been given, made obvious: a brief card a little
-- above the middle of the screen with each reward's icon, name and amount, then
-- each icon flies to the thing on the HUD that now shows that reward, and the
-- card fades.
--
--   * ONLY WHAT THE SERVER CONFIRMED. The caller plays it from a granted
--     reward and from nothing else; this only draws what it is handed.
--   * A GROUP stands side by side, compact, and every icon goes to its own
--     destination -- asked when the flight starts and again on every frame of
--     it, so a row still settling or a phone's column is followed, not guessed.
--   * NOWHERE TO GO: no visible destination, or one that goes away mid-flight,
--     and the icon fades where it is.
--   * REDUCED MOTION (the caller passes StatusText.reducedMotion()): the card
--     fades in, holds a little longer, and fades out. No pop, no flight.
--
-- Sized for the screen it is on (scaleFor), and never wider than most of it.
-- One RenderStepped connection while it plays, dropped at the end: nothing runs
-- between splashes. A new splash ends the one before it at once.
--==============================================================================

local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local RewardSplash = {}

export type Item = {
	-- Builds the reward's icon into `parent` (a `px`-square box), centred.
	draw: (parent: Frame, px: number) -> (),
	-- The reward's name with its amount ("+25% PLANT INCOME"), and an optional
	-- smaller line under it ("BOOST FOR 2 MIN").
	title: string,
	detail: string?,
	tint: Color3,
	-- Where it lands; nil when nothing suitable is on screen.
	destination: () -> GuiObject?,
	-- Called once as it lands (a nudge on the destination).
	landed: (() -> ())?,
}

export type Options = {
	-- The ScreenGui it draws in -- ideally the destinations' own, so the flight
	-- and the HUD share one space.
	layer: LayerCollector,
	heading: string?,
	items: { Item },
	reduced: boolean,
	zIndex: number?,
}

RewardSplash.EnterSeconds = 0.22
RewardSplash.HoldSeconds = 1.5
RewardSplash.StillHoldSeconds = 2.6
RewardSplash.FlySeconds = 0.6
RewardSplash.FadeSeconds = 0.3
RewardSplash.LandFadeSeconds = 0.12
-- At the desktop size; scaleFor sizes it for the screen.
RewardSplash.IconPx = 64
RewardSplash.TitleSize = 28
RewardSplash.DetailSize = 17
RewardSplash.HeadingSize = 16
RewardSplash.Pad = 16
RewardSplash.Gap = 26
-- The card's middle, as a share of the screen's height.
RewardSplash.CentreY = 0.42
-- Never wider than this share of the screen.
RewardSplash.MaxWidthShare = 0.92

RewardSplash.TitleFont = Enum.Font.LuckiestGuy
RewardSplash.DetailFont = Enum.Font.GothamBold
RewardSplash.Outline = Color3.fromRGB(34, 24, 16)
RewardSplash.Gold = Color3.fromRGB(255, 211, 77)
RewardSplash.Cream = Color3.fromRGB(242, 238, 206)

--==============================================================================
-- THE NUMBERS (pure: RewardSplashSpec checks them)
--==============================================================================
-- 1 at a 720-tall window, a phone's smaller, a big monitor's a little larger.
function RewardSplash.scaleFor(view: Vector2): number
	local short = math.min(view.X, view.Y)
	return math.clamp(short / 720, 0.62, 1.15)
end

-- A point on the flight at t in [0, 1]: eased in and out, lifted in a low arc
-- that peaks half-way, and how far along it is (0..1) for the shrink.
function RewardSplash.flight(from: Vector2, to: Vector2, t: number): (Vector2, number)
	local u = math.clamp(t, 0, 1)
	local e = u * u * (3 - 2 * u)
	local lift = math.sin(u * math.pi) * math.min(60, (to - from).Magnitude * 0.18)
	return from:Lerp(to, e) - Vector2.new(0, lift), e
end

-- The middle of `obj` in `layer`'s own space; nil unless it is on screen: shown
-- all the way up, in an enabled gui, with a size, inside the layer.
function RewardSplash.pointIn(obj: GuiObject?, layer: LayerCollector): Vector2?
	if obj == nil or obj.Parent == nil then
		return nil
	end
	local node: Instance? = obj
	while node and node:IsA("GuiObject") do
		if not node.Visible then
			return nil
		end
		node = node.Parent
	end
	local gui = obj:FindFirstAncestorWhichIsA("LayerCollector")
	if gui == nil or not gui.Enabled then
		return nil
	end
	local size = obj.AbsoluteSize
	if size.X < 1 or size.Y < 1 then
		return nil
	end
	local at = obj.AbsolutePosition + size / 2 - layer.AbsolutePosition
	local box = layer.AbsoluteSize
	if at.X < 0 or at.Y < 0 or at.X > box.X or at.Y > box.Y then
		return nil
	end
	return at
end

--==============================================================================
-- FADING A WHOLE PIECE: every transparency it has, from its resting value
--==============================================================================
type Fade = { target: Instance, prop: string, base: number }

local function collect(root: Instance, into: { Fade })
	local function add(target: Instance, prop: string)
		table.insert(into, { target = target, prop = prop, base = (target :: any)[prop] })
	end
	local all = root:GetDescendants()
	table.insert(all, root)
	for _, d in ipairs(all) do
		if d:IsA("TextLabel") then
			add(d, "TextTransparency")
			add(d, "BackgroundTransparency")
		elseif d:IsA("ImageLabel") then
			add(d, "ImageTransparency")
			add(d, "BackgroundTransparency")
		elseif d:IsA("Frame") then
			add(d, "BackgroundTransparency")
		elseif d:IsA("UIStroke") then
			add(d, "Transparency")
		end
	end
end

-- a = 0 as drawn, a = 1 gone.
local function apply(list: { Fade }, a: number)
	local k = math.clamp(a, 0, 1)
	for _, f in ipairs(list) do
		(f.target :: any)[f.prop] = f.base + (1 - f.base) * k
	end
end

local function textWidth(text: string, size: number, font: Enum.Font): number
	if text == "" then
		return 0
	end
	return TextService:GetTextSize(text, size, font, Vector2.new(4000, 400)).X
end

local function label(parent: Instance, name: string, text: string, size: number, font: Enum.Font, colour: Color3,
	y: number, h: number, outline: number, z: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = UDim2.new(0, 0, 0, y)
	l.Size = UDim2.new(1, 0, 0, h)
	l.Font = font
	l.TextSize = size
	l.Text = text
	l.TextColor3 = colour
	l.ZIndex = z
	l.Parent = parent
	local edge = Instance.new("UIStroke")
	edge.Color = RewardSplash.Outline
	edge.Thickness = outline
	edge.Parent = l
	return l
end

--==============================================================================
-- THE CARD
--==============================================================================
export type Piece = {
	item: Item,
	holder: Frame,
	holderScale: UIScale,
	fades: { Fade },
}

export type Built = {
	card: Frame,
	scale: UIScale,
	k: number,
	pieces: { Piece },
	fades: { Fade },
}

function RewardSplash.build(opts: Options): Built?
	local layer = opts.layer
	local view = layer.AbsoluteSize
	if #opts.items == 0 or view.X < 1 or view.Y < 1 then
		return nil
	end
	local S = RewardSplash
	local z = opts.zIndex or 40

	-- Each reward a column: icon, name, amount; as wide as its words need.
	local widths: { number } = {}
	local total = S.Pad * 2
	for i, item in ipairs(opts.items) do
		local w = math.max(S.IconPx + 24, textWidth(item.title, S.TitleSize, S.TitleFont) + 14,
			textWidth(item.detail or "", S.DetailSize, S.DetailFont) + 14)
		widths[i] = math.ceil(w)
		total += widths[i] + (if i > 1 then S.Gap else 0)
	end
	local headH = if opts.heading then S.HeadingSize + 8 else 0
	local hasDetail = false
	for _, item in ipairs(opts.items) do
		if item.detail then
			hasDetail = true
		end
	end
	local columnH = S.IconPx + 6 + S.TitleSize + 4 + (if hasDetail then S.DetailSize + 4 else 0)
	local height = S.Pad * 2 + headH + columnH
	local k = math.min(S.scaleFor(view), view.X * S.MaxWidthShare / total)

	-- TRANSPARENT (2026-10-09, the owner: "everything must be transparent,
	-- applies to buffs, and effects", and yes for this card): no plate, corner
	-- or rim behind the rewards -- the icons and the outlined words carry it,
	-- the way the floating signs read over any scene.
	local card = Instance.new("Frame")
	card.Name = "RewardSplash"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, S.CentreY)
	card.Size = UDim2.fromOffset(total, height)
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.Active = false
	card.ZIndex = z
	local scale = Instance.new("UIScale")
	scale.Scale = k
	scale.Parent = card

	-- Outlines a little heavier than they were on the plate: the only thing
	-- between a word and the scene now.
	if opts.heading then
		label(card, "Heading", opts.heading, S.HeadingSize, S.TitleFont, S.Gold, S.Pad - 2, S.HeadingSize + 4, 2, z + 1)
	end

	local pieces: { Piece } = {}
	local x = S.Pad
	for i, item in ipairs(opts.items) do
		local column = Instance.new("Frame")
		column.Name = "Reward" .. i
		column.BackgroundTransparency = 1
		column.Position = UDim2.fromOffset(x, S.Pad + headH)
		column.Size = UDim2.fromOffset(widths[i], columnH)
		column.ZIndex = z + 1
		column.Parent = card
		x += widths[i] + S.Gap

		local holder = Instance.new("Frame")
		holder.Name = "Icon"
		holder.AnchorPoint = Vector2.new(0.5, 0)
		holder.Position = UDim2.new(0.5, 0, 0, 0)
		holder.Size = UDim2.fromOffset(S.IconPx, S.IconPx)
		holder.BackgroundTransparency = 1
		holder.ZIndex = z + 2
		holder.Parent = column
		local holderScale = Instance.new("UIScale")
		holderScale.Parent = holder
		item.draw(holder, S.IconPx)
		-- Above the card whatever the gui's ZIndexBehavior, in the icon's own order.
		for _, d in ipairs(holder:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.ZIndex += z + 2
			end
		end

		label(column, "Title", item.title, S.TitleSize, S.TitleFont, item.tint, S.IconPx + 6, S.TitleSize + 4, 2.5,
			z + 1)
		if item.detail then
			label(column, "Detail", item.detail, S.DetailSize, S.DetailFont, S.Cream,
				S.IconPx + 6 + S.TitleSize + 4, S.DetailSize + 4, 2, z + 1)
		end
		local fades: { Fade } = {}
		collect(holder, fades)
		table.insert(pieces, { item = item, holder = holder, holderScale = holderScale, fades = fades })
	end

	-- The card's own fades leave the icons out: they fade on their own, or fly.
	local fades: { Fade } = {}
	local all = card:GetDescendants()
	table.insert(all, card)
	local inIcon: { [Instance]: boolean } = {}
	for _, piece in ipairs(pieces) do
		inIcon[piece.holder] = true
		for _, d in ipairs(piece.holder:GetDescendants()) do
			inIcon[d] = true
		end
	end
	for _, d in ipairs(all) do
		if not inIcon[d] then
			if d:IsA("TextLabel") then
				table.insert(fades, { target = d, prop = "TextTransparency", base = d.TextTransparency })
			elseif d:IsA("Frame") then
				table.insert(fades, { target = d, prop = "BackgroundTransparency", base = d.BackgroundTransparency })
			elseif d:IsA("UIStroke") then
				table.insert(fades, { target = d, prop = "Transparency", base = d.Transparency })
			end
		end
	end

	card.Parent = layer
	return { card = card, scale = scale, k = k, pieces = pieces, fades = fades }
end

--==============================================================================
-- PLAYING IT
--==============================================================================
local stopCurrent: (() -> ())? = nil

-- Ends the splash on screen now, if there is one.
function RewardSplash.stop()
	local stop = stopCurrent
	if stop then
		stop()
	end
end

-- Draws and plays it; false when there was nothing to draw (the caller then
-- says it another way).
function RewardSplash.play(opts: Options): boolean
	RewardSplash.stop()
	local built = RewardSplash.build(opts)
	if not built then
		return false
	end
	local S = RewardSplash
	local layer = opts.layer
	local card, k = built.card, built.k
	local zFly = (opts.zIndex or 40) + 3

	type Flyer = { piece: Piece, from: Vector2, endScale: number, lostAt: number?, landed: boolean, done: boolean }
	local flyers: { Flyer } = {}
	local staying: { Piece } = {}
	local launched = false
	local started = os.clock()
	local connection: RBXScriptConnection? = nil

	local function finish()
		local c = connection
		if c then
			c:Disconnect()
		end
		connection = nil
		card:Destroy()
		for _, f in ipairs(flyers) do
			f.piece.holder:Destroy()
		end
		if stopCurrent == finish then
			stopCurrent = nil
		end
	end
	stopCurrent = finish

	local function everything(a: number)
		apply(built.fades, a)
		for _, piece in ipairs(built.pieces) do
			apply(piece.fades, a)
		end
	end

	local function launch()
		for _, piece in ipairs(built.pieces) do
			local ok, dest = pcall(piece.item.destination)
			local target = if ok then RewardSplash.pointIn(dest, layer) else nil
			if target and dest then
				local holder = piece.holder
				local from = holder.AbsolutePosition + holder.AbsoluteSize / 2 - layer.AbsolutePosition
				holder.AnchorPoint = Vector2.new(0.5, 0.5)
				holder.Position = UDim2.fromOffset(from.X, from.Y)
				holder.ZIndex = zFly
				piece.holderScale.Scale = k
				holder.Parent = layer
				table.insert(flyers, {
					piece = piece,
					from = from,
					endScale = math.max(dest.AbsoluteSize.Y, 12) / S.IconPx,
					landed = false,
					done = false,
				})
			else
				table.insert(staying, piece)
			end
		end
	end

	local function step(f: Flyer, since: number)
		if f.done then
			return
		end
		local holder = f.piece.holder
		local ok, dest = pcall(f.piece.item.destination)
		local target = if ok then RewardSplash.pointIn(dest, layer) else nil
		if not target or f.lostAt then
			-- Nowhere to go any more: it fades where it is.
			f.lostAt = f.lostAt or since
			local a = (since - (f.lostAt :: number)) / S.FadeSeconds
			apply(f.piece.fades, a)
			if a >= 1 then
				f.done = true
				holder.Visible = false
			end
			return
		end
		local p, e = RewardSplash.flight(f.from, target :: Vector2, since / S.FlySeconds)
		holder.Position = UDim2.fromOffset(p.X, p.Y)
		f.piece.holderScale.Scale = k + (f.endScale - k) * e
		if since >= S.FlySeconds then
			if not f.landed then
				f.landed = true
				local landed = f.piece.item.landed
				if landed then
					pcall(landed)
				end
			end
			local a = (since - S.FlySeconds) / S.LandFadeSeconds
			apply(f.piece.fades, a)
			if a >= 1 then
				f.done = true
				holder.Visible = false
			end
		end
	end

	everything(1)
	connection = RunService.RenderStepped:Connect(function()
		if not card.Parent or not layer.Parent then
			finish()
			return
		end
		local t = os.clock() - started
		local E = S.EnterSeconds
		if opts.reduced then
			-- Still: in, hold, out. Nothing moves.
			local H, F = S.StillHoldSeconds, S.FadeSeconds
			if t < E then
				everything(1 - t / E)
			elseif t < E + H then
				everything(0)
			elseif t < E + H + F then
				everything((t - E - H) / F)
			else
				finish()
			end
			return
		end
		if t < E then
			local u = t / E
			local e = 1 - (1 - u) ^ 3
			built.scale.Scale = k * (0.8 + 0.2 * e)
			everything(1 - e)
			return
		end
		built.scale.Scale = k
		local flyAt = E + S.HoldSeconds
		if t < flyAt then
			everything(0)
			return
		end
		if not launched then
			launched = true
			launch()
		end
		local since = t - flyAt
		local a = since / S.FadeSeconds
		apply(built.fades, a)
		for _, piece in ipairs(staying) do
			apply(piece.fades, a)
		end
		local allDone = a >= 1
		for _, f in ipairs(flyers) do
			step(f, since)
			allDone = allDone and f.done
		end
		if allDone then
			finish()
		end
	end)
	return true
end

return RewardSplash
