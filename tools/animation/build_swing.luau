--!nocheck
-- Steal a Seed :: the bat swing, authored
--
--   python -m http.server 8731          (repo root)
--
--   -- Studio command bar, EDIT mode:
--   local build = loadstring(game:GetService("HttpService"):GetAsync(
--       "http://127.0.0.1:8731/tools/animation/build_swing.luau", true))()
--   print(build())
--
-- Puts a `SeedBatSwing` KeyframeSequence in ServerStorage, ready to publish.
-- Returns a short report. Safe to re-run: it destroys the previous one first.
--
--==============================================================================
-- NOTHING NEEDS THIS ANY MORE. READ THIS BEFORE USING IT.
--
-- This file exists because the swing was believed to require a PUBLISHED
-- animation asset -- the right shoulder read as inert, so posing the arm from
-- code looked impossible and a human pressing Publish looked like the only way
-- out. That premise was false.
--
-- The shoulder was being held by our own code: `CarryPose.client.luau` wrote
-- `Transform = rest` to both shoulders every frame in `Stepped`, after the
-- animator, and so reverted everything. Measured on the live avatar playing
-- Roblox's own `wave`: shoulder swept 0.0 degrees with CarryPose running and
-- 17.1 with it disabled. With the one-shot release in place the joint tracks a
-- commanded angle to within a degree.
--
-- SO THE SWING IS AUTHORED IN `WeaponFX.client.luau` INSTEAD, in degrees,
-- interpolated per frame, and measured at 22.67 studs of bat-tip travel. No
-- asset, no upload, no human step.
--
-- WHAT IS STILL WORTH KEEPING HERE. The KeyframeSequence findings below are
-- real and were expensive to get -- the root Pose needing Weight 0, the
-- AnimationRigData child that cannot be constructed, and the fact that
-- RegisterKeyframeSequence returns a machine-local id that never replicates.
-- If this project ever does want a published animation, start from those.
--
--==============================================================================
-- WHAT THE POSES ARE, AND HOW THE AXES WERE FOUND
--
-- Read off a real Roblox animation rather than guessed. `point` (507770453),
-- fetched and inspected, poses RightUpperArm at (93.6, 19.0, 23.4) degrees for
-- an arm raised forward -- so on this rig X is the forward/backward swing, Y
-- turns the arm across the body, Z lifts it away from the ribs.
--
-- Two things that make the difference between motion and nothing, both learned
-- by comparing an authored sequence against a fetched one that worked:
--
--   * The ROOT pose must carry Weight 0. At 1 it pins the whole body and the
--     arm travels 0.18 studs instead of a stride.
--   * The sequence needs an `AnimationRigData` child. Roblox's own carry one
--     ("AnimationRigDataBlocky"); it is cloned from a fetched animation here
--     because it is not constructible.
--
-- THE LEGS ARE NOT IN THIS SEQUENCE AT ALL. No hip, knee or foot pose, and
-- LowerTorso is present only as the link to UpperTorso, at Weight 0. That is
-- what keeps walking and jumping working underneath a swing: a joint nobody
-- animates is a joint the walk cycle still owns.
--==============================================================================

local ServerStorage = game:GetService("ServerStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local SEQUENCE_NAME = "SeedBatSwing"

-- Any published Roblox animation would do; this one is on every avatar already.
local RIG_DATA_DONOR = "rbxassetid://507770453"

--==============================================================================
-- THE SWING
--
-- Five poses. Degrees, in each joint's own frame.
--
--   0.00  neutral      blends out of whatever the body was doing
--   0.26  WIND-UP      arm up and back over the shoulder, torso coiled right,
--                      off hand pulled across -- the anticipation
--   0.40  CONTACT      arm driven down and across the front, torso uncoiled
--                      left. THIS IS THE FRAME THE SERVER'S HIT LINES UP WITH.
--   0.55  follow       arm continues past the body, torso keeps turning
--   0.90  neutral      settles back so the equipped idle takes over cleanly
--
-- CONTACT AT 0.40 OF 0.90 = 0.444 of the way through. CombatService scales
-- playback so that fraction lands exactly on each bat's own wind-up, which is
-- why this number is exported rather than left implicit.
--==============================================================================
local CONTACT_TIME = 0.40
local TOTAL_TIME = 0.90

--==============================================================================
-- THE "INERT SHOULDER" READING THAT USED TO BE HERE WAS AN ARTEFACT
--
-- This block recorded RightUpperArm as INERT -- a full 0..180 sweep leaving the
-- hand at (1.49, -1.07, 0.13) to two decimals -- and treated it as a property of
-- the rig. It was CarryPose overwriting the joint every frame; see the header.
-- The shoulder poses below are fine and would drive the arm today.
--
-- What remains true: UpperTorso answers (Y 0/25/50/-35 -> chest yaw
-- 3.2/27.8/39.6/-26.5) and RightLowerArm answers (X 0..135 -> the hand travels
-- about 1.2 studs).
--==============================================================================
local FRAMES = {
	{
		t = 0.00,
		UpperTorso = Vector3.new(0, 0, 0),
		RightUpperArm = Vector3.new(0, 0, 0),
		RightLowerArm = Vector3.new(0, 0, 0),
		RightHand = Vector3.new(0, 0, 0),
		LeftUpperArm = Vector3.new(0, 0, 0),
	},
	{
		-- WIND-UP. Chest coiled right, elbow folded hard so the bat comes back
		-- over the shoulder, off arm pulled across.
		t = 0.26,
		UpperTorso = Vector3.new(-6, 34, -5),
		RightUpperArm = Vector3.new(150, -28, 18),
		RightLowerArm = Vector3.new(-88, 0, 0),
		RightHand = Vector3.new(-12, 0, 0),
		LeftUpperArm = Vector3.new(-20, 0, -24),
	},
	{
		-- CONTACT. Chest driven the other way -- 80 degrees of rotation between
		-- this frame and the last -- and the elbow opening out so the bat is
		-- extended when the server's hit lands.
		t = CONTACT_TIME,
		UpperTorso = Vector3.new(8, -34, 7),
		RightUpperArm = Vector3.new(70, 42, -22),
		RightLowerArm = Vector3.new(-18, 0, 0),
		RightHand = Vector3.new(6, 0, 0),
		LeftUpperArm = Vector3.new(30, 0, -12),
	},
	{
		-- FOLLOW-THROUGH. The turn keeps going past the strike rather than
		-- stopping on it, which is most of what makes a swing read as weight.
		t = 0.55,
		UpperTorso = Vector3.new(10, -46, 9),
		RightUpperArm = Vector3.new(30, 66, -38),
		RightLowerArm = Vector3.new(-40, 0, 0),
		RightHand = Vector3.new(10, 0, 0),
		LeftUpperArm = Vector3.new(36, 0, -8),
	},
	{
		t = TOTAL_TIME,
		UpperTorso = Vector3.new(0, 0, 0),
		RightUpperArm = Vector3.new(0, 0, 0),
		RightLowerArm = Vector3.new(0, 0, 0),
		RightHand = Vector3.new(0, 0, 0),
		LeftUpperArm = Vector3.new(0, 0, 0),
	},
}

local function angles(v)
	return CFrame.Angles(math.rad(v.X), math.rad(v.Y), math.rad(v.Z))
end

local function pose(parent, name, cf, weight)
	local p = Instance.new("Pose")
	p.Name = name
	p.CFrame = cf or CFrame.new()
	p.Weight = weight or 1
	p.EasingStyle = Enum.PoseEasingStyle.Cubic
	p.EasingDirection = Enum.PoseEasingDirection.InOut
	p.Parent = parent
	return p
end

return function()
	local existing = ServerStorage:FindFirstChild(SEQUENCE_NAME)
	if existing then
		existing:Destroy()
	end

	local donor = KeyframeSequenceProvider:GetKeyframeSequenceAsync(RIG_DATA_DONOR)
	local rigData = donor:FindFirstChildOfClass("AnimationRigData")

	local kfs = Instance.new("KeyframeSequence")
	kfs.Name = SEQUENCE_NAME
	kfs.Loop = false
	kfs.Priority = Enum.AnimationPriority.Action4
	if rigData then
		rigData:Clone().Parent = kfs
	end

	for _, frame in ipairs(FRAMES) do
		local kf = Instance.new("Keyframe")
		kf.Time = frame.t

		-- Root at Weight 0: it is the link to everything else, not a pose.
		local root = pose(kf, "HumanoidRootPart", CFrame.new(), 0)
		-- LowerTorso likewise -- present so UpperTorso has a parent, weightless
		-- so the hips still belong to the walk cycle.
		local lower = pose(root, "LowerTorso", CFrame.new(), 0)
		local upper = pose(lower, "UpperTorso", angles(frame.UpperTorso), 1)

		local rua = pose(upper, "RightUpperArm", angles(frame.RightUpperArm), 1)
		local rla = pose(rua, "RightLowerArm", angles(frame.RightLowerArm), 1)
		pose(rla, "RightHand", angles(frame.RightHand), 1)

		-- The off hand travels with the swing. A bat held in one hand while the
		-- other arm hangs still reads as a prop rather than a weapon.
		pose(upper, "LeftUpperArm", angles(frame.LeftUpperArm), 1)

		kf.Parent = kfs
	end

	kfs.Parent = ServerStorage

	return string.format(
		"%s built in ServerStorage: %d keyframes, %.2fs long, contact at %.2fs (%.3f of the way through).\n"
			.. "AnimationRigData cloned: %s\n"
			.. "TO PUBLISH: right-click it in Explorer -> Save to Roblox -> set Type to Animation.\n"
			.. "Then paste the id into WeaponData.Combat.SwingAnimation and set\n"
			.. "SwingAnimationLength = %.2f and SwingAnimationContact = %.3f.",
		SEQUENCE_NAME, #FRAMES, TOTAL_TIME, CONTACT_TIME, CONTACT_TIME / TOTAL_TIME,
		tostring(rigData ~= nil), TOTAL_TIME, CONTACT_TIME / TOTAL_TIME)
end
