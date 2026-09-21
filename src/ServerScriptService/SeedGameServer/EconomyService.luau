--!strict
-- Steal a Seed :: EconomyService
--
-- THE FAUCET. Rule 6: cash mints here and nowhere else.
--
--==============================================================================
-- WHY THAT RULE IS WORTH THE INCONVENIENCE
--
-- PlayerDataService.AddCash is the MECHANISM -- it clamps and marks dirty. It
-- does not decide what earns. If five services each paid out "just this one
-- case", the answer to "why does this player have eight million" would live in
-- five files, and balancing the game would mean reading all of them.
--
-- One file. Anything that wants to pay a player asks this service to do it.
--
-- It said "one loop, one call" until the stall started buying bags. There are
-- FOUR ways to earn now -- the payout loop below, the stall (SellHeld and
-- SellOne), PayReward for the Index's one-time Biome Harvest, and ClaimOffline
-- for a garden that earned while its owner was away -- and they are all in this
-- file for exactly the reason the rule exists: "why does this player have eight
-- million" still has one file to read, and the answers sit a few dozen lines
-- apart.
--
--==============================================================================
-- WHAT EARNS: GROWN PLANTS, AND ONLY GROWN ONES
--
-- Straight off SeedData.IncomePerSecond, which is the size tier scaled by the
-- species' rarity and by how deep the biome it came from is. This file does not
-- know those factors and must not learn them: one calculation, in SeedData,
-- shared with every readout that shows the player a number.
--
-- A pod in the ground pays nothing and a sprout pays nothing -- the wait IS the
-- cost, and paying during it would turn planting into a deposit rather than a
-- bet.
--
-- That also makes the plot readable as a balance sheet: what you can SEE
-- standing up is what is paying you.
--
--==============================================================================
-- PAID FOR TIME ACTUALLY ELAPSED, NOT PER TICK
--
-- rate * dt, where dt is measured rather than assumed to be TICK. A server that
-- hitches for three seconds still owes three seconds of income, and a loop that
-- pays a flat amount per iteration quietly underpays exactly when the server is
-- struggling.
--
-- The clock starts when the player is first seen paying, not when they joined,
-- so nobody is paid for time before their plants existed.
--
--==============================================================================
-- OFFLINE, AS A CLAIM RATHER THAN A PAYOUT
--
-- Growth uses an absolute os.time() and keeps running while you are away. Cash
-- now does too, but never silently: it was deferred until it had the three
-- things an offline faucet needs, and it has them. A CLAIM FLOW -- the absence
-- is credited to the profile at load (OfflineEarnings) and paid here only when
-- the player presses CLAIM. A CAP -- SeedData.Offline, at most eight hours at
-- half speed, and only after twenty minutes away. An ANTI-ABUSE STORY -- the
-- server's own LastSeen and os.time(), no client input, one take per claim.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlantService = require(script.Parent:WaitForChild("PlantService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local PassService = require(script.Parent:WaitForChild("PassService"))

local EconomyService = {}
-- After PlantService (50): this reads what PlantService is growing.
EconomyService.Priority = 55

local TICK = 1

-- player -> os.clock() when they were last paid.
local lastPaid: { [Player]: number } = {}
-- player -> cash minted this session, for Snapshot. Diagnostics only; the
-- profile is the truth.
local minted: { [Player]: number } = {}

local running = false
local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/EconomyService] " .. message)
end

--==============================================================================
-- THE PASS, APPLIED IN ONE PLACE
--
-- Income online and income claimed after an absence are the same income, so the
-- x2 pass reaches both through this and nothing else. BalanceSpec counts it.
--==============================================================================
local function withPass(player: Player, amount: number): number
	return amount * PassService.CashMultiplier(player)
end

--==============================================================================
-- WHAT ONE PLAYER IS OWED PER SECOND
--
-- Public because the HUD will want to show it, and because a rate anybody can
-- ask for is a rate nobody has to re-derive.
--==============================================================================
function EconomyService.RateFor(player: Player): number
	local plot = PlotService.PlotOf(player)
	if not plot then
		return 0
	end
	-- Belt and braces on "only the plot's owner". PlotOf already answers that,
	-- but the two are separate tables and a lease that changed hands between
	-- them is exactly the sort of thing that pays the wrong person.
	if PlotService.OwnerOf(plot) ~= player then
		return 0
	end
	local rate = 0
	-- The INSTANCE tier, not the species sheet -- a faucet that ignored the roll
	-- would pay every Nubkin the same whatever came out of the pod. The SPECIES
	-- goes with it because rarity and biome are the other two factors, and
	-- GrownIn has always returned both.
	--
	-- Rounded per PLANT, inside IncomePerSecond, and summed after: a bed of
	-- twelve pays the sum of twelve whole numbers, which is what the garden
	-- panel adds up and shows.
	for _, grown in ipairs(PlantService.GrownIn(plot)) do
		rate += SeedData.IncomePerSecond(grown.species, grown.tier)
	end

	--==========================================================================
	-- THE x2 MONEY PASS MULTIPLIES HERE -- AND IN THE OFFLINE CLAIM, WHICH IS THE
	-- SAME INCOME -- THROUGH withPass, AND NOWHERE ELSE
	--
	-- This is the last line of the FAUCET, so a pass applied at this point
	-- reaches exactly one kind of income: cash grown by plants, whether the
	-- owner was here for it or claims it after an absence. It does not
	-- reach SellHeld forty lines below -- selling a bag at the stall is a sale,
	-- not production -- nor PayReward, whose one-off Biome Harvest is already
	-- sized in BiomeData; and it cannot reach the other five positive AddCash
	-- calls in the game, none of which come through here:
	--
	--   StoreService       a Robux cash pack, already paid for at its price
	--   PlotUpgradeService a refund when an upgrade fails to apply
	--   TreadmillService   the same, on a mill upgrade
	--   WeaponShopService  the same, on a weapon
	--   DebugService       an owner-only grant, which is not income
	--
	-- Doubling a REFUND is the one that would actually hurt: it would pay a
	-- player more to fail a purchase than the purchase cost them.
	--
	-- Applied to the rate rather than inside the payout loop so the number this
	-- function answers with is the number that gets banked. RateFor is what the
	-- Snapshot prints, and a diagnostic that disagrees with the payout is worse
	-- than no diagnostic.
	--
	-- Each term is already whole -- IncomePerSecond rounds per plant -- so an
	-- integer multiplier keeps the sum whole.
	--==========================================================================
	return withPass(player, rate)
end

--==============================================================================
-- THE TICK
--==============================================================================
local function payEveryone()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		-- Only while they are in the server. GetPlayers is that check; there is
		-- no queue of absent players to pay.
		if PlayerDataService.IsReady(player) then
			local since = lastPaid[player]
			lastPaid[player] = now
			if since then
				local dt = now - since
				-- A player who has just arrived, or whose clock was reset,
				-- gets no lump sum.
				if dt > 0 and dt < 30 then
					local rate = EconomyService.RateFor(player)
					if rate > 0 then
						local amount = rate * dt
						-- THE ONLY POSITIVE AddCash IN THE GAME.
						if PlayerDataService.AddCash(player, amount) then
							minted[player] = (minted[player] or 0) + amount
							PlayerDataService.RecordTutorial(player, "earn")
						end
					end
				end
			end
		else
			-- Not ready yet: do not start their clock, or the seconds spent
			-- loading a profile become seconds of income the moment it lands.
			lastPaid[player] = nil
		end
	end
end

local function forget(player: Player)
	lastPaid[player] = nil
	minted[player] = nil
end

--==============================================================================
-- LIFECYCLE
--==============================================================================

--==============================================================================
-- THE STALL BUYS THE BAG
--
-- The second way to earn, and the only one that is not a rate: a one-off for
-- everything the player is holding. Priced by SeedData.SellPrice, which is
-- thirty seconds of what the same plant would pay standing in the ground -- see
-- the banner there for why selling is deliberately the worse deal.
--
-- WHAT IS SOLD, AND WHAT IS NOT
--
-- Tools, in the Backpack and in the player's hands, because equipping MOVES a
-- Tool between the two and a sell that missed the one they were holding would
-- be the most obvious possible bug.
--
-- NOT the pod welded to them by a raid. That one has not been banked yet -- it
-- is still loot being carried home, CarryService owns it, and selling it out of
-- their arms at the stall would be taking something they had not put down.
--
-- COUNTED AND PAID ONCE. The tools are destroyed first and the total paid
-- after, so a failure between the two cannot pay twice; AddCash clamps, and a
-- refusal there leaves the bag already gone, which is why the amount is
-- computed from what was actually removed rather than from what was found.
--
-- The save follows for free: CarryService watches both containers for
-- ChildRemoved and re-snapshots the hotbar at the end of the frame.
--==============================================================================
function EconomyService.SellHeld(player: Player): (number, number)
	if player.Parent ~= Players then
		return 0, 0
	end

	local sold, total = 0, 0
	local function take(container: Instance?)
		if not container then
			return
		end
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") then
				local id = tool:GetAttribute("SpeciesId")
				local tier = tonumber(tool:GetAttribute(GameConfig.Attributes.CarryingKg))
				-- The species was already being looked up to validate the tool;
				-- it is now also what prices it, so a Mythic out of Starbloom
				-- sells for what it was worth standing up.
				local species = if type(id) == "string" then SeedData.Get(id) else nil
				if species and tier and tier >= 1 then
					total += SeedData.SellPrice(species, tier)
					sold += 1
					tool:Destroy()
				end
			end
		end
	end
	take(player:FindFirstChildOfClass("Backpack"))
	take(player.Character)
	CarryService.SyncHeldNow(player)

	if sold == 0 then
		return 0, 0
	end
	if total > 0 then
		PlayerDataService.AddCash(player, total)
	end
	log(string.format("%s sold %d item(s) at the stall for %s.",
		player.Name, sold, GameConfig.compact(total)))
	return sold, total
end

--==============================================================================
-- THE STALL BUYS ONE PLANT
--
-- The fourth way to earn, and the careful version of the second: the plant in
-- the player's HANDS, priced by the same SeedData.SellPrice and paid by the same
-- AddCash, so "why does this player have eight million" still has one file to
-- read. SellService owns the board, the prompt and the confirmation; this owns
-- what a plant is worth and the moment it stops being theirs.
--
-- STRICTER THAN SELL ALL, ON PURPOSE. SellHeld takes every Tool that names a
-- species, hatched or not, from both containers. This takes ONE Tool, and only:
--
--     held      in the Character, not the Backpack. Equipping MOVES a Tool, so
--               "in your hands" is a parent check and nothing looser.
--     grown     Hatched. An unhatched pod is a bet whose result the player has
--               not seen, and the stall does not buy bets one at a time.
--     a plant   SpeciesId names a species and the tier is real. A bat or a trap
--               has neither and is refused before a price is even asked.
--
-- The pod welded on from a raid is a Model, never a Tool, and CarryService puts
-- every plant Tool away while one is carried -- so a carrier holds nothing this
-- can price. IsCarrying is checked anyway: two rules that agree are cheaper
-- than one that is assumed.
--
-- QUOTE AND SALE ARE TWO CALLS. The quote decides nothing and touches nothing;
-- it is what the confirmation shows. The sale re-runs every check on the SAME
-- INSTANCE -- the one the quote was made for, never "whatever is in the hands
-- now" -- and if they still hold, destroys it, re-snapshots the bag and pays,
-- with no yield anywhere between the last check and the last write. A second
-- request for the same Tool, from a double tap or from SELL ALL landing first,
-- finds it already gone and is refused rather than paid.
--
-- THE PASS DOES NOT TOUCH THIS. SellPrice is thirty seconds of the BASE rate;
-- the x2 multiplier lives in RateFor, on income, and the quote never sees it.
--==============================================================================
export type OneQuote = {
	species: SeedData.Species,
	tier: number,
	price: number,
}

function EconomyService.QuoteOne(player: Player, tool: Instance?): (OneQuote?, string)
	if player.Parent ~= Players then
		return nil, "NO_PLAYER"
	end
	local character = player.Character
	if not character then
		return nil, "NO_CHARACTER"
	end
	if CarryService.IsCarrying(player) then
		return nil, "CARRYING"
	end
	if not (tool and tool:IsA("Tool")) then
		return nil, "NOTHING_HELD"
	end
	if tool.Parent ~= character then
		return nil, "NOT_HELD"
	end
	local id = tool:GetAttribute("SpeciesId")
	local species = if type(id) == "string" then SeedData.Get(id) else nil
	local tier = tonumber(tool:GetAttribute(GameConfig.Attributes.CarryingKg))
	if not (species and tier and tier >= 1) then
		return nil, "NOT_A_PLANT"
	end
	if tool:GetAttribute("Hatched") ~= true then
		return nil, "UNHATCHED"
	end
	local whole = math.floor(tier)
	return {
		species = species,
		tier = whole,
		price = SeedData.SellPrice(species, whole),
	}, ""
end

function EconomyService.SellOne(player: Player, tool: Instance?): (OneQuote?, string)
	local quote, reason = EconomyService.QuoteOne(player, tool)
	if not quote then
		return nil, reason
	end
	-- NO YIELD FROM HERE TO THE PAYMENT. Destroyed first, paid after -- the
	-- order SellHeld settled on, for the reason its banner gives.
	local held = tool :: Instance
	held:Destroy()
	CarryService.SyncHeldNow(player)
	PlayerDataService.AddCash(player, quote.price)
	log(string.format("%s sold one %s (tier %d) at the stall for %s.",
		player.Name, quote.species.Name, quote.tier, GameConfig.compact(quote.price)))
	return quote, ""
end

--==============================================================================
-- A ONE-OFF REWARD
--
-- The third way to earn, and in this file for the reason the other two are: the
-- Index's Biome Harvest pays through here, so a player's cash is still explained
-- by one file. The CALLER decides a reward is due and how much -- AlmanacService,
-- off the profile and BiomeData -- and this only pays it and says so in the log.
--==============================================================================
function EconomyService.PayReward(player: Player, amount: number, reason: string): boolean
	if player.Parent ~= Players or type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return false
	end
	if PlayerDataService.AddCash(player, amount) == nil then
		return false
	end
	minted[player] = (minted[player] or 0) + amount
	log(string.format("%s was paid %s for %s.", player.Name, GameConfig.compact(amount), reason))
	return true
end

--==============================================================================
-- THE OFFLINE CLAIM, PAID
--
-- The garden's time away was worked out when the profile loaded (see
-- OfflineEarnings) and is waiting on the profile as a claim. This takes it --
-- once: PlayerDataService zeroes it in the same resumption it reads it -- and
-- pays it through the same AddCash every other coin goes through, so the cash
-- cap applies. The x2 pass is applied HERE, at payment, as it is to income
-- online; a pass bought while the card is open counts.
--
-- Returns what was paid, or nil and why not.
--==============================================================================
function EconomyService.ClaimOffline(player: Player): (number?, string)
	if player.Parent ~= Players then
		return nil, "GONE"
	end
	if not PlayerDataService.IsReady(player) then
		return nil, "NOT_READY"
	end
	local cash, seconds = PlayerDataService.TakeOffline(player)
	if not cash then
		return nil, "NOTHING"
	end
	local paid = math.floor(withPass(player, cash))
	if PlayerDataService.AddCash(player, paid) == nil then
		return nil, "NOT_PAID"
	end
	minted[player] = (minted[player] or 0) + paid
	log(string.format("%s claimed %s of offline earnings (%.0f min credited).",
		player.Name, GameConfig.compact(paid), seconds / 60))
	return paid, "OK"
end

function EconomyService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(lastPaid)
	table.clear(minted)
end

function EconomyService.Start()
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(forget))
	--==========================================================================
	-- THE CLAIM VERB, ON THE REMOTE THE GAME ALREADY HAS
	--
	-- Carries nothing and needs nothing: what is owed is on the server's own
	-- copy of the profile. Anything else in the payload is ignored. The answer
	-- names the amount actually paid, pass included, so the card can show the
	-- number the wallet really moved by.
	--==========================================================================
	local OFFLINE = GameConfig.OfflineEarnings
	local remotes = ReplicatedStorage:WaitForChild("SeedGame"):FindFirstChild("Remotes")
	local channel = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if channel and channel:IsA("RemoteEvent") then
		local remote = channel :: RemoteEvent
		table.insert(serviceConnections, remote.OnServerEvent:Connect(
			function(player: Player, action: any)
				if action ~= OFFLINE.ClaimAction then
					return
				end
				local paid, reason = EconomyService.ClaimOffline(player)
				if player.Parent == Players then
					pcall(function()
						remote:FireClient(player, OFFLINE.ReplyAction, { paid = paid or 0, reason = reason })
					end)
				end
			end))
	else
		warn("[Seed/EconomyService] No GameEvent remote; offline earnings cannot be claimed.")
	end

	running = true
	task.spawn(function()
		while running do
			task.wait(TICK)
			-- pcall so one bad profile cannot stop the faucet for everybody.
			local ok, err = pcall(payEveryone)
			if not ok then
				warn("[Seed/EconomyService] pay tick failed: " .. tostring(err))
			end
		end
	end)

	log(string.format(
		"Ready. The only faucet: grown plants pay their size tier scaled by species "
		.. "rarity (%.2f-%.2fx) and biome depth (%.2f-%.2fx), ticking every %ds.",
		SeedData.RarityMultiplier.Common, SeedData.RarityMultiplier.Divine,
		SeedData.BiomeMultiplier.greenhollow, SeedData.BiomeMultiplier.starbloom, TICK))
end

--==============================================================================
-- DIAGNOSTICS
--==============================================================================
function EconomyService.Snapshot(): string
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		table.insert(rows, string.format("%s: %.0f/sec, %.0f cash (%.0f minted this session)",
			player.Name, EconomyService.RateFor(player),
			profile and profile.Cash or 0, minted[player] or 0))
	end
	table.sort(rows)
	return if #rows > 0 then table.concat(rows, " | ") else "nobody earning"
end

return EconomyService
