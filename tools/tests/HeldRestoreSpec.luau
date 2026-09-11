--!strict
--==============================================================================
-- Steal a Seed :: HeldRestoreSpec
--
-- The join-time race that erased a real bag of nine plants on 2026-09-11: the
-- profile arrived after restoreHeld's old 20 s cap, the plants were never
-- rebuilt, and the next Backpack change saved an empty Held list. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HeldRestoreSpec"))
--
-- The real CarryService, fresh-required. PlayerDataService's IsReady / Get /
-- SetHeld are replaced on the SAME module instance CarryService calls, so the
-- load can be made slow, late or absent on demand. Stand-in players carry a real
-- Backpack, so restored plants are real Tools built by the real builders.
--==============================================================================
local Players = game:GetService("Players")
local Server = game:GetService("ServerScriptService").SeedGameServer
local CarryService = require(Server.CarryService)
local PlayerDataService = require(Server.PlayerDataService)

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string)
	if ok then
		pass += 1
	else
		table.insert(fails, label)
	end
end

local fixture = Instance.new("Folder")
fixture.Name = "HeldRestoreSpecFixture"
fixture.Parent = workspace

local function stand(name: string, userId: number): (any, Backpack)
	local backpack = Instance.new("Backpack")
	backpack.Parent = fixture
	local attrs: { [string]: any } = {}
	local p: any = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = nil,
	}
	function p.SetAttribute(_, k: string, v: any)
		attrs[k] = v
	end
	function p.GetAttribute(_, k: string): any
		return attrs[k]
	end
	function p.FindFirstChildOfClass(_, className: string): any
		if className == "Backpack" and backpack.Parent then
			return backpack
		end
		return nil
	end
	return p, backpack
end

local function plantsIn(backpack: Backpack): number
	local n = 0
	for _, t in ipairs(backpack:GetChildren()) do
		if t:IsA("Tool") and t:GetAttribute("SpeciesId") then
			n += 1
		end
	end
	return n
end

local NINE = {
	{ Id = "nubkin", Tier = 1, Hatched = true }, { Id = "nubkin", Tier = 1, Hatched = true },
	{ Id = "nubkin", Tier = 1, Hatched = true }, { Id = "nubkin", Tier = 1, Hatched = true },
	{ Id = "nubkin", Tier = 5, Hatched = true }, { Id = "nubkin", Tier = 5, Hatched = true },
	{ Id = "nubkin", Tier = 3, Hatched = true }, { Id = "novaorb", Tier = 4, Hatched = true },
	{ Id = "nubkin", Tier = 1, Hatched = true },
}

local real = {
	IsReady = PlayerDataService.IsReady,
	Get = PlayerDataService.Get,
	SetHeld = PlayerDataService.SetHeld,
}
local patience = CarryService.HeldRestorePatience
local ready: { [any]: boolean } = {}
local profiles: { [any]: any } = {}
local writes: { { who: string, rows: number } } = {}

;(PlayerDataService :: any).IsReady = function(p: any): boolean
	return ready[p] == true
end
;(PlayerDataService :: any).Get = function(p: any): any
	return if ready[p] then profiles[p] else nil
end
;(PlayerDataService :: any).SetHeld = function(p: any, rows: { any }): boolean
	table.insert(writes, { who = p.Name, rows = #rows })
	if profiles[p] then
		profiles[p].Held = rows
	end
	return true
end

local function writesFor(name: string): { number }
	local out = {}
	for _, w in ipairs(writes) do
		if w.who == name then
			table.insert(out, w.rows)
		end
	end
	return out
end

local ok, err = pcall(function()
	--== 1. THE INCIDENT: A SLOW LOAD, AND THE BACKPACK CHANGING MEANWHILE ======
	local slow, slowPack = stand("SlowLoad", -201)
	profiles[slow] = { Held = table.clone(NINE) }
	CarryService.RestoreHeld(slow)
	check(not CarryService.IsHeldRestored(slow), "restore waits while the profile is still loading")

	-- What happened live: WeaponShopService hands out the bat, the Backpack
	-- changes, a snapshot is requested -- before a single plant exists.
	local bat = Instance.new("Tool")
	bat.Name = "Rootwood Bat"
	bat.Parent = slowPack
	CarryService.SyncHeldNow(slow)
	task.wait(1.2)
	CarryService.SyncHeldNow(slow)
	check(#writesFor("SlowLoad") == 0, "no Held write at all before the restore ran")

	ready[slow] = true
	task.wait(0.8)
	check(CarryService.IsHeldRestored(slow), "the restore completes once the profile arrives")
	check(plantsIn(slowPack) == #NINE, ("all nine saved plants were rebuilt (%d)"):format(plantsIn(slowPack)))
	local slowWrites = writesFor("SlowLoad")
	local smallest = math.huge
	for _, rows in ipairs(slowWrites) do
		smallest = math.min(smallest, rows)
	end
	check(#slowWrites >= 1 and smallest == #NINE,
		("every write carried all nine rows (writes %d, smallest %s)"):format(#slowWrites, tostring(smallest)))

	--== 2. PATIENCE RUNS OUT: STILL NOTHING IS OVERWRITTEN =====================
	CarryService.HeldRestorePatience = 0.5
	local late, latePack = stand("NeverInTime", -202)
	profiles[late] = { Held = table.clone(NINE) }
	CarryService.RestoreHeld(late)
	task.wait(1.1)
	ready[late] = true
	CarryService.SyncHeldNow(late)
	task.wait(0.3)
	check(not CarryService.IsHeldRestored(late), "a restore that gave up leaves the gate closed")
	check(#writesFor("NeverInTime") == 0 and #profiles[late].Held == #NINE,
		"and the saved bag is untouched however the Backpack changes")
	check(plantsIn(latePack) == 0, "nothing was half-restored")
	CarryService.HeldRestorePatience = patience

	--== 3. ONCE PER PLAYER =====================================================
	local twice, twicePack = stand("CalledTwice", -203)
	profiles[twice] = { Held = { NINE[1], NINE[8] } }
	ready[twice] = true
	CarryService.RestoreHeld(twice)
	CarryService.RestoreHeld(twice)
	task.wait(0.6)
	CarryService.RestoreHeld(twice)
	task.wait(0.3)
	check(plantsIn(twicePack) == 2, ("a repeated call builds nothing twice (%d)"):format(plantsIn(twicePack)))

	--== 4. AN EMPTY SAVE STILL OPENS THE GATE ==================================
	local fresh, freshPack = stand("NewPlayer", -204)
	profiles[fresh] = { Held = {} }
	ready[fresh] = true
	CarryService.RestoreHeld(fresh)
	task.wait(0.5)
	check(CarryService.IsHeldRestored(fresh), "a player with nothing saved can start recording")
	local banked = Instance.new("Tool")
	banked.Name = "???"
	banked:SetAttribute("SpeciesId", "nubkin")
	banked:SetAttribute("CarryingKg", 2)
	banked.Parent = freshPack
	CarryService.SyncHeldNow(fresh)
	local freshWrites = writesFor("NewPlayer")
	check(#freshWrites >= 1 and freshWrites[#freshWrites] == 1, "and what they bank next is recorded")

	--== 5. LEAVING MID-LOAD ====================================================
	local gone, gonePack = stand("LeftEarly", -205)
	profiles[gone] = { Held = table.clone(NINE) }
	CarryService.RestoreHeld(gone)
	task.wait(0.4)
	gone.Parent = nil
	ready[gone] = true
	task.wait(0.6)
	check(not CarryService.IsHeldRestored(gone) and plantsIn(gonePack) == 0 and #writesFor("LeftEarly") == 0,
		"a player who left mid-load gets no restore and no write")
end)

;(PlayerDataService :: any).IsReady = real.IsReady
;(PlayerDataService :: any).Get = real.Get
;(PlayerDataService :: any).SetHeld = real.SetHeld
CarryService.HeldRestorePatience = patience
fixture:Destroy()

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("HeldRestoreSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("HeldRestoreSpec: %d passed, 0 failed"):format(pass)
