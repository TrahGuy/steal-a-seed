--!nocheck
--==============================================================================
-- Steal a Seed :: SpeedShoeSpec
-- THE HUD SPEED SHOE, BIGGER, AND ITS "+" OPENS THE SHOP AT SPEED (the owner,
-- 2026-10-08: "make the speedhud logo bigger" -- the shoe, not the number --
-- "and connect that +sign to the speed section in the shop"). Edit mode:
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SpeedShoeSpec"))
--
--   bigger    the shoe CashUI draws is at least 1.4x the old one, on every face
--   in place  the drawn shoe and its badge stay inside the block, short of the
--             Speed number, its foot level with the Speed line's
--   press     the "+"'s press is at least the x2 card's touch area on every
--             face, inside the 8 px HudLayout keeps round the block, and short
--             of the number on a desktop
--   shop      the press fires ShopUI's OpenAt with the Speed shelf's id, which
--             GameConfig.Store.Sections has; ShopUI opens and scrolls to it
-- Pure numbers and CashUI's / ShopUI's own source: nothing is built.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))

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
local function sourceOf(name)
	local found = StarterPlayer:FindFirstChild(name, true)
	local ok, text = pcall(function()
		return found.Source
	end)
	return if ok and type(text) == "string" then text else ""
end
local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

-- The owner's shoe art (art/ui-icons/training-assets-2026-10-08/01-plain-speed-
-- shoe-transparent-512.png, uploaded as GameConfig.SourceIcons.speed): what of
-- its 512 square is drawn, measured off the alpha channel.
local ART = { left = 32 / 512, top = 84 / 512, right = 485 / 512, bottom = 431 / 512 }

local ok, err = pcall(function()

local cash = sourceOf("CashUI")
local shop = sourceOf("ShopUI")
local picture, drop = string.match(cash, "local PICTURE, PICTURE_DROP = (%d+), (%d+)")
picture, drop = tonumber(picture), tonumber(drop)
local bx, by = string.match(cash, "badge.Position = UDim2.fromOffset%((%d+), (%d+)%)")
bx, by = tonumber(bx), tonumber(by)
local badgeSize = tonumber(string.match(cash, "badge.Size = UDim2.fromOffset%((%d+), %d+%)"))
check(picture ~= nil and drop ~= nil and bx ~= nil and badgeSize ~= nil
		and has(cash, "shoePicture.Size = UDim2.fromOffset(PICTURE, PICTURE)")
		and has(cash, "shoePicture.Position = UDim2.fromOffset(0, 38 + PICTURE_DROP - PICTURE)"),
	"CashUI draws the shoe in a PICTURE box hanging PICTURE_DROP under its 50 x 38 box",
	tostring(picture) .. " / " .. tostring(drop))

--==============================================================================
say("-- 1. bigger, and in its place, on every face --")
local faces = HudLayout.Config.CashStyle
for _, name in ipairs({ "Desktop", "Compact", "Phone" }) do
	local f = faces[name]
	local s = f.ShoeScale
	local boxTop = f.ShoeBottom - 38 * s
	local picTop = boxTop + (38 + drop - picture) * s
	local left, right = picture * ART.left * s, picture * ART.right * s
	local top, bottom = picTop + picture * ART.top * s, picTop + picture * ART.bottom * s
	local oldW, oldH = 38 * (ART.right - ART.left) * s, 38 * (ART.bottom - ART.top) * s
	local w, h = right - left, bottom - top
	check(w >= 1.4 * oldW and h >= 1.4 * oldH,
		string.format("%s: the shoe draws %.1f x %.1f, %.2fx the old %.1f x %.1f", name, w, h, w / oldW, oldW, oldH))
	check(left >= 0 and right <= f.SpeedX - 1 and top >= 0 and bottom <= f.ShoeBottom + 0.5,
		string.format("%s: it stays in the block -- x %.1f-%.1f short of the number at %d, y %.1f-%.1f, foot at the "
			.. "Speed line's %d", name, left, right, f.SpeedX, top, bottom, f.ShoeBottom))
	local badgeRight = (bx + badgeSize) * s
	local badgeBottom = boxTop + (by + badgeSize) * s
	check(badgeRight <= f.SpeedX - 1 and badgeBottom <= f.ShoeBottom + 0.5 and (bx + badgeSize) * s > right - 12 * s,
		string.format("%s: the badge sits over the shoe's bottom-right, its edge at %.1f short of the number", name,
			badgeRight))
	-- The press, as CashUI's applyStyle sizes it: from (-8, -8).
	local pressW = math.max(f.SpeedX - 2, f.BuffHit - 8) + 8
	local pressH = math.max(f.ShoeBottom, f.BuffHit - 8) + 8
	check(pressW >= f.BuffHit and pressH >= f.BuffHit and pressW >= 44 and pressH >= 44,
		string.format("%s: the \"+\"'s press is %d x %d, at least the x2 card's %d touch area", name, pressW, pressH,
			f.BuffHit))
	if name == "Desktop" then
		check(pressW - 8 <= f.SpeedX - 2 and pressH - 8 <= f.ShoeBottom,
			"Desktop: the press ends short of the number and at the shoe's foot")
	end
end
check(HudLayout.Config.Margin >= 8
		and has(cash, "speedHit.Position = UDim2.fromOffset(-8, -8)")
		and has(cash, "speedHit.Size = UDim2.fromOffset(math.max(want.SpeedX - 2, want.BuffHit - 8) + 8,")
		and has(cash, "math.max(want.ShoeBottom, want.BuffHit - 8) + 8)"),
	"the press reaches only into the 8 px HudLayout keeps clear round the block, sized from the face in applyStyle")
check(has(cash, "shoePicture.Image = SizedIcon.at(GameConfig.SourceIcons.speed, PICTURE * style.ShoeScale)")
		and has(cash, "SizedIcon.follow(shoePicture)"),
	"the picture swaps to the owner's small shoe at the size it draws (SizedIcon), as before")

--==============================================================================
say("-- 2. the \"+\" opens the Shop at SPEED --")
local speedShelf = nil
for _, section in ipairs(GameConfig.Store.Sections) do
	if section.id == "Speed" then
		speedShelf = section
	end
end
check(speedShelf ~= nil and has(cash, 'local SPEED_SHELF = "Speed"') and has(cash, "openAt:Fire(SPEED_SHELF)")
		and has(cash, 'local shop = playerGui:FindFirstChild("SeedShop")')
		and has(cash, 'local openAt = shop and shop:FindFirstChild("OpenAt")'),
	"the press fires the Shop's OpenAt with the Speed shelf's id (GameConfig.Store.Sections)")
check(has(cash, "speedHit.Selectable = false") and has(cash, "speedHit.Activated:Connect("),
	"a mouse, a finger or a tap presses it; a controller keeps the rail's Shop button")
check(has(shop, 'openAt.Name = "OpenAt"') and has(shop, "openAt.Parent = gui")
		and has(shop, "local section = sections[tostring(categoryId)]")
		and has(shop, "setOpen(true)")
		and has(shop, "grid.CanvasPosition = Vector2.new(0, math.max(0, y))"),
	"ShopUI opens on OpenAt and puts that shelf's heading at the top of the page")

end)
if not ok then
	fail += 1
	say("  ERROR " .. tostring(err))
end
say(string.format("\nSpeedShoeSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
