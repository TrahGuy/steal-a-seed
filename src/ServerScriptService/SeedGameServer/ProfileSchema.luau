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
local SAVE = GameConfig.Save

local ProfileSchema = {}

export type Profile = {
	Version: number,
	Cash: number,
	Speed: number,
	PlotTier: number,
	-- Filled by PlantService when it exists. Present from v1 so the shape of a
	-- saved profile does not change on the day it starts being used.
	Plants: { any },
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
		Plants = {},
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
	p.CreatedAt = math.floor(number(raw.CreatedAt, p.CreatedAt, 0, MAX_TIME))
	p.LastSeen = math.floor(number(raw.LastSeen, p.LastSeen, 0, MAX_TIME))

	if type(raw.Plants) == "table" then
		p.Plants = raw.Plants
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
