--!strict
--==============================================================================
-- TEST STORE ON
--
-- Studio EDIT, before automated Play tests. Points ServerStorage.SeedTestStore
-- at a throwaway DataStore -- SeedTest_<UTC date> unless NAME is set -- so
-- every Play session in this Studio uses it instead of the real store (see
-- SaveService, WHICH STORE). Rojo never writes to ServerStorage, so a sync or
-- reconnect cannot switch it back. Then run store_guard.luau.
--
-- Opens no DataStore. Remove it again with test_store_off.luau, or the owner's
-- own Studio playtests will keep using the test store.
--==============================================================================

local NAME = "" -- empty: SeedTest_<yyyymmdd>
local MARKER = "SeedTestStore"
local THROWAWAY = "^Seed%a*Test_[%w_]+$"

local name = if NAME ~= "" then NAME else "SeedTest_" .. os.date("!%Y%m%d")
assert(string.find(name, THROWAWAY), name .. " is not a throwaway store name")

local ServerStorage = game:GetService("ServerStorage")
local existing = ServerStorage:FindFirstChild(MARKER)
if existing and not existing:IsA("StringValue") then
	existing:Destroy()
	existing = nil
end
local marker: StringValue
if existing then
	marker = existing :: StringValue
else
	marker = Instance.new("StringValue")
	marker.Name = MARKER
	marker.Parent = ServerStorage
end
marker.Value = name

local answer = "test store on: ServerStorage." .. MARKER .. " = " .. name
print("[TestStore] " .. answer)
return answer
