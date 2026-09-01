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

local FOLDER_NAME = "StarbloomSpeciesMockup"

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

function StarbloomMockupRunner.Build(tierOpt: number?): Folder
	StarbloomMockupRunner.Clear()

	local tier = tierOpt or SeedData.BaseTier or 1

	local gallery = Instance.new("Folder")
	gallery.Name = FOLDER_NAME
	gallery.Parent = workspace

	for i, id in ipairs(SPECIES_IDS) do
		local spec = SeedData.Get(id)
		if not spec then
			continue
		end

		local x = START_X + (i - 1) * SPACING_X
		local plinthCF = CFrame.new(x, 0.4, BASE_Z)

		local group = Instance.new("Model")
		group.Name = string.format("Species%02d_%s", i, spec.Name)
		group.Parent = gallery

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

	print(string.format("[Seed/StarbloomMockupRunner] Successfully built Starbloom showroom gallery at Tier %d (%d species) in Workspace.", tier, TOTAL_SPECIES))
	return gallery
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
	local initialPartCFrames: { [BasePart]: CFrame } = {}

	for i, id in ipairs(SPECIES_IDS) do
		local group = gallery:FindFirstChild(string.format("Species%02d_%s", i, SeedData.Get(id).Name))
		if group then
			local plant = group:FindFirstChildWhichIsA("Model")
			if plant and plant:IsA("Model") then
				local prim = plant.PrimaryPart
				if prim then
					baseOffsets[plant] = prim.CFrame
				end
				for _, p in ipairs(plant:GetDescendants()) do
					if p:IsA("BasePart") then
						initialPartCFrames[p] = p.CFrame
					end
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
				local strollAngle = t * 0.8
				local wanderRadius = 1.6
				local strollX = math.cos(strollAngle) * wanderRadius
				local strollZ = math.sin(strollAngle) * wanderRadius
				local strideBob = math.abs(math.sin(t * 3.5)) * 0.28
				local yaw = -strollAngle + math.pi * 0.5
				local targetCF = rootCF * CFrame.new(strollX, strideBob, strollZ) * CFrame.Angles(0, yaw, 0)
				plant:PivotTo(targetCF)

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
