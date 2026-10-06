--!strict
--==============================================================================
-- Steal a Seed :: ObbyUI
--
-- Every client's half of the Floating Garden (2026-09-27). The server builds
-- the course and judges every run (ObbyCourse, ObbyService); this moves the
-- moving parts, crumbles the leaves under this player's own feet, throws them
-- off the spring caps, and draws the run.
--
--==============================================================================
-- THE PLATFORMS: EVERY CLIENT MOVES ITS OWN COPY, FROM THE SERVER'S CLOCK
--
-- A drifting pad and a turning log are a pure function of
-- workspace:GetServerTimeNow(), so every client computes the same pose
-- without a single replicated CFrame, and a piece that streams back in is
-- simply put where it belongs this frame. Written in PreSimulation -- before
-- physics -- with the matching AssemblyLinearVelocity / AngularVelocity, which
-- is what carries a body standing on an anchored part along with it.
--
-- Twenty pieces (sixteen drifting pads, four logs), one CFrame write each: no
-- tweens, no per-frame work on decoration (the trim is welded to its piece and
-- rides the one write). The six twilight spires are the only scenery that
-- moves, one PivotTo each.
--
--==============================================================================
-- CRUMBLES AND SPRINGS: ONLY UNDER THIS PLAYER'S OWN FEET
--
-- One downward ray a frame, and only while this player is on a run and
-- standing on something. A falling leaf shakes and withers for its warning
-- (ObbyShake), drops and fades, and is back whole GoneSeconds later -- on
-- this client only, so nobody's leaf falls because somebody else stood on it.
-- A spring cap throws along the arc ObbyData solves from where the player
-- actually stands to the landing it names, and holds the horizontal part for
-- the whole flight: the Humanoid's air control cannot bend it, so the same
-- step always lands on the same spot.
--
--==============================================================================
-- THE HUD: a line with the stage and the clock, and RETURN TO PLOT
--
-- The line is text, not a pill (2026-09-27, StatusText): the stage's name in
-- its own accent with the notices' dark outline, the clock after it in a
-- smaller warm-white monospaced face, no plate, no capsule, no border. It
-- stands in HudLayout's notice band (statusRows) -- the biome name's, which
-- nothing on the course announces -- because the teleport slot under the clock
-- is RETURN TO PLOT's here. The button stands exactly where TELEPORT TO PLOT
-- does (HudLayout's teleport rect), which is hidden off the field, and looks
-- like it: same place, same plate, same D-pad Up while it shows. Pressing it
-- sends one verb; the server carries the player home and ends the run.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local Notice = require(Shared:WaitForChild("Notice"))
local PadInput = require(Shared:WaitForChild("PadInput"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local WheelData = require(Shared:WaitForChild("WheelData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local OA = ObbyData.Attributes
local TAGS = ObbyData.Tags
local RAIL = GameConfig.Rail
local TAU = math.pi * 2
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local PAPER = Color3.fromRGB(250, 246, 236)
local PAD_ACTION = "SeedObbyExit"
local DOWN = Vector3.new(0, -4.6, 0)
-- What a leaf turns while it warns: dry, brown, about to go.
local WITHER = Color3.fromRGB(118, 70, 38)

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedObbyHud")
if existing then
	existing:Destroy()
end
ContextActionService:UnbindAction(PAD_ACTION)

local function reducedMotion(): boolean
	if player:GetAttribute(GameConfig.Afterimage.QualityAttribute) == "Off" then
		return true
	end
	local ok, value = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
end

local function onCourse(): boolean
	return player:GetAttribute(OA.Course) == true
end

--==============================================================================
-- THE PLATFORMS
--==============================================================================
type Mover = { rest: CFrame, axis: Vector3, amp: number, period: number, phase: number }
type Spinner = { rest: CFrame, rate: number, phase: number }

local movers: { [BasePart]: Mover } = {}
local spinners: { [BasePart]: Spinner } = {}

local function watchTag(tag: string, add: (Instance) -> (), remove: (Instance) -> ())
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do
		add(inst)
	end
end

watchTag(TAGS.Mover, function(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local rest = inst:GetAttribute("ObbyRest")
	local axis = inst:GetAttribute("ObbyAxis")
	local amp = tonumber(inst:GetAttribute("ObbyAmp"))
	local period = tonumber(inst:GetAttribute("ObbyPeriod"))
	if typeof(rest) ~= "CFrame" or typeof(axis) ~= "Vector3" or not amp or not period or period <= 0 then
		return
	end
	movers[inst] = {
		rest = rest,
		axis = if axis.Magnitude > 0 then axis.Unit else Vector3.zAxis,
		amp = amp,
		period = period,
		phase = tonumber(inst:GetAttribute("ObbyPhase")) or 0,
	}
end, function(inst: Instance)
	movers[inst :: any] = nil
end)

watchTag(TAGS.Spinner, function(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local rest = inst:GetAttribute("ObbyRest")
	local rate = tonumber(inst:GetAttribute("ObbyDegPerSecond"))
	if typeof(rest) ~= "CFrame" or not rate then
		return
	end
	spinners[inst] = { rest = rest, rate = rate, phase = tonumber(inst:GetAttribute("ObbyPhase")) or 0 }
end, function(inst: Instance)
	spinners[inst :: any] = nil
end)

--== Scenery that drifts: the twilight spires, a stud or so up and down ==--
type Bob = { rest: CFrame, amp: number, period: number, phase: number }
local bobs: { [Model]: Bob } = {}

watchTag(TAGS.Bob, function(inst: Instance)
	if not inst:IsA("Model") then
		return
	end
	local period = tonumber(inst:GetAttribute("ObbyBobPeriod"))
	if not period or period <= 0 then
		return
	end
	bobs[inst] = {
		rest = inst:GetPivot(),
		amp = tonumber(inst:GetAttribute("ObbyBobAmp")) or 1,
		period = period,
		phase = tonumber(inst:GetAttribute("ObbyBobPhase")) or 0,
	}
end, function(inst: Instance)
	bobs[inst :: any] = nil
end)

local function stepPlatforms()
	local t = Workspace:GetServerTimeNow()
	for model, b in pairs(bobs) do
		local a = ((t / b.period + b.phase) % 1) * TAU
		model:PivotTo(b.rest + Vector3.new(0, b.amp * math.sin(a), 0))
	end
	for part, m in pairs(movers) do
		-- Reduced to one period first: the server clock is ~1.8e9 s, and the
		-- phase is what matters.
		local a = ((t / m.period + m.phase) % 1) * TAU
		part.CFrame = m.rest + m.axis * (m.amp * math.sin(a))
		part.AssemblyLinearVelocity = m.axis * (m.amp * TAU / m.period * math.cos(a))
	end
	for part, s in pairs(spinners) do
		local degrees = (s.phase + s.rate * t) % 360
		part.CFrame = s.rest * CFrame.Angles(0, math.rad(degrees), 0)
		part.AssemblyAngularVelocity = Vector3.new(0, math.rad(s.rate), 0)
	end
end

--==============================================================================
-- FALLING LEAVES (this client's own)
--==============================================================================
type Falling = {
	rest: CFrame,
	shake: number,
	parts: { BasePart },
	base: { number },
	colors: { Color3 },
	state: string,
	t0: number,
}

local falling: { [BasePart]: Falling } = {}

local function settle(part: BasePart, f: Falling)
	part.CFrame = f.rest
	for i, p in ipairs(f.parts) do
		if p.Parent then
			p.Color = f.colors[i]
			p.Transparency = f.base[i]
		end
	end
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
end

local function startFalling(part: BasePart, now: number)
	if falling[part] then
		return
	end
	local rest = part:GetAttribute("ObbyRest")
	if typeof(rest) ~= "CFrame" then
		return
	end
	local holder = part.Parent
	local parts: { BasePart } = {}
	if holder and holder:IsA("Model") then
		for _, d in ipairs(holder:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	else
		parts = { part }
	end
	local base, colors = {}, {}
	for i, p in ipairs(parts) do
		base[i] = p.Transparency
		colors[i] = p.Color
	end
	falling[part] = {
		rest = rest,
		shake = tonumber(part:GetAttribute("ObbyShake")) or ObbyData.Crumble.ShakeSeconds,
		parts = parts,
		base = base,
		colors = colors,
		state = "shake",
		t0 = now,
	}
end

local function stepFalling(now: number)
	local still = reducedMotion()
	for part, f in pairs(falling) do
		if not part.Parent then
			falling[part] = nil
			continue
		end
		local age = now - f.t0
		if f.state == "shake" then
			local k = math.clamp(age / f.shake, 0, 1)
			for i, p in ipairs(f.parts) do
				p.Color = f.colors[i]:Lerp(WITHER, k * 0.6)
			end
			if age >= f.shake then
				f.state = "gone"
				f.t0 = now
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
			elseif not still then
				local wob = math.sin(age * 46) * (1.2 + 2.6 * k)
				part.CFrame = f.rest * CFrame.new(0, -0.18 * k, 0)
					* CFrame.Angles(math.rad(wob * 0.5), 0, math.rad(wob))
			end
		elseif f.state == "gone" then
			local k = math.clamp(age / 0.4, 0, 1)
			if not still then
				part.CFrame = f.rest * CFrame.new(0, -7 * k * k, 0) * CFrame.Angles(math.rad(24 * k), 0, math.rad(10 * k))
			end
			for i, p in ipairs(f.parts) do
				p.Transparency = f.base[i] + (1 - f.base[i]) * k
			end
			if age >= ObbyData.Crumble.GoneSeconds then
				f.state = "back"
				f.t0 = now
				part.CFrame = f.rest
				for i, p in ipairs(f.parts) do
					p.Color = f.colors[i]
				end
				part.CanCollide = true
				part.CanQuery = true
				part.CanTouch = true
			end
		else
			local k = math.clamp(age / 0.3, 0, 1)
			for i, p in ipairs(f.parts) do
				p.Transparency = 1 - (1 - f.base[i]) * k
			end
			if k >= 1 then
				falling[part] = nil
			end
		end
	end
end

-- Every leaf whole again, now: a new run starts on a clean course.
local function resetFalling()
	for part, f in pairs(falling) do
		if part.Parent then
			settle(part, f)
		end
	end
	table.clear(falling)
end

watchTag(TAGS.Crumble, function() end, function(inst: Instance)
	falling[inst :: any] = nil
end)

--==============================================================================
-- THIS PLAYER'S BODY: what it stands on, and a spring's flight
--==============================================================================
local humanoid: Humanoid? = nil
local root: BasePart? = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {}

--==============================================================================
-- A SPRING'S THROW, IN TWO FRAMES
--
-- Measured 2026-09-27: a velocity written while the Humanoid is still Running
-- is not what it flies with -- its ground controller cut a 93 studs/s throw to
-- 52 on the same step, the arc peaked 8 studs up, and it passed UNDER the next
-- island. So the cap makes it jump (which lifts it off the floor the engine's
-- way), and the first frame it is airborne the throw is solved again from where
-- it is by then and written whole. Every frame after, until it lands, the
-- horizontal part is held.
--==============================================================================
type Flight = {
	spec: any,
	boosted: boolean,
	vx: number,
	vz: number,
	untilT: number,
	startedAt: number,
}
local flight: Flight? = nil
local lastLaunch = 0

local function launchFrom(cap: BasePart, now: number)
	if now - lastLaunch < 0.5 then
		return
	end
	local stage = ObbyData.stage(tostring(cap:GetAttribute("ObbyStage")))
	local index = tonumber(cap:GetAttribute("ObbyIndex"))
	local list = if stage then stage.launches else nil
	local spec = if list and index then list[index] else nil
	local h, r = humanoid, root
	if not (spec and h and r) then
		return
	end
	lastLaunch = now
	h:ChangeState(Enum.HumanoidStateType.Jumping)
	flight = { spec = spec, boosted = false, vx = 0, vz = 0, untilT = now + 0.4, startedAt = now }
end

local function stepBody(now: number)
	local h, r = humanoid, root
	if not onCourse() or not (h and r and r.Parent) or h.Health <= 0 then
		flight = nil
		return
	end
	local f = flight
	if f then
		if not f.boosted then
			if h.FloorMaterial == Enum.Material.Air then
				-- Airborne: throw from here. Feet ride hip height plus half
				-- the root below it.
				local feet = r.Position - Vector3.new(0, h.HipHeight + r.Size.Y / 2, 0)
				local velocity, seconds = ObbyData.launchVelocity(f.spec, Workspace.Gravity, feet)
				r.AssemblyLinearVelocity = velocity
				f.boosted = true
				f.vx = velocity.X
				f.vz = velocity.Z
				f.startedAt = now
				f.untilT = now + seconds + 0.3
			elseif now > f.untilT then
				-- The jump never left the ground (a ceiling, a stun): no throw.
				flight = nil
			end
			return
		end
		if now > f.untilT or (now - f.startedAt > 0.2 and h.FloorMaterial ~= Enum.Material.Air) then
			flight = nil
		else
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(f.vx, v.Y, f.vz)
			return
		end
	end
	if h.FloorMaterial == Enum.Material.Air then
		return
	end
	local hit = Workspace:Raycast(r.Position, DOWN, rayParams)
	if not hit then
		return
	end
	local part = hit.Instance
	if CollectionService:HasTag(part, TAGS.Launch) then
		launchFrom(part :: BasePart, now)
	elseif CollectionService:HasTag(part, TAGS.Crumble) then
		startFalling(part :: BasePart, now)
	end
end

local function bindBody(character: Model)
	flight = nil
	local h = character:WaitForChild("Humanoid", 10)
	local r = character:WaitForChild("HumanoidRootPart", 10)
	if player.Character ~= character then
		return
	end
	humanoid = if h and h:IsA("Humanoid") then h else nil
	root = if r and r:IsA("BasePart") then r else nil
end

player.CharacterAdded:Connect(bindBody)
if player.Character then
	task.spawn(bindBody, player.Character)
end

RunService.PreSimulation:Connect(function()
	stepPlatforms()
	local now = os.clock()
	if next(falling) ~= nil then
		stepFalling(now)
	end
	stepBody(now)
end)

--==============================================================================
-- THE HUD
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SeedObbyHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
-- The teleport button's own layer: over the world and the prompts, under
-- the belt's ScreenGui and every panel.
gui.DisplayOrder = 26
UIKit.tenFoot(gui)
gui.Parent = playerGui

--== THE RUN LINE: the stage, and the clock ==--
local run = StatusText.new({
	name = "RunLine",
	parent = gui,
	size = StatusText.Size.run,
	tint = PAPER,
	detailSize = StatusText.Size.runClock,
	detailFont = StatusText.ClockFont,
})
-- What the line says, painted by paintStage and paintClock below.
local runStage, runTint, runClock = "FLOATING GARDEN", PAPER, "0:00.0"

--==============================================================================
-- ON A PHONE: THE CLOCK ALONE, UP ON THE TOP ROW (2026-09-29)
--
-- The owner's report, from a phone: the words under the clock stood over the
-- obby's platforms and the player's forward view. The run line was one of
-- them -- a stage name and a clock across the middle of the screen for the
-- whole of a run.
--
-- So on a phone what LASTS is the clock, and only the clock: in the OBBY
-- button's own slot on the clock's row (HudLayout's `run`; that button is
-- hidden on the course), in the monospaced face so it never jiggles. The
-- stage's NAME is said when the stage begins, as a notice that goes after a
-- moment (announceStage, below) -- the world itself says where a runner is
-- the rest of the time. A desktop, a console and a small window keep the
-- line as it was.
--==============================================================================
local runTime = StatusText.new({
	name = "RunClock",
	parent = gui,
	size = StatusText.Size.runClock,
	tint = PAPER,
	headFont = StatusText.ClockFont,
})
-- Whether this screen draws the clock alone (a phone with room on its top row).
local clockAlone = false

-- One of the two is up while a run is on: the clock alone, or the whole line.
local function showRun(want: boolean)
	if want and clockAlone then
		run.hide(true)
		runTime.show()
	elseif want then
		runTime.hide(true)
		run.show()
	else
		run.hide()
		runTime.hide()
	end
end

local function placeRun()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local layout = HudLayout.solve(input)
	local inset = input.insetTop or 0
	local slot = layout.run
	local alone = layout.sidebar and slot.w > 0
	if alone ~= clockAlone then
		clockAlone = alone
		-- The screen changed kind with a run on: the other line takes over.
		if run.isShown() or runTime.isShown() then
			showRun(true)
		end
	end
	if clockAlone then
		runTime.setScale(StatusText.PhoneScale.runClock)
		local size = runTime.size()
		runTime.frame.Position = UDim2.new(0.5, math.round(slot.x + slot.w / 2 - layout.safe.X / 2),
			0, math.round(slot.y + (slot.h - size.Y) / 2))
		return
	end
	run.setScale(if layout.compact or layout.sidebar then StatusText.SmallScale.run else 1)
	local _, band = HudLayout.statusRows(layout, inset)
	local size = run.size()
	local r = HudLayout.centreIn(layout, band, size.X)
	-- This gui keeps the inset, so safe space is its own space.
	run.frame.Position = UDim2.new(0.5, math.round(r.x + r.w / 2 - layout.safe.X / 2),
		0, math.round(r.y + (r.h - size.Y) / 2))
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeRun)

-- Words only; placed again only when the line's width changes (a new stage).
local function paintRun()
	local before, beforeTime = run.size(), runTime.size()
	run.set(runStage, runClock, runTint)
	runTime.set(runClock)
	if run.size() ~= before or runTime.size() ~= beforeTime then
		placeRun()
	end
end

--== RETURN TO PLOT: PlotTeleportUI's button, in its place ==--
local button = Instance.new("TextButton")
button.Name = "ReturnToPlot"
button.AnchorPoint = Vector2.new(0.5, 0)
button.BackgroundTransparency = 1
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Selectable = true
button.Text = ""
button.Visible = false
button.Parent = gui
UIKit.clicks(button)

-- The HUD's plate button (UIKit.hudPlate, the global UI pass 2026-10-04): the
-- outline on the BORDER (it never drew on the old text-less label), the
-- family's darker foot, the inner rim, the icon and the outlined word.
local hud = UIKit.hudPlate(button, {
	top = RAIL.ShopTileTop,
	bottom = RAIL.ShopTileBottom,
	rim = RAIL.ShopEdge,
	image = RAIL.GardenIcon,
	text = "RETURN TO PLOT",
})
local plate = hud.plate
local plateScale = hud.scale
local rim = hud.rim
local icon = hud.icon
local label = hud.label


local scale = Instance.new("UIScale")
scale.Parent = button
UIKit.cardPop(button, scale, { hoverScale = 1.04, pressScale = 0.96, sound = false })

local function placeButton()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	-- TELEPORT's place everywhere but a phone's even row (2026-10-05), where the
	-- span BIOMES and PLOT take -- both hidden on the course -- holds the words
	-- alone (HudLayout's returnPlot, returnPlate, returnWide).
	local r = layout.returnPlot
	button.Position = HudLayout.place(r, button.AnchorPoint, layout.safe)
	button.Size = UDim2.fromOffset(r.w, r.h)
	-- The plate's own size, before its scale, as PlotTeleportUI's.
	plate.Size = UDim2.fromOffset(layout.returnPlate.X, layout.returnPlate.Y)
	plateScale.Scale = layout.teleportScale
	icon.Visible = layout.returnWide
	if layout.returnWide then
		label.Position = UDim2.new(0, 42, 0.5, 1)
		label.Size = UDim2.new(1, -50, 0, 22)
	else
		label.Position = UDim2.new(0, 6, 0.5, 1)
		label.Size = UDim2.new(1, -12, 0, 22)
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
	placeButton()
	placeRun()
end)
placeButton()

local channel: RemoteEvent? = nil
local lastPress = 0

local function requestExit()
	local remote = channel
	if not (remote and button.Visible) then
		return
	end
	local now = os.clock()
	if now - lastPress < 0.5 then
		return
	end
	lastPress = now
	remote:FireServer(ObbyData.Actions.Exit)
end
button.Activated:Connect(requestExit)

local padBound = false
local function bindPad(want: boolean)
	if want == padBound then
		return
	end
	padBound = want
	if want then
		ContextActionService:BindAction(PAD_ACTION, function(_, state: Enum.UserInputState)
			if state == Enum.UserInputState.Begin
				and not (PadInput.panelOpen() or GuiService.SelectedObject ~= nil) then
				requestExit()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.DPadUp)
	else
		ContextActionService:UnbindAction(PAD_ACTION)
	end
end

--==============================================================================
-- THE CLOCK AND THE STAGE
--==============================================================================
local function clockOf(seconds: number): string
	local s = math.max(0, seconds)
	local minutes = math.floor(s / 60)
	return string.format("%d:%04.1f", minutes, s - minutes * 60)
end

local function stageLook(id: string?): (string, Color3)
	if id == "finished" then
		return "FINISHED", Color3.fromRGB(255, 214, 92)
	end
	local stage = if id then ObbyData.stage(id) else nil
	if not stage then
		return "FLOATING GARDEN", PAPER
	end
	local palette = ObbyData.Palettes[stage.palette]
	return string.upper(stage.name), if palette then palette.accent else PAPER
end

local lastShown = ""
local function paintClock()
	local startedAt = tonumber(player:GetAttribute(OA.StartedAt))
	local endedAt = tonumber(player:GetAttribute(OA.EndedAt))
	local text = if startedAt then clockOf((endedAt or Workspace:GetServerTimeNow()) - startedAt) else "0:00.0"
	if text ~= lastShown then
		lastShown = text
		runClock = text
		paintRun()
	end
end

local function paintStage()
	runStage, runTint = stageLook(player:GetAttribute(OA.Stage) :: string?)
	paintRun()
end

local clockConnection: RBXScriptConnection? = nil

local function alive(): boolean
	local h = humanoid
	return h ~= nil and h.Parent ~= nil and h.Health > 0
end

--==============================================================================
-- THE SIGNS AND PROMPTS ON THE COURSE (this client's own copies)
--==============================================================================
local course: Instance? = nil
local lastResult: { [string]: any }? = nil

local function find(path: { string }): Instance?
	local node: Instance? = course
	for _, name in ipairs(path) do
		node = if node then node:FindFirstChild(name) else nil
	end
	return node
end

local function writeBoard(board: Instance?, lines: { string })
	if not board then
		return
	end
	for _, face in ipairs(board:GetChildren()) do
		if face:IsA("SurfaceGui") then
			for i, text in ipairs(lines) do
				local line = face:FindFirstChild("Line" .. i)
				if line and line:IsA("TextLabel") then
					line.Text = text
				end
			end
		end
	end
end

--==============================================================================
-- THE REWARD WHEEL'S DAILY ALLOWANCE (2026-09-27)
--
-- The first five paid runs in a player's 24-hour window earn a wheel spin in
-- place of the Speed (WheelService.AwardCompletion decides, at the finish).
-- This says what it will decide, from what WheelService publishes: whether the
-- next paid run earns a spin, and how many the open window has earned. Nothing
-- published (no profile yet, the wheel off) reads as "the Speed", which is what
-- the server pays then too.
--==============================================================================
local function spinsToday(): (boolean, number)
	local W = WheelData.Attributes
	if not WheelData.Enabled or player:GetAttribute(W.Earned) == nil then
		return false, 0
	end
	local ends = player:GetAttribute(W.DayEndsAt)
	if type(ends) ~= "number" or ends <= Workspace:GetServerTimeNow() then
		return true, 0
	end
	local count = tonumber(player:GetAttribute(W.DayCount)) or 0
	return count < WheelData.Daily.Limit, count
end

local function paintCourse()
	if not course then
		return
	end
	local main = tonumber(player:GetAttribute(OA.RewardMain))
	local extra = tonumber(player:GetAttribute(OA.RewardChallenge))
	local spin, today = spinsToday()
	local capped = not spin and WheelData.Enabled and player:GetAttribute(WheelData.Attributes.Earned) ~= nil
	writeBoard(find({ "Entrance", "RewardSign", "Board" }), {
		if capped then "DAILY SPINS EARNED!" else "YOUR REWARD",
		if spin then "+1 WHEEL SPIN" elseif main then "+" .. GameConfig.compact(main) .. " SPEED"
			else "Finish the course",
		if spin then string.format("Spins earned today: %d/%d", today, WheelData.Daily.Limit)
			elseif extra then "Challenge Route: +" .. GameConfig.compact(extra) .. " more" else "",
	})
	local result = lastResult
	if result then
		local ok = result.ok == true
		local won = (tonumber(result.spin) or 0) > 0
		writeBoard(find({ "Finish", "ResultSign", "Board" }), {
			if not ok then "RUN NOT COUNTED" elseif result.challenge == true then "CHALLENGE COMPLETE"
				else "COURSE COMPLETE",
			clockOf(tonumber(result.seconds) or 0),
			if not ok then "Replay to try again" elseif won then "+1 WHEEL SPIN"
				else "+" .. GameConfig.compact(tonumber(result.reward) or 0) .. " SPEED",
		})
	end
	local here = onCourse()
	local finished = player:GetAttribute(OA.Stage) == "finished"
	local start = find({ "Entrance", "StartStep", "StartPrompt" })
	if start and start:IsA("ProximityPrompt") then
		start.Enabled = not here
		start.ObjectText = if spin then "Reward: 1 Wheel Spin"
			elseif main then "Reward +" .. GameConfig.compact(main) .. " Speed" else "Speed Challenge"
	end
	for _, name in ipairs({ "Replay", "Return" }) do
		local prompt = find({ "Finish", name .. "Plinth", name .. "Prompt" })
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = here and finished
		end
	end
end

local function adoptCourse(folder: Instance)
	course = folder
	rayParams.FilterDescendantsInstances = { folder }
	-- Signs and prompts stream in (and back in) as fresh copies: write this
	-- player's numbers on each as it arrives.
	folder.DescendantAdded:Connect(function(d: Instance)
		if d:IsA("SurfaceGui") or d:IsA("ProximityPrompt") then
			task.defer(paintCourse)
		end
	end)
	paintCourse()
end

Workspace.ChildAdded:Connect(function(child: Instance)
	if child.Name == ObbyData.FolderName then
		adoptCourse(child)
	end
end)
local already = Workspace:FindFirstChild(ObbyData.FolderName)
if already then
	adoptCourse(already)
end

--==============================================================================
-- A FINISH: the board, a notice, and a small burst of petals
--==============================================================================
local function petalBurst()
	if reducedMotion() then
		return
	end
	local mark = find({ "Finish", "FinishMark" })
	if not (mark and mark:IsA("BasePart")) then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Parent = mark
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 196, 214)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 236, 140)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 160, 240)),
	})
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(1.1, 1.8)
	emitter.Speed = NumberRange.new(14, 24)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Acceleration = Vector3.new(0, -18, 0)
	emitter.Drag = 1.5
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rate = 0
	emitter.LightEmission = 0.3
	emitter.Parent = attachment
	emitter:Emit(36)
	task.delay(3, function()
		attachment:Destroy()
	end)
end

local function onResult(payload: { [string]: any })
	lastResult = payload
	paintCourse()
	local seconds = clockOf(tonumber(payload.seconds) or 0)
	if payload.ok == true then
		-- A spin-earning run says so and where to spend it; the sixth and later
		-- in a window say the Speed, as every run used to.
		local spin = tonumber(payload.spin) or 0
		local limit = tonumber(payload.limit) or WheelData.Daily.Limit
		Notice.post({
			kind = "success",
			title = if payload.challenge == true then "CHALLENGE COMPLETE" else "COURSE COMPLETE",
			detail = if spin > 0
				then string.format("+1 wheel spin in %s (%d/%d today). Spin it at the wheel by Marigold.",
					seconds, spin, limit)
				else string.format("+%s Speed in %s.", GameConfig.compact(tonumber(payload.reward) or 0), seconds),
			key = "obby:finish",
		})
		petalBurst()
	else
		Notice.post({
			kind = "warning",
			title = "RUN NOT COUNTED",
			detail = "Replay to try again.",
			key = "obby:finish",
		})
	end
end

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
		found.OnClientEvent:Connect(function(action: any, payload: any)
			if action == ObbyData.Actions.Result and type(payload) == "table" then
				onResult(payload)
			end
		end)
	else
		warn("[Seed/ObbyUI] No GameEvent remote; the Exit button cannot ask for anything.")
	end
end)

--==============================================================================
-- SHOWN OR NOT, AND THE NOTICES A RUN SAYS
--==============================================================================
local function refresh()
	local want = onCourse() and alive()
	-- Placed first: which of the two lines this screen shows is the layout's.
	placeRun()
	showRun(want)
	button.Visible = want
	bindPad(want)
	if want and not clockConnection then
		clockConnection = RunService.Heartbeat:Connect(paintClock)
	elseif not want and clockConnection then
		clockConnection:Disconnect()
		clockConnection = nil
	end
	paintStage()
	paintClock()
	placeRun()
	paintCourse()
end

--==============================================================================
-- ON A PHONE THE STAGE IS ANNOUNCED, NOT HELD UP (2026-09-29)
--
-- Where the run line is the clock alone (placeRun), a stage's name is a notice
-- as the stage begins: up for a moment in the notices' own band at the top of
-- the screen, no sound, and gone. Only going FORWARD -- a fall that puts a
-- runner back a stage says BACK TO CHECKPOINT and that is enough -- and never
-- for the first stage, which SPEED CHALLENGE has just introduced.
--==============================================================================
-- How far along the course each stage is: the main route's stages count 1 to
-- 6, and the two twilight stages stand between the fifth and the summit, which
-- is where they are run.
local STAGE_ORDER: { [string]: number } = {}
do
	local main, twilight = 0, 0
	for _, stage in ipairs(ObbyData.Stages) do
		if stage.route == "main" then
			main += 1
			STAGE_ORDER[stage.id] = main
		end
	end
	for _, stage in ipairs(ObbyData.Stages) do
		if stage.route ~= "main" then
			twilight += 1
			STAGE_ORDER[stage.id] = (main - 1) + twilight * 0.2
		end
	end
end
local announced = 0

-- How long a notice the course says stays up on a phone, where it stands over
-- the way ahead rather than over the belt; nil everywhere else (its kind's own).
local function brief(seconds: number): number?
	return if clockAlone then seconds else nil
end

local function announceStage()
	local id = player:GetAttribute(OA.Stage)
	local order = if type(id) == "string" then STAGE_ORDER[id] else nil
	if not (order and onCourse()) then
		return
	end
	if order <= announced then
		return
	end
	local first = announced == 0
	announced = order
	local stage = ObbyData.stage(id :: string)
	if first or not (clockAlone and stage) then
		return
	end
	Notice.post({ kind = "info", title = string.upper(stage.name), key = "obby:stage", quiet = true,
		seconds = brief(1.8) })
end

player:GetAttributeChangedSignal(OA.Course):Connect(function()
	if onCourse() then
		resetFalling()
		lastResult = nil
		announced = 0
	end
	refresh()
end)
player:GetAttributeChangedSignal(OA.Stage):Connect(function()
	paintStage()
	paintCourse()
	announceStage()
end)
player:GetAttributeChangedSignal(OA.RewardMain):Connect(paintCourse)
player:GetAttributeChangedSignal(OA.RewardChallenge):Connect(paintCourse)
-- The wheel's allowance: a spin earned, a window opened or closed.
for _, name in ipairs({ WheelData.Attributes.Earned, WheelData.Attributes.DayCount, WheelData.Attributes.DayEndsAt }) do
	player:GetAttributeChangedSignal(name):Connect(paintCourse)
end
player:GetAttributeChangedSignal(OA.EndedAt):Connect(paintClock)

player:GetAttributeChangedSignal(OA.StartedAt):Connect(function()
	if player:GetAttribute(OA.StartedAt) ~= nil and onCourse() then
		-- A run begun, the first or a Replay: its stages are announced afresh, and
		-- the first of them is what this notice introduces.
		announced = 1
		Notice.post({
			kind = "info",
			title = "SPEED CHALLENGE",
			detail = "Reach the pavilion. A fall brings you back.",
			key = "obby:start",
		})
	end
	paintClock()
end)

player:GetAttributeChangedSignal(OA.Checkpoint):Connect(function()
	local at = player:GetAttribute(OA.Checkpoint)
	if at == "cp1" or at == "cp2" then
		Notice.post({ kind = "success", title = "CHECKPOINT", detail = "A fall brings you back here.",
			key = "obby:checkpoint", seconds = brief(2) })
	end
end)

player:GetAttributeChangedSignal(OA.Route):Connect(function()
	if player:GetAttribute(OA.Route) == "challenge" then
		Notice.post({ kind = "info", title = "CHALLENGE ROUTE", detail = "Clear both twilight stages for extra Speed.",
			key = "obby:route" })
	end
end)

local lastFalls = 0
player:GetAttributeChangedSignal(OA.Falls):Connect(function()
	local falls = tonumber(player:GetAttribute(OA.Falls)) or 0
	if falls > lastFalls then
		-- The notice a runner sees most, at the moment they most need to see the
		-- next leaf: on a phone it is up for a second and a half.
		Notice.post({ kind = "info", title = "BACK TO CHECKPOINT", key = "obby:fall", quiet = true,
			seconds = brief(1.5) })
	end
	lastFalls = falls
end)

player.CharacterAdded:Connect(function(character: Model)
	local h = character:WaitForChild("Humanoid", 10)
	if h and h:IsA("Humanoid") then
		h.Died:Connect(refresh)
	end
	refresh()
end)
player.CharacterRemoving:Connect(function()
	showRun(false)
	button.Visible = false
	bindPad(false)
end)
if player.Character then
	task.spawn(function()
		local h = (player.Character :: Model):WaitForChild("Humanoid", 10)
		if h and h:IsA("Humanoid") then
			h.Died:Connect(refresh)
		end
		refresh()
	end)
end
refresh()
