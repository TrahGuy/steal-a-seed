# Upload-ready copies (2026-10-04)

The two cycle icons, cropped to their art (2% margin, square) and resized to 512 x 512, so a
`ScaleType.Fit` square in the HUD clock draws them at full size. Made from the v1 originals one
folder up, which are untouched.

- `cycle-moon-cloud-512.png`: beside the countdown to night.
- `cycle-sun-cloud-512.png`: beside the countdown to dawn.

**Not uploaded.** Upload them under the experience's owner (the Podnappers group), then paste the
ids into `GameConfig.WorldCycle.ClockIcons` (`Moon`, `Sun`) as `rbxassetid://<id>`. Until then the
clock draws its native stand-ins (`UIKit.cycleIcon`). A set id replaces its stand-in only once the
picture has loaded in game.
