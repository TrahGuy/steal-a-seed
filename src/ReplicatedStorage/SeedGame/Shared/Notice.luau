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
--                       down early the moment its situation ends. The one
--                       exception is a notice that FOLLOWS another (`after`,
--                       2026-10-05: a storm's Secret egg after the storm's own
--                       opening): on a stack with no room for both it waits
--                       until that one starts to leave, and no longer.
--
-- SOUNDS ARE THROTTLED SEPARATELY (soundFor): only a notice that goes up new
-- may play, never within SoundGapSeconds of any notice sound, and never within
-- KindGapSeconds of its own kind's last one.
--==============================================================================

local Notice = {}

-- "secret" (2026-10-01): the Secret egg toast -- silver headline, no sound of
-- its own, the word SECRET styled by the renderer (ActionToastUI) wherever it
-- stands in the sentence (2026-10-05: "A SECRET EGG SPAWNED ON ...").
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
	-- Where it came from (2026-10-03), a key of GameConfig.SourceIcons: its
	-- picture is drawn in place of the kind's glyph once uploaded, and until
	-- then the glyph is. Changes nothing else -- not the kind, timing or sound.
	icon: string?,
	-- No icon at all (2026-10-13, the owner: an admin's line has no gear): the
	-- headline stands alone, centred, with no icon's room kept beside it.
	bare: boolean?,
	-- An admin's line (2026-10-13, NAME BADGES): the sender's name as it stands
	-- in the title, and their badge's key (GameConfig.NameBadges), drawn right
	-- after the name. Both or neither.
	name: string?,
	badge: string?,
	-- The Secret word's sweep in this headline (2026-10-17, the owner: an
	-- admin's "summoned a SECRET!" line "with that secret text effect"): the
	-- word GameConfig.Secret.Toast.Word drawn as the Secret egg toast draws it,
	-- wherever it stands. A Secret egg toast (kind "secret") always has it.
	sheen: boolean?,
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
	-- The key of a notice this one follows (2026-10-05: a storm's Secret egg
	-- after the storm's own opening): while going up would put that one out
	-- before its time, this one waits for it (waitAfter) rather than replace it.
	after: string?,
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
-- `tint` is the icon. The headline is white since 2026-10-13 (the owner's
-- comic-face reference, ActionToastUI) and the detail line the same warm white,
-- so no sentence has to be read in red. Every tint is bright enough to read
-- over the field's grass and the night sky alike; the black outline under all
-- of it does the rest.
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
-- GIVING WAY (2026-10-12, the owner's rule for the top-centre band): the one
-- giving way -- the oldest notice when the next would pass the middle, a notice
-- under a card that wins the band, a phone's guide card or tracker under a
-- notice -- slides up this far and fades over this long, and comes back the
-- same way. Reduced Motion: the fade alone.
Notice.GiveWaySeconds = 0.3
Notice.GiveWayPixels = 10
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
	if post.icon ~= nil and type(post.icon) ~= "string" then
		return false
	end
	if post.onDismissed ~= nil and type(post.onDismissed) ~= "function" then
		return false
	end
	if post.after ~= nil and type(post.after) ~= "string" then
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

-- How long a post that follows `key` (Post.after) waits before going up, in
-- the renderer's clock: until `key` starts to leave, when going up now would
-- put it out -- it is up, the stack is full, and it is the one step() would
-- evict. 0 otherwise: room for both, or `key` not up (2026-10-05).
function Notice.waitAfter(stack: { Shown }, key: string, now: number, maxShown: number): number
	local live = 0
	local soonest: Shown? = nil
	local target: Shown? = nil
	for _, shown in ipairs(stack) do
		if now < shown.hideAt then
			live += 1
			if soonest == nil or shown.hideAt < soonest.hideAt then
				soonest = shown
			end
			if shown.key == key then
				target = shown
			end
		end
	end
	if target == nil or live < math.max(1, maxShown) or soonest ~= target then
		return 0
	end
	return target.hideAt - now
end

--==============================================================================
-- THE SECRET EGG TOAST (2026-10-05)
--
-- "A SECRET EGG SPAWNED ON {BIOME}!" when a Secret egg actually spawns -- a
-- road Secret, or a storm's special egg as its biome opens (NestService). The
-- server sends { id, biome, event? }: the spawn's own id, its biome's id, and
-- for a storm's egg the event it belongs to. Plain functions, so the specs
-- check them with no screen:
--
--   readSecret   the payload, or nil; an older server's bare biome id still reads
--   secretPost   the post for it -- ONCE per spawn id on this client, however
--                often it is delivered; a later spawn in the same biome has its
--                own id and is shown. The biome is told by its display name,
--                never its id.
--   wordSpan     where the styled word stands in the centred headline, wherever
--                it is in the sentence (it used to have to lead), on one line
--                or broken over more
--==============================================================================
export type SecretNews = { id: string?, biome: string, event: number? }

function Notice.readSecret(payload: any): SecretNews?
	if type(payload) == "string" then
		return if payload ~= "" then { id = nil, biome = payload, event = nil } else nil
	end
	if type(payload) ~= "table" then
		return nil
	end
	local id, biome, event = payload.id, payload.biome, payload.event
	if type(id) ~= "string" or id == "" or type(biome) ~= "string" or biome == "" then
		return nil
	end
	return { id = id, biome = biome, event = if type(event) == "number" then event else nil }
end

export type SecretWords = { Title: string, TitleNoName: string }

-- `seen` is this client's record of the spawns it has shown, filled in here.
-- Nil: shown already. `nameOf` answers a biome's display name, or nil.
function Notice.secretPost(news: SecretNews, words: SecretWords, nameOf: (string) -> string?,
	seen: { [string]: boolean }): Post?
	local id = news.id
	if id then
		if seen[id] then
			return nil
		end
		seen[id] = true
	end
	local name = nameOf(news.biome)
	-- The name stays on one line (2026-10-05, seen in Play: "RAIN / BIOME!"): its
	-- own spaces are no-break spaces, which LuckiestGuy draws exactly as a space
	-- (measured: the same 100 px), so a headline too wide for the stack breaks
	-- before the name rather than inside it.
	local title = if type(name) == "string" and name ~= ""
		then string.format(words.Title, (string.gsub(string.upper(name), " ", "\u{00A0}")))
		else words.TitleNoName
	return {
		kind = "secret",
		title = title,
		key = "secret:" .. (id or news.biome),
		quiet = true,
	}
end

--==============================================================================
-- A NOTICE THE SERVER WORDED (2026-10-07)
--
-- The GameEvent verb ServerNotice carries an information line whose words the
-- server wrote -- { title, detail?, key? } -- for a moment no client script
-- knows the words of (first: an item the server put in this player's Bag).
-- Always kind "info": a server line is never a refusal, a warning or a toast
-- with a sound of its own. The words are cut to ServerTitleMax / ServerDetailMax
-- characters, so a long name never runs off the screen, and the key folds a
-- repeat of the same line into one notice, as every notice's does.
--==============================================================================
Notice.ServerNotice = "ServerNotice"
Notice.ServerTitleMax = 90
Notice.ServerDetailMax = 120

-- At most `most` characters, cut on a character; nil for anything not a string.
local function cutWords(text: any, most: number): string?
	if type(text) ~= "string" then
		return nil
	end
	local trimmed = string.match(text, "^%s*(.-)%s*$") or ""
	if (utf8.len(trimmed) or #trimmed) <= most then
		return trimmed
	end
	local stop = utf8.offset(trimmed, most + 1)
	return if stop then string.sub(trimmed, 1, stop - 1) else string.sub(trimmed, 1, most)
end

function Notice.readServerNotice(payload: any): Post?
	if type(payload) ~= "table" then
		return nil
	end
	local title = cutWords(payload.title, Notice.ServerTitleMax)
	if not title or title == "" then
		return nil
	end
	local detail = cutWords(payload.detail, Notice.ServerDetailMax)
	local key = if type(payload.key) == "string" and payload.key ~= "" and #payload.key <= 100
		then "server:" .. payload.key
		else nil
	-- Optional (2026-10-08, TREADMILL FUN): a GameConfig.SourceIcons key -- a
	-- short word, never a path or an id -- drawn as every notice's icon is, and
	-- `quiet` when the moment made its own sound.
	local icon = if type(payload.icon) == "string" and #payload.icon <= 24
			and string.match(payload.icon, "^[%w_]+$") ~= nil
		then payload.icon
		else nil
	-- The sender's name badge (2026-10-13): a short key, with the name it follows
	-- -- only when that name stands in the title. The renderer draws only a key
	-- GameConfig.NameBadges knows.
	local badged = type(payload.badge) == "string" and #payload.badge <= 16
		and string.match(payload.badge, "^[%w_]+$") ~= nil
		and type(payload.name) == "string" and payload.name ~= "" and #payload.name <= 40
		and string.find(title, payload.name, 1, true) ~= nil
	return {
		kind = "info",
		title = title,
		detail = if detail and detail ~= "" then detail else nil,
		key = key,
		icon = icon,
		quiet = if payload.quiet == true then true else nil,
		-- An admin's line (2026-10-13): no icon at all.
		bare = if payload.bare == true then true else nil,
		name = if badged then payload.name else nil,
		badge = if badged then payload.badge else nil,
		-- The Secret word's sweep (2026-10-17): only a flag; the word is the
		-- renderer's, and a title without it is drawn as any other.
		sheen = if payload.sheen == true then true else nil,
	}
end

export type WordSpan = {
	-- The headline's lines, top first: one where it fits `room`, otherwise
	-- broken at spaces with as many words on each line as fit.
	lines: { string },
	-- The widest line: what the label is measured to.
	width: number,
	-- The word's line (1 at the top; nil when the headline has no such word),
	-- where it starts in that line's text, its left edge from the label's left
	-- with every line centred in `width`, and its own width.
	line: number?,
	at: number,
	x: number,
	w: number,
}

-- A whole word only: "SECRET" in "A SECRET EGG", never inside "SECRETS".
local function findWord(line: string, word: string): number?
	local from = 1
	while true do
		local a, b = string.find(line, word, from, true)
		if not a or not b then
			return nil
		end
		local before = if a > 1 then string.sub(line, a - 1, a - 1) else ""
		local after = string.sub(line, b + 1, b + 1)
		if (before == "" or before == " ") and not string.match(after, "%w") then
			return a
		end
		from = a + 1
	end
end

-- `measure(text)` is the text's width at the headline's size and font.
function Notice.wordSpan(title: string, word: string, room: number, measure: (string) -> number): WordSpan
	local lines: { string } = {}
	if measure(title) <= room then
		lines = { title }
	else
		local current = ""
		for piece in string.gmatch(title, "%S+") do
			local try = if current == "" then piece else current .. " " .. piece
			if current ~= "" and measure(try) > room then
				table.insert(lines, current)
				current = piece
			else
				current = try
			end
		end
		if current ~= "" then
			table.insert(lines, current)
		end
	end
	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, measure(line))
	end
	for i, line in ipairs(lines) do
		local at = findWord(line, word)
		if at then
			local before = string.sub(line, 1, at - 1)
			local left = (width - measure(line)) / 2
			-- The words before it measured WITH the word and less it, so the space
			-- in front of it counts however the measure treats a trailing space.
			local x = if before == "" then left else left + measure(before .. word) - measure(word)
			return { lines = lines, width = width, line = i, at = at, x = x, w = measure(word) }
		end
	end
	return { lines = lines, width = width, line = nil, at = 0, x = 0, w = 0 }
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

-- Whether a renderer is listening (2026-10-06): a post made before then is
-- dropped, so a poster with something to say at join (InviteUI's WELCOME!)
-- waits for this first.
function Notice.ready(): boolean
	local live = link
	return signal ~= nil and live ~= nil and live.Connected
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

--==============================================================================
-- HOW MANY NOTICES ARE STANDING (2026-10-08)
--
-- The guide's spotlight (TutorialUI) never dims the screen over a notice: it
-- waits while one is up and drops the moment one arrives. `showing` is how many
-- stand right now on every screen -- one already fading out is not counted. The
-- renderer says it as it restacks (setShowing); anybody may read it (showing)
-- and hear it change (onShowing). A count, and nothing else: what a notice SAID
-- is still read back by nobody. Made on first use, like `reach`.
--==============================================================================
local showingCount = 0
local showingSignal: BindableEvent? = nil

function Notice.showing(): number
	return showingCount
end

function Notice.setShowing(value: number?)
	local clean = if type(value) == "number" and value == value and value > 0 then math.floor(value) else 0
	if clean == showingCount then
		return
	end
	showingCount = clean
	local event = showingSignal
	if event then
		event:Fire()
	end
end

function Notice.onShowing(fn: () -> ()): RBXScriptConnection
	local event = showingSignal or Instance.new("BindableEvent")
	showingSignal = event
	return event.Event:Connect(fn)
end

--==============================================================================
-- WHAT ELSE STANDS IN THE NOTICES' BAND (2026-10-12)
--
-- The notices hang at the top centre on every screen (HudLayout.toastUnderRow).
-- What else may stand in that band says so here, by the GuiObject it draws:
--
--   "above"  the notices stack UNDER it while it shows -- the guide's card and
--            the spotlight's words, a desktop's Pod Rush tracker and mill bar,
--            an admin announcement
--   "over"   it wins: a notice it would meet gives way (GiveWaySeconds) and
--            comes back when it has gone, if its time is not up -- the chase
--            word, CONGRATULATIONS!, REBORN!, the invite and chest cards, the
--            Pod Rush end card, the Mysterious Pod's draw
--
-- What gives way to the notices instead (a phone's guide card, tracker and
-- mill bar) reads `showing` and `reach`. Each rect is asked live -- the
-- object's AbsolutePosition and AbsoluteSize, one space for every ScreenGui --
-- and only while the object draws: Visible all the way up, its ScreenGui
-- enabled. nil takes a key off. Made on first use, like `reach`.
--==============================================================================
export type BandKind = "above" | "over"
export type BandRect = { x: number, y: number, w: number, h: number }

local bandEntries: { [string]: { kind: BandKind, object: GuiObject } } = {}
local bandSignal: BindableEvent? = nil

function Notice.band(key: string, kind: BandKind, object: GuiObject?)
	local was = bandEntries[key]
	if object then
		if was and was.object == object and was.kind == kind then
			return
		end
		bandEntries[key] = { kind = kind, object = object }
	elseif was then
		bandEntries[key] = nil
	else
		return
	end
	local event = bandSignal
	if event then
		event:Fire()
	end
end

-- Whether `object` is drawn now: in the place, its ScreenGui enabled, it and
-- every GuiObject over it Visible, with some size -- and a label or a picture
-- not faded all the way out (the chase word stays Visible at transparency 1).
function Notice.drawn(object: GuiObject): boolean
	local layer = object:FindFirstAncestorWhichIsA("LayerCollector")
	if not layer or (layer:IsA("ScreenGui") and not layer.Enabled) then
		return false
	end
	local any = object :: any
	if (object:IsA("TextLabel") or object:IsA("TextButton"))
		and any.TextTransparency >= 1 and any.BackgroundTransparency >= 1 then
		return false
	elseif (object:IsA("ImageLabel") or object:IsA("ImageButton"))
		and any.ImageTransparency >= 1 and any.BackgroundTransparency >= 1 then
		return false
	end
	local at: Instance? = object
	while at and at ~= layer do
		if at:IsA("GuiObject") and not at.Visible then
			return false
		end
		at = at.Parent
	end
	return object.AbsoluteSize.X > 0 and object.AbsoluteSize.Y > 0
end

-- The rects of one kind standing now, in AbsolutePosition's space.
function Notice.bandRects(kind: BandKind): { BandRect }
	local out: { BandRect } = {}
	for _, entry in pairs(bandEntries) do
		if entry.kind == kind and Notice.drawn(entry.object) then
			local p, s = entry.object.AbsolutePosition, entry.object.AbsoluteSize
			table.insert(out, { x = p.X, y = p.Y, w = s.X, h = s.Y })
		end
	end
	return out
end

function Notice.onBand(fn: () -> ()): RBXScriptConnection
	local event = bandSignal or Instance.new("BindableEvent")
	bandSignal = event
	return event.Event:Connect(fn)
end

--==============================================================================
-- GIVING WAY TO THE NOTICES (2026-10-12)
--
-- What steps aside for a notice -- a phone's guide card, Pod Rush tracker and
-- mill bar -- calls giveWay(root, true) while one is up and giveWay(root,
-- false) after: everything under `root` fades out over GiveWaySeconds and the
-- whole of it slides up GiveWayPixels, then back the same way. The slide moves
-- the AnchorPoint, never the Position, so the element's own placement is never
-- written over; Reduced Motion (`still`) keeps the fade alone. Each resting
-- transparency is read as it starts, so it comes back exactly as it was.
--==============================================================================
local TRANSPARENT: { [string]: { string } } = {
	Frame = { "BackgroundTransparency" },
	TextLabel = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	TextButton = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	ImageLabel = { "BackgroundTransparency", "ImageTransparency" },
	ImageButton = { "BackgroundTransparency", "ImageTransparency" },
	ViewportFrame = { "BackgroundTransparency", "ImageTransparency" },
	UIStroke = { "Transparency" },
}

type GiveWayState = {
	on: boolean,
	-- True once the last return has finished: only then are the resting values
	-- read again. Read mid-tween they would be half-faded and half-slid, and a
	-- quick step-aside, back, step-aside would drift (seen in Play, 2026-10-12).
	settled: boolean,
	turn: number,
	rest: { { target: Instance, prop: string, value: number } },
	anchor: Vector2,
}
local givingWay: { [Instance]: GiveWayState } = setmetatable({} :: any, { __mode = "k" })

function Notice.giveWay(root: GuiObject, on: boolean, still: boolean?)
	local state = givingWay[root]
	if not state then
		if not on then
			return
		end
		state = { on = false, settled = true, turn = 0, rest = {}, anchor = root.AnchorPoint }
		givingWay[root] = state
	end
	if state.on == on then
		return
	end
	state.on = on
	state.turn += 1
	local turn = state.turn
	local TweenService = game:GetService("TweenService")
	local info = TweenInfo.new(Notice.GiveWaySeconds * Notice.TimeScale, Enum.EasingStyle.Quad,
		if on then Enum.EasingDirection.In else Enum.EasingDirection.Out)
	if on then
		if state.settled then
			state.settled = false
			state.rest = {}
			state.anchor = root.AnchorPoint
			local all = root:GetDescendants()
			table.insert(all, root)
			for _, target in ipairs(all) do
				for _, prop in ipairs(TRANSPARENT[target.ClassName] or {}) do
					local value = (target :: any)[prop]
					if value < 1 then
						table.insert(state.rest, { target = target, prop = prop, value = value })
					end
				end
			end
		end
		for _, rest in ipairs(state.rest) do
			if rest.target.Parent then
				TweenService:Create(rest.target, info, { [rest.prop] = 1 }):Play()
			end
		end
		local tall = root.AbsoluteSize.Y
		if not still and tall > 0 then
			TweenService:Create(root, info, {
				AnchorPoint = state.anchor + Vector2.new(0, Notice.GiveWayPixels / tall),
			}):Play()
		end
	else
		for _, rest in ipairs(state.rest) do
			if rest.target.Parent then
				TweenService:Create(rest.target, info, { [rest.prop] = rest.value }):Play()
			end
		end
		local back = TweenService:Create(root, info, { AnchorPoint = state.anchor })
		back.Completed:Once(function(status: Enum.PlaybackState)
			if status == Enum.PlaybackState.Completed and state.turn == turn then
				state.settled = true
			end
		end)
		back:Play()
	end
end

return Notice
