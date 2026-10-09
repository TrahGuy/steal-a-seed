--!strict
--==============================================================================
-- Steal a Seed :: PromptHoldLock
-- HATCH TARGET LOCK (the owner's brief, 2026-10-08, from Michael's report): a
-- hold never jumps to another pod.
--
-- THE BUG. Roblox shows ONE prompt per key, the best-placed one. With ready pods
-- close together, walking or turning mid-hold made another pod's Hatch the best
-- one: the held prompt was hidden, the hold dropped, and the next press landed
-- on the other pod. Plot levels 6-7 pack more pods, so it happened more.
--
-- THE LOCK. Once a hold begins on a prompt that locks (a pod's Hatch), every
-- OTHER prompt that could be shown while the player stays in that prompt's
-- range is put out of reach on THIS client -- its MaxActivationDistance read
-- and set to 0 -- until the hold ends: completed, let go, or the player leaving
-- the held prompt's own range. Nothing else can take the key, so the drawn
-- panel cannot move to another pod either. Prompts arriving or moving into
-- reach during the hold are put out of reach as the lock steps.
--
-- WHY THE REACH AND NOT `Enabled`: the server and two client scripts switch
-- prompts on and off with Enabled (the mill and plot boards, the Bonus Chest,
-- the obby's finish). A lock that wrote Enabled could not tell their writes
-- from its own, and could put back a prompt one of them had just switched off.
-- Nothing writes a prompt's reach after it is made, so a write the lock did not
-- make is somebody else's and is kept: it becomes the value given back, and the
-- prompt stays out of reach until the end. Enabled is never touched.
--
-- LOCAL ONLY. The server's prompts keep their own reach, and PlantService still
-- checks every hatch. Picking the target before a hold starts is unchanged.
--
-- THE SPLIT: the rules and the bookkeeping here (HatchLockSpec drives them in
-- Edit); the events that begin and end a lock in HatchHoldLock.client.luau.
--==============================================================================

local PromptHoldLock = {}

-- The prompts whose hold locks the target, by name: a pod's Hatch. Instant
-- Hatch (hold 0) never holds, so it never locks -- and while a Hatch hold is
-- locked it is out of reach like every other prompt.
PromptHoldLock.LockNames = { HatchPrompt = true } :: { [string]: boolean }

-- Slack on top of the two reaches, in studs, for a prompt's own wobble (the
-- pods sway) between two steps.
PromptHoldLock.Margin = 2

-- A lock longer than the hold plus this is let go whatever else happened: the
-- last guard that nothing stays out of reach.
PromptHoldLock.Overrun = 1.5

function PromptHoldLock.locks(prompt: ProximityPrompt): boolean
	return PromptHoldLock.LockNames[prompt.Name] == true and prompt.HoldDuration > 0
end

-- Where a prompt stands: its part, its attachment, or its model's pivot.
function PromptHoldLock.positionOf(prompt: Instance): Vector3?
	local parent = prompt.Parent
	if parent == nil then
		return nil
	elseif parent:IsA("BasePart") then
		return parent.Position
	elseif parent:IsA("Attachment") then
		return parent.WorldPosition
	elseif parent:IsA("Model") then
		local primary = parent.PrimaryPart
		return if primary then primary.Position else parent:GetPivot().Position
	end
	return nil
end

export type Lock = {
	held: ProximityPrompt,
	reach: number,
	startedAt: number,
	-- Every prompt put out of reach, and the reach it gets back.
	off: { [ProximityPrompt]: number },
	watches: { [ProximityPrompt]: RBXScriptConnection },
	done: boolean,
}

function PromptHoldLock.begin(held: ProximityPrompt, now: number): Lock
	return {
		held = held,
		reach = held.MaxActivationDistance,
		startedAt = now,
		off = {},
		watches = {},
		done = false,
	}
end

-- Whether `other` could be shown while the player is within the held prompt's
-- reach: the two reaches together, plus the margin, cover the gap between them.
function PromptHoldLock.competes(lock: Lock, other: ProximityPrompt): boolean
	if other == lock.held then
		return false
	end
	local heldAt = PromptHoldLock.positionOf(lock.held)
	local otherAt = PromptHoldLock.positionOf(other)
	if not (heldAt and otherAt) then
		return false
	end
	local otherReach = lock.off[other] or other.MaxActivationDistance
	return (otherAt - heldAt).Magnitude <= lock.reach + otherReach + PromptHoldLock.Margin
end

--==============================================================================
-- 0 IS THE LOCK'S OWN WRITE, ANYTHING ELSE IS SOMEBODY ELSE'S
--
-- Read at the moment the handler runs, not at the write: with deferred signals
-- a handler for the lock's own write runs after the lock has moved on, so a
-- "was it me?" flag would already be down, and the 0 would be kept as the
-- value to give back -- a prompt left out of reach for good. A 0 is treated
-- as ours, and any other value is kept as the one given back while the prompt
-- stays out of reach.
--
-- ONE OTHER WRITER OF 0 (2026-10-08): PromptUI puts a prompt on ANOTHER
-- player's plot out of reach the same way. One already at 0 when the lock
-- begins is given back 0. One PromptUI zeroes during a lock gets its old reach
-- back at the end, and PromptUI puts it out again the next time it shows.
--==============================================================================
local function putOut(lock: Lock, prompt: ProximityPrompt)
	lock.off[prompt] = prompt.MaxActivationDistance
	prompt.MaxActivationDistance = 0
	lock.watches[prompt] = prompt:GetPropertyChangedSignal("MaxActivationDistance"):Connect(function()
		local reach = prompt.MaxActivationDistance
		if lock.done or reach == 0 then
			return
		end
		lock.off[prompt] = reach
		prompt.MaxActivationDistance = 0
	end)
end

-- One step: everything that competes now is put out of reach (prompts that
-- arrived or moved since the last step included). Returns false when the lock
-- must end: the held prompt gone, or the hold overrun. Leaving the held
-- prompt's range ends it too -- the engine hides the prompt, and the client
-- lets go on PromptHidden.
function PromptHoldLock.step(lock: Lock, prompts: { [ProximityPrompt]: any }, now: number): boolean
	if lock.done then
		return false
	end
	local held = lock.held
	if held.Parent == nil or not held:IsDescendantOf(game) then
		return false
	end
	if now - lock.startedAt > held.HoldDuration + PromptHoldLock.Overrun then
		return false
	end
	for prompt in pairs(prompts) do
		if lock.off[prompt] == nil and prompt ~= held and prompt.Parent ~= nil
			and PromptHoldLock.competes(lock, prompt) then
			putOut(lock, prompt)
		end
	end
	return true
end

-- Every prompt put out of reach gets its reach back -- the value it had, or
-- the one somebody else wrote while it was out -- and nothing is watched after.
-- Safe to call more than once.
function PromptHoldLock.release(lock: Lock)
	if lock.done then
		return
	end
	lock.done = true
	for prompt, watch in pairs(lock.watches) do
		watch:Disconnect()
		lock.watches[prompt] = nil
	end
	for prompt, reach in pairs(lock.off) do
		lock.off[prompt] = nil
		pcall(function()
			if prompt.Parent ~= nil then
				prompt.MaxActivationDistance = reach
			end
		end)
	end
end

-- How many prompts the lock holds out of reach right now.
function PromptHoldLock.count(lock: Lock): number
	local n = 0
	for _ in pairs(lock.off) do
		n += 1
	end
	return n
end

return PromptHoldLock
