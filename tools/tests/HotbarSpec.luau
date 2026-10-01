--!nocheck
--==============================================================================
-- Steal a Seed :: HotbarSpec
--
-- The hotbar rework (2026-10-01, the owner's brief): the slots are ROLES --
-- bat, trap, Spin Tickets, the active plant or pod, the previous one -- the
-- two plant shortcuts are pointers into the Bag, the Bag's count is plant
-- storage, and the look is the owner's reference. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HotbarSpec"))
--
--   1. the roles      HotbarRoles with stand-in Tools: fixed positions, the
--                     newest plant into an empty active slot only, choosing,
--                     two identical copies as two items, a respawn's re-lease,
--                     a sold plant let go, the storage count
--   2. the card       HotbarCard on a throwaway ScreenGui: the plain number,
--                     the thin edge, the faint empty state, the held state, the
--                     hidden name, no lift or pop under reduced motion
--   3. the layout     HudLayout's name band over the strip, clear of notices
--   4. the wiring     LoadoutUI's source: five keys, HOLD chooses, the equip
--                     guards kept, the count from the profile, TutorialUI's
--                     pointer still finds a slot by its name
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HotbarRoles = require(Shared:WaitForChild("HotbarRoles"))
local HotbarCard = require(Shared:WaitForChild("HotbarCard"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local HOT = GameConfig.Hotbar

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
	local ok, src = pcall(function()
		return found and found.Source
	end)
	return if ok and src then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local function times(src, needle)
	local n, at = 0, 1
	while true do
		local found = string.find(src, needle, at, true)
		if not found then
			return n
		end
		n += 1
		at = found + #needle
	end
end

local layer = Instance.new("ScreenGui")
layer.Name = "ZZHotbarSpec"
layer.Archivable = false

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE ROLES
	--==========================================================================
	say("-- the roles --")
	local R = HotbarRoles.Roles
	check(#R == 5 and R[1] == "bat" and R[2] == "trap" and R[3] == "ticket" and R[4] == "active"
			and R[5] == "previous" and HotbarRoles.roleOf(6) == nil,
		"five roles in a fixed order: bat, trap, tickets, the active plant, the previous one")
	check(HudLayout.Config.DesktopSlots == 5 and HudLayout.Config.MobileSlots == 4,
		"a desktop shows all five and the Bag; a phone the first four and the Bag")

	local function tool(name)
		return { Name = name }
	end
	local KEY = "p:nubkin:1:true"
	local function plant(t, key, order)
		return { tool = t, key = key, kind = "plant", order = order }
	end
	local bat = { tool = tool("Rootwood Bat"), key = "w:rootwood", kind = "bat", order = 1 }
	local trap = { tool = tool("Bramblejaw Trap"), key = "w:bramblejaw", kind = "trap", order = 2 }
	local ticket = { tool = tool("Spin Ticket"), key = "t:spin", kind = "ticket", order = 3 }
	-- Two identical Nubkins: two items.
	local n1, n2 = tool("Nubkin"), tool("Nubkin")
	local live = { bat, trap, ticket, plant(n1, KEY, 4), plant(n2, KEY, 5) }

	local state = {}
	local waiting = HotbarRoles.reconcile(state, live, 100)
	local e = function(st, lv, i)
		return HotbarRoles.entryFor(st, lv, i)
	end
	check(not waiting and e(state, live, 1).kind == "bat" and e(state, live, 2).kind == "trap"
			and e(state, live, 3).kind == "ticket",
		"slots 1 to 3 are the bat, the trap and the tickets, by what the Tool is")
	check(state.active ~= nil and state.active.tool == n2 and state.previous == nil
			and e(state, live, 4).tool == n2 and e(state, live, 5) == nil,
		"an empty active slot takes the NEWEST plant; the previous slot waits for a choice")

	local noBat = { trap, ticket, plant(n1, KEY, 4) }
	local bare = {}
	HotbarRoles.reconcile(bare, noBat, 100)
	check(e(bare, noBat, 1) == nil and e(bare, noBat, 2).kind == "trap" and e(bare, noBat, 3).kind == "ticket"
			and e(bare, noBat, 4).tool == n1,
		"no bat owned: slot 1 is empty IN ITS PLACE, and nothing renumbers")

	-- Choosing.
	HotbarRoles.choose(state, KEY, n1)
	check(state.active.tool == n1 and state.previous.tool == n2,
		"choosing a plant in the Bag makes it the active one; the old active becomes the previous")
	HotbarRoles.choose(state, KEY, n2)
	check(state.active.tool == n2 and state.previous.tool == n1, "choosing the previous one swaps the two")
	HotbarRoles.choose(state, KEY, n2)
	check(state.active.tool == n2 and state.previous.tool == n1, "choosing the active one again changes nothing")
	HotbarRoles.reconcile(state, live, 101)
	check(state.active.tool == n2 and state.previous.tool == n1 and state.active.tool ~= state.previous.tool,
		"two identical copies are two items: one on each shortcut, the same copy never twice")
	local dup = { active = { key = KEY, tool = n1 }, previous = { key = KEY, tool = n1 } }
	HotbarRoles.reconcile(dup, live, 102)
	check(dup.active.tool == n1 and (dup.previous == nil or dup.previous.tool ~= n1),
		"the same copy set in both by hand: the previous is dropped")

	-- Arrivals never take a chosen shortcut.
	local n3 = tool("Bellchime")
	local more = { bat, trap, ticket, plant(n1, KEY, 4), plant(n2, KEY, 5), plant(n3, "p:bellchime:1:true", 9) }
	HotbarRoles.reconcile(state, more, 103)
	check(state.active.tool == n2 and state.previous.tool == n1,
		"a new plant arriving does not replace a chosen shortcut")
	local fresh = {}
	HotbarRoles.reconcile(fresh, more, 104)
	check(fresh.active.tool == n3 and fresh.previous == nil,
		"with nothing chosen, the newest arrival is what the active slot takes")
	check(HotbarRoles.holding(state, n2) == "active" and HotbarRoles.holding(state, n1) == "previous"
			and HotbarRoles.holding(state, n3) == nil,
		"holding says which shortcut has a copy, if any")

	-- A respawn: the Tools vanish, then come back as new instances with the same keys.
	local gone = { bat, trap, ticket }
	local wait1 = HotbarRoles.reconcile(state, gone, 105)
	check(wait1 and state.active ~= nil and state.active.tool == nil and state.previous ~= nil
			and state.previous.tool == nil and e(state, gone, 4) == nil,
		"in a respawn's gap both shortcuts wait with their keys, and show empty")
	local n1b, n2b = tool("Nubkin"), tool("Nubkin")
	local rebuilt = { bat, trap, ticket, plant(n1b, KEY, 11), plant(n2b, KEY, 12) }
	local wait2 = HotbarRoles.reconcile(state, rebuilt, 106)
	local a, p = state.active.tool, state.previous.tool
	check(not wait2 and a ~= nil and p ~= nil and a ~= p and (a == n1b or a == n2b) and (p == n1b or p == n2b),
		"and re-lease the rebuilt copies by key within the grace, one copy each")

	-- Sold: one copy never comes back.
	local sold = { bat, trap, ticket, plant(n2b, KEY, 12) }
	HotbarRoles.reconcile(state, sold, 107)
	local lostOne = (state.active and state.active.tool == nil) or (state.previous and state.previous.tool == nil)
	HotbarRoles.reconcile(state, sold, 107 + HotbarRoles.Grace + 1)
	check(lostOne and state.active ~= nil and state.active.tool == n2b and state.previous == nil,
		"a plant sold stays gone: after the grace its shortcut is let go, and the last plant steps up to active")

	-- The previous slot by a drop, and a swap.
	local two = { bat, trap, ticket, plant(n1b, KEY, 11), plant(n2b, KEY, 12) }
	HotbarRoles.reconcile(state, two, 120)
	HotbarRoles.setPrevious(state, KEY, n1b)
	check(state.active.tool == n2b and state.previous.tool == n1b, "a plant dropped on slot 5 is the previous one")
	HotbarRoles.setPrevious(state, KEY, n2b)
	check(state.active.tool == n1b and state.previous.tool == n2b,
		"dropping the active one on slot 5 swaps the two rather than doubling it")
	HotbarRoles.swap(state)
	check(state.active.tool == n2b and state.previous.tool == n1b, "a slot dropped on the other slot swaps them")
	HotbarRoles.clear(state, "previous")
	HotbarRoles.reconcile(state, two, 121)
	check(state.active.tool == n2b and state.previous == nil, "clearing the previous slot leaves the active one alone")

	-- Storage, as the Bag cell shows it.
	local t0, f0, k0 = HotbarRoles.storage(nil, false, 24)
	local t1, f1, k1 = HotbarRoles.storage(7, false, 24)
	local t2, f2, k2 = HotbarRoles.storage(23, true, 24)
	local t3, f3 = HotbarRoles.storage(24, false, 24)
	check(t0 == "…" and not f0 and not k0, "before the profile arrives there is no number, not a misleading 0/24")
	check(t1 == "7/24" and not f1 and k1 and t2 == "24/24" and f2 and k2 and t3 == "24/24" and f3,
		"the count is the saved rows plus the raid pod in both arms, out of Save.MaxHeld; full at the limit")
	check(GameConfig.Save.MaxHeld == 24, "the limit is the one the server enforces")

	--==========================================================================
	-- 2. THE CARD
	--==========================================================================
	say("\n-- the card --")
	layer.Parent = StarterGui
	local card = HotbarCard.build(layer, 4, HOT, 4)
	local numberKids = 0
	for _, kid in ipairs(card.number:GetChildren()) do
		if kid:IsA("GuiObject") or kid:IsA("UICorner") then
			numberKids += 1
		end
	end
	check(card.holder.Name == "Slot4" and card.holder.Parent == layer and card.button.Name == "Face"
			and card.number.Name == "Number" and card.number.Font == Enum.Font.FredokaOne
			and card.number.TextColor3 == HOT.Numeral and card.number.BackgroundTransparency == 1 and numberKids == 0
			and card.number.TextXAlignment == Enum.TextXAlignment.Left,
		"the number is plain white text in the top-left corner: no badge, no circle")
	check(card.stroke.Thickness == HOT.CardStroke and card.stroke.Color == HOT.Edge
			and card.faceCorner.CornerRadius.Offset == HOT.CardCorner
			and card.button.BackgroundColor3 == HOT.Plate
			and math.abs(card.button.BackgroundTransparency - HOT.PlateTransparency) < 1e-4
			and card.holder.Size.X.Offset == HOT.SlotWidth and card.holder.Size.Y.Offset == HOT.SlotHeight,
		"a square translucent charcoal plate with a thin light edge and small corners")
	check(card.name.Visible == false and card.name.TextTransparency == 1
			and card.preview.holder.Size.Y.Offset == HOT.PreviewHeight,
		"no name on the slot -- the label is there, hidden, for the pointer -- and a big preview")
	HotbarCard.paint(card, HOT, { empty = true, held = false, number = "4", name = "" })
	check(math.abs(card.button.BackgroundTransparency - HOT.EmptyPlateTransparency) < 1e-4
			and math.abs(card.stroke.Transparency - HOT.EmptyEdgeTransparency) < 1e-4
			and math.abs(card.number.TextTransparency - HOT.EmptyNumeralTransparency) < 1e-4
			and card.number.Text == "4" and not card.stack.Visible and not card.accent.Visible,
		"an empty slot is barely there, its number faint and in place")
	local rarity = Color3.fromRGB(200, 120, 255)
	HotbarCard.paint(card, HOT, { empty = false, held = true, number = "4", stack = "x5", accent = rarity, name = "Nubkin" })
	check(card.ringTint.Enabled and card.stroke.Thickness == HOT.LitThickness and card.stroke.Transparency == 0
			and card.number.TextColor3 == HOT.NumeralLit
			and math.abs(card.button.BackgroundTransparency - HOT.LitPlateTransparency) < 1e-4
			and card.stack.Visible and card.stack.Text == "x5" and card.accent.Visible
			and card.accent.BackgroundColor3 == rarity and card.name.Text == "Nubkin" and not card.name.Visible,
		"in hand: the warm edge, a lighter plate, an amber number; the stack count and the rarity bar where they apply")
	HotbarCard.paint(card, HOT, { empty = false, held = false, number = "4", name = "Nubkin" })
	check(not card.ringTint.Enabled and card.stroke.Thickness == HOT.CardStroke
			and math.abs(card.stroke.Transparency - HOT.EdgeTransparency) < 1e-4 and not card.stack.Visible
			and not card.accent.Visible,
		"and back to plain")
	HotbarCard.lift(card, true, true, HOT)
	HotbarCard.bump(card, true, HOT)
	check(card.wrap.Position.Y.Offset == 0 and card.bumpScale.Scale == 1,
		"reduced motion: no lift and no pop")
	HotbarCard.lift(card, true, false, HOT)
	check(card.liftGoal == -HOT.HeldLift, "otherwise the held slot lifts")
	local seconds = HotbarCard.flash(card, HOT.FlashArrived, HOT)
	check(seconds > HOT.FlashSeconds and card.stroke.Color == HOT.FlashArrived and card.flashUntil > os.clock(),
		"a flash takes the edge for a third of a second and says how long")
	local stackWidth = TextService:GetTextSize("x999", HOT.StackSize, Enum.Font.FredokaOne, Vector2.new(400, 40)).X
	check(stackWidth <= HOT.SlotWidth - HOT.StackInset * 2 - HOT.NumeralInset,
		"a three-figure stack count fits the slot's corner", stackWidth)
	local cardSrc = sourceOf(Shared, "HotbarCard")
	check(not has(cardSrc, "RenderStepped:") and not has(cardSrc, "Heartbeat:") and not has(cardSrc, ":Connect(")
			and not has(cardSrc, "task.wait") and not has(cardSrc, "while "),
		"the card listens to nothing and runs on no clock")

	--==========================================================================
	-- 3. THE LAYOUT: the name band over the strip
	--==========================================================================
	say("\n-- the layout --")
	local function screen(w, h, opts)
		opts = opts or {}
		return {
			safe = Vector2.new(w, h - 58),
			viewport = Vector2.new(w, h),
			-- The topbar's free span, as HudLayout.measure reports it.
			topbar = { x = 110, y = 0, w = w - 110, h = 58 },
			insetTop = 58,
			touch = opts.touch == true,
			keyboard = opts.keyboard ~= false,
		}
	end
	-- HudLayoutSpec's listed phones and three desktops. (Studio's 705 x 338
	-- emulation is not a listed phone: its weapon chooser meets the jump
	-- button at any belt height, which the layout reports as not fitting.)
	local bands = 0
	for _, size in ipairs({ { 1280, 720, false }, { 1920, 1080, false }, { 1000, 609, false },
		{ 801, 392, true }, { 896, 414, true }, { 772, 360, true }, { 874, 402, true } }) do
		local L = HudLayout.solve(screen(size[1], size[2], { touch = size[3] }))
		local band = L.namePopup
		local okBand = band.x == L.hotbar.x and band.w == L.hotbar.w and band.h == HOT.NamePopupHeight
			and band.y + band.h + HOT.NamePopupGap == L.hotbar.y
			and (L.toastTop or L.toast.y + L.toast.h + 8 <= band.y)
			and HudLayout.gap(band, L.cash) >= 8 and HudLayout.gap(band, L.equipment) >= 8
			and #HudLayout.problems(L) == 0
		if okBand then
			bands += 1
		end
	end
	check(bands == 7, "on every listed screen the name band stands over the strip, clear of the notices, the cash and BAT/TRAP, with nothing overlapping", bands)

	--==========================================================================
	-- 4. THE WIRING
	--==========================================================================
	say("\n-- the wiring --")
	local lo = sourceOf(Scripts, "LoadoutUI")
	local keys = string.match(lo, "local KEYS = {(.-)}") or ""
	check(has(keys, "Enum.KeyCode.Five") and not has(keys, "Enum.KeyCode.Six") and not has(keys, "Enum.KeyCode.Zero")
			and has(lo, "if i <= activeSlots then"),
		"keys 1 to 5, bound to the slots' positions; 6 to 0 are not bound")
	check(has(lo, "if row.kind == \"plant\" then\n\t\t\t\tchooseShortcut(row.tool)\n\t\t\tend\n\t\t\tholdTool(row.tool)")
			and has(lo, "HotbarRoles.choose(shortcuts, data.key, data.tool)"),
		"HOLD on a Bag card makes the plant the active shortcut, then puts it in the hands, through the one equip path")
	check(not has(lo, "returnToBag") and not has(lo, "DOUBLE_WINDOW") and not has(lo, "claimed[")
			and has(lo, "if slot.kind == \"plant\" then\n\t\t\t\tlocal tier"),
		"no double-tap return: every stored plant stays listed in the Bag, the two on the strip included")
	local holdAt = string.find(lo, "local function holdTool(", 1, true)
	local carryAt = holdAt and string.find(lo, 'raise("CARRYING_POD")', holdAt, true)
	local sealedAt = holdAt and string.find(lo, "if HatchRoll.sealed(tool) then", holdAt, true)
	local equipAt = holdAt and string.find(lo, "humanoid:EquipTool(tool)", holdAt, true)
	check(carryAt ~= nil and sealedAt ~= nil and equipAt ~= nil and carryAt < equipAt and sealedAt < equipAt
			and times(lo, "EquipTool(tool)") == 1 and times(lo, 'raise("CARRYING_POD")') == 1,
		"the equip guards are kept: a plant is refused while a pod is carried or its roll runs, and holdTool is the only equip")
	check(has(lo, "HotbarRoles.storage(heldRows,") and has(lo, "heldRows = #profile.Held")
			and has(lo, "player:GetAttribute(ATTR.CarryingSpecies) ~= nil, GameConfig.Save.MaxHeld)")
			and has(lo, "HOT.CountLoading"),
		"the Bag cell counts the profile's saved rows plus a carried pod against Save.MaxHeld, and says nothing before the profile")
	check(has(lo, "announce(held.Name, false)") and has(lo, "button.MouseEnter:Connect(") and has(lo, "ReducedMotionEnabled")
			and has(lo, 'player:GetAttribute("SeedAfterimageQuality") == "Off"'),
		"the name shows over the strip on an equip and under a mouse, and reduced motion is honoured")
	check(has(lo, "pendingArrivals[child] = true") and has(lo, "quietUntil = os.clock() + 3")
			and has(lo, "HotbarCard.bump(shown.card, still, HOT)"),
		"an arrival pops its slot or the Bag, and a spawn's rebuild is not an arrival")
	check(has(lo, "PadInput.nextSlot(occupiedSlots()") and has(lo, 'BindAction("SeedHotbarCycle"'),
		"LB and RB still walk the occupied slots")
	check(not has(lo, "HotbarTray") and has(lo, "HotbarCard.build(hotbar, index, HOT, 4)")
			and times(lo, 'hotbar.Name = "Hotbar"') == 1,
		"one strip, no tray, every slot a HotbarCard")
	local tut = sourceOf(Scripts, "TutorialUI")
	check(has(tut, 'loadout:FindFirstChild("Hotbar")') and has(tut, "for _, kid in slot:GetDescendants() do")
			and has(tut, 'kid:IsA("TextLabel") and string.upper(kid.Text) == want') and has(cardSrc, 'name.Name = "Name"'),
		"the guide's pointer still finds a plant's slot by the hidden name label")
end)

layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nHotbarSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
