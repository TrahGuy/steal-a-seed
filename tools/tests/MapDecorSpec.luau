--!nocheck
--==============================================================================
-- Steal a Seed :: MapDecorSpec
--
-- The environment art pass of 2026-09-18: five biomes of sculpted scenery and
-- a cradle round every nest, built by MapDecor from the approved concept
-- sheet. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("MapDecorSpec"))
--
-- WHAT THIS PROTECTS. Scenery in this game is allowed to be beautiful only on
-- terms: it may not catch a runner, block a bat, hide a pod, stand in the
-- racing line, stand in the guardian's way out of its nest, differ between
-- servers, or cost more than a bed of plants. Each of those is a rule someone
-- wrote down because breaking it was cheap and finding it was not. This drives
-- the real MapDecor into a fixture and measures the parts it actually built.
--
-- It does not judge how it looks. The owner does that in Studio.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local MapDecor = require(Server:WaitForChild("MapDecor"))

local MAP = GameConfig.Map

local pass, fails = 0, {}
local out = {}
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		table.insert(fails, label)
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local fixture = Instance.new("Folder")
fixture.Name = "MapDecorSpecFixture"
fixture.Archivable = false
fixture.Parent = workspace

-- The budget the pass was built against: about one plot's bed of twelve grown
-- plants per biome (480 at the worst form), with a little headroom.
local BIOME_BUDGET = 560
local ROAD_BUDGET = 2400
local FIELD_BUDGET = 520
local CENTRE_CLEAR = 24
-- A Colossal shell on the 16-stud ring reaches 22; the cradle starts past it.
local RING_CLEAR = 24.5
-- The tutorial's reserved pod: 24 out along +Z, then 26 degrees a slot.
local RESERVE_RADIUS, RESERVE_SPREAD = 24, math.rad(26)

-- A part's height is its extent along the world's up: a disc lies on its side
-- (its Size.Y is a diameter) and a blade leans.
local function heightOf(p)
	local up = p.CFrame:VectorToObjectSpace(Vector3.yAxis)
	return math.abs(p.Size.X * up.X) + math.abs(p.Size.Y * up.Y) + math.abs(p.Size.Z * up.Z)
end

local function parts(root)
	local list = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function signature(root)
	local rows = {}
	for _, p in ipairs(parts(root)) do
		table.insert(rows, string.format("%s|%.2f|%.2f|%.2f|%.2f|%.2f|%.2f", p.Name,
			p.Position.X, p.Position.Y, p.Position.Z, p.Size.X, p.Size.Y, p.Size.Z))
	end
	table.sort(rows)
	return table.concat(rows, "\n")
end

local function dress(biome)
	local model = Instance.new("Model")
	model.Name = biome.Id
	model.Parent = fixture
	MapDecor.dressSegment(biome, model)
	return model:FindFirstChild("Decor"), model
end

local ok, err = pcall(function()

local roadTotal = 0
for _, biome in ipairs(BiomeData.Biomes) do
	say("-- " .. biome.Id .. " --")
	local decor = dress(biome)
	check(decor ~= nil, biome.Id .. ": dressSegment leaves a Decor folder")
	local list = parts(decor)
	roadTotal += #list
	local nearZ, farZ = BiomeData.SegmentBounds(biome)

	--======================================================================
	-- 1. NOTHING IS COLLIDABLE, TOUCHABLE OR QUERYABLE, AND NOTHING MOVES
	--======================================================================
	local solid, loose, lights = 0, 0, 0
	for _, p in ipairs(list) do
		if p.CanCollide or p.CanTouch or p.CanQuery then
			solid += 1
		end
		if not p.Anchored then
			loose += 1
		end
	end
	for _, d in ipairs(decor:GetDescendants()) do
		if d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Beam") then
			lights += 1
		end
	end
	check(solid == 0, biome.Id .. ": every part is non-collidable, non-touchable, non-queryable", solid)
	check(loose == 0, biome.Id .. ": every part is anchored", loose)
	check(lights == 0, biome.Id .. ": no lights, emitters or beams in the scenery", lights)

	--======================================================================
	-- 2. THE RACING LINE, THE WALLS AND THE SEGMENT
	--======================================================================
	local intruders, outside, strayed = 0, 0, 0
	local halfW = MAP.CorridorWidth * 0.5
	for _, p in ipairs(list) do
		if heightOf(p) > 1 and math.abs(p.Position.X) < CENTRE_CLEAR then
			intruders += 1
		end
		if math.abs(p.Position.X) > halfW then
			outside += 1
		end
		if p.Position.Z > nearZ + 1 or p.Position.Z < farZ - 1 then
			strayed += 1
		end
	end
	check(intruders == 0, biome.Id .. ": no tall part inside the 24-stud racing line", intruders)
	check(outside == 0, biome.Id .. ": no part beyond the wall face", outside)
	check(strayed == 0, biome.Id .. ": no part outside its own segment", strayed)

	--======================================================================
	-- 3. THE NEST: PODS CLEAR, THE FRONT OPEN, THE RESERVED POD'S SPOT FREE
	--
	-- The cradle (everything taller than the bedding within 34 of the site)
	-- stands on the WALL side of the site, local +Z; the guardian's way out is
	-- the lane in front of it -- 14 either side of the site's axis, 40 studs
	-- toward the road -- and nothing may stand in it. The tutorial reserves
	-- pods at the Greenhollow nest only, 24 out along the road axis.
	--======================================================================
	for _, site in ipairs(BiomeData.NestCFrames(biome)) do
		local onRing, inFront, inLane, onReserve, cradleParts = 0, 0, 0, 0, 0
		local centre = site.Position
		local reserves = {}
		for slot = 0, 2 do
			local a = RESERVE_SPREAD * slot
			table.insert(reserves, centre + Vector3.new(math.sin(a) * RESERVE_RADIUS, 0, math.cos(a) * RESERVE_RADIUS))
		end
		for _, p in ipairs(list) do
			if heightOf(p) > 0.3 then
				local flat = Vector3.new(p.Position.X - centre.X, 0, p.Position.Z - centre.Z)
				local dist = flat.Magnitude
				local rel = site:PointToObjectSpace(Vector3.new(p.Position.X, centre.Y, p.Position.Z))
				if dist < 34 then
					cradleParts += 1
					if dist < RING_CLEAR then
						onRing += 1
					end
					if rel.Z <= 0 then
						inFront += 1
					end
				end
				if math.abs(rel.X) <= 14 and rel.Z <= 0 and rel.Z >= -40 then
					inLane += 1
				end
				if biome.Order == 1 then
					for _, r in ipairs(reserves) do
						if (Vector3.new(p.Position.X, 0, p.Position.Z) - Vector3.new(r.X, 0, r.Z)).Magnitude < 4 then
							onReserve += 1
						end
					end
				end
			end
		end
		check(cradleParts >= 12, biome.Id .. ": a cradle stands round the nest", cradleParts)
		check(onRing == 0, biome.Id .. ": nothing but bedding within 24.5 of the site -- the pod ring is clear", onRing)
		check(inFront == 0, biome.Id .. ": every cradle part is on the wall side of the site", inFront)
		check(inLane == 0, biome.Id .. ": the guardian's lane out to the road is empty", inLane)
		if biome.Order == 1 then
			check(onReserve == 0, biome.Id .. ": the tutorial's reserved-pod spots are clear", onReserve)
		end
		local cradle = decor:FindFirstChild("NestCradle")
		check(cradle ~= nil and cradle:IsA("Model"), biome.Id .. ": the cradle is one Model named NestCradle")
	end

	--======================================================================
	-- 4. THE LOOK IS THE GAME'S: PLASTIC, STUDDED, GROUPED
	--======================================================================
	local studded, badMaterial, looseParts = 0, 0, 0
	for _, p in ipairs(list) do
		if p.TopSurface == Enum.SurfaceType.Studs then
			studded += 1
		end
		if p.Material ~= Enum.Material.Plastic and p.Material ~= Enum.Material.Neon
			and p.Material ~= Enum.Material.Glass and p.Material ~= Enum.Material.Sand then
			badMaterial += 1
		end
		if p.Parent == decor and p.Name ~= "Growth" and p.Name ~= "Streak" then
			looseParts += 1
		end
	end
	check(studded >= #list * 0.25, biome.Id .. ": at least a quarter of the parts show studs", studded .. "/" .. #list)
	check(badMaterial == 0, biome.Id .. ": only Plastic, Neon, Glass and Sand", badMaterial)
	check(looseParts == 0, biome.Id .. ": every prop is a Model (only wall growth and floor streaks are loose parts)", looseParts)

	--======================================================================
	-- 5. THE BUDGET, AND THE SAME WORLD TWICE
	--======================================================================
	check(#list <= BIOME_BUDGET, string.format("%s: %d parts is within the %d budget", biome.Id, #list, BIOME_BUDGET))
	local again = dress(biome)
	check(signature(decor) == signature(again), biome.Id .. ": built twice, identical to the hundredth of a stud")
	say(string.format("    %s: %d parts, %d studded", biome.Id, #list, studded))
end
check(roadTotal <= ROAD_BUDGET, string.format("the road's scenery is %d parts, within %d", roadTotal, ROAD_BUDGET))

--==========================================================================
-- 6. THE FIELD
--==========================================================================
say("-- the field --")
local props = Instance.new("Folder")
props.Parent = fixture
MapDecor.dressField(props)
local fieldDecor = props:FindFirstChild("FieldDecor")
local fieldParts = parts(fieldDecor)
local fieldSolid = 0
for _, p in ipairs(fieldParts) do
	if p.CanCollide or p.CanQuery or not p.Anchored then
		fieldSolid += 1
	end
end
check(fieldSolid == 0, "every field prop is anchored and non-collidable", fieldSolid)
check(#fieldParts <= FIELD_BUDGET, string.format("the field's scenery is %d parts, within %d", #fieldParts, FIELD_BUDGET))
local outer = GameConfig.Plot.MaxReach + 4
local inRing = 0
for _, p in ipairs(fieldParts) do
	if p.Name ~= "Hedge" and heightOf(p) > 1 and math.sqrt(p.Position.X ^ 2 + p.Position.Z ^ 2) < outer then
		inRing += 1
	end
end
check(inRing == 0, "nothing tall stands inside the plot ring", inRing)

--==========================================================================
-- 7. BY SOURCE: NO LOOPS, NO LIGHTS, AND THE WALLS SHOW THEIR STUDS
--==========================================================================
local decorSrc = Server.MapDecor.Source
check(not decorSrc:find("RunService", 1, true) and not decorSrc:find("Heartbeat", 1, true)
		and not decorSrc:find("PointLight", 1, true) and not decorSrc:find("ParticleEmitter", 1, true),
	"MapDecor runs no loop and makes no light")
check(decorSrc:find("p.CanQuery = false", 1, true) ~= nil and decorSrc:find("p.CanCollide = false", 1, true) ~= nil,
	"the one part helper is what makes every prop a ghost")
local mapSrc = Server.MapService.Source
check(mapSrc:find("wall.LeftSurface = Enum.SurfaceType.Studs", 1, true) ~= nil,
	"MapService studs the wall faces the player sees")

end)

fixture:Destroy()
if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return table.concat(out, "\n") .. ("\nMapDecorSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return table.concat(out, "\n") .. ("\nMapDecorSpec: %d passed, 0 failed"):format(pass)
