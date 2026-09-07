--!strict
-- Steal a Seed :: TrapUI
--
-- The red countdown over somebody a Bramblejaw is holding.
--
--==============================================================================
-- TWO ATTRIBUTE WRITES, NOT SIXTY UPDATES A SECOND
--
-- CombatService writes `TrappedUntil` once when the jaws close and clears it
-- once when they open, in SERVER time. Every client subtracts that from
-- `Workspace:GetServerTimeNow()` -- the same clock on both ends -- and draws its
-- own number. So a two-second restraint costs two replications per victim
-- rather than a stream of them, and every watcher sees the same figure without
-- anybody being sent it.
--
-- It also means the label cannot outlive the restraint. The countdown is not a
-- timer this file started; it is a rendering of a value that either exists or
-- does not, so a bat or a guardian ending the hold early removes it on the next
-- attribute change rather than on a timeout nobody is honouring.
--
--==============================================================================
-- NO PLATE, NO CARD, NO BOX
--
-- A BillboardGui whose only child is text. The brief asks for a transparent
-- background and the reason is the same one the inventory previews are drawn
-- for: anything with a fill behind it reads as a UI element parked in the
-- world, and this has to read as something happening TO a player.
--
-- Readability without a plate is bought with a stroke, which is the recipe the
-- whole HUD already uses -- CashUI's outlined LuckiestGuy, the prompt labels,
-- the pod clocks. Slightly translucent so it sits in the scene rather than on
-- top of it.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local ATTR = GameConfig.Attributes

-- Red, and one of the few things allowed outside ink / paper / accent, for the
-- same reason the badge is: the job of it is to be found before you have
-- decided to look.
local RED = Color3.fromRGB(255, 64, 58)
local OUTLINE = Color3.fromRGB(48, 6, 6)

local LABEL_NAME = "SeedTrapCountdown"
-- Above the head and above whatever name label the platform is drawing there:
-- Roblox's own sits at roughly two studs, so this clears it.
local RISE = 3.4
local SIZE = Vector2.new(200, 44)
-- Far enough to read across a fight, near enough that a corridor of traps is
-- not a wall of numbers. The guardian alarm is audible further than this.
local VIEW_DISTANCE = 90

type Entry = {
	billboard: BillboardGui,
	text: TextLabel,
	adorn: BasePart,
}

local shown: { [Player]: Entry } = {}
local watched: { [Player]: { RBXScriptConnection } } = {}
local ticking: RBXScriptConnection? = nil

--==============================================================================
-- THE LABEL
--==============================================================================
local function build(head: BasePart): Entry
	local billboard = Instance.new("BillboardGui")
	billboard.Name = LABEL_NAME
	billboard.Size = UDim2.fromOffset(SIZE.X, SIZE.Y)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, RISE, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = VIEW_DISTANCE
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Adornee = head
	-- Parented to the head rather than to PlayerGui so it dies with the body:
	-- a respawn destroys the character and takes the label with it, which is one
	-- cleanup path this file then does not have to be trusted to run.
	billboard.Parent = head

	local text = Instance.new("TextLabel")
	text.Name = "Count"
	text.Size = UDim2.fromScale(1, 1)
	-- THE WHOLE POINT: nothing behind the letters.
	text.BackgroundTransparency = 1
	text.BorderSizePixel = 0
	text.Font = Enum.Font.LuckiestGuy
	text.TextScaled = true
	text.TextColor3 = RED
	-- Slightly translucent, so it belongs to the scene rather than sitting on
	-- the glass in front of it.
	text.TextTransparency = 0.12
	text.Text = ""
	text.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 2.5
	stroke.Transparency = 0.15
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = text

	return { billboard = billboard, text = text, adorn = head }
end

local function clear(player: Player)
	local entry = shown[player]
	if not entry then
		return
	end
	shown[player] = nil
	if entry.billboard.Parent then
		entry.billboard:Destroy()
	end
end

--==============================================================================
-- ONE TICK FOR EVERY COUNTDOWN ON SCREEN
--
-- Connected only while something is counting and disconnected the moment the
-- last one ends, so a server where nobody is trapped pays nothing -- the same
-- shape the swing loop and UIKit's card pump use, and for the same reason.
--==============================================================================
local function step()
	local now = Workspace:GetServerTimeNow()
	local any = false
	for player, entry in pairs(shown) do
		local endsAt = tonumber(player:GetAttribute(ATTR.TrappedUntil))
		local held = player:GetAttribute(ATTR.Trapped) == true
		if not held or not endsAt or not entry.billboard.Parent
			or not entry.adorn.Parent then
			clear(player)
		else
			local left = endsAt - now
			if left <= 0 then
				--==============================================================
				-- THE CLOCK RAN OUT BUT THE SERVER HAS NOT SAID SO YET
				--
				-- Held at zero rather than going negative or vanishing. The
				-- attribute clearing is what removes this label, and that is one
				-- round trip away; counting into negatives in the gap would be
				-- the client inventing state the server has not confirmed.
				--==============================================================
				entry.text.Text = "TRAPPED 0.0s"
			else
				entry.text.Text = string.format("TRAPPED %.1fs", left)
			end
			any = true
		end
	end
	if not any and ticking then
		ticking:Disconnect()
		ticking = nil
	end
end

local function refresh(player: Player)
	local held = player:GetAttribute(ATTR.Trapped) == true
	local endsAt = tonumber(player:GetAttribute(ATTR.TrappedUntil))
	if not held or not endsAt then
		clear(player)
		return
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		-- Streamed out, mid-respawn, or a body that has lost its head to a
		-- throw. Nothing to hang a label on; the next attribute change or the
		-- character arriving will try again.
		clear(player)
		return
	end

	local entry = shown[player]
	if entry and entry.adorn ~= head then
		-- A new body since this label was made. Never re-point an old label at
		-- a new head: rebuild, so there is no path where a stale billboard
		-- survives a respawn.
		clear(player)
		entry = nil
	end
	if not entry then
		entry = build(head)
		shown[player] = entry
	end

	if not ticking then
		ticking = RunService.Heartbeat:Connect(step)
	end
end

--==============================================================================
-- WATCHING EVERY PLAYER, INCLUDING THIS ONE
--
-- The victim has to see their own countdown and so does everybody near them, so
-- there is nothing special about the local player here.
--==============================================================================
local function unwatch(player: Player)
	local conns = watched[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		watched[player] = nil
	end
	clear(player)
end

local function watch(player: Player)
	unwatch(player)
	local conns: { RBXScriptConnection } = {}
	table.insert(conns, player:GetAttributeChangedSignal(ATTR.Trapped):Connect(function()
		refresh(player)
	end))
	table.insert(conns, player:GetAttributeChangedSignal(ATTR.TrappedUntil):Connect(function()
		refresh(player)
	end))
	--==========================================================================
	-- A CHARACTER ARRIVING IS A REASON TO LOOK AGAIN
	--
	-- Both for a respawn -- where the old label died with the old head -- and
	-- for STREAMING, where a distant player's character appears long after the
	-- attribute that says they are trapped.
	--==========================================================================
	table.insert(conns, player.CharacterAdded:Connect(function()
		task.defer(refresh, player)
	end))
	table.insert(conns, player.CharacterRemoving:Connect(function()
		clear(player)
	end))
	watched[player] = conns
	refresh(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	watch(player)
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(unwatch)
