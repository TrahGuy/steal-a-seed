# Rebirth icons v1 — deliverables and exact prompt

Generated 2026-10-08 using the built-in image tool, no CLI/API fallback. Owner brief: `rebirth-icons-v1.prompt.md`, preserved unchanged. This is supporting panel artwork only: no 3D Inferno Forge render, rebirth mechanics, receipt logic, text overlays or game integration.

## Upload and master sheets

- `rebirth-icons-v1-upload-1024.png`: 1024 × 256, four 256 × 256 cells. Recommended upload file from this brief.
- `rebirth-icons-v1-upload-1024.crops.json`: offsets 0, 256, 512, 768 on x; y0; each size256 ×256. Use this manifest for the uploaded sheet.
- `rebirth-icons-v1.png`: normalized 2048 × 512 master, four 512 × 512 cells.
- `rebirth-icons-v1.crops.json`: master coordinates plus measured native crop/scale data. Do NOT use its 512-pixel offsets on the 1024-wide upload.
- `rebirth-icons-v1-original.png`: untouched native generated PNG, 2172 × 724. Actual dimensions differ from requested 2048 × 512.

## Individual icons

Each has a 512 PNG and a native-size32 PNG:

- `rebirth-emblem-v1-512.png` / `rebirth-emblem-v1-32.png`: green sprout/cracked gold seed/magenta cycle arrow.
- `mill-v1-512.png` / `mill-v1-32.png`: wooden treadmill, dark belt, small console, gold hardware.
- `cash-reset-v1-512.png` / `cash-reset-v1-32.png`: three gold coins/green emblem/red downward curved arrow.
- `title-badge-v1-512.png` / `title-badge-v1-32.png`: open gold laurel/green sprout.

## Export and QA

Mechanical cropping/resampling only, via `export-rebirth-icons-v1.ps1`. No redrawing or nonuniform stretching. Real transparent gutters measured before cropping, so neighboring icons are not clipped. Each 512 cell keeps art inside a centered360 ×360 region, at least76 px of transparent margin, as requested. Native corner alpha all0; exterior edge alpha0 for the master, upload and each 512/32 icon. Full upload and native32 QA strip `rebirth-icons-v1-qa-32.png` visually inspected. Main silhouettes remain recognizable at32; fine bevel/rivet/laurel detail naturally reduces. No text or numbers baked in.

The treadmill is a generic supporting illustration, not an exact capture of the live 3D model. No Roblox upload/ID, Studio IsLoaded/device test, game wiring, rebirth changes, publish or git operations performed. `rebirth-icons-v1-pack.zip` contains both sheets, four individual icons and previews, crop manifests, original brief, exact prompt notes and QA strip; high-resolution original/export helper remain beside it.

## Exact generation prompt

Use case: stylized-concept.
Style: clean, colourful, friendly premium Roblox cartoon HUD illustrations for
Podnappers, a botanical Roblox plant-monster game whose menus are bright studded
LEGO-like panels. Bold near-black ink outlines of even thickness, broad simple shapes,
subtle bevel shading with one light from the upper left, crisp edge highlights,
saturated cheerful colours. Readable at 32 to 64 pixels. No photorealism, no fussy
detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
numbers, no watermark, no drawn grid lines, no cell backgrounds.

Asset: ONE transparent PNG icon atlas, exactly 2048 x 512: four invisible 512 x 512
cells in one row, one icon per cell, each centred and kept inside the central 360 x
360 area with at least 76 pixels of transparent margin. Same perceived size and the
same outline weight across all four. Real alpha transparency, not white and not a
painted checkerboard.

Left to right:
1. REBIRTH EMBLEM: a bright green sprout with two leaves rising out of a cracked
   open golden seed pod, circled by a bold magenta-pink circular arrow that loops
   round it (the cycle of starting again). Hopeful and powerful.
2. MILL: a chunky treadmill seen from the front-left three-quarter view — a dark
   ridged running belt on a warm wooden frame with a small console post at the
   front and two gold rivets. No character on it.
3. CASH RESET: a short stack of three gold coins with a green leaf emblem, and a
   bold red curved arrow sweeping down and round in front of them (the cash goes).
4. TITLE BADGE: a small golden laurel wreath of leaves open at the top, with a tiny
   green sprout in its centre (an earned title).

Exactly four icons, nothing else.
