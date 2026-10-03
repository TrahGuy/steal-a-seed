--!strict
-- Steal a Seed :: HatchFX
--
--==============================================================================
-- WHAT A HATCH LOOKS LIKE
--
-- Two jobs, both cosmetic, both entirely local:
--
--   THE HOLD    while the owner holds E on a ready pod, the shell brightens from
--               inside and throws a little dust. The RATTLE is PlantSway's -- it
--               already moves every planted model every frame -- so nothing here
--               touches a transform, and releasing the key leaves the pod exactly
--               where PlantSway puts it back.
--
--   THE REVEAL  when a hatch succeeds the server sends ONE message (see
--               PlantService.announceReveal) and every client within earshot
--               plays the whole thing locally: rings over the soil, a flash, the
--               real creature coming up out of the glow at its real size, a label
--               saying what it is and what it pays, and the rarity fanfare.
--
--   THE ROLL    (2026-09-29) the message says when the plant may be shown
--               (`revealAt`, three seconds on). Until then the place where the
--               pod stood turns plant silhouettes over under a floating
--               question mark -- quickly, then slowly, the last of them the
--               plant's own -- and nothing here names the plant: no creature,
--               no label, and no fanfare, which is chosen by rarity and would
--               say it out loud. The burst is at the hatch, as it always was.
--               With the roll off the wait is nought. IT IS IN THE WORLD, for
--               everybody who can see the pod: there is no card, no panel,
--               and nothing over anybody's camera.
--
--==============================================================================
-- IT DECIDES NOTHING
--
-- The plant is in the player's Backpack and the garden is saved before the
-- message that starts any of this is sent. There is no acknowledgement, no
-- request and no state here that the server reads. A client that never runs a
-- frame of this loses a second of animation and nothing else.
--
--==============================================================================
-- WHY THE CREATURE IS THE REAL BUILDER'S
--
-- The reveal is the one moment the player learns what they grew, so a simplified
-- stand-in would be lying about the thing they are about to hold. It is built by
-- CreatureModel at the pod's own tier, then stripped: every tag off, nothing
-- collidable, nothing queryable, no prompt and no gameplay attribute. It cannot
-- be clicked, walked into, paid or picked up, and it is destroyed when the reveal
-- ends. The Tool in the Backpack is the real one.
--
--==============================================================================
-- ONE FOLDER AND ONE CONNECTION PER HATCH
--
-- Two players hatching side by side, or one player hatching twice in a second,
-- each get their own token, their own folder, their own RenderStepped connection
-- and their own cleanup. Nothing is shared and nothing is borrowed, so one
-- reveal ending can never tear down another's model.
--
-- A RE-RUN CLEANS UP AFTER THE COPY BEFORE IT. A destroyed LocalScript's
-- Destroying handler is not guaranteed to run, so this deletes any folder the
-- previous copy left behind at startup rather than trusting it to have tidied.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))
-- Which silhouette stands where the pod was at each moment of a roll.
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))

local PLANT = GameConfig.Plant
local HATCH = PLANT.Hatch
local HOLD = HATCH.Hold
local BURST = PLANT.BurstSeconds
local REVEAL = HATCH.Reveal
local LABEL = HATCH.Label
local PAID = HATCH.Paid
local ROLL = HATCH.Roll
local WORLD = ROLL.World
-- The Index's own near-black: what an undiscovered plant is drawn in.
local SILHOUETTE: Color3 = GameConfig.Almanac.Silhouette
local SOUNDS = HATCH.Sounds
local REVEAL_FOR: { [string]: string } = (GameConfig.Sfx.RevealFor :: any)
-- The accent a few rarities add, and the hatches that have already had theirs,
-- by the server's token (a plain number; a session sees a few hundred hatches).
local REVEAL_ACCENT: { [string]: string } = (GameConfig.Sfx.RevealAccentFor :: any) or {}
local accented: { [number]: boolean } = {}

-- Reduced Effects. The same attribute SpeedFX, PlantAura and UIKit already read,
-- so one setting covers the whole game.
local QUALITY_ATTRIBUTE = "SeedAfterimageQuality"
local function reduced(): boolean
	return player:GetAttribute(QUALITY_ATTRIBUTE) == "Off"
end

--==============================================================================
-- THE ONE FOLDER EVERYTHING TEMPORARY LIVES IN
--==============================================================================
local STAGE_NAME = "SeedHatchFX"
do
	local stale = Workspace:FindFirstChild(STAGE_NAME)
	if stale then
		stale:Destroy()
	end
end

local stage = Instance.new("Folder")
stage.Name = STAGE_NAME
stage.Parent = Workspace

local function scrub(model: Instance)
	for _, tag in ipairs(CollectionService:GetTags(model)) do
		CollectionService:RemoveTag(model, tag)
	end
	for _, d in ipairs(model:GetDescendants()) do
		for _, tag in ipairs(CollectionService:GetTags(d)) do
			CollectionService:RemoveTag(d, tag)
		end
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		elseif d:IsA("ProximityPrompt") or d:IsA("ClickDetector") or d:IsA("Humanoid") then
			d:Destroy()
		end
	end
end

--==============================================================================
-- THE SHAPES A ROLL TURNS OVER
--
-- A silhouette is the real plant by the real builder, made dark: every part the
-- Index's near-black, nothing on it that shines, sparkles or casts a shadow. It
-- is built at the smallest size and outside the world, scrubbed before it goes
-- in, and drawn the size of the SHELL -- the plant's own size is the reveal's
-- to show.
--
-- ONE IS KEPT FOR EACH SPECIES this client has shown, parked outside the world
-- between rolls, so a second roll of the same biome builds nothing: a phone
-- pays for a shape once. Two rolls that want the same shape at the same moment
-- get one each, and the second is thrown away when its roll is over.
--==============================================================================
local parked: { [string]: Model } = {}
-- How many rolls are turning shapes on this screen now (World.MaxShapes).
local shaped = 0

local function darken(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Color = SILHOUETTE
			d.Material = Enum.Material.SmoothPlastic
			d.Reflectance = 0
			d.CastShadow = false
		elseif d:IsA("SpecialMesh") then
			d.TextureId = ""
			d.VertexColor = Vector3.new(1, 1, 1)
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
			or d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance")
			or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Highlight")
			or d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			d:Destroy()
		end
	end
end

local function takeShape(speciesId: string): Model?
	local kept = parked[speciesId]
	if kept then
		parked[speciesId] = nil
		return kept
	end
	local species = SeedData.Get(speciesId)
	if not species then
		return nil
	end
	local ok, model = pcall(function()
		return CreatureModel.Build(species, SeedData.BaseTier, CreatureModel.STAGE_GROWN,
			CFrame.new(), nil :: any)
	end)
	if not ok or typeof(model) ~= "Instance" then
		return nil
	end
	local shape = model :: Model
	scrub(shape)
	darken(shape)
	local size = shape:GetExtentsSize()
	-- Its longest side as it was built, which is what it is scaled from.
	shape:SetAttribute("Longest", math.max(size.X, size.Y, size.Z, 0.1))
	shape.Name = "Shape"
	return shape
end

local function keepShape(speciesId: string, shape: Model)
	local ok = pcall(function()
		shape.Parent = nil
	end)
	if ok and parked[speciesId] == nil then
		parked[speciesId] = shape
	else
		pcall(function()
			shape:Destroy()
		end)
	end
end

--==============================================================================
-- THE HOLD
--
-- One light and one emitter per pod being held, hung on the shell so they go with
-- it if the pod streams out or bursts. Cleared the moment Hatching goes false,
-- which is what a cancelled hold is.
--==============================================================================
local holding: { [Model]: { light: PointLight, dust: ParticleEmitter, at: number } } = {}

local function endHold(model: Model)
	local kit = holding[model]
	if not kit then
		return
	end
	holding[model] = nil
	if kit.light then
		kit.light:Destroy()
	end
	if kit.dust then
		kit.dust:Destroy()
	end
end

local function beginHold(model: Model)
	if holding[model] then
		return
	end
	local shell = model.PrimaryPart
	local tier = tonumber(model:GetAttribute("Tier"))
	if not (shell and tier) then
		return
	end
	local color = SeedData.ColorForTier(tier)

	local light = Instance.new("PointLight")
	light.Name = "HatchHoldGlow"
	light.Color = color
	light.Brightness = 0
	light.Range = HOLD.GlowRange
	light.Shadows = false
	light.Parent = shell

	local dust = Instance.new("ParticleEmitter")
	dust.Name = "HatchHoldDust"
	dust.Color = ColorSequence.new(color)
	dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	dust.Lifetime = NumberRange.new(0.35, 0.7)
	dust.Rate = 0
	dust.Speed = NumberRange.new(1.5, 3.5)
	dust.SpreadAngle = Vector2.new(50, 50)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, SeedData.PodDiameter(tier) * 0.10),
		NumberSequenceKeypoint.new(1, 0),
	})
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.LightEmission = 0.8
	dust.LightInfluence = 0
	dust.Acceleration = Vector3.new(0, 4, 0)
	dust.Parent = shell

	holding[model] = { light = light, dust = dust, at = os.clock() }

	if SOUNDS.Rattle ~= "" and SoundKit.has(SOUNDS.Rattle) then
		SoundKit.emit(SOUNDS.Rattle, shell)
	end
end

local function watchPod(model: Model)
	if not model:IsA("Model") then
		return
	end
	local function read()
		if model:GetAttribute("Hatching") == true then
			beginHold(model)
		else
			endHold(model)
		end
	end
	model:GetAttributeChangedSignal("Hatching"):Connect(read)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(Workspace) then
			endHold(model)
		end
	end)
	model.Destroying:Connect(function()
		endHold(model)
	end)
	read()
end

for _, model in ipairs(CollectionService:GetTagged(GameConfig.Tags.Planted)) do
	if model:IsA("Model") then
		watchPod(model)
	end
end
CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Planted):Connect(function(model)
	if model:IsA("Model") then
		watchPod(model)
	end
end)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Planted):Connect(function(model)
	if model:IsA("Model") then
		endHold(model)
	end
end)

-- The hold's glow and dust ramp with the hold, exactly as PlantSway's rattle
-- does. One connection for every held pod at once, and it does nothing at all
-- when nobody is holding anything.
RunService.Heartbeat:Connect(function()
	local quiet = reduced()
	for model, kit in pairs(holding) do
		if not model.Parent then
			endHold(model)
		else
			local held = math.clamp((os.clock() - kit.at) / PLANT.HatchHoldSeconds, 0, 1)
			local ramp = HOLD.StartFactor + (1 - HOLD.StartFactor) * held
			kit.light.Brightness = HOLD.GlowBrightness * ramp
			kit.dust.Rate = HOLD.DustRate * ramp * (if quiet then 0.5 else 1)
		end
	end
end)

--==============================================================================
-- THE REVEAL
--==============================================================================
type Reveal = {
	token: number,
	folder: Folder,
	connection: RBXScriptConnection?,
	done: boolean,
	-- The roll, while it runs: its one connection, what it has drawn, and the
	-- shapes it has out of the park.
	rolling: RBXScriptConnection?,
	holder: Instance?,
	shapes: { [string]: Model }?,
}

local live: { [number]: Reveal } = {}

-- The roll is over, or is being thrown away: its connection goes, its shapes
-- go back to the park, and its question mark and disc go with their folder.
-- Safe to call twice, and with no roll at all.
local function endRoll(job: Reveal)
	if job.rolling then
		job.rolling:Disconnect()
		job.rolling = nil
	end
	local shapes = job.shapes
	if shapes then
		job.shapes = nil
		shaped = math.max(shaped - 1, 0)
		for speciesId, shape in pairs(shapes) do
			keepShape(speciesId, shape)
		end
	end
	local holder = job.holder
	if holder then
		job.holder = nil
		if holder.Parent then
			holder:Destroy()
		end
	end
end

local function finish(job: Reveal)
	if job.done then
		return
	end
	job.done = true
	live[job.token] = nil
	if job.connection then
		job.connection:Disconnect()
		job.connection = nil
	end
	-- Before the folder goes: a shape destroyed with it could not be kept.
	endRoll(job)
	if job.folder.Parent then
		job.folder:Destroy()
	end
end

-- A flat disc over the soil that grows and fades. Two of these is what a Titan
-- gets instead of a longer animation.
local function ring(folder: Folder, at: Vector3, diameter: number, color: Color3,
	seconds: number, delay: number)
	local disc = Instance.new("Part")
	disc.Name = "HatchRing"
	disc.Shape = Enum.PartType.Cylinder
	-- A cylinder runs along its own X, so flat means rolled onto its side.
	disc.Size = Vector3.new(0.2, diameter * 0.3, diameter * 0.3)
	disc.CFrame = CFrame.new(at + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc.Material = Enum.Material.Neon
	disc.Color = color
	disc.Transparency = 0.15
	disc.Parent = folder
	task.delay(delay, function()
		if disc.Parent then
			TweenService:Create(disc,
				TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.2, diameter, diameter),
					Transparency = 1,
				}):Play()
		end
	end)
end

-- The Colossal's crack: three thin neon shards, gone in a fifth of a second.
-- Under Reduced Effects it is one shard and no flicker.
local function lightning(folder: Folder, at: Vector3, height: number, color: Color3)
	local shards = if reduced() then 1 else 3
	for i = 1, shards do
		local bolt = Instance.new("Part")
		bolt.Name = "HatchBolt"
		bolt.Size = Vector3.new(0.22, height, 0.22)
		bolt.CFrame = CFrame.new(at + Vector3.new(0, height * 0.5, 0))
			* CFrame.Angles(math.rad((i - 2) * 7), math.rad(i * 40), math.rad((i - 2) * 9))
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.CanQuery = false
		bolt.CanTouch = false
		bolt.Material = Enum.Material.Neon
		bolt.Color = color:Lerp(Color3.new(1, 1, 1), 0.55)
		bolt.Transparency = 0.1
		bolt.Parent = folder
		TweenService:Create(bolt,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1 }):Play()
	end
end

--==============================================================================
-- THE LABEL
--
-- Three lines, the HUD's own face and outline, and no plate behind any of it:
--
--     SUPERNOVUS
--     MYTHIC . COLOSSAL
--     +$66.5K/s
--
-- plus NEW DISCOVERY the first time a species is ever hatched. The rarity word
-- carries the rarity's colour, the income is compacted by the same function the
-- HUD uses, and Legendary and above get the bounded shimmer the Speed rail uses
-- -- a shallow brightness wobble, not a rainbow.
--==============================================================================
local SHIMMERS: { [string]: boolean } = {
	Legendary = true, Mythic = true, Secret = true, Divine = true,
}

local function label(folder: Folder, host: BasePart, species: SeedData.Species,
	tier: number, income: number, discovery: boolean): (BillboardGui, TextLabel?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HatchReveal"
	gui.Adornee = host
	gui.AlwaysOnTop = true
	gui.Size = UDim2.new(0, LABEL.Width, 0, LABEL.Height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, LABEL.Lift, 0)
	-- Bounded like every other billboard in this game. PlantUI's plate is 160 and
	-- a prompt is 250; a reveal is worth seeing from across a plot and no further.
	gui.MaxDistance = 170
	gui.Parent = folder

	local column = Instance.new("Frame")
	column.BackgroundTransparency = 1
	column.Size = UDim2.new(1, 0, 1, 0)
	column.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = column

	local function line(name: string, size: number, colour: Color3, text: string, order: number): TextLabel
		local it = UIKit.outlined(column, name, size, colour, 2)
		it.Size = UDim2.new(1, 0, 0, size + 6)
		it.Text = text
		it.LayoutOrder = order
		return it
	end

	local rarityColour = GameConfig.RarityColor[species.Rarity] or Color3.fromRGB(220, 220, 220)
	local nameLabel = line("Species", LABEL.NameSize,
		SeedData.FormColor(species), species.Name:upper(), 1)
	-- A Secret has its rarity and no size tier (2026-10-02): "SECRET" alone. So
	-- do the Rain event's unsized forms: "MYTHIC", "DIVINE".
	line("Rarity", LABEL.LineSize, rarityColour,
		if SeedData.Unsized(species) then species.Rarity:upper()
			else string.format("%s • %s", species.Rarity:upper(), SeedData.TierName(tier):upper()), 2)
	line("Income", LABEL.IncomeSize, Color3.fromRGB(142, 214, 86),
		string.format("+$%s/s", GameConfig.compact(income)), 3)
	if discovery then
		line("New", LABEL.LineSize, Color3.fromRGB(255, 226, 120), LABEL.NewText, 4)
	end

	return gui, if SHIMMERS[species.Rarity] then nameLabel else nil
end

--==============================================================================
-- THE OWNER'S CAMERA, AND NOBODY ELSE'S
--
-- A nudge on the CFrame for two frames' worth of decay, never a lock, never a
-- replacement, and never for anything under a Titan. Reduced Effects turns it
-- off completely. The camera is put back by the engine on the next frame it
-- controls, so there is nothing to restore.
--==============================================================================
local function bump(studs: number)
	if studs <= 0 or reduced() then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local decay = studs
	local started = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		local cam = Workspace.CurrentCamera
		local age = os.clock() - started
		if not cam or age > 0.35 then
			if connection then
				connection:Disconnect()
			end
			return
		end
		local fall = 1 - age / 0.35
		local shake = math.sin(age * 42) * decay * fall * 0.1
		cam.CFrame = cam.CFrame * CFrame.new(0, shake, 0)
	end)
end

--==============================================================================
-- ONE MESSAGE, ONE ANIMATION
--==============================================================================
local function playReveal(payload: any)
	if type(payload) ~= "table" then
		return
	end
	local species = SeedData.Get(tostring(payload.species))
	local tier = tonumber(payload.tier)
	local cf = payload.cf
	if not (species and tier and typeof(cf) == "CFrame") then
		return
	end
	local token = tonumber(payload.token) or 0

	-- Out of earshot: not worth a model. Measured from the camera, because that
	-- is where the player is looking from, not from their feet.
	local camera = Workspace.CurrentCamera
	local from = if camera then camera.CFrame.Position else cf.Position
	if (from - cf.Position).Magnitude > HATCH.HearingStuds then
		return
	end

	local intensity = HATCH.Tiers[math.clamp(tier, 1, #HATCH.Tiers)]
	local quiet = reduced()
	local color = SeedData.ColorForTier(tier)
	local diameter = SeedData.PodDiameter(tier)
	local isOwner = payload.owner == player

	local folder = Instance.new("Folder")
	folder.Name = string.format("Reveal_%d", token)
	folder.Parent = stage

	local job: Reveal = {
		token = token,
		folder = folder,
		connection = nil,
		done = false,
		rolling = nil,
		holder = nil,
		shapes = nil,
	}
	live[token] = job

	-- WHERE IN THE ANIMATION WE ARE, off the server's own clock. A client that
	-- receives this late starts partway in rather than a beat behind everybody
	-- else, and one that receives it absurdly late drops it.
	local sent = tonumber(payload.at) or Workspace:GetServerTimeNow()
	local behind = math.max(Workspace:GetServerTimeNow() - sent, 0)
	local paidLead = if payload.paid == true then PAID.PulseSeconds else 0
	--==========================================================================
	-- HOW LONG THE PLANT STAYS A SECRET (2026-09-29): from the hatch to
	-- `revealAt`, the server's own two times. Read as a claim -- not a time, not
	-- after the hatch, or further off than any roll could be, and there is no
	-- wait. Nought is the hatch as it was before there was a roll.
	--==========================================================================
	local claimed = tonumber(payload.revealAt)
	local rolled = if claimed and claimed == claimed then claimed - sent else 0
	if rolled <= 0 or rolled > ROLL.MaxHideSeconds then
		rolled = 0
	end
	-- The moment the plant comes up, on the clock everybody shares.
	local revealAt = sent + rolled
	if behind > rolled + BURST + paidLead + REVEAL.Seconds + LABEL.Seconds then
		finish(job)
		return
	end
	-- The burst is drawn by a client that was there for it. One that hears of
	-- the hatch partway through its roll starts at the silhouettes.
	local fresh = rolled == 0 or behind <= BURST + paidLead + 0.6

	--==========================================================================
	-- THE PAID PULSE: the only thing a purchase changes
	--==========================================================================
	if payload.paid == true and fresh then
		ring(folder, cf.Position, diameter * 1.4, PAID.Color, PAID.PulseSeconds, 0)
		if SOUNDS.TimeSkip ~= "" and SoundKit.has(SOUNDS.TimeSkip) then
			SoundKit.play(SOUNDS.TimeSkip)
		end
	end

	--==========================================================================
	-- THE BURST, on the client's side of it: rings, dust and the flash. The SHELL
	-- itself is the server's -- it owns those parts -- and it is already coming
	-- apart while this draws.
	--==========================================================================
	local ringSeconds = BURST + 0.15
	for i = 1, if fresh then intensity.rings else 0 do
		ring(folder, cf.Position, diameter * intensity.ringScale * (1 + (i - 1) * 0.5),
			color, ringSeconds, paidLead + (i - 1) * 0.09)
	end

	local flashPart = Instance.new("Part")
	flashPart.Name = "HatchFlash"
	flashPart.Size = Vector3.new(0.2, 0.2, 0.2)
	flashPart.CFrame = cf * CFrame.new(0, diameter * 0.4, 0)
	flashPart.Anchored = true
	flashPart.CanCollide = false
	flashPart.CanQuery = false
	flashPart.CanTouch = false
	flashPart.Transparency = 1
	flashPart.Parent = folder

	local flash = Instance.new("PointLight")
	flash.Color = color
	flash.Brightness = if fresh then HATCH.Burst.FlashBrightness * intensity.flash else 0
	flash.Range = HATCH.Burst.FlashRange
	flash.Shadows = false
	flash.Parent = flashPart
	TweenService:Create(flash,
		TweenInfo.new(BURST + 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0 }):Play()

	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(color)
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Lifetime = NumberRange.new(0.3, 0.8)
	sparks.Speed = NumberRange.new(diameter * 0.8, diameter * 2.2)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 0
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, diameter * 0.12),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Parent = flashPart
	-- CAPPED BY THE TIER TABLE, which tops out at 74, and halved under Reduced
	-- Effects. One Emit, not a rate: a burst is one event, and an emitter left
	-- running is a leak with a nice texture.
	if fresh then
		sparks:Emit(math.floor(intensity.particles * (if quiet then 0.5 else 1)))
	end

	if intensity.lightning and fresh then
		task.delay(paidLead, function()
			if not job.done then
				lightning(folder, cf.Position, diameter * 1.8, color)
			end
		end)
	end

	--==========================================================================
	-- THE FANFARE: rarity, not size. One per hatch, on the authoritative event
	-- rather than on anybody having held a prompt -- which is why a paid hatch
	-- now sounds exactly like a free one.
	--
	-- IT NAMES THE RARITY, so with a roll it waits for the plant (below): at the
	-- burst it would tell everybody, three seconds early, how rare the plant
	-- is. The crack is the shell's and says nothing.
	--==========================================================================
	local function fanfare()
		SoundKit.emit(REVEAL_FOR[species.Rarity] or "RevealCommon", flashPart)
	end
	if rolled == 0 then
		fanfare()
	end
	if fresh and SOUNDS.Crack ~= "" and SoundKit.has(SOUNDS.Crack) then
		SoundKit.emit(SOUNDS.Crack, flashPart)
	end

	if isOwner and fresh then
		bump(intensity.bump)
	end

	--==========================================================================
	-- THE ROLL, WHERE THE POD STOOD
	--
	-- For everybody who can see it, from the burst to the reveal: a disc of the
	-- tier's colour on the soil, a dark shape standing on it that keeps turning
	-- into another -- quickly, then slowly, the last of them the plant's own --
	-- and a question mark riding over it. It says a plant is coming and not
	-- which: the tier was already the shell's colour, and the shapes are the
	-- size of the shell.
	--
	-- MODEST. One shape in the world at a time; a sign, a disc and one
	-- connection, which turns the sign to the camera and rides it up and down.
	-- No particle, no light, no sound. With more rolls on the screen than
	-- World.MaxShapes, the later ones are a question mark with nothing turning
	-- under it. Reduced Effects keeps the shapes and stops the riding.
	--
	-- IT CANNOT BE LEFT BEHIND. It ends at the reveal, in `finish`, and at the
	-- backstop below, whichever comes first -- and `finish` is what a respawn
	-- and a build that throws both call.
	--==========================================================================
	if rolled > 0 then
		local opens = sent + HatchRoll.lead(payload.paid == true)
		task.delay(math.max(opens - Workspace:GetServerTimeNow(), 0), function()
			if job.done or not folder.Parent or Workspace:GetServerTimeNow() >= revealAt then
				return
			end
			local holder = Instance.new("Folder")
			holder.Name = "HatchRoll"
			job.holder = holder

			local disc = Instance.new("Part")
			disc.Name = "Disc"
			disc.Shape = Enum.PartType.Cylinder
			disc.Size = Vector3.new(0.2, diameter * WORLD.DiscInPods, diameter * WORLD.DiscInPods)
			disc.CFrame = CFrame.new(cf.Position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
			disc.Anchored = true
			disc.CanCollide = false
			disc.CanQuery = false
			disc.CanTouch = false
			disc.CastShadow = false
			disc.Material = Enum.Material.Neon
			disc.Color = color
			disc.Transparency = 0.55
			disc.Parent = holder

			local shapeStuds = math.clamp(diameter * WORLD.SizeInPods, WORLD.MinStuds, WORLD.MaxStuds)
			local markStuds = math.clamp(diameter * WORLD.MarkInPods, WORLD.MarkMinStuds, WORLD.MarkMaxStuds)
			local markAt = cf.Position
				+ Vector3.new(0, shapeStuds + WORLD.MarkGapStuds + markStuds * 0.5, 0)

			-- A sign in the world, not a billboard over it: it stands behind whatever
			-- stands in front of it, and is the size its distance makes it.
			local sign = Instance.new("Part")
			sign.Name = "Question"
			sign.Size = Vector3.new(markStuds, markStuds, 0.05)
			sign.CFrame = CFrame.new(markAt)
			sign.Anchored = true
			sign.CanCollide = false
			sign.CanQuery = false
			sign.CanTouch = false
			sign.CastShadow = false
			sign.Transparency = 1
			sign.Parent = holder
			local face = Instance.new("SurfaceGui")
			face.Name = "Face"
			face.Face = Enum.NormalId.Front
			face.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			face.CanvasSize = Vector2.new(128, 128)
			face.LightInfluence = 0
			face.MaxDistance = 170
			face.Parent = sign
			local word = UIKit.outlined(face, "Mark", 100, color:Lerp(Color3.new(1, 1, 1), 0.7), 4)
			word.Size = UDim2.fromScale(1, 1)
			word.Text = "?"

			holder.Parent = folder
			if not quiet then
				TweenService:Create(disc,
					TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Transparency = 0.8 }):Play()
			end

			-- THE SHAPES, in the order the hatch's own token gives: the same on every
			-- screen that draws them, and ending on the plant that hatched.
			local frames = HatchRoll.frames(species.Id, token)
			local window = math.max(revealAt - opens, 0.1)
			local shapes: { [string]: Model }? = nil
			if shaped < WORLD.MaxShapes then
				shaped += 1
				shapes = {}
				job.shapes = shapes
			end
			local standing: Model? = nil
			local standingFrame = 0

			local function stand(index: number)
				standingFrame = index
				local frame = frames[index]
				if not (shapes and frame) then
					return
				end
				local shape = shapes[frame.speciesId]
				if not shape then
					local made = takeShape(frame.speciesId)
					if not made then
						return
					end
					shapes[frame.speciesId] = made
					made:ScaleTo(shapeStuds / (tonumber(made:GetAttribute("Longest")) or 1))
					made:PivotTo(cf)
					shape = made
				end
				if standing and standing ~= shape then
					standing.Parent = nil
				end
				shape.Parent = holder
				standing = shape
			end

			local function turn()
				local now = Workspace:GetServerTimeNow()
				if now >= revealAt then
					-- The plant's own timer ends the roll; this only stops turning.
					return
				end
				local index = HatchRoll.frameAt(frames, math.clamp((now - opens) / window, 0, 1))
				if index ~= standingFrame then
					stand(index)
				end
				local at = markAt
				if not quiet then
					at += Vector3.new(0,
						math.sin((now - opens) / WORLD.BobSeconds * math.pi * 2) * WORLD.BobStuds, 0)
				end
				-- Turned to whoever is looking, about its own upright and no other way.
				local eye = Workspace.CurrentCamera
				local toward = if eye
					then Vector3.new(eye.CFrame.Position.X, at.Y, eye.CFrame.Position.Z)
					else at
				sign.CFrame = if (toward - at).Magnitude > 0.1 then CFrame.lookAt(at, toward) else CFrame.new(at)
			end

			job.rolling = RunService.RenderStepped:Connect(function()
				if job.done or not holder.Parent then
					endRoll(job)
					return
				end
				local ok, err = pcall(turn)
				if not ok then
					-- The roll is decoration: it goes, and the plant still comes.
					warn("[Seed/HatchFX] the roll failed: " .. tostring(err))
					endRoll(job)
				end
			end)
			-- Drawn once now, so the first frame anybody sees has a shape standing and
			-- the sign turned their way.
			if not pcall(turn) then
				endRoll(job)
			end
		end)
	end

	--==========================================================================
	-- AND THE CREATURE
	--
	-- With a roll it comes up AT `revealAt`, which is the moment the hotbar and
	-- the Bag stop calling it ???: the world shows the plant no later than
	-- anything else does.
	--==========================================================================
	local startAt = if rolled > 0
		then revealAt - Workspace:GetServerTimeNow()
		else paidLead + BURST * 0.55 - behind
	task.delay(math.max(startAt, 0), function()
		if job.done or not folder.Parent then
			return
		end
		-- The roll is over: the shapes and the question mark go as the plant comes.
		endRoll(job)
		local okBuild, model = pcall(function()
			return CreatureModel.Build(species, tier, CreatureModel.STAGE_GROWN, cf, folder)
		end)
		if not okBuild or typeof(model) ~= "Instance" then
			finish(job)
			return
		end
		local creature = model :: Model
		scrub(creature)
		local primary = creature.PrimaryPart
		if not primary then
			finish(job)
			return
		end

		--======================================================================
		-- THE RARE ACCENT (2026-09-27): with the CREATURE, not the timer. The
		-- fanfare above marks the burst; this marks the thing it revealed, the
		-- moment it is built and starts to rise. Only for the form rarities
		-- GameConfig.Sfx.RevealAccentFor names, and once per hatch however
		-- often its reveal arrives.
		--======================================================================
		--
		-- WITH A ROLL (2026-09-29) the fanfare is here as well: it names the
		-- rarity, so it sounds with the plant and not with the burst.
		local accent = REVEAL_ACCENT[species.Rarity]
		if rolled > 0 then
			fanfare()
		end
		if accent and (token == 0 or not accented[token]) and SoundKit.has(accent) then
			if token ~= 0 then
				accented[token] = true
			end
			SoundKit.emit(accent, flashPart)
		end

		local rest = creature:GetPivot()
		local height = creature:GetExtentsSize().Y
		local rise = height * REVEAL.RiseShare
		local gui, shimmer = label(folder, primary, species, tier,
			tonumber(payload.income) or 0, payload.discovery == true)
		gui.Enabled = false

		local began = os.clock()
		local labelUntil = math.huge
		job.connection = RunService.RenderStepped:Connect(function()
			if job.done or not creature.Parent then
				finish(job)
				return
			end
			local age = os.clock() - began
			local t = math.clamp(age / REVEAL.Seconds, 0, 1)
			-- Ease out, so it arrives rather than stops.
			local eased = 1 - (1 - t) * (1 - t)
			local scale = REVEAL.ScaleStart + (1 - REVEAL.ScaleStart) * eased
			-- NO TURN. A lean it settles out of, and a rise out of the glow: a
			-- reveal that spins reads as a shop viewport.
			local lean = math.rad(REVEAL.LeanDegrees) * (1 - eased)
			local ok = pcall(function()
				creature:ScaleTo(scale)
				creature:PivotTo(rest
					* CFrame.new(0, -rise * (1 - eased), 0)
					* CFrame.Angles(lean, 0, 0))
			end)
			if not ok then
				finish(job)
				return
			end
			if t >= 1 then
				if labelUntil == math.huge then
					labelUntil = os.clock() + LABEL.Seconds
					gui.Enabled = true
				end
				if shimmer then
					-- The Speed rail's treatment: a shallow brightness wobble,
					-- bounded, and only for Legendary and above.
					local wobble = 0.85 + 0.15 * math.sin(os.clock() * 9)
					local base = SeedData.FormColor(species)
					shimmer.TextColor3 = base:Lerp(Color3.new(1, 1, 1), 1 - wobble)
				end
				if os.clock() >= labelUntil then
					-- Fade both together: the label is the creature's, not the
					-- world's, and one outliving the other reads as a leftover.
					for _, d in ipairs(creature:GetDescendants()) do
						if d:IsA("BasePart") then
							TweenService:Create(d,
								TweenInfo.new(LABEL.FadeSeconds), { Transparency = 1 }):Play()
						end
					end
					for _, d in ipairs(gui:GetDescendants()) do
						if d:IsA("TextLabel") then
							TweenService:Create(d,
								TweenInfo.new(LABEL.FadeSeconds), { TextTransparency = 1 }):Play()
						end
					end
					local ending = job
					task.delay(LABEL.FadeSeconds + 0.05, function()
						finish(ending)
					end)
					if job.connection then
						job.connection:Disconnect()
						job.connection = nil
					end
				end
			end
		end)
	end)

	-- THE BACKSTOP. Whatever happens above -- a build that throws, a streamed-out
	-- part, a client that alt-tabs through the whole thing -- this folder is gone.
	task.delay(math.max(rolled - behind, 0) + paidLead + BURST + REVEAL.Seconds + LABEL.Seconds
		+ LABEL.FadeSeconds + 1,
		function()
			finish(job)
		end)
end

--==============================================================================
-- THE CHANNEL
--==============================================================================
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local channel = if remotes
		then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
		else nil
	if not (channel and channel:IsA("RemoteEvent")) then
		return
	end
	channel.OnClientEvent:Connect(function(action: any, payload: any)
		if action ~= HATCH.Action then
			return
		end
		local ok, err = pcall(playReveal, payload)
		if not ok then
			warn("[Seed/HatchFX] reveal failed: " .. tostring(err))
		end
	end)
end)

-- Dying mid-reveal cleans up: the plant is in the Backpack either way, and a
-- creature left standing in a bed that nobody owns is the one thing this must
-- never leave behind. A roll goes the same way, question mark and all: the
-- hotbar shows the plant when its time comes, whether or not this drew it.
player.CharacterRemoving:Connect(function()
	for _, job in pairs(live) do
		finish(job)
	end
end)
