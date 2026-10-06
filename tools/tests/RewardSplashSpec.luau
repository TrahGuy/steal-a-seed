--!nocheck
--==============================================================================
-- Steal a Seed :: RewardSplashSpec
--
-- The Bonus Chest's reward splash (2026-10-01, the owner's ask). Edit mode:
-- RewardSplash's numbers and its card, built on a throwaway ScreenGui, and
-- BonusChestUI's wiring read from its source -- played only for a claim the
-- server confirmed, with the reward the server named, once per claim, without
-- the flight under reduced motion, landing on that reward's line in the row.
--
-- Not here: the animation itself (Edit runs no frames for it) and a real claim
-- -- those are the Play check.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local RewardSplash = require(Shared:WaitForChild("RewardSplash"))
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Server = ServerScriptService:WaitForChild("SeedGameServer")

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
local V2 = Vector2.new

local layer = Instance.new("ScreenGui")
layer.Name = "ZZRewardSplashSpec"
layer.Archivable = false

local ok, err = pcall(function()
	--==========================================================================
	-- 1. THE NUMBERS
	--==========================================================================
	say("-- the numbers --")
	local S = RewardSplash
	check(S.scaleFor(V2(1280, 720)) == 1 and math.abs(S.scaleFor(V2(856, 716)) - 716 / 720) < 1e-6
			and S.scaleFor(V2(705, 338)) == 0.62 and S.scaleFor(V2(390, 844)) == 0.62
			and S.scaleFor(V2(2560, 1440)) == 1.15,
		"sized for the screen: 1 at 720 tall, a phone's never under 0.62, a big monitor's at most 1.15")
	local from, to = V2(400, 300), V2(640, 40)
	local p0, e0 = S.flight(from, to, 0)
	local p1, e1 = S.flight(from, to, 1)
	local pm, em = S.flight(from, to, 0.5)
	local straight = from:Lerp(to, em)
	check(p0 == from and e0 == 0 and p1 == to and e1 == 1 and pm.Y < straight.Y - 1 and em > 0 and em < 1,
		"the flight starts on the card, ends exactly on the destination, and lifts in a low arc between",
		tostring(pm) .. " vs " .. tostring(straight))
	local last, monotone = -1, true
	for i = 0, 20 do
		local _, e = S.flight(from, to, i / 20)
		monotone = monotone and e >= last
		last = e
	end
	check(monotone, "and the shrink only ever grows toward the destination's size")

	--==========================================================================
	-- 2. WHERE AN ICON MAY LAND
	--==========================================================================
	say("\n-- where it may land --")
	layer.Parent = StarterGui
	local hidden = Instance.new("Frame")
	hidden.Size = UDim2.fromOffset(20, 20)
	hidden.Visible = false
	hidden.Parent = layer
	local inside = Instance.new("Frame")
	inside.Size = UDim2.fromOffset(20, 20)
	inside.Parent = hidden
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(0, 0)
	box.Parent = layer
	check(S.pointIn(nil, layer) == nil and S.pointIn(inside, layer) == nil and S.pointIn(box, layer) == nil,
		"nowhere to land: nothing, something under a hidden parent, or something with no size")
	hidden.Visible = true
	layer.Enabled = false
	check(S.pointIn(inside, layer) == nil, "nor anything in a gui that is switched off")
	layer.Enabled = true
	local view = layer.AbsoluteSize
	if view.X > 0 then
		local at = S.pointIn(inside, layer)
		check(at ~= nil and (at - (inside.AbsolutePosition + inside.AbsoluteSize / 2 - layer.AbsolutePosition)).Magnitude
				< 1e-3,
			"a shown one: its middle, in the splash's own space", tostring(at))
	else
		check(false, "Studio gave the throwaway gui no size in Edit: the shown case is the Play check's")
	end

	--==========================================================================
	-- 3. THE CARD
	--==========================================================================
	say("\n-- the card --")
	local drawn = 0
	local function item(title, detail)
		return {
			draw = function(parent, px)
				drawn += 1
				local f = Instance.new("Frame")
				f.Name = "Shape"
				f.AnchorPoint = Vector2.new(0.5, 0.5)
				f.Position = UDim2.fromScale(0.5, 0.5)
				f.Size = UDim2.fromOffset(px * 0.8, px * 0.8)
				f.ZIndex = 3
				f.Parent = parent
			end,
			title = title,
			detail = detail,
			tint = Color3.fromRGB(38, 255, 0),
			destination = function()
				return nil
			end,
		}
	end
	if view.X > 0 then
		local built = S.build({
			layer = layer,
			heading = "BONUS CHEST",
			reduced = false,
			items = { item("+25% PLANT INCOME", "BOOST FOR 2 MIN"), item("+25% TRAINING", "BOOST FOR 2 MIN") },
		})
		local ok2 = built ~= nil and #built.pieces == 2 and drawn == 2
		local titles, aboveCard = 0, true
		if ok2 then
			for _, d in ipairs(built.card:GetDescendants()) do
				if d:IsA("TextLabel") and (d.Text == "+25% PLANT INCOME" or d.Text == "+25% TRAINING") then
					titles += 1
				end
			end
			for _, piece in ipairs(built.pieces) do
				for _, d in ipairs(piece.holder:GetDescendants()) do
					if d:IsA("GuiObject") and d.ZIndex <= built.card.ZIndex then
						aboveCard = false
					end
				end
			end
		end
		check(ok2 and titles == 2, "a group: one column per reward, each with its icon, name and amount")
		check(ok2 and aboveCard, "every icon draws above the card's plate, whatever the gui's ZIndexBehavior")
		check(ok2 and built.card.Size.X.Offset * built.k <= view.X * S.MaxWidthShare + 0.5
				and built.k <= S.scaleFor(view) + 1e-6,
			"never wider than most of the screen", ok2 and string.format("%.0f of %.0f", built.card.Size.X.Offset * built.k,
				view.X) or nil)
		if built then
			built.card:Destroy()
		end
		check(S.build({ layer = layer, items = {}, reduced = false }) == nil, "nothing to show: nothing is drawn")
	else
		check(false, "the card is built in Play only on this Studio (no size in Edit)")
	end

	--==========================================================================
	-- 4. THE MOTION RULES, FROM THE SOURCE
	--==========================================================================
	say("\n-- the motion rules --")
	local src = sourceOf(Shared, "RewardSplash")
	local stillAt = string.find(src, "if opts.reduced then", 1, true) or 0
	local launchAt = string.find(src, "launch()\n", stillAt, true) or 0
	local stillBlock = string.sub(src, stillAt, launchAt)
	check(stillAt > 0 and launchAt > stillAt and has(stillBlock, "return\n\t\tend") and not has(stillBlock, "launch()"),
		"reduced motion: in, hold, out -- it returns before anything flies")
	check(select(2, string.gsub(src, "RenderStepped:Connect", "")) == 1 and has(src, "c:Disconnect()")
			and has(src, "RewardSplash.stop()\n\tlocal built"),
		"one frame connection while it plays, dropped at the end; a new splash ends the old one first")
	check(has(src, "Nowhere to go any more: it fades where it is") and has(src, "table.insert(staying, piece)"),
		"no destination, or one that goes mid-flight: the icon fades where it is")

	--==========================================================================
	-- 5. THE CHEST'S WIRING
	--==========================================================================
	say("\n-- the Bonus Chest --")
	local chest = sourceOf(Scripts, "BonusChestUI")
	local okAt = string.find(chest, "if payload.ok == true then", 1, true) or 0
	local refusedAt = string.find(chest, "local reason = tostring(payload.reason)", okAt, true) or 0
	local okBlock = string.sub(chest, okAt, refusedAt)
	local refusedBlock = string.sub(chest, refusedAt, refusedAt + 900)
	check(okAt > 0 and refusedAt > okAt and has(okBlock, "splash(reward)")
			and has(okBlock, "GameConfig.bonusChestReward(payload.reward)") and not has(refusedBlock, "splash(")
			and select(2, string.gsub(chest, "splash%(reward%)", "")) == 1,
		"only a claim the server confirmed plays it, with the reward the server named; a refusal never does")
	check(has(okBlock, "string.format(\"%s:%s\", tostring(payload.nextAt), tostring(payload.reward))")
			and has(okBlock, "if key ~= lastClaimShown then"),
		"once per claim: the same answer delivered again shows nothing")
	check(has(chest, "reduced = StatusText.reducedMotion(),") and has(chest, "layer = gui,"),
		"it honours reduced motion, and draws in the row's own gui, so the flight and the row share one space")
	check(has(chest, "local icon = boostIcon(id)") and has(chest, 'icon:FindFirstChild("Icon", true)')
			and has(chest, 'icon:FindFirstChild("Pop")') and has(chest, "WheelDraw.icon(parent, icon, px)"),
		"the icon is the wheel's own for that boost, and it lands on that boost's ICON over the hotbar (2026-10-04)")
	check(has(okBlock, "if not (reward and splash(reward)) then") and has(okBlock, "Notice.post({"),
		"if it cannot draw, the old success notice says it instead")
	local service = sourceOf(Server, "BonusChestService")
	check(#service > 0 and not has(service, "RewardSplash") and not has(service, "splash"),
		"the server is untouched: the reward, the cooldown and the save are what they were")
end)

layer:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nRewardSplashSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
