--!strict
-- Steal a Seed :: PodMotion (shared maths; PodMotion.client plays it)
--
-- The owner's 25 pods' idles, on the client, over the anchored parts PodModel
-- built. The owner's pods each carried a server Script -- a Heartbeat loop that
-- moved the anchored root and waved Motor6D C0s. In a full server that is
-- dozens of loops moving parts on the server and sending every move over the
-- network, so none was imported: one client animator moves only what each
-- player sees.
--
--==============================================================================
-- NOTHING BREATHES (the owner, 2026-10-09: "disable breathing animation on
-- pods"). The scripts' `breathBob` -- the root's own bob, and the roll, pitch or
-- sway that rode on it -- is gone; no lid pod breathes either. What stays is the
-- motion of the pod's parts: each studded pod's joints wave as its script waved
-- them, each lid pod's lid peeks, and both pulse their lights.
--
-- A KINEMATIC TREE OVER ANCHORED PARTS
--
-- Every part stays anchored (the pod contract), so a joint moves nothing by
-- itself. The rig walks the joints from the pod's root (PodModel marked it) and
-- knows where every part rests in the Shell's frame. Each step it writes only
-- the parts a waving joint carries: Part1 = Part0 * C0 * pose * C1:Inverse(),
-- where `pose` is what the owner's script multiplied onto C0, from the Shell --
-- never from a pose this file wrote -- so a server move or a PlantSway pivot
-- composes, and a rebuilt rig cannot drift. The rest of the pod is never
-- written.
--
-- A part the owner anchored besides the root stood still in its script; it and
-- anything hanging only off it stay out of the tree.
--
-- THE STUDDED PODS play their own scripts' joint motions, number for number
-- (`STUDDED` below, each with its script's rate). Crookreed's script looked for
-- its PollenHeart and its eight tip joints inside parts they are not in, so in
-- Studio it stalled at its fifth line and never moved: here it moves as its
-- script wrote it to.
--
-- THE LID PODS had no idle (their script only opened the lid by OpenAmount), so
-- theirs is new: the lid peeking open a crack and shut, and their lights
-- pulsing (GameConfig.PodModels.Motion).
--
-- A READY POD (an old save's planted pod with its Ready attribute): a studded
-- pod's idle runs faster; a lid pod's lid stands part way open.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))
local PodForms = require(Shared:WaitForChild("PodForms"))
local PodModel = require(Shared:WaitForChild("PodModel"))

local M = GameConfig.PodModels.Motion

local PodMotion = {}

local rad, sin, cos, pi, exp = math.rad, math.sin, math.cos, math.pi, math.exp
local IDENTITY = CFrame.identity

-- Client-only, on each owner light: its brightness as built, so a rig rebuilt
-- after the light was pulsed starts from the light's own number.
local LIGHT_BASE = "PodLightBase"

export type Node = {
	part: BasePart,
	parent: number?,
	forward: boolean,
	c0: CFrame,
	c1: CFrame,
	c0Inv: CFrame,
	c1Inv: CFrame,
	joint: string?,
	-- Where it rests, in the Shell's frame.
	rest: CFrame,
	-- Whether a waving joint carries it (it is written), and its frame this step.
	moves: boolean,
	cf: CFrame,
}

export type Lamp = { light: PointLight, base: number }

export type Rig = {
	model: Model,
	form: string,
	studded: boolean,
	scale: number,
	shell: BasePart,
	-- nodes[1] is the root; `moving` holds the node indices a waving joint
	-- carries, parent before child, with their parts and frames aligned.
	nodes: { Node },
	moving: { number },
	parts: { BasePart },
	cframes: { CFrame },
	pose: { [string]: CFrame },
	lamps: { [string]: Lamp },
	cycle: number,
	phase: number,
	speed: number,
	open: number,
	written: number?,
	writtenAt: number,
	lidJoint: string?,
	lidDegrees: number,
	still: boolean,
}

--==============================================================================
-- THE STUDDED PODS' JOINT MOTIONS, AS THEIR SCRIPTS WROTE THEM
--
-- `rate` is each script's own: cycle += dt * IdleSpeed * rate. `pose` sets
-- each joint's pose by the joint's name, and each named light's brightness.
-- (Each script's breathBob line, and the root's roll, pitch or sway, are the
-- breathing the owner switched off.)
--==============================================================================
type Recipe = { rate: number, pose: (Rig, number) -> () }

local function lamp(rig: Rig, name: string, brightness: number)
	local l = rig.lamps[name]
	if l then
		l.light.Brightness = brightness
	end
end

local STUDDED: { [string]: Recipe } = {
	-- Tulip-bud petals flexing in and out.
	petalpip = { rate = 2.0, pose = function(rig: Rig, c: number)
		for i = 1, 5 do
			rig.pose["PetalJoint" .. i] = CFrame.Angles(sin(c + i * 0.25) * rad(2.0), 0, 0)
		end
	end },
	-- A helical twist through the waist and the tip.
	spiretip = { rate = 2.0, pose = function(rig: Rig, c: number)
		local twist = sin(c) * rad(2.2)
		local sway = cos(c * 0.8) * rad(1.8)
		rig.pose.WaistJoint = CFrame.Angles(0, twist, 0)
		rig.pose.TipJoint = CFrame.Angles(sway, twist * 0.6, 0)
	end },
	-- Two sprout leaves fluttering in the breeze.
	nubkin = { rate = 2.2, pose = function(rig: Rig, c: number)
		rig.pose.SproutJointL = CFrame.Angles(0, 0, sin(c * 1.3) * rad(6) + cos(c * 0.8) * rad(3))
		rig.pose.SproutJointR = CFrame.Angles(0, 0, -sin(c * 1.3 + 0.4) * rad(6) - cos(c * 0.8) * rad(3))
	end },
	-- The corona's eight spikes flaring, the heart's glow.
	suncrown = { rate = 2.0, pose = function(rig: Rig, c: number)
		for i = 1, 8 do
			rig.pose["SpikeJoint" .. i] = CFrame.Angles(sin(c + i * 0.35) * rad(2.4), 0, 0)
		end
		lamp(rig, "SolarGlow", 2.45 + sin(c * 1.8) * 0.65)
	end },
	-- Four lobes flexing, the dew drop quivering on the rim, the gold's glow.
	raincup = { rate = 2.0, pose = function(rig: Rig, c: number)
		for i = 1, 4 do
			rig.pose["LobeJoint" .. i] = CFrame.Angles(sin(c + i * 0.4) * rad(1.8), 0, 0)
		end
		local quiver = sin(c * 3.2) * rad(3.5) + cos(c * 2.1) * rad(2.0)
		rig.pose.DewDropJoint = CFrame.Angles(quiver, 0, quiver * 0.6)
		lamp(rig, "GoldGlow", 1.45 + sin(c * 1.6) * 0.4)
	end },
	-- The bloom nodding on top (the waddle it nodded against stays in its sum).
	paddlehop = { rate = 2.2, pose = function(rig: Rig, c: number)
		local waddle = sin(c * 0.9) * rad(1.8)
		rig.pose.BloomJoint = CFrame.Angles(0, 0, -waddle * 1.3 + sin(c * 1.5) * rad(1.2))
	end },
	-- Five blades breathing in a helix.
	thornwhorl = { rate = 2.0, pose = function(rig: Rig, c: number)
		for i = 1, 5 do
			rig.pose["BladeJoint" .. i] = CFrame.Angles(sin(c + i * 0.35) * rad(2.2), cos(c + i * 0.35) * rad(1.4), 0)
		end
	end },
	-- The lifted front plate flexing.
	dunebud = { rate = 2.0, pose = function(rig: Rig, c: number)
		rig.pose.LiftedHuskJoint = CFrame.Angles(sin(c * 1.1) * rad(2.4), 0, 0)
	end },
	-- Five digits clenching, the magma's flicker.
	cinderpaw = { rate = 2.2, pose = function(rig: Rig, c: number)
		local s = sin(c)
		local YAW = { -1.8, -1.0, 0, 1.0, 1.8 }
		local ROLL = { -2.2, -1.2, 0, 1.2, 2.2 }
		for i = 1, 5 do
			rig.pose["Digit" .. i .. "Joint"] = CFrame.Angles(s * rad(2.2), s * rad(YAW[i]), s * rad(ROLL[i]))
		end
		lamp(rig, "EmberCoreLight", 2.4 + sin(c * 1.5) * 0.45 + sin(c * 4.3) * 0.12 + cos(c * 2.7) * 0.18)
	end },
	-- The spire swaying like a candle in a draft, its flame.
	emberquill = { rate = 2.1, pose = function(rig: Rig, c: number)
		rig.pose.CenterSpireJoint = CFrame.Angles(sin(c * 0.8) * rad(1.6), 0, cos(c * 0.65) * rad(1.4))
		lamp(rig, "CandleLight", 2.65 + sin(c * 1.8) * 0.35 + sin(c * 7.3) * 0.12 + cos(c * 11.1) * 0.08)
	end },
	-- The reed crown swaying in a marsh breeze, eight tips fluttering, the pollen's glow.
	crookreed = { rate = 2.1, pose = function(rig: Rig, c: number)
		local sway = sin(c * 0.85) * rad(2.2)
		local roll = cos(c * 0.65) * rad(1.6)
		rig.pose.CrownJoint = CFrame.Angles(sway, 0, roll)
		for i = 1, 8 do
			local flutter = sin(c * 1.4 + i * 0.45) * rad(3.4)
			rig.pose["TipJoint" .. i] = CFrame.Angles(flutter, 0, flutter * 0.4)
		end
		lamp(rig, "MarshGlow", 1.45 + sin(c * 1.8) * 0.45)
	end },
	-- The handle swinging, candlelight flickering.
	lanterncap = { rate = 2.0, pose = function(rig: Rig, c: number)
		rig.pose.HandleJoint = CFrame.Angles(0, 0, sin(c * 1.2) * rad(4.2))
		lamp(rig, "LanternLight", 2.45 + sin(c * 1.5) * 0.45 + sin(c * 3.1) * 0.15 + cos(c * 1.7) * 0.25)
	end },
}
PodMotion.Studded = STUDDED

-- Every joint each studded recipe poses and every light it pulses, for the spec
-- ("every animation recipe finds its joints") and for the rig (only these
-- joints' parts are written).
PodMotion.RecipeJoints = {
	petalpip = { "PetalJoint1", "PetalJoint2", "PetalJoint3", "PetalJoint4", "PetalJoint5" },
	spiretip = { "WaistJoint", "TipJoint" },
	nubkin = { "SproutJointL", "SproutJointR" },
	suncrown = { "SpikeJoint1", "SpikeJoint2", "SpikeJoint3", "SpikeJoint4", "SpikeJoint5", "SpikeJoint6",
		"SpikeJoint7", "SpikeJoint8" },
	raincup = { "LobeJoint1", "LobeJoint2", "LobeJoint3", "LobeJoint4", "DewDropJoint" },
	paddlehop = { "BloomJoint" },
	thornwhorl = { "BladeJoint1", "BladeJoint2", "BladeJoint3", "BladeJoint4", "BladeJoint5" },
	dunebud = { "LiftedHuskJoint" },
	cinderpaw = { "Digit1Joint", "Digit2Joint", "Digit3Joint", "Digit4Joint", "Digit5Joint" },
	emberquill = { "CenterSpireJoint" },
	crookreed = { "CrownJoint", "TipJoint1", "TipJoint2", "TipJoint3", "TipJoint4", "TipJoint5", "TipJoint6",
		"TipJoint7", "TipJoint8" },
	lanterncap = { "HandleJoint" },
} :: { [string]: { string } }
PodMotion.RecipeLights = {
	suncrown = { "SolarGlow" },
	raincup = { "GoldGlow" },
	cinderpaw = { "EmberCoreLight" },
	emberquill = { "CandleLight" },
	crookreed = { "MarshGlow" },
	lanterncap = { "LanternLight" },
} :: { [string]: { string } }
-- A lid pod's one moving joint.
PodMotion.LID_JOINT = "LidHinge"

--==============================================================================
-- THE RIG
--==============================================================================
-- Whether this model is one PodMotion can animate at all (the attributes
-- PodModel writes); where and whether it moves is the client's call.
function PodMotion.IsPod(model: Instance): boolean
	return model:IsA("Model") and PodForms.Has(model:GetAttribute(PodModel.FORM_ATTRIBUTE) :: any)
end

function PodMotion.Rig(model: Model): Rig?
	local shell = model.PrimaryPart
	local form = model:GetAttribute(PodModel.FORM_ATTRIBUTE)
	local rootRest = model:GetAttribute(PodModel.REST_ATTRIBUTE)
	if not (shell and type(form) == "string" and PodForms.Has(form) and typeof(rootRest) == "CFrame") then
		return nil
	end
	local parts: { BasePart } = {}
	local index: { [BasePart]: number } = {}
	local root: number? = nil
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			index[d] = #parts
			if d:GetAttribute(PodModel.ROOT_ATTRIBUTE) == true then
				root = #parts
			end
		end
	end
	if not root then
		return nil
	end
	local studded = PodForms.IsStudded(form)
	-- The joints this pod's idle waves: only their parts are ever written.
	local waving: { [string]: boolean } = {}
	if studded then
		for _, name in ipairs(PodMotion.RecipeJoints[form] or {}) do
			waving[name] = true
		end
	else
		waving[PodMotion.LID_JOINT] = true
	end
	-- Every joint, as an edge both ways.
	type Edge = { other: number, joint: any, forward: boolean }
	local edges: { [number]: { Edge } } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") or d:IsA("Weld") then
			local j = d :: any
			local a, b = index[j.Part0], index[j.Part1]
			if a and b and a ~= b then
				edges[a] = edges[a] or {}
				edges[b] = edges[b] or {}
				table.insert(edges[a], { other = b, joint = j, forward = true })
				table.insert(edges[b], { other = a, joint = j, forward = false })
			end
		end
	end
	-- Breadth first from the root, never into a part the owner kept still; each
	-- part's rest worked out from its parent's through its joint, at rest.
	local nodes: { Node } = {}
	local nodeOf: { [number]: number } = {}
	local function add(i: number, parent: number?, edge: Edge?)
		local j = if edge then edge.joint else nil
		local c0: CFrame = if j then j.C0 else IDENTITY
		local c1: CFrame = if j then j.C1 else IDENTITY
		local forward = if edge then edge.forward else true
		local rest: CFrame
		local moves = false
		local name: string? = if j then j.Name else nil
		if parent then
			local p = nodes[parent]
			rest = if forward then p.rest * c0 * c1:Inverse() else p.rest * c1 * c0:Inverse()
			moves = p.moves or (name ~= nil and waving[name] == true)
		else
			rest = rootRest
		end
		table.insert(nodes, {
			part = parts[i],
			parent = parent,
			forward = forward,
			c0 = c0,
			c1 = c1,
			c0Inv = c0:Inverse(),
			c1Inv = c1:Inverse(),
			joint = name,
			rest = rest,
			moves = moves,
			cf = shell.CFrame * rest,
		})
		nodeOf[i] = #nodes
	end
	add(root, nil, nil)
	local head = 1
	while head <= #nodes do
		local at = head
		head += 1
		local partIndex = index[nodes[at].part]
		for _, edge in ipairs(edges[partIndex] or {}) do
			local other = edge.other
			if not nodeOf[other] and parts[other]:GetAttribute(SecretModel.FIXED_ATTRIBUTE) ~= true then
				add(other, at, edge)
			end
		end
	end
	local moving: { number } = {}
	local movingParts: { BasePart } = {}
	local cframes: { CFrame } = {}
	for i, node in ipairs(nodes) do
		if node.moves then
			table.insert(moving, i)
			table.insert(movingParts, node.part)
			table.insert(cframes, node.cf)
		end
	end
	-- The owner's lights in the tree, by name, with their brightness as built.
	local lamps: { [string]: Lamp } = {}
	for _, node in ipairs(nodes) do
		for _, child in ipairs(node.part:GetChildren()) do
			if child:IsA("PointLight") then
				local base = child:GetAttribute(LIGHT_BASE)
				if type(base) ~= "number" then
					base = child.Brightness
					child:SetAttribute(LIGHT_BASE, base)
				end
				lamps[child.Name] = { light = child, base = base :: number }
			end
		end
	end
	local spec = PodForms.Pods[form]
	local owner = spec and spec.Owner
	local speed = if owner and type(owner.IdleSpeed) == "number" then owner.IdleSpeed else 1
	-- Two pods side by side should not move in step: a phase off where it stands.
	local at = shell.Position
	local phase = (math.floor(math.abs(at.X * 13 + at.Z * 7)) % 97) / 97 * 10
	local lidJoint: string? = nil
	for _, node in ipairs(nodes) do
		if node.joint == PodMotion.LID_JOINT then
			lidJoint = node.joint
		end
	end
	return {
		model = model,
		form = form,
		studded = studded,
		scale = tonumber(model:GetAttribute(PodModel.SCALE_ATTRIBUTE)) or 1,
		shell = shell,
		nodes = nodes,
		moving = moving,
		parts = movingParts,
		cframes = cframes,
		pose = {},
		lamps = lamps,
		cycle = phase,
		phase = phase,
		speed = speed,
		open = 0,
		written = nil,
		writtenAt = 0,
		lidJoint = lidJoint,
		lidDegrees = PodForms.LidDegrees[form] or 65,
		still = true,
	}
end

--==============================================================================
-- ONE FRAME: the poses, then the moving parts written from the Shell.
--==============================================================================
local function apply(rig: Rig)
	local nodes, pose, cframes = rig.nodes, rig.pose, rig.cframes
	local shellCF = rig.shell.CFrame
	for k, i in ipairs(rig.moving) do
		local node = nodes[i]
		local parent = nodes[node.parent :: number]
		local p = if parent.moves then parent.cf else shellCF * parent.rest
		local joint = if node.joint then (pose[node.joint] or IDENTITY) else IDENTITY
		if node.forward then
			node.cf = p * node.c0 * joint * node.c1Inv
		else
			node.cf = p * node.c1 * joint:Inverse() * node.c0Inv
		end
		cframes[k] = node.cf
	end
	if #rig.parts > 0 then
		Workspace:BulkMoveTo(rig.parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- A lid's peek: shut most of the time; every PeekEvery seconds it opens to
-- PeekOpen and shuts again over PeekSeconds, smooth both ways.
function PodMotion.PeekAt(t: number): number
	local into = t % M.PeekEvery
	if into >= M.PeekSeconds then
		return 0
	end
	return M.PeekOpen * sin(pi * into / M.PeekSeconds)
end

-- One step at clock `now` (seconds), `dt` since the last, `ready` the pod's
-- Ready attribute.
function PodMotion.Step(rig: Rig, now: number, dt: number, ready: boolean)
	rig.still = false
	if rig.studded then
		local recipe = STUDDED[rig.form]
		if recipe then
			local hurry = if ready then M.ReadySpeed else 1
			rig.cycle += dt * rig.speed * recipe.rate * hurry
			recipe.pose(rig, rig.cycle)
		end
		apply(rig)
		return
	end
	local t = now + rig.phase
	local target = if ready then M.ReadyOpen else PodMotion.PeekAt(t)
	local ease = if ready then M.ReadyEase else 0.12
	rig.open += (target - rig.open) * (1 - exp(-dt * 3 / ease))
	local pulse = 1 + M.GlowPulse * sin(2 * pi * t / 2.6)
	for _, l in pairs(rig.lamps) do
		l.light.Brightness = l.base * pulse
	end
	-- A lid that has not moved is not written again -- but once a second it is,
	-- in case the server put the parts back where it built them.
	if rig.lidJoint and (rig.written == nil or math.abs(rig.open - rig.written) > 1e-4 or now - rig.writtenAt > 1) then
		rig.pose[rig.lidJoint] = CFrame.Angles(rad(rig.lidDegrees) * rig.open, 0, 0)
		rig.written = rig.open
		rig.writtenAt = now
		apply(rig)
	end
end

-- Rest, written once: every joint at its rest, the lid shut, the lights as built.
function PodMotion.Rest(rig: Rig)
	table.clear(rig.pose)
	rig.open = 0
	rig.written = nil
	for _, l in pairs(rig.lamps) do
		l.light.Brightness = l.base
	end
	apply(rig)
	rig.still = true
end

return PodMotion
