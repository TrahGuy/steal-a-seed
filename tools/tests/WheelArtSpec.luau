--!nocheck
--==============================================================================
-- Steal a Seed :: WheelArtSpec (2026-10-04, the owner's spin-wheel brief)
--
-- Edit mode, no Play:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("WheelArtSpec"))
--
-- The wheel's new prize art, drawn by the one renderer (WheelDraw) both wheels
-- use, measured rather than looked at:
--
--   1. NOTHING ABOUT A PRIZE CHANGED: every id, kind, amount, weight, tier,
--      pool, swap, product and the drawn order are what they were; the
--      Colossal pod is still the second-rarest prize after the trail, and
--      there is no Titan-and-Colossal prize.
--   2. THE ASSETS: the Speed icon is GameConfig.SourceIcons.training and the
--      only id the art uses; no other id is written in WheelDraw; the pod
--      upload slots are empty, so the pods are drawn in frames.
--   3. THE FACE, built at the panel's phone and desktop sizes and the world's:
--      coins that grow with the amount and are capped, one Speed icon or three,
--      pods whose silhouettes are exactly their pool's biomes with one "?" and
--      the size's outline, TITAN and COLOSSAL lettering where it fits; every
--      decoration inside its own slice, either way up; nothing upside down at
--      any angle; the light on the lettering never touching the gradients that
--      cut the slices; a bounded number of frames.
--   4. THE LETTERING'S LIGHT: slow, soft, no flash, still under reduced
--      motion; WheelDraw itself runs nothing, and WheelUI steps it only while
--      the panel is open or the world wheel is near.
--   5. THE BAG'S TRAIL PREVIEW: two ribbons, mint and gold, and a flower.
--
-- NOT here: how it looks (a capture in Play), a phone's real screen, a
-- controller.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

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
local function count(text, needle)
	local n, at = 0, 1
	while true do
		local found = string.find(text, needle, at, true)
		if not found then
			return n
		end
		n += 1
		at = found + #needle
	end
end
local function code(src)
	local lines = {}
	for _, line in ipairs(string.split(src, "\n")) do
		local at = string.find(line, "--", 1, true)
		table.insert(lines, if at then string.sub(line, 1, at - 1) else line)
	end
	return table.concat(lines, "\n")
end

local layer = Instance.new("ScreenGui")
layer.Name = "ZZWheelArtSpec"
layer.Archivable = false
layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
layer.Parent = StarterGui

local ok, err = pcall(function()

--==============================================================================
-- 1. NOTHING ABOUT A PRIZE CHANGED
--==============================================================================
say("-- 1. the prizes, unchanged --")
local EXPECT = {
	{ "cash_small", "cash", 5000, 2200, nil, nil },
	{ "speed_small", "speed", 1000, 2000, nil, nil },
	{ "pod_common", "pod", nil, 1300, 2, "common" },
	{ "boost_income", "boost", nil, 950, nil, nil },
	{ "cash_medium", "cash", 20000, 1000, nil, nil },
	{ "speed_large", "speed", 10000, 700, nil, nil },
	{ "pod_rare", "pod", nil, 500, 2, "rare" },
	{ "boost_training", "boost", nil, 850, nil, nil },
	{ "pod_titan", "pod", nil, 150, 6, "common" },
	{ "cash_jackpot", "cash", 75000, 250, nil, nil },
	{ "pod_colossal", "pod", nil, 60, 7, "common" },
	{ "trail", "trail", nil, 40, nil, nil },
}
local same = #WheelData.Rewards == #EXPECT
for i, e in ipairs(EXPECT) do
	local r = WheelData.Rewards[i]
	if not r or r.id ~= e[1] or r.kind ~= e[2] or r.amount ~= e[3] or r.weight ~= e[4] or r.tier ~= e[5]
		or r.pool ~= e[6] then
		same = false
	end
end
check(same and WheelData.TotalWeight == 10000 and WheelData.ById.trail.swap == "cash_jackpot",
	"every prize's id, kind, amount, weight, size and pool, in wheel order; the trail still swaps to the jackpot")
check(table.concat(WheelData.Pools.common, ",") == "nubkin,petalpip,spiretip,dunebud,paddlehop"
		and table.concat(WheelData.Pools.rare, ",") == "toadcap,thornwhorl,bogbonnet,crookreed,cinderpaw,emberquill,novaorb,cosmospire",
	"both species pools as they were")
check(table.concat(WheelData.DisplayOrder, ",")
		== "cash_small,speed_small,pod_common,pod_colossal,boost_income,pod_rare,cash_medium,trail,speed_large,pod_titan,boost_training,cash_jackpot"
		and WheelData.DisplayFloor == 12,
	"the drawn order and sizes as they were (so every landing is where it was)")
local productsSame = #WheelData.Products == 3 and WheelData.Products[1].productId == 3715745320
	and WheelData.Products[2].productId == 3715745407 and WheelData.Products[3].productId == 3715745552
	and WheelData.Products[1].spins == 1 and WheelData.Products[2].spins == 5 and WheelData.Products[3].spins == 10
check(productsSame and WheelData.Paid.Enabled == true, "the three Spin Ticket products and the paid switch as they were")
local byWeight = table.clone(WheelData.Rewards)
table.sort(byWeight, function(a, b)
	return a.weight < b.weight
end)
check(byWeight[1].id == "trail" and byWeight[2].id == "pod_colossal" and byWeight[3].id == "pod_titan",
	"the Bloomrunner Trail is the rarest prize, the Colossal pod the second-rarest, then the Titan")
local titans, colossals, both = 0, 0, 0
for _, r in ipairs(WheelData.Rewards) do
	if r.kind == "pod" and r.tier == 6 then
		titans += 1
	elseif r.kind == "pod" and r.tier == 7 then
		colossals += 1
	end
	if r.kind == "pod" and string.find(string.lower(r.title), "titan") and string.find(string.lower(r.title), "colossal") then
		both += 1
	end
end
check(titans == 1 and colossals == 1 and both == 0, "one Titan pod and one Colossal pod, never one prize that is both")
check(WheelData.ById.pod_titan.rarity == "Legendary" and WheelData.ById.pod_colossal.rarity == "Legendary"
		and WheelData.ById.trail.rarity == "Mythic",
	"their rarity words untouched: the lettering is for the SIZE")

--==============================================================================
-- 2. THE ASSETS
--==============================================================================
say("\n-- 2. the assets --")
local drawSource = Shared:FindFirstChild("WheelDraw").Source
local drawCode = code(drawSource)
check(GameConfig.SourceIcons.training == "rbxassetid://96656510808947", "the Speed icon is the owner's upload, rbxassetid://96656510808947")
check(not string.find(drawCode, "rbxassetid://%d") and not string.find(drawCode, "rbxasset://", 1, true),
	"WheelDraw writes no asset id of its own: the Speed icon comes from SourceIcons, the pods' from WheelPodArt")
local slots, bad = 0, {}
for biome, id in pairs(GameConfig.WheelPodArt) do
	slots += 1
	if id ~= "" and not string.match(id, "^rbxassetid://%d+$") then
		table.insert(bad, biome)
	end
end
check(slots == 5 and #bad == 0, "five pod upload slots, each empty or an rbxassetid", table.concat(bad, ","))
-- The owner's three uploads (2026-10-04), exactly; Dustbowl has none yet.
local UPLOADED = {
	greenhollow = "rbxassetid://121294253348295",
	tanglemire = "rbxassetid://122381169752786",
	starbloom = "rbxassetid://106800317033952",
}
local art = GameConfig.WheelPodArt
check(art.greenhollow == UPLOADED.greenhollow and art.tanglemire == UPLOADED.tanglemire
		and art.starbloom == UPLOADED.starbloom,
	"Greenhollow, Tanglemire and Starbloom hold the owner's uploads, exactly as given")
check(art.dustbowl == "" and art.emberroot == "",
	"Dustbowl (and Emberroot) have no picture yet, so they stay in frames: no other biome's picture stands in")

--==============================================================================
-- 3. THE FACE
--==============================================================================
say("\n-- 3. the face --")

-- A point of a GuiObject, in its wheel face's own (unturned) pixels.
local function turn(v, deg)
	local r = math.rad(deg)
	local c, s = math.cos(r), math.sin(r)
	return Vector2.new(v.X * c - v.Y * s, v.X * s + v.Y * c)
end
local function frameOf(obj, face, faceSize)
	local chain = {}
	local node = obj
	while node and node ~= face do
		table.insert(chain, 1, node)
		node = node.Parent
	end
	local O, theta, size = Vector2.zero, 0, Vector2.new(faceSize, faceSize)
	for _, n in ipairs(chain) do
		local ps = size
		local sz = Vector2.new(n.Size.X.Scale * ps.X + n.Size.X.Offset, n.Size.Y.Scale * ps.Y + n.Size.Y.Offset)
		local tl = Vector2.new(n.Position.X.Scale * ps.X + n.Position.X.Offset - n.AnchorPoint.X * sz.X,
			n.Position.Y.Scale * ps.Y + n.Position.Y.Offset - n.AnchorPoint.Y * sz.Y)
		local centre = tl + sz / 2
		O = O + turn(centre - turn(sz / 2, n.Rotation), theta)
		theta += n.Rotation
		size = sz
	end
	return O, theta, size
end

-- The circles an object is the union of: a circle or pill as its end circles,
-- a rounded block as its corner circles along its edges, text as its bounds.
local function circlesOf(obj, face, faceSize)
	local O, theta, size = frameOf(obj, face, faceSize)
	local function at(q)
		return O + turn(q, theta)
	end
	local out = {}
	local w, h = size.X, size.Y
	local x0, y0, x1, y1 = 0, 0, w, h
	local rc = 0
	if obj:IsA("ImageLabel") and string.match(obj.Name, "^Pod_") then
		-- An uploaded pod's square has a transparent margin of at least 6% on
		-- every side (the crops in art/icons/wheel/): measured without it.
		x0, x1, y0, y1 = w * 0.06, w * 0.94, h * 0.06, h * 0.94
	elseif obj:IsA("TextLabel") then
		local b = obj.TextBounds
		if b.X > 0 and b.Y > 0 then
			x0, x1 = (w - b.X) / 2, (w + b.X) / 2
			y0, y1 = (h - b.Y) / 2, (h + b.Y) / 2
		end
	else
		local corner = obj:FindFirstChildOfClass("UICorner")
		if corner then
			rc = math.min(math.min(w, h) / 2, corner.CornerRadius.Scale * math.min(w, h) + corner.CornerRadius.Offset)
		end
	end
	local ix0, iy0, ix1, iy1 = x0 + rc, y0 + rc, x1 - rc, y1 - rc
	if ix1 < ix0 then
		ix0, ix1 = (x0 + x1) / 2, (x0 + x1) / 2
	end
	if iy1 < iy0 then
		iy0, iy1 = (y0 + y1) / 2, (y0 + y1) / 2
	end
	for i = 0, 4 do
		local u = i / 4
		for _, q in ipairs({
			Vector2.new(ix0 + (ix1 - ix0) * u, iy0), Vector2.new(ix0 + (ix1 - ix0) * u, iy1),
			Vector2.new(ix0, iy0 + (iy1 - iy0) * u), Vector2.new(ix1, iy0 + (iy1 - iy0) * u),
		}) do
			table.insert(out, { p = at(q), r = rc })
		end
	end
	return out
end

local function drawnObjects(arm)
	local list = {}
	for _, d in ipairs(arm:GetDescendants()) do
		if d:IsA("GuiObject") and d.Visible and (d:IsA("TextLabel") or d.BackgroundTransparency < 1 or d:IsA("ImageLabel")) then
			local hidden = false
			local node = d.Parent
			while node and node ~= arm do
				if node:IsA("GuiObject") and not node.Visible then
					hidden = true
				end
				node = node.Parent
			end
			if not hidden then
				table.insert(list, d)
			end
		end
	end
	return list
end

-- How far a circle reaches past its slice (0 when it is inside), in pixels.
local function overreach(c, sector, size, k)
	local centre = Vector2.new(size / 2, size / 2)
	local d = c.p - centre
	local r = d.Magnitude
	local margin = 1.25 * k
	local worst = 0
	-- Past the rim of the coloured fill.
	worst = math.max(worst, r + c.r - (136.75 * k - 0.3 * k))
	-- Past either divider: the signed distance to each edge line, inward positive.
	for _, edge in ipairs({ sector.start, sector.finish }) do
		local a = math.rad(edge)
		local dir = Vector2.new(math.sin(a), -math.cos(a))
		local normal = if edge == sector.start then Vector2.new(dir.Y * -1, dir.X) else Vector2.new(dir.Y, -dir.X)
		local inward = d:Dot(normal)
		local along = d:Dot(dir)
		if along > -c.r then
			worst = math.max(worst, (c.r + margin) - inward)
		end
	end
	return worst
end

local sectors = WheelData.displaySectors()
local sectorOf = {}
for _, s in ipairs(sectors) do
	sectorOf[s.reward.id] = s
end

local function build(size)
	local holder = Instance.new("Frame")
	holder.Name = "Stage" .. size
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(size, size)
	holder.Position = UDim2.fromOffset(10, 10)
	holder.Parent = layer
	local drawn = WheelDraw.build(holder, size, { labels = true, hub = size == 600 })
	return drawn, holder
end

local budgets = {}
for _, size in ipairs({ 296, 520, 600 }) do
	local k = size / 296
	local drawn, holder = build(size)
	task.wait()
	local face = drawn.root:FindFirstChild("Face")
	local arms = {}
	for _, child in ipairs(face:GetChildren()) do
		local id = string.match(child.Name, "^Sector_(.+)$")
		if id then
			arms[id] = child
		end
	end

	-- Cash: coins that grow with the amount.
	local coinsBy, stacksBy = {}, {}
	for _, id in ipairs({ "cash_small", "cash_medium", "cash_jackpot" }) do
		local arm = arms[id]
		local pattern, stack = 0, 0
		for _, d in ipairs(arm:GetDescendants()) do
			if string.match(d.Name, "^Coin%d+$") then
				pattern += 1
			elseif d.Name == "CoinTop" then
				stack += 1
			end
		end
		coinsBy[id], stacksBy[id] = pattern, stack
	end
	local tiers = { cash_small = 1, cash_medium = 2, cash_jackpot = 3 }
	local capped = true
	for id, n in pairs(coinsBy) do
		capped = capped and n >= 1 and n <= WheelDraw.CoinPattern[tiers[id]]
	end
	check(capped and coinsBy.cash_small <= coinsBy.cash_medium and coinsBy.cash_medium <= coinsBy.cash_jackpot + 3,
		string.format("%d: background coins %d / %d / %d for $5,000 / $20,000 / $75,000, each within its cap", size,
			coinsBy.cash_small, coinsBy.cash_medium, coinsBy.cash_jackpot))
	check(stacksBy.cash_small < stacksBy.cash_medium and stacksBy.cash_medium < stacksBy.cash_jackpot
			and coinsBy.cash_small + stacksBy.cash_small < coinsBy.cash_medium + stacksBy.cash_medium
			and coinsBy.cash_medium + stacksBy.cash_medium < coinsBy.cash_jackpot + stacksBy.cash_jackpot,
		string.format("%d: richer stacks and more coins as the prize grows (%d, %d, %d coins stacked)", size,
			stacksBy.cash_small, stacksBy.cash_medium, stacksBy.cash_jackpot))

	-- Speed: the owner's icon, one or three.
	local function pictures(id)
		local n, right = 0, true
		for _, d in ipairs(arms[id]:GetDescendants()) do
			if d:IsA("ImageLabel") then
				n += 1
				right = right and d.Image == GameConfig.SourceIcons.training
			end
		end
		return n, right
	end
	local smallN, smallOk = pictures("speed_small")
	local largeN, largeOk = pictures("speed_large")
	check(smallN == 1 and largeN == 3 and smallOk and largeOk,
		string.format("%d: +1,000 Speed shows one Speed icon, +10,000 a cluster of three, all the uploaded picture", size),
		smallN .. "/" .. largeN)
	local fallbacks = 0
	for _, id in ipairs({ "speed_small", "speed_large" }) do
		if arms[id]:FindFirstChild("Fallback", true) then
			fallbacks += 1
		end
	end
	check(fallbacks == 2, "and until it loads, the bolt stands in (never a blank slice)")

	-- Pods: their pool's own biomes, one "?", the size's outline; the owner's
	-- picture for a biome that has one and frames for one that has not.
	local honest, marks, outlines, cores, noCreature = true, true, true, true, true
	local pictured, picturedWhat = true, ""
	for _, id in ipairs({ "pod_common", "pod_rare", "pod_titan", "pod_colossal" }) do
		local reward = WheelData.ById[id]
		local biomes = WheelDraw.podBiomes(reward)
		local pool = {}
		for _, sp in ipairs(WheelData.Pools[reward.pool]) do
			pool[SeedData.Get(sp).Biome] = true
		end
		local poolCount = 0
		for _ in pairs(pool) do
			poolCount += 1
		end
		for _, b in ipairs(biomes) do
			honest = honest and pool[b] == true
		end
		honest = honest and (#biomes >= math.min(2, poolCount)) and (poolCount < 2 or #biomes >= 2)
		local icon = arms[id]:FindFirstChild("Icon")
		local q, qStandIn = 0, 0
		local glow = SeedData.ColorForTier(reward.tier)
		local glowOk = false
		local images = {}
		for _, d in ipairs(icon:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text == "?" then
				local standIn = d:FindFirstAncestor("Fallback")
				if standIn and standIn:IsDescendantOf(icon) then
					qStandIn += 1
				else
					q += 1
				end
			elseif d.Name == "Glow" and d:IsA("Frame") and d.BackgroundColor3 == glow then
				glowOk = true
			elseif d:IsA("ImageLabel") then
				images[string.match(d.Name, "^Pod_(.+)$") or d.Name] = d.Image
			elseif d:IsA("ViewportFrame") or d:IsA("Model") then
				noCreature = false
			end
		end
		local anyFrames = false
		for _, b in ipairs(biomes) do
			local want = UPLOADED[b]
			if want then
				pictured = pictured and images[b] == want
			else
				anyFrames = true
				pictured = pictured and images[b] == nil
			end
			if not pictured and picturedWhat == "" then
				picturedWhat = id .. ":" .. b
			end
		end
		for b in pairs(images) do
			pictured = pictured and pool[b] == true
		end
		-- The front pod's "?": the picture's own when it is a picture, ours when
		-- it is frames -- never both on one pod. A picture's stand-in frames
		-- carry one, hidden with them once the picture has loaded.
		local cluster = WheelDraw.podCluster(reward)
		local frontPictured = UPLOADED[cluster[#cluster][1]] ~= nil
		marks = marks and q == (if frontPictured then 0 else 1) and qStandIn == (if frontPictured then 1 else 0)
		outlines = outlines and (glowOk or not anyFrames)
		if reward.tier == 7 then
			cores = cores and icon:FindFirstChild("Core") ~= nil
		end
	end
	check(honest, size .. ": every pod prize shows its pool's own biomes' pods -- Greenhollow and Dustbowl for Big, "
		.. "Titan and Colossal, three different biomes for the five-biome Rare pod")
	check(pictured, size .. ": the owner's picture for every Greenhollow, Tanglemire and Starbloom pod, frames for "
		.. "every Dustbowl one, and no picture of a biome outside the prize's pool", picturedWhat)
	check(marks and outlines and noCreature, size .. ": one \"?\" on each pod in front (a picture's own, never a second "
		.. "one over it; its stand-in frames carry theirs until it loads), the size's outline round the pods drawn in "
		.. "frames, and no creature")
	check(cores, size .. ": the Colossal's pods are cracked open with light, as the model is")
	local rareBiomes = table.concat(WheelDraw.podBiomes(WheelData.ById.pod_rare), ",")
	local bigBiomes = table.concat(WheelDraw.podBiomes(WheelData.ById.pod_common), ",")
	check(rareBiomes == "greenhollow,tanglemire,starbloom" and bigBiomes == "greenhollow,dustbowl",
		"the Rare pod: " .. rareBiomes .. "; the common-pool pods: " .. bigBiomes)

	-- TITAN and COLOSSAL.
	local function lettering(id)
		local arm = arms[id]
		local words = arm:FindFirstChild("Words")
		local n, glows = 0, 0
		if words then
			for _, d in ipairs(words:GetDescendants()) do
				if d:IsA("UIGradient") and d.Name == "Prestige" then
					n += 1
				elseif d:IsA("TextLabel") and string.find(d.Name, "Glow$") then
					glows += 1
				end
			end
		end
		return words ~= nil, n, glows
	end
	local tHas, tN = lettering("pod_titan")
	local cHas, cN, cGlow = lettering("pod_colossal")
	local wantColossal = WheelDraw.narrowWords(sectorOf.pod_colossal.finish - sectorOf.pod_colossal.start, k,
		WheelData.ById.pod_colossal.label) ~= nil
	check(tHas and tN >= 1, size .. ": TITAN in its warm lettering")
	check(cHas == wantColossal and (not cHas or (cN == 1 and cGlow == 1)),
		string.format("%d: COLOSSAL on its slice %s", size,
			if wantColossal then "in violet and gold with its glow" else "left off: too small to read at this size"))

	-- Inside its own slice, at rest and turned over. The new art (coins,
	-- icons, pods, the COLOSSAL word and its glow) must keep clear of both
	-- divider lines; the approved mockup's own words and its unchanged boost
	-- and trail icons may reach a divider line but never the colour past it.
	local worst, worstWhat = 0, ""
	local wordsWorst, wordsWhat = 0, ""
	local function measure(tag)
		for id, arm in pairs(arms) do
			local sector = sectorOf[id]
			local narrow = (sector.finish - sector.start) < 14
			-- The boosts' and the trail's icons are the mockup's, unchanged.
			local newArt = sector.reward.kind == "cash" or sector.reward.kind == "speed" or sector.reward.kind == "pod"
			for _, obj in ipairs(drawnObjects(arm)) do
				local inWords = obj:IsA("TextLabel") and obj.Parent and obj.Parent.Name == "Words"
				local oldWords = (inWords and not narrow) or (not newArt and not inWords)
				for _, c in ipairs(circlesOf(obj, face, size)) do
					local o = overreach(c, sector, size, k)
					local what = id .. "/" .. obj:GetFullName():match("[^%.]+%.[^%.]+$") .. " " .. tag
					if oldWords then
						if o > wordsWorst then
							wordsWorst, wordsWhat = o, what
						end
					elseif o > worst then
						worst, worstWhat = o, what
					end
				end
			end
		end
	end
	measure("upright")
	local flipped = {}
	for _, arm in pairs(arms) do
		local icon = arm:FindFirstChild("Icon")
		if icon then
			flipped[icon] = icon.Rotation
			icon.Rotation = (icon.Rotation + 180) % 360
		end
	end
	measure("turned over")
	for icon, rot in pairs(flipped) do
		icon.Rotation = rot
	end
	check(worst <= 0.75, string.format("%d: every piece of the new art stays inside its own slice, clear of the dividers, "
		.. "either way up (worst %.2f px%s)", size, worst, if worst > 0 then ", " .. worstWhat else ""))
	check(wordsWorst <= 1.25 * k + 0.75, string.format("%d: and the mockup's words never pass a divider line into the next "
		.. "slice, nor do its unchanged icons (closest %.2f px into a %.1f px line%s)", size, wordsWorst, 2.5 * k,
		if wordsWorst > 0 then ", " .. wordsWhat else ""))

	-- Never upside down, at any angle.
	local upsideDown = 0
	for a = 0, 359, 7 do
		drawn.setAngle(a)
		for _, arm in pairs(arms) do
			local icon = arm:FindFirstChild("Icon")
			for _, item in ipairs({ icon, arm:FindFirstChild("Words") }) do
				if item and item:IsA("GuiObject") then
					local total = (face.Rotation + arm.Rotation + item.Rotation) % 360
					if item.Name == "Icon" and total > 90.5 and total < 269.5 then
						upsideDown += 1
					end
				end
			end
		end
	end
	drawn.setAngle(0)
	check(upsideDown == 0, size .. ": no icon is ever upside down as the wheel turns", upsideDown)

	-- The light on the lettering never touches the slices' masks.
	drawn.setAngle(37)
	local before = {}
	for _, d in ipairs(drawn.root:GetDescendants()) do
		if d:IsA("UIGradient") and d.Parent and d.Parent.Name:match("^Fill%d+$") then
			before[d] = { d.Rotation, d.Offset, d.Enabled }
		end
	end
	for t = 0, 12, 0.37 do
		drawn.setGlint(t)
	end
	drawn.setGlint(0, true)
	local maskSame, masks = true, 0
	for g, v in pairs(before) do
		masks += 1
		maskSame = maskSame and g.Rotation == v[1] and g.Offset == v[2] and g.Enabled == v[3]
	end
	local onWords = true
	for _, g in ipairs(drawn.glints) do
		onWords = onWords and g.gradient.Parent:IsA("TextLabel")
	end
	check(masks > 0 and maskSame and onWords and #drawn.glints >= 1,
		string.format("%d: stepping the lettering's light moves no slice-cutting gradient (%d checked), only its words'",
			size, masks))
	drawn.setAngle(0)

	-- A bounded face.
	local objects = 0
	for _, d in ipairs(drawn.root:GetDescendants()) do
		if d:IsA("GuiObject") then
			objects += 1
		end
	end
	budgets[size] = objects
	check(objects <= 1300, string.format("%d: the whole face is %d GuiObjects (bounded)", size, objects))

	holder:Destroy()
	drawn.setGlint(5)
	check(true, size .. ": stepping a destroyed face's lettering is harmless")
end

-- The decoration layout itself, for every slice size the wheel could have.
local layoutOk, layoutWorst = true, 0
for span = 12, 70, 0.5 do
	for tier = 1, 3 do
		for _, c in ipairs(WheelDraw.coinLayout(span, tier, 9)) do
			local inward = c.r * math.sin(math.rad(span / 2) - math.abs(math.rad(c.a)))
			local need = c.d / 2 + 1.25
			layoutWorst = math.max(layoutWorst, need - inward)
			layoutOk = layoutOk and inward >= need and c.r + c.d / 2 <= 136.75 and c.r - c.d / 2 >= 50
		end
		layoutOk = layoutOk and #WheelDraw.coinLayout(span, tier, 9) <= WheelDraw.CoinPattern[tier]
	end
end
check(layoutOk, "coinLayout keeps every coin clear of both dividers, the rim and the hub at every slice width, "
	.. "within its cap", string.format("%.2f", layoutWorst))
check(WheelDraw.speedCount(1000) == 1 and WheelDraw.speedCount(10000) == 3 and WheelDraw.cashTier(5000) == 1
		and WheelDraw.cashTier(20000) == 2 and WheelDraw.cashTier(75000) == 3,
	"one Speed icon for +1,000 and three for +10,000; coin tiers 1, 2, 3 for the three cash prizes")

--==============================================================================
-- 4. THE LETTERING'S LIGHT
--==============================================================================
say("\n-- 4. the lettering's light --")
-- Perceived brightness, and how far a colour is lifted toward white in it.
local function luma(c)
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end
local function liftOf(c, base)
	local b = luma(base)
	return if b < 0.999 then (luma(c) - b) / (1 - b) else 0
end
local function colourAt(seq, t)
	local kps = seq.Keypoints
	for i = 1, #kps - 1 do
		local a, b = kps[i], kps[i + 1]
		if t >= a.Time and t <= b.Time then
			local span = b.Time - a.Time
			return a.Value:Lerp(b.Value, if span > 0 then (t - a.Time) / span else 0)
		end
	end
	return kps[#kps].Value
end
for _, style in ipairs({ "titan", "colossal" }) do
	local p = WheelDraw.Prestige[style]
	local valid, maxLift, maxStep = #p.frames == 32, 0, 0
	local prev, first = nil, nil
	for _, seq in ipairs(p.frames) do
		local kps = seq.Keypoints
		valid = valid and kps[1].Time == 0 and kps[#kps].Time == 1 and #kps <= 20
		local lifts = {}
		for i = 0, 100 do
			local t = i / 100
			local colour = colourAt(seq, t)
			maxLift = math.max(maxLift, liftOf(colour, colourAt(p.still, t)))
			lifts[i] = luma(colour)
			if prev then
				maxStep = math.max(maxStep, math.abs(lifts[i] - prev[i]))
			end
		end
		prev = lifts
		first = first or lifts
	end
	for i = 0, 100 do
		maxStep = math.max(maxStep, math.abs(prev[i] - first[i]))
	end
	check(valid and maxLift <= p.lift + 0.02 and maxStep <= 0.1 and p.seconds >= 2.5,
		string.format("%s: one slow pass every %.1f s in 32 steps, the light at most %.2f of the way to white, "
			.. "no point of the word brightening or dimming by more than %.3f a step -- no flash", style, p.seconds,
			maxLift, maxStep))
end
do
	local label = Instance.new("TextLabel")
	label.Text = "COLOSSAL POD"
	label.Parent = layer
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(27, 42, 24)
	stroke.Parent = label
	local g = WheelDraw.prestige(label, "colossal", true)
	local twin = layer:FindFirstChild("TextLabelGlow")
	check(g ~= nil and label.TextColor3 == Color3.new(1, 1, 1) and label:FindFirstChildOfClass("UIStroke").Color
			== Color3.fromRGB(27, 42, 24) and twin ~= nil and twin.ZIndex < label.ZIndex,
		"a lettered label: white under its ramp, its dark outline kept, the Colossal glow behind it")
	label.Text = "SOMETHING ELSE"
	label.Position = UDim2.fromOffset(40, 7)
	task.wait()
	check(twin and twin.Text == label.Text and twin.Position == label.Position, "and the glow follows the words")
	WheelDraw.glint({ g }, 1.3, true)
	local stillColour = g.gradient.Color
	WheelDraw.glint({ g }, 2.9, true)
	check(stillColour == WheelDraw.Prestige.colossal.still and g.gradient.Color == stillColour,
		"reduced motion: the plain ramp, held still")
	WheelDraw.glint({ g }, 1.3)
	check(g.gradient.Color ~= stillColour, "otherwise the light moves")
	label:Destroy()
	if twin then
		twin:Destroy()
	end
	check(WheelDraw.prestigeOf(WheelData.ById.pod_titan) == "titan"
			and WheelDraw.prestigeOf(WheelData.ById.pod_colossal) == "colossal"
			and WheelDraw.prestigeOf(WheelData.ById.pod_common) == nil and WheelDraw.prestigeOf(WheelData.ById.pod_rare) == nil
			and WheelDraw.prestigeOf(WheelData.ById.trail) == nil,
		"only the Titan and Colossal pods are lettered, by their size tier")
end
do
	local src = code(drawSource)
	check(not src:find("RunService", 1, true) and not src:find("Heartbeat", 1, true)
			and not src:find("RenderStepped", 1, true) and not src:find("task.spawn", 1, true)
			and not src:find("task.delay", 1, true) and not src:find("task.wait", 1, true)
			and not src:find("TweenService", 1, true),
		"WheelDraw runs nothing by itself: no loop, no tween, no timer")
	local ui = code(Scripts:FindFirstChild("WheelUI").Source)
	local tick = string.match(ui, "local function rainbowTick%(%)(.-)\nend\n")
	check(tick ~= nil and tick:find("d.setGlint(now, art.still)", 1, true) ~= nil
			and tick:find("WheelDraw.glint(art.glints, now, art.still)", 1, true) ~= nil,
		"WheelUI steps the panel's lettering in the RenderStepped it keeps only while the panel is open")
	check(ui:find("if near and not open then", 1, true) ~= nil
			and ui:find("face.setGlint(now, art.still)", 1, true) ~= nil and count(ui, ".setGlint(") == 3,
		"and the world faces' only while this camera is near and the panel is shut")
	check(ui:find("d.setGlint(0, true)", 1, true) ~= nil and ui:find("WheelDraw.glint(art.glints, 0, true)", 1, true) ~= nil,
		"when nothing steps it any more, the lettering is left on its plain ramp")
	check(ui:find("ReducedMotionEnabled", 1, true) ~= nil and ui:find("art.still = lettersStill()", 1, true) ~= nil,
		"reduced motion (Roblox's or FX Off) holds it still")
	check(ui:find('icon = if prize.kind == "speed" then "training" else "wheel"', 1, true) ~= nil
			and ui:find("holdLine(line, rarityText(prize.rarity), RESULT_SECONDS, prize.rainbow == true, prize)", 1, true) ~= nil
			and ui:find("WheelDraw.icon(holder, shown, holder.Size.X.Offset)", 1, true) ~= nil,
		"a won prize's line shows its picture, and a Speed win's notice wears the Speed icon")
	check(ui:find("local style = WheelDraw.prestigeOf(reward)", 1, true) ~= nil
			and ui:find("WheelDraw.prestige(name, style, style == \"colossal\")", 1, true) ~= nil,
		"Reward info letters TITAN POD and COLOSSAL POD")
end

--==============================================================================
-- 5. THE BAG'S TRAIL PREVIEW
--==============================================================================
say("\n-- 5. the Bag's trail preview --")
do
	local build = ItemArt.builder("trail-spec", { kind = "trail", tier = 1 })
	local model = build and build(workspace)
	local mint, gold, petals, heart, parts = 0, 0, 0, 0, 0
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
				if d.Name:match("^Mint%d") then
					mint += 1
				elseif d.Name:match("^Gold%d") then
					gold += 1
				elseif d.Name:match("^FlowerPetal") then
					petals += 1
				elseif d.Name == "FlowerHeart" then
					heart += 1
				end
			end
		end
	end
	-- In the world's own axes (GetExtentsSize follows the first part's turn).
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				for _, sx in ipairs({ -0.5, 0.5 }) do
					for _, sy in ipairs({ -0.5, 0.5 }) do
						for _, sz in ipairs({ -0.5, 0.5 }) do
							local p = d.CFrame * Vector3.new(d.Size.X * sx, d.Size.Y * sy, d.Size.Z * sz)
							lo = lo:Min(p)
							hi = hi:Max(p)
						end
					end
				end
			end
		end
	end
	local extents = hi - lo
	check(mint == 8 and gold == 8 and petals == 5 and heart == 1 and parts <= 30,
		string.format("two ribbons (%d mint, %d gold pieces), a flower of %d petals and a heart; %d parts", mint, gold,
			petals, parts))
	check(extents.X >= 5 and extents.X <= 6.5 and extents.Y <= 2.4,
		string.format("about the old preview's size, so the Bag frames it the same (%.1f x %.1f)", extents.X, extents.Y))
	local mintPart = model and model:FindFirstChild("Mint8")
	local goldPart = model and model:FindFirstChild("Gold8")
	local function near(a, b)
		return a and b and math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
	end
	check(mintPart and near(mintPart.Color, WheelData.Trail.Mint) and goldPart and near(goldPart.Color, WheelData.Trail.Gold),
		"in the trail's own mint and gold, fresh at the runner's end")
	if model then
		model:Destroy()
	end
end

end)

layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nWheelArtSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
