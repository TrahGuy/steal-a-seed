--!nocheck
--==============================================================================
-- Steal a Seed :: CardZoomSpec (2026-10-10, the owner: "can we zoom their
-- appearance than using a whole body?")
--
-- A grown creature's picture framed to its face and upper body on the Bag's
-- tiles, the hotbar, MY PLANTS, the Index and the plot's board (GameConfig.
-- Card.Zoom). In Edit, on stand-in models and real creatures:
--
--   1. the crop (UIKit.faceCorners): from BelowEyes of the height under the
--      eyes up where the model names its eyes; else the top TopShare; too few
--      corners above the cut keeps the whole creature
--   2. who is zoomed: ItemArt calls a grown creature "creature" and a pod
--      "plant"; UIKit.frameItem zooms only a creature, only when asked, only
--      with a fit -- the camera comes nearer; a pod's never moves
--   3. the Index's card (UIKit.framePlant): nearer zoomed; its big stage not
--   4. the wiring: each surface's switch; the Index's detail stage untouched
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local ZOOM = GameConfig.Card.Zoom

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
local function src(parent, name)
	local s = parent:FindFirstChild(name)
	local ok, text = pcall(function()
		return s.Source
	end)
	return if ok and type(text) == "string" then text else ""
end
local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end

local layer = Instance.new("ScreenGui")
layer.Name = "ZZCardZoomSpec"
layer.Archivable = false

-- A stand-in creature: a body block from 0 to 4 studs and a head block from 4
-- to 6, optionally with two eye parts at 5.
local function standIn(withEyes)
	local model = Instance.new("Model")
	local function part(name, size, at)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(at)
		p.Anchored = true
		p.Parent = model
		return p
	end
	model.PrimaryPart = part("Body", Vector3.new(2, 4, 2), Vector3.new(0, 2, 0))
	part("Head", Vector3.new(2, 2, 2), Vector3.new(0, 5, 0))
	if withEyes then
		part("EyeL", Vector3.new(0.3, 0.3, 0.1), Vector3.new(-0.5, 5, -1))
		part("EyeR", Vector3.new(0.3, 0.3, 0.1), Vector3.new(0.5, 5, -1))
	end
	return model
end
local function cornersOf(model)
	local points = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local h = d.Size * 0.5
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						table.insert(points, (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
					end
				end
			end
		end
	end
	return points
end
local function lowest(points)
	local y = math.huge
	for _, p in ipairs(points) do
		y = math.min(y, p.Y)
	end
	return y
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE CROP
	--==========================================================================
	say("-- the crop --")
	check(ZOOM.BelowEyes == 0.3 and ZOOM.TopShare == 0.55 and ZOOM.Bag and ZOOM.Hotbar and ZOOM.Plants and ZOOM.Board
			and ZOOM.Index,
		"the five surfaces on; a little under the eyes, else the top 55%")
	local eyed = standIn(true)
	local kept = UIKit.faceCorners(eyed, cornersOf(eyed))
	-- height 6 (0 to 6), eyes at 5: the cut is 5 - 0.3 x 6 = 3.2, so the body's
	-- bottom corners (0) go and its top ones (4) stay.
	check(math.abs(lowest(kept) - 4) < 1e-3 and #kept < #cornersOf(eyed),
		"named eyes: everything from 0.3 of the height under them up", lowest(kept))
	local plain = standIn(false)
	local keptPlain = UIKit.faceCorners(plain, cornersOf(plain))
	-- no eyes: the cut is 6 - 0.55 x 6 = 2.7: the body's bottom corners go.
	check(math.abs(lowest(keptPlain) - 4) < 1e-3, "no eyes: the top 55%", lowest(keptPlain))
	local flat = Instance.new("Model")
	local slab = Instance.new("Part")
	slab.Size = Vector3.new(4, 1, 4)
	slab.Parent = flat
	local all = cornersOf(flat)
	local keptFlat = UIKit.faceCorners(flat, all)
	check(#keptFlat == #all, "too few corners above the cut: the whole thing")

	--==========================================================================
	-- 2. WHO IS ZOOMED
	--==========================================================================
	say("-- who is zoomed --")
	local _, plantKind = ItemArt.builder("zz|plant", { kind = "plant", speciesId = "toadcap", tier = 1, weaponId = nil })
	local _, podKind = ItemArt.builder("zz|pod", { kind = "pod", speciesId = "toadcap", tier = 1, weaponId = nil })
	local _, batKind = ItemArt.builder("zz|bat",
		{ kind = "weapon", speciesId = nil, tier = 1, weaponId = "rootwood_bat" })
	check(plantKind == "creature" and podKind == "plant" and batKind == "bat",
		"ItemArt: a grown creature is \"creature\", a pod still \"plant\", a bat its own", plantKind .. "/" .. podKind)

	-- Where the creature's lowest drawn corner lands in the picture (-1 is the
	-- bottom edge, below it is cut off), and where the camera stands.
	local function distance(kind, zoom, build)
		local v = Instance.new("ViewportFrame")
		v.Size = UDim2.fromOffset(92, 92)
		v.Parent = layer
		local model = build(v)
		UIKit.frameItem(v, model, kind, 0.92, 1, zoom)
		local cam = v.CurrentCamera
		local half = math.tan(math.rad(cam.FieldOfView * 0.5))
		local low = math.huge
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				local h = d.Size * 0.5
				for sx = -1, 1, 2 do
					for sy = -1, 1, 2 do
						for sz = -1, 1, 2 do
							local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
							local rel = cam.CFrame:PointToObjectSpace(q)
							if rel.Z < -0.01 then
								low = math.min(low, rel.Y / (-rel.Z * half))
							end
						end
					end
				end
			end
		end
		local at = cam.CFrame.Position
		v:Destroy()
		return low, at
	end
	local toad = SeedData.Get("toadcap")
	local function creature(v)
		return CreatureModel.BuildCreature(toad, 1, CreatureModel.STAGE_GROWN, CFrame.new(), v)
	end
	local function pod(v)
		return CreatureModel.BuildPod(toad, 1, CFrame.new(), v)
	end
	local lowWhole, whole = distance("creature", false, creature)
	local lowFace = distance("creature", true, creature)
	local _, wholeTop = distance("creature", nil, creature)
	check(lowWhole >= -1.001 and lowFace < -1.05 and (wholeTop - whole).Magnitude < 1e-3,
		"a creature asked to zoom: its feet fall below the picture (the face and upper body fill it); not asked, "
			.. "the whole creature as before", string.format("lowest corner at %.2f zoomed, %.2f whole", lowFace, lowWhole))
	local _, podWhole = distance("plant", false, pod)
	local _, podZoom = distance("plant", true, pod)
	check((podZoom - podWhole).Magnitude < 1e-3, "a pod asked to zoom: never (the hatch's to show)")

	--==========================================================================
	-- 3. THE INDEX'S CARD
	--==========================================================================
	say("-- the Index --")
	local function plantDistance(zoom)
		local v = Instance.new("ViewportFrame")
		v.Size = UDim2.fromOffset(110, 90)
		v.Parent = layer
		local model = creature(v)
		local _, d = UIKit.framePlant(v, model, toad.Form, nil, zoom)
		v:Destroy()
		return d
	end
	local dWhole, dFace = plantDistance(false), plantDistance(true)
	check(dFace < dWhole - 0.5, "UIKit.framePlant zoomed: nearer than the whole creature",
		string.format("%.2f vs %.2f", dFace, dWhole))

	--==========================================================================
	-- 4. THE WIRING
	--==========================================================================
	say("-- the wiring --")
	local Client = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	check(has(src(Shared, "InventoryTile"), "zoom = (GameConfig.Card.Zoom :: any).Bag,")
			and has(src(Shared, "HotbarCard"), "zoom = (GameConfig.Card.Zoom :: any).Hotbar,")
			and has(src(Shared, "PlotShowcaseView"), "zoom = (GameConfig.Card.Zoom :: any).Board })")
			and has(src(Client, "GardenUI"), "zoom = (GameConfig.Card.Zoom :: any).Plants })"),
		"the Bag's tiles, the hotbar, the plot's board and MY PLANTS each read their own switch")
	local index = src(Client, "IndexUI")
	check(has(index, "local camera = UIKit.framePlant(c.view, model, species.Form, CARD_FILL,\n\t\t\t\t\t(GameConfig.Card.Zoom :: any).Index)")
			and has(index, "UIKit.framePlant(stageView, model, species.Form, STAGE_FILL)"),
		"the Index's cards read theirs; its big stage keeps the whole creature")
	check(has(src(Shared, "UIKit"), "pcall(UIKit.frameItem, hero, model, kind or \"bat\", opts.fit, aspectHint, opts.zoom)"),
		"an item preview hands its zoom to the frame")
end)

layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nCardZoomSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
