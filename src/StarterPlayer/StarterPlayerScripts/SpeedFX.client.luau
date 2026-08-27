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
-- THE STREAK
--
-- One Trail, built once per character and re-enabled rather than rebuilt. Two
-- attachments on the root: a trail needs a pair and draws the ribbon between
-- them, so their separation is the ribbon's width.
--==============================================================================
local trail: Trail? = nil
local humanoid: Humanoid? = nil

local function fitCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "SeedStreakA"
	a0.Position = Vector3.new(-0.9, 0.6, 0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "SeedStreakB"
	a1.Position = Vector3.new(0.9, -0.9, 0.4)
	a1.Parent = root

	local t = Instance.new("Trail")
	t.Name = "SeedStreak"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = 0.32
	t.MinLength = 0.2
	t.LightEmission = 0.4
	t.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	t.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), ACCENT)
	t.Enabled = false
	t.Parent = root
	trail = t
end

if player.Character then
	task.spawn(fitCharacter, player.Character)
end
player.CharacterAdded:Connect(function(character)
	trail = nil
	task.spawn(fitCharacter, character)
end)

RunService.Heartbeat:Connect(function()
	local t, h = trail, humanoid
	if not (t and h and t.Parent) then
		return
	end
	-- Moving AND fast. Standing still at high WalkSpeed should not smear a
	-- ribbon across the plot.
	--
	-- MEASURED OFF VELOCITY, NOT MoveDirection. On the modern physics rig
	-- MoveDirection stayed 0.00 through a 39.2 stud walk, so a gate built on it
	-- never opened once -- the streak was dead for that reason as much as for
	-- the threshold being too high. Velocity is what "moving" actually means.
	local root = h.RootPart
	local v = if root then root.AssemblyLinearVelocity else Vector3.zero
	local ground = Vector3.new(v.X, 0, v.Z).Magnitude
	local want = h.WalkSpeed >= STREAK_AT and ground > 2
	if t.Enabled ~= want then
		t.Enabled = want
	end
	if want then
		-- A HINT at the gate, a real streak well past it. Without this the first
		-- session gets the same ribbon as somebody who has milled for an hour,
		-- and the streak stops meaning anything.
		local strength = math.clamp(
			(h.WalkSpeed - STREAK_AT) / (STREAK_FULL_AT - STREAK_AT), 0, 1)
		local head = 0.82 - 0.5 * strength
		--==================================================================
		-- THE STREAK STEPS BACK SO THE GHOSTS HAVE ROOM
		--
		-- Both at full strength is a solid smear with no shape in it -- the
		-- echoes land inside a ribbon that is already opaque and simply do
		-- not read. The streak keeps the LINE and the ghosts carry the
		-- information, which is the only arrangement where having both is
		-- worth more than having either.
		--==================================================================
		local tier = player:GetAttribute(GameConfig.Attributes.SpeedVisualTier)
		if type(tier) == "number" and tier > 0 then
			head = math.max(head, GameConfig.Afterimage.TrailTransparencyFloor)
		end
		t.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, head),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
end)

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
-- THE AFTERIMAGE
--
-- Seven tiers. See GameConfig.Afterimage for what each one is -- every
-- threshold, colour, spacing, lifetime and animation setting lives there, and
-- there is deliberately not one `if score > N` anywhere in this file. This is
-- the machine; the table is the design.
--
--==============================================================================
-- THE SCORE QUALIFIES. THE MOVEMENT EMITS.
--
-- Two separate questions and they must not be merged. Standing still, dead,
-- ragdolled, mid-throw, teleporting, or crawling under a heavy pod all produce
-- nothing at any tier, because an afterimage is a statement about MOTION.
--
--==============================================================================
-- FIXED POOLS. NOTHING IS CLONED PER FRAME.
--
-- The naive build is character:Clone() per ghost, which at four ghosts every
-- five studs is a fifteen-part model built and thrown away several times a
-- second, forever, per player. Instead: ONE template read off the character when
-- it appears, a pool built once, and emitting is writing CFrames onto parts that
-- already exist.
--
-- HIGHER TIERS BUY COLOUR, NOT INSTANCES. The pool is four from tier 4 up and
-- never grows again. Rainbow Ascension costs exactly what Phase Runner costs in
-- parts; what it spends is a Color3 write at twelve hertz.
--
--==============================================================================
-- BODY ONLY
--
-- Direct BasePart children of the character and nothing else. That excludes
-- accessories (their parts live inside Accessory), tools (inside Tool), every
-- script, the Humanoid, and every ParticleEmitter -- all of which would either
-- cost far more than the ghost is worth or actively misbehave: a cloned Humanoid
-- tries to stand up, a cloned emitter keeps emitting, a cloned script runs.
--
-- Every ghost part is anchored, non-colliding, non-touching, non-queryable and
-- shadowless. A ghost must never be something the game can collide with, cast a
-- ray at, or light -- it is a smear, not an object.
--
--==============================================================================
-- ONE LOOP DRIVES ALL OF IT
--
-- Lifetime, transparency, colour, shimmer and expansion are all advanced from a
-- single Heartbeat over a single list. Not a Tween each and not a task.delay
-- each: at four ghosts a second per player that is hundreds of live objects a
-- minute whose only job is to count down, and none of them can be cancelled when
-- a player respawns mid-fade.
--
-- Colour is throttled INSIDE that loop rather than given its own: a wave nobody
-- can see move at 60 Hz does not need to be computed at 60 Hz.
--==============================================================================

local UserInputService = game:GetService("UserInputService")

local FX = GameConfig.Afterimage
local TIER_ATTR = GameConfig.Attributes.SpeedVisualTier
local CARRY_ATTR = GameConfig.Attributes.CarrySpeedMultiplier

--==============================================================================
-- WHAT THE LOAD DOES TO A TIER
--
-- Reads the SERVER'S multiplier off the player and returns a tier that has been
-- weakened, or nothing at all. Never re-derived from a weight: the attribute is
-- the same number CarryService multiplied into WalkSpeed, and a client that
-- worked it out for itself would be a client that could decide not to.
--
-- Missing means unloaded. A player whose attribute has not arrived yet is one
-- who is not carrying anything -- the server writes it the moment they pick
-- something up, and defaulting the other way would delete the effect for
-- everybody during the first second of a session.
--
-- The reduced band returns a COPY with three fields changed rather than mutating
-- the row, because the row is frozen shared config and is every player's.
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
	if multiplier < FX.CarryReducedAbove then
		--==================================================================
		-- HEAVY. NOTHING BUT THE TRAIL.
		--
		-- A maximum pod is 0.30, so this is the branch that guarantees a
		-- 10,000 kg haul is silent at EVERY tier -- including the rainbow,
		-- which the Speed threshold alone stopped being able to do the moment it
		-- dropped to 10 studs/s for tier 1's sake.
		--==================================================================
		return nil
	end
	-- Laden. Built once per tier and reused: this runs every frame a loaded
	-- player is moving, and allocating a table per frame to hold three numbers
	-- is the kind of garbage that only shows up as a stutter an hour later.
	local cached = reducedCache[tier]
	if not cached then
		cached = table.clone(tier)
		cached.Ghosts = math.min(tier.Ghosts, FX.CarryReducedGhosts)
		cached.SpacingStuds = tier.SpacingStuds * FX.CarryReducedSpacing
		cached.StartTransparency = math.min(0.98,
			tier.StartTransparency + FX.CarryReducedFade)
		reducedCache[tier] = cached
	end
	return cached
end

--==============================================================================
-- QUALITY IS ONE VARIABLE AND ONE FUNCTION
--
-- There is no settings panel yet. When there is, it writes here and nothing else
-- changes -- which is the difference between adding a setting and doing an
-- audit. Phones start Reduced without being asked: fewer ghosts and a slower
-- colour clock, but every tier and every animation intact. A phone at the top of
-- the ladder still gets the rainbow.
--==============================================================================
local QUALITY_FULL = "Full"
local QUALITY_REDUCED = "Reduced"
local QUALITY_OFF = "Off"

local onPhone = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local quality = if onPhone then QUALITY_REDUCED else QUALITY_FULL

local function maxGhostsFor(isLocal: boolean): number
	if quality == QUALITY_OFF then
		return 0
	end
	if quality == QUALITY_REDUCED then
		return FX.MobileMaxGhosts
	end
	return if isLocal then FX.LocalMaxGhosts else FX.RemoteMaxGhosts
end

local function colourInterval(): number
	local hz = if quality == QUALITY_REDUCED then FX.MobileColourHz else FX.ColourHz
	return 1 / math.max(1, hz)
end

--==============================================================================
-- STATE
--==============================================================================
type Ghost = {
	parts: { BasePart },
	sizes: { Vector3 },
	active: boolean,
	age: number,
	tier: any,
	phase: number,
}

type Tracked = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	source: { BasePart },
	-- Where each part sits from feet (0) to head (1). Measured once off the rig,
	-- because it is what lets a colour flow DOWN A BODY rather than paint a
	-- whole echo one shade.
	heights: { number },
	pool: { Ghost },
	nextGhost: number,
	lastPos: Vector3?,
	travelled: number,
	isLocal: boolean,
	folder: Folder,
}

local tracked: { [Player]: Tracked } = {}
local active: { Ghost } = {}
local buildPool: (Player, Model, Humanoid, BasePart) -> ()

local ghostRoot = Workspace:FindFirstChild("SeedAfterimage")
if ghostRoot then
	-- Rule 10: a Rojo re-sync re-runs this while the last run's ghosts are still
	-- standing in the world, anchored and invisible and never fading again.
	ghostRoot:Destroy()
end
ghostRoot = Instance.new("Folder")
ghostRoot.Name = "SeedAfterimage"
ghostRoot.Parent = Workspace

--==============================================================================
-- THE COLOUR ENGINE
--
-- One function for all seven tiers, driven entirely by the row's own fields.
-- Solid, per-ghost, down-the-body, travelling, and full-spectrum are the same
-- expression with different numbers -- which is why adding an eighth tier is a
-- row in a table and not a branch in here.
--
--     position = ghost's slot  +  height down the body  +  time
--
-- and that position is then read off either the hue wheel or the row's palette.
--==============================================================================
local function sampleAt(tier: any, position: number): Color3
	if tier.Rainbow then
		return Color3.fromHSV(position % 1, 0.82, 1)
	end
	local palette = tier.Palette
	local count = #palette
	if count == 1 then
		return palette[1]
	end
	local scaled = (position % 1) * count
	local index = math.floor(scaled) % count + 1
	local next_ = index % count + 1
	return palette[index]:Lerp(palette[next_], scaled % 1)
end

local function colourFor(tier: any, phase: number, height: number, clock: number): Color3
	local position = phase * (tier.GhostSpread or 0)
		+ (if tier.BodyGradient then (1 - height) * FX.BodyHueSpread else 0)
		+ clock * (tier.Wave or 0)
	return sampleAt(tier, position)
end

--==============================================================================
-- WHAT A GHOST IS MADE OF
--
-- Read off the character once. Direct children only, and the HumanoidRootPart is
-- skipped because it is invisible -- copying it would put an unlit box in the
-- middle of every echo.
--==============================================================================
local function bodyPartsOf(character: Model): { BasePart }
	local parts: { BasePart } = {}
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			table.insert(parts, child)
		end
	end
	return parts
end

local function heightsOf(source: { BasePart }): { number }
	local low, high = math.huge, -math.huge
	for _, part in ipairs(source) do
		low = math.min(low, part.Position.Y)
		high = math.max(high, part.Position.Y)
	end
	local span = math.max(high - low, 0.001)
	local out: { number } = {}
	for i, part in ipairs(source) do
		out[i] = (part.Position.Y - low) / span
	end
	return out
end

local function buildGhost(source: { BasePart }, parent: Folder): Ghost
	local parts: { BasePart } = {}
	local sizes: { Vector3 } = {}
	for _, live in ipairs(source) do
		local part = Instance.new("Part")
		part.Name = "Echo"
		part.Size = live.Size
		part.Shape = if live:IsA("Part") then (live :: Part).Shape else Enum.PartType.Block
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Massless = true
		-- Neon so it reads as light rather than as a second body. A ghost made of
		-- plastic looks like a bug where the character failed to move.
		part.Material = Enum.Material.Neon
		part.Transparency = 1
		part.Parent = parent
		table.insert(parts, part)
		table.insert(sizes, live.Size)
	end
	return {
		parts = parts, sizes = sizes,
		active = false, age = 0, tier = nil, phase = 0,
	}
end

--==============================================================================
-- TRACKING A CHARACTER
--==============================================================================
local function untrack(who: Player)
	local entry = tracked[who]
	if not entry then
		return
	end
	for _, ghost in ipairs(entry.pool) do
		ghost.active = false
	end
	-- Removed from the fade list by identity, so a ghost mid-fade on a player who
	-- just left cannot keep writing to destroyed parts.
	for i = #active, 1, -1 do
		if table.find(entry.pool, active[i]) then
			table.remove(active, i)
		end
	end
	entry.folder:Destroy()
	tracked[who] = nil
end

--==============================================================================
-- CharacterAdded IS NOT "THE CHARACTER IS READY"
--
-- MEASURED, AND IT BROKE EVERY RESPAWN. The event fires when the model is
-- parented, and an R15 rig's fifteen parts arrive over the frames after that --
-- so reading them immediately gets a Humanoid, no HumanoidRootPart, and an empty
-- body. The first version returned in that case and never tried again, which
-- meant the pool existed exactly until the player first died and then never came
-- back. It looked fine in testing because the character present at JOIN is
-- already complete.
--
-- So: wait for the two parts that must exist, then let the rig settle until the
-- part count stops changing. Bounded, and abandoned if the character is replaced
-- underneath us.
--==============================================================================
local function track(who: Player, character: Model)
	untrack(who)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		local rootInstance = character:WaitForChild("HumanoidRootPart", 10)
		if not (humanoid and humanoid:IsA("Humanoid")
			and rootInstance and rootInstance:IsA("BasePart")) then
			return
		end
		local last = -1
		for _ = 1, 30 do
			local n = #bodyPartsOf(character)
			if n > 0 and n == last then
				break
			end
			last = n
			task.wait()
		end
		if who.Character ~= character or not character.Parent then
			return
		end
		buildPool(who, character, humanoid :: Humanoid, rootInstance :: BasePart)
	end)
end

function buildPool(who, character, humanoid, rootInstance)
	if tracked[who] then
		return
	end
	local source = bodyPartsOf(character)
	if #source == 0 then
		return
	end
	local isLocal = who == player
	local budget = maxGhostsFor(isLocal)
	if budget <= 0 then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = who.Name
	folder.Parent = ghostRoot

	local pool: { Ghost } = {}
	for _ = 1, budget do
		table.insert(pool, buildGhost(source, folder))
	end

	tracked[who] = {
		player = who,
		character = character,
		humanoid = humanoid,
		root = rootInstance,
		source = source,
		heights = heightsOf(source),
		pool = pool,
		nextGhost = 1,
		lastPos = nil,
		travelled = 0,
		isLocal = isLocal,
		folder = folder,
	}
end

--==============================================================================
-- IS THIS CHARACTER ACTUALLY RUNNING
--
-- Every reason NOT to emit, in one place. Ragdolled and thrown are the same
-- test: NestService sets PlatformStand for the whole flight, and the physics
-- state covers anything else that takes the humanoid off its feet.
--==============================================================================
local function isRunning(entry: Tracked): boolean
	local humanoid = entry.humanoid
	if humanoid.Health <= 0 or humanoid.PlatformStand then
		return false
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Dead
		or state == Enum.HumanoidStateType.Physics
		or state == Enum.HumanoidStateType.FallingDown
		or state == Enum.HumanoidStateType.Ragdoll then
		return false
	end
	local v = entry.root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude >= FX.MoveStudsPerSecond
end

--==============================================================================
-- ONE ECHO
--==============================================================================
local function paint(entry: Tracked, ghost: Ghost, clock: number)
	local tier = ghost.tier
	if not tier then
		return
	end
	for i, part in ipairs(ghost.parts) do
		part.Color = colourFor(tier, ghost.phase, entry.heights[i] or 0, clock)
	end
end

local function emit(entry: Tracked, tier: any, clock: number)
	--==========================================================================
	-- THE TIER'S GHOST COUNT IS A CAP, NOT A DESCRIPTION
	--
	-- MEASURED, AND IT WAS WRONG. The round-robin walked the whole POOL, which is
	-- sized to the largest tier -- so how many echoes were on screen was an
	-- accident of spacing, speed and fade time rather than the number in the
	-- table. At 90 studs/s a tier-1 player got a fresh ghost every 0.12s and each
	-- lived 0.18s, so `Ghosts = 1` rendered TWO.
	--
	-- Rotating through only the first N slots fixes it by construction: emitting
	-- into a slot that is still fading restarts that same ghost, so N slots can
	-- never show more than N echoes at any speed.
	--==========================================================================
	local slots = math.clamp(tier.Ghosts, 1, #entry.pool)
	if entry.nextGhost > slots then
		entry.nextGhost = 1
	end
	local ghost = entry.pool[entry.nextGhost]
	if not ghost then
		return
	end
	local slot = entry.nextGhost - 1
	entry.nextGhost = entry.nextGhost % slots + 1

	ghost.tier = tier
	-- Where this echo starts in the palette or on the hue wheel. Consecutive
	-- ghosts begin at different colours, which is what makes four echoes read as
	-- a spectrum travelling with the player rather than four copies.
	ghost.phase = if slots > 1 then slot / slots else 0
	ghost.age = 0

	for i, live in ipairs(entry.source) do
		local part = ghost.parts[i]
		if part and live.Parent then
			part.CFrame = live.CFrame
			part.Size = ghost.sizes[i]
			part.Transparency = tier.StartTransparency
		end
	end
	paint(entry, ghost, clock)

	if not ghost.active then
		ghost.active = true
		table.insert(active, ghost)
	end
end

--==============================================================================
-- THE TRAIL BECOMES THE RAINBOW TOO
--
-- Tier 7 asks for the movement trail to flow rather than sit still, and the
-- trail already exists -- so this rebuilds its ColorSequence on the colour clock
-- instead of adding anything to the scene. Eight stops is enough to read as a
-- spectrum; Roblox allows twenty.
--
-- Off every other tier, where the trail keeps the single colour it has always
-- had. A rainbow streak at a thousand Speed would spend the whole ladder's
-- reward on its first rung.
--==============================================================================
local function rainbowTrail(t: Trail, clock: number)
	local stops: { ColorSequenceKeypoint } = {}
	for i = 0, FX.TrailRainbowStops - 1 do
		local at = i / (FX.TrailRainbowStops - 1)
		table.insert(stops, ColorSequenceKeypoint.new(at,
			Color3.fromHSV((at * 0.9 + clock * 0.5) % 1, 0.82, 1)))
	end
	t.Color = ColorSequence.new(stops)
end

--==============================================================================
-- THE ONE LOOP
--==============================================================================
local colourClock = 0
local sinceColour = 0
-- So the streak is only reset to its resting colour once, rather than
-- rebuilt every tick for every player who is not at tier 7.
local trailIsRainbow = false

RunService.Heartbeat:Connect(function(dt)
	colourClock += dt
	sinceColour += dt
	local repaint = sinceColour >= colourInterval()
	if repaint then
		sinceColour = 0
	end

	--== every echo that is out there, whoever it belongs to ==--
	for i = #active, 1, -1 do
		local ghost = active[i]
		local tier = ghost.tier
		ghost.age += dt
		local t = if tier and tier.FadeSeconds > 0 then ghost.age / tier.FadeSeconds else 1
		if t >= 1 or not tier then
			for _, part in ipairs(ghost.parts) do
				part.Transparency = 1
			end
			ghost.active = false
			table.remove(active, i)
		else
			--==============================================================
			-- FADE, PULSE, SHIMMER, EXPAND -- ALL FROM ONE NUMBER
			--
			-- The pulse rides ON the fade rather than replacing it, so an echo
			-- always ends invisible no matter what the tier asks for. A pulse
			-- that could push transparency back down would leave ghosts on
			-- screen forever at the top of the ladder.
			--==============================================================
			local base = tier.StartTransparency + (1 - tier.StartTransparency) * t
			local pulse = if tier.Pulse > 0
				then math.sin(t * math.pi * 2) * tier.Pulse * (1 - t)
				else 0
			local shimmer = if tier.Shimmer > 0
				then math.sin(colourClock * 24 + ghost.phase * 6.28) * tier.Shimmer * (1 - t)
				else 0
			local transparency = math.clamp(base - pulse - shimmer, 0, 1)

			local grow = if tier.Expand > 0 then 1 + tier.Expand * t else 1
			for k, part in ipairs(ghost.parts) do
				part.Transparency = transparency
				if tier.Expand > 0 then
					part.Size = ghost.sizes[k] * grow
				end
			end
		end
	end

	if quality == QUALITY_OFF then
		return
	end

	local localEntry = tracked[player]
	local localRoot = localEntry and localEntry.root
	local here = if localRoot and localRoot.Parent then localRoot.Position else nil

	--==========================================================================
	-- THE STREAK JOINS IN AT THE TOP OF THE LADDER
	--
	-- Driven off the same colour clock as the ghosts, so the trail and the echoes
	-- are phases of one animation rather than two things that happen to be
	-- rainbow. Restored to its resting colour the moment the tier drops, because
	-- a Trail keeps whatever ColorSequence it was last given forever.
	--==========================================================================
	if repaint and trail and trail.Parent then
		local mine = player:GetAttribute(TIER_ATTR)
		local row = if type(mine) == "number" then FX.Tiers[mine] else nil
		-- The streak is what a suppressed player is left with, so it must not
		-- still be the most spectacular thing in the game while they crawl.
		row = carriedTier(player, row)
		if row and row.TrailRainbow then
			rainbowTrail(trail, colourClock)
			trailIsRainbow = true
		elseif trailIsRainbow then
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), ACCENT)
			trailIsRainbow = false
		end
	end

	for who, entry in pairs(tracked) do
		if not (entry.character.Parent and entry.root.Parent) then
			untrack(who)
		else
			local tierIndex = who:GetAttribute(TIER_ATTR)
			local tier = if type(tierIndex) == "number" then FX.Tiers[tierIndex] else nil
			-- Weight can weaken it to one faint echo, or take it away entirely.
			tier = carriedTier(who, tier)
			local at = entry.root.Position

			local moved = if entry.lastPos
				then Vector3.new(at.X - entry.lastPos.X, 0, at.Z - entry.lastPos.Z).Magnitude
				else 0
			entry.lastPos = at

			--==============================================================
			-- A JUMP THIS BIG WAS NOT A RUN
			--
			-- The accumulator is RESET rather than added to, so nothing is
			-- emitted across the gap -- otherwise a respawn draws a line of
			-- ghosts from where you died to where you came back.
			--==============================================================
			if moved > FX.TeleportStuds then
				entry.travelled = 0
			elseif tier and isRunning(entry) then
				--==========================================================
				-- NOBODY NEEDS SOMEBODY ELSE'S GHOSTS FROM 1,500 STUDS AWAY
				--
				-- Checked before the work rather than by MaxDistance on the
				-- part, because the point is not to skip DRAWING them -- it is
				-- to skip computing them at all.
				--==========================================================
				local inRange = entry.isLocal
					or (here ~= nil and (at - here).Magnitude <= FX.RemoteMaxStuds)
				if inRange then
					entry.travelled += moved
					if entry.travelled >= tier.SpacingStuds then
						entry.travelled = 0
						emit(entry, tier, colourClock)
					end
				else
					entry.travelled = 0
				end
			else
				entry.travelled = 0
			end

			--==============================================================
			-- THE WAVE MOVES; THE FRAME RATE DOES NOT DECIDE HOW FAST
			--
			-- Repainted on the colour clock rather than every frame, and only
			-- for the tiers whose colour actually moves. Tiers 1 to 4 are
			-- painted once at emit and never touched again.
			--==============================================================
			if repaint then
				for _, ghost in ipairs(entry.pool) do
					if ghost.active and ghost.tier
						and (ghost.tier.Wave > 0 or ghost.tier.Rainbow) then
						paint(entry, ghost, colourClock)
					end
				end
			end
		end
	end
end)

--==============================================================================
-- WHO IS TRACKED
--
-- Everybody, including the local player -- the ghosts of the person you are
-- playing are the whole point, and a separate path for them would be a second
-- copy of all of the above.
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
-- Rebuilds the pools, because the budget decides how many ghosts exist and that
-- is fixed at build time by design. Nothing else in the file has to know.
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
-- answer from outside its own VM, as the test harness found out.
--
-- Applied on connect as well as on change, so a value written before this script
-- ran is not lost.
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
