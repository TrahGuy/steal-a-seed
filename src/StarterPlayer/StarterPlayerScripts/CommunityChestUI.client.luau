--!strict
-- Steal a Seed :: CommunityChestUI
--
-- THE COMMUNITY CHEST, AS THIS PLAYER SEES IT (2026-10-01, the owner's brief;
-- GameConfig.Community)
--
--   * THE WORDS over the chest: a rainbow FREE in the wheel sign's own font and
--     outline (FloatingSign, with the wheel sign's rainbow laid over it here),
--     "JOIN COMMUNITY · 5 FREE SPINS" under it. Once this player's profile has
--     claimed (the CommunityClaimed attribute), their own copy says CLAIMED and
--     the circle dims -- for them alone.
--   * THE CIRCLE: standing on it asks the server first (CheckAction, carrying
--     nothing), ONCE per visit -- nothing more while the body stays on it,
--     another try after stepping off and back. A member is granted without a
--     dialog. Only when the server answers "join" does Roblox's own join
--     prompt open (GroupService:PromptJoinAsync); when it closes, whatever it
--     said, the server checks again (CheckAction, "verify"). It decides from
--     Roblox's own answer and says how it went (ResultAction).
--   * THE TICKETS: holding the Spin Ticket says where it is used.
--
-- Nothing here grants anything; the client's word about the prompt is never
-- read by the server.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GroupService = game:GetService("GroupService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local Notice = require(Shared:WaitForChild("Notice"))

local player = Players.LocalPlayer
local COMMUNITY = GameConfig.Community
local alive = true

local channel: RemoteEvent? = nil
local sign: FloatingSign.Sign? = nil
local pad: BasePart? = nil
local rim: BasePart? = nil
local rainbow: UIGradient? = nil
-- FREE's glow, and the rainbow on its edge (2026-10-01).
local glow: TextLabel? = nil
local glowRainbow: UIGradient? = nil
-- The wheel sign drifts one pass in 14 s; the owner asked for about twice that.
local DRIFT_SECONDS = 7
-- The glow's edge in pixels, outside the 2.5 dark outline, and how clear it is.
local GLOW_THICKNESS = 7
local GLOW_TRANSPARENCY = 0.45

-- The wheel sign's rainbow (WheelModel, THE SIGN), stop for stop.
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 92, 92)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 176, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 232, 80)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(110, 220, 110)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(90, 176, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 120, 255)),
})
local WHITE = Color3.fromRGB(255, 255, 255)
local CLAIMED_GOLD = Color3.fromRGB(255, 214, 110)

local function claimed(): boolean
	return player:GetAttribute(COMMUNITY.ClaimedAttribute) == true
end

--==============================================================================
-- THE WORDS AND THE CIRCLE, IN THIS PLAYER'S STATE
--==============================================================================
local function paint()
	local s = sign
	if not s then
		return
	end
	local done = claimed()
	s.words.Text = if done then COMMUNITY.ClaimedTitle else COMMUNITY.Title
	s.words.TextColor3 = if done then CLAIMED_GOLD else WHITE
	local r = rainbow
	if r then
		r.Enabled = not done
	end
	local halo = glow
	if halo then
		halo.Visible = not done
	end
	local sub = s.sub
	if sub then
		sub.Text = if done then COMMUNITY.ClaimedSub else COMMUNITY.Sub
	end
	local p = pad
	if p then
		p.Transparency = if done then 0.75 else 0
		local light = p:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = not done
		end
	end
	local edge = rim
	if edge then
		edge.Transparency = if done then 0.9 else 0.45
	end
	s.setShown(true)
end

task.spawn(function()
	local folder = Workspace:WaitForChild(COMMUNITY.FolderName, 60)
	local model = folder and folder:WaitForChild("CommunityChest", 30)
	if not (model and model:IsA("Model")) or not alive then
		return
	end
	local found = model:WaitForChild("StepPad", 30)
	pad = if found and found:IsA("BasePart") then found else nil
	local edge = model:FindFirstChild("StepRim")
	rim = if edge and edge:IsA("BasePart") then edge else nil
	local at = model:GetPivot().Position
	local made = FloatingSign.new({
		name = "CommunityWords",
		parent = model,
		at = CFrame.new(at.X, COMMUNITY.Position.Y + COMMUNITY.SignAbove, at.Z),
		text = COMMUNITY.Title,
		colour = WHITE,
		width = COMMUNITY.SignWidth,
		height = COMMUNITY.SignHeight,
		subText = COMMUNITY.Sub,
		subHeight = COMMUNITY.SignSubHeight,
	})
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Rainbow"
	gradient.Color = RAINBOW
	gradient.Parent = made.words
	rainbow = gradient
	--==========================================================================
	-- THE GLOW (the owner, 2026-10-01): a copy of FREE just behind it, whose
	-- wide, half-clear edge carries the same rainbow -- the real letters and
	-- their dark outline sit on top, so a band of coloured light shows round
	-- them. The headline only: the line under it is untouched.
	--==========================================================================
	local halo = Instance.new("TextLabel")
	halo.Name = "Glow"
	halo.BackgroundTransparency = 1
	halo.Position = made.words.Position
	halo.Size = made.words.Size
	halo.Font = made.words.Font
	halo.TextScaled = true
	halo.Text = made.words.Text
	halo.TextColor3 = WHITE
	halo.ZIndex = 1
	made.words.ZIndex = 2
	local haloEdge = Instance.new("UIStroke")
	haloEdge.Color = WHITE
	haloEdge.Thickness = GLOW_THICKNESS
	haloEdge.Transparency = GLOW_TRANSPARENCY
	local haloRainbow = gradient:Clone()
	haloRainbow.Parent = haloEdge
	haloEdge.Parent = halo
	halo.Parent = made.gui
	glow, glowRainbow = halo, haloRainbow
	sign = made
	paint()
end)
player:GetAttributeChangedSignal(COMMUNITY.ClaimedAttribute):Connect(paint)

--==============================================================================
-- THE RAINBOW MOVES: the wheel sign's own drift (WheelUI), twice as fast
--
-- The same stops slid across the letters, one pass every DRIFT_SECONDS where
-- the wheel's takes 14, the fill and the glow together. Smooth steps while
-- this camera is near enough to draw the sign, a look once a second
-- otherwise, still while claimed, and still for a player who turned motion
-- off. No flashing: a colour only ever slides into its neighbour.
--==============================================================================
task.spawn(function()
	local drift = 0
	local last = os.clock()
	while alive do
		local s, g, camera = sign, rainbow, Workspace.CurrentCamera
		local near = s ~= nil and g ~= nil and g.Enabled and camera ~= nil
			and player:GetAttribute("SeedAfterimageQuality") ~= "Off"
			and (camera.CFrame.Position - s.anchor.Position).Magnitude <= FloatingSign.Distance
		local now = os.clock()
		if near and g then
			-- Capped, so coming back into view or unclaimed never jumps the colours.
			drift = (drift + math.min(now - last, 0.1) / DRIFT_SECONDS) % 1
			local offset = Vector2.new(drift * 2 - 1, 0)
			g.Offset = offset
			local edge = glowRainbow
			if edge then
				edge.Offset = offset
			end
		end
		last = now
		task.wait(if near then 1 / 30 else 1)
	end
end)

--==============================================================================
-- THE CIRCLE: one prompt per visit
--==============================================================================
local inFlight = false
local armed = true
local lastPrompt: string = ""

local function onCircle(): boolean
	local p = pad
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (p and root and root:IsA("BasePart")) then
		return false
	end
	local d = root.Position - p.Position
	return Vector2.new(d.X, d.Z).Magnitude <= COMMUNITY.PadRadius and d.Y >= -1 and d.Y <= COMMUNITY.PadReach
end

-- One question to the server; inFlight holds until its answer (ResultAction)
-- arrives, and the circle stays spent until the body has stepped off it.
local function send(stage: string?)
	local remote = channel
	if not remote then
		inFlight = false
		return
	end
	inFlight = true
	remote:FireServer(COMMUNITY.CheckAction, stage)
end

-- The server found no membership: Roblox's own prompt, then its verify.
local function promptJoin()
	local ok, result = pcall(function()
		return GroupService:PromptJoinAsync(COMMUNITY.GroupId)
	end)
	lastPrompt = if ok then tostring(result) else "failed"
	send("verify")
end

task.spawn(function()
	while alive do
		task.wait(0.15)
		local on = onCircle()
		if not on then
			if not inFlight then
				armed = true
			end
		elseif armed and not inFlight and not claimed() then
			armed = false
			lastPrompt = ""
			send(nil)
		end
	end
end)

--==============================================================================
-- WHAT THE SERVER SAID
--==============================================================================
local function onResult(payload: any)
	local outcome = type(payload) == "table" and payload.outcome or nil
	if outcome == "join" then
		task.spawn(promptJoin)
		return
	end
	inFlight = false
	if outcome == "claimed" then
		paint()
	elseif outcome == "granted" then
		Notice.post({ kind = "success", title = COMMUNITY.ClaimedNotice.Title,
			detail = COMMUNITY.ClaimedNotice.Detail, key = "CommunityClaimed" })
	elseif outcome == "notmember" then
		-- A cancelled prompt says nothing; a join Roblox has not shown yet, or a
		-- request waiting for approval, says when to try again.
		if string.find(lastPrompt, "Pending", 1, true) then
			Notice.post({ kind = "info", title = "JOIN REQUEST SENT", detail = "Step on the circle again once you're in." })
		elseif string.find(lastPrompt, "Joined", 1, true) or string.find(lastPrompt, "Member", 1, true) then
			Notice.post({ kind = "info", title = "NOT CONFIRMED YET", detail = "Step on the circle again in a moment." })
		end
	elseif outcome == "retry" or outcome == "wait" or outcome == "unavailable" then
		Notice.post({ kind = "info", title = "COULDN'T CHECK RIGHT NOW", detail = "Step on the circle again in a moment." })
	elseif outcome == "save" then
		Notice.post({ kind = "warning", title = "COULDN'T SAVE YOUR REWARD", detail = "Step on the circle again to retry." })
	elseif outcome == "full" then
		Notice.post({ kind = "info", title = "SPIN TICKETS FULL", detail = "Use some at the Spin Wheel first." })
	end
end

--==============================================================================
-- HOLDING A SPIN TICKET
--==============================================================================
local function watchBody(character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("SpinTicket") == true then
			Notice.post({ kind = "info", title = string.upper(COMMUNITY.TicketName), detail = COMMUNITY.TicketHint,
				key = "SpinTicketHint" })
		end
	end)
end
player.CharacterAdded:Connect(watchBody)
if player.Character then
	watchBody(player.Character)
end

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if not (found and found:IsA("RemoteEvent")) then
		warn("[Seed/CommunityChestUI] No GameEvent remote; the community chest cannot be claimed.")
		return
	end
	channel = found
	found.OnClientEvent:Connect(function(action: any, payload: any)
		if action == COMMUNITY.ResultAction then
			onResult(payload)
		end
	end)
end)

script.Destroying:Connect(function()
	alive = false
	local s = sign
	if s then
		s.destroy()
	end
end)
