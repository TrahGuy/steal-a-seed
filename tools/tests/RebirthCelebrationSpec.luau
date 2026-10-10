--!nocheck
--==============================================================================
-- Steal a Seed :: RebirthCelebrationSpec
--
-- The rebirth celebration (2026-10-09; GameConfig.Rebirth.Celebration,
-- Shared/RebirthCelebration, Shared/RebirthFX, RebirthService.Celebrate and
-- RebirthUI's "done" / "celebrate"), in Edit:
--
--   1. the config: the owner's four sheets, the fanfare's two rows and their
--      window, the empty art slots, the notice icon, the order of the moments
--   2. the timeline: flash, column, spin, orbs, card, rays, burst, the end
--   3. REDUCED FX: nothing moves; the card at once; the fanfare still plays
--   4. the turn: SpinTurns round and on to face the camera; the orbs the
--      other way, from the feet to over the head
--   5. the words: the card's lines, the server's line, the particles' tint
--   6. who sees it: the REAL RebirthService -- "celebrate" within Range, the
--      line to everybody else, nothing to the reborn player, and only after
--      the save and the "done" answer
--   7. the card on every listed screen: clear of the HUD, a phone's 85%, the
--      longest words readable
--   8. whole celebrations stepped by hand: built, held, handed back exactly,
--      and gone -- own, REDUCED FX, somebody else's, GAIA, played twice, a
--      body lost midway
--   9. the aura from WORLD TREE
--  10. the wiring
--
-- Not here, seen in Play instead: the pictures on a screen, a real camera and
-- body, another player's screen.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local Rebirth = require(Shared.Rebirth)
local RebirthCelebration = require(Shared.RebirthCelebration)
local RebirthFX = require(Shared.RebirthFX)
local HudLayout = require(Shared.HudLayout)
local Notice = require(Shared.Notice)
local SpeedMilestones = require(Shared.SpeedMilestones)

local CFG = GameConfig.Rebirth
local C = CFG.Celebration
local T = C.Textures
local CUES = GameConfig.Sfx.Cues
local TAU = math.pi * 2

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end
local function count(src, needle)
	local n, at = 0, 1
	while true do
		local i = string.find(src, needle, at, true)
		if not i then
			return n
		end
		n += 1
		at = i + #needle
	end
end
local function near(a, b, tol)
	return math.abs(a - b) <= (tol or 1e-6)
end

local scratch = Instance.new("Folder")
scratch.Name = "ZZRebirthCelebrationSpec"
scratch.Parent = Workspace

local ok, err = pcall(function()
	--==========================================================================
	say("1. The config")
	--==========================================================================
	check(T.Burst == "rbxassetid://104561904060787" and T.Leaf == "rbxassetid://139088327003961"
			and T.Sparkle == "rbxassetid://113832021583342" and T.Aura == "rbxassetid://136617357503029",
		"the owner's four sheets: burst, leaf, sparkle, aura")
	check(C.Rays == "rbxassetid://134900206184752" and C.Logo == "rbxassetid://107076109311776"
			and C.Rays ~= SpeedMilestones.Art.Burst,
		"the rays and the REBORN! logo are the owner's uploads (2026-10-09), never another upload standing in",
		C.Rays .. " / " .. C.Logo)
	local own, nearby = CUES[C.Cue], CUES[C.NearbyCue]
	check(own ~= nil and nearby ~= nil and own.id == "rbxassetid://115254226875194" and nearby.id == own.id,
		"the fanfare is the owner's Triumphant Chime, flat for the reborn player and from the body for the rest")
	check(own and nearby and own.start == nearby.start and own.clip == nearby.clip
			and own.fadeOut == nearby.fadeOut and own.volume == nearby.volume
			and own.group == "UI" and nearby.group == "World" and nearby.range == C.Range,
		"both rows play the same window; the body's is heard within the celebration's Range")
	-- The recording's arrival hit is at 2.41 s (measured 2026-10-09).
	check(own and near(2.41 - own.start, C.SpinSeconds, 0.1) and own.clip <= C.Seconds
			and own.start + own.clip <= 13.09 and (own.fadeOut or 0) > 0,
		"the window puts the chime's hit on the burst and ends with the card, faded rather than cut",
		own and string.format("hit at %.2f, ends %.2f", 2.41 - own.start, own.clip))
	check(GameConfig.SourceIcons.rebirth == CFG.Art.Emblem and CFG.Art.Emblem ~= "",
		"the line everybody else reads carries the owner's rebirth emblem")
	check(0 < C.PopupAt and C.PopupAt < C.SpinSeconds and C.SpinSeconds < C.Seconds - C.FadeSeconds
			and C.Column.FadeTo <= C.Seconds and C.FlashSeconds < C.SpinSeconds,
		"the moments in order: the flash, the card, the burst, the fade -- all inside Seconds")
	check(C.DisplayOrder > 35 and C.DisplayOrder < 40 and C.Range == 120 and C.Orbs.Count == 8
			and C.SpinTurns == 2 and C.Aura.From == 50,
		"over the menus and the invite card, under the rail; 120 studs; eight orbs; two turns; the aura from 50")

	--==========================================================================
	say("2. The timeline")
	--==========================================================================
	local f0 = RebirthCelebration.at(0, false)
	check(f0.flash == 1 and f0.held and f0.spin == 0 and not f0.popup and not f0.burst and not f0.done
			and f0.column == 0 and f0.columnAlpha == 1,
		"at once: the flash at its brightest, the column starting up, the camera and controls held, no card yet")
	check(RebirthCelebration.at(C.FlashSeconds, false).flash == 0
			and RebirthCelebration.at(C.FlashSeconds * 0.5, false).flash > 0,
		"the flash is over in FlashSeconds")
	check(near(RebirthCelebration.at(C.Column.RiseSeconds, false).column, 1)
			and RebirthCelebration.at(C.Column.FadeFrom, false).columnAlpha == 1
			and near(RebirthCelebration.at(C.Column.FadeTo, false).columnAlpha, 0),
		"the column is up in RiseSeconds and gone by FadeTo")
	local before = RebirthCelebration.at(C.PopupAt - 0.01, false)
	local popped = RebirthCelebration.at(C.PopupAt, false)
	local peak = RebirthCelebration.at(C.PopupAt + C.PopSeconds * 0.6, false)
	local settled = RebirthCelebration.at(C.PopupAt + C.PopSeconds + 0.01, false)
	check(not before.popup and popped.popup and near(popped.popScale, 0.6) and near(peak.popScale, 1.08, 1e-3)
			and settled.popScale == 1 and popped.rays == 0 and settled.rays == 1,
		"the card pops at PopupAt: 0.6, 1.08, then 1 of its size, the rays coming up with it")
	local monotonic, spinOK, last = true, true, -1
	for i = 0, 160 do
		local t = C.SpinSeconds * i / 160
		local f = RebirthCelebration.at(t, false)
		monotonic = monotonic and f.spin >= last - 1e-9 and f.orbRise == f.spin
		last = f.spin
		spinOK = spinOK and f.held == (t < C.SpinSeconds)
	end
	local S = C.SpinSeconds
	check(monotonic and near(RebirthCelebration.at(S * 0.5, false).spin, 0.5)
			and RebirthCelebration.at(S * 0.1, false).spin < 0.05 and RebirthCelebration.at(S * 0.9, false).spin > 0.95
			and RebirthCelebration.at(S, false).spin == 1,
		"the spin only ever goes forward, slow in and slow out, exactly round at SpinSeconds")
	check(spinOK and not RebirthCelebration.at(S, false).held, "the camera and the controls are held for the spin only")
	check(not RebirthCelebration.at(S - 0.001, false).burst and RebirthCelebration.at(S, false).burst
			and RebirthCelebration.at(S + 0.5, false).burst,
		"the burst goes at SpinSeconds")
	check(RebirthCelebration.at(S * 0.5, false).orbAlpha == 1
			and near(RebirthCelebration.at(S + C.Orbs.FadeSeconds, false).orbAlpha, 0),
		"the orbs shine through the spin and fade with its end")
	local fadeAt = C.Seconds - C.FadeSeconds
	check(RebirthCelebration.at(fadeAt, false).popAlpha == 1
			and near(RebirthCelebration.at(fadeAt + C.FadeSeconds * 0.5, false).popAlpha, 0.5)
			and not RebirthCelebration.at(C.Seconds, false).popup and RebirthCelebration.at(C.Seconds, false).done
			and not RebirthCelebration.at(C.Seconds - 0.01, false).done,
		"the card fades over FadeSeconds and everything is over at Seconds")

	--==========================================================================
	say("3. REDUCED FX")
	--==========================================================================
	local still = true
	for i = 0, 70 do
		local t = C.Seconds * i / 70
		local f = RebirthCelebration.at(t, true)
		still = still and f.flash == 0 and f.column == 0 and f.columnAlpha == 0 and f.spin == 0 and not f.held
			and f.orbAlpha == 0 and f.rays == 0 and f.rayAngle == 0 and not f.burst and f.popScale == 1
	end
	local r0 = RebirthCelebration.at(0, true)
	check(still, "no flash, column, spin, orbs, rays or burst at any moment, and the card never swells")
	check(r0.popup and r0.popAlpha == 1 and RebirthCelebration.at(C.Seconds, true).done,
		"the card simply appears at once, and goes at the same end")

	--==========================================================================
	say("4. The turn and the orbs")
	--==========================================================================
	local roundTrip, faces, inRange = true, true, true
	for a = -6, 6 do
		local y = a * 0.53
		roundTrip = roundTrip and near(RebirthCelebration.yaw(CFrame.Angles(0, y, 0).LookVector),
			RebirthCelebration.wrap(y), 1e-6)
		for b = -6, 6 do
			local face = b * 0.49
			local total = RebirthCelebration.turn(y, face)
			inRange = inRange and total / TAU >= C.SpinTurns - 0.5 - 1e-9 and total / TAU <= C.SpinTurns + 0.5 + 1e-9
			local look = CFrame.Angles(0, y + total, 0).LookVector
			local want = CFrame.Angles(0, face, 0).LookVector
			faces = faces and look:Dot(want) > 0.99999
		end
	end
	check(roundTrip, "a heading read off a look vector comes back the same")
	check(faces and inRange, "the turn is SpinTurns round, give or take half, and always ends looking where it was told")
	-- The body turns by +yaw, which carries +X towards -Z (a positive cross
	-- product's Y); the ring going the other way gives a negative one.
	local opposite = true
	local prev = RebirthCelebration.orb(1, RebirthCelebration.at(0, false))
	for i = 1, 20 do
		local now = RebirthCelebration.orb(1, RebirthCelebration.at(S * i / 20, false))
		local cross = Vector3.new(prev.X, 0, prev.Z):Cross(Vector3.new(now.X, 0, now.Z))
		opposite = opposite and cross.Y <= 1e-9
		prev = now
	end
	local bodyCross = Vector3.new(1, 0, 0):Cross(CFrame.Angles(0, 0.1, 0):VectorToWorldSpace(Vector3.new(1, 0, 0)))
	local low = RebirthCelebration.orb(3, RebirthCelebration.at(0, false))
	local high = RebirthCelebration.orb(3, RebirthCelebration.at(S, false))
	local ringOK = true
	local fRing = RebirthCelebration.at(S * 0.37, false)
	for i = 1, C.Orbs.Count do
		local v = RebirthCelebration.orb(i, fRing)
		ringOK = ringOK and near(Vector3.new(v.X, 0, v.Z).Magnitude, C.Orbs.Radius, 1e-6)
	end
	check(opposite and bodyCross.Y > 0, "the orbs go round the other way to the body")
	check(near(low.Y, C.Orbs.FromY) and near(high.Y, C.Orbs.ToY) and ringOK,
		"eight orbs on one ring of Radius, rising from the feet to over the head")

	--==========================================================================
	say("5. The words")
	--==========================================================================
	local w6 = RebirthCelebration.words(6, 4, 2.5)
	local _, botanist = Rebirth.titleFor(6)
	check(w6.reborn == "REBORN!" and w6.line == "REBIRTH 6 · BOTANIST II" and w6.bonus == "x4 training · x2.5 income"
			and w6.colour == botanist.Colour and not w6.rainbow,
		"the card at 6: REBORN!, REBIRTH 6 · BOTANIST II, x4 training · x2.5 income, in BOTANIST's colour",
		w6.line .. " / " .. w6.bonus)
	local w1 = RebirthCelebration.words(1, "junk", -5)
	check(w1.line == "REBIRTH 1 · SPROUT" and w1.bonus == "x1.5 training · x1.25 income",
		"numbers that are not numbers read as Rebirth's own", w1.bonus)
	local w298 = RebirthCelebration.words(298)
	check(w298.rainbow and w298.line == "REBIRTH 298 · GAIA I" and not RebirthCelebration.words(297).rainbow
			and RebirthCelebration.words(1000).line == "REBIRTH 1000 · GAIA V",
		"GAIA's card line is the rainbow (GAIA V from 302 on); GENESIS SOUL's is not")
	check(RebirthCelebration.serverLine("Pat", 6) == "Pat reached REBIRTH 6 · BOTANIST II!"
			and RebirthCelebration.serverLine("Pat", 298) == "Pat reached REBIRTH 298 · GAIA I!",
		"the line for everybody else: \"Pat reached REBIRTH 6 · BOTANIST II!\"")
	local longest = RebirthCelebration.serverLine(string.rep("W", 20), 134)
	check(#longest <= Notice.ServerTitleMax, "the longest line (a 20-letter name at ELDERWOOD WARDEN III) is never cut",
		#longest)
	-- THE 100 TITLES (2026-10-10): the leaves and sparkles wear the title's family's palette.
	local TITLE = CFG.Title
	local seedlight = TITLE.Families[1]
	local tint6 = RebirthCelebration.tint(6)
	local tint298 = RebirthCelebration.tint(298)
	local tint144 = RebirthCelebration.tint(144)
	check(#tint6.Keypoints == 2 and tint6.Keypoints[1].Value == seedlight.Primary
			and tint6.Keypoints[2].Value == seedlight.Secondary and #tint298.Keypoints > 2
			and tint144.Keypoints[1].Value == TITLE.Families[6].Primary,
		"leaves and sparkles in the family's palette (Garden apprentices' green to lime at 6, World Tree's gold at "
			.. "144), the rainbow at GAIA")

	--==========================================================================
	say("5b. The accent at the burst (2026-10-10, the 100 titles)")
	--==========================================================================
	local a6 = RebirthCelebration.accent(6)
	local a8 = RebirthCelebration.accent(8)
	local a144 = RebirthCelebration.accent(144)
	local a145 = RebirthCelebration.accent(145)
	local a52 = RebirthCelebration.accent(52)
	local a303 = RebirthCelebration.accent(303)
	local aJump = RebirthCelebration.accent(50, 4)
	check(a6.change == "rank" and a6.pulse and a6.signature == nil and a6.leaves == C.Motes.Leaves
			and a6.sparkles == C.Motes.Sparkles and C.Motes.Leaves < C.Leaves.Count
			and C.Motes.Sparkles < C.Sparkles.Count,
		"a rank only (BOTANIST II at 6): a few motes and the title's pulse, never the full accent")
	check(a8.change == "name" and a8.signature == "Seedlight" and not a8.pulse and a8.leaves == 0 and a8.sparkles == 0
			and a144.signature == "Halo" and a144.family == TITLE.Families[6]
			and a145.change == "rank" and a145.signature == nil and a145.pulse,
		"a new name in a prototype family: its own accent (LEAF TENDER I, Seedlight; WORLD TREE I, World Tree Halo)")
	check(a52.change == "name" and a52.signature == nil and not a52.pulse and a52.leaves == C.Leaves.Count
			and a52.sparkles == C.Sparkles.Count and a52.family == TITLE.Families[3]
			and a303.change == "rank" and a303.pulse and aJump.change == "name",
		"any other new name (THORN KNIGHT I): the full leaves and sparkles in its palette; GAIA V kept is a rank")
	-- The pulse, and the two signatures' poses: inside the celebration, from nothing back to nothing.
	local P = C.Pulse
	check(RebirthCelebration.pulse(0) == 1 and RebirthCelebration.pulse(P.Seconds) == 1
			and near(RebirthCelebration.pulse(P.Seconds / 2), P.Scale, 1e-9) and P.Scale <= 1.25
			and C.SpinSeconds + P.Seconds <= C.Seconds,
		"the pulse grows the words to Scale halfway and back, inside the celebration")
	local SL, H = C.Seedlight, C.Halo
	local arcOk, haloOk = true, true
	for i = 1, SL.Leaves do
		local before, a0 = RebirthCelebration.seedlightLeaf(i, SL.Leaves, -0.01)
		local start = RebirthCelebration.seedlightLeaf(i, SL.Leaves, (i - 1) * SL.Stagger)
		local mid, aMid = RebirthCelebration.seedlightLeaf(i, SL.Leaves, (i - 1) * SL.Stagger + SL.ArcSeconds / 2)
		local _, aEnd = RebirthCelebration.seedlightLeaf(i, SL.Leaves, (i - 1) * SL.Stagger + SL.ArcSeconds)
		arcOk = arcOk and a0 == 0 and aEnd < 1e-6 and aMid == 1 and start.X < 0 and math.abs(mid.X) < 0.05
			and mid.Y > start.Y and near(Vector3.new(mid.X, mid.Y / 0.75, 0).Magnitude, SL.Radius, 1e-6)
			and before.Z == 0
	end
	for i = 1, H.Leaves do
		local _, a0 = RebirthCelebration.haloLeaf(i, H.Leaves, 0)
		local open, aMid = RebirthCelebration.haloLeaf(i, H.Leaves, H.Seconds * 0.4)
		local wide, aEnd = RebirthCelebration.haloLeaf(i, H.Leaves, H.Seconds)
		haloOk = haloOk and a0 == 0 and aEnd == 0 and aMid == 1 and open.Y >= H.Above
			and Vector3.new(wide.X, 0, wide.Z).Magnitude > Vector3.new(open.X, 0, open.Z).Magnitude
			and near(Vector3.new(wide.X, 0, wide.Z).Magnitude, H.To, 1e-6)
	end
	check(arcOk and C.SpinSeconds + (SL.Leaves - 1) * SL.Stagger + SL.ArcSeconds <= C.Seconds,
		"Seedlight: each leaf rides one arc over the head from the left shoulder to the right, unseen before and after")
	check(haloOk and RebirthCelebration.haloRays(0) == 0 and RebirthCelebration.haloRays(H.RaysSeconds) == 0
			and RebirthCelebration.haloRays(H.RaysSeconds / 2) > 0.99 and C.SpinSeconds + H.Seconds <= C.Seconds,
		"World Tree Halo: the ring opens over the head from From to To studs while it turns, then fades; the rays in "
			.. "and out")

	--==========================================================================
	say("6. Who sees it: the real RebirthService")
	--==========================================================================
	local events = {}
	local profiles, made = {}, 0
	local fakePDS = {
		Get = function(p)
			return profiles[p]
		end,
		IsReady = function(p)
			return profiles[p] ~= nil
		end,
		AddCash = function(p, amount)
			profiles[p].Cash = math.max(0, profiles[p].Cash + amount)
		end,
		SetMillTier = function(p, t)
			profiles[p].MillTier = t
		end,
		UpdateRebirth = function(p, change)
			if change(profiles[p]) then
				p:SetAttribute(CFG.Attributes.Rebirths, profiles[p].Rebirths)
				return true
			end
			return false
		end,
		Save = function()
			table.insert(events, "save")
			return true
		end,
	}
	local siblings = {
		PlayerDataService = fakePDS,
		PlotService = {
			PlotOf = function()
				return nil
			end,
			OwnerOf = function()
				return nil
			end,
			OnAssigned = function()
				return function() end
			end,
			OnReleased = function()
				return function() end
			end,
			OnResized = function()
				return function() end
			end,
		},
		TreadmillService = { Unmount = function() end, Rebuild = function() end },
		CarryService = { IsCarrying = function()
			return false
		end },
		StoreService = { Deciding = function()
			return false
		end },
	}
	local parent = {}
	function parent:WaitForChild(childName)
		assert(siblings[childName] ~= nil, "unexpected sibling " .. childName)
		return { __standIn = siblings[childName] }
	end
	local outerRequire = require
	local chunk = assert(loadstring(sourceOf(Server, "RebirthService"), "=RebirthService"))
	setfenv(chunk, setmetatable({
		script = { Name = "RebirthService", Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	local Service = chunk()
	local everybody = {}
	local sent = {}
	Service.Hooks.now = function()
		return 1791500000
	end
	Service.Hooks.clock = function()
		return 50
	end
	Service.Hooks.distance = function()
		return 5
	end
	Service.Hooks.reply = function(_, payload)
		table.insert(events, "reply:" .. tostring(payload.verb))
	end
	Service.Hooks.send = function(p, action, payload)
		table.insert(events, "send:" .. tostring(action))
		table.insert(sent, { to = p, action = action, payload = payload })
	end
	Service.Hooks.players = function()
		return everybody
	end
	-- Simulated ids only (from 90,000,000,000).
	local function fakePlayer(label, at)
		made += 1
		local attrs = {}
		local p = { Name = label, DisplayName = label, UserId = 90000000000 + made }
		function p:GetAttribute(k)
			return attrs[k]
		end
		function p:SetAttribute(k, v)
			attrs[k] = v
		end
		if at then
			local model = Instance.new("Model")
			model.Name = "ZZCelebrate_" .. label
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored = true
			root.Position = at
			root.Parent = model
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Anchored = true
			head.Position = at + Vector3.new(0, 2, 0)
			head.Parent = model
			Instance.new("Humanoid").Parent = model
			model.Parent = scratch
			p.Character = model
		end
		return p
	end
	local hero = fakePlayer("Hero", Vector3.new(45, 3, 36))
	local close = fakePlayer("Close", Vector3.new(45 + 50, 3, 36))
	local edge = fakePlayer("Edge", Vector3.new(45, 3, 36 + 119.9))
	local beyond = fakePlayer("Beyond", Vector3.new(45 + 120.5, 3, 36))
	local bodiless = fakePlayer("Bodiless", nil)
	local far = fakePlayer("Far", Vector3.new(45 + 900, 3, 36))
	everybody = { hero, close, edge, beyond, bodiless, far }
	local seen, told = Service.Celebrate(hero, 6)
	local celebrated, lined = {}, {}
	local heroGot, payloadsOK = false, true
	for _, s in ipairs(sent) do
		if s.to == hero then
			heroGot = true
		elseif s.action == CFG.Action then
			table.insert(celebrated, s.to.Name)
			payloadsOK = payloadsOK and s.payload.verb == "celebrate" and s.payload.userId == hero.UserId
				and s.payload.rebirths == 6
		elseif s.action == Notice.ServerNotice then
			table.insert(lined, s.to.Name)
		end
	end
	table.sort(celebrated)
	table.sort(lined)
	check(table.concat(celebrated, ",") == "Close,Edge" and seen == 2 and payloadsOK,
		"the celebration goes to every body within 120 studs (50 and 119.9), with who and to what -- not to "
			.. "120.5, 900 or no body", table.concat(celebrated, ","))
	check(table.concat(lined, ",") == "Beyond,Bodiless,Close,Edge,Far" and told == 5 and not heroGot,
		"the line goes to everybody else in the server, near or far; the reborn player gets neither",
		table.concat(lined, ","))
	local line = nil
	for _, s in ipairs(sent) do
		if s.action == Notice.ServerNotice then
			line = s.payload
			break
		end
	end
	local post = Notice.readServerNotice(line)
	check(line and line.title == "Hero reached REBIRTH 6 · BOTANIST II!" and line.quiet == true and line.icon == "rebirth"
			and post and post.kind == "info" and post.icon == "rebirth" and post.quiet == true
			and post.key == "server:rebirth:" .. hero.UserId .. ":6",
		"the line: the name, the count and the title; quiet, with the emblem; ActionToastUI's reader takes it whole",
		line and line.title)

	-- Through the real Confirm: the save, then "done", then everybody else.
	table.clear(events)
	table.clear(sent)
	profiles[hero] = { Cash = 3.5e9, MillTier = 9, Rebirths = 0, RebirthAt = 0 }
	local q = Service.Quote(hero)
	local done = Service.Confirm(hero, { token = q.token })
	local order = table.concat(events, " ")
	local iSave = table.find(events, "save")
	local iDone = table.find(events, "reply:done")
	local iSend = table.find(events, "send:" .. CFG.Action)
	check(done == true and iSave and iDone and iSend and iSave < iDone and iDone < iSend,
		"a real rebirth: saved, then told \"done\", and only then shown to the others", order)
	local heroTitle = hero.Character.Head:FindFirstChild(CFG.Title.Name)
	if heroTitle then
		heroTitle:Destroy()
	end

	--==========================================================================
	say("7. The card on every listed screen")
	--==========================================================================
	local TOPBAR, BAR_LEFT = 58, 208
	local function rect(x, y, w, h)
		return { x = x, y = y, w = w, h = h }
	end
	local function screen(w, h, touch, keyboard, inset)
		inset = inset or 0
		return {
			safe = Vector2.new(w - inset * 2, h - TOPBAR - (if inset > 0 then 21 else 0)),
			touch = touch,
			keyboard = keyboard,
			viewport = Vector2.new(w, h),
			topbar = rect(BAR_LEFT, 0, w - BAR_LEFT, TOPBAR),
			insetTop = TOPBAR,
		}
	end
	local DESKS = { { 1280, 720 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 1000, 609 }, { 1167, 716 } }
	local PHONES = { { 640, 360 }, { 705, 338 }, { 772, 360 }, { 801, 392 }, { 874, 402, 62 }, { 896, 414, 48 },
		{ 956, 440, 62 }, { 844, 390, 47 } }
	local P = C.Popup
	local bad, scales = {}, {}
	local overToastOn = {}
	local smallest = math.huge
	local function try(tag, input, phone)
		local L = HudLayout.solve(input)
		-- The notices' line is soft (RebirthFX, 2026-10-09): kept off wherever the
		-- card still draws at Readable, given way to only where that draws it larger.
		local avoid = HudLayout.occupiedButToast(L)
		local r, s = RebirthCelebration.popup(L.safe, avoid, phone, { L.toast })
		local _, kept = RebirthCelebration.popup(L.safe, HudLayout.occupied(L), phone)
		local t = L.toast
		local overToast = t.w > 0 and r.x < t.x + t.w + P.Gap and t.x < r.x + r.w + P.Gap
			and r.y < t.y + t.h + P.Gap and t.y < r.y + r.h + P.Gap
		if overToast then
			table.insert(overToastOn, tag)
			if not (kept < P.Readable - 1e-9 and s > kept + 1e-9) then
				table.insert(bad, string.format("%s: over the notices' line though keeping off it draws %.2f", tag, kept))
			end
		end
		local inside = r.x >= P.Gap and r.y >= P.Gap and r.x + r.w <= L.safe.X - P.Gap and r.y + r.h <= L.safe.Y - P.Gap
		local clear = true
		for _, a in ipairs(avoid) do
			if a.w > 0 and a.h > 0 and r.x < a.x + a.w + P.Gap and a.x < r.x + r.w + P.Gap
				and r.y < a.y + a.h + P.Gap and a.y < r.y + r.h + P.Gap then
				clear = false
			end
		end
		local top = if phone then GameConfig.MenuSize.PhoneScale else 1
		-- Off the middle only as far as a corner's buttons push it.
		local off = (r.x + r.w / 2) - L.safe.X / 2
		if not inside or not clear or r.y + r.h / 2 > L.safe.Y / 2 or s > top + 1e-9 or s < P.MinScale - 1e-9
			or math.abs(off) > L.safe.X * 0.15 then
			table.insert(bad, string.format("%s: %d,%d %dx%d at %.2f, %+d off the middle%s%s", tag, r.x, r.y, r.w, r.h,
				s, off, if inside then "" else " OUTSIDE", if clear then "" else " OVER THE HUD"))
		end
		table.insert(scales, string.format("%s %.2f%s", tag, s,
			if math.abs(off) >= 1 then string.format(" (%+d)", off) else ""))
		if phone then
			smallest = math.min(smallest, s)
		end
		return s
	end
	for _, d in ipairs(DESKS) do
		local s = try(string.format("desk %dx%d", d[1], d[2]), screen(d[1], d[2], false, true), false)
		if s < 1 - 1e-9 then
			table.insert(bad, string.format("desk %dx%d drawn smaller (%.2f)", d[1], d[2], s))
		end
	end
	for _, d in ipairs(PHONES) do
		try(string.format("phone %dx%d", d[1], d[2]), screen(d[1], d[2], true, false, d[3]), true)
	end
	check(#bad == 0, "on every listed desktop (whole size) and phone (at most 85%): inside the safe area, clear of "
		.. "every HUD rect, in the upper half", table.concat(bad, "; "))
	say("    the card's scale: " .. table.concat(scales, ", "))
	say("    over the notices' line, to stay readable: " .. (if #overToastOn > 0 then table.concat(overToastOn, ", ")
		else "none"))
	local fxSrc = (Shared:FindFirstChild("RebirthFX") :: ModuleScript).Source
	check(P.Readable == 0.66 and string.find(fxSrc, "RebirthCelebration.popup(L.safe, HudLayout.occupiedButToast(L), "
			.. "phone, { L.toast })", 1, true) ~= nil,
		"the card keeps off the notices' line unless that would draw it under Popup.Readable (0.66), where it gives way")
	-- The longest words, at the size the card draws them on the smallest phone.
	local room = RebirthFX.cardRoom()
	local small = {}
	for _, n in ipairs({ 1, 4, 6, 16, 23, 50, 74, 100, 133, 134, 187, 264, 267, 298, 302, 303, 1000, 4200 }) do
		local w = RebirthCelebration.words(n)
		for _, part in ipairs({ { "Line", w.line }, { "Bonus", w.bonus }, { "Reborn", w.reborn } }) do
			local key = part[1]
			local need = RebirthFX.textWidth(part[2], RebirthFX.Sizes[key], RebirthFX.Fonts[key])
			local size = Rebirth.fitSize(RebirthFX.Sizes[key], need, room)
			local drawn = size * smallest
			if drawn < 12 then
				table.insert(small, string.format("%d %s %.1f px", n, key, drawn))
			end
		end
	end
	check(#small == 0, "every line it can say (ELDERWOOD WARDEN III the longest) is 12 px or more on the smallest phone's card",
		table.concat(small, "; "))

	--==========================================================================
	say("8. Whole celebrations, stepped by hand")
	--==========================================================================
	local function body(label, at)
		local model = Instance.new("Model")
		model.Name = "ZZBody_" .. label
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Size = Vector3.new(2, 2, 1)
		root.CFrame = CFrame.new(at)
		root.Parent = model
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Anchored = true
		head.Parent = model
		local humanoid = Instance.new("Humanoid")
		humanoid.HipHeight = 2
		humanoid.Parent = model
		model.Parent = scratch
		return model, root, humanoid
	end
	local worldBox = Instance.new("Folder")
	worldBox.Name = "World"
	worldBox.Parent = scratch
	local guiBox = Instance.new("Folder")
	guiBox.Name = "Guis"
	guiBox.Parent = scratch

	-- A. This player's own, whole: built, held, turned to face the camera,
	-- handed back, gone.
	local hero2, root2, hum2 = body("Own", Vector3.new(0, 10, 0))
	hum2.AutoRotate = true
	local camera = {
		CameraType = Enum.CameraType.Custom,
		CFrame = CFrame.lookAt(Vector3.new(6, 16, 14), Vector3.new(0, 10, 0)),
		CameraSubject = hum2,
	}
	local startCam = camera.CFrame
	local sounds = {}
	local handle = RebirthFX.play({
		character = hero2,
		own = true,
		rebirths = 6,
		training = 4,
		income = 2.5,
		reduced = false,
		manual = true,
		world = worldBox,
		gui = guiBox,
		camera = camera,
		phone = true,
		sound = function(isOwn, root)
			table.insert(sounds, { own = isOwn, root = root })
		end,
	})
	local world = worldBox:FindFirstChild(RebirthFX.Names.World)
	local cardGui = guiBox:FindFirstChild(RebirthFX.Names.Card)
	local flashGui = guiBox:FindFirstChild(RebirthFX.Names.Flash)
	local card = cardGui and cardGui:FindFirstChild("Card")
	check(handle ~= nil and world and world:FindFirstChild("Column") and world:FindFirstChild("ColumnGlow")
			and world:FindFirstChild("Anchor") and #world.Anchor:GetChildren() >= C.Orbs.Count
			and world:FindFirstChild("Burst", true) and world:FindFirstChild("GroundBurst", true)
			and world:FindFirstChild("Leaves", true) and world:FindFirstChild("Sparkles", true),
		"the world pieces: the column and its glow, eight orbs, the burst (front and ground), the leaves, the sparkles")
	check(cardGui and flashGui and card and card:FindFirstChild("Rays") and card:FindFirstChild("Plate") == nil
			and card:FindFirstChild("Emblem") and card:FindFirstChild("Logo") and card:FindFirstChild("Reborn") == nil
			and card:FindFirstChild("Line") and card:FindFirstChild("Bonus")
			and card.Line.Text == "REBIRTH 6 · BOTANIST II" and card.Emblem.Image == CFG.Art.Emblem
			and card.Logo.Image == C.Logo,
		"the own screen: the flash, and the card -- the rays, the owner's emblem, the REBORN! logo and two lines")
	-- TRANSPARENT (the owner, 2026-10-09): nothing on the card draws a background or a border edge.
	local drawn = {}
	if card then
		local all = card:GetDescendants()
		table.insert(all, card)
		for _, d in ipairs(all) do
			if d:IsA("GuiObject") and d.BackgroundTransparency < 1 and d.Name ~= "Ray" then
				table.insert(drawn, d.Name)
			elseif d:IsA("UIStroke") and d.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then
				table.insert(drawn, d.Parent.Name .. ".edge")
			end
		end
	end
	check(card ~= nil and #drawn == 0, "TRANSPARENT: no plate and no rim behind the card's words",
		table.concat(drawn, ", "))
	local burstImage = card.Rays:FindFirstChild("Burst")
	check(#card.Rays:GetChildren() == 1 and burstImage and burstImage:IsA("ImageLabel")
			and burstImage.Image == C.Rays and burstImage.ImageColor3 == C.RayColour,
		"the rays are the owner's sunburst, tinted RayColour; no drawn bars beside it")
	check(#sounds == 1 and sounds[1].own == true and sounds[1].root == root2, "the fanfare once, flat, at the start")
	check(camera.CameraType == Enum.CameraType.Scriptable and camera.CFrame == startCam and hum2.AutoRotate == false
			and hum2:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false and RebirthFX.celebrating(hero2),
		"held at once: the camera still where it was, the body's own turning and its jump off")
	local burstEmitter = world:FindFirstChild("Burst", true)
	check(burstEmitter.FlipbookLayout == Enum.ParticleFlipbookLayout.Grid4x4
			and burstEmitter.FlipbookMode == Enum.ParticleFlipbookMode.OneShot and burstEmitter.Texture == T.Burst
			and burstEmitter.ZOffset < 0,
		"the burst plays the 4 x 4 sheet once, behind the body")
	local leafEmitter = world:FindFirstChild("Leaves", true)
	local sparkEmitter = world:FindFirstChild("Sparkles", true)
	check(leafEmitter.FlipbookLayout == Enum.ParticleFlipbookLayout.Grid2x2
			and leafEmitter.FlipbookMode == Enum.ParticleFlipbookMode.PingPong
			and sparkEmitter.FlipbookMode == Enum.ParticleFlipbookMode.OneShot
			and leafEmitter.Color.Keypoints[1].Value == seedlight.Primary
			and sparkEmitter.Color.Keypoints[1].Value == seedlight.Primary
			and world:FindFirstChild("SeedlightLeaf", true) == nil and world:FindFirstChild("Pollen", true) == nil,
		"the leaves tumble back and forth (their last frame jumps), the sparkles once; both in Garden apprentices' "
			.. "palette; a rank only (BOTANIST II) wears no signature")
	check(leafEmitter.Lifetime.Max + C.SpinSeconds <= C.Seconds and sparkEmitter.Lifetime.Max + C.SpinSeconds <= C.Seconds
			and burstEmitter.Lifetime.Max + C.SpinSeconds <= C.Seconds,
		"every particle has lived its life before the celebration ends")
	handle.step(0.3)
	local flashFrame = flashGui:FindFirstChild("Flash")
	check(flashFrame.Visible and flashFrame.BackgroundTransparency < 1 and not card.Visible
			and world.Column.Transparency < 1,
		"at 0.3 s: the flash fading, the column up, no card yet")
	handle.step(1.0)
	local yawMid = RebirthCelebration.yaw(root2.CFrame.LookVector)
	check(card.Visible and card.Rays.Burst.ImageTransparency < 1 and camera.CameraType == Enum.CameraType.Scriptable
			and not flashFrame.Visible,
		"at 1.0 s: the card up with its rays, still held")
	handle.step(C.SpinSeconds)
	local toCamera = startCam.Position - root2.Position
	local flat = Vector3.new(toCamera.X, 0, toCamera.Z).Unit
	check(camera.CameraType == Enum.CameraType.Custom and camera.CFrame == startCam and camera.CameraSubject == hum2
			and hum2.AutoRotate == true and hum2:GetStateEnabled(Enum.HumanoidStateType.Jumping) == true,
		"at SpinSeconds everything is handed back exactly: the camera's type, place and subject, turning and jump")
	check(root2.CFrame.LookVector:Dot(flat) > 0.999 and yawMid ~= RebirthCelebration.yaw(root2.CFrame.LookVector),
		"and the body has spun round to face the camera", root2.CFrame.LookVector:Dot(flat))
	handle.step(2.0)
	handle.step(3.0)
	check(card.Visible and handle.finished() == false, "at 3.0 s the card is still up")
	handle.step(C.Seconds)
	check(handle.finished() and #worldBox:GetChildren() == 0 and #guiBox:GetChildren() == 0
			and not RebirthFX.celebrating(hero2) and camera.CameraType == Enum.CameraType.Custom,
		"at Seconds every piece is gone: nothing left in the world or the guis",
		#worldBox:GetDescendants() + #guiBox:GetDescendants())

	-- B. REDUCED FX: the card at once, the fanfare, nothing else, nothing touched.
	local hero3, _, hum3 = body("Reduced", Vector3.new(20, 10, 0))
	hum3.AutoRotate = true
	local camera3 = { CameraType = Enum.CameraType.Custom, CFrame = CFrame.new(20, 16, 14), CameraSubject = hum3 }
	local sounds3 = {}
	local h3 = RebirthFX.play({
		character = hero3,
		own = true,
		rebirths = 6,
		reduced = true,
		manual = true,
		world = worldBox,
		gui = guiBox,
		camera = camera3,
		phone = false,
		sound = function(isOwn)
			table.insert(sounds3, isOwn)
		end,
	})
	local world3 = worldBox:FindFirstChild(RebirthFX.Names.World)
	local cardGui3 = guiBox:FindFirstChild(RebirthFX.Names.Card)
	local card3 = cardGui3 and cardGui3:FindFirstChild("Card")
	check(world3 and #world3:GetDescendants() == 0 and guiBox:FindFirstChild(RebirthFX.Names.Flash) == nil
			and card3 and card3.Visible and card3:FindFirstChild("Rays") == nil,
		"REDUCED FX: no world piece, no flash, no rays -- the card is up at once")
	check(camera3.CameraType == Enum.CameraType.Custom and hum3.AutoRotate == true and #sounds3 == 1
			and sounds3[1] == true,
		"the camera and the body untouched; the fanfare still plays")
	h3.step(C.Seconds)
	check(h3.finished() and #worldBox:GetChildren() == 0 and #guiBox:GetChildren() == 0, "and it all goes at the end")

	-- C. Somebody else's: the world pieces round their body and the fanfare
	-- from it; no card, no camera.
	local other, otherRoot = body("Other", Vector3.new(40, 10, 0))
	local sounds4 = {}
	local h4 = RebirthFX.play({
		character = other,
		own = false,
		rebirths = 298,
		reduced = false,
		manual = true,
		world = worldBox,
		gui = guiBox,
		sound = function(isOwn, root)
			table.insert(sounds4, { own = isOwn, root = root })
		end,
	})
	local world4 = worldBox:FindFirstChild(RebirthFX.Names.World)
	check(world4 and world4:FindFirstChild("Column") and #guiBox:GetChildren() == 0 and #sounds4 == 1
			and sounds4[1].own == false and sounds4[1].root == otherRoot,
		"somebody else's: the column, the orbs and the burst round their body, the fanfare from it, no card")
	check(#world4:FindFirstChild("Leaves", true).Color.Keypoints > 2, "GAIA's leaves are the rainbow")
	h4.step(C.SpinSeconds + 0.1)
	h4.step(C.Seconds)
	check(h4.finished() and #worldBox:GetChildren() == 0, "and gone at the end")

	-- D. GAIA on the own card: the rainbow line.
	local hero5 = body("Gaia", Vector3.new(60, 10, 0))
	local h5 = RebirthFX.play({
		character = hero5,
		own = true,
		rebirths = 298,
		reduced = false,
		manual = true,
		world = worldBox,
		gui = guiBox,
		camera = { CameraType = Enum.CameraType.Custom, CFrame = CFrame.new(60, 16, 14), CameraSubject = nil },
		phone = false,
		sound = function() end,
	})
	local line5 = guiBox[RebirthFX.Names.Card].Card.Line
	check(line5.Text == "REBIRTH 298 · GAIA I" and line5:FindFirstChild("Rainbow") ~= nil
			and line5.TextColor3 == Color3.new(1, 1, 1),
		"GAIA's card line: white words under the turning rainbow")
	-- E. Played again before it ends: the first is stopped and handed back.
	local camera5b = { CameraType = Enum.CameraType.Custom, CFrame = CFrame.new(60, 20, 20), CameraSubject = nil }
	local h5b = RebirthFX.play({
		character = hero5,
		own = true,
		rebirths = 299,
		reduced = false,
		manual = true,
		world = worldBox,
		gui = guiBox,
		camera = camera5b,
		phone = false,
		sound = function() end,
	})
	check(h5.finished() and not h5b.finished() and #guiBox:GetChildren() == 2,
		"a second celebration on the same body stops the first: one card, one flash")
	-- F. The body gone midway: everything handed back and destroyed on the
	-- next frame.
	hero5.HumanoidRootPart.Parent = nil
	h5b.step(0.5)
	check(h5b.finished() and camera5b.CameraType == Enum.CameraType.Custom and #worldBox:GetChildren() == 0
			and #guiBox:GetChildren() == 0,
		"a body lost midway: the camera handed back and every piece gone at once")

	-- G. THE TWO PROTOTYPES (2026-10-10): Seedlight at LEAF TENDER I (8), World
	-- Tree Halo at WORLD TREE I (144) -- somebody else's, stepped by hand.
	local seedBody = body("Seedlight", Vector3.new(100, 10, 0))
	local hs = RebirthFX.play({ character = seedBody, own = false, rebirths = 8, reduced = false, manual = true,
		world = worldBox, gui = guiBox, sound = function() end })
	local ws = worldBox:FindFirstChild(RebirthFX.Names.World)
	local seedLeaves = {}
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Name == "SeedlightLeaf" then
			table.insert(seedLeaves, d)
		end
	end
	local leafImage = seedLeaves[1] and seedLeaves[1]:FindFirstChild("Leaf")
	check(#seedLeaves == C.Seedlight.Leaves and ws:FindFirstChild("Pollen", true) and ws:FindFirstChild("Twinkles", true)
			and leafImage and leafImage.Image == T.Leaf and leafImage.ImageTransparency == 1
			and (leafImage.ImageColor3 == seedlight.Primary or leafImage.ImageColor3 == seedlight.Secondary),
		"Seedlight: its leaves on the arc (the white leaf in the family's palette, unseen till the burst), the pollen "
			.. "and the twinkles")
	hs.step(C.SpinSeconds + C.Seedlight.ArcSeconds / 2)
	local midLeaf = seedLeaves[1]
	check(midLeaf.Leaf.ImageTransparency < 0.5 and midLeaf.StudsOffset.Y > 0,
		"halfway along the arc a leaf shows, over the head")
	hs.step(C.Seconds)
	check(hs.finished() and #worldBox:GetChildren() == 0, "and it is all gone at the end")
	local haloBody = body("Halo", Vector3.new(120, 10, 0))
	local hh = RebirthFX.play({ character = haloBody, own = false, rebirths = 144, reduced = false, manual = true,
		world = worldBox, gui = guiBox, sound = function() end })
	local wh = worldBox:FindFirstChild(RebirthFX.Names.World)
	local haloLeaves = {}
	for _, d in ipairs(wh:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Name == "HaloLeaf" then
			table.insert(haloLeaves, d)
		end
	end
	local rays = wh:FindFirstChild("HaloRays", true)
	check(#haloLeaves == C.Halo.Leaves and wh:FindFirstChild("Pollen", true) and wh:FindFirstChild("Twinkles", true) == nil
			and (C.Rays == "" or (rays and rays.Rays.Image == C.Rays and rays.Rays.ImageColor3 == C.Halo.Gold)),
		"World Tree Halo: its ring of leaves, gold pollen and the owner's sunburst behind the head")
	local headOf = haloBody:FindFirstChild("Head")
	hh.step(C.SpinSeconds + C.Halo.Seconds * 0.5)
	local att = haloLeaves[1].Parent
	local fromHead = att.WorldPosition - headOf.Position
	check(att:IsA("Attachment") and fromHead.Y > C.Halo.Above - 0.01 and haloLeaves[1].Leaf.ImageTransparency < 0.5
			and Vector3.new(fromHead.X, 0, fromHead.Z).Magnitude > C.Halo.From,
		"halfway, a leaf of the ring shows over the head, the ring opening", tostring(fromHead))
	hh.step(C.Seconds)
	check(hh.finished() and #worldBox:GetChildren() == 0, "and it is all gone at the end")
	-- H. A rank only marks the title over that head for its pulse (OwnerTitleUI grows it); a new name does not.
	local pulseBody = body("Pulse", Vector3.new(140, 10, 0))
	local pulseTitle = Instance.new("BillboardGui")
	pulseTitle.Name = TITLE.Name
	pulseTitle.Parent = pulseBody:FindFirstChild("Head")
	local hp = RebirthFX.play({ character = pulseBody, own = false, rebirths = 6, reduced = false, manual = true,
		world = worldBox, gui = guiBox, sound = function() end })
	hp.step(C.SpinSeconds - 0.05)
	local early = pulseTitle:GetAttribute(C.Pulse.Attribute)
	hp.step(C.SpinSeconds + 0.01)
	local marked = pulseTitle:GetAttribute(C.Pulse.Attribute)
	hp.step(C.Seconds)
	pulseTitle:SetAttribute(C.Pulse.Attribute, nil)
	local hn = RebirthFX.play({ character = pulseBody, own = false, rebirths = 8, reduced = false, manual = true,
		world = worldBox, gui = guiBox, sound = function() end })
	hn.step(C.SpinSeconds + 0.01)
	local unmarked = pulseTitle:GetAttribute(C.Pulse.Attribute)
	hn.step(C.Seconds)
	local hr = RebirthFX.play({ character = pulseBody, own = false, rebirths = 6, reduced = true, manual = true,
		world = worldBox, gui = guiBox, sound = function() end })
	hr.step(C.SpinSeconds + 0.01)
	local reducedMark = pulseTitle:GetAttribute(C.Pulse.Attribute)
	hr.step(C.Seconds)
	check(early == nil and type(marked) == "number" and unmarked == nil and reducedMark == nil
			and RebirthFX.PulseAttribute == C.Pulse.Attribute,
		"a rank only marks the title for its pulse at the burst; a new name and REDUCED FX never do")

	--==========================================================================
	say("9. The aura")
	--==========================================================================
	check(not RebirthCelebration.auraFor(49) and RebirthCelebration.auraFor(50) and RebirthCelebration.auraFor(4098)
			and not RebirthCelebration.auraFor("junk") and C.Aura.From == 50,
		"the aura from rebirth 50 up, and not before -- not moved to WORLD TREE's 144 by the 100 titles")
	local auraBody, auraRoot = body("Aura", Vector3.new(80, 10, 0))
	local auraBox = Instance.new("Folder")
	auraBox.Name = "Auras"
	auraBox.Parent = scratch
	local holder = RebirthFX.aura(auraRoot, 50, auraBox)
	local petal = TITLE.Families[2]
	check(holder:IsA("BasePart") and holder.Parent == auraBox and not holder:IsDescendantOf(auraBody)
			and holder.Anchored and not holder.CanCollide and not holder.CanQuery and not holder.CanTouch
			and holder.Transparency == 1 and holder:GetAttribute("Rebirths") == 50
			and RebirthFX.auraOf(auraRoot) == holder and holder.CFrame == auraRoot.CFrame,
		"the aura at 50 is a part of its own outside the character, invisible, anchored, touching nothing, on the "
			.. "body's root")
	local A = C.Aura
	local boards = {}
	for _, d in ipairs(holder:GetDescendants()) do
		if d:IsA("BillboardGui") then
			table.insert(boards, d)
		end
	end
	table.sort(boards, function(a, b)
		return a.Name < b.Name
	end)
	local boardsOK = #boards == 2
	for i, board in ipairs(boards) do
		local frame = board:FindFirstChild("Frame")
		boardsOK = boardsOK and frame and frame:IsA("ImageLabel") and frame.Image == T.Aura
			and frame.ImageRectSize == Vector2.new(256, 256)
			and frame.ImageColor3 == (if i == 1 then petal.Primary else petal.Secondary)
			and board.Size == UDim2.fromScale(A.Size, A.Size) and board.LightInfluence == 0 and not board.AlwaysOnTop
			and near(math.abs(board.StudsOffset.X), A.Side, 1e-4) and board.StudsOffset.Z < 0
			and (i == 1) == (board.StudsOffset.X < 0)
	end
	check(boardsOK, "its wisp sheet plays on two billboards, to the left and the right of the body in camera space and "
		.. "a little behind it, in the family's palette (GROVE MASTER's violet and pink), never drawn on top")
	RebirthFX.followAuras(0)
	local f1 = boards[1].Frame.ImageRectOffset
	local f2 = boards[2].Frame.ImageRectOffset
	RebirthFX.followAuras(5 / A.Framerate)
	local g1 = boards[1].Frame.ImageRectOffset
	RebirthFX.followAuras(16 / A.Framerate)
	local h1 = boards[1].Frame.ImageRectOffset
	check(f1 == Vector2.new(0, 0) and f2 == Vector2.new(0, 512) and g1 == Vector2.new(256, 256) and h1 == f1
			and RebirthFX.auraFrame(1, 0) == 0 and RebirthFX.auraFrame(2, 0) == 8,
		"it steps the sheet's 16 frames at Framerate, left to right and down, round again; the two wisps half a loop "
			.. "apart", tostring(f1) .. " / " .. tostring(f2) .. " / " .. tostring(g1))
	auraRoot.CFrame = CFrame.new(90, 12, 3) * CFrame.Angles(0, 1, 0)
	RebirthFX.followAuras()
	check(holder.CFrame == auraRoot.CFrame, "every frame it is put back on the body's root, wherever the body went")
	local gaia = RebirthFX.aura(auraRoot, 298, auraBox)
	local gaiaFrame = gaia:FindFirstChild("Frame", true)
	check(holder.Parent == nil and gaia.Parent == auraBox and #auraBox:GetChildren() == 1
			and RebirthFX.auraOf(auraRoot) == gaia and gaiaFrame and gaiaFrame:FindFirstChild("Rainbow") ~= nil
			and gaiaFrame.ImageColor3 == Color3.new(1, 1, 1),
		"a new count replaces it (one aura a body); GAIA's is the rainbow")
	-- GAIA's rainbow turns with the frames.
	local gaiaRainbow = gaiaFrame:FindFirstChild("Rainbow")
	RebirthFX.followAuras(0, auraRoot.Position)
	local c0 = gaiaRainbow.Color.Keypoints[1].Value
	RebirthFX.followAuras(C.Aura.RainbowSeconds / 4, auraRoot.Position)
	check(gaiaRainbow.Color.Keypoints[1].Value ~= c0 and C.Aura.RainbowSeconds == GameConfig.TitleFX.RainbowSeconds,
		"GAIA's rainbow turns, at its title's fast pace (the owner: \"make those fast too\")")
	RebirthFX.clearAura(auraRoot)
	check(gaia.Parent == nil and RebirthFX.auraOf(auraRoot) == nil, "taking it off takes it all")
	-- World Tree Halo's two accent leaves (its family's AuraAccents) go round the body.
	local tree = RebirthFX.aura(auraRoot, 150, auraBox)
	local accents = {}
	for _, d in ipairs(tree:GetDescendants()) do
		if d:IsA("BillboardGui") and string.sub(d.Name, 1, 6) == "Accent" then
			table.insert(accents, d)
		end
	end
	RebirthFX.followAuras(1, auraRoot.Position)
	local a1 = accents[1] and accents[1].StudsOffset
	RebirthFX.followAuras(2, auraRoot.Position)
	local a2 = accents[1] and accents[1].StudsOffset
	check(#accents == 2 and accents[1].Leaf.Image == T.Leaf and accents[1].Leaf.ImageColor3 == TITLE.Families[6].Primary
			and a1 ~= a2 and select(4, RebirthCelebration.auraLook(60)) == 0,
		"World Tree's aura wears two small leaves going round it; other families none")
	RebirthFX.clearAura(auraRoot)
	-- Only the Nearest bodies within MaxDistance show theirs (2026-10-10's budget).
	local crowd = {}
	for k = 1, C.Aura.Nearest + 2 do
		local _, r = body("Crowd" .. k, Vector3.new(200 + k * 10, 10, 0))
		table.insert(crowd, RebirthFX.aura(r, 60, auraBox))
	end
	RebirthFX.followAuras(10, Vector3.new(200, 10, 0))
	local shownCount, farShown = 0, false
	for k, h in ipairs(crowd) do
		if RebirthFX.auraShown(h) then
			shownCount += 1
			farShown = farShown or k > C.Aura.Nearest
		end
	end
	local picked = RebirthCelebration.nearest({ 5, 200, 1, 3, 9, 2 }, 4, 160)
	local beyond = RebirthCelebration.nearest({ 170, 5 }, 4, 160)
	check(C.Aura.Nearest == 4 and shownCount == C.Aura.Nearest and not farShown and picked[1] and picked[3]
			and picked[4] and picked[6] and not picked[2] and not picked[5] and beyond[1] == nil and beyond[2],
		"only the four nearest auras show on a screen; a fifth and sixth wait", tostring(shownCount))
	for _, h in ipairs(crowd) do
		h:Destroy()
	end
	local last = RebirthFX.aura(auraRoot, 60, auraBox)
	auraBody:Destroy()
	RebirthFX.followAuras()
	check(last.Parent == nil and #auraBox:GetChildren() == 0, "and when the body goes, its aura goes on the next frame")
	local fx = sourceOf(Shared, "RebirthFX")
	check(has(fx, "player:GetAttributeChangedSignal(CFG.Attributes.Rebirths)") and has(fx, "player.CharacterAdded")
			and has(fx, "if not RebirthCelebration.auraFor(n) or StatusText.reducedMotion() then")
			and has(fx, "local shown = head.LocalTransparencyModifier < 0.5")
			and has(fx, "RebirthFX.hideAura(holder, not shown)"),
		"every body's aura follows its count and its respawns, goes for REDUCED FX, and not round your own "
			.. "camera in first person")

	--==========================================================================
	say("10. The wiring")
	--==========================================================================
	local ui = sourceOf(Scripts, "RebirthUI")
	check(count(ui, "RebirthFX.play({") == 2 and has(ui, "own = true,")
			and has(ui, 'elseif verb == "celebrate" then')
			and has(ui, "Players:GetPlayerByUserId(payload.userId)")
			and has(ui, "RebirthFX.watchAuras()")
			and has(ui, "if RebirthFX.celebrating(player.Character) then")
			and has(ui, "if not shown then\n\t\t\tSoundKit.play(\"NoticeSuccess\")")
			and select(2, string.gsub(ui, "FireServer%(", "")) == 1,
		"RebirthUI: the celebration on \"done\" (the notice only with no body), another's on \"celebrate\", the "
			.. "auras, no quote over it; still one thing sent")
	local service = sourceOf(Server, "RebirthService")
	local a = string.find(service, "pcall(PlayerDataService.Save, player)", 1, true)
	local b = string.find(service, 'verb = "done"', 1, true)
	local c = string.find(service, "pcall(RebirthService.Celebrate, player, after)", 1, true)
	check(a and b and c and a < b and b < c and has(service, "channel:FireClient(player, action, payload)"),
		"RebirthService: the save, then \"done\", then the celebration, all through the one GameEvent")
	check(has(fx, "Enum.RenderPriority.Camera.Value - 1") and has(fx, "Enum.RenderPriority.Camera.Value + 1")
			and has(fx, "humanoid:Move(Vector3.zero, false)")
			and has(fx, "local reduced = if o.reduced ~= nil then o.reduced else StatusText.reducedMotion()")
			and has(fx, "SoundKit.play(C.Cue)") and has(fx, "SoundKit.emit(C.NearbyCue, root)")
			and not has(fx, "FireServer") and not has(fx, "OnClientEvent"),
		"RebirthFX: the camera held on both sides of its step, no walking while it spins, REDUCED FX read once, "
			.. "the fanfare by its rows; it sends and hears nothing")
	check(not has(sourceOf(Shared, "RebirthCelebration"), "Instance.new"), "RebirthCelebration is arithmetic only")
	-- An emitter given its flipbook before its sheet has loaded draws nothing
	-- until the flipbook is set again (Play, 2026-10-09: the aura built at join).
	local waited = os.clock()
	while not RebirthFX.sheetsReady() and os.clock() - waited < 15 do
		task.wait(0.1)
	end
	check(RebirthFX.sheetsReady() and has(fx, "ContentProvider:PreloadAsync(probes)") and has(fx, "waiting[e] = layout")
			and has(fx, "e.FlipbookLayout = Enum.ParticleFlipbookLayout.None\n\te.FlipbookLayout = layout"),
		"the four sheets are loaded as soon as RebirthFX is, and an emitter made before that has its flipbook set "
			.. "again once they are")
	-- On a body a random first frame left the aura undrawn (Play, 2026-10-09).
	check(not has(fx, "FlipbookStartRandom = true"), "no rebirth emitter starts on a random frame")
	-- And the aura follows the body from outside it, one RenderStepped for all.
	check(has(fx, "following = RunService.RenderStepped:Connect(function()\n\t\t\tRebirthFX.followAuras()")
			and not has(fx, "point.Parent = root"),
		"the auras are followed by one RenderStepped, and nothing of an aura is put in a character")
end)

pcall(function()
	scratch:Destroy()
end)
if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nRebirthCelebrationSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
