--!nocheck
--==============================================================================
-- Steal a Seed :: FitWordsSpec (2026-10-17, the owner's phone: "PERFORMA / NCE MODE")
--
-- UIKit.fitWords and the two HUD switches that use it. On the owner's phone every
-- fixed-size word stood 3 px taller than designed (the engine's preferred text
-- size), and PERFORMANCE -- which fills the phone row's 73 px exactly at 10 --
-- broke inside the word. Drives, in Edit, with a throwaway ScreenGui:
--
--   * the break itself: the old label (wrapped, 13 px) in the row's box
--   * fitWords at the default setting: drawn exactly as the design asked
--   * drawn larger (a label asking 13 for the row's 10, as that phone drew it):
--     the lines whole, inside the box, as large as the box allows; new words
--     fitted again at once
--   * a label not drawn yet: the design's size until it can be measured
--   * both switches: fitWords in both layouts, the row's own two lines
--
-- NOT here, seen on a device instead: the engine's real setting (read-only in
-- Studio), and a player changing it mid-game.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)
local UIKit = require(Shared.UIKit)

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local ROW = HudLayout.Config.Phone.Switch
local BOX = Vector2.new(ROW.W - (ROW.PadLeft + ROW.PadRight + 4 + ROW.Track.X), ROW.H)
local OTHERS = GameConfig.OtherPlants

local old = StarterGui:FindFirstChild("ZZFitWordsSpec")
if old then
	old:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "ZZFitWordsSpec"
gui.Archivable = false
gui.Parent = StarterGui

local function box(text)
	local l = Instance.new("TextLabel")
	l.Font = Enum.Font.LuckiestGuy
	l.Size = UDim2.fromOffset(BOX.X, BOX.Y)
	l.Text = text
	l.Parent = gui
	return l
end
local function settle()
	task.wait(0.1)
end
local function fitOf(l)
	return l:FindFirstChild(UIKit.FitWordsName)
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The break: the old row label at the owner's 13 px")
	--==========================================================================
	local was = box(OTHERS.Label)
	was.TextWrapped = true
	was.TextSize = 13
	local whole = box(OTHERS.Label)
	whole.TextWrapped = true
	whole.TextSize = ROW.Label
	settle()
	local perf13 = TextService:GetTextSize("PERFORMANCE", 13, Enum.Font.LuckiestGuy, Vector2.new(4000, 100)).X
	check(perf13 > BOX.X and was.TextBounds.X < perf13,
		string.format("at 13 px PERFORMANCE (%d px) is wider than the %d px box, so the engine broke it inside the word",
			perf13, BOX.X), was.TextBounds)
	check(math.abs(whole.TextBounds.X - BOX.X) < 0.5,
		string.format("at the design's %d px it fills the box exactly (%g px): no room to grow", ROW.Label,
			whole.TextBounds.X), whole.TextBounds)

	--==========================================================================
	say("2. fitWords at the default setting: as designed")
	--==========================================================================
	local perf = box(OTHERS.RowLabel)
	UIKit.fitWords(perf, ROW.Label, BOX)
	local walk = box(GameConfig.WalkMode.Label)
	UIKit.fitWords(walk, ROW.Label, BOX)
	local fit = fitOf(perf)
	check(perf.TextScaled == false and perf.TextWrapped == false and fit and fit:IsA("UITextSizeConstraint")
			and perf.TextSize == ROW.Label and fit.MaxTextSize == ROW.Label + UIKit.FitWordsGrow,
		"asks for the design's size, never wrapped by the engine, free to grow while it fits",
		string.format("scaled=%s wrapped=%s max=%s size=%s", tostring(perf.TextScaled), tostring(perf.TextWrapped),
			tostring(fit and fit.MaxTextSize), tostring(perf.TextSize)))
	check(math.abs(perf.TextBounds.X - BOX.X) < 0.5 and math.abs(perf.TextBounds.Y - ROW.Label * 2) < 0.5,
		"PERFORMANCE / MODE drawn exactly as before: two lines at 10, the box's width", perf.TextBounds)
	check(math.abs(walk.TextBounds.Y - ROW.Label) < 0.5 and walk.TextBounds.X <= BOX.X,
		"WALK MODE drawn as before: one line at 10", walk.TextBounds)

	--==========================================================================
	say("3. Drawn larger (the owner's phone: 3 px), the words stay whole")
	--==========================================================================
	-- The setting itself is read-only in Studio: a label asking for 13 is drawn
	-- as the owner's phone drew the row's 10.
	perf.TextSize = ROW.Label + 3
	UIKit.refitWords(perf)
	walk.TextSize = ROW.Label + 3
	UIKit.refitWords(walk)
	fit = fitOf(perf)
	check(fit and fit.MaxTextSize == ROW.Label and math.abs(perf.TextBounds.X - BOX.X) < 0.5
			and math.abs(perf.TextBounds.Y - ROW.Label * 2) < 0.5,
		"PERFORMANCE / MODE is held to the largest size its lines fit (10): two whole lines", perf.TextBounds)
	check(walk.TextBounds.X <= BOX.X + 0.5 and walk.TextBounds.Y > ROW.Label + 0.5 and walk.TextBounds.Y <= ROW.Label + 3,
		"WALK MODE grows as far as its line still fits (12 of 13)", walk.TextBounds)
	-- (Signals are deferred: the words' change is answered on the next step.)
	perf.Text = OTHERS.Label
	settle()
	check(perf.TextBounds.X <= BOX.X + 0.5, "new words are fitted again: one long line shrinks to the box",
		perf.TextBounds)
	perf.Text = OTHERS.RowLabel
	settle()
	check(fitOf(perf).MaxTextSize == ROW.Label and math.abs(perf.TextBounds.X - BOX.X) < 0.5,
		"and the row's words again: back to 10", perf.TextBounds)

	--==========================================================================
	say("4. A label not drawn yet waits for its measure")
	--==========================================================================
	local loose = Instance.new("TextLabel")
	loose.Font = Enum.Font.LuckiestGuy
	loose.Size = UDim2.fromOffset(BOX.X, BOX.Y)
	loose.Text = OTHERS.RowLabel
	UIKit.fitWords(loose, ROW.Label, BOX)
	check(fitOf(loose) and fitOf(loose).MaxTextSize == ROW.Label, "unmeasured: held to the design's size meanwhile",
		fitOf(loose) and fitOf(loose).MaxTextSize)
	loose.Parent = gui
	task.wait(0.35)
	check(fitOf(loose).MaxTextSize == ROW.Label + UIKit.FitWordsGrow and math.abs(loose.TextBounds.X - BOX.X) < 0.5,
		"drawn, it is measured and fitted", fitOf(loose).MaxTextSize)

	--==========================================================================
	say("5. The switches use it in both layouts")
	--==========================================================================
	check(OTHERS.RowLabel == string.gsub(OTHERS.Label, " ", "\n"), "the row's lines are PERFORMANCE MODE's own words",
		OTHERS.RowLabel)
	local SPS = StarterPlayer.StarterPlayerScripts
	local others = SPS:FindFirstChild("OtherPlantsUI")
	local walkUi = SPS:FindFirstChild("WalkModeUI")
	local oSrc = if others then others.Source else ""
	local wSrc = if walkUi then walkUi.Source else ""
	local ROW_FIT = "UIKit.fitWords(label, ROW.Label, Vector2.new(r.w - (ROW.PadLeft + ROW.PadRight + 4 + ROW.Track.X), r.h))"
	check(has(oSrc, ROW_FIT) and has(oSrc, "UIKit.fitWords(label, if wide then NAME_WIDE else NAME_NARROW, Vector2.new(r.w - 4, LABEL_H))")
			and has(oSrc, "label.Text = if inlineRow then OTHERS.RowLabel else OTHERS.Label")
			and not has(oSrc, "label.TextWrapped = true"),
		"PERFORMANCE MODE: fitted on a phone's row and in the rail, its own two lines on the row")
	check(has(wSrc, ROW_FIT) and has(wSrc, "UIKit.fitWords(label, if wide then 13 else 12, Vector2.new(r.w - 4, LABEL_H))"),
		"WALK MODE: fitted on a phone's row and in the rail")
end)

gui:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("FitWordsSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
