--!strict
--==============================================================================
-- Steal a Seed :: StarbloomTeaser (2026-10-01, the owner's ask)
--
-- Words over the road's last wall: "BEYOND THE STARS…" in glowing lavender,
-- "NEW BIOME · COMING SOON" under it in gold (GameConfig.StarbloomTeaser). A
-- visual teaser and nothing else -- no date, no biome, no door; nothing here
-- touches the game.
--
-- Drawn as the hub's floating words are (FloatingSign: LuckiestGuy, the dark
-- outline, a billboard sized in studs, so it always faces whoever looks at it),
-- each client's own on a local anchor, and up for everybody all the time.
--
-- THE GLOW is a copy of the headline just behind it whose wide, half-clear edge
-- is lavender -- the real letters and their dark outline sit on top, so a soft
-- band of light shows round them (the community chest's glow, without the
-- rainbow) -- and a soft lavender light on the wall behind. Both steady:
-- nothing here moves or flashes.
--
-- WHERE: the corridor's middle, OffWall in front of the end wall's face and
-- Above the road -- over the racing line, far from the pods along the walls and
-- their prompts, and in nobody's way: the anchor collides with nothing.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))

local StarbloomTeaser = {}

StarbloomTeaser.Name = "StarbloomTeaser"
StarbloomTeaser.BiomeId = "starbloom"

-- Starbloom, while it is the road's last segment -- the one MapService gives
-- the end wall. Nil otherwise: there is no wall to put the words on.
function StarbloomTeaser.biome(): BiomeData.Biome?
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.Id == StarbloomTeaser.BiomeId and biome.Order == #BiomeData.Biomes then
			return biome
		end
	end
	return nil
end

-- The middle of the words, in the world. The end wall stands just past the
-- segment's far edge (farZ), so its face is at farZ and the road is at higher Z.
function StarbloomTeaser.placement(): CFrame?
	local biome = StarbloomTeaser.biome()
	if not biome then
		return nil
	end
	local T = GameConfig.StarbloomTeaser
	local _, farZ = BiomeData.SegmentBounds(biome)
	return CFrame.new(0, GameConfig.Map.GroundY + T.Above, farZ + T.OffWall)
end

function StarbloomTeaser.build(parent: Instance): FloatingSign.Sign?
	local at = StarbloomTeaser.placement()
	if not at then
		return nil
	end
	local T = GameConfig.StarbloomTeaser
	local sign = FloatingSign.new({
		name = StarbloomTeaser.Name,
		parent = parent,
		at = at,
		text = T.Text,
		colour = T.Colour,
		width = T.Width,
		height = T.Height,
		subText = T.SubText,
		subHeight = T.SubHeight,
	})
	-- Seen down the whole last segment, not just across the hub.
	sign.gui.MaxDistance = T.Distance
	local sub = sign.sub
	if sub then
		sub.TextColor3 = T.SubColour
		sub.ZIndex = 2
	end

	local words = sign.words
	local halo = Instance.new("TextLabel")
	halo.Name = "Glow"
	halo.BackgroundTransparency = 1
	halo.Position = words.Position
	halo.Size = words.Size
	halo.Font = words.Font
	halo.TextScaled = true
	halo.Text = words.Text
	halo.TextColor3 = T.Colour
	halo.ZIndex = 1
	words.ZIndex = 2
	local edge = Instance.new("UIStroke")
	edge.Color = T.Colour
	edge.Thickness = T.GlowThickness
	edge.Transparency = T.GlowTransparency
	edge.Parent = halo
	halo.Parent = sign.gui

	local light = Instance.new("PointLight")
	light.Name = "TeaserLight"
	light.Color = T.Colour
	light.Brightness = T.LightBrightness
	light.Range = T.LightRange
	light.Shadows = false
	light.Parent = sign.anchor

	sign.setShown(true)
	return sign
end

return StarbloomTeaser
