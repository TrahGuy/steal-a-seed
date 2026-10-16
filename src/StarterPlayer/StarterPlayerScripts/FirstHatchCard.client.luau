--!strict
--==============================================================================
-- Steal a Seed :: FirstHatchCard (2026-10-16, the owner's fix for the onboarding
-- funnel's step 4; GameConfig.FirstHatch says what and why)
--
-- From the first pod this player ever banked until their first hatch: a card in
-- the lower middle, over the hotbar, clear of the whole HUD (Shared/
-- FirstHatchCard.rect over HudLayout.occupied). The pod's own picture, its size
-- and name, "YOUR POD IS GROWING…" over "Ready in 0:07" with a grey HATCH, then
-- "YOUR POD IS READY!" with a green HATCH and the Mist's pod-ready ping. No
-- dimmer and no close: the game goes on round it, and it stays until the pod
-- hatches -- by its HATCH or the Bag's -- standing down while a menu or a reward
-- moment is up (RewardMoments.busy).
--
-- WHAT IT ASKS, AND WHAT IT DOES NOT DECIDE. The server says a first hatch is
-- pending (FirstHatch.PendingAttribute) and stamps every pod's HatchAt; this
-- reads the Bag's own Tools. HATCH sends HatchInBag.FirstHatch with the pod's
-- item id, and the server checks all of it again (PlantService.FirstHatch): home
-- first -- onto the plot's spawn facing the bed its plant will come up in --
-- then the hatch in front of them. The server's answer names that landing, and
-- this writes it on the local player (FirstHatch.AskedAttribute, never
-- replicated), so ObbyCamera turns the camera once when the body is put there.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local RewardMoments = require(Shared:WaitForChild("RewardMoments"))
local FirstHatchCard = require(Shared:WaitForChild("FirstHatchCard"))

local FIRST = GameConfig.FirstHatch
local BAG = GameConfig.HatchInBag
local ATTR = GameConfig.Attributes
local B = FirstHatchCard.Blocks
local SIZES = FirstHatchCard.TextSizes
local WHITE = Color3.fromRGB(255, 255, 255)
local CREAM = Color3.fromRGB(242, 238, 206)
local Z = 2

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedFirstHatch")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedFirstHatch"
gui.ResetOnSpawn = false
-- The invite reward card's layer: over the belt and the menus' layers, under
-- the rail's 40; it only ever stands where the HUD does not.
gui.DisplayOrder = 35
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
-- The HUD's own units on a TV, so HudLayout's rects mean the same here.
UIKit.tenFoot(gui)

--==============================================================================
-- THE CARD (built once)
--==============================================================================
local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Size = UDim2.fromOffset(FirstHatchCard.Base.X, FirstHatchCard.Base.Y)
card.BackgroundTransparency = 1
card.Visible = false
card.ZIndex = Z
card.Parent = gui
local fit = Instance.new("UIScale")
fit.Parent = card

local function place(object: GuiObject, r: FirstHatchCard.Rect)
	object.Position = UDim2.fromOffset(r.x, r.y)
	object.Size = UDim2.fromOffset(r.w, r.h)
end

local function fitText(label: TextLabel, max: number, min: number)
	label.TextScaled = true
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = max
	c.MinTextSize = min
	c.Parent = label
end

local plate = MenuKit.baseplate(card, Z)
plate.Size = UDim2.fromScale(1, 1)
local rim = Instance.new("UIStroke")
rim.Name = "Rim"
rim.Thickness = 4
rim.Color = WHITE
rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rim.LineJoinMode = Enum.LineJoinMode.Round
rim.Parent = plate

-- COMIC TYPE, like the reward cards: white words over a thick ink line by size.
local title = UIKit.outlined(card, "Title", SIZES.title, WHITE, 2.5)
place(title, B.title)
title.ZIndex = Z + 3
fitText(title, SIZES.title, 12)
UIKit.comic(title, SIZES.title)

local preview = UIKit.itemPreview(card, { name = "Pod", position = UDim2.fromOffset(B.view.x, B.view.y),
	size = UDim2.fromOffset(B.view.w, B.view.h) })
preview.holder.ZIndex = Z + 3

local podName = MenuKit.text(card, "PodName", SIZES.pod, WHITE, Z + 3)
place(podName, B.pod)
podName.TextXAlignment = Enum.TextXAlignment.Left
MenuKit.keepInk(podName)
fitText(podName, SIZES.pod, 10)
UIKit.comic(podName, SIZES.pod)

local line = MenuKit.text(card, "Line", SIZES.line, CREAM, Z + 3)
place(line, B.line)
line.TextXAlignment = Enum.TextXAlignment.Left
MenuKit.keepInk(line)
fitText(line, SIZES.line, 9)
UIKit.comic(line, SIZES.line)

-- The guide's hand finds it by this name (TutorialUI).
local hatch = MenuKit.button(card, "FirstHatchButton", Z + 3, FIRST.Words.Hatch, SIZES.button, { studs = true })
place(hatch.hit, B.button)
UIKit.comic(hatch.label, SIZES.button)

--==============================================================================
-- WHAT IT IS FOR: the Bag's pods, from their Tools
--==============================================================================
local function bagPods(): { FirstHatchCard.Pod }
	local out: { FirstHatchCard.Pod } = {}
	for _, container in { player.Character, player:FindFirstChildOfClass("Backpack") } do
		if container then
			for _, tool in container:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("Hatched") ~= true then
					local due = tonumber(tool:GetAttribute(BAG.Attribute))
					local item = tool:GetAttribute(ATTR.ItemId)
					local species = tool:GetAttribute("SpeciesId")
					if due and type(item) == "string" and type(species) == "string" then
						table.insert(out, { item = item, speciesId = species,
							tier = tonumber(tool:GetAttribute(ATTR.CarryingKg)) or 1, hatchAt = due })
					end
				end
			end
		end
	end
	return out
end

--==============================================================================
-- THE WIRE
--==============================================================================
local remote: RemoteEvent? = nil
task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local ev = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if ev and ev:IsA("RemoteEvent") then
		remote = ev
	end
end)

-- The item asked for, from the press until the server's last word on it.
local askedItem: string? = nil
local askedAt = 0
local ASK_PATIENCE = 8

local function forgetAsk()
	askedItem = nil
	player:SetAttribute(FIRST.AskedAttribute, nil)
end

--==============================================================================
-- PAINTED
--==============================================================================
local shownItem: string? = nil
local styledReady: boolean? = nil
-- Said to the server once a session, the first time the card stands
-- (FirstHatch.ShownVerb; Metrics.firstHatchCardShown).
local toldShown = false
local readyRung: { [string]: boolean } = {}
local lastPlaced = -math.huge
-- When a screen last had no place at all (FirstHatchCard.rect): asked again once
-- a second, not every paint -- the search off the middle walks the whole width.
local lastFailed = -math.huge

local function placeCard(): boolean
	if gui.AbsoluteSize.X <= 0 then
		return false
	end
	local L = HudLayout.solve(HudLayout.measure(gui))
	-- The whole HUD, and the guide's words while they show (on a phone, its block
	-- in the left column reaches toward the middle).
	local avoid = HudLayout.occupied(L)
	for _, g in ipairs(UIKit.guideRects(playerGui, gui.AbsolutePosition)) do
		table.insert(avoid, g)
	end
	local r, scale = FirstHatchCard.rect(L.safe, avoid)
	if r.w <= 0 or scale <= 0 then
		return false
	end
	card.Position = UDim2.fromOffset(r.x + r.w / 2, r.y + r.h / 2)
	fit.Scale = scale
	return true
end

local function paint()
	if askedItem and os.clock() - askedAt > ASK_PATIENCE then
		forgetAsk()
	end
	local pod = FirstHatchCard.pick(bagPods())
	local pending = player:GetAttribute(FIRST.PendingAttribute) == true
	local busy = RewardMoments.busy(player, ATTR.OpenPanel)
	if not FirstHatchCard.shown(pending, pod, busy, askedItem ~= nil) or pod == nil then
		card.Visible = false
		shownItem = nil
		return
	end
	local species = SeedData.Get(pod.speciesId)
	local view = FirstHatchCard.view(pod, Workspace:GetServerTimeNow(), SeedData.TierName(pod.tier),
		if species then species.Name else "Pod")
	if shownItem ~= pod.item then
		shownItem = pod.item
		local key = "firsthatch:" .. pod.speciesId .. ":" .. tostring(pod.tier)
		local builder, category = ItemArt.builder(key, { kind = "pod", speciesId = pod.speciesId, tier = pod.tier })
		preview.setModel(key, builder, category)
		lastPlaced = -math.huge
		lastFailed = -math.huge
	end
	local now = os.clock()
	if not card.Visible or now - lastPlaced > 1 then
		if now - lastFailed < 1 then
			card.Visible = false
			return
		end
		lastPlaced = now
		if not placeCard() then
			lastFailed = now
			card.Visible = false
			return
		end
	end
	if title.Text ~= view.title then
		title.Text = view.title
	end
	if podName.Text ~= view.pod then
		podName.Text = view.pod
	end
	line.Visible = view.line ~= nil
	if view.line and line.Text ~= view.line then
		line.Text = view.line
	end
	if styledReady ~= view.ready then
		styledReady = view.ready
		hatch.style(if view.ready then "go" else "off")
	end
	if view.ready and not readyRung[pod.item] then
		readyRung[pod.item] = true
		-- Only when it turns ready in front of them, not for a pod that was
		-- ready before they came back.
		if card.Visible then
			SoundKit.play(FIRST.Sound)
		end
	end
	card.Visible = true
	local ev = remote
	if not toldShown and ev then
		toldShown = true
		ev:FireServer(FIRST.ShownVerb)
	end
end

hatch.hit.Activated:Connect(function()
	local pod = FirstHatchCard.pick(bagPods())
	local ev = remote
	if not (pod and ev and askedItem == nil) then
		return
	end
	if pod.hatchAt > Workspace:GetServerTimeNow() then
		return
	end
	askedItem = pod.item
	askedAt = os.clock()
	ev:FireServer(BAG.FirstHatch, pod.item)
	card.Visible = false
end)

-- The server's word: a refusal gives the card back; the last word on a hatch
-- that ran (done) ends the ask either way.
task.spawn(function()
	while remote == nil and gui.Parent do
		task.wait(0.5)
	end
	local ev = remote
	if not ev then
		return
	end
	ev.OnClientEvent:Connect(function(action: any, reply: any)
		if action ~= BAG.Reply or type(reply) ~= "table" or reply.op ~= BAG.FirstHatch then
			return
		end
		if reply.item ~= askedItem then
			return
		end
		-- Going home: the server's own landing, for the camera's one turn.
		if reply.ok == true and typeof(reply.landing) == "CFrame" then
			player:SetAttribute(FIRST.AskedAttribute, reply.landing)
		end
		if reply.ok ~= true or reply.done == true then
			forgetAsk()
		end
		paint()
	end)
end)

--==============================================================================
-- WHEN IT IS LOOKED AT AGAIN: the attributes and the Bag, and a few times a
-- second for the countdown
--==============================================================================
player:GetAttributeChangedSignal(FIRST.PendingAttribute):Connect(paint)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(paint)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	lastPlaced = -math.huge
	lastFailed = -math.huge
	paint()
end)
task.spawn(function()
	while gui.Parent do
		paint()
		task.wait(0.2)
	end
end)
