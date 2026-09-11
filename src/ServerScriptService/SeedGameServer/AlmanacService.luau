--!strict
-- Steal a Seed :: AlmanacService
--
-- THE BIOME HARVEST. Grow every species a biome has and the Index offers a
-- one-time bonus of cash and Speed. This is where that claim is settled.
--
--==============================================================================
-- THE CLIENT ASKS, THE SERVER DECIDES
--
-- Rule 3. The Index sends a biome id and nothing else: not an amount, and not a
-- claim that the shelf is full. Whether it is full is read off the profile this
-- server holds (AlmanacData.ClaimState), and the amounts come off BiomeData. A
-- client that fires the verb for a biome it has not finished gets "locked" back
-- and nothing moves.
--
--==============================================================================
-- RECORDED, THEN PAID
--
-- PlayerDataService.RecordMastery is set-once and returns false for a biome it
-- already holds, and the payment happens only on its true. Two requests cannot
-- both see "ready" and both pay: the first records, the second finds the
-- record. Nothing between the check and the payment yields, so nothing can land
-- in between.
--
-- The money goes through the two faucets that own it: cash through
-- EconomyService, Speed through TreadmillService, which also asks CarryService
-- to recompute WalkSpeed. This file decides a reward is due. It mints nothing.
--
--==============================================================================
-- ONE VERB ON GameEvent
--
-- The shared remote PlantAt, PickUp and the upgrades already ride, with a half
-- second cooldown per player so a held button cannot become a request storm.
-- The answer goes back on the same remote as (action, biomeId, ok, reason) so the
-- Index can drop its pending state; the new balance and the Mastery flag arrive
-- with the next profile packet, as everything else does.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local AlmanacData = require(Shared:WaitForChild("AlmanacData"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))

local AlmanacService = {}
-- After EconomyService (55) and TreadmillService (60), which do the paying.
AlmanacService.Priority = 70

local ACTION = GameConfig.Almanac.ClaimAction
local COOLDOWN = 0.5

local lastRequest: { [Player]: number } = {}
local serviceConnections: { RBXScriptConnection } = {}

local function log(message: string)
	print("[Seed/AlmanacService] " .. message)
end

--==============================================================================
-- SETTLE ONE CLAIM
--
-- Whether it paid, and a reason the Index can act on:
--
--   paid      recorded and paid
--   claimed   paid before
--   locked    the biome is not finished
--   unknown   not a biome id
--   loading   no profile yet
--   busy      inside the cooldown, and not read at all
--   gone      the player has left
--==============================================================================
function AlmanacService.Claim(player: Player, biomeId: any): (boolean, string)
	if player.Parent ~= Players then
		return false, "gone"
	end
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < COOLDOWN then
		return false, "busy"
	end
	lastRequest[player] = now

	local profile = PlayerDataService.Get(player)
	if not profile then
		return false, "loading"
	end
	local state = AlmanacData.ClaimState(profile.Almanac, profile.Mastery, biomeId)
	if state ~= "ready" then
		return false, state
	end
	-- "ready" is only ever the answer for a string that names a real biome.
	local id = biomeId :: string
	if not PlayerDataService.RecordMastery(player, id) then
		return false, "claimed"
	end

	local cash, speed = AlmanacData.Reward(id)
	local reason = BiomeData.ById[id].DisplayName .. " harvest"
	local paidCash = EconomyService.PayReward(player, cash, reason)
	local paidSpeed = TreadmillService.PayReward(player, speed, reason)
	if not (paidCash and paidSpeed) then
		-- Only reachable if a faucet refused a positive amount for a player who
		-- is here and has a profile, which neither does. Loud, because it would
		-- be a player who is owed something.
		warn(string.format("[Seed/AlmanacService] %s's %s was recorded but not fully paid "
			.. "(cash %s, speed %s).", player.Name, reason, tostring(paidCash), tostring(paidSpeed)))
	end
	log(string.format("%s claimed the %s: %s cash and %s Speed.",
		player.Name, reason, GameConfig.compact(cash), GameConfig.compact(speed)))
	return true, "paid"
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function AlmanacService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(lastRequest)
end

function AlmanacService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if not (found and found:IsA("RemoteEvent")) then
		warn("[Seed/AlmanacService] No GameEvent remote. Biome harvests cannot be claimed.")
		return
	end
	local channel = found :: RemoteEvent

	table.insert(serviceConnections, channel.OnServerEvent:Connect(
		function(player: Player, action: any, biomeId: any)
			if action ~= ACTION then
				return
			end
			local ok, reason = AlmanacService.Claim(player, biomeId)
			if player.Parent == Players then
				pcall(function()
					channel:FireClient(player, ACTION,
						if type(biomeId) == "string" then biomeId else nil, ok, reason)
				end)
			end
		end))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		lastRequest[player] = nil
	end))

	local road = AlmanacData.Biomes()
	local first, last = road[1], road[#road]
	local firstCash, firstSpeed = AlmanacData.Reward(first.Id)
	local lastCash, lastSpeed = AlmanacData.Reward(last.Id)
	log(string.format("Ready. A finished biome pays once: %s cash and %s Speed in %s, "
		.. "up to %s and %s in %s.",
		GameConfig.compact(firstCash), GameConfig.compact(firstSpeed), first.DisplayName,
		GameConfig.compact(lastCash), GameConfig.compact(lastSpeed), last.DisplayName))
end

return AlmanacService
