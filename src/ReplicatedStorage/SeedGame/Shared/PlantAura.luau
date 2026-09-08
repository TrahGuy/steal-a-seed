--!strict
--==============================================================================
-- Steal a Seed :: PlantAura
--
-- The crackle a COLOSSAL plant gets and nothing else does.
--
-- Two or three short, thin, jagged arcs snap around the silhouette for about a
-- fifth of a second, then nothing for two to four seconds. That is the whole
-- effect. It is a punctuation mark on the rarest thing in a garden, not weather.
--
--==============================================================================
-- IT IS COSMETIC, CLIENT-SIDE, AND OWNS NO LIFECYCLE OF ITS OWN
--
-- PlantSway already indexes every `Planted` model, waits for its PrimaryPart,
-- drops it on tag removal, and drives the whole bed from ONE Heartbeat on a
-- round robin. Re-implementing any of that here would be a second thing to keep
-- in step with planting, pickup, hatching and streaming -- and the second one is
-- the one that leaks.
--
-- So this module is a mechanism, not a system: PlantSway calls Prepare when it
-- remembers a plant, Forget when it drops one, and Tick once per frame from the
-- Heartbeat it already has. Nothing here connects to anything.
--
-- Nothing is replicated. No arc position ever crosses the wire, there is no
-- remote, and two players watching the same Colossal see different arcs. That is
-- correct: the effect carries no information.
--
--==============================================================================
-- WHY SEGMENTS RATHER THAN A BEAM
--
-- A Beam bends but does not KINK, and the read of lightning is entirely in the
-- kinks. Four thin Neon blocks hinged end to end give an irregular path for four
-- parts, cost nothing to place, and need no texture upload -- which also keeps
-- this inside the project's "everything is built from primitives" rule.
--
-- Neon carries the glow on its own. There is deliberately NO PointLight: a light
-- per arc is the difference between a crackle and a lightning storm, and a
-- hundred and twenty of them is the difference between a game and a slideshow.
--==============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local PlantAura = {}

--==============================================================================
-- THE PALETTES
--
-- `arc` is the body of the bolt and `core` the brief pale centre one segment
-- carries. Both are pitched to SUPPORT a species, never to repaint it: the arc
-- is thin, it is gone in a fifth of a second, and it never sits over a face.
--
-- Keyed by biome rather than by species, because the aura says "this is a
-- Colossal off that road", not "this is a Bellchime".
--==============================================================================
export type Palette = { arc: Color3, core: Color3 }

local PALETTES: { [string]: Palette } = {
	-- Pale leaf-green, with the warm gold that already lives in Greenhollow's
	-- crown accents rather than a yellow invented for the effect.
	greenhollow = {
		arc = Color3.fromRGB(198, 240, 168),
		core = Color3.fromRGB(255, 236, 176),
	},
	-- Amber over sandy gold. Dustbowl is the one biome whose own palette is
	-- already this colour, so the arc reads as heat off the plant.
	dustbowl = {
		arc = Color3.fromRGB(255, 196, 104),
		core = Color3.fromRGB(255, 232, 176),
	},
	-- Muted, on purpose. Tanglemire is the dim biome and a bright arc there
	-- would be the brightest thing on the road.
	tanglemire = {
		arc = Color3.fromRGB(126, 200, 178),
		core = Color3.fromRGB(196, 236, 220),
	},
	-- Ember-orange with a warm-white centre, which is the one palette where the
	-- core is meaningfully hotter than the arc.
	emberroot = {
		arc = Color3.fromRGB(255, 142, 62),
		core = Color3.fromRGB(255, 238, 214),
	},
	-- Lavender into cyan, pale centre. Starbloom already owns this range.
	starbloom = {
		arc = Color3.fromRGB(190, 168, 255),
		core = Color3.fromRGB(214, 248, 255),
	},
}

PlantAura.Palette = PALETTES

local FALLBACK: Palette = {
	arc = Color3.fromRGB(210, 226, 255),
	core = Color3.fromRGB(245, 250, 255),
}

--==============================================================================
-- THE NUMBERS
--
-- Tuned toward "slight". Every one of these was chosen by asking what the
-- SMALLEST version that still reads is, and the gap and the arc count were both
-- pushed down rather than up when it was close.
--==============================================================================
PlantAura.Config = {
	--== when ==--
	-- The starting point the brief asks for. Two to four seconds of nothing is
	-- most of a Colossal's life, which is what keeps it a punctuation mark.
	GapMin = 2.0,
	GapMax = 4.0,
	-- A pulse is over before a player can look at it directly. That is the
	-- point: it is caught in peripheral vision and confirms itself on the next
	-- one, which is how a crackle reads rather than a lamp.
	Life = 0.22,
	-- The FIRST gap is drawn from the whole window plus a slop, so a bed that
	-- streams in as one batch does not fire as one batch.
	FirstGapMax = 5.0,

	--== how much ==--
	ArcsNear = 3,
	ArcsMid = 2,
	ArcsFar = 1,
	Segments = 4,

	--== how big ==--
	-- Arc length is a fraction of the plant's MEASURED height, so it tracks
	-- whatever size curve ships, and then it is CAPPED. The cap is the thing
	-- that matters: a planting cell is 16 x 13.7 studs, so an arc that may
	-- reach five studs off the silhouette cannot cross into a neighbour's cell,
	-- let alone a neighbouring plot -- no matter how wide the plant gets.
	LengthFraction = 0.10,
	LengthMin = 1.6,
	LengthMax = 5.0,
	-- Sideways kink per joint, as a fraction of the arc's length.
	Jitter = 0.22,
	ThickFraction = 0.055,
	ThickMin = 0.10,
	ThickMax = 0.30,
	-- How far off the surface the arc floats. Enough to read as separate from
	-- the plastic, small enough to still be "around the silhouette".
	Standoff = 0.18,

	--== how bright ==--
	-- Never fully opaque even at its peak. This is the single biggest lever on
	-- "subtle" and it is deliberately not 0.
	PeakTransparency = 0.18,
	-- Per-frame flicker, added to the fade. Small -- it is the difference
	-- between electricity and a fading streak.
	Flicker = 0.14,

	--== how many at once ==--
	-- CLIENT-WIDE. Six full gardens is up to 120 Colossals; this is what stops
	-- 120 plants from ever being 120 simultaneous effects. A plant that is due
	-- while the budget is full is RESCHEDULED, not skipped forever.
	MaxConcurrent = 10,

	--== how far ==--
	NearStuds = 70,
	MidStuds = 140,
	FarStuds = 200,
	-- Inside this, an off-screen plant still pulses: it is close enough that a
	-- small camera turn brings it into frame mid-pulse.
	AlwaysStuds = 40,
}

local CFG = PlantAura.Config

--==============================================================================
-- WHAT AN ARC MAY HANG OFF
--
-- Never a face. The brief is explicit that faces, mouths and limbs stay
-- readable, and an arc across an eye is the one placement that would break it.
-- The invisible Base is excluded for a different reason: it is at ground level
-- and does not move with the creature, so an arc on it would sit in the dirt
-- while the plant leaned away.
--==============================================================================
local NEVER = {
	"Eye", "Glint", "Cheek", "Smile", "Lid", "Lash", "Pupil",
	"Base", "Label", "CellRail", "Ref", "StageFloor",
}

local function eligible(p: BasePart): boolean
	for _, word in ipairs(NEVER) do
		if string.find(p.Name, word) then
			return false
		end
	end
	-- Big enough to hang something off. A four-inch decoration would put the
	-- arc's root in a place the eye cannot connect to the creature.
	return p.Size.Magnitude > 0.35
end

--==============================================================================
-- STATE
--==============================================================================
type Seg = { part: BasePart, localCF: CFrame, core: boolean }
type Arc = { anchor: BasePart, segs: { Seg } }
type Pulse = { state: any, arcs: { Arc }, t: number }

export type State = {
	model: Model,
	parts: { BasePart },
	palette: Palette,
	length: number,
	thick: number,
	rng: Random,
	nextAt: number,
	pulsing: boolean,
}

local plants: { State } = {}
local slot: { [State]: number } = {}
local active: { Pulse } = {}
local pool: { BasePart } = {}
local folder: Folder? = nil
local quality = "Full"
local made = 0

--==============================================================================
-- REDUCED EFFECTS IS AN EXISTING SETTING, NOT A NEW ONE
--
-- SpeedFX already reads `SeedAfterimageQuality` off the Player and already
-- defaults touch devices to Reduced. This reads the same attribute and the same
-- three words rather than inventing a second control the player would have to
-- find. Off means no arcs at all; Reduced halves the concurrent budget and
-- drops the far band.
--==============================================================================
local QUALITY_ATTRIBUTE = "SeedAfterimageQuality"

function PlantAura.SetQuality(mode: string)
	if mode == "Full" or mode == "Reduced" or mode == "Off" then
		quality = mode
	end
end

function PlantAura.Quality(): string
	return quality
end

local function budget(): number
	if quality == "Off" then
		return 0
	end
	return if quality == "Reduced" then math.floor(CFG.MaxConcurrent * 0.5) else CFG.MaxConcurrent
end

local function reach(): number
	return if quality == "Reduced" then CFG.MidStuds else CFG.FarStuds
end

--==============================================================================
-- THE POOL
--
-- Segments are never destroyed while the session lives; they are parked
-- invisible and handed back out. A pulse allocates nothing after the pool has
-- warmed, which is what keeps a bed of Colossals off the garbage collector.
--
-- The ceiling is arithmetic, not a guess: MaxConcurrent pulses x the most arcs
-- a pulse can carry x segments per arc.
--==============================================================================
local function container(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "SeedPlantAura"
	-- Client-built, so it never replicates; Archivable = false keeps it out of
	-- any save the way every other scratch folder in this project does.
	f.Archivable = false
	f.Parent = workspace
	folder = f
	return f
end

local function take(): BasePart
	local n = #pool
	if n > 0 then
		local p = pool[n]
		pool[n] = nil
		return p
	end
	local p = Instance.new("Part")
	p.Name = "Arc"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Locked = true
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(0.1, 0.1, 1)
	p.Transparency = 1
	p.Parent = container()
	made += 1
	return p
end

local function give(p: BasePart)
	p.Transparency = 1
	-- Parked far from anything so a stray frame cannot show it where a plant
	-- used to be.
	p.CFrame = CFrame.new(0, -5000, 0)
	table.insert(pool, p)
end

--==============================================================================
-- ONE ARC, IN THE ANCHOR PART'S OWN SPACE
--
-- Built in LOCAL coordinates and stored that way. Every frame of the pulse the
-- segment is placed at `anchor.CFrame * localCF`, so the arc rides whatever
-- PlantSway is doing to that part -- lean, bob, walk cycle, leaf swing. It is
-- attached to the creature, not to a remembered world position, and a plant that
-- takes a step mid-pulse takes its lightning with it.
--==============================================================================
local function buildArc(state: State, anchor: BasePart, arcs: { Arc })
	local rng = state.rng
	local half = anchor.Size * 0.5

	--==========================================================================
	-- START ON A SIDE, NEVER THE TOP OR THE BOTTOM
	--
	-- A bolt off the top of a head reads as an antenna and a bolt off the
	-- underside is buried in the soil heap. The silhouette is the sides.
	--==========================================================================
	local face = rng:NextInteger(1, 4)
	local start: Vector3, outward: Vector3
	local ry = rng:NextNumber(-half.Y, half.Y) * 0.8
	if face == 1 then
		start = Vector3.new(half.X, ry, rng:NextNumber(-half.Z, half.Z) * 0.8)
		outward = Vector3.new(1, 0, 0)
	elseif face == 2 then
		start = Vector3.new(-half.X, ry, rng:NextNumber(-half.Z, half.Z) * 0.8)
		outward = Vector3.new(-1, 0, 0)
	elseif face == 3 then
		start = Vector3.new(rng:NextNumber(-half.X, half.X) * 0.8, ry, half.Z)
		outward = Vector3.new(0, 0, 1)
	else
		start = Vector3.new(rng:NextNumber(-half.X, half.X) * 0.8, ry, -half.Z)
		outward = Vector3.new(0, 0, -1)
	end
	start += outward * CFG.Standoff

	-- Mostly up or down the silhouette, with a lean. A bolt travelling straight
	-- out from the body reads as a spike; one running along it reads as a
	-- discharge crawling over the surface.
	local dir = Vector3.new(
		rng:NextNumber(-0.45, 0.45),
		if rng:NextNumber() < 0.5 then 1 else -1,
		rng:NextNumber(-0.45, 0.45)
	).Unit + outward * 0.25
	dir = dir.Unit

	-- Any vector not parallel to dir works as the jitter basis.
	local side = dir:Cross(Vector3.new(0, 1, 0))
	if side.Magnitude < 0.05 then
		side = dir:Cross(Vector3.new(1, 0, 0))
	end
	side = side.Unit
	local up = dir:Cross(side).Unit

	local n = CFG.Segments
	local step = state.length / n
	local jit = state.length * CFG.Jitter
	local points: { Vector3 } = { start }
	for i = 1, n do
		local kink = side * rng:NextNumber(-jit, jit) + up * rng:NextNumber(-jit, jit)
		-- The kink shrinks toward the tip, so an arc tapers to a point instead
		-- of flailing.
		local taper = 1 - (i - 1) / n * 0.55
		points[i + 1] = points[i] + dir * step + kink * taper
	end

	local segs: { Seg } = {}
	for i = 1, n do
		local a, b = points[i], points[i + 1]
		local d = b - a
		local len = d.Magnitude
		if len > 0.02 then
			local p = take()
			p.Size = Vector3.new(state.thick, state.thick, len)
			p.Color = if i == 2 then state.palette.core else state.palette.arc
			table.insert(segs, {
				part = p,
				localCF = CFrame.lookAt((a + b) * 0.5, b),
				core = i == 2,
			})
		end
	end
	if #segs > 0 then
		table.insert(arcs, { anchor = anchor, segs = segs })
	end
end

--==============================================================================
-- REGISTER / DROP
--==============================================================================

--==============================================================================
-- COLOSSAL AND NOTHING ELSE
--
-- The tier is read off the MODEL, which the server stamped in
-- CreatureModel.BuildCreature. Prepare answers nil for every other tier, so
-- Tiny through Titan carry no state, cost no scan and can never fire.
--==============================================================================
function PlantAura.Prepare(model: Model, headHeight: number, biomeId: string,
	colossalTier: number, now: number, rng: Random): State?
	if tonumber(model:GetAttribute("Tier")) ~= colossalTier then
		return nil
	end

	local parts: { BasePart } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and eligible(d) then
			table.insert(parts, d)
		end
	end
	if #parts == 0 then
		return nil
	end

	--==========================================================================
	-- THE BIOME COMES FROM THE SPECIES SHEET, NOT FROM AN ATTRIBUTE
	--
	-- A PLANTED creature carries SpeciesId, Rarity, Tier and Stage and NOTHING
	-- ELSE -- `BiomeId` is stamped by NestService on a pod in a ring, and never
	-- survives into a plot. Reading it here would have found nil on every plant
	-- in the game and quietly painted all five biomes the neutral fallback,
	-- which is a bug that looks exactly like "the palettes are too similar".
	--
	-- So the caller passes `species.Biome`, which it already has in hand. The
	-- fallback stays for a species pointing at a biome with no palette yet.
	--==========================================================================
	local palette = PALETTES[biomeId] or FALLBACK

	local length = math.clamp(headHeight * CFG.LengthFraction,
		CFG.LengthMin, CFG.LengthMax)

	local state: State = {
		model = model,
		parts = parts,
		palette = palette,
		length = length,
		thick = math.clamp(length * CFG.ThickFraction, CFG.ThickMin, CFG.ThickMax),
		rng = rng,
		-- Spread across the whole window at birth so a bed that streams in
		-- together does not flash together.
		nextAt = now + rng:NextNumber(0.2, CFG.FirstGapMax),
		pulsing = false,
	}
	table.insert(plants, state)
	slot[state] = #plants
	return state
end

local function endPulse(pulse: Pulse)
	for _, arc in ipairs(pulse.arcs) do
		for _, seg in ipairs(arc.segs) do
			give(seg.part)
		end
	end
	pulse.state.pulsing = false
end

function PlantAura.Forget(state: State?)
	if not state then
		return
	end
	local s = state :: State
	-- Any pulse it owns has to go back to the pool NOW. A plant picked up
	-- mid-pulse would otherwise leave four lit segments hanging in the bed.
	for i = #active, 1, -1 do
		if active[i].state == s then
			endPulse(active[i])
			table.remove(active, i)
		end
	end
	local at = slot[s]
	if at then
		-- Swap-remove, the same as PlantSway's own index.
		local last = #plants
		plants[at] = plants[last]
		slot[plants[at]] = at
		plants[last] = nil
		slot[s] = nil
	end
end

--==============================================================================
-- EVERYTHING, ONCE PER FRAME
--
-- Called from PlantSway's single Heartbeat. There is no connection in this file
-- and no per-plant thread -- 120 Colossals cost 120 number comparisons and
-- nothing else on a frame where none of them is due.
--==============================================================================
function PlantAura.Tick(now: number, dt: number, camPos: Vector3, camera: Camera?)
	--== advance what is already lit ==--
	for i = #active, 1, -1 do
		local pulse = active[i]
		pulse.t += dt
		local k = pulse.t / CFG.Life
		if k >= 1 or not pulse.state.model.Parent then
			endPulse(pulse)
			table.remove(active, i)
		else
			-- Quick out: brightest at the strike, gone by the end. The power
			-- puts most of the visible life in the first third.
			local fade = CFG.PeakTransparency
				+ (1 - CFG.PeakTransparency) * (k ^ 0.55)
			for _, arc in ipairs(pulse.arcs) do
				local anchor = arc.anchor
				if anchor.Parent then
					local base = anchor.CFrame
					for _, seg in ipairs(arc.segs) do
						seg.part.CFrame = base * seg.localCF
						-- Flicker is per SEGMENT, so a bolt shimmers along its
						-- length instead of pulsing as one bar.
						seg.part.Transparency = math.clamp(
							fade + (math.random() - 0.5) * CFG.Flicker, 0, 1)
					end
				else
					-- The part it was hanging off is gone -- a hatch, a pickup,
					-- a rebuild. Hide rather than follow a destroyed CFrame.
					for _, seg in ipairs(arc.segs) do
						seg.part.Transparency = 1
					end
				end
			end
		end
	end

	--== decide what lights next ==--
	local free = budget() - #active
	if free <= 0 then
		--======================================================================
		-- Budget full. Everything due is pushed back by a short random slice
		-- rather than left due, which is what stops a queue forming and then
		-- firing as one wave the moment the budget clears.
		--======================================================================
		for _, state in ipairs(plants) do
			if now >= state.nextAt then
				state.nextAt = now + math.random() * 0.6 + 0.2
			end
		end
		return
	end

	local far = reach()
	for _, state in ipairs(plants) do
		if free <= 0 then
			break
		end
		if now >= state.nextAt and not state.pulsing then
			local model = state.model
			if not model.Parent then
				continue
			end
			-- The pivot is the ground plate, which is good enough for a range
			-- test and costs nothing next to a bounding-box recompute.
			local at = model:GetPivot().Position
			local d = (at - camPos).Magnitude

			if d > far then
				-- Streamed out, or simply not worth drawing. Re-armed on the
				-- normal gap so it starts again as soon as the player is back.
				state.nextAt = now + state.rng:NextNumber(CFG.GapMin, CFG.GapMax)
				continue
			end

			--==================================================================
			-- OFF SCREEN IS WORK NOBODY SEES
			--
			-- Only asked of plants that are actually due this frame, which is a
			-- handful, so the viewport test never runs 120 times. Close plants
			-- skip the test: a small turn of the camera brings them in mid-pulse
			-- and a popped-in arc reads worse than one that was already there.
			--==================================================================
			if camera and d > CFG.AlwaysStuds then
				local _, onScreen = camera:WorldToViewportPoint(at)
				if not onScreen then
					state.nextAt = now + state.rng:NextNumber(CFG.GapMin, CFG.GapMax)
					continue
				end
			end

			local want = if d <= CFG.NearStuds then CFG.ArcsNear
				elseif d <= CFG.MidStuds then CFG.ArcsMid
				else CFG.ArcsFar
			if quality == "Reduced" then
				want = math.max(1, want - 1)
			end

			local arcs: { Arc } = {}
			for _ = 1, want do
				local anchor = state.parts[state.rng:NextInteger(1, #state.parts)]
				if anchor.Parent then
					buildArc(state, anchor, arcs)
				end
			end

			if #arcs > 0 then
				table.insert(active, { state = state, arcs = arcs, t = 0 })
				state.pulsing = true
				free -= 1
			end
			state.nextAt = now + state.rng:NextNumber(CFG.GapMin, CFG.GapMax)
		end
	end
end

--==============================================================================
-- FOR VERIFICATION, AND FOR A PREVIEW THAT IS REBUILT UNDER ITSELF
--==============================================================================
function PlantAura.Stats(): (number, number, number, number)
	return #plants, #active, #pool, made
end

function PlantAura.Reset()
	for i = #active, 1, -1 do
		endPulse(active[i])
		active[i] = nil
	end
	table.clear(plants)
	table.clear(slot)
end

--==============================================================================
-- The client's own starting quality, read the same way SpeedFX reads it -- same
-- attribute, same three words, same touch-device default.
--==============================================================================
function PlantAura.BindQuality(): RBXScriptConnection?
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	local function pull()
		local want = player:GetAttribute(QUALITY_ATTRIBUTE)
		if type(want) == "string" then
			PlantAura.SetQuality(want)
		end
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		quality = "Reduced"
	end
	pull()
	return player:GetAttributeChangedSignal(QUALITY_ATTRIBUTE):Connect(pull)
end

return PlantAura
