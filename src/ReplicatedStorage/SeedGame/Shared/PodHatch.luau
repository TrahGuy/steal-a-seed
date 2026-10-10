--!strict
--==============================================================================
-- Steal a Seed :: PodHatch (2026-10-10, Michael on v1047: "no way to hatch the
-- egg in your hotbar without navigating to bag and hatch all")
--
-- HATCH OVER A READY POD IN THE HANDS. Client only; LoadoutUI owns one, as it
-- owns TrapRemove, and tells it the same facts: the layout, whether the strip
-- is on screen and at rest, and the slot the pod in the hands stands in, with
-- the pod.
--
-- THE BUTTON is REMOVE's twin over the pod's own slot, in the same row
-- (HudLayout.removeButton; the row stands while either claims it,
-- TrapRemove.claimRow): HATCH on the green face, HELD -- the Bag's own hold
-- (MenuKit.hold: Plant.HatchHoldSeconds and the shell's rattle), and letting
-- go early does nothing. Only while that pod is READY: a growing pod's card
-- already counts its time down, and Instant Hatch stays in the Bag and at the
-- bed. A controller steps up from the pod's slot onto it and back down; its
-- own way is HandKey (LT) held, since RT plants the pod (PlantPlace).
--
-- THE HATCH is the Bag's own verb (HatchInBag.Hatch, by the pod's item id):
-- the server checks the pod is this player's and READY; the plant goes to a
-- free bed, else the Bag; its answer is the Bag's (LoadoutUI). One request per
-- pod until PENDING_SECONDS pass.
--
-- Nothing here runs per frame: a growing pod is looked at again when it is due.
--==============================================================================
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local PadInput = require(Shared:WaitForChild("PadInput"))
local TrapRemove = require(Shared:WaitForChild("TrapRemove"))

local PodHatch = {}

local HOT = GameConfig.Hotbar
local BAG = GameConfig.HatchInBag
local RATTLE: string = GameConfig.Plant.Hatch.Sounds.Rattle
local PAD_ACTION = "SeedHandHatch"
local PENDING_SECONDS = 2

-- The pod in the hands: its item id (its Bag row's) and when it is due, in
-- server time.
export type Pod = { item: string, hatchAt: number }

export type Options = {
	player: Player,
	-- The GameEvent remote, once LoadoutUI has found it.
	channel: () -> RemoteEvent?,
}

export type Handle = {
	layout: (HudLayout.Layout?) -> (),
	-- The slot the pod in the hands stands in, that slot's button, and the pod;
	-- nils for none (nothing in the hands, not a pod, or on no shown slot).
	slot: (number?, GuiObject?, Pod?) -> (),
	strip: (boolean) -> (),
	-- The hold's end: ask the server to hatch the pod in the hands. Answers
	-- whether it asked.
	press: () -> boolean,
	-- Whether HATCH stands now.
	offered: () -> boolean,
	button: TextButton,
}

function PodHatch.new(gui: ScreenGui, opts: Options): Handle
	local player = opts.player
	local layout: HudLayout.Layout? = nil
	local slotIndex: number? = nil
	local slotButton: GuiObject? = nil
	local pod: Pod? = nil
	local stripShown = true
	local rowWanted: boolean? = nil
	local shown = false
	local pendingFor: string? = nil
	local pendingUntil = 0
	local waitingFor: number? = nil

	--==========================================================================
	-- THE BUTTON: the press over the slot's row, a small green plate at its foot
	--==========================================================================
	local mb = MenuKit.button(gui, "PodHatch", 12, BAG.Words.Hatch, HOT.RemoveText)
	mb.style("go")
	local button = mb.hit
	button.Selectable = true
	button.Visible = false
	mb.plate.AnchorPoint = Vector2.zero
	local fit = mb.label:FindFirstChildOfClass("UITextSizeConstraint")

	local function press(): boolean
		local p = pod
		if not (p and shown) or Workspace:GetServerTimeNow() < p.hatchAt then
			return false
		end
		if pendingFor == p.item and os.clock() < pendingUntil then
			return false
		end
		local remote = opts.channel()
		if not remote then
			return false
		end
		pendingFor = p.item
		pendingUntil = os.clock() + PENDING_SECONDS
		remote:FireServer(BAG.Hatch, p.item)
		return true
	end
	local stopHold, startHold = MenuKit.hold(mb, GameConfig.Plant.HatchHoldSeconds, RATTLE, function()
		press()
	end)

	--==========================================================================
	-- LT ON A CONTROLLER: held, the same fill; let go and it stops
	--==========================================================================
	local padBound = false
	local function padHatch(_: string, state: Enum.UserInputState): Enum.ContextActionResult
		if state ~= Enum.UserInputState.Begin then
			stopHold()
			return Enum.ContextActionResult.Pass
		end
		-- A panel, or a selection out on the HUD, has the buttons.
		local selected = GuiService.SelectedObject
		if PadInput.panelOpen() or (selected ~= nil and selected ~= button) then
			return Enum.ContextActionResult.Pass
		end
		startHold()
		return Enum.ContextActionResult.Sink
	end
	local function bindPad(want: boolean)
		if want == padBound then
			return
		end
		padBound = want
		if want then
			ContextActionService:BindActionAtPriority(PAD_ACTION, padHatch, false,
				Enum.ContextActionPriority.High.Value, BAG.HandKey)
		else
			ContextActionService:UnbindAction(PAD_ACTION)
		end
	end

	--==========================================================================
	-- WHERE IT STANDS, AND WHETHER
	--
	-- Shown only with a READY pod in the hands on a shown slot, a layout that
	-- reserved the row, and the strip on screen and at rest. The row is claimed
	-- from the facts that do not depend on the layout, as REMOVE's is.
	--==========================================================================
	local place: () -> ()
	-- A growing pod: looked at again the moment it is due -- one wait per due
	-- time, however often the strip repaints meanwhile.
	local function lookWhenDue(due: number)
		if waitingFor == due then
			return
		end
		waitingFor = due
		task.delay(math.max(0.05, due - Workspace:GetServerTimeNow() + 0.05), function()
			if waitingFor == due then
				waitingFor = nil
				place()
			end
		end)
	end
	place = function()
		local p = pod
		local ready = p ~= nil and Workspace:GetServerTimeNow() >= p.hatchAt
		local want = ready and slotIndex ~= nil
		if rowWanted ~= want then
			rowWanted = want
			TrapRemove.claimRow(player, "hatch", want)
		end
		local L = layout
		local area, drawn = nil, nil
		if want and L and slotIndex then
			area, drawn = HudLayout.removeButton(L, slotIndex)
		end
		local show = want and stripShown and area ~= nil and drawn ~= nil
		if show and L and area and drawn then
			button.Position = HudLayout.place(area, Vector2.zero, L.safe)
			button.Size = UDim2.fromOffset(area.w, area.h)
			mb.plate.Position = UDim2.fromOffset(drawn.x - area.x, drawn.y - area.y)
			mb.plate.Size = UDim2.fromOffset(drawn.w, drawn.h)
			if fit then
				fit.MaxTextSize = L.hot.RemoveText or HOT.RemoveText
			end
		end
		if shown ~= show then
			shown = show
			button.Visible = show
			-- PlantPlace's reticle names LT beside RT and B while it stands.
			player:SetAttribute(BAG.HandAttribute, if show then true else nil)
			if not show then
				stopHold()
				-- A controller's selection on a button that just went goes back
				-- down to the pod's slot rather than nowhere.
				if GuiService.SelectedObject == button then
					GuiService.SelectedObject = slotButton :: any
				end
			end
		end
		bindPad(show)
		button.NextSelectionDown = slotButton
		if slotButton then
			(slotButton :: any).NextSelectionUp = if show then button else nil
		end
		if p and not ready then
			lookWhenDue(p.hatchAt)
		end
	end

	return {
		layout = function(L: HudLayout.Layout?)
			layout = L
			place()
		end,
		slot = function(index: number?, slotObject: GuiObject?, held: Pod?)
			-- The old slot's link up, unless REMOVE has it.
			local old = slotButton
			if old and old ~= slotObject and (old :: any).NextSelectionUp == button then
				(old :: any).NextSelectionUp = nil
			end
			pod = held
			slotIndex = if held then index else nil
			slotButton = if held then slotObject else nil
			place()
		end,
		strip = function(on: boolean)
			stripShown = on
			place()
		end,
		press = press,
		offered = function(): boolean
			return shown
		end,
		button = button,
	}
end

return PodHatch
