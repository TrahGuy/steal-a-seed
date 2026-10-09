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
-- REWRITTEN 2026-10-09 for the owner's pods. Until then every Dustbowl species
-- wore one procedural clay urn (6c1f228, 9 or 10 parts, a cylinder shell). Now
-- each of the five wears its own pod, modelled by the owner and replayed from
-- PodForms by PodModel (KB/POD-MODELS-PLAN.md). What has NOT changed is why this
-- spec exists: on 2026-09-15 the pods were rebuilt from imported AI meshes, the
-- owner dropped that on 2026-09-17, and a pod that waits for an asset is a pod
-- that can arrive late. So the negative half stays: no MeshPart, no file mesh,
-- no template, no PodPulse tag, no mesh service. The owner's pods draw their
-- spheres and cylinders with SpecialMesh primitives, which need no asset.
--
-- The real SeedData, GameConfig, PodForms and CreatureModel, fresh-required.
-- Everything this builds goes in one folder in ReplicatedStorage and is
-- destroyed. PodModelsSpec covers all 25 pods; this is Dustbowl's five, tier by
-- tier.
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
local PodForms = require(Shared:WaitForChild("PodForms"))

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

-- The owner's five, by their folder ("dustbowl pods").
local FIVE = { "dunebud", "paddlehop", "thornwhorl", "raincup", "suncrown" }

-- The box every pod fills (GameConfig.PodModels), in D.
local BOX_W, BOX_H = 1.25, 1.45

local fixture = Instance.new("Folder")
fixture.Name = "DustbowlPodSpecFixture"
fixture.Parent = ReplicatedStorage

local petalpip = SeedData.Get("petalpip")

-- A pod's drawn extents in its base frame (visible parts only: the Shell is
-- invisible), as width (the wider footprint side) and height, and its lowest
-- point.
local function drawn(pod, cf)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(pod:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.99 then
			local h = d.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local c = cf:PointToObjectSpace((d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
						lo = lo:Min(c)
						hi = hi:Max(c)
					end
				end
			end
		end
	end
	local size = hi - lo
	return math.max(size.X, size.Z), size.Y, lo.Y
end

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
	local podModel = sourceOf(Shared:FindFirstChild("PodModel"))
	check(podModel ~= nil and not podModel:find("MeshPart") and not podModel:find("rbxassetid"),
		"the owner's pods' builder names no MeshPart and no asset")

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
-- 3. FIVE OWNER'S PODS, SEVEN TIERS EACH, ALL PART-BUILT
--==============================================================================
say("\n-- the owner's five, part-built --")
local pods = {}
do
	local allParts, noFile, primaryOk, assembledOk, ownOk = true, true, true, true, true
	local detail = ""
	for _, id in ipairs(FIVE) do
		local sp = SeedData.Get(id)
		pods[id] = {}
		ownOk = ownOk and sp ~= nil and sp.Biome == "dustbowl" and PodForms.Has(id)
		for tier = 1, 7 do
			local cf = CFrame.new(0, tier * 40, 0)
			local pod = CreatureModel.BuildPod(sp, tier, cf, fixture)
			pods[id][tier] = pod
			local parts = 0
			for _, d in ipairs(pod:GetDescendants()) do
				if d:IsA("BasePart") then
					parts += 1
					if d.ClassName ~= "Part" and d.ClassName ~= "WedgePart" then
						allParts = false
						detail ..= string.format(" %s T%d=%s", id, tier, d.ClassName)
					end
				end
				-- A SpecialMesh IS a FileMesh to IsA: only its type and id tell them apart.
				if d:IsA("MeshPart") then
					noFile = false
					detail ..= string.format(" %s MeshPart", id)
				elseif d:IsA("DataModelMesh") and not (d:IsA("SpecialMesh") and d.MeshId == ""
					and (d.MeshType == Enum.MeshType.Sphere or d.MeshType == Enum.MeshType.Cylinder)) then
					noFile = false
					detail ..= string.format(" %s %s", id, d.ClassName)
				end
			end
			local primary = pod.PrimaryPart
			local D = SHEET[tier]
			if not primary or primary.Name ~= "Shell" or primary.ClassName ~= "Part" or primary.Transparency < 1
				or not near(cf:ToObjectSpace(primary.CFrame).Position.Y, D * 0.5, 0.001)
				or (cf:ToObjectSpace(primary.CFrame).Rotation.UpVector - Vector3.yAxis).Magnitude > 1e-4 then
				primaryOk = false
				detail ..= string.format(" %s T%d primary", id, tier)
			end
			-- The owner's parts (less the base each stood on), the Shell, and the Colossal's core.
			local want = PodForms.Pods[id].PartCount + 1 + (if tier == 7 then 1 else 0)
			if parts ~= want then
				assembledOk = false
				detail ..= string.format(" %s T%d parts=%d want %d", id, tier, parts, want)
			end
		end
	end
	check(ownOk, "each of Dustbowl's five species has the owner's own pod")
	check(allParts, "every piece of every tier is a Part or a WedgePart", detail)
	check(noFile, "no MeshPart and no file mesh: only the owner's sphere and cylinder SpecialMeshes", detail)
	check(primaryOk, "PrimaryPart is an invisible upright Shell half a diameter up, tier by tier", detail)
	check(assembledOk, "each is the owner's parts, less its base, plus the Shell, and the Colossal's core", detail)

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
	local withDecoy = CreatureModel.BuildPod(SeedData.Get("dunebud"), 3, CFrame.new(0, 400, 0), fixture)
	check(withDecoy.PrimaryPart ~= nil and withDecoy.PrimaryPart.ClassName == "Part"
			and near(withDecoy:GetExtentsSize().X, pods.dunebud[3]:GetExtentsSize().X, 0.01),
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
-- 4. THE SIZES: EACH FILLS ITS TIER'S BOX, IN ITS OWN PROPORTIONS
--
-- At most 1.25 D wide and 1.45 D tall, and touching one of the two -- the box
-- the carry, the haul and the nest ring are built for (the urn was 1.11-1.30 D
-- wide and 1.21 D tall). Its proportions are the owner's at every tier: the same
-- shape at seven sizes.
--==============================================================================
say("\n-- sizes --")
do
	local fitOk, fillOk, shapeOk, risesOk, groundOk, greenOk = true, true, true, true, true, true
	local detail = ""
	local measured = {}
	for _, id in ipairs(FIVE) do
		local ratio = nil
		local lastW = 0
		for tier = 1, 7 do
			local D = SHEET[tier]
			local w, h, bottom = drawn(pods[id][tier], CFrame.new(0, tier * 40, 0))
			if w / D > BOX_W + 0.002 or h / D > BOX_H + 0.002 then
				fitOk = false
				detail ..= string.format(" %s T%d %.3fx%.3f", id, tier, w / D, h / D)
			end
			if not near(math.max(w / D / BOX_W, h / D / BOX_H), 1, 0.002) then
				fillOk = false
				detail ..= string.format(" %s T%d fills %.3f", id, tier, math.max(w / D / BOX_W, h / D / BOX_H))
			end
			ratio = ratio or h / w
			if not near(h / w, ratio, 0.002) then
				shapeOk = false
			end
			if w <= lastW then
				risesOk = false
			end
			lastW = w
			if not near(bottom, 0, 0.002) then
				groundOk = false
				detail ..= string.format(" %s T%d bottom %.3f", id, tier, bottom)
			end
			if tier == 4 then
				table.insert(measured, string.format("%s %.2fx%.2f D", id, w / D, h / D))
			end
		end
	end
	for tier = 1, 7 do
		-- A Greenhollow species of the same tier fills the same box, because the
		-- ladder belongs to the tier and not to the biome.
		local cf = CFrame.new(200, tier * 40, 0)
		local green = CreatureModel.BuildPod(petalpip, tier, cf, fixture)
		local w, h = drawn(green, cf)
		local D = SHEET[tier]
		if not near(math.max(w / D / BOX_W, h / D / BOX_H), 1, 0.002) then
			greenOk = false
			detail ..= string.format(" green T%d", tier)
		end
		green:Destroy()
	end
	check(fitOk, "every tier of every one fits 1.25 of its diameter across and 1.45 tall", detail)
	check(fillOk, "and fills that box: it reaches the width or the height", detail)
	check(shapeOk, "the owner's proportions are kept at all seven sizes")
	check(risesOk, "so the seven silhouettes step up in size")
	check(groundOk, "and every one stands on its base, its lowest point at the ground", detail)
	check(greenOk, "a Greenhollow pod of the same tier fills the same box", detail)
	say("  ..    at Mega: " .. table.concat(measured, "  "))
end

--==============================================================================
-- 5. WHAT A TIER LOOKS LIKE, AND WHAT A POD REFUSES TO SAY
--==============================================================================
say("\n-- the tier readout --")
do
	-- NO BASE AND NO RING (the owner, 2026-10-09: "remove the base if there is a base below the pods"). The
	-- five are studded pods with no seam of their own, so their size shows by their scale alone.
	local bareOk = true
	local detail = ""
	for _, id in ipairs(FIVE) do
		for tier = 1, 7 do
			local pod = pods[id][tier]
			if pod:FindFirstChild("FlatBase", true) or pod:FindFirstChild("SeamRing", true) then
				bareOk = false
				detail ..= string.format(" %s T%d", id, tier)
			end
		end
	end
	check(bareOk, "no base under any of them, and no ring: the size shows by the pod's scale", detail)

	--==========================================================================
	-- NOT ONE WORD ON ANY OF THEM
	--
	-- The Colossal used to wear the word COLOSSAL over its crown -- the single
	-- exception to "a pod says nothing about itself". The owner had it removed on
	-- 2026-09-17, so the rule has no exception left, and this is the assertion
	-- that keeps it that way: no billboard, no text, on any tier.
	--==========================================================================
	local labels, words = 0, {}
	local soundOk = true
	for _, id in ipairs(FIVE) do
		for tier = 1, 7 do
			for _, d in ipairs(pods[id][tier]:GetDescendants()) do
				if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
					labels += 1
					table.insert(words, string.format("%s T%d %s", id, tier, d.Name))
				end
				if d:IsA("TextLabel") and d.Text ~= "" then
					table.insert(words, string.format("%s T%d %q", id, tier, d.Text))
				end
			end
			local sound = pods[id][tier]:GetAttribute("PickupSound")
			if (tier == 7) ~= (sound == "ColossalPickup") then
				soundOk = false
			end
		end
	end
	check(labels == 0, "no pod carries a label of any kind", table.concat(words, ", "))
	check(#words == 0, "and no pod carries any text at all", table.concat(words, ", "))
	check(soundOk, "the Colossal still asks for its own pickup sound, which is not a label")
end

--==============================================================================
-- 6. WHAT THE REST OF THE GAME READS OFF A POD
--==============================================================================
say("\n-- the contract --")
do
	local attrsOk, quietOk, ventOk, coreOk, inertOk, nameOk = true, true, true, true, true, true
	local detail = ""
	for _, id in ipairs(FIVE) do
		local sp = SeedData.Get(id)
		for tier = 1, 7 do
			local pod = pods[id][tier]
			if pod:GetAttribute("SpeciesId") ~= id or pod:GetAttribute("Tier") ~= tier
				or pod:GetAttribute("Rarity") ~= sp.Rarity
				or pod:GetAttribute("Stage") ~= CreatureModel.STAGE_POD then
				attrsOk = false
				detail ..= string.format(" %s T%d", id, tier)
			end
			if pod.Name ~= "Pod_" .. id then
				nameOk = false
			end
			local emitters, added = 0, 0
			for _, d in ipairs(pod:GetDescendants()) do
				if d:IsA("ParticleEmitter") then
					emitters += 1
				elseif d:IsA("PointLight") and (d.Name == "AuraGlow" or d.Name == "CoreGlow") then
					added += 1
				end
				if d:IsA("BasePart") and (not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch) then
					inertOk = false
				end
			end
			-- The owner's own lights burn at every tier; the tier adds nothing below Titan.
			if tier <= 5 and (emitters > 0 or added > 0) then
				quietOk = false
				detail ..= string.format(" %s T%d lit", id, tier)
			elseif tier >= 6 and (emitters == 0 or added == 0) then
				quietOk = false
				detail ..= string.format(" %s T%d dark", id, tier)
			end
			if tier == 6 then
				local vent = pod.PrimaryPart:FindFirstChild("EmberVent")
				ventOk = ventOk and vent ~= nil and vent:FindFirstChild("EmberTrail") ~= nil
			elseif tier == 7 then
				local core = pod:FindFirstChild("Core")
				coreOk = coreOk and core ~= nil and core.Material == Enum.Material.Neon
					and core:FindFirstChild("CoreGlow") ~= nil and core:FindFirstChild("AuraAttachment") ~= nil
			end
		end
	end
	check(attrsOk, "species, rarity, tier and stage are on the model for the services to read", detail)
	check(nameOk, "the model name is the one CarryService and NestService look for")
	check(inertOk, "every part is anchored, with collide, query and touch off")
	check(quietOk, "tiers 1 to 5 add no glow of their own; the Titan and the Colossal do", detail)
	check(ventOk, "the Titan's vent still trails embers off its top")
	check(coreOk, "the Colossal burns a Neon core with its light and its aura")
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
