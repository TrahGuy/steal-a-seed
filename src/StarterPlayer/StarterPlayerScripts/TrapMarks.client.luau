--!strict
-- Steal a Seed :: TrapMarks
--
-- THIS PLAYER'S OWN PLACED TRAPS, DRAWN ON THIS CLIENT ALONE (2026-10-04)
--
-- A placed trap is hidden from everybody but its owner (the owner's brief).
-- CombatService builds no trap in the world: it keeps each one as server state
-- and hands its OWNER a record -- a Configuration per trap inside the disabled
-- ScreenGui WeaponData.Trap.MarksGuiName in this player's PlayerGui, which
-- replicates to this player and nobody else. This file draws each record with
-- the same WeaponModel geometry the server used to build, in a folder this
-- client makes and only this client has.
--
-- PRESENTATION ONLY. Nothing here decides whether a trap is armed, who it
-- catches or when it goes: the server tests bodies against its own copy, and
-- removes the record when the trap is taken away -- its owner's REMOVE, the
-- owner leaving, a progress reset, its floor going -- which is the only thing
-- that erases a drawing here. The record's times are SERVER times, so the
-- arming is drawn on the same clock the server arms it on.
--
-- ONE CATCH (2026-10-05, the owner's brief; it replaces 2026-10-04's re-arm in
-- place): a catch consumes the trap, so the server removes its record at that
-- moment and this drawing goes with it -- the server's own public snap stands
-- where it was for everybody, the owner included, so the owner never sees two,
-- and nothing here ever draws a re-arming. One drawing per record, always.
--
-- THROUGH A DEATH: the records' gui survives a respawn (ResetOnSpawn off) and
-- this script lives in PlayerScripts, so nothing is lost or redrawn twice. If
-- the script itself starts again, it clears its own old folder first and draws
-- every record afresh from the server's copy.
--
-- THE TWO SOUNDS THAT USED TO GIVE A TRAP AWAY are played here, on the drawn
-- trap, for the owner: the set-down and the arming.
-- The SPRING is public -- the server shows the sprung trap and plays its cue
-- for everyone.
--
-- Cheap by shape: one Heartbeat connection that exists only while a drawn
-- trap is hidden or still arming (at most three per player), released when the
-- last one is armed. Nothing is built per frame.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local player = Players.LocalPlayer
local MARKS = WeaponData.Trap.MarksGuiName
local FOLDER = "SeedOwnTraps"
-- A record that arrives this soon after its placement gets the set-down cue; an
-- older one (a redraw after a reconnect of the gui) is drawn silently.
local FRESH_SECONDS = 1.5
type Drawn = {
	model: Model,
	placedAt: number,
	-- The arming: from the placement to armsAt, off the record.
	armFrom: number,
	armsAt: number,
	-- When the drawing may show: ArmFrom.
	showAt: number,
	armed: boolean,
	hidden: boolean,
	conn: RBXScriptConnection?,
}

local drawn: { [Instance]: Drawn } = {}
local folder: Folder? = nil
local loop: RBXScriptConnection? = nil

-- A previous run of this script (a restart, a hot reload) left its drawings
-- here; they belong to nobody now. The records are redrawn below.
do
	local stale = Workspace:FindFirstChild(FOLDER)
	if stale then
		stale:Destroy()
	end
end

-- A folder this client makes: it exists on this machine and nowhere else.
local function holder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local made = Instance.new("Folder")
	made.Name = FOLDER
	made.Parent = Workspace
	folder = made
	return made
end

local function fractionArmed(d: Drawn, nowServer: number): number
	return math.clamp((nowServer - d.armFrom) / math.max(0.05, d.armsAt - d.armFrom), 0, 1)
end

-- The drawing's place in the world: in the folder, or out of it until its
-- record's ArmFrom.
local function setHidden(d: Drawn, hide: boolean)
	if d.hidden == hide then
		return
	end
	d.hidden = hide
	d.model.Parent = if hide then nil else holder()
end

local function step()
	local nowServer = Workspace:GetServerTimeNow()
	local busy = false
	for _, d in pairs(drawn) do
		if not d.armed then
			if nowServer < d.showAt then
				setHidden(d, true)
				busy = true
			else
				setHidden(d, false)
				local f = fractionArmed(d, nowServer)
				WeaponModel.SetTrapArming(d.model, f)
				if f >= 1 then
					d.armed = true
					local base = d.model.PrimaryPart
					if base then
						-- Live, said once, to the one player who can see it.
						SoundKit.emit("TrapArmed", base)
					end
				else
					busy = true
				end
			end
		end
	end
	if not busy and loop then
		loop:Disconnect()
		loop = nil
	end
end

local function wake()
	if not loop then
		loop = RunService.Heartbeat:Connect(step)
	end
end

local function erase(mark: Instance)
	local d = drawn[mark]
	if not d then
		return
	end
	drawn[mark] = nil
	local conn = d.conn
	if conn then
		conn:Disconnect()
	end
	d.model:Destroy()
end

-- The record's arming, read on the first draw (and again should the server ever
-- re-stamp it): the drawing takes its unarmed look and the loop takes it from
-- there -- arming from ArmFrom to ArmsAt.
local function readArming(mark: Instance, d: Drawn)
	local placedAt = tonumber(mark:GetAttribute("PlacedAt")) or d.placedAt
	local armFrom = tonumber(mark:GetAttribute("ArmFrom")) or placedAt
	local armsAt = tonumber(mark:GetAttribute("ArmsAt")) or armFrom
	if armFrom == d.armFrom and armsAt == d.armsAt and d.armed then
		return
	end
	d.armFrom = armFrom
	d.armsAt = armsAt
	d.showAt = armFrom
	local nowServer = Workspace:GetServerTimeNow()
	local hide = nowServer < d.showAt
	local f = if hide then 0 else fractionArmed(d, nowServer)
	-- Already armed (a redraw) takes its armed look at once, silently.
	WeaponModel.SetTrapArming(d.model, f)
	d.armed = not hide and f >= 1
	setHidden(d, hide)
	if not d.armed then
		wake()
	end
end

local function draw(mark: Instance)
	if drawn[mark] or not mark:IsA("Configuration") then
		return
	end
	local item = WeaponData.Get(mark:GetAttribute("ItemId"))
	local at = mark:GetAttribute("At")
	local placedAt = tonumber(mark:GetAttribute("PlacedAt"))
	if not (item and typeof(at) == "Vector3" and placedAt) then
		return
	end
	local ok, built = pcall(WeaponModel.BuildTrapWorld, item :: WeaponData.Item,
		CFrame.new((at :: Vector3) + Vector3.new(0, 0.06, 0)), holder())
	if not ok or typeof(built) ~= "Instance" then
		warn("[Seed/TrapMarks] could not draw a trap: " .. tostring(built))
		return
	end
	local model = built :: Model
	-- A picture of a trap: nothing about it is solid, queryable or touchable.
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	local entry: Drawn = {
		model = model,
		placedAt = placedAt :: number,
		armFrom = -math.huge,
		armsAt = -math.huge,
		showAt = -math.huge,
		armed = false,
		hidden = false,
		conn = nil,
	}
	drawn[mark] = entry
	readArming(mark, entry)
	entry.conn = mark.AttributeChanged:Connect(function(name: string)
		if name == "ArmFrom" or name == "ArmsAt" then
			if drawn[mark] == entry then
				readArming(mark, entry)
			end
		end
	end)
	local base = model.PrimaryPart
	if base and Workspace:GetServerTimeNow() - (placedAt :: number) < FRESH_SECONDS then
		SoundKit.emit("TrapPlace", base)
	end
end

local function watchMarks(marks: Instance)
	for _, child in ipairs(marks:GetChildren()) do
		draw(child)
	end
	marks.ChildAdded:Connect(draw)
	marks.ChildRemoved:Connect(erase)
	marks.AncestryChanged:Connect(function()
		if not marks:IsDescendantOf(game) then
			for mark in pairs(drawn) do
				erase(mark)
			end
		end
	end)
end

local gui = player:WaitForChild("PlayerGui")
local existing = gui:FindFirstChild(MARKS)
if existing then
	watchMarks(existing)
end
gui.ChildAdded:Connect(function(child)
	if child.Name == MARKS then
		watchMarks(child)
	end
end)
