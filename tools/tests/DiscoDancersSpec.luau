--!nocheck
--==============================================================================
-- Steal a Seed :: DiscoDancersSpec
--
-- The disco's dancers and its music (2026-10-03), Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("DiscoDancersSpec"))
--
-- The eight dancer forms against the owner's originals, part for part; the
-- ported dances; the seeded troupe (the same on every client, inside the
-- config's zones, clear of everything, apart, 0.7-1.3x); every dancer on the
-- ground at both ends of its size range while it dances; and the wiring: the
-- client controller, the music's track and clock. Seen in Play instead: the
-- troupe on the live map, its fade, a late join, and the music loading.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.SeedGame.Shared
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SecretModel = require(Shared.SecretModel)
local DancerForms = require(Shared.DancerForms)
local DancerMoves = require(Shared.DancerMoves)
local DancerPlacement = require(Shared.DancerPlacement)

local CFG = GameConfig.MiniEvent.Dancers
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
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

local NAMES = {
	cocoloco = "Cocoloco", discopuff = "Discopuff", turnipop = "Turnipop", bananabop = "Bananabop",
	shroomhop = "Shroomhop", pricklepop = "Pricklepop", grooveroot = "Grooveroot", florasway = "Florasway",
}
local ACCESSORY = {
	cocoloco = "CanopyJoint", discopuff = "AfroJoint", turnipop = "SproutJoint", bananabop = "CanopyJoint",
	shroomhop = "CapJoint", pricklepop = "CrownJoint", grooveroot = "StamenJoint", florasway = "PetalJoint",
}

local scratch = Instance.new("Folder")
scratch.Name = "ZZDiscoDancersSpec"
scratch.Archivable = false
scratch.Parent = workspace

-- A dancer built the way DiscoDancers builds one, posed at a beat.
local function scaled(c, s)
	return CFrame.new(c.Position * s) * c.Rotation
end
local function buildPosed(id, s, home)
	local spec = DancerForms.Forms[id]
	local model = Instance.new("Model")
	local parts = SecretModel.Replay(spec, home, model, nil, s)
	model.Parent = scratch
	local nodes = {}
	for i, p in ipairs(parts) do
		nodes[i] = { part = p }
	end
	local edges = {}
	for _, j in ipairs(spec.Joints) do
		edges[j.a] = edges[j.a] or {}
		edges[j.b] = edges[j.b] or {}
		table.insert(edges[j.a], { other = j.b, j = j, forward = true })
		table.insert(edges[j.b], { other = j.a, j = j, forward = false })
	end
	local order, seen, head = { spec.Base }, { [spec.Base] = true }, 1
	while head <= #order do
		local at = order[head]
		head += 1
		for _, e in ipairs(edges[at] or {}) do
			if not seen[e.other] then
				seen[e.other] = true
				local n = nodes[e.other]
				n.parent, n.forward = at, e.forward
				n.c0, n.c1 = scaled(e.j.c0, s), scaled(e.j.c1, s)
				n.motor = if e.j.k == "Motor6D" then e.j.n else nil
				table.insert(order, e.other)
			end
		end
	end
	local rootRel = scaled(spec.Parts[spec.Base].cf, s)
	-- The feet, as DiscoDancers takes them: the visible parts below the hips.
	local leg, feet = {}, {}
	for i = 2, #order do
		local n = nodes[order[i]]
		leg[order[i]] = n.motor == "HipL" or n.motor == "HipR" or leg[n.parent] == true
	end
	for _, index in ipairs(order) do
		if leg[index] and parts[index].Transparency < 0.999 then
			table.insert(feet, { index = index, half = parts[index].Size / 2 })
		end
	end
	local function pose(beat)
		local p = if beat then DancerMoves.Pose(id, beat, 1, (spec.ModelScale or 1) * s) else nil
		local cf = {}
		cf[spec.Base] = home * rootRel * (if p then p.root else CFrame.identity)
		for i = 2, #order do
			local n = nodes[order[i]]
			local pcf = cf[n.parent]
			local jcf = if n.motor and p then (p.joints[n.motor] or CFrame.identity) else CFrame.identity
			cf[order[i]] = if n.forward then pcf * n.c0 * jcf * n.c1:Inverse() else pcf * n.c1 * jcf:Inverse() * n.c0:Inverse()
		end
		local lift = if p then DancerMoves.Lift(cf, feet, home.Position.Y) else 0
		for _, index in ipairs(order) do
			nodes[index].part.CFrame = cf[index] + Vector3.new(0, lift, 0)
		end
		return lift
	end
	return model, parts, pose, #order, #feet
end
local function lowestY(parts)
	local lo = math.huge
	for _, d in ipairs(parts) do
		if d.Transparency < 0.999 then
			local h = d.Size / 2
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						lo = math.min(lo, (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
					end
				end
			end
		end
	end
	return lo
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The eight forms are the owner's models, part for part")
	--==========================================================================
	local originals = ServerStorage:FindFirstChild("DiscoDancerOriginals") or workspace:FindFirstChild("disco Dancers")
	check(#DancerForms.Ids == 8 and originals ~= nil, "eight dancer forms, and the originals kept (ServerStorage.DiscoDancerOriginals)",
		originals and originals:GetFullName() or "missing")
	for _, id in ipairs(DancerForms.Ids) do
		local spec = DancerForms.Forms[id]
		local orig = originals and originals:FindFirstChild(NAMES[id])
		if not (spec and orig) then
			check(false, id .. ": a form and its original")
			continue
		end
		local motors = 0
		for _, j in ipairs(spec.Joints) do
			if j.k == "Motor6D" then
				motors += 1
			end
		end
		local model = Instance.new("Model")
		local parts = SecretModel.Replay(spec, CFrame.identity, model, nil, 1)
		local o = {}
		for _, d in ipairs(orig:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(o, d)
			end
		end
		local frame = orig.PrimaryPart.CFrame * spec.Parts[spec.Base].cf:Inverse()
		local worst, mism = 0, 0
		for i, p in ipairs(parts) do
			local rel = frame:ToObjectSpace(o[i].CFrame)
			worst = math.max(worst, (rel.Position - p.Position).Magnitude + (rel.LookVector - p.CFrame.LookVector).Magnitude
				+ (o[i].Size - p.Size).Magnitude)
			if o[i].Name ~= p.Name or o[i].Color ~= p.Color or o[i].Material ~= p.Material or o[i].TopSurface ~= p.TopSurface
				or o[i].BottomSurface ~= p.BottomSurface or math.abs(o[i].Transparency - p.Transparency) > 1e-6 then
				mism += 1
			end
		end
		local tex, otex = 0, 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Texture") then
				tex += 1
			end
		end
		for _, d in ipairs(orig:GetDescendants()) do
			if d:IsA("Texture") then
				otex += 1
			end
		end
		model:Destroy()
		check(#parts == #o and worst < 1e-3 and mism == 0 and tex == otex and spec.Parts[spec.Base].n == "Pelvis"
				and motors == (if id == "florasway" then 8 else 7) and math.abs(spec.ModelScale - orig:GetScale()) < 1e-5,
			string.format("%s: %d parts, %d motors, %d stud textures, Scale %.3f -- identical to the original (worst %.1e)",
				id, #parts, motors, tex, spec.ModelScale, worst))
	end

	--==========================================================================
	say("2. The dances: the scripts' moves, finite, on the beat")
	--==========================================================================
	for _, id in ipairs(DancerForms.Ids) do
		local bpm = DancerForms.Beat(id)
		local good, routines, accessory = true, {}, false
		for b = 0, 32, 0.25 do
			local p = DancerMoves.Pose(id, b, 1, 1)
			if not p then
				good = false
				break
			end
			for _, c in pairs(p.joints) do
				for _, x in ipairs({ c:GetComponents() }) do
					if x ~= x or math.abs(x) == math.huge then
						good = false
					end
				end
			end
			if p.joints[ACCESSORY[id]] and p.joints[ACCESSORY[id]] ~= CFrame.identity then
				accessory = true
			end
			routines[math.floor(b / 8) % 2] = (p.joints.ShoulderL ~= nil) and (p.joints.HipL ~= nil)
		end
		local want = if id == "shroomhop" then 128 elseif id == "florasway" then 120 else 124
		check(good and accessory and routines[0] and routines[1] and bpm == want,
			string.format("%s: %d BPM, both routines, its %s and the step-tap", id, bpm, ACCESSORY[id]))
	end
	do
		-- The dip is the body's; the hips rise by it, so the legs stay down.
		local p = DancerMoves.Pose("pricklepop", 0.5, 1, 2)
		check(math.abs(p.root.Position.Y + 0.14 * 2) < 1e-6 and math.abs(p.joints.HipL.Position.Y - 0.14 * 2) < 1e-6,
			"the beat's dip moves the body at the copy's size (x k) and the hips rise by the same")
	end

	--==========================================================================
	say("3. The troupe: seeded, the same everywhere, clear of everything")
	--==========================================================================
	local ids = { "0b38d5637a834658", "ee682de0a1a74bd9", "84587d15deadbeef", "5c58d50e011642e1", "fcd5811b68344cba" }
	for _, eventId in ipairs(ids) do
		local a, b = DancerPlacement.Picks(eventId), DancerPlacement.Picks(eventId)
		local same = #a == #b
		for i = 1, #a do
			if a[i].id ~= b[i].id or a[i].at ~= b[i].at or a[i].scale ~= b[i].scale or a[i].yaw ~= b[i].yaw then
				same = false
			end
		end
		local inside, apart, sized, deck, kinds = true, true, true, 0, {}
		for i, p in ipairs(a) do
			if not DancerPlacement.Clear(p.at, p.radius, p.zone) then
				inside = false
			end
			if p.scale < CFG.ScaleMin or p.scale > CFG.ScaleMax
				or math.abs(p.radius - DancerForms.Radius(p.id) * p.scale) > 1e-6 then
				sized = false
			end
			for j = i + 1, #a do
				local q = a[j]
				if (Vector3.new(p.at.X, 0, p.at.Z) - Vector3.new(q.at.X, 0, q.at.Z)).Magnitude < p.radius + q.radius + CFG.Gap - 1e-6 then
					apart = false
				end
			end
			if p.zone.Name == "Deck" then
				deck += 1
			end
			kinds[p.id] = true
		end
		local nk = 0
		for _ in pairs(kinds) do
			nk += 1
		end
		check(same and #a == CFG.Count and inside and apart and sized,
			string.format("event %s: %d dancers (%d on the deck), %d of the 8 models, all clear and %.1f studs apart, 0.7-1.3x, the same twice",
				string.sub(eventId, 1, 8), #a, deck, nk, CFG.Gap))
	end
	do
		local a, b = DancerPlacement.Picks(ids[1]), DancerPlacement.Picks(ids[2])
		local differ = false
		for i = 1, math.min(#a, #b) do
			if a[i].at ~= b[i].at then
				differ = true
			end
		end
		check(differ, "another event places another troupe")
	end
	do
		-- No dancer stands where tickets fall (the ticket band, east of the deck).
		local area = GameConfig.MiniEvent.Area
		local clearOfTickets = true
		for _, eventId in ipairs(ids) do
			for _, p in ipairs(DancerPlacement.Picks(eventId)) do
				local d = Vector3.new(p.at.X, 0, p.at.Z).Magnitude
				local angle = math.deg(math.atan2(p.at.Z, p.at.X))
				for _, s in ipairs(area.Sectors) do
					if d - p.radius < area.MaxRadius and (angle - s.From) % 360 <= (s.To - s.From) then
						clearOfTickets = false
					end
				end
			end
		end
		check(clearOfTickets, "no dancer stands in the ticket band")
	end

	--==========================================================================
	say("4. On the ground at both ends of the size range, while dancing")
	--==========================================================================
	for _, id in ipairs(DancerForms.Ids) do
		local spec = DancerForms.Forms[id]
		local worstRest, worstSink, worstHover, worstLift = 0, 0, 0, 0
		for _, s in ipairs({ CFG.ScaleMin, CFG.ScaleMax }) do
			local home = CFrame.new(0, 10, -400) * CFrame.Angles(0, 0.6, 0)
			local model, parts, pose, reached, feet = buildPosed(id, s, home)
			pose(nil)
			worstRest = math.max(worstRest, math.abs(lowestY(parts) - 10))
			local height = spec.Size.Y * s
			for b = 0, 16, 0.125 do
				local lift = pose(b)
				local low = lowestY(parts)
				worstSink = math.max(worstSink, 10 - low)
				worstHover = math.max(worstHover, (low - 10) / height)
				worstLift = math.max(worstLift, lift / height)
			end
			check(reached == #parts and feet >= 2, string.format("%s at %.1fx: every part hangs off the Pelvis; %d feet", id, s, feet))
			model:Destroy()
		end
		-- Nothing cuts the floor; the roll's lift and any daylight under both
		-- feet stay a sliver of the dancer's height.
		check(worstRest < 1e-3 and worstSink < 1e-3 and worstLift < 0.03 and worstHover < 0.03,
			string.format("%s: on the ground at 0.7x and 1.3x (%.1e); dancing, sinks %.1e, rises at most %.1f%% of its height, both feet up at most %.1f%%",
				id, worstRest, worstSink, worstLift * 100, worstHover * 100))
	end

	--==========================================================================
	say("5. Wiring: the client troupe, and the music")
	--==========================================================================
	local client = sourceOf(Scripts, "DiscoDancers")
	check(string.find(client, "DancerPlacement.Picks(eventId)", 1, true) ~= nil
			and string.find(client, "math.min(CFG.PhoneCount, #picks)", 1, true) ~= nil
			and string.find(client, "if troupeId == eventId then", 1, true) ~= nil
			and string.find(client, "elapsed * d.bpm / 60 * d.rate", 1, true) ~= nil
			and string.find(client, "folder.Archivable = false", 1, true) ~= nil,
		"DiscoDancers: one troupe per event id, the phone's share of it, the dance on the event's clock, a local folder")
	check(string.find(client, "p.CanCollide = false", 1, true) ~= nil and string.find(client, "p.CanTouch = false", 1, true) ~= nil
			and string.find(client, "p.CanQuery = false", 1, true) ~= nil and string.find(client, "p.Anchored = true", 1, true) ~= nil
			and not string.find(client, "FireServer", 1, true) and not string.find(client, "InvokeServer", 1, true),
		"every dancer part anchored, never collides, touches or answers a query; nothing is sent to the server")
	check(string.find(client, "StatusText.reducedMotion()", 1, true) ~= nil and string.find(client, "M.FadeSeconds", 1, true) ~= nil
			and string.find(client, "local alpha = math.clamp((t - builtAt)", 1, true) ~= nil,
		"reduced motion holds them still; they fade in as they appear on a screen and out with the event")
	-- Every event attribute the controller reads is one the event writes (Play
	-- found ATTR.Id, which is no attribute at all: the troupe never came).
	local unknown = {}
	for key in string.gmatch(client, "ATTR%.(%w+)") do
		if GameConfig.MiniEvent.Attributes[key] == nil then
			table.insert(unknown, key)
		end
	end
	check(#unknown == 0, "every MiniEvent attribute DiscoDancers reads exists in GameConfig.MiniEvent.Attributes",
		table.concat(unknown, ", "))
	local modes = GameConfig.MiniEvent.Modes
	check(modes.ticketdisco.Disco == true and modes.disco.Disco == true and modes.party.Disco == true
			and modes.tickets.Disco == false,
		"dancers and the disco bed for Ticket Disco, DISCO + MILL and the pure DISCO ONLY, never Ticket Shower Only")
	local music = sourceOf(Scripts, "Music")
	local ids2 = GameConfig.Music.DiscoTracks
	check(#ids2 == 1 and ids2[1] == "rbxassetid://118716691317783" and ids2[1] ~= GameConfig.Music.RainTracks[1]
			and string.find(music, "sound.TimePosition = math.max(0, Workspace:GetServerTimeNow() - started) % length", 1, true) ~= nil,
		"the disco bed is the owner's track on the one music Sound, started where the event is")
	-- The swap calls alignDisco: it has to be declared before applyPhase, or the
	-- call is a nil global (Play found the fade-in never ran: silence).
	local declared = string.find(music, "local alignDisco: () -> ()", 1, true)
	local phase = string.find(music, "local function applyPhase()", 1, true)
	check(declared ~= nil and phase ~= nil and declared < phase and string.find(music, "\nfunction alignDisco()", 1, true) ~= nil
			and string.find(music, "local function alignDisco()", 1, true) == nil,
		"Music declares alignDisco before the swap that calls it, so the disco fades in on the event's clock")
end)

scratch:Destroy()
if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nDiscoDancersSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
