--!nocheck
--==============================================================================
-- Steal a Seed :: RailFallbackSpec
--
-- A rail button never vanishes when its picture does not load (2026-10-09, the
-- owner: "some buttons are invisible like the garden and inventory"), by the
-- real UIKit in Edit, with UIKit.whenPictureLoads stood in so a picture "loads"
-- exactly when the spec says:
--
--   1. a bare button (Garden, the Bag): its word on a plate shows until its
--      icon has loaded, stays through a "not yet", and for good if it never
--      loads; a new id brings the word back until that one loads
--   2. an art button (Index, Shop, INVITE): the same for its Art
--   3. railPicture: hides nothing of ours before its picture has loaded -- the
--      picture stands over it all, never hidden; once loaded it hides all of
--      it and the word; nil puts ours back, and the word only while no picture
--      of the button's has loaded; a picture loaded before hides ours at once
--   4. one watch per picture and id: a relayout never asks again; a stale
--      answer for an id the picture no longer shows changes nothing
--   5. never a press: the plate and the word are not Active, under every
--      picture and the badge
--   6. the owners: every bare or art rail button passes its word but Settings,
--      which keeps its gear; the Bag cell says BAG until a picture loads
--
-- Not here: a real fetch failing (seen in Play with a bogus id instead).
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local UIKit = require(Shared.UIKit)

local RAIL = GameConfig.Rail

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
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
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function sourceOf(name)
	local found = StarterPlayer:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

-- THE STAND-IN: every wait is written down with the id it was asked for, and
-- answered only when the spec says.
local realWhen = UIKit.whenPictureLoads
local realSettle = UIKit.PictureSettleSeconds
local waits = {}
UIKit.whenPictureLoads = function(picture, onResult)
	table.insert(waits, { picture = picture, image = picture.Image, onResult = onResult })
end
-- Asked at once here; the settle itself is checked at the end.
UIKit.PictureSettleSeconds = 0
local function answer(picture, loaded, image)
	for _, w in ipairs(waits) do
		if w.picture == picture and (image == nil or w.image == image) then
			w.onResult(loaded)
		end
	end
end
local function waitsOn(picture, image)
	local n = 0
	for _, w in ipairs(waits) do
		if w.picture == picture and (image == nil or w.image == image) then
			n += 1
		end
	end
	return n
end

local root = Instance.new("Folder")
root.Name = "ZZRailFallbackSpec"

local ok, err = pcall(function()
	local function word(button)
		local plate = button:FindFirstChild("WordFallback")
		return plate, plate and plate:FindFirstChild("Word")
	end

	--==========================================================================
	say("-- 1. a bare button --")
	local garden = UIKit.railButton(root, { name = "SpecGarden", icon = RAIL.GardenIcon, wide = false,
		bare = true, fallback = RAIL.Words.Garden })
	local icon = garden:FindFirstChild("Icon")
	local plate, label = word(garden)
	check(plate ~= nil and plate.Visible and label ~= nil and label.Text == "GARDEN" and label.Visible,
		"Garden's word shows on its plate while its icon has not loaded")
	check(icon ~= nil and icon.Visible and icon.Image == RAIL.GardenIcon and waitsOn(icon) == 1,
		"its icon is shown (a hidden picture never loads) and waited on once")
	answer(icon, false)
	check(plate.Visible, "a \"not yet\" leaves the word")
	answer(icon, true)
	check(not plate.Visible, "the icon loaded: the word is hidden")
	icon.Image = "rbxassetid://0"
	task.wait()
	check(plate.Visible and waitsOn(icon, "rbxassetid://0") == 1,
		"a new id brings the word back and is waited on")
	answer(icon, false, "rbxassetid://0")
	check(plate.Visible, "an id that never loads keeps the word for good")
	icon.Image = RAIL.GardenIcon
	task.wait()
	check(not plate.Visible, "back to the id that loaded: hidden again at once")

	local bag = UIKit.railButton(root, { name = "SpecBag", icon = RAIL.BagIcon, wide = false, bare = true,
		fallback = RAIL.Words.Bag })
	local bagPlate, bagLabel = word(bag)
	check(bagPlate ~= nil and bagPlate.Visible and bagLabel.Text == "BAG", "the Bag's word is BAG, shown until it loads")
	answer(bag:FindFirstChild("Icon"), true)
	check(not bagPlate.Visible, "the satchel loaded: hidden")

	--==========================================================================
	say("-- 2. an art button --")
	local index = UIKit.railButton(root, { name = "SpecIndex", art = RAIL.IndexArt, fallback = RAIL.Words.Index })
	local artBox = index:FindFirstChild("ArtBox")
	local art = artBox and artBox:FindFirstChild("Art")
	local indexPlate, indexLabel = word(index)
	check(art ~= nil and indexPlate ~= nil and indexPlate.Visible and indexLabel.Text == "INDEX"
			and waitsOn(art) == 1,
		"an art button's word shows until its Art has loaded, and the Art is waited on once")

	--==========================================================================
	say("-- 3. railPicture waits for its picture --")
	UIKit.railPicture(index, RAIL.StuddedIndexArt, 1)
	local box = index:FindFirstChild("PictureBox")
	local picture = box and box:FindFirstChild("Picture")
	check(box ~= nil and box.Visible and picture.Visible and picture.Image == RAIL.StuddedIndexArt,
		"the picture stands over the button, never hidden")
	check(artBox.Visible and indexPlate.Visible,
		"before it has loaded nothing of ours is hidden: the art box and the word stay")
	UIKit.railPicture(index, RAIL.StuddedIndexArt, 1)
	check(waitsOn(picture, RAIL.StuddedIndexArt) == 1, "a relayout never asks again for the same id")
	answer(picture, false)
	check(artBox.Visible and indexPlate.Visible, "a \"not yet\" hides nothing; never loaded, it all stays")
	answer(picture, true)
	check(not artBox.Visible and not indexPlate.Visible and box.Visible,
		"loaded: the art box and the word are hidden under the picture")
	UIKit.railPicture(index, nil)
	check(not box.Visible and artBox.Visible and indexPlate.Visible,
		"nil: the art box back, and the word too, its own Art never having loaded")
	answer(art, true)
	check(not indexPlate.Visible, "its Art loaded: the word hidden")
	UIKit.railPicture(index, RAIL.StuddedIndexArt, 1)
	check(box.Visible and not artBox.Visible and not indexPlate.Visible,
		"a picture loaded before hides ours at once")

	-- A slab's own things (a phone tile, Settings' plate and gear): kept until
	-- the picture loads, every one hidden once it has. Settings passes no word.
	local settings = UIKit.railButton(root, { name = "SpecSettings", icon = RAIL.SettingsIcon, wide = false,
		bare = true })
	for _, name in ipairs({ "Label", "Tile", "TileLabel", "Plate", "GearDrawn" }) do
		local f = Instance.new("Frame")
		f.Name = name
		f.Parent = settings
	end
	local function shownOurs()
		local n = 0
		for _, name in ipairs({ "Icon", "Label", "Tile", "TileLabel", "Plate", "GearDrawn" }) do
			local f = settings:FindFirstChild(name)
			if f and f.Visible then
				n += 1
			end
		end
		return n
	end
	check(settings:FindFirstChild("WordFallback") == nil, "no word where none is given (Settings keeps its gear)")
	UIKit.railPicture(settings, RAIL.StuddedSettingsArt, 1)
	local sPicture = settings.PictureBox.Picture
	check(shownOurs() == 6, "the icon, words, tile, plate and drawn gear all stay before the picture loads",
		shownOurs())
	answer(sPicture, true)
	check(shownOurs() == 0, "every one hidden once it has", shownOurs())

	-- A stale answer: the picture was given a new id since it was asked.
	local shop = UIKit.railButton(root, { name = "SpecShop", art = RAIL.ShopArt, rim = true,
		fallback = RAIL.Words.Shop })
	local shopPlate = word(shop)
	UIKit.railPicture(shop, RAIL.StuddedShopArt, RAIL.StuddedShopAspect)
	local shopPicture = shop.PictureBox.Picture
	UIKit.railPicture(shop, "rbxassetid://0", 1)
	check(waitsOn(shopPicture) == 2, "a new id is asked about again", waitsOn(shopPicture))
	answer(shopPicture, true, RAIL.StuddedShopArt)
	check(shop.ArtBox.Visible and shopPlate.Visible,
		"the old id's answer changes nothing: the button shows another id now")
	check(shopPicture:GetAttribute("RailLoaded") == nil, "and nothing is written down for it")
	local rim = shop.ArtBox:FindFirstChild("Rim")
	check(rim ~= nil and not rim.Visible,
		"the Shop's rim waits for its picture too: never a rainbow square over the word")
	answer(shop.ArtBox.Art, true)
	check(rim.Visible and not shopPlate.Visible, "its picture loaded: the rim turns behind it, the word hidden")

	-- Answered after the button went back to its own look (a phone turned to a
	-- small window's square): nothing hidden then; shown again, hidden at once.
	local back = UIKit.railButton(root, { name = "SpecBack", art = RAIL.ShopArt, fallback = RAIL.Words.Shop })
	local backPlate = word(back)
	UIKit.railPicture(back, RAIL.StuddedShopArt, RAIL.StuddedShopAspect)
	local backPicture = back.PictureBox.Picture
	UIKit.railPicture(back, nil)
	answer(backPicture, true)
	check(back.ArtBox.Visible and backPlate.Visible and not back.PictureBox.Visible,
		"a picture that loads after the button went back to its own look hides nothing")
	UIKit.railPicture(back, RAIL.StuddedShopArt, RAIL.StuddedShopAspect)
	check(back.PictureBox.Visible and not back.ArtBox.Visible and not backPlate.Visible,
		"shown again, it hides ours at once")

	-- THE SETTLE (seen in Play 2026-10-09): right after an id is set IsLoaded
	-- still answers for the old picture, so the first question waits.
	UIKit.PictureSettleSeconds = 0.25
	local settled = UIKit.railButton(root, { name = "SpecSettle", icon = RAIL.GardenIcon, wide = false, bare = true,
		fallback = RAIL.Words.Garden })
	local settledIcon = settled:FindFirstChild("Icon")
	local asked = waitsOn(settledIcon)
	task.wait(0.4)
	check(asked == 0 and waitsOn(settledIcon) == 1 and UIKit.PictureSettleSeconds > 0 and realSettle >= 0.2,
		"the first question waits a moment after the id is set, never at once", asked)
	settledIcon.Image = "rbxassetid://0"
	task.wait(0.05)
	settledIcon.Image = RAIL.GardenIcon
	task.wait(0.4)
	check(waitsOn(settledIcon, "rbxassetid://0") == 0 and waitsOn(settledIcon) == 2,
		"an id given and taken back inside the settle is never asked about: one question more, for the id it shows",
		waitsOn(settledIcon))
	UIKit.PictureSettleSeconds = 0

	--==========================================================================
	say("-- 5. never a press --")
	check(not plate.Active and not label.Active and plate.ZIndex == 1 and label.ZIndex == 1
			and icon.ZIndex > plate.ZIndex and artBox.ZIndex > indexPlate.ZIndex and box.ZIndex > indexPlate.ZIndex,
		"the plate and its word take no press and stand under every picture")
	local badge = UIKit.badge(garden, RAIL.Badge)
	check(badge.ZIndex > plate.ZIndex, "and under the badge")
	check(plate.Size == UDim2.fromScale(1, 1) and label.TextScaled
			and label:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize == RAIL.FallbackTextMax
			and label:FindFirstChildOfClass("UITextSizeConstraint").MinTextSize == RAIL.FallbackTextMin,
		"the plate fills the button and the word fits it, whatever its shape")
	for key, w in pairs(RAIL.Words) do
		if not (type(w) == "string" and #w > 0 and w == string.upper(w)) then
			check(false, "every word is set, in capitals", key)
		end
	end

	--==========================================================================
	say("-- 6. the owners --")
	local kit = (function()
		local okSrc, src = pcall(function()
			return Shared.UIKit.Source
		end)
		return if okSrc then src else ""
	end)()
	local from = kit:find("local function watchPicture", 1, true)
	local body = if from then kit:sub(from, (kit:find("\nend\n", from, true) or #kit)) else ""
	check(has(body, "UIKit.whenPictureLoads(picture, function(loaded: boolean)")
			and has(body, "if loaded and picture.Image == image then"),
		"loaded is answered by UIKit.whenPictureLoads, the picture's own IsLoaded")
	from = kit:find("function UIKit.railPicture", 1, true)
	body = if from then kit:sub(from, (kit:find("\nend\n", from, true) or #kit)) else ""
	check(has(body, "watchPicture(picture, hideOurs)") and has(body, "if pictureLoaded(picture) then")
			and not has(body, "picture.Visible = false"),
		"railPicture hides ours only once its picture has loaded, and never hides the picture")
	-- Every bare or art rail button carries its word, but Settings.
	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local seen, missing = 0, {}
	for _, s in ipairs(scripts and scripts:GetDescendants() or {}) do
		if s:IsA("LuaSourceContainer") then
			local src = s.Source
			local at = 1
			while true do
				local i = src:find("UIKit.railButton(playerGui, {", at, true)
				if not i then
					break
				end
				local j = src:find("})", i, true) or #src
				local call = src:sub(i, j)
				at = j
				if has(call, "bare = true") or has(call, "art = ") then
					seen += 1
					if not has(call, "fallback = RAIL.Words.") and not has(call, "name = \"SettingsButton\"") then
						table.insert(missing, s.Name)
					end
				end
			end
		end
	end
	check(seen >= 7 and #missing == 0, "every bare or art rail button but Settings passes its word ("
		.. seen .. " found)", table.concat(missing, ", "))
	local settingsSrc = sourceOf("SettingsUI")
	check(has(settingsSrc, "drawGear(button, railIcon.Size.X.Offset - 8, 3)"),
		"Settings keeps its gear drawn from frames for an icon that never loads")
	local loadout = sourceOf("LoadoutUI")
	check(has(loadout, "iconWord.Text = RAIL.Words.Bag")
			and has(loadout, "UIKit.whenPictureLoads(icon, function(loaded: boolean)")
			and select(2, loadout:gsub("iconWord%.Visible = false", "")) == 2,
		"the Bag cell says BAG until the rail's art or the satchel has loaded")

	--==========================================================================
	say("-- 7. Garden and the Bag's own pictures (2026-10-09) --")
	-- The owner's two uploads, on the two rail buttons only; the old icons
	-- everywhere else; the hotbar cell's tile with the cell's plate dropped.
	check(RAIL.StuddedGardenArt == "rbxassetid://80369422946168" and RAIL.StuddedBagArt == "rbxassetid://100113253044275"
			and GameConfig.Hotbar.BagIconImage == RAIL.StuddedBagArt,
		"the owner's Garden and Bag pictures, and the hotbar cell's is the Bag's")
	check(RAIL.GardenIcon == "rbxassetid://106268245303506" and RAIL.BagIcon == "rbxassetid://135554729755251"
			and GameConfig.MenuIcons.plants == RAIL.GardenIcon and GameConfig.MenuIcons.bag == RAIL.BagIcon,
		"the old pot and satchel stay everywhere else (the panels' title icons, the teleport buttons)")
	for _, case in ipairs({ { "Garden", RAIL.GardenIcon, RAIL.StuddedGardenArt }, { "Bag", RAIL.BagIcon, RAIL.StuddedBagArt } }) do
		local b = UIKit.railButton(root, { name = "Spec" .. case[1] .. "Art", icon = case[2], wide = false, bare = true,
			fallback = RAIL.Words[case[1]] })
		local bPlate = word(b)
		UIKit.railPicture(b, case[3], 1)
		local bPicture = b.PictureBox.Picture
		check(b.Icon.Visible and bPlate.Visible and b.PictureBox.Visible and bPicture.Image == case[3],
			case[1] .. ": the picture over the old icon and the word, which stay until it loads")
		answer(bPicture, true)
		check(not b.Icon.Visible and not bPlate.Visible and b.PictureBox.Visible,
			case[1] .. ": loaded, the picture IS the button")
	end
	local garden = sourceOf("GardenUI")
	check(has(garden, "UIKit.railPicture(button, RAIL.StuddedGardenArt, 1)")
			and has(loadout, "UIKit.railPicture(bagButton, RAIL.StuddedBagArt, 1)"),
		"GardenUI and LoadoutUI draw them through railPicture on every layout")
	local from7 = loadout:find("THE OWNER'S TILE IS THE CELL", 1, true)
	local cell = if from7 then loadout:sub(from7, from7 + 2200) else ""
	check(has(cell, "tile.Parent = face") and has(cell, "square.AspectRatio = 1")
			and has(cell, "UIKit.whenPictureLoads(tile, function(loaded: boolean)")
			and has(cell, "face.BackgroundTransparency = 1") and has(cell, "faceStroke.Transparency = 1")
			and has(cell, "icon.ImageTransparency = 1"),
		"the Bag cell: the owner's tile square over the whole cell; its plate, edge and satchel go once it loads")
end)

UIKit.whenPictureLoads = realWhen
UIKit.PictureSettleSeconds = realSettle
root:Destroy()
if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end
say(string.format("RailFallbackSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
