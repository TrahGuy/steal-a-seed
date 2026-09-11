--!strict
--==============================================================================
-- Steal a Seed :: DebugTeleportSpec
--
-- DebugService's Teleport {where = "plot"} handed the PLAYER to
-- PlotService.SpawnCFrameFor(plot: Model) and threw "GetPivot is not a valid
-- member of Player", so the action never moved anyone. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("DebugTeleportSpec"))
--
-- The real DebugService handler through DebugService.RunAction, and the REAL
-- SpawnCFrameFor -- only PlotOf is stubbed, to hand back a plot built here -- so
-- passing anything but a plot Model would fail this spec the way it failed live.
--==============================================================================
local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local Server = game:GetService("ServerScriptService").SeedGameServer
local DebugService = require(Server.DebugService)
local PlotService = require(Server.PlotService)

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
fixture.Name = "DebugTeleportSpecFixture"
fixture.Parent = workspace

local body = Instance.new("Model")
body.Name = "SpecTeleporter"
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Anchored = true
root.CanCollide = false
root.Size = Vector3.new(2, 2, 1)
root.CFrame = CFrame.new(0, 900, 0)
root.Parent = body
body.PrimaryPart = root
body.Parent = fixture

local plot = Instance.new("Model")
plot.Name = "Plot_Spec"
local pad = Instance.new("Part")
pad.Name = GameConfig.Plot.SpawnPadName
pad.Anchored = true
pad.Size = Vector3.new(6, 1, 6)
pad.CFrame = CFrame.new(120, 910, -40) * CFrame.Angles(0, math.rad(90), 0)
pad.Parent = plot
plot.PrimaryPart = pad
plot.Parent = fixture

local player: any = {
	Name = "SpecTeleporter",
	UserId = -301,
	Parent = Players,
	Character = body,
}

local realPlotOf = PlotService.PlotOf
-- An untyped alias for the stubs, so no statement has to open with `;(`.
local plots: any = PlotService
local asked: { any } = {}

local ok, err = pcall(function()
	plots.PlotOf = function(who: any): Model?
		table.insert(asked, who)
		return plot
	end

	local reply = DebugService.RunAction(player, "Teleport", { where = "plot" })
	check(reply == "at your plot", "the plot teleport answers \"at your plot\" (" .. tostring(reply) .. ")")
	check(#asked == 1 and asked[1] == player, "it looked the plot up by player")
	local want = PlotService.SpawnCFrameFor(plot) + Vector3.new(0, 4, 0)
	check((root.Position - want.Position).Magnitude < 0.01,
		("the body stands on the spawn pad, 4 studs up (off by %.3f)"):format((root.Position - want.Position).Magnitude))
	check(root.CFrame.LookVector:Dot(want.LookVector) > 0.999, "and faces the way the pad faces")

	plots.PlotOf = function(): Model?
		return nil
	end
	root.CFrame = CFrame.new(0, 900, 0)
	local noPlot = DebugService.RunAction(player, "Teleport", { where = "plot" })
	check(noPlot == "Teleport: no plot", "no plot is an answer, not an error (" .. tostring(noPlot) .. ")")
	check(root.Position.Y > 899.9, "and nobody was moved")

	player.Character = nil
	check(DebugService.RunAction(player, "Teleport", { where = "plot" }) == "Teleport: no character",
		"no body is an answer too")
	player.Character = body

	check(DebugService.RunAction(player, "NoSuchAction", {}) == nil, "an unknown action runs nothing")
end)

plots.PlotOf = realPlotOf
fixture:Destroy()

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("DebugTeleportSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("DebugTeleportSpec: %d passed, 0 failed"):format(pass)
