--!strict
--==============================================================================
-- THE RAIN EVENT'S SUPPLIED MODELS, AS DATA (2026-10-02)
--
-- Twelve models the owner placed in the Podnappers Workspace folder "Rain
-- Event", lifted here by a read-only generator (the Secret pipeline's, with
-- trails, billboards and a sleep pose added) into one child module each. The
-- originals' geometry was not moved or changed; verified .rbxm copies (scripts
-- included) are in output/model-backups/2026-10-02-rain-event-originals.
--
-- THE MAPPING, as recorded before integration and confirmed by the owner:
--
--     pod      the pod model   its creatures (model -> form id)
--     Pod 1    pod1            Puddlepod POD1 -> puddlepod
--                              Drizzlet POD1  -> drizzlet
--                              Lotusling POD1 -> lotusling
--     Pod 2    pod2            Puddlepod POD2 -> puddlepod_colossal
--                              Drizzlet POD 3 -> drizzlet_colossal   (labelled
--                                "POD 3", stands in the Pod 2 row, 48 studs
--                                tall like the other two; the owner confirmed
--                                it is Pod 2's)
--                              Lotusling POD2 -> lotusling_colossal
--     Pod 3    pod3            Tempestoak POD 3 -> tempestoak
--                              Thundermaw POD 3 -> thundermaw
--                              (the owner's approved pool: these two, 1/2 each)
--     guardian                 Stormstrider GUARDIAN -> stormstrider
--
-- SIZE. Every form is replayed at the size it was supplied, whatever tier the
-- item carries: Pod 2's forms ARE the larger authored models, and "Colossal" is
-- only the label they show. Nothing here or in the builders scales them.
--
-- The idle each creature carried as a server Script is not here: SecretIdle
-- (client) drives the replayed joint tree with the same maths. The guardian's
-- run/sleep script is ported into StormstriderRun (driven by ParentAnim). The
-- nine demo Scripts themselves were deleted from the originals in the place
-- (2026-10-02; backups in output/model-backups/2026-10-02-rain-cleanup).
--==============================================================================
local SecretForms = require(script.Parent:WaitForChild("SecretForms"))

local RainForms = {}

local function load(name: string): SecretForms.FormSpec
	return (require :: any)(script:WaitForChild(name))
end

RainForms.Plants = {
	puddlepod = load("puddlepod"),
	drizzlet = load("drizzlet"),
	lotusling = load("lotusling"),
	puddlepod_colossal = load("puddlepod_colossal"),
	drizzlet_colossal = load("drizzlet_colossal"),
	lotusling_colossal = load("lotusling_colossal"),
	tempestoak = load("tempestoak"),
	thundermaw = load("thundermaw"),
} :: { [string]: SecretForms.FormSpec }

RainForms.Pods = {
	rainpod1 = load("rainpod1"),
	rainpod2 = load("rainpod2"),
	rainpod3 = load("rainpod3"),
} :: { [string]: SecretForms.FormSpec }

RainForms.Guardian = load("stormstrider")

return RainForms
