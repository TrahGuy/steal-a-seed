--!nocheck
--==============================================================================
-- Steal a Seed :: SourceIconsSpec
--
-- The approved category and source icons (2026-10-03), uploaded by the owner:
-- every slot holds an rbxassetid, each picture is drawn only once it has
-- LOADED here, and anything that never loads keeps the icon it always had --
-- never a blank. Edit mode. GameConfig is frozen, so a blank or a bad id is
-- stood in for by swapping StatusText.sourceImage, and put back.
--
--   1. the slots: the category ids, the eight sources, the Bag cell, all set,
--      and every one of the 14 pictures really loads in this place
--   2. StatusText.icon: no id -> the glyph; an id -> the picture over the glyph
--      it hides once loaded; an id that never loads -> the glyph stays
--   3. a line: the picture a little larger than the glyph, inside the same row
--      height; setIcon swaps it in place and the fades still reach it
--   4. a notice's `icon` is optional and must be a string
--   5. every caller names a real slot; the weather is ONE line whose picture
--      follows RainMode; community only on its claimed notice
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local ContentProvider = game:GetService("ContentProvider")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local Notice = require(Shared:WaitForChild("Notice"))
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

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
local function source(name)
	local s = Scripts:FindFirstChild(name)
	return if s then s.Source else ""
end

local layer = Instance.new("ScreenGui")
layer.Name = "ZZSourceIconsSpec"
layer.Archivable = false
local SOURCES = GameConfig.SourceIcons
local realLookup = StatusText.sourceImage
local override = {}
local function standIn(src)
	local o = override[src or ""]
	if o == false then
		return nil
	end
	return o or realLookup(src)
end

local ok, err = pcall(function()
	say("-- the slots --")
	local ids = {}
	local function want(slot, value)
		if type(value) ~= "string" or not string.match(value, "^rbxassetid://%d+$") then
			table.insert(ids, slot .. "=" .. tostring(value))
		end
	end
	for _, c in ipairs(InventoryModel.Categories) do
		want("IconImages." .. c.id, GameConfig.BagLook.IconImages[c.id])
	end
	want("Hotbar.BagIconImage", GameConfig.Hotbar.BagIconImage)
	-- The ticket and disco icons joined 2026-10-04 (the disco's id given by the owner the same day).
	local keys = { "rain", "thunder", "chest", "wheel", "sacrifice", "income", "training", "community", "tickets", "disco" }
	for _, k in ipairs(keys) do
		want("SourceIcons." .. k, SOURCES[k])
	end
	check(#ids == 0, "every one of the 16 slots holds an rbxassetid://", table.concat(ids, ", "))

	layer.Parent = StarterGui
	local labels = {}
	local function probe(slot, image)
		local l = Instance.new("ImageLabel")
		l.Name = slot
		l.Size = UDim2.fromOffset(24, 24)
		l.Image = image
		l.Parent = layer
		table.insert(labels, l)
	end
	for _, c in ipairs(InventoryModel.Categories) do
		probe(c.id, GameConfig.BagLook.IconImages[c.id])
	end
	probe("bag", GameConfig.Hotbar.BagIconImage)
	for _, k in ipairs(keys) do
		probe(k, SOURCES[k])
	end
	pcall(function()
		ContentProvider:PreloadAsync(labels)
	end)
	local t0 = os.clock()
	local missing = {}
	repeat
		table.clear(missing)
		for _, l in ipairs(labels) do
			if not l.IsLoaded then
				table.insert(missing, l.Name)
			end
		end
		if #missing > 0 then
			task.wait(0.25)
		end
	until #missing == 0 or os.clock() - t0 > 12
	check(#labels == 16 and #missing == 0, "all 16 uploaded pictures LOAD in this place (ImageLabel.IsLoaded)",
		table.concat(missing, ", "))

	say("\n-- StatusText.icon --")
	StatusText.sourceImage = standIn
	override.rain = false
	local glyph = StatusText.icon(layer, "boost", Color3.new(1, 1, 1), 16, "rain")
	check(glyph.Name == "Icon" and glyph:FindFirstChild("Shaft") and not glyph:FindFirstChild("Picture"),
		"no id: the boost arrow, exactly as before")
	override.rain = nil
	local pic = StatusText.icon(layer, "boost", Color3.new(1, 1, 1), 16, "rain")
	local image = pic:FindFirstChild("Picture")
	local fallback = pic:FindFirstChild("Fallback")
	check(pic.Name == "Icon" and image and image.Image == SOURCES.rain and fallback
			and fallback:FindFirstChild("Icon") and fallback.Icon:FindFirstChild("Shaft")
			and pic.Size == UDim2.fromOffset(16, 16) and image.BackgroundTransparency == 1,
		"an id: the picture over the arrow, in the same 16-px Icon box (RewardSplash's target)")
	local t1 = os.clock()
	while not (image.IsLoaded and not fallback.Visible) and os.clock() - t1 < 10 do
		task.wait(0.1)
	end
	check(image.IsLoaded and image.Visible and not fallback.Visible, "once loaded, the arrow is hidden")
	override.thunder = "rbxassetid://0"
	local bad = StatusText.icon(layer, "boost", Color3.new(1, 1, 1), 16, "thunder")
	check(bad.Fallback.Visible, "a picture still loading leaves the arrow showing")
	task.wait(9)
	check(bad.Fallback.Visible and bad.Picture.Visible and not bad.Picture.IsLoaded,
		"a picture that never loads: the arrow stays under it (an unloaded picture draws nothing, and is never "
			.. "hidden -- a hidden one would never load) -- never a blank")
	override.thunder = nil

	say("\n-- a line --")
	local plain = StatusText.new({ name = "Plain", parent = layer, size = 17, tint = Color3.new(1, 1, 1),
		icon = "boost", detailSize = 15 })
	local withPic = StatusText.new({ name = "Pic", parent = layer, size = 17, tint = Color3.new(1, 1, 1),
		icon = "boost", source = "rain", detailSize = 15 })
	local plainIcon, picIcon = plain.frame.Body.Icon, withPic.frame.Body.Icon
	check(plainIcon.Size.X.Offset == 16 and picIcon.Size.X.Offset == 20
			and plain.frame.Size.Y.Offset == withPic.frame.Size.Y.Offset
			and picIcon.Size.Y.Offset <= withPic.frame.Size.Y.Offset,
		"a picture is drawn 20 px where the glyph is 16, inside the same 23-px row",
		string.format("%d / %d, rows %d / %d", plainIcon.Size.X.Offset, picIcon.Size.X.Offset,
			plain.frame.Size.Y.Offset, withPic.frame.Size.Y.Offset))
	withPic.setIcon("boost", "thunder")
	local swapped = withPic.frame.Body:FindFirstChild("Icon")
	check(swapped and swapped.Picture.Image == SOURCES.thunder and #withPic.frame.Body:GetChildren() >= 2,
		"setIcon swaps rain for thunder in place")
	check(swapped.Picture.ImageTransparency == 1, "and the line's fade reaches the new picture (hidden line)")
	override.thunder = false
	withPic.setIcon("boost", "thunder")
	swapped = withPic.frame.Body:FindFirstChild("Icon")
	check(swapped and swapped:FindFirstChild("Shaft") and not swapped:FindFirstChild("Picture"),
		"and back to the arrow when a slot has no id")
	override.thunder = nil
	plain.destroy()
	withPic.destroy()

	say("\n-- notices --")
	check(Notice.valid({ kind = "success", title = "X", icon = "wheel" })
			and not Notice.valid({ kind = "success", title = "X", icon = 5 })
			and Notice.valid({ kind = "success", title = "X" }),
		"a notice's icon is optional and must be a string")

	say("\n-- the callers --")
	local wrong = {}
	for _, name in ipairs({ "ActionToastUI", "WheelUI", "SacrificeUI", "CommunityChestUI", "BonusChestUI", "MiniEventUI" }) do
		for key in string.gmatch(source(name), 'icon = "(%a+)"') do
			if key ~= "boost" and SOURCES[key] == nil then
				table.insert(wrong, name .. ":" .. key)
			end
		end
	end
	check(#wrong == 0, "every notice's icon names a real source slot", table.concat(wrong, ", "))
	-- The weather's line and the boost row became icons (2026-10-04): BoostIcons
	-- says which picture each wears.
	local BoostIcons = require(Shared.BoostIcons)
	local function sourceOf(snapshot)
		local list = BoostIcons.entries(snapshot)
		return if list[1] then list[1].source else "none"
	end
	check(sourceOf({ now = 1, rainState = "active", rainMode = "rain", rainEndsAt = 9 }) == "rain"
			and sourceOf({ now = 1, rainState = "active", rainMode = "thunder", rainEndsAt = 9 }) == "thunder",
		"the weather is ONE icon; its picture follows the server's RainMode")
	check(string.find(source("ActionToastUI"), 'icon = if thunder then "thunder" else "rain"', 1, true) ~= nil,
		"the opening notice's picture follows the same mode")
	check(string.find(source("CommunityChestUI"), 'key = "CommunityClaimed", icon = "community"', 1, true) ~= nil
			and select(2, string.gsub(source("CommunityChestUI"), 'icon = "community"', "")) == 1,
		"the community picture only on its claimed notice")
	check(sourceOf({ now = 1, chestBoost = "income", chestEndsAt = 9 }) == "income"
			and sourceOf({ now = 1, chestBoost = "training", chestEndsAt = 9 }) == "training"
			and sourceOf({ now = 1, sacrificeMultiplier = 1.5, sacrificeEndsAt = 9 }) == "sacrifice"
			and sourceOf({ now = 1, miniState = "running", miniMode = "tickets", miniEndsAt = 9 }) == "tickets"
			and sourceOf({ now = 1, miniState = "running", miniMode = "disco", miniEndsAt = 9 }) == "disco"
			and SOURCES.tickets == GameConfig.BagLook.IconImages.tickets
			and SOURCES.disco == "rbxassetid://129016824458756",
		"each boost icon wears its own source (income, training, sacrifice, tickets, disco); the tickets the Bag's "
			.. "Spin Ticket picture, the disco the owner's upload (2026-10-04)")
	-- The Bag cell's picture (2026-10-09: the owner's studded tile is the whole
	-- cell) one layer under the rail's satchel and over the plate, its layer set
	-- AFTER the satchel's own (built first, the old one sat at 2 under the
	-- cell's plate -- seen in Play); the satchel and the plate go only once the
	-- tile has loaded.
	local lo = source("LoadoutUI")
	local artLayer = string.find(lo, "\ticon.ZIndex = 8\n", 1, true)
	local tileLayer = string.find(lo, "tile.ZIndex = icon.ZIndex - 1", 1, true)
	check(artLayer ~= nil and tileLayer ~= nil and tileLayer > artLayer
			and string.find(lo, "icon.ImageTransparency = 1", 1, true) ~= nil
			and string.find(lo, "face.BackgroundTransparency = 1", 1, true) ~= nil,
		"the BAG cell's tile sits over the plate, under the rail's satchel, which fades with the plate only once the "
			.. "tile has loaded")
end)

StatusText.sourceImage = realLookup
layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nSourceIconsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
