--!strict
--==============================================================================
-- Steal a Seed :: RainBeacon (2026-10-11, the owner's item 8)
--
-- THE RAIN BIOME'S BEACON (GameConfig.Weather.Beacon): a tall, soft rain-blue
-- column of light over the bridge while the temporary biome is open. Where it
-- stands, when it shows, how it fades and breathes -- pure -- and Build and
-- Apply, which touch only the instances Build made. RainBeacon.client draws it
-- on each client for itself; the server holds no part of it.
--
-- One BillboardGui, sized in studs, faces the camera from every side; its
-- layers are frames inside it, the haze behind and the core on top, each faded
-- along its length by a gradient. A billboard, because at the lowest graphics
-- quality the engine draws no part or beam past ~300 studs and a billboard
-- still draws far beyond (GameConfig's note).
--==============================================================================
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local RainBeacon = {}

local W = GameConfig.Weather
local B = W.Biome
local CFG = W.Beacon
local TAU = math.pi * 2

RainBeacon.Name = "SeedRainBeacon"
RainBeacon.Board = "Light"

export type Layer = {
	Name: string,
	Width: number,
	Transparency: number,
	Colour: Color3,
	Phase: number,
	Rich: boolean?,
}

-- The middle of the bridge's deck, on its top.
function RainBeacon.Foot(): Vector3
	return Vector3.new((B.Deck.X0 + B.Deck.X1) / 2, GameConfig.Map.GroundY + B.Deck.Y, B.Deck.Z)
end

-- Shown while the biome is open (its entrance open), and only then.
function RainBeacon.Shown(state: any): boolean
	return state == "active"
end

-- Its strength, 0 to 1, one step toward shown or hidden.
function RainBeacon.Step(level: number, shown: boolean, dt: number): number
	local rate = dt / CFG.FadeSeconds
	return if shown then math.min(1, level + rate) else math.max(0, level - rate)
end

-- Whether a layer is drawn: the widest is dropped under Reduced FX.
function RainBeacon.Drawn(layer: Layer, still: boolean): boolean
	return not (still and layer.Rich == true)
end

-- A layer's width in studs at `now`: breathing, or still under Reduced FX.
function RainBeacon.Width(layer: Layer, now: number, still: boolean): number
	if still then
		return layer.Width
	end
	return layer.Width * (1 + CFG.Pulse.Amount * math.sin((now / CFG.Pulse.Seconds) % 1 * TAU + layer.Phase))
end

-- A layer's transparency at strength `level`.
function RainBeacon.Clearness(layer: Layer, level: number): number
	return 1 - (1 - layer.Transparency) * math.clamp(level, 0, 1)
end

-- The fade along its length, top (0) to the deck (1): out of the sky over
-- Out, steady, and in from the deck over In.
function RainBeacon.Fade(): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(CFG.Out, 0),
		NumberSequenceKeypoint.new(1 - CFG.In, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
end

-- The billboard's width in studs: the widest layer at the top of its breath.
function RainBeacon.BoardWidth(): number
	local widest = 0
	for _, layer: Layer in ipairs(CFG.Layers) do
		widest = math.max(widest, layer.Width)
	end
	return widest * (1 + CFG.Pulse.Amount)
end

-- The beacon, unlit: an invisible anchor at the foot that nothing collides
-- with, finds or touches, and on it one self-lit billboard, Height tall,
-- standing on the deck, a frame per layer inside it.
function RainBeacon.Build(parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = RainBeacon.Name
	local anchor = Instance.new("Part")
	anchor.Name = "Anchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(RainBeacon.Foot())
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Parent = model
	model.PrimaryPart = anchor
	local wide = RainBeacon.BoardWidth()
	local board = Instance.new("BillboardGui")
	board.Name = RainBeacon.Board
	board.Size = UDim2.new(wide, 0, CFG.Height, 0)
	board.StudsOffsetWorldSpace = Vector3.new(0, CFG.Height / 2, 0)
	board.AlwaysOnTop = false
	board.LightInfluence = 0
	board.Active = false
	board.Enabled = false
	board.Adornee = anchor
	for i, layer: Layer in ipairs(CFG.Layers) do
		local frame = Instance.new("Frame")
		frame.Name = layer.Name
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.Position = UDim2.fromScale(0.5, 0)
		frame.Size = UDim2.fromScale(layer.Width / wide, 1)
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = layer.Colour
		frame.BackgroundTransparency = 1
		-- The first layer (the core) on top.
		frame.ZIndex = #CFG.Layers - i + 1
		frame.Visible = false
		local fade = Instance.new("UIGradient")
		fade.Name = "Fade"
		fade.Rotation = 90
		fade.Transparency = RainBeacon.Fade()
		fade.Parent = frame
		frame.Parent = board
	end
	board.Parent = anchor
	model.Parent = parent
	return model
end

-- Lights a built beacon at strength `level` at `now`; `still` under Reduced FX.
function RainBeacon.Apply(model: Model, level: number, now: number, still: boolean)
	local anchor = model.PrimaryPart
	local board = anchor and anchor:FindFirstChild(RainBeacon.Board)
	if not (board and board:IsA("BillboardGui")) then
		return
	end
	board.Enabled = level > 0
	local wide = board.Size.X.Scale
	for _, layer: Layer in ipairs(CFG.Layers) do
		local frame = board:FindFirstChild(layer.Name)
		if frame and frame:IsA("Frame") then
			local drawn = level > 0 and RainBeacon.Drawn(layer, still)
			frame.Visible = drawn
			if drawn then
				frame.Size = UDim2.fromScale(RainBeacon.Width(layer, now, still) / wide, 1)
				frame.BackgroundTransparency = RainBeacon.Clearness(layer, level)
			end
		end
	end
end

return RainBeacon
