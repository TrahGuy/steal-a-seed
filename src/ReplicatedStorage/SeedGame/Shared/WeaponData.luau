--!strict
-- Steal a Seed :: WeaponData
--
-- Marigold's stock: six knockback bats and one reusable trap. Every number a
-- swing, a fling or a price depends on lives here (Rule 7) -- GameConfig holds
-- structure and curves, never what a thing is worth.
--
-- Same shape as SeedData, deliberately: an ordered array of records with stable
-- string ids, a `Get` by id, and no Instances anywhere. WeaponModel builds the
-- geometry from these records; nothing here knows what a Part is.
--
--==============================================================================
-- THESE ARE PERMANENT UNLOCKS, NOT STOCK
--
-- Bought once with cash, owned forever, saved in the profile as a set. There is
-- no quantity, no restock, no consumable and no scarcity, and there must not
-- be: the trap in particular is a TOOL that re-arms on a cooldown, so "buying
-- traps" would be a second currency loop nobody asked for.
--
--==============================================================================
-- KNOCKBACK ONLY. NO DAMAGE, EVER.
--
-- Not one number in this file touches Health, and CombatService never reads
-- one. A bat moves a player and costs them the racing line; that is the whole
-- of it. The prize in this game is the pod you are carrying and the distance
-- you still have to cover, so displacement IS the damage -- and a bat that
-- could kill would turn a chase into a deathmatch and make the corridor
-- unwalkable for anybody below the top of the ladder.
--
-- Bats also never take, delete or confiscate a pod. Being knocked over drops
-- what you were carrying exactly as a guardian's hit does, through the SAME
-- PlatformStand watcher in CarryService, and the pod lands on the road for
-- whoever gets to it first. Nothing here reaches into CarryService to move it.
--
--==============================================================================
-- POWER IS AN ABSTRACT RATING, AND THAT IS THE SECOND ATTEMPT
--
-- The first version stated fling as `FlingStuds`, the horizontal RANGE of a
-- ballistic arc, and solved the launch speed out of it the way a guardian's is
-- solved: sqrt(R*g / 2k). Two things were wrong with that and they compounded.
--
-- 1. THE NUMBER WAS A PROMISE THE PHYSICS DOES NOT KEEP. A limp body is
--    seventeen assemblies: it lands, keeps its horizontal speed and SKIDS.
--    Measured, configured -> travelled: 22 -> 59.5, 16 -> 58.7, 44 -> 147.5.
--    Two to four times, and worst on the flattest arcs.
--
-- 2. THE SOLVE FOUGHT ITS OWN LADDER. In sqrt(R*g / 2k), raising Lift LOWERS
--    the speed -- a taller arc covering the same ground is a slower one. So the
--    Sunflower, whose whole identity is a high lob, came out with the least
--    horizontal push in the shop while sitting third on the price list. There
--    is no assignment of FlingStuds that makes power climb with price while
--    lift still means anything.
--
-- So POWER is its own axis now. The launch is
--
--     horizontal = Power * SpeedPerPower          vertical = horizontal * Lift
--
-- which is the shape ThrowFX already applies (`unit * speed + up * speed*lift`),
-- so vertical is ADDED rather than traded against horizontal. Power therefore
-- decides how hard you are hit and Lift decides how high, independently -- and
-- a strictly rising Power column is a strictly rising shove, whatever any bat's
-- arc looks like.
--
-- POWER IS NOT A DISTANCE and the card does not print it as one. It is a
-- comparable rating between weapons, in the same way a Speed score is.
-- Observed travel is recorded in KB/HANDOFF, separately, where it belongs.
--
-- THE STRONGEST BAT IS STILL WEAKER THAN THE WEAKEST GUARDIAN, on purpose:
-- players hitting each other must never out-shove the thing a biome is built
-- around. Asserted at the bottom of this file against the guardians' own solve.
--
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("SeedGame")
	:WaitForChild("Shared"):WaitForChild("GameConfig"))

local WeaponData = {}

export type Palette = {
	-- The shaft, the grip binding, and the one saturated thing on the weapon.
	Wood: Color3,
	Bind: Color3,
	Accent: Color3,
	-- The card's own backdrop, so seven cards in a column are seven places.
	Card: Color3,
	CardEdge: Color3,
	-- Neon, and only where the fiction has something glowing. nil is normal.
	Glow: Color3?,
}

export type Item = {
	Id: string,
	Name: string,
	Category: string,
	Order: number,
	Price: number,
	-- One sentence. It appears on the card under the name and is the only
	-- place the special behaviour is explained in words.
	Blurb: string,
	-- What the badge on the right of the card says.
	Badge: string,

	--== BAT NUMBERS. Zero on the trap, which never swings. ==--
	-- How far in front of the swinger a hit can land, in studs.
	Reach: number,
	-- The abstract shove rating. Strictly increasing down the shelf, and the
	-- ONLY thing that decides horizontal launch speed. Not a distance.
	Power: number,
	-- Vertical launch as a fraction of the horizontal, ADDED on top of it. This
	-- is arc, not strength: it buys height and airtime and costs nothing.
	Lift: number,
	-- Degrees the launch is rotated about world up from "straight away from the
	-- swinger". 0 is a shove backwards; 70 is a shove across.
	Yaw: number,
	-- Anticipation before the hit lands, and how long the swinger is locked out
	-- of everything afterwards. Cooldown is measured from the START of a swing,
	-- so it is the real rate of fire and is always >= Windup + Recovery.
	Windup: number,
	Recovery: number,
	Cooldown: number,
	--==========================================================================
	-- HOW FAR THIS BARREL HANGS BELOW HORIZONTAL AT THE LOW HOLD
	--
	-- Degrees. `WeaponModel.GripFor` turns it into the weapon's `Tool.Grip`, and
	-- that is the whole of how a weapon sits in the hand -- there is no second
	-- rotation applied anywhere else.
	--
	-- It is per weapon because the hand sits 1.97 studs above the floor and the
	-- barrels run 4.37 to 7.80 studs. Each value here is the largest droop whose
	-- LOWEST CORNER, over every part of the built weapon, still clears the
	-- ground by 0.45 studs. Absent means level.
	--==========================================================================
	GripDroop: number?,
	-- Overrides Combat.SwingAnimation for this one weapon. Absent on all six
	-- today because there is only one published swing to point at; the field
	-- exists so a heavy bat can be given its own the day there are three.
	SwingAnimation: string?,

	Palette: Palette,
}

--==============================================================================
-- WHAT A SWING COSTS AND WHAT IT BUYS
--
-- Six bats, and not one of them is strictly better than the one below it. The
-- ladder buys REACH and FLING; it charges in WIND-UP and COOLDOWN, and it moves
-- the launch off the axis you would want it on:
--
--   Rootwood    the honest one. Nothing it does is remarkable and nothing it
--               does is bad, which is what a first bat should be.
--   Cactus      the FASTEST in the game -- 0.65s against Rootwood's 1.10 -- and
--               the shortest reach in the game. It shoves ACROSS, which is
--               nearly useless for stopping somebody and excellent for putting
--               them into a wall or off the racing line. Cheap, and never
--               obsolete: nothing else lands three hits in two seconds.
--   Sunflower   punts UP. The horizontal distance is unremarkable; what it buys
--               is seconds of somebody being nowhere near the ground, which is
--               worth more than studs when they are running past you. Pays for
--               it with the second-longest wind-up.
--   Mirewood    seventeen studs of reach, which is double the Cactus and
--               further than a guardian's grab. It is the only bat that hits
--               somebody who thinks they went round you. The sweep is 55
--               degrees off, so it rarely sends anybody back the way they came.
--   Cindercrack the hammer. 44 studs, and a 0.60s wind-up that every player on
--               the road can see coming -- 2.9s between swings means missing is
--               the whole punishment.
--   Comet       the generalist at the top: long reach, rising diagonal, and the
--               shortest cooldown of the three heavy bats. It costs sixty
--               million, and what it actually buys over Rootwood is 12 more
--               studs of fling and a launch that is hard to land against.
--
-- PRICES ARE FIRST-PASS AND SIT BELOW THE PROGRESSION LADDER AT EVERY RUNG.
-- Plot levels go 25K / 250K / 2.5M / 25M and mills go 10K / 75K / 500K / 3.5M /
-- 25M, so a player buying every bat in order is never choosing between a bat
-- and the upgrade that would earn them the next one. Rootwood at 5,000 is under
-- both first upgrades and inside one good pod sale (SeedData.SellSeconds is 30,
-- so a 170 kg pod pays for it). Comet at 60M is a goal, not a purchase.
--==============================================================================
WeaponData.Items = {
	{
		Id = "rootwood_bat",
		Name = "Rootwood Bat",
		Category = "bat",
		Order = 1,
		Price = 5000,
		Blurb = "Crooked timber wrapped in living root. Knocks straight back, and nothing more.",
		Badge = "STARTER",
		Reach = 12,
		Power = 10,
		Lift = 0.50,
		Yaw = 0,
		Windup = 0.18,
		Recovery = 0.30,
		Cooldown = 1.10,
		-- Clears by 0.50.
		GripDroop = 8,
		Palette = {
			Wood = Color3.fromRGB(126, 92, 58),
			Bind = Color3.fromRGB(88, 116, 56),
			Accent = Color3.fromRGB(158, 196, 96),
			Card = Color3.fromRGB(62, 48, 32),
			CardEdge = Color3.fromRGB(122, 92, 58),
		},
	},
	{
		Id = "cactus_club",
		Name = "Cactus Club",
		Category = "bat",
		Order = 2,
		Price = 40000,
		Blurb = "Ribbed cactus on a short handle. Swings twice as often and shoves sideways.",
		Badge = "FAST",
		Reach = 8.5,
		Power = 14,
		Lift = 0.35,
		Yaw = 70,
		Windup = 0.09,
		Recovery = 0.20,
		Cooldown = 0.65,
		-- The shortest barrel in the shop, so it can afford the most droop.
		GripDroop = 10,
		Palette = {
			Wood = Color3.fromRGB(150, 112, 66),
			Bind = Color3.fromRGB(196, 174, 122),
			Accent = Color3.fromRGB(96, 168, 92),
			Card = Color3.fromRGB(46, 56, 38),
			CardEdge = Color3.fromRGB(96, 138, 78),
		},
	},
	{
		Id = "sunflower_bonker",
		Name = "Sunflower Bonker",
		Category = "bat",
		Order = 3,
		Price = 300000,
		Blurb = "A seed-heavy flower head. Punts upward first and away second, in a burst of petals.",
		Badge = "LAUNCHER",
		Reach = 11,
		Power = 19,
		--======================================================================
		-- THE ONE AXIS THIS BAT OWNS OUTRIGHT
		--
		-- Lift is the vertical launch as a fraction of the horizontal, so apex
		-- is (k*v)^2/2g and airtime is 2kv/g -- and because vertical is ADDED
		-- rather than traded against horizontal, a big lift no longer costs
		-- this bat its shove. It is third on the price list and it hits third
		-- hardest, and it ALSO throws twice as high as anything else.
		--
		-- That was not true under the old solve, where raising lift lowered the
		-- speed: the Sunflower had the weakest push in the shop. WeaponSpec
		-- caught the shape of it, and raising lift to 1.60 fixed the apex and
		-- made the shove worse. Power driving speed fixes both.
		--
		-- 1.05 RATHER THAN 1.55, AND THAT WAS MEASURED. Under the new solve a
		-- big lift buys AIRTIME, and airtime buys ground -- a body in the air is
		-- not a body skidding to a stop. At 1.55 this bat threw people 71 and 77
		-- studs while the Mirewood, four times the price and six points more
		-- power, managed 47 and 65. A cheaper bat being visibly stronger is the
		-- one thing the ladder may not do.
		--
		-- It is still unmistakably the launcher: 1.05 is nearly twice the lift
		-- ratio of anything else on the shelf, and nothing else takes somebody
		-- off the ground for half a second. What it is no longer is the highest
		-- ARC in absolute terms -- the Comet hits twice as hard, so it throws
		-- people higher as well, which under a ladder that climbs is correct.
		--======================================================================
		Lift = 1.05,
		Yaw = 0,
		Windup = 0.42,
		Recovery = 0.55,
		Cooldown = 2.30,
		-- NEGATIVE, and it is the one weapon that needed it. The petal head is
		-- the widest in the shop and reaches sideways as far as it reaches
		-- along the shaft, so a LEVEL barrel already grazes the ground at
		-- -0.09. It carries seven degrees above horizontal instead.
		GripDroop = -7,
		Palette = {
			Wood = Color3.fromRGB(134, 100, 60),
			Bind = Color3.fromRGB(92, 136, 60),
			Accent = Color3.fromRGB(248, 196, 52),
			Card = Color3.fromRGB(72, 56, 26),
			CardEdge = Color3.fromRGB(180, 138, 46),
		},
	},
	{
		Id = "mirewood_paddle",
		Name = "Mirewood Paddle",
		Category = "bat",
		Order = 4,
		Price = 1200000,
		Blurb = "A broad swamp branch, flattened by water. Longest reach, and it sweeps across.",
		Badge = "REACH",
		Reach = 17,
		Power = 25,
		Lift = 0.40,
		Yaw = 55,
		Windup = 0.24,
		Recovery = 0.34,
		Cooldown = 1.50,
		-- The longest weapon at 7.80 studs; every extra degree costs it 0.12
		-- studs of ground clearance.
		GripDroop = 4,
		Palette = {
			Wood = Color3.fromRGB(86, 96, 74),
			Bind = Color3.fromRGB(120, 132, 88),
			Accent = Color3.fromRGB(124, 176, 148),
			Card = Color3.fromRGB(38, 52, 44),
			CardEdge = Color3.fromRGB(88, 126, 104),
		},
	},
	{
		Id = "cindercrack_bat",
		Name = "Cindercrack Bat",
		Category = "bat",
		Order = 5,
		Price = 9000000,
		Blurb = "Scorched wood split by glowing cracks. Hits hardest, and leaves you wide open.",
		Badge = "HEAVY",
		Reach = 13,
		Power = 32,
		Lift = 0.45,
		Yaw = 0,
		Windup = 0.60,
		Recovery = 0.75,
		Cooldown = 2.90,
		-- 6.34 studs of barrel.
		GripDroop = 5,
		Palette = {
			Wood = Color3.fromRGB(58, 44, 40),
			Bind = Color3.fromRGB(96, 62, 44),
			Accent = Color3.fromRGB(242, 118, 42),
			Card = Color3.fromRGB(58, 32, 26),
			CardEdge = Color3.fromRGB(158, 76, 34),
			Glow = Color3.fromRGB(255, 146, 48),
		},
	},
	{
		Id = "comet_bat",
		Name = "Comet Bat",
		Category = "bat",
		Order = 6,
		Price = 60000000,
		Blurb = "A tapered cosmic club. Launches on a rising diagonal and drags a star trail.",
		Badge = "COSMIC",
		Reach = 14,
		Power = 40,
		--======================================================================
		-- HIGH, BUT NOT THE HIGHEST
		--
		-- 0.75 here and the Comet out-arced the Sunflower -- apex 14.33 against
		-- 13.81 -- which WeaponSpec caught the moment power started driving
		-- speed. It is arithmetic rather than bad luck: vertical launch is
		-- Power * SpeedPerPower * Lift, so the strongest bat wins the height
		-- contest too unless its lift is pulled back deliberately.
		--
		-- At 0.62 the Comet still rises more steeply than every bat except the
		-- one whose whole name is the lob, and the Sunflower keeps the tallest
		-- arc in the shop by a clear margin (13.8 against 9.8).
		--======================================================================
		Lift = 0.62,
		Yaw = 25,
		Windup = 0.28,
		Recovery = 0.38,
		Cooldown = 1.80,
		-- The tail streamers reach further back than the head reaches forward,
		-- and they are what sets this one, not the tip.
		GripDroop = 8,
		Palette = {
			Wood = Color3.fromRGB(62, 58, 96),
			Bind = Color3.fromRGB(126, 118, 186),
			Accent = Color3.fromRGB(168, 214, 255),
			Card = Color3.fromRGB(34, 32, 58),
			CardEdge = Color3.fromRGB(104, 96, 168),
			Glow = Color3.fromRGB(196, 226, 255),
		},
	},
	{
		Id = "bramblejaw_trap",
		Name = "Bramblejaw Trap",
		Category = "trap",
		Order = 7,
		Price = 150000,
		Blurb = "Curved roots and thorn teeth around a glowing seed. Holds the next thief who steps in.",
		Badge = "TRAP",
		-- A trap never swings, and CombatService never reads these off it. They
		-- are zero rather than absent so every card can print the same three
		-- rows without asking whether the row exists -- and so a bat that ever
		-- arrives with a zero here is obviously wrong rather than nil-indexed.
		Reach = 0,
		Power = 0,
		Lift = 0,
		Yaw = 0,
		Windup = 0,
		Recovery = 0,
		Cooldown = 0,
		Palette = {
			Wood = Color3.fromRGB(98, 72, 44),
			Bind = Color3.fromRGB(72, 92, 48),
			Accent = Color3.fromRGB(214, 226, 118),
			Card = Color3.fromRGB(50, 44, 26),
			CardEdge = Color3.fromRGB(126, 116, 54),
			Glow = Color3.fromRGB(226, 240, 132),
		},
	},
} :: { Item }

--==============================================================================
-- THE NUMBERS THAT ARE TRUE OF EVERY WEAPON
--
-- Anything a single item cannot sensibly disagree about lives here, so there is
-- one place to move it and no chance of six copies drifting.
--==============================================================================
WeaponData.Combat = {
	--==========================================================================
	-- HOW LONG A HIT KEEPS YOU DOWN, AND HOW LONG IT CANNOT HAPPEN AGAIN
	--
	-- The tumble is about 1.1 seconds. That is deliberately far short of a
	-- guardian's -- HANDOFF measures those at 3.3 to 7.6 -- because a guardian
	-- hit is the end of a raid and a bat hit is an interruption in one.
	--
	-- FOUR DURATIONS, BECAUSE THEY ANSWER FOUR DIFFERENT QUESTIONS
	--
	-- These were two numbers doing three jobs, and the contradiction between
	-- them was the bat ragdoll bug:
	--
	--   VictimLimpSeconds was BOTH what the player should feel AND the server's
	--   safety net. The server restored the rig when it expired. But the
	--   victim's client could not possibly report back that fast -- it needed
	--   0.30s of launch guard, then 0.9s of minimum flight, then 0.35s of
	--   stillness before it would even look at standing up, so its earliest
	--   possible answer was about 1.55 seconds against a 1.1-second deadline.
	--
	-- So the server ALWAYS timed out first and restored the body while the
	-- client was still flying it. The client then ran on for another second,
	-- and any legitimate second hit arriving in that window was dropped on the
	-- floor by the client's own re-entry guard -- a victim who went limp, and
	-- did not move.
	--
	-- Split, they can each be set to what they are actually for:
	--
	--   MinLimp    the FLOOR. The client will not stand up before this even if
	--              the body has physically stopped, so a bat hit reads as a hit
	--              rather than a stumble. Nothing enforces this on the server;
	--              it is presentation and it belongs to the machine drawing it.
	--   Limp       what the player feels, and the DEADLINE the client is given.
	--              It may settle earlier -- landing against a wall often does --
	--              but at this instant it stops waiting and stands up wherever
	--              it is.
	--   Backstop   the server's safety net, and nothing else. It exists for a
	--              client that crashed, lagged or lied, and it must be LATER
	--              than the deadline or it fights the client for the body.
	--   Immunity   how long until another bat may touch this player, and it
	--              must be later than the Backstop -- a target that is still
	--              mid-flight is filtered out of every swing, so a hit landing
	--              between the two would be silently discarded.
	--
	-- THE ORDER IS THE CONTRACT: MinLimp < Limp < Backstop < Immunity. It is
	-- asserted in WeaponSpec, because every one of these numbers is individually
	-- reasonable and only their ORDER makes the system work.
	--
	-- The 0.25s between Limp and Backstop is round-trip grace: the client's
	-- "I have stopped" has to cross the wire, and a backstop that fired while
	-- that packet was in flight would be the original bug with smaller numbers.
	--==========================================================================
	VictimMinLimpSeconds = 0.9,
	VictimLimpSeconds = 1.1,
	VictimBackstopSeconds = 1.35,
	--==========================================================================
	-- THE IMMUNITY IS THE ONLY THING STOPPING A CHAIN-FLING, and it has to be
	-- longer than the fastest bat's cooldown or the Cactus Club alone locks a
	-- player on the floor forever: 0.65s of cooldown against a 1.1s tumble means
	-- the second swing lands while the first one is still playing. At 1.5 the
	-- victim is always upright and moving for at least four tenths of a second
	-- between hits, and two players with Cactus Clubs cannot do better than one.
	--==========================================================================
	HitImmunitySeconds = 1.5,
	--==========================================================================
	-- POWER -> HORIZONTAL LAUNCH SPEED
	--
	-- The whole ladder scales through this one number. 2.5 puts Rootwood at 25
	-- studs/sec and Comet at 100, against a biome-1 guardian's 114 -- so the
	-- strongest bat in the game shoves less hard than the gentlest guardian,
	-- which is the relationship the corridor is balanced around.
	--==========================================================================
	SpeedPerPower = 2.5,
	--==========================================================================
	-- THE SWING ANIMATION, WHICH IS NO LONGER WHERE THE SWING COMES FROM
	--
	-- This avatar is an R15 PHYSICS rig. Measured live, on the character the
	-- game actually spawns:
	--
	--     AnimationConstraint x15   BallSocketConstraint x14   Motor6D x0
	--
	-- So there is no Motor6D.C0 to compose against.
	--
	-- WHAT THIS BLOCK USED TO SAY, AND WHY IT WAS WRONG. It recorded that
	-- `AnimationConstraint.Transform` "is not the channel either -- written in
	-- RenderStepped, Stepped and Heartbeat it read back as -0.000 the next frame
	-- every time, and the animator never writes it either", and concluded that a
	-- custom PUBLISHED animation was the only way to swing a bat.
	--
	-- The joint was never inert. `CarryPose.client.luau` was writing
	-- `Transform = rest` to both shoulders on EVERY frame in `Stepped`, which is
	-- after the animator runs -- so it reverted the animation, and it reverted
	-- anything else that wrote there, for the whole session. Measured on the live
	-- avatar playing Roblox's own `wave`:
	--
	--     CarryPose running     right shoulder swept   0.0 deg
	--     CarryPose disabled    right shoulder swept  17.1 deg
	--
	-- With that fixed the shoulder tracks a commanded angle to within a degree
	-- (30 -> 29.4, 60 -> 59.4, 90 -> 89.6), and WeaponFX now authors the ready
	-- pose and the whole swing in degrees, per frame, with NO published asset:
	-- 22.67 studs of measured bat-tip travel through one swing.
	--
	-- That works, and it works well. Bat-tip displacement, measured twice each:
	--
	--     point      507770453    4.18 studs    <- a real, readable arc
	--     wave       507770239    2.02
	--     ToolSlash  522635514    0.21          <- Roblox's own R15 tool swing
	--     ToolLunge  522638767    0.21
	--
	-- Those numbers still stand and they are still why Roblox's own tool
	-- animations are not the answer: ToolSlash moves this rig's bat tip 0.21
	-- studs, against the 22.67 WeaponFX now produces.
	--
	-- WHY THIS IS STILL HERE. It is ToolSlash, it is real and supported, and it
	-- plays -- but it is now a garnish, not the swing. WeaponFX overrides the
	-- shoulder, elbow and wrist every `Stepped`, which is after the animator, so
	-- whatever this track does to the right arm is replaced before it is drawn;
	-- what survives is a little motion elsewhere in the body.
	--
	-- IT IS THEREFORE A CLEANUP CANDIDATE AND DELIBERATELY NOT DELETED IN THIS
	-- PASS. Removing it means touching CombatService's playback and the
	-- contact-fraction scaling below, both of which are verified working, for no
	-- visible gain. Left wired, honestly labelled, and easy to remove on purpose
	-- rather than by accident. A bat may still override it per weapon.
	--==========================================================================
	SwingAnimation = "rbxassetid://522635514",
	--==========================================================================
	-- AND HOW LONG THAT ASSET IS, WRITTEN DOWN
	--
	-- `AnimationTrack.Length` is 0 ON THE SERVER: the animation asset is never
	-- fetched there, so the number the scaling needs does not exist where the
	-- scaling happens. Measured live, this one is 0.50s -- printed by loading it
	-- on a client and waiting for Length to resolve.
	--
	-- Kept on the line below the id it describes so the two cannot drift: change
	-- the id, change this. If it is ever wrong the only symptom is a swing that
	-- plays at the wrong speed, which is why the server also prefers the real
	-- Length whenever it does happen to be non-zero.
	--==========================================================================
	SwingAnimationLength = 0.50,
	--==========================================================================
	-- WHERE IN THAT ANIMATION THE BAT ACTUALLY CONNECTS
	--
	-- A fraction of its length. Playback is scaled so this frame lands exactly
	-- on the bat's own `Windup`, which is the only way one asset can serve six
	-- weapons whose wind-ups run from 0.09 to 0.60 seconds and still have the
	-- visible strike agree with the server's hit for every one of them.
	--
	-- Scaling by TOTAL length instead -- which is what this did first -- lines
	-- the two ends up only for a bat whose wind-up happens to be the same
	-- fraction of its swing as the animation's contact is of its length. Across
	-- the six that fraction runs 0.22 to 0.42, so five of them were wrong.
	--
	-- 0.5 is a guess for ToolSlash, which is a placeholder that barely moves
	-- this rig anyway. The authored swing in tools/animation/build_swing.luau
	-- contacts at 0.444, and that is the number to put here with its id.
	--==========================================================================
	SwingAnimationContact = 0.5,
	--==========================================================================
	-- AND HOW FAR PLAYBACK MAY BE STRETCHED TO ACHIEVE THAT
	--
	-- Cactus wants the contact frame 0.09s in, which on a 0.90s animation is
	-- speed 4.4 -- a blur. Cindercrack wants it at 0.60s, which is speed 0.67.
	-- Clamped so neither end becomes unreadable; a bat outside the band takes
	-- the nearest edge and lands a few hundredths off, which is a frame or two.
	--==========================================================================
	SwingSpeedMin = 0.45,
	SwingSpeedMax = 3.0,
	--==========================================================================
	-- HOW FAR OUT OF THE SWINGER THE VICTIM IS STEPPED BEFORE THEY GO
	--
	-- ThrowFX moves the body clear before switching its limbs to collidable,
	-- because going collidable while overlapping another body wedges it or has
	-- the solver fling it. A guardian uses 5 studs and a 3-stud pop; those are
	-- sized for a creature you are standing inside. A bat lands at arm's length,
	-- so 1.4 and 0.6 is enough to separate two player capsules and small enough
	-- that the step is not itself the knockback.
	--==========================================================================
	ClearStuds = 1.4,
	ClearUpStuds = 0.6,
	-- A hit has to be able to see its target. The ray is cast between the two
	-- root parts and ignores both characters; anything else solid stops it.
	RequireLineOfSight = true,
	-- Vertical tolerance on a hit, so somebody on a ledge two studs up is still
	-- reachable and somebody on a roof is not.
	HeightTolerance = 7,
	-- How far off dead-ahead a target may be, in degrees. A bat is a swing, not
	-- an aura -- but it is a swing with a wide arc, and 75 either side is what
	-- makes a moving target hittable without pointing at them exactly.
	ArcDegrees = 75,
}

--==============================================================================
-- THE TRAP
--
-- Every number the brief fixes, in one table, so the card and the service read
-- the same second.
--==============================================================================
WeaponData.Trap = {
	-- Placed shut, opens over a second, and only bites once it is open.
	ArmSeconds = 1.0,
	-- How long a caught player is held. Two seconds is short enough that it is
	-- an interruption rather than a death sentence, and long enough that
	-- somebody with a bat can cross the gap and use it.
	HoldSeconds = 2.0,
	-- After release, and after any bat hit. Nothing can catch you during it.
	ImmunitySeconds = 4.0,
	-- An untriggered trap gives up rather than littering the road forever.
	ExpireSeconds = 20,
	-- From the moment it is PLACED, not from when it fires -- so a trap that
	-- catches somebody instantly and one that expires unused cost the same.
	PlaceCooldownSeconds = 15,
	-- How close a foot has to be, measured flat, plus how far above the jaws it
	-- may be. Flat because a player jumping over a trap should clear it.
	TriggerRadius = 4.0,
	TriggerHeight = 4.5,
	-- Refused this close to a pod or a nest marker. A trap sitting on the one
	-- tile everybody has to stand on to take a pod is not a play, it is a tax.
	NestClearanceStuds = 16,
	-- The ground has to be solid, level enough to stand on, and directly under
	-- the player -- no placing through a floor, off a ledge or in mid-air.
	MaxDropStuds = 6,
	MaxSlopeDot = 0.62,
}

--==============================================================================
-- LOOKUP
--==============================================================================
local byId: { [string]: Item } = {}
for _, item in ipairs(WeaponData.Items) do
	assert(byId[item.Id] == nil, "duplicate weapon id: " .. item.Id)
	byId[item.Id] = item
end

function WeaponData.Get(id: any): Item?
	if type(id) ~= "string" then
		return nil
	end
	return byId[id]
end

function WeaponData.IsBat(item: Item): boolean
	return item.Category == "bat"
end

--==============================================================================
-- POWER IN, HORIZONTAL SPEED OUT
--
-- One multiply, on purpose. The guardians solve sqrt(R*g / 2k) because they are
-- described by the ARC they throw; a bat is described by how hard it hits, and
-- putting a square root between the ladder and the launch is what let the
-- Sunflower sit third on price and last on shove.
--
-- ThrowFX applies `unit * speed + up * (speed * lift)`, so this is the whole
-- horizontal launch and Lift adds vertical on top of it -- which is what makes
-- the Power column and the felt shove the same ordering.
--
-- SpeedPerPower is the one number that scales the entire ladder. Move it and
-- every bat moves together; move a Power and one bat moves.
--==============================================================================
function WeaponData.LaunchSpeed(item: Item): number
	if item.Power <= 0 then
		return 0
	end
	return item.Power * WeaponData.Combat.SpeedPerPower
end

--==============================================================================
-- THE LAUNCH HANDSHAKE
--
-- Two functions, here rather than in CombatService, for one reason: a spec can
-- require this file and cannot require a service. The rule that decides whether
-- a victim's "I have stopped" is allowed to end a ragdoll is the rule most
-- worth testing in this whole subsystem, and a rule living inside a closure in
-- Start() is a rule no test can reach.
--
-- So the server calls these, the spec calls these, and there is no second copy
-- of the decision to drift.
--==============================================================================

--==============================================================================
-- IS THIS REPORT ALLOWED TO END THAT LAUNCH?
--
-- Three ways to say no, and each of them was a real failure mode:
--
--   the report carries no token   a guardian throw, or a client old enough to
--                                 predate the handshake. It must not end a BAT
--                                 launch, which is what the old argument-less
--                                 acknowledgement did to whatever was current.
--   nothing is live               a duplicate. The client reports once, but a
--                                 retry, a double-fire or a lying client must
--                                 not resurrect a launch that already ended.
--   the tokens differ            the stale one. This is the case that was
--                                 happening on every single hit: the client
--                                 could not answer inside its old deadline, so
--                                 its report arrived after the server had moved
--                                 on, and released whatever had replaced it.
--
-- Rule 4 of AGENTS.md, in one line: `quoted` came off the wire and is checked
-- for type before it is compared, so a table or a number is a no rather than an
-- error inside an event handler.
--==============================================================================
function WeaponData.AcceptsAck(live: any, quoted: any): boolean
	return type(live) == "string" and live ~= ""
		and type(quoted) == "string" and live == quoted
end

--==============================================================================
-- WHAT A BAT SENDS THE VICTIM
--
-- The three presentation numbers a bat differs by -- and they are the whole
-- difference, which is the point. A guardian sends NO style table at all, so
-- every field here is nil on that path and ThrowFX falls back to the constants
-- it had before any of this existed. That is why the guardian throw is
-- "defaulted, not branched".
--
-- The protocol fields ride along in the same table because it is already the
-- optional argument no guardian sends. A second RemoteEvent would have bought
-- nothing except another thing to create, resolve and tear down.
--==============================================================================
function WeaponData.BatThrowStyle(token: string, serverNow: number): { [string]: any }
	local C = WeaponData.Combat
	return {
		-- presentation: a swing at arm's length, no camera move, less spin
		up = C.ClearUpStuds,
		camera = false,
		tumble = 0.55,
		-- protocol
		kind = "bat",
		token = token,
		minLimp = C.VictimMinLimpSeconds,
		deadline = serverNow + C.VictimLimpSeconds,
	}
end

--==============================================================================
-- WHAT A GUARDIAN'S THROW WOULD BE, IN THE SAME UNITS
--
-- The guardians ARE described by an arc, so comparing a bat to one means
-- solving theirs. Here rather than in the assert so the spec can print it too.
--==============================================================================
function WeaponData.GuardianLaunchSpeed(biomeOrder: number): number
	local P = GameConfig.Parent
	local studs = GameConfig.parentThrowStudsFor(biomeOrder)
	return math.sqrt(studs * Workspace.Gravity / (2 * P.ThrowLift))
end

--==============================================================================
-- WHAT THE CARD SAYS
--
-- Here rather than in the panel so the shop cannot describe a weapon in terms
-- the server does not use. Three rows, the same three for every item, because a
-- card that changes shape per product is a card a player has to re-read.
--==============================================================================
export type StatLine = { label: string, value: string }

function WeaponData.StatLines(item: Item): { StatLine }
	if item.Category == "trap" then
		local T = WeaponData.Trap
		return {
			{ label = "HOLDS", value = string.format("%.0fs", T.HoldSeconds) },
			{ label = "ARMS IN", value = string.format("%.0fs", T.ArmSeconds) },
			{ label = "COOLDOWN", value = string.format("%.0fs", T.PlaceCooldownSeconds) },
		}
	end
	return {
		-- POWER, AND NO UNIT. It is a rating, comparable between weapons and
		-- deliberately not a distance: a ragdoll skids, so printing "22 studs"
		-- beside a hit that carries somebody sixty is a card that lies. Reach
		-- keeps its studs below because reach genuinely is one -- the server
		-- measures it.
		{ label = "POWER", value = string.format("%.0f", item.Power) },
		{ label = "REACH", value = string.format("%.1f studs", item.Reach) },
		{ label = "COOLDOWN", value = string.format("%.2fs", item.Cooldown) },
	}
end

function WeaponData.PriceText(item: Item): string
	return "$" .. GameConfig.compact(item.Price)
end

--==============================================================================
-- SELF-CHECKS
--
-- Asserted at require time rather than left to a test, because these are the
-- three ways this file can be wrong in a way nothing else would notice: a bat
-- that out-shoves a guardian, a cooldown shorter than the swing it gates, and
-- an immunity window a fast bat can swing through.
--==============================================================================
local weakestGuardian = WeaponData.GuardianLaunchSpeed(1)
local fastestCooldown = math.huge
local previousPower, previousPrice = -1, -1
for _, item in ipairs(WeaponData.Items) do
	if item.Category == "bat" then
		assert(WeaponData.LaunchSpeed(item) < weakestGuardian, string.format(
			"%s launches at %.1f, which is not under the weakest guardian's %.1f",
			item.Id, WeaponData.LaunchSpeed(item), weakestGuardian))
		assert(item.Cooldown >= item.Windup + item.Recovery, string.format(
			"%s has a cooldown shorter than its own swing", item.Id))
		--==================================================================
		-- THE LADDER CLIMBS, AND IT IS CHECKED HERE RATHER THAN HOPED FOR
		--
		-- Price and power both strictly increase down the shelf. This is the
		-- one invariant a future tuning pass is most likely to break by
		-- nudging a single number, and it is invisible from reading the table.
		--==================================================================
		assert(item.Power > previousPower, string.format(
			"%s has power %d, which does not exceed the bat above it (%d)",
			item.Id, item.Power, previousPower))
		assert(item.Price > previousPrice, string.format(
			"%s costs %d, which does not exceed the bat above it (%d)",
			item.Id, item.Price, previousPrice))
		previousPower, previousPrice = item.Power, item.Price
		fastestCooldown = math.min(fastestCooldown, item.Cooldown)
	end
	assert(item.Price >= 0, item.Id .. " has a negative price")
end
assert(WeaponData.Combat.HitImmunitySeconds > fastestCooldown, string.format(
	"hit immunity %.2fs must exceed the fastest bat's %.2fs cooldown, or that " ..
	"bat alone can chain-fling a player", WeaponData.Combat.HitImmunitySeconds,
	fastestCooldown))
assert(WeaponData.Combat.HitImmunitySeconds > WeaponData.Combat.VictimLimpSeconds,
	"a victim must be upright before the next hit can land")

--==============================================================================
-- THE ORDER OF THE FOUR DURATIONS IS THE CONTRACT
--
-- Every one of these numbers is individually reasonable. Only their ORDER makes
-- the system work, and the bug this guards against was exactly an order that had
-- gone wrong -- the server's safety net set EARLIER than the client could
-- possibly answer, so it always fired, and always fought the client for the body.
--
-- Asserted at load rather than in a spec alone, because a spec is run when
-- somebody remembers and this runs on every server boot.
--==============================================================================
do
	local C = WeaponData.Combat
	assert(C.VictimMinLimpSeconds < C.VictimLimpSeconds, string.format(
		"the limp floor %.2fs must be under the client's deadline %.2fs, or the " ..
		"client can never reach the deadline it was given",
		C.VictimMinLimpSeconds, C.VictimLimpSeconds))
	assert(C.VictimLimpSeconds < C.VictimBackstopSeconds, string.format(
		"the client's deadline %.2fs must be BEFORE the server's backstop %.2fs, " ..
		"or the server restores the rig while the client is still flying it",
		C.VictimLimpSeconds, C.VictimBackstopSeconds))
	assert(C.VictimBackstopSeconds < C.HitImmunitySeconds, string.format(
		"the backstop %.2fs must be before immunity ends %.2fs: a player who is " ..
		"still mid-flight is filtered out of every swing, so a hit landing " ..
		"between the two would be silently discarded",
		C.VictimBackstopSeconds, C.HitImmunitySeconds))
	--==========================================================================
	-- AND THERE HAS TO BE ROOM FOR THE ROUND TRIP
	--
	-- The gap between the client's deadline and the server's backstop is the
	-- only budget the "I have stopped" packet has to cross the wire in. Ten
	-- milliseconds would satisfy the ordering above and still be the original
	-- bug, so the margin is asserted rather than merely the order.
	--==========================================================================
	assert(C.VictimBackstopSeconds - C.VictimLimpSeconds >= 0.2, string.format(
		"only %.0fms of round-trip grace between the client deadline and the " ..
		"server backstop; 200ms is the floor",
		(C.VictimBackstopSeconds - C.VictimLimpSeconds) * 1000))
end

return WeaponData
