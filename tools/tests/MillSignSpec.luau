--!nocheck
--==============================================================================
-- THE MILL SIGN STAYS ON THE GROUND
--
-- It did not. TreadmillService rebuilt the sign from `sign:GetPivot()`, and the
-- sign's PrimaryPart is its POST, whose centre sits 2.6 * Scale above the base
-- BuildSign expects. So every upgrade handed the builder a frame that was
-- already half a post too high and it added the offset again: 1.976 studs of
-- rise per rebuild at Scale 0.76, cumulative, for ever.
--
-- Nobody noticed for a while because it is invisible until you upgrade, and
-- then it is a signpost hanging in the air over your machine.
--
-- This is a pure geometry fixture: it builds real mills and real signs and
-- measures them. No plot, no profile, no Play session. Run it with
-- tools/tests/run.luau in Edit for fresh source throughout.
--
-- Since 2026-10-06 the sign has three spots in the mill's frame
-- (GameConfig.Mill.Sign): FrontOffset for a mill in front of its plot (plots
-- 1-5, every tier), Offset beside a plot below BesideTallFrom, and
-- BesideTallOffset beside a plot from there (plot 6's tiers 12-14, whose decor
-- fills Offset). Every placement below runs at each spot its tiers use.
--==============================================================================
local Shared = game.ReplicatedStorage.SeedGame.Shared
local MillModel = require(Shared.MillModel)
local GameConfig = require(Shared.GameConfig)

local MILL = GameConfig.Mill
local SIGN = MILL.Sign
local S = SIGN.Scale

local passed = 0
local function check(ok, label)
	assert(ok, label)
	passed += 1
end

--==============================================================================
-- THE GROUND IS Offset.Y, AND THAT IS NOT A COINCIDENCE
--
-- Measured on the built map: a ray from the mill straight down hits TheField at
-- mill-local Y -0.60, which is exactly Sign.Offset.Y. BuildSign puts the post's
-- bottom on the frame it is given, so the post meets the grass. (The deck's own
-- underside is lower, at -1.13; it is deliberately buried.)
--==============================================================================
local GROUND = SIGN.Offset.Y

local holder = Instance.new("Folder")
holder.Name = "MillSignSpecFixture"
holder.Archivable = false
holder.Parent = workspace

local function lowestOf(model, axisCF)
	local low = math.huge
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local h = d.Size * 0.5
			for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do for _, sz in { -1, 1 } do
				local p = axisCF:PointToObjectSpace((d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
				low = math.min(low, p.Y)
			end end end
		end
	end
	return low
end

check(typeof(MillModel.SignBase) == "function", "MillModel exposes the shared placement helper")

--==============================================================================
-- IDEMPOTENCE, WHICH IS THE WHOLE POINT
--
-- Every tier at both places (in front of a plot, beside one), six rotations
-- including the awkward ones a real plot uses, and nine placements each -- the
-- first build plus eight rebuilds of the SAME tier, which
-- is the case that used to climb fastest because nothing about it looks like a
-- change.
--==============================================================================
local REBUILDS = 8
local YAWS = { 0, 37, 90, -124.2, 180, 264 }
local worstDrift, worstDriftAt = 0, ""
local worstGround, worstGroundAt = 0, ""
local worstMill, worstMillAt = 0, ""
local worstReach, worstReachAt = 0, ""
local placements = 0

for _, beside in { false, true } do
for tier = 1, #MILL.Tiers do
	for _, yaw in YAWS do
		local millCF = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(yaw), 0)
		local model, belt = MillModel.Build(tier, millCF, holder)
		local sign = MillModel.BuildSign(MillModel.SignBase(millCF, tier, beside), model)
		local base0 = MillModel.SignBase(millCF, tier, beside).Position
		local belt0, deck0 = belt.Position, model.PrimaryPart.Position

		for r = 0, REBUILDS do
			if r > 0 then
				-- Exactly the sequence TreadmillService.Rebuild performs.
				local cf = model:GetPivot()
				model:Destroy()
				model, belt = MillModel.Build(tier, cf, holder)
				sign = MillModel.BuildSign(MillModel.SignBase(cf, tier, beside), model)
			end
			placements += 1
			local where = string.format("%s, tier %d, yaw %.0f, placement %d", if beside then "beside" else "front",
				tier, yaw, r)

			local drift = (MillModel.SignBase(model:GetPivot(), tier, beside).Position - base0).Magnitude
			if drift > worstDrift then worstDrift, worstDriftAt = drift, where end

			local post = sign:FindFirstChild("Post")
			local bottom = millCF:PointToObjectSpace(
				post.Position - Vector3.new(0, post.Size.Y * 0.5, 0)).Y
			local gap = math.abs(bottom - GROUND)
			if gap > worstGround then
				worstGround, worstGroundAt = gap, where .. string.format(" (bottom %.4f)", bottom)
			end

			local moved = math.max((belt.Position - belt0).Magnitude,
				(model.PrimaryPart.Position - deck0).Magnitude)
			if moved > worstMill then worstMill, worstMillAt = moved, where end

			local board = sign:FindFirstChild("Board")
			local reach = (board.Position - belt.Position).Magnitude
			if reach > worstReach then worstReach, worstReachAt = reach, where end
		end
		model:Destroy()
	end
end
end

check(worstDrift < 1e-3, string.format(
	"the sign must not move between rebuilds -- worst %.6f studs at %s", worstDrift, worstDriftAt))
check(worstGround < 1e-3, string.format(
	"the post's bottom must sit on the ground -- worst %.6f off at %s", worstGround, worstGroundAt))
check(worstMill < 1e-3, string.format(
	"the mill, deck and belt must not move -- worst %.6f studs at %s", worstMill, worstMillAt))
check(worstReach <= SIGN.PromptRange, string.format(
	"the board must stay inside PromptRange of the belt -- worst %.2f of %d at %s",
	worstReach, SIGN.PromptRange, worstReachAt))

--==============================================================================
-- AND THE BUG ITSELF, SO THIS FILE CANNOT PASS FOR THE WRONG REASON
--
-- Feed a sign's own pivot back in the way the old code did and the rise must
-- still be there. If this stops failing, the post has stopped being the
-- PrimaryPart or the offset has moved, and the assertions above are measuring
-- something else.
--==============================================================================
local legacy = CFrame.new(0, 0, 0)
local before = legacy.Y
local sign = MillModel.BuildSign(legacy, holder)
local climbed = sign:GetPivot().Y - before
sign:Destroy()
check(math.abs(climbed - 2.6 * S) < 1e-3, string.format(
	"a sign's pivot still sits %.4f above its base (post half-height); measured %.4f", 2.6 * S, climbed))

--==============================================================================
-- CLEARANCE AT EVERY SPOT
--
-- The sign must not end up inside the machine: every part of it, grown 0.25
-- (MillPlacementSpec's clearance), against every visible or colliding part of
-- every tier that stands at that spot -- Workspace:GetPartsInPart, real
-- shapes, the way MillPlacementSpec asks. Beside a plot it must also not cross
-- the plot fence, whose outer face stands Place.Beside.Side less half the
-- fence's 1.6 thickness to the mill's -X (11.2 since 2026-09-30).
--==============================================================================
local CLEAR = 0.25
local hitsAt = {}
local spots = 0
for _, beside in { false, true } do
	for tier = 1, #MILL.Tiers do
		local model = MillModel.Build(tier, CFrame.new(0, 0, 0), holder)
		local sign = MillModel.BuildSign(MillModel.SignBase(CFrame.new(0, 0, 0), tier, beside), holder)
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { model }
		params.RespectCanCollide = false
		for _, part in sign:GetDescendants() do
			if part:IsA("BasePart") then
				local probe = Instance.new("Part")
				probe.Anchored = true
				probe.CanCollide = false
				probe.CanTouch = false
				probe.Transparency = 1
				probe.Size = part.Size + Vector3.new(CLEAR * 2, CLEAR * 2, CLEAR * 2)
				probe.CFrame = part.CFrame
				probe.Parent = holder
				for _, hit in workspace:GetPartsInPart(probe, params) do
					if hit.Transparency < 1 or hit.CanCollide then
						table.insert(hitsAt, string.format("%s T%d %s x %s", if beside then "beside" else "front",
							tier, part.Name, hit.Name))
					end
				end
				probe:Destroy()
			end
		end
		spots += 1
		sign:Destroy()
		model:Destroy()
	end
end
check(#hitsAt == 0, string.format("every spot stands %.2f clear of every tier that uses it -- %d tier-spots -- %s",
	CLEAR, spots, table.concat(hitsAt, ", ", 1, math.min(#hitsAt, 6))))

local FENCE_X = -(MILL.Place.Beside.Side - 0.8)
local halfBoard = 9 * S * 0.5
local boardMinX = math.min(SIGN.Offset.X, SIGN.BesideTallOffset.X) - halfBoard
check(boardMinX > FENCE_X, string.format(
	"beside a plot, the board must stay inside the fence line: %.2f vs %.2f", boardMinX, FENCE_X))

holder:Destroy()

return string.format(
	"MillSignSpec: %d passed, 0 failed. %d placements (%d tiers x 2 places x %d rotations x %d builds).\n" ..
	"  sign drift %.6f | post-to-ground %.6f | mill/deck/belt movement %.6f\n" ..
	"  board reach %.2f of %d studs (worst %s) | %d tier-spots clear by %.2f\n" ..
	"  beside a plot: board inner edge %.2f, fence at %.2f -> %.2f studs of daylight\n" ..
	"Pure geometry: no plot, profile or Play session.",
	passed, placements, #MILL.Tiers, #YAWS, REBUILDS + 1,
	worstDrift, worstGround, worstMill,
	worstReach, SIGN.PromptRange, worstReachAt, spots, CLEAR,
	boardMinX, FENCE_X, boardMinX - FENCE_X)
