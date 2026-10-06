--!strict
-- Steal a Seed :: InviteSounds (client, 2026-10-06)
--
-- The owner's ten Invite a Friend sounds, played by moment through SoundKit's
-- cues (GameConfig.Sfx.Cues Invite*: the player's own UI and World buses, so
-- Settings' volume and mute apply). The rules that keep them apart live here,
-- once, and are pure (`allow`) so InviteAudioSpec can hold them:
--
--   * Never two on top of each other: the reward popup's unlock wins -- it
--     stops any invite sound still playing, and a tick, a badge pop or an
--     evolve due while it plays is skipped.
--   * The progress tick: at most TickRun in a row, then silent until TickQuiet
--     has passed with none.
--   * "+1 INVITE": a second within JoinedQuiet of the first is the same notice
--     refreshed, and silent.
--   * Send, welcome: as asked, every time (the callers ask only once).

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local CONFIG = GameConfig.InviteRewards

local InviteSounds = {}

-- Moment -> cue. An unlock's cue is by rarity (UnlockCue).
InviteSounds.Cues = {
	send = "InviteSend",
	joined = "InviteJoined",
	tick = "InviteTick",
	badge = "InviteBadgePop",
	welcome = "InviteWelcome",
	evolve = "InviteEvolve",
}

-- How long an unlock holds the floor.
InviteSounds.UnlockHold = 2.5

export type State = { unlockUntil: number, ticks: { number }, joinedAt: number }

function InviteSounds.newState(): State
	return { unlockUntil = -math.huge, ticks = {}, joinedAt = -math.huge }
end

-- Whether `moment` may sound now, and the state after it (changed in place).
function InviteSounds.allow(state: State, moment: string, now: number): boolean
	if moment == "unlock" then
		state.unlockUntil = now + InviteSounds.UnlockHold
		return true
	end
	if now < state.unlockUntil and (moment == "tick" or moment == "badge" or moment == "evolve") then
		return false
	end
	if moment == "tick" then
		local recent: { number } = {}
		for _, at in ipairs(state.ticks) do
			if now - at < CONFIG.TickQuiet then
				table.insert(recent, at)
			end
		end
		state.ticks = recent
		if #recent >= CONFIG.TickRun then
			return false
		end
		table.insert(state.ticks, now)
		return true
	end
	if moment == "joined" then
		local quiet = now - state.joinedAt < CONFIG.JoinedQuiet
		state.joinedAt = now
		return not quiet
	end
	return true
end

-- The cue an unlock plays for a rarity, or nil.
function InviteSounds.unlockCue(rarity: string): string?
	return CONFIG.UnlockCue[rarity]
end

local shared = InviteSounds.newState()

-- The invite sounds started lately (never an unlock's): an unlock stops any
-- still playing, so it is the only invite sound heard.
local live: { Sound } = {}

local function keep(sound: Sound?)
	if sound then
		table.insert(live, sound)
		while #live > 8 do
			table.remove(live, 1)
		end
	end
end

local function hush()
	for _, sound in ipairs(live) do
		if sound.Parent and sound.IsPlaying then
			pcall(function()
				sound:Stop()
			end)
		end
	end
	table.clear(live)
end

-- Plays a moment's sound on the UI bus (2D), if the rules allow it now.
function InviteSounds.play(moment: string, rarity: string?): Sound?
	local now = os.clock()
	if not InviteSounds.allow(shared, moment, now) then
		return nil
	end
	local cue = if moment == "unlock" then InviteSounds.unlockCue(rarity or "") else InviteSounds.Cues[moment]
	if not cue then
		return nil
	end
	if moment == "unlock" then
		hush()
		return SoundKit.play(cue)
	end
	local sound = SoundKit.play(cue)
	keep(sound)
	return sound
end

-- The evolve, in the world on `at` (the pedestal), if the rules allow it now.
function InviteSounds.emit(moment: string, at: BasePart): Sound?
	if not InviteSounds.allow(shared, moment, os.clock()) then
		return nil
	end
	local cue = InviteSounds.Cues[moment]
	local sound = if cue then SoundKit.emit(cue, at) else nil
	keep(sound)
	return sound
end

return InviteSounds
