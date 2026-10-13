--!nocheck
--==============================================================================
-- Steal a Seed :: PadStickSpec (2026-10-13, the owner's backlog item 3)
--
-- THE RIGHT STICK IN A MENU: it scrolls the open panel, and the camera never
-- hears it while one is up. Real stick input cannot be made in Studio, so the
-- numbers and the choice are held here on real lists, and the bind and its
-- release by the script's own words; Michael confirms on console.
--
--   the rate     nothing inside the dead zone, the sign kept, a square ramp to
--                Speed at full tilt, NaN nothing
--   the step     push up to go up, never past either end, a long frame capped
--   the pick     the list around the selected control that can move the way
--                the stick is pushed, else the panel's biggest that can, or
--                none -- on real ScrollingFrames in a throwaway gui
--   the bind     Thumbstick2 only, at High (over the camera's Medium), sunk,
--                bound while a panel is open and released by the panel's
--                state and a frame watch; the left stick and D-pad untouched
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local PadScroll = require(Shared:WaitForChild("PadScroll"))

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
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local V2 = Vector2.new

local layer = Instance.new("ScreenGui")
layer.Name = "ZZPadStickSpec"
layer.Archivable = false

local ok, err = pcall(function()
	--==========================================================================
	say("-- the rate --")
	--==========================================================================
	local dz, speed = PadScroll.Deadzone, PadScroll.Speed
	check(PadScroll.rate(0) == 0 and PadScroll.rate(dz) == 0 and PadScroll.rate(-dz * 0.9) == 0 and PadScroll.rate(0 / 0) == 0,
		string.format("nothing inside the dead zone (%.2f), and nothing from a NaN", dz))
	check(math.abs(PadScroll.rate(1) - speed) < 1e-6 and math.abs(PadScroll.rate(-1) + speed) < 1e-6
			and PadScroll.rate(1.4) == PadScroll.rate(1),
		string.format("full tilt is Speed (%d a second), the sign kept, and never more", speed))
	local last, rising = 0, true
	for i = 1, 20 do
		local r = PadScroll.rate(dz + (1 - dz) * i / 20)
		rising = rising and r > last
		last = r
	end
	local half = PadScroll.rate(dz + (1 - dz) * 0.5)
	check(rising and math.abs(half - speed * 0.25) < 1e-6,
		"rising all the way, on a square: half way along the push is a quarter of the speed (a light push creeps)")

	--==========================================================================
	say("\n-- the step --")
	--==========================================================================
	local up = PadScroll.step(V2(0, 500), V2(0, 900), V2(0, 1), 0.05)
	local down = PadScroll.step(V2(0, 500), V2(0, 900), V2(0, -1), 0.05)
	check(math.abs(up.Y - (500 - speed * 0.05)) < 1e-6 and math.abs(down.Y - (500 + speed * 0.05)) < 1e-6,
		"pushing up scrolls the list up (its canvas goes back toward the top), down goes down", tostring(up) .. " " .. tostring(down))
	check(PadScroll.step(V2(0, 10), V2(0, 900), V2(0, 1), 0.05).Y == 0
			and PadScroll.step(V2(0, 890), V2(0, 900), V2(0, -1), 0.05).Y == 900,
		"and never past either end")
	local across = PadScroll.step(V2(100, 0), V2(600, 0), V2(1, 0), 0.05)
	check(math.abs(across.X - (100 + speed * 0.05)) < 1e-6 and across.Y == 0, "pushing right scrolls a strip right")
	check(PadScroll.step(V2(0, 0), V2(0, 9000), V2(0, -1), 5).Y == speed * 0.1
			and PadScroll.step(V2(0, 300), V2(0, 900), V2(0, -1), 0 / 0).Y == 300,
		"a long frame moves it at most a tenth of a second's worth; a NaN frame not at all")

	--==========================================================================
	say("\n-- the pick --")
	--==========================================================================
	layer.Parent = StarterGui
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(900, 700)
	panel.Parent = layer
	local function list(name, pos, size, canvas, direction)
		local s = Instance.new("ScrollingFrame")
		s.Name = name
		s.Position = pos
		s.Size = size
		s.CanvasSize = canvas
		s.ScrollingDirection = direction or Enum.ScrollingDirection.Y
		s.ScrollBarThickness = 0
		s.Parent = panel
		local b = Instance.new("TextButton")
		b.Name = "Button"
		b.Size = UDim2.fromOffset(60, 30)
		b.Parent = s
		return s, b
	end
	local listA, btnA = list("Big", UDim2.fromOffset(0, 0), UDim2.fromOffset(500, 300), UDim2.fromOffset(0, 1200))
	local listB, btnB = list("Small", UDim2.fromOffset(520, 0), UDim2.fromOffset(200, 150), UDim2.fromOffset(0, 600))
	local listC, btnC = list("Still", UDim2.fromOffset(520, 200), UDim2.fromOffset(200, 150), UDim2.fromOffset(0, 150))
	local listH, btnH = list("Strip", UDim2.fromOffset(0, 400), UDim2.fromOffset(300, 80), UDim2.fromOffset(1000, 0),
		Enum.ScrollingDirection.X)
	local UP, RIGHT, REST = V2(0, 1), V2(1, 0), V2(0.1, -0.1)
	if layer.AbsoluteSize.X <= 0 or listA.AbsoluteSize.Y <= 0 then
		check(false, "Studio gave the throwaway gui no size in Edit: the pick is the Play check's")
	else
		local lim = PadScroll.limit(listA)
		check(math.abs(lim.Y - 900) < 0.5 and lim.X < 0.5 and PadScroll.limit(listC).Y < 0.5,
			"how far a list can go: its canvas past its window (900 here), nothing for one that fits", tostring(lim))
		check(PadScroll.pick(btnB, panel, UP) == listB,
			"pushed up, the list around the selected control, when it can scroll up")
		check(PadScroll.pick(btnC, panel, UP) == listA and PadScroll.pick(nil, panel, UP) == listA,
			"a selected control in a list that cannot move (or none selected): the panel's biggest list that can")
		check(PadScroll.pick(btnH, panel, RIGHT) == listH and PadScroll.pick(btnH, panel, UP) == listA,
			"a strip that scrolls across takes a sideways push, and an up push from it goes to the biggest up-and-down list")
		check(PadScroll.pick(btnA, panel, REST) == nil and PadScroll.pick(btnA, nil, UP) == nil,
			"a stick resting in its dead zone picks nothing, and nor does no panel")
		listB.Visible = false
		check(PadScroll.pick(btnB, panel, UP) == listA, "a hidden list is never scrolled")
		listB.Visible = true
	end

	--==========================================================================
	say("\n-- the bind --")
	--==========================================================================
	local stickScript = StarterPlayer.StarterPlayerScripts:FindFirstChild("PadStick")
	local src = stickScript and stickScript.Source or ""
	check(stickScript ~= nil and has(src, "BindActionAtPriority(ACTION, onStick, false, PRIORITY, Enum.KeyCode.Thumbstick2)")
			and has(src, "local PRIORITY = Enum.ContextActionPriority.High.Value")
			and Enum.ContextActionPriority.High.Value > Enum.ContextActionPriority.Medium.Value
			and has(src, "return Enum.ContextActionResult.Sink"),
		"the right stick (Thumbstick2) is bound at High, over the camera's own bind at Medium, and sunk: the camera "
			.. "never turns while it is held")
	check(has(src, "setBound(PadInput.panelOpen())") and has(src, "PadInput.PanelChanged:Connect(refresh)")
			and has(src, "player:GetAttributeChangedSignal(GameConfig.Attributes.OpenPanel):Connect(refresh)"),
		"bound exactly while a panel is open: PadInput's panel state (every dimmer) and OpenPanel")
	check(has(src, "if not PadInput.panelOpen() then\n\t\tsetBound(false)") and has(src, "ContextActionService:UnbindAction(ACTION)"),
		"released on every way a panel shuts -- B, its X, another panel, a respawn -- and by a frame watch, whatever "
			.. "missed a signal")
	check(not has(src, "Thumbstick1") and not has(src, "DPad") and not has(src, "SelectedObject ="),
		"the left stick and the D-pad are never bound, and the selection is never moved: they still walk the menu")
	check(has(src, "PadScroll.pick(selected, panel, stick)")
			and has(src, "list.CanvasPosition = PadScroll.step(list.CanvasPosition, PadScroll.limit(list), stick, dt)"),
		"and while it is held, the list PadScroll picks scrolls every frame")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

layer:Destroy()

say(string.format("\nPadStickSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
