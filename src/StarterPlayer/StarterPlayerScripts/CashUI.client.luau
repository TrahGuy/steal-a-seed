--!strict
-- Steal a Seed :: CashUI
--
-- Two numbers in the bottom-left corner: not what you earn, what you HAVE.
--
--==============================================================================
-- DRAWN FROM THE OWNER'S REFERENCE SHOT, SAMPLED RATHER THAN EYEBALLED
--
-- `money speed gui.png` in the repo root. Every number below came out of that
-- file with a pixel sampler, not off a first impression -- the first impression
-- said "blue shoe with a green plus badge", and the badge is GOLD.
--
--     speed fill      rgb( 25,144,255)   glyphs 24px tall, "3.5M"   84px wide
--     cash fill       rgb( 38,255,  0)   glyphs 32px tall, "$1.8B" 105px wide
--     outline         rgb(  0,  0,  0)   2px on the speed line, 3px on the cash
--     badge           rgb(255,216,  0)   gold, with a white plus
--     shoe highlight  rgb(223,242,252)
--
-- LuckiestGuy is the face. Of the six heavy display fonts this engine ships it
-- is the only one that is heavy AND slanted AND rounded, which is all three
-- things the reference is. The sizes are SOLVED, not picked:
-- TextService:GetTextSize says 39 reproduces that 84px width and 47 reproduces
-- the 105px one, and at those sizes the cap heights land on 24 and 32 too.
--
-- NO PANEL. This used to have an ink plate with a corner radius and a stroke.
-- The reference is bare outlined text sitting on the grass, and the outline is
-- what does the job the plate was doing.
--
--==============================================================================
-- THE ONE PLACE THE PALETTE DOES NOT APPLY
--
-- Ink / paper / accent is the vocabulary everywhere else -- PromptUI, PlantUI,
-- the Index, the Garden. These four colours are not in it and are not meant to
-- be: they were sampled off a specific picture the owner asked for exactly.
--
-- There is a reason beyond "because it was asked", and it is worth keeping: a
-- HUD number is the one element with no plate behind it, so it has to stay
-- readable against grass, dirt, a nest and a treadmill on its own. Accent green
-- (142,196,62) is olive, and on Greenhollow grass it disappears.
--
-- The blue is NOT SpeedFX's shoe blue (96,164,232). Left different on purpose:
-- that pop is a different element and was not part of this request.
--
--==============================================================================
-- NO NEW REMOTE
--
-- PlayerDataService already pushes the whole profile down ProfileUpdated,
-- coalesced at four times a second, and announces the first on ProfileReady.
--
--==============================================================================
-- WaitForChild ON THE REMOTES, NOT FindFirstChild
--
-- The Remotes FOLDER replicates before the RemoteEvents inside it do. A
-- FindFirstChild here returned nil, the connection was silently skipped, and the
-- readout sat on its dash for a whole session with no error anywhere.
--
--==============================================================================
-- IT DOES NOT SHOW ZERO UNTIL IT HAS BEEN TOLD
--
-- The dash matters. "0" and "we have not heard from the server yet" are
-- different facts, and rendering the second as the first is how a player with a
-- real balance is shown an empty wallet during a slow DataStore call.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
-- For its TV scale (UIKit.tenFoot / UIKit.scaleOf) and the shoe's load.
local UIKit = require(Shared:WaitForChild("UIKit"))
local SizedIcon = require(Shared:WaitForChild("SizedIcon"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--== sampled out of money speed gui.png ==--
local SPEED_BLUE = Color3.fromRGB(25, 144, 255)
local CASH_GREEN = Color3.fromRGB(38, 255, 0)
local OUTLINE = Color3.fromRGB(0, 0, 0)
local BADGE_GOLD = Color3.fromRGB(255, 216, 0)
local SHOE_LIGHT = Color3.fromRGB(223, 242, 252)
local WHITE = Color3.fromRGB(255, 255, 255)

--==============================================================================
-- TWO FACES, ONE BLOCK
--
-- Every size here comes from HudLayout's CashStyle for the mode the screen is
-- in. The desktop face is what always shipped, to the pixel -- 39 and 47 above
-- are its two sizes -- and the compact face is the same block at the size a
-- landscape phone can afford (see THE CASH BLOCK'S TWO FACES in HudLayout). The
-- face comes with the same answer that places the block, and is drawn by
-- applyStyle below; nothing in this script decides what a phone is.
--==============================================================================
local style: HudLayout.CashStyle = HudLayout.Config.CashStyle.Desktop

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedCash")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedCash"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

--==============================================================================
-- CONNECTIONS DIE WITH THE GUI THEY DRAW
--
-- Destroying the old ScreenGui above was enough while every connection in this
-- file wrote to something inside it -- a handler firing at a destroyed label is
-- harmless. The buff indicator adds one on the PLAYER, which outlives the GUI,
-- so a second run of this script would leave the first run's listener attached
-- to a player that now has two of them.
--
-- Bound to Destroying rather than disconnected at the top, because the object
-- that knows a run is over is the GUI that run created.
--==============================================================================
local connections: { RBXScriptConnection } = {}
gui.Destroying:Once(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
end)

local function corner(parent: Instance, radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

--==============================================================================
-- THE STACK
--
-- Speed on top, cash under it and larger. Both the order and the size difference
-- are the reference's. Anchored to the BOTTOM edge so the cash line stays put
-- and the speed line sits off it.
--
-- AS WIDE AS WHAT IS IN IT. 340 was the status line's width, and that line is
-- gone; the widest thing left is the Speed label's box, 56 in from the shoe and
-- 260 across, so the block is 316. The cash box (300) and the buff card, which
-- is placed off the cash text and never reaches that far, both sit inside it.
-- Nothing moved: the shoe, the numbers and the card are where they were. (The
-- compact face keeps the same rule at its own sizes: 36 + 154 = 190.)
--==============================================================================
local root = Instance.new("Frame")
root.Name = "Corner"
root.AnchorPoint = Vector2.new(0, 1)
root.Position = UDim2.new(0, 12, 1, -10)
root.Size = UDim2.fromOffset(style.Root.X, style.Root.Y)
root.BackgroundTransparency = 1
root.Parent = gui

--==============================================================================
-- THE SHOE
--
-- THE OWNER'S SPEED SHOE SINCE 2026-10-08 (TREADMILL FUN, addendum 3: the one
-- Speed icon everywhere): GameConfig.SourceIcons.speed in this same 50 x 38
-- box, so no HUD rect moves. It draws at 38 px on a desktop and smaller on the
-- compact faces -- the owner's small version there (SizedIcon, 40 px or less).
-- The gold plus badge stays over its bottom-right, as in the reference.
--
-- The sneaker drawn from frames below (a glyph would come out a tofu box) is
-- what this showed before. It stays underneath until the picture has loaded,
-- and for good if it never does: white sole, blue upper with a taller heel, a
-- pale stripe across it.
--==============================================================================
local shoe = Instance.new("Frame")
shoe.Name = "Shoe"
shoe.AnchorPoint = Vector2.new(0, 1)
shoe.Position = UDim2.new(0, 0, 0, style.ShoeBottom)
shoe.Size = UDim2.fromOffset(50, 38)
shoe.BackgroundTransparency = 1
shoe.Parent = root

-- Drawn once at 50 x 38 and scaled as one piece about its bottom-left corner,
-- so the compact face's shoe is this same drawing and never a second one.
local shoeScale = Instance.new("UIScale")
shoeScale.Scale = style.ShoeScale
shoeScale.Parent = shoe

-- The frame sneaker, all in one holder so it can go as one once the picture is in.
local drawn = Instance.new("Frame")
drawn.Name = "Drawn"
drawn.Size = UDim2.fromScale(1, 1)
drawn.BackgroundTransparency = 1
drawn.Parent = shoe

local sole = Instance.new("Frame")
sole.Name = "Sole"
sole.Position = UDim2.fromOffset(0, 26)
sole.Size = UDim2.fromOffset(42, 11)
sole.BackgroundColor3 = WHITE
sole.BorderSizePixel = 0
sole.Parent = drawn
corner(sole, 5)

local heel = Instance.new("Frame")
heel.Name = "Heel"
heel.Position = UDim2.fromOffset(15, 4)
heel.Size = UDim2.fromOffset(27, 24)
heel.BackgroundColor3 = SPEED_BLUE
heel.BorderSizePixel = 0
heel.Parent = drawn
corner(heel, 9)

local toe = Instance.new("Frame")
toe.Name = "Toe"
toe.Position = UDim2.fromOffset(0, 14)
toe.Size = UDim2.fromOffset(23, 14)
toe.BackgroundColor3 = SPEED_BLUE
toe.BorderSizePixel = 0
toe.Parent = drawn
corner(toe, 7)

local stripe = Instance.new("Frame")
stripe.Name = "Stripe"
stripe.Position = UDim2.fromOffset(4, 19)
stripe.Size = UDim2.fromOffset(26, 5)
stripe.Rotation = -10
stripe.BackgroundColor3 = SHOE_LIGHT
stripe.BorderSizePixel = 0
stripe.Parent = drawn
corner(stripe, 2)

-- The owner's shoe, BIGGER (the owner, 2026-10-08: the shoe, not the number).
-- The art fills only 88% x 68% of its square (x 32-485, y 84-431 of 512), so
-- the old 38 box drew a 33 x 26 shoe. A PICTURE box at the box's left,
-- hanging PICTURE_DROP under it -- the clear rows under the sole -- draws it
-- about 48 x 37: as tall as the Speed line, its toe short of the number, and
-- inside the block on every face (SpeedShoeSpec). The 50 x 38 box, the
-- numbers and every HUD rect are as they were.
local PICTURE, PICTURE_DROP = 54, 8
local shoePicture = Instance.new("ImageLabel")
shoePicture.Name = "Picture"
shoePicture.Position = UDim2.fromOffset(0, 38 + PICTURE_DROP - PICTURE)
shoePicture.Size = UDim2.fromOffset(PICTURE, PICTURE)
shoePicture.BackgroundTransparency = 1
shoePicture.ScaleType = Enum.ScaleType.Fit
shoePicture.Image = SizedIcon.at(GameConfig.SourceIcons.speed, PICTURE * style.ShoeScale)
shoePicture.ZIndex = 2
shoePicture.Parent = shoe
SizedIcon.follow(shoePicture)
UIKit.whenPictureLoads(shoePicture, function(loaded: boolean)
	if loaded then
		drawn.Visible = false
	end
end)

--== the gold plus badge ==--
-- Over the bigger shoe's bottom-right, its right edge 2 px short of the
-- Speed number on every face (SpeedShoeSpec).
local badge = Instance.new("Frame")
badge.Name = "Badge"
badge.Position = UDim2.fromOffset(31, 15)
badge.Size = UDim2.fromOffset(23, 23)
badge.BackgroundColor3 = BADGE_GOLD
badge.BorderSizePixel = 0
badge.ZIndex = 3
badge.Parent = shoe
corner(badge, 6)

local badgeEdge = Instance.new("UIStroke")
badgeEdge.Color = OUTLINE
badgeEdge.Thickness = 2
badgeEdge.Parent = badge

for _, bar in ipairs({
	{ name = "PlusV", w = 5, h = 13 },
	{ name = "PlusH", w = 13, h = 5 },
}) do
	local piece = Instance.new("Frame")
	piece.Name = bar.name
	piece.AnchorPoint = Vector2.new(0.5, 0.5)
	piece.Position = UDim2.fromScale(0.5, 0.5)
	piece.Size = UDim2.fromOffset(bar.w, bar.h)
	piece.BackgroundColor3 = WHITE
	piece.BorderSizePixel = 0
	piece.ZIndex = 4
	piece.Parent = badge
	corner(piece, 1)
end

--==============================================================================
-- THE "+" OPENS THE SHOP AT SPEED (the owner, 2026-10-08)
--
-- One clear button over the shoe and its badge -- the press, never the picture.
-- It reaches from 8 px above and left of the block (inside the 8 px HudLayout
-- keeps clear round it) to 2 px short of the Speed number and down to the
-- shoe's foot. That is at least the x2 card's touch area (BuffHit, 44 on the
-- compact and phone faces). There it reaches a few px over the number and the
-- top of the cash line, neither of which takes a press. Sized in applyStyle.
-- It fires ShopUI's OpenAt with the Speed shelf's id: the Shop opens at SPEED.
--==============================================================================
local SPEED_SHELF = "Speed" -- GameConfig.Store.Sections' id for SPEED
local speedHit = Instance.new("TextButton")
speedHit.Name = "SpeedShop"
speedHit.Position = UDim2.fromOffset(-8, -8)
speedHit.BackgroundTransparency = 1
speedHit.BorderSizePixel = 0
speedHit.AutoButtonColor = false
speedHit.Selectable = false
speedHit.Text = ""
speedHit.ZIndex = 6
speedHit.Parent = root
table.insert(connections, speedHit.Activated:Connect(function()
	local shop = playerGui:FindFirstChild("SeedShop")
	local openAt = shop and shop:FindFirstChild("OpenAt")
	if openAt and openAt:IsA("BindableEvent") then
		SoundKit.play("CardClick")
		openAt:Fire(SPEED_SHELF)
	end
end))

--==============================================================================
-- THE NUMBERS
--==============================================================================
local function outlined(name: string, size: number, colour: Color3,
	thickness: number): (TextLabel, UIStroke)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.LuckiestGuy
	label.TextSize = size
	label.TextColor3 = colour
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = "—"
	label.Parent = root

	-- The outline IS the readability. There is no plate behind these, so it is
	-- the only thing keeping a lime number legible on lime grass.
	local edge = Instance.new("UIStroke")
	edge.Color = OUTLINE
	edge.Thickness = thickness
	edge.Parent = label
	return label, edge
end

local speed, speedEdge = outlined("Speed", style.SpeedSize, SPEED_BLUE, style.SpeedStroke)
speed.AnchorPoint = Vector2.new(0, 1)
speed.Position = UDim2.new(0, style.SpeedX, 0, style.SpeedBottom)
speed.Size = UDim2.fromOffset(style.SpeedW, style.SpeedSize + 4)

local amount, amountEdge = outlined("Amount", style.CashSize, CASH_GREEN, style.CashStroke)
amount.AnchorPoint = Vector2.new(0, 1)
amount.Position = UDim2.new(0, 0, 1, 0)
amount.Size = UDim2.fromOffset(style.CashW, style.CashSize + 4)

--==============================================================================
-- THE LINE THAT USED TO SIT ABOVE THIS BLOCK IS GONE
--
-- A rotating status line -- next trail, next biome, walk speed, Training Rush
-- -- sat 2 px above the Speed line until 2026-09-18, when the owner had it
-- removed. It was the only thing in this HUD wider than the numbers and the
-- only thing above them, so the block is now exactly the shoe, the two
-- numbers and the buff card, and nothing is drawn over the world above it.
--
-- Removed, not hidden: no label, no rotation clock and no 4 Hz rebuild are
-- left behind. The values it printed are still computed where they always
-- were, so a readout can come back without anything upstream moving -- all
-- but the Training Rush, which has left the mill itself (2026-10-05).
--==============================================================================
-- The colour secondary text on this HUD has always used, and the one thing
-- still drawn in it: the buff card's sentence.
local SECONDARY_TEXT = Color3.fromRGB(226, 238, 250)

--==============================================================================
-- THE x2 MONEY BUFF CARD
--
-- One small card beside the cash line, shown only while the player owns the
-- pass. It reads the CashMultiplier attribute the server publishes and NOTHING
-- ELSE: it is a label on a state, never the state itself. EconomyService
-- multiplies the faucet from PassService's own ownership table and never looks
-- at this attribute, so a client that rewrites its own copy changes what its own
-- HUD draws and not one coin of what it is paid.
--
-- NO ANIMATION. No pulse, no spin, no sparkle. It is furniture that says a thing
-- is true; a permanent buff that flashes for attention is a permanent
-- distraction, and this sits next to the number a player watches most.
--
-- IT MOVES WITH THE CASH TEXT, NOT WITH THE HUD. `$1.2K` and `$914.77T` are not
-- the same width, so a card at a fixed offset would either overlap the number or
-- float away from it. It is placed off the label's measured TextBounds every
-- time the text changes, which is the only thing here that is responsive -- the
-- shoe, the speed line and the cash line do not move at all.
--
-- ON A TOUCH SCREEN TOO, since the owner's mobile corrections (2026-10-05). It
-- stood on the top-right row as a button from 2026-09-23; now it rides the cash
-- text there as everywhere else, never nearer the thumbstick's zone than
-- HudLayout's `buffMinX`, and is drawn with NO PLATE on a touch screen: the
-- artwork alone -- no tile, no border, no backplate. Its press, its message and
-- when it shows are exactly what they were.
--==============================================================================
local PASS = GameConfig.Pass
local BUFF_EMERALD = Color3.fromRGB(12, 58, 34)
local BUFF_GOLD = Color3.fromRGB(238, 190, 62)

local buff = Instance.new("TextButton")
buff.Name = "MoneyBuff"
buff.AnchorPoint = Vector2.new(0, 1)
-- Two pixels under the cash label's bottom edge, which puts it just below the
-- text baseline rather than centred on it.
buff.Position = UDim2.new(0, 140, 1, style.BuffDrop)
buff.Size = UDim2.fromOffset(style.BuffSize, style.BuffSize)
buff.BackgroundColor3 = BUFF_EMERALD
buff.BackgroundTransparency = 0.08
buff.BorderSizePixel = 0
buff.AutoButtonColor = false
buff.Text = ""
buff.Visible = false
buff.ZIndex = 4
buff.Parent = root
local buffCorner = corner(buff, style.BuffCorner)

-- On the BORDER (the global UI pass, 2026-10-04): the card is a text-less
-- button, and a stroke in its default mode outlines the text -- none.
local buffEdge = Instance.new("UIStroke")
buffEdge.Color = BUFF_GOLD
buffEdge.Thickness = 1.5
buffEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
buffEdge.Parent = buff

--==============================================================================
-- THE PRESS LANDS ON A SQUARE AT LEAST AS BIG AS A THUMB
--
-- A transparent button centred on the card and `BuffHit` square: 44 around a
-- card drawn at 36 in the compact face, which is the touch floor, and exactly
-- the card on a desktop, where both are the same 46 -- so a click there lands
-- where it always did. Above the card and the icon, so it takes every press;
-- the card under it is only the picture. A child of the card, so it is shown,
-- hidden and moved with it and never needs placing on its own.
--==============================================================================
local buffHit = Instance.new("TextButton")
buffHit.Name = "Hit"
buffHit.AnchorPoint = Vector2.new(0.5, 0.5)
buffHit.Position = UDim2.fromScale(0.5, 0.5)
buffHit.Size = UDim2.fromOffset(style.BuffHit, style.BuffHit)
buffHit.BackgroundTransparency = 1
buffHit.BorderSizePixel = 0
buffHit.AutoButtonColor = false
buffHit.Text = ""
buffHit.ZIndex = 6
buffHit.Parent = buff

local buffIcon = Instance.new("ImageLabel")
buffIcon.Name = "Icon"
buffIcon.AnchorPoint = Vector2.new(0.5, 0.5)
buffIcon.Position = UDim2.fromScale(0.5, 0.5)
buffIcon.Size = UDim2.new(1, -8, 1, -8)
buffIcon.BackgroundTransparency = 1
buffIcon.Image = PASS.BuffIcon or ""
-- Fit, not Stretch: the cutout is wider than it is tall and a stretched one
-- would squash the coin into an ellipse.
buffIcon.ScaleType = Enum.ScaleType.Fit
buffIcon.ZIndex = 5
buffIcon.Parent = buff

--==============================================================================
-- THE MESSAGE
--
-- GothamMedium 15 on a 2px black outline with no plate -- the treatment this HUD
-- has always used for secondary text (the status line that used to sit above the
-- block was the same), so a second style is not invented for one sentence. 13
-- in the compact face.
--
-- Its width is measured when the face changes and at no other time. The string
-- never changes, so measuring it per click would be a TextService call on every
-- tap for an answer that cannot differ.
--==============================================================================
local BUFF_TEXT = PASS.BuffMessage or "Earn x2 money permanently."
local tip = Instance.new("TextLabel")
tip.Name = "BuffMessage"
tip.BackgroundTransparency = 1
tip.Font = Enum.Font.GothamMedium
tip.TextSize = style.TipSize
tip.TextColor3 = SECONDARY_TEXT
tip.TextXAlignment = Enum.TextXAlignment.Left
tip.TextYAlignment = Enum.TextYAlignment.Center
tip.AnchorPoint = Vector2.new(0, 1)
tip.Size = UDim2.fromOffset(240, 18)
tip.Text = BUFF_TEXT
tip.Visible = false
tip.ZIndex = 6
tip.Parent = root

local tipEdge = Instance.new("UIStroke")
tipEdge.Color = OUTLINE
tipEdge.Thickness = 2
tipEdge.Parent = tip

local tipWidth = 0

-- The card's leftmost place off the cash text on a touch screen: HudLayout's
-- `buffMinX`, which keeps its press 8 px off the thumbstick's zone. nil
-- elsewhere, where the face's own BuffMinX decides, as it always did.
local layoutMinX: number? = nil

--==============================================================================
-- WHERE THE CARD SITS
--
-- Beside the cash number, so it has to be measured off it. TextBounds is the
-- rendered width of the label's own text and updates with it; the floor is there
-- for the first frames, before the server has said anything and the label is
-- still a dash.
--==============================================================================
--==============================================================================
-- A STEADY WIDTH, NOT THE LIVE ONE
--
-- The balance is spelled in whole dollars below 100K, so its text changes with
-- every payout, and LuckiestGuy's digits are not all one width: a card placed
-- off TextBounds shuffled a pixel or two every second. It is placed off the
-- same string with every digit swapped for the widest one, which changes only
-- when a digit, a comma or a unit is actually gained.
--==============================================================================
local widestDigit: string? = nil

local function steadyWidth(): number
	if amount.Text == "" or amount.Text == "—" then
		-- TextBounds is real pixels; on a TV that is the gui's scale times the
		-- Offsets it is compared with (UIKit.scaleOf is 1 elsewhere).
		return math.max(amount.TextBounds.X / UIKit.scaleOf(gui), 0)
	end
	if widestDigit == nil then
		local best, bestWidth = "0", -1
		for d = 0, 9 do
			local width = TextService:GetTextSize(tostring(d), amount.TextSize, amount.Font,
				Vector2.new(1000, 1000)).X
			if width > bestWidth then
				best, bestWidth = tostring(d), width
			end
		end
		widestDigit = best
	end
	local template = (string.gsub(amount.Text, "%d", widestDigit :: string))
	return TextService:GetTextSize(template, amount.TextSize, amount.Font, Vector2.new(10000, 1000)).X
end

local function placeBuff()
	local textWidth = math.max(steadyWidth(), 0)
	local x = math.max(layoutMinX or style.BuffMinX, math.floor(textWidth) + style.BuffGap)
	buff.Position = UDim2.new(0, x, 1, style.BuffDrop)

	--==========================================================================
	-- The message follows the card, but is not allowed to leave the HUD's own
	-- footprint. On a narrow phone the sentence is wider than the gap between
	-- the card and the right edge, and a line that runs off the screen is a line
	-- nobody can read -- so it slides left until it fits and stays directly
	-- above the icon whenever there is room. Measured against the block's own
	-- width in its own units, which is what the offsets are in.
	--==========================================================================
	local limit = math.max(0, root.Size.X.Offset - tipWidth)
	tip.Position = UDim2.new(0, math.clamp(x, 0, limit), 1, -style.TipLift)
end

--==============================================================================
-- DRAWING A FACE
--
-- Every size that differs between the two faces, written in one place. Called
-- once as the block is built and again only when HudLayout's answer changes
-- face -- a desktop window dragged into compact, or back -- never per frame.
-- Positions inside the block are written here too, so a face is complete
-- whichever order it arrives in.
--==============================================================================
local function applyStyle(want: HudLayout.CashStyle)
	style = want
	root.Size = UDim2.fromOffset(want.Root.X, want.Root.Y)
	shoe.Position = UDim2.new(0, 0, 0, want.ShoeBottom)
	shoeScale.Scale = want.ShoeScale
	-- The "+"'s press: 2 px short of the number and down to the shoe's foot, or
	-- the x2 card's touch area where that is more (THE "+" OPENS THE SHOP).
	speedHit.Size = UDim2.fromOffset(math.max(want.SpeedX - 2, want.BuffHit - 8) + 8,
		math.max(want.ShoeBottom, want.BuffHit - 8) + 8)
	speed.TextSize = want.SpeedSize
	speed.Position = UDim2.new(0, want.SpeedX, 0, want.SpeedBottom)
	speed.Size = UDim2.fromOffset(want.SpeedW, want.SpeedSize + 4)
	speedEdge.Thickness = want.SpeedStroke
	amount.TextSize = want.CashSize
	amount.Size = UDim2.fromOffset(want.CashW, want.CashSize + 4)
	amountEdge.Thickness = want.CashStroke
	buff.Size = UDim2.fromOffset(want.BuffSize, want.BuffSize)
	buffCorner.CornerRadius = UDim.new(0, want.BuffCorner)
	buffHit.Size = UDim2.fromOffset(want.BuffHit, want.BuffHit)
	tip.TextSize = want.TipSize
	tipWidth = TextService:GetTextSize(
		BUFF_TEXT, want.TipSize, tip.Font, Vector2.new(1000, 100)).X + 4
	tip.Size = UDim2.fromOffset(math.ceil(tipWidth), want.TipSize + 3)
	placeBuff()
end

applyStyle(style)

--==============================================================================
-- WHERE THE BLOCK SITS: ONE MEASURED GROUP, MOVED, NEVER SHRUNK
--
-- The shoe, both numbers and the x2 card are one group, and HudLayout places
-- the group -- this script only measures it and applies the answer to `root`.
-- Nothing inside the block moves relative to anything else, so the easing, the
-- colours, the formatting and the card's place off the cash text are exactly
-- what they were.
--
--   desktop   the bottom-left corner, 12 in and 10 up, as it always was --
--             unless a narrow window leaves no room beside the hotbar, when
--             the whole block stands 8 px above the strip instead
--   phone     8 px above the thumbstick's resting ring, and above the
--             hotbar's top line wherever it would otherwise meet the strip,
--             in the compact face
--
-- THE WIDTH IS A RESERVATION, NOT THE NUMBER. HudLayout places the block by
-- the widest it can get -- "$9.99Qa" with the card beside it, 230 px on a
-- desktop and 180 in compact -- so a balance gaining a digit never makes the
-- block hop. What is measured here is the group's real width, and it only
-- matters if it ever outgrows that reservation, which no value under the save
-- cap does.
--==============================================================================
local function groupWidth(): number
	-- The outline (3 px on a desktop's cash line, 2 on its speed line) draws
	-- outside TextBounds; the card is placed off the text by placeBuff, and its
	-- touch area reaches past it by half the difference.
	local cashRight = math.ceil(steadyWidth()) + math.ceil(style.CashStroke)
	if buff.Visible and buff.Parent == root then
		cashRight = math.max(cashRight,
			buff.Position.X.Offset + (style.BuffSize + style.BuffHit) / 2)
	end
	return math.max(cashRight,
		style.SpeedX + math.ceil(speed.TextBounds.X / UIKit.scaleOf(gui)) + math.ceil(style.SpeedStroke))
end

local placedFor = 0

local function placeCorner()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui, groupWidth()))
	if layout.cashStyle ~= style then
		-- A new face is a new width, and the width is what the block is placed
		-- by, so the question is asked again about the block as it now is.
		applyStyle(layout.cashStyle)
		layout = HudLayout.solve(HudLayout.measure(gui, groupWidth()))
		if layout.cashStyle ~= style then
			applyStyle(layout.cashStyle)
		end
	end
	placedFor = layout.cash.w
	root.Position = HudLayout.place(layout.cashRoot, root.AnchorPoint, layout.safe)

	--==========================================================================
	-- THE x2 CARD, BESIDE THE CASH LINE ON EVERY SCREEN (the owner's mobile
	-- corrections, 2026-10-05)
	--
	-- It was the top-right row's first button on a phone from 2026-09-23. Now it
	-- rides the cash text there as everywhere else: off the text by placeBuff,
	-- never nearer the thumbstick's zone than HudLayout's `buffMinX`, which the
	-- belt keeps 8 px off. On a touch screen it is the artwork alone -- the card
	-- transparent, no border, the picture the whole card -- and its press, its
	-- message and when it shows are exactly what they were.
	--==========================================================================
	layoutMinX = layout.buffMinX
	local plain = layout.sidebar == true
	buff.BackgroundTransparency = if plain then 1 else 0.08
	buffEdge.Enabled = not plain
	buffIcon.Size = if plain then UDim2.fromScale(1, 1) else UDim2.new(1, -8, 1, -8)
	placeBuff()
end

table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeCorner))
-- The same two facts LoadoutUI re-asks on: a touch screen or a keyboard coming
-- or going changes the answer without changing the size.
table.insert(connections, UserInputService:GetPropertyChangedSignal("TouchEnabled")
	:Connect(placeCorner))
table.insert(connections, UserInputService:GetPropertyChangedSignal("KeyboardEnabled")
	:Connect(placeCorner))
-- A trap's REMOVE row over the strip (LoadoutUI, 2026-10-04) raises the band
-- the block steps over where it shares the strip's columns.
table.insert(connections, player:GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute)
	:Connect(placeCorner))
placeCorner()

--==============================================================================
-- SHOWN ONLY TO SOMEBODY WHO OWNS IT
--
-- GameConfig.cashMultiplier answers 1 for a missing, malformed or below-1
-- attribute, so "not published yet" and "does not own it" both read as no card
-- rather than as a card with nothing behind it.
--==============================================================================
local hideToken = 0
local hideTween: Tween? = nil

local function hideMessage(immediate: boolean?)
	hideToken += 1
	if hideTween then
		hideTween:Cancel()
		hideTween = nil
	end
	if immediate then
		tip.Visible = false
	end
end

local function refreshBuff()
	local on = GameConfig.cashMultiplier(player) > 1
	if buff.Visible == on then
		return
	end
	buff.Visible = on
	if not on then
		-- The message belongs to the card. Losing the pass with the line still
		-- up would leave a sentence about a buff that is no longer running.
		hideMessage(true)
	else
		placeBuff()
		if groupWidth() > placedFor then
			placeCorner()
		end
	end
end

--==============================================================================
-- ONE MESSAGE, ONE TIMER, ONE TWEEN
--
-- A second tap does not add anything -- it cancels the fade that is running,
-- puts the line back to full opacity and takes a new token. The old timer still
-- wakes up, sees a token that is not its own and returns without touching
-- anything, which is what keeps repeated taps from stacking fades on one label.
--==============================================================================
local FADE = PASS.BuffFade or 0.25

table.insert(connections, buffHit.Activated:Connect(function()
	hideMessage(false)
	local mine = hideToken

	tip.TextTransparency = 0
	tipEdge.Transparency = 0
	tip.Visible = true
	placeBuff()
	SoundKit.play("CardClick")

	task.delay(PASS.BuffSeconds or 2.5, function()
		if hideToken ~= mine or not tip.Parent then
			return
		end
		local info = TweenInfo.new(FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fade = TweenService:Create(tip, info, { TextTransparency = 1 })
		hideTween = fade
		TweenService:Create(tipEdge, info, { Transparency = 1 }):Play()
		fade.Completed:Once(function()
			if hideToken == mine then
				tip.Visible = false
			end
		end)
		fade:Play()
	end)
end))

--==============================================================================
-- THE ATTRIBUTE IS THE ONLY INPUT
--
-- No remote and no poll. PassService writes CashMultiplier on the Player when it
-- learns what they own -- at join, when a purchase prompt closes, and on its
-- slow re-ask -- and every one of those arrives here as this signal.
--==============================================================================
table.insert(connections, player:GetAttributeChangedSignal(
	GameConfig.Pass.MultiplierAttribute):Connect(refreshBuff))
refreshBuff()


--==============================================================================
-- STATE
--
-- Eased rather than stepped: cash arrives in 0.25s batches, so the raw value
-- moves in visible jumps, and easing reads as EARNING rather than as a number
-- being overwritten.
--
-- Formatted with the shared compactor, which is what makes it read `$1.8B` like
-- the reference instead of a run of commas. The cost is real and worth stating:
-- past a million the compacted text stops visibly ticking, because 1,046,473 and
-- 1,046,590 are both `$1M`. Under a thousand it prints exact integers and moves
-- on every single payout -- which is when the movement is doing the teaching.
--==============================================================================
local target: number? = nil
local shown = 0
--==============================================================================
-- THE TICK COUNTS A LUMP IN, AND ONLY MURMURS ABOUT INCOME
--
-- The number eases toward the truth on RenderStepped, so a tick per frame would
-- be sixty ticks a second for as long as a bank is being counted in -- a buzz,
-- not a counter. It was every third CHANGE of the printed text, which was right
-- for a sale landing and wrong for everything else: plant income changes the
-- text every second of a session, so an early garden ticked about once a
-- second and a $100/s one ten times a second, for ever. Reported as irritating
-- on 2026-09-26.
--
-- So each change of the balance is sorted as it arrives (GameConfig.
-- cashStepIsLump). A LUMP -- a sale, a reward, a purchase -- is counted in with
-- a tick per printed change, as before, but never faster than CountSeconds. A
-- ROUTINE change ticks at most once every RoutineSeconds, at RoutineVolume:
-- still there, so income is heard to be arriving, no longer a metronome. Both
-- through the UI bus, so the SOUND FX setting applies as it always did. The
-- balance itself is untouched -- this only decides when the tick sounds.
--
-- Deliberately NOT wired to CashPop's +$N. Every grown plant pays once a second
-- and a garden of twelve would be twelve ticks a second forever.
--==============================================================================
local TICKS = GameConfig.Sfx.CashTicks
local ROUTINE_TICK = {
	volume = (GameConfig.Sfx.Cues.CashTick.volume or 0.5) * TICKS.RoutineVolume,
}
local lastTickAt = -math.huge
-- The running size of an ordinary change, and whether a lump is being counted.
local routineStep: number? = nil
local counting = false
local speedTarget: number? = nil
local speedShown = 0

local function receive(profile: any)
	if type(profile) ~= "table" or type(profile.Cash) ~= "number" then
		return
	end
	if target == nil then
		-- First word from the server: land on it rather than counting up from
		-- zero, or a returning player watches their whole balance tick in.
		shown = profile.Cash
	else
		local step = profile.Cash - (target :: number)
		if step ~= 0 then
			if GameConfig.cashStepIsLump(step, routineStep) then
				counting = true
			end
			routineStep = GameConfig.cashRoutineStep(routineStep, step)
		end
	end
	target = profile.Cash
	if type(profile.Speed) == "number" then
		if speedTarget == nil then
			speedShown = profile.Speed
		end
		speedTarget = profile.Speed
	end
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	else
		warn("[Seed] ProfileUpdated never arrived; the readout will stay blank.")
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		-- (ok, profile, persistent) -- the same shape PlayerDataService fires.
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
end

RunService.RenderStepped:Connect(function(dt)
	local want = target
	if want == nil then
		return
	end
	-- Ease, but never fall behind: if the gap is large the catch-up is quick,
	-- and the last fraction of a cash unit is snapped so the label cannot sit
	-- forever one short of the truth.
	local gap = want - shown
	local landed = math.abs(gap) < 0.5
	if landed then
		shown = want
	else
		shown += gap * math.min(1, dt * 6)
	end
	-- GameConfig.money, not compact: one precision at every size and never
	-- rounded up (see A BALANCE IS SPELLED DIFFERENTLY FROM A PRICE).
	local text = "$" .. GameConfig.money(shown)
	if amount.Text ~= text then
		amount.Text = text
		-- The card sits off the end of this string, so it moves when the string
		-- does. Only on CHANGE -- placing it every frame would be arithmetic
		-- sixty times a second for a number that mostly is not moving.
		if buff.Visible then
			placeBuff()
		end
		-- And the block is placed again only if it outgrew its reservation.
		if groupWidth() > placedFor then
			placeCorner()
		end
		local now = os.clock()
		if now - lastTickAt >= (if counting then TICKS.CountSeconds else TICKS.RoutineSeconds) then
			lastTickAt = now
			SoundKit.play("CashTick", if counting then nil else ROUTINE_TICK)
		end
	end
	-- A lump is counted until the readout lands on it; after that, whatever
	-- arrives is routine again unless it is a lump of its own.
	if landed then
		counting = false
	end

	local wantSpeed = speedTarget
	if wantSpeed then
		local sgap = wantSpeed - speedShown
		if math.abs(sgap) < 0.5 then
			speedShown = wantSpeed
		else
			speedShown += sgap * math.min(1, dt * 6)
		end
		-- No "SPD" prefix: the shoe IS the label, exactly as the reference has
		-- an icon and a bare number.
		local stext = GameConfig.compact(speedShown)
		if speed.Text ~= stext then
			speed.Text = stext
			if groupWidth() > placedFor then
				placeCorner()
			end
		end
	end
end)
