--!nocheck
--==============================================================================
-- Steal a Seed :: ObbySignSpec (2026-10-13, the owner's item 8)
--
-- The "OBBY" sign over the Floating Garden's entrance arch (ObbyData.Sign,
-- ObbySign.client, FloatingSign.clampScale), in Edit, with no Play:
--
--   1. THE WORDS: "OBBY" over "Floating Garden", in the old pill's sky-blue rim
--      and gold pennant, each whole in its box at its full height.
--   2. OVER THE ARCH, NEVER ON THE START PROMPT: the bottom edge over the arch's
--      vine crown (ObbyCourse's own numbers), centred over the entrance, and it
--      stays there whatever size the camera makes it.
--   3. THE SIZE THAT READS: the header never under MinHeaderUnits far off, never
--      over MaxHeaderShare of the screen up close, its built studs between;
--      the Mist sign's own rule, the same numbers in, the same answer out.
--   4. EVERYBODY SEES IT: drawn out past the field's far side, on a local
--      anchor (never streamed out), behind walls, shown always while the obby
--      is on, its size written after the camera and only when it moves.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistStatus = require(Shared:WaitForChild("EnchantedMistStatus"))

local SIGN = ObbyData.Sign

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
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	if not found then
		return ""
	end
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

local ok, err = pcall(function()

--==============================================================================
say("-- 1. the words --")
--==============================================================================
check(SIGN.Header == "OBBY" and SIGN.Sub == "Floating Garden",
	"\"OBBY\" with \"Floating Garden\" under it (the owner's option 1)")
check(SIGN.HeaderColour == GameConfig.Rail.IndexEdge and SIGN.SubColour == Color3.fromRGB(255, 206, 84),
	"OBBY in the old pill's sky-blue rim (Rail.IndexEdge), Floating Garden in its gold pennant")
local function ratio(text)
	local v = TextService:GetTextSize(text, 100, FloatingSign.Font, Vector2.new(100000, 1000))
	return v.X / v.Y
end
local headW, subW = ratio(SIGN.Header) * SIGN.Height, ratio(SIGN.Sub) * SIGN.SubHeight
check(headW <= SIGN.Width and subW <= SIGN.Width and FloatingSign.Font == Enum.Font.LuckiestGuy,
	string.format("both lines whole at their full height in LuckiestGuy: OBBY %.1f and Floating Garden %.1f of %d studs",
		headW, subW, SIGN.Width))

--==============================================================================
say("\n-- 2. over the arch, never on the Start prompt --")
--==============================================================================
local course = sourceOf(ServerScriptService:FindFirstChild("SeedGameServer"), "ObbyCourse")
-- The arch's five vines: 3.6 x 1.6, their middles at 11 + cos(a) * 2.2, each
-- turned by its own angle a, so a turned vine's upper corner stands highest:
-- the crown is the highest corner of the five (14.5 at a = 31 degrees, the
-- built arch's top as measured in Play, 2026-10-13).
local archBuilt = has(course, "Vector3.new(3.6, 1.6, 1.8),")
	and has(course, "local a = i / 2 * math.rad(62)")
	and has(course, "base * CFrame.new(math.sin(a) * 6.4, 11 + math.cos(a) * 2.2, 0) * CFrame.Angles(0, 0, -a),")
	and has(course, "size = Vector3.new(1.8, 11, 1.8), cframe = base * CFrame.new(side * 6, 5.5, 0)")
local crown = -math.huge
for i = -2, 2 do
	local a = i / 2 * math.rad(62)
	crown = math.max(crown, 11 + math.cos(a) * 2.2 + math.abs(math.sin(a)) * 3.6 / 2 + math.cos(a) * 1.6 / 2)
end
crown += GameConfig.Map.GroundY + ObbyData.Entrance.At.Y
local stepTop = ObbyData.Entrance.At.Y + 0.6
check(archBuilt and has(course, 'prompt.Name = "StartPrompt"') and has(course, "prompt.Parent = step")
		and SIGN.BottomAbove >= crown + 1.5 and SIGN.BottomAbove > stepTop + 10,
	string.format("its bottom edge (%.1f up) clears the arch's vine crown (%.1f) and stands far over the Start "
		.. "prompt's step (%.1f)", SIGN.BottomAbove, crown, stepTop))
local client = sourceOf(StarterPlayer:FindFirstChild("StarterPlayerScripts"), "ObbySign")
local tall = SIGN.Height + SIGN.SubHeight
local middleY = GameConfig.Map.GroundY + SIGN.BottomAbove + tall / 2
local steady = true
for _, want in ipairs({ 0.3, 0.6, 1, 1.8, 3.5 }) do
	local bottom = middleY + (want - 1) * tall / 2 - tall * want / 2
	if math.abs(bottom - SIGN.BottomAbove) > 1e-6 then
		steady = false
	end
end
check(steady and has(client, "local entrance = ObbyData.Entrance.At")
		and has(client, "Vector3.new(entrance.X, (GameConfig.Map :: any).GroundY + SIGN.BottomAbove + tall / 2, entrance.Z)")
		and has(client, "sign.gui.Size = UDim2.fromScale(SIGN.Width * want, tall * want)")
		and has(client, "sign.gui.StudsOffsetWorldSpace = Vector3.new(0, (want - 1) * tall / 2, 0)"),
	"centred over the entrance, and whatever size the camera makes it, its bottom edge stays put: it grows up, "
		.. "never down onto the arch")

--==============================================================================
say("\n-- 3. the size that reads --")
--==============================================================================
local VH, FOV = 716, 70
local function drawn(distance)
	local perStud = (VH / 2) / math.tan(math.rad(FOV / 2)) / distance
	return SIGN.Height * perStud * FloatingSign.clampScale(distance, SIGN.Height, VH, FOV, SIGN.MinHeaderUnits,
		SIGN.MaxHeaderShare)
end
local most = math.max(SIGN.MinHeaderUnits, SIGN.MaxHeaderShare * VH)
local outside, between = {}, false
for d = 4, 600, 4 do
	local h = drawn(d)
	if h < SIGN.MinHeaderUnits - 1e-6 or h > most + 1e-6 then
		table.insert(outside, string.format("%d: %.1f", d, h))
	end
	if math.abs(FloatingSign.clampScale(d, SIGN.Height, VH, FOV, SIGN.MinHeaderUnits, SIGN.MaxHeaderShare) - 1) < 1e-9 then
		between = true
	end
end
check(#outside == 0 and between and math.abs(drawn(250) - SIGN.MinHeaderUnits) < 1e-6 and math.abs(drawn(20) - most) < 1e-6,
	string.format("on a 716-px screen its header draws %d to %.0f units from 4 to 600 studs: held at %d from the hub "
		.. "(250), at most %.0f up close, its built studs between", SIGN.MinHeaderUnits, most, SIGN.MinHeaderUnits, most),
	table.concat(outside, "; "))
local M = EnchantedMistConfig.Sign
local same = true
for _, d in ipairs({ 3, 20, 60, 120, 250, 500 }) do
	for _, view in ipairs({ { 338, 70 }, { 716, 70 }, { 1080, 50 } }) do
		local a = EnchantedMistStatus.signScale(d, view[1], view[2])
		local b = FloatingSign.clampScale(d, M.Height, view[1], view[2], M.MinHeaderUnits, M.MaxHeaderShare)
		if math.abs(a - b) > 1e-9 then
			same = false
		end
	end
end
check(same and FloatingSign.clampScale(100, 6, 0, 70, 22, 0.08) == 1 and FloatingSign.clampScale(100, 6, 716, 0, 22, 0.08) == 1,
	"the Mist sign's own rule: the same numbers in, the same scale out; no screen, no change")

--==============================================================================
say("\n-- 4. everybody sees it --")
--==============================================================================
local far = Vector2.new(ObbyData.Entrance.At.X, ObbyData.Entrance.At.Z).Magnitude + GameConfig.Plot.MaxReach + 12
check(SIGN.MaxDistance >= far and has(client, "sign.gui.MaxDistance = SIGN.MaxDistance"),
	string.format("drawn out to %d studs: past the field's far side (%.0f, the deepest plot's back and a camera "
		.. "behind it)", SIGN.MaxDistance, far))
check(has(client, 'folder.Name = "SeedObbySign"') and has(client, "folder.Parent = Workspace")
		and has(client, "parent = folder,") and has(client, "sign.setShown(true)")
		and not has(client, "setShown(false)") and has(client, "if not GameConfig.Obby.Enabled then")
		and not has(client, "AlwaysOnTop = true"),
	"on a local anchor of its own (never streamed out), behind walls, shown to everybody while the obby is on")
check(has(client, 'BindToRenderStep("SeedObbySignClamp", Enum.RenderPriority.Camera.Value + 1,')
		and has(client, "if math.abs(want - scale) > 0.004 then") and not has(client, "Heartbeat")
		and not has(client, "while true"),
	"its size written after the camera, and only when it moves")

end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nObbySignSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
