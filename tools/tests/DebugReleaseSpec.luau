--!strict
-- Edit-only release guard: no client debug UI/remote; server helpers reject live
-- calls, even from the creator. No real player, profile, or DataStore is used.
local Shared = game.ReplicatedStorage.SeedGame.Shared
local Config = require(Shared.GameConfig)
local Server = game.ServerScriptService.SeedGameServer
local Debug = require(Server.DebugService)
local pass = 0
local failures: { string } = {}
local function check(ok: boolean, label: string)
	if ok then pass += 1 else table.insert(failures, label) end
end

check((Config :: any).Debug == nil, "no shipped debug enable/allowlist/shortcut configuration")
check((Config.Remotes :: any).DebugCommand == nil, "bootstrap cannot create DebugCommand")
for key, name in pairs(Config.Remotes) do
	check(name ~= "DebugCommand", "no debug alias in remote manifest: " .. key)
end
check(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("DebugUI") == nil,
	"no debug LocalScript ships")
local clientSource = ""
for _, obj in ipairs(game.StarterPlayer.StarterPlayerScripts:GetDescendants()) do
	if obj:IsA("LuaSourceContainer") then clientSource ..= obj.Source end
end
check(not string.find(clientSource, "SeedDebugToggle", 1, true), "no debug action binding")
check(not string.find(clientSource, 'gui.Name = "SeedDebug"', 1, true), "no debug panel builder")
check(not string.find(Server.DebugService.Source, "OnServerEvent", 1, true),
	"debug service has no remote listener")
local ok, err = pcall(function()
	Debug.Init()
	Debug.Start()
	Debug.Start()
	Debug.Stop()
	Debug.Stop()
end)
check(ok, "repeated diagnostic lifecycle is inert: " .. tostring(err))

-- Load the REAL module with only IsStudio substituted. Dependencies still use
-- this runner's fresh require, but must never be called by a rejected action.
local studio = false
local chunk, compileError = loadstring(Server.DebugService.Source, "=DebugReleaseService")
assert(chunk, compileError)
local env: any = {
	script = Server.DebugService,
	require = require,
	game = setmetatable({ GetService = function(_: any, name: string): any
		if name == "RunService" then
			return { IsStudio = function(): boolean return studio end }
		end
		return game:GetService(name)
	end }, { __index = function(_: any, key: string): any return (game :: any)[key] end }),
}
setmetatable(env, { __index = getfenv(1) })
setfenv(chunk, env)
local live = chunk()
local touched = false
local fakePlayer = setmetatable({}, { __index = function(): any
	touched = true
	error("published diagnostic accessed the player")
end })
for _, action in ipairs({ "SetSpeed", "AddSpeed", "SetCash", "SetPass", "AddCash",
	"SpawnPod", "SetMill", "SetPlotTier", "Teleport", "RestockNests", "ResetParents",
	"WakeNearest", "ForceGuardianRoll", "ClearBag", "SellBag", "DropCarry", "Snapshot" }) do
	local accepted, result = pcall(live.RunAction, fakePlayer, action, {})
	check(accepted and result == nil, "published server refuses " .. action)
end
check(not touched, "live rejection happens before touching a player/profile")
studio = true
check(live.RunAction({ Character = nil }, "Teleport", { where = "plot" }) == "Teleport: no character",
	"Studio server helper remains reachable for existing specs")

return ("DebugReleaseSpec: %d passed, %d failed%s"):format(pass, #failures,
	if #failures > 0 then "\n" .. table.concat(failures, "\n") else "")
