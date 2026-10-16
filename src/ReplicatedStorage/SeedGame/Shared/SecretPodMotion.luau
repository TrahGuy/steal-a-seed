--!strict
-- Steal a Seed :: SecretPodMotion (shared maths; SecretPodMotion.client plays it)
--
-- The owner's three biome secret pod scripts (BiomeSecretForms, 2026-10-16),
-- played on the client over the pods SecretModel replays:
--
--   SunPulse    Scourwheel's pod. The winged sun bobs and beats its wings; the
--               eyes, ankhs and sun glow brighter and softer; the lights swell;
--               the aura breathes.
--   MawPulse    Nebulisk's pod. The jaw breathes on its hinge, and every 8 s it
--               gapes wide and snaps shut, flaring the throat light and core with
--               a burst of sparks; the lure sways on its hook; the rift spins; the
--               drool strings stretch; the glows, lights and aura as SunPulse's.
--   PodOpening  Grovemaw's pod. The lid swings open on its hinge (LidDegrees at
--               OpenAmount 1, over the form's OpenDuration, Quad Out) when the pod
--               is READY TO HATCH (the owner, 2026-10-16) -- in its owner's hands.
--
-- The Tanglemire and Emberroot pods came with no script and stay as built.
--
--==============================================================================
-- ON THE CRADLE: THE SCRIPTS' OWN MATHS, OVER ANCHORED PARTS
--
-- Both idles placed their moving parts "relative to the pod every frame", from
-- the model's pivot: here the owner's pivot (FormSpec.Pivot) on the base under
-- the Shell. Each part's rest is the FORM's (by the FormIndex SecretModel wrote
-- on it), never the part's own CFrame, so a rig rebuilt mid-gape cannot take a
-- gape for rest. Every distance the scripts read off an attribute (the bob, the
-- wing roots, the jaw hinge, the lure hook, the strands' ends) was written
-- before the owner rescaled the model, so it is taken times the form's
-- ModelScale (measured in Studio: the strands then sit on their parts exactly).
-- A size, colour, transparency or brightness at rest is the form's as built: an
-- aura's or the gullet's BaseSize is the old size.
--
-- Only an anchored pod moves this way. A carried, hauled or held one is welded,
-- and writing its parts would move whoever holds it.
--
-- IN THE HANDS: THE LID, BY ITS JOINT
--
-- A held pod's parts are welded to its Handle (CarryService.giveTool) and keep
-- the owner's joints. The lid's own parts -- the hinge's far side and all that
-- is jointed to it -- are let go of the Handle on this client only, and the
-- hinge's C0 is turned (what PodOpening tweened), so the lid swings on the pod in
-- every viewer's copy without a part written or a property sent.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local BiomeSecretForms = require(Shared:WaitForChild("BiomeSecretForms"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))

local SecretPodMotion = {}

local rad, sin, cos, pi, exp = math.rad, math.sin, math.cos, math.pi, math.exp
local TURN = 2 * pi

-- Which of the owner's scripts each pod form played.
SecretPodMotion.Scripts = {
	scourwheelpod = "sunpulse",
	nebuliskpod = "mawpulse",
	grovemawpod = "lid",
} :: { [string]: string }

-- PodOpening's hinge, how far it swings at OpenAmount 1, and its tween's length
-- when the form names none.
SecretPodMotion.LID_JOINT = "LidHinge"
SecretPodMotion.LidDegrees = 70
SecretPodMotion.LidSeconds = 0.45

-- Client-only, on a lid's hinge: its C0 as built, so a lid measured again after
-- it was turned still swings from where the owner hung it.
local REST_C0 = "SeedRestC0"

type Placed = { part: BasePart, rest: CFrame }
-- SunPulse's bobbing parts, and the wing parts' turn about their root.
type Mover = { part: BasePart, rest: CFrame, amp: number, side: number?, root: CFrame?, fromRoot: CFrame? }
type Spinner = { part: BasePart, pos: Vector3, turn: CFrame, speed: number }
type Strand = { part: BasePart, top: Vector3, bottom: Vector3, thick: number }
type Glow = { part: BasePart, base: Color3, hot: Color3 }
type Lamp = { light: PointLight, base: number, built: number, driven: boolean }
-- What Rest puts back: a part's CFrame, size, colour and transparency as built.
type Built = { part: BasePart, rest: CFrame, size: Vector3, color: Color3, transparency: number }

export type Rig = {
	model: Model,
	form: string,
	kind: string,
	shell: BasePart,
	-- The owner's pivot in the Shell's frame.
	pivot: CFrame,
	movers: { Mover },
	jaw: { Placed },
	lure: { Placed },
	spin: { Spinner },
	strands: { Strand },
	core: BasePart?,
	coreSize: Vector3,
	glows: { Glow },
	-- The colour tweens' and the lights' half period (2.2 s SunPulse, 2.0 s MawPulse).
	half: number,
	lamps: { Lamp },
	aura: BasePart?,
	auraT: number,
	auraSize: Vector3,
	embers: ParticleEmitter?,
	hinge: CFrame,
	unhinge: CFrame,
	hook: CFrame,
	unhook: CFrame,
	phase: number,
	lastBite: number,
	-- Every part this rig touches, as built; and the parts it moves, with this
	-- frame's CFrames, for one BulkMoveTo.
	built: { Built },
	moved: { BasePart },
	cframes: { CFrame },
	still: boolean,
}

-- Whether a pod form plays an idle on the cradle.
function SecretPodMotion.HasIdle(form: any): boolean
	local kind = if type(form) == "string" then SecretPodMotion.Scripts[form] else nil
	return kind == "sunpulse" or kind == "mawpulse"
end

-- Whether a pod form's lid opens when it is ready.
function SecretPodMotion.HasLid(form: any): boolean
	return type(form) == "string" and SecretPodMotion.Scripts[form] == "lid"
end

--==============================================================================
-- THE CRADLE RIG
--==============================================================================
function SecretPodMotion.Rig(model: Model): Rig?
	local shell = model.PrimaryPart
	local form = model:GetAttribute(SecretModel.FORM_ATTRIBUTE)
	if not (shell and type(form) == "string" and SecretPodMotion.HasIdle(form)) then
		return nil
	end
	local spec = BiomeSecretForms.Pods[form]
	if not spec then
		return nil
	end
	local k = spec.ModelScale or 1
	local owner = spec.Owner or {}
	local ownerPivot = spec.Pivot or CFrame.identity
	local unpivot = ownerPivot:Inverse()
	local hinge = CFrame.new((if typeof(owner.JawHinge) == "Vector3" then owner.JawHinge else Vector3.zero) * k)
	local hook = CFrame.new((if typeof(owner.LureHook) == "Vector3" then owner.LureHook else Vector3.zero) * k)
	local at = shell.Position
	local rig: Rig = {
		model = model,
		form = form,
		kind = SecretPodMotion.Scripts[form],
		shell = shell,
		pivot = CFrame.new(0, -SecretModel.SHELL_LIFT, 0) * ownerPivot,
		movers = {},
		jaw = {},
		lure = {},
		spin = {},
		strands = {},
		core = nil,
		coreSize = Vector3.one,
		glows = {},
		half = if SecretPodMotion.Scripts[form] == "sunpulse" then 2.2 else 2.0,
		lamps = {},
		aura = nil,
		auraT = 0,
		auraSize = Vector3.one,
		embers = nil,
		hinge = hinge,
		unhinge = hinge:Inverse(),
		hook = hook,
		unhook = hook:Inverse(),
		-- Two pods should not move in step: a phase off where it stands.
		phase = (math.floor(math.abs(at.X * 13 + at.Z * 7)) % 97) / 97 * 10,
		lastBite = -1,
		built = {},
		moved = {},
		cframes = {},
		still = true,
	}
	for _, part in ipairs(model:GetChildren()) do
		local index = if part:IsA("BasePart") then part:GetAttribute(SecretModel.INDEX_ATTRIBUTE) else nil
		local row = if type(index) == "number" then spec.Parts[index] else nil
		if not row then
			continue
		end
		local p = part :: BasePart
		local a = row.a or {}
		-- Where it rests, in the owner's pivot frame.
		local rest = unpivot * row.cf
		local touched = false
		if typeof(a.HotColor) == "Color3" and a.Pulse then
			table.insert(rig.glows, { part = p, base = if typeof(a.BaseColor) == "Color3" then a.BaseColor else row.c, hot = a.HotColor })
			touched = true
		end
		if type(a.Bob) == "number" then
			local mover: Mover = { part = p, rest = rest, amp = a.Bob * k }
			if type(a.Flap) == "number" and typeof(a.FlapRoot) == "Vector3" then
				local root = CFrame.new(a.FlapRoot * k)
				mover.side = a.Flap
				mover.root = root
				mover.fromRoot = root:Inverse() * rest
			end
			table.insert(rig.movers, mover)
			touched = true
		end
		if a.Move == "jaw" or a.Move == "lure" then
			table.insert(if a.Move == "jaw" then rig.jaw else rig.lure, { part = p, rest = rest })
			touched = true
		end
		if type(a.Spin) == "number" then
			table.insert(rig.spin, { part = p, pos = rest.Position, turn = rest.Rotation, speed = a.Spin })
			touched = true
		end
		if typeof(a.StrandTop) == "Vector3" then
			local top = a.StrandTop * k
			local bottom = (if typeof(a.StrandBottom) == "Vector3" then a.StrandBottom else a.StrandTop) * k
			table.insert(rig.strands, { part = p, top = top, bottom = bottom, thick = row.z.X })
			touched = true
		end
		if row.n == "Gullet" and rig.kind == "mawpulse" then
			rig.core = p
			rig.coreSize = row.z
			touched = true
		elseif row.n == "Aura" then
			rig.aura = p
			rig.auraT = if type(a.BaseTransparency) == "number" then a.BaseTransparency else (row.t or 0)
			rig.auraSize = row.z
			touched = true
		end
		if touched then
			table.insert(rig.built, { part = p, rest = rest, size = row.z, color = row.c, transparency = row.t or 0 })
		end
	end
	-- The parts it moves, in the order Step writes them.
	local groups: { { any } } = if rig.kind == "sunpulse" then { rig.movers } else { rig.jaw, rig.lure, rig.spin, rig.strands }
	for _, group in ipairs(groups) do
		for _, m in ipairs(group) do
			table.insert(rig.moved, m.part)
		end
	end
	-- Every light: from its BaseBrightness; MawPulse's Driven one is the throat's.
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("PointLight") then
			local host = d.Parent
			local index = if host and host:IsA("BasePart") then host:GetAttribute(SecretModel.INDEX_ATTRIBUTE) else nil
			local built = d.Brightness
			for _, l in ipairs(spec.Lights) do
				if l.p == index and l.n == d.Name then
					built = l.brightness
					break
				end
			end
			local base = d:GetAttribute("BaseBrightness")
			table.insert(rig.lamps, {
				light = d,
				base = if type(base) == "number" then base else built,
				built = built,
				driven = d:GetAttribute("Driven") == true,
			})
		elseif d:IsA("ParticleEmitter") and d.Name == "MawEmbers" then
			rig.embers = d
		end
	end
	return rig
end

--==============================================================================
-- ONE FRAME
--==============================================================================
-- MawPulse's jaw: how far open (degrees), how bright the bite's flare, which
-- cycle, and whether the snap has landed. A slow breath, and every 8 s a gape to
-- WIDE that snaps shut.
local PERIOD, WIDE = 8, 10
local function jawAt(now: number): (number, number, number, boolean)
	local breath = 3 * (1 - cos(now * TURN / 3.2)) / 2
	local cycle = math.floor(now / PERIOD)
	local t = now - cycle * PERIOD
	if t < 0.5 then
		return math.max(breath, WIDE * sin(t / 0.5 * pi / 2)), 0, cycle, false
	elseif t < 0.62 then
		return WIDE * (1 - (t - 0.5) / 0.12), 0, cycle, false
	elseif t < 1.4 then
		return breath * (t - 0.62) / 0.78, exp(-(t - 0.62) * 5), cycle, true
	end
	return breath, 0, cycle, false
end

-- One step at clock `now` (seconds).
function SecretPodMotion.Step(rig: Rig, now: number)
	rig.still = false
	local t = now + rig.phase
	local pivot = rig.shell.CFrame * rig.pivot
	-- The scripts' tweens: each glow from its BaseColor to its HotColor and each
	-- light from 0.7 to 1.3 of its brightness over `half` seconds, the aura to 0.2
	-- clearer and 4% bigger over 2.8, all Sine InOut and back, forever.
	local swing = 0.5 - 0.5 * cos(pi * t / rig.half)
	for _, g in ipairs(rig.glows) do
		g.part.Color = g.base:Lerp(g.hot, swing)
	end
	for _, l in ipairs(rig.lamps) do
		if not l.driven then
			l.light.Brightness = l.base * (0.7 + 0.6 * swing)
		end
	end
	local aura = rig.aura
	if aura then
		local slow = 0.5 - 0.5 * cos(pi * t / 2.8)
		aura.Transparency = rig.auraT + (math.min(rig.auraT + 0.2, 0.95) - rig.auraT) * slow
		aura.Size = rig.auraSize * (1 + 0.04 * slow)
	end
	local cframes = rig.cframes
	local n = 0
	if rig.kind == "sunpulse" then
		-- the winged sun lifts and settles; the wings beat about their roots
		local lift = (1 - cos(t * TURN / 5.6)) / 2
		local beat = rad(5) * sin(t * TURN / 3.2)
		for _, m in ipairs(rig.movers) do
			local up = CFrame.new(0, m.amp * lift, 0)
			n += 1
			cframes[n] = if m.side and m.root and m.fromRoot
				then pivot * up * m.root * CFrame.Angles(0, 0, m.side * beat) * m.fromRoot
				else pivot * up * m.rest
		end
	else
		-- the jaw
		local open, flare, cycle, bitten = jawAt(t)
		local jawSpace = rig.hinge * CFrame.Angles(rad(-open), 0, 0) * rig.unhinge
		local jawWorld = pivot * jawSpace
		for _, m in ipairs(rig.jaw) do
			n += 1
			cframes[n] = jawWorld * m.rest
		end
		if bitten and cycle ~= rig.lastBite then
			rig.lastBite = cycle
			local embers = rig.embers
			if embers then
				pcall(function()
					embers:Emit(16)
				end)
			end
		end
		local core = rig.core
		if core then
			core.Size = rig.coreSize * (1 + 0.4 * flare)
		end
		for _, l in ipairs(rig.lamps) do
			if l.driven then
				l.light.Brightness = l.base * (0.85 + 0.2 * sin(t * pi) + 1.6 * flare)
			end
		end
		-- the lure sways on its hook (only ever forward, away from the face)
		local forward = rad(3) * (1 - cos(t * TURN / 2.9))
		local side = rad(9) * sin(t * TURN / 3.6)
		local sway = pivot * rig.hook * CFrame.Angles(forward, 0, side) * rig.unhook
		for _, m in ipairs(rig.lure) do
			n += 1
			cframes[n] = sway * m.rest
		end
		-- the rift in the throat spins
		for _, m in ipairs(rig.spin) do
			n += 1
			cframes[n] = pivot * CFrame.new(m.pos) * CFrame.Angles(0, 0, (t * m.speed) % TURN) * m.turn
		end
		-- the drool strings, re-fitted between the palate and the moving floor
		for _, s in ipairs(rig.strands) do
			local bottom = (jawSpace * CFrame.new(s.bottom)).Position
			local d = s.top - bottom
			s.part.Size = Vector3.new(s.thick, d.Magnitude, s.thick)
			n += 1
			cframes[n] = pivot * CFrame.new((s.top + bottom) / 2) * CFrame.Angles(math.atan2(d.Z, d.Y), 0, 0)
		end
	end
	if n > 0 then
		Workspace:BulkMoveTo(rig.moved, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- Rest, written once: every part it touches as built, every light as built.
-- `place` false leaves where the parts are alone -- for a pod that has just been
-- picked up and welded, whose joints now hold them where the server built them.
function SecretPodMotion.Rest(rig: Rig, place: boolean)
	local pivot = rig.shell.CFrame * rig.pivot
	local parts, cframes = {}, {}
	for _, b in ipairs(rig.built) do
		b.part.Size = b.size
		b.part.Color = b.color
		b.part.Transparency = b.transparency
		table.insert(parts, b.part)
		table.insert(cframes, pivot * b.rest)
	end
	if place and #parts > 0 then
		Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for _, l in ipairs(rig.lamps) do
		l.light.Brightness = l.built
	end
	rig.still = true
end

--==============================================================================
-- THE LID IN THE HANDS
--==============================================================================
export type Lid = {
	hinge: Motor6D,
	rest: CFrame,
	-- The Handle's welds on the lid's parts, let go of while it swings.
	holds: { WeldConstraint },
	open: number,
}

-- The lid of a held pod (any container of its parts: the Tool), or nil.
function SecretPodMotion.Lid(container: Instance): Lid?
	local hinge: Motor6D? = nil
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == SecretPodMotion.LID_JOINT then
			hinge = d
			break
		end
	end
	if not hinge then
		return nil
	end
	local core, lidRoot = hinge.Part0, hinge.Part1
	if not (core and lidRoot) then
		return nil
	end
	-- The lid: the hinge's far side and every part jointed to it, never back
	-- across the hinge.
	local links: { [BasePart]: { BasePart } } = {}
	for _, d in ipairs(container:GetDescendants()) do
		if (d:IsA("Weld") or d:IsA("Motor6D")) and d ~= hinge then
			local j = d :: any
			local a, b = j.Part0, j.Part1
			if a and b then
				links[a] = links[a] or {}
				links[b] = links[b] or {}
				table.insert(links[a], b)
				table.insert(links[b], a)
			end
		end
	end
	local lid: { [BasePart]: boolean } = { [lidRoot] = true }
	local queue = { lidRoot }
	local head = 1
	while head <= #queue do
		local at = queue[head]
		head += 1
		for _, other in ipairs(links[at] or {}) do
			if not lid[other] then
				lid[other] = true
				table.insert(queue, other)
			end
		end
	end
	-- Joined back to the core some other way: not a lid that can swing.
	if lid[core] then
		return nil
	end
	local holds: { WeldConstraint } = {}
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("WeldConstraint") then
			local a, b = d.Part0, d.Part1
			if (a and lid[a]) or (b and lid[b]) then
				table.insert(holds, d)
			end
		end
	end
	local rest = hinge:GetAttribute(REST_C0)
	if typeof(rest) ~= "CFrame" then
		rest = hinge.C0
		hinge:SetAttribute(REST_C0, rest)
	end
	return { hinge = hinge, rest = rest :: CFrame, holds = holds, open = 0 }
end

-- PodOpening's swing at `amount` (0 shut, 1 open). Once it has opened, the lid
-- hangs on its hinge alone.
function SecretPodMotion.SetLid(lid: Lid, amount: number)
	if amount > 0 then
		for _, w in ipairs(lid.holds) do
			w.Enabled = false
		end
	end
	lid.open = amount
	lid.hinge.C0 = lid.rest * CFrame.Angles(rad(SecretPodMotion.LidDegrees) * amount, 0, 0)
end

-- PodOpening's tween: Quad Out from `from` to `to` over `seconds`, `elapsed` in.
function SecretPodMotion.LidAt(from: number, to: number, elapsed: number, seconds: number): number
	if seconds <= 0 or elapsed >= seconds then
		return to
	end
	local x = math.max(0, elapsed / seconds)
	return from + (to - from) * (1 - (1 - x) * (1 - x))
end

return SecretPodMotion
