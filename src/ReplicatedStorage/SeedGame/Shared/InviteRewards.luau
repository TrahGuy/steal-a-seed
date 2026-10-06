--!strict
-- Steal a Seed :: InviteRewards
--
-- The Invite a Friend track's one answer (2026-10-06): from a confirmed count
-- of friends who joined through a player's invites -- and how many forms the
-- server has given -- which form stands, what the sign and the panel say, which
-- card is earned, next or locked, and whether INVITE wears its "!".
--
-- PURE. Numbers in, tables out: no Instances, no clock, no player. The server
-- (InviteService) asks it which forms a count has earned; the hub pedestal
-- (InviteHub), the INVITE panel and button (InviteUI) and the specs ask it
-- what to show -- one function each, so the three can never disagree.
--
--==============================================================================
-- NEVER AHEAD OF THE GRANT
--
-- What a screen shows is the SHOWN tier: the forms the count has earned, but
-- never more than the server has actually given (a form owed while the Bag is
-- full is not shown until it lands). A client never picks a form above the
-- server's count, and never from its own input: both numbers are attributes
-- the server writes (GameConfig.InviteRewards.Attributes).
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local InviteForms = require(Shared:WaitForChild("InviteForms"))

local CONFIG = GameConfig.InviteRewards
local WORDS = CONFIG.Words

local InviteRewards = {}

InviteRewards.Thresholds = CONFIG.Thresholds
InviteRewards.Forms = CONFIG.Forms
InviteRewards.Count = #CONFIG.Forms

assert(#CONFIG.Thresholds == #CONFIG.Forms and #CONFIG.Forms >= 1,
	"GameConfig.InviteRewards: one threshold per form")
for i, form in ipairs(CONFIG.Forms) do
	local need = CONFIG.Thresholds[i]
	local species = SeedData.Get(form) :: any
	assert(species and species.Invite == true,
		string.format("GameConfig.InviteRewards: form %q is not an invite reward", tostring(form)))
	assert(type(need) == "number" and need >= 1 and math.floor(need) == need
			and (i == 1 or need > CONFIG.Thresholds[i - 1]),
		"GameConfig.InviteRewards: thresholds are whole, at least 1 and rising")
end

-- A count off the wire or a save: whole, never below 0.
local function whole(value: any): number
	if type(value) ~= "number" or value ~= value or value == math.huge then
		return 0
	end
	return math.max(0, math.floor(value))
end

-- How many forms a count has EARNED: the thresholds at or under it.
function InviteRewards.tierFor(count: any): number
	local n = whole(count)
	local tier = 0
	for i, need in ipairs(CONFIG.Thresholds) do
		if n >= need then
			tier = i
		end
	end
	return tier
end

-- The tier a screen shows: earned, and given (see NEVER AHEAD OF THE GRANT).
function InviteRewards.shownTier(count: any, granted: any): number
	return math.min(InviteRewards.tierFor(count), math.clamp(whole(granted), 0, InviteRewards.Count))
end

-- The form that stands for a tier. Tier 0 -- nobody yet -- shows the first form
-- as the goal.
function InviteRewards.formOfTier(tier: number): string
	return CONFIG.Forms[math.clamp(tier, 1, InviteRewards.Count)]
end

-- The count-to-form choice, in one place (the brief's "one shared, pure
-- function"): the form a count has earned, the first one as the goal at 0.
function InviteRewards.formFor(count: any): string
	return InviteRewards.formOfTier(InviteRewards.tierFor(count))
end

function InviteRewards.plural(n: number): string
	return if n == 1 then WORDS.One else WORDS.Many
end

export type Reward = {
	tier: number,
	form: string,
	name: string,
	rarity: string,
	colour: Color3,
	income: number,
	incomeText: string,
	-- Friends needed.
	at: number,
}

-- One form's row: its name, rarity and colour, its fixed rate and its threshold.
function InviteRewards.reward(tier: number): Reward
	local form = InviteRewards.formOfTier(tier)
	local species = SeedData.Get(form) :: SeedData.Species
	local income = SeedData.IncomePerSecond(species, SeedData.InviteTier)
	return {
		tier = math.clamp(tier, 1, InviteRewards.Count),
		form = form,
		name = species.Name,
		rarity = species.Rarity,
		colour = GameConfig.RarityColor[species.Rarity] or Color3.new(1, 1, 1),
		income = income,
		incomeText = string.format(WORDS.Income, GameConfig.compact(income)),
		at = CONFIG.Thresholds[math.clamp(tier, 1, InviteRewards.Count)],
	}
end

export type Content = {
	-- The tier shown (0 .. Count) and the form standing for it.
	tier: number,
	shown: Reward,
	-- The next form to earn and its line ("NEXT: ..."), or nil at the final form.
	next: Reward?,
	nextText: string?,
	-- The bar: friends counted over the next threshold (full at the final form).
	count: number,
	target: number,
	fraction: number,
	barText: string,
	-- The bar's fill: the next form's rarity colour, gold at the final form.
	fill: Color3,
	final: boolean,
	finalText: string?,
}

-- Everything the sign and the panel's hero say, for a count and the forms given.
function InviteRewards.content(count: any, granted: any): Content
	local n = whole(count)
	local tier = InviteRewards.shownTier(n, granted)
	local final = tier >= InviteRewards.Count
	local shown = InviteRewards.reward(math.max(tier, 1))
	if final then
		return {
			tier = tier,
			shown = shown,
			next = nil,
			nextText = nil,
			count = n,
			target = n,
			fraction = 1,
			barText = string.format(WORDS.Bar, n, CONFIG.Thresholds[InviteRewards.Count]),
			fill = CONFIG.Gold,
			final = true,
			finalText = WORDS.Final,
		}
	end
	local nxt = InviteRewards.reward(tier + 1)
	-- A form earned but not yet given (the Bag was full) shows a full bar: the
	-- count has reached it; the form follows the grant.
	local shownCount = math.min(n, nxt.at)
	return {
		tier = tier,
		shown = shown,
		next = nxt,
		nextText = string.format(WORDS.Next, nxt.name, nxt.rarity, nxt.at, InviteRewards.plural(nxt.at)),
		count = n,
		target = nxt.at,
		fraction = math.clamp(shownCount / nxt.at, 0, 1),
		barText = string.format(WORDS.Bar, shownCount, nxt.at),
		fill = nxt.colour,
		final = false,
		finalText = nil,
	}
end

export type CardState = "earned" | "next" | "locked"
export type Card = Reward & { state: CardState, gold: boolean }

-- The track's four cards: EARNED once given, NEXT the one after the last given,
-- LOCKED beyond -- never hidden. The final form's card is gold at every state.
function InviteRewards.cards(count: any, granted: any): { Card }
	local tier = InviteRewards.shownTier(count, granted)
	local out: { Card } = {}
	for i = 1, InviteRewards.Count do
		local r = InviteRewards.reward(i) :: any
		r.state = if i <= tier then "earned" elseif i == tier + 1 then "next" else "locked"
		r.gold = i == InviteRewards.Count
		table.insert(out, r :: Card)
	end
	return out
end

-- INVITE's "!" (the owner, 2026-10-06): shown until the panel has been opened
-- since the last form was given -- and before it was ever opened at all.
function InviteRewards.badge(seen: any): boolean
	return seen ~= true
end

--==============================================================================
-- THE NOTICES (InviteUI and InviteRewardUI post them; the owner's notices
-- brief, 2026-10-06): what each of the server's payloads says, in one place.
--==============================================================================

-- The "/N" of +1 INVITE: the next threshold after `count`, the last one once
-- the final form is earned.
function InviteRewards.nextAt(count: any): number
	local n = whole(count)
	for _, need in ipairs(CONFIG.Thresholds) do
		if n < need then
			return need
		end
	end
	return CONFIG.Thresholds[InviteRewards.Count]
end

-- A person by their DisplayName, or "a friend": never a number, never a UserId.
function InviteRewards.who(name: any): string
	if type(name) == "string" and name ~= "" and not string.match(name, "^%d+$") then
		return name
	end
	return WORDS.SomeFriend
end

local function capital(text: string): string
	return (string.gsub(text, "^%l", string.upper))
end

export type NoticeWords = {
	kind: string,
	title: string,
	detail: string,
	-- One key a kind: a second of the same notice soon after refreshes it
	-- where it stands (Notice's rules) rather than stacking.
	key: string,
	-- Its own invite sound (InviteSounds) in place of the kind's, or none.
	quiet: boolean,
	sound: string?,
}

-- The notice for a payload from InviteService (InviteNews), or nil.
function InviteRewards.notice(payload: any): NoticeWords?
	if type(payload) ~= "table" then
		return nil
	end
	local kind = payload.kind
	if kind == "joined" then
		local count = whole(payload.count)
		return {
			kind = "success",
			title = WORDS.Joined,
			detail = string.format(WORDS.JoinedDetail, capital(InviteRewards.who(payload.name)), count,
				InviteRewards.nextAt(count)),
			key = "InviteJoined",
			quiet = true,
			sound = "joined",
		}
	elseif kind == "notcounted" then
		return {
			kind = "info",
			title = string.format(WORDS.NotCounted, capital(InviteRewards.who(payload.name))),
			detail = WORDS.NotCountedWhy[payload.why] or WORDS.NotCountedWhy.returning,
			key = "InviteNotCounted",
			quiet = false,
			sound = nil,
		}
	elseif kind == "welcome" then
		return {
			kind = "info",
			title = WORDS.Welcome,
			detail = string.format(WORDS.WelcomeDetail, InviteRewards.who(payload.name)),
			key = "InviteWelcome",
			quiet = true,
			sound = "welcome",
		}
	elseif kind == "away" then
		local n = whole(payload.count)
		return {
			kind = "info",
			title = WORDS.Away,
			detail = string.format(WORDS.AwayDetail, n, if n == 1 then WORDS.Friend else WORDS.Friends),
			key = "InviteAway",
			quiet = false,
			sound = nil,
		}
	elseif kind == "full" then
		return { kind = "warning", title = WORDS.Full, detail = WORDS.FullDetail, key = "InviteFull", quiet = false,
			sound = nil }
	end
	return nil
end

-- The notice when this player cannot send invites (InviteSend).
function InviteRewards.cantSend(): NoticeWords
	return { kind = "blocked", title = WORDS.CantSend, detail = WORDS.CantSendDetail, key = "InviteCantSend",
		quiet = false, sound = nil }
end

--==============================================================================
-- THE REWARD POPUP (InviteRewardUI): one card a form given
--==============================================================================
export type Intensity = {
	rays: number,
	sparkles: number,
	sparkleSize: number,
	edge: boolean,
	confetti: number,
	burst: number,
	rim: Color3?,
}

export type PopupCard = Reward & {
	final: boolean,
	-- The rim: the rarity's colour, or the intensity's own (the Secret's gold).
	rim: Color3,
	ribbon: string,
	line: string,
	autoClose: number,
	intensity: Intensity,
}

-- The card for a tier: its words, its rim, how long it stays untouched, and how
-- loud it looks (GameConfig.InviteRewards.Popup.Intensity, by rarity).
function InviteRewards.popup(tier: number): PopupCard
	local P = CONFIG.Popup
	local card = InviteRewards.reward(tier) :: any
	local final = card.tier >= InviteRewards.Count
	local look = (P.Intensity[card.rarity] or P.Intensity.Epic) :: Intensity
	card.final = final
	card.rim = look.rim or card.colour
	card.ribbon = if final then P.FinalRibbon else P.Ribbon
	card.line = string.format(P.Line, card.at, if card.at == 1 then P.Friend else P.Friends, WORDS.Unsellable)
	card.autoClose = if final then P.FinalAutoClose else P.AutoClose
	card.intensity = look
	return card :: PopupCard
end

-- The popup's queue: each form given once, lowest first. Answers whether `tier`
-- joined it.
function InviteRewards.enqueue(queue: { number }, tier: any): boolean
	local t = whole(tier)
	if t < 1 or t > InviteRewards.Count or table.find(queue, t) then
		return false
	end
	table.insert(queue, t)
	table.sort(queue)
	return true
end

-- The card to show now: the lowest waiting -- none while another reward moment
-- or a centre panel is up (`busy`, RewardMoments.busy).
function InviteRewards.nextCard(queue: { number }, busy: boolean): number?
	if busy or #queue == 0 then
		return nil
	end
	return table.remove(queue, 1)
end

-- Where a form stands on the hub pedestal: the top surface's centre, front
-- (-Z) to the deck's centre. The server builds the pedestal round it and every
-- client stands its own form on it -- one answer for both.
function InviteRewards.standFrame(): CFrame
	local P = CONFIG.Pedestal
	local origin = CFrame.new(CONFIG.Position) * CFrame.Angles(0, math.rad(CONFIG.FacingDegrees), 0)
	return origin * CFrame.new(0, P.Foot.Y + P.Column.Y + P.Top.Y, 0)
end

--==============================================================================
-- THE PEDESTAL'S COPY FILLS THE ROOM UNDER THE SIGN (the owner, 2026-10-06)
--
-- The room: from the pedestal's top up to the plate's keyline, and out to the
-- pillars' inner faces either side. A form's display copy is scaled whole so
-- its highest point at rest stands DisplayFill of that height; and so that an
-- aura sphere swollen to AuraSwell -- the top of its flare -- still stands
-- DisplayClear inside the keyline and the pillars. Whichever binds first.
-- Measured off the form's own authored parts (InviteForms), invisible ones
-- aside. The display copy only: the source model and a granted plant keep
-- their own size.
--==============================================================================
export type Room = { height: number, half: number }

function InviteRewards.displayRoom(): Room
	local P, S = CONFIG.Pedestal, CONFIG.Sign
	return {
		height = S.Bottom - S.Keyline - (P.Foot.Y + P.Column.Y + P.Top.Y),
		half = S.PillarHalf - S.PillarWidth / 2,
	}
end

-- How high and how far to either side a form's visible parts reach at scale
-- 1, its aura sphere (if any) at `swell` times its size.
function InviteRewards.formReach(form: string, swell: number): (number, number)
	local spec = InviteForms.Plants[form] :: any
	local top, half = 0, 0
	for _, p in ipairs(if spec then spec.Parts else {}) do
		if p.t ~= 1 then
			local z: Vector3 = if p.n == "Aura" then p.z * swell else p.z
			local cf: CFrame = p.cf
			local x, y, w = cf.XVector, cf.YVector, cf.ZVector
			local hx = (math.abs(x.X) * z.X + math.abs(y.X) * z.Y + math.abs(w.X) * z.Z) / 2
			local hy = (math.abs(x.Y) * z.X + math.abs(y.Y) * z.Y + math.abs(w.Y) * z.Z) / 2
			top = math.max(top, cf.Y + hy)
			half = math.max(half, math.abs(cf.X) + hx)
		end
	end
	return top, half
end

local scales: { [string]: number } = {}

-- The hub pedestal's scale for a form (1 for one this file cannot measure).
function InviteRewards.displayScale(form: string): number
	local known = scales[form]
	if known then
		return known
	end
	local room = InviteRewards.displayRoom()
	local restTop = InviteRewards.formReach(form, 1)
	local flareTop, flareHalf = InviteRewards.formReach(form, CONFIG.AuraSwell)
	if restTop <= 0 or flareTop <= 0 or flareHalf <= 0 then
		return 1
	end
	local scale = math.min(CONFIG.DisplayFill * room.height / restTop, (room.height - CONFIG.DisplayClear) / flareTop,
		(room.half - CONFIG.DisplayClear) / flareHalf)
	scales[form] = scale
	return scale
end

return InviteRewards
