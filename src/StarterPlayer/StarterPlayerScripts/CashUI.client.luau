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

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local ATTR = GameConfig.Attributes

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--== sampled out of money speed gui.png ==--
local SPEED_BLUE = Color3.fromRGB(25, 144, 255)
local CASH_GREEN = Color3.fromRGB(38, 255, 0)
local OUTLINE = Color3.fromRGB(0, 0, 0)
local BADGE_GOLD = Color3.fromRGB(255, 216, 0)
local SHOE_LIGHT = Color3.fromRGB(223, 242, 252)
local WHITE = Color3.fromRGB(255, 255, 255)

local SPEED_SIZE = 39
local CASH_SIZE = 47

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
gui.Parent = playerGui

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

--==============================================================================
-- THE STACK
--
-- Speed on top, cash under it and larger. Both the order and the size difference
-- are the reference's. Anchored to the BOTTOM edge so the cash line stays put
-- and the speed line sits off it.
--==============================================================================
local root = Instance.new("Frame")
root.Name = "Corner"
root.AnchorPoint = Vector2.new(0, 1)
root.Position = UDim2.new(0, 12, 1, -10)
root.Size = UDim2.fromOffset(340, 108)
root.BackgroundTransparency = 1
root.Parent = gui

--==============================================================================
-- THE SHOE
--
-- Drawn from frames, not set as a glyph. Most of Gotham's symbol range renders
-- as tofu boxes in this engine -- SpeedFX paid for that with a trainer emoji,
-- and both rail icons are built the same way for the same reason.
--
-- A sneaker pointing LEFT: white sole, blue upper with a taller heel, a pale
-- stripe across it, and the gold badge overlapping its bottom-right.
--==============================================================================
local shoe = Instance.new("Frame")
shoe.Name = "Shoe"
shoe.AnchorPoint = Vector2.new(0, 1)
shoe.Position = UDim2.new(0, 0, 0, 44)
shoe.Size = UDim2.fromOffset(50, 38)
shoe.BackgroundTransparency = 1
shoe.Parent = root

local sole = Instance.new("Frame")
sole.Name = "Sole"
sole.Position = UDim2.fromOffset(0, 26)
sole.Size = UDim2.fromOffset(42, 11)
sole.BackgroundColor3 = WHITE
sole.BorderSizePixel = 0
sole.Parent = shoe
corner(sole, 5)

local heel = Instance.new("Frame")
heel.Name = "Heel"
heel.Position = UDim2.fromOffset(15, 4)
heel.Size = UDim2.fromOffset(27, 24)
heel.BackgroundColor3 = SPEED_BLUE
heel.BorderSizePixel = 0
heel.Parent = shoe
corner(heel, 9)

local toe = Instance.new("Frame")
toe.Name = "Toe"
toe.Position = UDim2.fromOffset(0, 14)
toe.Size = UDim2.fromOffset(23, 14)
toe.BackgroundColor3 = SPEED_BLUE
toe.BorderSizePixel = 0
toe.Parent = shoe
corner(toe, 7)

local stripe = Instance.new("Frame")
stripe.Name = "Stripe"
stripe.Position = UDim2.fromOffset(4, 19)
stripe.Size = UDim2.fromOffset(26, 5)
stripe.Rotation = -10
stripe.BackgroundColor3 = SHOE_LIGHT
stripe.BorderSizePixel = 0
stripe.Parent = shoe
corner(stripe, 2)

--== the gold plus badge ==--
local badge = Instance.new("Frame")
badge.Name = "Badge"
badge.Position = UDim2.fromOffset(26, 15)
badge.Size = UDim2.fromOffset(23, 23)
badge.BackgroundColor3 = BADGE_GOLD
badge.BorderSizePixel = 0
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
	piece.Parent = badge
	corner(piece, 1)
end

--==============================================================================
-- THE NUMBERS
--==============================================================================
local function outlined(name: string, size: number, colour: Color3,
	thickness: number): TextLabel
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
	return label
end

local speed = outlined("Speed", SPEED_SIZE, SPEED_BLUE, 2)
speed.AnchorPoint = Vector2.new(0, 1)
speed.Position = UDim2.new(0, 56, 0, 44)
speed.Size = UDim2.fromOffset(260, SPEED_SIZE + 4)

local amount = outlined("Amount", CASH_SIZE, CASH_GREEN, 3)
amount.AnchorPoint = Vector2.new(0, 1)
amount.Position = UDim2.new(0, 0, 1, 0)
amount.Size = UDim2.fromOffset(300, CASH_SIZE + 4)

--==============================================================================
-- WHAT THE SPEED IS FOR
--
-- The score on its own is a number going up. This is the line that says what it
-- is going up TOWARD: the next trail, the next biome, the next walk speed --
-- and, while a Training Rush is running, what the mill is actually paying.
--
-- ONE ROTATING LINE, NOT A PANEL, AND NOT FOUR LABELS. Four facts would be four
-- rows of permanent furniture on a HUD that is two numbers and a shoe, and on a
-- phone that is most of the bottom of the screen. Rotating them costs one
-- label, needs no tap target to discover, and cannot be left open covering the
-- road.
--
-- It sits ABOVE the block rather than inside it, so nothing established moves:
-- the shoe, the speed and the cash are exactly where they were.
--
-- ASCII ONLY. Roblox drops a lot of punctuation to blank boxes -- this project
-- has already lost a set of rotation arrows that way -- so this uses letters,
-- digits, slash and '>' and nothing else.
--==============================================================================
local PROGRESS_TEXT = Color3.fromRGB(226, 238, 250)
local RUSH_TEXT = Color3.fromRGB(250, 215, 80)

local progress = Instance.new("TextLabel")
progress.Name = "Progress"
progress.BackgroundTransparency = 1
progress.Font = Enum.Font.GothamMedium
progress.TextSize = 15
progress.TextColor3 = PROGRESS_TEXT
progress.TextXAlignment = Enum.TextXAlignment.Left
progress.TextYAlignment = Enum.TextYAlignment.Center
progress.TextTruncate = Enum.TextTruncate.AtEnd
progress.AnchorPoint = Vector2.new(0, 1)
progress.Position = UDim2.new(0, 4, 0, -2)
progress.Size = UDim2.fromOffset(336, 18)
progress.Text = ""
progress.Parent = root
do
	local edge = Instance.new("UIStroke")
	edge.Color = OUTLINE
	edge.Thickness = 2
	edge.Parent = progress
end

--==============================================================================
-- THE THREE THINGS IT ROTATES THROUGH
--
-- Each answers its own end of the ladder, so a maxed player is told they are
-- maxed rather than shown a blank or a stale target.
--==============================================================================
local ROTATE_SECONDS = 3.2

local function nextTrailLine(score: number): string
	for _, tier in ipairs(GameConfig.Afterimage.Tiers) do
		if score < tier.From then
			return string.format("NEXT TRAIL  %s  %s / %s",
				string.upper(tier.Name),
				GameConfig.compact(score), GameConfig.compact(tier.From))
		end
	end
	local tiers = GameConfig.Afterimage.Tiers
	local last = tiers[#tiers]
	return string.format("TRAIL  %s  MAX",
		if last then string.upper(last.Name) else "MAX")
end

local function nextBiomeLine(score: number): string
	local bestName, bestAt = nil, nil
	for _, biome in ipairs(BiomeData.Biomes) do
		local need = biome.RecommendedSpeed
		if type(need) == "number" and need > score
			and (bestAt == nil or need < bestAt) then
			bestName, bestAt = biome.DisplayName, need
		end
	end
	if bestName and bestAt then
		return string.format("NEXT BIOME  %s  %s / %s",
			string.upper(bestName),
			GameConfig.compact(score), GameConfig.compact(bestAt))
	end
	return "ALL BIOMES RECOMMENDED"
end

local function walkSpeedLine(score: number): string
	local now = GameConfig.walkSpeedFor(score)
	for _, anchor in ipairs(GameConfig.Speed.Anchors) do
		if score < anchor[1] then
			return string.format("WALKSPEED  %d > %d", math.floor(now), anchor[2])
		end
	end
	return string.format("WALKSPEED  %d  MAX", math.floor(now))
end

local ROTATION = { nextTrailLine, nextBiomeLine, walkSpeedLine }
local rotateClock = 0
local rotateIndex = 1
-- How often the line is rebuilt. Fast enough that a Training Rush countdown
-- ticks smoothly, slow enough that the formatting is not a per-frame cost.
local REFRESH_SECONDS = 0.25
local refreshClock = 0

--==============================================================================
-- TRAINING RUSH TAKES THE LINE WHILE IT IS RUNNING
--
-- Both numbers are read straight off the attributes the SERVER publishes -- the
-- multiplier it actually paid on and the charge it has left. Nothing here
-- derives either, which is the point: a client that computed the multiplier
-- could be talked into showing 4x forever.
--
-- x1.0 IS NOT A RUSH, AND MUST NOT SAY IT IS. TreadmillService clears the
-- attribute rather than publishing 1, so a player standing on a mill with the
-- charge spent has no multiplier to show -- and printing "TRAINING RUSH x1.0"
-- at them for the rest of the session reads as a stuck HUD. Standing on a spent
-- mill gets the one fact that is actually actionable instead: the charge comes
-- back when you get off.
--==============================================================================
local function progressText(score: number): (string, Color3)
	local rush = player:GetAttribute(ATTR.TrainingRush)
	if type(rush) == "number" and rush > 1 then
		local charge = player:GetAttribute(ATTR.TrainingCharge)
		if type(charge) == "number" and charge > 0 then
			return string.format("TRAINING RUSH  x%.1f   %ds LEFT", rush, charge), RUSH_TEXT
		end
		return string.format("TRAINING RUSH  x%.1f", rush), RUSH_TEXT
	end
	if player:GetAttribute(ATTR.OnTreadmill) == true then
		local charge = player:GetAttribute(ATTR.TrainingCharge)
		if type(charge) == "number" and charge <= 0 then
			return "RUSH SPENT  IT REFILLS OFF THE MILL", RUSH_TEXT
		end
	end
	return ROTATION[rotateIndex](score), PROGRESS_TEXT
end

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
-- THE TICK IS EVERY THIRD STEP OF THE READOUT, NOT EVERY FRAME
--
-- The number eases toward the truth on RenderStepped, so a tick per frame would
-- be sixty ticks a second for as long as a bank is being counted in -- a buzz,
-- not a counter. Every third CHANGE of the printed text is roughly a tick per
-- two frames while the gap is wide and nothing at all once it lands, which is
-- the shape of the thing being described.
--
-- Deliberately NOT wired to CashPop's +$N. Every grown plant pays once a second
-- and a garden of twelve would be twelve ticks a second forever.
--==============================================================================
local tickCount = 0
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
	if math.abs(gap) < 0.5 then
		shown = want
	else
		shown += gap * math.min(1, dt * 6)
	end
	local text = "$" .. GameConfig.compact(shown)
	if amount.Text ~= text then
		amount.Text = text
		tickCount += 1
		if tickCount % 3 == 0 then
			SoundKit.play("CashTick")
		end
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
		end
	end

	--======================================================================
	-- THE ROTATION IS A CLOCK, AND THE LINE IS REBUILT FOUR TIMES A SECOND
	--
	-- Every branch above this one is a comparison; this one is string.format,
	-- which allocates. At sixty frames that is sixty throwaway strings a second
	-- on a phone, for a line that changes about as often as a clock does -- so
	-- it is gated to 4 Hz and the write is still on change.
	--
	-- Driven off the TARGET rather than the eased readout: the eased number is
	-- still counting up for a second after a payout and would make the milestone
	-- text flicker between two answers while it caught up.
	--======================================================================
	rotateClock += dt
	if rotateClock >= ROTATE_SECONDS then
		rotateClock -= ROTATE_SECONDS
		rotateIndex = rotateIndex % #ROTATION + 1
	end
	refreshClock += dt
	if refreshClock >= REFRESH_SECONDS then
		refreshClock -= REFRESH_SECONDS
		local ptext, pcolour = progressText(speedTarget or 0)
		if progress.Text ~= ptext then
			progress.Text = ptext
		end
		if progress.TextColor3 ~= pcolour then
			progress.TextColor3 = pcolour
		end
	end
end)
