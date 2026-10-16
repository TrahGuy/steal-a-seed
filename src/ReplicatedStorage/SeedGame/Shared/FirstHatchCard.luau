--!strict
--==============================================================================
-- Steal a Seed :: FirstHatchCard (2026-10-16, the owner's fix for the onboarding
-- funnel's step 4; GameConfig.FirstHatch says what and why)
--
-- The first hatch's card as arithmetic -- pure, so FirstHatchSpec steps it on
-- stand-in numbers:
--
--   pick     the pod it is for: the soonest due in the Bag (the guide's choice)
--   view     what it says at a moment: growing, with its countdown, or ready
--   shown    whether it stands: a first hatch pending, a pod, nothing over it,
--            its HATCH not already pressed
--   rect     where: the lowest place over the hotbar clear of the whole HUD
--            (HudLayout.occupied, and the guide's block while it shows),
--            centred, as large as fits down to MinScale and never taller than
--            MaxHeightShare of the screen (a phone's smaller card)
--   Blocks   its pieces, in its own units
--   landing  where its HATCH puts the body: the plot's spawn facing the bed
--            the plant will come up in -- into the garden when there is none
--            (PlantService.FirstHatch lands there and tells this client, whose
--            ObbyCamera turns the camera to it)
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local FirstHatchCard = {}

local WORDS = GameConfig.FirstHatch.Words

export type Rect = { x: number, y: number, w: number, h: number }
-- A pod in the Bag: its Tool's item id, species, tier and HatchAt (a server time).
export type Pod = { item: string, speciesId: string, tier: number, hatchAt: number }
export type View = { title: string, pod: string, line: string?, ready: boolean, left: number }

local function rect(x: number, y: number, w: number, h: number): Rect
	return { x = x, y = y, w = w, h = h }
end

-- The card at scale 1, its pieces in the same units, and its words' largest
-- sizes (UIKit.comic's ink is by these).
FirstHatchCard.Base = Vector2.new(320, 160)
FirstHatchCard.Gap = 8
FirstHatchCard.MaxScale = 1
FirstHatchCard.MinScale = 0.55
-- Never taller than this share of the screen: on a 302-px phone about 115 px.
FirstHatchCard.MaxHeightShare = 0.38
FirstHatchCard.Step = 0.05
FirstHatchCard.Blocks = {
	title = rect(14, 8, 292, 30),
	view = rect(14, 42, 70, 66),
	pod = rect(94, 46, 212, 28),
	line = rect(94, 76, 212, 24),
	button = rect(16, 112, 288, 42),
}
FirstHatchCard.TextSizes = { title = 24, pod = 20, line = 16, button = 22 }

-- "0:07", "1:00": minutes and seconds, rounded UP (never 0:00 while time is left).
function FirstHatchCard.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds - 1e-6))
	return string.format("%d:%02d", s // 60, s % 60)
end

-- The pod the card is for: the soonest due, ties by item id; nil with none.
function FirstHatchCard.pick(pods: { Pod }): Pod?
	local best: Pod? = nil
	for _, p in ipairs(pods) do
		if type(p.item) == "string" and p.item ~= "" and type(p.hatchAt) == "number" then
			local b = best
			if b == nil or p.hatchAt < b.hatchAt or (p.hatchAt == b.hatchAt and p.item < b.item) then
				best = p
			end
		end
	end
	return best
end

-- What it says at `now` for `pod`, whose size word and species name are given.
function FirstHatchCard.view(pod: Pod, now: number, sizeWord: string, name: string): View
	local left = math.max(0, pod.hatchAt - now)
	local ready = left <= 0
	return {
		title = if ready then WORDS.Ready else WORDS.Growing,
		pod = string.format(WORDS.Pod, string.upper(sizeWord), name),
		line = if ready then nil else string.format(WORDS.ReadyIn, FirstHatchCard.clock(left)),
		ready = ready,
		left = left,
	}
end

-- Whether it stands.
function FirstHatchCard.shown(pending: boolean, pod: Pod?, busy: boolean, asked: boolean): boolean
	return pending and pod ~= nil and not busy and not asked
end

-- Where it stands on a `safe`-sized screen, clear of `avoid` by Gap, and its
-- scale; an empty rect when nothing fits.
function FirstHatchCard.rect(safe: Vector2, avoid: { Rect }): (Rect, number)
	local G = FirstHatchCard.Gap
	local base = FirstHatchCard.Base
	local function clear(r: Rect): boolean
		if r.x < G or r.y < G or r.x + r.w > safe.X - G or r.y + r.h > safe.Y - G then
			return false
		end
		for _, a in ipairs(avoid) do
			if a.w > 0 and a.h > 0 and r.x < a.x + a.w + G and a.x < r.x + r.w + G
				and r.y < a.y + a.h + G and a.y < r.y + r.h + G then
				return false
			end
		end
		return true
	end
	local scale = math.min(FirstHatchCard.MaxScale, (safe.X - G * 2) / base.X,
		FirstHatchCard.MaxHeightShare * safe.Y / base.Y)
	while scale >= FirstHatchCard.MinScale - 1e-9 do
		local w, h = math.floor(base.X * scale), math.floor(base.Y * scale)
		local x = math.floor(safe.X / 2 - w / 2)
		-- As low as it can stand: over the hotbar and the bands over it.
		local y = math.floor(safe.Y - G - h)
		while y >= G do
			local r = rect(x, y, w, h)
			if clear(r) then
				return r, w / base.X
			end
			y -= 4
		end
		scale -= FirstHatchCard.Step
	end
	return rect(0, 0, 0, 0), 0
end

-- Where the HATCH puts the body: on `spawn` (PlotService.SpawnCFrameFor, which
-- faces out through the gate), level, facing `toward` -- the bed the plant will
-- come up in -- or, with none (or one under the feet), turned round to face
-- into the garden.
function FirstHatchCard.landing(spawn: CFrame, toward: Vector3?): CFrame
	local at = spawn.Position
	if toward then
		local level = Vector3.new(toward.X, at.Y, toward.Z)
		if (level - at).Magnitude > 1 then
			return CFrame.lookAt(at, level)
		end
	end
	return spawn * CFrame.Angles(0, math.pi, 0)
end

return FirstHatchCard
