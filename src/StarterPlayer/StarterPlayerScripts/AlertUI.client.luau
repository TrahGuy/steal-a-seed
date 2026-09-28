--!strict
-- Steal a Seed :: AlertUI
--
-- The alarm. Taking a pod is the most dramatic thing that happens in this game
-- and it used to happen in silence -- a monster woke up somewhere behind you and
-- nothing on screen said so.
--
--==============================================================================
-- THREE LAYERS, AND THEY DO DIFFERENT JOBS
--
--   THE STINGER      one loud moment, so the danger has a beat.
--   THE WORD         "WAKING—RUN!" then "CHASED!" -- an instruction first,
--                    because a player mid-theft has no attention spare for
--                    reading. A line of text under the clock holds the same
--                    state while it lasts.
--   THE VIGNETTE     stays up for as long as a guardian is waking for you or
--                    chasing you -- not for as long as you carry: a pod in your
--                    arms with nothing after you is not a warning.
--
-- The vignette PULSES rather than sitting still, because a static red border
-- stops being visible within about two seconds -- the eye filters anything that
-- does not change. A slow throb never quite becomes wallpaper.
--
--==============================================================================
-- IT IS BUILT FROM FRAMES, NOT AN IMAGE
--
-- Four edge gradients rather than a vignette texture. No asset to upload, no
-- asset to 404, and it scales to any aspect ratio for free -- a single vignette
-- image would be stretched wrong on ultrawide and cropped on a phone.
--
--==============================================================================
-- BANKING HAS TO BE ITS OWN SIGNAL
--
-- From the client, losing a pod and banking one look identical: CarryingSpecies
-- goes nil. So the server bumps a BankedCount, and the difference between "I
-- made it" and "I was mugged" is a counter rather than a guess.
--==============================================================================

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local ATTR = GameConfig.Attributes

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DANGER = Color3.fromRGB(226, 46, 46)
local SAFE = Color3.fromRGB(126, 216, 86)
local PAPER = Color3.fromRGB(252, 250, 246)

-- Every one of these ships with the client. Verified present rather than
-- assumed: two of the ids tried alongside them load as nothing at all.
local PING = "rbxasset://sounds/electronicpingshort.wav"
local BOOM = "rbxasset://sounds/bass.mp3"

--==============================================================================
-- SOUND
--==============================================================================
local function makeSound(id: string, volume: number, pitch: number): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	-- On the Chase bus, so the settings panel's sound-effects level reaches the
	-- alarm too. These four were the only 2D sounds riding no bus at all, which
	-- made them the only ones a muted player would still hear.
	s.SoundGroup = SoundKit.group("Chase")
	-- SoundService, not the character: a 2D alert should not get quieter when
	-- the camera swings, and it must survive the character being ragdolled.
	s.Parent = SoundService
	return s
end

local sounds = {
	stinger = makeSound(BOOM, 0.55, 1.45),
	alarmLow = makeSound(PING, 0.42, 0.55),
	alarmHigh = makeSound(PING, 0.42, 0.78),
	banked = makeSound(PING, 0.5, 1.55),
}
task.spawn(function()
	local list = {}
	for _, s in pairs(sounds) do
		table.insert(list, s)
	end
	pcall(function()
		ContentProvider:PreloadAsync(list)
	end)
end)

local function alarm()
	sounds.stinger:Play()
	task.spawn(function()
		-- Two tones, alternating. One repeated note is a beep; two is an alarm.
		for i = 1, 4 do
			local s = if i % 2 == 1 then sounds.alarmLow else sounds.alarmHigh
			s:Play()
			task.wait(0.19)
		end
	end)
end

--==============================================================================
-- THE SCREEN
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SeedAlert"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = playerGui

local edges: { Frame } = {}
local THICKNESS = 0.17

local function edge(name: string, size: UDim2, pos: UDim2, rotation: number)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = DANGER
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ZIndex = 1
	f.Parent = gui

	local grad = Instance.new("UIGradient")
	grad.Rotation = rotation
	-- Opaque at the screen edge, gone by the time it reaches the middle. The
	-- transparency ramp does the work; the frame's own transparency scales the
	-- whole thing when it pulses.
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	grad.Parent = f
	table.insert(edges, f)
	return f
end

edge("Top", UDim2.fromScale(1, THICKNESS), UDim2.fromScale(0, 0), 90)
edge("Bottom", UDim2.fromScale(1, THICKNESS), UDim2.fromScale(0, 1 - THICKNESS), 270)
edge("Left", UDim2.fromScale(THICKNESS * 0.62, 1), UDim2.fromScale(0, 0), 0)
edge("Right", UDim2.fromScale(THICKNESS * 0.62, 1),
	UDim2.fromScale(1 - THICKNESS * 0.62, 0), 180)

local word = Instance.new("TextLabel")
word.Name = "Word"
word.AnchorPoint = Vector2.new(0.5, 0.5)
word.Position = UDim2.fromScale(0.5, 0.32)
word.Size = UDim2.fromScale(0.6, 0.16)
word.BackgroundTransparency = 1
word.Font = Enum.Font.GothamBlack
word.TextScaled = true
word.TextColor3 = PAPER
word.TextTransparency = 1
word.ZIndex = 3
word.Parent = gui

local wordStroke = Instance.new("UIStroke")
wordStroke.Thickness = 4
wordStroke.Color = Color3.fromRGB(24, 12, 12)
wordStroke.Transparency = 1
wordStroke.Parent = word

--==============================================================================
-- STATE
--==============================================================================
local pulse = 0
local intensity = 0
local targetIntensity = 0

local function say(text: string, colour: Color3, hold: number)
	word.Text = text
	word.TextColor3 = colour
	word.Size = UDim2.fromScale(0.85, 0.23)
	word.TextTransparency = 0
	wordStroke.Transparency = 0

	TweenService:Create(word, TweenInfo.new(0.22, Enum.EasingStyle.Back,
		Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.6, 0.16) }):Play()

	task.delay(hold, function()
		if word.Text ~= text then
			-- Something else has already claimed the label. Leave it alone.
			return
		end
		TweenService:Create(word, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(wordStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
end

RunService.RenderStepped:Connect(function(dt)
	intensity += (targetIntensity - intensity) * math.min(1, dt * 6)
	if intensity < 0.002 and targetIntensity == 0 then
		if edges[1].BackgroundTransparency < 1 then
			for _, f in ipairs(edges) do
				f.BackgroundTransparency = 1
			end
		end
		return
	end
	pulse += dt
	-- A slow throb. Static red stops registering within a couple of seconds
	-- because the eye filters anything that does not change.
	local throb = 0.78 + 0.22 * math.sin(pulse * 4.2)
	local alpha = intensity * throb
	for _, f in ipairs(edges) do
		f.BackgroundTransparency = 1 - alpha * 0.62
	end
end)

--==============================================================================
-- THE WARNING RIDES THE GUARDIAN, NOT THE POD (2026-09-27)
--
-- It used to ride CARRYING: the vignette, the RUN word and the alarm went up
-- the instant a pod was in your arms, whether anything was after you or not.
-- Now it reads the guardians' own state, which NestService publishes on this
-- player as two counts:
--
--   WakingBy    guardians in their wake delay with you as the target -- the
--               head start. "WAKING -- RUN!"
--   PursuedBy   guardians in the chasing state with you as the target.
--               "CHASED!"
--
-- Carrying a pod on its own shows nothing. A theft from a sleeping nest shows
-- WAKING for exactly the delay and then CHASED; a theft from a guardian that is
-- already up goes straight to CHASED.
--
-- COUNTS, SO GUARDIANS ADD UP. Two after you are one warning, and the first one
-- giving up does not end it -- both counts reaching nil does, and only after
-- they have stayed there for ChaseHoldSeconds, which rides a retarget or a
-- catch landing a tick before the next guardian counts. CHASED outranks WAKING:
-- one guardian running at you and another still standing up is a chase.
--
-- TWO PIECES, NOT A SECOND OVERLAY. The big word is the moment -- it pops on
-- the way in and fades like it always has, because a word that size held for a
-- whole run home would cover the road you are running down. The line under
-- the clock is the state: it says WAKING or CHASED for as long as that is true
-- and goes when it stops.
--
-- THE LINE IS TEXT, NOT A PILL (2026-09-27). Warm red in the HUD's display
-- face, with the notices' dark outline and their warning glyph -- no plate, no
-- capsule, no border (StatusText). In on a short rise and settle; steady for as
-- long as it lasts; a small nudge when WAKING turns to CHASED; a fade when it
-- ends. Nothing on it pulses: the vignette at the edges is what keeps moving.
--
-- IT STANDS IN HudLayout's STATUS BAND: the TELEPORT TO PLOT slot, centred
-- under the clock, which is empty wherever a guardian can chase -- the button
-- only shows in the Safe Zone. Inside the Safe Zone the line stands down, since
-- the chase is already over there; that covers the second a chase takes to let
-- go after the red line, when the button comes up in the same slot. The boost
-- row has its own band below (BonusChestUI), so neither moves the other.
--
-- THE BIG WORD STAYS OUT OF THE COLUMN. At 32% of the height it is far below
-- the clock, the line and the boost row on a desktop, and nothing changes
-- there; on a phone 32% reaches up into them, so it stands under the boost
-- row instead, for the second it is up.
--==============================================================================
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local StatusText = require(Shared:WaitForChild("StatusText"))

local WAKING_TEXT = "WAKING—RUN!"
local CHASED_TEXT = "CHASED!"

local status = StatusText.new({
	name = "ChaseStatus",
	parent = gui,
	size = StatusText.Size.status,
	tint = StatusText.Danger,
	icon = "warning",
	zIndex = 4,
})

-- The big word's resting centre and its popped height, as shares of the window.
local WORD_CENTRE = 0.32
local WORD_POP_HEIGHT = 0.23

local function placeStatus()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local layout = HudLayout.solve(input)
	local inset = input.insetTop or 0
	status.setScale(if layout.compact or layout.sidebar then StatusText.SmallScale.status else 1)
	local band, _, boosts = HudLayout.statusRows(layout, inset)
	local size = status.size()
	local r = HudLayout.centreIn(layout, band, size.X)
	status.frame.Position = UDim2.new(0.5, math.round(r.x + r.w / 2 - layout.safe.X / 2),
		0, math.round(r.y + (r.h - size.Y) / 2 + inset))
	local height = gui.AbsoluteSize.Y
	local under = boosts.y + boosts.h + inset + 8 + height * WORD_POP_HEIGHT / 2
	word.Position = UDim2.new(0.5, 0, 0, math.round(math.max(height * WORD_CENTRE, under)))
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeStatus)
-- The slot stands under the clock, which moves with the topbar's free span.
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeStatus)
placeStatus()

local function inSafeZone(): boolean
	return player:GetAttribute(ATTR.InSafeZone) == true
end

-- "none", "waking" or "chased", as last shown.
local danger = "none"
local dangerHold = 0

local function readDanger(): string
	local chasing = player:GetAttribute(ATTR.PursuedBy)
	if type(chasing) == "number" and chasing > 0 then
		return "chased"
	end
	local waking = player:GetAttribute(ATTR.WakingBy)
	if type(waking) == "number" and waking > 0 then
		return "waking"
	end
	return "none"
end

local function showDanger(state: string)
	local was = danger
	danger = state
	if state == "none" then
		targetIntensity = 0
		status.hide()
		return
	end
	local text = if state == "chased" then CHASED_TEXT else WAKING_TEXT
	targetIntensity = 1
	for _, f in ipairs(edges) do
		f.BackgroundColor3 = DANGER
	end
	status.set(text)
	placeStatus()
	if not inSafeZone() then
		status.show()
	end
	if was ~= "none" and was ~= state then
		status.nudge()
	end
	if was == "none" then
		-- Snap to full rather than easing in: the alarm is the moment, and an
		-- alarm that fades up has already missed it.
		intensity = 1
		say(text, PAPER, if state == "waking" then GameConfig.Parent.WakeDelaySeconds else 1.0)
		alarm()
	elseif was ~= state then
		-- Waking -> chased is the same danger getting worse: a new word, and the
		-- alarm that already sounded does not sound again.
		say(text, PAPER, 1.0)
	end
end

local function onDangerChanged()
	local state = readDanger()
	dangerHold += 1
	if state ~= "none" then
		if state ~= danger then
			showDanger(state)
		end
		return
	end
	if danger == "none" then
		return
	end
	local token = dangerHold
	task.delay(GameConfig.Sfx.ChaseHoldSeconds, function()
		if token == dangerHold and readDanger() == "none" then
			showDanger("none")
		end
	end)
end

player:GetAttributeChangedSignal(ATTR.PursuedBy):Connect(onDangerChanged)
player:GetAttributeChangedSignal(ATTR.WakingBy):Connect(onDangerChanged)
-- The line only, and only its visibility: the counts, the hold, the vignette
-- and the music are exactly what they were. Gone in the same frame, not on
-- its fade: TELEPORT TO PLOT comes up in this slot on this very change
-- (measured in Play 2026-09-27: a fade left the warning over the button for
-- a third of a second).
player:GetAttributeChangedSignal(ATTR.InSafeZone):Connect(function()
	if danger ~= "none" and not inSafeZone() then
		status.show()
	else
		status.hide(true)
	end
end)

player:GetAttributeChangedSignal(ATTR.BankedCount):Connect(function()
	-- Fires just before or after CarryingSpecies clears, depending on ordering,
	-- so it sets its own word rather than assuming the carry handler ran first.
	targetIntensity = 0
	for _, f in ipairs(edges) do
		f.BackgroundColor3 = SAFE
	end
	say("SAFE", SAFE, 0.7)
	--==========================================================================
	-- THE STOCK PING IS THE FALLBACK, NOT THE LEFTOVER
	--
	-- Banked is the payoff for a whole run home and it deserves its own sound.
	-- Until an id is pasted into GameConfig.Sfx.Cues.Banked there is not one, and
	-- a silent bank would be a REGRESSION from the pitched-up engine ping this
	-- has always used. So the ping stands in, and stands down the moment there
	-- is something better -- which is why this is the one cue in the game with a
	-- fallback rather than silence.
	--==========================================================================
	if not SoundKit.play("Banked") then
		sounds.banked:Play()
	end
end)

--==============================================================================
-- THE CHASE BED RIDES THE PURSUIT, NOT THE CARRY
--
-- It used to ride CARRYING, because nothing told the client who a guardian was
-- after -- and that was wrong both ways. A guardian that gave up at its leash
-- left the drums running all the way home; one still running at a player whose
-- pod had been knocked away went quiet mid-chase; a second thief retargeting
-- the parent left the first one scored for a chase that had moved on. The
-- music is the chase, and NestService now says when there is one: PursuedBy,
-- on this player, is how many guardians are running at them. (Since 2026-09-27
-- the vignette, the word and the alarm ride the guardians too -- see THE
-- WARNING RIDES THE GUARDIAN above -- so nothing here reads the carry.)
--
-- ONE BED FOR ANY NUMBER OF GUARDIANS. The count does the aggregating, so two
-- parents after you are one track, and the first one giving up does not end
-- it -- the count reaching nil does.
--
-- THE HOLD. Nil has to stay nil for ChaseHoldSeconds before the bed lets go,
-- which rides a retarget or a catch that lands while the next guardian is a
-- tick from counting. Any change inside the hold cancels it. Escape, catch,
-- death and a guardian giving up all arrive here the same way: the server
-- stops counting, and the bed fades rather than cuts (SoundKit.chase).
--
-- SoundKit.chase is still called from this one place. It ducks the garden bed
-- while it runs because they are one decision -- two calls is how the bed ends
-- up ducked with no chase running, which is a game gone quiet for no reason.
--==============================================================================
local chaseOn = false
local chaseHold = 0

local function onPursuitChanged()
	local count = player:GetAttribute(ATTR.PursuedBy)
	local pursued = type(count) == "number" and count > 0
	chaseHold += 1
	if pursued then
		if not chaseOn then
			chaseOn = true
			SoundKit.chase(true)
		end
		return
	end
	if not chaseOn then
		return
	end
	local token = chaseHold
	task.delay(GameConfig.Sfx.ChaseHoldSeconds, function()
		if token == chaseHold and chaseOn then
			chaseOn = false
			SoundKit.chase(false)
		end
	end)
end

player:GetAttributeChangedSignal(ATTR.PursuedBy):Connect(onPursuitChanged)

-- A respawn can end a chase without the counts arriving in any particular
-- order, so resync rather than trusting the last thing seen.
player.CharacterAdded:Connect(function()
	task.defer(onDangerChanged)
	task.defer(onPursuitChanged)
end)

onDangerChanged()
onPursuitChanged()
