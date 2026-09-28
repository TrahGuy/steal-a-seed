--!strict
--==============================================================================
-- STORE GUARD
--
-- Run it in Studio EDIT (MCP execute_luau, or the Command Bar) immediately
-- before EVERY automated Play start, and start Play only on "SAFE". Read-only:
-- it reads one value and two scripts' sources, and opens no DataStore.
--
-- Automated Play tests never load a real save (AGENTS.md). The test store is
-- the StringValue ServerStorage.SeedTestStore -- see GameConfig.Save and
-- SaveService, WHICH STORE. default.project.json does not map ServerStorage,
-- so no Rojo sync or reconnect can take the marker away; the old way, a
-- Studio-only edit of GameConfig's StoreName, was undone by exactly that on
-- 2026-09-26 and a Play test loaded the owner's real save.
--
-- "SAFE <store>" only when all three hold:
--
--   1. the marker exists, is a StringValue, and names a throwaway: "Seed",
--      then letters, then "Test_" -- SeedTest_20260927;
--   2. Studio's SaveService is the copy that reads the marker. An older copy
--      would ignore it and open the real store;
--   3. Studio's GameConfig names the same marker and the same pattern.
--
-- Anything else is "UNSAFE <why>", and Play must not start.
-- tools/studio/test_store_on.luau creates the marker; test_store_off.luau
-- empties the throwaway store and removes it.
--==============================================================================

local MARKER = "SeedTestStore"
local THROWAWAY = "^Seed%a*Test_[%w_]+$"

local function sourceAt(path: { string }): string?
	local node: Instance? = game
	for _, name in ipairs(path) do
		node = if node then node:FindFirstChild(name) else nil
	end
	if node and node:IsA("LuaSourceContainer") then
		return (node :: any).Source
	end
	return nil
end

local function verdict(): string
	local marker = game:GetService("ServerStorage"):FindFirstChild(MARKER)
	if not marker then
		return "UNSAFE no ServerStorage." .. MARKER .. " (run tools/studio/test_store_on.luau)"
	end
	if not marker:IsA("StringValue") then
		return "UNSAFE ServerStorage." .. MARKER .. " is a " .. marker.ClassName .. ", not a StringValue"
	end
	local name = (marker :: StringValue).Value
	if not string.find(name, THROWAWAY) then
		return "UNSAFE the marker names " .. name .. ", which is not a throwaway store"
	end
	local save = sourceAt({ "ServerScriptService", "SeedGameServer", "SaveService" })
	if not save or not string.find(save, "SAVE.TestStoreMarker", 1, true) then
		return "UNSAFE Studio's SaveService does not read the marker, so it would open the real store"
	end
	local config = sourceAt({ "ReplicatedStorage", "SeedGame", "Shared", "GameConfig" })
	if not config
		or not string.find(config, 'TestStoreMarker = "' .. MARKER .. '"', 1, true)
		or not string.find(config, 'TestStorePattern = "' .. THROWAWAY .. '"', 1, true) then
		return "UNSAFE Studio's GameConfig does not name the same marker and pattern"
	end
	return "SAFE " .. name
end

local answer = verdict()
print("[StoreGuard] " .. answer)
return answer
