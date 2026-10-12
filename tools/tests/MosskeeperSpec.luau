--==============================================================================
-- MosskeeperSpec (2026-10-11, Enchanted Mist stage 3)
--
-- The Mosskeeper, his surround and his deposits (KB/ENCHANTED-MIST-RESET-
-- ALIGNED-CLAUDE-PROMPT.md §8-9). Pure fixture: the service is loaded from its
-- source with stand-ins for every reach outside it; no profile is opened.
--
--   1. his model: the owner's builder's parts and joints, one anchored footing,
--      nothing colliding or touching, no script, prompt or bubble of its own
--   2. the surround: the owner's builder's own checks -- parts, the 20-stud
--      radius, 14 tall, the pad, the arch, the open front, his keep-clear space,
--      only the pad solid
--   3. where he stands: the hub's anchor, facing the road, inside the plaza;
--      on the plaza's floor between Mists, on the pad during one; the surround
--      up once, and gone whole after; the deck's dress -- carpet, ring, grove
--      and its detail (tufts, flowers, plants, the pond) -- each on its ground
--   4. his prompt: tap E -- Talk, clear of every berry's
--   5. give all: every refusal, the 15-berry example, the full Bag rejecting
--      the whole of a pod-earning delivery, a small one still taken, the stage 4
--      grant inside the one change, one request at a time
--   6. talk: the dialogue opens for a loaded player, active or not
--   7. his life: nothing drifts, he greets and watches, he serves, Reduced FX
--   8. the wiring
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local MosskeeperModel = require(Shared:WaitForChild("MosskeeperModel"))
local MistSurroundModel = require(Shared:WaitForChild("MistSurroundModel"))
local MosskeeperIdle = require(Shared:WaitForChild("MosskeeperIdle"))

local CFG = EnchantedMistConfig.Mosskeeper
local MAP = GameConfig.Map
local HUB = MAP.EventHub
local LIMITS = MistSurroundModel.Limits

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
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function corners(p)
	local h = p.Size * 0.5
	local list = {}
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				table.insert(list, p.CFrame * Vector3.new(sx * h.X, sy * h.Y, sz * h.Z))
			end
		end
	end
	return list
end
local function parts(model)
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local stage = Instance.new("Folder")
stage.Name = "MosskeeperSpecStage"
stage.Parent = Workspace

local ok, err = pcall(function()
	--==========================================================================
	say("1. His model (the owner's builder)")
	--==========================================================================
	local at = CFrame.new(500, 10, 500) * CFrame.Angles(0, math.rad(30), 0)
	local m = MosskeeperModel.build(at, stage)
	local ps = parts(m)
	local motors, welds, anchored, solid, queried = 0, 0, 0, 0, {}
	local foreign = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Motor6D") then
			motors += 1
		elseif d:IsA("Weld") then
			welds += 1
		elseif d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") or d:IsA("BindableEvent")
			or d:IsA("BillboardGui") then
			table.insert(foreign, d.ClassName)
		end
	end
	for _, p in ipairs(ps) do
		if p.Anchored then
			anchored += 1
		end
		if p.CanCollide or p.CanTouch then
			solid += 1
		end
		if not p.CanQuery then
			queried[p.Name] = true
		end
	end
	check(#ps == 211 and motors == 25 and welds == 185,
		"the owner's 211 parts, 25 joints that move and 185 that hold", string.format("%d parts, %d motors, %d welds",
			#ps, motors, welds))
	check(anchored == 1 and m.PrimaryPart ~= nil and m.PrimaryPart.Name == "Footing" and m.PrimaryPart.Anchored
			and solid == 0 and queried.Footing and queried.PromptPlate and queried.DewHalo,
		"one anchored footing holds him; nothing collides or touches; footing, prompt plate and halo never found by a ray",
		string.format("%d anchored, %d solid", anchored, solid))
	check(#foreign == 0, "no script, prompt, BindableEvent or speech bubble of the builder's", table.concat(foreign, ", "))
	local top, low = -math.huge, math.huge
	for _, p in ipairs(ps) do
		for _, c in ipairs(corners(p)) do
			local l = at:PointToObjectSpace(c)
			top, low = math.max(top, l.Y), math.min(low, l.Y)
		end
	end
	local head = m:FindFirstChild("Head")
	local headLocal = at:PointToObjectSpace(head.Position)
	check((m:GetPivot().Position - at.Position).Magnitude < 1e-3 and m:GetPivot().LookVector:Dot(at.LookVector) > 0.9999
			and top > 6.9 and top < 7.3 and low > -0.05 and head.Size == Vector3.new(1.28, 1.12, 1.1)
			and (headLocal - Vector3.new(0, 4.43, -0.3)).Magnitude < 1e-3,
		"his pivot is the floor between his feet, facing local -Z; the Dewdrop tops out at about 7.1",
		string.format("top %.2f, low %.2f, head %s", top, low, tostring(headLocal)))
	local light = m:FindFirstChild("DewGlow", true)
	local sparkle = m:FindFirstChild("DewSparkle", true)
	check(light ~= nil and light:IsA("PointLight") and sparkle ~= nil and sparkle:IsA("ParticleEmitter")
			and light.Parent == sparkle.Parent, "the Dewdrop's glow and motes, on the Dewdrop")
	m:Destroy()

	--==========================================================================
	say("2. The surround (the owner's builder's own checks)")
	--==========================================================================
	local pivot = CFrame.new(-500, 5, 300) * CFrame.Angles(0, math.rad(-20), 0)
	local s = MistSurroundModel.build(pivot, stage)
	local sp = parts(s)
	local pad = s:FindFirstChild("Pad")
	local anchor = s.PrimaryPart
	local maxR, maxY, minY = 0, -math.huge, math.huge
	local padMinX, padMaxX, padTop = math.huge, -math.huge, -math.huge
	local archMinX, archMaxX = math.huge, -math.huge
	local cache = {}
	for _, p in ipairs(sp) do
		local cs = {}
		for _, c in ipairs(corners(p)) do
			local l = pivot:PointToObjectSpace(c)
			table.insert(cs, l)
			maxR = math.max(maxR, math.sqrt(l.X * l.X + l.Z * l.Z))
			maxY, minY = math.max(maxY, l.Y), math.min(minY, l.Y)
			if p.Parent == pad then
				padMinX, padMaxX, padTop = math.min(padMinX, l.X), math.max(padMaxX, l.X), math.max(padTop, l.Y)
			end
			if p.Parent and p.Parent.Name == "Arch" and p.Name ~= "ArchGem" then
				archMinX, archMaxX = math.min(archMinX, l.X), math.max(archMaxX, l.X)
			end
		end
		cache[p] = cs
	end
	-- Oriented box against an axis-aligned one, in the pivot's space (the builder's test).
	local function hitsBox(p, lo, hi)
		local rel = pivot:ToObjectSpace(p.CFrame)
		local axes = { Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1) }
		for _, a in ipairs({ rel.RightVector, rel.UpVector, -rel.LookVector }) do
			table.insert(axes, a)
			for _, e in ipairs({ Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1) }) do
				local c = a:Cross(e)
				if c.Magnitude > 1e-6 then
					table.insert(axes, c.Unit)
				end
			end
		end
		local box = {}
		for _, x in ipairs({ lo.X, hi.X }) do
			for _, y in ipairs({ lo.Y, hi.Y }) do
				for _, z in ipairs({ lo.Z, hi.Z }) do
					table.insert(box, Vector3.new(x, y, z))
				end
			end
		end
		for _, ax in ipairs(axes) do
			local aMin, aMax, bMin, bMax = math.huge, -math.huge, math.huge, -math.huge
			for _, c in ipairs(cache[p]) do
				local v = c:Dot(ax)
				aMin, aMax = math.min(aMin, v), math.max(aMax, v)
			end
			for _, c in ipairs(box) do
				local v = c:Dot(ax)
				bMin, bMax = math.min(bMin, v), math.max(bMax, v)
			end
			if aMax < bMin - 1e-4 or bMax < aMin - 1e-4 then
				return false
			end
		end
		return true
	end
	local floorY = MistSurroundModel.PadHeight + 0.02
	local corridorHits, npcHits, colliders, queryable, touchable, loose = {}, {}, 0, 0, 0, 0
	for _, p in ipairs(sp) do
		if p ~= anchor and p.Parent ~= pad then
			if hitsBox(p, Vector3.new(-LIMITS.ApproachWidth / 2, floorY, -LIMITS.MaxRadius),
				Vector3.new(LIMITS.ApproachWidth / 2, LIMITS.MaxHeight, 0)) then
				table.insert(corridorHits, p.Name)
			end
			if hitsBox(p, Vector3.new(-LIMITS.NpcClearRadius, floorY, -LIMITS.NpcClearRadius),
				Vector3.new(LIMITS.NpcClearRadius, LIMITS.NpcClearHeight, LIMITS.NpcClearRadius)) then
				table.insert(npcHits, p.Name)
			end
		end
		if p.CanCollide then
			colliders += 1
		end
		if p.CanQuery then
			queryable += 1
		end
		if p.CanTouch then
			touchable += 1
		end
		if not p.Anchored then
			loose += 1
		end
	end
	local padParts = pad and #pad:GetChildren() or 0
	check(#sp >= LIMITS.PartsMin and #sp <= LIMITS.PartsMax, "his surround is the owner's 60-90 parts", #sp)
	check(maxR <= LIMITS.MaxRadius and maxY <= LIMITS.MaxHeight and minY >= -0.01,
		"inside 20 studs of him, under 14, nothing below the floor",
		string.format("r %.2f, top %.2f, low %.3f", maxR, maxY, minY))
	check(math.abs(padMaxX - padMinX - MistSurroundModel.PadWidth) < 0.01
			and math.abs(padTop - MistSurroundModel.PadHeight) < 0.001
			and math.abs(archMaxX - archMinX - LIMITS.ArchSpan) <= LIMITS.ArchSpanTolerance,
		"a 12-wide pad 0.3 up, an arch about 18 wide", string.format("pad %.2f top %.2f, arch %.2f",
			padMaxX - padMinX, padTop, archMaxX - archMinX))
	check(#corridorHits == 0 and #npcHits == 0, "the open front: a 12-wide approach and his own space clear",
		table.concat(corridorHits, ",") .. " | " .. table.concat(npcHits, ","))
	check(loose == 0 and colliders == padParts and queryable == padParts and touchable == 0 and padParts > 0,
		"all anchored; only the pad collides and is found by a ray; nothing touches",
		string.format("%d colliders, %d queried, %d pad parts", colliders, queryable, padParts))
	local anchorLocal = anchor and pivot:PointToObjectSpace(anchor.Position)
	check(anchor ~= nil and anchor.Name == "NPCAnchor" and anchorLocal ~= nil
			and (anchorLocal - Vector3.new(0, MistSurroundModel.PadHeight, 0)).Magnitude < 1e-3
			and s:GetAttribute(MistSurroundModel.TagAttribute) == MistSurroundModel.BuilderTag,
		"his anchor at the pad's centre, feet level; the builder's tag kept")
	local foreignS = {}
	for _, d in ipairs(s:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("ProximityPrompt") then
			table.insert(foreignS, d.Name)
		end
	end
	check(#foreignS == 0, "no script or prompt in it", table.concat(foreignS, ", "))
	s:Destroy()

	--==========================================================================
	-- THE SERVICE, FROM ITS SOURCE
	--==========================================================================
	local mist = {}
	function mist.IsActive()
		return false
	end
	function mist.OnStart()
		return function() end
	end
	function mist.OnEnd()
		return function() end
	end
	local moduleScript = Server:WaitForChild("MosskeeperService")
	local chunk = loadstring(moduleScript.Source, "=MosskeeperService")
	setfenv(chunk, setmetatable({ script = moduleScript, require = function(target)
		if target.Name == "EnchantedMistService" then
			return mist
		elseif target.Name == "PlayerDataService" or target.Name == "CarryService" then
			return {}
		end
		return require(target)
	end }, { __index = getfenv(1) }))
	local M = chunk()
	local H = M.Hooks
	local shownFlag, active = true, false
	H.parent = function()
		return stage
	end
	H.shown = function()
		return shownFlag
	end
	H.active = function()
		return active
	end

	--==========================================================================
	say("3. Where he stands")
	--==========================================================================
	-- SINCE 2026-10-11 (the owner): him, his surround and the deck's dress
	-- stand ALWAYS, built once by Show(); he stands on the surround's pad.
	local npc = M.Show()
	-- Start calls Show once: the first call must dress the hub by itself.
	local firstSur, firstDeck = M.Surround(), M.Deck()
	M.Show()
	local padFeet = HUB.NpcAnchor * CFrame.new(0, MistSurroundModel.PadHeight, 0)
	local inPlaza, tallest = true, -math.huge
	for _, p in ipairs(parts(npc)) do
		for _, c in ipairs(corners(p)) do
			if (flat(c) - flat(HUB.Centre)).Magnitude > HUB.Radius then
				inPlaza = false
			end
			tallest = math.max(tallest, c.Y - (MAP.GroundY + HUB.FloorY))
		end
	end
	check(npc.Parent == stage and (npc:GetPivot().Position - padFeet.Position).Magnitude < 1e-3
			and npc:GetPivot().LookVector:Dot(Vector3.new(0, 0, -1)) > 0.9999 and M.Show() == npc,
		"on the hub's anchor, on his surround's pad (0.3 up), facing down the road; built once",
		tostring(npc:GetPivot().Position))
	check(inPlaza and tallest <= HUB.MaxHeight, "inside the plaza and under its height", string.format("%.2f", tallest))
	local sur = M.Surround()
	local surrounds = 0
	for _, c in ipairs(stage:GetChildren()) do
		if c.Name == MistSurroundModel.Name then
			surrounds += 1
		end
	end
	local surInPlaza = true
	for _, p in ipairs(sur and parts(sur) or {}) do
		for _, c in ipairs(corners(p)) do
			if (flat(c) - flat(HUB.Centre)).Magnitude > HUB.Radius + 1e-3
				or c.Y - (MAP.GroundY + HUB.FloorY) > HUB.MaxHeight + 1e-3 then
				surInPlaza = false
			end
		end
	end
	check(sur ~= nil and firstSur == sur and firstDeck ~= nil and firstDeck == M.Deck() and surrounds == 1
			and sur.Archivable == false and surInPlaza
			and sur.PrimaryPart.Position:FuzzyEq((HUB.NpcAnchor * CFrame.new(0, MistSurroundModel.PadHeight, 0)).Position,
				1e-3),
		"always, from his first Show: one surround, on his anchor, inside the plaza and under 14, never saved with the place")
	-- THE DECK'S DRESS (the owner: A's moss carpet with C's fairy ring), standing always.
	local D = EnchantedMistConfig.Deck
	local deck = M.Deck()
	local ticketMax, ticketMin = nil, nil
	local function findDeckZone(t, depth)
		if depth > 6 or type(t) ~= "table" then
			return
		end
		if t.Name == "Deck" and type(t.MaxRadius) == "number" then
			ticketMax = t.MaxRadius
			ticketMin = t.MinRadius
			return
		end
		for _, v in pairs(t) do
			findDeckZone(v, depth + 1)
		end
	end
	findDeckZone(GameConfig.MiniEvent, 0)
	local deckTop = MAP.GroundY + HUB.FloorY
	local solidDeck, inside, outRing, onRoad, nearSpawn, carpetTop = 0, true, true, 0, 0, nil
	local ringParts = 0
	for _, p in ipairs(deck and parts(deck) or {}) do
		if not p.Anchored or p.CanCollide or p.CanQuery or p.CanTouch then
			solidDeck += 1
		end
		if p.Name == "MossCarpet" then
			carpetTop = p.Position.Y + p.Size.X / 2
		elseif p.Parent and (p.Parent.Name == "Grove" or p.Parent.Name == "Detail") then
			-- measured below, each on its own rules
		else
			ringParts += 1
			-- A round part (a cap, a spot) by its real radius, a block by its corners.
			local round = p:IsA("Part") and (p.Shape == Enum.PartType.Cylinder or p.Shape == Enum.PartType.Ball)
			local reach = if round then p.Size.Y / 2 else 0
			local centreR = (flat(p.Position) - flat(HUB.Centre)).Magnitude
			if round and (centreR + reach > MAP.HubRadius or (ticketMax and centreR - reach < ticketMax + 0.5)) then
				if centreR + reach > MAP.HubRadius then
					inside = false
				else
					outRing = false
				end
			end
			for _, c in ipairs(if round then { p.Position } else corners(p)) do
				local f = flat(c) - flat(HUB.Centre)
				if not round and f.Magnitude > MAP.HubRadius then
					inside = false
				end
				if not round and ticketMax and f.Magnitude < ticketMax + 0.5 then
					outRing = false
				end
				local a = math.atan2(f.X, -f.Z)
				if math.abs(a) < math.rad(D.RoadGapDegrees) - 0.05 then
					onRoad += 1
				end
				if (flat(c) - flat(MAP.OverflowSpawn)).Magnitude < 4 then
					nearSpawn += 1
				end
			end
		end
	end
	check(deck ~= nil and deck.Parent == stage and deck.Archivable == false and ringParts > 0 and ringParts <= 90,
		"always, with the surround, the deck's dress: a moss carpet and a fairy ring", ringParts)
	check(solidDeck == 0, "overlays only: nothing of it collides, is found by a ray or touches", solidDeck)
	check(carpetTop ~= nil and carpetTop > deckTop + 1e-3 and carpetTop < deckTop + HUB.Floor.Rise - 1e-3,
		"the carpet lies a hair over the deck and under the plaza's floor, so the plaza still shows", carpetTop)
	check(ticketMax ~= nil and outRing and inside and onRoad == 0 and nearSpawn == 0,
		"the ring stands outside the Deck ticket ring and inside the deck, the road's side open, the overflow spawn clear",
		string.format("ticket max %s, road %d, spawn %d", tostring(ticketMax), onRoad, nearSpawn))
	-- THE GROVE: trees and flowers round him, a path to his front.
	local G = D.Grove
	local grove = deck and deck:FindFirstChild("Grove")
	local groveParts = grove and parts(grove) or {}
	local plate = M.PromptPoint()
	local half = HUB.ApproachWidth / 2
	local signBottom = MAP.GroundY + HUB.FloorY + EnchantedMistConfig.Sign.Above - EnchantedMistConfig.Sign.Height
	local wrongPlace, wrongPath, wrongLamp, crowd, tall = {}, {}, {}, 0, 0
	for _, p in ipairs(groveParts) do
		local name = p.Name
		for _, c in ipairs(corners(p)) do
			local f = flat(c) - flat(HUB.Centre)
			local r = f.Magnitude
			if r > MAP.HubRadius then
				table.insert(wrongPlace, name)
			end
			if (string.find(name, "^Tree") or string.find(name, "^Flowers")) and (r < HUB.Radius or r > (ticketMin or 0)) then
				table.insert(wrongPlace, name)
			end
			if string.find(name, "^Path") and (math.abs(f.X) > half or r > G.PathFrom + 0.5) then
				table.insert(wrongPath, name)
			end
			if string.find(name, "^Lantern") and (math.abs(f.X) < half or r > (ticketMin or 0)) then
				table.insert(wrongLamp, name)
			end
			if (flat(c) - flat(MAP.OverflowSpawn)).Magnitude < 4 or (plate and (flat(c) - flat(plate)).Magnitude < 4) then
				crowd += 1
			end
			if c.Y > MAP.GroundY + HUB.FloorY + G.TreeMaxHeight or c.Y > signBottom then
				tall += 1
			end
		end
	end
	check(grove ~= nil and #groveParts > 0 and #groveParts <= 220,
		"the grove: trees, glowing flowers, a stepping-stone path and its lanterns", #groveParts)
	check(#wrongPlace == 0, "trees and flowers between the plaza and the Deck ticket ring, all inside the deck",
		table.concat(wrongPlace, ","))
	check(#wrongPath == 0 and #wrongLamp == 0,
		"the path inside the surround's approach, its lanterns just outside it",
		table.concat(wrongPath, ",") .. " | " .. table.concat(wrongLamp, ","))
	check(crowd == 0 and tall == 0, "clear of the overflow spawn and of his Talk prompt, under the Mist sign", crowd + tall)
	-- THE DETAIL (the owner, 2026-10-11: "Grass tufts, more flowers, a small
	-- POND, decorative plants"): over the deck's open band, low, overlays only
	-- (above), clear of everything the hub is for.
	local T = D.Detail
	local detail = deck and deck:FindFirstChild("Detail")
	local detailParts = detail and parts(detail) or {}
	local setCount = #parts(npc) + (if sur then #parts(sur) else 0) + (if deck then #parts(deck) else 0)
	local kinds = { Tuft = 0, Wildflowers = 0, Fern = 0, Bush = 0, Shrooms = 0, Rock = 0, Log = 0, Clover = 0,
		PondWater = 0, PondRim = 0, PondPad = 0, PondReed = 0 }
	for _, p in ipairs(detailParts) do
		for kind in pairs(kinds) do
			if string.sub(p.Name, 1, #kind) == kind then
				kinds[kind] += 1
			end
		end
	end
	local missing = {}
	for kind, n in pairs(kinds) do
		if n == 0 then
			table.insert(missing, kind)
		end
	end
	table.sort(missing)
	check(detail ~= nil and detail:IsA("Folder") and #missing == 0 and #detailParts <= 200,
		string.format("the detail: grass tufts, wildflowers, ferns, bushes, mushrooms, rocks, a log, clover and a pond -- "
			.. "%d parts (200 at most), the hub's whole set %d", #detailParts, setCount), table.concat(missing, ","))
	local extras, shadows, unlit = {}, 0, {}
	for _, d in ipairs(detail and detail:GetDescendants() or {}) do
		if not d:IsA("BasePart") then
			table.insert(extras, d.ClassName)
		else
			if d.CastShadow then
				shadows += 1
			end
			if (d.Material == Enum.Material.Neon) ~= (d:GetAttribute("MistGlow") == true) then
				table.insert(unlit, d.Name)
			end
		end
	end
	check(#extras == 0 and shadows == 0, "cheap on phones and still: parts alone (no light, particle, beam, sound or "
		.. "script), none casting a shadow", table.concat(extras, ",") .. " / " .. shadows)
	check(#unlit == 0, "every glowing bit is MistGlow, so Reduced FX stills it on that screen, and only those glow",
		table.concat(unlit, ","))
	local spawnClear = 0
	for _, list in ipairs({ GameConfig.MiniEvent.KeepClear, GameConfig.MiniEvent.Dancers.KeepClear }) do
		for _, k in ipairs(list) do
			if k.Name == "Spawn" then
				spawnClear = math.max(spawnClear, k.Radius)
			end
		end
	end
	local ringInner = D.RingRadius - D.CapWidth / 2
	local outBand, roadSide, nearPlate, tooTall, nearGrove = {}, {}, {}, {}, {}
	for _, p in ipairs(detailParts) do
		for _, c in ipairs(corners(p)) do
			local f = flat(c) - flat(HUB.Centre)
			local r = f.Magnitude
			if r < T.MinRadius - 1e-3 or r > T.MaxRadius + 1e-3 then
				table.insert(outBand, p.Name)
			end
			if math.abs(math.atan2(f.X, -f.Z)) < math.rad(T.RoadGapDegrees) - 1e-3
				or (flat(c) - flat(MAP.OverflowSpawn)).Magnitude < spawnClear
				or (f.Z < 0 and math.abs(f.X) < half + 1) then
				table.insert(roadSide, p.Name)
			end
			if plate and (flat(c) - flat(plate)).Magnitude < CFG.TalkReach then
				table.insert(nearPlate, p.Name)
			end
			if c.Y > deckTop + T.TallMax then
				table.insert(tooTall, p.Name)
			end
		end
		for _, gp in ipairs(groveParts) do
			if (string.find(gp.Name, "Trunk$") or string.find(gp.Name, "Pad$"))
				and (flat(p.Position) - flat(gp.Position)).Magnitude < 1.6 then
				table.insert(nearGrove, p.Name .. "@" .. gp.Name)
			end
		end
	end
	check(T.MinRadius > HUB.Radius and T.MaxRadius < ringInner and ringInner < MAP.HubRadius and #outBand == 0
			and #nearGrove == 0,
		string.format("on the deck's open band, from %.1f (out of the plaza) to %.1f (inside the mushroom ring and the "
			.. "rim's step), off the grove's trees and flowers", T.MinRadius, T.MaxRadius),
		table.concat(outBand, ",", 1, math.min(#outBand, 6)) .. " | " .. table.concat(nearGrove, ",", 1,
			math.min(#nearGrove, 6)))
	check(#roadSide == 0, string.format("the road's side open: none within %d degrees of the road, on the approach or "
		.. "its path, or within %d studs of the overflow spawn", T.RoadGapDegrees, spawnClear),
		table.concat(roadSide, ",", 1, math.min(#roadSide, 6)))
	check(plate ~= nil and #nearPlate == 0 and #tooTall == 0 and T.TallMax < G.TreeMaxHeight
			and deckTop + T.TallMax < signBottom - 1.5,
		string.format("out of his Talk prompt's reach (%d) and the plaza with his bubbles and bar; under %.1f studs, "
			.. "well under the grove's trees and the Mist sign", CFG.TalkReach, T.TallMax),
		table.concat(nearPlate, ",", 1, math.min(#nearPlate, 6)) .. " | " .. table.concat(tooTall, ",", 1,
			math.min(#tooTall, 6)))
	-- The mini events' ground on the deck: where a ticket may fall (the hub's
	-- Area) and where a disco's dancers stand (the Dancers' Deck zone).
	local AREA = GameConfig.MiniEvent.Area
	local deckZone = nil
	for _, z in ipairs(GameConfig.MiniEvent.Dancers.Zones) do
		if z.Name == "Deck" then
			deckZone = z
		end
	end
	local function onEventGround(c)
		local d = flat(c) - flat(AREA.Centre)
		local angle = math.deg(math.atan2(d.Z, d.X))
		if d.Magnitude >= AREA.MinRadius and d.Magnitude <= AREA.MaxRadius then
			for _, s in ipairs(AREA.Sectors) do
				if angle >= s.From and angle <= s.To then
					return true
				end
			end
		end
		local r = flat(c).Magnitude
		if deckZone and r >= deckZone.MinRadius and r <= deckZone.MaxRadius then
			local a = math.deg(math.atan2(c.Z, c.X))
			for _, s in ipairs(deckZone.Sectors) do
				if (a - s.From) % 360 <= (s.To - s.From) then
					return true
				end
			end
		end
		return false
	end
	local function topOf(p)
		local y = -math.huge
		for _, c in ipairs(corners(p)) do
			y = math.max(y, c.Y)
		end
		return y
	end
	local onGround, blockers = {}, {}
	for _, p in ipairs(detailParts) do
		if topOf(p) > deckTop + T.LowMax or string.sub(p.Name, 1, 4) == "Pond" then
			local reach = 0
			for _, c in ipairs(corners(p)) do
				reach = math.max(reach, (flat(c) - flat(p.Position)).Magnitude)
				if onEventGround(c) and not table.find(onGround, p.Name) then
					table.insert(onGround, p.Name)
				end
			end
			table.insert(blockers, { at = flat(p.Position), reach = reach, name = p.Name })
		end
	end
	check(deckZone ~= nil and #blockers > 0 and #onGround == 0,
		string.format("nothing over %.1f studs, and no part of the pond, where a mini event's ticket may fall on the hub "
			.. "or a disco's dancer stand on the deck", T.LowMax), table.concat(onGround, ",", 1, math.min(#onGround, 6)))
	local DancerPlacement = require(Shared:WaitForChild("DancerPlacement"))
	local seen, inPlants = 0, nil
	for i = 1, 400 do
		for _, pick in ipairs(DancerPlacement.Picks(string.format("hubdetail%04dspec", i))) do
			seen += 1
			for _, b in ipairs(blockers) do
				if (flat(pick.at) - b.at).Magnitude < pick.radius + b.reach then
					inPlants = inPlants or string.format("%s at (%.1f, %.1f)", b.name, pick.at.X, pick.at.Z)
				end
			end
		end
	end
	check(seen > 2000 and inPlants == nil, string.format("no dancer of 400 discos (%d) stands in the pond or a bush",
		seen), inPlants)
	local waters, flush = 0, true
	for _, p in ipairs(detailParts) do
		if string.find(p.Name, "^PondWater") or p.Name == "PondDeep" then
			waters += 1
			local top = p.Position.Y + p.Size.X / 2
			flush = flush and p:IsA("Part") and p.Shape == Enum.PartType.Cylinder and p.CFrame.RightVector.Y > 0.9999
				and p.Size.X <= 0.1 and carpetTop ~= nil and top > carpetTop + 1e-3 and top <= deckTop + 0.15
		end
	end
	local deckSrc = Shared:WaitForChild("MistDeckModel").Source
	check(waters >= 2 and flush and not string.find(deckSrc, "Terrain", 1, true),
		"the pond: a flush painted surface a hair over the carpet, under 0.15 over the deck, never Terrain water -- "
			.. "nothing to swim in, wade through or trip on", waters)
	-- No Dewberry falls on it: every zone the berries use near the plots
	-- starts outside the deck (the rest are the biomes' road).
	local berryZones, berryOff = 0, true
	for name in pairs(EnchantedMistData.Spawn.SafeZones) do
		for _, z in ipairs(GameConfig.MiniEvent.Zones) do
			if z.Name == name then
				berryZones += 1
				if z.Kind == "ring" then
					berryOff = berryOff and z.MinRadius > MAP.HubRadius
				elseif z.Kind == "box" then
					berryOff = berryOff and Vector2.new(math.clamp(0, z.X0, z.X1), math.clamp(0, z.Z0, z.Z1)).Magnitude
						> MAP.HubRadius
				else
					berryOff = false
				end
			end
		end
	end
	check(berryZones > 0 and berryOff, "no Dewberry falls among it: every zone the berries use near the plots starts "
		.. "outside the deck")
	local MistDeckModel = require(Shared:WaitForChild("MistDeckModel"))
	local again = MistDeckModel.build(nil)
	local mine, theirs = detailParts, parts(again:FindFirstChild("Detail") or again)
	local same = #mine == #theirs
	for i = 1, math.min(#mine, #theirs) do
		if mine[i].Name ~= theirs[i].Name or not mine[i].CFrame:FuzzyEq(theirs[i].CFrame, 1e-6)
			or mine[i].Size ~= theirs[i].Size then
			same = false
		end
	end
	again:Destroy()
	check(same, "built the same every time (each piece by its own seed): one hub on every server, for every late joiner")
	-- Mist or not: nothing takes the set down (no hook on a Mist's start or end).
	local serviceSrc = moduleScript.Source
	check(not string.find(serviceSrc, "EnchantedMistService.OnStart(", 1, true)
			and not string.find(serviceSrc, "EnchantedMistService.OnEnd(", 1, true)
			and (M :: any)._surroundDown == nil and (M :: any)._surroundUp == nil
			and M.Surround() == sur and M.Deck() == deck and sur ~= nil and sur.Parent == stage
			and deck ~= nil and deck.Parent == stage,
		"Mist or not, the surround and the deck's dress stand: nothing builds or removes them on a Mist's start or end")

	--==========================================================================
	say("4. His prompt")
	--==========================================================================
	local talk = npc:FindFirstChild(CFG.PromptName, true)
	check(talk ~= nil and talk:IsA("ProximityPrompt") and talk.Parent and talk.Parent.Name == MosskeeperModel.PromptPart
			and talk.HoldDuration == 0 and talk.Style == Enum.ProximityPromptStyle.Custom
			and talk.KeyboardKeyCode == Enum.KeyCode.E and talk.ActionText == CFG.ActionText
			and talk.MaxActivationDistance == CFG.TalkReach and not talk.RequiresLineOfSight,
		"tap E -- Talk: a tap, not a hold, drawn by PromptUI, on his plate in front of him")
	local plate = M.PromptPoint()
	local berryNearest = GameConfig.MiniEvent.Area.MinRadius - (flat(plate) - flat(HUB.Centre)).Magnitude
	check(berryNearest > CFG.TalkReach + EnchantedMistData.Spawn.Reach,
		"no berry can share his ground: the nearest a berry may lie is past both reaches",
		string.format("%.1f vs %d", berryNearest, CFG.TalkReach + EnchantedMistData.Spawn.Reach))

	--==========================================================================
	say("5. Give all")
	--==========================================================================
	local clock = 100
	local P = { Name = "SpecGiver", UserId = 90000000041 }
	local profiles = { [P] = { DewberriesCarried = 0, DewberryProgress = 0 } }
	local ready, carrying, bagReady, room = true, false, true, 5
	local grants, grantOk = 0, true
	local notes = {}
	local root = plate + Vector3.new(0, -1, -5)
	H.now = function()
		return clock
	end
	H.ready = function(p)
		return ready and profiles[p] ~= nil
	end
	H.profile = function(p)
		return profiles[p]
	end
	-- A transaction: committed only when the change says yes.
	H.update = function(p, change)
		local prof = profiles[p]
		if not prof then
			return false
		end
		local copy = table.clone(prof)
		if change(copy) then
			profiles[p] = copy
			return true
		end
		return false
	end
	H.root = function()
		return root
	end
	H.carryingPod = function()
		return carrying
	end
	H.bagReady = function()
		return bagReady
	end
	H.podRoom = function()
		return room
	end
	local grantFn = function(_p, prof)
		grants += 1
		if grantOk then
			prof.SpecPods = (prof.SpecPods or 0) + 1
		end
		return grantOk
	end
	H.grantPod = grantFn
	H.notify = function(_p, payload)
		table.insert(notes, payload)
	end
	local function give(carried, progress)
		local prof = profiles[P]
		if carried then
			prof.DewberriesCarried = carried
		end
		if progress then
			prof.DewberryProgress = progress
		end
		clock += 1
		return M.Give(P)
	end
	local function same(c, g)
		return profiles[P].DewberriesCarried == c and profiles[P].DewberryProgress == g
	end

	local r = give(5, 0)
	check(r.phase == "refused" and r.reason == "INACTIVE" and same(5, 0),
		"no Mist: refused, nothing taken -- he can accept berries only while it runs", r.reason)
	active = true
	root = plate + Vector3.new(0, 0, -(CFG.TalkReach + CFG.ReachSlack + 1))
	r = give()
	check(r.reason == "FAR" and same(5, 0), "too far from him: refused", r.reason)
	root = nil
	r = give()
	check(r.reason == "FAR", "no living body: refused", r.reason)
	root = plate + Vector3.new(0, -1, -5)
	carrying = true
	r = give()
	check(r.reason == "CARRYING" and same(5, 0), "a pod in hand: refused", r.reason)
	carrying = false
	ready = false
	r = give()
	check(r.reason == "NOT_LOADED" and same(5, 0), "a save still loading: refused", r.reason)
	ready = true
	shownFlag = false
	r = give()
	check(r.reason == "GONE", "him switched off: refused", r.reason)
	shownFlag = true
	r = give(0, 3)
	check(r.reason == "EMPTY" and same(0, 3), "nothing carried: refused", r.reason)

	-- The 15-berry example, cumulative.
	notes = {}
	local a1 = give(5, 0)
	local after1 = same(0, 5)
	local a2 = give(5, nil)
	local after2 = same(0, 0)
	local a3 = give(5, nil)
	local after3 = same(0, 5)
	check(a1.phase == "given" and a1.delivered == 5 and a1.pods == 0 and a1.progress == 5 and after1
			and a2.phase == "given" and a2.pods == 1 and a2.progress == 0 and after2
			and a3.phase == "given" and a3.pods == 0 and a3.progress == 5 and after3
			and grants == 1 and profiles[P].SpecPods == 1,
		"15 delivered five at a time: 5/10, then one pod and 0/10, then 5/10 -- the pod granted once",
		string.format("%s %s %s, grants %d", tostring(a1.progress), tostring(a2.pods), tostring(a3.progress), grants))
	check(#notes == 3 and notes[2].title == string.format(CFG.Words.GivenPod, 5) and notes[1].key == CFG.NoticeKey,
		"each delivery is told once, the pod by name", #notes)
	-- Carry 5 and 9 saved: still one pod, 4 kept.
	r = give(5, 9)
	check(r.phase == "given" and r.pods == 1 and r.progress == 4 and same(0, 4) and grants == 2,
		"5 onto 9 saved: one pod, 4 kept (one delivery earns at most one)", r.progress)

	-- A full Bag: the whole of a pod-earning delivery refused, nothing taken.
	room = 0
	r = give(5, 5)
	check(r.reason == "BAG_FULL" and same(5, 5) and grants == 2,
		"a full Bag refuses a delivery that would earn a pod -- all of it, nothing deducted", r.reason)
	check(CFG.Words.Refused.BAG_FULL == "Make room in your Bag.", "\"Make room in your Bag.\"")
	r = give(3, 0)
	check(r.phase == "given" and r.progress == 3 and same(0, 3),
		"a delivery under the threshold is taken with a full Bag", r.reason)
	room = 5
	bagReady = false
	r = give(5, 5)
	check(r.reason == "BAG_NOT_READY" and same(5, 5), "a Bag not yet restored: refused, nothing taken", r.reason)
	bagReady = true
	grantOk = false
	r = give(5, 5)
	check(r.phase == "refused" and same(5, 5) and profiles[P].SpecPods == 2,
		"the grant failing inside the change refuses it whole", r.reason)
	grantOk = true
	H.grantPod = nil
	r = give(5, 5)
	check(r.reason == "POD_NOT_READY" and same(5, 5),
		"no Mysterious Pod yet (stage 4): a pod-earning delivery refused whole", r.reason)
	r = give(4, 5)
	check(r.phase == "given" and same(0, 9), "and one that earns none still taken", r.reason)
	H.grantPod = grantFn
	-- One at a time.
	profiles[P].DewberriesCarried = 2
	profiles[P].DewberryProgress = 0
	clock += 5
	local first = M.Give(P)
	profiles[P].DewberriesCarried = 2
	local second = M.Give(P)
	check(first.phase == "given" and second.reason == "BUSY" and same(2, 2),
		"two requests inside GiveGap: the second waits", second.reason)
	-- The client's numbers are never read.
	local src = moduleScript.Source
	check(string.find(src, "Hooks.send(player, MosskeeperService.Give(player))", 1, true) ~= nil
			and string.find(src, "OnServerEvent:Connect(function(player: Player, action: any)\n", 1, true) ~= nil,
		"a Give all carries no amount: the server reads only who asked")

	--==========================================================================
	say("6. Talk")
	--==========================================================================
	local sent = {}
	H.send = function(_p, payload)
		table.insert(sent, payload)
	end
	active = false
	M._talk(P)
	active = true
	M._talk(P)
	ready = false
	M._talk(P)
	ready = true
	check(#sent == 2 and sent[1].phase == "open" and sent[1].active == false and sent[2].active == true,
		"Talk opens his dialogue whether or not a Mist runs; nothing for a player still loading", #sent)

	--==========================================================================
	say("7. His life (Shared/MosskeeperIdle)")
	--==========================================================================
	local still = function()
		return 0.5
	end
	local brainA = MosskeeperIdle.new(npc, still)
	local quiet = { players = {}, serving = false, reducedFx = false }
	local t0 = 2000
	for i = 0, 18000 do
		brainA.step(t0 + i / 60, quiet)
	end
	-- A second him, fresh, stepped only to the same moment: the JOINTS (what is
	-- drawn) must match, not just the brain's own record.
	local twin = MosskeeperModel.build(CFrame.new(300, 20, 300), stage)
	local brainB = MosskeeperIdle.new(twin, still)
	for i = -60, 0 do
		brainB.step(t0 + 300 + i / 60, quiet)
	end
	local drift = 0
	for _, name in ipairs(MosskeeperIdle.JointNames) do
		if name ~= "LidRJoint" and name ~= "LidLJoint" then
			local a = (npc:FindFirstChild(name, true) :: Motor6D).Transform
			local b = (twin:FindFirstChild(name, true) :: Motor6D).Transform
			drift = math.max(drift, (a.Position - b.Position).Magnitude, (a.LookVector - b.LookVector).Magnitude,
				(a.UpVector - b.UpVector).Magnitude)
		end
	end
	twin:Destroy()
	check(drift < 1e-4, "after five minutes his pose is a fresh one's at the same moment: nothing drifts",
		string.format("%.2e", drift))
	local pivotCF = npc:GetPivot()
	local brainC = MosskeeperIdle.new(npc, still)
	local front = { players = { (pivotCF * CFrame.new(0, 3, -9)).Position }, serving = false, reducedFx = false }
	local waved = 0
	for i = 0, 60 do
		brainC.step(5000 + i / 60, front)
		waved = math.max(waved, brainC.wave)
	end
	local side = { players = { (pivotCF * CFrame.new(-8, 3, -8)).Position }, serving = false, reducedFx = false }
	for i = 61, 240 do
		brainC.step(5000 + i / 60, side)
	end
	check(waved > 0.5 and brainC.lookYaw > 0.3,
		"he waves at a newcomer and turns his head to a player at his side",
		string.format("wave %.2f, yaw %.2f", waved, brainC.lookYaw))
	local serving = { players = { (pivotCF * CFrame.new(0, 3, -6)).Position }, serving = true, reducedFx = true }
	for i = 241, 420 do
		brainC.step(5000 + i / 60, serving)
	end
	local flap = brainC.pose.SatchelFlapJoint
	local lamp = npc:FindFirstChild("DewGlow", true)
	local motes = npc:FindFirstChild("DewSparkle", true)
	local rx = if flap then math.atan2(flap.LookVector.Y, -flap.LookVector.Z) else 0
	check(brainC.busy > 0.9 and math.abs(rx) > 0.9 and math.abs(lamp.Brightness - 1.2) < 1e-3 and not motes.Enabled,
		"serving the player who talks to him he bows and opens his satchel; Reduced FX stills the glow",
		string.format("busy %.2f, flap %.2f, lamp %.2f", brainC.busy, rx, lamp.Brightness))
	brainC.rest()
	local rested = true
	for _, name in ipairs(MosskeeperIdle.JointNames) do
		local j = npc:FindFirstChild(name, true)
		if j and j.Transform ~= CFrame.new() then
			rested = false
		end
	end
	check(rested, "and back to the builder's rest pose on request")

	--==========================================================================
	say("8. The wiring")
	--==========================================================================
	local mistSrc = Server:WaitForChild("EnchantedMistService").Source
	check(M.Priority == 77 and string.find(mistSrc, "EnchantedMistService.Priority = 75", 1, true) ~= nil,
		"started after the coordinator and its berries")
	check(EnchantedMistConfig.ShowMosskeeper == true and EnchantedMistConfig.Enabled == true,
		"he stands in the hub (the owner, 2026-10-11); the event's schedule on (the owner, 2026-10-12)")
	local ui = Scripts:WaitForChild("MosskeeperUI").Source
	local view = Scripts:WaitForChild("MosskeeperView").Source
	check(string.find(ui, "camera.CameraType ~= Enum.CameraType.Custom or camera.CameraSubject ~= humanoid or "
			.. "VRService.VREnabled", 1, true) ~= nil
			and string.find(ui, "camera:GetAttribute(CAMERA_MARK) ~= true then", 1, true) ~= nil
			and string.find(ui, "gui.ResetOnSpawn = false", 1, true) ~= nil,
		"the dialogue borrows only the default camera and gives back only its own")
	local Odds = require(Shared:WaitForChild("MistOddsView"))
	local c = EnchantedMistData.creatureChance
	check(Odds.animationFor(c("snarlbloom")) == "rainbow" and Odds.animationFor(c("gnarlmaw")) == "shimmer"
			and Odds.animationFor(EnchantedMistData.sizeChance(7)) == "shimmer"
			and Odds.animationFor(c("elderbough")) == nil and Odds.animationFor(c("mossbristle")) == nil,
		"the odds: 0.2% a rapid rainbow, the others under 1% a shimmer, the rest still")
	check(Odds.percent(c("snarlbloom")) == "0.2%" and Odds.percent(c("mossbristle")) == "60%"
			and Odds.percent(EnchantedMistData.sizeChance(7)) == "0.52%"
			and Odds.percent(EnchantedMistData.sizeChance(1)) == "53.25%",
		"written as percentages from the server's own numbers", Odds.percent(c("snarlbloom")))
	check(string.find(ui, "theme = MenuKit.studdedTheme(CFG.Look)", 1, true) ~= nil
			and string.find(ui, "MistOddsView.build(oddsHolder", 1, true) ~= nil,
		"his panels wear the studded kit; the Odds page is the cards")
	check(string.find(view, "p:GetAttribute(\"MistGlow\")", 1, true) ~= nil
			and string.find(view, "if reduced then Enum.Material.SmoothPlastic else Enum.Material.Neon", 1, true) ~= nil,
		"Reduced FX stills the fairy ring's glow on that screen")
	check(string.find(view, "RunService.PreSimulation:Connect", 1, true) ~= nil
			and not string.find(moduleScript.Source, "MosskeeperIdle", 1, true),
		"his life runs on each client, never the server")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
stage:Destroy()
say(string.format("\nMosskeeperSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
