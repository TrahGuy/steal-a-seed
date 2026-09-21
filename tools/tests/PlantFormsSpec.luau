--!nocheck
--==============================================================================
-- Steal a Seed :: PlantFormsSpec
--
-- The eight Greenhollow and Dustbowl plants rebuilt as authored builders on
-- 2026-09-18 -- Nubkin, Petalpip, Spiretip, Toadcap, Dunebud, Paddlehop,
-- Thornwhorl, Raincup -- MEASURED through the production CreatureModel.Build.
-- Every number here is one a reviewer can check; whether the art is right is
-- a judgement only an eye can make, and it is not made here.
--
--   python -m http.server 8731            (from the repo root)
--
--   local run = loadstring(game:GetService("HttpService"):GetAsync(
--       "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--   print(run("PlantFormsSpec"))
--
--==============================================================================
-- WHAT IS PINNED
--
--   1. AuthoredHeight IS the mockup's height. CreatureModel divides the frame
--      by it, so a literal that drifts from the geometry silently resizes a
--      species. Each builder is run at hs = gs = 1 and measured.
--   2. The CreatureModel contract at every tier: Base is the PrimaryPart and
--      sits at the ground, the drawn plant stands ON that ground and at its
--      SeedData frame, nothing collides, nothing lights, nothing is a script.
--   3. Determinism: the same species at the same tier builds the same parts.
--   4. The names PlantSway rigs by -- Leaf arms, Thigh / Foot / Toe legs that
--      cluster into two hips, Root<Word><n> roots with a socket that sweeps
--      fore and aft, Left/Right Eye + Pupil + Lid -- with the sides on the
--      sides they claim.
--   5. Nothing floats: every drawn part touches another (exact oriented-box
--      gap, the StarbloomLimbSpec test), at Tiny and at Colossal.
--   6. Studs on the body, smooth on the face and the wet things.
--   7. Bellchime and Suncrown, the two species this pass did not touch, still
--      build to their part counts, and every other species still builds.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local GreenhollowForms = require(Shared:WaitForChild("GreenhollowForms"))
local DustbowlForms = require(Shared:WaitForChild("DustbowlForms"))

local out = {}
local pass, fail = 0, 0

local function say(...)
	table.insert(out, table.concat({ ... }, " "))
end

local function check(ok: boolean, label: string, detail: any?)
	if ok then
		pass += 1
		say(string.format("  PASS %s%s", label,
			if detail ~= nil then "  [" .. tostring(detail) .. "]" else ""))
	else
		fail += 1
		say(string.format("  FAIL %s%s", label,
			if detail ~= nil then "  [" .. tostring(detail) .. "]" else ""))
	end
end

--==============================================================================
-- THE EIGHT, AND WHAT EACH ONE CLAIMS
--==============================================================================
local SPECIES = {
	{ id = "nubkin", forms = GreenhollowForms, rig = "legs", arms = 2, budget = 48 },
	{ id = "petalpip", forms = GreenhollowForms, rig = "legs", arms = 2, budget = 48 },
	{ id = "spiretip", forms = GreenhollowForms, rig = "legs", arms = 2, budget = 48 },
	{ id = "toadcap", forms = GreenhollowForms, rig = "roots", arms = 0, budget = 56 },
	{ id = "dunebud", forms = DustbowlForms, rig = "legs", arms = 2, budget = 48 },
	{ id = "paddlehop", forms = DustbowlForms, rig = "legs", arms = 2, budget = 48 },
	{ id = "thornwhorl", forms = DustbowlForms, rig = "roots", arms = 0, budget = 56 },
	{ id = "raincup", forms = DustbowlForms, rig = "legs", arms = 2, budget = 48 },
}

-- Smooth by contract: the face, the wet things. Everything else is studded.
local SMOOTH = { Smile = true, Bead = true, BeadGlint = true }
local function isSmoothName(n: string): boolean
	return SMOOTH[n] == true or n:sub(-5) == "Pupil" or n:sub(-3) == "Lid"
end

--==============================================================================
-- WHAT PlantSway ACTUALLY SAYS, read off its Source
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
check(#LEG_WORDS >= 10, "PlantSway still publishes its leg vocabulary", #LEG_WORDS)
local function isLegWord(n: string): boolean
	for _, w in ipairs(LEG_WORDS) do
		if string.find(n, w) then
			return true
		end
	end
	return false
end
local function isUpperWord(n: string): boolean
	return string.find(n, "Thigh") ~= nil or string.find(n, "Femur") ~= nil
		or string.find(n, "Haunch") ~= nil
end

--==============================================================================
-- GEOMETRY HELPERS
--==============================================================================
local function axesOf(cf: CFrame): { Vector3 }
	return { cf.RightVector, cf.UpVector, -cf.LookVector }
end

-- Exact closest distance between two oriented boxes (negative = overlap).
local function obbGap(pa: BasePart, pb: BasePart): number
	local ca, cb = pa.CFrame, pb.CFrame
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

local function lowestY(part: BasePart): number
	local h = part.Size * 0.5
	local a = axesOf(part.CFrame)
	return part.CFrame.Position.Y - (math.abs(a[1].Y) * h.X + math.abs(a[2].Y) * h.Y
		+ math.abs(a[3].Y) * h.Z)
end

local function drawn(model: Model): { BasePart }
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(list, d)
		end
	end
	return list
end

local function extents(list: { BasePart }): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(list) do
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
	return lo, hi
end

local scratch = Instance.new("Folder")
scratch.Name = "PlantFormsSpecScratch"
scratch.Archivable = false
scratch.Parent = workspace

local function build(id: string, tier: number, at: CFrame?): Model
	local sp = SeedData.Get(id)
	assert(sp, "no species " .. id)
	return CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, at or CFrame.new(), scratch)
end

local function signature(model: Model): string
	local rows = {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then
			local p = d.CFrame
			table.insert(rows, string.format("%s|%s|%.4f,%.4f,%.4f|%.4f,%.4f,%.4f|%s",
				d.Name, d.ClassName, d.Size.X, d.Size.Y, d.Size.Z,
				p.X, p.Y, p.Z, tostring(d.Color)))
		end
	end
	table.sort(rows)
	return table.concat(rows, "\n")
end

local counts = {}

for _, spec in ipairs(SPECIES) do
	local id = spec.id
	local sp = SeedData.Get(id)
	say("")
	say("-- " .. id .. " --")

	--======================================================================
	-- 1. THE AUTHORED HEIGHT IS THE GEOMETRY'S
	--======================================================================
	local mockup = Instance.new("Model")
	mockup.Parent = scratch
	local face = spec.forms.Build(mockup, id, CFrame.new(), 1, 1, sp)
	local mlo, mhi = extents(drawn(mockup))
	local authored = spec.forms.AuthoredHeight[id]
	check(face ~= nil, id .. ": the builder says where its face goes")
	check(math.abs((mhi.Y - mlo.Y) - authored) <= authored * 0.005,
		id .. ": AuthoredHeight matches the mockup within 0.5%",
		string.format("%.3f vs %.3f", mhi.Y - mlo.Y, authored))
	check(math.abs(mlo.Y) <= 0.02, id .. ": the mockup stands on Y = 0", string.format("%.3f", mlo.Y))
	mockup:Destroy()

	--======================================================================
	-- 2. THE CONTRACT AT EVERY TIER
	--======================================================================
	local tierParts = nil
	for tier = 1, SeedData.TierCount do
		local at = CFrame.new(tier * 60, 10, 0)
		local model = build(id, tier, at)
		local base = model.PrimaryPart
		local list = drawn(model)
		local lo, hi = extents(list)
		local frame = SeedData.FrameHeight(sp, tier)
		local n = #model:GetChildren()
		if tier == 1 then
			tierParts = n
			counts[id] = n
		end
		local okBase = base ~= nil and base.Name == "Base" and base.Transparency == 1
			and (base.Position - at.Position).Magnitude < 0.1
		local okGround = math.abs(lo.Y - at.Position.Y) <= 0.03
		local okHeight = math.abs((hi.Y - lo.Y) - frame) <= frame * 0.015
		local okFlags, okKids, okExtras = true, true, true
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				if not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch then
					okFlags = false
				end
				if d.Parent ~= model then
					okKids = false
				end
			elseif d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("LuaSourceContainer")
				or d:IsA("Model") then
				okExtras = false
			end
		end
		if tier == 1 or tier == 4 or tier == 7 then
			check(okBase, id .. " T" .. tier .. ": Base is the invisible PrimaryPart at the ground")
			check(okGround, id .. " T" .. tier .. ": the drawn plant stands on the ground",
				string.format("lowest %+.3f", lo.Y - at.Position.Y))
			check(okHeight, id .. " T" .. tier .. ": stands at its SeedData frame",
				string.format("%.2f of %.2f", hi.Y - lo.Y, frame))
			check(okFlags, id .. " T" .. tier .. ": anchored, no collide / query / touch")
			check(okKids and okExtras, id .. " T" .. tier .. ": flat model, no lights, emitters, scripts or sub-models")
		elseif not (okBase and okGround and okHeight and okFlags and okKids and okExtras) then
			check(false, id .. " T" .. tier .. ": contract", string.format("base %s ground %s height %s flags %s flat %s",
				tostring(okBase), tostring(okGround), tostring(okHeight), tostring(okFlags), tostring(okKids and okExtras)))
		end
		check(n == tierParts, id .. " T" .. tier .. ": same part count at every tier", n)
		model:Destroy()
	end
	check(tierParts <= spec.budget, id .. ": within its part budget", tierParts .. " of " .. spec.budget)

	--======================================================================
	-- 3. DETERMINISM
	--======================================================================
	local a = build(id, 3, CFrame.new(500, 0, 0))
	local b = build(id, 3, CFrame.new(500, 0, 0))
	check(signature(a) == signature(b), id .. ": builds the same parts twice")
	b:Destroy()

	--======================================================================
	-- 4. THE RIG NAMES, ON THE SIDES THEY CLAIM
	--======================================================================
	local model = a
	local pivot = model:GetPivot()
	local inverse = pivot:Inverse()
	local names = {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then
			names[d.Name] = (names[d.Name] or 0) + 1
		end
	end
	check((names.Leaf or 0) == spec.arms, id .. ": Leaf arms for PlantSway", names.Leaf or 0)
	for _, lf in ipairs(model:GetChildren()) do
		if lf.Name == "Leaf" then
			-- one arm per side, buried at the shoulder: its centre off the axis
			local x = (inverse * lf.CFrame).Position.X
			check(math.abs(x) > 0.2, id .. ": a Leaf stands off the axis", string.format("%.2f", x))
		end
	end
	check(names.LeftEye == 1 and names.RightEye == 1, id .. ": one eye per side")
	check((names.LeftPupil or 0) >= 1 and (names.RightPupil or 0) >= 1, id .. ": a pupil per side for the gaze rig")
	check(names.LeftLid == 1 and names.RightLid == 1, id .. ": a lid per side for the blink")
	local le, re = model:FindFirstChild("LeftEye"), model:FindFirstChild("RightEye")
	if le and re then
		local l = (inverse * le.CFrame).Position
		local r = (inverse * re.CFrame).Position
		check(l.Z < -0.1 and r.Z < -0.1, id .. ": the eyes are on the front (-Z)", string.format("%.2f %.2f", l.Z, r.Z))
		check(l.X < 0 and r.X > 0 and math.abs(l.X + r.X) < 0.05, id .. ": the eyes are mirrored", string.format("%.2f %.2f", l.X, r.X))
	end

	if spec.rig == "legs" then
		local legParts = {}
		local yLo, yHi = math.huge, -math.huge
		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("BasePart") and isLegWord(d.Name) then
				local cf = inverse * d.CFrame
				table.insert(legParts, { part = d, cf = cf })
				yLo = math.min(yLo, cf.Position.Y)
				yHi = math.max(yHi, cf.Position.Y)
			end
		end
		check(names.LeftThigh == 1 and names.RightThigh == 1, id .. ": a thigh per side")
		check(names.LeftFoot == 1 and names.RightFoot == 1, id .. ": a foot per side")
		check((names.LeftToe or 0) >= 2 and (names.RightToe or 0) >= 2, id .. ": toes on both feet")
		local hipLine = yLo + (yHi - yLo) * 0.55
		local thighsAbove, othersAbove, sidesRight = 0, 0, true
		for _, it in ipairs(legParts) do
			local n = it.part.Name
			local x = it.cf.Position.X
			if (n:sub(1, 4) == "Left" and x >= 0) or (n:sub(1, 5) == "Right" and x <= 0) then
				sidesRight = false
			end
			if it.cf.Position.Y >= hipLine then
				if isUpperWord(n) then
					thighsAbove += 1
				else
					othersAbove += 1
				end
			end
		end
		check(thighsAbove == 2 and othersAbove == 0,
			id .. ": the thighs alone sit above the hip line, so PlantSway finds two hips",
			string.format("%d thighs, %d others", thighsAbove, othersAbove))
		check(sidesRight, id .. ": every Left leg part is at -X and every Right at +X")
		local lt, rt = model:FindFirstChild("LeftThigh"), model:FindFirstChild("RightThigh")
		if lt and rt then
			local lo2, hi2 = extents(drawn(model))
			local spread = math.max(hi2.X - lo2.X, hi2.Z - lo2.Z)
			local hipNear = math.max(spread * 0.12, 0.25)
			local dx = (inverse * lt.CFrame).Position.X - (inverse * rt.CFrame).Position.X
			check(math.abs(dx) > hipNear, id .. ": the two hips are far enough apart to be two",
				string.format("%.2f vs %.2f", math.abs(dx), hipNear))
		end
		local anyRoot = false
		for n in pairs(names) do
			if string.match(n, "^Root%a*%d$") then
				anyRoot = true
			end
		end
		check(not anyRoot, id .. ": carries no root-walker names")
	else
		local hasUpper = false
		for n in pairs(names) do
			if isUpperWord(n) then
				hasUpper = true
			end
		end
		check(not hasUpper, id .. ": carries no Thigh, so the hip rig stays off")
		for slot = 1, 4 do
			local rise = model:FindFirstChild("RootRise" .. slot)
			local anchor = model:FindFirstChild("RootAnchor" .. slot)
			check(rise ~= nil and anchor ~= nil, id .. ": root " .. slot .. " has a rise and an anchor")
			if rise and anchor then
				local cf = inverse * rise.CFrame
				local half = rise.Size.Z * 0.5
				local ahead = (cf * CFrame.new(0, 0, half)).Position
				local behind = (cf * CFrame.new(0, 0, -half)).Position
				local inner = if Vector3.new(ahead.X, 0, ahead.Z).Magnitude
					<= Vector3.new(behind.X, 0, behind.Z).Magnitude then ahead else behind
				local flat = Vector3.new(inner.X, 0, inner.Z)
				check(flat.Magnitude > 0.05, id .. ": root " .. slot .. " socket stands off the axis",
					string.format("%.2f", flat.Magnitude))
				if flat.Magnitude > 1e-3 then
					local socket = CFrame.lookAt(inner, inner + flat.Unit, Vector3.yAxis)
					check(math.abs(socket.RightVector.Z) >= 0.3,
						id .. ": root " .. slot .. " sweeps fore and aft, not sideways",
						string.format("%.2f", math.abs(socket.RightVector.Z)))
				end
				-- Against the GROUND the model was built on (Y = 0 here), not the
				-- pivot: the Base plate stands 0.03 above the soil.
				check(math.abs(lowestY(anchor)) <= 0.03,
					id .. ": root " .. slot .. " anchor rests on the soil",
					string.format("%+.3f", lowestY(anchor)))
			end
		end
	end

	--======================================================================
	-- 5. NOTHING FLOATS, at Tiny and at Colossal
	--======================================================================
	for _, tier in ipairs({ 1, 7 }) do
		local m = build(id, tier, CFrame.new(900, 0, tier * 100))
		local list = drawn(m)
		local loose = {}
		for i, p in ipairs(list) do
			local near = math.huge
			for j, q in ipairs(list) do
				if i ~= j then
					near = math.min(near, obbGap(p, q))
					if near <= 0.05 then
						break
					end
				end
			end
			if near > 0.05 then
				table.insert(loose, string.format("%s %.2f", p.Name, near))
			end
		end
		check(#loose == 0, id .. " T" .. tier .. ": every drawn part touches another",
			if #loose > 0 then table.concat(loose, ", ") else nil)
		m:Destroy()
	end

	--======================================================================
	-- 6. STUDS ON THE BODY, SMOOTH ON THE FACE
	--======================================================================
	local wrongStud, wrongSmooth = {}, {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local top = d.TopSurface
			if isSmoothName(d.Name) then
				if top ~= Enum.SurfaceType.Smooth then
					table.insert(wrongSmooth, d.Name)
				end
			elseif d:IsA("Part") then
				if top ~= Enum.SurfaceType.Studs or d.Material ~= Enum.Material.Plastic then
					table.insert(wrongStud, d.Name)
				end
			end
		end
	end
	check(#wrongStud == 0, id .. ": body parts are studded Plastic", if #wrongStud > 0 then table.concat(wrongStud, ", ") else nil)
	check(#wrongSmooth == 0, id .. ": the face and the wet things are smooth", if #wrongSmooth > 0 then table.concat(wrongSmooth, ", ") else nil)

	model:Destroy()
end

--==============================================================================
-- 7. THE ONES THIS PASS DID NOT TOUCH
--==============================================================================
say("")
say("-- untouched --")
for _, expect in ipairs({ { "bellchime", 47 }, { "suncrown", 64 } }) do
	local m = build(expect[1], 1)
	local n = #m:GetChildren()
	check(n == expect[2], expect[1] .. " still builds to its part count", n)
	m:Destroy()
end
local built, failed = 0, {}
for _, sp in ipairs(SeedData.Species) do
	local ok, err = pcall(function()
		local m = CreatureModel.Build(sp, 1, CreatureModel.STAGE_GROWN, CFrame.new(), scratch)
		assert(m.PrimaryPart, "no PrimaryPart")
		m:Destroy()
	end)
	if ok then
		built += 1
	else
		table.insert(failed, sp.Id .. ": " .. tostring(err))
	end
end
check(#failed == 0, "every species still builds", if #failed > 0 then table.concat(failed, "; ") else built)

say("")
say("-- part counts, Base included --")
for _, spec in ipairs(SPECIES) do
	say(string.format("   %-11s %d", spec.id, counts[spec.id] or -1))
end

scratch:Destroy()

say("")
say(string.format("PlantFormsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
