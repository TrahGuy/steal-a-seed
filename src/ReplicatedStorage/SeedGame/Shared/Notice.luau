--!strict
--==============================================================================
-- Steal a Seed :: Notice
--
-- The game's own short notifications -- a refused action, a small success, a
-- warning, a passing piece of information -- and the rules for showing them.
-- Names, colours, words and plain functions, plus the one slot the renderer
-- stands in. ActionToastUI draws them; NoticeSpec drives every rule here
-- without a Play session.
--
--==============================================================================
-- WHAT IS NOT A NOTICE
--
-- Ongoing state is an INDICATOR, owned by the script that knows when the state
-- ends: the chase warning (AlertUI), a boost's timer (BonusChestUI), the
-- controller reticle's reason line (PlantPlace). A notice is something that
-- just happened; it says so once and goes. The deliberate reward moments --
-- the hatch reveal, offline earnings, the +$ pops -- keep their own staging.
--
--==============================================================================
-- FOUR KINDS, AND NONE OF THEM BY COLOUR ALONE
--
--   blocked   red     a ring with a bar through it   "you can't, and why"
--   success   green   a ring with a tick             "that worked"
--   warning   amber   a diamond with "!"             "look out"
--   info      blue    a ring with "i"                "worth knowing"
--
-- Each has its own shape and its own words, so a colour-blind player loses
-- nothing: the headline says what happened, the icon says what kind of thing.
--
--==============================================================================
-- THE RULES (step)
--
--   SAME NOTICE AGAIN   refreshed where it is: its clock restarts, it gives a
--                       small nudge, it makes NO sound. A mashed button is one
--                       notice and one sound, not a stack and a drum roll.
--   A DIFFERENT ONE     goes up at the bottom of a small stack (3 on a
--                       desktop, 2 on a small screen); the stale end of the
--                       stack -- the one due to leave first -- makes room.
--   NOTHING WAITS       a notice is shown the moment it arrives or not at all,
--                       so nothing can turn up late about a moment that has
--                       passed. `stillTrue`, where a notice has one, takes it
--                       down early the moment its situation ends.
--
-- SOUNDS ARE THROTTLED SEPARATELY (soundFor): only a notice that goes up new
-- may play, never within SoundGapSeconds of any notice sound, and never within
-- KindGapSeconds of its own kind's last one.
--==============================================================================

local Notice = {}

-- "secret" (2026-10-01): the SECRET POD SPAWNED toast -- silver headline, no
-- sound of its own, the word SECRET styled by the renderer (ActionToastUI).
export type Kind = "blocked" | "success" | "warning" | "info" | "secret"

export type Post = {
	kind: Kind,
	-- The headline: a few words, upper case, what happened.
	title: string,
	-- The smaller line under it: the next step that actually works, or the
	-- detail that makes the headline useful. Optional.
	detail: string?,
	-- Two posts with the same key are the same notice. Defaults to
	-- kind|title|detail, so an identical message is always one notice.
	key: string?,
	-- True when the action already made its own sound (a purchase chime, a
	-- chest opening): the notice then adds none.
	quiet: boolean?,
	-- How long it stays up, when the default for its kind is wrong for it.
	seconds: number?,
	-- Asked before it goes up and while it is up; false takes it down at once.
	-- For a notice about a situation that can end on its own.
	stillTrue: (() -> boolean)?,
	-- The player may take it down (2026-10-01, the like reminder): the renderer
	-- draws a small close button on it -- a click, a tap or the UI's selection
	-- -- and it may stay up to DismissibleMaxSeconds rather than MaxSeconds.
	-- `onDismissed` runs once if the player takes it down.
	dismissible: boolean?,
	onDismissed: (() -> ())?,
}

export type Shown = {
	key: string,
	kind: Kind,
	-- When it came up, and when it starts to leave: its entrance and its hold
	-- (Notice.lifeOf), the moment the renderer's own timer takes it down. In the
	-- renderer's clock -- Notice.now -- so a slowed-down preview agrees too.
	bornAt: number,
	hideAt: number,
	-- How many times it has been posted while up: 1, then 2, 3...
	count: number,
}

--==============================================================================
-- HOW EACH KIND LOOKS AND SOUNDS
--
-- `tint` is the headline and the icon. The detail line is always the same warm
-- white, so a long sentence never has to be read in red. Every tint is bright
-- enough to read over the field's grass and the night sky alike; the black
-- outline under all of it does the rest.
--
-- `sound` is a SoundKit cue: the owner's four dedicated notice recordings
-- (GameConfig.Sfx.Cues, THE NOTICES), each on its own row -- so a notice's
-- sound can change without touching Denied, which the shop, the Bag and the
-- mill still play for refusals that put up no notice.
--==============================================================================
export type Style = {
	tint: Color3,
	sound: string?,
	-- Default time up, before the detail's length adds its share.
	seconds: number,
}

Notice.Styles = {
	blocked = { tint = Color3.fromRGB(255, 104, 92), sound = "NoticeBlocked", seconds = 2.4 },
	success = { tint = Color3.fromRGB(126, 228, 98), sound = "NoticeSuccess", seconds = 2.6 },
	warning = { tint = Color3.fromRGB(255, 190, 64), sound = "NoticeWarning", seconds = 3.0 },
	info = { tint = Color3.fromRGB(176, 220, 255), sound = "NoticeInfo", seconds = 2.6 },
	-- No sound: the owner has not approved one (2026-10-01).
	secret = { tint = Color3.fromRGB(236, 236, 244), sound = nil, seconds = 4.0 },
} :: { [Kind]: Style }

Notice.DetailColour = Color3.fromRGB(248, 246, 238)
Notice.Outline = Color3.fromRGB(12, 10, 16)

--==============================================================================
-- TIMING
--==============================================================================
-- Reading time grows with the detail, a little, up to a ceiling.
Notice.ReadSecondsPerChar = 0.03
Notice.ReadFreeChars = 24
Notice.MaxSeconds = 5
-- A notice the player can take down themselves may stay up this long (2026-10-01).
Notice.DismissibleMaxSeconds = 12
-- The entrance: a short rise and a small scale settle. The exit: a fade with a
-- few pixels of drift. Neither bounces.
Notice.EnterSeconds = 0.26
Notice.ExitSeconds = 0.32
Notice.RisePixels = 12
Notice.StartScale = 0.94
-- How long a newcomer waits for the notices above it to slide out of its slot.
Notice.SlideLead = 0.06
-- A refreshed notice's nudge, and how fast an evicted one clears.
Notice.NudgeScale = 1.04
Notice.NudgeSeconds = 0.16
Notice.EvictSeconds = 0.16
-- How often a notice with `stillTrue` is asked again while it is up.
Notice.RecheckSeconds = 0.25
-- Every duration the renderer uses is multiplied by this. 1 in the game; a
-- Studio preview slows the whole thing down evenly to film it frame by frame.
Notice.TimeScale = 1

-- The stack: the most notices up at once.
Notice.MaxShown = 3
Notice.MaxShownCompact = 2

-- Sound throttles.
Notice.SoundGapSeconds = 0.3
Notice.KindGapSeconds = 0.9

local KINDS: { [string]: boolean } = { blocked = true, success = true, warning = true, info = true, secret = true }

function Notice.isKind(kind: any): boolean
	return type(kind) == "string" and KINDS[kind] == true
end

-- Two posts with the same key are the same notice.
function Notice.keyOf(post: Post): string
	if type(post.key) == "string" and post.key ~= "" then
		return post.key
	end
	return post.kind .. "|" .. post.title .. "|" .. (post.detail or "")
end

-- How long a post stays up once it is shown (not counting its entrance).
function Notice.holdFor(post: Post): number
	local style = Notice.Styles[post.kind]
	local base = if type(post.seconds) == "number" and post.seconds > 0
		then post.seconds
		else (if style then style.seconds else 2.6)
	local chars = if post.detail then (utf8.len(post.detail) or #post.detail) else 0
	local extra = math.max(0, chars - Notice.ReadFreeChars) * Notice.ReadSecondsPerChar
	local cap = if post.dismissible == true then Notice.DismissibleMaxSeconds else Notice.MaxSeconds
	return math.min(cap, base + extra)
end

-- From going up to starting to leave: the entrance, then the hold.
function Notice.lifeOf(post: Post): number
	return Notice.EnterSeconds + Notice.holdFor(post)
end

-- The renderer's clock: seconds, slowed by TimeScale so every rule here runs on
-- the same clock as the tweens and timers it describes.
function Notice.now(): number
	return os.clock() / math.max(1e-3, Notice.TimeScale)
end

-- Is this a post worth drawing at all? A kind nobody named, an empty headline
-- or a situation that has already ended is dropped before it reaches the screen.
function Notice.valid(post: any): boolean
	if type(post) ~= "table" or not Notice.isKind(post.kind) then
		return false
	end
	if type(post.title) ~= "string" or post.title == "" then
		return false
	end
	if post.detail ~= nil and type(post.detail) ~= "string" then
		return false
	end
	if post.dismissible ~= nil and type(post.dismissible) ~= "boolean" then
		return false
	end
	if post.onDismissed ~= nil and type(post.onDismissed) ~= "function" then
		return false
	end
	local still = post.stillTrue
	if still ~= nil then
		if type(still) ~= "function" then
			return false
		end
		local ok, answer = pcall(still)
		if not ok or answer ~= true then
			return false
		end
	end
	return true
end

--==============================================================================
-- THE STACK STEP
--
-- `stack` is what is up now, oldest first. Returns what to do with `post`:
--
--   "refresh", index   the same notice is up at `index`: its clock restarts
--                      and its count goes up. No sound, no new notice.
--   "show", index, evicted
--                      put it up at the bottom (`index`, the end); `evicted`
--                      lists the ones that must go now to keep the stack at
--                      `maxShown` -- always the ones due to leave soonest.
--
-- The table passed in is changed in place and is also what the caller draws.
--==============================================================================
function Notice.step(stack: { Shown }, post: Post, now: number, maxShown: number): (string, number, { Shown })
	local key = Notice.keyOf(post)
	local life = Notice.lifeOf(post)
	for i, shown in ipairs(stack) do
		if shown.key == key and now < shown.hideAt then
			shown.hideAt = now + life
			shown.count += 1
			return "refresh", i, {}
		end
	end
	-- A notice whose time is up but which is still fading counts as gone.
	for i = #stack, 1, -1 do
		if now >= stack[i].hideAt then
			table.remove(stack, i)
		end
	end
	local evicted: { Shown } = {}
	local room = math.max(1, maxShown)
	while #stack >= room do
		local soonest, at = 1, math.huge
		for i, shown in ipairs(stack) do
			if shown.hideAt < at then
				soonest, at = i, shown.hideAt
			end
		end
		table.insert(evicted, table.remove(stack, soonest) :: Shown)
	end
	table.insert(stack, {
		key = key,
		kind = post.kind,
		bornAt = now,
		hideAt = now + life,
		count = 1,
	})
	return "show", #stack, evicted
end

-- Takes a shown notice out of the stack once it has gone (its fade finished,
-- or its situation ended). Returns whether it was there.
function Notice.remove(stack: { Shown }, key: string): boolean
	for i, shown in ipairs(stack) do
		if shown.key == key then
			table.remove(stack, i)
			return true
		end
	end
	return false
end

--==============================================================================
-- THE SOUND THROTTLE
--
-- `state` remembers the last notice sound and each kind's last one; the caller
-- keeps it. Call only for a notice that just went up new (a refresh is always
-- silent). Returns the cue to play, or nil, and records the play.
--==============================================================================
export type SoundState = { last: number, byKind: { [string]: number } }

function Notice.newSoundState(): SoundState
	return { last = -math.huge, byKind = {} }
end

function Notice.soundFor(state: SoundState, post: Post, now: number): string?
	if post.quiet then
		return nil
	end
	local style = Notice.Styles[post.kind]
	local cue = if style then style.sound else nil
	if not cue then
		return nil
	end
	if now - state.last < Notice.SoundGapSeconds then
		return nil
	end
	if now - (state.byKind[post.kind] or -math.huge) < Notice.KindGapSeconds then
		return nil
	end
	state.last = now
	state.byKind[post.kind] = now
	return cue
end

--==============================================================================
-- THE ENTRANCE, THE HOLD AND THE EXIT AS NUMBERS
--
-- pose(t) for a notice t seconds after it went up, with `hold` seconds up:
-- how far below its slot it sits, its scale, and how transparent it is.
-- ActionToastUI tweens between these; NoticeSpec checks their shape (no
-- overshoot, fully readable through the hold). `still` is reduced motion: no
-- rise and no scale, the fade alone.
--==============================================================================
function Notice.pose(t: number, hold: number, still: boolean?): (number, number, number)
	local enter, exit = Notice.EnterSeconds, Notice.ExitSeconds
	if t < enter then
		local k = math.clamp(t / enter, 0, 1)
		-- Quint out: fast at first, settling without overshoot.
		local e = 1 - (1 - k) ^ 5
		if still then
			return 0, 1, 1 - e
		end
		return (1 - e) * Notice.RisePixels, Notice.StartScale + (1 - Notice.StartScale) * e, 1 - e
	end
	if t < enter + hold then
		return 0, 1, 0
	end
	local k = math.clamp((t - enter - hold) / exit, 0, 1)
	local e = k * k
	if still then
		return 0, 1, e
	end
	return -e * 4, 1, e
end

--==============================================================================
-- THE CLIENT'S ONE RENDERER
--
-- Any client script says `Notice.post{...}`; ActionToastUI draws it.
--
-- ONE RENDERER, REPLACED RATHER THAN JOINED. A renderer that runs again (a
-- Rojo re-sync re-runs a LocalScript) disconnects the old one's link before
-- making its own, so there is never a second listener drawing every notice
-- twice; a renderer that is destroyed takes its link with it.
--
-- DRAWN IN THE RENDERER'S OWN SCRIPT, NEVER THE POSTER'S. Everything a notice
-- starts -- its fade's connection, its timers -- belongs to the script whose
-- thread made it, and dies with that script. Drawn on the poster's thread, a
-- notice posted by a script that is later destroyed froze half-made and
-- invisible (measured 2026-09-27: text transparency stuck at 1). So a post is
-- parked here by number and only the NUMBER crosses the BindableEvent -- which
-- would copy a table and drop its `stillTrue` function -- and the renderer's
-- own connection picks it up.
--
-- A post made while no renderer is listening is dropped, not kept: nothing
-- waits. Requiring this on the server (ActionRefusal does) makes nothing.
--==============================================================================
local parked: { [number]: Post } = {}
local lastId = 0
local signal: BindableEvent? = nil
local link: RBXScriptConnection? = nil

function Notice.setRenderer(fn: ((Post) -> ())?)
	local old = link
	if old then
		old:Disconnect()
		link = nil
	end
	table.clear(parked)
	if not fn then
		return
	end
	local event = signal or Instance.new("BindableEvent")
	signal = event
	link = event.Event:Connect(function(id: number)
		local post = parked[id]
		parked[id] = nil
		if post then
			fn(post)
		end
	end)
end

function Notice.post(post: Post)
	local event, live = signal, link
	if not (event and live and live.Connected) or not Notice.valid(post) then
		return
	end
	lastId += 1
	parked[lastId] = post
	event:Fire(lastId)
end

--==============================================================================
-- WHERE THE STACK STANDS, FOR WHAT SHARES ITS BAND (2026-09-29)
--
-- On a phone the notices stand at the top of the centre column (HudLayout,
-- THE PHONE'S TOP ROW), in the band the biome name and the sale line pass
-- through, beside the column the guide's words stand in. So those three have
-- to know how far down the notices reach at this moment: a name arriving while
-- a notice is up stands UNDER it, and the guide's words stand down while one is
-- up rather than be written over.
--
-- `reach` is the foot of the stack in the HUD's units (HudLayout's safe space),
-- or nil -- no notice up, or a screen whose notices stand over the belt, where
-- nothing shares their place. The renderer says it (setReach); anybody may read
-- it (reach) and hear it change (onReach).
--
-- A PLACE ON THE SCREEN, AND NOTHING ELSE. What a notice SAID is still read
-- back by nobody; this is only where it is standing. Kept here rather than as
-- an attribute on the player so the renderer still writes nothing anywhere.
-- Made on first use, so requiring this on the server still makes nothing.
--==============================================================================
local reach: number? = nil
local reachSignal: BindableEvent? = nil

function Notice.reach(): number?
	return reach
end

function Notice.setReach(value: number?)
	local clean = if type(value) == "number" and value == value then value else nil
	if clean == reach then
		return
	end
	reach = clean
	local event = reachSignal
	if event then
		event:Fire()
	end
end

function Notice.onReach(fn: () -> ()): RBXScriptConnection
	local event = reachSignal or Instance.new("BindableEvent")
	reachSignal = event
	return event.Event:Connect(fn)
end

return Notice
