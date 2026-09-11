--!strict
--==============================================================================
-- PICKING YOUR OWN PLANT BACK UP, ON A TOUCHSCREEN
--
-- WHY THIS EXISTS AT ALL, because the obvious answer was tried and shipped and
-- the owner found it on a real phone.
--
-- A grown plant carries a `PickupPrompt` with a hold of ZERO -- taking your own
-- plant off your own bed should not need a hold, and that is still the right
-- call. But a zero-hold prompt fires on the touch that STARTS a gesture, and on
-- a phone the gesture that starts near a plant is usually the camera. So a thumb
-- coming down to look around lifted the plant instead, and the player had to
-- plant it again. Cancelling on movement cannot help: by the time a finger has
-- moved far enough to be called a drag, the pickup already happened.
--
-- Three things that do NOT fix it, for whoever is tempted:
--
--   a bigger movement threshold   makes the button harder to press on purpose
--                                 and still fires before the finger moves
--   another offset                the alignment is already exact -- 526a049
--                                 measured it and the owner approved it
--   a global delay before acting  makes every prompt in the game feel broken to
--                                 fix one of them
--
-- THE VERB WAS WRONG, NOT THE GEOMETRY. A destructive action must not be the
-- first half of an ambiguous gesture. So on touch it takes two deliberate steps:
--
--   1. tap the plant          -> it is SELECTED, and outlined. Nothing is taken.
--   2. press the PICK UP button -> now it is taken.
--
-- Step 1 is harmless, so being wrong about it costs nothing -- which is what
-- lets step 1 be a guess about a fingertip at all. Step 2 is a real button in a
-- real ScreenGui with its own rectangle, so being wrong about it is impossible.
--
-- DESKTOP IS UNTOUCHED. It keeps the floating prompt and E, because a mouse
-- cursor is not ambiguous and there was never a problem there.
--
--==============================================================================
-- WHAT THIS DOES NOT DO
--
-- It does not pick anything up, decide who owns anything, or keep a list of what
-- anybody has. It asks the server, using the verb the Garden panel has always
-- used, and the server decides. This file owns a highlight and a button.
--
-- IT WAS SUPPOSED TO PRESS THE PROMPT, and that is worth recording because the
-- reason it cannot is a real defect in something else -- see THE PROMPT CANNOT BE
-- PRESSED, below.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local Remotes = SeedGame:WaitForChild("Remotes")
local channel = Remotes:WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ATTR = GameConfig.Attributes
local PANEL = GameConfig.Panel
local PLANTING = GameConfig.Plant

local CREAM = Color3.fromRGB(242, 238, 206)
local BLACK = Color3.fromRGB(0, 0, 0)
local LIME = Color3.fromRGB(150, 220, 96)

--==============================================================================
-- TOUCH, AND THE SAME WORD PromptUI USES
--
-- PromptUI stops drawing the pickup panel when `UserInputService.TouchEnabled`,
-- and this starts working on exactly the same condition, so the two are
-- complementary by construction: there is no device where both draw an
-- affordance and none where neither does. Deriving "mobile" twice from two
-- different rules is how you get a gap.
--
-- The hotbar's own 10-or-5 decision is a DIFFERENT question -- it is about how
-- much width a strip needs -- and is deliberately not reused here. A desktop
-- with a touchscreen gets ten slots and this button, which is correct: it can
-- touch, so it needs a touch-safe way to pick a plant, and E still works.
--==============================================================================
local TOUCH = UserInputService.TouchEnabled
local PICKUP_PROMPT = "PickupPrompt"

--==============================================================================
-- TAP, OR CAMERA
--
-- Ten pixels and half a second. Deliberately SMALL, because this is not the
-- thing standing between the player and a mistake -- the button is. If a tap is
-- misread as a drag the player taps again; if a drag is misread as a tap they get
-- an outline they did not ask for and no plant is harmed. That asymmetry is the
-- whole reason the two-step exists, and it is why these numbers can stay tight
-- instead of creeping upward the way a one-step threshold has to.
--
-- The duration cap is what stops a slow camera swing that happens to return to
-- where it started from reading as a tap.
--==============================================================================
local TAP_SLOP = 10
local TAP_SECONDS = 0.5

-- Long enough that a double-press cannot ask twice, short enough to be invisible
-- to somebody who genuinely wants a second plant. The server refuses the second
-- ask anyway -- `byPlot[id] ~= entry` once it is gone -- so this is politeness
-- about the wire rather than the guard itself.
local PRESS_DEBOUNCE = 0.4

--==============================================================================
-- ONE HIGHLIGHT FOR THE WHOLE GAME
--
-- Created once and reparented, never one per plant: a bed holds twenty and
-- twenty permanent Highlight instances is twenty things to leak. Parent is the
-- adornee -- a Highlight with no Adornee outlines whatever it is parented to --
-- so clearing the selection is `Parent = nil` and the instance survives for the
-- next one.
--
-- Occluded, NOT AlwaysOnTop. A plant you can see through the fence is a plant
-- you would try to tap through the fence.
--==============================================================================
local highlight: Highlight? = nil

local function theHighlight(): Highlight
	local made = highlight
	if made then
		return made
	end
	made = Instance.new("Highlight")
	made.Name = "SeedPlantPick"
	made.DepthMode = Enum.HighlightDepthMode.Occluded
	made.FillColor = LIME
	made.FillTransparency = 0.86
	made.OutlineColor = LIME
	made.OutlineTransparency = 0
	highlight = made
	return made
end

--==============================================================================
-- THE BUTTON
--
-- A real TextButton in a real ScreenGui, sitting clear ABOVE the hotbar rather
-- than over it: the hotbar is 74 tall with a 12 gap under it, so 94 puts this
-- one's underside eight pixels above the top slot edge. Nothing overlaps, so
-- nothing steals a hotbar tap -- which matters because the hotbar is where the
-- plant is going.
--
-- DisplayOrder 31 is one above SeedLoadout so the strip cannot draw over it, and
-- below every panel (32+) so an open bag covers it -- though opening a panel
-- clears the selection anyway, so that is a belt on top of braces.
--==============================================================================
local HOTBAR_CLEARANCE = 94
local BUTTON_HEIGHT = 46

local layer = Instance.new("ScreenGui")
layer.Name = "SeedPlantPick"
layer.ResetOnSpawn = false
layer.DisplayOrder = 31
layer.Enabled = false
layer.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "PickUp"
button.AnchorPoint = Vector2.new(0.5, 1)
button.Position = UDim2.new(0.5, 0, 1, -HOTBAR_CLEARANCE)
-- 44 x 44 is the floor Roblox asks for and the one the close X was raised to in
-- 00b0142. This is wider than tall because it carries words, never narrower.
button.Size = UDim2.fromOffset(168, BUTTON_HEIGHT)
button.AutoButtonColor = false
button.BorderSizePixel = 0
button.Text = ""
button.BackgroundTransparency = 0.18
button.ZIndex = 5
button.Parent = layer
UIKit.corner(button, 12)
UIKit.gradient(button, PANEL.Fill, PANEL.Shade)
UIKit.stroke(button, BLACK, 2.5)
UIKit.clicks(button)

-- A second, brighter keyline inside the black one: the house edge stays black on
-- every surface in this game, so "this is live" is said by the ring inside it.
local ring = Instance.new("Frame")
ring.Name = "Ring"
ring.Position = UDim2.fromOffset(3, 3)
ring.Size = UDim2.new(1, -6, 1, -6)
ring.BackgroundTransparency = 1
ring.ZIndex = 6
ring.Parent = button
UIKit.corner(ring, 10)
UIKit.stroke(ring, LIME, 1.5)

local label = UIKit.outlined(button, "Word", 15, CREAM, 2)
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 5)
label.Size = UDim2.new(1, -12, 0, 17)
label.Text = "PICK UP"
label.ZIndex = 8

-- The plant's own name under the verb, so a player with two plants in reach can
-- see WHICH one they are about to lift. Truncated rather than wrapped: this is a
-- 46-pixel button and a second line would push the verb off it.
local caption = Instance.new("TextLabel")
caption.Name = "Which"
caption.AnchorPoint = Vector2.new(0.5, 1)
caption.Position = UDim2.new(0.5, 0, 1, -4)
caption.Size = UDim2.new(1, -12, 0, 14)
caption.BackgroundTransparency = 1
caption.Font = Enum.Font.FredokaOne
caption.TextSize = 11
caption.TextColor3 = PANEL.Edge
caption.TextTruncate = Enum.TextTruncate.AtEnd
caption.Text = ""
caption.ZIndex = 8
caption.Parent = button

--==============================================================================
-- WHAT IS SELECTED, AND EVERYTHING WATCHING IT
--
-- `watching` holds the connections that belong to THIS selection -- the model
-- going away, the prompt being switched off -- and is emptied every time the
-- selection is cleared. The global watchers further down are connected once and
-- live for the session; mixing the two is how a per-selection connection becomes
-- a per-selection leak.
--==============================================================================
type Selection = {
	model: Model,
	prompt: ProximityPrompt,
	label: string,
}

local selected: Selection? = nil
local watching: { RBXScriptConnection } = {}
local pressedAt = 0

-- Bumped by every clear and every select, so a watcher started for one selection
-- stops the moment it is no longer the current one. Cheaper and more certain than
-- trying to cancel a coroutine.
local generation = 0

--==============================================================================
-- HOW OFTEN A SELECTION LOOKS AT ITS OWN DISTANCE
--
-- A THIRD OF A SECOND, and only while something is selected -- the loop exits on
-- the next tick after the selection goes. So a player standing in their garden
-- with nothing selected pays nothing, which is the repo rule, and this is one
-- coroutine for the whole game rather than anything per plant or per frame.
--
-- It exists because PromptHidden cannot quite close the gap on its own: it fires
-- on a TRANSITION, so if a prompt is already hidden for its own reasons when the
-- player wanders off, no further hide arrives and the button would sit there
-- offering something out of reach.
--==============================================================================
local RANGE_POLL = 1 / 3

--==============================================================================
-- WHAT IS IN YOUR HANDS
--
-- Same test PlantPlace uses, and that is the point: while a plant Tool is held,
-- PlantPlace owns the tap -- a touch is aimed at the SOIL, to put the thing
-- down. Selecting a different plant in the middle of placing one is not
-- something anybody means, so this stands down entirely rather than racing it.
--==============================================================================
local function holdingAPlant(): boolean
	local character = player.Character
	local tool = if character then character:FindFirstChildOfClass("Tool") else nil
	return tool ~= nil and type(tool:GetAttribute("SpeciesId")) == "string"
end

--==============================================================================
-- STILL CLOSE ENOUGH TO PICK IT UP
--
-- Asked of the PROMPT, so the distance lives in exactly one place -- the same
-- MaxActivationDistance the engine uses to show it and the server honours when it
-- triggers. A second copy of that number here would be a second thing to keep in
-- step with PlantService.
--==============================================================================
local function inRange(prompt: ProximityPrompt): boolean
	local handle = prompt.Parent
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (handle and handle:IsA("BasePart") and root and root:IsA("BasePart")) then
		return false
	end
	return (handle.Position - root.Position).Magnitude <= prompt.MaxActivationDistance
end

local function myPlot(): Model?
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if instance:IsA("Model")
			and instance:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return instance
		end
	end
	return nil
end

--==============================================================================
-- IS THIS PLANT MINE, GROWN, AND OFFERING ITSELF
--
-- OWNERSHIP IS STRUCTURAL HERE, not a comparison: a plant is eligible only if it
-- is inside MY plot's Plants folder, and a neighbour's plants are in a folder
-- this never looks in. That is the same shape as the server's own guard -- it
-- indexes `growing` by plot, so asking for somebody else's placement id finds
-- nothing -- and it means a stranger's plant produces no selection and therefore
-- no button, rather than a button that fails.
--
-- The PROMPT is the availability test. It exists only on a grown plant
-- (`attachPickup` runs at STAGE_GROWN), it is destroyed with the model, and it
-- carries its own Enabled -- so "can this be picked up right now" is one
-- question asked of the object that will answer it, rather than three
-- reimplemented conditions that can drift from the server's.
--==============================================================================
local function promptFor(model: Instance): ProximityPrompt?
	if not model:IsA("Model") then
		return nil
	end
	if not CollectionService:HasTag(model, GameConfig.Tags.Planted) then
		return nil
	end
	--==========================================================================
	-- THE PROMPT IS NOT IN THE MODEL ANY MORE
	--
	-- It hangs off a server-owned anchor that follows the plant's authoritative
	-- wander position (see PlantService), kept in plot/Runtime/PickupAnchors and
	-- named by placement id. Looked up in MY plot only, so ownership stays
	-- structural: a neighbour's plant never resolves a prompt here.
	--==========================================================================
	local id = model:GetAttribute("PlacementId")
	local plot = myPlot()
	local runtime = if plot then plot:FindFirstChild(GameConfig.Plot.RuntimeFolderName) else nil
	local anchors = if runtime
		then runtime:FindFirstChild(GameConfig.Plot.PickupAnchorsFolderName)
		else nil
	local anchor = if anchors and type(id) == "number"
		then anchors:FindFirstChild(tostring(id))
		else nil
	local prompt = if anchor then anchor:FindFirstChild(PICKUP_PROMPT) else nil
	if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
		return prompt
	end
	return nil
end

local function myPlantsFolder(): Instance?
	local plot = myPlot()
	return if plot then plot:FindFirstChild(GameConfig.Plot.PlantsFolderName) else nil
end

--==============================================================================
-- RAY VERSUS THE PLANT'S REAL BOX
--
-- WHY NOT Workspace:Raycast, which would be the obvious way. Every creature part
-- in this game is CanQuery = false, and that is not an oversight -- it is
-- invariant 1, and CombatService leans on it: "a wall stops a bat, a pod does
-- not". A raycast finds only genuinely solid things, which is exactly the set
-- that should block a swing. Turning plant parts queryable to make them
-- tappable would start blocking bat swings on the far side of a garden, so the
-- ray tests the model's own bounding box instead and the invariant is untouched.
--
-- This is a real ray against real geometry, not an estimated screen rectangle --
-- the mistake 526a049 exists to correct. Measured on a live plant whose box is
-- 2.4 x 4.2 x 2.0: dead centre hits at 72.9 studs, one stud off hits, two studs
-- off misses. A box is coarser than thirty-six leaves, and for a step whose only
-- consequence is an outline that is the right trade.
--
-- Slab method, in the box's own space, so a plant turned to face down its plot
-- is tested as the box it actually is rather than an axis-aligned guess.
--==============================================================================
local function rayHitsBox(origin: Vector3, dir: Vector3, boxCF: CFrame,
	size: Vector3): number?
	local o = boxCF:PointToObjectSpace(origin)
	local d = boxCF:VectorToObjectSpace(dir)
	local half = size * 0.5
	local tmin, tmax = -math.huge, math.huge
	for _, axis in ipairs({ "X", "Y", "Z" }) do
		local oi = (o :: any)[axis] :: number
		local di = (d :: any)[axis] :: number
		local hi = (half :: any)[axis] :: number
		if math.abs(di) < 1e-7 then
			-- Parallel to this pair of faces: either inside them forever or
			-- outside them forever.
			if oi < -hi or oi > hi then
				return nil
			end
		else
			local t1, t2 = (-hi - oi) / di, (hi - oi) / di
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			tmin = math.max(tmin, t1)
			tmax = math.min(tmax, t2)
			if tmin > tmax then
				return nil
			end
		end
	end
	if tmax < 0 then
		return nil
	end
	return math.max(tmin, 0)
end

--==============================================================================
-- WHICH PLANT IS UNDER THAT POINT
--
-- THE COORDINATE SPACE, MEASURED, because getting this wrong by one GUI inset is
-- the exact bug 526a049 was about and it would be silent here too -- taps would
-- land on whatever is 58 pixels above the plant.
--
--     InputObject.Position   below-inset   <- what a touch reports
--     GetMouseLocation()     window        <- 58 higher, measured, same tap
--     ScreenPointToRay       below-inset   <- round-trips to 0.0000 studs
--     ViewportPointToRay     window        <- round-trips to 0.0000 studs
--
-- The wrong pairing missed a point 12.5 studs away by 2.41 studs. So there is no
-- arithmetic here at all: the touch arrives below-inset and goes straight into
-- ScreenPointToRay, which wants below-inset. Nothing to add, nothing to get
-- wrong, no constant to drift. (PlantPlace pairs GetMouseLocation with
-- ViewportPointToRay, which is the OTHER matching pair and equally correct --
-- only the wording of its comment is inverted.)
--
-- SOLID GEOMETRY STILL WINS. One ordinary raycast for the walls and the ground,
-- and a plant farther away than that is behind something -- so you cannot tap a
-- plant through your own fence.
--==============================================================================
local function plantUnder(at: Vector2): (Model?, ProximityPrompt?)
	local camera = Workspace.CurrentCamera
	local plants = myPlantsFolder()
	if not (camera and plants) then
		return nil, nil
	end
	local ray = camera:ScreenPointToRay(at.X, at.Y)
	local origin, dir = ray.Origin, ray.Direction.Unit

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character
		then { player.Character }
		else {}
	local solid = Workspace:Raycast(origin, dir * 600, params)
	local reach = if solid then (solid.Position - origin).Magnitude else 600

	local bestModel: Model? = nil
	local bestPrompt: ProximityPrompt? = nil
	local bestAt = math.huge
	for _, child in ipairs(plants:GetChildren()) do
		local prompt = promptFor(child)
		-- AND CLOSE ENOUGH TO ACTUALLY TAKE IT. Without this a plant across the
		-- bed selects, shows a button, and then un-selects a third of a second
		-- later when the range watcher catches up -- which reads as the tap
		-- being flaky rather than as the plant being too far away. Eligibility
		-- is asked once, here, and answered the same way the watcher answers it.
		if prompt and inRange(prompt) then
			local model = child :: Model
			local boxCF, boxSize = model:GetBoundingBox()
			local t = rayHitsBox(origin, dir, boxCF, boxSize)
			if t and t <= reach and t < bestAt then
				bestAt = t
				bestModel = model
				bestPrompt = prompt
			end
		end
	end
	return bestModel, bestPrompt
end

--==============================================================================
-- LETTING GO
--
-- Every route out of a selection funnels here, and there are a dozen of them --
-- the plant leaving, the player leaving, a panel opening, a pod landing in both
-- arms, the jaws closing, a death. Anything that leaves a highlight on a plant
-- nobody is looking at, or a button that would press a prompt that has gone, is
-- this function not having been called.
--==============================================================================
local function clearSelection()
	generation += 1
	for _, c in ipairs(watching) do
		c:Disconnect()
	end
	table.clear(watching)
	selected = nil
	local made = highlight
	if made then
		made.Parent = nil
	end
	layer.Enabled = false
	caption.Text = ""
end

local function select(model: Model, prompt: ProximityPrompt)
	clearSelection()
	local name = model:GetAttribute("SpeciesName")
	local shown = if type(name) == "string" and name ~= ""
		then name
		-- CreatureModel names the model "Creature_<species>"; the tail is the
		-- compact name a button has room for.
		else (model.Name:match("^Creature_(.+)$") or model.Name)
	selected = { model = model, prompt = prompt, label = shown }

	local made = theHighlight()
	made.Parent = model

	caption.Text = string.upper(shown)
	layer.Enabled = true
	SoundKit.play("CardClick")

	--==========================================================================
	-- AND THE SELECTION WATCHES ITS OWN SUBJECT
	--
	-- The model going away covers being picked up, sold, hatched over, replaced
	-- by a render() rebuild, or the plot being handed to somebody else -- one
	-- signal for every way a plant can stop being the plant that was tapped,
	-- rather than a list of them.
	--==========================================================================
	table.insert(watching, model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			clearSelection()
		end
	end))
	table.insert(watching, prompt.AncestryChanged:Connect(function(_, parent)
		if not parent then
			clearSelection()
		end
	end))
	table.insert(watching, prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		if not prompt.Enabled then
			clearSelection()
		end
	end))

	-- See RANGE_POLL: the belt to PromptHidden's braces, alive only as long as
	-- this selection is the current one.
	local mine = generation
	task.spawn(function()
		while mine == generation do
			task.wait(RANGE_POLL)
			if mine ~= generation then
				return
			end
			if not (prompt.Parent and prompt.Enabled and inRange(prompt)) then
				clearSelection()
				return
			end
		end
	end)
end

--==============================================================================
-- THE PROMPT CANNOT BE PRESSED, AND THAT IS NOT THIS FILE'S FAULT
--
-- The intended design was `prompt:InputHoldBegin()` / `InputHoldEnd()` -- the
-- prompt's own supported lifecycle, the identical path desktop's E takes, and the
-- pair PromptUI already uses successfully for the nest Take, Marigold and the
-- sell board. It does not work on a grown plant, and the measurements say why:
--
--     the client draws the plant   7.5 studs from the character
--     the SERVER has its Base     63.0 studs from the character  (max 26)
--
-- A GROWN PLANT IS ANIMATED BY THE CLIENT. PlantService publishes a wander leg as
-- four attributes and every client walks the model along it; the server never
-- moves the parts at all -- measured, `Base` identical for five seconds while
-- `WanderTo` pointed 65 studs away. That is a deliberate design (it is why the
-- wander costs no per-frame replication) and it is invisible until something
-- needs the two copies to agree about where the plant IS.
--
-- A ProximityPrompt needs exactly that. The client shows it, using the position
-- the client drew; the server validates the trigger, using the position the
-- server kept. Once a plant has walked, no standing position satisfies both --
-- two 26-stud spheres 63 studs apart do not overlap -- so the trigger is refused
-- in silence. Verified from both ends: the server's own PromptTriggered never
-- fired, from a button, from a bare script call, and while standing at the
-- server's copy.
--
-- THIS BREAKS DESKTOP E TOO, on any plant that has wandered off its planted spot,
-- and it did so before this file existed. It is recorded in HANDOFF as its own
-- defect because fixing it means changing how the wander replicates, which is a
-- PlantService decision and not a mobile-UI one.
--
--==============================================================================
-- SO IT ASKS THE SERVER, WITH THE VERB THAT ALREADY EXISTS
--
-- `PickUpAction` -> `PlantService.PickUpById`, which the Garden panel has used
-- since it was written. Nothing new is added: no remote, no handler, no second
-- ownership list, no widening of what a client may ask for.
--
-- WHAT THE SERVER CHECKS, none of it here: the payload must be a finite whole
-- positive number; the lookup happens in the CALLER'S OWN PLOT and nowhere else,
-- so a neighbour's placement id simply is not in the table; and `pickUp` then
-- re-tests ownership, that the entry is still the live one, that it is grown, and
-- that the bag accepted the handover. A forged or stale id finds nothing and
-- returns false.
--
-- DOUBLE PRESSES CANNOT DOUBLE UP. The debounce stops a second ask leaving, and
-- the server drops the entry from `growing` on the first one, so a second ask
-- finds nothing to give even if it arrives.
--==============================================================================
local function press()
	local current = selected
	if not current then
		return
	end
	local now = os.clock()
	if now - pressedAt < PRESS_DEBOUNCE then
		return
	end
	pressedAt = now
	local id = current.model:GetAttribute("PlacementId")
	if type(id) ~= "number" then
		clearSelection()
		return
	end
	SoundKit.play("UIClick")
	channel:FireServer(PLANTING.PickUpAction, id)
	--==========================================================================
	-- CLEARED ON THE WAY OUT, NOT ON THE WAY BACK
	--
	-- A successful pickup destroys the model, which clears this through the
	-- watcher above. A REFUSED one does not -- a full bag, a plot handed over
	-- mid-reach -- and leaving the button up after a refusal invites the player to
	-- jab at it. Either way the selection has been spent, so it goes.
	--==========================================================================
	clearSelection()
end

button.Activated:Connect(press)

--==============================================================================
-- THE TAP, DECIDED ON RELEASE
--
-- ON RELEASE, and that is the entire point of this file. Nothing about a touch
-- that has just landed tells you whether it is a tap or the beginning of a camera
-- swing -- so nothing is decided until the finger lifts and the question can be
-- answered honestly.
--
-- `processed` at BEGIN is what keeps the thumbstick, the jump button, the
-- hotbar, the rail and every open panel out of this: the engine has already
-- given that touch to a GUI, and a touch spoken for is not aimed at the world.
-- Checked at begin rather than at end because that is where the answer is true --
-- a finger that starts on the thumbstick and slides off it is still driving.
--
-- ONE FINGER. A second touch landing while one is pending abandons the pending
-- one: two fingers on the glass is a pinch or a camera, never a tap on a plant.
--==============================================================================
type Pending = {
	input: InputObject,
	at: Vector2,
	began: number,
}

local pending: Pending? = nil

if TOUCH then
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if pending then
			-- A second finger. Whatever this gesture is, it is not a tap.
			pending = nil
			return
		end
		if processed or holdingAPlant() then
			return
		end
		pending = {
			input = input,
			at = Vector2.new(input.Position.X, input.Position.Y),
			began = os.clock(),
		}
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		local waiting = pending
		if not waiting or input ~= waiting.input then
			return
		end
		pending = nil
		local at = Vector2.new(input.Position.X, input.Position.Y)
		if (at - waiting.at).Magnitude > TAP_SLOP then
			return
		end
		if os.clock() - waiting.began > TAP_SECONDS then
			return
		end
		-- Asked again at release: a plant Tool equipped mid-gesture, or a pod
		-- picked up, and this tap is no longer about selecting anything.
		if holdingAPlant() or player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
			clearSelection()
			return
		end
		--======================================================================
		-- AIMED FROM WHERE THE FINGER LANDED
		--
		-- The origin, not the release point. They are within TAP_SLOP of each
		-- other by now so it barely matters, but the origin is what the player
		-- was pointing at when they committed -- the release is just where their
		-- thumb happened to stop.
		--======================================================================
		local model, prompt = plantUnder(waiting.at)
		if model and prompt then
			local current = selected
			if current and current.model == model then
				-- Tapping the selected plant again is not a second selection and
				-- is deliberately NOT a pickup: the button is the only thing that
				-- picks up, which is the whole contract.
				return
			end
			select(model, prompt)
		else
			-- Empty ground, a fence, somebody else's plant, or a plant with no
			-- prompt. All the same answer.
			clearSelection()
		end
	end)
end

--==============================================================================
-- AND EVERYTHING THAT ENDS A SELECTION WITHOUT A TAP
--
-- Connected once, for the session. Each of these takes the player out of the
-- moment entirely, and none of them is a touch event, so without them the
-- outline and the button would simply stay:
--
--   out of range      PromptHidden -- the engine already decides this, at the
--                     prompt's own MaxActivationDistance, so there is no
--                     distance loop here and no second copy of the number
--   carrying a pod    both arms are full and the bed is not the subject
--   a panel opened    the bag, the shop, the index
--   trapped           held still and being hit
--   ragdolled         thrown; ThrowFX drives it through the Humanoid, there is
--                     no attribute for it
--   died, respawned   the character and everything hanging off it
--   placing a plant   a Tool with a SpeciesId reached the hands
--   touch went away   the layout is a desktop now and this affordance is not
--                     wanted; PromptUI's panel comes back in the same breath
--==============================================================================
--==============================================================================
-- OUT OF RANGE, AND ONLY ACTUALLY OUT OF RANGE
--
-- MEASURED, and it cost a confusing hour: this used to clear on any PromptHidden
-- for the selected prompt, which read as "the engine says you cannot reach it any
-- more". It is not what PromptHidden means. The engine hides and re-shows a
-- prompt for reasons that have nothing to do with the player -- a grown plant
-- WANDERS its bed, and the pair
--
--     PromptHidden(PickupPrompt)
--     PromptShown(PickupPrompt)
--
-- arrived back to back while standing still 8.4 studs from a plant whose range is
-- 26. Every one of those took the selection and the button away, so a tap
-- selected the plant and then silently un-selected it a moment later -- which
-- looked exactly like the tap never working at all.
--
-- So a hide is a reason to ASK, and the question is the one the requirement
-- actually states: is the player outside pickup range. If they are still standing
-- next to it, the selection stands.
--==============================================================================
ProximityPromptService.PromptHidden:Connect(function(prompt)
	local current = selected
	if not (current and current.prompt == prompt) then
		return
	end
	if not (prompt.Parent and prompt.Enabled and inRange(prompt)) then
		clearSelection()
	end
end)

player:GetAttributeChangedSignal(ATTR.CarryingSpecies):Connect(function()
	if player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
		clearSelection()
	end
end)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if player:GetAttribute(ATTR.OpenPanel) ~= nil then
		clearSelection()
	end
end)
player:GetAttributeChangedSignal(ATTR.Trapped):Connect(clearSelection)

UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
	if not UserInputService.TouchEnabled then
		clearSelection()
	end
end)

local humanoidConn: RBXScriptConnection? = nil
local toolConn: RBXScriptConnection? = nil

local function watchCharacter(character: Model)
	clearSelection()
	if humanoidConn then
		humanoidConn:Disconnect()
		humanoidConn = nil
	end
	if toolConn then
		toolConn:Disconnect()
		toolConn = nil
	end
	toolConn = character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and type(child:GetAttribute("SpeciesId")) == "string" then
			clearSelection()
		end
	end)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoidConn = humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Physics
			or new == Enum.HumanoidStateType.FallingDown
			or new == Enum.HumanoidStateType.Dead then
			clearSelection()
		end
	end)
end

if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)
player.CharacterRemoving:Connect(clearSelection)

--==============================================================================
-- NOTHING IS SHOWN UNTIL SOMETHING IS SELECTED
--==============================================================================
clearSelection()
