--!strict
-- Steal a Seed :: CarryPose
--
-- Both arms out, under the pod, while you are carrying one.
--
--==============================================================================
-- WHY THE ARMS NEED SAYING AT ALL
--
-- The server welds the pod in front of HumanoidRootPart. That alone puts the
-- object in the right place and leaves the player's arms hanging at their
-- sides, so a 110 kg Bellchime floats in front of somebody strolling with their
-- hands in their pockets. The weld makes it CARRIED; this makes it HELD.
--
--==============================================================================
-- C0, NOT Transform -- THE SAME REASON AMBIENCE USES C0
--
-- Transform is the field Roblox's own Animator writes every frame, so a pose
-- put there is erased by the walk cycle before it is ever drawn. C0 is a plain
-- joint property that composes UNDER the animation: the walk still plays, and
-- the arms play it from a raised rest position.
--
-- Captured once per joint and composed against, never read back and re-derived
-- -- reading the current C0 to compute the next one feeds each frame's rounding
-- into the following one and the arms drift.
--
--==============================================================================
-- IT DRAWS EVERY PLAYER, NOT JUST YOU
--
-- CarryingSpecies is a Player attribute and attributes replicate on their own,
-- so this poses whoever is carrying. Somebody sprinting past with a pod should
-- look like they are holding it from the outside too -- that is the whole read
-- of a chase you are not in.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))
local CARRYING = GameConfig.Attributes.CarryingSpecies

-- How far the shoulders swing forward, in radians. Enough to read as "holding",
-- short of the zombie salute.
local LIFT = math.rad(58)
-- Elbows in, so the arms cradle rather than present.
local TUCK = math.rad(9)
-- How fast the pose blends in and out. A snap looks like a glitch; this is
-- about a fifth of a second.
local BLEND = 9

type Rig = {
	joints: { { motor: Motor6D, rest: CFrame, side: number } },
	weight: number,
}

local rigs: { [Player]: Rig } = {}

--==============================================================================
-- FINDING THE SHOULDERS, R6 AND R15
--
-- Different rigs, different joint names, different parents. Named rather than
-- searched by class, because a character contains a dozen Motor6Ds and posing
-- the wrong two is how a player ends up walking with their hips rotated.
--==============================================================================
local R6 = { { "Torso", "Right Shoulder", 1 }, { "Torso", "Left Shoulder", -1 } }
local R15 = { { "UpperTorso", "RightShoulder", 1 }, { "UpperTorso", "LeftShoulder", -1 } }

local function buildRig(character: Model): Rig?
	local joints = {}
	for _, set in ipairs({ R15, R6 }) do
		for _, entry in ipairs(set) do
			local parent = character:FindFirstChild(entry[1] :: string)
			local motor = parent and parent:FindFirstChild(entry[2] :: string)
			if motor and motor:IsA("Motor6D") then
				table.insert(joints, {
					motor = motor,
					rest = motor.C0,
					side = entry[3] :: number,
				})
			end
		end
		if #joints > 0 then
			-- Whichever rig matched first wins; do not mix the two.
			break
		end
	end
	if #joints == 0 then
		return nil
	end
	return { joints = joints, weight = 0 }
end

local function track(player: Player)
	local function onCharacter(character: Model)
		rigs[player] = nil
		task.spawn(function()
			-- The joints arrive a beat after the character does.
			local deadline = os.clock() + 10
			local rig = buildRig(character)
			while not rig and character.Parent and os.clock() < deadline do
				task.wait(0.15)
				rig = buildRig(character)
			end
			if rig and character.Parent and player.Character == character then
				rigs[player] = rig
			end
		end)
	end
	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
	track(player)
end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(player)
	rigs[player] = nil
end)

--==============================================================================
-- THE POSE
--==============================================================================
RunService.Heartbeat:Connect(function(dt)
	local alpha = math.min(1, dt * BLEND)
	for player, rig in pairs(rigs) do
		local character = player.Character
		if not character or not character.Parent then
			rigs[player] = nil
		else
			local want = if player:GetAttribute(CARRYING) ~= nil then 1 else 0
			-- Blend even when already there, so a pose interrupted mid-way
			-- always finishes rather than sticking part-raised.
			rig.weight += (want - rig.weight) * alpha
			if rig.weight < 0.001 and want == 0 then
				rig.weight = 0
			end
			for _, joint in ipairs(rig.joints) do
				if joint.motor.Parent then
					joint.motor.C0 = joint.rest
						* CFrame.Angles(LIFT * rig.weight, 0, joint.side * TUCK * rig.weight)
				end
			end
		end
	end
end)
