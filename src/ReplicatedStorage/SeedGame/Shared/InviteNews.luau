--!strict
-- Steal a Seed :: InviteNews (client, 2026-10-06)
--
-- What InviteService tells THIS player about Invite a Friend -- a friend's
-- join counted ("joined"), a form given ("granted"), the Bag too full for one
-- ("full"), and, to an invited friend, WELCOME! ("welcome") -- heard once here
-- and handed to every script that subscribes: InviteUI (the notices and their
-- sounds) and InviteRewardUI (the reward popup).
--
-- NOTHING SAID BEFORE A SCRIPT LISTENED IS LOST. The first subscriber connects
-- to GameEvent and tells the server READY (GameConfig.InviteRewards
-- .ReadyAction); the server holds what it said before that -- a join's
-- WELCOME!, an inbox's +1, a form given while the profile loaded -- and sends
-- it then. Everything heard is kept for the session and replayed, in order, to
-- a script that subscribes later, so the two scripts may start in either order.
--
-- It sends nothing else and decides nothing: the payloads are the server's.

local Players = game:GetService("Players")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local CONFIG = GameConfig.InviteRewards

local InviteNews = {}

export type Payload = { [string]: any }

local heard: { Payload } = {}
local listeners: { (Payload) -> () } = {}
local started = false

local function start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local seedGame = game:GetService("ReplicatedStorage"):WaitForChild("SeedGame")
		local remotes = seedGame:WaitForChild("Remotes", 30)
		local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 30) else nil
		if not (found and found:IsA("RemoteEvent")) then
			warn("[Seed/InviteNews] No GameEvent remote; invite notices will not arrive.")
			return
		end
		local channel = found :: RemoteEvent
		channel.OnClientEvent:Connect(function(action: any, payload: any)
			if action ~= CONFIG.NoticeAction or type(payload) ~= "table" or type(payload.kind) ~= "string" then
				return
			end
			table.insert(heard, payload)
			for _, fn in ipairs(listeners) do
				task.spawn(fn, payload)
			end
		end)
		-- Listening: whatever the server held for this player comes now.
		if Players.LocalPlayer then
			channel:FireServer(CONFIG.ReadyAction)
		end
	end)
end

-- `fn` is called with every payload: those heard already, in order, then each
-- new one as it arrives.
function InviteNews.subscribe(fn: (Payload) -> ())
	for _, payload in ipairs(heard) do
		task.spawn(fn, payload)
	end
	table.insert(listeners, fn)
	start()
end

return InviteNews
