--!nocheck
--==============================================================================
-- Steal a Seed :: TrapRemoveSpec (2026-10-04, the reusable-trap brief)
--
-- The hotbar's side of reusable traps, in Edit, with a stand-in player:
--
--   * the count is the SERVER'S: nothing until the owner's records gui has
--     spoken, then Capacity - Placed as "3x" .. "0x", changed the moment the
--     records' Placed / Newest change (a confirmed placement or removal);
--   * REMOVE stands over the slot it is given -- through HudLayout's
--     removeButton -- only with a trap out, a slot named, the row reserved and
--     the strip showing; it publishes the row for every HUD owner;
--   * a press asks for the records' NEWEST id, once per id until the server
--     answers, and asks again for the next newest after it does;
--   * a controller steps up from the trap's slot onto it and back down;
--   * HotbarCard draws the count under a trap's picture, red at 0x;
--   * LoadoutUI paints every trap slot's count from it, follows the trap's
--     real slot, and offers the same REMOVE in a trap's Bag details.
--
-- The server's half -- the count written after every placement and removal,
-- newest-first and owner-only removal -- is TrapSystemSpec's.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local HotbarCard = require(Shared:WaitForChild("HotbarCard"))
local TrapRemove = require(Shared:WaitForChild("TrapRemove"))

local T = WeaponData.Trap
local HOT = GameConfig.Hotbar
local ROW = HOT.RemoveRowAttribute

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

local fixture = Instance.new("Folder")
fixture.Name = "TrapRemoveSpecFixture"
fixture.Parent = Workspace

local function run()
	say("-- the count and the button --")
	local playerGui = Instance.new("Folder")
	playerGui.Name = "PlayerGui"
	playerGui.Parent = fixture
	local attrs = {}
	local player = {
		Name = "SpecOwner",
		WaitForChild = function(_, name)
			assert(name == "PlayerGui", name)
			return playerGui
		end,
		SetAttribute = function(_, key, value)
			attrs[key] = value
		end,
		GetAttribute = function(_, key)
			return attrs[key]
		end,
	}
	local fired = {}
	local channel = {
		FireServer = function(_, ...)
			table.insert(fired, { ... })
		end,
	}
	local changes = 0
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpecLoadout"
	gui.Parent = fixture
	local handle = TrapRemove.new(gui, {
		player = player,
		channel = function()
			return channel
		end,
		changed = function()
			changes += 1
		end,
	})
	local button = handle.button
	local L = HudLayout.solve({ safe = Vector2.new(1280, 662), touch = false, keyboard = true, removeRow = true })
	local slotButton = Instance.new("TextButton")
	slotButton.Parent = gui
	handle.layout(L)
	handle.slot(4, slotButton)
	handle.strip(true)
	check(not handle.state().known and not button.Visible and attrs[ROW] == nil,
		"before the server's count arrives: no count, no button, no row")

	-- The owner's records gui, as CombatService writes it on joining.
	local marks = Instance.new("ScreenGui")
	marks.Name = T.MarksGuiName
	marks.Enabled = false
	marks:SetAttribute(T.CapacityAttribute, 3)
	marks:SetAttribute(T.PlacedAttribute, 0)
	marks:SetAttribute(T.NewestAttribute, 0)
	marks.Parent = playerGui
	task.wait()
	local s = handle.state()
	check(s.known and s.placed == 0 and s.left == 3 and WeaponData.TrapsLeftText(s.left) == "3\u{00D7}",
		"the server's count arrives: none out, \"3x\"", s.left)
	check(not button.Visible and attrs[ROW] == nil, "and with no trap out there is no REMOVE and no row")

	-- A confirmed placement.
	local before = changes
	marks:SetAttribute(T.PlacedAttribute, 1)
	marks:SetAttribute(T.NewestAttribute, 7)
	task.wait()
	s = handle.state()
	check(s.placed == 1 and s.left == 2 and s.newest == 7 and changes > before,
		"a placement the server confirmed: \"2x\" at once, and the strip is told to repaint", changes - before)
	check(button.Visible and attrs[ROW] == true, "REMOVE stands, and the row is published for every HUD owner")
	local press, plate = HudLayout.removeButton(L, 4)
	local platePart = button:FindFirstChild("Plate")
	check(press and plate and button.Position == HudLayout.place(press, Vector2.zero, L.safe)
			and button.Size == UDim2.fromOffset(press.w, press.h)
			and platePart and platePart.Position == UDim2.fromOffset(plate.x - press.x, plate.y - press.y),
		"over slot 4 exactly where HudLayout puts it: the press on the row, the plate at its foot",
		press and string.format("%s / %s", tostring(button.Position), tostring(HudLayout.place(press, Vector2.zero, L.safe))))
	local words = platePart and platePart:FindFirstChild("Words")
	check(words and words.Text == "REMOVE" and button.Selectable,
		"it reads REMOVE and a controller can select it")
	check(slotButton.NextSelectionUp == button and button.NextSelectionDown == slotButton,
		"up from the trap's slot lands on it, and down goes back")

	-- The slot moves (the trap reassigned): REMOVE follows it.
	handle.slot(2, slotButton)
	local press2 = HudLayout.removeButton(L, 2)
	check(button.Position == HudLayout.place(press2, Vector2.zero, L.safe),
		"the trap moved to slot 2: REMOVE follows it there -- never a fixed slot")
	handle.slot(4, slotButton)

	-- The press.
	check(handle.press() == true and #fired == 1 and fired[1][1] == GameConfig.Weapon.TrapRemoveAction
			and fired[1][2] == 7,
		"a press asks the server for the NEWEST trap, by its id", fired[1] and tostring(fired[1][2]))
	check(handle.press() == false and #fired == 1, "a second press before the answer asks nothing more")
	marks:SetAttribute(T.PlacedAttribute, 0)
	marks:SetAttribute(T.NewestAttribute, 0)
	task.wait()
	s = handle.state()
	check(s.left == 3 and not button.Visible and attrs[ROW] == nil,
		"the server confirms the removal: \"3x\", and REMOVE and its row go")

	-- Three out: 0x, and two removals in a row ask for two different ids.
	marks:SetAttribute(T.PlacedAttribute, 3)
	marks:SetAttribute(T.NewestAttribute, 12)
	task.wait()
	s = handle.state()
	check(s.left == 0 and WeaponData.TrapsLeftText(s.left) == "0\u{00D7}" and button.Visible, "three out: \"0x\"")
	task.wait(0.4)
	handle.press()
	marks:SetAttribute(T.PlacedAttribute, 2)
	marks:SetAttribute(T.NewestAttribute, 11)
	task.wait()
	check(handle.press() == false and #fired == 2,
		"a second press straight after (a double-click), even with the server already answered, counts once")
	task.wait(0.4)
	handle.press()
	check(#fired == 3 and fired[2][2] == 12 and fired[3][2] == 11 and handle.state().left == 1,
		"newest first, one press each: 12, then 11 -- a deliberate press later -- once the server had taken 12",
		string.format("%d presses: %s %s", #fired, tostring(fired[2] and fired[2][2]), tostring(fired[3] and fired[3][2])))

	-- Hidden with the strip, and with no trap slot shown.
	handle.strip(false)
	check(not button.Visible and attrs[ROW] == true,
		"the strip stepping aside (a phone's open Bag, a drag) hides REMOVE; the row stays reserved")
	handle.strip(true)
	check(button.Visible, "and it comes back with the strip")
	handle.slot(nil, nil)
	check(not button.Visible and attrs[ROW] == nil and slotButton.NextSelectionUp == nil,
		"no trap on a shown slot: no button, no row, no selection link left behind (REMOVE is in the Bag)")
	marks:Destroy()
	task.wait()
	check(not handle.state().known, "the records gui gone: the count is unknown again, never guessed")

	say("\n-- the count on a trap's slot --")
	local strip = Instance.new("Frame")
	strip.Parent = gui
	local card = HotbarCard.build(strip, 1, HOT, 4)
	HotbarCard.paint(card, HOT, { empty = false, held = false, number = "1", name = "", uses = "2\u{00D7}",
		usesEmpty = false })
	check(card.uses.Visible and card.uses.Text == "2\u{00D7}" and card.uses.TextColor3 == HOT.TrapCountColour
			and card.uses.AnchorPoint == Vector2.new(0.5, 1) and card.uses.Position.X.Scale == 0.5,
		"a trap slot shows \"2x\" under its picture, bottom centre, in cream")
	HotbarCard.paint(card, HOT, { empty = false, held = false, number = "1", name = "", uses = "0\u{00D7}",
		usesEmpty = true })
	check(card.uses.TextColor3 == HOT.TrapCountEmpty, "and \"0x\" in its warm red")
	HotbarCard.paint(card, HOT, { empty = false, held = false, number = "1", name = "" })
	check(not card.uses.Visible, "any other slot shows no count")
	local compact = HudLayout.hotMetrics(true)
	HotbarCard.restyle(card, compact)
	check(card.uses.TextSize == compact.TrapCountSize, "the phone's belt draws it at its own size")

	say("\n-- LoadoutUI, read --")
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local loadout = scripts:FindFirstChild("LoadoutUI")
	local readOk, read = pcall(function()
		return (loadout :: any).Source
	end)
	local src = if readOk and type(read) == "string" then read else ""
	check(src:find("uses = if isTrap and traps and traps.known then WeaponData.TrapsLeftText(traps.left) else nil", 1, true)
			~= nil,
		"every trap slot's count is the server's, painted only once it is known")
	check(src:find("if item and item.tool and item.tool.Parent then", 1, true) ~= nil
			and src:find("local at = trapSlot or anyTrapSlot", 1, true) ~= nil,
		"REMOVE follows the trap in the player's hands, else the first trap on the strip")
	check(src:find("{ id = \"removetrap\", label = \"Remove newest trap\" }", 1, true) ~= nil
			and src:find("trapRemove.press()", 1, true) ~= nil,
		"a trap's Bag details offer the same REMOVE, through the same press")
	check(src:find("slot.item.Category ~= \"trap\"", 1, true) ~= nil and src:find("PlaceCooldownSeconds", 1, true) == nil,
		"the strip draws no recharge shade on a trap")
end

local ok, err = pcall(run)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
fixture:Destroy()
say(string.format("\nTrapRemoveSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
