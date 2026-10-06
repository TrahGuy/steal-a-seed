--!strict
--==============================================================================
-- Steal a Seed :: PlantLabel (2026-10-04, the owner's overhead-label brief)
--
-- THE THREE LINES OVER A GROWN CREATURE IN A BED, as data and as one billboard.
-- PlantUI owns one per grown planted model and drives it; this file decides
-- what the lines say and builds what they are drawn with. It listens to
-- nothing and runs nothing by itself.
--
--     RARE                  the rarity word: its colour, or RarityFX's light for
--                           Mythic, Divine and Secret (the Bag's own styling)
--     FROSTROOT             the name, the largest line
--     HUGE • $1.46K/s       the size word in its tier colour -- TITAN and COLOSSAL
--                           in the wheel's own lettering (WheelDraw.prestige) --
--                           and the income per second in the reveal's green
--
-- SUPERSEDES the old rule that a grown plant carries no plate (PlantUI's banner).
-- NO KG ANYWHERE, and no size at all for a Secret or an unsized event form
-- (PlantInfo.SizeWord): the separator goes and the income stands centred.
--
-- THE INCOME IS THE OWNER'S, NOT THE LOOKER'S: SeedData.IncomePerSecond -- the
-- one calculation EconomyService pays from, fixed Secret and event incomes
-- included -- times GameConfig.gardenIncomeMultiplier(plot): the owner's pass
-- and boosts as the server publishes them on the plot, and the rain, each once.
--
-- BOUNDED: a fixed pixel size whatever the creature's size (a Tiny and an
-- oversized Secret wear the same label), its bottom edge GapStuds over the
-- creature's measured top -- measured ONCE, when the label is made -- faded
-- out between NearStuds and FarStuds of FLAT distance from the camera (height
-- ignored, so a Colossal's high label reads like a Tiny's) and off past it.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local WheelDraw = require(Shared:WaitForChild("WheelDraw"))

local PlantLabel = {}

local L = GameConfig.Labels.Plant
local DOT = " \u{2022} "

export type Content = {
	rarity: string,
	rarityText: string,
	rarityColour: Color3,
	name: string,
	-- nil when the creature has no size to show (a Secret, an unsized form).
	size: string?,
	sizeColour: Color3,
	-- "titan" | "colossal" | nil: the size word wears the wheel's lettering.
	sizeStyle: string?,
	income: string,
	incomePerSecond: number,
}

--==============================================================================
-- WHAT THE LINES SAY
--==============================================================================
-- nil for anything that is not a known species.
function PlantLabel.content(speciesId: any, tier: any, multiplier: number?): Content?
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	if not species then
		return nil
	end
	local info = PlantInfo.Describe(speciesId, tier, true, multiplier)
	local size = PlantInfo.SizeWord(speciesId, tier)
	local style: string? = nil
	if size then
		local band = SeedData.Tier(tonumber(tier))
		if band.name == "Colossal" then
			style = "colossal"
		elseif band.name == "Titan" then
			style = "titan"
		end
	end
	local rate = info.incomePerSecond or 0
	return {
		rarity = info.rarity,
		rarityText = string.upper(info.rarity),
		rarityColour = info.rarityColour,
		name = string.upper(info.title),
		size = if size then string.upper(size) else nil,
		sizeColour = PlantInfo.SizeColour(speciesId, tier),
		sizeStyle = style,
		income = "$" .. GameConfig.compact(rate) .. "/s",
		incomePerSecond = rate,
	}
end

--==============================================================================
-- HOW MUCH OF IT SHOWS AT A CAMERA DISTANCE
--==============================================================================
function PlantLabel.fade(distance: number): number
	if distance ~= distance then
		return 0
	end
	if distance <= L.NearStuds then
		return 1
	end
	if distance >= L.FarStuds then
		return 0
	end
	return 1 - (distance - L.NearStuds) / (L.FarStuds - L.NearStuds)
end

-- The label's drawn height in pixels, before any scale.
function PlantLabel.height(): number
	return (L.RaritySize + 4) + (L.NameSize + 6) + (L.IncomeSize + 6) + 4
end

--==============================================================================
-- THE BILLBOARD
--==============================================================================
export type Label = {
	gui: BillboardGui,
	column: Frame,
	rarity: TextLabel,
	rarityFX: RarityFX.Handle,
	name: TextLabel,
	info: Frame,
	size: TextLabel,
	dot: TextLabel,
	income: TextLabel,
	sizeStyle: string?,
	glint: WheelDraw.Glint?,
	-- Every text and stroke at full strength, as last painted: what a fade scales.
	base: { [Instance]: number },
	alpha: number,
	shown: boolean,
	scale: number,
	key: string,
}

local function line(parent: Instance, name: string, font: Enum.Font, size: number, colour: Color3,
	outline: number, order: number): (TextLabel, UIStroke)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextSize = size
	label.TextColor3 = colour
	label.Text = ""
	label.LayoutOrder = order
	-- Above layer 1, so a RarityFX twin (one layer below) can stand behind it.
	label.ZIndex = 3
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = L.Outline
	stroke.Thickness = outline
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return label, stroke
end

-- `anchor` the creature's base, `lift` studs from it to where the label's bottom
-- edge sits, `scale` the screen's (a phone's PhoneScale, a TV's own).
function PlantLabel.new(parent: Instance, anchor: BasePart, lift: number, scale: number): Label
	local height = PlantLabel.height()
	local gui = Instance.new("BillboardGui")
	gui.Name = "SeedPlantLabel"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(L.Width * scale, height * scale)
	-- Raised by half its own height, so its BOTTOM edge is at the point: the
	-- label stands on the crown whatever its pixel size (PromptUI's measure).
	gui.SizeOffset = Vector2.new(0, 0.5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	-- On top, like every other billboard in the game. It was depth-tested, and
	-- in the Edit preview a Snarlbloom's own eye stalks, reaching forward over
	-- its crown, hid its label entirely; the fade by distance is what keeps far
	-- labels from printing over near creatures. Never lit by the world.
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = L.FarStuds + 2
	gui.ResetOnSpawn = false
	gui.Enabled = false
	-- GLOBAL layering, and every line above layer 1: RarityFX draws a Secret's
	-- light keyline as a twin of the word one layer BELOW it, as its child, and
	-- only Global layering puts a child behind its parent. At layer 1 the twin
	-- landed on top and turned SECRET into a pale blur (the Edit preview).
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = parent

	local column = Instance.new("Frame")
	column.Name = "Column"
	column.BackgroundTransparency = 1
	column.Size = UDim2.new(1 / scale, 0, 1 / scale, 0)
	column.Parent = gui
	if scale ~= 1 then
		local s = Instance.new("UIScale")
		s.Scale = scale
		s.Parent = column
	end
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = column

	local rarity, rarityLine = line(column, "Rarity", L.RarityFont, L.RaritySize, L.Separator, L.LineOutline, 1)
	rarity.Size = UDim2.new(1, 0, 0, L.RaritySize + 4)
	local name = line(column, "Name", L.NameFont, L.NameSize, L.Name, L.NameOutline, 2)
	name.Size = UDim2.new(1, 0, 0, L.NameSize + 6)
	-- A long name shrinks rather than runs off the label.
	name.TextScaled = true
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = L.NameSize
	fit.MinTextSize = math.floor(L.NameSize * 0.6)
	fit.Parent = name

	local info = Instance.new("Frame")
	info.Name = "Info"
	info.BackgroundTransparency = 1
	info.Size = UDim2.new(1, 0, 0, L.IncomeSize + 6)
	info.LayoutOrder = 3
	info.Parent = column
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = info
	local function piece(pieceName: string, font: Enum.Font, size: number, colour: Color3, order: number): TextLabel
		local it = line(info, pieceName, font, size, colour, L.LineOutline, order)
		it.Size = UDim2.new(0, 0, 1, 0)
		it.AutomaticSize = Enum.AutomaticSize.X
		return it
	end
	local sizeWord = piece("Size", L.InfoFont, L.InfoSize, L.Separator, 1)
	local dot = piece("Dot", L.InfoFont, L.InfoSize, L.Separator, 2)
	dot.Text = DOT
	local income = piece("Income", L.IncomeFont, L.IncomeSize, L.Income, 3)

	return {
		gui = gui,
		column = column,
		rarity = rarity,
		rarityFX = RarityFX.text(rarity, rarityLine),
		name = name,
		info = info,
		size = sizeWord,
		dot = dot,
		income = income,
		sizeStyle = nil,
		glint = nil,
		base = {},
		alpha = 1,
		shown = false,
		scale = scale,
		key = "",
	}
end

-- What a fade scales from: every text and stroke under the label as painted.
local function captureBase(label: Label)
	table.clear(label.base)
	for _, d in ipairs(label.gui:GetDescendants()) do
		if d:IsA("TextLabel") then
			label.base[d] = d.TextTransparency
		elseif d:IsA("UIStroke") then
			label.base[d] = d.Transparency
		end
	end
end

local function applyAlpha(label: Label)
	local a = label.alpha
	for object, rest in pairs(label.base) do
		local want = 1 - (1 - rest) * a
		if object:IsA("TextLabel") then
			if object.TextTransparency ~= want then
				object.TextTransparency = want
			end
		elseif (object :: any).Transparency ~= want then
			(object :: any).Transparency = want
		end
	end
end

function PlantLabel.paint(label: Label, content: Content)
	local key = table.concat({ content.rarity, content.name, content.size or "", content.income,
		content.sizeStyle or "", if RarityFX.still() then "still" else "live" }, "|")
	if key == label.key then
		return
	end
	label.key = key
	-- Back to full strength before anything is restyled, so a fade never gets
	-- captured as the label's resting look.
	for object, rest in pairs(label.base) do
		if object:IsA("TextLabel") then
			object.TextTransparency = rest
		else
			(object :: any).Transparency = rest
		end
	end

	label.rarity.Text = content.rarityText
	RarityFX.setText(label.rarityFX, content.rarity, content.rarityColour)
	label.name.Text = content.name

	local sized = content.size ~= nil
	label.size.Visible = sized
	label.dot.Visible = sized
	label.size.Text = content.size or ""
	if label.sizeStyle ~= content.sizeStyle then
		local old = label.size:FindFirstChild("Prestige")
		if old then
			old:Destroy()
		end
		label.glint = nil
		label.sizeStyle = content.sizeStyle
		if content.sizeStyle then
			label.glint = WheelDraw.prestige(label.size, content.sizeStyle :: string)
		end
	end
	if not content.sizeStyle then
		label.size.TextColor3 = content.sizeColour
	end
	label.income.Text = content.income

	captureBase(label)
	applyAlpha(label)
end

-- How strong it is drawn (PlantLabel.fade), in tenths: a fade writes only when
-- its step changes.
function PlantLabel.setAlpha(label: Label, alpha: number)
	local stepped = math.clamp(math.floor(alpha * 10 + 0.5) / 10, 0, 1)
	if stepped == label.alpha then
		return
	end
	label.alpha = stepped
	applyAlpha(label)
end

-- On or off (out of range, faded out, selected for PICK UP). Only a shown
-- label's rarity light runs.
function PlantLabel.setShown(label: Label, shown: boolean)
	if label.shown == shown then
		return
	end
	label.shown = shown
	label.gui.Enabled = shown
	RarityFX.setActive(label.rarityFX, shown)
end

-- The drawn height in pixels while it is shown, 0 while it is not: what CashPop
-- starts a pop above.
function PlantLabel.drawnHeight(label: Label): number
	return if label.shown and label.alpha > 0 then math.round(PlantLabel.height() * label.scale) else 0
end

-- A TITAN or COLOSSAL size word's light, stepped by the caller's one update
-- for the labels it shows; still under reduced motion.
function PlantLabel.step(label: Label, t: number)
	local g = label.glint
	if g and label.shown then
		WheelDraw.glint({ g }, t, RarityFX.still())
	end
end

function PlantLabel.destroy(label: Label)
	RarityFX.forget(label.rarityFX)
	label.glint = nil
	label.gui:Destroy()
end

return PlantLabel
