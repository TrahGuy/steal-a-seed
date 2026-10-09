# Rebirth panel icons v1 — image prompt for Codex

Four icons for the REBIRTH panel (2026-10-08). The panel draws every word, number and
the mill itself (the real Inferno Forge model, live in 3D), so these are small
supporting icons only. One sheet; Codex crops it into four and writes a sibling
`rebirth-icons-v1.crops.json`, as for the other sheets.

## The prompt

> Style: clean, colourful, friendly premium Roblox cartoon HUD illustrations for
> Podnappers, a botanical Roblox plant-monster game whose menus are bright studded
> LEGO-like panels. Bold near-black ink outlines of even thickness, broad simple shapes,
> subtle bevel shading with one light from the upper left, crisp edge highlights,
> saturated cheerful colours. Readable at 32 to 64 pixels. No photorealism, no fussy
> detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
> numbers, no watermark, no drawn grid lines, no cell backgrounds.
>
> Asset: ONE transparent PNG icon atlas, exactly 2048 x 512: four invisible 512 x 512
> cells in one row, one icon per cell, each centred and kept inside the central 360 x
> 360 area with at least 76 pixels of transparent margin. Same perceived size and the
> same outline weight across all four. Real alpha transparency, not white and not a
> painted checkerboard.
>
> Left to right:
> 1. REBIRTH EMBLEM: a bright green sprout with two leaves rising out of a cracked
>    open golden seed pod, circled by a bold magenta-pink circular arrow that loops
>    round it (the cycle of starting again). Hopeful and powerful.
> 2. MILL: a chunky treadmill seen from the front-left three-quarter view — a dark
>    ridged running belt on a warm wooden frame with a small console post at the
>    front and two gold rivets. No character on it.
> 3. CASH RESET: a short stack of three gold coins with a green leaf emblem, and a
>    bold red curved arrow sweeping down and round in front of them (the cash goes).
> 4. TITLE BADGE: a small golden laurel wreath of leaves open at the top, with a tiny
>    green sprout in its centre (an earned title).
>
> Exactly four icons, nothing else.

## After generating

1. Check real transparency (a corner pixel's alpha is 0). Report the real size.
2. Crop into four 512 cells, then downscale the sheet to 1024 x 256 for upload.
3. The owner uploads it as an **Image** to the CrazyCozy Games group and sends the id;
   Claude checks it (Edit IsLoaded, a transparency capture) and wires it.
