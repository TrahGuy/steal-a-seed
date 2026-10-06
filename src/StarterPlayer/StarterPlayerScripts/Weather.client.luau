--!strict
-- Steal a Seed :: Weather (client)
--
-- What this client sees of the Rain event (2026-10-02): the rain over its own
-- camera wherever it goes, the white clouds it builds for itself round the
-- island, down the road and along the temporary biome, and the biome fading
-- away behind thickening cloud when the rain ends. Everything is read off the
-- server's attributes (GameConfig.Weather.Attributes); nothing here decides
-- anything, and a player who joins mid-event is right on their first frame.
-- The sky's cloud layer and the overcast light are WorldClock's (Lighting has
-- one owner); its icon over the hotbar is BoostIconsUI's.
--
--==============================================================================
-- THE RAIN, OVER THE CAMERA, EVERYWHERE
--
-- Two ParticleEmitters on two parts that follow the camera, under
-- workspace.CurrentCamera so they never replicate: a dense near sheet of thin
-- streaks over Area studs, and a sparser far sheet of bigger drops over
-- FarArea, so rain reads up close and at a distance alike -- at the hub, on a
-- plot, down every biome, over the bridge, in the temporary biome -- with no
-- dry gap, because the sheets go where the camera goes. The rates fade in and
-- out with the event; a touch screen gets the near sheet at its reduced rate
-- and no far sheet; REDUCED FX, or Roblox's reduced motion, gets none.
--
-- THE RAIN'S SOUND (2026-10-02): ONE flat loop, the RainAmbience cue on the
-- World bus (SOUND FX moves it, MUSIC does not), its level the rain's own
-- `level` -- in and out with the drops, full at once for a late joiner -- and a
-- little louder in a Thunderstorm (Audio.StormAmbience), never a second loop.
-- The music under the rain is Music.client's (Music.RainTracks).
--
-- THE WHITE CLOUDS are Shared/RainClouds' recipe, built here by every client
-- for itself the moment it sees the rain's state: banks of overlapping balls,
-- faded from one number per zone, bobbing gently (still under reduced
-- motion), lit white plastic by day and a dim self-lit grey-blue by night.
-- They go when the rain is gone. The server holds no part of them.
--==============================================================================
-- A THUNDERSTORM (2026-10-02), the same event in its heavier mode (the Mode
-- attribute): denser streaks (Weather.Thunder.Rain, a phone still at its
-- reduced rate), thicker banks while it falls, and now and then a jagged bolt
-- somewhere round the camera, on the moments RainClouds.lightning names --
-- the same moments as WorldClock's flash of light. Under reduced motion the
-- bolt is a faint one and there is no flash. Each bolt sounds ONCE where it
-- lands (ThunderClap, positional, fading with distance; at most
-- Audio.MaxStrikeSounds at a time), and a storm this client saw begin opens
-- with ThunderstormOpening, once -- never for a late joiner or a refused start.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local RainClouds = require(Shared:WaitForChild("RainClouds"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local player = Players.LocalPlayer
local W = GameConfig.Weather
local ATTR = W.Attributes
local TAGS = W.Tags
local CL = W.Clouds
local PHASE = GameConfig.Attributes.WorldPhase
local NIGHT = GameConfig.WorldCycle.PhaseNight
local TAU = math.pi * 2
-- The clouds and the biome are redrawn this often; the rain's rate every frame.
local FOG_EVERY = 0.1
local THUNDER = W.Thunder
local AUDIO = W.Audio

-- A re-run of this script (Rojo in Play) hands the old copy's work over.
local playerScripts = player:WaitForChild("PlayerScripts")
local previous = playerScripts:FindFirstChild("WeatherCleanup")
if previous and previous:IsA("BindableEvent") then
	previous:Fire()
	previous:Destroy()
end
local cleanupEvent = Instance.new("BindableEvent")
cleanupEvent.Name = "WeatherCleanup"
cleanupEvent.Parent = playerScripts

local connections: { RBXScriptConnection } = {}

local stepStorm: (string?, boolean) -> ()

--==============================================================================
-- THE RAIN
--==============================================================================
local function sheet(name: string, area: number): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(area, 1, area)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function streaks(parent: BasePart, name: string, size: number, near: number, far: number, life: number): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(life, life * 1.3)
	emitter.Speed = NumberRange.new(52, 64)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.SpreadAngle = Vector2.new(4, 4)
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.Size = NumberSequence.new(size)
	-- Long and thin along the fall.
	emitter.Squash = NumberSequence.new(-2.2)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, near),
		NumberSequenceKeypoint.new(1, far),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(196, 212, 232))
	emitter.LightEmission = 0.35
	emitter.LightInfluence = 0.6
	emitter.Rotation = NumberRange.new(0)
	emitter.Drag = 0
	emitter.Enabled = true
	emitter.Parent = parent
	return emitter
end

local anchor = sheet("RainAnchor", W.Rain.Area)
local farAnchor = sheet("RainAnchorFar", W.Rain.FarArea)
local emitter = streaks(anchor, "Rain", 0.42, 0.55, 0.8, 0.8)
local farEmitter = streaks(farAnchor, "RainFar", 1.15, 0.72, 0.9, 1.3)

-- How much of the rain shows, 0 to 1, eased toward the event's state -- and
-- 1 at once for a player who joins while it already rains.
local level = 0
local shownRate, shownFar = -1, -1

local function raining(state: any): boolean
	return state == "opening" or state == "active"
end

local function placeAnchors()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if anchor.Parent ~= camera then
		anchor.Parent = camera
		farAnchor.Parent = camera
	end
	local cf = camera.CFrame
	local look = cf.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local ahead = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zero
	anchor.CFrame = CFrame.new(cf.Position + Vector3.new(0, 28, 0) + ahead * 16)
	farAnchor.CFrame = CFrame.new(cf.Position + Vector3.new(0, 44, 0) + ahead * 40)
end

--==============================================================================
-- THE WHITE CLOUDS, BUILT HERE
--==============================================================================
type BankInstance = { model: Model, base: CFrame, zone: string, phase: number, parts: { BasePart } }
local cloudFolder: Folder? = nil
local banks: { BankInstance } = {}
local cloudLook: boolean? = nil

local function buildClouds()
	if cloudFolder then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SeedRainClouds"
	local rng = Random.new(CL.Seed + 7)
	for _, bank in ipairs(RainClouds.banks()) do
		local model = Instance.new("Model")
		model.Name = bank.name
		local base = CFrame.new(bank.at) * CFrame.Angles(0, bank.yaw, 0)
		local parts: { BasePart } = {}
		for _, puff in ipairs(bank.puffs) do
			local p = Instance.new("Part")
			p.Name = "Puff"
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(puff.diameter, puff.diameter, puff.diameter)
			p.CFrame = base * CFrame.new(puff.offset)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Transparency = 1
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p:SetAttribute("Zone", bank.zone)
			CollectionService:AddTag(p, TAGS.Fog)
			p.Parent = model
			table.insert(parts, p)
		end
		model.WorldPivot = base
		model.Parent = folder
		table.insert(banks, { model = model, base = base, zone = bank.zone, phase = rng:NextNumber(0, TAU), parts = parts })
	end
	folder.Parent = Workspace
	cloudFolder = folder
	cloudLook = nil
end

local function clearClouds()
	if cloudFolder then
		cloudFolder:Destroy()
		cloudFolder = nil
		table.clear(banks)
		cloudLook = nil
	end
end

-- Day or night, applied once per change.
local function applyLook(night: boolean)
	if cloudLook == night then
		return
	end
	cloudLook = night
	local look = RainClouds.look(night)
	for _, b in ipairs(banks) do
		for _, p in ipairs(b.parts) do
			p.Color = look.Color
			p.Material = look.Material
		end
	end
end

local function zoneTarget(targets: RainClouds.Targets, zone: string): number
	if zone == "biome" then
		return targets.biome
	elseif zone == "entrance" then
		return targets.entrance
	elseif zone == "road" then
		return targets.road
	end
	return targets.perimeter
end

--==============================================================================
-- THE BIOME, BY TAG
--==============================================================================
-- The biome's parts, each with the transparency it was built at.
local terrainParts: { [BasePart]: number } = {}

local function watch(tag: string, add: (BasePart) -> (), drop: (BasePart) -> ())
	for _, part in ipairs(CollectionService:GetTagged(tag)) do
		if part:IsA("BasePart") then
			add(part)
		end
	end
	table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(function(part)
		if part:IsA("BasePart") then
			add(part)
		end
	end))
	table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(function(part)
		if part:IsA("BasePart") then
			drop(part)
		end
	end))
end

local function addTerrain(part: BasePart)
	terrainParts[part] = part.Transparency
end
local function dropTerrain(part: BasePart)
	terrainParts[part] = nil
end
watch(TAGS.Terrain, addTerrain, dropTerrain)
watch(TAGS.Gate, addTerrain, dropTerrain)

-- The state, and how long it has been in it: the rain's start while opening,
-- the entrance's opening while active, the closing's start while closing.
local function stateNow(): (string?, number)
	local state = Workspace:GetAttribute(ATTR.State)
	if type(state) ~= "string" then
		return nil, 0
	end
	local now = Workspace:GetServerTimeNow()
	local from = if state == "opening" then Workspace:GetAttribute(ATTR.StartedAt)
		elseif state == "active" then Workspace:GetAttribute(ATTR.OpenedAt)
		else Workspace:GetAttribute(ATTR.ClosingAt)
	return state, now - (tonumber(from) or now)
end

--==============================================================================
-- THE THUNDERSTORM'S LIGHTNING, ITS STRIKES AND ITS OPENING
--==============================================================================
local L = THUNDER.Lightning
local lastFlash = 0

-- One jagged bolt from the cloud base to the ground, somewhere round the
-- camera (never on top of it), for the flash's length; under the camera, so it
-- never replicates. Answers where it landed.
local function bolt(eventId: number, index: number, faint: boolean): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local rng = Random.new(eventId * 1009 + index * 31)
	local angle = rng:NextNumber(0, TAU)
	local dist = rng:NextNumber(L.Radius * 0.35, L.Radius)
	local here = camera.CFrame.Position
	local ground = Vector3.new(here.X + math.cos(angle) * dist, GameConfig.Map.GroundY, here.Z + math.sin(angle) * dist)
	local top = ground + Vector3.new(rng:NextNumber(-20, 20), 230, rng:NextNumber(-20, 20))
	local folder = Instance.new("Folder")
	folder.Name = "SeedLightning"
	local from = top
	for i = 1, L.BoltParts do
		local t = i / L.BoltParts
		local jitter = if i == L.BoltParts then Vector3.zero
			else Vector3.new(rng:NextNumber(-14, 14), 0, rng:NextNumber(-14, 14))
		local to = top:Lerp(ground, t) + jitter
		local length = (to - from).Magnitude
		local seg = Instance.new("Part")
		seg.Name = "Bolt"
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.CastShadow = false
		seg.Material = Enum.Material.Neon
		seg.Color = L.Color
		seg.Transparency = if faint then 0.65 else 0
		seg.Size = Vector3.new(1.4, 1.4, length)
		seg.CFrame = CFrame.lookAt((from + to) / 2, to)
		seg.Parent = folder
		from = to
	end
	folder.Parent = camera
	task.delay(L.Seconds, function()
		folder:Destroy()
	end)
	return ground
end

-- A strike's ONE sound, where the bolt landed: a small local part (under the
-- camera, never replicated) holding SoundKit's positional one-shot, so it falls
-- off with distance like every world sound. At most Audio.MaxStrikeSounds at
-- once -- the oldest is cut for a new one -- and each goes with its part.
local strikeSpots: { BasePart } = {}

local function strikeSound(at: Vector3)
	local camera = Workspace.CurrentCamera
	if not camera or not SoundKit.has(AUDIO.ThunderClap) then
		return
	end
	while #strikeSpots >= AUDIO.MaxStrikeSounds do
		local oldest = table.remove(strikeSpots, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	local spot = Instance.new("Part")
	spot.Name = "SeedStrikeSound"
	spot.Size = Vector3.one
	spot.Transparency = 1
	spot.Anchored = true
	spot.CanCollide = false
	spot.CanQuery = false
	spot.CanTouch = false
	spot.CastShadow = false
	spot.CFrame = CFrame.new(at)
	spot.Parent = camera
	table.insert(strikeSpots, spot)
	SoundKit.emit(AUDIO.ThunderClap, spot)
	task.delay(8, function()
		local i = table.find(strikeSpots, spot)
		if i then
			table.remove(strikeSpots, i)
		end
		spot:Destroy()
	end)
end

-- A Thunderstorm's opening, ONCE, for an event this client saw begin: a new
-- EventId whose Mode is "thunder", no older than Audio.OpeningSeconds. The event
-- already running when this script starts (a late joiner, a re-run) is heard
-- already; a refused or duplicate start writes no new id, and a Rain is not a
-- Thunderstorm.
local heardEvent: any = Workspace:GetAttribute(ATTR.EventId)

local function stepOpening()
	local id = Workspace:GetAttribute(ATTR.EventId)
	if type(id) ~= "number" or id == heardEvent then
		return
	end
	local mode = Workspace:GetAttribute(ATTR.Mode)
	if mode == nil then
		-- The start's attributes are not all here yet.
		return
	end
	heardEvent = id
	local started = Workspace:GetAttribute(ATTR.StartedAt)
	if mode == "thunder" and type(started) == "number"
		and Workspace:GetServerTimeNow() - started <= AUDIO.OpeningSeconds then
		SoundKit.play(AUDIO.ThunderstormOpening)
	end
end

-- The rain's loop: one, at the rain's level (a storm's a little louder); played
-- when the rain starts showing, stopped when it has faded out.
local ambienceShown = -1
local ambienceSound: Sound? = nil

local function stepAmbience(thunder: boolean)
	local cue = SoundKit.cue(AUDIO.RainAmbience)
	if not cue then
		return
	end
	if level <= 0 then
		if ambienceShown >= 0 then
			ambienceShown = -1
			ambienceSound = nil
			SoundKit.stop(AUDIO.RainAmbience)
		end
		return
	end
	local want = (cue.volume or 0.5) * level * (if thunder then AUDIO.StormAmbience else 1)
	if ambienceShown < 0 then
		ambienceShown = want
		ambienceSound = SoundKit.play(AUDIO.RainAmbience, { volume = want })
	elseif math.abs(want - ambienceShown) > 0.002 then
		ambienceShown = want
		local sound = ambienceSound
		if sound and sound.Parent then
			sound.Volume = want
		end
	end
end

function stepStorm(state: string?, thunder: boolean)
	if not (thunder and raining(state)) then
		return
	end
	local id, started = Workspace:GetAttribute(ATTR.EventId), Workspace:GetAttribute(ATTR.StartedAt)
	if type(id) ~= "number" or type(started) ~= "number" then
		return
	end
	local bright, index = RainClouds.lightning(id, started, Workspace:GetServerTimeNow())
	if index > lastFlash and bright > 0 then
		lastFlash = index
		local landed = bolt(id, index, StatusText.reducedMotion())
		if landed then
			strikeSound(landed)
		end
	elseif index < lastFlash then
		-- A new event: its flashes are counted from one again.
		lastFlash = index
	end
end

local fogClock = 0

local function step(dt: number)
	local state, since = stateNow()
	local wantLevel = if raining(state) then 1 else 0
	if level ~= wantLevel then
		local pace = dt / math.max(0.05, W.RainFadeSeconds)
		level = if wantLevel > level then math.min(wantLevel, level + pace) else math.max(wantLevel, level - pace)
	end
	local thunder = Workspace:GetAttribute(ATTR.Mode) == "thunder"
	stepOpening()
	stepAmbience(thunder)
	local rates = if thunder then THUNDER.Rain else W.Rain
	local rate, far = 0, 0
	if level > 0 and not StatusText.reducedMotion() then
		if UserInputService.TouchEnabled then
			rate = rates.ReducedRate * level
		else
			rate = rates.Rate * level
			far = rates.FarRate * level
		end
	end
	stepStorm(state, thunder)
	if rate ~= shownRate or far ~= shownFar then
		shownRate, shownFar = rate, far
		emitter.Rate = rate
		farEmitter.Rate = far
	end
	if rate > 0 then
		placeAnchors()
	elseif anchor.Parent ~= nil and level <= 0 then
		anchor.Parent = nil
		farAnchor.Parent = nil
	end

	fogClock += dt
	if fogClock < FOG_EVERY then
		return
	end
	fogClock = 0
	local targets = RainClouds.targets(state, since)
	-- While it opens the clouds come in with the rain; while it closes the
	-- targets above are the whole story.
	local present = if state == "closing" then 1 else level
	if state ~= nil and not cloudFolder then
		buildClouds()
	end
	if cloudFolder then
		applyLook(Workspace:GetAttribute(PHASE) == NIGHT)
		local still = StatusText.reducedMotion()
		local now = Workspace:GetServerTimeNow()
		-- A Thunderstorm's banks are thicker while it falls; the closing is the
		-- rain's own, so they fade away exactly as it does.
		local thick = if raining(state) and Workspace:GetAttribute(ATTR.Mode) == "thunder"
			then THUNDER.CloudTransparency
			else 1
		for _, b in ipairs(banks) do
			local t = 1 + (zoneTarget(targets, b.zone) * thick - 1) * present
			for _, p in ipairs(b.parts) do
				if math.abs(p.Transparency - t) > 0.004 then
					p.Transparency = t
				end
			end
			if not still then
				b.model:PivotTo(b.base * CFrame.new(0, math.sin(now / CL.Bob.Seconds * TAU + b.phase) * CL.Bob.Studs, 0))
			end
		end
		if state == nil and level <= 0 then
			clearClouds()
		end
	end
	if targets.gone > 0 then
		for part, base in pairs(terrainParts) do
			local t = base + (1 - base) * targets.gone
			if math.abs(part.Transparency - t) > 0.004 then
				part.Transparency = t
			end
		end
	end
end

-- A late joiner: the rain, and the clouds, at full at once.
if raining(Workspace:GetAttribute(ATTR.State)) then
	level = 1
end
step(0)

table.insert(connections, RunService.Heartbeat:Connect(step))

local function cleanup()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	anchor:Destroy()
	farAnchor:Destroy()
	clearClouds()
	SoundKit.stop(AUDIO.RainAmbience)
	for _, spot in ipairs(strikeSpots) do
		spot:Destroy()
	end
	table.clear(strikeSpots)
	cleanupEvent:Destroy()
end
table.insert(connections, cleanupEvent.Event:Connect(cleanup))
table.insert(connections, script.Destroying:Connect(cleanup))
