--!strict
--==============================================================================
-- Steal a Seed :: MillMockupRunner
--
-- Builds an exhibition showroom gallery of every Treadmill tier side-by-side
-- at the back of the island (Z = 150) with exhibition plinths, official signs,
-- placards, and live animated belts and particles for inspection and editing.
-- Tiers 11-14 are the owner's own mills (MillForms): wider and longer than the
-- rest, so each plinth is sized to its tier's footprint (2026-10-06).
--==============================================================================

--==============================================================================
-- NOTHING CALLS THIS, AND THAT IS THE POINT
--
-- It was a Script, so it ran on every server start and built ten full mills
-- into Workspace -- during playtests, and in a published game. A Studio gate
-- fixed the published half and left the playtest half, because a Script cannot
-- run in Edit AT ALL: Roblox only executes scripts in Play/Run. "Studio only"
-- and "not while I am playing" are therefore the same gate, and it can only
-- ever pick the wrong one.
--
-- As a module it is invoked deliberately instead. Playtests never build it, and
-- Edit finally can -- from the command bar or MCP:
--
--   require(game.ServerScriptService.SeedGameServer.MillMockupRunner).Build()
--
-- Build() clears the previous gallery first, so it is safe to run repeatedly
-- while iterating on a tier.
--==============================================================================

local MillMockupRunner = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local MillForms = require(Shared:WaitForChild("MillForms"))

local FOLDER_NAME = "MillMockup_Gallery"

local MILL = GameConfig.Mill
local TIERS = MILL.Tiers

-- Showroom layout parameters at the BACK OF THE ISLAND (Z = 150)
local BASE_Z = 180
local GAP_X = 4
local TOTAL_TIERS = #TIERS

--==============================================================================
-- EACH PLINTH FITS ITS MILL
--
-- Half the width each tier needs and how far it reaches forward (-Z) and back
-- (+Z) from its deck centre. The code-built tiers keep the old 18 x 22 plinth;
-- the owner's mills (11-14) say their own size (MillForms), up to 23.5 wide and
-- 32 long -- on the old 22-stud spacing tiers 12 and 13 met.
--==============================================================================
local function footprintOf(tier: number): (number, number, number)
	local formId = MillForms.FormOf(tier)
	local form = if formId then MillForms.Forms[formId] else nil
	if form then
		return math.max(-form.Low.X, form.High.X, 9), math.max(-form.Low.Z, 11), math.max(form.High.Z, 11)
	end
	return 9, 11, 11
end

local CENTRE_X: { number } = {}
do
	local total = 0
	for tier = 1, TOTAL_TIERS do
		total += (footprintOf(tier)) * 2 + (if tier > 1 then GAP_X else 0)
	end
	local x = -total * 0.5
	for tier = 1, TOTAL_TIERS do
		local half = footprintOf(tier)
		CENTRE_X[tier] = x + half
		x += half * 2 + GAP_X
	end
end

-- Visual descriptions for every tier
local DESCRIPTIONS = {
	[1] = "Rustic wooden chassis, stone deck, and slow training belt.",
	[2] = "Tidy timber rails, packed soil deck, and corner planters.",
	[3] = "Open garden trellis promenade with lattice flank screens and climbing ivy.",
	[4] = "Heavy granite grinding stone, iron flumes, and steam pipes.",
	[5] = "Open crystal conservatory terrace with glass balustrades, planters, and mist.",
	[6] = "Gilded imperial sun terrace with 9.2-stud radiant Sunwheel and golden urns.",
	[7] = "Living heartwood tree, glowing rainbow spectrum, and pollen motes.",
	[8] = "Volcanic obsidian forge with molten magma core, dark iron chains, and flame braziers.",
	[9] = "Pearlescent alabaster terrace with seraphic angel wings, halo disc, and stardust motes.",
	[10] = "Void obsidian horizon with gyroscopic astrolabe, nebula core, and 12-band aurora.",
	-- 11-14: the owner's own mills (MillForms), described from their parts.
	[11] = "Deep-sea trench with swaying kelp, drifting jellyfish, and an anglerfish lure over the belt.",
	[12] = "Volcanic forge with a trip-hammer striking a glowing billet, a furnace, and lava rivers.",
	[13] = "Frozen glacier under rippling aurora ribbons, with ice spires and floating crystal shards.",
	[14] = "Black hole with an orbiting accretion disk, infalling debris, photon ring, and jets.",
}

--==============================================================================
-- HELPER: Create a decorative part
--==============================================================================
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

function MillMockupRunner.Clear()
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	print("[Seed/MillMockupRunner] Cleared MillMockup_Gallery from Workspace")
end

--==============================================================================
-- BUILD EVERY TIER
--==============================================================================
function MillMockupRunner.Build(): Folder
	-- Clearing first is what makes this re-runnable: build, look, edit a tier,
	-- build again, without ten galleries stacking up in the same place.
	MillMockupRunner.Clear()

	local gallery = Instance.new("Folder")
	gallery.Name = FOLDER_NAME
	gallery.Parent = workspace

	for tier = 1, TOTAL_TIERS do
		local spec = TIERS[tier]
		local half, front, back = footprintOf(tier)
		local supplied = MillForms.FormOf(tier) ~= nil
		local plinthCF = CFrame.new(CENTRE_X[tier], 0.3, BASE_Z)
		-- The plinth's own middle, which moves with a mill that reaches further
		-- one way than the other.
		local floorCF = plinthCF * CFrame.new(0, 0, (back - front) * 0.5)
		local floorSize = Vector3.new(half * 2, 0.6, front + back)

		local tierGroup = Instance.new("Model")
		tierGroup.Name = string.format("Tier%02d_%s", tier, spec.name:gsub("%s+", ""))
		tierGroup.Parent = gallery

		-- 1. Exhibition Pedestal Plinth
		local plinth = makePart({
			name = "Plinth",
			size = floorSize,
			cf = floorCF,
			color = if tier >= 8 then Color3.fromRGB(32, 32, 38) else Color3.fromRGB(48, 48, 52),
			material = Enum.Material.Cobblestone,
			parent = tierGroup,
		})

		-- Plinth Border Trim
		makePart({
			name = "PlinthTrim",
			size = floorSize + Vector3.new(0.6, 0.1, 0.6),
			cf = floorCF * CFrame.new(0, -0.05, 0),
			color = if tier == 8 then Color3.fromRGB(180, 50, 20)
				elseif tier == 9 then Color3.fromRGB(255, 220, 110)
				elseif tier == 10 then Color3.fromRGB(80, 210, 255)
				else Color3.fromRGB(126, 88, 54),
			material = if tier >= 8 then Enum.Material.Metal else Enum.Material.WoodPlanks,
			parent = tierGroup,
		})

		-- Plinth Step Ramp (Front)
		makePart({
			name = "PlinthStep",
			size = Vector3.new(12, 0.3, 3),
			cf = plinthCF * CFrame.new(0, -0.15, -front - 0.5),
			color = Color3.fromRGB(72, 70, 68),
			material = Enum.Material.Cobblestone,
			parent = tierGroup,
		})

		-- 2. Corner Lantern Bollards
		for _, sx in ipairs({ -(half - 0.8), half - 0.8 }) do
			local post = makePart({
				name = "LanternPost",
				size = Vector3.new(0.6, 3.2, 0.6),
				cf = plinthCF * CFrame.new(sx, 1.6, -front + 1),
				color = Color3.fromRGB(38, 38, 42),
				material = Enum.Material.Metal,
				parent = tierGroup,
			})
			local lampColor = if tier == 8 then Color3.fromRGB(255, 95, 20)
				elseif tier == 9 then Color3.fromRGB(255, 245, 210)
				elseif tier == 10 then Color3.fromRGB(60, 220, 255)
				elseif spec.cost > 10000000 then Color3.fromRGB(255, 220, 120)
				else Color3.fromRGB(240, 200, 140)
			local lamp = makePart({
				name = "Lamp",
				size = Vector3.new(1.0, 1.0, 1.0),
				cf = plinthCF * CFrame.new(sx, 3.2, -front + 1),
				color = lampColor,
				material = Enum.Material.Neon,
				parent = tierGroup,
			})
			local light = Instance.new("PointLight")
			light.Color = lamp.Color
			light.Brightness = 1.2
			light.Range = 14
			light.Parent = lamp
		end

		-- 3. Build the Mill Model
		local millCF = plinthCF * CFrame.new(0, 0.3, 0)
		local millModel, belt = MillModel.Build(tier, millCF, tierGroup)
		millModel.Name = "Mill"
		millModel:SetAttribute("PlotId", 90 + tier)
		millModel:SetAttribute("MillTier", tier)

		-- Tag belt and set tier speed so animations run live
		CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)
		belt:SetAttribute("BeltSpeed", spec.beltStuds)

		-- 4. Build Official Mill Upgrade Sign (Standing to the left side; in
		-- front of the plinth for the owner's mills, whose decor fills the side)
		local signCF = if supplied
			then plinthCF * CFrame.new(-half + 3.5, 0.3, -front - 4) * CFrame.Angles(0, math.rad(30), 0)
			else plinthCF * CFrame.new(-7.2, 0.3, -2) * CFrame.Angles(0, math.rad(30), 0)
		local signModel = MillModel.BuildSign(signCF, tierGroup)
		signModel:SetAttribute("PlotId", 90 + tier)

		-- Populate the sign face text
		local board = signModel:FindFirstChild("Board")
		if board then
			for _, child in ipairs(board:GetChildren()) do
				if child:IsA("SurfaceGui") then
					local title = child:FindFirstChild("Title") :: TextLabel?
					local stats = child:FindFirstChild("Stats") :: TextLabel?
					local prompt = child:FindFirstChild("Prompt") :: TextLabel?

					if title then title.Text = spec.name:upper() end
					-- Speed SCORE per second, not studs. `beltStuds` is the studs
					-- column and it is a different number entirely; printing one
					-- under the other's name is how a placard starts lying.
					if stats then
						stats.Text = GameConfig.compact(spec.speed) .. " SPEED/S"
					end
					if prompt then
						prompt.Text = if spec.cost > 0 then "$" .. GameConfig.compact(spec.cost) else "FREE"
					end
				end
			end
		end

		-- 5. Front Exhibition Placard Banner (Standing to the front right)
		local plaquePost = makePart({
			name = "PlaquePost",
			size = Vector3.new(0.4, 2.0, 0.4),
			cf = plinthCF * CFrame.new(half - 3, 1.0, -front - 0.5),
			color = Color3.fromRGB(92, 62, 38),
			material = Enum.Material.WoodPlanks,
			parent = tierGroup,
		})

		local plaqueBoard = makePart({
			name = "PlaqueBoard",
			size = Vector3.new(5.5, 2.5, 0.3),
			cf = plinthCF * CFrame.new(half - 3, 2.2, -front - 0.5) * CFrame.Angles(math.rad(-15), 0, 0),
			color = Color3.fromRGB(32, 28, 24),
			material = Enum.Material.WoodPlanks,
			parent = tierGroup,
		})

		local sg = Instance.new("SurfaceGui")
		sg.Name = "ExhibitPlaque"
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.LightInfluence = 0
		sg.Parent = plaqueBoard

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(24, 22, 20)
		frame.BorderSizePixel = 0
		frame.Parent = sg

		local stroke = Instance.new("UIStroke")
		stroke.Color = if tier == 8 then Color3.fromRGB(255, 95, 20)
			elseif tier == 9 then Color3.fromRGB(255, 224, 110)
			elseif tier == 10 then Color3.fromRGB(60, 220, 255)
			else Color3.fromRGB(200, 160, 80)
		stroke.Thickness = 2
		stroke.Parent = frame

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.Parent = frame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 0, 24)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.FredokaOne
		titleLabel.Text = string.format("TIER %d • %s", tier, spec.name:upper())
		titleLabel.TextColor3 = stroke.Color
		titleLabel.TextSize = 14
		titleLabel.TextXAlignment = Enum.TextXAlignment.Center
		titleLabel.Parent = frame

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Position = UDim2.new(0, 0, 0, 24)
		statsLabel.Size = UDim2.new(1, 0, 0, 18)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Font = Enum.Font.GothamBold
		statsLabel.Text = string.format("Speed: %s/s | %s",
			GameConfig.compact(spec.speed),
			if spec.cost > 0 then "$" .. GameConfig.compact(spec.cost) else "FREE")
		statsLabel.TextColor3 = Color3.fromRGB(150, 226, 150)
		statsLabel.TextSize = 13
		statsLabel.TextXAlignment = Enum.TextXAlignment.Center
		statsLabel.Parent = frame

		local descLabel = Instance.new("TextLabel")
		descLabel.Position = UDim2.new(0, 0, 0, 44)
		descLabel.Size = UDim2.new(1, 0, 1, -44)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = DESCRIPTIONS[tier] or ""
		descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		descLabel.TextSize = 10
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Center
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = frame	end

	print(string.format(
		"[Seed/MillMockupRunner] Built all %d Mill Tiers at the back of the island (Z = %d)",
		TOTAL_TIERS, BASE_Z))
	return gallery
end

return MillMockupRunner
