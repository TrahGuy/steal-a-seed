--!strict
-- Steal a Seed :: ProfileSchema
--
-- What a profile IS, and how to turn anything at all into a valid one.
--
-- NOT a *Service on purpose. ServerMain auto-requires and starts every
-- ModuleScript here whose name ends in "Service"; this has no lifecycle, it is
-- a shape and a validator. Same reasoning as MapDecor and HubFairy.
--
-- Separated from PlayerDataService so it can be TESTED. This is the function
-- standing between whatever came out of a DataStore and the running game, and a
-- validator nothing can exercise is a validator nobody has checked.
--
--==============================================================================
-- SANITISING IS THE MIGRATION STRATEGY
--
-- A loaded profile is never used as-is. It is poured into a fresh set of
-- defaults, field by field, and anything missing, mistyped or out of range is
-- replaced by its default rather than trusted.
--
-- That is not only paranoia about corruption -- it is how schema changes work
-- here. Adding a field needs no migration ladder: old profiles do not have it,
-- so they get the default, which is exactly what a migration would have
-- written. A ladder is only needed to RESHAPE an existing field, and Version is
-- carried so that day can be detected.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))
-- Only so an Almanac id can be checked against something real. A saved key
-- naming a species that no longer exists is dropped rather than carried, which
-- is the same rule every other field here follows.
local SeedData = require(SeedGame:WaitForChild("Shared"):WaitForChild("SeedData"))
local BiomeData = require(SeedGame:WaitForChild("Shared"):WaitForChild("BiomeData"))
local SAVE = GameConfig.Save

local ProfileSchema = {}

export type Profile = {
	Version: number,
	Cash: number,
	Speed: number,
	PlotTier: number,
	-- Which mill stands on their plot. Exactly the same idea as PlotTier and
	-- kept beside it on purpose: one number, owned by the server, that decides
	-- what gets built on YOUR ground.
	MillTier: number,
	--==========================================================================
	-- HOW HARD THAT MILL IS BEING RUN
	--
	-- Separate from MillTier because it is a separate purchase and because the
	-- tier ladder ENDS -- seven mills, seven models -- while this one continues.
	-- Saved rather than derived: it is bought with cash and losing it to a bad
	-- load would be losing hours.
	--==========================================================================
	MillOverclock: number,
	--==========================================================================
	-- THE HIGHEST BIOME SPEED MILESTONE THIS PLAYER HAS EARNED
	--
	-- A HIGH-WATER MARK, not access permission. Biome entrances are open, but
	-- overclock progression uses the same Speed targets. A future rebirth may set
	-- live Speed back to zero and must not confiscate milestones already earned.
	--
	-- Only ever raised. Nothing in the game lowers it.
	--==========================================================================
	HighestBiomeOrder: number,
	-- Filled by PlantService when it exists. Present from v1 so the shape of a
	-- saved profile does not change on the day it starts being used.
	Plants: { any },
	--==========================================================================
	-- WHAT IS IN THEIR HANDS, WHICH USED TO BE THROWN AWAY
	--
	-- The bed was saved from the first day and the HOTBAR was not, so anything
	-- held at the moment you left stopped existing: pick a plant out of your own
	-- dirt, leave, come back, and it is in neither place. That is not a UI bug,
	-- it is the save destroying property, and it hit hardest exactly where the
	-- game invites it -- the Garden's PICK UP.
	--
	-- One row per Tool, in hotbar order: the species id, what it weighs, and
	-- whether the shell has been opened. That is the whole of a Tool -- the
	-- three attributes CarryService stamps -- so a restored one is not a copy of
	-- the original, it IS the original.
	--
	-- The raid carry is deliberately NOT in here. A pod welded to your head on
	-- the wrong side of the red line is a bet you have not settled yet, and
	-- logging out is not a way to bank it.
	--==========================================================================
	Held: { any },
	--==========================================================================
	-- WHAT THEY HAVE SEEN GROW
	--
	-- A set, not a list: the only question ever asked of it is "is this one
	-- filled in", and a list would make that a linear scan on every Index row
	-- and would let the same id in twice.
	--
	-- Earned by a plant reaching STAGE_GROWN on a plot you own. Not by carrying
	-- a pod, not by a pod sitting in a nest, and not by a sprout -- because
	-- until it finishes you have not actually found out which species it was.
	-- The pod is coloured by rarity, so two Commons arrive identical; the
	-- reveal IS the grow-up, and this records that moment and no other.
	--==========================================================================
	Almanac: { [string]: boolean },
	CreatedAt: number,
	LastSeen: number,
}

-- Year 2100, as a sanity ceiling on stored timestamps. A clock-skewed or
-- corrupt LastSeen far in the future would make offline income pay out
-- centuries the moment that feature exists.
local MAX_TIME = 4102444800

function ProfileSchema.Default(): Profile
	local now = os.time()
	return {
		Version = SAVE.CurrentVersion,
		Cash = 0,
		Speed = 0,
		PlotTier = GameConfig.StartingPlotTier,
		MillTier = GameConfig.Mill.StartingTier,
		MillOverclock = 0,
		-- Greenhollow is on record from the first second. It is the biome the
		-- spawn is in, and a player who could be pushed out of it would have
		-- nowhere legal to stand.
		HighestBiomeOrder = 1,
		Plants = {},
		Held = {},
		Almanac = {},
		CreatedAt = now,
		LastSeen = now,
	}
end

--==============================================================================
-- NaN IS CHECKED SEPARATELY, AND THAT IS NOT PEDANTRY
--
-- NaN fails every comparison you would normally write. `n > max` is false for
-- NaN, `n < min` is false for NaN, so a plain clamp passes it straight through
-- untouched -- and math.clamp itself returns NaN. One NaN in Cash poisons every
-- sum it ever touches, saves cleanly, and reloads as NaN forever.
--
-- `value ~= value` is true only for NaN. It is the whole test.
--==============================================================================
local function number(value: any, fallback: number, min: number, max: number): number
	if type(value) ~= "number" or value ~= value then
		return fallback
	end
	-- Infinity clamps correctly (it compares), so it needs no special case.
	return math.clamp(value, min, max)
end

ProfileSchema.number = number

function ProfileSchema.Sanitise(raw: any): Profile
	local p = ProfileSchema.Default()
	if type(raw) ~= "table" then
		return p
	end

	p.Cash = number(raw.Cash, 0, 0, SAVE.MaxCash)
	p.Speed = number(raw.Speed, 0, 0, SAVE.MaxSpeedScore)
	p.PlotTier = math.floor(
		number(raw.PlotTier, GameConfig.StartingPlotTier, 1, #GameConfig.PlotTiers))
	p.MillTier = math.floor(
		number(raw.MillTier, GameConfig.Mill.StartingTier, 1, #GameConfig.Mill.Tiers))
	--==========================================================================
	-- BOTH NEW FIELDS MIGRATE BY BEING ABSENT
	--
	-- `number` already answers "not a number, or out of range" with the default,
	-- so a v1 save written before either field existed reads nil and lands on
	-- overclock 0 and Greenhollow -- which is exactly the state such a player is
	-- in. No version bump, no migration pass, no branch.
	--==========================================================================
	p.MillOverclock = math.floor(
		number(raw.MillOverclock, 0, 0, GameConfig.Mill.Overclock.MaxLevel))
	p.HighestBiomeOrder = math.floor(
		number(raw.HighestBiomeOrder, 1, 1, #BiomeData.Biomes))
	p.CreatedAt = math.floor(number(raw.CreatedAt, p.CreatedAt, 0, MAX_TIME))
	p.LastSeen = math.floor(number(raw.LastSeen, p.LastSeen, 0, MAX_TIME))

	if type(raw.Plants) == "table" then
		p.Plants = raw.Plants
	end

	--==========================================================================
	-- HELD IS REBUILT ROW BY ROW, NOT TRUSTED WHOLESALE
	--
	-- Same discipline as the Almanac below and for the same reason: a DataStore
	-- round trip can hand back a species that has since been deleted, a weight
	-- from before the roll existed, or a table with a hole in it. Every row has
	-- to name a real species and carry a sane weight or it does not come back.
	--
	-- Capped, because the list is rebuilt into Tools on join and an unbounded
	-- one is an unbounded amount of work at the worst moment.
	--==========================================================================
	if type(raw.Held) == "table" then
		for _, row in ipairs(raw.Held) do
			if #p.Held >= SAVE.MaxHeld then
				break
			end
			if type(row) == "table" and type(row.Id) == "string"
				and SeedData.Get(row.Id) then
				local kg = number(row.Kg, 0, 1, GameConfig.Carry.MaxKg)
				if kg >= 1 then
					table.insert(p.Held, {
						Id = row.Id,
						Kg = math.floor(kg),
						Hatched = row.Hatched == true,
					})
				end
			end
		end
	end

	-- Copied key by key rather than assigned wholesale, which is what makes the
	-- "unknown ids dropped" promise true. A DataStore round trip can hand back
	-- numeric keys, string values, or an id from a species that has since been
	-- deleted; none of those reach the Index.
	if type(raw.Almanac) == "table" then
		for id, seen in pairs(raw.Almanac) do
			if seen == true and type(id) == "string" and SeedData.Get(id) then
				p.Almanac[id] = true
			end
		end
	end

	-- Carried, not trusted. Nothing branches on it yet; the day a field has to
	-- be reshaped rather than added, this tells the ladder where to start.
	if type(raw.Version) == "number" and raw.Version == raw.Version then
		p.Version = math.floor(math.clamp(raw.Version, 1, 1e6))
	end

	-- Unknown keys are dropped by construction: everything above copies FROM
	-- raw INTO a fresh default, so a field removed from the schema stops being
	-- carried the moment it stops being read here.
	return p
end

return ProfileSchema
