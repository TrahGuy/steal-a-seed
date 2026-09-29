--!strict
--==============================================================================
-- Steal a Seed :: HatchRoll
--
-- THE SUSPENSE BEFORE A HATCH IS SHOWN (2026-09-29), as arithmetic.
--
-- The owner's request: "When a pod finishes hatching, show a polished animation
-- that cycles through plant silhouettes with a prominent question mark, then
-- reveals the plant actually hatched. The roll must last at least 5 seconds
-- before the final reveal. Start briskly, slow toward the end."
--
-- And the rule that came with it: "The server must determine and secure the
-- real outcome independently of the animation -- this is a visual reveal, not a
-- second roll."
--
--==============================================================================
-- NOTHING HERE DECIDES ANYTHING
--
-- Three questions, each answered from numbers somebody else has already fixed:
--
--   schedule   WHEN a hatch's roll runs, and when its plant may be shown. Asked
--              by the server, once, for a hatch that is about to happen. One
--              roll at a time for each player.
--   frames     WHICH silhouette is on the card at each moment. Asked by the
--              client. The last is always the plant that hatched; the others
--              are the plants of its biome in an order drawn from the hatch's
--              token -- so one hatch is one roll wherever it is drawn, and
--              drawing it twice cannot change it.
--   hidden     WHETHER a plant is still a secret. Asked by everything that
--              would otherwise name it: the hotbar, the Bag, the world.
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

local HatchRoll = {}

-- On a plant's Tool: the server time its plant may be shown. Set by the hatch,
-- taken off by the server when that time comes.
HatchRoll.Attribute = ROLL.Attribute :: string
-- What a secret is called, everywhere: CarryService's own word for a banked pod.
HatchRoll.Unknown = "???"

--==============================================================================
-- THE OWNER'S FIVE SECONDS, CHECKED WHEN THIS LOADS
--
-- A roll shorter than five seconds is not a roll the owner asked for, so a
-- number changed to make one fails the require instead of shipping.
--==============================================================================
assert(ROLL.MinSeconds >= 5, "HatchRoll: the roll's floor is the owner's five seconds")
assert(ROLL.Seconds >= ROLL.MinSeconds, "HatchRoll: the roll is shorter than its own floor")
assert(ROLL.Steps >= 3 and ROLL.Steps == math.floor(ROLL.Steps), "HatchRoll: a roll is three silhouettes or more")
assert(ROLL.FloorHold > 0 and ROLL.FirstHold > 0 and ROLL.LastHold >= ROLL.FirstHold,
	"HatchRoll: a roll starts brisk and ends slow, never the other way")
assert(ROLL.ShowSeconds > 0 and ROLL.MaxWaitSeconds >= 0, "HatchRoll: the card's times are not times")
assert(ROLL.MaxHideSeconds >= ROLL.MaxWaitSeconds + ROLL.Seconds + ROLL.ShowSeconds,
	"HatchRoll: a plant could be shown later than it may be hidden")

export type Frame = {
	-- Seconds after the roll began that this silhouette comes up, and how long
	-- it stays.
	at: number,
	hold: number,
	speciesId: string,
}

export type Schedule = {
	-- Server times: the roll's first silhouette, and the plant shown. The same
	-- moment, `now`, when the roll is switched off.
	rollAt: number,
	revealAt: number,
	-- When this player's card is free for the next hatch.
	busyUntil: number,
	-- True when the card is too far behind to wait for: the hatch counts down on
	-- its own and is told in a line.
	compact: boolean,
}

--==============================================================================
-- WHETHER THERE IS A ROLL AT ALL
--
-- GameConfig.Plant.Hatch.Roll.Enabled, or its StudioPreview in Studio -- where
-- the server and the client both answer yes, so a preview is a whole one. Off,
-- `schedule` answers "now" for everything and a hatch is the hatch it was.
--==============================================================================
function HatchRoll.live(): boolean
	if ROLL.Enabled == true then
		return true
	end
	return ROLL.StudioPreview == true and RunService:IsStudio()
end

--==============================================================================
-- HOW LONG EACH SILHOUETTE IS HELD
--
-- Brisk, then slow: the holds grow by one ratio from FirstHold to LastHold, and
-- are then stretched together so that they fill Seconds exactly. A hold that
-- stretching left under FloorHold is lifted to it -- which makes the roll
-- LONGER than Seconds, never shorter, and never a flicker.
--==============================================================================
local heldFor: { number } = {}
do
	local steps = ROLL.Steps
	local ratio = ROLL.LastHold / ROLL.FirstHold
	local total = 0
	for i = 1, steps do
		heldFor[i] = ROLL.FirstHold * ratio ^ ((i - 1) / (steps - 1))
		total += heldFor[i]
	end
	local stretch = ROLL.Seconds / total
	for i = 1, steps do
		heldFor[i] = math.max(heldFor[i] * stretch, ROLL.FloorHold)
	end
end

function HatchRoll.holds(): { number }
	return table.clone(heldFor)
end

-- The whole roll, first silhouette to the reveal. At least Seconds.
function HatchRoll.seconds(): number
	local total = 0
	for _, hold in ipairs(heldFor) do
		total += hold
	end
	return math.max(total, ROLL.Seconds)
end

-- From the first silhouette to the card going away.
function HatchRoll.cardSeconds(): number
	return HatchRoll.seconds() + ROLL.ShowSeconds
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
	local count = #heldFor
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
		frames[i] = { at = at, hold = heldFor[i], speciesId = order[i] }
		at += heldFor[i]
	end
	return frames
end

-- Which frame is up `elapsed` seconds into the roll: 1 before it starts, the
-- last one from the moment it lands.
function HatchRoll.frameAt(frames: { Frame }, elapsed: number): number
	local index = 1
	for i, frame in ipairs(frames) do
		if elapsed >= frame.at then
			index = i
		else
			break
		end
	end
	return index
end

--==============================================================================
-- ONE ROLL AT A TIME
--
-- `busyUntil` is when this player's card is free (nil: it is free now). A hatch
-- while it is busy waits its turn -- its roll starts when the one before it has
-- been shown -- unless that is further off than MaxWaitSeconds: then it does
-- not wait for the card at all, and is told in a line when its own time comes.
--
-- Either way the plant is shown no sooner than a whole roll after the hatch.
--==============================================================================
function HatchRoll.schedule(now: number, busyUntil: number?): Schedule
	if not HatchRoll.live() then
		return { rollAt = now, revealAt = now, busyUntil = now, compact = false }
	end
	local seconds = HatchRoll.seconds()
	local free = tonumber(busyUntil) or now
	if free ~= free or free < now then
		free = now
	end
	if free - now > ROLL.MaxWaitSeconds then
		return { rollAt = now, revealAt = now + seconds, busyUntil = free, compact = true }
	end
	local revealAt = free + seconds
	return { rollAt = free, revealAt = revealAt, busyUntil = revealAt + ROLL.ShowSeconds, compact = false }
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

--==============================================================================
-- THE FANFARE, ONCE
--
-- Two things can sound a hatch for its owner: their card, at the moment it
-- shows the plant, and the world's side (HatchFX) a moment later, which is the
-- one that does it when the card was put away or never drawn. Whichever asks
-- first for a hatch's token is told yes, and whoever asks after is told no.
--
-- Kept here because this is the one module both of them have, and kept by
-- token, so that two hatches shown in the same moment cannot answer for each
-- other. It is each client's own: nothing is sent, and nothing depends on it
-- but a sound.
--==============================================================================
local sounded: { [number]: boolean } = {}
local soundedCount = 0
-- A server counts its hatches up from one, and only a hatch of the last half
-- minute can still be asked for: the rest are forgotten, so a long session does
-- not keep a note for every plant it ever showed.
local KEEP = 128

function HatchRoll.claim(token: any): boolean
	local n = tonumber(token)
	if not n or n ~= n or n == 0 then
		-- A hatch with no token cannot be told from another: it is sounded.
		return true
	end
	if sounded[n] then
		return false
	end
	sounded[n] = true
	soundedCount += 1
	if soundedCount > KEEP * 2 then
		for old in pairs(sounded) do
			if old < n - KEEP then
				sounded[old] = nil
				soundedCount -= 1
			end
		end
	end
	return true
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
