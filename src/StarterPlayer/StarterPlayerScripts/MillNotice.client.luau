--!strict
-- Steal a Seed :: MillNotice
--
--==============================================================================
-- ONE NOTICE, ONCE: "Your Overclock became <tier name>!" (2026-10-06)
--
-- Overclock is history (GameConfig). A save that still held overclock levels
-- became a mill on its first load after (ProfileSchema.convertOverclock), and
-- PlayerDataService marks the player with the tier it became. This says so,
-- once a session, as soon as the notice stack is up: posts before
-- Notice.ready() are dropped, so it waits for it -- fifteen seconds at most, as
-- the invite notices do.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))

local player = Players.LocalPlayer
local ATTR = GameConfig.Attributes.MillOverclockBecame
local told = false

local function tell()
	if told then
		return
	end
	local tier = tonumber(player:GetAttribute(ATTR))
	local spec = if tier then GameConfig.Mill.Tiers[tier] else nil
	if not spec then
		return
	end
	told = true
	local waited = 0
	while not Notice.ready() and waited < 15 do
		waited += task.wait(0.25)
	end
	Notice.post({
		kind = "info",
		title = string.format("Your Overclock became %s!", spec.name),
		key = "MillOverclockBecame",
	})
end

player:GetAttributeChangedSignal(ATTR):Connect(function()
	task.spawn(tell)
end)
task.spawn(tell)
