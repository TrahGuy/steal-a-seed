--!nocheck
--==============================================================================
-- Steal a Seed :: HatchLockSpec
-- HATCH TARGET LOCK (the owner's brief, 2026-10-08). Edit mode:
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchLockSpec"))
--
-- The owner's checks, on REAL ProximityPrompts in a scratch folder far above the
-- map (removed at the end) and the real PromptHoldLock:
--   the lock holds   a hold on a pod's Hatch puts every prompt that could be
--                    shown in its range out of reach -- a nearer pod appearing
--                    or moving in, Instant Hatch, the mill's sign -- and never
--                    the held one, never anything out of range
--   it lets go       on every end: released, the held prompt gone, overrun;
--                    and the client wires let-go, completed, hidden, died and
--                    respawned to it
--   nothing stays    after every case, no prompt is left out of reach; a reach
--   off              somebody else wrote meanwhile is the one given back;
--                    Enabled is never touched
--   Instant Hatch    never starts a lock, and is out of reach during one
-- Not here: real input on a real screen (the guarded Play).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local s = parent:FindFirstChild(name)
	return if s then s.Source else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

-- A fresh copy of the module, so an edit is always the one tested.
local function fresh(module)
	local copy = module:Clone()
	copy.Parent = module.Parent
	local ok, m = pcall(require, copy)
	copy:Destroy()
	return if ok then m else error(m)
end
local Lock = fresh(Shared:WaitForChild("PromptHoldLock"))

local RANGE = GameConfig.Plant.RangeStuds
local HOLD = GameConfig.Plant.HatchHoldSeconds
local BASE = Vector3.new(0, 4000, 0)

local old = Workspace:FindFirstChild("ZZHatchLockSpec")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "ZZHatchLockSpec"
root.Parent = Workspace

local function part(name, x, y, z)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(1, 1, 1)
	p.Position = BASE + Vector3.new(x, y, z)
	p.Parent = root
	return p
end
local function prompt(parent, name, reach, hold)
	local pr = Instance.new("ProximityPrompt")
	pr.Name = name
	pr.MaxActivationDistance = reach
	pr.HoldDuration = hold
	pr.Parent = parent
	return pr
end
-- Let deferred signal handlers run.
local function settle()
	task.wait()
	task.wait()
end

local ok, err = pcall(function()

--==============================================================================
-- 1. WHAT LOCKS
--==============================================================================
say("-- what locks --")
local A = prompt(part("PodA", 0, 0, 0), "HatchPrompt", RANGE, HOLD)
local B = prompt(part("PodB", 4, 0, 0), "HatchPrompt", RANGE, HOLD)
local C = prompt(part("PodC", 0, 0, 6), "InstantHatchPrompt", RANGE, 0)
local millSign = prompt(part("MillSign", 38, 0, 0), "UpgradePrompt", 12, 0)
local farPart = part("Far", 120, 0, 0)
local far = prompt(farPart, "TakePrompt", 10, 0)
local attHolder = part("Stall", 10, 0, 0)
local att = Instance.new("Attachment")
att.Position = Vector3.new(0, 2, 0)
att.Parent = attHolder
local onAtt = prompt(att, "SellPrompt", 12, 0)
local model = Instance.new("Model")
model.Name = "PodModel"
local primary = part("ModelRoot", -8, 0, 0)
primary.Parent = model
model.PrimaryPart = primary
model.Parent = root
local onModel = prompt(model, "HatchPrompt", RANGE, HOLD)

check(Lock.locks(A) and not Lock.locks(C) and not Lock.locks(millSign) and not Lock.locks(far),
	"a hold on a pod's Hatch locks; Instant Hatch (hold 0), the mill's sign and a Take never do")
check(Lock.positionOf(onAtt) == att.WorldPosition and Lock.positionOf(onModel) == primary.Position
		and Lock.positionOf(A) == A.Parent.Position,
	"a prompt stands at its part, its attachment's world position, or its model's primary part")

--==============================================================================
-- 2. THE LOCK HOLDS
--==============================================================================
say("\n-- the lock holds --")
local registry = { [A] = true, [B] = true, [C] = true, [millSign] = true, [far] = true, [onAtt] = true, [onModel] = true }
local lock = Lock.begin(A, 0)
check(Lock.step(lock, registry, 0.05) == true, "a fresh lock steps on")
check(B.MaxActivationDistance == 0 and onModel.MaxActivationDistance == 0,
	"the other pods' Hatch prompts are out of reach: a nearer pod cannot take the key")
check(C.MaxActivationDistance == 0, "Instant Hatch is out of reach too: it never takes a held pod's place")
check(millSign.MaxActivationDistance == 0 and onAtt.MaxActivationDistance == 0,
	"so is every other prompt that could be shown in the held pod's range (the mill's sign, 38 studs off)")
check(A.MaxActivationDistance == RANGE, "the held prompt keeps its reach")
check(far.MaxActivationDistance == 10, "a prompt that cannot be shown from the held pod's range is not touched")
check(Lock.count(lock) == 5, "five prompts held out of reach", Lock.count(lock))
local enabledAll = true
for pr in pairs(registry) do
	enabledAll = enabledAll and pr.Enabled
end
check(enabledAll, "Enabled is never touched")

-- A nearer pod appearing mid-hold, and one moving into range.
local N = prompt(part("PodNew", 2, 0, 0), "HatchPrompt", RANGE, HOLD)
registry[N] = true
farPart.Position = BASE + Vector3.new(30, 0, 0)
check(Lock.step(lock, registry, 0.4) == true and N.MaxActivationDistance == 0 and far.MaxActivationDistance == 0,
	"a nearer pod appearing mid-hold, and a prompt moving into range, are put out of reach at the next step")
-- Somebody else's writes mid-hold.
B.MaxActivationDistance = 15
C.Enabled = false
settle()
check(B.MaxActivationDistance == 0, "a reach the server writes mid-hold is kept for later: the prompt stays out of reach",
	B.MaxActivationDistance)

--==============================================================================
-- 3. IT LETS GO, AND NOTHING STAYS OFF
--==============================================================================
say("\n-- it lets go --")
local function zeroes()
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.MaxActivationDistance == 0 then
			n += 1
		end
	end
	return n
end
Lock.release(lock)
settle()
check(zeroes() == 0, "released: no prompt is left out of reach", zeroes())
check(B.MaxActivationDistance == 15, "the reach the server wrote mid-hold is the one given back", B.MaxActivationDistance)
check(C.MaxActivationDistance == RANGE and C.Enabled == false,
	"Instant Hatch gets its reach back; its Enabled is whatever the server set (off), untouched by the lock")
check(millSign.MaxActivationDistance == 12 and onAtt.MaxActivationDistance == 12 and onModel.MaxActivationDistance == RANGE
		and N.MaxActivationDistance == RANGE and far.MaxActivationDistance == 10,
	"every other prompt has exactly the reach it had")
B.MaxActivationDistance = 9
settle()
check(B.MaxActivationDistance == 9 and Lock.count(lock) == 0, "after the release nothing is watched any more")
local again = pcall(Lock.release, lock)
check(again and zeroes() == 0, "a second release is harmless")
check(Lock.step(lock, registry, 0.5) == false, "a released lock never steps again")
B.MaxActivationDistance = RANGE
C.Enabled = true
farPart.Position = BASE + Vector3.new(120, 0, 0)

-- The held prompt goes (the pod hatched, the prompt destroyed, the plot rebuilt).
local gone = Lock.begin(A, 0)
Lock.step(gone, registry, 0.1)
local podA = A.Parent
A.Parent = nil
check(Lock.step(gone, registry, 0.2) == false, "the held prompt leaving the game ends the lock")
Lock.release(gone)
settle()
check(zeroes() == 0, "... and nothing stays out of reach", zeroes())
A.Parent = podA

-- Overrun: the last guard.
local long = Lock.begin(A, 10)
check(Lock.step(long, registry, 10 + HOLD + Lock.Overrun - 0.05) == true
	and Lock.step(long, registry, 10 + HOLD + Lock.Overrun + 0.05) == false,
	string.format("a lock lasting longer than the hold plus %.1f s ends whatever happened", Lock.Overrun))
Lock.release(long)

-- A prompt held out of reach is destroyed mid-hold.
local mid = Lock.begin(A, 0)
Lock.step(mid, registry, 0.1)
local nPart = N.Parent
N:Destroy()
registry[N] = nil
local released = pcall(Lock.release, mid)
settle()
check(released and zeroes() == 0, "a prompt destroyed mid-hold does not stop the others getting their reach back")
nPart:Destroy()

-- A deferred own-write is never taken for somebody else's.
local deferred = Lock.begin(A, 0)
Lock.step(deferred, registry, 0.1)
settle()
check(deferred.off[B] == RANGE and deferred.off[C] == RANGE,
	"the lock's own 0, seen late by a deferred handler, is not kept as the reach to give back")
Lock.release(deferred)
settle()
check(zeroes() == 0 and B.MaxActivationDistance == RANGE, "... so the release gives back the real reach")

--==============================================================================
-- 4. THE CLIENT WIRES EVERY END TO IT
--==============================================================================
say("\n-- the client --")
local client = sourceOf(Scripts, "HatchHoldLock")
check(has(client, "PromptHoldLock.locks(prompt)") and has(client, "ProximityPromptService.PromptButtonHoldBegan:Connect"),
	"a hold beginning on a lockable prompt (keyboard, controller, or PromptUI's InputHoldBegin on touch) starts a lock")
check(has(client, "PromptHoldLock.step(fresh, prompts, os.clock())"), "the first step runs at once, not a frame later")
check(has(client, "ProximityPromptService.PromptButtonHoldEnded:Connect(endsHeld)")
		and has(client, "ProximityPromptService.PromptTriggered:Connect(endsHeld)")
		and has(client, "ProximityPromptService.PromptHidden:Connect(endsHeld)"),
	"let go, completed, and hidden (out of range, the panel hiding, a teleport away) all let go")
check(has(client, "player.CharacterRemoving:Connect(letGo)") and has(client, "humanoid.Died:Connect(letGo)")
		and has(client, "player.CharacterAdded:Connect"),
	"a death and a respawn let go")
check(has(client, "RunService.Heartbeat:Connect") and has(client, "not PromptHoldLock.step(current, prompts, os.clock())"),
	"every frame: newcomers put out of reach, and the held prompt gone or an overrun let go")
check(has(client, "Workspace.DescendantAdded:Connect") and has(client, "Workspace.DescendantRemoving:Connect"),
	"the client keeps every prompt in the world in view as they come and go")
local module = sourceOf(Shared, "PromptHoldLock")
check(not has(client, "FireServer") and not has(client, "InvokeServer") and not has(client, ".Enabled =")
		and not has(module, ".Enabled ="),
	"local only: nothing is sent, and Enabled is written nowhere")
local promptUI = sourceOf(Scripts, "PromptUI")
check(has(promptUI, "prompt:InputHoldBegin()") and has(promptUI, "prompt:InputHoldEnd()"),
	"touch holds go through the engine's hold (PromptUI), so they lock and let go exactly like E")

--==============================================================================
-- 5. THE SERVER IS UNCHANGED
--==============================================================================
say("\n-- the server --")
local plant = sourceOf(Server, "PlantService")
check(has(plant, "prompt.Name = \"HatchPrompt\"") and has(plant, "prompt.HoldDuration = HATCH_HOLD")
		and has(plant, "prompt.Name = \"InstantHatchPrompt\"") and has(plant, "prompt.HoldDuration = 0"),
	"the Hatch prompt is still the named 1.1 s hold the lock looks for; Instant Hatch still holds 0")
check(has(plant, "PlantService.HatchByHand(player, entry.plot, entry.id)") and HOLD == 1.1,
	"every hatch is still the server's HatchByHand, and the hold is still 1.1 s")

end)
root:Destroy()
if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end

say(string.format("\nHatchLockSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
