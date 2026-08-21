--!strict
-- Steal a Seed :: CashUI
--
-- One number. This is not the HUD -- it is the proof that Phase A closes: steal
-- a pod, run it home, plant it, and watch a number go up because of it.
--
--==============================================================================
-- NO NEW REMOTE
--
-- PlayerDataService already pushes the whole profile down ProfileUpdated,
-- coalesced at four times a second, and announces the first one on
-- ProfileReady. So this listens to what is already there and draws
-- profile.Cash. A second remote carrying the same field is a second thing to
-- keep in step with the first.
--
--==============================================================================
-- IT DOES NOT SHOW ZERO UNTIL IT HAS BEEN TOLD
--
-- The dash matters. "0" and "we have not heard from the server yet" are
-- different facts, and rendering the second as the first is how a player with a
-- real balance is shown an empty wallet during a slow DataStore call -- which
-- looks exactly like being robbed. GameConfig says as much where ProfileReady
-- is declared; this is that warning obeyed.
--
--==============================================================================
-- IT COUNTS UP RATHER THAN STEPPING
--
-- Cash arrives in 0.25s batches, so the raw value moves in visible jumps. The
-- label eases toward it instead, which reads as EARNING rather than as a number
-- being overwritten -- and at 2 cash a second the difference between those two
-- is the whole feeling of the thing.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- The same vocabulary as PromptUI and PlantUI.
local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local ACCENT = Color3.fromRGB(142, 196, 62)

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedCash")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedCash"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = playerGui

-- Top-left, clear of the Roblox chrome. Sized in SCALE with a minimum, so it is
-- readable on a phone without being a billboard on a monitor.
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.new(0, 12, 0, 12)
panel.Size = UDim2.new(0.26, 0, 0.075, 0)
panel.BackgroundColor3 = INK
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui

local minSize = Instance.new("UISizeConstraint")
minSize.MinSize = Vector2.new(150, 44)
minSize.MaxSize = Vector2.new(340, 86)
minSize.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = ACCENT
stroke.Thickness = 2
stroke.Transparency = 0.35
stroke.Parent = panel

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)
pad.Parent = panel

local amount = Instance.new("TextLabel")
amount.Name = "Amount"
amount.Size = UDim2.fromScale(1, 1)
amount.BackgroundTransparency = 1
amount.Font = Enum.Font.GothamBlack
amount.TextScaled = true
amount.TextColor3 = PAPER
amount.TextXAlignment = Enum.TextXAlignment.Left
amount.Text = "—"
amount.Parent = panel

--==============================================================================
-- FORMATTING
--==============================================================================
local function commas(n: number): string
	local whole = string.format("%d", math.floor(n))
	local out = whole
	local count
	repeat
		out, count = string.gsub(out, "^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return out
end

--==============================================================================
-- STATE
--==============================================================================
local target: number? = nil
local shown = 0

local function receive(profile: any)
	if type(profile) ~= "table" or type(profile.Cash) ~= "number" then
		return
	end
	if target == nil then
		-- First word from the server: land on it rather than counting up from
		-- zero, or a returning player watches their whole balance tick in.
		shown = profile.Cash
	end
	target = profile.Cash
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	local updated = remotes:FindFirstChild(GameConfig.Remotes.ProfileUpdated)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	end
	local ready = remotes:FindFirstChild(GameConfig.Remotes.ProfileReady)
	if ready and ready:IsA("RemoteEvent") then
		-- (ok, profile, persistent) -- the same shape PlayerDataService fires.
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
end

RunService.RenderStepped:Connect(function(dt)
	local want = target
	if want == nil then
		return
	end
	-- Ease, but never fall behind: if the gap is large the catch-up is quick,
	-- and the last fraction of a cash unit is snapped so the label cannot sit
	-- forever one short of the truth.
	local gap = want - shown
	if math.abs(gap) < 0.5 then
		shown = want
	else
		shown += gap * math.min(1, dt * 6)
	end
	local text = commas(shown)
	if amount.Text ~= text then
		amount.Text = text
	end
end)
