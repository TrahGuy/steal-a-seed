--!strict
-- Steal a Seed :: FairyService
--
-- Walks Marigold around behind her stall.
--
--==============================================================================
-- WHY THIS ONE IS ON THE SERVER, WHEN THE WINGS ARE NOT
--
-- Everything else that moves for decoration in this game moves on the client,
-- for good reasons written up in Ambience.client.luau. Walking is the exception,
-- and not arbitrarily:
--
--   A Humanoid IS a server-simulated thing. `MoveTo` drives real physics, real
--   ground detection and a real state machine. Faking a walk on each client
--   would mean every player seeing her in a different place -- fine for a
--   hovering sprite nobody can touch, not fine for a character standing on a
--   floor who will one day have a shop prompt attached to her.
--
-- So the SERVER walks her and each CLIENT flaps her wings and swings her limbs.
-- The two never write the same property: the server owns her root's position,
-- the client owns Motor6D.Transform. That split is why they cannot fight.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local FairyService = {}
-- After MapService (1), which is what builds and tags her.
FairyService.Priority = 30

-- How far she wanders either side of where she was placed, and how long she
-- pauses on arrival. The pause is most of what makes her look like somebody
-- working rather than a patrol: a character that never stops reads as a guard.
local WANDER_X = 6.5
local WANDER_Z = 2.2
local PAUSE_MIN = 1.8
local PAUSE_MAX = 4.5
-- If she has not arrived in this long she is stuck on something. Re-issuing the
-- move is cheaper and more robust than working out what she caught on.
local MOVE_TIMEOUT = 6

local running: { [Model]: boolean } = {}

local function log(message: string)
	print("[Seed/FairyService] " .. message)
end

--==============================================================================
-- ONE FAIRY'S LOOP
--
-- Deliberately a coroutine per fairy rather than one central loop over a table.
-- Each one spends nearly all of its life yielded inside a wait, which costs
-- nothing, and the alternative -- a shared loop tracking each fairy's pause
-- deadline and move state by hand -- is a state machine written out longhand to
-- save a thread that was never expensive.
--==============================================================================
local function walkLoop(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	if not (humanoid and root) then
		warn("[Seed/FairyService] " .. model:GetFullName() .. " has no Humanoid or PrimaryPart.")
		return
	end

	-- Home is where MapService put her. Captured ONCE: reading it live would
	-- mean her wander area follows her, and she would walk out of the stall one
	-- step at a time.
	local home = root.Position
	local facing = root.CFrame.LookVector
	local right = root.CFrame.RightVector

	-- Seeded from her position so every server sends her the same way. She is a
	-- shared world object; two players describing where she is should agree.
	local rng = Random.new(math.floor(home.X * 7 + home.Z * 13))

	while running[model] and model.Parent and humanoid.Health > 0 do
		local target = home
			+ right * rng:NextNumber(-WANDER_X, WANDER_X)
			+ facing * rng:NextNumber(-WANDER_Z, WANDER_Z)

		humanoid:MoveTo(target)

		-- MoveToFinished fires on arrival OR on its own 8-second timeout, so the
		-- result is checked rather than assumed -- a fairy wedged behind a crate
		-- would otherwise stand there forever waiting for an arrival that is
		-- never coming.
		local reached = humanoid.MoveToFinished:Wait()
		if not reached then
			-- Nudge her back toward the middle rather than retrying the same
			-- unreachable spot.
			humanoid:MoveTo(home)
			humanoid.MoveToFinished:Wait()
		end

		task.wait(rng:NextNumber(PAUSE_MIN, PAUSE_MAX))
	end

	running[model] = nil
end

local function start(model: Instance)
	if not model:IsA("Model") or running[model] then
		return
	end
	running[model] = true
	task.spawn(walkLoop, model)
end

function FairyService.Start()
	for _, m in ipairs(CollectionService:GetTagged(GameConfig.Tags.Fairy)) do
		start(m)
	end
	CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Fairy):Connect(start)
	CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Fairy):Connect(function(m)
		running[m] = nil
	end)

	local n = #CollectionService:GetTagged(GameConfig.Tags.Fairy)
	log(string.format("Ready. %d fairy(s) walking, %.0f x %.0f studs of wander.",
		n, WANDER_X * 2, WANDER_Z * 2))
end

return FairyService
