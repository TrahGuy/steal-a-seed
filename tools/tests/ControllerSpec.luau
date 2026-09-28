--!nocheck
--==============================================================================
-- Steal a Seed :: ControllerSpec
--
-- The controller paths added 2026-09-24 -- LB/RB on the hotbar, planting with
-- the camera's middle and RT, B to put away or to close, a panel's focus and
-- where it goes back to -- checked without a controller: the bumper walk as
-- pure arithmetic, the modal chrome a selection must never land on as real
-- instances, and the wiring every path depends on, read from source.
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("ControllerSpec"))
--
-- Not here: real presses. Those are the Controller Emulator's (KB/HANDOFF), and
-- a physical Xbox's after that.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local PadInput = require(Shared.PadInput)
local UIKit = require(Shared.UIKit)
local ActionRefusal = require(Shared.ActionRefusal)

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
local function sourceOf(instance)
	if instance == nil then
		return ""
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function before(src, first, second)
	local a = string.find(src, first, 1, true)
	local b = string.find(src, second, 1, true)
	return a ~= nil and b ~= nil and a < b
end

local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local placeSrc = sourceOf(scripts:FindFirstChild("PlantPlace"))
local loadoutSrc = sourceOf(scripts:FindFirstChild("LoadoutUI"))
local focusSrc = sourceOf(scripts:FindFirstChild("PadFocus"))
local promptSrc = sourceOf(scripts:FindFirstChild("PromptUI"))
local gardenSrc = sourceOf(scripts:FindFirstChild("GardenUI"))
local sellSrc = sourceOf(scripts:FindFirstChild("SellUI"))
local teleportSrc = sourceOf(scripts:FindFirstChild("PlotTeleportUI"))
local adminModule = game:GetService("ServerScriptService").SeedGameServer:FindFirstChild("AdminService")
local adminSrc = sourceOf(adminModule and adminModule:FindFirstChild("AdminConsoleUI"))

local ok, err = pcall(function()
	--==========================================================================
	-- 1. WHERE A BUMPER LANDS
	--==========================================================================
	say("-- LB / RB --")
	local S = { 1, 3, 4 }
	check(PadInput.nextSlot(S, 3, 1) == 4, "RB from slot 3 goes to 4")
	check(PadInput.nextSlot(S, 4, 1) == 1, "RB from the last filled slot wraps to the first")
	check(PadInput.nextSlot(S, 1, -1) == 4, "LB from the first wraps to the last")
	check(PadInput.nextSlot(S, 3, -1) == 1, "LB from 3 skips the empty slot 2 and lands on 1")
	check(PadInput.nextSlot(S, 1, 1) == 3, "RB from 1 skips the empty slot 2")
	check(PadInput.nextSlot(S, nil, 1) == 1 and PadInput.nextSlot(S, nil, -1) == 4,
		"empty hands: RB takes the first thing on the strip, LB the last")
	check(PadInput.nextSlot(S, 2, 1) == 1 and PadInput.nextSlot(S, 7, -1) == 4,
		"hands holding something the strip does not show: from outside either end")
	check(PadInput.nextSlot({ 2 }, 2, 1) == 2 and PadInput.nextSlot({ 2 }, 2, -1) == 2,
		"one thing on the strip: a bumper lands on it again (the caller leaves it in the hands)")
	check(PadInput.nextSlot({}, nil, 1) == nil and PadInput.nextSlot({}, 3, -1) == nil,
		"an empty strip: nowhere to go")
	-- Every strip shape of 1-10 slots: a walk of #filled presses returns to its
	-- start, and never stops on a slot that is not filled.
	local walksOk, bad = true, nil
	for mask = 1, 1023 do
		local filled, set = {}, {}
		for i = 1, 10 do
			if bit32.band(mask, bit32.lshift(1, i - 1)) ~= 0 then
				table.insert(filled, i)
				set[i] = true
			end
		end
		for _, step in ipairs({ 1, -1 }) do
			local at = filled[1]
			for _ = 1, #filled do
				at = PadInput.nextSlot(filled, at, step)
				if not set[at] then
					walksOk, bad = false, string.format("mask %d step %d landed on %s", mask, step, tostring(at))
				end
			end
			if at ~= filled[1] then
				walksOk, bad = false, string.format("mask %d step %d did not come back round", mask, step)
			end
		end
	end
	check(walksOk, "all 1023 strip shapes: every press lands on a filled slot and a full walk comes back round", bad)

	--==========================================================================
	-- 2. WHO IS ON A CONTROLLER, AND WHAT ITS BUTTONS ARE CALLED
	--==========================================================================
	say("\n-- input --")
	check(PadInput.isGamepad(Enum.UserInputType.Gamepad1) and PadInput.isGamepad(Enum.UserInputType.Gamepad8),
		"Gamepad1..8 are a controller")
	check(not PadInput.isGamepad(Enum.UserInputType.Keyboard) and not PadInput.isGamepad(Enum.UserInputType.MouseButton1)
			and not PadInput.isGamepad(Enum.UserInputType.Touch),
		"the keyboard, the mouse and a finger are not")
	check(PadInput.short(Enum.KeyCode.ButtonR2) == "RT" and PadInput.short(Enum.KeyCode.ButtonB) == "B"
			and PadInput.short(Enum.KeyCode.ButtonL1) == "LB" and PadInput.short(Enum.KeyCode.ButtonR1) == "RB",
		"the fallback names are the Xbox ones: RT, B, LB, RB")
	check(type(PadInput.glyph(Enum.KeyCode.ButtonR2)) == "string", "a glyph lookup never throws")
	check(type(PadInput.panelOpen()) == "boolean", "'is a panel open' answers with no player at all (Edit)")

	--==========================================================================
	-- 3. THE MODAL'S CHROME IS NEVER SOMEWHERE A SELECTION LANDS
	--==========================================================================
	say("\n-- the modal --")
	local holder = Instance.new("Folder")
	holder.Name = "ControllerSpecFixture"
	holder.Archivable = false
	holder.Parent = ServerStorage
	local gui = Instance.new("ScreenGui")
	gui.Parent = holder
	local m = UIKit.modal(gui, { name = "Probe", title = "PROBE", maxWidth = 300, maxHeight = 300 })
	check(m.dimmer.Selectable == false, "the full-screen dimmer is not selectable")
	local blocker = m.shell:FindFirstChild("ClickBlocker")
	check(blocker ~= nil and blocker.Selectable == false, "the panel-sized ClickBlocker is not selectable")
	check(m.close.Selectable == true, "the close button still is")
	check(m.dimmer.Parent == gui and string.sub(m.dimmer.Name, -6) == "Dimmer",
		"the dimmer sits directly under its gui, named ...Dimmer -- the rule PadInput reads panels by")
	holder:Destroy()

	--==========================================================================
	-- 4. PLANTING ON A CONTROLLER, FROM SOURCE
	--==========================================================================
	say("\n-- planting --")
	check(placeSrc ~= "", "PlantPlace's source is readable")
	check(has(placeSrc, "soilPoint(if pad then padAim() else nil)") and has(placeSrc, "size.X * 0.5, size.Y * 0.5"),
		"on a controller the ray comes from the middle of the camera")
	check(has(placeSrc, "Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR2")
			and has(placeSrc, "channel:FireServer(PLANTING.PlaceAction, point)"),
		"RT sends the same PlaceAction a click sends -- every server rule applies unchanged")
	check(has(placeSrc, "Enum.ContextActionPriority.Medium.Value, Enum.KeyCode.ButtonB")
			and has(placeSrc, "return unequip(name, state)"),
		"B puts the plant away through the same UnequipTools as Q and the phone button")
	check(has(placeSrc, "return PadInput.panelOpen() or GuiService.SelectedObject ~= nil"),
		"with a panel up or a selection being steered, RT and B belong to the UI, not the world")
	check(has(placeSrc, "if pad and uiHasTheButtons() then\n\t\tsetPadBound(false)\n\t\tshowPad(false)"),
		"and then the reticle, its hints and RT/B are all put away -- no 'RT PLANT' while RT is the UI's")
	check(has(placeSrc, "PLANT_OUT_OF_RANGE = ActionRefusal.Text.PLANT_OUT_OF_RANGE")
			and has(placeSrc, "PLOT_FULL = ActionRefusal.Text.PLOT_FULL")
			and ActionRefusal.Text.PLANT_OUT_OF_RANGE ~= nil and ActionRefusal.Text.PLOT_FULL ~= nil,
		"the reticle says why in the server's own words")
	local refusal = string.match(placeSrc, "local function placeRefusal(.-)\nend") or ""
	-- Room names its next step since 2026-09-27 (ActionRefusal.plotFull picks one
	-- of the four full-plot codes); the order is what this pins.
	check(before(refusal, "PLANT_OUT_OF_RANGE", "ActionRefusal.plotFull("),
		"reach is checked before room, in PlaceAt's order")
	check(has(placeSrc, "if processed then") and has(placeSrc, "input.UserInputType ~= Enum.UserInputType.MouseButton1")
			and has(placeSrc, "and input.UserInputType ~= Enum.UserInputType.Touch then"),
		"the click and the tap are unchanged: a UI press never plants")
	check(has(placeSrc, "padGui.IgnoreGuiInset = true") and has(placeSrc, "ring.Position = UDim2.fromScale(0.5, 0.5)"),
		"the reticle is drawn in window space at the exact middle the ray is cast through")
	check(teleportSrc ~= ""
			and has(teleportSrc, "and not (PadInput.panelOpen() or GuiService.SelectedObject ~= nil) then\n\t\t\t\trequest()")
			and has(teleportSrc, "end, false, Enum.KeyCode.DPadUp)"),
		"D-pad Up teleports home only while the UI has nothing -- in a panel or on the HUD it walks the selection")

	--==========================================================================
	-- 4b. EVERY PROMPT NAMES THE BUTTON THAT WORKS
	--==========================================================================
	say("\n-- prompts --")
	check(promptSrc ~= "" and gardenSrc ~= "", "PromptUI's and GardenUI's sources are readable")
	check(has(promptSrc, "if PadInput.active() then\n\t\treturn PadInput.short(prompt.GamepadKeyCode)")
			and has(promptSrc, "key.Text = capText(prompt)"),
		"on a controller a prompt's key cap is its GamepadKeyCode (X, or Y for Instant Hatch) -- not the E an Xbox does not have")
	check(has(promptSrc, "PadInput.Changed:Connect(function()") and has(promptSrc, "key.Text = capText(prompt)\n\t\tend"),
		"and the caps already on screen re-label when the controller is picked up or put down")
	check(PadInput.short(Enum.KeyCode.ButtonX) == "X" and PadInput.short(Enum.KeyCode.ButtonY) == "Y",
		"the short names the caps print")
	check(has(gardenSrc, '"HOLD [" .. PadInput.short(Enum.KeyCode.ButtonX) .. "] IN FIELD"')
			and has(gardenSrc, '"HOLD [E] IN FIELD"'),
		"a ready pod's Garden card says X on a controller and E at a keyboard")

	--==========================================================================
	-- 5. LB / RB WIRING
	--==========================================================================
	say("\n-- the hotbar --")
	check(has(loadoutSrc, 'BindAction("SeedHotbarCycle"') and has(loadoutSrc, "Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1"),
		"LB and RB are bound on the hotbar")
	check(has(loadoutSrc, "if PadInput.panelOpen() then\n\t\t\treturn Enum.ContextActionResult.Pass"),
		"and do nothing while any panel is open")
	check(has(loadoutSrc, "PadInput.nextSlot(occupiedSlots()") and has(loadoutSrc, "holdTool(slot.tool)"),
		"they walk the strip with nextSlot and equip through holdTool, the number row's path")

	--==========================================================================
	-- 6. PANELS ON A CONTROLLER
	--==========================================================================
	say("\n-- panels --")
	check(focusSrc ~= "", "PadFocus's source is readable")
	check(has(focusSrc, "SeedAdmin = true") and has(focusSrc, "if not managed(gui) then"),
		"the admin console's own focus system is left alone")
	check(has(focusSrc, "local BACK_PRIORITY = 2500") and has(focusSrc, "player:SetAttribute(ATTR.OpenPanel, nil)"),
		"B closes a panel on the OpenPanel mutex by clearing it")
	check(has(focusSrc, "while anyAButtonDown() and waited < RELEASE_WAIT do"),
		"the selection moves in only after the A that opened the panel is let go")
	check(has(focusSrc, "shell.SelectionBehaviorUp = Enum.SelectionBehavior.Stop") and has(focusSrc, "shell.SelectionGroup = true"),
		"the D-pad is kept inside the open panel")
	check(has(focusSrc, "GuiService.SelectedObject = back") and has(focusSrc, "restoreFor[dimmer] ="),
		"focus goes back to what had it before the panel opened")
	check(has(focusSrc, "evicted[dimmer] = true") and has(focusSrc, "and not movedByTheEngine then")
			and has(focusSrc, "if was == nil or onScreen(was) then"),
		"even when the engine re-homed the selection first, as it does the moment the selected control hides")
	check(has(focusSrc, "if dimmer == nil and not PadInput.panelOpen() and GuiService.SelectedObject ~= nil then\n\t\t\tGuiService.SelectedObject = nil\n\t\t\treturn Enum.ContextActionResult.Sink"),
		"with no panel up, B steps the selection off the HUD (where a closed panel leaves it) -- never while the admin console is open")
	check(has(focusSrc, 'shell:FindFirstChild("PadFirst")'), "a panel can name where the selection starts")
	local first = string.match(focusSrc, "local function firstControl(.-)\nend") or ""
	check(before(first, "scan(body, true)", "scan(body, false)") and before(first, "scan(body, false)", "scan(shell, true)")
			and has(focusSrc, 'return object:IsA("GuiButton") or object:IsA("TextBox")'),
		"a panel opens on its first CONTROL -- not on the scrolling list that holds it -- and on the close button only when the body has nothing")
	check(has(focusSrc, "playerGui.SelectionImageObject = selectionRing"), "the selection frame is the thick gold ring")
	check(has(sellSrc, "padFirst.Value = cancelButton.button")
			and has(sellSrc, "Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB"),
		"the sell confirmation starts on CANCEL and B is a no")
	-- The B ladder: a panel with its own B (3000) > the generic panel close
	-- (2500) > putting a plant away (2000).
	check(has(adminSrc, "3000, Enum.KeyCode.ButtonB") and 3000 > 2500 and 2500 > Enum.ContextActionPriority.Medium.Value,
		"B's order: a panel's own B, then any panel's close, then the plant in the hands")

	--==========================================================================
	-- 7. THE GARDEN'S BOTTOM ROW (reported from a console 2026-09-26)
	--
	-- Reaching a bottom-row PICK UP scrolled the list, any scroll dropped the
	-- selection, and the button hid under the pad's focus. The arithmetic is
	-- the real layout at the 480 x 560 cap: three 142 x 184 cells a row, gutter
	-- 8, 10 of padding top and bottom, a 452-unit window, and a 7-plant bed --
	-- three rows, a 588-unit canvas.
	--==========================================================================
	say("\n-- the Garden's bottom row --")
	local VIEW, CANVAS, ACTION = 452, 588, GameConfig.Card.ActionHeight
	local function span(row) -- the card and the ring's margin round it
		local top = 10 + (row - 1) * (184 + 8)
		return top - 10, top + 184 + 10, top + 184
	end
	local lo1, hi1 = span(1)
	local lo2, hi2 = span(2)
	local lo3, hi3, bottom3 = span(3)
	check(UIKit.scrollToShow(0, VIEW, lo1, hi1, CANVAS) == 0, "the first row, already in view, does not move the list")
	check(UIKit.scrollToShow(0, VIEW, lo2, hi2, CANVAS) == 0, "nor does a middle row that is wholly in view")
	local down = UIKit.scrollToShow(0, VIEW, lo3, hi3, CANVAS)
	check(down == CANVAS - VIEW, "the half-hidden bottom row scrolls the list to its end", down)
	check(UIKit.spanShown(down, VIEW, bottom3 - ACTION, bottom3),
		"and its PICK UP is then wholly in view")
	check(not UIKit.spanShown(0, VIEW, bottom3 - ACTION, bottom3),
		"-- which it was not before: the strip sat under the list's edge")
	check(UIKit.scrollToShow(60, VIEW, lo3, hi3, CANVAS) == CANVAS - VIEW,
		"a partly scrolled list goes the rest of the way")
	check(UIKit.scrollToShow(CANVAS - VIEW, VIEW, lo1, hi1, CANVAS) == 0,
		"and from the bottom, focus on the first row brings the list back to the top")
	-- A landscape phone: a 150-unit window under a 200-unit card.
	local tall = UIKit.scrollToShow(0, 150, 0, 220, 400)
	check(tall == 70 and UIKit.spanShown(tall, 150, 210 - ACTION, 210),
		"a card taller than the window shows its bottom -- the PICK UP -- not its top", tall)
	check(UIKit.scrollToShow(0, VIEW, 500, 700, CANVAS) == CANVAS - VIEW,
		"and a reveal never scrolls past the end of the canvas")

	check(has(gardenSrc, "list.Selectable = false"), "the Garden list is never a pad stop -- its cards are")
	local pad = tonumber(string.match(gardenSrc, "local EDGE_PAD = (%d+)") or "")
	check(pad ~= nil and pad >= 9 and has(gardenSrc, "listPad.PaddingBottom = UDim.new(0, EDGE_PAD)")
			and has(gardenSrc, "2 * EDGE_PAD + FOOTER_HEIGHT"),
		"room under the last row for the ring (9 px on a TV), and the panel is sized for it", pad)
	check(not has(gardenSrc, 'GetPropertyChangedSignal("CanvasPosition"):Connect(function()\n\tclearSelection()\nend)'),
		"a scroll no longer drops the selection unconditionally")
	check(has(gardenSrc, "if focus and slotIndexOf[focus] == index then\n\t\treturn")
			and has(gardenSrc, "if not UIKit.spanShown(list.CanvasPosition.Y, viewHeight(),"),
		"it drops it only when the PICK UP leaves the window, and never while the pad's focus is on that card")
	local clearing = string.match(gardenSrc, "local function clearSelection%(%)(.-)\nend") or ""
	check(before(clearing, "GuiService.SelectedObject = slot.button", "slot.setSelected(false)"),
		"after a pick-up the focus is handed to the same card BEFORE its button hides")
	check(has(gardenSrc, "slot.button.NextSelectionDown = slot.action")
			and has(gardenSrc, "slot.action.NextSelectionUp = slot.button"),
		"down from a selected card is its own PICK UP, and up is back to the card")
	check(has(gardenSrc, 'GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(')
			and has(gardenSrc, "if open and index then\n\t\treveal(index)"),
		"a card that takes the pad's focus is scrolled into view whole")
	check(has(gardenSrc, "GuiService.SelectedObject = slotAt(n).button"),
		"a card hidden by a shrinking list hands the focus to the last card that stays")
	check(has(gardenSrc, "if selectedSlot == slot or not placementId then"),
		"a pod or an empty hole offers no PICK UP, so pressing it selects nothing")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nControllerSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
