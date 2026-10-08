--!strict
-- Steal a Seed :: InviteHub (client)
--
-- The Invite a Friend pedestal on THIS screen (2026-10-06): this player's own
-- form standing on the shared pedestal, the sign's words and bar, the evolve
-- moment, and the prompt's answer.
--
--   THE FORM   built here, for this player only (SecretModel.BuildDisplay),
--              scaled whole to fill the room under the sign
--              (InviteRewards.displayScale), its lights with it but never past
--              DisplayLightMax, idling under SecretIdle and never walking (no
--              Planted tag). A display copy: the source model and a granted
--              plant keep their own size. It
--              is a local model, so streaming never takes it away: it stands
--              wherever the hub does. Which form is InviteRewards.content's
--              answer for the two numbers the server publishes -- never this
--              script's own count, and never ahead of the grant.
--   THE SIGN   the shared plate's two faces, drawn in this PlayerGui and
--              adorned to it: INVITE FRIENDS, the form's name, its rarity and
--              $/s, NEXT and the bar -- or FINAL FORM REACHED with a gold trim.
--              Past Sign.FarFrom studs from the camera, only INVITE / FRIENDS,
--              as large as the plate allows (read from the nearest spawn pad,
--              the owner, 2026-10-06); nearer, the whole sign again.
--   EVOLVING   when the shown form changes while the player is here: the old
--              form shrinks away, a burst in the new form's rarity colour with
--              the hatch's crack, the new form grows in -- under 2 s. On join
--              the form simply stands; a jump past several forms evolves once,
--              straight to the last.
--   THE PROMPT INVITE A FRIEND: Roblox's own invite dialog (InviteSend).
--
-- Every animation is decoration: the form and the sign are right without it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local InviteRewards = require(Shared:WaitForChild("InviteRewards"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))
local InviteSend = require(Shared:WaitForChild("InviteSend"))
local InviteSounds = require(Shared:WaitForChild("InviteSounds"))

local player = Players.LocalPlayer
local CONFIG = GameConfig.InviteRewards
local A = CONFIG.Attributes
local S = CONFIG.Sign
local E = CONFIG.Evolve
local WORDS = CONFIG.Words

if not CONFIG.Enabled then
	return
end

local folder = Instance.new("Folder")
folder.Name = "InviteHubLocal"
folder.Archivable = false
folder.Parent = Workspace

--==============================================================================
-- THE SIGN
--==============================================================================
local W, H = S.Width * S.PixelsPerStud, S.Height * S.PixelsPerStud
-- The whole sign is laid out as it was on the old 14 x 7.4 plate's 700 x 370
-- canvas, every length times K: the canvas's height over that one's. Lengths
-- across take what the width leaves, so the lines fill the wider plate. The
-- rows, top to bottom, are Sign.Rows.
local K = H / 370
local ROWS = S.Rows

local function hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end

local function stroke(parent: Instance, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = CONFIG.Ink
	s.Thickness = thickness
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
end

local function label(parent: Instance, name: string, x: number, y: number, w: number, h: number,
	font: Enum.Font, colour: Color3, inkWidth: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.Font = font
	l.TextColor3 = colour
	l.TextScaled = true
	l.RichText = true
	l.Text = ""
	stroke(l, inkWidth)
	l.Parent = parent
	return l
end

type Face = {
	gui: SurfaceGui,
	near: Frame,
	far: Frame,
	rules: Frame,
	trim: UIStroke,
	farTrim: UIStroke,
	name: TextLabel,
	info: TextLabel,
	nextLine: TextLabel,
	fill: Frame,
	barText: TextLabel,
}

-- The far view or the whole sign (see the switch under THE SIGN FROM AFAR).
local farNow = false
-- The near sign's rules in place of its progress (THE RULES ON THE SIGN).
local rulesNow = false

-- The final form's gold trim round a view (off until then).
local function goldTrim(parent: Frame): UIStroke
	local trim = Instance.new("UIStroke")
	trim.Color = CONFIG.Gold
	trim.Thickness = 10 * K
	trim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trim.Enabled = false
	trim.Parent = parent
	return trim
end

local function face(plate: BasePart, normal: Enum.NormalId): Face
	local gui = Instance.new("SurfaceGui")
	gui.Name = "InviteSign" .. normal.Name
	gui.Face = normal
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(W, H)
	gui.LightInfluence = 0
	gui.MaxDistance = S.MaxDistance
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Adornee = plate

	-- The plate shows through: its own studded face is the background.
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Visible = not farNow
	root.Parent = gui
	local trim = goldTrim(root)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = GameConfig.BagLook.PlateEdge
	header.BackgroundTransparency = 0.1
	header.Position = UDim2.fromOffset(70 * K, ROWS.Header[1] * K)
	header.Size = UDim2.fromOffset(W - 140 * K, ROWS.Header[2] * K)
	header.Parent = root
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18 * K)
	corner.Parent = header
	local title = label(header, "Title", 16 * K, ROWS.Title[1] * K, W - 172 * K, ROWS.Title[2] * K,
		Enum.Font.LuckiestGuy, Color3.new(1, 1, 1), 3 * K)
	title.Text = WORDS.Title

	local name = label(root, "FormName", 24 * K, ROWS.Name[1] * K, W - 48 * K, ROWS.Name[2] * K, Enum.Font.LuckiestGuy,
		Color3.new(1, 1, 1), 4 * K)
	local info = label(root, "Info", 24 * K, ROWS.Info[1] * K, W - 48 * K, ROWS.Info[2] * K, Enum.Font.GothamBold,
		CONFIG.Cream, 2.5 * K)
	local nextLine = label(root, "Next", 24 * K, ROWS.Next[1] * K, W - 48 * K, ROWS.Next[2] * K, Enum.Font.GothamBold,
		CONFIG.Cream, 2 * K)

	-- The chunky bar: ink, a dark track, the fill with its studs, the count on top.
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BackgroundColor3 = CONFIG.Ink
	bar.Position = UDim2.fromOffset(44 * K, ROWS.Bar[1] * K)
	bar.Size = UDim2.fromOffset(W - 88 * K, ROWS.Bar[2] * K)
	bar.Parent = root
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 18 * K)
	barCorner.Parent = bar
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = GameConfig.BagLook.PlateEdge
	track.Position = UDim2.fromOffset(7 * K, 7 * K)
	track.Size = UDim2.new(1, -14 * K, 1, -14 * K)
	track.ClipsDescendants = true
	track.Parent = bar
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 12 * K)
	trackCorner.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.ClipsDescendants = true
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 12 * K)
	fillCorner.Parent = fill
	-- Raised studs along the fill (a fixed row; the fill clips them).
	local trackW = W - 88 * K - 14 * K
	for i = 0, math.floor(trackW / (34 * K)) do
		local stud = Instance.new("Frame")
		stud.Name = "Stud"
		stud.AnchorPoint = Vector2.new(0.5, 0.5)
		stud.Position = UDim2.new(0, (17 + i * 34) * K, 0.5, 0)
		stud.Size = UDim2.fromOffset(20 * K, 20 * K)
		stud.BackgroundColor3 = Color3.new(1, 1, 1)
		stud.BackgroundTransparency = 0.72
		stud.BorderSizePixel = 0
		stud.Parent = fill
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(1, 0)
		round.Parent = stud
	end
	local barText = label(bar, "Count", 0, ROWS.Count[1] * K, W - 88 * K, ROWS.Count[2] * K, Enum.Font.LuckiestGuy,
		Color3.new(1, 1, 1), 3 * K)
	barText.ZIndex = 3

	-- THE FAR VIEW: the title on two lines (Words.SignFar), each half the plate
	-- less FarPad all round -- TextScaled's 100-px top, 100 / PixelsPerStud studs
	-- -- in a heavier ink line than the near words, for the distance.
	local far = Instance.new("Frame")
	far.Name = "Far"
	far.BackgroundTransparency = 1
	far.Size = UDim2.fromScale(1, 1)
	far.Visible = farNow
	far.Parent = gui
	local farTrim = goldTrim(far)
	local pad = S.FarPad
	local lineH = (H - pad * 2) / #WORDS.SignFar
	for i, word in ipairs(WORDS.SignFar) do
		local line = label(far, "Line" .. i, pad, pad + (i - 1) * lineH, W - pad * 2, lineH, Enum.Font.LuckiestGuy,
			Color3.new(1, 1, 1), 8)
		line.Text = word
	end

	-- THE RULES (2026-10-08, the owner's brief): in the near view's place for a
	-- few seconds in every cycle -- who counts, the four plants, a returning
	-- friend's spin (Words.Rules), each on its own line, as large as it fits.
	local rules = Instance.new("Frame")
	rules.Name = "Rules"
	rules.BackgroundTransparency = 1
	rules.Size = UDim2.fromScale(1, 1)
	rules.Visible = false
	rules.Parent = gui
	local rulesHeader = Instance.new("Frame")
	rulesHeader.Name = "Header"
	rulesHeader.BackgroundColor3 = GameConfig.BagLook.PlateEdge
	rulesHeader.BackgroundTransparency = 0.1
	rulesHeader.Position = UDim2.fromOffset(70 * K, 12 * K)
	rulesHeader.Size = UDim2.fromOffset(W - 140 * K, 66 * K)
	rulesHeader.Parent = rules
	local rulesCorner = Instance.new("UICorner")
	rulesCorner.CornerRadius = UDim.new(0, 18 * K)
	rulesCorner.Parent = rulesHeader
	local rulesTitle = label(rulesHeader, "Title", 16 * K, 6 * K, W - 172 * K, 54 * K, Enum.Font.LuckiestGuy,
		Color3.new(1, 1, 1), 3 * K)
	rulesTitle.Text = WORDS.RulesTitle
	for i, line in ipairs(WORDS.Rules) do
		local l = label(rules, "Rule" .. i, 24 * K, (92 + (i - 1) * 84) * K, W - 48 * K, 70 * K, Enum.Font.GothamBold,
			CONFIG.Cream, 2.5 * K)
		l.Text = line
	end

	gui.Parent = player:WaitForChild("PlayerGui")
	return {
		gui = gui,
		near = root,
		far = far,
		rules = rules,
		trim = trim,
		farTrim = farTrim,
		name = name,
		info = info,
		nextLine = nextLine,
		fill = fill,
		barText = barText,
	}
end

local faces: { Face } = {}
local signPlate: BasePart? = nil

--==============================================================================
-- THE SIGN FROM AFAR: past FarFrom studs between the camera and the plate the
-- far view, back under FarFrom - FarBand -- asked four times a second.
--==============================================================================
local function showViews()
	for _, f in ipairs(faces) do
		f.near.Visible = not farNow and not rulesNow
		f.rules.Visible = not farNow and rulesNow
		f.far.Visible = farNow
	end
end

local function setFar(want: boolean)
	if want == farNow then
		return
	end
	farNow = want
	showViews()
end

-- THE RULES ON THE SIGN: the progress for most of each cycle, the rules for
-- RulesSignSeconds of it. The far view is unchanged.
task.spawn(function()
	while folder.Parent do
		task.wait(CONFIG.RulesSignCycle - CONFIG.RulesSignSeconds)
		rulesNow = true
		showViews()
		task.wait(CONFIG.RulesSignSeconds)
		rulesNow = false
		showViews()
	end
end)

task.spawn(function()
	while folder.Parent do
		task.wait(0.25)
		local camera, plate = Workspace.CurrentCamera, signPlate
		if camera and plate then
			local d = (camera.CFrame.Position - plate.Position).Magnitude
			if farNow then
				if d < S.FarFrom - S.FarBand then
					setFar(false)
				end
			elseif d > S.FarFrom then
				setFar(true)
			end
		end
	end
end)

local function drawSign(content: InviteRewards.Content)
	local shown = content.shown
	local nameText = string.upper(shown.name)
	local infoText = string.format('<font color="%s">%s</font>  <font color="%s">%s</font>', hex(shown.colour),
		string.upper(shown.rarity), hex(CONFIG.Income), shown.incomeText)
	local nextText = ""
	if content.final then
		nextText = string.format('<font color="%s">%s</font>', hex(CONFIG.Gold), content.finalText or WORDS.Final)
	elseif content.next then
		local nxt = content.next :: InviteRewards.Reward
		nextText = string.format(WORDS.Next, nxt.name, string.format('<font color="%s">%s</font>', hex(nxt.colour),
			nxt.rarity), nxt.at, InviteRewards.plural(nxt.at))
	end
	for _, f in ipairs(faces) do
		f.name.Text = nameText
		f.info.Text = infoText
		f.nextLine.Text = nextText
		f.fill.BackgroundColor3 = content.fill
		f.fill.Size = UDim2.fromScale(content.fraction, 1)
		f.barText.Text = content.barText
		f.trim.Enabled = content.final
		f.farTrim.Enabled = content.final
	end
end

--==============================================================================
-- THE FORM AND ITS EVOLVE MOMENT
--==============================================================================
local display: Model? = nil
-- What stands, and what is wanted: content.shown's form at content.tier. The
-- form is the last plant of the track owned -- one won on the wheel too
-- (2026-10-08) -- so a new form or a new tier is each an evolve moment.
local shownKey: string? = nil
local wantKey: string? = nil
local wantForm: string? = nil
local evolving = false

local function ease(x: number): number
	return x * x * (3 - 2 * x)
end

local function stand(form: string): Model
	local model = Instance.new("Model")
	model.Name = "InviteForm"
	model:SetAttribute("InviteForm", form)
	SecretModel.BuildDisplay(form, InviteRewards.standFrame(), model, InviteRewards.displayScale(form))
	-- Its lights grew with it (range x scale); never past DisplayLightMax.
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("PointLight") then
			d.Range = math.min(d.Range, CONFIG.DisplayLightMax)
		end
	end
	model.Parent = folder
	return model
end

-- A burst on the pedestal in the new form's rarity colour, with the hatch's crack.
local function burst(colour: Color3)
	local at = InviteRewards.standFrame() * CFrame.new(0, 2, 0)
	local holder = Instance.new("Part")
	holder.Name = "InviteBurst"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.CFrame = at
	holder.Parent = folder
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(colour)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	sparks.Speed = NumberRange.new(8, 15)
	sparks.Lifetime = NumberRange.new(0.5, 0.9)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 0
	sparks.Parent = holder
	sparks:Emit(E.Sparks)
	local ring = Instance.new("Part")
	ring.Name = "InviteRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = colour
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Size = Vector3.new(0.15, 1, 1)
	ring.CFrame = InviteRewards.standFrame() * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.15
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.15, 11, 11), Transparency = 1 }):Play()
	-- The owner's invite_evolve, in the world on the pedestal: heard on the deck.
	InviteSounds.emit("evolve", holder)
	task.delay(1.5, function()
		holder:Destroy()
		ring:Destroy()
	end)
end

-- Scale a still model about its base over `seconds`, from `from` to `to`.
local function scaleOver(model: Model, from: number, to: number, seconds: number)
	local started = os.clock()
	while model.Parent do
		local k = math.clamp((os.clock() - started) / seconds, 0, 1)
		pcall(function()
			model:ScaleTo(math.max(0.02, from + (to - from) * ease(k)))
		end)
		if k >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
end

local function evolveTo(form: string, key: string)
	evolving = true
	local old = display
	if old then
		-- Out of the animator's hands, then shrunk away.
		CollectionService:RemoveTag(old, SecretModel.RIG_TAG)
		scaleOver(old, 1, 0.02, E.Shrink)
		old:Destroy()
	end
	burst(InviteRewards.reward(1, form).colour)
	task.wait(E.Hold)
	local new = stand(form)
	CollectionService:RemoveTag(new, SecretModel.RIG_TAG)
	pcall(function()
		new:ScaleTo(0.02)
	end)
	scaleOver(new, 0.02, 1, E.Grow)
	pcall(function()
		new:ScaleTo(1)
	end)
	-- Whole and at rest: the animator takes it again.
	CollectionService:AddTag(new, SecretModel.RIG_TAG)
	display = new
	shownKey = key
	evolving = false
	-- A later change while this one ran: straight to it, once.
	local later, laterForm = wantKey, wantForm
	if later and laterForm and later ~= key then
		evolveTo(laterForm, later)
	end
end

-- The bar filling one step, while the sign is in view and the panel is not
-- open (the panel ticks for itself): a tick a step, InviteSounds' rules over it.
local lastCount: number? = nil
local function signInView(): boolean
	local camera = Workspace.CurrentCamera
	if not camera or player:GetAttribute(GameConfig.Attributes.OpenPanel) ~= nil then
		return false
	end
	local at = InviteRewards.standFrame().Position + Vector3.new(0, S.Bottom, 0)
	local _, onScreen = camera:WorldToViewportPoint(at)
	return onScreen and (camera.CFrame.Position - at).Magnitude <= S.MaxDistance
end

local function refresh()
	local count, granted = player:GetAttribute(A.Count), player:GetAttribute(A.Granted)
	if count == nil or granted == nil then
		return
	end
	-- The plants owned, the wheel's too: the sign and the pedestal name the
	-- plant each milestone really gives (InviteRewards, THE TRACK WITH THE WHEEL).
	local content = InviteRewards.content(count, granted, InviteRewards.ownedSet(player:GetAttribute(A.Owned)))
	drawSign(content)
	local before = lastCount
	lastCount = content.count
	if before and content.count > before and signInView() then
		for step = 1, math.min(content.count - before, GameConfig.InviteRewards.TickRun) do
			task.delay((step - 1) * 0.15, InviteSounds.play, "tick")
		end
	end
	local form = content.shown.form
	local key = form .. "@" .. tostring(content.tier)
	wantKey, wantForm = key, form
	if shownKey == nil then
		-- On join: the form simply stands.
		shownKey = key
		display = stand(form)
		return
	end
	if key ~= shownKey and not evolving then
		task.spawn(evolveTo, form, key)
	end
end

--==============================================================================
-- WIRING
--==============================================================================
task.spawn(function()
	local hub = Workspace:WaitForChild(CONFIG.FolderName, 60)
	local model = if hub then hub:WaitForChild("InvitePedestal", 30) else nil
	local plate = if model then model:WaitForChild("SignPlate", 30) else nil
	local top = if model then model:WaitForChild("Top", 30) else nil
	if plate and plate:IsA("BasePart") then
		table.insert(faces, face(plate, Enum.NormalId.Front))
		table.insert(faces, face(plate, Enum.NormalId.Back))
		signPlate = plate
	end
	local prompt = if top then top:WaitForChild("InvitePrompt", 30) else nil
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(who: Player)
			if who == player then
				InviteSend.prompt()
			end
		end)
	end
	refresh()
end)

player:GetAttributeChangedSignal(A.Count):Connect(refresh)
player:GetAttributeChangedSignal(A.Granted):Connect(refresh)
player:GetAttributeChangedSignal(A.Owned):Connect(refresh)
