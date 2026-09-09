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
local MapService = require(script.Parent:WaitForChild("MapService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local WeaponShopService = require(script.Parent:WaitForChild("WeaponShopService"))

local CombatService = {}

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
-- The swing animation currently playing on each player, so a second swing stops
-- the first rather than blending two half-swings together.
local swingTracks: { [Player]: AnimationTrack } = {}
-- One Animation instance per asset id, shared by every player. LoadAnimation
-- caches per Animator on top of this, so a swing costs no allocation at all
-- after the first one.
local animationCache: { [string]: Animation } = {}
local immuneUntil: { [Player]: number } = {}
local placeReadyAt: { [Player]: number } = {}
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

type Trap = {
	owner: Player,
	model: Model,
	base: BasePart,
	at: Vector3,
	placedAt: number,
	sprung: boolean,
}
local traps: { [Player]: Trap } = {}

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
type Hold = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	token: number,
	until_: number,
	conns: { RBXScriptConnection },
}
local holds: { [Player]: Hold } = {}
local nextToken = 0

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

local function deny(player: Player)
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
	local track = swingTracks[player]
	if track then
		swingTracks[player] = nil
		pcall(function()
			track:Stop(0.08)
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

	stopSwing(player)

	local anim = animationCache[id]
	if not anim then
		anim = Instance.new("Animation")
		anim.AnimationId = id
		animationCache[id] = anim
	end

	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not track then
		return
	end
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false

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
	swingTracks[player] = track

	-- Let go of it once it is done, so nothing holds a track belonging to a
	-- character that has since been rebuilt.
	track.Stopped:Connect(function()
		if swingTracks[player] == track then
			swingTracks[player] = nil
		end
	end)
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

	player:SetAttribute(ATTR.Trapped, nil)
	player:SetAttribute(ATTR.TrappedUntil, nil)
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

local function holdPlayer(player: Player, body: Body)
	if holds[player] then
		return
	end
	nextToken += 1
	local token = nextToken
	local hold: Hold = {
		player = player,
		character = body.character,
		humanoid = body.humanoid,
		token = token,
		until_ = now() + T.HoldSeconds,
		conns = {},
	}
	holds[player] = hold

	player:SetAttribute(ATTR.Trapped, true)
	--==========================================================================
	-- AND WHEN IT ENDS, FOR THE CLIENTS TO COUNT DOWN FROM
	--
	-- Written once, in SERVER time, so every watcher draws the same number off
	-- one clock. Cleared in releaseHold, which is what makes the label vanish
	-- the instant a bat or a guardian ends the hold early rather than running to
	-- zero on a timer nobody is honouring any more.
	--==========================================================================
	player:SetAttribute(ATTR.TrappedUntil, Workspace:GetServerTimeNow() + T.HoldSeconds)
	pcall(function()
		body.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end)
	body.humanoid.Jump = false
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
local function knockBack(victim: Player, body: Body, dir: Vector3, item: WeaponData.Item)
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
	--==========================================================================
	local stood = body.root.Position
	local dropped = false
	if CarryService.IsCarrying(victim) then
		local ok, result = pcall(CarryService.Drop, victim, stood)
		if ok then
			dropped = result == true
		else
			warn("[Seed/CombatService] drop failed: " .. tostring(result))
		end
	end

	local loosened = NestService.RagdollOn(body.character)
	local speed = WeaponData.LaunchSpeed(item)

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
			rem:FireClient(victim, dir, speed, item.Lift, C.ClearStuds, 0,
				WeaponData.BatThrowStyle(token, Workspace:GetServerTimeNow()))
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
	-- THIS WAITED ON VictimLimpSeconds AND THAT WAS THE BUG. The same 1.1
	-- seconds was being used as the thing the player feels AND as the safety net
	-- -- so the net was set earlier than the client could possibly answer, and
	-- fired on every single hit. The client is given the 1.1 now; this is the
	-- 1.35 behind it, and in the normal case it never reaches the end of its
	-- own loop.
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
			-- The client is given 1.10s and this waits 1.35s, so on any normal
			-- connection the report is already here. Reaching the end of the
			-- loop means it did not arrive at all -- a client that crashed,
			-- lagged past a quarter of a second of round trip, or is refusing
			-- to answer. All three are worth seeing in a log, and none of them
			-- is worth breaking a fight over: the restore below happens either
			-- way, which is the entire point of a backstop.
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
		-- Recomputed, never restored. The player may have dropped a pod on the
		-- way down, which changes what their speed should be.
		CarryService.RefreshWalkSpeed(victim)
	end)
end

--==============================================================================
-- WHO IS IN THE ARC
--
-- Flat distance, a height tolerance, an angle, and a clear line -- in that
-- order, cheapest first, because this runs once per swing per player on the
-- server and the first test throws away almost everybody.
--==============================================================================
local function lineIsClear(from: BasePart, to: BasePart): boolean
	if not C.RequireLineOfSight then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { from.Parent :: Instance, to.Parent :: Instance }
	params.IgnoreWater = true
	local delta = to.Position - from.Position
	local hit = Workspace:Raycast(from.Position, delta, params)
	--==========================================================================
	-- A WALL STOPS A BAT. A POD DOES NOT.
	--
	-- Everything decorative in this game is already CanQuery = false (invariant
	-- 1 in AGENTS.md, and every creature part besides), so a raycast only finds
	-- things that are genuinely solid -- the corridor walls, the gates, the
	-- ground. That is exactly the set that should block a swing, and it is why
	-- this needs no allow-list of its own.
	--==========================================================================
	return hit == nil
end

local function targetsFor(swinger: Player, from: Body, item: WeaponData.Item): { { player: Player, body: Body } }
	local out = {}
	local origin = from.root.Position
	local look = from.root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then
		return out
	end
	flatLook = flatLook.Unit
	local cosLimit = math.cos(math.rad(C.ArcDegrees))
	local clock = now()

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= swinger and (immuneUntil[other] or 0) <= clock and not flying[other] then
			local body = bodyOf(other)
			if body and not body.humanoid.PlatformStand then
				local delta = body.root.Position - origin
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude <= item.Reach
					and math.abs(delta.Y) <= C.HeightTolerance
					and flat.Magnitude > 0.01
					and flat.Unit:Dot(flatLook) >= cosLimit
					-- SAFE IS SAFE. A player standing in the field cannot be
					-- hit, whatever the geometry says.
					and not MapService.IsInSafeZone(body.root.Position)
					and lineIsClear(from.root, body.root) then
					table.insert(out, { player = other, body = body })
				end
			end
		end
	end
	return out
end

--==============================================================================
-- THE SWING
--
-- Wind-up, contact, recovery. The cooldown starts at the PRESS, not at the
-- contact, so what a card calls a cooldown is the real rate of fire and is
-- always at least as long as the swing it gates (asserted in WeaponData).
--
-- ONE HIT PER TARGET PER SWING falls out of the shape rather than being
-- enforced: the arc is resolved exactly once, in a single pass, after the
-- wind-up. There is no loop, no Touched event and no window during which a
-- second contact could register.
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
	-- A player who is held, or mid-flight themselves, does not get to swing.
	if holds[player] or flying[player] then
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
	-- risk if the person about to be hit can watch it happen.
	--==========================================================================
	tool:SetAttribute(SWING_WINDUP, item.Windup)
	tool:SetAttribute(SWING_RECOVER, item.Recovery)
	tool:SetAttribute(SWING_AT, Workspace:GetServerTimeNow())
	playSwing(player, body, item)
	--==========================================================================
	-- NO SWING AUDIO, AND THAT IS DELIBERATE RATHER THAN MISSING
	--
	-- GameConfig.Sfx has eighteen cues and not one of them is a whoosh. Reaching
	-- for the nearest -- a footstep, a pod pickup -- would put a wrong sound on
	-- the most repeated action in the feature, and a wrong sound is worse than
	-- silence because it cannot be un-learned. The IMPACT uses "Grab", which is
	-- literally the sound of something being struck in this game. A whoosh is
	-- one cue away whenever somebody records one.
	--==========================================================================

	task.spawn(function()
		if item.Windup > 0 then
			task.wait(item.Windup)
		end
		--======================================================================
		-- EVERYTHING RE-CHECKED AFTER THE COIL
		--
		-- Half a second is a long time on a road where the top speed is 150.
		-- The swinger can have died, respawned, been thrown, crossed the red
		-- line or put the bat away inside the wind-up, and every one of those
		-- has to cost them the hit rather than landing one from a body that is
		-- no longer there.
		--======================================================================
		if player.Parent ~= Players or tool.Parent == nil then
			return
		end
		local live = bodyOf(player)
		if not live or live.humanoid.PlatformStand or holds[player] then
			return
		end
		if tool.Parent ~= live.character then
			-- Unequipped mid-swing: no hit, and the arm stops swinging a bat it
			-- is no longer holding.
			stopSwing(player)
			return
		end
		if MapService.IsInSafeZone(live.root.Position) then
			return
		end

		local hits = targetsFor(player, live, item)
		if #hits == 0 then
			return
		end

		tool:SetAttribute(HIT_AT, Workspace:GetServerTimeNow())
		local handle = tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			SoundKit.emit("Grab", handle)
		end

		local names = {}
		for _, hit in ipairs(hits) do
			--==================================================================
			-- THE TRAP LETS GO BEFORE THE BAT LAUNCHES
			--
			-- Required by the brief and correct on its own: launching a body
			-- that is still pinned at WalkSpeed 0 with Jumping disabled means
			-- the release lands mid-flight and hands a flying player a
			-- recomputed walk speed they cannot use. Freeing first makes the
			-- knockback the only thing happening to them.
			--
			-- It also grants trap immunity on the way out, which is what stops
			-- a bat and a trap from being a loop.
			--==================================================================
			if holds[hit.player] then
				releaseHold(hit.player, "hit by a bat")
			end

			--==================================================================
			-- AWAY FROM THE SWINGER, THEN TURNED BY THE WEAPON'S OWN YAW
			--
			-- Away is the direction the arm just travelled, so the launch and
			-- the visible strike agree -- the rule the guardian throw follows
			-- for the same reason. The yaw is what makes six bats six weapons:
			-- Rootwood shoves you back, the Paddle sweeps you across, the Comet
			-- sends you off at an angle.
			--==================================================================
			local delta = hit.body.root.Position - live.root.Position
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local away = if flat.Magnitude > 0.05
				then flat.Unit
				else Vector3.new(live.root.CFrame.LookVector.X, 0,
					live.root.CFrame.LookVector.Z).Unit
			local dir = if item.Yaw ~= 0
				then (CFrame.Angles(0, math.rad(item.Yaw), 0) * away).Unit
				else away

			immuneUntil[hit.player] = now() + C.HitImmunitySeconds
			local wasCarrying = CarryService.IsCarrying(hit.player)
			knockBack(hit.player, hit.body, dir, item)
			table.insert(names, hit.player.Name ..
				(if wasCarrying then " (dropped their pod)" else ""))
		end
		log(string.format("%s swung a %s and hit %s.",
			player.Name, item.Id, table.concat(names, ", ")))
	end)
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
local function nearProtectedGround(at: Vector3): boolean
	for _, tag in ipairs({ GameConfig.Tags.SeedPod, GameConfig.Tags.NestSite }) do
		for _, thing in ipairs(CollectionService:GetTagged(tag)) do
			local pivot: Vector3? = nil
			if thing:IsA("BasePart") then
				pivot = thing.Position
			elseif thing:IsA("Model") then
				pivot = thing:GetPivot().Position
			end
			if pivot and (Vector3.new(pivot.X, 0, pivot.Z)
				- Vector3.new(at.X, 0, at.Z)).Magnitude < T.NestClearanceStuds then
				return true
			end
		end
	end
	return false
end

local function removeTrap(owner: Player, why: string)
	local trap = traps[owner]
	if not trap then
		return
	end
	traps[owner] = nil
	if trap.model.Parent then
		trap.model:Destroy()
	end
	log(string.format("%s's trap removed (%s).", owner.Name, why))
end

local function tryPlace(player: Player, item: WeaponData.Item, tool: Tool)
	local clock = now()
	if (placeReadyAt[player] or 0) > clock then
		deny(player)
		return
	end
	if traps[player] then
		-- ONE ACTIVE TRAP PER OWNER. Not a balance choice so much as the thing
		-- that makes every other rule in here bounded: one trap means one timer,
		-- one cooldown and one cleanup path per player.
		deny(player)
		return
	end
	local body = bodyOf(player)
	if not body or body.humanoid.PlatformStand or holds[player] or flying[player] then
		deny(player)
		return
	end
	if MapService.IsInSafeZone(body.root.Position) then
		deny(player)
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
	if MapService.IsInSafeZone(landing) or nearProtectedGround(landing) then
		deny(player)
		return
	end
	for _, other in pairs(traps) do
		if (Vector3.new(other.at.X, 0, other.at.Z)
			- Vector3.new(landing.X, 0, landing.Z)).Magnitude < T.TriggerRadius * 2 then
			deny(player)
			return
		end
	end

	--==========================================================================
	-- THE COOLDOWN STARTS NOW, NOT WHEN IT FIRES
	--
	-- So a trap that catches somebody in the first second and one that sits
	-- there for its full twenty cost the same fifteen. Timing it from the SPRING
	-- would reward a lucky placement with a faster next one.
	--==========================================================================
	placeReadyAt[player] = clock + T.PlaceCooldownSeconds
	tool:SetAttribute(READY_AT, Workspace:GetServerTimeNow() + T.PlaceCooldownSeconds)

	local map = MapService.GetMap() or Workspace
	local cf = CFrame.new(landing + Vector3.new(0, 0.06, 0))
	local model = WeaponModel.BuildTrapWorld(item, cf, map)
	model:SetAttribute("OwnerUserId", player.UserId)
	CollectionService:AddTag(model, GameConfig.Tags.Trap)

	traps[player] = {
		owner = player,
		model = model,
		base = model.PrimaryPart :: BasePart,
		at = landing,
		placedAt = clock,
		sprung = false,
	}
	SoundKit.emit("TakePod", model.PrimaryPart :: BasePart)
	log(string.format("%s set a trap at %.0f, %.0f, %.0f.",
		player.Name, landing.X, landing.Y, landing.Z))
end

--==============================================================================
-- THE TRAP: ONE TICK FOR ALL OF THEM
--
-- Arming, expiry and catching, on one Heartbeat over at most one trap per
-- player. A connection per trap would be a connection to leak.
--
-- THE JAWS OPEN ON THE SERVER, which is the one place in this project where a
-- cosmetic joint is written server-side on purpose. The opening IS the arming
-- window -- the second in which a player can still walk away -- and a client
-- drawing it locally could show a trap wide open while this side still had it
-- shut, or the reverse. Everybody has to be looking at the same second. It is
-- one Motor6D on one model for one second, so the cost of being right is
-- nothing.
--==============================================================================
local function stepTraps(clock: number)
	for owner, trap in pairs(traps) do
		if not trap.model.Parent or owner.Parent ~= Players then
			removeTrap(owner, "the owner or the model went away")
			continue
		end
		local age = clock - trap.placedAt
		if age < T.ArmSeconds then
			WeaponModel.SetTrapJaw(trap.model, age / T.ArmSeconds)
			continue
		end
		if not trap.sprung then
			WeaponModel.SetTrapJaw(trap.model, 1)
		end
		if age > T.ExpireSeconds then
			removeTrap(owner, "expired")
			continue
		end
		if trap.sprung then
			continue
		end

		for _, victim in ipairs(Players:GetPlayers()) do
			--==================================================================
			-- THE OWNER WALKS OVER THEIR OWN TRAP
			--
			-- Not out of politeness: a trap you can stand in is a trap you
			-- cannot place in a doorway and then defend, and every fight over
			-- it would be somebody catching themselves backing away.
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
					-- is the counterplay a visible trap is entitled to.
					if flat.Magnitude <= T.TriggerRadius
						and delta.Y >= -2 and delta.Y <= T.TriggerHeight then
						trap.sprung = true
						WeaponModel.SetTrapJaw(trap.model, 0.10)
						SoundKit.emit("Grab", trap.base)
						holdPlayer(victim, body)
						log(string.format("%s's trap caught %s.", owner.Name, victim.Name))
						-- ONE TRAP, ONE CATCH. It is destroyed on the next tick
						-- by the branch below rather than here, so the shut jaws
						-- are on screen for a moment before it goes.
						task.delay(0.6, function()
							removeTrap(owner, "sprung")
						end)
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
		end
	end
end

--==============================================================================
-- THE ONE THING A CLIENT SENDS: A BUTTON PRESS ON AN EQUIPPED TOOL
--
-- `Tool.Activated` fires on the server, carries nothing, and cannot be raised
-- for a Tool the engine does not consider equipped. So there is no remote here
-- at all, and nothing to validate beyond "what is this, and may they use it" --
-- both of which are read on this side.
--==============================================================================
local function bindTool(tool: Tool)
	if toolConnections[tool] then
		return
	end
	if not WeaponData.Get(tool:GetAttribute(WeaponModel.ItemAttribute)) then
		return
	end
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
		local item = WeaponShopService.HeldItem(player)
		if not item then
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
-- LIFECYCLE
--==============================================================================
local function forget(player: Player)
	stopSwing(player)
	releaseHold(player, "left")
	removeTrap(player, "the owner left")
	swingReadyAt[player] = nil
	immuneUntil[player] = nil
	placeReadyAt[player] = nil
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
		stopSwing(player)
	end
	table.clear(animationCache)
	for player in pairs(holds) do
		releaseHold(player, "service restart")
	end
	for owner in pairs(traps) do
		removeTrap(owner, "service restart")
	end
	table.clear(swingReadyAt)
	table.clear(immuneUntil)
	table.clear(placeReadyAt)
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
			swingTracks[player] = nil
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
		--======================================================================
		table.insert(serviceConnections, player.ChildAdded:Connect(function(child)
			if child:IsA("Backpack") then
				watchContainer(child)
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
	end)

	log(string.format(
		"Ready. %d bat(s) and the Bramblejaw; hits are knockback only, %.1fs of " ..
		"immunity after one, and traps hold for %.0fs.",
		#WeaponData.Items - 1, C.HitImmunitySeconds, T.HoldSeconds))
end

function CombatService.Snapshot(): string
	local lines = { "CombatService" }
	local clock = now()
	local trapCount = 0
	for _ in pairs(traps) do
		trapCount += 1
	end
	local heldCount = 0
	for _ in pairs(holds) do
		heldCount += 1
	end
	table.insert(lines, string.format("  %d trap(s) down, %d player(s) held",
		trapCount, heldCount))
	for _, player in ipairs(Players:GetPlayers()) do
		local item = WeaponShopService.HeldItem(player)
		table.insert(lines, string.format(
			"  %s: holding %s, swing in %.2fs, immune for %.2fs, trap in %.1fs",
			player.Name, if item then item.Id else "-",
			math.max(0, (swingReadyAt[player] or 0) - clock),
			math.max(0, (immuneUntil[player] or 0) - clock),
			math.max(0, (placeReadyAt[player] or 0) - clock)))
	end
	return table.concat(lines, "\n")
end

return CombatService
