--!nocheck
--==============================================================================
-- Steal a Seed :: HatchRollSpec
--
-- THE ROLL (2026-09-29): the seconds between a pod bursting and its plant being
-- shown, in which the owner watches silhouettes turn over behind a question
-- mark. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HatchRollSpec"))
--
-- The owner's rules, which are what is asserted:
--
--   "The roll must last at least 5 seconds before the final reveal. Start
--    briskly, slow toward the end."
--   "The server must determine and secure the real outcome independently of
--    the animation -- this is a visual reveal, not a second roll."
--   "Ensure the Bag, hotbar, world model, notifications, and other UI do not
--    spoil the result before the reveal."
--   "Handle multiple pods hatching close together without overlapping reveal
--    screens or blocking controls indefinitely."
--
-- HatchRoll is loaded from its source with the switch set each way, because a
-- spec runs in Studio and the Studio preview would otherwise decide for it.
-- PlantService is the real one with the roll ON, against the stand-ins
-- HatchRevealSpec uses; that spec is the same hatch with the roll OFF.
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

local function near(a, b)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) < 1e-6
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
		check(ROLL.Enabled == false,
			"as shipped, the roll is OFF on a published server: the owner has not approved it yet",
			ROLL.Enabled)
		check(ROLL.StudioPreview == true,
			"and ON in Studio, which is where the owner asked to see it first", ROLL.StudioPreview)
		local shipped = loadWith(Shared.HatchRoll, { GameConfig = GameConfig, SeedData = SeedData },
			nil, published)
		check(shipped.live() == false,
			"so a published server with the shipped numbers has no roll")
		local plan = shipped.schedule(1000, nil)
		check(plan.rollAt == 1000 and plan.revealAt == 1000 and plan.busyUntil == 1000
				and plan.compact == false,
			"and schedules nothing: the plant may be shown at the moment of the hatch")
		local studio = loadWith(Shared.HatchRoll, { GameConfig = GameConfig, SeedData = SeedData })
		check(studio.live() == true, "while in Studio the same numbers give the preview")
		check(rollOn.live() == true and rollOff.live() == false,
			"and Enabled alone decides it once StudioPreview is out of the way")
		local approved = rollWith({ Enabled = true, StudioPreview = false }, published)
		check(approved.live() == true,
			"switched on, a published server rolls")
		check(ROLL.Attribute == "RevealAt" and rollOn.Attribute == "RevealAt"
				and rollOn.Unknown == "???",
			"a plant still being rolled for says so in RevealAt, and is called ???")
	end

	--==========================================================================
	-- 2. AT LEAST FIVE SECONDS; BRISK, THEN SLOW
	--==========================================================================
	say("\n-- the owner's five seconds --")
	do
		check(ROLL.MinSeconds >= 5, "the floor is five seconds", ROLL.MinSeconds)
		check(ROLL.Seconds >= ROLL.MinSeconds, "and the roll is set at or over it", ROLL.Seconds)
		local holds = rollOn.holds()
		local total, least, rising = 0, math.huge, true
		for i, hold in ipairs(holds) do
			total += hold
			least = math.min(least, hold)
			if i > 1 and hold < holds[i - 1] - 1e-9 then
				rising = false
			end
		end
		check(#holds == ROLL.Steps, "one hold for each silhouette", #holds)
		check(total >= 5, string.format("the silhouettes are held for %.3fs in all: five or more", total))
		check(near(total, rollOn.seconds()) and rollOn.seconds() >= ROLL.Seconds,
			"which is the length the server schedules by", rollOn.seconds())
		check(rising, "no silhouette is held for less time than the one before it")
		check(holds[1] <= 0.3, string.format("it starts briskly: the first is up for %.3fs", holds[1]))
		check(holds[#holds] >= holds[1] * 2,
			string.format("and ends slowly: the last but one turn takes %.3fs", holds[#holds]))
		check(least >= ROLL.FloorHold and ROLL.FloorHold >= 0.1,
			string.format("nothing flickers: the shortest hold is %.3fs", least))
		check(near(rollOn.cardSeconds(), rollOn.seconds() + ROLL.ShowSeconds),
			"the card is the roll and then the plant, shown", rollOn.cardSeconds())

		-- Numbers changed to make a shorter roll do not load at all.
		local function refuses(roll)
			local ok = pcall(rollWith, roll)
			return not ok
		end
		check(refuses({ Enabled = true, Seconds = 4.9, MinSeconds = 4.9 }),
			"a floor under five seconds is refused when the module loads")
		check(refuses({ Enabled = true, Seconds = 4.5 }),
			"and so is a roll shorter than its floor")
		check(refuses({ Enabled = true, Steps = 2 }), "and one of fewer than three silhouettes")
		check(refuses({ Enabled = true, FirstHold = 0.9, LastHold = 0.2 }),
			"and one that would start slow and end brisk")
		check(refuses({ Enabled = true, MaxHideSeconds = 10 }),
			"and one whose plant could be shown later than it may be hidden")
		-- A floor that stretching would break makes the roll LONGER, never shorter.
		local stretched = rollWith({ Enabled = true, FirstHold = 0.02, LastHold = 3, FloorHold = 0.3 })
		local floorTotal, floorLeast = 0, math.huge
		for _, hold in ipairs(stretched.holds()) do
			floorTotal += hold
			floorLeast = math.min(floorLeast, hold)
		end
		check(floorLeast >= 0.3 - 1e-9 and floorTotal >= ROLL.Seconds and near(floorTotal, stretched.seconds()),
			"a hold lifted to the floor makes the roll longer, never shorter",
			string.format("%.3fs, shortest %.3f", floorTotal, floorLeast))
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
					clock = true }
				local seen, shapes = {}, 0
				local at = 0
				for i, frame in ipairs(frames) do
					if not pool[frame.speciesId] then
						ok.biome = false
					end
					if i > 1 and frames[i - 1].speciesId == frame.speciesId then
						ok.neighbours = false
					end
					if not near(frame.at, at) then
						ok.clock = false
					end
					at += frame.hold
					if not seen[frame.speciesId] then
						seen[frame.speciesId] = true
						shapes += 1
					end
				end
				if not near(at, rollOn.seconds()) then
					ok.clock = false
				end
				endsRight += if ok.last then 1 else 0
				sameBiome += if ok.biome then 1 else 0
				noRepeat += if ok.neighbours then 1 else 0
				timed += if ok.clock then 1 else 0
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
		check(timed == rolls, "the silhouettes follow one another with no gap, for the roll's whole length",
			timed)

		-- The same hatch is the same roll, wherever and however often it is drawn.
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
			"one hatch is one roll: the same token and plant give the same silhouettes, whatever "
				.. "else has used a random number since", first)
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
			and rollOn.frameAt(frames, 1e9) == #frames
		local before = 1
		for i, frame in ipairs(frames) do
			if rollOn.frameAt(frames, frame.at) ~= i
				or rollOn.frameAt(frames, frame.at + frame.hold * 0.5) ~= i then
				right = false
			end
			if i > 1 and rollOn.frameAt(frames, frame.at - 1e-4) ~= i - 1 then
				right = false
			end
			before = i
		end
		check(right and before == #frames,
			"a late frame draws where the roll IS: each moment has one silhouette, in order")
		check(rollOn.frameAt(frames, rollOn.seconds() - 1e-4) == #frames
				and frames[#frames].at < rollOn.seconds(),
			"and the last thing up before the reveal is the plant's own silhouette")
	end

	--==========================================================================
	-- 4. ONE ROLL AT A TIME
	--==========================================================================
	say("\n-- one card at a time --")
	do
		local seconds = rollOn.seconds()
		local now = 50000
		local one = rollOn.schedule(now, nil)
		check(one.rollAt == now and near(one.revealAt, now + seconds) and one.compact == false,
			"a hatch with the card free rolls at once")
		check(one.revealAt - now >= 5, "and its plant is shown five seconds later or more",
			one.revealAt - now)
		check(near(one.busyUntil, one.revealAt + ROLL.ShowSeconds),
			"the card is taken until that plant has been shown")

		local two = rollOn.schedule(now + 0.05, one.busyUntil)
		check(near(two.rollAt, one.busyUntil) and near(two.revealAt, one.busyUntil + seconds)
				and two.compact == false,
			"a second hatch a moment later waits for the first: its roll starts when that card is done")
		check(two.rollAt >= one.revealAt + ROLL.ShowSeconds - 1e-9,
			"so two cards are never up together")

		local three = rollOn.schedule(now + 0.1, two.busyUntil)
		check(two.busyUntil - (now + 0.1) > ROLL.MaxWaitSeconds,
			"a third straight after would wait longer than the card may keep anybody",
			two.busyUntil - (now + 0.1))
		check(three.compact == true and three.rollAt == now + 0.1
				and near(three.revealAt, now + 0.1 + seconds),
			"so it does not wait for the card: it counts down by itself and is told in a line")
		check(three.busyUntil == two.busyUntil, "and takes none of the card's time")
		local late = rollOn.schedule(now + 2, two.busyUntil)
		check(late.compact == false and near(late.rollAt, two.busyUntil)
				and two.busyUntil - (now + 2) <= ROLL.MaxWaitSeconds,
			"one that hatches two seconds later is near enough to wait its turn: a third card, after the second",
			two.busyUntil - (now + 2))

		-- Whatever the queue, the wait is bounded and the five seconds hold.
		local busy = nil
		local worst, least, hiddenAll = 0, math.huge, true
		local clock = 90000
		for i = 1, 60 do
			clock += (i % 7) * 0.4
			local plan = rollOn.schedule(clock, busy)
			busy = plan.busyUntil
			worst = math.max(worst, plan.revealAt - clock)
			least = math.min(least, plan.revealAt - clock)
			if not rollOn.hidden(plan.revealAt, clock) then
				hiddenAll = false
			end
		end
		check(least >= 5, string.format("sixty hatches in a row: none is shown sooner than %.2fs", least))
		check(worst <= ROLL.MaxWaitSeconds + seconds + 1e-6,
			string.format("and none is kept back longer than %.2fs", worst))
		check(hiddenAll and worst < ROLL.MaxHideSeconds,
			"every one of those is a time the masks honour")

		local stale = rollOn.schedule(now, now - 300)
		check(stale.rollAt == now and stale.compact == false,
			"a card that was busy long ago is free")
		local nan = rollOn.schedule(now, 0 / 0)
		check(nan.rollAt == now and near(nan.revealAt, now + seconds),
			"and a time that is not a time is no queue at all")
		local off = rollOff.schedule(now, now + 500)
		check(off.rollAt == now and off.revealAt == now and off.busyUntil == now and off.compact == false,
			"switched off there is no roll to queue for, whatever the card was doing")
	end

	--==========================================================================
	-- 5. A SECRET CAN RUN OUT; IT CANNOT GET STUCK
	--==========================================================================
	say("\n-- the masks expire --")
	do
		local now = 70000
		check(rollOn.hidden(now + 5.5, now) == true, "a plant whose time is ahead is a secret")
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
		check(ROLL.MaxHideSeconds >= ROLL.MaxWaitSeconds + rollOn.cardSeconds(),
			"and that limit is past the longest honest wait", ROLL.MaxHideSeconds)
	end

	--==========================================================================
	-- 6. WHAT A TOOL SAYS
	--==========================================================================
	say("\n-- the Tool says so itself --")
	do
		local HatchRoll = require(Shared.HatchRoll)
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
		local rolling = plant("nubkin", 3, true, now + 30, backpack)
		local shownTool = plant("novaorb", 4, true, nil, backpack)
		local over = plant("petalpip", 2, true, now - 1, backpack)
		local pod = plant("dunebud", 5, false, nil, backpack)
		local inHand = plant("dunebud", 6, true, now + 20, hands)

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
		check(near(waiting.nubkin, now + 30) and near(HatchRoll.pendingUntil(holder), now + 30),
			"with the time the last of them ends")
		rolling:SetAttribute(ROLL.Attribute, nil)
		inHand:SetAttribute(ROLL.Attribute, nil)
		check(HatchRoll.sealed(rolling) == false and HatchRoll.shownHatched(rolling) == true
				and HatchRoll.shownName(rolling) == rolling.Name,
			"the time taken off, the same Tool is its plant")
		check(HatchRoll.pendingUntil(holder) == nil and next(HatchRoll.sealedSpecies(holder)) == nil,
			"and nothing is waiting")

		-- The fanfare: whoever asks first for a hatch plays it, and nobody after.
		check(rollOn.claim(41) == true and rollOn.claim(41) == false and rollOn.claim(41) == false,
			"a hatch is sounded once: the first to ask for its token is told yes, the rest no")
		check(rollOn.claim(42) == true and rollOn.claim(41) == false,
			"by token, so two hatches shown in the same moment cannot answer for each other")
		check(rollOn.claim(0) == true and rollOn.claim(0) == true and rollOn.claim(nil) == true
				and rollOn.claim("x") == true,
			"and a hatch with no token is sounded rather than silenced")
		check(rollOff.claim(41) == true,
			"each client keeps its own count: nothing about it is shared or sent")
		-- A long session: a thousand hatches, and the recent ones still answer.
		local long = rollWith({ Enabled = true, StudioPreview = false })
		local firstTime = true
		for token = 1, 1000 do
			if long.claim(token) ~= true then
				firstTime = false
			end
		end
		local recent = true
		for token = 1000 - 100, 1000 do
			if long.claim(token) ~= false then
				recent = false
			end
		end
		check(firstTime and recent,
			"after a thousand hatches every one was sounded once, and the last hundred still are not again")
		check(Shared.HatchRoll.Source:find("sounded[old] = nil", 1, true) ~= nil,
			"and the old ones are forgotten: a long session keeps no note for every plant it showed")
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

		local leaving = {}
		local fakePlayers = {
			PlayerRemoving = {
				Connect = function(_, fn)
					table.insert(leaving, fn)
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

		-- Six pods, hatched in this order: a receipt with no note against it takes
		-- the pod with the longest wait left.
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
			}, { HatchRoll = rollOn }, fakeGame)
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

		local seconds = rollOn.seconds()
		local function hatchNext()
			trace = {}
			local before = #reveals
			local done = false
			local answered = nil
			local thread = coroutine.create(function()
				answered = PlantService.InstantHatch(owner)
				done = true
			end)
			local resumed, err = coroutine.resume(thread)
			return answered, reveals[before + 1], done and resumed, err
		end

		--== THE FIRST: THE CARD IS FREE ==--
		local ok1, first, whole1 = hatchNext()
		check(ok1 == true and first ~= nil, "the first pod hatches")
		check(whole1 == true,
			"and the hatch ran from its guards to its announcement without once yielding")
		check(first ~= nil and first.species == pods[1].id and first.tier == pods[1].tier,
			"the plant announced is the pod's own species and tier: nothing was rolled for",
			first and (tostring(first.species) .. " T" .. tostring(first.tier)))
		check(first ~= nil and first.rollAt == first.at and near(first.revealAt, first.at + seconds)
				and first.compact == false,
			"its roll starts at the hatch and its plant may be shown a whole roll later")
		check(first ~= nil and first.revealAt - first.at >= 5,
			"which is five seconds or more", first and first.revealAt - first.at)
		local give = last("GiveHatched")
		check(give ~= nil and give.args[2] == SeedData.Get(pods[1].id) and give.args[3] == pods[1].tier,
			"the Tool asked for is that same plant")
		check(give ~= nil and first ~= nil and give.args[5] == first.revealAt,
			"and is told to stay a secret until the very time the clients are given",
			give and tostring(give.args[5]))
		check(give ~= nil and first ~= nil
				and near(give.args[4], (first.revealAt - first.at) + BURST + HATCH.Reveal.Seconds
					+ HATCH.Paid.PulseSeconds),
			"the hand waits for the roll, then the burst and the rise, as it did before",
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

		--== THE SECOND: QUEUED ==--
		local ok2, second, whole2 = hatchNext()
		check(ok2 == true and whole2 == true and second ~= nil and second.species == pods[2].id
				and second.tier == pods[2].tier,
			"a second pod hatched straight after is its own plant too")
		check(second ~= nil and first ~= nil and near(second.rollAt, first.revealAt + ROLL.ShowSeconds)
				and near(second.revealAt, second.rollAt + seconds) and second.compact == false,
			"its roll waits for the first card to have shown its plant",
			second and string.format("%.3f after the first reveal", second.rollAt - first.revealAt))
		local give2 = last("GiveHatched")
		check(give2 ~= nil and second ~= nil and give2.args[5] == second.revealAt
				and near(give2.args[4], (second.revealAt - second.at) + BURST + HATCH.Reveal.Seconds
					+ HATCH.Paid.PulseSeconds),
			"its Tool and its hand wait for ITS OWN reveal, not the first one's")
		check(second ~= nil and first ~= nil and second.token ~= first.token,
			"and it has a token of its own")

		--== THE THIRD: TOO FAR BEHIND ==--
		local ok3, third = hatchNext()
		check(ok3 == true and third ~= nil and third.species == pods[3].id and third.compact == true
				and third.rollAt == third.at and near(third.revealAt, third.at + seconds),
			"a third is not made to wait for two cards: it is told in a line, a whole roll after it hatched",
			third and string.format("compact %s, wait %.2f", tostring(third.compact), third.revealAt - third.at))
		local give3 = last("GiveHatched")
		check(give3 ~= nil and third ~= nil and give3.args[5] == third.revealAt,
			"and its Tool is a secret until then all the same")

		--== A HATCH THAT FAILS TAKES NOTHING ==--
		giveWorks = false
		local ok4, none = hatchNext()
		check(ok4 == false and none == nil and count("SetPlants") == 0 and count("Reveal") == 0,
			"a hatch whose Tool cannot be made does not happen: no save, no announcement")
		giveWorks = true
		local ok5, fourth = hatchNext()
		check(ok5 == true and fourth ~= nil and fourth.species == pods[4].id,
			"the same pod hatches when it can be")
		check(fourth ~= nil and second ~= nil and fourth.compact == true
				and near(fourth.revealAt, fourth.at + seconds),
			"and the failure took none of the card's time: the queue is where the second left it")

		--== LEAVING FREES THE CARD ==--
		check(#leaving >= 1, "PlantService listens for a player leaving")
		for _, fn in ipairs(leaving) do
			fn(owner)
		end
		local ok6, fifth = hatchNext()
		check(ok6 == true and fifth ~= nil and fifth.rollAt == fifth.at and fifth.compact == false
				and near(fifth.revealAt, fifth.at + seconds),
			"a player who left and came back is not behind a card from before they went")

		--== AND WITH THE ROLL OFF, THE SAME SERVICE ==--
		local offService = loadWith(Server.PlantService, {
			PlotService = PlotService,
			PlayerDataService = PlayerDataService,
			CarryService = CarryService,
			PlantWander = PlantWander,
		}, { HatchRoll = rollOff }, fakeGame)
		check(type(offService.InstantHatch) == "function",
			"(the roll-off hatch is HatchRevealSpec's, and loads from the same source)")
	end

	--==========================================================================
	-- 8. EVERYTHING THAT WOULD NAME THE PLANT EARLY
	--==========================================================================
	say("\n-- nothing says it first --")
	do
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
		local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

		--== THE HOTBAR AND THE BAG ==--
		local loadout = sourceOf(scripts and scripts:FindFirstChild("LoadoutUI"))
		check(loadout ~= nil, "LoadoutUI is there to be read")
		if loadout then
			local sealedAt = loadout:find("if HatchRoll.sealed(tool) then", 1, true)
			local rawAt = loadout:find('tool:GetAttribute("Hatched") == true', 1, true)
			check(sealedAt ~= nil and loadout:find("label = HatchRoll.Unknown", 1, true) ~= nil
					and loadout:find('"p:~%s:%d:sealed"', 1, true) ~= nil,
				"a plant mid-roll is classified as ???, sorted by its pod and never by its species")
			check(times(loadout, 'GetAttribute("Hatched")') == 1 and rawAt ~= nil and sealedAt ~= nil
					and rawAt > sealedAt,
				"the one place the hotbar reads Hatched straight off a Tool is after that test",
				times(loadout, 'GetAttribute("Hatched")'))
			check(loadout:find("local hatched = HatchRoll.shownHatched(slot.tool)", 1, true) ~= nil,
				"its picture is the pod's")
			check(loadout:find("if not HatchRoll.shownHatched(data.tool) then", 1, true) ~= nil,
				"its chip says POD, not a size edged in its rarity's colour")
			check(loadout:find("HatchRoll.shownHatched(tool),", 1, true) ~= nil
					and loadout:find("hatched = HatchRoll.shownHatched(slot.tool),", 1, true) ~= nil,
				"and the Bag's card and details are a pod's")
			local holdAt = loadout:find("local function holdTool(", 1, true)
			local guardAt = holdAt and loadout:find("if HatchRoll.sealed(tool) then", holdAt, true)
			local equipAt = holdAt and loadout:find("humanoid:EquipTool(tool)", holdAt, true)
			check(holdAt ~= nil and guardAt ~= nil and equipAt ~= nil and guardAt < equipAt
					and times(loadout, "EquipTool(tool)") == 1,
				"it cannot be taken in the hands, which is the only place a client equips anything")
			check(loadout:find("or name == HatchRoll.Attribute then", 1, true) ~= nil,
				"and the card repaints as the plant the moment the Tool's time comes off")
		end

		--== THE WORLD ==--
		local fx = sourceOf(scripts and scripts:FindFirstChild("HatchFX"))
		check(fx ~= nil, "HatchFX is there to be read")
		if fx then
			check(fx:find("local startAt = rolled + paidLead + BURST * 0.55 - behind", 1, true) ~= nil,
				"the creature, and the label that is drawn with it, wait for the roll")
			check(times(fx, "SoundKit.emit(REVEAL_FOR[species.Rarity]") == 1
					and times(fx, "fanfare()") == 3
					and fx:find("if rolled == 0 then", 1, true) ~= nil,
				"the fanfare names the rarity, so at the burst it plays only when there is no roll",
				times(fx, "fanfare()"))
			check(fx:find('holder.Name = "HatchQuestion"', 1, true) ~= nil
					and fx:find('word.Text = "?"', 1, true) ~= nil,
				"and until then the soil holds a question mark")
			check(fx:find("local cardPlays = rolled > 0 and not HatchRoll.claim(token)", 1, true) ~= nil,
				"the owner hears the fanfare once: from the card, or from here when the card is away")
			check(fx:find("CameraType", 1, true) == nil and fx:find("FireServer", 1, true) == nil,
				"it still takes no camera and sends nothing")
		end

		--== THE INDEX AND THE GUIDE ==--
		local index = sourceOf(scripts and scripts:FindFirstChild("IndexUI"))
		check(index ~= nil and index:find("HatchRoll.sealedSpecies(player)", 1, true) ~= nil,
			"the Index keeps a first discovery's silhouette until its plant has been shown")
		local guide = sourceOf(scripts and scripts:FindFirstChild("TutorialUI"))
		check(guide ~= nil and guide:find("HatchRoll.pendingUntil(player)", 1, true) ~= nil,
			"and the guide's congratulations for a first hatch come after its card, not over it")

		--== THE CARD ==--
		local card = sourceOf(scripts and scripts:FindFirstChild("HatchRollUI"))
		check(card ~= nil, "HatchRollUI is there to be read")
		if card then
			check(card:find("FireServer", 1, true) == nil and card:find("InvokeServer", 1, true) == nil,
				"the card sends nothing to the server: closing it, or never drawing it, changes nothing")
			check(card:find("math.random", 1, true) == nil and card:find("Random.new", 1, true) == nil
					and card:find("SeedData.Roll", 1, true) == nil,
				"and picks nothing: it has no random number in it")
			check(card:find("frames = HatchRoll.frames(speciesId, token)", 1, true) ~= nil
					and card:find("payload.owner ~= player", 1, true) ~= nil,
				"its silhouettes are the server's plant and token, and it is drawn for the owner alone")
			check(card:find("CameraType", 1, true) == nil
					and card:find("SetAttribute(ATTR.OpenPanel", 1, true) == nil
					and card:find("ModalEnabled", 1, true) == nil,
				"it is not a panel: it takes no camera, no movement and nobody's turn at a menu")
			check(card:find("close.Selectable = false", 1, true) ~= nil
					and card:find("card.button.Selectable = false", 1, true) ~= nil
					and card:find("card.action.Selectable = false", 1, true) ~= nil
					and card:find("Enum.KeyCode.ButtonB", 1, true) ~= nil,
				"nothing on it takes a controller's selection, and B puts it away")
			check(card:find("local ok, err = pcall(step)", 1, true) ~= nil
					and card:find("pcall(onHatch, payload)", 1, true) ~= nil,
				"and an error in it puts the card away instead of stopping anything")
			local failAt = card:find("local failed = current", 1, true)
			local keepAt = failAt and card:find("table.insert(waiting, failed)", failAt, true)
			local hideAt = failAt and card:find("pcall(hideCard)", failAt, true)
			check(failAt ~= nil and keepAt ~= nil and hideAt ~= nil and keepAt < hideAt
					and card:find("failed.compact = true", failAt, true) ~= nil,
				"the plant that was on a card that failed is still told, in a line, at its own time")
			check(card:find("if HatchRoll.claim(hatch.token) then", 1, true) ~= nil,
				"it plays the fanfare only for a hatch nobody has sounded yet")
		end

		--== THE SERVER ==--
		local plant = sourceOf(Server:FindFirstChild("PlantService"))
		check(plant ~= nil, "PlantService is there to be read")
		if plant then
			local from = plant:find("function hatch(player: Player, entry: Planted, early: boolean?): boolean",
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
			check(lines:find("HatchRoll.schedule(now, rollBusy[player.UserId])", 1, true) ~= nil
					and lines:find("entry.species, entry.tier", 1, true) ~= nil
					and lines:find("SeedData.Roll", 1, true) == nil and lines:find("Random", 1, true) == nil,
				"the roll is given a time and nothing else: the plant is the pod's entry, as it was")
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
-- 9. WHERE THE CARD STANDS, ON SCREENS NOBODY HERE HAS
--
-- The card's own placing, cut out of its source and run against HudLayout's
-- answer for each screen: phones with and without a notch, tablets, windows
-- down to 640 x 480, and a television. It must be on the screen, over the
-- hotbar, and clear of every HUD group it shares rows with.
--==============================================================================
local function placing()
	say("\n-- where the card stands --")
	local HudLayout = require(Shared:WaitForChild("HudLayout"))
	local scripts = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local read = sourceOf(scripts and scripts:FindFirstChild("HatchRollUI"))
	local source = read and string.gsub(read, string.char(13, 10), string.char(10))
	local from = source and source:find("local function place(): number", 1, true)
	local to = from and source:find("\nend\n", from, true)
	local plateW, plateH = nil, nil
	local overhang = nil
	if source then
		plateW, plateH = source:match("local PLATE = Vector2%.new%((%d+), (%d+)%)")
		overhang = source:match("local OVERHANG = (%d+)")
	end
	check(from ~= nil and to ~= nil and plateW ~= nil and overhang ~= nil,
		"the card's own placing can be found in its source")
	if not (from and to and plateW and overhang) then
		return
	end
	local chunk, err = loadstring("local HudLayout, UIKit, gui, plate, plateScale, PLATE, OVERHANG = ...\n"
		.. source:sub(from, to + 4) .. "\nreturn place", "=HatchRollUI.place")
	check(chunk ~= nil, "and it compiles by itself", err)
	if not chunk then
		return
	end
	local PLATE = Vector2.new(tonumber(plateW), tonumber(plateH))
	local HANG = tonumber(overhang)

	local TOPBAR = 58
	local function rect(x, y, w, h)
		return { x = x, y = y, w = w, h = h }
	end
	local function screen(w, h, opts)
		opts = opts or {}
		local left, right, bottom = opts.left or 0, opts.right or 0, opts.bottom or 0
		return {
			safe = Vector2.new(w - left - right, h - TOPBAR - bottom),
			touch = opts.touch == true,
			keyboard = opts.keyboard ~= false,
			viewport = Vector2.new(w, h),
			topbar = rect(208, 0, w - 208, TOPBAR),
			insetTop = TOPBAR,
		}
	end
	local cases = {}
	for _, p in ipairs({ { 640, 480 }, { 772, 360 }, { 801, 392 }, { 874, 402 }, { 896, 414 }, { 956, 440 },
		{ 1000, 609 } }) do
		table.insert(cases, { tag = string.format("%dx%d phone", p[1], p[2]),
			input = screen(p[1], p[2], { touch = true, keyboard = false }) })
		table.insert(cases, { tag = string.format("%dx%d emulated phone", p[1], p[2]),
			input = screen(p[1], p[2], { touch = true, keyboard = true }) })
	end
	for _, p in ipairs({ { 874, 402, 62, 21 }, { 956, 440, 62, 21 }, { 896, 414, 48, 21 }, { 799, 359, 47, 21 } }) do
		table.insert(cases, { tag = string.format("%dx%d notched phone", p[1], p[2]),
			input = screen(p[1], p[2], { touch = true, keyboard = false, left = p[3], right = p[3],
				bottom = p[4] }) })
	end
	for _, p in ipairs({ { 768, 1024 }, { 1024, 768 }, { 1366, 1024 } }) do
		table.insert(cases, { tag = string.format("%dx%d tablet", p[1], p[2]),
			input = screen(p[1], p[2], { touch = true, keyboard = false }) })
	end
	for _, p in ipairs({ { 1920, 1080 }, { 1600, 900 }, { 1366, 768 }, { 1280, 720 }, { 1024, 768 },
		{ 1000, 609 }, { 860, 700 }, { 800, 600 }, { 700, 400 }, { 640, 480 } }) do
		table.insert(cases, { tag = string.format("%dx%d window", p[1], p[2]),
			input = screen(p[1], p[2], { touch = false }) })
	end
	for _, p in ipairs({ { 1920, 1080, 0 }, { 1920, 1080, 58 }, { 1280, 720, 0 }, { 3840, 2160, 0 } }) do
		table.insert(cases, { tag = string.format("%dx%d television", p[1], p[2]),
			input = HudLayout.tenFootInput({
				safe = Vector2.new(p[1], p[2] - p[3]),
				touch = false,
				keyboard = false,
				viewport = Vector2.new(p[1], p[2]),
				topbar = rect(0, 0, 0, p[3]),
				insetTop = p[3],
			}) })
	end

	local onScreen, overHotbar, clear, sized = 0, 0, 0, 0
	local wrong, tight = {}, {}
	local smallest, largest = math.huge, 0
	for _, case in ipairs(cases) do
		local input = case.input
		local plate, plateScale = { Position = UDim2.new() }, { Scale = 1 }
		local proxy = setmetatable({
			measure = function()
				return input
			end,
		}, { __index = HudLayout })
		local place = chunk(proxy, {
			scaleOf = function()
				return 1
			end,
		}, { AbsoluteSize = input.safe }, plate, plateScale, PLATE, HANG)
		local scale = place()
		local cx, cy = plate.Position.X.Offset, plate.Position.Y.Offset
		local hang = HANG * scale
		-- The card with its X: OVERHANG past the plate at the top and the right.
		local box = rect(cx - PLATE.X * scale / 2, cy - PLATE.Y * scale / 2 - hang,
			PLATE.X * scale + hang, PLATE.Y * scale + hang)
		local L = HudLayout.solve(input)
		local W, H = input.safe.X, input.safe.Y
		smallest, largest = math.min(smallest, scale), math.max(largest, scale)

		local inside = box.x >= 0 and box.y >= 0 and box.x + box.w <= W + 0.01 and box.y + box.h <= H + 0.01
		local above = box.y + box.h <= L.hotbar.y + 0.01
		local touching = {}
		local left, right = 8, W - 8
		for _, group in ipairs(HudLayout.groups(L, true)) do
			local r = group.rect
			if group.name ~= "hotbar" then
				if box.x < r.x + r.w and r.x < box.x + box.w and box.y < r.y + r.h and r.y < box.y + box.h then
					table.insert(touching, group.name)
				end
				if r.y < L.hotbar.y - 8 and r.y + r.h > 6 then
					if r.x + r.w / 2 < W / 2 then
						left = math.max(left, r.x + r.w + 8)
					else
						right = math.min(right, r.x - 8)
					end
				end
			end
		end
		-- A screen with less room between its side columns than the card at its
		-- smallest: nothing could fit, and the card is in the middle of what is.
		local room = right - left >= (PLATE.X + HANG) * 0.8
		if inside then
			onScreen += 1
		end
		if above then
			overHotbar += 1
		end
		if #touching == 0 or not room then
			clear += 1
		end
		if scale >= 0.8 - 1e-9 and scale <= 1.25 + 1e-9 then
			sized += 1
		end
		if not room then
			table.insert(tight, string.format("%s (%d wide between the columns)", case.tag, right - left))
		end
		if not (inside and above and (#touching == 0 or not room)) then
			table.insert(wrong, string.format("%s: box (%d,%d %dx%d) scale %.2f, screen %dx%d, hotbar at %d, touching %s",
				case.tag, box.x, box.y, box.w, box.h, scale, W, H, L.hotbar.y, table.concat(touching, "+")))
		end
	end
	local n = #cases
	check(onScreen == n, string.format("on all %d screens the whole card, its X included, is on the screen", n),
		wrong[1])
	check(overHotbar == n, "and over the hotbar, never on it", wrong[1])
	check(clear == n, "and clear of the rail, the drawer, Garden, the Bag and the bats wherever there is room to be",
		wrong[1])
	check(sized == n and smallest >= 0.8 - 1e-9,
		string.format("drawn between %.2f and %.2f of its size: never too small to read", smallest, largest))
	say(string.format("  NOTE  screens with less room between the side columns than the card needs: %d%s", #tight,
		if #tight > 0 then " -- " .. table.concat(tight, "; ") else ""))

	-- A window too short for the card at any size worth reading: it is drawn at
	-- its floor and no smaller, and on a wide screen at its ceiling and no bigger.
	local function scaleOn(input)
		local plate, plateScale = { Position = UDim2.new() }, { Scale = 1 }
		local proxy = setmetatable({
			measure = function()
				return input
			end,
		}, { __index = HudLayout })
		return chunk(proxy, {
			scaleOf = function()
				return 1
			end,
		}, { AbsoluteSize = input.safe }, plate, plateScale, PLATE, HANG)()
	end
	local squat = scaleOn(screen(640, 250, { touch = false }))
	local vast = scaleOn(screen(3840, 2160, { touch = false }))
	check(near(squat, 0.8), "a window far too short for it still gets a card four fifths the size, not a smaller one",
		squat)
	check(near(vast, 1.25), "and the biggest screen a card a quarter bigger, not more", vast)
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
local placedOk, placedErr = pcall(placing)
if not placedOk then
	fail += 1
	say("  FAIL  the placing section threw  <- " .. tostring(placedErr))
end

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
