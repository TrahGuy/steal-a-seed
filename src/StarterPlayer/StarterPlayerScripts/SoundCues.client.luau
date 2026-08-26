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
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
-- THE REVEAL
--
-- THE HATCH IS THE ONLY MOMENT THIS GAME REVEALS ANYTHING. A pod is anonymous
-- from the nest to the ground to the shell breaking -- the hotbar says ???, the
-- Garden says ???, and the pod's colour is its WEIGHT and not its species. So
-- the sound that plays when the shell opens is carrying the whole payoff of the
-- feature.
--
-- WHY IT IS NOT SIMPLY "A HATCHED TOOL ARRIVED". Three different things put a
-- hatched Tool in the Backpack: the hatch, picking a grown plant back up, and a
-- rejoin restoring the hotbar. The last one puts SEVERAL in at once, which
-- without a guard would greet every returning player with a fanfare per plant
-- they happened to be holding when they left.
--
-- So the prompt opens a window and the Tool has to arrive inside it.
-- PromptTriggered on the client fires for the local player only, and the prompt
-- that hatches is the only one named HatchPrompt -- Pick Up is PickupPrompt for
-- exactly this kind of reason.
--==============================================================================
local revealUntil = 0
-- Generous. It covers the server round trip, the model build and a bad frame,
-- and the only thing a too-long window can do is let a PICK UP within four
-- seconds of a hatch borrow the fanfare -- which is a sound in the right family
-- at the wrong moment, not a wrong sound.
local REVEAL_WINDOW = 4

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if prompt.Name == "HatchPrompt" then
		revealUntil = os.clock() + REVEAL_WINDOW
	end
end)

local REVEAL_FOR: { [string]: string } = (SFX.RevealFor :: any)

local function onTool(tool: Instance)
	if not tool:IsA("Tool") or tool:GetAttribute("Hatched") ~= true then
		return
	end
	if os.clock() > revealUntil then
		return
	end
	revealUntil = 0

	local id = tool:GetAttribute("SpeciesId")
	local species = if type(id) == "string" then SeedData.Get(id) else nil
	--==========================================================================
	-- THE FORM'S RARITY, NOT THE WEIGHT BAND
	--
	-- Two vocabularies in this game share four words. What the hatch reveals is
	-- the SHAPE -- which is what the Index spells and what the tooltip prints --
	-- and not SeedData.RarityForKg, which is how heavy this particular one is
	-- and is already legible as the colour of the shell.
	--==========================================================================
	local rarity = if species then species.Rarity else "Common"
	SoundKit.play(REVEAL_FOR[rarity] or "RevealCommon")
end

local function watch(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		onTool(child)
	end
	container.ChildAdded:Connect(onTool)
end

do
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		watch(backpack)
	end
	--==========================================================================
	-- THE BACKPACK IS REPLACED ON EVERY RESPAWN
	--
	-- Not emptied -- replaced. A connection to the one that existed at join is a
	-- connection to an instance nothing puts anything in any more, which is a
	-- reveal that works exactly until the first time somebody dies.
	--==========================================================================
	player.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Backpack") then
			watch(child)
		end
	end)
	-- And a Tool goes straight to the CHARACTER when it is equipped, which is
	-- where the hatch's own Tool lands if the player had an empty hand.
	local function watchCharacter(character: Model)
		watch(character)
	end
	if player.Character then
		watchCharacter(player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
end

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
-- single step every couple of studs COVERED.
--
-- Distance and not wall-clock, which is the same rule ParentAnim's stride uses
-- and for the same reason: a clock-driven step slides its feet when the parent
-- is slow and sprints on the spot when it has stopped. Distance keeps a foot on
-- the ground at any speed, and the parent's speed rises with every theft.
--==============================================================================
local TAG = GameConfig.Tags.NestParent
-- ParentAnim swings a whole stride every ~4 studs, so half that is a step.
local STUDS_PER_STEP = 2.2

type Voice = {
	model: Model,
	root: BasePart,
	sleep: Sound?,
	step: Sound?,
	stepLooped: boolean,
	walked: number,
	at: Vector3,
}

local voices: { [Model]: Voice } = {}
-- Models being waited on. Without it, a tag that fires twice starts two waiters
-- on the same parent and it ends up wearing two of each Sound.
local pending: { [Model]: boolean } = {}

local function untrack(model: Model)
	pending[model] = nil
	local voice = voices[model]
	if voice then
		if voice.sleep then
			voice.sleep:Destroy()
		end
		if voice.step then
			voice.step:Destroy()
		end
		voices[model] = nil
	end
end

local function track(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local model = instance :: Model
	if voices[model] then
		return
	end
	local rootInstance = model:FindFirstChild("HumanoidRootPart")
	if not (rootInstance and rootInstance:IsA("BasePart")) then
		--======================================================================
		-- WaitForChild, NOT task.defer. MEASURED, AND IT THREW.
		--
		-- The tag reaches a client BEFORE the rig does -- the parent is 87 parts
		-- and they replicate over several frames, so GetInstanceAddedSignal
		-- fires on a Model that is still nearly empty.
		--
		-- The first version of this deferred and called itself again, which
		-- looks like "try again next frame" and is not. task.defer resumes
		-- LATER IN THE SAME CYCLE, so it re-ran eighty times inside one frame,
		-- never yielding long enough for a single part to arrive, and died:
		--
		--     Maximum re-entrancy depth (80) exceeded calling task.defer
		--       Script 'SoundCues', Line 248 - function track
		--
		-- Which left the sleeping parent silent on any client that saw it
		-- appear, and only on those -- a nest present at join was fine, so this
		-- would have looked intermittent.
		--
		-- WaitForChild actually yields, so one waiter costs one thread and ends
		-- either when the part arrives or after ten seconds.
		--======================================================================
		if pending[model] then
			return
		end
		pending[model] = true
		task.spawn(function()
			local found = model:WaitForChild("HumanoidRootPart", 10)
			pending[model] = nil
			if found and found:IsA("BasePart") and model.Parent and not voices[model] then
				track(model)
			end
		end)
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

	local stepCue = SoundKit.cue("ChaseStep")
	local voice: Voice = {
		model = model,
		root = root,
		sleep = SoundKit.attach("ParentSleep", root),
		step = if stepCue and stepCue.looped then SoundKit.attach("ChaseStep", root) else nil,
		stepLooped = stepCue ~= nil and stepCue.looped == true,
		walked = 0,
		at = root.Position,
	}
	voices[model] = voice
end

for _, model in ipairs(CollectionService:GetTagged(TAG)) do
	track(model)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
	if instance:IsA("Model") then
		untrack(instance)
	end
end)

RunService.Heartbeat:Connect(function()
	if next(voices) == nil then
		return
	end
	for model, voice in pairs(voices) do
		if not voice.root.Parent then
			untrack(model)
		else
			-- Written by NestService and replicated. Not-false rather than true:
			-- a parent that has not had the attribute set yet is one that has
			-- never been robbed, which is asleep.
			local awake = model:GetAttribute("Asleep") == false

			if voice.sleep then
				voice.sleep.Playing = not awake
			end

			local here = voice.root.Position
			local moved = (here - voice.at).Magnitude
			voice.at = here

			if voice.stepLooped then
				if voice.step then
					voice.step.Playing = awake
				end
			elseif awake then
				voice.walked += moved
				if voice.walked >= STUDS_PER_STEP then
					voice.walked = 0
					SoundKit.emit("ChaseStep", voice.root)
				end
			else
				voice.walked = 0
			end
		end
	end
end)
