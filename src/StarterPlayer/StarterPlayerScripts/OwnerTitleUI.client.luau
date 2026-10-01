--!strict
-- Steal a Seed :: OwnerTitleUI
--
-- THE OWNER'S "ADMIN" TITLE, TURNING (2026-10-01; GameConfig.OwnerTitle)
--
-- OwnerTitleService builds the title on the owner's head and every client
-- receives it with their character. This only turns its rainbow -- the wheel's
-- own (WheelDraw.rainbow), one turn of its hues every DriftSeconds, the letters
-- and their glow together -- on THIS viewer's screen: smooth steps while one is
-- within its draw distance of this camera, a look twice a second otherwise, and
-- a still rainbow for a viewer who asked for reduced motion
-- (StatusText.reducedMotion). Decides nothing: who has a title is the server's.
--
-- It also steps aside -- on this screen only -- while TrapUI's red countdown
-- stands over that player (their TrappedUntil runs), so the two never overlap.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local TITLE = GameConfig.OwnerTitle
local TRAPPED_UNTIL = GameConfig.Attributes.TrappedUntil

-- Whether TrapUI's countdown is over this title's player right now.
local function trapped(gui: BillboardGui): boolean
	local head = gui.Adornee
	local character = head and head.Parent
	local owner = character and Players:GetPlayerFromCharacter(character)
	local endsAt = owner and tonumber(owner:GetAttribute(TRAPPED_UNTIL))
	return endsAt ~= nil and Workspace:GetServerTimeNow() < endsAt
end

-- Each title this client has, and the two rainbows in it.
local titles: { [BillboardGui]: { UIGradient } } = {}

local function track(instance: Instance)
	if not instance:IsA("BillboardGui") then
		return
	end
	local rainbows: { UIGradient } = {}
	for _, d in ipairs(instance:GetDescendants()) do
		if d:IsA("UIGradient") and d.Name == "Rainbow" then
			table.insert(rainbows, d)
		end
	end
	titles[instance] = rainbows
end

CollectionService:GetInstanceAddedSignal(TITLE.Tag):Connect(track)
CollectionService:GetInstanceRemovedSignal(TITLE.Tag):Connect(function(instance: Instance)
	titles[instance :: any] = nil
end)
for _, instance in ipairs(CollectionService:GetTagged(TITLE.Tag)) do
	track(instance)
end

task.spawn(function()
	local shift = 0
	local last = os.clock()
	while true do
		local now = os.clock()
		local still = StatusText.reducedMotion()
		if not still then
			-- Capped, so a hitch never jumps the colours.
			shift = (shift + math.min(now - last, 0.1) / TITLE.DriftSeconds) % 1
		end
		last = now
		local camera = Workspace.CurrentCamera
		local seen = false
		local colours: ColorSequence? = nil
		for gui, rainbows in pairs(titles) do
			if not gui.Parent then
				titles[gui] = nil
			else
				local clear = not trapped(gui)
				if gui.Enabled ~= clear then
					gui.Enabled = clear
				end
				local adornee = gui.Adornee
				if camera and adornee and adornee:IsA("BasePart")
					and (camera.CFrame.Position - adornee.Position).Magnitude <= TITLE.MaxDistance then
					seen = true
					colours = colours or WheelDraw.rainbow(if still then 0 else shift)
					for _, g in ipairs(rainbows) do
						g.Color = colours :: ColorSequence
					end
				end
			end
		end
		task.wait(if seen and not still then 1 / 30 else 0.5)
	end
end)
