# Rebirth FX v1 — exact prompts used

Built-in image generation/editing only; no CLI/API fallback. Four requested sheets were generated separately. The supplied rebirth-fx-v1.prompt.md remains unchanged. Selected originals and exact-size drafts are preserved. The unsuccessful burst correction is not selected. On 2026-10-09 the owner authorized finishing the images; offline alpha/RGB export cleanup was then applied, retaining the exact sheet sizes and grids without cropping, padding or repacking. Final PNGs and animation previews now exist; Studio/loop acceptance is still pending. The exact original prompts below are unchanged.

## A — burst generation

Use case: stylized-concept.
Style: clean, bright, friendly cartoon game VFX for Podnappers, a cozy botanical
Roblox plant-monster game. Cel-shaded, simple bold shapes, smooth soft-edged glows,
crisp silhouettes that read when drawn only 16 to 64 pixels on screen. Thin, even
outlines on solid shapes such as leaves; NO outlines on glows, light and sparkles.
No photorealism, no smoke realism, no lightning, no dark or scary energy, no fussy
detail, no text, no letters, no numbers, no watermark, no drawn grid lines, no cell
backgrounds, no ground, no shadows. Background must be real alpha transparency — not
black, not white, not a painted checkerboard — with clean soft alpha edges and no dark
fringe.

Asset: ONE transparent PNG flipbook, exactly 1024 x 1024, a 4 x 4 grid of invisible
256 x 256 cells — 16 frames, read left to right, top row first. Every frame is
centred on its cell's exact centre and stays inside its cell with at least 8 pixels of
transparent margin; nothing crosses into another cell.

The animation, one burst that plays once, seen from the front:
- Frames 1–3: a small bright white-gold flash at the centre swells quickly, with a
  tiny green sprout of two leaves popping up out of it.
- Frames 4–10: a ring of warm golden light expands outward from the centre toward the
  cell's edge, thick at first, then thinner. A few small bright green leaves and round
  golden pollen dots fly outward with the ring, spinning. The central flash fades as
  the ring grows.
- Frames 11–16: the ring reaches about 90% of the cell, thins to a faint golden line,
  and dissolves into scattered fading pollen dots; frame 16 is almost empty — only a
  few faint dots.

Colours: white-gold core, warm gold ring (#FFD34D to #FFB020), fresh green leaves
(#7BE04A to #3FB84A), a touch of soft pink (#FF6FCF) only in the very first flash.
Exactly 16 frames, nothing else.
Production constraint: this is a ParticleEmitter animation texture, not an icon sheet. Keep equal cells, no visible grid and genuine transparent gutters. No black matte or dark fringe.

## B — leaf generation

Use case: stylized-concept.
Style: clean, bright, friendly cartoon game VFX for Podnappers, a cozy botanical
Roblox plant-monster game. Cel-shaded, simple bold shapes, smooth soft-edged glows,
crisp silhouettes that read when drawn only 16 to 64 pixels on screen. Thin, even
outlines on solid shapes such as leaves; NO outlines on glows, light and sparkles.
No photorealism, no smoke realism, no lightning, no dark or scary energy, no fussy
detail, no text, no letters, no numbers, no watermark, no drawn grid lines, no cell
backgrounds, no ground, no shadows. Background must be real alpha transparency — not
black, not white, not a painted checkerboard — with clean soft alpha edges and no dark
fringe.

Asset: ONE transparent PNG flipbook, exactly 512 x 512, a 2 x 2 grid of invisible
256 x 256 cells — 4 frames, left to right, top row first, that LOOP smoothly: a single
simple rounded leaf with a short stem and one centre vein, tumbling through the air.
Frame 1 the leaf seen flat and wide; frame 2 turned so it looks narrower; frame 3 seen
edge-on (a thin sliver); frame 4 turning back, narrower again — so frame 4 flows into
frame 1. Each leaf centred in its cell, filling about 70% of it.

Drawn in WHITE and very light grey only (the game tints it): a white leaf, light grey
soft shading on one side, a thin light grey outline and vein. No green, no other
colour. Exactly 4 frames.
Production constraint: this is a ParticleEmitter animation texture, not an icon sheet. Keep equal cells, no visible grid and genuine transparent gutters. No black matte or dark fringe.

## C — sparkle generation

Use case: stylized-concept.
Style: clean, bright, friendly cartoon game VFX for Podnappers, a cozy botanical
Roblox plant-monster game. Cel-shaded, simple bold shapes, smooth soft-edged glows,
crisp silhouettes that read when drawn only 16 to 64 pixels on screen. Thin, even
outlines on solid shapes such as leaves; NO outlines on glows, light and sparkles.
No photorealism, no smoke realism, no lightning, no dark or scary energy, no fussy
detail, no text, no letters, no numbers, no watermark, no drawn grid lines, no cell
backgrounds, no ground, no shadows. Background must be real alpha transparency — not
black, not white, not a painted checkerboard — with clean soft alpha edges and no dark
fringe.

Asset: ONE transparent PNG flipbook, exactly 512 x 512, a 2 x 2 grid of invisible
256 x 256 cells — 4 frames that play once per particle: a round soft glowing pollen
mote that twinkles.
- Frame 1: a small soft glowing dot.
- Frame 2: brighter and larger, with four short soft rays in a plus shape.
- Frame 3: at its brightest, the four rays longer and four shorter diagonal rays between them.
- Frame 4: fading back to a small dim dot.
Each centred on its cell's centre; the longest ray stays inside the cell with 16
pixels of margin.

Pure WHITE only, brightest at the centre, fading smoothly to fully transparent at the
edges (the game tints and adds its glow). No colour, no outline. Exactly 4 frames.
Production constraint: this is a ParticleEmitter animation texture, not an icon sheet. Keep equal cells, no visible grid and genuine transparent gutters. No black matte or dark fringe.

## D — aura generation

Use case: stylized-concept.
Style: clean, bright, friendly cartoon game VFX for Podnappers, a cozy botanical
Roblox plant-monster game. Cel-shaded, simple bold shapes, smooth soft-edged glows,
crisp silhouettes that read when drawn only 16 to 64 pixels on screen. Thin, even
outlines on solid shapes such as leaves; NO outlines on glows, light and sparkles.
No photorealism, no smoke realism, no lightning, no dark or scary energy, no fussy
detail, no text, no letters, no numbers, no watermark, no drawn grid lines, no cell
backgrounds, no ground, no shadows. Background must be real alpha transparency — not
black, not white, not a painted checkerboard — with clean soft alpha edges and no dark
fringe.

Asset: ONE transparent PNG flipbook, exactly 1024 x 1024, a 4 x 4 grid of invisible
256 x 256 cells — 16 frames, left to right, top row first, that LOOP seamlessly
(frame 16 flows into frame 1): a soft rising wisp of light, like a gentle upward
flame made of light, slowly swaying left and right as it rises, with two or three
tiny leaf shapes and pollen dots carried up inside it. The wisp's base sits near the
bottom-centre of each cell and its tip near the top; it is about 40% of the cell
wide at its widest.

WHITE and light grey only (the game tints it), soft and mostly transparent — the
brightest part no more than about 70% opaque, edges fading to fully transparent.
No hard outline except thin light grey lines on the tiny leaves. Exactly 16 frames.
Production constraint: this is a ParticleEmitter animation texture, not an icon sheet. Keep equal cells, no visible grid and genuine transparent gutters. No black matte or dark fringe. The 16 frames are one smooth repeating sway; the last pose must almost match the first, not fade away or grow from an empty start.

## A — attempted gutter correction, not selected

Use case: precise-object-edit.
Edit target: the supplied 16-frame botanical rebirth burst flipbook.
Correct ONLY the grid registration and transparent gutters, and remove the noisy oversized haze. Keep the same gold/green botanical burst progression, two-leaf sprout in early frames, outward-expanding rings/leaves/pollen, late dissolution, and almost-empty final frame.
One square PNG, ideally1024x1024, exactly4 columns and4 rows. At final1024 size each cell is256x256. Effect centers MUST lie on the regular coordinates (128,128),(384,128),(640,128),(896,128), and the equivalent four centers in each later row. Use normalized cell-centres12.5%,37.5%,62.5%,87.5% if native size differs.
CRITICAL: every frame is an ISOLATED effect with genuinely empty transparent borders. All visible artwork INCLUDING soft glow and flying dots/leaves stays inside the central224x224 of each256x256 cell, leaving16 transparent pixels on ALL FOUR cell sides. Leave32px-wide transparent gaps between neighboring frame artwork. No connected glow columns or merging rings. Ring centre stays fixed; only radius expands. Maximum ring radius about100px so outer particles/glow can still stay within the protected border.
Frames1–3 small core/sprout;4–10 expanding warm golden ring with just a few green leaves and round dots;11–15 thinner ring dissolving into fading dots;16 just3–4 faint dots, nearly empty.
Smooth clean alpha edges and a restrained soft gold glow. Remove the grainy speckled cloud/noisy halo that currently spills over the cells. No pink after the first few frames, no outlines on light, no letters/numbers/grid/background. True alpha0 in all margins. Do not turn this into icons or change the frame order.
