--!strict
--==============================================================================
-- Steal a Seed :: HatchHoldLock
-- HATCH TARGET LOCK (the owner's brief, 2026-10-08): the events around
-- PromptHoldLock. A hold that begins on a pod's Hatch -- keyboard E, a
-- controller's button, or a finger on PromptUI's panel (PromptUI calls
-- InputHoldBegin, so all three arrive here as PromptButtonHoldBegan) -- locks
-- that pod as the target until the hold ends. LOCAL ONLY: nothing is sent, and
-- PlantService still checks every hatch.
--
-- EVERY WAY A HOLD ENDS LETS GO:
--   let go, or completed            PromptButtonHoldEnded, PromptTriggered
--   out of the pod's range, the     PromptHidden of the held prompt (a teleport
--   panel hiding                    that lands out of range is the same)
--   the pod hatching, the prompt    the held prompt leaving the game, checked
--   destroyed, the plot resizing    every frame (a rebuilt plot is new prompts)
--   a death or a respawn            Humanoid.Died, CharacterRemoving / Added
--   anything missed                 the hold's own length plus Overrun
-- and every prompt the lock put out of reach gets its reach back.
--==============================================================================
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local PromptHoldLock = require(Shared:WaitForChild("PromptHoldLock"))

local player = Players.LocalPlayer

-- Every prompt in the world, kept as they come and go (and stream in and out):
-- what a lock looks through.
local prompts: { [ProximityPrompt]: boolean } = {}
for _, d in ipairs(Workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then
		prompts[d] = true
	end
end
Workspace.DescendantAdded:Connect(function(d: Instance)
	if d:IsA("ProximityPrompt") then
		prompts[d] = true
	end
end)
Workspace.DescendantRemoving:Connect(function(d: Instance)
	if d:IsA("ProximityPrompt") then
		prompts[d] = nil
	end
end)

local lock: PromptHoldLock.Lock? = nil

local function letGo()
	local current = lock
	lock = nil
	if current then
		PromptHoldLock.release(current)
	end
end

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt)
	if not PromptHoldLock.locks(prompt) then
		return
	end
	letGo()
	local fresh = PromptHoldLock.begin(prompt, os.clock())
	lock = fresh
	-- At once, not on the next frame: a nearer pod must not get one frame in
	-- which to take the key.
	PromptHoldLock.step(fresh, prompts, os.clock())
end)

local function endsHeld(prompt: ProximityPrompt)
	local current = lock
	if current and current.held == prompt then
		letGo()
	end
end
ProximityPromptService.PromptButtonHoldEnded:Connect(endsHeld)
ProximityPromptService.PromptTriggered:Connect(endsHeld)
ProximityPromptService.PromptHidden:Connect(endsHeld)

-- Newcomers and movers put out of reach as they come; the end checks.
RunService.Heartbeat:Connect(function()
	local current = lock
	if current and not PromptHoldLock.step(current, prompts, os.clock()) then
		letGo()
	end
end)

local function watchBody(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(letGo)
	end
end
player.CharacterRemoving:Connect(letGo)
player.CharacterAdded:Connect(function(character: Model)
	letGo()
	watchBody(character)
end)
if player.Character then
	task.spawn(watchBody, player.Character)
end
