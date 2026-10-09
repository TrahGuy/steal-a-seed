--!nocheck
--==============================================================================
-- Steal a Seed :: PlacementCircleSpec
--
-- The owner's placement rule (2026-10-02), for EVERY pod, plant and Secret: an
-- item is placed by its BASE, one small circle the same for all
-- (GameConfig.Plant.BaseCircleStuds), and how far the model reaches -- over other
-- plants, the owner's own fence, gate, signs or mill -- is never a reason to
-- refuse it. The base stays on the owner's own soil; ownership, storage, the
-- item check and refusal-before-consumption stay as they were; no spacing rule
-- takes the footprint's place. It replaced SecretFootprintSpec. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlacementCircleSpec"))
--
-- Not here, verified in Play instead: a real placement overlapping other plants
-- and the fence, the circle on screen, refusals with the item kept, a hatch and
-- a pickup.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local SeedGame = ReplicatedStorage.SeedGame
local Shared = SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local PlantInfo = require(Shared.PlantInfo)
local ActionRefusal = require(Shared.ActionRefusal)
local CreatureModel = require(Shared.CreatureModel)

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
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function count(text, plain)
	local n, at = 0, 1
	while true do
		local s, e = string.find(text, plain, at, true)
		if not s then
			return n
		end
		n += 1
		at = e + 1
	end
end

local PLANT = GameConfig.Plant
local scratch = Instance.new("Folder")
scratch.Name = "ZZPlacementCircleSpec"
scratch.Parent = workspace

local ok, err = pcall(function()
	--==========================================================================
	say("1. One small circle, the same for everything")
	--==========================================================================
	check(PLANT.BaseCircleStuds == 2, "the base circle is 2 studs across", PLANT.BaseCircleStuds)
	check(PLANT.EdgeMarginStuds >= PLANT.BaseCircleStuds / 2,
		string.format("the server's clamp (%.1f studs in from the rim) keeps the WHOLE circle on the soil",
			PLANT.EdgeMarginStuds))
	local placeSrc = sourceOf(Scripts, "PlantPlace")
	check(placeSrc ~= "", "PlantPlace's source is readable")
	check(string.find(placeSrc, "local BASE_CIRCLE = PLANTING.BaseCircleStuds", 1, true) ~= nil
			and string.find(placeSrc, "ghost.Size = Vector3.new(0.12, BASE_CIRCLE, BASE_CIRCLE)", 1, true) ~= nil
			and count(placeSrc, "ghost.Size =") == 1,
		"the preview disc is sized once, from BaseCircleStuds, and never resized for what is in the hands")
	check(string.find(placeSrc, "local function footprint", 1, true) == nil
			and string.find(placeSrc, "PodDiameter", 1, true) == nil and string.find(placeSrc, "FrameHeight", 1, true) == nil,
		"nothing about the model's size reaches the preview")
	check(string.find(placeSrc, "ghost.Color = PlantInfo.SizeColour(species.Id, tier)", 1, true) ~= nil,
		"the disc is tinted by what is in the hands")
	check(PlantInfo.SizeColour("snarlbloom", 1) == GameConfig.RarityColor.Secret
			and PlantInfo.SizeColour("nubkin", 7) == SeedData.ColorForTier(7),
		"a Secret's disc wears its rarity colour, an ordinary item's its weight band -- never a size for a Secret")
	check(string.find(placeSrc, "SecretGhost", 1, true) == nil and string.find(placeSrc, "SecretPlaceArea", 1, true) == nil
			and string.find(placeSrc, "SECRET_", 1, true) == nil,
		"no Secret box, green area, snap or Secret refusal on the client")
	check(count(placeSrc, "RenderStepped:Connect") == 1, "one per-frame hook, as before")

	--==========================================================================
	say("2. Only the base is checked, and only on the owner's own soil")
	--==========================================================================
	local plantSrc = sourceOf(Server, "PlantService")
	local placeAt = string.find(plantSrc, "function PlantService.PlaceAt", 1, true) or 0
	local destroyAt = string.find(plantSrc, "tool:Destroy()", placeAt, true) or 0
	local endAt = string.find(plantSrc, "\nend\n", destroyAt, true) or 0
	local before = if placeAt > 0 and destroyAt > placeAt then string.sub(plantSrc, placeAt, destroyAt - 1) else ""
	local after = if endAt > destroyAt then string.sub(plantSrc, destroyAt, endAt) else ""
	check(before ~= "" and after ~= "", "PlaceAt and the line that consumes the item are found")
	local codes = {}
	for code in string.gmatch(before, 'refuse%(player, "([%u_]+)"%)') do
		codes[code] = true
	end
	for first, second in string.gmatch(before, 'then "([%u_]+)" else "([%u_]+)"') do
		codes[first] = true
		codes[second] = true
	end
	local listed = {}
	for code in pairs(codes) do
		table.insert(listed, code)
	end
	table.sort(listed)
	-- POD since 2026-10-09: pods hatch in the Bag, and are never placed.
	local want = { "BED_FULL", "NO_CHARACTER", "NO_PLOT", "NO_PROFILE", "NO_SOIL", "NO_TOOL", "OUT_OF_RANGE",
		"POD", "UNKNOWN_SPECIES" }
	check(table.concat(listed, ",") == table.concat(want, ","),
		"PlaceAt refuses for the plot, the profile, the soil, the character, the item, reach and room -- nothing else",
		table.concat(listed, ","))
	check(string.find(after, "refuse(", 1, true) == nil,
		"every refusal comes before the item is consumed: nothing is refused once the Tool is gone")
	local plotAt = string.find(before, "local plot = PlotService.PlotOf(player)", 1, true)
	local bedAt = string.find(before, "pickBed(plot, worldPos)", 1, true)
	check(plotAt ~= nil and bedAt ~= nil and plotAt < bedAt,
		"the click is pulled onto a bed of the SENDER's own plot -- never another player's, the road or the hub")
	check(string.find(placeSrc, "instance:IsDescendantOf(plot)", 1, true) ~= nil,
		"the client sends a click only when it lands on the player's own bed")
	check(string.find(plantSrc, "SECRET_", 1, true) == nil and string.find(plantSrc, "Footprint", 1, true) == nil,
		"no footprint or Secret-room check is left in PlantService")
	local secretCodes = 0
	for code in pairs(ActionRefusal.Text) do
		if string.sub(code, 1, 7) == "SECRET_" then
			secretCodes += 1
		end
	end
	check(secretCodes == 0 and ActionRefusal.fromPlacement("SECRET_NEAR") == nil,
		"no Secret-room refusal is left for a toast to show", secretCodes)
	check(Shared:FindFirstChild("SecretFootprint") == nil and GameConfig.Secret.Footprint == nil
			and SeedData.Get("snarlbloom").Footprint == nil and SeedData.Get("petalfawn").PodFootprint == nil,
		"the footprint module, its zones and its measurements are gone")
	local mentions = {}
	for _, root in ipairs({ SeedGame, Server, Scripts }) do
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				local okRead, src = pcall(function()
					return d.Source
				end)
				if okRead and type(src) == "string" and string.find(src, "SecretFootprint", 1, true) then
					table.insert(mentions, d:GetFullName())
				end
			end
		end
	end
	check(#mentions == 0, "no script anywhere still asks SecretFootprint", table.concat(mentions, ", "))

	--==========================================================================
	say("3. A model that reaches past its base is never in anybody's way")
	--==========================================================================
	local function solid(model)
		local n = 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.CanCollide then
				n += 1
			end
		end
		return n
	end
	local built, solidParts = 0, 0
	for _, id in ipairs({ "snarlbloom", "petalfawn", "supernovus", "bellchime", "nubkin" }) do
		local species = SeedData.Get(id)
		if species then
			local tier = if species.Secret then SeedData.SecretTier else SeedData.TierCount
			local plant = CreatureModel.Build(species, tier, CreatureModel.STAGE_GROWN, CFrame.new(0, 0, 0), scratch)
			local pod = CreatureModel.BuildPod(species, tier, CFrame.new(40, 0, 0), scratch)
			solidParts += solid(plant) + solid(pod)
			built += 2
			plant:Destroy()
			pod:Destroy()
		end
	end
	check(built == 10 and solidParts == 0,
		string.format("%d planted builds (both Secrets and the biggest ordinary plants, pods and plants): no part collides",
			built), solidParts)
	-- A PART's CanCollide (".CanCollide"): the Bag hatch's ground probe sets a
	-- RaycastParams' RespectCanCollide, which collides nothing (2026-10-09).
	check(string.find(plantSrc, "%.CanCollide = true") == nil,
		"PlantService never makes a planted part collide")

	--==========================================================================
	say("4. Walkers, the Secret pod's facing, the switch")
	--==========================================================================
	local wanderSrc = sourceOf(Server, "PlantWander")
	check(wanderSrc ~= "" and string.find(wanderSrc, "Blocker", 1, true) == nil
			and string.find(plantSrc, "entry.offset, walkTier, byPlot :: any, entry.id, rng)", 1, true) ~= nil,
		"a walker is never turned away from a Secret: no walls, every walk as it always was")
	check(GameConfig.Secret.PodFacing == math.pi
			and string.find(plantSrc, "then GameConfig.Secret.PodFacing\n\t\telse entry.facing", 1, true) ~= nil
			and string.find(plantSrc, "not hatched then GameConfig.Secret.PodFacing else facingFor(id)", 1, true) ~= nil,
		"a planted Secret pod still stands with its narrow side to the gate (kept; it decides no placement)")
	check(GameConfig.Secret.Enabled == true, "natural Secret spawning is on (the owner, 2026-10-09)")
end)

scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("PlacementCircleSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
