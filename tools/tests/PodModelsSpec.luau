--!nocheck
--==============================================================================
-- Steal a Seed :: PodModelsSpec (2026-10-09)
--
-- THE OWNER'S 25 PODS IN THE GAME (KB/POD-MODELS-PLAN.md, approved "approve but
-- let claude terminal build"). Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PodModelsSpec"))
--
-- What it holds the pods to:
--   1. PodForms is the owner's 25, one per ordinary plant, lifted losslessly:
--      the counts the generator measured, and -- where the owner's Workspace
--      folders are in the place -- every part replayed at the size supplied
--      standing exactly where the owner's does;
--   2. the pod contract at all 7 sizes (CreatureModel.BuildPod's, through
--      PodModel): name, attributes, an invisible upright Shell, everything
--      anchored and inert, no Scripts, no text, PickupSound at Colossal;
--   3. the box: at most 1.25 D wide and 1.45 D tall and touching one, the lid
--      pods at exactly their designed ClosedWidth / ClosedHeight;
--   4. the size colour on a lid pod's own SizeSeam; no base and no ring on any
--      pod (the owner, 2026-10-09: the base each stood on is left out);
--   5. the top two tiers' vent, aura and core;
--   6. PodMotion: every recipe finds its joints and lights; a step moves only
--      what its waving joints carry (nothing breathes: the owner, 2026-10-09);
--      rest is exact; a lid peeks and stands open when ready;
--   7. the wiring the rest of the game needs (source pins).
--
-- The real modules, fresh-required. What it builds goes in one folder in the
-- Workspace (PodMotion moves anchored parts with BulkMoveTo) and is destroyed.
-- The owner's folders are only read.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))
local PodForms = require(Shared:WaitForChild("PodForms"))
local PodModel = require(Shared:WaitForChild("PodModel"))
local PodMotion = require(Shared:WaitForChild("PodMotion"))

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 0.01)
end
local function sameColor(a, b)
	return math.round(a.R * 255) == math.round(b.R * 255) and math.round(a.G * 255) == math.round(b.G * 255)
		and math.round(a.B * 255) == math.round(b.B * 255)
end
local function cfNear(a, b, eps)
	local d = a:ToObjectSpace(b)
	return d.Position.Magnitude <= eps and (d.LookVector - Vector3.new(0, 0, -1)).Magnitude <= eps * 4
		and (d.UpVector - Vector3.yAxis).Magnitude <= eps * 4
end

local CFG = GameConfig.PodModels
local BOX_W, BOX_H = CFG.MaxWidth, CFG.MaxHeight
local TIERS = SeedData.TierCount

-- What the read-only generator measured in the owner's 25 (2026-10-09), less the base each stood on: parts,
-- Motor6Ds, Welds and WeldConstraints, stud textures, lights and SpecialMeshes.
local COUNTS = {
	nubkin = { parts = 60, motors = 2, welds = 57, textures = 360, lights = 1, meshes = 0 },
	petalpip = { parts = 42, motors = 5, welds = 36, textures = 222, lights = 1, meshes = 2 },
	spiretip = { parts = 32, motors = 2, welds = 29, textures = 180, lights = 1, meshes = 3 },
	toadcap = { parts = 46, motors = 1, welds = 44, textures = 0, lights = 1, meshes = 0 },
	bellchime = { parts = 52, motors = 1, welds = 50, textures = 0, lights = 1, meshes = 0 },
	dunebud = { parts = 18, motors = 1, welds = 16, textures = 96, lights = 1, meshes = 6 },
	paddlehop = { parts = 34, motors = 1, welds = 32, textures = 198, lights = 1, meshes = 25 },
	thornwhorl = { parts = 42, motors = 5, welds = 36, textures = 222, lights = 1, meshes = 2 },
	raincup = { parts = 36, motors = 5, welds = 30, textures = 168, lights = 2, meshes = 8 },
	suncrown = { parts = 77, motors = 8, welds = 68, textures = 408, lights = 2, meshes = 5 },
	bogbonnet = { parts = 31, motors = 1, welds = 23, textures = 0, lights = 0, meshes = 0 },
	crookreed = { parts = 61, motors = 9, welds = 51, textures = 306, lights = 2, meshes = 4 },
	snapmoss = { parts = 43, motors = 1, welds = 41, textures = 0, lights = 0, meshes = 0 },
	lanterncap = { parts = 52, motors = 1, welds = 44, textures = 300, lights = 2, meshes = 12 },
	gloomlotus = { parts = 42, motors = 1, welds = 37, textures = 0, lights = 1, meshes = 0 },
	cinderpaw = { parts = 52, motors = 5, welds = 46, textures = 174, lights = 2, meshes = 3 },
	emberquill = { parts = 66, motors = 1, welds = 64, textures = 378, lights = 2, meshes = 3 },
	slagbloom = { parts = 42, motors = 1, welds = 40, textures = 0, lights = 1, meshes = 0 },
	kilnhusk = { parts = 46, motors = 1, welds = 44, textures = 0, lights = 0, meshes = 0 },
	pyrelotus = { parts = 47, motors = 1, welds = 45, textures = 0, lights = 1, meshes = 0 },
	novaorb = { parts = 47, motors = 1, welds = 45, textures = 0, lights = 1, meshes = 0 },
	cosmospire = { parts = 50, motors = 1, welds = 48, textures = 0, lights = 1, meshes = 0 },
	voidpetal = { parts = 54, motors = 1, welds = 26, textures = 0, lights = 0, meshes = 0 },
	astralhorn = { parts = 42, motors = 1, welds = 40, textures = 0, lights = 1, meshes = 0 },
	supernovus = { parts = 58, motors = 1, welds = 56, textures = 0, lights = 1, meshes = 0 },
}
-- The owner's source folders: moved, intact, from the Workspace to ServerStorage
-- (2026-10-09, the owner's approval), where their 25 scripts never run.
local FOLDERS = {
	greenhollow = "greenhollow pods", dustbowl = "dustbowl pods", tanglemire = "tanglemire pods",
	emberroot = "emberroot pods", starbloom = "starbloom pods",
}

local fixture = Instance.new("Folder")
fixture.Name = "ZZPodModelsSpecFixture"
fixture.Parent = Workspace

-- A built model's own counts.
local function countsOf(model)
	local c = { parts = 0, motors = 0, welds = 0, textures = 0, lights = 0, meshes = 0, scripts = 0, guis = 0,
		emitters = 0 }
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			c.parts += 1
		elseif d:IsA("Motor6D") then
			c.motors += 1
		elseif d:IsA("Weld") or d:IsA("WeldConstraint") then
			c.welds += 1
		elseif d:IsA("Texture") then
			c.textures += 1
		elseif d:IsA("PointLight") then
			c.lights += 1
		elseif d:IsA("SpecialMesh") then
			c.meshes += 1
		elseif d:IsA("LuaSourceContainer") then
			c.scripts += 1
		elseif d:IsA("LayerCollector") or d:IsA("TextLabel") then
			c.guis += 1
		elseif d:IsA("ParticleEmitter") then
			c.emitters += 1
		end
	end
	return c
end

-- A pod's drawn box in its base frame: visible parts only (the Shell is
-- invisible; the seam ring and the core are the game's, not the owner's).
local function drawn(model, cf)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.99 and d.Name ~= PodModel.CORE then
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
	return hi - lo, lo
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE OWNER'S 25, LOSSLESSLY
	--==========================================================================
	say("-- the owner's 25 --")
	local ordinary = {}
	for _, sp in ipairs(SeedData.Species) do
		if sp.Secret ~= true then
			table.insert(ordinary, sp)
		end
	end
	local missing, extra, biomeOk = {}, {}, true
	for _, sp in ipairs(ordinary) do
		if not PodForms.Has(sp.Id) then
			table.insert(missing, sp.Id)
		end
	end
	local BIOMES = { "greenhollow", "dustbowl", "tanglemire", "emberroot", "starbloom" }
	for i, id in ipairs(PodForms.Ids) do
		local sp = SeedData.Get(id)
		if not (sp and sp.Secret ~= true) then
			table.insert(extra, id)
		elseif sp.Biome ~= BIOMES[math.ceil(i / 5)] then
			biomeOk = false
		end
	end
	check(#PodForms.Ids == 25 and #missing == 0, "every ordinary plant has the owner's pod, 25 in all",
		table.concat(missing, ","))
	check(#extra == 0 and biomeOk, "and PodForms holds exactly those, five per biome as the owner's folders do",
		table.concat(extra, ","))
	local countsOk, totals = true, { parts = 0, textures = 0, lights = 0 }
	local detail = ""
	for id, want in pairs(COUNTS) do
		local spec = PodForms.Pods[id]
		local model = Instance.new("Model")
		local parts = SecretModel.Replay(spec, CFrame.new(0, -500, 0), model, nil, 1, true)
		local c = countsOf(model)
		totals.parts += c.parts
		totals.textures += c.textures
		totals.lights += c.lights
		for _, k in ipairs({ "parts", "motors", "welds", "textures", "lights", "meshes" }) do
			if c[k] ~= want[k] then
				countsOk = false
				detail ..= string.format(" %s %s=%d want %d", id, k, c[k], want[k])
			end
		end
		if #parts ~= spec.PartCount or spec.PartCount ~= want.parts then
			countsOk = false
		end
		model:Destroy()
	end
	check(countsOk, "replayed at the size supplied, each has the owner's parts, joints, stud textures, lights and meshes",
		detail)
	check(totals.parts == 1172 and totals.textures == 3012 and totals.lights == 27,
		"1,172 parts, 3,012 stud textures and 27 lights in all: Studio's 1,207, 3,102 and 27 less the 35 base parts",
		string.format("%d %d %d", totals.parts, totals.textures, totals.lights))

	-- Against the originals themselves, when they are in this place: the replay
	-- at the size supplied, built at the original's own base, part for part --
	-- every part but the base the owner had left out (each form's Removed).
	local compared, off, offDetail = 0, 0, ""
	for _, id in ipairs(PodForms.Ids) do
		local sp = SeedData.Get(id)
		local folder = ServerStorage:FindFirstChild(FOLDERS[sp.Biome]) or Workspace:FindFirstChild(FOLDERS[sp.Biome])
		local original = folder and folder:FindFirstChild(sp.Name .. "Pod")
		if original and original:IsA("Model") and original.PrimaryPart then
			local spec = PodForms.Pods[id]
			local root = original.PrimaryPart
			local look = root.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z).Unit
			if PodForms.IsStudded(id) then
				flat = -flat
			end
			local frame0 = CFrame.new(root.Position) * CFrame.lookAt(Vector3.zero, flat)
			local lo = Vector3.new(math.huge, math.huge, math.huge)
			local hi = -lo
			local originals = {}
			local gone = {}
			for _, name in ipairs(spec.Removed or {}) do
				gone[name] = true
			end
			for _, d in ipairs(original:GetDescendants()) do
				if d:IsA("BasePart") and not gone[d.Name] then
					table.insert(originals, d)
					if d.Transparency < 0.999 then
						local h = d.Size / 2
						for _, sx in ipairs({ -1, 1 }) do
							for _, sy in ipairs({ -1, 1 }) do
								for _, sz in ipairs({ -1, 1 }) do
									local c = frame0:PointToObjectSpace((d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
									lo = lo:Min(c)
									hi = hi:Max(c)
								end
							end
						end
					end
				end
			end
			local mid = (lo + hi) / 2
			local base = frame0 * CFrame.new(mid.X, lo.Y, mid.Z)
			local model = Instance.new("Model")
			local parts = SecretModel.Replay(spec, base, model, nil, 1, true)
			compared += 1
			for i, o in ipairs(originals) do
				local p = parts[i]
				local mesh = o:FindFirstChildOfClass("SpecialMesh")
				local pmesh = if p then p:FindFirstChildOfClass("SpecialMesh") else nil
				local same = p ~= nil and p.ClassName == o.ClassName and p.Name == o.Name
					and (p.Size - o.Size).Magnitude < 1e-3 and cfNear(p.CFrame, o.CFrame, 2e-3)
					and sameColor(p.Color, o.Color) and p.Material == o.Material and near(p.Transparency, o.Transparency, 1e-4)
					and (not o:IsA("Part") or (p :: any).Shape == (o :: any).Shape)
					and (mesh == nil) == (pmesh == nil)
					and (mesh == nil or (pmesh.MeshType == mesh.MeshType and (pmesh.Scale - mesh.Scale).Magnitude < 1e-4
						and (pmesh.Offset - mesh.Offset).Magnitude < 1e-4))
				if same then
					local ot, pt = 0, 0
					for _, c in ipairs(o:GetChildren()) do
						if c:IsA("Texture") then
							ot += 1
						end
					end
					for _, c in ipairs(p:GetChildren()) do
						if c:IsA("Texture") then
							pt += 1
						end
					end
					same = ot == pt
				end
				if not same then
					off += 1
					if #offDetail < 400 then
						offDetail ..= string.format(" %s#%d %s", id, i, o.Name)
					end
				end
			end
			model:Destroy()
		end
	end
	if compared == 0 then
		say("  ..    the owner's pod folders are not in this place: the part-for-part comparison was not run")
	else
		check(compared == 25 and off == 0, string.format(
			"every part of the %d originals in this place is replayed exactly where, and as, the owner built it",
			compared), offDetail)
	end
	-- In the Workspace a publish would put the originals in the live map, and their 25 PodAnimate /
	-- PodOpening scripts would run in every server.
	local inWorkspace = {}
	for _, name in pairs(FOLDERS) do
		if Workspace:FindFirstChild(name) then
			table.insert(inWorkspace, name)
		end
	end
	check(#inWorkspace == 0, "none of the owner's five pod folders is in the Workspace (they live in ServerStorage)",
		table.concat(inWorkspace, ", "))

	--==========================================================================
	-- 2-5. EVERY POD AT EVERY SIZE
	--==========================================================================
	say("\n-- the contract, the box, the colour and the top tiers, at all " .. TIERS .. " sizes --")
	local contractOk, inertOk, shellOk, noScripts, noText, soundOk, tagOk = true, true, true, true, true, true, true
	local grownOk, baseOk = true, true
	local fitOk, fillOk, designedOk, groundOk, seamOk, keptOk, ringOk, quietOk, titanOk, colossalOk =
		true, true, true, true, true, true, true, true, true, true
	local d1, d2, d3, d4 = "", "", "", ""
	-- No shadows (2026-10-09, the owner's approval); a pale pod's softer Colossal glow, by species.
	local shadowOk, glowOk, d5 = true, true, ""
	local glowK = {}
	for n, id in ipairs(PodForms.Ids) do
		local sp = SeedData.Get(id)
		local spec = PodForms.Pods[id]
		local seamParts = 0
		for _, p in ipairs(spec.Parts) do
			if p.g == "SizeSeam" then
				seamParts += 1
			end
		end
		for tier = 1, TIERS do
			local D = SeedData.PodDiameter(tier)
			local cf = CFrame.new(n * 30, 200 + tier * 30, 0) * CFrame.Angles(0, math.rad(tier * 20), 0)
			local pod = CreatureModel.BuildPod(sp, tier, cf, fixture)
			local c = countsOf(pod)
			-- 2. the contract
			if pod.Name ~= "Pod_" .. id or pod:GetAttribute("SpeciesId") ~= id or pod:GetAttribute("Tier") ~= tier
				or pod:GetAttribute("Rarity") ~= sp.Rarity or pod:GetAttribute("Stage") ~= CreatureModel.STAGE_POD
				or pod:GetAttribute(PodModel.FORM_ATTRIBUTE) ~= id
				or typeof(pod:GetAttribute(PodModel.REST_ATTRIBUTE)) ~= "CFrame" then
				contractOk = false
				d1 ..= string.format(" %s T%d", id, tier)
			end
			for _, d in ipairs(pod:GetDescendants()) do
				if d:IsA("BasePart") and (not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch) then
					inertOk = false
				elseif d:IsA("Light") and d.Shadows then
					shadowOk = false
					d5 ..= string.format(" %s T%d %s", id, tier, d.Name)
				end
			end
			local shell = pod.PrimaryPart
			local size, lo = drawn(pod, cf)
			local tall = math.min(D, size.Y)
			if not (shell and shell.Name == "Shell" and shell.Parent == pod and shell.Transparency == 1
				and cfNear(shell.CFrame, cf * CFrame.new(0, tall / 2, 0), 1e-3)
				and near(shell.Size.Y, tall, 1e-3)) then
				shellOk = false
				d1 ..= string.format(" %s T%d shell", id, tier)
			end
			if c.scripts > 0 then
				noScripts = false
			end
			if c.guis > 0 then
				noText = false
			end
			if (tier == TIERS) ~= (pod:GetAttribute("PickupSound") == "ColossalPickup") then
				soundOk = false
			end
			if not CollectionService:HasTag(pod, PodModel.TAG) or pod.ModelStreamingMode ~= Enum.ModelStreamingMode.Atomic then
				tagOk = false
			end
			-- Studs and meshes grow with the pod: every stud tile and mesh offset at the pod's factor.
			local scale = pod:GetAttribute(PodModel.SCALE_ATTRIBUTE)
			local replayedParts = {}
			for _, p in ipairs(pod:GetChildren()) do
				if p:IsA("BasePart") and p.Name ~= "Shell" and p.Name ~= PodModel.CORE then
					table.insert(replayedParts, p)
				end
			end
			for i, ps in ipairs(spec.Parts) do
				local p = replayedParts[i]
				local mesh = p and p:FindFirstChildOfClass("SpecialMesh")
				if ps.sm and not (mesh and (mesh.Offset - ps.sm.o * scale).Magnitude < 1e-4
					and (mesh.Scale - ps.sm.s).Magnitude < 1e-6) then
					grownOk = false
				end
			end
			for _, tx in ipairs(spec.Textures or {}) do
				local host = replayedParts[tx.p]
				local t = host and host:FindFirstChildOfClass("Texture")
				if not (t and near(t.StudsPerTileU, tx.u * scale, 1e-4) and near(t.StudsPerTileV, tx.v * scale, 1e-4)) then
					grownOk = false
				end
				break
			end
			-- 3. the box
			local width = math.max(size.X, size.Z)
			if width / D > BOX_W + 0.002 or size.Y / D > BOX_H + 0.002 then
				fitOk = false
				d2 ..= string.format(" %s T%d %.3fx%.3f", id, tier, width / D, size.Y / D)
			end
			local designed = PodForms.DesignedWidth(id)
			if designed then
				local owner = spec.Owner
				-- The owner's ClosedWidth is the pod's side along its own X (its front is -Z). Its ClosedHeight
				-- counted the base, now left out, so the pod stands lower than it, never taller.
				if not (near(size.X / D, designed, 0.003) and size.Y / D < owner.ClosedHeight) then
					designedOk = false
					d2 ..= string.format(" %s T%d %.3fx%.3f want %.3f wide, under %.3f", id, tier, size.X / D, size.Y / D,
						designed, owner.ClosedHeight)
				end
			elseif not near(math.max(width / D / BOX_W, size.Y / D / BOX_H), 1, 0.002) then
				fillOk = false
				d2 ..= string.format(" %s T%d fills %.3f", id, tier, math.max(width / D / BOX_W, size.Y / D / BOX_H))
			end
			if not near(lo.Y, 0, 0.002) then
				groundOk = false
			end
			-- 4. the size colour, and no base (the owner, 2026-10-09)
			local tierColour = SeedData.ColorForTier(tier)
			local gone = {}
			for _, name in ipairs(spec.Removed or {}) do
				gone[name] = true
			end
			for _, p in ipairs(pod:GetDescendants()) do
				if p:IsA("BasePart") and (gone[p.Name] or p.Name == "SeamRing") then
					baseOk = false
					d3 ..= string.format(" %s T%d %s", id, tier, p.Name)
				end
			end
			if #(spec.Removed or {}) == 0 then
				baseOk = false
				d3 ..= " " .. id .. " left nothing out"
			end
			if seamParts > 0 then
				local coloured = 0
				for _, p in ipairs(pod:GetChildren()) do
					if p:IsA("BasePart") and p:GetAttribute(SecretModel.GROUP_ATTRIBUTE) == "SizeSeam"
						and sameColor(p.Color, tierColour) then
						coloured += 1
					end
				end
				if coloured ~= seamParts then
					seamOk = false
					d3 ..= string.format(" %s T%d %d/%d", id, tier, coloured, seamParts)
				end
				-- Nothing but the seam is repainted: every other owner's part keeps its colour.
				local replayed = {}
				for _, p in ipairs(pod:GetChildren()) do
					if p:IsA("BasePart") and p.Name ~= "Shell" and p.Name ~= PodModel.CORE then
						table.insert(replayed, p)
					end
				end
				local kept = #replayed == #spec.Parts
				for i, ps in ipairs(spec.Parts) do
					local p = replayed[i]
					if ps.g ~= "SizeSeam" and not (p and sameColor(p.Color, ps.c)) then
						kept = false
					end
				end
				if not kept then
					keptOk = false
					d3 ..= string.format(" %s T%d repainted", id, tier)
				end
			end
			-- Nothing is added to show the size (no ring, no plate): the owner's parts, the Shell, and the
			-- Colossal's core are every part there is.
			if c.parts ~= spec.PartCount + 1 + (if tier == TIERS then 1 else 0) then
				ringOk = false
				d3 ..= string.format(" %s T%d %d parts", id, tier, c.parts)
			end
			-- 5. the top tiers
			local added = 0
			for _, d in ipairs(pod:GetDescendants()) do
				if d:IsA("PointLight") and (d.Name == "AuraGlow" or d.Name == "CoreGlow") then
					added += 1
				end
			end
			if tier < 6 then
				if c.emitters > 0 or added > 0 or pod:FindFirstChild(PodModel.CORE) then
					quietOk = false
					d4 ..= string.format(" %s T%d", id, tier)
				end
			elseif tier == 6 then
				local vent = shell and shell:FindFirstChild("EmberVent")
				local top = if vent then (shell.CFrame * vent.Position).Y - cf.Y else nil
				if not (vent and vent:FindFirstChild("EmberTrail") and shell:FindFirstChild("AuraAttachment")
					and shell:FindFirstChild("AuraGlow") and top and top >= size.Y) then
					titanOk = false
					d4 ..= string.format(" %s T6", id)
				end
			elseif tier == 7 then
				local core = pod:FindFirstChild(PodModel.CORE)
				if not (core and core.Material == Enum.Material.Neon and core:FindFirstChild("CoreGlow")
					and core:FindFirstChild("AuraAttachment") and shell and (core.Position - shell.Position).Magnitude < 1e-3
					and core.Size.X < math.max(size.X, size.Z) and core.Size.Y < size.Y) then
					colossalOk = false
					d4 ..= string.format(" %s T7", id)
				end
				-- Its two lights follow its own brightness (PaleGlow), measured here on its own: the visible
				-- parts' mean luminance, by area. The halo is the one it always had.
				local sum, weight = 0, 0
				for _, p in ipairs(replayedParts) do
					if p.Transparency < 0.99 then
						local s = p.Size
						local area = 2 * (s.X * s.Y + s.Y * s.Z + s.Z * s.X) * (1 - p.Transparency)
						sum += (0.2126 * p.Color.R + 0.7152 * p.Color.G + 0.0722 * p.Color.B) * area
						weight += area
					end
				end
				local P = CFG.PaleGlow
				local t = math.clamp((sum / weight - P.From) / (P.To - P.From), 0, 1)
				local k, r = 1 - t * (1 - P.Floor), 1 - t * (1 - P.RangeFloor)
				glowK[id] = k
				local coreGlow = core and core:FindFirstChild("CoreGlow")
				local auraGlow = core and core:FindFirstChild("AuraGlow")
				local att = core and core:FindFirstChild("AuraAttachment")
				local halo = att and att:FindFirstChild("AuraPulse")
				if not (coreGlow and auraGlow and halo and near(coreGlow.Brightness, 1.6 * k, 1e-4)
					and near(coreGlow.Range, D * 2.4 * r, 1e-3) and near(auraGlow.Brightness, 2.2 * k, 1e-4)
					and near(auraGlow.Range, D * 2.0 * r, 1e-3) and near(halo.Transparency.Keypoints[2].Value, 0.62, 1e-4)
					and near(halo.Size.Keypoints[2].Value, D * 1.30, 1e-3)) then
					glowOk = false
					d5 ..= string.format(" %s glow k %.2f", id, k)
				end
			end
			pod:Destroy()
		end
	end
	check(contractOk, "named Pod_<id>, with species, rarity, tier, stage, its form and its root's rest", d1)
	check(inertOk, "every part anchored, with collide, query and touch off")
	check(shellOk, "the PrimaryPart is an invisible upright Shell, a direct child, half a D up (or the pod's middle if shorter)", d1)
	check(noScripts, "no Script came in with any pod")
	check(noText, "and no label or text either")
	check(soundOk, "PickupSound at Colossal and nowhere else")
	check(tagOk, "each is tagged for PodMotion and streams whole")
	check(grownOk, "its stud tiles and its meshes' offsets grow with it, as the owner built them, only bigger")
	check(fitOk, "every pod fits 1.25 of its diameter across and 1.45 tall at every size", d2)
	check(fillOk, "and the ones without a designed size fill that box, touching its width or its height", d2)
	check(designedOk, "the lid pods keep their designed ClosedWidth, standing lower than their ClosedHeight by the base", d2)
	check(groundOk, "every pod's lowest point is its base")
	check(seamOk, "a lid pod's own SizeSeam parts all take the tier's colour", d3)
	check(keptOk, "and nothing else on it is repainted", d3)
	check(baseOk, "no pod keeps the base it stood on, and none wears a ring (the owner, 2026-10-09)", d3)
	check(ringOk, "nothing is added to show the size: the owner's parts, the Shell and a Colossal's core are all there is", d3)
	check(quietOk, "Tiny to Giant add no aura, no vent and no core", d4)
	check(titanOk, "a Titan's vent trails off its top, its aura round the Shell", d4)
	check(colossalOk, "a Colossal burns a Neon core inside it, its light and stronger aura on the core", d4)
	local casters = 0
	for _, id in ipairs(PodForms.Ids) do
		for _, l in ipairs(PodForms.Pods[id].Lights or {}) do
			if l.shadows then
				casters += 1
			end
		end
	end
	-- Sixteen of the owner's lights cast shadows: ten StudioFillLights and six of the pods' own (EmberCoreLight,
	-- MarshGlow, CandleLight, LanternLight, GoldGlow, SolarGlow).
	check(shadowOk and casters == 16, string.format("no light on any built pod casts shadows (%d of the owner's did)",
		casters), d5)
	check(glowOk, "a Colossal's two lights follow its own brightness (PaleGlow): strength and reach; the halo as it was", d5)
	local paleSofter, darkFull, palestFloor = true, true, true
	local d6 = ""
	for _, id in ipairs(PodForms.Ids) do
		local biome = SeedData.Get(id).Biome
		local k = glowK[id]
		if (biome == "greenhollow" or biome == "dustbowl") and not (k and k < 1) then
			paleSofter = false
			d6 ..= string.format(" %s %s", id, tostring(k))
		elseif (biome == "emberroot" or biome == "starbloom") and k ~= 1 then
			darkFull = false
			d6 ..= string.format(" %s %s", id, tostring(k))
		end
	end
	for _, id in ipairs({ "bellchime", "lanterncap", "petalpip", "toadcap", "gloomlotus" }) do
		if not (glowK[id] and near(glowK[id], CFG.PaleGlow.Floor, 1e-9)) then
			palestFloor = false
			d6 ..= string.format(" %s %s", id, tostring(glowK[id]))
		end
	end
	check(paleSofter and darkFull and palestFloor,
		"every Greenhollow and Dustbowl pod's Colossal glow is softer, the palest five at the floor; Emberroot and "
			.. "Starbloom keep theirs in full", d6)

	--==========================================================================
	-- 6. POD MOTION
	--==========================================================================
	say("\n-- PodMotion --")
	local recipeOk, lightOk, lidOk, movesOk, fixedOk, restOk, peekOk, readyOk, studdedReadyOk =
		true, true, true, true, true, true, true, true, true
	local m1, m2 = "", ""
	local stillOk, fewOk = true, true
	-- A moment a lid's peek stands open (half its PeekSeconds in), for the one step below.
	local peekOpenAt = CFG.Motion.PeekSeconds / 2
	for n, id in ipairs(PodForms.Ids) do
		local sp = SeedData.Get(id)
		-- Near the origin: a float's last place out at 600 studs is the size of the error this measures.
		local cf = CFrame.new(-40, 60, n * 12)
		local pod = CreatureModel.BuildPod(sp, 4, cf, fixture)
		local built = {}
		for _, d in ipairs(pod:GetDescendants()) do
			if d:IsA("BasePart") then
				built[d] = d.CFrame
			end
		end
		local rig = PodMotion.Rig(pod)
		if not rig then
			recipeOk = false
			m1 ..= " " .. id .. " no rig"
		else
			local joints = {}
			for _, node in ipairs(rig.nodes) do
				if node.joint then
					joints[node.joint] = true
				end
			end
			if PodForms.IsStudded(id) then
				for _, name in ipairs(PodMotion.RecipeJoints[id] or {}) do
					if not joints[name] then
						recipeOk = false
						m1 ..= " " .. id .. ":" .. name
					end
				end
				for _, name in ipairs(PodMotion.RecipeLights[id] or {}) do
					if not rig.lamps[name] then
						lightOk = false
						m1 ..= " " .. id .. ":" .. name
					end
				end
				if not PodMotion.Studded[id] then
					recipeOk = false
				end
			elseif rig.lidJoint ~= PodMotion.LID_JOINT then
				lidOk = false
				m1 ..= " " .. id .. " lid"
			end
			-- One step (a studded pod's idle clock from zero; a lid pod mid-peek): the parts its waving joints
			-- carry move, and nothing else does -- not the root, not the body (nothing breathes), not what the
			-- owner kept still, not the Shell or the core.
			rig.cycle = 0
			PodMotion.Step(rig, peekOpenAt - rig.phase, 0.8, false)
			local carried = {}
			for _, i in ipairs(rig.moving) do
				carried[rig.nodes[i].part] = true
			end
			local anyMoved = false
			for part, was in pairs(built) do
				if carried[part] then
					if not cfNear(part.CFrame, was, 1e-4) then
						anyMoved = true
					end
				elseif not cfNear(part.CFrame, was, 1e-5) then
					stillOk = false
					m2 ..= " " .. id .. ":" .. part.Name
				end
			end
			if #rig.moving == 0 or not anyMoved then
				movesOk = false
				m2 ..= " " .. id .. " still"
			end
			-- Only what a waving joint carries is ever written: the parts below one of the idle's joints,
			-- counted here up each part's own chain, and never the whole pod.
			local waving = {}
			for _, name in ipairs(if PodForms.IsStudded(id) then (PodMotion.RecipeJoints[id] or {}) else { PodMotion.LID_JOINT }) do
				waving[name] = true
			end
			local expected = 0
			for _, node in ipairs(rig.nodes) do
				local at = node
				local under = false
				while at do
					if at.joint and waving[at.joint] then
						under = true
						break
					end
					at = if at.parent then rig.nodes[at.parent] else nil
				end
				if under then
					expected += 1
				end
			end
			if #rig.moving ~= expected or expected >= #rig.nodes then
				fewOk = false
				m2 ..= string.format(" %s %d/%d (want %d)", id, #rig.moving, #rig.nodes, expected)
			end
			if not PodForms.IsStudded(id) then
				-- Its peek never opens past PeekOpen; ready, it stands open.
				local most = 0
				for t = 0, CFG.Motion.PeekEvery, 0.05 do
					most = math.max(most, PodMotion.PeekAt(t))
				end
				if most > CFG.Motion.PeekOpen + 1e-6 or most < CFG.Motion.PeekOpen * 0.9 then
					peekOk = false
				end
				for _ = 1, 40 do
					PodMotion.Step(rig, 10, 0.1, true)
				end
				if not near(rig.open, CFG.Motion.ReadyOpen, 0.01) then
					readyOk = false
					m2 ..= string.format(" %s open %.2f", id, rig.open)
				end
			else
				local before = rig.cycle
				PodMotion.Step(rig, 1, 0.1, true)
				local hurried = rig.cycle - before
				before = rig.cycle
				PodMotion.Step(rig, 1.1, 0.1, false)
				if not near(hurried, (rig.cycle - before) * CFG.Motion.ReadySpeed, 1e-6) then
					studdedReadyOk = false
				end
			end
			-- Rest is exact, the lights as built.
			PodMotion.Rest(rig)
			for part, was in pairs(built) do
				if not cfNear(part.CFrame, was, 2e-4) then
					restOk = false
					m2 ..= " " .. id .. " rest:" .. part.Name
					break
				end
			end
			for _, l in pairs(rig.lamps) do
				if not near(l.light.Brightness, l.base, 1e-6) then
					restOk = false
				end
			end
		end
		pod:Destroy()
	end
	check(recipeOk, "every studded pod's idle finds every joint its script waved", m1)
	check(lightOk, "and every light its script pulsed", m1)
	check(lidOk, "every lid pod has its LidHinge", m1)
	check(movesOk, "a step moves the parts its waving joints carry", m2)
	check(stillOk, "and nothing else: no root or body moves (nothing breathes), nor what the owner kept still, the Shell or the core", m2)
	check(fewOk, "only those parts are ever written, never the whole pod", m2)
	check(peekOk, "a lid's peek opens it a crack, never past " .. CFG.Motion.PeekOpen)
	check(readyOk, "a ready lid pod stands part way open (" .. CFG.Motion.ReadyOpen .. ")", m2)
	check(studdedReadyOk, "a ready studded pod's idle runs " .. CFG.Motion.ReadySpeed .. " times as fast")
	check(restOk, "rest puts every part back exactly where it was built, and every light as built", m2)

	--==========================================================================
	-- 7. THE WIRING (source pins)
	--==========================================================================
	say("\n-- the wiring --")
	local function sourceOf(instance)
		return if instance then (instance :: any).Source else ""
	end
	local client = sourceOf(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("PodMotion"))
	check(client:find("shell.Anchored", 1, true) ~= nil and client:find("IsDescendantOf(Workspace)", 1, true) ~= nil
			and client:find("SEED_POD", 1, true) ~= nil and client:find("PLANTED", 1, true) ~= nil
			and client:find("StatusText.reducedMotion()", 1, true) ~= nil and client:find("M.Range", 1, true) ~= nil,
		"PodMotion moves only anchored world pods (nest, loose, planted, a stand) in range, and none under REDUCED FX")
	local server = game:GetService("ServerScriptService").SeedGameServer
	local carry = sourceOf(server:FindFirstChild("CarryService"))
	local giveAt = carry:find("local ownJoints = model:GetAttribute(GameConfig.PodModels.FormAttribute) ~= nil", 1, true)
	local frontAt = carry:find("local function attachInFront", 1, true)
	check(giveAt ~= nil and frontAt ~= nil
			and carry:find("if model:GetAttribute(GameConfig.PodModels.FormAttribute) ~= nil then", frontAt, true) ~= nil
			and carry:find('if type(form) == "string" and PlantForms.Plants[form] then', 1, true) ~= nil,
		"a carried or held owner's pod drops its joints, as a held plant rig does")
	local plant = sourceOf(server:FindFirstChild("PlantService"))
	check(plant:find("if d:IsA(\"Decal\") then", 1, true) ~= nil,
		"a burst fades the pods' stud textures with their parts")
	local aura = sourceOf(Shared:FindFirstChild("PlantAura"))
	check(aura:find("p.Transparency >= 0.99", 1, true) ~= nil, "PlantAura hangs no arc off an invisible part")
end)

fixture:Destroy()
if not ok then
	fail += 1
	say("  FAIL  THREW " .. tostring(err))
end
say(string.format("\nPodModelsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
