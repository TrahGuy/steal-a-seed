--!strict
--==============================================================================
-- TEST STORE OFF
--
-- Studio EDIT, after automated Play tests. Deletes every key in the throwaway
-- store ServerStorage.SeedTestStore names -- only when that name is a
-- throwaway -- and then removes the marker, so Studio playtests use the real
-- store again. The real store is never named here and never opened.
--==============================================================================

local MARKER = "SeedTestStore"
local THROWAWAY = "^Seed%a*Test_[%w_]+$"

local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local marker = ServerStorage:FindFirstChild(MARKER)
if not marker then
	return "test store off: there was no marker"
end
local name = if marker:IsA("StringValue") then (marker :: StringValue).Value else ""
local report = "not a throwaway name, no keys touched"
if string.find(name, THROWAWAY) then
	local store = DataStoreService:GetDataStore(name)
	local removed = 0
	local ok, err = pcall(function()
		local pages = store:ListKeysAsync()
		while true do
			for _, key in ipairs(pages:GetCurrentPage()) do
				store:RemoveAsync((key :: any).KeyName)
				removed += 1
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
	local left = -1
	pcall(function()
		left = #store:ListKeysAsync():GetCurrentPage()
	end)
	report = string.format("%d key(s) removed, %d left%s", removed, left,
		if ok then "" else " (listing failed: " .. tostring(err) .. ")")
end
marker:Destroy()

local answer = string.format("test store off: %s -- %s; marker removed", name, report)
print("[TestStore] " .. answer)
return answer
