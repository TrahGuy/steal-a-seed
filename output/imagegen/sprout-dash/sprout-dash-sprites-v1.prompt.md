# Sprout Dash sprites v1 — image prompts for Codex

The art for **Sprout Dash**, the minigame played while riding the mill (2026-10-08). A
little sprout runs right along a treadmill strip; the player hops over obstacles and
collects seed coins. The game is a 2D screen inside a studded Roblox UI panel, so these
are flat 2D sprites, side view.

Four generations, each ONE PNG sheet that Codex crops afterwards (write a sibling
`.crops.json` with the measured rectangles, as for `podnappers-boost-weather-icons-v1`).
Sheets A and B need real alpha. C and D are opaque.

**Already have, do NOT draw:** the seed coin (rbxassetid 97002362837712) and the gold
burst (138957621639655). No text anywhere: the UI draws every word, number and title.

---

## Shared style (paste at the top of every prompt)

> Style: clean, colourful, friendly premium Roblox cartoon game art for Podnappers, a
> botanical Roblox plant-monster game whose menus are bright studded LEGO-like panels.
> Flat 2D side-view sprites, bold near-black ink outlines of even thickness, broad simple
> shapes, chunky slightly blocky Roblox proportions, subtle bevel shading with one light
> from the upper left, crisp edge highlights. Saturated cheerful greens, warm browns and
> golds. Readable when drawn about 64 to 128 pixels tall. No photorealism, no fussy
> detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
> numbers, no watermark, no drawn grid lines, no cell backgrounds.

---

## A. The runner — `sprout-dash-runner-v1.png`

> [Shared style]
>
> Asset: ONE transparent PNG sprite sheet of a single original character: a small
> cheerful sprout creature — a round green seed-pod body with a pale cream belly, two
> big friendly eyes, a tiny smile, a bright green two-leaf sprig on top of its head,
> two short stubby legs with little brown feet, and tiny arms. The SAME character, same
> colours, same size and same outline weight in every frame.
>
> Canvas: exactly 2048 x 1024, a 4-column by 2-row grid of invisible 512 x 512 cells.
> Each frame centred horizontally in its cell. The character stands on one shared
> invisible baseline 64 pixels above the bottom of each cell, and its body fills about
> 300 pixels of height. At least 64 pixels of transparent margin inside every cell; no
> pixel crosses into another cell. Background must be real alpha transparency, not white
> and not a painted checkerboard.
>
> Every frame faces RIGHT (running toward the right edge), in strict side view.
>
> TOP ROW, a 4-frame run cycle that loops smoothly:
> 1. right foot forward on the ground, left foot back, arms swinging opposite
> 2. passing pose, body slightly higher, both feet under the body
> 3. left foot forward on the ground, right foot back
> 4. passing pose again, mirrored arms, body slightly higher
> The leaf sprig bounces a little through the cycle.
>
> BOTTOM ROW:
> 5. hop: mid-air, knees tucked up, arms raised, sprig blown back, body lifted
>    about 80 pixels above the baseline
> 6. hit: knocked back, leaning left with a surprised squinting face, one leaf
>    drooping, still on the baseline
> 7. ready: standing still facing right, feet on the baseline, eager smile
> 8. cheer: both arms up, big happy closed-eye smile, feet on the baseline
>
> Exactly eight frames, nothing else.

## B. Obstacles and effects — `sprout-dash-props-v1.png`

> [Shared style]
>
> Asset: ONE transparent PNG sprite atlas of eight separate original game props for a
> side-view runner, all sized to the same character scale as a small 300-pixel-tall
> sprout creature.
>
> Canvas: exactly 2048 x 1024, a 4-column by 2-row grid of invisible 512 x 512 cells,
> one prop per cell, centred horizontally. Ground props sit on a shared invisible
> baseline 64 pixels above the bottom of each cell. At least 64 pixels of transparent
> margin inside every cell; nothing crosses into another cell. Real alpha transparency.
>
> TOP ROW, obstacles (the runner hops over these; each must read instantly as "jump
> over me"):
> 1. a chunky grey boulder with two mossy patches, about 150 pixels tall
> 2. a thorny purple weed clump with spiky leaves, about 170 pixels tall
> 3. a short fallen wooden log lying across the path, round end facing the viewer,
>    about 120 pixels tall and 300 wide
> 4. a cracked clay flower pot tipped on its side, about 140 pixels tall
>
> BOTTOM ROW, effects and lives:
> 5. a full red heart with a white highlight (a life), about 160 pixels, centred
>    vertically in its cell
> 6. the same heart empty: dark grey interior, same outline (a lost life)
> 7. a small dust puff of three soft round cartoon clouds (the hop's take-off), on
>    the baseline
> 8. a bold yellow and white star-burst impact spark (the hit), centred vertically
>
> Exactly eight props, nothing else.

## C. The treadmill strip — `sprout-dash-ground-v1.png`

> [Shared style]
>
> Asset: ONE opaque PNG that tiles SEAMLESSLY left to right: the running surface for a
> side-view runner game, a chunky treadmill belt seen straight from the side. A dark
> charcoal rubber belt with evenly spaced raised ridges on its top surface, sitting on
> a sturdy warm brown wooden frame with gold rivets, a thin green grass edge along the
> very top. The left and right edges must match exactly so the strip repeats with no
> visible seam; the ridges are evenly spaced so an integer number fit across.
>
> Canvas: exactly 2048 x 512, the belt's top surface a straight horizontal line 96
> pixels below the top of the image. No characters, no props, no text.

## D. Backdrop (optional) — `sprout-dash-backdrop-v1.png`

> [Shared style, but soft]
>
> Asset: ONE opaque PNG backdrop that tiles SEAMLESSLY left to right, for behind a
> side-view runner game: a calm sunny garden — soft blue sky with a few rounded
> clouds, gentle green hills, distant rows of blocky Roblox-style garden plots and a
> few round trees. Pale and low-contrast so bright sprites in front of it read clearly;
> softer outlines than the sprites. Nothing in the bottom 25 percent but plain grass
> colour (the treadmill strip covers it). No characters, no text.
>
> Canvas: exactly 2048 x 1024; the left and right edges match exactly.

---

## Constraints that matter for the game, not the picture

* **Real transparency on A and B.** The owner's first Speed-shoe uploads came on a
  black square. Check a corner pixel's alpha is 0 before handing them over.
* **One baseline, one scale.** The game moves a frame by swapping ImageRectOffset, so
  if the feet or the size jump between frames the runner visibly hops in place.
* **Facing right**, strict side view: the course scrolls from right to left.
* **No text.** Distance, coins, lives, titles and buttons are all drawn by the UI.

## What happens to the files

1. Codex crops each sheet into its cells and records the rectangles in a sibling
   `.crops.json`. Report the real output dimensions, which may differ from the request.
2. Downscale each sheet to at most 1024 px wide before upload (Roblox stores larger
   images at 1024). The runner sheet becomes 1024 x 512 (256-px cells), the props sheet
   1024 x 512, the strip 1024 x 256, the backdrop 1024 x 512.
3. The owner uploads them as **Images** to the CrazyCozy Games group and sends the ids.
   Claude checks them (Edit IsLoaded, a transparency capture) and sets
   `GameConfig.SproutDash.Art`.
