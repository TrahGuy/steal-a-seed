--!strict
--==============================================================================
-- Steal a Seed :: VipChat (2026-10-12, the owner's item 9: the VIP pass)
--
-- A VIP's chat messages carry a gold [VIP] before their name, in every
-- player's chat window: TextChatService.OnIncomingMessage, keyed on the Vip
-- attribute PassService publishes on the speaker (GameConfig.Pass.VipChat's
-- words and colour). Presentation only: the attribute is the server's.
--
-- The one OnIncomingMessage in this project: assigning it anywhere else would
-- silently replace this one.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local GameConfig = require(ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
	:WaitForChild("GameConfig"))

local PASS = GameConfig.Pass

TextChatService.OnIncomingMessage = function(message: TextChatMessage): TextChatMessageProperties?
	local source = message.TextSource
	if not source then
		return nil
	end
	local speaker = Players:GetPlayerByUserId(source.UserId)
	if not (speaker and speaker:GetAttribute(PASS.VipAttribute) == true) then
		return nil
	end
	local props = Instance.new("TextChatMessageProperties")
	props.PrefixText = GameConfig.vipPrefix(message.PrefixText)
	return props
end
