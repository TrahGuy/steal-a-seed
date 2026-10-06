--!strict
--==============================================================================
-- Steal a Seed :: ItemArt (2026-10-03, the owner's compact Bag + free hotbar)
--
-- HOW AN ITEM'S PICTURE IS BUILT, for UIKit.itemPreview: the Bag's tiles and
-- the hotbar's slots ask the same function, so the picture in the Bag is the
-- one on the strip. Moved out of LoadoutUI, whose chunk is rationed to Luau's
-- 200 locals.
--
--   a bat or a trap   WeaponModel.BuildPreview -- the shop card's own call
--   the Spin Tickets  a gold ticket in blocks, the wheel's colours on its stub
--   the trail         two ribbons, mint and gold, weaving round each other,
--                     a small flower on the wake and three petals (2026-10-04)
--   a plant           CreatureModel's grown creature
--   a pod             CreatureModel's pod -- built from InventoryModel's
--                     REPRESENTATIVE species for that shell, never from what is
--                     inside, so not even the model's own name says which one
--
-- TAGS ARE STRIPPED. CreatureModel's output is the geometry that stands in a
-- plot, and anything tagged inside a ViewportFrame would be found by PlantSway
-- and animated as though it grew in somebody's garden.
--
-- BUILT ONCE PER PICTURE. The first build is kept as a template (tags already
-- off) and every later one is a clone of it: a Bag of 24 Nubkins builds one.
--==============================================================================
local CollectionService = game:GetService("CollectionService")

local Shared = script.Parent
local SeedData = require(Shared:WaitForChild("SeedData"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local WheelData = require(Shared:WaitForChild("WheelData"))

local ItemArt = {}

export type Art = { kind: string, speciesId: string?, tier: number, weaponId: string? }
type Builder = (Instance) -> Model?

local templates: { [string]: Model } = {}

local function strip(model: Instance)
	for _, d in ipairs(model:GetDescendants()) do
		for _, tag in ipairs(CollectionService:GetTags(d)) do
			CollectionService:RemoveTag(d, tag)
		end
	end
	for _, tag in ipairs(CollectionService:GetTags(model)) do
		CollectionService:RemoveTag(model, tag)
	end
end

local function part(model: Model, name: string, size: Vector3, cf: CFrame, colour: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Parent = model
	return p
end

local function ticket(parent: Instance): Model?
	local model = Instance.new("Model")
	model.Name = "SpinTicketPreview"
	local body = part(model, "Ticket", Vector3.new(3.2, 1.8, 0.2), CFrame.new(), Color3.fromRGB(255, 206, 84))
	part(model, "Stub", Vector3.new(0.8, 1.6, 0.24), CFrame.new(1.05, 0, 0), Color3.fromRGB(240, 120, 90))
	part(model, "Band", Vector3.new(1.9, 0.3, 0.24), CFrame.new(-0.45, 0.45, 0), Color3.fromRGB(90, 176, 255))
	part(model, "Band", Vector3.new(1.9, 0.3, 0.24), CFrame.new(-0.45, -0.45, 0), Color3.fromRGB(110, 220, 110))
	model.PrimaryPart = body
	model.Parent = parent
	return model
end

-- The Bloomrunner Trail as TrailFX draws it behind a runner, in parts
-- (2026-10-04, after the trail's jackpot upgrade): TWO ribbons, mint and warm
-- gold, crossing and re-crossing as they weave -- thick at the runner's end
-- (+X), thin and leafier at the old end -- and the floral wake behind them, a
-- small flower opening on the trail and a few loose petals. The same width and
-- height as the single ribbon it replaces, so the Bag frames it the same.
local function trail(parent: Instance): Model?
	local t = WheelData.Trail
	local model = Instance.new("Model")
	model.Name = "BloomrunnerPreview"
	local SEGMENTS = 8
	local spacing = 0.68
	for which = 1, 2 do
		local fresh = if which == 1 then t.Mint else t.Gold
		local old = if which == 1 then t.Mint:Lerp(t.Leaf, 0.6) else t.Gold:Lerp(t.Leaf, 0.35)
		local function at(i: number): Vector3
			local x = (i - (SEGMENTS + 1) / 2) * spacing
			local phase = (i / SEGMENTS) * math.pi * 2.2 + (if which == 2 then math.pi else 0)
			-- Toward the camera (-Z) on one pass, away on the next: the two cross.
			return Vector3.new(x, math.sin(phase) * 0.42, -math.cos(phase) * 0.14)
		end
		for i = 1, SEGMENTS do
			local a, b = at(i - 0.5), at(i + 0.5)
			local mid = (a + b) / 2
			local slope = math.atan2(b.Y - a.Y, b.X - a.X)
			local u = (i - 1) / (SEGMENTS - 1)
			part(model, (if which == 1 then "Mint" else "Gold") .. i,
				Vector3.new((b - a).Magnitude + 0.06, 0.16 + 0.22 * u, 0.06),
				CFrame.new(mid) * CFrame.Angles(0, 0, slope), old:Lerp(fresh, u))
		end
	end
	-- The wake's flower near the old end: five petals round a gold heart.
	local flower = Vector3.new(-2.15, -0.72, -0.2)
	for k = 0, 4 do
		local angle = k * math.pi * 2 / 5
		part(model, "FlowerPetal" .. k + 1, Vector3.new(0.36, 0.2, 0.05),
			CFrame.new(flower + Vector3.new(math.cos(angle) * 0.22, math.sin(angle) * 0.22, 0))
				* CFrame.Angles(0, 0, angle), if k == 1 or k == 3 then t.Gold else t.Mint)
	end
	local heart = part(model, "FlowerHeart", Vector3.new(0.2, 0.2, 0.2), CFrame.new(flower + Vector3.new(0, 0, -0.04)),
		t.Gold)
	heart.Shape = Enum.PartType.Ball
	-- Loose petals drifting off the ribbons.
	for i, spot in ipairs({ Vector3.new(-1.1, 0.86, 0.1), Vector3.new(0.5, -0.82, -0.1), Vector3.new(1.9, 0.8, 0.05) }) do
		part(model, "Petal" .. i, Vector3.new(0.3, 0.17, 0.05), CFrame.new(spot) * CFrame.Angles(0, 0, math.rad(40 * i)),
			if i % 2 == 0 then t.Gold else t.Mint)
	end
	model.Parent = parent
	return model
end

-- The builder for `art`, keyed `key` in the template cache, and the preview's
-- framing kind ("bat", "trap", "ticket", "trail", "plant").
function ItemArt.builder(key: string, art: Art): (Builder?, string)
	local make: Builder? = nil
	local kind = "plant"
	if art.kind == "weapon" then
		local item = WeaponData.Get(art.weaponId)
		if item then
			local weapon = item :: WeaponData.Item
			kind = weapon.Category
			make = function(parent: Instance): Model?
				return WeaponModel.BuildPreview(weapon, parent)
			end
		end
	elseif art.kind == "ticket" then
		kind = "ticket"
		make = ticket
	elseif art.kind == "trail" then
		kind = "trail"
		make = trail
	else
		local species = SeedData.Get(art.speciesId or "")
		if species then
			local known = species :: SeedData.Species
			local tier = art.tier
			if art.kind == "plant" then
				make = function(parent: Instance): Model?
					return CreatureModel.BuildCreature(known, tier, CreatureModel.STAGE_GROWN, CFrame.new(), parent)
				end
			else
				make = function(parent: Instance): Model?
					return CreatureModel.BuildPod(known, tier, CFrame.new(), parent)
				end
			end
		end
	end
	local build = make
	if not build then
		return nil, kind
	end
	return function(parent: Instance): Model?
		local template = templates[key]
		if template then
			local ok, copy = pcall(function()
				return template:Clone()
			end)
			if ok and copy then
				copy.Parent = parent
				return copy
			end
		end
		local model = (build :: Builder)(parent)
		if model then
			strip(model)
			local ok, copy = pcall(function()
				return model:Clone()
			end)
			if ok and copy then
				templates[key] = copy
			end
		end
		return model
	end, kind
end

return ItemArt
