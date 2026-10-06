--!strict
-- Steal a Seed :: InviteSend (client)
--
-- The one way this game asks Roblox to invite friends (2026-10-06): the hub
-- pedestal's prompt and the INVITE panel's big button both call `prompt`.
-- CanSendGameInviteAsync first; where it says no -- or either call fails, as it
-- does in Studio -- the blocked notice says so ("CAN'T SEND INVITES"). One
-- request at a time. It sends nothing to this game's server and grants
-- nothing: a friend counts when they JOIN (InviteService).
--
-- Never pressed from a tool: it opens Roblox's real invite dialog.

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")

local Shared = script.Parent
local Notice = require(Shared:WaitForChild("Notice"))
local InviteSounds = require(Shared:WaitForChild("InviteSounds"))
local InviteRewards = require(Shared:WaitForChild("InviteRewards"))

local InviteSend = {}

-- The two engine calls, replaceable by InviteAudioSpec (the dialog stubbed:
-- never opened from a test); the game never changes them.
InviteSend.Hooks = {
	canSend = function(player: Player): boolean
		return SocialService:CanSendGameInviteAsync(player)
	end,
	prompt = function(player: Player)
		SocialService:PromptGameInvite(player)
	end,
}

local busy = false

function InviteSend.prompt(): boolean
	if busy then
		return false
	end
	busy = true
	local player = Players.LocalPlayer
	local opened = false
	local ok, can = pcall(InviteSend.Hooks.canSend, player)
	if ok and can == true then
		opened = pcall(InviteSend.Hooks.prompt, player)
	end
	busy = false
	if opened then
		-- The owner's invite_send, only when the dialog was allowed to open.
		InviteSounds.play("send")
	else
		-- CAN'T SEND INVITES: "Invites aren't available on this account".
		local words = InviteRewards.cantSend()
		Notice.post({ kind = words.kind :: any, title = words.title, detail = words.detail, key = words.key })
	end
	return opened
end

return InviteSend
