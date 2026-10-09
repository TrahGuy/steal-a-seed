# Rebirth effects v1 — image prompts for Codex

Particle textures for the REBIRTH moment and the top rebirth titles (2026-10-08). The owner
asked whether effects are needed. The answer was one burst when a player rebirths, seen by
everyone near them, plus a faint aura for the highest titles. They are nature-themed
(golden pollen, leaves, a sprout's light), not lightning or void: the game is a cozy
botanical one.

These are NOT icons. Roblox's ParticleEmitter draws them, many at a time, small, moving,
tinted and fading. That changes the rules:

- **Flipbooks** are one square image cut into an even grid. Roblox plays the cells
  left to right, top row first. Allowed grids are 2x2, 4x4 and 8x8. The image is at most
  1024 x 1024, because uploads are stored at 1024.
- **Tintable** sheets (B, C, D) are drawn in WHITE and light grey only. The game colours
  each particle with the player's title colour (GAIA's is a rainbow). Anything already
  coloured would muddy that.
- **Real alpha is a must.** Glows especially come back on a black background. A black
  background is unusable: it draws as a black square in the game.

Four generations, each ONE PNG. No crops.json is needed: the game cuts the grid itself.
Instead, write a sibling `<name>.notes.md` for each one. It gives the real pixel size, the
grid, the corner pixel's alpha, and a line confirming that every frame sits inside its
own cell.

**Already have, do NOT draw:** the rebirth emblem, title badge and cash-reset icons, which
are uploaded and wired. No text anywhere.

---

## Shared style (paste at the top of every prompt)

> Style: clean, bright, friendly cartoon game VFX for Podnappers, a cozy botanical
> Roblox plant-monster game. Cel-shaded, simple bold shapes, smooth soft-edged glows,
> crisp silhouettes that read when drawn only 16 to 64 pixels on screen. Thin, even
> outlines on solid shapes such as leaves; NO outlines on glows, light and sparkles.
> No photorealism, no smoke realism, no lightning, no dark or scary energy, no fussy
> detail, no text, no letters, no numbers, no watermark, no drawn grid lines, no cell
> backgrounds, no ground, no shadows. Background must be real alpha transparency — not
> black, not white, not a painted checkerboard — with clean soft alpha edges and no dark
> fringe.

---

## A. The rebirth burst — `rebirth-burst-v1.png`

Played ONCE where the player stands when they rebirth, about 12 studs across. Its
colours are baked in, because this is the rebirth's own look.

> [Shared style]
>
> Asset: ONE transparent PNG flipbook, exactly 1024 x 1024, a 4 x 4 grid of invisible
> 256 x 256 cells — 16 frames, read left to right, top row first. Every frame is
> centred on its cell's exact centre and stays inside its cell with at least 8 pixels of
> transparent margin; nothing crosses into another cell.
>
> The animation, one burst that plays once, seen from the front:
> - Frames 1–3: a small bright white-gold flash at the centre swells quickly, with a
>   tiny green sprout of two leaves popping up out of it.
> - Frames 4–10: a ring of warm golden light expands outward from the centre toward the
>   cell's edge, thick at first, then thinner. A few small bright green leaves and round
>   golden pollen dots fly outward with the ring, spinning. The central flash fades as
>   the ring grows.
> - Frames 11–16: the ring reaches about 90% of the cell, thins to a faint golden line,
>   and dissolves into scattered fading pollen dots; frame 16 is almost empty — only a
>   few faint dots.
>
> Colours: white-gold core, warm gold ring (#FFD34D to #FFB020), fresh green leaves
> (#7BE04A to #3FB84A), a touch of soft pink (#FF6FCF) only in the very first flash.
> Exactly 16 frames, nothing else.

## B. Tumbling leaf — `rebirth-leaf-v1.png` (tintable)

About 20 leaves swirl up around the player for a second and a half with the burst, coloured
by the new title. The same leaves feed the aura in D.

> [Shared style]
>
> Asset: ONE transparent PNG flipbook, exactly 512 x 512, a 2 x 2 grid of invisible
> 256 x 256 cells — 4 frames, left to right, top row first, that LOOP smoothly: a single
> simple rounded leaf with a short stem and one centre vein, tumbling through the air.
> Frame 1 the leaf seen flat and wide; frame 2 turned so it looks narrower; frame 3 seen
> edge-on (a thin sliver); frame 4 turning back, narrower again — so frame 4 flows into
> frame 1. Each leaf centred in its cell, filling about 70% of it.
>
> Drawn in WHITE and very light grey only (the game tints it): a white leaf, light grey
> soft shading on one side, a thin light grey outline and vein. No green, no other
> colour. Exactly 4 frames.

## C. Pollen sparkle — `rebirth-sparkle-v1.png` (tintable)

Small twinkles that drift up with the leaves, and the main part of the aura in D.

> [Shared style]
>
> Asset: ONE transparent PNG flipbook, exactly 512 x 512, a 2 x 2 grid of invisible
> 256 x 256 cells — 4 frames that play once per particle: a round soft glowing pollen
> mote that twinkles.
> - Frame 1: a small soft glowing dot.
> - Frame 2: brighter and larger, with four short soft rays in a plus shape.
> - Frame 3: at its brightest, the four rays longer and four shorter diagonal rays between them.
> - Frame 4: fading back to a small dim dot.
> Each centred on its cell's centre; the longest ray stays inside the cell with 16
> pixels of margin.
>
> Pure WHITE only, brightest at the centre, fading smoothly to fully transparent at the
> edges (the game tints and adds its glow). No colour, no outline. Exactly 4 frames.

## D. Title aura wisp — `rebirth-aura-v1.png` (tintable)

A FAINT, slow aura around players with the top titles (WORLD TREE at rebirth 50 and above),
coloured by their title. It must never hide the character, so it is soft and mostly
transparent.

> [Shared style]
>
> Asset: ONE transparent PNG flipbook, exactly 1024 x 1024, a 4 x 4 grid of invisible
> 256 x 256 cells — 16 frames, left to right, top row first, that LOOP seamlessly
> (frame 16 flows into frame 1): a soft rising wisp of light, like a gentle upward
> flame made of light, slowly swaying left and right as it rises, with two or three
> tiny leaf shapes and pollen dots carried up inside it. The wisp's base sits near the
> bottom-centre of each cell and its tip near the top; it is about 40% of the cell
> wide at its widest.
>
> WHITE and light grey only (the game tints it), soft and mostly transparent — the
> brightest part no more than about 70% opaque, edges fading to fully transparent.
> No hard outline except thin light grey lines on the tiny leaves. Exactly 16 frames.

---

## After generating

1. Check real transparency for each sheet: a corner pixel's alpha is 0 and there is no black
   background or dark fringe. Report the real size.
2. Check the grid: every frame is inside its own cell and centred where the prompt says. In A
   and D, frame 16 must lead into frame 1 (D) or be almost empty (A).
3. Keep the sizes exactly as asked (1024 or 512 square). Do not crop and do not pad: the
   game cuts the grid by the image's size.
4. Write each `<name>.notes.md` (size, grid, frame order, alpha check).
5. The owner uploads each one as an **Image** to the CrazyCozy Games group and sends the
   four ids.
   - Claude checks them: economy details, Edit IsLoaded, alpha.
   - The terminal Claude builds the effects: the burst at rebirth (everyone nearby sees it),
     the leaves and sparkles tinted by the new title, and the aura from rebirth 50.
   - REDUCED FX in Settings switches all of them off.
