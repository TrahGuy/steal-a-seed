--!strict
-- Steal a Seed :: RobuxPrice
--
-- What a pass or a developer product costs THE PLAYER LOOKING AT IT, asked of
-- Roblox while the game runs -- the number the purchase prompt will quote.
--
--==============================================================================
-- WHY A TILE CANNOT PRINT THE MANIFEST'S PRICE
--
-- Roblox prices passes and developer products by region. The x2 MONEY pass
-- (1975418369) lists at 199 and was offered to the owner's own account at 79;
-- the shop tile printed the manifest's copy of the owner's number, so a tester
-- read 79 on the tile and 199 in his purchase prompt. No number in a data file
-- can be right for every player. Roblox's documented answer (Creator Docs,
-- "Regional pricing"; the regional pricing announcement: "called from the client
-- for every user") is to ask at run time: MarketplaceService:GetProductInfoAsync
-- with the pass's or the product's id returns THIS player's PriceInRobux.
--
--==============================================================================
-- AND NEVER A GUESS IN ITS PLACE
--
-- While the answer is on its way a caller is told "loading"; if Roblox cannot
-- answer after every retry it is told "failed" and should show NO price -- the
-- manifest's number is exactly the misleading fallback this module removes. A
-- pass Roblox says is not on sale is "offsale". The purchase prompt stays one
-- press away in every state and is always the authority: it quotes, and
-- charges, the real price.
--
-- CLIENT ONLY. The server has no "this player" to price for, and the manifest's
-- `robux` stays what the server checks receipts and logs against.
--==============================================================================

local MarketplaceService = game:GetService("MarketplaceService")

local RobuxPrice = {}

export type Kind = "pass" | "product"
-- "loading"  asked, no answer yet
-- "ready"    `price` is this player's price
-- "offsale"  Roblox answered: not for sale
-- "failed"   no answer after every retry -- show no price at all
export type State = "loading" | "ready" | "offsale" | "failed"
export type Listener = (State, number?) -> ()

type Entry = {
	kind: Kind,
	id: number,
	state: State,
	price: number?,
	listeners: { Listener },
	fetchedAt: number?,
	busy: boolean,
}

-- Seconds between tries after a failed one. Three retries covers a join that
-- lands in a web hiccup without hammering an endpoint that is down.
RobuxPrice.RetryAfter = { 2, 5, 15 }
-- A price can change while a server runs -- a sale, the owner re-pricing -- so
-- `refresh` asks again for any answer older than this.
RobuxPrice.StaleAfter = 600

local entries: { [string]: Entry } = {}

local function infoTypeOf(kind: Kind): Enum.InfoType
	return if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
end

-- One question to Roblox. GetProductInfoAsync is the current name; the older
-- GetProductInfo is the fallback for a client that predates it.
local function askRoblox(kind: Kind, id: number): (boolean, any)
	local infoType = infoTypeOf(kind)
	local ok, info = pcall(function()
		return (MarketplaceService :: any):GetProductInfoAsync(id, infoType)
	end)
	if not ok and string.find(tostring(info), "valid member", 1, true) then
		ok, info = pcall(function()
			return (MarketplaceService :: any):GetProductInfo(id, infoType)
		end)
	end
	return ok, info
end

-- Swappable so RobuxPriceSpec can drive every state without a network.
local ask: (Kind, number) -> (boolean, any) = askRoblox

function RobuxPrice.setAskerForTests(fn: ((Kind, number) -> (boolean, any))?)
	ask = fn or askRoblox
	table.clear(entries)
end

-- What an answer means. A developer product has no IsForSale; a pass that is
-- off sale answers IsForSale = false and no price.
local function read(info: any): (State, number?)
	if type(info) ~= "table" then
		return "failed", nil
	end
	local price = tonumber(info.PriceInRobux)
	if info.IsForSale == false then
		return "offsale", nil
	end
	if price == nil or price ~= price or price < 0 then
		return "failed", nil
	end
	return "ready", math.floor(price)
end

local function set(entry: Entry, state: State, price: number?)
	entry.state = state
	entry.price = price
	for _, listener in ipairs(table.clone(entry.listeners)) do
		local ok, err = pcall(listener, state, price)
		if not ok then
			warn("[Seed/RobuxPrice] a listener failed: " .. tostring(err))
		end
	end
end

local function fetch(entry: Entry)
	if entry.busy then
		return
	end
	entry.busy = true
	task.spawn(function()
		local tries = #RobuxPrice.RetryAfter + 1
		for attempt = 1, tries do
			local ok, info = ask(entry.kind, entry.id)
			if ok then
				local state, price = read(info)
				if state ~= "failed" then
					entry.busy = false
					entry.fetchedAt = os.clock()
					set(entry, state, price)
					return
				end
			end
			local pause = RobuxPrice.RetryAfter[attempt]
			if pause == nil then
				break
			end
			task.wait(pause)
		end
		entry.busy = false
		-- A refresh that fails keeps the price already on screen: it was right a
		-- few minutes ago, and a blank is worse than that.
		if entry.state ~= "ready" and entry.state ~= "offsale" then
			set(entry, "failed", nil)
		end
	end)
end

--==============================================================================
-- WATCH A PRICE
--
-- `listener` is called at once with what is known -- "loading" the first time
-- an id is asked for -- and again every time that changes. Every caller of the
-- same id shares one question to Roblox. Returns the function that stops it.
--==============================================================================
function RobuxPrice.watch(kind: Kind, id: number, listener: Listener): () -> ()
	local key = kind .. ":" .. tostring(id)
	local entry = entries[key]
	local fresh = entry == nil
	if not entry then
		entry = {
			kind = kind,
			id = id,
			state = "loading",
			price = nil,
			listeners = {},
			fetchedAt = nil,
			busy = false,
		}
		entries[key] = entry
	end
	local this = entry :: Entry
	table.insert(this.listeners, listener)
	local ok, err = pcall(listener, this.state, this.price)
	if not ok then
		warn("[Seed/RobuxPrice] a listener failed: " .. tostring(err))
	end
	if fresh then
		fetch(this)
	end
	return function()
		local at = table.find(this.listeners, listener)
		if at then
			table.remove(this.listeners, at)
		end
	end
end

-- Asks again for every price that failed, or that is older than StaleAfter. The
-- Shop calls this as it opens, so a join that met a web hiccup heals itself.
function RobuxPrice.refresh()
	local now = os.clock()
	for _, entry in pairs(entries) do
		local stale = entry.fetchedAt ~= nil and now - entry.fetchedAt > RobuxPrice.StaleAfter
		if not entry.busy and (entry.state == "failed" or stale) then
			fetch(entry)
		end
	end
end

-- 199 -> "199", 1500 -> "1,500": the grouping the purchase prompt uses.
function RobuxPrice.format(price: number): string
	local text = tostring(math.floor(price))
	local grouped = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1,")))
	return (string.gsub(grouped, "^,", ""))
end

return RobuxPrice
