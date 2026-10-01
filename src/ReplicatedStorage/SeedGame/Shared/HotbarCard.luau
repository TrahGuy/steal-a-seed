--!strict
--==============================================================================
-- Steal a Seed :: HotbarCard (2026-10-01, the owner's hotbar rework)
--
-- HOW ONE HOTBAR SLOT IS DRAWN, to the owner's reference: a nearly square slot
-- on a translucent charcoal plate with small rounded corners and a thin
-- light-grey edge; the item large in the middle; a small white number in the
-- top-left corner, plain text; no tray, no shadow, no name on the slot.
-- Everything is a number in GameConfig.Hotbar (`H` below), the compact belt
-- laid over it on a phone.
--
-- The slot's look lives here, out of LoadoutUI, which is rationed to Luau's
-- 200 top-level locals. LoadoutUI builds a card per slot, wires its presses,
-- and paints it from what the slot shows; nothing here listens to anything.
--
--   build     the instances, once per slot
--   restyle   the sizes again, on a change of face
--   paint     the state: empty or not, held or not, the number, a stack count,
--             a rarity accent, the hidden name
--   lift      the in-hand lift (none under reduced motion)
--   bump      a brief pop on equip or arrival (none under reduced motion)
--   flash     the edge takes a colour for a third of a second
--
-- STATES, from quietest to loudest:
--   empty     plate and edge nearly gone, the number faint: the key is there,
--             nothing is in it
--   plain     the plate, the edge, a white number
--   hover     a brighter edge (UIKit.cardPop drives it)
--   held      the warm amber-to-green edge, a lighter plate, an amber number,
--             a small lift
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local UIKit = require(Shared:WaitForChild("UIKit"))

local HotbarCard = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

export type Card = {
	holder: Frame,
	wrap: Frame,
	button: TextButton,
	stroke: UIStroke,
	ringTint: UIGradient,
	rimStroke: UIStroke,
	cooldown: Frame,
	preview: UIKit.ItemPreview,
	number: TextLabel,
	numberEdge: UIStroke,
	stack: TextLabel,
	accent: Frame,
	-- Hidden: carries the Tool's whole name, which TutorialUI's pointer reads.
	name: TextLabel,
	pop: UIKit.CardPop,
	bumpScale: UIScale,
	faceCorner: UICorner,
	rimCorner: UICorner,
	coolCorner: UICorner,
	-- What the paint last drew, so a redraw changes only what changed.
	lit: boolean,
	liftGoal: number,
	liftTween: Tween?,
	bumpTween: Tween?,
	-- os.clock() until which a flash owns the edge.
	flashUntil: number,
}

export type Paint = {
	empty: boolean,
	held: boolean,
	number: string,
	stack: string?,
	accent: Color3?,
	name: string,
}

function HotbarCard.build(parent: Instance, index: number, H: any, zIndex: number): Card
	--==========================================================================
	-- THREE LAYERS, SO NOTHING THAT MOVES MOVES ITS NEIGHBOURS
	--
	--   holder   the list's cell: a fixed size, laid out
	--   wrap     centred in it, carrying the in-hand lift and the bump
	--   button   the plate, carrying the hover lift and the hover and press scale
	--==========================================================================
	local holder = Instance.new("Frame")
	holder.Name = "Slot" .. index
	holder.LayoutOrder = index
	holder.Size = UDim2.fromOffset(H.SlotWidth, H.SlotHeight)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = zIndex
	holder.Parent = parent

	local wrap = Instance.new("Frame")
	wrap.Name = "Wrap"
	wrap.AnchorPoint = Vector2.new(0.5, 0.5)
	wrap.Position = UDim2.fromScale(0.5, 0.5)
	wrap.Size = UDim2.fromScale(1, 1)
	wrap.BackgroundTransparency = 1
	wrap.BorderSizePixel = 0
	wrap.ZIndex = zIndex
	wrap.Parent = holder
	local bumpScale = Instance.new("UIScale")
	bumpScale.Parent = wrap

	local button = Instance.new("TextButton")
	button.Name = "Face"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.Size = UDim2.fromScale(1, 1)
	button.BackgroundColor3 = H.Plate
	button.BackgroundTransparency = H.PlateTransparency
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = zIndex + 1
	button.Parent = wrap
	local faceCorner = UIKit.corner(button, H.CardCorner)
	local stroke = UIKit.stroke(button, H.Edge, H.CardStroke, H.EdgeTransparency)

	-- The warm keyline is a gradient on the stroke: a held slot sets the stroke
	-- white and enables this; every other state disables it.
	local ringTint = Instance.new("UIGradient")
	ringTint.Color = ColorSequence.new(H.LitTop, H.LitBottom)
	ringTint.Rotation = 90
	ringTint.Enabled = false
	ringTint.Parent = stroke

	-- The hover edge, a hairline on its own inset frame: a GuiObject draws one
	-- UIStroke and the keyline owns it.
	local rim = Instance.new("Frame")
	rim.Name = "Rim"
	rim.AnchorPoint = Vector2.new(0.5, 0.5)
	rim.Position = UDim2.fromScale(0.5, 0.5)
	rim.Size = UDim2.new(1, -3, 1, -3)
	rim.BackgroundTransparency = 1
	rim.BorderSizePixel = 0
	rim.ZIndex = zIndex + 1
	rim.Parent = button
	local rimCorner = UIKit.corner(rim, math.max(1, H.CardCorner - 1.5))
	local rimStroke = UIKit.stroke(rim, H.Edge, 1, 1)

	-- The cooldown: a dark shade rising from the bottom, under the item.
	local cooldown = Instance.new("Frame")
	cooldown.Name = "Cooldown"
	cooldown.AnchorPoint = Vector2.new(0, 1)
	cooldown.Position = UDim2.fromScale(0, 1)
	cooldown.Size = UDim2.fromScale(1, 0)
	cooldown.BackgroundColor3 = BLACK
	cooldown.BackgroundTransparency = H.CooldownShade
	cooldown.BorderSizePixel = 0
	cooldown.ZIndex = zIndex + 2
	cooldown.Parent = button
	local coolCorner = UIKit.corner(cooldown, H.CardCorner)

	-- The preview: the real Tool, framed to fill the glass (UIKit.itemPreview).
	local preview = UIKit.itemPreview(button, {
		name = "Preview",
		size = UDim2.fromOffset(H.SlotWidth - H.PreviewInset * 2, H.PreviewHeight),
		position = UDim2.fromOffset(H.PreviewInset, H.PreviewTop),
		scrim = 1,
		fit = H.PreviewFit,
	})
	preview.hero.Ambient = H.PreviewAmbient

	-- The number: plain white text, top left, a hairline of ink round it so it
	-- reads over a light item.
	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.Position = UDim2.fromOffset(H.NumeralInset, H.NumeralInset - 2)
	number.Size = UDim2.fromOffset(H.NumeralSize + 6, H.NumeralSize + 4)
	number.BackgroundTransparency = 1
	number.Font = Enum.Font.FredokaOne
	number.TextSize = H.NumeralSize
	number.TextColor3 = H.Numeral
	number.TextXAlignment = Enum.TextXAlignment.Left
	number.TextYAlignment = Enum.TextYAlignment.Top
	number.Text = ""
	number.ZIndex = zIndex + 5
	number.Parent = button
	local numberEdge = UIKit.stroke(number, H.Ink, H.NumeralOutline)

	-- The stack count, bottom right: the tickets' xN.
	local stack = Instance.new("TextLabel")
	stack.Name = "Stack"
	stack.AnchorPoint = Vector2.new(1, 1)
	stack.Position = UDim2.new(1, -H.StackInset, 1, -H.StackInset + 1)
	stack.Size = UDim2.fromOffset(H.SlotWidth - H.StackInset * 2, H.StackSize + 3)
	stack.BackgroundTransparency = 1
	stack.Font = Enum.Font.FredokaOne
	stack.TextSize = H.StackSize
	stack.TextColor3 = H.StackColour
	stack.TextXAlignment = Enum.TextXAlignment.Right
	stack.TextYAlignment = Enum.TextYAlignment.Bottom
	stack.Text = ""
	stack.Visible = false
	stack.ZIndex = zIndex + 5
	stack.Parent = button
	UIKit.stroke(stack, H.Ink, H.NumeralOutline)

	-- The rarity accent: a thin bar on the bottom edge, in the form's colour.
	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.AnchorPoint = Vector2.new(0.5, 1)
	accent.Position = UDim2.new(0.5, 0, 1, -H.AccentBottom)
	accent.Size = UDim2.new(H.AccentShare, 0, 0, H.AccentHeight)
	accent.BorderSizePixel = 0
	accent.Visible = false
	accent.ZIndex = zIndex + 4
	accent.Parent = button
	UIKit.corner(accent, 1)

	-- The name, hidden: the Tool's whole name, for TutorialUI's pointer and the
	-- popup; never drawn on the slot.
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.fromScale(1, 1)
	name.BackgroundTransparency = 1
	name.TextTransparency = 1
	name.Text = ""
	name.Visible = false
	name.ZIndex = zIndex + 1
	name.Parent = button

	-- Hover and press: UIKit.cardPop, silent, with the rim as its glow.
	local pressScale = Instance.new("UIScale")
	pressScale.Parent = button
	local pop = UIKit.cardPop(button, pressScale, {
		hoverScale = H.HoverScale,
		pressScale = H.PressScale,
		glow = rimStroke,
		glowRest = 1,
		glowHover = H.HoverEdgeTransparency,
		lift = H.HoverLift,
		sound = false,
	})

	return {
		holder = holder,
		wrap = wrap,
		button = button,
		stroke = stroke,
		ringTint = ringTint,
		rimStroke = rimStroke,
		cooldown = cooldown,
		preview = preview,
		number = number,
		numberEdge = numberEdge,
		stack = stack,
		accent = accent,
		name = name,
		pop = pop,
		bumpScale = bumpScale,
		faceCorner = faceCorner,
		rimCorner = rimCorner,
		coolCorner = coolCorner,
		lit = false,
		liftGoal = 0,
		liftTween = nil,
		bumpTween = nil,
		flashUntil = 0,
	}
end

-- The sizes again, for a change of face. The preview keeps its model.
function HotbarCard.restyle(card: Card, H: any)
	card.holder.Size = UDim2.fromOffset(H.SlotWidth, H.SlotHeight)
	card.faceCorner.CornerRadius = UDim.new(0, H.CardCorner)
	card.rimCorner.CornerRadius = UDim.new(0, math.max(1, H.CardCorner - 1.5))
	card.coolCorner.CornerRadius = UDim.new(0, H.CardCorner)
	card.preview.holder.Size = UDim2.fromOffset(H.SlotWidth - H.PreviewInset * 2, H.PreviewHeight)
	card.preview.holder.Position = UDim2.fromOffset(H.PreviewInset, H.PreviewTop)
	card.number.Position = UDim2.fromOffset(H.NumeralInset, H.NumeralInset - 2)
	card.number.Size = UDim2.fromOffset(H.NumeralSize + 6, H.NumeralSize + 4)
	card.number.TextSize = H.NumeralSize
	card.stack.Position = UDim2.new(1, -H.StackInset, 1, -H.StackInset + 1)
	card.stack.Size = UDim2.fromOffset(H.SlotWidth - H.StackInset * 2, H.StackSize + 3)
	card.stack.TextSize = H.StackSize
	card.accent.Position = UDim2.new(0.5, 0, 1, -H.AccentBottom)
	card.accent.Size = UDim2.new(H.AccentShare, 0, 0, H.AccentHeight)
end

function HotbarCard.paint(card: Card, H: any, p: Paint)
	local empty, held = p.empty, p.held
	card.number.Text = p.number
	card.number.TextColor3 = if held then H.NumeralLit else H.Numeral
	card.number.TextTransparency = if empty then H.EmptyNumeralTransparency else 0
	card.numberEdge.Transparency = if empty then H.EmptyNumeralTransparency else 0
	card.name.Text = p.name
	local stackText = p.stack
	card.stack.Visible = stackText ~= nil and not empty
	if stackText then
		card.stack.Text = stackText
	end
	local accent = p.accent
	card.accent.Visible = accent ~= nil and not empty
	if accent then
		card.accent.BackgroundColor3 = accent
	end

	-- The plate: nearly gone when empty, lighter when held.
	card.button.BackgroundColor3 = if held then H.LitPlate else H.Plate
	card.button.BackgroundTransparency = if empty then H.EmptyPlateTransparency
		elseif held then H.LitPlateTransparency
		else H.PlateTransparency

	-- The edge, unless a flash owns it.
	if os.clock() >= card.flashUntil then
		card.ringTint.Enabled = held
		card.stroke.Color = if held then WHITE else H.Edge
		card.stroke.Thickness = if held then H.LitThickness else H.CardStroke
		card.stroke.Transparency = if held then 0
			elseif empty then H.EmptyEdgeTransparency
			else H.EdgeTransparency
	end
	card.lit = held
end

-- The in-hand lift: a few pixels up, tweened once per change; none at all
-- under reduced motion, where the edge and the plate say it alone.
function HotbarCard.lift(card: Card, up: boolean, still: boolean, H: any)
	local goal = if up and not still then -H.HeldLift else 0
	if card.liftGoal == goal and not (still and card.wrap.Position.Y.Offset ~= goal) then
		return
	end
	card.liftGoal = goal
	local running = card.liftTween
	if running then
		running:Cancel()
		card.liftTween = nil
	end
	local want = UDim2.new(0.5, 0, 0.5, goal)
	if still then
		card.wrap.Position = want
		return
	end
	local tween = TweenService:Create(card.wrap, TweenInfo.new(0.14, Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out), { Position = want })
	card.liftTween = tween
	tween:Play()
end

-- A brief pop: equip feedback, or an arrival on this slot. One tween, nothing
-- per frame; nothing at all under reduced motion.
function HotbarCard.bump(card: Card, still: boolean, H: any)
	local running = card.bumpTween
	if running then
		running:Cancel()
		card.bumpTween = nil
	end
	if still then
		card.bumpScale.Scale = 1
		return
	end
	card.bumpScale.Scale = H.BumpScale
	local tween = TweenService:Create(card.bumpScale, TweenInfo.new(H.BumpSeconds, Enum.EasingStyle.Back,
		Enum.EasingDirection.Out), { Scale = 1 })
	card.bumpTween = tween
	tween:Play()
end

-- The edge takes `colour` for a third of a second; the caller repaints after.
-- Deliberately NOT a RenderStepped pulse: one tween, then one redraw.
function HotbarCard.flash(card: Card, colour: Color3, H: any): number
	local seconds = H.FlashSeconds
	card.flashUntil = os.clock() + seconds + 0.02
	card.ringTint.Enabled = false
	card.stroke.Transparency = 0
	card.stroke.Color = colour
	card.stroke.Thickness = H.CardStroke + 1.5
	TweenService:Create(card.stroke, TweenInfo.new(seconds), { Thickness = H.CardStroke }):Play()
	return seconds + 0.02
end

return HotbarCard
