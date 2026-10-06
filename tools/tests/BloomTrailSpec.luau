--!nocheck
--==============================================================================
-- Steal a Seed :: BloomTrailSpec (2026-10-04, the owner's Bloomrunner brief)
--
-- Edit mode, no Play:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("BloomTrailSpec"))
--
-- 1. THE LOOK'S NUMBERS (Shared/BloomTrail): what Full, Reduced and Off draw;
--    the weave stays between ankle and waist, behind the body, and holds still
--    without road; the shimmer is slow and soft; petals and flowers are laid
--    by road with hard rate caps, and nothing outlives a second and a half.
-- 2. TRAILFX, RUN FOR REAL: the real client script, loaded with stand-in
--    players, a stand-in Heartbeat and clock, on real bodies over a real floor
--    high above the map. Equip, unequip, respawn, leaving, a body vanishing,
--    teleports, the course, ragdoll / seat / death, distance, standing still,
--    a wall, starting, turning, sprinting, stopping, Full / Reduced / Off and
--    reduced motion -- counting every Trail, attachment and part it makes, and
--    every one it should not.
-- 3. THE SOURCE: one loop; nothing made, connected or tweened per frame; no
--    texture ids; nothing sent; Lighting untouched.
--
-- NOT here: how it looks (a screenshot in Play), a second real client, phones.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local BloomTrail = require(Shared.BloomTrail)
local GameConfig = require(Shared.GameConfig)
local ObbyData = require(Shared.ObbyData)
local WheelData = require(Shared.WheelData)
local Scripts = game:GetService("StarterPlayer").StarterPlayerScripts

local L = BloomTrail.Look
local B = BloomTrail.Budget
local FX = GameConfig.Afterimage
local TRAIL_ATTR = WheelData.Attributes.Trail
local TRAIL_ID = WheelData.Trail.Id
local QUALITY = FX.QualityAttribute
local COURSE = ObbyData.Attributes.Course

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
		say("  FAIL  " .. label .. (if detail ~= nil and detail ~= "" then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local s = parent:FindFirstChild(name)
	return if s then s.Source else ""
end
local function count(text, needle)
	local n, at = 0, 1
	while true do
		local found = string.find(text, needle, at, true)
		if not found then
			return n
		end
		n += 1
		at = found + #needle
	end
end
-- Source with its comments taken out, so a rule written down is not mistaken
-- for a rule in force.
local function code(src)
	local lines = {}
	for _, line in ipairs(string.split(src, "\n")) do
		local at = string.find(line, "--", 1, true)
		table.insert(lines, if at then string.sub(line, 1, at - 1) else line)
	end
	return table.concat(lines, "\n")
end
local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-6)
end
-- A ColorSequence's colour at t, as the engine blends it.
local function colourAt(seq, t)
	local kps = seq.Keypoints
	for i = 1, #kps - 1 do
		local a, b = kps[i], kps[i + 1]
		if t >= a.Time and t <= b.Time then
			local span = b.Time - a.Time
			return a.Value:Lerp(b.Value, if span > 0 then (t - a.Time) / span else 0)
		end
	end
	return kps[#kps].Value
end
-- How far c is lifted from base toward white (0 = not at all, 1 = white).
local function liftOf(c, base)
	local most = 0
	for _, k in ipairs({ "R", "G", "B" }) do
		local room = 1 - base[k]
		if room > 0.02 then
			most = math.max(most, (c[k] - base[k]) / room)
		end
	end
	return most
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZBloomTrailSpec"
scratch.Archivable = false
scratch.Parent = Workspace
local copies = {}

local ok, err = pcall(function()

--==============================================================================
-- 1. THE LOOK'S NUMBERS
--==============================================================================
say("-- 1. the look's numbers --")
check(B.Full.Ribbons == 2 and B.Reduced.Ribbons == 1 and B.Off.Ribbons == 0,
	"Full draws two ribbons, Reduced one, Off none")
check(B.Reduced.Petals == 0 and B.Reduced.Blooms == 0 and B.Off.Petals == 0 and B.Off.Blooms == 0,
	"Reduced and Off lay no petals and open no flowers")
check(B.Full.Petals >= 6 and B.Full.Petals <= 16 and B.Full.Blooms >= 1 and B.Full.Blooms <= 3
		and B.Full.BloomPetals >= 4 and B.Full.BloomPetals <= 6,
	"Full's caps are a handful, not a cloud: " .. B.Full.Petals .. " petals, " .. B.Full.Blooms .. " flowers of "
		.. B.Full.BloomPetals)
check(BloomTrail.partsFor("Full") == 24 and BloomTrail.partsFor("Reduced") == 0 and BloomTrail.partsFor("Off") == 0
		and BloomTrail.partsFor("nonsense") == 0,
	"one wearer's pool: 24 parts on Full, none on Reduced or Off")

check(BloomTrail.mode("Off", false) == "Off" and BloomTrail.mode("Off", true) == "Off",
	"FX Off is Off, reduced motion or not")
check(BloomTrail.mode("Reduced", false) == "Reduced" and BloomTrail.mode("Full", true) == "Reduced"
		and BloomTrail.mode(nil, true) == "Reduced",
	"Reduced FX, and reduced motion on any other setting, draw what Reduced draws")
check(BloomTrail.mode("Full", false) == "Full" and BloomTrail.mode(nil, false) == "Full"
		and BloomTrail.mode(7, false) == "Full",
	"anything else is Full")

do
	local bounded, rising = true, true
	local last = -1
	for speed = -10, 400, 0.5 do
		local e = BloomTrail.energy(speed)
		bounded = bounded and e >= 0 and e <= 1
		rising = rising and e >= last
		last = e
	end
	check(bounded and rising and BloomTrail.energy(0 / 0) == 0 and BloomTrail.energy(math.huge) == 1,
		"energy rises with speed and stays within 0..1 (NaN is 0, any sprint is 1)")
	check(BloomTrail.energy(16) == 0 and BloomTrail.energy(L.EnergyToSpeed) == 1,
		"a walk at 16 is calm; full energy from " .. L.EnergyToSpeed .. " studs/s")
	local wide = L.RibbonHalf * (1 + L.RibbonHalfEnergy)
	check(wide <= L.RibbonHalf * 1.3 and L.WeaveAmplitudeEnergy <= 0.25 and L.PetalStudsEnergy >= L.PetalStuds * 0.6
			and L.BloomStudsEnergy >= L.BloomStuds * 0.7,
		"and what energy adds is modest: ribbons +" .. math.floor(L.RibbonHalfEnergy * 100 + 0.5) .. "% wide, weave +"
			.. math.floor(L.WeaveAmplitudeEnergy * 100 + 0.5) .. "%, petals and flowers a little closer")
end

do
	-- A body whose root stands 3 studs high: ankle ~0.3 off the floor (-2.7),
	-- waist at the root (0). Behind is +Z. The swing at its widest included.
	local lowest, highest, minBehind, widest = math.huge, -math.huge, math.huge, 0
	local still, collapsed, crossing, periodic, steady = true, true, true, true, true
	for d = 0, 36, 0.25 do
		for _, presence in ipairs({ 0, 0.4, 1 }) do
			for _, energy in ipairs({ 0, 1 }) do
				for which = 1, 2 do
					for _, quiet in ipairs({ false, true }) do
						local c, half = BloomTrail.weave(d, presence, energy, which, quiet)
						lowest = math.min(lowest, c.Y - half)
						highest = math.max(highest, c.Y + half)
						minBehind = math.min(minBehind, c.Z)
						widest = math.max(widest, math.abs(c.X) + L.TurnSwingMax)
						if quiet then
							still = still and c.X == 0 and near(c.Y, L.RibbonHeight, 1e-5)
						end
						if presence == 0 then
							collapsed = collapsed and half == 0 and (quiet or c.X == 0)
						end
						local again = BloomTrail.weave(d, presence, energy, which, quiet)
						steady = steady and again == c
						local later = BloomTrail.weave(d + L.WeaveStuds, presence, energy, which, quiet)
						periodic = periodic and (later - c).Magnitude < 1e-6
					end
				end
				local mint = BloomTrail.weave(d, presence, energy, 1, false)
				local gold = BloomTrail.weave(d, presence, energy, 2, false)
				crossing = crossing and near(mint.X, -gold.X, 1e-6)
					and near(mint.Y - L.RibbonHeight, -(gold.Y - L.RibbonHeight), 1e-6)
			end
		end
	end
	check(lowest >= -2.7 and highest <= 0, "both ribbons stay between ankle and waist",
		string.format("%.2f..%.2f", lowest, highest))
	check(minBehind >= 0.5, "and behind the body", string.format("nearest %.2f", minBehind))
	check(widest <= 1.0, "never wider than the body, even swung out in a turn", string.format("%.2f", widest))
	check(still, "Reduced's one ribbon is still: on the centre line at every distance")
	check(collapsed, "with no presence a ribbon is nothing: no width, no weave")
	check(crossing, "mint and gold are half a turn apart: they cross and re-cross, one over while one goes under")
	check(steady, "the same road gives the same place: standing still moves nothing")
	check(periodic, "one weave every " .. L.WeaveStuds .. " studs, so TrailFX can wrap the road it counts")
	check(BloomTrail.swing(3) > 0 and BloomTrail.swing(-3) < 0 and BloomTrail.swing(1e6) == L.TurnSwingMax
			and BloomTrail.swing(-1e6) == -L.TurnSwingMax and BloomTrail.swing(0 / 0) == 0,
		"a turn swings the pair to its outside, never more than " .. L.TurnSwingMax .. " studs")
end

do
	local mint, leaf = WheelData.Trail.Mint, WheelData.Trail.Leaf
	local frames = BloomTrail.shimmerFrames(mint, leaf, L.ShimmerFrames)
	local valid, maxLift, maxStep, maxCover = #frames == L.ShimmerFrames, 0, 0, 0
	local prev, first = nil, nil
	for _, seq in ipairs(frames) do
		local kps = seq.Keypoints
		valid = valid and kps[1].Time == 0 and kps[#kps].Time == 1 and #kps <= 20
		for i = 2, #kps do
			valid = valid and kps[i].Time > kps[i - 1].Time
		end
		local lifts = {}
		local covered = 0
		for i = 0, 100 do
			local t = i / 100
			local lift = liftOf(colourAt(seq, t), mint:Lerp(leaf, t))
			lifts[i] = lift
			maxLift = math.max(maxLift, lift)
			if lift > 0.05 then
				covered += 1
			end
			if prev then
				maxStep = math.max(maxStep, math.abs(lift - prev[i]))
			end
		end
		maxCover = math.max(maxCover, covered / 101)
		prev = lifts
		first = first or lifts
	end
	-- and from the last frame back round to the first
	for i = 0, 100 do
		maxStep = math.max(maxStep, math.abs(prev[i] - first[i]))
	end
	check(valid, L.ShimmerFrames .. " shimmer frames, each a valid sequence from the fresh end to the old")
	check(maxLift <= L.ShimmerLift + 0.01 and maxLift >= L.ShimmerLift - 0.05,
		"the light lifts the ribbon's own colour at most " .. L.ShimmerLift .. " of the way to white",
		string.format("%.3f", maxLift))
	check(maxCover <= 0.3, "and lights at most a third of it at once: a band, never the whole ribbon",
		string.format("%.2f", maxCover))
	check(maxStep <= 0.16, "frame to frame, no point of the ribbon brightens or dims by more than a sixth of that: no flash",
		string.format("%.3f", maxStep))
	check(L.ShimmerSeconds >= 1.2 and L.ShimmerSeconds / L.ShimmerFrames <= 0.1,
		string.format("one slow pass every %.1f s, in steps of %.0f ms", L.ShimmerSeconds,
			1000 * L.ShimmerSeconds / L.ShimmerFrames))
	local cycle, monotone = true, true
	local last = 0
	for i = 0, L.ShimmerFrames * 4 - 1 do
		local t = (i + 0.5) * L.ShimmerSeconds / (L.ShimmerFrames * 4)
		local k = BloomTrail.shimmerIndex(t, L.ShimmerFrames)
		monotone = monotone and k >= last
		last = k
	end
	cycle = BloomTrail.shimmerIndex(0, L.ShimmerFrames) == 1
		and BloomTrail.shimmerIndex(L.ShimmerSeconds * 0.999, L.ShimmerFrames) == L.ShimmerFrames
		and BloomTrail.shimmerIndex(L.ShimmerSeconds * 1.001, L.ShimmerFrames) == 1
	check(cycle and monotone, "the frames step through in order and wrap at the end of each pass")
	local stillSeq = BloomTrail.stillColour(mint, WheelData.Trail.Gold, leaf)
	local mid = stillSeq.Keypoints[2].Value
	local gold = WheelData.Trail.Gold
	check(#stillSeq.Keypoints == 3 and near(mid.R, gold.R, 1e-4) and near(mid.G, gold.G, 1e-4) and near(mid.B, gold.B, 1e-4),
		"Reduced's still ribbon is the original band: mint, gold, leaf")
end

do
	local function walk(emitter, studsPerSecond, seconds, fps, energy, mode, roll, t0)
		local petals, blooms, firstBloomAt = 0, 0, nil
		local perSecond, worstSecond = {}, 0
		local now = 0
		for i = 1, math.floor(seconds * fps + 0.5) do
			now = (t0 or 0) + i / fps
			local p, b = BloomTrail.emit(emitter, studsPerSecond / fps, now, energy, mode, roll)
			petals += p
			if b then
				blooms += 1
				firstBloomAt = firstBloomAt or now
			end
			local s = math.floor(now - 1e-9)
			perSecond[s] = (perSecond[s] or 0) + p
			worstSecond = math.max(worstSecond, perSecond[s])
		end
		return petals, blooms, worstSecond
	end
	local idle = BloomTrail.newEmitter(0.5)
	local p0, b0 = 0, 0
	for i = 1, 600 do
		local p, b = BloomTrail.emit(idle, 0, i / 60, 0, "Full", 0.5)
		p0 += p
		b0 += if b then 1 else 0
	end
	for _, bad in ipairs({ -1, 0 / 0, math.huge }) do
		local p, b = BloomTrail.emit(idle, bad, 20, 0, "Full", 0.5)
		p0 += p
		b0 += if b then 1 else 0
	end
	check(p0 == 0 and b0 == 0, "no road, no flowers: 10 s standing still (and a negative, NaN or endless step) lays nothing")

	local petals, blooms = walk(BloomTrail.newEmitter(0.5), 16, 10, 60, 0, "Full", 0.5)
	check(petals >= 60 and petals <= 63, "160 studs at a walk: a petal every " .. L.PetalStuds .. " studs", petals)
	check(blooms >= 8 and blooms <= 10, "and a flower every " .. L.BloomStuds .. " or so", blooms)
	local slow = { walk(BloomTrail.newEmitter(0.5), 16, 20, 30, 0, "Full", 0.5) }
	check(slow[1] >= 120 and slow[1] <= 126, "the same at 30 fps: laid by road, not by frames", slow[1])

	local sp, sb, worst = walk(BloomTrail.newEmitter(0.5), 150, 10, 60, 1, "Full", 0.5)
	check(worst <= L.PetalMaxPerSecond and sp <= L.PetalMaxPerSecond * 10 and sp >= 70,
		"a 150-stud/s sprint is capped at " .. L.PetalMaxPerSecond .. " petals a second", sp .. " (worst second " .. worst .. ")")
	check(sb <= math.floor(10 / L.BloomMinSeconds) + 1 and sb >= 8,
		"and a flower at most every " .. L.BloomMinSeconds .. " s", sb)
	local after = BloomTrail.newEmitter(0.5)
	walk(after, 150, 10, 60, 1, "Full", 0.5)
	local burst = walk(after, 16, 1, 60, 0, "Full", 0.5, 10)
	check(burst <= math.ceil(16 / L.PetalStuds) + 1, "and what the cap held back is dropped, not let out in a burst later", burst)
	local rp, rb = walk(BloomTrail.newEmitter(0.5), 30, 10, 60, 0.2, "Reduced", 0.5)
	local op, ob = walk(BloomTrail.newEmitter(0.5), 30, 10, 60, 0.2, "Off", 0.5)
	check(rp + rb + op + ob == 0, "Reduced and Off lay nothing at any speed")

	check(BloomTrail.petalFade(0) == 0.2 and BloomTrail.petalFade(0.3) == 0.2 and BloomTrail.petalFade(1) == 1
			and BloomTrail.petalFade(2) == 1 and BloomTrail.petalFade(0.7) > 0.2 and BloomTrail.petalFade(0.7) < 1,
		"a petal holds, then thins away to nothing by the end of its life")
	local open0, shed0, over0 = BloomTrail.bloomPhase(0)
	local openA, shedA = BloomTrail.bloomPhase(L.BloomOpen)
	local _, shedB = BloomTrail.bloomPhase(L.BloomOpen + L.BloomHold + 0.01)
	local _, _, overEnd = BloomTrail.bloomPhase(BloomTrail.bloomSeconds())
	check(open0 == 0 and shed0 == 0 and not over0 and openA == 1 and shedA == 0 and shedB > 0 and overEnd,
		string.format("a flower opens in %.2f s, holds %.2f s and sheds in %.2f s", L.BloomOpen, L.BloomHold, L.BloomShed))
	check(BloomTrail.bloomSeconds() <= 1.5 and L.PetalLife[2] <= 1.5,
		"nothing lasts longer than a second and a half: no decoration is left on the ground")
	local drift, fall = BloomTrail.petalTravel(L.PetalLife[2])
	local lowestPetal = 3 + L.RibbonHeight - 0.25 - fall + L.PetalLift[1] * drift
	check(lowestPetal >= 0.2 and 3 + L.RibbonHeight + 0.25 + L.PetalLift[2] * drift <= 3,
		"a petal falls no lower than the ankle and rises no higher than the waist", string.format("%.2f", lowestPetal))
	local tallest = L.BloomFloorHeight + L.BloomRise + L.BloomPetalSize.Z * math.sin(L.BloomClosedTilt) * 1.1
	check(L.BloomFloorHeight >= 0.3 and tallest <= 1.4,
		"a flower stands at the ankle and is never knee-high", string.format("top %.2f", tallest))
end

--==============================================================================
-- 2. TRAILFX, RUN FOR REAL
--==============================================================================
say("-- 2. TrailFX for real --")
local trailSource = sourceOf(Scripts, "TrailFX")
check(trailSource ~= "", "TrailFX is in StarterPlayerScripts")

local fakeNow = 1000
local fakeOs = setmetatable({
	clock = function()
		return fakeNow
	end,
}, { __index = os })

-- Plain listener lists: called at once, handed the same tables.
local connects = 0
local function signal()
	local fns = {}
	local sig = {}
	function sig:Connect(fn)
		connects += 1
		table.insert(fns, fn)
		local handle = { Connected = true }
		function handle:Disconnect()
			self.Connected = false
			local at = table.find(fns, fn)
			if at then
				table.remove(fns, at)
			end
		end
		return handle
	end
	function sig.fire(...)
		for _, fn in ipairs(table.clone(fns)) do
			fn(...)
		end
	end
	function sig.listeners()
		return #fns
	end
	return sig
end

local function standIn(name, userId)
	local attrs = {}
	local watched = {}
	local p = { Name = name, UserId = userId, Character = nil }
	p.CharacterAdded = signal()
	p.CharacterRemoving = signal()
	function p:GetAttribute(key)
		return attrs[key]
	end
	function p:GetAttributeChangedSignal(key)
		local s = watched[key]
		if not s then
			s = signal()
			watched[key] = s
		end
		return s
	end
	function p.set(key, value)
		attrs[key] = value
		local s = watched[key]
		if s then
			s.fire()
		end
	end
	return p
end

-- A floor high above the map, and bodies standing on it (root 3 studs up).
local FLOOR_Y = 6000
local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.CanCollide = true
floor.Size = Vector3.new(2048, 1, 2048)
floor.CFrame = CFrame.new(0, FLOOR_Y - 0.5, 0)
floor.Parent = scratch

local function body(name, x, z)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = false
	root.Transparency = 1
	root.CFrame = CFrame.new(x, FLOOR_Y + 3, z)
	root.Parent = model
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = root
	model.Parent = scratch
	return model, root, humanoid
end

local function load(me, players, reducedAtStart)
	local hb = signal()
	local motion = signal()
	local added, removing = signal(), signal()
	local list = table.clone(players)
	local reduced = { on = reducedAtStart == true }
	local playersStandIn = {
		LocalPlayer = me,
		GetPlayers = function()
			return table.clone(list)
		end,
		PlayerAdded = added,
		PlayerRemoving = removing,
	}
	local stand = {}
	function stand:GetService(name)
		if name == "Players" then
			return playersStandIn
		elseif name == "RunService" then
			return { Heartbeat = hb }
		elseif name == "GuiService" then
			return {
				GetPropertyChangedSignal = function(_, property)
					assert(property == "ReducedMotionEnabled", "TrailFX asked GuiService for " .. tostring(property))
					return motion
				end,
			}
		end
		return game:GetService(name)
	end
	local statusText = {
		reducedMotion = function()
			return reduced.on or me:GetAttribute(QUALITY) == "Off"
		end,
	}
	local chunk, cerr = loadstring(trailSource
		.. "\nreturn { tracked = tracked, folder = function() return folder end, mode = function() return mode end }",
		"=TrailFX")
	assert(chunk, tostring(cerr))
	setfenv(chunk, setmetatable({
		game = stand,
		os = fakeOs,
		require = function(target)
			if typeof(target) == "Instance" and target.Name == "StatusText" then
				return statusText
			end
			return require(target)
		end,
	}, { __index = getfenv(1) }))
	local before = connects
	local fx = chunk()
	local c = {
		fx = fx,
		hb = hb,
		motion = motion,
		list = list,
		added = added,
		removing = removing,
		reduced = reduced,
		connectsAtLoad = connects - before,
	}
	table.insert(copies, c)
	return c
end

local function tick(c, dt, move)
	fakeNow += dt
	if move then
		move(dt)
	end
	c.hb.fire(dt)
end
local function run(c, seconds, fps, move, each)
	local dt = 1 / fps
	for _ = 1, math.floor(seconds * fps + 0.5) do
		tick(c, dt, move)
		if each then
			each()
		end
	end
end
-- Straight ahead at `speed`, turning `turn` radians a second (positive: left).
local function stride(root, speed, turn)
	return function(dt)
		local cf = root.CFrame
		if turn then
			cf = cf * CFrame.Angles(0, turn * dt, 0)
		end
		root.CFrame = cf + cf.LookVector * speed * dt
	end
end
local function ribbonsOn(root)
	local trails, atts, on = 0, 0, 0
	for _, d in ipairs(root:GetChildren()) do
		if d:IsA("Trail") then
			trails += 1
			if d.Enabled then
				on += 1
			end
		elseif d:IsA("Attachment") and string.find(d.Name, "^Bloomrunner") then
			atts += 1
		end
	end
	return trails, atts, on
end
local function poolOf(c, p)
	local f = c.fx.folder()
	local home = f and f:FindFirstChild("Bloomrunner_" .. p.Name)
	if not home then
		return 0, 0, nil
	end
	local parts, shown = 0, 0
	for _, d in ipairs(home:GetChildren()) do
		if d:IsA("BasePart") then
			parts += 1
			if d.Transparency < 1 then
				shown += 1
			end
		end
	end
	return parts, shown, home
end
local function liveOf(entry)
	local petals, blooms = 0, 0
	for _, x in ipairs(entry.petals) do
		if x.live then
			petals += 1
		end
	end
	for _, b in ipairs(entry.blooms) do
		if b.live then
			blooms += 1
		end
	end
	return petals, blooms
end

local me = standIn("SpecBloomRunner", -7101)
local meModel, meRoot, meHum = body(me.Name, 0, 0)
me.Character = meModel
me.set(TRAIL_ATTR, TRAIL_ID)
local A = load(me, { me })
local entry = A.fx.tracked[me]
check(entry ~= nil and A.fx.mode() == "Full", "wearing it when the script starts: drawn on Full at once")
say(string.format("  .. a Humanoid in Edit reports state %s", tostring(meHum:GetState())))
do
	local trails, atts, on = ribbonsOn(meRoot)
	local parts, shown = poolOf(A, me)
	check(trails == 2 and atts == 4 and on == 0, "Full: two Trails and four attachments on the root, off while standing",
		trails .. "/" .. atts .. "/" .. on)
	check(parts == 24 and shown == 0, "and one pool of 24 parts, all hidden", parts .. "/" .. shown)
	local loose = 0
	local meshes = 0
	for _, d in ipairs(A.fx.folder():GetDescendants()) do
		if d:IsA("BasePart") and (d.CanCollide or d.CanQuery or d.CanTouch or not d.Anchored or d.CastShadow) then
			loose += 1
		elseif d:IsA("SpecialMesh") then
			meshes += 1
		end
	end
	check(loose == 0 and meshes == 24, "every pool part is anchored, casts no shadow, and blocks, touches and is found by nothing")
	local lengthsOk = near(entry.ribbons[1].trail.MaxLength, L.RibbonMaxLength.Full, 1e-4)
		and near(entry.ribbons[2].trail.Lifetime, L.RibbonSeconds.Full, 1e-4)
	check(lengthsOk, string.format("Full ribbons last %.2f s and never pass %d studs", L.RibbonSeconds.Full,
		L.RibbonMaxLength.Full))
	check(A.hb.listeners() == 1, "one Heartbeat for every wearer")
end

-- Standing, pushing into a wall, creeping.
do
	local laid = entry.laid
	run(A, 2, 60)
	local _, _, on = ribbonsOn(meRoot)
	check(on == 0 and entry.laid == laid and entry.live == 0, "standing still for 2 s: nothing drawn, nothing laid")
	meRoot.AssemblyLinearVelocity = Vector3.new(0, 0, -24)
	run(A, 3, 60)
	_, _, on = ribbonsOn(meRoot)
	check(on == 0 and entry.laid == laid and entry.live == 0,
		"held in place while its velocity says 24 -- a wall, a mill's belt -- for 3 s: nothing")
	meRoot.AssemblyLinearVelocity = Vector3.zero
	run(A, 5, 60, stride(meRoot, 1))
	_, _, on = ribbonsOn(meRoot)
	check(on == 0 and entry.laid == laid, "creeping at 1 stud/s, under the " .. FX.MinGroundSpeed .. " that counts as running: nothing")
end

-- Starting, running, the weave, the shimmer, the budget.
do
	local added = 0
	local watcher = Workspace.DescendantAdded:Connect(function()
		added += 1
	end)
	local connectsBefore = connects
	local widths = {}
	local growing = true
	run(A, 0.4, 60, stride(meRoot, 16), function()
		local r = entry.ribbons[1]
		local w = r.high.Position.Y - r.low.Position.Y
		if #widths > 0 and #widths < 10 then
			growing = growing and w >= widths[#widths] - 1e-6
		end
		table.insert(widths, w)
	end)
	check(widths[1] > 0 and widths[1] < 0.2 and growing and near(widths[#widths], 2 * L.RibbonHalf, 0.02),
		"starting: the ribbons grow in from nothing over the first frames, not at once",
		string.format("%.3f -> %.3f", widths[1], widths[#widths]))

	local mintX, crossing, bandOk, signFlips = {}, true, true, 0
	local colours, lastColour = 0, entry.ribbons[1].trail.Color
	local maxPetals, maxBlooms, heightsOk, behindOk = 0, 0, true, true
	local bloomBorn = {}
	local blooms = 0
	local flowerOk = true
	local laid0 = entry.laid
	run(A, 10, 60, stride(meRoot, 16), function()
		local m, g = entry.ribbons[1], entry.ribbons[2]
		local x = m.low.Position.X
		if #mintX > 0 and (x > 0) ~= (mintX[#mintX] > 0) then
			signFlips += 1
		end
		table.insert(mintX, x)
		crossing = crossing and near(m.low.Position.X, -g.low.Position.X, 0.02)
		for _, r in ipairs({ m, g }) do
			bandOk = bandOk and r.low.Position.Y >= -2.7 and r.high.Position.Y <= 0 and r.low.Position.Z > 0.4
		end
		if m.trail.Color ~= lastColour then
			colours += 1
			lastColour = m.trail.Color
		end
		local p, b = liveOf(entry)
		maxPetals = math.max(maxPetals, p)
		maxBlooms = math.max(maxBlooms, b)
		local look = meRoot.CFrame.LookVector
		for _, petal in ipairs(entry.petals) do
			if petal.live then
				local pos = petal.part.Position
				heightsOk = heightsOk and pos.Y - FLOOR_Y >= 0.15 and pos.Y - FLOOR_Y <= 3.05
				behindOk = behindOk and (pos - meRoot.Position):Dot(look) < 0.6
			end
		end
		for i, bloom in ipairs(entry.blooms) do
			if bloom.live and bloomBorn[i] ~= bloom.born then
				bloomBorn[i] = bloom.born
				blooms += 1
				local spot = bloom.at.Position
				flowerOk = flowerOk and spot.Y - FLOOR_Y >= 0.3 and spot.Y - FLOOR_Y <= 0.8
					and (spot - meRoot.Position):Dot(look) <= -2
			end
		end
	end)
	watcher:Disconnect()
	local laid = entry.laid - laid0
	local spread = 0
	for _, x in ipairs(mintX) do
		spread = math.max(spread, math.abs(x))
	end
	check(spread >= L.WeaveAmplitude * 0.9 and spread <= L.WeaveAmplitude * 1.05 and crossing,
		"running: mint and gold weave round each other, mirror images", string.format("%.2f", spread))
	check(signFlips >= 32 and signFlips <= 38, "one weave every " .. L.WeaveStuds .. " studs of road (160 studs, ~35 crossings)",
		signFlips)
	check(bandOk, "every frame of it between ankle and waist, behind the body")
	check(colours >= 120, string.format("the light travels along the mint ribbon, the colour stepping %.0f times a second",
		L.ShimmerFrames / L.ShimmerSeconds), colours)
	check(laid >= 56 and laid <= 64, "petals laid by road: " .. laid .. " over 160 studs", laid)
	check(blooms >= 6 and blooms <= 12 and flowerOk,
		"flowers by road: " .. blooms .. ", each opening on the floor 3 studs behind, at the ankle", blooms)
	check(maxPetals <= B.Full.Petals and maxBlooms <= B.Full.Blooms,
		string.format("never more than %d petals and %d flowers in the air (saw %d and %d)", B.Full.Petals, B.Full.Blooms,
			maxPetals, maxBlooms))
	check(heightsOk and behindOk, "every petal between ankle and waist, behind the runner")
	check(added == 0 and connects == connectsBefore,
		"10 s of running made no Instance and connected nothing", added .. " added, " .. (connects - connectsBefore) .. " connected")
end

-- A turn, both ways, and a snap.
do
	local outside, inside = 0, 0
	run(A, 1, 60, stride(meRoot, 16, 3), function()
		outside = entry.swing
	end)
	run(A, 1, 60, stride(meRoot, 16, -3), function()
		inside = entry.swing
	end)
	check(near(outside, BloomTrail.swing(3), 0.02) and near(inside, BloomTrail.swing(-3), 0.02),
		"turning swings the ribbons to the outside of the turn, either way",
		string.format("%.3f / %.3f", outside, inside))
	local most = 0
	tick(A, 1 / 60, function()
		meRoot.CFrame = meRoot.CFrame * CFrame.Angles(0, math.pi, 0)
	end)
	run(A, 0.3, 60, stride(meRoot, 16), function()
		most = math.max(most, math.abs(entry.swing))
	end)
	run(A, 1, 60, stride(meRoot, 16))
	check(most <= L.TurnSwingMax + 1e-6 and math.abs(entry.swing) < 0.02,
		"a snap about-face swings them no more than " .. L.TurnSwingMax .. " studs, and they settle again",
		string.format("%.3f, then %.3f", most, entry.swing))
end

-- A sprint: modestly livelier, and the caps hold.
do
	local maxPetals, maxBlooms, widest = 0, 0, 0
	local laid0 = entry.laid
	run(A, 4, 60, stride(meRoot, 150), function()
		local p, b = liveOf(entry)
		maxPetals = math.max(maxPetals, p)
		maxBlooms = math.max(maxBlooms, b)
		local r = entry.ribbons[1]
		widest = math.max(widest, r.high.Position.Y - r.low.Position.Y)
	end)
	local laid = entry.laid - laid0
	check(entry.energy > 0.9 and widest <= 2 * L.RibbonHalf * (1 + L.RibbonHalfEnergy) + 1e-3,
		string.format("150 studs/s: full energy, the ribbons %.2f wide at most", widest))
	check(laid <= 4 * L.PetalMaxPerSecond and maxPetals <= B.Full.Petals and maxBlooms <= B.Full.Blooms,
		string.format("and still capped: %d petals in 4 s, at most %d and %d in the air", laid, maxPetals, maxBlooms))
end

-- Stopping.
do
	local laid = entry.laid
	local offAfter = nil
	local narrowing = true
	local lastWidth = math.huge
	local t = 0
	run(A, 2, 60, nil, function()
		t += 1 / 60
		local r = entry.ribbons[1]
		if r.trail.Enabled then
			local w = r.high.Position.Y - r.low.Position.Y
			narrowing = narrowing and w <= lastWidth + 1e-6
			lastWidth = w
		elseif offAfter == nil then
			offAfter = t
		end
	end)
	local parts, shown = poolOf(A, me)
	check(offAfter ~= nil and offAfter <= 0.8 and narrowing,
		"stopping, even from a sprint: the ribbons narrow away and are off within 0.8 s", offAfter)
	check(entry.laid == laid and entry.live == 0 and shown == 0 and parts == 24,
		"nothing new laid, and every petal and flower already in the air has faded back into the pool")
end

-- Teleports.
do
	run(A, 1, 60, stride(meRoot, 16))
	local before = entry.live
	local _, _, onBefore = ribbonsOn(meRoot)
	tick(A, 1 / 60, function()
		meRoot.CFrame = meRoot.CFrame + Vector3.new(300, 0, 0)
	end)
	local _, _, on = ribbonsOn(meRoot)
	local _, shown = poolOf(A, me)
	check(before > 0 and onBefore == 2 and on == 0 and entry.live == 0 and shown == 0 and entry.presence == 0,
		"a 300-stud jump while running: that frame the ribbons are cleared and off, the petals and flowers gone")
	check(entry.speed < 16, "and the jump is not counted as speed", string.format("%.1f", entry.speed))
	run(A, 0.3, 60, stride(meRoot, 16))
	_, _, on = ribbonsOn(meRoot)
	check(on == 2, "drawn again from the new spot as they run on")

	-- Play, 2026-10-04: a server putting a standing body back 20 studs drew a
	-- ribbon across the gap and laid a flower under the old 24-stud rule.
	run(A, 2, 60)
	local laid = entry.laid
	local _, _, onStill = ribbonsOn(meRoot)
	tick(A, 1 / 60, function()
		meRoot.CFrame = meRoot.CFrame + Vector3.new(0, 0, 15)
	end)
	local hopOn = select(3, ribbonsOn(meRoot))
	run(A, 1, 60)
	local laterOn = select(3, ribbonsOn(meRoot))
	check(onStill == 0 and hopOn == 0 and laterOn == 0 and entry.laid == laid and entry.live == 0 and entry.speed < 2,
		"a 15-stud hop in one frame (a body put back): a teleport too -- no ribbon across it, nothing laid",
		string.format("%d/%d/%d, laid %d, speed %.1f", onStill, hopOn, laterOn, entry.laid - laid, entry.speed))
	local most = 0
	run(A, 1, 60, stride(meRoot, GameConfig.Speed.MaxWalkSpeed), function()
		most = math.max(most, select(3, ribbonsOn(meRoot)))
	end)
	check(most == 2 and entry.live > 0, "while a real sprint at the " .. GameConfig.Speed.MaxWalkSpeed
		.. "-stud/s cap is never mistaken for one")
end

-- The course, ragdoll, seat, death.
do
	run(A, 0.5, 60, stride(meRoot, 16))
	me.set(COURSE, true)
	tick(A, 1 / 60, stride(meRoot, 16))
	local _, _, on = ribbonsOn(meRoot)
	local laid = entry.laid
	check(on == 0 and entry.live == 0, "onto the Floating Garden: off and cleared that frame")
	run(A, 1, 60, stride(meRoot, 16))
	_, _, on = ribbonsOn(meRoot)
	check(on == 0 and entry.laid == laid, "and nothing drawn or laid while they run the course")
	me.set(COURSE, nil)
	run(A, 0.3, 60, stride(meRoot, 16))
	_, _, on = ribbonsOn(meRoot)
	check(on == 2, "off the course: drawn again")

	for _, case in ipairs({
		{ "ragdolled (PlatformStand)", function(v) meHum.PlatformStand = v end },
		{ "seated", function(v) meHum.Sit = v end },
		{ "dead", function(v) meHum.Health = if v then 0 else 100 end },
	}) do
		run(A, 0.4, 60, stride(meRoot, 16))
		case[2](true)
		tick(A, 1 / 60, stride(meRoot, 16))
		local _, _, cut = ribbonsOn(meRoot)
		local laidNow = entry.laid
		run(A, 1, 60, stride(meRoot, 16))
		local _, _, still = ribbonsOn(meRoot)
		check(cut == 0 and still == 0 and entry.laid == laidNow,
			case[1] .. " while moving: off that frame, not narrowed away, and nothing laid")
		case[2](false)
	end
	run(A, 0.3, 60, stride(meRoot, 16))
	local _, _, on2 = ribbonsOn(meRoot)
	check(on2 == 2, "up again: drawn again")
end

-- Another wearer: distance, unequip, re-equip, leaving, a vanishing body.
do
	local far = standIn("SpecBloomFar", -7102)
	local farModel, farRoot = body(far.Name, 400, 0)
	farRoot.CFrame = meRoot.CFrame + Vector3.new(400, 0, 0)
	far.Character = farModel
	far.set(TRAIL_ATTR, TRAIL_ID)
	table.insert(A.list, far)
	A.added.fire(far)
	local farEntry = A.fx.tracked[far]
	check(farEntry ~= nil, "a second wearer joining is tracked with a pool of its own")
	local _, _, home = poolOf(A, far)
	check(home ~= nil and home ~= select(3, poolOf(A, me)), "each wearer has their own folder of 24")
	run(A, 2, 60, function(dt)
		stride(meRoot, 16)(dt)
		stride(farRoot, 16)(dt)
	end)
	local _, _, onFar = ribbonsOn(farRoot)
	check(onFar == 0 and farEntry.laid == 0, "one running " .. math.floor((farRoot.Position - meRoot.Position).Magnitude)
		.. " studs away is not drawn or worked out (past " .. FX.RemoteMaxStuds .. ")")
	farRoot.CFrame = meRoot.CFrame + Vector3.new(30, 0, 0)
	tick(A, 1 / 60)
	run(A, 2, 60, function(dt)
		stride(meRoot, 16)(dt)
		stride(farRoot, 16)(dt)
	end)
	_, _, onFar = ribbonsOn(farRoot)
	check(onFar == 2 and farEntry.laid > 0, "within range: drawn")
	local nearLive = farEntry.live
	for _ = 1, 40 do
		-- 3 studs a frame (180 studs/s): fast, but no teleport, so this is the
		-- distance rule at work and not TELEPORTS.
		tick(A, 1 / 60, function()
			farRoot.CFrame = farRoot.CFrame + Vector3.new(3, 0, 0)
		end)
	end
	local _, farShown = poolOf(A, far)
	_, _, onFar = ribbonsOn(farRoot)
	check(nearLive > 0 and farEntry.live == 0 and farShown == 0 and onFar == 0,
		"and out of range again: off, and what it had in the air put away")

	far.set(TRAIL_ATTR, nil)
	local trails, atts = ribbonsOn(farRoot)
	local farParts, _, farHome = poolOf(A, far)
	check(A.fx.tracked[far] == nil and trails == 0 and atts == 0 and farParts == 0 and farHome == nil,
		"taking it off: every Trail, attachment and part of it destroyed")
	far.set(TRAIL_ATTR, "somethingElse")
	check(A.fx.tracked[far] == nil, "a trail that is not the Bloomrunner draws nothing here")
	far.set(TRAIL_ATTR, TRAIL_ID)
	trails, atts = ribbonsOn(farRoot)
	farParts = poolOf(A, far)
	check(A.fx.tracked[far] ~= nil and trails == 2 and atts == 4 and farParts == 24, "putting it back on: built again")

	A.removing.fire(far)
	trails = ribbonsOn(farRoot)
	check(A.fx.tracked[far] == nil and trails == 0 and select(1, poolOf(A, far)) == 0, "leaving: all of it gone")
	A.added.fire(far)
	local again = A.fx.tracked[far]
	farModel:Destroy()
	tick(A, 1 / 60)
	check(again ~= nil and A.fx.tracked[far] == nil and select(1, poolOf(A, far)) == 0,
		"a body that vanishes on its own: noticed the next frame, its pool destroyed")
	table.remove(A.list, table.find(A.list, far))
	local plain = standIn("SpecBloomPlain", -7103)
	local plainModel, plainRoot = body(plain.Name, 10, 10)
	plain.Character = plainModel
	table.insert(A.list, plain)
	A.added.fire(plain)
	trails = ribbonsOn(plainRoot)
	check(A.fx.tracked[plain] == nil and trails == 0 and select(1, poolOf(A, plain)) == 0,
		"a player not wearing it costs nothing: no Trail, no pool")
end

-- Respawn.
do
	local oldRoot = meRoot
	me.CharacterRemoving.fire(meModel)
	local trails, atts = ribbonsOn(oldRoot)
	check(A.fx.tracked[me] == nil and trails == 0 and atts == 0 and select(1, poolOf(A, me)) == 0,
		"the body going: everything on it destroyed")
	meModel, meRoot, meHum = body(me.Name, -500, -500)
	me.Character = meModel
	me.CharacterAdded.fire(meModel)
	entry = A.fx.tracked[me]
	trails, atts = ribbonsOn(meRoot)
	check(entry ~= nil and trails == 2 and atts == 4 and select(1, poolOf(A, me)) == 24,
		"the new body: built again, once")
	tick(A, 1 / 60)
	run(A, 0.5, 60, stride(meRoot, 16))
	local _, _, on = ribbonsOn(meRoot)
	check(on == 2 and entry.speed < 20, "and drawn from where it stands: no streak from the old body", string.format("%.1f", entry.speed))
end

-- Reduced, reduced motion, Off, and back.
do
	me.set(QUALITY, "Reduced")
	entry = A.fx.tracked[me]
	local trails, atts = ribbonsOn(meRoot)
	check(A.fx.mode() == "Reduced" and trails == 1 and atts == 2 and select(1, poolOf(A, me)) == 0,
		"REDUCED FX: rebuilt as one Trail and no pool")
	local r = entry.ribbons[1]
	check(near(r.trail.Lifetime, L.RibbonSeconds.Reduced, 1e-4) and near(r.trail.MaxLength, L.RibbonMaxLength.Reduced, 1e-4)
			and L.RibbonSeconds.Reduced < L.RibbonSeconds.Full and L.RibbonMaxLength.Reduced < L.RibbonMaxLength.Full,
		string.format("a shorter ribbon: %.2f s and %d studs", L.RibbonSeconds.Reduced, L.RibbonMaxLength.Reduced))
	local colour = r.trail.Color
	local stillX, sameColour = true, true
	run(A, 3, 60, stride(meRoot, 30, 1), function()
		stillX = stillX and r.low.Position.X == 0 and r.high.Position.X == 0
		sameColour = sameColour and r.trail.Color == colour
	end)
	local _, _, on = ribbonsOn(meRoot)
	check(on == 1 and stillX and sameColour and entry.laid == 0,
		"running and turning on Reduced: drawn, with no weave, no swing, no shimmer, no petals, no flowers")

	me.set(QUALITY, "Off")
	trails, atts = ribbonsOn(meRoot)
	check(A.fx.mode() == "Off" and next(A.fx.tracked) == nil and trails == 0 and atts == 0,
		"FX OFF: everything destroyed")
	run(A, 1, 60, stride(meRoot, 16))
	trails = ribbonsOn(meRoot)
	check(trails == 0, "and nothing comes back while running")

	me.set(QUALITY, nil)
	entry = A.fx.tracked[me]
	trails, atts = ribbonsOn(meRoot)
	check(A.fx.mode() == "Full" and entry ~= nil and trails == 2 and atts == 4 and select(1, poolOf(A, me)) == 24,
		"back to Full: built once again")

	A.reduced.on = true
	A.motion.fire()
	entry = A.fx.tracked[me]
	trails = ribbonsOn(meRoot)
	check(A.fx.mode() == "Reduced" and trails == 1 and select(1, poolOf(A, me)) == 0,
		"Roblox's reduced motion switched on: what Reduced draws")
	A.reduced.on = false
	A.motion.fire()
	entry = A.fx.tracked[me]
	trails = ribbonsOn(meRoot)
	check(A.fx.mode() == "Full" and trails == 2, "and off again: Full")

	for _ = 1, 5 do
		me.set(QUALITY, "Reduced")
		me.set(QUALITY, "Off")
		me.set(QUALITY, "Full")
	end
	local homes = 0
	for _, f in ipairs(A.fx.folder():GetChildren()) do
		if f:IsA("Folder") then
			homes += 1
		end
	end
	trails, atts = ribbonsOn(meRoot)
	check(trails == 2 and atts == 4 and homes == 1 and select(1, poolOf(A, me)) == 24,
		"fifteen switches later: one set on the body and one pool -- nothing left behind", homes .. " folders")
	check(A.hb.listeners() == 1, "and still one Heartbeat")
end

-- FX Off from the start, and reduced motion from the start.
do
	local quiet = standIn("SpecBloomQuiet", -7104)
	local qModel, qRoot = body(quiet.Name, 40, -40)
	quiet.Character = qModel
	quiet.set(QUALITY, "Off")
	quiet.set(TRAIL_ATTR, TRAIL_ID)
	local C = load(quiet, { quiet })
	run(C, 1, 60, stride(qRoot, 16))
	local trails = ribbonsOn(qRoot)
	check(C.fx.mode() == "Off" and next(C.fx.tracked) == nil and C.fx.folder() == nil and trails == 0,
		"FX OFF when the script starts: builds nothing at all -- not even its folder")
	local calm = standIn("SpecBloomCalm", -7105)
	local cModel, cRoot = body(calm.Name, -40, 40)
	calm.Character = cModel
	calm.set(TRAIL_ATTR, TRAIL_ID)
	local D = load(calm, { calm }, true)
	local t2, a2 = ribbonsOn(cRoot)
	check(D.fx.mode() == "Reduced" and t2 == 1 and a2 == 2 and D.fx.folder() == nil,
		"reduced motion when the script starts: one still ribbon, no pool")
end

--==============================================================================
-- 3. THE SOURCE
--==============================================================================
say("-- 3. the source --")
do
	local src = code(trailSource)
	local pure = code(sourceOf(Shared, "BloomTrail"))
	check(count(src, "RunService.Heartbeat:Connect(") == 1 and not src:find("RenderStepped", 1, true)
			and not src:find("BindToRenderStep", 1, true) and not src:find("Stepped", 1, true)
			and not src:find("while ", 1, true) and not src:find("task.wait", 1, true)
			and not src:find("task.delay", 1, true),
		"one Heartbeat and no other loop")
	local from = string.find(src, "local function hideAir", 1, true)
	local to = string.find(src, "local function watch", 1, true)
	local frame = if from and to then string.sub(src, from, to) else ""
	check(frame ~= "" and not frame:find("Instance.new(", 1, true) and count(frame, ":Connect(") == 1
			and not frame:find("Clone(", 1, true),
		"everything the frame runs makes no Instance and connects nothing (built only in build/newRibbon/poolPart)")
	check(not src:find("Tween", 1, true) and not pure:find("Tween", 1, true), "no tweens")
	check(not src:find("rbxassetid", 1, true) and not src:find("rbxasset://", 1, true) and not src:find("Texture", 1, true)
			and not pure:find("rbxasset", 1, true),
		"no texture of any kind, so no invented id: plain ribbons and pooled ellipsoids")
	check(not src:find("Lighting", 1, true) and not pure:find("Lighting", 1, true), "Lighting is not touched")
	check(not src:find("SetAttribute", 1, true) and not src:find("FireServer", 1, true)
			and not src:find("InvokeServer", 1, true),
		"it writes no attribute and sends nothing: ownership, wearing and saves are the server's")
	check(src:find("if teleported then\n\t\t\t\tclearAir(entry)", 1, true) ~= nil and count(src, "r.trail:Clear()") == 1,
		"a teleport clears the ribbons, not just pauses them")
	check(src:find("StatusText.reducedMotion()", 1, true) ~= nil
			and src:find("GetPropertyChangedSignal(\"ReducedMotionEnabled\")", 1, true) ~= nil,
		"it follows Roblox's reduced motion as well as REDUCED FX")
	check(not pure:find("Instance", 1, true) and not pure:find("game", 1, true),
		"BloomTrail is pure arithmetic: no instance, no service")
end

end)

for _, c in ipairs(copies) do
	for who in pairs(c.fx.tracked) do
		c.fx.tracked[who] = nil
	end
	local f = c.fx.folder()
	if f then
		f:Destroy()
	end
end
scratch:Destroy()
for _, stray in ipairs(Workspace:GetChildren()) do
	if stray.Name == "SeedBloomTrail" then
		stray:Destroy()
	end
end
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nBloomTrailSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
