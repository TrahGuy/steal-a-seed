--!strict
--==============================================================================
-- Steal a Seed :: PerformanceMode (2026-10-11, the owner: the HUD's OTHER PLANTS
-- switch became PERFORMANCE MODE)
--
-- ON: other players' grown plants are not drawn on this screen (PlantVisibility,
-- as OTHER PLANTS: OFF did) AND Reduced FX is on. OFF: every garden drawn, and
-- Reduced FX back to the player's own choice -- never switched off if they had
-- switched it on themselves (GameConfig.OtherPlants says the rest).
--
-- THE ONE VALUE EVERY EFFECT ALREADY READS. Reduced FX is the local quality
-- attribute (GameConfig.Afterimage.QualityAttribute, "Off" = Reduced FX on):
-- StatusText.reducedMotion() reads it, and so does every effect that asks it
-- directly. So the rule "reduced = the player's own Reduced FX OR Performance
-- Mode" is kept IN that attribute: while Performance Mode is on it says "Off",
-- and the player's own value waits in OwnQualityAttribute until it turns off.
-- No effect needs to know Performance Mode exists; each one that follows the
-- attribute live follows the switch live.
--
-- Local only: this client writes it, nothing is sent, nothing is saved.
--
-- THREE LEVELS (2026-10-13, the owner: "insert a level 3 switch on performance
-- mode, when turned level 3, owned plants will be hidden too"): OFF, ON, and
-- ULTRA -- ON with this player's own grown plants hidden as well
-- (PlantVisibility's hideOwn). One press steps OFF, ON, ULTRA, then OFF again
-- (nextLevel). ON and ULTRA are both "on" for Reduced FX (isOn).
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlantVisibility = require(Shared:WaitForChild("PlantVisibility"))

local PerformanceMode = {}

local QUALITY = GameConfig.Afterimage.QualityAttribute
local OWN = GameConfig.OtherPlants.OwnQualityAttribute

-- What OwnQualityAttribute holds for "the player never chose" (an attribute
-- cannot hold nil and still say it is there).
PerformanceMode.Unset = "Unset"

-- Whether Performance Mode is on for `player` on this screen.
function PerformanceMode.isOn(player: Player): boolean
	return not PlantVisibility.showOthers(player)
end

-- The quality a screen gets when nobody chose one: SettingsUI's own rule (a
-- touch-only screen Reduced, everything else Full).
function PerformanceMode.deviceQuality(): string
	return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then "Reduced" else "Full"
end

-- The player's OWN Reduced FX choice: while Performance Mode holds the
-- attribute, the value it put aside; otherwise the attribute itself.
function PerformanceMode.ownReduced(player: Player): boolean
	local own = player:GetAttribute(OWN)
	if type(own) == "string" then
		return own == "Off"
	end
	return player:GetAttribute(QUALITY) == "Off"
end

-- Turns Performance Mode on (ON, never ULTRA) or off on this screen.
function PerformanceMode.set(player: Player, on: boolean)
	if on then
		-- Put the player's own choice aside once, however often this is called.
		if player:GetAttribute(OWN) == nil then
			local q = player:GetAttribute(QUALITY)
			player:SetAttribute(OWN, if type(q) == "string" then q else PerformanceMode.Unset)
		end
		player:SetAttribute(QUALITY, "Off")
		PlantVisibility.setHideOwn(player, false)
		PlantVisibility.setShowOthers(player, false)
		return
	end
	local own = player:GetAttribute(OWN)
	player:SetAttribute(OWN, nil)
	if type(own) == "string" then
		-- Never chosen: the screen's own default, as Settings gives it back (an
		-- effect reads a cleared attribute as "no change", not as the default).
		player:SetAttribute(QUALITY, if own == PerformanceMode.Unset then PerformanceMode.deviceQuality() else own)
	end
	PlantVisibility.setHideOwn(player, false)
	PlantVisibility.setShowOthers(player, true)
end

--==============================================================================
-- THE THREE LEVELS
--==============================================================================
export type Level = "off" | "on" | "ultra"

PerformanceMode.Levels = { "off", "on", "ultra" } :: { Level }

-- The level `player` is at on this screen.
function PerformanceMode.level(player: Player): Level
	if not PerformanceMode.isOn(player) then
		return "off"
	end
	return if PlantVisibility.hideOwn(player) then "ultra" else "on"
end

-- The level one press goes to: OFF, ON, ULTRA, then OFF again. Pure.
function PerformanceMode.nextLevel(level: string): Level
	if level == "off" then
		return "on"
	elseif level == "on" then
		return "ultra"
	end
	return "off"
end

-- Puts `player` at `level` on this screen: ON's work for ON and ULTRA, and
-- ULTRA's own plants hidden after it.
function PerformanceMode.setLevel(player: Player, level: string)
	if level == "on" or level == "ultra" then
		PerformanceMode.set(player, true)
		PlantVisibility.setHideOwn(player, level == "ultra")
	else
		PerformanceMode.set(player, false)
	end
end

return PerformanceMode
