--!nocheck
--==============================================================================
-- Steal a Seed :: PassBenefitsSpec (2026-10-12, the owner's item 9: the passes)
--
-- The three new Game Passes -- +12 Bag Slots, Faster Hatch, VIP -- in Edit:
--   1. the manifest: the owner's ids and prices, each benefit field, the card's
--      own words and icon; the first product ids never read
--   2. the Shop: every pass on the obsidian card, which shines gold (Pass) and
--      no product shelf wears
--   3. what owned passes are worth (PassService.benefits): x2 and VIP stack to
--      2.2, +12 plant room, 0.75 of a pod's wait, VIP
--   4. a pod's wait (PassService.growSecondsWith): three quarters of the
--      species' own, never a Mysterious Pod's
--   5. on the client: the plant room (GameConfig.bagLimit), the x2 card only at
--      x2 (Pass.BuffAt), the full Bag's count (ActionRefusal.notice)
--   6. the VIP's gold name (VipService.dress), the engine's hidden; and back
--   7. the wiring: every place a pod's wait is stamped and every plant room
--      reads the passes; the publish; the [VIP] chat tag
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PassService = require(Server:WaitForChild("PassService"))
local VipService = require(Server:WaitForChild("VipService"))
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
local function sourceOf(parent, name)
	local s = parent:FindFirstChild(name)
	return if s then s.Source else ""
end
local function has(text, needle)
	return string.find(text, needle, 1, true) ~= nil
end
local function near(a, b)
	return math.abs(a - b) < 1e-9
end

local STORE = GameConfig.Store
local PASS = GameConfig.Pass

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the manifest --")
	--==========================================================================
	local rows = {}
	for _, item in ipairs(STORE.Items.Passes) do
		rows[item.key] = item
	end
	local B, F, V, X = rows.bagslots, rows.fasterhatch, rows.vip, rows.x2money
	check(B and B.pass == 2026034867 and B.robux == 149 and B.kind == "pass" and B.bagSlots == 12,
		"+12 BAG SLOTS: the owner's pass 2026034867 at 149, 12 more plant slots")
	check(F and F.pass == 2026400906 and F.robux == 129 and F.kind == "pass" and near(F.hatchFactor, 0.75),
		"FASTER HATCH: the owner's pass 2026400906 at 129, a pod's wait times 0.75")
	check(V and V.pass == 2025452917 and V.robux == 249 and V.kind == "pass" and V.vip == true
			and near(V.multiplier, 1.1),
		"VIP: the owner's pass 2025452917 at 249, VIP and a 1.1 multiplier")
	check(X and X.pass == 1975418369 and X.multiplier == 2 and X.bagSlots == nil and X.vip == nil,
		"the x2 Money pass as it was")
	local retired = { [3717932585] = true, [3717932381] = true, [3717932216] = true }
	local found = {}
	for _, list in pairs(STORE.Items) do
		for _, item in ipairs(list) do
			for _, field in ipairs({ "product", "pass" }) do
				if retired[tonumber(item[field]) or 0] then
					table.insert(found, item.key)
				end
			end
		end
	end
	check(#found == 0, "the owner's first product ids for them (going off sale) are never read",
		table.concat(found, ", "))
	local icons = STORE.Icons
	check(icons.bagslots == "rbxassetid://115691273223693" and icons.fasterhatch == "rbxassetid://72267498407717"
			and icons.vip == "rbxassetid://126152654716285",
		"each card wears the owner's own icon")

	--==========================================================================
	say("\n-- 2. the Shop --")
	--==========================================================================
	local entries = ShopCatalog.entries("Passes")
	local byKey = {}
	for _, e in ipairs(entries) do
		byKey[e.key] = e
	end
	local allObsidian = #entries == 4
	for _, e in ipairs(entries) do
		if e.studs ~= "obsidian" or e.kind ~= "pass" then
			allObsidian = false
		end
	end
	check(allObsidian, "four pass cards, each a Game Pass on the obsidian card", #entries)
	check(byKey.bagslots and byKey.bagslots.benefit == B.benefit and byKey.bagslots.icon == icons.bagslots
			and byKey.vip.benefit == V.benefit and byKey.vip.detail == V.detail and byKey.vip.icon == icons.vip
			and byKey.fasterhatch.benefit == F.benefit
			and byKey.x2money.benefit == "Permanent \u{00D7}2 plant income" and byKey.x2money.icon == PASS.BuffIcon,
		"each says its own words under its own icon; x2 Money its multiplier")
	local others = {}
	for _, spec in ipairs(STORE.Sections) do
		if spec.id ~= "Passes" and spec.studs == "obsidian" then
			table.insert(others, spec.id)
		end
	end
	local obsidian = GameConfig.BagLook.Studs.obsidian
	local passShine = GameConfig.RarityFX.ShineOnly and GameConfig.RarityFX.ShineOnly.Pass
	check(#others == 0 and obsidian.shine == "Pass" and passShine and #passShine.Shine == 3
			and RarityFX.style("Pass") == nil,
		"a colour no product shelf wears, shining gold (a shine-only look, never a rarity)",
		table.concat(others, ", "))
	local shop = sourceOf(Scripts, "ShopUI")
	check(has(shop, "RarityFX.setShine(shine, if studSpec and studSpec.shine then studSpec.shine else nil)")
			and has(shop, "RarityFX.setActive(h, want)"),
		"ShopUI: a card shines by its studs, only while the Shop is open")

	--==========================================================================
	say("\n-- 3. what owned passes are worth --")
	--==========================================================================
	local none = PassService.benefits({})
	check(none.multiplier == 1 and none.bagSlots == 0 and none.hatchFactor == 1 and none.vip == false,
		"none: the base game")
	local both = PassService.benefits({ X, V })
	check(near(both.multiplier, 2.2) and both.vip == true and both.bagSlots == 0 and both.hatchFactor == 1,
		"x2 Money and VIP stack: 2 x 1.1 = 2.2", both.multiplier)
	local all = PassService.benefits({ X, B, F, V })
	check(near(all.multiplier, 2.2) and all.bagSlots == 12 and near(all.hatchFactor, 0.75) and all.vip,
		"all four: 2.2, 12 more plants, 0.75 of a pod's wait, VIP")

	--==========================================================================
	say("\n-- 4. a pod's wait --")
	--==========================================================================
	local nubkin = SeedData.Get("nubkin")
	local shell = SeedData.Get("mysterypod")
	check(nubkin and near(PassService.growSecondsWith(0.75, nubkin, 4), SeedData.GrowSecondsFor(nubkin, 4) * 0.75)
			and near(PassService.growSecondsWith(1, nubkin, 4), SeedData.GrowSecondsFor(nubkin, 4)),
		"Faster Hatch: three quarters of the species' own wait; without it, the whole")
	check(shell and shell.Mystery == true
			and PassService.growSecondsWith(0.75, shell, 1) == SeedData.GrowSecondsFor(shell, 1),
		"never a Mysterious Pod's: it keeps its fixed wait")

	--==========================================================================
	say("\n-- 5. on the client --")
	--==========================================================================
	local base = GameConfig.Save.MaxHeld
	local function stand(value)
		return { GetAttribute = function(_, name)
			return if name == PASS.BagSlotsAttribute then value else nil
		end }
	end
	check(GameConfig.bagLimit(stand(nil)) == base and GameConfig.bagLimit(stand(base + 12)) == base + 12
			and GameConfig.bagLimit(stand(3)) == base and GameConfig.bagLimit(stand(0 / 0)) == base
			and GameConfig.bagLimit(nil) == base,
		"the plant room shown: the published one, never under Save.MaxHeld")
	local cash = sourceOf(Scripts, "CashUI")
	local hud = sourceOf(Shared, "HudLayout")
	check(PASS.BuffAt == 2 and has(cash, "GameConfig.cashMultiplier(player) >= GameConfig.Pass.BuffAt")
			and has(hud, "GameConfig.cashMultiplier(me) >= GameConfig.Pass.BuffAt"),
		"the x2 card only at x2 and over: VIP's own 1.1 is no x2")
	local full = ActionRefusal.notice("STORAGE_FULL", base + 12)
	local plain = ActionRefusal.notice("STORAGE_FULL", base)
	check(full and string.sub(full.detail, 1, #tostring(base + 12) * 2 + 1)
				== string.format("%d/%d", base + 12, base + 12)
			and plain and plain.detail == ActionRefusal.Notices.STORAGE_FULL.detail,
		"a full Bag says the player's own count", full and full.detail)
	local toast = sourceOf(Scripts, "ActionToastUI")
	check(has(toast, "ActionRefusal.notice(code, GameConfig.bagLimit(Players.LocalPlayer))"),
		"and the toast asks for it")

	--==========================================================================
	say("\n-- 6. the VIP's gold name --")
	--==========================================================================
	local NAME = PASS.VipName
	local character = Instance.new("Model")
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Parent = character
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	local gui = VipService.dress(character, "Nicky", true)
	local label = gui and gui:FindFirstChild("Words")
	check(gui and gui.Parent == head and gui.Name == NAME.Name and label and label.Text == "Nicky"
			and label.TextColor3 == NAME.Colour and label.Font == Enum.Font.LuckiestGuy
			and label:FindFirstChildOfClass("UIStroke") ~= nil
			and humanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None,
		"a VIP: their name in gold over the head, the engine's own hidden")
	local anchored = gui and gui.StudsOffsetWorldSpace == Vector3.new(0, NAME.Rise, 0)
		and gui.SizeOffset == Vector2.new(0, NAME.Drop) and gui.MaxDistance == NAME.MaxDistance
		and gui.AlwaysOnTop == false
	VipService.dress(character, "Nicky", false)
	check(head:FindFirstChild(NAME.Name) == nil
			and humanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.Viewer,
		"no longer a VIP: the gold gone, the engine's name back")
	character:Destroy()
	-- UNDER THE TITLES AT EVERY DISTANCE: the same stud anchor as ADMIN's and
	-- REBIRTH's, so only pixels part them -- a title's bottom over the name's
	-- top by 2 px or more, on a desktop and on a phone (ADMIN at half size
	-- there, REBIRTH at 0.75), raised by its own Lift (the lowest title's).
	local function gap(lift: number, h: number): number
		return (lift * h - h / 2) - (NAME.Drop * NAME.Size.Y + NAME.Size.Y / 2)
	end
	local admin, rebirth = GameConfig.OwnerTitle, GameConfig.Rebirth.Title
	local phone = Vector2.new(800, 400)
	local adminPhone = GameConfig.ownerTitleScale(phone, true)
	local rebirthPhone = GameConfig.rebirthTitleScale(phone, true)
	local alone = GameConfig.ownerTitleLift(false)
	local least = math.min(
		gap(alone, GameConfig.ownerTitleLook(1).box.Y),
		gap(alone, GameConfig.ownerTitleLook(adminPhone).box.Y),
		gap(rebirth.Lift, (GameConfig.rebirthTitleLook(1)).Y),
		gap(rebirth.Lift, (GameConfig.rebirthTitleLook(rebirthPhone)).Y))
	check(anchored and NAME.Rise == admin.Rise and NAME.Rise == rebirth.Rise and adminPhone < 1 and least >= 2,
		"anchored where the titles are, under them by pixels at every distance and on every screen; hidden "
			.. "past 100 studs and behind the world, as the engine's name", string.format("%.1f px at the least", least))
	check(NAME.TextSize <= admin.PhoneTextSize and NAME.Size.Y <= 22,
		"a player name's size (ADMIN's on a phone, measured to match the engine's), not a title's", NAME.TextSize)

	--==========================================================================
	say("\n-- 7. the wiring --")
	--==========================================================================
	local carry = sourceOf(Server, "CarryService")
	check(has(carry, "return SAVE.MaxHeld + (if player then PassService.BagBonus(player) else 0)")
			and has(carry, "if row and (if pod then pods < SAVE.MaxPods else plants < plantLimit) then")
			and has(carry, "end, fresh, limitOf(player, false))")
			and has(carry, "local limit = limitOf(player, pods)")
			and has(carry, "if countKind(kept, not hatched) >= limitOf(player, not hatched) then"),
		"CarryService: every plant room is the player's own (the snapshot, the merge, the room, the record)")
	check(has(carry, "local hatchAt = os.time() + PassService.GrowSeconds(player, species, tier)")
			and has(carry, "os.time() + PassService.GrowSeconds(player, species, size))"),
		"a banked pod's wait and a given pod's: the player's own")
	local plant = sourceOf(Server, "PlantService")
	local _, fits = string.gsub(plant, "GameConfig%.Save%.MaxHeld %+ PassService%.BagBonus%(player%)%) then", "")
	check(has(plant, "else now + PassService.GrowSeconds(player, species, tier),") and fits == 2,
		"PlantService: a planted pod's wait, and the room a garden plan fits in", fits)
	local loadout = sourceOf(Scripts, "LoadoutUI")
	local _, limits = string.gsub(loadout, "GameConfig%.bagLimit%(player%)", "")
	check(limits == 3 and has(loadout, "GameConfig.Pass.BagSlotsAttribute }) do"),
		"the Bag's count and bar are the player's own room, redrawn when it changes", limits)
	local passSrc = sourceOf(Server, "PassService")
	check(has(passSrc, "player:SetAttribute(BAG_ATTRIBUTE, GameConfig.Save.MaxHeld + worth.bagSlots)")
			and has(passSrc, "player:SetAttribute(VIP_ATTRIBUTE, worth.vip)")
			and has(passSrc, "PassService.Changed:Fire(player)"),
		"PassService publishes the room and the VIP flag, and says so")
	local chat = sourceOf(Scripts, "VipChat")
	check(has(chat, "TextChatService.OnIncomingMessage = function(")
			and has(chat, "speaker:GetAttribute(PASS.VipAttribute) == true")
			and has(chat, "props.PrefixText = GameConfig.vipPrefix(message.PrefixText)")
			and GameConfig.vipPrefix("Nicky") == string.format('<font color="%s">[VIP]</font> Nicky', PASS.VipChat.Colour),
		"the [VIP] chat tag: gold, before a VIP speaker's name, in every chat", GameConfig.vipPrefix("Nicky"))

	--==========================================================================
	say("\n-- 8. a pass lost or not yet known --")
	--==========================================================================
	-- Nothing is ever taken for it: a saved plant past the room is kept, given
	-- back its Tool at a join with no room asked, and the room only stops a
	-- new one (a refund, a revoked pass, a check that failed at the join).
	local merge = string.match(carry, "local function mergeHeld(.-)\nend\n") or ""
	local savedLoop = string.match(merge, "ipairs%(saved%)(.-)ipairs%(live%)") or "plantLimit"
	local restore = string.match(carry, "local function restoreOne(.-)\nend\n") or ""
	check(merge ~= "" and not has(savedLoop, "plantLimit") and not has(savedLoop, "MaxHeld")
			and has(restore, "given = CarryService.GiveHatched(player, species, tier, nil, nil, nil, item)")
			and has(carry, "return math.max(limit - count, 0), count, true"),
		"over the room, nothing is dropped or hidden: every saved plant is kept and given back; only adding stops")
	check(has(passSrc, "if answer ~= nil and answer ~= mine[key] then")
			and has(passSrc, "local RETRY_FAILED_SECONDS = 15")
			and has(passSrc, "task.delay(RETRY_FAILED_SECONDS, function()")
			and has(passSrc, "if failed and not retrying[player] then"),
		"a failed check never clears an owned pass, and is asked again in 15 s, not 90")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nPassBenefitsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
