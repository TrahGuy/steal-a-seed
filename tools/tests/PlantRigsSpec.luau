--!nocheck
--==============================================================================
-- Steal a Seed :: PlantRigsSpec
--
-- The ordinary plants built from the owner's supplied rigs (2026-10-03):
-- PlantForms holds all twenty-five as data, CreatureModel builds the approved
-- ones from it at their tier's size and the rest the old way, SecretIdle plays
-- each rig's idle and steps its legs by the distance walked, and nothing about
-- a species but its body changed. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlantRigsSpec"))
--
-- The walks are simulated the way PlantSway draws one (SecretWalkSpec's way):
-- the pivot carried along a line on a 20 Hz slice at the tier's pace while
-- SecretIdle.Step runs every frame. Not here, seen in Play instead: real legs
-- from PlantService, the carry, the hatch, the Index and the hotbar previews.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.SeedGame.Shared
local Scripts = StarterPlayer.StarterPlayerScripts
local Server = ServerScriptService.SeedGameServer
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local PlantForms = require(Shared.PlantForms)
local PlantIdles = require(Shared.PlantIdles)
local SecretModel = require(Shared.SecretModel)
local SecretIdle = require(Shared.SecretIdle)
local CreatureModel = require(Shared.CreatureModel)

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
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

local IDS = {
	"nubkin", "petalpip", "spiretip", "toadcap", "bellchime",
	"dunebud", "paddlehop", "thornwhorl", "raincup", "suncrown",
	"bogbonnet", "crookreed", "snapmoss", "lanterncap", "gloomlotus",
	"cinderpaw", "emberquill", "slagbloom", "kilnhusk", "pyrelotus",
	"novaorb", "cosmospire", "voidpetal", "astralhorn", "supernovus",
}
-- Sized on their LONGEST side at Tiny (the owner's choice, 2026-10-03): their
-- longest side before the swap, which for both was their height.
local LONGEST = { snapmoss = 6.74, emberquill = 7.46 }
-- How many legs each walk steps (0: it hops).
local LEGS = {
	nubkin = 2, petalpip = 2, spiretip = 2, toadcap = 2, dunebud = 2, paddlehop = 2, bogbonnet = 2,
	bellchime = 0, thornwhorl = 0, lanterncap = 0, novaorb = 0, cosmospire = 0,
	cinderpaw = 4, snapmoss = 4, kilnhusk = 2, crookreed = 4, emberquill = 2, slagbloom = 4,
	voidpetal = 4, astralhorn = 4, raincup = 4, suncrown = 4, gloomlotus = 4, pyrelotus = 4, supernovus = 4,
}
-- The ones whose scripts never blinked (SuperNovus has no eyes).
local NO_BLINK = { supernovus = true }

local scratch = Instance.new("Folder")
scratch.Name = "ZZPlantRigsSpec"
scratch.Archivable = false
scratch.Parent = workspace

-- The drawn extents (visible parts only) in the model's own frame.
local function drawn(model)
	local pivot = model:GetPivot()
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.999 then
			local h = d.Size / 2
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local c = pivot:PointToObjectSpace((d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
						lo = lo:Min(c)
						hi = hi:Max(c)
					end
				end
			end
		end
	end
	return hi - lo, lo
end

local function bad(v)
	return v ~= v or math.abs(v) == math.huge
end
local function cfBad(cf)
	for _, x in ipairs({ cf:GetComponents() }) do
		if bad(x) then
			return true
		end
	end
	return false
end

-- The size every tier is built to: its Tiny height (or, for the two sized on
-- their longest side, that side) times the ladder.
local function wantAt(id, tier)
	local mul = SeedData.SizeScale(tier)
	if LONGEST[id] then
		return LONGEST[id] * mul, "longest"
	end
	return PlantForms.TinyHeight[id] * mul, "height"
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The data: twenty-five supplied rigs, whole, mapped by name")
	--==========================================================================
	-- Since 2026-10-05 it also holds the Rain event's second family, four rigs
	-- built at their supplied size x the ladder (PlantForms.Supplied); they are
	-- RainFamilySpec's, and none of the twenty-five is one of them.
	local formCount, supplied = 0, 0
	for id in pairs(PlantForms.Plants) do
		formCount += 1
		if PlantForms.Supplied[id] then
			supplied += 1
		end
	end
	local roadSupplied = {}
	for _, id in ipairs(IDS) do
		if PlantForms.Supplied[id] then
			table.insert(roadSupplied, id)
		end
	end
	check(formCount == 25 + 4 and supplied == 4 and #roadSupplied == 0,
		"PlantForms holds the twenty-five supplied road rigs, and the Rain event's four apart from them",
		formCount .. " forms, " .. supplied .. " Supplied, road ones Supplied: " .. table.concat(roadSupplied, ","))
	for _, id in ipairs(IDS) do
		local spec = PlantForms.Plants[id]
		local sp = SeedData.Get(id)
		if not (spec and sp) then
			check(false, id .. ": a form and a species", tostring(spec) .. " " .. tostring(sp))
			continue
		end
		local good = #spec.Parts == spec.PartCount and spec.Parts[spec.Base] ~= nil and spec.Height > 0
		for _, j in ipairs(spec.Joints) do
			if not (spec.Parts[j.a] and spec.Parts[j.b]) or j.a == j.b then
				good = false
			end
		end
		local motors = 0
		for _, j in ipairs(spec.Joints) do
			if j.k == "Motor6D" then
				motors += 1
			end
		end
		check(good and motors > 0 and string.lower(string.match(spec.Source, "/(.+)$") or "") == id
				and sp.Biome ~= nil and not sp.Secret and sp.Event == nil,
			string.format("%s: %d parts, %d joints (%d motors), every joint between two of its parts; a listed %s species",
				id, #spec.Parts, #spec.Joints, motors, tostring(sp.Biome)))
		check(PlantForms.Has(id) and (PlantForms.TinyLongest[id] == LONGEST[id])
				and ((PlantForms.TinyHeight[id] ~= nil) == (LONGEST[id] == nil)),
			id .. (if LONGEST[id] then ": built from its rig, sized on its longest Tiny side" else ": built from its rig, sized on its Tiny height"))
	end

	--==========================================================================
	say("2. Built at every tier's size, whole, on the same contract as before")
	--==========================================================================
	local x = 0
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		local spec = PlantForms.Plants[id]
		local worstHeight, worstPose, flagsOk, contractOk, countsOk = 0, 0, true, true, true
		for tier = 1, SeedData.TierCount do
			x += 40
			local model = CreatureModel.BuildCreature(sp, tier, CreatureModel.STAGE_GROWN, CFrame.new(x, 0, 0), scratch)
			local want, rule = wantAt(id, tier)
			local size, lo = drawn(model)
			local got = if rule == "longest" then math.max(size.X, size.Y, size.Z) else size.Y
			worstHeight = math.max(worstHeight, math.abs(got - want) / want, math.abs(lo.Y) / want)
			-- The contract every creature keeps.
			local base = model.PrimaryPart
			if not (base and base.Name == "Base" and base.Transparency == 1
				and model:GetAttribute("SpeciesId") == id and model:GetAttribute("Tier") == tier
				and model:GetAttribute("Rarity") == sp.Rarity and model:GetAttribute("Stage") == CreatureModel.STAGE_GROWN
				and model:GetAttribute("SecretForm") == id
				and math.abs((model:GetAttribute("RigScale") or 0) - PlantForms.Scale(id, SeedData.SizeScale(tier))) < 1e-6
				and CollectionService:HasTag(model, GameConfig.Tags.Creature)
				and CollectionService:HasTag(model, SecretModel.RIG_TAG)) then
				contractOk = false
			end
			-- Every part replayed, the way every plant's are: anchored, no collisions.
			local parts, joints, other = 0, 0, 0
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					parts += 1
					if not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch then
						flagsOk = false
					end
				elseif d:IsA("Motor6D") or d:IsA("Weld") then
					joints += 1
				elseif d:IsA("LuaSourceContainer") or d:IsA("AnimationController") or d:IsA("Animator")
					or d:IsA("Humanoid") or d:IsA("WeldConstraint") then
					other += 1
				end
			end
			if parts ~= spec.PartCount + 1 or joints ~= #spec.Joints or other ~= 0 then
				countsOk = false
			end
			-- The kinematic tree at rest is the replayed placement, exactly.
			if tier == 1 or tier == SeedData.TierCount then
				local before = {}
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("BasePart") then
						before[d] = d.CFrame
					end
				end
				local rig = SecretIdle.Rig(model)
				SecretIdle.Rest(rig)
				for part, cf in pairs(before) do
					worstPose = math.max(worstPose, (part.Position - cf.Position).Magnitude
						+ (part.CFrame.LookVector - cf.LookVector).Magnitude + (part.CFrame.UpVector - cf.UpVector).Magnitude)
				end
			end
			model:Destroy()
		end
		check(worstHeight < 0.01, string.format("%s: every tier is its Tiny %s x the ladder, on the soil (worst %.2f%%)",
			id, if LONGEST[id] then "longest side" else "height", worstHeight * 100))
		check(contractOk, id .. ": the invisible Base pivot, the species, tier, rarity and stage, the rig tag and its scale")
		check(flagsOk and countsOk, string.format("%s: %d parts and %d joints, all anchored and non-colliding; no scripts or animators",
			id, spec.PartCount + 1, #spec.Joints))
		check(worstPose < 1e-3, string.format("%s: the tree at rest is the authored pose at Tiny and Colossal (%.1e)", id, worstPose))
	end
	do
		local sp = SeedData.Get("nubkin")
		local grown = CreatureModel.BuildCreature(sp, 3, CreatureModel.STAGE_GROWN, CFrame.new(0, 0, 80), scratch)
		local sprout = CreatureModel.BuildCreature(sp, 3, CreatureModel.STAGE_SPROUT, CFrame.new(10, 0, 80), scratch)
		local g, s = drawn(grown), drawn(sprout)
		check(math.abs(s.Y / g.Y - 0.45) < 0.005, string.format("a sprout is the grown rig at 0.45 (%.3f)", s.Y / g.Y))
		grown:Destroy()
		sprout:Destroy()
	end

	--==========================================================================
	say("3. Each rig idles, blinks and walks on the existing system")
	--==========================================================================
	local FPS, SLICE = 60, 3
	for _, id in ipairs(IDS) do
		for _, tier in ipairs({ 1, SeedData.TierCount }) do
			local sp = SeedData.Get(id)
			local spec = PlantForms.Plants[id]
			local scale = PlantForms.Scale(id, SeedData.SizeScale(tier))
			local cf = CFrame.new(0, 0, 200)
			local function make(at)
				return CreatureModel.BuildCreature(sp, tier, CreatureModel.STAGE_GROWN, at, scratch)
			end
			local model = make(cf)
			local still = make(cf * CFrame.new(60, 0, 0))
			local carried = make(cf * CFrame.new(120, 0, 0))
			local rig, stillRig, carriedRig = SecretIdle.Rig(model), SecretIdle.Rig(still), SecretIdle.Rig(carried)
			local tag = string.format("%s %s", id, SeedData.TierName(tier))
			local gait = rig and rig.gait
			if not (rig and gait and rig.plant and PlantIdles.Idles[id]) then
				check(false, tag .. ": a rig, an idle and a walk", tostring(rig) .. " " .. tostring(gait))
				model:Destroy()
				still:Destroy()
				carried:Destroy()
				continue
			end
			check(#gait.legs == LEGS[id], string.format("%s: the walk finds its %d legs", tag, LEGS[id]), #gait.legs)
			rig.walks, stillRig.walks, carriedRig.walks = true, true, false
			local height = spec.Height * scale
			-- The point of each foot that stands on the step, tracked in the world.
			local feet = {}
			local pivot0 = model:GetPivot()
			for i, leg in ipairs(gait.legs) do
				local joint = if leg.kind == "swing" then (leg.swingAnkle or leg.hip)
					elseif leg.kind == "foot" then leg.foot else leg.ankle
				local part = nil
				for _, node in ipairs(rig.nodes) do
					if node.motor == joint then
						part = node.part
					end
				end
				local sole = pivot0 * leg.ankleAt
				feet[i] = { part = part, at = part and part.CFrame:PointToObjectSpace(sole), rest = sole.Y,
					down = nil, slip = 0, sink = 0, lift = 0, stances = 0 }
			end
			local speed = SeedData.WanderSpeed(tier)
			local home = model:GetPivot()
			local frames = 6 * FPS
			local z, travelled, cycles, lastPhase = 0, 0, 0, gait.phase
			local nan, moved, blinked, idleMoved, carriedStill = false, false, false, false, true
			local eyes0 = {}
			for _, e in ipairs(rig.plant.eyes) do
				eyes0[e.part] = e.part.Size
			end
			local lidsAt = rig.pose
			local rootPart = rig.nodes[rig.rootNode].part
			local lowest = math.huge
			for f = 1, frames + 4 * FPS do
				local now = 100 + f / FPS
				local walking = f <= frames
				if walking and f % SLICE == 0 then
					local step = speed * SLICE / FPS
					z -= step
					travelled += step
					model:PivotTo(home * CFrame.new(0, 0, z))
					carried:PivotTo(home * CFrame.new(120, 0, z))
				end
				local wasMoving = gait.moving
				SecretIdle.Step(rig, now)
				SecretIdle.Step(stillRig, now)
				SecretIdle.Step(carriedRig, now)
				if walking and wasMoving then
					cycles += (gait.phase - lastPhase) % 1
				end
				lastPhase = gait.phase
				if carriedRig.gait and carriedRig.gait.weight > 0 then
					carriedStill = false
				end
				for _, node in ipairs(rig.nodes) do
					if cfBad(node.part.CFrame) then
						nan = true
					end
				end
				for _, e in ipairs(stillRig.plant.eyes) do
					if e.part.Size.Y < e.size.Y * 0.5 then
						blinked = true
					end
				end
				if (stillRig.pose.LeftEyelid and stillRig.pose.LeftEyelid.Position.Y < -1e-3) then
					blinked = true
				end
				for name, value in pairs(stillRig.pose) do
					if value ~= CFrame.identity then
						idleMoved = true
					end
				end
				-- The feet, once it is under way.
				if walking and f > FPS then
					for i, leg in ipairs(gait.legs) do
						local foot = feet[i]
						if foot.part then
							local p = foot.part.CFrame * foot.at
							if leg.down then
								if not foot.down then
									foot.down = p
									foot.stances += 1
								end
								foot.slip = math.max(foot.slip, Vector3.new(p.X - foot.down.X, 0, p.Z - foot.down.Z).Magnitude)
								foot.sink = math.max(foot.sink, math.abs(p.Y - foot.rest))
							else
								foot.down = nil
								foot.lift = math.max(foot.lift, p.Y - foot.rest)
							end
						end
					end
				end
				-- A hop leaves the soil; nothing else does.
				local y = (model:GetPivot():Inverse() * rootPart.CFrame).Position.Y
				lowest = math.min(lowest, y)
				if gait.weight > 0.5 then
					moved = true
				end
			end
			local want = travelled / gait.stride
			check(not nan and moved, tag .. ": the walk comes on, and no part ever leaves the numbers")
			check(math.abs(cycles - want) < 0.15 * want + 0.1,
				string.format("%s: %.2f strides for %.1f studs (%.2f expected): the steps follow the distance", tag, cycles,
					travelled, want))
			if #gait.legs > 0 then
				-- The least lift of any foot that took a step (a Colossal walks less
				-- than a stride in six seconds, so not every foot gets one).
				local slip, sink, lift, stances = 0, 0, math.huge, 0
				for _, foot in ipairs(feet) do
					slip = math.max(slip, foot.slip)
					sink = math.max(sink, foot.sink)
					if foot.stances > 1 then
						lift = math.min(lift, foot.lift)
					end
					stances += foot.stances
				end
				check(stances >= #feet and slip < 0.03 * height and sink < 0.03 * height,
					string.format("%s: a planted foot stays put on the soil (slip %.3f, off it %.3f, of %.1f tall; %d stances)",
						tag, slip, sink, height, stances))
				check(lift > 0.4 * gait.profile.lift * gait.scale,
					string.format("%s: and every foot lifts when it steps (least %.3f studs)", tag, lift))
			end
			check(carriedStill, tag .. ": a copy that is not planted never steps, however it is moved")
			check(idleMoved and (blinked or NO_BLINK[id]),
				tag .. (if NO_BLINK[id] then ": idles (no eyes to blink)" else ": idles and blinks"))
			-- Standing again: the walk fades out and the legs come home.
			check(gait.weight < 0.05 and gait.legWeight < 0.05,
				string.format("%s: stops walking when the model stops (%.2f, %.2f)", tag, gait.weight, gait.legWeight))
			SecretIdle.Rest(rig)
			model:Destroy()
			still:Destroy()
			carried:Destroy()
		end
	end

	--==========================================================================
	say("4. Wired through the existing builders and animators, and nowhere else")
	--==========================================================================
	local creatureSrc = sourceOf(Shared, "CreatureModel")
	check(string.find(creatureSrc, "local rigScale = PlantForms.Scale(sp.Id, SeedData.SizeScale(tier))", 1, true)
			and string.find(creatureSrc, "SecretModel.BuildPlantForm(sp.Id, cf, model, rigScale * scale)", 1, true),
		"CreatureModel builds an approved species from its rig at the tier's size (and the sprout's)")
	local swaySrc = sourceOf(Scripts, "PlantSway")
	check(string.find(swaySrc, "local secretRig = (species :: any).Animator == \"secret\" or model:GetAttribute(\"SecretForm\") ~= nil",
			1, true) ~= nil,
		"PlantSway leaves a replayed rig's limbs to SecretIdle and moves only the whole model")
	--==========================================================================
	-- THE OVERHEAD CARRY (2026-10-03): a hatched rigged plant rides over the
	-- head like a Secret; its pod, and any other species, does not.
	--==========================================================================
	local table_ = {
		{ "nubkin", true, true }, { "nubkin", false, false }, { "snapmoss", true, true }, { "emberquill", false, false },
		{ "supernovus", true, true }, { "snarlbloom", true, true }, { "snarlbloom", false, true },
		{ "puddlepod", false, true },
	}
	local truth = true
	for _, row in ipairs(table_) do
		if PlantForms.CarriedOverhead(SeedData.Get(row[1]), row[2]) ~= row[3] then
			truth = false
		end
	end
	check(truth and PlantForms.CarriedOverhead(nil, true) == false,
		"carried overhead: every hatched rigged plant and every Secret/Rain form; a rigged species' POD keeps its old carry")
	local size = PlantForms.SizeAt("astralhorn", SeedData.SizeScale(SeedData.TierCount))
	check(size ~= nil and math.abs(size.Y - PlantForms.TinyHeight.astralhorn * SeedData.SizeScale(SeedData.TierCount)) < 0.05,
		string.format("the carry camera's size for a Colossal Astralhorn is its built height (%.1f)", size and size.Y or -1))
	local carrySrc = sourceOf(Server, "CarryService")
	check(string.find(carrySrc, "local grip = if PlantForms.CarriedOverhead(species, true)", 1, true) ~= nil
			and string.find(carrySrc, "-- A secret (SeedData Carry = \"overhead\") rides over the head in both hands:", 1, true) ~= nil
			and select(2, string.gsub(carrySrc, "if species and %(species :: any%)%.Carry == \"overhead\" then", "")) == 1,
		"CarryService: a hatched rigged plant is welded at OverheadLift; gripFor (pods) is unchanged")
	check(string.find(sourceOf(Scripts, "CarryPose"), "return PlantForms.CarriedOverhead(species, hatched)", 1, true) ~= nil
			and string.find(sourceOf(Scripts, "SecretCarryCamera"), "if not species or not PlantForms.CarriedOverhead(species, hatched) then", 1, true) ~= nil,
		"CarryPose raises both arms and the carry camera frames it, by the same rule")
	check(string.find(sourceOf(Scripts, "CarryPose"), "local function clearHandGrip(character: Model)", 1, true) ~= nil,
		"CarryPose drops a client-only hand grip on a handle the carry owns, so the right hand stays in the pose")
	-- 2026-10-03: the respawn pose. The neutral is never read off a playing animation.
	local poseSrc = sourceOf(Scripts, "CarryPose")
	check(string.find(poseSrc, "rest = CFrame.identity, sign = entry[3] :: number,", 1, true) ~= nil
			and not string.find(poseSrc, "rest = joint.Transform", 1, true)
			and not string.find(poseSrc, "rest = m.C0", 1, true)
			and string.find(poseSrc, "m:SetAttribute(REST_C0, m.C0)", 1, true) ~= nil
			and string.find(poseSrc, "gripWatch = character.DescendantAdded:Connect", 1, true) ~= nil,
		"CarryPose: identity is an AnimationConstraint's neutral, a Motor6D's authored C0 is kept; one grip watch per body")
	check(string.find(carrySrc, "local function dropStaleGrips(character: Model?)", 1, true) ~= nil
			and string.find(carrySrc, "task.delay(0.5, dropStaleGrips, character)", 1, true) ~= nil
			and string.find(carrySrc, "table.insert(serviceConnections, tool.Destroying:Connect(function()", 1, true) ~= nil,
		"CarryService: a late hand grip on a put-away carry Tool's own Handle is removed; a Tool destroyed in the hands cuts its watch")
	check(string.find(swaySrc, "amp = math.min(amp, math.asin(math.clamp(0.01 * headHeight / halfFoot, 0, 1)))", 1, true) ~= nil,
		"PlantSway: a supplied rig's whole-model lean dips its footprint's edge at most 1% of its height")
	check(string.find(carrySrc, "if type(form) == \"string\" and PlantForms.Plants[form] then", 1, true) ~= nil
			and string.find(carrySrc, "if d:IsA(\"Motor6D\") or d:IsA(\"Weld\") then", 1, true) ~= nil,
		"a held copy drops its joints (welded whole to the Handle, out of the character Animator's reach)")
	check(SecretModel.HasPlant("nubkin") == false and SecretModel.HasPlant("snarlbloom") == true,
		"the Secret and Rain lookups still mean only those sets")

	--==========================================================================
	say("5. Emberquill's new rig (2026-10-03): the owner's model, its idle, a biped walk")
	--==========================================================================
	do
		local spec = PlantForms.Plants.emberquill
		local motors, holds = 0, 0
		for _, j in ipairs(spec.Joints) do
			if j.k == "Motor6D" then
				motors += 1
			elseif j.n == "Hold" then
				holds += 1
			end
		end
		check(spec.Source == "Workspace/Emberquill" and #spec.Parts == 49 and motors == 26 and holds == 22
				and spec.Unit == 4 and math.abs((spec.ModelScale or 0) - 1.334448) < 1e-5
				and #spec.Lights == 1 and #spec.Emitters == 1,
			string.format("the data is the new Workspace model: %d parts, %d motors, %d welds, its wick light and embers",
				#spec.Parts, motors, holds))
		local tall = math.max(spec.Size.X, spec.Size.Y, spec.Size.Z)
		check(tall == spec.Size.Y and math.abs(PlantForms.Scale("emberquill", 1) * spec.Size.Y - 7.46) < 1e-6,
			string.format("its longest side is its height, 7.46 at Tiny (x %.4f)", PlantForms.Scale("emberquill", 1)))
		local walk = PlantIdles.Walks.emberquill
		check(walk and #walk.legs == 2 and walk.legs[1].hip == "HipL" and walk.legs[2].ankle == "AnkleR"
				and #walk.arms == 2,
			"its walk is a biped's: two hip-knee-ankle chains, the paws swinging against them")
		local sp = SeedData.Get("emberquill")
		local model = CreatureModel.BuildCreature(sp, 1, CreatureModel.STAGE_GROWN, CFrame.new(0, 0, -200), scratch)
		local rig = SecretIdle.Rig(model)
		local flameRest, flameMax, flame = nil, 0, nil
		local backPosed, crestPosed, flamePosed, legsIdle = false, false, false, true
		for _, part in ipairs(rig.plant.sized) do
			if part.part.Name == "Flame" then
				flame = part
				flameRest = part.size
			end
		end
		local base = flame and flame.part:GetAttribute("BaseSize")
		for f = 0, 12 * 30 do
			local now = 300 + f / 30
			SecretIdle.Step(rig, now)
			if rig.pose.Back3 and rig.pose.Back3 ~= CFrame.identity then
				backPosed = true
			end
			if rig.pose.Crest1 and rig.pose.Crest1 ~= CFrame.identity then
				crestPosed = true
			end
			if rig.pose.WickFlame and rig.pose.WickFlame.Position.Y ~= 0 then
				flamePosed = true
			end
			for _, n in ipairs({ "HipL", "HipR", "KneeL", "KneeR", "AnkleL", "AnkleR" }) do
				if rig.pose[n] and rig.pose[n] ~= CFrame.identity then
					legsIdle = false
				end
			end
			if flame then
				flameMax = math.max(flameMax, flame.part.Size.Y)
			end
		end
		check(#rig.plant.eyes == 4 and #rig.plant.sized == 2 and rig.plant.sides.Back2 == -1 and rig.plant.sides.Back3 == 1,
			string.format("its idle finds the eyes and pupils (%d), the flame (%d) and each back quill's side",
				#rig.plant.eyes, #rig.plant.sized))
		check(backPosed and crestPosed and flamePosed and legsIdle,
			"the quills ripple and bristle, the flame lifts out of its cup, and standing it never moves its legs")
		check(flame ~= nil and typeof(base) == "Vector3" and flameRest.Y > base.Y * 1.2 and flameMax > flameRest.Y * 1.4,
			string.format("the flame grows from the size it was built at (%.3f), not the stale BaseSize (%.3f): up to %.3f",
				flameRest and flameRest.Y or -1, typeof(base) == "Vector3" and base.Y or -1, flameMax))
		SecretIdle.Rest(rig)
		model:Destroy()
	end
end)

scratch:Destroy()
if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nPlantRigsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
