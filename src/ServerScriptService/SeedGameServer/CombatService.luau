--!strict
--==============================================================================
-- Steal a Seed :: CombatService
--
-- What Marigold's stock DOES. Swings, hits, knockback, and the Bramblejaw.
--
-- WeaponShopService owns who has what; this file never writes ownership and
-- never touches cash. It asks one question -- "what is in this player's hands
-- right now" -- and everything else it decides for itself.
--
--==============================================================================
-- KNOCKBACK ONLY. NOTHING IN THIS FILE READS OR WRITES HEALTH.
--
-- A hit costs you your footing and your racing line, and in a game whose whole
-- tension is the distance between a nest and the red line, that IS the damage.
-- It is also the only version of PvP that a five-biome ladder can survive: a
-- player who can kill would make the corridor impassable for everybody below
-- them, and the corridor is the game.
--
--==============================================================================
-- A HIT KNOCKS THE POD OUT OF THEIR HANDS
--
-- This file used to say the opposite -- that a bat never touched a carry and
-- the ragdoll's PlatformStand watcher would incidentally drop it. That was
-- wrong twice over. It made the single most valuable thing on the road immune
-- to the only PvP verb in the game; and it was not even reliable, because the
-- PlatformStand that fires the watcher is written by the VICTIM'S client, so
-- whether it reached the server at all was a race.
--
-- The drop is explicit now, it happens BEFORE the launch, and it goes through
-- `CarryService.Drop` -- the same canonical path a guardian's throw and a
-- player's own Drop button use. There is no second pod ownership system here:
-- this file does not know what a pod is beyond calling that one function.
--
-- BEFORE the launch matters for two reasons. The pod lands at the victim's
-- feet where they were standing, rather than being carried along by a body
-- travelling at eighty studs a second; and a pod welded to a ragdolling head
-- is a pod being flung, which is exactly what the brief forbids.
--
-- It still never GIVES the pod to anybody. It goes on the ground, loose, with
-- its species, tier and origin nest intact, and whoever gets there first takes
-- it through the ordinary prompt.
--
--==============================================================================
-- THE SERVER DECIDES EVERY PART OF A HIT
--
-- The client's entire contribution is `Tool.Activated`, which is the engine
-- telling us a button was pressed on a Tool the engine says is equipped. It
-- carries no target, no direction, no timing and no damage. This file reads the
-- weapon off the Tool, the cooldown off its own clock, the arc off the
-- character's replicated CFrame, and the launch out of WeaponData.
--
-- What clients do is draw it: WeaponFX animates the arm and the impact off two
-- attributes stamped here, and ThrowFX applies the impulse to the body it owns
-- because a player's character is simulated by that player and there is no way
-- round that worth having (see the banner in NestService).
--
--==============================================================================
-- SAFE IS SAFE, FOR BOTH ENDS OF A SWING
--
-- MapService.IsInSafeZone is the whole field -- the hub, the stall, every plot
-- and every spawn -- and both the swinger and the target are tested against it.
-- Testing only the victim would let somebody stand on the safe side of the red
-- line and reach across it, which is the same promise being broken from the
-- other direction.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local WeaponShopService = require(script.Parent:WaitForChild("WeaponShopService"))

local CombatService = {}

--==============================================================================
-- A RUN ON THE FLOATING GARDEN IS NOBODY'S TARGET
--
-- The course floats outside the Safe Zone, so the field's test says nothing
-- about it; this is the course's own. A player ObbyService has put on the
-- course can neither be struck nor strike, and cannot set a trap there --
-- "no PvP during an authorized run", from both ends, like the field.
--==============================================================================
local function onCourse(player: Player): boolean
	return player:GetAttribute(ObbyData.Attributes.Course) == true
end

-- After WeaponShopService (62), which hands out the Tools this reacts to, and
-- after CarryService (45) and NestService (40), whose speed and ragdoll it uses.
CombatService.Priority = 70

local C = WeaponData.Combat
local T = WeaponData.Trap
local ATTR = GameConfig.Attributes
local W = GameConfig.Weapon

--==============================================================================
-- ATTRIBUTES THE CLIENTS DRAW FROM
--
-- Stamped on the TOOL, not on the player, because a swing belongs to the weapon
-- and a Tool replicates to everybody who can see the character holding it --
-- which is exactly the set of people who should see the swing. Same split as
-- the guardian's AttackSwipe, which ParentAnim animates off.
--==============================================================================
local SWING_AT = "SwingAt"
local SWING_WINDUP = "SwingWindup"
local SWING_RECOVER = "SwingRecover"
local HIT_AT = "HitAt"
--==============================================================================
-- WHEN THIS TOOL IS NEXT USABLE, IN SERVER TIME
--
-- Stamped so the hotbar can draw a cooldown without being told one and without
-- computing one. The client already knows the weapon's cooldown from
-- WeaponData, but it does not know when the SERVER started counting -- and a
-- client that guessed would show a bat as ready a frame before it is, which is
-- the one thing a cooldown readout must never do.
--
-- Read-only presentation. Nothing on this side ever reads it back.
--==============================================================================
local READY_AT = "ReadyAt"

local serviceConnections: { RBXScriptConnection } = {}
local toolConnections: { [Tool]: RBXScriptConnection } = {}
local heartbeat: RBXScriptConnection? = nil
local channel: RemoteEvent? = nil
local throwRemote: RemoteEvent? = nil

-- Per player, all keyed off os.clock().
local swingReadyAt: { [Player]: number } = {}
--==============================================================================
-- ONE SWING TRACK PER BODY, LOADED ONCE (2026-10-04)
--
-- This loaded a NEW AnimationTrack and connected a NEW Stopped handler on every
-- single swing, and neither was ever let go: an Animator keeps every track it
-- has loaded, and complains past 256 of them. Now each body loads the swing
-- once, plays that same track on every swing, and the entry is dropped when the
-- body or the asset changes. No per-swing connection exists any more.
--==============================================================================
type SwingTrack = { animator: Animator, track: AnimationTrack, id: string }
local swingTracks: { [Player]: SwingTrack } = {}
-- One Animation instance per asset id, shared by every player.
local animationCache: { [string]: Animation } = {}
local immuneUntil: { [Player]: number } = {}
--==============================================================================
-- NO PLACEMENT COOLDOWN (2026-10-04, the reusable-trap brief)
--
-- There was one per trap type; it went with the traps' lifetime. An owner sets
-- their three as fast as the placement rules allow -- floor, slope, the Safe
-- Zone, the clearances and the separation -- and the three-trap limit is the
-- whole budget. What stops one owner holding one victim is the victim's
-- immunity (asserted in WeaponData), never a recharge.
--
-- The one clock kept per player here is REMOVE's request gap: protection
-- against a flood of requests, not a recharge (WeaponData.Trap.RemoveGapSeconds).
--==============================================================================
local removeReadyAt: { [Player]: number } = {}
--==============================================================================
-- WHO IS MID-KNOCKBACK, AND WHICH LAUNCH IT IS
--
-- This was `flying[player] = true` and an acknowledgement that carried nothing:
-- any "I have stopped" from that player cleared whatever launch happened to be
-- current. Two things went wrong with that, and the first one happened on
-- every single hit.
--
-- A STALE ANSWER RELEASED A NEWER LAUNCH. The client could not report inside
-- the old 1.1s deadline -- it needed about 1.55s -- so the server timed out,
-- restored the rig, and the client went on running. Its eventual report then
-- arrived against whatever came next.
--
-- AND `false` IS FALSY, which made the acknowledgement itself a hole. Every
-- guard in this file asks `if flying[player] then`, so between the client's
-- report and the backstop task waking up to clean up -- up to a twentieth of a
-- second -- the victim read as NOT flying while another task still owned their
-- ragdoll. A second knockback landing in that window would have called
-- RagdollOn on an already-limp rig, taken an EMPTY set of constraints back, and
-- left the player limp forever when its partner restored nothing.
--
-- So the value is the LAUNCH TOKEN, which is a non-empty string and therefore
-- always truthy. Every `if flying[x] then` guard in this file is unchanged and
-- now closes that window as well. The acknowledgement lands in a second table
-- keyed by the same token, so a report can only ever end the launch it names.
--==============================================================================
local flying: { [Player]: string } = {}
local acked: { [Player]: string } = {}
local launchSeq = 0

--==============================================================================
-- A TRAP ON THE GROUND REMEMBERS WHICH TRAP IT IS
--
-- `item` and `spec` are carried on the record rather than looked up per tick, and
-- that is not a saving: the item a trap was placed with is the item it stays,
-- even if its owner sells it, swaps it or is holding something else when it
-- fires. A trap that read the owner's CURRENT loadout at the moment it sprung
-- would be a Bramblejaw that turns into a Starlock because somebody changed
-- weapons while walking away from it.
--==============================================================================
--==============================================================================
-- AND IT IS STATE, NOT A MODEL (2026-10-04, the owner's brief)
--
-- A placed trap is HIDDEN from everybody but its owner. So the server keeps no
-- model in the world at all: a trap is this record -- where, which, since when
-- -- and the tick tests bodies against it, exactly as it always tested them
-- against `at`. The owner's client is handed a copy of the record in its OWN
-- PlayerGui (`mark`, which replicates to that player alone) and draws the trap
-- locally from it (TrapMarks.client). Nobody else receives anything to draw,
-- and no client decides who is caught.
--
-- Up to MaxActivePerPlayer per owner, any mix, keyed by a server-minted id
-- that only ever rises -- so the highest id an owner has is their NEWEST trap,
-- which is the one REMOVE takes.
--
-- NO LIFETIME (2026-10-04), AND ONE CATCH (2026-10-05, the owner's brief): an
-- untriggered trap stays until its owner REMOVEs it. The catch CONSUMES it --
-- its record goes, its slot comes back, the public snap shows for
-- Trap.SprungSeconds -- and its owner may set no trap for the trigger cooldown
-- (placeCooldownUntil). It never re-arms in place: that superseded behaviour
-- (2026-10-04's reusable traps) is gone.
--==============================================================================
type Trap = {
	id: number,
	owner: Player,
	item: WeaponData.Item,
	spec: WeaponData.TrapSpec,
	at: Vector3,
	-- The part it was set on. A floor that leaves the world -- the Rain event's
	-- temporary biome is destroyed whole when the rain ends -- takes the trap
	-- with it, so no trap is ever left floating where a floor used to be.
	ground: Instance?,
	placedAt: number,
	-- When it first bites (os.clock): ArmSeconds after it is set. Nothing bites
	-- before it.
	armsAt: number,
	-- The owner's copy, in their PlayerGui; nil for a player without one.
	mark: Instance?,
}
local traps: { [number]: Trap } = {}
local trapSeq = 0

--==============================================================================
-- THE TRIGGER COOLDOWN (2026-10-05, the owner's brief)
--
-- When one of an owner's traps catches somebody, that owner may set NO trap --
-- of any kind, from any slot or the Bag -- until this deadline (os.clock,
-- WeaponData.Trap.TriggerCooldownSeconds after the catch). One deadline per
-- OWNER: switching traps finds the same answer, so nothing bypasses it, and
-- their other traps already down stay live and may catch as usual. A later
-- catch moves it to ten seconds after itself -- the later of the two, never a
-- sum. Their REMOVE, a death and a respawn leave it running; leaving the
-- server and a service restart drop it, and it is dropped the tick it runs out.
-- The owner's client reads it as a SERVER-time deadline on the records' gui
-- (publishCooldown), the same clock the arming is drawn on.
--==============================================================================
local placeCooldownUntil: { [Player]: number } = {}

--==============================================================================
-- A SWING IS LIVE FOR A SHORT WINDOW, NOT ONE INSTANT (2026-10-04)
--
-- Registered at the press and swept by the one Heartbeat while its window is
-- open (WeaponData.Combat.HitWindow*): `seen` is where each body was on the
-- previous frame of the window, so the next frame can test the path between,
-- and `struck` is who this swing has already hit -- one hit per target per
-- swing, by construction.
--==============================================================================
type ActiveSwing = {
	tool: Tool,
	item: WeaponData.Item,
	opensAt: number,
	closesAt: number,
	-- How far the targets' own motion is wound back toward what the swinger saw.
	rewind: number,
	lastClock: number?,
	selfAt: Vector3?,
	seen: { [Player]: Vector3 },
	struck: { [Player]: boolean },
	hits: { string },
	spared: boolean,
	landed: boolean,
}
local activeSwings: { [Player]: ActiveSwing } = {}

--==============================================================================
-- A RESTRAINT KNOWS WHICH BODY IT BELONGS TO
--
-- `character` and `token` are the identity check the brief asks for, and they
-- are not theoretical. A hold is created for one character; that character can
-- die and be rebuilt while the hold's own Died and CharacterRemoving handlers
-- are still queued. Without an identity, a late callback from the OLD restraint
-- releases the NEW one -- which reads as a trap that let go early for no reason,
-- and is impossible to reproduce on purpose.
--
-- `token` rises forever, so every restraint in a session is distinguishable
-- from every other one even on the same character.
--==============================================================================
--==============================================================================
-- AND A RESTRAINT KNOWS WHAT KIND OF RESTRAINT IT IS
--
-- Two kinds now, and one record for both:
--
--   root   the Bramblejaw. WalkSpeed 0 and no jump for the whole hold.
--   slow   Mirecoil and Starlock. A FRACTION of their own speed, and jumping
--          back after `jumpUntil` while the slow runs on.
--
-- ONE TABLE, ONE TICK, ONE RELEASE. The alternative -- a second table for slows
-- -- is how a player ends up rooted by one and slowed by another with two
-- cleanup paths that each think they are the only one. Everything that can end a
-- restraint (expiry, a bat, a guardian, death, respawn, a service restart)
-- already goes through releaseHold, and it now clears both kinds.
--==============================================================================
type Hold = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	token: number,
	-- "root" or "slow".
	kind: string,
	-- 0 for a root; the fraction of their own speed for a slow.
	multiplier: number,
	until_: number,
	-- When jumping comes back, which for a root is when the hold ends and for a
	-- slow is a second in. Nil once it has been handed back.
	jumpUntil: number?,
	conns: { RBXScriptConnection },
}
local holds: { [Player]: Hold } = {}
local nextToken = 0

--==============================================================================
-- A ROOT STOPS A SWING; A SLOW DOES NOT (2026-10-04)
--
-- This refused a swing to anybody under ANY restraint, which made every slow a
-- stun in disguise -- and the snare's own design (WeaponData), TrapUI's amber
-- SLOWED and the owner's brief all say a slowed player is still walking,
-- steering and swinging. Placing a trap stays refused under either kind.
--==============================================================================
local function rooted(player: Player): boolean
	local hold = holds[player]
	return hold ~= nil and hold.kind == "root"
end

local function log(message: string)
	print("[Seed/CombatService] " .. message)
end

local function now(): number
	return os.clock()
end

--==============================================================================
-- SMALL READS
--==============================================================================
type Body = { character: Model, humanoid: Humanoid, root: BasePart }

local function bodyOf(player: Player): Body?
	local character = player.Character
	if not character or not character.Parent then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")) then
		return nil
	end
	return { character = character, humanoid = humanoid, root = root }
end

--==============================================================================
-- A REFUSAL, WITH ITS REASON WHEN THE PLAYER CAN ACT ON ONE
--
-- Every caller has already refused; `code` only captions it. With a code from
-- ActionRefusal.Text the refusal goes out as that line, and the client's toast
-- plays the denial along with it -- the bare WeaponDenied would only play the
-- same sound a second time. Without one it is the bare denial it always was: a
-- trap with no spec, a body mid-respawn, no floor underfoot, one trap already
-- down.
--==============================================================================
local function deny(player: Player, code: string?)
	if code then
		ActionRefusal.send(player, code)
		return
	end
	local ch = channel
	if not ch then
		return
	end
	pcall(function()
		ch:FireClient(player, W.DeniedAction, false)
	end)
end

local function resolveThrowRemote(): RemoteEvent?
	if throwRemote and throwRemote.Parent then
		return throwRemote
	end
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = remotes and remotes:FindFirstChild(GameConfig.Remotes.ThrowVictim)
	if found and found:IsA("RemoteEvent") then
		throwRemote = found
		return found
	end
	return nil
end

--==============================================================================
-- THE SWING, ON THE AVATAR'S OWN ANIMATOR
--
-- Played on the SERVER, which is what makes it visible to everybody: an
-- AnimationTrack started server-side on a player's Animator replicates to every
-- client, so nobody has to be told a swing happened and no client can be
-- talked out of drawing one.
--
-- SCALED TO THE SWING IT BELONGS TO. The animation is stretched so its whole
-- length covers wind-up + strike + recovery, which means the visible motion and
-- the server's hit window are the same clock: Cindercrack's 0.60s coil plays
-- slowly and the Cactus's 0.09s plays fast, off one asset.
--
-- See WeaponData.Combat.SwingAnimation for what this rig can and cannot be
-- animated with, and for the publishing blocker behind the placeholder id.
--==============================================================================
local function stopSwing(player: Player)
	local entry = swingTracks[player]
	if entry then
		pcall(function()
			entry.track:Stop(0.08)
		end)
	end
end

-- The body (or the asset) changed: the old track goes with the old Animator.
local function dropSwingTrack(player: Player)
	local entry = swingTracks[player]
	swingTracks[player] = nil
	if entry then
		pcall(function()
			entry.track:Stop(0)
			entry.track:Destroy()
		end)
	end
end

local function playSwing(player: Player, body: Body, item: WeaponData.Item)
	local id = item.SwingAnimation or C.SwingAnimation
	if type(id) ~= "string" or id == "" then
		return
	end
	local animator = body.humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		-- No Animator means no supported way to move this rig. Silent rather
		-- than warning every swing: WeaponData's banner is where this is
		-- explained, and a per-swing warn would bury a real one.
		return
	end

	local entry = swingTracks[player]
	if entry and (entry.animator ~= animator or entry.id ~= id or not animator:IsDescendantOf(Workspace)) then
		dropSwingTrack(player)
		entry = nil
	end
	if not entry then
		local anim = animationCache[id]
		if not anim then
			anim = Instance.new("Animation")
			anim.AnimationId = id
			animationCache[id] = anim
		end
		local ok, loaded = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if not ok or not loaded then
			return
		end
		loaded.Priority = Enum.AnimationPriority.Action4
		loaded.Looped = false
		entry = { animator = animator, track = loaded, id = id }
		swingTracks[player] = entry
	end
	local track = (entry :: SwingTrack).track
	-- A second swing restarts the one track rather than blending two halves.
	if track.IsPlaying then
		track:Stop(0)
	end

	--==========================================================================
	-- STRETCH IT OVER THE REAL SWING
	--
	-- This is what makes one asset serve six bats: Cindercrack's 0.60s coil
	-- plays slow and heavy, the Cactus's 0.09s plays fast and light, and the
	-- visible motion ends when the server's recovery does.
	--
	-- `track.Length` IS ZERO ON THE SERVER -- the asset is never fetched there,
	-- so the number the scaling needs does not exist where the scaling happens.
	-- Measured: both bats replicated at Speed 1.00 with the length-derived
	-- branch in place, because the branch never ran. The configured length is
	-- the fallback and in practice the only value used; the real Length is still
	-- preferred if it ever resolves, so this cannot drift silently forever.
	--==========================================================================
	--==========================================================================
	-- THE CONTACT FRAME LANDS ON THE HIT, NOT THE LAST FRAME ON THE RECOVERY
	--
	-- What has to line up is the moment the bat visibly connects and the moment
	-- the server accepts the hit -- `item.Windup` after the swing starts. So
	-- playback is scaled by where the contact frame sits in the animation:
	--
	--     speed = (length * contactFraction) / Windup
	--
	-- This was scaled by TOTAL length over total swing, which lines the two up
	-- only where a bat's wind-up is the same fraction of its swing as the
	-- animation's contact is of its length. Across the six bats that fraction
	-- runs 0.22 to 0.42, so it was right for none of them by construction.
	--
	-- `track.Length` IS ZERO ON THE SERVER -- the asset is never fetched there,
	-- so the number the scaling needs does not exist where the scaling happens.
	-- The configured length is the value actually used; the real one is
	-- preferred if it ever resolves, so the two cannot drift silently forever.
	--==========================================================================
	local length = if track.Length > 0
		then track.Length
		else (tonumber(C.SwingAnimationLength) or 0)
	local contact = math.clamp(tonumber(C.SwingAnimationContact) or 0.5, 0.05, 0.95)
	local speed = 1
	if length > 0 and item.Windup > 0.02 then
		speed = math.clamp((length * contact) / item.Windup,
			tonumber(C.SwingSpeedMin) or 0.45, tonumber(C.SwingSpeedMax) or 3.0)
	end

	--==========================================================================
	-- THE SPEED GOES INTO Play, NOT INTO AdjustSpeed AFTERWARDS
	--
	-- Measured: with `AdjustSpeed` called after `Play`, all three bats arrived
	-- on the client at Speed 1.00 -- the play command replicates, the later
	-- adjustment does not. `Play(fade, weight, speed)` carries it in the one
	-- message, so what every other player sees is the speed this side chose.
	--==========================================================================
	track:Play(0.06, 1, speed)
end

--==============================================================================
-- THE RESTRAINT
--
-- Two writes and one recompute, and NOT a captured WalkSpeed.
--
-- CarryService is the only file in this game that assigns WalkSpeed, because
-- the number is a product of a saved Speed score, a carry multiplier and
-- whatever else is currently stopping the player -- and no single caller knows
-- all three. So a trap sets an ATTRIBUTE and asks CarryService to recompute.
-- Releasing does the same in reverse.
--
-- That is the difference between this and a bug: capture-and-restore hands back
-- the number that was true when the trap fired, so a player who picks up a pod
-- or steps onto their mill while held would be released at the wrong speed, or
-- released out of somebody else's lock. Recomputing cannot be wrong, because it
-- reads the truth of the moment it happens.
--
-- JUMPING IS DISABLED AT THE TWO EDGES AND NOWHERE ELSE. Deliberately not in
-- RefreshWalkSpeed, which runs on every carry event and every respawn: a
-- function that asserts "jumping is allowed" a hundred times a session is a
-- function that will one day re-enable it underneath something else.
--
-- The camera is never touched. A held player can look wherever they like, which
-- is most of what stops two seconds of standing still feeling like a disconnect.
--==============================================================================
--==============================================================================
-- THE ONE WAY OUT OF A TRAP
--
-- Expiry, a bat hit, a guardian hit, death, respawn, the trap being removed, the
-- owner leaving and a service restart all come through here. There is no second
-- path, which is what makes "released twice" and "released for the wrong reason"
-- the same harmless no-op.
--
-- IDEMPOTENT BY THE FIRST LINE: the record is taken out of the table before
-- anything else happens, so a second call finds nothing and returns false. That
-- is also how a stale callback is neutralised -- it can only release the hold it
-- was made for, and that hold is already gone.
--
-- Returns whether a restraint was actually held, which is what the guardian
-- bridge reports back.
--==============================================================================
local function releaseHold(player: Player, why: string, token: number?): boolean
	local hold = holds[player]
	if not hold then
		return false
	end
	--==========================================================================
	-- A CALLER NAMING A TOKEN MUST NAME THIS ONE
	--
	-- Only the hold's own connections pass a token, and only to refuse a late
	-- firing that belongs to a restraint that has already ended. Everything else
	-- -- the tick, a bat, a guardian -- releases whatever is current, which is
	-- what those callers mean.
	--==========================================================================
	if token ~= nil and hold.token ~= token then
		return false
	end
	holds[player] = nil
	for _, c in ipairs(hold.conns) do
		c:Disconnect()
	end
	table.clear(hold.conns)

	--==========================================================================
	-- EVERY ATTRIBUTE A RESTRAINT CAN HAVE SET, CLEARED HERE
	--
	-- All four, unconditionally, whatever kind this was. A release that cleared
	-- only the ones its own kind sets would leave a slow's fraction on a player
	-- who was rooted a moment later -- and the fraction is what CarryService
	-- multiplies by, so the leftover would be permanent and invisible.
	--==========================================================================
	player:SetAttribute(ATTR.Trapped, nil)
	player:SetAttribute(ATTR.TrappedUntil, nil)
	player:SetAttribute(ATTR.TrappedKind, nil)
	player:SetAttribute(ATTR.TrapSlow, nil)
	if hold.humanoid.Parent then
		pcall(function()
			hold.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end)
	end
	--==========================================================================
	-- RECOMPUTED, AND EVEN IF THE BODY IS GONE
	--
	-- The attribute lives on the PLAYER and outlives the character, so a body
	-- that died while held must still clear it or the next character spawns at
	-- WalkSpeed 0. RefreshWalkSpeed is a no-op without a humanoid and correct
	-- with one, so it is safe to call either way.
	--
	-- NOTE it does not put a number back. If a guardian is mid-throw right now,
	-- that throw's own restore will recompute again when it lands -- and because
	-- both ends recompute rather than replay, the order they happen in does not
	-- matter. That is the whole of the freeze fix.
	--==========================================================================
	CarryService.RefreshWalkSpeed(player)
	immuneUntil[player] = math.max(immuneUntil[player] or 0, now() + T.ImmunitySeconds)
	log(string.format("%s released from a trap (%s).", player.Name, why))
	return true
end

--==============================================================================
-- PUT A RESTRAINT ON SOMEBODY
--
-- The spec says which kind, how long, how much of their speed they keep and how
-- long their jump is gone. Everything else -- the token, the identity, the two
-- ways a body can go away, the recompute -- is the same for both kinds, which is
-- why there is one of these and not two.
--
-- REFUSES TO STACK. A player who is already held is left alone: the trap that
-- caught them is the trap that has them, and a second effect landing on top
-- would be two timers racing to release one player. The tick and the trigger
-- both check, so this is the third guard on the same rule.
--==============================================================================
local function holdPlayer(player: Player, body: Body, spec: WeaponData.TrapSpec)
	if holds[player] then
		return
	end
	local rooted = spec.Effect == "root"
	local multiplier = if rooted then 0 else (spec.MoveMultiplier or 1)
	nextToken += 1
	local token = nextToken
	local hold: Hold = {
		player = player,
		character = body.character,
		humanoid = body.humanoid,
		token = token,
		kind = if rooted then "root" else "slow",
		multiplier = multiplier,
		until_ = now() + spec.EffectSeconds,
		jumpUntil = if spec.JumpLockSeconds > 0
			then now() + spec.JumpLockSeconds
			else nil,
		conns = {},
	}
	holds[player] = hold

	--==========================================================================
	-- WHAT THE MOVEMENT AUTHORITY IS TOLD
	--
	-- A ROOT sets `Trapped`, which CarryService reads as zero -- unchanged, and
	-- the Bramblejaw's behaviour depends on it being exactly that.
	--
	-- A SLOW sets `TrapSlow` to a FRACTION instead, which CarryService multiplies
	-- its computed speed by. Not `Trapped`: a slowed player can walk, and the two
	-- facts must not share one attribute.
	--==========================================================================
	if rooted then
		player:SetAttribute(ATTR.Trapped, true)
	else
		player:SetAttribute(ATTR.TrapSlow, multiplier)
	end
	player:SetAttribute(ATTR.TrappedKind, spec.Status or hold.kind)
	--==========================================================================
	-- AND WHEN IT ENDS, FOR THE CLIENTS TO COUNT DOWN FROM
	--
	-- Written once, in SERVER time, so every watcher draws the same number off
	-- one clock. Cleared in releaseHold, which is what makes the label vanish
	-- the instant a bat or a guardian ends the hold early rather than running to
	-- zero on a timer nobody is honouring any more.
	--==========================================================================
	player:SetAttribute(ATTR.TrappedUntil,
		Workspace:GetServerTimeNow() + spec.EffectSeconds)
	--==========================================================================
	-- AND THE JUMP, FOR AS LONG AS THIS TRAP TAKES IT
	--
	-- A root takes it for the whole hold; a snare takes it for the first second
	-- and hands it back while the slow runs on, because the answer to mud should
	-- not be "hop". Only set here, only cleared in releaseHold and in the tick --
	-- never in RefreshWalkSpeed, which runs on every carry event and would
	-- eventually be the thing that re-enabled it underneath somebody's hold.
	--==========================================================================
	if hold.jumpUntil then
		pcall(function()
			body.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end)
		body.humanoid.Jump = false
	end
	CarryService.RefreshWalkSpeed(player)

	--==========================================================================
	-- EVERY WAY A HELD PLAYER CAN STOP BEING ONE
	--
	-- The tick releases on time. These two release on the body going away, and
	-- they matter more than the timer does: a player who dies or respawns while
	-- held would otherwise take the attribute into their next character, and the
	-- next character reads WalkSpeed 0 from a trap that no longer exists.
	--==========================================================================
	table.insert(hold.conns, body.humanoid.Died:Connect(function()
		releaseHold(player, "died", token)
	end))
	table.insert(hold.conns, player.CharacterRemoving:Connect(function()
		releaseHold(player, "respawned", token)
	end))
end

--==============================================================================
-- THE KNOCKBACK
--
-- The same pipeline a guardian uses, down the same remote, with the same
-- ragdoll -- and three presentation numbers turned down. See the ThrowStyle
-- banner in ThrowFX for why that is one optional argument rather than a second
-- knockback system.
--
-- THE VICTIM'S CLIENT APPLIES THE IMPULSE. It has to: a player's character is
-- simulated by that player, and a velocity written on the server is overwritten
-- by the owner's next update. That was measured the hard way in NestService and
-- there is no reason to relearn it here.
--==============================================================================
--==============================================================================
-- ONE LAUNCH, TWO CALLERS
--
-- This was knockBack(victim, body, dir, item) and read its speed and lift off the
-- bat that swung. Two traps launch as well now -- a Dunesnap trip and a
-- Cinderburst blast -- and they are not items with a Power column, so what the
-- launch needs is the NUMBERS rather than the weapon.
--
-- EVERYTHING ELSE IS UNCHANGED AND SHARED, which is the point of doing it this
-- way instead of writing a second launcher for traps: one token per launch, the
-- pod off first, one RagdollOn, one remote, one backstop, one restore, one
-- post-recovery immunity. A trap cannot get any of that subtly wrong, because it
-- does not implement any of it.
--==============================================================================
--==============================================================================
-- THE POD COMES OFF FIRST: ONE CALL FOR A BAT AND FOR EVERY TRAP (2026-10-04)
--
-- Through CarryService.DropHeldPod and nothing else -- the authoritative drop
-- for a raid carry and for a banked pod held as a Tool -- at the feet the
-- victim is standing on, BEFORE any knockback, ragdoll, root, slow or pull
-- begins. Idempotent by construction (each source is emptied first), so a
-- second hit landing in the same frame drops nothing twice.
--==============================================================================
local function dropPodFrom(victim: Player, at: Vector3): boolean
	local ok, dropped, kind = pcall(CarryService.DropHeldPod, victim, at)
	if not ok then
		warn("[Seed/CombatService] drop failed: " .. tostring(dropped))
		return false
	end
	if dropped then
		log(string.format("%s's pod came loose (%s).", victim.Name, tostring(kind)))
	end
	return dropped == true
end

type Launch = {
	speed: number,
	lift: number,
	-- The floor on how long the victim sees themselves down. Nil takes the bat's.
	minLimp: number?,
	-- Whether a carried pod comes off first. A bat takes it here; a trap has
	-- already taken it before its effect began (applyTrapEffect), so it passes
	-- false and nothing is asked twice.
	dropPod: boolean,
	-- For the log on both ends: "bat" or "trap".
	kind: string,
	-- What did this, for this side's log only.
	why: string,
}

local function launch(victim: Player, body: Body, dir: Vector3, opts: Launch)
	if flying[victim] then
		return
	end

	--==========================================================================
	-- ONE TOKEN PER ACCEPTED LAUNCH
	--
	-- Server-minted, sent to the victim, and quoted back by them. It is what
	-- makes "I have stopped" mean "I have stopped THIS", so a report from a
	-- launch that has already ended cannot release the one that replaced it.
	--
	-- The counter alone would be enough within one server's life; the clock is
	-- in there so a token is also readable in a log, which is where these are
	-- actually going to be debugged from.
	--==========================================================================
	launchSeq += 1
	local token = string.format("b%d@%.2f", launchSeq, now())
	flying[victim] = token
	acked[victim] = nil

	--==========================================================================
	-- THE POD COMES OFF FIRST, AT THE FEET THEY ARE STILL STANDING ON
	--
	-- Captured before anything moves, so the pod lands where the victim was hit
	-- rather than wherever the ragdoll ends up. `Drop` casts down for solid
	-- ground itself and puts the shell on it -- the same call the red-line
	-- drop, the death handler and the guardian's throw all make.
	--
	-- IDEMPOTENT BY CONSTRUCTION, which is what makes duplicate hits safe: the
	-- first thing Drop does is clear `carried[player]`, so a second call finds
	-- nothing and returns false. It also means the PlatformStand watcher firing
	-- a moment later -- which it still will -- costs nothing and duplicates
	-- nothing.
	--
	-- Nothing here inspects or names the pod. Species, tier and origin nest
	-- travel inside CarryService and this file never sees them, which is how
	-- "do not create a second pod ownership system" is kept true rather than
	-- promised.
	--
	-- AND IT IS EVERY POD IN THE HANDS (2026-10-04): DropHeldPod takes a raid
	-- carry OR a banked pod held as a Tool. Asking IsCarrying -- the raid carry
	-- alone -- is why a player holding a banked pod was hit and kept it.
	--==========================================================================
	local stood = body.root.Position
	local dropped = false
	if opts.dropPod then
		dropped = dropPodFrom(victim, stood)
	end

	local loosened = NestService.RagdollOn(body.character)
	local speed = opts.speed

	local rem = resolveThrowRemote()
	if rem then
		pcall(function()
			--==================================================================
			-- hold = 0, WHICH IS THE HONEST ARC AND NOT ASTRALMAW'S TUNING
			--
			-- This sent nil at first -- the LEGACY hold the four unprofiled
			-- guardians use -- on the reasoning that it was the older, more
			-- tested branch. Measured in Play, that reasoning was wrong by a
			-- factor of seven:
			--
			--     rootwood_bat, configured 22 studs and a 2.5-stud apex
			--     legacy hold  ->  152 studs travelled, 24.5-stud apex
			--
			-- ThrowFX's own banner says why: the legacy path re-writes
			-- AssemblyLinearVelocity every frame for 0.35 seconds, which does
			-- not "hold" a launch, it CANCELS GRAVITY for the duration. The
			-- four guardians that use it were tuned against that behaviour, so
			-- their numbers are right for them and describe nothing.
			--
			-- A bat cannot afford that: the card prints a POWER rating and the
			-- player acts on it, so the launch has to be the one the rating
			-- describes. `hold = 0` is one impulse and then gravity.
			--
			-- THIS IS NOT ROUTING A BAT THROUGH ASTRALMAW. What is exceptional
			-- about Astralmaw is its NUMBERS -- 300 studs a second, 0.55 lift,
			-- an arc sized to clear a corridor wall -- and none of those are
			-- here. What is shared is the branch that makes a launch obey the
			-- parabola it was given, which is not a guardian behaviour at all.
			--==================================================================
			--==============================================================
			-- THE STYLE TABLE CARRIES THE PROTOCOL TOO
			--
			-- It is already the optional argument no guardian sends, which
			-- makes it the one place a bat can say something without the
			-- guardian path being able to hear it. No second remote: this one
			-- is a table, and a table takes fields.
			--
			-- `deadline` is in SERVER time, not a duration, because a duration
			-- starts counting when the packet is UNWRAPPED and the wire time is
			-- exactly the error we are trying to leave room for. Both sides can
			-- read Workspace:GetServerTimeNow(), so both sides mean the same
			-- instant.
			--
			-- `minLimp` is a duration on purpose, and the opposite reasoning:
			-- it is a floor on how long the victim SEES themselves down, so it
			-- should start when their machine starts drawing it.
			--==============================================================
			--==============================================================
			-- THE SAME STYLE TABLE, WITH THE TWO THINGS A TRAP DIFFERS BY
			--
			-- `kind` is a label the client logs and nothing branches on -- the
			-- branch that matters is `emergency`, which is present either way, so
			-- a trap launch goes down the tested bat path rather than the legacy
			-- gravity-cancelling one.
			--
			-- `minLimp` is the floor a trap may shorten: a Dunesnap trip is 1.1s
			-- on the floor by design, and holding it to a bat's 1.4 would make the
			-- cheap plate feel like the expensive mine.
			--==============================================================
			local style = WeaponData.BatThrowStyle(token, Workspace:GetServerTimeNow())
			style.kind = opts.kind
			if opts.minLimp then
				style.minLimp = opts.minLimp
			end
			rem:FireClient(victim, dir, speed, opts.lift, C.ClearStuds, 0, style)
		end)
	end

	--==========================================================================
	-- A BOUNDED TUMBLE, AND ONE RESTORE
	--
	-- The client says when it has settled and this waits for that -- but only up
	-- to VictimBackstopSeconds, because a bat hit has to END. A guardian can
	-- afford a six-second backstop; a bat that left somebody limp for six
	-- seconds after a shove would be a stun, and this file does not do stuns.
	--
	-- THIS WAITED ON VictimLimpSeconds AND THAT WAS THE FIRST BUG. The same 1.1
	-- seconds was being used as the thing the player feels AND as the safety net
	-- -- so the net was set earlier than the client could possibly answer, and
	-- fired on every single hit.
	--
	-- AND THEN 1.35 WAS STILL TOO SHORT, which was the second. A bat ragdoll is
	-- not a fixed length any more: the client waits for the body to actually
	-- land, which takes as long as the fall takes. So this is 3.2 -- behind the
	-- client's own 2.8 emergency, and still under the 3.3 that would make a bat
	-- feel like a guardian.
	--
	-- One exit, reached by every path, for the reason written over throwPlayer:
	-- a lock only the happy path releases is not a lock, it is a trap.
	--==========================================================================
	task.spawn(function()
		local deadline = now() + C.VictimBackstopSeconds
		local why = "the backstop"
		while now() < deadline do
			-- Only THIS launch's acknowledgement ends this loop. One from the
			-- launch before it names a token that is no longer here.
			if acked[victim] == token then
				why = "the client"
				break
			end
			if victim.Parent ~= Players or not body.humanoid.Parent
				or body.humanoid.Health <= 0 then
				-- Not a failure to report. There is nothing left to report ON,
				-- and warning about it would cry wolf on every death in a fight
				-- -- which is most of them.
				why = "the body went away"
				break
			end
			task.wait(0.05)
		end

		--======================================================================
		-- AND ONLY THIS LAUNCH CLEANS UP AFTER THIS LAUNCH
		--
		-- `loosened` is the set of constraints THIS knockback switched off, and
		-- it is the only thing that can switch them back on: a later RagdollOn
		-- would find them already off and take an empty set. So the restore is
		-- gated on the token still being ours. It always is today, because no
		-- second launch can begin while `flying` is set -- the check is here so
		-- that stays true if anybody ever relaxes that guard.
		--======================================================================
		if flying[victim] ~= token then
			return
		end
		flying[victim] = nil
		acked[victim] = nil
		if why == "the backstop" then
			--==================================================================
			-- WORTH A WARNING, AND ONLY IN THIS ONE CASE
			--
			-- The client contains itself at 2.8s and this waits 3.2s, so on any
			-- normal connection the report is already here -- and on a normal
			-- HIT it arrived at about 1.5 to 2.0, when the body finished
			-- landing. Reaching the end of this loop means no report came at
			-- all: a client that crashed, lagged past 400ms of round trip, or
			-- is refusing to answer. All three are worth seeing in a log, and
			-- none is worth breaking a fight over -- the restore below happens
			-- either way, which is the entire point of a backstop.
			--==================================================================
			warn(string.format(
				"[Seed/CombatService] %s never reported landing (%s); restored " ..
				"by the backstop after %.2fs.", victim.Name, token,
				C.VictimBackstopSeconds))
		end
		pcall(NestService.RagdollOff, loosened)
		if body.humanoid.Parent then
			body.humanoid.PlatformStand = false
		end
		if dropped then
			log(string.format("%s dropped a pod to %s.", victim.Name, opts.why))
		end
		-- Recomputed, never restored. The player may have dropped a pod on the
		-- way down, which changes what their speed should be.
		CarryService.RefreshWalkSpeed(victim)

		--==================================================================
		-- AND A MOMENT OF PROTECTION AT THE INSTANT THEY STAND
		--
		-- Until now the only immunity was counted from the HIT, and that was
		-- sound while a ragdoll had a fixed length. It does not any more: the
		-- client waits for the body to land, so recovery lands somewhere in a
		-- range and the fixed window can expire well before the victim is back
		-- on their feet.
		--
		-- The gap that leaves is real and it is the nastiest one in the system:
		-- a second attacker standing over a downed player, swinging on the exact
		-- frame the ragdoll clears. `flying` protects the whole tumble -- every
		-- swing filters on it -- and this covers the seam on the other side, so
		-- there is no instant at which a victim is both upright and free.
		--
		-- math.max, never assignment: a hit that landed a moment ago may have
		-- set a longer window, and a recovery must not SHORTEN somebody's
		-- immunity.
		--==================================================================
		immuneUntil[victim] = math.max(immuneUntil[victim] or 0,
			now() + C.VictimPostRecoverySeconds)
	end)
end

--==============================================================================
-- A BAT HIT, WHICH IS THE LAUNCH IT ALWAYS WAS
--
-- The numbers come off the item exactly as they did: Power through the ladder for
-- the horizontal, the item's own Lift for the vertical, and a bat always takes the
-- pod. Nothing about a swing changed.
--==============================================================================
local function knockBack(victim: Player, body: Body, dir: Vector3, item: WeaponData.Item)
	launch(victim, body, dir, {
		speed = WeaponData.LaunchSpeed(item),
		lift = item.Lift,
		dropPod = true,
		kind = "bat",
		why = item.Name,
	})
end

--==============================================================================
-- THE PULL, AND WHY IT IS NOT A CONSTRAINT
--
-- One move of up to `PullStuds` toward the anchor, and the move is a POSITION
-- WRITE rather than a force. Three reasons, in the order they matter:
--
--   IT CANNOT PASS THROUGH ANYTHING. The distance is decided by a raycast from
--   the victim's own root toward the trap, and if that ray hits a wall, a fence, a
--   gate or a rock, the pull stops a stud and a half short of it. A force cannot
--   promise that -- it can only pull, and the solver decides what happens when the
--   body meets a corner at speed.
--
--   NOTHING SURVIVES IT. An AlignPosition or a rope strong enough to drag a player
--   is an instance parented into their character, and four of the five ways a
--   character ends -- death, respawn, streaming, a service restart -- are ways
--   that instance becomes a permanent restraint nobody owns. This writes one
--   CFrame and is finished.
--
--   IT IS BOUNDED BY CONSTRUCTION. Eight studs, once, and the spec asserts the
--   number is under a dozen. There is no path where a pull becomes a teleport
--   across the map, because the only number involved is the one in the table.
--
-- The victim keeps their camera, their facing and their control. They arrive
-- slowed, which is the Starlock's actual weapon; the yank is what puts them back
-- inside somebody's bat range.
--==============================================================================
local PULL_STOP_SHORT = 1.5

local function pullToward(victim: Player, body: Body, target: Vector3, studs: number): number
	local from = body.root.Position
	local delta = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
	local flat = delta.Magnitude
	if flat < 0.5 then
		return 0
	end
	local dir = delta.Unit
	local want = math.min(studs, flat)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { body.character }
	params.IgnoreWater = true
	local hit = Workspace:Raycast(from, dir * want, params)
	local travel = want
	if hit then
		-- Stop at the last safe position. `hit.Distance` is where the wall is, so
		-- the body goes to just short of it -- and if it is already closer than
		-- that, nothing moves at all.
		travel = math.max(0, hit.Distance - PULL_STOP_SHORT)
	end
	if travel < 0.5 then
		return 0
	end
	--==========================================================================
	-- AND THE BODY IS MOVED, NOT THE ROOT ALONE
	--
	-- PivotTo on the character keeps the whole assembly together and keeps the
	-- victim's own facing: a MoveTo would walk them there and a root-only write
	-- would leave their limbs behind for a frame.
	--==========================================================================
	local ok = pcall(function()
		body.character:PivotTo(body.character:GetPivot() + dir * travel)
	end)
	return if ok then travel else 0
end

--==============================================================================
-- WHAT A TRAP DOES TO WHOEVER STEPPED ON IT
--
-- FIVE EFFECTS, ONE DOOR. The tick finds the victim and calls this; this reads
-- the spec and does exactly what it says. Adding a sixth trap is a row in
-- WeaponData and a branch here, and nothing else in the service moves.
--
-- THE ORDER INSIDE A TRIGGER IS FIXED, and every one of these steps is here
-- because of a rule in the brief:
--
--   1. the immunity is set FIRST, from the effect's own length, so no second
--      trap and no bat can land inside this one;
--   2. the pod comes off -- EVERY trap's, since 2026-10-04 -- through
--      CarryService.DropHeldPod and nothing else, at the feet the victim is
--      still standing on, before anything roots, trips, slows, blasts or
--      pulls them;
--   3. any restraint already on the victim is released before a launch or a
--      pull begins -- a rooted player who is then blasted must not be launched
--      at WalkSpeed 0 with their jump disabled;
--   4. and then the effect itself, whose deadline -- the countdown over the
--      victim -- is `EffectSeconds` from now.
--==============================================================================
local function applyTrapEffect(trap: Trap, victim: Player, body: Body)
	local spec = trap.spec
	--==========================================================================
	-- IMMUNITY FROM THE TRIGGER, NOT FROM THE RELEASE
	--
	-- Set here so it covers the effect AND the five seconds after it, which is
	-- what stops two owners standing two traps side by side. releaseHold extends
	-- it again when a restraint ends, so a root that is cut short by a bat still
	-- leaves its five seconds behind.
	--==========================================================================
	immuneUntil[victim] = math.max(immuneUntil[victim] or 0,
		now() + spec.EffectSeconds + T.ImmunitySeconds)

	dropPodFrom(victim, body.root.Position)

	if spec.Effect == "root" or spec.Effect == "slow" then
		holdPlayer(victim, body, spec)
		return
	end

	--==========================================================================
	-- A LAUNCH RELEASES WHATEVER WAS HOLDING THEM FIRST
	--
	-- The same handshake a bat and a guardian use, and for the same reason: a
	-- launch on a body that is pinned at zero with no jump is a launch that ends
	-- with a player sliding upright at the wrong speed.
	--
	-- AND THEN THE REST OF THE WINDOW IS A SLOW (2026-10-04). The knockdown
	-- keeps its own short floor (LaunchMinLimp) and ends when the body lands,
	-- exactly as before; the slow is put on at the same moment, so the one
	-- countdown runs from the trigger for the whole EffectSeconds. A body on the
	-- floor cannot walk anyway, and the moment it stands the launch's own
	-- recompute reads the slow -- nobody is held in a ragdoll for five seconds.
	--==========================================================================
	if spec.Effect == "trip" or spec.Effect == "blast" then
		releaseHold(victim, "a trap launched them")
		local away = body.root.Position - trap.at
		local flat = Vector3.new(away.X, 0, away.Z)
		-- Backward, which means away from the trap they stepped on. A player who
		-- managed to stand exactly on the middle of it goes the way they face.
		local dir = if flat.Magnitude > 0.25
			then flat.Unit
			else body.root.CFrame.LookVector
		launch(victim, body, dir, {
			speed = spec.LaunchSpeed or 0,
			lift = spec.LaunchLift or 0,
			minLimp = spec.LaunchMinLimp,
			dropPod = false,
			kind = "trap",
			why = trap.item.Name,
		})
		holdPlayer(victim, body, spec)
		return
	end

	if spec.Effect == "pull" then
		releaseHold(victim, "a trap pulled them")
		local travelled = pullToward(victim, body, trap.at, spec.PullStuds or 0)
		holdPlayer(victim, body, spec)
		log(string.format("%s was pulled %.1f studs by %s.",
			victim.Name, travelled, trap.item.Name))
		return
	end

	warn(string.format("[Seed/CombatService] %s has effect %q, which nothing implements",
		trap.item.Id, tostring(spec.Effect)))
end

--==============================================================================
-- A CLEAR LINE, FROM WHERE THE SWING IS TO WHERE IT MET THE BODY
--
-- Cast between the swinger's root and the contact point, ignoring both bodies.
--==============================================================================
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
sightParams.IgnoreWater = true

local function lineIsClear(from: Vector3, to: Vector3, a: Instance, b: Instance): boolean
	if not C.RequireLineOfSight then
		return true
	end
	sightParams.FilterDescendantsInstances = { a, b }
	--==========================================================================
	-- A WALL STOPS A BAT. A POD DOES NOT.
	--
	-- Everything decorative in this game is already CanQuery = false (invariant
	-- 1 in AGENTS.md, and every creature part besides), so a raycast only finds
	-- things that are genuinely solid -- the corridor walls, the gates, the
	-- ground. That is exactly the set that should block a swing, and it is why
	-- this needs no allow-list of its own.
	--==========================================================================
	return Workspace:Raycast(from, to - from, sightParams) == nil
end

--==============================================================================
-- THE SWING
--
-- Wind-up, contact, recovery. The cooldown starts at the PRESS, not at the
-- contact, so what a card calls a cooldown is the real rate of fire and is
-- always at least as long as the swing it gates (asserted in WeaponData).
--
-- THE HIT IS A SHORT WINDOW NOW, NOT ONE INSTANT (2026-10-04). The press only
-- registers the swing; the one Heartbeat sweeps it while its window is open
-- -- HitWindowLead before the visible contact at `Windup`, HitWindowTrail after
-- it, while the bat crosses the front of its arc -- and resolves nothing
-- before or after. One hit per target per swing is still by construction: a
-- body struck once is in `struck` for the rest of this swing.
--==============================================================================
local function trySwing(player: Player, item: WeaponData.Item, tool: Tool)
	local clock = now()
	if (swingReadyAt[player] or 0) > clock then
		return
	end
	local body = bodyOf(player)
	if not body or body.humanoid.PlatformStand then
		return
	end
	-- A player who is ROOTED, or mid-flight themselves, does not get to swing.
	-- A slowed one does: see `rooted`. Nor does one carrying a pod (2026-10-10,
	-- the owner: a carrier's hands are full; CarryService puts the bat away on
	-- a take, and this is the server's own word on it).
	if rooted(player) or flying[player] or CarryService.IsCarrying(player) then
		return
	end
	swingReadyAt[player] = clock + item.Cooldown
	tool:SetAttribute(READY_AT, Workspace:GetServerTimeNow() + item.Cooldown)

	--==========================================================================
	-- THE TELL, PUBLISHED BEFORE THE HIT
	--
	-- Stamped at the start of the wind-up so every client can draw the coil
	-- rather than the impact -- the same contract ParentAnim animates the
	-- guardian's AttackWindup / AttackSwipe pair on. A wind-up nobody can see is
	-- not a wind-up, it is lag, and Cindercrack's 0.6 seconds only reads as a
	-- risk if the person about to be hit can watch it happen. WeaponFX draws the
	-- visible contact at exactly SwingAt + Windup, the middle of the window.
	--==========================================================================
	tool:SetAttribute(SWING_WINDUP, item.Windup)
	tool:SetAttribute(SWING_RECOVER, item.Recovery)
	tool:SetAttribute(SWING_AT, Workspace:GetServerTimeNow())
	playSwing(player, body, item)
	--==========================================================================
	-- THE WHOOSH, WHICH WAS THE ONE CUE AWAY
	--
	-- ON THE HANDLE, so it comes from the bat rather than from the middle of the
	-- swinger, and unconditionally -- a swing that misses still cost a cooldown
	-- and still made a noise. The IMPACT is a different cue, played when
	-- something is actually struck.
	--==========================================================================
	local swungHandle = tool:FindFirstChild("Handle")
	if swungHandle and swungHandle:IsA("BasePart") then
		SoundKit.emit("BatSwing", swungHandle)
	end

	--==========================================================================
	-- HOW FAR BACK THE SWINGER'S VIEW IS
	--
	-- Their screen draws a target a little behind where the server has it: half
	-- their own round trip, plus the interpolation every client draws others
	-- through. Bounded either way, and read off the engine, never off a remote.
	--==========================================================================
	local ping = 0
	pcall(function()
		ping = tonumber((player :: any):GetNetworkPing()) or 0
	end)
	local contact = clock + item.Windup
	activeSwings[player] = {
		tool = tool,
		item = item,
		opensAt = contact - C.HitWindowLead,
		closesAt = contact + C.HitWindowTrail,
		rewind = math.clamp(C.HitRewindBaseSeconds + ping * 0.5, 0, C.HitRewindMaxSeconds),
		lastClock = nil,
		selfAt = nil,
		seen = {},
		struck = {},
		hits = {},
		spared = false,
		landed = false,
	}
end

--==============================================================================
-- ONE BODY STRUCK BY ONE SWING
--==============================================================================
local function landHit(swing: ActiveSwing, live: Body, victim: Player, body: Body)
	swing.struck[victim] = true
	--==========================================================================
	-- THE TRAP LETS GO BEFORE THE BAT LAUNCHES
	--
	-- Launching a body that is still pinned at WalkSpeed 0 with Jumping disabled
	-- means the release lands mid-flight and hands a flying player a recomputed
	-- walk speed they cannot use. Freeing first makes the knockback the only
	-- thing happening to them, and grants trap immunity on the way out, which
	-- is what stops a bat and a trap from being a loop.
	--==========================================================================
	if holds[victim] then
		releaseHold(victim, "hit by a bat")
	end

	--==========================================================================
	-- AWAY FROM THE SWINGER, THEN TURNED BY THE WEAPON'S OWN YAW
	--
	-- Away is the direction the arm just travelled, so the launch and the
	-- visible strike agree -- the rule the guardian throw follows for the same
	-- reason. The yaw is what makes six bats six weapons: Rootwood shoves you
	-- back, the Paddle sweeps you across, the Comet sends you off at an angle.
	--==========================================================================
	local delta = body.root.Position - live.root.Position
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local look = live.root.CFrame.LookVector
	local away = if flat.Magnitude > 0.05
		then flat.Unit
		else Vector3.new(look.X, 0, look.Z).Unit
	local item = swing.item
	local dir = if item.Yaw ~= 0
		then (CFrame.Angles(0, math.rad(item.Yaw), 0) * away).Unit
		else away

	immuneUntil[victim] = math.max(immuneUntil[victim] or 0, now() + C.HitImmunitySeconds)
	local had = CarryService.HoldsPod(victim)
	-- The pod comes off inside the launch, before the ragdoll (dropPodFrom).
	knockBack(victim, body, dir, item)

	if not swing.landed then
		-- The first body this swing struck is the visible impact.
		swing.landed = true
		swing.tool:SetAttribute(HIT_AT, Workspace:GetServerTimeNow())
		local handle = swing.tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			-- Was Grab -- the parent's hand closing on somebody -- which was the
			-- closest thing in the table to wood landing on a person. It has its
			-- own recording now, and it carries further than the swing does.
			SoundKit.emit("BatImpact", handle)
		end
	end
	table.insert(swing.hits, victim.Name .. (if had then " (dropped their pod)" else ""))
end

--==============================================================================
-- ONE FRAME OF AN OPEN WINDOW
--
-- For every other body: where it was on the previous frame and where it is
-- now, BOTH relative to the swinger at those moments -- so the segment between
-- is both players' motion at once -- tested against the swing's reach, arc and
-- height by WeaponData.SweepContact, plus a little of what the swinger saw.
-- Then the field and the line, in that order, exactly as the instant test did.
--
-- NO HIT ALONG A JUMP: a body (either one) that moved further than a frame
-- could carry it is tested where it is now, never along the way there.
--==============================================================================
local MAX_WALK = GameConfig.Speed.MaxWalkSpeed

local function sweepFrame(swinger: Player, swing: ActiveSwing, live: Body, clock: number)
	local origin = live.root.Position
	local dt = if swing.lastClock then clock - (swing.lastClock :: number) else 0
	swing.lastClock = clock
	local jumpLimit = math.max(C.SweepTeleportStuds, MAX_WALK * dt * 2)
	local prevOrigin = swing.selfAt
	swing.selfAt = origin
	local selfJumped = prevOrigin == nil or (origin - (prevOrigin :: Vector3)).Magnitude > jumpLimit

	local look = live.root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then
		return
	end
	flatLook = flatLook.Unit
	-- SAFE IS SAFE, for both ends of a swing (see the banner at the top).
	local swingerSafe = MapService.IsInSafeZone(origin)
	local item = swing.item
	local reach = item.Reach + C.HitReachSlack
	local cosLimit = math.cos(math.rad(math.min(89, C.ArcDegrees + C.HitArcSlack)))

	for _, other in ipairs(Players:GetPlayers()) do
		if other == swinger or swing.struck[other] then
			continue
		end
		local body = bodyOf(other)
		if not body then
			swing.seen[other] = nil
			continue
		end
		local at = body.root.Position
		local before = swing.seen[other]
		swing.seen[other] = at
		if (immuneUntil[other] or 0) > clock or flying[other] or onCourse(other)
			or body.humanoid.PlatformStand then
			continue
		end

		local jumped = before == nil or (at - (before :: Vector3)).Magnitude > jumpLimit
		local relBefore: Vector3? = nil
		if not jumped and not selfJumped then
			relBefore = (before :: Vector3) - (prevOrigin :: Vector3)
		end
		local rewind = Vector3.zero
		if not jumped then
			local v = body.root.AssemblyLinearVelocity
			local flatV = Vector3.new(v.X, 0, v.Z)
			-- A body moving faster than anybody can run is being thrown, not
			-- running: nothing of that is wound back.
			if flatV.Magnitude <= MAX_WALK * 1.6 then
				rewind = flatV * swing.rewind
				if rewind.Magnitude > C.HitRewindMaxStuds then
					rewind = rewind.Unit * C.HitRewindMaxStuds
				end
			end
		end

		local rel = WeaponData.SweepContact(relBefore, at - origin, rewind, flatLook, reach,
			cosLimit, C.HeightTolerance, C.SweepSubSamples)
		if rel then
			local point = origin + (rel :: Vector3)
			if lineIsClear(origin, point, live.character, body.character) then
				if swingerSafe or MapService.IsInSafeZone(at) or MapService.IsInSafeZone(point) then
					-- Withheld by the field: only a caption, if nothing else lands.
					swing.spared = true
				else
					landHit(swing, live, other, body)
				end
			end
		end
	end
end

local function finishSwing(player: Player, swing: ActiveSwing)
	if activeSwings[player] == swing then
		activeSwings[player] = nil
	end
	if swing.landed then
		log(string.format("%s swung a %s and hit %s.",
			player.Name, swing.item.Id, table.concat(swing.hits, ", ")))
		return
	end
	-- Nothing struck. Said out loud only when the Safe Zone is why: a miss and a
	-- wall stay as silent as they always were.
	local code = ActionRefusal.forSwing(0, swing.spared)
	if code and player.Parent == Players then
		deny(player, code)
	end
end

--==============================================================================
-- EVERY OPEN WINDOW, ONE FRAME (on the one Heartbeat)
--
-- Nothing at all while nobody is mid-swing: the table is empty and this is one
-- `pairs` over nothing. A window that has not opened yet is skipped; the
-- swinger is re-checked every frame of it -- dead, thrown, rooted, gone onto
-- the course, or the bat put away, and the swing is void with no hit and no
-- caption.
--==============================================================================
local function stepSwings(clock: number)
	for player, swing in pairs(activeSwings) do
		if clock < swing.opensAt then
			continue
		end
		local live = if player.Parent == Players then bodyOf(player) else nil
		-- Taking a pod mid-swing voids it too (2026-10-10): the hands are full.
		if not live or live.humanoid.PlatformStand or rooted(player) or flying[player]
			or onCourse(player) or swing.tool.Parent ~= live.character or CarryService.IsCarrying(player) then
			if live and swing.tool.Parent ~= live.character then
				-- Unequipped mid-swing: no hit, and the arm stops swinging a bat
				-- it is no longer holding.
				stopSwing(player)
			end
			activeSwings[player] = nil
			continue
		end
		sweepFrame(player, swing, live, clock)
		if clock >= swing.closesAt then
			finishSwing(player, swing)
		end
	end
end

--==============================================================================
-- THE TRAP: PUTTING ONE DOWN
--
-- Placed at the player's OWN FEET and nowhere else, which is what makes "no
-- placing through walls" true by construction rather than by a check: there is
-- no aim vector to send, so there is nothing to send through a wall. The one
-- cast is straight down from the player's own root, and if it finds nothing
-- within a few studs they are in mid-air and the placement is refused.
--==============================================================================
--==============================================================================
-- GROUND A TRAP MAY NOT SIT ON
--
-- Two lists, two distances, one sweep.
--
--   THE NEST LIST, unchanged at 16 studs: a pod or a nest marker. A trap on the
--   one tile everybody has to stand on to take a pod is not a play, it is a tax.
--
--   THE FURNITURE LIST, at 14: everything tagged that a player is REQUIRED to
--   walk up to. Plots and their soil, the plot spawn pad, planters and plant
--   slots -- which is where hatching happens -- treadmills, the two signs and the
--   biome gates. Most of these already stand inside the safe field, which
--   CombatService refuses wholesale; this is what covers the ones that do not, and
--   what keeps covering them if the map ever moves.
--
-- SPAWN, MARIGOLD'S SHOP AND THE SELL BOARD are the safe field. They are not
-- tagged, they have never been tagged, and the rectangle is a better guarantee
-- than a tag would be: there is no position inside the hub where a trap is legal.
--
-- FLAT DISTANCE, like the trigger: a trap under a bridge is not beside the thing
-- on top of it.
--==============================================================================
local PROTECTED_TAGS = {
	GameConfig.Tags.Plot,
	GameConfig.Tags.PlotSpawn,
	GameConfig.Tags.Planter,
	GameConfig.Tags.PlantSlot,
	GameConfig.Tags.Treadmill,
	GameConfig.Tags.MillSign,
	GameConfig.Tags.PlotSign,
	GameConfig.Tags.BiomeGate,
}

local function tooCloseToTagged(at: Vector3, tag: string, clearance: number): boolean
	local flatAt = Vector3.new(at.X, 0, at.Z)
	for _, thing in ipairs(CollectionService:GetTagged(tag)) do
		local pivot: Vector3? = nil
		if thing:IsA("BasePart") then
			pivot = thing.Position
		elseif thing:IsA("Model") then
			pivot = thing:GetPivot().Position
		end
		if pivot and (Vector3.new(pivot.X, 0, pivot.Z) - flatAt).Magnitude < clearance then
			return true
		end
	end
	return false
end

local function nearProtectedGround(at: Vector3): boolean
	for _, tag in ipairs({ GameConfig.Tags.SeedPod, GameConfig.Tags.NestSite }) do
		if tooCloseToTagged(at, tag, T.NestClearanceStuds) then
			return true
		end
	end
	for _, tag in ipairs(PROTECTED_TAGS) do
		if tooCloseToTagged(at, tag, T.ProtectedClearanceStuds) then
			return true
		end
	end
	return false
end

--==============================================================================
-- THE OWNER'S COPY OF THEIR OWN TRAPS (2026-10-04)
--
-- One ScreenGui in the owner's PlayerGui -- disabled, it draws nothing itself
-- -- holding a Configuration per trap: its id, which item, where, when it was
-- set, and when its arming runs (ArmFrom to ArmsAt), in SERVER time. A catch
-- removes the record (2026-10-05): there is no re-arming to stamp. A PlayerGui replicates
-- to its own player alone, so this is the whole of "visible only to its owner":
-- TrapMarks.client draws each trap from its record, and nobody else is sent
-- anything to draw. ResetOnSpawn is off, so an owner's traps stay drawn through
-- their own death. Nothing here is ever read back: the server's own `traps`
-- table is the trap.
--
-- THE GUI ITSELF CARRIES THE COUNT (2026-10-04): Placed, Capacity and Newest
-- (WeaponData.Trap), written by syncSlots whenever a trap is set or goes --
-- and on joining, so the hotbar's "3x" is the server's from the first frame.
-- And the trigger cooldown's deadline (2026-10-05, CooldownAttribute),
-- written by publishCooldown when a catch starts it and when it runs out.
--==============================================================================
local function marksFor(owner: Player, create: boolean): Instance?
	local gui = owner:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return nil
	end
	local marks = gui:FindFirstChild(T.MarksGuiName)
	if not marks and create then
		local holder = Instance.new("ScreenGui")
		holder.Name = T.MarksGuiName
		holder.ResetOnSpawn = false
		holder.Enabled = false
		holder.Parent = gui
		marks = holder
	end
	return marks
end

-- A moment on this side's clock, as the SERVER time every client counts in.
local function serverTime(clock: number): number
	return Workspace:GetServerTimeNow() - (now() - clock)
end

-- The record's arming clock: from ArmFrom (the placement) to ArmsAt, in
-- server time.
local function stampArming(trap: Trap)
	local mark = trap.mark
	if not mark then
		return
	end
	mark:SetAttribute("ArmFrom", serverTime(trap.placedAt))
	mark:SetAttribute("ArmsAt", serverTime(trap.armsAt))
end

local function markTrap(trap: Trap)
	local marks = marksFor(trap.owner, true)
	if not marks then
		return
	end
	local mark = Instance.new("Configuration")
	mark.Name = "Trap" .. tostring(trap.id)
	mark:SetAttribute("Id", trap.id)
	mark:SetAttribute("ItemId", trap.item.Id)
	mark:SetAttribute("At", trap.at)
	mark:SetAttribute("PlacedAt", serverTime(trap.placedAt))
	trap.mark = mark
	stampArming(trap)
	mark.Parent = marks
end

local function trapCount(owner: Player): number
	local n = 0
	for _, trap in pairs(traps) do
		if trap.owner == owner then
			n += 1
		end
	end
	return n
end

-- The owner's newest remaining trap: the highest id they hold, or 0.
local function newestOf(owner: Player): number
	local newest = 0
	for id, trap in pairs(traps) do
		if trap.owner == owner and id > newest then
			newest = id
		end
	end
	return newest
end

--==============================================================================
-- THE COUNT, WHERE THE OWNER'S CLIENT READS IT (2026-10-04)
--
-- Written after every placement and every removal, so the hotbar's count and
-- its REMOVE button change on the server's word and at once. A catch is a
-- removal (2026-10-05): the consumed trap's slot comes back the same way.
--==============================================================================
local function syncSlots(owner: Player)
	if owner.Parent ~= Players then
		return
	end
	local marks = marksFor(owner, true)
	if not marks then
		return
	end
	marks:SetAttribute(T.CapacityAttribute, T.MaxActivePerPlayer)
	marks:SetAttribute(T.PlacedAttribute, trapCount(owner))
	marks:SetAttribute(T.NewestAttribute, newestOf(owner))
end

-- The trigger cooldown's deadline where the owner's hotbar reads it: SERVER
-- time while it runs, nothing once it has run out or never started.
local function publishCooldown(owner: Player)
	if owner.Parent ~= Players then
		return
	end
	local marks = marksFor(owner, true)
	if not marks then
		return
	end
	local untilAt = placeCooldownUntil[owner]
	marks:SetAttribute(T.CooldownAttribute, if untilAt and untilAt > now() then serverTime(untilAt) else nil)
end

-- How long this owner must still wait before setting a trap, in seconds; 0 when
-- they may. For the specs and the Studio probe; the game reads the deadline.
local function cooldownLeft(owner: Player): number
	return math.max(0, (placeCooldownUntil[owner] or -math.huge) - now())
end

--==============================================================================
-- THE ONE WAY A TRAP GOES
--
-- Its owner's REMOVE, the owner leaving, a progress reset, the floor under it
-- going away, a service restart -- and its catch (consumeTrap, 2026-10-05):
-- each removes the record, which frees the owner's slot at once, takes the
-- owner's copy with it and rewrites the count. Never an expiry -- there is
-- none -- and never the trigger cooldown: a REMOVE leaves it running.
-- Idempotent by the first line.
--
-- NOTHING HERE TOUCHES A VICTIM. An effect this trap already put on somebody
-- is a hold of its own, and runs to its own deadline whatever happens to the
-- trap that caused it.
--==============================================================================
local function removeTrap(id: number, why: string)
	local trap = traps[id]
	if not trap then
		return
	end
	traps[id] = nil
	local mark = trap.mark
	trap.mark = nil
	if mark and mark.Parent then
		mark:Destroy()
	end
	syncSlots(trap.owner)
	log(string.format("%s's %s #%d removed (%s).", trap.owner.Name, trap.item.Name, id, why))
end

local function removeTrapsOf(owner: Player, why: string)
	for id, trap in pairs(traps) do
		if trap.owner == owner then
			removeTrap(id, why)
		end
	end
end

--==============================================================================
-- THE MOMENT IT GOES OFF, FOR EVERYBODY TO SEE
--
-- A hidden trap stops being a secret the instant it catches somebody: the
-- snap, the burst and the sound are the impact, and the victim and everybody
-- near them should see what had them. So the model is built HERE, on the
-- server, for the first time, already sprung -- seen by everyone for a moment
-- and gone. It is never a trap: nothing tests a body against it.
--
-- Trap.SprungSeconds, and then nothing: the catch consumed the trap
-- (2026-10-05), so its owner's own drawing went with its record at that moment
-- (TrapMarks.client) and they never see two of it.
--==============================================================================
local SPRUNG_SECONDS = T.SprungSeconds

local function showSprung(trap: Trap)
	local ok, err = pcall(function()
		local map = MapService.GetMap() or Workspace
		local model = WeaponModel.BuildTrapWorld(trap.item,
			CFrame.new(trap.at + Vector3.new(0, 0.06, 0)), map)
		WeaponModel.SetTrapArming(model, 1)
		WeaponModel.SpringTrap(model)
		local base = model.PrimaryPart
		if base then
			-- Its own, named in its own spec. Jaws, a plate, a snare, a mine and
			-- an anchor do not sound alike.
			SoundKit.emit(trap.spec.SpringCue or "Grab", base)
		end
		task.delay(SPRUNG_SECONDS, function()
			if model.Parent then
				model:Destroy()
			end
		end)
	end)
	if not ok then
		warn("[Seed/CombatService] the sprung trap could not be shown: " .. tostring(err))
	end
end

--==============================================================================
-- A CATCH CONSUMES THE TRAP (2026-10-05, the owner's brief)
--
-- It replaces the re-arm. Claimed FIRST -- out of the records before anything
-- else happens, so no other body, frame or path can spring it again -- through
-- the one removal every other way out uses: the owner's slot back, their copy
-- gone, the count rewritten. Then the owner's trigger cooldown (the later of
-- the one running and ten seconds from now) and its deadline published, then
-- the public snap. Nothing is granted and nothing is equipped: the trap is
-- still the owner's item, in their hotbar, ready again once the cooldown ends.
-- The victim's effect is applied after this by the caller and is a hold of its
-- own: the trap being gone never shortens it. One function, so the tick's
-- catch and the Studio hook below are the same few lines.
--==============================================================================
local function consumeTrap(trap: Trap, clock: number)
	removeTrap(trap.id, "sprung -- consumed by its catch")
	local owner = trap.owner
	placeCooldownUntil[owner] = math.max(placeCooldownUntil[owner] or -math.huge,
		clock + T.TriggerCooldownSeconds)
	publishCooldown(owner)
	showSprung(trap)
end

local function tryPlace(player: Player, item: WeaponData.Item, tool: Tool)
	local clock = now()
	--==========================================================================
	-- WHICH TRAP IS THIS, AND DOES THIS FILE KNOW IT
	--
	-- Read first, because every check below it is one of this trap's own numbers.
	-- An item with no spec is refused outright rather than falling back to
	-- somebody else's timings -- a trap nobody has described should do nothing.
	--==========================================================================
	local spec = WeaponData.TrapSpec(item)
	if not spec then
		warn(string.format("[Seed/CombatService] %s has no trap spec; placement refused",
			tostring(item.Id)))
		deny(player)
		return
	end
	if onCourse(player) then
		deny(player, "TRAP_OBBY")
		return
	end
	--==========================================================================
	-- NOT DURING THE OWNER'S TRIGGER COOLDOWN (2026-10-05)
	--
	-- One deadline for every trap they own, so a different or rarer trap, another
	-- hotbar slot or the Bag finds the same refusal -- and asked before the count,
	-- so the answer names the wait rather than a limit the catch just freed.
	-- Nothing else about a placement has a recharge.
	--==========================================================================
	if (placeCooldownUntil[player] or -math.huge) > clock then
		deny(player, "TRAP_COOLDOWN")
		return
	end
	--==========================================================================
	-- THREE OUT AT ONCE, ANY MIX (2026-10-04)
	--
	-- The fourth press is refused with its reason and touches none of the three
	-- already down. Every trap out counts -- arming or armed -- until it goes:
	-- REMOVEd, or consumed by its catch (2026-10-05). Nothing expires.
	--==========================================================================
	if trapCount(player) >= T.MaxActivePerPlayer then
		deny(player, "TRAP_LIMIT")
		return
	end
	local body = bodyOf(player)
	if not body or body.humanoid.PlatformStand or holds[player] or flying[player] then
		deny(player)
		return
	end
	-- No trap from full hands (2026-10-10, the owner: a carrier's hands are full).
	if CarryService.IsCarrying(player) then
		deny(player, "CARRYING_POD")
		return
	end
	if MapService.IsInSafeZone(body.root.Position) then
		deny(player, "TRAP_SAFE_ZONE")
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { body.character }
	params.IgnoreWater = true
	local from = body.root.Position
	local hit = Workspace:Raycast(from, Vector3.new(0, -(T.MaxDropStuds + 4), 0), params)
	if not hit then
		-- Mid-air, or standing over a hole. Either way there is no floor to set
		-- a trap on.
		deny(player)
		return
	end
	if hit.Normal.Y < T.MaxSlopeDot then
		deny(player)
		return
	end
	local landing = hit.Position
	if (from.Y - landing.Y) > T.MaxDropStuds then
		deny(player)
		return
	end
	-- One test that was an `or`, split only so each half can say its own thing:
	-- the field first, exactly as the `or` evaluated it, and both still refuse.
	if MapService.IsInSafeZone(landing) then
		deny(player, "TRAP_SAFE_ZONE")
		return
	end
	if nearProtectedGround(landing) then
		deny(player)
		return
	end
	--==========================================================================
	-- AND NOT ON TOP OF ANOTHER TRAP -- ANYBODY'S, THE OWNER'S OWN INCLUDED
	--
	-- Measured against the WIDER of the two triggers, so a small plate cannot be
	-- tucked inside a snare's radius. Two effects on one step is the thing every
	-- stacking rule in this file exists to prevent, and this is where it is
	-- cheapest to prevent it. Hidden traps change nothing here: the server knows
	-- where every one of them is.
	--==========================================================================
	for _, other in pairs(traps) do
		local reach = math.max(spec.TriggerRadius, other.spec.TriggerRadius)
			* T.SeparationRadiusScale
		if (Vector3.new(other.at.X, 0, other.at.Z)
			- Vector3.new(landing.X, 0, landing.Z)).Magnitude < reach then
			deny(player)
			return
		end
	end

	--==========================================================================
	-- THE SPECIFICATION IT WAS SET WITH IS THE ONE IT KEEPS
	--
	-- Copied here, with the item: the owner switching traps, selling one or
	-- holding something else when it fires changes nothing about a trap already
	-- down. A Bramblejaw never turns into a Starlock because somebody changed
	-- weapons while walking away from it.
	--
	-- No cooldown is started and nothing is stamped on the Tool: setting a trap
	-- costs no wait. The one wait is the trigger cooldown, the OWNER'S, started
	-- by a catch (consumeTrap) and drawn on every trap slot from the records.
	--==========================================================================
	trapSeq += 1
	local trap: Trap = {
		id = trapSeq,
		owner = player,
		item = item,
		spec = table.clone(spec),
		at = landing,
		ground = hit.Instance,
		placedAt = clock,
		armsAt = clock + spec.ArmSeconds,
		mark = nil,
	}
	traps[trap.id] = trap
	markTrap(trap)
	syncSlots(player)
	-- No sound from here: the placement and arming cues are the OWNER'S now
	-- (TrapMarks.client plays both on the trap it draws). A sound the whole road
	-- could hear would hand a hidden trap away.
	log(string.format("%s set a %s at %.0f, %.0f, %.0f (%s, arms in %.1fs; %d of %d out).",
		player.Name, item.Name, landing.X, landing.Y, landing.Z,
		spec.Effect, spec.ArmSeconds, trapCount(player), T.MaxActivePerPlayer))
end

--==============================================================================
-- THE TRAP: ONE TICK FOR ALL OF THEM
--
-- Catching, on one Heartbeat over every trap down -- at most three per player.
-- A connection per trap would be a connection to leak.
--
-- THE ARMING IS DRAWN BY THE OWNER, NOT HERE (2026-10-04). It used to be the
-- one cosmetic joint this project wrote server-side on purpose, so everybody
-- saw the same second of it; a hidden trap has exactly one viewer, who draws it
-- from the record's own ArmFrom and ArmsAt. What has not changed is that
-- nothing bites before it is armed, and that this side alone decides who is
-- caught.
--
-- NO EXPIRY (2026-10-04, the reusable-trap brief). What this tick still takes
-- away is a trap nobody can own any more -- its owner gone -- and a trap with
-- nothing under it: the part it was set on has left the world, which is how
-- the Rain event's temporary biome goes when the rain ends. A trap is never
-- left floating or orphaned. And a catch consumes its trap (2026-10-05).
--
-- THE TRIGGER COOLDOWNS RUN OUT HERE TOO: a deadline passed is dropped and its
-- owner's published copy cleared, so no stale deadline is left on anybody's
-- screen.
--==============================================================================
local function stepTraps(clock: number)
	for owner, untilAt in pairs(placeCooldownUntil) do
		if clock >= untilAt then
			placeCooldownUntil[owner] = nil
			publishCooldown(owner)
		end
	end
	for id, trap in pairs(traps) do
		local owner = trap.owner
		if owner.Parent ~= Players then
			removeTrap(id, "the owner went away")
			continue
		end
		local ground = trap.ground
		if ground and not ground:IsDescendantOf(Workspace) then
			removeTrap(id, "the floor under it went away")
			continue
		end
		local spec = trap.spec
		-- Set and still arming: nothing bites until armsAt.
		if clock < trap.armsAt then
			continue
		end

		for _, victim in ipairs(Players:GetPlayers()) do
			--==================================================================
			-- THE OWNER WALKS OVER THEIR OWN TRAP
			--
			-- Not out of politeness: a trap you can stand in is a trap you
			-- cannot place in a doorway and then defend, and every fight over
			-- it would be somebody catching themselves backing away.
			--
			-- AND AN IMMUNE, HELD OR FLYING VICTIM DOES NOT USE IT UP: the trap
			-- stays exactly where it is, armed, for the next body, and no
			-- cooldown starts.
			--==================================================================
			if victim ~= owner
				and (immuneUntil[victim] or 0) <= clock
				and not holds[victim]
				and not flying[victim] then
				local body = bodyOf(victim)
				if body and not body.humanoid.PlatformStand then
					local delta = body.root.Position - trap.at
					local flat = Vector3.new(delta.X, 0, delta.Z)
					-- FLAT, plus a ceiling. Jumping over a trap clears it, which
					-- is the counterplay a trap is entitled to -- and it is each
					-- trap's OWN radius and ceiling, because a snare is a wider
					-- pool than a mine is a plate.
					if flat.Magnitude <= spec.TriggerRadius
						and delta.Y >= -2 and delta.Y <= spec.TriggerHeight then
						--==========================================================
						-- ONE TRAP, ONE CATCH -- AND THEN IT IS GONE (2026-10-05)
						--
						-- Claimed first (consumeTrap): out of the records, its
						-- slot back, its owner's cooldown started, the snap shown
						-- -- so the next body in its radius, this frame or any
						-- later one, finds nothing to step on. Then the victim's
						-- effect, pod first, and the immunity after it. `break`:
						-- one victim for one trap.
						--==========================================================
						consumeTrap(trap, clock)
						applyTrapEffect(trap, victim, body)
						log(string.format("%s's %s caught %s (%s, %.1fs); consumed, %s may set a trap again in %.0fs.",
							owner.Name, trap.item.Name, victim.Name, spec.Effect, spec.EffectSeconds,
							owner.Name, cooldownLeft(owner)))
						break
					end
				end
			end
		end
	end
end

local function stepHolds(clock: number)
	for player, hold in pairs(holds) do
		if player.Parent ~= Players or not hold.humanoid.Parent
			or hold.humanoid.Health <= 0
			--==============================================================
			-- THE BODY THIS RESTRAINT WAS PUT ON IS NOT THE ONE STANDING
			-- HERE ANY MORE
			--
			-- CharacterRemoving normally catches a respawn, but it is a
			-- signal and signals can be missed on a rejoin or a fast
			-- LoadCharacter. The tick is the backstop: a hold whose character
			-- is no longer the player's is a hold about nobody.
			--==============================================================
			or player.Character ~= hold.character then
			releaseHold(player, "the body went away")
		elseif clock >= hold.until_ then
			releaseHold(player, "time")
		elseif hold.jumpUntil and clock >= hold.jumpUntil then
			--==============================================================
			-- THE JUMP COMES BACK BEFORE THE SLOW DOES
			--
			-- A snare takes it for one second of four. Handed back HERE rather
			-- than on a task.delay, because a delay is a callback that can fire
			-- after the hold it belonged to has ended -- and re-enabling jumping
			-- under somebody else's root is exactly the bug the token rules in
			-- this file exist to stop. Cleared so it happens once.
			--==============================================================
			hold.jumpUntil = nil
			if hold.humanoid.Parent then
				pcall(function()
					hold.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				end)
			end
		end
	end
end

--==============================================================================
-- THE ONE THING A CLIENT SENDS: A BUTTON PRESS ON AN EQUIPPED TOOL
--
-- `Tool.Activated` fires on the server, carries nothing, and cannot be raised
-- for a Tool the engine does not consider equipped. So no remote swings a bat
-- or sets a trap, and there is nothing to validate beyond "what is this, and
-- may they use it" -- both of which are read on this side: the holder is a
-- character the engine names, the item is re-read off the profile's ownership
-- (HeldItem), and the Tool that fired must be the very Tool in that
-- character's hands. No client ever names a target: the swing finds its own,
-- on this side. (REMOVE is the one request with a payload; see tryRemove.)
--==============================================================================
local function bindTool(tool: Tool)
	if toolConnections[tool] then
		return
	end
	local boundItem = WeaponData.Get(tool:GetAttribute(WeaponModel.ItemAttribute))
	if not boundItem then
		return
	end
	-- A trap Tool carries no recharge of its own: the one wait, the trigger
	-- cooldown (2026-10-05), is its OWNER'S, the same for every trap Tool.
	local conn = tool.Activated:Connect(function()
		--==================================================================
		-- ACTIVATED MEANS EQUIPPED, AND EQUIPPED MEANS PARENTED TO A CHARACTER
		--
		-- The engine only raises this for a Tool it considers held, so the
		-- parent is the character. Read rather than assumed anyway: a Tool
		-- destroyed in the same frame as its own activation would otherwise
		-- index nil, and the whole point of a server-side handler is that it
		-- cannot be talked into anything.
		--==================================================================
		local holder = tool.Parent
		local player = if holder then Players:GetPlayerFromCharacter(holder) else nil
		if not player then
			return
		end
		local item, held = WeaponShopService.HeldItem(player)
		if not item or held ~= tool then
			return
		end
		if item.Category == "trap" then
			tryPlace(player, item, tool)
		else
			trySwing(player, item, tool)
		end
	end)
	toolConnections[tool] = conn
	tool.Destroying:Connect(function()
		local c = toolConnections[tool]
		if c then
			c:Disconnect()
			toolConnections[tool] = nil
		end
	end)
end

--==============================================================================
-- REMOVE: THE OWNER TAKES THEIR NEWEST TRAP BACK (2026-10-04)
--
-- The one client request in this file. It carries ONE number -- the id of the
-- newest trap the owner's own records show -- and every part of it is checked
-- here, because everything off the wire is a lie until it is:
--
--   a whole positive number, or it is dropped;
--   no sooner than RemoveGapSeconds after this player's last request, or it is
--     dropped unanswered (protection, not a recharge);
--   a trap that exists and is THIS PLAYER'S, or nothing happens -- an id of
--     somebody else's trap never removes it, however it was found;
--   and their NEWEST remaining trap, or nothing happens -- newest first, always.
--
-- IDEMPOTENT: the same press arriving twice names a trap the first one already
-- took, and the second finds nothing. Each accepted press removes exactly one
-- trap and gives back exactly one slot (removeTrap rewrites the count).
--
-- AN EFFECT ALREADY ON A VICTIM IS NOT TOUCHED: it is their hold, not the
-- trap's, and it ends on its own deadline.
--==============================================================================
local function tryRemove(player: Player, id: any): boolean
	if type(id) ~= "number" or id ~= id or id < 1 or id > trapSeq or id % 1 ~= 0 then
		return false
	end
	local clock = now()
	if (removeReadyAt[player] or -math.huge) > clock then
		return false
	end
	removeReadyAt[player] = clock + T.RemoveGapSeconds
	local trap = traps[id]
	if not trap or trap.owner ~= player then
		return false
	end
	if newestOf(player) ~= id then
		return false
	end
	removeTrap(id, "its owner removed it")
	return true
end

--==============================================================================
-- LIFECYCLE
--
-- A DEATH OR A RESPAWN TAKES NO TRAP (2026-10-04): the traps are the owner's
-- records, not their body's. Nothing here listens for one to remove them, the
-- records' gui survives the respawn (ResetOnSpawn off), and TrapMarks.client
-- keeps drawing them on the new body's screen. Leaving does take them.
--==============================================================================
local function forget(player: Player)
	activeSwings[player] = nil
	dropSwingTrack(player)
	releaseHold(player, "left")
	removeTrapsOf(player, "the owner left")
	-- Their trigger cooldown goes with them; a rejoin starts clean.
	placeCooldownUntil[player] = nil
	swingReadyAt[player] = nil
	immuneUntil[player] = nil
	removeReadyAt[player] = nil
	-- Both halves of the handshake, or a rejoining player inherits a token for
	-- a launch that ended before they left.
	flying[player] = nil
	acked[player] = nil
end

function CombatService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	for tool, c in pairs(toolConnections) do
		c:Disconnect()
		toolConnections[tool] = nil
	end
	for player in pairs(swingTracks) do
		dropSwingTrack(player)
	end
	table.clear(activeSwings)
	table.clear(animationCache)
	for player in pairs(holds) do
		releaseHold(player, "service restart")
	end
	for id in pairs(traps) do
		removeTrap(id, "service restart")
	end
	trapSeq = 0
	table.clear(placeCooldownUntil)
	table.clear(swingReadyAt)
	table.clear(immuneUntil)
	table.clear(removeReadyAt)
	table.clear(flying)
	table.clear(acked)
	channel = nil
	throwRemote = nil
end

function CombatService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
		--======================================================================
		-- REMOVE, ON THE REMOTE EVERY CLIENT ALREADY LISTENS TO (2026-10-04)
		--
		-- One verb and one number; tryRemove checks all of it. Every other verb
		-- on GameEvent belongs to another service and is ignored here.
		--======================================================================
		table.insert(serviceConnections, found.OnServerEvent:Connect(function(player: Player, action: any,
			payload: any)
			if action == W.TrapRemoveAction then
				tryRemove(player, payload)
			end
		end))
	end

	--==========================================================================
	-- THE VICTIM'S "I HAVE STOPPED"
	--
	-- The same handshake NestService listens for, on the same remote, in a
	-- separate table. Both handlers run for every report and each ignores one it
	-- did not start, which is simpler and safer than one shared flag two systems
	-- would have to take turns owning.
	--==========================================================================
	--==========================================================================
	-- A GUARDIAN CAN END A RESTRAINT
	--
	-- Handed DOWN to NestService (40) because this service is 70 and requires
	-- it, so it cannot require back. Same shape as CarryService's bridge, and
	-- the same reason: the nests need one verb from a file above them.
	--
	-- It is called at the CONFIRMED catch, before the throw, so a miss or an
	-- abandoned chase releases nothing.
	--==========================================================================
	NestService.SetCombatBridge({
		ReleaseTrap = function(player: Player, why: string): boolean
			return releaseHold(player, why)
		end,
	})

	local throwRem = resolveThrowRemote()
	if throwRem then
		--======================================================================
		-- "I HAVE STOPPED" -- AND IT HAS TO SAY WHICH LAUNCH
		--
		-- Rule 4: the sender is engine-stamped and cannot be forged; everything
		-- else off the wire is a lie until checked. There is one argument now
		-- and it is checked twice -- that it is a string at all, and that it is
		-- the string THIS server minted for the launch this player is currently
		-- in. Anything else is dropped without comment.
		--
		-- That is what makes a stale report harmless. The client that was still
		-- flying an already-restored launch used to report into whatever came
		-- next and end it early; now it names a token nobody is holding.
		--
		-- A GUARDIAN THROW REPORTS WITH NO TOKEN AT ALL. NestService sends no
		-- style table, so the client has nothing to quote and fires nil, which
		-- fails the type check here and is ignored -- while NestService's own
		-- handler, which takes no arguments and never did, is untouched. The two
		-- systems no longer answer each other's post.
		--
		-- The worst a victim can do by lying is quote their own live token
		-- early, which shortens their own ragdoll -- a punishment they are
		-- cutting short for themselves, and the backstop still bounds it.
		--======================================================================
		table.insert(serviceConnections, throwRem.OnServerEvent:Connect(function(player, token)
			-- The rule itself lives in WeaponData so a spec can reach it. This
			-- is the only place on the server that asks.
			if WeaponData.AcceptsAck(flying[player], token) then
				acked[player] = token :: string
			end
		end))
	end

	--==========================================================================
	-- FINDING THE TOOLS
	--
	-- Every weapon Tool is built by WeaponShopService into a Backpack, so both
	-- containers are watched and every existing one is bound at Start -- which
	-- is what makes this safe to restart against a server that already has
	-- players holding bats.
	--==========================================================================
	local function watchContainer(container: Instance)
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") then
				bindTool(child)
			end
		end
		table.insert(serviceConnections, container.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				bindTool(child)
			end
		end))
	end

	local function watchPlayer(player: Player)
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			watchContainer(backpack)
		end
		if player.Character then
			watchContainer(player.Character)
		end
		table.insert(serviceConnections, player.CharacterAdded:Connect(function(character)
			-- The old Animator died with the old character; drop the track that
			-- belonged to it rather than leaving a dead reference in the table.
			-- A swing still in its window died with that body too.
			dropSwingTrack(player)
			activeSwings[player] = nil
			watchContainer(character)
			local bag = player:FindFirstChildOfClass("Backpack")
			if bag then
				watchContainer(bag)
			end
		end))
		--======================================================================
		-- THE BACKPACK IS REPLACED ON EVERY RESPAWN
		--
		-- Same trap CarryService documents: the connections above are to an
		-- instance the engine destroys, so the new one has to be picked up.
		--
		-- AND THE COUNT IS WRITTEN AS SOON AS THERE IS A PLAYERGUI TO WRITE IT
		-- TO (2026-10-04): 3x before the first trap is ever set, read off the
		-- server rather than assumed by the hotbar.
		--======================================================================
		if player:FindFirstChildOfClass("PlayerGui") then
			syncSlots(player)
			publishCooldown(player)
		end
		table.insert(serviceConnections, player.ChildAdded:Connect(function(child)
			if child:IsA("Backpack") then
				watchContainer(child)
			elseif child:IsA("PlayerGui") then
				syncSlots(player)
				publishCooldown(player)
			end
		end))
	end

	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
	table.insert(serviceConnections, Players.PlayerAdded:Connect(watchPlayer))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(forget))

	heartbeat = RunService.Heartbeat:Connect(function()
		local clock = now()
		stepHolds(clock)
		stepTraps(clock)
		stepSwings(clock)
	end)

	local bats, trapList = 0, {}
	for _, item in ipairs(WeaponData.Items) do
		if item.Category == "bat" then
			bats += 1
		elseif item.Category == "trap" then
			local spec = WeaponData.TrapSpec(item)
			table.insert(trapList, string.format("%s (%s %.1fs)", item.Name,
				if spec then spec.Effect else "?",
				if spec then spec.EffectSeconds else 0))
		end
	end
	log(string.format(
		"Ready. %d bat(s) and %d trap(s): %s. Hits are knockback only, %.1fs of " ..
		"immunity after one, and %.1fs after any trap effect; up to %d reusable traps out " ..
		"per player (no recharge, no expiry, REMOVE newest first), drawn for their owner " ..
		"alone; a swing is live for %.2fs around its contact.",
		bats, #trapList, table.concat(trapList, ", "), C.HitImmunitySeconds,
		T.ImmunitySeconds, T.MaxActivePerPlayer, C.HitWindowLead + C.HitWindowTrail))
end

--==============================================================================
-- THE TWO THINGS ONLY THE ENGINE CAN NORMALLY ASK FOR
--
-- `Tool.Activated` is the entire client contribution to this service, and it
-- cannot be raised from a script -- not from a spec, not from the debug console,
-- not from anywhere. That makes the two verbs behind it unreachable to any test:
-- a spec can build a trap, a victim and a floor, and then has no way to ask for
-- the placement it wants to check.
--
-- So the two handlers are exposed by name. They are NOT a second entry point:
-- they are the same local functions the Activated connections call, with the same
-- guards, in the same order, and they are server-only -- this module is never
-- required by a client and no remote reaches them.
--
-- What a spec gets from this is the whole of the trap system under test: place,
-- arm, catch (and consume), the trigger cooldown, hold, remove and clean up, on
-- a controllable clock.
--
-- RequestRemove is the same: the very function the REMOVE remote calls, with
-- the payload exactly as it would arrive off the wire (2026-10-04).
--==============================================================================
function CombatService.RequestPlace(player: Player, item: WeaponData.Item, tool: Tool)
	tryPlace(player, item, tool)
end

function CombatService.RequestSwing(player: Player, item: WeaponData.Item, tool: Tool)
	trySwing(player, item, tool)
end

function CombatService.RequestRemove(player: Player, id: any): boolean
	return tryRemove(player, id)
end

-- AdminService's Reset Player Progress: the traps a player has down go with the
-- rest of what they had out in the world -- the same removal REMOVE uses.
function CombatService.ClearTrap(player: Player)
	removeTrapsOf(player, "progress reset")
end

-- How many traps this owner has out right now (arming and armed).
-- For the specs and the Studio probe; the game reads the records' count.
function CombatService.TrapCount(owner: Player): number
	return trapCount(owner)
end

-- Seconds this owner must still wait to set a trap (the trigger cooldown); 0
-- when they may. For the specs and the Studio probe only.
function CombatService.TrapCooldown(owner: Player): number
	return cooldownLeft(owner)
end

-- This owner's trap ids, oldest first, and whether each bites right now. For
-- the specs and the Studio probe only.
function CombatService.TrapsOf(owner: Player): { { id: number, itemId: string, armed: boolean } }
	local list = {}
	local clock = now()
	for id, trap in pairs(traps) do
		if trap.owner == owner then
			table.insert(list, { id = id, itemId = trap.item.Id, armed = clock >= trap.armsAt })
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

--==============================================================================
-- A TRAP SPRUNG ON A PLAYER IN STUDIO, AS IF THEY HAD STEPPED ON IT
--
-- Play Solo has one player and a trap never catches its owner, so the one way
-- to run a real trap EFFECT on a real body in Studio is to spring one here: the
-- same applyTrapEffect the tick calls -- the pod drop, the root, slow, trip,
-- blast or pull, the countdown, the immunity -- on an anonymous trap of the
-- named kind at the player's feet. Refused outside Studio, and for a victim
-- the tick itself would leave alone (immune, held, flying, knocked flat).
--==============================================================================
function CombatService.StudioSpring(victim: Player, itemId: string): (boolean, string)
	if not RunService:IsStudio() then
		return false, "Studio only"
	end
	local item = WeaponData.Get(itemId)
	local spec = if item then WeaponData.TrapSpec(item) else nil
	local body = bodyOf(victim)
	if not (item and spec) then
		return false, "not a trap: " .. tostring(itemId)
	end
	if not body or body.humanoid.PlatformStand then
		return false, "no standing body"
	end
	if (immuneUntil[victim] or 0) > now() or holds[victim] or flying[victim] then
		return false, "immune, held or flying"
	end
	local trap: Trap = {
		id = 0,
		owner = victim,
		item = item :: WeaponData.Item,
		spec = table.clone(spec :: WeaponData.TrapSpec),
		at = body.root.Position - Vector3.new(0, 2.5, 0),
		ground = nil,
		placedAt = now(),
		armsAt = now(),
		mark = nil,
	}
	showSprung(trap)
	applyTrapEffect(trap, victim, body)
	return true, string.format("%s sprung on %s (%s, %.1fs)", (item :: WeaponData.Item).Name,
		victim.Name, (spec :: WeaponData.TrapSpec).Effect, (spec :: WeaponData.TrapSpec).EffectSeconds)
end

--==============================================================================
-- A PLACED TRAP SPRUNG IN STUDIO, WITH NOBODY ON IT (2026-10-04)
--
-- Play Solo cannot catch anybody in its owner's own trap, so a catch's effect
-- on the TRAP -- consumed, its slot back, the owner's trigger cooldown, the
-- public snap (2026-10-05) -- is shown here on the owner's REAL placed trap:
-- the same consumeTrap the tick runs at a catch, minus a victim. Refused
-- outside Studio, for a trap that is not this owner's, and for one still arming.
--==============================================================================
function CombatService.StudioSpringTrap(owner: Player, id: number): (boolean, string)
	if not RunService:IsStudio() then
		return false, "Studio only"
	end
	local trap = traps[id]
	if not trap or trap.owner ~= owner then
		return false, "not this owner's trap: " .. tostring(id)
	end
	local clock = now()
	if clock < trap.armsAt then
		return false, "still arming"
	end
	consumeTrap(trap, clock)
	return true, string.format("#%d %s sprung and consumed; %s may set a trap again in %.1fs", id,
		trap.item.Name, owner.Name, cooldownLeft(owner))
end

function CombatService.Snapshot(): string
	local lines = { "CombatService" }
	local clock = now()
	local downCount = 0
	for _ in pairs(traps) do
		downCount += 1
	end
	local heldCount = 0
	for _ in pairs(holds) do
		heldCount += 1
	end
	table.insert(lines, string.format("  %d trap(s) down, %d player(s) held",
		downCount, heldCount))
	for id, trap in pairs(traps) do
		table.insert(lines, string.format("    #%d %s: %s, %s, %.1fs old, %s",
			id, trap.owner.Name, trap.item.Name, trap.spec.Effect, clock - trap.placedAt,
			if clock >= trap.armsAt then "armed" else string.format("arms in %.1fs", trap.armsAt - clock)))
	end
	for player, hold in pairs(holds) do
		table.insert(lines, string.format("    %s: %s at x%.2f, %.1fs left%s",
			player.Name, hold.kind, hold.multiplier,
			math.max(0, hold.until_ - clock),
			if hold.jumpUntil then ", jump locked" else ""))
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local item = WeaponShopService.HeldItem(player)
		table.insert(lines, string.format(
			"  %s: holding %s, swing in %.2fs, immune for %.2fs, %d of %d trap(s) out, newest #%d, "
				.. "trap cooldown %.1fs",
			player.Name, if item then item.Id else "-",
			math.max(0, (swingReadyAt[player] or 0) - clock),
			math.max(0, (immuneUntil[player] or 0) - clock),
			trapCount(player), T.MaxActivePerPlayer, newestOf(player), cooldownLeft(player)))
	end
	return table.concat(lines, "\n")
end

return CombatService
