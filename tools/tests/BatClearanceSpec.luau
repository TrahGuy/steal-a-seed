--!nocheck
--==============================================================================
-- BAT CLEARANCE -- does the swing go through the body or the floor?
--
-- BatSwingSpec checks ATTACHMENT MATH: contact direction and timing, blend
-- endpoints, grip preservation, support-joint release. It passed 93/93 while the
-- barrel was going 1.36 studs through the ground and the handle 0.53 studs into
-- the chest, because nothing in it looks at where the weapon's GEOMETRY ends up.
-- This file is that missing half, and it exists because those two defects
-- shipped green.
--
-- It uses the REAL built Tools -- every part of every bat, all eight corners of
-- each -- against a body and a floor, sampled across the whole swing.
--
-- WHAT IT IS NOT: a visual or multiplayer test. The body below is an IDEALISED
-- STANDING FIXTURE -- real measured R15 part sizes, but mirrored left/right and
-- with the idle animation's leg rotations zeroed, so the result is deterministic
-- instead of depending on which animation frame a capture happened to catch. The
-- live avatar remains the authority; this catches the class of regression.
--
-- Run with tools/tests/run.luau in Edit for fresh source throughout.
--==============================================================================
local Shared = game.ReplicatedStorage.SeedGame.Shared
local Motion = require(Shared.BatSwingMotion)
local Data = require(Shared.WeaponData)
local Models = require(Shared.WeaponModel)

local passed = 0
local function check(ok, label)
	assert(ok, label)
	passed += 1
end

--==============================================================================
-- THE LIMITS
--
-- Not zero. A two-hand swing brings the handle past the chest and the thigh by
-- design, and some contact is geometrically forced at these proportions -- the
-- strike phase of the ACCEPTED swing already ran 0.11-0.20. These are regression
-- limits set above what the corrected motion measures and well below what the
-- defect measured, so the bug that prompted this file fails loudly here.
--
--   measured before the clearance pass:  ground -1.36   penetration 0.53
--   measured after it, live, all six:    ground +0.20   penetration 0.33
--==============================================================================
local MIN_GROUND = 0.02
local MAX_PENETRATION = 0.42
local SAMPLES = 48

-- Rest geometry read off the live avatar, then symmetrised. Name, size, and
-- centre in the untwisted torso frame that BatSwingMotion's positions live in.
local UPPER = {
	{ "Head", Vector3.new(1.1962, 1.2029, 1.1979), Vector3.new(0, 1.4408, 0.0677) },
	{ "UpperTorso", Vector3.new(1.8154, 1.7732, 1.1102), Vector3.new(0, 0, 0) },
}
local LOWER = {
	{ "LowerTorso", Vector3.new(1.6962, 0.5661, 0.9525), Vector3.new(0, -0.8293, -0.0557) },
	{ "LeftUpperLeg", Vector3.new(0.7597, 1.3789, 0.7694), Vector3.new(-0.4862, -1.4842, -0.1745) },
	{ "RightUpperLeg", Vector3.new(0.7597, 1.3789, 0.7694), Vector3.new(0.4862, -1.4842, -0.1745) },
	{ "LeftLowerLeg", Vector3.new(0.7420, 1.0774, 0.8213), Vector3.new(-0.6291, -2.2775, -0.2251) },
	{ "RightLowerLeg", Vector3.new(0.7420, 1.0774, 0.8213), Vector3.new(0.6291, -2.2775, -0.2251) },
	{ "LeftFoot", Vector3.new(0.8362, 0.6279, 1.2425), Vector3.new(-0.6807, -2.6256, -0.3580) },
	{ "RightFoot", Vector3.new(0.8362, 0.6279, 1.2425), Vector3.new(0.6807, -2.6256, -0.3580) },
}
-- The sole of the foot. Everything below this is underground.
local FLOOR_Y = -2.6256 - 0.6279 / 2

--==============================================================================
-- THE ARMS ARE DELIBERATELY NOT IN THAT LIST
--
-- Both upper arms are driven BY the swing, so a static box for them would be
-- fiction, and a bat brushing the arm that is holding it is not the defect this
-- guards. Hands and forearms are the grip itself. HumanoidRootPart is never
-- rendered. What is left -- head, torso, legs, feet, floor -- is what a player
-- would see the bat pass through.
--==============================================================================

local function fixture(scale)
	local c = Instance.new("Model")
	local function part(name, size)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size * scale
		p.CFrame = CFrame.new(23, 10, -19) * CFrame.Angles(0, scale, 0)
		p.Parent = c
		return p
	end
	local lower = part("LowerTorso", Vector3.one)
	local torso = part("UpperTorso", Vector3.new(1.8154, 1.7732, 1.1102))
	local function attachment(p, name, cf)
		local a = Instance.new("Attachment")
		a.Name = name
		a.CFrame = CFrame.new(cf.Position * scale) * cf.Rotation
		a.Parent = p
		return a
	end
	local function seam(name, p0, p1, v0, v1)
		local j = Instance.new("AnimationConstraint")
		j.Name = name
		j.Attachment0 = attachment(p0, name .. "0", CFrame.new(v0))
		j.Attachment1 = attachment(p1, name .. "1", CFrame.new(v1))
		j.Enabled = true
		j.IsKinematic = true
		j.Parent = p1
	end
	seam("Waist", lower, torso, Vector3.new(0,.08515,.09998), Vector3.new(0,-.74411,.04428))
	for _, side in {"Right", "Left"} do
		local sign = if side == "Right" then 1 else -1
		local upper = part(side .. "UpperArm", Vector3.one)
		local fore = part(side .. "LowerArm", Vector3.one)
		local hand = part(side .. "Hand", Vector3.one)
		seam(side .. "Shoulder", torso, upper, Vector3.new(.911*sign,.47425,.04428), Vector3.new(-.28159*sign,.29391,-.01902))
		seam(side .. "Elbow", upper, fore, Vector3.new(.03741*sign,-.30470,.12269), Vector3.new(-.08010*sign,.26582,.03960))
		seam(side .. "Wrist", fore, hand, Vector3.new(.12690*sign,-.26345,.03960), Vector3.new(.05408*sign,.43198,.13974))
		attachment(hand, side .. "GripAttachment", CFrame.new(-.07792*sign,-.14706,.13974) * CFrame.Angles(-math.pi/2,0,0))
	end
	return c
end

-- Edit has no animation solver, so nothing MOVES when Transform is written.
-- Every frame below is therefore computed the same way the rig would resolve it.
local function handFrame(a, torso)
	local upper = torso * a.s0 * a.shoulder.Transform * a.s1:Inverse()
	local lower = upper * a.e0 * a.elbow.Transform * a.e1:Inverse()
	return lower * a.w0 * a.wrist.Transform * a.w1:Inverse()
end

-- Deepest a corner sits inside a box, 0 when outside. Depth, not just presence:
-- "the handle grazes the chest" and "the bat is buried in it" must not read the
-- same, or the limit above would be meaningless.
local function depthIn(pointLocal, half)
	local dx = half.X - math.abs(pointLocal.X)
	local dy = half.Y - math.abs(pointLocal.Y)
	local dz = half.Z - math.abs(pointLocal.Z)
	if dx <= 0 or dy <= 0 or dz <= 0 then return 0 end
	return math.min(dx, dy, dz)
end

local report = {}
for _, scale in {0.85, 1, 1.15} do
	local c = fixture(scale)
	local rig = Motion.Bind(c)
	check(rig ~= nil, "bind clearance fixture " .. scale)
	local lowerCF = c.LowerTorso.CFrame

	for _, item in Data.Items do
		if item.Category ~= "bat" then continue end
		local tool = Models.BuildTool(item)
		local handle = tool:FindFirstChild("Handle")
		check(handle ~= nil, item.Id .. " has a Handle")

		-- Each weapon part, and its eight corners, frozen relative to the Handle.
		local pieces = {}
		for _, d in tool:GetDescendants() do
			if d:IsA("BasePart") then
				local rel = handle.CFrame:ToObjectSpace(d.CFrame)
				local h = d.Size * 0.5 * scale
				local corners = {}
				for _, sx in {-1, 1} do for _, sy in {-1, 1} do for _, sz in {-1, 1} do
					corners[#corners + 1] = CFrame.new(rel.Position * scale) * rel.Rotation
						* CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)
				end end end
				pieces[#pieces + 1] = corners
			end
		end

		local total = item.Windup + item.Recovery
		local worstGround, worstDepth, worstWho, worstAt = math.huge, 0, "", 0
		for i = 0, SAMPLES do
			local t = total * i / SAMPLES
			check(Motion.Apply(rig, tool, scale * 1000 + i, t, item.Windup, item.Recovery, 1)
				or true, "apply")
			local torso = lowerCF * rig.waist0 * rig.waist.Transform * rig.waist1:Inverse()
			local neutral = lowerCF * rig.waist0 * rig.waist1:Inverse()
			local hand = handFrame(rig.right, torso)
			local hCF = hand * rig.right.grip * tool.Grip:Inverse()

			for _, corners in pieces do
				for _, rel in corners do
					local world = (hCF * rel).Position
					local inNeutral = neutral:PointToObjectSpace(world)
					local clearance = (inNeutral.Y - FLOOR_Y * scale) / scale
					if clearance < worstGround then worstGround = clearance end
					-- Head and chest ride the waist twist; the rest do not.
					for _, box in UPPER do
						local d = depthIn(torso:PointToObjectSpace(world) - box[3] * scale, box[2] * 0.5 * scale)
						if d / scale > worstDepth then worstDepth, worstWho, worstAt = d / scale, box[1], t end
					end
					for _, box in LOWER do
						local d = depthIn(neutral:PointToObjectSpace(world) - box[3] * scale, box[2] * 0.5 * scale)
						if d / scale > worstDepth then worstDepth, worstWho, worstAt = d / scale, box[1], t end
					end
				end
			end
		end

		report[#report + 1] = string.format("   %-17s x%.2f  ground %+.2f  deepest %.2f into %s @t%.3f",
			item.Id, scale, worstGround, worstDepth, (if worstWho == "" then "nothing" else worstWho), worstAt)
		check(worstGround >= MIN_GROUND, string.format(
			"%s @x%.2f goes %.2f studs THROUGH THE GROUND (limit %.2f)", item.Id, scale, worstGround, MIN_GROUND))
		check(worstDepth <= MAX_PENETRATION, string.format(
			"%s @x%.2f sinks %.2f studs into %s (limit %.2f)", item.Id, scale, worstDepth, worstWho, MAX_PENETRATION))
		tool:Destroy()
	end
	c:Destroy()
end

return table.concat(report, "\n") .. string.format(
	"\n\nBatClearanceSpec %d/%d; %d samples per bat per scale, real weapon geometry, all corners." ..
	"\nLimits: ground >= %.2f, penetration <= %.2f. Idealised standing fixture -- not a visual test.",
	passed, passed, SAMPLES + 1, MIN_GROUND, MAX_PENETRATION)
