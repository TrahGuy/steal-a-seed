--!nocheck
--==============================================================================
-- Steal a Seed :: DustbowlPodSpec
--
-- Dustbowl's mesh pods: the width ladder, the seven tiers the builder makes out
-- of two templates, and the part-built fallback when a template is missing.
-- Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("DustbowlPodSpec"))
--
-- The real SeedData and CreatureModel, fresh-required. The templates are blank
-- MeshParts at the imported meshes' own proportions unless real ones are
-- already in ReplicatedStorage.Assets.Pods, in which case those are used and
-- left exactly as they were found. Everything this builds is destroyed.
--
-- Not here: how the meshes look (Studio, once imported), the particles moving
-- and the lights flickering (Play), and the carry grip (Play).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 0.01)
end

local function sameColor(a, b)
	return near(a.R, b.R, 0.004) and near(a.G, b.G, 0.004) and near(a.B, b.B, 0.004)
end

local LADDER = { 2.0, 3.2, 4.6, 6.4, 8.6, 11.2, 14.5 }
local RATIO = { 1.00, 1.60, 2.30, 3.20, 4.30, 5.60, 7.25 }

--==============================================================================
-- 1. THE WIDTH LADDER
--==============================================================================
say("\n-- widths --")
do
	local ladderOk, ratioOk, othersOk, gripOk = true, true, true, true
	local detail = ""
	for tier = 1, 7 do
		local w = SeedData.PodDiameter(tier, "dustbowl")
		if not near(w, LADDER[tier], 1e-9) then
			ladderOk = false
			detail ..= string.format(" T%d=%s", tier, tostring(w))
		end
		if not near(w / SeedData.PodDiameter(1, "dustbowl"), RATIO[tier], 0.02) then
			ratioOk = false
		end
		local sheet = SeedData.Tier(tier).pod
		for _, biome in ipairs({ "greenhollow", "tanglemire", "emberroot", "starbloom" }) do
			if SeedData.PodDiameter(tier, biome) ~= sheet then
				othersOk = false
			end
		end
		if SeedData.PodDiameter(tier) ~= sheet or SeedData.PodDiameter(tier, nil) ~= sheet then
			othersOk = false
		end
		if not near(SeedData.GripForward(tier, "dustbowl"),
			GameConfig.Carry.GripForwardBase + LADDER[tier] * 0.5, 1e-9)
			or SeedData.GripForward(tier) ~= GameConfig.Carry.GripForwardBase + sheet * 0.5 then
			gripOk = false
		end
	end
	check(ladderOk, "Dustbowl pods are 2.0 / 3.2 / 4.6 / 6.4 / 8.6 / 11.2 / 14.5 studs wide", detail)
	check(ratioOk, "which is 1.00x 1.60x 2.30x 3.20x 4.30x 5.60x 7.25x of a Tiny")
	check(othersOk, "every other biome, and a call with no biome, still reads the tier sheet")
	check(gripOk, "the grip follows the same width, and is unchanged for everybody else")
	local junk = pcall(function()
		return SeedData.PodDiameter(nil, "dustbowl") + SeedData.PodDiameter(0 / 0, "dustbowl")
			+ SeedData.PodDiameter(99, "dustbowl") + SeedData.PodDiameter(3, "nowhere")
	end)
	check(junk and SeedData.PodDiameter(99, "dustbowl") == 14.5 and SeedData.PodDiameter(nil, "dustbowl") == 2.0,
		"a junk tier or biome reads as a real rung rather than throwing")
end

--==============================================================================
-- 2. TEMPLATES
--==============================================================================
local node = ReplicatedStorage
local made = {}
for _, step in ipairs(GameConfig.PodMeshes.Path) do
	local child = node:FindFirstChild(step)
	if not child then
		child = Instance.new("Folder")
		child.Name = step
		child.Parent = node
		table.insert(made, child)
	end
	node = child
end
local podsFolder = node

-- The imported meshes' own bounding boxes, in the centimetres the importer
-- read as studs: 122574206027033 and 116363561995758.
local NATIVE = {
	Dustbowl_T1to5 = Vector3.new(103.94, 190.12, 103.72),
	Dustbowl_T6to7 = Vector3.new(133.26, 190.01, 133.59),
}
local standIns = {}
for name, size in pairs(NATIVE) do
	local existing = podsFolder:FindFirstChild(name)
	if not (existing and existing:IsA("MeshPart")) then
		local mp = Instance.new("MeshPart")
		mp.Name = name
		mp.Size = size
		mp.Anchored = true
		mp.Parent = podsFolder
		standIns[name] = mp
	end
end

local workFolder = Instance.new("Folder")
workFolder.Name = "DustbowlPodSpecTemp"
workFolder.Archivable = false
workFolder.Parent = workspace

local species = SeedData.InBiome("dustbowl")[1]
local ORIGIN = Vector3.new(1300, 400, -900)

local FINISH = {
	{ Color3.fromRGB(228, 212, 182), Enum.Material.SmoothPlastic },
	{ Color3.fromRGB(214, 168, 108), Enum.Material.Sandstone },
	{ Color3.fromRGB(188, 110, 68), Enum.Material.Sandstone },
	{ Color3.fromRGB(152, 78, 52), Enum.Material.Slate },
	{ Color3.fromRGB(116, 56, 42), Enum.Material.Basalt },
	{ Color3.fromRGB(175, 65, 35), Enum.Material.Sandstone },
	{ Color3.fromRGB(245, 185, 55), Enum.Material.Sandstone },
}

local function find(model, className, name)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA(className) and (name == nil or d.Name == name) then
			return d
		end
	end
	return nil
end

local function count(model, className)
	local n = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA(className) then
			n += 1
		end
	end
	return n
end

local function keypoints(seq)
	local list = {}
	for _, k in ipairs(seq.Keypoints) do
		table.insert(list, { k.Time, k.Value })
	end
	return list
end

local function sequenceIs(seq, expected)
	local got = keypoints(seq)
	if #got ~= #expected then
		return false
	end
	for i, e in ipairs(expected) do
		if not (near(got[i][1], e[1], 1e-3) and near(got[i][2], e[2], 1e-3)) then
			return false
		end
	end
	return true
end

local function body()
	--==========================================================================
	-- 3. SEVEN TIERS OUT OF TWO SHELLS
	--==========================================================================
	say("\n-- tiers --")
	local builtColors = {}
	for tier = 1, 7 do
		local cf = CFrame.new(ORIGIN + Vector3.new(tier * 20, 0, 0))
		local pod = CreatureModel.BuildPod(species, tier, cf, workFolder)
		local shell = pod.PrimaryPart
		local templateName = if tier >= 6 then "Dustbowl_T6to7" else "Dustbowl_T1to5"
		local template = podsFolder:FindFirstChild(templateName)
		local width = LADDER[tier]
		local tag = string.format("T%d", tier)

		check(shell ~= nil and shell:IsA("MeshPart") and shell.Name == "Shell"
			and shell.Parent == pod,
			tag .. ": the primary part is a MeshPart shell", shell and shell.ClassName)
		if not (shell and shell:IsA("MeshPart") and template) then
			continue
		end
		local native = template.Size
		local aspect = native.Y / math.max(native.X, native.Z)
		check(near(math.max(shell.Size.X, shell.Size.Z), width)
			and near(shell.Size.Y / math.max(shell.Size.X, shell.Size.Z), aspect, 0.002),
			tag .. ": scaled evenly to its width from the " .. templateName .. " template",
			string.format("%.2f x %.2f x %.2f", shell.Size.X, shell.Size.Y, shell.Size.Z))
		check(near(shell.Position.Y - shell.Size.Y * 0.5, cf.Position.Y)
			and near(shell.Position.X, cf.Position.X) and near(shell.Position.Z, cf.Position.Z),
			tag .. ": stands on the CFrame it was given",
			string.format("base %.3f", shell.Position.Y - shell.Size.Y * 0.5 - cf.Position.Y))
		check(sameColor(shell.Color, FINISH[tier][1]) and shell.Material == FINISH[tier][2],
			tag .. ": " .. FINISH[tier][2].Name .. " in its own colour",
			string.format("%s %s", tostring(shell.Color), shell.Material.Name))
		table.insert(builtColors, { shell.Color, shell.Material })

		local anchoredQuiet = true
		for _, d in ipairs(pod:GetDescendants()) do
			if d:IsA("BasePart") and (not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch) then
				anchoredQuiet = false
			end
		end
		check(anchoredQuiet, tag .. ": anchored and inert as built; queryability is the caller's call")
		local leftovers = find(pod, "BasePart", "Crown") or find(pod, "BasePart", "Seam")
			or find(pod, "BasePart", "CrustShard") or find(pod, "BasePart", "ShellShoulder")
		check(leftovers == nil and pod:GetAttribute("SpeciesId") == species.Id
			and pod:GetAttribute("Tier") == tier and pod:GetAttribute("Stage") == CreatureModel.STAGE_POD,
			tag .. ": no part-built pieces, and the usual attributes", leftovers and leftovers.Name)

		local emitters = count(pod, "ParticleEmitter")
		local lights = count(pod, "PointLight")
		local core = find(pod, "BasePart", "Core")
		local tierTag = find(pod, "BillboardGui", "TierTag")
		if tier <= 4 then
			check(emitters == 0 and lights == 0 and core == nil and tierTag == nil,
				tag .. ": no light, no aura, no core, no label",
				string.format("%d emitters %d lights", emitters, lights))
		elseif tier == 5 then
			local seam = find(pod, "PointLight", "SeamLight")
			check(emitters == 0 and lights == 1 and seam and sameColor(seam.Color, Color3.fromRGB(245, 140, 40))
				and core == nil and tierTag == nil,
				tag .. ": one faint amber light behind the seam, and nothing else",
				string.format("%d emitters %d lights", emitters, lights))
		end

		if tier >= 6 then
			local coreColor = if tier == 6 then Color3.fromRGB(255, 115, 20) else Color3.fromRGB(200, 245, 255)
			check(core ~= nil and core.Material == Enum.Material.Neon and sameColor(core.Color, coreColor),
				tag .. ": a neon core", core and tostring(core.Color))
			if core then
				local coreR = core.Size.X * 0.5
				local shellR = math.min(shell.Size.X, shell.Size.Z) * 0.5
				check(coreR < shellR * 0.72 and core.Position.Y - coreR > shell.Position.Y - shell.Size.Y * 0.5
					and core.Position.Y + coreR < shell.Position.Y + shell.Size.Y * 0.5,
					tag .. ": the core stays inside the shell's outline",
					string.format("core r %.2f vs shell r %.2f", coreR, shellR))
			end
		end

		if tier == 6 then
			local fire = find(pod, "ParticleEmitter", "FireAura")
			check(fire ~= nil and emitters == 1, tag .. ": one emitter, FireAura", emitters)
			if fire then
				local k = width * 0.25
				check(sequenceIs(fire.Size, { { 0, 0.4 * k }, { 0.5, 1.2 * k }, { 1, 0 } }),
					tag .. ": the brief's ember curve, scaled to a quarter of the pod's width",
					string.format("x%.2f", k))
				check(sequenceIs(fire.Transparency, { { 0, 0.2 }, { 1, 1 } })
					and near(fire.Lifetime.Min, 0.8) and near(fire.Lifetime.Max, 1.4)
					and fire.Rate == 25
					and near(fire.Speed.Min, 3) and near(fire.Speed.Max, 7)
					and fire.Acceleration == Vector3.new(0, 8, 0)
					and near(fire.LightEmission, 0.85)
					and sameColor(fire.Color.Keypoints[1].Value, Color3.fromRGB(255, 180, 40))
					and sameColor(fire.Color.Keypoints[#fire.Color.Keypoints].Value, Color3.fromRGB(220, 40, 10)),
					tag .. ": otherwise the brief's fire: fade, lifetime, top rate, rise and glow")
				check(fire.Shape == Enum.ParticleEmitterShape.Sphere
					and fire.ShapeStyle == Enum.ParticleEmitterShapeStyle.Surface
					and fire.ShapeInOut == Enum.ParticleEmitterShapeInOut.Outward,
					tag .. ": thrown off the egg's outline, not born inside it")
			end
			local light = find(pod, "PointLight", "FireLight")
			check(light ~= nil and lights == 1 and sameColor(light.Color, Color3.fromRGB(255, 130, 30))
				and near(light.Brightness, 2.2) and near(light.Range, math.min(width * 2.2, 60), 0.05)
				and light.Shadows == true
				and CollectionService:HasTag(light, GameConfig.Tags.PodPulse)
				and light:GetAttribute("PulseStyle") == "fire" and light:GetAttribute("PulseBase") == 2.2,
				tag .. ": a warm light that casts shadows, tagged to flicker like fire",
				light and string.format("%s %.2f %.1f", tostring(light.Color), light.Brightness, light.Range))
			check(tierTag == nil and pod:GetAttribute("PickupSound") == nil, tag .. ": no COLOSSAL label")
		elseif tier == 7 then
			local spark = find(pod, "ParticleEmitter", "ElectricAura")
			check(spark ~= nil and emitters == 1, tag .. ": one emitter, ElectricAura", emitters)
			if spark then
				local k = width * 0.25
				check(sequenceIs(spark.Size, { { 0, 0.6 * k }, { 0.3, 1.6 * k }, { 1, 0 } }),
					tag .. ": the brief's spark curve, scaled to a quarter of the pod's width",
					string.format("x%.2f", k))
				check(sequenceIs(spark.Transparency, { { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } })
					and near(spark.Lifetime.Min, 0.15) and near(spark.Lifetime.Max, 0.35)
					and spark.Rate == 30
					and spark.SpreadAngle == Vector2.new(180, 180)
					and near(spark.LightEmission, 1)
					and sameColor(spark.Color.Keypoints[1].Value, Color3.fromRGB(160, 230, 255))
					and sameColor(spark.Color.Keypoints[#spark.Color.Keypoints].Value, Color3.fromRGB(80, 140, 255)),
					tag .. ": otherwise the brief's lightning: fade, lifetime, top rate, spread and glow")
				check(spark.Shape == Enum.ParticleEmitterShape.Sphere
					and spark.ShapeStyle == Enum.ParticleEmitterShapeStyle.Surface
					and spark.ShapeInOut == Enum.ParticleEmitterShapeInOut.Outward,
					tag .. ": thrown off the egg's outline, not born inside it")
			end
			local light = find(pod, "PointLight", "ElectricLight")
			check(light ~= nil and lights == 1 and sameColor(light.Color, Color3.fromRGB(140, 210, 255))
				and near(light.Brightness, 3.5) and near(light.Range, math.min(width * 2.8, 60), 0.05)
				and light.Shadows == true
				and CollectionService:HasTag(light, GameConfig.Tags.PodPulse)
				and light:GetAttribute("PulseStyle") == "electric",
				tag .. ": a bright cold light that casts shadows, tagged to flicker like lightning",
				light and string.format("%s %.2f %.1f", tostring(light.Color), light.Brightness, light.Range))
			local text = tierTag and tierTag:FindFirstChildOfClass("TextLabel")
			check(tierTag ~= nil and tierTag.MaxDistance == 160 and tierTag.AlwaysOnTop and text
				and text.Text == "COLOSSAL" and tierTag.Parent == shell
				and pod:GetAttribute("PickupSound") == "ColossalPickup",
				tag .. ": the COLOSSAL label, bounded at 160, and the pickup sound")
		end
	end

	-- Tiers 1 to 5 share one shell, so the finish is the whole difference.
	local distinct = true
	for i = 1, 5 do
		for j = i + 1, 5 do
			local a, b = builtColors[i], builtColors[j]
			if a and b and sameColor(a[1], b[1]) then
				distinct = false
			end
		end
	end
	local materials = {}
	for i = 1, 5 do
		if builtColors[i] then
			materials[builtColors[i][2]] = true
		end
	end
	local materialCount = 0
	for _ in pairs(materials) do
		materialCount += 1
	end
	check(distinct and materialCount >= 4,
		"tiers 1 to 5 never repeat a colour, and use at least four materials", materialCount)

	--==========================================================================
	-- 4. NO TEMPLATE, NO MESH
	--==========================================================================
	say("\n-- fallback --")
	local stash = {}
	for _, name in ipairs({ "Dustbowl_T1to5", "Dustbowl_T6to7" }) do
		local t = podsFolder:FindFirstChild(name)
		if t then
			stash[name] = t
			t.Parent = nil
		end
	end
	local bare = CreatureModel.BuildPod(species, 4, CFrame.new(ORIGIN + Vector3.new(0, 0, 40)), workFolder)
	local bareShell = bare.PrimaryPart
	check(bareShell ~= nil and bareShell.ClassName == "Part" and bareShell.Name == "Shell"
		and find(bare, "BasePart", "CrustShard") ~= nil,
		"with no template, a Dustbowl pod is the part-built urn",
		bareShell and bareShell.ClassName)
	-- The urn's cylinder is D * 0.88 across its round face.
	check(bareShell ~= nil and near(bareShell.Size.Y, LADDER[4] * 0.88, 0.02),
		"and it is built at the new width, so the carry and the disc still agree with it",
		bareShell and bareShell.Size.Y)
	for name, t in pairs(stash) do
		t.Parent = podsFolder
	end

	local frozen = podsFolder:FindFirstChild("Dustbowl_T1to5")
	if frozen then
		local was = frozen.Archivable
		frozen.Archivable = false
		local refused = CreatureModel.BuildPod(species, 2, CFrame.new(ORIGIN + Vector3.new(0, 0, 60)), workFolder)
		frozen.Archivable = was
		check(refused.PrimaryPart ~= nil and refused.PrimaryPart.ClassName == "Part",
			"a template that cannot be cloned counts as no template, not as an error")
	end

	local green = SeedData.InBiome("greenhollow")[1]
	local greenPod = CreatureModel.BuildPod(green, 7, CFrame.new(ORIGIN + Vector3.new(0, 0, 80)), workFolder)
	local greenShell = greenPod.PrimaryPart
	check(greenShell ~= nil and greenShell.ClassName == "Part"
		and greenShell.Shape == Enum.PartType.Ball
		and near(greenShell.Size.X, SeedData.Tier(7).pod, 1e-3)
		and find(greenPod, "ParticleEmitter", "FireAura") == nil
		and find(greenPod, "ParticleEmitter", "ElectricAura") == nil,
		"a Greenhollow Colossal is exactly the pod it was", greenShell and greenShell.Size.X)
end

local ok, err = pcall(body)
workFolder:Destroy()
for _, mp in pairs(standIns) do
	mp:Destroy()
end
for i = #made, 1, -1 do
	if #made[i]:GetChildren() == 0 then
		made[i]:Destroy()
	end
end
check(ok, "the spec ran to the end", err)

say(string.format("\nDustbowlPodSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
