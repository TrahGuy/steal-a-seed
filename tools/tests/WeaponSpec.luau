--!nocheck
-- Steal a Seed :: Marigold's shelf -- prices, tradeoffs, geometry and the save
--
--   python -m http.server 8731        (repo root)
--   local run = loadstring(game:GetService("HttpService"):GetAsync(
--       "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--   print(run("WeaponSpec"))
--
-- Edit mode is enough for everything here: the shelf is a table, the geometry is
-- a pure builder, and the profile migration is a pure function of a raw table.
--
-- What is NOT covered here and is checked in a playtest instead: the purchase
-- transaction, the swing arc against a real character, the knockback, the trap
-- catching anybody, and every part of the panel. Those need two clients or a
-- running server, and a number this file could print about them would be a
-- simulation dressed up as a test.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local ProfileSchema = require(
	ServerScriptService:WaitForChild("SeedGameServer"):WaitForChild("ProfileSchema"))

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s%s", label,
			if detail then "  [" .. tostring(detail) .. "]" else ""))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail then "  <- " .. tostring(detail) else ""))
	end
end

--==============================================================================
-- 1. THE SHELF
--==============================================================================
say("\n-- the shelf --")

check(#WeaponData.Items == 7, "seven items", #WeaponData.Items)

local bats, traps = 0, 0
local ids = {}
local orderOk = true
for i, item in ipairs(WeaponData.Items) do
	if item.Category == "bat" then bats += 1 elseif item.Category == "trap" then traps += 1 end
	if item.Order ~= i then orderOk = false end
	ids[item.Id] = (ids[item.Id] or 0) + 1
end
check(bats == 6 and traps == 1, "six bats and one trap",
	string.format("%d / %d", bats, traps))
check(orderOk, "Order matches shelf position")

local uniqueOk = true
for _, n in pairs(ids) do
	if n ~= 1 then uniqueOk = false end
end
check(uniqueOk, "every id is unique")

local lookupOk = true
for _, item in ipairs(WeaponData.Items) do
	if WeaponData.Get(item.Id) ~= item then lookupOk = false end
end
check(lookupOk and WeaponData.Get("not_a_weapon") == nil
	and WeaponData.Get(42) == nil and WeaponData.Get(nil) == nil,
	"Get resolves real ids and refuses everything else")

--==============================================================================
-- 2. PRICES AGAINST THE PROGRESSION LADDER
--
-- The rule this is enforcing: a weapon must never be the thing standing between
-- a player and the upgrade that earns them the next weapon. So Rootwood is under
-- the cheapest upgrade in the game, and every rung after it rises.
--==============================================================================
say("\n-- prices --")

local cheapestUpgrade = math.min(
	GameConfig.PlotTiers[2].cost, GameConfig.Mill.Tiers[2].cost)
local root = WeaponData.Get("rootwood_bat")
check(root.Price < cheapestUpgrade, "Rootwood is cheaper than the first upgrade",
	string.format("%s < %s", GameConfig.compact(root.Price),
		GameConfig.compact(cheapestUpgrade)))

local rising, ladder = true, ""
local prev = -1
for _, item in ipairs(WeaponData.Items) do
	if item.Category == "bat" then
		ladder ..= string.format(" %s", GameConfig.compact(item.Price))
		if item.Price <= prev then rising = false end
		prev = item.Price
	end
end
check(rising, "each bat costs more than the one before it", ladder)

local trap = WeaponData.Get("bramblejaw_trap")
check(trap.Price > WeaponData.Get("cactus_club").Price
	and trap.Price < WeaponData.Get("sunflower_bonker").Price,
	"the trap sits mid-ladder, reachable", GameConfig.compact(trap.Price))

local top = WeaponData.Get("comet_bat").Price
check(top < GameConfig.Mill.Tiers[#GameConfig.Mill.Tiers].cost,
	"even the top bat is under the top mill", GameConfig.compact(top))

--==============================================================================
-- 3. THE LADDER CLIMBS
--
-- This section used to assert the OPPOSITE -- that no bat beat another on every
-- axis -- because the design was sidegrades. The direction changed: power now
-- rises with price, and what has to be checked is that it rises STRICTLY and
-- that nothing cheaper is quietly stronger.
--==============================================================================
say("\n-- the ladder --")

local batList = {}
for _, item in ipairs(WeaponData.Items) do
	if item.Category == "bat" then
		table.insert(batList, item)
	end
end

local risingPower, risingPrice, powers = true, true, ""
local prevPower, prevPrice = -1, -1
for _, item in ipairs(batList) do
	powers ..= string.format(" %d", item.Power)
	if item.Power <= prevPower then risingPower = false end
	if item.Price <= prevPrice then risingPrice = false end
	prevPower, prevPrice = item.Power, item.Price
end
check(risingPower, "power increases at every step", powers)
check(risingPrice, "and so does price")

--==============================================================================
-- POWER IS THE ONLY THING THAT SETS HORIZONTAL LAUNCH
--
-- The point of the rewrite. Under the old sqrt(R*g/2k) solve a higher Lift
-- LOWERED the launch speed, so a bat could climb the power column and get
-- weaker. Now speed is Power * SpeedPerPower and Lift is added on top, so the
-- speed ordering cannot disagree with the power ordering -- checked rather
-- than asserted, because it is exactly the kind of thing a later tuning pass
-- silently breaks.
--==============================================================================
local risingSpeed, speeds = true, ""
local prevSpeed = -1
for _, item in ipairs(batList) do
	local v = WeaponData.LaunchSpeed(item)
	speeds ..= string.format(" %.0f", v)
	if v <= prevSpeed then risingSpeed = false end
	prevSpeed = v
end
check(risingSpeed, "launch speed rises with power, whatever the lift is", speeds)

local guardian = WeaponData.GuardianLaunchSpeed(1)
local underGuardian, hardest = true, 0
for _, item in ipairs(batList) do
	local v = WeaponData.LaunchSpeed(item)
	hardest = math.max(hardest, v)
	if v >= guardian then underGuardian = false end
end
check(underGuardian,
	"the strongest bat still shoves less than the gentlest guardian",
	string.format("%.1f < %.1f", hardest, guardian))

local swingFits = true
for _, item in ipairs(batList) do
	if item.Cooldown < item.Windup + item.Recovery then swingFits = false end
end
check(swingFits, "no cooldown is shorter than the swing it gates")

--==============================================================================
-- AND THE LAUNCHER STILL LAUNCHES
--
-- Apex is (k*v)^2 / 2g and airtime is 2kv/g off the same launch the server
-- fires. Printed rather than only asserted, because "how long does this take
-- you out of the run for" is the number that decides whether the Sunflower is
-- worth three hundred thousand, and no table read tells you it.
--==============================================================================
local g = workspace.Gravity
local arcs = ""
local bestLift, bestLiftId = -1, ""
for _, item in ipairs(batList) do
	local v = WeaponData.LaunchSpeed(item)
	local apex = (item.Lift * v) ^ 2 / (2 * g)
	local air = 2 * item.Lift * v / g
	arcs ..= string.format("\n     %-18s power %2d  v %5.1f  lift %.2f  apex %5.2f  air %.2fs",
		item.Id, item.Power, v, item.Lift, apex, air)
	if item.Lift > bestLift then
		bestLift, bestLiftId = item.Lift, item.Id
	end
end
--==============================================================================
-- THE LAUNCHER IS THE STEEPEST LAUNCH, NOT THE TALLEST ARC
--
-- This asserted the highest APEX, and that is the wrong invariant now. Apex is
-- (lift * speed)^2 and speed rises with power, so the most expensive bat throws
-- people highest simply by hitting hardest -- which under a ladder that climbs
-- is correct rather than a bug.
--
-- What makes the Sunflower the launcher is that it converts more of its shove
-- upward than anything else does, and that is its LIFT RATIO. It was 1.55 and
-- is 1.05, because measured in Play a 1.55 lift carried people 71 and 77 studs
-- against the Mirewood's 47 and 65 -- a cheaper bat visibly stronger, which is
-- the one thing this ladder may not do.
--==============================================================================
check(bestLiftId == "sunflower_bonker",
	"the Sunflower Bonker launches at the steepest angle in the shop", arcs)

local secondLift = 0
for _, item in ipairs(batList) do
	if item.Id ~= "sunflower_bonker" then
		secondLift = math.max(secondLift, item.Lift)
	end
end
check(bestLift >= secondLift * 1.4,
	"and by a margin nobody could mistake for rounding",
	string.format("%.2f against %.2f", bestLift, secondLift))

--==============================================================================
-- 4. THE CHAIN-FLING GUARD
--
-- The immunity window is the only thing between a Cactus Club and a player who
-- never gets up. It has to outlast BOTH the fastest cooldown and the tumble.
--==============================================================================
say("\n-- chain-fling --")

local C = WeaponData.Combat
local fastest = math.huge
for _, item in ipairs(batList) do
	fastest = math.min(fastest, item.Cooldown)
end
check(C.HitImmunitySeconds > fastest,
	"immunity outlasts the fastest bat's cooldown",
	string.format("%.2fs > %.2fs", C.HitImmunitySeconds, fastest))
check(C.HitImmunitySeconds > C.VictimLimpSeconds,
	"a victim is upright before the next hit can land",
	string.format("%.2fs > %.2fs", C.HitImmunitySeconds, C.VictimLimpSeconds))
check(C.VictimLimpSeconds < 3.3,
	"the tumble is far shorter than a guardian's measured 3.3-7.6s",
	string.format("%.2fs", C.VictimLimpSeconds))

--==============================================================================
-- 5. THE TRAP'S OWN NUMBERS, AS THE BRIEF FIXES THEM
--==============================================================================
say("\n-- the trap --")

local T = WeaponData.Trap
check(T.ArmSeconds == 1.0, "arms in one second", T.ArmSeconds)
check(T.HoldSeconds == 2.0, "holds for two seconds", T.HoldSeconds)
check(T.ImmunitySeconds == 4.0, "four seconds of immunity after release", T.ImmunitySeconds)
check(T.ExpireSeconds == 20, "expires after twenty seconds", T.ExpireSeconds)
check(T.PlaceCooldownSeconds == 15, "fifteen-second placement cooldown",
	T.PlaceCooldownSeconds)
check(T.ExpireSeconds > T.ArmSeconds + T.HoldSeconds,
	"a trap outlives its own arming and hold")
check(T.PlaceCooldownSeconds >= T.HoldSeconds + T.ImmunitySeconds,
	"the cooldown outlasts a full catch, so one owner cannot re-trap a victim",
	string.format("%.0f >= %.0f", T.PlaceCooldownSeconds,
		T.HoldSeconds + T.ImmunitySeconds))

local lines = WeaponData.StatLines(trap)
local said = ""
for _, l in ipairs(lines) do
	said ..= string.format(" %s=%s", l.label, l.value)
end
check(#lines == 3 and string.find(said, "2s", 1, true) ~= nil
	and string.find(said, "15s", 1, true) ~= nil,
	"the card states the two-second hold and the fifteen-second cooldown", said)

--==============================================================================
-- 6. THE GEOMETRY
--
-- Every item builds, every one is an authored silhouette rather than a stack of
-- identical bars, and none of them is a part-count problem.
--==============================================================================
say("\n-- geometry --")

local stash = Instance.new("Folder")
stash.Name = "WeaponSpecStash"
stash.Parent = ServerStorage

local builtAll = true
local report = ""
for _, item in ipairs(WeaponData.Items) do
	local ok, model = pcall(WeaponModel.BuildPreview, item, stash)
	if not ok or not model then
		builtAll = false
		report ..= string.format("\n     %s FAILED %s", item.Id, tostring(model))
	else
		local parts, widths, tilted = 0, {}, 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
				widths[string.format("%.2f", d.Size.X)] = true
				local _, _, _, r00, _, _, _, r11 = d.CFrame:GetComponents()
				if math.abs(r00 - 1) > 1e-4 or math.abs(r11 - 1) > 1e-4 then
					tilted += 1
				end
			end
		end
		local distinct = 0
		for _ in pairs(widths) do
			distinct += 1
		end
		--======================================================================
		-- TWO CHEAP PROXIES FOR "AUTHORED", AND THEY ARE PROXIES
		--
		-- A weapon made of one repeated bar has ONE distinct width; a weapon
		-- that is axis-aligned all the way up has ZERO rotated parts. Neither
		-- test proves a shape is good. Both catch the specific failure the
		-- brief names -- equal-width bars and stacked primitives -- and both
		-- would have caught a lazy first draft.
		--======================================================================
		check(parts >= 10 and parts <= 24,
			string.format("%s is 10-24 parts", item.Id), parts)
		check(distinct >= 5,
			string.format("%s has varied widths", item.Id),
			string.format("%d distinct", distinct))
		check(tilted >= 3,
			string.format("%s is not axis-aligned", item.Id),
			string.format("%d rotated", tilted))
		report ..= string.format("\n     %-18s %2d parts, %2d widths, %2d tilted",
			item.Id, parts, distinct, tilted)
	end
end
check(builtAll, "every item builds", report)

--== THE TOOL ==--
local okTool, tool = pcall(WeaponModel.BuildTool, root)
if okTool then
	local handle = tool:FindFirstChild("Handle")
	check(handle ~= nil and handle:IsA("BasePart"), "a Tool has a BasePart Handle")
	check(tool:GetAttribute(WeaponModel.ItemAttribute) == root.Id,
		"the Tool carries its own id", tostring(tool:GetAttribute(WeaponModel.ItemAttribute)))
	--==========================================================================
	-- THE ONE FACT THAT KEEPS A BAT OUT OF THE STALL, THE SAVE AND THE SOIL
	--
	-- EconomyService.SellHeld, CarryService.heldSnapshot and PlantService.PlaceAt
	-- all gate on `SpeciesId`. A weapon Tool must not have one, or a player
	-- sells their Comet Bat by pressing E at Marigold's board.
	--==========================================================================
	check(tool:GetAttribute("SpeciesId") == nil,
		"a Tool has NO SpeciesId, so the stall and the save walk past it")
	check(tool:GetAttribute(GameConfig.Attributes.CarryingKg) == nil,
		"and no weight, so it cannot be priced")
	tool:Destroy()
else
	check(false, "BuildTool", tostring(tool))
end

--== THE TRAP'S JAWS ==--
local trapModel = WeaponModel.BuildTrapWorld(trap, CFrame.new(), stash)
local base = trapModel.PrimaryPart
local hingeL = base and base:FindFirstChild("JawLHinge")
local hingeR = base and base:FindFirstChild("JawRHinge")
check(hingeL ~= nil and hingeR ~= nil, "the trap has two hinged jaws")
if hingeL and hingeR then
	WeaponModel.SetTrapJaw(trapModel, 0)
	local shutL = hingeL.C0
	WeaponModel.SetTrapJaw(trapModel, 1)
	local openL = hingeL.C0
	WeaponModel.SetTrapJaw(trapModel, 0)
	check((shutL.Position - hingeL.C0.Position).Magnitude < 1e-5
		and math.abs(shutL:ToObjectSpace(openL).LookVector:Dot(Vector3.new(0, 0, 1)) - 1) > 1e-3,
		"opening moves the jaw and shutting puts it exactly back")
end
check(base ~= nil and base.Anchored, "the trap base is anchored")
stash:Destroy()

--==============================================================================
-- 7. THE SAVE
--
-- Weapons and Equipped migrate by being absent, and neither may be trusted from
-- a DataStore. This is the part that quietly loses somebody's Comet Bat.
--==============================================================================
say("\n-- the profile --")

local fresh = ProfileSchema.Default()
check(type(fresh.Weapons) == "table" and next(fresh.Weapons) == nil,
	"a new profile owns nothing")
check(fresh.EquippedBat == "" and fresh.EquippedTrap == "",
	"and has both loadout slots empty")

--== A v1 SAVE THAT PREDATES THE SHOP ==--
local old = ProfileSchema.Sanitise({ Version = 1, Cash = 500, PlotTier = 2 })
check(type(old.Weapons) == "table" and next(old.Weapons) == nil
	and old.EquippedBat == "" and old.EquippedTrap == "",
	"a save written before the shop existed loads clean")
check(old.Cash == 500 and old.PlotTier >= 2,
	"and keeps everything else it had",
	string.format("cash %d, level %d", old.Cash, old.PlotTier))

--== JUNK ==--
local junk = ProfileSchema.Sanitise({
	Weapons = {
		rootwood_bat = true,
		not_a_weapon = true,
		[7] = true,
		comet_bat = "yes",
	},
	Equipped = "cactus_club",
})
check(junk.Weapons.rootwood_bat == true, "a real owned id survives")
check(junk.Weapons.not_a_weapon == nil, "an id that is not on the shelf is dropped")
check(junk.Weapons[7] == nil, "a numeric key is dropped")
check(junk.Weapons.comet_bat == nil, "a non-true value is not ownership")
check(junk.EquippedBat == "",
	"equipping something you do not own comes back empty-handed", junk.EquippedBat)

local armed = ProfileSchema.Sanitise({
	Weapons = { comet_bat = true },
	EquippedBat = "comet_bat",
})
check(armed.EquippedBat == "comet_bat", "and a legitimate one is kept")

--== ROUND TRIP ==--
local twice = ProfileSchema.Sanitise(ProfileSchema.Sanitise(armed))
check(twice.EquippedBat == "comet_bat" and twice.Weapons.comet_bat == true,
	"sanitising twice is the same as once")

--==============================================================================
-- THE ONE-SLOT SAVE, SORTED INTO THE RIGHT DRAWER
--
-- Every profile written before this pass carries a single `Equipped`. Each has
-- to land in the slot its own CATEGORY names, the other slot has to stay empty
-- rather than being guessed at, and -- the part that actually matters --
-- nothing else in the profile may move.
--==============================================================================
say("\n-- the one-slot migration --")

local hadBat = ProfileSchema.Sanitise({
	Weapons = { comet_bat = true, bramblejaw_trap = true },
	Equipped = "comet_bat",
})
check(hadBat.EquippedBat == "comet_bat", "an equipped BAT lands in the bat slot",
	hadBat.EquippedBat)
check(hadBat.EquippedTrap == "", "and the trap slot is left empty, not guessed",
	string.format("%q", hadBat.EquippedTrap))
check(hadBat.Weapons.bramblejaw_trap == true, "the unequipped trap is still owned")

local hadTrap = ProfileSchema.Sanitise({
	Weapons = { comet_bat = true, bramblejaw_trap = true },
	Equipped = "bramblejaw_trap",
})
check(hadTrap.EquippedTrap == "bramblejaw_trap",
	"an equipped TRAP lands in the trap slot", hadTrap.EquippedTrap)
check(hadTrap.EquippedBat == "", "and the bat slot is left empty")

local unowned = ProfileSchema.Sanitise({ Weapons = {}, Equipped = "comet_bat" })
check(unowned.EquippedBat == "" and unowned.EquippedTrap == "",
	"an old save equipping something it does not own migrates to nothing")

--== AND A NEW SLOT WINS OVER THE OLD FIELD ==--
local both = ProfileSchema.Sanitise({
	Weapons = { comet_bat = true, rootwood_bat = true },
	Equipped = "rootwood_bat",
	EquippedBat = "comet_bat",
})
check(both.EquippedBat == "comet_bat",
	"a profile carrying both keeps the new slot", both.EquippedBat)

--== NOTHING UNRELATED MOVES ==--
local SPECIES2 = next(require(Shared:WaitForChild("SeedData")).ById)
local rich = ProfileSchema.Sanitise({
	Version = 2,
	Cash = 123456,
	Speed = 999,
	PlotTier = 4,
	MillTier = 3,
	Almanac = { [SPECIES2] = true },
	Plants = { { SpeciesId = SPECIES2, Tier = 3, PlantedAt = 1000,
		X = 2, Z = 3, Stage = 3, Facing = 45 } },
	Weapons = { rootwood_bat = true },
	Equipped = "rootwood_bat",
})
check(rich.Cash == 123456 and rich.Speed == 999 and rich.PlotTier == 4
	and rich.MillTier == 3 and #rich.Plants == 1
	and rich.Almanac[SPECIES2] == true,
	"cash, speed, plot, mill, plants and almanac all survive the migration",
	string.format("cash %d, level %d, %d plant(s)", rich.Cash, rich.PlotTier,
		#rich.Plants))
check(rich.EquippedBat == "rootwood_bat", "and the bat still came across")

--== PLANTS ARE NOT DISTURBED ==--
local withGarden = ProfileSchema.Sanitise({
	Version = 2,
	Plants = { { SpeciesId = next(require(Shared:WaitForChild("SeedData")).ById),
		Tier = 3, PlantedAt = 1000, X = 2, Z = 3, Stage = 3, Facing = 45 } },
	Weapons = { rootwood_bat = true },
})
check(#withGarden.Plants == 1 and withGarden.Weapons.rootwood_bat == true,
	"a garden and a shelf survive the same load", #withGarden.Plants)

--==============================================================================
-- 8. THE VERBS
--==============================================================================
say("\n-- the wire --")

local W = GameConfig.Weapon
check(type(W.BuyAction) == "string" and type(W.EquipAction) == "string"
	and type(W.ShopAction) == "string" and type(W.DeniedAction) == "string",
	"four verbs are named")
local distinctVerbs = {}
local verbOk = true
for _, v in ipairs({ W.BuyAction, W.EquipAction, W.ShopAction, W.DeniedAction,
	GameConfig.PlotUpgradeAction, GameConfig.Mill.Action }) do
	if distinctVerbs[v] then verbOk = false end
	distinctVerbs[v] = true
end
check(verbOk, "and none of them collides with a verb already on GameEvent")
check(GameConfig.Attributes.Trapped == "Trapped"
	and GameConfig.Tags.Trap == "Trap", "the attribute and the tag are named")

say(string.format("\n%d passed, %d failed", pass, fail))
return table.concat(out, "\n")
