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
	--==========================================================================
	-- AND FOUR MORE TRAPS, ONE PER BIOME PAST GREENHOLLOW
	--
	-- Approved by the owner on 2026-09-17. The shelf is a ladder in PRICE and in
	-- CONSEQUENCE, not in raw stopping power: a Bramblejaw still holds you dead
	-- still, which is the strongest effect in the list, and the expensive ones buy
	-- a DIFFERENT answer to somebody running past you with a pod -- a trip, a
	-- crawl, the pod itself knocked out of their arms, or being dragged back.
	--
	-- Every gameplay number lives in WeaponData.TrapSpecs below, keyed by the same
	-- id. These rows are the SHOP: name, price, blurb, palette, and the zeroed
	-- swing columns a trap shares with the Bramblejaw so one card shape fits all.
	--==========================================================================
	{
		Id = "dunesnap_trap",
		Name = "Dunesnap Plate",
		Category = "trap",
		Order = 8,
		Price = 750000,
		Blurb = "A cracked sandstone plate. Stand on it and the sand goes out from under you.",
		Badge = "TRAP",
		Reach = 0,
		Power = 0,
		Lift = 0,
		Yaw = 0,
		Windup = 0,
		Recovery = 0,
		Cooldown = 0,
		Palette = {
			Wood = Color3.fromRGB(196, 162, 112),
			Bind = Color3.fromRGB(152, 118, 78),
			Accent = Color3.fromRGB(232, 206, 150),
			Card = Color3.fromRGB(74, 58, 38),
			CardEdge = Color3.fromRGB(166, 132, 84),
			Glow = Color3.fromRGB(246, 226, 170),
		},
	},
	{
		Id = "mirecoil_trap",
		Name = "Mirecoil Snare",
		Category = "trap",
		Order = 9,
		Price = 3500000,
		Blurb = "A shallow mud pool ringed with live vine. They tighten, and the road turns to wading.",
		Badge = "TRAP",
		Reach = 0,
		Power = 0,
		Lift = 0,
		Yaw = 0,
		Windup = 0,
		Recovery = 0,
		Cooldown = 0,
		Palette = {
			Wood = Color3.fromRGB(58, 52, 40),
			Bind = Color3.fromRGB(66, 92, 58),
			Accent = Color3.fromRGB(124, 166, 96),
			Card = Color3.fromRGB(34, 42, 32),
			CardEdge = Color3.fromRGB(96, 126, 78),
			Glow = Color3.fromRGB(168, 222, 136),
		},
	},
	{
		Id = "cinderburst_trap",
		Name = "Cinderburst Mine",
		Category = "trap",
		Order = 10,
		Price = 15000000,
		Blurb = "Volcanic plate, glowing seams. It takes the pod out of their arms and them off their feet.",
		Badge = "TRAP",
		Reach = 0,
		Power = 0,
		Lift = 0,
		Yaw = 0,
		Windup = 0,
		Recovery = 0,
		Cooldown = 0,
		Palette = {
			Wood = Color3.fromRGB(44, 38, 38),
			Bind = Color3.fromRGB(86, 50, 36),
			Accent = Color3.fromRGB(255, 112, 42),
			Card = Color3.fromRGB(40, 26, 24),
			CardEdge = Color3.fromRGB(140, 66, 40),
			Glow = Color3.fromRGB(255, 150, 60),
		},
	},
	{
		Id = "starlock_trap",
		Name = "Starlock Anchor",
		Category = "trap",
		Order = 11,
		Price = 60000000,
		Blurb = "A cosmic anchor on a violet base. It pulls the thief back to it, then lets them crawl away.",
		Badge = "TRAP",
		Reach = 0,
		Power = 0,
		Lift = 0,
		Yaw = 0,
		Windup = 0,
		Recovery = 0,
		Cooldown = 0,
		Palette = {
			Wood = Color3.fromRGB(52, 42, 86),
			Bind = Color3.fromRGB(92, 74, 150),
			Accent = Color3.fromRGB(168, 140, 255),
			Card = Color3.fromRGB(32, 28, 58),
			CardEdge = Color3.fromRGB(110, 92, 180),
			Glow = Color3.fromRGB(198, 224, 255),
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
	-- A bat hit is far shorter than a guardian's -- HANDOFF measures those at
	-- 3.3 to 7.6 seconds -- because a guardian hit is the end of a raid and a
	-- bat hit is an interruption in one. It is not, however, a SHOVE, and that
	-- mistake is the whole history of this block.
	--
	--==========================================================================
	-- WHAT WAS WRONG THE FIRST TIME: ONE NUMBER, THREE JOBS
	--
	-- `VictimLimpSeconds` was BOTH what the player should feel AND the server's
	-- safety net, and the client could not answer inside it. The server timed
	-- out on every hit and restored the rig while the client was still flying
	-- it. Fixed in 147535c by splitting the number.
	--
	--==========================================================================
	-- WHAT WAS WRONG THE SECOND TIME, AND IT IS WHY THESE ARE NOT CLOCKS
	--
	-- The split kept a bad assumption: that a bat "lands almost immediately --
	-- it is a shove, not a flight". Two real players disproved it. The victim
	-- did not visibly fall, did not stay down, and stood up on their own.
	--
	-- A DEADLINE MEASURED FROM THE HIT DOES NOT PROVE THE BODY HAS FALLEN. It
	-- expires just as happily while the victim is still upright, still in the
	-- air, or -- the case that was actually happening -- while the server's
	-- disabled AnimationConstraints have not yet reached the victim's machine,
	-- so the impulse was applied to a rig the animator was still holding in its
	-- standing pose. A rigid body slid, a clock ran out, and it stood up.
	--
	-- So recovery is not on a clock any more. It is on EVENTS, and the clocks
	-- below only bound them:
	--
	--   MinLimp     the floor, from the hit. The body may not stand before it,
	--               however quickly it lands.
	--   Knockdown   how long it stays limp AFTER IT TOUCHES THE GROUND. This is
	--               the number that makes a hit read as a knockdown rather than
	--               a stumble, and it is measured from the landing because that
	--               is the moment the player can see.
	--   Emergency   the client's failure containment. Not the animation: if
	--               this fires, something went wrong and the log says so.
	--   Backstop    the server's failure containment, behind the client's.
	--   PostRecovery  a short window of protection at the moment the victim
	--               stands, so two attackers cannot knock them down again on
	--               the exact frame they get up.
	--   Immunity    the immediate post-hit window, and the anti-chain guarantee
	--               against the fastest bat's cooldown.
	--
	-- THE ORDER IS STILL THE CONTRACT: MinLimp < Emergency < Backstop, with
	-- room between the last two for the round trip. Immunity no longer has to
	-- outlast the backstop -- a victim is untargetable for as long as `flying`
	-- holds their token, which is the whole ragdoll however long it takes, and
	-- PostRecovery covers the seam as they stand.
	--
	-- EXPECTED TOTAL, which is an OUTCOME and not a setting: roughly 1.4 to 2.2
	-- seconds, depending on the weapon and what the body hits on the way down.
	-- If it is coming out at the Emergency value, the landing detection is not
	-- working and the number to change is not in this block.
	--==========================================================================
	--==========================================================================
	-- 1.4, MEASURED, NOT 0.9 GUESSED
	--
	-- 0.9 was carried over from the version the owner rejected, and measuring the
	-- real thing is what showed why it could never have worked. A rootwood hit
	-- puts the victim on the ground 0.75s after impact -- the body genuinely
	-- falls, torso up-vector 0.16, almost flat -- and the old floor then stood
	-- them up at 1.14s. That is 0.39 SECONDS of lying on the floor.
	--
	-- The fall was real. Nobody could see it. A knockdown that is over in four
	-- tenths of a second reads as a stumble, which is exactly the report: "does
	-- not visibly fall or remain knocked down".
	--
	-- So the floor is the bottom of the band the owner asked for, and the weakest
	-- bat in the game now holds the victim down for 0.65s after they land instead
	-- of 0.39s. Stronger bats fly longer and finish later on their own.
	--==========================================================================
	VictimMinLimpSeconds = 1.4,
	VictimKnockdownHoldSeconds = 0.5,
	--==========================================================================
	-- 3.3, BECAUSE THE STRONGEST BAT IS IN THE AIR FOR TWO SECONDS
	--
	-- THIS EXCEEDS THE 2.5-3.0 THE BRIEF SUGGESTED, deliberately, and the whole
	-- six-bat ladder measured on a real client is why:
	--
	--     rootwood      touched 0.57s   recovered 1.43s
	--     cactus        touched 0.72s   recovered 1.42s
	--     sunflower     touched 1.00s   recovered 1.55s
	--     mirewood      touched 1.08s   recovered 1.60s
	--     cindercrack   touched 1.15s   recovered 1.72s
	--     comet         touched 2.05s   recovered 2.62s
	--
	-- The Comet throws its victim 138 studs. Two seconds of that is FLIGHT, and
	-- flight is launch speed and lift -- both locked. At 3.0 the top of the
	-- ladder had 0.38s of margin, and a victim who lands off a ledge or down a
	-- slope would spend it and be emergency-recovered on a hit that was working
	-- perfectly.
	--
	-- 3.3 gives that same hit 0.68s. It is the shortest guardian ragdoll HANDOFF
	-- has measured, which sounds alarming and is not: this is the number that
	-- fires when the landing detection FAILS, and it fired on none of the six.
	-- What a player experiences is the floor plus their own fall -- 1.4 to 2.7
	-- measured -- and that is the number held against guardian length below.
	--
	-- These were 2.8 and 3.2 until the two bats at the ends of the ladder were
	-- measured, and the Comet does not fit behind 2.8 with any margin worth
	-- having:
	--
	--     rootwood  touched down 0.47s, recovered 1.42s   (0.95s on the ground)
	--     comet     touched down 1.89s, recovered 2.45s   (0.56s on the ground)
	--
	-- The Comet's 1.89 seconds is FLIGHT, and flight is launch speed and lift --
	-- both locked. So the only honest place to put the emergency is behind the
	-- longest legitimate fall, and 2.8 left the strongest bat 0.35s of margin
	-- against a body that might land later still off a ledge or up a slope.
	--
	-- This is the only reason the numbers moved. The emergency is not the
	-- animation and raising it does not make a single hit longer -- what ends a
	-- bat ragdoll is the landing, and both bats above ended on theirs.
	--==========================================================================
	VictimEmergencySeconds = 3.3,
	VictimBackstopSeconds = 3.7,
	VictimPostRecoverySeconds = 0.4,
	--==========================================================================
	-- THE IMMUNITY IS THE ONLY THING STOPPING A CHAIN-FLING, and it has to be
	-- longer than the fastest bat's cooldown or the Cactus Club alone locks a
	-- player on the floor forever: 0.65s of cooldown means the second swing
	-- would otherwise land while the first tumble is still playing.
	--
	-- IT IS NO LONGER THE ONLY GUARD, and it is no longer the longest one. A
	-- victim is filtered out of every swing for as long as `flying` holds their
	-- launch token, and that now outlives this window -- so the real protection
	-- is the ragdoll itself, this covers the moment before it is established,
	-- and PostRecovery covers the moment after it ends.
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
-- WHAT IS TRUE OF EVERY TRAP, WHATEVER IT DOES
--
-- PLACEMENT AND SAFETY ONLY. This table used to carry the Bramblejaw's timings
-- as well -- arm, hold, expiry, cooldown, trigger size -- and CombatService read
-- them for "the trap". With five traps that is exactly the shape that cannot
-- work: one of them holds you still for two seconds and another drags you nine
-- studs and lets you crawl, and they do not share a single duration.
--
-- So the timings moved to TrapSpecs, keyed by item id, and what is left here is
-- the part no trap may disagree about: where one may be set, how far from the
-- things a player has to be able to stand on, and how long you are safe after
-- one has had you.
--==============================================================================
WeaponData.Trap = {
	-- After ANY trap effect ends, and after any bat hit. Nothing can catch you
	-- during it, which is what stops a corridor of traps being a corridor.
	ImmunitySeconds = 4.0,
	-- Refused this close to a pod or a nest marker. A trap sitting on the one
	-- tile everybody has to stand on to take a pod is not a play, it is a tax.
	NestClearanceStuds = 16,
	--==========================================================================
	-- AND THIS CLOSE TO ANYTHING A PLAYER HAS TO WALK ONTO
	--
	-- The safe field already covers the hub, the stall, the spawn, Marigold and
	-- every plot with its mill and its soil -- CombatService refuses the whole
	-- rectangle. This is the belt to that braces: the tagged furniture a player
	-- is REQUIRED to approach, wherever it ends up standing. A trap on the tile
	-- in front of a biome gate or a plot sign is not an ambush, it is a toll.
	--==========================================================================
	ProtectedClearanceStuds = 14,
	-- The ground has to be solid, level enough to stand on, and directly under
	-- the player -- no placing through a floor, off a ledge or in mid-air.
	MaxDropStuds = 6,
	MaxSlopeDot = 0.62,
	-- Two traps may not overlap: a new one is refused within this many times the
	-- trigger radius of one already down. Stacking two effects on one step is the
	-- thing every rule below is written to prevent.
	SeparationRadiusScale = 2,
}

--==============================================================================
-- THE FIVE TRAPS, AND EVERY NUMBER THAT MAKES THEM DIFFERENT
--
-- ONE SPECIFICATION PER ITEM ID, and CombatService dispatches on `Effect`. The
-- alternative -- five branches threaded through the service -- was the thing the
-- brief refused, and rightly: the service already owns the ragdoll handshake,
-- the restraint, the placement validation and the cleanup, and none of those
-- five copies would stay in step.
--
-- EFFECTS, and what each one costs the victim:
--
--   root   WalkSpeed 0 and no jump, for a fixed time. The Bramblejaw, unchanged.
--   trip   a short ragdoll with almost no push. You are down, not thrown.
--   slow   a movement MULTIPLIER for a time, with jumping locked for the first
--          second only. You can still steer, still swing, still fight.
--   blast  the carried pod comes off, then a launch down the bat pipeline --
--          weaker than the weakest bat, and backward rather than up.
--   pull   one yank toward the trap, obstruction-checked, then a slow.
--
-- WHY THE DURATIONS CLIMB WITH PRICE AND THE STOPPING POWER DOES NOT: a root is
-- the harshest thing that can happen to somebody carrying a Colossal pod, and it
-- is the cheapest trap on the shelf. What the money buys is reach into the rest
-- of the fight -- a pod on the floor, a body dragged back to you, four seconds of
-- wading -- and a longer window in which to use it.
--==============================================================================
export type TrapSpec = {
	Effect: string,
	-- Opens, glows, heats up. It only bites once it is armed, which is the second
	-- a player gets to walk away.
	ArmSeconds: number,
	-- How long an untriggered trap sits there before it gives up.
	ExpireSeconds: number,
	-- From the moment it is PLACED, not from when it fires.
	PlaceCooldownSeconds: number,
	-- How close a foot has to be, measured FLAT, plus how far above the trap it
	-- may be. Flat because jumping over a trap has to clear it.
	TriggerRadius: number,
	TriggerHeight: number,
	-- How long the effect lasts on the victim. For a launch it is how long they
	-- are counted as being in it, which is what the immunity is measured from.
	EffectSeconds: number,
	-- Movement as a FRACTION of whatever the victim's speed would otherwise be.
	-- 0 for a root. nil for anything that does not touch movement.
	MoveMultiplier: number?,
	-- Jumping is disabled for this long, from the trigger. A root locks it for
	-- the whole hold; a slow locks the first second so the answer to mud is not
	-- "hop out of it", and then hands it back while the slow runs on.
	JumpLockSeconds: number,
	-- Launch numbers, for `trip` and `blast` only. Horizontal studs per second
	-- and the vertical share of it, exactly as a bat's Power and Lift resolve --
	-- see LaunchSpeed. MinLimp is the floor on how long the victim sees
	-- themselves down.
	LaunchSpeed: number?,
	LaunchLift: number?,
	LaunchMinLimp: number?,
	-- Pull numbers, for `pull` only.
	PullStuds: number?,
	-- Whether the victim's carried pod is dropped, through CarryService.Drop and
	-- nothing else.
	DropsPod: boolean,
	-- Which geometry WeaponModel builds, and how it poses while arming.
	Model: string,
	-- What the countdown over the victim says, and in which colour. "root" is the
	-- red TRAPPED label the Bramblejaw has always had; "slow" is amber, and says
	-- SLOWED, because a player who can still move needs to know that.
	Status: string?,
	-- The one line the shop card leads with.
	EffectText: string,
}

WeaponData.TrapSpecs = {
	--==========================================================================
	-- THE BRAMBLEJAW, UNCHANGED
	--
	-- Every number here is the number this trap has always had. It is written
	-- down per-trap now instead of as "the trap", and that is the whole of the
	-- change: 1.0 to arm, 2.0 held, 20 to expire, 15 to place again, 4.0 flat and
	-- 4.5 up. Anything different would be a balance change nobody asked for.
	--==========================================================================
	bramblejaw_trap = {
		Effect = "root",
		ArmSeconds = 1.0,
		ExpireSeconds = 20,
		PlaceCooldownSeconds = 15,
		TriggerRadius = 4.0,
		TriggerHeight = 4.5,
		EffectSeconds = 2.0,
		MoveMultiplier = 0,
		JumpLockSeconds = 2.0,
		DropsPod = false,
		Model = "jaw",
		Status = "root",
		EffectText = "ROOT",
	},
	--==========================================================================
	-- DUNESNAP: THE SAND GOES OUT FROM UNDER YOU
	--
	-- A trip, not a throw. The launch numbers are deliberately tiny -- 7 studs a
	-- second with barely any lift -- because what this trap sells is the 1.1
	-- seconds on the floor, and a plate that flung people would be a cheap
	-- Cinderburst. It does NOT take the pod: a thief who trips over a plate gets
	-- up still holding it, which is what keeps this the entry-level answer.
	--==========================================================================
	dunesnap_trap = {
		Effect = "trip",
		ArmSeconds = 0.8,
		ExpireSeconds = 24,
		PlaceCooldownSeconds = 16,
		TriggerRadius = 4.4,
		TriggerHeight = 4.5,
		-- The window the victim is counted as being in the trip, which is what
		-- the four seconds of immunity is measured from. The ragdoll itself ends
		-- when the body reports landing, exactly as a bat's does.
		EffectSeconds = 1.1,
		JumpLockSeconds = 0,
		LaunchSpeed = 7,
		LaunchLift = 0.30,
		LaunchMinLimp = 1.1,
		DropsPod = false,
		Model = "plate",
		EffectText = "TRIP",
	},
	--==========================================================================
	-- MIRECOIL: THE ROAD TURNS TO WADING
	--
	-- 35% of whatever they would otherwise be doing, for four seconds, and the
	-- multiplier is the point: it is a fraction of the SPEED THEY HAVE, so a
	-- billionaire sprinting past at 90 is cut to 31 and a beginner at 20 is cut
	-- to 7. A flat number would be a nerf to the rich and a root to everybody
	-- else.
	--
	-- JUMP LOCKED FOR ONE SECOND, NOT FOUR. Long enough that the first instinct
	-- -- hop out of it -- does not work; short enough that a player who is being
	-- chased through mud still has their best move back while it matters.
	--==========================================================================
	mirecoil_trap = {
		Effect = "slow",
		ArmSeconds = 1.2,
		ExpireSeconds = 26,
		PlaceCooldownSeconds = 19,
		TriggerRadius = 4.6,
		TriggerHeight = 4.5,
		EffectSeconds = 4.0,
		MoveMultiplier = 0.35,
		JumpLockSeconds = 1.0,
		DropsPod = false,
		Model = "pool",
		Status = "slow",
		EffectText = "SLOW 35%",
	},
	--==========================================================================
	-- CINDERBURST: THE POD COMES OFF FIRST
	--
	-- The only trap that touches a carry, and the order is not negotiable: the
	-- pod is dropped through CarryService.Drop at the feet they are still
	-- standing on, and only then does the launch begin. Backward and up, down the
	-- same handshake a bat uses -- one token, one ragdoll, one backstop.
	--
	-- WEAKER THAN THE ROOTWOOD, which is asserted at load below. The cheapest bat
	-- launches at 25 studs a second; this is 16 with more of it turned upward, so
	-- the victim goes over rather than away. A trap that out-flung the weakest bat
	-- would make the bat pointless at a fortieth of the price.
	--==========================================================================
	cinderburst_trap = {
		Effect = "blast",
		ArmSeconds = 1.4,
		ExpireSeconds = 26,
		PlaceCooldownSeconds = 25,
		TriggerRadius = 4.2,
		TriggerHeight = 4.5,
		EffectSeconds = 1.4,
		JumpLockSeconds = 0,
		LaunchSpeed = 16,
		LaunchLift = 0.85,
		LaunchMinLimp = 1.4,
		DropsPod = true,
		Model = "mine",
		EffectText = "BLAST/DROP",
	},
	--==========================================================================
	-- STARLOCK: IT BRINGS THEM BACK TO YOU
	--
	-- One yank of up to eight studs toward the anchor, then 40% for three
	-- seconds. The pull is a SINGLE obstruction-checked move and not a
	-- constraint: an AlignPosition strong enough to drag a player is a thing that
	-- can survive a death, a respawn, a streaming-out or a service restart, and
	-- four of those five are how a permanent restraint becomes a permanent bug.
	--
	-- It does not take the pod. Dragging somebody back into the fight WITH their
	-- pod is the point -- the owner wanted a chance to hit them, not the loot.
	--==========================================================================
	starlock_trap = {
		Effect = "pull",
		ArmSeconds = 1.5,
		ExpireSeconds = 28,
		PlaceCooldownSeconds = 30,
		TriggerRadius = 4.2,
		TriggerHeight = 4.5,
		EffectSeconds = 3.0,
		MoveMultiplier = 0.40,
		JumpLockSeconds = 0.6,
		PullStuds = 8,
		DropsPod = false,
		Model = "anchor",
		Status = "slow",
		EffectText = "PULL/SLOW",
	},
} :: { [string]: TrapSpec }

--==============================================================================
-- THE ONE WAY TO ASK WHAT A TRAP DOES
--
-- Takes an item or an id, so a caller with either does not have to convert. Nil
-- for anything that is not a trap this file ships, which is what lets
-- CombatService refuse an unknown trap rather than fall back to somebody else's
-- numbers.
--==============================================================================
function WeaponData.TrapSpec(itemOrId: any): TrapSpec?
	local id = if type(itemOrId) == "table" then (itemOrId :: any).Id else itemOrId
	if type(id) ~= "string" then
		return nil
	end
	return (WeaponData.TrapSpecs :: any)[id]
end

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
		--==================================================================
		-- THE SPIN IS THE GUARDIAN'S NOW. THE DISTANCE IS NOT.
		--
		-- This was 0.55 -- a bat "tumbles less" -- and it was the wrong half of
		-- the guardian to turn down. What the owner rejected was the PHYSICAL
		-- LANGUAGE: limbs that do not read as limp, a body that does not read as
		-- falling. Angular velocity is most of that language, and halving it
		-- halved the one thing the hit needed.
		--
		-- So the tumble is 1.0, the tested guardian value, and the three things
		-- that make a guardian a guardian are still turned off or down: it does
		-- not take the camera, it is stepped 0.6 studs clear instead of 3, and
		-- its launch speed is the power ladder rather than a thrown arc.
		--
		-- Distance is untouched. Angular velocity does not move a body.
		--==================================================================
		up = C.ClearUpStuds,
		camera = false,
		tumble = 1.0,
		-- protocol
		kind = "bat",
		token = token,
		--==================================================================
		-- THE TERMS OF THE LANDING, NOT A DEADLINE TO STAND UP ON
		--
		-- `deadline` used to be the moment the client stopped waiting and
		-- stood the body up wherever it was. That is what the owner saw and
		-- rejected: it expires just as happily on a victim who never fell.
		--
		-- It is EMERGENCY containment now, and the two numbers above it are
		-- what actually end a bat ragdoll -- a floor from the hit, and a hold
		-- from the moment the body touches the ground. If `emergency` is what
		-- ends a hit, the landing detection failed and the log says so.
		--==================================================================
		minLimp = C.VictimMinLimpSeconds,
		groundHold = C.VictimKnockdownHoldSeconds,
		emergency = serverNow + C.VictimEmergencySeconds,
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
		--======================================================================
		-- FOUR ROWS FOR A TRAP, AND NOT ONE OF THEM IS A BAT'S
		--
		-- A trap has no power and no reach, and printing either would be the card
		-- lying about what it sells. What a buyer actually compares is WHAT it
		-- does, HOW LONG for, how long they have to wait for it to arm, and how
		-- long until they can set another -- in that order, because the first two
		-- are the purchase and the last two are the cost of using it.
		--======================================================================
		local spec = WeaponData.TrapSpec(item)
		if not spec then
			return {}
		end
		return {
			{ label = "EFFECT", value = spec.EffectText },
			{ label = "DURATION", value = string.format("%.1fs", spec.EffectSeconds) },
			{ label = "ARMS IN", value = string.format("%.1fs", spec.ArmSeconds) },
			{ label = "COOLDOWN", value = string.format("%.0fs", spec.PlaceCooldownSeconds) },
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
--==============================================================================
-- A VICTIM IS UNTARGETABLE FOR THE WHOLE RAGDOLL, NOT FOR A FIXED WINDOW
--
-- This asserted `HitImmunitySeconds > VictimLimpSeconds` -- immunity outlasting
-- the tumble -- and it stopped being the right question when the tumble stopped
-- being a fixed length. A bat ragdoll now ends when the body has landed, which
-- is usually 1.4-2.2s and is bounded rather than known.
--
-- What guarantees the property instead is `flying`: CombatService filters a
-- player out of every swing for as long as their launch token is live, however
-- long that is, and applies PostRecovery at the moment it clears. So the seam
-- this used to protect is covered at both ends by construction.
--==============================================================================
assert(WeaponData.Combat.VictimPostRecoverySeconds > 0,
	"a victim with no post-recovery window can be knocked down on the frame " ..
	"they stand up")

--==============================================================================
-- AND EVERY TRAP HAS TO BE A TRAP
--
-- Five specifications, one per trap on the shelf, and every one of them is read
-- by a service that cannot check them: CombatService dispatches on `Effect` and
-- applies whatever numbers it finds. A missing spec, an effect nobody
-- implements, a multiplier of 1.4 or a launch that out-flings the cheapest bat
-- would all be invisible until somebody stepped on it in a live raid.
--
-- REFUSED AT REQUIRE, so a bad trap is a server that does not boot rather than a
-- fight that does not make sense.
--==============================================================================
do
	local EFFECTS = { root = true, trip = true, slow = true, blast = true, pull = true }
	local MODELS = { jaw = true, plate = true, pool = true, mine = true, anchor = true }
	local weakestBat = math.huge
	local trapCount = 0
	for _, item in ipairs(WeaponData.Items) do
		if item.Category == "bat" then
			weakestBat = math.min(weakestBat, WeaponData.LaunchSpeed(item))
		end
	end

	for _, item in ipairs(WeaponData.Items) do
		if item.Category ~= "trap" then
			continue
		end
		trapCount += 1
		local spec = WeaponData.TrapSpec(item)
		assert(spec, string.format("trap %s has no entry in WeaponData.TrapSpecs", item.Id))
		local s = spec :: TrapSpec
		assert(EFFECTS[s.Effect], string.format(
			"trap %s has effect %q, which no service implements", item.Id, tostring(s.Effect)))
		assert(MODELS[s.Model], string.format(
			"trap %s asks for model %q, which WeaponModel cannot build",
			item.Id, tostring(s.Model)))

		for field, value in pairs({
			ArmSeconds = s.ArmSeconds,
			ExpireSeconds = s.ExpireSeconds,
			PlaceCooldownSeconds = s.PlaceCooldownSeconds,
			TriggerRadius = s.TriggerRadius,
			TriggerHeight = s.TriggerHeight,
			EffectSeconds = s.EffectSeconds,
		}) do
			assert(type(value) == "number" and value == value and value > 0
				and value < math.huge, string.format(
				"trap %s has %s = %s, which is not a positive finite number",
				item.Id, field, tostring(value)))
		end

		--======================================================================
		-- ARMING MUST FIT INSIDE THE TRAP'S OWN LIFE
		--
		-- A trap that took longer to arm than it lasts would sit there, never
		-- bite, and expire -- a purchase that does nothing, with no error.
		--======================================================================
		assert(s.ArmSeconds < s.ExpireSeconds, string.format(
			"trap %s arms in %.1fs but expires after %.1fs", item.Id,
			s.ArmSeconds, s.ExpireSeconds))
		--======================================================================
		-- AND THE EFFECT MUST END BEFORE THE NEXT TRAP CAN BE SET
		--
		-- Cooldown longer than effect plus immunity is what stops one owner
		-- keeping one victim permanently under a trap effect. It is the single
		-- most important number in this table and the least visible.
		--======================================================================
		assert(s.PlaceCooldownSeconds > s.EffectSeconds + WeaponData.Trap.ImmunitySeconds,
			string.format(
			"trap %s: a %.0fs cooldown does not outlast its own %.1fs effect plus " ..
			"%.1fs of immunity, so one owner could hold one victim forever",
			item.Id, s.PlaceCooldownSeconds, s.EffectSeconds,
			WeaponData.Trap.ImmunitySeconds))
		assert(s.JumpLockSeconds >= 0 and s.JumpLockSeconds <= s.EffectSeconds,
			string.format(
			"trap %s locks jumping for %.1fs, which is outside its own %.1fs effect",
			item.Id, s.JumpLockSeconds, s.EffectSeconds))

		if s.MoveMultiplier ~= nil then
			assert(s.MoveMultiplier >= 0 and s.MoveMultiplier <= 1, string.format(
				"trap %s has a movement multiplier of %s: a trap may slow or stop a " ..
				"player and may never speed one up", item.Id, tostring(s.MoveMultiplier)))
		end
		if s.Effect == "slow" or s.Effect == "pull" then
			assert(s.MoveMultiplier ~= nil and s.MoveMultiplier > 0, string.format(
				"trap %s slows without a multiplier", item.Id))
			assert(s.Status == "slow", string.format(
				"trap %s slows but does not label itself as a slow, so the victim " ..
				"would read a root's countdown", item.Id))
		end
		if s.Effect == "root" then
			assert(s.MoveMultiplier == 0 and s.Status == "root", string.format(
				"trap %s roots without stopping the player", item.Id))
		end
		if s.Effect == "trip" or s.Effect == "blast" then
			assert(type(s.LaunchSpeed) == "number" and (s.LaunchSpeed :: number) > 0
				and type(s.LaunchLift) == "number", string.format(
				"trap %s launches without launch numbers", item.Id))
			--==================================================================
			-- NO TRAP OUT-FLINGS THE CHEAPEST BAT
			--
			-- The bat ladder is the thing a player buys for knockback, and a
			-- $750K plate that threw further than a $5K bat would make the whole
			-- shelf above it decoration.
			--==================================================================
			assert((s.LaunchSpeed :: number) < weakestBat, string.format(
				"trap %s launches at %.1f, which is not under the cheapest bat's %.1f",
				item.Id, s.LaunchSpeed, weakestBat))
		end
		if s.Effect == "pull" then
			assert(type(s.PullStuds) == "number" and (s.PullStuds :: number) > 0
				and (s.PullStuds :: number) <= 12, string.format(
				"trap %s pulls %s studs; over a dozen is a teleport",
				item.Id, tostring(s.PullStuds)))
		end
		assert(type(s.DropsPod) == "boolean", item.Id .. " does not say whether it drops a pod")
		assert(#WeaponData.StatLines(item) > 0, item.Id .. " has no shop stats")
	end
	assert(trapCount == 5, string.format(
		"the approved shelf has five traps, one per biome; this file has %d", trapCount))
end

--==============================================================================
-- THE ORDER OF THE DURATIONS IS THE CONTRACT
--
-- Every one of these numbers is individually reasonable. Only their ORDER makes
-- the system work, and both bat bugs were an order that had gone wrong -- first
-- the server's net set earlier than the client could answer, then a client
-- deadline set earlier than a body can fall.
--
-- Asserted at load rather than in a spec alone, because a spec is run when
-- somebody remembers and this runs on every server boot.
--==============================================================================
do
	local C = WeaponData.Combat

	--==========================================================================
	-- THE FLOOR HAS TO LEAVE ROOM FOR AN ACTUAL LANDING
	--
	-- Floor plus ground-hold is the FASTEST a bat ragdoll can legally end, and
	-- it has to be comfortably under the emergency or every hit would be
	-- emergency-recovered and nobody would notice.
	--==========================================================================
	assert(C.VictimMinLimpSeconds + C.VictimKnockdownHoldSeconds
		< C.VictimEmergencySeconds, string.format(
		"floor %.2fs + ground hold %.2fs must be under the emergency %.2fs, or " ..
		"a bat can never recover normally",
		C.VictimMinLimpSeconds, C.VictimKnockdownHoldSeconds,
		C.VictimEmergencySeconds))
	assert(C.VictimKnockdownHoldSeconds >= 0.35
		and C.VictimKnockdownHoldSeconds <= 0.55, string.format(
		"a %.2fs hold on the ground is outside the 0.35-0.55 the brief fixes: " ..
		"under it a knockdown reads as a stumble, over it as a stun",
		C.VictimKnockdownHoldSeconds))
	--==========================================================================
	-- AND THE FLOOR IS THE BOTTOM OF THE BAND
	--
	-- The fastest a bat can legally end is the floor itself, because a body that
	-- lands early waits for it. So the floor IS the bottom of the intended
	-- 1.4-2.2s of helplessness, and asserting it is the only way this file can
	-- speak about that band at all -- everything above the bottom depends on how
	-- long the body was in the air, which no data file knows.
	--==========================================================================
	assert(C.VictimMinLimpSeconds >= 1.4, string.format(
		"a %.2fs floor is under the 1.4s bottom of the band: measured, a rootwood " ..
		"victim is on the ground by 0.75s, so anything less is a stumble",
		C.VictimMinLimpSeconds))
	assert(C.VictimMinLimpSeconds < 2.2, string.format(
		"a %.2fs floor is already at the TOP of the band, which leaves the " ..
		"stronger bats nowhere to be longer than the weakest",
		C.VictimMinLimpSeconds))
	assert(C.VictimEmergencySeconds < C.VictimBackstopSeconds, string.format(
		"the client's emergency %.2fs must be BEFORE the server's backstop " ..
		"%.2fs, or the server restores the rig while the client still owns it",
		C.VictimEmergencySeconds, C.VictimBackstopSeconds))

	--==========================================================================
	-- AND THERE HAS TO BE ROOM FOR THE ROUND TRIP
	--
	-- The gap between the client's last word and the server's backstop is the
	-- only budget the "I have stopped" packet has to cross the wire in. Ten
	-- milliseconds would satisfy the ordering above and still be the first bug.
	--==========================================================================
	assert(C.VictimBackstopSeconds - C.VictimEmergencySeconds >= 0.2,
		string.format(
		"only %.0fms of round-trip grace between the client emergency and the " ..
		"server backstop; 200ms is the floor",
		(C.VictimBackstopSeconds - C.VictimEmergencySeconds) * 1000))

	--==========================================================================
	-- AND IT MUST STILL BE A BAT, NOT A GUARDIAN
	--
	-- The whole point of the retune is a hit that reads as a knockdown. The point
	-- it must not reach is a STUN: HANDOFF measures guardian ragdolls at 3.3 to
	-- 7.6 seconds.
	--
	-- MEASURED AGAINST THE FLOOR, NOT THE EMERGENCY, and the distinction matters.
	-- An earlier version of this assert compared the BACKSTOP against 3.3 and it
	-- was the wrong comparison: the backstop is what happens when the landing
	-- detection fails, and holding failure containment to the length of a normal
	-- guardian ragdoll is what forced the emergency too tight to fit the Comet.
	--
	-- What a player experiences is the floor plus their own fall. That is what
	-- has to stay short of guardian length, and it does: 1.4 against 3.3, with
	-- the longest measured real hit at 2.50.
	--==========================================================================
	assert(C.VictimMinLimpSeconds + C.VictimKnockdownHoldSeconds < 3.3,
		string.format(
		"floor %.2fs + hold %.2fs is guardian length; bats interrupt a raid, " ..
		"they do not end one",
		C.VictimMinLimpSeconds, C.VictimKnockdownHoldSeconds))
end

return WeaponData
