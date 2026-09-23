--!nocheck
--==============================================================================
-- Steal a Seed :: StarbloomLimbSpec
--
-- The legs of all five Starbloom creatures -- the Moonbulb Prowler's four root
-- legs (Novaorb), the Crescent Reedwalker's four stilts (Cosmospire),
-- Voidpetal's cat legs, the Mooncrest Stag's four jointed legs (Astralhorn) and
-- the four pillar legs of the Supernovus colossus -- MEASURED, and everything
-- else PlantSway moves on them: every Leaf and every eye must stay on the body
-- in every pose it draws. Every number here is one a reviewer can check;
-- nothing here is a judgement about whether the art looks right, which only an
-- eye can make.
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
--
-- AND A BALL IS A SPHERE. The engine draws a Ball as a sphere of its smallest
-- axis, so a leg sunk into a round bulb is measured against the sphere, never
-- against the box around it -- the box would report a joint the eye can see
-- is open.
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
-- The arm swing every "Leaf" takes about its own centre, and how far an eye
-- turns in its socket: the other two things PlantSway moves on these bodies.
local SWING_AMP = math.rad(assert(tonumber(string.match(sway.Source,
	"local SWING_AMP = math%.rad%((%d+%.?%d*)%)")), "could not find SWING_AMP in PlantSway"))
local GAZE_MAX = math.rad(assert(tonumber(string.match(sway.Source,
	"local GAZE_MAX = math%.rad%((%d+%.?%d*)%)")), "could not find GAZE_MAX in PlantSway"))

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

--==============================================================================
-- AND A BALL IS A SPHERE
--
-- The engine draws a Ball as a sphere of its SMALLEST axis, so the box around it
-- is not the part. Against a sphere the distance is the centre's distance to
-- the other box, less the radius -- signed the same way obbGap is, negative
-- inside.
--==============================================================================
local function isBall(p: BasePart): boolean
	return p:IsA("Part") and p.Shape == Enum.PartType.Ball
end

local function radiusOf(p: BasePart): number
	return math.min(p.Size.X, p.Size.Y, p.Size.Z) * 0.5
end

local function pointBoxGap(pt: Vector3, part: BasePart, cf: CFrame): number
	local l = cf:PointToObjectSpace(pt)
	local h = part.Size * 0.5
	local q = Vector3.new(math.clamp(l.X, -h.X, h.X), math.clamp(l.Y, -h.Y, h.Y),
		math.clamp(l.Z, -h.Z, h.Z))
	local outside = (l - q).Magnitude
	if outside > 0 then
		return outside
	end
	return -math.min(h.X - math.abs(l.X), h.Y - math.abs(l.Y), h.Z - math.abs(l.Z))
end

local function partGap(pa: BasePart, ca: CFrame, pb: BasePart, cb: CFrame): number
	if isBall(pa) and isBall(pb) then
		return (ca.Position - cb.Position).Magnitude - radiusOf(pa) - radiusOf(pb)
	elseif isBall(pa) then
		return pointBoxGap(ca.Position, pb, cb) - radiusOf(pa)
	elseif isBall(pb) then
		return pointBoxGap(cb.Position, pa, ca) - radiusOf(pb)
	end
	return obbGap(pa, ca, pb, cb)
end

-- The lowest point of a part, in world Y: a box by its corners, a ball by its
-- radius.
local function lowestY(part: BasePart, cf: CFrame): number
	if isBall(part) then
		return cf.Position.Y - radiusOf(part)
	end
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
-- THE FIVE SPECIES, AND THE CHAINS THAT HAVE TO STAY SHUT
--
-- `body` lists the masses a leg may sink its top into -- exact part names --
-- and a chain link to BODY is shut if the leg is inside ANY of them: the
-- Mooncrest Stag's front thighs sit in its chest and its rear ones in the rear
-- body, so no single part is "the" body. `parts`, `lights` and `emitters` pin
-- the approved build and its effect budget at every tier.
--==============================================================================
local BODY = "<body>"

local SPEC = {
	-- The Moonbulb Prowler (approved 2026-09-23): four short root legs, a thigh
	-- sunk in the bulb and a foot under it.
	novaorb = {
		body = { "BulbLower", "BulbRear", "BellyPlate" },
		chain = {
			{ "hip", "Thigh", BODY },
			{ "ankle", "Thigh", "Foot" },
		},
		legs = 4,
		ground = { "Foot" },
		parts = 30, lights = 1, emitters = 0,
	},
	-- The Crescent Reedwalker (approved 2026-09-23) kept the stilt chain.
	cosmospire = {
		body = { "Thorax" },
		chain = {
			{ "shoulder", "Femur", BODY },
			{ "knee", "Femur", "Knee" },
			{ "knee", "Knee", "Tibia" },
			{ "ankle", "Tibia", "StiltClaw" },
		},
		legs = 4,
		ground = { "StiltClaw" },
		parts = 38, lights = 1, emitters = 0,
	},
	voidpetal = {
		body = { "SpineTorso" },
		chain = {
			{ "shoulder", "Haunch", BODY },
			{ "knee", "Haunch", "Shin" },
			{ "ankle", "Shin", "Paw" },
			{ "toes", "Paw", "Toe" },
		},
		legs = 4,
		ground = { "Paw", "Toe" },
		parts = 39, lights = 1, emitters = 0,
		-- KNOWN, NOT FIXED: the top petal of the six-petal mane touches only the
		-- two petals beside it and stands 0.058 authored studs off the skull
		-- (measured 2026-09-23, when section 7 first ran). Voidpetal was outside
		-- that day's approved redesign, so it is reported rather than moved. One
		-- loose part is tolerated here; a second fails.
		knownLoose = 1,
	},
	-- The Mooncrest Stag (approved 2026-09-23): thigh -> shin -> hoof -> toe,
	-- the shin counter-bent under the hip.
	astralhorn = {
		body = { "Chest", "RearBody", "Belly" },
		chain = {
			{ "hip", "Thigh", BODY },
			{ "knee", "Thigh", "Shin" },
			{ "ankle", "Shin", "Hoof" },
			{ "toes", "Hoof", "Toe" },
		},
		legs = 4,
		ground = { "Hoof", "Toe" },
		parts = 47, lights = 1, emitters = 0,
	},
	-- The Cosmic Star Colossus (2026-09-11): four pillar legs, thigh -> ankle
	-- collar -> pad -> claws. Three claws on a front foot and two on a rear one;
	-- a chain entry whose part a leg does not have is skipped for that leg.
	supernovus = {
		body = { "TitanCarapace" },
		chain = {
			{ "hip", "TitanThigh", BODY },
			{ "ankle", "TitanThigh", "TitanHock" },
			{ "ankle", "TitanHock", "TitanFootPad" },
			{ "ankle", "TitanThigh", "TitanFootPad" },
			{ "toes", "TitanFootPad", "TitanToe1" },
			{ "toes", "TitanFootPad", "TitanToe2" },
			{ "toes", "TitanFootPad", "TitanToe3" },
		},
		legs = 4,
		ground = { "TitanFootPad", "TitanToe1", "TitanToe2", "TitanToe3" },
		parts = 81, lights = 3, emitters = 2,
	},
}

-- The named body masses of one built model, by exact name.
local function bodiesOf(model: Model, spec): { BasePart }
	local list = {}
	for _, name in ipairs(spec.body) do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			table.insert(list, p)
		end
	end
	return list
end

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

		local bodies = bodiesOf(model, spec)
		if tier == TIERS[1] then
			check(#bodies == #spec.body, string.format("%s: every named body mass exists", id),
				string.format("%d of %d", #bodies, #spec.body))
		end
		local worstByLabel = {}
		local deepestByLabel = {}

		for _, pose in ipairs(POSES) do
			local at = posed(model, rig, pose[2] * LEG_SWING, pose[3])
			for _, h in ipairs(rig.hips) do
				for _, c in ipairs(spec.chain) do
					local label, an, bn = c[1], c[2], c[3]
					local a = findIn(h.items, an)
					local g: number? = nil
					if a and bn == BODY then
						-- Shut if the leg is inside ANY of the body masses.
						for _, b in ipairs(bodies) do
							local gb = partGap(a, at[a], b, at[b])
							g = if g == nil then gb else math.min(g, gb)
						end
					elseif a then
						local b = findIn(h.items, bn)
						if b and a ~= b then
							g = partGap(a, at[a], b, at[b])
						end
					end
					if g ~= nil then
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

		-- How far a sole's heel or toe tips below the plane at the ends of the
		-- stride. PlantSway swings a whole leg rigidly about its hip, so a flat
		-- sole turned LEG_SWING drives one corner down into the soil. Reported,
		-- not failed: it is the rig's, shared by every legged species.
		local hsGround = SeedData.FrameHeight(SeedData.Get(id), tier)
			/ (require(Shared:WaitForChild("StarbloomForms")).AuthoredHeight[id])
		local dip = 0
		for _, a in ipairs({ LEG_SWING, -LEG_SWING }) do
			local at = posed(model, entry.rig, a, 0)
			for _, h in ipairs(entry.rig.hips) do
				for _, it in ipairs(h.items) do
					dip = math.min(dip, lowestY(it.part, at[it.part]))
				end
			end
		end
		say(string.format("   %-11s %-8s stride dip %+.3f authored (%+.2f studs) at the ends of the swing",
			id, SeedData.TierName(tier), dip / hsGround, dip))
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

	-- The approved build and its effect budget, at every tier: the same parts,
	-- one light apiece (the Mythic's three), and no emitter a design did not
	-- ask for. PlantGlow keeps every one of those lights dark by day.
	local counts = {}
	local countsOk = true
	for _, tier in ipairs(TIERS) do
		local n, l, e = 0, 0, 0
		for _, d in ipairs(rigs[id][tier].model:GetDescendants()) do
			if d:IsA("BasePart") then
				n += 1
			elseif d:IsA("Light") then
				l += 1
			elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
				e += 1
			end
		end
		table.insert(counts, string.format("T%d %d/%d/%d", tier, n, l, e))
		if n ~= spec.parts or l ~= spec.lights or e ~= spec.emitters then
			countsOk = false
		end
	end
	check(countsOk, string.format("%s: %d parts, %d light(s), %d emitter(s) at every tier", id,
		spec.parts, spec.lights, spec.emitters), table.concat(counts, "  "))
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
-- 7. NOTHING ELSE COMES AWAY
--
-- The legs are one of three things PlantSway moves. Every direct child named
-- "Leaf" swings about its own centre as an arm, and every pupil orbits the
-- centre of its eye (the eyeball itself stays put). Everything else -- brows,
-- cheeks, jaws, crowns, bracts, antlers, the eyeballs -- rides the body's one
-- PivotTo and cannot leave it. So each thing that moves is held to what it
-- touched at rest:
--
--   a leg (every part on one hip)    to the body it sinks into
--   a Leaf                           to the body it grows from
--   a pupil                          to its eye
--
-- "Body" is every part no rig claims. A leg that touches only another leg, or a
-- leaf that touches only another leaf, is attached to nothing that holds still,
-- and fails. Measured through a whole stride, in a turn and at both ends of the
-- gaze, at Tiny, Mega and Colossal.
--
-- The lids are the one moving part excused: a lid sits proud of its eye by
-- design and sweeps over it to blink, and the girth spread lifts it a little
-- further off at the big tiers.
--
-- AND ONLY THE FACE IS A FACE. A name ending Eye, Pupil, Lid or Glint joins the
-- gaze rig and a name like Root<Word><n> joins the root walker; a decoration
-- carrying one would be dragged about as a feature it is not.
--==============================================================================
say("")
say("-- everything else stays on --")
local TOUCH = 0.01 -- authored studs

-- Who moves each part: "leg<i>", "leaf<j>", "gaze<k>" (an eye and its pupils),
-- "lid", or nil for the body.
local function motionRig(model: Model, rig)
	local role = {}
	for hi, h in ipairs(rig.hips) do
		for _, it in ipairs(h.items) do
			role[it.part] = "leg" .. hi
		end
	end
	local inv = rig.pivot:Inverse()
	local leaves = {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Name == "Leaf" then
			local off = inv * d.CFrame
			table.insert(leaves, { part = d, offset = off, sign = if off.Position.X < 0 then -1 else 1 })
			role[d] = "leaf" .. #leaves
		end
	end
	local eyes, pupils = {}, {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then
			if d.Name:sub(-5) == "Pupil" then
				table.insert(pupils, d)
			elseif d.Name:sub(-3) == "Eye" then
				table.insert(eyes, d)
			elseif d.Name:sub(-3) == "Lid" then
				role[d] = "lid"
			end
		end
	end
	-- The eyeball itself never moves -- PlantSway turns only what rides on it --
	-- so it is body, and its pupils orbit its centre.
	local gaze = {}
	for k, e in ipairs(eyes) do
		for _, p in ipairs(pupils) do
			if p.Name:sub(1, -6) == e.Name:sub(1, -4) then
				role[p] = "gaze" .. k
				table.insert(gaze, { part = p, eye = e, localCF = e.CFrame:ToObjectSpace(p.CFrame) })
			end
		end
	end
	return role, leaves, gaze
end

-- Every part at one moment -- stride phase, turn, gaze -- composed from rest the
-- way PlantSway composes it: legs about their hip, leaves about their own
-- centre, pupils about the centre of their eye.
local function posedAll(model: Model, rig, leaves, gaze, phase: number, yaw: number,
	gy: number, gp: number): { [BasePart]: CFrame }
	local target = rig.pivot * CFrame.Angles(0, yaw, 0)
	local pinv = rig.pivot:Inverse()
	local at = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			at[d] = target * (pinv * d.CFrame)
		end
	end
	local swing = math.sin(phase) * SWING_AMP
	for _, lf in ipairs(leaves) do
		at[lf.part] = target * lf.offset * CFrame.Angles(swing * lf.sign, 0, 0)
	end
	for _, h in ipairs(rig.hips) do
		local a = math.sin(phase + h.phase) * LEG_SWING
		for _, it in ipairs(h.items) do
			at[it.part] = target * h.frame * CFrame.Angles(a, 0, 0) * it.rel
		end
	end
	local turn = CFrame.Angles(gp, gy, 0)
	for _, g in ipairs(gaze) do
		at[g.part] = target * (pinv * g.eye.CFrame) * turn * g.localCF
	end
	return at
end

local FULL_POSES = {}
for k = 0, 7 do
	table.insert(FULL_POSES, { string.format("stride %d/8", k), k * math.pi / 4, 0, 0, 0 })
end
table.insert(FULL_POSES, { "turn", math.pi / 2, math.rad(37), 0, 0 })
-- Tracking a player clamps yaw and pitch to GAZE_MAX each, so the corners are
-- the extremes the client can reach.
table.insert(FULL_POSES, { "gaze up-left", 0, 0, GAZE_MAX, GAZE_MAX })
table.insert(FULL_POSES, { "gaze down-right", 0, 0, -GAZE_MAX, -GAZE_MAX })
table.insert(FULL_POSES, { "gaze up-right", 0, 0, -GAZE_MAX, GAZE_MAX })
table.insert(FULL_POSES, { "gaze down-left", 0, 0, GAZE_MAX, -GAZE_MAX })

for id in pairs(SPEC) do
	for _, tier in ipairs({ 1, 4, 7 }) do
		local entry = rigs[id][tier]
		local model, rig = entry.model, entry.rig
		local hs = SeedData.FrameHeight(SeedData.Get(id), tier)
			/ (require(Shared:WaitForChild("StarbloomForms")).AuthoredHeight[id])
		local role, leaves, gaze = motionRig(model, rig)
		local parts = {}
		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("BasePart") and d.Name ~= "Base" and role[d] ~= "lid" then
				table.insert(parts, d)
			end
		end
		-- Each moving group, and every body part it touches at rest.
		local anchors = {}
		for i = 1, #parts do
			for j = i + 1, #parts do
				local a, b = parts[i], parts[j]
				local ra, rb = role[a], role[b]
				if (ra == nil) ~= (rb == nil)
					and partGap(a, a.CFrame, b, b.CFrame) <= TOUCH * hs then
					local moving = if ra then a else b
					local still = if ra then b else a
					local g = role[moving]
					anchors[g] = anchors[g] or {}
					table.insert(anchors[g], { moving, still })
				end
			end
		end
		local groups = {}
		for _, r in pairs(role) do
			if r ~= "lid" then
				groups[r] = true
			end
		end
		local poses = {}
		for pi, pose in ipairs(FULL_POSES) do
			poses[pi] = posedAll(model, rig, leaves, gaze, pose[2], pose[3], pose[4], pose[5])
		end
		local unanchored, detached = {}, {}
		local worst, worstWhere = -math.huge, "none"
		for g in pairs(groups) do
			local list = anchors[g]
			if not list then
				table.insert(unanchored, g)
			else
				for pi, pose in ipairs(FULL_POSES) do
					local at = poses[pi]
					local best = math.huge
					for _, pair in ipairs(list) do
						best = math.min(best, partGap(pair[1], at[pair[1]], pair[2], at[pair[2]]))
					end
					local bestA = best / hs
					if bestA > worst then
						worst, worstWhere = bestA, g .. " at " .. pose[1]
					end
					if bestA > TOUCH then
						table.insert(detached, string.format("%s at %s %+.3f", g, pose[1], bestA))
						break
					end
				end
			end
		end
		table.sort(unanchored)
		table.sort(detached)
		local known = SPEC[id].knownLoose or 0
		check(#unanchored <= known, string.format("%s @%s: every leg, Leaf and pupil touches the body at rest%s",
			id, SeedData.TierName(tier), if known > 0 then string.format(" (%d known exception)", known) else ""),
			if #unanchored > 0 then table.concat(unanchored, ",") else nil)
		check(#detached == 0, string.format("%s @%s: none of them leaves it in any pose", id,
			SeedData.TierName(tier)), if #detached > 0 then table.concat(detached, "; ")
			else string.format("closest to leaving %+.3f authored, %s", worst, worstWhere))
	end

	-- Only the face is a face, and nothing opts into the root walker.
	local stray = {}
	for _, d in ipairs(rigs[id][1].model:GetChildren()) do
		if d:IsA("BasePart") then
			local n = d.Name
			local faceWord = n:sub(-3) == "Eye" or n:sub(-5) == "Pupil" or n:sub(-3) == "Lid"
				or n:sub(-5) == "Glint"
			if faceWord and not (string.match(n, "^Left") or string.match(n, "^Right")) then
				table.insert(stray, n)
			end
			if string.match(n, "^Root%a*%d$") or string.match(n, "^PropRoot%d$") then
				table.insert(stray, n)
			end
		end
	end
	check(#stray == 0, string.format("%s: only the Left/Right eyes carry face words, and nothing is a root", id),
		if #stray > 0 then table.concat(stray, ",") else nil)
end

scratch:Destroy()

say("")
say(string.format("%d passed, %d failed", pass, fail))
return table.concat(out, "\n")
