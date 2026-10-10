--!nocheck
--==============================================================================
-- Steal a Seed :: FloatingSignSpec
--
-- The words that float over the Bonus Chest, the Sacrifice Pedestal and, since
-- 2026-10-08, Marigold's stall ("BAT SHOP!" over "BATS & TRAPS", in a red
-- orange of its own, clear of the awning, her head, her prompt and every other
-- sign in the square)
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

	--==========================================================================
	-- THE STARBLOOM TEASER (2026-10-01): the same look, over the road's last wall
	--==========================================================================
	say("\n-- the Starbloom teaser --")
	local BiomeData = require(Shared:WaitForChild("BiomeData"))
	local Teaser = require(Shared:WaitForChild("StarbloomTeaser"))
	local T = GameConfig.StarbloomTeaser
	check(T.Text == "BEYOND THE STARS…" and T.SubText == "NEW BIOME · COMING SOON"
			and hex(T.Colour) == "#C9A7FF" and hex(T.SubColour) == "#FFD34D",
		"the owner's words: BEYOND THE STARS… in lavender over NEW BIOME · COMING SOON in the chest's gold",
		hex(T.Colour) .. " / " .. hex(T.SubColour))
	local biome = Teaser.biome()
	local at = Teaser.placement()
	local nearZ, farZ = 0, 0
	if biome then
		nearZ, farZ = BiomeData.SegmentBounds(biome)
	end
	check(biome ~= nil and biome.Order == #BiomeData.Biomes and at ~= nil and at.Position.X == 0
			and math.abs(at.Position.Z - (farZ + T.OffWall)) < 1e-6 and T.OffWall >= 6
			and at.Position.Z < nearZ and at.Position.Z > farZ,
		"over the end wall of Starbloom, the last segment: the corridor's middle, OffWall studs off the wall's face",
		at and tostring(at.Position))
	local bottom = T.Above - (T.Height + T.SubHeight) / 2
	check(T.Width / 2 < GameConfig.Map.CorridorWidth / 2 - 4 and bottom >= 10,
		"clear of both walls, and its foot well over heads, pods and their prompts",
		string.format("half width %.1f, foot %.1f studs up", T.Width / 2, bottom))
	check(T.Distance >= GameConfig.Map.SegmentLength,
		"drawn down the whole Starbloom segment, not just across the hub", T.Distance)
	local tall, subTall = letters(T.Text, T.Width, T.Height), letters(T.SubText, T.Width, T.SubHeight)
	check(tall >= T.Height - 0.01 and subTall >= T.SubHeight - 0.01 and tall >= 6 and subTall >= 3.5,
		"letters about 6.5 and 3.6 studs tall: the boxes are wide enough that the height decides",
		string.format("%.2f / %.2f", tall, subTall))
	local made = Teaser.build(scratch)
	local glow = made and made.gui:FindFirstChild("Glow")
	local glowEdge = glow and glow:FindFirstChildOfClass("UIStroke")
	local edge = made and made.words:FindFirstChildOfClass("UIStroke")
	local light = made and made.anchor:FindFirstChildOfClass("PointLight")
	check(made ~= nil and made.gui.Enabled and made.gui.MaxDistance == T.Distance
			and made.words.Font == FloatingSign.Font and made.words.Text == T.Text
			and edge ~= nil and edge.Color == FloatingSign.Outline and edge.Thickness == FloatingSign.OutlineThickness
			and made.sub ~= nil and made.sub.Text == T.SubText and made.sub.TextColor3 == T.SubColour,
		"drawn by FloatingSign: LuckiestGuy with the hub's dark outline, the gold line under it, up for everybody")
	check(glow ~= nil and glow.ZIndex < made.words.ZIndex and glow.Text == T.Text and glowEdge ~= nil
			and glowEdge.Color == T.Colour and glowEdge.Thickness == T.GlowThickness
			and math.abs(glowEdge.Transparency - T.GlowTransparency) < 1e-4 and light ~= nil and light.Color == T.Colour
			and not light.Shadows and not made.anchor.CanCollide and not made.anchor.CanQuery
			and not made.anchor.CanTouch,
		"the glow: a half-clear lavender edge behind the letters and a soft light, on an anchor nothing can touch")
	local clientSrc = sourceOf(Scripts, "StarbloomTeaser") or ""
	local moduleSrc = sourceOf(Shared, "StarbloomTeaser") or ""
	local both = clientSrc .. moduleSrc
	check(#clientSrc > 0 and #moduleSrc > 0 and not has(both, "RenderStepped") and not has(both, "Heartbeat")
			and not has(both, "TweenService") and not has(both, "task.wait") and not has(both, "UIGradient"),
		"steady: nothing in it moves, pulses or flashes")
	local serverHits = 0
	for _, s in ipairs(Server:GetDescendants()) do
		if s:IsA("LuaSourceContainer") and has(sourceOf(s.Parent, s.Name) or "", "StarbloomTeaser") then
			serverHits += 1
		end
	end
	check(serverHits == 0 and not has(both, "Remote") and not has(both, "Teleport") and not has(both, "Prompt"),
		"a teaser only: no server, remote, teleport or prompt has anything to do with it")

	--==========================================================================
	-- MARIGOLD'S "BAT SHOP!" (2026-10-08, the owner: "new players dont know
	-- about where to buy bats, we will add a shop text above marigold like
	-- spinwheel")
	--==========================================================================
	say("\n-- Marigold's BAT SHOP! --")
	local M = GameConfig.Weapon.FloatingWords
	local function apart(a, b)
		return math.sqrt(((a.R - b.R) * 255) ^ 2 + ((a.G - b.G) * 255) ^ 2 + ((a.B - b.B) * 255) ^ 2)
	end
	local nearest = math.huge
	for _, c in ipairs({ C.Colour, P.Colour, T.Colour, T.SubColour, Color3.new(1, 1, 1) }) do
		nearest = math.min(nearest, apart(M.Colour, c))
	end
	check(M.Text == "BAT SHOP!" and M.SubText == "BATS & TRAPS" and nearest >= 100,
		"BAT SHOP! over BATS & TRAPS, in a colour no other sign in the square wears (gold, lime, lavender, the "
			.. "wheel's white)", string.format("%s, %.0f from the nearest", hex(M.Colour), nearest))
	local shopLetters, shopSub = letters(M.Text, M.Width, M.Height), letters(M.SubText, M.Width, M.SubHeight)
	check(shopLetters >= wheelLetters and shopLetters <= wheelLetters * 1.2 and shopSub >= 0.7
			and shopSub < shopLetters * 0.75,
		"letters a touch over the wheel's, for the square's one shop; the second line clearly smaller",
		string.format("%.2f / %.2f studs (the wheel's %.2f)", shopLetters, shopSub, wheelLetters))

	-- Where the stall's numbers come from: MapService builds it, so its source
	-- is pinned and the awning's top and front edge worked out from it.
	local mapSrc = sourceOf(Server, "MapService") or ""
	check(has(mapSrc, "local stallCF = GameConfig.hubStallCFrame()")
			and has(mapSrc, "local counter = build({ name = MAP.SellStandName, size = Vector3.new(20, 3.6, 6),")
			and has(mapSrc, "cframe = stallCF * CFrame.new(0, 2.4, 0), color = WOOD,")
			and has(mapSrc, 'build({ name = "Awning", size = Vector3.new(3.4, 0.6, 12),')
			and has(mapSrc, "cframe = stallCF * CFrame.new(-10.2 + i * 3.4, 13.4, -1.5)")
			and has(mapSrc, "* CFrame.Angles(math.rad(-17), 0, 0),")
			and has(mapSrc, "HubFairy.build(stallCF * CFrame.new(0, 2, -5.5) * CFrame.Angles(0, math.pi, 0), hub)"),
		"(the stall is still: the counter's middle 2.4 up, the awning 13.4 up and tilted 17 degrees, Marigold on the "
			.. "riser 2 up)")
	-- OVER THE ROOF since 2026-10-10 (the owner: "lift BAT SHOP! over the
	-- roof"), like SPIN THE WHEEL! over its arch. The awning's HIGH edge is its
	-- front one, the customers' side (its slats tilt up toward them): the
	-- words' foot clears it by 1.5 and more, over the roof's span.
	local tilt = math.rad(17)
	local roofTop = 13.4 + 6 * math.sin(tilt) + 0.3 * math.cos(tilt) - 2.4
	local awningFront = -1.5 + 6 * math.cos(tilt) - 0.3 * math.sin(tilt)
	local awningBack = -1.5 - 6 * math.cos(tilt) - 0.3 * math.sin(tilt)
	local foot = M.Above - (M.Height + M.SubHeight) / 2
	check(foot >= roofTop + 1.5 and M.Front > awningBack and M.Front < awningFront,
		"over the roof, 1.5 studs and more clear of its high front edge, over the roof's span",
		string.format("foot %.2f over the counter's middle, the roof's top %.2f; %.2f out, the roof %.2f to %.2f", foot,
			roofTop, M.Front, awningBack, awningFront))
	-- Marigold is 5.5 studs tall (measured, Edit, 2026-10-08), standing on the
	-- riser 2 up; her prompt hangs off her Torso and PromptUI lifts its panel
	-- 2.4 over that, reaching `reach` either side on a phone up close (and a
	-- prompt is drawn over the world anyway).
	local herTop = 2 + 5.5 - 2.4
	local promptTop = 2 + 3 + 2.4 + reach - 2.4
	check(foot >= herTop + 1 and foot >= promptTop + 0.3,
		"over Marigold's head and over her Open Shop prompt, even on a phone",
		string.format("foot %.2f; her head %.2f, the prompt to %.2f", foot, herTop, promptTop))
	-- THE WHEEL STOOD STRAIGHT BEHIND THE STALL until 2026-10-10, so from the
	-- square and the road -- all of it on that line -- words over the roof sat
	-- right on top of "SPIN THE WHEEL!" (Play, 2026-10-08). The stall stands
	-- beside the road's approach now (Map.Stall), off that line, and the rule
	-- stays. Both are billboards, square to every eye: each covers atan(half /
	-- distance) either side of the line to its middle, across and up, and two
	-- overlap on screen when both spans do. The wheel's words, measured in that
	-- Play: middle (0, 24.3, 36.4).
	check(has(wheel, "at(0, archTop + 3.4, -1.6)") and has(wheel, "board.Size = UDim2.fromScale(15, 2.8)"),
		"(the wheel's words still stand 3.4 over its arch, 1.6 behind its middle, 15 by 2.8)")
	local shopAt = GameConfig.hubStallCFrame():PointToWorldSpace(Vector3.new(0, 2.4 + M.Above, M.Front))
	local shopY = GameConfig.Map.GroundY + 2.4 + M.Above
	local shopHalf = (M.Height + M.SubHeight) / 2
	-- How much of b's box a's covers on screen, 0 to 1. A billboard past its
	-- draw distance is not drawn at all: every one here stops at
	-- FloatingSign.Distance, the wheel's at its SignDistance, the same.
	local function overlap(eye, a, b)
		local da, db = (a.at - eye).Magnitude, (b.at - eye).Magnitude
		if da > FloatingSign.Distance or db > FloatingSign.Distance then
			return 0
		end
		local function view(s, d)
			local flat = Vector2.new(s.at.X - eye.X, s.at.Z - eye.Z)
			return math.atan2(flat.X, flat.Y), math.atan2(s.at.Y - eye.Y, flat.Magnitude),
				math.atan2(s.halfW, d), math.atan2(s.halfH, d)
		end
		local azA, elA, wA, hA = view(a, da)
		local azB, elB, wB, hB = view(b, db)
		local across = (azA - azB + math.pi) % (2 * math.pi) - math.pi
		local up = elA - elB
		local ox = math.max(0, math.min(across + wA, wB) - math.max(across - wA, -wB))
		local oy = math.max(0, math.min(up + hA, hB) - math.max(up - hA, -hB))
		return ox * oy / (4 * wB * hB)
	end
	local function nearer(eye, a, b)
		return (a.at - eye).Magnitude < (b.at - eye).Magnitude
	end
	local shopSign = { at = shopAt, halfW = M.Width / 2, halfH = shopHalf }
	local WP = WheelData.Place
	local spinSign = { name = "SPIN THE WHEEL!", halfW = 15 / 2, halfH = 2.8 / 2,
		at = (CFrame.new(WP.Position) * CFrame.Angles(0, math.rad(WP.FacingDegrees), 0)):PointToWorldSpace(
			Vector3.new(0, 23.4, -1.6)) }
	-- The other words in the square, from their own configs (the chest's
	-- behind its pivot, the pedestal's over its bowl, 3.1 up).
	local chestCF = CFrame.new(GameConfig.BonusChest.Position)
		* CFrame.Angles(0, math.rad(GameConfig.BonusChest.FacingDegrees), 0)
	local R = GameConfig.Rebirth.FloatingWords
	local signs = {
		spinSign,
		{ name = "FREE CHEST", at = chestCF:PointToWorldSpace(Vector3.new(0, C.Above, C.Behind)), halfW = C.Width / 2,
			halfH = (C.Height + C.SubHeight) / 2 },
		{ name = "SACRIFICE A POD!", at = GameConfig.Sacrifice.Position + Vector3.new(0, 3.1 + P.Above, 0),
			halfW = P.Width / 2, halfH = (P.Height + P.SubHeight + P.NoteHeight) / 2 },
		{ name = "REBIRTH", at = GameConfig.Rebirth.Position + Vector3.new(0, R.Above, 0), halfW = R.Width / 2,
			halfH = (R.Height + R.SubHeight) / 2 },
	}
	-- Eyes 6 to 16 studs up, two studs apart, since the shop row (2026-10-10,
	-- Map.Stall): in the field before the row, on ground no plot ever takes
	-- (west of plot 1's growth, and the pocket before the stall), where the
	-- plots' players come from; and in the road's mouth.
	local fieldEyes, mouthEyes = {}, {}
	for y = 6, 16, 2 do
		for x = -260, -190, 2 do
			for z = -112, -60, 2 do
				table.insert(fieldEyes, Vector3.new(x, y, z))
			end
		end
		for x = -136, -120, 2 do
			for z = -140, -128, 2 do
				table.insert(fieldEyes, Vector3.new(x, y, z))
			end
		end
		for x = -60, 0, 2 do
			for z = -164, -124, 2 do
				table.insert(mouthEyes, Vector3.new(x, y, z))
			end
		end
	end
	local spinCovered, firstSpin = 0, nil
	for _, eye in ipairs(fieldEyes) do
		if overlap(eye, shopSign, spinSign) > 0 or overlap(eye, spinSign, shopSign) > 0 then
			spinCovered += 1
			firstSpin = firstSpin or string.format("from (%d, %d, %d)", eye.X, eye.Y, eye.Z)
		end
	end
	check(spinCovered == 0 and #fieldEyes > 5000 and #mouthEyes > 3000,
		"SPIN THE WHEEL! and these never cover each other from the field before the row",
		firstSpin or string.format("%d + %d eyes", #fieldEyes, #mouthEyes))
	-- From the road's mouth the row is seen end-on, its words in a line:
	-- measured, not ruled.
	local mouthSpin = 0
	for _, eye in ipairs(mouthEyes) do
		if overlap(eye, shopSign, spinSign) > 0 or overlap(eye, spinSign, shopSign) > 0 then
			mouthSpin += 1
		end
	end
	say(string.format("  NOTE  from the road's mouth SPIN THE WHEEL! and BAT SHOP! share screen from %.0f%% of eyes",
		100 * mouthSpin / #mouthEyes))
	local mouthHidden, firstMouth = 0, nil
	for _, eye in ipairs(mouthEyes) do
		for _, o in ipairs(signs) do
			if nearer(eye, o, shopSign) and overlap(eye, o, shopSign) > 0 then
				mouthHidden += 1
				firstMouth = firstMouth or string.format("%s from (%d, %d, %d)", o.name, eye.X, eye.Y, eye.Z)
			end
		end
	end
	check(mouthHidden == 0, "from the road's mouth, no nearer sign's words stand in front of BAT SHOP!", firstMouth)
	-- Measured, not ruled: from the field a nearer sign can stand in front of
	-- it from some spots, as anything nearer does. Reported every run.
	local fieldHid = 0
	for _, eye in ipairs(fieldEyes) do
		local worst = 0
		for _, o in ipairs(signs) do
			if nearer(eye, o, shopSign) then
				worst = math.max(worst, overlap(eye, o, shopSign))
			end
		end
		if worst > 0.25 then
			fieldHid += 1
		end
	end
	say(string.format("  NOTE  a nearer sign's words cover over a quarter of BAT SHOP! from %.0f%% of the field's eyes",
		100 * fieldHid / math.max(1, #fieldEyes)))
	local shopXZ = Vector2.new(shopAt.X, shopAt.Z)
	local worst, worstName = math.huge, ""
	for _, o in ipairs({
		{ "the wheel", WheelData.Place.Position, 15 / 2 },
		{ "FREE CHEST", GameConfig.BonusChest.Position, C.Width / 2 },
		{ "SACRIFICE A POD!", GameConfig.Sacrifice.Position, P.Width / 2 },
		{ "the community chest", GameConfig.Community.Position, GameConfig.Community.SignWidth / 2 },
		{ "the invite pedestal", GameConfig.InviteRewards.Position, 5 },
	}) do
		local gap = (Vector2.new(o[2].X, o[2].Z) - shopXZ).Magnitude - M.Width / 2 - o[3]
		if gap < worst then
			worst, worstName = gap, o[1]
		end
	end
	check(worst >= 4, "clear of every other sign in the square", string.format("nearest: %s, %.1f studs between",
		worstName, worst))
	-- The Edit preview of the map, when it is there, agrees with the numbers.
	local hubModel = workspace:FindFirstChild(GameConfig.Map.FolderName)
	hubModel = hubModel and hubModel:FindFirstChild(GameConfig.Map.PropsFolderName)
	hubModel = hubModel and hubModel:FindFirstChild("Hub")
	local stand = hubModel and hubModel:FindFirstChild(GameConfig.Map.SellStandName)
	if stand and stand:IsA("BasePart") then
		-- The words' box, and every part of the real stall's box, in the
		-- counter's own frame (the stall stands turned): none may reach into it.
		local at = stand.Position + Vector3.yAxis * M.Above - stand.CFrame.LookVector * M.Front
		local mid = stand.CFrame:PointToObjectSpace(at)
		local lo = mid - Vector3.new(M.Width / 2, shopHalf, 0.1)
		local hi = mid + Vector3.new(M.Width / 2, shopHalf, 0.1)
		local inside = {}
		for _, d in ipairs(hubModel:GetDescendants()) do
			if d:IsA("BasePart") then
				local cf, size = d.CFrame, d.Size
				local pLo, pHi = Vector3.new(math.huge, math.huge, math.huge), -Vector3.new(math.huge, math.huge, math.huge)
				for _, sx in ipairs({ -0.5, 0.5 }) do
					for _, sy in ipairs({ -0.5, 0.5 }) do
						for _, sz in ipairs({ -0.5, 0.5 }) do
							local p = stand.CFrame:PointToObjectSpace(
								cf:PointToWorldSpace(Vector3.new(sx * size.X, sy * size.Y, sz * size.Z)))
							pLo, pHi = pLo:Min(p), pHi:Max(p)
						end
					end
				end
				if pLo.X < hi.X and pHi.X > lo.X and pLo.Y < hi.Y and pHi.Y > lo.Y and pLo.Z < hi.Z and pHi.Z > lo.Z then
					table.insert(inside, d.Name)
				end
			end
		end
		check(#inside == 0 and (at - shopAt).Magnitude < 0.01 and math.abs(at.Y - shopY) < 0.01,
			"(the Edit preview's real stall agrees: no part of it inside the words' box)",
			string.format("words at %s; in the way: %s", tostring(at), table.concat(inside, ", ")))
	end
	-- The real FloatingSign, from these numbers.
	local shop = FloatingSign.new({
		name = "SpecShop", parent = scratch, at = CFrame.new(0, 20, 0), text = M.Text, colour = M.Colour,
		width = M.Width, height = M.Height, subText = M.SubText, subHeight = M.SubHeight,
	})
	check(shop.gui.Size == UDim2.fromScale(M.Width, M.Height + M.SubHeight) and shop.words.Text == M.Text
			and shop.sub ~= nil and shop.sub.Text == M.SubText and shop.sub.TextColor3 == M.Colour
			and shop.words.TextColor3 == M.Colour and shop.note == nil,
		"drawn by FloatingSign: the two lines, one colour, no third line")
	shop.destroy()
	local markSrc = sourceOf(Scripts, "MarigoldSign") or ""
	local shopServer = sourceOf(Server, "WeaponShopService") or ""
	check(has(markSrc, "local W = GameConfig.Weapon.FloatingWords") and has(markSrc, "FloatingSign.new({")
			and has(markSrc, "subText = W.SubText") and has(markSrc, "sign.setShown(true)")
			and has(markSrc, "- counter.CFrame.LookVector * W.Front") and not has(markSrc, "RenderStepped")
			and not has(markSrc, "Heartbeat") and not has(markSrc, "TweenService") and not has(markSrc, "setShown(false)"),
		"MarigoldSign puts it up for everybody, all the time, steady: anyone can buy")
	check(#shopServer > 0 and not has(shopServer, "FloatingSign") and not has(shopServer, "FloatingWords"),
		"each client makes its own: the shop's server never builds it")
end

local ok, err = pcall(body)
scratch:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nFloatingSignSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
