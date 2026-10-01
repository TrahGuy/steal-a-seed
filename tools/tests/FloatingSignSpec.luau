--!nocheck
--==============================================================================
-- Steal a Seed :: FloatingSignSpec
--
-- The words that float over the Bonus Chest and the Sacrifice Pedestal
-- (2026-09-30, the owner's ask; reworked 2026-10-01): "FREE CHEST" in warm gold
-- with that player's state under it -- READY TO CLAIM! only when they can claim,
-- the time left on cooldown, nothing at all while it is locked to them -- and
-- "SACRIFICE A POD!" in bright lime with "+50% GARDEN INCOME" under it and a
-- third line, the one-sentence explanation or the time left, always up. Drawn
-- like the wheel's "SPIN THE WHEEL!", and nothing more.
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("FloatingSignSpec"))
--
-- The REAL FloatingSign, built on a throwaway folder, and the numbers in
-- GameConfig; the wheel's sign, the chest's board, PromptUI's lift and the two
-- UIs' wiring read from their sources. Not here: the words on a screen, and a
-- player's state changing under them -- those are the Play check.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	if not found then
		return nil
	end
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else nil
end

local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local function hex(c)
	return string.format("#%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

-- How tall, in studs, TextScaled makes a line of `text` in a box of w by h studs.
local function letters(text, w, h)
	local at100 = TextService:GetTextSize(text, 100, Enum.Font.LuckiestGuy, Vector2.new(100000, 1000))
	return math.min(h, w * 100 / at100.X)
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZFloatingSignSpec"
scratch.Archivable = false

local function body()
	local wheel = sourceOf(Server, "WheelModel") or ""
	local chestUI = sourceOf(Scripts, "BonusChestUI") or ""
	local pedestalUI = sourceOf(Scripts, "SacrificeUI") or ""
	local promptUI = sourceOf(Scripts, "PromptUI") or ""
	local signSrc = sourceOf(Shared, "FloatingSign") or ""
	local C = GameConfig.BonusChest.FloatingWords
	local P = GameConfig.Sacrifice.FloatingWords

	--==========================================================================
	-- 1. THE LOOK: THE WHEEL SIGN'S
	--==========================================================================
	say("\n-- the look: the wheel sign's --")
	check(has(wheel, "words.Font = Enum.Font.LuckiestGuy") and has(wheel, "outline.Color = Color3.fromRGB(34, 24, 16)")
			and has(wheel, "outline.Thickness = 2.5") and has(wheel, "board.MaxDistance = place.SignDistance")
			and has(wheel, "board.LightInfluence = 0") and has(wheel, "board.AlwaysOnTop = false"),
		"(the wheel's sign is still LuckiestGuy, a 2.5 dark outline, lit by nothing, gone past SignDistance)")
	check(FloatingSign.Font == Enum.Font.LuckiestGuy and FloatingSign.Outline == Color3.fromRGB(34, 24, 16)
			and FloatingSign.OutlineThickness == 2.5 and FloatingSign.Distance == WheelData.Place.SignDistance,
		"the floating words take the wheel sign's face, outline and reach", FloatingSign.Distance)

	local sign = FloatingSign.new({
		name = "SpecWords", parent = scratch, at = CFrame.new(0, 10, 0), text = "HELLO!",
		colour = Color3.fromRGB(1, 2, 3), width = 10, height = 2, subText = "SMALL", subHeight = 1,
	})
	local gui = sign.gui
	check(gui:IsA("BillboardGui") and gui.Size == UDim2.fromScale(10, 3) and gui.MaxDistance == FloatingSign.Distance
			and gui.LightInfluence == 0 and gui.AlwaysOnTop == false,
		"a billboard sized in studs, so it shrinks with distance like the wheel's, gone past the same distance",
		tostring(gui.Size))
	check(gui.Enabled == false and sign.shown() == false, "it starts hidden: nothing shows until its script says so")
	sign.setShown(true)
	local on = gui.Enabled and sign.shown()
	sign.setShown(false)
	check(on and not gui.Enabled and not sign.shown(), "and shows and hides on its script's word")
	local edge = sign.words:FindFirstChildOfClass("UIStroke")
	check(sign.words.Font == Enum.Font.LuckiestGuy and sign.words.TextScaled and sign.words.Text == "HELLO!"
			and sign.words.TextColor3 == Color3.fromRGB(1, 2, 3) and edge ~= nil and edge.Thickness == 2.5
			and edge.Color == FloatingSign.Outline,
		"the words: LuckiestGuy, scaled to their box, one plain colour, the thick dark outline")
	local sub = sign.sub
	check(sub ~= nil and sub.Text == "SMALL" and sub.TextColor3 == sign.words.TextColor3
			and math.abs(sub.Position.Y.Scale - 2 / 3) < 1e-6 and math.abs(sign.words.Size.Y.Scale - 2 / 3) < 1e-6,
		"and a second line under them, in its own smaller box")
	local anchor = sign.anchor
	check(anchor.Transparency == 1 and anchor.Anchored and not anchor.CanCollide and not anchor.CanQuery
			and not anchor.CanTouch and anchor.Parent == scratch and gui.Parent == anchor
			and anchor.Position == Vector3.new(0, 10, 0),
		"hung on an invisible anchor that nothing can touch, stand on or hit")
	local extras = 0
	for _, d in ipairs(anchor:GetDescendants()) do
		if d:IsA("UIGradient") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
			or d:IsA("ScreenGui") or d:IsA("LuaSourceContainer") then
			extras += 1
		end
	end
	check(extras == 0, "no rainbow, no particles, no screen panel: plain words", extras)
	check(not has(signSrc, "UIGradient") and not has(signSrc, "ParticleEmitter") and not has(signSrc, "ScreenGui")
			and not has(signSrc, "RenderStepped") and not has(signSrc, "Heartbeat") and not has(signSrc, "TweenService"),
		"and nothing in it moves or animates")
	sign.destroy()
	check(anchor.Parent == nil, "and it goes when it is taken away")

	-- The third line (2026-10-01): a sentence, under the other two.
	local three = FloatingSign.new({
		name = "SpecNote", parent = scratch, at = CFrame.new(0, 10, 0), text = "HELLO!",
		colour = Color3.fromRGB(1, 2, 3), width = 10, height = 2, subText = "SMALL", subHeight = 1,
		noteText = "A sentence.", noteHeight = 1, noteColour = Color3.fromRGB(4, 5, 6),
	})
	local note = three.note
	check(three.gui.Size == UDim2.fromScale(10, 4) and note ~= nil and note.Text == "A sentence."
			and note.Font == FloatingSign.NoteFont and note.TextWrapped and note.TextScaled
			and note.TextColor3 == Color3.fromRGB(4, 5, 6)
			and math.abs(note.Position.Y.Scale - 0.75) < 1e-6 and math.abs(three.sub.Size.Y.Scale - 0.25) < 1e-6
			and note:FindFirstChildOfClass("UIStroke").Thickness == FloatingSign.NoteOutlineThickness,
		"and an optional third line under them: a wrapped sentence in the boards' plain bold face")
	three.destroy()

	--==========================================================================
	-- 2. THE WORDS AND THEIR COLOURS
	--==========================================================================
	say("\n-- the words --")
	check(C.Text == "FREE CHEST" and hex(C.Colour) == "#FFD34D" and C.ReadyText == "READY TO CLAIM!",
		"the chest: FREE CHEST in warm gold, #FFD34D, and READY TO CLAIM! under it", C.Text .. " " .. hex(C.Colour))
	check(not string.find(string.upper(C.Text), "BOOST", 1, true),
		"and it is never called a boost: the chest can give different rewards")
	check(P.Text == "SACRIFICE A POD!" and hex(P.Colour) == "#8CFF6A",
		"the pedestal: SACRIFICE A POD! in bright lime, #8CFF6A", P.Text .. " " .. hex(P.Colour))
	local line = GameConfig.sacrificeBoostTitle(SeedData.Sacrifice.Multiplier)
	check(line == "+50% GARDEN INCOME",
		"and its smaller line, written from the pedestal's own numbers: +50% GARDEN INCOME", line)
	local explain = GameConfig.sacrificeExplain(SeedData.Sacrifice.Multiplier, SeedData.Sacrifice.DurationSeconds)
	check(explain == "Sacrifice one owned, banked pod for +50% garden income for 45 seconds.",
		"and its sentence, from the same numbers", explain)

	--==========================================================================
	-- 3. THE SIZE
	--==========================================================================
	say("\n-- the size --")
	check(has(wheel, "board.Size = UDim2.fromScale(15, 2.8)"), "(the wheel's words box is still 15 by 2.8 studs)")
	local wheelLetters = letters("SPIN THE WHEEL!", 15, 2.8)
	local chestLetters = letters(C.Text, C.Width, C.Height)
	local pedestalLetters = letters(P.Text, P.Width, P.Height)
	local subLetters = letters(line, P.Width, P.SubHeight)
	check(chestLetters >= 1.3 and chestLetters < wheelLetters and pedestalLetters >= 1.3
			and pedestalLetters < wheelLetters,
		"letters a little smaller than the wheel's, over two smaller things",
		string.format("wheel %.2f, chest %.2f, pedestal %.2f studs", wheelLetters, chestLetters, pedestalLetters))
	check(subLetters >= 0.7 and subLetters < pedestalLetters * 0.75,
		"the second line clearly smaller, and still big enough to read",
		string.format("%.2f studs", subLetters))

	--==========================================================================
	-- 4. WHERE THEY FLOAT: CLEAR OF THE BOARDS AND THE PROMPTS
	--==========================================================================
	say("\n-- where they float --")
	check(has(chestUI, "board.CFrame = origin * CFrame.new(0, 5.6, 2.6)")
			and has(chestUI, "signPart(\"Rim\", Vector3.new(6.7, 3.7, 0.25)"),
		"(the chest's board still stands 5.6 up with a 3.7 tall rim: its top is 7.45)")
	-- The lowest letters are the second line's, at their longest.
	local chestSub = letters(C.WaitText .. "10:00", C.Width, C.SubHeight)
	local chestLow = C.Above - (C.Height + C.SubHeight) / 2 + (C.SubHeight - chestSub) / 2
	check(C.Behind == 2.6 and chestLow >= 7.45 + 0.8,
		"the chest's words float over its board, in its plane, with room between",
		string.format("letters from %.2f studs", chestLow))
	-- A prompt's panel is drawn LIFT over its part at a fixed 52 px. On a phone
	-- screen 390 px tall, 18 studs off, that panel reaches this far either side.
	check(has(promptUI, "local LIFT = Vector3.new(0, 2.4, 0)"), "(PromptUI still draws a prompt 2.4 studs over its part)")
	local reach = 26 * (2 * 18 * math.tan(math.rad(35))) / 390
	local pedestalLow = P.Above - (P.Height + P.SubHeight + P.NoteHeight) / 2
	check(pedestalLow >= 2.4 + reach + 0.3,
		"the pedestal's words start above its prompt, even on a phone up close",
		string.format("box from %.2f over the bowl; the prompt reaches %.2f", pedestalLow, 2.4 + reach))

	--==========================================================================
	-- 5. SHOWN TO WHOM, AND WHEN
	--==========================================================================
	say("\n-- shown to whom, and when --")
	check(has(chestUI, "local ready = unlocked and now >= nextAt and not pending")
			and has(chestUI, "b.words.setShown(unlocked)") and has(chestUI, "local W = CHEST.FloatingWords")
			and has(chestUI, "if ready then\n\t\t\t\tsub.Text, sub.TextColor3 = W.ReadyText, READY")
			and has(chestUI, "FloatingSign.new({"),
		"the chest's words stay up through the cooldown, never for a player it is locked to, and say READY TO"
			.. " CLAIM! on the prompt's own answer only")
	check(has(pedestalUI, "local ready = now >= nextAt") and has(pedestalUI, "w.setShown(true)")
			and has(pedestalUI, "local W = CONFIG.FloatingWords")
			and has(pedestalUI, "subText = GameConfig.sacrificeBoostTitle(SeedData.Sacrifice.Multiplier)")
			and has(pedestalUI, "\"RECHARGING · READY IN \" .. StatusText.clock(nextAt - now)"),
		"the pedestal's words stay up; its third line says how long while it recharges")
	local chestServer = sourceOf(Server, "BonusChestService") or ""
	local pedestalServer = sourceOf(Server, "SacrificeService") or ""
	check(#chestServer > 0 and #pedestalServer > 0 and not has(chestServer, "FloatingSign")
			and not has(chestServer, "FloatingWords") and not has(pedestalServer, "FloatingSign")
			and not has(pedestalServer, "FloatingWords"),
		"each client makes its own: the servers never build these words, so nobody sees another player's")
end

local ok, err = pcall(body)
scratch:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nFloatingSignSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
