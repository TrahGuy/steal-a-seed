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
-- PAID SPINS: DISABLED
--
-- WheelBought exists and StoreService can fill it, but only once WheelData.
-- Product is configured and enabled, which it is not. Spending one also needs
-- PolicyService to say this player may use paid random items; a failed check
-- counts as "may not". The free, earned path never depends on either.
--==============================================================================

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local BonusChestService = require(script.Parent:WaitForChild("BonusChestService"))
local Metrics = require(script.Parent:WaitForChild("Metrics"))
local WheelModel = require(script.Parent:WaitForChild("WheelModel"))

local WheelService = {}
-- After the profiles (20), the bag, the faucets and the chest (58). Nothing
-- here needs another service to have started; ObbyService and StoreService
-- call in only when a run or a receipt arrives.
WheelService.Priority = 62

local A = WheelData.Attributes
local ACT = WheelData.Actions
local DAY = WheelData.Daily
local TRAIL = WheelData.Trail.Id
local MAX_HELD = GameConfig.Save.MaxHeld

type Profile = PlayerDataService.Profile
type Prize = { Id: string, Rolled: string, Prize: string, Species: string, Source: string, At: number }

local busy: { [Player]: boolean } = {}
-- PolicyService's answer per player: true only when it said paid random items
-- are allowed. Missing (not asked yet) and false read the same.
local paidOk: { [Player]: boolean } = {}
local serviceConnections: { RBXScriptConnection } = {}
local channel: RemoteEvent? = nil
local running = false
local generation = 0
local rng = Random.new()

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

--==============================================================================
-- WHAT THE CLIENT SEES: attributes on the player, written only when they change
--==============================================================================
local function put(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function productLive(): boolean
	local product = WheelData.Product
	return product.Enabled == true and product.ProductId > 0 and product.Quantity > 0
end

local function paidAllowed(player: Player): boolean
	return paidOk[player] == true and productLive()
end

local function windowOpen(profile: Profile, at: number): boolean
	return profile.WheelDayAt > 0 and at < profile.WheelDayAt + DAY.WindowSeconds
end

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
		return
	end
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
-- Asked once per join. Anything but a clear "not restricted" -- an error, a
-- missing field, a Studio that cannot answer -- leaves paid spins off for them.
--==============================================================================
local function checkPolicy(player: Player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if player.Parent ~= Players then
		return
	end
	paidOk[player] = ok and type(info) == "table" and (info :: any).ArePaidRandomItemsRestricted == false
	publish(player)
end

--==============================================================================
-- DELIVERY: pay one owed prize, synchronously
--
-- Returns whether it landed. Everything called here writes the profile without
-- yielding (AddCash, AddSpeed, SetChest, GivePod's restore, the cosmetic set),
-- and the caller strikes the row in the same step, so no save can ever catch a
-- prize both paid and still owed.
--==============================================================================
local function deliverOne(player: Player, profile: Profile, row: Prize): boolean
	local prize = WheelData.ById[row.Prize]
	if not prize then
		return false
	end
	if prize.kind == "cash" then
		return EconomyService.PayReward(player, prize.amount or 0, "the reward wheel")
	elseif prize.kind == "speed" then
		return TreadmillService.PayReward(player, prize.amount or 0, "the reward wheel")
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
		if not CarryService.IsHeldRestored(player) or #profile.Held >= MAX_HELD then
			return false
		end
		return CarryService.GivePod(player, row.Species, prize.tier or 1)
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
			log(string.format("%s was paid %s (spin %s, %s).", player.Name, prize and prize.title or row.Prize,
				row.Id, row.Source))
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
	local prize, swapped = WheelData.resolve(rolled, profile.Cosmetics[TRAIL] == true)
	local species = ""
	if prize.kind == "pod" then
		local pool = WheelData.Pools[prize.pool or ""] or {}
		species = pool[rng:NextInteger(1, #pool)]
		if force and force.species and table.find(pool, force.species) then
			species = force.species
		end
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
	Metrics.wheelSpun(player, prize.id, source)
	log(string.format("%s spent a%s spin: %s%s%s.", player.Name, if source == "bought" then " BOUGHT" else "n earned",
		rolled.title, if swapped then " -> " .. prize.title else "", if still then " (owed: no room yet)" else ""))
	reply(player, {
		ok = true,
		id = id,
		rolled = rolled.id,
		prize = prize.id,
		swapped = swapped,
		within = within,
		source = source,
		owed = still,
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
-- BOUGHT SPINS, CALLED BY StoreService's receipt handler (only once WheelData.
-- Product is live). Returns whether they landed; StoreService saves.
--==============================================================================
function WheelService.GrantBought(player: Player, quantity: number): boolean
	local n = math.floor(tonumber(quantity) or 0)
	if n <= 0 or n ~= n then
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
	task.spawn(checkPolicy, player)
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
	channel = nil
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
			end
		end))
	end
	table.insert(serviceConnections, Players.PlayerAdded:Connect(function(player: Player)
		watch(player, gen)
	end))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		busy[player] = nil
		paidOk[player] = nil
		forced[player] = nil
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
		if productLive() then "; the spin pack is LIVE" else "; paid spins OFF (no product configured)"))
end

return WheelService
