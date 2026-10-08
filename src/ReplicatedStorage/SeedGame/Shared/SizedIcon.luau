--!strict
--==============================================================================
-- Steal a Seed :: SizedIcon
-- THE OWNER'S SMALL VERSIONS, DRAWN WHERE THEY BELONG (2026-10-08)
--
-- Some pictures come in two uploads: the big one, and a small one the owner
-- made for small draws (GameConfig.SmallIcons, keyed by the big id). The rule is
-- the owner's: the small one wherever the picture draws at
-- GameConfig.SmallIconMax px or less, the big one above that.
--
--   at(image, px)       which of the two to draw at `px` (pure). An unknown or
--                       zero size gives the big one.
--   follow(picture)     an ImageLabel that keeps to the rule as its drawn size
--                       changes: its shorter side (ScaleType.Fit draws a square
--                       picture that wide), after every UIScale over it. Only a
--                       picture whose image has a small version is watched;
--                       anything else is left exactly as it is.
--
-- Requires nothing but GameConfig, so the server can require a module that uses
-- it: follow() only connects when it is handed a picture.
--==============================================================================
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local SizedIcon = {}

-- The big upload behind either of the two ids, or nil when `image` has no small
-- version.
local bigOf: { [string]: string } = {}
for big, small in pairs(GameConfig.SmallIcons) do
	bigOf[big] = big
	bigOf[small] = big
end

function SizedIcon.bigOf(image: string): string?
	return bigOf[image]
end

function SizedIcon.at(image: string, px: number?): string
	local big = bigOf[image]
	if not big then
		return image
	end
	if px and px > 0 and px <= GameConfig.SmallIconMax then
		return GameConfig.SmallIcons[big]
	end
	return big
end

function SizedIcon.follow(picture: ImageLabel)
	local big = bigOf[picture.Image]
	if not big then
		return
	end
	local function pick()
		local size = picture.AbsoluteSize
		local px = math.min(size.X, size.Y)
		if px > 0 then
			local want = SizedIcon.at(big, px)
			if picture.Image ~= want then
				picture.Image = want
			end
		end
	end
	pick()
	picture:GetPropertyChangedSignal("AbsoluteSize"):Connect(pick)
end

return SizedIcon
