--!strict
--==============================================================================
-- THE INVITE A FRIEND REWARDS' SUPPLIED RIGS, AS DATA (2026-10-06)
--
-- Four rigged models the owner placed straight in the Podnappers Workspace,
-- lifted by the PlantForms generator (read-only) into one child module each.
-- The originals were not moved or changed and are still in the Workspace;
-- verified .rbxm copies (Heliothorn's aura script included) are in
-- output/model-backups/2026-10-06-invite-originals.
--
-- THE MAPPING (model -> species id, the owner's track, 2026-10-06):
--
--     invites  model                        id           rarity     $/s (unboosted)
--     1        Dustthorn (Base Form)        dustthorn    Epic         5,000
--     5        Thornbrute (First Form)      thornbrute   Legendary   25,000
--     10       Pharaothorn (Second Form)    pharaothorn  Mythic      75,000
--     20       Heliothorn (Final Form)      heliothorn   Secret     175,000
--
-- The thresholds and words are GameConfig.InviteRewards'; the species rows and
-- their incomes are SeedData.InviteSpecies'. This file is only what the forms
-- LOOK like and how they MOVE.
--
-- SIZE. One size each, the supplied one: SecretModel.BuildPlant replays these
-- at scale 1 whatever the tier, as it does the Secrets and the Rain event's
-- first forms (drawn extents, studs: Dustthorn 4.01 x 4.06 x 2.13, Thornbrute
-- 5.50 x 9.26 x 6.74, Pharaothorn 7.92 x 15.20 x 9.95, Heliothorn 14.29 x
-- 26.57 x 17.59 -- its translucent Aura sphere, 30.65 across, is left out of
-- that measure and hangs 2.6 studs below its toes).
--==============================================================================
-- THE RIGS, AS INSPECTED (2026-10-06; KB/HANDOFF.md has the full table)
--
-- One family: every form stands on an invisible anchored root plate (Base,
-- renamed Footing here, the PrimaryPart), a Motor6D tree hangs off it, and the
-- decoration is welded to the bones. No Bones, no AnimationConstraints, no
-- Animation objects or ids; each carried an AnimationController + Animator
-- (left out: SecretIdle poses anchored parts itself) and Heliothorn one Script,
-- HeliothornAura, which animated its aura only -- ported below, not run.
--
--   Dustthorn    13 Motor6Ds: Root, ShoulderL/R, ElbowL/R, HipL/R, KneeL/R,
--                AnkleL/R, Stem, Flower. A round body IS its head.
--   Thornbrute   24: + Waist, Neck, Head, Jaw, WristL/R, Tail1-3, HornL/R.
--   Pharaothorn  25: Thornbrute's without the horns, + LappetL/R, Pyramid,
--                and Crown in Flower's place.
--   Heliothorn   38: Pharaothorn's without stem, crown and pyramid, + HornL/R,
--                Sun with Ray1-8, Orbit with Orbiter1-4.
--
-- No eyelids on any of them (Eye / Pupil / EyeSocket / Shine are welded), so
-- by the owner's rule none of them blinks.
--==============================================================================
-- HOW THEY MOVE: THE PROFILES BELOW, PLAYED BY THE SHARED ANIMATOR
--
-- Every number that makes one form move differently from another is HERE, per
-- species; PlantIdles plays them all with one idle and SecretIdle walks them
-- with the gait every supplied biped uses (Emberquill's and the Secrets' hip,
-- knee and ankle chains). Distances are in the supplied model's own studs.
--
--   idle   breathing (the chest -- or Dustthorn's whole body -- lifts and
--          settles), a slow sway, the head looking about, the jaw easing open
--          with each breath, the arms hanging and swaying, the tail swinging
--          down its length, the flower or crown nodding, the headdress
--          lappets lifting. Absolute poses from rest, written every frame --
--          nothing is added to last frame's pose, so nothing drifts.
--   walk   on the walk ladder's rung for the form's height (SeedData species
--          WanderTier): 1 Tiny, 3 Huge, 4 Mega, 6 Titan.
--   carry  overhead, like the Secrets (SeedData species Carry).
--   sleep  none: nothing in this game puts a plant to sleep.
--
-- HEAVIER AND SLOWER AS IT EVOLVES: every period grows and every angle shrinks
-- from Dustthorn to Heliothorn, and the walk's duty, crouch and bob grow with
-- the body. Heliothorn is the grandest: the slowest breath, a long look about,
-- and its owner-authored aura (`aura`).
--==============================================================================
local SecretForms = require(script.Parent:WaitForChild("SecretForms"))

local InviteForms = {}

local function load(name: string): SecretForms.FormSpec
	return (require :: any)(script:WaitForChild(name))
end

-- In the order of the track: the form for 1, 5, 10 and 20 invites.
InviteForms.Order = { "dustthorn", "thornbrute", "pharaothorn", "heliothorn" }

InviteForms.Plants = {} :: { [string]: SecretForms.FormSpec }
for _, id in ipairs(InviteForms.Order) do
	InviteForms.Plants[id] = load(id)
end

local rad = math.rad

--==============================================================================
-- THE IDLE PROFILE
--
-- Periods in seconds, angles in radians. A joint the rig does not have is
-- simply not posed (Dustthorn has no Waist, Neck or tail:
-- its breath and sway ride on Root, with the hips turned back by the same so
-- its feet stay where they stand).
--==============================================================================
export type IdleProfile = {
	-- The joint the breath and the sway ride on: "Waist" (the chest over the
	-- hips) or, for a rig with no Waist, "Root" -- the whole body, with both
	-- hips turned back by the same so the feet stay where they stand.
	chest: string,
	-- One breath: the chest pitches back by `pitch` at the top of it (Root for
	-- a rig with no Waist), the jaw opens by `jaw`, the arms spread by `spread`.
	breath: { period: number, pitch: number, jaw: number, spread: number },
	-- The body's slow sway: yaw and roll about the Waist (or Root).
	sway: { period: number, yaw: number, roll: number },
	-- The head looking about (Neck), and the Head's own small tilt.
	look: { period: number, yaw: number, pitch: number, tilt: number },
	-- The arms hanging and swaying (ShoulderL/R), opposite each other.
	arms: { period: number, swing: number },
	-- The tail swinging (Tail1-3), each segment `lag` radians behind the one
	-- before and `grow` times its swing.
	tail: { period: number, yaw: number, pitch: number, lag: number, grow: number },
	-- The flower or crown on its stem (Stem, Flower / Crown).
	crown: { period: number, sway: number },
	-- The headdress lappets (LappetL/R) and the back pyramid (Pyramid).
	lappet: { period: number, lift: number },
	pyramid: { period: number, tilt: number },
	-- Heliothorn's own aura script, ported as written (PlantIdles.aura).
	aura: boolean,
}

-- The walk: SecretIdle's WalkProfile numbers for a two-legged chain walk.
export type WalkNumbers = {
	duty: number,
	reach: number,
	lift: number,
	footSwing: number,
	crouch: number,
	bob: number,
	roll: number,
	lean: number,
	-- The arms swing against the legs by this much of each leg's swing.
	armGain: number,
	-- The neck nods with each pair of steps by this much (0: no Neck).
	nod: number,
}

export type Profile = { idle: IdleProfile, walk: WalkNumbers }

InviteForms.Profiles = {
	-- The base form: small and quick, its whole body breathing and swaying.
	dustthorn = {
		idle = {
			chest = "Root",
			breath = { period = 2.8, pitch = rad(2.5), jaw = 0, spread = rad(3) },
			sway = { period = 5.0, yaw = rad(2.5), roll = rad(2) },
			look = { period = 7.0, yaw = 0, pitch = 0, tilt = 0 },
			arms = { period = 3.2, swing = rad(5) },
			tail = { period = 3.0, yaw = 0, pitch = 0, lag = 0, grow = 1 },
			crown = { period = 3.6, sway = rad(5) },
			lappet = { period = 4.0, lift = 0 },
			pyramid = { period = 6.0, tilt = 0 },
			aura = false,
		},
		walk = {
			duty = 0.6, reach = 0.3, lift = 0.2, footSwing = rad(8), crouch = 0.03, bob = 0.05,
			roll = rad(3), lean = -rad(2), armGain = -0.5, nod = 0,
		},
	},
	-- The first form: a stocky biped with a club tail.
	thornbrute = {
		idle = {
			chest = "Waist",
			breath = { period = 3.4, pitch = rad(2.2), jaw = rad(4), spread = rad(2.5) },
			sway = { period = 6.0, yaw = rad(1.8), roll = rad(1.5) },
			look = { period = 8.0, yaw = rad(12), pitch = rad(3), tilt = rad(2) },
			arms = { period = 3.8, swing = rad(4) },
			tail = { period = 3.6, yaw = rad(10), pitch = rad(2), lag = 0.6, grow = 1.25 },
			crown = { period = 4.2, sway = rad(5) },
			lappet = { period = 4.0, lift = 0 },
			pyramid = { period = 6.0, tilt = 0 },
			aura = false,
		},
		walk = {
			duty = 0.62, reach = 0.7, lift = 0.42, footSwing = rad(10), crouch = 0.07, bob = 0.09,
			roll = rad(2.5), lean = -rad(2), armGain = -0.5, nod = rad(2),
		},
	},
	-- The second form: taller and slower, the pharaoh's headdress lifting.
	pharaothorn = {
		idle = {
			chest = "Waist",
			breath = { period = 4.0, pitch = rad(1.8), jaw = rad(3), spread = rad(2) },
			sway = { period = 7.0, yaw = rad(1.4), roll = rad(1.2) },
			look = { period = 9.5, yaw = rad(10), pitch = rad(2.5), tilt = rad(1.6) },
			arms = { period = 4.4, swing = rad(3) },
			tail = { period = 4.2, yaw = rad(8), pitch = rad(1.6), lag = 0.6, grow = 1.25 },
			crown = { period = 5.0, sway = rad(3) },
			lappet = { period = 4.6, lift = rad(4) },
			pyramid = { period = 6.5, tilt = rad(1.5) },
			aura = false,
		},
		walk = {
			duty = 0.64, reach = 1.1, lift = 0.62, footSwing = rad(10), crouch = 0.11, bob = 0.13,
			roll = rad(2.2), lean = -rad(2), armGain = -0.45, nod = rad(1.5),
		},
	},
	-- The final form: the grandest -- the slowest breath, a long look about,
	-- and the owner's aura turning, pulsing and flaring every seven seconds.
	heliothorn = {
		idle = {
			chest = "Waist",
			breath = { period = 5.0, pitch = rad(1.5), jaw = rad(2.5), spread = rad(1.6) },
			sway = { period = 8.5, yaw = rad(1.0), roll = rad(0.9) },
			look = { period = 11.0, yaw = rad(8), pitch = rad(2), tilt = rad(1.2) },
			arms = { period = 5.2, swing = rad(2.2) },
			tail = { period = 5.0, yaw = rad(6), pitch = rad(1.2), lag = 0.6, grow = 1.25 },
			crown = { period = 5.0, sway = 0 },
			lappet = { period = 5.4, lift = rad(3) },
			pyramid = { period = 6.5, tilt = 0 },
			aura = true,
		},
		walk = {
			duty = 0.66, reach = 1.8, lift = 0.95, footSwing = rad(8), crouch = 0.18, bob = 0.2,
			roll = rad(2), lean = -rad(2.5), armGain = -0.4, nod = rad(1.2),
		},
	},
} :: { [string]: Profile }

-- Whether a form id is one of these four.
function InviteForms.Has(id: string): boolean
	return InviteForms.Plants[id] ~= nil
end

return InviteForms
