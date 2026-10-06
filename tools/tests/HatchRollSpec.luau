--!nocheck
--==============================================================================
-- Steal a Seed :: HatchRollSpec
--
-- THE ROLL (2026-09-29; in the world since the same day): the three seconds
-- between a pod bursting and its plant being shown, in which the place where
-- the pod stood turns silhouettes over under a question mark. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchRollSpec"))
--
-- The owner's rules, which are what is asserted:
--
--   "show a lightweight world-space animation at that pod's exact position.
--    For about 3 seconds, quickly cycle plant silhouettes with a floating
--    question mark, slow the cycle, then reveal the actual plant there with the
--    existing hatch effects. Nearby players should be able to see it. Do not
--    open a modal, cover the camera, stop movement, or add a lingering result
--    panel."
--   "The real plant must still be determined and safely recorded by the server
--    before the cosmetic animation. This is not a second roll."
--   "reuse the temporary ??? masking only until the world reveal finishes; do
--    not make the player wait longer than necessary to use it."
--   "handle simultaneous hatches, streaming, leaving, and respawning without
--    stuck question marks or lost plants."
--
-- HatchRoll is loaded from its source with the switch set each way, because a
-- spec runs in Studio and the Studio preview would otherwise decide for it.
-- PlantService is the real one with the roll ON, against the stand-ins
-- HatchRevealSpec uses; that spec is the same hatch with the roll OFF.
--
-- THE WORLD'S SIDE IS RUN, not only read: HatchFX's own source, with a player,
-- a frame clock and a sound kit that stand in, draws real rolls where nobody is
-- looking and is watched frame by frame (section 9).
--
-- Not here: what any of it looks like (Play, and the owner's eyes), and what a
-- hatch must never cost -- a plant lost or handed over twice -- which is
-- HatchDeliverySpec's, against the real CarryService.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))

local HATCH = GameConfig.Plant.Hatch
local ROLL = HATCH.Roll
local WORLD = ROLL.World
local BURST = GameConfig.Plant.BurstSeconds

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
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local function near(a, b, within)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) < (within or 1e-6)
end

--==============================================================================
-- LOADING A MODULE WITH SOMETHING ELSE IN ITS HANDS
--==============================================================================
local function gameWith(services)
	local stand = {}
	function stand:GetService(name)
		if services[name] ~= nil then
			return services[name]
		end
		return game:GetService(name)
	end
	return stand
end

local outerRequire = require
local function loadWith(module, siblings, overrides, gameStandIn)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local env = setmetatable({
		game = gameStandIn or game,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			if overrides and typeof(target) == "Instance" and overrides[target.Name] ~= nil then
				return overrides[target.Name]
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

-- GameConfig with the roll's numbers replaced, and everything else its own.
local function configWith(roll, base)
	local rollConfig = setmetatable(roll, { __index = ROLL })
	local hatchConfig = setmetatable({ Roll = rollConfig }, { __index = HATCH })
	local plant = setmetatable({ Hatch = hatchConfig }, { __index = GameConfig.Plant })
	return setmetatable({ Plant = plant }, { __index = base or GameConfig })
end

local function rollWith(roll, gameStandIn)
	return loadWith(Shared.HatchRoll, {
		GameConfig = configWith(roll),
		SeedData = SeedData,
	}, nil, gameStandIn)
end

local published = gameWith({
	RunService = {
		IsStudio = function()
			return false
		end,
	},
})

-- What a script says, for the checks that read it: PLAIN FINDS only, since a Luau
-- string full of dots and brackets is a pattern that matches nothing.
local function sourceOf(instance)
	if instance == nil then
		return nil
	end
	local ok, src = pcall(function()
		return (instance :: any).Source
	end)
	return if ok then src else nil
end

local function times(source, plain)
	local n, at = 0, 1
	while true do
		local found, stop = source:find(plain, at, true)
		if not found then
			return n
		end
		n += 1
		at = stop + 1
	end
end

local fixture = nil
local plotModel = nil
local PlantService = nil

local function body()
	fixture = Instance.new("Folder")
	fixture.Name = "HatchRollSpecFixture"
	fixture.Parent = Workspace

	--==========================================================================
	-- 1. THE SWITCH, AS IT SHIPS
	--==========================================================================
	say("\n-- the switch --")
	local rollOn = rollWith({ Enabled = true, StudioPreview = false })
	local rollOff = rollWith({ Enabled = false, StudioPreview = false })
	do
		-- The tripwire, changed with the switch: the owner switched the roll on for
		-- players on 2026-09-30.
		check(ROLL.Enabled == true,
			"as shipped, the roll is ON on a published server: the owner switched it on on 2026-09-30",
			ROLL.Enabled)
		check(ROLL.StudioPreview == true,
			"and ON in Studio, which is where the owner asked to see it first", ROLL.StudioPreview)
		local shipped = loadWith(Shared.HatchRoll, { GameConfig = GameConfig, SeedData = SeedData },
			nil, published)
		check(shipped.live() == true,
			"so a published server with the shipped numbers rolls")
		check(near(shipped.revealAt(1000), 1000 + ROLL.Seconds),
			"and shows a hatched plant its three seconds after the hatch")
		local studio = loadWith(Shared.HatchRoll, { GameConfig = GameConfig, SeedData = SeedData })
		check(studio.live() == true, "while in Studio the same numbers give the preview")
		check(rollOn.live() == true and rollOff.live() == false,
			"and Enabled alone decides it once StudioPreview is out of the way")
		local approved = rollWith({ Enabled = true, StudioPreview = false }, published)
		check(approved.live() == true and near(approved.revealAt(1000), 1000 + ROLL.Seconds),
			"switched on, a published server rolls")
		check(ROLL.Attribute == "RevealAt" and rollOn.Attribute == "RevealAt"
				and rollOn.Unknown == "???",
			"a plant still being rolled for says so in RevealAt, and is called ???")

		-- The card the owner did not want, and everything that was only its.
		check(rawget(ROLL, "ShowSeconds") == nil and rawget(ROLL, "MaxWaitSeconds") == nil,
			"the numbers of the card are gone: how long it stayed, how long a hatch waited for it")
		check(rollOn.schedule == nil and rollOn.cardSeconds == nil and rollOn.claim == nil,
			"and so are its queue, its length and its turn at the fanfare")
		local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
		check(scripts ~= nil and scripts:FindFirstChild("HatchRollUI") == nil,
			"there is no hatch card script")
		local named = {}
		for _, child in ipairs(if scripts then scripts:GetChildren() else {}) do
			local text = sourceOf(child)
			if text and (text:find("SeedHatchRoll", 1, true) or text:find("HatchRollUI", 1, true)) then
				table.insert(named, child.Name)
			end
		end
		check(#named == 0, "and no client script draws one, or speaks of one", table.concat(named, ", "))
	end

	--==========================================================================
	-- 2. ABOUT THREE SECONDS; QUICK, THEN SLOW
	--==========================================================================
	say("\n-- the owner's three seconds --")
	do
		check(ROLL.Seconds >= 2.5 and ROLL.Seconds <= 3.5,
			string.format("from the hatch to the plant is %.2fs: about three", ROLL.Seconds))
		check(near(rollOn.seconds(), ROLL.Seconds) and near(rollOn.revealAt(500) - 500, ROLL.Seconds),
			"which is the time the server gives a hatch")
		check(near(rollOn.lead(false), BURST * 0.55)
				and near(rollOn.lead(true), BURST * 0.55 + HATCH.Paid.PulseSeconds),
			"the shell bursts first: the silhouettes begin where the creature used to, a pulse later for a purchase")
		for _, paid in ipairs({ false, true }) do
			local holds = rollOn.holds(paid)
			local total, least, rising = 0, math.huge, true
			for i, hold in ipairs(holds) do
				total += hold
				least = math.min(least, hold)
				if i > 1 and hold < holds[i - 1] - 1e-9 then
					rising = false
				end
			end
			local who = if paid then "a purchase" else "a free hatch"
			check(#holds == ROLL.Steps and near(total, rollOn.cycle(paid))
					and near(total + rollOn.lead(paid), ROLL.Seconds),
				string.format("%s: %d silhouettes fill the %.3fs from the burst to the reveal exactly", who,
					#holds, total))
			check(rising and holds[1] <= 0.2 and holds[#holds] >= holds[1] * 3,
				string.format("%s: quick, then slow -- the first is up for %.3fs and the last for %.3fs", who,
					holds[1], holds[#holds]))
			check(least >= ROLL.FloorHold and ROLL.FloorHold >= 0.1,
				string.format("%s: nothing flickers -- the shortest hold is %.3fs", who, least))
		end

		-- Numbers changed to make another roll do not load at all.
		local function refuses(roll)
			local ok = pcall(rollWith, roll)
			return not ok
		end
		check(refuses({ Enabled = true, Seconds = 5.5, MaxSeconds = 6 }),
			"the five and a half seconds of the card are refused when the module loads")
		check(refuses({ Enabled = true, Seconds = 1.5, MinSeconds = 1 }),
			"and so is a roll too short to be one")
		check(refuses({ Enabled = true, Seconds = 3.4, MaxSeconds = 3.2 }),
			"and one longer than its own ceiling")
		check(refuses({ Enabled = true, Steps = 2 }), "and one of fewer than three silhouettes")
		check(refuses({ Enabled = true, FirstHold = 0.9, LastHold = 0.2 }),
			"and one that would start slow and end quick")
		check(refuses({ Enabled = true, FirstHold = 0.01, LastHold = 3 }),
			"and one whose first silhouettes would flicker")
		check(refuses({ Enabled = true, MaxHideSeconds = 2 }),
			"and one whose plant could be shown later than it may be hidden")
	end

	--==========================================================================
	-- 3. THE SILHOUETTES END ON THE PLANT THAT HATCHED
	--==========================================================================
	say("\n-- not a second roll --")
	do
		local tokens = { 0, 1, 2, 3, 17, 255, 999, 123456, 2147483646, 2147483647, 9e15 }
		local species = SeedData.Species
		check(#species >= 20, "every species is tried", #species)

		local endsRight, sameBiome, noRepeat, everyShape, timed, counted = 0, 0, 0, 0, 0, 0
		local heldRight = 0
		local holds = rollOn.holds(false)
		local cycle = rollOn.cycle(false)
		local rolls = 0
		local firstBad = nil
		for _, one in ipairs(species) do
			local pool = {}
			for _, other in ipairs(SeedData.InBiome(one.Biome)) do
				pool[other.Id] = true
			end
			local poolSize = #SeedData.InBiome(one.Biome)
			for _, token in ipairs(tokens) do
				rolls += 1
				local frames = rollOn.frames(one.Id, token)
				local ok = { last = frames[#frames].speciesId == one.Id, biome = true, neighbours = true,
					clock = true, held = #frames == #holds }
				local seen, shapes = {}, 0
				local at = 0
				for i, frame in ipairs(frames) do
					if not pool[frame.speciesId] then
						ok.biome = false
					end
					-- A frame is a share of the cycle; a hold is that share in seconds.
					if not near((frame.to - frame.from) * cycle, holds[i], 1e-4) then
						ok.held = false
					end
					if i > 1 and frames[i - 1].speciesId == frame.speciesId then
						ok.neighbours = false
					end
					if not near(frame.from, at) or frame.to <= frame.from then
						ok.clock = false
					end
					at = frame.to
					if not seen[frame.speciesId] then
						seen[frame.speciesId] = true
						shapes += 1
					end
				end
				if not near(at, 1) then
					ok.clock = false
				end
				endsRight += if ok.last then 1 else 0
				sameBiome += if ok.biome then 1 else 0
				noRepeat += if ok.neighbours then 1 else 0
				timed += if ok.clock then 1 else 0
				heldRight += if ok.held then 1 else 0
				counted += if #frames == ROLL.Steps then 1 else 0
				everyShape += if shapes == math.min(poolSize, ROLL.Steps) then 1 else 0
				if firstBad == nil and not (ok.last and ok.biome and ok.neighbours and ok.clock) then
					firstBad = string.format("%s token %s", one.Id, tostring(token))
				end
			end
		end
		check(endsRight == rolls,
			string.format("all %d rolls end on the plant that was handed in", rolls),
			string.format("%d did; first wrong: %s", endsRight, tostring(firstBad)))
		check(counted == rolls, "each is one silhouette per hold", counted)
		check(sameBiome == rolls,
			"every silhouette is a plant of the pod's own biome: the shapes that shell could hold",
			sameBiome)
		check(noRepeat == rolls, "no shape is shown twice running, so every turn is seen to turn",
			noRepeat)
		check(everyShape == rolls, "and every plant of the biome is shown in every roll", everyShape)
		check(timed == rolls, "the silhouettes follow one another with no gap, from the burst to the reveal",
			timed)
		check(heldRight == rolls,
			"and each is up for exactly its own hold: the plant's shape is not brought on early", heldRight)

		-- The same hatch is the same roll, on every screen and however often it is drawn.
		local function spell(frames)
			local ids = {}
			for _, frame in ipairs(frames) do
				table.insert(ids, frame.speciesId)
			end
			return table.concat(ids, ",")
		end
		local first = spell(rollOn.frames("nubkin", 4242))
		math.randomseed(1)
		local again = spell(rollOn.frames("nubkin", 4242))
		math.randomseed(987654)
		math.random()
		local third = spell(rollOff.frames("nubkin", 4242))
		check(first == again and first == third,
			"one hatch is one roll for everybody who sees it: the same token and plant give the same "
				.. "silhouettes, whatever else has used a random number since", first)
		local distinct, kinds = {}, 0
		for token = 1, 40 do
			local spelled = spell(rollOn.frames("nubkin", token))
			if not distinct[spelled] then
				distinct[spelled] = true
				kinds += 1
			end
		end
		check(kinds >= 20, "and different hatches are different rolls", kinds .. " of 40")

		-- The plant is an argument and never a result.
		local stranger = rollOn.frames("not-a-plant", 7)
		check(#stranger == ROLL.Steps and stranger[#stranger].speciesId == "not-a-plant",
			"a plant it has never heard of is still what the roll ends on: it picks nothing itself")
		local source = Shared.HatchRoll.Source
		check(source:find("SeedData.Roll", 1, true) == nil and source:find("RollTier", 1, true) == nil
				and source:find("RollKg", 1, true) == nil and source:find("math.random", 1, true) == nil,
			"and the module calls none of the game's rolls")
		check(source:find("FireServer", 1, true) == nil and source:find("SetAttribute", 1, true) == nil
				and source:find("Instance.new", 1, true) == nil,
			"sends nothing, writes nothing and makes nothing")

		-- Which silhouette is up at a moment.
		local frames = rollOn.frames("nubkin", 5)
		local right = rollOn.frameAt(frames, -3) == 1 and rollOn.frameAt(frames, 0) == 1
			and rollOn.frameAt(frames, 5) == #frames
		for i, frame in ipairs(frames) do
			if rollOn.frameAt(frames, frame.from) ~= i
				or rollOn.frameAt(frames, (frame.from + frame.to) * 0.5) ~= i then
				right = false
			end
			if i > 1 and rollOn.frameAt(frames, frame.from - 1e-6) ~= i - 1 then
				right = false
			end
		end
		check(right, "a late frame draws where the roll IS: each moment has one silhouette, in order")
		check(rollOn.frameAt(frames, 1 - 1e-6) == #frames and frames[#frames].from < 1,
			"and the last thing standing before the reveal is the plant's own silhouette")
	end

	--==========================================================================
	-- 4. EVERY HATCH HAS ITS OWN THREE SECONDS
	--==========================================================================
	say("\n-- nothing waits for anything else --")
	do
		local now = 50000
		local worst, least = 0, math.huge
		for i = 0, 59 do
			local at = now + i * 0.05
			local shown = rollOn.revealAt(at)
			worst = math.max(worst, shown - at)
			least = math.min(least, shown - at)
		end
		check(near(worst, ROLL.Seconds) and near(least, ROLL.Seconds),
			string.format("sixty hatches in three seconds: every one is shown %.2fs after it hatched", worst))
		check(rollOn.hidden(rollOn.revealAt(now), now) == true,
			"and that is a time the masks honour")
		check(rollOff.revealAt(now) == now, "switched off, a hatch is shown as it happens")
	end

	--==========================================================================
	-- 5. A SECRET CAN RUN OUT; IT CANNOT GET STUCK
	--==========================================================================
	say("\n-- the masks expire --")
	do
		local now = 70000
		check(rollOn.hidden(now + 3, now) == true, "a plant whose time is ahead is a secret")
		check(rollOn.hidden(now, now) == false and rollOn.hidden(now - 0.001, now) == false,
			"and is not one from the moment that time comes")
		check(rollOn.hidden(nil, now) == false and rollOn.hidden("soon", now) == false
				and rollOn.hidden({}, now) == false and rollOn.hidden(true, now) == false,
			"no time, or something that is not a time, hides nothing")
		check(rollOn.hidden(0 / 0, now) == false and rollOn.hidden(math.huge, now) == false,
			"nor does a time that is not a number, or is never")
		check(rollOn.hidden(now + ROLL.MaxHideSeconds + 1, now) == false
				and rollOn.hidden(now + ROLL.MaxHideSeconds, now) == true,
			"nor one further off than any roll runs: a wrong clock cannot hide a plant for ever")
		check(ROLL.MaxHideSeconds >= ROLL.Seconds and ROLL.MaxHideSeconds <= 15,
			"and that limit is past the roll and not far past it", ROLL.MaxHideSeconds)
	end

	--==========================================================================
	-- 6. WHAT A TOOL SAYS
	--==========================================================================
	say("\n-- the Tool says so itself --")
	do
		-- The copy loaded above, which is the one every other section reads: a
		-- mask is the same question whether the roll is switched on or off.
		local HatchRoll = rollOn
		local backpack = Instance.new("Backpack")
		backpack.Parent = fixture
		local hands = Instance.new("Model")
		hands.Name = "Body"
		hands.Parent = fixture
		local function plant(id, tier, hatched, revealAt, parent)
			local tool = Instance.new("Tool")
			tool.Name = if hatched then SeedData.Get(id).Name else "???"
			tool:SetAttribute("SpeciesId", id)
			tool:SetAttribute(GameConfig.Attributes.CarryingKg, tier)
			tool:SetAttribute("Hatched", hatched)
			if revealAt then
				tool:SetAttribute(ROLL.Attribute, revealAt)
			end
			tool.Parent = parent
			return tool
		end
		local now = Workspace:GetServerTimeNow()
		local rolling = plant("nubkin", 3, true, now + 8, backpack)
		local shownTool = plant("novaorb", 4, true, nil, backpack)
		local over = plant("petalpip", 2, true, now - 1, backpack)
		local pod = plant("dunebud", 5, false, nil, backpack)
		local inHand = plant("dunebud", 6, true, now + 6, hands)

		check(HatchRoll.sealed(rolling) and HatchRoll.shownHatched(rolling) == false
				and HatchRoll.shownName(rolling) == "???",
			"a plant whose roll is running is drawn as a pod, and called ???")
		check(HatchRoll.sealed(shownTool) == false and HatchRoll.shownHatched(shownTool) == true
				and HatchRoll.shownName(shownTool) == shownTool.Name,
			"a plant with no time on it is the plant it is")
		check(HatchRoll.sealed(over) == false and HatchRoll.shownHatched(over) == true,
			"and so is one whose time has passed, even if nobody took the time off")
		check(HatchRoll.sealed(pod) == false and HatchRoll.shownHatched(pod) == false
				and HatchRoll.shownName(pod) == "???",
			"a banked pod is a pod, as it always was")
		check(HatchRoll.sealed(nil) == false, "and nothing at all is not a secret")

		local holder = {
			Character = hands,
			FindFirstChildOfClass = function(_, className)
				return if className == "Backpack" then backpack else nil
			end,
		}
		local waiting = HatchRoll.sealedSpecies(holder)
		local names = {}
		for id in pairs(waiting) do
			table.insert(names, id)
		end
		table.sort(names)
		check(table.concat(names, ",") == "dunebud,nubkin",
			"what a player is waiting to be shown is read off the Tools they hold, in the bag and "
				.. "in the hands", table.concat(names, ","))
		check(near(waiting.nubkin, now + 8) and near(HatchRoll.pendingUntil(holder), now + 8),
			"with the time the last of them ends")
		rolling:SetAttribute(ROLL.Attribute, nil)
		inHand:SetAttribute(ROLL.Attribute, nil)
		check(HatchRoll.sealed(rolling) == false and HatchRoll.shownHatched(rolling) == true
				and HatchRoll.shownName(rolling) == rolling.Name,
			"the time taken off, the same Tool is its plant")
		check(HatchRoll.pendingUntil(holder) == nil and next(HatchRoll.sealedSpecies(holder)) == nil,
			"and nothing is waiting")
	end

	--==========================================================================
	-- 7. THE HATCH ITSELF, WITH THE ROLL ON
	--==========================================================================
	say("\n-- the hatch, rolled --")
	do
		local trace = {}
		local function record(name, ...)
			table.insert(trace, { name = name, args = { ... } })
		end
		local function indexOf(name)
			for i, t in ipairs(trace) do
				if t.name == name then
					return i
				end
			end
			return nil
		end
		local function count(name)
			local n = 0
			for _, t in ipairs(trace) do
				if t.name == name then
					n += 1
				end
			end
			return n
		end
		local function last(name)
			for i = #trace, 1, -1 do
				if trace[i].name == name then
					return trace[i]
				end
			end
			return nil
		end

		local fakePlayers = {
			PlayerRemoving = {
				Connect = function()
					return { Disconnect = function() end }
				end,
			},
		}
		local owner = { Name = "RollOwner", UserId = 8282, Parent = fakePlayers }

		local assignedFn = nil
		local PlotService = {
			OwnerOf = function(plot)
				return if plot ~= nil and plot == plotModel then owner else nil
			end,
			PlotOf = function(playerArg)
				return if playerArg == owner then plotModel else nil
			end,
			OnAssigned = function(fn)
				assignedFn = fn
			end,
			OnReleased = function() end,
			OnResizing = function() end,
			OnResized = function() end,
		}
		local seen = {}
		local profile = { Plants = {} }
		local PlayerDataService = {
			IsReady = function()
				return true
			end,
			Get = function(playerArg)
				return if playerArg == owner then profile else nil
			end,
			SetPlants = function(playerArg, list)
				record("SetPlants", playerArg, list)
			end,
			MarkSeen = function(playerArg, id)
				record("MarkSeen", playerArg, id)
				if seen[id] then
					return false
				end
				seen[id] = true
				return true
			end,
			RecordTutorial = function(playerArg, step)
				record("RecordTutorial", playerArg, step)
			end,
		}
		local giveWorks = true
		local CarryService = {
			GiveHatched = function(playerArg, species, tier, equipAfter, revealAt, onRecord)
				record("GiveHatched", playerArg, species, tier, equipAfter, revealAt, onRecord)
				return giveWorks
			end,
			SyncHeldNow = function() end,
			-- The saved record has room: the Instant Hatch key counts it before a dialog.
			HeldRoom = function()
				return 10, 0, true
			end,
			IsCarrying = function()
				return false
			end,
		}
		local fakeMarket = {}
		function fakeMarket:PromptProductPurchase() end
		local fakeGame = gameWith({ MarketplaceService = fakeMarket, Players = fakePlayers })

		plotModel = Instance.new("Model")
		plotModel.Name = "HatchRollSpecPlot"
		plotModel.Archivable = false
		plotModel:SetAttribute("PreviewOnly", true)
		plotModel:SetAttribute(GameConfig.Attributes.PlotId, 95)
		plotModel.Parent = Workspace
		local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
		local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
		plotModel:SetAttribute("PlotCF",
			CFrame.lookAt(Vector3.new(0, 930, centreR), Vector3.new(0, 930, 0)))
		plotModel:SetAttribute("Depth", startDepth)
		MapService.ResizePlot(plotModel, 1)

		-- No gap between purchase dialogs, so each press can come straight before
		-- its receipt and four hatches can still land within the same second.
		local gapless = setmetatable({
			Plant = setmetatable({
				InstantHatch = setmetatable({ OfferGapSeconds = 0 }, { __index = GameConfig.Plant.InstantHatch }),
			}, { __index = GameConfig.Plant }),
		}, { __index = GameConfig })
		-- Six pods, pressed and hatched in this order: each receipt follows the press
		-- on the pod with the longest wait left (a receipt hatches only the pod that
		-- was pressed, 2026-09-30).
		local pods = {
			{ id = "dunebud", tier = 7 }, { id = "nubkin", tier = 2 }, { id = "novaorb", tier = 4 },
			{ id = "petalpip", tier = 1 }, { id = "dunebud", tier = 3 }, { id = "nubkin", tier = 5 },
		}
		local stamp = os.time()
		for i, pod in ipairs(pods) do
			table.insert(profile.Plants, { SpeciesId = pod.id, Tier = pod.tier, PlantedAt = stamp,
				HatchAt = stamp + 9000 - i * 100, X = -10 + i * 3, Z = -4, Stage = 1, Facing = 0 })
		end

		local loadOk, loadErr = pcall(function()
			PlantService = loadWith(Server.PlantService, {
				PlotService = PlotService,
				PlayerDataService = PlayerDataService,
				CarryService = CarryService,
				PlantWander = PlantWander,
			}, { HatchRoll = rollOn, GameConfig = gapless }, fakeGame)
			PlantService.Init()
			PlantService.Start()
		end)
		check(loadOk and assignedFn ~= nil, "PlantService loads with the roll switched on", loadErr)
		if not (loadOk and assignedFn) then
			return
		end
		local reveals = {}
		PlantService.OnRevealed(function(payload)
			table.insert(reveals, payload)
			record("Reveal", payload)
		end)
		assignedFn(owner, plotModel)

		local function hatchNext()
			-- The pod is pressed first, the one with the longest wait still counting
			-- down: a receipt hatches the pod that was pressed and no other.
			local best, bestAt = nil, -math.huge
			for _, d in ipairs(plotModel:GetDescendants()) do
				-- Planted: a hatched pod stays in the plot for its reveal, untagged.
				if d:IsA("Model") and d:GetAttribute("PlacementId") ~= nil and d:GetAttribute("Stage") == 1
					and game:GetService("CollectionService"):HasTag(d, GameConfig.Tags.Planted)
					and d:GetAttribute("Ready") ~= true then
					local at = tonumber(d:GetAttribute("HatchAt")) or 0
					local id = d:GetAttribute("PlacementId")
					if at > bestAt or (at == bestAt and best ~= nil and id < best) then
						best, bestAt = id, at
					end
				end
			end
			if best ~= nil then
				PlantService.OfferInstantHatch(owner, plotModel, best)
			end
			trace = {}
			local before = #reveals
			local done = false
			local answered = nil
			local thread = coroutine.create(function()
				answered = PlantService.InstantHatch(owner)
				done = true
			end)
			local resumed = coroutine.resume(thread)
			return answered, reveals[before + 1], done and resumed
		end

		--== THE FIRST ==--
		local ok1, first, whole1 = hatchNext()
		check(ok1 == true and first ~= nil, "the first pod hatches")
		check(whole1 == true,
			"and the hatch ran from its guards to its announcement without once yielding")
		check(first ~= nil and first.species == pods[1].id and first.tier == pods[1].tier,
			"the plant announced is the pod's own species and tier: nothing was rolled for",
			first and (tostring(first.species) .. " T" .. tostring(first.tier)))
		check(first ~= nil and near(first.revealAt, first.at + ROLL.Seconds),
			"its plant may be shown three seconds after it hatched",
			first and first.revealAt - first.at)
		check(first ~= nil and first.rollAt == nil and first.compact == nil,
			"and the message says nothing of a card: no turn to wait for, no line instead of one")
		local give = last("GiveHatched")
		check(give ~= nil and give.args[2] == SeedData.Get(pods[1].id) and give.args[3] == pods[1].tier,
			"the Tool asked for is that same plant")
		check(give ~= nil and first ~= nil and give.args[5] == first.revealAt,
			"and is told to stay a secret until the very time the clients are given",
			give and tostring(give.args[5]))
		check(give ~= nil and first ~= nil
				and near(give.args[4], (first.revealAt - first.at) + HATCH.Reveal.Seconds),
			"the hand is given the plant when it has come up, and not a moment after that",
			give and give.args[4])
		check(give ~= nil and give.args[6] == true,
			"and the same call puts the plant on the record, as it does with the roll off")
		local gave, saved = indexOf("GiveHatched"), indexOf("SetPlants")
		local marked, revealed = indexOf("MarkSeen"), indexOf("Reveal")
		check(gave and saved and marked and revealed
				and gave < saved and saved < marked and marked < revealed,
			"Tool and record, garden, Almanac, and only then the announcement: the roll changes no order")
		local frames = first and rollOn.frames(first.species, first.token)
		check(frames ~= nil and frames[#frames].speciesId == pods[1].id,
			"and the silhouettes drawn from its token end on that plant")

		--== AND THE REST, STRAIGHT AFTER ==--
		local own, tokens = 0, { [first.token] = true }
		local latest = first.revealAt
		for i = 2, 4 do
			local okN, payload, wholeN = hatchNext()
			local giveN = last("GiveHatched")
			if okN == true and wholeN == true and payload ~= nil and payload.species == pods[i].id
				and payload.tier == pods[i].tier and near(payload.revealAt, payload.at + ROLL.Seconds)
				and giveN ~= nil and giveN.args[5] == payload.revealAt and not tokens[payload.token] then
				own += 1
				tokens[payload.token] = true
				latest = math.max(latest, payload.revealAt)
			end
		end
		check(own == 3,
			"three more pods hatched straight after are each their own plant, their own token and their "
				.. "own three seconds", own)
		check(latest - first.at <= ROLL.Seconds + 1,
			"none waited for another: four hatched together are all shown within a second of each other",
			latest - first.at)

		--== A HATCH THAT FAILS TAKES NOTHING ==--
		giveWorks = false
		local ok5, none = hatchNext()
		check(ok5 == false and none == nil and count("SetPlants") == 0 and count("Reveal") == 0,
			"a hatch whose Tool cannot be made does not happen: no save, no announcement")
		giveWorks = true
		local ok6, fifth = hatchNext()
		check(ok6 == true and fifth ~= nil and fifth.species == pods[5].id
				and near(fifth.revealAt, fifth.at + ROLL.Seconds),
			"and the same pod hatches when it can be, with its own three seconds")
	end

	--==========================================================================
	-- 8. EVERYTHING THAT WOULD NAME THE PLANT EARLY
	--==========================================================================
	say("\n-- nothing says it first --")
	do
		local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

		--== THE HOTBAR AND THE BAG ==--
		-- Since 2026-10-03 the Bag's and the strip's faces are InventoryModel's,
		-- so they are checked by what they SAY of a Tool whose roll still runs.
		local InventoryModel = require(game:GetService("ReplicatedStorage").SeedGame.Shared.InventoryModel)
		local rollAttribute = require(game:GetService("ReplicatedStorage").SeedGame.Shared.HatchRoll).Attribute
		local now = workspace:GetServerTimeNow()
		local function stand(revealAt)
			return { GetAttribute = function(_, name)
				local attrs = { SpeciesId = "nubkin", CarryingKg = 3, Hatched = true, ItemId = "7",
					[rollAttribute] = revealAt }
				return attrs[name]
			end }
		end
		local held = { { Id = "nubkin", Tier = 3, Hatched = true, Item = "7" } }
		local sealed = InventoryModel.collect({ held = held, tools = { stand(now + 2) }, sealedUntil = {}, now = now })[1]
		local face = InventoryModel.face(sealed)
		local species = SeedData.Get("nubkin")
		local said = string.lower(face.name .. " " .. face.search .. " " .. face.visual .. " " .. face.variant)
		check(sealed.kind == "pod" and sealed.sealed and face.category == "pods" and face.art.kind == "pod"
				and not string.find(said, string.lower(species.Name), 1, true)
				and not string.find(face.visual, "nubkin", 1, true),
			"a plant mid-roll is a pod in the Bag and on the strip: its name, picture, search words and key say nothing of it")
		local key = InventoryModel.groupKey(sealed, face)
		check(string.find(key, "|sealed", 1, true) ~= nil and not string.find(key, "nubkin", 1, true),
			"and it is grouped by its shell, never by its species", key)
		local shown = InventoryModel.collect({ held = held, tools = { stand(now - 1) }, sealedUntil = {}, now = now })[1]
		check(shown.kind == "plant" and InventoryModel.face(shown).name == species.Name,
			"once its time comes off it is the plant")
		local loadout = sourceOf(scripts and scripts:FindFirstChild("LoadoutUI"))
		check(loadout ~= nil, "LoadoutUI is there to be read")
		if loadout then
			check(times(loadout, 'GetAttribute("Hatched")') == 0,
				"the hotbar never reads Hatched straight off a Tool: InventoryModel decides what is shown")
			local holdAt = loadout:find("local function holdTool(", 1, true)
			local guardAt = holdAt and loadout:find("if HatchRoll.sealed(tool) then", holdAt, true)
			local equipAt = holdAt and loadout:find("humanoid:EquipTool(tool)", holdAt, true)
			check(holdAt ~= nil and guardAt ~= nil and equipAt ~= nil and guardAt < equipAt
					and times(loadout, "EquipTool(tool)") == 1,
				"it cannot be taken in the hands until its time, which is the only place a client equips anything")
			check(loadout:find("or name == HatchRoll.Attribute then", 1, true) ~= nil
					and loadout:find("name = if item and item.tool then HatchRoll.shownName(item.tool)", 1, true) ~= nil,
				"and the slot repaints as the plant the moment the Tool's time comes off; its hidden name is ??? till then")
		end

		--== THE WORLD ==--
		local fx = sourceOf(scripts and scripts:FindFirstChild("HatchFX"))
		check(fx ~= nil, "HatchFX is there to be read")
		if fx then
			check(fx:find("then revealAt - Workspace:GetServerTimeNow()", 1, true) ~= nil
					and fx:find("local startAt = if rolled > 0", 1, true) ~= nil,
				"the creature, and the label that is drawn with it, come up at the reveal and not before")
			check(times(fx, "SoundKit.emit(REVEAL_FOR[species.Rarity]") == 1
					and times(fx, "fanfare()") == 3
					and fx:find("if rolled == 0 then", 1, true) ~= nil,
				"the fanfare names the rarity, so at the burst it plays only when there is no roll",
				times(fx, "fanfare()"))
			local from = fx:find("-- THE ROLL, WHERE THE POD STOOD", 1, true)
			local to = from and fx:find("-- AND THE CREATURE", from, true)
			local roll = if from and to then fx:sub(from, to) else ""
			check(#roll > 0 and roll:find("SoundKit", 1, true) == nil
					and roll:find("ParticleEmitter", 1, true) == nil and roll:find("PointLight", 1, true) == nil
					and roll:find("BillboardGui", 1, true) == nil,
				"the roll itself makes no sound, no particle, no light and no billboard")
			check(roll:find('Instance.new("SurfaceGui")', 1, true) ~= nil
					and roll:find('word.Text = "?"', 1, true) ~= nil,
				"its question mark is a sign standing in the world")
			check(roll:find("if shaped < WORLD.MaxShapes then", 1, true) ~= nil,
				"and only so many rolls turn shapes at once on one screen")
			check(fx:find("ScreenGui", 1, true) == nil and fx:find("PlayerGui", 1, true) == nil,
				"nothing of a hatch is drawn on the screen itself: no card, no panel")
			check(fx:find("CameraType", 1, true) == nil and fx:find("ContextActionService", 1, true) == nil
					and fx:find("WalkSpeed", 1, true) == nil and fx:find("ModalEnabled", 1, true) == nil
					and fx:find("FireServer", 1, true) == nil,
				"it takes no camera, no key and nobody's feet, and sends nothing")
		end

		--== THE INDEX AND THE GUIDE ==--
		local index = sourceOf(scripts and scripts:FindFirstChild("IndexUI"))
		check(index ~= nil and index:find("HatchRoll.sealedSpecies(player)", 1, true) ~= nil,
			"the Index keeps a first discovery's silhouette until its plant has been shown")
		local guide = sourceOf(scripts and scripts:FindFirstChild("TutorialUI"))
		check(guide ~= nil and guide:find("HatchRoll.pendingUntil(player)", 1, true) ~= nil
				and guide:find("Roll.ShowSeconds", 1, true) == nil,
			"and the guide's congratulations for a first hatch come after the plant, not before it")

		--== THE SERVER ==--
		local plant = sourceOf(Server:FindFirstChild("PlantService"))
		check(plant ~= nil, "PlantService is there to be read")
		if plant then
			-- By its name and arguments: what it answers has changed since (a reason
			-- rides back beside a refusal), and may again.
			local from = plant:find("function hatch(player: Player, entry: Planted, early: boolean?)",
				1, true)
			local to = from and plant:find("announceReveal({", from, true)
			local slice = if from and to then plant:sub(from, to) else ""
			-- Comments may say "no wait"; the code may not wait.
			local code = {}
			for _, row in ipairs(string.split(slice, "\n")) do
				local bare = row:gsub("^%s+", "")
				if bare:sub(1, 2) ~= "--" then
					table.insert(code, row)
				end
			end
			local lines = table.concat(code, "\n")
			check(#slice > 0 and lines:find("task.wait", 1, true) == nil
					and lines:find("task.delay", 1, true) == nil and lines:find(":Wait(", 1, true) == nil
					and lines:find("WaitForChild", 1, true) == nil and lines:find("Async", 1, true) == nil
					and lines:find("InvokeClient", 1, true) == nil,
				"from the guards to the announcement the hatch has nothing in it that can yield")
			check(lines:find("HatchRoll.revealAt(now)", 1, true) ~= nil
					and lines:find("entry.species, entry.tier", 1, true) ~= nil
					and lines:find("SeedData.Roll", 1, true) == nil and lines:find("Random", 1, true) == nil,
				"the roll is given a time and nothing else: the plant is the pod's entry, as it was")
			check(plant:find("rollBusy", 1, true) == nil,
				"and no hatch is kept waiting behind another")
		end
		local carry = sourceOf(Server:FindFirstChild("CarryService"))
		check(carry ~= nil, "CarryService is there to be read")
		if carry then
			local from = carry:find("local function giveTool(", 1, true)
			local stampAt = from and carry:find("tool:SetAttribute(REVEAL_AT, revealAt)", from, true)
			local parentAt = from and carry:find("\ttool.Parent = backpack", from, true)
			check(stampAt ~= nil and parentAt ~= nil and stampAt < parentAt,
				"the Tool is marked BEFORE it is parented: no client ever has it without its time")
			local rowFrom = carry:find("local function rowOf(", 1, true)
			local rowTo = rowFrom and carry:find("local function heldSnapshot(", rowFrom, true)
			local row = if rowFrom and rowTo then carry:sub(rowFrom, rowTo) else ""
			check(#row > 0 and row:find("REVEAL_AT", 1, true) == nil and row:find("RevealAt", 1, true) == nil,
				"and the time is never part of what is saved")
		end
	end
end

--==============================================================================
-- 9. WHERE THE POD STOOD, RUN
--
-- HatchFX's own source, loaded the way the game loads it but with four things
-- standing in: the player it is drawn for, the frame clock (so the spec decides
-- when a frame happens), the sound kit (so a fanfare is a line in a list) and
-- the builder (so every model built is counted). Its rolls are real instances
-- in the real Workspace, high over wherever the Studio camera is, and they run
-- on the real clock: a roll here takes the three seconds it takes in the game.
--==============================================================================
local copies = {}

local function world()
	say("\n-- where the pod stood --")
	local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local script = scripts and scripts:FindFirstChild("HatchFX")
	local read = sourceOf(script)
	check(read ~= nil, "HatchFX is there to be run")
	if not read then
		return
	end
	local source = string.gsub(read, string.char(13, 10), string.char(10))
		.. "\nreturn { playReveal = playReveal, live = live, parked = parked, stage = stage,"
		.. " shaped = function() return shaped end }\n"

	local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
	local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
	local DARK = GameConfig.Almanac.Silhouette
	-- WHERE THE STUDIO CAMERA IS, READ EVERY TIME IT IS NEEDED. Somebody may be
	-- using this Studio while the spec runs, and a camera moved between two
	-- hatches would put the second out of sight of the first one's numbers:
	-- every hatch here stands where the camera is when it happens.
	local function eyeNow()
		local camera = Workspace.CurrentCamera
		return if camera then camera.CFrame.Position else Vector3.new(0, 50, 0)
	end
	local UP = Vector3.new(0, 150, 0)

	local function copy(quality)
		local render = Instance.new("BindableEvent")
		local idle = Instance.new("BindableEvent")
		local removing = Instance.new("BindableEvent")
		local attrs = { SeedAfterimageQuality = quality }
		local me = {
			Name = "SpecWatcher",
			UserId = -501,
			CharacterRemoving = removing.Event,
			GetAttribute = function(_, key)
				return attrs[key]
			end,
		}
		local never = {
			Connect = function()
				return { Disconnect = function() end }
			end,
		}
		local stand = gameWith({
			Players = { LocalPlayer = me },
			RunService = {
				RenderStepped = render.Event,
				Heartbeat = idle.Event,
				IsStudio = function()
					return true
				end,
			},
			CollectionService = {
				GetTagged = function()
					return {}
				end,
				GetInstanceAddedSignal = function()
					return never
				end,
				GetInstanceRemovedSignal = function()
					return never
				end,
				GetTags = function(_, instance)
					return CollectionService:GetTags(instance)
				end,
				RemoveTag = function(_, instance, tag)
					CollectionService:RemoveTag(instance, tag)
				end,
			},
		})
		-- Every sound asked for, with the place it was asked for at: two hatches
		-- of one rarity share a fanfare, and are told apart by where they stand.
		local sounds = {}
		local kit = {
			has = function()
				return true
			end,
			emit = function(cue, part)
				table.insert(sounds, {
					cue = cue,
					at = Workspace:GetServerTimeNow(),
					where = if typeof(part) == "Instance" and part:IsA("BasePart") then part.Position else nil,
				})
			end,
			play = function(cue)
				table.insert(sounds, { cue = cue, at = Workspace:GetServerTimeNow() })
			end,
		}
		local builds = { shapes = 0, creatures = 0, fail = nil }
		local builder = setmetatable({
			Build = function(species, tier, stage, cf, parent)
				if parent == nil then
					builds.shapes += 1
					if builds.fail == species.Id then
						error("spec: this shape cannot be built")
					end
				else
					builds.creatures += 1
				end
				return CreatureModel.Build(species, tier, stage, cf, parent)
			end,
		}, { __index = CreatureModel })
		local chunk, err = loadstring(source, "=HatchFX")
		assert(chunk, tostring(err))
		setfenv(chunk, setmetatable({
			game = stand,
			script = script,
			require = function(target)
				if typeof(target) == "Instance" then
					if target.Name == "SoundKit" then
						return kit
					elseif target.Name == "CreatureModel" then
						return builder
					end
				end
				return outerRequire(target)
			end,
		}, { __index = getfenv(1) }))
		local made = {
			fx = chunk(),
			render = render,
			removing = removing,
			sounds = sounds,
			builds = builds,
			signals = { render, idle, removing },
		}
		table.insert(copies, made)
		-- HatchFX clears away the stage of the copy before it when it starts, as
		-- a script run again should. Here several copies run side by side, so
		-- each one's stage is given a name the next will not take for its own.
		made.fx.stage.Name = "SeedHatchFX_Spec" .. #copies
		return made
	end

	local nextToken = 100
	local function hatchAt(c, id, tier, offset, options)
		options = options or {}
		local where = eyeNow() + offset
		nextToken += 1
		local species = SeedData.Get(id)
		local now = Workspace:GetServerTimeNow()
		local at = now - (options.behind or 0)
		local job = {
			token = nextToken,
			id = id,
			tier = tier,
			where = where,
			at = at,
			revealAt = if options.off then at else at + ROLL.Seconds,
			-- What the message says instead, when it is to say something else:
			-- any value at all.
			says = if options.claim ~= nil then options.claim(at) else nil,
			paid = options.paid == true,
			cue = GameConfig.Sfx.RevealFor[species.Rarity] or "RevealCommon",
			frames = HatchRoll.frames(id, nextToken),
			-- What was seen of it.
			most = 0,
			wrong = {},
			early = false,
			held = false,
			signs = 0,
			faced = 0,
			highest = -math.huge,
			lowest = math.huge,
			sizes = {},
			stood = {},
			rings = 0,
		}
		job.opens = job.at + HatchRoll.lead(job.paid)
		c.fx.playReveal({
			token = job.token,
			species = id,
			tier = tier,
			rarity = species.Rarity,
			income = SeedData.IncomePerSecond(species, tier),
			cf = CFrame.new(where),
			-- Somebody else's: the owner's own hatch nudges the owner's camera.
			owner = {},
			paid = job.paid,
			discovery = false,
			at = job.at,
			revealAt = if options.claim ~= nil then job.says else job.revealAt,
		})
		return job
	end

	local function note(job, what)
		if #job.wrong < 4 then
			table.insert(job.wrong, what)
		end
	end

	-- One look at one hatch, now.
	local function watch(c, job)
		local now = Workspace:GetServerTimeNow()
		local folder = c.fx.stage:FindFirstChild("Reveal_" .. job.token)
		if not folder then
			job.gone = job.gone or now
			return
		end
		local holder = folder:FindFirstChild("HatchRoll")
		local rings = 0
		local creature = nil
		for _, child in ipairs(folder:GetChildren()) do
			if child.Name == "HatchRing" then
				rings += 1
			elseif child:IsA("Model") then
				creature = child
			end
		end
		job.rings = math.max(job.rings, rings)
		if creature then
			job.creatureAt = job.creatureAt or now
			if creature:GetAttribute("SpeciesId") ~= job.id then
				note(job, "the creature is a " .. tostring(creature:GetAttribute("SpeciesId")))
			end
			if now < job.revealAt - 0.03 then
				job.early = true
			end
			if holder then
				note(job, "the question mark is still there beside the plant")
			end
		end
		if not holder then
			return
		end
		job.held = true
		job.heldLast = now
		local sign = holder:FindFirstChild("Question")
		local face = sign and sign:FindFirstChildOfClass("SurfaceGui")
		local word = face and face:FindFirstChildWhichIsA("TextLabel", true)
		if sign and face and word and word.Text == "?" then
			job.signs += 1
			job.highest = math.max(job.highest, sign.Position.Y)
			job.lowest = math.min(job.lowest, sign.Position.Y)
			local eye = eyeNow()
			local flat = Vector3.new(eye.X - sign.Position.X, 0, eye.Z - sign.Position.Z)
			if flat.Magnitude < 1 or sign.CFrame.LookVector:Dot(flat.Unit) > 0.98 then
				job.faced += 1
			end
		else
			note(job, "no question mark on the sign")
		end
		if not holder:FindFirstChild("Disc") then
			note(job, "no disc on the soil")
		end
		local standing = {}
		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("Model") then
				table.insert(standing, child)
			end
		end
		job.most = math.max(job.most, #standing)
		local shape = standing[1]
		if not shape then
			return
		end
		local id = shape:GetAttribute("SpeciesId")
		job.stood[id] = true
		-- The frame the clock says, or the one before it: a look can land between
		-- the clock moving and the next frame being drawn.
		local fraction = math.clamp((now - job.opens) / math.max(job.revealAt - job.opens, 0.1), 0, 1)
		local index = HatchRoll.frameAt(job.frames, fraction)
		local wanted = job.frames[index].speciesId
		local accepted = { [wanted] = true }
		-- A shape that cannot be built is passed over: what stood before it stays.
		local back = index - 1
		while back >= 1 do
			local earlier = job.frames[back].speciesId
			accepted[earlier] = true
			if earlier ~= job.skip then
				break
			end
			back -= 1
		end
		if not accepted[id] then
			note(job, string.format("a %s stood where the roll has a %s", tostring(id), wanted))
		end
		job.lastStood = id
		for _, d in ipairs(shape:GetDescendants()) do
			if d:IsA("BasePart") then
				if math.abs(d.Color.R - DARK.R) + math.abs(d.Color.G - DARK.G) + math.abs(d.Color.B - DARK.B) > 0.02 then
					note(job, d.Name .. " is not dark")
				end
				if d.CanCollide or d.CanQuery or d.CanTouch or not d.Anchored or d.CastShadow then
					note(job, d.Name .. " can be touched, moved or casts a shadow")
				end
			elseif d:IsA("Light") or d:IsA("ParticleEmitter") then
				note(job, "a shape has a " .. d.ClassName)
			end
		end
		local size = shape:GetExtentsSize()
		table.insert(job.sizes, math.max(size.X, size.Y, size.Z))
		if (shape:GetPivot().Position - job.where).Magnitude > 0.05 then
			note(job, "a shape stands somewhere else")
		end
	end

	local function run(c, seconds, jobs, each)
		local untilAt = os.clock() + seconds
		while os.clock() < untilAt do
			c.render:Fire()
			task.wait()
			for _, job in ipairs(jobs) do
				watch(c, job)
			end
			if each then
				each()
			end
		end
	end

	-- The fanfares of ONE hatch: its rarity's cue, asked for where its pod stood.
	local function fanfares(c, job)
		local list = {}
		for _, sound in ipairs(c.sounds) do
			if sound.cue == job.cue and sound.where then
				local across = Vector3.new(sound.where.X - job.where.X, 0, sound.where.Z - job.where.Z)
				if across.Magnitude < 1 then
					table.insert(list, sound.at)
				end
			end
		end
		return list
	end

	-- Every sound asked for at one hatch's place before its reveal, but the
	-- shell's own: a roll has no sound, and nothing names the plant early.
	local function early(c, job)
		local list = {}
		for _, sound in ipairs(c.sounds) do
			if sound.where and sound.at < job.revealAt - 0.03 and sound.at > job.at + BURST + 0.3 then
				local across = Vector3.new(sound.where.X - job.where.X, 0, sound.where.Z - job.where.Z)
				if across.Magnitude < 1 then
					table.insert(list, sound.cue)
				end
			end
		end
		return list
	end

	local function sizeFor(tier)
		return math.clamp(SeedData.PodDiameter(tier) * WORLD.SizeInPods, WORLD.MinStuds, WORLD.MaxStuds)
	end

	--==========================================================================
	-- A FREE HATCH, A PURCHASE, A HATCH WITH THE ROLL OFF, A LATE SCREEN, AND
	-- ONE TOO FAR AWAY TO DRAW -- all at once, each where its own pod stood.
	--==========================================================================
	--==========================================================================
	-- A SCREEN WHOSE FRAMES STOP COMING
	--
	-- Started first and looked at last. This copy is never given a frame, so
	-- nothing that waits for one can tidy up after it: what is left is the
	-- backstop's, which waits for the clock and for nothing else.
	--==========================================================================
	local frozen = copy(nil)
	local stuck = hatchAt(frozen, "nubkin", 2, UP + Vector3.new(0, 20, -40))
	local stuckUntil = stuck.revealAt + BURST + HATCH.Reveal.Seconds + HATCH.Label.Seconds
		+ HATCH.Label.FadeSeconds + 1
	task.wait(0.6)
	local stuckFolder = frozen.fx.stage:FindFirstChild("Reveal_" .. stuck.token)
	check(stuckFolder ~= nil and stuckFolder:FindFirstChild("HatchRoll") ~= nil,
		"a screen whose frames stop coming has its question mark standing all the same")

	local a = copy(nil)
	check(a.fx.stage.Parent == Workspace and #a.fx.stage:GetChildren() == 0,
		"the world's side loads, and has drawn nothing")
	local free = hatchAt(a, "nubkin", 3, UP + Vector3.new(-45, 0, 0))
	local paid = hatchAt(a, "dunebud", 5, UP + Vector3.new(-15, 0, 0), { paid = true })
	local plain = hatchAt(a, "novaorb", 2, UP + Vector3.new(15, 0, 0), { off = true })
	local late = hatchAt(a, "bellchime", 1, UP + Vector3.new(45, 0, 0), { behind = 1.4 })
	local far = hatchAt(a, "snapmoss", 4, Vector3.new(0, HATCH.HearingStuds + 200, 0))
	local everyone = { free, paid, plain, late, far }
	run(a, ROLL.Seconds + HATCH.Reveal.Seconds + HATCH.Label.Seconds + HATCH.Label.FadeSeconds + 1.2, everyone)

	for _, row in ipairs({ { free, "a free hatch" }, { paid, "a purchase" }, { late, "a screen that heard of it late" } }) do
		local job, who = row[1], row[2]
		check(job.held and job.signs > 10 and #job.wrong == 0,
			string.format("%s: a disc, a question mark and dark shapes stand where the pod stood", who),
			table.concat(job.wrong, "; "))
		check(job.most == 1, string.format("%s: one shape at a time", who), job.most)
		local kinds = 0
		for _ in pairs(job.stood) do
			kinds += 1
		end
		-- A screen that came to it late has the last few turns only, and two
		-- plants can share those between them; a whole roll shows every plant of
		-- the biome.
		local least = if job == late then 2 else 3
		check(job.lastStood == job.id and kinds >= least,
			string.format("%s: the shapes turn, and the last to stand is the plant's own", who),
			string.format("%d shapes, last %s", kinds, tostring(job.lastStood)))
		local wanted = sizeFor(job.tier)
		local sized = #job.sizes > 0
		for _, size in ipairs(job.sizes) do
			if math.abs(size - wanted) > wanted * 0.03 then
				sized = false
			end
		end
		check(sized, string.format("%s: every shape is the size of the shell (%.1f studs), whatever plant it is",
			who, wanted))
		-- All but two looks: a camera somebody moves between a frame and the look
		-- at it is a look at a sign turned to where the camera was.
		check(job.faced >= job.signs - 2, string.format("%s: the question mark is turned to whoever is looking", who),
			string.format("%d of %d", job.faced, job.signs))
		check(not job.early and job.creatureAt ~= nil and job.creatureAt >= job.revealAt - 0.03
				and job.creatureAt <= job.revealAt + 0.25,
			string.format("%s: the plant comes up at the reveal -- not before, and not late", who),
			job.creatureAt and string.format("%+.3fs", job.creatureAt - job.revealAt))
		check(job.heldLast ~= nil and job.heldLast >= job.revealAt - 0.25
				and job.heldLast <= job.revealAt + 0.1,
			string.format("%s: the question mark stays until the plant comes, and goes with the last shape", who),
			job.heldLast and string.format("%+.3fs", job.heldLast - job.revealAt))
		local sounded = fanfares(a, job)
		check(#sounded == 1 and sounded[1] >= job.revealAt - 0.03 and sounded[1] <= job.revealAt + 0.25,
			string.format("%s: the fanfare, which names the rarity, sounds once and with the plant", who),
			string.format("%d, first %+.3fs", #sounded, (sounded[1] or 0) - job.revealAt))
		local during = early(a, job)
		check(#during == 0, string.format("%s: and the roll itself makes no sound", who),
			table.concat(during, ","))
		check(job.gone ~= nil, string.format("%s: and when it is over nothing of it is left", who))
	end
	check(free.rings >= 1 and paid.rings >= 1, "the shell's own burst is drawn as it always was")
	check(late.rings == 0,
		"a screen that heard of the hatch a second late draws no burst: it starts at the shapes")
	check(free.highest - free.lowest > WORLD.BobStuds,
		"the question mark rides up and down", string.format("%.3f studs", free.highest - free.lowest))

	check(plain.held == false and plain.creatureAt ~= nil and plain.creatureAt <= plain.at + 0.6
			and #plain.wrong == 0,
		"with the roll off there is no question mark and no shape: the plant comes up out of the burst, as it did",
		plain.creatureAt and string.format("%+.3fs", plain.creatureAt - plain.at))
	local plainSounds = fanfares(a, plain)
	check(#plainSounds == 1 and plainSounds[1] <= plain.at + 0.3,
		"and its fanfare is at the burst, as it was", #plainSounds)
	check(far.held == false and far.creatureAt == nil and far.gone ~= nil,
		"a hatch too far away to see draws nothing at all")

	check(#a.fx.stage:GetChildren() == 0 and a.fx.shaped() == 0 and next(a.fx.live) == nil,
		"when they are all over the world has nothing of them, and nothing is still counted as rolling",
		#a.fx.stage:GetChildren())
	local kept, loose = 0, 0
	for _, shape in pairs(a.fx.parked) do
		kept += 1
		if shape.Parent ~= nil then
			loose += 1
		end
	end
	check(kept >= 5 and kept <= 10 and loose == 0,
		"one shape is kept for each species shown, outside the world", string.format("%d kept, %d loose", kept, loose))
	check(a.builds.creatures == 4 and a.builds.shapes <= 15,
		"four plants were built, and no more shapes than three rolls can show", a.builds.shapes)

	-- The same biome again: nothing is built but the plant.
	local builtBefore = a.builds.shapes
	local again = hatchAt(a, "petalpip", 6, UP + Vector3.new(-45, 0, 30))
	run(a, ROLL.Seconds + 0.4, { again })
	check(again.held and #again.wrong == 0 and again.lastStood == "petalpip" and again.most == 1,
		"a second roll of the same biome turns the same shapes", table.concat(again.wrong, "; "))
	check(a.builds.shapes == builtBefore,
		"and builds none of them: a phone pays for a shape once", a.builds.shapes - builtBefore)
	local wantedAgain = sizeFor(6)
	local resized = #again.sizes > 0
	for _, size in ipairs(again.sizes) do
		if math.abs(size - wantedAgain) > wantedAgain * 0.03 then
			resized = false
		end
	end
	check(resized, string.format("at the size of THIS shell (%.1f studs), not the last one's", wantedAgain))

	--==========================================================================
	-- FIVE AT ONCE, AND A RESPAWN IN THE MIDDLE OF THEM
	--==========================================================================
	local b = copy(nil)
	local crowd = {}
	for i, id in ipairs({ "nubkin", "dunebud", "bogbonnet", "cinderpaw", "novaorb" }) do
		table.insert(crowd, hatchAt(b, id, 2, UP + Vector3.new(-60 + i * 20, 40, 0)))
	end
	run(b, 1.4, crowd)
	local turning, marked = 0, 0
	for _, job in ipairs(crowd) do
		if job.most >= 1 then
			turning += 1
		end
		if job.held and job.signs > 0 then
			marked += 1
		end
	end
	check(marked == 5, "five pods hatched together are five question marks, each where its own pod stood",
		marked)
	check(turning == WORLD.MaxShapes and b.fx.shaped() == WORLD.MaxShapes and WORLD.MaxShapes <= 4,
		string.format("and %d of them turn shapes: the rest are a question mark alone", WORLD.MaxShapes), turning)
	b.removing:Fire()
	-- Long enough for the respawn to be heard, and no frame drawn: whatever
	-- ends a roll ends it there and then, not when the next frame notices.
	task.wait()
	check(#b.fx.stage:GetChildren() == 0 and b.fx.shaped() == 0 and next(b.fx.live) == nil,
		"a respawn in the middle of them takes every one away at once, before another frame is drawn",
		string.format("%d in the world, %d counted", #b.fx.stage:GetChildren(), b.fx.shaped()))
	run(b, 0.2, {})
	check(#b.fx.stage:GetChildren() == 0 and b.fx.shaped() == 0 and next(b.fx.live) == nil,
		"and no question mark is left standing in the frames that follow",
		#b.fx.stage:GetChildren())
	local builtB = b.builds.shapes
	local after = hatchAt(b, "petalpip", 2, UP + Vector3.new(-40, 40, 0))
	run(b, ROLL.Seconds + 0.4, { after })
	check(after.held and after.most == 1 and after.lastStood == "petalpip" and #after.wrong == 0
			and after.creatureAt ~= nil,
		"and the next hatch rolls and shows its plant as if nothing had happened",
		table.concat(after.wrong, "; "))
	check(b.builds.shapes - builtB <= 2,
		"with the shapes the respawn put away: they were kept, not thrown out",
		b.builds.shapes - builtB)

	--==========================================================================
	-- REDUCED EFFECTS, AND A SHAPE THAT CANNOT BE BUILT
	--==========================================================================
	local c = copy("Off")
	c.builds.fail = "spiretip"
	local still = hatchAt(c, "toadcap", 4, UP + Vector3.new(0, 80, 0))
	still.skip = "spiretip"
	run(c, ROLL.Seconds + 0.5, { still })
	check(still.held and still.signs > 10 and still.highest - still.lowest < 0.01,
		"under Reduced Effects the question mark stands still",
		string.format("%.3f studs", still.highest - still.lowest))
	check(still.most == 1 and still.lastStood == "toadcap" and not still.stood.spiretip,
		"the shapes still turn -- and one that could not be built is passed over, not an error")
	check(still.heldLast ~= nil and still.heldLast >= still.revealAt - 0.25
			and still.heldLast <= still.revealAt + 0.1,
		"the roll goes on past the shape it could not build, to its own end",
		still.heldLast and string.format("%+.3fs", still.heldLast - still.revealAt))
	check(#still.wrong == 0 and still.creatureAt ~= nil and still.creatureAt >= still.revealAt - 0.03,
		"and the plant comes up at its time all the same", table.concat(still.wrong, "; "))

	--==========================================================================
	-- THE TIME IN THE MESSAGE IS A CLAIM
	--
	-- A minute away, not a number at all, already past: there is no roll for
	-- any of them, and the plant comes up out of the burst with its fanfare, as
	-- a hatch with no roll does. Nothing a message says can stand a question
	-- mark in the world for longer than a roll runs.
	--==========================================================================
	local d = copy(nil)
	local claims = {
		{ "a minute away", "nubkin", function(at)
			return at + 60
		end },
		{ "not a number", "dunebud", function()
			return 0 / 0
		end },
		{ "already past", "novaorb", function(at)
			return at - 5
		end },
		{ "a word", "snapmoss", function()
			return "soon"
		end },
	}
	local claimed = {}
	for i, row in ipairs(claims) do
		local job = hatchAt(d, row[2], 2, UP + Vector3.new(-60 + i * 25, 20, 40), { claim = row[3] })
		job.who = row[1]
		table.insert(claimed, job)
	end
	run(d, 1.2, claimed)
	for _, job in ipairs(claimed) do
		local sounded = fanfares(d, job)
		check(job.held == false and job.creatureAt ~= nil and job.creatureAt <= job.at + 0.6,
			string.format("a message whose time is %s: no question mark, and the plant out of the burst", job.who),
			job.creatureAt and string.format("%+.3fs", job.creatureAt - job.at))
		check(#sounded == 1 and sounded[1] <= job.at + 0.3,
			string.format("a message whose time is %s: with its fanfare, once", job.who), #sounded)
	end
	run(d, HATCH.Reveal.Seconds + HATCH.Label.Seconds + HATCH.Label.FadeSeconds + 1.2, claimed)
	check(#d.fx.stage:GetChildren() == 0 and d.fx.shaped() == 0 and next(d.fx.live) == nil,
		"and nothing of them is left in the world", #d.fx.stage:GetChildren())

	-- The screen that was never given a frame, long past its backstop by now.
	local left = stuckUntil + 0.3 - Workspace:GetServerTimeNow()
	if left > 0 then
		task.wait(left)
	end
	check(#frozen.fx.stage:GetChildren() == 0 and frozen.fx.shaped() == 0 and next(frozen.fx.live) == nil,
		"and is left with nothing when its time is up: no question mark, no plant, nothing counted",
		string.format("%d in the world, %d counted", #frozen.fx.stage:GetChildren(), frozen.fx.shaped()))
end

local function tidy()
	for _, made in ipairs(copies) do
		pcall(function()
			for token, job in pairs(made.fx.live) do
				made.fx.live[token] = nil
			end
			if made.fx.stage.Parent then
				made.fx.stage:Destroy()
			end
			for id, shape in pairs(made.fx.parked) do
				made.fx.parked[id] = nil
				shape:Destroy()
			end
			for _, signal in ipairs(made.signals) do
				signal:Destroy()
			end
		end)
	end
	local stale = Workspace:FindFirstChild("SeedHatchFX")
	if stale then
		stale:Destroy()
	end
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
local worldOk, worldErr = pcall(world)
if not worldOk then
	fail += 1
	say("  FAIL  the world section threw  <- " .. tostring(worldErr))
end
tidy()

if PlantService then
	pcall(PlantService.Init)
end
if plotModel then
	plotModel:Destroy()
end
if fixture then
	fixture:Destroy()
end

say(string.format("\nHatchRollSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
