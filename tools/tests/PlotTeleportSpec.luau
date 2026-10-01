--!nocheck
--==============================================================================
-- Steal a Seed :: PlotTeleportSpec
--
-- TELEPORT TO PLOT, on the server: PlotService.TeleportHome, and the one verb
-- that reaches it. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlotTeleportSpec"))
--
-- The REAL PlotService, fresh-required, with the real SpawnCFrameFor and the
-- real MapService.IsInSafeZone. Only PlotOf is stubbed, to hand back plots built
-- here far above the map -- inside the field's X and Z, which is all the Safe
-- Zone test reads. The players are tables with real bodies, as in
-- DebugTeleportSpec, so every move is a real PivotTo that can be measured.
--
-- WHAT THE BRIEF ASKED TO BE PINNED: a press from outside the Safe Zone, a
-- stale or dead body, rapid repeated presses and a player with no plot -- and
-- that wherever a press lands, it is the sender's own plot, over ground.
--
-- Not here: the button (HudLayoutSpec places it; Play shows it), the round trip
-- over the remote (Play), and two real people pressing at once (Play).
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlotService = require(Server:WaitForChild("PlotService"))
local MapService = require(Server:WaitForChild("MapService"))

local PLOT = GameConfig.Plot
local ATTR = GameConfig.Attributes
local MAP = GameConfig.Map

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local function sourceOf(instance)
	if instance == nil then
		return nil
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok then src else nil
end

--==============================================================================
-- 1. THE VERB AND ITS WORDS
--==============================================================================
say("-- the verb --")
check(type(PLOT.TeleportAction) == "string" and PLOT.TeleportAction ~= ""
		and PLOT.TeleportAction ~= GameConfig.Plant.PlaceAction
		and PLOT.TeleportAction ~= ActionRefusal.Action,
	"TELEPORT TO PLOT is one verb of its own on GameEvent", PLOT.TeleportAction)
check(type(PLOT.TeleportCooldownSeconds) == "number" and PLOT.TeleportCooldownSeconds >= 1
		and PLOT.TeleportCooldownSeconds <= 10,
	"with a short server cooldown", PLOT.TeleportCooldownSeconds)
check(type(PLOT.TeleportGroundProbe) == "number"
		and PLOT.TeleportGroundProbe > PLOT.SpawnHeightOffset + 1,
	"and a ground probe long enough to reach the pad under the spawn height",
	PLOT.TeleportGroundProbe)

local plotSource = sourceOf(Server:FindFirstChild("PlotService"))
do
	local named, missing = {}, {}
	for code in string.gmatch(plotSource or "", "\"(TELEPORT_[A-Z_]+)\"") do
		if not named[code] then
			named[code] = true
			if ActionRefusal.Text[code] == nil then
				table.insert(missing, code)
			end
		end
	end
	check(next(named) ~= nil and #missing == 0,
		"every refusal TeleportHome can name has a line in ActionRefusal.Text",
		table.concat(missing, ", "))
	check(ActionRefusal.Text.CARRYING_POD ~= nil,
		"and the carry refusal it shares with a second pod does too")
end

--==============================================================================
-- THE FIXTURE
--
-- Two plots side by side at the back of the field, well above everything, and
-- bodies that stand where each case needs them.
--==============================================================================
local HIGH = 1500
local fixture = Instance.new("Folder")
fixture.Name = "PlotTeleportSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

local function addFloor(plot, pad)
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(20, 1, 20)
	floor.CFrame = CFrame.new(pad.Position - Vector3.new(0, 1.1, 0))
	floor.Parent = plot
	return floor
end

-- Like MapService's: the pad is a transparent, NON-COLLIDABLE marker, and what
-- a body lands on is the plot's collidable floor under it. `floored == false`
-- leaves the floor out -- a plot with nothing to stand on.
local function makePlot(name, at, floored)
	local plot = Instance.new("Model")
	plot.Name = name
	local pad = Instance.new("Part")
	pad.Name = PLOT.SpawnPadName
	pad.Anchored = true
	pad.CanCollide = false
	pad.Transparency = 1
	pad.Size = Vector3.new(6, 1, 6)
	-- Turned, so "faces the way the pad faces" is a real check.
	pad.CFrame = CFrame.new(at) * CFrame.Angles(0, math.rad(180), 0)
	pad.Parent = plot
	plot.PrimaryPart = pad
	if floored ~= false then
		addFloor(plot, pad)
	end
	plot.Parent = fixture
	return plot, pad
end

local function makePlayer(name, userId, at)
	local body = Instance.new("Model")
	body.Name = name .. "Body"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(at)
	root.Parent = body
	body.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = body
	body.Parent = fixture

	local attrs = {}
	local p = { Name = name, UserId = userId, Parent = Players, Character = body }
	function p.GetAttribute(_, key)
		return attrs[key]
	end
	function p.SetAttribute(_, key, value)
		attrs[key] = value
	end
	p.body, p.root, p.humanoid = body, root, humanoid
	return p
end

-- Inside the field: X within half its width, Z between its front and back.
local IN_FIELD = Vector3.new(0, HIGH + 3, 0)
-- On the road, forty studs past the red line.
local ON_ROAD = Vector3.new(0, HIGH + 3, -MAP.FieldFront - 40)
-- Half a stud inside the red line: still the Safe Zone.
local AT_LINE = Vector3.new(0, HIGH + 3, -MAP.FieldFront + 0.5)

local plotA, padA = makePlot("PlotTeleportSpecA", Vector3.new(60, HIGH, 150))
local plotB, padB = makePlot("PlotTeleportSpecB", Vector3.new(-60, HIGH, 150))

local function standAt(p, at)
	p.body:PivotTo(CFrame.new(at))
end

local function at(p)
	return p.root.Position
end

local function onPad(p, pad)
	local want = pad.CFrame + Vector3.new(0, PLOT.SpawnHeightOffset, 0)
	return (p.root.Position - want.Position).Magnitude < 0.05
		and p.root.CFrame.LookVector:Dot(want.LookVector) > 0.999
end

local function still(p, where)
	return (p.root.Position - where).Magnitude < 0.05
end

local leases = {}
local realPlotOf = PlotService.PlotOf

local function body()
	PlotService.PlotOf = function(player)
		return leases[player]
	end

	check(MapService.IsInSafeZone(IN_FIELD) and MapService.IsInSafeZone(AT_LINE)
			and not MapService.IsInSafeZone(ON_ROAD)
			and MapService.IsInSafeZone(padA.Position) and MapService.IsInSafeZone(padB.Position),
		"(the fixture: the field spots and both pads are in the Safe Zone, the road is not)")

	--==========================================================================
	-- 2. HOME
	--==========================================================================
	say("\n-- home --")
	local a = makePlayer("SpecHomeA", -401, IN_FIELD)
	leases[a] = plotA
	local held = Instance.new("Tool")
	held.Name = "SpecHeldPlant"
	held.RequiresHandle = false
	held.Parent = a.body
	a:SetAttribute("SpecKeep", 7)
	-- An anchored part keeps the velocity it is given (the conveyor trick), so a
	-- running start is something the teleport can be seen to take away.
	a.root.AssemblyLinearVelocity = Vector3.new(0, 0, 80)

	local moved, code = PlotService.TeleportHome(a)
	check(moved == true and code == nil, "a press in the Safe Zone with a plot moves the player",
		tostring(code))
	check(onPad(a, padA), "onto their own plot's spawn pad, spawn height up, facing the way it faces",
		tostring(at(a)))
	check(held.Parent == a.body and a:GetAttribute("SpecKeep") == 7 and leases[a] == plotA,
		"with the Tool still in their hand and nothing about them changed")
	check(a.root.AssemblyLinearVelocity.Magnitude < 0.01,
		"and no momentum carried across")

	--==========================================================================
	-- 3. RAPID PRESSES
	--
	-- One press moves you. Everything inside the next three seconds is refused
	-- and moves nobody -- and a refused press does not push the cooldown out,
	-- so the press after it lands exactly when the first one's cooldown ends.
	--==========================================================================
	say("\n-- rapid presses --")
	standAt(a, IN_FIELD)
	local refusedAll, stayed = true, true
	for _ = 1, 10 do
		local m, c = PlotService.TeleportHome(a)
		if m or c ~= "TELEPORT_COOLDOWN" then
			refusedAll = false
		end
		if not still(a, IN_FIELD) then
			stayed = false
		end
	end
	check(refusedAll, "ten more presses straight away are all refused: \"Teleport recharging…\"")
	check(stayed, "and none of them moved anybody")

	task.wait(PLOT.TeleportCooldownSeconds * 0.5)
	local midMoved, midCode = PlotService.TeleportHome(a)
	check(not midMoved and midCode == "TELEPORT_COOLDOWN" and still(a, IN_FIELD),
		"half way through the cooldown: still refused", tostring(midCode))
	task.wait(PLOT.TeleportCooldownSeconds * 0.5 + 0.2)
	local lateMoved, lateCode = PlotService.TeleportHome(a)
	check(lateMoved == true and onPad(a, padA),
		"just past the cooldown the next press works: a refused press never extended it",
		tostring(lateCode))

	--==========================================================================
	-- 4. OUTSIDE THE SAFE ZONE
	--==========================================================================
	say("\n-- outside the Safe Zone --")
	local b = makePlayer("SpecHomeB", -402, ON_ROAD)
	leases[b] = plotB
	local roadMoved, roadCode = PlotService.TeleportHome(b)
	check(not roadMoved and roadCode == "TELEPORT_OUTSIDE" and still(b, ON_ROAD),
		"a press from the road is refused -- \"Teleport works only in the Safe Zone.\" -- and moves nothing",
		tostring(roadCode))
	-- The button hides on the road; a press that was already on its way when the
	-- player stepped over the line is exactly this case.
	standAt(b, AT_LINE)
	local lineMoved = PlotService.TeleportHome(b)
	check(lineMoved == true and onPad(b, padB),
		"half a stud inside the red line it works -- the game's one Safe Zone test decides")
	check(not onPad(b, padA), "and it lands on B's plot, not A's")
	check(onPad(a, padA), "while A, whose press came first, is still on A's")

	--==========================================================================
	-- 5. NO PLOT
	--==========================================================================
	say("\n-- no plot --")
	local c = makePlayer("SpecQueued", -403, IN_FIELD)
	local queuedMoved, queuedCode = PlotService.TeleportHome(c)
	check(not queuedMoved and queuedCode == "TELEPORT_NO_PLOT" and still(c, IN_FIELD),
		"a player still queued for a plot is told \"You don't have a plot yet.\" and stays put",
		tostring(queuedCode))
	standAt(c, ON_ROAD)
	local _, queuedRoadCode = PlotService.TeleportHome(c)
	check(queuedRoadCode == "TELEPORT_NO_PLOT",
		"from the road too: no plot is checked before the Safe Zone", tostring(queuedRoadCode))

	--==========================================================================
	-- 6. A STALE OR DEAD BODY: refused, and SILENT -- not a player's action
	--==========================================================================
	say("\n-- stale and dead bodies --")
	local d = makePlayer("SpecGhost", -404, IN_FIELD)
	leases[d] = plotA

	d.humanoid.Health = 0
	local deadMoved, deadCode = PlotService.TeleportHome(d)
	check(not deadMoved and deadCode == nil and still(d, IN_FIELD),
		"a dead body is not moved, and gets no line", tostring(deadCode))
	d.humanoid.Health = d.humanoid.MaxHealth

	d.body.Parent = nil
	local staleMoved, staleCode = PlotService.TeleportHome(d)
	check(not staleMoved and staleCode == nil,
		"a body already taken out of the world (mid-respawn): refused, silently", tostring(staleCode))
	d.body.Parent = fixture

	d.Character = nil
	local noneMoved, noneCode = PlotService.TeleportHome(d)
	check(not noneMoved and noneCode == nil, "no body at all: refused, silently", tostring(noneCode))
	d.Character = d.body

	local rootless = d.root
	rootless.Parent = nil
	local rootMoved, rootCode = PlotService.TeleportHome(d)
	check(not rootMoved and rootCode == nil, "a body with no root: refused, silently", tostring(rootCode))
	rootless.Parent = d.body
	d.body.PrimaryPart = rootless

	d.Parent = nil
	local goneMoved, goneCode = PlotService.TeleportHome(d)
	check(not goneMoved and goneCode == nil and still(d, IN_FIELD),
		"a player who has left: refused, silently", tostring(goneCode))
	d.Parent = Players

	local backMoved = PlotService.TeleportHome(d)
	check(backMoved == true and onPad(d, padA),
		"and the same player, alive and whole again, goes home -- none of that spent the cooldown")

	--==========================================================================
	-- 7. HELD: a raided pod, a trap, a knock-down
	--==========================================================================
	say("\n-- held --")
	local e = makePlayer("SpecHeld", -405, IN_FIELD)
	leases[e] = plotB

	e:SetAttribute(ATTR.CarryingSpecies, "nubkin")
	local carryMoved, carryCode = PlotService.TeleportHome(e)
	check(not carryMoved and carryCode == "CARRYING_POD" and still(e, IN_FIELD),
		"carrying a raided pod: \"Bank your pod before doing that.\" -- no skipping the run home",
		tostring(carryCode))
	e:SetAttribute(ATTR.CarryingSpecies, nil)

	e:SetAttribute(ATTR.Trapped, true)
	local trapMoved, trapCode = PlotService.TeleportHome(e)
	check(not trapMoved and trapCode == "TELEPORT_STUNNED" and still(e, IN_FIELD),
		"held by a trap: \"Wait until you can move again.\"", tostring(trapCode))
	e:SetAttribute(ATTR.Trapped, nil)

	e.humanoid.PlatformStand = true
	local downMoved, downCode = PlotService.TeleportHome(e)
	check(not downMoved and downCode == "TELEPORT_STUNNED" and still(e, IN_FIELD),
		"knocked down (ragdolled): the same", tostring(downCode))
	e.humanoid.PlatformStand = false

	local freeMoved = PlotService.TeleportHome(e)
	check(freeMoved == true and onPad(e, padB), "and once free, home -- none of those spent the cooldown")

	--==========================================================================
	-- 8. NOWHERE TO LAND
	--
	-- A plot with nothing to stand on under its spawn and a plot whose spawn is
	-- not in the field refuse rather than drop the player. Neither spends the
	-- cooldown. The pad on its own does not count: it is a non-collidable
	-- marker, and a probe that stopped on it would be standing a body on air.
	--==========================================================================
	say("\n-- nowhere to land --")
	local f = makePlayer("SpecHollow", -406, IN_FIELD)
	local hollow, hollowPad = makePlot("PlotTeleportSpecHollow", Vector3.new(0, HIGH, 200), false)
	leases[f] = hollow
	local hollowMoved, hollowCode = PlotService.TeleportHome(f)
	check(not hollowMoved and hollowCode == "TELEPORT_BLOCKED" and still(f, IN_FIELD),
		"a spawn pad with no floor under it: refused, \"Your plot isn't ready yet.\", nobody dropped",
		tostring(hollowCode))
	addFloor(hollow, hollowPad)
	local solidMoved = PlotService.TeleportHome(f)
	check(solidMoved == true and onPad(f, hollowPad),
		"the moment there is a floor it works, straight away: the refusal cost nothing")

	local g = makePlayer("SpecAstray", -407, IN_FIELD)
	local astray = makePlot("PlotTeleportSpecAstray", Vector3.new(0, HIGH, -MAP.FieldFront - 60))
	leases[g] = astray
	local astrayMoved, astrayCode = PlotService.TeleportHome(g)
	check(not astrayMoved and astrayCode == "TELEPORT_BLOCKED" and still(g, IN_FIELD),
		"a spawn outside the field is never a destination", tostring(astrayCode))

	--==========================================================================
	-- 9. NOTHING THE CLIENT SENDS IS READ
	--==========================================================================
	say("\n-- the client names nothing --")
	local handler = plotSource and string.match(plotSource,
		"channel%.OnServerEvent:Connect%((function%([^)]*%).-)\n\t\tend%)%)")
	check(handler ~= nil, "PlotService connects one GameEvent handler for the verb")
	check(handler ~= nil and string.find(handler, "function(player: Player, action: any)", 1, true) == 1,
		"which takes the engine-stamped sender and the verb, and no third argument")
	check(handler ~= nil and string.find(handler, "PlotService.TeleportHome(player)", 1, true) ~= nil
			and string.find(handler, "payload", 1, true) == nil,
		"and hands TeleportHome the sender alone")
	check(plotSource ~= nil
			and string.find(plotSource, "function PlotService.TeleportHome(player: Player): (boolean, string?)",
				1, true) ~= nil,
		"TeleportHome takes a player and nothing else: no plot id, no position")
	local teleportBody = plotSource and string.match(plotSource,
		"function PlotService%.TeleportHome(.-)\nend\n")
	check(teleportBody ~= nil and string.find(teleportBody, "PlotService.PlotOf(player)", 1, true) ~= nil
			and string.find(teleportBody, "PlotService.SpawnCFrameFor(plot)", 1, true) ~= nil
			and string.find(teleportBody, "MapService.IsInSafeZone(root.Position)", 1, true) ~= nil,
		"the plot is the server's lease, the spot is SpawnCFrameFor, the zone test is MapService's")

	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local ui = sourceOf(scripts and scripts:FindFirstChild("PlotTeleportUI"))
	local _, fires = string.gsub(ui or "", "FireServer%(", "")
	check(ui ~= nil and fires == 1
			and string.find(ui, "remote:FireServer(PLOT.TeleportAction)", 1, true) ~= nil,
		"the button sends the verb and nothing else", fires)
	check(plotSource ~= nil
			and string.find(plotSource, "player:SetAttribute(ATTR.OwnPlotId, id)", 1, true) ~= nil
			and string.find(plotSource, "player:SetAttribute(ATTR.OwnPlotId, nil)", 1, true) ~= nil,
		"the plot the button shows off is set on assignment and cleared on release")

	--==========================================================================
	-- 10. THE OBBY BUTTON (2026-09-27): PlotService.TeleportTo
	--
	-- TELEPORT TO PLOT's rules less the plot, ONE cooldown shared with it, and a
	-- landing the server names -- ObbyService's entrance frame -- that must be in
	-- the Safe Zone with ground under it, or the caller's own code comes back.
	--==========================================================================
	say("\n-- the OBBY button's teleport --")
	local landingFloor = Instance.new("Part")
	landingFloor.Name = "ObbyLandingFloor"
	landingFloor.Anchored = true
	landingFloor.Size = Vector3.new(20, 1, 20)
	landingFloor.CFrame = CFrame.new(40, HIGH - 0.5, 100)
	landingFloor.Parent = fixture
	local landing = CFrame.new(40, HIGH + 3, 100)
	local function landed(p)
		return (p.root.Position - landing.Position).Magnitude < 0.05
	end

	local h = makePlayer("SpecObby", -408, IN_FIELD)
	leases[h] = plotA
	h.root.AssemblyLinearVelocity = Vector3.new(60, 0, 0)
	local toMoved, toCode = PlotService.TeleportTo(h, landing, "OBBY_BLOCKED")
	check(toMoved == true and toCode == nil and landed(h) and h.root.AssemblyLinearVelocity.Magnitude < 0.01,
		"from the Safe Zone it lands on the named spot, with no momentum carried", tostring(toCode))
	standAt(h, IN_FIELD)
	local againMoved, againCode = PlotService.TeleportTo(h, landing, "OBBY_BLOCKED")
	local homeMoved, homeCode = PlotService.TeleportHome(h)
	check(not againMoved and againCode == "TELEPORT_COOLDOWN" and not homeMoved and homeCode == "TELEPORT_COOLDOWN"
			and still(h, IN_FIELD),
		"and it shares TELEPORT TO PLOT's cooldown: neither button works again straight away",
		tostring(againCode) .. " / " .. tostring(homeCode))

	local i = makePlayer("SpecObbyHeld", -409, ON_ROAD)
	local roadMoved2, roadCode2 = PlotService.TeleportTo(i, landing, "OBBY_BLOCKED")
	check(not roadMoved2 and roadCode2 == "TELEPORT_OUTSIDE" and still(i, ON_ROAD),
		"from the road: refused, only the Safe Zone -- it can never shortcut a run home", tostring(roadCode2))
	standAt(i, IN_FIELD)
	i:SetAttribute(ATTR.CarryingSpecies, "nubkin")
	local podMoved, podCode = PlotService.TeleportTo(i, landing, "OBBY_BLOCKED")
	i:SetAttribute(ATTR.CarryingSpecies, nil)
	i:SetAttribute(ATTR.Trapped, true)
	local trappedMoved, trappedCode = PlotService.TeleportTo(i, landing, "OBBY_BLOCKED")
	i:SetAttribute(ATTR.Trapped, nil)
	i.humanoid.PlatformStand = true
	local ragMoved, ragCode = PlotService.TeleportTo(i, landing, "OBBY_BLOCKED")
	i.humanoid.PlatformStand = false
	i.humanoid.Health = 0
	local deadMoved2, deadCode2 = PlotService.TeleportTo(i, landing, "OBBY_BLOCKED")
	i.humanoid.Health = i.humanoid.MaxHealth
	check(not podMoved and podCode == "CARRYING_POD" and not trappedMoved and trappedCode == "TELEPORT_STUNNED"
			and not ragMoved and ragCode == "TELEPORT_STUNNED" and not deadMoved2 and deadCode2 == nil
			and still(i, IN_FIELD),
		"a raided pod, a trap, a knock-down and a dead body are refused exactly as TELEPORT TO PLOT refuses them",
		string.format("%s %s %s %s", tostring(podCode), tostring(trappedCode), tostring(ragCode), tostring(deadCode2)))

	local roadLanding = CFrame.new(0, HIGH + 3, -MAP.FieldFront - 40)
	local airLanding = CFrame.new(-40, HIGH + 3, 100)
	local nanLanding = CFrame.new(0 / 0, HIGH, 0)
	local outMoved, outCode = PlotService.TeleportTo(i, roadLanding, "OBBY_BLOCKED")
	local airMoved, airCode = PlotService.TeleportTo(i, airLanding, "OBBY_BLOCKED")
	local nanMoved, nanCode = PlotService.TeleportTo(i, nanLanding, "OBBY_BLOCKED")
	check(not outMoved and outCode == "OBBY_BLOCKED" and not airMoved and airCode == "OBBY_BLOCKED"
			and not nanMoved and nanCode == "OBBY_BLOCKED" and still(i, IN_FIELD),
		"a landing outside the Safe Zone, over nothing, or not a number: the caller's own code, nobody moved",
		string.format("%s %s %s", tostring(outCode), tostring(airCode), tostring(nanCode)))
	local freeMoved2 = PlotService.TeleportTo(i, landing, "OBBY_BLOCKED")
	check(freeMoved2 == true and landed(i), "and none of those refusals spent the cooldown")

	-- The real destination: ObbyService's entrance frame (the arch's own landing,
	-- where Return and a death put a runner) is inside the Safe Zone.
	local ObbyData = require(Shared:WaitForChild("ObbyData"))
	local E = ObbyData.Entrance
	local entrance = CFrame.new(E.At) * CFrame.Angles(0, math.rad(E.FacingDegrees), 0) * CFrame.new(0, 3.5, 6)
	check(MapService.IsInSafeZone(entrance.Position), "the obby entrance's landing is inside the Safe Zone",
		tostring(entrance.Position))
	local obbySource = sourceOf(Server:FindFirstChild("ObbyService")) or ""
	check(string.find(obbySource, "PlotService.TeleportTo(player, entranceFrame(), \"OBBY_BLOCKED\")", 1, true) ~= nil
			and string.find(obbySource, "return CFrame.new(E.At) * CFrame.Angles(0, math.rad(E.FacingDegrees), 0) "
				.. "* CFrame.new(0, 3.5, 6)", 1, true) ~= nil,
		"ObbyService asks for exactly that frame, with its own refusal")
	check(ActionRefusal.Text.OBBY_BLOCKED ~= nil, "and that refusal has words")

	--==========================================================================
	-- 11. THE BIOMES BUTTON (2026-09-30): ONE PLACE, THE GREENHOLLOW ENTRANCE
	--
	-- The owner's brief: one fixed destination where the biome road begins,
	-- chosen from the map, clear of obstacles, nests and guardians, facing down
	-- the road; free; TELEPORT TO PLOT's rules and cooldown; the server names
	-- the place and the client sends nothing but the verb.
	--==========================================================================
	say("\n-- the BIOMES button's teleport --")
	local BiomeData = require(Shared:WaitForChild("BiomeData"))
	check(type(PLOT.BiomesAction) == "string" and PLOT.BiomesAction ~= "" and PLOT.BiomesAction ~= PLOT.TeleportAction
			and PLOT.BiomesAction ~= GameConfig.Plant.PlaceAction and PLOT.BiomesAction ~= ActionRefusal.Action,
		"BIOMES is one verb of its own on GameEvent", PLOT.BiomesAction)
	local greenhollow = nil
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.Id == "greenhollow" then
			greenhollow = biome
		end
	end
	local landingB = PlotService.BiomesLanding()
	local nearZ = if greenhollow then BiomeData.SegmentBounds(greenhollow) else nil
	check(greenhollow ~= nil and greenhollow.Order == 1 and landingB ~= nil and nearZ == -MAP.FieldFront,
		"the destination is Greenhollow's, the first biome, whose near edge is where the road begins")
	if landingB and nearZ then
		local at = landingB.Position
		check(at.X == 0 and math.abs(at.Z - (nearZ + PLOT.BiomesLandingInset)) < 1e-6
				and PLOT.BiomesLandingInset > 0 and PLOT.BiomesLandingInset <= 15
				and MapService.IsInSafeZone(at) and not MapService.IsInSafeZone(at + Vector3.new(0, 0, -PLOT.BiomesLandingInset - 1)),
			"it lands on the road's centre line, a few studs inside the red line: the entrance, still the Safe Zone",
			tostring(at))
		check(math.abs(at.Y - (MAP.GroundY + PLOT.SpawnHeightOffset)) < 1e-6
				and landingB.LookVector:Dot(Vector3.new(0, 0, -1)) > 0.999,
			"at the spawn height, facing forward down the road", tostring(landingB.LookVector))
		check(math.abs(at.X) + 10 <= MAP.CorridorWidth / 2,
			"with the corridor's walls far to either side", string.format("half-width %g", MAP.CorridorWidth / 2))
		-- Nothing of the rest of the road is a destination: the landing is before
		-- Greenhollow's own nest, far from it, and before every later biome.
		local nests = BiomeData.NestCFrames(greenhollow)
		local nearest = math.huge
		for _, nest in ipairs(nests) do
			nearest = math.min(nearest, (nest.Position - at).Magnitude)
		end
		check(#nests >= 1 and nearest > 200,
			"far from Greenhollow's nest and its guardian, in the segment's far corner", string.format("%.0f studs", nearest))
		for _, biome in ipairs(BiomeData.Biomes) do
			if biome.Order > 1 then
				local near = BiomeData.SegmentBounds(biome)
				if at.Z <= near then
					check(false, "the landing is short of " .. biome.DisplayName)
				end
			end
		end
		-- THE REAL MAP, where Edit has it (MapService builds a preview in Edit):
		-- a floor to stand on, and nothing collidable where a body will stand.
		local mapFolder = Workspace:FindFirstChild(MAP.FolderName)
		if mapFolder then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { fixture }
			params.RespectCanCollide = true
			local hit = Workspace:Raycast(at, Vector3.new(0, -PLOT.TeleportGroundProbe, 0), params)
			check(hit ~= nil and hit.Instance:IsDescendantOf(mapFolder) and math.abs(hit.Position.Y - MAP.GroundY) < 0.5,
				"on the map in Edit: the field's floor is under the landing", hit and hit.Instance:GetFullName())
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Exclude
			overlap.FilterDescendantsInstances = { fixture }
			local solid = {}
			for _, part in ipairs(Workspace:GetPartBoundsInBox(CFrame.new(at.X, MAP.GroundY + 4, at.Z),
				Vector3.new(8, 7, 8), overlap)) do
				if part.CanCollide and part.Name ~= "Terrain" then
					table.insert(solid, part:GetFullName())
				end
			end
			check(#solid == 0, "and nothing collidable in the 8 x 7 x 8 box a body lands in", table.concat(solid, ", "))
		else
			say("  (no map in this Edit session: the floor and clearance checks are Play's)")
		end
	end

	-- The press, by TELEPORT TO PLOT's rules: from the field it lands there; the
	-- cooldown is the one TELEPORT TO PLOT shares; the road, a raided pod, a trap
	-- and a knock-down refuse it exactly as they refuse TELEPORT TO PLOT.
	if landingB and Workspace:FindFirstChild(MAP.FolderName) then
		local j = makePlayer("SpecBiomes", -410, IN_FIELD)
		leases[j] = plotA
		j.root.AssemblyLinearVelocity = Vector3.new(0, 0, 50)
		local bMoved, bCode = PlotService.TeleportToBiomes(j)
		check(bMoved == true and bCode == nil and (j.root.Position - landingB.Position).Magnitude < 0.05
				and j.root.CFrame.LookVector:Dot(landingB.LookVector) > 0.999
				and j.root.AssemblyLinearVelocity.Magnitude < 0.01,
			"a press in the Safe Zone lands at the Greenhollow entrance, facing the road, momentum taken off",
			tostring(bCode) .. " " .. tostring(j.root.Position))
		standAt(j, IN_FIELD)
		local b2Moved, b2Code = PlotService.TeleportToBiomes(j)
		local homeMoved2, homeCode2 = PlotService.TeleportHome(j)
		check(not b2Moved and b2Code == "TELEPORT_COOLDOWN" and not homeMoved2 and homeCode2 == "TELEPORT_COOLDOWN"
				and still(j, IN_FIELD),
			"and it shares TELEPORT TO PLOT's cooldown: neither button works again straight away",
			tostring(b2Code) .. " / " .. tostring(homeCode2))

		local k = makePlayer("SpecBiomesHeld", -411, ON_ROAD)
		local rMoved, rCode = PlotService.TeleportToBiomes(k)
		standAt(k, IN_FIELD)
		k:SetAttribute(ATTR.CarryingSpecies, "nubkin")
		local cMoved, cCode = PlotService.TeleportToBiomes(k)
		k:SetAttribute(ATTR.CarryingSpecies, nil)
		k:SetAttribute(ATTR.Trapped, true)
		local tMoved, tCode = PlotService.TeleportToBiomes(k)
		k:SetAttribute(ATTR.Trapped, nil)
		k.humanoid.PlatformStand = true
		local dMoved, dCode = PlotService.TeleportToBiomes(k)
		k.humanoid.PlatformStand = false
		k.humanoid.Health = 0
		local xMoved, xCode = PlotService.TeleportToBiomes(k)
		k.humanoid.Health = k.humanoid.MaxHealth
		check(not rMoved and rCode == "TELEPORT_OUTSIDE" and not cMoved and cCode == "CARRYING_POD"
				and not tMoved and tCode == "TELEPORT_STUNNED" and not dMoved and dCode == "TELEPORT_STUNNED"
				and not xMoved and xCode == nil and still(k, IN_FIELD),
			"from the road, with an unbanked raided pod, trapped, knocked down or dead: refused as TELEPORT TO PLOT is",
			string.format("%s %s %s %s %s", tostring(rCode), tostring(cCode), tostring(tCode), tostring(dCode),
				tostring(xCode)))
		local freeMoved3 = PlotService.TeleportToBiomes(k)
		check(freeMoved3 == true and (k.root.Position - landingB.Position).Magnitude < 0.05,
			"and none of those refusals spent the cooldown")
	else
		say("  (no map in this Edit session: the press itself is Play's)")
	end

	-- Nothing the client sends is read: the handler passes the sender alone, and
	-- the destination is BiomesLanding's.
	local handlerB = plotSource and string.match(plotSource,
		"channel%.OnServerEvent:Connect%((function%([^)]*%).-)\n\t\tend%)%)")
	check(handlerB ~= nil and string.find(handlerB, "PlotService.TeleportToBiomes(player)", 1, true) ~= nil
			and string.find(handlerB, "if action == PLOT.BiomesAction then", 1, true) ~= nil,
		"the one GameEvent handler hands TeleportToBiomes the sender alone, for the verb alone")
	check(plotSource ~= nil
			and string.find(plotSource, "function PlotService.TeleportToBiomes(player: Player): (boolean, string?)", 1, true) ~= nil
			and string.find(plotSource, "return PlotService.TeleportTo(player, landing, \"BIOMES_BLOCKED\")", 1, true) ~= nil
			and string.find(plotSource, "local landing = PlotService.BiomesLanding()", 1, true) ~= nil,
		"TeleportToBiomes takes a player and nothing else, and lands only at BiomesLanding, through TeleportTo")
	local biomesUi = sourceOf(scripts and scripts:FindFirstChild("BiomesButtonUI"))
	local _, biomesFires = string.gsub(biomesUi or "", "FireServer%(", "")
	check(biomesUi ~= nil and biomesFires == 1
			and string.find(biomesUi, "remote:FireServer(PLOT.BiomesAction)", 1, true) ~= nil,
		"the button sends the verb and nothing else", biomesFires)
	check(ActionRefusal.Text.BIOMES_BLOCKED ~= nil and #ActionRefusal.Text.BIOMES_BLOCKED <= 40
			and ActionRefusal.Notices.BIOMES_BLOCKED ~= nil,
		"and its one refusal of its own -- nothing to stand on -- has words and a notice")
	-- No other biome is a destination: nothing in the server names another landing.
	local others = {}
	for _, id in ipairs({ "dustbowl", "tanglemire", "emberroot", "starbloom" }) do
		if plotSource and string.find(plotSource, "\"" .. id .. "\"", 1, true) then
			table.insert(others, id)
		end
	end
	check(#others == 0, "and no other biome is named as a destination", table.concat(others, ", "))
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

PlotService.PlotOf = realPlotOf
fixture:Destroy()

say(string.format("\nPlotTeleportSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
