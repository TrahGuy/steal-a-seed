--!strict
--==============================================================================
-- Steal a Seed :: LeaderstatsSpec
--
-- The player list's two columns -- Speed, then Cash -- spelled by
-- GameConfig.compact and kept in step with the profile. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("LeaderstatsSpec"))
--
-- The real PlayerDataService, fresh-required, driven through its real join and
-- leave handlers (Join / Leave) and its real AddCash and AddSpeed. SaveService's
-- Load, Save and Forget and PlotService.SetDesiredLevel are stubbed on the shared
-- module tables, so nothing reaches a DataStore or a plot.
--
-- A Player cannot be created in Edit ("lacking capability WritePlayer"), so the
-- player is a stand-in table, and MountStats is spied to mount the real folder on
-- a stand-in Folder. MountStats is also called straight, on a Folder of its own.
--
-- Not here, verified in Play instead: the columns in the real player list.
--==============================================================================
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local Server = game:GetService("ServerScriptService").SeedGameServer
local SaveService = require(Server.SaveService)
local PlotService = require(Server.PlotService)
local ProfileSchema = require(Server.ProfileSchema)
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
fixture.Name = "LeaderstatsSpecFixture"
fixture.Parent = ServerStorage

local saves: any = SaveService
local plots: any = PlotService
local data: any = PlayerDataService
local real = {
	Load = saves.Load,
	Save = saves.Save,
	Forget = saves.Forget,
	SetDesiredLevel = plots.SetDesiredLevel,
	MountStats = data.MountStats,
}

local answer: { status: string, raw: any } = { status = "ok", raw = nil }
local saved = 0
local kicked = 0
saves.Load = function(_userId: number): (string, any)
	return answer.status, answer.raw
end
saves.Save = function(): boolean
	saved += 1
	return true
end
saves.Forget = function() end
plots.SetDesiredLevel = function() end

local holders: { [any]: Folder } = {}
local mountedFor: { any } = {}
data.MountStats = function(holder: any, profile: any): any
	table.insert(mountedFor, holder)
	return real.MountStats(holders[holder] or holder, profile)
end

local function stand(name: string, userId: number, parent: Instance?): (any, Folder)
	local holder = Instance.new("Folder")
	holder.Name = name
	holder.Parent = fixture
	local characterAdded = Instance.new("BindableEvent")
	characterAdded.Parent = holder
	local attrs: { [string]: any } = {}
	local p: any = {
		Name = name,
		UserId = userId,
		Parent = parent,
		CharacterAdded = characterAdded.Event,
	}
	function p.SetAttribute(_, k: string, v: any)
		attrs[k] = v
	end
	function p.GetAttribute(_, k: string): any
		return attrs[k]
	end
	function p.Kick()
		kicked += 1
	end
	holders[p] = holder
	return p, holder
end

local function columns(holder: Instance): (Folder?, StringValue?, StringValue?)
	local folder = holder:FindFirstChild("leaderstats")
	if not (folder and folder:IsA("Folder")) then
		return nil, nil, nil
	end
	local speed = folder:FindFirstChild("Speed")
	local cash = folder:FindFirstChild("Cash")
	return folder,
		if speed and speed:IsA("StringValue") then speed else nil,
		if cash and cash:IsA("StringValue") then cash else nil
end

local function profileWith(cash: number, speed: number): any
	local raw: any = ProfileSchema.Sanitise(nil)
	raw.Cash = cash
	raw.Speed = speed
	return raw
end

local function valueOf(v: StringValue?): string
	return if v then v.Value else "<none>"
end

local ok, err = pcall(function()
	--== 1. A JOIN MOUNTS BOTH COLUMNS, SPELLED ================================
	answer.status, answer.raw = "ok", profileWith(3427039827, 1.25e12)
	local p1, h1 = stand("Grower", -701, Players)
	data.Join(p1)
	check(data.IsReady(p1), "the stand-in's profile loaded")
	check(mountedFor[1] == p1, "the columns were mounted for the joining player")
	local folder, speed, cash = columns(h1)
	check(folder ~= nil, "a Folder named leaderstats exists")
	check(speed ~= nil and cash ~= nil, "it holds a Speed and a Cash StringValue")
	if folder then
		local kids = folder:GetChildren()
		check(#kids == 2 and kids[1].Name == "Speed" and kids[2].Name == "Cash",
			"exactly two values, Speed first")
	end
	check(valueOf(speed) == "1.25T", "Speed reads 1.25T (got " .. valueOf(speed) .. ")")
	check(valueOf(cash) == "$3.43B", "Cash reads $3.43B (got " .. valueOf(cash) .. ")")
	check(valueOf(speed) == GameConfig.compact(1.25e12), "Speed is GameConfig.compact of the profile")

	--== 2. ADDCASH AND ADDSPEED KEEP THEM IN STEP =============================
	local writes = 0
	if cash then
		cash.Changed:Connect(function()
			writes += 1
		end)
	end
	check(data.AddCash(p1, 10000000) == 3437039827, "AddCash returns the new balance")
	check(valueOf(cash) == "$3.44B", "Cash follows AddCash to $3.44B (got " .. valueOf(cash) .. ")")
	task.wait()
	local afterMove = writes
	data.AddCash(p1, 1)
	task.wait()
	check(valueOf(cash) == "$3.44B" and writes == afterMove and afterMove > 0,
		"a gain too small to change the spelling does not rewrite the value")
	data.AddSpeed(p1, 1e10)
	check(valueOf(speed) == "1.26T", "Speed follows AddSpeed to 1.26T (got " .. valueOf(speed) .. ")")
	data.AddCash(p1, -1e15)
	check(valueOf(cash) == "$0", "a debit past zero clamps and reads $0 (got " .. valueOf(cash) .. ")")
	check(data.AddSpeed(p1, 0 / 0) == nil and valueOf(speed) == "1.26T", "NaN is refused and nothing moves")

	--== 3. NOT LOADED, NO COLUMNS =============================================
	local p2, h2 = stand("Stranger", -702, Players)
	check(data.AddCash(p2, 50) == nil, "AddCash for a player with no profile does nothing")
	data.PublishStats(p2)
	check(h2:FindFirstChild("leaderstats") == nil, "and no columns appear for them")

	--== 4. A TEMPORARY PROFILE STILL SHOWS ITS NUMBERS ========================
	answer.status, answer.raw = "unavailable", nil
	local p3, h3 = stand("Offline", -703, Players)
	data.Join(p3)
	local _, speed3, cash3 = columns(h3)
	local profile3 = data.Get(p3)
	check(profile3 ~= nil and valueOf(cash3) == "$" .. GameConfig.compact(profile3.Cash),
		"a temporary profile mounts Cash too")
	check(profile3 ~= nil and valueOf(speed3) == GameConfig.compact(profile3.Speed),
		"and Speed")

	--== 5. LEFT DURING THE LOAD, OR KICKED: NOTHING MOUNTED ===================
	answer.status, answer.raw = "ok", profileWith(5, 5)
	local p4, h4 = stand("Gone", -704, nil)
	data.Join(p4)
	check(not data.IsReady(p4) and h4:FindFirstChild("leaderstats") == nil,
		"a player who left during the load gets no columns")
	answer.status, answer.raw = "failed", nil
	local p5, h5 = stand("Bounced", -705, Players)
	data.Join(p5)
	check(kicked == 1 and h5:FindFirstChild("leaderstats") == nil,
		"a failed load kicks and mounts nothing")

	--== 6. LEAVING TAKES THE COLUMNS WITH IT ==================================
	local savesBefore = saved
	local folder1 = h1:FindFirstChild("leaderstats")
	data.Leave(p1)
	check(saved == savesBefore + 1, "the leave still saves")
	check(h1:FindFirstChild("leaderstats") == nil and folder1 ~= nil and folder1.Parent == nil,
		"the columns are destroyed on leave")
	check(not data.IsReady(p1), "the profile is gone")
	local okAfter = pcall(data.PublishStats, p1)
	check(okAfter and h1:FindFirstChild("leaderstats") == nil,
		"publishing after the leave neither throws nor mounts again")
	check(data.AddCash(p1, 5) == nil, "AddCash after the leave does nothing")
	data.Leave(p3)
	check(h3:FindFirstChild("leaderstats") == nil, "a temporary profile's columns go on leave too")

	--== 7. MOUNTING TWICE NEVER MAKES TWO =====================================
	local h6 = Instance.new("Folder")
	h6.Parent = fixture
	local stale = Instance.new("Folder")
	stale.Name = "leaderstats"
	stale.Parent = h6
	local mounted = real.MountStats(h6, profileWith(1500, 110))
	local count = 0
	for _, c in ipairs(h6:GetChildren()) do
		if c.Name == "leaderstats" then
			count += 1
		end
	end
	check(count == 1 and stale.Parent == nil, "an older leaderstats folder is replaced, not added to")
	check(mounted.speed.Value == "110" and mounted.cash.Value == "$1.5K",
		"a fresh mount reads 110 and $1.5K")
end)

saves.Load = real.Load
saves.Save = real.Save
saves.Forget = real.Forget
plots.SetDesiredLevel = real.SetDesiredLevel
data.MountStats = real.MountStats
fixture:Destroy()

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("LeaderstatsSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("LeaderstatsSpec: %d passed, 0 failed"):format(pass)
