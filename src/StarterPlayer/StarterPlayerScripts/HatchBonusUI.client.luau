--!strict
-- Steal a Seed :: HatchBonusUI
--
-- THE HATCH BONUS'S NOTICE, AND THE LIKE REMINDER (2026-10-01, the owner's
-- brief; GameConfig.HatchBonus)
--
-- Nothing here grants, counts or decides anything: the server gave the spin
-- (WheelService.GrantHatchBonus) before this hears a word of it. This only
-- says so, at the right moment, and then asks -- once -- for a like that
-- nothing detects and nothing pays for.
--
--==============================================================================
-- 1. THE BONUS'S NOTICE, AFTER THE HATCH HAS FINISHED SHOWING ITSELF
--
-- WheelService sends WheelData.Actions.HatchBonus { label, revealAt } the
-- moment the bonus is given, which is the moment of the hatch. The plant is
-- not shown until `revealAt` (the silhouette roll), then rises, is named and
-- fades (GameConfig.Plant.Hatch.Reveal and .Label); a beginner's first hatch
-- then gets the guide's congratulations (TutorialUI's Celebration), which
-- start a moment after the plant is shown. So this waits for the reveal's
-- end and a beat, then for the congratulations to have gone, and a beat; and
-- only then posts one success notice -- FIRST HATCH BONUS! or WELCOME BACK
-- BONUS!, "You earned 1 free wheel spin." -- in the game's own notice stack.
--
-- 2. THE REMINDER, ONCE THAT AND THE GUIDE HAVE GONE
--
-- When the bonus's notice has left, and no guide message (its congratulations
-- or its instruction) and no other notice is up, and no panel is open: a
-- small notice the player can dismiss -- "Enjoying Podnappers? Leave us a
-- like!" -- for Reminder.Seconds. Once it has stood Reminder.ShownAfter
-- seconds, or was dismissed sooner, this tells the server it was shown, and
-- the saved state goes from "pending" to "shown". Nothing else happens either
-- way: the spin was the player's before the reminder ever came up.
--
-- 3. A REMINDER LEFT PENDING BY AN EARLIER VISIT
--
-- The LikeReminder attribute (the saved state, stamped by PlayerDataService)
-- says "pending" when this player left after the bonus and before the
-- reminder. It then waits Reminder.CalmSeconds after the body arrives, and for
-- a calm moment -- in the Safe Zone, alive, no pod in the arms, no panel, no
-- guide message, no notice -- and shows it there. Never twice in a session.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local Notice = require(Shared:WaitForChild("Notice"))
local PadInput = require(Shared:WaitForChild("PadInput"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BONUS = GameConfig.HatchBonus
local REMIND = BONUS.Reminder
local HATCH = GameConfig.Plant.Hatch
local ATTR = GameConfig.Attributes

-- How long after `revealAt` the plant's own reveal is over: its rise, its
-- label's stay and the label's fade.
local REVEAL_SECONDS = HATCH.Reveal.Seconds + HATCH.Label.Seconds + HATCH.Label.FadeSeconds

local channel: RemoteEvent? = nil
local alive = true
-- One reminder a session: "idle", then "busy" while a flow is getting it up,
-- then "done" once it has been reported shown.
local reminder = "idle"
-- When the bonus's own flow began, so the attribute's change that comes with
-- it is not mistaken for a reminder left over from an earlier visit.
local bonusAt = -math.huge

--==============================================================================
-- WHAT IS ON THE SCREEN
--==============================================================================
-- How long the guide's INSTRUCTION banner may hold the reminder back: the hint
-- after a first hatch ("Plant it...") stands 45 s at most. A guide left
-- unfinished keeps its banner up for good, and HudLayout keeps the notices
-- clear of the guide's words, so past this the reminder may share the screen.
local INSTRUCTION_WAIT = 60

local function guidePanel(name: string): boolean
	local guide = playerGui:FindFirstChild("SeedBeginnerGuide")
	if not (guide and guide:IsA("ScreenGui") and guide.Enabled) then
		return false
	end
	local frame = guide:FindFirstChild(name, true)
	return frame ~= nil and frame:IsA("GuiObject") and frame.Visible
end

local function celebrating(): boolean
	return guidePanel("Celebration")
end

-- A guide message is up: its congratulations, or its instruction for less
-- than INSTRUCTION_WAIT since `since`.
local function guideUp(since: number): boolean
	return celebrating() or (guidePanel("Instruction") and os.clock() - since < INSTRUCTION_WAIT)
end

-- The notices on screen, by headline: ActionToastUI's own stack.
local function noticeUp(title: string?): boolean
	local toast = playerGui:FindFirstChild("SeedToast")
	local stack = toast and toast:FindFirstChild("Stack")
	if not stack then
		return false
	end
	for _, frame in ipairs(stack:GetChildren()) do
		if frame.Name == "Notice" then
			if title == nil then
				return true
			end
			local label = frame:FindFirstChild("Title", true)
			if label and label:IsA("TextLabel") and label.Text == title then
				return true
			end
		end
	end
	return false
end

local function bodyOk(): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return humanoid ~= nil and humanoid.Health > 0
end

local function calm(strict: boolean, since: number): boolean
	if PadInput.panelOpen() or guideUp(since) or noticeUp(nil) or not bodyOk() then
		return false
	end
	if strict then
		return player:GetAttribute(ATTR.InSafeZone) == true
			and player:GetAttribute(ATTR.CarryingSpecies) == nil
	end
	return true
end

local function waitUntil(test: () -> boolean, every: number)
	while alive and not test() do
		task.wait(every)
	end
end

--==============================================================================
-- THE REMINDER
--==============================================================================
local function report()
	local remote = channel
	if reminder ~= "done" and remote then
		reminder = "done"
		remote:FireServer(REMIND.Action)
	end
end

-- Puts it up; reports it once it has stood ShownAfter seconds, or at once if
-- it is dismissed sooner. Answers whether it was reported -- a reminder pushed
-- off the screen before it had stood its time is tried again later.
local function showReminder(): boolean
	local dismissed = false
	Notice.post({
		kind = "info",
		title = REMIND.Title,
		detail = REMIND.Detail,
		key = "LikeReminder",
		seconds = REMIND.Seconds,
		dismissible = true,
		onDismissed = function()
			dismissed = true
			report()
		end,
	})
	local waited = 0
	while alive and waited < REMIND.ShownAfter and not dismissed do
		task.wait(0.25)
		waited += 0.25
	end
	if dismissed or reminder == "done" then
		return true
	end
	if noticeUp(REMIND.Title) then
		report()
		return true
	end
	return false
end

local function remindWhenCalm(strict: boolean)
	if reminder ~= "idle" then
		return
	end
	reminder = "busy"
	while alive and player:GetAttribute(ATTR.LikeReminder) == "pending" do
		local since = os.clock()
		waitUntil(function()
			return calm(strict, since)
		end, 1)
		if not alive or player:GetAttribute(ATTR.LikeReminder) ~= "pending" then
			break
		end
		if showReminder() then
			return
		end
		task.wait(5)
	end
	if reminder == "busy" then
		reminder = "idle"
	end
end

--==============================================================================
-- THE BONUS
--==============================================================================
local function onBonus(payload: any)
	if type(payload) ~= "table" then
		return
	end
	bonusAt = os.clock()
	local label = if payload.label == "first" then BONUS.FirstTitle else BONUS.WelcomeTitle
	local revealAt = if type(payload.revealAt) == "number" then payload.revealAt else Workspace:GetServerTimeNow()

	-- The roll, the plant's reveal, and a beat.
	local untilReveal = revealAt + REVEAL_SECONDS - Workspace:GetServerTimeNow()
	task.wait(math.max(0, untilReveal) + BONUS.BeatSeconds)
	-- The guide's congratulations, which begin a moment after the plant shows,
	-- and a beat after them.
	if celebrating() then
		waitUntil(function()
			return not celebrating()
		end, 0.2)
		task.wait(BONUS.BeatSeconds)
	end
	if not alive then
		return
	end
	local post: Notice.Post = { kind = "success", title = label, detail = BONUS.Detail, key = "HatchBonus" }
	Notice.post(post)

	-- Then the reminder, once that notice has left and the screen is calm.
	task.wait(Notice.lifeOf(post) + Notice.ExitSeconds + BONUS.BeatSeconds)
	remindWhenCalm(false)
end

--==============================================================================
-- A REMINDER FROM AN EARLIER VISIT
--==============================================================================
local function pendingFromBefore()
	if player:GetAttribute(ATTR.LikeReminder) ~= "pending" or reminder ~= "idle" then
		return
	end
	-- The bonus given just now raises this too; its own flow shows the reminder.
	task.wait(2)
	if os.clock() - bonusAt < 30 or reminder ~= "idle" then
		return
	end
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	task.wait(REMIND.CalmSeconds)
	remindWhenCalm(true)
end

--==============================================================================
-- WIRING
--==============================================================================
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if not (found and found:IsA("RemoteEvent")) then
		warn("[Seed/HatchBonusUI] No GameEvent remote; the hatch bonus's notice cannot be shown.")
		return
	end
	channel = found
	found.OnClientEvent:Connect(function(action: any, payload: any)
		if action == WheelData.Actions.HatchBonus then
			task.spawn(onBonus, payload)
		end
	end)
	task.spawn(pendingFromBefore)
	player:GetAttributeChangedSignal(ATTR.LikeReminder):Connect(function()
		task.spawn(pendingFromBefore)
	end)
end)

script.Destroying:Connect(function()
	alive = false
end)
