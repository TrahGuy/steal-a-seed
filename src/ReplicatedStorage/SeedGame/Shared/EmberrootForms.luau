--!strict
--==============================================================================
-- EMBERROOT, AS APPROVED
--
-- The five plants were designed as a temporary Edit-mode mockup under
-- `Workspace.EmberrootSpeciesMockup`, reviewed there, and approved there. This
-- file is those plants, lifted verbatim and frozen.
--
-- IT IS ART, NOT ART DIRECTION. Nothing here was redrawn, recoloured or tidied
-- on the way across; every size, CFrame and colour is the number that was
-- approved, and the banners explaining WHY each shape is what it is came with
-- them. A preview folder is a scratchpad that gets deleted, so the approved
-- geometry had to stop living in one -- but "translate it into code" only counts
-- if the translation is lossless.
--
--==============================================================================
-- WHAT IS SHARED, AND WHY
--
-- Cinderpaw's approval fixed the biome's body: a cracked cinder pad, two braced
-- root-legs, a bent three-segment stem with one heat crack, two small fore-limbs
-- and a face bulb with a brow, a hanging jaw and a glowing throat. All five
-- carry it, exactly as Greenhollow's five share a soil heap and Tanglemire's
-- five share a peat hummock. That is the family resemblance.
--
-- What varies is the CROWN and the FACE, because the crown is the dominant mass
-- in every case -- a plant that has limbs, not a creature that has leaves.
--
--==============================================================================
-- HOW IT SCALES, AND WHY AUTHORED IS MEASURED RATHER THAN CHOSEN
--
-- Each plant was drawn at its own size and the FIVE SIZES RELATIVE TO EACH OTHER
-- ARE PART OF THE APPROVAL. Tanglemire settled this precedent: its five were
-- conformed by one shared factor because re-laddering them independently would
-- have reversed Lanterncap and Snapmoss. The same applies here, so AUTHORED
-- records what each plant actually measures and SeedData.Height is that number
-- times one factor shared by all five.
--
-- The spread is wide -- Emberquill is 1.73x Cinderpaw -- and that is the
-- approved shape of the biome, not a mistake. Greenhollow spans 1.67x for the
-- same reason; Tanglemire's narrow 1.12x is the outlier.
--==============================================================================

local EmberrootForms = {}

-- Position scales; rotation does not. Subtracting a CFrame's own position
-- leaves the rotation-only CFrame. The same arithmetic every other builder in
-- the project uses, so nothing grows differently here.
local function scaled(c: CFrame, s: number): CFrame
	local p = c.Position
	return CFrame.new(p.X * s, p.Y * s, p.Z * s) * (c - p)
end

local C = {
	Basalt     = Color3.fromRGB(52, 40, 38),
	Bark       = Color3.fromRGB(88, 60, 48),
	BarkPale   = Color3.fromRGB(120, 86, 66),
	Ember      = Color3.fromRGB(255, 118, 44),
	EmberDeep  = Color3.fromRGB(198, 68, 24),
	EmberPale  = Color3.fromRGB(255, 166, 78),
	Throat     = Color3.fromRGB(255, 186, 96),
	EyeGlow    = Color3.fromRGB(255, 222, 150),
	Glint      = Color3.fromRGB(255, 255, 255),
	Char       = Color3.fromRGB(30, 24, 23),
	Cinder     = Color3.fromRGB(92, 46, 32),
	-- Per-species accents, still inside the ember family so the biome holds.
	Quill      = Color3.fromRGB(255, 200, 92),
	Slag       = Color3.fromRGB(168, 38, 30),
	SlagDrip   = Color3.fromRGB(255, 96, 30),
	Kiln       = Color3.fromRGB(74, 58, 54),
	KilnGlow   = Color3.fromRGB(255, 148, 40),
	Lotus      = Color3.fromRGB(255, 140, 96),
	LotusDeep  = Color3.fromRGB(214, 62, 74),
	LotusCore  = Color3.fromRGB(255, 236, 176),
	-- Neon renders roughly the part colour at full brightness, so a near-white
	-- core came out as a plain white ball. This is saturated enough to stay
	-- orange under its own light.
	CoreEmber  = Color3.fromRGB(255, 162, 62),
}

local SURFACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

type Opts = {
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	parent: Instance,
	shape: Enum.PartType?,
	wedge: boolean?,
	material: Enum.Material?,
	smooth: boolean?,
}

local function mk(o: Opts): BasePart
	local p: BasePart
	if o.wedge then
		p = Instance.new("WedgePart")
	else
		local b = Instance.new("Part")
		b.Shape = o.shape or Enum.PartType.Block
		p = b
	end
	p.Name = o.name
	p.Size = o.size
	p.CFrame = o.cf
	p.Color = o.color
	p.Material = o.material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	local face = if o.smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
	for _, f in ipairs(SURFACES) do
		pcall(function()
			(p :: any)[f] = face
		end)
	end
	p.Parent = o.parent
	return p
end

local function rad(d: number): number
	return math.rad(d)
end

--==============================================================================
-- FIVE BODIES, NOT ONE
--
-- The art bible shares LEAF, STEM and SOIL across a biome and gives each species
-- its own Body, Crown and Accent. The first Emberroot build shared the entire
-- body, so five species read as one plant in five hats.
--
-- Shared now: the cinder pad and the root-legs. That is the ground contact, and
-- it is what still makes these one biome.
--
-- Varying: stem, limbs, bulb, brow, jaw and crown. Each body sits at a
-- different VALUE as well as a different hue, so the five separate in greyscale
-- and not only in colour -- which is the check the skill actually asks for.
--==============================================================================
type Palette = {
	stem: Color3,
	stemPale: Color3,
	bulb: Color3,
	brow: Color3,
	crack: Color3,
}

local PALETTES: { [string]: Palette } = {
	-- Cinderpaw: the approved one. Warm charcoal, mid value.
	cinderpaw = {
		stem = Color3.fromRGB(88, 60, 48), stemPale = Color3.fromRGB(120, 86, 66),
		bulb = Color3.fromRGB(52, 40, 38), brow = Color3.fromRGB(88, 60, 48),
		crack = Color3.fromRGB(198, 68, 24),
	},
	-- Emberquill: dry and pale, the lightest of the five. Bleached ash wood.
	emberquill = {
		stem = Color3.fromRGB(150, 122, 92), stemPale = Color3.fromRGB(188, 162, 128),
		bulb = Color3.fromRGB(96, 78, 62), brow = Color3.fromRGB(150, 122, 92),
		crack = Color3.fromRGB(255, 196, 78),
	},
	-- Slagbloom: crimson-black, the darkest and hottest. Cooling slag.
	slagbloom = {
		stem = Color3.fromRGB(74, 30, 28), stemPale = Color3.fromRGB(104, 44, 38),
		bulb = Color3.fromRGB(38, 18, 18), brow = Color3.fromRGB(74, 30, 28),
		crack = Color3.fromRGB(255, 84, 26),
	},
	-- Kilnhusk: cool grey stone, the only one that is not warm. Fired clay.
	kilnhusk = {
		stem = Color3.fromRGB(96, 92, 88), stemPale = Color3.fromRGB(132, 126, 120),
		bulb = Color3.fromRGB(60, 58, 56), brow = Color3.fromRGB(96, 92, 88),
		crack = Color3.fromRGB(255, 148, 40),
	},
	-- Pyrelotus: violet-charcoal, the only cool-dark. Reads exotic beside the
	-- other four, which is the Mythic doing its job before you read the word.
	--
	-- The first values were too dark to work. The bulb was the darkest of the
	-- five at a relative luminance of 21, and unlike Slagbloom -- which is nearly
	-- as dark but wears a bright crown right above its face -- this species is
	-- violet everywhere, so the face had nothing to sit against and the eyes and
	-- jaw disappeared into the head. The HUE is unchanged, which is what carries
	-- the "only cool-dark" reading; only the value is lifted, to about 44, so the
	-- face is legible at the range a player actually walks past it.
	pyrelotus = {
		stem = Color3.fromRGB(66, 38, 66), stemPale = Color3.fromRGB(96, 62, 94),
		bulb = Color3.fromRGB(52, 32, 56), brow = Color3.fromRGB(66, 38, 66),
		crack = Color3.fromRGB(255, 128, 148),
	},
}

--==============================================================================
-- THE SHARED BODY -- ground contact shared, everything above it per-species
--
-- Returns the crown hub and the head frame, because those are the two places a
-- species is allowed to differ.
--==============================================================================
type Body = { hub: CFrame, head: CFrame }

local function body(m: Model, at: CFrame, stemScale: number, brace: number,
	pal: Palette): Body
	local function P(o: Opts): BasePart
		o.cf = at * o.cf
		o.parent = m
		return mk(o)
	end

	P({ name = "CinderPad", size = Vector3.new(2.30, 0.26, 2.10),
		cf = CFrame.new(0, 0.13, 0) * CFrame.Angles(0, rad(9), 0),
		color = C.Char, parent = m })

	--== ROOT-LEGS ==--
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		local tag = (i == 0) and "LeftRoot" or "RightRoot"
		local hip = at * CFrame.new(side * 0.34, 0.92, 0.02)
			* CFrame.Angles(rad(-8), side * rad(14), side * rad(-30 - brace))

		mk({ name = tag .. "Thigh", size = Vector3.new(0.46, 0.78, 0.52),
			cf = hip * CFrame.new(0, -0.30, 0.02) * CFrame.Angles(rad(14), 0, 0),
			color = C.Bark, parent = m })
		mk({ name = tag .. "Shin", size = Vector3.new(0.38, 0.64, 0.44),
			cf = hip * CFrame.new(side * 0.16, -0.42, -0.10)
				* CFrame.Angles(rad(-26), 0, side * rad(-14)),
			color = C.Basalt, parent = m })
		mk({ name = tag .. "Sole", size = Vector3.new(0.52, 0.24, 0.72),
			cf = hip * CFrame.new(side * 0.24, -0.63, -0.26)
				* CFrame.Angles(rad(4), side * rad(16), 0),
			color = C.Basalt, parent = m })
		mk({ name = tag .. "Claw", size = Vector3.new(0.24, 0.20, 0.38),
			cf = hip * CFrame.new(side * 0.22, -0.67, -0.62)
				* CFrame.Angles(rad(-10), side * rad(16), 0),
			color = C.Char, wedge = true, parent = m })
	end

	--== STEM: three segments that disagree ==--
	local h = stemScale
	P({ name = "StemBase", size = Vector3.new(0.86, 0.80 * h, 0.82),
		cf = CFrame.new(0, 0.62 * h, 0.02) * CFrame.Angles(rad(4), 0, rad(-3)),
		color = pal.stem, parent = m })
	P({ name = "StemMid", size = Vector3.new(0.68, 0.86 * h, 0.66),
		cf = CFrame.new(0.06, 1.34 * h, -0.04) * CFrame.Angles(rad(-6), rad(8), rad(5)),
		color = pal.stem, parent = m })
	P({ name = "StemTop", size = Vector3.new(0.54, 0.74 * h, 0.54),
		cf = CFrame.new(0.02, 2.02 * h, -0.10) * CFrame.Angles(rad(8), rad(-6), rad(-4)),
		color = pal.stemPale, parent = m })
	P({ name = "StemCrack", size = Vector3.new(0.10, 0.92 * h, 0.09),
		cf = CFrame.new(-0.22, 1.32 * h, -0.34) * CFrame.Angles(rad(-4), 0, rad(8)),
		color = pal.crack, material = Enum.Material.Neon, smooth = true, parent = m })

	--== FORE-LIMBS ==--
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		local tag = (i == 0) and "LeftLimb" or "RightLimb"
		local reach = (i == 0) and 0 or 14
		local sh = at * CFrame.new(side * 0.36, 1.62 * h, -0.16)
			* CFrame.Angles(rad(34 + reach), side * rad(-22), side * rad(38))

		mk({ name = tag .. "Upper", size = Vector3.new(0.28, 0.56, 0.30),
			cf = sh * CFrame.new(0, -0.22, 0), color = pal.stem, parent = m })
		mk({ name = tag .. "Fore", size = Vector3.new(0.23, 0.50, 0.25),
			cf = sh * CFrame.new(side * 0.05, -0.64, 0.12) * CFrame.Angles(rad(36), 0, 0),
			color = pal.stemPale, parent = m })
		mk({ name = tag .. "Claw", size = Vector3.new(0.17, 0.16, 0.34),
			cf = sh * CFrame.new(side * 0.05, -0.88, 0.30)
				* CFrame.Angles(rad(64), 0, side * rad(12)),
			color = C.Char, wedge = true, parent = m })
	end

	return {
		hub = at * CFrame.new(0.02, 3.24 * h, 0.10),
		head = at * CFrame.new(0.02, 2.44 * h, -0.46) * CFrame.Angles(rad(19), rad(-4), 0),
	}
end

--==============================================================================
-- THE FACE -- shared shape, per-species proportions
--
-- No smile bars and no blush cheeks: the mouth is the GAP between bulb and jaw,
-- with the throat lit inside it. `wide` fattens the whole head for the species
-- that need a heavier read.
--==============================================================================
--==============================================================================
-- THE FACE
--
-- Held to the same rules CreatureModel's addFace states, because a player reads
-- Emberroot's plants next to Greenhollow's and a face that follows different
-- rules looks wrong without them being able to say why. Two of those rules had
-- been broken here, and they were the two the production file calls out by name.
--
-- THE EYE IS DARK AND THE GLINT IS THE HOT PART.
--
-- The eyeball used to be Neon EyeGlow -- 255, 222, 150, near enough to white
-- that it rendered as a flat blown-out disc. The glint then sat on top of an
-- already-white ball and did nothing, so the ONE SHARED LIGHT rule, which
-- CreatureModel describes as "what makes two spheres read as one face lit from
-- one side instead of two googly eyes", had no way to show. Two blank circles
-- is exactly what came out.
--
-- The glow simply moves: the eye takes a dark body and the glint becomes the
-- emissive part. Costs nothing, reads as an eye rather than a disc, and it
-- suits the biome better -- these should look lit from inside. The offset stays
-- the same on BOTH eyes, never mirrored, which is the whole point of the rule.
--
-- THE MOUTH IS THREE BLOCKS, NOT ONE BAR.
--
-- CreatureModel: "still three blocks -- one bar reads as a grimace". This had
-- one, and it read as a letterbox. Three, with the ends lifted a hair, is what
-- the rest of the game's creatures do. It stays Neon in the species' own throat
-- colour, because Cinderpaw's signature IS the ember maw and a dark line would
-- throw that away.
--==============================================================================
local function face(m: Model, head: CFrame, wide: number, throat: Color3,
	pal: Palette)
	mk({ name = "Bulb", size = Vector3.new(0.96 * wide, 0.96, 0.96 * wide),
		cf = head, color = pal.bulb, shape = Enum.PartType.Ball, parent = m })
	-- Narrowed from 1.00: it was wider than the 0.96 head it sits on, so it
	-- read as a shelf laid across the top rather than as part of the skull.
	--==========================================================================
	-- EVERY DEPTH ON THIS FACE SCALES WITH `wide`
	--
	-- The bulb is Vector3.new(0.96 * wide, 0.96, 0.96 * wide) -- so its Z radius
	-- is 0.48 * wide, not 0.48. Every z offset here used to be a fixed number
	-- tuned against wide = 1, which meant the face sat at the wrong DEPTH on any
	-- species whose head is not that width: Slagbloom (1.18) had its mouth and
	-- eyes buried inside the skull, and Emberquill (0.88) had them floating
	-- three-quarters clear of it. Scaling the depths fixes all five at once
	-- rather than tuning each species by hand.
	--==========================================================================
	local D = wide

	mk({ name = "Brow", size = Vector3.new(0.86 * wide, 0.22, 0.50),
		cf = head * CFrame.new(0, 0.26, -0.34 * D) * CFrame.Angles(rad(-28), 0, 0),
		color = pal.brow, parent = m })
	mk({ name = "Jaw", size = Vector3.new(0.78 * wide, 0.28, 0.60),
		cf = head * CFrame.new(0, -0.58, -0.30 * D) * CFrame.Angles(rad(-18), 0, rad(-3)),
		color = pal.bulb, parent = m })

	--== THE MAW: three segments, ends lifted ==--
	-- Lifting the ends is the difference between pleased and unwell, and it is
	-- the only thing keeping these on the friendly side of the game's tone --
	-- they are collectible plants, not the guardian.
	-- NO ROLL ON THE END SEGMENTS. Tilting them outward dips their inner
	-- corners and the three pieces stop being a mouth and become a BOWTIE --
	-- which is exactly what the first attempt produced. Production rolls none
	-- of them; the ends only STEP UP. Flat bars too: at 0.145 tall against
	-- 0.165 wide these were near-square chunks rather than a line.
	-- SIZED OFF THE PRODUCTION FACE, NOT BY EYE.
	--
	-- A Greenhollow plant built next to this one settled it. CreatureModel's
	-- smile is 28% of the head's width and 5% of it tall, in DARK. This was 45%
	-- wide and 8.9% tall in full-brightness Neon -- roughly 1.6x too wide, 1.8x
	-- too tall, and glowing. At that size a mouth stops being a feature on a
	-- face and becomes the face, and three stepped blocks that big read as a
	-- BOWTIE rather than a smile. The eyes needed none of this: at 22% of head
	-- width against production's 23% they were already right, and only their
	-- colour was wrong.
	--
	-- The proportions below are production's, against this head's own width
	-- (0.96 * wide). It stays Neon in the species' throat colour, because small
	-- and glowing still reads as Cinderpaw's ember maw -- it is the SIZE that
	-- was doing the damage, not the light.
	local HW = 0.96 * wide
	local mw = 0.10 * HW
	for i, spec in ipairs({ { -1, 0.030 }, { 0, 0 }, { 1, 0.030 } }) do
		local sx = spec[1] :: number
		local lift = (spec[2] :: number) * 0.96
		mk({ name = "Maw" .. i,
			size = Vector3.new(mw, 0.05 * 0.96, 0.07 * 0.96),
			-- z pushed out to 0.315. At 0.275 the front face landed on 0.345
			-- against a surface of 0.344 at the centre and 0.353 at the ends --
			-- flush in the middle and SUNK at both ends, so the head's own skin
			-- cut across the mouth and every junction showed as a dark notch.
			-- The segments were overlapping the whole time; they were underwater.
			-- This stands all three clearly proud, like a moulded lip.
			cf = head * CFrame.new(sx * mw * 0.92, -0.30 + lift, -0.375 * D),
			color = throat, material = Enum.Material.Neon,
			smooth = true, parent = m })
	end

	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		local tag = (i == 0) and "Left" or "Right"
		-- Centred on the surface at this offset, so half stands proud.
		local eye = head * CFrame.new(side * 0.24 * wide, 0.02, -0.42 * D)
		mk({ name = tag .. "Eye", size = Vector3.new(0.21, 0.21, 0.21),
			cf = eye, color = C.Char, shape = Enum.PartType.Ball,
			smooth = true, parent = m })
		--==================================================================
		-- THE EMBER DOT IS A PUPIL NOW, NOT A GLINT
		--
		-- It used to be a fixed highlight sitting upper-left on both eyes --
		-- the "one shared light" trick, which exists so two spheres read as
		-- one face lit from one side. That rule is for a HIGHLIGHT, and a
		-- highlight is the one thing on a face that can never look alive: it
		-- is pinned to the light, so no matter how the geometry is tuned the
		-- eye keeps staring through you.
		--
		-- So it becomes the pupil instead. Built dead centre, looking straight
		-- ahead, and moved at runtime -- which is what makes an eye read as an
		-- eye without anyone having to keep adjusting its shape.
		--
		-- Hung off the EYE rather than the head, so it travels with the eye's
		-- depth and the runtime only ever has to think in angles.
		--
		-- PLACED ON THE EYEBALL'S SURFACE, not on a flat plane in front of it:
		-- a pupil that slides across a plane detaches from the ball at the
		-- edges. 0.0928 is the eye's radius less a quarter of the pupil's, so
		-- it sits just into the skin and stays there through the full sweep.
		--==================================================================
		mk({ name = tag .. "Pupil", size = Vector3.new(0.098, 0.098, 0.098),
			cf = eye * CFrame.new(0, 0, -0.0928),
			color = C.EyeGlow, material = Enum.Material.Neon,
			shape = Enum.PartType.Ball, smooth = true, parent = m })
	end
end

--==============================================================================
-- SPECIES
--==============================================================================
local function cinderpaw(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Cinderpaw"; m.Parent = parent
	local pal = PALETTES.cinderpaw
	local b = body(m, at, 1.0, 0, pal)
	face(m, b.head, 1.0, C.Throat, pal)
	mk({ name = "CrownHub", size = Vector3.new(0.60, 0.34, 0.58),
		cf = b.hub * CFrame.Angles(rad(-6), 0, 0), color = C.Cinder, parent = m })
	local fronds = {
		{ -28, 1.94, 9, 1.18, C.Ember }, { 34, 1.76, 13, 1.06, C.EmberPale },
		{ -96, 1.52, 6, 0.94, C.EmberDeep }, { 104, 1.64, 4, 1.00, C.Ember },
		{ 178, 1.28, 17, 0.84, C.EmberDeep },
	}
	for i, f in ipairs(fronds) do
		local base = b.hub * CFrame.Angles(0, rad(f[1] :: number), 0)
			* CFrame.Angles(rad(-(f[3] :: number)), 0, 0)
		local L = f[2] :: number
		mk({ name = "FrondRib" .. i, size = Vector3.new(0.11, 0.10, L),
			cf = base * CFrame.new(0, 0, -L * 0.5), color = C.Cinder, parent = m })
		mk({ name = "FrondBlade" .. i, size = Vector3.new(f[4] :: number, 0.13, L * 0.86),
			cf = base * CFrame.new(0, 0.045, -L * 0.52)
				* CFrame.Angles(0, 0, rad((i % 2 == 0) and 7 or -6)),
			color = f[5] :: Color3, parent = m })
	end
	return m
end

--==============================================================================
-- EMBERQUILL -- the other Rare, and it must not be mistaken for Cinderpaw.
-- Cinderpaw fans OUT and sits low; this points UP and stands tall, on a longer
-- stem, with narrow quills instead of broad blades. Signature: one central
-- quill taller than the rest, lit at the tip like a wick.
--==============================================================================
local function emberquill(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Emberquill"; m.Parent = parent
	local pal = PALETTES.emberquill
	local b = body(m, at, 1.22, -6, pal)
	face(m, b.head, 0.88, C.Throat, pal)
	mk({ name = "CrownHub", size = Vector3.new(0.46, 0.30, 0.46),
		cf = b.hub, color = C.Cinder, parent = m })
	-- Six quills, uneven lean, none vertical: a fence of equal spikes is the
	-- failure the skill names, so lean and length vary across the set.
	local quills = {
		{ -22, 1.62, 52, C.Quill }, { 46, 1.38, 43, C.Ember },
		{ -88, 1.20, 34, C.EmberDeep }, { 118, 1.46, 47, C.EmberPale },
		{ 168, 1.08, 38, C.EmberDeep },
	}
	for i, q in ipairs(quills) do
		local L = q[2] :: number
		local base = b.hub * CFrame.Angles(0, rad(q[1] :: number), 0)
			* CFrame.Angles(rad(-(q[3] :: number)), 0, 0)
		mk({ name = "Quill" .. i, size = Vector3.new(0.19, 0.15, L),
			cf = base * CFrame.new(0, 0, -L * 0.5), color = q[4] :: Color3, parent = m })
	end
	-- THE SIGNATURE: the wick.
	mk({ name = "WickQuill", size = Vector3.new(0.22, 0.20, 1.84),
		cf = b.hub * CFrame.Angles(rad(-84), rad(8), 0) * CFrame.new(0, 0, -0.92),
		color = C.Quill, parent = m })
	mk({ name = "WickTip", size = Vector3.new(0.30, 0.30, 0.30),
		cf = b.hub * CFrame.new(0.12, 1.86, 0.02), color = C.LotusCore,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	-- A dry husk collar under the crown and two seed beads down the stem: this
	-- is the species that reads as SPENT, so it carries what it has shed.
	for i = 0, 2 do
		local a = -50 + i * 62
		mk({ name = "HuskFlake" .. (i + 1), size = Vector3.new(0.44, 0.11, 0.34),
			cf = b.hub * CFrame.Angles(0, rad(a), 0) * CFrame.new(0, -0.30, -0.34)
				* CFrame.Angles(rad(28), 0, rad((i % 2 == 0) and 8 or -9)),
			color = pal.stemPale, wedge = true, parent = m })
	end
	mk({ name = "SeedBead", size = Vector3.new(0.22, 0.26, 0.22),
		cf = at * CFrame.new(0.30, 1.52, -0.40) * CFrame.Angles(rad(12), 0, rad(-14)),
		color = C.Quill, parent = m })
	return m
end

--==============================================================================
-- SLAGBLOOM -- Epic. Squat and heavy where the Rares are light. The crown
-- DROOPS instead of lifting, four thick petals folding down over the head, and
-- the signature is a molten drip hanging off the lowest one.
--==============================================================================
local function slagbloom(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Slagbloom"; m.Parent = parent
	local pal = PALETTES.slagbloom
	local b = body(m, at, 0.90, 10, pal)
	face(m, b.head, 1.18, C.SlagDrip, pal)
	mk({ name = "CrownHub", size = Vector3.new(0.78, 0.40, 0.74),
		cf = b.hub * CFrame.Angles(rad(4), 0, 0), color = C.Cinder, parent = m })
	local petals = {
		{ -40, 1.30, -34, 1.26, C.Slag }, { 38, 1.16, -28, 1.14, C.SlagDrip },
		{ -124, 1.04, -22, 1.02, C.Slag }, { 132, 1.10, -30, 1.08, C.EmberDeep },
	}
	for i, p in ipairs(petals) do
		local L = p[2] :: number
		local base = b.hub * CFrame.Angles(0, rad(p[1] :: number), 0)
			* CFrame.Angles(rad(-(p[3] :: number)), 0, 0)
		mk({ name = "PetalRib" .. i, size = Vector3.new(0.14, 0.12, L),
			cf = base * CFrame.new(0, 0, -L * 0.5), color = C.Cinder, parent = m })
		mk({ name = "Petal" .. i, size = Vector3.new(p[4] :: number, 0.20, L * 0.88),
			cf = base * CFrame.new(0, 0.06, -L * 0.5)
				* CFrame.Angles(rad(-14), 0, rad((i % 2 == 0) and 9 or -8)),
			color = p[5] :: Color3, parent = m })
	end
	-- THE SIGNATURE: molten running off one petal and hanging.
	mk({ name = "DripRun", size = Vector3.new(0.13, 0.52, 0.13),
		cf = b.hub * CFrame.new(-0.92, -0.42, -0.66) * CFrame.Angles(rad(6), 0, rad(10)),
		color = C.SlagDrip, material = Enum.Material.Neon, smooth = true, parent = m })
	mk({ name = "DripBead", size = Vector3.new(0.26, 0.26, 0.26),
		cf = b.hub * CFrame.new(-0.96, -0.76, -0.68), color = C.LotusCore,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	-- Slag crust over the shoulders: this one is the heavy species, and weight
	-- reads as crust rather than as height.
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		mk({ name = "SlagCrust" .. (i + 1), size = Vector3.new(0.62, 0.26, 0.54),
			cf = at * CFrame.new(side * 0.44, 2.06, -0.10)
				* CFrame.Angles(rad(-12), side * rad(18), side * rad(-22)),
			color = C.Slag, parent = m })
	end
	return m
end

--==============================================================================
-- KILNHUSK -- Legendary, and the only one built like a BUILDING.
--
-- Every other species in the biome is foliage on a stem. This is a squat stone
-- barrel with an arched mouth and a chimney: no crown, no petals, no fronds. It
-- is the widest and heaviest silhouette on the road, and it is recognisable at
-- distance because nothing else in Emberroot has a straight vertical edge.
--
-- The face sits INSIDE the arch, lit by the furnace behind it, so the head is
-- framed rather than crowned.
--==============================================================================
local function kilnhusk(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Kilnhusk"; m.Parent = parent
	local pal = PALETTES.kilnhusk
	local b = body(m, at, 0.86, -18, pal)
	face(m, b.head, 1.0, C.KilnGlow, pal)

	--== THE BARREL: three stacked courses, standing BEHIND the head ==--
	-- The first build put these boxes straight through the face. Each course was
	-- centred near z = 0 and cut nearly three studs deep, so it reached further
	-- forward than the brow, the jaw and the arch posts alike, across exactly the
	-- height band the face occupies. The species advertises "the face sits inside
	-- the arch" and what stood on the road was a stack of blocks with the face
	-- walled in behind it.
	--
	-- The mass now starts at z = +0.18 and grows backwards, which leaves the head
	-- standing clear in the arch opening with the furnace glowing between them.
	-- The Y turns are also cut from 13/-9 to 8/-6: a wide box swings its corners
	-- forward as it rotates, and at the old angles that alone reached past the
	-- face even after the box was moved back.
	--
	-- Turning each course still stops the stack reading as one extruded box, and
	-- the narrowing is what makes it a kiln rather than a crate.
	local BARREL_Z = 1.10
	local rings = {
		{ 2.16, 3.34, 0.78, 0 }, { 2.86, 3.02, 0.70, 8 }, { 3.44, 2.54, 0.58, -6 },
	}
	for i, r in ipairs(rings) do
		mk({ name = "KilnCourse" .. i,
			size = Vector3.new(r[2] :: number, r[3] :: number, (r[2] :: number) * 0.55),
			cf = at * CFrame.new(0, r[1] :: number, BARREL_Z)
				* CFrame.Angles(0, rad(r[4] :: number), rad((i == 2) and 3 or -2)),
			color = if i == 2 then C.Basalt else C.Kiln, parent = m })
	end

	--== THE ARCH: two jambs and a lintel, framing the face ==--
	-- These were 0.40 deep and sat a stud proud of everything, so they read as
	-- two loose slats rather than as the mouth of a kiln. They are now driven
	-- back far enough to meet the barrel's front face, which turns the arch into
	-- a real opening with depth to it -- the face sits IN the recess rather than
	-- in front of a wall.
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		mk({ name = (i == 0 and "ArchLeft" or "ArchRight"),
			size = Vector3.new(0.34, 1.24, 1.60),
			cf = at * CFrame.new(side * 0.86, 2.46, -0.55)
				* CFrame.Angles(rad(4), side * rad(-6), 0),
			color = C.Kiln, parent = m })
	end
	mk({ name = "ArchLintel", size = Vector3.new(2.10, 0.40, 1.50),
		cf = at * CFrame.new(0, 3.18, -0.55) * CFrame.Angles(rad(-8), 0, rad(2)),
		color = C.Basalt, parent = m })

	--== THE CHIMNEY, OFF CENTRE ==--
	-- Off centre and leaning, because a chimney on the axis would make the whole
	-- thing symmetrical and dead.
	mk({ name = "Chimney", size = Vector3.new(0.56, 1.44, 0.54),
		cf = at * CFrame.new(0.46, 4.24, 1.02) * CFrame.Angles(rad(6), rad(14), rad(-9)),
		color = C.Kiln, parent = m })
	mk({ name = "ChimneyCap", size = Vector3.new(0.76, 0.24, 0.72),
		cf = at * CFrame.new(0.50, 4.98, 1.06) * CFrame.Angles(rad(4), rad(14), rad(-7)),
		color = C.Basalt, parent = m })
	mk({ name = "ChimneyMouth", size = Vector3.new(0.30, 0.16, 0.28),
		cf = at * CFrame.new(0.50, 5.08, 1.06), color = C.KilnGlow,
		material = Enum.Material.Neon, smooth = true, parent = m })

	--== THE SIGNATURE: the furnace, seen through the arch ==--
	local furnace = mk({ name = "Furnace", size = Vector3.new(0.42, 0.42, 0.42),
		cf = at * CFrame.new(0, 2.62, -0.10), color = C.KilnGlow,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	mk({ name = "KilnSplit", size = Vector3.new(0.15, 1.30, 0.13),
		cf = at * CFrame.new(-0.74, 2.90, -0.62) * CFrame.Angles(rad(-6), 0, rad(11)),
		color = C.KilnGlow, material = Enum.Material.Neon, smooth = true, parent = m })
	local light = Instance.new("PointLight")
	light.Name = "FurnaceGlow"
	light.Color = C.Ember
	light.Brightness = 1.8
	light.Range = 11
	light.Shadows = false
	light.Parent = furnace
	return m
end

--==============================================================================
-- PYRELOTUS -- Mythic, and the only one with a HOLE in its silhouette.
--
-- Three ribs rise off the crown and arc inward until they almost touch, leaving
-- a hollow with the burning core suspended in it. Nothing else in Emberroot is
-- hollow: Cinderpaw fans, Slagbloom droops, Emberquill spikes, Kilnhusk stacks.
-- A cage cannot be mistaken for any of them, at any distance or angle.
--
-- The brightest thing on the model is seen THROUGH the form rather than on it,
-- which is what makes it worth walking up to -- and the face sits low at the
-- cage mouth, so the plant reads as carrying the ember rather than wearing it.
--
-- The rarity is the budget: nothing below Mythic gets a light, a halo and an
-- emitter, and nothing else gets an enclosing form at all.
--==============================================================================
local function pyrelotus(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Pyrelotus"; m.Parent = parent
	local pal = PALETTES.pyrelotus
	local b = body(m, at, 0.94, 8, pal)
	face(m, b.head, 0.92, C.LotusCore, pal)

	--== THE CAGE MOUTH ==--
	-- A flared collar the ribs spring from, so they look grown rather than
	-- planted in the top of the stem.
	mk({ name = "CageMouth", size = Vector3.new(1.34, 0.30, 1.28),
		cf = at * CFrame.new(0.02, 3.06, 0.04) * CFrame.Angles(rad(-5), rad(11), 0),
		color = C.Cinder, parent = m })

	--==========================================================================
	-- THREE RIBS, WALKED RATHER THAN PLACED
	--
	-- The first attempt positioned each segment by its own height and radius,
	-- which guaranteed nothing about whether one met the next -- and they did
	-- not. It read as a sunburst of loose blocks.
	--
	-- Each rib is now walked with a CURSOR. A segment is laid along the cursor's
	-- own forward axis, then the cursor advances the whole segment length and
	-- turns inward. Built that way an arc cannot come apart, because every
	-- segment starts exactly where the last one finished.
	--
	-- Three ribs, not four or six: the anti-overgeometry rule warns against
	-- rings of identical parts, and three is the fewest that still encloses. The
	-- bearings are uneven and each rib closes by a different amount, so the cage
	-- is lopsided the way a grown thing is.
	--==========================================================================
	local ribs = {
		{ bearing = -34, close = 1.00, tint = C.LotusDeep },
		{ bearing = 78, close = 0.88, tint = C.Lotus },
		{ bearing = 196, close = 0.94, tint = C.LotusDeep },
	}
	-- length, how far to turn inward AFTER it, thickness
	local segments = {
		{ 1.05, 30, 0.30 },
		{ 0.95, 34, 0.26 },
		{ 0.80, 38, 0.22 },
	}
	for i, rib in ipairs(ribs) do
		-- Start at the collar rim, already leaning out a little so the cage
		-- flares before it closes.
		local cursor = at * CFrame.new(0.02, 3.16, 0.04)
			* CFrame.Angles(0, rad(rib.bearing), 0)
			* CFrame.new(0, 0, -0.62 * rib.close)
			* CFrame.Angles(rad(-16), 0, 0)
		for k, sg in ipairs(segments) do
			local len = (sg[1] :: number) * rib.close
			local turn = sg[2] :: number
			local thick = sg[3] :: number
			-- Laid along the cursor's LOCAL Y, centred half a length along it.
			mk({ name = string.format("Rib%d_%d", i, k),
				size = Vector3.new(thick, len, thick * 1.35),
				cf = cursor * CFrame.new(0, len * 0.5, 0),
				color = rib.tint, parent = m })
			-- Advance the full length, then turn inward for the next segment.
			cursor = cursor * CFrame.new(0, len, 0) * CFrame.Angles(rad(turn), 0, 0)
		end
	end

	--== THE CROWN KNOT ==--
	-- Where the three ribs nearly meet. Offset from the axis so the cage does
	-- not close symmetrically, which would read as machined.
	mk({ name = "CageKnot", size = Vector3.new(0.38, 0.30, 0.36),
		cf = at * CFrame.new(0.12, 5.18, -0.06) * CFrame.Angles(rad(12), rad(24), rad(-8)),
		color = C.Cinder, parent = m })

	--==========================================================================
	-- THE SIGNATURE: THE CORE, HUNG IN THE HOLLOW
	--==========================================================================
	local core = mk({ name = "Core", size = Vector3.new(0.54, 0.54, 0.54),
		cf = at * CFrame.new(0.04, 4.10, -0.02), color = C.CoreEmber,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	mk({ name = "Halo", size = Vector3.new(1.42, 0.08, 1.42),
		cf = at * CFrame.new(0.04, 4.10, -0.02) * CFrame.Angles(rad(9), 0, rad(90)),
		color = C.Lotus, material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder, smooth = true, parent = m })
	--==========================================================================
	-- WHAT THE MYTHIC SPENDS ITS EXTRA PARTS ON
	--
	-- This species runs over the 25-40 band on purpose. Every addition below is
	-- held to the same test the rest of the model is -- change the silhouette,
	-- explain anatomy, make a colour region, carry an animation seam, or be a
	-- close-range focal detail -- and anything that failed it was cut.
	--
	-- The cost is real: a bed of twelve at this count is over 570 parts, where
	-- twelve Cinderpaws is 456. It is affordable because a Mythic is a 0.2%
	-- roll, so a plot will almost never hold two.
	--==========================================================================

	--== COLLAR PETALS: a colour region where there was a bare plate ==--
	local collar = { { -18, 0.62 }, { 104, 0.54 }, { 226, 0.58 } }
	for i, cp in ipairs(collar) do
		mk({ name = "Collar" .. i,
			size = Vector3.new(cp[2] :: number, 0.12, 0.54),
			cf = at * CFrame.new(0.02, 3.02, 0.04)
				* CFrame.Angles(0, rad(cp[1] :: number), 0)
				* CFrame.new(0, 0.02, -0.62)
				* CFrame.Angles(rad(-22), 0, rad((i % 2 == 0) and 8 or -7)),
			color = C.Lotus, parent = m })
	end

	--== ORBIT MOTES: three beads hung inside the cage ==--
	-- Different radii, heights and bearings, so they read as caught in the
	-- updraught rather than as a bracelet. Each is its own animation seam.
	local motes = { { 34, 0.52, 3.72 }, { 158, 0.66, 4.34 }, { 268, 0.44, 4.02 } }
	for i, mo in ipairs(motes) do
		mk({ name = "Mote" .. i, size = Vector3.new(0.16, 0.16, 0.16),
			cf = at * CFrame.Angles(0, rad(mo[1] :: number), 0)
				* CFrame.new(0, mo[3] :: number, -(mo[2] :: number)),
			color = C.EmberPale, material = Enum.Material.Neon,
			shape = Enum.PartType.Ball, smooth = true, parent = m })
	end

	--== HUNG SEEDS: two, uneven, breaking the arc outline ==--
	mk({ name = "HungSeed1", size = Vector3.new(0.19, 0.26, 0.19),
		cf = at * CFrame.new(-0.74, 4.02, -0.34) * CFrame.Angles(rad(9), 0, rad(-12)),
		color = C.LotusDeep, parent = m })
	mk({ name = "HungSeed2", size = Vector3.new(0.15, 0.21, 0.15),
		cf = at * CFrame.new(0.58, 4.62, 0.42) * CFrame.Angles(rad(-7), 0, rad(10)),
		color = C.LotusDeep, parent = m })

	--==========================================================================
	-- THE AURA -- WHAT MAKES IT READ AS MYTHIC BEFORE YOU READ THE WORD
	--
	-- Everything here is Attachments and ParticleEmitters, so it costs the part
	-- budget NOTHING. That matters: the model is already over the band on
	-- geometry, and this is the one way left to add presence without adding to
	-- that number.
	--
	-- Three emitters, because one at a high rate just looks like smoke. They work
	-- at different speeds and different heights, and the eye reads the layering
	-- as "this thing is radiating" rather than "this thing is on fire":
	--
	--   Motes   a slow churn filling the cage hollow. NOT a column: the first
	--           tuning gave these 4 studs/s and 3.2 of upward acceleration and
	--           they shot eight studs clear of the plant, which read as a smoke
	--           plume -- a thing on fire, colliding with Kilnhusk's furnace and
	--           Emberquill's torch. Dragged and barely accelerated, they stay in
	--           the hollow and the cage looks FULL instead of venting.
	--   Aura    a slow, wide, near-still haze hanging AROUND and ABOVE the crown.
	--           Long lifetime and heavy drag, so it hangs rather than rises. This
	--           is the halo you see from across the plot.
	--   Sparks  small, bright, quick pinpricks in every direction. Punctuation on
	--           top of the haze, so the aura glitters instead of sitting flat.
	--   Crown   a hovering cloud of DISTINCT dots above the cage. The other three
	--           blur into one glow at any distance, which is the right read for
	--           a halo but means you never actually count particles. These are
	--           kept small and slow on purpose: small enough that they never
	--           merge, slow enough that they hang there and can be counted.
	--
	-- All three run LightInfluence = 0 and LightEmission = 1, which is what keeps
	-- them bright at night and under the biome's dark ambient -- the whole point
	-- of a rarity tell is that it survives bad lighting.
	--
	-- COST: about 220 live particles per plant. That is affordable only because a
	-- Mythic is a 0.2% roll and a plot will almost never hold two. If it ever
	-- does need trimming, Aura.Rate is the dial -- it owns roughly half the total
	-- and it is the cheapest to thin without losing the read.
	--==========================================================================
	local light = Instance.new("PointLight")
	light.Name = "CoreGlow"
	light.Color = C.Ember
	-- Wider than it is bright: this should wash the ground around the plant
	-- rather than blow out the core, which is what the old 2.2 was doing.
	light.Brightness = 1.45
	light.Range = 16
	light.Shadows = false
	light.Parent = core

	--== MOTES: the rising column ==--
	local att = Instance.new("Attachment")
	att.Name = "CoreAttachment"
	att.Parent = core
	local em = Instance.new("ParticleEmitter")
	em.Name = "Motes"
	em.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.LotusCore),
		ColorSequenceKeypoint.new(0.45, C.EmberPale),
		ColorSequenceKeypoint.new(1, C.Ember),
	})
	-- Grows just after birth, so the column has a waist rather than being a
	-- uniform stream of identical dots.
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.10),
		NumberSequenceKeypoint.new(0.3, 0.40),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(1.0, 1.7)
	em.Rate = 38
	-- Slow and heavily dragged, so they hang in the cage instead of venting.
	em.Speed = NumberRange.new(0.4, 1.1)
	em.Drag = 2.4
	em.SpreadAngle = Vector2.new(55, 55)
	em.Acceleration = Vector3.new(0, 0.7, 0)
	em.EmissionDirection = Enum.NormalId.Top
	em.Rotation = NumberRange.new(0, 360)
	em.RotSpeed = NumberRange.new(-40, 40)
	em.LightEmission = 1
	em.LightInfluence = 0
	em.Parent = att

	--== AURA: the slow haze that hangs above the crown ==--
	-- The core is an unrotated ball, so an offset on ITS attachment is a clean
	-- world-space offset -- putting this above the cage knot without inheriting
	-- the knot's tilt.
	local auraAtt = Instance.new("Attachment")
	auraAtt.Name = "AuraAttachment"
	auraAtt.Position = Vector3.new(0, 0.95, 0)
	auraAtt.Parent = core
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "Aura"
	aura.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.EmberPale),
		ColorSequenceKeypoint.new(0.5, C.Ember),
		ColorSequenceKeypoint.new(1, C.LotusDeep),
	})
	aura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, 1.05),
		NumberSequenceKeypoint.new(1, 0.20),
	})
	-- Fades in AND out, so nothing ever pops into or out of existence.
	aura.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.30),
		NumberSequenceKeypoint.new(0.8, 0.44),
		NumberSequenceKeypoint.new(1, 1),
	})
	aura.Lifetime = NumberRange.new(2.0, 3.2)
	aura.Rate = 34
	-- Dragged to a near stop with NO upward pull at all. Any acceleration here
	-- and the haze drifts off the plant and becomes a second, weaker plume; at
	-- zero it sits on the crown like a worn halo, which is the whole point.
	aura.Speed = NumberRange.new(0.15, 0.55)
	aura.Drag = 3.4
	aura.Acceleration = Vector3.new(0, 0, 0)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Rotation = NumberRange.new(0, 360)
	aura.RotSpeed = NumberRange.new(-22, 22)
	aura.LightEmission = 1
	aura.LightInfluence = 0
	-- Pushed behind the geometry so the cage ribs stay crisp through the haze.
	aura.ZOffset = -0.6
	aura.Parent = auraAtt

	--== SPARKS: the glitter on top ==--
	local sparkAtt = Instance.new("Attachment")
	sparkAtt.Name = "SparkAttachment"
	sparkAtt.Position = Vector3.new(0, 0.85, 0)
	sparkAtt.Parent = core
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Color = ColorSequence.new(C.Glint, C.EmberPale)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new(0.1, 1)
	sparks.Lifetime = NumberRange.new(0.7, 1.3)
	sparks.Rate = 16
	-- Fast off the mark but dragged hard, so each spark darts a short way and
	-- stops -- a shell of glitter around the crown rather than a fountain.
	sparks.Speed = NumberRange.new(1.4, 2.8)
	sparks.Drag = 3.6
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, 0.25, 0)
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Parent = sparkAtt

	--== CROWN: the cloud of separate motes hanging over the plant ==--
	-- Sits just clear of the tallest geometry (the model is 5.77 tall and the
	-- core is at 4.10, so +1.9 puts this at about 6.0) -- above the plant, which
	-- is the point, but close enough that it still reads as belonging to it.
	local crownAtt = Instance.new("Attachment")
	crownAtt.Name = "CrownAttachment"
	crownAtt.Position = Vector3.new(0, 1.90, 0)
	crownAtt.Parent = core
	local crown = Instance.new("ParticleEmitter")
	crown.Name = "Crown"
	crown.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.LotusCore),
		ColorSequenceKeypoint.new(0.6, C.EmberPale),
		ColorSequenceKeypoint.new(1, C.Ember),
	})
	-- Deliberately SMALL and near-constant. A mote that swells is a mote that
	-- merges with its neighbours, and then this is just more haze.
	crown.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.15, 0.19),
		NumberSequenceKeypoint.new(0.85, 0.17),
		NumberSequenceKeypoint.new(1, 0),
	})
	crown.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.08),
		NumberSequenceKeypoint.new(0.85, 0.12),
		NumberSequenceKeypoint.new(1, 1),
	})
	crown.Lifetime = NumberRange.new(2.2, 3.6)
	crown.Rate = 24
	crown.Speed = NumberRange.new(0.35, 1.10)
	-- Enough drag to stop them dispersing, a whisper of lift so the cloud
	-- breathes upward instead of sitting dead still.
	crown.Drag = 2.2
	crown.Acceleration = Vector3.new(0, 0.30, 0)
	crown.SpreadAngle = Vector2.new(180, 180)
	crown.Rotation = NumberRange.new(0, 360)
	crown.RotSpeed = NumberRange.new(-30, 30)
	crown.LightEmission = 1
	crown.LightInfluence = 0
	crown.Parent = crownAtt
	return m
end

--==============================================================================
-- WHAT EACH APPROVED PLANT ACTUALLY MEASURES
--
-- The true silhouette height over the ROTATED corners of every part, taken off
-- the approved mockup. Not a design dial: change one of these and the plant
-- comes out the wrong size relative to its four siblings, which is the one
-- thing the approval fixed.
--==============================================================================
EmberrootForms.AuthoredHeight = {
	cinderpaw = 3.474,
	slagbloom = 3.736,
	kilnhusk = 5.196,
	pyrelotus = 5.775,
	emberquill = 5.994,
} :: { [string]: number }

local BUILDERS: { [string]: (Instance, CFrame) -> Model } = {
	cinderpaw = cinderpaw,
	emberquill = emberquill,
	slagbloom = slagbloom,
	kilnhusk = kilnhusk,
	pyrelotus = pyrelotus,
}

--==============================================================================
-- A NumberSequence DOES NOT SCALE ITSELF
--
-- Pyrelotus is the only plant in the game that carries particles, and a
-- Colossal is fifty times a Tiny. Left alone, its aura would be a pinprick of
-- glitter beside a fifteen-stud flower -- the effect would simply stop reading
-- at exactly the tier it is supposed to celebrate.
--==============================================================================
local function scaleSequence(seq: NumberSequence, s: number): NumberSequence
	local pts = {}
	for _, k in ipairs(seq.Keypoints) do
		table.insert(pts, NumberSequenceKeypoint.new(k.Time, k.Value * s, k.Envelope * s))
	end
	return NumberSequence.new(pts)
end

--==============================================================================
-- BUILD ONE, GROWN TO THE FRAME HEIGHT ASKED FOR
--
-- The species builders each make their own Model, which is how they were
-- approved and how the mockup still calls them. Rather than rewrite five
-- functions, this builds into a scratch folder, grows what came out, and hands
-- the parts to the caller's model -- so CreatureModel keeps its own pivot and
-- its own tag, and the approved code is never touched.
--==============================================================================
function EmberrootForms.Build(model: Model, id: string, at: CFrame, hs: number): boolean
	local fn = BUILDERS[id]
	if not fn then
		return false
	end
	local scratch = Instance.new("Folder")
	scratch.Parent = model
	local built = fn(scratch, at)

	if math.abs(hs - 1) > 1e-6 then
		for _, d in ipairs(built:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = at * scaled(at:ToObjectSpace(d.CFrame), hs)
				d.Size = d.Size * hs
			elseif d:IsA("Attachment") then
				d.Position = d.Position * hs
			elseif d:IsA("PointLight") then
				d.Range = d.Range * hs
			elseif d:IsA("ParticleEmitter") then
				d.Size = scaleSequence(d.Size, hs)
				d.Speed = NumberRange.new(d.Speed.Min * hs, d.Speed.Max * hs)
				d.Acceleration = d.Acceleration * hs
			end
		end
	end

	for _, d in ipairs(built:GetChildren()) do
		d.Parent = model
	end
	scratch:Destroy()
	return true
end

return EmberrootForms
