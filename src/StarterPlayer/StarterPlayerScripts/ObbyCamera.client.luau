--!strict
-- Steal a Seed :: ObbyCamera
--
-- Turns the camera to face the route, ONCE, each time the Floating Garden puts
-- this player down: the start island, a checkpoint after a fall, the summit
-- after a fall from it, and the arch the OBBY button lands in front of. After
-- that the camera is the player's -- nothing here runs until the next time.
--
-- WHY, AND HOW: Shared/ObbyView. In short, a phone's camera turns to look the
-- way its subject has just travelled, a fall's way back to its checkpoint is
-- backward, and the stick is read against the camera. ObbyView is the
-- arithmetic and the state machine; this owns the camera and the events.
--
--==============================================================================
-- WHAT STARTS IT: THE SERVER'S OWN ATTRIBUTES, AND ONE OF THIS CLIENT'S
--
--   ObbyFalls going UP          a fall: back on the respawn ObbyCheckpoint names
--   ObbyCheckpoint = "start"    a run begun, from the arch's prompt or the
--   (on the course)             pavilion's Replay
--   ObbyEntranceAsked           this client's own note that the OBBY button was
--                               pressed (ObbyButtonUI); it never leaves this
--                               machine, and the server may still refuse
--
-- None of them turns the camera. Each only says where the body is about to be
-- put, and the turn is made when the body is FOUND there -- within ArriveStuds
-- of the landing, which a falling body never is -- or given up after a few
-- seconds. So a refused press, a death on the way, or a teleport that never
-- comes turns nothing.
--
--==============================================================================
-- ONE STEP, AND ONLY ON THE COURSE
--
-- One render step, bound while this player is on the course or a placement is
-- expected, and unbound the frame neither is true: off the Floating Garden
-- nothing here runs at all. It runs just before the engine's own camera step.
--
-- ON THE COURSE IT ALSO WATCHES THE BODY ITSELF (ObbyView.placed): a body that
-- is suddenly standing on a landing has been put there, whatever has or has
-- not arrived to say so. Measured 2026-09-29, turning on the attributes alone
-- was one frame late after a fall -- the fall's count and the body's new place
-- arrive together, and the count's signal runs after that frame's camera
-- step -- and the wrong way was drawn for that one frame. Watching the body,
-- the frame it lands is the frame the camera is turned.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VRService = game:GetService("VRService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local ObbyView = require(Shared:WaitForChild("ObbyView"))

local player = Players.LocalPlayer
local OA = ObbyData.Attributes
local STEP = "SeedObbyCamera"
-- The same CFrame written again AFTER the engine's camera step, while a hold is
-- on. Measured 2026-09-29: the frame the camera is taken, the engine's step
-- still runs once -- it hears of the change after the frame -- and writes its
-- own turned-round camera over ours. Written last, ours is what is drawn.
local STEP_AFTER = "SeedObbyCameraAfter"
-- On the camera while it is in our hands, so a copy of this script that is run
-- again (a Rojo sync) can hand back what the last copy took.
local HELD = "SeedObbyCameraHeld"

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
pcall(function()
	RunService:UnbindFromRenderStep(STEP)
end)
pcall(function()
	RunService:UnbindFromRenderStep(STEP_AFTER)
end)

local function handBack()
	local camera = Workspace.CurrentCamera
	if camera and camera:GetAttribute(HELD) == true then
		camera:SetAttribute(HELD, nil)
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end
handBack()

-- No course, nothing to face.
if not GameConfig.Obby.Enabled then
	return
end

local watch = ObbyView.new()
local bound = false
-- Where the body stood last frame, while the step is bound.
local lastAt: Vector3? = nil
-- The CFrame this frame's hold asks for, or nil: what the second step writes.
local holding: CFrame? = nil

local function rootOf(): BasePart?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- The engine's to move, and so ours to turn: the ordinary camera, on this
-- player's own living body, and no headset.
local function free(camera: Camera): boolean
	if VRService.VREnabled or camera.CameraType ~= Enum.CameraType.Custom then
		return false
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return humanoid ~= nil and camera.CameraSubject == humanoid
end

-- The four camera settings the engine reads, as their names. A setting that
-- cannot be read counts as the default, which follows on a touch screen.
local function follows(): boolean
	local userTouch, userComputer = "Default", "Default"
	pcall(function()
		local settings = UserSettings():GetService("UserGameSettings")
		userTouch = settings.TouchCameraMovementMode.Name
		userComputer = settings.ComputerCameraMovementMode.Name
	end)
	return ObbyView.follows(UserInputService.TouchEnabled, player.DevTouchCameraMode.Name, userTouch,
		player.DevComputerCameraMode.Name, userComputer)
end

local function unbind()
	if bound then
		bound = false
		RunService:UnbindFromRenderStep(STEP)
		RunService:UnbindFromRenderStep(STEP_AFTER)
	end
	lastAt = nil
	holding = nil
	handBack()
end

local function after()
	local camera = Workspace.CurrentCamera
	local goal = holding
	if camera and goal then
		camera.CFrame = goal
	end
end

local function frame()
	local camera = Workspace.CurrentCamera
	if not camera then
		ObbyView.stop(watch)
		unbind()
		return
	end
	local held = camera:GetAttribute(HELD) == true
	local root = rootOf()
	local at = if root then root.Position else nil
	local onCourse = ObbyData.onCourse(player)
	-- Carried onto a landing since the last frame: that is a placement, now.
	if at and onCourse then
		local key = ObbyView.placed(lastAt, at)
		if key then
			ObbyView.arm(watch, ObbyView.landing(key), ObbyView.forward(key), os.clock(), nil, true)
		end
	end
	lastAt = at
	local zoom = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	local goal, take = ObbyView.step(watch, os.clock(), at, held or free(camera), follows(), zoom,
		camera.CFrame.LookVector)
	holding = goal
	if goal then
		if take and not held then
			camera:SetAttribute(HELD, true)
			camera.CameraType = Enum.CameraType.Scriptable
		end
		camera.CFrame = goal
	elseif held then
		handBack()
	end
	if not ObbyView.active(watch) and not onCourse then
		unbind()
	end
end

local function bind()
	if not bound then
		bound = true
		-- Just before the engine's camera step: what is written here is what it
		-- reads. And just after it, for the frames of a hold (STEP_AFTER).
		RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value - 1, frame)
		RunService:BindToRenderStep(STEP_AFTER, Enum.RenderPriority.Camera.Value + 1, after)
	end
end

local function expect(target: Vector3?, forward: Vector3?, seconds: number?)
	if not (target and forward) then
		return
	end
	ObbyView.arm(watch, target, forward, os.clock(), seconds)
	bind()
end

--==============================================================================
-- THE THREE THINGS THAT SAY A PLACEMENT IS COMING
--==============================================================================
local function respawnKey(): string
	local key = player:GetAttribute(OA.Checkpoint)
	return if type(key) == "string" and ObbyData.Respawns[key] ~= nil then key else "start"
end

-- A fall: the count goes up, and the body comes back on the respawn named.
local lastFalls = tonumber(player:GetAttribute(OA.Falls)) or 0
player:GetAttributeChangedSignal(OA.Falls):Connect(function()
	local falls = tonumber(player:GetAttribute(OA.Falls)) or 0
	if falls > lastFalls and ObbyData.onCourse(player) then
		local key = respawnKey()
		expect(ObbyView.landing(key), ObbyView.forward(key))
	end
	lastFalls = falls
end)

-- A run begun: the respawn goes (back) to the start, on the course. Both
-- attributes are watched because they arrive as two changes, in either order.
local function begun()
	if ObbyData.onCourse(player) and player:GetAttribute(OA.Checkpoint) == "start" then
		expect(ObbyView.landing("start"), ObbyView.forward("start"))
	end
end
local wasOnCourse = ObbyData.onCourse(player)
player:GetAttributeChangedSignal(OA.Course):Connect(function()
	local on = ObbyData.onCourse(player)
	if on and not wasOnCourse then
		bind()
		begun()
	elseif not on then
		-- Off the course: whatever was expected there is not coming.
		ObbyView.stop(watch)
		unbind()
	end
	wasOnCourse = on
end)
-- Already on the course when this script starts (a re-run mid-run).
if wasOnCourse then
	bind()
end
local lastCheckpoint = player:GetAttribute(OA.Checkpoint)
player:GetAttributeChangedSignal(OA.Checkpoint):Connect(function()
	local now = player:GetAttribute(OA.Checkpoint)
	if now == "start" and lastCheckpoint ~= "start" then
		begun()
	end
	lastCheckpoint = now
end)

-- The OBBY button, pressed on this client: in front of the arch, facing it.
player:GetAttributeChangedSignal(ObbyData.LocalAttributes.EntranceAsked):Connect(function()
	if player:GetAttribute(ObbyData.LocalAttributes.EntranceAsked) ~= nil and not ObbyData.onCourse(player) then
		local at, forward = ObbyView.entrance()
		expect(at, forward, ObbyView.EntranceWaitSeconds)
	end
end)

-- A body going takes the placement with it: the next one is put down by the
-- ordinary spawn, which the engine's camera already stands behind.
player.CharacterRemoving:Connect(function()
	ObbyView.stop(watch)
	unbind()
end)

script.Destroying:Connect(function()
	ObbyView.stop(watch)
	unbind()
end)
