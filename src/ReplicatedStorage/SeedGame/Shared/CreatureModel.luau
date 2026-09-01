--!strict
-- Steal a Seed :: CreatureModel
--
-- Builds the pod you steal and the creature it grows into, to the Greenhollow
-- reference sheets in KB/biome1-plants.png and KB/biome1-pods.png.
--
-- NOT a *Service. No lifecycle, just geometry -- same as MapDecor and HubFairy.
--
--==============================================================================
-- ROBLOX HAS NO CONE, NO EGG, AND NO DOME
--
-- Four of the five forms on the sheet are shapes the engine cannot make. Every
-- one is approximated from Block, Ball and Cylinder, and the approximations are
-- written down here because the next person will otherwise assume a mesh went
-- missing:
--
--   teardrop  a Ball with two mirrored Wedges above it, which from the front
--             reads as a point rather than as a roof.
--   dome cap  a Cylinder disc with a Ball resting on it. A Ball alone cannot
--             do it -- Roblox sizes a Ball by its SMALLEST axis, so a wide flat
--             sphere is not a thing that exists.
--   bell      three stacked Cylinders widening downward. A cone by staircase.
--   egg       two overlapping Balls, the upper slightly smaller.
--
-- That Ball rule catches everyone once: setting a Ball to (4, 1, 4) does not
-- give a squashed sphere, it gives a sphere of diameter 1.
--
--==============================================================================
-- THE FACE IS THE WHOLE CHARACTER, AND IT IS SEVEN PARTS
--
-- Two black eyes, two white highlights, three blocks of smile. The highlights
-- are what make it read as alive rather than as a hole, and the smile is three
-- parts rather than one because a straight bar reads as a grimace -- offsetting
-- the ends upward by a hair is the entire difference between a creature that
-- looks pleased and one that looks unwell.
--
-- Budget: ~12 parts of body plus 0-8 of crown. Six plots of twelve slots is 72
-- creatures, so roughly 1,200 parts at tier 1. Worth watching as tiers grow.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local TanglemireForms = require(Shared:WaitForChild("TanglemireForms"))
local EmberrootForms = require(Shared:WaitForChild("EmberrootForms"))
local StarbloomForms = require(Shared:WaitForChild("StarbloomForms"))

local CreatureModel = {}

CreatureModel.STAGE_POD = 1
CreatureModel.STAGE_SPROUT = 2
CreatureModel.STAGE_GROWN = 3

export type Stage = number

-- Small enough that growth is obviously incomplete from across the plot, big
-- enough to tell what it is -- because knowing what is nearly ready is what
-- makes somebody else's plot worth watching.
local SPROUT_SCALE = 0.45

local DARK = Color3.fromRGB(38, 34, 40)
local WHITE = Color3.fromRGB(252, 252, 250)
-- Tanglemire is the only biome whose eye shows a sclera, so this colour is used
-- exactly once. AMBER, not pale green: the first try was (206, 220, 190) and it
-- sat within a few points of Bogbonnet's own pale mint head, so the eyeball sank
-- into the face and only the slit carried it. A jaundiced yellow separates by
-- hue as well as value against every green head in the biome, and it is what an
-- amphibian's eye actually looks like -- which is the read the slit is after.
-- TWO ambers, and the species picks whichever it contrasts with. One fixed
-- colour cannot work: amber against Bogbonnet's mint head is a luminance gap of
-- 0.417, but against Lanterncap's own pale amber body it is 0.035 and the
-- eyeball vanishes into the face. Choosing by contrast costs no parts and needs
-- no per-species table to keep in step when a body colour changes.
local SCLERA_LIGHT = Color3.fromRGB(214, 192, 96)
local SCLERA_DARK = Color3.fromRGB(78, 66, 24)
-- Starbloom's pinprick. Cold where Emberroot's is hot, which is the whole
-- difference between the last two biomes said in one part.
local STARLIGHT = Color3.fromRGB(198, 214, 255)

type Opts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	shape: Enum.PartType?,
	material: Enum.Material?,
	-- Studded unless told otherwise. Only the face opts out.
	studs: boolean?,
}

--==============================================================================
-- STUDS GO ON EVERYTHING, INCLUDING THE ROUND PARTS
--
-- Worth stating because the obvious assumption is wrong: Roblox renders surface
-- studs on Ball and Cylinder parts too, not only on Blocks -- they wrap round
-- the curve. Tested before relying on it, because building the creatures out of
-- blocks to "make studs possible" would have thrown away the shapes.
--
-- Material must be Plastic. SmoothPlastic has no studs at all, and Ground,
-- Grass and WoodPlanks paint their own noise OVER the studs -- which is the
-- trap that made the plot beds look smooth next to a studded field.
--
-- All six faces, not just the top: a creature is seen from every side, and
-- studs on the top alone reads as a manufacturing defect.
--==============================================================================
local STUD_FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

local function part(o: Opts): BasePart
	local p = Instance.new("Part")
	p.Name = o.name
	p.Size = o.size
	p.CFrame = o.cframe
	p.Color = o.color
	p.Shape = o.shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false

	local studded = o.studs ~= false
	p.Material = o.material or (if studded then Enum.Material.Plastic
		else Enum.Material.SmoothPlastic)
	-- Enum.SurfaceType, not Enum.NormalId. Both have a Top, and the wrong one
	-- fails at runtime rather than at compile time.
	local surface = if studded then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	for _, face in ipairs(STUD_FACES) do
		(p :: any)[face] = surface
	end
	p.Parent = o.parent
	return p
end

-- An upright cylinder. Roblox cylinders run along their LOCAL X, so standing
-- one up is a 90-degree roll, and the caller should not have to remember that.
local function upright(name: string, height: number, diameter: number, cf: CFrame,
	color: Color3, parent: Instance, studs: boolean?): BasePart
	return part({
		name = name,
		size = Vector3.new(height, diameter, diameter),
		cframe = cf * CFrame.Angles(0, 0, math.rad(90)),
		color = color,
		shape = Enum.PartType.Cylinder,
		parent = parent,
		studs = studs,
	})
end

local function ball(name: string, diameter: number, cf: CFrame, color: Color3,
	parent: Instance, studs: boolean?): BasePart
	return part({
		name = name,
		size = Vector3.new(diameter, diameter, diameter),
		cframe = cf,
		color = color,
		shape = Enum.PartType.Ball,
		parent = parent,
		studs = studs,
	})
end

local function wedge(name: string, size: Vector3, cf: CFrame, color: Color3,
	parent: Instance): BasePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	for _, face in ipairs(STUD_FACES) do
		pcall(function()
			(p :: any)[face] = Enum.SurfaceType.Studs
		end)
	end
	p.Parent = parent
	return p
end

--==============================================================================
-- A TAPERED PLATE, WHICH IS NOT THE SAME AS A WEDGE
--
-- `wedge` above takes a raw Vector3 and applies no rotation of its own. Every
-- Dustbowl plate -- root feet, sepals, husk plates, blades, lobes -- was
-- authored against a different convention: size (thick, length, width) PLUS a
-- 90-degree yaw, which is what makes the plate taper to a point across its
-- WIDTH. Sized the other way it tapers the THICKNESS and reads as a rectangle
-- from every angle, which is what the first Dunebud pass looked like.
--
-- The taper is a RIGHT triangle, so pairs must mirror or the whole set leans
-- one way.
--
-- A separate helper, not a change to `wedge`: five shipped Greenhollow forms
-- call that one and none of them should move today.
--==============================================================================
-- A disc lying in the XY plane, facing FORWARD along Z -- a coin seen face-on,
-- not `upright`'s pancake seen edge-on. Paddlehop's pad is a flat slab and its
-- rounded rims are these; without them the pad is a rectangle with corners.
local function coin(name: string, diameter: number, thick: number, cf: CFrame,
	color: Color3, parent: Instance): BasePart
	return part({
		name = name,
		size = Vector3.new(thick, diameter, diameter),
		cframe = cf * CFrame.Angles(0, math.rad(90), 0),
		color = color,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
end

local function plate(name: string, width: number, length: number, thick: number,
	cf: CFrame, color: Color3, parent: Instance, mirror: boolean?): BasePart
	return wedge(name, Vector3.new(thick, length, width),
		cf * CFrame.Angles(0, math.rad(90), 0)
			* (if mirror then CFrame.Angles(0, math.pi, 0) else CFrame.new()),
		color, parent)
end

--==============================================================================
-- THE FACE IS MOULDED, NOT PRINTED
--
-- Every piece of it used to be 0.08 studs thick and smooth: two Eye cards, two
-- Glints, two Cheeks and three Smile bars, all lying flat against the front of
-- the head. That is a DECAL made of parts. It disappeared from any angle off
-- dead centre -- and now that plants walk and each one stands on its own
-- bearing, dead centre is exactly where the player usually is not.
--
-- The comment that used to live here said a stud on a 0.3-stud eye is a
-- blister rather than a texture. That was true OF A CARD. It is not true of a
-- ball: a creature in this game is moulded plastic, and its eyes are lumps of
-- the same plastic, not stickers on it.
--
--     eyes     dark balls, centred ON the surface so half stands proud
--     glints   smaller balls sitting on the eyes
--     cheeks   balls, outboard and low
--     smile    still three blocks -- one bar reads as a grimace -- but deep
--
-- ONE SHARED LIGHT. The glint sits upper-LEFT on BOTH eyes rather than being
-- mirrored. That is what makes two spheres read as one face lit from one side
-- instead of two googly eyes.
--
-- `front` is the surface the face sits on and it is per-form for a reason: the
-- widest part of a head is not always the part the face is on. The bell proved
-- it once already, with a smile inside its own skirt.
--==============================================================================
--==============================================================================
-- ONE EYE PER BIOME
--
-- Every species used to share a dark ball and a white glint. BiomeData already
-- ranks the biomes by mood -- 🙂 😐 😟 😨 💀 in order -- so the eyes escalate
-- along that ladder instead of being five unrelated looks, and each is a
-- different KIND of eye rather than a recolour, so the difference survives being
-- seen small and from across a plot.
--
-- THE RIG FALLS OUT OF THE NAMES. PlantSway takes the pupil rig for anything
-- ending in "Pupil" and slides the whole eye otherwise. So the three biomes that
-- have a pupil get the better treatment -- eye still, pupil travelling across it
-- -- and the two that do not keep sliding the eye, which is the only thing you
-- can do with an eye that is already all pupil.
--==============================================================================
local EYE_STYLE: { [string]: string } = {
	greenhollow = "doe",
	dustbowl = "squint",
	tanglemire = "slit",
	emberroot = "ember",
	starbloom = "void",
}

--==============================================================================
-- TANGLEMIRE'S EYE HAS TO BE RETROFITTED, BECAUSE IT NEVER MEETS addFace
--
-- Tanglemire replays frozen approved geometry and returns before the shared
-- face builder runs, so its five would have kept the old dark-ball-and-glint
-- while every other biome got its own eye. This reworks the eyes the mockup
-- already placed rather than adding a second face: the balls stay exactly where
-- and how big they were approved, and only their COLOUR changes, plus a slit.
--
-- Safe to hang a pupil on: measured against the PLACEMENT frame the frozen eyes
-- sit at rotation (0, 0, 0), dead symmetric. They look rotated -94 degrees when
-- measured against the model pivot, but that is the Base cylinder being rolled
-- on its side, not the eyes -- and PlantSway reconstructs the eye's own frame
-- from that same pivot, so a pupil in the eye's local space travels correctly.
--==============================================================================
--==============================================================================
-- A LID ON EVERY EYE
--
-- Blinking needs something to close, and the eyes are BALLS -- a Roblox Ball
-- renders as a sphere of its smallest axis, so squashing one shut does nothing
-- at all. It has to be a separate part sweeping over the eye.
--
-- Built in the creature's own skin so it reads as brow rather than as a bar,
-- and parked clear ABOVE the eye where it is part of the face until it drops.
-- Dustbowl parks its much lower, which is what its squint is.
--
-- `gap` is where its lower edge rests relative to the eye's TOP, in
-- diameters: positive floats it clear as a brow, negative parks it down over
-- the eye, which is exactly what Dustbowl's squint is.
-- The old note said `rest` was a height above the eye centre. The rig works the blink
-- travel out from that and the eye's radius rather than being told, so a lid
-- that starts low has a short blink and one that starts high has a long one --
-- and it stays right at any weight, because both come off the parts.
--==============================================================================
-- Tall enough to hide a whole eye. At 0.56 the first version covered the
-- bottom 56% and left the top staring out, however far it travelled.
-- The eye SHRINKS as the lid comes down, so the lid no longer has to hide a
-- full-size ball. At 1.16 it was a plate wider and taller than the eye,
-- standing proud of a curved face -- two shutters bolted on rather than
-- eyelids. Smaller, over a closing eye, reads as a lid.
local LID_H = 0.72
local function addLid(model: Model, tag: string, eyeCF: CFrame, eyeDia: number,
	gap: number, skin: Color3?)
	-- DEEP ENOUGH TO PASS IN FRONT OF THE EYE. The ball is centred ON the head
	-- surface, so half of it stands proud -- a shallow lid sitting near the skin
	-- sweeps down BEHIND that hemisphere and is hidden by the very thing it is
	-- meant to cover. Held shut, the first version left the eyes wide open.
	--
	-- So it is pushed forward and 0.72 diameters deep -- spanning from just
	-- behind the eye's centre to 0.16 clear of its front pole. 1.3 was the first
	-- try and it worked, but it stood a whole diameter proud of the face and
	-- read as two boxes glued on rather than as eyelids. The eye only sticks out
	-- half a diameter; there is nothing to gain past that.
	part({
		name = tag .. "Lid",
		size = Vector3.new(eyeDia * 1.24, eyeDia * LID_H, eyeDia * 0.62),
		cframe = eyeCF * CFrame.new(0, eyeDia * (0.5 + LID_H * 0.5 + gap), -eyeDia * 0.30),
		color = skin or DARK,
		parent = model,
		studs = false,
	})
end

local function luminance(c: Color3): number
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

--==============================================================================
-- WHICH PART IS THE HEAD?
--
-- Cannot be answered by name. Only Bogbonnet calls its head "Bulb" -- Crookreed
-- has a CattailBody, Lanterncap a Lantern, and Snapmoss has no part enclosing
-- its eye at all. This is replayed mockup geometry and each of the five was
-- authored on its own terms.
--
-- So it is answered by GEOMETRY: the biggest solid part whose box contains the
-- eye, and failing that the nearest solid part. Transparent things are skipped
-- or Gloomlotus would hand back its aura shell, which is not a head and is not
-- the colour of one.
--==============================================================================
local FACEY = { "Eye", "Pupil", "Lid", "Cheek", "Smile", "Glint" }
local function mireHeadColor(model: Model, eye: BasePart): Color3?
	local best, bestVol, near, nearD = nil, 0, nil, math.huge
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Transparency < 0.5 then
			local facey = false
			for _, tag in ipairs(FACEY) do
				if string.find(d.Name, tag) then
					facey = true
					break
				end
			end
			if not facey then
				local lp = d.CFrame:PointToObjectSpace(eye.Position)
				local dist = (d.Position - eye.Position).Magnitude
				if dist < nearD then
					nearD, near = dist, d
				end
				if math.abs(lp.X) <= d.Size.X * 0.6
					and math.abs(lp.Y) <= d.Size.Y * 0.6
					and math.abs(lp.Z) <= d.Size.Z * 0.6 then
					local v = d.Size.X * d.Size.Y * d.Size.Z
					if v > bestVol then
						bestVol, best = v, d
					end
				end
			end
		end
	end
	local head = best or near
	return if head then head.Color else nil
end

local function retrofitMireEye(model: Model, skin: Color3)
	-- Whichever amber stands further from this species' own body.
	local sclera = if math.abs(luminance(SCLERA_LIGHT) - luminance(skin))
		>= math.abs(luminance(SCLERA_DARK) - luminance(skin))
		then SCLERA_LIGHT else SCLERA_DARK
	for _, tag in ipairs({ "Left", "Right" }) do
		local eye = model:FindFirstChild(tag .. "Eye")
		if eye and eye:IsA("BasePart") then
			local r = eye.Size.X * 0.5
			eye.Color = sclera
			part({
				name = tag .. "Pupil",
				size = Vector3.new(r * 0.36, r * 1.70, r * 1.00),
				-- Proud of the sclera by about a third of a radius, and rooted
				-- inside it, so it cannot detach as the gaze swings.
				cframe = eye.CFrame * CFrame.new(0, 0, -r * 0.86),
				-- On the dark sclera the slit has to invert, or it is a dark
				-- mark on a dark ball and there is no pupil at all.
				color = if sclera == SCLERA_DARK then Color3.fromRGB(18, 16, 10) else DARK,
				parent = model,
				studs = false,
			})
			-- The approved glint was a third of the eye and white. On a pale
			-- sclera that is invisible, so it moves onto the slit where a
			-- highlight has something to sit against.
			-- The frozen glint is renamed, not replaced: it becomes a second
			-- pupil so it rides the slit instead of sitting still on the sclera
			-- while the gaze swings out from under it.
			local glint = model:FindFirstChild(tag .. "Glint")
			if glint and glint:IsA("BasePart") then
				glint.Size = Vector3.new(r * 0.30, r * 0.30, r * 0.30)
				glint.CFrame = eye.CFrame * CFrame.new(-r * 0.20, r * 0.32, -r * 1.12)
				glint.Name = tag .. "Pupil"
			end
			-- TWO THINGS THIS BIOME NEEDS THAT THE OTHERS DO NOT.
			--
			-- The gap is negative. Every other biome's face sits on a broad
			-- head where a lid can float clear above the eye and still read as
			-- brow; Tanglemire's is a small ball with the eyes set high on it,
			-- so a lid 0.96 diameters up lands off the top of the skull
			-- entirely -- two slabs hanging in the air by the bonnet brim.
			-- Resting it ON the eye keeps it on the head.
			--
			-- And the colour comes off the HEAD PART, not sp.Body. This is
			-- replayed mockup geometry: its head is pale mint while sp.Body is
			-- the dark green of the stem, so a lid in sp.Body reads as a foreign
			-- plate stuck to the face rather than as part of it.
			addLid(model, tag, eye.CFrame, r * 2, -0.22, mireHeadColor(model, eye) or skin)
		end
	end
end

local function addFace(model: Model, headCF: CFrame, width: number, front: number,
	biome: string?, skin: Color3?)
	local eyeD = width * 0.23
	local gap = width * 0.23
	local style = EYE_STYLE[tostring(biome)] or "doe"

	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		-- Centred on the surface, so half the ball is outside the head. No
		-- fudge factor: the radius IS the proudness.
		local eyeCF = headCF * CFrame.new(side * gap, width * 0.06, -front)

		if style == "doe" then
			-- The biggest eye in the game, and the only one with a second
			-- catchlight. Two highlights is the whole trick behind a friendly
			-- cartoon eye -- one reads as wet, two reads as delighted.
			-- THE OFFSETS SCALE WITH THE EYE. This ball is 1.14x the size the
			-- other biomes use, and the first pass left the highlight offsets
			-- at the old radius -- which put the small sparkle 0.481 out on a
			-- ball of radius 0.570, entirely INSIDE it. It rendered as one
			-- highlight, not two, and two is the whole point of this eye.
			--
			-- BOTH are Pupils, so both travel. The rig keeps each one's offset
			-- from the eye centre and swings the pair together, which is what
			-- stops the sparkle collapsing onto the main highlight.
			local R = 1.14
			ball(tag .. "Eye", eyeD * R, eyeCF, DARK, model)
			ball(tag .. "Pupil", eyeD * 0.36,
				eyeCF * CFrame.new(-eyeD * 0.29 * R, eyeD * 0.27 * R, -eyeD * 0.33 * R),
				WHITE, model, false)
			ball(tag .. "Pupil", eyeD * 0.17,
				eyeCF * CFrame.new(eyeD * 0.23 * R, -eyeD * 0.25 * R, -eyeD * 0.36 * R),
				WHITE, model, false)
			addLid(model, tag, eyeCF, eyeD * R, 0.10, skin)

		elseif style == "squint" then
			ball(tag .. "Eye", eyeD, eyeCF, DARK, model)
			ball(tag .. "Pupil", eyeD * 0.30,
				eyeCF * CFrame.new(-eyeD * 0.26, eyeD * 0.18, -eyeD * 0.30),
				WHITE, model, false)
			-- This biome pays nothing for its blink. The slab that gives it the
			-- squint is already a lid, sitting low over the eye -- blinking is
			-- that same part finishing the movement it is already halfway
			-- through. It rests LOWER than the other biomes' lids, which is the
			-- squint, and the rig works the travel out from where it starts.
			addLid(model, tag, eyeCF, eyeD, -0.34, skin)

		elseif style == "slit" then
			-- The only eye in the game that shows a sclera. Everything else is
			-- a dark ball that is already all pupil, so a visible white-of-eye
			-- is instantly non-mammalian -- which is the read a swamp wants.
			ball(tag .. "Eye", eyeD * 1.02, eyeCF, SCLERA, model)
			part({
				name = tag .. "Pupil",
				size = Vector3.new(eyeD * 0.18, eyeD * 0.88, eyeD * 0.52),
				cframe = eyeCF * CFrame.new(0, 0, -eyeD * 0.44),
				color = DARK,
				parent = model,
				studs = false,
			})
			-- The highlight rides the slit rather than sitting still on the
			-- sclera: on an eye that HAS a pupil, a fixed catchlight drifts off
			-- it as the gaze swings and reads as a blemish on the eyeball.
			ball(tag .. "Pupil", eyeD * 0.20,
				eyeCF * CFrame.new(-eyeD * 0.30, eyeD * 0.26, -eyeD * 0.34),
				WHITE, model, false)
			addLid(model, tag, eyeCF, eyeD * 1.02, 0.10, skin)

		elseif style == "ember" then
			ball(tag .. "Eye", eyeD, eyeCF, DARK, model)
			ball(tag .. "Pupil", eyeD * 0.46,
				eyeCF * CFrame.new(0, 0, -eyeD * 0.44),
				Color3.fromRGB(255, 222, 150), model, false)
			addLid(model, tag, eyeCF, eyeD, 0.10, skin)

		else -- "void"
			-- No glint. That is the entire design: a highlight is what makes an
			-- eye look wet, and taking it away is what makes this one look like
			-- it is not alive. One cold pinprick, and nothing else.
			ball(tag .. "Eye", eyeD * 1.06, eyeCF, Color3.fromRGB(14, 12, 20), model)
			ball(tag .. "Pupil", eyeD * 0.20,
				eyeCF * CFrame.new(0, 0, -eyeD * 0.46),
				STARLIGHT, model, false)
			addLid(model, tag, eyeCF, eyeD * 1.06, 0.10, skin)
		end
	end

	--==========================================================================
	-- CHEEKS SIT CLOSE, BECAUSE THE HEAD IS ROUND
	--
	-- `front` is the surface distance at the CENTRE of the face. Four of the
	-- five heads are spheres, so the real surface falls away as you move out --
	-- at 1.9 gaps from centre on an orb it has dropped 0.19 of a head width
	-- behind `front`, and a ball placed there hangs in the air beside the head.
	--
	-- It got away with that as a flat card because a card that thin reads as
	-- part of the outline from the front and is invisible from the side. A
	-- sphere does not: it is visible from everywhere, floating included.
	--
	-- 1.45 gaps is the furthest out the error stays under a cheek's own radius
	-- on every one of the five, and 0.88 of `front` sets it just into the skin.
	-- No per-form parameter needed, which is worth more than the extra reach.
	--==========================================================================
	for _, side in ipairs({ -1, 1 }) do
		ball("Cheek", width * 0.15,
			headCF * CFrame.new(side * gap * 1.45, -width * 0.08, -front * 0.88),
			SeedData.Blush, model)
	end

	-- Lifting the ends by a hair is the whole difference between pleased and
	-- unwell. Smooth, like the eyes' glints -- a mouth is a line, and studs on
	-- one really would be a blister.
	local mw = width * 0.10
	for _, spec in ipairs({ { -1, 0.030 }, { 0, 0 }, { 1, 0.030 } }) do
		local sx: number, lift: number = spec[1], spec[2]
		part({
			name = "Smile",
			size = Vector3.new(mw, width * 0.05, width * 0.07),
			cframe = headCF * CFrame.new(sx * mw * 0.92,
				-width * 0.15 + lift * width, -front * 0.99),
			color = DARK,
			parent = model,
			studs = false,
		})
	end
end

--==============================================================================
-- THE CROWNS
--==============================================================================
--==============================================================================
-- A FLOWER WITH A BACK TO IT
--
-- Five petals lying flat in one plane is a paper daisy: edge-on from the side
-- it vanishes to five lines, and there was nothing underneath it at all -- the
-- flower simply started in mid-air above a bald orb.
--
-- Three changes, no extra petals: they TILT UP so the flower is a shallow bowl
-- rather than a disc, they are thicker, and a ring of three SEPALS sits under
-- them in the leaf colour. The sepals are what make it grow out of the head
-- instead of resting on it.
--==============================================================================
local function addFlower(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- Under the petals and offset half a step round, so they show through the
	-- gaps rather than hiding directly behind.
	for i = 1, 3 do
		local a = (i - 1) / 3 * math.pi * 2 + math.pi / 5
		part({
			name = "Sepal",
			size = Vector3.new(w * 0.20, w * 0.09, w * 0.34),
			cframe = top
				* CFrame.Angles(0, a, 0)
				* CFrame.new(0, -w * 0.11, -w * 0.20)
				* CFrame.Angles(math.rad(24), 0, 0),
			color = sp.Leaf,
			parent = model,
		})
	end
	for i = 1, 5 do
		local a = (i - 1) / 5 * math.pi * 2
		part({
			name = "Petal",
			size = Vector3.new(w * 0.38, w * 0.13, w * 0.32),
			cframe = top
				* CFrame.Angles(0, a, 0)
				* CFrame.new(0, 0, -w * 0.28)
				-- Cupped. Every petal lifts its outer edge by the same amount,
				-- which turns five flat cards into one shallow bowl.
				* CFrame.Angles(math.rad(-17), 0, 0),
			color = sp.Crown,
			parent = model,
		})
	end
	ball("FlowerCentre", w * 0.26, top * CFrame.new(0, w * 0.04, 0), sp.Accent, model)
end

--==============================================================================
-- SIX SPIKES, NOT THREE
--
-- Three big ones in a flat row read as a fan seen edge-on: from the side the
-- Spiretip had a crest, from the front it had a stick. The sheet has a RING of
-- smaller ones round the crown, which reads the same from every angle -- which
-- matters more now that plants walk and face different ways.
--
-- Turned as well as tilted, so each leans OUT from the centre rather than all
-- of them leaning within one plane.
--==============================================================================
local SPIRE_SPIKES = {
	-- turn round the crown, height, lean out
	{ 0.00, 1.00, 6 },
	{ 0.17, 0.72, 22 },
	{ 0.33, 0.86, 15 },
	{ 0.50, 0.66, 24 },
	{ 0.67, 0.90, 13 },
	{ 0.84, 0.74, 20 },
}

local function addSpikes(model: Model, sp: SeedData.Species, top: CFrame, w: number, h: number)
	for _, spec in ipairs(SPIRE_SPIKES) do
		local turn: number, scale: number, lean: number = spec[1], spec[2], spec[3]
		part({
			name = "Spike",
			size = Vector3.new(w * 0.13, h * 0.26 * scale, w * 0.11),
			cframe = top
				* CFrame.Angles(0, turn * math.pi * 2, 0)
				* CFrame.new(0, h * 0.11 * scale, -w * 0.24)
				* CFrame.Angles(math.rad(-lean), 0, 0),
			color = sp.Crown,
			parent = model,
		})
	end
end

local function addFronds(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- The drooping green fronds over the mushroom cap.
	for i = 1, 3 do
		local a = (i - 1) / 3 * math.pi * 2
		local arm = top * CFrame.Angles(0, a, 0)
		part({
			name = "Frond",
			size = Vector3.new(w * 0.09, w * 0.42, w * 0.09),
			cframe = arm * CFrame.new(0, w * 0.20, -w * 0.10),
			color = sp.Leaf,
			parent = model,
		})
		part({
			name = "FrondTip",
			size = Vector3.new(w * 0.22, w * 0.09, w * 0.16),
			cframe = arm * CFrame.new(0, w * 0.36, -w * 0.30)
				* CFrame.Angles(math.rad(-38), 0, 0),
			color = sp.Leaf,
			parent = model,
		})
	end
end

--==============================================================================
-- THE DIRT IT GROWS OUT OF
--
-- What was here before was ONE CYLINDER, 0.66 of the frame height across, and it
-- read as a hockey puck. Worse, it scaled with the frame: a 10,000 kg Bellchime
-- stood on a twenty-four stud brown pancake, so the biggest thing you could
-- grow was also the one that looked most like furniture.
--
-- The reference sheet has no plinth. It has a LOOSE HEAP -- a few clods of dirt
-- shoved up around the stem, irregular enough that no angle shows a circle, low
-- enough that the leaves hang over it. That is what this builds.
--
-- SEVEN BLOCKS, deterministic, overlapping and part-buried. Not spheres: a
-- Roblox Ball takes its diameter from its smallest axis, so a squashed lump is
-- not available without a mesh, and a tilted block reads as a clod perfectly
-- well. Not random: every other decoration in this file is a literal table for
-- the same reason -- two servers must build the same creature, and a bug report
-- that says "the third one looked wrong" has to mean something.
--
-- The first pass used six, spaced, sitting flat on the surface. They read as
-- separate BRICKS with gaps between them, which is worse than the puck was. It
-- takes overlap, a fifth of each clod buried, and a few degrees of tilt before
-- the eye stops counting them and starts seeing a heap.
--
-- Nine became seven when the heads were remodelled. Seven still overlaps into
-- one heap; the two it cost bought a brow, a collar and a set of sepals, which
-- are at eye level rather than under the leaves.
--
-- Sized off the STEM, not off the frame. That is the whole fix: dirt belongs to
-- the thing growing out of it, and a heavier plant gets a thicker stem and a
-- proportionally bigger heap rather than a bigger pancake.
--
-- Smooth, against a studded bed. The heap is the one thing here that is not
-- moulded plastic, and dropping the studs is what says so.
--==============================================================================
-- turn round the stem, distance out, width, height, yaw, and a tilt
local SOIL_CLODS = {
	-- Highest at the stem and thinning outward, so the heap has a peak rather
	-- than being a ring of debris.
	{ 0.00, 0.00, 1.70, 0.95, 0, 0 },
	{ 0.09, 0.80, 1.35, 0.80, 18, 7 },
	{ 0.24, 1.34, 1.05, 0.58, -34, -5 },
	{ 0.38, 0.60, 1.20, 0.88, 41, 9 },
	{ 0.53, 1.42, 0.95, 0.62, -12, 6 },
	{ 0.68, 0.84, 1.40, 0.82, 27, -8 },
	{ 0.84, 1.30, 1.00, 0.60, -39, 5 },
}

local function addSoil(model: Model, sp: SeedData.Species, cf: CFrame, stemW: number)
	for _, clod in ipairs(SOIL_CLODS) do
		local turn: number, out: number = clod[1], clod[2]
		local wide: number, tall: number = clod[3], clod[4]
		local yaw: number, tilt: number = clod[5], clod[6]
		local w = stemW * wide
		local h = stemW * tall
		part({
			name = "Soil",
			-- Deeper than wide by a fifth, so even the silhouette of one clod
			-- is not square.
			size = Vector3.new(w, h, w * 0.8),
			cframe = cf
				* CFrame.Angles(0, turn * math.pi * 2, 0)
				-- 0.38 rather than 0.5: each clod is a fifth buried, which is
				-- what merges nine boxes into one heap instead of nine boxes.
				--
				-- The tilt sinks the low corner further -- 1.2 studs under the
				-- surface on a 10,000 kg Bellchime. That is deliberate and it
				-- is not visible: planted, it is inside the bed; carried, the
				-- base rides below foot height so the overhang is inside the
				-- floor. PlantSway's anchor drops with it and the walk carries
				-- that same Y through, so nothing sinks or floats.
				* CFrame.new(0, h * 0.38, -stemW * out)
				* CFrame.Angles(math.rad(tilt * 0.6), math.rad(yaw), math.rad(tilt)),
			color = sp.Soil,
			parent = model,
			studs = false,
		})
	end
end

local function addBuds(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- A ring of stalked buds, as on the Bellchime. Four rather than seven: two
	-- parts each makes this the most expensive decoration in the file, and the
	-- bell is already the busiest form. Four still reads as a ring and the
	-- alternating lean keeps it from looking like a compass rose.
	for i = 1, 4 do
		local a = (i - 1) / 4 * math.pi * 2
		local lean = (i % 2 == 0) and 1.0 or 0.76
		local arm = top * CFrame.Angles(0, a, 0)
		local reach = w * 0.26
		part({
			name = "BudStalk",
			size = Vector3.new(w * 0.05, w * 0.40 * lean, w * 0.05),
			cframe = arm * CFrame.new(0, w * 0.20 * lean, -reach * 0.7)
				* CFrame.Angles(math.rad(-11), 0, 0),
			color = sp.Accent,
			parent = model,
		})
		ball("Bud", w * 0.18, arm * CFrame.new(0, w * 0.42 * lean, -reach), sp.Crown, model)
	end
end

--==============================================================================
-- THE CREATURE
--
-- An invisible pivot plate, a heap of dirt clods, stem, two leaves, a head that
-- depends on the form, a face, and a crown. The CFrame handed in is the BASE --
-- where it meets the ground.
--==============================================================================
--==============================================================================
-- WEIGHT IS AN ARGUMENT NOW, NOT A PROPERTY OF THE SPECIES
--
-- `kg` is the weight THIS pod rolled. It decides how big the thing is, what it
-- earns and what colour its shell was. The species decides only the form.
--
-- Nothing here may read `sp.Kg`. That field is the fallback for a plant saved
-- before weights were rolled, and a spawn that used it would be a creature
-- whose size disagreed with its own price tag.
--==============================================================================
-- THE DUSTBOWL FOOTING
--
-- What every Dustbowl species stands on, and it is identical on all five --
-- same rule as the shared stem and leaf colour. It replaces the seven soil
-- clods with four broad root feet spreading from one crown, plus a neck ring
-- that hides the head-to-stem join.
--
--   greenhollow  Base 1 + Soil 7 + Stem 1 + Leaf 4                     = 13
--   dustbowl     Base 1 + RootCrown 1 + RootFoot 4 + Stem 1 + Leaf 2
--                + Neck 1 + Sepal 2                                    = 12
--
-- FEET ARE BROAD AND THIN: 0.38-0.50 of head width across, 0.09-0.11 thick.
-- The first cut of this used 0.18-0.22 thick and produced four beams and a
-- block -- a stool, not a root system.
--
-- TWO LEAVES, NOT FOUR, AND THEY MUST BE DIRECT CHILDREN. PlantSway swings
-- parts named "Leaf" as opposed arms and finds them with model:GetChildren() --
-- direct children only -- working out which side each is on from its own X
-- offset. One per side is exactly what that wants.
--
-- The tables are literal and deterministic. Two servers must build the same
-- creature, and a bug report saying "the third one looked wrong" has to mean
-- something.
--==============================================================================
local DUST_FEET = {
	-- yaw, length, width, splay, tipCurl, thick
	{ 24, 0.72, 0.50, 82, 12, 0.11 },   -- the long front one, tip turns up
	{ 108, 0.52, 0.44, 85, 4, 0.10 },
	{ 200, 0.60, 0.48, 83, 7, 0.105 },
	{ 296, 0.34, 0.38, 88, 2, 0.09 },   -- the short chipped one
}
local DUST_SEPALS = { { 52, 0.62, 0.34 }, { 214, 0.46, 0.28 } }
local DUST_LEAVES = {
	-- side, long, wide, up, yaw, roll
	{ -1, 0.34, 0.15, 0.52, 18, -14 },
	{ 1, 0.26, 0.12, 0.68, -24, -30 },
}

local function addDustbowlFooting(model: Model, sp: SeedData.Species, cf: CFrame,
	H: number, G: number, stemW: number, stemH: number)
	local W = H * 0.46 * G

	-- Visible, unlike Base. This is the woody knot the feet spread from, and it
	-- is what the eye reads as the plant meeting the ground.
	part({
		name = "RootCrown",
		size = Vector3.new(stemW * 1.50, stemW * 0.44, stemW * 1.50),
		cframe = cf * CFrame.new(0, stemW * 0.22, 0),
		color = sp.Soil,
		parent = model,
	})

	for i, t in ipairs(DUST_FEET) do
		local yaw, length, width = t[1], t[2], t[3]
		local splay, curl, thick = t[4], t[5], t[6]
		local footCF = cf
			* CFrame.Angles(0, math.rad(yaw), 0)
			-- starts INSIDE the crown, not beside it, so it reads as emerging
			* CFrame.new(0, stemW * 0.30, -stemW * 0.28)
			* CFrame.Angles(math.rad(-splay + curl), 0, 0)
		plate("RootFoot", W * width, W * length, W * thick,
			footCF * CFrame.new(0, W * length * 0.5, 0), sp.Soil, model, i % 2 == 0)
	end

	upright("Stem", stemH, stemW, cf * CFrame.new(0, stemH * 0.5, 0), sp.Stem, model)

	for _, lf in ipairs(DUST_LEAVES) do
		local side, long, wide, up, yaw, roll = lf[1], lf[2], lf[3], lf[4], lf[5], lf[6]
		part({
			name = "Leaf",
			-- X and Z take G; Y is thickness and does not.
			size = Vector3.new(H * long * G, H * 0.055, H * wide * G),
			cframe = cf * CFrame.new(side * H * long * 0.52 * G, stemH * up, 0)
				* CFrame.Angles(0, side * math.rad(yaw), side * math.rad(roll)),
			color = sp.Leaf,
			parent = model,
		})
	end

	--==========================================================================
	-- THE NECK EARNS ITS PLACE TWICE
	--
	-- It hides the join where a head meets a cylinder, which every one of these
	-- species previously left as a hard edge. And in GREYSCALE it is the value
	-- break -- dark olive against a bright head and a mid-tan stem -- that keeps
	-- the two separate when colour is taken away. Raincup's cup blue and the
	-- stem tan land 17 luma apart and meet at exactly this point.
	--==========================================================================
	upright("Neck", W * 0.16, stemW * 2.40, cf * CFrame.new(0, stemH + W * 0.02, 0),
		sp.Leaf, model)
	for i, sd in ipairs(DUST_SEPALS) do
		local yaw, long, wide = sd[1], sd[2], sd[3]
		plate("Sepal", stemW * wide * 2.2, stemW * long * 2.2, stemW * 0.26,
			cf * CFrame.Angles(0, math.rad(yaw), 0)
				* CFrame.new(0, stemH + W * 0.04, -stemW * 0.82)
				* CFrame.Angles(math.rad(-26), 0, 0)
				* CFrame.new(0, stemW * long * 1.1, 0),
			sp.Leaf, model, i % 2 == 0)
	end
end

--==============================================================================
--==============================================================================
-- TANGLEMIRE IS REPLAYED, NOT REASSEMBLED
--
-- Greenhollow and Dustbowl are ASSEMBLED here: a footing helper, a stem, two
-- leaves, then a form branch that measures a head off headW. Tanglemire is not,
-- and the difference is deliberate rather than lazy.
--
-- Its five were designed, reviewed and approved as WHOLE SCULPTURES. Each one
-- already carries its own peat hummock, four clods, moss collar, stem, four wet
-- leaves and a full face, so there is nothing left for a shared footing to
-- contribute. Rebuilding them out of the shared vocabulary would mean
-- re-deriving thirty-odd approved part positions by hand and hoping the result
-- still looked like the thing that was signed off -- which is precisely the
-- redesign the approval existed to end.
--
-- So the geometry is data (TanglemireForms) and this is the player. What it
-- still shares is what actually matters: `Base` is the same invisible pivot the
-- other ten use, so PlantService, PlantSway, CarryService and both prompts
-- cannot tell the difference, and weight still drives size through the same H.
--
-- WHY GIRTH IS DAMPED AND HORIZONTAL HERE
--
-- Two thirds of the approved parts are rotated off-axis. Scaling a rotated box
-- along world X and Z does not widen it, it SHEARS it, so girth cannot be the
-- per-axis multiplier it is in a hand-authored form -- doing that would bend
-- approved art out of shape at exactly the weights players see most.
--
-- Instead each part keeps its approved proportions (size scales by hs alone)
-- and girth SPREADS THE PARTS APART horizontally. That is the same restraint
-- Suncrown already shows, folding girth into a damped `0.85 + 0.15 * gs` rather
-- than multiplying by it raw. Normalised so gs is exactly 1.0 at the size
-- reference weight, which is what makes a median plant the approved mockup
-- rather than the approved mockup within a few percent of itself.
--==============================================================================
local GIRTH_REF = SeedData.Girth(SeedData.BaseTier)
local GIRTH_SPREAD = 0.16

-- Named for the biome that needed it first; it is now the one girth curve all
-- three assembled-form biomes share, so a Colossal is the same amount broader
-- whichever road it came off.
local function girthSpread(G: number): number
	return 1 + GIRTH_SPREAD * (G - GIRTH_REF) / GIRTH_REF
end

local SHAPE_BY_NAME: { [string]: Enum.PartType } = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

--------------------------------------------------------------------------------
-- One approved part, placed. `cf` is the model base, matching every other
-- builder in this file; `hs` conforms the mockup to the shared frame and `gs`
-- is the damped horizontal spread. Rotation is copied through untouched.
--------------------------------------------------------------------------------
local function replayPart(spec: TanglemireForms.PartSpec, cf: CFrame, hs: number,
	gs: number, color: Color3, parent: Instance): BasePart
	local offset = spec.cf.Position
	local placed = cf
		* CFrame.new(offset.X * hs * gs, offset.Y * hs, offset.Z * hs * gs)
		* (spec.cf - offset)

	local p: BasePart
	if spec.shape == "Wedge" then
		p = wedge(spec.name, spec.size * hs, placed, color, parent)
	else
		p = part({
			name = spec.name,
			size = spec.size * hs,
			cframe = placed,
			color = color,
			shape = SHAPE_BY_NAME[spec.shape] or Enum.PartType.Block,
			parent = parent,
		})
	end
	-- Material last and unconditionally: the approved set includes Glass and
	-- Neon, and `part` would otherwise have picked Plastic for the studs.
	p.Material = spec.material
	p.Transparency = spec.transparency or 0
	p.Reflectance = spec.reflectance or 0
	return p
end

function CreatureModel.BuildCreature(sp: SeedData.Species, tier: number, stage: Stage,
	cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Creature_" .. sp.Id
	model:SetAttribute("SpeciesId", sp.Id)
	-- The FORM's drop tier, for anything listing shapes. What this one is worth
	-- is its Kg, and its band is SeedData.RarityForKg.
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Tier", tier)
	model:SetAttribute("Stage", stage)
	model.Parent = parent

	local scale = if stage == CreatureModel.STAGE_SPROUT then SPROUT_SCALE else 1
	-- The species frame, scaled by what this one weighs.
	local H = SeedData.FrameHeight(sp, tier) * scale
	--==========================================================================
	-- TWO SCALARS, NOT ONE. H IS TALLNESS, G IS FATNESS.
	--
	-- Every horizontal dimension used to be a fraction of H, so bulk tracked
	-- HEIGHT and nothing at all tracked WEIGHT -- a 2 kg Nubkin and a 110 kg
	-- Bellchime came out 1.67x apart in width across a 55x weight range, and
	-- the Bellchime was proportionally the slimmer of the two.
	--
	-- G multiplies the width terms only. It is applied in THREE places now --
	-- stem, leaves, headW -- because every other horizontal measurement in the
	-- forms below is already derived from one of them, so they inherit it for
	-- free. The dirt heap comes off the stem width, which already carries it.
	--==========================================================================
	local G = SeedData.Girth(tier)

	local stemW = H * 0.13 * G

	--==========================================================================
	-- THE PIVOT IS A PLATE NOBODY SEES
	--
	-- Everything downstream needs a part at the creature's ground contact and
	-- needs it to be the PrimaryPart: PlantService places by that pivot,
	-- PlantSway leans and walks about it, CarryService welds it low in the
	-- hands, and the Hatch and Pick Up prompts hang off it.
	--
	-- None of that requires it to be VISIBLE, and the old mound was only ever
	-- visible by accident -- it was the pivot and the decoration at once, so
	-- getting rid of the puck meant getting rid of the anchor for four systems.
	-- Splitting them costs one invisible part and settles it.
	--
	-- A BLOCK, NOT A ROLLED CYLINDER, AND THAT IS A FIX. `upright` builds its
	-- cylinders rotated ninety degrees about Z so their length runs up the
	-- world Y -- which meant the model's pivot had its local X pointing at the
	-- sky. Harmless while the plant is in the ground, because PlantSway leans
	-- about a computed upright anchor rather than about the pivot. NOT harmless
	-- when carried: giveTool sets `handle.CFrame = root.CFrame * grip` and
	-- everything else is welded to it, so a rolled handle carried the whole
	-- plant on its side. This is axis-aligned, so a held creature stands up.
	--==========================================================================
	local base = part({
		name = "Base",
		size = Vector3.new(stemW * 1.2, 0.06, stemW * 1.2),
		cframe = cf * CFrame.new(0, 0.03, 0),
		color = sp.Soil,
		parent = model,
		studs = false,
	})
	base.Transparency = 1

	--==========================================================================
	-- EVERY EXIT FROM THIS FUNCTION GOES THROUGH HERE
	--
	-- BuildCreature has three returns and two of them are Tanglemire's, which
	-- answers early because its geometry arrives already assembled. Both of
	-- those sat about nine hundred lines above the two statements that actually
	-- FINISH a creature, so every Tanglemire plant came out with a nil
	-- PrimaryPart -- and the consequence was silent. giveTool reads
	-- `model.PrimaryPart` as its Handle, finds nothing, destroys the model and
	-- returns nil; GiveHatched returns false; hatch returns false. Holding E on
	-- a ripe Tanglemire pod did nothing at all, with no error to go on.
	--
	-- A closure rather than three copies of two lines, because three copies is
	-- how the third one goes missing. The next early return gets this for free.
	--
	-- THE TAG IS STILL LAST. CollectionService listeners fire the moment a tag
	-- lands and none of them can tell a half-built model from a finished one,
	-- so tagging where `base` is born would hand them a plant with no leaves.
	--==========================================================================
	local function finish(): Model
		-- PrimaryPart is the BASE plate: a creature's pivot is where it meets
		-- the soil, so planting one is placing its pivot on the dirt rather
		-- than working out how tall it is first. It is invisible, and
		-- deliberately so -- see the block where it is built.
		model.PrimaryPart = base
		CollectionService:AddTag(model, GameConfig.Tags.Creature)
		return model
	end

	--==========================================================================
	-- TANGLEMIRE ANSWERS HERE AND STOPS
	--
	-- Everything below this point assembles a plant out of a stem, a footing and
	-- a form branch. A Tanglemire plant is already assembled -- see the banner on
	-- replayPart -- so it takes the shared pivot above and nothing else.
	--
	-- Deliberately AFTER `Base` and before the per-biome footing: the pivot is
	-- the one thing four other systems reach for by name, and a biome that
	-- skipped it would be a biome whose plants could not be planted, carried or
	-- swayed.
	--==========================================================================
	if sp.Biome == "tanglemire" then
		local specs = TanglemireForms.Plants[sp.Id]
		if specs then
			local hs = H / TanglemireForms.PreviewHeight[sp.Id]
			local gs = girthSpread(G)
			for _, spec in ipairs(specs) do
				replayPart(spec, cf, hs, gs, spec.color or sp.Body, model)
			end
			-- The one thing the approved geometry does not get to keep: this
			-- biome's eye is a slit, and the shared face builder is never
			-- reached from here to give it one.
			retrofitMireEye(model, sp.Body)
			return finish()
		end
		-- No approved geometry for this id. Falling through would build a
		-- Greenhollow plant in mire colours and call it a Tanglemire species,
		-- which is worse than an empty pivot somebody notices immediately.
		warn(string.format(
			"[Seed/CreatureModel] tanglemire species %q has no approved geometry",
			sp.Id))
		return finish()

	--==========================================================================
	-- EMBERROOT ANSWERS HERE TOO, AND FOR THE SAME REASON
	--
	-- Its five arrive already assembled -- their own cinder pad, root-legs,
	-- stem, limbs, bulb and face -- so everything below this point, which builds
	-- a plant out of a shared stem and a footing, would be building a second
	-- plant inside the first.
	--
	-- One factor per plant, hs = the frame height asked for over the height the
	-- plant was APPROVED at. That is the same trick Tanglemire uses and it
	-- exists for the same reason: the five were drawn at sizes that are correct
	-- RELATIVE TO EACH OTHER, and normalising them individually would flatten
	-- the ladder the approval fixed. Emberquill is 1.73x Cinderpaw and stays
	-- that way at every tier.
	--==========================================================================
	elseif sp.Biome == "emberroot" then
		local authored = EmberrootForms.AuthoredHeight[sp.Id]
		if authored and authored > 0 then
			if EmberrootForms.Build(model, sp.Id, cf, H / authored, girthSpread(G)) then
				return finish()
			end
		end
		-- Same refusal Tanglemire makes: falling through would build a
		-- Greenhollow plant in ember colours and call it an Emberroot species,
		-- which is worse than an empty pivot somebody notices immediately.
		warn(string.format(
			"[Seed/CreatureModel] emberroot species %q has no approved geometry",
			sp.Id))
		return finish()

	elseif sp.Biome == "starbloom" then
		--======================================================================
		-- STARBLOOM ANSWERS HERE TOO, AND ON THE SAME TWO FACTORS
		--
		-- Authored at a fixed height per species and conformed to the tier's
		-- frame by the ratio, exactly as Emberroot does -- and spread by the same
		-- girth curve, so the ladder reads as heavier and not merely as bigger.
		--======================================================================
		local authored = StarbloomForms.AuthoredHeight[sp.Id]
		if authored and authored > 0 then
			if StarbloomForms.Build(model, sp.Id, cf, H / authored, girthSpread(G)) then
				return finish()
			end
		end
		-- The same refusal again. A starbloom species with no builder must not
		-- come out as a Greenhollow plant painted violet.
		warn(string.format(
			"[Seed/CreatureModel] starbloom species %q has no approved geometry",
			sp.Id))
		return finish()
	end

	local stemH = H * 0.417
	local stemBase = 0

	--==========================================================================
	-- THE BODY IS PER-BIOME FROM HERE DOWN
	--
	-- Greenhollow's five stand in a heap of seven soil clods. Dustbowl's five
	-- stand on four broad root feet with nothing shovelled around them -- the
	-- crown, not a plinth, owns the ground silhouette. That is not a style
	-- preference: a ring of clods says "this was planted" where the plant should
	-- say "this grew", and it was the single biggest thing making the two biomes
	-- look like different games.
	--
	-- `Base` is built ABOVE this branch and stays shared. It is the pivot four
	-- systems depend on -- PlantService places by it, PlantSway leans about it,
	-- CarryService welds it low in the hands, both prompts hang off it -- and a
	-- per-biome pivot would be a per-biome bug.
	--==========================================================================
	if sp.Form == "crown" then
		--==================================================================
		-- SUNCROWN BUILDS ITS OWN GROUND, AND THAT IS DELIBERATE
		--
		-- It is the one species that already had real anatomy down here before
		-- the shared footing existed: a central taproot, two rear heels and
		-- THREE COLOURED ROOTS in coral, orange and gold. Handing it four
		-- identical tan feet would delete the thing that makes it the
		-- Legendary, so its form branch does the whole job -- roots, stem,
		-- neck and leaves -- and nothing is built here.
		--
		-- Everything else in the biome shares the footing, which is the point
		-- of the footing. One exception, stated out loud, is not a crack in
		-- the rule.
		--==================================================================
	elseif sp.Biome == "dustbowl" then
		addDustbowlFooting(model, sp, cf, H, G, stemW, stemH)
	else
		--== THE DIRT ==--
		addSoil(model, sp, cf, stemW)

		--==========================================================================
		-- THE STEM STARTS AT THE BED
		--
		-- It used to start at `moundH * 0.7`, sunk three tenths into the puck so it
		-- did not look planted on top of one. With the puck gone that offset would
		-- be a stem hovering a fraction of a stud over the soil, so the base goes
		-- to zero and the stem grows the difference.
		--
		-- 0.417 is not a new number: it is exactly what `moundH * 0.7 + H * 0.34`
		-- came to. The head therefore sits at precisely the height it sat at
		-- before, every finished-height figure on the SeedData sheet still holds,
		-- and the boot report prints the same table. Only the plinth is gone.
		--==========================================================================
		upright("Stem", stemH, stemW, cf * CFrame.new(0, stemBase + stemH * 0.5, 0),
			SeedData.Stem, model)

		--==========================================================================
		-- A LEAF AND A LEAFLET, NOT TWO PROPELLERS
		--
		-- Two blades, one per side, at the same height and the same angle: from
		-- above it was a rotor. A second smaller leaflet higher up the stem and
		-- turned the OTHER way breaks that -- there is no viewpoint left where the
		-- four line up.
		--
		-- Both are still named "Leaf". PlantSway swings every part with that name
		-- as an arm while a plant walks, and works out which side each is on from
		-- its own offset, so a leaflet joins in for free.
		--==========================================================================
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "Leaf",
				-- X and Z are the leaf's length and width and take G; Y is its
				-- thickness and does not.
				size = Vector3.new(H * 0.27 * G, H * 0.05, H * 0.12 * G),
				cframe = cf
					-- 0.51 of a stem that is now 23% longer, which lands the leaves
					-- at the same height above the soil they have always been at --
					-- low, with the heap coming up around them.
					* CFrame.new(side * H * 0.16 * G, stemBase + stemH * 0.51, 0)
					-- Down and out. Level bars read as propellers, which is exactly
					-- what the first build looked like.
					* CFrame.Angles(0, side * math.rad(16), side * math.rad(-13)),
				color = sp.Leaf,
				parent = model,
			})
			part({
				name = "Leaf",
				size = Vector3.new(H * 0.16 * G, H * 0.045, H * 0.08 * G),
				cframe = cf
					* CFrame.new(side * H * 0.105 * G, stemBase + stemH * 0.74, 0)
					-- Swept back and lifted, against the big blade's forward droop.
					* CFrame.Angles(0, side * math.rad(-27), side * math.rad(-34)),
				color = sp.Leaf,
				parent = model,
			})
		end
	end

	--== HEAD ==--
	-- The one that matters: the head, the cap, the bell tiers, the flower, the
	-- spikes, the buds, the fronds and the face are all measured off headW.
	local headW = H * 0.46 * G
	local headCentreY = stemBase + stemH + headW * 0.46
	local headCF = cf * CFrame.new(0, headCentreY, 0)
	local topCF = headCF * CFrame.new(0, headW * 0.5, 0)

	-- WHERE THE FACE GOES IS PER-FORM, and it has to be, because the widest
	-- part of a head is not always the part the face sits on. The bell proved
	-- it: one shared `front` put the smile at local z -0.78 inside a skirt of
	-- radius 0.99, so the creature had eyes and no mouth and nobody could see
	-- why. Each branch sets these three explicitly now.
	local faceCF = headCF
	local faceW = headW
	local front = headW * 0.5

	if sp.Form == "cube" then
		part({ name = "Head", size = Vector3.new(headW, headW, headW),
			cframe = headCF, color = sp.Body, parent = model })
		--==================================================================
		-- BREAK THE BOX
		--
		-- One cube is a die with a face drawn on it. Two things fix that
		-- without stopping it being a cube, which is the whole silhouette:
		--
		--   THE BROW   a bar across the top of the face, standing a little
		--              proud. It gives the eyes something to sit under, and
		--              it is the single part that stops the front reading as
		--              a flat panel.
		--   THE NUBS   two small blocks on the upper corners. From the side
		--              -- which is where a walking plant usually is -- they
		--              are the difference between a box and a head.
		--==================================================================
		part({
			name = "Brow",
			size = Vector3.new(headW * 0.74, headW * 0.11, headW * 0.10),
			cframe = headCF * CFrame.new(0, headW * 0.24, -headW * 0.49),
			color = sp.Crown,
			parent = model,
		})
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "Nub",
				size = Vector3.new(headW * 0.16, headW * 0.18, headW * 0.16),
				cframe = headCF
					* CFrame.new(side * headW * 0.46, headW * 0.40, 0)
					* CFrame.Angles(0, 0, side * math.rad(14)),
				color = sp.Body,
				parent = model,
			})
		end
		--==================================================================
		-- A SPROUT, BECAUSE THE CUBE HAD NOTHING
		--
		-- Every other form carries something on its head -- a flower, spikes,
		-- a cap, buds -- and reads as a plant because of it. The cube was a
		-- green box with a face, and its Crown and Accent colours were the
		-- only two fields on the sheet that nothing anywhere used.
		--
		-- Two small leaves and a pale tip. Deliberately tiny: a Nubkin is the
		-- Common, it is often the smallest thing in the bed, and giving it a
		-- crown to rival a Bellchime's would be a lie about what it is worth.
		--==================================================================
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "Sprout",
				size = Vector3.new(headW * 0.30, headW * 0.09, headW * 0.17),
				cframe = topCF
					* CFrame.new(side * headW * 0.15, headW * 0.05, 0)
					* CFrame.Angles(0, side * math.rad(22), side * math.rad(-30)),
				color = sp.Crown,
				parent = model,
			})
		end
		ball("SproutTip", headW * 0.13, topCF * CFrame.new(0, headW * 0.10, 0),
			sp.Accent, model)

	elseif sp.Form == "orb" then
		ball("Head", headW, headCF, sp.Body, model)
		front = headW * 0.46
		addFlower(model, sp, topCF * CFrame.new(0, headW * 0.06, 0), headW)

	elseif sp.Form == "teardrop" then
		ball("Head", headW, headCF, sp.Body, model)
		front = headW * 0.46
		-- Two mirrored wedges make a point from the front rather than a roof.
		for _, side in ipairs({ -1, 1 }) do
			wedge("HeadPoint", Vector3.new(headW * 0.5, headW * 0.52, headW * 0.5),
				headCF * CFrame.new(side * headW * 0.25, headW * 0.44, 0)
					* CFrame.Angles(0, side > 0 and 0 or math.pi, 0),
				sp.Body, model)
		end
		-- A banded collar where the head meets the stem. Without it the
		-- teardrop is a balloon with sticks in the top and nothing explaining
		-- where it joins the plant.
		upright("Collar", headW * 0.13, headW * 0.62,
			headCF * CFrame.new(0, -headW * 0.42, 0), sp.Crown, model)
		addSpikes(model, sp, topCF * CFrame.new(0, headW * 0.38, 0), headW, H)

	elseif sp.Form == "mushroom" then
		ball("Head", headW * 0.86, headCF, sp.Body, model)
		faceW = headW * 0.86
		front = headW * 0.42
		local capY = headW * 0.42
		--==================================================================
		-- GILLS
		--
		-- The underside of the cap was a flat disc in the same red as the top,
		-- so from anywhere below eye level -- which is most of the time, since
		-- these are on the ground -- a Toadcap was a red plate on a stalk. Six
		-- pale radial blocks set just under the rim give it an inside.
		--
		-- Under the disc rather than inside it, and pale rather than red, so
		-- the two faces of the cap read as two different things.
		--==================================================================
		for i = 1, 4 do
			part({
				name = "Gill",
				-- A bar through the centre covers BOTH sides, so four of them at
				-- 45 degree steps give eight spokes. Long enough to reach 0.52
				-- of the way out against the cap's own 0.66 radius -- they stop
				-- just inside the rim rather than poking past it.
				size = Vector3.new(headW * 0.08, headW * 0.10, headW * 1.05),
				cframe = headCF
					* CFrame.new(0, capY - headW * 0.10, 0)
					* CFrame.Angles(0, (i - 1) / 4 * math.pi, 0),
				color = sp.Accent,
				parent = model,
				studs = false,
			})
		end
		upright("CapDisc", headW * 0.16, headW * 1.32,
			headCF * CFrame.new(0, capY, 0), sp.Crown, model)
		ball("CapDome", headW * 1.10, headCF * CFrame.new(0, capY + headW * 0.10, 0),
			sp.Crown, model)
		-- Spots, set into the dome's upper face.
		for i = 1, 4 do
			local a = (i - 1) / 4 * math.pi * 2
			upright("Spot", headW * 0.05, headW * 0.24,
				headCF * CFrame.Angles(0, a, 0)
					* CFrame.new(0, capY + headW * 0.36, -headW * 0.40),
				sp.Accent, model)
		end
		addFronds(model, sp, headCF * CFrame.new(0, capY + headW * 0.44, 0), headW)

	--==========================================================================
	-- DUSTBOWL FORMS
	--
	-- Ported from the approved Studio previews. Every one of them was authored
	-- against `W = H * 0.46 * G` with a head centre at `stemH + W * 0.46` --
	-- which are headW and headCentreY here, the same two numbers -- so the
	-- shapes transfer without re-proportioning.
	--
	-- Each branch sets faceCF / faceW / front and stops. addFace below builds
	-- the same nine parts for all ten species: the previews copied its
	-- arithmetic verbatim, so there is nothing per-form left to do.
	--==========================================================================
	elseif sp.Form == "husk" then
		--==================================================================
		-- DUNEBUD: a sealed bud with ONE plate peeled down at the front
		--
		-- The brief ruled out "a plain ball or an egg", and a cream sphere in
		-- a rust collar IS an egg in a cape -- so the husk closes OVER the top
		-- and the face is recessed inside it. The plant is not wearing the
		-- husk, it is looking out of it.
		--
		-- The whole head is canted: six degrees into the wind and five of
		-- roll. That tilt is why it reads as weathered rather than placed.
		--==================================================================
		local hCF = headCF * CFrame.Angles(math.rad(-6), 0, math.rad(5))
		local function plateCF(yawDeg: number, out: number, baseYOff: number,
			length: number, tiltDeg: number): CFrame
			return hCF
				* CFrame.Angles(0, math.rad(yawDeg), 0)
				-- yaw 0 is the FRONT (-Z)
				* CFrame.new(0, baseYOff, -out)
				-- tip the top OUTWARD
				* CFrame.Angles(math.rad(-tiltDeg), 0, 0)
				-- a wedge's origin is its middle, not its root
				* CFrame.new(0, length * 0.5, 0)
		end

		upright("Collar", headW * 0.16, headW * 0.82,
			hCF * CFrame.new(0, -headW * 0.46, 0), sp.Crown, model)
		local budD = headW * 0.62
		ball("Bud", budD, hCF * CFrame.new(0, -headW * 0.02, 0), sp.Body, model)

		-- The low pair either side of the face SET THE WINDOW; the upper pair
		-- turn IN and meet at the knot over the bud. At 132 degrees with
		-- outward tilt they rose off the back of the head like two horns and
		-- did nothing for the bud. At 112, tilted 20 inward, their tips land
		-- just over the bud's crown -- a husk closing, not a pair of ears.
		for _, side in ipairs({ 1, -1 }) do
			plate("HuskLow", headW * 0.52, headW * 0.76, headW * 0.15,
				plateCF(side * 78, headW * 0.31, -headW * 0.50, headW * 0.76, 8),
				sp.Crown, model, side > 0)
			plate("HuskUp", headW * 0.50, headW * 0.62, headW * 0.15,
				plateCF(side * 112, headW * 0.37, -headW * 0.28, headW * 0.62, -20),
				sp.Crown, model, side > 0)
		end
		plate("HuskBack", headW * 0.56, headW * 0.72, headW * 0.15,
			plateCF(180, headW * 0.26, -headW * 0.48, headW * 0.72, 6),
			sp.Crown, model, false)

		-- A BLOCK, not a wedge. A wedge's taper is a RIGHT triangle: fine on a
		-- mirrored pair, wrong on a single plate dead centre, where it read as
		-- a sash tied across the mouth.
		part({
			name = "Peel",
			size = Vector3.new(headW * 0.50, headW * 0.36, headW * 0.12),
			cframe = plateCF(0, headW * 0.24, -headW * 0.54, headW * 0.36, 26),
			color = sp.Crown,
			parent = model,
		})
		ball("Knot", headW * 0.22, hCF * CFrame.new(0, headW * 0.22, 0),
			sp.Accent, model)

		faceW = headW * 0.54
		front = budD * 0.5
		faceCF = hCF
		-- The single part that stops the front reading as a flat panel: it
		-- gives the eyes something to sit under.
		part({
			name = "Brow",
			size = Vector3.new(headW * 0.42, headW * 0.10, headW * 0.12),
			cframe = hCF * CFrame.new(0, faceW * 0.30, -front * 0.74)
				* CFrame.Angles(math.rad(-16), 0, 0),
			color = sp.Crown,
			parent = model,
		})

	elseif sp.Form == "pad" then
		--==================================================================
		-- PADDLEHOP: a flat prickly-pear pad, three buds, one bloom
		--
		-- ONE RULE makes the beige legible rather than stripey: every rounded
		-- RIM is the dark olive, on the main pad and all three buds alike. The
		-- eye reads "edge" once and then reads it everywhere. Before that,
		-- core, edges and buds were one colour and three overlapping pads read
		-- as one lumpy mass -- cardboard, not a plant.
		--
		-- The bloom is the most saturated thing in the biome and it is one
		-- part the size of a thumbnail. Deliberate: a desaturated flower would
		-- read as background scenery.
		--==================================================================
		local padW, padH, padD = headW * 0.84, headW * 0.98, headW * 0.38
		part({
			name = "PadCore",
			size = Vector3.new(padW * 0.94, padH, padD),
			cframe = headCF, color = sp.Body, parent = model,
		})
		coin("PadEdge", padW, padD * 0.34, headCF * CFrame.new(0, padH * 0.5, 0),
			sp.Crown, model)
		coin("PadEdge", padW, padD * 0.28, headCF * CFrame.new(0, -padH * 0.5, 0),
			sp.Crown, model)

		-- Three buds, no two alike in size, lean, height or depth.
		local PADS = {
			-- sign, out, up, roll, blockH, wide, deep, z, yaw
			{ -1, 0.42, 0.18, 17, 0.68, 0.60, 0.26, 0.42, 0 },
			{ 1, 0.56, -0.16, 44, 0.16, 0.48, 0.22, 0.86, 62 },
			{ -1, 0.38, -0.44, 58, 0.14, 0.40, 0.14, -0.74, 38 },
		}
		local firstTip = headCF
		for i, d in ipairs(PADS) do
			local sign, out, up, roll = d[1], d[2], d[3], d[4]
			local blockH, wide, deep, z, yaw = d[5], d[6], d[7], d[8], d[9]
			local rootCF = headCF
				* CFrame.new(sign * headW * out, headW * up, padD * z)
				* CFrame.Angles(0, math.rad(sign * yaw), 0)
				* CFrame.Angles(0, 0, math.rad(-sign * roll))
			part({
				name = "PadBud",
				size = Vector3.new(headW * wide * 0.94, headW * blockH, headW * deep),
				cframe = rootCF * CFrame.new(0, headW * blockH * 0.5, 0),
				color = sp.Body:Lerp(sp.Crown, 0.32), parent = model,
			})
			local tipCF = rootCF * CFrame.new(0, headW * blockH, 0)
			coin("PadEdge", headW * wide, headW * deep * 0.55, tipCF, sp.Crown, model)
			if i == 1 then
				firstTip = tipCF * CFrame.new(0, headW * wide * 0.5, 0)
			end
		end

		local pale = sp.Accent:Lerp(WHITE, 0.62)
		coin("Bract", headW * 0.30, headW * 0.07,
			firstTip * CFrame.new(0, headW * 0.10, 0), pale, model)
		ball("Bloom", headW * 0.24, firstTip * CFrame.new(0, headW * 0.14, 0),
			sp.Accent, model)
		ball("Glow", headW * 0.09,
			firstTip * CFrame.new(-headW * 0.09, headW * 0.02, -headW * 0.06),
			pale, model)

		-- Four surface marks on the pad face. Smooth, because they are
		-- markings ON the pad rather than lumps of it.
		local frontZ = -padD * 0.5
		local DETAIL = {
			{ "Rib", 0.05, 0.46, 0.160, -0.26, 0.20, 9 },
			{ "Areole", 0.11, 0.08, 0.130, 0.22, 0.14, 0 },
			{ "Areole", 0.08, 0.06, 0.100, -0.30, -0.10, 0 },
			{ "Scar", 0.22, 0.05, 0.070, 0.30, 0.40, -21 },
		}
		for _, d in ipairs(DETAIL) do
			part({
				name = d[1] :: string,
				size = Vector3.new(headW * (d[2] :: number), headW * (d[3] :: number),
					headW * (d[4] :: number)),
				cframe = headCF
					* CFrame.new(padW * (d[5] :: number), padH * (d[6] :: number), frontZ)
					* CFrame.Angles(0, 0, math.rad(d[7] :: number)),
				color = sp.Crown, parent = model, studs = false,
			})
		end

		faceW = headW * 0.70
		front = padD * 0.5

	elseif sp.Form == "whorl" then
		--==================================================================
		-- THORNWHORL: five weathered blades spiralling off a bone core
		--
		-- The 26 degrees of shared twist about each blade's own length is what
		-- makes the ring a SPIRAL rather than a gear. Without it, five plates
		-- at even angles is a hub with spokes.
		--
		-- Two of the five are pulled darker and flatter so the whorl has depth
		-- instead of five identical boards, and `up` spans -0.14 to +0.26 so
		-- the SIDE view gets separated layers rather than one dense stack of
		-- boards at eye level.
		--==================================================================
		upright("Collar", headW * 0.15, headW * 0.94,
			headCF * CFrame.new(0, -headW * 0.30, 0), sp.Crown, model)
		local coreD = headW * 0.74
		ball("CoreBody", coreD, headCF, sp.Body, model)

		local BLADES = {
			-- yaw, out, up, back, splay, length, width, hook, dark
			{ 85, 0.40, -0.14, 0.02, 88, 0.62, 0.80, 34, false },
			{ 130, 0.38, 0.16, 0.02, 78, 0.56, 0.78, 30, true },
			{ 180, 0.36, -0.04, 0.02, 92, 0.66, 0.90, 38, false },
			{ 230, 0.42, 0.26, 0.02, 46, 0.98, 0.96, 26, false },
			{ 275, 0.42, 0.06, 0.02, 84, 0.52, 0.74, 36, true },
		}
		local bladeDark = sp.Crown:Lerp(Color3.new(0, 0, 0), 0.16)
		for i, b in ipairs(BLADES) do
			local yaw, out, up, back = b[1] :: number, b[2] :: number,
				b[3] :: number, b[4] :: number
			local splay, length = b[5] :: number, b[6] :: number
			local width, hook = b[7] :: number, b[8] :: number
			local rootCF = headCF
				* CFrame.Angles(0, math.rad(yaw), 0)
				* CFrame.new(0, headW * up, headW * back - headW * out)
				-- lean out from vertical
				* CFrame.Angles(math.rad(-splay), 0, 0)
				-- THE SPIRAL
				* CFrame.Angles(0, 0, math.rad(26))
			-- Hoisted rather than inlined as an expression-if: two of the five
			-- blades are the darker tone, and the choice reads better named.
			local plateColour = if b[9] then bladeDark else sp.Crown
			plate("Plate", headW * width, headW * length, headW * 0.15,
				rootCF * CFrame.new(0, headW * length * 0.5, 0),
				plateColour, model, i % 2 == 0)
			-- Pale ochre, barely above the plate it grows out of, which is what
			-- makes it read as GROWN rather than as a cap screwed on the end.
			plate("Hook", headW * width * 0.34, headW * length * 0.22, headW * 0.15,
				rootCF * CFrame.new(0, headW * length * 0.94, 0)
					* CFrame.Angles(math.rad(hook), 0, 0),
				sp.Accent, model, i % 2 == 0)
		end

		local crownCF = headCF * CFrame.new(0, headW * 0.34, headW * 0.04)
			* CFrame.Angles(math.rad(-16), math.rad(20), 0)
		plate("Spur", headW * 0.34, headW * 0.62, headW * 0.13,
			crownCF * CFrame.new(0, headW * 0.31, 0), sp.Crown, model, false)
		plate("SpurTip", headW * 0.22, headW * 0.22, headW * 0.13,
			crownCF * CFrame.new(0, headW * 0.58, 0) * CFrame.Angles(math.rad(52), 0, 0),
			sp.Accent, model, false)

		faceW = headW * 0.66
		front = coreD * 0.5

	elseif sp.Form == "cup" then
		--==================================================================
		-- RAINCUP: a stepped goblet, and the steps are the whole point
		--
		-- A Roblox Cylinder seen side-on is a plain RECTANGLE. One wide disc
		-- read as a cup only from directly overhead; from the front -- the
		-- angle a player actually has -- it was a blue box with two horns.
		-- Three discs widening upward, 0.52 -> 0.92 -> 1.26, carry the
		-- silhouette because the STEPS do; each disc alone is a rectangle.
		--
		-- The yellow floor is FLUSH with the rim and never sunk below it. The
		-- engine has no hollow cylinder, so a floor "recessed" inside a solid
		-- rim is simply buried, and the focal colour of the whole model
		-- disappears from every angle including from above.
		--==================================================================
		upright("CupFoot", headW * 0.20, headW * 0.52,
			headCF * CFrame.new(0, -headW * 0.34, 0),
			sp.Body:Lerp(Color3.new(0, 0, 0), 0.28), model)
		upright("CupWall", headW * 0.26, headW * 0.92,
			headCF * CFrame.new(0, -headW * 0.13, 0), sp.Body, model)
		upright("CupRim", headW * 0.34, headW * 1.26,
			headCF * CFrame.new(0, headW * 0.09, 0), sp.Body, model)
		upright("CupInner", headW * 0.12, headW * 0.72,
			headCF * CFrame.new(0, headW * 0.22, 0), sp.Crown, model)
		ball("CupCore", headW * 0.24, headCF * CFrame.new(0, headW * 0.30, 0),
			sp.Crown, model)

		-- Five lobes, ONE plate each. The first design spent fifteen parts on
		-- five petals x (outer + liner + rim bar) -- three concentric rings of
		-- five, which is a gear. They root at 0.52-0.56, inside the rim's 0.63
		-- edge, so they rise FROM the rim and continue its flare.
		local LOBES = {
			-- yaw, out, splay, length, width
			{ 50, 0.54, 20, 0.80, 0.80 },   -- the long one, and the most upright
			{ 116, 0.52, 16, 0.74, 0.74 },
			{ 192, 0.54, 24, 0.74, 0.76 },
			{ 264, 0.52, 18, 0.76, 0.72 },
			{ 322, 0.56, 44, 0.42, 0.68 },  -- lower, partly folded, widest reach
		}
		local ribColour = sp.Body:Lerp(Color3.new(0, 0, 0), 0.34)
		for i, d in ipairs(LOBES) do
			local yaw, out = d[1] :: number, d[2] :: number
			local splay, length, width = d[3] :: number, d[4] :: number, d[5] :: number
			local L = headW * length * (0.92 + 0.10 * G)
			local rootCF = headCF
				* CFrame.Angles(0, math.rad(yaw), 0)
				* CFrame.new(0, headW * 0.20, -headW * out)
				* CFrame.Angles(math.rad(-splay), 0, 0)
			plate("Lobe", headW * width, L, headW * 0.20,
				rootCF * CFrame.new(0, L * 0.5, 0), sp.Body, model, i % 2 == 0)
			-- The rib PASSES THROUGH: 0.28 against the lobe's 0.20, so it stands
			-- proud on BOTH faces and details the inner ones too. On the outer
			-- face only it detailed the half of the crown facing away.
			--
			-- Darker than the lobe, never brighter. A bright vein out-values the
			-- core and steals the focal point the hierarchy is built around.
			part({
				name = "LobeRib",
				size = Vector3.new(headW * width * 0.16, L * 0.72, headW * 0.28),
				cframe = rootCF * CFrame.new(0, L * 0.40, 0),
				color = ribColour, parent = model,
			})
			-- The throat of TWO lobes only. A wedge, not a block: as a rectangle
			-- its corners hung past the tapering edges of the lobe it was meant
			-- to be colouring, and it read as a pink card standing in the cup.
			if i == 1 or i == 3 then
				plate("LobeBlush", headW * width * 0.70, L * 0.34, headW * 0.06,
					rootCF * CFrame.new(0, L * 0.19, headW * 0.085),
					sp.Accent, model, i % 2 == 0)
			end
		end

		-- The caught drop. OPAQUE -- Roblox sorts transparency per part and the
		-- bead is not allowed to be a second transparent layer -- and floored in
		-- size so it is still visible at 1 kg, where the whole plant is about
		-- two and a half studs tall.
		local beadD = math.max(headW * 0.24 * (0.86 + 0.14 * G), 0.34)
		local beadCF = headCF
			* CFrame.new(-headW * 0.26, headW * 0.17 + beadD * 0.5, headW * 0.04)
		ball("Bead", beadD, beadCF, Color3.fromRGB(74, 172, 246), model, false)
		ball("BeadGlint", beadD * 0.36,
			beadCF * CFrame.new(-beadD * 0.26, beadD * 0.30, -beadD * 0.24),
			Color3.fromRGB(206, 236, 248), model, false)

		faceW = headW * 0.60
		-- On the RIM, the widest step. On the wall below it the rim ledge
		-- overhung the face and dropped it into a shadow unreadable at distance.
		front = headW * 1.26 * 0.5
		faceCF = headCF * CFrame.new(0, headW * 0.09, 0)

	elseif sp.Form == "crown" then
		--==================================================================
		-- SUNCROWN: a nine-ray sun on a face disc
		--
		-- The only head in either biome that is RADIAL on purpose, so the usual
		-- warning against a ring of identical parts does not apply -- but the
		-- rays still earn it: three lengths, three widths, three colours, and
		-- only three of the nine carry a crimson accent.
		--
		-- IT ALSO BUILDS ITS OWN FOOTING, and that is why this branch is longer
		-- than the other four. Suncrown is the one species that already had real
		-- anatomy at the ground -- a central taproot, two rear heels and THREE
		-- COLOURED ROOTS -- before the shared footing existed. Handing it four
		-- identical tan feet would delete the thing that makes it the Legendary,
		-- so `addDustbowlFooting` is skipped for this form and the roots below
		-- stand in for it.
		--
		-- IT WAS AUTHORED ON ITS OWN SIZE CURVE, (kg/110)^0.18, where
		-- heightScale is 1.0 at 110 kg. headW on the sheet's shared curve is
		-- 4.2306 studs at that same weight, so ONE factor carries the approved
		-- proportions onto the shared frame and nothing else here has to know
		-- the preview used different maths. Conforming it is what keeps "a
		-- Dunebud stays shorter than a Suncrown at every weight" true: two
		-- curves crossing would break that at one end or the other.
		--==================================================================
		local hs = (headW / 4.2306) * 0.95
		local gs = math.clamp(G, 0.68, 2.60)
		local ws = hs * (1.14 + 0.16 * gs)
		local ds = hs * (0.85 + 0.15 * gs)
		local sunStemH = 2.30 * hs
		local sunStemD = 1.02 * ds
		local faceD = 2.90 * hs * (0.88 + 0.12 * gs)
		local faceThick = 0.72 * ds

		-- A plate lying flat on the GROUND, splayed along a compass bearing.
		-- fromMatrix, not lookAt: this states RightVector / UpVector directly,
		-- which is what a tangent frame needs.
		local function groundCF(pos: Vector3, radial: Vector3, roll: number): CFrame
			local tangent = Vector3.yAxis:Cross(radial).Unit
			return CFrame.fromMatrix(pos, Vector3.yAxis, radial.Unit, tangent)
				* CFrame.Angles(0, 0, math.rad(roll))
		end
		-- The same idea stood upright against the crown disc.
		local function crownCF(pos: Vector3, radial: Vector3): CFrame
			local tangent = Vector3.new(-radial.Y, radial.X, 0).Unit
			return CFrame.fromMatrix(pos, Vector3.zAxis, radial.Unit, tangent)
		end
		local origin = cf.Position

		--== THE TAPROOT AND FIVE SPREADING ROOTS ==--
		local tapH = 0.82 * hs
		wedge("CentralTaproot",
			Vector3.new(0.95 * ws, tapH, 1.00 * ds),
			cf * CFrame.new(0, tapH * 0.47, -0.03 * ds), sp.Soil, model)
		for _, d in ipairs({
			-- name, bearing, length, width, colour, roll
			{ "RearHeelL", 38, 2.18, 0.86, sp.Soil, 3 },
			{ "RearHeelR", 322, 2.18, 0.86, sp.Soil, -3 },
			{ "FrontCoral", 144, 1.86, 0.72, sp.Accent, 4 },
			{ "FrontOrange", 180, 2.12, 0.75, sp.Crown, 0 },
			{ "FrontGold", 216, 1.86, 0.72, sp.Body, -4 },
		}) do
			local angle = math.rad(d[2] :: number)
			local radial = Vector3.new(math.sin(angle), 0, math.cos(angle))
			local len = (d[3] :: number) * ws
			local wid = (d[4] :: number) * ds
			local rootH = 0.40 * hs
			local pos = origin + radial * (len * 0.43) + Vector3.new(0, rootH * 0.47, 0)
			wedge(d[1] :: string, Vector3.new(rootH, len, wid),
				groundCF(pos, radial, d[6] :: number), d[5] :: Color3, model)
		end

		--== STEM AND NECK ==--
		upright("Stem", sunStemH, sunStemD,
			cf * CFrame.new(0, sunStemH * 0.50, 0.05 * ds), sp.Stem, model)
		upright("Neck", sunStemH * 0.12, sunStemD * 2.35,
			cf * CFrame.new(0, sunStemH * 0.90, 0.05 * ds), sp.Leaf, model)

		--==================================================================
		-- FOUR SUPPORT LEAVES, AND THEY ARE NAMED "Leaf" ON PURPOSE
		--
		-- The preview called them SupportLeaf1-4. PlantSway swings every part
		-- named "Leaf" as an arm while a plant walks and works out which side
		-- each is on from its own X offset -- and it finds them with
		-- GetChildren(), direct children only. Under the preview's name they
		-- would simply never move. Two point one way and two the other, so they
		-- swing in opposition exactly as Greenhollow's four do.
		--==================================================================
		local leafSocketY = sunStemH * 0.60
		for _, d in ipairs({
			{ 58, 1.82, 0.74, 10, 1 },
			{ 126, 1.94, 0.78, 13, -1 },
			{ 234, 1.90, 0.76, -12, 1 },
			{ 302, 1.78, 0.72, -9, -1 },
		}) do
			local angle = math.rad(d[1] :: number)
			local radial = Vector3.new(math.sin(angle), 0, math.cos(angle))
			local len = (d[2] :: number) * ws
			local wid = (d[3] :: number) * ds
			local thick = 0.23 * hs
			-- Two tiers, a third of a thickness apart, so overlapping leaves
			-- never share a plane -- two coincident faces sliding against each
			-- other is exactly what flickers.
			local tierY = thick * 0.30 * (d[5] :: number)
			local pos = origin
				+ Vector3.new(0, leafSocketY + tierY, 0)
				+ radial * (sunStemD * 0.34 + len * 0.40)
			wedge("Leaf", Vector3.new(thick, len, wid),
				groundCF(pos, radial, d[4] :: number), sp.Leaf, model)
		end

		--== THE FACE DISC: five rows, widening to the middle ==--
		local faceCentre = cf * CFrame.new(0, sunStemH + faceD * 0.48, 0)
		for i, r in ipairs({
			{ 0.58, 0.40 }, { 0.86, 0.20 }, { 1.00, 0.00 },
			{ 0.86, -0.20 }, { 0.58, -0.40 },
		}) do
			part({
				name = if i == 3 then "FaceCore" else "FaceRow",
				size = Vector3.new(faceD * (r[1] :: number), faceD * 0.203, faceThick),
				cframe = faceCentre * CFrame.new(0, faceD * (r[2] :: number), 0),
				color = sp.Body, parent = model,
			})
		end
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "FaceNotch",
				size = Vector3.new(faceD * 0.11, faceD * 0.30, faceThick * 0.62),
				cframe = faceCentre * CFrame.new(side * faceD * 0.44, 0, -faceThick * 0.32),
				color = sp.Crown, parent = model,
			})
		end
		local backThick = faceThick * 0.80
		for _, r in ipairs({ { 0.74, 0.203 }, { 0.90, 0.0 }, { 0.74, -0.203 } }) do
			part({
				name = "FaceBack",
				size = Vector3.new(faceD * (r[1] :: number), faceD * 0.203, backThick),
				cframe = faceCentre
					* CFrame.new(0, faceD * (r[2] :: number),
						faceThick * 0.20 + backThick * 0.50),
				color = sp.Crown, parent = model,
			})
		end

		--== NINE RAYS ==--
		-- Wings are longest and widest and sit outermost; the peak is the
		-- crimson one dead centre; the two inner pairs are short fillers that
		-- close the gaps without competing for the eye.
		local CRIMSON = Color3.fromRGB(142, 42, 48)
		local FILLER = sp.Body:Lerp(sp.Crown, 0.5)
		local wings: { CFrame } = {}
		for _, d in ipairs({
			-- bearing, length, width, colour, accent, principal
			{ -84, 3.70, 1.28, sp.Accent, false, true },
			{ -58, 3.20, 1.44, sp.Body, false, true },
			{ -34, 3.40, 1.27, sp.Crown, true, true },
			{ -18, 2.05, 0.86, FILLER, false, false },
			{ 0, 3.90, 1.43, CRIMSON, true, true },
			{ 18, 2.05, 0.86, FILLER, false, false },
			{ 34, 3.40, 1.27, sp.Crown, true, true },
			{ 58, 3.20, 1.44, sp.Body, false, true },
			{ 84, 3.70, 1.28, sp.Accent, false, true },
		}) do
			local bearing = d[1] :: number
			local principal = d[6] :: boolean
			local angle = math.rad(bearing)
			local radial = Vector3.new(math.sin(angle), math.cos(angle), 0)
			local len = (d[2] :: number) * (if principal then ws else hs)
			local wid = (d[3] :: number) * ds
			local thick = (if principal then 0.34 else 0.27) * ds
			-- Principals sit a layer proud, so the fillers read as BEHIND them
			-- rather than as part of one flat ring.
			local layer = if principal then 0.65 else 0.48
			local rootPos = (faceCentre * CFrame.new(0, faceD * 0.06, 0)).Position
				+ radial * (faceD * (if principal then 0.35 else 0.30))
				+ Vector3.new(0, 0, faceThick * layer)
			-- A bar plus a round cap, and the bar gives up exactly the cap's
			-- radius, so overall ray length is unchanged by the cap.
			local capR = wid * 0.5
			local plateCF = crownCF(rootPos + radial * (len * 0.44), radial)
			part({
				name = "Ray",
				size = Vector3.new(thick, len - capR, wid),
				cframe = plateCF * CFrame.new(0, -capR * 0.5, 0),
				color = d[4] :: Color3, parent = model,
			})
			part({
				name = "RayTip",
				size = Vector3.new(thick * 0.78, wid, wid),
				cframe = plateCF * CFrame.new(0, (len - capR) * 0.5 - capR * 0.5, 0),
				color = d[4] :: Color3, shape = Enum.PartType.Cylinder, parent = model,
			})
			if d[5] then
				local at = math.max(0.05, thick * 0.26)
				part({
					name = "RayAccent",
					size = Vector3.new(at, len * 0.56, wid * 0.24),
					cframe = plateCF * CFrame.new(
						-(thick + at) * 0.50 - math.max(0.04, 0.05 * ds),
						-len * 0.04, 0),
					color = CRIMSON, parent = model,
				})
			end
			if bearing == -84 or bearing == 84 then
				table.insert(wings, crownCF(rootPos + radial * (len * 0.70), radial))
			end
		end

		--==================================================================
		-- FOUR PENDANTS, TWO PER WING
		--
		-- RIGID IN GAME. They swung on four independent phases in the preview
		-- and that motion does not survive integration: PlantSway moves a whole
		-- plant with ONE PivotTo and swings the leaves, and nothing else. The
		-- geometry is kept because it is approved and it is most of what makes
		-- the wings read as loaded rather than bare.
		--==================================================================
		for _, w in ipairs(wings) do
			for _, drop in ipairs({ -0.10, 0.18 }) do
				local top = w * CFrame.new(0, drop * faceD, 0)
				local rodL = 0.62 * hs
				local rodD = math.max(0.06, 0.095 * ds)
				local beadD = 0.42 * hs * (0.92 + 0.08 * gs)
				upright("PendantRod", rodL, rodD,
					top * CFrame.new(0, -rodL * 0.5, 0), sp.Body, model)
				local beadCF = top * CFrame.new(0, -rodL - beadD * 0.10, 0)
				ball("SunCore", beadD, beadCF, sp.Body, model)
				local barL, barT = beadD * 1.45, math.max(0.06, beadD * 0.23)
				part({ name = "SunRay", size = Vector3.new(barL, barT, barT),
					cframe = beadCF, color = sp.Body, parent = model })
				part({ name = "SunRay", size = Vector3.new(barT, barL, barT),
					cframe = beadCF, color = sp.Body, parent = model })
			end
		end

		--== THE COLLAR: five cool blocks under the face ==--
		-- The only cool note on a creature that is otherwise entirely hot, and
		-- what stops the gold reading as one flat mass.
		local CYAN = Color3.fromRGB(36, 183, 207)
		local BLUE = Color3.fromRGB(30, 91, 180)
		for i, d in ipairs({
			{ -0.38, 18, CYAN }, { -0.19, 9, BLUE }, { 0.00, 0, CYAN },
			{ 0.19, -9, BLUE }, { 0.38, -18, CYAN },
		}) do
			local px = (d[1] :: number) * faceD
			-- Arched: the middle block rides highest, so the row reads as a
			-- collar rather than as a straight bar of five.
			local arch = (1 - math.abs(d[1] :: number) / 0.38) * faceD * 0.035
			part({
				name = "Collar" .. i,
				size = Vector3.new(faceD * 0.235, faceD * 0.19, faceThick * 0.40),
				cframe = faceCentre
					* CFrame.new(px, -faceD * 0.46 - arch, -faceThick * 0.56)
					* CFrame.Angles(0, 0, math.rad(d[2] :: number)),
				color = d[3] :: Color3, parent = model,
			})
		end

		faceW = faceD
		front = faceThick * 0.5
		faceCF = faceCentre

	else -- "bell"
		-- A cone by staircase. Four tiers rather than three, and a wider spread
		-- top to bottom: at 0.62-to-1.08 the flare was too slight to read as a
		-- skirt and the whole thing looked like a lump.
		-- A fifth step at the hem, wider and shallower than the rest: the
		-- skirt now finishes on a RIDGE rather than just stopping, which is
		-- what the sheet's flared lip does.
		local tiers = {
			{ 0.50, 0.40 }, { 0.74, 0.16 }, { 1.00, -0.08 },
			{ 1.20, -0.30 }, { 1.32, -0.44 },
		}
		for _, t in ipairs(tiers) do
			local d: number, dy: number = t[1], t[2]
			upright("BellTier", headW * 0.28, headW * d,
				headCF * CFrame.new(0, dy * headW, 0), sp.Body, model)
		end
		--==================================================================
		-- A SCALLOPED COLLAR, NOT A NAPKIN RING
		--
		-- This was one plain cylinder in the Accent green. The sheet has a ring
		-- of overlapping PINK petals where the skirt meets the stem -- the
		-- single most recognisable thing about a Bellchime after its shape --
		-- and a smooth ring threw all of it away.
		--
		-- Five blocks round the rim, alternating slightly in size so the
		-- outline scallops instead of stepping evenly. Crown, not Accent: on
		-- the sheet the collar and the bud tips are the same pink and the
		-- stalks between them are the green.
		--==================================================================
		for i = 1, 5 do
			local big = (i % 2 == 0)
			local petal = headW * (if big then 0.34 else 0.28)
			part({
				name = "CollarPetal",
				size = Vector3.new(petal, headW * 0.13, petal * 0.72),
				cframe = headCF
					* CFrame.new(0, headW * 0.54, 0)
					* CFrame.Angles(0, (i - 1) / 5 * math.pi * 2, 0)
					* CFrame.new(0, 0, -headW * 0.29)
					* CFrame.Angles(math.rad(-14), 0, 0),
				color = sp.Crown,
				parent = model,
				studs = false,
			})
		end
		addBuds(model, sp, headCF * CFrame.new(0, headW * 0.60, 0), headW)
		-- The face rides the WIDE lower skirt, which is where the sheet puts it,
		-- so `front` is that tier's radius rather than the head's.
		faceCF = headCF * CFrame.new(0, -headW * 0.10, 0)
		faceW = headW * 1.00
		front = headW * 0.60
	end

	-- No +0.04 any more. That was the sticker being pushed a hair clear of the
	-- head so it did not z-fight; a ball centred on the surface needs no help.
	addFace(model, faceCF, faceW, front, sp.Biome, sp.Body)

	return finish()
end

--==============================================================================
-- THE POD
--
-- Egg, jagged seam, curled tendril -- the pod sheet. The body says biome; its
-- diameter and smaller tier-coloured crown/seam say how hard it is to carry.
-- Species stays hidden until hatch.
--==============================================================================
function CreatureModel.BuildPod(sp: SeedData.Species, tier: number, cf: CFrame,
	parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Pod_" .. sp.Id
	model:SetAttribute("SpeciesId", sp.Id)
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Tier", tier)
	model:SetAttribute("Stage", CreatureModel.STAGE_POD)
	model.Parent = parent

	-- THE CFRAME IS THE BASE, not the centre -- same contract as BuildCreature,
	-- because two builders in one file meaning different things by the same
	-- argument is a trap for every caller.
	-- Size comes from weight, so the pod tells you what it will cost to carry
	-- before you commit to the hold. See SeedData.PodDiameter.
	local D = SeedData.PodDiameter(tier)
	-- The shell owns the BIOME colour now. Keeping tier colour over the entire
	-- body made five different silhouettes collapse back into the same family at
	-- normal viewing distance. Tier still has a fixed, readable home on the
	-- smaller crown/seam (and the Colossal label); it no longer paints the egg.
	local color = SeedData.ColorForTier(tier)
	local biome = sp.Biome
	local baseCF = cf * CFrame.new(0, D * 0.5, 0)
	local BIOME_PALETTE = {
		dustbowl = {
			body = Color3.fromRGB(132, 74, 45),
			accent = Color3.fromRGB(191, 119, 65),
			shadow = Color3.fromRGB(76, 51, 41),
			focal = Color3.fromRGB(242, 178, 91),
		},
		tanglemire = {
			body = Color3.fromRGB(35, 72, 60),
			accent = Color3.fromRGB(65, 126, 89),
			shadow = Color3.fromRGB(23, 48, 43),
			focal = Color3.fromRGB(126, 236, 222),
		},
		emberroot = {
			body = Color3.fromRGB(43, 37, 39),
			accent = Color3.fromRGB(108, 50, 34),
			shadow = Color3.fromRGB(21, 19, 21),
			-- Neon lifts toward yellow in Studio, so this starts red-hot.
			focal = Color3.fromRGB(255, 45, 5),
		},
		starbloom = {
			body = Color3.fromRGB(39, 37, 82),
			accent = Color3.fromRGB(91, 70, 164),
			shadow = Color3.fromRGB(24, 21, 55),
			focal = Color3.fromRGB(213, 198, 255),
		},
	}
	local palette = BIOME_PALETTE[biome]
	local bodyColor = if palette then palette.body else color
	local accent = if palette then palette.accent else color
	local shadow = if palette then palette.shadow else color:Lerp(Color3.new(0, 0, 0), 0.30)
	local focal = if palette then palette.focal else color
	local shell: BasePart
	local shellTop = 1.00

	if biome == "greenhollow" then
		-- LOCKED: the shipped Greenhollow shell is one D ball at baseCF.
		shell = ball("Shell", D, baseCF, color, model)
	elseif biome == "dustbowl" then
		-- A squat clay urn: rusted clay body and sun-baked shoulder.
		shell = upright("Shell", D * 0.74, D * 0.88,
			cf * CFrame.new(0, D * 0.37, 0), bodyColor, model)
		ball("ShellShoulder", D * 0.63,
			cf * CFrame.new(0, D * 0.73, 0), accent, model)
		shellTop = 1.045
	elseif biome == "tanglemire" then
		-- A leaning two-lobed gourd, with the mire colour concentrated above.
		shell = ball("Shell", D * 0.80,
			cf * CFrame.new(0, D * 0.40, 0), bodyColor, model)
		ball("ShellShoulder", D * 0.64,
			cf * CFrame.new(-D * 0.08, D * 0.79, D * 0.025), accent, model)
		shellTop = 1.11
	elseif biome == "emberroot" then
		-- A compact furnace nut: basalt chamber, oxidized volcanic collar.
		shell = upright("Shell", D * 0.80, D * 0.78,
			cf * CFrame.new(0, D * 0.40, 0), bodyColor, model)
		upright("ShellShoulder", D * 0.23, D * 0.65,
			cf * CFrame.new(0, D * 0.805, 0), accent, model)
		for i = 0, 1 do
			local side = if i == 0 then -1 else 1
			plate("ShoulderFacet", D * 0.25, D * 0.28, D * 0.075,
				cf * CFrame.new(side * D * 0.29, D * 0.74, 0)
					* CFrame.Angles(0, 0, side * math.rad(-18)),
				shadow, model, i == 1)
		end
		-- Three angular magma inclusions break through the egg itself. They are
		-- short surface chips, not floating embers and not another dotted ring.
		local MAGMA_BITS = {
			{ -0.22, 0.57, -0.345,  31, -18, 0.12, 0.085 },
			{  0.27, 0.28, -0.305, -40,  17, 0.10, 0.075 },
			{  0.16, 0.70, -0.365, -24, -29, 0.085, 0.065 },
		}
		for _, spec in ipairs(MAGMA_BITS) do
			local chip = wedge("MagmaBit",
				Vector3.new(D * spec[6], D * spec[7], D * 0.055),
				cf * CFrame.new(D * spec[1], D * spec[2], D * spec[3])
					* CFrame.Angles(0, math.rad(spec[4]), math.rad(spec[5])),
				focal, model)
			chip.Material = Enum.Material.Neon
			for _, face in ipairs(STUD_FACES) do
				(chip :: any)[face] = Enum.SurfaceType.Smooth
			end
		end
		shellTop = 0.92
	elseif biome == "starbloom" then
		-- A diagonal double-star seed rather than an upright egg.
		shell = ball("Shell", D * 0.76,
			cf * CFrame.new(0, D * 0.38, 0), bodyColor, model)
		ball("ShellShoulder", D * 0.58,
			cf * CFrame.new(D * 0.13, D * 0.70, -D * 0.04), accent, model)
		shellTop = 0.99
	else
		shell = ball("Shell", D, baseCF, color, model)
	end

	--==========================================================================
	-- THE TOP TWO TIERS SIGNAL WITH SILHOUETTE, NOT SIZE
	--
	-- Diameter is deliberately compressed and capped near 9 studs. It is not a
	-- free dial: SeedData.GripForward reads it directly to place the pod in the
	-- carrier's hands, and a player judges a hold by it from across the nest.
	-- Tracking a 50x plant scale would mean an 83-stud pod on a 34-stud bed.
	--
	-- Carry cost is untouched by any of this -- CarryMultiplier keys off the
	-- TIER's value, so a Colossal is 30% speed whatever its shell looks like.
	-- Pod art and pod gameplay are deliberately separable.
	--
	-- ONE silhouette change each, and no decoration. A ring of spikes reads as
	-- clutter at ten studs and as noise at fifty; a changed OUTLINE reads at
	-- both.
	--==========================================================================
	--==========================================================================
	-- THE TOP TWO TIERS ARE A DIFFERENT OBJECT, NOT A BIGGER ONE
	--
	-- Tier used to live entirely on the crown and the seam: the shell itself was
	-- the biome body colour at every tier from Tiny to Colossal. At arm's length
	-- that reads; across a nest it does not, and a Titan looked like a Tiny that
	-- had been scaled up. These two are 6.4% of all rolls between them -- rare
	-- enough that seeing one should be an event, common enough that a player
	-- will learn the silhouette.
	--
	-- So the SHELL takes the tier colour too, mixed into the biome body rather
	-- than replacing it, because a Titan must still read as belonging to the
	-- biome it was stolen from. Colossal mixes further than Titan, so the last
	-- step of the ladder is still a step.
	--
	-- GREENHOLLOW IS EXCLUDED. Its shell is marked LOCKED above and shipped
	-- that way; the tutorial biome does not get repainted for this.
	--==========================================================================
	--==========================================================================
	-- STARBLOOM'S CROWN IS A STEM, NOT A PLATE
	--
	-- All three of this biome's crowns were one flat quadrilateral tilted at a
	-- slightly different angle -- common, Titan and Colossal alike. Three
	-- rotations of the same sticker, and every one of them read as geometry
	-- sitting on a lid rather than as something the pod grew.
	--
	-- TWO SEGMENTS HINGED THE OPPOSITE WAY, so the stalk makes an S rather than
	-- a spike. That is the whole difference between a stem and a spar: a single
	-- straight piece at any angle still reads as a stick, and it is the CHANGE
	-- of direction partway up that the eye reads as growth. The upper segment is
	-- thinner than the lower, so it tapers.
	--
	-- The bud is the one Ball here, and the art bible allows a sphere for
	-- exactly this -- a bud, a glint, a dew drop. It is Neon and it is the only
	-- lit thing on a common pod, so the eye goes to the tip of the stalk.
	--
	-- ONE BUILDER, THREE TIERS. The crowns drifted apart because each tier
	-- hand-rolled its own; the aura had already gone the same way. Tier is the
	-- `frond` and the scale, not a different shape.
	--==========================================================================
	local function alienStem(anchor: CFrame, stalkColor: Color3, budColor: Color3,
		scale: number, frond: boolean)
		-- LONG AND THIN, OR THE TAPER NEVER SHOWS. The first pass ran these at
		-- 0.13 and 0.085 of a diameter over a third of one in length, and a
		-- segment that stubby reads as a spike no matter how it is hinged --
		-- the two thicknesses were too close to tell apart at pod scale.
		--
		-- THINNESS IS FREE, LENGTH IS NOT. The fix for "reads as a spike" is the
		-- 3.4:1 ratio below, and it is tempting to buy that with length -- but
		-- length goes straight into the pod's HEIGHT. At 0.42 and 0.36 the
		-- Colossal stood 18.7 studs against 10.6 wide, which is the same 19
		-- studs this file already caught the core placement causing once. The
		-- ratio comes from the diameters instead.
		local lowerLen = D * 0.32 * scale
		local upperLen = D * 0.26 * scale

		-- Lower segment: leans out and forward off the shell.
		local hingeA = anchor * CFrame.Angles(math.rad(8), 0, math.rad(-17))
		upright("CrownStalk", lowerLen, D * 0.095 * scale,
			hingeA * CFrame.new(0, lowerLen * 0.5, 0), stalkColor, model, false)

		-- Upper segment: hinged BACK the other way, which is the S, and barely
		-- over half the lower one's thickness.
		local hingeB = hingeA * CFrame.new(0, lowerLen, 0)
			* CFrame.Angles(math.rad(-6), 0, math.rad(36))
		upright("CrownStalkTip", upperLen, D * 0.055 * scale,
			hingeB * CFrame.new(0, upperLen * 0.5, 0), stalkColor, model, false)

		local tip = hingeB * CFrame.new(0, upperLen, 0)
		local bud = ball("CrownBud", D * 0.16 * scale, tip, budColor, model, false)
		bud.Material = Enum.Material.Neon

		if frond then
			-- A single curled blade off the hinge. It hangs on the OUTSIDE of
			-- the bend, where a leaf on a real stalk would sit, and it is what
			-- separates the top two tiers from the common stem.
			-- IT HANGS. Pointing the blade up off the bend gave the stalk a
			-- barb and the whole crown read as an arrow; drooping it past
			-- horizontal is what makes the same wedge read as a leaf. Longer
			-- and thinner than the first pass for the same reason the stalk is.
			local blade = plate("CrownFrond", D * 0.17 * scale, D * 0.40 * scale,
				D * 0.035 * scale,
				hingeB * CFrame.new(D * 0.06 * scale, -D * 0.04 * scale, 0)
					* CFrame.Angles(math.rad(6), math.rad(-28), math.rad(-118)),
				stalkColor, model, true)
			blade.Material = Enum.Material.SmoothPlastic
		end
	end

	local function tintTopTier(mix: number)
		if biome == "greenhollow" then
			return
		end
		shell.Color = bodyColor:Lerp(color, mix)
		-- BOTH LOBES, OR IT READS AS A MISTAKE. Every biome but Greenhollow
		-- builds the egg from two masses, and tinting only the main one left a
		-- Titan with a crimson body and an indigo shoulder -- which looks like a
		-- part somebody forgot rather than like a tier.
		--
		-- The shoulder takes LESS of the mix on purpose. It is the mass that
		-- catches the light from behind, so holding it nearer the biome colour
		-- keeps a shape in the egg; tinting the two identically flattened it
		-- into one flat silhouette with no read of its own.
		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("BasePart") and d.Name == "ShellShoulder" then
				d.Color = bodyColor:Lerp(color, mix * 0.62)
			end
		end
	end

	--==========================================================================
	-- AN AURA IS A FIELD, NOT A SPARKLE
	--
	-- Two pieces, and they do different jobs. The EMITTER is a slow wide swell
	-- that breathes on its own -- no driver, so it cannot stop when a script
	-- does and costs nothing per frame. The LIGHT is what makes the pod affect
	-- the ground it sits on, which is the difference between a pod that glows
	-- and a pod that is merely bright.
	--
	-- Sized off D, so a Colossal's aura is a Colossal's aura rather than a Tiny
	-- effect stretched over a bigger egg.
	--==========================================================================
	local function addAura(host: BasePart, hue: Color3, tail: Color3,
		reach: number, rate: number, bright: number)
		local att = Instance.new("Attachment")
		att.Name = "AuraAttachment"
		att.Position = Vector3.new(0, 0, 0)
		att.Parent = host

		local halo = Instance.new("ParticleEmitter")
		halo.Name = "AuraPulse"
		halo.Color = ColorSequence.new(hue, tail)
		halo.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, D * 0.30 * reach),
			NumberSequenceKeypoint.new(1, D * 1.30 * reach),
		})
		-- In at the start, out at the end: a swell, not a pop.
		halo.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0.62),
			NumberSequenceKeypoint.new(1, 1),
		})
		halo.Lifetime = NumberRange.new(2.2, 2.6)
		-- Slow. One swell a second is a heartbeat; five is a strobe.
		halo.Rate = rate
		halo.Speed = NumberRange.new(0, 0)
		halo.LightEmission = 1
		halo.LightInfluence = 0
		halo.Parent = att

		local glow = Instance.new("PointLight")
		glow.Name = "AuraGlow"
		glow.Color = hue
		glow.Brightness = bright
		glow.Range = D * 2.0 * reach
		glow.Shadows = false
		glow.Parent = host
		return halo
	end

	if tier == 6 then
		tintTopTier(0.42)
		if biome == "greenhollow" then
			-- LOCKED: shipped split-ball crown.
			for i = 0, 1 do
				local side = if i == 0 then -1 else 1
				ball(if i == 0 then "CrownLeft" else "CrownRight", D * 0.56,
					baseCF * CFrame.new(side * D * 0.20, D * 0.32, 0)
						* CFrame.Angles(0, 0, side * math.rad(-16)),
					color, model)
			end
		elseif biome == "dustbowl" then
			for i = 0, 1 do
				local side = if i == 0 then -1 else 1
				wedge(if i == 0 then "CrownLeft" else "CrownRight",
					Vector3.new(D * 0.38, D * 0.24, D * 0.42),
					cf * CFrame.new(side * D * 0.18, D * 1.01, 0)
						* CFrame.Angles(0, side * math.rad(9), side * math.rad(-17)),
					if i == 0 then accent else color, model)
			end
		elseif biome == "tanglemire" then
			for i = 0, 1 do
				local side = if i == 0 then -1 else 1
				plate(if i == 0 then "CrownLeft" else "CrownRight",
					D * 0.36, D * (if i == 0 then 0.40 else 0.32), D * 0.09,
					cf * CFrame.new(side * D * 0.12, D * 1.13, 0)
						* CFrame.Angles(0, 0, side * math.rad(-23)),
					if i == 0 then color else shadow, model, i == 1)
			end
		elseif biome == "emberroot" then
			for i = 0, 1 do
				local side = if i == 0 then -1 else 1
				plate(if i == 0 then "CrownLeft" else "CrownRight",
					D * 0.32, D * 0.34, D * 0.10,
					cf * CFrame.new(side * D * 0.17, D * 0.98, 0)
						* CFrame.Angles(0, 0, side * math.rad(-25)),
					if i == 0 then shadow else color, model, i == 1)
			end
		elseif biome == "starbloom" then
			-- A taller stem than the common one, and it grows a frond.
			alienStem(cf * CFrame.new(0, D * 0.94, 0), color, focal, 1.10, true)
		else
			for i = 0, 1 do
				local side = if i == 0 then -1 else 1
				ball(if i == 0 then "CrownLeft" else "CrownRight", D * 0.56,
					baseCF * CFrame.new(side * D * 0.20, D * 0.32, 0), color, model)
			end
		end

		-- Restrained on purpose: this is punctuation on the cleft, not a fire.
		-- An emitter animates itself, so the pod needs no driver to look alive.
		local att = Instance.new("Attachment")
		att.Name = "EmberVent"
		att.Parent = shell
		if biome == "greenhollow" then
			att.Position = Vector3.new(0, D * 0.42, 0)
		else
			att.Position = shell.CFrame:PointToObjectSpace(
				(cf * CFrame.new(0, D * (shellTop + 0.03), 0)).Position)
		end
		local em = Instance.new("ParticleEmitter")
		em.Name = "EmberTrail"
		em.Color = if biome == "greenhollow"
			then ColorSequence.new(color, color:Lerp(Color3.fromRGB(120, 20, 10), 0.7))
			else ColorSequence.new(color, focal)
		em.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, D * 0.05),
			NumberSequenceKeypoint.new(0.4, D * 0.11),
			NumberSequenceKeypoint.new(1, 0),
		})
		em.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		em.Lifetime = NumberRange.new(0.9, 1.6)
		em.Rate = 7
		em.Speed = NumberRange.new(D * 0.10, D * 0.22)
		em.Acceleration = Vector3.new(0, D * 0.30, 0)
		em.SpreadAngle = Vector2.new(16, 16)
		em.LightEmission = 1
		em.LightInfluence = 0
		em.Parent = att

		-- AND THE AURA. The vent trail above is punctuation on the cleft; this
		-- is the field around the whole egg, and it is the thing a player sees
		-- before they are close enough to read a crown. Pitched deliberately
		-- under Colossal's -- shorter reach, slower rate, dimmer -- so the last
		-- rung of the ladder is still a rung.
		addAura(shell, color, accent, 0.78, 0.8, 1.1)

	elseif tier == 7 then
		tintTopTier(0.55)
		--== COLOSSAL: the shell is cracked open, and something is burning ==--
		-- The crown is lifted and tilted off the shell rather than seated on it,
		-- so the outline breaks and a gap opens. That gap is the silhouette
		-- change; the core is what the gap is FOR.
		-- THE CORE HAS TO BREAK THE SURFACE OR NOTHING IS REVEALED. First pass
		-- put it at 0.26 D inside a shell of radius 0.5 D -- entirely buried --
		-- and lifted the crown by too little to open a gap, so the pod just read
		-- as a lopsided gourd. The core now sits ON the shell's crown line and
		-- stands a quarter of a diameter proud of it.
		-- OFFSETS ARE FROM baseCF, WHICH IS ALREADY HALF A DIAMETER UP. Measuring
		-- from the ground instead double-counted that lift: the core ended up
		-- 0.74 D clear of the shell and the pod grew to 19 studs tall against
		-- the 13.5 it should be. The shell's own top is 0.50 D above baseCF, so
		-- 0.44 puts the core through it by a quarter of a diameter -- enough to
		-- be a burst, not a balloon on a stick.
		local coreDiameter = if biome == "greenhollow" then 0.60
			elseif biome == "dustbowl" then 0.52
			elseif biome == "tanglemire" then 0.50
			elseif biome == "emberroot" then 0.56
			elseif biome == "starbloom" then 0.48
			else 0.60
		local coreColor = if biome == "dustbowl" then Color3.fromRGB(255, 210, 145)
			elseif biome == "tanglemire" then Color3.fromRGB(158, 255, 223)
			elseif biome == "emberroot" then Color3.fromRGB(255, 174, 92)
			elseif biome == "starbloom" then Color3.fromRGB(222, 210, 255)
			else Color3.fromRGB(255, 240, 190)
		local coreCF = if biome == "greenhollow"
			then baseCF * CFrame.new(0, D * 0.44, 0)
			else cf * CFrame.new(0, D * (shellTop + 0.24 - coreDiameter * 0.5), 0)
		local core = ball("Core", D * coreDiameter, coreCF, coreColor, model, false)
		core.Material = Enum.Material.Neon

		if biome == "greenhollow" then
			-- LOCKED: shipped offset ball lid.
			ball("Crown", D * 0.66,
				baseCF * CFrame.new(D * 0.22, D * 0.62, -D * 0.06)
					* CFrame.Angles(math.rad(-16), 0, math.rad(14)),
				color, model)
		elseif biome == "dustbowl" then
			wedge("Crown", Vector3.new(D * 0.40, D * 0.18, D * 0.40),
				cf * CFrame.new(D * 0.06, D * 1.12, -D * 0.03)
					* CFrame.Angles(math.rad(-12), 0, math.rad(17)), color, model)
		elseif biome == "tanglemire" then
			plate("Crown", D * 0.56, D * 0.38, D * 0.11,
				cf * CFrame.new(D * 0.19, D * 1.20, -D * 0.04)
					* CFrame.Angles(math.rad(-10), 0, math.rad(21)),
				color, model)
		elseif biome == "emberroot" then
			upright("Crown", D * 0.16, D * 0.58,
				cf * CFrame.new(D * 0.15, D * 1.05, -D * 0.03)
					* CFrame.Angles(math.rad(-12), 0, math.rad(13)),
				color, model)
		elseif biome == "starbloom" then
			-- The tallest stem, and its bud takes the CORE's colour rather than
			-- the tier's: on a Colossal the shell is already broken open and the
			-- stalk should look like it is lit by whatever got out.
			alienStem(cf * CFrame.new(0, D * 0.94, 0), color, coreColor, 1.20, true)
		else
			ball("Crown", D * 0.66,
				baseCF * CFrame.new(D * 0.22, D * 0.62, -D * 0.06), color, model)
		end

		local glow = Instance.new("PointLight")
		glow.Name = "CoreGlow"
		glow.Color = if biome == "greenhollow" then color else coreColor
		glow.Brightness = 1.6
		glow.Range = D * 2.4
		glow.Shadows = false
		glow.Parent = core

		-- THE PULSE IS AN EMITTER, NOT A SCRIPT. A light animated from a driver
		-- would need one more thing running per pod and would stop the moment
		-- the driver did; a slow, wide, low-rate emitter breathes on its own and
		-- costs nothing to keep alive.
		-- The same aura Titan wears, turned up: wider reach, faster swell and a
		-- brighter light. Hung on the CORE rather than the shell, because on a
		-- Colossal the core is the thing that broke out and the aura should look
		-- like it is coming from the burst rather than from the egg.
		--
		-- Shared with Titan on purpose. Two hand-rolled emitters drifted apart
		-- once already -- Colossal had a field and Titan had seven sparks a
		-- second -- and the ladder only reads if the two are the same effect at
		-- two strengths.
		addAura(core, if biome == "greenhollow" then color else coreColor,
			accent, 1.0, 1.4, 2.2)

		--==================================================================
		-- THE ONE LABEL A POD IS ALLOWED
		--
		-- Pods carry no species id, no form rarity and no name, because an
		-- unhatched pod exists to ask what is inside it and a label would
		-- answer that. A TIER label answers a different question -- how big,
		-- how slow, how much -- which the diameter and tier-coloured crown/seam
		-- already shout anyway. It spoils nothing, and at 0.5% of rolls it should be
		-- unmistakable when it happens.
		--==================================================================
		local tag = Instance.new("BillboardGui")
		tag.Name = "TierTag"
		tag.Size = UDim2.new(0, 190, 0, 44)
		tag.StudsOffsetWorldSpace = Vector3.new(0, D * 0.95, 0)
		tag.AlwaysOnTop = true
		--==================================================================
		-- BOUNDED, LIKE EVERY OTHER LABEL IN THIS GAME
		--
		-- AlwaysOnTop with no MaxDistance is a label that draws THROUGH the
		-- world at ANY range: one Colossal pod in one nest put the word
		-- COLOSSAL through the terrain, into the eyeline of every player on a
		-- 1,500 stud road, and it followed the carrier around because the tag
		-- rides along when the pod becomes a Tool.
		--
		-- AlwaysOnTop is still right -- the label has to beat the pod's own
		-- crown, which is taller than it is. The range is what was missing.
		-- 160 is PlantUI's number for a label on a plant, which is the same
		-- job; PromptUI uses 250 and SpeedFX 90. This was the only billboard
		-- in the codebase that set no range at all.
		--==================================================================
		tag.MaxDistance = 160
		tag.Parent = shell
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = color
		text.TextStrokeTransparency = 0.35
		text.Text = "COLOSSAL"
		text.Parent = tag

		-- For CarryService and SoundCues to read. Geometry does not play sound,
		-- and it does not decide when a pickup happened either.
		model:SetAttribute("PickupSound", "ColossalPickup")
	else
		if biome == "greenhollow" then
			-- LOCKED: shipped common crown.
			ball("Crown", D * 0.84, baseCF * CFrame.new(0, D * 0.34, 0), color, model)
		elseif biome == "dustbowl" then
			wedge("Crown", Vector3.new(D * 0.58, D * 0.22, D * 0.42),
				cf * CFrame.new(0, D * 1.00, 0), color, model)
		elseif biome == "tanglemire" then
			plate("Crown", D * 0.48, D * 0.34, D * 0.10,
				cf * CFrame.new(-D * 0.10, D * 1.15, 0)
					* CFrame.Angles(0, 0, math.rad(-19)), color, model)
		elseif biome == "emberroot" then
			plate("Crown", D * 0.42, D * 0.30, D * 0.12,
				cf * CFrame.new(0, D * 1.02, 0)
					* CFrame.Angles(0, 0, math.rad(-8)),
				color, model)
		elseif biome == "starbloom" then
			-- The plain stem: no frond, and the bud is the only lit thing on the
			-- pod. Same builder as the top two tiers, one size down.
			alienStem(cf * CFrame.new(0, D * 0.94, 0), color, focal, 1.0, false)
		else
			ball("Crown", D * 0.84, baseCF * CFrame.new(0, D * 0.34, 0), color, model)
		end
	end

	-- The seam is still the family trait, but its direction now follows the body
	-- plan instead of stamping the same ring onto all five pods.
	if biome == "greenhollow" then
		-- LOCKED: shipped waist seam.
		upright("Seam", D * 0.07, D * 1.02, baseCF * CFrame.new(0, D * 0.02, 0),
			color:Lerp(Color3.new(0, 0, 0), 0.18), model)
	elseif biome == "dustbowl" then
		upright("Seam", D * 0.055, D * 0.91, cf * CFrame.new(0, D * 0.43, 0),
			color, model)
	elseif biome == "tanglemire" then
		wedge("Seam", Vector3.new(D * 0.11, D * 0.55, D * 0.085),
			cf * CFrame.new(0, D * 0.63, -D * 0.405)
				* CFrame.Angles(0, 0, math.rad(-18)), color, model)
	elseif biome == "emberroot" then
		local seam = part({
			name = "Seam",
			size = Vector3.new(D * 0.075, D * 0.38, D * 0.055),
			cframe = cf * CFrame.new(-D * 0.05, D * 0.34, -D * 0.40)
				* CFrame.Angles(0, 0, math.rad(-11)),
			color = focal,
			material = Enum.Material.Neon,
			studs = false,
			parent = model,
		})
		part({
			name = "SeamFork",
			size = Vector3.new(D * 0.06, D * 0.22, D * 0.055),
			cframe = seam.CFrame * CFrame.new(D * 0.08, D * 0.24, 0)
				* CFrame.Angles(0, 0, math.rad(29)),
			color = seam.Color,
			material = Enum.Material.Neon,
			studs = false,
			parent = model,
		})
	elseif biome == "starbloom" then
		part({
			name = "Seam",
			size = Vector3.new(D * 0.10, D * 0.52, D * 0.055),
			cframe = cf * CFrame.new(0, D * 0.60, -D * 0.385)
				* CFrame.Angles(0, 0, math.rad(-32)),
			color = color,
			studs = false,
			parent = model,
		})
	else
		upright("Seam", D * 0.07, D * 1.02, baseCF * CFrame.new(0, D * 0.02, 0),
			color:Lerp(Color3.new(0, 0, 0), 0.18), model)
	end

	--==========================================================================
	-- EVERY BIOME OWNS A DIFFERENT REGION OF THE OUTLINE
	--
	-- Silhouette still carries the long-distance read; the new biome shell
	-- palettes reinforce it at medium distance while the smaller crown/seam owns
	-- the tier signal. Silhouette has only so many places to put
	-- mass, so they are divided up, one region each, and none of them overlap:
	--
	--   greenhollow   ABOVE       tendrils curling off the crown
	--   dustbowl      BELOW-WIDE  a cracked clay pan splayed round the foot
	--   tanglemire    THE FLANK   a withe belt with strands hanging off it
	--   emberroot     THE SIDES   charred claws gripping it, cracks glowing through
	--   starbloom     DIAGONAL    a tilted halo crossing the whole outline
	--
	-- Top, bottom, fringe, grip, diagonal. Squint at any two and they are
	-- different shapes -- which is the actual test, because a pod is first seen
	-- across a nest, small and against the sky, and at that size detail is worth
	-- nothing and outline is worth everything.
	--
	-- GREENHOLLOW IS LOCKED and is reproduced below exactly as it shipped. What
	-- did change is that it is no longer the `else` branch: emberroot and
	-- starbloom used to fall into it and wear Greenhollow's green tendrils,
	-- which is why three of the five biomes had the same pod.
	--
	-- THERE IS NO `else` NOW, DELIBERATELY. All five biomes are named, and a
	-- sixth would come out as a bare shell -- which is what it should look
	-- like. A default branch here is how the last two biomes ended up
	-- disguised as Greenhollow without anyone deciding they should be.
	--
	-- The hatch stays unspoiled on all five: no species id, no form rarity, no
	-- name. Greenhollow means five possible shapes and Dustbowl means five
	-- others, and a pod that named which would answer the only question an
	-- unhatched pod exists to ask.
	--==========================================================================
	if sp.Biome == "greenhollow" then
		--== LOCKED. Four tendrils curling up and off the crown. ==--
		-- One incremental walk, each step rotated on from the last, which is what
		-- makes it curl rather than fan. Do not straighten it.
		local tip = baseCF * CFrame.new(0, D * 0.62, 0)
		for _ = 1, 4 do
			tip = tip * CFrame.new(0, D * 0.13, 0) * CFrame.Angles(0, 0, math.rad(38))
			part({
				name = "Tendril",
				size = Vector3.new(D * 0.10, D * 0.16, D * 0.10),
				cframe = tip,
				color = Color3.fromRGB(104, 158, 62),
				parent = model,
			})
		end

	elseif sp.Biome == "dustbowl" then
		--== THE BROKEN SUN PAN: low, wide and completely bare above. ==--
		-- Five broad wedges overlap the shell's footprint and flare into an
		-- irregular baked-clay saucer. The old upright bars read as a wooden cog;
		-- these stay low enough that their taper, not their construction, makes
		-- the outline. Every wedge is centred at half its own height, so its base
		-- rests on `cf` instead of clipping through the nest pedestal.
		local CLAY = Color3.fromRGB(164, 105, 62)
		local BAKED = Color3.fromRGB(96, 67, 54)
		local SHARDS = {
			{ -12, 0.40, 0.46, 0.34, 0.15 },
			{  61, 0.39, 0.38, 0.29, 0.11 },
			{ 139, 0.42, 0.43, 0.36, 0.13 },
			{ 218, 0.38, 0.36, 0.27, 0.10 },
			{ 296, 0.41, 0.44, 0.32, 0.14 },
		}
		for i, spec in ipairs(SHARDS) do
			local az, radius, length, width, height =
				spec[1], spec[2], spec[3], spec[4], spec[5]
			wedge("CrustShard", Vector3.new(D * width, D * height, D * length),
				cf * CFrame.Angles(0, math.rad(az), 0)
					* CFrame.new(0, D * height * 0.5, -D * radius),
				if i == 2 or i == 5 then CLAY else BAKED, model)
		end

	elseif sp.Biome == "tanglemire" then
		--== THE CROOKED WITHE: an incomplete living wrap on the flanks. ==--
		-- TanglemireForms.Pod remains frozen as the Mire-Cage record; this branch
		-- does not call or alter it. Four short tangent pieces imply a belt without
		-- drawing a mechanical ring, and three tapered drops occupy the shoulder
		-- gap where the shell curves away.
		local BOG = Color3.fromRGB(43, 82, 67)
		local REED = Color3.fromRGB(72, 126, 91)
		local DEW = Color3.fromRGB(126, 236, 222)
		local BELT = {
			{  18,  0.05,  13, 0.42 },
			{ 108, -0.02, -10, 0.34 },
			{ 201,  0.04,  16, 0.39 },
			{ 292, -0.05, -14, 0.31 },
		}
		for i, spec in ipairs(BELT) do
			local az, y, roll, length = spec[1], spec[2], spec[3], spec[4]
			part({
				name = "WitheBelt",
				size = Vector3.new(D * length, D * 0.09, D * 0.10),
				cframe = baseCF * CFrame.new(0, D * y, 0)
					* CFrame.Angles(0, math.rad(az), 0)
					* CFrame.new(0, 0, -D * 0.50)
					* CFrame.Angles(0, 0, math.rad(roll)),
				color = if i == 2 then BOG else REED,
				parent = model,
			})
		end

		local DROPS = {
			{  26, 0.38, true },
			{ 157, 0.29, false },
			{ 276, 0.34, true },
		}
		for i, spec in ipairs(DROPS) do
			local az, amount, beaded = spec[1] :: number, spec[2] :: number, spec[3] :: boolean
			local drop = D * amount
			local anchor = baseCF * CFrame.Angles(0, math.rad(az), 0)
				* CFrame.new(0, D * 0.01, -D * 0.515)
			plate("WitheStrand", D * 0.13, drop, D * 0.06,
				anchor * CFrame.new(0, -drop * 0.5, 0)
					* CFrame.Angles(0, 0, math.rad(if i == 2 then -5 else 6)),
				if i == 2 then BOG else REED, model, i == 2)
			if beaded then
				ball("Dew", D * 0.085, anchor * CFrame.new(0, -drop, 0), DEW, model, false)
			end
		end

	elseif sp.Biome == "emberroot" then
		--== THE CLINKER TALONS: side mass with a visible knuckle-to-tip taper. ==--
		-- Four two-joint roots curl in from outside the shell. Their bases are
		-- raised by the thickness allowance and every centre is measured from its
		-- preceding root frame, so the angled wedges stay above `cf`. Reducing the
		-- second joint to roughly half width is what makes a claw instead of a
		-- fence post.
		local CHAR = Color3.fromRGB(25, 22, 23)
		local ASH = Color3.fromRGB(74, 67, 66)
		for i, degrees in ipairs({ 38, 142, 224, 318 }) do
			local root = cf * CFrame.Angles(0, math.rad(degrees), 0)
				* CFrame.new(0, D * 0.035, -D * 0.555)
				* CFrame.Angles(math.rad(-13), 0, math.rad(if i % 2 == 0 then -4 else 4))
			local rootLen = D * (if i == 3 then 0.34 else 0.37)
			plate("ClawRoot", D * 0.20, rootLen, D * 0.095,
				root * CFrame.new(0, rootLen * 0.5, 0), CHAR, model, i % 2 == 0)

			local tipRoot = root * CFrame.new(0, rootLen, 0)
				* CFrame.Angles(math.rad(-25), 0, 0)
			local tipLen = D * (if i == 1 then 0.25 else 0.22)
			plate("ClawTip", D * 0.10, tipLen, D * 0.055,
				tipRoot * CFrame.new(0, tipLen * 0.5, 0), ASH, model, i % 2 ~= 0)
		end

		-- Three angular coals punctuate the foot without turning it into a dotted
		-- ring. Neon is intentionally pushed red so it renders ember-orange.
		local COALS = {
			{  76, 0.11, 0.08 },
			{ 191, 0.08, 0.06 },
			{ 302, 0.095, 0.07 },
		}
		for _, spec in ipairs(COALS) do
			local az, width, height = spec[1], spec[2], spec[3]
			local coal = wedge("Coal", Vector3.new(D * width, D * height, D * width),
				cf * CFrame.Angles(0, math.rad(az), 0)
					* CFrame.new(0, D * height * 0.5, -D * 0.46),
				Color3.fromRGB(255, 66, 10), model)
			coal.Material = Enum.Material.Neon
		end

	elseif sp.Biome == "starbloom" then
		--== THE FALLING STAR: ACCRETION, NOT A DECORATIVE RING. ==--
		-- A dark singularity terminates one end of a broad, uneven crescent. Five
		-- shards are visibly stretched across the shell toward it, while a comet
		-- enters from the open end. The pieces deliberately differ in mass and
		-- spacing: this is matter being pulled apart, not five copies of one halo
		-- segment. The diagonal remains Starbloom's silhouette territory.
		local ORBIT = Color3.fromRGB(105, 86, 180)
		local tilt = CFrame.Angles(math.rad(29), math.rad(-7), math.rad(-18))
		local function smoothPart(p: BasePart): BasePart
			p.Material = Enum.Material.SmoothPlastic
			for _, face in ipairs(STUD_FACES) do
				(p :: any)[face] = Enum.SurfaceType.Smooth
			end
			return p
		end

		local function accretionPlate(name: string, azimuth: number, size: Vector3,
			lift: number, radius: number, roll: number, plateColor: Color3): BasePart
			return smoothPart(wedge(name, size * D,
				baseCF * tilt * CFrame.Angles(0, math.rad(azimuth), 0)
					* CFrame.new(0, D * lift, -D * radius)
					* CFrame.Angles(0, 0, math.rad(roll)),
				plateColor, model))
		end

		-- Four unequal masses carry the main silhouette. The heavy middle sweep
		-- and small hooked tip are readable even when the surface shards disappear
		-- on a low-end phone.
		accretionPlate("AccretionAnchor", -101, Vector3.new(0.24, 0.075, 0.18),
			0.040, 0.525, -11, shadow)
		accretionPlate("AccretionSweep", -58, Vector3.new(0.43, 0.085, 0.20),
			0.025, 0.525, 4, accent)
		accretionPlate("AccretionFan", -13, Vector3.new(0.36, 0.070, 0.16),
			0.020, 0.530, 9, ORBIT)
		accretionPlate("AccretionHook", 31, Vector3.new(0.25, 0.060, 0.12),
			0.035, 0.535, 16, focal)

		-- The void sits proud of the shell at the closed end of the crescent. Its
		-- two thin horizon slivers frame darkness instead of filling it with glow.
		local singularityCF = baseCF * tilt
			* CFrame.Angles(0, math.rad(-116), 0)
			* CFrame.new(0, D * 0.040, -D * 0.555)
		local singularity = ball("Singularity", D * 0.16, singularityCF,
			Color3.fromRGB(9, 8, 18), model, false)
		singularity.Material = Enum.Material.SmoothPlastic
		for _, sign in ipairs({ -1, 1 }) do
			local horizon = smoothPart(wedge(
				if sign < 0 then "EventHorizonLower" else "EventHorizonUpper",
				Vector3.new(D * 0.21, D * 0.032, D * 0.052),
				singularityCF * CFrame.new(0, D * 0.070 * sign, -D * 0.072)
					* CFrame.Angles(0, 0, math.rad(12 * sign)),
				focal, model))
			horizon.Material = Enum.Material.Neon
		end

		-- Surface shards walk a separate diagonal across the front of the pod.
		-- Every centre sits on or beyond the shell surface; none are hidden inside.
		local INFALL = {
			{  0.39, -0.14, -0.31, 0.13, 0.055, 0.065, -34, -15 },
			{  0.27, -0.06, -0.41, 0.15, 0.052, 0.060, -31, -10 },
			{  0.12,  0.02, -0.49, 0.17, 0.050, 0.055, -28,  -5 },
			{ -0.05,  0.09, -0.50, 0.14, 0.045, 0.050, -24,   2 },
			{ -0.21,  0.15, -0.46, 0.11, 0.040, 0.045, -19,   8 },
		}
		for i, spec in ipairs(INFALL) do
			local shard = smoothPart(wedge("InfallShard" .. i,
				Vector3.new(D * spec[4], D * spec[5], D * spec[6]),
				baseCF * CFrame.new(D * spec[1], D * spec[2], D * spec[3])
					* CFrame.Angles(0, math.rad(spec[8]), math.rad(spec[7])),
				if i % 2 == 0 then focal else ORBIT, model))
			if i == 2 or i == 4 then
				shard.Material = Enum.Material.Neon
			end
		end

		-- The open end receives one head and a two-step wake. Their taper points
		-- toward the singularity, so the whole composition has one direction.
		local cometCF = baseCF * tilt * CFrame.Angles(0, math.rad(68), 0)
			* CFrame.new(0, D * 0.035, -D * 0.558)
		local comet = ball("CometHead", D * 0.085, cometCF,
			Color3.fromRGB(220, 205, 255), model, false)
		comet.Material = Enum.Material.Neon
		for i, spec in ipairs({
			{ "CometWakeNear", 0.16, 0.045, 0.060, 0.11 },
			{ "CometWakeFar", 0.11, 0.032, 0.045, 0.20 },
		}) do
			local wake = smoothPart(wedge(spec[1] :: string,
				Vector3.new(D * (spec[2] :: number), D * (spec[3] :: number), D * (spec[4] :: number)),
				cometCF * CFrame.new(D * (spec[5] :: number), 0, D * 0.025 * i)
					* CFrame.Angles(0, math.rad(-18), math.rad(-28)),
				if i == 1 then focal else ORBIT, model))
			if i == 1 then
				wake.Material = Enum.Material.Neon
			end
		end
	end

	model.PrimaryPart = shell
	--==========================================================================
	-- IT DOES NOT TAG ITSELF SeedPod. THE CALLER DECIDES WHAT A POD MEANS.
	--
	-- This used to add the tag here, which quietly made every pod in the game
	-- loot -- including the three that are not. Five callers, and only two want
	-- it: a nest pod and a dropped pod are takeable; a pod welded to your head,
	-- a pod being used as a Tool handle, and a pod HATCHING IN SOMEBODY'S PLOT
	-- are not.
	--
	-- The plot case was a live bug: a planted pod grew a Take prompt, and taking
	-- it ran the whole raid alarm -- RUN, then SAFE -- in the middle of the safe
	-- zone, for a pod the player had just carried home themselves.
	--
	-- Whether a thing is loot is a gameplay claim. A geometry builder has no
	-- business making it.
	--==========================================================================
	return model
end

function CreatureModel.Build(sp: SeedData.Species, tier: number, stage: Stage,
	cf: CFrame, parent: Instance): Model
	if stage == CreatureModel.STAGE_POD then
		return CreatureModel.BuildPod(sp, tier, cf, parent)
	end
	return CreatureModel.BuildCreature(sp, tier, stage, cf, parent)
end

return CreatureModel
