--!strict
-- Steal a Seed :: PlantSculpt
--
-- The sculpting kit behind the AUTHORED Greenhollow and Dustbowl plants -- the
-- eight rebuilt from the approved concept sheets on 2026-09-18. Not a *Service
-- and not a plant system: CreatureModel still owns every creature, the Forms
-- modules still own every species, and this only makes the parts they ask for.
--
-- WHY IT EXISTS. EmberrootForms and StarbloomForms each carry a private `mk`
-- and a private scale function, and a third and fourth copy for the two biomes
-- that were half converted would have been four copies of the same thirty lines,
-- drifting. The kit is those thirty lines plus the shapes the concept sheets
-- are made of and the engine does not have: a leaf that thins to its tip, a
-- petal that narrows to its tip, a beam between two points, and a chain of beams
-- along a curve.
--
-- THE CONTRACT IS CreatureModel's. A builder authors in MOCKUP SPACE -- ground
-- at Y = 0, front toward -Z, its own studs -- and the kit places every part
-- through the same arithmetic replayPart uses: positions scale by hs (height)
-- and by gs (girth, horizontal only), sizes by hs alone, rotations untouched.
-- So a Colossal is the Tiny's sculpture eight times larger and a tenth broader,
-- never a sheared one.
--
-- STUDS ON EVERYTHING BUT WHAT THE BUILDER SAYS IS SMOOTH -- the art bible's
-- rule, applied exactly as CreatureModel.part applies it: a studded part is
-- Plastic with all six surfaces Studs, because a creature is seen from every
-- side; a smooth one is SmoothPlastic with every surface Smooth.
--
-- WHAT A WEDGE IS, measured (tools/art/bellchime_bloom.luau): a WedgePart is
-- FULL HEIGHT at its local +Z and a knife edge at its local -Z, flat along its
-- -Y face and constant across X. `blade` and `fin` below are that one fact
-- turned two ways.
--
-- EVERY PART IS A DIRECT CHILD OF THE MODEL. PlantSway resolves its arms, legs,
-- roots and eyes from model:GetChildren(), so a part inside a sub-model would
-- be scenery it cannot move.

local PlantSculpt = {}

local SURFACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}
local UP = Vector3.yAxis

export type Opts = {
	smooth: boolean?,
	material: Enum.Material?,
	transparency: number?,
}

-- Where CreatureModel.addFace should put this species' face, already in WORLD
-- terms: the kit scales the mockup frame, width and surface distance so the
-- face lands on the same skin at every tier.
export type Face = {
	cf: CFrame,
	width: number,
	front: number,
	skin: Color3,
}

export type Kit = {
	model: Model,
	place: (CFrame) -> CFrame,
	-- name, size, mockup CFrame, colour
	block: (string, Vector3, CFrame, Color3, Opts?) -> BasePart,
	-- name, diameter, mockup CFrame, colour
	ball: (string, number, CFrame, Color3, Opts?) -> BasePart,
	-- a cylinder standing on its axis: name, diameter, thickness, CFrame, colour
	disc: (string, number, number, CFrame, Color3, Opts?) -> BasePart,
	-- a cylinder facing along Z, a coin seen face-on: name, diameter, thickness
	coin: (string, number, number, CFrame, Color3, Opts?) -> BasePart,
	-- a cylinder from one point to another: name, a, b, diameter, colour
	rod: (string, Vector3, Vector3, number, Color3, Opts?) -> BasePart,
	-- a raw WedgePart: name, size, CFrame, colour
	wedge: (string, Vector3, CFrame, Color3, Opts?) -> BasePart,
	-- a leaf that THINS to its tip: name, from, tip, width, thickness at the
	-- root, the leaf's upward normal, colour. Flat underneath, sloped on top.
	blade: (string, Vector3, Vector3, number, number, Vector3, Color3, Opts?) -> BasePart,
	-- a petal that NARROWS to its tip: name, root, tip, width at the root,
	-- thickness, the petal's normal, which side the width bulges to (+1/-1),
	-- colour. Its straight edge runs root to tip; pairs mirror.
	fin: (string, Vector3, Vector3, number, number, Vector3, number, Color3, Opts?) -> BasePart,
	-- a block from a to b, length along its own Z: name, a, b, width, height,
	-- colour, opts, overrun past each end (hides a joint inside the neighbour)
	beam: (string, Vector3, Vector3, number, number, Color3, Opts?, number?) -> BasePart,
	-- beams along a polyline, named prefix..1, prefix..2, ...: prefix, points,
	-- width, height, taper per segment, colour
	chain: (string, { Vector3 }, number, number, number, Color3, Opts?) -> { BasePart },
	-- mockup face frame, width, surface distance along -Z, lid colour
	face: (CFrame, number, number, Color3) -> Face,
}

-- lookAt with a guard: a hint parallel to the line has no frame in it.
function PlantSculpt.look(from: Vector3, to: Vector3, up: Vector3?): CFrame
	local d = to - from
	if d.Magnitude < 1e-6 then
		return CFrame.new(from)
	end
	local hint = up or UP
	if hint.Magnitude < 1e-6 or math.abs(d.Unit:Dot(hint.Unit)) > 0.999 then
		hint = if math.abs(d.Unit.Y) > 0.9 then Vector3.zAxis else UP
	end
	return CFrame.lookAt(from, to, hint)
end

function PlantSculpt.new(model: Model, at: CFrame, hs: number, gs: number): Kit
	local function place(cf: CFrame): CFrame
		local p = cf.Position
		return at * CFrame.new(p.X * hs * gs, p.Y * hs, p.Z * hs * gs) * (cf - p)
	end

	local function mk(name: string, size: Vector3, cf: CFrame, color: Color3,
		opts: Opts?, kind: string): BasePart
		local p: BasePart
		if kind == "wedge" then
			p = Instance.new("WedgePart")
		else
			local b = Instance.new("Part")
			b.Shape = if kind == "ball" then Enum.PartType.Ball
				elseif kind == "cylinder" then Enum.PartType.Cylinder
				else Enum.PartType.Block
			p = b
		end
		local o: Opts = opts or {}
		local smooth = o.smooth == true
		p.Name = name
		p.Size = size * hs
		p.CFrame = place(cf)
		p.Color = color
		p.Material = o.material or (if smooth then Enum.Material.SmoothPlastic
			else Enum.Material.Plastic)
		p.Transparency = o.transparency or 0
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		local surface = if smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
		for _, f in ipairs(SURFACES) do
			-- A wedge lacks faces a block has, so each write is guarded.
			pcall(function()
				(p :: any)[f] = surface
			end)
		end
		p.Parent = model
		return p
	end

	local kit: Kit
	kit = {
		model = model,
		place = place,

		block = function(name, size, cf, color, opts)
			return mk(name, size, cf, color, opts, "block")
		end,

		ball = function(name, d, cf, color, opts)
			return mk(name, Vector3.new(d, d, d), cf, color, opts, "ball")
		end,

		disc = function(name, d, thick, cf, color, opts)
			-- Roblox cylinders run along their local X; standing one up is a
			-- ninety-degree roll, as CreatureModel.upright does.
			return mk(name, Vector3.new(thick, d, d),
				cf * CFrame.Angles(0, 0, math.rad(90)), color, opts, "cylinder")
		end,

		coin = function(name, d, thick, cf, color, opts)
			return mk(name, Vector3.new(thick, d, d),
				cf * CFrame.Angles(0, math.rad(90), 0), color, opts, "cylinder")
		end,

		rod = function(name, a, b, d, color, opts)
			local len = (b - a).Magnitude
			-- lookAt puts -Z on the line; the yaw turns the cylinder's X onto it.
			return mk(name, Vector3.new(len, d, d),
				PlantSculpt.look((a + b) * 0.5, b) * CFrame.Angles(0, math.rad(90), 0),
				color, opts, "cylinder")
		end,

		wedge = function(name, size, cf, color, opts)
			return mk(name, size, cf, color, opts, "wedge")
		end,

		blade = function(name, from, tip, width, thick, up, color, opts)
			-- -Z toward the tip puts the knife edge there; the flat -Y face is
			-- the underside and the slope faces `up`.
			local len = (tip - from).Magnitude
			return mk(name, Vector3.new(width, thick, len),
				PlantSculpt.look((from + tip) * 0.5, tip, up), color, opts, "wedge")
		end,

		fin = function(name, root, tip, width, thick, normal, side, color, opts)
			local d = tip - root
			local len = d.Magnitude
			local dir = d.Unit
			local across = normal:Cross(dir)
			if across.Magnitude < 1e-6 then
				across = UP:Cross(dir)
			end
			across = across.Unit * (if side < 0 then -1 else 1)
			-- The wedge's Y tapers from full at +Z to nothing at -Z, and its -Y
			-- face is the straight one -- so the box sits half a width to the
			-- bulge side of the root-to-tip line, and that line is its spine.
			local centre = (root + tip) * 0.5 + across * (width * 0.5)
			local vZ = -dir
			local vY = across
			local vX = vY:Cross(vZ)
			return mk(name, Vector3.new(thick, width, len),
				CFrame.fromMatrix(centre, vX, vY, vZ), color, opts, "wedge")
		end,

		beam = function(name, a, b, w, h, color, opts, overrun)
			local o = overrun or 0
			local len = (b - a).Magnitude + o * 2
			return mk(name, Vector3.new(w, h, len),
				PlantSculpt.look((a + b) * 0.5, b), color, opts, "block")
		end,

		chain = function(prefix, points, w0, h0, taper, color, opts)
			local made = {}
			for i = 1, #points - 1 do
				local f = taper ^ (i - 1)
				local w, h = w0 * f, h0 * f
				table.insert(made, kit.beam(prefix .. i, points[i], points[i + 1],
					w, h, color, opts, math.min(w, h) * 0.45))
			end
			return made
		end,

		face = function(cf, width, front, skin)
			return {
				cf = place(cf),
				width = width * hs,
				front = front * hs,
				skin = skin,
			}
		end,
	}
	return kit
end

return PlantSculpt
