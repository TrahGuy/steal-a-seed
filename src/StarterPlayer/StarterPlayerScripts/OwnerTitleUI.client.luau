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
--
-- ON A PHONE (2026-10-09, the owner: "make the title smaller, it looks huge
-- specially on phones"): the server builds every rebirth title at its desktop
-- size. This redraws each one at GameConfig.rebirthTitleLook for THIS screen
-- (rebirthTitleScale: three quarters on a phone, 1 elsewhere) and keeps ADMIN
-- over it at that size (ownerTitleLift). ADMIN itself shrinks on a phone too
-- (the owner, 2026-10-09: "shrink admin on phones too": ownerTitleScale,
-- ownerTitleLook). Checked with the rainbow's steps, so a turned or resized
-- screen follows. A desktop's titles are never touched.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local TITLE = GameConfig.OwnerTitle
local REBIRTH = GameConfig.Rebirth.Title
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

-- This screen's scales: the rebirth titles' and ADMIN's (both 1 on desktops
-- and tablets).
local function screenScales(): (number, number)
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize
	local touch = UserInputService.TouchEnabled
	return GameConfig.rebirthTitleScale(viewport, touch), GameConfig.ownerTitleScale(viewport, touch)
end

-- One of ADMIN's two words (the glow, the letters): its size and its outline.
local function fitWord(label: Instance?, size: number, thickness: number)
	if label and label:IsA("TextLabel") then
		if label.TextSize ~= size then
			label.TextSize = size
		end
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke and stroke.Thickness ~= thickness then
			stroke.Thickness = thickness
		end
	end
end

-- A rebirth title at this screen's size, or ADMIN at this screen's size and
-- lift over it. Writes only what differs, so at scale 1 the server's values
-- stand.
local function place(gui: BillboardGui, scale: number, adminScale: number)
	if gui.Name == REBIRTH.Name then
		local box, words, sub = GameConfig.rebirthTitleLook(scale)
		local size = UDim2.fromOffset(box.X, box.Y)
		if gui.Size ~= size then
			gui.Size = size
		end
		local w = gui:FindFirstChild("Words")
		if w and w:IsA("TextLabel") and w.TextSize ~= words then
			w.TextSize = words
		end
		local s = gui:FindFirstChild("Sub")
		if s and s:IsA("TextLabel") and s.TextSize ~= sub then
			s.TextSize = sub
		end
	elseif gui.Name == TITLE.Name then
		local look = GameConfig.ownerTitleLook(adminScale)
		local size = UDim2.fromOffset(look.box.X, look.box.Y)
		if gui.Size ~= size then
			gui.Size = size
		end
		fitWord(gui:FindFirstChild("Glow"), look.text, look.glow)
		fitWord(gui:FindFirstChild("Letters"), look.text, look.edge)
		local head = gui.Parent
		local stacked = head ~= nil and head:FindFirstChild(REBIRTH.Name) ~= nil
		local lift = Vector2.new(0, GameConfig.ownerTitleLift(stacked, scale, adminScale))
		if gui.SizeOffset ~= lift then
			gui.SizeOffset = lift
		end
	end
end

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
	-- At this screen's size from its first frame; a new rebirth title moves
	-- ADMIN on the same head with it.
	local scale, adminScale = screenScales()
	place(instance, scale, adminScale)
	local head = instance.Parent
	local admin = if instance.Name == REBIRTH.Name and head then head:FindFirstChild(TITLE.Name) else nil
	if admin and admin:IsA("BillboardGui") then
		place(admin, scale, adminScale)
	end
end

-- ADMIN's, and since 2026-10-08 the rebirth titles too (RebirthService): each
-- hides under a trap's countdown the same way, and the top step of the rebirth
-- ladder carries a rainbow that turns with ADMIN's. The others have none.
for _, tag in ipairs({ TITLE.Tag, GameConfig.Rebirth.Title.Tag }) do
	CollectionService:GetInstanceAddedSignal(tag):Connect(track)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
		titles[instance :: any] = nil
	end)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		track(instance)
	end
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
		local scale, adminScale = screenScales()
		local seen = false
		local colours: ColorSequence? = nil
		for gui, rainbows in pairs(titles) do
			if not gui.Parent then
				titles[gui] = nil
			else
				place(gui, scale, adminScale)
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
