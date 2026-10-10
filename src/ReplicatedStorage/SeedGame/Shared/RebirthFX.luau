--!strict
--==============================================================================
-- Steal a Seed :: RebirthFX (2026-10-09)
--
-- Draws the rebirth celebration on THIS screen: Shared/RebirthCelebration's
-- timeline with GameConfig.Rebirth.Celebration's numbers. Client only, and it
-- decides nothing -- the server said who was reborn, and to what.
--
--   play (own)    the reborn player's own screen: the white-gold flash, the
--                 REBORN! card at the upper middle with the gold rays behind
--                 it, the spin (the camera held still and the controls held
--                 while it runs, both handed back exactly as they were), the
--                 world pieces below and the fanfare, flat;
--   play (other)  somebody close was reborn: the column of light, the eight
--                 orbs, the burst, the leaves and sparkles round THAT body, and
--                 the fanfare from it;
--   watchAuras    the faint aura round every body with Aura.From rebirths or
--                 more, on this screen.
-- REDUCED FX (StatusText.reducedMotion): no spin, orbs, rays, flash, column or
-- particles, and no aura -- the card simply appears and the fanfare still
-- plays. Every piece is made when a celebration starts and destroyed when it
-- ends: nothing is left behind.
--
-- The seams in Options (manual, world, gui, camera, sound, phone, reduced) are
-- for RebirthCelebrationSpec, which steps a whole celebration in Edit; the
-- game passes none of them.
--==============================================================================

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Rebirth = require(Shared:WaitForChild("Rebirth"))
local RebirthCelebration = require(Shared:WaitForChild("RebirthCelebration"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local CFG = GameConfig.Rebirth
local C = CFG.Celebration
local T = C.Textures
local ART = CFG.Art
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 214, 64)
-- The sparkle sheet's frame 3, its biggest twinkle: the orbs.
local ORB_RECT = Vector2.new(0, 256)

local RebirthFX = {}

-- The names a spec looks for.
RebirthFX.Names = {
	World = "SeedRebirthFX",
	Card = "SeedRebirthCelebration",
	Flash = "SeedRebirthFlash",
	Aura = "SeedRebirthAura",
	Auras = "SeedRebirthAuras",
}

-- A rank-only rebirth's pulse (2026-10-10): the title over that head is told,
-- on this screen only, when it began (os.clock); OwnerTitleUI, which draws the
-- title, grows its words by RebirthCelebration.pulse.
RebirthFX.PulseAttribute = C.Pulse.Attribute

export type Options = {
	character: Model,
	-- This screen's own rebirth: the card, the flash, the spin, the camera and
	-- the controls. Otherwise only the world pieces, round that body.
	own: boolean,
	rebirths: number,
	-- The count before it (one less when left out): a new name or a rank only.
	before: number?,
	-- The server's numbers for the card (Rebirth's own otherwise).
	training: number?,
	income: number?,
	-- Seams (RebirthCelebrationSpec); the game passes none.
	reduced: boolean?,
	manual: boolean?,
	world: Instance?,
	gui: Instance?,
	camera: any?,
	sound: ((own: boolean, root: BasePart) -> ())?,
	phone: boolean?,
}

export type Handle = {
	-- Shows the celebration as it is `t` seconds in (the game steps it every
	-- frame; a spec steps it by hand).
	step: (t: number) -> (),
	-- Ends it now: everything handed back, every piece destroyed.
	stop: () -> (),
	finished: () -> boolean,
	world: Folder,
	card: TextButton?,
}

type Orb = { at: Attachment, image: ImageLabel, trail: ParticleEmitter }
-- A signature's leaf: its billboard (on the head's attachment, offset in camera
-- space: Seedlight's arc) or its own attachment (World Tree's ring), and its
-- picture.
type Flier = { board: BillboardGui, at: Attachment?, image: ImageLabel }
type Fade = { instance: Instance, property: string, base: number }
type Hold = { cameraType: any, cframe: CFrame, subject: any, autoRotate: boolean?, jump: boolean? }

local active: { [Model]: Handle } = {}
local counter = 0

-- Whether a body is celebrating right now on this screen.
function RebirthFX.celebrating(character: Model?): boolean
	return character ~= nil and active[character] ~= nil
end

--==============================================================================
-- PIECES
--==============================================================================
local function piece(name: string, parent: Instance, size: Vector3, colour: Color3, material: Enum.Material,
	shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = colour
	p.Material = material
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Locked = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function keys(points: { { number } }): NumberSequence
	local out = {}
	for _, p in ipairs(points) do
		table.insert(out, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(out)
end

--==============================================================================
-- THE SHEETS LOAD FIRST (measured in Play, 2026-10-09)
--
-- An emitter given its flipbook before its sheet has loaded draws NOTHING --
-- the aura built at join stood invisible -- until its flipbook is set again
-- after the load. So on a client the four sheets are loaded as soon as this
-- module is, and every emitter made before that finishes has its flipbook set
-- again once they are.
--==============================================================================
local sheetsReady = false
local waiting: { [ParticleEmitter]: Enum.ParticleFlipbookLayout } = setmetatable({}, { __mode = "k" }) :: any

local function rearm(e: ParticleEmitter, layout: Enum.ParticleFlipbookLayout)
	e.FlipbookLayout = Enum.ParticleFlipbookLayout.None
	e.FlipbookLayout = layout
end

function RebirthFX.sheetsReady(): boolean
	return sheetsReady
end

if RunService:IsClient() then
	task.spawn(function()
		local probes: { Instance } = {}
		for _, id in pairs(T) do
			local probe = Instance.new("ParticleEmitter")
			probe.Texture = id
			table.insert(probes, probe)
		end
		-- The card's pictures too: an emblem fetched only when the card pops in
		-- arrived late in Play (2026-10-09; the panel usually loads it first).
		for _, id in ipairs({ ART.Emblem, C.Rays, C.Logo }) do
			if id ~= "" then
				local probe = Instance.new("ImageLabel")
				probe.Image = id
				table.insert(probes, probe)
			end
		end
		pcall(function()
			ContentProvider:PreloadAsync(probes)
		end)
		sheetsReady = true
		for e, layout in pairs(waiting) do
			if e.Parent then
				rearm(e, layout)
			end
		end
		table.clear(waiting)
		for _, probe in ipairs(probes) do
			probe:Destroy()
		end
	end)
end

-- A particle emitter of one of the owner's sheets: emits only when told to
-- (Rate 0) unless the caller gives it a rate.
local function sheet(name: string, parent: Instance, texture: string, layout: Enum.ParticleFlipbookLayout,
	mode: Enum.ParticleFlipbookMode): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = texture
	e.FlipbookLayout = layout
	e.FlipbookMode = mode
	e.Rate = 0
	e.LightInfluence = 0
	e.Parent = parent
	if not sheetsReady then
		waiting[e] = layout
	end
	return e
end

local function outlineOf(label: TextLabel, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = FloatingSign.Outline
	s.Thickness = thickness
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = label
	return s
end

-- One line of the card: as large as `size` and never wider than its box (the
-- engine shrinks it; a long GAIA numeral is the reason).
local function cardLine(parent: Instance, name: string, font: Enum.Font, size: number, colour: Color3,
	position: UDim2, box: UDim2, z: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextColor3 = colour
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = position
	label.Size = box
	label.ZIndex = z
	label.Active = false
	label.Parent = parent
	local most = Instance.new("UITextSizeConstraint")
	most.MaxTextSize = size
	most.MinTextSize = 8
	most.Parent = label
	return label
end

-- The widest a line may be on the card, and how wide its words are at `size`:
-- RebirthCelebrationSpec measures every line it can say with these.
function RebirthFX.cardRoom(): number
	local P = C.Popup
	return P.Size.X - (16 + P.Emblem + 14) - 16
end
function RebirthFX.textWidth(text: string, size: number, font: Enum.Font): number
	return TextService:GetTextSize(text, size, font, Vector2.new(4000, 400)).X
end
RebirthFX.Fonts = { Reborn = Enum.Font.LuckiestGuy, Line = Enum.Font.FredokaOne, Bonus = Enum.Font.FredokaOne }
RebirthFX.Sizes = { Reborn = 40, Line = 26, Bonus = 19 }

--==============================================================================
-- THE AURA (Aura.From rebirths and up): the owner's looping wisp sheet, played
-- as a 16-frame picture on two billboards either side of the body, in the
-- title's family's palette (since the 100 titles, 2026-10-10: the first wisp
-- Primary, the second Secondary; GAIA's the rainbow, turning slowly), with a
-- family's accent leaves going round it (World Tree Halo's two). Only the
-- Aura.Nearest bodies nearest this camera show theirs.
--
-- BILLBOARDS, NOT PARTICLES. Measured in Play 2026-10-09: the very same sheet
-- as a flipbook ParticleEmitter drew only now and then -- on the body and in a
-- loose part following it alike, whatever its settings -- while two billboards
-- stepping its frames drew every time, front and back. Their offset is in
-- CAMERA space (StudsOffset): from any side the wisps stand to the left and the
-- right of the body and a little behind it, so the body is never covered.
-- Each aura is an invisible anchored part in this client's folder, put on its
-- body's root every frame by one RenderStepped (followAuras), which also steps
-- the frames. Gone with its body.
--==============================================================================
local auraFolder: Folder? = nil
type Aura = {
	root: BasePart,
	frames: { ImageLabel },
	shown: { number },
	-- Every billboard of it (wisps and accents), the accents, their leaves and
	-- the frame each shows, GAIA's rainbows.
	boards: { BillboardGui },
	accents: { BillboardGui },
	leaves: { ImageLabel },
	leafShown: number,
	rainbows: { UIGradient },
	-- Among the Nearest to this camera; hidden round your own camera in first
	-- person; and whether its billboards are on now (nil: not yet set).
	near: boolean,
	hidden: boolean,
	on: boolean?,
}
local auras: { [BasePart]: Aura } = {}
local following: RBXScriptConnection? = nil
local nearestAt = -math.huge
-- The sheet: 4 x 4 frames of 256 px, left to right, top row first.
local AURA_CELL = 256
local AURA_FRAMES = 16
-- The leaf sheet: 2 x 2 frames of 256 px, played back and forth.
local LEAF_CELL = 256

local function aurasFolder(): Folder
	local f = auraFolder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = RebirthFX.Names.Auras
	made.Parent = Workspace
	auraFolder = made
	return made
end

-- The frame wisp `i` shows at `now`: the two are half a loop apart.
function RebirthFX.auraFrame(i: number, now: number): number
	return (math.floor(now * C.Aura.Framerate) + (i - 1) * (AURA_FRAMES // 2)) % AURA_FRAMES
end

-- The leaf sheet's frame at `now`, back and forth through its four (0 1 2 3 2 1).
function RebirthFX.leafFrame(now: number): number
	local k = math.floor(now * 6) % 6
	return if k <= 3 then k else 6 - k
end

-- Every aura onto its body's root and on to its next frame; an aura whose body
-- is gone goes with it. Which ones show: the Aura.Nearest within MaxDistance of
-- `viewer` (this camera unless given; a spec gives one), looked at again four
-- times a second. The game runs it every frame while any aura stands; a spec
-- steps it by hand with its own clock.
function RebirthFX.followAuras(now: number?, viewer: Vector3?)
	local t = now or os.clock()
	local A = C.Aura
	if viewer or t - nearestAt >= 0.25 or t < nearestAt then
		nearestAt = t
		local camera = Workspace.CurrentCamera
		local from = viewer or (if camera then camera.CFrame.Position else nil)
		local keys: { BasePart } = {}
		local distances: { number } = {}
		for part, a in pairs(auras) do
			if a.root.Parent and part.Parent then
				table.insert(keys, part)
				table.insert(distances, if from then (a.root.Position - from).Magnitude else 0)
			end
		end
		local shown = RebirthCelebration.nearest(distances, A.Nearest, A.MaxDistance)
		for i, part in ipairs(keys) do
			(auras[part] :: Aura).near = shown[i] == true
		end
	end
	for part, a in pairs(auras) do
		if a.root.Parent and part.Parent then
			part.CFrame = a.root.CFrame
			local on = a.near and not a.hidden
			if a.on ~= on then
				a.on = on
				for _, board in ipairs(a.boards) do
					board.Enabled = on
				end
			end
			local stepped = false
			for i, label in ipairs(a.frames) do
				local f = RebirthFX.auraFrame(i, t)
				if a.shown[i] ~= f then
					a.shown[i] = f
					stepped = true
					label.ImageRectOffset = Vector2.new((f % 4) * AURA_CELL, (f // 4) * AURA_CELL)
				end
			end
			if on then
				for i, board in ipairs(a.accents) do
					board.StudsOffset = RebirthCelebration.auraAccent(i, #a.accents, t)
				end
				local leaf = RebirthFX.leafFrame(t)
				if a.leafShown ~= leaf then
					a.leafShown = leaf
					for _, label in ipairs(a.leaves) do
						label.ImageRectOffset = Vector2.new((leaf % 2) * LEAF_CELL, (leaf // 2) * LEAF_CELL)
					end
				end
				-- GAIA's rainbow turns with the frames (Framerate a second).
				if stepped and #a.rainbows > 0 then
					local colours = WheelDraw.rainbow((t / A.RainbowSeconds) % 1)
					for _, g in ipairs(a.rainbows) do
						g.Color = colours
					end
				end
			end
		else
			auras[part] = nil
			part:Destroy()
		end
	end
	local f = following
	if f and next(auras) == nil then
		f:Disconnect()
		following = nil
	end
end

-- The aura standing round a body's root, or nil.
function RebirthFX.auraOf(root: Instance): BasePart?
	for part, a in pairs(auras) do
		if a.root == root and part.Parent then
			return part
		end
	end
	return nil
end

-- Takes a body's aura off.
function RebirthFX.clearAura(root: Instance)
	for part, a in pairs(auras) do
		if a.root == root then
			auras[part] = nil
			part:Destroy()
		end
	end
end

-- Hides one aura on this screen (this player's own round a first-person
-- camera) or shows it again, from the next followAuras.
function RebirthFX.hideAura(holder: BasePart, hidden: boolean)
	local a = auras[holder]
	if a and a.hidden ~= hidden then
		a.hidden = hidden
		a.on = nil
	end
end

-- Whether an aura's billboards are on now (a spec's look).
function RebirthFX.auraShown(holder: BasePart): boolean
	local a = auras[holder]
	return a ~= nil and a.on ~= false
end

-- Puts the aura for `rebirths` round a body (any one it had goes first).
-- `parent` is a seam for RebirthCelebrationSpec; the game passes none.
function RebirthFX.aura(root: BasePart, rebirths: number, parent: Instance?): BasePart
	RebirthFX.clearAura(root)
	local A = C.Aura
	local first, second, rainbow, accentCount = RebirthCelebration.auraLook(rebirths)
	local holder = Instance.new("Part")
	holder.Name = RebirthFX.Names.Aura
	holder.Size = Vector3.new(1, 1, 1)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	holder.Locked = true
	holder.CFrame = root.CFrame
	holder:SetAttribute("Rebirths", rebirths)
	local centre = Instance.new("Attachment")
	centre.Name = "Centre"
	centre.Parent = holder
	local frames: { ImageLabel } = {}
	local boards: { BillboardGui } = {}
	local rainbows: { UIGradient } = {}
	for i, side in ipairs({ -A.Side, A.Side }) do
		local board = Instance.new("BillboardGui")
		board.Name = "Wisp" .. i
		board.Size = UDim2.fromScale(A.Size, A.Size)
		-- Camera space: to the left and the right of the body, a little behind.
		board.StudsOffset = Vector3.new(side, A.Lift, -A.Back)
		board.LightInfluence = 0
		board.AlwaysOnTop = false
		board.MaxDistance = A.MaxDistance
		board.ResetOnSpawn = false
		board.Active = false
		board.Parent = centre
		local frame = Instance.new("ImageLabel")
		frame.Name = "Frame"
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.Image = T.Aura
		frame.ImageRectSize = Vector2.new(AURA_CELL, AURA_CELL)
		frame.ImageRectOffset = Vector2.zero
		frame.ImageColor3 = if rainbow then WHITE elseif i == 1 then first else second
		frame.ImageTransparency = A.Transparency
		frame.Parent = board
		if rainbow then
			-- GAIA: the ladder's rainbow over the white wisp, turning slowly.
			local g = Instance.new("UIGradient")
			g.Name = "Rainbow"
			g.Color = WheelDraw.rainbow(0)
			g.Rotation = 90
			g.Parent = frame
			table.insert(rainbows, g)
		end
		table.insert(frames, frame)
		table.insert(boards, board)
	end
	-- The family's accent leaves (World Tree Halo's two), going round the body.
	local accents: { BillboardGui } = {}
	local leaves: { ImageLabel } = {}
	for i = 1, accentCount do
		local board = Instance.new("BillboardGui")
		board.Name = "Accent" .. i
		board.Size = UDim2.fromScale(A.Accent.Size, A.Accent.Size)
		board.StudsOffset = RebirthCelebration.auraAccent(i, accentCount, 0)
		board.LightInfluence = 0
		board.AlwaysOnTop = false
		board.MaxDistance = A.MaxDistance
		board.ResetOnSpawn = false
		board.Active = false
		board.Parent = centre
		local leaf = Instance.new("ImageLabel")
		leaf.Name = "Leaf"
		leaf.BackgroundTransparency = 1
		leaf.Size = UDim2.fromScale(1, 1)
		leaf.Image = T.Leaf
		leaf.ImageRectSize = Vector2.new(LEAF_CELL, LEAF_CELL)
		leaf.ImageRectOffset = Vector2.zero
		leaf.ImageColor3 = if i == 1 then first else second
		leaf.Parent = board
		table.insert(accents, board)
		table.insert(leaves, leaf)
		table.insert(boards, board)
	end
	holder.Parent = parent or aurasFolder()
	auras[holder] = {
		root = root,
		frames = frames,
		shown = {},
		boards = boards,
		accents = accents,
		leaves = leaves,
		leafShown = 0,
		rainbows = rainbows,
		near = true,
		hidden = false,
		on = nil,
	}
	if not following and RunService:IsRunning() then
		following = RunService.RenderStepped:Connect(function()
			RebirthFX.followAuras()
		end)
	end
	return holder
end

local watching = false

-- Keeps every body's aura right on this screen: built from Aura.From, re-tinted
-- when the count changes, gone below it, for REDUCED FX, and round this
-- player's own camera in first person. Once per client (RebirthUI).
function RebirthFX.watchAuras()
	if watching then
		return
	end
	watching = true
	local me = Players.LocalPlayer
	local function refresh(player: Player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (character and root and root:IsA("BasePart")) then
			return
		end
		local n = Rebirth.count(player:GetAttribute(CFG.Attributes.Rebirths))
		if not RebirthCelebration.auraFor(n) or StatusText.reducedMotion() then
			RebirthFX.clearAura(root)
			return
		end
		local holder = RebirthFX.auraOf(root)
		if not holder or holder:GetAttribute("Rebirths") ~= n then
			holder = RebirthFX.aura(root, n)
		end
		if player == me and holder then
			local head = character:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local shown = head.LocalTransparencyModifier < 0.5
				RebirthFX.hideAura(holder, not shown)
			end
		end
	end
	local function refreshAll()
		for _, player in ipairs(Players:GetPlayers()) do
			refresh(player)
		end
	end
	local function watchPlayer(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			task.spawn(function()
				character:WaitForChild("HumanoidRootPart", 10)
				refresh(player)
			end)
		end)
		player:GetAttributeChangedSignal(CFG.Attributes.Rebirths):Connect(function()
			refresh(player)
		end)
		refresh(player)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	if me then
		me:GetAttributeChangedSignal(GameConfig.Afterimage.QualityAttribute):Connect(refreshAll)
	end
	pcall(function()
		GuiService:GetPropertyChangedSignal("ReducedMotionEnabled" :: any):Connect(refreshAll)
	end)
	-- A body streamed out and back, a first-person zoom: looked at again now and
	-- then rather than on every frame.
	task.spawn(function()
		while true do
			task.wait(2)
			refreshAll()
		end
	end)
end

--==============================================================================
-- ONE CELEBRATION
--==============================================================================
function RebirthFX.play(o: Options): Handle?
	local character = o.character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (rootPart and rootPart:IsA("BasePart")) then
		return nil
	end
	local root: BasePart = rootPart
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local previous = active[character]
	if previous then
		previous.stop()
	end
	local own = o.own == true
	local reduced = if o.reduced ~= nil then o.reduced else StatusText.reducedMotion()
	local n = Rebirth.count(o.rebirths)
	local said = RebirthCelebration.words(n, o.training, o.income)
	local tint = RebirthCelebration.tint(n)
	-- What the burst throws (the 100 titles, 2026-10-10): a new name its
	-- family's accent, a rank only a few motes and the title's pulse.
	local accent = RebirthCelebration.accent(n, o.before)
	counter += 1
	local stepName = "SeedRebirthFX" .. counter
	local stopped = false
	-- How far below the root the feet are.
	local drop = (if humanoid and humanoid.HipHeight > 0 then humanoid.HipHeight else 2) + root.Size.Y * 0.5

	--==========================================================================
	-- THE WORLD PIECES (none for REDUCED FX)
	--==========================================================================
	local folder = Instance.new("Folder")
	folder.Name = RebirthFX.Names.World
	local anchor: Part? = nil
	local core: Part?, glow: Part?, light: PointLight? = nil, nil, nil
	local orbs: { Orb } = {}
	local bursts: { ParticleEmitter } = {}
	local leaves: ParticleEmitter? = nil
	local sparkles: ParticleEmitter? = nil
	local headAt: Attachment? = nil
	local pollen: ParticleEmitter? = nil
	local twinkles: ParticleEmitter? = nil
	local fliers: { Flier } = {}
	local haloRays: ImageLabel? = nil
	if not reduced then
		local base = piece("Anchor", folder, Vector3.new(4, 0.4, 4), WHITE, Enum.Material.SmoothPlastic)
		anchor = base
		local col = C.Column
		core = piece("Column", folder, Vector3.new(0.1, col.Core, col.Core), col.CoreColour, Enum.Material.Neon,
			Enum.PartType.Cylinder)
		glow = piece("ColumnGlow", folder, Vector3.new(0.1, col.Glow, col.Glow), col.Colour, Enum.Material.Neon,
			Enum.PartType.Cylinder)
		local lamp = Instance.new("PointLight")
		lamp.Color = col.Colour
		lamp.Range = 16
		lamp.Brightness = 0
		lamp.Shadows = false
		lamp.Parent = core
		light = lamp

		local O = C.Orbs
		for i = 1, O.Count do
			local at = Instance.new("Attachment")
			at.Name = "Orb" .. i
			at.Parent = base
			local bill = Instance.new("BillboardGui")
			bill.Name = "Orb"
			bill.Size = UDim2.fromScale(O.Size, O.Size)
			bill.LightInfluence = 0
			bill.AlwaysOnTop = false
			bill.MaxDistance = 220
			bill.ResetOnSpawn = false
			bill.Active = false
			bill.Parent = at
			local image = Instance.new("ImageLabel")
			image.Name = "Glow"
			image.BackgroundTransparency = 1
			image.Size = UDim2.fromScale(1, 1)
			image.Image = T.Sparkle
			image.ImageRectOffset = ORB_RECT
			image.ImageRectSize = Vector2.new(256, 256)
			image.ImageColor3 = O.Colour
			image.ImageTransparency = 1
			image.Parent = bill
			local trail = sheet("Trail", at, T.Sparkle, Enum.ParticleFlipbookLayout.Grid2x2,
				Enum.ParticleFlipbookMode.OneShot)
			trail.Rate = 22
			trail.Lifetime = NumberRange.new(0.3, 0.45)
			trail.Speed = NumberRange.new(0)
			trail.Size = keys({ { 0, 0.7 }, { 1, 0.2 } })
			trail.LightEmission = 1
			trail.Color = ColorSequence.new(O.Colour)
			trail.Enabled = false
			table.insert(orbs, { at = at, image = image, trail = trail })
		end

		local B = C.Burst
		local chest = Instance.new("Attachment")
		chest.Name = "Chest"
		chest.Position = Vector3.new(0, drop, 0)
		chest.Parent = base
		local front = sheet("Burst", chest, T.Burst, Enum.ParticleFlipbookLayout.Grid4x4,
			Enum.ParticleFlipbookMode.OneShot)
		front.Lifetime = NumberRange.new(B.Lifetime)
		front.Size = NumberSequence.new(B.Size)
		front.Speed = NumberRange.new(0)
		front.LightEmission = 0.4
		-- Behind the body: it bursts round it, never over it.
		front.ZOffset = -2
		table.insert(bursts, front)
		local ground = Instance.new("Attachment")
		ground.Name = "Ground"
		ground.Position = Vector3.new(0, 0.25, 0)
		ground.Parent = base
		local flat = sheet("GroundBurst", ground, T.Burst, Enum.ParticleFlipbookLayout.Grid4x4,
			Enum.ParticleFlipbookMode.OneShot)
		flat.Lifetime = NumberRange.new(B.Lifetime)
		flat.Size = NumberSequence.new(B.Ground)
		-- Flat on the ground: a quad across its (upward) velocity.
		flat.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		flat.EmissionDirection = Enum.NormalId.Top
		flat.SpreadAngle = Vector2.zero
		flat.Speed = NumberRange.new(0.01)
		flat.LightEmission = 0.4
		table.insert(bursts, flat)

		local leaf = sheet("Leaves", base, T.Leaf, Enum.ParticleFlipbookLayout.Grid2x2,
			Enum.ParticleFlipbookMode.PingPong)
		leaf.FlipbookFramerate = NumberRange.new(8, 12)
		leaf.Color = tint
		leaf.Size = keys({ { 0, 0.5 }, { 0.2, 0.85 }, { 1, 0.6 } })
		leaf.Transparency = keys({ { 0, 0 }, { 0.75, 0 }, { 1, 1 } })
		-- Gone before the celebration ends (it starts 1.6 s in).
		leaf.Lifetime = NumberRange.new(1.2, 1.8)
		leaf.Speed = NumberRange.new(6, 11)
		leaf.SpreadAngle = Vector2.new(35, 35)
		leaf.EmissionDirection = Enum.NormalId.Top
		leaf.Acceleration = Vector3.new(0, 1.5, 0)
		leaf.Drag = 2.5
		leaf.Rotation = NumberRange.new(0, 360)
		leaf.RotSpeed = NumberRange.new(-120, 120)
		leaf.LightEmission = 0.15
		leaves = leaf
		local spark = sheet("Sparkles", base, T.Sparkle, Enum.ParticleFlipbookLayout.Grid2x2,
			Enum.ParticleFlipbookMode.OneShot)
		spark.Color = tint
		spark.Size = keys({ { 0, 0.5 }, { 1, 1.1 } })
		spark.Lifetime = NumberRange.new(0.6, 1.0)
		spark.Speed = NumberRange.new(8, 14)
		spark.SpreadAngle = Vector2.new(25, 25)
		spark.EmissionDirection = Enum.NormalId.Top
		spark.Acceleration = Vector3.new(0, 2, 0)
		spark.Drag = 3
		spark.LightEmission = 1
		sparkles = spark

		-- THE FAMILY'S OWN ACCENT ON A NEW NAME (2026-10-10, the two prototypes):
		-- Seedlight's leaf arc over the head with a pollen puff and twinkles;
		-- World Tree Halo's ring of leaves opening over the head, gold pollen and
		-- the owner's sunburst behind. In place of the leaves and sparkles above.
		local signature = accent.signature
		if signature then
			local family = accent.family
			local first = if family then family.Primary else C.Orbs.Colour
			local second = if family then family.Secondary else C.Orbs.Colour
			local halo = signature == "Halo"
			local head = Instance.new("Attachment")
			head.Name = "Head"
			head.Position = Vector3.new(0, drop + 1.5, 0)
			head.Parent = base
			headAt = head
			local puff = sheet("Pollen", head, T.Sparkle, Enum.ParticleFlipbookLayout.Grid2x2,
				Enum.ParticleFlipbookMode.OneShot)
			puff.Color = ColorSequence.new(if halo then C.Halo.Gold else second)
			puff.Size = keys({ { 0, 0.25 }, { 1, 0.5 } })
			puff.Lifetime = NumberRange.new(0.8, 1.3)
			puff.Speed = NumberRange.new(3, 6)
			puff.SpreadAngle = Vector2.new(40, 40)
			puff.EmissionDirection = Enum.NormalId.Top
			puff.Acceleration = Vector3.new(0, 1, 0)
			puff.Drag = 2
			puff.LightEmission = 1
			pollen = puff
			local count = if halo then C.Halo.Leaves else C.Seedlight.Leaves
			local size = if halo then C.Halo.LeafSize else C.Seedlight.LeafSize
			for i = 1, count do
				local holder: Instance = head
				local at: Attachment? = nil
				if halo then
					-- Round the head in the world: an attachment each.
					local a = Instance.new("Attachment")
					a.Name = "HaloLeaf" .. i
					a.Parent = base
					at = a
					holder = a
				end
				local bill = Instance.new("BillboardGui")
				bill.Name = if halo then "HaloLeaf" else "SeedlightLeaf"
				bill.Size = UDim2.fromScale(size, size)
				bill.LightInfluence = 0
				bill.AlwaysOnTop = false
				bill.MaxDistance = 220
				bill.ResetOnSpawn = false
				bill.Active = false
				bill.Parent = holder
				local image = Instance.new("ImageLabel")
				image.Name = "Leaf"
				image.BackgroundTransparency = 1
				image.Size = UDim2.fromScale(1, 1)
				image.Image = T.Leaf
				image.ImageRectSize = Vector2.new(256, 256)
				image.ImageColor3 = if i % 2 == 1 then first else second
				image.ImageTransparency = 1
				image.Rotation = (i * 47) % 360
				image.Parent = bill
				table.insert(fliers, { board = bill, at = at, image = image })
			end
			if not halo then
				local twinkle = sheet("Twinkles", head, T.Sparkle, Enum.ParticleFlipbookLayout.Grid2x2,
					Enum.ParticleFlipbookMode.OneShot)
				twinkle.Color = ColorSequence.new(WHITE, first)
				twinkle.Size = keys({ { 0, 0.4 }, { 0.5, 0.9 }, { 1, 0.3 } })
				twinkle.Lifetime = NumberRange.new(0.5, 0.8)
				twinkle.Speed = NumberRange.new(1.5, 3)
				twinkle.SpreadAngle = Vector2.new(180, 180)
				twinkle.LightEmission = 1
				twinkles = twinkle
			elseif C.Rays ~= "" then
				local bill = Instance.new("BillboardGui")
				bill.Name = "HaloRays"
				bill.Size = UDim2.fromScale(C.Halo.RaysSize, C.Halo.RaysSize)
				-- Behind the head in camera space, never over the face.
				bill.StudsOffset = Vector3.new(0, 0.6, -1.2)
				bill.LightInfluence = 0
				bill.AlwaysOnTop = false
				bill.MaxDistance = 220
				bill.ResetOnSpawn = false
				bill.Active = false
				bill.Parent = head
				local image = Instance.new("ImageLabel")
				image.Name = "Rays"
				image.BackgroundTransparency = 1
				image.Size = UDim2.fromScale(1, 1)
				image.ScaleType = Enum.ScaleType.Fit
				image.Image = C.Rays
				image.ImageColor3 = C.Halo.Gold
				image.ImageTransparency = 1
				image.Parent = bill
				haloRays = image
			end
		end
	end
	folder.Parent = o.world or Workspace

	--==========================================================================
	-- THE OWN SCREEN: the flash and the card
	--==========================================================================
	local guiParent: Instance? = o.gui
	if own and not guiParent then
		local me = Players.LocalPlayer
		guiParent = me and me:FindFirstChildOfClass("PlayerGui")
	end
	local cardGui: ScreenGui? = nil
	local flashGui: ScreenGui? = nil
	local flashFrame: Frame? = nil
	local card: TextButton? = nil
	local fit: UIScale? = nil
	local rays: Frame? = nil
	local rayParts: { Fade } = {}
	local rainbow: UIGradient? = nil
	local fades: { Fade } = {}
	if own and guiParent then
		local P = C.Popup
		if not reduced then
			local whole = Instance.new("ScreenGui")
			whole.Name = RebirthFX.Names.Flash
			whole.ResetOnSpawn = false
			whole.IgnoreGuiInset = true
			whole.ScreenInsets = Enum.ScreenInsets.None
			whole.DisplayOrder = C.DisplayOrder - 1
			local flash = Instance.new("Frame")
			flash.Name = "Flash"
			flash.Size = UDim2.fromScale(1, 1)
			flash.BorderSizePixel = 0
			flash.BackgroundColor3 = C.FlashColour
			flash.BackgroundTransparency = 1
			flash.Active = false
			flash.Parent = whole
			whole.Parent = guiParent
			flashGui = whole
			flashFrame = flash
		end
		local screen = Instance.new("ScreenGui")
		screen.Name = RebirthFX.Names.Card
		screen.ResetOnSpawn = false
		screen.DisplayOrder = C.DisplayOrder
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.Parent = guiParent
		-- The HUD's own units on a TV, so HudLayout's rects mean the same here.
		UIKit.tenFoot(screen)
		cardGui = screen

		-- A tap on it closes it sooner; it takes no other tap.
		local button = Instance.new("TextButton")
		button.Name = "Card"
		button.Text = ""
		button.AutoButtonColor = false
		button.Selectable = false
		button.BackgroundTransparency = 1
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = UDim2.fromScale(0.5, 0.3)
		button.Size = UDim2.fromOffset(P.Size.X, P.Size.Y)
		button.Visible = false
		button.ZIndex = 1
		button.Parent = screen
		card = button
		local scale = Instance.new("UIScale")
		scale.Parent = button
		fit = scale

		-- The emblem's middle, in the card's own units.
		local ex, ey = 16 + P.Emblem * 0.5, P.Size.Y * 0.5
		if not reduced then
			-- The rays, turning: the owner's white sunburst tinted RayColour once
			-- its id is in, drawn bars until then (never another upload).
			local holder = Instance.new("Frame")
			holder.Name = "Rays"
			holder.BackgroundTransparency = 1
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.fromOffset(ex, ey)
			holder.Size = UDim2.fromOffset(P.Rays, P.Rays)
			-- UNDER THE EMBLEM AND THE WORDS (2026-10-09, the owner's sunburst),
			-- round the emblem. The card has had no plate since the same day's
			-- transparency rule; the burst was put over the plate first because
			-- behind it only its tips showed past the card's edge (seen in Play).
			holder.ZIndex = 3
			holder.Active = false
			holder.Parent = button
			rays = holder
			if C.Rays ~= "" then
				local image = Instance.new("ImageLabel")
				image.Name = "Burst"
				image.BackgroundTransparency = 1
				image.Size = UDim2.fromScale(1, 1)
				image.ScaleType = Enum.ScaleType.Fit
				image.Image = C.Rays
				image.ImageColor3 = C.RayColour
				image.ImageTransparency = 1
				image.ZIndex = 3
				image.Parent = holder
				-- Softened, so the words over it still read.
				table.insert(rayParts, { instance = image, property = "ImageTransparency", base = C.RayFade })
			else
				for i = 1, C.RayBars do
					local bar = Instance.new("Frame")
					bar.Name = "Ray"
					bar.BorderSizePixel = 0
					bar.BackgroundColor3 = C.RayColour
					bar.BackgroundTransparency = 1
					bar.AnchorPoint = Vector2.new(0.5, 0.5)
					bar.Position = UDim2.fromScale(0.5, 0.5)
					bar.Size = UDim2.new(0, 16, 1, 0)
					bar.Rotation = (i - 1) * 180 / C.RayBars
					bar.ZIndex = 3
					bar.Active = false
					bar.Parent = holder
					-- Soft at both ends; the middle is behind the card anyway.
					local soft = Instance.new("UIGradient")
					soft.Rotation = 90
					soft.Transparency = keys({ { 0, 1 }, { 0.18, 0.35 }, { 0.5, 0.1 }, { 0.82, 0.35 }, { 1, 1 } })
					soft.Parent = bar
					table.insert(rayParts, { instance = bar, property = "BackgroundTransparency", base = 0 })
				end
			end
		end
		-- TRANSPARENT (2026-10-09, the owner: "everything must be transparent,
		-- applies to buffs, and effects", and yes for this card): no plate and no
		-- rim -- the rays, the emblem and the outlined words over the scene.

		local emblem = Instance.new("ImageLabel")
		emblem.Name = "Emblem"
		emblem.BackgroundTransparency = 1
		emblem.AnchorPoint = Vector2.new(0.5, 0.5)
		emblem.Position = UDim2.fromOffset(ex, ey)
		emblem.Size = UDim2.fromOffset(P.Emblem, P.Emblem)
		emblem.ScaleType = Enum.ScaleType.Fit
		emblem.Image = ART.Emblem
		emblem.ImageRectOffset = ART.CropOffset
		emblem.ImageRectSize = ART.CropSize
		emblem.ZIndex = 4
		emblem.Parent = button
		table.insert(fades, { instance = emblem, property = "ImageTransparency", base = 0 })

		local wx = 16 + P.Emblem + 14
		local room = RebirthFX.cardRoom()
		local S, F = RebirthFX.Sizes, RebirthFX.Fonts
		-- REBORN!: the owner's word picture once its id is in (Celebration.Logo,
		-- 1024 x 384, left on the card like the lines), the words until then.
		local reborn: TextLabel? = nil
		if C.Logo ~= "" then
			local logo = Instance.new("ImageLabel")
			logo.Name = "Logo"
			logo.BackgroundTransparency = 1
			logo.Position = UDim2.fromOffset(wx, 4)
			logo.Size = UDim2.fromOffset(math.floor(60 * 1024 / 384), 60)
			logo.ScaleType = Enum.ScaleType.Fit
			logo.Image = C.Logo
			logo.ZIndex = 4
			logo.Parent = button
			table.insert(fades, { instance = logo, property = "ImageTransparency", base = 0 })
		else
			local words = cardLine(button, "Reborn", F.Reborn, S.Reborn, GOLD, UDim2.fromOffset(wx, 12),
				UDim2.fromOffset(room, 50), 4)
			words.Text = said.reborn
			reborn = words
		end
		local line = cardLine(button, "Line", F.Line, S.Line, if said.rainbow then WHITE else said.colour,
			UDim2.fromOffset(wx, 66), UDim2.fromOffset(room, 34), 4)
		line.Text = said.line
		if said.rainbow then
			-- GAIA: the rainbow, turning (still for REDUCED FX). The dark outline
			-- stays dark under it.
			local g = Instance.new("UIGradient")
			g.Name = "Rainbow"
			g.Color = WheelDraw.rainbow(0)
			g.Parent = line
			rainbow = g
		end
		local bonus = cardLine(button, "Bonus", F.Bonus, S.Bonus, WHITE, UDim2.fromOffset(wx, 104),
			UDim2.fromOffset(room, 30), 4)
		bonus.Text = said.bonus
		local labels = { line, bonus }
		if reborn then
			table.insert(labels, 1, reborn)
		end
		for _, label in ipairs(labels) do
			local stroke = outlineOf(label, if label == reborn then 3 else 2.5)
			table.insert(fades, { instance = label, property = "TextTransparency", base = 0 })
			table.insert(fades, { instance = stroke, property = "Transparency", base = 0 })
		end
	end

	-- The card's place on this screen: RebirthCelebration.popup, from the HUD.
	local fitScale = 1
	local function placeCard()
		local screen, button = cardGui, card
		if not (screen and button) or screen.AbsoluteSize.X <= 0 then
			return
		end
		local L = HudLayout.solve(HudLayout.measure(screen))
		local phone = if o.phone ~= nil then o.phone else UIKit.phoneMenuScale() < 1
		-- The notices' line is soft: kept off unless that draws the card too small
		-- to read (2026-10-09, under the phone's panel row).
		local r, s = RebirthCelebration.popup(L.safe, HudLayout.occupiedButToast(L), phone, { L.toast })
		fitScale = s
		button.Position = UDim2.fromOffset(r.x + r.w * 0.5, r.y + r.h * 0.5)
	end
	placeCard()
	local placed: RBXScriptConnection? = nil
	if cardGui then
		placed = cardGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeCard)
	end

	--==========================================================================
	-- THE BODY: the spin, with the camera held still and the controls held
	--==========================================================================
	local hold: Hold? = nil
	local camera: any = if own and not reduced then (o.camera or Workspace.CurrentCamera) else nil
	local startYaw, total = 0, 0
	if camera then
		startYaw = RebirthCelebration.yaw(root.CFrame.LookVector)
		local toCamera = camera.CFrame.Position - root.Position
		local flat = Vector3.new(toCamera.X, 0, toCamera.Z)
		local faceYaw = if flat.Magnitude > 0.05 then RebirthCelebration.yaw(flat) else startYaw
		total = RebirthCelebration.turn(startYaw, faceYaw)
		local h: Hold = { cameraType = camera.CameraType, cframe = camera.CFrame, subject = camera.CameraSubject }
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = h.cframe
		if humanoid then
			h.autoRotate = humanoid.AutoRotate
			humanoid.AutoRotate = false
			h.jump = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
		hold = h
	end

	local function turnBody(p: number)
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, startYaw + total * p, 0)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
		root.AssemblyAngularVelocity = Vector3.zero
		if humanoid then
			-- After the controls' own write this frame: no walking while it spins.
			humanoid:Move(Vector3.zero, false)
		end
	end

	-- Everything back exactly as it was: the camera's type, place and subject,
	-- the body's turning and its jump.
	local function giveBack()
		local h = hold
		if not h then
			return
		end
		hold = nil
		if camera then
			camera.CFrame = h.cframe
			camera.CameraType = h.cameraType
			if camera.CameraSubject ~= h.subject then
				camera.CameraSubject = h.subject
			end
			camera.CFrame = h.cframe
		end
		if humanoid then
			if h.autoRotate ~= nil then
				humanoid.AutoRotate = h.autoRotate
			end
			if h.jump ~= nil then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, h.jump)
			end
		end
	end

	--==========================================================================
	-- EVERY FRAME
	--==========================================================================
	local handle: Handle
	local burstGone = false
	local dismissedAt: number? = nil
	local lastT = 0
	local renderConnection: RBXScriptConnection? = nil
	local bound = false

	local function stop()
		if stopped then
			return
		end
		stopped = true
		if bound then
			RunService:UnbindFromRenderStep(stepName .. "Hold")
			RunService:UnbindFromRenderStep(stepName)
		end
		if renderConnection then
			renderConnection:Disconnect()
		end
		if placed then
			placed:Disconnect()
		end
		giveBack()
		folder:Destroy()
		if cardGui then
			cardGui:Destroy()
		end
		if flashGui then
			flashGui:Destroy()
		end
		if active[character] == handle then
			active[character] = nil
		end
	end

	local function step(t: number)
		if stopped then
			return
		end
		lastT = t
		if not root.Parent or (humanoid and humanoid.Health <= 0) then
			stop()
			return
		end
		local f = RebirthCelebration.at(t, reduced)
		if hold then
			if f.held then
				turnBody(f.spin)
			else
				-- Exactly round, facing the camera, and everything handed back.
				turnBody(1)
				giveBack()
			end
		end
		local base = anchor
		if base then
			local feet = root.Position - Vector3.new(0, drop, 0)
			base.CFrame = CFrame.new(feet)
			local col = C.Column
			if core and glow then
				local h = math.max(0.05, col.Height * f.column)
				local up = CFrame.new(feet + Vector3.new(0, h * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
				core.Size = Vector3.new(h, col.Core, col.Core)
				core.CFrame = up
				core.Transparency = 1 - 0.8 * f.columnAlpha
				glow.Size = Vector3.new(h, col.Glow, col.Glow)
				glow.CFrame = up
				glow.Transparency = 1 - 0.3 * f.columnAlpha
			end
			if light then
				light.Brightness = 2.5 * f.columnAlpha
			end
			for i, orb in ipairs(orbs) do
				orb.at.Position = RebirthCelebration.orb(i, f) + Vector3.new(0, drop, 0)
				orb.image.ImageTransparency = 1 - f.orbAlpha
				orb.trail.Enabled = f.orbAlpha > 0.05
			end
			if f.burst and not burstGone then
				burstGone = true
				for _, b in ipairs(bursts) do
					b:Emit(1)
				end
				if leaves and accent.leaves > 0 then
					leaves:Emit(accent.leaves)
				end
				if sparkles and accent.sparkles > 0 then
					sparkles:Emit(accent.sparkles)
				end
				if pollen then
					pollen:Emit(if accent.signature == "Halo" then C.Halo.Pollen else C.Seedlight.Pollen)
				end
				if twinkles then
					twinkles:Emit(C.Seedlight.Twinkles)
				end
				if accent.pulse then
					-- A rank only: the title over the head pulses once (OwnerTitleUI).
					local headPart = character:FindFirstChild("Head")
					local title = headPart and headPart:FindFirstChild(CFG.Title.Name)
					if title then
						title:SetAttribute(RebirthFX.PulseAttribute, os.clock())
					end
				end
			end
			-- The signature's leaves (and the halo's rays), round the head.
			local head = headAt
			if head then
				local headPart = character:FindFirstChild("Head")
				head.Position = if headPart and headPart:IsA("BasePart")
					then headPart.Position - feet
					else Vector3.new(0, drop + 1.5, 0)
				local u = t - C.SpinSeconds
				for i, flier in ipairs(fliers) do
					local at = flier.at
					if at then
						local offset, alpha = RebirthCelebration.haloLeaf(i, #fliers, u)
						at.Position = head.Position + offset
						flier.image.ImageTransparency = 1 - alpha
					else
						local offset, alpha = RebirthCelebration.seedlightLeaf(i, #fliers, u)
						flier.board.StudsOffset = offset
						flier.image.ImageTransparency = 1 - alpha
					end
				end
				local rays = haloRays
				if rays then
					rays.ImageTransparency = 1 - (1 - C.RayFade) * RebirthCelebration.haloRays(u)
					rays.Rotation = (math.max(0, u) * C.RaySpin) % 360
				end
			end
		end
		local flash = flashFrame
		if flash then
			flash.Visible = f.flash > 0
			flash.BackgroundTransparency = 1 - (1 - C.FlashTransparency) * f.flash
		end
		local button = card
		if button then
			local a = f.popAlpha
			local gone = dismissedAt
			if gone then
				a = math.min(a, math.max(0, 1 - (t - gone) / 0.2))
			end
			button.Visible = f.popup and a > 0
			button.Active = button.Visible
			if fit then
				fit.Scale = fitScale * f.popScale
			end
			for _, fade in ipairs(fades) do
				(fade.instance :: any)[fade.property] = 1 - (1 - fade.base) * a
			end
			local turning = rays
			if turning then
				turning.Rotation = f.rayAngle
				for _, ray in ipairs(rayParts) do
					(ray.instance :: any)[ray.property] = 1 - (1 - ray.base) * f.rays * a
				end
			end
			local g = rainbow
			if g and not reduced then
				g.Color = WheelDraw.rainbow((t / 3) % 1)
			end
		end
		if f.done then
			stop()
		end
	end

	handle = {
		step = step,
		stop = stop,
		finished = function(): boolean
			return stopped
		end,
		world = folder,
		card = card,
	}
	active[character] = handle
	if card then
		card.Activated:Connect(function()
			if not dismissedAt then
				dismissedAt = lastT
			end
		end)
	end

	-- The fanfare: flat on this screen for its own rebirth, from the body for
	-- anybody else's (SoundKit.emit, the cue's range).
	if o.sound then
		o.sound(own, root)
	elseif own then
		SoundKit.play(C.Cue)
	else
		SoundKit.emit(C.NearbyCue, root)
	end

	step(0)
	if not o.manual and not stopped then
		local t0 = os.clock()
		if camera then
			-- Held still on both sides of the camera's own step (the engine's
			-- step runs once in the frame a camera is taken), then the frame's
			-- work after the controls and the camera have written theirs.
			bound = true
			RunService:BindToRenderStep(stepName .. "Hold", Enum.RenderPriority.Camera.Value - 1, function()
				local h = hold
				if h and camera then
					camera.CFrame = h.cframe
				end
			end)
			RunService:BindToRenderStep(stepName, Enum.RenderPriority.Camera.Value + 1, function()
				step(os.clock() - t0)
			end)
		else
			renderConnection = RunService.RenderStepped:Connect(function()
				step(os.clock() - t0)
			end)
		end
	end
	return handle
end

return RebirthFX
