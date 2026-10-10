--!strict
--==============================================================================
-- Steal a Seed :: DewberryModel (2026-10-11, Enchanted Mist)
--
-- The Dewberry, built in code from Codex's approved builder
-- (output/models/dewberry/Dewberry.command.luau, "Codex.Dewberry.v1" -- the
-- model the owner keeps in ServerStorage.ENCHANTED MIST): three interlocking
-- cores, twelve peel facets, a bent stem, three tapered leaves, three neon dew
-- beads and a glint, a soft mint PointLight. Art only: no logic, no script.
-- Everything anchored, nothing collides, touches or is found by a ray. The
-- pivot sits at the floor; `Root` (the PrimaryPart) carries the
-- `PickupAnchor` attachment at mid-height, where a prompt hangs.
--==============================================================================
local DewberryModel = {}

DewberryModel.BuilderId = "Codex.Dewberry.v1"

local COLOR = {
	Fruit = Color3.fromRGB(109, 197, 157),
	Lower = Color3.fromRGB(64, 145, 111),
	Upper = Color3.fromRGB(156, 221, 172),
	Leaf = Color3.fromRGB(86, 150, 66),
	Stem = Color3.fromRGB(124, 182, 92),
	Dew = Color3.fromRGB(180, 255, 225),
	Glint = Color3.fromRGB(244, 255, 239),
}

-- `at` is the floor point and facing; `scale` 1 is the approved size (about
-- 2.1 x 2.4 x 1.9 studs). Without a `parent` the model is left unparented, for
-- the caller to finish (a prompt, attributes) before it replicates.
function DewberryModel.build(at: CFrame, parent: Instance?, scale: number?): Model
	local k = scale or 1
	local model = Instance.new("Model")
	model.Name = "Dewberry"
	model:SetAttribute("BuilderId", DewberryModel.BuilderId)
	local pieces: { BasePart } = {}

	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, kind: string?, smooth: boolean?,
		neon: boolean?): BasePart
		local p: BasePart
		if kind == "wedge" then
			p = Instance.new("WedgePart")
		else
			local block = Instance.new("Part")
			if kind == "ball" then
				block.Shape = Enum.PartType.Ball
			end
			p = block
		end
		p.Name = name
		p.Size = size * k
		p.CFrame = CFrame.new(cf.Position * k) * cf.Rotation
		p.Color = color
		p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = not neon
		local surface = if smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
		p.TopSurface = surface
		p.BottomSurface = surface
		p.LeftSurface = surface
		p.RightSurface = surface
		p.FrontSurface = surface
		p.BackSurface = surface
		p.Parent = model
		table.insert(pieces, p)
		return p
	end

	part("LowerCore", Vector3.new(0.85, 0.85, 0.85), CFrame.new(0, 0.55, 0), COLOR.Lower)
	part("BerryCore", Vector3.new(1.15, 0.9, 1.1), CFrame.new(0, 1.05, 0), COLOR.Fruit)
	part("UpperCore", Vector3.new(1.05, 0.6, 1), CFrame.new(0, 1.6, 0), COLOR.Upper)

	local frontCF = CFrame.identity
	for i = 0, 5 do
		local turn = CFrame.Angles(0, i * math.pi / 3, 0)
		part("LowerPeel" .. i, Vector3.new(0.72, 1.05, 0.46),
			turn * CFrame.new(0, 0.65, 0.48) * CFrame.Angles(math.rad(17), 0, 0), COLOR.Lower)
		local upperCF = turn * CFrame.new(0, 1.43, 0.54) * CFrame.Angles(math.rad(-21), 0, 0)
		part("UpperPeel" .. i, Vector3.new(0.86, 0.97, 0.48), upperCF, COLOR.Fruit)
		if i == 3 then
			frontCF = upperCF
		end
	end

	part("Stem", Vector3.new(0.18, 0.48, 0.18), CFrame.new(0.03, 2.04, 0.02) * CFrame.Angles(0, 0, math.rad(-12)),
		COLOR.Stem)
	part("StemTip", Vector3.new(0.16, 0.23, 0.16), CFrame.new(0.085, 2.31, 0.02) * CFrame.Angles(0, 0, math.rad(-22)),
		COLOR.Stem)

	local function leaf(name: string, yaw: number, pitch: number, length: number, width: number): CFrame
		local cf = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(0, 2.12, -length * 0.30)
			* CFrame.Angles(math.rad(pitch), 0, 0)
		local halfSize = Vector3.new(0.12, width * 0.5, length)
		part(name .. "Left", halfSize, cf * CFrame.new(-width * 0.25, 0, 0) * CFrame.Angles(0, 0, math.pi / 2),
			COLOR.Leaf, "wedge")
		part(name .. "Right", halfSize, cf * CFrame.new(width * 0.25, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2),
			COLOR.Leaf, "wedge")
		part(name .. "Vein", Vector3.new(0.045, 0.04, length * 0.78), cf * CFrame.new(0, 0.075, 0), COLOR.Stem, nil,
			true)
		return cf
	end
	local mainLeafCF = leaf("MainLeaf", -32, 23, 1.12, 0.67)
	leaf("SideLeaf", 102, 13, 0.86, 0.55)
	leaf("BackLeaf", 223, 30, 0.72, 0.48)

	local dew = part("MainDew", Vector3.new(0.28, 0.28, 0.28), frontCF * CFrame.new(-0.19, 0.13, 0.26), COLOR.Dew,
		"ball", true, true)
	part("MainGlint", Vector3.new(0.06, 0.06, 0.06), frontCF * CFrame.new(-0.235, 0.19, 0.36), COLOR.Glint, "ball",
		true)
	part("SmallDew", Vector3.new(0.17, 0.17, 0.17), frontCF * CFrame.new(0.24, -0.12, 0.25), COLOR.Dew, "ball", true,
		true)
	part("CrownDew", Vector3.new(0.15, 0.15, 0.15), mainLeafCF * CFrame.new(0.10, 0.13, -0.18), COLOR.Dew, "ball",
		true, true)

	local light = Instance.new("PointLight")
	light.Color = COLOR.Dew
	light.Brightness = 0.35
	light.Range = math.min(6 * k, 24)
	light.Shadows = false
	light.Parent = dew

	-- Centre it over the floor point, its lowest corner on the floor.
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in ipairs(pieces) do
		local half = p.Size * 0.5
		for _, x in ipairs({ -1, 1 }) do
			for _, y in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					local q = p.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
					lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
					hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
				end
			end
		end
	end
	local shift = Vector3.new(-(lo.X + hi.X) * 0.5, -lo.Y, -(lo.Z + hi.Z) * 0.5)
	for _, p in ipairs(pieces) do
		p.CFrame = p.CFrame + shift
	end
	local size = hi - lo

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.05, 0.05, 0.05)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CastShadow = false
	root.Parent = model
	local anchor = Instance.new("Attachment")
	anchor.Name = "PickupAnchor"
	anchor.Position = Vector3.new(0, size.Y * 0.5, 0)
	anchor.Parent = root
	model.PrimaryPart = root
	model.WorldPivot = CFrame.identity
	model:PivotTo(at)
	model:SetAttribute("ReferenceSize", size)
	model.Parent = parent
	return model
end

return DewberryModel
