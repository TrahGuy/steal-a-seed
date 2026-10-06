--!strict
--==============================================================================
-- THE DISCO'S DANCERS, AS DATA (2026-10-03)
--
-- Eight rigged dancers the owner placed in the Podnappers Workspace (folder
-- "disco Dancers"), lifted here by the same read-only generator as the plant
-- rigs (PlantForms), one child module each. The originals were backed up to
-- output/model-backups/2026-10-03-disco-dancers (with their preview dance
-- scripts) and moved out of the live map to ServerStorage.DiscoDancerOriginals
-- -- recoverable, never a second permanent troupe on the map.
--
-- COSMETIC ONLY. DiscoDancers (client) builds them from here during every mode
-- with Disco (Ticket Disco, Disco + Mill, the pure Disco Only), scattered
-- round the hub at 0.7-1.3x their authored
-- size, and DancerMoves dances them. Nothing here is a reward, a pickup or a
-- gameplay object; none of the eight holds a ticket.
--==============================================================================
local SecretForms = require(script.Parent:WaitForChild("SecretForms"))

local DancerForms = {}

local function load(name: string): SecretForms.FormSpec
	return (require :: any)(script:WaitForChild(name))
end

-- In a fixed order: the event's seeded picks index into it.
DancerForms.Ids = {
	"cocoloco", "discopuff", "turnipop", "bananabop",
	"shroomhop", "pricklepop", "grooveroot", "florasway",
} :: { string }

DancerForms.Forms = {} :: { [string]: SecretForms.FormSpec }
for _, id in ipairs(DancerForms.Ids) do
	DancerForms.Forms[id] = load(id)
end

-- Half the larger of its width and depth at its authored size: the circle it
-- stands in, before its 0.7-1.3x.
function DancerForms.Radius(id: string): number
	local spec = DancerForms.Forms[id]
	if not spec then
		return 0
	end
	return math.max(spec.Size.X, spec.Size.Z) / 2
end

-- Its preview script's beat (the model's DanceBPM attribute), energy and rate.
function DancerForms.Beat(id: string): (number, number, number)
	local spec = DancerForms.Forms[id]
	local a = if spec then spec.Attributes else {}
	return tonumber(a.DanceBPM) or 124, tonumber(a.DanceEnergy) or 1, tonumber(a.RateScale) or 1
end

return DancerForms
