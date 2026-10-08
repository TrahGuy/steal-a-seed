--!strict
--==============================================================================
-- Steal a Seed :: MillFormMotion
--
-- THE OWNER'S MILLS MOVE AS THEIR OWN SCRIPTS MOVED THEM (2026-10-06)
--
-- Tiers 11-14 came with a client script each -- AbyssBrain, ForgeBrain,
-- GlacierBrain, SingularityBrain -- that moved its decor every frame: kelp that
-- sways joint by joint, jellyfish that pulse and drift, a trip-hammer that
-- strikes a billet in a shower of sparks, aurora rays that ripple, crystal
-- shards that turn, an accretion disk in orbit and debris spiralling into the
-- horizon. MillForms replays the models without the scripts; this plays the
-- same motion, ported line for line, from Ambience's one Heartbeat. Client
-- only: none of it is ever replicated.
--
-- THREE DIFFERENCES, ALL THE GAME'S RULES RATHER THAN NEW LOOKS:
--
--   * The arrows run at the belt's REAL speed -- Ambience's clock for that
--     belt, off the BeltSpeed TreadmillService writes -- where the scripts ran
--     them at a fixed VisualBeltSpeed of 8. So they crawl at rest and race
--     while the owner trains, like every other mill's.
--   * Only while the mill can be seen: on screen and within MAX_DISTANCE. A
--     mill off screen holds its last pose and picks up where its clock is.
--   * Rest frames are taken off the Deck when a client first sees the model,
--     which is why MillModel streams these ATOMIC: never half a mill.
--==============================================================================

local MillFormMotion = {}

local S, C = math.sin, math.cos
local MAX_DISTANCE = 320
-- A mill's reach from its deck centre, for the on-screen test (the largest
-- spans about 32 studs end to end).
local RADIUS = 22

type Step = (t: number, dt: number, dist: number) -> ()

local function sw(t: number, w: number, ph: number): number
	return S(w * t + ph) - S(ph)
end

type Chevron = { part: BasePart, x: number, y: number, z0: number, rot: number }

local function chevronOf(deck0: CFrame, p: BasePart, side: string): Chevron
	local rel = deck0:ToObjectSpace(p.CFrame)
	return { part = p, x = rel.Position.X, y = rel.Position.Y, z0 = rel.Position.Z,
		rot = (if side == "L" then -1 else 1) * math.rad(28) }
end

-- The belt: arrows flow toward the back (+Z) like the game's, coloured from
-- `front` to `back` along the run and faded at the wrap.
local function runChevrons(chevs: { Chevron }, deckCF: CFrame, dist: number, front: Color3, back: Color3)
	for _, c in ipairs(chevs) do
		local z = ((c.z0 + 8 + dist) % 16) - 8
		c.part.CFrame = deckCF * CFrame.new(c.x, c.y, z) * CFrame.Angles(0, c.rot, 0)
		c.part.Color = front:Lerp(back, ((z + 8) / 16) ^ 0.8)
		c.part.Transparency = 1 - math.clamp((7.4 - math.abs(z)) / 1.0, 0, 1)
	end
end

local function part(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

--==============================================================================
-- 11. ABYSSAL TRENCH (AbyssBrain)
--==============================================================================
local function abyss(model: Model): Step?
	local deck = part(model, "Deck")
	local lastStalk = part(model, "Stalk14")
	local bulb = part(model, "LureBulb")
	if not (deck and lastStalk and bulb) then
		return nil
	end
	local halo = part(model, "LureHalo")
	local glow = bulb:FindFirstChild("LureGlow") :: PointLight?
	local MINT = Color3.fromRGB(205, 255, 230)
	local GLOWG = Color3.fromRGB(110, 255, 170)
	local TEALD = Color3.fromRGB(22, 110, 112)
	local DIMG = Color3.fromRGB(36, 120, 100)
	local deck0 = deck.CFrame
	local tip0 = lastStalk.CFrame * CFrame.new(0, lastStalk.Size.Y / 2, 0)
	local kelp: { [number]: { [number]: { part: BasePart, len: number, R: CFrame } } } = {}
	local tips: { [number]: BasePart } = {}
	local jelly: { [number]: any } = {}
	local chevs: { Chevron } = {}
	local photos: { { part: BasePart, k: number } } = {}
	local lure: { part: BasePart, rel: CFrame }? = nil
	local tends: { [number]: { part: BasePart, top: CFrame, len: number } } = {}
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			local p = child
			local n = p.Name
			local kn, kj = string.match(n, "^Kelp(%d+)_(%d)$")
			local kt = string.match(n, "^KelpTip(%d+)$")
			local jb = string.match(n, "^JellyB(%d+)$")
			local jc = string.match(n, "^JellyC(%d+)$")
			local jn, jk = string.match(n, "^JellyT(%d+)_(%d)$")
			local side = string.match(n, "^Chev([LR])%d+$")
			local ph = string.match(n, "^Photo(%d+)$")
			local lt = string.match(n, "^LureTend(%d)$")
			if kn and kj then
				local k = tonumber(kn) :: number
				kelp[k] = kelp[k] or {}
				kelp[k][tonumber(kj) :: number] = { part = p, len = p.Size.Y, R = deck0:ToObjectSpace(p.CFrame) }
			elseif kt then
				tips[tonumber(kt) :: number] = p
			elseif jb then
				local j = tonumber(jb) :: number
				jelly[j] = jelly[j] or { tents = {} }
				jelly[j].bell = { part = p, rel = deck0:ToObjectSpace(p.CFrame), size = p.Size }
			elseif jc then
				local j = tonumber(jc) :: number
				jelly[j] = jelly[j] or { tents = {} }
				jelly[j].core = { part = p, rel = deck0:ToObjectSpace(p.CFrame), size = p.Size }
			elseif jn and jk then
				local j = tonumber(jn) :: number
				jelly[j] = jelly[j] or { tents = {} }
				local rel = deck0:ToObjectSpace(p.CFrame)
				jelly[j].tents[tonumber(jk) :: number] = { part = p, top = rel * CFrame.new(0, p.Size.Y / 2, 0), len = p.Size.Y }
			elseif side then
				table.insert(chevs, chevronOf(deck0, p, side))
			elseif ph then
				table.insert(photos, { part = p, k = tonumber(ph) :: number })
			elseif n == "LureLine" then
				lure = { part = p, rel = tip0:ToObjectSpace(p.CFrame) }
			elseif lt then
				local rel = tip0:ToObjectSpace(p.CFrame)
				tends[tonumber(lt) :: number] = { part = p, top = rel * CFrame.new(0, p.Size.Y / 2, 0), len = p.Size.Y }
			end
		end
	end
	local bulbRel = tip0:ToObjectSpace(bulb.CFrame)
	local haloRel = if halo then tip0:ToObjectSpace(halo.CFrame) else nil
	-- Kelp: each strand is a chain of three joints; the rest offset of every
	-- segment from the joint below it.
	local chains: { [number]: { base: CFrame, segs: { { part: BasePart, len: number, T: CFrame } }, tip: BasePart? } } = {}
	for k, segs in pairs(kelp) do
		if segs[1] and segs[2] and segs[3] then
			local base = segs[1].R * CFrame.new(0, -segs[1].len / 2, 0)
			local prev = base
			local list = {}
			for j = 1, 3 do
				local s = segs[j]
				list[j] = { part = s.part, len = s.len, T = prev:Inverse() * s.R }
				prev = s.R * CFrame.new(0, s.len / 2, 0)
			end
			chains[k] = { base = base, segs = list, tip = tips[k] }
		end
	end
	local DRIFT = { { 0.5, 0.8, 1.1 }, { 0.5, 0.9, 1.1 }, { 0.5, 0.7, 1 }, { 0.5, 0.7, 1 }, { 0.9, 0.7, 1.2 } }
	return function(t, _dt, dist)
		local deckCF = deck.CFrame
		local tipCF = lastStalk.CFrame * CFrame.new(0, lastStalk.Size.Y / 2, 0)
		-- The lure swings under the end of the stalk; the tendrils trail.
		local anchor = tipCF * CFrame.Angles(0.05 * sw(t, 1.1, 0.4), 0, 0.07 * sw(t, 0.8, 1.3))
		if lure then
			lure.part.CFrame = anchor * lure.rel
		end
		bulb.CFrame = anchor * bulbRel
		if halo and haloRel then
			halo.CFrame = anchor * haloRel
			halo.Transparency = 0.82 + 0.05 * S(t * 1.6)
		end
		bulb.Color = MINT:Lerp(GLOWG, 0.5 + 0.5 * S(t * 1.3))
		for k, d in pairs(tends) do
			d.part.CFrame = anchor * d.top * CFrame.Angles(0.22 * sw(t, 1.7, k), 0, 0.22 * sw(t, 1.3, k + 1))
				* CFrame.new(0, -d.len / 2, 0)
		end
		if glow then
			glow.Brightness = 3 + 0.8 * S(t * 1.3) + 0.4 * S(t * 3.7)
		end
		-- Kelp sways: each joint leans a little more than the one below it.
		for k, c in pairs(chains) do
			local parent = deckCF * c.base
			for j, s in ipairs(c.segs) do
				local a = (0.02 + 0.015 * j) * sw(t, 0.9, k * 1.7 + j * 0.7)
				local b = (0.015 + 0.015 * j) * sw(t, 0.7, k * 0.9 + j * 0.5)
				local cf = parent * CFrame.Angles(a, 0, b) * s.T
				s.part.CFrame = cf
				parent = cf * CFrame.new(0, s.len / 2, 0)
				if j == 3 and c.tip then
					c.tip.CFrame = parent * CFrame.new(0, 0.12, 0)
				end
			end
			if c.tip then
				c.tip.Color = GLOWG:Lerp(MINT, 0.5 + 0.5 * S(t * 1.8 + k))
			end
		end
		-- Jellyfish: the bell pulses, the whole animal drifts, the tentacles trail.
		for n, j in pairs(jelly) do
			local d = DRIFT[n]
			if d and j.bell and j.core then
				local off = CFrame.new(d[1] * sw(t, 0.31, n), d[2] * sw(t, 0.47, n * 1.3), d[3] * sw(t, 0.27, n * 0.7))
				local pu = sw(t, 2.1, n * 1.1)
				local bs, cs = j.bell.size, j.core.size
				j.bell.part.Size = Vector3.new(bs.X * (1 - 0.10 * pu), bs.Y * (1 + 0.30 * pu), bs.Z * (1 - 0.10 * pu))
				j.bell.part.CFrame = deckCF * off * j.bell.rel
				j.core.part.Size = Vector3.new(cs.X * (1 - 0.10 * pu), cs.Y * (1 + 0.30 * pu), cs.Z * (1 - 0.10 * pu))
				j.core.part.CFrame = deckCF * off * j.core.rel
				for k, tn in pairs(j.tents) do
					tn.part.CFrame = deckCF * off * tn.top
						* CFrame.Angles(0.16 * sw(t, 1.9, n + k), 0, 0.16 * sw(t, 1.5, n + k * 0.7)) * CFrame.new(0, -tn.len / 2, 0)
				end
			end
		end
		-- Mint near the lure, teal at the step.
		runChevrons(chevs, deckCF, dist, MINT, TEALD)
		-- A pulse of light runs up the stalk to the lure.
		for _, p in ipairs(photos) do
			p.part.Color = DIMG:Lerp(MINT, 0.5 + 0.5 * S(t * 2.2 - p.k * 0.9))
		end
	end
end

--==============================================================================
-- 12. VOLCANIC FORGE (ForgeBrain)
--==============================================================================
local function forge(model: Model): Step?
	local deck = part(model, "Deck")
	local arm = part(model, "HammerArm")
	local mouth = part(model, "FurnaceMouth")
	if not (deck and arm and mouth) then
		return nil
	end
	local EMBER = Color3.fromRGB(255, 110, 30)
	local LAVAY = Color3.fromRGB(255, 196, 70)
	local HOT = Color3.fromRGB(255, 240, 190)
	local MOUTHA, MOUTHB = Color3.fromRGB(255, 90, 25), Color3.fromRGB(255, 214, 120)
	local GOLD, EMBA = Color3.fromRGB(255, 214, 90), Color3.fromRGB(255, 96, 30)
	local deck0 = deck.CFrame
	local pivotCF = CFrame.new(-5.2, 7.2, -12.2)
	local pivotInv = pivotCF:Inverse()
	local THI, TLO = math.rad(34), math.rad(-16.5)
	local CYCLE, IMPACT = 3.4, 0.44
	local hammer: { { part: BasePart, rel: CFrame } } = {}
	local lava: { { part: BasePart, k: number } } = {}
	local cracks: { { part: BasePart, n: number } } = {}
	local craters: { { part: BasePart, n: number } } = {}
	local chevs: { Chevron } = {}
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			local p = child
			local n = p.Name
			local lr, lk = string.match(n, "^Lava(%d)_(%d+)$")
			local cn = string.match(n, "^Crack(%d+)$")
			local rn = string.match(n, "^Crater(%d+)$")
			local side = string.match(n, "^Chev([LR])%d+$")
			if n == "HammerArm" or n == "HammerHead" or n == "HammerWeight" then
				table.insert(hammer, { part = p, rel = pivotInv * deck0:ToObjectSpace(p.CFrame) })
			elseif lr and lk then
				table.insert(lava, { part = p, k = (tonumber(lk) :: number) + 4 * ((tonumber(lr) :: number) - 1) })
			elseif cn then
				table.insert(cracks, { part = p, n = tonumber(cn) :: number })
			elseif rn then
				table.insert(craters, { part = p, n = tonumber(rn) :: number })
			elseif side then
				table.insert(chevs, chevronOf(deck0, p, side))
			end
		end
	end
	local billet = part(model, "Billet")
	local sparkPart = part(model, "SparkPoint")
	local sparks = if sparkPart then sparkPart:FindFirstChild("Sparks") :: ParticleEmitter? else nil
	local glow = mouth:FindFirstChild("ForgeGlow") :: PointLight?
	-- 0 = hammer raised, 1 = hammer on the billet: hold, drop fast, rebound,
	-- lift slowly, hold.
	local function prof(p: number): number
		if p < 0.30 then
			return 0
		elseif p < IMPACT then
			local u = (p - 0.30) / (IMPACT - 0.30)
			return u * u
		elseif p < 0.95 then
			local u = (p - IMPACT) / (0.95 - IMPACT)
			return 0.5 + 0.5 * math.cos(math.pi * u)
		end
		return 0
	end
	local nextImpact = IMPACT * CYCLE
	local flash = 0
	return function(t, dt, dist)
		local deckCF = deck.CFrame
		-- The trip-hammer: arm, head and counterweight turn together about the pivot.
		local spin = CFrame.Angles(0, 0, (TLO - THI) * prof((t % CYCLE) / CYCLE))
		for _, h in ipairs(hammer) do
			h.part.CFrame = deckCF * pivotCF * spin * h.rel
		end
		-- Blows missed while off screen are skipped, not fired in a burst.
		if t >= nextImpact then
			nextImpact = (math.floor((t - IMPACT * CYCLE) / CYCLE) + 1) * CYCLE + IMPACT * CYCLE
			flash = 1
			if sparks then
				sparks:Emit(36)
			end
		end
		flash = math.max(0, flash - dt * 2.6)
		-- The billet and the furnace mouth glow; the light flickers and kicks on every blow.
		if billet then
			billet.Color = EMBER:Lerp(HOT, 0.5 + 0.5 * S(1.2 * t)):Lerp(Color3.fromRGB(255, 255, 255), flash * 0.9)
		end
		mouth.Color = MOUTHA:Lerp(MOUTHB, math.min(1, 0.5 + 0.5 * S(1.7 * t) + 0.3 * flash))
		if glow then
			glow.Brightness = 3 + 0.8 * S(1.9 * t) + 0.5 * S(5.3 * t) + 3 * flash
		end
		-- Lava runs down the rivers; the cracks and craters breathe.
		for _, l in ipairs(lava) do
			l.part.Color = EMBER:Lerp(LAVAY, 0.5 + 0.5 * S(1.5 * t - 0.9 * l.k))
		end
		for _, c in ipairs(cracks) do
			c.part.Color = EMBER:Lerp(LAVAY, 0.5 + 0.5 * S(1.5 * t - 0.9 * (2 * c.n)))
		end
		for _, c in ipairs(craters) do
			c.part.Color = EMBER:Lerp(HOT, 0.5 + 0.5 * S(2.2 * t + c.n))
		end
		-- Gold near the forge, ember at the step.
		runChevrons(chevs, deckCF, dist, GOLD, EMBA)
	end
end

--==============================================================================
-- 13. FROZEN AURORA (GlacierBrain)
--==============================================================================
local function glacier(model: Model): Step?
	local deck = part(model, "Deck")
	if not deck then
		return nil
	end
	local AUR = {
		{ Color3.fromRGB(110, 255, 170), Color3.fromRGB(60, 225, 205), 0.06 },
		{ Color3.fromRGB(70, 240, 225), Color3.fromRGB(130, 190, 255), 0.2 },
		{ Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 120, 210), 0.42 },
	}
	local AMP = { 0.35, 0.6, 0.9 }
	local DRIFT = {
		{ 0.35, 0.5, 0.35, 0.5, -8.6, 7.6, 5 },
		{ 0.35, 0.5, 0.35, -0.42, 9.2, 8.6, 3.2 },
		{ 0.3, 0.5, 0.35, 0.58, -9.2, 5.6, -3.4 },
		{ 0.3, 0.45, 0.35, -0.5, 9, 5.2, -5.5 },
		{ 0.4, 0.55, 0.4, 0.36, -6.4, 11.2, -2 },
		{ 0.4, 0.55, 0.4, -0.46, 5.6, 13, -1.4 },
	}
	local TIPA, TIPB = Color3.fromRGB(110, 240, 255), Color3.fromRGB(255, 255, 255)
	local CORA, CORB = Color3.fromRGB(110, 255, 170), Color3.fromRGB(190, 130, 255)
	local LGA, LGB = Color3.fromRGB(150, 255, 210), Color3.fromRGB(200, 160, 255)
	local WHITE = Color3.fromRGB(236, 250, 255)
	local VIOL = Color3.fromRGB(176, 124, 255)
	local deck0 = deck.CFrame
	local aur: { { part: BasePart, i: number, lv: number, rel: CFrame } } = {}
	local shards: { { part: BasePart, n: number, core: boolean, pos: Vector3, rot: CFrame } } = {}
	local tips: { { part: BasePart, n: number } } = {}
	local crev: { { part: BasePart, n: number } } = {}
	local chevs: { Chevron } = {}
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			local p = child
			local n = p.Name
			local ai, al = string.match(n, "^Aur(%d+)_(%d)$")
			local sn = string.match(n, "^Shard(%d+)$")
			local cn = string.match(n, "^ShardCore(%d+)$")
			local cpn = string.match(n, "^ShardCap(%d+)%a$")
			local tn = string.match(n, "^CrystalTip(%d+)$")
			local vn = string.match(n, "^Crev(%d+)$")
			local side = string.match(n, "^Chev([LR])%d+$")
			if ai and al then
				table.insert(aur, { part = p, i = tonumber(ai) :: number, lv = tonumber(al) :: number,
					rel = deck0:ToObjectSpace(p.CFrame) })
			elseif sn or cn or cpn then
				local rel = deck0:ToObjectSpace(p.CFrame)
				table.insert(shards, { part = p, n = tonumber(sn or cn or cpn) :: number, core = cn ~= nil,
					pos = rel.Position, rot = CFrame.new(-rel.Position) * rel })
			elseif tn then
				table.insert(tips, { part = p, n = tonumber(tn) :: number })
			elseif vn then
				table.insert(crev, { part = p, n = tonumber(vn) :: number })
			elseif side then
				table.insert(chevs, chevronOf(deck0, p, side))
			end
		end
	end
	local lightPart = part(model, "Aur11_2")
	local glow = if lightPart then lightPart:FindFirstChild("AuroraGlow") :: PointLight? else nil
	return function(t, _dt, dist)
		local deckCF = deck.CFrame
		-- The aurora: every ray ripples in z (more toward the top), and its
		-- colour and glow ride travelling waves.
		for _, a in ipairs(aur) do
			local lv = AUR[a.lv]
			if lv then
				a.part.CFrame = deckCF * CFrame.new(0, 0, AMP[a.lv] * sw(t, 0.55, 0.42 * a.i)) * a.rel
				a.part.Color = (lv[1] :: Color3):Lerp(lv[2] :: Color3, 0.5 + 0.5 * S(0.9 * t - 0.55 * a.i + 0.8 * a.lv))
				a.part.Transparency = (lv[3] :: number) + 0.14 * (1 - (0.5 + 0.5 * S(1.3 * t - 0.4 * a.i + a.lv)))
			end
		end
		if glow then
			glow.Brightness = 2.4 + 0.7 * S(t * 0.9) + 0.3 * S(t * 2.3)
			glow.Color = LGA:Lerp(LGB, 0.5 + 0.5 * S(t * 0.4))
		end
		-- Floating shards bob, drift and turn about their own centres, so caps
		-- and core stay assembled; the cores cycle through the aurora colours.
		for _, s in ipairs(shards) do
			local d = DRIFT[s.n]
			if d then
				local ctr = Vector3.new(d[5], d[6], d[7])
				local off = Vector3.new(d[1] * sw(t, 0.33, s.n), d[2] * sw(t, 0.62, s.n * 1.3), d[3] * sw(t, 0.28, s.n * 0.7))
				s.part.CFrame = deckCF * CFrame.new(ctr + off) * CFrame.Angles(0, d[4] * t, 0) * CFrame.new(s.pos - ctr) * s.rot
				if s.core then
					s.part.Color = CORA:Lerp(CORB, 0.5 + 0.5 * S(0.8 * t + s.n * 1.1))
				end
			end
		end
		-- Crystal tips glint; crevasses glow with the aurora.
		for _, c in ipairs(tips) do
			c.part.Color = TIPA:Lerp(TIPB, 0.5 + 0.5 * S(1.7 * t + c.n))
		end
		local first = AUR[1]
		for _, c in ipairs(crev) do
			c.part.Color = (first[1] :: Color3):Lerp(first[2] :: Color3, 0.5 + 0.5 * S(0.9 * t - 0.55 * (2 * c.n) + 0.8))
		end
		-- White near the aurora, violet at the step.
		runChevrons(chevs, deckCF, dist, WHITE, VIOL)
	end
end

--==============================================================================
-- 14. EVENT HORIZON (SingularityBrain)
--==============================================================================
local function singularity(model: Model): Step?
	local deck = part(model, "Deck")
	local hole = part(model, "EventHorizon")
	if not (deck and hole) then
		return nil
	end
	local halo = part(model, "HorizonHalo")
	local glow = hole:FindFirstChild("SingularityGlow") :: PointLight?
	local WHITE = Color3.fromRGB(255, 246, 228)
	local HOT = Color3.fromRGB(255, 236, 205)
	local CRIM = Color3.fromRGB(176, 24, 44)
	local CRIMN = Color3.fromRGB(236, 38, 60)
	local PINKW = Color3.fromRGB(255, 214, 196)
	local BLACK = Color3.new(0, 0, 0)
	local OMEGA = { 1.4, 0.97244, 0.738854, 0.598321 }
	local PHI0 = 1.099557
	local CYCLE, R_START, R_END, K = 15, 9.2, 3.45, 57.509759
	local DEBRIS = {
		{ phi0 = -0.02381, off = 0.447818, len = 1.354526, th = 0.325191, h = 0.005018 },
		{ phi0 = 0.567291, off = 1.397728, len = 1.107145, th = 0.348184, h = 0.187505 },
		{ phi0 = 0.844259, off = 2.742721, len = 0.854402, th = 0.37335, h = 0.123801 },
		{ phi0 = 1.341736, off = 4.535755, len = 1.378855, th = 0.351549, h = 0.07396 },
		{ phi0 = 1.923142, off = 5.012001, len = 1.117029, th = 0.268337, h = -0.198267 },
		{ phi0 = 2.488965, off = 6.274066, len = 1.078361, th = 0.321674, h = 0.219153 },
		{ phi0 = 3.151155, off = 8.012233, len = 1.099864, th = 0.352743, h = -0.027309 },
		{ phi0 = 3.554273, off = 9.548125, len = 1.397415, th = 0.37763, h = 0.132998 },
		{ phi0 = 4.096429, off = 10.183733, len = 0.973424, th = 0.269831, h = 0.170424 },
		{ phi0 = 4.662589, off = 11.927267, len = 1.031908, th = 0.394126, h = 0.222278 },
		{ phi0 = 4.98626, off = 12.667774, len = 1.346163, th = 0.325798, h = 0.30743 },
		{ phi0 = 5.708299, off = 13.808431, len = 1.177673, th = 0.368992, h = -0.147344 },
	}
	local pivot0 = hole.CFrame
	local deck0 = deck.CFrame
	local disk: { { part: BasePart, ring: number, rel: CFrame, phi: number } } = {}
	local debris: { { part: BasePart, d: typeof(DEBRIS[1]) } } = {}
	local chevs: { Chevron } = {}
	local photons: { BasePart } = {}
	local caps: { { part: BasePart, k: number } } = {}
	local jets: { { part: BasePart, k: number } } = {}
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			local p = child
			local n = p.Name
			local ring = string.match(n, "^Disk(%d)_%d+$")
			local deb = string.match(n, "^Debris(%d+)$")
			local side = string.match(n, "^Chev([LR])%d+$")
			local ph = string.match(n, "^Photon%d+$")
			local cs, ck = string.match(n, "^Cap([LR])(%d+)$")
			local jt = string.match(n, "^Jet(%d+)$")
			if ring then
				local rel = pivot0:ToObjectSpace(p.CFrame)
				table.insert(disk, { part = p, ring = tonumber(ring) :: number, rel = rel,
					phi = math.atan2(rel.Position.Z, rel.Position.X) })
			elseif deb then
				local d = DEBRIS[tonumber(deb) :: number]
				if d then
					table.insert(debris, { part = p, d = d })
				end
			elseif side then
				table.insert(chevs, chevronOf(deck0, p, side))
			elseif ph then
				table.insert(photons, p)
			elseif cs and ck then
				table.insert(caps, { part = p, k = tonumber(ck) :: number })
			elseif jt then
				table.insert(jets, { part = p, k = tonumber(jt) :: number })
			end
		end
	end
	local RING_COLOR = {
		Color3.fromRGB(255, 248, 232), Color3.fromRGB(255, 206, 150), Color3.fromRGB(245, 92, 52), Color3.fromRGB(176, 22, 44),
	}
	local RING_DARK = {}
	for i, c in ipairs(RING_COLOR) do
		RING_DARK[i] = c:Lerp(BLACK, 0.82)
	end
	return function(t, _dt, dist)
		local pivot = hole.CFrame
		local deckCF = deck.CFrame
		-- The accretion disk: each ring orbits at its own speed; one side is
		-- always the bright one.
		for _, d in ipairs(disk) do
			local omega = OMEGA[d.ring]
			if omega then
				local th = omega * t
				d.part.CFrame = pivot * CFrame.Angles(0, th, 0) * d.rel
				local b = 0.38 + 0.62 * (0.5 + 0.5 * C(d.phi - th - PHI0))
				d.part.Color = RING_DARK[d.ring]:Lerp(RING_COLOR[d.ring], b)
			end
		end
		-- Debris spirals in, stretching and heating up, and is gone at the horizon.
		for _, e in ipairs(debris) do
			local d = e.d
			local u = ((t + d.off) % CYCLE) / CYCLE
			local r = R_START - u * (R_START - R_END)
			local a = d.phi0 - K * (r ^ -0.5 - R_START ^ -0.5)
			local scale = math.clamp(math.min((r - R_END) / 1.0, u / 0.06), 0, 1)
			local h = d.h * math.clamp((r - R_END) / 6, 0, 1)
			local len = math.max(0.05, d.len * (1 + 2.4 * u ^ 1.5) * scale)
			local thick = math.max(0.05, d.th * (1 - 0.5 * u) * scale)
			e.part.Size = Vector3.new(len, thick, thick)
			e.part.CFrame = pivot * CFrame.new(r * C(a), h, r * S(a)) * CFrame.Angles(0, math.pi / 2 - a, 0)
			e.part.Color = CRIM:Lerp(HOT, u ^ 0.8)
		end
		-- White-hot near the hole, crimson at the step.
		runChevrons(chevs, deckCF, dist, WHITE, CRIM)
		-- The photon ring shimmers; a pulse of light runs up the side posts.
		for i, p in ipairs(photons) do
			p.Color = WHITE:Lerp(PINKW, 0.5 + 0.5 * S(t * 2.4 + i * 0.5))
		end
		for _, c in ipairs(caps) do
			c.part.Color = CRIMN:Lerp(HOT, 0.5 + 0.5 * S(t * 2.2 - c.k * 0.9))
		end
		for _, j in ipairs(jets) do
			j.part.Transparency = 0.32 + 0.16 * S(t * 3.1 + j.k)
		end
		if halo then
			halo.Transparency = 0.84 + 0.05 * S(t * 1.7)
		end
		if glow then
			glow.Brightness = 2.2 + 0.5 * S(t * 2.0) + 0.2 * S(t * 5.3)
		end
	end
end

local SETUP: { [string]: (Model) -> Step? } = {
	abyssaltrench = abyss,
	volcanicforge = forge,
	frozenaurora = glacier,
	eventhorizon = singularity,
}

--==============================================================================
-- TRACKING
--
-- One entry per model this client has seen, keyed by the model. Ambience calls
-- track when it meets a belt whose mill carries a MillForm, and step every
-- frame with its own belt clocks.
--==============================================================================
type Entry = { model: Model, belt: BasePart, deck: BasePart, step: Step, t: number }
local entries: { [Model]: Entry } = {}

function MillFormMotion.track(model: Model, belt: BasePart): boolean
	if entries[model] then
		return true
	end
	local formId = model:GetAttribute("MillForm")
	local setup = if type(formId) == "string" then SETUP[formId] else nil
	local deck = model.PrimaryPart
	if not (setup and deck) then
		return false
	end
	local step = setup(model)
	if not step then
		return false
	end
	entries[model] = { model = model, belt = belt, deck = deck, step = step, t = 0 }
	return true
end

function MillFormMotion.tracked(model: Model): boolean
	return entries[model] ~= nil
end

local function visible(camera: Camera, at: Vector3): boolean
	local cf = camera.CFrame
	local to = at - cf.Position
	local d = to.Magnitude
	if d < RADIUS then
		return true
	end
	if d > MAX_DISTANCE then
		return false
	end
	local vp = camera.ViewportSize
	local halfV = math.rad(camera.FieldOfView) * 0.5
	local halfH = math.atan(math.tan(halfV) * vp.X / math.max(vp.Y, 1))
	local cone = math.max(halfV, halfH) + math.asin(math.min(RADIUS / d, 1))
	return (to / d):Dot(cf.LookVector) >= math.cos(cone)
end

-- Every tracked mill's clock advances every frame, seen or not, so one that
-- comes back on screen is where it would have been; only the seen ones are
-- posed. `clockOf` is how far that belt's surface has travelled, in studs.
function MillFormMotion.step(dt: number, camera: Camera?, clockOf: (BasePart) -> number)
	for model, e in pairs(entries) do
		if not (model.Parent and e.deck.Parent and e.belt.Parent) then
			entries[model] = nil
		else
			e.t += dt
			if camera == nil or visible(camera, e.deck.Position) then
				e.step(e.t, dt, clockOf(e.belt))
			end
		end
	end
end

return MillFormMotion
