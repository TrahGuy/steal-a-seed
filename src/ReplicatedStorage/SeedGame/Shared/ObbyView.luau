--!strict
--==============================================================================
-- Steal a Seed :: ObbyView
--
-- WHERE A RUNNER LOOKS WHEN THE COURSE PUTS THEM DOWN (2026-09-29)
--
-- The owner's report, from a phone: "After I fall and return to an obby
-- checkpoint, the camera faces the opposite direction, so I accidentally move
-- backward."
--
-- MEASURED the same day in Studio's phone emulation (705 x 338, touch). The
-- body was never wrong: ObbyService puts it down facing the respawn's own
-- direction, and every respawn faces its next obstacle. The camera was. A
-- phone's default camera (Follow) turns to look along the way its subject has
-- just travelled, and a fall's way back is BACKWARD -- from under the leaf that
-- was missed to the checkpoint behind it. One frame after the body landed the
-- camera looked back down the course (yaw 93 before the fall, -90 after it, the
-- body at 90 throughout). The stick is read against the camera, so "forward"
-- walked the runner back off the island.
--
--==============================================================================
-- WHAT TURNS IT, MEASURED (the camera is the engine's own script now; there is
-- nothing in PlayerScripts to read or reach into)
--
--   one CFrame write, Follow camera    undone inside the same frame
--   the touch camera mode, switched    refused: a LocalScript may not set it
--   the camera TAKEN for a frame or    kept. Handed back, the camera carries
--   two, then handed back              on from exactly where it was left.
--
-- So on a camera that follows, the camera is taken (CameraType Scriptable) for
-- HoldFrames frames, held behind the body looking the way the body faces, and
-- handed back. On a camera that does not follow -- a desktop's default -- it is
-- only WRITTEN, which that camera keeps: nothing is taken, so a player's mouse
-- lock never notices. A write that did not hold is taken once instead.
--
-- ONCE, AND THEN IT IS THE PLAYER'S. Nothing here runs between placements: no
-- lock, no pull back toward the route, nothing that reads the player's own
-- turning of the camera afterwards. The zoom is the player's and is kept; so is
-- the pitch, inside a band that can see the next leaf.
--
--==============================================================================
-- PURE, LIKE HudLayout
--
-- Numbers and a small state machine. ObbyCamera (the LocalScript) owns the
-- camera and the events, and feeds this the clock, the body's position and the
-- camera's zoom and look; ObbyViewSpec drives every branch without Play.
--==============================================================================

local ObbyData = require(script.Parent:WaitForChild("ObbyData"))

local ObbyView = {}

-- How far over a respawn's floor ObbyService puts the body (its respawnFrame),
-- and how far behind the arch its entranceFrame stands a player.
ObbyView.RootRise = 3.5
ObbyView.EntranceBack = 6
-- The engine's camera looks at a point this far over a character's root
-- (measured: focus 34.5 for a root at 33.0).
ObbyView.FocusRise = 1.5
-- Within this of the landing, the body has been put down there. A fall is only
-- called 26 studs under the checkpoint's floor, so a falling body is never this
-- near by accident.
ObbyView.ArriveStuds = 6
-- A body that moved this far in one frame was carried, not walked or thrown:
-- the course's fastest throw is under 100 studs a second, 7 studs in a frame
-- at 15 frames a second.
ObbyView.JumpStuds = 12
-- How long a placement is waited for: the server streams the landing in first
-- (RequestStreamAroundAsync, 2 s at most) and then moves the body.
ObbyView.WaitSeconds = 4
ObbyView.EntranceWaitSeconds = 3
-- How many frames the camera is held. One was enough in every measurement.
ObbyView.HoldFrames = 2
-- A write is believed when the camera still looks within this of it a frame on.
ObbyView.HeldWithinDegrees = 30
-- What was only SAID to be a placement is not answered again for a landing the
-- camera was turned to within this (ObbyView.arm).
ObbyView.SameLandingSeconds = 1
-- The look keeps the player's own pitch, between these (degrees; down is
-- negative): level enough to see the next leaf, steep enough to see the feet.
ObbyView.PitchLow = -40
ObbyView.PitchHigh = -8
ObbyView.PitchDefault = -15

local function facingOf(degrees: number): Vector3
	return CFrame.Angles(0, math.rad(degrees), 0).LookVector
end

--==============================================================================
-- THE PLACES THE COURSE PUTS A BODY, AND WHICH WAY EACH FACES
--
-- ObbyService's own arithmetic (respawnFrame, entranceFrame), from ObbyData's
-- own numbers: the landing is where the body's root is put, the forward the way
-- it is turned. ObbyViewSpec holds both to the server's source, and every
-- forward to the obstacle that comes next.
--==============================================================================
function ObbyView.landing(key: string): Vector3?
	local spot = ObbyData.Respawns[key]
	if not spot then
		return nil
	end
	return ObbyData.world(spot.at) + Vector3.new(0, ObbyView.RootRise, 0)
end

function ObbyView.forward(key: string): Vector3?
	local spot = ObbyData.Respawns[key]
	if not spot then
		return nil
	end
	return facingOf(spot.facing)
end

-- In front of the arch, facing it: where the OBBY button lands.
function ObbyView.entrance(): (Vector3, Vector3)
	local E = ObbyData.Entrance
	local frame = CFrame.new(E.At) * CFrame.Angles(0, math.rad(E.FacingDegrees), 0)
		* CFrame.new(0, ObbyView.RootRise, ObbyView.EntranceBack)
	return frame.Position, frame.LookVector
end

-- The first thing to stand on after each respawn, in world space: what its
-- facing is held to (ObbyViewSpec). nil for a respawn nobody named.
function ObbyView.nextObstacle(key: string): Vector3?
	local function first(stageId: string): Vector3?
		local stage = ObbyData.stage(stageId)
		if not stage then
			return nil
		end
		local nearest: Vector3? = nil
		local from = ObbyView.landing(key)
		-- By name: a stage has only some of these, and a list with a gap in it
		-- would stop at the gap.
		for _, kind in ipairs({ "pads", "movers", "spinners", "crumbles", "launches" }) do
			for _, piece in ipairs((stage :: any)[kind] or {}) do
				local at = ObbyData.world(piece.at)
				if from and (nearest == nil or (at - from).Magnitude < ((nearest :: Vector3) - from).Magnitude) then
					nearest = at
				end
			end
		end
		return nearest
	end
	if key == "start" then
		return first("sunpetal")
	elseif key == "cp1" then
		return first("rootgrove")
	elseif key == "cp2" then
		return first("autumn")
	elseif key == "finished" then
		return ObbyData.world(ObbyData.Finish.at)
	end
	return nil
end

--==============================================================================
-- PUT DOWN, THIS FRAME?
--
-- The respawn a body has just been carried onto: it moved JumpStuds or more
-- since the last frame and now stands within ArriveStuds of that landing. nil
-- otherwise -- a body walking, jumping, thrown by a spring or still falling.
--
-- WHY THE POSITION AND NOT ONLY THE ATTRIBUTES. Measured in Play 2026-09-29: a
-- fall's ObbyFalls and the body's new position reach the client together, and
-- the attribute's signal runs after that frame's camera step -- so a camera
-- turned on the attribute alone was turned one frame late, and the wrong way
-- was drawn for that frame. The body's own position is there for the asking,
-- on the frame the engine's camera would have turned.
--==============================================================================
function ObbyView.placed(before: Vector3?, now: Vector3): string?
	if not before or (now - before).Magnitude < ObbyView.JumpStuds then
		return nil
	end
	for key in pairs(ObbyData.Respawns) do
		local at = ObbyView.landing(key)
		if at and (now - at).Magnitude <= ObbyView.ArriveStuds then
			return key
		end
	end
	return nil
end

--==============================================================================
-- DOES THIS CAMERA TURN BY ITSELF?
--
-- The engine's own rule, from the four settings it reads, as their names: on a
-- touch screen the touch pair, elsewhere the computer pair; the developer's
-- choice unless it is UserChoice; and "Default" is Follow on touch, Classic on
-- a computer. Only a camera that follows needs taking.
--==============================================================================
function ObbyView.follows(touch: boolean, devTouch: string, userTouch: string,
	devComputer: string, userComputer: string): boolean
	if touch then
		if devTouch ~= "UserChoice" then
			return devTouch == "Follow"
		end
		return userTouch == "Default" or userTouch == "Follow"
	end
	if devComputer ~= "UserChoice" then
		return devComputer == "Follow"
	end
	return userComputer == "Follow"
end

--==============================================================================
-- THE CAMERA, BEHIND THE BODY
--==============================================================================
function ObbyView.pitchOf(look: Vector3?): number
	if not look or look ~= look or look.Magnitude < 1e-3 then
		return ObbyView.PitchDefault
	end
	local pitch = math.deg(math.asin(math.clamp(look.Unit.Y, -1, 1)))
	if pitch ~= pitch then
		return ObbyView.PitchDefault
	end
	return math.clamp(pitch, ObbyView.PitchLow, ObbyView.PitchHigh)
end

-- `zoom` behind the point the engine's camera looks at on this body, looking
-- the way `forward` runs across the ground, at the pitch of `look`.
function ObbyView.cameraAt(bodyAt: Vector3, forward: Vector3, zoom: number, look: Vector3?): CFrame
	local flat = Vector3.new(forward.X, 0, forward.Z)
	if flat ~= flat or flat.Magnitude < 1e-3 then
		flat = Vector3.xAxis
	end
	flat = flat.Unit
	local pitch = math.rad(ObbyView.pitchOf(look))
	local direction = flat * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
	local distance = if zoom == zoom then math.clamp(zoom, 0.5, 400) else 12.5
	local focus = bodyAt + Vector3.new(0, ObbyView.FocusRise, 0)
	return CFrame.lookAt(focus - direction * distance, focus)
end

-- How far apart two looks are across the ground, in degrees.
function ObbyView.yawBetween(a: Vector3, b: Vector3): number
	local fa = Vector3.new(a.X, 0, a.Z)
	local fb = Vector3.new(b.X, 0, b.Z)
	if fa.Magnitude < 1e-3 or fb.Magnitude < 1e-3 then
		return 0
	end
	return math.deg(math.acos(math.clamp(fa.Unit:Dot(fb.Unit), -1, 1)))
end

--==============================================================================
-- ONE PLACEMENT, START TO END
--
--   idle      nothing to do; ObbyCamera runs nothing at all
--   waiting   the server has said it is putting the runner down; the body has
--             not arrived. Given up after `seconds`.
--   holding   the body is down: the camera is turned, for HoldFrames frames --
--             TAKEN on a camera that follows, only written on one that does not
--   checking  one frame after a write: did it hold? If the camera looks
--             somewhere else, it is taken once (holding again); if it held, or
--             was taken to begin with, idle.
--
-- `step` answers each frame with the CFrame to put the camera at, and whether
-- the camera has to be in our hands for it (taken) -- or nil: not ours.
--==============================================================================
export type Watch = {
	state: string,
	target: Vector3?,
	forward: Vector3?,
	deadline: number,
	framesLeft: number,
	-- Taken, or only written.
	taken: boolean,
	-- The zoom and the look the camera had when the body arrived.
	zoom: number,
	look: Vector3?,
	-- Whether a write has already been followed by a take, this placement.
	retried: boolean,
	-- The landing the camera was last turned to, and when.
	turnedTo: Vector3?,
	turnedAt: number,
	-- How many times it has turned a camera, for harnesses and the spec.
	turns: number,
}

function ObbyView.new(): Watch
	return {
		state = "idle",
		target = nil,
		forward = nil,
		deadline = 0,
		framesLeft = 0,
		taken = false,
		zoom = 12.5,
		look = nil,
		retried = false,
		turnedTo = nil,
		turnedAt = -math.huge,
		turns = 0,
	}
end

function ObbyView.active(watch: Watch): boolean
	return watch.state ~= "idle"
end

function ObbyView.stop(watch: Watch)
	watch.state = "idle"
	watch.target = nil
	watch.forward = nil
	watch.framesLeft = 0
end

-- The course is putting the runner down at `target`, facing `forward`.
--
-- `seen` is true when the body itself was seen being put there (ObbyView.placed)
-- and false or nil when something only SAID it would be (an attribute, the OBBY
-- button's press). What was only said is not started again for a landing the
-- camera was turned to a moment ago: a fall's count arrives with the body or
-- after it, and the fall it is about has then already been answered. A body
-- seen landing is always a placement -- the next fall is at least a second
-- behind the last, the time it takes to walk off an island and drop 26 studs.
function ObbyView.arm(watch: Watch, target: Vector3?, forward: Vector3?, now: number, seconds: number?,
	seen: boolean?)
	if not (target and forward) then
		return
	end
	if not seen then
		local last = watch.turnedTo
		if last and (last - target).Magnitude < 0.5 and now - watch.turnedAt < ObbyView.SameLandingSeconds then
			return
		end
	end
	watch.state = "waiting"
	watch.target = target
	watch.forward = forward
	watch.deadline = now + (seconds or ObbyView.WaitSeconds)
	watch.framesLeft = 0
	watch.retried = false
end

-- One frame. `bodyAt` is the root's position (nil with no living body), `free`
-- whether the camera is the engine's to move this frame and so ours to turn,
-- `follows` whether it turns by itself (ObbyView.follows), `zoom` and `look` the
-- camera's as it stands.
function ObbyView.step(watch: Watch, now: number, bodyAt: Vector3?, free: boolean, follows: boolean,
	zoom: number, look: Vector3?): (CFrame?, boolean)
	local target, forward = watch.target, watch.forward
	if watch.state == "idle" or not (target and forward) then
		watch.state = "idle"
		return nil, false
	end
	if not bodyAt then
		-- No body to stand behind: a death, or the body being replaced.
		ObbyView.stop(watch)
		return nil, false
	end

	if watch.state == "waiting" then
		if now > watch.deadline then
			ObbyView.stop(watch)
			return nil, false
		end
		if (bodyAt - target).Magnitude > ObbyView.ArriveStuds then
			return nil, false
		end
		-- Down. A camera that is somebody else's this frame -- a cutscene, a
		-- ragdoll's follow part, a headset -- is left alone, and the turn is
		-- given up rather than made late.
		if not free then
			ObbyView.stop(watch)
			return nil, false
		end
		watch.state = "holding"
		watch.framesLeft = ObbyView.HoldFrames
		watch.taken = follows
		watch.zoom = zoom
		watch.look = look
		watch.turnedTo = target
		watch.turnedAt = now
		watch.turns += 1
	end

	if watch.state == "checking" then
		local goal = ObbyView.cameraAt(bodyAt, forward, watch.zoom, watch.look)
		local held = look ~= nil and ObbyView.yawBetween(look, goal.LookVector) <= ObbyView.HeldWithinDegrees
		if held or watch.retried or not free then
			ObbyView.stop(watch)
			return nil, false
		end
		-- The write did not hold: this camera follows after all. Taken, once.
		watch.retried = true
		watch.state = "holding"
		watch.framesLeft = ObbyView.HoldFrames
		watch.taken = true
		watch.turns += 1
	end

	if watch.state == "holding" then
		if watch.framesLeft <= 0 then
			if watch.taken then
				ObbyView.stop(watch)
			else
				watch.state = "checking"
			end
			return nil, false
		end
		watch.framesLeft -= 1
		return ObbyView.cameraAt(bodyAt, forward, watch.zoom, watch.look), watch.taken
	end

	return nil, false
end

return ObbyView
