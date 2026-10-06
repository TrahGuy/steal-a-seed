--!strict
-- Steal a Seed :: InviteService
--
-- Invite a Friend (2026-10-06, the owner's track): a friend who joins the game
-- through a player's invite counts once for that player, forever; at 1, 5, 10
-- and 20 such friends the player is GIVEN a grown, placeable, unsellable plant
-- (GameConfig.InviteRewards, SeedData.InviteSpecies). This file counts, gives
-- and publishes -- the server alone -- and builds the hub pedestal every
-- client draws its own form on (InviteHub).
--
--==============================================================================
-- WHAT COUNTS
--
-- A join counts when the joining player's GetJoinData().ReferredByPlayerId
-- names the inviter, the two are different players, and the joiner is a
-- first-time player of the game: their save was NEW this session
-- (PlayerDataService.IsNewProfile) -- unless CountReturningPlayers says
-- otherwise. Each friend counts once per inviter, forever: the inviter's save
-- keeps the SET of ids (InviteIds), never just a number, so a friend who
-- rejoins, or joins from a second invite, adds nothing.
--
-- WHERE THE CREDIT GOES
--
-- To the inviter's profile when the inviter is in this server; otherwise to
-- the inviter's INBOX (SaveService), in the same store as the profiles, which
-- their own server takes when their profile loads and every InboxPollSeconds
-- while they play. Taken in this order -- added to the profile, the profile
-- SAVED, and only then taken out of the inbox -- so a crash between the two
-- leaves the ids in both, and the set takes them once.
--
-- WHAT IS GIVEN, ONCE
--
-- Whenever the count earns a form the profile has not been given, the form is
-- handed over the way a hatch hands one over (CarryService.GiveHatched with
-- onRecord: the Bag's room counted, the Held row written, or nothing at all)
-- and InviteGranted is raised in the SAME resumption, so a save holds the
-- plant and its marker together or neither. A full Bag gives nothing: the form
-- waits, the player is told once, and it is tried again every RetrySeconds.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local InviteRewards = require(Shared:WaitForChild("InviteRewards"))

local SaveService = require(script.Parent:WaitForChild("SaveService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local CONFIG = GameConfig.InviteRewards

local InviteService = {}
-- After CarryService (45), whose GiveHatched it uses, and SellService (65).
InviteService.Priority = 67

-- A grant into the Bag, never into the hands (AdminService's NO_EQUIP).
local NO_EQUIP = -1
-- The verb this service tells its clients with, on GameEvent.
InviteService.NoticeAction = CONFIG.NoticeAction

local channel: RemoteEvent? = nil

--==============================================================================
-- SEAMS FOR THE SPEC
--
-- The engine's join data, the clock and the wire to one client, replaceable by
-- InviteRewardsSpec; the game never changes them.
--==============================================================================
InviteService.Hooks = {
	joinData = function(player: Player): any
		local ok, data = pcall(function()
			return player:GetJoinData()
		end)
		return if ok then data else nil
	end,
	now = os.clock,
	playerById = function(id: number): Player?
		return Players:GetPlayerByUserId(id)
	end,
	send = function(player: Player, payload: { [string]: any })
		local remote = channel
		if remote then
			pcall(function()
				remote:FireClient(player, InviteService.NoticeAction, payload)
			end)
		end
	end,
	-- A person's DisplayName for the notices: theirs if they are in this
	-- server, else Roblox's (UserService), else nil -- the client then says
	-- "a friend". Never a UserId.
	displayName = function(id: number): string?
		local here = Players:GetPlayerByUserId(id)
		if here then
			return here.DisplayName
		end
		local ok, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync({ id })
		end)
		local info = if ok and type(infos) == "table" then infos[1] else nil
		local name = if type(info) == "table" then info.DisplayName else nil
		return if type(name) == "string" and name ~= "" then name else nil
	end,
}

local serviceConnections: { RBXScriptConnection } = {}
local running = false
-- Players with a form earned and not given (the Bag was full).
local owed: { [Player]: boolean } = {}
-- The tier a player was last told "make room" for, so it is said once.
local fullTold: { [Player]: number } = {}
-- When each player's inbox was last read.
local inboxAt: { [Player]: number } = {}
-- What a player was told before their client said READY (CONFIG.ReadyAction),
-- in order, and who has said it. A join's WELCOME!, an inbox's +1 and a form
-- given while the profile loaded happen before the client's scripts listen.
local held: { [Player]: { { [string]: any } } } = {}
local listening: { [Player]: boolean } = {}

local function log(message: string)
	print("[Seed/InviteService] " .. message)
end

-- DisplayNames already asked for (false: Roblox had none), so a name costs one
-- lookup a server.
local names: { [number]: string | boolean } = {}
local function nameOf(id: number): string?
	local known = names[id]
	if known == nil then
		local ok, name = pcall(InviteService.Hooks.displayName, id)
		known = if ok and type(name) == "string" and name ~= "" then name else false
		names[id] = known
	end
	return if type(known) == "string" then known else nil
end

local function tell(player: Player, payload: { [string]: any })
	if player.Parent ~= Players then
		return
	end
	if not listening[player] then
		local list = held[player] or {}
		held[player] = list
		table.insert(list, payload)
		while #list > CONFIG.HeldMax do
			table.remove(list, 1)
		end
		return
	end
	InviteService.Hooks.send(player, payload)
end

-- The client listens now (it said READY): what it was told before then, in order.
function InviteService.Ready(player: Player)
	if listening[player] then
		return
	end
	listening[player] = true
	local list = held[player]
	held[player] = nil
	for _, payload in ipairs(list or {}) do
		tell(player, payload)
	end
end

-- A whole, positive UserId, or nil.
local function userId(value: any): number?
	if type(value) ~= "number" or value ~= value or value < 1 or value >= 2 ^ 53 or math.floor(value) ~= value then
		return nil
	end
	return value
end

--==============================================================================
-- 1. FRIENDS ADDED TO A PROFILE IN THIS SERVER
--
-- Each id once, never the player's own; answers how many were new.
--==============================================================================
local function addIds(player: Player, ids: { number }): (number, { number })
	local fresh: { number } = {}
	PlayerDataService.UpdateInvites(player, function(profile: any): boolean
		local list = profile.InviteIds
		local seen: { [number]: boolean } = {}
		for _, id in ipairs(list) do
			seen[id] = true
		end
		for _, id in ipairs(ids) do
			if id ~= player.UserId and not seen[id] then
				seen[id] = true
				table.insert(list, id)
				table.insert(fresh, id)
			end
		end
		while #list > CONFIG.MaxRemembered do
			table.remove(list, 1)
		end
		return #fresh > 0
	end)
	return #fresh, fresh
end

local function countOf(player: Player): number
	local profile = PlayerDataService.Get(player) :: any
	return if profile then #(profile.InviteIds or {}) else 0
end

--==============================================================================
-- 2. WHAT THE COUNT HAS EARNED, GIVEN ONCE (see WHAT IS GIVEN, ONCE)
--==============================================================================
local function grantOwed(player: Player): number
	local profile = PlayerDataService.Get(player) :: any
	if not profile or not PlayerDataService.IsPersistent(player) then
		return 0
	end
	local earned = InviteRewards.tierFor(#(profile.InviteIds or {}))
	local given = 0
	while (profile.InviteGranted or 0) < earned do
		local tier = (profile.InviteGranted or 0) + 1
		local species = SeedData.Get(CONFIG.Forms[tier])
		if not species then
			break
		end
		local ok, why = CarryService.GiveHatched(player, species, SeedData.InviteTier, NO_EQUIP, nil, true)
		if not ok then
			owed[player] = true
			if why == "STORAGE_FULL" and fullTold[player] ~= tier then
				fullTold[player] = tier
				tell(player, { kind = "full", tier = tier })
			end
			log(string.format("%s: form %d (%s) waits (%s).", player.Name, tier, species.Name, tostring(why)))
			break
		end
		-- The Held row is written; the marker goes on in this same resumption.
		PlayerDataService.UpdateInvites(player, function(p: any): boolean
			p.InviteGranted = tier
			p.InviteSeen = false
			return true
		end)
		given += 1
		fullTold[player] = nil
		log(string.format("%s was given %s (form %d) for %d invite(s).", player.Name, species.Name, tier,
			#(profile.InviteIds or {})))
		tell(player, { kind = "granted", tier = tier, form = species.Id })
	end
	if (profile.InviteGranted or 0) >= earned then
		owed[player] = nil
	end
	if given > 0 then
		task.spawn(PlayerDataService.Save, player)
	end
	return given
end
InviteService.GrantOwed = grantOwed

--==============================================================================
-- 3. THE INBOX (see WHERE THE CREDIT GOES)
--==============================================================================
local function idsIn(box: any): { number }
	local out: { number } = {}
	if type(box) == "table" and type(box.Ids) == "table" then
		for _, value in ipairs(box.Ids) do
			local id = userId(value)
			if id then
				table.insert(out, id)
			end
		end
	end
	return out
end

-- `atJoin`: the take as the player arrives -- friends credited while they were
-- away, told once as WHILE YOU WERE AWAY. Later takes (every InboxPollSeconds)
-- are friends joining elsewhere while they play: a +1 INVITE each, by name.
local function takeInbox(player: Player, atJoin: boolean?): number
	inboxAt[player] = InviteService.Hooks.now()
	if not PlayerDataService.IsPersistent(player) then
		return 0
	end
	local ok, box = SaveService.ReadInbox(player.UserId)
	if not ok then
		return 0
	end
	local ids = idsIn(box)
	if #ids == 0 then
		return 0
	end
	local added, fresh = addIds(player, ids)
	-- In the profile now; saved, and only then out of the inbox.
	if not PlayerDataService.Save(player) then
		return added
	end
	local taken: { [number]: boolean } = {}
	for _, id in ipairs(ids) do
		taken[id] = true
	end
	SaveService.UpdateInbox(player.UserId, function(old: any): any
		local keep: { number } = {}
		for _, id in ipairs(idsIn(old)) do
			if not taken[id] then
				table.insert(keep, id)
			end
		end
		return { Ids = keep }
	end)
	if added > 0 then
		local count = countOf(player)
		log(string.format("%s took %d invited friend(s) from their inbox (now %d).", player.Name, added, count))
		if atJoin then
			tell(player, { kind = "away", count = added })
		else
			for i, id in ipairs(fresh) do
				tell(player, { kind = "joined", name = nameOf(id), count = count - added + i })
			end
		end
	end
	return added
end
InviteService.TakeInbox = takeInbox

-- A friend's join that did not count, told to the inviter if they are here.
local function notCounted(inviterId: number, name: string?, why: string)
	local here = InviteService.Hooks.playerById(inviterId)
	if here then
		tell(here, { kind = "notcounted", name = name, why = why })
	end
end

--==============================================================================
-- 4. A CREDIT: inviter `inviterId` gets friend `inviteeId`
--
-- Answers where it went: "here" (the inviter's profile in this server), "inbox"
-- (their inbox), "known" (here, and already counted), or "failed". The inviter
-- here is told either way: +1 INVITE, or that the friend joined and why it did
-- not count. `inviteeName` is the friend's DisplayName where it is known.
--==============================================================================
function InviteService.Credit(inviterId: number, inviteeId: number, inviteeName: string?): string
	local inviter = userId(inviterId)
	local invitee = userId(inviteeId)
	if not inviter or not invitee or inviter == invitee then
		return "failed"
	end
	local here = InviteService.Hooks.playerById(inviter)
	if here and PlayerDataService.IsReady(here) and PlayerDataService.IsPersistent(here) then
		if (addIds(here, { invitee })) == 0 then
			tell(here, { kind = "notcounted", name = inviteeName or nameOf(invitee), why = "known" })
			return "known"
		end
		log(string.format("%s's invite brought a friend (%d); now %d.", here.Name, invitee, countOf(here)))
		tell(here, { kind = "joined", name = inviteeName or nameOf(invitee), count = countOf(here) })
		grantOwed(here)
		task.spawn(PlayerDataService.Save, here)
		return "here"
	end
	local wrote = SaveService.UpdateInbox(inviter, function(old: any): any
		local ids = idsIn(old)
		for _, id in ipairs(ids) do
			if id == invitee then
				-- Already waiting: nothing to write.
				return nil
			end
		end
		table.insert(ids, invitee)
		while #ids > CONFIG.InboxMax do
			table.remove(ids, 1)
		end
		return { Ids = ids }
	end)
	if wrote then
		log(string.format("A friend (%d) of %d joined; the credit waits in their inbox.", invitee, inviter))
	end
	return if wrote then "inbox" else "failed"
end

--==============================================================================
-- 5. A JOIN, AS AN INVITED FRIEND (see WHAT COUNTS)
--==============================================================================
function InviteService.CreditJoin(joiner: Player): string
	local data = InviteService.Hooks.joinData(joiner)
	local inviter = if type(data) == "table" then userId(data.ReferredByPlayerId) else nil
	if not inviter then
		return "none"
	end
	if inviter == joiner.UserId then
		return "self"
	end
	if not CONFIG.CountReturningPlayers and not PlayerDataService.IsNewProfile(joiner) then
		log(string.format("%s joined from %d's invite but has played before: not counted.", joiner.Name, inviter))
		notCounted(inviter, joiner.DisplayName, "returning")
		return "returning"
	end
	local result = InviteService.Credit(inviter, joiner.UserId, joiner.DisplayName)
	-- Their join counted, on a referral this server read: the friend is
	-- welcomed, once, by their inviter's name (InviteUI's WELCOME!).
	if result == "here" or result == "inbox" then
		tell(joiner, { kind = "welcome", name = nameOf(inviter) })
	end
	return result
end

-- The INVITE panel was opened: the "!" comes off (a single saved flag).
function InviteService.MarkSeen(player: Player): boolean
	return PlayerDataService.UpdateInvites(player, function(profile: any): boolean
		if profile.InviteSeen == true then
			return false
		end
		profile.InviteSeen = true
		return true
	end)
end

--==============================================================================
-- STUDIO TEST PATH (the brief's "fake join data in the test store")
--
-- A join from `inviteeId` carrying ReferredByPlayerId = `inviterId`, judged by
-- exactly the rules a real join is (first-time unless told otherwise). Studio
-- only: a live server refuses, whatever calls it, so no test path ships live.
--==============================================================================
function InviteService.SimulateJoin(inviteeId: number, inviterId: number, firstTime: boolean): string
	if not RunService:IsStudio() then
		return "refused"
	end
	if inviteeId == inviterId then
		return "self"
	end
	if not CONFIG.CountReturningPlayers and not firstTime then
		notCounted(inviterId, nameOf(inviteeId), "returning")
		return "returning"
	end
	return InviteService.Credit(inviterId, inviteeId)
end

--==============================================================================
-- THE HUB PEDESTAL (shared; every client draws its own form and sign on it)
--
-- Stone foot and column like the Sacrifice pedestal's, a studded top, two
-- pillars and the studded plate resting on them over the form; the plate's words
-- and bar are each client's (InviteHub draws them in its PlayerGui, adorned to
-- the plate). Persistent, like the other hub pieces a client draws on.
--==============================================================================
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3,
	material: Enum.Material, studs: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	local kind = if studs then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	p.TopSurface = kind
	p.BottomSurface = kind
	p.FrontSurface = kind
	p.BackSurface = kind
	p.LeftSurface = kind
	p.RightSurface = kind
	p.Parent = parent
	return p
end

-- Where the pedestal's top surface meets a form's base: the CFrame a client
-- stands its form on (front, -Z, to the deck's centre).
InviteService.StandFrame = InviteRewards.standFrame

local function build(): BasePart?
	local old = Workspace:FindFirstChild(CONFIG.FolderName)
	if old then
		old:Destroy()
	end
	if not CONFIG.Enabled then
		return nil
	end
	local P, S = CONFIG.Pedestal, CONFIG.Sign
	local folder = Instance.new("Folder")
	folder.Name = CONFIG.FolderName
	folder.Archivable = false
	local model = Instance.new("Model")
	model.Name = "InvitePedestal"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = folder

	local origin = CFrame.new(CONFIG.Position) * CFrame.Angles(0, math.rad(CONFIG.FacingDegrees), 0)
	part(model, "Foot", P.Foot, origin * CFrame.new(0, P.Foot.Y / 2, 0), P.Stone, Enum.Material.Slate)
	part(model, "Column", P.Column, origin * CFrame.new(0, P.Foot.Y + P.Column.Y / 2, 0), P.Stone,
		Enum.Material.Slate)
	local top = part(model, "Top", P.Top, origin * CFrame.new(0, P.Foot.Y + P.Column.Y + P.Top.Y / 2, 0),
		P.TopColour, Enum.Material.Plastic, true)

	-- The sign: two pillars beside the pedestal, their feet where they stood
	-- beside the 14-stud plate (PillarHalf), ending under the plate's keyline;
	-- the plate rests on them and overhangs them.
	local half = S.PillarHalf
	local pillarH = S.Bottom - S.Keyline
	part(model, "PillarL", Vector3.new(S.PillarWidth, pillarH, S.PillarWidth),
		origin * CFrame.new(-half, pillarH / 2, 0), P.Stone, Enum.Material.Slate)
	part(model, "PillarR", Vector3.new(S.PillarWidth, pillarH, S.PillarWidth),
		origin * CFrame.new(half, pillarH / 2, 0), P.Stone, Enum.Material.Slate)
	local look = GameConfig.BagLook
	local plateCf = origin * CFrame.new(0, S.Bottom + S.Height / 2, 0)
	-- The dark keyline: a slightly larger, thinner backing behind the plate.
	local edge = part(model, "SignEdge", Vector3.new(S.Width + S.Keyline * 2, S.Height + S.Keyline * 2, S.Depth * 0.6),
		plateCf, look.PlateEdge, Enum.Material.Plastic)
	edge.CanCollide = false
	local plate = part(model, "SignPlate", Vector3.new(S.Width, S.Height, S.Depth), plateCf, look.PlateFill,
		Enum.Material.Plastic, true)
	plate.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InvitePrompt"
	-- Custom, so PromptUI draws it in the same chrome as every other prompt.
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = CONFIG.PromptAction
	prompt.ObjectText = CONFIG.PromptObject
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CONFIG.PromptDistance
	prompt.RequiresLineOfSight = false
	-- The client answers it: SocialService's invite prompt is the player's own.
	prompt.Parent = top
	model.PrimaryPart = top

	folder.Parent = Workspace
	return top
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function arrive(player: Player)
	task.spawn(function()
		local started = os.clock()
		while running and player.Parent == Players and not PlayerDataService.IsReady(player)
			and os.clock() - started < 120 do
			task.wait(0.5)
		end
		if not running or player.Parent ~= Players or not PlayerDataService.IsReady(player) then
			return
		end
		PlayerDataService.PublishInvites(player)
		-- As an invited friend, then as an inviter: their own inbox (WHILE YOU
		-- WERE AWAY), then the forms.
		InviteService.CreditJoin(player)
		takeInbox(player, true)
		grantOwed(player)
	end)
end

function InviteService.Init()
	running = false
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	table.clear(owed)
	table.clear(fullTold)
	table.clear(inboxAt)
	table.clear(held)
	table.clear(listening)
	channel = nil
end

function InviteService.Start()
	if not CONFIG.Enabled then
		return
	end
	build()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil
	local remote = channel
	if remote then
		table.insert(serviceConnections, remote.OnServerEvent:Connect(function(player: Player, action: any)
			if action == CONFIG.OpenedAction then
				InviteService.MarkSeen(player)
			elseif action == CONFIG.ReadyAction then
				InviteService.Ready(player)
			end
		end))
	end
	running = true
	table.insert(serviceConnections, Players.PlayerAdded:Connect(arrive))
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		owed[player] = nil
		fullTold[player] = nil
		inboxAt[player] = nil
		held[player] = nil
		listening[player] = nil
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		arrive(player)
	end
	-- Owed forms every RetrySeconds; each inbox every InboxPollSeconds.
	task.spawn(function()
		while running do
			task.wait(CONFIG.RetrySeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				if running and PlayerDataService.IsReady(player) then
					if owed[player] then
						grantOwed(player)
					end
					local last = inboxAt[player]
					if last and InviteService.Hooks.now() - last >= CONFIG.InboxPollSeconds then
						inboxAt[player] = InviteService.Hooks.now()
						task.spawn(function()
							takeInbox(player)
							grantOwed(player)
						end)
					end
				end
			end
		end
	end)
end

return InviteService
