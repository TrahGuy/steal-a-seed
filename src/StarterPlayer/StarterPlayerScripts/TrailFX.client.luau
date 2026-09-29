--!strict
-- Steal a Seed :: TrailFX
--
-- THE BLOOMRUNNER TRAIL (2026-09-27), the reward wheel's rarest prize: a
-- mint-and-gold petal ribbon at leg height and a few drifting gold petals,
-- drawn only while its wearer is running. PURELY COSMETIC -- nothing reads it,
-- nothing it touches changes speed, reach or anything else.
--
-- Every client draws it for every player whose SeedTrail attribute names it --
-- WheelService publishes that from the saved profile on join and on every
-- change -- the way SpeedFX draws the Speed afterimage, and by SpeedFX's rules:
--
--   * REDUCED FX draws the ribbon alone and shorter; OFF builds nothing at all;
--   * never for somebody more than RemoteMaxStuds away, never on the frame a
--     body teleports (no streak drawn across the map), never while ragdolled,
--     seated or standing still;
--   * never behind a runner on the Floating Garden, where it would lie over the
--     next jump (2026-09-29; NOT ON THE COURSE, below) -- worn all the same;
--   * built per body, and everything goes with the body: on death, respawn,
--     taking the trail off, leaving -- and a body that vanishes on its own is
--     noticed by the next frame and its pieces destroyed.
--
-- Built only for wearers, so a server of forty people with none of them
-- wearing it costs nothing but the attribute watch.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
-- Only for ObbyData.onCourse: not drawn behind a runner (NOT ON THE COURSE, below).
local ObbyData = require(Shared:WaitForChild("ObbyData"))

local player = Players.LocalPlayer
local FX = GameConfig.Afterimage
local TRAIL = WheelData.Trail
local ATTR = WheelData.Attributes.Trail

local QUALITY_REDUCED = "Reduced"
local QUALITY_OFF = "Off"
local RIBBON_SECONDS = 0.55
-- The engine's own sparkle, tinted: no uploaded texture.
local PETAL_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

type Entry = {
	character: Model,
	root: BasePart,
	humanoid: Humanoid,
	pieces: { Instance },
	ribbon: Trail,
	petals: ParticleEmitter,
	lastPos: Vector3?,
	-- Whether its wearer was on the Floating Garden last frame (NOT ON THE COURSE).
	onCourse: boolean,
}

local tracked: { [Player]: Entry } = {}
local quality = "Full"

local function untrack(who: Player)
	local entry = tracked[who]
	tracked[who] = nil
	if entry then
		for _, piece in ipairs(entry.pieces) do
			if piece.Parent then
				piece:Destroy()
			end
		end
	end
end

local function wears(who: Player): boolean
	return who:GetAttribute(ATTR) == TRAIL.Id
end

local function track(who: Player)
	untrack(who)
	local character = who.Character
	if quality == QUALITY_OFF or not character or not wears(who) then
		return
	end
	task.spawn(function()
		local root = character:WaitForChild("HumanoidRootPart", 5)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not (root and humanoid and root:IsA("BasePart") and humanoid:IsA("Humanoid")) then
			return
		end
		-- The body waited for may no longer be the current one (SpeedFX's note).
		if not character.Parent or who.Character ~= character or not wears(who) or tracked[who]
			or quality == QUALITY_OFF then
			return
		end
		local low = Instance.new("Attachment")
		low.Name = "BloomrunnerLow"
		low.Position = Vector3.new(0, -2.0, 0.35)
		low.Parent = root
		local high = Instance.new("Attachment")
		high.Name = "BloomrunnerHigh"
		high.Position = Vector3.new(0, -0.7, 0.35)
		high.Parent = root
		local ribbon = Instance.new("Trail")
		ribbon.Name = "BloomrunnerRibbon"
		ribbon.Attachment0 = low
		ribbon.Attachment1 = high
		ribbon.FaceCamera = true
		ribbon.MinLength = 0.12
		ribbon.Lifetime = if quality == QUALITY_REDUCED then RIBBON_SECONDS * FX.ReducedLifetimeScale
			else RIBBON_SECONDS
		ribbon.LightEmission = 0.35
		ribbon.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, TRAIL.Mint),
			ColorSequenceKeypoint.new(0.5, TRAIL.Gold),
			ColorSequenceKeypoint.new(1, TRAIL.Leaf),
		})
		ribbon.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		ribbon.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.25),
		})
		ribbon.Enabled = false
		ribbon.Parent = root

		local spot = Instance.new("Attachment")
		spot.Name = "BloomrunnerPetals"
		spot.Position = Vector3.new(0, -1.4, 0.6)
		spot.Parent = root
		local petals = Instance.new("ParticleEmitter")
		petals.Name = "BloomrunnerPetals"
		petals.Texture = PETAL_TEXTURE
		petals.Color = ColorSequence.new(TRAIL.Gold, TRAIL.Mint)
		petals.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.32),
			NumberSequenceKeypoint.new(1, 0),
		})
		petals.Transparency = NumberSequence.new(0.15, 1)
		petals.Lifetime = NumberRange.new(0.6, 0.95)
		petals.Rate = 7
		petals.Speed = NumberRange.new(0.4, 1.4)
		petals.SpreadAngle = Vector2.new(40, 40)
		petals.Drag = 1.2
		petals.LightEmission = 0.5
		petals.Rotation = NumberRange.new(0, 360)
		petals.RotSpeed = NumberRange.new(-90, 90)
		petals.EmissionDirection = Enum.NormalId.Back
		petals.Enabled = false
		petals.Parent = spot

		tracked[who] = {
			character = character,
			root = root,
			humanoid = humanoid,
			pieces = { low, high, ribbon, spot },
			ribbon = ribbon,
			petals = petals,
			lastPos = nil,
			onCourse = false,
		}
	end)
end

local function running(entry: Entry): boolean
	local humanoid = entry.humanoid
	if humanoid.Health <= 0 or humanoid.PlatformStand then
		return false
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.Physics
		or state == Enum.HumanoidStateType.Seated then
		return false
	end
	local v = entry.root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude > FX.MinGroundSpeed
end

RunService.Heartbeat:Connect(function()
	if quality == QUALITY_OFF or next(tracked) == nil then
		return
	end
	local mine = player.Character
	local mineRoot = if mine then mine:FindFirstChild("HumanoidRootPart") else nil
	local here = if mineRoot and mineRoot:IsA("BasePart") then mineRoot.Position else nil
	for who, entry in pairs(tracked) do
		if not (entry.character.Parent and entry.root.Parent and entry.ribbon.Parent) then
			untrack(who)
		else
			local at = entry.root.Position
			local teleported = entry.lastPos ~= nil and (at - entry.lastPos).Magnitude > FX.TeleportStuds
			entry.lastPos = at
			local near = who == player or (here ~= nil and (at - here).Magnitude <= FX.RemoteMaxStuds)
			--==================================================================
			-- NOT ON THE COURSE (2026-09-29)
			--
			-- A runner on the Floating Garden wears it and shows none of it: the
			-- camera sits behind the body there, and a ribbon at leg height lies
			-- over the next jump. Drawn again the moment the server says the run
			-- is over (ObbyData.onCourse), by the rules above.
			--
			-- ONLY THE DRAWING. The SeedTrail attribute, the profile's Cosmetics
			-- and EquippedTrail, and the Bag's WEARING card are not touched --
			-- nothing is taken off, so nothing has to be put back on, and no way
			-- out of the course (Return, Exit, a death, leaving and rejoining)
			-- can leave it stuck either way. What is already in the air is
			-- cleared on the way in.
			--==================================================================
			local onCourse = ObbyData.onCourse(who)
			if onCourse ~= entry.onCourse then
				entry.onCourse = onCourse
				if onCourse then
					entry.ribbon:Clear()
					entry.petals:Clear()
				end
			end
			local want = near and not onCourse and not teleported and running(entry)
			if entry.ribbon.Enabled ~= want then
				entry.ribbon.Enabled = want
			end
			local sparkle = want and quality ~= QUALITY_REDUCED
			if entry.petals.Enabled ~= sparkle then
				entry.petals.Enabled = sparkle
			end
		end
	end
end)

local function watch(who: Player)
	who.CharacterAdded:Connect(function()
		track(who)
	end)
	who.CharacterRemoving:Connect(function()
		untrack(who)
	end)
	who:GetAttributeChangedSignal(ATTR):Connect(function()
		track(who)
	end)
	track(who)
end

for _, who in ipairs(Players:GetPlayers()) do
	watch(who)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(untrack)

-- The Settings panel's REDUCED FX, as SpeedFX reads it: a change rebuilds all.
local function setQuality()
	local want = player:GetAttribute(FX.QualityAttribute)
	local mode = if want == QUALITY_OFF or want == QUALITY_REDUCED then want else "Full"
	if mode == quality then
		return
	end
	quality = mode
	for _, who in ipairs(Players:GetPlayers()) do
		track(who)
	end
end
player:GetAttributeChangedSignal(FX.QualityAttribute):Connect(setQuality)
setQuality()
