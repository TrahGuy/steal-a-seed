--!strict
--==============================================================================
-- Steal a Seed :: PlantGlowSpec
--
-- A planted creature's lights and its Colossal crackle belong to the night.
-- Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlantGlowSpec"))
--
-- The real PlantGlow and PlantAura, fresh-required, against stand-in models in a
-- throwaway folder. PlantGlow is driven exactly the way PlantSway drives it --
-- Watch, Add for a late arrival, Remove, Release, SetNight -- and PlantAura is
-- ticked on its own clock with no camera.
--
-- Not here, verified in Play instead: PlantSway's own watch and phase listener,
-- streaming, real plant builds, what a garden looks like, and the frame rate.
--==============================================================================
local Workspace = game:GetService("Workspace")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local PlantGlow = require(Shared.PlantGlow) :: any
local PlantAura = require(Shared.PlantAura) :: any

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string)
	if ok then
		pass += 1
	else
		table.insert(fails, label)
	end
end

local AUTHORED = "SeedGlowAuthored"
local ORIGIN = Vector3.new(-40, 1200, -40)

local fixture = Instance.new("Folder")
fixture.Name = "PlantGlowSpecFixture"
fixture.Parent = Workspace
local auraFolderBefore = Workspace:FindFirstChild("SeedPlantAura")

local function part(name: string, parent: Instance, offset: Vector3, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size or Vector3.new(2, 2, 2)
	p.CFrame = CFrame.new(ORIGIN + offset)
	p.Parent = parent
	return p
end

local ok, err = pcall(function()
	--== 1. A PLANT WITH THREE KINDS OF LIGHT, ONE AUTHORED OFF =================
	local plant = Instance.new("Model")
	plant.Name = "GlowPlant"
	local body = part("Body", plant, Vector3.zero)
	local head = part("Head", plant, Vector3.new(0, 3, 0))
	local att = Instance.new("Attachment")
	att.Name = "GlowAttachment"
	att.Parent = head
	plant.PrimaryPart = body
	plant.Parent = fixture

	local point = Instance.new("PointLight")
	point.Name = "SolarGlow"
	point.Brightness = 2.4
	point.Range = 60
	point.Color = Color3.fromRGB(255, 190, 40)
	point.Shadows = false
	point.Enabled = true
	point.Parent = body

	local spot = Instance.new("SpotLight")
	spot.Name = "AuthoredOff"
	spot.Brightness = 1.25
	spot.Range = 17.5
	spot.Color = Color3.fromRGB(12, 200, 255)
	spot.Shadows = true
	spot.Angle = 45
	spot.Enabled = false
	spot.Parent = att

	local surface = Instance.new("SurfaceLight")
	surface.Name = "Panel"
	surface.Brightness = 0.7
	surface.Range = 9
	surface.Face = Enum.NormalId.Top
	surface.Enabled = true
	surface.Parent = head

	local authored: { [Light]: { any } } = {}
	for _, l in ipairs({ point, spot, surface } :: { Light }) do
		authored[l] = { l.Brightness, l.Range, l.Color, l.Shadows, l.Parent }
	end
	local function untouched(): boolean
		for l, v in pairs(authored) do
			if l.Brightness ~= v[1] or l.Range ~= v[2] or l.Color ~= v[3]
				or l.Shadows ~= v[4] or l.Parent ~= v[5] then
				return false
			end
		end
		return true
	end

	-- A light that is NOT in a planted model, which the gate must never touch.
	local bystanderHost = part("Mill", fixture, Vector3.new(40, 0, 0))
	local bystander = Instance.new("PointLight")
	bystander.Name = "MillLight"
	bystander.Brightness = 3
	bystander.Enabled = true
	bystander.Parent = bystanderHost

	--== 2. WATCHED BY DAY ======================================================
	PlantGlow.SetNight(false)
	check(PlantGlow.IsNight() == false, "starts in day")
	PlantGlow.Watch(plant)
	check(point.Enabled == false and spot.Enabled == false and surface.Enabled == false,
		"day: every light in the plant is off, whatever its class")
	check(point:GetAttribute(AUTHORED) == true, "PointLight's authored ON captured before the write")
	check(spot:GetAttribute(AUTHORED) == false, "SpotLight's authored OFF captured, not assumed on")
	check(surface:GetAttribute(AUTHORED) == true, "SurfaceLight's authored ON captured")
	local models, lights, lit = PlantGlow.Stats()
	check(models == 1 and lights == 3 and lit == 0, "day: 1 model, 3 lights held, 0 lit")
	check(untouched(), "day: Brightness, Range, Color, Shadows and parent unchanged")
	check(bystander.Enabled == true, "day: a light outside any plant is left on")

	--== 3. NIGHT ===============================================================
	PlantGlow.SetNight(true)
	check(point.Enabled == true and surface.Enabled == true,
		"night: authored-on lights come back")
	check(spot.Enabled == false, "night: an authored-off light stays off")
	models, lights, lit = PlantGlow.Stats()
	check(models == 1 and lights == 3 and lit == 2, "night: 2 of 3 lit")
	check(untouched(), "night: nothing but Enabled ever written")

	--== 4. A LIGHT ARRIVING LATE, AT NIGHT AND BY DAY ==========================
	local late = Instance.new("PointLight")
	late.Name = "LateGlow"
	late.Enabled = true
	late.Parent = head
	PlantGlow.Add(plant, late)
	check(late.Enabled == true, "night: a light added after the watch is on")
	PlantGlow.SetNight(false)
	check(late.Enabled == false and point.Enabled == false, "day: the late light goes dark with the rest")
	local lateByDay = Instance.new("PointLight")
	lateByDay.Name = "StreamedInByDay"
	lateByDay.Enabled = true
	lateByDay.Parent = body
	PlantGlow.Add(plant, lateByDay)
	check(lateByDay.Enabled == false and lateByDay:GetAttribute(AUTHORED) == true,
		"day: a light streaming in is captured ON and switched off at once")
	PlantGlow.Add(plant, lateByDay)
	models, lights = PlantGlow.Stats()
	check(lights == 5, "adding the same light twice holds it once")

	--== 5. ANYTHING THAT IS NOT A LIGHT IS IGNORED =============================
	local extra = part("Petal", plant, Vector3.new(1, 1, 1))
	PlantGlow.Add(plant, extra)
	PlantGlow.Add(plant, att)
	models, lights = PlantGlow.Stats()
	check(models == 1 and lights == 5, "parts and attachments are not held")
	check(extra:GetAttribute(AUTHORED) == nil, "a non-light never gets the attribute")

	--== 6. A LIGHT THAT LEAVES =================================================
	PlantGlow.Remove(late)
	late:Destroy()
	models, lights = PlantGlow.Stats()
	check(lights == 4, "a removed light is dropped")
	PlantGlow.Remove(extra)
	models, lights = PlantGlow.Stats()
	check(lights == 4, "removing a non-light changes nothing")

	-- Destroyed without a removal reaching the gate: dropped at the next phase.
	lateByDay:Destroy()
	PlantGlow.SetNight(true)
	models, lights, lit = PlantGlow.Stats()
	check(lights == 3 and lit == 2, "a light destroyed silently is dropped at the next phase change")

	--== 7. FIVE FULL DAY -> NIGHT -> DAY CYCLES ================================
	local cyclesOk = true
	for _ = 1, 5 do
		PlantGlow.SetNight(false)
		local _, l1, lit1 = PlantGlow.Stats()
		if l1 ~= 3 or lit1 ~= 0 or point.Enabled or surface.Enabled or spot.Enabled then
			cyclesOk = false
		end
		PlantGlow.SetNight(true)
		local _, l2, lit2 = PlantGlow.Stats()
		if l2 ~= 3 or lit2 ~= 2 or not point.Enabled or not surface.Enabled or spot.Enabled then
			cyclesOk = false
		end
	end
	PlantGlow.SetNight(false)
	check(cyclesOk, "five cycles: 0 lit by day and 2 lit by night every time")
	check(point:GetAttribute(AUTHORED) == true and spot:GetAttribute(AUTHORED) == false
		and surface:GetAttribute(AUTHORED) == true, "five cycles: authored values never overwritten")
	check(untouched(), "five cycles: Brightness, Range, Color, Shadows and parent exact")
	check(bystander.Enabled == true, "five cycles: the bystander light was never written")
	PlantGlow.SetNight(false)
	check(point.Enabled == false, "setting the same phase twice is harmless")

	--== 8. RELEASE, AND BEING WATCHED AGAIN ====================================
	PlantGlow.Release(plant)
	models, lights = PlantGlow.Stats()
	check(models == 0 and lights == 0, "release drops every reference")
	check(point.Enabled == false, "release by day leaves the light dark (no flash on a lift or burst)")
	PlantGlow.SetNight(true)
	check(point.Enabled == false, "a released plant is no longer switched by the phase")
	PlantGlow.Watch(plant)
	check(point.Enabled == true and surface.Enabled == true and spot.Enabled == false,
		"watched again at night: restored from the AUTHORED value, not from what the gate left")

	--== 9. RESET ===============================================================
	PlantGlow.Reset()
	models, lights = PlantGlow.Stats()
	check(models == 0 and lights == 0, "reset clears the tables")
	check(point.Enabled == true, "reset writes nothing")
	PlantGlow.SetNight(false)
	check(point.Enabled == true, "after reset the phase reaches nothing")

	--== 10. THE COLOSSAL CRACKLE ===============================================
	local colossal = Instance.new("Model")
	colossal.Name = "Colossal"
	local cbody = part("Trunk", colossal, Vector3.new(0, 0, 80), Vector3.new(4, 12, 4))
	part("Arm", colossal, Vector3.new(3, 4, 80), Vector3.new(2, 1, 1))
	part("Crown", colossal, Vector3.new(0, 8, 80), Vector3.new(5, 3, 5))
	colossal.PrimaryPart = cbody
	colossal:SetAttribute("Tier", 7)
	colossal.Parent = fixture
	local camPos = ORIGIN + Vector3.new(0, 4, 95)

	PlantAura.SetQuality("Full")
	local now = 0
	local state = PlantAura.Prepare(colossal, 12, "starbloom", 7, now, Random.new(20260914))
	check(state ~= nil, "a Colossal gets an aura state")

	local function auraLights(): (number, number)
		local folder = Workspace:FindFirstChild("SeedPlantAura")
		local parented, visible = 0, 0
		if folder then
			for _, d in ipairs(folder:GetDescendants()) do
				if d:IsA("PointLight") then
					parented += 1
				elseif d:IsA("BasePart") and d.Transparency < 1 then
					visible += 1
				end
			end
		end
		return parented, visible
	end

	local function run(seconds: number): (number, number, number)
		local peakActive, peakLights, peakVisible = 0, 0, 0
		local dt = 1 / 30
		for _ = 1, math.floor(seconds / dt) do
			now += dt
			PlantAura.Tick(now, dt, camPos, nil)
			local _, active, _, _, lightsOut = PlantAura.Stats()
			local _, visible = auraLights()
			peakActive = math.max(peakActive, active)
			peakLights = math.max(peakLights, lightsOut)
			peakVisible = math.max(peakVisible, visible)
		end
		return peakActive, peakLights, peakVisible
	end

	PlantAura.SetNight(false, now)
	local a0, l0, v0 = run(8)
	check(a0 == 0 and l0 == 0 and v0 == 0, "day: eight seconds and not one pulse, light or lit segment")

	local cycleOk = true
	local madeAfterFirst = -1
	for cycle = 1, 5 do
		PlantAura.SetNight(true, now)
		local a1, l1 = run(6)
		if a1 == 0 or l1 == 0 then
			cycleOk = false
		end
		-- Dawn lands mid-strike on purpose: run until something is lit, then end
		-- the night on that frame.
		local guard = 0
		repeat
			now += 1 / 30
			PlantAura.Tick(now, 1 / 30, camPos, nil)
			local _, active = PlantAura.Stats()
			guard += 1
		until active > 0 or guard > 600
		PlantAura.SetNight(false, now)
		local plantsN, active, _, made, lightsOut = PlantAura.Stats()
		local parented, visible = auraLights()
		if active ~= 0 or lightsOut ~= 0 or parented ~= 0 or visible ~= 0 or plantsN ~= 1 then
			cycleOk = false
		end
		local a2, l2, v2 = run(3)
		if a2 ~= 0 or l2 ~= 0 or v2 ~= 0 then
			cycleOk = false
		end
		if cycle == 1 then
			madeAfterFirst = made
		end
	end
	local _, _, _, madeEnd = PlantAura.Stats()
	check(cycleOk, "five cycles: strikes at night, and dawn retires every segment and flash light at once")
	-- One plant pulses at most once at a time, so its whole lifetime of strikes
	-- can never need more segments than one near pulse holds.
	local ceiling = PlantAura.Config.ArcsNear * PlantAura.Config.Segments
	check(madeAfterFirst > 0 and madeEnd <= ceiling,
		("five cycles: the pool is reused -- %d segment(s) ever made, ceiling %d"):format(madeEnd, ceiling))

	-- Reduced effects are untouched by the phase: Off still means nothing, at night.
	PlantAura.SetQuality("Off")
	PlantAura.SetNight(true, now)
	local aOff = run(6)
	check(aOff == 0, "night with effects Off: still no pulses")
	PlantAura.SetQuality("Full")
	PlantAura.SetNight(false, now)

	PlantAura.Forget(state)
	local plantsLeft = PlantAura.Stats()
	check(plantsLeft == 0, "forget drops the aura state")
end)

fixture:Destroy()
if not auraFolderBefore then
	local made = Workspace:FindFirstChild("SeedPlantAura")
	if made then
		made:Destroy()
	end
end

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("PlantGlowSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("PlantGlowSpec: %d passed, 0 failed"):format(pass)
