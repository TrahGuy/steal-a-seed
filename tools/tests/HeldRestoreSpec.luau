--!strict
--==============================================================================
-- Steal a Seed :: HeldRestoreSpec
--
-- Two ways the held-plant save was erased, and the rule that now stops both:
--
--   JOIN     (9a007b6) the profile arrived after restoreHeld's old 20 s cap, the
--            plants were never rebuilt, and the next Backpack change saved an
--            empty Held list.
--   RESPAWN  a death, reset or LoadCharacter destroys the Backpack and the body
--            with their Tools; the new empty Backpack and the new body both asked
--            for a snapshot while the gate was open, and saved nothing.
--
-- Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("HeldRestoreSpec"))
--
-- The real CarryService, fresh-required. PlayerDataService's IsReady / Get /
-- SetHeld are replaced on the SAME module instance CarryService calls. Respawns
-- are played through CarryService's own watchers (WatchHeld) with stand-in
-- players whose ChildAdded / CharacterAdded / CharacterRemoving are real signals
-- and whose Backpack and body are real instances, destroyed the way the engine
-- destroys them. Restored plants are real Tools from the real builders.
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

-- A player with a Backpack and no body, for the join scenarios.
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

-- A player who can die: real signals, and a Backpack and body the spec swaps.
local function living(name: string, userId: number): any
	local childAdded = Instance.new("BindableEvent")
	local characterAdded = Instance.new("BindableEvent")
	local characterRemoving = Instance.new("BindableEvent")
	local attrs: { [string]: any } = {}
	local p: any = {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = nil,
		ChildAdded = childAdded.Event,
		CharacterAdded = characterAdded.Event,
		CharacterRemoving = characterRemoving.Event,
		_backpack = nil,
		_fire = { childAdded = childAdded, characterAdded = characterAdded, characterRemoving = characterRemoving },
	}
	function p.SetAttribute(_, k: string, v: any)
		attrs[k] = v
	end
	function p.GetAttribute(_, k: string): any
		return attrs[k]
	end
	function p.FindFirstChildOfClass(self: any, className: string): any
		local backpack = self._backpack
		if className == "Backpack" and backpack and backpack.Parent then
			return backpack
		end
		return nil
	end
	return p
end

local function newBackpack(p: any, announce: boolean): Backpack
	local backpack = Instance.new("Backpack")
	backpack.Parent = fixture
	p._backpack = backpack
	if announce then
		p._fire.childAdded:Fire(backpack)
	end
	return backpack
end

local function newBody(p: any, announce: boolean): Model
	local body = Instance.new("Model")
	body.Name = p.Name .. "Body"
	body.Parent = fixture
	p.Character = body
	if announce then
		p._fire.characterAdded:Fire(body)
	end
	return body
end

local function plantsIn(container: Instance?): number
	local n = 0
	if container then
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("SpeciesId") then
				n += 1
			end
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

local function smallestWrite(name: string, since: number?): number
	local smallest = math.huge
	for i, w in ipairs(writes) do
		if w.who == name and i > (since or 0) then
			smallest = math.min(smallest, w.rows)
		end
	end
	return smallest
end

-- Every step of a teardown is followed by an attempt to record, the way stray
-- deferred syncs land in a real one.
local function step(p: any, fn: () -> ())
	fn()
	CarryService.SyncHeldNow(p)
	task.wait(0.05)
	CarryService.SyncHeldNow(p)
end

-- Alive, armed, holding the saved plants. Returns the Backpack and body.
local function spawnWith(name: string, userId: number, held: { any }): (any, Backpack, Model)
	local p = living(name, userId)
	profiles[p] = { Held = table.clone(held) }
	ready[p] = true
	local backpack = newBackpack(p, false)
	local body = newBody(p, false)
	CarryService.WatchHeld(p)
	CarryService.RestoreHeld(p)
	task.wait(0.5)
	return p, backpack, body
end

local ok, err = pcall(function()
	--== 1. JOIN: A SLOW LOAD, AND THE BACKPACK CHANGING MEANWHILE ==============
	local slow, slowPack = stand("SlowLoad", -201)
	profiles[slow] = { Held = table.clone(NINE) }
	CarryService.RestoreHeld(slow)
	check(not CarryService.IsHeldRestored(slow), "restore waits while the profile is still loading")
	local bat = Instance.new("Tool")
	bat.Name = "Rootwood Bat"
	bat.Parent = slowPack
	CarryService.SyncHeldNow(slow)
	task.wait(1.2)
	CarryService.SyncHeldNow(slow)
	check(#writesFor("SlowLoad") == 0, "join: no Held write at all before the restore ran")
	ready[slow] = true
	task.wait(0.8)
	check(CarryService.IsHeldRestored(slow), "join: the restore completes once the profile arrives")
	check(plantsIn(slowPack) == #NINE, ("join: all nine saved plants were rebuilt (%d)"):format(plantsIn(slowPack)))
	check(#writesFor("SlowLoad") >= 1 and smallestWrite("SlowLoad") == #NINE,
		"join: every write carried all nine rows")

	--== 2. JOIN: PATIENCE RUNS OUT, AND STILL NOTHING IS OVERWRITTEN ===========
	CarryService.HeldRestorePatience = 0.5
	local late, latePack = stand("NeverInTime", -202)
	profiles[late] = { Held = table.clone(NINE) }
	CarryService.RestoreHeld(late)
	task.wait(1.1)
	ready[late] = true
	CarryService.SyncHeldNow(late)
	task.wait(0.3)
	check(not CarryService.IsHeldRestored(late), "join: a restore that gave up leaves the gate closed")
	check(#writesFor("NeverInTime") == 0 and #profiles[late].Held == #NINE,
		"join: and the saved bag is untouched however the Backpack changes")
	check(plantsIn(latePack) == 0, "join: nothing was half-restored")
	CarryService.HeldRestorePatience = patience

	--== 3. JOIN: REPEATED CALLS BUILD NOTHING TWICE ============================
	local twice, twicePack = stand("CalledTwice", -203)
	profiles[twice] = { Held = { NINE[1], NINE[8] } }
	ready[twice] = true
	CarryService.RestoreHeld(twice)
	CarryService.RestoreHeld(twice)
	task.wait(0.6)
	CarryService.RestoreHeld(twice)
	task.wait(0.3)
	check(plantsIn(twicePack) == 2, ("join: a repeated call builds nothing twice (%d)"):format(plantsIn(twicePack)))

	--== 4. JOIN: AN EMPTY SAVE STILL OPENS THE GATE ============================
	local fresh, freshPack = stand("NewPlayer", -204)
	profiles[fresh] = { Held = {} }
	ready[fresh] = true
	CarryService.RestoreHeld(fresh)
	task.wait(0.5)
	check(CarryService.IsHeldRestored(fresh), "join: a player with nothing saved can start recording")
	local banked = Instance.new("Tool")
	banked.Name = "???"
	banked:SetAttribute("SpeciesId", "nubkin")
	banked:SetAttribute("CarryingKg", 2)
	banked.Parent = freshPack
	CarryService.SyncHeldNow(fresh)
	local freshWrites = writesFor("NewPlayer")
	check(#freshWrites >= 1 and freshWrites[#freshWrites] == 1, "join: and what they bank next is recorded")

	--== 5. JOIN: LEAVING MID-LOAD ==============================================
	local gone, gonePack = stand("LeftEarly", -205)
	profiles[gone] = { Held = table.clone(NINE) }
	CarryService.RestoreHeld(gone)
	task.wait(0.4)
	gone.Parent = nil
	ready[gone] = true
	task.wait(0.6)
	check(not CarryService.IsHeldRestored(gone) and plantsIn(gonePack) == 0 and #writesFor("LeftEarly") == 0,
		"join: a player who left mid-load gets no restore and no write")

	--== 6. RESPAWN, IN THE ENGINE'S ORDER, WITH A PLANT IN HAND ================
	do
		local p, pack, body = spawnWith("DiesHolding", -206, NINE)
		check(CarryService.IsHeldRestored(p) and plantsIn(pack) == #NINE, "respawn: alive, armed, nine in the bag")
		-- Equip one: it moves into the body, and the snapshot still counts nine.
		local held = pack:FindFirstChildWhichIsA("Tool") :: Tool
		held.Parent = body
		task.wait(0.2)
		check(smallestWrite("DiesHolding") == #NINE, "respawn: equipping one still records nine")
		local mark = #writes

		step(p, function() p._fire.characterRemoving:Fire(body) end)
		check(not CarryService.IsHeldRestored(p), "respawn: CharacterRemoving disarms")
		step(p, function()
			p.Character = nil
			body:Destroy()
		end)
		step(p, function() pack:Destroy() end)
		local newPack = newBackpack(p, false)
		step(p, function() p._fire.childAdded:Fire(newPack) end)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		task.wait(0.6)

		check(smallestWrite("DiesHolding", mark) == #NINE,
			("respawn: no write after the death carried fewer than nine rows (smallest %s)"):format(
				tostring(smallestWrite("DiesHolding", mark))))
		check(#writes > mark, "respawn: the rebuild recorded the bag again")
		check(plantsIn(newPack) == #NINE, ("respawn: all nine are back, the held one included (%d)"):format(plantsIn(newPack)))
		check(CarryService.IsHeldRestored(p), "respawn: armed again for the new Backpack and body")
		check(#profiles[p].Held == #NINE, "respawn: the save still lists nine")
	end

	--== 7. RESPAWN, WITH THE NEW BACKPACK ANNOUNCED BEFORE ANYTHING ELSE =======
	do
		local p, pack, body = spawnWith("BackpackFirst", -207, NINE)
		local mark = #writes
		local newPack = newBackpack(p, false)
		step(p, function() p._fire.childAdded:Fire(newPack) end)
		step(p, function() pack:Destroy() end)
		step(p, function() p._fire.characterRemoving:Fire(body) end)
		step(p, function()
			p.Character = nil
			body:Destroy()
		end)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		task.wait(0.6)
		check(smallestWrite("BackpackFirst", mark) == #NINE and plantsIn(newPack) == #NINE,
			("backpack first: nothing shrank and nine came back (%d)"):format(plantsIn(newPack)))
	end

	--== 8. RESPAWN, WITH CharacterRemoving NEVER HEARD =========================
	do
		local p, pack, body = spawnWith("NoRemoving", -208, NINE)
		local mark = #writes
		step(p, function()
			p.Character = nil
			body:Destroy()
		end)
		step(p, function() pack:Destroy() end)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		local newPack = newBackpack(p, false)
		step(p, function() p._fire.childAdded:Fire(newPack) end)
		task.wait(0.6)
		check(smallestWrite("NoRemoving", mark) == #NINE and plantsIn(newPack) == #NINE,
			("no CharacterRemoving: the pair check alone held, nine came back (%d)"):format(plantsIn(newPack)))
	end

	--== 9. A NEW BODY THAT KEPT ITS TOOLS BUILDS NOTHING =======================
	do
		local p, pack, body = spawnWith("KeptTools", -209, NINE)
		step(p, function() p._fire.characterRemoving:Fire(body) end)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		task.wait(0.6)
		check(plantsIn(pack) == #NINE and CarryService.IsHeldRestored(p),
			("kept tools: no duplicates, re-armed (%d)"):format(plantsIn(pack)))
	end

	--== 10. SOME SURVIVED: ONLY THE MISSING ONES ARE BUILT =====================
	do
		local p, pack, body = spawnWith("PartlyKept", -210, NINE)
		step(p, function() p._fire.characterRemoving:Fire(body) end)
		local removed = 0
		for _, t in ipairs(pack:GetChildren()) do
			if removed < 4 and t:IsA("Tool") then
				t:Destroy()
				removed += 1
			end
		end
		CarryService.SyncHeldNow(p)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		task.wait(0.6)
		check(plantsIn(pack) == #NINE, ("partly kept: the four lost in the teardown were rebuilt (%d)"):format(plantsIn(pack)))
	end

	--== 11. A PLANT PLANTED OR SOLD WHILE ALIVE DOES NOT COME BACK =============
	do
		local p, pack, body = spawnWith("SoldOne", -211, NINE)
		local sold = pack:FindFirstChildWhichIsA("Tool") :: Tool
		sold:Destroy()
		CarryService.SyncHeldNow(p)
		check(#profiles[p].Held == #NINE - 1, "alive: selling one records eight")
		step(p, function() p._fire.characterRemoving:Fire(body) end)
		step(p, function()
			p.Character = nil
			body:Destroy()
		end)
		step(p, function() pack:Destroy() end)
		local newPack = newBackpack(p, false)
		step(p, function() p._fire.childAdded:Fire(newPack) end)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		task.wait(0.6)
		check(plantsIn(newPack) == #NINE - 1 and #profiles[p].Held == #NINE - 1,
			("sold: eight come back, not nine (%d)"):format(plantsIn(newPack)))
	end

	--== 12. FreezeHeld, THE LoadCharacter PATH =================================
	do
		local p, pack, body = spawnWith("Reloaded", -212, NINE)
		local before = #writes
		CarryService.FreezeHeld(p)
		check(#writes == before + 1 and writes[#writes].rows == #NINE, "freeze: one last snapshot of nine")
		check(not CarryService.IsHeldRestored(p), "freeze: then disarmed")
		local mark = #writes
		step(p, function()
			p.Character = nil
			body:Destroy()
		end)
		step(p, function() pack:Destroy() end)
		local newPack = newBackpack(p, false)
		step(p, function() p._fire.childAdded:Fire(newPack) end)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		task.wait(0.6)
		check(smallestWrite("Reloaded", mark) == #NINE and plantsIn(newPack) == #NINE,
			("freeze: the swap recorded nothing smaller and nine came back (%d)"):format(plantsIn(newPack)))
	end

	--== 13. DYING WHILE THE JOIN LOAD IS STILL RUNNING =========================
	do
		local p = living("DiesWhileLoading", -213)
		profiles[p] = { Held = table.clone(NINE) }
		local pack = newBackpack(p, false)
		local body = newBody(p, false)
		CarryService.WatchHeld(p)
		CarryService.RestoreHeld(p)
		task.wait(0.3)
		step(p, function() p._fire.characterRemoving:Fire(body) end)
		step(p, function()
			p.Character = nil
			body:Destroy()
		end)
		step(p, function() pack:Destroy() end)
		local newPack = newBackpack(p, false)
		step(p, function() p._fire.childAdded:Fire(newPack) end)
		local newBodyModel = newBody(p, false)
		step(p, function() p._fire.characterAdded:Fire(newBodyModel) end)
		check(#writesFor("DiesWhileLoading") == 0, "load + death: nothing recorded before the profile")
		ready[p] = true
		task.wait(1.0)
		check(plantsIn(newPack) == #NINE and CarryService.IsHeldRestored(p) and smallestWrite("DiesWhileLoading") == #NINE,
			("load + death: nine built once, into the new Backpack (%d)"):format(plantsIn(newPack)))
	end
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
