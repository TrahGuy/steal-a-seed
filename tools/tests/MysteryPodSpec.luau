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
	M.TellHatch(P, o, 41)
	check(#told == 1 and told[1].phase == "hatch" and told[1].species == first.Id and told[1].size == rec.Size
			and told[1].seconds == SHELL.ReelSeconds and saves == 1,
		"its owner told the saved creature and size for the card reels, and a save asked for")
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
			and string.find(reels, "StatusText.reducedMotion()", 1, true) ~= nil
			and not string.find(reels, "HatchRollUI", 1, true),
		"the card reels: this family's own, no camera, Reduced Motion lands them at once")
	-- A reel's card stands a creature that exists in its window, as the Odds
	-- page does; one not made yet keeps the dark "???".
	local MistOddsView = require(Shared:WaitForChild("MistOddsView"))
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
			and string.find(reels, "MistOddsView.card(slot, e, Z + 2, CARD_H, moving, fx, if near then views else {})", 1,
				true) ~= nil
			and string.find(reels, "local near = i >= LAND - 4 and i <= LAND + 2", 1, true) ~= nil
			and string.find(reels, "if i == LAND then entryFor(species, payload.rarity)", 1, true) ~= nil
			and string.find(reels, "MistOddsView.drawViews(views)", 1, true) ~= nil,
		"a reel's card draws a creature that exists in its window; one not made yet stays \"???\"",
		string.format("made %s drawn %s dark %s", tostring(made and made.Id), tostring(drawn), tostring(dark)))
	-- The reels' filler: by the odds' own mix (never misstating them), the
	-- answer always at the landing, never two alike side by side.
	local LAND, COUNT = 12, 17
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
		local sizes = MistOddsView.reelItems(15, LAND, sizeAnswer, function()
			return EnchantedMistData.pickSize(sizeRng:NextNumber())
		end, tiers)
		if items[LAND] == answer and sizes[LAND] == sizeAnswer and #items == COUNT and #sizes == 15 then
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
		for i = 1, 15 do
			if i > 1 and sizes[i] == sizes[i - 1] then
				alike += 1
			end
			if i ~= LAND then
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
	check(EnchantedMistConfig.Enabled == false, "the event itself still off")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMysteryPodSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
