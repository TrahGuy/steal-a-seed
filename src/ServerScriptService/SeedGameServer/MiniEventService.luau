--!strict
-- Steal a Seed :: MiniEventService
--
-- MINI EVENTS: TICKET DISCO (2026-10-03, the owner's brief; made GLOBAL the
-- same day). A short event an allowlisted admin starts from the console's MINI
-- EVENTS section (START GLOBAL EVENT), for EVERY server of this place, in one
-- of four modes (GameConfig.MiniEvent.Modes):
--
--   ticketdisco   Golden Spinwheel Tickets fall round the hub, with the disco
--   disco         DISCO + MILL: the disco (a ball over the hub, soft colour,
--                 dancing) and the giant Disco Mill
--   party         DISCO ONLY (2026-10-04): the disco and x1.5 movement for
--                 everybody (CarryService) -- no mill, no tickets
--   tickets       the ticket shower alone
--
-- This file drops tickets only for a mode with Tickets; the mill and the
-- movement factor read the same published state on their own.
--
--==============================================================================
-- ONE SHARED RECORD, MANY SERVERS
--
-- The authoritative event is ONE record in shared storage (a DataStore key,
-- GameConfig.MiniEvent.Global):
--
--   { v, ns, id, rev, mode, startedAt, endsAt, by, byName, state,
--     endedAt?, endedBy?, endedByName?, endedIds }
--
--   id         unique per event (never reused)
--   rev        bumped by EVERY write -- a start, an end -- so a server applies a
--              record only if its rev is higher than the highest it has seen:
--              a duplicate or a late message is a no-op, wherever it came from
--   startedAt  absolute times, workspace:GetServerTimeNow(): the same epoch
--   endsAt     clock on every server, so every countdown, every dance beat and
--              every server's close agree without anybody being told
--   state      "running" or "ended" (an END); a running record whose endsAt has
--              passed is over by its timer and needs no write
--   endedIds   the last few ended events' ids -- the TOMBSTONES: a START for one
--              of them, however late it arrives, can never bring it back
--
-- START and END are UpdateAsync transforms on that key, so concurrent presses
-- on different servers are serialised by the store: the first START makes the
-- event and every other START finds it running and changes nothing -- not its
-- timer, not its caps; an END ends exactly that event, and a second END finds
-- nothing to end. After a write lands, MessagingService tells every server at
-- once (best-effort, and said so honestly to the admin); every server ALSO
-- re-reads the record on a timer (Global.PollSeconds, backing off on failure),
-- so a missed message is only late, never lost, and a server that starts
-- mid-event joins it for what is LEFT of it. Messages that arrive before a
-- new server's first read are held and applied after it, in revision order.
--
-- EACH SERVER DROPS ITS OWN TICKETS. Nothing per-ticket or per-frame crosses
-- servers: only the record. The per-player cap is per GLOBAL event and lives
-- on the player's own profile (EventClaims, WheelService.GrantEventSpin), saved
-- with the spins themselves -- so leaving, dying, rejoining or moving to
-- another server meets the same count.
--
-- STUDIO NEVER TOUCHES THE LIVE RECORD OR TOPIC. With the throwaway test store
-- switched on (ServerStorage.SeedTestStore) Studio uses that throwaway
-- DataStore and a topic named after it; without it, an event in Studio is this
-- server's alone (scope "local"). Live servers use this PlaceId's own key and
-- topic, so no other place or game is affected.
--
-- INDEPENDENT OF THE WEATHER. Nothing here reads or writes WeatherService, the
-- income factor, the rain biome, pods, guardians or the evacuation, and the
-- weather stays this server's. The light and the music are the clients' one
-- owners' (WorldClock, Music), which compose the disco over whatever weather,
-- day or night is live -- nothing here touches Lighting.
--
--==============================================================================
-- ON THIS SERVER: THE TICKETS, AND THE SERVER DECIDES EVERYTHING
--
-- A ticket is a server record: an id this file made, where it lies, when it
-- lands and when it expires. The clients draw them from a folder of those
-- records and NOTHING comes back: there is no remote for picking up. Every
-- Heartbeat this file looks at where each living body is -- swept along its
-- path since the last frame, so a fast runner cannot step over one, while a
-- teleport is not a sweep -- and a body on a landed ticket takes it, in one
-- synchronous step: the ticket still exists, has landed and has not expired;
-- WheelService.GrantEventSpin accepted ONE free earned spin with the claim
-- (refused at the cap, with a full balance, or with a profile that is not
-- saving); only then is the ticket gone and the collector told.
--
-- THE SEAMS -- the clock, the player list, a body's position, the broadcast,
-- the grant, the claim count, the shared store and messaging, and where the
-- attributes go -- are swappable so MiniEventSpec runs whole events, and two
-- "servers" against one stand-in store, in Edit; every default is real.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local DancerPlacement = require(Shared:WaitForChild("DancerPlacement"))
local WheelService = require(script.Parent:WaitForChild("WheelService"))

local MiniEventService = {}
-- After the wheel (62) and the weather (65); nothing waits on it.
MiniEventService.Priority = 66

local M = GameConfig.MiniEvent
local ATTR = M.Attributes
local EVENTS = M.Events
local T = M.Tickets
local AREA = M.Area
local G = M.Global
local SAVE = GameConfig.Save
local MODES: { [string]: any } = M.Modes :: any
local RECORD_VERSION = 1

export type Record = {
	v: number,
	ns: string,
	id: string,
	rev: number,
	mode: string,
	startedAt: number,
	endsAt: number,
	by: number,
	byName: string,
	state: string,
	endedAt: number?,
	endedBy: number?,
	endedByName: string?,
	endedIds: { string },
}

export type Ticket = {
	id: number,
	-- Where it lies: on the floor's surface.
	at: Vector3,
	droppedAt: number,
	landsAt: number,
	expiresAt: number,
	record: Instance?,
	-- The zone it fell in (MiniEvent.Zones' name, or a biome's id): a ticket in
	-- the rain biome goes when the biome starts to close, one in a permanent
	-- biome when night shuts the road.
	zone: string?,
}

-- This server's presentation of the global event the record names.
export type Event = {
	globalId: string,
	rev: number,
	mode: string,
	state: string,
	startedAt: number,
	endsAt: number,
	endingAt: number?,
	byName: string,
	announced: boolean,
	nextDropAt: number,
	nextCountAt: number,
	tickets: { [number]: Ticket },
	collected: number,
	dropped: number,
	-- When each UserId was last told it could not take a ticket.
	toldAt: { [number]: number },
}

-- What the shared store and the messaging are, behind one seam.
export type SharedSeam = {
	scope: string,
	note: string,
	ns: string,
	update: (transform: (any) -> any) -> (boolean, string?),
	read: () -> (boolean, any),
	publish: (record: Record) -> (boolean, string?),
	subscribe: (handler: (any) -> ()) -> (boolean, string?),
}

local current: Event? = nil
local known: Record? = nil
-- Ended event ids, oldest first, and a set over them.
local tombstoneList: { string } = {}
local tombstones: { [string]: boolean } = {}
local ticketSeq = 0
local generation = 0
local running = false
local connections: { RBXScriptConnection } = {}
-- Each body's root last frame, for the sweep.
local lastRoot: { [any]: Vector3 } = setmetatable({}, { __mode = "k" }) :: any
local rng = Random.new()
local requestBusy = false
-- The sync's health, for the admins and the log.
local sync = {
	status = "starting",
	lastOkAt = 0,
	lastError = nil :: string?,
	subscribed = false,
	nextPollAt = 0,
	backoff = 0,
	polling = false,
	-- Before the first read has been tried, messages wait here.
	ready = false,
	pending = {} :: { any },
	warned = false,
}

local function log(message: string)
	print("[Seed/MiniEventService] " .. message)
end

local function nameOf(who: any): string
	local ok, name = pcall(function()
		return who.Name
	end)
	return if ok and type(name) == "string" then name else "?"
end

local function userIdOf(who: any): number?
	local ok, id = pcall(function()
		return who.UserId
	end)
	if ok and type(id) == "number" and id == id and id ~= 0 and id == math.floor(id) then
		return id
	end
	return nil
end

local function mmss(seconds: number): string
	local whole = math.max(0, math.ceil(seconds - 1e-6))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function short(id: string): string
	return string.sub(id, 1, 8)
end

local function modeOf(mode: string): any
	return MODES[mode]
end

local function hasTickets(event: Event): boolean
	local mode = modeOf(event.mode)
	return mode ~= nil and mode.Tickets == true
end

--==============================================================================
-- THE LOCAL SEAMS
--==============================================================================
local clock: () -> number = function()
	return Workspace:GetServerTimeNow()
end

local playersNow: () -> { any } = function()
	return Players:GetPlayers()
end

-- A living body's root position, or nil.
local function realRoot(player: any): Vector3?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end
local rootOf: (any) -> Vector3? = realRoot

local function remote(): RemoteEvent?
	local seedGame = ReplicatedStorage:FindFirstChild("SeedGame")
	local remotes = if seedGame then seedGame:FindFirstChild("Remotes") else nil
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	return if found and found:IsA("RemoteEvent") then found else nil
end

-- To everyone in the server, or to `to` alone.
local function sendEvent(action: string, payload: any, to: { any }?)
	local event = remote()
	if not event then
		return
	end
	if to then
		for _, player in ipairs(to) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				event:FireClient(player, action, payload)
			end
		end
	else
		event:FireAllClients(action, payload)
	end
end
local broadcast: (string, any, { any }?) -> () = sendEvent

local function realGrant(player: any, eventId: string, cap: number, source: string): (boolean, string?, number)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "NOT_SAVED", 0
	end
	return WheelService.GrantEventSpin(player :: Player, eventId, cap, source)
end
local grant: (any, string, number, string) -> (boolean, string?, number) = realGrant

local function realCount(player: any, eventId: string): number?
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end
	return WheelService.EventClaimCount(player :: Player, eventId)
end
local countOf: (any, string) -> number? = realCount

-- A spot override for the spec (nil: the real picker).
local spotFn: ((Event) -> Vector3?)? = nil
-- Where the attributes are written and the ticket folder kept.
local attrTarget: Instance = Workspace
local ticketParent: Instance = ReplicatedStorage

function MiniEventService.useClock(fn: (() -> number)?)
	clock = fn or function()
		return Workspace:GetServerTimeNow()
	end
end

function MiniEventService.usePlayers(fn: (() -> { any })?)
	playersNow = fn or function()
		return Players:GetPlayers()
	end
end

function MiniEventService.useRoot(fn: ((any) -> Vector3?)?)
	rootOf = fn or realRoot
	table.clear(lastRoot)
end

function MiniEventService.useBroadcast(fn: ((string, any, { any }?) -> ())?)
	broadcast = fn or sendEvent
end

function MiniEventService.useGrant(fn: ((any, string, number, string) -> (boolean, string?, number))?)
	grant = fn or realGrant
end

function MiniEventService.useCount(fn: ((any, string) -> number?)?)
	countOf = fn or realCount
end

function MiniEventService.useSpot(fn: ((Event) -> Vector3?)?)
	spotFn = fn
end

function MiniEventService.useWorld(target: Instance?, parent: Instance?)
	attrTarget = target or Workspace
	ticketParent = parent or ReplicatedStorage
end

--==============================================================================
-- THE SHARED SEAM: WHERE THE RECORD LIVES
--
-- Decided once, at Start, from where this server runs:
--   a live server                 GameConfig's store, this PlaceId's key/topic
--   Studio + the test store on    the throwaway store, a topic named after it
--   Studio without it             "local": an in-memory record, no messaging
--==============================================================================
local function memorySeam(note: string): SharedSeam
	local value: any = nil
	return {
		scope = "local",
		note = note,
		ns = "local",
		update = function(transform: (any) -> any): (boolean, string?)
			local nextValue = transform(value)
			if nextValue ~= nil then
				value = nextValue
			end
			return true, nil
		end,
		read = function(): (boolean, any)
			return true, value
		end,
		publish = function(_record: Record): (boolean, string?)
			return true, nil
		end,
		subscribe = function(_handler: (any) -> ()): (boolean, string?)
			return true, nil
		end,
	}
end

local function realSeam(storeName: string, key: string, topic: string, note: string): SharedSeam
	local store: DataStore? = nil
	local function open(): DataStore
		local s = store
		if s then
			return s
		end
		local made = DataStoreService:GetDataStore(storeName)
		store = made
		return made
	end
	return {
		scope = "global",
		note = note,
		ns = key,
		update = function(transform: (any) -> any): (boolean, string?)
			local ok, err = pcall(function()
				open():UpdateAsync(key, function(old: any): any
					return transform(old)
				end)
			end)
			return ok, if ok then nil else tostring(err)
		end,
		read = function(): (boolean, any)
			local ok, value = pcall(function(): any
				local options: any = nil
				pcall(function()
					local o = Instance.new("DataStoreGetOptions")
					o.UseCache = false
					options = o
				end)
				if options then
					return (open() :: any):GetAsync(key, options)
				end
				return open():GetAsync(key)
			end)
			return ok, value
		end,
		publish = function(record: Record): (boolean, string?)
			local ok, err = pcall(function()
				MessagingService:PublishAsync(topic, record)
			end)
			return ok, if ok then nil else tostring(err)
		end,
		subscribe = function(handler: (any) -> ()): (boolean, string?)
			local ok, result = pcall(function()
				return MessagingService:SubscribeAsync(topic, function(message: any)
					handler(if type(message) == "table" then message.Data else nil)
				end)
			end)
			if ok and typeof(result) == "RBXScriptConnection" then
				table.insert(connections, result)
			end
			return ok, if ok then nil else tostring(result)
		end,
	}
end

local function resolveSeam(): SharedSeam
	local place = tostring(game.PlaceId)
	if RunService:IsStudio() then
		local marker = ServerStorage:FindFirstChild(SAVE.TestStoreMarker)
		local name = if marker and marker:IsA("StringValue") then (marker :: StringValue).Value else ""
		if string.find(name, SAVE.TestStorePattern) ~= nil then
			return realSeam(name, G.TestKeyPrefix .. place, name .. G.TestTopicSuffix,
				"Studio test namespace " .. name .. " (never the live record or topic)")
		end
		return memorySeam("Studio without the throwaway test store: THIS SERVER ONLY, not global")
	end
	return realSeam(G.Store, G.KeyPrefix .. place, G.TopicPrefix .. place, "every server of place " .. place)
end

local seam: SharedSeam = memorySeam("not started")

-- The spec stands its own store and bus in here; nil puts the real one back.
function MiniEventService.useShared(fn: SharedSeam?)
	seam = fn or resolveSeam()
end

--==============================================================================
-- THE TICKET RECORDS THE CLIENTS DRAW FROM
--
-- One non-archivable folder in ReplicatedStorage (always replicated, whatever
-- streams), one Configuration per unclaimed ticket with its id, where it lies
-- and its three times. A collected ticket is stamped ClaimedBy before it goes,
-- so its collector's client can play the pickup where it lay.
--==============================================================================
local function ticketFolder(): Instance
	local found = ticketParent:FindFirstChild(M.FolderName)
	if found and found:IsA("Folder") then
		return found
	end
	local made = Instance.new("Folder")
	made.Name = M.FolderName
	made.Archivable = false
	made.Parent = ticketParent
	return made
end

local function makeRecord(event: Event, ticket: Ticket): Instance
	local record = Instance.new("Configuration")
	record.Name = "T" .. tostring(ticket.id)
	record.Archivable = false
	record:SetAttribute("Event", event.globalId)
	record:SetAttribute("Id", ticket.id)
	record:SetAttribute("At", ticket.at)
	record:SetAttribute("DroppedAt", ticket.droppedAt)
	record:SetAttribute("LandsAt", ticket.landsAt)
	record:SetAttribute("ExpiresAt", ticket.expiresAt)
	record:SetAttribute("Zone", ticket.zone)
	record.Parent = ticketFolder()
	return record
end

local function dropRecord(ticket: Ticket, claimedBy: number?)
	local record = ticket.record
	ticket.record = nil
	if not record then
		return
	end
	if claimedBy then
		record:SetAttribute("ClaimedBy", claimedBy)
		-- Long enough for the stamp to reach the clients before the record goes.
		task.delay(0.6, function()
			record:Destroy()
		end)
	else
		record:Destroy()
	end
end

--==============================================================================
-- PUBLISHING (to this server's clients)
--
-- Every attribute, State last: a client that sees the state finds the rest
-- already in place. Each player's own count rides an attribute on the player.
--==============================================================================
local function publish(event: Event?)
	local target = attrTarget
	if not event then
		target:SetAttribute(ATTR.State, nil)
		target:SetAttribute(ATTR.Mode, nil)
		target:SetAttribute(ATTR.EventId, nil)
		target:SetAttribute(ATTR.StartedAt, nil)
		target:SetAttribute(ATTR.EndsAt, nil)
		target:SetAttribute(ATTR.EndingAt, nil)
		target:SetAttribute(ATTR.Cap, nil)
		target:SetAttribute(ATTR.Scope, nil)
		return
	end
	target:SetAttribute(ATTR.Mode, event.mode)
	target:SetAttribute(ATTR.EventId, event.globalId)
	target:SetAttribute(ATTR.StartedAt, event.startedAt)
	target:SetAttribute(ATTR.EndsAt, event.endsAt)
	target:SetAttribute(ATTR.EndingAt, event.endingAt)
	target:SetAttribute(ATTR.Cap, if hasTickets(event) then T.PerPlayerCap else nil)
	target:SetAttribute(ATTR.Scope, seam.scope)
	target:SetAttribute(ATTR.State, event.state)
end

local function setCount(player: any, count: number?)
	if typeof(player) == "Instance" and player:IsA("Player") then
		if player:GetAttribute(ATTR.PlayerTickets) ~= count then
			player:SetAttribute(ATTR.PlayerTickets, count)
		end
	end
end

-- Each player's count for the running event, off their profile.
local function publishCounts(event: Event?)
	for _, player in ipairs(playersNow()) do
		if event and event.state == "running" and hasTickets(event) then
			local n = countOf(player, event.globalId)
			if n ~= nil then
				setCount(player, n)
			end
		else
			setCount(player, nil)
		end
	end
end

--==============================================================================
-- WHERE A TICKET MAY FALL
--
-- A random point in the area's radius band and sectors, refused near anything
-- people go to the hub for, near another unclaimed ticket, off the floor, or
-- where something solid stands. Bodies are never in the way: they are left out
-- of both checks, and a ticket is drawn without collision anyway.
--==============================================================================
export type Clear = { name: string, at: Vector3, radius: number }

function MiniEventService.KeepClear(): { Clear }
	local list: { Clear } = {}
	for _, k in ipairs(M.KeepClear) do
		table.insert(list, { name = k.Name, at = k.At, radius = k.Radius })
	end
	local community = GameConfig.Community
	table.insert(list, { name = "BonusChest", at = GameConfig.BonusChest.Position, radius = 5 })
	-- The community chest and the step pad in front of it.
	table.insert(list, { name = "CommunityChest", at = community.Position,
		radius = community.PadAhead + community.PadRadius + 1 })
	table.insert(list, { name = "SacrificePedestal", at = GameConfig.Sacrifice.Position, radius = 6 })
	table.insert(list, { name = "Wheel", at = WheelData.Place.Position, radius = 10 })
	table.insert(list, { name = "ObbyEntrance", at = ObbyData.Entrance.At, radius = 14 })
	-- The Disco Mill's ground (2026-10-04), whether or not it stands right now.
	local mill = M.DiscoMill
	if mill.Enabled then
		table.insert(list, { name = "DiscoMill", at = mill.At, radius = mill.KeepClearRadius })
	end
	return list
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Inside the radius band and one of the sectors (pure geometry).
function MiniEventService.InArea(at: Vector3): boolean
	local d = flat(at - AREA.Centre)
	local r = d.Magnitude
	if r < AREA.MinRadius or r > AREA.MaxRadius then
		return false
	end
	local angle = math.deg(math.atan2(d.Z, d.X))
	for _, sector in ipairs(AREA.Sectors) do
		if angle >= sector.From and angle <= sector.To then
			return true
		end
	end
	return false
end

-- Clear of every keep-clear thing (pure geometry).
function MiniEventService.ClearOfKept(at: Vector3): (boolean, string?)
	for _, k in ipairs(MiniEventService.KeepClear()) do
		if flat(at - k.at).Magnitude < k.radius + AREA.Clearance then
			return false, k.name
		end
	end
	return true, nil
end

local function bodies(): { Instance }
	local list: { Instance } = {}
	for _, player in ipairs(playersNow()) do
		local character = if typeof(player) == "Instance" then (player :: any).Character else nil
		if character then
			table.insert(list, character)
		end
	end
	return list
end

-- The floor under (x, z), or nil when it is not the floor or something solid
-- stands on it.
function MiniEventService.FloorAt(x: number, z: number): Vector3?
	local ground = GameConfig.Map.GroundY
	local ignore = bodies()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	local hit = Workspace:Raycast(Vector3.new(x, ground + 40, z), Vector3.new(0, -80, 0), params)
	if not hit or math.abs(hit.Position.Y - ground) > AREA.FloorTolerance then
		return nil
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ignore
	overlap.RespectCanCollide = true
	local standing = Workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 3, 0)),
		Vector3.new(3, 4.6, 3), overlap)
	if #standing > 0 then
		return nil
	end
	return hit.Position
end

--==============================================================================
-- ALL OVER THE MAP (2026-10-04, the owner's ask; GameConfig.MiniEvent.Zones)
--
-- A drop picks a ZONE by weight among those open now -- a zone somebody is
-- standing in weighs (1 + PresenceBoost) times as much -- then a spot in it,
-- and the spot must pass every check below or another is tried. Nothing about
-- what a ticket is worth, how often one drops, how long it lies or how many a
-- player may take is different.
--==============================================================================
export type Zone = { name: string, kind: string, weight: number, spec: any, biome: any? }

local MAP = GameConfig.Map
local RAIN_FOLDER = GameConfig.Weather.Biome.FolderName
local PLOT_WIDTH = GameConfig.Plot.Width

local function rainOpen(): boolean
	return Workspace:GetAttribute(GameConfig.Weather.Attributes.State) == "active"
		and Workspace:FindFirstChild(RAIN_FOLDER) ~= nil
end

-- The rain biome's walking floors (RoomFloor*, CorridorFloor*), and the box
-- round all of them; found again whenever the biome is rebuilt.
local rainFloors: { folder: Instance?, parts: { BasePart }, box: { number } } =
	{ folder = nil, parts = {}, box = { 0, 0, 0, 0 } }

local function floorsOfRain(): { BasePart }
	local folder = Workspace:FindFirstChild(RAIN_FOLDER)
	if folder ~= rainFloors.folder then
		local parts: { BasePart } = {}
		local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
		if folder then
			for _, d in ipairs(folder:GetDescendants()) do
				if d:IsA("BasePart") and (string.sub(d.Name, 1, 9) == "RoomFloor"
					or string.sub(d.Name, 1, 13) == "CorridorFloor") then
					table.insert(parts, d)
					local half = d.Size.Magnitude / 2
					x0, x1 = math.min(x0, d.Position.X - half), math.max(x1, d.Position.X + half)
					z0, z1 = math.min(z0, d.Position.Z - half), math.max(z1, d.Position.Z + half)
				end
			end
		end
		rainFloors = { folder = folder, parts = parts, box = { x0, x1, z0, z1 } }
	end
	return rainFloors.parts
end

-- The zones open right now.
function MiniEventService.Zones(): { Zone }
	local out: { Zone } = {}
	for _, z in ipairs(M.Zones) do
		if z.Kind == "biomes" then
			-- The road shuts at night: no ticket where nobody can go.
			if GameConfig.isDay() then
				for _, biome in ipairs(BiomeData.Biomes) do
					table.insert(out, { name = biome.Id, kind = "biome", weight = z.Weight, spec = z, biome = biome })
				end
			end
		elseif z.Kind == "rain" then
			if rainOpen() and #floorsOfRain() > 0 then
				table.insert(out, { name = z.Name, kind = "rain", weight = z.Weight, spec = z })
			end
		else
			table.insert(out, { name = z.Name, kind = z.Kind, weight = z.Weight, spec = z })
		end
	end
	return out
end

-- Is a spot inside this zone (pure geometry, the rain's box excepted)?
local function inZone(zone: Zone, at: Vector3): boolean
	local z = zone.spec
	if zone.kind == "area" then
		return MiniEventService.InArea(at)
	elseif zone.kind == "ring" then
		local r = flat(at).Magnitude
		return r >= z.MinRadius and r <= z.MaxRadius
	elseif zone.kind == "box" then
		return at.X >= z.X0 and at.X <= z.X1 and at.Z >= z.Z0 and at.Z <= z.Z1
	elseif zone.kind == "biome" then
		local nearZ, farZ = BiomeData.SegmentBounds(zone.biome)
		return math.abs(at.X) <= MAP.CorridorWidth / 2 and at.Z <= nearZ and at.Z >= farZ
	elseif zone.kind == "rain" then
		floorsOfRain()
		local box = rainFloors.box
		return at.X >= box[1] and at.X <= box[2] and at.Z >= box[3] and at.Z <= box[4]
	end
	return false
end

-- Is a spot inside the open zone named `name`? (Zones overlap: the field's
-- ring runs into the front's box.)
function MiniEventService.InZone(name: string, at: Vector3): boolean
	for _, zone in ipairs(MiniEventService.Zones()) do
		if zone.name == name then
			return inZone(zone, at)
		end
	end
	return false
end

-- The name of the first open zone a spot lies in, or nil.
function MiniEventService.ZoneOf(at: Vector3): string?
	for _, zone in ipairs(MiniEventService.Zones()) do
		if inZone(zone, at) then
			return zone.name
		end
	end
	return nil
end

-- Somewhere in the zone, before any check.
local function guessIn(zone: Zone): Vector3?
	local z = zone.spec
	if zone.kind == "area" then
		local sector = AREA.Sectors[rng:NextInteger(1, #AREA.Sectors)]
		local angle = math.rad(sector.From + (sector.To - sector.From) * rng:NextNumber())
		-- Uniform over the band's area, not bunched at its inner edge.
		local r = math.sqrt(AREA.MinRadius ^ 2 + (AREA.MaxRadius ^ 2 - AREA.MinRadius ^ 2) * rng:NextNumber())
		return AREA.Centre + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
	elseif zone.kind == "ring" then
		local angle = rng:NextNumber() * math.pi * 2
		local r = math.sqrt(z.MinRadius ^ 2 + (z.MaxRadius ^ 2 - z.MinRadius ^ 2) * rng:NextNumber())
		return Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
	elseif zone.kind == "box" then
		return Vector3.new(z.X0 + (z.X1 - z.X0) * rng:NextNumber(), 0, z.Z0 + (z.Z1 - z.Z0) * rng:NextNumber())
	elseif zone.kind == "biome" then
		local nearZ, farZ = BiomeData.SegmentBounds(zone.biome)
		local zz = (farZ + z.FarMargin) + ((nearZ - z.NearMargin) - (farZ + z.FarMargin)) * rng:NextNumber()
		return Vector3.new((rng:NextNumber() * 2 - 1) * z.HalfWidth, 0, zz)
	elseif zone.kind == "rain" then
		local parts = floorsOfRain()
		if #parts == 0 then
			return nil
		end
		-- A floor by its area, then a point in its middle `Inset` of it; a point
		-- off a round floor's edge finds no floor under it and is tried again.
		local total = 0
		for _, p in ipairs(parts) do
			total += p.Size.X * p.Size.Z
		end
		local pick = rng:NextNumber() * total
		local chosen = parts[#parts]
		for _, p in ipairs(parts) do
			pick -= p.Size.X * p.Size.Z
			if pick <= 0 then
				chosen = p
				break
			end
		end
		local inset = z.Inset
		local lx = (rng:NextNumber() - 0.5) * chosen.Size.X * inset
		local lz = (rng:NextNumber() - 0.5) * chosen.Size.Z * inset
		local at = chosen.CFrame:PointToWorldSpace(Vector3.new(lx, 0, lz))
		return Vector3.new(at.X, 0, at.Z)
	end
	return nil
end

-- Inside a plot (its main bed or its wing), PlotMargin studs generous. Read
-- off the attributes MapService stamps on every plot: the centre frame (local
-- -Z faces the hub), its depth, and its wing.
function MiniEventService.InPlot(at: Vector3): boolean
	local margin = M.PlotMargin
	for _, plot in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		local cf = plot:GetAttribute("PlotCF")
		local depth = tonumber(plot:GetAttribute("Depth"))
		if typeof(cf) == "CFrame" and depth then
			local p = cf:PointToObjectSpace(Vector3.new(at.X, cf.Y, at.Z))
			local halfW, halfD = PLOT_WIDTH / 2, depth / 2
			if math.abs(p.X) <= halfW + margin and math.abs(p.Z) <= halfD + margin then
				return true
			end
			local wing = tonumber(plot:GetAttribute("WingWidth")) or 0
			local front = tonumber(plot:GetAttribute("WingFrontZ")) or halfD
			-- The back fence, but on plot 6 at Levels 6-7 (GameConfig.Plot.Beside).
			local back = math.min(tonumber(plot:GetAttribute("WingBackZ")) or halfD, halfD)
			if wing > 0 and p.X >= halfW - margin and p.X <= halfW + wing + margin
				and p.Z >= front - margin and p.Z <= back + margin then
				return true
			end
		end
	end
	return false
end

-- Within NestClear of a biome's nest, or of the Secret pod's spot across the
-- road from it (the guardians' ground).
local function nearNest(zone: Zone, at: Vector3): boolean
	if zone.kind ~= "biome" then
		return false
	end
	local clear = zone.spec.NestClear
	for _, nest in ipairs(BiomeData.NestCFrames(zone.biome)) do
		for _, x in ipairs({ nest.X, -nest.X }) do
			if flat(at - Vector3.new(x, 0, nest.Z)).Magnitude < clear then
				return true
			end
		end
	end
	return false
end

-- A disco's dancers: the same picks every client draws for this event.
local dancers: { id: string?, picks: { DancerPlacement.Pick } } = { id = nil, picks = {} }

local function nearDancer(event: Event, at: Vector3): boolean
	local mode = modeOf(event.mode)
	if not (mode and mode.Disco) then
		return false
	end
	if dancers.id ~= event.globalId then
		local ok, picks = pcall(DancerPlacement.Picks, event.globalId)
		dancers = { id = event.globalId, picks = if ok then picks else {} }
	end
	for _, pick in ipairs(dancers.picks) do
		if flat(at - pick.at).Magnitude < pick.radius + 2 then
			return true
		end
	end
	return false
end

--==============================================================================
-- THE PROPS, MEASURED ONCE
--
-- MapDecor's props cannot be hit by any query (CanCollide and CanQuery off),
-- so nothing the floor test does can see a tree. Instead every part of the map
-- standing more than a stud above the ground -- collidable or not, prop, fence,
-- arch, sign, mill -- goes into a grid of flat boxes, PropMargin wider, and a
-- spot inside any box is refused. Measured again for each event, and when the
-- rain biome or the Disco Mill comes or goes.
--==============================================================================
local CELL = 16
type Grid = { key: string, cells: { [number]: { [number]: { { number } } } } }
local grid: Grid = { key = "", cells = {} }

local function gridKey(): string
	local event = current
	local rain = Workspace:FindFirstChild(RAIN_FOLDER)
	local mill = Workspace:FindFirstChild(M.DiscoMill.ModelName)
	return string.format("%s|%s|%s", if event then event.globalId else "-",
		if rain then tostring(#rain:GetDescendants()) else "-", if mill then "mill" else "-")
end

local function measureProps(): Grid
	local key = gridKey()
	if grid.key == key then
		return grid
	end
	local cells: { [number]: { [number]: { { number } } } } = {}
	local ground = MAP.GroundY
	local margin = M.PropMargin
	local function add(part: BasePart)
		local cf, size = part.CFrame, part.Size
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local sx = math.abs(r.X) * size.X + math.abs(u.X) * size.Y + math.abs(l.X) * size.Z
		local sy = math.abs(r.Y) * size.X + math.abs(u.Y) * size.Y + math.abs(l.Y) * size.Z
		local sz = math.abs(r.Z) * size.X + math.abs(u.Z) * size.Y + math.abs(l.Z) * size.Z
		if cf.Y + sy / 2 < ground + 1.2 or cf.Y - sy / 2 > ground + 7 or sx > 200 or sz > 200 then
			return
		end
		if part.Transparency >= 1 and not part.CanCollide then
			return
		end
		local box = { cf.X - sx / 2 - margin, cf.X + sx / 2 + margin, cf.Z - sz / 2 - margin, cf.Z + sz / 2 + margin }
		for cx = math.floor(box[1] / CELL), math.floor(box[2] / CELL) do
			local column = cells[cx]
			if not column then
				column = {}
				cells[cx] = column
			end
			for cz = math.floor(box[3] / CELL), math.floor(box[4] / CELL) do
				local list = column[cz]
				if not list then
					list = {}
					column[cz] = list
				end
				table.insert(list, box)
			end
		end
	end
	for _, name in ipairs({ "SeedMap", RAIN_FOLDER, M.DiscoMill.ModelName }) do
		local root = Workspace:FindFirstChild(name)
		if root then
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("BasePart") then
					add(d)
				end
			end
		end
	end
	grid = { key = key, cells = cells }
	return grid
end

function MiniEventService.PropAt(at: Vector3): boolean
	local column = measureProps().cells[math.floor(at.X / CELL)]
	local list = column and column[math.floor(at.Z / CELL)]
	if not list then
		return false
	end
	for _, box in ipairs(list) do
		if at.X >= box[1] and at.X <= box[2] and at.Z >= box[3] and at.Z <= box[4] then
			return true
		end
	end
	return false
end

-- Every check but the floor and the other tickets, for a spot in `zone`.
function MiniEventService.SpotClear(at: Vector3, zone: Zone, event: Event?): (boolean, string?)
	local ok, why = MiniEventService.ClearOfKept(at)
	if not ok then
		return false, why
	end
	if MiniEventService.InPlot(at) then
		return false, "plot"
	end
	if nearNest(zone, at) then
		return false, "nest"
	end
	if event and nearDancer(event, at) then
		return false, "dancer"
	end
	if MiniEventService.PropAt(at) then
		return false, "prop"
	end
	return true, nil
end

local function weighed(): ({ Zone }, { number }, number)
	local zones = MiniEventService.Zones()
	local roots: { Vector3 } = {}
	for _, player in ipairs(playersNow()) do
		local root = rootOf(player)
		if root then
			table.insert(roots, root)
		end
	end
	local weights: { number } = {}
	local total = 0
	for i, zone in ipairs(zones) do
		local w = zone.weight
		for _, root in ipairs(roots) do
			if inZone(zone, root) then
				w *= 1 + M.PresenceBoost
				break
			end
		end
		weights[i] = w
		total += w
	end
	return zones, weights, total
end

-- One try in `zone`: a spot that passes every check, or nil.
local function tryIn(zone: Zone, event: Event): Vector3?
	local guess = guessIn(zone)
	if not guess then
		return nil
	end
	for _, other in pairs(event.tickets) do
		if flat(other.at - guess).Magnitude < T.MinSpacing then
			return nil
		end
	end
	if not MiniEventService.SpotClear(guess, zone, event) then
		return nil
	end
	return MiniEventService.FloorAt(guess.X, guess.Z)
end

local function pickSpot(event: Event): (Vector3?, string?)
	local override = spotFn
	if override then
		return override(event), nil
	end
	local zones, weights, total = weighed()
	if #zones == 0 or total <= 0 then
		return nil, nil
	end
	for _ = 1, 24 do
		local roll = rng:NextNumber() * total
		local zone = zones[#zones]
		for i, z in ipairs(zones) do
			roll -= weights[i]
			if roll <= 0 then
				zone = z
				break
			end
		end
		local floor = tryIn(zone, event)
		if floor then
			return floor, zone.name
		end
	end
	return nil, nil
end
MiniEventService.PickSpot = pickSpot

-- A spot in the open zone named `name` (the spec walks every zone this way),
-- with the same checks and the same 24 tries a drop gets; nil if it is shut.
function MiniEventService.PickIn(name: string, event: Event): Vector3?
	for _, zone in ipairs(MiniEventService.Zones()) do
		if zone.name == name then
			for _ = 1, 24 do
				local floor = tryIn(zone, event)
				if floor then
					return floor
				end
			end
			return nil
		end
	end
	return nil
end

-- Is the zone a ticket fell in still somewhere a player can go? The rain
-- biome only while it is open; a permanent biome only by day.
local function zoneStillOpen(name: string?, rain: boolean, day: boolean): boolean
	if not name then
		return true
	end
	if name == "Rain" then
		return rain
	end
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.Id == name then
			return day
		end
	end
	return true
end

function MiniEventService.ZoneOpen(name: string?): boolean
	return zoneStillOpen(name, rainOpen(), GameConfig.isDay())
end

--==============================================================================
-- DROPS, EXPIRY AND COLLECTION
--==============================================================================
local function unclaimed(event: Event): number
	local n = 0
	for _ in pairs(event.tickets) do
		n += 1
	end
	return n
end

local function drop(event: Event, now: number): Ticket?
	if unclaimed(event) >= T.MaxUnclaimed then
		return nil
	end
	local at, zone = pickSpot(event)
	if not at then
		return nil
	end
	ticketSeq += 1
	local ticket: Ticket = {
		id = ticketSeq,
		at = at,
		droppedAt = now,
		landsAt = now + T.FallSeconds,
		expiresAt = now + T.ExpireSeconds,
		record = nil,
		zone = zone,
	}
	event.tickets[ticket.id] = ticket
	event.dropped += 1
	ticket.record = makeRecord(event, ticket)
	return ticket
end

local function removeTicket(event: Event, ticket: Ticket, claimedBy: number?)
	event.tickets[ticket.id] = nil
	dropRecord(ticket, claimedBy)
end

-- Told at most once per NoticeGapSeconds why a ticket underfoot stays put.
local function tell(event: Event, player: any, id: number, reason: string, count: number, now: number)
	local last = event.toldAt[id]
	if last and now - last < T.NoticeGapSeconds then
		return
	end
	event.toldAt[id] = now
	broadcast(EVENTS.Refused, { id = event.globalId, reason = reason, count = count, cap = T.PerPlayerCap }, { player })
end

-- One player on one landed ticket: take it, or leave it where it lies.
local function collect(event: Event, ticket: Ticket, player: any, now: number): boolean
	if event.tickets[ticket.id] ~= ticket or now < ticket.landsAt or now >= ticket.expiresAt then
		return false
	end
	local id = userIdOf(player)
	if not id then
		return false
	end
	local have = countOf(player, event.globalId)
	if have == nil then
		-- No profile yet: nothing can be saved, so nothing is taken.
		tell(event, player, id, "UNAVAILABLE", 0, now)
		return false
	end
	if have >= T.PerPlayerCap then
		setCount(player, have)
		tell(event, player, id, "CAP", have, now)
		return false
	end
	local ok, granted, why, count = pcall(grant, player, event.globalId, T.PerPlayerCap,
		string.format("%s %s, ticket %d", modeOf(event.mode).Name, short(event.globalId), ticket.id))
	if not ok then
		warn("[Seed/MiniEventService] a ticket's spin failed: " .. tostring(granted))
		tell(event, player, id, "UNAVAILABLE", have, now)
		return false
	end
	local n = if type(count) == "number" then count else have
	if granted ~= true then
		setCount(player, n)
		tell(event, player, id, if why == "CAP" then "CAP" elseif why == "FULL" then "FULL" else "UNAVAILABLE", n, now)
		return false
	end
	-- Granted and claimed on the profile: in the same step the ticket is gone.
	event.collected += 1
	removeTicket(event, ticket, id)
	setCount(player, n)
	broadcast(EVENTS.Collected, { id = event.globalId, count = n, cap = T.PerPlayerCap, at = ticket.at }, { player })
	log(string.format("%s collected ticket %d (%d/%d) in global event %s.", nameOf(player), ticket.id, n,
		T.PerPlayerCap, short(event.globalId)))
	return true
end

-- Does the path from `from` to `to` pass within reach of a ticket at `at`?
local function reaches(from: Vector3, to: Vector3, at: Vector3): boolean
	local a, b, p = flat(from), flat(to), flat(at)
	local ab = b - a
	local length2 = ab:Dot(ab)
	local t = if length2 > 1e-6 then math.clamp((p - a):Dot(ab) / length2, 0, 1) else 1
	local closest = a + ab * t
	if (p - closest).Magnitude > T.PickupRadius then
		return false
	end
	local y = from.Y + (to.Y - from.Y) * t
	local above = y - at.Y
	return above >= -2 and above <= T.PickupHeight
end
MiniEventService.Reaches = reaches

-- Every living body against every landed ticket, swept since the last frame.
function MiniEventService.CheckPickups(now: number)
	local event = current
	if not (event and event.state == "running" and hasTickets(event)) then
		table.clear(lastRoot)
		return
	end
	for _, player in ipairs(playersNow()) do
		local root = rootOf(player)
		local previous = lastRoot[player]
		if root then
			lastRoot[player] = root
		else
			lastRoot[player] = nil
		end
		if root and next(event.tickets) ~= nil then
			local from = previous
			if not from or (root - from).Magnitude > T.TeleportStuds then
				from = root
			end
			local within: { Ticket } = {}
			for _, ticket in pairs(event.tickets) do
				if now >= ticket.landsAt and now < ticket.expiresAt and reaches(from :: Vector3, root, ticket.at) then
					table.insert(within, ticket)
				end
			end
			table.sort(within, function(x: Ticket, y: Ticket): boolean
				return x.id < y.id
			end)
			for _, ticket in ipairs(within) do
				collect(event, ticket, player, now)
			end
		end
	end
end

--==============================================================================
-- THIS SERVER'S PRESENTATION: START, ONE CLOSE, FINISH
--==============================================================================
local function close(event: Event, now: number, why: string)
	if event.state ~= "running" then
		return
	end
	event.state = "ending"
	event.endingAt = now
	local gone = 0
	for _, ticket in pairs(event.tickets) do
		gone += 1
		dropRecord(ticket, nil)
	end
	table.clear(event.tickets)
	publish(event)
	publishCounts(nil)
	log(string.format("%s ending here (%s, global event %s): drops stopped, %d unclaimed ticket(s) removed, %d "
		.. "collected on this server; the effects fade over %d s.", modeOf(event.mode).Name, why, short(event.globalId),
		gone, event.collected, M.FadeSeconds))
end

local function finish(event: Event)
	if current == event then
		current = nil
	end
	for _, ticket in pairs(event.tickets) do
		dropRecord(ticket, nil)
	end
	table.clear(event.tickets)
	local folder = ticketParent:FindFirstChild(M.FolderName)
	if folder then
		folder:ClearAllChildren()
	end
	publish(nil)
	publishCounts(nil)
	table.clear(lastRoot)
	log(string.format("%s over here (global event %s).", modeOf(event.mode).Name, short(event.globalId)))
end

local function startLocal(record: Record, now: number, source: string)
	local announceAt = record.startedAt + M.AnnounceDelaySeconds
	local event: Event = {
		globalId = record.id,
		rev = record.rev,
		mode = record.mode,
		state = "running",
		startedAt = record.startedAt,
		endsAt = record.endsAt,
		endingAt = nil,
		byName = record.byName,
		-- Learned too late to announce (a new server, a late read): silently.
		announced = now > announceAt + G.AnnounceGraceSeconds,
		-- The first ticket a moment in, so the shower has begun by the time the
		-- announcement says so -- or at once, for an event already under way.
		nextDropAt = math.max(now, record.startedAt + math.min(1, M.AnnounceDelaySeconds)),
		nextCountAt = now,
		tickets = {},
		collected = 0,
		dropped = 0,
		toldAt = {},
	}
	current = event
	table.clear(lastRoot)
	publish(event)
	publishCounts(event)
	log(string.format("%s running here (global event %s, rev %d, from %s): %s left of %s, started by %s.",
		modeOf(record.mode).Name, short(record.id), record.rev, source, mmss(record.endsAt - now),
		mmss(record.endsAt - record.startedAt), record.byName))
end

--==============================================================================
-- THE RECORD: CHECKED, ORDERED, APPLIED
--==============================================================================
function MiniEventService.ValidRecord(r: any): boolean
	if type(r) ~= "table" or r.v ~= RECORD_VERSION then
		return false
	end
	if type(r.ns) ~= "string" or type(r.id) ~= "string" or #r.id < 8 or #r.id > 40
		or string.match(r.id, "^[%w]+$") == nil then
		return false
	end
	if type(r.rev) ~= "number" or r.rev ~= math.floor(r.rev) or r.rev < 1 or r.rev > 1e12 then
		return false
	end
	if type(r.mode) ~= "string" or MODES[r.mode] == nil then
		return false
	end
	if type(r.startedAt) ~= "number" or type(r.endsAt) ~= "number" or r.startedAt ~= r.startedAt
		or r.endsAt ~= r.endsAt or r.endsAt <= r.startedAt or r.endsAt - r.startedAt > M.MaxSeconds + 1 then
		return false
	end
	if r.state ~= "running" and r.state ~= "ended" then
		return false
	end
	if type(r.by) ~= "number" or type(r.byName) ~= "string" or #r.byName > 40 then
		return false
	end
	if type(r.endedIds) ~= "table" or #r.endedIds > G.EndedKept * 2 then
		return false
	end
	for _, id in ipairs(r.endedIds) do
		if type(id) ~= "string" or #id > 40 then
			return false
		end
	end
	return true
end

local function tombstone(id: string)
	if tombstones[id] then
		return
	end
	tombstones[id] = true
	table.insert(tombstoneList, id)
	while #tombstoneList > G.EndedKept * 4 do
		local old = table.remove(tombstoneList, 1)
		if old then
			tombstones[old] = nil
		end
	end
end

-- What this server shows, from the newest record it has.
local function reconcile(now: number, source: string)
	local record = known
	local want = record ~= nil and record.state == "running" and now < record.endsAt and not tombstones[record.id]
	local event = current
	if want then
		local r = record :: Record
		if event and event.globalId == r.id then
			event.rev = r.rev
			return
		end
		if event then
			-- An older event still showing (a missed end): it goes at once.
			finish(event)
		end
		startLocal(r, now, source)
	elseif event and event.state == "running" then
		local ended = record ~= nil and record.id == event.globalId and record.state == "ended"
		close(event, now, if ended then "ended globally by " .. tostring((record :: Record).endedByName)
			else "no longer running globally")
	end
end

-- A record from anywhere: storage, a message, this server's own write. Applied
-- only if it is newer than everything seen; answers whether it was.
local function apply(r: any, source: string): boolean
	if not MiniEventService.ValidRecord(r) or r.ns ~= seam.ns then
		return false
	end
	local record = r :: Record
	for _, id in ipairs(record.endedIds) do
		tombstone(id)
	end
	if record.state == "ended" then
		tombstone(record.id)
	end
	local have = known
	if have and record.rev <= have.rev then
		return false
	end
	known = record
	reconcile(clock(), source)
	return true
end
MiniEventService.Apply = apply

-- A message off the topic: held until the first read has been tried.
local function onMessage(data: any)
	if not sync.ready then
		if #sync.pending < 16 then
			table.insert(sync.pending, data)
		end
		return
	end
	apply(data, "message")
end
MiniEventService.OnMessage = onMessage

local function nextPoll(now: number)
	local base = if current ~= nil or (known ~= nil and (known :: Record).state == "running"
		and now < (known :: Record).endsAt) then G.PollSeconds else G.IdlePollSeconds
	local wait = if sync.backoff > 0 then sync.backoff else base
	sync.nextPollAt = now + wait * (1 + (rng:NextNumber() * 2 - 1) * G.PollJitter)
end

-- One read of the record (yields).
function MiniEventService.Poll(): boolean
	if sync.polling then
		return false
	end
	sync.polling = true
	local ok, value = seam.read()
	sync.polling = false
	local now = clock()
	if ok then
		sync.status = if seam.scope == "local" then "local" else "ok"
		sync.lastOkAt = now
		sync.lastError = nil
		sync.backoff = 0
		sync.warned = false
		if value ~= nil then
			apply(value, "storage")
		end
	else
		sync.status = "failing"
		sync.lastError = tostring(value)
		sync.backoff = math.clamp(sync.backoff * 2, 5, G.MaxBackoffSeconds)
		if not sync.warned then
			sync.warned = true
			warn("[Seed/MiniEventService] could not read the shared event record (" .. tostring(value)
				.. "); retrying with backoff. This server may miss a global start or end until it can.")
		end
	end
	if not sync.ready then
		-- The first read has been tried: the held messages now, oldest rev first.
		sync.ready = true
		local held = sync.pending
		sync.pending = {}
		table.sort(held, function(a: any, b: any): boolean
			local ra = if type(a) == "table" and type(a.rev) == "number" then a.rev else 0
			local rb = if type(b) == "table" and type(b.rev) == "number" then b.rev else 0
			return ra < rb
		end)
		for _, data in ipairs(held) do
			apply(data, "message")
		end
	end
	nextPoll(now)
	return ok
end

--==============================================================================
-- ONE STEP OF THIS SERVER'S PRESENTATION
--
-- Public and pure in `now`, so the spec can walk an event through every state
-- on its own clock; the loop below calls it on the server's.
--==============================================================================
function MiniEventService.Step(now: number)
	local event = current
	if not event then
		return
	end
	if event.state == "running" then
		if now >= event.endsAt then
			-- The timer: the same close as an END, on every server at its own
			-- reading of the same absolute time.
			close(event, now, "the timer")
			return
		end
		if not event.announced and now >= event.startedAt + M.AnnounceDelaySeconds then
			event.announced = true
			broadcast(EVENTS.Opened, { id = event.globalId, mode = event.mode }, nil)
		end
		if hasTickets(event) then
			-- Expired, or lying where nobody can go any more: the rain biome
			-- closing, or night shutting the road to the biomes.
			local rain, day = rainOpen(), GameConfig.isDay()
			for _, ticket in pairs(event.tickets) do
				if now >= ticket.expiresAt or not zoneStillOpen(ticket.zone, rain, day) then
					removeTicket(event, ticket, nil)
				end
			end
			if now >= event.nextDropAt then
				drop(event, now)
				local gap = T.DropSeconds + (rng:NextNumber() * 2 - 1) * T.DropJitter
				-- Never a burst to catch up after a stall: the next one from now.
				event.nextDropAt = math.max(event.nextDropAt + gap, now + gap * 0.5)
			end
			if now >= event.nextCountAt then
				event.nextCountAt = now + 1
				publishCounts(event)
			end
		end
	elseif event.state == "ending" then
		if now >= (event.endingAt or now) + M.FadeSeconds then
			finish(event)
		end
	end
end

--==============================================================================
-- READ API
--==============================================================================
-- A copy of this server's presentation, or nil.
function MiniEventService.State(): { [string]: any }?
	local event = current
	if not event then
		return nil
	end
	local tickets = {}
	for _, ticket in pairs(event.tickets) do
		table.insert(tickets, { id = ticket.id, at = ticket.at, landsAt = ticket.landsAt,
			expiresAt = ticket.expiresAt })
	end
	table.sort(tickets, function(a, b)
		return a.id < b.id
	end)
	return {
		id = event.globalId,
		rev = event.rev,
		mode = event.mode,
		state = event.state,
		startedAt = event.startedAt,
		endsAt = event.endsAt,
		endingAt = event.endingAt,
		announced = event.announced,
		tickets = tickets,
		collected = event.collected,
		dropped = event.dropped,
	}
end

-- The newest shared record this server has seen (a copy), or nil.
function MiniEventService.Known(): Record?
	local record = known
	return if record then table.clone(record) else nil
end

-- Where the record lives: the scope ("global" or "local"), the namespace (the
-- store key, which names the place or the Studio test store) and a note.
function MiniEventService.Scope(): (string, string, string)
	return seam.scope, seam.ns, seam.note
end

-- One line for the admins: scope, the record, and how the sync is doing.
function MiniEventService.StatusLine(): string
	local now = clock()
	local parts: { string } = {}
	if seam.scope == "local" then
		table.insert(parts, "THIS SERVER ONLY (Studio, test store off)")
	else
		table.insert(parts, "GLOBAL")
	end
	local record = known
	if record then
		table.insert(parts, string.format("event %s rev %d by %s", short(record.id), record.rev, record.byName))
		if record.state == "ended" then
			table.insert(parts, "ended by " .. tostring(record.endedByName))
		elseif now >= record.endsAt then
			table.insert(parts, "ended by its timer")
		end
	end
	if seam.scope ~= "local" then
		if sync.status == "ok" then
			table.insert(parts, string.format("storage OK %ds ago", math.floor(now - sync.lastOkAt)))
		elseif sync.status == "failing" then
			table.insert(parts, "storage FAILING: " .. string.sub(tostring(sync.lastError), 1, 60))
		else
			table.insert(parts, "storage: first read pending")
		end
		table.insert(parts, if sync.subscribed then "notices on" else "notices OFF (polling only)")
	end
	return table.concat(parts, " · ")
end

--==============================================================================
-- START AND END, FOR EVERY SERVER
--
-- Both are reached from AdminService alone, after ITS checks: the allowlist
-- (IsAdmin, by UserId) and the one-a-second limit. Here: a known mode, a
-- whole duration in range, one request at a time on this server, and the
-- store's own serialisation for every server. What the admin is told is what
-- actually happened -- the store write, and whether the instant notice went
-- out -- never "started everywhere", which no server can know.
--==============================================================================
local function newId(): string
	return string.sub((string.gsub(HttpService:GenerateGUID(false), "-", "")), 1, 16)
end

local function carryEnded(previous: Record?, also: string?): { string }
	local list: { string } = {}
	if previous then
		for _, id in ipairs(previous.endedIds) do
			table.insert(list, id)
		end
	end
	if also and not table.find(list, also) then
		table.insert(list, also)
	end
	while #list > G.EndedKept do
		table.remove(list, 1)
	end
	return list
end

local function noticeLine(okPub: boolean, why: string?): string
	if seam.scope == "local" then
		return "Studio without the test store: this server only, nothing was sent to other servers."
	end
	if okPub then
		return string.format("The instant notice to other servers was sent (best effort); any server that misses "
			.. "it catches up from storage within about %d s.", math.ceil(G.PollSeconds * (1 + G.PollJitter)))
	end
	return string.format("The instant notice to other servers FAILED (%s); they catch up from storage when they "
		.. "next check, within about %d s.", string.sub(tostring(why), 1, 60), math.ceil(G.IdlePollSeconds * (1 + G.PollJitter)))
end

local function startGlobal(by: any, mode: string, seconds: number): (boolean, string)
	local id = newId()
	local byId = userIdOf(by) or 0
	local byName = string.sub(nameOf(by), 1, 40)
	local existing: Record? = nil
	local written: Record? = nil
	local okUpdate, err = seam.update(function(old: any): any
		existing, written = nil, nil
		local t = clock()
		local previous: Record? = if MiniEventService.ValidRecord(old) and old.ns == seam.ns then old else nil
		if previous and previous.state == "running" and t < previous.endsAt and not tombstones[previous.id] then
			existing = previous
			return nil
		end
		local finished = if previous and previous.state ~= "ended" then previous.id else nil
		local record: Record = {
			v = RECORD_VERSION,
			ns = seam.ns,
			id = id,
			rev = (if previous then previous.rev else 0) + 1,
			mode = mode,
			startedAt = t,
			endsAt = t + seconds,
			by = byId,
			byName = byName,
			state = "running",
			endedAt = nil,
			endedBy = nil,
			endedByName = nil,
			endedIds = carryEnded(previous, finished),
		}
		written = record
		return record
	end)
	local name = modeOf(mode).Name
	if not okUpdate then
		return false, string.format("Couldn't reach the shared event store, so NO global event was started (%s). "
			.. "Try again in a moment.", string.sub(tostring(err), 1, 80))
	end
	if existing then
		local e = existing :: Record
		apply(e, "storage")
		return false, string.format("%s is already running globally (event %s, %s left, started by %s). Nothing "
			.. "changed: its timer and its caps are untouched.", modeOf(e.mode).Name, short(e.id), mmss(e.endsAt - clock()),
			e.byName)
	end
	local record = written
	if not record then
		return false, "The shared event store did not confirm the start. Nothing was started; try again."
	end
	apply(record, "this server")
	local okPub, why = seam.publish(record)
	local scopeWord = if seam.scope == "local" then "THIS SERVER ONLY" else "saved to shared storage"
	local tickets = if modeOf(mode).Tickets
		then string.format(" Up to %d tickets per player for the whole event.", T.PerPlayerCap) else ""
	return true, string.format("Global %s started for %s: %s (event %s, rev %d) and running on this server.%s %s",
		name, mmss(seconds), scopeWord, short(record.id), record.rev, tickets, noticeLine(okPub, why))
end

local function endGlobal(by: any): (boolean, string, boolean)
	local byId = userIdOf(by) or 0
	local byName = string.sub(nameOf(by), 1, 40)
	local nothing: Record? = nil
	local ended: Record? = nil
	local okUpdate, err = seam.update(function(old: any): any
		nothing, ended = nil, nil
		local t = clock()
		local previous: Record? = if MiniEventService.ValidRecord(old) and old.ns == seam.ns then old else nil
		if not previous or previous.state ~= "running" or t >= previous.endsAt then
			nothing = previous
			return nil
		end
		local p = previous :: Record
		local record: Record = table.clone(p)
		record.state = "ended"
		record.rev = p.rev + 1
		record.endedAt = t
		record.endedBy = byId
		record.endedByName = byName
		record.endedIds = carryEnded(p, p.id)
		ended = record
		return record
	end)
	if not okUpdate then
		return false, string.format("Couldn't reach the shared event store, so the global event was NOT ended "
			.. "anywhere (%s). Try again in a moment.", string.sub(tostring(err), 1, 80)), false
	end
	local record = ended
	if not record then
		local n = nothing
		if n then
			apply(n, "storage")
		end
		local over = n ~= nil and n.state == "running"
		return true, if over then "The global event already ended by its timer. Nothing more to do."
			else "No global event is running. Nothing changed.", false
	end
	apply(record, "this server")
	local okPub, why = seam.publish(record)
	return true, string.format("Global %s ended (event %s, rev %d): recorded in shared storage and ended on this "
		.. "server; unclaimed tickets are gone, collected spins are kept. %s", modeOf(record.mode).Name,
		short(record.id), record.rev, noticeLine(okPub, why)), true
end

-- Named apart from the lifecycle's Start(), which ServerMain calls.
function MiniEventService.StartGlobal(by: any, mode: any, seconds: any): (boolean, string)
	if type(mode) ~= "string" or MODES[mode] == nil then
		return false, "Unknown mini event. Nothing changed."
	end
	if type(seconds) ~= "number" or seconds ~= seconds or seconds ~= math.floor(seconds)
		or seconds < M.MinSeconds or seconds > M.MaxSeconds then
		return false, string.format("Duration must be a whole number of seconds from %d to %d. Nothing changed.",
			M.MinSeconds, M.MaxSeconds)
	end
	if requestBusy then
		return false, "A global event request is already in progress on this server. Wait for its answer."
	end
	requestBusy = true
	local ok, started, message = pcall(startGlobal, by, mode, seconds)
	requestBusy = false
	if not ok then
		warn("[Seed/MiniEventService] a global start failed: " .. tostring(started))
		return false, "The server hit an error starting the global event; nothing is confirmed. Check the log."
	end
	if started then
		log(string.format("%s asked for a global %s: %s", nameOf(by), mode, message))
	end
	return started, message
end

-- The third answer: whether this call ended anything (for the record).
function MiniEventService.EndGlobal(by: any): (boolean, string, boolean)
	if requestBusy then
		return false, "A global event request is already in progress on this server. Wait for its answer.", false
	end
	requestBusy = true
	local ok, done, message, ended = pcall(endGlobal, by)
	requestBusy = false
	if not ok then
		warn("[Seed/MiniEventService] a global end failed: " .. tostring(done))
		return false, "The server hit an error ending the global event; nothing is confirmed. Check the log.", false
	end
	return done, message, ended
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function dropConnections()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
end

-- Everything this file keeps, back to nothing (Init, and the spec between runs).
function MiniEventService.Reset()
	running = false
	generation += 1
	dropConnections()
	local event = current
	current = nil
	if event then
		for _, ticket in pairs(event.tickets) do
			dropRecord(ticket, nil)
		end
	end
	local stale = ticketParent:FindFirstChild(M.FolderName)
	if stale then
		stale:Destroy()
	end
	known = nil
	table.clear(tombstoneList)
	table.clear(tombstones)
	table.clear(lastRoot)
	requestBusy = false
	sync.status = "starting"
	sync.lastOkAt = 0
	sync.lastError = nil
	sync.subscribed = false
	sync.nextPollAt = 0
	sync.backoff = 0
	sync.polling = false
	sync.ready = false
	sync.pending = {}
	sync.warned = false
	publish(nil)
	for _, player in ipairs(Players:GetPlayers()) do
		setCount(player, nil)
	end
end

function MiniEventService.Init()
	MiniEventService.Reset()
end

function MiniEventService.Start()
	seam = resolveSeam()
	generation += 1
	local mine = generation
	running = true
	-- The topic first, so nothing published after the first read is missed;
	-- what arrives before it waits for that read (onMessage).
	task.spawn(function()
		local pause = 5
		while running and mine == generation do
			local ok, why = seam.subscribe(onMessage)
			if ok then
				sync.subscribed = true
				return
			end
			warn(string.format("[Seed/MiniEventService] could not subscribe to global event notices (%s); "
				.. "retrying in %d s (storage is still checked).", tostring(why), pause))
			task.wait(pause)
			pause = math.min(pause * 2, 120)
		end
	end)
	-- This server's presentation, ten times a second, and the record's re-read
	-- when it is due (off this thread: a read yields).
	task.spawn(function()
		while running and mine == generation do
			local now = clock()
			local ok, err = pcall(MiniEventService.Step, now)
			if not ok then
				warn("[Seed/MiniEventService] step failed: " .. tostring(err))
			end
			if not sync.polling and now >= sync.nextPollAt then
				sync.nextPollAt = math.huge
				task.spawn(function()
					local okPoll, errPoll = pcall(MiniEventService.Poll)
					if not okPoll then
						warn("[Seed/MiniEventService] poll failed: " .. tostring(errPoll))
						sync.polling = false
						sync.nextPollAt = clock() + G.PollSeconds
					end
				end)
			end
			task.wait(M.TickSeconds)
		end
	end)
	table.insert(connections, RunService.Heartbeat:Connect(function()
		if current then
			local ok, err = pcall(MiniEventService.CheckPickups, clock())
			if not ok then
				warn("[Seed/MiniEventService] pickup check failed: " .. tostring(err))
			end
		end
	end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
		lastRoot[player] = nil
	end))
	log(string.format("Ready (%s). Mini events are the admins' to start, %d to %d s, %d s by default; tickets: "
		.. "one every ~%d s per server, at most %d unclaimed, %d per player per GLOBAL event, each one free earned spin.",
		seam.note, M.MinSeconds, M.MaxSeconds, M.DefaultSeconds, T.DropSeconds, T.MaxUnclaimed, T.PerPlayerCap))
end

function MiniEventService.Stop()
	running = false
	generation += 1
	dropConnections()
end

return MiniEventService
