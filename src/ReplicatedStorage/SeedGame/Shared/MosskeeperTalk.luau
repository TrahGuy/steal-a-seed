--!strict
--==============================================================================
-- Steal a Seed :: MosskeeperTalk (2026-10-11)
--
-- THE MOSSKEEPER'S TALK, AS WORDS AND ARITHMETIC (the owner's clip of a
-- Grow-a-Garden-style shop NPC; EnchantedMistConfig.Mosskeeper.Talk). Nothing
-- here touches an instance: MosskeeperUI draws what this decides, and
-- MosskeeperTalkSpec drives it on every screen.
--
--   his lines    the greeting (the Mist running or not), his answer to a Give
--                all from the server's own payload, How to play's short run
--   the replies  #1 Give all Dewberries, #2 Odds, #3 How to play, #4 Nevermind
--   the typing   how much of a line shows t seconds in; Reduced Motion shows
--                it whole at once
--   the place    the replies' rows beside the player on screen, inside the
--                HUD's free middle, a touch screen's tall enough to tap
--   the camera   behind the player's right shoulder, facing him
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local SpeedMilestones = require(Shared:WaitForChild("SpeedMilestones"))

local CFG = EnchantedMistConfig.Mosskeeper
local TALK = CFG.Talk
local CAP = EnchantedMistData.CarryCap
local PER_POD = EnchantedMistData.BerriesPerPod

local MosskeeperTalk = {}

export type Rect = { x: number, y: number, w: number, h: number }
export type Option = { id: string, key: number, text: string }
export type Look = { Type: number, Row: number, Gap: number, Bubble: number, BubbleWidth: number, Counts: number }
export type Block = { rows: { Rect }, counts: Rect, look: Look, clear: boolean, keepsHis: boolean, keepsSoft: boolean }

local function rect(x: number, y: number, w: number, h: number): Rect
	return { x = x, y = y, w = w, h = h }
end

local function length(text: string): number
	return utf8.len(text) or #text
end

local function hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end

--==============================================================================
-- THE REPLIES
--==============================================================================
function MosskeeperTalk.options(): { Option }
	local out: { Option } = {}
	for i, o in ipairs(TALK.Options) do
		table.insert(out, { id = o.id, key = i, text = o.text })
	end
	return out
end

-- What a reply reads, as the clip writes them: #1 ["Give all Dewberries"].
function MosskeeperTalk.plain(option: Option): string
	return string.format("#%d [\"%s\"]", option.key, option.text)
end

-- The same in RichText: the number gold, the words in `colour` (white, or the
-- picked colour while a controller is on it).
function MosskeeperTalk.label(option: Option, colour: Color3?): string
	return string.format("<font color=\"%s\">#%d</font> <font color=\"%s\">[\"%s\"]</font>", hex(TALK.Look.Number),
		option.key, hex(colour or TALK.Look.Text), option.text)
end

--==============================================================================
-- HIS LINES
--==============================================================================
function MosskeeperTalk.greeting(active: boolean): string
	return if active then CFG.Lines.Active else CFG.Lines.Inactive
end

-- A number under ten as a word ("five"); anything else as digits.
function MosskeeperTalk.word(n: number): string
	return TALK.Numbers[n] or tostring(n)
end

-- His answer to a Give all, from the server's own payload, and whether it was
-- taken (GIVE ALL's sound) or refused (Action Blocked).
function MosskeeperTalk.answer(payload: { [string]: any }): (string, boolean)
	if payload.phase == "given" then
		if (tonumber(payload.pods) or 0) > 0 then
			return TALK.GivenPod, true
		end
		local left = math.clamp(math.floor(tonumber(payload.progress) or 0), 0, PER_POD - 1)
		return string.format(TALK.Given, left, PER_POD, MosskeeperTalk.word(PER_POD - left)), true
	end
	return TALK.Refused[tostring(payload.reason)] or TALK.Refused.BUSY, false
end

-- How to play: his short run, the carry cap and the berries a pod filled in.
function MosskeeperTalk.howTo(): { string }
	local out: { string } = {}
	for _, line in ipairs(TALK.HowTo) do
		local text = string.gsub(line, "{cap}", tostring(CAP))
		text = string.gsub(text, "{pod}", tostring(PER_POD))
		table.insert(out, text)
	end
	return out
end

-- Under the replies: what the player carries and their saved progress.
function MosskeeperTalk.counts(carried: number, progress: number): string
	return string.format(TALK.Counts, math.clamp(math.floor(carried), 0, CAP), CAP,
		math.clamp(math.floor(progress), 0, PER_POD - 1), PER_POD)
end

--==============================================================================
-- THE TYPING
--
-- How many of a line's characters show `elapsed` seconds into its typing, and
-- whether all of it does. Reduced Motion: all of it at once. A line in a run
-- stays its reading time once typed.
--==============================================================================
function MosskeeperTalk.typed(text: string, elapsed: number, reduced: boolean): (number, boolean)
	local total = length(text)
	if reduced or total == 0 then
		return total, true
	end
	local n = math.clamp(math.floor(math.max(0, elapsed) * TALK.CharsPerSecond), 0, total)
	return n, n >= total
end

function MosskeeperTalk.typeTime(text: string, reduced: boolean): number
	return if reduced then 0 else length(text) / TALK.CharsPerSecond
end

function MosskeeperTalk.readTime(text: string): number
	return TALK.ReadHold + length(text) * TALK.ReadPerChar
end

--==============================================================================
-- AN ADMIN'S LINE (MOSSKEEPER SAYS, 2026-10-12)
--
-- The server puts it on the Workspace for everybody (Mosskeeper.SaidAttribute)
-- as { n = its count, t = its words, e = the server time it ends }, so a late
-- joiner -- or a player who walks up to him while it stands -- shows the rest.
-- It stands SaySeconds, or its reading time if longer. A player may skip it on
-- their own screen (skipsSaid); nobody else's changes.
--==============================================================================
export type Said = { n: number, t: string, e: number }
-- One press as UserInputService.InputBegan saw it; onButton: a touch that
-- landed on one of the game's own buttons.
export type Press = { kind: Enum.UserInputType, key: Enum.KeyCode, x: number, y: number, onButton: boolean }

function MosskeeperTalk.sayTime(text: string): number
	return math.max(TALK.SaySeconds, MosskeeperTalk.readTime(text))
end

function MosskeeperTalk.said(n: number, text: string, serverNow: number): Said
	return { n = n, t = text, e = serverNow + MosskeeperTalk.sayTime(text) }
end

-- A line read back at serverNow: its count, its words and the seconds it has
-- left (never more than its own time); nil while it is not one or its time is up.
function MosskeeperTalk.saidLeft(line: any, serverNow: number): (number?, string?, number?)
	if type(line) ~= "table" or type(line.n) ~= "number" or type(line.t) ~= "string" or line.t == ""
		or type(line.e) ~= "number" then
		return nil, nil, nil
	end
	local left = line.e - serverNow
	if left <= 0 then
		return nil, nil, nil
	end
	return line.n, line.t, math.min(left, MosskeeperTalk.sayTime(line.t))
end

-- THE SKIP (the owner, 2026-10-12): a mouse button, a touch, or a gamepad's A
-- or R2, once the line has stood SaySkipAfter seconds -- so a press already on
-- its way never skips it at once. Never a touch that starts on the move stick
-- (sticks: the stick areas showing, in the press's pixels), so walking never
-- skips it -- unless that touch landed on one of the game's buttons over the
-- stick's area, which is a tap on the button.
function MosskeeperTalk.skipsSaid(press: Press, shownFor: number, sticks: { Rect }): boolean
	if shownFor < TALK.SaySkipAfter then
		return false
	end
	if press.kind == Enum.UserInputType.Touch then
		if press.onButton then
			return true
		end
		for _, r in ipairs(sticks) do
			if press.x >= r.x and press.x < r.x + r.w and press.y >= r.y and press.y < r.y + r.h then
				return false
			end
		end
		return true
	end
	return press.kind == Enum.UserInputType.MouseButton1 or press.kind == Enum.UserInputType.MouseButton2
		or press.kind == Enum.UserInputType.MouseButton3 or press.key == Enum.KeyCode.ButtonA
		or press.key == Enum.KeyCode.ButtonR2
end

--==============================================================================
-- THE CAMERA
--
-- Behind the player's right shoulder, on the line from the player to him: Back
-- studs behind, Up over and Side to the right of the player's root, looking at
-- his pivot plus LookUp -- the player bottom left, him and his bar ahead. Eased
-- in and out on a smoothstep; Reduced Motion cuts.
--==============================================================================
function MosskeeperTalk.shoulder(root: Vector3, target: Vector3): CFrame
	local C = TALK.Camera
	local flat = Vector3.new(target.X - root.X, 0, target.Z - root.Z)
	local forward = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
	local right = forward:Cross(Vector3.yAxis)
	local eye = root - forward * C.Back + Vector3.yAxis * C.Up + right * C.Side
	return CFrame.lookAt(eye, target + Vector3.yAxis * C.LookUp)
end

-- Where the replies start in the world: Beside studs right of him (the
-- camera's side) and BesideUp over his pivot -- beside the player and him on
-- screen, over neither.
function MosskeeperTalk.besidePoint(root: Vector3, target: Vector3): Vector3
	local flat = Vector3.new(target.X - root.X, 0, target.Z - root.Z)
	local forward = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
	return target + forward:Cross(Vector3.yAxis) * TALK.Beside + Vector3.yAxis * TALK.BesideUp
end

function MosskeeperTalk.ease(u: number): number
	local t = math.clamp(u, 0, 1)
	return t * t * (3 - 2 * t)
end

--==============================================================================
-- THE REPLIES' PLACE
--
-- `anchor` is where they start on screen -- the player's right side -- and
-- `bounds` the screen, in the caller's own pixels; `blocked` is the HUD's
-- buttons, bands and touch controls there, `soft` what comes and goes (the
-- notices' line, the biome name, the chase warning, the running boosts) and
-- `his` his line's rect (nil while he says nothing). The rows stand one under another, each as wide as the widest reply
-- and the look's Row tall (a touch screen's 44 px), the counts line under
-- them; the block goes to the nearest place Margin clear of the screen's edge
-- and of what it must clear (SpeedMilestones.clearOf: up costs double) -- all
-- of it, then the HUD and his line, then everything with his line put away
-- while the replies show (`keepsHis` false), then the HUD alone (`keepsSoft`
-- false too) -- each in the first look, else the tight one. Nowhere clear at
-- all: the tight look inside the screen (`clear` false). `widths(look)`
-- measures the widest reply and the counts line at that look's type.
--==============================================================================
function MosskeeperTalk.look(touch: boolean): Look
	return if touch then TALK.Look.Touch else TALK.Look.Desktop
end

function MosskeeperTalk.looks(touch: boolean): { Look }
	return if touch then { TALK.Look.Touch, TALK.Look.TouchTight } else { TALK.Look.Desktop, TALK.Look.DesktopTight }
end

local function blockSize(look: Look, widths: (Look) -> (number, number), count: number): (number, number, number)
	local widest, countsWidth = widths(look)
	local rowsH = count * look.Row + math.max(0, count - 1) * look.Gap
	return math.ceil(math.max(widest, countsWidth)), rowsH + look.Gap + look.Counts + 6, rowsH
end

local function blockAt(x: number, y: number, look: Look, widths: (Look) -> (number, number), count: number,
	clear: boolean, keepsHis: boolean, keepsSoft: boolean): Block
	local w, h, rowsH = blockSize(look, widths, count)
	local rows: { Rect } = {}
	for i = 1, count do
		table.insert(rows, rect(x, y + (i - 1) * (look.Row + look.Gap), w, look.Row))
	end
	return {
		rows = rows,
		counts = rect(x, y + rowsH + look.Gap, w, h - rowsH - look.Gap),
		look = look,
		clear = clear,
		keepsHis = keepsHis,
		keepsSoft = keepsSoft,
	}
end

function MosskeeperTalk.place(anchor: Vector2, bounds: Rect, touch: boolean, widths: (Look) -> (number, number),
	blocked: { Rect }, soft: { Rect }, his: Rect?, count: number): Block
	local M = TALK.Margin
	local inner = rect(bounds.x + M, bounds.y + M, math.max(0, bounds.w - 2 * M), math.max(0, bounds.h - 2 * M))
	local function joined(withSoft: boolean, withHis: boolean): { Rect }
		local out = table.clone(blocked)
		if withSoft then
			for _, r in ipairs(soft) do
				table.insert(out, r)
			end
		end
		if withHis and his then
			table.insert(out, his)
		end
		return out
	end
	local looks = MosskeeperTalk.looks(touch)
	for _, pass in ipairs({ { true, true }, { false, true }, { true, false }, { false, false } }) do
		local against = joined(pass[1], pass[2])
		for _, look in ipairs(looks) do
			local w, h = blockSize(look, widths, count)
			local spot = SpeedMilestones.clearOf(rect(anchor.X, anchor.Y - h / 2, w, h), against, inner, M)
			if spot then
				return blockAt(spot.x, spot.y, look, widths, count, true, pass[2] or his == nil, pass[1] or #soft == 0)
			end
		end
	end
	local look = looks[#looks]
	local w, h = blockSize(look, widths, count)
	local hiX, hiY = inner.x + inner.w - w, inner.y + inner.h - h
	local x = if hiX < inner.x then inner.x else math.clamp(anchor.X, inner.x, hiX)
	local y = if hiY < inner.y then inner.y else math.clamp(anchor.Y - h / 2, inner.y, hiY)
	return blockAt(x, y, look, widths, count, false, his == nil, #soft == 0)
end

return MosskeeperTalk
