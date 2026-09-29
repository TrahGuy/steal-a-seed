--!strict
--==============================================================================
-- Steal a Seed :: HatchRoll
--
-- THE SUSPENSE BEFORE A HATCH IS SHOWN (2026-09-29), as arithmetic.
--
-- The owner's request, as revised the same day: "when a pod hatches, show a
-- lightweight world-space animation at that pod's exact position. For about 3
-- seconds, quickly cycle plant silhouettes with a floating question mark, slow
-- the cycle, then reveal the actual plant there with the existing hatch
-- effects. Nearby players should be able to see it. Do not open a modal, cover
-- the camera, stop movement, or add a lingering result panel."
--
-- And the rule that came with it: "The real plant must still be determined and
-- safely recorded by the server before the cosmetic animation. This is not a
-- second roll."
--
--==============================================================================
-- NOTHING HERE DECIDES ANYTHING
--
-- Three questions, each answered from numbers somebody else has already fixed:
--
--   revealAt   WHEN a hatch's plant may be shown. Asked by the server, once,
--              for a hatch that is about to happen. Every hatch has its own
--              three seconds; nothing waits for anything else.
--   frames     WHICH silhouette stands where the pod was at each moment. Asked
--              by every client that can see it. The last is always the plant
--              that hatched; the others are the plants of its biome in an order
--              drawn from the hatch's token -- so one hatch is one roll on
--              every screen, and drawing it twice cannot change it.
--   hidden     WHETHER a plant is still a secret. Asked by everything that
--              would otherwise name it: the hotbar, the Bag, the Index.
--
-- The species is an ARGUMENT to `frames`, never a result of it. There is no
-- function in this file that returns a plant nobody handed it.
--
-- Every number is GameConfig.Plant.Hatch.Roll's. The clock is the caller's:
-- Workspace:GetServerTimeNow(), which the server and every client agree on.
--==============================================================================

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local ROLL = GameConfig.Plant.Hatch.Roll
local BURST: number = GameConfig.Plant.BurstSeconds
local PULSE: number = GameConfig.Plant.Hatch.Paid.PulseSeconds
-- How far into the burst the soil is clear enough to stand something on: the
-- moment the creature itself used to begin.
local BURST_SHARE = 0.55

local HatchRoll = {}

-- On a plant's Tool: the server time its plant may be shown. Set by the hatch,
-- taken off by the server when that time comes.
HatchRoll.Attribute = ROLL.Attribute :: string
-- What a secret is called, everywhere: CarryService's own word for a banked pod.
HatchRoll.Unknown = "???"

--==============================================================================
-- THE OWNER'S THREE SECONDS, CHECKED WHEN THIS LOADS
--
-- "About 3 seconds" is between two and a half and three and a half. A number
-- changed to make the roll something else fails the require instead of shipping.
--==============================================================================
assert(ROLL.MinSeconds >= 2.5 and ROLL.MaxSeconds <= 3.5,
	"HatchRoll: the owner asked for about three seconds")
assert(ROLL.Seconds >= ROLL.MinSeconds and ROLL.Seconds <= ROLL.MaxSeconds,
	"HatchRoll: the roll is not about three seconds")
assert(ROLL.Steps >= 3 and ROLL.Steps == math.floor(ROLL.Steps), "HatchRoll: a roll is three silhouettes or more")
assert(ROLL.FloorHold > 0 and ROLL.FirstHold > 0 and ROLL.LastHold >= ROLL.FirstHold,
	"HatchRoll: a roll starts quick and ends slow, never the other way")
assert(ROLL.MaxHideSeconds >= ROLL.Seconds, "HatchRoll: a plant could be shown later than it may be hidden")

export type Frame = {
	-- Where in the cycle this silhouette comes up and where it gives way, from
	-- nought (the first silhouette) to one (the reveal).
	from: number,
	to: number,
	speciesId: string,
}

--==============================================================================
-- WHETHER THERE IS A ROLL AT ALL
--
-- GameConfig.Plant.Hatch.Roll.Enabled, or its StudioPreview in Studio -- where
-- the server and the client both answer yes, so a preview is a whole one. Off,
-- `revealAt` answers "now" and a hatch is the hatch it was.
--==============================================================================
function HatchRoll.live(): boolean
	if ROLL.Enabled == true then
		return true
	end
	return ROLL.StudioPreview == true and RunService:IsStudio()
end

-- From the hatch to the plant, shown.
function HatchRoll.seconds(): number
	return ROLL.Seconds
end

-- When a hatch that happens `now` may show its plant. The same moment when the
-- roll is switched off.
function HatchRoll.revealAt(now: number): number
	if not HatchRoll.live() then
		return now
	end
	return now + ROLL.Seconds
end

--==============================================================================
-- WHEN THE SILHOUETTES TURN
--
-- The shell bursts first, as it always has: the silhouettes begin when the soil
-- is clear -- where the creature used to begin -- and turn until the reveal. A
-- purchase puts its pulse in front of the burst, so its silhouettes have that
-- much less time and turn that much quicker; the reveal is at the same moment.
--==============================================================================
function HatchRoll.lead(paid: boolean?): number
	return BURST * BURST_SHARE + (if paid == true then PULSE else 0)
end

function HatchRoll.cycle(paid: boolean?): number
	return math.max(ROLL.Seconds - HatchRoll.lead(paid), 0.1)
end

--==============================================================================
-- HOW LONG EACH SILHOUETTE IS HELD
--
-- Quick, then slow: the holds grow by one ratio from FirstHold to LastHold, and
-- are kept as SHARES of the cycle, so that they fill it exactly whatever its
-- length. The shortest of them, in the shortest cycle there is, is not under
-- FloorHold: numbers that would make a silhouette flicker do not load.
--==============================================================================
local share: { number } = {}
do
	local steps = ROLL.Steps
	local ratio = ROLL.LastHold / ROLL.FirstHold
	local total = 0
	for i = 1, steps do
		share[i] = ROLL.FirstHold * ratio ^ ((i - 1) / (steps - 1))
		total += share[i]
	end
	for i = 1, steps do
		share[i] /= total
	end
end
assert(share[1] * HatchRoll.cycle(true) >= ROLL.FloorHold,
	"HatchRoll: a silhouette would be held for less than the floor")

-- The holds of one cycle, in seconds.
function HatchRoll.holds(paid: boolean?): { number }
	local cycle = HatchRoll.cycle(paid)
	local holds: { number } = table.create(#share)
	for i, part in ipairs(share) do
		holds[i] = part * cycle
	end
	return holds
end

--==============================================================================
-- WHOSE SILHOUETTES
--
-- The plants of the hatched plant's own biome, in the species sheet's order. A
-- pod is a shell coloured by its biome, so these are the shapes that shell
-- could have held. Ids only.
--==============================================================================
function HatchRoll.candidates(actualId: any): { string }
	local actual = if type(actualId) == "string" then SeedData.Get(actualId) else nil
	local ids: { string } = {}
	if actual then
		for _, species in ipairs(SeedData.InBiome(actual.Biome)) do
			table.insert(ids, species.Id)
		end
	end
	if #ids == 0 and type(actualId) == "string" then
		ids[1] = actualId
	end
	return ids
end

--==============================================================================
-- THE ROLL, FRAME BY FRAME
--
-- Built BACKWARDS from the plant that hatched: the last silhouette is its own,
-- and each one before it is any of the biome's plants but the one that follows
-- -- so no shape is ever shown twice running, and the roll cannot end anywhere
-- but on the truth. The plants come out of a shuffled bag that is refilled when
-- it empties, so every shape is seen before any is seen a second time.
--
-- `seed` is the hatch's token. The same token and plant give the same frames on
-- every client, in every session, however often they are asked for.
--==============================================================================
function HatchRoll.frames(actualId: string, seed: number?): { Frame }
	local pool = HatchRoll.candidates(actualId)
	local count = #share
	local order: { string } = table.create(count, actualId)
	local rng = Random.new(math.floor(math.abs(tonumber(seed) or 0)) % 2147483647)
	local bag: { string } = {}

	local function draw(avoid: string): string
		for _ = 1, 2 do
			for i = #bag, 1, -1 do
				if bag[i] ~= avoid then
					return table.remove(bag, i) :: string
				end
			end
			bag = table.clone(pool)
			for i = #bag, 2, -1 do
				local j = rng:NextInteger(1, i)
				bag[i], bag[j] = bag[j], bag[i]
			end
		end
		-- A biome of one plant: there is nothing else to show.
		return avoid
	end

	for i = count - 1, 1, -1 do
		order[i] = draw(order[i + 1])
	end

	local frames: { Frame } = table.create(count)
	local at = 0
	for i = 1, count do
		local to = if i == count then 1 else at + share[i]
		frames[i] = { from = at, to = to, speciesId = order[i] }
		at = to
	end
	return frames
end

-- Which frame is up at `fraction` of the cycle: the first before it starts, the
-- last from the moment it lands.
function HatchRoll.frameAt(frames: { Frame }, fraction: number): number
	local index = 1
	for i, frame in ipairs(frames) do
		if fraction >= frame.from then
			index = i
		else
			break
		end
	end
	return index
end

--==============================================================================
-- IS IT STILL A SECRET
--
-- `revealAt` came off a Tool or out of a message, so it is read as a claim: not
-- a number, not a time, already past, or further off than any roll could be,
-- and the plant is simply shown. A secret can run out; it cannot get stuck.
--==============================================================================
function HatchRoll.hidden(revealAt: any, now: number): boolean
	local at = tonumber(revealAt)
	if not at or at ~= at then
		return false
	end
	local left = at - now
	return left > 0 and left <= ROLL.MaxHideSeconds
end

-- The same question of a plant's Tool, by the clock everybody shares.
function HatchRoll.sealed(tool: Instance?): boolean
	if not tool then
		return false
	end
	return HatchRoll.hidden(tool:GetAttribute(HatchRoll.Attribute), Workspace:GetServerTimeNow())
end

-- What the hotbar and the Bag may say of a plant's Tool: a hatched plant whose
-- roll is still running is drawn as the pod it came out of.
function HatchRoll.shownHatched(tool: Instance): boolean
	return tool:GetAttribute("Hatched") == true and not HatchRoll.sealed(tool)
end

function HatchRoll.shownName(tool: Instance): string
	return if HatchRoll.sealed(tool) then HatchRoll.Unknown else tool.Name
end

--==============================================================================
-- WHAT THIS PLAYER IS STILL WAITING TO BE SHOWN
--
-- Read off the plant Tools they hold, which is where the server wrote it: the
-- species whose rolls are still running, each with the time it ends. For the
-- things that would name a plant without drawing its Tool -- the Index losing a
-- silhouette, the guide congratulating a first hatch.
--==============================================================================
function HatchRoll.sealedSpecies(player: Player): { [string]: number }
	local found: { [string]: number } = {}
	local now = Workspace:GetServerTimeNow()
	local function read(container: Instance?)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") then
				local at = child:GetAttribute(HatchRoll.Attribute)
				local id = child:GetAttribute("SpeciesId")
				if type(id) == "string" and HatchRoll.hidden(at, now) then
					found[id] = math.max(found[id] or 0, tonumber(at) :: number)
				end
			end
		end
	end
	read(player:FindFirstChildOfClass("Backpack"))
	read(player.Character)
	return found
end

-- The moment the last of them ends, or nil when nothing is waiting.
function HatchRoll.pendingUntil(player: Player): number?
	local latest: number? = nil
	for _, at in pairs(HatchRoll.sealedSpecies(player)) do
		if latest == nil or at > latest then
			latest = at
		end
	end
	return latest
end

return HatchRoll
