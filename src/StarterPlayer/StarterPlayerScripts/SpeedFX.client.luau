--!strict
-- Steal a Seed :: SpeedFX
--
-- Two pieces of feedback for the one stat you grind: a `+N` that pops off the
-- character when the treadmill pays, and a streak behind you when you are
-- actually moving fast.
--
--==============================================================================
-- NO SECOND REMOTE
--
-- The pop is driven by DIFFING profile.Speed off the ProfileUpdated packet that
-- already arrives four times a second. The server does not announce "you earned
-- 2"; the client notices the number went up and says so. One less remote, and
-- it is automatically correct for any source of Speed added later.
--
--==============================================================================
-- THE STREAK IS READ OFF WalkSpeed, NOT OFF THE SCORE
--
-- Speed SCORE is what you own; WalkSpeed is what you are doing. The streak is
-- about motion, so it watches the humanoid -- which means it also appears when
-- a heavy pod is slowing you down and does not, and that is correct: it should
-- reflect how fast you are actually going home.
--==============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ACCENT = Color3.fromRGB(142, 196, 62)
--==============================================================================
-- IT IS A STREAK NOW, NOT A LABEL
--
-- This and the plant's `+$N` were the same object: GothamBlack, lime, a
-- three-pixel ink outline, the same rise and the same fade. The only thing
-- separating them was the shoe below -- 22 pixels, which at the 90-stud draw
-- distance these are read from is four. A player could not tell what had just
-- paid them, which is the entire job of a floating number.
--
-- See GameConfig.Pops for what each is now. The short version: this one is
-- narrow, sharp, slanted by the typeface itself, and it slides sideways as it
-- rises so it reads as being LEFT BEHIND.
--==============================================================================
local POP = GameConfig.Pops.Speed
-- The shoe's blue moved into GameConfig.Pops.Speed, where it is now the foot of
-- the number's own gradient rather than a lone accent beside it -- so the icon
-- and the digits are one object instead of a green label wearing a blue badge.

--==============================================================================
-- THE GATE IS AN ABSOLUTE MARGIN, NOT A MULTIPLIER
--
-- It was walkSpeedFor(0) * 1.55 = 24.8, and the curve is far flatter than that
-- assumed -- Scale is 20,000, so:
--
--     Speed   180  ->  WalkSpeed 17.20
--     Speed   400  ->  WalkSpeed 18.65
--     Speed 1,265  ->  WalkSpeed 24.80   <- where the old gate sat
--
-- Twenty-one minutes of milling before the streak ever appeared once, which is
-- why the lane trail was never seen. A margin ABOVE the floor scales with the
-- curve instead of fighting it: base + 1.2 lands at ~180 Speed, about ninety
-- seconds on the belt, so a first session gets the hint it is meant to get.
--
-- Still strictly above base 16, so it is off for a player who has never milled,
-- and the MoveDirection test below keeps it off when standing still.
--==============================================================================
local STREAK_AT = GameConfig.walkSpeedFor(0) + 1.2
-- Fully opaque by this much over the gate, so it starts as a hint and grows.
local STREAK_FULL_AT = STREAK_AT + 14

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedSpeedFX")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedSpeedFX"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = playerGui

--==============================================================================
-- THE POP
--
-- A small POOL rather than one Instance.new per payout. The treadmill pays once
-- a second for as long as somebody stands on it, which over a long session is
-- thousands of billboards created and collected for no reason.
--==============================================================================
local POOL_SIZE = 5
local pool: { BillboardGui } = {}
local nextInPool = 1

for i = 1, POOL_SIZE do
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Pop" .. i
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(POP.Width, POP.Height)
	billboard.Enabled = false
	billboard.MaxDistance = 90
	billboard.Parent = gui

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -26, 1, 0)
	label.Position = UDim2.fromOffset(26, 0)
	label.BackgroundTransparency = 1
	label.Font = POP.Font
	label.TextScaled = true
	-- White, because the gradient below MULTIPLIES against it. Tinting here as
	-- well would take the blue somewhere muddy.
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = billboard

	--==========================================================================
	-- WHITE AT THE HEAD, BLUE AT THE FOOT
	--
	-- The same vertical gradient the cash pop uses, in the opposite temperature.
	-- Two numbers with the same MECHANISM and opposite palettes read as a pair
	-- of related things rather than as two unrelated bits of UI.
	--==========================================================================
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(POP.Top, POP.Bottom)
	gradient.Rotation = 90
	gradient.Parent = label

	--== THE SHOE ==--
	-- Drawn from two rounded frames rather than set as a glyph. Most of Gotham's
	-- symbol range renders as tofu boxes in this engine -- checked, and a
	-- trainer emoji is one of them -- so a shoe made of rectangles is the only
	-- one guaranteed to be a shoe on every device.
	local shoe = Instance.new("Frame")
	shoe.Name = "Shoe"
	shoe.Size = UDim2.fromOffset(22, 20)
	shoe.Position = UDim2.fromOffset(0, 5)
	shoe.BackgroundTransparency = 1
	shoe.Parent = billboard

	local upper = Instance.new("Frame")
	upper.Name = "Upper"
	upper.Size = UDim2.fromOffset(14, 11)
	upper.Position = UDim2.fromOffset(6, 0)
	upper.BackgroundColor3 = POP.Bottom
	upper.BorderSizePixel = 0
	upper.Parent = shoe
	local upperCorner = Instance.new("UICorner")
	upperCorner.CornerRadius = UDim.new(0, 5)
	upperCorner.Parent = upper

	local sole = Instance.new("Frame")
	sole.Name = "Sole"
	sole.Size = UDim2.fromOffset(22, 7)
	sole.Position = UDim2.fromOffset(0, 10)
	sole.BackgroundColor3 = POP.Bottom
	sole.BorderSizePixel = 0
	sole.Parent = shoe
	local soleCorner = Instance.new("UICorner")
	soleCorner.CornerRadius = UDim.new(0, 3)
	soleCorner.Parent = sole

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = POP.OutlineThickness
	-- A cooler ink than the cash pop's, so even the outline is a different
	-- temperature at a distance where the letters have stopped being letters.
	stroke.Color = POP.Outline
	stroke.Parent = label

	pool[i] = billboard
end

local function pop(amount: number)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
	local billboard = pool[nextInPool]
	nextInPool += 1
	if nextInPool > POOL_SIZE then
		nextInPool = 1
	end

	local label = billboard:FindFirstChild("Label") :: TextLabel
	--==========================================================================
	-- COMPACTED, BECAUSE AN OVERCLOCKED MILL PAYS 52,428,800 A SECOND
	--
	-- This printed the raw integer, which was fine while the top tier paid 50
	-- and became unreadable the moment overclocking existed: a nine-digit number
	-- in a 90-pixel billboard, once a second, forever. `+52.4M` is the same fact
	-- in five characters.
	--
	-- Still floored to at least 1, so a fractional tick never pops "+0".
	--==========================================================================
	label.Text = "+" .. GameConfig.compact(math.max(1, math.floor(amount + 0.5)))
	label.TextTransparency = 0
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	billboard.Adornee = head
	local start = Vector3.new((nextInPool - 3) * 0.35, 1.6, 0)
	billboard.StudsOffset = start
	billboard.Enabled = true

	--==========================================================================
	-- UP AND SIDEWAYS, NOT STRAIGHT UP
	--
	-- The cash pop climbs vertically because money is not going anywhere. This
	-- one slides as it rises, alternating direction by pool slot -- which stops
	-- consecutive pops stacking into an illegible column AND makes the number
	-- read as something the player has run out from under. A speed readout that
	-- lifts off gently is the one shape it must not have.
	--==========================================================================
	local sideways = if nextInPool % 2 == 0 then POP.DriftStuds else -POP.DriftStuds
	local rise = TweenService:Create(billboard,
		TweenInfo.new(POP.Seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = start + Vector3.new(sideways, POP.RiseStuds, 0) })
	rise:Play()

	-- Held briefly, then faded -- one tween with a delay rather than a tween and
	-- a task.delay that can outlive the slot it belongs to.
	local hold = POP.Seconds * POP.Hold
	local fade = TweenInfo.new(POP.Seconds - hold, Enum.EasingStyle.Quad,
		Enum.EasingDirection.In, 0, false, hold)
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	if stroke then
		TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
	end
	local shoe = billboard:FindFirstChild("Shoe")
	if shoe then
		for _, piece in ipairs(shoe:GetChildren()) do
			if piece:IsA("Frame") then
				piece.BackgroundTransparency = 0
				TweenService:Create(piece, fade, { BackgroundTransparency = 1 }):Play()
			end
		end
	end
	task.delay(POP.Seconds + 0.05, function()
		-- Only hide it if nothing else has claimed this slot since.
		if label.TextTransparency >= 1 then
			billboard.Enabled = false
		end
	end)
end

--==============================================================================
-- WATCHING THE SCORE
--==============================================================================
local lastSpeed: number? = nil

local function receive(profile: any)
	if type(profile) ~= "table" or type(profile.Speed) ~= "number" then
		return
	end
	local now = profile.Speed
	local before = lastSpeed
	lastSpeed = now
	-- The first packet is not a gain, it is finding out where you already were.
	if before and now > before + 0.05 then
		pop(now - before)
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
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
end

--==============================================================================
-- THE STREAK MOVED
--
-- It used to live here as a local-player-only Trail whose job was to hold a
-- LINE while the ghosts carried the reading -- which is why it deliberately
-- held itself faint. The ghosts are gone and the ribbon is now the whole
-- effect, so it is built per player down in THE TRAIL alongside the tier that
-- drives it. Two systems drawing one ribbon was the arrangement worth ending.
--==============================================================================

--==============================================================================
-- THE RUN CYCLE ON THE MILL
--
-- Occupancy pays without touching a key, which is correct and looks wrong: the
-- character stands on a moving belt like it is a box. So while the OnTreadmill
-- attribute is set, the run animation plays regardless of input.
--
-- The animation id is read off the character's own Animate script rather than
-- hardcoded, so a player with a purchased run animation trains in THEIR run,
-- and there is no asset id in this repo to rot.
--
-- Priority Action, so it beats the idle the default Animate script is playing.
--==============================================================================
local millTrack: AnimationTrack? = nil

--==============================================================================
-- WHICH BELT IS UNDER THE PLAYER
--
-- The server says OnTreadmill and nothing else, which was all the FX needed
-- until the belt had a speed worth matching. Rather than add a message, the
-- nearest tagged belt is the one being stood on -- the attribute only goes up
-- while the player is standing on one, so there is no ambiguity to resolve.
--==============================================================================
local function beltUnderPlayer(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local nearest: BasePart? = nil
	local best = math.huge
	for _, belt in ipairs(CollectionService:GetTagged(GameConfig.Tags.Treadmill)) do
		if belt:IsA("BasePart") then
			local d = (belt.Position - (root :: BasePart).Position).Magnitude
			if d < best then
				best = d
				nearest = belt
			end
		end
	end
	return if best < 24 then nearest else nil
end

--==============================================================================
-- FEET AT THE SPEED OF THE BELT
--
-- Roblox's own Animate script scales the run cycle by speed/16, which is what
-- keeps a running character's feet on the ground. A character on a mill does not
-- move, so nothing did that division for it -- and the result was a sprint over
-- a surface crawling at a flat 5.5 studs a second.
--
-- Same number the chevrons scroll at, off the same attribute.
--==============================================================================
local function matchBeltCadence()
	local track = millTrack
	if not track then
		return
	end
	local belt = beltUnderPlayer()
	local studs = (belt and tonumber(belt:GetAttribute("BeltSpeed")))
		or GameConfig.Mill.Tiers[1].beltStuds
	track:AdjustSpeed(studs / GameConfig.Mill.RunCycleStuds)
end

local function stopMillRun()
	if millTrack then
		millTrack:Stop(0.2)
		millTrack = nil
	end
end

local function startMillRun()
	if millTrack then
		return
	end
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local animate = character and character:FindFirstChild("Animate")
	local run = animate and (animate:FindFirstChild("run") or animate:FindFirstChild("walk"))
	local source = run and run:FindFirstChildOfClass("Animation")
	if not (animator and source and source.AnimationId ~= "") then
		return
	end
	local clip = Instance.new("Animation")
	clip.AnimationId = source.AnimationId
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(clip)
	end)
	if not ok or not track then
		return
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(0.2)
	millTrack = track
	matchBeltCadence()
end

player:GetAttributeChangedSignal(GameConfig.Attributes.OnTreadmill):Connect(function()
	if player:GetAttribute(GameConfig.Attributes.OnTreadmill) then
		startMillRun()
	else
		stopMillRun()
	end
end)
player.CharacterAdded:Connect(function()
	-- The old track belonged to the old character's Animator.
	millTrack = nil
end)

--==============================================================================
-- THE TRAIL
--
-- Seven tiers, one Trail per character, and nothing is cloned. See
-- GameConfig.Afterimage for what each tier is and why the ladder is shaped the
-- way it is.
--
-- WHAT THIS REPLACED, AND WHY IT MATTERS HERE. The old system emitted copies of
-- the character -- up to four alive at once, fifteen parts each, respawned every
-- few studs for as long as you ran, with a pool per player and a per-frame walk
-- over every part of every echo to repaint it. All of that is gone. What is left
-- is one instance per player and a property write.
--
-- The tiers did not change. Their names, their unlock scores and their palettes
-- are the ones that shipped; only the thing expressing them changed.
--==============================================================================
local FX = GameConfig.Afterimage
local TIER_ATTR = GameConfig.Attributes.SpeedVisualTier
local CARRY_ATTR = GameConfig.Attributes.CarrySpeedMultiplier

local QUALITY_FULL = "Full"
local QUALITY_REDUCED = "Reduced"
local QUALITY_OFF = "Off"

--==============================================================================
-- A PHONE GETS A SHORTER RIBBON, NOT A DIFFERENT EFFECT
--
-- The whole point of moving off ghosts is that every machine can afford every
-- tier. Reduced trims length and width; Off is the only setting that takes the
-- effect away, and it exists for people who simply do not want it.
--==============================================================================
-- TOUCH ALONE IS NOT A PHONE. A laptop with a touchscreen has a keyboard, and
-- giving it the phone budget would have quietly downgraded a machine that can
-- afford everything. The original made this distinction and it is worth keeping.
local UserInputService = game:GetService("UserInputService")
local onPhone = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local quality = if onPhone then QUALITY_REDUCED else QUALITY_FULL

--==============================================================================
-- WHAT A LOAD DOES TO A TIER
--
-- Reads the SERVER'S multiplier off the player. Never re-derived from a size:
-- the attribute is the same number CarryService multiplied into WalkSpeed, and
-- a client that worked it out for itself would be a client that could decide
-- not to.
--
-- Missing means unloaded. A player whose attribute has not arrived yet is one
-- who is not carrying anything -- the server writes it the moment they pick
-- something up, and defaulting the other way would delete the effect for
-- everybody during the first second of a session.
--
-- The laden band returns a COPY, cached per tier, because the row is frozen
-- shared config and is every player's -- and because this runs every frame a
-- loaded player is moving, where allocating a table to hold four numbers is the
-- kind of garbage that shows up as a stutter an hour later.
--==============================================================================
local reducedCache: { [any]: any } = {}

local function carriedTier(who: Player, tier: any): any
	if not tier then
		return nil
	end
	local multiplier = who:GetAttribute(CARRY_ATTR)
	if type(multiplier) ~= "number" or multiplier ~= multiplier
		or multiplier > FX.CarryFullAbove then
		return tier
	end
	-- Heavy. Nothing at all -- this is the branch that guarantees a Colossal
	-- haul is silent at EVERY tier, including the rainbow.
	if multiplier < FX.CarryReducedAbove then
		return nil
	end
	local cached = reducedCache[tier]
	if not cached then
		cached = table.clone(tier)
		cached.Lifetime = tier.Lifetime * FX.CarryLifetimeScale
		cached.WidthStuds = tier.WidthStuds * FX.CarryWidthScale
		cached.HeadTransparency = math.min(0.98, tier.HeadTransparency + FX.CarryFadeAdd)
		reducedCache[tier] = cached
	end
	return cached
end

--==============================================================================
-- COLOUR
--
-- A Trail takes a ColorSequence, so a palette becomes stops along the ribbon
-- rather than a colour per echo. `Wave` slides those stops along it; the
-- rainbow ignores the palette and walks the hue wheel instead.
--==============================================================================
local function paletteSequence(tier: any, clock: number): ColorSequence
	if tier.Rainbow then
		local stops = {}
		local n = FX.RainbowStops
		for i = 0, n - 1 do
			local at = i / (n - 1)
			local hue = (at * 0.85 + clock * tier.Wave) % 1
			table.insert(stops, ColorSequenceKeypoint.new(at,
				Color3.fromHSV(hue, 0.72, 1)))
		end
		return ColorSequence.new(stops)
	end

	local palette = tier.Palette
	if #palette == 1 then
		return ColorSequence.new(palette[1])
	end
	-- Roblox requires the first stop at 0 and the last at 1, so the palette is
	-- sampled at even positions and offset by the wave rather than rotated --
	-- rotating it would move the endpoints off 0 and 1 and be rejected.
	local stops = {}
	local n = math.min(#palette + 1, 20)
	for i = 0, n - 1 do
		local at = i / (n - 1)
		local pick = ((at + clock * tier.Wave) % 1) * #palette
		local lo = math.floor(pick) % #palette
		local frac = pick - math.floor(pick)
		local a = palette[lo + 1]
		local b = palette[(lo + 1) % #palette + 1]
		table.insert(stops, ColorSequenceKeypoint.new(at, a:Lerp(b, frac)))
	end
	return ColorSequence.new(stops)
end

--==============================================================================
-- ONE RIBBON PER CHARACTER
--
-- A Trail draws between a PAIR of attachments and their separation is its
-- width, so changing width means moving an attachment -- which is why WidthStuds
-- is a tier property rather than a Trail property.
--==============================================================================
type Entry = {
	character: Model,
	root: BasePart,
	humanoid: Humanoid,
	trail: Trail,
	a0: Attachment,
	a1: Attachment,
	isLocal: boolean,
	lastPos: Vector3?,
	width: number,
}

local tracked: { [Player]: Entry } = {}

local function untrack(who: Player)
	local entry = tracked[who]
	if not entry then
		return
	end
	tracked[who] = nil
	if entry.trail.Parent then entry.trail:Destroy() end
	if entry.a0.Parent then entry.a0:Destroy() end
	if entry.a1.Parent then entry.a1:Destroy() end
end

local function track(who: Player, character: Model)
	untrack(who)
	if quality == QUALITY_OFF then
		return
	end
	task.spawn(function()
		local root = character:WaitForChild("HumanoidRootPart", 10)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not (root and root:IsA("BasePart") and humanoid and humanoid:IsA("Humanoid")) then
			return
		end
		if character.Parent == nil or who.Character ~= character then
			return
		end
		local a0 = Instance.new("Attachment")
		a0.Name = "SeedStreakA"
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = "SeedStreakB"
		a1.Parent = root

		local t = Instance.new("Trail")
		t.Name = "SeedStreak"
		t.Attachment0 = a0
		t.Attachment1 = a1
		t.MinLength = 0.2
		t.FaceCamera = true
		t.Enabled = false
		t.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), ACCENT)
		t.Parent = root

		tracked[who] = {
			character = character, root = root :: BasePart,
			humanoid = humanoid :: Humanoid, trail = t, a0 = a0, a1 = a1,
			isLocal = who == player, lastPos = nil, width = -1,
		}
	end)
end

--==============================================================================
-- OFF ITS FEET IS OFF
--
-- Dead, ragdolled, thrown or seated: the ribbon is a statement about running and
-- none of those are running.
--==============================================================================
local function isRunning(entry: Entry): boolean
	local humanoid = entry.humanoid
	if humanoid.Health <= 0 or humanoid.PlatformStand then
		return false
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Dead
		or state == Enum.HumanoidStateType.Physics
		or state == Enum.HumanoidStateType.Seated then
		return false
	end
	local v = entry.root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude > FX.MinGroundSpeed
end

--==============================================================================
-- THE ONE LOOP
--
-- Colour is repainted on a fixed clock rather than every frame, so a wave moves
-- at the same speed on a 144 Hz machine as on a 30 Hz one -- and so the tiers
-- whose colour does not move are painted once and never touched again.
--==============================================================================
local colourClock = 0
local sinceColour = 0

RunService.Heartbeat:Connect(function(dt)
	colourClock += dt
	sinceColour += dt
	local repaint = sinceColour >= FX.ColourInterval
	if repaint then
		sinceColour = 0
	end
	if quality == QUALITY_OFF then
		return
	end

	local mine = tracked[player]
	local here = if mine and mine.root.Parent then mine.root.Position else nil

	for who, entry in pairs(tracked) do
		if not (entry.character.Parent and entry.root.Parent and entry.trail.Parent) then
			untrack(who)
		else
			local index = who:GetAttribute(TIER_ATTR)
			local tier = if type(index) == "number" then FX.Tiers[index] else nil
			tier = carriedTier(who, tier)

			--==============================================================
			-- A JUMP THIS BIG WAS NOT A RUN
			--
			-- A Trail draws a segment between where it was and where it is, so
			-- a respawn would smear a ribbon straight across the map. Disabling
			-- it for the frame that covers the gap is what breaks the segment.
			--==============================================================
			local at = entry.root.Position
			local teleported = entry.lastPos ~= nil
				and (at - entry.lastPos).Magnitude > FX.TeleportStuds
			entry.lastPos = at

			local inRange = entry.isLocal
				or (here ~= nil and (at - here).Magnitude <= FX.RemoteMaxStuds)

			local want = tier ~= nil and not teleported and inRange and isRunning(entry)
			if entry.trail.Enabled ~= want then
				entry.trail.Enabled = want
			end

			if want and tier then
				local scale = if quality == QUALITY_REDUCED
					then FX.ReducedLifetimeScale else 1
				local widthScale = if quality == QUALITY_REDUCED
					then FX.ReducedWidthScale else 1

				entry.trail.Lifetime = tier.Lifetime * scale
				entry.trail.LightEmission = tier.LightEmission

				--======================================================
				-- MOVING AN ATTACHMENT IS THE ONLY WAY TO CHANGE WIDTH
				--
				-- Guarded so it only writes when the width actually changes:
				-- this runs every frame for every running player, and a Trail
				-- rebuilds when its attachments move.
				--======================================================
				local width = tier.WidthStuds * widthScale
				if math.abs(entry.width - width) > 1e-3 then
					entry.width = width
					entry.a0.Position = Vector3.new(0, width * 0.5, 0.4)
					entry.a1.Position = Vector3.new(0, -width * 0.5, 0.4)
				end

				local head = tier.HeadTransparency
				if tier.Shimmer > 0 then
					head = math.clamp(head
						- math.sin(colourClock * 24) * tier.Shimmer, 0, 1)
				end
				entry.trail.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, head),
					NumberSequenceKeypoint.new(1, 1),
				})

				-- Static tiers are painted once. `width` doubles as the flag for
				-- "this ribbon has been set up at all" -- it starts at -1.
				if repaint and (tier.Wave > 0 or tier.Rainbow) then
					entry.trail.Color = paletteSequence(tier, colourClock)
				elseif entry.width == width and tier.Wave == 0 and not tier.Rainbow then
					entry.trail.Color = paletteSequence(tier, 0)
				end
			end
		end
	end
end)

--==============================================================================
-- WHO IS TRACKED
--
-- Everybody, including the local player. Ghosts were emitted for everyone while
-- the ribbon was local-only; keeping that split would have meant every other
-- player silently lost their effect the day the ghosts went.
--==============================================================================
local function watchPlayer(who: Player)
	if who.Character then
		track(who, who.Character)
	end
	who.CharacterAdded:Connect(function(character)
		track(who, character)
	end)
	who.CharacterRemoving:Connect(function()
		untrack(who)
	end)
end

for _, who in ipairs(Players:GetPlayers()) do
	watchPlayer(who)
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(untrack)

--==============================================================================
-- THE SEAM A SETTINGS PANEL WILL USE
--
-- Cheaper than it was: the budget no longer decides how many objects exist, so
-- a quality change is a rebuild of one instance per player rather than of a
-- pool of sixty parts.
--==============================================================================
local function setQuality(mode: string)
	if mode ~= QUALITY_FULL and mode ~= QUALITY_REDUCED and mode ~= QUALITY_OFF then
		return
	end
	if quality == mode then
		return
	end
	quality = mode
	for _, who in ipairs(Players:GetPlayers()) do
		local character = who.Character
		untrack(who)
		if character and mode ~= QUALITY_OFF then
			track(who, character)
		end
	end
end

--==============================================================================
-- DRIVEN BY AN ATTRIBUTE, NOT A GLOBAL
--
-- `player:SetAttribute("SeedAfterimageQuality", "Reduced")` and that is the
-- whole interface. A settings panel writes it, this reads it, and anything at
-- all can ask what a machine is rendering -- which a `_G` function cannot
-- answer from outside its own VM.
--
-- Applied on connect as well as on change, so a value written before this
-- script ran is not lost.
--==============================================================================
player:GetAttributeChangedSignal(FX.QualityAttribute):Connect(function()
	local want = player:GetAttribute(FX.QualityAttribute)
	if type(want) == "string" then
		setQuality(want)
	end
end)
do
	local want = player:GetAttribute(FX.QualityAttribute)
	if type(want) == "string" then
		setQuality(want)
	end
end
