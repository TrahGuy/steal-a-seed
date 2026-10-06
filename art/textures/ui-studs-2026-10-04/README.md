# Studded UI color atlas

Prepared from the owner's gray square-stud texture, using the built-in image generator. This is a texture-only sheet, not an implemented UI change. Original and generated cache images are preserved.

## Files

- ui-studs-12-colors-v1.png: final opaque 1448 x 1086 color atlas.
- source-gray-studs.png: untouched local copy of the owner's reference.
- manifest.json: color names, suggested uses, hashes and exact crop rectangles.
- generation.prompt.md: exact generation prompt and provenance.

## Crop order

Four columns by three rows; each cell is 362 x 362 pixels. Read left to right:

- Row 1: cream, mint, leaf-green, emerald.
- Row 2: sky-blue, blue, lavender, violet.
- Row 3: gold, coral, forest-charcoal, deep-teal.

Column x offsets: 0, 362, 724, 1086. Row y offsets: 0, 362, 724. Crop using the manifest's rectangles and save each named PNG losslessly. No labels or gutters are baked into the sheet.

## Claude handoff

Crop the twelve variants into separate named PNGs from the atlas; do not modify the source or replace the atlas. Inspect the crop edges before calling any crop seamless. Upload selected crops as individual Roblox Image assets before wiring them; these local files are not Roblox asset IDs. Do not invent upload IDs or use the whole atlas as a single repeating texture.

For UI, use the studs as a faint decorative layer over solid-color panels/buttons, not high-contrast noise beneath small lettering. A starting ImageTransparency around 0.80 is a visual suggestion, not a verified runtime value. Preserve readable plain body text, existing rarity/size effects and every gameplay behavior. Keep one consistent stud scale rather than stretching it across each panel. UI implementation is for the later Claude task; none has been done here.

The generated shades approximate the requested palette; they are not pixel-exact recolors. Cropping, tile-seam validation, Roblox uploads and in-game UI/phone checks remain undone.

