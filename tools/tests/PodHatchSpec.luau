--!nocheck
--==============================================================================
-- Steal a Seed :: PodHatchSpec (2026-10-10, Michael on v1047: "no way to hatch
-- the egg in your hotbar without navigating to bag and hatch all")
--
-- HATCH over a READY pod in the hands, in Edit, with a stand-in player:
--
--   * only a READY pod in the hands on a shown slot gets it: nothing for none,
--     nothing for a growing pod -- until it is due, when it stands unasked;
--   * it stands over the pod's own slot in REMOVE's row (HudLayout's
--     removeButton), reads HATCH, and a controller steps up onto it and back
--     down; it claims the row, binds LT, and raises HandAttribute for
--     PlantPlace's LT hint;
--   * its end asks the server for the Bag's own Hatch, by the pod's item id,
--     once per pod until the answer can have come;
--   * it steps aside with the strip; the row is shared with REMOVE and stands
--     while either claims it;
--   * the hold is MenuKit.hold -- the Bag's own, now shared;
--   * LoadoutUI tells it what it tells REMOVE; PlantPlace names LT.
--
-- Not here, seen in Play: the hold filling (no tweens run in Edit) and the
-- hatch itself (the server's verb is HatchInBagSpec's).
--==============================================================================
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local TrapRemove = require(Shared:WaitForChild("TrapRemove"))
local PodHatch = require(Shared:WaitForChild("PodHatch"))

local HOT = GameConfig.Hotbar
local BAG = GameConfig.HatchInBag
local ROW = HOT.RemoveRowAttribute
local HAND = BAG.HandAttribute
local PAD_ACTION = "SeedHandHatch"

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
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
-- LT bound under PodHatch's action, at High.
local function ltBound()
	local ok, info = pcall(function()
		return ContextActionService:GetBoundActionInfo(PAD_ACTION)
	end)
	return ok and type(info) == "table" and next(info) ~= nil
end

local fixture = Instance.new("Folder")
fixture.Name = "PodHatchSpecFixture"
fixture.Parent = Workspace

local function run()
	say("-- the button --")
	local attrs = {}
	local player = {
		Name = "SpecOwner",
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
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpecLoadout"
	gui.Parent = fixture
	local handle = PodHatch.new(gui, {
		player = player,
		channel = function()
			return channel
		end,
	})
	local button = handle.button
	local L = HudLayout.solve({ safe = Vector2.new(1280, 662), touch = false, keyboard = true, removeRow = true })
	local slotButton = Instance.new("TextButton")
	slotButton.Parent = gui
	handle.layout(L)
	handle.strip(true)

	handle.slot(nil, nil, nil)
	check(not button.Visible and not handle.offered() and attrs[ROW] == nil and attrs[HAND] == nil and not ltBound(),
		"nothing in the hands: no HATCH, no row, no LT, no hint")
	check(handle.press() == false and #fired == 0, "and an end of a hold asks nothing")

	local now = Workspace:GetServerTimeNow()
	handle.slot(3, slotButton, { item = "pod-1", hatchAt = now + 30 })
	check(not button.Visible and attrs[ROW] == nil and attrs[HAND] == nil and not ltBound(),
		"a growing pod in the hands: no HATCH (its card counts its time down), no row")

	handle.slot(3, slotButton, { item = "pod-1", hatchAt = now - 1 })
	check(button.Visible and handle.offered() and attrs[ROW] == true and attrs[HAND] == true and ltBound(),
		"a READY pod in the hands: HATCH stands, the row is claimed, LT is bound, PlantPlace is told")
	local area, plate = HudLayout.removeButton(L, 3)
	local platePart = button:FindFirstChild("Plate")
	check(area and plate and button.Position == HudLayout.place(area, Vector2.zero, L.safe)
			and button.Size == UDim2.fromOffset(area.w, area.h) and platePart
			and platePart.Position == UDim2.fromOffset(plate.x - area.x, plate.y - area.y)
			and platePart.Size == UDim2.fromOffset(plate.w, plate.h),
		"over slot 3 exactly where REMOVE would stand: the press on the row, the plate at its foot")
	local label = platePart and platePart:FindFirstChild("Label")
	check(label and label.Text == BAG.Words.Hatch and button.Selectable and slotButton.NextSelectionUp == button
			and button.NextSelectionDown == slotButton,
		"it reads HATCH, and a controller steps up onto it from the pod's slot and back down")
	-- The word fits the plate on the desktop belt and on a phone's.
	local font = GameConfig.BagLook.LabelFont
	local word = TextService:GetTextSize(BAG.Words.Hatch, HOT.RemoveText, font, Vector2.new(1000, 100)).X
	local compact = HudLayout.hotMetrics(true)
	local desk = HudLayout.hotMetrics(false)
	check(word <= compact.SlotWidth - 10 and word <= desk.SlotWidth - 10
			and HOT.RemoveHeight * (1 - GameConfig.BagLook.FootShare) >= HOT.RemoveText,
		"HATCH fits its plate at full size on both belts", string.format("%d px in %d / %d", word,
			compact.SlotWidth - 10, desk.SlotWidth - 10))

	say("\n-- the hatch --")
	check(handle.press() == true and #fired == 1 and fired[1][1] == BAG.Hatch and fired[1][2] == "pod-1",
		"the hold's end asks the server for the Bag's own Hatch, by the pod's item id",
		fired[1] and tostring(fired[1][2]))
	check(handle.press() == false and #fired == 1, "a second end straight after asks nothing more")

	say("\n-- with the strip, and with REMOVE --")
	handle.strip(false)
	check(not button.Visible and attrs[ROW] == true and attrs[HAND] == nil and not ltBound(),
		"the strip stepping aside hides HATCH and frees LT; the row stays claimed")
	handle.strip(true)
	check(button.Visible and attrs[HAND] == true and ltBound(), "and it comes back with the strip")
	TrapRemove.claimRow(player, "trap", true)
	handle.slot(nil, nil, nil)
	check(not button.Visible and attrs[ROW] == true and attrs[HAND] == nil and slotButton.NextSelectionUp == nil,
		"the pod put away: HATCH and its link up go, and the row stays while REMOVE claims it")
	TrapRemove.claimRow(player, "trap", false)
	check(attrs[ROW] == nil, "and the row goes once neither claims it")

	say("\n-- due while in the hands --")
	now = Workspace:GetServerTimeNow()
	handle.slot(2, slotButton, { item = "pod-2", hatchAt = now + 0.4 })
	check(not button.Visible and attrs[ROW] == nil, "a pod due in 0.4 s: not yet")
	task.wait(0.8)
	check(button.Visible and handle.offered() and attrs[ROW] == true,
		"and once it is due HATCH stands, with nothing asked to repaint")
	handle.slot(nil, nil, nil)
	check(not ltBound(), "put away again: LT is free")

	say("\n-- the source --")
	local podSrc = sourceOf(Shared, "PodHatch")
	check(has(podSrc, "MenuKit.hold(mb, GameConfig.Plant.HatchHoldSeconds, RATTLE, function()")
			and has(podSrc, "Enum.ContextActionPriority.High.Value, BAG.HandKey)")
			and has(podSrc, 'TrapRemove.claimRow(player, "hatch", want)')
			and has(podSrc, "remote:FireServer(BAG.Hatch, p.item)"),
		"the Bag's hold and the Bag's verb; LT over the default; the row claimed, not written")
	local trapSrc = sourceOf(Shared, "TrapRemove")
	check(has(trapSrc, 'TrapRemove.claimRow(player, "trap", want)')
			and not has(trapSrc, "player:SetAttribute(HOT.RemoveRowAttribute, if want then true else nil)"),
		"REMOVE claims the row too, so neither takes it from the other")
	local panelSrc = sourceOf(Shared, "InventoryPanel")
	local kitSrc = sourceOf(Shared, "MenuKit")
	check(has(panelSrc, "local stop = MenuKit.hold(mb, seconds, RATTLE, done)")
			and has(kitSrc, "function MenuKit.hold(mb: Button, seconds: number, sound: string?, done: () -> ()):")
			and has(kitSrc, "\treturn stop, begin\nend"),
		"the Bag's HATCH and HATCH ALL hold through the same MenuKit.hold")
	check(BAG.HandKey == Enum.KeyCode.ButtonL2 and type(HAND) == "string" and HAND ~= "",
		"LT on a controller (RT plants the pod)")
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local lo = sourceOf(scripts, "LoadoutUI")
	check(has(lo, "podHatch = PodHatch.new(gui, {")
			and has(lo, 'local podId = if isHeld and item and item.kind == "pod" and not item.hatched and item.hatchAt and item.ref')
			and has(lo, "hatch.slot(podSlot, if podSlot and hotSlots[podSlot] then hotSlots[podSlot].button else nil, podHeld)")
			and has(lo, "hatch.strip(hotbar.Visible and not lifted)") and has(lo, "hatch.layout(layout)"),
		"LoadoutUI tells it the pod in the hands, its slot, the strip and the layout -- REMOVE's facts")
	local place = sourceOf(scripts, "PlantPlace")
	check(has(place, "local hatchHint = hint(3, HAND.HandKey, HAND.Words.Hatch)")
			and has(place, "hatchHint.chip.Visible = player:GetAttribute(HAND.HandAttribute) == true")
			and has(place, "player:GetAttributeChangedSignal(HAND.HandAttribute):Connect(paintHatchHint)"),
		"PlantPlace's reticle names LT HATCH beside RT and B, exactly while HATCH stands")
end

local ok, err = pcall(run)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
pcall(function()
	ContextActionService:UnbindAction(PAD_ACTION)
end)
fixture:Destroy()
say(string.format("\nPodHatchSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
