--!strict
-- Steal a Seed :: PlotService
--
-- Decides who owns which patch of ground, and puts them on it.
--
--==============================================================================
-- A PLOT IS A LEASE ON THIS SERVER, NOT A PROPERTY OF AN ACCOUNT
--
-- Stated before the code because the save schema hangs off it: WHICH plot you
-- get is never saved. It is a slot in this server, handed out on arrival and
-- handed back on departure.
--
-- What persists is what is ON a plot -- its tier, and later its plants --
-- restored onto whichever patch of ground the lease gave you this session.
-- Saving the plot id instead buys nothing and costs plenty: a returning player
-- either waits for "their" plot while three others sit empty, or is quietly
-- given a different one anyway, which is this behaviour with an extra field to
-- keep in step. And a stored plot id is a POINTER INTO THE MAP, while the map
-- is code that moves every time the geometry does.
--
--==============================================================================
-- NOBODY SHOPS FOR A PLOT
--
-- The lowest-numbered free one, the moment you join. No claim prompt, no
-- walking up to a board, no choosing. An UNCLAIMED sign was built once and
-- removed, because picking a plot is a decision with no inputs: they are
-- identical, so the only thing a player learns by choosing is that the game
-- made them do paperwork before it let them play.
--
--==============================================================================
-- MORE PLAYERS THAN PLOTS IS THE NORMAL CASE, NOT THE ERROR CASE
--
-- `Players.MaxPlayers` is a place setting a script cannot change, and it is 60
-- against six plots until somebody opens Game Settings. ServerMain shouts about
-- that at every boot; this service has to actually cope with it.
--
-- So: a join-ordered queue. No plot means you spawn on the overflow pad in the
-- hub and take the next one that frees, in the order you arrived. Not a kick,
-- and not a random draw when one opens -- both punish a player for a setting
-- they cannot see.
--
--==============================================================================
-- A LEASE THAT ENDS RETURNS THE GROUND EMPTY
--
-- Releasing clears the plot's Plants and Runtime folders, because the next
-- player handed it must not inherit the last one's crop. That is the invariant
-- this service owns and nothing else can: any service that puts something on a
-- plot puts it in one of those two folders, and gets cleanup for free.
--
-- WHEN TIERS SHIP (Phase D) RELEASE GAINS ONE MORE JOB. A plot left at tier 3
-- is the wrong SHAPE for an arriving player whose save says tier 1, so handover
-- will have to rebuild it. Today every plot is built at StartingPlotTier and
-- nothing ever changes that, so there is nothing to rebuild -- but this is the
-- function that will have to know.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))
local MapService = require(script.Parent:WaitForChild("MapService"))

local PLOT = GameConfig.Plot
local ATTR = GameConfig.Attributes

local PlotService = {}
-- After MapService (1), which builds the ground this hands out. Before anything
-- that wants to know whose plot is whose.
PlotService.Priority = 10

local function log(message: string)
	print("[Seed/PlotService] " .. message)
end

--==============================================================================
-- STATE
--
-- Two tables pointing at each other rather than one and a scan. Both directions
-- get asked constantly -- "where does this player build" and "who owns this
-- ground" -- and a linear search for the second is the kind of thing that is
-- invisible at six plots and embarrassing later.
--==============================================================================
local plotsById: { [number]: Model } = {}
-- Ascending plot ids. GetChildren order is not defined, and "the first free
-- plot" has to mean the same thing on every server or two players comparing
-- notes get different answers.
local plotOrder: { number } = {}

local ownerOf: { [number]: Player } = {}
local plotOf: { [Player]: number } = {}
-- Join-ordered. Index 1 is next.
local waiting: { Player } = {}

local connections: { [Player]: { RBXScriptConnection } } = {}
-- The service's OWN signal connections, kept so Init can drop them. Without
-- this, calling Start twice -- which Rule 10 says has to be safe, and which is
-- exactly what tuning in Edit does -- leaves the previous run's PlayerAdded
-- still connected. They accumulate silently: nothing misbehaves visibly,
-- because onPlayerAdded is idempotent, but every re-run adds another listener
-- that never goes away.
local serviceConnections: { RBXScriptConnection } = {}

--==============================================================================
-- WHAT LEVEL EACH PLAYER'S PLOT SHOULD BE, WHICH IS NOT WHAT IT IS
--
-- A plot is handed out the instant a player joins. Their profile arrives from
-- the DataStore seconds later. So for those seconds the server knows the player
-- owns a plot but not how big it is, and the plot is standing there at whatever
-- size its last owner left it.
--
-- This table is the answer to that: PlayerDataService writes the level here the
-- moment the profile lands, and PlotUpgradeService writes it again on a
-- purchase. Either way the write goes through SetDesiredLevel, which rebuilds
-- the plot if it is already assigned and simply remembers if it is not.
--
-- The remembering is the important half. A player who joins into a FULL server
-- waits in the queue with no plot at all; their profile still loads, their
-- level is still recorded, and when a plot frees up they are given it at the
-- right size in one build -- not handed a Level 1 plot that visibly grows a
-- moment later.
--==============================================================================
local desiredLevel: { [Player]: number } = {}

type Listener = (player: Player, plot: Model) -> ()
local onAssigned: { Listener } = {}
local onReleased: { Listener } = {}
-- Fired either side of a live rebuild, so PlantService can carry the garden
-- across it. PlotService cannot require PlantService -- PlantService requires
-- THIS -- so the dependency is inverted into these two lists.
local onResizing: { Listener } = {}
local onResized: { Listener } = {}

local function fire(listeners: { Listener }, player: Player, plot: Model)
	for _, fn in ipairs(listeners) do
		-- pcall'd for the same reason ServerMain pcalls a service: one bad
		-- listener must not be able to stop a player being given a plot.
		local ok, err = pcall(fn, player, plot)
		if not ok then
			warn("[Seed/PlotService] listener failed: " .. tostring(err))
		end
	end
end

--==============================================================================
-- READ API
--==============================================================================
function PlotService.PlotOf(player: Player): Model?
	local id = plotOf[player]
	return if id then plotsById[id] else nil
end

function PlotService.OwnerOf(plot: Model): Player?
	local id = plot:GetAttribute(ATTR.PlotId)
	return if type(id) == "number" then ownerOf[id] else nil
end

-- 0 means "has a plot". 1 means "next".
function PlotService.QueuePosition(player: Player): number
	return table.find(waiting, player) or 0
end

-- Where a character standing on this plot goes. Never nil: a plot you cannot be
-- put on is worse than a plot you are put on slightly wrong.
function PlotService.SpawnCFrameFor(plot: Model): CFrame
	local lift = Vector3.new(0, PLOT.SpawnHeightOffset, 0)
	local pad = plot:FindFirstChild(PLOT.SpawnPadName)
	if pad and pad:IsA("BasePart") then
		-- Added in WORLD space rather than composed. The pad inherits the plot's
		-- yaw, so its LookVector already points at the hub and you spawn facing
		-- out through your own gate toward the road; composing a local offset
		-- would start mattering the day a plot is built on a slope.
		return pad.CFrame + lift
	end
	return plot:GetPivot() + lift
end

function PlotService.OnAssigned(fn: Listener): () -> ()
	table.insert(onAssigned, fn)
	return function()
		local i = table.find(onAssigned, fn)
		if i then
			table.remove(onAssigned, i)
		end
	end
end

function PlotService.OnReleased(fn: Listener): () -> ()
	table.insert(onReleased, fn)
	return function()
		local i = table.find(onReleased, fn)
		if i then
			table.remove(onReleased, i)
		end
	end
end

-- Called with the plot ABOUT to be rebuilt, while its old geometry still
-- stands. The last chance to read anything measured against it.
function PlotService.OnResizing(fn: Listener): () -> ()
	table.insert(onResizing, fn)
	return function()
		local i = table.find(onResizing, fn)
		if i then
			table.remove(onResizing, i)
		end
	end
end

-- Called with the new geometry in place, same frame.
function PlotService.OnResized(fn: Listener): () -> ()
	table.insert(onResized, fn)
	return function()
		local i = table.find(onResized, fn)
		if i then
			table.remove(onResized, i)
		end
	end
end

--==============================================================================
-- WHAT LEVEL THIS PLOT IS
--==============================================================================
function PlotService.LevelOf(plot: Model): number
	local n = tonumber(plot:GetAttribute("Level"))
	if n == nil or n ~= n then
		return GameConfig.StartingPlotTier
	end
	return math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)
end

--==============================================================================
-- PLACEMENT IS PivotTo, NOT RespawnLocation
--
-- RespawnLocation is set as well, because it is one line and it means the
-- engine usually puts a character in roughly the right place to begin with
-- rather than at the origin. It is not what this service RELIES on:
--
--   * It only works for plots. A queued player's destination is a marker Part
--     on the hub deck, not a SpawnLocation, so RespawnLocation cannot express
--     it at all. PivotTo covers both, and one mechanism that handles every case
--     beats two that each handle half.
--   * The plot pads are deliberately built `Enabled = false` -- six enabled
--     spawns on one field would scatter players through other people's gardens
--     any time RespawnLocation was not honoured. Whether the engine still
--     respects a disabled pad as an explicit RespawnLocation is a detail no
--     player's spawn should be resting on.
--
-- The pivot runs after HumanoidRootPart exists, which is after the engine has
-- finished placing the character -- so it corrects rather than races.
--==============================================================================
--
-- SPAWNED, NEVER INLINE, because this function YIELDS: a character can be
-- parented before its HumanoidRootPart exists, so the WaitForChild below is
-- real and can burn five seconds. Called inline from `assign` that would mean
-- the lease's listeners and the client notification wait behind a character
-- that may never finish loading -- and worse, `drainQueue` assigns in a LOOP,
-- so one slow character would stall every other queued player behind it. It
-- would also open a yield in the middle of assignment, letting a release run
-- and mutate the queue half way through draining it.
--
-- Placement is not part of the lease. It can take as long as it takes.
local function placeCharacter(player: Player, character: Model)
	task.spawn(function()
		local root = character:FindFirstChild("HumanoidRootPart")
			or character:WaitForChild("HumanoidRootPart", 5)
		-- Either of those can come back with the player already gone.
		if not root or character.Parent == nil or player.Parent ~= Players then
			return
		end

		local plot = PlotService.PlotOf(player)
		local target = if plot
			then PlotService.SpawnCFrameFor(plot)
			else MapService.GetOverflowCFrame()

		local ok, err = pcall(function()
			character:PivotTo(target)
		end)
		if not ok then
			warn(string.format("[Seed/PlotService] could not place %s: %s",
				player.Name, tostring(err)))
		end
	end)
end

--==============================================================================
-- TELLING THE CLIENT
--
-- One payload for both states, because they are the same question: what ground
-- do I have. `plot` is nil while queued and `position` says how long the wait
-- is; `position` is 0 once you have one.
--==============================================================================
local plotAssignedRemote: RemoteEvent? = nil

--
-- pcall'd, and called LAST by everything that changes a lease. Telling the
-- client is a notification, not part of the transaction, and a notification
-- that throws must never leave an assignment half-applied -- attributes
-- stamped, tables updated, listeners never run. That is not hypothetical: this
-- exact call throws in the Edit datamodel, where FireClient refuses to run
-- because IsServer() is false.
local function pushState(player: Player)
	local remote = plotAssignedRemote
	if not remote or player.Parent ~= Players then
		return
	end
	local ok, err = pcall(function()
		remote:FireClient(player, PlotService.PlotOf(player), PlotService.QueuePosition(player))
	end)
	if not ok then
		warn(string.format("[Seed/PlotService] could not tell %s about their plot: %s",
			player.Name, tostring(err)))
	end
end

--==============================================================================
-- ASSIGN / RELEASE
--==============================================================================
local function firstFreePlotId(): number?
	for _, id in ipairs(plotOrder) do
		if not ownerOf[id] then
			return id
		end
	end
	return nil
end

--==============================================================================
-- THE ONE PLACE A PLOT CHANGES SIZE
--
-- Everything that wants a plot at a different level comes through here: the
-- assignment path, the release path and the shop. That is what keeps the
-- Level attribute, the geometry and the plants from ever disagreeing.
--
-- No-ops when the plot is already the right size, which is the common case --
-- every join by a Level 1 player, and every release of a plot that was never
-- upgraded. Rebuilding a plot to the size it already is would destroy and
-- recreate ~200 parts for nothing.
--==============================================================================
local function levelOf(plot: Model): number
	local n = tonumber(plot:GetAttribute("Level"))
	if n == nil or n ~= n then
		return GameConfig.StartingPlotTier
	end
	return math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)
end

local function resizeTo(plot: Model, level: number, owner: Player?): boolean
	local want = math.clamp(math.floor(level), 1, #GameConfig.PlotTiers)
	if levelOf(plot) == want then
		return false
	end

	-- Only fired for an OWNED plot. A plot being reset on release has already
	-- been emptied, so there is nothing to carry across and no owner to name.
	if owner then
		fire(onResizing, owner, plot)
	end
	MapService.ResizePlot(plot, want)
	if owner then
		fire(onResized, owner, plot)

		-- The old SpawnLocation was destroyed with the rest of the geometry, so
		-- a player who died right now would respawn at the world default.
		local pad = plot:FindFirstChild(PLOT.SpawnPadName)
		if pad and pad:IsA("SpawnLocation") then
			owner.RespawnLocation = pad
		end
	end
	return true
end

-- DEFINED HERE, NOT WITH THE REST OF THE PUBLIC API ABOVE, because it calls
-- resizeTo and pushState. Both are locals declared further up this file, and a
-- function written above their declarations would capture the NAMES as globals
-- -- nil at call time, with a parse that succeeds and a build that passes.
--==============================================================================
-- SET THE LEVEL THIS PLAYER'S PLOT SHOULD BE
--
-- The only entry point. Safe to call before the player has a plot, after they
-- have left, with a level they already have, or with rubbish -- all of which
-- happen, because the two callers are a DataStore load racing a join and a shop
-- button racing everything.
--
-- Returns true if a plot was actually rebuilt, so a caller can tell "applied
-- now" from "remembered for later" without inspecting the plot itself.
--==============================================================================
function PlotService.SetDesiredLevel(player: Player, level: number): boolean
	-- A caller with no player at all. Reached while testing by asking for the
	-- owner of an unowned plot and passing the nil straight in; it threw on the
	-- presence check below. Nothing in production does that today, but a public
	-- entry point should answer "no" rather than raise.
	if typeof(player) ~= "Instance" then
		return false
	end
	local n = tonumber(level)
	if n == nil or n ~= n then
		return false
	end
	local want = math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)

	--==========================================================================
	-- NOTHING IS REMEMBERED FOR A PLAYER WHO HAS LEFT
	--
	-- The profile load runs on a spawned thread across a DataStore call that
	-- can take fifteen seconds, and PlayerDataService says so in as many words.
	-- It re-checks presence after the load, so today this cannot be reached
	-- late -- but this is a public entry point with three callers, and a table
	-- keyed by Player must not be written from a path whose cleanup has already
	-- run. That is how the entry outlives the player.
	--
	-- Checked BEFORE the write rather than after, because the write is the
	-- thing being prevented.
	--==========================================================================
	if player.Parent ~= Players then
		return false
	end
	desiredLevel[player] = want

	local id = plotOf[player]
	local plot = if id then plotsById[id] else nil
	if not plot then
		-- Queued, or gone. assign() will read the table when their turn comes.
		return false
	end
	local changed = resizeTo(plot, want, player)
	if changed then
		pushState(player)
	end
	return changed
end

local function clearPlot(plot: Model)
	for _, folderName in ipairs({ PLOT.PlantsFolderName, PLOT.RuntimeFolderName }) do
		local folder = plot:FindFirstChild(folderName)
		if folder then
			folder:ClearAllChildren()
		end
	end
	plot:SetAttribute(ATTR.OwnerUserId, 0)
	plot:SetAttribute(ATTR.OwnerName, "")
	plot:SetAttribute(ATTR.Claimed, false)
end

local function assign(player: Player, id: number)
	local plot = plotsById[id]
	if not plot then
		return
	end

	ownerOf[id] = player
	plotOf[player] = id

	--==========================================================================
	-- SIZED BEFORE IT IS ANNOUNCED
	--
	-- Ahead of the SpawnPad lookup below, ahead of placeCharacter, and ahead of
	-- the onAssigned listeners -- because ResizePlot destroys and rebuilds every
	-- part in the plot, including that pad, and PlantService restores the whole
	-- garden from an onAssigned listener. Doing this afterwards would hand the
	-- player a stale pad reference and drop their restored plants into soil that
	-- was about to be replaced.
	--
	-- It is also why the player is given the plot at their real size in ONE
	-- build. Assigning at Level 1 and growing it a moment later would work, and
	-- would look like a bug every single join.
	--==========================================================================
	resizeTo(plot, desiredLevel[player] or GameConfig.StartingPlotTier, nil)

	-- Attributes, not a remote. They replicate on their own, so any client that
	-- can see the plot can already read who owns it without being told.
	plot:SetAttribute(ATTR.OwnerUserId, player.UserId)
	plot:SetAttribute(ATTR.OwnerName, player.Name)
	plot:SetAttribute(ATTR.Claimed, true)

	local pad = plot:FindFirstChild(PLOT.SpawnPadName)
	if pad and pad:IsA("SpawnLocation") then
		player.RespawnLocation = pad
	end

	-- They may already be standing somewhere: freshly joined, or promoted off
	-- the queue while alive on the overflow pad.
	local character = player.Character
	if character then
		placeCharacter(player, character)
	end

	fire(onAssigned, player, plot)
	pushState(player)
end

-- Hand freed plots to whoever has waited longest. A loop rather than one step,
-- because a plot can free at the same moment the head of the queue leaves.
local function drainQueue()
	local moved = false
	while #waiting > 0 do
		local nextUp = waiting[1]
		if nextUp.Parent ~= Players then
			-- Left while waiting, and PlayerRemoving either already ran or never
			-- will.
			table.remove(waiting, 1)
			moved = true
			continue
		end
		local id = firstFreePlotId()
		if not id then
			break
		end
		table.remove(waiting, 1)
		assign(nextUp, id)
		local plot = plotsById[id]
		log(string.format("%s promoted off the queue onto %s. %d still waiting.",
			nextUp.Name, plot and plot.Name or ("plot " .. id), #waiting - 1))
		moved = true
	end

	if moved then
		-- Everybody still waiting just moved up.
		for _, player in ipairs(waiting) do
			pushState(player)
		end
	end
end

local function release(player: Player)
	local queued = table.find(waiting, player)
	if queued then
		table.remove(waiting, queued)
	end

	--==========================================================================
	-- CLEARED HERE, AHEAD OF THE EARLY RETURN BELOW
	--
	-- This used to sit further down, past `if not id then ... return end`, and
	-- so it never ran for a player who left while QUEUED -- which is the exact
	-- player most likely to have an entry, because a queued player's profile
	-- loads and records their level while they wait for a plot.
	--
	-- The table is keyed by the Player instance, so a missed clear is a strong
	-- reference held for the life of the server: the leak is one Player object
	-- per queued joiner who gave up waiting, on a server whose whole purpose is
	-- to make people wait.
	--==========================================================================
	desiredLevel[player] = nil

	local id = plotOf[player]
	if not id then
		if queued then
			drainQueue()
		end
		return
	end

	plotOf[player] = nil
	ownerOf[id] = nil

	local plot = plotsById[id]
	if plot then
		-- Listeners run BEFORE the clear, so a service that wants to save what
		-- was growing here still has something left to read.
		fire(onReleased, player, plot)
		clearPlot(plot)
		-- BACK TO LEVEL 1. A plot is not the player's property, it is a slot on
		-- this server; leaving it at Level 5 would hand the next joiner a plot
		-- worth 27 million cash that their profile says they do not own. The
		-- attributes and the profile would then disagree about capacity, and the
		-- attributes are what PlantService enforces against.
		resizeTo(plot, GameConfig.StartingPlotTier, nil)
		log(string.format("%s released %s. It is empty again.", player.Name, plot.Name))
	end

	drainQueue()
end

--==============================================================================
-- JOIN / LEAVE
--==============================================================================
local function onPlayerAdded(player: Player)
	if connections[player] then
		return
	end
	connections[player] = {
		player.CharacterAdded:Connect(function(character)
			placeCharacter(player, character)
		end),
	}

	local id = firstFreePlotId()
	if id then
		assign(player, id)
		local plot = plotsById[id]
		log(string.format("%s -> %s.", player.Name, plot and plot.Name or ("plot " .. id)))
	else
		table.insert(waiting, player)
		log(string.format("%s is waiting -- all %d plots are taken (position %d).",
			player.Name, #plotOrder, #waiting))
		pushState(player)
		-- A queued player still has to be moved off the origin.
		local character = player.Character
		if character then
			placeCharacter(player, character)
		end
	end
end

local function onPlayerRemoving(player: Player)
	local conns = connections[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		connections[player] = nil
	end
	release(player)
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function PlotService.Init()
	-- Re-runnable: requiring this module again in Edit must not leave half of
	-- the previous run's state behind. Same rule as MapService rebuilding rather
	-- than patching.
	table.clear(plotsById)
	table.clear(plotOrder)
	table.clear(ownerOf)
	table.clear(plotOf)
	table.clear(waiting)
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	for player, conns in pairs(connections) do
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		connections[player] = nil
	end
end

function PlotService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local remote = if remotes then remotes:FindFirstChild(GameConfig.Remotes.PlotAssigned) else nil
	if remote and remote:IsA("RemoteEvent") then
		plotAssignedRemote = remote
	else
		warn("[Seed/PlotService] No PlotAssigned remote. Clients will not be told their plot.")
	end

	--== FIND THE PLOTS ==--
	-- BY TAG, NOT BY FOLDER CHILDREN. The Plots folder also holds one Treadmill
	-- model per plot, so taking every child would hand somebody a treadmill and
	-- report twice as many plots as exist.
	local folder = MapService.GetPlotsFolder()
	if not folder then
		warn("[Seed/PlotService] No plots folder. MapService did not build. Nobody gets a plot.")
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and CollectionService:HasTag(child, GameConfig.Tags.Plot) then
			local id = child:GetAttribute(ATTR.PlotId)
			if type(id) == "number" then
				if plotsById[id] then
					warn(string.format("[Seed/PlotService] Two plots share id %d. Ignoring %s.",
						id, child:GetFullName()))
				else
					plotsById[id] = child
					table.insert(plotOrder, id)
					-- The map may have been rebuilt under a service that was
					-- already running.
					clearPlot(child)
				end
			end
		end
	end
	table.sort(plotOrder)

	if #plotOrder ~= GameConfig.MaxPlots then
		warn(string.format("[Seed/PlotService] Found %d plots but GameConfig.MaxPlots is %d.",
			#plotOrder, GameConfig.MaxPlots))
	end

	--== PLAYERS ==--
	-- Tracked, so Init can drop them and a second Start does not double up.
	table.insert(serviceConnections, Players.PlayerAdded:Connect(onPlayerAdded))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(onPlayerRemoving))
	-- ANYONE ALREADY HERE. In Play Solo the local player exists before
	-- ServerMain has finished booting, so connecting PlayerAdded and stopping
	-- there would miss the only player in the session -- which is precisely the
	-- player doing the testing.
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	log(string.format("Ready. %d plot(s): %s.", #plotOrder,
		#plotOrder > 0 and table.concat(plotOrder, ", ") or "none"))
end

-- For the console. Answers "who has what" in one line without a tree walk.
function PlotService.Snapshot(): string
	local rows = {}
	for _, id in ipairs(plotOrder) do
		local owner = ownerOf[id]
		table.insert(rows, string.format("%02d:%s", id, owner and owner.Name or "-"))
	end
	local queueNames = {}
	for _, player in ipairs(waiting) do
		table.insert(queueNames, player.Name)
	end
	return string.format("plots [%s] waiting [%s]",
		table.concat(rows, " "), table.concat(queueNames, " "))
end

return PlotService
