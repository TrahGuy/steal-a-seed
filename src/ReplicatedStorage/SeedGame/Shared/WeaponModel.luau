--!strict
-- Steal a Seed :: WeaponModel
--
-- The geometry for everything Marigold sells. ONE builder per weapon, and the
-- Tool in a player's hands, the model in the shop's ViewportFrame and the trap
-- lying on the road all come out of it.
--
-- That is the whole reason this file is separate from WeaponData: the moment
-- the shop draws its own idea of a Cactus Club, the picture and the product
-- start to drift and nobody notices until somebody buys the wrong thing. Same
-- split as SeedData / CreatureModel, and NOT a *Service -- it has no lifecycle.
--
--==============================================================================
-- EVERY WEAPON IS BUILT ALONG +Y FROM ITS GRIP AT THE ORIGIN
--
-- The grip's BASE sits at the passed CFrame and the weapon runs upward out of
-- it. One convention, so the Tool grip, the camera framing and the swing pose
-- all have the same idea of which end is the handle -- and so `BuildInto` can
-- be handed a Tool, a Model or a ViewportFrame without caring which.
--
--==============================================================================
-- AUTHORED SILHOUETTES, NOT STACKS OF EQUAL BARS
--
-- The project rule for creatures (AGENTS.md 11) is that a primitive is raw
-- material and never a finished form, and a weapon is held six studs from the
-- camera so it gets the same treatment. Concretely, in this file:
--
--   * every shaft TAPERS -- no weapon has two segments the same width
--   * every weapon is ASYMMETRIC somewhere on purpose: a burl on one side of
--     the Rootwood, one arm on the Cactus, a chipped corner on the Cindercrack,
--     fringe down one edge of the Paddle
--   * nothing is axis-aligned all the way up. Segments carry a few degrees of
--     lean so the outer contour is a crooked line rather than a ruler
--   * the saturated colour is used ONCE per weapon, on the thing the fiction
--     is about -- roots, ribs, petals, cracks, the trail
--
-- Spheres are reserved for eyes, buds and seeds, which here means the trap's
-- glowing seed and nothing else.
--==============================================================================

local WeaponData = require(script.Parent:WaitForChild("WeaponData"))

local WeaponModel = {}

type Item = WeaponData.Item

local BLACK = Color3.fromRGB(0, 0, 0)

--==============================================================================
-- ONE PART
--
-- Offsets are given in the weapon's own frame -- x right, y up the shaft, z
-- forward -- and turned into world space by the base CFrame. Rotations are
-- degrees about that same frame, applied before the offset so a leaning segment
-- leans about its own centre rather than swinging out from the grip.
--==============================================================================
type Spec = {
	name: string,
	size: Vector3,
	at: Vector3,
	colour: Color3,
	-- Degrees, x/y/z, about the weapon's own axes. All optional.
	rot: Vector3?,
	material: Enum.Material?,
	transparency: number?,
	shape: Enum.PartType?,
}

local function piece(container: Instance, base: CFrame, spec: Spec): BasePart
	local p = Instance.new("Part")
	p.Name = spec.name
	p.Size = spec.size
	local rot = spec.rot or Vector3.zero
	p.CFrame = base
		* CFrame.new(spec.at)
		* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
	p.Color = spec.colour
	p.Material = spec.material or Enum.Material.Wood
	p.Transparency = spec.transparency or 0
	if spec.shape then
		p.Shape = spec.shape
	end
	p.Anchored = false
	-- NOTHING ON A WEAPON COLLIDES OR IS QUERYABLE. A bat is resolved by the
	-- server measuring distances, never by a Touched event, and a swung club
	-- that could shove a body with its own physics would be a second, unowned
	-- knockback system running underneath the one that is validated.
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = container
	return p
end

-- The house idiom for a non-seam join: rigid, so the whole weapon is one
-- assembly and one grip weld carries all of it.
local function weld(to: BasePart, p: BasePart)
	if p == to then
		return
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
end

--==============================================================================
-- THE SIX BATS
--
-- Each returns its list of specs. The first entry is always the grip, and
-- BuildInto relies on that: it is the part the hand holds and the part
-- everything else is welded to.
--==============================================================================
local function rootwoodSpecs(pal: WeaponData.Palette): { Spec }
	local dark = pal.Wood:Lerp(BLACK, 0.28)
	local specs: { Spec } = {
		{ name = "Handle", size = Vector3.new(0.56, 1.50, 0.56), at = Vector3.new(0, 0.75, 0), colour = dark },
		-- Binding, three turns, none of them level.
		{ name = "Bind1", size = Vector3.new(0.64, 0.17, 0.64), at = Vector3.new(0, 0.34, 0), colour = pal.Bind, rot = Vector3.new(3, 0, 5) },
		{ name = "Bind2", size = Vector3.new(0.65, 0.15, 0.65), at = Vector3.new(0, 0.76, 0), colour = pal.Bind, rot = Vector3.new(-4, 0, 3) },
		{ name = "Bind3", size = Vector3.new(0.63, 0.16, 0.63), at = Vector3.new(0, 1.16, 0), colour = pal.Bind, rot = Vector3.new(2, 0, -6) },
		-- The shaft is crooked: three segments, each leaning the other way.
		{ name = "Shaft1", size = Vector3.new(0.72, 1.55, 0.68), at = Vector3.new(0.03, 2.20, 0), colour = pal.Wood, rot = Vector3.new(0, 0, -4) },
		{ name = "Shaft2", size = Vector3.new(0.90, 1.60, 0.84), at = Vector3.new(-0.02, 3.60, 0.02), colour = pal.Wood, rot = Vector3.new(2, 0, 6) },
		{ name = "Head", size = Vector3.new(1.16, 1.70, 1.04), at = Vector3.new(0.06, 5.05, 0), colour = pal.Wood, rot = Vector3.new(0, 0, -3) },
		{ name = "Cap", size = Vector3.new(1.00, 0.42, 0.94), at = Vector3.new(0.08, 5.95, 0), colour = dark, rot = Vector3.new(0, 0, -3) },
		-- ONE burl, on ONE side. The asymmetry is the point.
		{ name = "Burl", size = Vector3.new(0.62, 0.66, 0.58), at = Vector3.new(0.54, 4.55, 0.06), colour = pal.Wood:Lerp(BLACK, 0.14), rot = Vector3.new(0, 18, 22) },
		-- Living root, wound up the shaft.
		{ name = "Root1", size = Vector3.new(0.19, 1.60, 0.19), at = Vector3.new(0.32, 2.40, 0.26), colour = pal.Accent, rot = Vector3.new(18, 26, 24) },
		{ name = "Root2", size = Vector3.new(0.17, 1.70, 0.17), at = Vector3.new(-0.30, 3.60, -0.24), colour = pal.Accent, rot = Vector3.new(-16, 30, -22) },
		{ name = "Root3", size = Vector3.new(0.15, 1.10, 0.15), at = Vector3.new(0.26, 4.90, -0.30), colour = pal.Accent, rot = Vector3.new(22, -18, 28) },
		{ name = "Sprig", size = Vector3.new(0.34, 0.16, 0.22), at = Vector3.new(-0.48, 4.10, 0.10), colour = pal.Accent, rot = Vector3.new(0, 14, -34) },
	}
	return specs
end

local function cactusSpecs(pal: WeaponData.Palette): { Spec }
	local dark = pal.Accent:Lerp(BLACK, 0.30)
	local specs: { Spec } = {
		{ name = "Handle", size = Vector3.new(0.50, 1.30, 0.50), at = Vector3.new(0, 0.65, 0), colour = pal.Wood },
		{ name = "Collar", size = Vector3.new(0.68, 0.24, 0.68), at = Vector3.new(0, 1.36, 0), colour = pal.Bind },
		-- A barrel that swells and then stops. Short, which is the whole weapon.
		{ name = "Body1", size = Vector3.new(0.94, 1.20, 0.88), at = Vector3.new(0, 2.10, 0), colour = pal.Accent, rot = Vector3.new(0, 6, -2) },
		{ name = "Body2", size = Vector3.new(1.12, 1.24, 1.02), at = Vector3.new(0.02, 3.20, 0), colour = pal.Accent, rot = Vector3.new(0, -8, 3) },
		{ name = "Body3", size = Vector3.new(0.86, 0.92, 0.80), at = Vector3.new(-0.02, 4.16, 0.02), colour = pal.Accent, rot = Vector3.new(0, 4, -4) },
		{ name = "Crown", size = Vector3.new(0.58, 0.44, 0.54), at = Vector3.new(-0.04, 4.76, 0.02), colour = dark, rot = Vector3.new(0, 12, -5) },
		-- ONE arm, and a nub where the second one never grew.
		{ name = "Arm", size = Vector3.new(0.44, 0.86, 0.44), at = Vector3.new(0.78, 3.30, 0.04), colour = pal.Accent, rot = Vector3.new(0, 0, -34) },
		{ name = "ArmTip", size = Vector3.new(0.38, 0.52, 0.38), at = Vector3.new(1.02, 3.90, 0.04), colour = pal.Accent, rot = Vector3.new(0, 0, -12) },
		{ name = "Nub", size = Vector3.new(0.36, 0.40, 0.34), at = Vector3.new(-0.60, 2.48, 0.08), colour = pal.Accent, rot = Vector3.new(0, 0, 26) },
		-- Ribs. Four, at four different lengths, because four the same is a barrel.
		{ name = "Rib1", size = Vector3.new(0.13, 2.60, 0.13), at = Vector3.new(0.52, 3.00, 0.14), colour = dark, rot = Vector3.new(0, 0, -3) },
		{ name = "Rib2", size = Vector3.new(0.12, 2.20, 0.12), at = Vector3.new(-0.50, 2.90, 0.20), colour = dark, rot = Vector3.new(0, 0, 4) },
		{ name = "Rib3", size = Vector3.new(0.12, 2.40, 0.12), at = Vector3.new(0.10, 3.05, 0.50), colour = dark, rot = Vector3.new(3, 0, 0) },
		{ name = "Rib4", size = Vector3.new(0.12, 1.90, 0.12), at = Vector3.new(-0.08, 2.80, -0.48), colour = dark, rot = Vector3.new(-3, 0, 0) },
		-- Spines: small, pale, and only where a hand would not be.
		{ name = "Spine1", size = Vector3.new(0.10, 0.30, 0.10), at = Vector3.new(0.66, 3.70, 0.22), colour = pal.Bind, rot = Vector3.new(0, 0, -50) },
		{ name = "Spine2", size = Vector3.new(0.10, 0.28, 0.10), at = Vector3.new(-0.62, 3.42, -0.20), colour = pal.Bind, rot = Vector3.new(0, 0, 46) },
		{ name = "Spine3", size = Vector3.new(0.09, 0.26, 0.09), at = Vector3.new(0.18, 4.52, 0.42), colour = pal.Bind, rot = Vector3.new(52, 0, 0) },
	}
	return specs
end

local function sunflowerSpecs(pal: WeaponData.Palette): { Spec }
	local specs: { Spec } = {
		{ name = "Handle", size = Vector3.new(0.50, 1.40, 0.50), at = Vector3.new(0, 0.70, 0), colour = pal.Wood },
		{ name = "Bind", size = Vector3.new(0.60, 0.22, 0.60), at = Vector3.new(0, 1.44, 0), colour = pal.Bind, rot = Vector3.new(0, 0, 4) },
		-- A stalk, not a pole: two lengths, and the upper one leans.
		{ name = "Stem1", size = Vector3.new(0.44, 1.70, 0.42), at = Vector3.new(0, 2.40, 0), colour = pal.Bind, rot = Vector3.new(0, 0, -3) },
		{ name = "Stem2", size = Vector3.new(0.38, 1.60, 0.36), at = Vector3.new(-0.08, 4.00, 0.02), colour = pal.Bind, rot = Vector3.new(0, 0, 5) },
		{ name = "Leaf1", size = Vector3.new(0.86, 0.16, 0.42), at = Vector3.new(0.48, 2.62, 0.06), colour = pal.Bind, rot = Vector3.new(0, 12, -28) },
		{ name = "Leaf2", size = Vector3.new(0.68, 0.14, 0.34), at = Vector3.new(-0.44, 3.72, -0.06), colour = pal.Bind, rot = Vector3.new(0, -18, 24) },
		-- The head. The dark seed disc is the mass, and it is why this thing is
		-- slow: the card says LAUNCHER and the silhouette says heavy.
		{ name = "Backing", size = Vector3.new(1.30, 0.42, 1.26), at = Vector3.new(-0.10, 4.86, 0), colour = pal.Bind, rot = Vector3.new(0, 0, 5) },
		{ name = "SeedDisc", size = Vector3.new(1.52, 0.78, 1.46), at = Vector3.new(-0.12, 5.32, 0), colour = pal.Wood:Lerp(BLACK, 0.45), rot = Vector3.new(0, 0, 5) },
		{ name = "SeedRing", size = Vector3.new(1.04, 0.34, 1.00), at = Vector3.new(-0.12, 5.72, 0), colour = pal.Wood:Lerp(BLACK, 0.60), rot = Vector3.new(0, 0, 5) },
	}
	--==========================================================================
	-- NINE PETALS AT THREE LENGTHS
	--
	-- Eight identical ones round a circle is the "equal-width bars" failure in
	-- a ring. An odd count with a repeating long/short/mid cycle never lines up
	-- opposite itself, so the head reads as a grown flower rather than a gear.
	--==========================================================================
	local petalLen = { 1.10, 0.86, 0.98 }
	for i = 1, 9 do
		local ang = (i - 1) * (360 / 9)
		local len = petalLen[((i - 1) % 3) + 1]
		local r = 0.86 + len * 0.42
		--======================================================================
		-- THE YAW AND THE OFFSET HAVE TO AGREE, OR THE PETALS SIT CROSSWISE
		--
		-- CFrame.Angles(0, t, 0) sends a part's local +Z to (sin t, 0, cos t),
		-- and the petal's LENGTH is its Z. So the offset direction has to be
		-- that same vector, or every petal points along the rim instead of out
		-- from the middle -- which renders as a cog, not a flower.
		--======================================================================
		local out = Vector3.new(math.sin(math.rad(ang)), 0, math.cos(math.rad(ang)))
		table.insert(specs, {
			name = "Petal" .. i,
			size = Vector3.new(0.46, 0.20, len),
			at = Vector3.new(-0.12, 5.30, 0) + out * r,
			colour = if i % 3 == 0 then pal.Accent:Lerp(BLACK, 0.12) else pal.Accent,
			rot = Vector3.new(if i % 2 == 0 then 8 else -6, ang, 4),
		} :: Spec)
	end
	return specs
end

local function mirewoodSpecs(pal: WeaponData.Palette): { Spec }
	local dark = pal.Wood:Lerp(BLACK, 0.30)
	local specs: { Spec } = {
		{ name = "Handle", size = Vector3.new(0.50, 1.50, 0.48), at = Vector3.new(0, 0.75, 0), colour = dark },
		{ name = "Bind1", size = Vector3.new(0.58, 0.18, 0.56), at = Vector3.new(0, 0.42, 0), colour = pal.Bind, rot = Vector3.new(0, 0, 6) },
		{ name = "Bind2", size = Vector3.new(0.58, 0.16, 0.56), at = Vector3.new(0, 1.12, 0), colour = pal.Bind, rot = Vector3.new(0, 0, -5) },
		-- The shaft TWISTS as it rises, which is what makes the blade above it
		-- read as one grown branch rather than a paddle screwed to a stick.
		{ name = "Shaft1", size = Vector3.new(0.56, 1.60, 0.52), at = Vector3.new(0, 2.30, 0), colour = pal.Wood, rot = Vector3.new(0, 10, -2) },
		{ name = "Shaft2", size = Vector3.new(0.62, 1.50, 0.56), at = Vector3.new(0.04, 3.70, 0.02), colour = pal.Wood, rot = Vector3.new(0, 22, 3) },
		-- Three blade sections, widening then coming back, each turned further.
		{ name = "Blade1", size = Vector3.new(1.44, 1.50, 0.38), at = Vector3.new(0.06, 5.05, 0.02), colour = pal.Wood, rot = Vector3.new(0, 30, -2) },
		{ name = "Blade2", size = Vector3.new(1.92, 1.60, 0.34), at = Vector3.new(0.10, 6.35, 0.02), colour = pal.Wood, rot = Vector3.new(0, 38, 3) },
		{ name = "Blade3", size = Vector3.new(1.36, 1.20, 0.30), at = Vector3.new(0.14, 7.50, 0), colour = pal.Wood, rot = Vector3.new(0, 44, -4) },
		{ name = "BladeTip", size = Vector3.new(0.78, 0.60, 0.28), at = Vector3.new(0.16, 8.20, 0), colour = dark, rot = Vector3.new(0, 48, -6) },
		-- Fringe down ONE edge. A paddle trimmed on both sides is a paddle.
		{ name = "Fringe1", size = Vector3.new(0.30, 0.44, 0.22), at = Vector3.new(-0.84, 5.40, 0.16), colour = pal.Accent, rot = Vector3.new(0, 30, -24) },
		{ name = "Fringe2", size = Vector3.new(0.34, 0.52, 0.24), at = Vector3.new(-1.02, 6.40, 0.14), colour = pal.Accent, rot = Vector3.new(0, 38, -18) },
		{ name = "Fringe3", size = Vector3.new(0.26, 0.38, 0.20), at = Vector3.new(-0.80, 7.30, 0.12), colour = pal.Accent, rot = Vector3.new(0, 44, -28) },
		{ name = "Moss", size = Vector3.new(0.52, 0.44, 0.30), at = Vector3.new(0.62, 6.00, -0.18), colour = pal.Accent:Lerp(BLACK, 0.18), rot = Vector3.new(12, 38, 16) },
		{ name = "Vine", size = Vector3.new(0.15, 1.90, 0.15), at = Vector3.new(-0.24, 3.30, 0.24), colour = pal.Accent, rot = Vector3.new(20, 24, -28) },
	}
	return specs
end

local function cindercrackSpecs(pal: WeaponData.Palette): { Spec }
	local glow = pal.Glow or pal.Accent
	local specs: { Spec } = {
		{ name = "Handle", size = Vector3.new(0.60, 1.50, 0.60), at = Vector3.new(0, 0.75, 0), colour = pal.Wood:Lerp(BLACK, 0.35) },
		{ name = "Bind1", size = Vector3.new(0.70, 0.26, 0.70), at = Vector3.new(0, 0.40, 0), colour = pal.Bind, rot = Vector3.new(0, 0, 4) },
		{ name = "Bind2", size = Vector3.new(0.70, 0.24, 0.70), at = Vector3.new(0, 1.20, 0), colour = pal.Bind, rot = Vector3.new(0, 0, -5) },
		{ name = "Shaft", size = Vector3.new(0.88, 1.80, 0.82), at = Vector3.new(0, 2.40, 0), colour = pal.Wood, rot = Vector3.new(0, 0, -2) },
		{ name = "Body", size = Vector3.new(1.26, 2.00, 1.16), at = Vector3.new(0.04, 4.20, 0.02), colour = pal.Wood, rot = Vector3.new(0, 4, 3) },
		{ name = "Head", size = Vector3.new(1.48, 1.55, 1.32), at = Vector3.new(0.02, 5.90, 0), colour = pal.Wood, rot = Vector3.new(0, -6, -2) },
		{ name = "Crown", size = Vector3.new(1.16, 0.44, 1.06), at = Vector3.new(0.02, 6.80, 0), colour = pal.Wood:Lerp(BLACK, 0.30), rot = Vector3.new(0, -6, -2) },
		-- A chunk missing from one shoulder. Deliberately not mirrored.
		{ name = "Chip", size = Vector3.new(0.56, 0.52, 0.50), at = Vector3.new(-0.62, 6.35, 0.42), colour = pal.Wood:Lerp(BLACK, 0.45), rot = Vector3.new(28, 20, 34) },
		{ name = "Scorch", size = Vector3.new(0.72, 0.62, 0.16), at = Vector3.new(0, 3.60, 0.60), colour = pal.Wood:Lerp(BLACK, 0.55), rot = Vector3.new(0, 0, 14) },
		-- The cracks. Neon, thin, and running with the grain rather than across
		-- it -- a lattice of them would read as a net thrown over the bat.
		{ name = "Crack1", size = Vector3.new(0.10, 1.30, 0.10), at = Vector3.new(0.42, 4.30, 0.56), colour = glow, rot = Vector3.new(0, 0, 12), material = Enum.Material.Neon },
		{ name = "Crack2", size = Vector3.new(0.09, 0.90, 0.09), at = Vector3.new(0.60, 5.60, 0.30), colour = glow, rot = Vector3.new(0, 22, -18), material = Enum.Material.Neon },
		{ name = "Crack3", size = Vector3.new(0.08, 1.05, 0.08), at = Vector3.new(-0.52, 4.80, 0.50), colour = glow, rot = Vector3.new(0, -16, 20), material = Enum.Material.Neon },
		{ name = "Crack4", size = Vector3.new(0.09, 0.70, 0.09), at = Vector3.new(0.10, 6.20, 0.64), colour = glow, rot = Vector3.new(0, 0, -8), material = Enum.Material.Neon },
		{ name = "Crack5", size = Vector3.new(0.08, 0.62, 0.08), at = Vector3.new(-0.34, 2.70, 0.42), colour = glow, rot = Vector3.new(0, 0, 26), material = Enum.Material.Neon },
		{ name = "Ember1", size = Vector3.new(0.16, 0.16, 0.16), at = Vector3.new(0.74, 5.05, 0.20), colour = pal.Accent, material = Enum.Material.Neon },
		{ name = "Ember2", size = Vector3.new(0.13, 0.13, 0.13), at = Vector3.new(-0.66, 3.90, 0.34), colour = pal.Accent, material = Enum.Material.Neon },
	}
	return specs
end

local function cometSpecs(pal: WeaponData.Palette): { Spec }
	local glow = pal.Glow or pal.Accent
	local specs: { Spec } = {
		{ name = "Handle", size = Vector3.new(0.46, 1.40, 0.46), at = Vector3.new(0, 0.70, 0), colour = pal.Wood:Lerp(BLACK, 0.30) },
		{ name = "Bind", size = Vector3.new(0.56, 0.22, 0.56), at = Vector3.new(0, 1.42, 0), colour = pal.Bind, rot = Vector3.new(0, 0, 5) },
		-- A CONTINUOUS taper, four segments, no two the same width. This is the
		-- one weapon whose silhouette is the whole design.
		{ name = "Taper1", size = Vector3.new(0.58, 1.60, 0.54), at = Vector3.new(0, 2.30, 0), colour = pal.Wood, rot = Vector3.new(0, 4, -2) },
		{ name = "Taper2", size = Vector3.new(0.78, 1.60, 0.70), at = Vector3.new(0.03, 3.85, 0), colour = pal.Wood, rot = Vector3.new(0, -5, 3) },
		{ name = "Taper3", size = Vector3.new(1.00, 1.50, 0.90), at = Vector3.new(0.02, 5.35, 0.02), colour = pal.Wood, rot = Vector3.new(0, 6, -2) },
		{ name = "Tip", size = Vector3.new(0.74, 0.62, 0.66), at = Vector3.new(0.02, 6.30, 0.02), colour = pal.Bind, rot = Vector3.new(0, 6, -2) },
		{ name = "Ring", size = Vector3.new(1.14, 0.16, 1.04), at = Vector3.new(0.02, 4.70, 0), colour = pal.Bind, rot = Vector3.new(6, 0, 14) },
		{ name = "Rim", size = Vector3.new(0.92, 0.13, 0.84), at = Vector3.new(0.02, 5.95, 0), colour = pal.Accent, rot = Vector3.new(-4, 0, 10), material = Enum.Material.Neon },
	}
	--==========================================================================
	-- THE TRAIL RUNS OFF THE HEAD, NOT ROUND IT
	--
	-- Six shards on a rising diagonal behind the tip, each smaller and more
	-- transparent than the last. It says which way the bat is going, which is
	-- also the direction it launches -- so the art and the LAUNCH agree, the
	-- same rule the guardian swipe follows.
	--==========================================================================
	for i = 1, 6 do
		local t = i / 6
		table.insert(specs, {
			name = "Trail" .. i,
			size = Vector3.new(0.40 - 0.05 * i, 0.40 - 0.05 * i, 0.40 - 0.05 * i),
			at = Vector3.new(-0.30 - 0.44 * i, 6.05 - 0.30 * i, -0.16 - 0.20 * i),
			colour = glow,
			rot = Vector3.new(0, 34 * t, 40 * t),
			material = Enum.Material.Neon,
			transparency = 0.10 + 0.11 * i,
		} :: Spec)
	end
	return specs
end

--==============================================================================
-- THE TRAP, FOLDED
--
-- What you carry. Shut, compact, and recognisably the same object that ends up
-- on the road -- so a player looking at the thing in their hand and the thing
-- they placed does not have to be told they are the same item.
--==============================================================================
local function trapCarrySpecs(pal: WeaponData.Palette): { Spec }
	local glow = pal.Glow or pal.Accent
	local specs: { Spec } = {
		{ name = "Handle", size = Vector3.new(0.44, 1.10, 0.44), at = Vector3.new(0, 0.55, 0), colour = pal.Wood:Lerp(BLACK, 0.25) },
		{ name = "Plate", size = Vector3.new(1.60, 0.26, 1.44), at = Vector3.new(0, 1.28, 0), colour = pal.Wood, rot = Vector3.new(0, 8, 0) },
		{ name = "RimA", size = Vector3.new(0.26, 0.28, 1.50), at = Vector3.new(0.70, 1.32, 0), colour = pal.Wood:Lerp(BLACK, 0.30), rot = Vector3.new(0, 8, 4) },
		{ name = "RimB", size = Vector3.new(0.24, 0.26, 1.34), at = Vector3.new(-0.68, 1.30, 0.04), colour = pal.Wood:Lerp(BLACK, 0.30), rot = Vector3.new(0, 8, -5) },
		{ name = "JawShut", size = Vector3.new(1.30, 0.34, 0.30), at = Vector3.new(0, 1.58, 0), colour = pal.Bind, rot = Vector3.new(0, 8, 3) },
		{ name = "Tooth1", size = Vector3.new(0.16, 0.34, 0.16), at = Vector3.new(-0.42, 1.80, 0), colour = pal.Bind:Lerp(BLACK, 0.2), rot = Vector3.new(0, 0, 14) },
		{ name = "Tooth2", size = Vector3.new(0.15, 0.30, 0.15), at = Vector3.new(0.02, 1.80, 0.02), colour = pal.Bind:Lerp(BLACK, 0.2), rot = Vector3.new(0, 0, -8) },
		{ name = "Tooth3", size = Vector3.new(0.14, 0.26, 0.14), at = Vector3.new(0.44, 1.78, 0), colour = pal.Bind:Lerp(BLACK, 0.2), rot = Vector3.new(0, 0, 18) },
		{ name = "Seed", size = Vector3.new(0.40, 0.40, 0.40), at = Vector3.new(0, 1.44, 0.02), colour = glow, material = Enum.Material.Neon, shape = Enum.PartType.Ball },
	}
	return specs
end

local BUILDERS: { [string]: (WeaponData.Palette) -> { Spec } } = {
	rootwood_bat = rootwoodSpecs,
	cactus_club = cactusSpecs,
	sunflower_bonker = sunflowerSpecs,
	mirewood_paddle = mirewoodSpecs,
	cindercrack_bat = cindercrackSpecs,
	comet_bat = cometSpecs,
	bramblejaw_trap = trapCarrySpecs,
}

--==============================================================================
-- BUILD ONE, INTO ANYTHING
--
-- Returns the grip. Everything else is welded to it, so the caller has a single
-- part to anchor, weld to a hand, or hand to a camera.
--==============================================================================
function WeaponModel.BuildInto(item: Item, container: Instance, base: CFrame?): BasePart
	local at = base or CFrame.new()
	local make = BUILDERS[item.Id]
	assert(make, "no geometry for weapon " .. tostring(item.Id))
	local specs = make(item.Palette)
	assert(#specs > 0, item.Id .. " built nothing")

	local grip: BasePart? = nil
	for _, spec in ipairs(specs) do
		local p = piece(container, at, spec)
		if grip == nil then
			grip = p
		else
			weld(grip :: BasePart, p)
		end
	end
	return grip :: BasePart
end

--==============================================================================
-- THE TOOL
--
-- One Tool, one Handle, and the Handle IS the grip the geometry was built
-- around -- so `Tool.Grip` orients the whole weapon by orienting one part.
--
-- The ITEM ID IS AN ATTRIBUTE, and it is what makes this Tool safe to leave in
-- a hotbar full of seed pods. Everything that sweeps the bag reads `SpeciesId`
-- -- EconomyService.SellHeld prices it, CarryService.heldSnapshot saves it,
-- PlantService.PlaceAt plants it -- and a weapon has none, so all three walk
-- past it without a line of code being added to any of them.
--==============================================================================
WeaponModel.ItemAttribute = "WeaponId"

--==============================================================================
-- THE GRIP, SOLVED RATHER THAN TYPED
--
-- The low hold leaves the arm almost exactly where the rig rests it, so the
-- hand's orientation there is a fixed property of the rig. Given that, a grip
-- that puts the barrel on a chosen bearing is arithmetic.
--
-- WHY THIS IS BUILT AS A FRAME AND NOT AS THREE EULER ANGLES. A barrel
-- direction pins only two degrees of freedom; the ROLL about the barrel is
-- free. Solving three Euler angles per weapon therefore lands each one on a
-- different arbitrary branch -- six weapons came back with roll disagreeing by
-- up to 180 degrees, so a paddle showed its edge where a bat showed its face.
-- Building the frame explicitly pins the roll for all of them at once.
--==============================================================================

-- The hand's rotation at the low hold, already multiplied by the hand's own
-- grip socket, read off the live avatar.
--
-- IT IS TIED TO THE LOW-HOLD ARM POSE IN WeaponFX. Change that pose and every
-- barrel below points somewhere new; re-measure this rather than patching the
-- droops to compensate.
local LOW_HOLD_HAND = CFrame.Angles(-1.3782, -0.1217, 0.0107)

-- Where the barrel leaves the fist on the horizontal plane: out to the right
-- and forward, away from the body. A unit vector in (x, z) -- the droop
-- supplies the y.
local BEARING_X, BEARING_Z = 0.4873, -0.8732

-- Where the grip point sits in the palm. Unchanged from the original grip.
local GRIP_OFFSET = CFrame.new(0, -0.35, 0)

--==============================================================================
-- `droopDegrees` is how far below horizontal that barrel hangs. It is per
-- weapon because the weapons are not the same length: the hand sits 1.97 studs
-- above the floor at the low hold and the barrels run 4.37 to 7.80 studs, so
-- the same angle that reads as a relaxed carry on the Cactus drives the
-- Mirewood's blade into the ground.
--==============================================================================
function WeaponModel.GripFor(droopDegrees: number): CFrame
	local s = math.sin(math.rad(droopDegrees))
	local c = math.cos(math.rad(droopDegrees))
	local up = Vector3.new(BEARING_X * c, -s, BEARING_Z * c).Unit
	-- Roll pinned by keeping the weapon's own +X horizontal. Safe because the
	-- barrel is near horizontal here; it would degenerate only if `up` went
	-- vertical, which a droop this small cannot do.
	local right = Vector3.new(0, 1, 0):Cross(up).Unit
	local frame = CFrame.fromMatrix(Vector3.zero, right, up, right:Cross(up))
	return GRIP_OFFSET * (frame:Inverse() * LOW_HOLD_HAND)
end

function WeaponModel.BuildTool(item: Item): Tool
	local tool = Instance.new("Tool")
	tool.Name = item.Name
	tool.ToolTip = item.Blurb
	tool.CanBeDropped = false
	-- Nothing about a weapon needs the mouse, and RequiresHandle stays true so
	-- an unequipped Tool cannot be activated from the backpack.
	tool.RequiresHandle = true
	tool:SetAttribute(WeaponModel.ItemAttribute, item.Id)

	local grip = WeaponModel.BuildInto(item, tool)
	grip.Name = "Handle"

	--==========================================================================
	-- HOW IT SITS IN THE HAND -- AND THIS IS THE ONLY LAYER THAT DECIDES IT
	--
	-- `Tool.Grip` IS the grip weld's C1; verified on the live avatar, where the
	-- engine builds `RightGrip` with C0 = the hand's own socket and
	-- C1 = Tool.Grip, so `handle = hand.CFrame * C0 * C1:Inverse()` to 0.0000
	-- studs. WeaponFX moves the ARM and never writes the weld, so when a barrel
	-- points somewhere wrong there is exactly one place to look.
	--
	-- Every barrel in the shop runs up +Y out of its own Handle -- measured, not
	-- assumed: the far corner of each built weapon lies within 8 degrees of
	-- Handle +Y for all six.
	--==========================================================================
	tool.Grip = WeaponModel.GripFor(tonumber((item :: any).GripDroop) or 0)
	return tool
end

--==============================================================================
-- THE TRAP AS IT LIES ON THE ROAD
--
-- Two hinged jaws on an anchored base. The jaws are Motor6D'd rather than
-- welded because they MOVE -- the opening is the arming, and a trap that
-- appeared already open would give a player no second in which to walk away.
--
-- Anchored base, unanchored massless jaws: exactly the arrangement every
-- guardian rig uses, and the reason a joint can pose the teeth for free.
--==============================================================================
local TRAP_TEETH_LEFT = 5
local TRAP_TEETH_RIGHT = 4

function WeaponModel.BuildTrapWorld(item: Item, cf: CFrame, parent: Instance): Model
	local pal = item.Palette
	local glow = pal.Glow or pal.Accent
	local model = Instance.new("Model")
	model.Name = "BramblejawTrap"

	local base = piece(model, cf, {
		name = "Base",
		size = Vector3.new(2.60, 0.26, 2.40),
		at = Vector3.new(0, 0.13, 0),
		colour = pal.Wood,
		rot = Vector3.new(0, 6, 0),
	})
	base.Anchored = true
	base.Massless = false
	model.PrimaryPart = base

	-- The frame: two root arcs and a low back rail, none of them level.
	for _, spec in ipairs({
		{ n = "RootArcA", s = Vector3.new(0.30, 0.34, 2.50), a = Vector3.new(1.14, 0.24, 0.06), r = Vector3.new(4, 6, 0) },
		{ n = "RootArcB", s = Vector3.new(0.26, 0.30, 2.20), a = Vector3.new(-1.10, 0.22, -0.08), r = Vector3.new(-5, 6, 0) },
		{ n = "BackRail", s = Vector3.new(2.10, 0.22, 0.28), a = Vector3.new(0, 0.24, -1.02), r = Vector3.new(0, 6, 3) },
		{ n = "Bramble1", s = Vector3.new(0.16, 0.44, 0.16), a = Vector3.new(0.88, 0.42, 0.86), r = Vector3.new(24, 20, 18) },
		{ n = "Bramble2", s = Vector3.new(0.14, 0.36, 0.14), a = Vector3.new(-0.94, 0.38, -0.62), r = Vector3.new(-18, 30, -22) },
		{ n = "Bramble3", s = Vector3.new(0.13, 0.30, 0.13), a = Vector3.new(0.34, 0.34, -0.96), r = Vector3.new(14, -12, 26) },
	}) do
		local p = piece(model, cf, {
			name = spec.n, size = spec.s, at = spec.a,
			colour = pal.Wood:Lerp(BLACK, 0.28), rot = spec.r,
		})
		p.Anchored = true
	end

	-- The bait. A sphere, which is what this file reserves them for.
	local seed = piece(model, cf, {
		name = "Seed",
		size = Vector3.new(0.62, 0.62, 0.62),
		at = Vector3.new(0, 0.52, 0),
		colour = glow,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
	})
	seed.Anchored = true

	--==========================================================================
	-- THE JAWS
	--
	-- Each is a spine with teeth welded to it, hinged at the OUTER edge so it
	-- swings up and out. Different tooth counts on the two sides on purpose:
	-- five and four is a mouth, five and five is a machine.
	--==========================================================================
	local function jaw(name: string, side: number, teeth: number): BasePart
		local hingeX = side * 1.00
		local spine = piece(model, cf, {
			name = name,
			size = Vector3.new(0.34, 0.30, 2.10),
			at = Vector3.new(hingeX, 0.30, 0),
			colour = pal.Bind,
			rot = Vector3.new(0, 6, 0),
		})
		for i = 1, teeth do
			local t = (i - 0.5) / teeth
			local len = 0.52 + 0.22 * math.sin(t * math.pi)
			local tooth = piece(model, spine.CFrame, {
				name = name .. "Tooth" .. i,
				size = Vector3.new(0.15, len, 0.15),
				at = Vector3.new(-side * 0.06, 0.16 + len * 0.5, (t - 0.5) * 1.90),
				colour = pal.Accent,
				rot = Vector3.new(0, 0, side * (10 + 6 * math.cos(t * math.pi))),
			})
			weld(spine, tooth)
		end
		local hinge = Instance.new("Motor6D")
		hinge.Name = name .. "Hinge"
		hinge.Part0 = base
		hinge.Part1 = spine
		hinge.C0 = base.CFrame:ToObjectSpace(spine.CFrame)
		hinge.C1 = CFrame.new()
		hinge.Parent = base
		return spine
	end

	jaw("JawL", -1, TRAP_TEETH_LEFT)
	jaw("JawR", 1, TRAP_TEETH_RIGHT)

	model.Parent = parent
	WeaponModel.SetTrapJaw(model, 0)
	return model
end

--==============================================================================
-- HOW FAR OPEN
--
-- 0 is shut, 1 is set. The jaws rotate about their own hinge line, so the teeth
-- ride round with them and nothing has to be repositioned by hand.
--==============================================================================
local JAW_OPEN_DEGREES = 74

function WeaponModel.SetTrapJaw(model: Model, openFraction: number)
	local base = model.PrimaryPart
	if not base then
		return
	end
	local f = math.clamp(openFraction, 0, 1)
	for _, side in ipairs({ { "JawLHinge", 1 }, { "JawRHinge", -1 } }) do
		local hinge = base:FindFirstChild(side[1] :: string)
		if hinge and hinge:IsA("Motor6D") then
			local rest = hinge:GetAttribute("Rest")
			if typeof(rest) ~= "CFrame" then
				rest = hinge.C0
				hinge:SetAttribute("Rest", rest)
			end
			hinge.C0 = (rest :: CFrame)
				* CFrame.Angles(0, 0, math.rad(JAW_OPEN_DEGREES * f * (side[2] :: number)))
		end
	end
end

--==============================================================================
-- THE SHOP PICTURE
--
-- The same geometry, in a Model with its PrimaryPart set so a ViewportFrame can
-- frame it. The trap shows the PLACED form, three quarters open: the card is
-- selling a bear trap, and a folded one on a stick would be selling a stick.
--==============================================================================
function WeaponModel.BuildPreview(item: Item, parent: Instance): Model
	if item.Category == "trap" then
		local model = WeaponModel.BuildTrapWorld(item, CFrame.new(), parent)
		WeaponModel.SetTrapJaw(model, 0.78)
		return model
	end
	local model = Instance.new("Model")
	model.Name = item.Id
	local grip = WeaponModel.BuildInto(item, model)
	model.PrimaryPart = grip
	model.Parent = parent
	return model
end

return WeaponModel
