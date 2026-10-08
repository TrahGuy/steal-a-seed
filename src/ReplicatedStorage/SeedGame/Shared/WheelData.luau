--!strict
-- Steal a Seed :: WheelData
--
-- THE OBBY REWARD WHEEL, AS NUMBERS (2026-09-27). Every prize, amount, weight,
-- species pool, colour and name the wheel uses, and the pure arithmetic over
-- them -- the sectors, the roll, and the complete list of final outcomes with
-- their exact odds. WheelService, WheelUI, WheelDraw and WheelSpec all read
-- this and nothing else, so a prize changes in one place.
--
--==============================================================================
-- THESE ARE TEST VALUES, NOT APPROVED LAUNCH BALANCE
--
-- Chosen conservative against the economy as it stands (KB/HANDOFF.md, the
-- wheel entry): the cash prizes sit at and under the cheapest bat and the
-- smallest cash pack ($5K, $24K); the Speed prizes are the tutorial's first
-- target and ten times it; pods are Big-sized unless the prize names a bigger
-- size. The owner sets the real ones. SINCE 2026-10-08 those cash and Speed
-- amounts are FLOORS: each prize pays the larger of its floor and a few
-- minutes of the player's own income or mill (THE PRIZES SCALE WITH THE
-- PLAYER, below), shown on the wheel exactly as it is paid.
--
--==============================================================================
-- WEIGHTS ARE WHOLE NUMBERS OUT OF 10,000
--
-- So the odds are exact decimals with no float drift: 2,200 is 22%, 40 is
-- 0.4%. TotalWeight is asserted below and by WheelSpec. The Colossal pod is
-- rarer than the Titan pod and the trail is the rarest outcome of all, as the
-- brief requires; the wheel draws every sector at exactly its share of the
-- circle, so the trail is a sliver, never an equal slice.
--==============================================================================

local Shared = script.Parent
local SeedData = require(Shared:WaitForChild("SeedData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local WheelData = {}

-- The one switch. Off: no wheel is built, no spin is earned, and the obby pays
-- its Speed exactly as before.
WheelData.Enabled = true

--==============================================================================
-- THE DAILY EARNING ALLOWANCE
--
-- Up to `Limit` spins EARNED from obby completions per player per rolling
-- window of `WindowSeconds`, which opens at the first spin-earning completion
-- (server os.time) and runs whether or not the player is online. Not a cap on
-- how many spins can be HELD: unused spins keep, bought spins never count, and
-- spending never gives the allowance back.
--==============================================================================
WheelData.Daily = {
	Limit = 5,
	WindowSeconds = 24 * 60 * 60,
}

-- Upper bounds a saved balance is clamped to on load -- far above anything a
-- player can reach, there only so a corrupt save cannot hold a billion spins.
WheelData.MaxEarnedHeld = 500
WheelData.MaxBoughtHeld = 100000
-- How many recorded-but-undelivered prizes a profile may hold (a pod waiting for
-- bag space, or a prize whose delivery a crash interrupted).
WheelData.MaxPending = 10
-- How many completion ids a profile remembers, so a completion can never be
-- credited twice however it arrives.
WheelData.RememberRuns = 12

--==============================================================================
-- PAID SPINS: THREE SPIN-TICKET PACKS, SWITCHED ON (2026-10-01)
--
-- The owner's packs since 2026-10-01 (Roblox's own record of each, asked from
-- Studio, carries the owner's icon):
--
--   spin1    3715745320   "X1 Spin Ticket"     1 bought spin    listed at 19 Robux
--   spin5    3715745407   "x5 Spin Tickets"    5 bought spins   listed at 85 Robux
--   spin10   3715745552   "x10 Spin Tickets"   10 bought spins  listed at 180 Robux
--
-- No pack is called the best value: at these list prices two x5 packs cost less
-- than one x10.
--
-- THE TWO FIRST PRODUCTS ARE RETIRED (RetiredProducts), disabled by the owner:
-- 3715369823 "+1 Spin" and 3715370108 "+10 Spins" (2026-09-29). Never shown,
-- never prompted -- but a receipt for one still pays what it always did, once,
-- through the same ledger, so nothing bought before is lost.
--
-- A BOUGHT SPIN IS A PAID RANDOM ITEM. Roblox's rules for one (Creator Docs,
-- "Paid random items policy guidelines"; the clarification of 2026-05-26) are
-- what Paid.Enabled waits for, and KB/HANDOFF.md's paid-spins entry lists them:
-- every final outcome's numerical odds shown before the purchase and before a
-- bought spin is spent, behind a button that SAYS what it is; nothing offered
-- to a player PolicyService restricts, or whose answer could not be had; the
-- Content Maturity questionnaire declaring paid random items; and neither
-- product sold outside the game.
--
-- `Enabled` IS THE ONE SWITCH. The owner turned it on on 2026-10-01, with paid
-- random items declared in the Content Maturity questionnaire and sales outside
-- the game switched off for the three packs. On, PolicyService still decides,
-- player by player, and fails closed. Off, StoreService indexes no spin
-- product, so no receipt can grant a spin; WheelService opens no purchase
-- prompt and lets no bought spin be spent; and the panel shows no way to buy.
-- The free, earned path never reads any of this.
--
-- `robux` IS THE OWNER'S LIST PRICE, FOR THE RECORD ONLY. Roblox prices by
-- region -- Studio was quoted 8, 35 and 75 for the three packs -- so the Shop
-- and the wheel print what RobuxPrice hears from Roblox for THIS player and
-- never this number.
--
-- `icon` is the product's own icon as Roblox reports it (IconImageAssetId): the
-- owner's artwork, uploaded by the owner with the product (the x10's is the
-- rainbow one). All three load in Podnappers (Studio preload, 2026-10-01).
--==============================================================================
export type Product = {
	key: string,
	productId: number,
	spins: number,
	robux: number,
	name: string,
	icon: number,
}

WheelData.Paid = {
	Enabled = true,
	-- Seconds one player waits between two purchase prompts.
	PromptCooldown = 2,
}

-- What is sold, in the order the Shop and GET SPINS show it.
WheelData.Products = {
	{ key = "spin1", productId = 3715745320, spins = 1, robux = 19, name = "×1 Spin Ticket", icon = 74250574261417 },
	{ key = "spin5", productId = 3715745407, spins = 5, robux = 85, name = "×5 Spin Tickets", icon = 129968452678126 },
	{ key = "spin10", productId = 3715745552, spins = 10, robux = 180, name = "×10 Spin Tickets",
		icon = 109596534013386 },
} :: { Product }

-- No longer sold: never shown or prompted, and no key a client can ask for.
-- StoreService still honours a receipt for one (receiptProducts).
WheelData.RetiredProducts = {
	{ key = "retired1", productId = 3715369823, spins = 1, robux = 9, name = "+1 Spin", icon = 84064901294156 },
	{ key = "retired10", productId = 3715370108, spins = 10, robux = 85, name = "+10 Spins", icon = 139551271701020 },
} :: { Product }

-- The SOLD products, by key and by id: what a client may ask for.
WheelData.ProductByKey = {} :: { [string]: Product }
WheelData.ProductById = {} :: { [number]: Product }
do
	local keys: { [string]: boolean } = {}
	local ids: { [number]: boolean } = {}
	local function admit(product: Product, sold: boolean)
		assert(type(product.key) == "string" and #product.key > 0 and not keys[product.key],
			"WheelData: a spin product's key is missing or used twice")
		assert(product.productId > 0 and product.productId == math.floor(product.productId)
			and not ids[product.productId],
			"WheelData: spin product " .. product.key .. " has no id of its own")
		assert(product.spins >= 1 and product.spins == math.floor(product.spins),
			"WheelData: spin product " .. product.key .. " grants no whole number of spins")
		keys[product.key] = true
		ids[product.productId] = true
		if sold then
			WheelData.ProductByKey[product.key] = product
			WheelData.ProductById[product.productId] = product
		end
	end
	for _, product in ipairs(WheelData.Products) do
		admit(product, true)
	end
	for _, product in ipairs(WheelData.RetiredProducts) do
		admit(product, false)
	end
end

-- Every product a receipt may name: the sold ones and the retired ones.
function WheelData.receiptProducts(): { Product }
	local all = table.clone(WheelData.Products)
	for _, product in ipairs(WheelData.RetiredProducts) do
		table.insert(all, product)
	end
	return all
end

--==============================================================================
-- A STUDIO PREVIEW, NEVER A LIVE SWITCH (2026-10-01)
--
-- So the Shop and GET SPINS can be looked at in Studio Play without turning
-- `Enabled` on in source -- the owner's Publish ships the working tree, and
-- Enabled waits for the owner's own steps. In Studio, and only there, a
-- ReplicatedStorage attribute PREVIEW_ATTRIBUTE = true counts as on, for the
-- server and every client alike. A live server is never Studio, so there this
-- is just Enabled. PolicyService still decides who may buy, preview or not.
-- With Enabled on (2026-10-01) it changes nothing; it stays for the day the
-- switch is off again.
--==============================================================================
WheelData.PreviewAttribute = "SeedPaidSpinsStudioPreview"

-- The Shop's REWARDS & ODDS (2026-10-01): ShopUI bumps this LOCAL attribute on
-- its own player and WheelUI opens straight to Reward info -- one sheet of odds
-- for both places a spin is sold. Never replicated; asks for nothing.
WheelData.OpenOddsAttribute = "WheelOpenOddsRequest"

local function studioPreview(): boolean
	local ok, on = pcall(function()
		return game:GetService("RunService"):IsStudio()
			and game:GetService("ReplicatedStorage"):GetAttribute(WheelData.PreviewAttribute) == true
	end)
	return ok and on == true
end

-- Whether paid spins exist at all in this build: the switch, and something to sell.
function WheelData.paidLive(): boolean
	return (WheelData.Paid.Enabled == true or studioPreview()) and #WheelData.Products > 0
end

--==============================================================================
-- THE POOLS A POD PRIZE PICKS ITS SPECIES FROM
--
-- Explicit species ids, each checked against SeedData when this loads. A prize
-- picks one with equal odds, on the server, at the spin; the species stays
-- hidden until the pod's own hatch reveal, like every pod's does.
--
--   common    the five Common and Uncommon species
--   rare      the eight Rare-FORM species: the hatch reveals "RARE"
--==============================================================================
WheelData.Pools = {
	common = { "nubkin", "petalpip", "spiretip", "dunebud", "paddlehop" },
	rare = { "toadcap", "thornwhorl", "bogbonnet", "crookreed", "cinderpaw", "emberquill", "novaorb", "cosmospire" },
}

--==============================================================================
-- THE TWELVE PRIZES, IN WHEEL ORDER (clockwise from the pointer at 12 o'clock)
--
--   kind    cash | speed | pod | boost | trail
--   amount  cash and speed: exactly what is paid and printed on the sector
--   tier    pods: the size tier the pod is (2 Big, 6 Titan, 7 Colossal)
--   pool    pods: which species pool
--   boost   boosts: the Bonus Chest reward id it grants (same definition and
--           rules: +25% for 2 minutes, and a new boost replaces a running one)
--   swap    the trail: the prize paid instead to a player who owns it already
--==============================================================================
export type Reward = {
	id: string,
	kind: string,
	weight: number,
	-- Short words on the sector, and the full name in lists and results.
	label: string,
	title: string,
	colour: Color3,
	icon: string,
	amount: number?,
	tier: number?,
	pool: string?,
	boost: string?,
	swap: string?,
	-- Cash and Speed (2026-10-08, THE PRIZES SCALE WITH THE PLAYER): `amount`
	-- is the FLOOR, and the prize pays the larger of it and `seconds` of the
	-- player's garden income ("income") or of their own mill's tier rate
	-- ("mill"). See WheelData.amountFor.
	scale: { per: string, seconds: number }?,
	--==========================================================================
	-- DISPLAY ONLY (the wheel panel, approved mockup 2026-09-27). The server
	-- never reads these: the roll, the payout and the odds do not depend on them.
	--   short    the prize's name in the Reward info list ("+1,000 Speed")
	--   rarity   its rarity word, a GameConfig.Rarities name, strictly by odds:
	--            a rarer prize never carries a lower tier (WheelSpec checks)
	--   note     a small line under the name in that list
	--   rainbow  drawn with the animated rainbow (the Bloomrunner Trail)
	--==========================================================================
	short: string,
	rarity: string,
	note: string?,
	rainbow: boolean?,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Sector colours are the approved mockup's (Podnappers Spin Wheel Mockup); the
-- three prizes it does not draw got a lilac, a red and a gold of their own.
WheelData.Rewards = {
	{ id = "cash_small", kind = "cash", amount = 5000, weight = 2180, scale = { per = "income", seconds = 120 },
		label = "$5,000", title = "$5,000 Cash", colour = rgb(63, 174, 90), icon = "cash",
		short = "$5,000", rarity = "Common" },
	{ id = "speed_small", kind = "speed", amount = 1000, weight = 2000, scale = { per = "mill", seconds = 60 },
		label = "+1,000 SPEED", title = "+1,000 Speed", colour = rgb(63, 143, 224), icon = "speed",
		short = "+1,000 Speed", rarity = "Common" },
	{ id = "pod_common", kind = "pod", tier = 2, pool = "common", weight = 1300,
		label = "POD", title = "Big Pod", colour = rgb(147, 87, 214), icon = "pod",
		short = "Pod", rarity = "Uncommon" },
	{ id = "boost_income", kind = "boost", boost = "income", weight = 950,
		label = "+25% INCOME", title = "+25% Plant Income, 2 min", colour = rgb(31, 158, 140), icon = "boost",
		short = "+25% Income", rarity = "Rare" },
	{ id = "cash_medium", kind = "cash", amount = 20000, weight = 1000, scale = { per = "income", seconds = 360 },
		label = "$20,000", title = "$20,000 Cash", colour = rgb(43, 138, 69), icon = "cash",
		short = "$20,000", rarity = "Rare" },
	{ id = "speed_large", kind = "speed", amount = 10000, weight = 700, scale = { per = "mill", seconds = 300 },
		label = "+10,000 SPEED", title = "+10,000 Speed", colour = rgb(42, 95, 192), icon = "speed",
		short = "+10,000 Speed", rarity = "Epic" },
	{ id = "pod_rare", kind = "pod", tier = 2, pool = "rare", weight = 500,
		label = "RARE POD", title = "Rare Pod (Big)", colour = rgb(186, 96, 214), icon = "pod",
		short = "Rare Pod", rarity = "Epic" },
	{ id = "boost_training", kind = "boost", boost = "training", weight = 850,
		label = "+25% TRAINING", title = "+25% Training, 2 min", colour = rgb(72, 182, 232), icon = "boost",
		short = "+25% Training", rarity = "Rare" },
	{ id = "pod_titan", kind = "pod", tier = 6, pool = "common", weight = 150,
		label = "TITAN", title = "Random Titan Pod", colour = rgb(214, 70, 60), icon = "pod",
		short = "Titan Pod", rarity = "Legendary" },
	{ id = "cash_jackpot", kind = "cash", amount = 75000, weight = 250, scale = { per = "income", seconds = 1200 },
		label = "$75,000", title = "$75,000 Cash Jackpot", colour = rgb(236, 160, 42), icon = "cash",
		short = "$75,000 Jackpot", rarity = "Legendary" },
	{ id = "pod_colossal", kind = "pod", tier = 7, pool = "common", weight = 60,
		label = "COLOSSAL", title = "Random Colossal Pod", colour = rgb(58, 42, 77), icon = "pod",
		short = "Colossal Pod", rarity = "Legendary", note = "species hidden until hatch" },
	{ id = "trail", kind = "trail", swap = "cash_jackpot", weight = 40,
		label = "TRAIL", title = "Bloomrunner Trail", colour = rgb(140, 236, 190), icon = "trail",
		short = "Bloomrunner Trail", rarity = "Mythic", rainbow = true },
	-- INVITE PLANTS ON THE WHEEL (2026-10-08, Michael's suggestion, the owner's
	-- approval): for a player with no friends to invite. The next invite plant
	-- in the track's order (GameConfig.InviteRewards.Forms) that this player has
	-- never been given, handed over as an invite gives it (grown, placeable,
	-- unsellable; owed while the Bag is full); with every one owned it pays its
	-- swap, as the trail does. Its 20 came off cash_small (2200 -> 2180).
	{ id = "invite", kind = "invite", swap = "cash_jackpot", weight = 20,
		label = "INVITE PLANT", title = "Invite Plant", colour = rgb(232, 84, 156), icon = "invite",
		short = "Invite Plant", rarity = "Mythic", note = "one you don't own yet" },
} :: { Reward }

WheelData.TotalWeight = 10000

WheelData.ById = {} :: { [string]: Reward }
do
	local total = 0
	for _, reward in ipairs(WheelData.Rewards) do
		assert(WheelData.ById[reward.id] == nil, "WheelData: duplicate prize id " .. reward.id)
		assert(reward.weight > 0 and reward.weight == math.floor(reward.weight),
			"WheelData: a weight is a whole number above 0 (" .. reward.id .. ")")
		WheelData.ById[reward.id] = reward
		total += reward.weight
		if reward.kind == "pod" then
			local pool = WheelData.Pools[reward.pool or ""]
			assert(pool and #pool > 0, "WheelData: " .. reward.id .. " names no pool")
			assert(reward.tier and reward.tier >= 1 and reward.tier <= SeedData.TierCount,
				"WheelData: " .. reward.id .. " names no size tier")
		elseif reward.kind == "cash" or reward.kind == "speed" then
			assert(reward.amount and reward.amount > 0, "WheelData: " .. reward.id .. " pays nothing")
		end
	end
	assert(total == WheelData.TotalWeight, string.format("WheelData: weights sum to %d, not %d", total,
		WheelData.TotalWeight))
	for name, pool in pairs(WheelData.Pools) do
		for _, id in ipairs(pool) do
			assert(SeedData.Get(id), string.format("WheelData: pool %s names %s, which is not a species", name, id))
		end
	end
	local swap = WheelData.ById.trail.swap
	assert(swap and WheelData.ById[swap], "WheelData: the trail's replacement is not a prize")
	local inviteSwap = WheelData.ById.invite.swap
	assert(inviteSwap and WheelData.ById[inviteSwap], "WheelData: the invite prize's replacement is not a prize")
	assert(#GameConfig.InviteRewards.Forms > 0, "WheelData: the invite prize has no plants to give")
	for _, reward in ipairs(WheelData.Rewards) do
		local scale = reward.scale
		if scale then
			assert((reward.kind == "cash" or reward.kind == "speed") and (scale.per == "income" or scale.per == "mill")
				and scale.seconds > 0, "WheelData: " .. reward.id .. " scales by nothing a cash or Speed prize can")
		end
	end
	-- A boost prize's words come from the Bonus Chest's own definition, so the
	-- wheel can never promise a size or a length the chest does not grant.
	local seconds = GameConfig.BonusChest.BoostSeconds
	for _, reward in ipairs(WheelData.Rewards) do
		if reward.kind == "boost" then
			local chest = GameConfig.bonusChestReward(reward.boost)
			assert(chest, "WheelData: " .. reward.id .. " names no Bonus Chest boost")
			local pct = math.floor((chest.Multiplier - 1) * 100 + 0.5)
			reward.label = string.format("+%d%% %s", pct, if reward.boost == "income" then "INCOME" else "TRAINING")
			reward.title = string.format("%s for %d min", chest.Title, seconds // 60)
			reward.short = string.format("+%d%% %s", pct, if reward.boost == "income" then "Income" else "Training")
		end
	end
	for _, reward in ipairs(WheelData.Rewards) do
		assert(GameConfig.RarityTier[reward.rarity], "WheelData: " .. reward.id .. " names no rarity")
	end
end

--==============================================================================
-- THE BLOOMRUNNER TRAIL
--==============================================================================
WheelData.Trail = {
	Id = "bloomrunner",
	Name = "Bloomrunner Trail",
	Mint = rgb(140, 236, 190),
	Gold = rgb(255, 214, 110),
	Leaf = rgb(92, 196, 120),
}

--==============================================================================
-- NAMES THE CLIENT AND SERVER SHARE
--==============================================================================
WheelData.Attributes = {
	-- Unused spins, by source.
	Earned = "WheelSpinsEarned",
	Bought = "WheelSpinsBought",
	-- Spins earned in the open window, and os.time() at which it closes (nil when
	-- no window is open).
	DayCount = "WheelDayCount",
	DayEndsAt = "WheelDayEndsAt",
	-- Prizes recorded and not yet delivered (a pod waiting for bag space).
	Pending = "WheelPending",
	-- True only when PolicyService says this player may use paid random items AND
	-- the product is configured and enabled.
	PaidAllowed = "WheelPaidAllowed",
	-- The player owns the trail; and the trail they wear (every client draws it).
	TrailOwned = "TrailOwned",
	Trail = "SeedTrail",
	-- This player's cash and Speed prizes as the next spin pays them
	-- (WheelData.encodeAmounts): published when the panel opens and after
	-- every spin, and what the roll pays -- so the wheel's words are the pay.
	Amounts = "WheelAmounts",
}

WheelData.Actions = {
	-- client -> server: spin ("earned" or "bought"), claim waiting prizes, and
	-- wear or take off the trail. server -> client: the result.
	Spin = "WheelSpin",
	Claim = "WheelClaim",
	Equip = "TrailEquip",
	Result = "WheelResult",
	-- client -> server: ask for the purchase prompt of one spin product, by its
	-- key ("spin1", "spin5", "spin10"; never a retired one). The SERVER opens the
	-- prompt -- from the wheel's GET SPINS or the Shop alike -- and only for a player
	-- it may sell to; the spins come from the receipt and nowhere else.
	Buy = "WheelBuy",
	-- client -> server: TELEPORT TO the obby's entrance (the OBBY button).
	ObbyTeleport = "ObbyTeleport",
	-- client -> server, carrying nothing: the wheel panel opened -- publish this
	-- player's prize amounts again (Attributes.Amounts).
	Open = "WheelOpen",
	-- server -> client: the one-time hatch bonus was given (WheelService.
	-- GrantHatchBonus): { label = "first" | "welcome", revealAt = server time
	-- the hatched plant shows }. HatchBonusUI says so once the reveal is over.
	HatchBonus = "WheelHatchBonus",
}

WheelData.FolderName = "SeedWheel"

--==============================================================================
-- WHERE THE WHEEL STANDS (surveyed from the map's own numbers, 2026-09-27)
--
-- On the hub deck's centre line, 14 studs behind Marigold's stall, facing north
-- (+Z) toward plots 3 and 4: clear of the overflow spawn at the deck's centre
-- (38 studs), of Marigold's wander box and her prompt's reach (it ends at
-- z 33.7; this prompt's starts at 35), of both sell boards (24), of every
-- plot-to-stall and plot-to-road walk (about 21), and 8 inside the deck's edge.
-- The sign stands on the arch above the wheel, high enough to show over the
-- stall's awning from the spawn.
--==============================================================================
WheelData.Place = {
	Position = Vector3.new(0, 0.9, 38),
	FacingDegrees = 0,
	PromptDistance = 9,
	-- The sign's own draw distance: readable across the hub, gone beyond it.
	SignDistance = 150,
}

--==============================================================================
-- THE SECTORS: each prize's arc, in degrees clockwise from the pointer
--==============================================================================
export type Sector = { reward: Reward, start: number, finish: number, mid: number }

function WheelData.sectors(): { Sector }
	local out: { Sector } = {}
	local at = 0
	for _, reward in ipairs(WheelData.Rewards) do
		local span = reward.weight / WheelData.TotalWeight * 360
		table.insert(out, { reward = reward, start = at, finish = at + span, mid = at + span / 2 })
		at += span
	end
	return out
end

--==============================================================================
-- THE ROLL
--
-- `pick` is a whole number 1..TotalWeight from the server's own Random; the
-- prize is the sector it falls in, in wheel order. `within` (0..1) is where in
-- that sector the pointer comes to rest -- uniform, so the wheel never stops
-- near an edge on purpose (no fake near misses). Pure, so WheelSpec drives it.
--==============================================================================
function WheelData.prizeAt(pick: number): Reward
	local n = math.clamp(math.floor(pick), 1, WheelData.TotalWeight)
	local at = 0
	for _, reward in ipairs(WheelData.Rewards) do
		at += reward.weight
		if n <= at then
			return reward
		end
	end
	return WheelData.Rewards[#WheelData.Rewards]
end

-- The prize actually paid for `reward`: the trail becomes its swap for a player
-- who owns it already, and the invite prize for one who owns every invite
-- plant. Returns the paid prize and whether it was swapped.
function WheelData.resolve(reward: Reward, ownsTrail: boolean, ownsEveryInvite: boolean?): (Reward, boolean)
	if reward.swap and ((reward.kind == "trail" and ownsTrail)
		or (reward.kind == "invite" and ownsEveryInvite == true)) then
		return WheelData.ById[reward.swap], true
	end
	return reward, false
end

-- The invite plant the wheel gives a player who has been given `owned` (a set
-- of species ids): the first of the track's forms not in it, or nil when they
-- own them all. The track's order, so the wheel never jumps straight to the
-- top referral reward.
function WheelData.nextInvite(owned: { [string]: boolean }): string?
	for _, form in ipairs(GameConfig.InviteRewards.Forms) do
		if not owned[form] then
			return form
		end
	end
	return nil
end

-- The angle (clockwise from the pointer) of the point on the wheel that must
-- stop under the pointer for `reward`, `within` its arc. Kept a little inside
-- both edges so the pointer never sits on a divider line.
function WheelData.landingAngle(reward: Reward, within: number): number
	for _, sector in ipairs(WheelData.sectors()) do
		if sector.reward == reward then
			local w = math.clamp(within, 0.1, 0.9)
			return sector.start + (sector.finish - sector.start) * w
		end
	end
	return 0
end

--==============================================================================
-- THE WHEEL AS DRAWN (display only, approved mockup 2026-09-27)
--
-- The wheel the player SEES lays its prizes out in DisplayOrder, which
-- spreads the small sectors round the circle, at READABLE sizes: each prize
-- gets DisplayFloor degrees plus a share of what is left in proportion to its
-- weight. So the sizes still follow the odds (a rarer prize is never drawn
-- bigger) but the rarest is still wide enough for its icon. Not to scale: the
-- exact odds are in Reward info. The roll above never reads any of this; a
-- spin comes to rest inside the rolled prize's DRAWN sector (displayLanding,
-- the same 10%-in-from-each-edge rule), so the pointer always shows the prize
-- that was won.
--==============================================================================
WheelData.DisplayOrder = {
	"cash_small", "speed_small", "pod_common", "pod_colossal", "boost_income", "pod_rare",
	"cash_medium", "trail", "speed_large", "pod_titan", "invite", "boost_training", "cash_jackpot",
}
WheelData.DisplayFloor = 12

do
	local seen = {}
	for _, id in ipairs(WheelData.DisplayOrder) do
		assert(WheelData.ById[id] and not seen[id], "WheelData: DisplayOrder names " .. id .. " wrongly")
		seen[id] = true
	end
	assert(#WheelData.DisplayOrder == #WheelData.Rewards, "WheelData: DisplayOrder misses a prize")
	assert(WheelData.DisplayFloor * #WheelData.DisplayOrder < 360, "WheelData: DisplayFloor leaves no room")
end

function WheelData.displaySectors(): { Sector }
	local out: { Sector } = {}
	local spare = 360 - WheelData.DisplayFloor * #WheelData.DisplayOrder
	local at = 0
	for _, id in ipairs(WheelData.DisplayOrder) do
		local reward = WheelData.ById[id]
		local span = WheelData.DisplayFloor + spare * reward.weight / WheelData.TotalWeight
		table.insert(out, { reward = reward, start = at, finish = at + span, mid = at + span / 2 })
		at += span
	end
	return out
end

-- landingAngle's rule on the drawn wheel: where `reward`'s drawn sector must
-- stop under the pointer, `within` (the server's own number) its arc.
function WheelData.displayLanding(reward: Reward, within: number): number
	for _, sector in ipairs(WheelData.displaySectors()) do
		if sector.reward == reward then
			local w = math.clamp(within, 0.1, 0.9)
			return sector.start + (sector.finish - sector.start) * w
		end
	end
	return 0
end

-- A pod prize's species with each one's exact odds (the prize's own share,
-- split evenly across its pool, exactly as the server picks), rarest first,
-- then by name. Empty for anything but a pod.
export type PoolOdds = { id: string, name: string, rarity: string, probability: number }

function WheelData.poolOdds(reward: Reward): { PoolOdds }
	local out: { PoolOdds } = {}
	local pool = WheelData.Pools[reward.pool or ""]
	if reward.kind ~= "pod" or not pool then
		return out
	end
	local each = reward.weight / WheelData.TotalWeight / #pool
	for _, id in ipairs(pool) do
		local species = SeedData.Get(id)
		table.insert(out, {
			id = id,
			name = if species then species.Name else id,
			rarity = if species then species.Rarity else "Common",
			probability = each,
		})
	end
	table.sort(out, function(a, b)
		local ta, tb = GameConfig.RarityTier[a.rarity] or 0, GameConfig.RarityTier[b.rarity] or 0
		if ta ~= tb then
			return ta > tb
		end
		return a.name < b.name
	end)
	return out
end

--==============================================================================
-- WORDS
--==============================================================================
local function commas(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end
WheelData.commas = commas

-- A probability as a percentage with enough places to be non-zero and exact to
-- four places past its first significant digit (Roblox's rule for long
-- decimals), trailing zeros trimmed: 22%, 0.4%, 0.12%, 0.625%.
function WheelData.percent(p: number): string
	local pct = p * 100
	if pct <= 0 then
		return "0%"
	end
	local first = math.floor(math.log10(pct))
	local places = math.clamp(4 - first, 0, 8)
	local s = string.format("%." .. places .. "f", pct)
	if s:find("%.") then
		s = s:gsub("0+$", ""):gsub("%.$", "")
	end
	return s .. "%"
end

--==============================================================================
-- THE PRIZES SCALE WITH THE PLAYER (2026-10-08; Michael's suggestion, the
-- owner's approval -- the seconds are proposals the owner may change)
--
-- A cash or Speed prize pays the larger of its fixed amount -- now its FLOOR --
-- and `scale.seconds` of the player's garden income (EconomyService.RateFor:
-- what the garden really pays them, the x2 pass included) or of their own
-- mill's tier rate (GameConfig.Mill, no boosts), rounded DOWN to two
-- significant figures. Two figures because that is what the wheel's words show
-- exactly -- "$1.2M" is 1,200,000 to the dollar -- so what is shown is what is
-- paid. The server works these out from its own numbers only, when it
-- publishes them (Attributes.Amounts), and the roll pays the published number.
--==============================================================================
function WheelData.niceDown(n: number): number
	if n ~= n or n <= 0 then
		return 0
	end
	local unit = 1
	while n >= 100 * unit do
		unit *= 10
	end
	return math.floor(n / unit) * unit
end

function WheelData.amountFor(reward: Reward, incomePerSecond: number?, millRate: number?): number
	local floor = reward.amount or 0
	local scale = reward.scale
	if not scale then
		return floor
	end
	local rate = tonumber(if scale.per == "mill" then millRate else incomePerSecond) or 0
	if rate ~= rate or rate <= 0 or rate == math.huge then
		return floor
	end
	return math.max(floor, WheelData.niceDown(rate * scale.seconds))
end

-- Every scaled prize's amount for one player, by prize id.
function WheelData.amountsFor(incomePerSecond: number?, millRate: number?): { [string]: number }
	local out: { [string]: number } = {}
	for _, reward in ipairs(WheelData.Rewards) do
		if reward.scale then
			out[reward.id] = WheelData.amountFor(reward, incomePerSecond, millRate)
		end
	end
	return out
end

-- An amount in the wheel's words: commas under 100K ("5,000", "73,000"), the
-- game's compact form from there ("1.2M") -- both exact for a two-figure amount.
function WheelData.amountWords(amount: number): string
	if amount < 100000 then
		return commas(amount)
	end
	return GameConfig.compact(amount)
end

-- `reward`'s three sets of words at `amount`: the sector's, the Reward info
-- list's, and the full title. A prize with no amount keeps its own words, and
-- at its floor a prize says exactly what it always said.
function WheelData.wordsFor(reward: Reward, amount: number?): (string, string, string)
	if amount == nil or not (reward.kind == "cash" or reward.kind == "speed") then
		return reward.label, reward.short, reward.title
	end
	local n = WheelData.amountWords(amount)
	if reward.kind == "cash" then
		if reward.id == "cash_jackpot" then
			return "$" .. n, "$" .. n .. " Jackpot", "$" .. n .. " Cash Jackpot"
		end
		return "$" .. n, "$" .. n, "$" .. n .. " Cash"
	end
	return "+" .. n .. " SPEED", "+" .. n .. " Speed", "+" .. n .. " Speed"
end

-- The published amounts as one attribute string ("cash_small=5000;...") and
-- back. Anything malformed reads as missing, and the client then shows floors.
function WheelData.encodeAmounts(amounts: { [string]: number }): string
	local ids: { string } = {}
	for id in pairs(amounts) do
		table.insert(ids, id)
	end
	table.sort(ids)
	local parts: { string } = {}
	for _, id in ipairs(ids) do
		table.insert(parts, string.format("%s=%d", id, math.floor(amounts[id])))
	end
	return table.concat(parts, ";")
end

function WheelData.decodeAmounts(text: any): { [string]: number }
	local out: { [string]: number } = {}
	if type(text) ~= "string" then
		return out
	end
	for id, value in string.gmatch(text, "([%w_]+)=(%d+)") do
		local reward = WheelData.ById[id]
		local n = tonumber(value)
		if reward and reward.scale and n then
			out[id] = n
		end
	end
	return out
end

--==============================================================================
-- EVERY FINAL OUTCOME, WITH ITS EXACT ODDS
--
-- What the Details view lists before a spin, down to the species and size of a
-- pod: a pod prize splits evenly across its pool. For a player who owns the
-- trail already, the trail's line says what it pays instead (the cash jackpot)
-- at the trail's own share. The shares add to exactly 1.
--==============================================================================
export type Outcome = {
	-- Group heading (the prize) and the final line under it.
	prize: string,
	line: string,
	probability: number,
	note: string?,
}

function WheelData.outcomes(ownsTrail: boolean, ownsEveryInvite: boolean?, amounts: { [string]: number }?): { Outcome }
	local out: { Outcome } = {}
	for _, reward in ipairs(WheelData.Rewards) do
		local share = reward.weight / WheelData.TotalWeight
		local _, _, title = WheelData.wordsFor(reward, if amounts then amounts[reward.id] else nil)
		if reward.kind == "pod" then
			local pool = WheelData.Pools[reward.pool or ""] or {}
			local tier = SeedData.Tier(reward.tier)
			for _, id in ipairs(pool) do
				local species = SeedData.Get(id)
				table.insert(out, {
					prize = reward.title,
					line = string.format("%s pod: %s species, %s size", species and species.Name or id,
						species and species.Rarity or "?", tier.name),
					probability = share / #pool,
				})
			end
		elseif (reward.kind == "trail" and ownsTrail) or (reward.kind == "invite" and ownsEveryInvite) then
			local swap = WheelData.ById[reward.swap or ""]
			local swapTitle = "cash"
			if swap then
				local _, _, t = WheelData.wordsFor(swap, if amounts then amounts[swap.id] else nil)
				swapTitle = t
			end
			table.insert(out, {
				prize = reward.title,
				line = if reward.kind == "trail"
					then string.format("You own the %s, so this pays %s instead", reward.title, swapTitle)
					else string.format("You own every invite plant, so this pays %s instead", swapTitle),
				probability = share,
				note = "replacement",
			})
		elseif reward.kind == "invite" then
			table.insert(out, { prize = reward.title, line = "The next invite plant you don't own yet",
				probability = share })
		else
			table.insert(out, { prize = title, line = title, probability = share })
		end
	end
	return out
end

return WheelData
