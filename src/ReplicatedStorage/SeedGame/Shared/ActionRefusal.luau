--!strict
--==============================================================================
-- Steal a Seed :: ActionRefusal
--
-- The one short line the game says when it refuses something a player has just
-- tried, and the rules for saying it. Names, words and plain functions only --
-- no remote, no instance on the server, no clock of its own -- so the server can
-- name a reason, the client can draw it, and ActionRefusalSpec can drive every
-- rule here without a Play session.
--
--==============================================================================
-- THE SERVER DECIDES. THIS ONLY EXPLAINS.
--
-- Every code below is sent by the guard that already refused the action, after
-- it refused, and nothing anywhere reads a code to decide what happens. The
-- guards keep their order and their outcomes; a code is a caption on a refusal
-- that was going to happen anyway.
--
-- ONLY REASONS A PLAYER CAN ACT ON ARE NAMED. A refusal with no code keeps its
-- old behaviour exactly -- silence, or the bare denial sound it always made. A
-- malformed request, a missing profile, a body mid-respawn, a trap tool with no
-- spec: none of those is a normal player action, and none of them gets a line.
--
-- TWO LINES FROM THE BRIEF ARE DELIBERATELY ABSENT (2026-09-23):
--
--   "That plant belongs to another player."  Nothing lets a player TRY to pick
--       up a neighbour's plant. There is no pickup prompt (see THERE IS NO
--       PICKUP PROMPT in PlantService); PlantPickUI answers only your own
--       plants, and the Garden panel lists only yours. A line with no attempt to
--       attach it to would need a control invented to trigger it.
--   "Your Bag is full."  Nothing refuses on the size of the BAG. The hotbar's
--       5/5 or 10/10 is the strip's slots, "a fact, not a fault", and a rebuild
--       is handed over without being counted.
--
-- WHAT IS REFUSED IS WHAT THE SAVED RECORD HAS NO ROOM FOR (2026-09-29). The
-- record holds SAVE.MaxHeld plants and pods, and anything handed over past it
-- used to be given and never saved -- gone at the next death or rejoin. The
-- owner's decisions: "refuse the hatch and leave the pod planted and ready
-- until the player makes room"; a pickup and a banked pod "must not hand over
-- an item that cannot be saved"; a purchase of an instant hatch that finds no
-- room makes "its intended pod ready immediately" instead; and one that finds
-- that pod's wait already over is kept as a credit (2026-09-30), as is one
-- that finds no unhatched pod at all. The lines:
--
--   STORAGE_FULL           a hatch, a pickup, or a pod at a nest: refused
--   STORAGE_FULL_BANK      a pod at the red line: it stays in the arms
--   STORAGE_FULL_READY     an instant hatch that was paid for: the pod is ready
--   STORAGE_FULL_CREDIT    an instant hatch that was paid for, and no wait left
--                          to end: saved, and the next one is free
--   INSTANT_CREDIT_NO_POD  an instant hatch that was paid for, and no pod to
--                          hatch: saved, and the next one is free
--   INSTANT_CREDIT_READY   an instant hatch that was paid for, and its pod (or
--                          every pod) already ready: saved; they hatch free
--   INSTANT_CREDIT_SAVED   an instant hatch that was paid for, with no pod it
--                          can be told was bought for: saved for any pod
--   INSTANT_CREDIT_USED    that saved instant hatch, spent on a hatch
--==============================================================================

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local Notice = require(script.Parent:WaitForChild("Notice"))

local ActionRefusal = {}

-- How many plants and pods the saved record holds: the number in the storage
-- lines below.
local MAX_HELD: number = GameConfig.Save.MaxHeld

-- Server -> client, on the GameEvent remote every client already listens to,
-- carrying one code from `Text` and nothing else.
ActionRefusal.Action = "ActionRefused"

--==============================================================================
-- THE WORDS, BY CODE
--
-- Short enough for the compact face: HudLayoutSpec measures every one of these
-- against the toast's width on every listed phone.
--==============================================================================
ActionRefusal.Text = {
	-- A swing that reached a player the Safe Zone protects. Never for a miss, a
	-- wall or a swing on cooldown -- see forSwing.
	SAFE_ZONE_TARGET = "Players are protected in the Safe Zone.",
	-- Trying to set a trap while standing in the Safe Zone.
	TRAP_SAFE_ZONE = "Place traps outside the Safe Zone.",
	-- Clicking your own bed from beyond planting reach.
	PLANT_OUT_OF_RANGE = "Move closer to your plot.",
	-- Planting into a plot that holds as many plants as its level allows.
	PLOT_FULL = "Your plot is full.",
	-- Something the carry rule blocks while a raided pod is in your arms: taking
	-- a second pod, or putting a plant in your hands.
	CARRYING_POD = "Bank your pod before doing that.",
	-- Trying to set a trap before the last one's placement cooldown is over.
	TRAP_COOLDOWN = "Trap recharging…",

	--==========================================================================
	-- TELEPORT TO PLOT (PlotService.TeleportHome), 2026-09-23
	--
	-- The button only shows in the Safe Zone, alive, with a plot; these are for
	-- a press the server refuses anyway -- a stale one from a player who has just
	-- stepped onto the road, a second one inside the cooldown, a player who is
	-- held. A dead or respawning body is not a player action and says nothing.
	--==========================================================================
	TELEPORT_OUTSIDE = "Teleport works only in the Safe Zone.",
	TELEPORT_NO_PLOT = "You don't have a plot yet.",
	TELEPORT_STUNNED = "Wait until you can move again.",
	TELEPORT_COOLDOWN = "Teleport recharging…",
	TELEPORT_BLOCKED = "Your plot isn't ready yet.",

	-- A FULL PLOT, BY WHAT CAN STILL BE DONE ABOUT IT (2026-09-27). The same
	-- sentence as PLOT_FULL; the toast's next step differs (see Notices), and
	-- plotFull picks the code.
	PLOT_FULL_MAX = "Your plot is full.",
	PLOT_FULL_GROWING = "Your plot is full.",
	PLOT_FULL_WAIT = "Your plot is full.",

	--==========================================================================
	-- THE FLOATING GARDEN (ObbyService.Begin), 2026-09-27
	--
	-- The Start prompt stands in the Safe Zone, so a chase has already been
	-- given up by the time anybody reaches it; OBBY_CHASED is the second or two
	-- before the pursuit count clears. A raided pod reuses CARRYING_POD, since
	-- banking it is the same next step. A trap set ON the course is refused
	-- with its own line, because "outside the Safe Zone" would be true and no
	-- help.
	--==========================================================================
	OBBY_CHASED = "Wait for the chase to end.",
	OBBY_STUNNED = "Wait until you can move again.",
	TRAP_OBBY = "Traps don't work on the course.",
	-- The OBBY button's teleport (2026-09-27) shares TELEPORT TO PLOT's codes
	-- word for word, except a landing with no ground under it: that is the
	-- course's entrance, not the player's plot.
	OBBY_BLOCKED = "The obby entrance isn't ready yet.",
	-- The BIOMES button's teleport (2026-09-30), likewise: TELEPORT TO PLOT's
	-- codes, and this one for a Greenhollow entrance with no ground under it.
	BIOMES_BLOCKED = "The road isn't ready yet.",

	--==========================================================================
	-- PLANT STORAGE (CarryService.HeldRoom), 2026-09-29
	--
	-- What the saved record has no room for: a hatch (the held prompt on a ready
	-- pod, and the Instant Hatch key, which then opens no purchase), a pickup,
	-- a pod at a nest and a pod at the red line. The number is the limit's own,
	-- so the words cannot say one thing and the rule another.
	-- STORAGE_FULL_READY and STORAGE_FULL_CREDIT are a receipt that found the
	-- record full -- it filled after the purchase dialog opened, or Roblox
	-- delivered the receipt again. INSTANT_CREDIT_NO_POD is a receipt that
	-- found no pod to hatch (2026-09-30), INSTANT_CREDIT_READY one whose pod
	-- (or every pod) was already ready, and INSTANT_CREDIT_SAVED one that named
	-- no pod it can still hatch while others grow. INSTANT_CREDIT_USED is the
	-- credit spent.
	--==========================================================================
	STORAGE_FULL = string.format("Plant storage full (%d/%d).", MAX_HELD, MAX_HELD),
	STORAGE_FULL_BANK = string.format("Plant storage full (%d/%d).", MAX_HELD, MAX_HELD),
	STORAGE_FULL_READY = "Pod ready. Make room to hatch it free.",
	STORAGE_FULL_CREDIT = "Instant Hatch saved: next one is free.",
	INSTANT_CREDIT_NO_POD = "Instant Hatch saved for later.",
	INSTANT_CREDIT_READY = "Instant Hatch saved: pods are ready.",
	INSTANT_CREDIT_SAVED = "Instant Hatch saved for any pod.",
	INSTANT_CREDIT_USED = "Saved Instant Hatch used.",
}

--==============================================================================
-- WHAT THE TOAST SHOWS, BY CODE (2026-09-27)
--
-- A headline and, under it, the next step that ACTUALLY WORKS for that reason.
-- `Text` above stays the one plain sentence -- the controller reticle reads it
-- out under the crosshair as a live reason, which is a different job.
--
-- Where no next step is true for every player who can hit the refusal, there is
-- no detail line rather than a hopeful one: TRAP_COOLDOWN, TELEPORT_COOLDOWN,
-- TELEPORT_NO_PLOT (queued behind a full server) and TELEPORT_BLOCKED (a spawn
-- with nothing to stand on) have nothing the player can do but wait.
--
-- A FULL PLOT has four, because what makes room depends on the plot:
--
--   PLOT_FULL           a grown plant to pick up, and a level still to buy
--   PLOT_FULL_MAX       a grown plant to pick up; the plot is at its top level
--   PLOT_FULL_GROWING   nothing grown yet (only grown plants can be picked
--                       up -- PlantService.pickUp); a level still to buy
--   PLOT_FULL_WAIT      nothing grown yet, and nothing left to buy
--==============================================================================
-- `kind` is how the notice looks and sounds (Notice.Styles). A refusal is
-- "blocked" and needs none; a line here that is not a refusal names its own.
export type Line = { title: string, detail: string?, kind: Notice.Kind? }

ActionRefusal.Notices = {
	SAFE_ZONE_TARGET = { title = "SAFE ZONE", detail = "Players here can't be hit." },
	TRAP_SAFE_ZONE = { title = "NO TRAPS HERE", detail = "Set traps outside the Safe Zone." },
	PLANT_OUT_OF_RANGE = { title = "TOO FAR AWAY", detail = "Move closer to your plot." },
	PLOT_FULL = { title = "GARDEN FULL", detail = "Pick up a plant or upgrade your plot." },
	PLOT_FULL_MAX = { title = "GARDEN FULL", detail = "Pick up a grown plant to make room." },
	PLOT_FULL_GROWING = { title = "GARDEN FULL", detail = "Upgrade your plot for more room." },
	PLOT_FULL_WAIT = { title = "GARDEN FULL", detail = "Pick one up once it has grown." },
	CARRYING_POD = { title = "CARRYING A POD", detail = "Bank it at your plot first." },
	TRAP_COOLDOWN = { title = "TRAP RECHARGING" },
	TELEPORT_OUTSIDE = { title = "CAN'T TELEPORT HERE", detail = "Teleport works only in the Safe Zone." },
	TELEPORT_NO_PLOT = { title = "NO PLOT YET" },
	TELEPORT_STUNNED = { title = "CAN'T TELEPORT YET", detail = "Wait until you can move again." },
	TELEPORT_COOLDOWN = { title = "TELEPORT RECHARGING" },
	TELEPORT_BLOCKED = { title = "PLOT NOT READY" },
	OBBY_CHASED = { title = "STILL BEING CHASED", detail = "Wait for the chase to end." },
	OBBY_STUNNED = { title = "CAN'T START YET", detail = "Wait until you can move again." },
	TRAP_OBBY = { title = "NO TRAPS HERE", detail = "Traps don't work on the course." },
	OBBY_BLOCKED = { title = "OBBY NOT READY" },
	BIOMES_BLOCKED = { title = "ROAD NOT READY" },
	-- PLANT STORAGE FULL, 24/24: the headline is held to twenty characters like
	-- every other, so the count leads the line under it. What makes room is what
	-- takes a plant or a pod out of the bag: putting it in the ground, or
	-- selling it.
	STORAGE_FULL = {
		title = "PLANT STORAGE FULL",
		detail = string.format("%d/%d. Plant or sell one to make room.", MAX_HELD, MAX_HELD),
	},
	-- A pod at the red line: it stays in the arms, and is banked by itself the
	-- moment there is room. It does not say "make room": with a pod in the
	-- arms nothing can be planted or sold, so that is not theirs to do yet.
	STORAGE_FULL_BANK = {
		title = "PLANT STORAGE FULL",
		detail = string.format("%d/%d. Your pod is banked when there is room.", MAX_HELD, MAX_HELD),
	},
	-- THE PURCHASE WAS USED: it ended the pod's wait. Not a refusal, so not red:
	-- the player is told the storage is full AND what they now have.
	STORAGE_FULL_READY = {
		title = "PLANT STORAGE FULL",
		detail = "Your pod is ready. Make room to hatch it free.",
		kind = "warning",
	},
	-- THE PURCHASE WAS KEPT: there was no wait left to end, so it is saved as a
	-- credit, and the next Instant Hatch that works costs nothing. Not a
	-- refusal either: the player is told what their purchase became.
	STORAGE_FULL_CREDIT = {
		title = "PLANT STORAGE FULL",
		detail = "Instant Hatch saved. Your next one is free.",
		kind = "warning",
	},
	-- THE PURCHASE WAS KEPT, with nothing wrong: no unhatched pod for it to
	-- open (it hatched while the dialog was open, or Roblox delivered the
	-- receipt again before the garden was back), so it is saved as a credit.
	-- News, not a warning.
	INSTANT_CREDIT_NO_POD = {
		title = "INSTANT HATCH SAVED",
		detail = "Nothing to hatch now. Your next one is free.",
		kind = "info",
	},
	-- THE PURCHASE WAS KEPT BECAUSE ITS POD WAS ALREADY READY (the pressed pod,
	-- or every pod): a ready pod hatches free, so the purchase is saved for one
	-- with time left, and the line says both. News, not a warning.
	INSTANT_CREDIT_READY = {
		title = "INSTANT HATCH SAVED",
		detail = "Ready pods hatch free. Your next one is free.",
		kind = "info",
	},
	-- THE PURCHASE WAS KEPT BECAUSE NO POD CAN BE TOLD IT WAS BOUGHT FOR (2026-09-30):
	-- a receipt delivered again with no note, or its pod gone, while other pods
	-- still grow. The owner's rule: never switch it to another pod. Saved, and
	-- any growing pod's Instant Hatch is now free.
	INSTANT_CREDIT_SAVED = {
		title = "INSTANT HATCH SAVED",
		detail = "Your next Instant Hatch is free.",
		kind = "info",
	},
	-- The saved one, spent: said so that a hatch with no purchase dialog is not
	-- mistaken for one that was charged.
	INSTANT_CREDIT_USED = {
		title = "INSTANT HATCH",
		detail = "Your saved Instant Hatch was used.",
		kind = "success",
	},
} :: { [string]: Line }

-- Which full-plot code: `canUpgrade` -- the plot is below its top level;
-- `hasGrown` -- at least one of the player's plants there is grown.
function ActionRefusal.plotFull(canUpgrade: boolean, hasGrown: boolean): string
	if hasGrown then
		return if canUpgrade then "PLOT_FULL" else "PLOT_FULL_MAX"
	end
	return if canUpgrade then "PLOT_FULL_GROWING" else "PLOT_FULL_WAIT"
end

-- The notice a refusal code puts up, or nil for a code nobody named.
function ActionRefusal.notice(code: string): Notice.Post?
	local line = if type(code) == "string" then ActionRefusal.Notices[code] else nil
	if not line then
		return nil
	end
	return {
		kind = line.kind or "blocked",
		title = line.title,
		detail = line.detail,
		key = "refusal:" .. code,
	}
end

--==============================================================================
-- PLANTING: PlaceAt names its guard; two of them are the player's to fix
--
-- OUT_OF_RANGE comes BEFORE BED_FULL in PlaceAt, so a click from too far away on
-- a full plot says "move closer" -- the guard order decides which line, exactly
-- as it decides the outcome. Every other PlaceAt code (NO_PLOT, NO_PROFILE,
-- NO_SOIL, NO_CHARACTER, NO_TOOL, UNKNOWN_SPECIES) is internal and says nothing.
--==============================================================================
local FROM_PLACEMENT: { [string]: string } = {
	OUT_OF_RANGE = "PLANT_OUT_OF_RANGE",
	BED_FULL = "PLOT_FULL",
}

function ActionRefusal.fromPlacement(code: string?): string?
	if type(code) ~= "string" then
		return nil
	end
	return FROM_PLACEMENT[code]
end

--==============================================================================
-- A SWING: ONLY THE SAFE ZONE SPEAKS
--
-- `hits` is how many players the swing actually struck; `spared` is whether
-- the Safe Zone withheld somebody the swing would otherwise have reached -- in
-- reach, in the arc, at the right height, not behind a wall, not already
-- immune, flying or ragdolled. A swing that struck anybody says nothing. A swing
-- that reached nobody -- a miss, or a player behind a wall -- says nothing. A
-- swing on cooldown never starts, so it never gets this far.
--==============================================================================
function ActionRefusal.forSwing(hits: number, spared: boolean): string?
	if hits == 0 and spared then
		return "SAFE_ZONE_TARGET"
	end
	return nil
end

--==============================================================================
-- ONE TOAST PER REASON, AND WHAT A REPEAT DOES TO IT
--
-- The rule is Notice.step, shared with every other notice the game shows: the
-- same refusal again while it is up only stays up longer -- no sound, no new
-- animation, nothing stacked -- which is what keeps a mashed button from
-- turning into a drum roll. A different refusal goes up beside it in the small
-- stack, and the one due to leave first makes room. Every refusal of one code
-- is one notice (`notice` keys it by code), whatever its words.
--==============================================================================

--==============================================================================
-- SENDING ONE: SERVER ONLY
--
-- Called by a guard that has ALREADY refused, on its way out; this decides
-- nothing. A code nobody named in `Text` is dropped here, so nothing internal
-- can reach a player's screen by accident. Here rather than in a server module
-- so that every service that sends one needs no new sibling -- the specs load
-- those services against a fixed list of stand-in siblings, and Shared modules
-- resolve to the real thing there.
--
-- RATE LIMITED PER PLAYER AND CODE, gently. The toast already folds a repeated
-- line into one; this only keeps a player clicking their bed from across the
-- plot from sending the same few bytes thirty times a second.
--==============================================================================
local QUIET_SECONDS = 0.25
-- Weak keys, so a player who leaves is collected without a hook to forget them.
local lastSent: { [any]: { [string]: number } } = setmetatable({}, { __mode = "k" }) :: any
local remote: RemoteEvent? = nil
local capture: ((any, string) -> ())? = nil

local function resolveRemote(): RemoteEvent?
	local known = remote
	if known and known.Parent then
		return known
	end
	local seedGame = game:GetService("ReplicatedStorage"):FindFirstChild("SeedGame")
	local remotes = if seedGame then seedGame:FindFirstChild("Remotes") else nil
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		remote = found
		return found
	end
	return nil
end

function ActionRefusal.send(player: Player, code: string)
	if ActionRefusal.Text[code] == nil then
		return
	end
	local hook = capture
	if hook then
		hook(player, code)
		return
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player")
		or player.Parent ~= game:GetService("Players") then
		return
	end
	local now = os.clock()
	local seen = lastSent[player]
	if not seen then
		seen = {}
		lastSent[player] = seen
	end
	if now - (seen[code] or -math.huge) < QUIET_SECONDS then
		return
	end
	seen[code] = now
	local channel = resolveRemote()
	if not channel then
		return
	end
	pcall(function()
		channel:FireClient(player, ActionRefusal.Action, code)
	end)
end

-- SPECS ONLY. Routes every named refusal to `fn` instead of the wire, so a spec
-- can call the real guards with stand-in players and read back what they said.
-- nil puts the wire back.
function ActionRefusal.capture(fn: ((any, string) -> ())?)
	capture = fn
end

--==============================================================================
-- A REFUSAL THE CLIENT ALREADY KNOWS
--
-- One rule is enforced on the client before anything is sent: LoadoutUI will not
-- put a plant in your hands while a raided pod is in your arms (and CarryService
-- would put it straight back). The reason there is the server's own replicated
-- CarryingSpecies attribute, not a guess, so the line is raised locally rather
-- than inventing a round trip. Client only: it goes straight to the notice
-- renderer, exactly as the server's code does when it arrives.
--==============================================================================
function ActionRefusal.raise(code: string)
	local post = ActionRefusal.notice(code)
	if post then
		Notice.post(post)
	end
end

return ActionRefusal
