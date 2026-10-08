--!strict
-- WeatherTeaserSpec: the teaser screen is pure decoration, stands clear of the
-- road, the red line, the night shutter and every plot at its MAX level, and
-- shows the owner's two pictures (2026-10-06): their exact uploads, each at
-- rest exactly as cut at time 0, the creatures breathing, leaning and (the one
-- that floats) hovering within the brief's limits about feet that never move,
-- no two in step, A and B crossfading, SOON under them -- and no storm left.
-- Pure fixture; never starts services or opens a profile.
local Shared = game.ReplicatedStorage.SeedGame.Shared
local Teaser = require(Shared.WeatherTeaser)
local Config = require(Shared.GameConfig)
local Map = require(game.ServerScriptService.SeedGameServer.MapService)
local pass = 0
local failures: { string } = {}
local function check(ok: boolean, message: string)
	if ok then pass += 1 else table.insert(failures, message) end
end

local CFG = Config.WeatherTeaser
local CANVAS = Vector2.new(960, 540)
local SX, SY = CANVAS.X / CFG.Source.X, CANVAS.Y / CFG.Source.Y

-- THE OWNER'S UPLOADS (CrazyCozy Games, 2026-10-06), written out here rather
-- than read from GameConfig, so a slip in either one fails.
local OWNER = {
	{ Background = "rbxassetid://108987983355390" :: string?, Creatures = {
		"rbxassetid://89476211121024", "rbxassetid://139403382929852", "rbxassetid://94766727026749" } },
	{ Background = "rbxassetid://112662331303116" :: string?, Creatures = {
		"rbxassetid://124789383294317", "rbxassetid://105049401486153", "rbxassetid://85864328194602",
		"rbxassetid://99819334779640", "rbxassetid://126484898711252" } },
}

-- A part's footprint on the ground, as four corners in XZ.
local function footprint(p: BasePart): { Vector2 }
	local pts = {}
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			local v = p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x, 0, z) * 0.5)
			table.insert(pts, Vector2.new(v.X, v.Z))
		end
	end
	return pts
end

-- Exact 2D separating-axis gap between two rectangles (negative = overlap).
local function edges(poly: { Vector2 }): { Vector2 }
	local out = {}
	local order = { 1, 2, 4, 3 }
	for i = 1, 4 do
		local e = poly[order[i % 4 + 1]] - poly[order[i]]
		if e.Magnitude > 1e-6 then
			table.insert(out, Vector2.new(-e.Y, e.X).Unit)
		end
	end
	return out
end
local function gap(a: { Vector2 }, b: { Vector2 }): number
	local axes = edges(a)
	for _, v in ipairs(edges(b)) do
		table.insert(axes, v)
	end
	local best = -math.huge
	for _, ax in ipairs(axes) do
		local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
		for _, p in ipairs(a) do
			local d = p:Dot(ax)
			amin, amax = math.min(amin, d), math.max(amax, d)
		end
		for _, p in ipairs(b) do
			local d = p:Dot(ax)
			bmin, bmax = math.min(bmin, d), math.max(bmax, d)
		end
		best = math.max(best, bmin - amax, amin - bmax)
	end
	return best
end

-- How far a plot at its top level must stay from the board. The failure this
-- guards against is a real one: the first placement lost 14.7 studs to Plot_06.
local PLOT_CLEARANCE = 8

-- A label's unturned box on the canvas, in canvas pixels, and where a point of
-- it (a fraction of the box) is drawn once the engine turns it about its centre.
local function box(label: GuiObject): (Vector2, Vector2)
	local size = Vector2.new(label.Size.X.Scale * CANVAS.X + label.Size.X.Offset,
		label.Size.Y.Scale * CANVAS.Y + label.Size.Y.Offset)
	local at = Vector2.new(label.Position.X.Scale * CANVAS.X + label.Position.X.Offset,
		label.Position.Y.Scale * CANVAS.Y + label.Position.Y.Offset)
	return at - label.AnchorPoint * size, size
end
local function drawn(label: GuiObject, fraction: Vector2): Vector2
	local topLeft, size = box(label)
	local centre = topLeft + size * 0.5
	local p = topLeft + size * fraction - centre
	local r = math.rad(label.Rotation)
	return centre + Vector2.new(p.X * math.cos(r) - p.Y * math.sin(r), p.X * math.sin(r) + p.Y * math.cos(r))
end
local function near(a: Vector2, b: Vector2, tolerance: number): boolean
	return (a - b).Magnitude <= tolerance
end

local fixture = Instance.new("Folder")
local ok, err = pcall(function()
	local board = Teaser.Build(fixture)
	local parts, lights, sounds = 0, 0, 0
	local min = Vector3.new(math.huge, math.huge, math.huge)
	local max = Vector3.new(-math.huge, -math.huge, -math.huge)
	local boardPrints: { { Vector2 } } = {}
	for _, child in ipairs(board:GetDescendants()) do
		if child:IsA("Light") then lights += 1 end
		if child:IsA("Sound") then sounds += 1 end
		if child:IsA("BasePart") then
			parts += 1
			check(child.Anchored and not child.CanCollide and not child.CanQuery and not child.CanTouch,
				child.Name .. " cannot obstruct walking, combat or touches")
			for _, x in ipairs({ -1, 1 }) do for _, y in ipairs({ -1, 1 }) do for _, z in ipairs({ -1, 1 }) do
				local p = child.CFrame:PointToWorldSpace(child.Size * Vector3.new(x, y, z) * 0.5)
				min = min:Min(p); max = max:Max(p)
			end end end
			table.insert(boardPrints, footprint(child))
		end
	end
	check(parts == 7 and lights == 0 and sounds == 0, "seven parts, no lights or sounds")
	local shutterHalf = (Config.Map.CorridorWidth + Config.WorldCycle.Barrier.WidthPad) * 0.5
	check(min.X > shutterHalf or max.X < -shutterHalf,
		"entire board outside the road AND the night shutter's width, on either side")
	check(min.Z > -Config.Map.FieldFront + Config.Map.SafeLineThickness, "entire board on safe side of red line")
	check(min.Y >= Config.Map.GroundY - 0.001, "feet above ground")
	local screenPart = board:FindFirstChild("Screen") :: BasePart
	check(screenPart.Size == Vector3.new(25.6, 14.4, 0.15)
		and screenPart.CFrame.LookVector:FuzzyEq(Teaser.Placement().LookVector, 1e-4),
		"the screen keeps its size and faces the field as before")
	check(Teaser.Reach == 260 and Teaser.Tag == "SeedWeatherTeaser" and board:HasTag(Teaser.Tag),
		"Reach 260 and the Tag are unchanged")

	local state = assert(Teaser.Bind(board))
	check(state.gui.CanvasSize == CANVAS and not state.gui.AlwaysOnTop,
		"bounded 16:9 canvas, no through-wall overlay")
	check(state.gui.MaxDistance == Teaser.Reach, "the screen draws exactly as far as the client plays it")

	-- THE STORM IS GONE: its parts, its words and its clock.
	local stormNames = { Cloud = true, Rain = true, Bolt = true, Flash = true, Scan = true, Progress = true,
		Track = true, TopRule = true, Mystery = true, Title = true, Eyebrow = true, Hint = true }
	local leftovers, oldWords = 0, 0
	for _, d in ipairs(board:GetDescendants()) do
		if stormNames[d.Name] then leftovers += 1 end
		if d:IsA("TextLabel") and (d.Text:find("UPDATE") or d.Text:find("%?%?%?")) then oldWords += 1 end
	end
	local api = Teaser :: any
	check(leftovers == 0 and oldWords == 0 and api.StrikeAt == nil and api.Period == nil and api.Drops == nil,
		string.format("no cloud, rain, scanline, lightning or UPDATE SOON left (%d parts, %d words)",
			leftovers, oldWords))

	-- THE OWNER'S PICTURES, EXACTLY.
	check(#state.scenes == 2 and #state.scenes[1].creatures == 3 and #state.scenes[2].creatures == 5,
		"picture A has its three creatures and B its five")
	for s, scene in ipairs(state.scenes) do
		local name = CFG.Scenes[s].Name
		local want = OWNER[s].Background
		check(want ~= nil and state.backs[s].Image == want and CFG.Scenes[s].Background == want,
			string.format("picture %s's background is the owner's upload (%s)", name,
				if want then want else "WAITING FOR THE OWNER'S ID"))
		check(state.backs[s].ScaleType == Enum.ScaleType.Crop and state.backs[s].Size == UDim2.fromScale(1, 1),
			"picture " .. name .. "'s background fills the screen, cropped, never stretched")
		for i, c in ipairs(scene.creatures) do
			check(c.label.Image == OWNER[s].Creatures[i] and CFG.Scenes[s].Creatures[i].Image == OWNER[s].Creatures[i],
				string.format("%s%d is the owner's upload %s", name, i, OWNER[s].Creatures[i]))
			check(c.label.ZIndex == i, string.format("%s%d is drawn in the order it was cut", name, i))
		end
	end

	-- TIME 0, THE SERVER'S OWN FRAME: every creature at its recorded rect,
	-- unturned, picture A shown, B clear, no "?" haze, SOON in A's colour.
	local function atRest(where: string)
		for s, scene in ipairs(state.scenes) do
			for i, c in ipairs(scene.creatures) do
				local rect = CFG.Scenes[s].Creatures[i].Rect
				local topLeft, size = box(c.label)
				check(near(topLeft, Vector2.new(rect[1] * SX, rect[2] * SY), 0.01)
					and near(size, Vector2.new(rect[3] * SX, rect[4] * SY), 0.01) and c.label.Rotation == 0,
					string.format("%s: %s%d sits exactly at its recorded rect", where, CFG.Scenes[s].Name, i))
				local haze = true
				for _, disc in ipairs(c.discs) do
					if disc.BackgroundTransparency ~= 1 then haze = false end
				end
				check(c.label.ImageTransparency == (if s == 1 then 0 else 1) and haze,
					string.format("%s: %s%d %s, its \"?\" unlit", where, CFG.Scenes[s].Name, i,
						if s == 1 then "shown" else "clear"))
			end
		end
		check(state.backs[1].ImageTransparency == 0 and state.backs[2].ImageTransparency == 1,
			where .. ": picture A's background shown, B's clear")
		check(state.glows[1].TextColor3 == CFG.Scenes[1].Glow, where .. ": SOON glows in picture A's colour")
	end
	atRest("built")
	Teaser.Paint(state, 0, false)
	atRest("time 0")

	-- SOON: large, centred near the bottom, white LuckiestGuy, a dark ink edge,
	-- the scene's colour glowing behind it; the word from GameConfig.
	local words = state.words
	local ink = words:FindFirstChildOfClass("UIStroke")
	local soon = words.Parent :: Frame
	local scale = soon:FindFirstChildOfClass("UIScale")
	check(words.Text == CFG.Words.Soon and CFG.Words.Soon == "SOON" and words.Font == Enum.Font.LuckiestGuy
		and words.TextColor3 == Color3.new(1, 1, 1) and ink ~= nil and ink.Color == CFG.Ink,
		"SOON is white LuckiestGuy with a dark ink edge, its word from GameConfig")
	check(soon.AnchorPoint == Vector2.new(0.5, 1) and soon.Position.X.Scale == 0.5 and soon.Position.Y.Scale == 1
		and soon.Position.Y.Offset > -20 and scale ~= nil and words.TextSize * scale.Scale >= 110,
		"SOON is large and centred near the bottom")
	local glowsBehind = #state.glows >= 2
	for _, g in ipairs(state.glows) do
		if g.ZIndex >= words.ZIndex or g.Text ~= words.Text then glowsBehind = false end
	end
	check(glowsBehind, "SOON's glow sits behind the word")

	-- THE CROSSFADE: A holds, fades to B, B holds, fades back; eased, so no
	-- frame jumps.
	local H, F = CFG.Hold, CFG.Fade
	local loop = 2 * (H + F)
	check(Teaser.Mix(0) == 0 and Teaser.Mix(H - 0.01) == 0 and math.abs(Teaser.Mix(H + F * 0.5) - 0.5) < 1e-9
		and Teaser.Mix(H + F + 0.01) == 1 and Teaser.Mix(2 * H + F - 0.01) == 1
		and math.abs(Teaser.Mix(2 * H + 1.5 * F) - 0.5) < 1e-9 and Teaser.Mix(loop) == 0,
		"A holds, fades to B, B holds, fades back")
	check(math.abs(H - 8) <= 1 and F == 1.5, "about 8 s a picture and a 1.5 s crossfade")
	local steepest = 0
	local t = 0
	while t < loop do
		steepest = math.max(steepest, math.abs(Teaser.Mix(t + Teaser.Interval) - Teaser.Mix(t)))
		t += Teaser.Interval / 3
	end
	check(steepest < 0.07, string.format("the fade never jumps (%.3f of the screen per frame at most)", steepest))
	local mid = 1000 * loop + H + F * 0.5
	Teaser.Paint(state, mid, false)
	local fading = math.abs(state.backs[2].ImageTransparency - 0.5) < 1e-3
	local moving = 0
	for s, scene in ipairs(state.scenes) do
		for _, c in ipairs(scene.creatures) do
			if math.abs(c.label.ImageTransparency - 0.5) >= 1e-3 then fading = false end
			if c.label.Rotation ~= 0 then moving += 1 end
		end
	end
	check(fading, "mid-fade, both pictures are half on the screen")
	check(moving == 8, string.format("the creatures keep moving through the fade (%d of 8 turned)", moving))
	local blend = CFG.Scenes[1].Glow:Lerp(CFG.Scenes[2].Glow, 0.5)
	local glowColour = state.glows[1].TextColor3
	check(math.abs(glowColour.R - blend.R) < 1e-3 and math.abs(glowColour.G - blend.G) < 1e-3
		and math.abs(glowColour.B - blend.B) < 1e-3, "SOON's glow blends the two colours in the fade")
	Teaser.Paint(state, 1000 * loop + 2, false)
	local cleared = true
	for _, c in ipairs(state.scenes[2].creatures) do
		if c.label.ImageTransparency ~= 1 then cleared = false end
		for _, disc in ipairs(c.discs) do
			if disc.BackgroundTransparency ~= 1 then cleared = false end
		end
	end
	check(cleared and state.backs[2].ImageTransparency == 1, "while A holds, B is fully clear, haze and all")

	-- THE MOTION: a pure function of the time, inside the brief's limits, about
	-- feet that never move, the floater alone hovering, no two in step.
	local periods: { number } = {}
	for s, scene in ipairs(CFG.Scenes) do
		for i, c in ipairs(scene.Creatures) do
			check(c.Period >= 3.5 and c.Period <= 6, string.format("%s%d breathes every 3.5 to 6 s (%.1f)",
				scene.Name, i, c.Period))
			for _, p in ipairs(periods) do
				check(math.abs(p - c.Period) >= 0.2, string.format("%s%d's period is its own", scene.Name, i))
			end
			table.insert(periods, c.Period)
		end
	end
	local floaters = 0
	for _, scene in ipairs(CFG.Scenes) do
		for _, c in ipairs(scene.Creatures) do
			if (c.Bob or 0) > 0 then floaters += 1 end
		end
	end
	local spiky = CFG.Scenes[2].Creatures[3]
	check(floaters == 1 and spiky.Bob ~= nil and spiky.Bob >= 0.02 and spiky.Bob <= 0.04,
		"only B's floating spiky one hovers, a little more than a small bob; the rest stay grounded")
	check(CFG.Breath == 0.025 and CFG.BreathX > 0 and CFG.BreathX < 1 and CFG.Sway == 1.5,
		"breath to 1.025 high (a little less wide), lean 1.5 degrees either way")

	-- Sampled at the client's own rate across a minute, then on the server's
	-- real clock (about two billion seconds).
	local samples: { number } = {}
	t = 2.5
	while t < 62.5 do
		table.insert(samples, t)
		t += Teaser.Interval
	end
	for k = 0, 40 do
		table.insert(samples, 1.76e9 + k * 0.37)
	end
	local inLimits, feetFixed, inside, pure = true, true, true, true
	local worstFeet, worstOut, worstStep = 0, 0, 0
	local glowFollows = true
	local overshoot = 6 -- canvas pixels: the cut-outs' feathered, clear edge (see GameConfig)
	local previous: { [ImageLabel]: { at: number, corners: { Vector2 } } } = {}
	local sequences: { [ImageLabel]: { number } } = {}
	for n, time in ipairs(samples) do
		Teaser.Paint(state, time, false)
		local mix = Teaser.Mix(time)
		for s, scene in ipairs(state.scenes) do
			local share = if s == 1 then 1 - mix else mix
			if share <= 0 then continue end
			for i, c in ipairs(scene.creatures) do
				local cfg = CFG.Scenes[s].Creatures[i]
				local pose = Teaser.Pose(cfg, time)
				local again = Teaser.Pose(cfg, time)
				if pose.ScaleX ~= again.ScaleX or pose.Rotation ~= again.Rotation or pose.Lift ~= again.Lift then
					pure = false
				end
				if pose.ScaleY < 1 or pose.ScaleY > 1 + CFG.Breath + 1e-9 or pose.ScaleX < 1
					or pose.ScaleX - 1 > (pose.ScaleY - 1) + 1e-9 or math.abs(pose.Rotation) > CFG.Sway + 1e-9
					or pose.Lift < 0 or pose.Lift > (cfg.Bob or 0) + 1e-9 or pose.Glow < 0 or pose.Glow > 1 then
					inLimits = false
				end
				-- The feet, where the engine draws them, against where they stand.
				local rest = Vector2.new(cfg.Feet[1] * SX, cfg.Feet[2] * SY - pose.Lift * cfg.Rect[4] * SY)
				local feet = drawn(c.label, c.label.AnchorPoint)
				local off = (feet - rest).Magnitude
				worstFeet = math.max(worstFeet, off)
				if off > 0.01 then feetFixed = false end
				-- The turned box against the screen's edges.
				local corners = {}
				for _, f in ipairs({ Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) }) do
					local p = drawn(c.label, f)
					table.insert(corners, p)
					worstOut = math.max(worstOut, -p.X, -p.Y, p.X - CANVAS.X, p.Y - CANVAS.Y)
				end
				if worstOut > overshoot then inside = false end
				-- Calm: no corner moves more than a pixel and a half from one frame
				-- to the next (frames this creature was on the screen for).
				local before = previous[c.label]
				if before and before.at == n - 1 and samples[n] - samples[n - 1] < Teaser.Interval * 1.01 then
					for k, p in ipairs(corners) do
						worstStep = math.max(worstStep, (p - before.corners[k]).Magnitude)
					end
				end
				previous[c.label] = { at = n, corners = corners }
				local seq = sequences[c.label] or {}
				sequences[c.label] = seq
				table.insert(seq, pose.Glow)
				-- The "?" haze follows the breath: clear at rest, whiter as it fills.
				local haze = c.discs[1].BackgroundTransparency
				if math.abs((1 - haze) - (1 - c.discs[#c.discs].BackgroundTransparency)) > 1e-6
					or (pose.Glow * share < 1e-6) ~= (haze >= 1 - 1e-9) then
					glowFollows = false
				end
			end
		end
	end
	check(pure, "the pose is a pure function of the time")
	check(inLimits, "every pose stays within the breath, lean and hover limits")
	check(feetFixed, string.format("the feet never move (worst %.4f px)", worstFeet))
	check(inside, string.format("every creature stays on the screen (its clear edge out by %.1f px at most)", worstOut))
	check(worstStep < 1.5, string.format("nothing jumps: %.2f px a frame at most", worstStep))
	check(glowFollows, "the \"?\" haze brightens with each breath and is clear at rest")
	-- No two in step: within each picture, every pair's breaths part ways.
	for s, scene in ipairs(state.scenes) do
		for i = 1, #scene.creatures do
			for j = i + 1, #scene.creatures do
				local a, b = sequences[scene.creatures[i].label], sequences[scene.creatures[j].label]
				local apart = 0
				for k = 1, math.min(#a, #b) do
					apart = math.max(apart, math.abs(a[k] - b[k]))
				end
				check(apart > 0.5, string.format("%s%d and %s%d never breathe in step (apart by up to %.2f)",
					CFG.Scenes[s].Name, i, CFG.Scenes[s].Name, j, apart))
			end
		end
	end
	-- The same time twice is the same frame, whatever came between.
	Teaser.Paint(state, 1.76e9 + 3.3, false)
	local first = state.scenes[1].creatures[1].label.Position
	Teaser.Paint(state, 1.76e9 + 9.9, false)
	Teaser.Paint(state, 1.76e9 + 3.3, false)
	check(state.scenes[1].creatures[1].label.Position == first, "a frame depends on its time alone")

	-- REDUCED FX: the still card, picture A at rest, whatever the time.
	Teaser.Paint(state, 1.76e9 + 9.5, true)
	atRest("Reduced FX")
	Teaser.Paint(state, 1.76e9 + 100, true)
	atRest("Reduced FX later")

	-- EVERY PLOT AT ITS TOP LEVEL, placed exactly as MapService.Init places them.
	local gapRad = math.rad(Config.Map.RoadGapDegrees)
	local step = (2 * math.pi - gapRad) / Config.MaxPlots
	local depth = Config.plotDepthFor(Config.plotRowsForTier(1))
	for i = 1, Config.MaxPlots do
		local angle = math.pi + gapRad * 0.5 + (i - 0.5) * step
		local r = Config.Map.PlotRingInner + depth * 0.5
		local pos = Vector3.new(math.sin(angle) * r, Config.Map.GroundY, math.cos(angle) * r)
		local plot = Instance.new("Model")
		plot.Parent = fixture
		plot:SetAttribute(Config.Attributes.PlotId, i)
		plot:SetAttribute("PlotCF", CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)))
		plot:SetAttribute("Depth", depth)
		Map.ResizePlot(plot, #Config.PlotTiers)
		local nearest = math.huge
		for _, p in ipairs(plot:GetDescendants()) do
			if p:IsA("BasePart") then
				local fp = footprint(p)
				for _, bp in ipairs(boardPrints) do
					nearest = math.min(nearest, gap(fp, bp))
				end
			end
		end
		check(nearest >= PLOT_CLEARANCE, string.format(
			"screen stands %d+ studs clear of max-level plot %d (%.1f)", PLOT_CLEARANCE, i, nearest))
		plot:Destroy()
	end

	local replacement = Teaser.Build(fixture)
	check(board.Parent == nil and #fixture:GetChildren() == 1, "rebuild replaces, never duplicates")
	local again = Teaser.Bind(replacement)
	check(again ~= nil and #Teaser.Pictures(again :: any) == 10, "rebuilt screen still binds, all ten pictures")
	local incomplete = Instance.new("Model")
	check(Teaser.Bind(incomplete) == nil, "incomplete streaming model can retry")
	incomplete:Destroy()
end)
fixture:Destroy()
if not ok then table.insert(failures, tostring(err)) end
return ("WeatherTeaserSpec: %d passed, %d failed%s"):format(pass, #failures,
	if #failures > 0 then "\n" .. table.concat(failures, "\n") else "")
