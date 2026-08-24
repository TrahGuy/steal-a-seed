--!strict
-- Steal a Seed :: CarryPose
--
-- Both arms out under the pod while you are carrying one.
--
--==============================================================================
-- THE FIRST VERSION POSED JOINTS THAT DO NOT EXIST
--
-- It looked for Motor6D shoulders and composed against `C0`, which is how
-- Ambience moves the fairy and how ParentAnim moves the nest parent. Both of
-- those are rigs THIS REPO BUILDS, and both really do have Motor6Ds.
--
-- A modern Roblox avatar does not. The test account's character is:
--
--     AnimationConstraint x15, BallSocketConstraint x14, Motor6D x0
--
-- so `buildRig` found nothing, gave up silently, and the arms hung while the
-- pod floated in front of them. Measured, not assumed: a scan of the character
-- on both server and client returned zero joints of any class.
--
--==============================================================================
-- SO IT DRIVES WHATEVER THE RIG ACTUALLY HAS
--
--   AnimationConstraint  ->  .Transform, written every Stepped
--   Motor6D              ->  .C0, composed against a captured rest pose
--
-- The two behave differently and the difference matters. C0 composes UNDER the
-- animation, so a walk cycle still plays through it. `Transform` OVERRIDES the
-- animation for that joint -- verified by driving it and watching the hand move
-- 1.956 studs, then snap back 1.957 when released. For a carry that is what we
-- want anyway: arms that hold something should not also be swinging.
--
-- Written in `Stepped` rather than `Heartbeat` because that is after the
-- animation has been evaluated for the frame. Writing earlier loses the race.
--
--==============================================================================
-- WHICH AXIS SWINGS AN ARM FORWARD IS PER-RIG AND WAS MEASURED
--
-- Right shoulder, R15 AnimationConstraint, hand position in ROOT space:
--
--     rest       x +1.47  y -0.99  z -0.64
--     X +60 deg  x +1.26  y -0.06  z -1.63   <- FORWARD
--     Y +60 deg  x +1.02  y -1.02  z -0.67      barely moves
--     Z +60 deg  x +2.47  y +0.24  z -0.40      sideways and up
--
-- So X swings forward and Z spreads sideways. That is the OPPOSITE of R6, where
-- Ambience measured that a 90-degree yaw baked into every shoulder C0 makes X
-- slide the arm sideways and Z swing it. Two rigs, two answers, and guessing
-- either one gives you a character doing star jumps.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local CARRYING_KG = GameConfig.Attributes.CarryingKg

-- How fast the pose blends in and out. A snap reads as a glitch.
local BLEND = 9

type Side = {
	-- Exactly one of these two is set.
	constraint: AnimationConstraint?,
	motor: Motor6D?,
	rest: CFrame,
	-- +1 right, -1 left.
	sign: number,
}

type Rig = {
	sides: { Side },
	-- "constraint" | "motor6d-r15" | "motor6d-r6"
	kind: string,
	weight: number,
}

local rigs: { [Player]: Rig } = {}

--==============================================================================
-- FINDING WHATEVER THE SHOULDERS ARE
--==============================================================================
local function buildRig(character: Model): Rig?
	local sides: { Side } = {}

	-- 1. The modern physics rig.
	for _, entry in ipairs({ { "RightUpperArm", "RightShoulder", 1 },
		{ "LeftUpperArm", "LeftShoulder", -1 } }) do
		local part = character:FindFirstChild(entry[1] :: string)
		local joint = part and part:FindFirstChild(entry[2] :: string)
		if joint and joint:IsA("AnimationConstraint") then
			table.insert(sides, {
				constraint = joint, motor = nil,
				rest = joint.Transform, sign = entry[3] :: number,
			})
		end
	end
	if #sides == 2 then
		return { sides = sides, kind = "constraint", weight = 0 }
	end
	table.clear(sides)

	-- 2. Motor6D R15.
	local upper = character:FindFirstChild("UpperTorso")
	if upper then
		for _, entry in ipairs({ { "RightShoulder", 1 }, { "LeftShoulder", -1 } }) do
			local m = upper:FindFirstChild(entry[1] :: string)
			if m and m:IsA("Motor6D") then
				table.insert(sides, {
					constraint = nil, motor = m, rest = m.C0, sign = entry[2] :: number,
				})
			end
		end
		if #sides == 2 then
			return { sides = sides, kind = "motor6d-r15", weight = 0 }
		end
	end
	table.clear(sides)

	-- 3. Motor6D R6.
	local torso = character:FindFirstChild("Torso")
	if torso then
		for _, entry in ipairs({ { "Right Shoulder", 1 }, { "Left Shoulder", -1 } }) do
			local m = torso:FindFirstChild(entry[1] :: string)
			if m and m:IsA("Motor6D") then
				table.insert(sides, {
					constraint = nil, motor = m, rest = m.C0, sign = entry[2] :: number,
				})
			end
		end
		if #sides == 2 then
			return { sides = sides, kind = "motor6d-r6", weight = 0 }
		end
	end
	return nil
end

--==============================================================================
-- AIMING AT THE POD
--
-- Not a fixed pose: the arms follow the thing. GripForward puts a 1 kg pod 1.5
-- studs out and a 10,000 kg one 5.8, so one angle cannot serve both -- a pose
-- tuned for the small pod leaves the boulder held at the fingertips.
--
-- IT IS THE WEIGHT, NOT THE SPECIES. Every pod rolls its own now, so the form
-- says nothing about how far out it rides: two Nubkins can want two different
-- poses. Reading the species here would brace the arms for a 2 kg cube while
-- the player is carrying a 9,000 kg one.
--
-- Reach drives how far the shoulders swing forward, and how far apart. A big pod
-- needs the hands WIDER, not just further out, which is why the spread relaxes
-- as reach grows.
--==============================================================================
local function anglesFor(kg: number?): (number, number)
	local reach = if kg then SeedData.GripForward(kg) else 1.6
	-- 1.5 studs of reach -> ~57 deg, 5.8 -> clamped at 82. Clamped so no pod
	-- folds the arm back through the shoulder.
	local lift = math.clamp(43 + 9.2 * reach, 45, 82)
	-- Negative is inward. Small pods are hugged; big ones are braced.
	local spread = math.clamp(-24 + 6 * reach, -22, 4)
	return math.rad(lift), math.rad(spread)
end

local function track(player: Player)
	local function onCharacter(character: Model)
		rigs[player] = nil
		task.spawn(function()
			local deadline = os.clock() + 12
			local rig = buildRig(character)
			while not rig and character.Parent and os.clock() < deadline do
				task.wait(0.15)
				rig = buildRig(character)
			end
			if rig and character.Parent and player.Character == character then
				rigs[player] = rig
			elseif not rig then
				warn("[Seed/CarryPose] no shoulders found on " .. player.Name
					.. "'s rig; arms will not pose.")
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
-- A BANKED POD IS STILL A CARRIED POD
--
-- CarryingKg is set while you are running a stolen pod home and cleared the
-- INSTANT you bank it -- but the pod does not leave your hands when you bank it.
-- It becomes a Tool in your hotbar and you carry the same object onward. So the
-- attribute alone posed both arms under a pod you had stolen and dropped them
-- for one you owned, and the default Roblox tool animation took over: the same
-- pod, held two different ways depending on whose it was.
--
-- CarryService stamps the same CarryingKg on that Tool, and an equipped Tool is
-- parented INSIDE the character -- so this reads for every player on screen, not
-- only the local one, exactly like the attribute it falls back from.
--
-- The pose still wins over the tool animation: these are AnimationConstraint
-- Transforms written in Stepped, which is after the animator has run.
--==============================================================================
-- Returns the WEIGHT of whatever is being carried, or nil for empty hands. The
-- species id is not wanted here any more -- nothing about the pose depends on
-- the shape -- but the same two places still have to be checked, because the
-- attribute is only set during a raid and the Tool is what survives banking.
local function carriedKg(player: Player, character: Model): number?
	local attribute = player:GetAttribute(CARRYING_KG)
	if type(attribute) == "number" then
		return attribute
	end
	for _, d in ipairs(character:GetChildren()) do
		if d:IsA("Tool") then
			local kg = d:GetAttribute(CARRYING_KG)
			if type(kg) == "number" then
				return kg
			end
		end
	end
	return nil
end

--==============================================================================
-- THE POSE
--
-- Stepped, not Heartbeat: after the animation has been evaluated for the frame.
--==============================================================================
RunService.Stepped:Connect(function(_, dt)
	local alpha = math.min(1, dt * BLEND)
	for player, rig in pairs(rigs) do
		local character = player.Character
		if not character or not character.Parent then
			rigs[player] = nil
		else
			local kg = carriedKg(player, character)
			local want = if kg ~= nil then 1 else 0
			rig.weight += (want - rig.weight) * alpha
			if rig.weight < 0.002 and want == 0 then
				rig.weight = 0
			end

			if rig.weight > 0 then
				local lift, spread = anglesFor(kg)
				for _, side in ipairs(rig.sides) do
					local w = rig.weight
					local pose: CFrame
					if rig.kind == "motor6d-r6" then
						-- R6 swings on Z. Ambience measured this the hard way.
						pose = CFrame.Angles(0, 0, side.sign * lift * w)
					else
						-- R15, both joint kinds: X forward, Z spreads.
						pose = CFrame.Angles(lift * w, 0, side.sign * spread * w)
					end
					if side.constraint then
						-- OVERRIDES the animation for this joint, every frame.
						side.constraint.Transform = side.rest * pose
					elseif side.motor then
						-- Composes UNDER the animation.
						side.motor.C0 = side.rest * pose
					end
				end
			elseif rig.weight == 0 then
				-- Hand the joints back. A constraint left driven would freeze the
				-- arms mid-walk; a Motor6D would keep an offset forever.
				for _, side in ipairs(rig.sides) do
					if side.constraint and side.constraint.Transform ~= side.rest then
						side.constraint.Transform = side.rest
					elseif side.motor and side.motor.C0 ~= side.rest then
						side.motor.C0 = side.rest
					end
				end
			end
		end
	end
end)
