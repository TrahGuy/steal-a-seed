--!nocheck
--==============================================================================
-- Steal a Seed :: HotbarSpec
--
-- The freely assignable hotbar (2026-10-03, the owner's spec), replacing the
-- fixed roles of 2026-10-01: any eligible item in any slot, ten on a desktop
-- (keys 1-9 and 0), five on a phone, saved by item id on the server; the look
-- is still the owner's reference. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HotbarSpec"))
--
--   1. the count      ten and five, from HudLayout
--   2. the card       HotbarCard on a throwaway ScreenGui: the plain number,
--                     the thin edge, the faint empty state, the held state, the
--                     hidden name, a faint slot's word, restoring, a pending
--                     equip, assign mode's target; no lift or pop under reduced
--                     motion
--   3. the layout     HudLayout's name band over the strip, clear of notices,
--                     on every listed screen
--   4. the wiring     LoadoutUI's source: ten keys gated by what is shown, one
--                     sender for the bar and one for the hearts, arrivals read
--                     off the profile, a silent equip refusal, the equip guards
--                     kept, a local budget, TutorialUI's pointer
--
-- The grammar is HotbarSlotsSpec's; the server's half InventorySpec's; what the
-- Bag shows InventoryModelSpec's.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
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
-- Names a chunk declares at its top level: every `local` at column 0, each name
-- of a `local a, b` counted (commas inside braces or brackets are a type's).
local function topLevelNames(src)
	local n = 0
	for line in string.gmatch(src, "[^\n]+") do
		if string.sub(line, 1, 6) == "local " then
			if string.sub(line, 1, 15) == "local function " then
				n += 1
			else
				local decl = string.match(line, "^local%s+(.-)%s*=") or string.sub(line, 7)
				local depth, names = 0, 1
				for i = 1, #decl do
					local c = string.sub(decl, i, i)
					if c == "{" or c == "(" or c == "<" then
						depth += 1
					elseif c == "}" or c == ")" or c == ">" then
						depth -= 1
					elseif c == "," and depth == 0 then
						names += 1
					end
				end
				n += names
			end
		end
	end
	return n
end

local layer = Instance.new("ScreenGui")
layer.Name = "ZZHotbarSpec"
layer.Archivable = false

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE COUNT
	--==========================================================================
	say("-- the count --")
	check(HudLayout.Config.DesktopSlots == 10 and HudLayout.Config.MobileSlots == 5
			and GameConfig.Inventory.Slots == 10,
		"ten slots on a desktop (keys 1-9 and 0), five on a phone, ten saved")
	check(not Shared:FindFirstChild("HotbarRoles"), "the fixed roles are gone")

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
			and card.number.Text == "4" and not card.stack.Visible and not card.accent.Visible
			and not card.ghost.Visible,
		"an empty slot is barely there, its number faint and in place")
	HotbarCard.paint(card, HOT, { empty = true, held = false, number = "0", name = "", ghost = HOT.Tags.bat.text })
	check(card.ghost.Visible and card.ghost.Text == "BAT" and card.number.Text == "0"
			and math.abs(card.ghost.TextTransparency - HOT.EmptyNumeralTransparency) < 1e-4,
		"a FAINT slot says, quietly, what it waits for; the tenth slot is numbered 0")
	check(HOT.Tags.ticket and HOT.Tags.trap and TextService:GetTextSize(HOT.Tags.ticket.text, HOT.Compact.NumeralSize,
		Enum.Font.FredokaOne, Vector2.new(400, 40)).X <= HOT.Compact.SlotWidth - 6,
		"every faint word fits a phone's slot")
	local rarity = Color3.fromRGB(200, 120, 255)
	HotbarCard.paint(card, HOT, { empty = false, held = true, number = "4", stack = "x5", accent = rarity, name = "Nubkin" })
	check(card.ringTint.Enabled and card.stroke.Thickness == HOT.LitThickness and card.stroke.Transparency == 0
			and card.number.TextColor3 == HOT.NumeralLit
			and math.abs(card.button.BackgroundTransparency - HOT.LitPlateTransparency) < 1e-4
			and card.stack.Visible and card.stack.Text == "x5" and card.accent.Visible
			and card.accent.BackgroundColor3 == rarity and card.name.Text == "Nubkin" and not card.name.Visible
			and not card.ghost.Visible,
		"in hand: the warm edge, a lighter plate, an amber number; the stack count and the rarity bar where they apply")
	HotbarCard.paint(card, HOT, { empty = false, held = false, number = "4", name = "Nubkin" })
	check(not card.ringTint.Enabled and card.stroke.Thickness == HOT.CardStroke
			and math.abs(card.stroke.Transparency - HOT.EdgeTransparency) < 1e-4 and not card.stack.Visible
			and not card.accent.Visible and card.preview.hero.ImageTransparency == 0,
		"and back to plain")
	HotbarCard.paint(card, HOT, { empty = false, held = false, number = "4", name = "Nubkin", restoring = true })
	check(card.preview.hero.ImageTransparency > 0.5, "restoring after a respawn: the item is drawn dimmed")
	HotbarCard.paint(card, HOT, { empty = false, held = false, number = "1", name = "Rootwood Bat", pending = true })
	check(card.stroke.Color == HOT.LitTop and card.stroke.Transparency < HOT.EdgeTransparency,
		"a weapon asked of the server wears a soft amber edge until it lands")
	HotbarCard.paint(card, HOT, { empty = true, held = false, number = "4", name = "", target = true })
	check(card.stroke.Color == Color3.new(1, 1, 1) and card.stroke.Transparency == 0 and not card.ringTint.Enabled,
		"while a phone assigns, every slot wears a bright edge, empty ones too")
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
			safe = Vector2.new(w - (opts.sides or 0) * 2, h - 58),
			viewport = Vector2.new(w, h),
			-- The topbar's free span, as HudLayout.measure reports it.
			topbar = { x = 110, y = 0, w = w - 110, h = 58 },
			insetTop = 58,
			touch = opts.touch == true,
			keyboard = opts.keyboard ~= false,
		}
	end
	-- HudLayoutSpec's listed phones, the three it added for the free hotbar --
	-- Studio's 705 x 338 among them, which only failed before for the chooser --
	-- and three desktops.
	local bands, cases = 0, {
		{ 1280, 720, false }, { 1920, 1080, false }, { 1000, 609, false }, { 1366, 768, false },
		{ 801, 392, true }, { 896, 414, true }, { 772, 360, true }, { 874, 402, true },
		{ 705, 338, true }, { 640, 360, true }, { 844, 390, true, 47 },
	}
	local bad = {}
	for _, size in ipairs(cases) do
		local L = HudLayout.solve(screen(size[1], size[2], { touch = size[3], sides = size[4] }))
		local band = L.namePopup
		local okBand = band.x == L.hotbar.x and band.w == L.hotbar.w and band.h == HOT.NamePopupHeight
			and band.y + band.h + HOT.NamePopupGap == L.hotbar.y
			and (L.toastTop or L.toast.y + L.toast.h + 8 <= band.y)
			and HudLayout.gap(band, L.cash) >= 8
			and #HudLayout.problems(L) == 0
			and L.slots == (if size[3] then 5 else 10)
		if okBand then
			bands += 1
		else
			table.insert(bad, size[1] .. "x" .. size[2] .. ": " .. table.concat(HudLayout.problems(L), "; "))
		end
	end
	check(bands == #cases, "on every listed screen the name band stands over the strip, clear of the notices and the "
		.. "cash, with nothing overlapping, and the count is ten or five", table.concat(bad, " | "))

	--==========================================================================
	-- 4. THE WIRING
	--==========================================================================
	say("\n-- the wiring --")
	local lo = sourceOf(Scripts, "LoadoutUI")
	local keys = string.match(lo, "local KEYS = {(.-)}") or ""
	check(has(keys, "Enum.KeyCode.Nine") and has(keys, "Enum.KeyCode.Zero") and times(keys, "Enum.KeyCode.") == 10
			and has(lo, "if i <= activeSlots then"),
		"keys 1-9 and 0, bound to the slots' positions, and only for slots on screen")
	check(has(lo, 'return if i == 10 then "0" else tostring(i)'), "the tenth slot is numbered 0")
	check(times(lo, "FireServer(INV.SetAction") == 1 and times(lo, "FireServer(INV.FavouriteAction") == 1
			and times(lo, "FireServer(W.EquipAction") == 1,
		"one sender for the bar, one for the hearts, and the shop's one equip verb")
	check(has(lo, "HotbarSlots.arrivals(before, now)") and has(lo, "HotbarSlots.arrive(working, ref, activeSlots)")
			and has(lo, "local before = prof.owned"),
		"arrivals are what the profile owns now and did not before; the first packet is only the baseline")
	local refusal = string.match(lo, "if action == W%.EquipAction and ok == false(.-)\nend") or ""
	check(refusal ~= "" and not has(refusal, "SoundKit"),
		"an equip refusal only clears the wait -- MarigoldShopUI already plays Denied")
	check(has(lo, "bar.pending = nil") and has(lo, "task.delay(2, function()"),
		"an edit the server does not answer within two seconds gives way to the server's bar")
	local holdAt = string.find(lo, "local function holdTool(", 1, true)
	local carryAt = holdAt and string.find(lo, 'raise("CARRYING_POD")', holdAt, true)
	local sealedAt = holdAt and string.find(lo, "if HatchRoll.sealed(tool) then", holdAt, true)
	local equipAt = holdAt and string.find(lo, "humanoid:EquipTool(tool)", holdAt, true)
	check(carryAt ~= nil and sealedAt ~= nil and equipAt ~= nil and carryAt < equipAt and sealedAt < equipAt
			and times(lo, "EquipTool(tool)") == 1 and times(lo, 'raise("CARRYING_POD")') == 1,
		"the equip guards are kept: a plant is refused while a pod is carried or its roll runs, and holdTool is the only equip")
	local activate = string.match(lo, "activateKey = function(.-)\nend\n") or ""
	local holdCall = string.find(activate, "holdRef(ref)", 1, true)
	local arriveCall = string.find(activate, "HotbarSlots.arrive(", 1, true)
	check(holdCall ~= nil and arriveCall ~= nil and holdCall < arriveCall
			and has(activate, "if not (done and ref) or HotbarSlots.slotOf(shownBar(), ref) then"),
		"a tile press holds first, through the guards, and assigns only what was held and has no slot")
	check(has(lo, "HotbarSlots.storage(rows,") and has(lo, "player:GetAttribute(ATTR.CarryingSpecies) ~= nil, GameConfig.Save.MaxHeld)")
			and has(lo, "HOT.CountLoading"),
		"the Bag cell counts the profile's saved rows plus a carried pod against Save.MaxHeld, and says nothing before the profile")
	check(has(lo, "announce(if item then visibleName(item) else HatchRoll.shownName(held), false)")
			and has(lo, "button.MouseEnter:Connect(") and has(lo, "ReducedMotionEnabled")
			and has(lo, 'player:GetAttribute("SeedAfterimageQuality") == "Off"'),
		"the visible name (never ???) shows over the strip on an equip and under a mouse, and reduced motion is honoured")
	check(has(lo, "PadInput.nextSlot(occupiedSlots()") and has(lo, 'BindAction("SeedHotbarCycle"'),
		"LB and RB still walk the occupied slots")
	check(not has(lo, "HotbarTray") and has(lo, "HotbarCard.build(hotbar, index, HOT, 4)")
			and times(lo, 'hotbar.Name = "Hotbar"') == 1 and not has(lo, "HotbarRoles"),
		"one strip, no tray, every slot a HotbarCard, and no roles")
	check(not has(lo, "chooser") and not has(lo, "sideSlots") and not has(lo, "layout.equipment"),
		"no BAT/TRAP column, no phone sidebar, no chooser")
	local names = topLevelNames(lo)
	check(names <= 150, "LoadoutUI's top level stays well inside Luau's 200 locals", names)
	local quiet = true
	for _, module in ipairs({ "HotbarSlots", "InventoryModel", "PressGesture", "InventoryTile", "ItemArt",
		"InventoryPanel", "RarityFX" }) do
		local src = sourceOf(Shared, module)
		if src == "" or has(src, "RenderStepped") or has(src, "Heartbeat") or has(src, "BindToRenderStep")
			or has(src, "while true") then
			quiet = false
		end
	end
	check(quiet, "no new module runs per frame")
	local tut = sourceOf(Scripts, "TutorialUI")
	check(has(tut, 'loadout:FindFirstChild("Hotbar")') and has(tut, "for _, kid in slot:GetDescendants() do")
			and has(tut, 'kid:IsA("TextLabel") and string.upper(kid.Text) == want') and has(cardSrc, 'name.Name = "Name"')
			and has(lo, "name = if item and item.tool then HatchRoll.shownName(item.tool)"),
		"the guide's pointer still finds a plant's slot by the hidden name label, the Tool's own")
end)

layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nHotbarSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
