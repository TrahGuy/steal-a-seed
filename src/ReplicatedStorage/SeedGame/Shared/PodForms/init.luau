--!strict
--==============================================================================
-- THE OWNER'S 25 PODS, AS DATA (2026-10-09)
--
-- One pod per ordinary plant, modelled by the owner from
-- output/imagegen/pods/pod-per-plant-v1.prompt.md and put in five Studio
-- Workspace folders ("greenhollow pods", "dustbowl pods", "tanglemire pods",
-- "emberroot pods", "starbloom pods"), lifted here by a read-only generator
-- into one child module each. The originals were not changed; later that day
-- they were moved, intact, to ServerStorage (the owner's approval), so their 25
-- scripts never run in a server and a publish keeps them out of the live map.
-- Verified .rbxm copies (their scripts included) are in
-- output/model-backups/2026-10-09-pod-originals. The plan the owner approved
-- ("approve but let claude terminal build"): KB/POD-MODELS-PLAN.md.
--
-- ART ONLY. PodModel builds a pod from here for CreatureModel.BuildPod; the
-- pod keeps its name, attributes, tags, carry, haul, prompts and labels. The
-- per-pod Scripts were not copied: PodMotion (client) plays the idles.
--
-- WITHOUT THE BASE (the owner, the same day: "remove the base if there is a
-- base below the pods"). The plate or plinth each pod stood on is left out of
-- its form (each form's `Removed`): every SeedBase, FlatBase, PlinthBevel,
-- BasePlinth, BulbPlinth, BaseRim and PlinthBase. A pod's own underside stays
-- (Nubkin's bottom plates, Raincup's goblet foot, Paddlehop's bottom rim,
-- Dunebud's front lip). Each form is measured from what stays.
--
-- TWO STYLES:
--   studded   12 pods with stud textures and the owner's idle (Motor6D waves, a
--             light's pulse), ported to PodMotion
--   lid       13 pods with a LidHinge the owner opened by OpenAmount; 12 have
--             a SizeSeam folder (for the size colour) and a GlowAccents folder,
--             and their designed ClosedWidth / ClosedHeight in pod widths.
--             Bogbonnet has neither: it is sized like a studded pod.
--==============================================================================
-- SIZE: ONE UNIFORM FACTOR, SO THE POD FILLS ITS TIER'S BOX
--
-- D is the tier's pod size (SeedData.PodDiameter, Tiny 1.66 .. Colossal 9.04).
-- A pod with the owner's designed size keeps it: ClosedWidth x D across its own
-- X, its proportions kept. Its ClosedHeight counted the base it stood on, so
-- without the base it stands that much lower; its width is its body's (every
-- base was narrower). Every other pod fills GameConfig.PodModels' box -- at
-- most MaxWidth x D wide (its wider footprint side) and MaxHeight x D tall --
-- whichever it reaches first. That is the box the carry grip, the guardian
-- haul and the nest ring are built for. Joints, lights, meshes and stud
-- textures grow with the pod: it looks exactly as built, only bigger.
--==============================================================================

local Shared = script.Parent
local SecretForms = require(Shared:WaitForChild("SecretForms"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PodForms = {}

local function load(name: string): SecretForms.FormSpec
	return (require :: any)(script:WaitForChild(name))
end

-- By biome, as the owner's folders hold them (species ids).
PodForms.Ids = {
	"nubkin", "petalpip", "spiretip", "toadcap", "bellchime",
	"dunebud", "paddlehop", "thornwhorl", "raincup", "suncrown",
	"bogbonnet", "crookreed", "snapmoss", "lanterncap", "gloomlotus",
	"cinderpaw", "emberquill", "slagbloom", "kilnhusk", "pyrelotus",
	"novaorb", "cosmospire", "voidpetal", "astralhorn", "supernovus",
} :: { string }

PodForms.Pods = {} :: { [string]: SecretForms.FormSpec }
for _, id in ipairs(PodForms.Ids) do
	PodForms.Pods[id] = load(id)
end

-- Which way each pod moves (PodMotion).
PodForms.Studded = {
	nubkin = true, petalpip = true, spiretip = true,
	dunebud = true, paddlehop = true, thornwhorl = true, raincup = true, suncrown = true,
	crookreed = true, lanterncap = true,
	cinderpaw = true, emberquill = true,
} :: { [string]: boolean }

-- The owner's lid swings this far open at OpenAmount 1 (each pod's PodOpening
-- script: 65 degrees, or 70 for the six built on the shorter script).
PodForms.LidDegrees = {
	toadcap = 65, bellchime = 65, pyrelotus = 65, slagbloom = 65, astralhorn = 65, cosmospire = 65, novaorb = 65,
	kilnhusk = 70, voidpetal = 70, snapmoss = 70, bogbonnet = 70, supernovus = 70, gloomlotus = 70,
} :: { [string]: number }

-- Whether a species is built from the owner's pod.
function PodForms.Has(id: string?): boolean
	return type(id) == "string" and PodForms.Pods[id] ~= nil
end

function PodForms.IsStudded(id: string): boolean
	return PodForms.Studded[id] == true
end

-- The owner's designed width in pod widths (ClosedWidth), or nil.
function PodForms.DesignedWidth(id: string): number?
	local spec = PodForms.Pods[id]
	local owner = spec and spec.Owner
	local w = if owner then owner.ClosedWidth else nil
	return if type(w) == "number" and w > 0 then w else nil
end

-- The whole-model factor a species' pod is built at for a tier, or nil when it
-- is not built from here.
function PodForms.Scale(id: string, tier: number?): number?
	local spec = PodForms.Pods[id]
	if not spec then
		return nil
	end
	local D = SeedData.PodDiameter(tier)
	local width, height = math.max(spec.Size.X, spec.Size.Z), spec.Size.Y
	if width <= 0 or height <= 0 then
		return nil
	end
	local designed = PodForms.DesignedWidth(id)
	if designed and spec.Size.X > 0 then
		return designed * D / spec.Size.X
	end
	local box = GameConfig.PodModels
	return D * math.min(box.MaxWidth / width, box.MaxHeight / height)
end

-- The drawn box of a species' pod at a tier (X, height, Z), or nil.
function PodForms.SizeAt(id: string, tier: number?): Vector3?
	local spec = PodForms.Pods[id]
	local scale = PodForms.Scale(id, tier)
	if not (spec and scale) then
		return nil
	end
	return spec.Size * scale
end

return PodForms
