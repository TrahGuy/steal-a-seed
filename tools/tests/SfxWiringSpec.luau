--!nocheck
--==============================================================================
-- Steal a Seed :: SfxWiringSpec
--
-- The eighteen cues added on the evening of 2026-09-17, and the moments they are
-- attached to. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SfxWiringSpec"))
--
-- WHY A SECOND SOUND SPEC. ParentVoiceSpec is about WHOSE voice a cue is --
-- five creatures, four roles, and the falling back between them. This one is
-- about WHETHER A MOMENT HAS ONE: a trap going off, a bat landing, a pod hitting
-- the ground, a shell cracking, a bag being sold. Different question, different
-- failure, and mixing them would make one long spec nobody reads the middle of.
--
-- THE THREE FAILURES IT IS BUILT AROUND:
--
--   1. A WINDOW OFF THE END OF THE ASSET. start + clip is checked against the
--      measured length of the file the id came from. Every duration below was
--      confirmed twice: off the WAV in sfx/, and off the uploaded asset's own
--      TimeLength in Studio. All eighteen agreed to the hundredth.
--
--   2. A BORROWED SOUND LEFT BEHIND. Six of these moments were playing SOMETHING
--      ELSE until tonight -- the trap spring and the bat impact both used the
--      parent's Grab, the placement used TakePod, the sell used MillUpgrade, and
--      PanelClose was PanelOpen pitched up 6%. Each of those is asserted to be
--      gone, by source, because a stand-in that outlives its replacement is
--      invisible: it makes a sound, just the wrong one.
--
--   3. A POINTER TO NOWHERE. Each trap spec names its spring cue and
--      GameConfig.Plant.Hatch.Sounds names three more. A name that is not a row
--      is silence, so every pointer is followed here.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))

local pass, fails = 0, {}
local out = {}

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		table.insert(fails, label)
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local CUES = GameConfig.Sfx.Cues

--==============================================================================
-- 1. THE EIGHTEEN ROWS
--
-- name, asset id, the measured length of the file, and the bus it belongs on.
-- The id is written down here as well as in GameConfig so that re-pointing a
-- moment at a different recording has to be a deliberate change in two places.
--==============================================================================
say("-- the eighteen rows --")

local ROWS = {
	{ "TrapPlace", "73333240019513", 1.00, "World" },
	{ "TrapArmed", "85062135388466", 2.00, "World" },
	{ "TrapSpringBramblejaw", "113454656665508", 2.00, "World" },
	{ "TrapSpringDunesnap", "135633126454821", 1.00, "World" },
	{ "TrapSpringMirecoil", "94258758905177", 2.00, "World" },
	{ "TrapSpringCinderburst", "74420052751382", 2.00, "World" },
	{ "TrapSpringStarlock", "94296728955633", 2.00, "World" },
	{ "BatSwing", "127465264913354", 2.00, "World" },
	{ "BatImpact", "120499284760036", 1.00, "World" },
	{ "PodDrop", "119713147046244", 2.00, "World" },
	{ "ColossalPickup", "130996586864709", 4.00, "World" },
	{ "HatchRattle", "113736151394399", 2.00, "World" },
	{ "HatchCrack", "125982914448542", 2.00, "World" },
	{ "HatchTimeSkip", "77501647710630", 2.00, "UI" },
	{ "ParentWakeEmberroot", "80131277872397", 2.00, "World" },
	{ "ParentWakeStarbloom", "138701632491162", 1.00, "World" },
	{ "SellAll", "70521588661081", 0.88, "World" },
	{ "PanelClose", "98956134010999", 0.88, "UI" },
}

local seen = {}
for _, row in ipairs(ROWS) do
	local name, id, seconds, bus = row[1], row[2], row[3], row[4]
	local cue = CUES[name]
	check(cue ~= nil, name .. " has a row")
	if cue then
		check(cue.id == "rbxassetid://" .. id, name .. " names its own asset", cue.id)
		check(SoundKit.cue(name) ~= nil, name .. " resolves to a playable cue")
		check((cue.group or "UI") == bus, name .. " is on the " .. bus .. " bus", cue.group)

		local start = cue.start or 0
		check(start >= 0 and start < seconds, name .. " starts inside its asset", start)
		if cue.clip then
			check(start + cue.clip <= seconds + 0.001,
				string.format("%s's window ends inside the asset (%.2f + %.2f <= %.2f)",
					name, start, cue.clip, seconds))
		end
		check(type(cue.volume) == "number" and cue.volume > 0 and cue.volume <= 2,
			name .. " has a level inside the band", cue.volume)
		if bus == "World" then
			check(type(cue.range) == "number" and cue.range >= 40 and cue.range <= 200,
				name .. " carries a sensible distance", cue.range)
		else
			check(cue.range == nil, name .. " is 2D, so it names no distance", cue.range)
		end
		check(seen[cue.id] == nil, name .. " does not reuse another row's asset", seen[cue.id])
		seen[cue.id] = name
	end
end

--==============================================================================
-- 2. THE ONE THAT IS NOT CLIPPED, AND WHY
--
-- The Starlock never goes quiet: its noise floor is -20 dB where every other
-- file in the folder sits below -63, because it is a sustained hum with the lock
-- inside it rather than a hit and a decay. Clipping it would cut a held note off
-- mid-ring. Written down so that "why has this one no window" has an answer.
--==============================================================================
say("\n-- the sustained one --")
check(CUES.TrapSpringStarlock ~= nil and CUES.TrapSpringStarlock.clip == nil,
	"the Starlock plays its whole two seconds",
	CUES.TrapSpringStarlock and CUES.TrapSpringStarlock.clip)
check(CUES.TrapSpringStarlock ~= nil
		and (CUES.TrapSpringStarlock.clip == nil)
		and WeaponData.TrapSpec("starlock_trap") ~= nil
		and WeaponData.TrapSpec("starlock_trap").EffectSeconds >= 2.0,
	"and the effect it belongs to outlasts it")

--==============================================================================
-- 3. EVERY TRAP NAMES ITS OWN SPRING, AND NO TWO SHARE ONE
--
-- The pointer lives in the trap's spec beside its radius and its cooldown, and
-- WeaponData refuses to load if it names a row that does not exist -- so by the
-- time this spec runs, the interesting question is no longer "does it resolve"
-- but "is it the trap's OWN".
--==============================================================================
say("\n-- five traps, five springs --")

local EXPECTED_SPRING = {
	bramblejaw_trap = "TrapSpringBramblejaw",
	dunesnap_trap = "TrapSpringDunesnap",
	mirecoil_trap = "TrapSpringMirecoil",
	cinderburst_trap = "TrapSpringCinderburst",
	starlock_trap = "TrapSpringStarlock",
}

local usedCue, traps = {}, 0
for id, want in pairs(EXPECTED_SPRING) do
	local spec = WeaponData.TrapSpec(id)
	traps += 1
	check(spec ~= nil and spec.SpringCue == want, id .. " springs with " .. want,
		spec and spec.SpringCue)
	if spec and spec.SpringCue then
		check(usedCue[spec.SpringCue] == nil, id .. "'s spring is its own, not a shared one",
			usedCue[spec.SpringCue])
		usedCue[spec.SpringCue] = id
		check(SoundKit.cue(spec.SpringCue) ~= nil,
			id .. "'s spring cue is a playable row")
	end
end
check(traps == 5, "all five traps were checked", traps)

--==============================================================================
-- 4. THE HATCH'S THREE, WHICH WERE EMPTY STRINGS BY DESIGN
--==============================================================================
say("\n-- the hatch --")

local SOUNDS = GameConfig.Plant.Hatch.Sounds
check(SOUNDS.Rattle == "HatchRattle" and SoundKit.cue(SOUNDS.Rattle) ~= nil,
	"the hold rattles", SOUNDS.Rattle)
check(SOUNDS.Crack == "HatchCrack" and SoundKit.cue(SOUNDS.Crack) ~= nil,
	"the burst cracks", SOUNDS.Crack)
check(SOUNDS.TimeSkip == "HatchTimeSkip" and SoundKit.cue(SOUNDS.TimeSkip) ~= nil,
	"the paid hatch has its pulse", SOUNDS.TimeSkip)
check(CUES.HatchRattle ~= nil and CUES.HatchRattle.clip ~= nil
		and CUES.HatchRattle.clip <= GameConfig.Plant.HatchHoldSeconds,
	"the rattle ends inside the hold rather than under the reveal",
	CUES.HatchRattle and CUES.HatchRattle.clip)
check(CUES.HatchTimeSkip ~= nil and CUES.HatchTimeSkip.group == "UI",
	"the paid pulse is a receipt on your own screen, not a sound in the world",
	CUES.HatchTimeSkip and CUES.HatchTimeSkip.group)

--==============================================================================
-- 5. THE POD NAMES ITS OWN PICKUP
--
-- CreatureModel stamps the attribute; CarryService reads it at the take. Both
-- ends are checked, because either one alone is a no-op that looks wired.
--==============================================================================
say("\n-- the Colossal --")

local function sourceOf(instance)
	if not instance then
		return nil
	end
	local ok, src = pcall(function()
		return (instance :: any).Source
	end)
	return if ok then src else nil
end

local creature = sourceOf(Shared:FindFirstChild("CreatureModel"))
local stamped = creature and string.match(creature,
	'SetAttribute%("PickupSound",%s*"([%w_]+)"%)')
check(stamped ~= nil, "CreatureModel stamps a pickup cue on the pod it belongs to", stamped)
check(stamped ~= nil and CUES[stamped] ~= nil,
	"and the name it stamps is a row in the table", stamped)
check(stamped == "ColossalPickup", "which is the Colossal's", stamped)

local server = ServerScriptService:FindFirstChild("SeedGameServer")
local carry = sourceOf(server and server:FindFirstChild("CarryService"))
check(carry ~= nil and carry:find('pod:GetAttribute("PickupSound")', 1, true) ~= nil,
	"CarryService reads it, before the pod is destroyed")
check(carry ~= nil and carry:find('SoundKit.has(pickupCue)', 1, true) ~= nil,
	"and falls back to the ordinary shell if that row is not wired")

--==============================================================================
-- 6. NO STAND-IN OUTLIVED ITS REPLACEMENT
--
-- Six moments were playing a borrowed sound this morning. A stand-in left behind
-- is the hardest kind of wrong to notice, because the moment is not silent.
--==============================================================================
say("\n-- the borrowed sounds are given back --")

local combat = sourceOf(server and server:FindFirstChild("CombatService"))
local sell = sourceOf(server and server:FindFirstChild("SellService"))

check(combat ~= nil and combat:find('SoundKit.emit("TrapPlace"', 1, true) ~= nil,
	"a trap going down plays the placement, not TakePod")
check(combat ~= nil and combat:find('SoundKit.emit("TrapArmed"', 1, true) ~= nil,
	"and says once when it arms")
check(combat ~= nil and combat:find('SoundKit.emit(spec.SpringCue or "Grab"', 1, true) ~= nil,
	"and springs with its own cue")
check(combat ~= nil and combat:find('SoundKit.emit("BatSwing"', 1, true) ~= nil,
	"the bat has a whoosh")
check(combat ~= nil and combat:find('SoundKit.emit("BatImpact"', 1, true) ~= nil,
	"and an impact of its own")
check(combat ~= nil and combat:find('SoundKit.emit("Grab"', 1, true) == nil,
	"and CombatService borrows the guardian's hand for nothing at all")
check(combat ~= nil and combat:find('SoundKit.emit("TakePod", model', 1, true) == nil,
	"nothing in combat plays a pod being taken")
check(sell ~= nil and sell:find('SoundKit.emit("SellAll", board)', 1, true) ~= nil
		and sell:find('SoundKit.emit("MillUpgrade"', 1, true) == nil,
	"the sell-all board rings its own till instead of the mill's")
check(carry ~= nil and carry:find('SoundKit.emit("PodDrop", landed)', 1, true) ~= nil,
	"a pod landing on the road is heard landing")

check(CUES.PanelOpen ~= nil and CUES.PanelClose ~= nil
		and CUES.PanelClose.id ~= CUES.PanelOpen.id,
	"the panel closes with its own recording",
	CUES.PanelClose and CUES.PanelClose.id)
check(CUES.PanelClose ~= nil and CUES.PanelClose.pitch == nil,
	"and is no longer the open pitched up to disguise it",
	CUES.PanelClose and CUES.PanelClose.pitch)

--==============================================================================
-- 7. THE ARMING TICK IS AN EDGE, NOT A STATE
--
-- The branch it sits in runs every frame for the whole life of the trap. Without
-- the flag it would be a sixty-hertz buzz for twenty seconds -- the kind of bug
-- that is obvious in Play and invisible in a diff.
--==============================================================================
say("\n-- said once --")
check(combat ~= nil and combat:find("if not trap.armed then", 1, true) ~= nil
		and combat:find("trap.armed = true", 1, true) ~= nil,
	"the arming cue is gated on an edge the trap remembers")
check(combat ~= nil and combat:find("armed = false,", 1, true) ~= nil,
	"and every trap starts having not said it")

if #fails > 0 then
	return ("SfxWiringSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails,
		table.concat(fails, "\n  "))
end
return ("SfxWiringSpec: %d passed, 0 failed"):format(pass)
