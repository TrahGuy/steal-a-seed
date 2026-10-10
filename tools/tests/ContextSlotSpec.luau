--!nocheck
--==============================================================================
-- Steal a Seed :: ContextSlotSpec
--
-- THE CONTEXT SLOT (2026-10-10, the owner: "we can remove the hotbar while the
-- drop button appears, so the button will replace hotbar position, we could
-- also apply it while riding the mill for the minigame button too"). Edit mode,
-- by arithmetic and by source:
--
--   1. the config: the yield prefix, the owner's DROP picture, its keys, verb
--      and press gap (GameConfig.ContextSlot)
--   2. HudLayout.contextButton on every listed screen: inside the strip's rect,
--      centred on it, at the button's own aspect, never taller than the strip
--      -- DROP and PLAY MINIGAME both
--   3. LoadoutUI: the strip, its number keys and LB / RB step aside while any
--      yield attribute is raised; only Visible changes
--   4. DropButtonUI: shown, bound and yielding exactly while a raid pod is
--      carried; it asks, and decides nothing
--   5. CarryService: the DropPod verb drops a RAID carry only, at the player's
--      feet, once per press gap, and counts it as "dropped"
--   6. SproutDashUI: PLAY MINIGAME in the strip's place while riding the mill,
--      yielding the strip
--
-- Not here, seen in Play instead: a press, the pod on the ground, the strip
-- coming back.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

local TOPBAR, BAR_LEFT = 58, 208
local function rect(x, y, w, h)
	return { x = x, y = y, w = w, h = h }
end
local function screen(w, h, touch, inset)
	inset = inset or 0
	return {
		safe = Vector2.new(w - inset * 2, h - TOPBAR - (if inset > 0 then 21 else 0)),
		touch = touch,
		keyboard = not touch,
		viewport = Vector2.new(w, h),
		topbar = rect(BAR_LEFT, 0, w - BAR_LEFT, TOPBAR),
		insetTop = TOPBAR,
	}
end

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the config --")
	--==========================================================================
	local CS = GameConfig.ContextSlot
	local D = CS and CS.Drop
	check(CS ~= nil and CS.YieldPrefix == "SeedHotbarYield_" and D ~= nil
			and D.Image == "rbxassetid://77040710214310" and math.abs(D.Aspect - 1024 / 384) < 1e-9
			and D.Action == "DropPod" and D.PressGap > 0 and D.PressGap <= 1
			and table.find(D.Keys, Enum.KeyCode.Backspace) ~= nil and table.find(D.Keys, Enum.KeyCode.ButtonB) ~= nil,
		"the owner's DROP picture (1024 x 384), Backspace and B, the DropPod verb, one press per gap")

	--==========================================================================
	say("-- 2. the button's place, on every listed screen --")
	--==========================================================================
	local screens = {
		{ 1280, 720, false }, { 1366, 768, false }, { 1920, 1080, false }, { 1000, 609, false }, { 860, 700, false },
		{ 700, 400, false }, { 640, 360, true }, { 705, 338, true }, { 772, 360, true }, { 801, 392, true },
		{ 874, 402, true, 62 }, { 896, 414, true, 48 }, { 956, 440, true, 62 }, { 844, 390, true, 47 },
		{ 640, 480, true },
	}
	local bad, smallest = {}, math.huge
	for _, s in ipairs(screens) do
		local L = HudLayout.solve(screen(s[1], s[2], s[3], s[4]))
		local strip = L.hotbar
		for _, b in ipairs({ { "drop", D.Aspect, nil }, { "minigame", 230 / 56, 56 } }) do
			local r = HudLayout.contextButton(L, b[2], b[3])
			local inside = r.x >= strip.x - 1e-6 and r.y >= strip.y - 1e-6 and r.x + r.w <= strip.x + strip.w + 1e-6
				and r.y + r.h <= strip.y + strip.h + 1e-6
			local centred = math.abs((r.x + r.w / 2) - (strip.x + strip.w / 2)) < 1e-6
				and math.abs((r.y + r.h / 2) - (strip.y + strip.h / 2)) < 1e-6
			local shaped = math.abs(r.w / r.h - b[2]) < 1e-6 and r.h <= (b[3] or math.huge) + 1e-6
			if not (inside and centred and shaped) then
				table.insert(bad, string.format("%dx%d %s (%g,%g %gx%g) strip (%g,%g %gx%g)", s[1], s[2], b[1], r.x, r.y,
					r.w, r.h, strip.x, strip.y, strip.w, strip.h))
			end
			if s[3] then
				smallest = math.min(smallest, r.h)
			end
		end
	end
	check(#bad == 0, "DROP and PLAY MINIGAME stand inside the strip's rect, centred on it, at their own aspect, "
		.. "never taller than the strip (PLAY MINIGAME never past 56)", table.concat(bad, "; "))
	check(smallest >= 44, "on every phone the button is at least the touch floor tall", smallest)

	--==========================================================================
	say("-- 3. LoadoutUI steps aside --")
	--==========================================================================
	local lo = sourceOf(Scripts, "LoadoutUI")
	check(has(lo, "hotbar.Visible = not ((bagOpen and not lifted and layout ~= nil and layout.touch) or view.yield)")
			and has(lo, "local prefix = GameConfig.ContextSlot.YieldPrefix")
			and has(lo, "if value == true and string.sub(name, 1, #prefix) == prefix then")
			and has(lo, "if state ~= Enum.UserInputState.Begin or view.yield then")
			and has(lo, "if PadInput.panelOpen() or view.yield then"),
		"the strip, its number keys and LB / RB wait while any yield attribute is raised; only Visible changes")

	--==========================================================================
	say("-- 4. DropButtonUI --")
	--==========================================================================
	local db = sourceOf(Scripts, "DropButtonUI")
	check(db ~= "" and has(db, "return player:GetAttribute(ATTR.CarryingSpecies) ~= nil")
			and has(db, "local r = HudLayout.contextButton(layout, D.Aspect)")
			and has(db, "player:SetAttribute(YIELD, if want then true else nil)")
			and has(db, "Enum.ContextActionPriority.High.Value,\n\t\t\ttable.unpack(D.Keys))")
			and has(db, "(PadInput.panelOpen() or GuiService.SelectedObject ~= nil)")
			and has(db, "channel:FireServer(D.Action)") and has(db, "now - lastPress < D.PressGap")
			and not has(db, "CarryService.Drop(") and not has(db, "SeedGameServer"),
		"shown, bound and yielding exactly while a raid pod is carried; B passes to a panel or a selection; it asks only")

	--==========================================================================
	say("-- 5. CarryService drops a raid carry on DropPod --")
	--==========================================================================
	local carry = sourceOf(Server, "CarryService")
	local at = string.find(carry, "THE DROP BUTTON, ON THE SAME REMOTE", 1, true)
	local block = if at then string.sub(carry, at, at + 2600) else ""
	check(has(block, "if action ~= DROP.Action or not carried[player] then")
			and has(block, "if now - (askedAt[player] or -math.huge) < DROP.PressGap then")
			and has(block, "if CarryService.Drop(player, nil) then")
			and has(block, "Metrics.raidEnded(player, \"dropped\")"),
		"the DropPod verb drops a RAID carry only, at the player's feet, once per gap, counted as dropped")
	local Metrics = require(Server.Metrics)
	check(Metrics.Outcomes.dropped == true, "\"dropped\" is a raid outcome Metrics keeps")

	--==========================================================================
	say("-- 6. SproutDashUI --")
	--==========================================================================
	local sd = sourceOf(Scripts, "SproutDashUI")
	check(has(sd, "local r = HudLayout.contextButton(L, BUTTON_W / BUTTON_H, BUTTON_H)")
			and has(sd, "local YIELD = GameConfig.ContextSlot.YieldPrefix .. \"Minigame\"")
			and has(sd, "player:SetAttribute(YIELD, if want then true else nil)")
			and not has(sd, "SpeedMilestones.clearOf"),
		"PLAY MINIGAME stands in the strip's place while riding the mill, and the strip steps aside for it")
end)

if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nContextSlotSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
