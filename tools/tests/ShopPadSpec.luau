--!nocheck
--==============================================================================
-- Steal a Seed :: ShopPadSpec (2026-10-13, the owner's backlog item 2)
--
-- THE SHOP ON A CONTROLLER: every button reachable in reading order, the
-- page following the selection, the banner's sheets holding it, B closing a
-- sheet before the Shop. Real D-pad presses cannot be made in Studio, so the
-- graph the D-pad walks is built and walked here; Michael confirms on console.
--
--   the graph     PadGraph's rows and links, on numbers: reading order, the
--                 nearest stop below and above, edges that hold, every stop
--                 reached from the first
--   on a page     PadGraph.wire on real buttons laid out like the Shop's -- a
--                 header, then a scrolling page holding the banner's ODDS /
--                 BUY / GIFT and a grid of cards (a face and a BUY each), the
--                 page scrolled so cards stand above the window: walked from
--                 the banner's ODDS through NextSelection*, every button found,
--                 none left, nothing pointing anywhere else
--   the scroll    PadGraph.scrollInto brings a card below the window, then one
--                 above it, inside with the margin
--   the wiring    ShopUI writes it on open, on change and on every selection
--                 move, starts on the banner, LB / RB stop at the banner; the
--                 banner's sheets take the selection, hold it, B shuts the
--                 sheet alone and hands it back to its opener
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local PadGraph = require(Shared:WaitForChild("PadGraph"))

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local layer = Instance.new("ScreenGui")
layer.Name = "ZZShopPadSpec"
layer.Archivable = false

local ok, err = pcall(function()
	--==========================================================================
	say("-- the graph --")
	--==========================================================================
	local function stop(id, x, y)
		return { id = id, x = x, y = y }
	end
	local rows = PadGraph.rows({ stop("b", 200, 52), stop("a", 100, 50), stop("c", 150, 120), stop("d", 50, 118) })
	check(#rows == 2 and rows[1][1].id == "a" and rows[1][2].id == "b" and rows[2][1].id == "d" and rows[2][2].id == "c",
		"rows: centres within a few pixels are one row, top to bottom, each left to right")
	local links = PadGraph.links({ { stop("h1", 400, 0), stop("h2", 500, 0) }, {}, { stop("o", 480, 50) },
		{ stop("p", 100, 100), stop("q", 300, 100), stop("r", 500, 100) } })
	check(links.p.left == "p" and links.p.right == "q" and links.r.right == "r" and links.q.left == "p",
		"left and right walk the row; at either end the press holds")
	check(links.o.up == "h2" and links.o.down == "r" and links.q.up == "o" and links.h1.down == "o",
		"up and down take the nearest stop in x in the next row, and an empty row is passed over")
	check(links.h1.up == "h1" and links.p.down == "p", "past the first and the last row, the press holds")
	local tie = PadGraph.links({ { stop("t", 200, 0) }, { stop("l", 100, 50), stop("m", 300, 50) } })
	check(tie.t.down == "l", "a tie goes to the left one")

	-- The Shop's page in numbers: header, banner, two rows of three cards.
	local page = {
		stop("hdrOdds", 470, 10), stop("close", 600, 10),
		stop("odds", 560, 60),
		stop("buy1", 90, 200), stop("buy3", 240, 200), stop("buy10", 390, 200), stop("buy50", 540, 200),
		stop("gift1", 90, 236), stop("gift3", 240, 236), stop("gift10", 390, 236), stop("gift50", 540, 236),
	}
	for r = 1, 2 do
		for c = 1, 3 do
			table.insert(page, stop(string.format("face%d%d", r, c), 100 + (c - 1) * 200, 300 + (r - 1) * 140))
			table.insert(page, stop(string.format("cbuy%d%d", r, c), 100 + (c - 1) * 200, 340 + (r - 1) * 140))
		end
	end
	local shopLinks = PadGraph.links(PadGraph.rows(page))
	local reached = PadGraph.reach(shopLinks, "odds")
	local missing = {}
	for _, s in ipairs(page) do
		if not reached[s.id] then
			table.insert(missing, s.id)
		end
	end
	check(#missing == 0, string.format("every one of the %d stops is reached from the banner's ODDS", #page),
		table.concat(missing, ", "))
	check(shopLinks.odds.down == "buy50" and shopLinks.buy1.down == "gift1" and shopLinks.gift1.down == "face11"
			and shopLinks.face11.down == "cbuy11" and shopLinks.cbuy11.down == "face21" and shopLinks.cbuy23.down == "cbuy23",
		"down: ODDS to the bundles, a BUY to its GIFT, a GIFT to the first cards, a card's face to its BUY, a BUY to "
			.. "the card under it; the last row holds")
	check(shopLinks.face21.up == "cbuy11" and shopLinks.face11.up == "gift1" and shopLinks.buy50.up == "odds"
			and shopLinks.odds.up == "close", "and up walks the same way back, to the header")

	--==========================================================================
	say("\n-- on a page --")
	--==========================================================================
	layer.Parent = StarterGui
	local function button(parent, name, pos, size)
		local b = Instance.new("TextButton")
		b.Name = name
		b.Text = ""
		b.Position = pos
		b.Size = size
		b.Parent = parent
		return b
	end
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.fromOffset(640, 50)
	header.Parent = layer
	local hdrOdds = button(header, "RewardsAndOdds", UDim2.fromOffset(420, 4), UDim2.fromOffset(150, 40))
	local close = button(header, "Close", UDim2.fromOffset(590, 4), UDim2.fromOffset(40, 40))
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Products"
	scroller.Position = UDim2.fromOffset(0, 60)
	scroller.Size = UDim2.fromOffset(640, 300)
	scroller.CanvasSize = UDim2.fromOffset(0, 1100)
	scroller.Selectable = false
	scroller.Parent = layer
	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.Size = UDim2.fromOffset(640, 260)
	banner.Parent = scroller
	local bodds = button(banner, "Odds", UDim2.fromOffset(520, 10), UDim2.fromOffset(96, 38))
	local buys, gifts = {}, {}
	for i = 1, 4 do
		table.insert(buys, button(banner, "Buy" .. i, UDim2.fromOffset(20 + (i - 1) * 156, 150), UDim2.fromOffset(132, 40)))
		table.insert(gifts, button(banner, "Gift" .. i, UDim2.fromOffset(34 + (i - 1) * 156, 210), UDim2.fromOffset(104, 26)))
	end
	local faces, cbuys = {}, {}
	for r = 1, 4 do
		for c = 1, 3 do
			local face = button(scroller, string.format("Face%d%d", r, c),
				UDim2.fromOffset(10 + (c - 1) * 210, 280 + (r - 1) * 130), UDim2.fromOffset(200, 120))
			table.insert(faces, face)
			table.insert(cbuys, button(face, "Buy", UDim2.fromOffset(8, 70), UDim2.fromOffset(184, 44)))
		end
	end
	-- Scrolled so the banner and a row of cards stand ABOVE the window, higher
	-- on the screen than the header.
	scroller.CanvasPosition = Vector2.new(0, 420)
	local head = { hdrOdds, close }
	local pageControls = { bodds }
	for _, b in ipairs(buys) do
		table.insert(pageControls, b)
	end
	for _, b in ipairs(gifts) do
		table.insert(pageControls, b)
	end
	for i = 1, #faces do
		table.insert(pageControls, faces[i])
		table.insert(pageControls, cbuys[i])
	end
	local sized = layer.AbsoluteSize.X > 0 and faces[1].AbsoluteSize.X > 0
	if not sized then
		check(false, "Studio gave the throwaway gui no size in Edit: the page walk is the Play check's")
	else
		check(bodds.AbsolutePosition.Y < close.AbsolutePosition.Y,
			"the page is scrolled: the banner's ODDS stands higher on the screen than the header's close")
		local wired = PadGraph.wire({ head, pageControls })
		local all = {}
		for _, c in ipairs(head) do
			all[c] = true
		end
		for _, c in ipairs(pageControls) do
			all[c] = true
		end
		-- Walk the written links, as the D-pad would.
		local seen, queue, strays = { [bodds] = true }, { bodds }, {}
		local i = 1
		while i <= #queue do
			local c = queue[i]
			i += 1
			for _, nextOne in ipairs({ c.NextSelectionUp, c.NextSelectionDown, c.NextSelectionLeft, c.NextSelectionRight }) do
				if nextOne and not all[nextOne] then
					table.insert(strays, c.Name .. " -> " .. nextOne:GetFullName())
				elseif nextOne and not seen[nextOne] then
					seen[nextOne] = true
					table.insert(queue, nextOne)
				end
			end
		end
		local left = {}
		for c in pairs(all) do
			if not seen[c] then
				table.insert(left, c.Name)
			end
		end
		check(#left == 0 and #strays == 0, string.format("walked from the banner's ODDS through NextSelection*: all %d "
			.. "buttons reached, and no link points anywhere else", #queue), table.concat(left, ", ") .. " / "
			.. table.concat(strays, ", "))
		check(#wired[1] == 2 and wired[1][1].id == hdrOdds and wired[2][1].id == bodds and bodds.NextSelectionUp == close,
			"the header is the first row even with the page scrolled up past it, and ODDS goes up to the header")
		check(gifts[1].NextSelectionDown == faces[1] and faces[1].NextSelectionDown == cbuys[1]
				and cbuys[1].NextSelectionDown == faces[4] and faces[2].NextSelectionLeft == faces[1]
				and cbuys[2].NextSelectionLeft == cbuys[1] and cbuys[12].NextSelectionDown == cbuys[12],
			"down from GIFT to the first card, a face to its own BUY (a desktop tile's stands under it), a BUY to the "
				.. "card below; across, card to card; the last holds")

		--======================================================================
		say("\n-- the scroll --")
		--======================================================================
		local function insideWindow(object, margin)
			local m = margin or 11
			local top = scroller.AbsolutePosition.Y
			local bottom = top + scroller.AbsoluteWindowSize.Y
			return object.AbsolutePosition.Y >= top + m and object.AbsolutePosition.Y + object.AbsoluteSize.Y <= bottom - m
		end
		scroller.CanvasPosition = Vector2.new(0, 0)
		local low = faces[10]
		local before = insideWindow(low)
		local moved = PadGraph.scrollInto(scroller, low, 12)
		check(not before and moved and insideWindow(low),
			"a card below the window: the page scrolls down until it stands inside, the margin clear",
			tostring(scroller.CanvasPosition))
		local again = PadGraph.scrollInto(scroller, low, 12)
		check(not again, "and asked again for a card already inside, nothing moves")
		local high = bodds
		local beforeHigh = insideWindow(high, 0)
		PadGraph.scrollInto(scroller, high, 12)
		-- The banner's ODDS is 10 from the page's top: the canvas stops at 0, short of the margin.
		check(not beforeHigh and insideWindow(high, 0) and scroller.CanvasPosition.Y == 0,
			"a control above the window: the page scrolls back up to it, never past the page's top",
			tostring(scroller.CanvasPosition))
	end

	--==========================================================================
	say("\n-- the wiring --")
	--==========================================================================
	local shop = StarterPlayer.StarterPlayerScripts:FindFirstChild("ShopUI")
	local shopSrc = shop and shop.Source or ""
	local bannerSrc = Shared:WaitForChild("MysteryShopBanner").Source
	local focusSrc = StarterPlayer.StarterPlayerScripts:FindFirstChild("PadFocus").Source
	local kitSrc = Shared:WaitForChild("MenuKit").Source
	check(has(shopSrc, "PadGraph.wire(padGroups())") and has(shopSrc, "return { head, page }")
			and has(shopSrc, "add(page, card.face)") and has(shopSrc, "add(page, card.buy.hit)")
			and has(shopSrc, "for _, object in ipairs(podBanner.padControls()) do"),
		"ShopUI wires two groups -- the header, then the page: the banner's controls and every shown card's face and BUY")
	check(has(shopSrc, 'GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()')
			and has(shopSrc, "PadGraph.scrollInto(grid, selected, 12)") and has(shopSrc, "if want then\n\t\t-- A controller's way through it, once it has laid out.")
			and select(2, string.gsub(shopSrc, "task.defer%(function%(%)\n%s*relink%(%)\n%s*end%)", "")) >= 4,
		"and writes it again on every selection move inside the Shop (the page scrolling to it), on open, and when "
			.. "the page or the details change")
	check(has(shopSrc, "padFirst.Value = if lead then lead elseif top then top.face else nil")
			and has(shopSrc, "local lead = podBanner.padControls()[1]"),
		"a controller starts on the banner's first control (PadFirst), not past it on the first card")
	check(has(shopSrc, "{ frame = podBanner.frame, first = function(): GuiObject?") and has(shopSrc,
			"if detailKey ~= nil or podBanner.sheetOpen() then"),
		"LB / RB stop at the banner too, and never move the page under an open sheet")
	check(has(bannerSrc, "back.Selectable = false") and has(bannerSrc, "panel.SelectionGroup = true")
			and select(2, string.gsub(bannerSrc, "panel%.SelectionBehavior%a+ = Enum%.SelectionBehavior%.Stop", "")) == 4
			and has(bannerSrc, "list.Selectable = false"),
		"a banner sheet's dimmed backdrop is never a stop, the sheet holds the selection at every edge, its names' "
			.. "list is no stop either")
	check(has(bannerSrc, "MenuKit.bindBack(MysteryShopBanner.BackAction, function()")
			and has(bannerSrc, "MenuKit.unbind(MysteryShopBanner.BackAction)")
			and has(bannerSrc, "if shopOpen and from and from.Visible and MenuKit.onPad() then\n\t\t\t\tGuiService.SelectedObject = from")
			and has(bannerSrc, "holdPad(oddsBack, oddsButton.hit, function(): GuiObject?")
			and has(bannerSrc, "holdPad(giftBack, from, function(): GuiObject?")
			and has(bannerSrc, "openGift(giftItem, giftButton.hit)"),
		"a sheet takes B and the selection when it comes up, and however it shuts gives B back and the selection to "
			.. "the button that opened it (not when the whole Shop shut it)")
	check(has(kitSrc, "end, false, 3000, Enum.KeyCode.ButtonB)") and has(focusSrc, "local BACK_PRIORITY = 2500"),
		"the sheet's B (3000) answers before PadFocus's (2500), which would close the whole Shop")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

layer:Destroy()

say(string.format("\nShopPadSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
