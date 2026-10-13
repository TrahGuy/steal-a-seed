--!nocheck
--==============================================================================
-- Steal a Seed :: NameBadgeSpec
--
-- NAME BADGES (2026-10-13, the owner's request; GameConfig.NameBadges): a
-- small square picture right after a name -- the owner's, Michael's, and every
-- VIP's -- on the name over the head and on every broadcast and admin line its
-- SENDER makes. Edit mode:
--
--   1. who wears which: by UserId (the two named accounts) and then VIP, with
--      simulated UserIds from 90,000,000,000 for VIP and no badge; the
--      owner's three uploads; the square's size and place by each face's caps
--   2. the name over the head (VipService.dress) and its place on the name
--      (NameBadgeUI: against the last letter, the two centred as one)
--   3. the broadcast: the badge in the queue and across servers, drawn in the
--      name's box (AnnouncementUI)
--   4. the admin lines: the payload, the notice, the shared event record, and
--      the room kept after the name (ActionToastUI)
--
-- Not here, seen in the guarded Play: the pictures themselves on a screen.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Notice = require(Shared:WaitForChild("Notice"))
local UIKit = require(Shared:WaitForChild("UIKit"))

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
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found and found.Source
	end)
	return if ok and src then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local B = GameConfig.NameBadges
-- Simulated accounts only (from 90,000,000,000), besides the two the owner named.
local SIM_VIP, SIM_PLAIN = 90000000001, 90000000002
local OWNER, MICHAEL = 4119740186, 11607308004

local board = Instance.new("Folder")
board.Name = "ZZNameBadgeSpecBoard"
board.Archivable = false

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. who wears which --")
	--==========================================================================
	local personal = 0
	for _ in pairs(B.Personal) do
		personal += 1
	end
	check(personal == 2 and B.Personal[OWNER] == "owner" and B.Personal[MICHAEL] == "michael",
		"by UserId, the two accounts the owner named: nicnicniccoal (4119740186) and Michael's admin account, "
			.. "Teambarnze825 (11607308004)")
	check(B.Images.owner == "rbxassetid://134108586814210" and B.Images.michael == "rbxassetid://107958688128648"
			and B.Images.vip == "rbxassetid://106551880162131",
		"the owner's three uploads, by the ids they sent")
	check(GameConfig.nameBadgeFor(OWNER, true) == "owner" and GameConfig.nameBadgeFor(MICHAEL, true) == "michael"
			and GameConfig.nameBadgeFor(MICHAEL, false) == "michael",
		"one a person: a personal badge wins over VIP's, VIP or not")
	check(GameConfig.nameBadgeFor(SIM_VIP, true) == "vip" and GameConfig.nameBadgeFor(SIM_PLAIN, false) == nil
			and GameConfig.nameBadgeFor(nil, true) == "vip" and GameConfig.nameBadgeFor(SIM_PLAIN, "yes") == nil,
		"anybody else: VIP's when they own VIP, else none")
	check(GameConfig.nameBadgeFor(tostring(OWNER), false) == nil and GameConfig.nameBadgeFor(OWNER + 0.5, false) == nil,
		"matched by the numeric UserId only: never a string that looks like one")
	check(GameConfig.nameBadgeKey("owner") == "owner" and GameConfig.nameBadgeKey("vip") == "vip"
			and GameConfig.nameBadgeKey("admin") == nil and GameConfig.nameBadgeKey("") == nil
			and GameConfig.nameBadgeKey(1) == nil and GameConfig.nameBadgeKey(nil) == nil,
		"a key handed over is drawn only when it is one")
	-- The square: about the capitals' height, its foot on their baseline.
	local feet, clamped = true, true
	for _, face in ipairs({ "LuckiestGuy", "Comic" }) do
		local caps = B.Caps[face]
		for size = 12, 30 do
			local side, top, gap = GameConfig.nameBadgeBox(face, size)
			local capTop, capH = size * caps.Top, size * caps.Height
			if side >= capH and math.abs((top + side) - (capTop + capH)) > 1e-6 then
				feet = false
			end
			if side < B.MinPx or side > B.MaxPx or gap < 1 or top > capTop + 1e-6 then
				clamped = false
			end
		end
	end
	-- A billboard draws the name as tall as its box (VipService.dress keeps the room for that).
	local nameSide, nameTop, nameGap = GameConfig.nameBadgeBox("LuckiestGuy", GameConfig.Pass.VipName.Size.Y)
	local castSide = GameConfig.nameBadgeBox("Comic", 22)
	check(feet and clamped and nameSide == 17 and nameGap == 3 and nameTop < 0 and castSide == 14
			and GameConfig.nameBadgeBox("Comic", 200) == B.MaxPx and GameConfig.nameBadgeBox("Comic", 4) == B.MinPx,
		"the square: its foot on the capitals' baseline, its top a touch over theirs, held to its least and most",
		string.format("name %d (top %.2f, gap %d), broadcast %d", nameSide, nameTop, nameGap, castSide))

	--==========================================================================
	say("\n-- 2. the name over the head --")
	--==========================================================================
	local VipService = require(Server:WaitForChild("VipService"))
	local NAME = GameConfig.Pass.VipName
	local function body()
		local character = Instance.new("Model")
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Parent = character
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = character
		return character, head, humanoid
	end
	local c1, _, hum1 = body()
	local gold = VipService.dress(c1, "Nicky", true, "vip")
	local words = gold and gold:FindFirstChild("Words")
	local mark = gold and gold:FindFirstChild("Badge")
	check(gold and words and words.TextColor3 == NAME.Colour and mark and mark:IsA("ImageLabel")
			and mark.Image == B.Images.vip and mark.Visible == false and gold:GetAttribute("Badge") == "vip"
			and mark.Size == UDim2.fromOffset(nameSide, nameSide)
			and words.Size == UDim2.new(1, -(nameSide + nameGap), 1, 0)
			and hum1.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None,
		"a VIP: the gold name, its badge in the room kept on its right, hidden until a screen places it")
	c1:Destroy()
	local c2, h2, hum2 = body()
	local white = VipService.dress(c2, "Mike", false, "michael")
	local wWords = white and white:FindFirstChild("Words")
	local wEdge = wWords and wWords:FindFirstChildOfClass("UIStroke")
	check(white and wWords and wWords.TextColor3 == NAME.PlainColour and wEdge and wEdge.Color == NAME.PlainOutline
			and white:FindFirstChild("Badge") and white.Badge.Image == B.Images.michael
			and hum2.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None
			and white.MaxDistance == NAME.MaxDistance and white.AlwaysOnTop == false,
		"a badge's wearer who is no VIP: the same name in white, the engine's hidden, as far as the name is seen")
	VipService.dress(c2, "Mike", false, "admin")
	check(h2:FindFirstChild(NAME.Name) == nil and hum2.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.Viewer,
		"no badge it knows and no VIP: no name of ours, the engine's back")
	c2:Destroy()
	local c3 = body()
	local plainGold = VipService.dress(c3, "Nicky", true)
	check(plainGold and plainGold:FindFirstChild("Badge") == nil and plainGold:GetAttribute("Badge") == nil
			and plainGold.Words.Size == UDim2.fromScale(1, 1),
		"a VIP named with no badge (the old call) is the gold name as it was")
	c3:Destroy()
	local vipSrc = sourceOf(Server, "VipService")
	check(has(vipSrc, "return GameConfig.nameBadgeFor(player.UserId, PassService.IsVip(player))")
			and has(vipSrc, "player:SetAttribute(GameConfig.NameBadges.Attribute, badgeOf(player))")
			and has(vipSrc, "VipService.dress(character, player.DisplayName, PassService.IsVip(player), badgeOf(player))"),
		"the server decides it by UserId, then VIP (PassService, real or gifted), and publishes it on the player")
	-- Its place on the name (NameBadgeUI): against the last letter as drawn,
	-- the name and its badge centred as one.
	local ui = sourceOf(Scripts, "NameBadgeUI")
	check(has(ui, "return (labelW + drawn.X) / 2 + gap, (labelH - size) / 2 + top, side")
			and has(ui, "label:GetPropertyChangedSignal(\"TextBounds\"):Connect(function()")
			and has(ui, "local x, y, side = spot(drawn, NAME.Size.X - kept, NAME.Size.Y)")
			and has(ui, "mark.Visible = true") and has(ui, "elseif p.label.TextBounds ~= p.at then"),
		"each screen puts it after the name's letters as it draws them, again whenever they change")
	local centred = true
	for _, textW in ipairs({ 40, 120, 190 }) do
		local labelW = NAME.Size.X - (nameSide + nameGap)
		local x = (labelW + textW) / 2 + nameGap
		local left, right = (labelW - textW) / 2, x + nameSide
		if math.abs((left + right) / 2 - NAME.Size.X / 2) > 0.5 or right > NAME.Size.X then
			centred = false
		end
	end
	check(centred, "at the name's own size the name and its badge stand centred over the head, inside the name's box")

	--==========================================================================
	say("\n-- 3. the broadcast --")
	--==========================================================================
	local Announce = require(Server:WaitForChild("AnnouncementService"))
	local now = 2_000_000
	Announce.Init()
	board.Parent = game:GetService("ServerStorage")
	Announce.useBoard(board)
	Announce.useClock(function()
		return now
	end)
	Announce.useShowClock(function()
		return now
	end)
	local function sender(userId, vip)
		return {
			UserId = userId,
			GetAttribute = function(_, name)
				return if name == GameConfig.Pass.VipAttribute then vip else nil
			end,
		}
	end
	check(Announce.SenderBadge(sender(OWNER, true)) == "owner" and Announce.SenderBadge(sender(SIM_VIP, true)) == "vip"
			and Announce.SenderBadge(sender(SIM_PLAIN, false)) == nil and Announce.SenderBadge(nil) == nil,
		"a broadcast's sender wears theirs: by UserId, then VIP")
	local function receive(id, badge)
		return Announce.Receive({ id = id, text = "hello all", from = "Far Admin", badge = badge, sentAt = now,
			expiresAt = now + 30 })
	end
	local shownWith = receive("BADGEOWNER000001", "owner")
	local shownOdd = receive("BADGEODD00000002", "admin")
	local shownNone = receive("BADGENONE0000003", nil)
	local byId = {}
	for _, e in ipairs(Announce.Queue()) do
		byId[e.id] = e
	end
	local raw = board:GetAttribute(GameConfig.Announce.Attributes.Queue)
	local okJson, list = pcall(function()
		return game:GetService("HttpService"):JSONDecode(raw)
	end)
	local carried = false
	if okJson and type(list) == "table" then
		for _, v in ipairs(list) do
			if v.i == "BADGEOWNER000001" and v.b == "owner" then
				carried = true
			end
		end
	end
	check(shownWith == "shown" and shownOdd == "shown" and shownNone == "shown"
			and byId.BADGEOWNER000001 and byId.BADGEOWNER000001.badge == "owner"
			and byId.BADGEODD00000002 and byId.BADGEODD00000002.badge == nil
			and byId.BADGENONE0000003 and byId.BADGENONE0000003.badge == nil and carried,
		"another server's broadcast keeps its sender's badge; one it does not know is shown without, never refused")
	local svc = sourceOf(Server, "AnnouncementService")
	check(has(svc, "local badge = senderBadge(sender)\n\tlocal queued, ahead, startsIn = showHere(id, shown, from, badge)")
			and has(svc, "\t\tbadge = badge,\n\t\tsentAt = now,")
			and has(svc, "{ i = e.id, t = e.text, f = e.from, b = e.badge, s = e.startAt, e = e.endAt }"),
		"this server's own broadcast carries it on the queue and to every other server")
	local castUi = sourceOf(Scripts, "AnnouncementUI")
	check(has(castUi, "badge = GameConfig.nameBadgeKey(v.b),")
			and has(castUi, "draw(current.from, current.text, current.badge)")
			and has(castUi, "side, top, gap = GameConfig.nameBadgeBox(\"Comic\", style.size)")
			and has(castUi, "box.Size = UDim2.fromOffset(lettersW + badgeW, lettersH)")
			and has(castUi, "mark.Position = UDim2.fromOffset(lettersW + gap, math.floor(top + 0.5))")
			and has(castUi, "local head = widthOf(name) + badgeW + widthOf(\":\") + style.gap"),
		"the line draws it in the name's box, against the last letter, so the colon follows it: \"Name▣: message\"")

	--==========================================================================
	say("\n-- 4. the admin lines --")
	--==========================================================================
	local withBadge = Notice.readServerNotice({ title = "Nicky made it night!", bare = true, name = "Nicky",
		badge = "owner" })
	local notInTitle = Notice.readServerNotice({ title = "Nicky made it night!", bare = true, name = "Rin",
		badge = "owner" })
	local oddKey = Notice.readServerNotice({ title = "Nicky made it night!", bare = true, name = "Nicky",
		badge = "own er" })
	local none = Notice.readServerNotice({ title = "Nicky made it night!", bare = true })
	check(withBadge and withBadge.name == "Nicky" and withBadge.badge == "owner" and notInTitle
			and notInTitle.name == nil and notInTitle.badge == nil and oddKey and oddKey.badge == nil
			and none and none.badge == nil,
		"a notice keeps the sender's badge only with the name it follows, standing in its title")
	local Admin = require(Server:WaitForChild("AdminService"))
	check(Admin.BadgeOf(sender(OWNER, false)) == "owner" and Admin.BadgeOf(sender(MICHAEL, false)) == "michael"
			and Admin.BadgeOf(sender(SIM_VIP, true)) == "vip" and Admin.BadgeOf(sender(SIM_PLAIN, false)) == nil,
		"an admin's line carries the admin's badge, by UserId then VIP")
	local adminSrc = sourceOf(Server, "AdminService")
	check(has(adminSrc, "name = if sender and sender.badge then sender.name else nil,")
			and has(adminSrc, "badge = if sender then sender.badge else nil })")
			and has(adminSrc, "AdminAnnounce.quiet(what.kind), { name = shown, badge = AdminService.BadgeOf(admin) })"),
		"AdminService sends the name as it stands in the line, with the badge")
	local okMes, MES = pcall(require, Server:WaitForChild("MiniEventService"))
	local function record(extra)
		local r = { v = 1, ns = "spec", id = "abcdef1234567890", rev = 1, mode = "podrush", startedAt = 1000,
			endsAt = 1300, state = "running", by = SIM_VIP, byName = "Spec", endedIds = {} }
		for k, v in pairs(extra) do
			r[k] = v
		end
		return r
	end
	check(okMes and MES.ValidRecord(record({})) and MES.ValidRecord(record({ byBadge = "vip", endedByBadge = "owner" }))
			and MES.ValidRecord(record({ byBadge = "somethingnew" })) and not MES.ValidRecord(record({ byBadge = 7 }))
			and not MES.ValidRecord(record({ byBadge = string.rep("x", 17) })),
		"a global event's record carries its admins' badges to every server; an old record without them is still one",
		if okMes then nil else MES)
	local mini = sourceOf(Server, "MiniEventService")
	local _, sends = string.gsub(mini, "name = if badge then shown else nil, badge = badge, bare = true }, nil%)", "")
	check(sends == 2 and has(mini, "byBadge = badgeOf(by),") and has(mini, "record.endedByBadge = badgeOf(by)")
			and has(mini, "local badge = GameConfig.nameBadgeKey(event.byBadge)")
			and has(mini, "local badge = GameConfig.nameBadgeKey(r.endedByBadge)"),
		"both of its lines -- started and ended -- name the admin with their badge", sends)
	-- The room kept after the name, in the headline's own face and size.
	local toast = sourceOf(Scripts, "ActionToastUI")
	check(has(toast, "local badge = if bare then GameConfig.nameBadgeKey(post.badge) else nil")
			and has(toast, "while textWidth(\"A\" .. pad .. \"A\", size) - textWidth(\"AA\", size) < gap + side + space / 2")
			and has(toast, "if string.sub(rest, 1, 1) == \" \" then\n\t\t\t\t\trest = string.sub(rest, 2)")
			and has(toast, "local found = Notice.wordSpan(title, badgeName, room, function(text: string): number")
			and has(toast, "mark.Position = UDim2.fromOffset(math.floor(1 + badgeSpan.x + badgeSpan.w + gap + 0.5),")
			and has(toast, "local NBSP = \"\\u{00A0}\""),
		"the notice keeps no-break room after the name and lays the badge over it")
	local hs = 26
	local side, _, gap = GameConfig.nameBadgeBox("Comic", hs)
	local function width(text)
		return UIKit.comicBounds(text, hs).X
	end
	local space = width("A A") - width("AA")
	local pad = "\u{00A0}"
	while width("A" .. pad .. "A") - width("AA") < gap + side + space / 2 and #pad < 40 do
		pad ..= "\u{00A0}"
	end
	-- The room takes the place of the space after the name.
	local titled = "nicnicniccoal" .. pad .. "made it night!"
	local span = Notice.wordSpan(titled, "nicnicniccoal", 200, width)
	local kept = width("nicnicniccoal" .. pad .. "A") - width("nicnicniccoalA")
	local after = kept - gap - side
	check(span.line == 1 and span.x >= 0 and span.w > 0 and after >= space / 2 - 0.5 and after <= space * 2
			and #span.lines >= 2 and string.find(span.lines[1], "nicnicniccoal" .. pad, 1, true) == 1,
		"wrapped or not, the name and its room stay on one line: the gap, the badge, then about a space before "
			.. "the next word",
		string.format("lines %d, room %.1f for %d + %d, then %.1f (a space is %.1f)", #span.lines, kept, gap, side,
			after, space))
	-- Chat and the player list are not touched: neither can show a picture.
	local chat = sourceOf(Scripts, "VipChat")
	check(not has(chat, "NameBadge") and GameConfig.vipPrefix("Nicky") == '<font color="#FFD040">[VIP]</font> Nicky',
		"chat keeps the gold [VIP] tag as it was; no badge there")
end)

pcall(function()
	local A = require(Server:WaitForChild("AnnouncementService"))
	A.useBoard(nil)
	A.useClock(nil)
	A.useShowClock(nil)
end)
board:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nNameBadgeSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
