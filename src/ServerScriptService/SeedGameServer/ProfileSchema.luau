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
-- Same reason as SeedData above: so a saved weapon id can be checked against
-- something real, and an id for an item that has been removed from the shelf is
-- dropped rather than carried forever.
local WeaponData = require(SeedGame:WaitForChild("Shared"):WaitForChild("WeaponData"))
local TutorialData = require(SeedGame:WaitForChild("Shared"):WaitForChild("TutorialData"))
-- Treadmill fun's saved marks (2026-10-08): the milestone a save starts at, and
-- the belt ticket window's limit.
local SpeedMilestones = require(SeedGame:WaitForChild("Shared"):WaitForChild("SpeedMilestones"))
local BeltCatch = require(SeedGame:WaitForChild("Shared"):WaitForChild("BeltCatch"))
-- So a saved wheel prize or cosmetic can be checked against the real list.
local WheelData = require(SeedGame:WaitForChild("Shared"):WaitForChild("WheelData"))
-- The hotbar's shortcuts and the Bag's hearts are cleaned against what the
-- profile owns, by the same grammar the server and the client edit with.
local HotbarSlots = require(SeedGame:WaitForChild("Shared"):WaitForChild("HotbarSlots"))
local SAVE = GameConfig.Save

local ProfileSchema = {}

export type Profile = {
	Tutorial: TutorialData.Progress,
	--==========================================================================
	-- RECEIPTS ALREADY HONOURED
	--
	-- Roblox retries ProcessReceipt until it is told PurchaseGranted, including
	-- across a server restart and a rejoin. Without a record that survives the
	-- save, a retry after a crash grants a second time -- and this is the one
	-- table in the profile where getting it wrong costs somebody real money.
	--
	-- Bounded, newest last. A player who buys more than the cap between one save
	-- and the next does not exist; a list that grows forever does.
	--==========================================================================
	Receipts: { string },
	--==========================================================================
	-- SAVED INSTANT HATCHES (2026-09-30)
	--
	-- Instant Hatch purchases kept for later: a receipt that found the saved
	-- record full and its pod's wait already over (PlantService.InstantHatch).
	-- Added in the same step as that receipt's entry in Receipts above, so a
	-- save holds both or neither; spent only by an instant hatch that has
	-- succeeded. Kept by a progress reset, like a bought spin. An old save has
	-- none and reads 0.
	--==========================================================================
	InstantCredits: number,
	--==========================================================================
	-- THE HATCH BONUS AND THE LIKE REMINDER (2026-10-01; GameConfig.HatchBonus)
	--
	-- HatchBonusClaimed: the one free wheel spin a successful hatch earns has
	-- been given. Set in the same step as WheelEarned's +1 and LikeReminder's
	-- "pending" (WheelService.GrantHatchBonus), so a save holds the marker
	-- with its spin or neither. LikeReminder: "" (not earned yet), "pending"
	-- (earned, not yet shown) or "shown". Both are kept by a progress reset,
	-- so the bonus cannot be claimed again. An old save has neither: false, "".
	--==========================================================================
	HatchBonusClaimed: boolean,
	LikeReminder: string,
	-- BatHintShown: the one-time "Buy a bat at Marigold's stall to fight back!"
	-- (BatHintService, 2026-10-08) has been shown. An old save has none: false.
	BatHintShown: boolean,
	--==========================================================================
	-- THE FIRST MINUTE (2026-10-08; FirstMinute)
	--
	-- StarterAt: os.time() the game planted this profile's starter pod -- the
	-- PlantedAt of that row, which is how PlantService knows it while it grows
	-- -- or 0 if it never did. Set once (PlayerDataService.RecordStarter), in
	-- the same step the row goes into the garden, and KEPT by a progress reset:
	-- one starter per profile, ever. Non-zero also tells TutorialData.Sanitise
	-- that this profile's possessions prove no tutorial step.
	-- FirstCatchSpecies / FirstCatchTier: the pod taken while `steal` was not
	-- done (CarryService), waiting for the hatch whose reveal says "BIG! Your
	-- first catch." -- cleared by that hatch. "" and 0 when nothing is waiting.
	-- Old saves have none: 0, "", 0.
	--==========================================================================
	StarterAt: number,
	FirstCatchSpecies: string,
	FirstCatchTier: number,
	--==========================================================================
	-- TREADMILL FUN (2026-10-08; SpeedMilestones, BeltCatch)
	--
	-- SpeedMilestone: the highest Speed milestone this profile has PASSED (a
	-- Speed value, 0 for none). Every milestone at or below it is spent: paid
	-- once, ever, or passed with no prize (admin and debug Speed). A save from
	-- before this shipped has no key and starts at the highest milestone under
	-- its Speed -- no back pay.
	-- MilestoneSpinsOwed: milestone tickets won while the earned spin balance
	-- was full, paid as soon as it has room (0..5).
	-- BeltTicketAt / BeltTicketCount: the belt's golden-ticket window -- its own
	-- rolling 24 h, opened by the first ticket caught (WheelData.Daily's
	-- pattern, never the obby's allowance) -- and how many it has given (0..1).
	-- All four are KEPT by a progress reset. New saves: 0, 0, 0, 0.
	--==========================================================================
	SpeedMilestone: number,
	MilestoneSpinsOwed: number,
	BeltTicketAt: number,
	BeltTicketCount: number,
	-- THE COMMUNITY CHEST'S SPINS WERE GIVEN (2026-10-01; GameConfig.Community).
	-- Set in the same step as WheelEarned's +Spins and saved with it
	-- (WheelService.GrantCommunity); kept by a progress reset. Old saves: false.
	CommunityClaimed: boolean,
	--==========================================================================
	-- INVITE A FRIEND (2026-10-06; InviteService, GameConfig.InviteRewards)
	--
	-- InviteIds: the UserIds of friends who joined the game through this
	-- player's invites -- each once, forever (the newest MaxRemembered). Its
	-- length IS the count every screen shows.
	-- InviteGranted: how many of the track's forms have been given (0 .. the
	-- track's length), raised in the SAME step as the plant's Held row is
	-- written (CarryService.GiveHatched with onRecord), so a save holds both
	-- or neither and a rejoin never gives a form twice.
	-- InviteSeen: the INVITE panel was opened since the last form was given --
	-- false shows INVITE's "!" (never opened at all included).
	-- InviteOwned (2026-10-08): every invite plant this player has ever been
	-- GIVEN, by an invite milestone or by the wheel, so neither gives one twice.
	-- Old saves: the first InviteGranted forms of the track.
	-- InviteReturnIds (2026-10-08): friends who came back through this
	-- player's invite having played before -- each paid one free spin, once,
	-- forever; never counted toward the plants. Old saves: {}.
	-- Kept by a progress reset: a reset must not hand the forms out again.
	-- Old saves have none: {}, 0, false.
	--==========================================================================
	InviteIds: { number },
	InviteGranted: number,
	InviteSeen: boolean,
	InviteOwned: { string },
	InviteReturnIds: { number },
	--==========================================================================
	-- SPROUT DASH (2026-10-08; SproutDashService, GameConfig.SproutDash): the
	-- minigame's own +25% training boost (os.time() it runs out), the boost
	-- seconds earned in the last hour (its cap; trimmed on every grant) and
	-- today's best distance. Old saves: 0, {}, 0, 0.
	--==========================================================================
	SproutBoostEndsAt: number,
	SproutEarned: { { At: number, Seconds: number } },
	SproutBestDay: number,
	SproutBest: number,
	--==========================================================================
	-- REBIRTH (2026-10-08; RebirthService, GameConfig.Rebirth): how many times
	-- this save has been reborn, and when it last was (os.time(); the cooldown
	-- reads it). Kept through an admin progress reset. Old saves: 0, 0.
	--==========================================================================
	Rebirths: number,
	RebirthAt: number,
	--==========================================================================
	-- GLOBAL MINI-EVENT TICKETS (2026-10-03; MiniEventService, GameConfig.MiniEvent)
	--
	-- Tickets collected per GLOBAL event, by its id: Count of them (never past
	-- the event's per-player cap) and At, when the last one was taken. Written
	-- in the SAME step as WheelEarned's +1 (WheelService.GrantEventSpin), so a
	-- save holds each spin with its claim or neither -- and a player who
	-- leaves, dies, rejoins or moves to another server meets the same count.
	-- Bounded: the newest Tickets.ClaimsKept events only, oldest dropped. Kept
	-- by a progress reset, so a reset cannot reopen a running event's cap.
	-- Old saves have none.
	--==========================================================================
	EventClaims: { { Id: string, Count: number, At: number } },
	--==========================================================================
	-- POD RUSH (2026-10-09; PodRushService, GameConfig.PodRush)
	--
	-- The latest rush's numbers, under its global event id: the pods counted,
	-- the levels paid (0..3; each pays once per rush) and the highest biome
	-- Order banked from (the GOLD pod's biome). A rejoin -- on any server --
	-- meets the same row; a new rush id starts it again. PodOwed is the biome
	-- ids of GOLD Titan pods not yet given (the Bag was full), oldest first and
	-- comma-joined, at most PodRush.MaxOwed, "" for none; it outlives the rush
	-- they were won in. Kept by a progress reset, so a reset cannot repay a
	-- level. Old saves: an empty row.
	--==========================================================================
	PodRush: { Id: string, Count: number, Paid: number, Top: number, PodOwed: string },
	-- DISCO DANCING (2026-10-03): the third stored setting -- dance at the hub
	-- while a disco runs. ON unless the player switched it off; an old save
	-- with no key reads ON. Kept by a progress reset, like Walk Mode.
	DiscoDance: boolean,
	Version: number,
	Cash: number,
	Speed: number,
	PlotTier: number,
	-- Which mill stands on their plot. Exactly the same idea as PlotTier and
	-- kept beside it on purpose: one number, owned by the server, that decides
	-- what gets built on YOUR ground.
	MillTier: number,
	--==========================================================================
	-- WHAT IS LEFT OF OVERCLOCK (history since 2026-10-06)
	--
	-- A tier-10 mill used to buy overclock levels, saved here. Tiers 11-14
	-- replaced them: the field stays so a save from then loads exactly, and
	-- convertOverclock turns its levels into a tier on the first load after.
	-- Nothing sets it above 0 any more.
	--==========================================================================
	MillOverclock: number,
	--==========================================================================
	-- THE HIGHEST BIOME SPEED MILESTONE THIS PLAYER HAS EARNED
	--
	-- A HIGH-WATER MARK, not access permission. Biome entrances are open; this
	-- records the Speed milestones reached. A future rebirth may set live Speed
	-- back to zero and must not confiscate milestones already earned.
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
	--
	-- EACH ROW IS ONE ITEM, BY NAME (2026-10-03). `Item` is a string id unique on
	-- this profile and never reused, so two identical Nubkins are told apart: the
	-- Tool carries it (GameConfig.Attributes.ItemId), a hotbar shortcut remembers
	-- it across a respawn, and a sale takes exactly that row off. Minted from
	-- NextItem below; a row saved without one (any save from before this) is
	-- given one on load, and nothing is dropped for lacking it.
	--
	-- A POD ROW CARRIES ITS DEADLINE (2026-10-09, pods hatch in the Bag):
	-- `HatchAt`, the os.time() it may be hatched, stamped when it is banked or
	-- given. A pod row saved before then is given now + its grow time on load.
	-- Plant rows have none.
	--==========================================================================
	Held: { any },
	-- The next Item id to hand out. Only ever raised -- a progress reset keeps
	-- it too, so an old shortcut can never attach to a new item.
	NextItem: number,
	--==========================================================================
	-- THE HOTBAR AND THE HEARTS (2026-10-03, the owner's compact Bag + free
	-- hotbar; HotbarSlots)
	--
	-- Hotbar: exactly ten strings, slot 1 first, each a ref ("i:<Item>",
	-- "w:<weapon>", "ticket"), a faint "+bat" / "+trap" / "+ticket" waiting for
	-- the first of its kind, or "" for empty. Shortcuts, never copies: an item on
	-- the bar is still in Held. Favourites: a set of the same refs.
	--
	-- Both migrate by being ABSENT: an old save seeds the bar from what it has
	-- out (1 bat, 2 trap, 3 tickets) and starts with no hearts; a new player's
	-- bar is the three faint slots. Every load cleans both against what is owned.
	--==========================================================================
	Hotbar: { string },
	Favourites: { [string]: boolean },
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
	--==========================================================================
	-- WHICH BIOME HARVESTS HAVE BEEN PAID
	--
	-- A set of biome ids, written by AlmanacService the moment it pays a biome's
	-- one-time bonus for growing every species on its shelf. A set for the
	-- Almanac's reasons: one question ("was this one paid"), and a set cannot
	-- hold the same claim twice.
	--
	-- Migrates by being ABSENT: a save from before the Biome Harvest reads nil
	-- and lands on an empty set, which is exactly what that player has claimed.
	--==========================================================================
	Mastery: { [string]: boolean },
	--==========================================================================
	-- WHAT THEY HAVE BOUGHT OFF MARIGOLD, AND WHAT THEY HAVE OUT
	--
	-- A SET, like the Almanac, and for the same reason: the only question ever
	-- asked of it is "do they own this one", a list would make that a scan on
	-- every card repaint, and a set cannot contain the same purchase twice --
	-- which is one of the two things standing between a double-click and a
	-- double charge.
	--
	-- These are PERMANENT UNLOCKS. There is no count, no durability and no
	-- restock; a weapon bought in 2026 is a weapon owned in 2036.
	--
	--==========================================================================
	-- TWO LOADOUT SLOTS, ONE PER CATEGORY
	--
	-- This was a single `Equipped` field, because one shop tool was out at a
	-- time. A player may now have a bat AND a trap ready at once, so the slot
	-- is per CATEGORY -- which is also what makes "switching to the trap must
	-- not clear the bat" true by construction rather than by remembering.
	--
	-- Each is one id or the empty string. Saved rather than derived from the
	-- Backpack, so a player rejoins with what they logged out holding, and both
	-- are sanitised against Weapons AND against the item's own category below:
	-- a profile naming a bat in the trap slot comes back with an empty trap
	-- slot rather than a bat that cannot be placed.
	--
	-- Everything here migrates by being ABSENT. A save written before Marigold
	-- sold anything reads nil and lands on an empty set with both slots empty,
	-- which is exactly the state such a player is in. No version bump.
	--==========================================================================
	Weapons: { [string]: boolean },
	EquippedBat: string,
	EquippedTrap: string,
	--==========================================================================
	-- WALK MODE, WHICH IS A PREFERENCE AND THEREFORE SAVED
	--
	-- A player who asked to walk asked to walk, and having to ask again on every
	-- rejoin would make the switch a toy. It is the first stored SETTING in this
	-- profile -- sound levels live on the client, quality lives on an attribute --
	-- so it is added the way every other field here was: default false, sanitised
	-- to a boolean, and absent in an old save means OFF.
	--==========================================================================
	WalkMode: boolean,
	-- MENU SIZE, the second stored setting, added the same way (2026-09-26): a
	-- GameConfig.MenuSize option id, default "normal", and anything that is not
	-- an option -- an old save with no key included -- reads as "normal".
	MenuSize: string,
	CreatedAt: number,
	LastSeen: number,
	-- An unclaimed offline claim (see OfflineEarnings): cash before the x2
	-- pass, seconds credited toward SeedData.Offline.MaxCreditSeconds, and
	-- seconds actually away. All zero once claimed.
	OfflineCash: number,
	OfflineSeconds: number,
	OfflineAway: number,
	--==========================================================================
	-- THE BONUS CHEST (2026-09-27): when the next claim opens, and the one
	-- boost the last claim left running. Absolute os.time() seconds, so both
	-- keep elapsing while the player is away and a rejoin can neither reset
	-- the cooldown nor extend the boost. ChestBoost is a GameConfig.BonusChest
	-- reward Id, or "" for none. All three are written together, by one claim,
	-- and saved before the claim is confirmed (BonusChestService). An old save
	-- has no keys and reads 0 / "" / 0: ready once the guide is done, nothing
	-- running.
	--==========================================================================
	ChestNextAt: number,
	ChestBoost: string,
	ChestBoostEndsAt: number,
	--==========================================================================
	-- THE SACRIFICE PEDESTAL (2026-09-28; SacrificeService, numbers in
	-- SeedData.Sacrifice): when the pedestal is ready again, and when the boost
	-- the last sacrifice bought runs out. Absolute os.time() seconds, like the
	-- chest's, so both keep elapsing while the player is away and a rejoin can
	-- neither reset the cooldown nor extend the boost. Written together by one
	-- sacrifice, in the same resumption that takes the pod's row off Held --
	-- so they reach the save with the pod's removal, or not at all. An old save
	-- has neither key and reads 0 / 0: ready, nothing running.
	--==========================================================================
	SacrificeNextAt: number,
	SacrificeEndsAt: number,
	--==========================================================================
	-- THE OBBY REWARD WHEEL (2026-09-27; WheelService, numbers in WheelData)
	--
	--   WheelEarned / WheelBought  unused spins, by where they came from, kept
	--                              apart so a bought spin is always known as one
	--   WheelDayAt / WheelDayCount the open earning window: the os.time() it
	--                              opened (the first spin-earning completion) and
	--                              the spins it has earned; 0 / 0 is none open
	--   WheelRuns                  the last few obby completion ids credited, so
	--                              no completion is ever credited twice
	--   WheelPending               prizes rolled and recorded but not delivered:
	--                              SAVED before a spin is confirmed, delivered
	--                              right after, and delivered again on the next
	--                              join if a crash came between (or once there is
	--                              bag space, for a pod)
	--   WheelSeq                   a counter for spin ids
	--   Cosmetics / EquippedTrail  owned cosmetic ids and the trail worn ("")
	--
	-- All migrate by being absent: an old save has no spins, no window, nothing
	-- pending and no cosmetics -- exactly its state.
	--==========================================================================
	WheelEarned: number,
	WheelBought: number,
	WheelDayAt: number,
	WheelDayCount: number,
	WheelRuns: { string },
	WheelPending: { WheelPrize },
	WheelSeq: number,
	Cosmetics: { [string]: boolean },
	EquippedTrail: string,
}

-- One prize the wheel has rolled: which spin (Id), what was rolled and what is
-- paid (Rolled and Prize differ only when an owned trail pays its swap), the
-- species a pod prize hatches into ("" otherwise), which balance paid for it,
-- and when.
export type WheelPrize = {
	Id: string,
	Rolled: string,
	Prize: string,
	Species: string,
	Source: string,
	At: number,
	-- A scaled cash or Speed prize's amount as published and rolled (2026-10-08);
	-- nil on rows from before, which pay the prize's floor.
	Amount: number?,
}

-- Year 2100, as a sanity ceiling on stored timestamps. A clock-skewed or
-- corrupt LastSeen far in the future would make offline income pay out
-- centuries the moment that feature exists.
local MAX_TIME = 4102444800

function ProfileSchema.Default(): Profile
	local now = os.time()
	return {
		Tutorial = TutorialData.Default(),
		Receipts = {},
		InstantCredits = 0,
		HatchBonusClaimed = false,
		BatHintShown = false,
		LikeReminder = "",
		StarterAt = 0,
		FirstCatchSpecies = "",
		FirstCatchTier = 0,
		SpeedMilestone = 0,
		MilestoneSpinsOwed = 0,
		BeltTicketAt = 0,
		BeltTicketCount = 0,
		CommunityClaimed = false,
		InviteIds = {},
		InviteGranted = 0,
		InviteSeen = false,
		InviteOwned = {},
		InviteReturnIds = {},
		SproutBoostEndsAt = 0,
		SproutEarned = {},
		SproutBestDay = 0,
		SproutBest = 0,
		Rebirths = 0,
		RebirthAt = 0,
		EventClaims = {},
		PodRush = { Id = "", Count = 0, Paid = 0, Top = 0, PodOwed = "" },
		DiscoDance = true,
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
		NextItem = 1,
		Hotbar = HotbarSlots.seed(nil),
		Favourites = {},
		Almanac = {},
		Mastery = {},
		Weapons = {},
		EquippedBat = "",
		EquippedTrap = "",
		WalkMode = false,
		MenuSize = GameConfig.MenuSize.Default,
		CreatedAt = now,
		LastSeen = now,
		OfflineCash = 0,
		OfflineSeconds = 0,
		OfflineAway = 0,
		ChestNextAt = 0,
		ChestBoost = "",
		ChestBoostEndsAt = 0,
		SacrificeNextAt = 0,
		SacrificeEndsAt = 0,
		WheelEarned = 0,
		WheelBought = 0,
		WheelDayAt = 0,
		WheelDayCount = 0,
		WheelRuns = {},
		WheelPending = {},
		WheelSeq = 0,
		Cosmetics = {},
		EquippedTrail = "",
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

-- The ten levels Overclock ever had (see convertOverclock).
local OVERCLOCK_LEVELS = 10

-- The top of the plot ladder the v1 -> v2 migration was written against
-- (Levels 1-5). Levels 6-7 (2026-10-07) are bought, never migrated into.
local MIGRATION_TOP_LEVEL = 5

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
	--
	-- The overclock is kept as saved, within the ten levels there ever were;
	-- what it was worth becomes a tier in convertOverclock, which the load runs
	-- after this (2026-10-06).
	--==========================================================================
	p.MillOverclock = math.floor(number(raw.MillOverclock, 0, 0, OVERCLOCK_LEVELS))
	--==========================================================================
	-- THE MILL'S OLD TRAINING CHARGE IS NOT CARRIED FORWARD (2026-10-05)
	--
	-- Records saved before the Training Rush was removed hold TrainingCharge and
	-- TrainingChargeAt. Nothing reads them any more, and like any field this
	-- schema no longer knows they are simply not copied: an old record loads
	-- whole -- Speed, mill tier and overclock untouched -- and its next save
	-- leaves them behind. They can never pay anything again.
	--==========================================================================
	p.HighestBiomeOrder = math.floor(
		number(raw.HighestBiomeOrder, 1, 1, #BiomeData.Biomes))
	p.CreatedAt = math.floor(number(raw.CreatedAt, p.CreatedAt, 0, MAX_TIME))
	p.LastSeen = math.floor(number(raw.LastSeen, p.LastSeen, 0, MAX_TIME))
	--==========================================================================
	-- THE UNCLAIMED OFFLINE CLAIM MIGRATES BY BEING ABSENT
	--
	-- A save from before offline earnings has none of these and reads 0: no
	-- claim waiting, which is exactly its state. Clamped like every other
	-- number here, so a corrupt row can neither mint more than the cash cap nor
	-- claim to have banked more than a night of credit.
	--==========================================================================
	p.OfflineCash = math.floor(number(raw.OfflineCash, 0, 0, SAVE.MaxCash))
	p.OfflineSeconds = math.floor(number(raw.OfflineSeconds, 0, 0, SeedData.Offline.MaxCreditSeconds))
	p.OfflineAway = math.floor(number(raw.OfflineAway, 0, 0, MAX_TIME))
	--==========================================================================
	-- THE BONUS CHEST MIGRATES BY BEING ABSENT, AND IS BOUNDED BY NOW
	--
	-- An old save reads 0 / "" / 0 -- ready, nothing running. A value no claim
	-- could have written is pulled back to the most one could: never more than
	-- one cooldown or one boost from this moment, so a corrupt or clock-skewed
	-- row can neither lock the chest for a century nor run a boost for one. An
	-- unknown reward id reads as no boost at all.
	--==========================================================================
	local chest = GameConfig.BonusChest
	local now = os.time()
	p.ChestNextAt = math.floor(number(raw.ChestNextAt, 0, 0, now + chest.CooldownSeconds))
	if GameConfig.bonusChestReward(raw.ChestBoost) ~= nil then
		p.ChestBoost = raw.ChestBoost
		p.ChestBoostEndsAt = math.floor(number(raw.ChestBoostEndsAt, 0, 0, now + chest.BoostSeconds))
	end

	--==========================================================================
	-- THE SACRIFICE PEDESTAL, BY THE SAME TWO RULES
	--
	-- An old save has neither key and reads 0 / 0: ready, nothing running. And
	-- neither time may lie further ahead than one sacrifice made this second
	-- could have put it -- one cooldown, one boost -- so a clock-skewed row
	-- cannot lock the pedestal or pay its boost for longer than the game ever
	-- would. A time in the past is kept as it is: it only says "over".
	--==========================================================================
	local sacrifice = SeedData.Sacrifice
	p.SacrificeNextAt = math.floor(number(raw.SacrificeNextAt, 0, 0, now + sacrifice.CooldownSeconds))
	p.SacrificeEndsAt = math.floor(number(raw.SacrificeEndsAt, 0, 0, now + sacrifice.DurationSeconds))

	--==========================================================================
	-- THE WHEEL, BOUNDED BY WHAT WheelService COULD HAVE WRITTEN
	--
	-- Balances are whole and capped far above any real player; a window cannot
	-- have opened in the future (so no skewed clock can stretch one), and its
	-- count is within the daily limit. A pending prize is kept only if every
	-- part of it names something real -- a prize, and for a pod a species from
	-- that prize's own pool -- because it is paid out on the next join, and a
	-- mangled row must not pay anything it could not have won.
	--==========================================================================
	p.WheelEarned = math.floor(number(raw.WheelEarned, 0, 0, WheelData.MaxEarnedHeld))
	p.WheelBought = math.floor(number(raw.WheelBought, 0, 0, WheelData.MaxBoughtHeld))
	p.WheelDayAt = math.floor(number(raw.WheelDayAt, 0, 0, now))
	p.WheelDayCount = if p.WheelDayAt > 0
		then math.floor(number(raw.WheelDayCount, 0, 0, WheelData.Daily.Limit))
		else 0
	p.WheelSeq = math.floor(number(raw.WheelSeq, 0, 0, 1e12))
	if type(raw.WheelRuns) == "table" then
		for _, id in ipairs(raw.WheelRuns) do
			if type(id) == "string" and #id > 0 and #id <= 64 and #p.WheelRuns < WheelData.RememberRuns then
				table.insert(p.WheelRuns, id)
			end
		end
	end
	if type(raw.WheelPending) == "table" then
		for _, row in ipairs(raw.WheelPending) do
			if #p.WheelPending >= WheelData.MaxPending then
				break
			end
			if type(row) == "table" and type(row.Id) == "string" and #row.Id > 0 and #row.Id <= 64 then
				local prize = WheelData.ById[if type(row.Prize) == "string" then row.Prize else ""]
				local rolled = WheelData.ById[if type(row.Rolled) == "string" then row.Rolled else ""]
				local source = row.Source
				local species = if type(row.Species) == "string" then row.Species else ""
				local speciesOk = true
				if prize and prize.kind == "pod" then
					speciesOk = false
					for _, id in ipairs(WheelData.Pools[prize.pool or ""] or {}) do
						if id == species then
							speciesOk = true
						end
					end
				elseif prize and prize.kind == "invite" then
					-- An invite plant: one of the track's forms, and nothing else.
					speciesOk = table.find(GameConfig.InviteRewards.Forms, species) ~= nil
				else
					species = ""
				end
				-- What was paid is what was rolled, or the trail's or the invite
				-- prize's own replacement.
				local consistent = prize ~= nil and rolled ~= nil
					and (prize == rolled or ((rolled.kind == "trail" or rolled.kind == "invite") and rolled.swap == prize.id))
				-- A scaled amount: whole, never under the prize's floor, never over
				-- what a balance can hold. Absent on older rows (the floor is paid).
				local amount: number? = nil
				if prize and prize.scale and type(row.Amount) == "number" and row.Amount == row.Amount then
					local cap = if prize.kind == "speed" then SAVE.MaxSpeedScore else SAVE.MaxCash
					amount = math.floor(math.clamp(row.Amount, prize.amount or 0, cap))
				end
				if consistent and prize and rolled and speciesOk and (source == "earned" or source == "bought") then
					table.insert(p.WheelPending, {
						Id = row.Id,
						Rolled = rolled.id,
						Prize = prize.id,
						Species = species,
						Source = source,
						At = math.floor(number(row.At, now, 0, MAX_TIME)),
						Amount = amount,
					})
				end
			end
		end
	end
	if type(raw.Cosmetics) == "table" and raw.Cosmetics[WheelData.Trail.Id] == true then
		p.Cosmetics[WheelData.Trail.Id] = true
	end
	p.EquippedTrail = if raw.EquippedTrail == WheelData.Trail.Id and p.Cosmetics[WheelData.Trail.Id]
		then WheelData.Trail.Id
		else ""

	if type(raw.Plants) == "table" then
		for _, row in ipairs(raw.Plants) do
			if type(row) == "table" and type(row.SpeciesId) == "string" and SeedData.Get(row.SpeciesId) then
				local tier = number(row.Tier, 0, 1, SeedData.TierCount)
				local plantedAt = number(row.PlantedAt, 0, 0, MAX_TIME)
				--======================================================
				-- THE POD'S OWN HATCH DEADLINE, OR 0 FOR "NOT WRITTEN YET"
				--
				-- Added 2026-09-17 with the approved hatch ladder. A row saved
				-- before it has no HatchAt, and 0 is what tells PlantService to
				-- keep the old five-minute-curve promise for that pod instead of
				-- applying today's much longer ladder to it. Forward migration
				-- only: nothing is rewritten here, and a row that has the field
				-- keeps its exact value.
				--======================================================
				local hatchAt = number(row.HatchAt, 0, 0, MAX_TIME)
				local x = number(row.X, 0, -1000, 1000)
				local z = number(row.Z, 0, -1000, 1000)
				local facing = number(row.Facing, 0, -360, 360)
				local stage = 1
				if type(row.Stage) == "number" then
					stage = number(row.Stage, 1, 1, 3)
				elseif type(row.Stage) == "string" then
					if row.Stage == "grown" then
						stage = 3
					else
						stage = 1
					end
				end
				if tier >= 1 then
					-- A GROWN creature's item id (2026-10-04, MY PLANTS): the same
					-- id it had in the Bag, kept while it stands in the ground, so
					-- its shortcut and its heart are its own when it comes back.
					-- Checked against the Bag's ids below, once those are read.
					local item = row.Item
					if math.floor(stage) ~= 3 or type(item) ~= "string" or item == "" or #item > 24 then
						item = nil
					end
					table.insert(p.Plants, {
						SpeciesId = row.SpeciesId,
						PlantedAt = math.floor(plantedAt),
						HatchAt = math.floor(hatchAt),
						Tier = math.floor(tier),
						X = x,
						Z = z,
						Stage = math.floor(stage),
						Facing = facing,
						Item = item,
					})
				end
			end
		end
	end

	--==========================================================================
	-- HELD IS REBUILT ROW BY ROW, NOT TRUSTED WHOLESALE
	--
	-- Same discipline as the Almanac below and for the same reason: a DataStore
	-- round trip can hand back a species that has since been deleted, a weight
	-- from before the roll existed, or a table with a hole in it. Every row has
	-- to name a real species and carry a sane weight or it does not come back.
	--
	-- NOT CUT TO THE LIMIT (2026-09-29). This used to stop reading at
	-- SAVE.MaxHeld rows and say nothing about the rest, so a record that held
	-- more lost plants at the door. The owner's rule: "Do not silently delete
	-- or truncate an existing profile that already exceeds the cap." The limit
	-- is asked when something is ADDED (CarryService.HeldRoom), and no writer
	-- adds a row past it; a record that already holds more comes back whole,
	-- and is full until its owner has sold or planted it back under. What it
	-- costs to rebuild is bounded by what was saved.
	--==========================================================================
	--==========================================================================
	-- EVERY ROW LEAVES HERE WITH ITS OWN ITEM ID (2026-10-03)
	--
	-- A saved id is kept when it is a short string no earlier row took; a row
	-- without one -- every save from before item ids, or one written by an older
	-- server, which does not know the field -- or with a duplicate is given the
	-- next number. NextItem ends past every number in use, so nothing minted later
	-- can collide. Ids are labels, not counts: nothing is ever dropped for one.
	--==========================================================================
	p.NextItem = math.floor(number(raw.NextItem, 1, 1, 1e12))
	if type(raw.Held) == "table" then
		local taken: { [string]: boolean } = {}
		for _, row in ipairs(raw.Held) do
			if type(row) == "table" and type(row.Id) == "string"
				and SeedData.Get(row.Id) then
				local tier = number(row.Tier, 0, 1, SeedData.TierCount)
				if tier >= 1 then
					local item = row.Item
					if type(item) ~= "string" or item == "" or #item > 24 or taken[item] then
						item = nil
					end
					if item then
						taken[item] = true
						local n = tonumber(item)
						if n and n == n and n >= p.NextItem and n < 1e12 then
							p.NextItem = math.floor(n) + 1
						end
					end
					--==================================================
					-- A BAG POD'S DEADLINE (2026-10-09, pods hatch in the Bag)
					--
					-- os.time() it may be hatched, stamped when it was banked
					-- or given. A pod saved before then has none, and its
					-- wait starts at this load: now plus the ladder's own
					-- time for it (SeedData.GrowSecondsFor), as the owner
					-- approved. A saved one is kept, never further off than
					-- a whole wait from now.
					--==================================================
					local hatched = row.Hatched == true
					local hatchAt: number? = nil
					if not hatched then
						local grow = SeedData.GrowSecondsFor(SeedData.Get(row.Id), math.floor(tier))
						local saved = number(row.HatchAt, 0, 0, now + grow)
						hatchAt = math.floor(if saved > 0 then saved else now + grow)
					end
					table.insert(p.Held, {
						Id = row.Id,
						Tier = math.floor(tier),
						Hatched = hatched,
						Item = item,
						HatchAt = hatchAt,
					})
				end
			end
		end
		for _, row in ipairs(p.Held) do
			if row.Item == nil then
				local item = tostring(p.NextItem)
				while taken[item] do
					p.NextItem += 1
					item = tostring(p.NextItem)
				end
				row.Item = item
				taken[item] = true
				p.NextItem += 1
			end
		end
	end
	--==========================================================================
	-- A PLANTED ID IS NEVER ALSO A BAG ID (2026-10-04, MY PLANTS)
	--
	-- One item is in the Bag or in the ground, never both: a planted row whose id
	-- a Bag row (or an earlier planted row) already has loses the id -- the plant
	-- itself is kept, only its shortcut and heart are not its to claim. NextItem
	-- ends past every planted id too, so nothing minted later collides.
	--==========================================================================
	do
		local used: { [string]: boolean } = {}
		for _, row in ipairs(p.Held) do
			if type(row.Item) == "string" then
				used[row.Item] = true
			end
		end
		for _, row in ipairs(p.Plants) do
			local item = row.Item
			if type(item) == "string" then
				if used[item] then
					row.Item = nil
				else
					used[item] = true
					local n = tonumber(item)
					if n and n == n and n >= p.NextItem and n < 1e12 then
						p.NextItem = math.floor(n) + 1
					end
				end
			end
		end
	end

	-- Copied key by key rather than assigned wholesale, which is what makes the
	-- "unknown ids dropped" promise true. A DataStore round trip can hand back
	-- numeric keys, string values, or an id from a species that has since been
	-- deleted; none of those reach the Index.
	-- The Biome Harvest set: only `true` against a biome that still exists.
	if type(raw.Mastery) == "table" then
		for id, paid in pairs(raw.Mastery) do
			if paid == true and type(id) == "string" and BiomeData.ById[id] then
				p.Mastery[id] = true
			end
		end
	end

	if type(raw.Almanac) == "table" then
		for id, seen in pairs(raw.Almanac) do
			if seen == true and type(id) == "string" and SeedData.Get(id) then
				p.Almanac[id] = true
			end
		end
	end

	--==========================================================================
	-- COPIED KEY BY KEY, NOT ASSIGNED
	--
	-- Same construction as the Almanac immediately above: a DataStore round trip
	-- can hand back numeric keys, string values, or the id of an item that has
	-- since been taken off the shelf, and none of those may reach the shop.
	--==========================================================================
	if type(raw.Weapons) == "table" then
		for id, owned in pairs(raw.Weapons) do
			if owned == true and type(id) == "string" and WeaponData.Get(id) then
				p.Weapons[id] = true
			end
		end
	end

	--==========================================================================
	-- A SLOT MUST BE OWNED **AND** OF THE RIGHT CATEGORY
	--
	-- Ownership is the interesting check and it is not hypothetical: a refund,
	-- a shelf change, or a partial write that landed the equip and lost the
	-- purchase would each produce a slot naming something unowned. Category is
	-- the new one -- a bat in the trap slot would be a tool that cannot do the
	-- only thing that slot's button offers.
	--
	-- Failing either check empties that slot and nothing else. The worst
	-- outcome is a player who presses EQUIP again.
	--==========================================================================
	local function slot(value: any, want: string): string
		if type(value) ~= "string" or value == "" or not p.Weapons[value] then
			return ""
		end
		local item = WeaponData.Get(value)
		if not item or item.Category ~= want then
			return ""
		end
		return value
	end

	p.EquippedBat = slot(raw.EquippedBat, "bat")
	p.EquippedTrap = slot(raw.EquippedTrap, "trap")
	-- FORWARD MIGRATION, the same shape as every other field: a save written
	-- before Walk Mode existed has no key here, `raw.WalkMode` is nil, and nil is
	-- not true -- so an old profile loads with it off and nothing is rewritten.
	p.WalkMode = raw.WalkMode == true
	-- The same forward migration for the menu size: no key, or no such option,
	-- is the default size, and nothing is rewritten until the player chooses.
	p.MenuSize = if GameConfig.menuSizeScale(raw.MenuSize) ~= nil
		then raw.MenuSize
		else GameConfig.MenuSize.Default

	--==========================================================================
	-- THE ONE-SLOT SAVE, SORTED INTO THE RIGHT DRAWER
	--
	-- Profiles written while Marigold sold a single equipped item carry
	-- `Equipped`, which this schema no longer has. It is read here ONLY to
	-- place it, and only into the slot its own category names -- so somebody
	-- who logged out holding a Comet Bat comes back with a Comet Bat in the bat
	-- slot and an empty trap slot, and somebody holding the Bramblejaw comes
	-- back the other way round.
	--
	-- The other slot is left EMPTY rather than guessed at. A player who owned
	-- five bats had exactly one out, and picking one of the other four for them
	-- would be inventing a decision they never made.
	--
	-- It runs only when the target slot is still empty, so a profile that has
	-- both the old field and a new one keeps the new one. No version bump: the
	-- old field is not a reshape of a field that still exists, it is a field
	-- that was replaced, and `Weapons` -- the thing that actually matters -- is
	-- untouched by any of this.
	--==========================================================================
	if type(raw.Equipped) == "string" and raw.Equipped ~= "" then
		local item = WeaponData.Get(raw.Equipped)
		if item and p.Weapons[raw.Equipped] then
			if item.Category == "bat" and p.EquippedBat == "" then
				p.EquippedBat = raw.Equipped
			elseif item.Category == "trap" and p.EquippedTrap == "" then
				p.EquippedTrap = raw.Equipped
			end
		end
	end

	-- Carried, not trusted. Version 2 is the first time this has branched.
	local from = 1
	if type(raw.Version) == "number" and raw.Version == raw.Version then
		from = math.floor(math.clamp(raw.Version, 1, 1e6))
		p.Version = from
	end

	--==========================================================================
	-- MIGRATION v1 -> v2: THE PLOT LADDER WAS RE-CUT UNDER LIVE SAVES
	--
	-- Version 1 had four levels of 4, 6, 8 and 10 rows, and capacity fell out of
	-- `rows * 3` -- so twelve plants at level 1. Version 2 has five levels with
	-- capacity written down, and level 1 holds FIVE. Every v1 garden is
	-- therefore potentially over its own level's new capacity, and the plot it
	-- is standing in is a different depth than the one its plants were saved in.
	--
	-- Two things have to be true when this finishes, and nothing else matters
	-- as much as these two:
	--
	--   1. NOT ONE VALID SAVED PLANT IS DISCARDED. Not one. The player grew
	--      them; a ladder change on our side is not a reason to take them. The
	--      level is raised to fit the garden rather than the garden cut to fit
	--      the level -- and a garden of more than twenty simply gets Level 5 and
	--      stays over capacity, which PlantService now restores intact.
	--   2. THE PLANTS DO NOT MOVE. Z is stored relative to the plot's CENTRE and
	--      the centre shifts when the depth changes, so leaving Z alone would
	--      slide the whole garden backwards by half the difference.
	--
	-- The gate is the fixed thing. Local -Z faces it, so a plant's distance from
	-- the gate is `z + depth/2` and that number does not care which ladder it
	-- was measured under. Convert through it and the garden stays put.
	--
	-- Which also resolves what looks circular: the new depth depends on the new
	-- level, and the new level depends on whether the plants fit the new depth.
	-- Gate distance is independent of both, so it is measured once, up front.
	--==========================================================================
	if from < 2 then
		local oldRows = GameConfig.LegacyPlotRowsV1[p.PlotTier]
			or GameConfig.LegacyPlotRowsV1[#GameConfig.LegacyPlotRowsV1]
		local oldDepth = GameConfig.plotDepthFor(oldRows)

		-- Distance from the gate, before anything moves.
		local gateDist = table.create(#p.Plants)
		local deepest = 0
		for i, plant in ipairs(p.Plants) do
			local d = plant.Z + oldDepth * 0.5
			gateDist[i] = d
			if d > deepest then
				deepest = d
			end
		end

		-- Big enough to HOLD them, then big enough to REACH the furthest one.
		-- Capacity first because that is the promise the level makes; reach
		-- second because a plant beyond the bed gets clamped to its back edge,
		-- and a row of plants all clamped to the same line is a visible loss.
		--
		-- ON THE LADDER AS IT STOOD (2026-10-07): Levels 1-5, the ones version 2
		-- was written against. Levels 6 and 7 are bought, never handed out by a
		-- migration, so a v1 save lands exactly where it always did -- without
		-- this cap a deep old garden would have migrated straight to Level 7.
		local top = math.min(MIGRATION_TOP_LEVEL, #GameConfig.PlotTiers)
		local level = math.min(math.max(p.PlotTier, GameConfig.plotLevelForPlants(#p.Plants)), top)
		while level < top do
			local _, far = GameConfig.plotGateReach(GameConfig.plotRowsForTier(level))
			if deepest <= far then
				break
			end
			level += 1
		end
		p.PlotTier = level

		--======================================================================
		-- THE NEW LADDER IS SHALLOWER AT THE TOP THAN THE OLD ONE WAS
		--
		-- v1 level 4 was ten rows, 132.8 studs deep. v2 level 5 is seven rows
		-- and 96.2, because capacity stopped being tied to the grid and twenty
		-- plants no longer need ten rows to sit in. So the loop above CANNOT
		-- always succeed: a v1 tier 3 or 4 garden with plants near its back
		-- fence has a rear section with nowhere to stand in any v2 plot.
		--
		-- Those plants are clamped to the back of the new bed. They keep their
		-- species, tier, age and stage -- they are not lost, which is the rule
		-- that outranks everything here -- but a deep old garden will find its
		-- last row or two bunched against the fence. That is the visible cost of
		-- re-cutting the ladder, and it is the cheapest one available: the
		-- alternatives were deleting the plants or keeping a ten-row level 5
		-- that no capacity number justifies.
		--
		-- Anyone below old tier 3 sees nothing at all. Their whole bed fits.
		--======================================================================
		local near, far = GameConfig.plotGateReach(GameConfig.plotRowsForTier(level))
		local half = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(level)) * 0.5
		for i, plant in ipairs(p.Plants) do
			plant.Z = math.clamp(gateDist[i], near, far) - half
		end

		p.Version = 2
	end

	--==========================================================================
	-- Strings only, capped, order preserved. A corrupt entry is dropped rather
	-- than repaired: the worst case for a dropped receipt is one retry that
	-- grants again, and the worst case for a repaired one is a grant that never
	-- happens because a mangled id matched.
	--==========================================================================
	if type(raw.Receipts) == "table" then
		for _, id in ipairs(raw.Receipts) do
			if type(id) == "string" and #id > 0 and #id <= 128
				and #p.Receipts < SAVE.MaxReceipts then
				table.insert(p.Receipts, id)
			end
		end
	end
	-- Whole, never below zero, never past the cap; anything else reads 0.
	p.InstantCredits = math.floor(number(raw.InstantCredits, 0, 0, SAVE.MaxInstantCredits))
	-- True only when saved true; the reminder only one of its three words.
	p.HatchBonusClaimed = raw.HatchBonusClaimed == true
	p.BatHintShown = raw.BatHintShown == true
	p.LikeReminder = if raw.LikeReminder == "pending" or raw.LikeReminder == "shown" then raw.LikeReminder else ""
	-- The first minute (2026-10-08): a whole timestamp or 0; a caught species
	-- only if the sheet still has it, with a real size, else nothing waiting.
	p.StarterAt = math.floor(number(raw.StarterAt, 0, 0, MAX_TIME))
	local caught = if type(raw.FirstCatchSpecies) == "string" then SeedData.Get(raw.FirstCatchSpecies) else nil
	local caughtTier = math.floor(number(raw.FirstCatchTier, 0, 0, SeedData.TierCount))
	if caught and caughtTier >= 1 then
		p.FirstCatchSpecies = caught.Id
		p.FirstCatchTier = caughtTier
	end
	-- Treadmill fun (2026-10-08). A save with NO milestone key is from before
	-- they existed: every milestone under its Speed is passed, unpaid. A key
	-- that is there is read as it stands.
	p.SpeedMilestone = if type(raw.SpeedMilestone) == "number"
		then number(raw.SpeedMilestone, 0, 0, SAVE.MaxSpeedScore)
		else SpeedMilestones.highestAtOrBelow(p.Speed)
	p.MilestoneSpinsOwed = math.floor(number(raw.MilestoneSpinsOwed, 0, 0, 5))
	p.BeltTicketAt = math.floor(number(raw.BeltTicketAt, 0, 0, now))
	p.BeltTicketCount = if p.BeltTicketAt > 0
		then math.floor(number(raw.BeltTicketCount, 0, 0, BeltCatch.TicketsPerWindow))
		else 0
	p.CommunityClaimed = raw.CommunityClaimed == true
	-- Invite a Friend (2026-10-06): whole, positive ids, each once, the newest
	-- MaxRemembered; the forms given, whole and within the track; the panel's
	-- seen flag only when saved true.
	p.InviteIds = {}
	if type(raw.InviteIds) == "table" then
		local seenIds: { [number]: boolean } = {}
		for _, id in ipairs(raw.InviteIds) do
			if type(id) == "number" and id == id and id >= 1 and id < 2 ^ 53 and math.floor(id) == id
				and not seenIds[id] then
				seenIds[id] = true
				table.insert(p.InviteIds, id)
			end
		end
		while #p.InviteIds > GameConfig.InviteRewards.MaxRemembered do
			table.remove(p.InviteIds, 1)
		end
	end
	p.InviteGranted = math.floor(number(raw.InviteGranted, 0, 0, #GameConfig.InviteRewards.Forms))
	p.InviteSeen = raw.InviteSeen == true
	-- The invite plants ever given (2026-10-08): the track's own form ids, each
	-- once. A save from before has none written: the forms its milestones gave.
	p.InviteOwned = {}
	local forms = GameConfig.InviteRewards.Forms
	if type(raw.InviteOwned) == "table" then
		for _, id in ipairs(raw.InviteOwned) do
			if type(id) == "string" and table.find(forms, id) and not table.find(p.InviteOwned, id) then
				table.insert(p.InviteOwned, id)
			end
		end
	else
		for i = 1, p.InviteGranted do
			table.insert(p.InviteOwned, forms[i])
		end
	end
	-- Returning friends already paid for (2026-10-08): whole, positive ids,
	-- each once, the newest MaxRemembered.
	p.InviteReturnIds = {}
	if type(raw.InviteReturnIds) == "table" then
		local seenBack: { [number]: boolean } = {}
		for _, id in ipairs(raw.InviteReturnIds) do
			if type(id) == "number" and id == id and id >= 1 and id < 2 ^ 53 and math.floor(id) == id
				and not seenBack[id] then
				seenBack[id] = true
				table.insert(p.InviteReturnIds, id)
			end
		end
		while #p.InviteReturnIds > GameConfig.InviteRewards.MaxRemembered do
			table.remove(p.InviteReturnIds, 1)
		end
	end
	-- Sprout Dash (2026-10-08): whole, non-negative times and distances; the
	-- earned log's rows well-formed, at most 60 of them (an hour holds 15 at
	-- the most a run pays).
	local function wholeOrZero(v: any): number
		return if type(v) == "number" and v == v and v >= 0 and v < 2 ^ 53 then math.floor(v) else 0
	end
	p.SproutBoostEndsAt = wholeOrZero(raw.SproutBoostEndsAt)
	p.SproutBestDay = wholeOrZero(raw.SproutBestDay)
	p.SproutBest = wholeOrZero(raw.SproutBest)
	p.SproutEarned = {}
	if type(raw.SproutEarned) == "table" then
		for _, row in ipairs(raw.SproutEarned) do
			if type(row) == "table" and wholeOrZero(row.At) > 0 and wholeOrZero(row.Seconds) > 0 then
				table.insert(p.SproutEarned, { At = wholeOrZero(row.At), Seconds = wholeOrZero(row.Seconds) })
			end
		end
		while #p.SproutEarned > 60 do
			table.remove(p.SproutEarned, 1)
		end
	end
	-- Rebirth (2026-10-08): whole and never below 0, like the times above.
	p.Rebirths = wholeOrZero(raw.Rebirths)
	p.RebirthAt = wholeOrZero(raw.RebirthAt)
	-- Global mini-event claims: well-formed rows only, one per id, counts
	-- whole and within the cap, the newest ClaimsKept kept.
	p.EventClaims = {}
	if type(raw.EventClaims) == "table" then
		local T = GameConfig.MiniEvent.Tickets
		local seen: { [string]: boolean } = {}
		local rows: { { Id: string, Count: number, At: number } } = {}
		for _, row in ipairs(raw.EventClaims) do
			if #rows >= 64 then
				break
			end
			if type(row) == "table" and type(row.Id) == "string" and #row.Id > 0 and #row.Id <= 40
				and string.match(row.Id, "^[%w_%-]+$") ~= nil and not seen[row.Id] then
				seen[row.Id] = true
				table.insert(rows, {
					Id = row.Id,
					Count = math.floor(number(row.Count, 0, 0, T.PerPlayerCap)),
					At = math.floor(number(row.At, 0, 0, MAX_TIME)),
				})
			end
		end
		while #rows > T.ClaimsKept do
			table.remove(rows, 1)
		end
		p.EventClaims = rows
	end
	-- Pod Rush (2026-10-09): an id like an event claim's (or ""), whole counts
	-- in range, and owed pods only for biomes that exist, MaxOwed at most.
	do
		local row = if type(raw.PodRush) == "table" then raw.PodRush else {}
		local id = row.Id
		local owed: { string } = {}
		if type(row.PodOwed) == "string" then
			for biomeId in string.gmatch(row.PodOwed, "[^,]+") do
				if BiomeData.ById[biomeId] ~= nil and #owed < GameConfig.PodRush.MaxOwed then
					table.insert(owed, biomeId)
				end
			end
		end
		p.PodRush = {
			Id = if type(id) == "string" and #id <= 40 and string.match(id, "^[%w_%-]*$") ~= nil then id else "",
			Count = math.floor(number(row.Count, 0, 0, 9999)),
			Paid = math.floor(number(row.Paid, 0, 0, #GameConfig.PodRush.Levels)),
			Top = math.floor(number(row.Top, 0, 0, #BiomeData.Biomes)),
			PodOwed = table.concat(owed, ","),
		}
	end
	-- ON unless saved false: an old save with no key dances.
	p.DiscoDance = raw.DiscoDance ~= false

	--==========================================================================
	-- THE HOTBAR AND THE HEARTS, AGAINST WHAT IS OWNED NOW
	--
	-- Here because everything they name is clean by now: Held with its ids,
	-- Weapons, both equipped slots (the legacy one sorted in), WheelEarned. A
	-- saved bar keeps its positions and loses whatever is no longer owned; a
	-- faint slot whose kind is owned and placed nowhere is filled (HotbarSlots.
	-- fill). No saved bar: seeded from what they have out. Junk is CLEANED, not
	-- re-seeded -- an emptied bar was the player's choice.
	--==========================================================================
	p.Hotbar = if type(raw.Hotbar) == "table"
		then HotbarSlots.fill(p, HotbarSlots.clean(p, raw.Hotbar))
		else HotbarSlots.seed(p)
	p.Favourites = HotbarSlots.cleanFavourites(p, raw.Favourites)

	p.Tutorial = TutorialData.Sanitise(raw.Tutorial, p)
	-- Unknown keys are dropped by construction: everything above copies FROM
	-- raw INTO a fresh default, so a field removed from the schema stops being
	-- carried the moment it stops being read here.
	return p
end

--==============================================================================
-- AN OLD OVERCLOCK BECOMES A MILL (the owner's addendum, 2026-10-06)
--
-- Overclock ran a tier-10 mill at 400M x 2^level a second. Tiers 11-14 replaced
-- it, so a tier-10 save with levels becomes the LOWEST of those tiers paying at
-- least what it did -- levels 1-2 Abyssal Trench, 3-5 Volcanic Forge, 6-7
-- Frozen Aurora, 8-10 Event Horizon -- for nothing, and its overclock goes to
-- 0. A save at any other tier keeps its tier and loses the levels: they were
-- only ever sold at 10.
--
-- Run by PlayerDataService on every load, after Sanitise, and saved through
-- the normal path. Idempotent: a second run finds overclock 0 and does
-- nothing. Returns the tier the overclock became, or nil when no tier changed.
--==============================================================================
local OVERCLOCK_TIER = 10
local OVERCLOCK_BASE = 400000000
local OVERCLOCK_MULTIPLIER = 2

-- What a tier-10 mill at `level` paid a second, before rebirths.
function ProfileSchema.overclockRate(level: number): number
	return OVERCLOCK_BASE * OVERCLOCK_MULTIPLIER ^ level
end

function ProfileSchema.convertOverclock(p: Profile): number?
	local level = p.MillOverclock
	if type(level) ~= "number" or level <= 0 then
		return nil
	end
	p.MillOverclock = 0
	if p.MillTier ~= OVERCLOCK_TIER then
		return nil
	end
	local paid = ProfileSchema.overclockRate(level)
	local tiers = GameConfig.Mill.Tiers
	local became = #tiers
	for tier = OVERCLOCK_TIER + 1, #tiers do
		if tiers[tier].speed >= paid then
			became = tier
			break
		end
	end
	p.MillTier = became
	return became
end

return ProfileSchema
