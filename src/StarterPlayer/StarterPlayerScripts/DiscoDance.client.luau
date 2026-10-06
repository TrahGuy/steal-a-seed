--!strict
-- Steal a Seed :: DiscoDance
--
-- DISCO DANCING (2026-10-03, TICKET DISCO / DISCO ONLY). While a disco mode
-- runs, this player's own avatar dances when it stands still in the hub area --
-- Roblox's own dance animations (R15 or R6, GameConfig.MiniEvent.Dance), played
-- on the character's own Animator, so everybody nearby sees it too (a
-- character's animation replicates from its owner). Nothing is sent to the
-- server, and nothing else's animation is touched.
--
-- ONE BEAT FOR EVERYONE. Which dance and how far into it are both read off the
-- event's shared start time (MiniEventStartedAt, an absolute server time that
-- every server of the place shares) -- every VariantSeconds the next dance, in
-- step on every screen. A player who starts dancing late joins mid-step rather
-- than from the top.
--
-- ANYTHING MORE IMPORTANT WINS, AT ONCE. It does not dance -- and stops,
-- faded over FadeSeconds -- while the player:
--   carries a pod or a plant (CarryingSpecies), or holds ANY Tool (the bat, the
--   trap, the Spin Ticket, a carried item): equipment and the carry come first
--   and keep their own poses (CarryPose, WeaponFX);
--   walks, jumps, falls, climbs, swims, sits or is thrown (the Humanoid's own
--   state), or stood still for less than SettleSeconds;
--   stands on a mill, is trapped or is being chased;
--   is outside Dance.Radius of the hub, is dead, or the disco is ending.
--
-- THE PLAYER'S CHOICE. Off when the saved DISCO DANCING setting is off (the
-- DiscoDance attribute, Settings), and never under reduced motion (Reduced FX,
-- or Roblox's own). Rebuilt for every new body; nothing survives a respawn.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))

local player = Players.LocalPlayer
local M = GameConfig.MiniEvent
local ATTR = M.Attributes
local DANCE = M.Dance
local A = GameConfig.Attributes
local MODES: { [string]: any } = M.Modes :: any
local HUB = M.Area.Centre

local BUSY_STATES: { [Enum.HumanoidStateType]: boolean } = {
	[Enum.HumanoidStateType.Jumping] = true,
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.Physics] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.PlatformStanding] = true,
	[Enum.HumanoidStateType.GettingUp] = true,
	[Enum.HumanoidStateType.Dead] = true,
}

type Rig = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	tracks: { AnimationTrack },
	playing: number,
	lastMoved: number,
	lastSync: number,
}

local rig: Rig? = nil

local function discoOn(): boolean
	if Workspace:GetAttribute(ATTR.State) ~= "running" then
		return false
	end
	local mode = MODES[Workspace:GetAttribute(ATTR.Mode) or ""]
	return mode ~= nil and mode.Disco == true
end

local function stop(r: Rig)
	if r.playing ~= 0 then
		local track = r.tracks[r.playing]
		if track then
			track:Stop(DANCE.FadeSeconds)
		end
		r.playing = 0
	end
end

local function build(character: Model): Rig?
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not (humanoid and humanoid:IsA("Humanoid") and root and root:IsA("BasePart")) then
		return nil
	end
	return {
		character = character,
		humanoid = humanoid,
		root = root,
		tracks = {},
		playing = 0,
		lastMoved = os.clock(),
		lastSync = 0,
	}
end

-- The tracks, loaded the first time this body dances.
local function tracksOf(r: Rig): { AnimationTrack }
	if #r.tracks > 0 then
		return r.tracks
	end
	local animator = r.humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return r.tracks
	end
	local ids = if r.humanoid.RigType == Enum.HumanoidRigType.R15 then DANCE.R15 else DANCE.R6
	for i, id in ipairs(ids) do
		local animation = Instance.new("Animation")
		animation.Name = "DiscoDance" .. i
		animation.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if ok and track then
			track.Looped = true
			track.Priority = Enum.AnimationPriority.Action
			table.insert(r.tracks, track)
		end
	end
	return r.tracks
end

local function mayDance(r: Rig): boolean
	if not discoOn() or player:GetAttribute(A.DiscoDance) == false or StatusText.reducedMotion() then
		return false
	end
	local humanoid, character = r.humanoid, r.character
	if humanoid.Health <= 0 or character.Parent == nil then
		return false
	end
	-- Equipment and the carry first.
	if character:FindFirstChildOfClass("Tool") or player:GetAttribute(A.CarryingSpecies) ~= nil then
		return false
	end
	if player:GetAttribute(A.MillMounted) or player:GetAttribute(A.Trapped) or player:GetAttribute(A.PursuedBy) then
		return false
	end
	-- Training on any belt -- the Disco Mill stands inside the dance radius
	-- (2026-10-04) -- runs, never dances: SpeedFX's run owns the legs there.
	if player:GetAttribute(A.OnTreadmill) then
		return false
	end
	if humanoid.Sit or humanoid.PlatformStand or BUSY_STATES[humanoid:GetState()] then
		r.lastMoved = os.clock()
		return false
	end
	if humanoid.MoveDirection.Magnitude > 0.05 then
		r.lastMoved = os.clock()
		return false
	end
	if os.clock() - r.lastMoved < DANCE.SettleSeconds then
		return false
	end
	local p = r.root.Position
	return Vector2.new(p.X - HUB.X, p.Z - HUB.Z).Magnitude <= DANCE.Radius
end

RunService.Heartbeat:Connect(function()
	local r = rig
	if not r then
		return
	end
	if not mayDance(r) then
		stop(r)
		return
	end
	local tracks = tracksOf(r)
	if #tracks == 0 then
		return
	end
	local startedAt = tonumber(Workspace:GetAttribute(ATTR.StartedAt)) or 0
	local elapsed = math.max(0, Workspace:GetServerTimeNow() - startedAt)
	local want = (math.floor(elapsed / DANCE.VariantSeconds) % #tracks) + 1
	local track = tracks[want]
	local length = track.Length
	local phase = if length > 0 then (elapsed % DANCE.VariantSeconds) % length else 0
	if r.playing ~= want then
		stop(r)
		track:Play(DANCE.FadeSeconds)
		r.playing = want
		r.lastSync = 0
	end
	-- In step with the shared clock: set when it starts, and again only if it
	-- has drifted (checked twice a second, never written every frame).
	if length > 0 and os.clock() - r.lastSync > 0.5 then
		r.lastSync = os.clock()
		if math.abs(track.TimePosition - phase) > 0.25 then
			track.TimePosition = phase
		end
	end
end)

local function onCharacter(character: Model)
	local before = rig
	if before then
		stop(before)
	end
	rig = nil
	local made = build(character)
	if made and player.Character == character then
		rig = made
	end
end

player.CharacterAdded:Connect(onCharacter)
player.CharacterRemoving:Connect(function()
	local r = rig
	if r then
		stop(r)
	end
	rig = nil
end)
if player.Character then
	task.spawn(onCharacter, player.Character)
end
