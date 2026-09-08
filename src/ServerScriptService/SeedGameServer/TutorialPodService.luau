--!strict
--==============================================================================
-- THE BEGINNER'S RESERVED POD
--
-- Greenhollow is ONE nest of FIVE pods and a taken slot does not grow back
-- until dawn -- that scarcity is the point of the road and nothing here touches
-- it. But it means a new player can finish the training steps, walk out to the
-- nest the guide is pointing at, and find nothing there for up to a full day.
-- The tutorial is then blocked by other people's play, which is the one thing a
-- tutorial must never be.
--
-- So one extra pod stands outside the ring with a beginner's name on it. It is
-- ADDITIONAL supply, not a public slot: the ring still holds five, the rolls are
-- unchanged, and nobody else's raid is any easier or harder.
--
--==============================================================================
-- IT IS AN ORDINARY POD IN EVERY WAY THAT MATTERS
--
-- Built by the same builder, tagged the same, prompted the same, taken through
-- the same CarryService path, and it wakes the same guardian for the same
-- chase. It is deliberately NOT given a NestId, which routes it through the
-- LOOSE branch of TryTake -- the branch that provokes by FromNestId and touches
-- no slot bookkeeping. That is what keeps public pod counts exactly as they
-- were.
--
-- The only thing unusual about it is the ReservedFor attribute, and the only
-- thing that attribute does is make CarryService.TryTake refuse everybody else.
--
--==============================================================================
-- WHY THERE IS NO IDENTITY THREADED THROUGH THE SAVE
--
-- The obvious design gives the pod a GUID and follows it: nest -> carried ->
-- dropped -> banked -> planted -> hatched. That needs a new field in two save
-- whitelists, and ProfileSchema rebuilds Held and Plants rows field by field on
-- every load, so it means touching the save format in two places to answer one
-- question.
--
-- The question is only ever "does this player already have a pod?" -- because
-- what the feature owes them is A POD, not a particular one. So possession is
-- what is checked, across every state a pod can be in, and the identity that
-- does exist (ReservedFor on the model) is needed for exactly one thing the
-- possession check cannot do on its own: telling "their pod is lying on the
-- ground over there" apart from "they have nothing". A dropped pod is invisible
-- to a save-based check and would otherwise look like a loss.
--
-- What stops this becoming a tap is the grant COUNT, which is the one thing that
-- had to be saved. See TutorialData.MaxPodGrants.
--==============================================================================
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TutorialData = require(Shared:WaitForChild("TutorialData"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local TutorialPodService = {}
TutorialPodService.Priority = 75

--==============================================================================
-- WHAT IS RESERVED
--
-- A Tiny Common, which is the floor of the loot table: the tutorial owes a
-- beginner a first pod, not a good one. `nubkin` is a registered Greenhollow
-- Common -- looked up rather than assumed, so deleting it from SeedData turns
-- this feature off instead of spawning a nil.
--==============================================================================
-- The lane the guide sends a beginner down, and the only one this touches.
local BIOME_ID = "greenhollow"
local SPECIES_ID = "nubkin"
local TIER = 1

-- The public ring is 16 studs out (NestService.NEST_RADIUS). Reservations stand
-- clear of it, and clear of each other, so two beginners never share a spot.
local RESERVE_RADIUS = 24
local SPREAD_DEGREES = 26

local TICK_SECONDS = 2

local function log(message: string)
	print("[Seed/TutorialPodService] " .. message)
end

--==============================================================================
-- STATE, AND IT IS ALL RUNTIME
--
-- The standing pod is a world object; if the server dies it goes with the world.
-- Nothing here is saved except the grant count, which PlayerDataService owns.
--==============================================================================
local standing: { [Player]: Model } = {}
local slotOf: { [Player]: number } = {}
local connections: { RBXScriptConnection } = {}
local running = false

--==============================================================================
-- THE NEST THIS BELONGS TO
--
-- Read off the built world rather than computed, because the id the guardian is
-- provoked by is the nest FOLDER'S NAME and guessing that format here would be
-- a second copy of it.
--==============================================================================
local function greenhollowNest(): (string?, Vector3?)
	--==========================================================================
	-- OFF THE MARKER, NOT OFF A TREE WALK
	--
	-- MapService tags an invisible NestSite part at every nest position and
	-- NestService names its folder `Nest_<biome>_<index>` from the marker's
	-- NestIndex. Reading both from the marker means the id handed to the
	-- guardian and the position the pod stands at come from the SAME source the
	-- real nest was built from -- so a moved nest moves the reservation with it,
	-- and a renamed folder cannot leave this pointing at nothing.
	--==========================================================================
	for _, marker in ipairs(CollectionService:GetTagged(GameConfig.Tags.NestSite)) do
		if marker:IsA("BasePart") and marker:IsDescendantOf(workspace)
			and marker:GetAttribute(GameConfig.Attributes.BiomeId) == BIOME_ID then
			local index = tonumber(marker:GetAttribute("NestIndex")) or 0
			return string.format("Nest_%s_%02d", BIOME_ID, index), marker.Position
		end
	end
	return nil, nil
end

--==============================================================================
-- WHERE ONE STANDS
--
-- The same arithmetic NestService uses for the public ring -- a flat offset from
-- the nest marker, no raycast -- and deliberately so. The road is flat, the ring
-- is placed this way, and a ray fired down from above a nest can just as easily
-- hit a guardian, another pod or a decoration as it can the ground. Matching the
-- ring means a reserved pod sits at exactly the height the five beside it do.
--
-- The radius is 24 against the ring's 16, which puts it OUTSIDE the ring rather
-- than among it: it cannot overlap a public pod at any angle, and a beginner
-- reaches it a step before they are inside the guardian's circle.
--==============================================================================
local function spotFor(centre: Vector3, slot: number): Vector3
	local angle = math.rad(SPREAD_DEGREES * slot)
	return centre + Vector3.new(math.sin(angle) * RESERVE_RADIUS, 0,
		math.cos(angle) * RESERVE_RADIUS)
end

--==============================================================================
-- IS THERE A POD OF THIS PLAYER'S ANYWHERE IN THE WORLD
--
-- Covers the standing reservation AND a dropped one, which is the case a
-- save-based check cannot see. Streaming does not affect this: it runs on the
-- SERVER, where the model exists whether or not any client has been sent it.
-- That is what makes "the client cannot see it" and "it is gone" different
-- questions here.
--==============================================================================
local function worldPodFor(userId: number): Model?
	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod:IsA("Model") and pod:IsDescendantOf(workspace)
			and not CollectionService:HasTag(pod, GameConfig.Tags.Planted)
			and CarryService.ReservedFor(pod) == userId then
			return pod
		end
	end
	return nil
end

--==============================================================================
-- GATHER THE FACTS, THEN ASK THE RULE
--
-- The rule itself is TutorialData.HasOutstandingPod, which is pure and tested
-- without a world. This half is the part that can only be done here, and its one
-- job is to gather honestly.
--
-- STREAMING CANNOT REACH IT. `inWorld` is answered on the SERVER, where the
-- model exists whether or not any client has been sent it -- so "the owner
-- cannot see their pod" and "the pod is gone" stay different questions, and
-- only the second one buys a replacement.
--==============================================================================
local function hasOutstandingPod(player: Player): boolean
	local profile = PlayerDataService.Get(player)
	if not profile then
		--======================================================================
		-- NO PROFILE IS NOT "THEY HAVE NOTHING", IT IS "WE DO NOT KNOW YET"
		--
		-- This is the reconnect reconciliation, and it is a single line because
		-- the safe answer is the conservative one: until the save has loaded and
		-- its Held and Plants rows can be read, answering YES means no pod is
		-- placed. A player rejoining with a banked pod therefore cannot be handed
		-- a second one in the window before their save arrives.
		--======================================================================
		return true
	end
	return TutorialData.HasOutstandingPod({
		carrying = CarryService.IsCarrying(player),
		inWorld = worldPodFor(player.UserId) ~= nil,
		held = profile.Held,
		plants = profile.Plants,
	})
end

local function eligible(player: Player): boolean
	local profile = PlayerDataService.Get(player)
	if not profile or type(profile.Tutorial) ~= "table" then
		return false
	end
	return TutorialData.PodEligible(profile.Tutorial)
end

--==============================================================================
-- PUTTING ONE OUT, AND TAKING IT BACK
--==============================================================================
local function clearStanding(player: Player)
	local pod = standing[player]
	standing[player] = nil
	slotOf[player] = nil
	if pod and pod.Parent then
		pod:Destroy()
	end
end

local function place(player: Player): boolean
	local nestId, centre = greenhollowNest()
	if not (nestId and centre) then
		return false
	end
	--==========================================================================
	-- A SPOT OF THEIR OWN
	--
	-- Two beginners must not be handed the same patch of grass. The slot is the
	-- lowest index nobody else is using, turned into an angle, so the ring fills
	-- outward from one side instead of stacking.
	--==========================================================================
	local used: { [number]: boolean } = {}
	for other, slot in pairs(slotOf) do
		if other ~= player then
			used[slot] = true
		end
	end
	local slot = 0
	while used[slot] do
		slot += 1
	end
	local pod = CarryService.SpawnLoose(SPECIES_ID, TIER,
		CFrame.new(spotFor(centre, slot)), nestId, player.UserId, true)
	if not pod then
		return false
	end
	standing[player] = pod
	slotOf[player] = slot
	--==========================================================================
	-- COUNTED WHEN IT IS PLACED, NOT WHEN IT IS TAKEN
	--
	-- A pod that was put out and then abandoned still cost a grant. Counting on
	-- the take would let somebody farm the SPAWN -- stand there, never take it,
	-- log out, come back -- and counting nothing at all is the sell-loop.
	--==========================================================================
	local grants = PlayerDataService.RecordPodGrant(player) or 0
	log(string.format("reserved a %s for %s (grant %d of %d)", SPECIES_ID, player.Name,
		grants, TutorialData.MaxPodGrants))
	return true
end

--==============================================================================
-- ONE PASS
--
-- Deliberately a poll rather than a web of events. The inputs are the world
-- phase, four kinds of possession and a saved counter, and any of them can move
-- without an event this service would hear -- a pod despawning on its own timer
-- is the obvious one. A pass every two seconds is cheaper than being wrong.
--
-- Every branch is idempotent: it either leaves a pod standing or it does not,
-- and running it twice in a row changes nothing.
--==============================================================================
local function pass()
	for _, player in ipairs(Players:GetPlayers()) do
		local ok, err = pcall(function()
			--==============================================================
			-- NIGHT TAKES THE UNCLAIMED ONE BACK, AND ONLY THAT ONE
			--
			-- Nothing stealable may stand out on the road behind a closed
			-- barrier: the nests are cleared at dusk and this is part of the
			-- same supply. What is NOT touched is anything the player already
			-- owns -- carried, banked or planted are theirs and night has no
			-- opinion about them.
			--==============================================================
			if not GameConfig.isDay() then
				if standing[player] then
					clearStanding(player)
				end
				return
			end
			if not eligible(player) then
				clearStanding(player)
				return
			end
			-- Their own standing pod counts as outstanding, so this is also the
			-- "already has one out" case and costs nothing to re-run.
			if hasOutstandingPod(player) then
				-- Keep the handle fresh if the pod was taken and re-dropped.
				if standing[player] and not standing[player].Parent then
					standing[player] = nil
					slotOf[player] = nil
				end
				return
			end
			place(player)
		end)
		if not ok then
			warn("[Seed/TutorialPodService] " .. tostring(err))
		end
	end
end

--==============================================================================
-- PUBLIC, for the debug console and for tests
--==============================================================================
-- The pod reserved for this user id, wherever it is standing. Takes an ID
-- rather than a Player so a fixture can ask about one that never joined.
function TutorialPodService.WorldPodFor(userId: number): Model?
	return worldPodFor(userId)
end

function TutorialPodService.Eligible(player: Player): boolean
	return eligible(player)
end

function TutorialPodService.Snapshot(): string
	local out = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.Get(player)
		out[#out + 1] = string.format("%s eligible=%s outstanding=%s grants=%s",
			player.Name, tostring(eligible(player)), tostring(hasOutstandingPod(player)),
			tostring(profile and profile.Tutorial.PodGrants))
	end
	if #out == 0 then
		return "no players"
	end
	return table.concat(out, "; ")
end

function TutorialPodService.Init()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	for player in pairs(standing) do
		clearStanding(player)
	end
	table.clear(standing)
	table.clear(slotOf)
	running = false
end

function TutorialPodService.Start()
	if running then
		return
	end
	running = true

	--==========================================================================
	-- A LEAVER'S UNCLAIMED POD GOES WITH THEM
	--
	-- Only the one still standing in the nest. Anything they banked or planted
	-- is saved property and is none of this service's business.
	--==========================================================================
	table.insert(connections, Players.PlayerRemoving:Connect(function(player)
		clearStanding(player)
		-- And the one they took and DROPPED, which `standing` never knew about:
		-- a drop destroys the original and spawns a fresh model. It would expire
		-- on its own inside a minute, but until then it is an unremovable prop
		-- that nobody left in the server is allowed to pick up.
		local dropped = worldPodFor(player.UserId)
		if dropped then
			dropped:Destroy()
		end
	end))

	task.spawn(function()
		while running do
			task.wait(TICK_SECONDS)
			pass()
		end
	end)

	log(string.format("Ready. One %s tier %d per eligible beginner, %d studs out, "
		.. "max %d grants each. Public nest counts and rolls are untouched.",
		SPECIES_ID, TIER, RESERVE_RADIUS, TutorialData.MaxPodGrants))
end

function TutorialPodService.Stop()
	running = false
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

return TutorialPodService
