--!nocheck
--==============================================================================
-- Steal a Seed :: WalkModeSpec
--
-- The walk switch, the one function that owns WalkSpeed, and the profile that
-- remembers both. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("WalkModeSpec"))
--
--==============================================================================
-- WHAT IS UNDER TEST IS A PRECEDENCE, NOT A NUMBER
--
-- CarryService.RefreshWalkSpeed is the only writer of WalkSpeed in this game, and
-- it now answers to five things at once: the Speed score, the weight being
-- carried, a mill, a trap, and the walk switch. The ORDER those are applied in is
-- the whole feature:
--
--     rooted           0, and nothing below it is consulted
--     mounted          0, same
--     otherwise        score -> weight -> trap fraction -> min(_, 16) if walking
--
-- So this spec drives that function with a real Humanoid and reads WalkSpeed back.
-- The stand-in is the PROFILE, because the score is the only input that comes from
-- one; everything else is an attribute on the player, which is exactly how the
-- real services set it.
--
-- AND IT PROVES THE NEGATIVE. Turning the switch off must recompute rather than
-- restore: the spec changes the weight WHILE walking, turns the switch off, and
-- checks the answer is the new product rather than the number from before.
--
-- Not here: the button (Play, desktop and touch), and the remote's rate limit.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

local ATTR = GameConfig.Attributes
local CAP = GameConfig.WalkMode.CapStuds

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
	return math.abs(a - b) <= 0.001
end

--==============================================================================
-- 1. THE SWITCH IS A SAVED PREFERENCE, AND AN OLD SAVE IS OFF
--==============================================================================
say("\n-- the profile --")
do
	local fresh = ProfileSchema.Default()
	check(fresh.WalkMode == false, "a new profile walks nowhere: the switch is off",
		tostring(fresh.WalkMode))

	-- 21. FORWARD MIGRATION. A save written before the switch existed has no key.
	local old = ProfileSchema.Sanitise({ Version = 2, Cash = 10, Speed = 100 })
	check(old.WalkMode == false, "a save from before the switch loads with it off",
		tostring(old.WalkMode))
	local on = ProfileSchema.Sanitise({ Version = 2, WalkMode = true })
	check(on.WalkMode == true, "a save with it on keeps it on")
	local junk = ProfileSchema.Sanitise({ Version = 2, WalkMode = "yes please" })
	check(junk.WalkMode == false, "and anything that is not a boolean is off",
		tostring(junk.WalkMode))

	-- 21. AND THE TRAPS SAVE LIKE EVERY OTHER WEAPON.
	local owned = ProfileSchema.Sanitise({
		Version = 2,
		Weapons = {
			bramblejaw_trap = true,
			starlock_trap = true,
			rootwood_bat = true,
			not_a_weapon = true,
		},
		EquippedTrap = "starlock_trap",
		EquippedBat = "rootwood_bat",
	})
	check(owned.Weapons.bramblejaw_trap == true and owned.Weapons.starlock_trap == true,
		"an owned Bramblejaw and an owned Starlock both survive a load")
	check(owned.Weapons.not_a_weapon == nil, "and an id that is not a weapon does not")
	check(owned.EquippedTrap == "starlock_trap" and owned.EquippedBat == "rootwood_bat",
		"one trap and one bat stay equipped together",
		owned.EquippedTrap .. " / " .. owned.EquippedBat)

	-- A trap in the bat slot is refused by category, which is what keeps "one bat
	-- and one trap" true however a profile arrives.
	local crossed = ProfileSchema.Sanitise({
		Version = 2,
		Weapons = { starlock_trap = true },
		EquippedBat = "starlock_trap",
		EquippedTrap = "starlock_trap",
	})
	check(crossed.EquippedBat == "" and crossed.EquippedTrap == "starlock_trap",
		"a trap cannot be equipped as a bat", crossed.EquippedBat)
	local unowned = ProfileSchema.Sanitise({
		Version = 2,
		Weapons = {},
		EquippedTrap = "mirecoil_trap",
	})
	check(unowned.EquippedTrap == "", "and a trap nobody owns cannot be equipped",
		unowned.EquippedTrap)
end

--==============================================================================
-- THE HARNESS: ONE REAL HUMANOID AND A STAND-IN PROFILE
--==============================================================================
local fixture = Instance.new("Folder")
fixture.Name = "WalkModeSpecFixture"
fixture.Parent = Workspace

local profile = { Speed = 0, WalkMode = false }
local PlayerDataService = {
	Get = function()
		return profile
	end,
	WalkModeOf = function()
		return profile.WalkMode == true
	end,
}

local outerRequire = require
local function loadWith(module, siblings)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		if sibling ~= nil then
			return { __standIn = sibling }
		end
		-- Everything this spec does not stand in for is the real module: they all
		-- load in Edit and none of them is consulted by RefreshWalkSpeed.
		return Server:WaitForChild(name)
	end
	local env = setmetatable({
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

local CarryService = nil
local player = nil
local humanoid = nil

local function attributeStore()
	local values = {}
	return values, function(_, key)
		return values[key]
	end, function(_, key, value)
		values[key] = value
	end
end

local function body()
	local values, get, set = attributeStore()
	local character = Instance.new("Model")
	character.Name = "WalkModeBody"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = Vector3.new(4200, 900, 4200)
	root.Anchored = true
	root.Parent = character
	character.PrimaryPart = root
	humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	character.Parent = fixture

	player = {
		Name = "WalkSpec",
		UserId = 5501,
		Parent = Players,
		Character = character,
		GetAttribute = get,
		SetAttribute = set,
		FindFirstChildOfClass = function()
			return nil
		end,
	}
	player.attributes = values
	return player
end

local function speedNow(): number
	CarryService.RefreshWalkSpeed(player)
	return humanoid.WalkSpeed
end

local function run()
	body()
	local ok, err = pcall(function()
		CarryService = loadWith(Server.CarryService, {
			PlayerDataService = PlayerDataService,
		})
	end)
	check(ok, "CarryService loads against a stand-in profile", err)
	if not ok then
		return
	end

	--==========================================================================
	-- 17, 18. THE CAP, AND THE FLOOR IT MUST NOT RAISE
	--==========================================================================
	say("\n-- the cap --")
	profile.Speed = 0
	local slowBase = speedNow()
	check(slowBase > 0, string.format("a player with no Speed score walks at %.1f", slowBase))
	--======================================================================
	-- AND A BEGINNER IS ALREADY AT THE CAP
	--
	-- GameConfig.walkSpeedFor(0) is 16, which is Roblox's own walking speed and
	-- exactly what this switch caps to -- so the feature does nothing at all for a
	-- new player, and that is the correct amount of nothing. It is the reason the
	-- rule is min() and not an assignment.
	--======================================================================
	check(slowBase <= CAP, "which is already at or under the walk cap", slowBase)

	player:SetAttribute(ATTR.WalkMode, true)
	check(near(speedNow(), slowBase), string.format(
		"asking to walk does NOT speed them up: still %.1f, not %d", slowBase, CAP))
	player:SetAttribute(ATTR.WalkMode, nil)

	-- And a player who has earned some Speed.
	profile.Speed = 1e12
	local fast = speedNow()
	check(fast > CAP, string.format("a rich player runs at %.1f", fast))
	player:SetAttribute(ATTR.WalkMode, true)
	check(near(speedNow(), CAP), string.format(
		"and walks at exactly %d with the switch on", CAP), speedNow())

	--==========================================================================
	-- 19. OFF RECOMPUTES, AND DOES NOT RESTORE
	--==========================================================================
	say("\n-- off is a recompute --")
	-- The weight changes WHILE they are walking, which is the case a
	-- capture-and-restore implementation gets wrong: it would hand back `fast`.
	player:SetAttribute(ATTR.CarrySpeedMultiplier, nil)
	local carriedMultiplier = GameConfig.carryMultiplierFor(4000)
	check(carriedMultiplier < 1, "a heavy pod slows a player", carriedMultiplier)
	player:SetAttribute(ATTR.WalkMode, nil)
	local unloaded = speedNow()
	check(near(unloaded, fast), "with the switch off they are back to their own speed",
		string.format("%.2f vs %.2f", unloaded, fast))

	--==========================================================================
	-- 20. AND EVERY OTHER MOVEMENT STATE STILL WINS
	--==========================================================================
	say("\n-- precedence --")
	player:SetAttribute(ATTR.WalkMode, true)
	player:SetAttribute(ATTR.Trapped, true)
	check(near(speedNow(), 0), "a rooted player is at zero, cap or no cap", speedNow())
	player:SetAttribute(ATTR.Trapped, nil)

	player:SetAttribute(ATTR.MillMounted, true)
	check(near(speedNow(), 0), "a mounted player is at zero", speedNow())
	player:SetAttribute(ATTR.MillMounted, nil)

	-- A trap that SLOWS multiplies what they would otherwise be doing, and the cap
	-- is applied after it -- so the lower of the two wins without either being lost.
	player:SetAttribute(ATTR.TrapSlow, 0.35)
	local snared = speedNow()
	check(snared <= CAP, string.format("a snared walker is at or under the cap (%.2f)", snared))
	check(near(snared, math.min(fast * 0.35, CAP)), "which is the lower of the slow and the cap",
		string.format("%.2f vs %.2f", snared, math.min(fast * 0.35, CAP)))
	player:SetAttribute(ATTR.WalkMode, nil)
	local snaredRunning = speedNow()
	check(near(snaredRunning, fast * 0.35), string.format(
		"and with the switch off it is 35%% of their own %.1f = %.2f", fast, snaredRunning))
	player:SetAttribute(ATTR.TrapSlow, nil)

	--==========================================================================
	-- AND IT NEVER TOUCHES WHAT THEY EARNED
	--==========================================================================
	say("\n-- what it does not do --")
	local scoreBefore = profile.Speed
	player:SetAttribute(ATTR.WalkMode, true)
	speedNow()
	player:SetAttribute(ATTR.WalkMode, nil)
	speedNow()
	check(profile.Speed == scoreBefore, "the Speed score is untouched by the switch",
		profile.Speed)

	-- A body that has gone away is not a crash and not a leftover: the function is
	-- a no-op without a humanoid, which is what makes it safe to call on death.
	local dead = player.Character
	player.Character = nil
	local okDead = pcall(CarryService.RefreshWalkSpeed, player)
	check(okDead, "recomputing for a player with no character is harmless")
	player.Character = dead
	player:SetAttribute(ATTR.WalkMode, true)
	check(near(speedNow(), CAP), "and the cap is back the moment a body is", speedNow())
end

local okRun, err = pcall(run)
if not okRun then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

--==============================================================================
-- 22. ONE TOOL PER EQUIPPED WEAPON, AND NO SECOND COPY
--==============================================================================
say("\n-- one bat, one trap, no duplicates --")
do
	local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
	local backpack = Instance.new("Backpack")
	backpack.Parent = fixture

	local shopProfile = {
		Weapons = { rootwood_bat = true, starlock_trap = true },
		EquippedBat = "rootwood_bat",
		EquippedTrap = "starlock_trap",
	}
	local shopPlayer = {
		Name = "ShopSpec",
		UserId = 5502,
		Parent = Players,
		Character = nil,
		FindFirstChildOfClass = function(_, className)
			return if className == "Backpack" then backpack else nil
		end,
	}
	--======================================================================
	-- THE PROFILE, THROUGH THE THREE READS THE SHOP ACTUALLY MAKES
	--
	-- LoadoutOf is the one that matters: EquippedId asks it per category, and
	-- RefreshTools asks EquippedId. Get backs the ownership check.
	--======================================================================
	local ShopData = {
		Get = function()
			return shopProfile
		end,
		LoadoutOf = function(_, category)
			if category == "bat" then
				return shopProfile.EquippedBat
			elseif category == "trap" then
				return shopProfile.EquippedTrap
			end
			return ""
		end,
		SetLoadout = function()
			return true
		end,
		GrantWeapon = function()
			return true
		end,
	}
	local WeaponShopService = nil
	local okLoad, loadErr = pcall(function()
		WeaponShopService = loadWith(Server.WeaponShopService, {
			PlayerDataService = ShopData,
		})
	end)
	check(okLoad, "WeaponShopService loads", loadErr)
	if okLoad then
		local function toolsIn(): ({ [string]: number }, number)
			local byId, total = {}, 0
			for _, child in ipairs(backpack:GetChildren()) do
				if child:IsA("Tool") then
					local id = tostring(child:GetAttribute(WeaponModel.ItemAttribute))
					byId[id] = (byId[id] or 0) + 1
					total += 1
				end
			end
			return byId, total
		end

		WeaponShopService.RefreshTools(shopPlayer)
		local byId, total = toolsIn()
		check(total == 2 and byId.rootwood_bat == 1 and byId.starlock_trap == 1,
			"an equipped bat and an equipped trap build one Tool each", total)

		-- Called again, as a respawn and a profile update both do.
		WeaponShopService.RefreshTools(shopPlayer)
		WeaponShopService.RefreshTools(shopPlayer)
		byId, total = toolsIn()
		check(total == 2 and byId.starlock_trap == 1,
			"and three more refreshes build no second copy", total)

		-- A duplicate that arrives some other way is destroyed rather than kept.
		local sneaky = WeaponModel.BuildTool(WeaponData.Get("starlock_trap"))
		sneaky.Parent = backpack
		WeaponShopService.RefreshTools(shopPlayer)
		byId, total = toolsIn()
		check(total == 2 and byId.starlock_trap == 1,
			"a duplicate Tool is cleared on the next refresh", total)

		-- And swapping traps leaves exactly one trap Tool, the new one.
		shopProfile.Weapons.mirecoil_trap = true
		shopProfile.EquippedTrap = "mirecoil_trap"
		WeaponShopService.RefreshTools(shopPlayer)
		byId, total = toolsIn()
		check(total == 2 and byId.mirecoil_trap == 1 and byId.starlock_trap == nil,
			"swapping traps replaces the Tool rather than adding one", total)
	end
end

fixture:Destroy()

say(string.format("\nWalkModeSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
