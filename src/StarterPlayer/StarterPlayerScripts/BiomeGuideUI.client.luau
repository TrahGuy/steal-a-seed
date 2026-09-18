--!strict
-- Steal a Seed :: BiomeGuideUI
--
-- The biome's name, briefly, when the server sees this player cross into it.
--
--==============================================================================
-- THE NAME AND NOTHING ELSE
--
-- This used to be a 520 px card: a gradient plate, an accent stripe, the name
-- with the biome's mood beside it, a RECOMMENDED SPEED line and an ADVISORY ONLY
-- footnote. The owner cut it to the one fact a player needs on the way in --
-- where they are -- on 2026-09-18. The Speed numbers still live on the arches at
-- every biome boundary; they are not repeated here, and NOTHING REPLACES THEM
-- here either. If this notice ever grows a second line, that is a design change
-- somebody has to ask for, not a gap somebody has filled.
--
-- NO PLATE. Bare outlined text in the HUD's own face -- LuckiestGuy on a black
-- UIStroke, which is exactly what the Cash and Speed readout is, through the same
-- UIKit.outlined helper -- so it reads as part of the same screen rather than as a
-- popup laid over it. The outline is what keeps it legible on Dustbowl's sand and
-- Tanglemire's mud alike, and it is kept at the readout's proportion (1.5 px on
-- 24 px text, where the Speed line is 2 on 39) so a notice never out-shouts the
-- numbers.
--
--==============================================================================
-- WHERE IT SITS, AND WHAT IT HAS TO MISS
--
-- Top-centre, 50 px down from the very top of the window (IgnoreGuiInset, like
-- the world clock and the alarm), in the band between them:
--
--     world clock plate      8 ..  42   absolute, when it is showing
--     THIS                  50 ..  80
--     tutorial banner      inset + 84 and down  (142 on a 58 px desktop topbar)
--     RUN! alarm           centred at 32% of the height, so never above ~146
--
-- Far above the character, who is in the middle of the screen, and nowhere near
-- the corners -- the cash readout and the joystick bottom-left, the jump button
-- bottom-right, the hotbar bottom-centre, the rail top-left and top-right.
--
-- THE TUTORIAL NO LONGER STEPS ASIDE FOR IT. TutorialUI hides its own banner
-- while this GUI holds a visible Frame, because the old card and the banner
-- shared the top of the screen. There is no Frame now -- the notice is a single
-- TextLabel, in its own band -- so a beginner keeps their instructions up while
-- the name goes by. That matters more than it used to: Greenhollow is announced
-- now, and it is exactly where the tutorial sends them.
--
--==============================================================================
-- WHEN IT FIRES
--
-- NOT DECIDED HERE. BiomeGateService polls the road position on the server and
-- sends a biome id only when the order CHANGES, by day -- that is the whole of
-- the debounce, and it is untouched: standing inside a biome sends nothing, and
-- leaving and coming back sends it again.
--
-- ONE TOKEN, SO NOTHING STACKS. Every arrival takes a new token; the hold timer
-- and the fade-out check it and stand down if a newer arrival owns the label. The
-- same name arriving while it is still up -- a player dancing on a boundary --
-- therefore reads as one notice held a little longer, not as a flicker, because
-- fading in to the opacity it already has changes nothing on screen.
--
-- NO LOOP. TweenService and one task.delay per arrival, exactly as the card had.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- Still named for what it used to carry. Renaming a remote is a server change
-- and a replication change for no behaviour at all; it carries a biome id.
local remoteInstance = SeedGame:WaitForChild("Remotes")
	:WaitForChild(GameConfig.Remotes.BiomeRecommendation)
if not remoteInstance:IsA("RemoteEvent") then
	warn("[Seed/BiomeGuideUI] BiomeRecommendation is not a RemoteEvent.")
	return
end
local entered = remoteInstance :: RemoteEvent

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedBiomeGuide")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedBiomeGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 45
gui.Parent = playerGui

local TEXT_SIZE = 24
local OUTLINE = 1.5
local TOP = 50
local HEIGHT = 30
local NAME_COLOUR = Color3.fromRGB(255, 255, 255)

local FADE_IN = 0.25
local HOLD = 1.6
local FADE_OUT = 0.7

--==============================================================================
-- ONE LABEL, SIZED TO ITS OWN WORD
--
-- AutomaticSize on X, so the label's box IS the text: a layout check that asks
-- what this covers gets the word's width and not a transparent strip across the
-- screen. The anchor keeps it centred as the word changes length.
--==============================================================================
local label = UIKit.outlined(gui, "BiomeName", TEXT_SIZE, NAME_COLOUR, OUTLINE)
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, TOP)
label.Size = UDim2.fromOffset(0, HEIGHT)
label.AutomaticSize = Enum.AutomaticSize.X
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.TextTransparency = 1
label.Visible = false

local edge = label:FindFirstChildOfClass("UIStroke")
assert(edge, "UIKit.outlined always gives its label a stroke")
local outline = edge :: UIStroke
outline.Transparency = 1

--==============================================================================
-- CLEAR OF THE TOP ROWS
--
-- 50 px from the top of the window is level with the rail on a 58 px topbar,
-- so the word is asked of HudLayout like everything else up there: centred
-- wherever it clears both top groups by 8 px -- every desktop, and every
-- biome name on every listed phone -- slid between them where it only fits
-- off centre, and dropped under them where it fits neither. Placed when the
-- word changes width and when the screen changes shape.
--==============================================================================
local function placeNotice()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local input = HudLayout.measure(gui)
	local layout = HudLayout.solve(input)
	local inset = input.insetTop or 0
	local width = label.AbsoluteSize.X + OUTLINE * 2
	local dx, top = HudLayout.notice(layout, width, HEIGHT, TOP - inset)
	label.Position = UDim2.new(0.5, math.round(dx), 0, top + inset)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeNotice)
label:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeNotice)
placeNotice()

local token = 0
local running: { Tween } = {}

local function fadeTo(alpha: number, seconds: number, direction: Enum.EasingDirection): Tween
	for _, tween in ipairs(running) do
		tween:Cancel()
	end
	table.clear(running)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, direction)
	local text = TweenService:Create(label, info, { TextTransparency = alpha })
	local stroke = TweenService:Create(outline, info, { Transparency = alpha })
	table.insert(running, text)
	table.insert(running, stroke)
	text:Play()
	stroke:Play()
	return text
end

local function showBiome(biomeId: string)
	local biome = BiomeData.ById[biomeId]
	if not biome then
		return
	end

	token += 1
	local mine = token
	label.Text = string.upper(biome.DisplayName)
	label.Visible = true
	fadeTo(0, FADE_IN, Enum.EasingDirection.Out)

	task.delay(FADE_IN + HOLD, function()
		if mine ~= token or not label.Parent then
			return
		end
		local out = fadeTo(1, FADE_OUT, Enum.EasingDirection.In)
		out.Completed:Once(function(state: Enum.PlaybackState)
			-- Cancelled means a newer arrival took the label mid-fade; it is
			-- that arrival's to hide, not this one's.
			if mine == token and state == Enum.PlaybackState.Completed then
				label.Visible = false
			end
		end)
	end)
end

entered.OnClientEvent:Connect(function(biomeId: unknown)
	if type(biomeId) ~= "string" then
		return
	end
	showBiome(biomeId)
end)
