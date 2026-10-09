--!nocheck
--==============================================================================
-- Steal a Seed :: StuddedLookSpec
--
-- The studded UI kit's look on the Shop and Settings (2026-10-08, the owner:
-- "restyle the shop and settings first"). Edit mode:
--
--   1. the tokens: GameConfig.StuddedLook carries the kit's own values, read
--      off the owner's StuddedUI-Free.rbxm (the stud tile, its two
--      transparencies, each menu's band and edge, the close)
--   2. the theme: MenuKit.studdedTheme builds UIKit.modal's band from them
--   3. a real UIKit.modal built here with that theme: no lift, the band and
--      the white body and the close plate each wearing the stud tile, the
--      outline and a solid base in the edge colour, a white title -- and one
--      built with the rim theme carries none of it
--   4. the wiring: the Shop and Settings take the band, every other menu keeps
--      the rim, the Shop's green plate is not drawn, Settings' rows are the
--      kit's dark blue strips
--
-- Not here, seen in Play instead: what it looks like.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CoreGui = game:GetService("CoreGui")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))

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
	local found = Scripts:FindFirstChild(name)
	local ok, src = pcall(function()
		return found and found.Source
	end)
	return if ok and src then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local function same(a, b)
	return typeof(a) == "Color3" and typeof(b) == "Color3" and math.abs(a.R - b.R) < 1e-3
		and math.abs(a.G - b.G) < 1e-3 and math.abs(a.B - b.B) < 1e-3
end

local S = GameConfig.StuddedLook

--==============================================================================
say("1. The kit's own values")
--==============================================================================
check(S.Texture == "rbxassetid://118347284107187" and S.Tile == 90, "the kit's stud tile, tiled at 90 px")
check(S.BandStuds == 0.5 and S.BodyStuds == 0.85, "over a band at 0.5, over the white body at 0.85")
check(same(S.Shop.Band, rgb(255, 53, 67)) and same(S.Shop.Edge, rgb(133, 13, 27)), "the Shop: the kit's red band, its dark red edge")
check(same(S.Settings.Band, rgb(24, 143, 255)) and same(S.Settings.Edge, rgb(0, 57, 132))
		and same(S.Settings.Row, rgb(23, 89, 165)), "Settings: the kit's blue band, its dark blue edge and rows")
check(same(S.Close, rgb(255, 32, 70)) and same(S.CloseEdge, rgb(120, 10, 28)), "the close: the kit's red, its dark red edge")

--==============================================================================
say("2. The theme")
--==============================================================================
local theme = MenuKit.studdedTheme(S.Shop)
check(theme.band == true and theme.rim == nil and theme.lift == nil, "a band: no rim, no lift")
check(same(theme.headerTop, S.Shop.Band) and same(theme.headerBottom, S.Shop.Band) and same(theme.outline, S.Shop.Edge),
	"the band is the menu's colour, the outline its edge")
check(theme.texture and theme.texture.image == S.Texture and theme.texture.band == S.BandStuds
		and theme.texture.body == S.BodyStuds and theme.base == S.Base, "the stud tile on band and body, and the base")
check(same(theme.closeTop, S.Close) and same(theme.closeEdge, S.CloseEdge) and same(theme.closeMarkLine, S.TitleLine),
	"the kit's close: red, its own edge, a black X line")

--==============================================================================
say("3. A real modal, built here")
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ZZStuddedLookSpec"
gui.Parent = CoreGui
local ok, err = pcall(function()
	local m = UIKit.modal(gui, { name = "ZZBand", title = "SHOP", titleColour = S.Title, theme = theme, fixedHeader = true })
	local shell = m.shell
	local body = shell:FindFirstChild("StudTexture")
	check(m.lift == 0, "no lift: the band is the panel's own top", m.lift)
	check(body and body:IsA("ImageLabel") and body.Image == S.Texture and body.ScaleType == Enum.ScaleType.Tile
			and math.abs(body.ImageTransparency - S.BodyStuds) < 1e-4 and body.TileSize == UDim2.fromOffset(S.Tile, S.Tile),
		"the white body wears the stud tile, faint")
	local base = shell:FindFirstChild("Base")
	check(base and base.ZIndex == 0 and same(base.BackgroundColor3, S.Shop.Edge) and base.Position == UDim2.fromOffset(0, S.Base),
		"a solid base in the edge colour stands Base px out under the shell")
	check(shell.Size == UDim2.new(1, -GameConfig.Rail.OutlineThickness * 2, 1, -GameConfig.Rail.OutlineThickness * 2 - S.Base),
		"and the shell gives those px up at its foot", shell.Size)
	local edge = shell:FindFirstChildOfClass("UIStroke")
	check(edge and same(edge.Color, S.Shop.Edge), "the outline is the edge colour")
	local banner = shell:FindFirstChild("HeaderBanner")
	local bandTex = banner and banner:FindFirstChild("StudTexture")
	check(bandTex and bandTex.ImageTransparency == S.BandStuds, "the band wears the stud tile at 0.5")
	local plate = m.close:FindFirstChild("Plate")
	local plateTex = plate and plate:FindFirstChild("StudTexture")
	local plateEdge = plate and plate:FindFirstChildOfClass("UIStroke")
	check(plateTex and plateEdge and same(plateEdge.Color, S.CloseEdge), "the close plate: studded, with the kit's own edge")
	check(same(m.title.TextColor3, S.Title), "a white title")
	local lattice = shell:FindFirstChild("Lattice")
	check(lattice == nil, "no lattice on a band's body")

	local rim = UIKit.modal(gui, { name = "ZZRim", title = "BAG", theme = MenuKit.rimTheme(), fixedHeader = true })
	check(rim.shell:FindFirstChild("StudTexture") == nil and rim.shell:FindFirstChild("Base") == nil and rim.lift > 0,
		"a rim-themed menu carries none of it, and keeps its lift")
end)
gui:Destroy()
check(ok, "both modals build in Edit", err)

--==============================================================================
say("4. The wiring")
--==============================================================================
local shop, settings = sourceOf("ShopUI"), sourceOf("SettingsUI")
check(has(shop, "MenuKit.studdedTheme(GameConfig.StuddedLook.Shop))"), "the Shop takes the red band")
check(has(shop, "plate.Visible = false") and not has(shop, "plate.Visible = true"),
	"and its green plate is never drawn -- not even after a card's detail closes")
check(has(settings, "theme = MenuKit.studdedTheme(STUDDED.Settings),"), "Settings takes the blue band")
check(has(settings, "frame.BackgroundColor3 = ROWS.Row") and has(settings, 'MenuKit.text(frame, "Title", 18, ROWS.RowText, 4)'),
	"and its rows are the kit's dark blue strips with white words")
-- The Index and the Bag next (2026-10-08, the owner: "do the index and bag
-- next"): the kit's Pets green and Trade Inventory cyan.
local index, loadout = sourceOf("IndexUI"), sourceOf("LoadoutUI")
local S4 = GameConfig.StuddedLook
check(S4.Index and S4.Bag and same(S4.Index.Band, Color3.fromRGB(52, 217, 135)) and same(S4.Index.Edge, Color3.fromRGB(9, 106, 67))
		and same(S4.Bag.Band, Color3.fromRGB(33, 187, 235)) and same(S4.Bag.Edge, Color3.fromRGB(7, 87, 118)),
	"the Index's colours are the kit's Pets green, the Bag's its Trade Inventory cyan")
check(has(index, "MenuKit.studdedTheme(GameConfig.StuddedLook.Index))") and has(index, "plate.Visible = false")
		and not has(index, "plate.Visible = true"),
	"the Index takes the green band, and its plate is never drawn -- not even after a card's detail closes")
check(has(loadout, "theme = MenuKit.studdedTheme(GameConfig.StuddedLook.Bag),")
		and has(loadout, "titleColour = GameConfig.StuddedLook.Title,") and not has(loadout, "theme = MenuKit.rimTheme(),"),
	"the Bag takes the cyan band and the white title (InventoryPanel takes back a lift of 0)")
local kept = {}
for _, name in ipairs({ "MarigoldShopUI", "SacrificeUI", "SellUI" }) do
	if has(sourceOf(name), "theme = MenuKit.rimTheme(),") then
		table.insert(kept, name)
	end
end
check(#kept == 3, "every other menu keeps the studded rim (so far: Shop, Settings, Index and Bag only)",
	table.concat(kept, ","))
-- The Reward Wheel's chrome (2026-10-08, the owner: "let claude terminal do the
-- wheel too"): the kit's Spin purple, green and Settings' blue; its art untouched.
local wheel = sourceOf("WheelUI")
local W4 = S4.Wheel
check(W4 and same(W4.Band, Color3.fromRGB(169, 91, 255)) and same(W4.Edge, Color3.fromRGB(78, 28, 134))
		and same(W4.Go, Color3.fromRGB(85, 255, 0)),
	"the wheel's colours are the kit's Spin purple (SKIP, +10 SPINS) and its green SPIN")
check(has(wheel, "Sheet = GameConfig.StuddedLook.Wheel.Band,") and has(wheel, "Go = GameConfig.StuddedLook.Wheel.Go,")
		and has(wheel, "Blue = GameConfig.StuddedLook.Settings.Band,") and has(wheel, "Red = GameConfig.StuddedLook.Close,")
		and not has(wheel, "rgb(67, 176, 79)"),
	"WheelUI's cards, buttons and round buttons take the kit's faces, and no old green is left")
check(has(wheel, 'local body = panel(sheet, "Body", GameConfig.StuddedLook.Body, 17, 4)')
		and has(wheel, "studs(body, GameConfig.StuddedLook.BodyStuds, UDim.new(0, 17), 0)")
		and has(wheel, "studs(trim.header, GameConfig.StuddedLook.BandStuds, UDim.new(0, 17), 1)")
		and has(wheel, "frame.BackgroundColor3 = C.Row") and has(wheel, "frame.BackgroundTransparency = 0"),
	"Reward info: a studded purple band, a white studded body, each prize on a solid dark strip")
check(has(wheel, "studs(face, GameConfig.StuddedLook.BandStuds, UDim.new(0.5, 0), 3)")
		and has(wheel, "studs(b, GameConfig.StuddedLook.BandStuds, UDim.new(0, 8), 2)")
		and has(wheel, "t.Image = GameConfig.StuddedLook.Texture"),
	"every button face on the wheel's panel wears the kit's stud tile")
local menuKit = Shared:FindFirstChild("MenuKit")
check(menuKit and has(menuKit.Source, "local look = theme or MenuKit.rimTheme()"), "MenuKit.modal's menus keep the rim unless told")

say(string.format("\nStuddedLookSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
