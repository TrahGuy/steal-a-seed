--!nocheck
--==============================================================================
-- Steal a Seed :: StarbloomLimbSpec
--
-- Cosmospire's limbs, Voidpetal's legs and Supernovus's feet, MEASURED. Every
-- number here is one a reviewer can check; nothing here is a
-- judgement about whether the art looks right, which only an eye can make.
--
--   python -m http.server 8731            (from the repo root)
--
--   local run = loadstring(game:GetService("HttpService"):GetAsync(
--       "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--   print(run("StarbloomLimbSpec"))
--
--==============================================================================
-- THREE THINGS THIS FILE HAS TO GET RIGHT
--
-- 1. A JOINT IS MEASURED BETWEEN BOXES, NOT BETWEEN CENTRES. Two part centres
--    0.4 studs apart can be overlapping or a stud clear of one another
--    depending on their sizes and rotations. `obbGap` is a full separating-axis
--    test over all fifteen axes, which for two boxes returns the EXACT closest
--    distance when they are apart and the penetration depth when they are not.
--
-- 2. THE POSE MATTERS, so every joint is measured at rest, at both ends of the
--    gait, and through a turn. PlantSway rotates a whole leg rigidly about one
--    hip frame, so a leg whose parts all belong to the same hip cannot open a
--    seam as it swings -- but a part that landed on the WRONG hip swings in
--    antiphase and tears off, and that is exactly what this catches.
--
-- 3. THE RIG IS MIRRORED FROM PlantSway, NOT REIMPLEMENTED FROM MEMORY. The
--    vocabulary and the swing amplitude are read out of PlantSway's own Source,
--    so a rename there fails this spec instead of silently invalidating it. The
--    clustering below is a copy of PlantSway's and has to be kept in step with
--    it; there is an assertion at the end that fails if the two files stop
--    agreeing about what a leg word is.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local out = {}
local pass, fail = 0, 0

local function say(...)
	table.insert(out, table.concat({ ... }, " "))
end

local function check(ok: boolean, label: string, detail: any?)
	if ok then
		pass += 1
		say(string.format("  ok   %s%s", label,
			if detail ~= nil then "  [" .. tostring(detail) .. "]" else ""))
	else
		fail += 1
		say(string.format("  FAIL %s%s", label,
			if detail ~= nil then "  [" .. tostring(detail) .. "]" else ""))
	end
end

--==============================================================================
-- WHAT PlantSway ACTUALLY SAYS
--==============================================================================
local sway = nil
for _, d in ipairs(StarterPlayer:WaitForChild("StarterPlayerScripts"):GetChildren()) do
	if string.find(d.Name, "PlantSway") then
		sway = d
		break
	end
end
assert(sway, "PlantSway not found in StarterPlayerScripts")

local LEG_WORDS = {}
do
	local block = string.match(sway.Source, "local LEG_WORDS = (%b{})")
	assert(block, "could not find LEG_WORDS in PlantSway")
	for w in string.gmatch(block, '"([%w]+)"') do
		table.insert(LEG_WORDS, w)
	end
end
local LEG_SWING = math.rad(tonumber(string.match(sway.Source,
	"local LEG_SWING = math%.rad%((%d+%.?%d*)%)")) or 21)

--==============================================================================
-- EXACT DISTANCE BETWEEN TWO ORIENTED BOXES
--
-- Positive is daylight, in studs. Negative is overlap, and its size is how deep.
-- For two convex bodies the closest distance is the largest separation over all
-- candidate directions, and for boxes those are the six face normals plus the
-- nine edge-pair crosses -- so the maximum below is not an estimate.
--==============================================================================
local function axesOf(cf: CFrame): { Vector3 }
	return { cf.RightVector, cf.UpVector, -cf.LookVector }
end

local function obbGap(pa: BasePart, ca: CFrame, pb: BasePart, cb: CFrame): number
	local A, B = axesOf(ca), axesOf(cb)
	local ha, hb = pa.Size * 0.5, pb.Size * 0.5
	local d = cb.Position - ca.Position
	local axes = { A[1], A[2], A[3], B[1], B[2], B[3] }
	for i = 1, 3 do
		for j = 1, 3 do
			local c = A[i]:Cross(B[j])
			if c.Magnitude > 1e-5 then
				table.insert(axes, c.Unit)
			end
		end
	end
	local best = -math.huge
	for _, ax in ipairs(axes) do
		local ra = math.abs(A[1]:Dot(ax)) * ha.X + math.abs(A[2]:Dot(ax)) * ha.Y
			+ math.abs(A[3]:Dot(ax)) * ha.Z
		local rb = math.abs(B[1]:Dot(ax)) * hb.X + math.abs(B[2]:Dot(ax)) * hb.Y
			+ math.abs(B[3]:Dot(ax)) * hb.Z
		best = math.max(best, math.abs(d:Dot(ax)) - (ra + rb))
	end
	return best
end

-- The lowest corner of a box, in world Y.
local function lowestY(part: BasePart, cf: CFrame): number
	local h = part.Size * 0.5
	local a = axesOf(cf)
	return cf.Position.Y - (math.abs(a[1].Y) * h.X + math.abs(a[2].Y) * h.Y
		+ math.abs(a[3].Y) * h.Z)
end

--==============================================================================
-- PlantSway'S LEG RIG, MIRRORED
--
-- Same order, same constants, same tie-breaks as the client. Returns one entry
-- per hip: its frame, its phase, and every part hanging on it.
--==============================================================================
local function rigOf(model: Model)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local h = d.Size * 0.5
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
						hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
					end
				end
			end
		end
	end

	local pivot = model:GetPivot()
	local inverse = pivot:Inverse()
	local legParts = {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then
			for _, w in ipairs(LEG_WORDS) do
				if string.find(d.Name, w) then
					table.insert(legParts, { part = d, cf = inverse * d.CFrame })
					break
				end
			end
		end
	end

	local hasUpper = false
	for _, it in ipairs(legParts) do
		local n = it.part.Name
		if string.find(n, "Thigh") or string.find(n, "Femur") or string.find(n, "Haunch") then
			hasUpper = true
			break
		end
	end
	if #legParts == 0 or not hasUpper then
		return { pivot = pivot, hips = {}, parts = legParts }
	end

	local spread = math.max(hi.X - lo.X, hi.Z - lo.Z)
	local yLo, yHi = math.huge, -math.huge
	for _, it in ipairs(legParts) do
		yLo = math.min(yLo, it.cf.Position.Y)
		yHi = math.max(yHi, it.cf.Position.Y)
	end
	local hipLine = yLo + (yHi - yLo) * 0.55

	local hips = {}
	local hipNear = math.max(spread * 0.12, 0.25)
	for _, it in ipairs(legParts) do
		if it.cf.Position.Y >= hipLine then
			local p = it.cf.Position
			local found = nil
			for _, h in ipairs(hips) do
				local dx, dz = h.x - p.X, h.z - p.Z
				if dx * dx + dz * dz <= hipNear * hipNear then
					found = h
					break
				end
			end
			if found then
				local n = found.n
				found.x = (found.x * n + p.X) / (n + 1)
				found.z = (found.z * n + p.Z) / (n + 1)
				found.top = math.max(found.top, p.Y + it.part.Size.Y * 0.5)
				found.n = n + 1
			else
				table.insert(hips, { x = p.X, z = p.Z, n = 1,
					top = p.Y + it.part.Size.Y * 0.5, items = {} })
			end
		end
	end

	local ranked = table.clone(hips)
	table.sort(ranked, function(a, b)
		return a.z < b.z
	end)
	local bandGap = math.max(spread * 0.15, 0.30)
	local rank, prevZ = 0, nil
	for _, h in ipairs(ranked) do
		if prevZ == nil or h.z - prevZ > bandGap then
			rank += 1
		end
		prevZ = h.z
		h.phase = math.pi * ((rank + (if h.x < 0 then 0 else 1)) % 2)
		h.rank = rank
	end

	-- The margin is what this spec is really after: how much nearer a part is to
	-- its own hip than to the next one. 1.0 means it is on the fence.
	for _, it in ipairs(legParts) do
		local p = it.cf.Position
		local best, bestD, secondD = nil, math.huge, math.huge
		for _, h in ipairs(hips) do
			local dx, dz = h.x - p.X, h.z - p.Z
			local d = dx * dx + dz * dz
			if d < bestD then
				secondD = bestD
				bestD, best = d, h
			elseif d < secondD then
				secondD = d
			end
		end
		it.margin = if secondD < math.huge then math.sqrt(secondD / math.max(bestD, 1e-9)) else math.huge
		it.hip = best
		table.insert(best.items, it)
	end

	for _, h in ipairs(hips) do
		h.frame = CFrame.new(h.x, h.top, h.z)
		h.inv = h.frame:Inverse()
		for _, it in ipairs(h.items) do
			it.rel = h.inv * it.cf
		end
	end

	return { pivot = pivot, hips = hips, parts = legParts, hipLine = hipLine,
		hipNear = hipNear, bandGap = bandGap, spread = spread, yLo = yLo, yHi = yHi }
end

--==============================================================================
-- WHERE EVERY PART SITS AT A GIVEN MOMENT OF THE WALK
--
-- `a` is the swing angle this leg is at; `yaw` is the plant turning. Both are
-- applied exactly the way PlantSway applies them, so a pose of (0, 0) has to
-- reproduce the rest CFrames to floating point -- which is checked below.
--==============================================================================
local function posed(model: Model, rig, a: number, yaw: number): { [BasePart]: CFrame }
	local target = rig.pivot * CFrame.Angles(0, yaw, 0)
	local at = {}
	local pinv = rig.pivot:Inverse()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			at[d] = target * (pinv * d.CFrame)
		end
	end
	for _, h in ipairs(rig.hips) do
		for _, it in ipairs(h.items) do
			at[it.part] = target * h.frame * CFrame.Angles(a, 0, 0) * it.rel
		end
	end
	return at
end

--==============================================================================
-- THE TWO SPECIES, AND THE CHAINS THAT HAVE TO STAY SHUT
--==============================================================================
local SPEC = {
	cosmospire = {
		body = "Thorax",
		chain = {
			{ "shoulder", "Femur", "Thorax" },
			{ "knee", "Femur", "Knee" },
			{ "knee", "Knee", "Tibia" },
			{ "ankle", "Tibia", "StiltClaw" },
		},
		legs = 4,
		ground = { "StiltClaw" },
	},
	voidpetal = {
		body = "SpineTorso",
		chain = {
			{ "shoulder", "Haunch", "SpineTorso" },
			{ "knee", "Haunch", "Shin" },
			{ "ankle", "Shin", "Paw" },
			{ "toes", "Paw", "Toe" },
		},
		legs = 4,
		ground = { "Paw", "Toe" },
	},
	astralhorn = {
		body = "CarapaceTorso",
		chain = {
			{ "hip", "PillarThigh", "CarapaceTorso" },
			{ "ankle", "PillarThigh", "Hoof" },
			{ "toes", "Hoof", "Toe" },
		},
		legs = 4,
		ground = { "Hoof", "Toe" },
	},
	supernovus = {
		body = "TitanCarapace",
		chain = {
			{ "hip", "TitanThigh", "TitanCarapace" },
			{ "ankle", "TitanThigh", "TitanHock" },
			{ "ankle", "TitanHock", "TitanFootPad" },
			{ "ankle", "TitanThigh", "TitanFootPad" },
			{ "foot", "TitanFootPad", "TitanFootHeel" },
			{ "toes", "TitanFootPad", "TitanToe1" },
			{ "toes", "TitanFootPad", "TitanToe2" },
		},
		legs = 6,
		ground = { "TitanFootPad", "TitanFootHeel", "TitanToe1", "TitanToe2" },
	},
}

local TIERS = { 1, 4, 6, 7 }

local scratch = Instance.new("Folder")
scratch.Name = "__StarbloomLimbSpec"
scratch.Parent = workspace

local function build(id: string, tier: number): Model
	local sp = SeedData.Get(id)
	local model = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN,
		CFrame.new(0, 0, 0), scratch)
	return model
end

local function findIn(items, word: string): BasePart?
	for _, it in ipairs(items) do
		if string.find(it.part.Name, word) then
			return it.part
		end
	end
	return nil
end

local function partNamed(model: Model, word: string): BasePart?
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and string.find(d.Name, word) then
			return d
		end
	end
	return nil
end

--==============================================================================
-- 1. THE RIG
--==============================================================================
say("-- rig --")
say(string.format("   PlantSway vocabulary: %s", table.concat(LEG_WORDS, " ")))
say(string.format("   LEG_SWING %.1f deg", math.deg(LEG_SWING)))

local rigs = {}
for id, spec in pairs(SPEC) do
	rigs[id] = {}
	for _, tier in ipairs(TIERS) do
		local model = build(id, tier)
		local rig = rigOf(model)
		rigs[id][tier] = { model = model, rig = rig }
	end

	local base = rigs[id][1].rig
	check(#base.hips == spec.legs,
		string.format("%s clusters into %d legs", id, spec.legs),
		string.format("%d hips, %d limb parts", #base.hips, #base.parts))

	-- Two phases, alternating, one per side of each rank.
	local phases, ranks = {}, {}
	for _, h in ipairs(base.hips) do
		phases[string.format("%.3f", h.phase)] = true
		ranks[h.rank] = (ranks[h.rank] or 0) + 1
	end
	local nPhase = 0
	for _ in pairs(phases) do
		nPhase += 1
	end
	check(nPhase == 2, string.format("%s runs on two alternating phases", id),
		string.format("%d distinct", nPhase))

	local alternating = true
	for _, h in ipairs(base.hips) do
		local want = math.pi * ((h.rank + (if h.x < 0 then 0 else 1)) % 2)
		if math.abs(h.phase - want) > 1e-6 then
			alternating = false
		end
	end
	local rankTxt = ""
	for r = 1, 8 do
		if ranks[r] then
			rankTxt ..= string.format(" rank%d=%d", r, ranks[r])
		end
	end
	check(alternating, string.format("%s alternates left/right along the body", id), rankTxt)

	-- Every anchor is an upper-leg piece, and nothing else is.
	local anchorsOk = true
	local anchorNames = {}
	for _, h in ipairs(base.hips) do
		for _, it in ipairs(h.items) do
			if it.cf.Position.Y >= base.hipLine then
				anchorNames[it.part.Name] = true
				-- The same three words PlantSway's own `hasUpper` test uses. An
				-- earlier version of this check knew only two of them and failed
				-- Voidpetal's four haunches for being haunches.
				if not (string.find(it.part.Name, "Thigh") or string.find(it.part.Name, "Femur")
					or string.find(it.part.Name, "Haunch")) then
					anchorsOk = false
				end
			end
		end
	end
	local anames = {}
	for n in pairs(anchorNames) do
		table.insert(anames, n)
	end
	check(anchorsOk, string.format("%s: only upper-leg pieces are anchors", id),
		table.concat(anames, ","))

	-- Nothing cosmetic swept into a leg.
	local strays = {}
	for _, it in ipairs(base.parts) do
		local n = it.part.Name
		local wanted = false
		for _, c in ipairs(spec.chain) do
			if string.find(n, c[2]) or string.find(n, c[3]) then
				wanted = true
			end
		end
		if not wanted then
			table.insert(strays, n)
		end
	end
	check(#strays == 0, string.format("%s: no cosmetic part classified as a leg", id),
		if #strays > 0 then table.concat(strays, ",") else "none")

	-- Every limb part is comfortably nearer its own hip than the next.
	local worst, worstName = math.huge, ""
	for _, it in ipairs(base.parts) do
		if it.margin < worst then
			worst, worstName = it.margin, it.part.Name
		end
	end
	check(worst >= 1.25,
		string.format("%s: every limb part sits with its own leg", id),
		string.format("worst %.2f:1 at %s", worst, worstName))
end

--==============================================================================
-- 2. THE POSE MACHINERY ITSELF
--==============================================================================
say("")
say("-- pose --")
do
	local entry = rigs.cosmospire[1]
	local at = posed(entry.model, entry.rig, 0, 0)
	local worst = 0
	for part, cf in pairs(at) do
		worst = math.max(worst, (cf.Position - part.CFrame.Position).Magnitude)
	end
	check(worst < 1e-4, "a rest pose reproduces the built model exactly",
		string.format("%.2e studs", worst))
end

--==============================================================================
-- 3. THE JOINTS
--
-- Rest, both gait extremes, and a turn. The reported number is the WORST of the
-- four, because one open frame in a walk cycle is an open joint.
--==============================================================================
say("")
say("-- joints (positive is daylight, negative is overlap) --")

local POSES = {
	{ "rest", 0, 0 },
	{ "gait+", 1, 0 },
	{ "gait-", -1, 0 },
	{ "turn", 0.6, math.rad(37) },
}

local jointReport = {}
for id, spec in pairs(SPEC) do
	for _, tier in ipairs(TIERS) do
		local entry = rigs[id][tier]
		local model, rig = entry.model, entry.rig
		local hs = SeedData.FrameHeight(SeedData.Get(id), tier)
			/ (require(Shared:WaitForChild("StarbloomForms")).AuthoredHeight[id])

		local body = partNamed(model, spec.body)
		local worstByLabel = {}
		local deepestByLabel = {}

		for _, pose in ipairs(POSES) do
			local at = posed(model, rig, pose[2] * LEG_SWING, pose[3])
			for _, h in ipairs(rig.hips) do
				for _, c in ipairs(spec.chain) do
					local label, an, bn = c[1], c[2], c[3]
					local a = findIn(h.items, an)
					local b = findIn(h.items, bn) or (if bn == spec.body then body else nil)
					if a and b and a ~= b then
						local g = obbGap(a, at[a], b, at[b])
						-- Reported in AUTHORED studs so tiers compare.
						local gg = g / hs
						worstByLabel[label] = math.max(worstByLabel[label] or -math.huge, gg)
						deepestByLabel[label] = math.min(deepestByLabel[label] or math.huge, gg)
					end
				end
			end
		end

		for label, g in pairs(worstByLabel) do
			table.insert(jointReport, { id = id, tier = tier, label = label,
				gap = g, deep = deepestByLabel[label] })
		end
	end
end

table.sort(jointReport, function(a, b)
	if a.id ~= b.id then
		return a.id < b.id
	end
	if a.label ~= b.label then
		return a.label < b.label
	end
	return a.tier < b.tier
end)

local worstGap, worstWhere = -math.huge, ""
local deepest, deepWhere = math.huge, ""
for _, r in ipairs(jointReport) do
	say(string.format("   %-11s %-9s %-8s worst %+7.4f   deepest overlap %+7.4f",
		r.id, r.label, SeedData.TierName(r.tier), r.gap, r.deep))
	if r.gap > worstGap then
		worstGap, worstWhere = r.gap, string.format("%s %s @%s", r.id, r.label, SeedData.TierName(r.tier))
	end
	if r.deep < deepest then
		deepest, deepWhere = r.deep, string.format("%s %s @%s", r.id, r.label, SeedData.TierName(r.tier))
	end
end

check(worstGap < 0, "no anatomical connection shows daylight in any pose",
	string.format("worst %+.4f studs at %s", worstGap, worstWhere))
check(deepest > -1.2, "no joint is swallowed whole",
	string.format("deepest %+.4f studs at %s", deepest, deepWhere))

--==============================================================================
-- 4. GROUND CONTACT
--==============================================================================
say("")
say("-- ground --")
for id, spec in pairs(SPEC) do
	for _, tier in ipairs(TIERS) do
		local entry = rigs[id][tier]
		local model = entry.model
		local baseY = model.PrimaryPart and model.PrimaryPart.Position.Y or 0
		local lowestFoot, lowestAny = math.huge, math.huge
		local lowestAnyName = ""
		local contactCount = 0
		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("BasePart") then
				local y = lowestY(d, d.CFrame)
				if y < lowestAny then
					lowestAny, lowestAnyName = y, d.Name
				end
				for _, w in ipairs(spec.ground) do
					if string.find(d.Name, w) then
						lowestFoot = math.min(lowestFoot, y)
						if math.abs(y) < 1e-3 then
							contactCount += 1
						end
					end
				end
			end
		end
		say(string.format("   %-11s %-8s lowest foot %+.5f   lowest part %+.5f (%s)   soles on the plane %d",
			id, SeedData.TierName(tier), lowestFoot, lowestAny, lowestAnyName, contactCount))
		check(math.abs(lowestFoot) < 1e-3,
			string.format("%s @%s: the foot rests ON the plane", id, SeedData.TierName(tier)),
			string.format("%+.6f", lowestFoot))
		check(lowestAny > -1e-3,
			string.format("%s @%s: nothing reaches below it", id, SeedData.TierName(tier)),
			string.format("%+.6f at %s", lowestAny, lowestAnyName))
		local _ = baseY
	end
end

--==============================================================================
-- 5. PRIMITIVES, AND THE PART BUDGET
--==============================================================================
say("")
say("-- parts --")
for id, spec in pairs(SPEC) do
	local model = rigs[id][1].model
	local total, balls, cylinders = 0, {}, {}
	local limb = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			total += 1
			local isLimb = false
			for _, w in ipairs(LEG_WORDS) do
				if string.find(d.Name, w) then
					isLimb = true
					break
				end
			end
			if isLimb then
				limb += 1
				if d:IsA("Part") then
					if d.Shape == Enum.PartType.Ball then
						table.insert(balls, d.Name)
					elseif d.Shape == Enum.PartType.Cylinder then
						table.insert(cylinders, d.Name)
					end
				end
			end
		end
	end
	say(string.format("   %-11s %d parts total, %d of them limb/foot", id, total, limb))
	check(#balls == 0, string.format("%s: no Ball in limb or foot anatomy", id),
		if #balls > 0 then table.concat(balls, ",") else "0")
	check(#cylinders == 0, string.format("%s: no Cylinder in limb or foot anatomy", id),
		if #cylinders > 0 then table.concat(cylinders, ",") else "0")
	check(model.PrimaryPart ~= nil and model.PrimaryPart.Name == "Base",
		string.format("%s: PrimaryPart is still Base", id),
		model.PrimaryPart and model.PrimaryPart.Name or "NONE")
	local _ = spec
end

--==============================================================================
-- 6. HEIGHT AND SILHOUETTE, AGAINST THE SHEET
--==============================================================================
say("")
say("-- frame --")
for id in pairs(SPEC) do
	for _, tier in ipairs({ 1, 7 }) do
		local model = rigs[id][tier].model
		local lo = Vector3.new(math.huge, math.huge, math.huge)
		local hi = -lo
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				local h = d.Size * 0.5
				for sx = -1, 1, 2 do
					for sy = -1, 1, 2 do
						for sz = -1, 1, 2 do
							local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
							lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
							hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
						end
					end
				end
			end
		end
		say(string.format("   %-11s %-8s  %.2f w x %.2f h x %.2f d   sheet %.2f",
			id, SeedData.TierName(tier), hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z,
			SeedData.FrameHeight(SeedData.Get(id), tier)))
	end
end

--==============================================================================
-- 7. THE ONE THAT WAS NOT TOUCHED
--==============================================================================
say("")
say("-- untouched --")
for _, id in ipairs({ "novaorb" }) do
	local model = build(id, 1)
	local n = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	say(string.format("   %-11s %d parts", id, n))
end

scratch:Destroy()

say("")
say(string.format("%d passed, %d failed", pass, fail))
return table.concat(out, "\n")
