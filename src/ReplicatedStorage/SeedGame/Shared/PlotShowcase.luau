--!strict
--==============================================================================
-- Steal a Seed :: PlotShowcase (2026-10-05, the owner's TOP CREATURES board)
--
-- THE BOARD BESIDE EVERY PLOT'S UPGRADE PLOT SIGN: that plot OWNER's two best
-- grown creatures, for everybody who walks past. This file is the board's
-- arithmetic and its wood -- pure but for `build`, which makes parts and
-- nothing else:
--
--   row       one planted model as a ranking row, or nil: a GROWN creature
--             (CreatureModel.STAGE_GROWN) of a known species. A pod, and a
--             sprout still growing, are never on the board.
--   top       the two best rows: SeedData.IncomePerSecond -- the number EQUIP
--             BEST ranks by, BEFORE the pass, the boosts and the rain multiply
--             the whole garden alike (GameConfig.gardenIncomeMultiplier is one
--             factor per plot, so no boost can reorder a garden) -- highest
--             first, equal incomes in EQUIP BEST's own order (GardenPlan.before:
--             the lower item id, then the lower placement id).
--   publish   the plain attributes PlotShowcaseService writes on the board
--             (`attributes`: each slot's species id, tier and placement id;
--             nil where a slot is empty) and `read`, a client's view of them --
--             a slot with junk in it, or a species this build does not know,
--             reads as no slot.
--   build     the board itself: a post, a plank and its rim, in the upgrade
--             board's own wood (MillModel.BuildSign's colours), the post's
--             foot on the frame it is handed (GameConfig.plotShowcaseBase).
--             Signage: anchored, never collides, never touched, never queried
--             -- it cannot stop a runner, catch a planting click's raycast, or
--             stand in a prompt's line of sight.
--
-- THE WORDS ARE PlantLabel.content, at the owner's rate
-- (GameConfig.gardenIncomeMultiplier(plot)) -- PlotShowcaseView paints them --
-- so the board and the overhead labels can never disagree.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local GardenPlan = require(Shared:WaitForChild("GardenPlan"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local PlotShowcase = {}

local SC = GameConfig.Plot.Showcase
local A = SC.Attributes

PlotShowcase.Slots = SC.Slots

export type Row = {
	species: string,
	tier: number,
	placementId: number,
	-- The item id the creature carries into the ground (MY PLANTS); nil for a
	-- legacy planting with none. Only the tie-break reads it.
	item: string?,
	-- SeedData.IncomePerSecond: what ranks it, never what the board prints.
	income: number,
}

export type Slot = {
	species: string,
	tier: number,
	placementId: number,
}

--==============================================================================
-- ONE PLANTED MODEL AS A ROW
--
-- Off the attributes CreatureModel.Build and PlantService.render stamp on every
-- planted model (SpeciesId, Tier, Stage, PlacementId, ItemId). nil for anything
-- that is not a grown creature of a species this build knows.
--==============================================================================
function PlotShowcase.row(speciesId: any, tier: any, stage: any, placementId: any, item: any): Row?
	if stage ~= CreatureModel.STAGE_GROWN or type(speciesId) ~= "string" then
		return nil
	end
	local species = SeedData.Get(speciesId)
	local t = tonumber(tier)
	local id = tonumber(placementId)
	if not species or not t or t ~= t or not id or id ~= id then
		return nil
	end
	t = math.clamp(math.floor(t), 1, SeedData.TierCount)
	return {
		species = speciesId,
		tier = t :: number,
		placementId = id :: number,
		item = if item ~= nil and item ~= "" then tostring(item) else nil,
		income = SeedData.IncomePerSecond(species, t),
	}
end

-- A planted model's row, read off the model itself.
function PlotShowcase.rowOf(model: Instance): Row?
	return PlotShowcase.row(model:GetAttribute("SpeciesId"), model:GetAttribute("Tier"),
		model:GetAttribute("Stage"), model:GetAttribute("PlacementId"),
		model:GetAttribute(GameConfig.Attributes.ItemId))
end

--==============================================================================
-- THE TWO BEST, IN EQUIP BEST'S ORDER
--==============================================================================
function PlotShowcase.top(rows: { Row }): { Row }
	local candidates: { GardenPlan.Candidate } = {}
	local byKey: { [string]: Row } = {}
	for _, r in ipairs(rows) do
		local key = "p:" .. tostring(r.placementId)
		if byKey[key] == nil then
			byKey[key] = r
			table.insert(candidates, {
				key = key,
				income = r.income,
				planted = true,
				item = r.item,
				placementId = r.placementId,
			})
		end
	end
	table.sort(candidates, GardenPlan.before)
	local out: { Row } = {}
	for i = 1, math.min(SC.Slots, #candidates) do
		table.insert(out, byKey[candidates[i].key])
	end
	return out
end

--==============================================================================
-- WHAT THE SERVER PUBLISHES
--
-- Every name the board may carry, so a writer can clear the ones a shorter
-- list leaves empty (a table cannot hold a nil to say so).
--==============================================================================
function PlotShowcase.attributeNames(): { string }
	local names = {}
	for i = 1, SC.Slots do
		table.insert(names, A.Species[i])
		table.insert(names, A.Tier[i])
		table.insert(names, A.Placement[i])
	end
	return names
end

-- The values for a top list, by name; a name missing from the answer is a slot
-- that should be cleared.
function PlotShowcase.attributes(top: { Row }): { [string]: any }
	local out: { [string]: any } = {}
	for i = 1, SC.Slots do
		local r = top[i]
		if r then
			out[A.Species[i]] = r.species
			out[A.Tier[i]] = r.tier
			out[A.Placement[i]] = r.placementId
		end
	end
	return out
end

-- Writes a top list onto `board`, touching only the attributes that change, so
-- an unchanged garden replicates nothing. Answers whether anything was written.
function PlotShowcase.publish(board: Instance, top: { Row }): boolean
	local want = PlotShowcase.attributes(top)
	local wrote = false
	for _, name in ipairs(PlotShowcase.attributeNames()) do
		local value = want[name]
		if board:GetAttribute(name) ~= value then
			board:SetAttribute(name, value)
			wrote = true
		end
	end
	return wrote
end

--==============================================================================
-- WHAT A CLIENT READS BACK
--
-- In slot order. A slot whose species this build does not know, or whose tier
-- or placement id is not a number, is skipped rather than drawn wrong.
--==============================================================================
function PlotShowcase.read(board: Instance): { Slot }
	local out: { Slot } = {}
	for i = 1, SC.Slots do
		local species = board:GetAttribute(A.Species[i])
		local tier = tonumber(board:GetAttribute(A.Tier[i]))
		local placementId = tonumber(board:GetAttribute(A.Placement[i]))
		if type(species) == "string" and SeedData.Get(species) ~= nil and tier and tier == tier
			and placementId and placementId == placementId then
			table.insert(out, {
				species = species,
				tier = math.clamp(math.floor(tier), 1, SeedData.TierCount),
				placementId = placementId,
			})
		end
	end
	return out
end

--==============================================================================
-- THE BOARD ITSELF
--
-- `cf` is the post's GROUND BASE (GameConfig.plotShowcaseBase), facing the way
-- the gate does; the plank's Front face is the one that is read. Pivot at the
-- post's foot, so PivotTo(ground) stands it on the ground -- the mill sign's
-- climbing board taught that one (MillModel.SignBase).
--==============================================================================
local OAK = Color3.fromRGB(126, 88, 54)
local OAK_DARK = Color3.fromRGB(92, 62, 38)
local PLANK = Color3.fromRGB(72, 54, 40)

local function part(name: string, size: Vector3, cframe: CFrame, colour: Color3, material: Enum.Material,
	parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The plank's centre over the post's foot, in studs.
function PlotShowcase.boardCentreY(): number
	return SC.BoardTopY - SC.BoardSize.Y * 0.5
end

function PlotShowcase.build(cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "PlotShowcase"
	local centreY = PlotShowcase.boardCentreY()
	-- One post under the plank's middle, reaching PostOverlap into its lower
	-- edge -- the upgrade board's own build, so the pair reads as one family --
	-- but set BACK: the post is thicker than the plank, and centred it stood
	-- 0.08 proud of the lettered face, a dark bar over both cards' inner
	-- corners (seen in Play, 2026-10-05). Its front face is PostInset behind
	-- the plank's.
	local postTall = centreY - SC.BoardSize.Y * 0.5 + SC.PostOverlap
	local postBack = SC.PostWidth * 0.5 - SC.BoardSize.Z * 0.5 + SC.PostInset
	local post = part("Post", Vector3.new(SC.PostWidth, postTall, SC.PostWidth),
		cf * CFrame.new(0, postTall * 0.5, postBack), OAK_DARK, Enum.Material.Wood, model)
	-- A model with a PrimaryPart pivots on THAT part's pivot (WorldPivot is then
	-- ignored), and a part's pivot is its centre: half a post up. So the post's
	-- own pivot is moved down to its foot -- MEASURED, the board's pivot read
	-- 1.30 up before this.
	post.PivotOffset = post.CFrame:ToObjectSpace(cf)
	model.PrimaryPart = post
	part("Board", SC.BoardSize, cf * CFrame.new(0, centreY, 0), PLANK, Enum.Material.WoodPlanks, model)
	-- The rim: a slightly larger, slightly thinner frame centred on the plank
	-- (the plaque's), so a light edge of oak shows round the lettered face. No
	-- bolts: the face is lettered to its corners and a bolt would stand through
	-- the cards.
	part("Rim", SC.BoardSize + Vector3.new(SC.RimStuds * 2, SC.RimStuds * 2, -0.1),
		cf * CFrame.new(0, centreY, 0), OAK, Enum.Material.Wood, model)
	model.Parent = parent
	return model
end

return PlotShowcase
