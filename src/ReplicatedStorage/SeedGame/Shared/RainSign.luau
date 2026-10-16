--!strict
--==============================================================================
-- Steal a Seed :: RainSign (2026-10-16, the owner: "add a Huge Rain Text biome
-- with a timer")
--
-- What the RAIN BIOME sign over the rain bridge says at a moment, from what the
-- server has published -- pure, so a spec can step it through every state
-- without a server -- and where it stands and how big it draws
-- (GameConfig.Weather.Sign says why). RainSign.client calls describe on a
-- change and once a second with Workspace:GetServerTimeNow(); nothing is
-- networked to count down.
--
--   no weather, the next mark ahead        "Next rain in 42:10"
--   the mark come, its start a moment off  "Starting…"
--   opening (falling, the entrance shut)   "Opening…"
--   active (the entrance open)             "OPEN · Closes in 2:31"
--   closing (the biome fading)             "Closing…"
--   no weather and no schedule             nothing under the header
--
-- A Thunderstorm is the same event and says the same.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))

local RainSign = {}

local W = GameConfig.Weather
local SIGN = W.Sign
local WORDS = SIGN.Words

export type View = {
	-- Weather.Attributes.State: "opening", "active", "closing", or nil.
	state: string?,
	endsAt: number?,
	-- Weather.Auto.NextAtAttribute: the next mark, a server time.
	nextAt: number?,
}

-- "0:07", "2:31", "42:10", "60:00": minutes and seconds, rounded UP (a timer
-- never reads 0:00 while time is left), the minutes as many digits as they need.
function RainSign.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds - 1e-6))
	return string.format("%d:%02d", s // 60, s % 60)
end

-- The line under RAIN BIOME at `now`, or nil for none.
function RainSign.describe(v: View, now: number): string?
	local state = v.state
	if state == "opening" then
		return WORDS.Opening
	end
	if state == "active" then
		local endsAt = v.endsAt
		if type(endsAt) ~= "number" or endsAt <= now then
			-- Its time is up; the server closes it on its next step.
			return WORDS.Closing
		end
		return string.format(WORDS.Open, RainSign.clock(endsAt - now))
	end
	if state == "closing" then
		return WORDS.Closing
	end
	local nextAt = v.nextAt
	if type(nextAt) ~= "number" then
		return nil
	end
	if nextAt <= now then
		return WORDS.Starting
	end
	return string.format(WORDS.Next, RainSign.clock(nextAt - now))
end

-- The height of its two lines in studs, as built.
function RainSign.tall(): number
	return SIGN.Height + SIGN.SubHeight
end

-- Its middle as built: over the foot of the bridge, on the deck's south half,
-- its bottom edge BottomAbove the ground.
function RainSign.at(): Vector3
	return Vector3.new(SIGN.X, (GameConfig.Map :: any).GroundY + SIGN.BottomAbove + RainSign.tall() / 2, SIGN.Z)
end

-- How many times its built studs it draws for a camera `distance` studs from
-- its middle: FloatingSign.clampScale with this sign's numbers.
function RainSign.scale(distance: number, viewportHeight: number, fieldOfView: number): number
	return FloatingSign.clampScale(distance, SIGN.Height, viewportHeight, fieldOfView, SIGN.MinHeaderUnits,
		SIGN.MaxHeaderShare)
end

-- Its width and height in studs at `scale`, and how far its middle rises so its
-- bottom edge stays where it is built.
function RainSign.frame(scale: number): (number, number, number)
	local tall = RainSign.tall()
	return SIGN.Width * scale, tall * scale, (scale - 1) * tall / 2
end

return RainSign
