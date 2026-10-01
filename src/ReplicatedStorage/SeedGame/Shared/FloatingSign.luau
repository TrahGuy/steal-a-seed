--!strict
--==============================================================================
-- Steal a Seed :: FloatingSign
--
-- Words that float over something in the hub, drawn the way the reward wheel's
-- "SPIN THE WHEEL!" is (WheelModel, THE SIGN): LuckiestGuy with a thick dark
-- outline, on a BillboardGui sized in STUDS -- a fixed size in the world, so it
-- shrinks with distance like the thing it stands over -- lit by nothing, and
-- gone past the wheel's own SignDistance. One plain colour: no gradient, no
-- motion, no particles, no screen panel (the owner, 2026-09-30).
--
-- EACH CLIENT'S OWN. A client makes it on a local anchor, so nobody else ever
-- sees it, and shows it only while THIS player can do what it says. That is
-- the caller's decision, made from the attributes the server already publishes;
-- this only draws. It starts hidden.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local WheelData = require(Shared:WaitForChild("WheelData"))

local FloatingSign = {}

-- The wheel sign's own face, outline and reach, so the hub's floating words
-- read as one family.
FloatingSign.Font = Enum.Font.LuckiestGuy
FloatingSign.Outline = Color3.fromRGB(34, 24, 16)
FloatingSign.OutlineThickness = 2.5
-- A smaller second line gets a slightly thinner edge: the same pixels round
-- smaller letters would read as a smear.
FloatingSign.SubOutlineThickness = 2
-- An optional third line for a sentence rather than a headline (2026-10-01):
-- the plain bold face the hub's boards use for their small print, wrapped, with
-- a thinner edge still.
FloatingSign.NoteFont = Enum.Font.GothamBold
FloatingSign.NoteOutlineThickness = 1.5
FloatingSign.Distance = WheelData.Place.SignDistance

export type Spec = {
	-- The BillboardGui's name; the anchor is named after it.
	name: string,
	-- Where the local anchor goes: the thing the words are over.
	parent: Instance,
	-- The middle of the words, in the world.
	at: CFrame,
	text: string,
	colour: Color3,
	-- The words' box, in studs.
	width: number,
	height: number,
	-- An optional smaller line under the words, and its box's height in studs.
	subText: string?,
	subHeight: number?,
	-- An optional sentence under that, wrapped, its box's height in studs, and
	-- its colour (the words' when not given).
	noteText: string?,
	noteHeight: number?,
	noteColour: Color3?,
}

export type Sign = {
	gui: BillboardGui,
	anchor: BasePart,
	words: TextLabel,
	sub: TextLabel?,
	note: TextLabel?,
	setShown: (boolean) -> (),
	shown: () -> boolean,
	destroy: () -> (),
}

local function lettered(parent: Instance, name: string, text: string, colour: Color3, position: UDim2,
	size: UDim2, thickness: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = FloatingSign.Font
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = colour
	label.Parent = parent
	local edge = Instance.new("UIStroke")
	edge.Color = FloatingSign.Outline
	edge.Thickness = thickness
	edge.Parent = label
	return label
end

function FloatingSign.new(spec: Spec): Sign
	local subHeight = if spec.subText then (spec.subHeight or spec.height * 0.5) else 0
	local noteHeight = if spec.noteText then (spec.noteHeight or spec.height * 0.6) else 0
	local total = spec.height + subHeight + noteHeight

	-- An invisible point to hang the words on, like the wheel's SignAnchor, and
	-- nothing a ray, a foot or a touch can find.
	local anchor = Instance.new("Part")
	anchor.Name = spec.name .. "Anchor"
	anchor.Size = Vector3.one * 0.2
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = spec.at
	anchor.Parent = spec.parent

	local gui = Instance.new("BillboardGui")
	gui.Name = spec.name
	-- In studs, as the wheel's: a fixed size in the world.
	gui.Size = UDim2.fromScale(spec.width, total)
	gui.MaxDistance = FloatingSign.Distance
	gui.LightInfluence = 0
	-- Behind walls like the rest of the world; a prompt, drawn on top of the
	-- world, is never under it.
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = anchor

	local share = spec.height / total
	local subShare = subHeight / total
	local words = lettered(gui, "Words", spec.text, spec.colour, UDim2.fromScale(0, 0), UDim2.fromScale(1, share),
		FloatingSign.OutlineThickness)
	local sub: TextLabel? = nil
	if spec.subText then
		sub = lettered(gui, "Sub", spec.subText, spec.colour, UDim2.fromScale(0, share),
			UDim2.fromScale(1, subShare), FloatingSign.SubOutlineThickness)
	end
	local note: TextLabel? = nil
	if spec.noteText then
		local made = lettered(gui, "Note", spec.noteText, spec.noteColour or spec.colour,
			UDim2.fromScale(0, share + subShare), UDim2.fromScale(1, 1 - share - subShare),
			FloatingSign.NoteOutlineThickness)
		made.Font = FloatingSign.NoteFont
		made.TextWrapped = true
		note = made
	end

	return {
		gui = gui,
		anchor = anchor,
		words = words,
		sub = sub,
		note = note,
		setShown = function(on: boolean)
			if gui.Enabled ~= on then
				gui.Enabled = on
			end
		end,
		shown = function(): boolean
			return gui.Enabled
		end,
		destroy = function()
			anchor:Destroy()
		end,
	}
end

return FloatingSign
