--!strict
--==============================================================================
-- Steal a Seed :: StarbloomMockupRunner
--
-- Builds an exhibition showroom gallery of all 5 Starbloom (Biome 5) species
-- side-by-side on dedicated cosmic pedestals with exhibition placards,
-- starlight lanterns, and live cosmic particles for inspection.
--==============================================================================

local StarbloomMockupRunner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local StarbloomForms = require(Shared:WaitForChild("StarbloomForms"))

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
	novaorb = "Rotund alien toad-biped with muscular jumping legs, glowing cyan eyes, shoulder leaf fronds & 4 orbiting motes.",
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

function StarbloomMockupRunner.Build(): Folder
	StarbloomMockupRunner.Clear()

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

		-- 3. The Starbloom Plant Model
		local plantModel = Instance.new("Model")
		plantModel.Name = "Plant_" .. spec.Name
		plantModel.Parent = group

		local plantBaseCF = plinthCF * CFrame.new(0, 0.62, 0)
		StarbloomForms.Build(plantModel, id, plantBaseCF, 1.0)

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
		frame.BackgroundTransparency = 1
		frame.Parent = sGui

		local title = Instance.new("TextLabel")
		title.Position = UDim2.new(0, 12, 0, 10)
		title.Size = UDim2.new(1, -24, 0, 36)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.Text = string.format("%d. %s", i, spec.Name:upper())
		title.TextColor3 = Color3.fromRGB(242, 238, 255)
		title.TextSize = 24
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = frame

		local rarityColor = RARITY_COLORS[spec.Rarity] or Color3.fromRGB(255, 255, 255)
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Position = UDim2.new(0, 12, 0, 48)
		rarityLabel.Size = UDim2.new(1, -24, 0, 24)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Font = Enum.Font.GothamMedium
		rarityLabel.Text = string.format("%s // Height: %.1f studs", spec.Rarity:upper(), StarbloomForms.AuthoredHeight[id] or 5.0)
		rarityLabel.TextColor3 = rarityColor
		rarityLabel.TextSize = 16
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.Parent = frame

		local desc = Instance.new("TextLabel")
		desc.Position = UDim2.new(0, 12, 0, 80)
		desc.Size = UDim2.new(1, -24, 1, -88)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.Text = DESCRIPTIONS[id] or ""
		desc.TextColor3 = Color3.fromRGB(200, 195, 220)
		desc.TextSize = 14
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Parent = frame
	end

	print(string.format("[Seed/StarbloomMockupRunner] Built all %d Starbloom Species mockups at Z = %d", TOTAL_SPECIES, BASE_Z))
	return gallery
end

local simConnection: RBXScriptConnection? = nil

function StarbloomMockupRunner.Simulate(enable: boolean?): boolean
	local RunService = game:GetService("RunService")
	if enable == false then
		if simConnection then
			simConnection:Disconnect()
			simConnection = nil
		end
		print("[Seed/StarbloomMockupRunner] Simulation stopped.")
		return false
	end

	if simConnection then
		simConnection:Disconnect()
		simConnection = nil
	end

	local gallery = workspace:FindFirstChild(FOLDER_NAME)
	if not gallery then
		StarbloomMockupRunner.Build()
		gallery = workspace:FindFirstChild(FOLDER_NAME)
	end
	if not gallery then return false end

	local animated = {}
	for _, group in ipairs(gallery:GetChildren()) do
		local plant = group:FindFirstChildWhichIsA("Model")
		local plinth = group:FindFirstChild("Plinth")
		if plant and plinth then
			local baseCF = plinth.CFrame * CFrame.new(0, 0.62, 0)
			local entry = {
				model = plant,
				group = group,
				baseCF = baseCF,
				walkAngle = math.random() * math.pi * 2,
				walkRadius = 1.4,
				orbitAngle = 0,
				motes = {},
				capacitors = {},
				satellites = {},
			}
			for _, child in ipairs(plant:GetChildren()) do
				if child.Name == "Mote" then
					table.insert(entry.motes, child)
				elseif child.Name == "CapacitorNode" then
					table.insert(entry.capacitors, child)
				elseif child.Name == "CometSatellite" or child.Name == "OrbitalArc" then
					table.insert(entry.satellites, child)
				end
			end
			table.insert(animated, entry)
		end
	end

	local clock = 0
	simConnection = RunService.Heartbeat:Connect(function(dt)
		clock += dt
		for _, e in ipairs(animated) do
			if not e.model.Parent then continue end

			-- 1. Organic stroll & stride bob
			e.walkAngle += dt * 0.35
			local swayX = math.sin(e.walkAngle) * e.walkRadius
			local swayZ = math.cos(e.walkAngle * 0.75) * (e.walkRadius * 0.65)
			local walkStep = math.sin(clock * 3.2) * 0.12
			local lookYaw = math.sin(e.walkAngle * 1.4) * 0.30

			local targetCF = e.baseCF * CFrame.new(swayX, math.abs(walkStep), swayZ) * CFrame.Angles(0, lookYaw, math.sin(clock * 1.8) * 0.035)
			e.model:PivotTo(targetCF)

			-- 2. Orbital motes & satellites
			e.orbitAngle += dt * 1.6
			for i, m in ipairs(e.motes) do
				local a = e.orbitAngle + (i * math.pi * 0.5)
				local orbitOffset = CFrame.Angles(math.rad(15), a, 0) * CFrame.new(0, 0, 1.8)
				m.CFrame = targetCF * CFrame.new(0, 1.8, 0) * orbitOffset
			end

			for i, cap in ipairs(e.capacitors) do
				local a = -e.orbitAngle * 0.8 + (i * math.pi * 0.5)
				local bob = math.sin(clock * 2.2 + i) * 0.18
				local nodeCF = CFrame.Angles(0, a, 0) * CFrame.new(0, bob, 1.25) * CFrame.Angles(math.rad(45), math.rad(45), 0)
				cap.CFrame = targetCF * CFrame.new(0, 3.2, 0) * nodeCF
			end

			for i, sat in ipairs(e.satellites) do
				local a = e.orbitAngle * 1.1 + (i * (math.pi * 2 / #e.satellites))
				local ringTilt = CFrame.new(0, 1.6, 0) * CFrame.Angles(math.rad(22), math.rad(35) + e.orbitAngle * 0.25, 0)
				if sat.Name == "CometSatellite" then
					sat.CFrame = targetCF * CFrame.new(0, 3.8, 0) * ringTilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 2.6)
				elseif sat.Name == "OrbitalArc" then
					sat.CFrame = targetCF * CFrame.new(0, 3.8, 0) * ringTilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 2.2)
				end
			end
		end
	end)

	print("[Seed/StarbloomMockupRunner] Live strolling & orbital kinematics active!")
	return true
end

return StarbloomMockupRunner
