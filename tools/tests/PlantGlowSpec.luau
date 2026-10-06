--!strict
--==============================================================================
-- Steal a Seed :: PlantGlowSpec
--
-- A planted creature's lights belong to the night. Its Colossal crackle
-- strikes day and night, and only the crackle's flash light is the night's
-- (2026-10-05, the owner's ask; it used to be night only).
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

	--== 10. THE COLOSSAL CRACKLE: BOLTS DAY AND NIGHT, THE FLASH AT NIGHT ====
	-- (2026-10-05, the owner's ask.) It used to be night only, bolts and all.
	-- Now the pooled bolts strike in every phase on the same pacing, the one
	-- flash light per pulse is the night's, and a phase change neither queues
	-- a wave nor silences a bed.
	local HIDDEN = require(Shared.PlantVisibility).Marker
	local camPos = ORIGIN + Vector3.new(0, 4, 95)

	local function standIn(name: string, x: number, tier: number): Model
		local m = Instance.new("Model")
		m.Name = name
		local trunk = part("Trunk", m, Vector3.new(x, 0, 80), Vector3.new(4, 12, 4))
		part("Arm", m, Vector3.new(x + 3, 4, 80), Vector3.new(2, 1, 1))
		part("Crown", m, Vector3.new(x, 8, 80), Vector3.new(5, 3, 5))
		m.PrimaryPart = trunk
		m:SetAttribute("Tier", tier)
		m.Parent = fixture
		return m
	end

	PlantAura.SetQuality("Full")
	PlantAura.SetNight(false, 0)
	local now = 0
	local titan = standIn("Titan", -60, 6)
	check(PlantAura.Prepare(titan, 12, "starbloom", 7, now, Random.new(7)) == nil,
		"a Titan gets no aura state: the crackle is still Colossal only")
	local colossal = standIn("Colossal", 0, 7)
	local state = PlantAura.Prepare(colossal, 12, "starbloom", 7, now, Random.new(20260914))
	check(state ~= nil, "a Colossal gets an aura state")

	-- Every state being watched, so a frame's STARTS can be counted: a pulse
	-- begins where `pulsing` turns true.
	local watched: { any } = { state }
	local was: { [any]: boolean } = {}

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

	type Run = { active: number, lights: number, visible: number, parented: number,
		starts: number, maxStarts: number, firstStarts: number, struck: { [any]: number },
		thickLo: number, thickHi: number, core: boolean }
	-- The lit segments' stroke: the thinnest and thickest, and whether any is
	-- the palette's near-white core (only one palette is in play where it is read).
	local coreColour = PlantAura.Palette.starbloom.core
	local function strokes(r: Run)
		local folder = Workspace:FindFirstChild("SeedPlantAura")
		if not folder then
			return
		end
		for _, d in ipairs(folder:GetChildren()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				r.thickLo = math.min(r.thickLo, d.Size.X)
				r.thickHi = math.max(r.thickHi, d.Size.X)
				if d.Color == coreColour then
					r.core = true
				end
			end
		end
	end
	local function step(r: Run, frame: number)
		local dt = 1 / 30
		now += dt
		PlantAura.Tick(now, dt, camPos, nil)
		local _, active, _, _, lightsOut = PlantAura.Stats()
		local parented, visible = auraLights()
		r.active = math.max(r.active, active)
		r.lights = math.max(r.lights, lightsOut)
		r.visible = math.max(r.visible, visible)
		r.parented = math.max(r.parented, parented)
		strokes(r)
		local started = 0
		for _, st in ipairs(watched) do
			if st.pulsing and not was[st] then
				started += 1
				r.struck[st] = (r.struck[st] or 0) + 1
			end
			was[st] = st.pulsing
		end
		r.starts += started
		r.maxStarts = math.max(r.maxStarts, started)
		if frame == 1 then
			r.firstStarts = started
		end
	end
	local function run(seconds: number): Run
		local r: Run = { active = 0, lights = 0, visible = 0, parented = 0, starts = 0,
			maxStarts = 0, firstStarts = 0, struck = {}, thickLo = math.huge, thickHi = 0, core = false }
		for frame = 1, math.floor(seconds / (1 / 30) + 0.5) do
			step(r, frame)
		end
		return r
	end
	-- Ticks until `want` holds, so a phase change can be made to land mid-strike.
	local function until_(want: () -> boolean): boolean
		local r = run(0)
		for frame = 1, 900 do
			if want() then
				return true
			end
			step(r, frame)
		end
		return want()
	end
	local function lightsOut(): number
		local _, _, _, _, l = PlantAura.Stats()
		return l
	end
	local function activeNow(): number
		local _, a = PlantAura.Stats()
		return a
	end

	--== 10a. BY DAY: BOLTS, NO FLASH ==
	local day = run(8)
	check(day.starts >= 3 and day.visible > 0,
		("day: the Colossal strikes (%d pulses in 8 s, %d lit segment(s) at most)"):format(day.starts, day.visible))
	check(day.lights == 0 and day.parented == 0, "day: no flash light is ever taken or parented")
	local dayThick = state.thick * PlantAura.Config.DayThickScale
	check(math.abs(day.thickLo - dayThick) < 1e-4 and math.abs(day.thickHi - dayThick) < 1e-4 and not day.core,
		string.format("day: every lit segment is the bolder stroke (%.3f, x%.1f the night's) and none is the near-white core",
			dayThick, PlantAura.Config.DayThickScale), string.format("%.3f-%.3f core %s", day.thickLo, day.thickHi, tostring(day.core)))

	--== 10b. AT NIGHT: BOLTS AND THE FLASH ==
	PlantAura.SetNight(true, now)
	local night = run(6)
	check(night.starts >= 2 and night.lights > 0 and night.parented > 0,
		("night: strikes with a flash light (%d pulses, %d light(s) at most)"):format(night.starts, night.lights))
	-- The pulse begun by day, if one is still fading, is the only bold one: the first strikes of the night set the look.
	local nightLook = run(2)
	check(math.abs(nightLook.thickLo - state.thick) < 1e-4 and math.abs(nightLook.thickHi - state.thick) < 1e-4
		and nightLook.core,
		string.format("night: the approved look -- the %.3f stroke with its near-white core segments", state.thick),
		string.format("%.3f-%.3f core %s", nightLook.thickLo, nightLook.thickHi, tostring(nightLook.core)))

	--== 10c. DAWN MID-FLASH: THE LIGHT GOES, THE BOLT FINISHES, THE BED GOES ON ==
	check(until_(function()
		return lightsOut() > 0
	end), "night: a pulse with a flash light comes up")
	-- Two frames on, so the new pulse's segments have been placed and lit (a
	-- pulse is drawn from the Tick after the one that starts it).
	run(2 / 30)
	check(lightsOut() > 0, "night: the flash is still lit two frames in")
	local activeBefore = activeNow()
	PlantAura.SetNight(false, now)
	local parentedAfter, visibleAfter = auraLights()
	check(lightsOut() == 0 and parentedAfter == 0,
		"dawn mid-strike: every flash light is back in its pool at once")
	check(activeNow() == activeBefore and visibleAfter > 0,
		"dawn mid-strike: the bolt itself is not cut off -- it finishes its own fade")
	local afterDawn = run(3)
	check(afterDawn.starts >= 1 and afterDawn.lights == 0 and afterDawn.parented == 0,
		("after dawn: still striking (%d), never with a light"):format(afterDawn.starts))

	--== 10d. DUSK MID-STRIKE: A DAYTIME PULSE TAKES NO LIGHT; THE NEXT MAY ==
	check(until_(function()
		return activeNow() > 0
	end), "day: a pulse comes up")
	PlantAura.SetNight(true, now)
	check(lightsOut() == 0, "dusk mid-strike: no light is hung on a pulse that began by day")
	local afterDusk = run(6)
	check(afterDusk.starts >= 2 and afterDusk.lights > 0,
		("after dusk: striking (%d) and the flash is back"):format(afterDusk.starts))

	--== 10e. FIVE CYCLES, EACH CHANGE LANDING MID-STRIKE ==
	local cycleOk = true
	local cycleNote = ""
	for cycle = 1, 5 do
		until_(function()
			return lightsOut() > 0
		end)
		PlantAura.SetNight(false, now)
		local p0 = auraLights()
		if lightsOut() ~= 0 or p0 ~= 0 then
			cycleOk = false
			cycleNote ..= (" c%d: light left at dawn"):format(cycle)
		end
		local d = run(4)
		if d.starts == 0 or d.lights ~= 0 then
			cycleOk = false
			cycleNote ..= (" c%d: day %d starts %d lights"):format(cycle, d.starts, d.lights)
		end
		until_(function()
			return activeNow() > 0
		end)
		PlantAura.SetNight(true, now)
		local n = run(4)
		if n.starts == 0 or n.lights == 0 then
			cycleOk = false
			cycleNote ..= (" c%d: night %d starts %d lights"):format(cycle, n.starts, n.lights)
		end
	end
	check(cycleOk, "five day/night cycles: strikes in every phase, a flash only at night, none left at dawn" .. cycleNote)
	local plantsN, _, _, madeOne = PlantAura.Stats()
	-- One plant pulses at most once at a time, so its whole lifetime of strikes
	-- can never need more segments than one near pulse holds.
	local ceiling = PlantAura.Config.ArcsNear * PlantAura.Config.Segments
	check(plantsN == 1 and madeOne > 0 and madeOne <= ceiling,
		("cycles: one state, and the pool is reused -- %d segment(s) ever made, ceiling %d"):format(madeOne, ceiling))

	--== 10f. A BED: NO WAVE AT A CHANGE, NOBODY GOES QUIET ==
	-- Under the old rule a bed that sat out the day was all due at dusk; this
	-- is the check that it never is now. Ten Colossals, a long day, then both
	-- changes. Every plant strikes within any 3 s (its gap is at most 1.9 s).
	PlantAura.SetNight(false, now)
	local bed: { any } = {}
	for i = 1, 10 do
		local m = standIn("Bed" .. i, -40 + i * 8, 7)
		m:PivotTo(m:GetPivot() + Vector3.new(0, 0, -20))
		local st = PlantAura.Prepare(m, 12, "greenhollow", 7, now, Random.new(4100 + i))
		table.insert(bed, st)
		table.insert(watched, st)
	end
	local longDay = run(30)
	local function everyone(r: Run): boolean
		for _, st in ipairs(bed) do
			if (r.struck[st] or 0) == 0 then
				return false
			end
		end
		return true
	end
	PlantAura.SetNight(true, now)
	local dusk = run(3)
	PlantAura.SetNight(false, now)
	local dawn = run(3)
	check(longDay.lights == 0 and dusk.firstStarts <= 2 and dawn.firstStarts <= 2,
		("bed: no wave on the frame of a change (dusk %d, dawn %d start(s); steady max %d a frame)")
			:format(dusk.firstStarts, dawn.firstStarts, longDay.maxStarts))
	check(dusk.maxStarts <= math.max(3, longDay.maxStarts) and dawn.maxStarts <= math.max(3, longDay.maxStarts),
		("bed: the frames after a change are no busier than the day (%d / %d vs %d)")
			:format(dusk.maxStarts, dawn.maxStarts, longDay.maxStarts))
	check(everyone(dusk) and everyone(dawn),
		"bed: every Colossal strikes in the 3 s after dusk and in the 3 s after dawn")
	check(longDay.active <= PlantAura.Config.MaxConcurrent and dusk.active <= PlantAura.Config.MaxConcurrent,
		"bed: never more pulses than the client-wide budget")

	--== 10g. QUALITY: OFF IS OFF IN BOTH PHASES; REDUCED NEVER FLASHES ==
	PlantAura.SetQuality("Off")
	local offDay = run(4)
	PlantAura.SetNight(true, now)
	local offNight = run(4)
	check(offDay.starts == 0 and offNight.starts == 0 and offNight.lights == 0,
		"effects Off: no pulse by day or by night")
	PlantAura.SetQuality("Reduced")
	local reduced = run(4)
	check(reduced.starts > 0 and reduced.lights == 0
		and reduced.active <= math.floor(PlantAura.Config.MaxConcurrent * 0.5),
		("Reduced at night: strikes (%d), no flash, within half the budget"):format(reduced.starts))
	PlantAura.SetQuality("Full")

	--== 10h. A BUSY BED STAYS INSIDE BOTH BUDGETS ==
	local crowd: { any } = {}
	for i = 1, 30 do
		local m = standIn("Crowd" .. i, -45 + (i % 10) * 10, 7)
		m:PivotTo(m:GetPivot() + Vector3.new(0, 0, -math.floor(i / 10) * 14))
		local st = PlantAura.Prepare(m, 12, "dustbowl", 7, now, Random.new(9000 + i))
		table.insert(crowd, st)
		table.insert(watched, st)
	end
	local busyNight = run(6)
	PlantAura.SetQuality("Reduced")
	-- Pulses begun at Full finish their own 0.32 s first; only then is every
	-- lit pulse one the halved budget let start.
	run(0.5)
	local busyReduced = run(6)
	PlantAura.SetQuality("Full")
	PlantAura.SetNight(false, now)
	local busyDay = run(6)
	local _, _, _, madeBusy = PlantAura.Stats()
	local cap = PlantAura.Config.MaxConcurrent * PlantAura.Config.ArcsNear * PlantAura.Config.Segments
	check(busyNight.active <= PlantAura.Config.MaxConcurrent and busyDay.active <= PlantAura.Config.MaxConcurrent
		and busyNight.lights <= PlantAura.Config.MaxLights and busyDay.lights == 0,
		("41 Colossals: at most %d pulses (night %d, day %d) and %d lights (night %d, day %d)")
			:format(PlantAura.Config.MaxConcurrent, busyNight.active, busyDay.active,
				PlantAura.Config.MaxLights, busyNight.lights, busyDay.lights))
	check(busyReduced.active == math.floor(PlantAura.Config.MaxConcurrent * 0.5),
		("41 Colossals on Reduced: the halved budget binds (%d)"):format(busyReduced.active))
	check(madeBusy <= cap, ("41 Colossals: %d segment(s) ever made, ceiling %d"):format(madeBusy, cap))
	for _, st in ipairs(crowd) do
		PlantAura.Forget(st)
	end

	--== 10i. OTHER PLANTS: OFF -- A HIDDEN COLOSSAL TAKES ITS BOLTS AND LIGHT ==
	-- Only the one Colossal: the bed is set aside first.
	for _, st in ipairs(bed) do
		PlantAura.Forget(st)
	end
	PlantAura.SetNight(true, now)
	check(until_(function()
		return lightsOut() > 0
	end), "night: the Colossal is lit again")
	colossal:SetAttribute(HIDDEN, true)
	local hiddenRun = run(0.1)
	local pH, vH = auraLights()
	check(activeNow() == 0 and lightsOut() == 0 and pH == 0 and vH == 0,
		"hidden mid-strike: the bolt and its light go at once")
	local hiddenNight = run(3)
	PlantAura.SetNight(false, now)
	local hiddenDay = run(3)
	check(hiddenRun.starts + hiddenNight.starts + hiddenDay.starts == 0,
		"hidden: nothing starts, by night or by day")
	colossal:SetAttribute(HIDDEN, nil)
	local shown = run(3)
	check(shown.starts >= 1, "shown again: it strikes on its own gap")

	--== 10j. REMOVAL MID-STRIKE RETURNS EVERYTHING ==
	PlantAura.SetNight(true, now)
	check(until_(function()
		return lightsOut() > 0
	end), "night: lit once more before the removal")
	PlantAura.Forget(state)
	local pR, vR = auraLights()
	local plantsLeft, activeLeft, poolLeft, madeAll, lightsLeft = PlantAura.Stats()
	check(plantsLeft == 0 and activeLeft == 0 and lightsLeft == 0 and pR == 0 and vR == 0,
		"forget mid-strike: the state, its bolt and its light are all gone at once")
	check(poolLeft == madeAll, ("every segment ever made is parked in the pool (%d of %d)"):format(poolLeft, madeAll))

	--== 10k. A MODEL THAT LEAVES MID-STRIKE ==
	local leaver = standIn("Leaver", 30, 7)
	local leaverState = PlantAura.Prepare(leaver, 12, "emberroot", 7, now, Random.new(55))
	check(until_(function()
		return activeNow() > 0
	end), "the leaver strikes")
	leaver.Parent = nil
	run(0.1)
	local pL, vL = auraLights()
	check(activeNow() == 0 and lightsOut() == 0 and pL == 0 and vL == 0,
		"a model gone mid-strike: the next tick takes its bolt and light back")
	PlantAura.Forget(leaverState)
	leaver:Destroy()
	PlantAura.SetNight(false, now)
	local plantsEnd, activeEnd, poolEnd, madeEnd, lightsEnd = PlantAura.Stats()
	check(plantsEnd == 0 and activeEnd == 0 and lightsEnd == 0 and poolEnd == madeEnd,
		"at the end: no state, no pulse, no light, every segment in the pool")
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
