--!strict
--==============================================================================
-- Steal a Seed :: EmberrootRootMockupRunner
--
-- The five Emberroot species at Tiny and at Colossal, side by side, each in the
-- eleven-stud planting cell it has to live inside. Built for one question: does
-- the root sculpture that replaced CinderPad read at both ends of the ladder,
-- and does its footprint stay in the cell when the body does not.
--==============================================================================

--==============================================================================
-- NOTHING CALLS THIS, AND THAT IS THE POINT
--
-- A Script cannot run in Edit at all -- Roblox executes scripts only in
-- Play/Run -- so a `RunService:IsStudio()` gate on a `.server.luau` gates the
-- published game and leaves playtests building the gallery. Two runners were
-- deleted for exactly that. As a module it is invoked deliberately:
--
--   require(game.ServerScriptService.SeedGameServer.EmberrootRootMockupRunner).Build()
--
-- Build() clears the previous folder first, so it is safe to run repeatedly
-- while iterating on a profile.
--
-- IT BUILDS THROUGH THE PRODUCTION PATH. CreatureModel.Build and
-- EmberrootForms, the same two the game uses, so what is reviewed here is what
-- ships. A preview that keeps its own copy of the geometry is a preview that
-- can approve a shape the game never builds -- which is exactly how Starbloom
-- came to be approved at one point of a seven-point ladder.
--==============================================================================

local EmberrootRootMockupRunner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "EmberrootSpeciesMockup"
local SPECIES = { "cinderpaw", "emberquill", "slagbloom", "kilnhusk", "pyrelotus" }
-- The planting cell the roots have to stay inside.
local CELL = 11
local GAP = 5

--==============================================================================
-- WHY THE PREVIEW STANDS IN OPEN SKY
--
-- Built at the origin it lands inside the live map, and a Colossal Emberroot is
-- 200 to 375 studs tall on the game's untouched tier curve -- so the camera ends
-- up inside a plant and the review is of somebody's shin. Clear air, well off
-- the road, is the only place ten of these fit side by side.
--==============================================================================
local ORIGIN = Vector3.new(600, 300, -600)

--==============================================================================
-- FRESH MODULES, OR THE PREVIEW SHOWS THE LAST BUILD
--
-- Roblox's require cache keys on the ModuleScript INSTANCE, and Rojo rewrites
-- Source in place rather than replacing the instance -- so a module required
-- earlier in the session keeps answering with its old body no matter how many
-- times the file changes on disk. Cloning forces the body to re-run.
--
-- CreatureModel's own requires have to be repointed at the clones too, or a
-- fresh CreatureModel would still pull the cached EmberrootForms.
--==============================================================================
local function freshModules(): (any, any, { Instance })
	local shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
	local temps: { Instance } = {}

	local forms = shared:FindFirstChild("EmberrootForms")
	local cm = shared:FindFirstChild("CreatureModel")
	local sd = shared:FindFirstChild("SeedData")
	assert(forms and cm and sd, "EmberrootForms, CreatureModel and SeedData must be synced")

	local formsClone = (forms :: ModuleScript):Clone()
	formsClone.Name = "EmberrootFormsPreview"
	formsClone.Parent = shared
	table.insert(temps, formsClone)

	local cmClone = (cm :: ModuleScript):Clone()
	cmClone.Name = "CreatureModelPreview"
	cmClone.Source = cmClone.Source:gsub(
		'WaitForChild%("EmberrootForms"%)', 'WaitForChild("EmberrootFormsPreview")')
	cmClone.Parent = shared
	table.insert(temps, cmClone)

	local sdClone = (sd :: ModuleScript):Clone()
	sdClone.Parent = shared
	table.insert(temps, sdClone)

	return require(cmClone) :: any, require(sdClone) :: any, temps
end

local function part(name: string, size: Vector3, cf: CFrame, colour: Color3,
	parent: Instance, transparency: number?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

--==============================================================================
-- THE CELL, DRAWN AS AN OUTLINE
--
-- Four thin rails rather than a filled square: a solid floor under the plant
-- would hide the one thing this preview exists to show, which is where the
-- roots actually reach. Low and thin enough to sight along from the side.
--==============================================================================
local function cell(at: CFrame, parent: Instance, colour: Color3)
	local h = CELL * 0.5
	local t = 0.14
	for _, side in ipairs({
		{ CFrame.new(0, 0, -h), Vector3.new(CELL, t, t) },
		{ CFrame.new(0, 0, h), Vector3.new(CELL, t, t) },
		{ CFrame.new(-h, 0, 0), Vector3.new(t, t, CELL) },
		{ CFrame.new(h, 0, 0), Vector3.new(t, t, CELL) },
	}) do
		part("CellRail", side[2] :: Vector3, at * (side[1] :: CFrame), colour, parent)
	end
end

local function label(text: string, at: CFrame, parent: Instance, size: number,
	colour: Color3, wide: number)
	local a = part("Label", Vector3.new(0.2, 0.2, 0.2), at, colour, parent, 1)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromScale(wide, wide * 0.22)
	b.AlwaysOnTop = true
	b.MaxDistance = 400
	b.Parent = a
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = colour
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = b
	local _ = size
end

function EmberrootRootMockupRunner.Clear()
	local existing = workspace:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	print("[Seed/EmberrootRootMockup] Cleared " .. FOLDER_NAME .. " from Workspace")
end

--==============================================================================
-- BUILD
--
-- Ten models: five species, Tiny in the front row and Colossal in the back, so
-- the pair for one species reads as a column and the ladder reads as a row.
--==============================================================================
function EmberrootRootMockupRunner.Build(): Folder
	EmberrootRootMockupRunner.Clear()

	local CreatureModel, SeedData, temps = freshModules()

	local root = Instance.new("Folder")
	root.Name = FOLDER_NAME
	-- Archivable = false is what keeps a scratch preview out of the .rbxl. This
	-- place has already lost a session to debris saved into the place file.
	root.Archivable = false
	root:SetAttribute("PreviewOnly", true)
	root.Parent = workspace

	--==========================================================================
	-- THE PITCH IS SET BY THE BODY, NOT BY THE CELL
	--
	-- A Colossal Emberroot measures about 210 x 233 x 373 studs on the game's
	-- untouched tier curve. Laid out on the 11-stud planting pitch these plants
	-- actually occupy, every Colossal would swallow its neighbours and the
	-- camera would be standing inside one -- which is what the first pass did.
	--
	-- So SPECIES are 280 studs apart and the Tiny/Colossal PAIR is 30 apart
	-- inside that, which is close enough to sight both root systems in one shot
	-- and far enough that the Colossal body is not sitting on the Tiny one. The
	-- spacing is itself a measurement of the problem that is out of scope here.
	--==========================================================================
	--==========================================================================
	-- TWO ROWS ON TWO DIFFERENT PITCHES, BECAUSE THE TIERS ARE NOT COMPARABLE
	--
	-- A Tiny Emberroot is about 4 studs across. A Colossal is 210, on the game's
	-- untouched tier curve -- and its own feet reach 31 studs forward, which is
	-- further than a whole Tiny plant. Laid out on one pitch, either the Tiny row
	-- is a row of specks or the camera stands inside a Colossal foot. Both
	-- happened before this split.
	--
	-- So the TINY row is on a 16-stud pitch and reads as a set: five sculptures
	-- side by side, which is what the silhouettes have to be judged against each
	-- other on. The COLOSSAL row is 300 studs behind on a 280-stud pitch, where
	-- the question is not composition but footprint -- does the root system stay
	-- in its cell when the body does not.
	--==========================================================================
	local TIERS = { { 1, "TINY", CELL + GAP, 0 }, { SeedData.TierCount, "COLOSSAL", 280, -300 } }
	local report = {}

	for col, id in ipairs(SPECIES) do
		local sp = SeedData.Get(id)
		for row, spec in ipairs(TIERS) do
			local tier = spec[1] :: number
			local at = CFrame.new(ORIGIN
				+ Vector3.new((col - 1) * (spec[3] :: number), 0, spec[4] :: number))

			local group = Instance.new("Model")
			group.Name = string.format("%s_%s", sp.Name, spec[2])
			group.Parent = root

			cell(at, group, Color3.fromRGB(120, 96, 88))

			local m = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, at, group)
			m.Name = string.format("Plant_%s_T%d", sp.Name, tier)

			-- Measure the ROOTS alone -- the tagged ground parts -- because the
			-- body is still on the 50x curve and would swamp the number this
			-- preview is for.
			local lo, hi = math.huge, -math.huge
			local loZ, hiZ, lowestY = math.huge, -math.huge, math.huge
			local rootParts, allParts = 0, 0
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					allParts += 1
					if d:GetAttribute("GroundRoot") then
						rootParts += 1
						local h = d.Size * 0.5
						for sx = -1, 1, 2 do
							for sy = -1, 1, 2 do
								for sz = -1, 1, 2 do
									local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
									lo = math.min(lo, q.X); hi = math.max(hi, q.X)
									loZ = math.min(loZ, q.Z); hiZ = math.max(hiZ, q.Z)
									lowestY = math.min(lowestY, q.Y)
								end
							end
						end
					end
				end
			end
			local fx, fz = hi - lo, hiZ - loZ
			table.insert(report, string.format(
				"%-11s %-9s roots %2d / %3d parts   footprint %5.2f x %5.2f   lowest y %+.3f",
				id, spec[2], rootParts, allParts, fx, fz, lowestY - at.Position.Y))

			label(string.format("%s\n%s", string.upper(sp.Name), spec[2]),
				at * CFrame.new(0, 0.4, -CELL * 0.5 - 1.2), group, 18,
				Color3.fromRGB(255, 166, 78), 9)
			label(string.format("roots %.1f x %.1f", fx, fz),
				at * CFrame.new(0, 0.4, CELL * 0.5 + 1.2), group, 14,
				Color3.fromRGB(180, 200, 255), 8)
		end
	end

	for _, t in ipairs(temps) do
		t:Destroy()
	end

	print("[Seed/EmberrootRootMockup] " .. FOLDER_NAME .. " built.")
	for _, line in ipairs(report) do
		print("  " .. line)
	end
	return root
end

--==============================================================================
-- GHOST THE BODY, SO THE ROOTS CAN BE SEEN FROM ABOVE
--
-- The one view that shows a root system's plan -- which direction dominates,
-- where the negative space is, whether the branches are evenly spaced -- is
-- straight down, and that is exactly the view the crown blocks. Every species
-- carries a crown wider than its roots.
--
-- This fades everything that is NOT a ground root or a walking leg, so the
-- sculpture can be judged in plan and then put back. It changes Transparency on
-- the preview build only and adds no geometry: the parts being faded are the
-- production parts, so what is judged is still what ships.
--
--   require(game.ServerScriptService.SeedGameServer.EmberrootRootMockupRunner).Ghost(true)
--==============================================================================
function EmberrootRootMockupRunner.Ghost(on: boolean)
	local root = workspace:FindFirstChild(FOLDER_NAME)
	if not root then
		warn("[Seed/EmberrootRootMockup] nothing to ghost -- run Build() first")
		return
	end
	local LEG = { "Thigh", "Shin", "Sole", "Claw", "Toe" }
	local faded = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "CellRail" and d.Name ~= "Label" then
			local keep = d:GetAttribute("GroundRoot") == true
			if not keep then
				for _, w in ipairs(LEG) do
					if string.find(d.Name, w) then keep = true break end
				end
			end
			if not keep then
				-- The Base plate is already invisible and must stay that way.
				if d.Transparency < 1 then
					if on then
						d:SetAttribute("GhostRestore", d.Transparency)
						d.Transparency = 0.93
						faded += 1
					end
				elseif not on then
					local was = d:GetAttribute("GhostRestore")
					if was ~= nil then
						d.Transparency = was :: number
						d:SetAttribute("GhostRestore", nil)
					end
				end
				if not on then
					local was = d:GetAttribute("GhostRestore")
					if was ~= nil then
						d.Transparency = was :: number
						d:SetAttribute("GhostRestore", nil)
						faded += 1
					end
				end
			end
		end
	end
	print(string.format("[Seed/EmberrootRootMockup] ghost %s (%d parts)",
		if on then "ON" else "OFF", faded))
end

return EmberrootRootMockupRunner
