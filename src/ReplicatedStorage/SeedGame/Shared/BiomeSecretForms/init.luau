--!strict
--==============================================================================
-- A SECRET IN EVERY BIOME: THE OWNER'S SUPPLIED MODELS, AS DATA (2026-10-16)
--
-- Ten models the owner pasted into ServerStorage -- a secret creature and its
-- pod for each biome -- lifted by a read-only generator into one child module
-- each. The originals were not moved or changed; verified .rbxm copies (their
-- scripts included) are in output/model-backups/2026-10-16-biome-secrets-originals.
-- The plan and the owner's answers: KB/BIOME-SECRETS-PLAN.md.
--
-- THE MAPPING (folder, model -> form id; the species are SeedData.SecretSpecies):
--
--     Greenhollow Secret   Grovemaw Secret          grovemaw
--                          Secret Grenhollow Pod    grovemawpod
--     DUSTBOWL SECRET      Scourwheel Secret        scourwheel
--                          Dustbowl Secret Pod      scourwheelpod
--     Tanglemire Secret    Mirehydra Secret         mirehydra
--                          Tanglemire Secret Pod    mirehydrapod
--     Emberroot Secret     Cinderdrake (SECRET)     cinderdrake
--                          Emberroot Secret Pod     cinderdrakepod
--     Starbloom Secret     Nebulisk Secret          nebulisk
--                          Starbloom Secret Pod     nebuliskpod
--
-- SIZE. One size each, the supplied one, everywhere (the owner, 2026-10-16:
-- cradle, carried, planted, Index): SecretModel replays these at scale 1.
--
-- NO AURA SPHERES. The Cinderdrake's 90-stud and the Mirehydra's 61-stud Aura
-- balls (with the embers they gave off) are left out at the owner's word
-- (2026-10-16): they set each form's box and its lowest point, so they stood
-- the Cinderdrake's claws 21.5 studs and the Mirehydra 8.8 studs off the
-- ground. Each form now stands on its own feet. The pods keep their small auras.
--
-- THE OWNER'S SCRIPTS are not here (PodOpening, SunPulse, MawPulse,
-- MirehydraAura, CinderdrakeAura, NebuliskIdle): the client plays each over
-- the replayed rig with the same maths (SecretIdle for the creatures,
-- SecretPodMotion for the pods). Their distances were written before the owner
-- rescaled the models, so the ports multiply them by the form's ModelScale.
--==============================================================================
local SecretForms = require(script.Parent:WaitForChild("SecretForms"))

local BiomeSecretForms = {}

local function load(name: string): SecretForms.FormSpec
	return (require :: any)(script:WaitForChild(name))
end

BiomeSecretForms.Plants = {
	grovemaw = load("grovemaw"),
	scourwheel = load("scourwheel"),
	mirehydra = load("mirehydra"),
	cinderdrake = load("cinderdrake"),
	nebulisk = load("nebulisk"),
} :: { [string]: SecretForms.FormSpec }

BiomeSecretForms.Pods = {
	grovemawpod = load("grovemawpod"),
	scourwheelpod = load("scourwheelpod"),
	mirehydrapod = load("mirehydrapod"),
	cinderdrakepod = load("cinderdrakepod"),
	nebuliskpod = load("nebuliskpod"),
} :: { [string]: SecretForms.FormSpec }

return BiomeSecretForms
