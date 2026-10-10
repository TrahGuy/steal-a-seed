--!nocheck
--==============================================================================
-- Steal a Seed :: TitleFXSpec
--
-- THE REBIRTH TITLES' LEAVES, FLOWERS AND MIST (2026-10-10, the owner's brief;
-- GameConfig.TitleFX, Shared/TitleFX, OwnerTitleUI). Edit mode:
--
--   1. the config: every step of the current ladder wears a known profile (or
--      none: GAIA keeps its rainbow alone), at most MaxSprites; every art key
--      named; with no id uploaded, every profile is OFF
--   2. where the sprites stand, for every title the ladder gives (rebirth 1 to
--      303, all 100 titles since 2026-10-10) at desktop and phone size: inside the title's band (ADMIN over it,
--      the name under it), the leaves beside the words, the sprigs at their
--      ends, the mist faint and off the words' middle, nothing flashing
--   3. the four nearest move, never one out of range
--   4. the layer: under the words and REBIRTH N, no panel, no light, hidden
--      until stepped, a picture that never loads stays clear, gone with the
--      title
--   5. OwnerTitleUI: the profile from the player's Rebirths through
--      Rebirth.title, never the words; one loop; hidden under Reduced FX and
--      a trap; forgotten with its title. The celebration and the aura are not
--      touched.
--   6. the Rebirth panel's "?" TITLES list (the owner: "add them to the ?
--      list too"): every step's row wears its title's effects round its
--      words, inside the row, between its plate and its texts; moved from the
--      panel's own loop on the rows in view, faded on LOCKED rows, none under
--      Reduced FX
--
-- Not here, seen in Play once the ids are uploaded: the art itself by day and
-- night, on a phone, with ADMIN.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local Rebirth = require(Shared.Rebirth)
local TitleFX = require(Shared.TitleFX)

local FX = GameConfig.TitleFX
local TITLE = GameConfig.Rebirth.Title

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
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

local fixture = Instance.new("Folder")
fixture.Name = "TitleFXSpecFixture"
fixture.Parent = Workspace

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the config --")
	--==========================================================================
	local MOTIONS = { drift = true, outward = true, laurel = true, mist = true }
	local bad = {}
	for name, profile in pairs(FX.Profiles) do
		if not MOTIONS[profile.Motion] or #profile.Art < 1 or #profile.Tints < 1 then
			table.insert(bad, name)
		end
		for _, key in ipairs(profile.Art) do
			if FX.Art[key] == nil then
				table.insert(bad, name .. ":" .. key)
			end
		end
		if profile.LeafArt and FX.Art[profile.LeafArt] == nil then
			table.insert(bad, name .. ":" .. profile.LeafArt)
		end
	end
	check(#bad == 0, "every profile has a known motion, and every picture it names is in Art", table.concat(bad, ", "))
	local unmapped, over = {}, {}
	for index, step in ipairs(TITLE.Ladder) do
		local wants = FX.Steps[step.Text]
		if step.Rainbow then
			if wants then
				table.insert(unmapped, step.Text .. " (rainbow wears more)")
			end
		elseif not wants or not FX.Profiles[wants.Profile] then
			table.insert(unmapped, step.Text)
		elseif wants.Count < 1 or wants.Count > FX.MaxSprites then
			table.insert(over, step.Text)
		end
		local _ = index
	end
	local stray = {}
	for text in pairs(FX.Steps) do
		local found = false
		for _, step in ipairs(TITLE.Ladder) do
			found = found or step.Text == text
		end
		if not found then
			table.insert(stray, text)
		end
	end
	check(#unmapped == 0 and #over == 0 and #stray == 0 and FX.MaxSprites <= 6 and FX.MaxAnimated == 4,
		"every step but the rainbow wears a profile, 1 to 6 sprites; no step listed that the ladder lacks; "
			.. "four titles move at most", table.concat(unmapped, ", ") .. " / " .. table.concat(over, ", ") .. " / "
			.. table.concat(stray, ", "))
	local off = true
	for _, id in pairs(FX.Art) do
		off = off and id == ""
	end
	local anyOn = false
	for n = 1, 303 do
		local profileName = TitleFX.profileFor(Rebirth.title(n))
		anyOn = anyOn or profileName ~= nil
	end
	check(not off or not anyOn, "with no id uploaded every profile is off: no layer is ever made (the words alone)")
	say("  (art ids uploaded: " .. (if off then "none -- every effect off" else "some") .. ")")
	check(TitleFX.profileFor(nil) == nil and TitleFX.profileFor({ Text = "NOT A STEP" }) == nil,
		"no step, or one not listed, wears nothing")

	--==========================================================================
	say("-- 2. where the sprites stand, every title, desktop and phone --")
	--==========================================================================
	local outside, overWords, mistCore, flashing, notFaint = {}, {}, {}, {}, {}
	local samples = 0
	for _, phone in ipairs({ false, true }) do
		local scale = if phone then TITLE.PhoneScale else 1
		local box, wordSize = GameConfig.rebirthTitleLook(scale)
		local seenText = {}
		for n = 1, 303 do
			local text, step = Rebirth.titleFor(n)
			local wants = step and FX.Steps[step.Text]
			if text and wants and not seenText[text] then
				seenText[text] = true
				local profile = FX.Profiles[wants.Profile]
				local words = TextService:GetTextSize(text, wordSize, Enum.Font.FredokaOne, Vector2.new(2000, 200)).X
				local mid, half = box.X / 2, words / 2
				local k = box.Y / TITLE.Size.Y
				for i = 1, wants.Count do
					local last = nil
					for f = 0, 89 do
						local t = f * 0.1
						local p = TitleFX.pose(profile, i, wants.Count, t, box, words)
						samples += 1
						local tag = string.format("%s %s #%d", if phone then "phone" else "desk", text, i)
						if p.y - p.size / 2 < -0.5 or p.y + p.size / 2 > box.Y + 0.5 then
							table.insert(outside, string.format("%s y %.1f size %.1f in %d", tag, p.y, p.size, box.Y))
						end
						local fromMid = math.abs(p.x - mid)
						if profile.Motion == "mist" then
							-- The puff's core (its inner half) never on the words' middle fifth.
							if fromMid - p.size / 4 < words * 0.1 then
								table.insert(mistCore, tag)
							end
							if p.transparency < 0.7 then
								table.insert(notFaint, tag)
							end
						elseif fromMid < half - 5 * k then
							table.insert(overWords, string.format("%s %.0f from the middle, words %.0f", tag, fromMid, half))
						end
						if last and math.abs(p.transparency - last) > 0.2 then
							table.insert(flashing, tag)
						end
						last = p.transparency
					end
				end
			end
		end
	end
	local function first(list)
		return table.concat({ table.unpack(list, 1, math.min(4, #list)) }, "; ")
	end
	check(samples > 1000 and #outside == 0, "every sprite stays inside the title's band: ADMIN over it and the name "
		.. "under it are never touched (" .. samples .. " poses)", first(outside))
	check(#overWords == 0, "the leaves, petals and sprigs stand beside the words, not on them", first(overWords))
	check(#mistCore == 0 and #notFaint == 0, "the mist stays faint (never under 0.7 transparent) and off the words' middle",
		first(mistCore) .. " / " .. first(notFaint))
	check(#flashing == 0, "nothing flashes: no sprite changes by more than 0.2 transparency in a tenth of a second",
		first(flashing))
	local gold = FX.Profiles.gold
	local left = TitleFX.pose(gold, 1, 4, 0, TITLE.Size, 120)
	local right = TitleFX.pose(gold, 2, 4, 0, TITLE.Size, 120)
	local loose = TitleFX.pose(gold, 3, 4, 0, TITLE.Size, 120)
	check(left.art == "SprigLeft" and right.art == "SprigRight" and loose.art == gold.LeafArt
			and left.x < TITLE.Size.X / 2 and right.x > TITLE.Size.X / 2,
		"the gold titles: the left sprig left, the right one right, and the loose leaves never a sprig")
	local nature = FX.Profiles.nature
	local a = TitleFX.pose(nature, 1, 4, 0, TITLE.Size, 120)
	local b = TitleFX.pose(nature, 2, 4, 0, TITLE.Size, 120)
	local c = TitleFX.pose(nature, 3, 4, 0, TITLE.Size, 120)
	check(a.art == b.art and a.art ~= c.art and a.x < TITLE.Size.X / 2 and b.x > TITLE.Size.X / 2,
		"left and right go in pairs: each pair one picture, both sides wearing every kind")

	--==========================================================================
	say("-- 3. the four nearest move --")
	--==========================================================================
	local list = {}
	for i, d in ipairs({ 30, 5, 90, 150, 12, 60, 101, 44 }) do
		table.insert(list, { key = i, distance = d })
	end
	local moving = TitleFX.nearest(list, FX.MaxAnimated, TITLE.MaxDistance)
	local count = 0
	for _ in pairs(moving) do
		count += 1
	end
	check(count == 4 and moving[2] and moving[5] and moving[1] and moving[8] and not moving[4] and not moving[7],
		"of eight titles the four nearest within reach move (5, 12, 30 and 44 studs); 150 and 101 never")
	local few = TitleFX.nearest({ { key = "a", distance = 150 } }, 4, TITLE.MaxDistance)
	check(next(few) == nil, "a title past MaxDistance never moves")

	--==========================================================================
	say("-- 4. the layer on a title --")
	--==========================================================================
	local gui = Instance.new("BillboardGui")
	gui.Name = TITLE.Name
	gui.Size = UDim2.fromOffset(TITLE.Size.X, TITLE.Size.Y)
	gui.Parent = fixture
	local wordsLabel = Instance.new("TextLabel")
	wordsLabel.Name = "Words"
	wordsLabel.Size = UDim2.fromScale(1, 0.6)
	wordsLabel.Text = "GREEN THUMB"
	wordsLabel.Font = Enum.Font.FredokaOne
	wordsLabel.TextSize = TITLE.TextSize
	wordsLabel.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.fromScale(0, 0.6)
	sub.Size = UDim2.fromScale(1, 0.4)
	sub.Parent = gui
	local layer = TitleFX.attach(gui, FX.Profiles.nature, 4)
	local frame = gui:FindFirstChild("TitleFX")
	local sprites = frame and frame:GetChildren() or {}
	local images, panel = 0, false
	for _, s in ipairs(sprites) do
		if s:IsA("ImageLabel") then
			images += 1
			panel = panel or s.BackgroundTransparency < 1 or s.ZIndex >= wordsLabel.ZIndex
		end
	end
	check(frame and frame.ZIndex < wordsLabel.ZIndex and frame.ZIndex < sub.ZIndex and frame.BackgroundTransparency == 1
			and images == 4 and not panel,
		"four ImageLabels in a clear frame under the words and REBIRTH N: no panel")
	local lights = 0
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("Light") or d:IsA("UIStroke") or d:IsA("UIGradient") then
			lights += 1
		end
	end
	check(lights == 0, "no light, no outline, no gradient added")
	check(frame and not frame.Visible, "hidden until it is stepped")
	layer.step(os.clock())
	local clear = true
	for _, s in ipairs(sprites) do
		if s:IsA("ImageLabel") then
			-- Every id is "" (or a picture Edit never loaded): nothing drawn.
			clear = clear and (s.IsLoaded and s.Image ~= "" or s.ImageTransparency == 1)
		end
	end
	check(frame.Visible and clear, "stepped: shown, and a sprite whose picture has not loaded stays fully clear")
	layer.hide()
	check(not frame.Visible, "hidden again (Reduced FX, a trap, out of the nearest four)")
	layer.destroy()
	check(gui:FindFirstChild("TitleFX") == nil, "destroyed with its title: nothing left behind")
	local again = TitleFX.attach(gui, FX.Profiles.mystic, 2)
	gui:Destroy()
	check(again.frame.Parent == nil, "a title destroyed (a respawn, a rebirth, a player leaving) takes its layer with it")

	--==========================================================================
	say("-- 5. OwnerTitleUI --")
	--==========================================================================
	local ui = sourceOf(Scripts, "OwnerTitleUI")
	check(has(ui, "local n = owner and owner:GetAttribute(REBIRTHS)")
			and has(ui, "local _, profile, count = TitleFX.profileFor(Rebirth.title(n))")
			and not has(ui, "Words.Text") and not has(ui, "roman"),
		"the profile is the player's: Rebirths through Rebirth.title, never the words or their numeral")
	check(has(ui, "local moving = TitleFX.nearest(candidates, FX.MaxAnimated, REBIRTH.MaxDistance)")
			and has(ui, "if still or not gui.Enabled or not camera or not (adornee and adornee:IsA(\"BasePart\")) then")
			and has(ui, "layer.step(now)"),
		"moved from the one loop on the nearest four; hidden under Reduced FX, a trap's hiding, or no camera")
	local tf = sourceOf(Shared, "TitleFX")
	local loops = select(2, ui:gsub("task%.spawn%(function%(%)", "")) + select(2, tf:gsub("task%.spawn", ""))
	check(loops == 1 and not has(ui, "RenderStepped") and not has(ui, "Heartbeat") and not has(tf, "RenderStepped")
			and not has(tf, "Heartbeat") and not has(tf, "while true"),
		"one loop for every title: no frame connection or endless loop of a sprite's own")
	check(has(ui, "forget(instance :: any)") and has(ui, "if not gui.Parent then\n\t\t\t\tforget(gui)"),
		"a title gone takes its layer out of the loop")
	local untouched = true
	for _, name in ipairs({ "RebirthFX", "RebirthCelebration", "RebirthService" }) do
		local src = sourceOf(Shared, name) .. sourceOf(Scripts, name)
			.. sourceOf(game:GetService("ServerScriptService"), name)
		untouched = untouched and not has(src, "TitleFX")
	end
	check(untouched and not has(tf, "PointLight") and not has(tf, "Atmosphere") and not has(tf, "Lighting"),
		"the celebration and the aura are not touched; no light or fog anywhere")

	--==========================================================================
	say("-- 6. the \"?\" TITLES list --")
	--==========================================================================
	local LIST = FX.List
	local left = 12 + LIST.Room
	local band = Vector2.new(TITLE.Size.X, 30)
	local outRow, outLine = {}, {}
	for index, step in ipairs(TITLE.Ladder) do
		local wants = FX.Steps[step.Text]
		if wants then
			local profile = FX.Profiles[wants.Profile]
			local text = Rebirth.stepWords(index)
			local w = TextService:GetTextSize(text, 22, Enum.Font.FredokaOne, Vector2.new(2000, 200)).X
			for i = 1, wants.Count do
				for f = 0, 59 do
					local p = TitleFX.pose(profile, i, wants.Count, f * 0.15, band, w, w / 2)
					local x = math.max(p.x, -left + p.size / 2)
					if x - p.size / 2 < -left - 0.01 then
						table.insert(outRow, step.Text .. " #" .. i)
					end
					if p.y - p.size / 2 < -0.5 or p.y + p.size / 2 > band.Y + 0.5 then
						table.insert(outLine, step.Text .. " #" .. i)
					end
				end
			end
		end
	end
	check(#outRow == 0 and #outLine == 0 and LIST.Room >= 10 and LIST.LockedFade > 0 and LIST.LockedFade < 1,
		"in a row every sprite stays inside the row's left edge and the words' own line",
		table.concat(outRow, ", ") .. " / " .. table.concat(outLine, ", "))
	local row = Instance.new("Frame")
	row.Parent = fixture
	local rowWord = Instance.new("TextLabel")
	rowWord.ZIndex = 8
	rowWord.Parent = row
	local listLayer = TitleFX.attach(row, FX.Profiles.bloom, 4, {
		at = UDim2.fromOffset(left, 4),
		box = band,
		z = 7,
		words = function()
			return 120
		end,
		centre = function()
			return 60
		end,
		left = -left,
	})
	local fxFrame = row:FindFirstChild("TitleFX")
	listLayer.step(os.clock(), LIST.LockedFade)
	check(fxFrame and fxFrame.Position == UDim2.fromOffset(left, 4) and fxFrame.Size == UDim2.fromOffset(band.X, band.Y)
			and fxFrame.ZIndex == 7 and fxFrame.ZIndex < rowWord.ZIndex and fxFrame.Visible,
		"a row's layer stands on the words' line, between the row's plate (6) and its texts (8)")
	listLayer.destroy()
	local rb = sourceOf(Scripts, "RebirthUI")
	check(has(rb, "local _, fxProfile, fxCount = TitleFX.profileFor(step)")
			and has(rb, 'local word = words(row, "Word", 22, step.Colour, 8)')
			and has(rb, 'local rebirthWords = words(row, "Rebirth", 13, Color3.fromRGB(255, 236, 244), 8)')
			and has(rb, 'local bonusWords = words(row, "Bonus", 14, WHITE, 8)')
			and has(rb, 'local chip = words(row, "State", 14, WHITE, 9)')
			and has(rb, "\t\t\tz = 7,") and has(rb, "\t\t\tleft = -FX_LEFT,")
			and has(rb, "local FX_LEFT = 12 + (if fxAny then FX_LIST.Room else 0)"),
		"every row: the step's own profile (the ladder's step), its texts one ZIndex over the effects; the words "
			.. "move in for them only once any title's art is uploaded")
	check(has(rb, "\t\tif showingTitles then\n\t\t\tstepTitleFX(still)")
			and has(rb, "if still or y + r.frame.AbsoluteSize.Y < top or y > bottom then")
			and has(rb, "fx.step(now, if r.locked then FX_LIST.LockedFade else 0)") and has(rb, "r.locked = locked")
			and select(2, rb:gsub("RunService%.RenderStepped:Connect", "")) == 1,
		"moved from the panel's one loop while the list shows, only the rows in view, faded when LOCKED, none under "
			.. "Reduced FX")
end)

fixture:Destroy()
if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nTitleFXSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
