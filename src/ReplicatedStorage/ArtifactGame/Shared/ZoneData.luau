--!strict
-- Steal an Artifact :: ZoneData
--
-- Where artifacts appear, and how often. Geometry lives here rather than in
-- GameConfig because a zone is content: adding a third one in Phase 5 should be
-- a table entry, not an edit to a service.
--
--==============================================================================
-- TWO ZONES, ON OPPOSITE SIDES, IS A DESIGN DECISION AND NOT A LAYOUT
--
-- The blueprint puts one at the top of the map and one at the bottom with the
-- bases ringed between them. That shape is what creates the game: whichever
-- zone you run to, you are running AWAY from half the server and THROUGH the
-- other half on the way home. One central zone would put every player in the
-- same place at the same time and turn the game into a scrum; four small ones
-- would spread everybody out until nobody ever met.
--
-- RarityBonus is a multiplier applied to the roll weights of the top bands in
-- that zone. The far zone pays better because it is a longer, more dangerous
-- run home -- that is the only reason anybody would use it, so it has to be
-- true and it has to be visible to the player.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ZoneData = {}

local BASE_Y = GameConfig.Map.BaseY
local DIST = GameConfig.Map.ZoneDistance

export type Zone = {
	Id: string,
	DisplayName: string,
	-- Offset from world origin, on the ground plane.
	Position: Vector3,
	Size: Vector3,
	Color: Color3,
	-- How many pedestals stand in this zone. An artifact occupies a pedestal
	-- until somebody takes it, so this is also the cap on how much loot can be
	-- sitting in the zone at once.
	Pedestals: number,
	-- Seconds between one pedestal restocking. Not per zone -- per PEDESTAL, so
	-- a zone with more pedestals genuinely produces more.
	RespawnSeconds: number,
	-- Multiplier on the Epic-and-above roll weights. 1.0 is the base table.
	RarityBonus: number,
}

ZoneData.Zones = {
	{
		Id = "north_ruins",
		DisplayName = "The Ruins",
		Position = Vector3.new(0, BASE_Y, -DIST),
		Size = Vector3.new(220, 1, 160),
		Color = Color3.fromRGB(196, 172, 128),
		Pedestals = 10,
		RespawnSeconds = 22,
		RarityBonus = 1.0,
	},
	{
		Id = "south_vault",
		DisplayName = "The Vault",
		Position = Vector3.new(0, BASE_Y, DIST),
		Size = Vector3.new(220, 1, 160),
		Color = Color3.fromRGB(126, 138, 178),
		-- Fewer pedestals, slower restock, better odds. The Vault is the
		-- greedy choice, and it should feel like one: you wait longer, you walk
		-- further, and what you get is worth more.
		Pedestals = 6,
		RespawnSeconds = 34,
		RarityBonus = 2.2,
	},
} :: { Zone }

local byId: { [string]: Zone } = {}
for _, zone in ipairs(ZoneData.Zones) do
	byId[zone.Id] = zone
end
ZoneData.ById = byId

--==============================================================================
-- PEDESTAL LAYOUT
--
-- Returns the world CFrames for one zone's pedestals: a grid, inset from the
-- zone edge so nothing spawns half inside a wall, and jittered on a fixed
-- pattern so it does not read as graph paper.
--
-- DETERMINISTIC ON PURPOSE. The jitter is derived from the pedestal index, not
-- from math.random, so every server in the game builds the identical zone --
-- which means a player who learns the layout on one server knows it on all of
-- them, and a bug report about "the pedestal in the corner" means something.
--==============================================================================
function ZoneData.PedestalCFrames(zone: Zone): { CFrame }
	local out: { CFrame } = {}
	local count = zone.Pedestals
	if count <= 0 then
		return out
	end

	local cols = math.ceil(math.sqrt(count))
	local rows = math.ceil(count / cols)
	local inset = 26
	local spanX = math.max(1, zone.Size.X - inset * 2)
	local spanZ = math.max(1, zone.Size.Z - inset * 2)

	local index = 0
	for row = 1, rows do
		for col = 1, cols do
			index += 1
			if index > count then
				break
			end
			-- (col - 0.5) / cols spreads the points across the span with a half
			-- step of padding at each end, so the outermost pedestals are not
			-- flush against the inset edge.
			local fx = (col - 0.5) / cols - 0.5
			local fz = (row - 0.5) / rows - 0.5
			local jitterX = math.sin(index * 2.399963) * 6
			local jitterZ = math.cos(index * 2.399963) * 6
			out[index] = CFrame.new(
				zone.Position.X + fx * spanX + jitterX,
				zone.Position.Y,
				zone.Position.Z + fz * spanZ + jitterZ
			) * CFrame.Angles(0, index * 0.7, 0)
		end
	end
	return out
end

return ZoneData
