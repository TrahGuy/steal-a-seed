--!strict
-- Two hands share one handle trajectory. Joint rotations are solved from the
-- actual avatar attachments; the Tool weld and limb lengths never change.
-- WeaponFX owns evaluation from the server's SwingAt/Windup/Recover clock.
local Motion = {}

type Arm = {
	shoulder: AnimationConstraint, elbow: AnimationConstraint, wrist: AnimationConstraint,
	s0: CFrame, s1: CFrame, e0: CFrame, e1: CFrame, w0: CFrame, w1: CFrame,
	upperAxis: CFrame, lowerAxis: CFrame, upperLength: number, lowerLength: number,
	grip: CFrame,
}
export type Rig = {
	right: Arm, left: Arm, waist: AnimationConstraint,
	waist0: CFrame, waist1: CFrame, scale: number,
	leftStartS: CFrame, leftStartE: CFrame, leftStartW: CFrame,
	waistStart: CFrame, startedAt: number?,
	-- The idle this swing leaves from and returns to, captured once per swing.
	lowPos: Vector3, lowYaw: number, lowElev: number,
}

local function joint(character: Model, partName: string, jointName: string): AnimationConstraint?
	local part = character:FindFirstChild(partName)
	local found = part and part:FindFirstChild(jointName)
	return if found and found:IsA("AnimationConstraint") then found else nil
end

local function arm(character: Model, side: string): Arm?
	local s = joint(character, side .. "UpperArm", side .. "Shoulder")
	local e = joint(character, side .. "LowerArm", side .. "Elbow")
	local w = joint(character, side .. "Hand", side .. "Wrist")
	local hand = character:FindFirstChild(side .. "Hand")
	local grip = hand and hand:FindFirstChild(side .. "GripAttachment")
	if not (s and e and w and s.Attachment0 and s.Attachment1
		and e.Attachment0 and e.Attachment1 and w.Attachment0 and w.Attachment1
		and grip and grip:IsA("Attachment")) then return nil end
	local upper = e.Attachment0.Position - s.Attachment1.Position
	local lower = w.Attachment0.Position - e.Attachment1.Position
	if upper.Magnitude < 0.01 or lower.Magnitude < 0.01 then return nil end
	return {
		shoulder = s, elbow = e, wrist = w,
		s0 = s.Attachment0.CFrame, s1 = s.Attachment1.CFrame,
		e0 = e.Attachment0.CFrame, e1 = e.Attachment1.CFrame,
		w0 = w.Attachment0.CFrame, w1 = w.Attachment1.CFrame,
		upperAxis = CFrame.lookAt(Vector3.zero, upper, Vector3.zAxis),
		lowerAxis = CFrame.lookAt(Vector3.zero, lower, Vector3.zAxis),
		upperLength = upper.Magnitude, lowerLength = lower.Magnitude,
		grip = grip.CFrame,
	}
end

-- Declared above Bind because Bind seeds a rig with them; a local declared
-- further down the file is not in scope inside a function defined above it,
-- and would silently read as a nil global.
local DEFAULT_LOW_POS = Vector3.new(1.510, -1.163, -0.082)
local DEFAULT_LOW_YAW = 29.2
local DEFAULT_LOW_ELEV = 0

function Motion.Bind(character: Model): Rig?
	local right, left = arm(character, "Right"), arm(character, "Left")
	local waist = joint(character, "UpperTorso", "Waist")
	local torso = character:FindFirstChild("UpperTorso")
	if not (right and left and waist and waist.Attachment0 and waist.Attachment1
		and torso and torso:IsA("BasePart")) then return nil end
	return {
		right = right, left = left, waist = waist,
		waist0 = waist.Attachment0.CFrame, waist1 = waist.Attachment1.CFrame,
		scale = torso.Size.X / 1.8154,
		leftStartS = CFrame.identity, leftStartE = CFrame.identity,
		leftStartW = CFrame.identity, waistStart = CFrame.identity, startedAt = nil,
		lowPos = DEFAULT_LOW_POS, lowYaw = DEFAULT_LOW_YAW, lowElev = DEFAULT_LOW_ELEV,
	}
end

local function smooth(u: number): number
	return u * u * (3 - 2 * u)
end

local function barrel(yaw: number, elevation: number): CFrame
	local y, e = math.rad(yaw), math.rad(elevation)
	local up = Vector3.new(math.sin(y) * math.cos(e), math.sin(e), -math.cos(y) * math.cos(e))
	local right = Vector3.yAxis:Cross(up).Unit
	return CFrame.fromMatrix(Vector3.zero, right, up, right:Cross(up))
end

-- Positions are the gripping palm in the UNTWiSTED torso frame. The shoulder
-- coil rotates the chest beneath the hands instead of moving the hit off axis.
local LOAD_POS = Vector3.new(0.48, 0.48, -0.88)
local HIT_POS = Vector3.new(0.10, 0.02, -1.35)
local FOLLOW_POS = Vector3.new(-0.52, 0.18, -0.95)
local LOAD_ROT = barrel(112, 38)
local HIT_ROT = barrel(0, 4)
local FOLLOW_ROT = barrel(-82, 18)
local LOAD_WAIST = CFrame.Angles(math.rad(-5), math.rad(-27), math.rad(-4))
local HIT_WAIST = CFrame.Angles(math.rad(6), math.rad(8), math.rad(2))
local FOLLOW_WAIST = CFrame.Angles(math.rad(4), math.rad(32), math.rad(5))
local LOW_S = CFrame.Angles(math.rad(6), 0, math.rad(7))
local LOW_E = CFrame.Angles(math.rad(5), 0, 0)

--==============================================================================
-- THE TWO TRANSITS, WHICH USED TO BE UNGUIDED
--
-- The strike -- LOAD, HIT, FOLLOW -- is verified and untouched. What was wrong
-- was everything either side of it: the swing used to hold LOAD while the blend
-- weight ramped 0 -> 1, and hold FOLLOW while it ramped back to 0. A weight ramp
-- interpolates JOINT ROTATIONS between the idle and the solved pose, and the
-- path that takes is whatever the rotations happen to sweep through. Measured on
-- the live rig, corner-sampled against the real bat models: the handle went
-- 0.53 studs into the chest on the way up, and the barrel went 1.36 studs THROUGH
-- THE FLOOR on the way back, on the Mirewood.
--
-- So both transits are now explicit hand-space moves with waypoints, and the
-- weight ramp only runs while the target IS the idle -- where the two poses
-- agree, so the blend has nowhere wrong to go.
--
--   idle -> LIFT -> LOAD .. HIT .. FOLLOW -> CROSS -> DROP -> idle
--            up and                          across    down and
--            outboard                        in front  outboard
--
-- CROSS exists because one straight line cannot do the return: pulling the hand
-- back while crossing the chest drags the handle through the torso, and staying
-- forward to avoid that drops it onto the thigh. Cross first, then descend.
--==============================================================================
local RISE_AT = 0.16
local CROSS_AT = 0.62
local DROP_AT = 0.86
local LIFT_POS = Vector3.new(1.60, -0.05, -1.00)
local LIFT_YAW = 55
local LIFT_RAISE = 22
local CROSS_POS = Vector3.new(0.85, -0.50, -1.45)
local CROSS_YAW, CROSS_ELEV = 14, 10
local DROP_POS = Vector3.new(1.68, -0.92, -0.82)
local DROP_YAW = 28
local DROP_RAISE = 8

--==============================================================================
-- WHY THE TRANSITS INTERPOLATE A BEARING AND NOT A CFrame
--
-- `barrel()` pins roll by keeping the weapon's own +X horizontal. Two such
-- frames slerped together do NOT preserve that in between -- the blade rolls
-- edge-down partway across, and on a long weapon that roll excursion is what
-- reaches the floor. The Mirewood and the Sunflower measured clean at BOTH ends
-- of the final move and 0.28 studs underground in the middle of it.
--
-- Lerping the yaw and elevation instead keeps roll pinned the whole way. The
-- strike still slerps, because it is verified as it stands and its clearance is
-- 2.7 studs.
--==============================================================================
local function bearing(y1: number, e1: number, y2: number, e2: number, u: number): CFrame
	return barrel(y1 + (y2 - y1) * u, e1 + (e2 - e1) * u)
end

--==============================================================================
-- WHERE THE IDLE ACTUALLY IS, PER WEAPON
--
-- The barrel's resting elevation is NOT shared: `WeaponData.GripDroop` is 10 on
-- the Cactus and -7 on the Sunflower, whose petal head rests ABOVE horizontal.
-- Anchoring every weapon to one hard-coded idle aimed the Sunflower 15 degrees
-- below its own rest and drove the head into the ground.
--
-- Derived rather than measured: at the idle the joints ARE LOW_S / LOW_E / an
-- identity wrist, so forward kinematics through the rig's own attachment frames
-- gives the handle exactly, for whatever is held. Returns the palm in Sample's
-- units and the barrel's bearing. Verified against the live avatar: elevation
-- comes back as exactly -GripDroop for all six bats.
--==============================================================================
function Motion.LowAnchor(rig: Rig, tool: Tool): (Vector3, number, number)
	local parent = rig.waist.Attachment0 and rig.waist.Attachment0.Parent
	if not (parent and parent:IsA("BasePart")) then
		return DEFAULT_LOW_POS, DEFAULT_LOW_YAW, DEFAULT_LOW_ELEV
	end
	local neutral = parent.CFrame * rig.waist0 * rig.waist1:Inverse()
	local a = rig.right
	local upper = neutral * a.s0 * LOW_S * a.s1:Inverse()
	local lower = upper * a.e0 * LOW_E * a.e1:Inverse()
	local hand = lower * a.w0 * a.w1:Inverse()
	local handle = hand * a.grip * tool.Grip:Inverse()
	local palm = handle.Position + handle.Rotation:VectorToWorldSpace(tool.Grip.Position)
	local up = (neutral.Rotation:Inverse() * handle.Rotation).UpVector
	return neutral:PointToObjectSpace(palm) / rig.scale,
		math.deg(math.atan2(up.X, -up.Z)),
		math.deg(math.asin(math.clamp(up.Y, -1, 1)))
end

--==============================================================================
-- Pure timing function, also used by the verification sampler. CONTACT REMAINS
-- EXACTLY AT WINDUP for every bat, and the coil still accelerates hard into it:
-- those two are what the server's hit window is matched against and neither
-- moved in the clearance pass.
--
-- The idle anchor is optional so a fixture can still call this with three
-- arguments; runtime always passes the real one. Anchor-independent properties
-- -- the rotation at contact, and a weight of 0 at both ends -- hold either way.
--==============================================================================
function Motion.Sample(t: number, windup: number, recovery: number,
	lowPos: Vector3?, lowYaw: number?, lowElev: number?): (Vector3, CFrame, CFrame, number)
	local lp = lowPos or DEFAULT_LOW_POS
	local ly = lowYaw or DEFAULT_LOW_YAW
	local le = lowElev or DEFAULT_LOW_ELEV
	local rise = windup * RISE_AT
	local coil = windup * 0.52
	local follow = windup + recovery * 0.36
	local cross = windup + recovery * CROSS_AT
	local drop = windup + recovery * DROP_AT
	local total = windup + recovery
	local liftElev, dropElev = le + LIFT_RAISE, le + DROP_RAISE
	if t < rise then
		-- Off the idle, up and OUTBOARD. The weight ramp lives here, where the
		-- target is still the idle the joints are already sitting in.
		local u = smooth(math.clamp(t / rise, 0, 1))
		return lp:Lerp(LIFT_POS, u), bearing(ly, le, LIFT_YAW, liftElev, u),
			CFrame.identity:Lerp(LOAD_WAIST, u), u
	elseif t < coil then
		local u = smooth(math.clamp((t - rise) / (coil - rise), 0, 1))
		return LIFT_POS:Lerp(LOAD_POS, u), bearing(LIFT_YAW, liftElev, 112, 38, u), LOAD_WAIST, 1
	elseif t < windup then
		local u = math.clamp((t - coil) / (windup - coil), 0, 1)
		u = u * u
		return LOAD_POS:Lerp(HIT_POS, u), LOAD_ROT:Lerp(HIT_ROT, u), LOAD_WAIST:Lerp(HIT_WAIST, u), 1
	elseif t < follow then
		local u = (t - windup) / (follow - windup)
		u = 1 - (1 - u) ^ 3
		return HIT_POS:Lerp(FOLLOW_POS, u), HIT_ROT:Lerp(FOLLOW_ROT, u), HIT_WAIST:Lerp(FOLLOW_WAIST, u), 1
	elseif t < cross then
		-- Across the front, still ahead of the chest.
		local u = smooth(math.clamp((t - follow) / (cross - follow), 0, 1))
		return FOLLOW_POS:Lerp(CROSS_POS, u), bearing(-82, 18, CROSS_YAW, CROSS_ELEV, u),
			FOLLOW_WAIST:Lerp(CFrame.identity, u), 1
	elseif t < drop then
		-- Then down the outside, clear of the thigh.
		local u = smooth(math.clamp((t - cross) / (drop - cross), 0, 1))
		return CROSS_POS:Lerp(DROP_POS, u), bearing(CROSS_YAW, CROSS_ELEV, DROP_YAW, dropElev, u),
			CFrame.identity, 1
	end
	local u = smooth(math.clamp((t - drop) / math.max(total - drop, 1e-6), 0, 1))
	return DROP_POS:Lerp(lp, u), bearing(DROP_YAW, dropElev, ly, le, u), CFrame.identity, 1 - u
end

-- A two-bone solve. Only rotations are written, preserving the rest sockets.
-- Using the desired parent frame (not last frame's simulated CFrame) keeps the
-- supporting hand attached during a fast strike and when the character turns.
local function solve(a: Arm, torso: CFrame, hand: CFrame, pole: Vector3): (CFrame, CFrame, CFrame, number)
	local shoulder = (torso * a.s0).Position
	local target = (hand * a.w1).Position
	local delta = target - shoulder
	local actual = delta.Magnitude
	local d = math.clamp(actual, math.abs(a.upperLength - a.lowerLength) + 0.001,
		a.upperLength + a.lowerLength - 0.001)
	local direction = if actual > 0.0001 then delta / actual else -torso.UpVector
	local bend = pole - direction * pole:Dot(direction)
	if bend.Magnitude < 0.001 then bend = torso.LookVector:Cross(direction) end
	bend = bend.Unit
	local along = (a.upperLength ^ 2 - a.lowerLength ^ 2 + d ^ 2) / (2 * d)
	local height = math.sqrt(math.max(0, a.upperLength ^ 2 - along ^ 2))
	local elbow = shoulder + direction * along + bend * height
	local wrist = shoulder + direction * d
	local normal = direction:Cross(bend).Unit
	local upperRot = CFrame.lookAt(Vector3.zero, elbow - shoulder, normal) * a.upperAxis:Inverse()
	local lowerRot = CFrame.lookAt(Vector3.zero, wrist - elbow, normal) * a.lowerAxis:Inverse()
	local upperCF = CFrame.new(shoulder - upperRot:VectorToWorldSpace(a.s1.Position)) * upperRot
	local lowerCF = CFrame.new(elbow - lowerRot:VectorToWorldSpace(a.e1.Position)) * lowerRot
	local s = (torso * a.s0):Inverse() * upperCF * a.s1
	local e = (upperCF * a.e0):Inverse() * lowerCF * a.e1
	local w = (lowerCF * a.w0):Inverse() * hand * a.w1
	return s.Rotation, e.Rotation, w.Rotation, math.max(0, actual - d)
end

-- Project the shared handle into BOTH arms' reach, not each wrist separately.
-- Independent clamping separates the support hand from the actual Tool.
local function project(p: Vector3, c: Vector3, r: number): Vector3
	local v = p - c
	return if v.Magnitude > r then c + v.Unit * r else p
end

local function sharedReach(point: Vector3, c1: Vector3, r1: number, c2: Vector3, r2: number): Vector3
	local p1 = project(point, c1, r1)
	if (p1 - c2).Magnitude <= r2 then return p1 end
	local p2 = project(point, c2, r2)
	if (p2 - c1).Magnitude <= r1 then return p2 end
	local delta = c2 - c1
	local d = delta.Magnitude
	if d < 0.0001 then return project(point, c1, math.min(r1, r2)) end
	local axis = delta / d
	local x = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
	local centre = c1 + axis * x
	local radius = math.sqrt(math.max(0, r1 * r1 - x * x))
	local radial = point - centre
	radial -= axis * radial:Dot(axis)
	if radial.Magnitude < 0.0001 then
		radial = axis:Cross(if math.abs(axis.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis)
	end
	return centre + radial.Unit * radius
end

function Motion.Apply(rig: Rig, tool: Tool, startedAt: number, t: number, windup: number, recovery: number, equipWeight: number): boolean
	if not (rig.waist.Enabled and rig.right.wrist.Enabled and rig.left.shoulder.Enabled
		and rig.left.elbow.Enabled and rig.left.wrist.Enabled) then return false end
	local parent = rig.waist.Attachment0 and rig.waist.Attachment0.Parent
	if not (parent and parent:IsA("BasePart")) then return false end
	if rig.startedAt ~= startedAt then
		rig.startedAt = startedAt
		rig.leftStartS = rig.left.shoulder.Transform
		rig.leftStartE = rig.left.elbow.Transform
		rig.leftStartW = rig.left.wrist.Transform
		rig.waistStart = rig.waist.Transform
		-- Captured once per swing, not per frame: this weapon's own idle.
		rig.lowPos, rig.lowYaw, rig.lowElev = Motion.LowAnchor(rig, tool)
	end
	local position, rotation, waist, weight =
		Motion.Sample(t, windup, recovery, rig.lowPos, rig.lowYaw, rig.lowElev)
	weight *= equipWeight
	local neutral = parent.CFrame * rig.waist0 * rig.waist1:Inverse()
	local waistPose = rig.waistStart:Lerp(waist, weight)
	local torso = parent.CFrame * rig.waist0 * waistPose * rig.waist1:Inverse()
	local palm = neutral:PointToWorldSpace(position * rig.scale)
	local worldRot = neutral.Rotation * rotation
	local handle = CFrame.new(palm - worldRot:VectorToWorldSpace(tool.Grip.Position)) * worldRot
	-- Left palm immediately below the right palm on the same handle, with the
	-- same roll. The palms remain locked during the loaded/strike/follow phases.
	local support = tool.Grip + Vector3.new(0, -0.38 * rig.scale, 0)
	local rightOffset = tool.Grip * rig.right.grip:Inverse()
	local leftOffset = support * rig.left.grip:Inverse()
	local c1 = (torso * rig.right.s0).Position - worldRot:VectorToWorldSpace((rightOffset * rig.right.w1).Position)
	local c2 = (torso * rig.left.s0).Position - worldRot:VectorToWorldSpace((leftOffset * rig.left.w1).Position)
	local fitted = sharedReach(handle.Position, c1, rig.right.upperLength + rig.right.lowerLength - 0.02,
		c2, rig.left.upperLength + rig.left.lowerLength - 0.02)
	handle = CFrame.new(fitted) * worldRot
	local rightHand = handle * rightOffset
	local leftHand = handle * support * rig.left.grip:Inverse()
	local rs, re, rw = solve(rig.right, torso, rightHand, neutral:VectorToWorldSpace(Vector3.new(1, -0.65, 0.2)))
	local ls, le, lw = solve(rig.left, torso, leftHand, neutral:VectorToWorldSpace(Vector3.new(-1, -0.8, -0.15)))
	rig.right.shoulder.Transform = LOW_S:Lerp(rs, weight)
	rig.right.elbow.Transform = LOW_E:Lerp(re, weight)
	rig.right.wrist.Transform = CFrame.identity:Lerp(rw, weight)
	rig.left.shoulder.Transform = rig.leftStartS:Lerp(ls, weight)
	rig.left.elbow.Transform = rig.leftStartE:Lerp(le, weight)
	rig.left.wrist.Transform = rig.leftStartW:Lerp(lw, weight)
	rig.waist.Transform = waistPose
	return true
end

function Motion.Release(rig: Rig)
	rig.startedAt = nil
	rig.left.elbow.Transform = CFrame.identity
	rig.left.wrist.Transform = CFrame.identity
end

return Motion
