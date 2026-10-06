--!strict
-- Steal a Seed :: RewardMoments (client, 2026-10-06)
--
-- The deliberate reward moments a new one must not stand over. A moment says
-- when it began and when it ended here -- the hatch reveal of the player's own
-- plant (HatchFX), the offline earnings card (OfflineUI) -- as client-local
-- attributes on the local player, never replicated; a centre panel (the
-- wheel's prize included) already says so through OpenPanel. The Invite a
-- Friend reward popup (InviteRewardUI) waits while any is up.

local Players = game:GetService("Players")

local RewardMoments = {}

RewardMoments.Prefix = "SeedMoment_"

local tokens: { [string]: number } = {}

-- A moment begins; with `seconds` it ends by itself then (unless begun again).
function RewardMoments.begin(name: string, seconds: number?)
	local me = Players.LocalPlayer
	if not me then
		return
	end
	local token = (tokens[name] or 0) + 1
	tokens[name] = token
	me:SetAttribute(RewardMoments.Prefix .. name, true)
	if seconds then
		task.delay(seconds, function()
			if tokens[name] == token then
				RewardMoments.finish(name)
			end
		end)
	end
end

function RewardMoments.finish(name: string)
	local me = Players.LocalPlayer
	if me then
		me:SetAttribute(RewardMoments.Prefix .. name, nil)
	end
end

-- Whether any moment is up on `player`, or a centre panel is open (`openPanel`
-- is GameConfig.Attributes.OpenPanel). Pure over the player's attributes.
function RewardMoments.busy(player: any, openPanel: string): boolean
	if player:GetAttribute(openPanel) ~= nil then
		return true
	end
	for name, value in pairs(player:GetAttributes()) do
		if value == true and string.sub(name, 1, #RewardMoments.Prefix) == RewardMoments.Prefix then
			return true
		end
	end
	return false
end

return RewardMoments
