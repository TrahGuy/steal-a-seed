--!nocheck
--==============================================================================
-- Steal a Seed :: DustbowlPodSpec
--
-- Dustbowl's pods are PART-BUILT, and this is the spec that keeps them that way.
-- Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("DustbowlPodSpec"))
--
-- WHY IT READS LIKE A REVERSION. On 2026-09-15 Dustbowl's pods were rebuilt from
-- two imported AI meshes (commit 5a91e16) on a width ladder of their own. The
-- owner dropped that on 2026-09-17 and asked for the procedural urn back, exactly
-- as it stood at 6c1f228. So half the assertions here are NEGATIVE: no MeshPart,
-- no mesh template, no biome ladder, no pod-pulse tag, no mesh service. A pod
-- that waits for an asset is a pod that can arrive late, and a boot that waited
-- for one is what cost the owner their garden.
--
-- The real SeedData, GameConfig and CreatureModel, fresh-required. Everything
-- this builds goes in one folder in ReplicatedStorage and is destroyed.
--
-- Not here: how it LOOKS (Studio), the carry grip and the take range (Play), and
-- the hatch clock (the plant specs).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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

-- The shared tier sheet's pod diameters, written down here so that changing the
-- sheet has to be a deliberate change to this spec too. Dustbowl uses these and
-- nothing else.
local SHEET = { 1.66, 2.59, 3.66, 4.87, 6.09, 7.94, 9.04 }

--==============================================================================
-- WHAT THE URN MEASURES, AS A MULTIPLE OF ITS OWN DIAMETER
--
-- Measured off the production builder at 6c1f228 on 2026-09-17, which is the
-- behaviour the owner asked to have back:
--
--     T1..T5   1.1100 D wide   1.2140 D tall   1.2489 D deep    9 parts
--     T6       1.1803 D wide   1.2140 D tall   1.2489 D deep   10 parts
--     T7       1.3030 D wide   1.2140 D tall   1.2489 D deep   10 parts
--
-- The first five are the SAME SHAPE at five sizes -- that is the ladder doing the
-- work -- and the top two are wider for their crowns without being taller. Pinned
-- to four decimals because this is the reference: if a pod's proportions move
-- again, this is the line that says so.
--==============================================================================
local WIDE = { 1.1100, 1.1100, 1.1100, 1.1100, 1.1100, 1.1803, 1.3030 }
local TALL = 1.2140
local DEEP = 1.2489
local PARTS = { 9, 9, 9, 9, 9, 10, 10 }

local DUSTBOWL_BODY = Color3.fromRGB(132, 74, 45)

local fixture = Instance.new("Folder")
fixture.Name = "DustbowlPodSpecFixture"
fixture.Parent = ReplicatedStorage

local dunebud = SeedData.Get("dunebud")
local petalpip = SeedData.Get("petalpip")

--==============================================================================
-- 1. ONE LADDER, SHARED BY EVERY BIOME
--==============================================================================
say("\n-- the shared ladder --")
do
	local sheetOk, risesOk, biomeFreeOk, gripOk = true, true, true, true
	local detail = ""
	for tier = 1, 7 do
		local d = SeedData.PodDiameter(tier)
		if not near(d, SHEET[tier], 1e-9) then
			sheetOk = false
			detail ..= string.format(" T%d=%s", tier, tostring(d))
		end
		if tier > 1 and d <= SeedData.PodDiameter(tier - 1) then
			risesOk = false
		end
		-- The biome-aware signature is gone. Passing one anyway must not move the
		-- number: that is the whole difference from 5a91e16.
		for _, biome in ipairs({ "dustbowl", "greenhollow", "tanglemire", "emberroot", "starbloom" }) do
			if SeedData.PodDiameter(tier, biome) ~= d
				or SeedData.GripForward(tier, biome) ~= SeedData.GripForward(tier) then
				biomeFreeOk = false
			end
		end
		if not near(SeedData.GripForward(tier),
			GameConfig.Carry.GripForwardBase + SHEET[tier] * 0.5, 1e-9) then
			gripOk = false
		end
	end
	check(sheetOk, "pod diameters are the tier sheet's 1.66 / 2.59 / 3.66 / 4.87 / 6.09 / 7.94 / 9.04", detail)
	check(risesOk, "and every tier is wider than the one below it")
	check(biomeFreeOk, "no biome has a ladder of its own -- a biome argument changes nothing")
	check(gripOk, "the grip is the base plus half the pod, for everybody")
	check(SeedData.PodDiameter(nil) == SHEET[1] and SeedData.PodDiameter(99) == SHEET[7],
		"a junk tier still reads as a real rung rather than throwing")
end

--==============================================================================
-- 2. NOTHING IMPORTED IS LEFT TO DEPEND ON
--
-- Source reads, not behaviour: the point is that the CODE cannot reach a mesh, so
-- no ordering, no id and no asset fetch can change what a pod is.
--==============================================================================
say("\n-- no imported geometry --")
do
	check(rawget(GameConfig, "PodMeshes") == nil, "GameConfig has no PodMeshes block")
	check(GameConfig.Tags.PodPulse == nil, "and no PodPulse tag")
	check(GameConfig.Tags.MillPulse ~= nil, "while MillPulse, which is a mill's, is untouched")

	local server = ServerScriptService:FindFirstChild("SeedGameServer")
	check(server ~= nil and server:FindFirstChild("PodMeshService") == nil,
		"there is no PodMeshService")

	local function sourceOf(instance)
		if instance == nil then
			return nil
		end
		local ok, src = pcall(function()
			return (instance :: any).Source
		end)
		return if ok then src else nil
	end

	local model = sourceOf(Shared:FindFirstChild("CreatureModel"))
	check(model ~= nil and not model:find("CreateMeshPartAsync")
			and not model:find("PodMeshes") and not model:find("MeshPart"),
		"the builder's source names no mesh, no template and no CreateMeshPartAsync")
	check(model ~= nil and not model:find("122574206027033")
			and not model:find("116363561995758"),
		"and neither imported asset id appears in it")

	local nest = sourceOf(server and server:FindFirstChild("NestService"))
	check(nest ~= nil and not nest:find("RebuildPods"),
		"NestService has no RebuildPods left over for a late template")

	local carry = sourceOf(server and server:FindFirstChild("CarryService"))
	check(carry ~= nil and not carry:find("takeRangeOf") and not carry:find("lowestPoint"),
		"CarryService is back to one grip and one take range")

	local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local amb = sourceOf(scripts and scripts:FindFirstChild("Ambience"))
	check(amb ~= nil and not amb:find("PodPulse"), "Ambience flickers no pod lights")
end

--==============================================================================
-- 3. SEVEN PART-BUILT PODS
--==============================================================================
say("\n-- seven procedural tiers --")
local pods = {}
do
	local allParts, primaryOk, noMesh, assembledOk = true, true, true, true
	local detail = ""
	for tier = 1, 7 do
		local pod = CreatureModel.BuildPod(dunebud, tier, CFrame.new(0, tier * 40, 0), fixture)
		pods[tier] = pod
		local parts = 0
		for _, d in ipairs(pod:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
				if d.ClassName ~= "Part" and d.ClassName ~= "WedgePart" then
					allParts = false
					detail ..= string.format(" T%d=%s", tier, d.ClassName)
				end
			end
			if d:IsA("MeshPart") or d:IsA("SpecialMesh") or d:IsA("FileMesh") then
				noMesh = false
			end
		end
		local primary = pod.PrimaryPart
		if not primary or primary.Name ~= "Shell" or primary.ClassName ~= "Part"
			or primary.Shape ~= Enum.PartType.Cylinder then
			primaryOk = false
			detail ..= string.format(" T%d primary=%s", tier,
				if primary then primary.Name .. "/" .. primary.ClassName else "nil")
		end
		if parts ~= PARTS[tier] then
			assembledOk = false
			detail ..= string.format(" T%d parts=%d want %d", tier, parts, PARTS[tier])
		end
	end
	check(allParts, "every piece of every tier is a Part or a WedgePart", detail)
	check(noMesh, "no MeshPart, SpecialMesh or FileMesh anywhere in the seven")
	check(primaryOk, "PrimaryPart is the built cylinder shell, tier by tier", detail)
	check(assembledOk, "each is assembled from its own 9 pieces, or 10 for the top two", detail)

	-- A template sitting where the mesh service used to put one must now be
	-- ignored. That is the proof that no code path looks for one.
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local madeAssets = nil
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "Assets"
		assets.Parent = ReplicatedStorage
		madeAssets = assets
	end
	local podsFolder = assets:FindFirstChild("Pods")
	local madePods = nil
	if not podsFolder then
		podsFolder = Instance.new("Folder")
		podsFolder.Name = "Pods"
		podsFolder.Parent = assets
		madePods = podsFolder
	end
	local decoy = Instance.new("Part")
	decoy.Name = "Dustbowl_T1to5"
	decoy.Size = Vector3.new(99, 99, 99)
	decoy.Parent = podsFolder
	local withDecoy = CreatureModel.BuildPod(dunebud, 3, CFrame.new(0, 400, 0), fixture)
	check(withDecoy.PrimaryPart ~= nil and withDecoy.PrimaryPart.ClassName == "Part"
			and near(withDecoy:GetExtentsSize().X, pods[3]:GetExtentsSize().X, 0.01),
		"a pod template dropped into ReplicatedStorage changes nothing")
	withDecoy:Destroy()
	decoy:Destroy()
	if madePods then
		madePods:Destroy()
	end
	if madeAssets then
		madeAssets:Destroy()
	end
end

--==============================================================================
-- 4. THE SIZES ARE THE ONES FROM BEFORE THE MESHES
--==============================================================================
say("\n-- sizes --")
do
	local wideOk, tallOk, risesOk, matchesGreen = true, true, true, true
	local detail = ""
	for tier = 1, 7 do
		local D = SHEET[tier]
		local ext = pods[tier]:GetExtentsSize()
		if not near(ext.X / D, WIDE[tier], 0.002) or not near(ext.Z / D, DEEP, 0.002) then
			wideOk = false
			detail ..= string.format(" T%d w=%.4f d=%.4f", tier, ext.X / D, ext.Z / D)
		end
		if not near(ext.Y / D, TALL, 0.002) then
			tallOk = false
			detail ..= string.format(" T%d h=%.4f", tier, ext.Y / D)
		end
		if tier > 1 and ext.X <= pods[tier - 1]:GetExtentsSize().X then
			risesOk = false
		end
		-- A Greenhollow species of the same tier is built to the same diameter,
		-- because the ladder belongs to the tier and not to the biome.
		local green = CreatureModel.BuildPod(petalpip, tier, CFrame.new(200, tier * 40, 0), fixture)
		if not near(green:GetExtentsSize().X / D, 1.0, 0.25) then
			matchesGreen = false
			detail ..= string.format(" green T%d=%.2f", tier, green:GetExtentsSize().X / D)
		end
		green:Destroy()
	end
	check(wideOk, "every tier measures 1.11 of its diameter across, 1.18 and 1.30 for the "
		.. "crowned top two, and 1.2489 deep", detail)
	check(tallOk, "and every one of the seven stands 1.2140 of its own diameter tall", detail)
	check(risesOk, "so the seven silhouettes step up in size")
	check(matchesGreen, "a Greenhollow pod of the same tier is built to the same diameter", detail)
	local measured = {}
	for tier = 1, 7 do
		local e = pods[tier]:GetExtentsSize()
		measured[#measured + 1] = string.format("T%d %.2fx%.2f", tier, e.X, e.Y)
	end
	say("  ..    measured: " .. table.concat(measured, "  "))
end

--==============================================================================
-- 5. WHAT A TIER LOOKS LIKE, AND WHAT A POD REFUSES TO SAY
--==============================================================================
say("\n-- the tier readout --")
do
	local bodyOk, crownOk = true, true
	local detail = ""
	for tier = 1, 5 do
		if not sameColor(pods[tier].PrimaryPart.Color, DUSTBOWL_BODY) then
			bodyOk = false
			detail ..= string.format(" T%d", tier)
		end
	end
	local function mixDistance(tier)
		local c = pods[tier].PrimaryPart.Color
		return math.abs(c.R - DUSTBOWL_BODY.R) + math.abs(c.G - DUSTBOWL_BODY.G)
			+ math.abs(c.B - DUSTBOWL_BODY.B)
	end
	for tier = 1, 7 do
		local tierColor = SeedData.ColorForTier(tier)
		local found = false
		for _, d in ipairs(pods[tier]:GetDescendants()) do
			if d:IsA("BasePart") and sameColor(d.Color, tierColor) then
				found = true
			end
		end
		if not found then
			crownOk = false
			detail ..= string.format(" T%d has no tier colour", tier)
		end
	end
	check(bodyOk, "tiers 1 to 5 all wear the Dustbowl body colour on the shell", detail)
	check(mixDistance(6) > 0.02 and mixDistance(7) > mixDistance(6),
		"a Titan's shell is mixed toward its tier, and a Colossal's further")
	check(crownOk, "every tier puts its own colour somewhere on the pod", detail)

	local labels, colossal, namesSpecies = 0, nil, false
	for tier = 1, 7 do
		for _, d in ipairs(pods[tier]:GetDescendants()) do
			if d:IsA("BillboardGui") then
				labels += 1
				if tier == 7 then
					colossal = d
				end
			end
			if d:IsA("TextLabel") then
				local text = d.Text:lower()
				if text:find("dunebud") or text:find("uncommon") then
					namesSpecies = true
				end
			end
		end
	end
	check(labels == 1 and colossal ~= nil, "exactly one pod in seven carries a label", labels)
	check(not namesSpecies, "and no label names the species or its rarity")
	local text = colossal and colossal:FindFirstChildWhichIsA("TextLabel")
	check(text ~= nil and text.Text == "COLOSSAL" and colossal.MaxDistance == 160,
		"the one label says COLOSSAL, bounded to 160 studs")
	check(pods[7]:GetAttribute("PickupSound") == "ColossalPickup"
			and pods[6]:GetAttribute("PickupSound") == nil,
		"only the Colossal asks for its own pickup sound")
end

--==============================================================================
-- 6. WHAT THE REST OF THE GAME READS OFF A POD
--==============================================================================
say("\n-- the contract --")
do
	local attrsOk, auraOk, ventOk = true, true, false
	local detail = ""
	for tier = 1, 7 do
		local pod = pods[tier]
		if pod:GetAttribute("SpeciesId") ~= "dunebud" or pod:GetAttribute("Tier") ~= tier
			or pod:GetAttribute("Rarity") ~= dunebud.Rarity
			or pod:GetAttribute("Stage") ~= CreatureModel.STAGE_POD then
			attrsOk = false
			detail ..= string.format(" T%d", tier)
		end
		local emitters, lights = 0, 0
		for _, d in ipairs(pod:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				emitters += 1
			elseif d:IsA("PointLight") then
				lights += 1
			end
		end
		if tier <= 5 and (emitters > 0 or lights > 0) then
			auraOk = false
			detail ..= string.format(" T%d lit", tier)
		elseif tier >= 6 and (emitters == 0 or lights == 0) then
			auraOk = false
			detail ..= string.format(" T%d dark", tier)
		end
		if tier == 6 then
			local vent = pod.PrimaryPart:FindFirstChild("EmberVent")
			ventOk = vent ~= nil and vent:FindFirstChild("EmberTrail") ~= nil
		end
	end
	check(attrsOk, "species, rarity, tier and stage are on the model for the services to read", detail)
	check(auraOk, "tiers 1 to 5 are quiet; the Titan and the Colossal glow", detail)
	check(ventOk, "the Titan's vent still trails embers off its cleft")
	check(pods[1].Name == "Pod_dunebud" and pods[7].Name == "Pod_dunebud",
		"the model name is the one CarryService and NestService look for")
end

--==============================================================================
-- 7. EVERY OTHER BIOME STILL BUILDS
--==============================================================================
say("\n-- the other biomes --")
do
	local built, meshFree, primaryOk = 0, true, true
	for _, biome in ipairs({ "greenhollow", "tanglemire", "emberroot", "starbloom" }) do
		for _, sp in ipairs(SeedData.InBiome(biome)) do
			for _, tier in ipairs({ 1, 6, 7 }) do
				local pod = CreatureModel.BuildPod(sp, tier, CFrame.new(400, tier * 40, 0), fixture)
				built += 1
				if pod.PrimaryPart == nil then
					primaryOk = false
				end
				for _, d in ipairs(pod:GetDescendants()) do
					if d:IsA("MeshPart") then
						meshFree = false
					end
				end
				pod:Destroy()
			end
		end
	end
	check(built >= 9, "a pod builds for every species outside Dustbowl", built)
	check(primaryOk, "each one has a PrimaryPart for the carry to weld to")
	check(meshFree, "and not one of them is a mesh")
end

fixture:Destroy()

say(string.format("\nDustbowlPodSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
