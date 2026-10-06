--!strict
-- Steal a Seed :: DancerPlacement
--
-- Where the disco's dancers stand (2026-10-03): a pure function of the global
-- event's id and GameConfig.MiniEvent.Dancers -- which dancer, where, facing
-- which way and at what size. Nothing streamed, nothing random per client, so
-- every player of a server sees the same troupe. DiscoDancers (client) calls
-- it; MiniEventSpec checks it against the config and the real map.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local DancerForms = require(Shared:WaitForChild("DancerForms"))

local CFG = GameConfig.MiniEvent.Dancers

local DancerPlacement = {}

export type Pick = {
	id: string,
	-- On the ground plane (Y = 0); the client finds the ground's height.
	at: Vector3,
	-- The footprint's radius at this scale.
	radius: number,
	scale: number,
	-- Radians off facing the hub's centre.
	yaw: number,
	zone: any,
}

-- A stable number from the event's id (the same on every client).
function DancerPlacement.Seed(eventId: string): number
	local h = 7
	for i = 1, #eventId do
		h = (h * 31 + string.byte(eventId, i)) % 2147483647
	end
	return h
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function inSectors(zone: any, angle: number): boolean
	if not zone.Sectors then
		return true
	end
	for _, s in ipairs(zone.Sectors) do
		if (angle - s.From) % 360 <= (s.To - s.From) then
			return true
		end
	end
	return false
end

local function segmentDistance(p: Vector3, a: Vector3, b: Vector3): number
	local ab = flat(b) - flat(a)
	local t = math.clamp((flat(p) - flat(a)):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (flat(p) - (flat(a) + ab * t)).Magnitude
end

-- Whether a footprint of radius `r` at `p`, in `zone`, keeps clear of every
-- KeepClear circle (and ring) and every Corridor.
function DancerPlacement.Clear(p: Vector3, r: number, zone: any): boolean
	local dist = flat(p).Magnitude
	if dist - r < zone.MinRadius - 1e-6 or dist + r > zone.MaxRadius + 1e-6 then
		return false
	end
	for _, k in ipairs(CFG.KeepClear) do
		local d = (flat(p) - flat(k.At)).Magnitude
		if k.Ring then
			if not (d + r < k.Ring[1] or d - r > k.Ring[2]) then
				return false
			end
		elseif d < k.Radius + r then
			return false
		end
	end
	for _, c in ipairs(CFG.Corridors) do
		if segmentDistance(p, c.From, c.To) < c.HalfWidth + r then
			return false
		end
	end
	return true
end

-- The troupe for an event: up to Count picks, in a fixed order (a phone draws
-- the first PhoneCount).
function DancerPlacement.Picks(eventId: string): { Pick }
	local rng = Random.new(DancerPlacement.Seed(eventId))
	local zones = CFG.Zones
	local total = 0
	for _, z in ipairs(zones) do
		total += z.Weight
	end
	local ids = DancerForms.Ids
	local out: { Pick } = {}
	for _ = 1, CFG.Attempts do
		if #out >= CFG.Count then
			break
		end
		-- Every attempt draws the same six numbers, so the sequence never
		-- depends on which earlier attempts were refused.
		local zr, ar, rr, ir, sr, yr = rng:NextNumber(), rng:NextNumber(), rng:NextNumber(), rng:NextNumber(),
			rng:NextNumber(), rng:NextNumber()
		local zone = zones[#zones]
		local acc = 0
		for _, z in ipairs(zones) do
			acc += z.Weight / total
			if zr <= acc then
				zone = z
				break
			end
		end
		local angle = ar * 360
		if not inSectors(zone, angle) then
			continue
		end
		-- Even over the area, not over the radius.
		local radius = math.sqrt(zone.MinRadius ^ 2 + (zone.MaxRadius ^ 2 - zone.MinRadius ^ 2) * rr)
		local at = Vector3.new(math.cos(math.rad(angle)) * radius, 0, math.sin(math.rad(angle)) * radius)
		local id = ids[math.clamp(math.floor(ir * #ids) + 1, 1, #ids)]
		local scale = CFG.ScaleMin + (CFG.ScaleMax - CFG.ScaleMin) * sr
		local r = DancerForms.Radius(id) * scale
		if not DancerPlacement.Clear(at, r, zone) then
			continue
		end
		local apart = true
		for _, other in ipairs(out) do
			if (flat(other.at) - flat(at)).Magnitude < other.radius + r + CFG.Gap then
				apart = false
				break
			end
		end
		if apart then
			table.insert(out, {
				id = id,
				at = at,
				radius = r,
				scale = scale,
				yaw = math.rad((yr * 2 - 1) * CFG.FacingJitterDegrees),
				zone = zone,
			})
		end
	end
	return out
end

return DancerPlacement
