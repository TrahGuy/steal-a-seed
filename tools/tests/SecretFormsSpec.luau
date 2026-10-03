--!nocheck
--==============================================================================
-- Steal a Seed :: SecretFormsSpec
--
-- The two secret plants and their pods (2026-10-01): the templates are the
-- inserted models, the builders replay them at their authored size by species
-- id, the client animator's tree reproduces the authored pose at rest and moves
-- it when stepped, and the species sit outside every pool. Run with the shared
-- runner, Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SecretFormsSpec"))
--
-- NOT HERE, verified in Play instead: the overhead carry on a real character,
-- the camera, placement, the hatch, the nest spawn and the guardian.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local SecretForms = require(Shared.SecretForms)
local SecretModel = require(Shared.SecretModel)
local SecretIdle = require(Shared.SecretIdle)
local CreatureModel = require(Shared.CreatureModel)
local HatchRoll = require(Shared.HatchRoll)
local AlmanacData = require(Shared.AlmanacData)

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else ""
end

local scratch = Instance.new("Folder")
scratch.Name = "__SecretFormsSpec"
scratch.Archivable = false
scratch.Parent = workspace

-- What the generator measured on the inserted originals, 2026-10-01.
local ORIGINALS = {
	snarlbloom = { parts = 103, motors = 21, welds = 81, size = Vector3.new(31.588, 47.260, 27.262), kind = "plant" },
	petalfawn = { parts = 106, motors = 27, welds = 78, size = Vector3.new(11.659, 38.760, 24.082), kind = "plant" },
	greenhollowsecretpod = { parts = 102, motors = 0, welds = 0, size = Vector3.new(46.613, 40.502, 31.711), kind = "pod" },
	starbloomsecretpod = { parts = 80, motors = 0, welds = 0, size = Vector3.new(17.010, 21.449, 17.010), kind = "pod" },
}

local function near(a, b, tol)
	return math.abs(a - b) <= tol
end
local function sizeNear(a, b, tol)
	return near(a.X, b.X, tol) and near(a.Y, b.Y, tol) and near(a.Z, b.Z, tol)
end
local function count(model)
	local parts, motors, welds, scripts = 0, 0, 0, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("Motor6D") then
			motors += 1
		elseif d:IsA("Weld") then
			welds += 1
		elseif d:IsA("LuaSourceContainer") then
			scripts += 1
		end
	end
	return parts, motors, welds, scripts
end

local ok, err = pcall(function()
	--======================================================================
	say("-- the templates are the originals --")
	--======================================================================
	for id, want in pairs(ORIGINALS) do
		local spec = SecretForms.Plants[id] or SecretForms.Pods[id]
		check(spec ~= nil, id .. " has a template")
		if spec then
			check(spec.PartCount == want.parts and #spec.Parts == want.parts, id .. " keeps every part", #spec.Parts)
			local motors, welds = 0, 0
			for _, j in ipairs(spec.Joints) do
				if j.k == "Motor6D" then
					motors += 1
				elseif j.k == "Weld" then
					welds += 1
				end
			end
			check(motors == want.motors and welds == want.welds, id .. " keeps every joint", motors .. "/" .. welds)
			check(sizeNear(spec.Size, want.size, 0.01), id .. " records the authored size", tostring(spec.Size))
			check(spec.Kind == want.kind, id .. " is a " .. want.kind)
			for i, p in ipairs(spec.Parts) do
				if p.s ~= "Block" and p.s ~= "Ball" and p.s ~= "Cylinder" and p.s ~= "Wedge" then
					check(false, id .. " part " .. i .. " is a primitive", p.s)
					break
				end
			end
		end
	end
	check(SecretForms.Pods.greenhollowsecretpod.Yaw == 180, "the Greenhollow pod is stored facing -Z (yawed 180)")

	--======================================================================
	say("\n-- the species rows, outside every pool --")
	--======================================================================
	local snarl, fawn = SeedData.Get("snarlbloom"), SeedData.Get("petalfawn")
	check(snarl and fawn, "both secrets resolve by id")
	check(snarl and snarl.Rarity == "Secret" and snarl.Biome == "greenhollow" and snarl.Secret == true, "Snarlbloom is Greenhollow's Secret")
	check(fawn and fawn.Rarity == "Secret" and fawn.Biome == "starbloom" and fawn.Secret == true, "Petalfawn is Starbloom's Secret")
	-- They walk now (2026-10-02): no NoWander, and the Colossal rung for their size.
	check(snarl and snarl.Animator == "secret" and snarl.Carry == "overhead" and snarl.NoWander == nil
			and snarl.WanderTier == SeedData.TierCount and snarl.Pod == "greenhollowsecretpod",
		"Snarlbloom carries the secret flags")
	check(fawn and fawn.Animator == "secret" and fawn.Carry == "overhead" and fawn.NoWander == nil
			and fawn.WanderTier == SeedData.TierCount and fawn.Pod == "starbloomsecretpod",
		"Petalfawn carries the secret flags")
	check(SeedData.SecretByBiome.greenhollow == "snarlbloom" and SeedData.SecretByBiome.starbloom == "petalfawn",
		"SecretByBiome names the two")
	check(#SeedData.Species == 25, "the listed species are still 25", #SeedData.Species)
	for _, biome in ipairs({ "greenhollow", "starbloom" }) do
		local inPool = false
		for _, sp in ipairs(SeedData.InBiome(biome)) do
			if sp.Secret then
				inPool = true
			end
		end
		check(not inPool, biome .. "'s pool has no secret")
		check(#AlmanacData.SpeciesIn(biome) == 5, biome .. "'s Index shelf is still five", #AlmanacData.SpeciesIn(biome))
		local rng = Random.new(20261001)
		local rolled = false
		for _ = 1, 3000 do
			local sp = SeedData.Roll(biome, rng)
			if sp and sp.Secret then
				rolled = true
			end
		end
		check(not rolled, biome .. " never rolls a secret in 3,000 draws")
	end
	local frames = HatchRoll.candidates("nubkin")
	local leaks = false
	for _, id in ipairs(frames) do
		if id == "snarlbloom" then
			leaks = true
		end
	end
	check(not leaks, "a Greenhollow hatch roll never shows the secret's silhouette")
	local own = HatchRoll.frames("snarlbloom", 7)
	check(#own > 0 and own[#own].speciesId == "snarlbloom", "a secret's own roll ends on the secret")
	local _, total = AlmanacData.TotalProgress({})
	check(total == 25, "the Index total is still 25", total)

	--======================================================================
	say("\n-- the builders replay them by id, at the authored size --")
	--======================================================================
	for _, id in ipairs({ "snarlbloom", "petalfawn" }) do
		local sp = SeedData.Get(id)
		local want = ORIGINALS[id]
		local sizes = {}
		for _, tier in ipairs({ 1, 7 }) do
			local model = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, CFrame.new(0, 0, 0), scratch)
			local parts, motors, welds, scripts = count(model)
			local _, size = model:GetBoundingBox()
			sizes[tier] = size
			check(model.PrimaryPart ~= nil and model.PrimaryPart.Name == "Base" and model.PrimaryPart.Transparency == 1,
				id .. " tier " .. tier .. ": the invisible Base is the PrimaryPart")
			check(parts == want.parts + 1, id .. " tier " .. tier .. ": every part plus the Base", parts)
			check(motors == want.motors and welds == want.welds, id .. " tier " .. tier .. ": every joint", motors .. "/" .. welds)
			check(scripts == 0, id .. " tier " .. tier .. ": no script in the built model")
			check(sizeNear(size, want.size, 0.08), id .. " tier " .. tier .. ": the authored size, not the tier's", tostring(size))
			local anchored, flat = true, true
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					if not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch then
						anchored = false
					end
					if d.Parent ~= model then
						flat = false
					end
				end
			end
			check(anchored, id .. " tier " .. tier .. ": anchored, no collide/query/touch")
			check(flat, id .. " tier " .. tier .. ": parts are direct children")
			local bottom = 1e9
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") and d.Transparency < 1 then
					bottom = math.min(bottom, d.Position.Y - d.Size.Y / 2)
				end
			end
			check(near(bottom, 0, 0.05), id .. " tier " .. tier .. ": the lowest drawn point is on the ground", bottom)
			check(CollectionService:HasTag(model, SecretModel.RIG_TAG) and model:GetAttribute("SecretForm") == id,
				id .. " tier " .. tier .. ": tagged for the animator")
			if tier == 1 then
				-- The kinematic tree at rest reproduces the authored placement.
				local before = {}
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("BasePart") then
						before[d] = d.CFrame
					end
				end
				local rig = SecretIdle.Rig(model)
				check(rig ~= nil and #rig.order == want.parts, id .. ": the tree reaches every authored part", rig and #rig.order)
				SecretIdle.Rest(rig)
				local worst = 0
				for d, cf in pairs(before) do
					worst = math.max(worst, (d.CFrame.Position - cf.Position).Magnitude,
						(d.CFrame.LookVector - cf.LookVector).Magnitude, (d.CFrame.UpVector - cf.UpVector).Magnitude)
				end
				check(worst < 1e-3, id .. ": rest pose equals the authored pose", worst)
				SecretIdle.Step(rig, 1.0)
				local moved = 0
				for d, cf in pairs(before) do
					if (d.CFrame.Position - cf.Position).Magnitude > 1e-3 then
						moved += 1
					end
				end
				check(moved > 10, id .. ": a step moves the rig (" .. moved .. " parts)")
				model:SetAttribute("ProceduralIdle", false)
				SecretIdle.Step(rig, 2.0)
				worst = 0
				for d, cf in pairs(before) do
					worst = math.max(worst, (d.CFrame.Position - cf.Position).Magnitude)
				end
				check(worst < 1e-3, id .. ": ProceduralIdle=false puts it back to rest", worst)
			end
			model:Destroy()
		end
		check(sizeNear(sizes[1], sizes[7], 1e-3), id .. ": tier 1 and tier 7 build the same size")
		local pod = CreatureModel.BuildPod(sp, 1, CFrame.new(10, 0, 0), scratch)
		local wantPod = ORIGINALS[sp.Pod]
		local parts = count(pod)
		local _, psize = pod:GetBoundingBox()
		check(pod.PrimaryPart ~= nil and pod.PrimaryPart.Name == "Shell" and pod.PrimaryPart.Transparency == 1,
			sp.Pod .. ": an invisible Shell is the PrimaryPart")
		check(pod.PrimaryPart and near(pod.PrimaryPart.Position.Y, 0.1, 0.01), sp.Pod .. ": the Shell sits at the BASE",
			pod.PrimaryPart and pod.PrimaryPart.Position.Y)
		check(parts == wantPod.parts + 1, sp.Pod .. ": every part plus the Shell", parts)
		check(sizeNear(psize, wantPod.size, 0.08), sp.Pod .. ": the authored size", tostring(psize))
		check(pod:GetAttribute("SecretForm") == sp.Pod and pod:GetAttribute("SpeciesId") == id, sp.Pod .. ": stamped")
		pod:Destroy()
	end
	-- Two builds are the same build.
	local a = CreatureModel.Build(SeedData.Get("snarlbloom"), 1, CreatureModel.STAGE_GROWN, CFrame.new(), scratch)
	local b = CreatureModel.Build(SeedData.Get("snarlbloom"), 1, CreatureModel.STAGE_GROWN, CFrame.new(), scratch)
	local same = true
	local ac, bc = a:GetChildren(), b:GetChildren()
	for i, d in ipairs(ac) do
		local e = bc[i]
		if not (e and d.Name == e.Name and d.ClassName == e.ClassName) then
			same = false
		elseif d:IsA("BasePart") and (d.CFrame ~= e.CFrame or d.Size ~= e.Size or d.Color ~= e.Color) then
			same = false
		end
	end
	check(same and #ac == #bc, "two builds of Snarlbloom are identical")
	a:Destroy()
	b:Destroy()

	--======================================================================
	say("\n-- the carry, the camera, the sway: wiring --")
	--======================================================================
	check(GameConfig.Carry.OverheadLift == 3.0, "GameConfig.Carry.OverheadLift is 3.0")
	local carrySrc = sourceOf(Server, "CarryService")
	check(string.find(carrySrc, 'Carry == "overhead"', 1, true) ~= nil and string.find(carrySrc, "OverheadLift", 1, true) ~= nil,
		"CarryService grips an overhead species at OverheadLift")
	check(string.find(carrySrc, "attachInFront(model, root, takenTier, taken)", 1, true) ~= nil,
		"a taken pod is attached with its species")
	local poseSrc = sourceOf(Scripts, "CarryPose")
	check(string.find(poseSrc, "OVERHEAD_LIFT", 1, true) ~= nil and string.find(poseSrc, "carriesOverhead", 1, true) ~= nil,
		"CarryPose has the arms-up variant")
	-- Moved here from SecretFootprintSpec when the footprint rules were retired
	-- (2026-10-02): the fix it pinned is a carry fix, not a placement one.
	local _, straightLoops = string.gsub(poseSrc, "for _, side in ipairs%(rig%.straight%) do", "")
	check(string.find(poseSrc, "if s > STRAIGHT_FLOOR then", 1, true) ~= nil and straightLoops == 1,
		"an ordinary carry leaves the elbows and wrists to the animation (written only for the overhead pose)")
	local swaySrc = sourceOf(Scripts, "PlantSway")
	check(string.find(swaySrc, "not entry.pod and not secretRig", 1, true) ~= nil, "PlantSway skips its rigs for a secret")
	local plantSrc = sourceOf(Server, "PlantService")
	check(string.find(plantSrc, "SeedData.WanderTierOf(entry.species, entry.tier)", 1, true) ~= nil
			and string.find(plantSrc, "NoWander", 1, true) == nil,
		"PlantService walks a secret like any grown creature, on its own rung (SecretWalkSpec has the rest)")
	local camSrc = sourceOf(Scripts, "SecretCarryCamera")
	check(string.find(camSrc, "CameraMinZoomDistance = math.max(kept.min, distance)", 1, true) ~= nil,
		"the carry camera raises the zoom floor, never a lock")
	check(string.find(camSrc, "CharacterRemoving:Connect(restore)", 1, true) ~= nil
		and string.find(camSrc, "humanoid.Died:Connect(restore)", 1, true) ~= nil, "the carry camera restores on death and leave")
	local throwSrc = sourceOf(Scripts, "ThrowFX")
	check(string.find(throwSrc, "SeedCarryCamMin", 1, true) ~= nil, "a throw restores the player's own zoom, not the carry's")
	local idleSrc = sourceOf(Scripts, "SecretIdle")
	check(idleSrc ~= "" and string.find(idleSrc, "RenderStepped", 1, true) ~= nil, "the client animator exists")
	-- A plant streams in and its pivot can land a frame after its tag: waiting, not
	-- dropping, is what keeps a planted rig animated (found in Play, 2026-10-01).
	check(string.find(idleSrc, "if not model.PrimaryPart or not model:IsDescendantOf(workspace) then", 1, true) ~= nil
		and string.find(idleSrc, 'GetPropertyChangedSignal("PrimaryPart"):Connect(dirty)', 1, true) ~= nil,
		"the client animator waits for a pivot that arrives late, and rebuilds when it does")
end)

scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("SecretFormsSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
