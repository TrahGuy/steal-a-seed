--!strict
--==============================================================================
-- Steal a Seed :: ShopCatalog (2026-10-03, the compact Shop)
--
-- WHAT THE SHOP SELLS, AS ITS CATEGORIES AND CARDS. Pure: read off the two
-- tables the server grants from -- GameConfig.Store (its shelves, passes and
-- products) and WheelData.Products (the Spin Ticket packs) -- and nothing else,
-- so a card can never advertise something StoreService or WheelService does not
-- know how to give, and CompactMenusSpec can check every id is carried across.
--
--   a category   one per configured shelf, in its order and under its own
--                heading ("???" stays "???", the owner's word), then Spin
--                Tickets -- shown only while the server says this player may
--                buy them (the caller passes that in)
--   a card       the product's own uploaded icon, its label, the exact amount
--                or benefit in words, and HOW it is bought:
--                  pass     a Game Pass, PromptGamePassPurchase (pass id)
--                  product  a Developer Product, PromptProductPurchase
--                  spin     a key sent to the server, which opens the prompt
--                  soon     id 0: not created yet; the button refuses
--
-- NO PRICE LIVES HERE. Robux prices are this player's, from RobuxPrice; the
-- manifest's `robux` is never read.
--
-- SPEED WEARS THE CATALOGUE'S SPEED ICON (2026-10-03, the owner's ask: one
-- speed icon everywhere): GameConfig.SourceIcons.training, the uploaded winged
-- shoe the boost row already shows -- on every Speed pack and on the category.
-- The pack's own shoe stays as the fallback until that picture has loaded.
--==============================================================================
local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local WheelData = require(Shared:WaitForChild("WheelData"))

local ShopCatalog = {}

local STORE = GameConfig.Store
local ICONS: { [string]: string } = (STORE.Icons :: any) or {}
local CARDS: { [string]: string } = (STORE.Cards :: any) or {}

ShopCatalog.SpeedIcon = GameConfig.SourceIcons.training
ShopCatalog.TicketsId = "Tickets"

export type Category = {
	id: string,
	label: string,
	icon: string,
	-- A drawn or uploaded fallback shown until `icon` loads.
	fallback: string?,
}

export type Entry = {
	key: string,
	kind: string, -- "pass" | "product" | "spin" | "soon"
	-- The id the purchase uses: a pass id, a product id, or 0.
	id: number,
	-- The label, as the shelf printed it ("+150K SPEED", "x2 MONEY", "GIANT NUBKIN").
	title: string,
	-- The pack's amount, for the amount's colour (nil: a premium item).
	amount: number?,
	-- One short line: the exact amount or the benefit.
	benefit: string,
	-- The details view's longer words.
	detail: string,
	icon: string,
	fallback: string?,
	-- A pass's 3:2 card art, for the details view.
	art: string?,
	-- A spin pack's key, which is what the server is sent.
	spinKey: string?,
	-- A pass's multiplier, for its owned check.
	multiplier: number?,
	-- The card's studded background (2026-10-04, GameConfig.BagLook.Studs): its
	-- shelf's (`studs` on GameConfig.Store.Sections), a Spin Ticket pack the
	-- premium violet, the featured pack (BagLook.StudsFeatured) the rainbow.
	studs: string?,
}

-- 150000 -> "150,000".
function ShopCatalog.group(n: number): string
	local s = tostring(math.floor(math.abs(n) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if n < 0 then "-" else "") .. out
end

local function titleCase(heading: string): string
	if heading:match("^%W+$") then
		return heading
	end
	return heading:sub(1, 1):upper() .. heading:sub(2):lower()
end

local function sectionIcon(spec: any): (string, string?)
	if spec.layout == "pass" then
		return GameConfig.Pass.BuffIcon or "", nil
	end
	local items = (STORE.Items :: any)[spec.id] or {}
	local first = items[1]
	if spec.id == "Speed" then
		return ShopCatalog.SpeedIcon, if first then ICONS[first.key] else nil
	end
	-- The shelf's second pack where it has one (the cash shelf's stack reads
	-- better small than the fan), else its first.
	local pick = items[2] or first
	return if pick then (ICONS[pick.key] or "") else (ICONS.comingSoon or ""), nil
end

function ShopCatalog.categories(spinsAllowed: boolean): { Category }
	local out: { Category } = {}
	for _, spec in ipairs(STORE.Sections) do
		local icon, fallback = sectionIcon(spec)
		table.insert(out, { id = spec.id, label = titleCase(spec.heading), icon = icon, fallback = fallback })
	end
	if spinsAllowed then
		table.insert(out, {
			id = ShopCatalog.TicketsId,
			label = "Spin Tickets",
			icon = GameConfig.BagLook.IconImages.tickets,
			fallback = nil,
		})
	end
	return out
end

local function productEntry(item: any): Entry
	local id = tonumber(item.product) or 0
	local kind = if id > 0 then "product" else "soon"
	local amount = tonumber(item.amount)
	local benefit, detail, icon, fallback = "", "", ICONS[item.key] or "", nil
	if item.kind == "speed" and amount then
		benefit = "Adds " .. ShopCatalog.group(amount) .. " Speed"
		detail = "Adds " .. ShopCatalog.group(amount)
			.. " Speed to your total at once. Speed sets how fast you run, which is how far down the road you can reach."
		icon, fallback = ShopCatalog.SpeedIcon, ICONS[item.key]
	elseif item.kind == "cash" and amount then
		benefit = "Adds $" .. ShopCatalog.group(amount) .. " cash"
		detail = "Adds $" .. ShopCatalog.group(amount) .. " cash to your balance at once."
	elseif item.kind == "pod" then
		local species = SeedData.ById and SeedData.ById[item.species]
		local size = SeedData.Tier(tonumber(item.tier)).name
		local name = if species then species.Name else tostring(item.species)
		benefit = string.format("A %s %s pod", size, name)
		detail = string.format("Exactly one %s pod, %s size -- nothing about it is rolled.", name, size)
	end
	if kind == "soon" then
		detail = if detail ~= "" then detail .. " Coming soon." else "Coming soon."
	end
	return {
		key = tostring(item.key),
		kind = kind,
		id = id,
		title = tostring(item.label),
		amount = amount,
		benefit = benefit,
		detail = detail,
		icon = icon,
		fallback = fallback,
	}
end

local function passEntry(item: any): Entry
	local id = tonumber(item.pass) or 0
	local mul = tonumber(item.multiplier) or 1
	return {
		key = tostring(item.key),
		kind = if id > 0 then "pass" else "soon",
		id = id,
		title = tostring(item.label),
		amount = nil,
		benefit = string.format("Permanent \u{00D7}%d plant income", mul),
		detail = string.format("A Game Pass: yours for good. Every grown plant in your garden earns \u{00D7}%d. "
			.. "It does not apply to sales or cash packs.", mul),
		icon = GameConfig.Pass.BuffIcon or "",
		fallback = nil,
		art = CARDS[tostring(item.key)],
		multiplier = mul,
	}
end

local function spinEntry(product: any): Entry
	local plural = if product.spins == 1 then "TICKET" else "TICKETS"
	return {
		key = product.key,
		kind = "spin",
		id = product.productId,
		title = string.format("\u{00D7}%d %s", product.spins, plural),
		amount = product.spins,
		benefit = string.format("Adds %d Spin Ticket%s", product.spins, if product.spins == 1 then "" else "s"),
		detail = string.format("%d spin%s of the Reward Wheel. Prizes are random: see REWARDS & ODDS for every "
			.. "prize's chance before you buy.", product.spins, if product.spins == 1 then "" else "s"),
		icon = "rbxassetid://" .. tostring(product.icon),
		fallback = nil,
		spinKey = product.key,
	}
end

local FEATURED: { [string]: boolean } = (GameConfig.BagLook.StudsFeatured :: any) or {}

function ShopCatalog.entries(categoryId: string): { Entry }
	if categoryId == ShopCatalog.TicketsId then
		local out: { Entry } = {}
		for _, product in ipairs(WheelData.Products) do
			local entry = spinEntry(product)
			entry.studs = if FEATURED[entry.key] then "rainbow" else "purple"
			table.insert(out, entry)
		end
		return out
	end
	for _, spec in ipairs(STORE.Sections) do
		if spec.id == categoryId then
			local items = (STORE.Items :: any)[spec.id] or {}
			local out: { Entry } = {}
			if #items == 0 then
				-- An empty shelf still says something: a plate that promises.
				table.insert(out, {
					key = "comingSoon", kind = "soon", id = 0, title = "COMING SOON", amount = nil,
					benefit = "Coming soon", detail = "Coming soon.", icon = ICONS.comingSoon or "",
					studs = spec.studs,
				})
			end
			for _, item in ipairs(items) do
				local entry = if spec.layout == "pass" then passEntry(item) else productEntry(item)
				entry.studs = if FEATURED[entry.key] then "rainbow" else spec.studs
				table.insert(out, entry)
			end
			return out
		end
	end
	return {}
end

return ShopCatalog
