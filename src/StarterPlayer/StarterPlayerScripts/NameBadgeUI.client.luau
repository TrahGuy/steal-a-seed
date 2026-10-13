--!strict
--==============================================================================
-- Steal a Seed :: NameBadgeUI (2026-10-13, the owner's NAME BADGES)
--
-- A name badge on a name over a head, put against the name's last letter as
-- THIS screen draws it (GameConfig.NameBadges).
--
-- VipService builds the name -- gold for a VIP, white for a badge's wearer who
-- is not one -- with the badge hidden in room kept on its right. A long name
-- shrinks to fit (TextScaled), so only a screen knows where its letters end:
-- the name's TextBounds, read whenever they change and once a second. The square is
-- GameConfig.nameBadgeBox for the size the name is drawn at: about its
-- capitals' height, its foot on their baseline, a small gap after the last
-- letter. The room kept on the right is what centres the name and its badge
-- as one.
--
-- Decides nothing: who wears which badge is the server's (by UserId, then VIP).
-- The badge sits in the name's own BillboardGui, so it shows and hides with the
-- name, at the same size near and far (an offset-sized billboard), and the
-- same MaxDistance.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local NAME = GameConfig.Pass.VipName

-- Each name's connections, dropped with it.
local watched: { [Instance]: { RBXScriptConnection } } = {}
-- Each placed name, with the bounds it was placed for.
type Placed = { label: TextLabel, mark: ImageLabel, at: Vector2 }
local placed: { [Instance]: Placed } = {}

-- Where the square goes for a name whose letters are `drawn` big, centred in a
-- label `labelW` x `labelH` at the billboard's left: the square's top-left in
-- the billboard, and its side.
local function spot(drawn: Vector2, labelW: number, labelH: number): (number, number, number)
	local size = drawn.Y
	local side, top, gap = GameConfig.nameBadgeBox("LuckiestGuy", size)
	return (labelW + drawn.X) / 2 + gap, (labelH - size) / 2 + top, side
end

local function place(gui: Instance, label: TextLabel, mark: ImageLabel)
	local drawn = label.TextBounds
	placed[gui] = { label = label, mark = mark, at = drawn }
	if drawn.X <= 0 or drawn.Y <= 0 then
		mark.Visible = false
		return
	end
	-- The label: the billboard's full height, its width less the room kept for
	-- the badge (VipService.dress), at its left.
	local kept = -label.Size.X.Offset
	local x, y, side = spot(drawn, NAME.Size.X - kept, NAME.Size.Y)
	mark.Size = UDim2.fromOffset(side, side)
	mark.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
	mark.Visible = true
end

local function watch(gui: Instance)
	if watched[gui] or not gui:IsA("BillboardGui") then
		return
	end
	local connections: { RBXScriptConnection } = {}
	watched[gui] = connections
	task.spawn(function()
		local label = gui:WaitForChild("Words", 10)
		local mark = gui:WaitForChild("Badge", 10)
		if not (label and label:IsA("TextLabel") and mark and mark:IsA("ImageLabel")) or watched[gui] ~= connections then
			return
		end
		table.insert(connections, label:GetPropertyChangedSignal("TextBounds"):Connect(function()
			place(gui, label, mark)
		end))
		place(gui, label, mark)
	end)
end

local function forget(gui: Instance)
	local connections = watched[gui]
	if connections then
		for _, c in ipairs(connections) do
			c:Disconnect()
		end
		watched[gui] = nil
	end
	placed[gui] = nil
end

-- ONCE A SECOND, TOO: a name's TextBounds can change with no signal. The
-- owner's read 104 x 15 when first placed and 131.7 x 19.8 once drawn (Play,
-- 2026-10-13), so every placed name is looked at again, and placed again when
-- its letters have moved. A few names, once a second.
task.spawn(function()
	while true do
		task.wait(1)
		for gui, p in pairs(placed) do
			if not gui.Parent then
				forget(gui)
			elseif p.label.TextBounds ~= p.at then
				place(gui, p.label, p.mark)
			end
		end
	end
end)

-- Only a name with a badge: VipService marks it (its "Badge" attribute).
local function consider(gui: Instance)
	if gui:GetAttribute("Badge") ~= nil then
		watch(gui)
	end
end

CollectionService:GetInstanceAddedSignal(NAME.Tag):Connect(consider)
CollectionService:GetInstanceRemovedSignal(NAME.Tag):Connect(forget)
for _, gui in ipairs(CollectionService:GetTagged(NAME.Tag)) do
	consider(gui)
end
