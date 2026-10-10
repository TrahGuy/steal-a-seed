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
--             a rarity accent, the hidden name -- and since 2026-10-03 (the
--             freely assignable hotbar) four more: a FAINT slot's word (a
--             placeholder waiting for the first bat, trap or tickets), an item
--             being RESTORED after a respawn, a TARGET as a phone assigns, and
--             a weapon whose equip is PENDING at the server -- and since
--             2026-10-04 a trap's PLACEMENTS still available ("3x" .. "0x")
--   cool      a trap's TRIGGER COOLDOWN (2026-10-05): the picture dimmed, the
--             shade shrinking, the seconds left over it
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
--   ghost     the empty plate with a faint word in the middle ("BAT")
--   restoring the item dimmed: it is coming back after a respawn
--   pending   the item, its edge a soft amber: asked of the server, not here yet
--   target    a bright white edge on every slot as a phone assigns
--
-- AND A RARITY (2026-10-03, the owner's inventory pass): a Mythic, Divine or
-- Secret the player can already see takes its colour on the edge and a small
-- light travelling round it (RarityFX) -- the quietest of these, so held,
-- target, pending, restoring and a flash all put the light out for as long as
-- they last. In hand also shows the Bag's small amber diamond on the top-right
-- corner, so a coloured edge is never read as the selection.
--
-- AND THE OTHER FIVE (2026-10-10, the owner: "yes, add rarity edges"): a grown
-- plant from Common to Legendary takes its rarity's still colour on the edge,
-- RarityEdge.Strip px (GameConfig.RarityEdge) -- the quietest state but plain:
-- held, target, pending and a flash all outrank it; restoring keeps it.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local InventoryTile = require(Shared:WaitForChild("InventoryTile"))

local HotbarCard = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
-- A READY pod's word (2026-10-09, pods hatch in the Bag).
local POD_READY = Color3.fromRGB(126, 214, 92)

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
	-- A trap's placements still available, bottom centre (2026-10-04).
	uses: TextLabel,
	-- A pod's size word, top right (2026-10-10).
	size: TextLabel,
	-- The trigger cooldown's seconds, over the picture (2026-10-05), and
	-- whether it is running (the picture's dim is then cool's, not paint's).
	timer: TextLabel,
	cooling: boolean,
	timerText: string,
	accent: Frame,
	-- Hidden: carries the Tool's whole name, which TutorialUI's pointer reads.
	name: TextLabel,
	-- A faint slot's word, centred (2026-10-03).
	ghost: TextLabel,
	-- The rarest rarities' travelling light, and the in-hand diamond.
	fxEdge: RarityFX.Handle,
	marker: Frame,
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
	-- 2026-10-03: a faint slot's word; restoring; a pending equip; assign mode.
	ghost: string?,
	restoring: boolean?,
	pending: boolean?,
	target: boolean?,
	-- The rarity the player may see (InventoryModel's face), or nil.
	rarity: string?,
	-- 2026-10-10: a grown plant's still rarity edge (InventoryModel's face), or
	-- nil (a pod, anything that is not a plant, the three rarest).
	edge: Color3?,
	-- 2026-10-04: a trap's placements still available ("3x"; WeaponData.TrapsLeftText),
	-- and whether that is none (drawn in TrapCountEmpty). nil for everything else.
	uses: string?,
	usesEmpty: boolean?,
	-- 2026-10-09 (pods hatch in the Bag): a pod's READY, or its time left
	-- ("4:05"), where a trap's count goes. nil and false for anything else.
	podReady: boolean?,
	podClock: string?,
	-- 2026-10-10 (Michael on v1047: "No way to view the size of eggs in the
	-- hotbar"): a pod's size word ("Titan") and its tier's colour; nil for
	-- anything else, and for a Secret or Rain pod, whose word is its rarity.
	size: string?,
	sizeColour: Color3?,
}

-- Where a pod's size word stands, at the card's sizes: top right, from 2 px
-- past the slot number's one digit (at most 0.6 of its size wide, measured:
-- "0" is 6 px at 10) to the right inset, as tall as the stack's numeral; the
-- word shrinks to fit (never under SIZE_MIN), never past StackSize. COLOSSAL is
-- 35 px at 7: a phone's card has 38 for it, a desktop's 47.
local SIZE_MIN = 7
local function placeSize(label: TextLabel, H: any)
	label.Position = UDim2.new(1, -H.StackInset, 0, H.NumeralInset - 1)
	label.Size = UDim2.fromOffset(H.SlotWidth - H.NumeralInset - math.ceil(H.NumeralSize * 0.6) - 2 - H.StackInset,
		H.StackSize + 3)
	local fit = label:FindFirstChildOfClass("UITextSizeConstraint")
	if fit then
		fit.MaxTextSize = H.StackSize
	end
end

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
	-- Border, said out loud: on a TextButton the default (Contextual) strokes
	-- the TEXT, which is empty, so the keyline, the flashes and assign mode's
	-- targets never drew at all.
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

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

	-- A trap's placements still available (2026-10-04, the reusable-trap brief):
	-- "3x" .. "0x" under its picture, bottom centre, read off the server's count
	-- by LoadoutUI. Cream with a dark keyline over any picture; a warm red at 0x.
	local uses = Instance.new("TextLabel")
	uses.Name = "Uses"
	uses.AnchorPoint = Vector2.new(0.5, 1)
	uses.Position = UDim2.new(0.5, 0, 1, -H.TrapCountBottom)
	uses.Size = UDim2.new(1, -4, 0, H.TrapCountSize + 3)
	uses.BackgroundTransparency = 1
	uses.Font = Enum.Font.FredokaOne
	uses.TextSize = H.TrapCountSize
	uses.TextColor3 = H.TrapCountColour
	uses.TextXAlignment = Enum.TextXAlignment.Center
	uses.TextYAlignment = Enum.TextYAlignment.Bottom
	uses.Text = ""
	uses.Visible = false
	uses.ZIndex = zIndex + 5
	uses.Parent = button
	UIKit.stroke(uses, H.Ink, H.NumeralOutline + 0.3)

	-- A pod's size (2026-10-10): its size word in its tier's colour, top right
	-- beside the slot number -- what the Bag tile says, on the card.
	local size = Instance.new("TextLabel")
	size.Name = "Size"
	size.AnchorPoint = Vector2.new(1, 0)
	size.BackgroundTransparency = 1
	size.Font = Enum.Font.FredokaOne
	size.TextScaled = true
	size.TextColor3 = WHITE
	size.TextXAlignment = Enum.TextXAlignment.Right
	size.TextYAlignment = Enum.TextYAlignment.Top
	size.Text = ""
	size.Visible = false
	size.ZIndex = zIndex + 5
	size.Parent = button
	UIKit.stroke(size, H.Ink, H.NumeralOutline)
	local sizeFit = Instance.new("UITextSizeConstraint")
	sizeFit.MinTextSize = SIZE_MIN
	sizeFit.Parent = size
	placeSize(size, H)

	-- A trap's trigger cooldown (2026-10-05): the seconds left, centred over the
	-- picture, white on a dark keyline, above the count. Hidden the rest of the
	-- time.
	local timer = Instance.new("TextLabel")
	timer.Name = "CoolTimer"
	timer.AnchorPoint = Vector2.new(0.5, 0.5)
	timer.Position = UDim2.fromScale(0.5, 0.45)
	timer.Size = UDim2.new(1, -4, 0, H.TrapCoolSize + 4)
	timer.BackgroundTransparency = 1
	timer.Font = Enum.Font.FredokaOne
	timer.TextSize = H.TrapCoolSize
	timer.TextColor3 = H.TrapCoolColour
	timer.TextXAlignment = Enum.TextXAlignment.Center
	timer.Text = ""
	timer.Visible = false
	timer.ZIndex = zIndex + 6
	timer.Parent = button
	UIKit.stroke(timer, H.Ink, H.NumeralOutline + 0.6)

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

	-- A faint slot's word: what the slot is waiting for, small and quiet.
	local ghost = Instance.new("TextLabel")
	ghost.Name = "Ghost"
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.Position = UDim2.fromScale(0.5, 0.56)
	ghost.Size = UDim2.new(1, -6, 0, H.NumeralSize + 4)
	ghost.BackgroundTransparency = 1
	ghost.Font = Enum.Font.FredokaOne
	ghost.TextSize = H.NumeralSize
	ghost.TextColor3 = H.Numeral
	ghost.TextTransparency = H.EmptyNumeralTransparency
	ghost.Text = ""
	ghost.Visible = false
	ghost.ZIndex = zIndex + 3
	ghost.Parent = button

	-- A Mythic, Divine or Secret's light on the border, under the number and
	-- the stack; the in-hand diamond on the corner, over everything.
	local fxEdge = RarityFX.edge(button, H.CardCorner, zIndex + 3)
	local marker = InventoryTile.marker(button, H.MarkerSize, H.Marker, H.Ink, zIndex + 6)

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
		uses = uses,
		size = size,
		timer = timer,
		cooling = false,
		timerText = "",
		accent = accent,
		name = name,
		ghost = ghost,
		fxEdge = fxEdge,
		marker = marker,
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
	card.uses.Position = UDim2.new(0.5, 0, 1, -H.TrapCountBottom)
	card.uses.Size = UDim2.new(1, -4, 0, H.TrapCountSize + 3)
	card.uses.TextSize = H.TrapCountSize
	placeSize(card.size, H)
	card.timer.Size = UDim2.new(1, -4, 0, H.TrapCoolSize + 4)
	card.timer.TextSize = H.TrapCoolSize
	card.accent.Position = UDim2.new(0.5, 0, 1, -H.AccentBottom)
	card.accent.Size = UDim2.new(H.AccentShare, 0, 0, H.AccentHeight)
	card.ghost.Size = UDim2.new(1, -6, 0, H.NumeralSize + 4)
	card.ghost.TextSize = H.NumeralSize
	RarityFX.setRadius(card.fxEdge, H.CardCorner)
	card.marker.Size = UDim2.fromOffset(H.MarkerSize, H.MarkerSize)
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
	local usesText = p.uses
	card.uses.Visible = usesText ~= nil and not empty
	if usesText then
		card.uses.Text = usesText
		card.uses.TextColor3 = if p.usesEmpty then H.TrapCountEmpty else H.TrapCountColour
	end
	-- A pod (2026-10-09): READY in green, or its time left, in the same place.
	local podText = if p.podReady then GameConfig.HatchInBag.Words.Ready else p.podClock
	if podText and not empty then
		card.uses.Visible = true
		card.uses.Text = podText
		card.uses.TextColor3 = if p.podReady then POD_READY else WHITE
	end
	local sizeWord = p.size
	card.size.Visible = sizeWord ~= nil and not empty
	if sizeWord then
		card.size.Text = string.upper(sizeWord)
		card.size.TextColor3 = p.sizeColour or WHITE
	end
	local accent = p.accent
	card.accent.Visible = accent ~= nil and not empty
	if accent then
		card.accent.BackgroundColor3 = accent
	end
	local ghostText = p.ghost
	card.ghost.Visible = ghostText ~= nil and empty
	if ghostText then
		card.ghost.Text = ghostText
	end
	-- Coming back after a respawn: the item is there, dimmed, and waits. A trap
	-- in its trigger cooldown is dimmed by cool(), which owns it until it ends.
	card.preview.hero.ImageTransparency = if p.restoring then 0.6
		elseif card.cooling then H.TrapCoolDim
		else 0

	-- The plate: nearly gone when empty, lighter when held.
	card.button.BackgroundColor3 = if held then H.LitPlate else H.Plate
	card.button.BackgroundTransparency = if empty then H.EmptyPlateTransparency
		elseif held then H.LitPlateTransparency
		else H.PlateTransparency

	-- The edge, unless a flash owns it. Assign mode's target outranks
	-- everything but a flash; a pending equip is a soft amber; a rarest
	-- rarity's colour is the quietest, under all of them.
	local target, pending = p.target == true, p.pending == true and not held
	local rarity = if empty then nil else p.rarity
	local rare = RarityFX.edgeColour(rarity)
	-- The other five's still colour, under every state but plain.
	local still = if empty or rare then nil else p.edge
	local flashing = os.clock() < card.flashUntil
	if not flashing then
		card.ringTint.Enabled = held and not target
		card.stroke.Color = if target or held then WHITE
			elseif pending then H.LitTop
			elseif rare then rare
			elseif still then still
			else H.Edge
		card.stroke.Thickness = if target or held then H.LitThickness
			elseif still and not pending then (GameConfig.RarityEdge :: any).Strip
			else H.CardStroke
		card.stroke.Transparency = if target or held then 0
			elseif pending then 0.3
			elseif empty then H.EmptyEdgeTransparency
			elseif rare or still then 0.05
			else H.EdgeTransparency
	end
	card.marker.Visible = held
	RarityFX.setEdge(card.fxEdge, rarity,
		not (held or target or pending or p.restoring == true or flashing))
	card.lit = held
end

--==============================================================================
-- A TRAP'S TRIGGER COOLDOWN (2026-10-05)
--
-- `left` seconds of `total` still to wait, or 0 for none. Called every frame
-- by LoadoutUI's strip loop. The shade shrinks with the wait (as a bat's recovery
-- does), the picture stays dimmed and the whole seconds left stand over it --
-- "10" down to "1" -- written only when the number changes. Ended, everything
-- goes back at once: the dim, the shade and the number.
--==============================================================================
function HotbarCard.cool(card: Card, H: any, left: number, total: number)
	local running = left > 0 and total > 0
	if running then
		local share = math.min(1, left / total)
		card.cooldown.Size = UDim2.fromScale(1, share)
		local text = tostring(math.max(1, math.ceil(left - 1e-6)))
		if text ~= card.timerText then
			card.timerText = text
			card.timer.Text = text
		end
		if not card.cooling then
			card.cooling = true
			card.timer.Visible = true
			card.preview.hero.ImageTransparency = H.TrapCoolDim
		end
	elseif card.cooling then
		card.cooling = false
		card.timerText = ""
		card.timer.Text = ""
		card.timer.Visible = false
		card.cooldown.Size = UDim2.fromScale(1, 0)
		card.preview.hero.ImageTransparency = 0
	end
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
	RarityFX.setEdge(card.fxEdge, card.fxEdge.rarity, false)
	card.stroke.Transparency = 0
	card.stroke.Color = colour
	card.stroke.Thickness = H.CardStroke + 1.5
	TweenService:Create(card.stroke, TweenInfo.new(seconds), { Thickness = H.CardStroke }):Play()
	return seconds + 0.02
end

return HotbarCard
