--!nocheck
-- Mathematical R15 attachment fixture, NOT a multiplayer/visual playtest.
-- Run with tools/tests/run.luau in Edit for fresh source throughout.
local Shared = game.ReplicatedStorage.SeedGame.Shared
local Motion = require(Shared.BatSwingMotion)
local Data = require(Shared.WeaponData)
local Models = require(Shared.WeaponModel)
local passed = 0
local peak = 0
local function check(ok, label)
	assert(ok, label)
	passed += 1
end
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
local function handFrame(a, torso)
	local upper = torso*a.s0*a.shoulder.Transform*a.s1:Inverse()
	local lower = upper*a.e0*a.elbow.Transform*a.e1:Inverse()
	return lower*a.w0*a.wrist.Transform*a.w1:Inverse()
end
for _, scale in {.85, 1, 1.15} do
	local c = fixture(scale)
	local rig = Motion.Bind(c)
	check(rig ~= nil, "bind fixture " .. scale)
	for _, item in Data.Items do
		if item.Category ~= "bat" then continue end
		local tool = Models.BuildTool(item)
		local originalGrip = tool.Grip
		local originalSocket = rig.right.shoulder.Attachment0.CFrame
		local maxGap = 0
		local start = item.Windup*.52
		local finish = item.Windup + item.Recovery*.36
		for n = 0, 60 do
			local t = start + (finish-start)*n/60
			assert(Motion.Apply(rig, tool, n+1, t, item.Windup, item.Recovery, 1))
			local torso = rig.waist.Attachment0.Parent.CFrame*rig.waist0*rig.waist.Transform*rig.waist1:Inverse()
			local right = handFrame(rig.right, torso)
			local left = handFrame(rig.left, torso)
			local handle = right*rig.right.grip*tool.Grip:Inverse()
			local support = handle*(tool.Grip+Vector3.new(0,-.38*rig.scale,0))
			maxGap = math.max(maxGap, ((left*rig.left.grip).Position-support.Position).Magnitude)
			assert(maxGap == maxGap, "finite hand solve")
		end
		peak = math.max(peak, maxGap)
		check(maxGap < .04, item.Id .. " shared grip gap " .. maxGap .. " at scale " .. scale)
		local _, hit = Motion.Sample(item.Windup, item.Windup, item.Recovery)
		check(hit.UpVector.Z < -.99, item.Id .. " contact points forward at server hit time")
		check(select(4, Motion.Sample(0,item.Windup,item.Recovery)) == 0
			and select(4, Motion.Sample(item.Windup+item.Recovery,item.Windup,item.Recovery)) == 0,
			item.Id .. " acquisition/recovery blend endpoints")
		check(tool.Grip == originalGrip and rig.right.shoulder.Attachment0.CFrame == originalSocket,
			item.Id .. " no grip/socket mutation")
		Motion.Release(rig)
		check(rig.startedAt == nil and rig.left.elbow.Transform == CFrame.identity
			and rig.left.wrist.Transform == CFrame.identity, item.Id .. " releases support joints")
		tool:Destroy()
	end
	c:Destroy()
end
return string.format("BatSwingSpec %d/%d; 18 bat/scale combinations, 1098 active-arc samples; max support gap %.6f studs. Mathematical fixture only; live animation and PvP require Play.", passed, passed, peak)
