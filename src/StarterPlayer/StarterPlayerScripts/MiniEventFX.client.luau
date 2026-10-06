--!strict
-- Steal a Seed :: MiniEventFX
--
-- What a mini event looks like on this screen (2026-10-03, TICKET DISCO):
--
--   THE DISCO (ticketdisco, disco)  a disco ball over the hub, turning slowly,
--      a few soft beams sweeping the deck from it, a gentle colour drift and a
--      handful of sparkles -- all of it faded in and out over FadeSeconds. The
--      soft tint over the whole light is WorldClock's (Lighting's one owner);
--      the music is Music.client's; the dancing is DiscoDance.client's.
--   THE TICKETS (ticketdisco, tickets)  every ticket record the server keeps in
--      ReplicatedStorage, drawn: a Golden Spinwheel Ticket (ItemArt's Spin
--      Ticket) falling from the sky to its spot, then hovering and turning
--      over a soft gold ring; faded for a player who has their three; gone
--      with a little lift toward its collector, or a fade when it expires.
--
-- ENTIRELY LOCAL. Every part is this client's own, in a non-archivable folder
-- under Workspace, anchored, with no collision, no touch and no queries -- a
-- ticket cannot block a body or a click -- and nothing is sent back: the
-- server decides who took a ticket. Nothing flashes: colours move through the
-- wheel over HueSeconds, beams sweep at a walking pace.
--
-- REDUCED MOTION (Reduced FX, or Roblox's own) keeps the ball and the beams
-- still and their colours steady, draws no sparkles, and shows a ticket at its
-- spot (faded in) rather than falling and spinning. A PHONE gets fewer beams
-- and fewer sparkles.
--
-- AND THE WHOLE MAP (2026-10-03): pools of coloured light and slow spotlights
-- at stations laid out from the map itself (DiscoLights) -- round the hub, the
-- field, the road, every plot, every biome and the rain biome while it stands
-- -- of which only the nearest few are lit (THE MAP'S LIGHTS below). Every
-- disco colour here is the palette's (DiscoLights.colourAt), the same as
-- WorldClock's map-wide tint.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local DiscoLights = require(Shared:WaitForChild("DiscoLights"))
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local M = GameConfig.MiniEvent
local ATTR = M.Attributes
local DISCO = M.Disco
local TICKET = M.Ticket
local MODES: { [string]: any } = M.Modes :: any

-- RE-RUN SAFE: a Rojo re-sync re-runs this while the old folder is up.
local old = Workspace:FindFirstChild(M.FxFolderName)
if old then
	old:Destroy()
end
local fx = Instance.new("Folder")
fx.Name = M.FxFolderName
fx.Archivable = false
fx.Parent = Workspace

local function inert(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Massless = true
end

local function still(): boolean
	return StatusText.reducedMotion()
end

local function phone(): boolean
	return UserInputService.TouchEnabled
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function modeNow(): any
	return MODES[Workspace:GetAttribute(ATTR.Mode) or ""]
end

local function eventRunning(): boolean
	return Workspace:GetAttribute(ATTR.State) == "running" and modeNow() ~= nil
end

--==============================================================================
-- THE DISCO BALL, THE BEAMS AND THE SPARKLES
--==============================================================================
type Disco = {
	model: Model,
	ball: Part,
	chain: Part,
	light: PointLight,
	sparkles: ParticleEmitter,
	floor: Part,
	beams: { { beam: Beam, foot: Attachment, angle: number, reach: number } },
	level: number,
}

local disco: Disco? = nil

-- The palette's colour (2026-10-03; it was a turn of the whole hue wheel).
local function hueAt(t: number, offset: number): Color3
	return DiscoLights.colourAt(t, offset)
end

-- How far in a running event is, as a fade level: a late joiner (or a client
-- that built its effects after the fade) starts at full, not at nothing.
local function joinLevel(): number
	local startedAt = tonumber(Workspace:GetAttribute(ATTR.StartedAt))
	if not startedAt then
		return 0
	end
	return math.clamp((now() - startedAt) / math.max(0.05, M.FadeSeconds), 0, 1)
end

local function buildDisco(): Disco
	local model = Instance.new("Model")
	model.Name = "DiscoBall"

	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * DISCO.BallDiameter
	ball.Material = Enum.Material.Foil
	ball.Color = Color3.fromRGB(214, 220, 232)
	ball.Reflectance = 0.25
	ball.Transparency = 1
	ball.CFrame = CFrame.new(DISCO.BallAt)
	inert(ball)
	ball.Parent = model

	local chain = Instance.new("Part")
	chain.Name = "Chain"
	chain.Size = Vector3.new(0.25, 6, 0.25)
	chain.Material = Enum.Material.Metal
	chain.Color = Color3.fromRGB(150, 150, 160)
	chain.Transparency = 1
	chain.CFrame = CFrame.new(DISCO.BallAt + Vector3.new(0, DISCO.BallDiameter / 2 + 3, 0))
	inert(chain)
	chain.Parent = model

	local light = Instance.new("PointLight")
	light.Range = 34
	light.Brightness = 0
	light.Shadows = false
	light.Parent = ball

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Rate = 0
	sparkles.Lifetime = NumberRange.new(1.2, 2)
	sparkles.Speed = NumberRange.new(2, 4)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new(0.2)
	sparkles.LightEmission = 1
	sparkles.Parent = ball

	-- The beams' feet ride on one invisible part at the hub's centre.
	local floor = Instance.new("Part")
	floor.Name = "BeamFloor"
	floor.Size = Vector3.new(1, 1, 1)
	floor.Transparency = 1
	floor.CFrame = CFrame.new(Vector3.new(DISCO.BallAt.X, GameConfig.Map.GroundY + 1, DISCO.BallAt.Z))
	inert(floor)
	floor.Parent = model

	local count = if phone() then DISCO.PhoneBeams else DISCO.Beams
	local top = Instance.new("Attachment")
	top.Name = "BeamTop"
	top.Parent = ball
	local beams = {}
	for i = 1, count do
		local foot = Instance.new("Attachment")
		foot.Name = "BeamFoot" .. i
		foot.Parent = floor
		local beam = Instance.new("Beam")
		beam.Name = "Beam" .. i
		beam.Attachment0 = top
		beam.Attachment1 = foot
		beam.Width0 = 0.6
		beam.Width1 = 7
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Segments = 1
		beam.Transparency = NumberSequence.new(1)
		beam.Parent = model
		table.insert(beams, {
			beam = beam,
			foot = foot,
			angle = (i - 1) / count * math.pi * 2,
			-- Alternate reaches, so the pools of light are not one ring.
			reach = DISCO.BeamReach * (if i % 2 == 0 then 0.6 else 1),
		})
	end
	model.Parent = fx
	return {
		model = model,
		ball = ball,
		chain = chain,
		light = light,
		sparkles = sparkles,
		floor = floor,
		beams = beams,
		level = 0,
	}
end

local function stepDisco(dt: number)
	local mode = modeNow()
	local want = if eventRunning() and mode.Disco then 1 else 0
	local d = disco
	if want == 0 and not d then
		return
	end
	if not d then
		d = buildDisco()
		-- A late joiner sees the event's light as it is now.
		d.level = if want == 1 then joinLevel() else 0
		disco = d
	end
	local made = d :: Disco
	local step = dt / math.max(0.05, M.FadeSeconds)
	made.level = if want > made.level then math.min(1, made.level + step) else math.max(0, made.level - step)
	local level = made.level
	if level <= 0 and want == 0 then
		made.model:Destroy()
		disco = nil
		return
	end
	local calm = still()
	-- The shared start time, so every screen on every server turns together.
	local startedAt = tonumber(Workspace:GetAttribute(ATTR.StartedAt)) or 0
	local t = if calm then 0 else now() - startedAt
	made.ball.Transparency = 1 - level
	made.chain.Transparency = 1 - level
	made.ball.CFrame = CFrame.new(DISCO.BallAt) * CFrame.Angles(0, math.rad(DISCO.BallSpinDegreesPerSecond * t), 0)
	made.light.Brightness = 1.2 * level
	made.light.Color = hueAt(t, 0)
	made.sparkles.Rate = if calm then 0 else (if phone() then DISCO.PhoneSparkleRate else DISCO.SparkleRate) * level
	local fade = 1 - (1 - DISCO.BeamTransparency) * level
	local transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fade),
		NumberSequenceKeypoint.new(1, math.min(1, fade + 0.12)),
	})
	for i, b in ipairs(made.beams) do
		local angle = b.angle + math.rad(DISCO.BeamSweepDegreesPerSecond * t)
		b.foot.Position = Vector3.new(math.cos(angle) * b.reach, 0, math.sin(angle) * b.reach)
		b.beam.Color = ColorSequence.new(hueAt(t, i / #made.beams))
		b.beam.Transparency = transparency
	end
end

--==============================================================================
-- THE MAP'S LIGHTS (2026-10-03)
--
-- The disco reaches the whole playable map, not just the hub: the stations
-- (DiscoLights) are the hub's ring, the field, the road, every plot this client
-- has, every permanent biome and the rain biome's floors while it stands. A
-- fixed handful of lights -- Budget.Full or Budget.Reduced (a phone, or the
-- Reduced quality), none under Reduced FX -- is moved every ReassignSeconds to
-- the stations nearest the player within ActivationRadius, each one fading out
-- of its old station and into its new one, so nothing pops. Pools are
-- PointLights a few studs up; spots are SpotLights high above, their cones
-- leaning a little and turning slowly so a lit patch circles on the floor, with
-- a faint shaft down the cone. Shadows are off on every one.
--
-- REDUCED MOTION: the same lights, still -- spots straight down, no shafts,
-- each station's colour steady. REDUCED FX: none at all; WorldClock's tint and
-- ambient carry the disco across the map on their own.
--
-- ONE CONTROLLER, built when a disco mode starts (or on joining one) and torn
-- down -- every light destroyed, the rain biome's watches disconnected -- when
-- it has faded out after the event. Repeated notices change nothing: the
-- controller is driven by the Workspace attributes, never by messages.
--==============================================================================
local MAPL = DISCO.Map
local RAIN_FOLDER = GameConfig.Weather.Biome.FolderName

type Rig = {
	part: Part,
	light: Light,
	kind: string,
	station: DiscoLights.Station?,
	alpha: number,
	want: boolean,
	beam: Beam?,
	foot: Part?,
}

type MapLights = {
	folder: Folder,
	level: number,
	fixed: { DiscoLights.Station },
	rain: { DiscoLights.Station },
	rainDirty: boolean,
	rainWatches: { RBXScriptConnection },
	watches: { RBXScriptConnection },
	rigs: { Rig },
	quality: string,
	calm: boolean,
	lastPick: number,
}

local mapLights: MapLights? = nil

-- "Full", "Reduced" (a phone, or the Reduced quality) or "Off" (Reduced FX).
local function quality(): string
	local q = player:GetAttribute(GameConfig.Afterimage.QualityAttribute)
	if q == "Off" then
		return "Off"
	end
	if q == "Reduced" or phone() then
		return "Reduced"
	end
	return "Full"
end

local function buildRig(folder: Folder, kind: string, calm: boolean): Rig
	local part = Instance.new("Part")
	part.Name = if kind == "spot" then "DiscoSpot" else "DiscoPool"
	part.Size = Vector3.new(0.4, 0.4, 0.4)
	part.Transparency = 1
	inert(part)
	part.CFrame = CFrame.new(0, -500, 0)
	local light: Light
	if kind == "spot" then
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Angle = MAPL.Spot.Angle
		spot.Range = MAPL.Spot.Range
		light = spot
	else
		local pool = Instance.new("PointLight")
		pool.Range = MAPL.Pool.Range
		light = pool
	end
	light.Shadows = false
	light.Brightness = 0
	light.Enabled = false
	light.Parent = part
	part.Parent = folder
	local rig: Rig = { part = part, light = light, kind = kind, station = nil, alpha = 0, want = false, beam = nil, foot = nil }
	if kind == "spot" and not calm then
		-- The faint shaft: from the lamp to where the cone's axis meets the floor.
		local foot = Instance.new("Part")
		foot.Name = "DiscoSpotFoot"
		foot.Size = Vector3.new(0.4, 0.4, 0.4)
		foot.Transparency = 1
		inert(foot)
		foot.CFrame = CFrame.new(0, -500, 0)
		foot.Parent = folder
		local a0 = Instance.new("Attachment")
		a0.Parent = part
		local a1 = Instance.new("Attachment")
		a1.Parent = foot
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 1
		beam.Width1 = 2 * MAPL.Spot.Height * math.tan(math.rad(MAPL.Spot.Angle / 2)) * 0.55
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Segments = 1
		beam.Transparency = NumberSequence.new(1)
		beam.Parent = part
		rig.beam = beam
		rig.foot = foot
	end
	return rig
end

-- The rain biome's stations, recomputed when its folder or its floors change.
local function watchRain(ml: MapLights)
	for _, c in ipairs(ml.rainWatches) do
		c:Disconnect()
	end
	table.clear(ml.rainWatches)
	ml.rain = {}
	ml.rainDirty = true
	local folder = Workspace:FindFirstChild(RAIN_FOLDER)
	if folder then
		local function dirty()
			ml.rainDirty = true
		end
		table.insert(ml.rainWatches, folder.DescendantAdded:Connect(dirty))
		table.insert(ml.rainWatches, folder.DescendantRemoving:Connect(dirty))
	end
end

local function buildMap(): MapLights
	local folder = Instance.new("Folder")
	folder.Name = "DiscoMapLights"
	folder.Parent = fx
	local q = quality()
	local calm = still()
	local ml: MapLights = {
		folder = folder,
		level = 0,
		fixed = DiscoLights.fixedStations(),
		rain = {},
		rainDirty = true,
		rainWatches = {},
		watches = {},
		rigs = {},
		quality = q,
		calm = calm,
		lastPick = -math.huge,
	}
	local pools, spots = DiscoLights.budget(q)
	for _ = 1, pools do
		table.insert(ml.rigs, buildRig(folder, "pool", calm))
	end
	for _ = 1, spots do
		table.insert(ml.rigs, buildRig(folder, "spot", calm))
	end
	-- The rain biome comes and goes with the weather: its folder is watched.
	table.insert(ml.watches, Workspace.ChildAdded:Connect(function(child)
		if child.Name == RAIN_FOLDER then
			watchRain(ml)
		end
	end))
	table.insert(ml.watches, Workspace.ChildRemoved:Connect(function(child)
		if child.Name == RAIN_FOLDER then
			watchRain(ml)
		end
	end))
	watchRain(ml)
	return ml
end

local function destroyMap(ml: MapLights)
	for _, c in ipairs(ml.watches) do
		c:Disconnect()
	end
	for _, c in ipairs(ml.rainWatches) do
		c:Disconnect()
	end
	table.clear(ml.watches)
	table.clear(ml.rainWatches)
	ml.folder:Destroy()
end

-- Where "near" is measured from: the player's body, or the camera.
local function focus(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	local camera = Workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

local function stations(ml: MapLights): { DiscoLights.Station }
	if ml.rainDirty then
		ml.rainDirty = false
		local folder = Workspace:FindFirstChild(RAIN_FOLDER)
		ml.rain = if folder then DiscoLights.rainStations(folder) else {}
	end
	local list = table.clone(ml.fixed)
	for _, plot in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if plot:IsDescendantOf(Workspace) then
			local s = DiscoLights.plotStation(plot)
			if s then
				table.insert(list, s)
			end
		end
	end
	for _, s in ipairs(ml.rain) do
		table.insert(list, s)
	end
	return list
end

local function reassign(ml: MapLights)
	local at = focus()
	if not at then
		return
	end
	local pools, spots = DiscoLights.budget(ml.quality)
	local chosen = DiscoLights.pick(stations(ml), at, pools, spots)
	local byKey: { [string]: DiscoLights.Station } = {}
	for s in pairs(chosen) do
		byKey[s.key] = s
	end
	local held: { [string]: boolean } = {}
	for _, rig in ipairs(ml.rigs) do
		local s = rig.station
		if s then
			local fresh = byKey[s.key]
			rig.want = fresh ~= nil
			if fresh then
				rig.station = fresh
				held[s.key] = true
			end
		end
	end
	for key, s in pairs(byKey) do
		if not held[key] then
			for _, rig in ipairs(ml.rigs) do
				if rig.station == nil and rig.kind == s.kind then
					rig.station = s
					rig.want = true
					rig.alpha = 0
					break
				end
			end
		end
	end
end

local function stepMap(dt: number)
	local mode = modeNow()
	local on = eventRunning() and mode.Disco and quality() ~= "Off"
	local want = if on then 1 else 0
	local ml = mapLights
	if want == 0 and not ml then
		return
	end
	if ml and (ml.quality ~= quality() or ml.calm ~= still()) and want == 1 then
		-- The quality or motion setting changed mid-disco: the lights rebuilt to suit.
		destroyMap(ml)
		ml = nil
		mapLights = nil
	end
	if not ml then
		local made = buildMap()
		made.level = if want == 1 then joinLevel() else 0
		mapLights = made
		ml = made
	end
	local m = ml :: MapLights
	local step = dt / math.max(0.05, M.FadeSeconds)
	m.level = if want > m.level then math.min(1, m.level + step) else math.max(0, m.level - step)
	if m.level <= 0 and want == 0 then
		destroyMap(m)
		mapLights = nil
		return
	end
	if os.clock() - m.lastPick >= MAPL.ReassignSeconds then
		m.lastPick = os.clock()
		reassign(m)
	end
	local startedAt = tonumber(Workspace:GetAttribute(ATTR.StartedAt)) or 0
	local t = if m.calm then 0 else now() - startedAt
	local swap = dt / math.max(0.05, MAPL.SwapSeconds)
	local tilt = math.rad(MAPL.Spot.TiltDegrees)
	for _, rig in ipairs(m.rigs) do
		local s = rig.station
		if not s then
			continue
		end
		rig.alpha = if rig.want then math.min(1, rig.alpha + swap) else math.max(0, rig.alpha - swap)
		if rig.alpha <= 0 and not rig.want then
			-- Faded out of its old station: free for the next one.
			rig.station = nil
			rig.light.Enabled = false
			if rig.beam then
				rig.beam.Transparency = NumberSequence.new(1)
			end
			continue
		end
		local k = m.level * rig.alpha
		local colour = DiscoLights.colourAt(t, s.offset)
		rig.light.Color = colour
		rig.light.Enabled = k > 0.01
		if rig.kind == "spot" then
			local head = s.at + Vector3.new(0, MAPL.Spot.Height, 0)
			local cf = if m.calm
				then CFrame.new(head)
				else CFrame.new(head) * CFrame.Angles(0, s.offset * math.pi * 2 + math.rad(MAPL.Spot.SweepDegreesPerSecond) * t, 0)
					* CFrame.Angles(tilt, 0, 0)
			rig.part.CFrame = cf
			rig.light.Brightness = MAPL.Spot.Brightness * k
			local beam, foot = rig.beam, rig.foot
			if beam and foot then
				local down = -cf.UpVector
				local reach = MAPL.Spot.Height / math.max(0.2, -down.Y)
				foot.CFrame = CFrame.new(head + down * reach)
				beam.Color = ColorSequence.new(colour)
				local fade = 1 - (1 - MAPL.Spot.BeamTransparency) * k
				beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, fade),
					NumberSequenceKeypoint.new(1, math.min(1, fade + 0.08)),
				})
			end
		else
			rig.part.CFrame = CFrame.new(s.at + Vector3.new(0, MAPL.Pool.Height, 0))
			rig.light.Brightness = MAPL.Pool.Brightness * k
		end
	end
end

--==============================================================================
-- THE TICKETS
--==============================================================================
type Shown = {
	record: Instance,
	model: Model,
	ring: Part,
	parts: { BasePart },
	at: Vector3,
	droppedAt: number,
	landsAt: number,
	expiresAt: number,
	-- Set when it leaves: how, and when.
	leaving: string?,
	leftAt: number,
	phase: number,
}

local shown: { [Instance]: Shown } = {}
local ticketTemplate: Model? = nil

local function ticketModel(): Model?
	local template = ticketTemplate
	if not template then
		local build = ItemArt.builder("mini-event-ticket", { kind = "ticket", tier = 1 })
		if not build then
			return nil
		end
		local holder = Instance.new("Folder")
		local made = build(holder)
		if not made then
			holder:Destroy()
			return nil
		end
		pcall(function()
			made:ScaleTo(TICKET.Scale)
		end)
		made.Parent = nil
		holder:Destroy()
		ticketTemplate = made
		template = made
	end
	local copy = (template :: Model):Clone()
	return copy
end

local function capped(): boolean
	local count = tonumber(player:GetAttribute(ATTR.PlayerTickets)) or 0
	local cap = tonumber(Workspace:GetAttribute(ATTR.Cap)) or M.Tickets.PerPlayerCap
	return count >= cap
end

local function setAlpha(s: Shown, alpha: number, ringAlpha: number)
	for _, part in ipairs(s.parts) do
		part.Transparency = 1 - alpha
	end
	s.ring.Transparency = 1 - (1 - TICKET.Ring.Transparency) * ringAlpha
end

local function addTicket(record: Instance)
	if shown[record] or not record:IsA("Configuration") or record.Parent == nil then
		return
	end
	local at = record:GetAttribute("At")
	local droppedAt = record:GetAttribute("DroppedAt")
	local landsAt = record:GetAttribute("LandsAt")
	local expiresAt = record:GetAttribute("ExpiresAt")
	if typeof(at) ~= "Vector3" or type(droppedAt) ~= "number" or type(landsAt) ~= "number"
		or type(expiresAt) ~= "number" then
		return
	end
	local model = ticketModel()
	if not model then
		return
	end
	model.Name = "Ticket_" .. record.Name
	local parts: { BasePart } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			inert(d)
			d.Transparency = 1
			table.insert(parts, d)
		end
	end
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.12, TICKET.Ring.Diameter, TICKET.Ring.Diameter)
	ring.CFrame = CFrame.new((at :: Vector3) + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon
	ring.Color = TICKET.Ring.Colour
	ring.Transparency = 1
	inert(ring)
	ring.Parent = model
	model.Parent = fx
	shown[record] = {
		record = record,
		model = model,
		ring = ring,
		parts = parts,
		at = at :: Vector3,
		droppedAt = droppedAt :: number,
		landsAt = landsAt :: number,
		expiresAt = expiresAt :: number,
		leaving = nil,
		leftAt = 0,
		phase = (tonumber(record:GetAttribute("Id")) or 0) * 1.7,
	}
	record:GetAttributeChangedSignal("ClaimedBy"):Connect(function()
		local s = shown[record]
		if s and not s.leaving then
			s.leaving = if record:GetAttribute("ClaimedBy") == player.UserId then "mine" else "taken"
			s.leftAt = os.clock()
		end
	end)
end

local function removeTicket(record: Instance)
	local s = shown[record]
	if s and not s.leaving then
		s.leaving = "gone"
		s.leftAt = os.clock()
	end
end

local function stepTickets()
	local t = now()
	local calm = still()
	local faded = capped()
	for record, s in pairs(shown) do
		local hover = s.at + Vector3.new(0, TICKET.Hover, 0)
		local alpha = if faded then 1 - TICKET.CappedTransparency else 1
		local leaving = s.leaving
		if leaving then
			local k = math.clamp((os.clock() - s.leftAt) / 0.4, 0, 1)
			if k >= 1 then
				s.model:Destroy()
				shown[record] = nil
			else
				local lift = if leaving == "mine" and not calm then k * 2.5 else 0
				s.model:PivotTo(CFrame.new(hover + Vector3.new(0, lift, 0)))
				setAlpha(s, alpha * (1 - k), 1 - k)
			end
			continue
		end
		local pos: Vector3
		local ringAlpha = 0
		if t < s.landsAt then
			-- In the air: falling, swaying a little -- or, still, waiting unseen.
			local k = math.clamp((t - s.droppedAt) / math.max(0.05, s.landsAt - s.droppedAt), 0, 1)
			if calm then
				pos = hover
				alpha *= k
			else
				local eased = k * k
				local sway = math.sin(k * math.pi * 2 + s.phase) * (1 - k) * 1.5
				pos = hover + Vector3.new(sway, TICKET.FallHeight * (1 - eased), 0)
			end
		else
			local bob = if calm then 0 else math.sin((t - s.landsAt) * 2.2 + s.phase) * 0.25
			pos = hover + Vector3.new(0, bob, 0)
			ringAlpha = math.clamp((t - s.landsAt) / 0.3, 0, 1)
		end
		-- The last seconds before it expires, it fades.
		local left = s.expiresAt - t
		if left < TICKET.FadeOutSeconds then
			local k = math.clamp(left / TICKET.FadeOutSeconds, 0, 1)
			alpha *= k
			ringAlpha *= k
		end
		local spin = if calm then 0 else math.rad(TICKET.SpinDegreesPerSecond) * (t - s.droppedAt) + s.phase
		s.model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, spin, 0))
		setAlpha(s, alpha, ringAlpha * (if faded then 0.4 else 1))
	end
end

local folder: Instance? = nil
local function watchFolder(found: Instance)
	folder = found
	for _, child in ipairs(found:GetChildren()) do
		addTicket(child)
	end
	found.ChildAdded:Connect(function(child)
		-- Its attributes arrive with it; a frame later to be sure.
		task.defer(addTicket, child)
	end)
	found.ChildRemoved:Connect(removeTicket)
end

local existing = ReplicatedStorage:FindFirstChild(M.FolderName)
if existing then
	watchFolder(existing)
end
ReplicatedStorage.ChildAdded:Connect(function(child)
	if child.Name == M.FolderName and child ~= folder then
		watchFolder(child)
	end
end)

--==============================================================================
-- EVERY FRAME, ONLY WHILE THERE IS SOMETHING TO DRAW
--==============================================================================
RunService.RenderStepped:Connect(function(dt: number)
	if disco or eventRunning() then
		stepDisco(dt)
	end
	if mapLights or eventRunning() then
		stepMap(dt)
	end
	if next(shown) ~= nil then
		stepTickets()
	end
end)

fx.Destroying:Connect(function()
	table.clear(shown)
	disco = nil
	local ml = mapLights
	if ml then
		for _, c in ipairs(ml.watches) do
			c:Disconnect()
		end
		for _, c in ipairs(ml.rainWatches) do
			c:Disconnect()
		end
	end
	mapLights = nil
end)
