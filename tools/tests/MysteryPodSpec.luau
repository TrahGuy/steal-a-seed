--==============================================================================
-- MysteryPodSpec (2026-10-11, Enchanted Mist stage 4)
--
-- The Mysterious Pod (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §10-11).
-- Pure fixture: MysteryPodService is loaded from its source with stand-ins;
-- the pool's unmade creatures are FIXTURE species here only, never registered.
--
--   1. the shell: the owner's LuckhollowPod, one generic species -- unlisted,
--      unsellable, one size, 30 s -- and nothing on it names what is inside
--   2. the saved record: cleaned on load, never in a client's copy
--   3. the grant: creature and (Legendary to Divine) size chosen once, saved
--      under the shell's item with the versions and the ready time; nothing
--      saved when anything fails; no grant until every creature is real
--   4. the hatch: the saved creature at the saved size (a Secret its own),
--      spent once, the owner told for the card reels, a save asked for
--   5. the rules and the wiring: never knocked loose, never sold or
--      sacrificed, no paid shortcut, never in a HATCH ALL, planted with its
--      record, both hatches spend it; the reels touch no camera
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local PodForms = require(Shared:WaitForChild("PodForms"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local SHELL = EnchantedMistData.Shell

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
local function strip(src)
	return (string.gsub(src, "%-%-[^\n]*", ""))
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The shell")
	--==========================================================================
	local shell = SeedData.Get(SHELL.Id)
	check(SHELL.Id == "mysterypod" and shell ~= nil and shell.Name == "Mysterious Pod" and SHELL.Name == shell.Name,
		"one shell, the owner's name for it: Mysterious Pod")
	local listed = false
	for _, s in ipairs(SeedData.Species) do
		if s.Id == SHELL.Id then
			listed = true
		end
	end
	check(shell ~= nil and (shell :: any).Mystery == true and not listed and not SeedData.Sellable(shell)
			and SeedData.Unsized(shell) and SeedData.GrowSecondsFor(shell, 1) == EnchantedMistData.HatchSeconds,
		"unlisted (no nest, Index or stall), unsellable, one size, ready in 30 s")
	check(PodForms.Has(SHELL.Id) and PodForms.Pods[SHELL.Id].Owner.Species == "Luckhollow"
			and PodForms.Pods[SHELL.Id].PartCount == 88,
		"built from the owner's LuckhollowPod, lifted part for part (its base left out, as every owner pod's)")
	local folder = Instance.new("Folder")
	folder.Parent = workspace
	local model = CreatureModel.BuildPod(shell, 1, CFrame.new(0, 300, 0), folder)
	local scripts = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		end
	end
	check(model:GetAttribute("PodForm") == SHELL.Id and scripts == 0 and model:GetAttribute("Rarity") ~= "Event",
		"its pod is the owner's shape, with no script of the builder's")
	folder:Destroy()
	local info = PlantInfo.Describe(SHELL.Id, 1, false)
	check(info.title == "Mysterious Pod" and info.rarity == PlantInfo.Unknown and info.biome == PlantInfo.Unknown
			and info.size == "",
		"its card says Mysterious Pod and nothing else: no biome, rarity or size", info.title)

	--==========================================================================
	say("2. The saved record")
	--==========================================================================
	local cleaned = ProfileSchema.cleanMystery({
		good = { Species = "mossbristle", Size = 3, PoolVersion = 1, SizesVersion = 1, ReadyAt = 100 },
		secret = { Species = "gnarlmaw", PoolVersion = 1, SizesVersion = 1, ReadyAt = 100 },
		badSize = { Species = "mossbristle", Size = 9, PoolVersion = 1, SizesVersion = 1, ReadyAt = 100 },
		badSpecies = { Species = "bad id!", PoolVersion = 1, SizesVersion = 1, ReadyAt = 100 },
		nanReady = { Species = "mossbristle", PoolVersion = 1, SizesVersion = 1, ReadyAt = 0 / 0 },
		[5] = { Species = "mossbristle", ReadyAt = 1 },
	})
	local n = 0
	for _ in pairs(cleaned) do
		n += 1
	end
	check(n == 2 and cleaned.good.Size == 3 and cleaned.secret.Size == nil,
		"cleaned on load: a good record kept whole, a Secret's with no size, anything else dropped", n)
	local profile = ProfileSchema.Default()
	profile.MysteryPods = { i1 = cleaned.good }
	local view = ProfileSchema.ClientView(profile)
	check(type(ProfileSchema.Default().MysteryPods) == "table" and view.MysteryPods == nil
			and profile.MysteryPods.i1 ~= nil and view.Held == profile.Held,
		"never in what a client is sent (ClientView); the server's own copy untouched")
	local pds = strip(Server:WaitForChild("PlayerDataService").Source)
	local _, sends = string.gsub(pds, "FireClient%([^\n]*ProfileSchema%.ClientView%(", "")
	local _, raw = string.gsub(pds, "FireClient%(player, entry%.profile%)", "")
	check(sends == 2 and raw == 0, "both profile sends (ProfileUpdated and ProfileReady) go through ClientView", sends)

	--==========================================================================
	-- THE SERVICE, FROM ITS SOURCE, WITH FIXTURE CREATURES
	--==========================================================================
	local moduleScript = Server:WaitForChild("MysteryPodService")
	local chunk = loadstring(moduleScript.Source, "=MysteryPodService")
	setfenv(chunk, setmetatable({ script = moduleScript, require = function(target)
		if target.Name == "PlayerDataService" or target.Name == "CarryService" then
			return {}
		end
		return require(target)
	end }, { __index = getfenv(1) }))
	local M = chunk()
	local H = M.Hooks
	local fixtures = {}
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		fixtures[e.Id] = SeedData.Get(e.Id) or { Id = e.Id, Name = e.Name, Rarity = e.Rarity,
			Secret = e.Rarity == "Secret" or nil }
	end
	local real = true
	H.species = function(id)
		if id == SHELL.Id then
			return shell
		end
		return if real then fixtures[id] else SeedData.Get(id)
	end
	local clock = 5000
	H.now = function()
		return clock
	end
	local rolls = {}
	H.random = function()
		return table.remove(rolls, 1) or 0
	end
	local given, nextItem = true, 7
	H.giveShell = function(_player, id)
		if not given or id ~= SHELL.Id then
			return false, nil
		end
		nextItem += 1
		return true, "i" .. nextItem
	end
	local P = { Name = "SpecHatcher", UserId = 90000000051 }
	local prof = { MysteryPods = {} }
	H.profile = function()
		return prof
	end
	local saves, told = 0, {}
	H.saveSoon = function()
		saves += 1
	end
	H.tell = function(_p, payload)
		table.insert(told, payload)
	end

	--==========================================================================
	say("3. The grant")
	--==========================================================================
	-- 0 picks the pool's first (Legendary: sized); then the size roll.
	rolls = { 0, 0.999 }
	local granted = M.Grant(P, prof)
	local rec = prof.MysteryPods.i8
	local first = EnchantedMistData.Pool.Entries[1]
	check(granted and rec ~= nil and rec.Species == first.Id and rec.Size == #EnchantedMistData.Sizes.Weights
			and rec.PoolVersion == EnchantedMistData.Pool.Version and rec.SizesVersion == EnchantedMistData.Sizes.Version
			and rec.ReadyAt == clock + EnchantedMistData.HatchSeconds,
		"a Legendary: the creature and its size chosen once, saved under the shell's item with both versions and "
			.. "the 30 s ready time", if rec then rec.Species .. " " .. tostring(rec.Size) else "none")
	-- 0.9995 lands on the last entry (a Secret): no size roll.
	rolls = { 0.9995, 0.5 }
	M.Grant(P, prof)
	local secretRec = prof.MysteryPods.i9
	check(secretRec ~= nil and EnchantedMistData.Pool.Entries[#EnchantedMistData.Pool.Entries].Rarity == "Secret"
			and secretRec.Size == nil and #rolls == 1,
		"a Secret keeps its own size: no size is rolled for it", secretRec and secretRec.Species)
	given = false
	local before = 0
	for _ in pairs(prof.MysteryPods) do
		before += 1
	end
	rolls = { 0, 0 }
	local refused = not M.Grant(P, prof)
	local after = 0
	for _ in pairs(prof.MysteryPods) do
		after += 1
	end
	check(refused and before == after, "no shell given (the Bag full, say): nothing saved, the grant refused")
	given = true
	real = false
	local allReal = true
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		if SeedData.Get(e.Id) == nil then
			allReal = false
		end
	end
	check(M.CanGrant() == allReal, "no grant until every creature the pool can pick is a real species (none substituted)")
	rolls = { 0, 0 }
	check(SeedData.Get(first.Id) ~= nil or not M.Grant(P, prof), "a creature the game cannot make is never saved")
	real = true

	--==========================================================================
	say("4. The hatch")
	--==========================================================================
	local o = M.Outcome(P, "i8")
	local so = M.Outcome(P, "i9")
	check(o ~= nil and o.species.Id == first.Id and o.tier == rec.Size and o.readyAt == rec.ReadyAt
			and so ~= nil and so.size == nil and so.tier == SeedData.SecretTier and M.Outcome(P, "nope") == nil,
		"the saved creature at the saved size; a Secret at its own; an unknown item nothing")
	local oSized = o ~= nil and o.size ~= nil and EnchantedMistData.isSized(tostring(o.species.Rarity))
	M.TellHatch(P, o, 41)
	check(#told == 1 and told[1].phase == "hatch" and told[1].species == first.Id and told[1].size == rec.Size
			and told[1].seconds == EnchantedMistData.drawSeconds(oSized) and saves == 1,
		"its owner told the saved creature and size for the card draw, and a save asked for")
	-- EACH DRAW IN ITS TURN (2026-10-12, the owner: "sometimes the draw doesn't run, it auto chooses"): a second
	-- hatch's draw starts when this player's last one ends; a hatch refused after its reservation gives it back.
	local a0, aLen = M.Reserve(P, o, 1000)
	local b0, bLen = M.Reserve(P, so, 1001, 0.5)
	M.Unreserve(P, b0, bLen)
	local c0 = M.Reserve(P, so, 1002)
	check(a0 == 1000 and aLen == EnchantedMistData.drawSeconds(oSized) and b0 == a0 + aLen
			and bLen == EnchantedMistData.drawSeconds(false) and c0 == a0 + aLen,
		"each draw in its turn: a second one starts as the first ends, a refused one gives its slot back",
		string.format("a %.1f+%.1f, b %.1f, c %.1f", a0, aLen, b0, c0))
	M.Consume(P, "i8")
	check(prof.MysteryPods.i8 == nil and M.Outcome(P, "i8") == nil and prof.MysteryPods.i9 ~= nil,
		"spent once: the record gone with the shell, the other pod's kept")

	--==========================================================================
	say("5. The rules and the wiring")
	--==========================================================================
	local plant = strip(Server:WaitForChild("PlantService").Source)
	local carry = strip(Server:WaitForChild("CarryService").Source)
	local sacrifice = strip(Server:WaitForChild("SacrificeService").Source)
	local moss = strip(Server:WaitForChild("MosskeeperService").Source)
	check(string.find(carry, "if species and (species :: any).Mystery == true then\n\t\treturn false, \"mystery\"", 1, true)
			~= nil, "never knocked loose: it stays in the hands (the owner's exception)")
	check(string.find(sacrifice, "if shell and (shell :: any).Mystery == true then\n\t\treturn \"MYSTERY\", nil", 1, true)
			~= nil and not SeedData.Sellable(shell),
		"never sacrificed until hatched; never sold (unsellable)")
	check(string.find(plant, "if MysteryPodService.IsShell(row.Id) then\n\t\treturn false, \"MYSTERY\"", 1, true) ~= nil
			and string.find(plant, "if entry.starter or (entry.species :: any).Mystery == true then", 1, true) ~= nil
			and string.find(plant, "not MysteryPodService.IsShell(row.Id) then", 1, true) ~= nil,
		"no paid shortcut (no offer, no bed prompt), and never in a HATCH ALL")
	check(string.find(plant, "podTool:Destroy()\n\tCarryService.SyncHeldNow(player, { podTool })\n\t\n\tif mystery then\n"
			.. "\t\tMysteryPodService.Consume(player, item)", 1, true) ~= nil
			and string.find(plant, "persist(entry.plot)\n\t\n\tif mystery and entry.item then\n"
				.. "\t\tMysteryPodService.Consume(player, entry.item)", 1, true) ~= nil,
		"both hatches (the Bag's and the bed's) spend the record in the step that takes the shell away")
	check(string.find(plant, "(hatched or (species :: any).Mystery == true)", 1, true) ~= nil
			and string.find(plant, "STAGE_GROWN or (entry.species :: any).Mystery == true", 1, true) ~= nil
			and string.find(plant, "(stage == CreatureModel.STAGE_GROWN or (species :: any).Mystery == true)", 1, true)
				~= nil,
		"planted, it keeps its item in the bed, in the save and on a reload: its record follows it")
	check(string.find(moss, "if Hooks.grantPod == nil or not Hooks.canGrant() then", 1, true) ~= nil
			and string.find(moss, "if result.phase == \"given\" and result.pods > 0 then\n\t\tHooks.saveSoon(player)", 1,
				true) ~= nil,
		"the Mosskeeper refuses a pod-earning delivery until a pod can be granted, and saves after one")
	local reels = strip(Scripts:WaitForChild("MysteryRevealUI").Source)
	check(string.find(reels, "CFG.Action", 1, true) ~= nil and not string.find(reels, "CurrentCamera", 1, true)
			and string.find(reels, "if PerformanceMode.ownReduced(player) then", 1, true) ~= nil
			and string.find(reels, "return (GuiService :: any).ReducedMotionEnabled", 1, true) ~= nil
			and not string.find(reels, "StatusText.reducedMotion()", 1, true)
			and not string.find(reels, "HatchRollUI", 1, true),
		"the card reels: this family's own, no camera; only an EXPLICIT Reduced Motion -- the player's own Reduced "
			.. "FX or Roblox's -- lands them at once, never Performance Mode alone (2026-10-12)")
	check(string.find(reels, "local wait = (tonumber(payload.startAt) or 0) - Workspace:GetServerTimeNow()", 1, true)
				~= nil
			and string.find(reels, "table.insert(queue, payload)\n\t\tif not busy then\n\t\t\trunNext()", 1, true) ~= nil
			and string.find(reels, "task.delay(times.close, finish, mine)", 1, true) ~= nil,
		"every draw plays whole and in its turn, from the server's start for it (MysteryPodService.Reserve)")
	check(string.find(reels, "local SKIP_HOLD = 0.8", 1, true) ~= nil
			and string.find(reels, "local SKIP_AFTER = 0.5", 1, true) ~= nil
			and string.find(reels, "end, false, 3000, Enum.KeyCode.ButtonB)", 1, true) ~= nil
			and string.find(reels, "if not snap then\n\t\ttask.delay(SKIP_AFTER, function()", 1, true) ~= nil
			and string.find(reels, "then Vector2.new(96, 44) else Vector2.new(84, 34)", 1, true) ~= nil
			and string.find(reels, "task.delay(SKIP_HOLD, finish, skipped)", 1, true) ~= nil
			and string.find(reels, "local land = landNow\n\t\tif land then\n\t\t\tland()\n\t\tend", 1, true) ~= nil
			and string.find(reels, "if sizing or not sized then", 1, true) ~= nil
			and not string.find(reels, "creatureReel(payload, 0)", 1, true),
		"SKIP (the owner, 2026-10-12): shown 0.5 s into a moving draw, a touch screen's 44 tall, the pad's B; the "
			.. "reel on screen lands where it was going (the same cards, none built again), each landed card held 0.8 s "
			.. "-- on the size reel only the size; nothing sent")
	check(string.find(reels, "gui.ScreenInsets = Enum.ScreenInsets.None", 1, true) ~= nil
			and string.find(reels, "gui.IgnoreGuiInset = true", 1, true) ~= nil
			and string.find(reels, "scrim.BackgroundTransparency = 0.55", 1, true) ~= nil
			and not string.find(reels, "BackgroundColor3 = WHITE", 1, true)
			and not string.find(reels, "Instance.new(\"CanvasGroup\")", 1, true)
			and string.find(reels, "local CREATURE_COUNT, CREATURE_LAND = 34, 30", 1, true) ~= nil
			and string.find(reels, "local SIZE_COUNT, SIZE_LAND = 30, 26", 1, true) ~= nil
			and string.find(reels, "gui.DisplayOrder = 44", 1, true) ~= nil,
		"THE LOOK (2026-10-12): no white panel -- the cards run over a slight dimmer covering the whole screen, notches "
			.. "and the rail's buttons too (44: under the notices and the RUN alarm), with no CanvasGroup; about twice "
			.. "the cards for the longer spin")
	local MistOddsView = require(Shared:WaitForChild("MistOddsView"))
	-- WHERE THE DRAW STANDS (2026-10-12, the owner: "make the reel's cards BIGGER
	-- and the strip CENTRED a bit LOWER on screen (not hugging the top row), on
	-- desktop and phones. Keep the SKIP pill clear"). HudLayout's own answer for
	-- HudLayoutSpec's screens: the cards at least 1.15x (a desktop's 1.3x),
	-- centred at half the screen or lower, under the top row, inside the safe
	-- width and above the belt's name line (a compact screen's belt middle); SKIP
	-- at its own size clear of the top row, the belt and a phone's thumbs.
	local HudLayout = require(Shared:WaitForChild("HudLayout"))
	local TOPBAR = 58
	local function screenOf(w, h, opts)
		local left, right, bottom = opts.left or 0, opts.right or 0, opts.bottom or 0
		return {
			safe = Vector2.new(w - left - right, h - TOPBAR - bottom),
			touch = opts.touch == true,
			keyboard = opts.keyboard ~= false,
			viewport = Vector2.new(w, h),
			topbar = HudLayout.rect(208, 0, w - 208, TOPBAR),
			insetTop = TOPBAR,
		}, Vector2.new(left, TOPBAR)
	end
	local SCREENS = {
		{ 1169, 716, {} }, { 1280, 720, {} }, { 1920, 1080, {} }, { 1000, 609, {} },
		{ 705, 338, { touch = true } }, { 640, 360, { touch = true, keyboard = false } },
		{ 772, 360, { touch = true, keyboard = false } }, { 801, 392, { touch = true } },
		{ 844, 390, { touch = true, keyboard = false, left = 47, right = 47, bottom = 21 } },
		{ 956, 440, { touch = true, keyboard = false, left = 62, right = 62, bottom = 21 } },
	}
	local placeBad = {}
	local function overlaps(a, b)
		return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
	end
	for _, c in ipairs(SCREENS) do
		local input, shift = screenOf(c[1], c[2], c[3])
		local L = HudLayout.solve(input)
		local s, centre = MistOddsView.drawPlace(L, Vector2.new(c[1], c[2]), shift, 1)
		local box = MistOddsView.DrawStage * s
		local x0, y0 = centre.X - box.X / 2, centre.Y - box.Y / 2
		local touch = c[3].touch == true
		local pw, ph = if touch then 96 else 84, if touch then 44 else 34
		local pill = { x = x0 + box.X - 8 * s - pw, y = y0 + 22 * s - ph / 2, w = pw, h = ph }
		local topRow = shift.Y
		for _, key in ipairs({ "biomes", "teleport", "returnPlot", "obby", "run" }) do
			local r = L[key]
			if r and r.w > 0 and r.h > 0 then
				topRow = math.max(topRow, shift.Y + r.y + r.h)
			end
		end
		local hot = L.hotbar
		local floor = if L.compact then shift.Y + hot.y + hot.h / 2 else shift.Y + math.min(hot.y, L.namePopup.y)
		local tag = string.format("%dx%d", c[1], c[2])
		if s < 1.15 or (not L.compact and s < MistOddsView.DrawMax) then
			table.insert(placeBad, string.format("%s cards at %.2fx", tag, s))
		end
		if centre.Y < 0.5 * c[2] - 0.5 or y0 < topRow or pill.y < topRow then
			table.insert(placeBad, tag .. " up in the top row")
		end
		if x0 < shift.X or x0 + box.X > shift.X + L.safe.X or y0 + box.Y > floor + 0.5 then
			table.insert(placeBad, tag .. " off the safe width or on the belt")
		end
		for _, key in ipairs({ "hotbar", "namePopup", "jump", "thumb" }) do
			local r = L[key]
			if r and r.w > 0 and overlaps(pill, { x = shift.X + r.x, y = shift.Y + r.y, w = r.w, h = r.h }) then
				table.insert(placeBad, tag .. " SKIP on " .. key)
			end
		end
	end
	check(#placeBad == 0 and string.find(reels, "local scale, centre = MistOddsView.drawPlace(L, size, "
				.. "measureGui.AbsolutePosition - gui.AbsolutePosition,", 1, true) ~= nil
			and string.find(reels, "stageScale.Scale = scale", 1, true) ~= nil
			and string.find(reels, "local TITLE_ROW = 44", 1, true) ~= nil
			and string.find(reels, "skipButton.Position = UDim2.new(1, -8, 0, TITLE_ROW / 2)", 1, true) ~= nil
			and string.find(reels, "skipButton.Size = UDim2.fromOffset(nominal.X / s, nominal.Y / s)", 1, true) ~= nil,
		"WHERE THE DRAW STANDS (2026-10-12): on every listed desktop and phone the cards bigger (1.15x and up, a "
			.. "desktop's 1.3x), centred lower, under the top row and above the belt; SKIP beside the title at its own "
			.. "size, clear of the belt and the thumbs", table.concat(placeBad, "; "))
	-- A DRAW IS A MOMENT (2026-10-12, the owner: the guide's banner, its step and
	-- GUIDE hide while it runs, and come back after): begun as it starts, ended
	-- as it closes, and a re-run leaves none standing; the guide's words give
	-- way to it (TutorialUI's coverWords; HudLayoutSpec pins that side).
	local RewardMoments = require(Shared:WaitForChild("RewardMoments"))
	local _, finishes = string.gsub(reels, "RewardMoments%.finish%(RewardMoments%.MysteryDraw%)", "")
	check(type(RewardMoments.MysteryDraw) == "string"
			and string.find(reels, "gui.Enabled = true\n\t\n\tRewardMoments.begin(RewardMoments.MysteryDraw)", 1, true)
				~= nil
			and string.find(reels, "gui.Enabled = false\n\tRewardMoments.finish(RewardMoments.MysteryDraw)", 1, true) ~= nil
			and finishes == 2,
		"a draw is a reward moment from its start to its close (RewardMoments.MysteryDraw); a re-run leaves none up")
	-- A reel's card stands a creature that exists in its window, as the Odds
	-- page does; one not made yet keeps the dark "???".
	local made, unmade
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		if SeedData.Get(e.Id) then
			made = made or e
		else
			unmade = unmade or e
		end
	end
	local holder = Instance.new("Frame")
	local views = {}
	local drawn, dark = nil, nil
	if made then
		local card = MistOddsView.card(holder, made, 1, 140, {}, {}, views)
		MistOddsView.drawViews(views)
		local window = card:FindFirstChild("Plant", true)
		drawn = window ~= nil and window:FindFirstChildWhichIsA("Model", true) ~= nil and window.CurrentCamera ~= nil
	end
	if unmade then
		local card = MistOddsView.card(holder, unmade, 1, 140, {}, {}, views)
		local unknown = card:FindFirstChild("Unknown", true)
		dark = card:FindFirstChild("Plant", true) == nil and unknown ~= nil and unknown.Text == "???"
	end
	holder:Destroy()
	check(made ~= nil and drawn == true and (unmade == nil or dark == true)
			and string.find(reels, "MistOddsView.card(slot, e, Z + 2, CARD_H, moving, fx, views[i])", 1, true) ~= nil
			and string.find(reels, "if i == CREATURE_LAND then entryFor(species, payload.rarity)", 1, true) ~= nil
			and string.find(reels, "for k = math.max(1, centred - 2), math.min(CREATURE_COUNT, centred + 3) do", 1,
				true) ~= nil
			and string.find(reels, "if made >= 2 and not all then", 1, true) ~= nil
			and string.find(reels, "MistOddsView.drawViews(list)", 1, true) ~= nil
			and string.find(reels, "end, seconds, near)", 1, true) ~= nil,
		"a reel's card draws a creature that exists in its window -- every card (a 5.5 s spin is no blur), each built as "
			.. "it nears the notches, two a frame at most; one not made yet stays \"???\"",
		string.format("made %s drawn %s dark %s", tostring(made and made.Id), tostring(drawn), tostring(dark)))
	-- No black window behind a creature (2026-10-12, the owner), on the Odds
	-- page and the reels alike: a made one stands on its card's studs, white,
	-- in the Odds' own light; only one with no model yet keeps the dark "???".
	local ODDS = EnchantedMistConfig.Mosskeeper.Odds
	local clearHolder = Instance.new("Frame")
	local clear = MistOddsView.card(clearHolder, made, 1, 140, {}, {}, {})
	local ghost = MistOddsView.card(clearHolder, { Id = "zz_unmade", Name = "Nobody", Rarity = "Mythic", Weight = 0 },
		1, 140, {}, {}, {})
	local well, plantView = clear:FindFirstChild("Preview", true), clear:FindFirstChild("Plant", true)
	local ghostWell, ghostWord = ghost:FindFirstChild("Preview", true), ghost:FindFirstChild("Unknown", true)
	local lit = plantView ~= nil and plantView.ImageColor3 == Color3.new(1, 1, 1) and plantView.Ambient == ODDS.Ambient
		and plantView.LightColor == ODDS.LightColour and ODDS.Ambient ~= nil
	local studded = clear:FindFirstChild("Studs", true)
	clearHolder:Destroy()
	check(well ~= nil and well.BackgroundTransparency == 1 and studded ~= nil and studded.Visible and lit
			and ghostWell ~= nil and ghostWell.BackgroundTransparency == 0 and ghostWord ~= nil
			and ghostWord.Text == "???" and ghost:FindFirstChild("Plant", true) == nil,
		"no black window behind a creature: it stands on its card's studs, white, in the Odds' own light; only one "
			.. "with no model yet keeps the dark \"???\" window")
	-- THE LANDED CREATURE HOLDS (2026-10-12, the owner via the peer: the size
	-- reel replaced it after ~0.15 s): ~1 s to read it before the size reel;
	-- the size still lands before the world reveal; the whole reveal compact.
	-- A chance on a LIGHT card in its rarity's deep ink (2026-10-12, the peer
	-- for the owner: Divine's cream "5%" was lost on the pearl): dark enough to
	-- read there; Mythic keeps its own rose, a card that is not light its own.
	local GameConfig = require(Shared:WaitForChild("GameConfig"))
	local inkHolder = Instance.new("Frame")
	local function chanceOf(rarity)
		local card = MistOddsView.card(inkHolder, { Id = made.Id, Name = "Ink", Rarity = rarity, Weight = 5 }, 1, 140,
			{}, {}, {})
		return card:FindFirstChild("Chance", true)
	end
	local divine, mythic, legendary = chanceOf("Divine"), chanceOf("Mythic"), chanceOf("Legendary")
	inkHolder:Destroy()
	local function lum(c)
		return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
	end
	local pearlTop = GameConfig.BagLook.Studs.pearl.top
	check(ODDS.LightCards.pearl == true and ODDS.LightCards.stone == true and divine ~= nil
			and divine.TextColor3 == ODDS.InkOnLight.Divine and lum(pearlTop) - lum(divine.TextColor3) >= 0.3
			and mythic ~= nil and mythic.TextColor3 == GameConfig.RarityColor.Mythic
			and legendary ~= nil and legendary.TextColor3 == GameConfig.RarityColor.Legendary
			and ODDS.InkOnLight.Common ~= nil and lum(ODDS.InkOnLight.Common) < 0.35,
		"a chance on a light card (the pearl, the stone) in its rarity's deep ink, dark enough to read; Mythic's rose "
			.. "and a gold card's own colour stay",
		divine and tostring(divine.TextColor3))
	-- EACH REEL SPINS AT LEAST 5 s (the owner, 2026-10-12): the creature reel, its landed card's ~1 s hold, and a
	-- sized creature's size reel as long again, landing before the world reveal; a Secret's reel, then its words.
	local sizedT = EnchantedMistData.reelTimes(true)
	local secretT = EnchantedMistData.reelTimes(false)
	local sizedAll, otherAll = EnchantedMistData.drawSeconds(true), EnchantedMistData.drawSeconds(false)
	check(SHELL.SpinSeconds >= 5 and sizedT.creature >= 5 and sizedT.sizeSpin >= 5 and secretT.creature >= 5
			and SHELL.LandHoldSeconds >= 1 and SHELL.LandHoldSeconds <= 1.2
			and math.abs(sizedT.next - sizedT.creature - SHELL.LandHoldSeconds) < 1e-9
			and sizedT.next + sizedT.sizeSpin <= sizedAll - 0.2
			and secretT.next - secretT.creature <= 0.2 and otherAll >= secretT.creature + 1
			and sizedAll >= 11 and sizedAll <= 14 and otherAll >= 6 and otherAll <= 7.5,
		"EACH REEL SPINS AT LEAST 5 s: the creature reel, its landed card's ~1 s hold and the size reel as long "
			.. "again, landing before the world reveal (~12.7 s); a Secret's reel, then \"A SECRET!\" (~6.6 s)",
		string.format("creature %.2f next %.2f size %.2f; %.1f s / %.1f s", sizedT.creature, sizedT.next,
			sizedT.sizeSpin, sizedAll, otherAll))
	check(string.find(reels, "local times = EnchantedMistData.reelTimes(sized)", 1, true) ~= nil
			and string.find(reels, "task.delay(times.next, function()", 1, true) ~= nil
			and string.find(reels, "creatureReel(payload, if snap then 0 else times.creature)", 1, true) ~= nil
			and string.find(reels, "sizeReel(payload, if snap then 0 else times.sizeSpin)", 1, true) ~= nil
			and string.find(reels, "TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)", 1, true)
				~= nil,
		"the draw takes its times from reelTimes (an explicit Reduced Motion still lands each reel at once); each reel "
			.. "brakes evenly (Quad), moving the whole spin and stopping as CARD LANDS plays")
	-- The reels' filler: by the odds' own mix (never misstating them), the
	-- answer always at the landing, never two alike side by side -- at the
	-- client's own counts (34 cards landing on 30; 30 sizes on 26).
	local LAND, COUNT = 30, 34
	local SIZE_LAND, SIZE_COUNT = 26, 30
	local ids, tiers = {}, {}
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		table.insert(ids, e.Id)
	end
	for tier = 1, #EnchantedMistData.Sizes.Weights do
		table.insert(tiers, tier)
	end
	local seen, sizesSeen, filler, sizeFiller = {}, {}, 0, 0
	local landedRight, alike = 0, 0
	for token = 1, 300 do
		local answer = ids[(token % #ids) + 1]
		local rng = Random.new(token)
		local items = MistOddsView.reelItems(COUNT, LAND, answer, function()
			return EnchantedMistData.pickCreature(rng:NextNumber()).Id
		end, ids)
		local sizeAnswer = tiers[(token % #tiers) + 1]
		local sizeRng = Random.new(token + 1)
		local sizes = MistOddsView.reelItems(SIZE_COUNT, SIZE_LAND, sizeAnswer, function()
			return EnchantedMistData.pickSize(sizeRng:NextNumber())
		end, tiers)
		if items[LAND] == answer and sizes[SIZE_LAND] == sizeAnswer and #items == COUNT and #sizes == SIZE_COUNT then
			landedRight += 1
		end
		for i = 1, COUNT do
			if i > 1 and items[i] == items[i - 1] then
				alike += 1
			end
			if i ~= LAND then
				seen[items[i]] = (seen[items[i]] or 0) + 1
				filler += 1
			end
		end
		for i = 1, SIZE_COUNT do
			if i > 1 and sizes[i] == sizes[i - 1] then
				alike += 1
			end
			if i ~= SIZE_LAND then
				sizesSeen[sizes[i]] = (sizesSeen[sizes[i]] or 0) + 1
				sizeFiller += 1
			end
		end
	end
	local commonest = ids[1]
	for _, id in ipairs(ids) do
		if (seen[id] or 0) > (seen[commonest] or 0) then
			commonest = id
		end
	end
	local secrets = 0
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		if e.Rarity == "Secret" then
			secrets += seen[e.Id] or 0
		end
	end
	local tinyMost = true
	for tier = 2, #tiers do
		if (sizesSeen[tier] or 0) >= (sizesSeen[1] or 0) then
			tinyMost = false
		end
	end
	check(landedRight == 300 and alike == 0, "every reel lands on the saved answer; no two alike side by side",
		string.format("landed %d/300, alike %d", landedRight, alike))
	check(commonest == "mossbristle" and secrets / filler < 0.03 and tinyMost
			and (sizesSeen[7] or 0) / sizeFiller < 0.03
			and string.find(reels, "return EnchantedMistData.pickCreature(rng:NextNumber()).Id", 1, true) ~= nil
			and string.find(reels, "return EnchantedMistData.pickSize(sizeRng:NextNumber())", 1, true) ~= nil,
		"the filler follows the odds: mostly Mossbristle and Tiny, the Secrets and Colossal rarest",
		string.format("commonest %s, secrets %.3f, colossal %.3f", commonest, secrets / filler,
			(sizesSeen[7] or 0) / sizeFiller))
	-- The size cards wear their odds at the top too; Colossal's shimmer shows.
	local tray = Instance.new("Frame")
	local moving = {}
	local colossal = MistOddsView.sizeWords(tray, "Chance", 18, 7, 1, moving)
	local tiny = MistOddsView.sizeWords(tray, "Chance", 18, 1, 1, moving)
	local band = moving[1] and moving[1].gradient.Color.Keypoints
	tray:Destroy()
	check(#moving == 1 and moving[1].kind == "shimmer" and band ~= nil and band[1].Value ~= band[3].Value
			and colossal.Text == MistOddsView.percent(EnchantedMistData.sizeChance(7))
			and tiny.Text == MistOddsView.percent(EnchantedMistData.sizeChance(1))
			and string.find(reels, "MistOddsView.sizeWords(chip, \"Chance\", 18, tier, Z + 6, moving)", 1, true) ~= nil
			and select(2, string.gsub(reels, "stopMoving = MistOddsView.animate%(moving%)", "")) == 2,
		"the size cards' % at their top, Colossal's 0.52% shimmering visibly; both reels' words move",
		string.format("moving %d", #moving))
	-- Mosskeeper's bar: the shell itself at its end (a live render, never the
	-- stand-in picture) and a solid track (the owner's rule, 2026-10-10).
	local barView = strip(Scripts:WaitForChild("MosskeeperView").Source)
	check(string.find(barView, "SeedData.Get(EnchantedMistData.Shell.Id or \"\")", 1, true) ~= nil
			and string.find(barView, "pcall(CreatureModel.Build, shell, 1, CreatureModel.STAGE_POD, CFrame.new(), podIcon)",
				1, true) ~= nil
			and string.find(barView, "local podIcon = Instance.new(\"ViewportFrame\")", 1, true) ~= nil
			and not string.find(barView, "Icons.pod1", 1, true)
			and string.find(barView, "track.BackgroundTransparency = 0\n", 1, true) ~= nil
			and string.find(barView, "trackStroke.Color = BAR.TrackEdge", 1, true) ~= nil
			and typeof(EnchantedMistConfig.Mosskeeper.Bar.TrackEdge) == "Color3",
		"the bar ends on the Mysterious Pod itself, live, over a solid edged track")
	check(EnchantedMistConfig.Enabled == true, "the event itself on (the owner, 2026-10-12)")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMysteryPodSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
