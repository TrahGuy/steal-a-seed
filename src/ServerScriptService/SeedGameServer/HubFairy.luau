--!strict
-- Steal a Seed :: HubFairy
--
-- Builds the fairy that tends the market stall. Geometry only -- it does not
-- move her. Motion lives on the CLIENT, in Ambience.client.luau, and the two
-- halves meet at one CollectionService tag.
--
-- NOT NAMED "*Service" ON PURPOSE, same as MapDecor: ServerMain auto-starts
-- every ModuleScript in this folder whose name ends in Service, and this is a
-- builder with no lifecycle of its own.
--
--==============================================================================
-- WHY THE SERVER DOES NOT ANIMATE HER
--
-- The obvious build is a server loop writing her CFrame every frame. It works,
-- and it is the wrong shape:
--
--   * Every write REPLICATES. One fairy at 60 Hz is a stream of position
--     updates to every client in the server, forever, for a decoration.
--   * It runs at the SERVER's framerate, so she stutters exactly when the
--     server is busy -- which is when players are actually doing things.
--   * She would be anchored and server-owned, so the motion would arrive
--     interpolated and slightly late on every machine.
--
-- Animating on each client instead costs no bandwidth at all, runs at each
-- player's own framerate, and looks better on a good machine. The positions
-- diverge between clients by a fraction of a stud, which for a fairy nobody can
-- interact with is not a difference anybody can observe.
--
-- This is the same split the previous project used for its shimmering
-- nameplates: the server builds and tags, one client loop walks the tagged set.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local HubFairy = {}

--==============================================================================
-- SHE IS NOT MADE OF NEON
--
-- The first build made every part Neon, on the theory that a fairy should glow.
-- At midday, under Brightness 2.4, Neon does not glow -- it CLIPS. Body, hair,
-- head and four translucent wings all saturated to the same white, and the
-- whole character came out as a featureless blob you could not find a face on.
--
-- The glow comes from the PointLight instead, which lights the stall around her
-- without touching her own shading. Everything she is made of is plain plastic,
-- so her colours survive the exposure and she reads as a person.
--==============================================================================
local WING = Color3.fromRGB(206, 240, 252)
local DRESS = Color3.fromRGB(240, 112, 168)
local DRESS_DARK = Color3.fromRGB(212, 86, 142)
local SKIN = Color3.fromRGB(255, 220, 186)
local HAIR = Color3.fromRGB(250, 200, 96)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame,
	color: Color3, material: Enum.Material?, transparency: number?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	-- She is scenery you cannot touch. Non-collidable so nobody can shove her
	-- through the counter, non-query so she never blocks a raycast.
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ball(parent: Instance, name: string, size: number, cf: CFrame,
	color: Color3, material: Enum.Material?): BasePart
	local p = part(parent, name, Vector3.new(size, size, size), cf, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

--==============================================================================
-- BUILD
--
-- `home` is where she hovers. The client reads it back off the model's own
-- attributes rather than being told, so a fairy moved in Studio still orbits
-- wherever she was put.
--==============================================================================
function HubFairy.build(home: CFrame, facing: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Fairy"

	-- Invisible root. Everything is positioned relative to it, and the client
	-- moves it -- so her shape is authored once here in local space and the
	-- animation never has to know what she is made of.
	local root = part(model, "Root", Vector3.new(0.4, 0.4, 0.4), home,
		Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1)
	model.PrimaryPart = root

	-- A SKIRT, NOT JUST A BALL. Three stacked spheres read as a snowman, which
	-- is what the first attempt looked like. A flattened cone under a smaller
	-- body gives her a waist, and a waist is most of what separates a person
	-- from a snowman at this part count.
	local skirt = ball(model, "Skirt", 1.7, home * CFrame.new(0, -0.95, 0), DRESS_DARK)
	skirt.Size = Vector3.new(1.7, 1.0, 1.7)
	ball(model, "Body", 1.15, home * CFrame.new(0, -0.2, 0), DRESS)
	ball(model, "Head", 1.0, home * CFrame.new(0, 0.62, 0), SKIN)
	-- Hair BEHIND and slightly above, never centred: a sphere the same size as
	-- the head, centred on it, swallows the face and gives her two heads.
	--
	-- BEHIND IS +Z. A CFrame's local -Z is the direction it FACES, so the
	-- obvious-looking negative offset puts hair and wings over the face instead
	-- of behind the head -- which is exactly what the first build did.
	local hair = ball(model, "Hair", 1.15, home * CFrame.new(0, 0.78, 0.28), HAIR)
	hair.Size = Vector3.new(1.15, 1.0, 1.05)

	--== WINGS ==--
	-- VERTICAL PANELS BEHIND THE SHOULDERS (+Z -- see the note on hair above),
	-- swept out and back. The first pass
	-- laid them flat and horizontal, which read as a plank driven through her
	-- rather than as wings -- a wing seen from the side is a tall thin shape,
	-- not a wide flat one.
	--
	-- The rest pose is a full CFrame, not three numbers. Position alone cannot
	-- express "swept back 20 degrees", so the sweep had to live somewhere, and
	-- a rotation baked into the offset is a rotation the animation never has to
	-- know about.
	local wingSpecs = {
		{ name = "WingUL", size = Vector3.new(1.5, 2.1, 0.12),
		  off = CFrame.new(-0.85, 0.35, 0.45) * CFrame.Angles(0, math.rad(28), math.rad(18)) },
		{ name = "WingUR", size = Vector3.new(1.5, 2.1, 0.12),
		  off = CFrame.new(0.85, 0.35, 0.45) * CFrame.Angles(0, math.rad(-28), math.rad(-18)) },
		{ name = "WingLL", size = Vector3.new(1.1, 1.5, 0.12),
		  off = CFrame.new(-0.7, -0.55, 0.5) * CFrame.Angles(0, math.rad(34), math.rad(30)) },
		{ name = "WingLR", size = Vector3.new(1.1, 1.5, 0.12),
		  off = CFrame.new(0.7, -0.55, 0.5) * CFrame.Angles(0, math.rad(-34), math.rad(-30)) },
	}
	for _, spec in ipairs(wingSpecs) do
		-- Translucent plastic, not Neon. A Neon wing at this transparency is a
		-- white rectangle over her face; plastic lets the colour and the shape
		-- through.
		local w = part(model, spec.name, spec.size, home * spec.off, WING,
			Enum.Material.SmoothPlastic, 0.45)
		-- Stored on the part so the animation never derives a rest pose from a
		-- CFrame that is already moving -- doing that is how a flapping wing
		-- walks off the body one rounding error at a time.
		w:SetAttribute("RestOffset", spec.off)
		w:SetAttribute("Side", spec.off.X < 0 and -1 or 1)
	end

	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Brightness = 2.2
	glow.Range = 18
	glow.Color = Color3.fromRGB(255, 190, 230)
	glow.Shadows = false
	glow.Parent = root

	-- Where she orbits. Written as attributes rather than captured at runtime so
	-- the client has a fixed anchor even after it has moved her a thousand
	-- times -- otherwise the orbit walks away from the stall.
	model:SetAttribute("HomeX", home.X)
	model:SetAttribute("HomeY", home.Y)
	model:SetAttribute("HomeZ", home.Z)

	-- SHE FACES THE CUSTOMER, NOT HER DIRECTION OF TRAVEL.
	--
	-- Facing the orbit tangent is what a bird does and it is wrong for a
	-- shopkeeper: she spent most of her circuit with her back to whoever walked
	-- up to the counter. A fixed facing with drifting movement reads as somebody
	-- hovering in place attending to you, which is the whole job.
	local f = facing.Magnitude > 0 and facing.Unit or Vector3.new(0, 0, -1)
	model:SetAttribute("FaceX", f.X)
	model:SetAttribute("FaceZ", f.Z)

	model.Parent = parent
	CollectionService:AddTag(model, GameConfig.Tags.Fairy)
	return model
end

return HubFairy
