--!strict
--==============================================================================
-- Steal a Seed :: StarbloomMockupRunner
--
-- Builds an exhibition showroom gallery of all 5 Starbloom (Biome 5) species
-- side-by-side on dedicated cosmic pedestals with exhibition placards,
-- starlight lanterns, and live cosmic particles for inspection.
--
-- Routes through CreatureModel.Build so real scale, girth, primary parts, and
-- hierarchy matches live production game plants.
--==============================================================================

local StarbloomMockupRunner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local StarterPlayer = game:GetService("StarterPlayer")

local FOLDER_NAME = "StarbloomSpeciesMockup"

--==============================================================================
-- THE WALK, MIRRORED OFF PlantSway -- AND READ OUT OF IT, NOT COPIED FROM IT
--
-- The showroom used to slide each plant round a small circle and call it motion.
-- Nothing in it touched the legs, which is exactly the half of the animation an
-- anatomy review has to see: PlantSway swings a whole limb rigidly about ONE hip
-- frame per leg, so a joint that is shut at rest stays shut through the stride
-- -- unless a part landed on the wrong hip, in which case it swings in antiphase
-- and tears off. That failure is invisible in a still and obvious in a step.
--
-- The vocabulary and the swing angle are read out of PlantSway's own Source at
-- build time rather than written down again here. A rename there changes what
-- this preview shows on the next run instead of quietly making it a lie.
--
-- IT RUNS IN EDIT, on plants that PlantSway itself will never see -- the client
-- script does not run in the Edit datamodel, and these models are not in a plot.
-- That is the whole reason it exists.
--==============================================================================
local function swaySource(): string
	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	if scripts then
		for _, d in ipairs(scripts:GetChildren()) do
			if string.find(d.Name, "PlantSway") and d:IsA("LuaSourceContainer") then
				return d.Source
			end
		end
	end
	return ""
end

local function legVocabulary(): ({ string }, number)
	local src = swaySource()
	local words = {}
	local block = string.match(src, "local LEG_WORDS = (%b{})")
	if block then
		for w in string.gmatch(block, '"([%w]+)"') do
			table.insert(words, w)
		end
	end
	if #words == 0 then
		warn("[Seed/StarbloomMockupRunner] could not read LEG_WORDS from PlantSway;"
			.. " the preview will not swing any legs")
	end
	local swing = tonumber(string.match(src, "local LEG_SWING = math%.rad%((%d+%.?%d*)%)"))
	return words, math.rad(swing or 21)
end

--==============================================================================
-- ONE HIP PER LEG, AND EVERY PART ON THE NEAREST ONE
--
-- Same order, same constants and same tie-breaks as PlantSway. Exported because
-- tools/tests/StarbloomLimbSpec.luau measures against it: one mirror that the
-- preview and the measurements share cannot disagree with itself, where two
-- would drift apart the first time either was tuned.
--==============================================================================
function StarbloomMockupRunner.RigOf(model: Model)
	local words, swing = legVocabulary()
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local h = d.Size * 0.5
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
						hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
					end
				end
			end
		end
	end

	local pivot = model:GetPivot()
	local inverse = pivot:Inverse()
	local legParts = {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then
			for _, w in ipairs(words) do
				if string.find(d.Name, w) then
					table.insert(legParts, { part = d, cf = inverse * d.CFrame })
					break
				end
			end
		end
	end

	local hasUpper = false
	for _, it in ipairs(legParts) do
		local n = it.part.Name
		if string.find(n, "Thigh") or string.find(n, "Femur") or string.find(n, "Haunch") then
			hasUpper = true
			break
		end
	end
	local rig = { pivot = pivot, swing = swing, hips = {}, parts = legParts, words = words }
	if #legParts == 0 or not hasUpper then
		return rig
	end

	local spread = math.max(hi.X - lo.X, hi.Z - lo.Z)
	local yLo, yHi = math.huge, -math.huge
	for _, it in ipairs(legParts) do
		yLo = math.min(yLo, it.cf.Position.Y)
		yHi = math.max(yHi, it.cf.Position.Y)
	end
	local hipLine = yLo + (yHi - yLo) * 0.55
	local hipNear = math.max(spread * 0.12, 0.25)

	local hips = {}
	for _, it in ipairs(legParts) do
		if it.cf.Position.Y >= hipLine then
			local p = it.cf.Position
			local found = nil
			for _, h in ipairs(hips) do
				local dx, dz = h.x - p.X, h.z - p.Z
				if dx * dx + dz * dz <= hipNear * hipNear then
					found = h
					break
				end
			end
			if found then
				local n = found.n
				found.x = (found.x * n + p.X) / (n + 1)
				found.z = (found.z * n + p.Z) / (n + 1)
				found.top = math.max(found.top, p.Y + it.part.Size.Y * 0.5)
				found.n = n + 1
			else
				table.insert(hips, { x = p.X, z = p.Z, n = 1,
					top = p.Y + it.part.Size.Y * 0.5, items = {} })
			end
		end
	end

	local ranked = table.clone(hips)
	table.sort(ranked, function(a, b)
		return a.z < b.z
	end)
	local bandGap = math.max(spread * 0.15, 0.30)
	local rank, prevZ = 0, nil
	for _, h in ipairs(ranked) do
		if prevZ == nil or h.z - prevZ > bandGap then
			rank += 1
		end
		prevZ = h.z
		h.rank = rank
		h.phase = math.pi * ((rank + (if h.x < 0 then 0 else 1)) % 2)
	end

	for _, it in ipairs(legParts) do
		local p = it.cf.Position
		local best, bestD, secondD = nil, math.huge, math.huge
		for _, h in ipairs(hips) do
			local dx, dz = h.x - p.X, h.z - p.Z
			local d = dx * dx + dz * dz
			if d < bestD then
				secondD = bestD
				bestD, best = d, h
			elseif d < secondD then
				secondD = d
			end
		end
		it.margin = if secondD < math.huge then math.sqrt(secondD / math.max(bestD, 1e-9)) else math.huge
		table.insert((best :: any).items, it)
	end

	for _, h in ipairs(hips) do
		h.frame = CFrame.new(h.x, h.top, h.z)
		local inv = h.frame:Inverse()
		for _, it in ipairs(h.items) do
			it.rel = inv * it.cf
		end
	end

	rig.hips = hips
	rig.hipLine = hipLine
	rig.hipNear = hipNear
	rig.spread = spread
	return rig
end

--==============================================================================
-- PUT A PLANT AT A MOMENT OF ITS OWN STRIDE
--
-- `target` is where the model stands, `phase` is how far through the cycle it
-- is, and `amount` scales the swing so 0 is the rest pose and 1 both extremes.
-- Written exactly as PlantSway writes it, including the order of the multiply:
-- hip, then the swing, then the part's rest offset from the hip.
--==============================================================================
function StarbloomMockupRunner.PoseLegs(model: Model, rig, target: CFrame,
	phase: number, amount: number)
	model:PivotTo(target)
	for _, h in ipairs(rig.hips) do
		local a = math.sin(phase + h.phase) * rig.swing * amount
		for _, it in ipairs(h.items) do
			it.part.CFrame = target * h.frame * CFrame.Angles(a, 0, 0) * it.rel
		end
	end
end

-- Exhibition layout parameters (open lawn display platform)
local BASE_Z = 70
local SPACING_X = 18
local SPECIES_IDS = { "novaorb", "cosmospire", "voidpetal", "astralhorn", "supernovus" }
local TOTAL_SPECIES = #SPECIES_IDS
local START_X = -((TOTAL_SPECIES - 1) * SPACING_X) * 0.5

local RARITY_COLORS = {
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 185, 45),
	Mythic = Color3.fromRGB(255, 75, 110),
}

local DESCRIPTIONS = {
	novaorb = "Rotund alien toad-biped with muscular jumping legs, glowing cyan eyes, shoulder leaf fronds & 3 orbiting motes.",
	cosmospire = "Tall 4-legged stilt mantis predator with raptor skull, eye slits, dorsal needle spire & crystal leaf wings.",
	voidpetal = "Prowling void panther predator with 4 feline limbs, 6-petal orchid neck mane, glowing maw & twin leaf tails.",
	astralhorn = "Armored stag-dragon behemoth with 4 heavy pillar legs, beast skull, spine leaf fronds & crystal antlers.",
	supernovus = "Hexapod cosmic dragon titan with 6 walking legs, roaring cosmic maw, dorsal galaxy lotus, giant leaves & orbital ring.",
}

local function makePart(props: {
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	parent: Instance,
	transparency: number?,
	shape: Enum.PartType?,
}): BasePart
	local p = Instance.new("Part")
	p.Name = props.name
	p.Size = props.size
	p.CFrame = props.cf
	p.Color = props.color
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.Anchored = true
	p.CanCollide = true
	p.CastShadow = true
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent
	return p
end

function StarbloomMockupRunner.Clear()
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	print("[Seed/StarbloomMockupRunner] Cleared StarbloomSpeciesMockup from Workspace")
end

--==============================================================================
-- ONE STAGE, ONE OR MORE ROWS
--
-- `Build(4)` is the old behaviour. `Build({1, 7})` puts a second row behind the
-- first, which is the only way to see what the size curve does to a joint: a
-- Colossal is fifty times a Tiny in height while the girth curve spreads the
-- parts horizontally by a further twelve per cent, so a seam that is shut at
-- authored scale is not automatically shut at the top of the ladder.
--
-- Only the FIRST row gets plinths, lanterns and placards. A Colossal Cosmospire
-- is 380 studs tall; a twelve-stud plinth under it is not scenery, it is a
-- speck, and the row exists to be measured and looked at rather than exhibited.
-- The row spacing comes off the row's own frame height for the same reason.
--==============================================================================
function StarbloomMockupRunner.Build(tierOpt: (number | { number })?): Folder
	StarbloomMockupRunner.Clear()

	local tiers: { number }
	if type(tierOpt) == "table" then
		tiers = tierOpt
	else
		tiers = { (tierOpt :: number?) or SeedData.BaseTier or 1 }
	end

	local gallery = Instance.new("Folder")
	gallery.Name = FOLDER_NAME
	-- IT MUST NOT REACH THE .rbxl. Everything in this project is built from code
	-- and the place file holds none of it; a showroom that saved itself would be
	-- the one hand-placed thing in the game, and the next session would have no
	-- way to tell it from the real map. `SeedMap` is marked the same way.
	gallery.Archivable = false
	gallery.Parent = workspace

	-- THE GAP BETWEEN ROWS IS THE SUM OF WHAT IS ON EITHER SIDE OF IT, not what
	-- was on the last one. A Colossal is fifty times a Tiny, so advancing by the
	-- row already built put a 460-stud creature 33 studs behind an 8-stud one and
	-- swallowed it whole.
	local rowZ = BASE_Z
	local previous = 0
	for rowIndex, tier in ipairs(tiers) do
		local dressed = rowIndex == 1
		local widest = 0
		for _, id in ipairs(SPECIES_IDS) do
			local sp = SeedData.Get(id)
			if sp then
				widest = math.max(widest, SeedData.FrameHeight(sp, tier))
			end
		end
		if rowIndex > 1 then
			rowZ += (previous + widest) * 0.9 + 30
		end
		local spacing = if dressed then SPACING_X else widest * 0.9
		local startX = -((TOTAL_SPECIES - 1) * spacing) * 0.5
		StarbloomMockupRunner.BuildRow(gallery, tier, rowIndex, rowZ, spacing, startX, dressed)
		previous = widest
	end

	print(string.format(
		"[Seed/StarbloomMockupRunner] Showroom rebuilt: %d row(s), %d species each.",
		#tiers, TOTAL_SPECIES))
	return gallery
end

function StarbloomMockupRunner.BuildRow(gallery: Folder, tier: number, rowIndex: number,
	baseZ: number, SPACING_X: number, START_X: number, dressed: boolean)
	local BASE_Z = baseZ
	for i, id in ipairs(SPECIES_IDS) do
		local spec = SeedData.Get(id)
		if not spec then
			continue
		end

		local x = START_X + (i - 1) * SPACING_X
		local plinthCF = CFrame.new(x, 0.4, BASE_Z)

		local group = Instance.new("Model")
		group.Name = string.format("Row%d_T%d_Species%02d_%s", rowIndex, tier, i, spec.Name)
		group.Parent = gallery

		if not dressed then
			-- A bare row: the creature, on the ground, and nothing to look past.
			local plant = CreatureModel.Build(spec, tier, CreatureModel.STAGE_GROWN,
				CFrame.new(x, 0, BASE_Z), group)
			plant.Name = "Plant_" .. spec.Name
			continue
		end

		-- 1. Cosmic Exhibition Plinth
		local plinth = makePart({
			name = "Plinth",
			size = Vector3.new(12, 0.8, 12),
			cf = plinthCF,
			color = Color3.fromRGB(20, 16, 32),
			material = Enum.Material.Cobblestone,
			parent = group,
		})

		-- Plinth Cyan Neon Border Trim
		makePart({
			name = "PlinthTrim",
			size = Vector3.new(12.3, 0.15, 12.3),
			cf = plinthCF * CFrame.new(0, 0.4, 0),
			color = Color3.fromRGB(110, 230, 255),
			material = Enum.Material.Neon,
			parent = group,
		})

		-- Inner Midnight Slab
		makePart({
			name = "InnerSlab",
			size = Vector3.new(10.2, 0.25, 10.2),
			cf = plinthCF * CFrame.new(0, 0.5, 0),
			color = Color3.fromRGB(34, 28, 54),
			material = Enum.Material.SmoothPlastic,
			parent = group,
		})

		-- 2. Starlight Corner Lanterns
		for _, offset in ipairs({
			Vector3.new(-5.2, 0.8, -5.2),
			Vector3.new( 5.2, 0.8, -5.2),
			Vector3.new(-5.2, 0.8,  5.2),
			Vector3.new( 5.2, 0.8,  5.2),
		}) do
			local post = makePart({
				name = "LanternPost",
				size = Vector3.new(0.35, 1.4, 0.35),
				cf = plinthCF * CFrame.new(offset),
				color = Color3.fromRGB(48, 38, 72),
				material = Enum.Material.Metal,
				parent = group,
			})
			local globe = makePart({
				name = "LanternGlobe",
				size = Vector3.new(0.65, 0.65, 0.65),
				cf = plinthCF * CFrame.new(offset + Vector3.new(0, 0.9, 0)),
				color = Color3.fromRGB(180, 245, 255),
				material = Enum.Material.Neon,
				shape = Enum.PartType.Ball,
				parent = group,
			})
			local pLight = Instance.new("PointLight")
			pLight.Color = Color3.fromRGB(140, 230, 255)
			pLight.Brightness = 0.8
			pLight.Range = 6
			pLight.Parent = globe
		end

		-- 3. The Starbloom Plant Model (Built through CreatureModel)
		local plantBaseCF = plinthCF * CFrame.new(0, 0.62, 0)
		local plantModel = CreatureModel.Build(spec, tier, CreatureModel.STAGE_GROWN, plantBaseCF, group)
		plantModel.Name = "Plant_" .. spec.Name

		-- Count parts and leaves for verification & placard
		local partCount = 0
		local leafCount = 0
		for _, desc in ipairs(plantModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				partCount += 1
			end
		end
		for _, child in ipairs(plantModel:GetChildren()) do
			if child.Name == "Leaf" then
				leafCount += 1
			end
		end

		-- 4. Official Exhibition Placard (In front of each plinth facing -Z)
		local placardCF = plinthCF * CFrame.new(0, 1.3, -5.6) * CFrame.Angles(math.rad(-22), 0, 0)
		local postPlacard = makePart({
			name = "PlacardPost",
			size = Vector3.new(0.35, 1.4, 0.35),
			cf = plinthCF * CFrame.new(0, 0.7, -5.6),
			color = Color3.fromRGB(48, 38, 72),
			material = Enum.Material.Metal,
			parent = group,
		})
		local trim = makePart({
			name = "PlacardTrim",
			size = Vector3.new(6.55, 2.95, 0.1),
			cf = placardCF * CFrame.new(0, 0, 0.12),
			color = Color3.fromRGB(110, 230, 255),
			material = Enum.Material.Neon,
			parent = group,
		})
		local board = makePart({
			name = "PlacardBoard",
			size = Vector3.new(6.4, 2.8, 0.25),
			cf = placardCF,
			color = Color3.fromRGB(18, 14, 28),
			material = Enum.Material.SmoothPlastic,
			parent = group,
		})

		-- Placard UI Billboard
		local sGui = Instance.new("SurfaceGui")
		sGui.Name = "InfoUI"
		sGui.Face = Enum.NormalId.Front
		sGui.AlwaysOnTop = true
		sGui.CanvasSize = Vector2.new(480, 220)
		sGui.LightInfluence = 0
		sGui.Parent = board

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
		frame.BorderSizePixel = 0
		frame.Parent = sGui

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 10)
		pad.PaddingBottom = UDim.new(0, 10)
		pad.PaddingLeft = UDim.new(0, 14)
		pad.PaddingRight = UDim.new(0, 14)
		pad.Parent = frame

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 28)
		title.BackgroundTransparency = 1
		title.Text = string.format("%d. %s", i, spec.Name:upper())
		title.TextColor3 = RARITY_COLORS[spec.Rarity] or Color3.fromRGB(255, 255, 255)
		title.TextSize = 22
		title.Font = Enum.Font.GothamBold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = frame

		local tierName = SeedData.TierName and SeedData.TierName(tier) or ("Tier " .. tostring(tier))
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, 0, 0, 18)
		rarityLabel.Position = UDim2.new(0, 0, 0, 30)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = string.format("%s // Tier %d (%s) // Frame Height: %.1f studs", spec.Rarity:upper(), tier, tierName, SeedData.FrameHeight and SeedData.FrameHeight(spec, tier) or spec.Height)
		rarityLabel.TextColor3 = Color3.fromRGB(160, 210, 255)
		rarityLabel.TextSize = 13
		rarityLabel.Font = Enum.Font.GothamMedium
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.Parent = frame

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(1, 0, 0, 16)
		statsLabel.Position = UDim2.new(0, 0, 0, 50)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Text = string.format("Parts: %d (Budget: 25-40) | Leaves: %d | PrimaryPart: %s", partCount, leafCount, plantModel.PrimaryPart and plantModel.PrimaryPart.Name or "NONE")
		statsLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
		statsLabel.TextSize = 12
		statsLabel.Font = Enum.Font.Gotham
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = frame

		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.new(0, 0, 0, 70)
		divider.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
		divider.BorderSizePixel = 0
		divider.Parent = frame

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 0, 70)
		desc.Position = UDim2.new(0, 0, 0, 76)
		desc.BackgroundTransparency = 1
		desc.Text = DESCRIPTIONS[id] or "Cosmic endgame entity with articulated limbs and alien leaves."
		desc.TextColor3 = Color3.fromRGB(220, 215, 235)
		desc.TextSize = 13
		desc.Font = Enum.Font.Gotham
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Parent = frame
	end
end

--==============================================================================
-- FREEZE THE WHOLE SHOWROOM AT ONE MOMENT OF THE STRIDE
--
--   Pose(0)     rest -- what a still screenshot of a standing plant looks like
--   Pose(0.25)  one extreme: the sine is at +1, so every leg is at full swing
--   Pose(-0.25) the other
--
-- Both extremes matter and neither is the mirror of the other, because the legs
-- carry two phases: at +1 the left front and right rear are forward, at -1 they
-- are back, and a joint can only be judged open or shut with a specific leg in a
-- specific place.
--==============================================================================
function StarbloomMockupRunner.Pose(k: number?)
	local gallery = workspace:FindFirstChild(FOLDER_NAME)
	if not gallery then
		warn("[Seed/StarbloomMockupRunner] Gallery not found! Run Build() first.")
		return
	end
	local turn = math.pi * 2 * (k or 0)
	local n = 0
	for _, group in ipairs(gallery:GetChildren()) do
		local plant = group:FindFirstChildWhichIsA("Model")
		if plant then
			local rig = StarbloomMockupRunner.RigOf(plant)
			StarbloomMockupRunner.PoseLegs(plant, rig, plant:GetPivot(), turn,
				if (k or 0) == 0 then 0 else 1)
			n += 1
		end
	end
	print(string.format("[Seed/StarbloomMockupRunner] Posed %d plants at k=%.2f", n, k or 0))
end

--==============================================================================
-- LIVE MOTION SIMULATION
--==============================================================================
local simConnection: RBXScriptConnection? = nil

function StarbloomMockupRunner.Simulate(enable: boolean)
	if simConnection then
		simConnection:Disconnect()
		simConnection = nil
	end

	if not enable then
		print("[Seed/StarbloomMockupRunner] Motion simulation stopped.")
		return
	end

	local gallery = workspace:FindFirstChild(FOLDER_NAME)
	if not gallery then
		warn("[Seed/StarbloomMockupRunner] Gallery not found! Run Build() first.")
		return
	end

	local baseOffsets: { [Model]: CFrame } = {}
	local rigs: { [Model]: any } = {}
	local initialPartCFrames: { [BasePart]: CFrame } = {}

	for _, group in ipairs(gallery:GetChildren()) do
		local plant = group:FindFirstChildWhichIsA("Model")
		if plant and plant:IsA("Model") then
			baseOffsets[plant] = plant:GetPivot()
			rigs[plant] = StarbloomMockupRunner.RigOf(plant)
			for _, p in ipairs(plant:GetDescendants()) do
				if p:IsA("BasePart") then
					initialPartCFrames[p] = p.CFrame
				end
			end
		end
	end

	local startTime = os.clock()
	simConnection = RunService.Heartbeat:Connect(function()
		local t = os.clock() - startTime
		local gal = workspace:FindFirstChild(FOLDER_NAME)
		if not gal then
			if simConnection then
				simConnection:Disconnect()
				simConnection = nil
			end
			return
		end

		for plant, rootCF in pairs(baseOffsets) do
			if plant.Parent and plant.PrimaryPart then
				--==========================================================
				-- A WALK, NOT A SLIDE
				--
				-- The stroll is scaled to the creature so a Colossal does not
				-- take a Tiny's stride, and the legs run on the same clock the
				-- body bobs to -- which is the point: a foot that beats against
				-- the bob instead of with it reads as a limp however good the
				-- geometry is.
				--==========================================================
				local reach = math.max(plant:GetExtentsSize().Y, 1) * 0.22
				local strollAngle = t * 0.8
				local strollX = math.cos(strollAngle) * reach
				local strollZ = math.sin(strollAngle) * reach
				local strideBob = math.abs(math.sin(t * 3.5)) * reach * 0.04
				local yaw = -strollAngle + math.pi * 0.5
				local targetCF = rootCF * CFrame.new(strollX, strideBob, strollZ) * CFrame.Angles(0, yaw, 0)
				local rig = rigs[plant]
				if rig then
					StarbloomMockupRunner.PoseLegs(plant, rig, targetCF, t * 3.5, 1)
				else
					plant:PivotTo(targetCF)
				end

				for _, part in ipairs(plant:GetDescendants()) do
					if part:IsA("BasePart") and part.Name == "Mote" then
						local orig = initialPartCFrames[part]
						if orig then
							local spin = CFrame.Angles(0, t * 1.8, 0)
							part.CFrame = targetCF * (rootCF:ToObjectSpace(orig)) * spin
						end
					end
				end
			end
		end
	end)

	print("[Seed/StarbloomMockupRunner] Motion simulation active!")
end

return StarbloomMockupRunner
