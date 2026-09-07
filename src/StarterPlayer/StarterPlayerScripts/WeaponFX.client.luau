--!strict
-- Steal a Seed :: WeaponFX
--
-- How a bat is held, how it is swung, and the flash when it lands. Presentation
-- only.
--
--==============================================================================
-- THE SERVER SAYS WHEN. THIS SAYS WHAT IT LOOKS LIKE.
--
-- CombatService stamps three attributes on the Tool -- SwingAt, SwingWindup,
-- SwingRecover -- and a fourth, HitAt, if the swing connected. Attributes
-- replicate on their own, so every client that can see the character holding
-- the bat draws the same swing at the same moment, with no remote and nothing
-- to be trusted with.
--
-- Exactly the split ParentAnim runs on for the guardians: the server owns the
-- event and every client owns the joint. Nothing in this file decides whether a
-- hit happened, who it hit, or what it did.
--
--==============================================================================
-- IT POSES THE ARM. THE PREVIOUS THREE PASSES COULD NOT, AND HERE IS WHY.
--
-- This file, WeaponData and HANDOFF all used to record the right shoulder as
-- INERT -- that `AnimationConstraint.Transform` was written and read back as
-- -0.000 the next frame, that the animator never touched the joint either, and
-- that a swing therefore had to rotate the WEAPON while the arm hung down. On
-- that basis a custom PUBLISHED animation was written up as the only way out.
--
-- All of it was one bug in our own code. `CarryPose.client.luau` released the
-- shoulders by writing `Transform = rest` on EVERY FRAME in `Stepped` -- which
-- is after the animator runs -- so it reverted the animation, every frame, for
-- the whole session, on every character. Measured on the live avatar playing
-- Roblox's own `wave`:
--
--     CarryPose running     right shoulder swept   0.0 deg
--     CarryPose disabled    right shoulder swept  17.1 deg
--
-- and sweeping all fifteen joints showed the animator driving eleven of them
-- while both shoulders sat at exactly (-0.0, 0.0, -0.0). CarryPose now releases
-- once and latches, and the joint answers normally. Driven from `Stepped`:
--
--     commanded X 30 deg  ->  measured 29.4      hand (1.42, -0.74, -0.87)
--     commanded X 60 deg  ->  measured 59.4      hand (1.49, -0.12, -1.32)
--     commanded X 90 deg  ->  measured 89.6      hand (1.57,  0.63, -1.40)
--
-- So the arm tracks a commanded angle to within a degree, and NO PUBLISHED
-- ASSET IS NEEDED for any of this: the ready pose and the swing are both
-- evaluated locally from the shared BatSwingMotion handle trajectory.
--
--==============================================================================
-- WHICH JOINTS ARE HELD, AND WHICH ARE LEFT ALONE
--
--   RIGHT SHOULDER + ELBOW   held for as long as a bat is equipped. That is the
--                            ready pose, and it has to override the walk cycle
--                            or the bat waves about while you run.
--   LEFT ARM + WAIST         driven ONLY through a swing, and released the
--                            moment it ends. At rest the off arm swings with
--                            the walk like anybody else's, which is what "the
--                            other arm relaxed" means; and the waist belongs to
--                            the walk cycle except in the half second it is
--                            being used to put the body behind a strike.
--   EVERYTHING ELSE          never touched. Hips, knees, ankles and neck stay
--                            with the animator, which is what keeps walking and
--                            jumping working underneath the pose.
--
-- Writing `Transform` OVERRIDES the animation for that joint, so every joint
-- taken here is a joint the walk cycle loses. That is the whole reason the list
-- is limited to the arms and waist rather than the entire body.
--
--==============================================================================
-- AND IT LETS GO ONCE, NOT FOREVER
--
-- The release path writes rest a single time and latches -- `posed.released`.
-- Re-writing rest every frame is precisely the bug described above, and this
-- file drives the same joints from the same phase, so it would have reproduced
-- it exactly.
--
-- A client writing an AnimationConstraint or a Weld is a LOCAL write -- property
-- changes replicate server-to-client only -- so every machine draws this for
-- itself off the same replicated timestamp and there is nothing to double-apply.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local BatSwingMotion = require(Shared:WaitForChild("BatSwingMotion"))

local SWING_AT = "SwingAt"
local SWING_WINDUP = "SwingWindup"
local SWING_RECOVER = "SwingRecover"
local HIT_AT = "HitAt"

local CARRYING_KG = GameConfig.Attributes.CarryingKg

-- How quickly the ready pose fades in on equip and out on unequip. Fast enough
-- to feel like drawing a weapon, slow enough not to read as a teleport.
local EQUIP_BLEND = 11

type Pose = {
	-- Degrees, in each joint's own frame. X swings the arm forward, Z spreads it
	-- away from the ribs, Y turns it across the body -- measured on this rig,
	-- not assumed, and the same convention CarryPose records.
	Shoulder: Vector3,
	Elbow: Vector3,
	--==========================================================================
	-- AND THE WRIST, WHICH IS NOT OPTIONAL
	--
	-- Left undriven, the bat's own weight rotates it. Measured: with the arm
	-- posed and the wrist free, the barrel swung from pointing UP AND ACROSS
	-- (-0.30, 0.91, 0.29) to hanging DOWN AND BACK (-0.46, -0.56, 0.69) within a
	-- second, and stayed there. A four-stud lever on a physics rig is a lever.
	--==========================================================================
	Wrist: Vector3,
	-- The off arm and the chest. Zero in the hold because neither is driven
	-- there -- they are borrowed for the swing and given straight back.
	Left: Vector3,
	Waist: Vector3,
}

--==============================================================================
-- THE LOW HOLD
--
-- The owner's direction, and it replaces an over-the-shoulder rest pose that
-- was rejected. The bat is carried LOW, in one hand, beside the body: normal
-- upright torso, head and legs, the holding arm hanging where the rig already
-- hangs it, and the barrel running away from the body and slightly down.
--
-- THE MOST IMPORTANT MEASUREMENT HERE IS THAT ALMOST NOTHING IS NEEDED.
-- With every joint at zero the rig already puts the right hand at
-- (1.38, -1.09, 0.05) in torso space -- hip height, beside the thigh, which is
-- the low hold. A solver asked for that hand position while being charged for
-- every degree it spent came back with six degrees of shoulder and five of
-- elbow.
--
-- So why write the joints at all? Because equipping a Tool makes Roblox play
-- its own tool-hold animation, which raises the arm to (83.8, 1.4, -6.5) --
-- measured, by releasing the joints and reading what the animator put there.
-- These values do not pose the character into anything; they hold the arm at
-- the rest it would have had with empty hands.
--
-- The off arm and the waist are NOT driven here. At idle they belong to the
-- walk cycle, which is what keeps the other arm relaxed and the chest untwisted
-- without this file having to author either.
--==============================================================================
local LOW_HOLD: Pose = {
	Shoulder = Vector3.new(6, 0, 7),
	Elbow = Vector3.new(5, 0, 0),
	Wrist = Vector3.zero,
	Left = Vector3.zero,
	Waist = Vector3.zero,
}

-- BatSwingMotion owns the two-hand shoulder coil, forward strike and recovery.
-- There is no legacy one-arm attack fallback: an incomplete streamed rig keeps
-- its low hold until the full arm sockets can be bound on the next attack.

type Swing = {
	tool: Tool,
	startedAt: number,
	windup: number,
	recover: number,
}

type Posed = {
	twoHand: BatSwingMotion.Rig?,
	character: Model,
	humanoid: Humanoid,
	player: Player?,
	shoulder: AnimationConstraint,
	elbow: AnimationConstraint,
	wrist: AnimationConstraint?,
	left: AnimationConstraint?,
	waist: AnimationConstraint?,
	-- 0 when the arms belong to the animator, 1 when they belong to this file.
	weight: number,
	-- Whether the joints have already been handed back. See the header.
	released: boolean,
	--==========================================================================
	-- AND WHETHER THE SWING-ONLY JOINTS ARE CURRENTLY OURS
	--
	-- The off arm and the waist are borrowed for the half second of a strike and
	-- given straight back. Without this latch the release would be a write on
	-- every frame -- the CarryPose bug in the header, reproduced by the file that
	-- documents it.
	--==========================================================================
	swingHeld: boolean,
	swing: Swing?,
}

local posed: { [Model]: Posed } = {}
local watching: { [Tool]: { RBXScriptConnection } } = {}
local loop: RBXScriptConnection? = nil
local warned: { [Model]: boolean } = {}

--==============================================================================
-- THE JOINTS
--
-- Constraints live on the CHILD part of the pair -- RightShoulder inside
-- RightUpperArm, Waist inside UpperTorso -- which is how the rig names them.
-- The right shoulder and elbow are required; the off arm and the waist are
-- nice-to-have, so a rig missing either still gets a pose instead of nothing.
--==============================================================================
local function constraintIn(character: Model, part: string, joint: string): AnimationConstraint?
	local p = character:FindFirstChild(part)
	local j = p and p:FindFirstChild(joint)
	if j and j:IsA("AnimationConstraint") then
		return j
	end
	return nil
end

local function buildPosed(character: Model): Posed?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local shoulder = constraintIn(character, "RightUpperArm", "RightShoulder")
	local elbow = constraintIn(character, "RightLowerArm", "RightElbow")
	if not (humanoid and shoulder and elbow) then
		if not warned[character] then
			warned[character] = true
			warn("[Seed/WeaponFX] " .. character.Name
				.. " has no R15 right arm constraints; its bat will not be posed.")
		end
		return nil
	end
	return {
		twoHand = BatSwingMotion.Bind(character),
		character = character,
		humanoid = humanoid,
		player = Players:GetPlayerFromCharacter(character),
		shoulder = shoulder,
		elbow = elbow,
		wrist = constraintIn(character, "RightHand", "RightWrist"),
		left = constraintIn(character, "LeftUpperArm", "LeftShoulder"),
		waist = constraintIn(character, "UpperTorso", "Waist"),
		weight = 0,
		released = true,
		swingHeld = false,
		swing = nil,
	}
end

--==============================================================================
-- WHAT IS ACTUALLY IN THE HAND
--
-- A BAT, and only a bat. The trap is a weapon item too and it is placed, not
-- swung, so switching to it drops the pose -- as does any other Tool, a pod
-- included, and an empty hand.
--==============================================================================
local function battedTool(character: Model): (Tool?, WeaponData.Item?)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			local item = WeaponData.Get(child:GetAttribute(WeaponModel.ItemAttribute))
			if item and item.Category == "bat" then
				return child, item
			end
			-- Exactly one Tool is equipped at a time, so the first one found
			-- settles it either way.
			return nil, nil
		end
	end
	return nil, nil
end

--==============================================================================
-- WHEN THE ARMS ARE NOT OURS TO POSE
--
-- Every one of these is a state where something else owns the body, and holding
-- a bat pose through it is either wrong or a fight:
--
--   carrying     CarryPose has both shoulders under a pod. One writer per joint.
--   ragdoll      NestService DISABLES the AnimationConstraints to go limp, so a
--                write here would do nothing at all -- and PlatformStand is the
--                same state a frame earlier, before the constraints are off.
--   dead         the joints belong to the death animation.
--==============================================================================
local function mayPose(entry: Posed): boolean
	if entry.humanoid.Health <= 0 or entry.humanoid.PlatformStand then
		return false
	end
	if not (entry.shoulder.Enabled and entry.elbow.Enabled) then
		return false
	end
	local player = entry.player
	if player and type(player:GetAttribute(CARRYING_KG)) == "number" then
		return false
	end
	-- A banked pod is still a carried pod: it becomes a Tool with the weight
	-- stamped on it, and CarryPose follows it there. Same reasoning as the
	-- fallback in CarryPose, and it cannot be a bat, so no bat is lost to it.
	for _, child in ipairs(entry.character:GetChildren()) do
		if child:IsA("Tool") and type(child:GetAttribute(CARRYING_KG)) == "number" then
			return false
		end
	end
	return true
end

--==============================================================================
-- ONE LOOP FOR EVERY BAT ON SCREEN
--
-- Registered rather than a connection per character, for the reason UIKit's card
-- pump exists: seventeen per-frame connections was the thing that made the HUD
-- lag. It disconnects the moment the last bat is put away, so a server where
-- nobody is armed costs nothing at all.
--
-- `Stepped`, not Heartbeat: that is after the animation has been evaluated for
-- the frame. Writing earlier loses the race -- measured, and the reason
-- CarryPose runs in the same phase.
--==============================================================================
local function angles(v: Vector3): CFrame
	return CFrame.Angles(math.rad(v.X), math.rad(v.Y), math.rad(v.Z))
end

local function letGo(entry: Posed)
	if entry.released then
		return
	end
	--==========================================================================
	-- ONCE. NOT EVERY FRAME.
	--
	-- Identity is this rig's neutral for an AnimationConstraint -- the animator
	-- writes an absolute local transform each frame, so handing a joint back
	-- means writing nothing at all and letting it do that. The single write here
	-- only guarantees nothing is left displaced in the frame before it resumes.
	--==========================================================================
	entry.released = true
	entry.weight = 0
	entry.swing = nil
	entry.swingHeld = false
	if entry.twoHand then
		BatSwingMotion.Release(entry.twoHand)
	end
	if entry.shoulder.Parent then
		entry.shoulder.Transform = CFrame.identity
	end
	if entry.elbow.Parent then
		entry.elbow.Transform = CFrame.identity
	end
	if entry.wrist and entry.wrist.Parent then
		entry.wrist.Transform = CFrame.identity
	end
	if entry.left and entry.left.Parent then
		entry.left.Transform = CFrame.identity
	end
	if entry.waist and entry.waist.Parent then
		entry.waist.Transform = CFrame.identity
	end
end

local function step(_, dt: number)
	local clock = Workspace:GetServerTimeNow()
	local alpha = math.min(1, dt * EQUIP_BLEND)
	local any = false

	for character, entry in pairs(posed) do
		if not character.Parent then
			posed[character] = nil
			continue
		end

		local tool = battedTool(character)
		local want = if tool and mayPose(entry) then 1 else 0
		-- An interrupted attack must never continue on a newly equipped bat.
		if entry.swing and (entry.swing.tool ~= tool or want == 0) then
			entry.swing = nil
		end

		entry.weight += (want - entry.weight) * alpha
		if want == 0 and entry.weight < 0.004 then
			letGo(entry)
			--==============================================================
			-- A SUPPRESSED POSE IS NOT A FINISHED ONE
			--
			-- Letting go because of a ragdoll or a carried pod is temporary:
			-- the bat is still in the hand and the pose has to come back when
			-- the state clears. Nothing else would wake this loop -- the wake
			-- calls all hang off a Tool arriving or leaving, and neither
			-- happens when somebody gets up off the floor.
			--
			-- Found by testing: ragdoll a player holding a bat, stand them
			-- back up, and the shoulder stayed on the animator's tool pose at
			-- (83.8, 1.4, -6.5) instead of returning to (5, 34, 62). It took a
			-- re-equip to come back.
			--
			-- An EMPTY hand still stops the loop, which is the case that
			-- matters for cost: a server where nobody is armed pays nothing.
			--==============================================================
			if tool then
				any = true
			end
			continue
		end
		entry.released = false
		any = true

		local swing = entry.swing
		if swing and tool and entry.twoHand then
			local elapsed = clock - swing.startedAt
			if elapsed >= 0 and elapsed < swing.windup + swing.recover
				and BatSwingMotion.Apply(entry.twoHand, tool, swing.startedAt,
					elapsed, swing.windup, swing.recover, entry.weight) then
				entry.swingHeld = true
				continue
			end
		end
		if swing and clock - swing.startedAt >= swing.windup + swing.recover then
			entry.swing = nil
		end
		local pose: Pose = LOW_HOLD

		--======================================================================
		-- SCALED BY THE EQUIP BLEND, WHICH IS ALSO THE UNEQUIP BLEND
		--
		-- Every angle is measured from the rig's neutral, so multiplying by the
		-- weight is a clean fade between "the animator has this joint" and "we
		-- do" -- in both directions, with no second code path for letting go.
		--======================================================================
		local w = entry.weight
		entry.shoulder.Transform = angles(pose.Shoulder * w)
		entry.elbow.Transform = angles(pose.Elbow * w)
		if entry.wrist then
			entry.wrist.Transform = angles(pose.Wrist * w)
		end
		--======================================================================
		-- THE OFF ARM AND THE WAIST ARE ONLY BORROWED FOR THE SWING
		--
		-- Writing them whenever a bat is equipped pins them -- their LOW_HOLD values
		-- are zero, so the write is `identity`, every frame, which is not "leave
		-- this joint alone", it is "hold this joint at neutral". Measured before
		-- this branch existed: with a bat held and the character jumping, the
		-- hips swept 9.0 degrees, the knees 12.6 and the neck 25.1, while the off
		-- shoulder and the waist swept EXACTLY 0.0.
		--
		-- That is the same mistake CarryPose made and this file's own header
		-- describes. Driven only while a swing is running, released once when it
		-- ends, and the walk cycle has them back for everything else.
		--======================================================================
		if entry.swingHeld then
			entry.swingHeld = false
			if entry.twoHand then BatSwingMotion.Release(entry.twoHand) end
			if entry.left then
				entry.left.Transform = CFrame.identity
			end
			if entry.waist then
				entry.waist.Transform = CFrame.identity
			end
		end
	end

	if not any and loop then
		loop:Disconnect()
		loop = nil
	end
end

local function wake()
	if not loop then
		loop = RunService.Stepped:Connect(step)
	end
end

local function entryFor(character: Model): Posed?
	local entry = posed[character]
	if not entry then
		entry = buildPosed(character)
		if not entry then
			return nil
		end
		posed[character] = entry
	end
	return entry
end

local function beginSwing(tool: Tool)
	local at = tool:GetAttribute(SWING_AT)
	if type(at) ~= "number" then
		return
	end
	local character = tool.Parent
	if not (character and character:IsA("Model")) then
		return
	end
	local entry = entryFor(character)
	if not entry then
		return
	end
	-- A Tool can replicate before the off-hand attachments. Retry on an attack,
	-- not every frame, so an early partial rig never permanently loses its grip.
	if not entry.twoHand then entry.twoHand = BatSwingMotion.Bind(character) end
	entry.swing = {
		tool = tool,
		startedAt = at,
		windup = math.clamp(tonumber(tool:GetAttribute(SWING_WINDUP)) or 0.2, 0.02, 2),
		recover = math.clamp(tonumber(tool:GetAttribute(SWING_RECOVER)) or 0.3, 0.05, 2),
	}
	wake()
end

--==============================================================================
-- THE IMPACT
--
-- Six shards off the head of the weapon, out and down, gone in a third of a
-- second. Each weapon throws its own accent colour, so the Sunflower bursts in
-- petals and the Cindercrack in embers without a second effect being written.
--
-- BRIEF AND SMALL ON PURPOSE. The brief asks for effects that do not obscure the
-- target, and this is a hit at arm's length -- the person who was struck has to
-- be able to see where they are being thrown. Six parts, no particle emitter, no
-- light, and nothing that outlives a third of a second.
--==============================================================================
local BURST_PARTS = 6
local BURST_SECONDS = 0.30

local function burst(tool: Tool)
	local item = WeaponData.Get(tool:GetAttribute(WeaponModel.ItemAttribute))
	if not item then
		return
	end
	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		return
	end
	-- Off the HEAD, not the grip: the weapon runs up +Y out of its handle, so
	-- the business end is a few studs along the handle's own up axis. Taken from
	-- the handle's CFrame rather than a bounding box, which would mean walking
	-- every part on a swing that happens several times a second.
	local origin = handle.CFrame * CFrame.new(0, 4.2, 0)
	local colour = item.Palette.Glow or item.Palette.Accent

	for i = 1, BURST_PARTS do
		local shard = Instance.new("Part")
		shard.Name = "Impact"
		shard.Size = Vector3.new(0.22, 0.22, 0.42) * (1.4 - i * 0.12)
		shard.CFrame = origin * CFrame.Angles(
			math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		shard.Color = colour
		shard.Material = Enum.Material.Neon
		shard.Anchored = true
		shard.CanCollide = false
		shard.CanQuery = false
		shard.CanTouch = false
		shard.Transparency = 0.15
		shard.Parent = Workspace

		local drift = Vector3.new(
			math.random() * 2 - 1, math.random() * 0.9, math.random() * 2 - 1).Unit * 3.4
		local target = shard.CFrame + drift
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < BURST_SECONDS and shard.Parent do
				local u = (os.clock() - t0) / BURST_SECONDS
				shard.CFrame = shard.CFrame:Lerp(target, math.min(1, u * 0.35))
				shard.Transparency = 0.15 + 0.85 * u
				RunService.Heartbeat:Wait()
			end
			shard:Destroy()
		end)
		-- A backstop, so a shard whose thread is killed cannot outlive the game.
		Debris:AddItem(shard, BURST_SECONDS + 0.6)
	end
end

--==============================================================================
-- FINDING THE TOOLS
--
-- Every character on this client, own and other, plus whatever arrives later.
-- Streaming means a distant player's character can appear at any moment, so this
-- is by signal rather than a sweep at login.
--==============================================================================
local function unwatch(tool: Tool)
	local conns = watching[tool]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		watching[tool] = nil
	end
end

local function watchTool(tool: Tool)
	if watching[tool] then
		return
	end
	if not WeaponData.Get(tool:GetAttribute(WeaponModel.ItemAttribute)) then
		return
	end
	local conns: { RBXScriptConnection } = {}
	table.insert(conns, tool:GetAttributeChangedSignal(SWING_AT):Connect(function()
		beginSwing(tool)
	end))
	table.insert(conns, tool:GetAttributeChangedSignal(HIT_AT):Connect(function()
		burst(tool)
	end))
	table.insert(conns, tool.AncestryChanged:Connect(function()
		local character = tool.Parent
		if character and character:IsA("Model") and character:FindFirstChildOfClass("Humanoid") then
			-- Equipped. The pose loop picks it up from here.
			if entryFor(character) then
				wake()
			end
		end
	end))
	watching[tool] = conns
	tool.Destroying:Connect(function()
		unwatch(tool)
	end)
end

local function watchCharacter(character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			watchTool(child)
		end
	end
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			watchTool(child)
			if entryFor(character) then
				wake()
			end
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			-- Put away. Waking is what lets the blend run DOWN to zero and then
			-- let go; without it the loop could already have stopped with the
			-- arms still posed.
			wake()
		end
	end)
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(Workspace) then
			posed[character] = nil
			warned[character] = nil
		end
	end)
end

local function watchPlayer(other: Player)
	if other.Character then
		watchCharacter(other.Character)
	end
	other.CharacterAdded:Connect(watchCharacter)
	other.CharacterRemoving:Connect(function(character)
		posed[character] = nil
		warned[character] = nil
	end)
end

for _, other in ipairs(Players:GetPlayers()) do
	watchPlayer(other)
end
Players.PlayerAdded:Connect(watchPlayer)
