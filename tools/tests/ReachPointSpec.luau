--!nocheck
--==============================================================================
-- Steal a Seed :: ReachPointSpec
--
-- Where a pod's hatch timer, the prompt stacked above it, and a grown plant's
-- PICK UP button sit against objects up to 67 studs tall. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("ReachPointSpec"))
--
-- THE DEFECT, MEASURED 2026-09-18 OFF THE PRODUCTION BUILDER:
--
--   pod timer centre above the soil       Tiny 3.6   Colossal 15.6
--   PICK UP button above the soil         Colossal Supernovus 68.2
--
-- Both were placed ABOVE THE OBJECT'S TOP. On a phone the timer and the Instant
-- Hatch button stacked on it left the screen for a player standing beside a
-- tall pod, and a Colossal's PICK UP button was only visible from far away.
--
-- WHAT THIS DRIVES: the real ReachPoint, GameConfig and CreatureModel,
-- fresh-required, against pods and plants built by the production builder for
-- every tier. What it cannot do is watch a phone -- the touch layer's drawing is
-- Play-only, and a physical device is the owner's.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local ReachPoint = require(Shared:WaitForChild("ReachPoint"))

local POD = GameConfig.Labels.Pod
local PROMPT = GameConfig.Labels.Prompt
local REACH = GameConfig.Plant.Reach

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
local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 0.01)
end

local fixture = Instance.new("Folder")
fixture.Name = "ReachPointSpecFixture"
fixture.Parent = ReplicatedStorage

local ok, err = pcall(function()

--==============================================================================
-- 1. THE BOX ARITHMETIC, ON BOXES WHOSE ANSWER IS KNOWN
--==============================================================================
say("-- the box --")
local flat = CFrame.new(10, 5, -3)
check(near(ReachPoint.lowestY(flat, Vector3.new(4, 6, 2)), 2),
	"an upright 6-tall box centred at 5 reaches down to 2")
check(near(ReachPoint.reachAlong(flat, Vector3.new(4, 6, 2), Vector3.xAxis), 2)
		and near(ReachPoint.reachAlong(flat, Vector3.new(4, 6, 2), Vector3.zAxis), 1),
	"and reaches 2 along X and 1 along Z")
local rolled = CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90))
check(near(ReachPoint.lowestY(rolled, Vector3.new(4, 6, 2)), 3),
	"a box rolled 90 degrees -- a pod's pivot -- is measured by its real height, 4, not 6",
	ReachPoint.lowestY(rolled, Vector3.new(4, 6, 2)))
local turned = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(45), 0)
check(near(ReachPoint.reachAlong(turned, Vector3.new(2, 1, 2), Vector3.xAxis), math.sqrt(2)),
	"a square footprint turned 45 degrees reaches its corner, sqrt 2",
	ReachPoint.reachAlong(turned, Vector3.new(2, 1, 2), Vector3.xAxis))

--==============================================================================
-- 2. THE POD TIMER'S HEIGHT, EVERY TIER, OFF THE PRODUCTION BUILDER
--==============================================================================
say("\n-- the timer's height --")
local rows = {}
for _, id in ipairs({ "nubkin", "dunebud" }) do
	local sp = SeedData.Get(id)
	if sp then
		for tier = 1, 7 do
			local pod = CreatureModel.BuildPod(sp, tier, CFrame.new(tier * 40, 0, 0), fixture)
			local anchor = pod.PrimaryPart
			local boxCF, boxSize = pod:GetBoundingBox()
			local soil = ReachPoint.lowestY(boxCF, boxSize)
			local top = GameConfig.topOfModel(pod, anchor)
			local anchorAbove = anchor.Position.Y - soil
			local old = anchorAbove + top + POD.LiftStuds
			local lift = ReachPoint.podLabelLift(top, anchorAbove, POD.LiftStuds, POD.MaxAboveSoil)
			local now = anchorAbove + lift
			table.insert(rows, { id = id, tier = tier, old = old, now = now })
			pod:Destroy()
		end
	end
end
local unchanged, capped, above, lines = true, true, true, {}
for _, r in ipairs(rows) do
	table.insert(lines, string.format("%s T%d %.2f->%.2f", r.id, r.tier, r.old, r.now))
	if r.old <= POD.MaxAboveSoil and not near(r.old, r.now, 0.001) then
		unchanged = false
	end
	if r.old > POD.MaxAboveSoil and not near(r.now, POD.MaxAboveSoil, 0.001) then
		capped = false
	end
	if r.now > POD.MaxAboveSoil + 0.001 then
		above = false
	end
end
say("    " .. table.concat(lines, "  "))
check(#rows == 14, "fourteen production pods measured", #rows)
check(unchanged, "every pod whose timer already sat under the ceiling keeps it to the thousandth")
check(capped, "every taller one is held exactly at the ceiling")
check(above, "no pod's timer sits above " .. POD.MaxAboveSoil .. " studs")
check(rows[7] and rows[7].old > 15 and near(rows[7].now, POD.MaxAboveSoil, 0.001),
	"a Colossal nubkin's timer comes down from over 15 studs to eye level",
	rows[7] and string.format("%.2f -> %.2f", rows[7].old, rows[7].now))
check(rows[1] and rows[1].old < POD.MaxAboveSoil,
	"a Tiny's timer was always under it, and is untouched")

--==============================================================================
-- 3. THE STACK ON A TOUCH SCREEN
--
-- A phone in landscape (844 x 390, 47 of topbar) and a desktop window. Anchors
-- swept across and well beyond every edge. The guarantees: the prompt is always
-- directly above the timer; they never overlap; the group stays below the topbar
-- and above the bottom; and each stays across the screen.
--==============================================================================
say("\n-- the stack --")
local label = Vector2.new(POD.Width, POD.Height)
local prompt = Vector2.new(210, PROMPT.PanelHeight)
local margin = POD.ScreenMargin
local screens = {
	{ name = "phone 844x390", size = Vector2.new(844, 390), inset = 47 },
	{ name = "desktop 1037x714", size = Vector2.new(1037, 714), inset = 58 },
	{ name = "narrow phone 667x375", size = Vector2.new(667, 375), inset = 36 },
}
for _, screen in ipairs(screens) do
	local overlaps, escapes, order, samples = 0, 0, 0, 0
	for x = -400, screen.size.X + 400, 37 do
		for y = -600, screen.size.Y + 600, 29 do
			samples += 1
			local l, p = ReachPoint.stack(Vector2.new(x, y), screen.size, screen.inset,
				label, prompt, PROMPT.StackGap, margin)
			local lTop, lBottom = l.Y - label.Y / 2, l.Y + label.Y / 2
			local pTop, pBottom = p.Y - prompt.Y / 2, p.Y + prompt.Y / 2
			if not (pBottom <= lTop + 0.001 or lBottom <= pTop + 0.001) then
				overlaps += 1
			end
			if pBottom > lTop + 0.001 then
				order += 1
			end
			if pTop < screen.inset + margin - 0.001 or lBottom > screen.size.Y - margin + 0.001
				or l.X - label.X / 2 < margin - 0.001 or l.X + label.X / 2 > screen.size.X - margin + 0.001
				or p.X - prompt.X / 2 < margin - 0.001 or p.X + prompt.X / 2 > screen.size.X - margin + 0.001 then
				escapes += 1
			end
		end
	end
	check(overlaps == 0, string.format("%s: the timer and the prompt never overlap (%d anchors)",
		screen.name, samples), overlaps)
	check(order == 0, screen.name .. ": the prompt is always above the timer", order)
	check(escapes == 0, screen.name .. ": the pair never leaves the safe area", escapes)
end
local l0, p0 = ReachPoint.stack(Vector2.new(422, 200), Vector2.new(844, 390), 47,
	label, prompt, PROMPT.StackGap, margin)
check(near(l0.Y, 200) and near(p0.Y, 200 - (label.Y / 2 + PROMPT.StackGap + prompt.Y / 2)),
	"a pod comfortably on screen is not moved at all -- the stack is exactly PromptUI's old raise")
local l1 = ReachPoint.stack(Vector2.new(422, -300), Vector2.new(844, 390), 47,
	label, prompt, PROMPT.StackGap, margin)
check(l1.Y > 47 and l1.Y < 390, "a pod whose timer projects far above the screen is brought back onto it",
	l1.Y)

--==============================================================================
-- 4. WHICH SIDE: THE DEAD BAND
--==============================================================================
say("\n-- the bearing --")
local east = Vector3.xAxis
local slightly = (Vector3.xAxis + Vector3.zAxis * 0.2).Unit    -- ~11 degrees
local across = Vector3.zAxis                                   -- 90 degrees
check(ReachPoint.bearing(east, slightly, REACH.DeadbandDegrees) == east,
	"a player drifting 11 degrees does not move the button")
check(ReachPoint.bearing(east, across, REACH.DeadbandDegrees) == across,
	"a player walking round a quarter does")
check(ReachPoint.bearing(east, -east, REACH.DeadbandDegrees) == -east,
	"crossing straight through the centreline moves it once, to the new side")
check(ReachPoint.bearing(east, nil, REACH.DeadbandDegrees) == east,
	"no character: it keeps the side it had")
check(ReachPoint.bearing(nil, across, REACH.DeadbandDegrees) == across,
	"a first aim takes the player's side")
check(ReachPoint.toward(Vector3.new(1, 0, 1), Vector3.new(1, 9, 1)) == nil,
	"a player directly above the centre has no side, rather than a NaN")

--==============================================================================
-- 5. THE PICK UP BUTTON, ON PRODUCTION PLANTS
--==============================================================================
say("\n-- the pick up button --")
local soilCF = CFrame.new(0, 0, 0)
local soilSize = Vector3.new(60, 1, 60)
local report = {}
local shortSame, tallHeight, tallEdge, tallInside, onSoil, beyondPlayer = true, true, true, true, true, true
for _, id in ipairs({ "nubkin", "bellchime", "supernovus" }) do
	local sp = SeedData.Get(id)
	for _, tier in ipairs({ 1, 3, 5, 6, 7 }) do
		local model = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN,
			CFrame.new(0, 0.5, 0), fixture)
		local base = model.PrimaryPart
		local boxCF, boxSize = model:GetBoundingBox()
		local height = model:GetExtentsSize().Y
		local soilY = ReachPoint.lowestY(boxCF, boxSize)
		local dir = Vector3.xAxis
		local far = boxCF.Position + dir * 200
		local point, tall = ReachPoint.pickupPoint(boxCF, boxSize, height, base.Position, far,
			dir, nil, nil, REACH)
		local oldY = base.Position.Y + height + 0.8
		local out = Vector3.new(point.X - boxCF.Position.X, 0, point.Z - boxCF.Position.Z).Magnitude
		table.insert(report, string.format("%s T%d h%.1f: %s %.1f up, %.1f out (was %.1f up)",
			id, tier, height, if tall then "edge" else "over", point.Y - soilY, out, oldY - soilY))
		if not tall then
			if not (near(point.Y, oldY, 0.001) and near(point.X, base.Position.X, 0.001)
				and near(point.Z, base.Position.Z, 0.001)) then
				shortSame = false
			end
		else
			if not near(point.Y - soilY, REACH.InteractHeight, 0.001) then
				tallHeight = false
			end
			local edge = ReachPoint.reachAlong(boxCF, boxSize, dir) + REACH.EdgeMargin
			if not near(out, edge, 0.01) then
				tallEdge = false
			end
			-- A player standing INSIDE the footprint gets it in front of them.
			local inside = boxCF.Position + dir * 3
			local p2 = ReachPoint.pickupPoint(boxCF, boxSize, height, base.Position, inside,
				dir, nil, nil, REACH)
			local out2 = Vector3.new(p2.X - boxCF.Position.X, 0, p2.Z - boxCF.Position.Z).Magnitude
			if out2 > 3 - REACH.StandOff + 0.01 then
				beyondPlayer = false
			end
			if (Vector3.new(p2.X, 0, p2.Z) - Vector3.new(inside.X, 0, inside.Z)).Magnitude
				< REACH.StandOff - 0.01 and out2 > 0 then
				tallInside = false
			end
			-- And a bed smaller than the plant keeps it on the soil.
			local p3 = ReachPoint.pickupPoint(boxCF, boxSize, height, base.Position, far,
				dir, soilCF, soilSize, REACH)
			local here = soilCF:PointToObjectSpace(p3)
			if math.abs(here.X) > soilSize.X / 2 - REACH.SoilInset + 0.01
				or math.abs(here.Z) > soilSize.Z / 2 - REACH.SoilInset + 0.01 then
				onSoil = false
			end
		end
		if id == "supernovus" and tier == 7 then
			check(point.Y - soilY <= REACH.InteractHeight + 0.001,
				string.format("a Colossal Supernovus's button is %.1f studs up, not %.1f",
					point.Y - soilY, oldY - soilY))
		end
		model:Destroy()
	end
end
for _, line in ipairs(report) do
	say("    " .. line)
end
check(shortSame, "a plant whose head is within reach keeps the button exactly where it was")
check(tallHeight, "every taller plant's button is at a person's height above the soil")
check(tallEdge, "at its own footprint's edge on the player's side, plus the margin")
check(beyondPlayer, "never further out than the player standing inside a huge footprint")
check(tallInside, "and then just in front of them rather than on top of them")
check(onSoil, "and inside the bed when the plant is bigger than the bed")

--==============================================================================
-- 6. WHAT MUST NOT HAVE CHANGED: THE PER-FRAME BUDGET AND THE TOUCH SAFETY RULES
--==============================================================================
say("\n-- the budget and the rules --")
local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local function sourceOf(name)
	local s = scripts and scripts:FindFirstChild(name)
	local okS, src = pcall(function() return s.Source end)
	return if okS then src else nil
end
local function count(src, pattern)
	local n = 0
	for _ in string.gmatch(src or "", pattern) do
		n += 1
	end
	return n
end
local plantUI = sourceOf("PlantUI")
local pick = sourceOf("PlantPickUI")
local promptUI = sourceOf("PromptUI")
check(plantUI and count(plantUI, "BindToRenderStep%(") == 1
		and count(plantUI, "Heartbeat:Connect") == 0 and count(plantUI, "RenderStepped:Connect") == 0,
	"PlantUI has exactly one per-frame binding for every pod -- the one it always had")
check(pick and count(pick, "BindToRenderStep%(") == 0 and count(pick, "Heartbeat:Connect") == 0
		and count(pick, "RenderStepped:Connect") == 0,
	"PlantPickUI runs nothing per frame; it re-aims on the selection's poll")
check(promptUI and count(promptUI, "BindToRenderStep%(") == 1,
	"PromptUI still has its one tracker")
--==============================================================================
-- THE COUNTDOWN SURVIVES A DEATH
--
-- Found in Play on 2026-09-18: PlantUI kept every billboard in a plain Folder,
-- a respawn's PlayerGui reset deleted the Folder, and the player had no timer on
-- any pod for the rest of the session -- 14 pods, 0 billboards. A billboard now
-- stands in PlayerGui on its own with ResetOnSpawn off.
--==============================================================================
check(plantUI and plantUI:find("made.ResetOnSpawn = false", 1, true) ~= nil
		and plantUI:find("made.Parent = playerGui", 1, true) ~= nil,
	"PlantUI's billboards sit in PlayerGui with ResetOnSpawn off, so a respawn keeps them")
check(plantUI and plantUI:find('Instance.new("Folder")', 1, true) == nil,
	"and there is no Folder left for a respawn to delete them with")

check(pick and pick:find("local TAP_SLOP = 10", 1, true) ~= nil
		and pick:find("local TAP_SECONDS = 0.5", 1, true) ~= nil,
	"a touch still has to begin and end as a tap to select")
check(pick and pick:find("if processed or holdingAPlant() then", 1, true) ~= nil,
	"planting still owns every click while a plant is in the hands")
check(pick and pick:find("button.Activated:Connect(press)", 1, true) ~= nil
		and pick:find("channel:FireServer(PLANTING.PickUpAction, id)", 1, true) ~= nil
		and pick:find("local PRESS_DEBOUNCE = 0.4", 1, true) ~= nil,
	"PICK UP is still a separate button that sends one request, debounced")
check(pick and pick:find("markerFor", 1, true) ~= nil and pick:find("myPlot()", 1, true) ~= nil,
	"only a plant in your own plot can be selected")
check(pick and pick:find("ProximityPrompt\")", 1, true) == nil,
	"and no pickup ProximityPrompt came back -- the one with no key ate every mouse click")

end)

fixture:Destroy()
if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return table.concat(out, "\n") .. ("\nReachPointSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return table.concat(out, "\n") .. ("\nReachPointSpec: %d passed, 0 failed"):format(pass)
