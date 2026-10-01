--!nocheck
--==============================================================================
-- Steal a Seed :: CommunitySpec
--
-- THE COMMUNITY CHEST AND SPIN TICKETS (2026-10-01, the owner's brief;
-- GameConfig.Community). Edit mode, WheelSpec's way: the REAL WheelService and
-- CommunityService, loaded with stand-in profiles, faucets and membership, so a
-- save can fail on purpose and a spin can be driven. The owner's checks:
--
--   checked first                a member is granted on the first look; only a
--                                non-member is answered "join" (the prompt)
--   once-only granting           a member claims once; never twice
--   failed-save retry            a save that fails takes the grant back; the
--                                next try lands
--   saved ticket persistence     spins and flag saved together; the ticket is
--                                rebuilt from the balance after a respawn and
--                                read back through a save
--   one ticket per accepted spin a spin the server accepts uses one; a refused
--                                one uses none; bought spins are untouched
--
-- Live joining (GroupService:PromptJoinAsync) is Roblox's own and is not here.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

local COMMUNITY = GameConfig.Community
local N = COMMUNITY.Spins

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

--==============================================================================
-- THE STAND-INS (WheelSpec's, trimmed)
--==============================================================================
local fixture = Instance.new("Folder")
fixture.Name = "CommunitySpecFixture"
fixture.Parent = game:GetService("ServerStorage")

local fakePlayers = {}
local noSignal = {
	Connect = function()
		return { Disconnect = function() end }
	end,
}
fakePlayers.PlayerAdded = noSignal
fakePlayers.PlayerRemoving = noSignal
function fakePlayers:GetPlayers()
	return {}
end
local function makePlayer(name, userId)
	local attrs = {}
	local backpack = Instance.new("Folder")
	backpack.Name = name .. "Backpack"
	backpack.Parent = fixture
	local p = { Name = name, UserId = userId, Parent = fakePlayers, Character = nil, _backpack = backpack }
	function p:GetAttribute(key)
		return attrs[key]
	end
	function p:SetAttribute(key, value)
		attrs[key] = value
	end
	function p:FindFirstChildOfClass(class)
		return if class == "Backpack" then p._backpack else nil
	end
	return p
end

local profiles = {}
local saveWorks = true
local saves = {}
local PlayerDataService = {
	Get = function(player)
		return profiles[player]
	end,
	IsPersistent = function()
		return true
	end,
	IsReady = function(player)
		return profiles[player] ~= nil
	end,
	UpdateWheel = function(player, change)
		local p = profiles[player]
		return p ~= nil and change(p) == true
	end,
	Save = function(player)
		local p = profiles[player]
		if saveWorks and p then
			-- What a real save writes: the whole profile at that moment.
			table.insert(saves, { player = player, earned = p.WheelEarned, claimed = p.CommunityClaimed,
				bought = p.WheelBought })
		end
		return saveWorks
	end,
}
local EconomyService = {
	PayReward = function(player, amount)
		profiles[player].Cash += amount
		return true
	end,
}
local TreadmillService = {
	PayReward = function(player, amount)
		profiles[player].Speed += amount
		return true
	end,
}
local CarryService = {
	IsHeldRestored = function()
		return true
	end,
	HeldRoom = function(player)
		return math.max(GameConfig.Save.MaxHeld - #profiles[player].Held, 0), #profiles[player].Held, true
	end,
	GivePod = function(player, species, tier)
		table.insert(profiles[player].Held, { Id = species, Tier = tier, Hatched = false })
		return true
	end,
}
local BonusChestService = { GrantBoost = function()
	return true
end }
local Metrics = { wheelSpun = function() end, wheelSpinEarned = function() end }
local WheelModel = { build = function()
	return nil
end }
local PlantService = { OnRevealed = function()
	return function() end
end }

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end

local outerRequire = require
local function loadWith(module, siblings)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	setfenv(chunk, setmetatable({
		game = fakeGame,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	return chunk()
end

local W = loadWith(Server:WaitForChild("WheelService"), {
	PlayerDataService = PlayerDataService, EconomyService = EconomyService, TreadmillService = TreadmillService,
	CarryService = CarryService, BonusChestService = BonusChestService, Metrics = Metrics,
	WheelModel = WheelModel, PlantService = PlantService,
})
W.Init()
W.useReply(function() end)
local C = loadWith(Server:WaitForChild("CommunityService"), {
	PlayerDataService = PlayerDataService, WheelService = W,
})
C.Init()
local membership = {}
C.useMembership(function(player)
	local list = membership[player]
	if type(list) == "table" then
		return table.remove(list, 1)
	end
	return list
end)
C.useWait(function() end)

local function join(name, userId)
	local p = makePlayer(name, userId)
	profiles[p] = ProfileSchema.Default()
	return p, profiles[p]
end
local function ticket(p)
	return W.TicketOf(p)
end

local ok, err = pcall(function()
	--==========================================================================
	-- 1. ONCE ONLY
	--==========================================================================
	say("-- once only --")
	local a, pa = join("CommunityMember", 9901)
	membership[a] = true
	local first = C.Check(a)
	check(first == "granted" and pa.WheelEarned == N and pa.CommunityClaimed == true,
		string.format("an existing member's first look grants %d spins and the claimed flag -- no prompt", N), first)
	check(a:GetAttribute(COMMUNITY.ClaimedAttribute) == true, "and the chest's claimed state is published for them")
	task.wait(COMMUNITY.CheckCooldownSeconds + 0.1)
	local second = C.Check(a)
	check(second == "claimed" and pa.WheelEarned == N, "a second check grants nothing more", second)
	check(W.GrantCommunity(a) == "claimed" and pa.WheelEarned == N,
		"nor does the grant itself, asked again directly")

	--==========================================================================
	-- 2. CANCELLED, AND A JOIN NOT VISIBLE YET
	--==========================================================================
	say("\n-- checked first; cancelled, and delayed --")
	local b, pb = join("CommunityCancel", 9902)
	membership[b] = { false, false, false, false }
	local look = C.Check(b)
	check(look == "join" and #membership[b] == 3 and pb.WheelEarned == 0 and pb.CommunityClaimed == false,
		"a non-member's first look asks Roblox once and answers \"join\" (open the prompt); nothing granted", look)
	local cancelled = C.Check(b, "verify")
	check(cancelled == "notmember" and #membership[b] == 0 and pb.WheelEarned == 0 and pb.CommunityClaimed == false,
		"the verify after the prompt skips the cooldown, asks VerifyTries times, and a cancel gets nothing", cancelled)
	membership[b] = true
	local again = C.Check(b, "verify")
	check(again == "wait" and pb.WheelEarned == 0,
		"a second verify with no prompt behind it is a first look again, under the cooldown", again)
	local c, pc = join("CommunityLate", 9903)
	membership[c] = { false, false, false, true }
	check(C.Check(c) == "join" and C.Check(c, "verify") == "granted" and pc.WheelEarned == N,
		"a join that shows on the verify's last ask is still granted, in the same check")
	local d, pd = join("CommunityUnknown", 9904)
	membership[d] = nil
	check(C.Check(d) == "retry" and pd.WheelEarned == 0 and pd.CommunityClaimed == false,
		"Roblox not answering grants nothing and says to try again")
	task.wait(COMMUNITY.CheckCooldownSeconds + 0.1)
	membership[d] = true
	check(C.Check(d) == "granted" and pd.WheelEarned == N, "and the retry lands, with no prompt for a member")

	--==========================================================================
	-- 3. A FAILED SAVE, AND ITS RETRY
	--==========================================================================
	say("\n-- a failed save --")
	local e, pe = join("CommunitySaveFails", 9905)
	pe.WheelEarned = 2
	membership[e] = true
	saveWorks = false
	local failed = C.Check(e)
	saveWorks = true
	check(failed == "save" and pe.WheelEarned == 2 and pe.CommunityClaimed == false,
		"a save that fails takes the spins and the flag back together", failed)
	check(e:GetAttribute(COMMUNITY.ClaimedAttribute) == nil, "and the chest still offers the claim")
	task.wait(COMMUNITY.CheckCooldownSeconds + 0.1)
	check(C.Check(e) == "granted" and pe.WheelEarned == 2 + N and pe.CommunityClaimed == true,
		"stepping on again lands it, on top of the spins already held")

	--==========================================================================
	-- 4. SAVED TOGETHER, AND THE TICKETS PERSIST
	--==========================================================================
	say("\n-- saved, and persistent --")
	local saved = nil
	for _, s in ipairs(saves) do
		if s.player == e then
			saved = s
		end
	end
	check(saved and saved.earned == 2 + N and saved.claimed == true,
		"the save that landed holds the spins and the flag together",
		saved and string.format("%s %s", tostring(saved.earned), tostring(saved.claimed)))
	local back = ProfileSchema.Sanitise({ WheelEarned = pe.WheelEarned, CommunityClaimed = true })
	check(back.WheelEarned == 2 + N and back.CommunityClaimed == true,
		"and a rejoin reads both back")
	check(ProfileSchema.Sanitise({}).CommunityClaimed == false and ProfileSchema.Default().CommunityClaimed == false,
		"an old or new profile has not claimed")
	local t = ticket(e)
	check(t ~= nil and t:IsA("Tool") and t.Name == COMMUNITY.TicketName and t:GetAttribute("TicketCount") == 2 + N
			and t:GetAttribute("SpeciesId") == nil and t.CanBeDropped == false,
		"the hotbar's Spin Ticket is one stacked Tool counting the earned balance -- not a plant, so no storage",
		t and t:GetAttribute("TicketCount"))
	t:Destroy()
	check(ticket(e) == nil, "(a death empties the Backpack)")
	W.Publish(e)
	local again = ticket(e)
	check(again ~= nil and again:GetAttribute("TicketCount") == 2 + N,
		"and the next publish rebuilds it from the saved balance, nothing lost")

	--==========================================================================
	-- 5. ONE TICKET PER ACCEPTED SPIN
	--==========================================================================
	say("\n-- spending --")
	local f, pf = join("CommunitySpender", 9906)
	membership[f] = true
	C.Check(f)
	pf.WheelBought = 3
	local before = pf.WheelEarned
	W.DebugForce(f, "cash_small")
	W.Spin(f, "earned")
	check(pf.WheelEarned == before - 1 and pf.WheelBought == 3 and ticket(f):GetAttribute("TicketCount") == before - 1,
		"a spin the server accepts uses exactly one ticket, and no bought spin",
		string.format("%d -> %d", before, pf.WheelEarned))
	saveWorks = false
	W.DebugForce(f, "cash_small")
	W.Spin(f, "earned")
	saveWorks = true
	check(pf.WheelEarned == before - 1 and ticket(f):GetAttribute("TicketCount") == before - 1,
		"a spin whose save fails is taken back: no ticket used", pf.WheelEarned)
	for _ = 1, before - 1 do
		W.DebugForce(f, "cash_small")
		W.Spin(f, "earned")
	end
	check(pf.WheelEarned == 0 and ticket(f) == nil and pf.WheelBought == 3,
		"spending the last ticket leaves no Tool behind, and the bought spins as they were")
	W.Spin(f, "earned")
	check(pf.WheelEarned == 0 and pf.WheelBought == 3, "with no tickets, an earned spin is refused and nothing is used")

	--==========================================================================
	-- 6. THE BALANCE'S CAP, AND THE RESET
	--==========================================================================
	say("\n-- the cap, and a reset --")
	local g, pg = join("CommunityFull", 9907)
	pg.WheelEarned = require(Shared:WaitForChild("WheelData")).MaxEarnedHeld - 1
	membership[g] = true
	check(C.Check(g) == "full" and pg.CommunityClaimed == false,
		"with no room for all of them, nothing is granted and the claim stays open")
	local pds = Server:FindFirstChild("PlayerDataService").Source
	local reset = string.match(pds, "function PlayerDataService%.ResetProgress(.-)\nend\n") or ""
	check(reset:find("CommunityClaimed = ", 1, true) ~= nil, "a progress reset keeps the claimed flag")
end)

W.Init()
C.Init()
fixture:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nCommunitySpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
