--!nocheck
--==============================================================================
-- Steal a Seed :: BoostIconsSpec (2026-10-04, the owner's boosts brief)
--
-- Edit mode, no Play:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("BoostIconsSpec"))
--
-- 1. THE ICONS' CATALOGUE (Shared/BoostIcons): which boosts and events stand,
--    in order, with the exact words, the authoritative deadline, the ring and
--    the controller's stepping -- every case from snapshots of attributes.
-- 2. THE ROW ON EVERY SCREEN (HudLayout): over the strip's name band, the
--    toast over the row, clear of every group and both thumbs, nothing else
--    moved, bounded however many icons there are.
-- 3. THE UI'S WIRING (BoostIconsUI): read-only, one popover, closed from
--    outside without eating the tap, the controller's key, the splash's way in.
-- 4. THE DISCO MILL (the real TreadmillService, its siblings stood in): built
--    once per event from the attributes and never in Ticket Shower Only or the
--    pure DISCO ONLY (2026-10-04, which shows its own "Disco Party" icon); each
--    rider paid their OWN normal training x10 in the same tick -- two
--    progressions -- normal mills unchanged; unmounted pays nothing; a full
--    mill refuses; the end stops the pay and sets every rider down beside it.
--
-- NOT here: anything drawn (screenshots in Play), real touches and real
-- controllers, two real players on the Disco Mill at once, live servers.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local BoostIcons = require(Shared.BoostIcons)
local HudLayout = require(Shared.HudLayout)
local SeedData = require(Shared.SeedData)
local Server = game:GetService("ServerScriptService").SeedGameServer
local Scripts = game:GetService("StarterPlayer").StarterPlayerScripts

local CFG = GameConfig.BoostIcons
local WORDS = CFG.Words
local M = GameConfig.MiniEvent
local DISCO = M.DiscoMill
local ATTR = GameConfig.Attributes

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
		say("  FAIL  " .. label .. (if detail and detail ~= "" then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local s = parent:FindFirstChild(name)
	return if s then s.Source else ""
end
local function ids(list)
	local t = {}
	for i, e in ipairs(list) do
		t[i] = e.id
	end
	return table.concat(t, ",")
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZBoostIconsSpec"
scratch.Archivable = false
scratch.Parent = Workspace
local savedAttrs = {}
for _, name in ipairs({ M.Attributes.State, M.Attributes.Mode, M.Attributes.EventId }) do
	savedAttrs[name] = Workspace:GetAttribute(name)
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The catalogue")
	--==========================================================================
	local NOW = 5000
	local all = BoostIcons.entries({
		now = NOW,
		rainState = "active", rainMode = "thunder", rainStartedAt = NOW - 30, rainEndsAt = NOW + 150,
		miniState = "running", miniMode = "ticketdisco", miniStartedAt = NOW - 10, miniEndsAt = NOW + 80,
		miniCap = 3, tickets = 1,
		chestBoost = "training", chestEndsAt = NOW + 60,
		sacrificeMultiplier = SeedData.Sacrifice.Multiplier, sacrificeEndsAt = NOW + 20,
	})
	check(ids(all) == "weather,disco,tickets,training,sacrifice",
		"everything at once stands in the configured order, the weather first", ids(all))
	local byId = {}
	for _, e in ipairs(all) do
		byId[e.id] = e
	end
	check(byId.disco.effect == "Disco Mill: \u{00D7}10 your normal treadmill training while mounted."
			and byId.disco.title == "Disco" and byId.disco.source == "disco",
		"the disco's popover says the owner's words exactly")
	check(byId.weather.title == "Thunderstorm" and byId.weather.source == "thunder"
			and byId.weather.endsAt == NOW + 150 and byId.weather.total == 180,
		"the thunderstorm wears its own picture and title; its deadline and whole run are the server's")
	check(byId.tickets.badge == "1/3" and byId.tickets.hint == string.format(WORDS.TicketsProgress, 1, 3)
			and byId.tickets.endsAt == NOW + 80 and byId.disco.endsAt == NOW + 80,
		"the tickets carry this player's count of the limit; both read the event's one deadline")
	check(byId.training.effect == "+25% treadmill training" and byId.training.title == WORDS.Boost
			and byId.training.total == GameConfig.BonusChest.BoostSeconds,
		"the chest's (or wheel's) training boost says its exact +25%")
	check(byId.sacrifice.effect == string.format("+%d%% garden income",
			math.floor((SeedData.Sacrifice.Multiplier - 1) * 100 + 0.5)) and byId.sacrifice.title == WORDS.Sacrifice,
		"the pedestal's boost says its exact percentage")
	local capped = BoostIcons.entries({ now = NOW, miniState = "running", miniMode = "tickets",
		miniEndsAt = NOW + 5, miniCap = 3, tickets = 3 })
	check(ids(capped) == "tickets" and capped[1].hint == string.format(WORDS.TicketsCapped, 3) and capped[1].badge == "3/3",
		"at the limit the ticket icon says so")
	-- The pure DISCO ONLY (2026-10-04): the Disco picture, the owner's two lines
	-- and the time left -- never the mill's x10, even with a stray ticket count.
	local party = BoostIcons.entries({ now = NOW, miniState = "running", miniMode = "party", miniStartedAt = NOW - 10,
		miniEndsAt = NOW + 80, miniCap = 3, tickets = 1 })
	local p1 = party[1] or {}
	check(ids(party) == "disco" and p1.source == "disco" and p1.title == "Disco Party"
			and p1.effect == "Up to +50% movement speed" and p1.hint == nil and p1.badge == nil
			and p1.endsAt == NOW + 80 and p1.total == 90 and BoostIcons.timeLine(p1, NOW) == "Ends in 1:20",
		"DISCO ONLY's popover: \"Disco Party\", \"Up to +50% movement speed\" (the owner's label), the time left; one "
			.. "icon, no tickets",
		ids(party) .. " | " .. tostring(p1.title) .. " | " .. tostring(p1.effect))
	local partyWords = tostring(p1.title) .. tostring(p1.effect) .. tostring(p1.hint)
	check(string.find(partyWords, "\u{00D7}", 1, true) == nil and string.find(partyWords, "Mill", 1, true) == nil
			and string.find(partyWords, "training", 1, true) == nil
			and GameConfig.SourceIcons[p1.source] == "rbxassetid://129016824458756",
		"and never a x10, a mill or training; its picture is the configured Disco icon")
	local gone = BoostIcons.entries({
		now = NOW,
		rainState = "closing", rainEndsAt = NOW + 50,
		miniState = "ending", miniMode = "disco", miniEndsAt = NOW + 50,
		chestBoost = "income", chestEndsAt = NOW - 1,
		sacrificeMultiplier = 1, sacrificeEndsAt = NOW + 50,
	})
	local late = BoostIcons.entries({ now = NOW, rainState = "active", rainEndsAt = NOW, miniState = "running",
		miniMode = "disco", miniEndsAt = NOW - 1, chestBoost = "nonsense", chestEndsAt = NOW + 9 })
	check(#gone == 0 and #late == 0,
		"nothing for a closing rain, an ending event, a spent or unknown boost, a x1 pedestal, or a passed deadline")
	check(BoostIcons.timeLine(byId.weather, NOW) == "Ends in 2:30" and BoostIcons.clock(3725) == "1:02:05",
		"the popover's time is the deadline less now")

	local r1, l1 = BoostIcons.ringRotations(1)
	local r2, l2 = BoostIcons.ringRotations(0.25)
	local r3, l3 = BoostIcons.ringRotations(0)
	local r4, l4 = BoostIcons.ringRotations(0.75)
	check(r1 == 180 and l1 == 360 and r2 == 90 and l2 == 180 and r3 == 0 and l3 == 180 and r4 == 180 and l4 == 270,
		"the ring's halves turn to the time left: full, a quarter, none, three quarters")
	check(BoostIcons.fraction(byId.weather, NOW) == 150 / 180
			and BoostIcons.fraction({ endsAt = 10, total = 0 }, 5) == 1,
		"the ring is the share of the whole run left (full when the run is unknown)")
	local order = { "weather", "disco", "tickets" }
	check(BoostIcons.nextOpen(order, nil, 1, false) == "weather" and BoostIcons.nextOpen(order, "weather", 1, false) == "disco"
			and BoostIcons.nextOpen(order, "tickets", 1, false) == nil
			and BoostIcons.nextOpen(order, "weather", -1, true) == "tickets"
			and BoostIcons.nextOpen(order, "tickets", 1, true) == "weather" and BoostIcons.nextOpen({}, nil, 1, false) == nil,
		"the controller's key opens the first, then each next, and closes past the last; left/right wrap")

	--==========================================================================
	say("2. The row on every screen")
	--==========================================================================
	local TOPBAR = 58
	local function screen(w, h, touch, icons, keyboard)
		return { safe = Vector2.new(w, h - TOPBAR), touch = touch, keyboard = keyboard ~= false, icons = icons,
			viewport = Vector2.new(w, h), topbar = HudLayout.rect(0, 0, w, TOPBAR), insetTop = TOPBAR }
	end
	local SCREENS = {
		{ "desktop 1920x1080", 1920, 1080, false }, { "desktop 1366x768", 1366, 768, false },
		{ "desktop 1024x600", 1024, 600, false }, { "small window 800x600", 800, 600, false },
		{ "phone 640x480", 640, 480, true }, { "phone 772x360", 772, 360, true }, { "phone 705x338", 705, 338, true },
		{ "phone 640x360", 640, 360, true }, { "phone 801x392", 801, 392, true }, { "phone 874x402", 874, 402, true },
		{ "phone 956x440", 956, 440, true }, { "phone 1000x609", 1000, 609, true },
	}
	local bad, tooBig = {}, {}
	for _, s in ipairs(SCREENS) do
		local base = HudLayout.solve(screen(s[2], s[3], s[4], nil))
		for n = 1, #CFG.Order do
			local L = HudLayout.solve(screen(s[2], s[3], s[4], n))
			local row = L.icons
			local band = HudLayout.hotbarBand(L.hotbar)
			local why = {}
			if not row then
				table.insert(why, "no row")
			else
				local cols = L.iconColumns
				local rows = math.ceil(n / math.max(1, cols))
				if row.y + row.h > band.y - 8 + 1e-6 then
					table.insert(why, "under the name band")
				end
				if row.x < 8 - 1e-6 or row.x + row.w > L.safe.X - 8 + 1e-6 then
					table.insert(why, "off the side")
				end
				for _, g in ipairs(HudLayout.groups(L, true)) do
					if g.name ~= "icons" and HudLayout.gap(row, g.rect) < 8 - 1e-6 then
						table.insert(why, "meets " .. g.name)
					end
				end
				for _, zone in ipairs({ L.thumb, L.jump }) do
					if zone and HudLayout.gap(row, zone) < 8 - 1e-6 then
						table.insert(why, "meets a thumb")
					end
				end
				if L.toast.y + L.toast.h > row.y - 8 + 1e-6 then
					table.insert(why, "the toast is not over it")
				end
				if base.hotbar.x ~= L.hotbar.x or base.hotbar.y ~= L.hotbar.y or base.cash.y ~= L.cash.y then
					table.insert(why, "something else moved")
				end
				if L.iconSize < CFG.Size.Min or rows > 2 or #HudLayout.problems(L) > 0 then
					table.insert(tooBig, string.format("%s x%d: %d px, %d rows, %s", s[1], n, L.iconSize, rows,
						table.concat(HudLayout.problems(L), "; ")))
				end
			end
			if #why > 0 then
				table.insert(bad, string.format("%s x%d: %s", s[1], n, table.concat(why, ", ")))
			end
		end
		if base.icons ~= nil then
			table.insert(bad, s[1] .. ": a row with no icons")
		end
	end
	check(#bad == 0, "on 12 screens, 1 to 6 icons stand over the strip's name band, 8 px clear of every group and "
		.. "both thumbs, the toast over them, nothing else moved", table.concat(bad, "; "))
	check(#tooBig == 0, "and the row stays bounded: never under the Min size, never more than two rows, no problem",
		table.concat(tooBig, "; "))
	local s1, c1, n1 = HudLayout.iconGrid(6, 1000, 40)
	local s2, c2, n2 = HudLayout.iconGrid(6, 200, 40)
	local s3, c3, n3 = HudLayout.iconGrid(6, 100, 40)
	check(s1 == 40 and c1 == 6 and n1 == 1 and s2 < 40 and s2 >= CFG.Size.Min and c2 == 6 and n2 == 1
			and s3 == CFG.Size.Min and n3 == 2 and c3 * n3 >= 6,
		"too many for the room: smaller first, then a second row -- never more",
		string.format("%d/%d/%d, %d/%d/%d, %d/%d/%d", s1, c1, n1, s2, c2, n2, s3, c3, n3))
	do
		local desk = HudLayout.solve(screen(1920, 1080, false, 3))
		local phone = HudLayout.solve(screen(801, 392, true, 3))
		check(desk.iconSize == CFG.Size.Desktop and phone.iconSize == CFG.Size.Phone and phone.toastTop == false,
			"desktop icons 40 px, a phone's 30, and a phone's notices over the belt too")
	end

	--==========================================================================
	say("3. BoostIconsUI's wiring")
	--==========================================================================
	local ui = sourceOf(Scripts, "BoostIconsUI")
	check(ui ~= "" and not string.find(ui, "FireServer", 1, true) and not string.find(ui, "InvokeServer", 1, true)
			and string.find(ui, "BoostIcons.entries(BoostIcons.read(player, Workspace, now))", 1, true) ~= nil
			and string.find(ui, "for _, w in ipairs(BoostIcons.watched()) do", 1, true) ~= nil,
		"read-only: drawn from the server's attributes (and redrawn on each), nothing sent anywhere")
	check(string.find(ui, "open(if openId == id then nil else id)", 1, true) ~= nil
			and string.find(ui, "UserInputService.InputBegan:Connect(function(input: InputObject)", 1, true) ~= nil
			and string.find(ui, "if inside(popover, at) or inside(row, at) then", 1, true) ~= nil
			and string.find(ui, "PadInput.PanelChanged:Connect", 1, true) ~= nil,
		"one popover: the same icon closes it, a tap elsewhere closes it without being taken, a panel closes it")
	check(string.find(ui, "end, false, CFG.PadKey)", 1, true) ~= nil
			and string.find(ui, "Enum.KeyCode.ButtonB, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight", 1, true) ~= nil
			and string.find(ui, "PadInput.panelOpen()", 1, true) ~= nil and CFG.PadKey == Enum.KeyCode.DPadDown,
		"a controller opens it with DPadDown (free on every path), steps with left/right, closes with B")
	check(string.find(ui, "gui.DisplayOrder = 29", 1, true) ~= nil and string.find(ui, "hit.Selectable = false", 1, true) ~= nil
			and string.find(ui, "StatusText.reducedMotion()", 1, true) ~= nil,
		"under the hotbar and every panel, out of the engine's selection, its rise dropped for reduced motion")
	local chest = sourceOf(Scripts, "BonusChestUI")
	check(string.find(chest, 'local icons = playerGui:FindFirstChild("SeedBoostIcons")', 1, true) ~= nil
			and string.find(ui, 'frame.Name = e.id', 1, true) ~= nil and string.find(ui, 'pop.Name = "Pop"', 1, true) ~= nil,
		"the chest's reward splash flies to the boost's own icon, by its id")

	--==========================================================================
	say("4. The Disco Mill, through the real TreadmillService")
	--==========================================================================
	local riders = {}
	local profiles, chestMult, paid = {}, {}, {}
	local function fakePlayer(name, plotId, tier, overclock)
		local attrs = {}
		local p = { Name = name, UserId = 7000 + #riders }
		function p:GetAttribute(k)
			return attrs[k]
		end
		function p:SetAttribute(k, v)
			attrs[k] = v
		end
		local model = Instance.new("Model")
		model.Name = "ZZRider_" .. name
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Size = Vector3.new(2, 2, 1)
		root.Parent = model
		model.PrimaryPart = root
		Instance.new("Humanoid").Parent = model
		model.Parent = scratch
		p.Character = model
		p.plotId = plotId
		profiles[p] = { MillTier = tier, MillOverclock = overclock, Speed = 0 }
		table.insert(riders, p)
		return p
	end
	local fakePlayers = {}
	function fakePlayers:GetPlayers()
		return riders
	end
	function fakePlayers:GetPlayerFromCharacter(character)
		for _, p in ipairs(riders) do
			if p.Character == character then
				return p
			end
		end
		return nil
	end
	local plots = {}
	local function plotOf(player)
		local plot = plots[player.plotId]
		if not plot then
			plot = { id = player.plotId, owner = player }
			function plot:GetAttribute(k)
				return if k == ATTR.PlotId then self.id else nil
			end
			plots[player.plotId] = plot
		end
		return plot
	end
	local PlotService = {
		PlotOf = plotOf,
		OwnerOf = function(plot)
			return plot.owner
		end,
	}
	local PlayerDataService = {
		IsReady = function()
			return true
		end,
		Get = function(player)
			return profiles[player]
		end,
		AddSpeed = function(player, amount)
			table.insert(paid, { player = player, amount = amount })
			profiles[player].Speed += amount
			return true
		end,
	}
	local CarryService = { RefreshWalkSpeed = function() end }
	local BonusChestService = {
		Multiplier = function(player, kind)
			return if kind == "training" then (chestMult[player] or 1) else 1
		end,
	}
	local fakeGame = {}
	function fakeGame:GetService(name)
		if name == "Players" then
			return fakePlayers
		end
		return game:GetService(name)
	end
	local module = Server.TreadmillService
	local chunk = assert(loadstring(module.Source, "=TreadmillService"))
	local siblings = { PlotService = PlotService, PlayerDataService = PlayerDataService,
		CarryService = CarryService, BonusChestService = BonusChestService }
	local parent = {}
	function parent:WaitForChild(name)
		assert(siblings[name] ~= nil, "unexpected sibling " .. name)
		return { __standIn = siblings[name] }
	end
	local outerRequire = require
	setfenv(chunk, setmetatable({
		game = fakeGame,
		script = { Name = "TreadmillService", Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	local Treadmill = chunk()
	Treadmill.Init()

	-- Two own mills for the comparison: plain belts, tagged and stamped as the
	-- map's are, far off the map.
	local function ownMill(id, x)
		local mill = Instance.new("Model")
		mill.Name = "ZZOwnMill" .. id
		mill:SetAttribute(ATTR.PlotId, id)
		local belt = Instance.new("Part")
		belt.Name = "Treadmill"
		belt.Anchored = true
		belt.Size = Vector3.new(8, 1.4, 16)
		belt.Position = Vector3.new(x, 1, 3000)
		belt.Parent = mill
		mill.Parent = scratch
		CollectionService:AddTag(belt, GameConfig.Tags.Treadmill)
		return belt
	end
	local beltA = ownMill(901, 3000)
	local beltC = ownMill(902, 3040)
	local A = fakePlayer("A", 901, 1, 0)
	local B = fakePlayer("B", 903, 1, 0)
	local C = fakePlayer("C", 902, 5, 0)
	local D = fakePlayer("D", 904, 5, 0)
	local function standOn(p, belt)
		p.Character.HumanoidRootPart.CFrame = belt.CFrame * CFrame.new(0, belt.Size.Y / 2 + 1, 0)
	end
	standOn(A, beltA)
	standOn(C, beltC)

	local W = Workspace
	local function event(state, mode, id)
		W:SetAttribute(M.Attributes.EventId, id)
		W:SetAttribute(M.Attributes.Mode, mode)
		W:SetAttribute(M.Attributes.State, state)
		Treadmill.SyncDiscoMill()
	end
	local function mills()
		local n = 0
		for _, child in ipairs(W:GetChildren()) do
			if child.Name == DISCO.ModelName then
				n += 1
			end
		end
		return n
	end
	event("running", "tickets", "spec00000000aaaa")
	check(mills() == 0, "Ticket Shower Only builds no Disco Mill")
	event("running", "ticketdisco", "spec00000000bbbb")
	local first = Treadmill.DiscoMill()
	Treadmill.SyncDiscoMill()
	event("running", "ticketdisco", "spec00000000bbbb")
	check(mills() == 1 and first ~= nil and Treadmill.DiscoMill() == first and first:GetAttribute("DiscoMill") == "spec00000000bbbb",
		"Ticket Disco builds ONE Disco Mill; the same event again (a repeat notice, a late read) builds no second one",
		mills() .. " mills")
	local belt = first and first:FindFirstChild(GameConfig.Plot.TreadmillName, true)
	check(belt ~= nil and CollectionService:HasTag(belt, GameConfig.Tags.Treadmill)
			and first:GetAttribute(ATTR.PlotId) == nil and not CollectionService:HasTag(first, GameConfig.Tags.MillSign)
			and first:FindFirstChildWhichIsA("ProximityPrompt", true) == nil
			and first.ModelStreamingMode == Enum.ModelStreamingMode.Atomic,
		"its belt is a Treadmill belt with no plot and no sign, streamed whole")
	-- Where it stands: clear of everything on the map, west of the road.
	local cf, size = first:GetBoundingBox()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { first, scratch }
	local touching = {}
	for _, part in ipairs(W:GetPartBoundsInBox(cf, size, params)) do
		if part.Name ~= "TheField" then
			table.insert(touching, part:GetFullName())
		end
	end
	check(#touching == 0 and cf.X + size.X / 2 <= -15 and cf.Z - size.Z / 2 > -GameConfig.Map.FieldFront + 20
			and (cf.Position - Vector3.new(0, cf.Y, 0)).Magnitude - size.Z / 2 > GameConfig.Map.HubRadius,
		"it stands on open ground in front of the hub: touching nothing, its road-side edge 15+ studs off the "
			.. "road's centre line, short of the SAFE line, clear of the deck",
		table.concat(touching, ", ") .. string.format(" | box x %.0f..%.0f z %.0f..%.0f", cf.X - size.X / 2,
			cf.X + size.X / 2, cf.Z - size.Z / 2, cf.Z + size.Z / 2))

	-- Mounting: each rider on a spot of their own.
	local spotB = Treadmill.MountDisco(B)
	local spotD = Treadmill.MountDisco(D)
	local rootB = B.Character.HumanoidRootPart.Position
	local rootD = D.Character.HumanoidRootPart.Position
	check(spotB == 1 and spotD == 2 and (rootB - rootD).Magnitude > 4 and B:GetAttribute(ATTR.MillMounted) == true
			and Treadmill.OnDiscoMill(B) and Treadmill.OnDiscoMill(D),
		"two riders get two separate spots on it, mounted and standing on its belt")
	check(Treadmill.RateFor(B) == Treadmill.RateOf(B) and Treadmill.RateFor(D) == Treadmill.RateOf(D)
			and Treadmill.RateOf(D) > Treadmill.RateOf(B),
		"the rate it reports is each rider's OWN normal rate (the x10 is not hidden in it)")

	-- Two ticks: the first starts every clock, the second pays.
	chestMult[A], chestMult[B] = 1.25, 1.25
	Treadmill.PayTick()
	table.clear(paid)
	task.wait(0.4)
	Treadmill.PayTick()
	local amount = {}
	for _, row in ipairs(paid) do
		amount[row.player] = (amount[row.player] or 0) + row.amount
	end
	local a, b, c, d = amount[A] or 0, amount[B] or 0, amount[C] or 0, amount[D] or 0
	local function near(x, y)
		return math.abs(x - y) <= 1e-9 * math.max(1, math.abs(y))
	end
	check(#paid == 4 and a > 0 and c > 0 and near(b, a * DISCO.Multiplier) and near(d, c * DISCO.Multiplier),
		"in the same tick each rider earns exactly x10 what the same player earns on their own mill -- tier 1 with a "
			.. "+25% training boost, and tier 5: their own progression, composed once",
		string.format("A %.4f B %.4f C %.4f D %.4f", a, b, c, d))
	check(near(a / (Treadmill.RateOf(A) * 1.25), c / Treadmill.RateOf(C)) and b ~= d,
		"own mills are paid exactly as before (rate x boost x the tick), and the riders' pay differs by "
			.. "their own progression")
	check(B:GetAttribute(ATTR.OnTreadmill) == true and first:FindFirstChild(GameConfig.Plot.TreadmillName, true)
			:GetAttribute("BeltSpeed") == DISCO.BeltStuds,
		"its belt runs while anybody is paid on it")

	-- Standing on it unmounted, and a full mill.
	local E = fakePlayer("E", 905, 1, 0)
	E.Character.HumanoidRootPart.CFrame = belt.CFrame * CFrame.new(0, belt.Size.Y / 2 + 1, 0)
	check(not Treadmill.OnDiscoMill(E) and Treadmill.RateFor(E) == 0, "standing on it without a spot earns nothing")
	local extra = {}
	for i = 1, #DISCO.Spots do
		table.insert(extra, fakePlayer("F" .. i, 910 + i, 1, 0))
	end
	local given = 0
	for _, p in ipairs(extra) do
		if Treadmill.MountDisco(p) then
			given += 1
		end
	end
	check(given == #DISCO.Spots - 2, string.format("with %d spots and two taken, only %d more riders get one",
		#DISCO.Spots, #DISCO.Spots - 2), given .. " given")
	for _, p in ipairs(extra) do
		Treadmill.Unmount(p)
	end

	-- A jump is a dismount; and the end of the event.
	Treadmill.Unmount(D)
	check(D:GetAttribute(ATTR.MillMounted) == nil and not Treadmill.OnDiscoMill(D), "getting off frees the rider")
	local beforeEnd = B.Character.HumanoidRootPart.Position
	event("ending", "ticketdisco", "spec00000000bbbb")
	local after = B.Character.HumanoidRootPart.Position
	local belowGround = after.Y < GameConfig.Map.GroundY
	check(mills() == 0 and Treadmill.DiscoMill() == nil and B:GetAttribute(ATTR.MillMounted) == nil
			and after.X > cf.X + size.X / 2 and not belowGround and (after - beforeEnd).Magnitude > 4
			and D.Character.HumanoidRootPart.Position == rootD,
		"the event ending takes it down at once and sets its rider down beside it on the road side; a player who "
			.. "had already got off is not moved",
		string.format("B now %s", tostring(after)))
	table.clear(paid)
	Treadmill.PayTick()
	local bPaid = 0
	for _, row in ipairs(paid) do
		if row.player == B then
			bPaid += row.amount
		end
	end
	check(bPaid == 0 and B:GetAttribute(ATTR.OnTreadmill) == nil, "and nobody is paid for it any more")
	-- A new event builds a new one; a restart leaves none behind.
	event("running", "disco", "spec00000000cccc")
	local second = Treadmill.DiscoMill()
	check(mills() == 1 and second ~= first and second:GetAttribute("DiscoMill") == "spec00000000cccc",
		"DISCO + MILL (the old \"disco\" id) builds one for its own event")
	-- The pure DISCO ONLY (2026-10-04): the disco without the mill. Taking over
	-- from a mill's event takes that mill down, and it never builds its own.
	event("running", "party", "spec00000000dddd")
	local partyMills = mills()
	Treadmill.SyncDiscoMill()
	check(partyMills == 0 and mills() == 0 and Treadmill.DiscoMill() == nil and Treadmill.MountDisco(E) == nil,
		"DISCO ONLY builds no Disco Mill -- and replacing DISCO + MILL with it takes that one down -- so nobody can mount one",
		partyMills .. " mills")
	event("running", "disco", "spec00000000eeee")
	check(mills() == 1, "and the next DISCO + MILL builds its own again")
	Treadmill.Init()
	check(mills() == 0, "a restart of the service leaves none standing")
	event(nil, nil, nil)
	for _, p in ipairs(riders) do
		Treadmill.Unmount(p)
	end
	CollectionService:RemoveTag(beltA, GameConfig.Tags.Treadmill)
	CollectionService:RemoveTag(beltC, GameConfig.Tags.Treadmill)
	local stray = W:FindFirstChild(DISCO.ModelName)
	if stray then
		stray:Destroy()
	end
end)

for name, value in pairs(savedAttrs) do
	Workspace:SetAttribute(name, value)
end
scratch:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nBoostIconsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
