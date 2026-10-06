--!strict
-- Steal a Seed :: MiniEventUI
--
-- The global mini event's notices and the "+1" over a player who took a
-- ticket (2026-10-03, TICKET DISCO; reworked 2026-10-04). Reads what the
-- server tells this player, and decides nothing.
--
-- THE STATUS LINE IS GONE (2026-10-04). "Tickets: 2/3 · 0:42" and "Disco ·
-- 0:42" became BoostIconsUI's tickets and disco icons over the hotbar: the
-- same attributes, the count on the ticket icon's badge, the time and the
-- progress in its popover.
--
-- THE NOTICES (Notice.post, drawn by ActionToastUI over the icon row): the one
-- announcement per event, which the server sends about two seconds in to
-- whoever is here then, with the event's own picture; "ALL 3 TICKETS
-- COLLECTED!" ONCE per event when the last one is taken (or "TICKET LIMIT
-- REACHED" once, if this screen missed that -- a rejoin at the cap); a full
-- spin balance or a profile that is not saving, at most every few seconds;
-- and the Disco Mill with every spot taken.
--
-- "+1 [ticket]" OVER THE COLLECTOR: on this player's own screen, for a ticket
-- the server CONFIRMED -- the Collected event, which MiniEventService sends
-- only after WheelService granted and recorded it -- and for nothing else: not
-- a prediction (the client never decides a pickup), not the count attribute
-- arriving on a join or rejoin, never a refusal. Once per ticket: the event's
-- id and the count it brought this player to. Cosmetic -- it grants nothing.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local Notice = require(Shared:WaitForChild("Notice"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local M = GameConfig.MiniEvent
local EVENTS = M.Events
local WORDS = M.Notices
local POP = M.Pop
local MODES: { [string]: any } = M.Modes :: any
local TICKET_INK = Color3.fromRGB(255, 214, 92)

local function whole(value: any, fallback: number): number
	return if type(value) == "number" and value == value then math.floor(value) else fallback
end

--==============================================================================
-- "+1 [ticket]" OVER THE COLLECTOR
--==============================================================================
local popped: { [string]: boolean } = {}

local function pop(eventId: string, count: number)
	local key = eventId .. ":" .. count
	if popped[key] then
		return
	end
	popped[key] = true
	local character = player.Character
	local head = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
	if not (head and head:IsA("BasePart")) then
		return
	end
	local board = Instance.new("BillboardGui")
	board.Name = "SeedTicketPop"
	board.Adornee = head
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.ResetOnSpawn = false
	board.Size = UDim2.fromOffset(POP.Width, POP.Height)
	board.StudsOffsetWorldSpace = Vector3.new(0, POP.Above, 0)
	board.Parent = playerGui

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = board
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 4)
	list.Parent = holder

	local plus = Instance.new("TextLabel")
	plus.Name = "Plus"
	plus.BackgroundTransparency = 1
	plus.Font = Enum.Font.LuckiestGuy
	plus.Text = POP.Text
	plus.TextColor3 = TICKET_INK
	plus.TextSize = math.round(POP.Height * 0.62)
	plus.AutomaticSize = Enum.AutomaticSize.X
	plus.Size = UDim2.new(0, 0, 1, 0)
	plus.LayoutOrder = 1
	plus.Parent = holder
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(40, 26, 6)
	edge.Thickness = 2
	edge.Parent = plus

	-- The Spin Ticket's own picture (the Bag's); "+1" stands alone if it never
	-- loads.
	local picture = Instance.new("ImageLabel")
	picture.Name = "Ticket"
	picture.BackgroundTransparency = 1
	picture.ScaleType = Enum.ScaleType.Fit
	picture.Image = StatusText.sourceImage("tickets") or ""
	picture.Size = UDim2.fromOffset(POP.Height, POP.Height)
	picture.LayoutOrder = 2
	picture.Visible = picture.Image ~= ""
	picture.Parent = holder

	local still = StatusText.reducedMotion()
	local seconds = POP.Seconds
	local fade = TweenInfo.new(seconds * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false,
		seconds * 0.55)
	TweenService:Create(plus, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(edge, fade, { Transparency = 1 }):Play()
	TweenService:Create(picture, fade, { ImageTransparency = 1 }):Play()
	if not still then
		TweenService:Create(board, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ StudsOffsetWorldSpace = Vector3.new(0, POP.Above + POP.Rise, 0) }):Play()
	end
	task.delay(seconds + 0.1, function()
		board:Destroy()
	end)
end

--==============================================================================
-- THE NOTICES
--==============================================================================
-- The limit is said once per event: whichever of the two ways comes first.
local limitSaid: { [string]: boolean } = {}

local function onEvent(action: any, payload: any)
	if action == M.DiscoMill.FullAction then
		Notice.post({ kind = "warning", title = WORDS.MillFull.Title, detail = WORDS.MillFull.Detail,
			key = "mini:millfull", icon = "disco" })
		return
	end
	if type(payload) ~= "table" then
		return
	end
	local id = if type(payload.id) == "string" then payload.id else "?"
	if action == EVENTS.Opened then
		local mode = MODES[if type(payload.mode) == "string" then payload.mode else ""]
		if not mode then
			return
		end
		Notice.post({
			kind = "info",
			title = mode.Announce.Title,
			detail = mode.Announce.Detail,
			key = "mini:open:" .. id,
			icon = mode.Announce.Icon,
			seconds = 4,
		})
	elseif action == EVENTS.Collected then
		local count = whole(payload.count, 1)
		local cap = whole(payload.cap, M.Tickets.PerPlayerCap)
		pop(id, count)
		if count >= cap and not limitSaid[id] then
			limitSaid[id] = true
			Notice.post({
				kind = "success",
				title = string.format(WORDS.Capped.Title, cap),
				detail = WORDS.Capped.Detail,
				key = "mini:capped:" .. id,
				icon = "tickets",
			})
		end
	elseif action == EVENTS.Refused then
		local reason = payload.reason
		local count = whole(payload.count, 0)
		local cap = whole(payload.cap, M.Tickets.PerPlayerCap)
		if reason == "CAP" then
			if not limitSaid[id] then
				limitSaid[id] = true
				Notice.post({
					kind = "info",
					title = WORDS.AtCap.Title,
					detail = string.format(WORDS.AtCap.Detail, count, cap),
					key = "mini:atcap:" .. id,
					icon = "tickets",
					quiet = true,
				})
			end
		elseif reason == "FULL" then
			Notice.post({ kind = "warning", title = WORDS.Full.Title, detail = WORDS.Full.Detail,
				key = "mini:full:" .. id, icon = "tickets" })
		else
			Notice.post({ kind = "warning", title = WORDS.Unavailable.Title, detail = WORDS.Unavailable.Detail,
				key = "mini:unavailable:" .. id })
		end
	end
end

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if not (found and found:IsA("RemoteEvent")) then
		warn("[Seed/MiniEventUI] No GameEvent remote; mini-event notices will not be shown.")
		return
	end
	found.OnClientEvent:Connect(onEvent)
end)
