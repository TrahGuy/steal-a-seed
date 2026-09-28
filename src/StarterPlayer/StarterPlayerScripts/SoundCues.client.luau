--!strict
-- Steal a Seed :: SoundCues
--
-- The cues that belong to no other script: the hatch reveal, the mill's refusal,
-- and the nest parent's own two sounds.
--
--==============================================================================
-- WHY THESE FOUR AND NOT THE OTHER FIFTEEN
--
-- Every other cue in the game is played by the script that already owns the
-- moment. The hover pop is in UIKit because UIKit owns the hover; the chase bed
-- is in AlertUI because AlertUI owns the carry; the mill's thump is in
-- TreadmillService because that is the line that catches you.
--
-- What is left over is what has no owner yet -- a reveal that happens two
-- systems away from the prompt that caused it, a refusal that is currently
-- nothing but a `return false`, and a monster whose sounds are the only thing in
-- the game keyed to a tag rather than to a player. Those live here.
--
--==============================================================================
-- THE PARENT'S SOUNDS ARE PAINT, SO THEY ARE THE CLIENT'S JOB
--
-- Same split as ParentAnim and for the same reason: the server walks it and each
-- client decides what it sounds like. `Asleep` replicates on its own, so nobody
-- has to be told anything.
--
-- Deliberately NOT in ParentAnim, which owns Motor6D.C0 and nothing else. A loop
-- that swings arms and also manages Sound instances is two jobs sharing a
-- Heartbeat because they happened to want the same iteration.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local player = Players.LocalPlayer
local SFX = GameConfig.Sfx

--==============================================================================
-- WHAT IS RECORDED AND WHAT IS NOT, SAID ONCE
--
-- The same call Music.client makes, for the same reason. A cue with no id plays
-- nothing and reports nothing, so without this the only symptom of a forgotten
-- row is a game that is quieter than it was meant to be for a reason nobody can
-- see. Printed rather than warned when there are only a few left, because a
-- table being filled in over a week should not shout every join.
--==============================================================================
SoundKit.preload()

do
	local missing = SoundKit.report()
	if #missing > 0 then
		print(string.format("[Seed/SoundCues] %d cue(s) have no id yet and are "
			.. "silent: %s. Paste ids into GameConfig.Sfx.Cues; nothing else has "
			.. "to change.", #missing, table.concat(missing, ", ")))
	end
end

--==============================================================================
-- THE REVEAL IS NOT THIS SCRIPT'S ANY MORE
--
-- It used to be armed HERE, by watching for a prompt named HatchPrompt and then
-- listening for a hatched Tool to arrive in the Backpack inside a four-second
-- window. That worked for the free hatch and could not work for the paid one:
-- INSTANT HATCH ARRIVES AS A RECEIPT, with no prompt held and often no prompt on
-- screen at all, so a 99 Robux hatch could hand over the plant in silence.
--
-- The server now announces every successful hatch on the GameEvent remote, free
-- and paid alike, and HatchFX plays the rarity fanfare off that one message --
-- exactly once, at the pod, for everybody near enough to see the shell open. The
-- window, the Tool watching and the guesswork are all gone with it; a Tool
-- arriving in the Backpack is no longer a sound at all, which is also why a
-- rejoin restoring five plants is silent.
--
-- See GameConfig.Plant.Hatch.Action and HatchFX.client.
--==============================================================================

--==============================================================================
-- THE MILL SAYING NO
--
-- Success needs no message -- the mill is rebuilt in front of you, the sign
-- repaints, and MillUpgrade plays off the new belt. A REFUSAL changes nothing at
-- all on screen, so holding the prompt with $40 short is indistinguishable from
-- holding a prompt that is broken.
--
-- The server sends the verb and `false` down the GameEvent remote it already
-- owns. No reason is sent and none is wanted: the client is told that it did not
-- happen, which is all it needs to make a noise about.
--==============================================================================
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local channel = if remotes
		then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
		else nil
	if not (channel and channel:IsA("RemoteEvent")) then
		return
	end
	channel.OnClientEvent:Connect(function(action: any, ok: any)
		if action == GameConfig.Mill.Action and ok == false then
			SoundKit.play("Denied")
		end
	end)
end)

--==============================================================================
-- THE PARENT
--
-- Two sounds and one rule: asleep it breathes, awake it runs. Both are attached
-- once when the model is tagged and live for as long as it does, so the loop
-- below never creates or destroys anything -- it moves `Playing`.
--
--==============================================================================
-- A FOOTSTEP IS NOT A LOOP UNLESS THE RECORDING IS ONE
--
-- Both are supported, because which one was recorded is a fact about a WAV file
-- and not a fact about this game. `looped = true` in the cue table hangs a
-- looping Sound on the parent and lets it run; `looped = false` retriggers a
-- single step at every footfall -- every STUDS_PER_STEP COVERED, below.
--
-- Distance and not wall-clock, which is the same rule ParentAnim's stride uses
-- and for the same reason: a clock-driven step slides its feet when the parent
-- is slow and sprints on the spot when it has stopped. Distance keeps a foot on
-- the ground at any speed, and the parent's speed rises with every theft.
--==============================================================================
local TAG = GameConfig.Tags.NestParent
--==============================================================================
-- A STEP IS A FOOTFALL, AND THE FOOTFALLS ARE PARENTANIM'S
--
-- This was 2.2 studs, off a note saying ParentAnim "swings a whole stride every
-- ~4 studs". It does not: it advances the stride by SWING_PER_STUD = 0.40
-- radians a stud, a whole two-footed cycle every 2*pi/0.40 = 15.7 studs -- so
-- a footfall every 7.85. At 2.2 the Brambleback, Dustbowl's guardian and the
-- only one with a one-shot step (the rest loop ChaseStep), stomped three and a
-- half times per footfall, and at its chase speed that was a stomp nearly
-- every frame: dozens a second, each a fresh 0.55-second Sound on top of the
-- last. Reported 2026-09-26 as the second guardian's audio "rapid-firing".
--
-- AND NEVER FASTER THAN A FOOT CAN LAND. Past about 31 studs a second even the
-- real stride is more footfalls than a two-ton stomp can be heard as, so one
-- voice waits MIN_STEP_SECONDS between stomps and a stomp still ringing is cut
-- when the next lands: one at a time per parent, however long the chase.
--==============================================================================
local STUDS_PER_STEP = math.pi / 0.40
local MIN_STEP_SECONDS = 0.25

type Voice = {
	model: Model,
	root: BasePart,
	sleep: Sound?,
	step: Sound?,
	-- The cue the per-stride branch fires. Held because it is a different row
	-- for a Brambleback than for Greenhollow's brute, and the loop below must
	-- not have to work that out sixty times a second.
	stepName: string?,
	stepLooped: boolean,
	walked: number,
	at: Vector3,
	-- The one-shot step still sounding, if any, and when it was started.
	stomp: Sound?,
	steppedAt: number,
	-- THE BREATHING, AS SHOWN (2026-09-27): nil until first seen, so a parent
	-- dressed mid-sleep or mid-chase starts in the right state without a fade.
	-- `sleepVolume` is the row's level, put back each time it lies down.
	sleeping: boolean?,
	sleepVolume: number,
	sleepFade: Tween?,
	-- THE WALK HOME: the last ParentState seen, the Return cue its biome has
	-- (nil while that row has no id), and the one-shot still sounding.
	state: string?,
	returnName: string?,
	back: Sound?,
}

-- How long a breath takes to die away when the parent wakes, and a walk-home
-- cue when something cuts it off.
local SLEEP_FADE_SECONDS = 0.35
local RETURN_FADE_SECONDS = 0.25
local RETURN_AT = if SFX.ReturnCueAt == "arrive" then "arrive" else "leave"

-- Takes a sound down over `seconds` and stops it; 0 stops it at once.
local function fadeAway(sound: Sound, seconds: number): Tween?
	if not sound.Parent then
		return nil
	end
	if seconds <= 0 or not sound.IsPlaying then
		sound:Stop()
		return nil
	end
	local tween = TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Quad,
		Enum.EasingDirection.In), { Volume = 0 })
	tween.Completed:Once(function(state: Enum.PlaybackState)
		if state == Enum.PlaybackState.Completed and sound.Parent then
			sound:Stop()
		end
	end)
	tween:Play()
	return tween
end

local function quietBack(voice: Voice, seconds: number)
	local back = voice.back
	voice.back = nil
	if back then
		fadeAway(back, seconds)
	end
end

-- A stomp still ringing when its parent sleeps, streams out or is forgotten
-- stops there rather than playing out its clip.
local function hush(voice: Voice)
	local stomp = voice.stomp
	voice.stomp = nil
	if stomp and stomp.Parent then
		stomp:Stop()
	end
end

local voices: { [Model]: Voice } = {}
--==============================================================================
-- ONE WATCHER PER PARENT, FOR AS LONG AS IT IS TAGGED
--
-- Not a flag saying "somebody is waiting": a live connection that dresses the
-- parent EVERY time its body turns up. Which is more than once -- see below.
--==============================================================================
local watching: { [Model]: RBXScriptConnection } = {}

local function untrack(model: Model)
	local voice = voices[model]
	if voice then
		hush(voice)
		quietBack(voice, 0)
		if voice.sleep then
			voice.sleep:Destroy()
		end
		if voice.step then
			voice.step:Destroy()
		end
		voices[model] = nil
	end
end

--==============================================================================
-- A PARENT CAN ARRIVE TWICE, AND THE SECOND TIME IS THE ONE THAT WAS MISSED
--
-- Two facts, and the second one was found in Play on 2026-09-17 with a
-- StreamingEnabled place open:
--
--   1. THE TAG REACHES A CLIENT BEFORE THE RIG DOES. The parent is 74 to 122
--      parts and they replicate over several frames, so GetInstanceAddedSignal
--      fires on a Model that is still nearly empty.
--
--   2. WITH STREAMING, THE BODY COMES AND GOES FOR THE WHOLE SESSION. The
--      tagged Model stays; its parts are sent when you get near and taken back
--      when you leave. Four of the five parents in the running place had their
--      rigs; Starbloom's was an EMPTY MODEL with the tag on it, and walking to
--      Starbloom would not have fixed it.
--
-- The version this replaces waited ten seconds for HumanoidRootPart and then
-- gave up forever, which answers (1) and gets (2) exactly backwards: a parent
-- more than a streaming radius away at join was silent for that client for the
-- rest of the session, no matter how close they later stood to it. Nothing
-- errored and nothing warned -- a monster that breathes at some players and not
-- at others looks like a sound that "doesn't always play".
--
-- A CONNECTION, NOT A DEADLINE. It costs one connection per tagged parent --
-- five in this game -- it fires only when a child is added to a parent Model,
-- and it re-dresses on every re-stream, because the Sounds went out with the
-- root part they were parented to and the Heartbeat below has already dropped
-- the voice by then.
--
-- AND NOT task.defer, WHICH WAS THE FIRST VERSION AND THREW. Deferring and
-- calling itself again looks like "try again next frame" and is not:
-- task.defer resumes LATER IN THE SAME CYCLE, so it re-ran eighty times inside
-- one frame, never yielding long enough for a part to arrive, and died with
-- "Maximum re-entrancy depth (80) exceeded calling task.defer".
--==============================================================================
local track: (Instance) -> ()

local function watchFor(model: Model)
	if watching[model] then
		return
	end
	watching[model] = model.ChildAdded:Connect(function(child)
		if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
			track(model)
		end
	end)
end

-- The tag is gone, or the model is. Everything this client built for it goes.
local function forget(model: Model)
	local watcher = watching[model]
	if watcher then
		watcher:Disconnect()
		watching[model] = nil
	end
	untrack(model)
end

function track(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local model = instance :: Model
	if voices[model] then
		return
	end
	-- Before the early return as well as after it: a parent with no body yet is
	-- exactly the one that needs watching.
	watchFor(model)
	local rootInstance = model:FindFirstChild("HumanoidRootPart")
	if not (rootInstance and rootInstance:IsA("BasePart")) then
		return
	end
	local root = rootInstance :: BasePart

	--==========================================================================
	-- A RE-SYNC MUST NOT LEAVE TWO OF EACH
	--
	-- Rule 10. This script re-runs on a Rojo sync while the parents it dressed
	-- last time are still standing in the world wearing their Sounds, and two
	-- copies of a sleep loop a few milliseconds apart is a phasing noise that
	-- gets blamed on the recording.
	--==========================================================================
	for _, existing in ipairs(root:GetChildren()) do
		if existing:IsA("Sound") and string.sub(existing.Name, 1, 9) == "SeedLoop_" then
			existing:Destroy()
		end
	end

	--==========================================================================
	-- THE BIOME CHOOSES THE VOICE
	--
	-- A Brambleback breathes like a Brambleback and lands like two tons of it;
	-- Greenhollow's brute does neither. GameConfig.Sfx.ParentVoices holds which
	-- creature gets which row and SoundKit.parentCue does the falling back, so
	-- this reads one attribute and is told a cue name -- or nil, which is a
	-- parent that makes no sound rather than a bug.
	--
	-- BiomeId IS ALREADY HERE. Every builder sets it before it parents the
	-- model, so it replicates with the model rather than after it -- unlike the
	-- root part, which this function already had to wait for. If it were ever
	-- missing the worst case is the generic voice, not silence.
	--==========================================================================
	local biome = model:GetAttribute("BiomeId")
	local biomeId = if typeof(biome) == "string" then biome else nil
	local sleepName = SoundKit.parentCue(biomeId, "Sleep")
	local stepName = SoundKit.parentCue(biomeId, "Step")
	local stepCue = if stepName then SoundKit.cue(stepName) else nil
	local loopedStep = stepCue ~= nil and stepCue.looped == true
	local sleepSound = if sleepName then SoundKit.attach(sleepName, root) else nil
	local voice: Voice = {
		model = model,
		root = root,
		sleep = sleepSound,
		step = if stepName and loopedStep then SoundKit.attach(stepName, root) else nil,
		stepName = stepName,
		stepLooped = loopedStep,
		walked = 0,
		at = root.Position,
		stomp = nil,
		steppedAt = 0,
		sleeping = nil,
		sleepVolume = if sleepSound then sleepSound.Volume else 0,
		sleepFade = nil,
		state = nil,
		returnName = SoundKit.parentCue(biomeId, "Return"),
		back = nil,
	}
	voices[model] = voice
end

for _, model in ipairs(CollectionService:GetTagged(TAG)) do
	track(model)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
	if instance:IsA("Model") then
		forget(instance :: Model)
	end
end)

RunService.Heartbeat:Connect(function()
	if next(voices) == nil then
		return
	end
	for model, voice in pairs(voices) do
		if not voice.root.Parent then
			-- untrack, not forget: the body streamed out or was destroyed, and
			-- either way the watcher stays so that a body arriving again gets
			-- dressed again.
			untrack(model)
		else
			-- Written by NestService and replicated. Not-false rather than true:
			-- a parent that has not had the attribute set yet is one that has
			-- never been robbed, which is asleep.
			local awake = model:GetAttribute("Asleep") == false

			--==================================================================
			-- THE BREATHING, ON THE CHANGE ONLY (2026-09-27). It used to be set
			-- every frame (Playing = not awake), which paused a breath mid-sound
			-- and resumed it wherever it stopped. Now: lying down starts the loop
			-- from its top at its own level; waking lets the breath die away over
			-- a third of a second and stops it. A parent seen for the first time
			-- just takes the state it is in, with no fade.
			--==================================================================
			-- ASLEEP MEANS ParentState "asleep", where the guardian publishes one:
			-- `Asleep` only turns false when the chase begins, so keyed on it the
			-- breath went on for the whole second-long wake, under the roar
			-- (measured 2026-09-27). The steps below still use `awake` -- a
			-- guardian rising in place must not start its running loop.
			local shownState = model:GetAttribute("ParentState")
			local sleepingNow = if typeof(shownState) == "string"
				then shownState == "asleep"
				else not awake
			local sleep = voice.sleep
			if sleep and voice.sleeping ~= sleepingNow then
				local first = voice.sleeping == nil
				voice.sleeping = sleepingNow
				local fading = voice.sleepFade
				if fading then
					fading:Cancel()
					voice.sleepFade = nil
				end
				if sleepingNow then
					sleep.Volume = voice.sleepVolume
					sleep:Play()
				elseif first then
					sleep:Stop()
				else
					voice.sleepFade = fadeAway(sleep, SLEEP_FADE_SECONDS)
				end
			end

			--==================================================================
			-- THE WALK HOME (2026-09-27): one cue per trip, on the state change
			-- SoundKit.returnCueStep names -- never per step, never again when a
			-- walk becomes a haul, cut off by a fresh chase or a lie-down.
			--==================================================================
			local state = model:GetAttribute("ParentState")
			if typeof(state) == "string" and state ~= voice.state then
				local verdict = SoundKit.returnCueStep(voice.state, state, RETURN_AT)
				voice.state = state
				if verdict == "play" and voice.returnName then
					quietBack(voice, 0)
					voice.back = SoundKit.emit(voice.returnName, voice.root)
				elseif verdict == "fade" then
					quietBack(voice, RETURN_FADE_SECONDS)
				end
			end

			-- Ground covered, measured flat as ParentAnim measures its stride: a
			-- lurch or a hop is not a footfall.
			local here = voice.root.Position
			local dx, dz = here.X - voice.at.X, here.Z - voice.at.Z
			local moved = math.sqrt(dx * dx + dz * dz)
			voice.at = here

			if voice.stepLooped then
				if voice.step then
					voice.step.Playing = awake
				end
			elseif awake then
				voice.walked += moved
				local now = os.clock()
				if voice.walked >= STUDS_PER_STEP and voice.stepName
					and now - voice.steppedAt >= MIN_STEP_SECONDS then
					voice.walked = 0
					voice.steppedAt = now
					hush(voice)
					voice.stomp = SoundKit.emit(voice.stepName, voice.root)
				end
			else
				voice.walked = 0
				hush(voice)
			end
		end
	end
end)
