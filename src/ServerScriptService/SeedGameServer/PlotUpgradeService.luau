--!strict
--==============================================================================
-- Steal a Seed :: PlotUpgradeService
--
-- Buying the next plot level. One verb, one price, no arguments.
--
-- THE CLIENT SENDS A VERB AND NOTHING ELSE. Not a level, not a price, not a
-- plot id. Everything that decides the outcome is read on the server from the
-- sender -- which the engine stamps and the client cannot forge -- so the worst
-- a modified client can do is ask to buy the upgrade it was already entitled to
-- buy, as fast as it likes.
--
-- That is why there is no "level" parameter anywhere in this file. A client
-- that could name its target would buy Level 5 for the price of Level 2, and no
-- amount of range-checking the number afterwards recovers the fact that the
-- number should never have crossed the wire.
--
-- WHAT AN UPGRADE ACTUALLY IS, in order:
--
--   1. the profile's PlotTier goes up          (what persists)
--   2. the plot in the world is rebuilt deeper (what is seen)
--   3. the plants are rebased onto the new soil (PlantService, via PlotService)
--
-- Only step 1 survives a server restart, which is why it is first, and why a
-- failure at step 2 rolls step 1 back rather than leaving a profile claiming a
-- size the world never built.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local PlotUpgradeService = {}

-- After PlotService (10), PlayerDataService (20) and PlantService (50): this
-- reads profiles and drives plot rebuilds, so all three have to be up first.
PlotUpgradeService.Priority = 60

local ACTION = GameConfig.PlotUpgradeAction
local TIERS = GameConfig.PlotTiers

local serviceConnections: { RBXScriptConnection } = {}

--==============================================================================
-- ONE UPGRADE AT A TIME, PER PLAYER
--
-- The transaction below yields nowhere, so on today's code two clicks cannot
-- interleave. That is a property of the current implementation and not of the
-- design: rebuilding ~200 parts is exactly the kind of work that acquires a
-- wait() the first time somebody wants it animated, and on that day a
-- double-click would charge twice and upgrade once.
--
-- The guard costs one table write and removes the whole class in advance.
--==============================================================================
local busy: { [Player]: boolean } = {}

local function log(message: string)
	print("[Seed/PlotUpgradeService] " .. message)
end

--==============================================================================
-- WHAT THIS PLAYER CAN BUY NEXT
--
-- The profile is the authority on what level a player owns -- not the plot's
-- attributes. The plot is a slot on this server that gets rebuilt, released and
-- handed to somebody else; the profile is the thing that follows the player. If
-- the two ever disagree, the profile is right and the plot is stale.
--
-- Shared with the Shop so the panel and the purchase cannot price differently.
--==============================================================================
export type Step = {
	kind: "next" | "max",
	level: number,
	cost: number,
}

function PlotUpgradeService.LevelOf(player: Player): number
	local profile = PlayerDataService.Get(player)
	local n = tonumber(profile and profile.PlotTier)
	if n == nil or n ~= n then
		return GameConfig.StartingPlotTier
	end
	return math.clamp(math.floor(n), 1, #TIERS)
end

function PlotUpgradeService.NextStepFor(player: Player): Step
	local level = PlotUpgradeService.LevelOf(player)
	if level >= #TIERS then
		return { kind = "max", level = level, cost = 0 }
	end
	local nextLevel = level + 1
	return { kind = "next", level = nextLevel, cost = TIERS[nextLevel].cost }
end

--==============================================================================
-- BUY IT
--
-- Returns false for every refusal and says nothing about which one. A refusal
-- is not information the client is owed: the panel already knows the price and
-- the balance, so the only way to reach a "no" is to have sent something the
-- panel would not have sent.
--==============================================================================
function PlotUpgradeService.TryUpgrade(player: Player): boolean
	if busy[player] then
		return false
	end
	if not PlayerDataService.IsReady(player) then
		return false
	end

	local plot = PlotService.PlotOf(player)
	if not plot or PlotService.OwnerOf(plot) ~= player then
		-- Queued for a plot, or between plots. Nothing to grow.
		return false
	end

	local step = PlotUpgradeService.NextStepFor(player)
	if step.kind == "max" then
		return false
	end

	local profile = PlayerDataService.Get(player)
	if not profile or profile.Cash < step.cost then
		return false
	end

	local before = PlotUpgradeService.LevelOf(player)
	busy[player] = true

	--==========================================================================
	-- PAY, RECORD, BUILD -- AND UNWIND IN THE OPPOSITE ORDER
	--
	-- Charging first is deliberate. The alternative -- build, then charge --
	-- hands out a free upgrade every time the charge fails, and the charge is
	-- the step most likely to fail, because it is the one another service can
	-- race (a payout landing in the same frame).
	--
	-- Every later failure therefore has to give the money back. Paid and not
	-- upgraded is the one outcome that must never stand.
	--==========================================================================
	if not PlayerDataService.AddCash(player, -step.cost) then
		busy[player] = false
		return false
	end

	if not PlayerDataService.SetPlotTier(player, step.level) then
		PlayerDataService.AddCash(player, step.cost)
		busy[player] = false
		return false
	end

	--==========================================================================
	-- OWNERSHIP, RE-CHECKED IMMEDIATELY BEFORE THE GEOMETRY MOVES
	--
	-- The plot was checked at the top of this function, and on today's code
	-- nothing between there and here yields -- so it cannot have changed hands.
	-- That is an accident of the current implementation, not a guarantee: the
	-- moment anything in this path acquires a wait (an animated rebuild is the
	-- obvious candidate), a player could leave mid-transaction, drainQueue
	-- could hand their plot to the next in line, and this step would resize
	-- SOMEBODY ELSE'S garden on the departing player's behalf.
	--
	-- So the plot is re-fetched rather than trusted. `plot` above is a stale
	-- reference from before the charge and is not used again.
	--
	-- If ownership is gone, the purchase still STANDS: they were charged and
	-- their profile carries the new level, which is a complete and consistent
	-- transaction. The geometry is simply built later, when they are next given
	-- a plot -- PlayerDataService feeds the saved level back into
	-- SetDesiredLevel on their next load. Rolling back instead would be equally
	-- consistent but strictly worse for the player, who did nothing wrong.
	--==========================================================================
	local live = PlotService.PlotOf(player)
	if live == nil or PlotService.OwnerOf(live) ~= player then
		busy[player] = false
		log(string.format(
			"%s lost their plot mid-upgrade; charged and recorded at level %d, " ..
			"geometry deferred to their next plot.", player.Name, step.level))
		return true
	end

	--==========================================================================
	-- THE REBUILD IS THE PART THAT CAN THROW
	--
	-- It destroys and recreates every part in the plot and moves a live garden
	-- onto new soil. pcall'd not because a specific failure is expected, but
	-- because an unexpected one here would otherwise leave the player charged,
	-- their profile claiming a level, and their plot still the old size --
	-- the exact inconsistency the whole ordering exists to prevent.
	--==========================================================================
	local ok, err = pcall(PlotService.SetDesiredLevel, player, step.level)
	if not ok then
		warn(string.format(
			"[Seed/PlotUpgradeService] %s: rebuild to level %d failed, rolling back: %s",
			player.Name, step.level, tostring(err)))
		PlayerDataService.SetPlotTier(player, before)
		PlayerDataService.AddCash(player, step.cost)
		-- Put the geometry back too, or the world keeps a plot at a size the
		-- profile no longer claims.
		pcall(PlotService.SetDesiredLevel, player, before)
		busy[player] = false
		return false
	end

	busy[player] = false

	--==========================================================================
	-- THE SOUND IS FIRED HERE, NOT ON THE CLIENT
	--
	-- The Shop plays nothing on click. A click is a REQUEST, and a click that
	-- gets refused -- not enough cash, no plot, already max -- must not sound
	-- like a purchase. This fires only on the path where the money actually
	-- moved, so the cue means what it sounds like it means.
	--==========================================================================
	--==========================================================================
	-- AND AT THE PLOT THEY STILL OWN, NOT THE ONE THEY OWNED
	--
	-- Re-fetched for the same reason as the geometry step. Emitting on the
	-- stale reference would play a purchase cue in the garden of whoever
	-- inherited the plot -- a sound with no cause, in somebody else's plot,
	-- attributable to nothing they did.
	--==========================================================================
	local anchor = live.PrimaryPart
	if anchor and live.Parent and PlotService.OwnerOf(live) == player then
		SoundKit.emit("MillUpgrade", anchor)
	end

	log(string.format("%s upgraded their plot to level %d (%d slots) for %s.",
		player.Name, step.level, GameConfig.plotCapacityForTier(step.level),
		GameConfig.compact(step.cost)))
	return true
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PlotUpgradeService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(busy)
end

function PlotUpgradeService.Start()
	--==========================================================================
	-- A THIRD VERB ON THE SAME REMOTE
	--
	-- GameEvent already carries PlantAt and PickUp, each connected by the
	-- service that owns it. This adds a listener rather than a remote, for the
	-- same reason those did: the validation belongs next to the thing being
	-- validated, and a remote per verb is a remote per verb for no gain.
	--==========================================================================
	local remotes = SeedGame:FindFirstChild("Remotes")
	local channel = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if channel and channel:IsA("RemoteEvent") then
		table.insert(serviceConnections, channel.OnServerEvent:Connect(
			function(player: Player, action: any)
				if action == ACTION then
					PlotUpgradeService.TryUpgrade(player)
				end
			end))
	else
		warn("[Seed/PlotUpgradeService] No GameEvent remote. Plots cannot be upgraded.")
	end

	table.insert(serviceConnections,
		game:GetService("Players").PlayerRemoving:Connect(function(player)
			busy[player] = nil
		end))
end

function PlotUpgradeService.Snapshot(): string
	local lines = { "PlotUpgradeService" }
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local step = PlotUpgradeService.NextStepFor(player)
		table.insert(lines, string.format("  %s: level %d, next %s",
			player.Name, PlotUpgradeService.LevelOf(player),
			if step.kind == "max" then "MAX"
			else string.format("L%d for %s", step.level, GameConfig.compact(step.cost))))
	end
	return table.concat(lines, "\n")
end

return PlotUpgradeService
