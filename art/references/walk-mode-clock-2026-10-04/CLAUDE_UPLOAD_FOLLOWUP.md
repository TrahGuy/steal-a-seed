# Cycle icon upload follow-up

The owner supplied these uploaded Image IDs in a screenshot:

- Moon/cloud: `rbxassetid://123862305697349`
- Sun/cloud: `rbxassetid://138878981553342`

Wire these into `GameConfig.WorldCycle.ClockIcons.Moon` and `.Sun`. Verify the images actually load; keep the existing native fallback until each image has loaded successfully. These IDs have been transcribed from the screenshot, not independently verified in Roblox.

Preserve the existing phase logic: moon for the countdown to night, sun for the countdown to dawn. Normal countdown text stays white, including throughout night; red only during DAY when the remaining time is within the configured WarnSeconds window. Do not change cycle durations, lighting, Walk Mode or other gameplay.

Use focused compilation and Edit image-loading checks first. Report any loading/permission failure and anything unverified. No unnecessary additional Play session, and do not commit, push or publish.
