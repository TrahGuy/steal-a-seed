--!strict
-- Steal a Seed :: WheelService
--
-- THE OBBY REWARD WHEEL, ON THE SERVER (2026-09-27). How many spins a player
-- holds and where each came from, what a spin wins, and whether that prize has
-- been paid -- decided, recorded and delivered here and nowhere else. The
-- numbers are WheelData's; WheelUI only shows what this decided; WheelModel is
-- the wheel standing by Marigold.
--
--==============================================================================
-- EARNING: FIVE PER WINDOW, FROM THE OBBY
--
-- ObbyService calls AwardCompletion exactly once per paid run, where it used
-- to pay the run's Speed. Inside one synchronous step -- no yield, so no other
-- request can see half of it:
--
--   * a completion id already on the profile (WheelRuns) earns nothing again;
--   * a window that has run its 24 hours is closed;
--   * while the open window has earned fewer than Daily.Limit, this completion
--     earns ONE spin instead of the Speed (opening a window if none is open);
--   * otherwise it pays the run's Speed, exactly as the obby always has.
--
-- So a spin and the Speed are never both paid, a completion is never counted
-- twice, and a completion landing on the second a window closes is simply the
-- first of the next one. The window runs on os.time() -- the server's clock --
-- whether or not the player is online; rejoining or changing servers changes
-- nothing. Spending a spin never gives the allowance back, and a bought spin
-- never touches it.
--
--==============================================================================
-- SPINNING: RECORDED AND SAVED BEFORE ANYTHING IS SAID
--
--   1. refuse what is not allowed: no profile, a profile that cannot be saved,
--      no spin of the kind asked for, a spin already in flight for this player,
--      a bought spin without the paid-random-item permission;
--   2. roll the prize on this server's own Random -- a pod's species too;
--   3. take the spin and write the prize to WheelPending, together;
--   4. SAVE, and wait for it; if it did not land, put both back exactly and
--      say THAT (never a success nobody saved);
--   5. deliver: pay the prize and strike it from WheelPending in the same
--      synchronous step, then tell the client what it won.
--
-- A crash between 4 and 5 leaves the prize on the saved profile, and the next
-- join delivers it: never lost, never twice. The client's animation starts only
-- from the answer, so closing the panel, skipping the spin or leaving mid-spin
-- changes nothing. A pod the bag has no room for stays owed (WheelPending) and
-- is handed over the moment there is space -- never discarded.
--
-- NOTHING FROM THE CLIENT PICKS ANYTHING. A spin request carries one word --
-- which balance to spend -- and the server decides the rest.
--
--==============================================================================
-- PAID SPINS: WheelData.Paid.Enabled (2026-09-29; switched on 2026-10-01)
--
-- A bought spin is a PAID RANDOM ITEM, so three things are decided here, on the
-- server, and every one of them fails CLOSED:
--
--   WHO MAY   PolicyService said, of this player, ArePaidRandomItemsRestricted
--             == false. An error, a missing field, no answer yet: "may not".
--   BUYING    the client sends the product's KEY and nothing else; this opens
--             the purchase prompt, and only for a player who may, whose save
--             is loaded and can be written, and whose balance has room. The
--             prompt grants NOTHING, open or closed or finished: spins come
--             from StoreService's receipt, through GrantBought, which asks the
--             same questions again -- a receipt can arrive with no prompt
--             behind it (bought outside the game, or re-delivered on a join).
--             Refused there, the receipt is not acknowledged and Roblox hands
--             the Robux back when it stops retrying.
--   SPENDING  only by the player's yes to a question that names it, earned
--             spins first, and never for a player who may not.
--
-- The free, earned path never reads any of this.
--==============================================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
-- The invite prize's plant (2026-10-08).
local SeedData = require(Shared:WaitForChild("SeedData"))
-- The belt's golden-ticket window (TREADMILL FUN, 2026-10-08).
local BeltCatch = require(Shared:WaitForChild("BeltCatch"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local BonusChestService = require(script.Parent:WaitForChild("BonusChestService"))
local Metrics = require(script.Parent:WaitForChild("Metrics"))
local WheelModel = require(script.Parent:WaitForChild("WheelModel"))
-- For its reveal hook only (the hatch bonus). No cycle: PlantService never
-- requires this service.
local PlantService = require(script.Parent:WaitForChild("PlantService"))

local WheelService = {}
-- After the profiles (20), the bag, the faucets and the chest (58). Nothing
-- here needs another service to have started; ObbyService and StoreService
-- call in only when a run or a receipt arrives.
WheelService.Priority = 62

local A = WheelData.Attributes
local ACT = WheelData.Actions
local DAY = WheelData.Daily
local TRAIL = WheelData.Trail.Id

type Profile = PlayerDataService.Profile
type Prize = { Id: string, Rolled: string, Prize: string, Species: string, Source: string, At: number }

local busy: { [Player]: boolean } = {}
-- PolicyService's answer per player: true only when it said paid random items
-- are allowed. Missing (not asked yet) and false read the same.
local paidOk: { [Player]: boolean } = {}
-- PolicyService ANSWERED for this player (either way). Missing: it has not, or
-- every try failed -- the one case worth asking again (ensurePolicy).
local policyKnown: { [Player]: boolean } = {}
-- os.clock() of each player's last purchase prompt (Paid.PromptCooldown).
local prompted: { [Player]: number } = {}
local serviceConnections: { RBXScriptConnection } = {}
local channel: RemoteEvent? = nil
local running = false
local generation = 0
local rng = Random.new()
-- THE PRIZES SCALE WITH THE PLAYER (2026-10-08): each player's cash and Speed
-- amounts as last published (Attributes.Amounts) -- what the next spin pays.
local published: { [Player]: { [string]: number } } = {}
-- os.clock() of each player's last WheelOpen, so a client cannot make the
-- server work the amounts out every frame.
local openedAt: { [Player]: number } = {}
-- A grant into the Bag, never into the hands (InviteService's NO_EQUIP).
local NO_EQUIP = -1

local function log(message: string)
	print("[Seed/WheelService] " .. message)
end

--==============================================================================
-- THE CLOCK, AND THE STUDIO-ONLY TEST SEAMS
--
-- os.time() everywhere. A Studio harness may stand a clock in (useClock) to
-- walk a window past its 24 hours, and may force the next spin's prize
-- (DebugForce) to see all twelve on purpose. Both refuse outside Studio, and
-- neither has a remote: no player can reach either.
--==============================================================================
local clockFn: () -> number = os.time
local forced: { [Player]: { prize: string, species: string? } } = {}
-- Where an answer goes instead of the remote, while a Studio spec listens.
local replyFn: ((Player, { [string]: any }) -> ())? = nil
-- PlantService.OnRevealed's unsubscribe, for the hatch bonus; dropped by Init.
local unhookReveal: (() -> ())? = nil
-- What opens a purchase prompt: Roblox's own, or a Studio spec's recorder.
local promptFn: ((Player, number) -> ())? = nil

local function now(): number
	return math.floor(clockFn())
end

function WheelService.useClock(fn: (() -> number)?): boolean
	if not RunService:IsStudio() then
		return false
	end
	clockFn = fn or os.time
	return true
end

function WheelService.DebugForce(player: Player, prizeId: string, species: string?): boolean
	if not RunService:IsStudio() or WheelData.ById[prizeId] == nil then
		return false
	end
	forced[player] = { prize = prizeId, species = species }
	return true
end

-- WheelSpec hears the answers here rather than over the remote. Studio only.
function WheelService.useReply(fn: ((Player, { [string]: any }) -> ())?): boolean
	if not RunService:IsStudio() then
		return false
	end
	replyFn = fn
	return true
end

-- HatchBonusSpec hears the hatch bonus's message here instead. Studio only.
local bonusFn: ((Player, { [string]: any }) -> ())? = nil
function WheelService.useBonusReply(fn: ((Player, { [string]: any }) -> ())?): boolean
	if not RunService:IsStudio() then
		return false
	end
	bonusFn = fn
	return true
end

-- A spec records the purchase prompts here instead of opening one. Studio only.
function WheelService.usePrompt(fn: ((Player, number) -> ())?): boolean
	if not RunService:IsStudio() then
		return false
	end
	promptFn = fn
	return true
end

--==============================================================================
-- WHAT THE CLIENT SEES: attributes on the player, written only when they change
--==============================================================================
local function put(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function productLive(): boolean
	return WheelData.paidLive()
end

-- This player may buy and spend bought spins: PolicyService said so, of them,
-- and paid spins are switched on. Anything less is "may not".
local function paidAllowed(player: Player): boolean
	return paidOk[player] == true and productLive()
end

local function windowOpen(profile: Profile, at: number): boolean
	return profile.WheelDayAt > 0 and at < profile.WheelDayAt + DAY.WindowSeconds
end

--==============================================================================
-- SPIN TICKETS (2026-10-01, the owner's brief; GameConfig.Community)
--
-- The EARNED balance, shown in the hotbar as ONE stacked Tool -- "Spin Ticket",
-- TicketCount = WheelEarned. A view of the balance, never a balance of its own:
-- earning, spending and saving all stay on WheelEarned, so a ticket cannot be
-- spent twice, and one is used only when roll() takes an earned spin. It is
-- not a plant (no SpeciesId), so the saved record never counts it and it takes
-- no storage; and it is rebuilt from the balance whenever it is missing -- a
-- death empties the Backpack -- so rejoins and respawns never lose one. Kept
-- in step by publish(), which every change and the 3-second loop call.
--==============================================================================
local TICKET = "SpinTicket"
local TICKET_COUNT = "TicketCount"

local function ticketOf(player: Player): Tool?
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute(TICKET) == true then
					return child
				end
			end
		end
	end
	return nil
end

local function syncTicket(player: Player, count: number)
	local tool = ticketOf(player)
	if count < 1 then
		if tool then
			tool:Destroy()
		end
		return
	end
	if not tool then
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then
			return
		end
		local made = Instance.new("Tool")
		made.Name = GameConfig.Community.TicketName
		made.RequiresHandle = false
		made.CanBeDropped = false
		made.ToolTip = GameConfig.Community.TicketHint
		made:SetAttribute(TICKET, true)
		made.Parent = backpack
		tool = made
	end
	local t = tool :: Tool
	if t:GetAttribute(TICKET_COUNT) ~= count then
		t:SetAttribute(TICKET_COUNT, count)
	end
end
WheelService.TicketOf = ticketOf

local function publish(player: Player)
	if player.Parent ~= Players then
		return
	end
	local profile = PlayerDataService.Get(player)
	if not profile or not WheelData.Enabled then
		for _, name in pairs(A) do
			if name ~= A.Trail then
				put(player, name, nil)
			end
		end
		syncTicket(player, 0)
		return
	end
	syncTicket(player, profile.WheelEarned)
	local at = now()
	local open = windowOpen(profile, at)
	put(player, A.Earned, profile.WheelEarned)
	put(player, A.Bought, profile.WheelBought)
	put(player, A.DayCount, if open then profile.WheelDayCount else 0)
	put(player, A.DayEndsAt, if open then profile.WheelDayAt + DAY.WindowSeconds else nil)
	put(player, A.Pending, #profile.WheelPending)
	put(player, A.PaidAllowed, if paidAllowed(player) then true else nil)
	put(player, A.TrailOwned, if profile.Cosmetics[TRAIL] then true else nil)
	put(player, A.Trail, if profile.EquippedTrail ~= "" then profile.EquippedTrail else nil)
end
WheelService.Publish = publish

--==============================================================================
-- THE PRIZES SCALE WITH THE PLAYER (WheelData.amountFor, 2026-10-08)
--
-- From the server's own numbers only: the garden's income (EconomyService.
-- RateFor, as it pays) and the mill tier's rate (GameConfig.Mill, no boosts).
-- Published when the profile is ready, when the panel opens (WheelOpen) and
-- after every spin; the roll pays the published amount, so the words the wheel
-- showed are the amount paid.
--==============================================================================
local function millRateOf(profile: Profile): number
	local tiers = GameConfig.Mill.Tiers
	local tier = tiers[math.clamp(math.floor(tonumber((profile :: any).MillTier) or 1), 1, #tiers)]
	return if tier then tier.speed else 0
end

local function publishAmounts(player: Player): { [string]: number }
	local profile = PlayerDataService.Get(player)
	if not profile or not WheelData.Enabled then
		return {}
	end
	local amounts = WheelData.amountsFor(EconomyService.RateFor(player), millRateOf(profile))
	published[player] = amounts
	put(player, A.Amounts, WheelData.encodeAmounts(amounts))
	return amounts
end
WheelService.PublishAmounts = publishAmounts

-- The invite plants this player has ever been given, as a set.
local function invitesOwned(profile: Profile): { [string]: boolean }
	local owned: { [string]: boolean } = {}
	for _, id in ipairs((profile :: any).InviteOwned or {}) do
		owned[id] = true
	end
	return owned
end

local function reply(player: Player, payload: { [string]: any })
	local hook = replyFn
	if hook then
		hook(player, payload)
		return
	end
	local remote = channel
	if remote and player.Parent == Players then
		remote:FireClient(player, ACT.Result, payload)
	end
end

--==============================================================================
-- PAID RANDOM ITEMS: WHAT PolicyService SAYS ABOUT THIS PLAYER
--
-- Asked on every join. Anything but a clear "not restricted" -- an error, a
-- missing field, a Studio that cannot answer -- leaves paid spins off for them:
-- no way to buy is shown, no prompt is opened, no bought spin is granted or
-- spent. Returns whether PolicyService ANSWERED (either way); a call that threw
-- is the one case asked again, a few times at the join (watch) and once more
-- when a receipt arrives for a player it has never answered for (GrantBought).
--
-- ONLY AN ANSWER REPLACES AN ANSWER. Two calls can be in the air for one player
-- -- the join's, and a receipt's -- and come back in either order. A call that
-- failed says nothing about the player, so it leaves standing what PolicyService
-- last really said of them: a late failure would otherwise shut a player out of
-- spins they had just been allowed to buy. With no answer at all it stays closed.
--==============================================================================
local POLICY_RETRY_SECONDS = { 5, 20, 60 }

local function checkPolicy(player: Player): boolean
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if player.Parent ~= Players then
		return false
	end
	if ok and type(info) == "table" then
		paidOk[player] = (info :: any).ArePaidRandomItemsRestricted == false
		policyKnown[player] = true
	elseif not policyKnown[player] then
		paidOk[player] = nil
	end
	publish(player)
	return policyKnown[player] == true
end

-- For a receipt: the answer already had, or one more ask if there is none.
local function ensurePolicy(player: Player): boolean
	if not policyKnown[player] then
		checkPolicy(player)
	end
	return paidAllowed(player)
end

--==============================================================================
-- DELIVERY: pay one owed prize, synchronously
--
-- Returns whether it landed. Everything called here writes the profile without
-- yielding (AddCash, AddSpeed, SetChest, GivePod's count and row, the cosmetic set),
-- and the caller strikes the row in the same step, so no save can ever catch a
-- prize both paid and still owed.
--==============================================================================
local function deliverOne(player: Player, profile: Profile, row: Prize): boolean
	local prize = WheelData.ById[row.Prize]
	if not prize then
		return false
	end
	-- A scaled amount as it was rolled; a row from before pays the floor.
	if prize.kind == "cash" then
		return EconomyService.PayReward(player, row.Amount or prize.amount or 0, "the reward wheel")
	elseif prize.kind == "speed" then
		return TreadmillService.PayReward(player, row.Amount or prize.amount or 0, "the reward wheel")
	elseif prize.kind == "invite" then
		-- The plant rolled, unless an invite milestone gave it meanwhile: then the
		-- next one not owned. Every one given meanwhile: the prize's own swap,
		-- at this player's amount now -- what the odds list says it pays. Handed
		-- over as an invite gives it -- the Bag's room counted and the Held row
		-- written, or nothing (owed, tried again).
		local owned = invitesOwned(profile)
		local form = if row.Species ~= "" and not owned[row.Species] then row.Species
			else WheelData.nextInvite(owned)
		if not form then
			local swap = WheelData.ById[prize.swap or ""]
			if not swap then
				return false
			end
			local amount = WheelData.amountFor(swap, EconomyService.RateFor(player), millRateOf(profile))
			if swap.kind == "speed" then
				return TreadmillService.PayReward(player, amount, "the reward wheel")
			end
			return EconomyService.PayReward(player, amount, "the reward wheel")
		end
		local species = SeedData.Get(form)
		if not species then
			return false
		end
		local given = CarryService.GiveHatched(player, species, SeedData.InviteTier, NO_EQUIP, nil, true)
		if given then
			table.insert((profile :: any).InviteOwned, form)
			PlayerDataService.PublishInvites(player)
		end
		return given
	elseif prize.kind == "boost" then
		return BonusChestService.GrantBoost(player, prize.boost or "")
	elseif prize.kind == "trail" then
		-- Winning it puts it on; the player can take it off (TrailEquip).
		profile.Cosmetics[TRAIL] = true
		if profile.EquippedTrail == "" then
			profile.EquippedTrail = TRAIL
		end
		return true
	elseif prize.kind == "pod" then
		-- Only into a bag that is really there and has room: a Tool past the
		-- saved cap, or handed to a Backpack between bodies, would be lost.
		--
		-- THE ROOM IS CarryService's COUNT (2026-09-30), which keeps a place for
		-- a pod being carried home. Counted here as `#profile.Held`, a prize paid
		-- into that place left the carried pod nowhere to bank. The owner's
		-- decision: the wheel waits its turn -- the prize stays owed, and the
		-- next pass pays it once there is room.
		if not CarryService.IsHeldRestored(player) then
			return false
		end
		-- The POD room since 2026-10-09: pods have their own (Save.MaxPods).
		local room, _, known = CarryService.PodRoom(player)
		if not known or room < 1 then
			return false
		end
		return (CarryService.GivePod(player, row.Species, prize.tier or 1))
	end
	return false
end

-- Every owed prize that can be paid now. Returns how many landed and how many
-- are still owed.
local function deliverPending(player: Player): (number, number)
	local profile = PlayerDataService.Get(player)
	if not profile then
		return 0, 0
	end
	local landed = 0
	local index = 1
	while index <= #profile.WheelPending do
		local row = profile.WheelPending[index]
		local ok = false
		PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
			if deliverOne(player, p, row) then
				table.remove(p.WheelPending, index)
				ok = true
				return true
			end
			return false
		end)
		if ok then
			landed += 1
			local prize = WheelData.ById[row.Prize]
			-- In the words of the amount paid (THE PRIZES SCALE WITH THE PLAYER).
			local paid = if prize then select(3, WheelData.wordsFor(prize, row.Amount)) else row.Prize
			log(string.format("%s was paid %s (spin %s, %s).", player.Name, paid, row.Id, row.Source))
		else
			index += 1
		end
	end
	return landed, #profile.WheelPending
end

--==============================================================================
-- A SPIN
--==============================================================================
local function refuse(player: Player, reason: string)
	reply(player, { ok = false, reason = reason })
end

-- Steps 2 to 5 of a spin, under the caller's lock.
local function roll(player: Player, profile: Profile, source: string)
	-- 2. The roll.
	local force = forced[player]
	forced[player] = nil
	local rolled = if force then WheelData.ById[force.prize]
		else WheelData.prizeAt(rng:NextInteger(1, WheelData.TotalWeight))
	local nextInvite = WheelData.nextInvite(invitesOwned(profile))
	local prize, swapped = WheelData.resolve(rolled, profile.Cosmetics[TRAIL] == true, nextInvite == nil)
	local species = ""
	if prize.kind == "pod" then
		local pool = WheelData.Pools[prize.pool or ""] or {}
		species = pool[rng:NextInteger(1, #pool)]
		if force and force.species and table.find(pool, force.species) then
			species = force.species
		end
	elseif prize.kind == "invite" then
		species = nextInvite or ""
	end
	-- What the wheel showed this player, as last published (THE PRIZES SCALE
	-- WITH THE PLAYER); worked out now if nothing was published yet.
	local amount: number? = nil
	if prize.scale then
		local amounts = published[player] or publishAmounts(player)
		amount = amounts[prize.id] or WheelData.amountFor(prize, EconomyService.RateFor(player), millRateOf(profile))
	end
	local within = rng:NextNumber()

	-- 3. Take the spin and record the prize, together.
	local id = ""
	PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
		p.WheelSeq += 1
		id = string.format("%d-%d-%d", player.UserId, now(), p.WheelSeq)
		if source == "bought" then
			p.WheelBought -= 1
		else
			p.WheelEarned -= 1
		end
		table.insert(p.WheelPending, {
			Id = id,
			Rolled = rolled.id,
			Prize = prize.id,
			Species = species,
			Source = source,
			At = now(),
			Amount = amount,
		})
		return true
	end)

	-- 4. Saved, or it did not happen.
	local saved = PlayerDataService.Save(player)
	if not saved then
		PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
			for index, row in ipairs(p.WheelPending) do
				if row.Id == id then
					table.remove(p.WheelPending, index)
					if source == "bought" then
						p.WheelBought += 1
					else
						p.WheelEarned += 1
					end
					return true
				end
			end
			return false
		end)
		publish(player)
		warn(string.format("[Seed/WheelService] %s's spin did not save; nothing was taken or won.", player.Name))
		return refuse(player, "SAVE_FAILED")
	end

	-- 5. Pay it, then say so.
	deliverPending(player)
	local still = false
	for _, row in ipairs(profile.WheelPending) do
		if row.Id == id then
			still = true
		end
	end
	publish(player)
	-- The next spin's amounts: a garden that grew since the panel opened, or a
	-- Speed prize that changed nothing, alike.
	publishAmounts(player)
	Metrics.wheelSpun(player, prize.id, source)
	-- The prize in the words of its amount (THE PRIZES SCALE WITH THE PLAYER).
	local paidTitle = select(3, WheelData.wordsFor(prize, amount))
	log(string.format("%s spent a%s spin: %s%s.", player.Name, if source == "bought" then " BOUGHT" else "n earned",
		if swapped then rolled.title .. " -> " .. paidTitle else paidTitle, if still then " (owed: no room yet)" else ""))
	reply(player, {
		ok = true,
		id = id,
		rolled = rolled.id,
		prize = prize.id,
		swapped = swapped,
		within = within,
		source = source,
		owed = still,
		-- What was paid: a scaled amount, or the invite plant given.
		amount = amount,
		species = if prize.kind == "invite" then species else nil,
	})
	-- The delivery's own save; the prize is safe on the profile either way.
	task.spawn(PlayerDataService.Save, player)
end

local function spin(player: Player, want: any)
	if not WheelData.Enabled then
		return refuse(player, "DISABLED")
	end
	if busy[player] then
		return refuse(player, "BUSY")
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return refuse(player, "NOT_READY")
	end
	if not PlayerDataService.IsPersistent(player) then
		return refuse(player, "NOT_SAVED")
	end
	local source: string
	if want == "bought" then
		if not paidAllowed(player) then
			return refuse(player, "PAID_UNAVAILABLE")
		end
		if profile.WheelBought < 1 then
			return refuse(player, "NO_SPINS")
		end
		source = "bought"
	else
		if profile.WheelEarned < 1 then
			-- NEVER A SILENT SWITCH: a player with only bought spins is asked,
			-- and spends one only by saying "bought".
			return refuse(player, if profile.WheelBought > 0 and paidAllowed(player)
				then "CONFIRM_BOUGHT" else "NO_SPINS")
		end
		source = "earned"
	end
	if #profile.WheelPending >= WheelData.MaxPending then
		return refuse(player, "PENDING_FULL")
	end

	-- Whatever happens inside, the lock comes off: an error must not leave this
	-- player unable to spin for the rest of the session. An error AFTER the save
	-- leaves the prize owed on the profile, which the loop in Start pays -- so
	-- the words say exactly that, never "nothing was used".
	busy[player] = true
	local ok, err = pcall(roll, player, profile, source)
	busy[player] = nil
	if not ok then
		warn(string.format("[Seed/WheelService] %s's spin stopped with an error: %s", player.Name, tostring(err)))
		publish(player)
		refuse(player, "FAILED")
	end
end

--==============================================================================
-- OWED PRIZES, ON REQUEST (the wheel's CLAIM) and on a timer
--==============================================================================
-- deliverPending under this player's lock, which comes off even if a delivery
-- throws (the rows it did not strike stay owed for the next attempt).
local function deliverLocked(player: Player, profile: Profile): (number, number)
	busy[player] = true
	local ok, landed, left = pcall(deliverPending, player)
	busy[player] = nil
	if not ok then
		warn(string.format("[Seed/WheelService] delivering %s's owed prizes stopped with an error: %s",
			player.Name, tostring(landed)))
		return 0, #profile.WheelPending
	end
	return landed :: number, left :: number
end

local function claim(player: Player)
	if busy[player] then
		return
	end
	local profile = PlayerDataService.Get(player)
	if not profile or #profile.WheelPending == 0 then
		return
	end
	local landed, left = deliverLocked(player, profile)
	publish(player)
	reply(player, { ok = landed > 0, claim = true, landed = landed, left = left,
		reason = if landed == 0 then "NO_ROOM" else nil })
	if landed > 0 then
		task.spawn(PlayerDataService.Save, player)
	end
end

--==============================================================================
-- THE TRAIL: on or off, only if owned
--==============================================================================
local function equip(player: Player, want: any)
	local wear = want == true
	PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
		if wear then
			if not p.Cosmetics[TRAIL] or p.EquippedTrail == TRAIL then
				return false
			end
			p.EquippedTrail = TRAIL
		else
			if p.EquippedTrail == "" then
				return false
			end
			p.EquippedTrail = ""
		end
		return true
	end)
	publish(player)
end

--==============================================================================
-- BUYING (2026-09-29): THE SERVER OPENS THE PROMPT, AND GRANTS NOTHING HERE
--
-- The client names one of WheelData.Products by its key. Every refusal leaves
-- everything as it was and says why. An allowed request opens Roblox's own
-- purchase prompt, which quotes and charges this player's real price.
--
-- WHAT THE PLAYER DOES WITH THE PROMPT IS NOT HEARD HERE AT ALL. A prompt that
-- closed, or finished, is not a purchase: only StoreService's receipt is, and
-- only it calls GrantBought. Nothing in this file listens for a prompt ending.
--==============================================================================
-- The key is said back only when it is one of ours: whatever else a client
-- sent -- a megabyte of it, if it likes -- is not sent back to it.
local function refuseBuy(player: Player, reason: string, key: any)
	local known = type(key) == "string" and #key <= 32 and WheelData.ProductByKey[key] ~= nil
	reply(player, { ok = false, buy = true, reason = reason, key = if known then key else nil })
end

local function buy(player: Player, key: any)
	if not WheelData.Enabled then
		return refuseBuy(player, "DISABLED", key)
	end
	local product = if type(key) == "string" and #key <= 32 then WheelData.ProductByKey[key] else nil
	if not product then
		return refuseBuy(player, "UNKNOWN_PRODUCT", key)
	end
	-- Switched off, restricted, or never answered: one refusal, and no prompt.
	if not paidAllowed(player) then
		return refuseBuy(player, "PAID_UNAVAILABLE", key)
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return refuseBuy(player, "NOT_READY", key)
	end
	-- A profile that cannot be saved cannot keep what is bought into it.
	if not PlayerDataService.IsPersistent(player) then
		return refuseBuy(player, "NOT_SAVED", key)
	end
	if profile.WheelBought + product.spins > WheelData.MaxBoughtHeld then
		return refuseBuy(player, "BALANCE_FULL", key)
	end
	local at = os.clock()
	local last = prompted[player]
	if last and at - last < WheelData.Paid.PromptCooldown then
		return refuseBuy(player, "PROMPT_BUSY", key)
	end
	prompted[player] = at
	local open = promptFn
	local ok, err = pcall(function()
		if open then
			open(player, product.productId)
		else
			MarketplaceService:PromptProductPurchase(player, product.productId)
		end
	end)
	if not ok then
		warn(string.format("[Seed/WheelService] the purchase prompt for %q did not open: %s", product.key,
			tostring(err)))
		return refuseBuy(player, "PROMPT_FAILED", key)
	end
	log(string.format("%s was shown the purchase prompt for %q (product %d).", player.Name, product.key,
		product.productId))
	reply(player, { ok = true, buy = true, key = product.key })
end

--==============================================================================
-- EARNING, CALLED BY ObbyService ONCE PER PAID RUN
--
-- `runId` is the run's own id; `speed` is what the run pays in Speed when it
-- does not earn a spin. Returns "spin" with the window's new count, "speed"
-- with the Speed paid, or "none" for a completion already credited.
--==============================================================================
function WheelService.AwardCompletion(player: Player, runId: string, speed: number): (string, number)
	local profile = PlayerDataService.Get(player)
	local spinnable = WheelData.Enabled and profile ~= nil and PlayerDataService.IsPersistent(player)
	local outcome, count = "speed", 0
	if profile and spinnable then
		PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
			for _, done in ipairs(p.WheelRuns) do
				if done == runId then
					outcome = "none"
					return false
				end
			end
			local at = now()
			if not windowOpen(p, at) then
				p.WheelDayAt, p.WheelDayCount = 0, 0
			end
			if p.WheelDayCount < DAY.Limit and p.WheelEarned < WheelData.MaxEarnedHeld then
				if p.WheelDayAt == 0 then
					p.WheelDayAt = at
				end
				p.WheelDayCount += 1
				p.WheelEarned += 1
				outcome, count = "spin", p.WheelDayCount
			end
			table.insert(p.WheelRuns, runId)
			while #p.WheelRuns > WheelData.RememberRuns do
				table.remove(p.WheelRuns, 1)
			end
			return true
		end)
	end
	if outcome == "speed" then
		if speed > 0 and TreadmillService.PayReward(player, speed, "the Floating Garden") then
			count = speed
		else
			count = 0
		end
	elseif outcome == "spin" then
		Metrics.wheelSpinEarned(player, count)
		task.spawn(PlayerDataService.Save, player)
	end
	publish(player)
	return outcome, count
end

--==============================================================================
-- THE HATCH BONUS (2026-10-01, the owner's brief; GameConfig.HatchBonus)
--
-- One free spin per player, once, for a successful hatch: PlantService's own
-- reveal (OnRevealed, hooked in Start), which comes from a hatch that has
-- happened and never from a refused one. `firstHatch` is that hatch's answer to
-- "had this record ever hatched?", taken before the hatch was recorded. It
-- picks the label and nothing else: a player who had hatched before gets the
-- same one spin, as a welcome back.
--
-- ONE STEP OR NOTHING, inside UpdateWheel with no yield:
--   * already claimed: nothing, ever again;
--   * the earned balance full: nothing YET. It is capped on load, so a spin
--     past the cap would vanish on the next join; the next hatch with room
--     claims it;
--   * otherwise the spin on the EARNED balance (the obby's daily allowance --
--     WheelDayAt, WheelDayCount -- is not read or written), the marker, and the
--     like reminder's "pending", together, so a save has all three or none.
-- Two hatches in one moment are two calls in turn, and the second finds the
-- marker. A profile that is not saving claims nothing, rather than a spin that
-- vanishes with the server.
--
-- Returns the label given ("first" or "welcome"), or nil.
--==============================================================================
function WheelService.GrantHatchBonus(player: Player, firstHatch: boolean, revealAt: number?): string?
	if not WheelData.Enabled or player.Parent ~= Players or not PlayerDataService.IsPersistent(player) then
		return nil
	end
	local label = if firstHatch == true then "first" else "welcome"
	local granted = PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
		if p.HatchBonusClaimed or p.WheelEarned >= WheelData.MaxEarnedHeld then
			return false
		end
		p.WheelEarned += 1
		p.HatchBonusClaimed = true
		if p.LikeReminder ~= "pending" and p.LikeReminder ~= "shown" then
			p.LikeReminder = "pending"
		end
		return true
	end)
	if not granted then
		return nil
	end
	log(string.format("%s earned the hatch bonus (%s): one free spin.", player.Name, label))
	task.spawn(PlayerDataService.Save, player)
	publish(player)
	PlayerDataService.PublishLikeReminder(player)
	local payload = { label = label, revealAt = if type(revealAt) == "number" then revealAt else nil }
	local hook = bonusFn
	if hook then
		hook(player, payload)
	else
		local remote = channel
		if remote then
			remote:FireClient(player, ACT.HatchBonus, payload)
		end
	end
	return label
end

--==============================================================================
-- THE COMMUNITY CHEST'S SPINS (2026-10-01, the owner's brief; GameConfig.Community)
--
-- Called by CommunityService once it has confirmed membership itself. Under
-- this player's wheel lock, so no spin can run while the claim is in flight:
--   * already claimed: "claimed", nothing changes;
--   * no room on the earned balance for all of them (it is capped on load):
--     "full", nothing changes;
--   * otherwise WheelEarned += Spins and CommunityClaimed in ONE step, then a
--     save. A save that fails takes both back ("save") -- never a flag without
--     its spins or spins without their flag -- and the player may try again.
-- Answers "granted", "claimed", "full", "save", "busy" or "unavailable".
--==============================================================================
function WheelService.GrantCommunity(player: Player): string
	local n = GameConfig.Community.Spins
	if not WheelData.Enabled or player.Parent ~= Players or not PlayerDataService.IsPersistent(player) then
		return "unavailable"
	end
	if busy[player] then
		return "busy"
	end
	local profile = PlayerDataService.Get(player)
	if not profile then
		return "unavailable"
	end
	if profile.CommunityClaimed then
		return "claimed"
	end
	busy[player] = true
	local outcome = "full"
	local ok, err = pcall(function()
		local granted = PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
			if p.CommunityClaimed or p.WheelEarned + n > WheelData.MaxEarnedHeld then
				return false
			end
			p.WheelEarned += n
			p.CommunityClaimed = true
			return true
		end)
		if not granted then
			outcome = if profile.CommunityClaimed then "claimed" else "full"
			return
		end
		if PlayerDataService.Save(player) then
			outcome = "granted"
			log(string.format("%s claimed the community chest: %d free spins.", player.Name, n))
		else
			PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
				p.WheelEarned = math.max(0, p.WheelEarned - n)
				p.CommunityClaimed = false
				return true
			end)
			outcome = "save"
			warn(string.format("[Seed/WheelService] %s's community spins did not save; taken back.", player.Name))
		end
	end)
	busy[player] = nil
	if not ok then
		warn(string.format("[Seed/WheelService] %s's community claim stopped: %s", player.Name, tostring(err)))
		outcome = "unavailable"
	end
	publish(player)
	return outcome
end

--==============================================================================
-- A GLOBAL MINI EVENT'S TICKET (2026-10-03, TICKET DISCO; MiniEventService)
--
-- Called by MiniEventService once IT has decided a collection is real: the
-- ticket exists and has landed, nobody took it first, and the body stood on
-- it. ONE free spin on the EARNED balance -- the hotbar's Spin Ticket, spent
-- at the wheel like any other -- AND the claim, in one synchronous step:
--   * the claim is the profile's own (EventClaims, by the GLOBAL event's id):
--     at `cap` already, nothing ("CAP"). The profile is session-locked to one
--     server at a time and saved with the spin, so leaving, dying, rejoining or
--     moving to another server meets the same count -- per event, not per
--     server, and never a temporary counter somewhere else;
--   * not the obby's allowance: WheelDayAt and WheelDayCount are neither read
--     nor written; no once-per-profile marker (HatchBonusClaimed,
--     CommunityClaimed) either -- every event may give its tickets again;
--   * a balance already at MaxEarnedHeld takes nothing ("FULL"): it is capped
--     on load, so a spin past it would vanish on the next join;
--   * a profile that is not saving takes nothing ("NOT_SAVED"), rather than a
--     spin that vanishes with the server.
-- The claims list stays bounded: the newest ClaimsKept events, oldest dropped.
-- Accepted, it is the hatch bonus's convention: changed in memory and marked
-- dirty (UpdateWheel), then saved -- one coalesced save per player however
-- quickly the tickets come. A save that does not land leaves the profile
-- dirty: the autosave and the leave save keep trying, and the write warns;
-- the claim and its spin are in the same table, so they land or are lost
-- together, never one without the other. Nothing is ever granted twice: the
-- caller grants once per ticket, and the ticket is gone in the same step.
-- Answers true and the new count, or false, why ("DISABLED", "NOT_SAVED",
-- "BAD_EVENT", "CAP", "FULL") and the count as it stands.
--==============================================================================
local saveQueued: { [Player]: boolean } = {}
local saveAgain: { [Player]: boolean } = {}

local function saveSoon(player: Player)
	if saveQueued[player] then
		saveAgain[player] = true
		return
	end
	saveQueued[player] = true
	task.spawn(function()
		repeat
			saveAgain[player] = nil
			if player.Parent ~= Players then
				break
			end
			if not PlayerDataService.Save(player) then
				warn(string.format("[Seed/WheelService] %s's event spin save did not land yet; the profile stays "
					.. "dirty and the autosave keeps trying.", player.Name))
			end
		until not saveAgain[player]
		saveQueued[player] = nil
		saveAgain[player] = nil
	end)
end

local function claimRow(p: Profile, eventId: string): { Id: string, Count: number, At: number }?
	for _, row in ipairs((p :: any).EventClaims or {}) do
		if row.Id == eventId then
			return row
		end
	end
	return nil
end

-- How many tickets this player has collected in that global event (0 if none),
-- or nil while their profile is not loaded.
function WheelService.EventClaimCount(player: Player, eventId: string): number?
	local profile = PlayerDataService.Get(player)
	if not profile then
		return nil
	end
	local row = claimRow(profile, eventId)
	return if row then row.Count else 0
end

function WheelService.GrantEventSpin(player: Player, eventId: string, cap: number, source: string):
	(boolean, string?, number)
	if not WheelData.Enabled then
		return false, "DISABLED", 0
	end
	if type(eventId) ~= "string" or #eventId == 0 or #eventId > 40 or type(cap) ~= "number" or cap < 1 then
		return false, "BAD_EVENT", 0
	end
	if player.Parent ~= Players or not PlayerDataService.IsPersistent(player) then
		return false, "NOT_SAVED", WheelService.EventClaimCount(player, eventId) or 0
	end
	local why: string? = nil
	local count = 0
	local granted = PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
		local claims = (p :: any).EventClaims
		if type(claims) ~= "table" then
			claims = {}
			;(p :: any).EventClaims = claims
		end
		local row = claimRow(p, eventId)
		count = if row then row.Count else 0
		if count >= cap then
			why = "CAP"
			return false
		end
		if p.WheelEarned >= WheelData.MaxEarnedHeld then
			why = "FULL"
			return false
		end
		if not row then
			row = { Id = eventId, Count = 0, At = 0 }
			table.insert(claims, row)
			while #claims > GameConfig.MiniEvent.Tickets.ClaimsKept do
				table.remove(claims, 1)
			end
		end
		local claim = row :: { Id: string, Count: number, At: number }
		claim.Count += 1
		claim.At = os.time()
		count = claim.Count
		p.WheelEarned += 1
		return true
	end)
	if not granted then
		return false, why or "NOT_SAVED", count
	end
	log(string.format("%s collected a free spin (%s): %d/%d this global event.", player.Name, tostring(source),
		count, cap))
	publish(player)
	saveSoon(player)
	return true, nil, count
end

--==============================================================================
-- TREADMILL FUN'S FREE SPINS (2026-10-08; TreadmillFunService)
--
-- MILESTONE SPINS: up to `n` onto the EARNED balance, as many as it has room
-- for under MaxEarnedHeld (capped on load, so past it a spin would vanish).
-- Answers how many landed; the caller keeps the rest owed and pays them when
-- there is room (MilestoneSpinsOwed). Not the obby's allowance -- WheelDayAt and
-- WheelDayCount are neither read nor written.
--
-- THE BELT'S GOLDEN TICKET: its OWN rolling 24 h window (BeltTicketAt /
-- BeltTicketCount, BeltCatch's limit), opened by the first ticket caught and
-- running whether or not they play -- WheelData.Daily's pattern, never its
-- fields. In one UpdateWheel step: a closed window reopens, a full one says
-- "CAP", a full balance says "FULL", otherwise the count and the spin together.
-- `BeltTicketOpen` asks the same question without granting, so the server only
-- ever SENDS a ticket a player could take.
-- Both: a profile that is not saving takes nothing, rather than a spin that
-- vanishes with the server; accepted spins are published and saved soon, as
-- GrantEventSpin's are.
--==============================================================================
function WheelService.GrantMilestoneSpins(player: Player, n: number, why: string): number
	if not WheelData.Enabled or player.Parent ~= Players or not PlayerDataService.IsPersistent(player) then
		return 0
	end
	if type(n) ~= "number" or n < 1 or n ~= math.floor(n) then
		return 0
	end
	local landed = 0
	PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
		landed = math.clamp(WheelData.MaxEarnedHeld - p.WheelEarned, 0, n)
		if landed <= 0 then
			return false
		end
		p.WheelEarned += landed
		return true
	end)
	if landed > 0 then
		log(string.format("%s earned %d free spin(s) for %s.", player.Name, landed, tostring(why)))
		publish(player)
		saveSoon(player)
	end
	return landed
end

-- A returning friend's free spin (InviteService.CreditReturning, 2026-10-08):
-- one earned spin onto the balance, as a milestone's.
function WheelService.GrantInviteSpin(player: Player): number
	return WheelService.GrantMilestoneSpins(player, 1, "a friend who came back through their invite")
end

local function beltWindow(p: Profile, at: number): (number, number)
	local q = p :: any
	local opened = tonumber(q.BeltTicketAt) or 0
	if opened <= 0 or at >= opened + BeltCatch.TicketWindowSeconds then
		return 0, 0
	end
	return opened, tonumber(q.BeltTicketCount) or 0
end

function WheelService.BeltTicketOpen(player: Player): boolean
	local profile = PlayerDataService.Get(player)
	if not WheelData.Enabled or not profile or not PlayerDataService.IsPersistent(player) then
		return false
	end
	local _, count = beltWindow(profile, now())
	return count < BeltCatch.TicketsPerWindow and profile.WheelEarned < WheelData.MaxEarnedHeld
end

function WheelService.GrantBeltTicket(player: Player): (boolean, string?)
	if not WheelData.Enabled then
		return false, "DISABLED"
	end
	if player.Parent ~= Players or not PlayerDataService.IsPersistent(player) then
		return false, "NOT_SAVED"
	end
	local why: string? = nil
	local granted = PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
		local at = now()
		local opened, count = beltWindow(p, at)
		if count >= BeltCatch.TicketsPerWindow then
			why = "CAP"
			return false
		end
		if p.WheelEarned >= WheelData.MaxEarnedHeld then
			why = "FULL"
			return false
		end
		local q = p :: any
		q.BeltTicketAt = if opened > 0 then opened else at
		q.BeltTicketCount = count + 1
		p.WheelEarned += 1
		return true
	end)
	if not granted then
		return false, why or "NOT_SAVED"
	end
	log(string.format("%s caught a golden ticket on their belt: one free spin.", player.Name))
	publish(player)
	saveSoon(player)
	return true, nil
end

--==============================================================================
-- BOUGHT SPINS, CALLED BY StoreService's RECEIPT HANDLER AND BY NOTHING ELSE
--
-- Returns whether they landed; StoreService writes the ledger and saves, and
-- acknowledges the receipt only after that. False means "not now": the receipt
-- is not acknowledged, Roblox delivers it again, and the ledger -- which has no
-- entry for it -- lets that later delivery pay. Nothing is granted twice and
-- nothing paid for is dropped.
--
-- THE SAME QUESTIONS AS THE PROMPT, ASKED AGAIN, because a receipt can arrive
-- with no prompt of ours behind it: bought outside the game, re-delivered on a
-- rejoin, or prompted by a client that was tampered with.
--
--   * paid spins switched off: nothing (StoreService does not even index them);
--   * a player PolicyService restricts, or will not answer for -- asked once
--     more here if it never has: nothing. They may not hold a paid random
--     item, so the receipt stays unacknowledged and the Robux go back;
--   * a profile that is not saving: nothing, rather than spins that vanish
--     with the server;
--   * a balance with no room for the whole pack: nothing, never part of it.
--
-- The daily earning allowance is not read or written: a bought spin is not an
-- earned one.
--==============================================================================
function WheelService.GrantBought(player: Player, quantity: number): boolean
	local n = math.floor(tonumber(quantity) or 0)
	if n <= 0 or n ~= n then
		return false
	end
	if not productLive() then
		return false
	end
	if not ensurePolicy(player) then
		warn(string.format("[Seed/WheelService] %s: a spin purchase arrived, and this player may not hold paid "
			.. "random items (or PolicyService would not answer). Not granted; the receipt stays open.", player.Name))
		return false
	end
	if not PlayerDataService.IsPersistent(player) then
		return false
	end
	local landed = PlayerDataService.UpdateWheel(player, function(p: Profile): boolean
		if p.WheelBought + n > WheelData.MaxBoughtHeld then
			return false
		end
		p.WheelBought += n
		return true
	end)
	publish(player)
	if landed then
		log(string.format("%s was granted %d bought spin(s).", player.Name, n))
	end
	return landed
end

--==============================================================================
-- FOR THE SPEC AND THE CONSOLE
--==============================================================================
function WheelService.Snapshot(player: Player): string
	local p = PlayerDataService.Get(player)
	if not p then
		return "no profile"
	end
	return string.format("earned %d, bought %d, window %s/%d, pending %d, trail %s%s",
		p.WheelEarned, p.WheelBought, if windowOpen(p, now()) then tostring(p.WheelDayCount) else "closed",
		DAY.Limit, #p.WheelPending, if p.Cosmetics[TRAIL] then "owned" else "not owned",
		if p.EquippedTrail ~= "" then ", worn" else "")
end

WheelService.Spin = spin
WheelService.Claim = claim
WheelService.Equip = equip
WheelService.Buy = buy
WheelService.DeliverPending = deliverPending
WheelService.PaidAllowed = paidAllowed
-- Asked by `watch` on every join; exported so WheelSpec can drive it against a
-- stand-in PolicyService. It only reads the policy and publishes.
WheelService.CheckPolicy = checkPolicy

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function watch(player: Player, gen: number)
	-- A profile first; then the attributes and the policy answer. Anything a
	-- crash or a full bag left owed is paid by the loop in Start, once the bag
	-- is really back.
	local t = os.clock()
	while running and gen == generation and player.Parent == Players
		and not PlayerDataService.IsReady(player) and os.clock() - t < 120 do
		task.wait(0.25)
	end
	if not (running and gen == generation and player.Parent == Players) then
		return
	end
	publish(player)
	publishAmounts(player)
	-- A new body comes with an empty Backpack: its Spin Ticket goes straight back
	-- (SPIN TICKETS) rather than at the loop's next pass.
	table.insert(serviceConnections, player.CharacterAdded:Connect(function()
		task.defer(publish, player)
	end))
	-- The policy answer, off this thread: asked now, and again a few times only
	-- if PolicyService would not answer at all. Until it does, "may not".
	task.spawn(function()
		if checkPolicy(player) then
			return
		end
		for _, pause in ipairs(POLICY_RETRY_SECONDS) do
			task.wait(pause)
			if not (running and gen == generation and player.Parent == Players) or policyKnown[player] then
				return
			end
			if checkPolicy(player) then
				return
			end
		end
	end)
end

function WheelService.Init()
	running = false
	generation += 1
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(busy)
	table.clear(forced)
	table.clear(paidOk)
	table.clear(policyKnown)
	table.clear(prompted)
	table.clear(saveQueued)
	table.clear(saveAgain)
	channel = nil
	local unhook = unhookReveal
	unhookReveal = nil
	if unhook then
		unhook()
	end
end

function WheelService.Start()
	if not WheelData.Enabled then
		log("Switched OFF (WheelData.Enabled = false): no wheel, and the obby pays Speed as before.")
		return
	end
	-- Found, never waited for: nothing in a service's Start may yield (the boot
	-- that lost a garden, KB/HANDOFF.md). The remotes exist before any Start.
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil
	if not channel then
		warn("[Seed/WheelService] No GameEvent remote at Start; the wheel cannot be spun this session.")
	end

	local model = WheelModel.build()

	-- THE HATCH BONUS: every successful hatch, as it happens (GrantHatchBonus).
	unhookReveal = PlantService.OnRevealed(function(reveal: any)
		local owner = reveal and reveal.owner
		if typeof(owner) == "Instance" and owner:IsA("Player") then
			WheelService.GrantHatchBonus(owner, reveal.firstHatch == true, reveal.revealAt)
		end
	end)

	running = true
	local gen = generation
	local remote = channel
	if remote then
		table.insert(serviceConnections, remote.OnServerEvent:Connect(function(player: Player, action: any, payload: any)
			if action == ACT.Spin then
				spin(player, payload)
			elseif action == ACT.Claim then
				claim(player)
			elseif action == ACT.Equip then
				equip(player, payload)
			elseif action == ACT.Buy then
				buy(player, payload)
			elseif action == ACT.Open then
				-- The panel opened: this player's amounts again, at most twice a second.
				local last = openedAt[player]
				if not last or os.clock() - last >= 0.5 then
					openedAt[player] = os.clock()
					publishAmounts(player)
				end
			end
		end))
	end
	table.insert(serviceConnections, Players.PlayerAdded:Connect(function(player: Player)
		watch(player, gen)
	end))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		busy[player] = nil
		paidOk[player] = nil
		policyKnown[player] = nil
		prompted[player] = nil
		forced[player] = nil
		saveAgain[player] = nil
		published[player] = nil
		openedAt[player] = nil
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(watch, player, gen)
	end

	-- Every few seconds: pay what is owed wherever it can be paid now (a crash
	-- recovered, or bag space freed), and roll a closed window off the HUD.
	task.spawn(function()
		while running and gen == generation do
			task.wait(3)
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = PlayerDataService.Get(player)
				if profile and not busy[player] then
					if #profile.WheelPending > 0 then
						local landed = deliverLocked(player, profile)
						if landed > 0 then
							task.spawn(PlayerDataService.Save, player)
						end
					end
					publish(player)
				end
			end
		end
	end)

	local at = if model then model:GetPivot().Position else Vector3.zero
	log(string.format("Ready. The wheel stands at (%.0f, %.0f, %.0f); %d prizes, %d earned spins per %dh window%s.",
		at.X, at.Y, at.Z, #WheelData.Rewards, DAY.Limit, DAY.WindowSeconds // 3600,
		if productLive() then string.format("; paid spins ON (%d products)", #WheelData.Products)
			else "; paid spins OFF (WheelData.Paid.Enabled is false)"))
end

return WheelService
