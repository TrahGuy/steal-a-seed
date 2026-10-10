--!strict
--==============================================================================
-- Steal a Seed :: InventoryPanel (2026-10-03, the owner's compact Bag + free
-- hotbar)
--
-- THE BAG'S INSIDES, inside LoadoutUI's UIKit.modal ("Bag"):
--
--   top bar     a search box and the favourites heart -- their own row under
--               the title, or the title's row on a short screen
--               (HudLayout.bagSearch)
--   left        five category buttons: All Items, Plants, Pods, Equipment,
--               Spin Tickets, each with its count
--   grid        small square tiles (InventoryTile), pooled by group, their
--               pictures built only once a tile has been on screen; downward on
--               a desktop, sideways in whole rows on a phone
--   footer      the storage line ("Plant storage: 4/24")
--   tooltip     a mouse resting on a tile: its full name and details
--   menu        a long press, a right-click or RT: the details and what can be
--               done -- drawn over everything, with its own selection group and
--               a backdrop that takes the outside click, so a click never
--               reaches the Bag's dimmer behind it
--
-- WHAT A PRESS MEANT is PressGesture's (a tap, a long press, a mouse drag, a
-- scroll that is none of those); WHAT IT DOES is LoadoutUI's, through the
-- callbacks. This file holds no item, no profile and no remote: it draws the
-- view it is handed and says which key was pressed. Out of LoadoutUI, whose
-- chunk is rationed to Luau's 200 locals.
--
-- THE LOOK (2026-10-03, the owner's approved mockup, GameConfig.BagLook):
-- forest slate, cream type, a sprout beside the title, a magnifying glass in
-- the search box, an icon on each category (the approved category art once its
-- ids are in BagLook.IconImages; until then drawn in frames, the Garden's pot
-- art for plants), the chosen one green with a narrow
-- amber mark, a dark inset grid, a storage bar beside the footer's words. Every
-- keyline a thin Border stroke -- a TextButton's default strokes its TEXT.
-- A Mythic, Divine or Secret's rarity word moves (RarityFX) on its tile and on
-- the tooltip's and menu's Rarity line -- only on screen, only while open.
--==============================================================================
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local InventoryTile = require(Shared:WaitForChild("InventoryTile"))
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local PressGesture = require(Shared:WaitForChild("PressGesture"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local InventoryPanel = {}

local RAIL = GameConfig.Rail
local LOOK = GameConfig.BagLook
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local CREAM = LOOK.Cream
local MUTED = LOOK.Muted
-- Words on the Bag's LIGHT plates since the bright recolor (2026-10-04): the
-- search, the tooltip, the footer. CREAM stays for the dark count pill.
local TEXT = LOOK.Text

-- The footer's words sit on the light shell, but its colours are the strip's
-- bright count colours (HOT.CountOpen / CountFull / CountLoading, made for the
-- dark strip): the words take them toward ink; the storage bar keeps them.
local function onLight(colour: Color3): Color3
	return colour:Lerp(LOOK.Ink, 0.4)
end
-- The item menu's measures (two columns since 2026-10-10: InventoryPanel.menuFit).
local MENU_W = 228
local MENU_PAD_X, MENU_PAD_TOP, MENU_PAD_BOTTOM = 10, 8, 10
local MENU_INNER = MENU_W - 2 * MENU_PAD_X
local MENU_ROW_GAP, MENU_SIDE_GAP = 4, 10
local MENU_BUTTON_H, MENU_BUTTON_GAP = 44, 4
-- placeBeside's margin, on every edge of the screen.
local MENU_MARGIN = 8
-- A column that scrolls: its bar, and the room its buttons keep clear of the
-- clip on each side (a plate's keyline, and its hover growth).
local MENU_BAR, MENU_CLEAR = 4, 6
-- A Bag menu action's face (MenuKit), by the action's id.
local MENU_FACE: { [string]: string } = {
	assign = "go",
	wear = "go",
	remove = "sky",
	favourite = "idle",
	removetrap = "danger",
	-- Pods hatch in the Bag (2026-10-09): HATCH green, Instant Hatch premium.
	hatch = "go",
	instant = "premium",
	hold = "idle",
}

--==============================================================================
-- A HOLD, NOT A PRESS (2026-10-09, pods hatch in the Bag)
--
-- HATCH and HATCH ALL are the bed prompt's own hold (`seconds`,
-- GameConfig.Plant.HatchHoldSeconds): a finger or the mouse holds the button
-- down while its face fills and the shell's rattle plays, and letting go early
-- -- anywhere on the screen -- does nothing at all. A controller's A or Enter
-- (Activated with no press under way) starts the same fill, which closing the
-- menu stops. Answers a function that stops a hold under way.
--==============================================================================
local RATTLE: string = GameConfig.Plant.Hatch.Sounds.Rattle
-- Tweened, so nothing here runs per frame: the face fills over the hold, and
-- the plate rocks a few degrees while it does.
local ROCK = TweenInfo.new(0.07, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local function holdButton(mb: MenuKit.Button, seconds: number, done: () -> ()): () -> ()
	local fill = Instance.new("Frame")
	fill.Name = "HoldFill"
	fill.BackgroundColor3 = WHITE
	fill.BackgroundTransparency = 0.55
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.ZIndex = mb.label.ZIndex - 1
	fill.Active = false
	fill.Parent = mb.plate
	UIKit.corner(fill, 10)
	local hold = 0
	local filling: Tween? = nil
	local rocking: Tween? = nil
	local letGo: RBXScriptConnection? = nil
	local pressing = false
	local lastEnded = 0
	local function stop()
		hold += 1
		pressing = false
		if filling then
			filling:Cancel()
			filling = nil
		end
		if rocking then
			rocking:Cancel()
			rocking = nil
		end
		if letGo then
			letGo:Disconnect()
			letGo = nil
		end
		fill.Size = UDim2.fromScale(0, 1)
		mb.plate.Rotation = 0
	end
	local function begin()
		if filling then
			return
		end
		hold += 1
		local this = hold
		if RATTLE ~= "" and SoundKit.has(RATTLE) then
			SoundKit.play(RATTLE)
		end
		mb.plate.Rotation = -3
		local rock = TweenService:Create(mb.plate, ROCK, { Rotation = 3 })
		rocking = rock
		rock:Play()
		local tween = TweenService:Create(fill, TweenInfo.new(seconds, Enum.EasingStyle.Linear),
			{ Size = UDim2.fromScale(1, 1) })
		filling = tween
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			-- Only this hold, run to its end, on a button still in the game.
			if state ~= Enum.PlaybackState.Completed or hold ~= this or not mb.hit:IsDescendantOf(game) then
				return
			end
			stop()
			done()
		end)
		tween:Play()
	end
	mb.hit.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			pressing = true
			begin()
			-- Let go anywhere and the hold is off, not only over the button.
			if letGo then
				letGo:Disconnect()
			end
			letGo = UserInputService.InputEnded:Connect(function(ended: InputObject)
				if ended.UserInputType == kind then
					lastEnded = os.clock()
					stop()
				end
			end)
		end
	end)
	mb.hit.Activated:Connect(function()
		if pressing or filling or os.clock() - lastEnded < 0.4 then
			return
		end
		begin()
	end)
	return stop
end

-- A small icon on the left of a button's face (the owner's HatchInBag icons,
-- cut by their shared crop); none for an id that is "".
local function buttonIcon(mb: MenuKit.Button, id: string?)
	if not id or id == "" then
		return
	end
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 6, 0.5, -2)
	icon.Size = UDim2.fromOffset(24, 24)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = mb.label.ZIndex
	icon.Parent = mb.plate
	InventoryTile.bagIcon(icon, id)
	mb.label.Position = UDim2.fromOffset(30, 1)
	mb.label.Size = UDim2.new(1, -36, 1 - LOOK.FootShare, 0)
end
local TIP_W = 210
-- The Bag's own approved satchel beside the title (GameConfig.Rail.BagIcon,
-- the global UI pass), and the room it takes before the title's words.
local TITLE_ICON = 34
local TITLE_ICON_GAP = 4
-- A category's icon: drawn on a desktop's column, left out of a phone's narrow one.
local CAT_ICON = 18
local CAT_ICON_MIN_COLUMN = 130

-- A thin keyline on a box's BORDER, whatever the box is.
local function keyline(parent: GuiObject, colour: Color3, thickness: number, transparency: number?): UIStroke
	local s = UIKit.stroke(parent, colour, thickness, transparency)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

-- Every layer of a drawn icon moved up to `z` and above, for a gui whose
-- ZIndexBehavior is Global (UIKit's drawn icons are built from 1 up).
local function raise(root: GuiObject, z: number)
	root.ZIndex = z
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = z + d.ZIndex
		end
	end
end

--==============================================================================
-- THE CATEGORY ICONS, in a square box: the leaf for everything, the Garden's
-- own pot for plants, the wheel's green pod for pods, a bat for equipment, a
-- ticket for Spin Tickets. Big flat shapes and an ink edge: nothing thinner
-- than a tenth of the box, the size they are read at.
--==============================================================================
local drawnIcon: (GuiObject, string, number, number) -> GuiObject

local function categoryIcon(parent: GuiObject, id: string, size: number, z: number): GuiObject
	-- The approved category art (BagLook.IconImages), over the drawn icon,
	-- which stays until the picture has loaded here and for good if it never
	-- does (UIKit.whenPictureLoads).
	local art = (LOOK.IconImages :: any)[id]
	if type(art) == "string" and art ~= "" then
		local holder = Instance.new("Frame")
		holder.Name = "Icon"
		holder.AnchorPoint = Vector2.new(0, 0.5)
		holder.Size = UDim2.fromOffset(LOOK.IconImageSize, LOOK.IconImageSize)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Active = false
		holder.ZIndex = z
		holder.Parent = parent
		local fallback = drawnIcon(holder, id, size, z)
		fallback.Name = "Fallback"
		fallback.AnchorPoint = Vector2.new(0.5, 0.5)
		fallback.Position = UDim2.fromScale(0.5, 0.5)
		local pic = Instance.new("ImageLabel")
		pic.Name = "Picture"
		pic.Size = UDim2.fromScale(1, 1)
		pic.BackgroundTransparency = 1
		pic.BorderSizePixel = 0
		pic.Active = false
		pic.Image = art
		pic.ScaleType = Enum.ScaleType.Fit
		pic.ZIndex = z + 4
		pic.Parent = holder
		-- The drawn icon goes once the picture has loaded; the picture is never
		-- hidden (an unloaded one draws nothing, the drawn icon shows through).
		UIKit.whenPictureLoads(pic, function(loaded: boolean)
			if loaded then
				fallback.Visible = false
			end
		end)
		return holder
	end
	return drawnIcon(parent, id, size, z)
end

drawnIcon = function(parent: GuiObject, id: string, size: number, z: number): GuiObject
	local box = Instance.new("Frame")
	box.Name = "Icon"
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Size = UDim2.fromOffset(size, size)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Active = false
	box.Parent = parent
	if id == "plants" then
		local pot = Instance.new("ImageLabel")
		pot.Name = "Pot"
		pot.Size = UDim2.fromScale(1, 1)
		pot.BackgroundTransparency = 1
		pot.Image = RAIL.GardenIcon
		pot.ScaleType = Enum.ScaleType.Fit
		pot.Parent = box
	elseif id == "pods" then
		-- A closed seed pod, after the approved art (never the wheel's oval,
		-- which read as a "0" at this size): a teardrop body pointing up, a
		-- darker rib, two small leaves at its foot.
		UIKit.piece(box, "Body", 0.5, 0.60, 0.66, 0.66, LOOK.IconLeaf, 0.5, nil, 1)
		UIKit.piece(box, "Point", 0.5, 0.42, 0.47, 0.47, LOOK.IconLeaf, 0.14, 45, 1)
		UIKit.piece(box, "Rib", 0.5, 0.56, 0.12, 0.56, LOOK.IconVein, 0.5, nil, 2)
		UIKit.piece(box, "LeafL", 0.30, 0.86, 0.34, 0.16, LOOK.IconVein, 0.5, -24, 2)
		UIKit.piece(box, "LeafR", 0.70, 0.86, 0.34, 0.16, LOOK.IconVein, 0.5, 24, 2)
	elseif id == "equipment" then
		UIKit.piece(box, "Grip", 0.30, 0.70, 0.17, 0.52, LOOK.IconGrip, 0.5, 45, 1)
		local head = UIKit.piece(box, "Barrel", 0.58, 0.42, 0.30, 0.66, LOOK.IconWood, 0.5, 45, 2)
		keyline(head, LOOK.Ink, 1)
	elseif id == "tickets" then
		local ticket = UIKit.piece(box, "Ticket", 0.5, 0.5, 0.92, 0.62, LOOK.IconTicket, 0.18, -14, 1)
		keyline(ticket, LOOK.IconTicketInk, 1.25)
		UIKit.piece(box, "Mark", 0.5, 0.5, 0.24, 0.24, LOOK.IconTicketInk, 0.15, 31, 2)
	else
		-- A leaf as a teardrop: a disc and a turned square of the same size,
		-- the square's corner the tip (up and right), a vein along it, a stalk.
		UIKit.piece(box, "Body", 0.42, 0.58, 0.62, 0.62, LOOK.IconLeaf, 0.5, nil, 1)
		UIKit.piece(box, "Tip", 0.56, 0.44, 0.62, 0.62, LOOK.IconLeaf, 0.12, 45, 1)
		UIKit.piece(box, "Vein", 0.48, 0.52, 0.10, 0.70, LOOK.IconVein, 0.5, 45, 2)
		UIKit.piece(box, "Stalk", 0.16, 0.86, 0.10, 0.26, LOOK.IconVein, 0.5, 45, 2)
	end
	raise(box, z)
	return box
end

export type Entry = {
	key: string,
	paint: InventoryTile.Paint,
	art: InventoryModel.Art,
	artKey: string,
}

export type View = {
	entries: { Entry },
	counts: { [string]: number },
	footer: string,
	footerColour: Color3,
	-- How full plant storage is, 0..1, for the bar beside the words (nil: no bar).
	footerFill: number?,
	empty: string?,
	compact: boolean,
	-- How many pods in the Bag are READY (2026-10-09): HATCH ALL shows while
	-- there is one.
	readyPods: number?,
}

-- `hold` (2026-10-09): seconds the action must be held (HATCH); `icon`: an
-- owner's icon on its face.
export type MenuSpec = {
	title: string,
	lines: { InventoryModel.Line },
	actions: { { id: string, label: string, hold: number?, icon: string? } },
}

export type Callbacks = {
	activate: (key: string, by: string) -> (),
	menu: (key: string, anchor: Rect) -> (),
	canDrag: (key: string) -> boolean,
	dragBegin: (key: string, input: InputObject) -> (),
	describe: (key: string) -> (string?, { InventoryModel.Line }?),
	changed: () -> (),
	-- HATCH ALL held to the end (2026-10-09).
	hatchAll: (() -> ())?,
}

type Rect = HudLayout.Rect

export type Panel = {
	state: { category: string, search: string, favouritesOnly: boolean },
	paint: (View) -> (),
	layout: (HudLayout.Bag, number) -> (),
	contains: (Vector2) -> boolean,
	keyAt: (Vector2) -> string?,
	tileButton: (string) -> GuiObject?,
	openMenu: (Rect, MenuSpec, (string) -> ()) -> (),
	closeMenu: () -> (),
	menuOpen: () -> boolean,
	hideTooltip: () -> (),
	say: (string, number) -> (),
	dim: (boolean) -> (),
	reset: () -> (),
	setOpen: (boolean) -> (),
	grid: ScrollingFrame,
}

local function rectOf(object: GuiObject, k: number): Rect
	local at, size = object.AbsolutePosition / k, object.AbsoluteSize / k
	return { x = at.X, y = at.Y, w = size.X, h = size.Y }
end

local function inside(pt: Vector2, object: GuiObject): boolean
	local at, size = object.AbsolutePosition, object.AbsoluteSize
	return object.Visible and pt.X >= at.X and pt.X <= at.X + size.X and pt.Y >= at.Y and pt.Y <= at.Y + size.Y
end

--==============================================================================
-- THE MENU'S SHAPE ON A SCREEN (2026-10-10)
--
-- The owner's phone screenshot: a pod's menu -- six lines of details over
-- INSTANT HATCH, Assign to slot, Favourite, Hold in hands, WHAT'S INSIDE? --
-- ran off the bottom of a landscape phone, its last buttons out of reach. The
-- menu is two columns now, its words (MenuInfo) and its buttons (MenuActions):
--
--   * one over the other where the screen's height holds both -- a desktop,
--     and a phone's shorter menus: the menu every screen had before;
--   * side by side where it does not and the screen is wide enough for two (a
--     landscape phone always is);
--   * and a column still taller than the room scrolls, its bar showing --
--     never the menu off the screen. On a screen too narrow for two, the
--     buttons give way first, never to less than one button's height.
--
-- `screen` is the gui's whole size, `info` the words' own height, `count` the
-- buttons. Every number in the gui's units, the menu's padding included; the
-- room is MENU_MARGIN clear of each edge (placeBeside's).
--==============================================================================
export type MenuFit = {
	side: boolean,
	width: number,
	height: number,
	-- Each column's window: a column scrolls where its content is taller.
	infoView: number,
	actionsView: number,
	-- The buttons' whole column.
	actions: number,
}

function InventoryPanel.menuFit(screen: Vector2, info: number, count: number): MenuFit
	local pad = MENU_PAD_TOP + MENU_PAD_BOTTOM
	local actions = if count > 0 then count * MENU_BUTTON_H + (count - 1) * MENU_BUTTON_GAP else 0
	local gap = if count > 0 then MENU_ROW_GAP else 0
	local roomY = math.max(0, screen.Y - 2 * MENU_MARGIN) - pad
	local roomX = math.max(0, screen.X - 2 * MENU_MARGIN)
	local sideW = MENU_W + MENU_SIDE_GAP + MENU_INNER
	if info + gap + actions <= roomY or count == 0 or sideW > roomX then
		local actionsView = math.min(actions, math.max(MENU_BUTTON_H, roomY - info - gap))
		local infoView = math.min(info, math.max(MENU_BUTTON_H, roomY - gap - actionsView))
		return { side = false, width = MENU_W, height = pad + infoView + gap + actionsView, infoView = infoView,
			actionsView = actionsView, actions = actions }
	end
	local actionsView = math.min(actions, math.max(MENU_BUTTON_H, roomY))
	local infoView = math.min(info, math.max(MENU_BUTTON_H, roomY))
	return { side = true, width = sideW, height = pad + math.max(infoView, actionsView), infoView = infoView,
		actionsView = actionsView, actions = actions }
end

function InventoryPanel.build(gui: ScreenGui, modal: any, T: any, cb: Callbacks): Panel
	local shell: Frame = modal.shell
	local body: Frame = modal.body
	local state = { category = "all", search = "", favouritesOnly = false }
	local player = Players.LocalPlayer

	--==========================================================================
	-- THE TITLE'S ICON: THE BAG'S OWN SATCHEL
	--
	-- Beside the word, on the studded rim: the approved Bag picture (the rail's,
	-- GameConfig.Rail.BagIcon) where the drawn sprout stood. The title moves over
	-- by its width, and `layout` tells HudLayout.bagSearch the title is that
	-- much wider.
	--==========================================================================
	local titleBar = modal.title.Parent :: GuiObject
	local sprout = MenuKit.picture(titleBar, RAIL.BagIcon, nil, modal.title.ZIndex + 1)
	sprout.AnchorPoint = Vector2.new(0, 0.5)
	sprout.Position = UDim2.new(0, 0, 0.5, -1)
	sprout.Size = UDim2.fromOffset(TITLE_ICON, TITLE_ICON)
	modal.title.Position = UDim2.new(0, TITLE_ICON + TITLE_ICON_GAP, 0.5, 0)
	modal.title.Size = UDim2.new(1, -52 - TITLE_ICON - TITLE_ICON_GAP, 1, 0)

	--==========================================================================
	-- THE TOP BAR
	--==========================================================================
	local search = Instance.new("TextBox")
	search.Name = "Search"
	search.BackgroundColor3 = LOOK.Well
	search.BackgroundTransparency = LOOK.WellTransparency
	search.BorderSizePixel = 0
	search.ClearTextOnFocus = false
	search.Font = LOOK.BodyFont
	search.TextSize = 15
	search.TextColor3 = TEXT
	search.PlaceholderText = "Search"
	search.PlaceholderColor3 = LOOK.Placeholder
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.Text = ""
	search.ZIndex = 5
	search.Parent = shell
	UIKit.corner(search, 9)
	keyline(search, LOOK.WellEdge, 1)
	local searchPad = Instance.new("UIPadding")
	searchPad.PaddingLeft = UDim.new(0, 32)
	searchPad.PaddingRight = UDim.new(0, 10)
	searchPad.Parent = search
	-- The magnifying glass: a ring and a handle, in the placeholder's colour.
	-- Laid on the shell beside the box's text, never inside the TextBox, so
	-- the box's padding cannot move it.
	local glass = Instance.new("Frame")
	glass.Name = "SearchGlass"
	glass.AnchorPoint = Vector2.new(0, 0.5)
	glass.Size = UDim2.fromOffset(16, 16)
	glass.BackgroundTransparency = 1
	glass.Active = false
	glass.Parent = shell
	local ring = UIKit.piece(glass, "Ring", 0.42, 0.42, 0.66, 0.66, LOOK.Placeholder, 0.5, nil, 1)
	ring.BackgroundTransparency = 1
	keyline(ring, LOOK.Placeholder, 2)
	UIKit.piece(glass, "Handle", 0.80, 0.80, 0.16, 0.42, LOOK.Placeholder, 0.5, -45, 1)
	raise(glass, 6)

	local heartButton = Instance.new("TextButton")
	heartButton.Name = "Favourites"
	heartButton.BackgroundColor3 = LOOK.Well
	heartButton.BackgroundTransparency = LOOK.WellTransparency
	heartButton.BorderSizePixel = 0
	heartButton.AutoButtonColor = false
	heartButton.Text = ""
	heartButton.ZIndex = 5
	heartButton.Parent = shell
	UIKit.corner(heartButton, 9)
	local heartEdge = keyline(heartButton, LOOK.WellEdge, 1)
	UIKit.clicks(heartButton)
	local filterHeart = InventoryTile.heart(heartButton, 18, 6)
	filterHeart.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	filterHeart.frame.Position = UDim2.fromScale(0.5, 0.5)

	--==========================================================================
	-- THE CATEGORY COLUMN
	--==========================================================================
	local column = Instance.new("Frame")
	column.Name = "Categories"
	column.BackgroundTransparency = 1
	column.ZIndex = 4
	column.Parent = body
	type Cat = { button: TextButton, tint: UIGradient, edge: UIStroke, label: TextLabel, count: TextLabel,
		icon: GuiObject, mark: Frame }
	local catButtons: { [string]: Cat } = {}
	for i, category in ipairs(InventoryModel.Categories) do
		local b = Instance.new("TextButton")
		b.Name = "Cat" .. category.id
		b.BackgroundColor3 = WHITE
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Text = ""
		b.LayoutOrder = i
		b.ZIndex = 5
		b.Parent = column
		UIKit.corner(b, 9)
		local edge = keyline(b, LOOK.CatEdge, 1)
		UIKit.clicks(b)
		local tint = UIKit.gradient(b, LOOK.CatTop, LOOK.CatBottom)
		-- The chosen one's narrow amber mark, down the left edge.
		local mark = Instance.new("Frame")
		mark.Name = "Mark"
		mark.AnchorPoint = Vector2.new(0, 0.5)
		mark.Position = UDim2.new(0, 3, 0.5, 0)
		mark.Size = UDim2.new(0, 3, 1, -14)
		mark.BackgroundColor3 = LOOK.CatMark
		mark.BorderSizePixel = 0
		mark.Active = false
		mark.Visible = false
		mark.ZIndex = 7
		mark.Parent = b
		UIKit.corner(mark, 2)
		local icon = categoryIcon(b, category.id, CAT_ICON, 6)
		icon.Position = UDim2.new(0, 9, 0.5, 0)
		-- Plain dark words on the pale button; white with a thin ink line once
		-- chosen (MenuKit's ink follows the colour). The readability brief: no
		-- outline round small dark type.
		local label = MenuKit.text(b, "Label", 15, LOOK.CatText, 6)
		label.Position = UDim2.fromOffset(8, 0)
		label.Size = UDim2.new(1, -44, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		-- ONE line, its size measured (fitLabels): TextScaled wraps "SPIN
		-- TICKETS" onto two lines beside an icon, which the mockup never does.
		label.TextScaled = false
		label.TextWrapped = false
		label.Text = category.label
		label.ZIndex = 6
		local count = Instance.new("TextLabel")
		count.Name = "Count"
		count.AnchorPoint = Vector2.new(1, 0.5)
		count.Position = UDim2.new(1, -5, 0.5, 0)
		count.Size = UDim2.fromOffset(0, 18)
		count.AutomaticSize = Enum.AutomaticSize.X
		count.BackgroundColor3 = LOOK.Count
		count.BackgroundTransparency = LOOK.CountTransparency
		count.BorderSizePixel = 0
		count.Font = Enum.Font.FredokaOne
		count.TextSize = 12
		count.TextColor3 = CREAM
		count.Text = "0"
		count.ZIndex = 7
		count.Parent = b
		UIKit.corner(count, 9)
		local countPad = Instance.new("UIPadding")
		countPad.PaddingLeft = UDim.new(0, 5)
		countPad.PaddingRight = UDim.new(0, 5)
		countPad.Parent = count
		local scale = Instance.new("UIScale")
		scale.Parent = b
		UIKit.cardPop(b, scale, { hoverScale = 1.03, pressScale = 0.97, sound = false })
		catButtons[category.id] = { button = b, tint = tint, edge = edge, label = label, count = count,
			icon = icon, mark = mark }
		b.Activated:Connect(function()
			if state.category ~= category.id then
				state.category = category.id
				cb.changed()
			end
		end)
	end
	local columnLayout = Instance.new("UIListLayout")
	columnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	columnLayout.Parent = column

	-- ONE size for all five labels: the largest (15 down to 9) at which every
	-- one fits on its line between its icon and its count, in the panel's own
	-- units -- five different sizes down one column read as a mistake.
	local labelX = 8
	local function fitLabels()
		local k = math.max(1e-3, UIKit.scaleOf(gui) * modal.userScale())
		local columnW = column.Size.X.Offset
		local size = 15
		for _, ui in pairs(catButtons) do
			local room = columnW - labelX - ui.count.AbsoluteSize.X / k - 9
			ui.label.Size = UDim2.new(0, math.max(10, room), 1, 0)
			while size > 9 and TextService:GetTextSize(ui.label.Text, size, ui.label.Font,
				Vector2.new(10000, 100)).X > room do
				size -= 1
			end
		end
		for _, ui in pairs(catButtons) do
			ui.label.TextSize = size
		end
	end

	--==========================================================================
	-- THE GRID, THE EMPTY LINE AND THE FOOTER
	--==========================================================================
	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Items"
	grid.BackgroundColor3 = LOOK.Well
	grid.BackgroundTransparency = LOOK.WellTransparency
	grid.BorderSizePixel = 0
	grid.CanvasSize = UDim2.new()
	grid.ScrollBarThickness = 6
	grid.ScrollBarImageColor3 = LOOK.WellEdge
	grid.ElasticBehavior = Enum.ElasticBehavior.Always
	-- The tiles are the controller's stops, never the list behind them.
	grid.Selectable = false
	grid.ZIndex = 4
	grid.Parent = body
	UIKit.corner(grid, 10)
	keyline(grid, LOOK.WellEdge, 1, 0.3)
	local gridPad = Instance.new("UIPadding")
	gridPad.Parent = grid
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	-- On the body, over the grid -- never inside it, where the grid's layout
	-- would take it for a tile (measured: squeezed into the first cell).
	local emptyLabel = MenuKit.body(body, "Empty", 15, MUTED, 6)
	emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false
	emptyLabel.ZIndex = 6

	-- The footer: a sprout, the storage words, and -- where the line has the
	-- room -- a small bar of how full storage is, in the words' colour.
	local footerSprout = UIKit.sproutIcon(body, 15, LOOK.Stem, LOOK.Leaf)
	footerSprout.AnchorPoint = Vector2.new(0, 0.5)
	raise(footerSprout, 5)
	local footer = Instance.new("TextLabel")
	footer.Name = "Storage"
	footer.BackgroundTransparency = 1
	footer.Font = Enum.Font.FredokaOne
	footer.TextScaled = true
	footer.TextXAlignment = Enum.TextXAlignment.Left
	footer.Text = ""
	footer.ZIndex = 5
	footer.Parent = body
	-- Dark words on the light shell: plain (no ink line round small dark type).
	local footerFit = Instance.new("UITextSizeConstraint")
	footerFit.MaxTextSize = 13
	footerFit.MinTextSize = 10
	footerFit.Parent = footer
	local barTrack = Instance.new("Frame")
	barTrack.Name = "StorageBar"
	barTrack.AnchorPoint = Vector2.new(0, 0.5)
	barTrack.BackgroundColor3 = LOOK.BarTrack
	barTrack.BorderSizePixel = 0
	barTrack.Active = false
	barTrack.ZIndex = 5
	barTrack.Parent = body
	UIKit.corner(barTrack, 3)
	keyline(barTrack, LOOK.WellEdge, 1, 0.4)
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BorderSizePixel = 0
	barFill.Active = false
	barFill.ZIndex = 6
	barFill.Parent = barTrack
	UIKit.corner(barFill, 3)
	-- Just after the words, and only where it fits whole on the line: a long
	-- line (a carried pod, prizes waiting) or a phone's narrow footer drops it.
	local function placeBar()
		local at, size = footer.Position, footer.Size
		-- TextBounds is drawn pixels: back to the panel's units (LoadoutUI
		-- reads the title's the same way).
		local k = math.max(1e-3, UIKit.scaleOf(gui) * modal.userScale())
		local x = at.X.Offset + footer.TextBounds.X / k + 10
		local fits = footer.Text ~= "" and x + LOOK.BarWidth <= at.X.Offset + size.X.Offset
		barTrack.Visible = fits
		barTrack.Position = UDim2.fromOffset(x, at.Y.Offset + size.Y.Offset / 2)
	end
	footer:GetPropertyChangedSignal("TextBounds"):Connect(placeBar)

	--==========================================================================
	-- HATCH ALL (2026-10-09, pods hatch in the Bag)
	--
	-- In the grid's bottom-right corner while a pod in the Bag is READY, with
	-- how many: held to the end like HATCH (holdButton), it hatches every one.
	-- The grid's bottom padding grows by its height while it shows, so the last
	-- row of tiles can always be scrolled clear of it.
	--==========================================================================
	local BAG = GameConfig.HatchInBag
	local hatchAll = MenuKit.button(body, "HatchAll", 30, BAG.Words.HatchAll, 15, { studs = true })
	hatchAll.style("go")
	buttonIcon(hatchAll, BAG.Icons.Hatch)
	hatchAll.hit.AnchorPoint = Vector2.new(1, 1)
	hatchAll.hit.Size = UDim2.fromOffset(150, 46)
	hatchAll.hit.Visible = false
	UIKit.clicks(hatchAll.hit)
	local HATCH_ALL_ROOM = 50
	local stopHatchAll = holdButton(hatchAll, GameConfig.Plant.HatchHoldSeconds, function()
		local fn = cb.hatchAll
		if fn then
			fn()
		end
	end)

	-- Assign mode's dim: a sheet over the whole shell, not the modal's
	-- GroupTransparency -- measured in Play, the Bag's CanvasGroup drew fully
	-- opaque at 0.4 and at 0.85 while a fresh one beside it faded. Never Active,
	-- so a tap still reaches what it lands on (and cancels the assignment).
	local dimSheet = Instance.new("Frame")
	dimSheet.Name = "AssignDim"
	dimSheet.Size = UDim2.fromScale(1, 1)
	dimSheet.BackgroundColor3 = BLACK
	dimSheet.BackgroundTransparency = 0.45
	dimSheet.BorderSizePixel = 0
	dimSheet.Active = false
	dimSheet.Visible = false
	dimSheet.ZIndex = 20
	dimSheet.Parent = shell
	UIKit.corner(dimSheet, 16)

	-- A controller's selection starts on the first tile (PadFocus reads this).
	local padFirst = Instance.new("ObjectValue")
	padFirst.Name = "PadFirst"
	padFirst.Parent = shell

	--==========================================================================
	-- THE TOOLTIP AND THE MENU: OVER EVERYTHING, AT THE GUI'S LEVEL
	--==========================================================================
	local tip = Instance.new("Frame")
	tip.Name = "BagTooltip"
	tip.BackgroundColor3 = LOOK.Sheet
	-- Solid: anything see-through over tiles ghosts their names through it.
	tip.BackgroundTransparency = 0
	tip.BorderSizePixel = 0
	tip.Size = UDim2.fromOffset(TIP_W, 10)
	tip.AutomaticSize = Enum.AutomaticSize.Y
	tip.Visible = false
	tip.ZIndex = 80
	tip.Parent = gui
	UIKit.corner(tip, 8)
	keyline(tip, LOOK.SheetEdge, 1, 0.3)
	local tipPad = Instance.new("UIPadding")
	tipPad.PaddingLeft = UDim.new(0, 8)
	tipPad.PaddingRight = UDim.new(0, 8)
	tipPad.PaddingTop = UDim.new(0, 6)
	tipPad.PaddingBottom = UDim.new(0, 6)
	tipPad.Parent = tip
	local tipLayout = Instance.new("UIListLayout")
	tipLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tipLayout.Padding = UDim.new(0, 2)
	tipLayout.Parent = tip

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "BagMenuBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundTransparency = 1
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.Selectable = false
	backdrop.Visible = false
	backdrop.ZIndex = 81
	backdrop.Parent = gui
	--==========================================================================
	-- THE MENU: ITS WORDS AND ITS BUTTONS, TWO COLUMNS (2026-10-10)
	--
	-- One over the other, or side by side where a screen is too short for that
	-- (InventoryPanel.menuFit); fitMenu lays them out on every open, and again
	-- whenever the words or the screen change size.
	--==========================================================================
	local menu = Instance.new("Frame")
	menu.Name = "BagMenu"
	menu.BackgroundColor3 = LOOK.Sheet
	menu.BackgroundTransparency = 0
	menu.BorderSizePixel = 0
	menu.Size = UDim2.fromOffset(MENU_W, 10)
	menu.Visible = false
	menu.ZIndex = 82
	menu.SelectionGroup = true
	menu.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	menu.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	menu.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	menu.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	menu.Parent = gui
	UIKit.corner(menu, 10)
	keyline(menu, LOOK.SheetEdge, 1.5, 0.15)
	local menuPad = Instance.new("UIPadding")
	menuPad.PaddingLeft = UDim.new(0, MENU_PAD_X)
	menuPad.PaddingRight = UDim.new(0, MENU_PAD_X)
	menuPad.PaddingTop = UDim.new(0, MENU_PAD_TOP)
	menuPad.PaddingBottom = UDim.new(0, MENU_PAD_BOTTOM)
	menuPad.Parent = menu
	local menuLayout = Instance.new("UIListLayout")
	menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
	menuLayout.Padding = UDim.new(0, MENU_ROW_GAP)
	menuLayout.Parent = menu
	-- A column of the menu: it scrolls only while its content is taller than it.
	local function menuColumn(name: string, order: number, gap: number): (ScrollingFrame, UIListLayout)
		local column = Instance.new("ScrollingFrame")
		column.Name = name
		column.BackgroundTransparency = 1
		column.BorderSizePixel = 0
		column.Size = UDim2.fromOffset(MENU_INNER, 0)
		column.CanvasSize = UDim2.new()
		column.ScrollingDirection = Enum.ScrollingDirection.Y
		column.ScrollingEnabled = false
		column.ClipsDescendants = false
		column.ScrollBarThickness = 0
		column.ScrollBarImageColor3 = LOOK.WellEdge
		column.Selectable = false
		column.LayoutOrder = order
		column.ZIndex = 83
		column.Parent = menu
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, gap)
		list.Parent = column
		return column, list
	end
	local menuInfo, infoList = menuColumn("MenuInfo", 1, 4)
	local menuActions = menuColumn("MenuActions", 2, MENU_BUTTON_GAP)
	-- The buttons' bar takes its own width (their height never changes with it);
	-- the words' bar lies over them, so it can never re-wrap them.
	menuActions.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	local actionsClear = Instance.new("UIPadding")
	actionsClear.Parent = menuActions

	local function scaleNow(): number
		return UIKit.scaleOf(gui)
	end

	local function clearChildren(frame: Instance)
		for _, child in ipairs(frame:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	local function line(parent: Instance, order: number, text: string, size: number, colour: Color3, z: number)
		local l = Instance.new("TextLabel")
		l.Name = "Line" .. order
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0, size + 4)
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.TextWrapped = true
		-- The sheet's title in FredokaOne; its lines in the clean body face.
		l.Font = if order == 1 then LOOK.LabelFont else LOOK.BodyFont
		l.TextSize = size
		l.TextColor3 = colour
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = text
		l.LayoutOrder = order
		l.ZIndex = z
		l.Parent = parent
		return l
	end

	-- The rarity words drawn on the tooltip and the menu, so clearing a sheet
	-- forgets them (RarityFX keeps nothing for a label that has gone).
	local sheetFX: { [Instance]: { RarityFX.Handle } } = {}

	-- `gate`: the frame whose Visible pauses the rarity light (the sheet itself
	-- unless given: the menu's words sit in a column that never hides).
	local function fillLines(parent: GuiObject, title: string, lines: { InventoryModel.Line }, z: number,
		gate: GuiObject?)
		line(parent, 1, title, 15, TEXT, z)
		local handles: { RarityFX.Handle } = {}
		for i, entry in ipairs(lines) do
			local rarity = entry.rarity
			if rarity and RarityFX.style(rarity) then
				-- "Rarity:" in cream, the word in its own label beside it, so the
				-- light crosses the word and nothing else.
				local row = line(parent, i + 1, entry.key .. ":", 12, TEXT, z)
				row.AutomaticSize = Enum.AutomaticSize.None
				row.TextWrapped = false
				local word = Instance.new("TextLabel")
				word.Name = "RarityWord"
				word.BackgroundTransparency = 1
				word.Position = UDim2.fromOffset(row.TextBounds.X + 4, 0)
				word.Size = UDim2.new(0, 0, 1, 0)
				word.AutomaticSize = Enum.AutomaticSize.X
				word.Font = Enum.Font.FredokaOne
				word.TextSize = 12
				word.TextXAlignment = Enum.TextXAlignment.Left
				word.Text = entry.value
				-- One layer up, so a Secret's halo (one under the word) still
				-- clears the sheet behind it.
				word.ZIndex = z + 1
				word.Parent = row
				local wordLine = UIKit.stroke(word, LOOK.Ink, 1)
				local h = RarityFX.text(word, wordLine)
				h.gate = gate or parent
				RarityFX.setText(h, rarity, entry.colour or TEXT)
				RarityFX.setActive(h, true)
				table.insert(handles, h)
				-- The key's width is only known once it is drawn.
				row:GetPropertyChangedSignal("TextBounds"):Connect(function()
					word.Position = UDim2.fromOffset(row.TextBounds.X + 4, 0)
				end)
			else
				local l = line(parent, i + 1, entry.key .. ": " .. entry.value, 12, TEXT, z)
				local colour = entry.colour
				if colour then
					l.RichText = true
					l.Text = string.format('%s: <font color="#%s">%s</font>', entry.key, colour:ToHex(), entry.value)
				end
			end
		end
		sheetFX[parent] = handles
	end

	local function clearSheet(frame: GuiObject)
		local handles = sheetFX[frame]
		if handles then
			for _, h in ipairs(handles) do
				RarityFX.forget(h)
			end
			sheetFX[frame] = nil
		end
		clearChildren(frame)
	end

	-- Beside an anchor rect (logical units), inside the screen. `knownHeight` when
	-- the caller has it (the menu's own sum), else what the frame has drawn.
	local function placeBeside(frame: GuiObject, anchor: Rect, width: number, knownHeight: number?)
		local screen = gui.AbsoluteSize / scaleNow()
		local height = knownHeight or frame.AbsoluteSize.Y / scaleNow()
		local x = anchor.x + anchor.w + 6
		if x + width > screen.X - 8 then
			x = anchor.x - 6 - width
		end
		x = math.clamp(x, 8, math.max(8, screen.X - 8 - width))
		local y = math.clamp(anchor.y, 8, math.max(8, screen.Y - 8 - height))
		frame.Position = UDim2.fromOffset(x, y)
	end

	local tipKey: string? = nil
	local function hideTooltip()
		tipKey = nil
		tip.Visible = false
	end
	local function showTooltip(key: string, anchor: Rect)
		local text, lines = cb.describe(key)
		if not text then
			return
		end
		tipKey = key
		clearSheet(tip)
		fillLines(tip, text, lines :: { InventoryModel.Line }, 81)
		tip.Visible = true
		placeBeside(tip, anchor, TIP_W)
		task.defer(function()
			if tipKey == key then
				placeBeside(tip, anchor, TIP_W)
			end
		end)
	end

	local menuPick: ((string) -> ())? = nil
	-- The menu's HATCH holds (2026-10-09): stopped when it closes, so a hold a
	-- controller started can never finish behind a closed menu.
	local menuHolds: { () -> () } = {}
	-- The open menu's anchor and its number of buttons, for fitMenu.
	local menuAnchor: Rect? = nil
	local menuCount = 0
	local function closeMenu()
		for _, stopHold in ipairs(menuHolds) do
			stopHold()
		end
		table.clear(menuHolds)
		menuPick = nil
		menuAnchor = nil
		menu.Visible = false
		backdrop.Visible = false
		ContextActionService:UnbindAction("SeedBagMenuBack")
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(menu) then
			GuiService.SelectedObject = nil
		end
	end

	-- A column's window: scrolling, clipped and barred only while its content is
	-- taller than the window. Answers whether it scrolls.
	local function window(column: ScrollingFrame, view: number, content: number): boolean
		local scrolls = content > view + 0.5
		column.Size = UDim2.fromOffset(MENU_INNER, view)
		column.CanvasSize = UDim2.fromOffset(0, if scrolls then content else 0)
		column.ScrollingEnabled = scrolls
		column.ClipsDescendants = scrolls
		column.ScrollBarThickness = if scrolls then MENU_BAR else 0
		if not scrolls then
			column.CanvasPosition = Vector2.zero
		end
		return scrolls
	end

	-- The open menu laid out to the screen (InventoryPanel.menuFit), its words
	-- measured as drawn: on an open, and whenever they or the screen change size.
	local function fitMenu()
		local anchor = menuAnchor
		if not anchor or not menu.Visible then
			return
		end
		local k = scaleNow()
		local words = infoList.AbsoluteContentSize.Y / k
		local fit = InventoryPanel.menuFit(gui.AbsoluteSize / k, words, menuCount)
		menuLayout.FillDirection = if fit.side then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
		menuLayout.Padding = UDim.new(0, if fit.side then MENU_SIDE_GAP else MENU_ROW_GAP)
		window(menuInfo, fit.infoView, words)
		local scrolls = window(menuActions, fit.actionsView, fit.actions)
		actionsClear.PaddingLeft = UDim.new(0, if scrolls then MENU_CLEAR else 0)
		actionsClear.PaddingRight = UDim.new(0, if scrolls then MENU_CLEAR else 0)
		menuActions.Visible = menuCount > 0
		menu.Size = UDim2.fromOffset(fit.width, fit.height)
		placeBeside(menu, anchor, fit.width, fit.height)
	end
	infoList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitMenu)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitMenu)

	local function openMenu(anchor: Rect, spec: MenuSpec, onPick: (string) -> ())
		hideTooltip()
		clearSheet(menuInfo)
		clearChildren(menuActions)
		menuInfo.CanvasPosition = Vector2.zero
		menuActions.CanvasPosition = Vector2.zero
		fillLines(menuInfo, spec.title, spec.lines, 83, menu)
		local first: GuiObject? = nil
		for i, action in ipairs(spec.actions) do
			-- MenuKit's button, in the face its action means (the global UI
			-- pass): green to put something to use, blue to take a shortcut
			-- off, quiet for a favourite, red to remove a placed trap.
			local mb = MenuKit.button(menuActions, "Action" .. action.id, 84, action.label, 15)
			mb.style(MENU_FACE[action.id] or "go")
			buttonIcon(mb, action.icon)
			local b = mb.hit
			b.Size = UDim2.new(1, 0, 0, MENU_BUTTON_H)
			b.LayoutOrder = i
			UIKit.clicks(b)
			first = first or b
			local id = action.id
			local function chosen()
				local pick = menuPick
				closeMenu()
				if pick then
					pick(id)
				end
			end
			local hold = action.hold
			if hold and hold > 0 then
				-- HATCH (2026-10-09): held to the end, never a tap.
				table.insert(menuHolds, holdButton(mb, hold, chosen))
			else
				-- A tap, never the end of a scroll: on a short screen the buttons scroll.
				MenuKit.tap(b, menuActions, function()
					chosen()
				end)
			end
		end
		menuPick = onPick
		menuAnchor = anchor
		menuCount = #spec.actions
		backdrop.Visible = true
		menu.Visible = true
		fitMenu()
		task.defer(fitMenu)
		-- B closes the menu before it closes the Bag (priority over the panel's).
		ContextActionService:BindActionAtPriority("SeedBagMenuBack", function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				closeMenu()
			end
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.ButtonB)
		if first and UserInputService.GamepadEnabled
			and UserInputService:GetLastInputType().Name:find("Gamepad") then
			GuiService.SelectedObject = first
		end
	end
	backdrop.Activated:Connect(closeMenu)

	--==========================================================================
	-- THE TILES, POOLED BY GROUP
	--==========================================================================
	type Live = { tile: InventoryTile.Tile, key: string, art: InventoryModel.Art?, artKey: string }
	local live: { [string]: Live } = {}
	local spare: { InventoryTile.Tile } = {}
	local byButton: { [GuiObject]: Live } = {}
	local compact = false
	local lastHandled = 0
	-- The Bag is open: a rarity's light moves only then (and only in view).
	local isOpen = false

	local function anchorOf(entry: Live): Rect
		return rectOf(entry.tile.button, scaleNow())
	end

	-- A tile's picture, built only once the tile has been on screen; and its
	-- rarity light, moving only while it is in view with the Bag open.
	local function buildVisible()
		local at, size = grid.AbsolutePosition, grid.AbsoluteSize
		for _, entry in pairs(live) do
			local art = entry.art
			local p, s = entry.tile.holder.AbsolutePosition, entry.tile.holder.AbsoluteSize
			local onScreen = entry.tile.holder.Visible
				and p.X + s.X >= at.X - 40 and p.X <= at.X + size.X + 40
				and p.Y + s.Y >= at.Y - 40 and p.Y <= at.Y + size.Y + 40
			if art and entry.tile.shownKey ~= entry.artKey and onScreen then
				local builder, kind = ItemArt.builder(entry.artKey, art)
				entry.tile.preview.setModel(entry.artKey, builder, kind)
				entry.tile.shownKey = entry.artKey
			end
			-- Strictly in the grid's view for the light (no 40-px margin).
			local inView = onScreen and p.X + s.X > at.X and p.X < at.X + size.X
				and p.Y + s.Y > at.Y and p.Y < at.Y + size.Y
			InventoryTile.animate(entry.tile, isOpen and inView)
		end
	end
	-- Asked again whenever what is on screen can have changed: a scroll, the
	-- grid laid out anew (tiles placed a frame after a paint), the grid resized.
	grid:GetPropertyChangedSignal("CanvasPosition"):Connect(buildVisible)
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		task.defer(buildVisible)
	end)
	grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(buildVisible)
	end)

	--==========================================================================
	-- ONE PRESS, ONE ACTION
	--
	-- A click can arrive as InputBegan, Activated, InputEnded (measured in Studio
	-- Play, 2026-10-03) or with Activated after InputEnded: either way the press
	-- is answered once. Activated during a press answers it if the press is still
	-- a press; InputEnded answers one nobody answered; Activated with no press at
	-- all is a controller's A (or Enter), unless a press just ended.
	--==========================================================================
	local function wire(tile: InventoryTile.Tile)
		local button = tile.button
		local press: PressGesture.Press? = nil
		local handled = false
		local function keyOf(): string?
			local entry = byButton[button]
			return if entry then entry.key else nil
		end
		button.InputBegan:Connect(function(input: InputObject)
			local kind = input.UserInputType
			local by = if kind == Enum.UserInputType.Touch then "touch"
				elseif kind == Enum.UserInputType.MouseButton1 then "mouse"
				else nil
			if not by then
				return
			end
			local key = keyOf()
			if not key then
				return
			end
			local p = PressGesture.begin(by, Vector2.new(input.Position.X, input.Position.Y), grid.CanvasPosition,
				os.clock(), by == "mouse" and cb.canDrag(key))
			press = p
			handled = false
			if by == "touch" then
				task.delay(PressGesture.LongPress, function()
					if press == p and not handled
						and PressGesture.step(p, nil, grid.CanvasPosition, os.clock()) == "long" then
						handled = true
						local entry = byButton[button]
						if entry and entry.key == key then
							cb.menu(key, anchorOf(entry))
						end
					end
				end)
			end
		end)
		button.InputChanged:Connect(function(input: InputObject)
			local p = press
			if not p or handled then
				return
			end
			local kind = input.UserInputType
			if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseMovement then
				return
			end
			local was = p.state
			local now = PressGesture.step(p, Vector2.new(input.Position.X, input.Position.Y), grid.CanvasPosition,
				os.clock())
			if now == "drag" and was ~= "drag" then
				local key = keyOf()
				handled = true
				if key then
					hideTooltip()
					cb.dragBegin(key, input)
				end
			end
		end)
		button.InputEnded:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local p = press
			press = nil
			if not p then
				return
			end
			lastHandled = os.clock()
			if handled then
				return
			end
			handled = true
			local result = PressGesture.release(p, Vector2.new(input.Position.X, input.Position.Y),
				grid.CanvasPosition, os.clock())
			local key = keyOf()
			if result == "tap" and key then
				cb.activate(key, p.by)
			end
		end)
		button.Activated:Connect(function()
			local key = keyOf()
			local p = press
			if p then
				-- Mid-press: answered here only while it is still a plain press.
				if handled or PressGesture.step(p, nil, grid.CanvasPosition, os.clock()) ~= "pressing" then
					return
				end
				handled = true
				if key then
					cb.activate(key, p.by)
				end
				return
			end
			-- No press: a controller's A, unless a press has only just ended.
			if os.clock() - lastHandled < 0.15 then
				return
			end
			if key then
				cb.activate(key, "pad")
			end
		end)
		button.MouseButton2Click:Connect(function()
			local entry = byButton[button]
			if entry then
				cb.menu(entry.key, anchorOf(entry))
			end
		end)
		button.MouseEnter:Connect(function()
			local entry = byButton[button]
			if entry and not menu.Visible and not UserInputService.TouchEnabled then
				showTooltip(entry.key, anchorOf(entry))
			end
		end)
		button.MouseLeave:Connect(function()
			local entry = byButton[button]
			if entry and tipKey == entry.key then
				hideTooltip()
			end
		end)
	end

	local function acquire(): InventoryTile.Tile
		local tile = table.remove(spare)
		if tile then
			tile.holder.Visible = true
			-- Rebound to another group: dark until buildVisible finds it in view.
			InventoryTile.animate(tile, false)
			return tile
		end
		local made = InventoryTile.build(grid, T, 5)
		InventoryTile.shape(made, compact)
		wire(made)
		return made
	end

	--==========================================================================
	-- PAINT
	--==========================================================================
	local sayUntil = 0
	local footerText, footerColour = "", T.CountLoading
	local function showFooter()
		if os.clock() >= sayUntil then
			footer.Text = footerText
			footer.TextColor3 = onLight(footerColour)
		end
	end

	local CAT_ON = ColorSequence.new(LOOK.CatOnTop, LOOK.CatOnBottom)
	local CAT_OFF = ColorSequence.new(LOOK.CatTop, LOOK.CatBottom)
	local function paintCategories(counts: { [string]: number })
		for id, ui in pairs(catButtons) do
			local on = state.category == id
			ui.tint.Color = if on then CAT_ON else CAT_OFF
			ui.edge.Color = if on then LOOK.CatOnEdge else LOOK.CatEdge
			ui.label.TextColor3 = if on then LOOK.CatTextOn else LOOK.CatText
			ui.mark.Visible = on
			local n = counts[id] or 0
			ui.count.Text = if id == "tickets" then "x" .. tostring(n) else tostring(n)
		end
		-- A count's chip resizes a frame later; the words fit round it then.
		task.defer(fitLabels)
		filterHeart.paint(if state.favouritesOnly then InventoryTile.HeartColour else MUTED,
			if state.favouritesOnly then 0 else 0.35)
		heartEdge.Color = if state.favouritesOnly then InventoryTile.HeartColour else LOOK.WellEdge
	end

	local function paint(view: View)
		if view.compact ~= compact then
			compact = view.compact
			for _, entry in pairs(live) do
				InventoryTile.shape(entry.tile, compact)
			end
			for _, tile in ipairs(spare) do
				InventoryTile.shape(tile, compact)
			end
		end
		local seen: { [string]: boolean } = {}
		for index, item in ipairs(view.entries) do
			seen[item.key] = true
			local entry = live[item.key]
			if not entry then
				local tile = acquire()
				entry = { tile = tile, key = item.key, art = item.art, artKey = item.artKey }
				live[item.key] = entry
				byButton[tile.button] = entry
			end
			local e = entry :: Live
			e.art = item.art
			e.artKey = item.artKey
			e.tile.holder.LayoutOrder = index
			e.tile.holder.Name = "Tile" .. index
			InventoryTile.paint(e.tile, T, item.paint)
		end
		for key, entry in pairs(live) do
			if not seen[key] then
				live[key] = nil
				byButton[entry.tile.button] = nil
				entry.tile.holder.Visible = false
				entry.tile.pop.reset()
				InventoryTile.animate(entry.tile, false)
				table.insert(spare, entry.tile)
				if tipKey == key then
					hideTooltip()
				end
			end
		end
		local first = view.entries[1]
		padFirst.Value = if first and live[first.key] then live[first.key].tile.button
			else catButtons[state.category].button
		local empty = view.empty
		emptyLabel.Visible = empty ~= nil
		if empty then
			emptyLabel.Text = empty
		end
		footerText, footerColour = view.footer, view.footerColour
		showFooter()
		local fill = view.footerFill
		barFill.Visible = fill ~= nil
		barFill.Size = UDim2.fromScale(math.clamp(fill or 0, 0, 1), 1)
		barFill.BackgroundColor3 = view.footerColour
		-- HATCH ALL, with the count of READY pods (2026-10-09).
		local readyPods = view.readyPods or 0
		local showAll = readyPods > 0
		if hatchAll.hit.Visible ~= showAll then
			if not showAll then
				stopHatchAll()
			end
			hatchAll.hit.Visible = showAll
			gridPad.PaddingBottom = UDim.new(0, gridPad.PaddingTop.Offset + (if showAll then HATCH_ALL_ROOM else 0))
		end
		if showAll then
			hatchAll.set(string.format("%s (%d)", BAG.Words.HatchAll, readyPods))
		end
		paintCategories(view.counts)
		task.defer(buildVisible)
	end

	--==========================================================================
	-- LAYOUT: HudLayout.bag's answer, applied
	--==========================================================================
	local sideways: boolean? = nil
	local function layout(bag: HudLayout.Bag, titleWidth: number)
		local titlePad = modal.title.Parent and modal.title.Parent:FindFirstChildOfClass("UIPadding")
		local padLeft = if titlePad then titlePad.PaddingLeft.Offset else 0
		local padRight = if titlePad then titlePad.PaddingRight.Offset else 0
		local shellW = bag.panel.w / bag.scale - RAIL.OutlineThickness * 2
		-- The sprout stands before the title's words, so the title is that wide.
		titleWidth += TITLE_ICON + TITLE_ICON_GAP
		local box, heart = HudLayout.bagSearch(bag, shellW, titleWidth, padLeft, padRight)
		--======================================================================
		-- THE RIM'S LIFT, TAKEN BACK (2026-10-04)
		--
		-- HudLayout's numbers are in a shell that starts at the panel's top;
		-- the studded rim's shell starts `lift` lower (UIKit.modal), so every
		-- y here gives it back and the search, the heart and the body keep
		-- exactly the rects they had. A search on the title's row stays on
		-- the rim, clear of its top edge.
		--======================================================================
		local lift = modal.lift or 0
		local boxY = if bag.compactHeader then math.max(box.y - lift, 4) else box.y - lift
		local heartY = boxY + (heart.y - box.y)
		search.Position = UDim2.fromOffset(box.x, boxY)
		search.Size = UDim2.fromOffset(box.w, box.h)
		search.Visible = box.w >= 60
		glass.Position = UDim2.fromOffset(box.x + 10, boxY + box.h / 2)
		glass.Visible = search.Visible
		heartButton.Position = UDim2.fromOffset(heart.x, heartY)
		heartButton.Size = UDim2.fromOffset(heart.w, heart.h)
		local B = HudLayout.Config.Bag
		body.Position = UDim2.fromOffset(12, (if bag.compactHeader then B.BodyTopCompact else B.BodyTop) - lift)
		body.Size = UDim2.new(1, -24, 1, -((if bag.compactHeader then B.BodyTrimCompact else B.BodyTrim) - lift))
		column.Position = UDim2.fromOffset(bag.column.x, bag.column.y)
		column.Size = UDim2.fromOffset(bag.column.w, bag.column.h)
		columnLayout.Padding = UDim.new(0, bag.catGap)
		-- A desktop's column has room for the icons; a phone's keeps its words.
		local icons = bag.column.w >= CAT_ICON_MIN_COLUMN
		-- The widest icon in the column sets where every label starts (a drawn
		-- icon is CAT_ICON, an uploaded picture BagLook.IconImageSize).
		local iconW = 0
		for _, ui in pairs(catButtons) do
			iconW = math.max(iconW, ui.icon.Size.X.Offset)
		end
		labelX = if icons then 9 + iconW + 5 else 8
		for _, ui in pairs(catButtons) do
			ui.button.Size = UDim2.new(1, 0, 0, bag.catH)
			ui.icon.Visible = icons
			ui.label.Position = UDim2.fromOffset(labelX, 0)
		end
		fitLabels()
		grid.Position = UDim2.fromOffset(bag.grid.x, bag.grid.y)
		grid.Size = UDim2.fromOffset(bag.grid.w, bag.grid.h)
		emptyLabel.Position = UDim2.fromOffset(bag.grid.x + bag.grid.w / 2, bag.grid.y + bag.grid.h * 0.42)
		emptyLabel.Size = UDim2.fromOffset(math.max(60, bag.grid.w - 30), 50)
		-- The footer: the sprout, the words, and the bar after them (placeBar).
		local midY = bag.footer.y + bag.footer.h / 2
		footerSprout.Position = UDim2.fromOffset(bag.footer.x + 2, midY)
		local textX = bag.footer.x + 2 + 15 + 5
		footer.Position = UDim2.fromOffset(textX, bag.footer.y)
		footer.Size = UDim2.fromOffset(bag.footer.x + bag.footer.w - textX - 2, bag.footer.h)
		barTrack.Size = UDim2.fromOffset(LOOK.BarWidth, LOOK.BarHeight)
		placeBar()
		gridPad.PaddingLeft = UDim.new(0, bag.pad)
		gridPad.PaddingRight = UDim.new(0, bag.pad)
		gridPad.PaddingTop = UDim.new(0, bag.pad)
		gridPad.PaddingBottom = UDim.new(0, bag.pad + (if hatchAll.hit.Visible then HATCH_ALL_ROOM else 0))
		hatchAll.hit.Position = UDim2.fromOffset(bag.grid.x + bag.grid.w - 8, bag.grid.y + bag.grid.h - 6)
		gridLayout.CellSize = UDim2.fromOffset(bag.tile.X, bag.tile.Y)
		gridLayout.CellPadding = UDim2.fromOffset(bag.gap, bag.gap)
		gridLayout.FillDirectionMaxCells = if bag.horizontal then bag.rows else 0
		if sideways ~= bag.horizontal then
			sideways = bag.horizontal
			grid.CanvasPosition = Vector2.zero
			grid.ScrollingDirection = if bag.horizontal then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y
			grid.AutomaticCanvasSize = if bag.horizontal then Enum.AutomaticSize.X else Enum.AutomaticSize.Y
			gridLayout.FillDirection = if bag.horizontal then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal
			gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			gridLayout.VerticalAlignment = if bag.horizontal then Enum.VerticalAlignment.Center
				else Enum.VerticalAlignment.Top
		end
		task.defer(buildVisible)
	end

	--==========================================================================
	-- THE TOP BAR'S TWO CONTROLS
	--==========================================================================
	search:GetPropertyChangedSignal("Text"):Connect(function()
		if state.search ~= search.Text then
			state.search = search.Text
			grid.CanvasPosition = Vector2.zero
			cb.changed()
		end
	end)
	heartButton.Activated:Connect(function()
		state.favouritesOnly = not state.favouritesOnly
		grid.CanvasPosition = Vector2.zero
		cb.changed()
	end)

	--==========================================================================
	-- LB / RB STEP THE CATEGORIES AND RT OPENS A TILE'S MENU, WHILE OPEN
	--==========================================================================
	local function setOpen(open: boolean)
		if open then
			ContextActionService:BindActionAtPriority("SeedBagPad", function(_, inputState, input)
				if inputState ~= Enum.UserInputState.Begin then
					return Enum.ContextActionResult.Pass
				end
				if input.KeyCode == Enum.KeyCode.ButtonR2 then
					local selected = GuiService.SelectedObject
					local entry = if selected then byButton[selected] else nil
					if entry then
						cb.menu(entry.key, anchorOf(entry))
						return Enum.ContextActionResult.Sink
					end
					return Enum.ContextActionResult.Pass
				end
				local list = InventoryModel.Categories
				local at = 1
				for i, category in ipairs(list) do
					if category.id == state.category then
						at = i
					end
				end
				local step = if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1
				state.category = list[(at - 1 + step) % #list + 1].id
				grid.CanvasPosition = Vector2.zero
				cb.changed()
				return Enum.ContextActionResult.Sink
			end, false, 2600, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonR2)
		else
			ContextActionService:UnbindAction("SeedBagPad")
			-- A HATCH ALL held as the Bag shuts goes nowhere (2026-10-09).
			stopHatchAll()
		end
		-- Closed, every tile's light stops now; open, buildVisible starts the
		-- ones in view.
		isOpen = open
		if open then
			task.defer(buildVisible)
		else
			for _, entry in pairs(live) do
				InventoryTile.animate(entry.tile, false)
			end
		end
	end

	local panel: Panel = {
		state = state,
		paint = paint,
		layout = layout,
		contains = function(pt: Vector2): boolean
			return modal.group.Visible and modal.dimmer.Visible and inside(pt, modal.group)
		end,
		keyAt = function(pt: Vector2): string?
			for key, entry in pairs(live) do
				if entry.tile.holder.Visible and inside(pt, entry.tile.button) and inside(pt, grid) then
					return key
				end
			end
			return nil
		end,
		tileButton = function(key: string): GuiObject?
			local entry = live[key]
			return if entry then entry.tile.button else nil
		end,
		openMenu = openMenu,
		closeMenu = closeMenu,
		menuOpen = function(): boolean
			return menu.Visible
		end,
		hideTooltip = hideTooltip,
		say = function(text: string, seconds: number)
			sayUntil = os.clock() + seconds
			footer.Text = text
			footer.TextColor3 = onLight(T.NumeralLit)
			task.delay(seconds + 0.05, showFooter)
		end,
		dim = function(on: boolean)
			dimSheet.Visible = on
		end,
		reset = function()
			closeMenu()
			hideTooltip()
			search:ReleaseFocus()
			if search.Text ~= "" then
				search.Text = ""
			end
			for _, entry in pairs(live) do
				entry.tile.pop.reset()
			end
			dimSheet.Visible = false
		end,
		setOpen = setOpen,
		grid = grid,
	}
	if player then
		player.CharacterRemoving:Connect(function()
			closeMenu()
			hideTooltip()
		end)
	end
	return panel
end

return InventoryPanel
