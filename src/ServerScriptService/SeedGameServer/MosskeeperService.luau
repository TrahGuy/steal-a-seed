--!strict
--==============================================================================
-- Steal a Seed :: MosskeeperService (2026-10-11, Enchanted Mist stage 3)
--
-- THE MOSSKEEPER (KB/ENCHANTED-MIST-RESET-ALIGNED-CLAUDE-PROMPT.md §8-9): the
-- resident NPC on GameConfig.Map.EventHub.NpcAnchor, the owner's own model
-- (Shared/MosskeeperModel), shown once EnchantedMistConfig.ShowMosskeeper is
-- on. THE EVENT HUB, ALWAYS (the owner, 2026-10-11; it replaced "only during
-- a Mist"): with him, built once at start and standing Mist or not, his
-- surround (the owner's Shared/MistSurroundModel) with him on its pad, and the
-- deck's dress (Shared/MistDeckModel: A's moss carpet, C's mushroom ring, the
-- grove). It is the server's, so it replicates to everybody, late joiners too.
-- Only the Mist's LOOK (MistLook: the night light, wisps, fireflies, glints)
-- comes and goes with a Mist.
--
-- TAP E -- TALK opens his dialogue on that player's screen (MosskeeperUI);
-- the server says nothing else until the player asks to GIVE ALL. Talk works
-- whether or not a Mist runs; a deposit does not.
--
-- GIVE ALL, the server's alone: every berry the player carries (up to the
-- carry cap) joins their saved progress; ten make a pod; one delivery earns at
-- most one (EnchantedMistData.deliver). Checked, in order: one request at a
-- time per player (and GiveGap apart), him standing, an active Mist, a living
-- body within TalkReach + ReachSlack of his prompt, no pod in hand, a loaded
-- profile, berries to give. A delivery that would EARN a pod also needs the
-- Mysterious Pod's grant (Hooks.grantPod -- stage 4; until it exists such a
-- delivery is refused), the Bag restored and room in its pod storage --
-- otherwise the WHOLE delivery is refused, nothing deducted ("Make room in your
-- Bag"). A delivery under the threshold succeeds with a full Bag. The carried
-- count, the remaining progress and the pod's grant are one profile change
-- (PlayerDataService.UpdateDewberries), with nothing that yields inside it; the
-- client's numbers are never read.
--==============================================================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local MosskeeperModel = require(Shared:WaitForChild("MosskeeperModel"))
local MistSurroundModel = require(Shared:WaitForChild("MistSurroundModel"))
local MistDeckModel = require(Shared:WaitForChild("MistDeckModel"))
local MosskeeperTalk = require(Shared:WaitForChild("MosskeeperTalk"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local EnchantedMistService = require(script.Parent:WaitForChild("EnchantedMistService"))

local MosskeeperService = {}
-- After EnchantedMistService (75) and its berries (76); before
-- MysteryPodService (78), which fills the grant hook below.
MosskeeperService.Priority = 77

local CFG = EnchantedMistConfig.Mosskeeper
local HUB = GameConfig.Map.EventHub
local CAP = EnchantedMistData.CarryCap
local PER_POD = EnchantedMistData.BerriesPerPod

local function log(message: string)
	print("[Seed/MosskeeperService] " .. message)
end

--==============================================================================
-- SPEC-REPLACEABLE HOOKS: every reach outside this file.
--==============================================================================
MosskeeperService.Hooks = {
	now = function(): number
		return os.clock()
	end,
	shown = function(): boolean
		return EnchantedMistConfig.ShowMosskeeper == true
	end,
	active = function(): boolean
		return EnchantedMistService.IsActive()
	end,
	ready = function(player: any): boolean
		return PlayerDataService.IsReady(player)
	end,
	profile = function(player: any): any
		return PlayerDataService.Get(player)
	end,
	update = function(player: any, change: (any) -> boolean): boolean
		return PlayerDataService.UpdateDewberries(player, change)
	end,
	-- A living body's root position, or nil.
	root = function(player: any): Vector3?
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return root.Position
		end
		return nil
	end,
	carryingPod = function(player: any): boolean
		return player:GetAttribute(GameConfig.Attributes.CarryingSpecies) ~= nil
	end,
	bagReady = function(player: any): boolean
		return CarryService.IsHeldRestored(player)
	end,
	-- Free places in the Bag's pod storage; 0 when not known.
	podRoom = function(player: any): number
		local room, _, known = CarryService.PodRoom(player)
		return if known then room else 0
	end,
	-- STAGE 4 (Built.MysteriousPod): puts one Mysterious Pod in `profile`, inside
	-- the delivery's own profile change, and must not yield; false refuses the
	-- whole delivery. nil until it exists: no delivery can earn a pod yet.
	grantPod = nil :: ((player: any, profile: any) -> boolean)?,
	-- Whether a pod can be granted at all now (stage 4: every pool creature
	-- real); false refuses a pod-earning delivery as not ready.
	canGrant = function(): boolean
		return true
	end,
	-- A save soon after a pod is granted (stage 4).
	saveSoon = function(_player: any) end,
	-- Start points these at the GameEvent remote.
	send = function(_player: any, _payload: { [string]: any }) end,
	notify = function(_player: any, _payload: { [string]: any }) end,
	-- An admin's line goes up for everybody, late joiners too, in server time.
	serverNow = function(): number
		return Workspace:GetServerTimeNow()
	end,
	publish = function(value: string)
		Workspace:SetAttribute(CFG.SaidAttribute, value)
	end,
	parent = function(): Instance
		local folder = Workspace:FindFirstChild(CFG.FolderName)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = CFG.FolderName
			folder.Archivable = false
			folder.Parent = Workspace
		end
		return folder :: Instance
	end,
}
local Hooks = MosskeeperService.Hooks

--==============================================================================
-- HIM, AND HIS SURROUND
--==============================================================================
local npc: Model? = nil
local surround: Model? = nil
-- The hub deck's dress (Shared/MistDeckModel), standing with the surround.
local deck: Model? = nil

-- Where his feet go: the surround's pad, which stands with him (the plaza's
-- visible floor only in the moment before it is built).
function MosskeeperService.FeetLift(): number
	if surround then
		return MistSurroundModel.PadHeight
	end
	return HUB.Floor.Rise + 0.02
end

local function standHim()
	local model = npc
	if model and model.Parent then
		model:PivotTo(HUB.NpcAnchor * CFrame.new(0, MosskeeperService.FeetLift(), 0))
	end
end

-- The world point the server measures reach from: his prompt's plate.
function MosskeeperService.PromptPoint(): Vector3?
	local model = npc
	local plate = model and model:FindFirstChild(MosskeeperModel.PromptPart)
	return if plate and plate:IsA("BasePart") then plate.Position else nil
end

function MosskeeperService.Model(): Model?
	return npc
end

function MosskeeperService.Surround(): Model?
	return surround
end

function MosskeeperService.Deck(): Model?
	return deck
end

local onTalk: (any) -> () = function() end

-- The hub's dress round him, built once and left standing: his surround, with
-- him on its pad, and the deck's carpet, mushroom ring and grove.
local function dress()
	local current = surround
	if current and current.Parent then
		return
	end
	local model = MistSurroundModel.build(HUB.NpcAnchor, nil)
	model.Archivable = false
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = Hooks.parent()
	surround = model
	local look = MistDeckModel.build(nil)
	look.Archivable = false
	look.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	look.Parent = Hooks.parent()
	deck = look
	standHim()
end

-- Builds him (once), on the anchor, with the game's own Talk prompt, and the
-- hub's dress round him.
function MosskeeperService.Show(): Model
	local current = npc
	if current and current.Parent then
		dress()
		return current
	end
	local model = MosskeeperModel.build(HUB.NpcAnchor, nil)
	model.Archivable = false
	-- His prompt, parts and joints arrive on a client together, or not at all
	-- (a client animates him: MosskeeperView).
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local plate = model:FindFirstChild(MosskeeperModel.PromptPart) :: BasePart
	local talk = Instance.new("ProximityPrompt")
	talk.Name = CFG.PromptName
	talk.Style = Enum.ProximityPromptStyle.Custom
	talk.ActionText = CFG.ActionText
	talk.ObjectText = ""
	talk.KeyboardKeyCode = Enum.KeyCode.E
	-- A TAP, unlike the berry and hatch holds.
	talk.HoldDuration = 0
	talk.MaxActivationDistance = CFG.TalkReach
	talk.RequiresLineOfSight = false
	talk.Triggered:Connect(function(player)
		onTalk(player)
	end)
	talk.Parent = plate
	npc = model
	model.Parent = Hooks.parent()
	dress()
	standHim()
	log(string.format("Mosskeeper stands at the Event Hub with its dress (%s).", tostring(model:GetPivot().Position)))
	return model
end

--==============================================================================
-- TALK
--==============================================================================
onTalk = function(player: any)
	if not Hooks.ready(player) then
		return
	end
	Hooks.send(player, { phase = "open", active = Hooks.active() })
end

-- What a Talk does, for specs (a prompt cannot be pressed in one).
function MosskeeperService._talk(player: any)
	onTalk(player)
end

--==============================================================================
-- GIVE ALL
--==============================================================================
local busy: { [any]: boolean } = {}
local lastAsk: { [any]: number } = {}

local function refuse(reason: string): { [string]: any }
	return { phase = "refused", reason = reason }
end

-- The whole check and the one profile change; the answer for the client.
function MosskeeperService.Give(player: any): { [string]: any }
	if busy[player] then
		return refuse("BUSY")
	end
	local now = Hooks.now()
	if now - (lastAsk[player] or -math.huge) < CFG.GiveGap then
		return refuse("BUSY")
	end
	lastAsk[player] = now
	busy[player] = true
	local ok, answer = pcall(function(): { [string]: any }
		local at = MosskeeperService.PromptPoint()
		if not (Hooks.shown() and at) then
			return refuse("GONE")
		end
		if not Hooks.active() then
			return refuse("INACTIVE")
		end
		local root = Hooks.root(player)
		if not root or (root - (at :: Vector3)).Magnitude > CFG.TalkReach + CFG.ReachSlack then
			return refuse("FAR")
		end
		if Hooks.carryingPod(player) then
			return refuse("CARRYING")
		end
		local profile = Hooks.ready(player) and Hooks.profile(player)
		if not profile then
			return refuse("NOT_LOADED")
		end
		local carried = math.clamp(math.floor(tonumber(profile.DewberriesCarried) or 0), 0, CAP)
		if carried <= 0 then
			return refuse("EMPTY")
		end
		local pods = EnchantedMistData.deliver(tonumber(profile.DewberryProgress) or 0, carried)
		if pods > 0 then
			-- A pod-earning delivery: all of it, or none of it.
			if Hooks.grantPod == nil or not Hooks.canGrant() then
				return refuse("POD_NOT_READY")
			end
			if not Hooks.bagReady(player) then
				return refuse("BAG_NOT_READY")
			end
			if Hooks.podRoom(player) <= 0 then
				return refuse("BAG_FULL")
			end
		end
		-- One profile change, nothing yields inside it: the carried count, the
		-- remaining progress and the pod, together.
		local gave, earned, left = 0, 0, 0
		local changed = Hooks.update(player, function(p: any): boolean
			local have = math.clamp(math.floor(tonumber(p.DewberriesCarried) or 0), 0, CAP)
			if have <= 0 then
				return false
			end
			local n, rest = EnchantedMistData.deliver(tonumber(p.DewberryProgress) or 0, have)
			if n > 0 then
				local grant = Hooks.grantPod
				if not grant or not grant(player, p) then
					return false
				end
			end
			p.DewberriesCarried = 0
			p.DewberryProgress = rest
			gave, earned, left = have, n, rest
			return true
		end)
		if not changed then
			return refuse(if pods > 0 then "BAG_FULL" else "EMPTY")
		end
		return { phase = "given", delivered = gave, pods = earned, progress = left, carried = 0 }
	end)
	busy[player] = nil
	if not ok then
		warn("[Seed/MosskeeperService] a delivery failed: " .. tostring(answer))
		return refuse("BUSY")
	end
	local result = answer :: { [string]: any }
	if result.phase == "given" and result.pods > 0 then
		Hooks.saveSoon(player)
	end
	if result.phase == "given" then
		local plural = if result.delivered == 1 then "y" else "ies"
		log(string.format("%s delivered %d Dewberr%s: %d pod(s), %d/%d saved.", tostring(player.Name),
			result.delivered, plural, result.pods, result.progress, PER_POD))
		local words = CFG.Words
		Hooks.notify(player, {
			title = if result.pods > 0 then string.format(words.GivenPod, result.delivered)
				else string.format(words.Given, result.delivered, plural, result.progress, PER_POD),
			key = CFG.NoticeKey,
			-- The delivery makes its own sound on the client (GIVE ALL, POD EARNED).
			quiet = true,
			-- The Mist's badge (2026-10-12, item 15).
			icon = "mist",
		})
	end
	return result
end

--==============================================================================
-- AN ADMIN'S LINE (2026-10-12, the owner's item 12: MOSSKEEPER SAYS)
--
-- In his bubble over his head, for everybody in this server, as long as an
-- admin announcement or its reading time if longer (MosskeeperUI,
-- MosskeeperTalk.sayTime). The words come already filtered for everyone and
-- cut to Talk.SayMaxChars (AdminService, the broadcast filter); the bubble is
-- the whole announcement. Refused while he is not shown.
--
-- It goes up on the Workspace (Mosskeeper.SaidAttribute: its count, words and
-- end in server time), not to the players here now: a late joiner, or a player
-- who walks up to him while it stands, shows the rest. A player who skips it
-- hides it on their own screen only; the line here stays.
--==============================================================================
local saidCount = 0

function MosskeeperService.Say(text: string): boolean
	if not Hooks.shown() or type(text) ~= "string" or text == "" then
		return false
	end
	saidCount += 1
	Hooks.publish(HttpService:JSONEncode(MosskeeperTalk.said(saidCount, text, Hooks.serverNow())))
	log("said an admin's line over his head: " .. text)
	return true
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local unhooks: { () -> () } = {}
local generation = 0

function MosskeeperService.Init()
	for _, unhook in ipairs(unhooks) do
		unhook()
	end
	table.clear(unhooks)
	generation += 1
	table.clear(busy)
	table.clear(lastAsk)
end

function MosskeeperService.Start()
	local mine = generation
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	if found and found:IsA("RemoteEvent") then
		local channel = found :: RemoteEvent
		Hooks.send = function(player: any, payload: { [string]: any })
			if player.Parent == Players then
				channel:FireClient(player, CFG.ServerAction, payload)
			end
		end
		Hooks.notify = function(player: any, payload: { [string]: any })
			if player.Parent == Players then
				channel:FireClient(player, Notice.ServerNotice, payload)
			end
		end
		local asked = channel.OnServerEvent:Connect(function(player: Player, action: any)
			if action ~= CFG.ClientAction or generation ~= mine then
				return
			end
			Hooks.send(player, MosskeeperService.Give(player))
		end)
		table.insert(unhooks, function()
			asked:Disconnect()
		end)
	end
	local leaving = Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
		lastAsk[player] = nil
	end)
	table.insert(unhooks, function()
		leaving:Disconnect()
	end)
	if not Hooks.shown() then
		log("off (EnchantedMistConfig.ShowMosskeeper is false).")
		return
	end
	-- Him and the hub's dress, once, Mist or not (a Mist's start and end
	-- change nothing here; only its look comes and goes).
	MosskeeperService.Show()
end

return MosskeeperService
