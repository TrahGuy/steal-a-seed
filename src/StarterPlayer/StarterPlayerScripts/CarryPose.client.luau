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
-- Which carries ride over the head (2026-10-03): PlantForms.CarriedOverhead.
local PlantForms = require(Shared:WaitForChild("PlantForms"))

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
	--==========================================================================
	-- THE ELBOWS AND WRISTS, FOR THE OVERHEAD CARRY ONLY -- 2026-10-01
	--
	-- A pod in front of the chest leaves the lower arms to the animation, and
	-- this script does not touch them; a secret held OVER the head (SeedData
	-- Carry = "overhead") needs both arms straight up, so only while that pose
	-- has weight are these joints blended from the animator's value toward an
	-- identity Transform. `rest` is kept for the Side shape and not used.
	--==========================================================================
	straight: { Side },
	-- "constraint" | "motor6d-r15" | "motor6d-r6"
	kind: string,
	weight: number,
	-- Whether the current carry is the overhead one. Blended with `weight`.
	overhead: number,
	--==========================================================================
	-- WHETHER THE JOINTS HAVE ALREADY BEEN HANDED BACK
	--
	-- Releasing an AnimationConstraint means WRITING TO IT ONCE AND THEN LEAVING
	-- IT ALONE. Without this latch the release branch below wrote `rest` on every
	-- single frame, which is not a release at all -- see the block there.
	--==========================================================================
	released: boolean,
}

local rigs: { [Player]: Rig } = {}

--==============================================================================
-- THE NEUTRAL IS NEVER READ OFF A PLAYING ANIMATION (2026-10-03)
--
-- `rest` used to be whatever the joint held the frame the rig was built. After
-- a death the character comes back and the Bag hands the held Tool straight
-- back into the hand, so the rig was often built WHILE the tool-hold animation
-- had the right arm raised forward -- and every carry after that was posed on
-- top of it: the overhead right arm came out low and behind (the left, which
-- that animation does not move, stayed right). Measured 2026-10-03, the same
-- for a hatched plant and a Secret pod.
--
--   AnimationConstraint  identity, its true neutral: the animator writes an
--                        absolute local Transform every frame (WeaponFX uses
--                        the same convention).
--   Motor6D              C0 is not animated, but THIS script writes it, so the
--                        authored C0 is kept on the joint the first time it is
--                        seen and read back from there -- a restarted script
--                        never takes a posed C0 for rest.
--==============================================================================
local REST_C0 = "SeedCarryRestC0"
local function motorRest(m: Motor6D): CFrame
	local kept = m:GetAttribute(REST_C0)
	if typeof(kept) == "CFrame" then
		return kept
	end
	m:SetAttribute(REST_C0, m.C0)
	return m.C0
end

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
				rest = CFrame.identity, sign = entry[3] :: number,
			})
		end
	end
	if #sides == 2 then
		-- The lower arms, for the overhead pose: AnimationConstraints inside the
		-- lower arm and hand parts, as the shoulders are inside the upper arms.
		local straight: { Side } = {}
		for _, entry in ipairs({ { "RightLowerArm", "RightElbow" }, { "LeftLowerArm", "LeftElbow" },
			{ "RightHand", "RightWrist" }, { "LeftHand", "LeftWrist" } }) do
			local part = character:FindFirstChild(entry[1])
			local joint = part and part:FindFirstChild(entry[2])
			if joint and joint:IsA("AnimationConstraint") then
				table.insert(straight, { constraint = joint, motor = nil, rest = CFrame.identity, sign = 0 })
			end
		end
		return { sides = sides, straight = straight, kind = "constraint", weight = 0, overhead = 0, released = true }
	end
	table.clear(sides)

	-- 2. Motor6D R15.
	local upper = character:FindFirstChild("UpperTorso")
	if upper then
		for _, entry in ipairs({ { "RightShoulder", 1 }, { "LeftShoulder", -1 } }) do
			local m = upper:FindFirstChild(entry[1] :: string)
			if m and m:IsA("Motor6D") then
				table.insert(sides, {
					constraint = nil, motor = m, rest = motorRest(m), sign = entry[2] :: number,
				})
			end
		end
		if #sides == 2 then
			local straight: { Side } = {}
			for _, entry in ipairs({ { "RightLowerArm", "RightElbow" }, { "LeftLowerArm", "LeftElbow" },
				{ "RightHand", "RightWrist" }, { "LeftHand", "LeftWrist" } }) do
				local part = character:FindFirstChild(entry[1])
				local m = part and part:FindFirstChild(entry[2])
				if m and m:IsA("Motor6D") then
					table.insert(straight, { constraint = nil, motor = m, rest = motorRest(m), sign = 0 })
				end
			end
			return { sides = sides, straight = straight, kind = "motor6d-r15", weight = 0, overhead = 0, released = true }
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
					constraint = nil, motor = m, rest = motorRest(m), sign = entry[2] :: number,
				})
			end
		end
		if #sides == 2 then
			return { sides = sides, straight = {}, kind = "motor6d-r6", weight = 0, overhead = 0, released = true }
		end
	end
	return nil
end

--==============================================================================
-- THE OVERHEAD POSE -- 2026-10-01
--
-- Both arms straight up and a little out, elbows and wrists held straight, for
-- a secret pod or plant (SeedData Carry = "overhead", welded by CarryService at
-- GameConfig.Carry.OverheadLift). 170 degrees rather than 180 so the hands sit
-- a touch forward of the crown, under the model's base rather than behind it.
--==============================================================================
local OVERHEAD_LIFT = math.rad(170)
local OVERHEAD_SPREAD = math.rad(8)
-- Below this much overhead weight the lower arms are the animator's alone.
local STRAIGHT_FLOOR = 0.001

-- Whether what the player carries rides over the head: the raid pod's species
-- is a player attribute (a pod, never hatched), a Tool's is on the Tool with
-- whether it is the hatched plant. PlantForms.CarriedOverhead decides: the
-- Secrets and Rain forms, pod and plant, and since 2026-10-03 every hatched
-- plant built from the owner's supplied rigs -- not their pods.
local function carriesOverhead(player: Player, character: Model): boolean
	local id = player:GetAttribute(GameConfig.Attributes.CarryingSpecies)
	local hatched = false
	if type(id) ~= "string" then
		for _, d in ipairs(character:GetChildren()) do
			if d:IsA("Tool") then
				id = d:GetAttribute("SpeciesId")
				hatched = d:GetAttribute("Hatched") == true
				break
			end
		end
	end
	local species = if type(id) == "string" then SeedData.Get(id) else nil
	return PlantForms.CarriedOverhead(species, hatched)
end

--==============================================================================
-- AIMING AT THE POD
--
-- Not a fixed pose: the arms follow the thing. GripForward puts a 1 kg pod 1.5
-- studs out and a 10,000 kg one 5.8, so one angle cannot serve both -- a pose
-- tuned for the small pod leaves the boulder held at the fingertips.
--
-- IT IS THE REACH, AND THE REACH IS MEASURED, NOT DERIVED
--
-- This used to compute SeedData.GripForward(kg) -- a POD's radius -- for
-- whatever was in the player's hands. That is right for a raid pod and wrong
-- for everything else: a hatched creature is a completely different shape from
-- the shell it came out of, and a Bellchime's skirt is four times its pod's
-- diameter, so the pod formula aimed the arms at a place the plant was not.
--
-- CarryService writes the real number on the Tool as GripReach when it builds
-- the grip, from the model it has in front of it. One measurement, taken where
-- the thing exists, read here.
--
-- Reach drives how far the shoulders swing forward, and how far apart. A big pod
-- needs the hands WIDER, not just further out, which is why the spread relaxes
-- as reach grows.
--==============================================================================
local function anglesFor(reach: number?): (number, number)
	local out = reach or 1.6
	-- 1.5 studs of reach -> ~57 deg, 5.8 -> clamped at 82. Clamped so no pod
	-- folds the arm back through the shoulder.
	local lift = math.clamp(43 + 9.2 * out, 45, 82)
	-- Negative is inward. Small pods are hugged; big ones are braced.
	local spread = math.clamp(-24 + 6 * out, -22, 4)
	return math.rad(lift), math.rad(spread)
end

--==============================================================================
-- THE HAND WELD THIS CLIENT KEEPS (2026-10-03)
--
-- CarryService destroys the engine's RightGrip on the SERVER and welds the
-- Handle to the root instead (CarryWeld). Measured in Play: now and then the
-- local client still has a RightGrip of its own for that handle -- the server
-- never sees it, so never removes it -- and it drags the right hand onto the
-- handle: for the overhead carry, up onto the plant's base instead of beside
-- the head where the pose puts it. A grip on a handle the carry owns (it has a
-- CarryWeld) is removed here, on this client, for its own character only. The
-- server's state, which every other player sees, is already this.
--==============================================================================
local function clearHandGrip(character: Model)
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			local handle = tool:FindFirstChild("Handle")
			if handle and handle:FindFirstChild("CarryWeld") then
				for _, d in ipairs(character:GetDescendants()) do
					if d:IsA("JointInstance") and d.Name ~= "CarryWeld" and (d :: any).Part1 == handle then
						d:Destroy()
					end
				end
			end
		end
	end
end

-- The local character's grip watch: one at a time, cut when the character
-- changes, so a respawn never leaves the old body's connection running.
local gripWatch: RBXScriptConnection? = nil

local function track(player: Player)
	local function onCharacter(character: Model)
		rigs[player] = nil
		if player == Players.LocalPlayer then
			if gripWatch then
				gripWatch:Disconnect()
			end
			-- Part1 may not be set yet when a joint arrives: checked a moment later.
			gripWatch = character.DescendantAdded:Connect(function(d)
				if d:IsA("JointInstance") then
					task.delay(0.1, clearHandGrip, character)
				end
			end)
		end
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
-- How far in front of the root whatever is being carried actually rides, or nil
-- for empty hands. Two places to look, because the player attribute is only set
-- during a raid and the Tool is what survives banking.
--
-- A RAID POD has no Tool, so its reach still comes off the weight -- which is
-- correct there, because the thing in your arms IS the shell that formula
-- describes. Everything in the hotbar carries its own measured GripReach, and
-- the weight fallback is only for a Tool built before that existed.
local function carriedReach(player: Player, character: Model): number?
	local tier = player:GetAttribute(CARRYING_KG)
	if type(tier) == "number" then
		return SeedData.GripForward(tier)
	end
	for _, d in ipairs(character:GetChildren()) do
		if d:IsA("Tool") then
			local reach = d:GetAttribute("GripReach")
			if type(reach) == "number" then
				return reach
			end
			local weight = d:GetAttribute(CARRYING_KG)
			if type(weight) == "number" then
				return SeedData.GripForward(weight)
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
		-- A shoulder that is no longer on this character (the avatar's limbs
		-- were rebuilt after spawn, or the joint was replaced) means a rig of
		-- dead references: built again from what is there now.
		local first = rig.sides[1]
		local joint: Instance? = if first then (first.constraint or first.motor) else nil
		if character and character.Parent and not (joint and joint:IsDescendantOf(character)) then
			local fresh = buildRig(character)
			if fresh then
				rigs[player] = fresh
				rig = fresh
			end
		end
		if not character or not character.Parent then
			rigs[player] = nil
		else
			local reach = carriedReach(player, character)
			local want = if reach ~= nil then 1 else 0
			rig.weight += (want - rig.weight) * alpha
			if rig.weight < 0.002 and want == 0 then
				rig.weight = 0
			end
			-- Which pose: blended too, so a secret banked into a Tool does not
			-- snap the arms between the two.
			local wantOverhead = if want == 1 and carriesOverhead(player, character) then 1 else 0
			rig.overhead += (wantOverhead - rig.overhead) * alpha

			if rig.weight > 0 then
				-- Driving again, so the joints will need handing back again.
				rig.released = false
				local lift, spread = anglesFor(reach)
				local o = rig.overhead
				lift = lift + (OVERHEAD_LIFT - lift) * o
				spread = spread + (OVERHEAD_SPREAD - spread) * o
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
				--==============================================================
				-- THE LOWER ARMS: NOT TOUCHED AT ALL UNLESS THE POSE IS OVERHEAD
				--
				-- The chest carry leaves the elbows and wrists to the animation,
				-- exactly as before the overhead pose existed. The first version
				-- of this loop (2026-10-01) wrote them on EVERY carry -- `rest`
				-- when the pose was not overhead -- which pinned every carrier's
				-- lower arms at the pose captured on spawn: the same mistake the
				-- shoulders' hand-back note below describes.
				--
				-- While the overhead pose has weight, each joint is blended from
				-- what the animator gave it THIS frame toward straight, so there
				-- is no remembered value to restore and nothing to hand back: the
				-- frame the weight runs out, the writes stop and the animator has
				-- the joint, as it always did.
				--==============================================================
				local s = rig.weight * o
				if s > STRAIGHT_FLOOR then
					for _, side in ipairs(rig.straight) do
						local joint: any = side.constraint or side.motor
						if joint then
							joint.Transform = (joint.Transform :: CFrame):Lerp(CFrame.identity, s)
						end
					end
				end
			elseif rig.weight == 0 and not rig.released then
				--==============================================================
				-- HAND THE JOINTS BACK -- ONCE, AND THEN NEVER AGAIN
				--
				-- THIS BRANCH USED TO RUN EVERY FRAME, AND IT PINNED BOTH
				-- SHOULDERS OF EVERY PLAYER FOR THE WHOLE SESSION.
				--
				-- The old guard was `if constraint.Transform ~= rest then write`,
				-- which reads like "only correct it when something moved it".
				-- What actually moves it is THE ANIMATOR, every frame, and this
				-- loop runs in `Stepped` -- after the animation is evaluated. So
				-- the guard was true on every frame forever and the write landed
				-- on every frame forever, reverting the animation.
				--
				-- Measured on the live avatar, playing Roblox's own `wave`:
				--
				--     CarryPose running    right shoulder swept  0.0 deg
				--     CarryPose disabled   right shoulder swept 17.1 deg
				--
				-- and a sweep of all fifteen joints showed the animator visibly
				-- driving eleven of them while BOTH SHOULDERS sat at exactly
				-- (-0.0, 0.0, -0.0) -- the shape of a value being written, not
				-- one being left alone.
				--
				-- That cost more than the arms: it is why three passes of notes
				-- in HANDOFF, WeaponData and build_swing.luau record the shoulder
				-- as "INERT -- the animator never writes it" and concluded a
				-- custom PUBLISHED animation was the only way to swing a bat. The
				-- shoulder was never inert. This line was overwriting it.
				--
				-- A one-shot is the whole fix: write rest once so nothing is left
				-- displaced, latch, and let the animator have the joint back.
				--==============================================================
				rig.released = true
				for _, side in ipairs(rig.sides) do
					if side.constraint then
						side.constraint.Transform = side.rest
					elseif side.motor then
						side.motor.C0 = side.rest
					end
				end
				-- The lower arms are not handed back: they were only ever blended
				-- from the animator's own value, never set to a remembered one.
			end
		end
	end
end)
