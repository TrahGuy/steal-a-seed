--==============================================================================
-- RainBeaconSpec (2026-10-11, the owner's item 8)
--
-- The rain biome's beacon (Shared/RainBeacon, RainBeacon.client,
-- GameConfig.Weather.Beacon): a tall, soft rain-blue column of light over the
-- bridge while the temporary biome is open. Edit mode; nothing is left behind.
--
--   1. where it stands: the middle of the bridge's deck, on its top
--   2. over everything: its light far over every cloud bank the rain builds
--   3. in sight from every plot, the hub and the road, past the map, the open
--      biome and the hub's standing set
--   4. shown while the biome is open, and only then; a fade either way
--   5. light, not a thing: one invisible anchor nothing collides with, finds
--      or touches, one self-lit camera-facing billboard drawn at any distance
--      (never over the world), no HUD, no arrow, no sign
--   6. Reduced FX keeps it, still and narrower; it stays plainly visible
--   7. lighting it: what is drawn at each strength
--   8. the wiring: the client's alone, a late joiner sees it at once
--   9. no clash: clear of the obby's course, rain-blue beside the Mist's mint,
--      no light of the world touched
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RainBeacon = require(Shared:WaitForChild("RainBeacon"))
local RainClouds = require(Shared:WaitForChild("RainClouds"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))

local W = GameConfig.Weather
local B = W.Biome
local CFG = W.Beacon
local MAP = GameConfig.Map

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	if not found then
		return ""
	end
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local stage = Instance.new("Folder")
stage.Name = "ZZRainBeaconSpec"
stage.Archivable = false
stage.Parent = Workspace

local function body()
	local foot = RainBeacon.Foot()
	-- The light at full strength: from In of its length over the deck to the
	-- last Out of it.
	local litHigh = foot.Y + CFG.Height * (1 - CFG.Out)
	local widest = 0
	for _, layer in ipairs(CFG.Layers) do
		widest = math.max(widest, layer.Width * (1 + CFG.Pulse.Amount))
	end

	--==========================================================================
	say("1. Where it stands")
	--==========================================================================
	check(foot.X > B.Deck.X0 and foot.X < B.Deck.X1 and math.abs(foot.X - (B.Deck.X0 + B.Deck.X1) / 2) < 1e-6
			and foot.Z == B.Deck.Z and math.abs(foot.Y - (MAP.GroundY + B.Deck.Y)) < 1e-6,
		string.format("the middle of the bridge's deck, on its top (%s)", tostring(foot)))
	check(CFG.In > 0 and CFG.In * CFG.Height >= 12 and CFG.Out > 0 and CFG.In + CFG.Out < 0.5,
		string.format("its light comes in from the deck over %.0f studs (a walker on the bridge stands in its faint foot) "
			.. "and fades into the sky over the last %.0f", CFG.In * CFG.Height, CFG.Out * CFG.Height))

	--==========================================================================
	say("2. Over everything")
	--==========================================================================
	local cloudTop, banks = -math.huge, 0
	for _, bank in ipairs(RainClouds.banks()) do
		banks += 1
		for _, puff in ipairs(bank.puffs) do
			cloudTop = math.max(cloudTop, bank.at.Y + puff.offset.Y + puff.diameter / 2 + W.Clouds.Bob.Studs)
		end
	end
	check(banks > 0 and litHigh > cloudTop + 100,
		string.format("its full light reaches %.0f studs up, %.0f over the highest cloud bank's top (%d banks)", litHigh,
			litHigh - cloudTop, banks))

	--==========================================================================
	say("3. In sight from every plot, the hub and the road")
	--==========================================================================
	-- The map as the plugin builds it in Edit, the biome as the event builds it,
	-- and the hub's standing set from its builders.
	local map = Workspace:FindFirstChild(MAP.FolderName)
	if not map then
		require(Server:WaitForChild("MapService")).Init()
		map = Workspace:FindFirstChild(MAP.FolderName)
	end
	local RainBiome = require(Server:WaitForChild("RainBiome"))
	local biome = RainBiome.Build(stage)
	RainBiome.SetEntry(biome, true)
	local HUB = MAP.EventHub
	local sur = require(Shared:WaitForChild("MistSurroundModel")).build(HUB.NpcAnchor, nil)
	sur.Parent = stage
	local dress = require(Shared:WaitForChild("MistDeckModel")).build(stage)
	local him = require(Shared:WaitForChild("MosskeeperModel")).build(HUB.NpcAnchor, stage)
	local setParts = {}
	for _, m in ipairs({ sur, dress, him }) do
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(setParts, d)
			end
		end
	end
	-- A segment through a part's box (the set's parts are found by no ray).
	local function crosses(a, b, p)
		local la, lb, h = p.CFrame:PointToObjectSpace(a), p.CFrame:PointToObjectSpace(b), p.Size * 0.5
		local t0, t1 = 0, 1
		for _, axis in ipairs({ "X", "Y", "Z" }) do
			local s, d, lim = la[axis], lb[axis] - la[axis], h[axis]
			if math.abs(d) < 1e-9 then
				if s < -lim or s > lim then
					return false
				end
			else
				local u0, u1 = (-lim - s) / d, (lim - s) / d
				if u0 > u1 then
					u0, u1 = u1, u0
				end
				t0, t1 = math.max(t0, u0), math.min(t1, u1)
				if t0 > t1 then
					return false
				end
			end
		end
		return true
	end
	-- The ring of plots as MapService.Init lays it out (EventHubSpec's): each
	-- gate's frame, local -Z toward the hub.
	local nPlots = 6
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(GameConfig.StartingPlotTier))
	local cams = {}
	do
		local gap = math.rad(MAP.RoadGapDegrees)
		local step = (math.pi * 2 - gap) / nPlots
		local first = math.pi + gap * 0.5
		for id = 1, nPlots do
			local angle = first + (id - 0.5) * step
			local r = MAP.PlotRingInner + startDepth * 0.5
			local pos = Vector3.new(math.sin(angle) * r, MAP.GroundY, math.cos(angle) * r)
			local gate = CFrame.lookAt(pos, Vector3.new(0, MAP.GroundY, 0)) * CFrame.new(0, 0, -startDepth * 0.5)
			table.insert(cams, { name = string.format("plot %d's gate camera", id),
				at = (gate * CFrame.new(0, 8.5, 12)).Position })
			table.insert(cams, { name = string.format("plot %d's back camera", id),
				at = (gate * CFrame.new(0, 8.5, startDepth + 12)).Position })
		end
	end
	local deckTop = MAP.GroundY + HUB.FloorY
	for _, d in ipairs({ { "north", 0, 1 }, { "east", 1, 0 }, { "south", 0, -1 }, { "west", -1, 0 } }) do
		table.insert(cams, { name = "the hub's " .. d[1] .. " side",
			at = Vector3.new(HUB.Centre.X + d[2] * 12, deckTop + 5, HUB.Centre.Z + d[3] * 12) })
	end
	for _, z in ipairs({ -MAP.FieldFront - 5, -150, -300 }) do
		table.insert(cams, { name = string.format("the road at z %d", z), at = Vector3.new(0, MAP.GroundY + 5, z) })
	end
	local target = foot + Vector3.new(0, CFG.Height * 0.7, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map, biome }
	local blocked, by = 0, nil
	for _, cam in ipairs(cams) do
		local hit = Workspace:Raycast(cam.at, target - cam.at, params)
		local through = nil
		for _, p in ipairs(setParts) do
			if crosses(cam.at, target, p) then
				through = p.Name
				break
			end
		end
		if hit or through then
			blocked += 1
			by = by or string.format("%s: %s", cam.name, if hit then hit.Instance:GetFullName() else through)
		end
	end
	check(map ~= nil and #cams >= 19 and blocked == 0,
		string.format("from every plot's gate and back, the hub's four sides and down the road (%d eyes), %.0f studs up "
			.. "it is in sight: past the map, the open biome and the hub's set", #cams, CFG.Height * 0.7), by)

	--==========================================================================
	say("4. Shown while the biome is open, and only then")
	--==========================================================================
	check(RainBeacon.Shown("active") and not RainBeacon.Shown("opening") and not RainBeacon.Shown("closing")
			and not RainBeacon.Shown(nil) and not RainBeacon.Shown("rain") and not RainBeacon.Shown(true),
		"open (\"active\") shows it; opening, closing and clear weather never do")
	local up = RainBeacon.Step(0, true, CFG.FadeSeconds / 2)
	check(math.abs(up - 0.5) < 1e-6 and RainBeacon.Step(0, true, CFG.FadeSeconds) == 1
			and RainBeacon.Step(1, false, CFG.FadeSeconds) == 0 and RainBeacon.Step(1, true, 5) == 1
			and RainBeacon.Step(0, false, 5) == 0 and CFG.FadeSeconds > 0 and CFG.FadeSeconds <= 3,
		string.format("it fades in and out over %s s, never past full or nothing", tostring(CFG.FadeSeconds)))

	--==========================================================================
	say("5. Light, not a thing")
	--==========================================================================
	local model = RainBeacon.Build(stage)
	local partsN, boards, frames, fades, others, solid = 0, {}, {}, 0, {}, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			partsN += 1
			if not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch or d.CastShadow or d.Transparency < 1 then
				solid += 1
			end
		elseif d:IsA("BillboardGui") then
			table.insert(boards, d)
		elseif d.ClassName == "Frame" then
			table.insert(frames, d)
		elseif d:IsA("UIGradient") then
			fades += 1
		else
			table.insert(others, d.ClassName)
		end
	end
	check(model.Name == RainBeacon.Name and partsN == 1 and solid == 0 and #others == 0 and #boards == 1
			and #frames == #CFG.Layers and fades == #CFG.Layers and #CFG.Layers <= 6
			and #model:GetDescendants() == 2 + 2 * #CFG.Layers,
		string.format("one invisible anchor that nothing collides with, finds or touches, one billboard on it, a plain "
			.. "faded frame per layer: %d instances, no light, particle, sound, text, picture or button",
			#model:GetDescendants()), table.concat(others, ","))
	local board = boards[1]
	local anchor = model.PrimaryPart
	local wide = RainBeacon.BoardWidth()
	local boardOk = board ~= nil and anchor ~= nil and (anchor.Position - foot).Magnitude < 1e-3
		and (board.Adornee == anchor or board.Parent == anchor) and not board.AlwaysOnTop and board.LightInfluence == 0
		and board.Size == UDim2.new(wide, 0, CFG.Height, 0) and board.SizeOffset == Vector2.new(0, 0)
		and board.StudsOffsetWorldSpace == Vector3.new(0, CFG.Height / 2, 0) and board.StudsOffset == Vector3.new(0, 0, 0)
		and board.MaxDistance == math.huge and not board.Enabled
	check(boardOk, string.format("one billboard, %.1f by %d studs standing on the deck: it faces the camera from every "
		.. "side, is hidden by the world like any light (never drawn over it), self-lit (the rain's overcast, the night "
		.. "and the Mist's look never dim it), drawn at any distance, dark until lit", wide, CFG.Height))
	local fadeOk, order = true, {}
	for i, layer in ipairs(CFG.Layers) do
		local frame = board and board:FindFirstChild(layer.Name)
		local fade = frame and frame:FindFirstChildOfClass("UIGradient")
		local k = fade and fade.Transparency.Keypoints
		fadeOk = fadeOk and frame ~= nil and frame:IsA("Frame") and fade ~= nil and fade.Rotation == 90 and #k == 4
			and k[1].Value == 1 and k[2].Value == 0 and k[3].Value == 0 and k[4].Value == 1
			and math.abs(k[2].Time - CFG.Out) < 1e-6 and math.abs(k[3].Time - (1 - CFG.In)) < 1e-6
			and frame.BackgroundColor3 == layer.Colour and frame.BorderSizePixel == 0 and not frame.Visible
			and math.abs(frame.Size.X.Scale * wide - layer.Width) < 1e-6 and frame.Size.Y.Scale == 1
		order[i] = frame and frame.ZIndex or 0
	end
	for i = 2, #order do
		fadeOk = fadeOk and order[i] < order[i - 1]
	end
	check(fadeOk, "each layer a frame of its own colour and width, faded out into the sky and in from the deck along its "
		.. "length, the core on top and the haze behind")

	--==========================================================================
	say("6. Reduced FX keeps it, still and narrower")
	--==========================================================================
	local stillOk, moves, drawnStill, coreClear = true, false, 0, 1
	for _, layer in ipairs(CFG.Layers) do
		for _, t in ipairs({ 0, 0.7, 1.9, 3.3, 100.25 }) do
			if RainBeacon.Width(layer, t, true) ~= layer.Width then
				stillOk = false
			end
			local w = RainBeacon.Width(layer, t, false)
			if math.abs(w - layer.Width) > 1e-3 then
				moves = true
			end
			if w < layer.Width * (1 - CFG.Pulse.Amount) - 1e-6 or w > layer.Width * (1 + CFG.Pulse.Amount) + 1e-6 then
				stillOk = false
			end
		end
		if RainBeacon.Drawn(layer, true) then
			drawnStill += 1
			coreClear = math.min(coreClear, layer.Transparency)
		end
	end
	local richGone = true
	for _, layer in ipairs(CFG.Layers) do
		if layer.Rich and RainBeacon.Drawn(layer, true) then
			richGone = false
		end
		if not RainBeacon.Drawn(layer, false) then
			richGone = false
		end
	end
	check(stillOk and moves and CFG.Pulse.Amount > 0 and CFG.Pulse.Amount <= 0.15,
		string.format("it breathes (its width by %d%%, every %.1f s), and is still under Reduced FX",
			math.floor(CFG.Pulse.Amount * 100 + 0.5), CFG.Pulse.Seconds))
	check(richGone and drawnStill >= 2 and coreClear <= 0.3,
		string.format("Reduced FX drops only the widest layer: %d of %d still drawn, the core at %.2f transparency -- "
			.. "plainly visible", drawnStill, #CFG.Layers, coreClear))

	--==========================================================================
	say("7. Lighting it")
	--==========================================================================
	local function states()
		local s = { board = board.Enabled }
		for _, frame in ipairs(frames) do
			s[frame.Name] = { on = frame.Visible, w = frame.Size.X.Scale * wide, t = frame.BackgroundTransparency }
		end
		return s
	end
	RainBeacon.Apply(model, 1, 0, false)
	local full = states()
	RainBeacon.Apply(model, 1, 0, true)
	local still = states()
	RainBeacon.Apply(model, 0.5, 0, false)
	local half = states()
	RainBeacon.Apply(model, 0, 0, false)
	local none = states()
	local lightOk = full.board and still.board and half.board and not none.board
	for _, layer in ipairs(CFG.Layers) do
		local f, s, h, n = full[layer.Name], still[layer.Name], half[layer.Name], none[layer.Name]
		lightOk = lightOk and f ~= nil and f.on and math.abs(f.t - layer.Transparency) < 1e-6
			and math.abs(f.w - RainBeacon.Width(layer, 0, false)) < 1e-6
			and s.on == not layer.Rich and (layer.Rich or math.abs(s.w - layer.Width) < 1e-6)
			and h.on and math.abs(h.t - (1 - (1 - layer.Transparency) * 0.5)) < 1e-6 and not n.on
	end
	check(lightOk, "lit at full every layer at its own transparency; half-faded, halfway; under Reduced FX the widest "
		.. "off and the rest still; at nothing, dark")
	model:Destroy()

	--==========================================================================
	say("8. The wiring")
	--==========================================================================
	local client = sourceOf(Scripts, "RainBeacon")
	check(has(client, "local STATE = GameConfig.Weather.Attributes.State")
			and has(client, "local level = if RainBeacon.Shown(Workspace:GetAttribute(STATE)) then 1 else 0")
			and has(client, "level = RainBeacon.Step(level, RainBeacon.Shown(Workspace:GetAttribute(STATE)), dt)")
			and has(client, "beacon = RainBeacon.Build(Workspace)")
			and has(client, "RainBeacon.Apply(current, level, os.clock(), StatusText.reducedMotion())")
			and has(client, "if level <= 0 then\n\t\t\tcurrent:Destroy()"),
		"each client draws its own from the Weather State, at full at once for a late joiner, faded otherwise, still "
			.. "under Reduced FX, gone when faded out")
	check(has(client, "local previous = playerScripts:FindFirstChild(\"RainBeaconCleanup\")")
			and has(client, "script.Destroying:Connect(cleanup)"),
		"a re-run of the script hands the old copy's beacon over: never two")
	local serverMentions = {}
	for _, d in ipairs(ServerScriptService:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			local ok, src = pcall(function()
				return d.Source
			end)
			if ok and has(src, "RainBeacon") then
				table.insert(serverMentions, d.Name)
			end
		end
	end
	check(#serverMentions == 0, "the server holds no part of it", table.concat(serverMentions, ","))

	--==========================================================================
	say("9. No clash")
	--==========================================================================
	local maxZ = -math.huge
	local function walk(t, depth)
		if type(t) ~= "table" or depth > 6 then
			return
		end
		for k, v in pairs(t) do
			if typeof(v) == "Vector3" and (k == "at" or k == "At" or k == "replayAt" or k == "returnAt") then
				maxZ = math.max(maxZ, v.Z)
			elseif type(v) == "table" then
				walk(v, depth + 1)
			end
		end
	end
	walk(ObbyData, 0)
	-- Its widest piece is 18 studs long (ObbyData's spinners): 9 either side
	-- of its anchor, and a few more for luck (RainEventSpec's measure).
	local courseZ = ObbyData.Origin.Z + maxZ + 12
	check(foot.Z - widest / 2 - courseZ >= 20,
		string.format("clear of the obby's course: its widest light ends %.0f studs north of it",
			foot.Z - widest / 2 - courseZ))
	local mint = EnchantedMistConfig.Sign.Colour
	local blue = true
	for _, layer in ipairs(CFG.Layers) do
		local c = layer.Colour
		blue = blue and c.B >= c.G and c.G > c.R and c.B > mint.B
	end
	check(blue and mint.G > mint.B, "rain-blue, every layer: never the Mist sign's mint")
	local module = sourceOf(Shared, "RainBeacon")
	local hud = false
	for _, word in ipairs({ "ScreenGui", "SurfaceGui", "TextLabel", "TextButton", "ImageLabel", "ImageButton",
		"AlwaysOnTop = true", "PlayerGui" }) do
		if has(module, word) or has(client, word) then
			hud = true
		end
	end
	check(module ~= "" and not has(module, "Lighting") and not has(client, "Lighting") and not hud,
		"it touches no light of the world (WorldClock's, the rain's and the Mist's own) and draws nothing on the HUD: "
			.. "no screen, no words, no pictures, never over the world")
end

local ok, err = pcall(body)
stage:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nRainBeaconSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
