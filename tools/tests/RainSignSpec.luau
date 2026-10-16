--==============================================================================
-- RainSignSpec (2026-10-16, the owner: "add a Huge Rain Text biome with a
-- timer"; their picks: over the rain bridge, "RAIN BIOME" over "Next rain in
-- 42:10", "OPEN · Closes in 2:31" while it is open)
--
-- The RAIN BIOME sign (Shared/RainSign, RainSign.client, GameConfig.Weather
-- .Sign) and the hourly weather's next mark it counts down to. Edit mode;
-- nothing is left behind.
--
--   1. its words in every state, the countdown rounded up
--   2. where it stands: over the foot of the bridge, its bottom edge over the
--      gate's top at every size
--   3. its words fit their box in its own face
--   4. read from afar, never huge up close (the OBBY sign's rule)
--   5. in sight from every plot, the hub and the road's mouth, within reach,
--      and over neither the hub's ENCHANTED MIST sign nor the OBBY sign on a
--      desktop's or a tablet's screen from any plot (a phone's counted)
--   6. the wiring: the client's alone, from the published weather and mark,
--      a repaint a second, nothing sent
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RainSign = require(Shared:WaitForChild("RainSign"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistStatus = require(Shared:WaitForChild("EnchantedMistStatus"))

local W = GameConfig.Weather
local B = W.Biome
local SIGN = W.Sign
local WORDS = SIGN.Words
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
stage.Name = "ZZRainSignSpec"
stage.Archivable = false
stage.Parent = Workspace

local function body()
	--==========================================================================
	say("1. Its words")
	--==========================================================================
	local now = 1000
	local function line(t)
		return RainSign.describe(t, now)
	end
	check(SIGN.Header == "RAIN BIOME" and WORDS.Next == "Next rain in %s" and WORDS.Open == "OPEN \u{00B7} Closes in %s",
		"the owner's words: RAIN BIOME, \"Next rain in\", \"OPEN · Closes in\"")
	check(line({ nextAt = now + 2530 }) == "Next rain in 42:10" and line({ nextAt = now + 3600 }) == "Next rain in 60:00"
			and line({ nextAt = now + 59.2 }) == "Next rain in 1:00" and line({ nextAt = now + 0.2 }) == "Next rain in 0:01",
		"no weather: Next rain in 42:10 -- an hour reads 60:00, a part second rounds up, never 0:00 while time is left",
		line({ nextAt = now + 0.2 }))
	check(line({ nextAt = now }) == WORDS.Starting and line({ nextAt = now - 3 }) == WORDS.Starting
			and WORDS.Starting == "Starting\u{2026}",
		"the mark come, its start a moment off: Starting…")
	check(line({}) == nil and line({ state = "rain" }) == nil,
		"no weather and no schedule (the scheduler off): nothing under the header")
	check(line({ state = "opening", endsAt = now + 177, nextAt = now + 3600 }) == WORDS.Opening
			and WORDS.Opening == "Opening\u{2026}",
		"opening (the rain falling, the entrance not yet open): Opening…")
	check(line({ state = "active", endsAt = now + 151, nextAt = now + 3449 }) == "OPEN \u{00B7} Closes in 2:31"
			and line({ state = "active", endsAt = now + 1800 }) == "OPEN \u{00B7} Closes in 30:00",
		"open: OPEN · Closes in 2:31 -- to the event's own end, not the next mark (and the console's longest, 30:00)",
		line({ state = "active", endsAt = now + 151 }))
	check(line({ state = "active", endsAt = now }) == WORDS.Closing and line({ state = "active" }) == WORDS.Closing
			and line({ state = "closing", nextAt = now + 3400 }) == WORDS.Closing and WORDS.Closing == "Closing\u{2026}",
		"its time up, or closing (the biome fading): Closing…")

	--==========================================================================
	say("2. Where it stands")
	--==========================================================================
	local at = RainSign.at()
	local tall = RainSign.tall()
	local bottom = at.Y - tall / 2
	local south = B.Deck.Z - B.Deck.Width / 2
	check(at.Z == SIGN.Z and at.Z > south + 5 and at.Z < B.Deck.Z and at.X > B.Ramp.X0 and at.X < B.Gate.X
			and at.X > B.Landing.X and tall == SIGN.Height + SIGN.SubHeight,
		string.format("over the foot of the bridge: x %.0f, between the ramp's foot (%d) and its gate (%d), over the "
			.. "deck's south half (z %.0f; the deck runs %.0f to %.0f)", at.X, B.Ramp.X0, B.Gate.X, at.Z, south,
			B.Deck.Z + B.Deck.Width / 2))
	check(math.abs(bottom - (MAP.GroundY + SIGN.BottomAbove)) < 1e-9 and bottom >= MAP.GroundY + B.Gate.Height + 2,
		string.format("its bottom edge %.0f up, %.0f over the gate's top: the bridge, its gate and its walkers never "
			.. "meet it", bottom - MAP.GroundY, bottom - MAP.GroundY - B.Gate.Height))
	local bottoms = true
	for _, scale in ipairs({ 0.5, 1, 1.7, 3, 6 }) do
		local w, h, lift = RainSign.frame(scale)
		local b = at.Y + lift - h / 2
		bottoms = bottoms and math.abs(b - bottom) < 1e-9 and math.abs(w - SIGN.Width * scale) < 1e-9
	end
	check(bottoms, "at every size its bottom edge stays where it is built: it grows upward")
	local obby = ObbyData.Entrance.At
	local apart = (Vector3.new(at.X, 0, at.Z) - Vector3.new(obby.X, 0, obby.Z)).Magnitude
	check(apart > 60, string.format("%.0f studs along the island's edge from the OBBY sign over the obby's arch", apart),
		apart)

	--==========================================================================
	say("3. Its words fit their box")
	--==========================================================================
	local function aspect(text)
		local size = TextService:GetTextSize(text, 100, FloatingSign.Font, Vector2.new(100000, 1000))
		return size.X / size.Y
	end
	local header = aspect(SIGN.Header)
	check(header * SIGN.Height <= SIGN.Width,
		string.format("RAIN BIOME is %.2f times as wide as tall: whole at %d studs in %d", header, SIGN.Height, SIGN.Width),
		header * SIGN.Height)
	local worst, worstText = 0, ""
	for _, text in ipairs({ string.format(WORDS.Next, "60:00"), string.format(WORDS.Open, "30:00"), WORDS.Starting,
		WORDS.Opening, WORDS.Closing }) do
		local a = aspect(text)
		if a > worst then
			worst, worstText = a, text
		end
	end
	check(worst * SIGN.SubHeight <= SIGN.Width,
		string.format("every status line whole at %d studs: the longest, \"%s\", %.1f wide", SIGN.SubHeight, worstText,
			worst * SIGN.SubHeight))

	--==========================================================================
	say("4. Read from afar, never huge up close")
	--==========================================================================
	local VH, FOV = 720, 70
	local perStud = function(d)
		return (VH / 2) / math.tan(math.rad(FOV / 2)) / d
	end
	local far = 420
	local nearD = 25
	local mid = SIGN.Height * (VH / 2) / math.tan(math.rad(FOV / 2)) / (SIGN.MinHeaderUnits * 1.5)
	local farPx = SIGN.Height * RainSign.scale(far, VH, FOV) * perStud(far)
	local nearPx = SIGN.Height * RainSign.scale(nearD, VH, FOV) * perStud(nearD)
	check(math.abs(farPx - SIGN.MinHeaderUnits) < 1e-6 and math.abs(nearPx - SIGN.MaxHeaderShare * VH) < 1e-6
			and RainSign.scale(mid, VH, FOV) == 1,
		string.format("on a 720-px screen its header is %d px from %d studs (grown to hold it), %.1f px from %d (capped), "
			.. "and as built in between", SIGN.MinHeaderUnits, far, nearPx, nearD), farPx)
	check(RainSign.scale(far, VH, FOV) == FloatingSign.clampScale(far, SIGN.Height, VH, FOV, SIGN.MinHeaderUnits,
			SIGN.MaxHeaderShare) and SIGN.Height == ObbyData.Sign.Height and SIGN.MinHeaderUnits == ObbyData.Sign.MinHeaderUnits
			and SIGN.MaxHeaderShare == ObbyData.Sign.MaxHeaderShare,
		"the OBBY sign's size and rule: FloatingSign.clampScale with its numbers")

	--==========================================================================
	say("5. In sight, within reach, never over the OBBY sign")
	--==========================================================================
	local map = Workspace:FindFirstChild(MAP.FolderName)
	if not map then
		require(Server:WaitForChild("MapService")).Init()
		map = Workspace:FindFirstChild(MAP.FolderName)
	end
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
	-- The ring of plots as MapService.Init lays it out (RainBeaconSpec's eyes).
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
	table.insert(cams, { name = "the road's mouth", at = Vector3.new(0, MAP.GroundY + 5, -MAP.FieldFront - 5) })
	table.insert(cams, { name = "the landing", at = Vector3.new(B.Landing.X - 20, MAP.GroundY + 5, B.Landing.Z) })
	local headerMiddle = at + Vector3.new(0, tall / 2 - SIGN.Height / 2, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	-- What stands between an eye and the header: nil, or its name.
	local function blocker(eye)
		local hit = Workspace:Raycast(eye, headerMiddle - eye, params)
		if hit then
			return hit.Instance:GetFullName()
		end
		for _, p in ipairs(setParts) do
			if crosses(eye, headerMiddle, p) then
				return p.Name
			end
		end
		return nil
	end
	local blocked, by, farthest = 0, nil, 0
	for _, cam in ipairs(cams) do
		farthest = math.max(farthest, (at - cam.at).Magnitude)
		if string.sub(cam.name, 1, 8) ~= "the hub'" then
			local what = blocker(cam.at)
			if what then
				blocked += 1
				by = by or string.format("%s: %s", cam.name, what)
			end
		end
	end
	check(map ~= nil and #cams >= 18 and blocked == 0,
		string.format("from every plot's gate and back, the road's mouth and the landing (%d eyes) its header is in "
			.. "sight: past the map and the hub's set", #cams - 4), by)
	-- The hub is the Mosskeeper's grove: trees round every eye. A player's
	-- camera sits behind and over their head, about 12 studs up; at a standing
	-- eye's 5 the trees hide it from some spots (counted, not required).
	local seenHigh, totalHigh, seenLow, missHigh = 0, 0, 0, nil
	for _, side in ipairs({ { "north", 0, 1 }, { "east", 1, 0 }, { "south", 0, -1 }, { "west", -1, 0 } }) do
		for r = 6, 30, 6 do
			for _, dx in ipairs({ -6, 0, 6 }) do
				local x = HUB.Centre.X + side[2] * r + (if side[2] == 0 then dx else 0)
				local z = HUB.Centre.Z + side[3] * r + (if side[3] == 0 then dx else 0)
				totalHigh += 1
				local what = blocker(Vector3.new(x, deckTop + 12, z))
				if what then
					missHigh = missHigh or string.format("%s side, %d out: %s", side[1], r, what)
				else
					seenHigh += 1
				end
				if blocker(Vector3.new(x, deckTop + 5, z)) == nil then
					seenLow += 1
				end
			end
		end
	end
	check(seenHigh == totalHigh and totalHigh == 60,
		string.format("from the hub, a camera 12 up sees it from all %d spots 6-30 studs out on its four sides (a standing "
			.. "eye 5 up, through the grove's trees, from %d of them)", totalHigh, seenLow), missHigh)
	-- The signs as each plot's screens draw them (70 degrees; every sign at its
	-- own read-from-afar size): a desktop's 1280 x 720, a tablet-ish 942 x 739
	-- and a small phone's 640 x 360. Each plot's eye at its gate, its middle and
	-- its back, 8.5 and 14 up, and the road's mouth.
	local OS = ObbyData.Sign
	local obbyTall = OS.Height + OS.SubHeight
	local obbyMiddle = Vector3.new(obby.X, MAP.GroundY + OS.BottomAbove + obbyTall / 2, obby.Z)
	local MS = EnchantedMistConfig.Sign
	local mistTall = MS.Height + MS.SubHeight + MS.NoteHeight
	local mistMiddle = Vector3.new(HUB.Centre.X, MAP.GroundY + HUB.FloorY + MS.Above, HUB.Centre.Z)
	local eyes = {}
	do
		local gap = math.rad(MAP.RoadGapDegrees)
		local step = (math.pi * 2 - gap) / nPlots
		local first = math.pi + gap * 0.5
		for id = 1, nPlots do
			local angle = first + (id - 0.5) * step
			local r = MAP.PlotRingInner + startDepth * 0.5
			local pos = Vector3.new(math.sin(angle) * r, MAP.GroundY, math.cos(angle) * r)
			local g = CFrame.lookAt(pos, Vector3.new(0, MAP.GroundY, 0)) * CFrame.new(0, 0, -startDepth * 0.5)
			for _, back in ipairs({ 12, startDepth * 0.5, startDepth + 12 }) do
				for _, up in ipairs({ 8.5, 14 }) do
					table.insert(eyes, { name = string.format("plot %d, %d back, %.1f up", id, back, up),
						at = (g * CFrame.new(0, up, back)).Position })
				end
			end
		end
		table.insert(eyes, { name = "the road's mouth", at = Vector3.new(0, MAP.GroundY + 5, -MAP.FieldFront - 5) })
	end
	local function box(eye, middle, width, high, scale, look, f)
		local rel = middle + Vector3.new(0, (scale - 1) * high / 2, 0) - eye
		local z = rel:Dot(look.LookVector)
		return rel:Dot(look.RightVector) / z * f, rel:Dot(look.UpVector) / z * f, width * scale / 2 * f / z,
			high * scale / 2 * f / z, z
	end
	local function crossing(a, b)
		return a[5] > 0 and b[5] > 0 and math.abs(a[1] - b[1]) < a[3] + b[3] and math.abs(a[2] - b[2]) < a[4] + b[4]
	end
	local counts, firstOver = {}, nil
	for _, vp in ipairs({ { 1280, 720 }, { 942, 739 }, { 640, 360 } }) do
		local h = vp[2]
		local f = (h / 2) / math.tan(math.rad(FOV / 2))
		local n = { mist = 0, obby = 0, base = 0 }
		for _, eye in ipairs(eyes) do
			local look = CFrame.lookAt(eye.at, at)
			local rain = { box(eye.at, at, SIGN.Width, tall, RainSign.scale((at - eye.at).Magnitude, h, FOV), look, f) }
			local mist = { box(eye.at, mistMiddle, MS.Width, mistTall,
				EnchantedMistStatus.signScale((mistMiddle - eye.at).Magnitude, h, FOV), look, f) }
			local ob = { box(eye.at, obbyMiddle, OS.Width, obbyTall, FloatingSign.clampScale((obbyMiddle - eye.at).Magnitude,
				OS.Height, h, FOV, OS.MinHeaderUnits, OS.MaxHeaderShare), look, f) }
			if crossing(rain, mist) then
				n.mist += 1
				if h ~= 360 then
					firstOver = firstOver or string.format("%dx%d, %s: over the Mist sign", vp[1], h, eye.name)
				end
			end
			if crossing(rain, ob) then
				n.obby += 1
				if h ~= 360 then
					firstOver = firstOver or string.format("%dx%d, %s: over the OBBY sign", vp[1], h, eye.name)
				end
			end
			if crossing(mist, ob) then
				n.base += 1
			end
		end
		counts[h] = n
	end
	check(firstOver == nil and counts[720].mist == 0 and counts[720].obby == 0 and counts[739].mist == 0
			and counts[739].obby == 0,
		string.format("from %d plot and road eyes it stands over neither the hub's ENCHANTED MIST sign nor the OBBY sign "
			.. "on a 1280 x 720 or a 942 x 739 screen. On a 640 x 360 phone every floating sign grows to stay readable: "
			.. "over the Mist sign from %d, the OBBY sign from %d (those two over each other from %d)", #eyes,
			counts[360].mist, counts[360].obby, counts[360].base), firstOver)

	--==========================================================================
	say("6. The wiring")
	--==========================================================================
	local client = sourceOf(Scripts, "RainSign")
	local weather = sourceOf(Server, "WeatherService")
	check(client ~= "" and has(client, "local NEXT_AT = W.Auto.NextAtAttribute")
			and has(client, "for _, name in ipairs({ ATTR.State, ATTR.EndsAt, NEXT_AT }) do")
			and has(client, "Workspace:GetServerTimeNow()") and has(client, "task.wait(1)")
			and has(weather, "Workspace:SetAttribute(NEXT_AT, at)"),
		"the client reads the published weather and the next mark the server publishes, repainting on a change and once "
			.. "a second; nothing is sent to count down")
	check(has(client, 'folder.Name = "SeedRainSign"') and has(client, "folder.Parent = Workspace")
			and has(client, "FloatingSign.new({") and has(client, "sign.gui.MaxDistance = SIGN.MaxDistance")
			and has(client, "sign.setShown(true)") and has(client, "RainSign.scale((middle - camera.CFrame.Position).Magnitude")
			and not has(client, "FireServer") and not has(client, "RemoteEvent") and not has(client, "PlayerGui"),
		"each client's own, on a local anchor in a folder of its own, shown to everybody always, sized after the camera, "
			.. "no remote, no HUD")
	local c, obbyC, mint = SIGN.HeaderColour, OS.HeaderColour, EnchantedMistConfig.Sign.Colour
	check(c.B > c.G and c.G > c.R and (c.R < obbyC.R - 0.1 or c.G < obbyC.G - 0.1) and mint.G > mint.B,
		"a rain blue deeper than the OBBY sign's sky blue, never the Mist sign's mint")
end

local ok, err = pcall(body)
stage:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nRainSignSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
