# Hatch icons v1 — export notes

- Final atlas: `hatch-icons-v1.png`, 2048 × 512, genuine RGBA; four 512px cells in one row.
- Upload the separate `hatch-v1-512.png`, `instant-hatch-v1-512.png`, `hatch-timer-v1-512.png`, `hatch-ready-v1-512.png` to avoid atlas upload rescaling.
- Left-to-right uses: Hatch / Hatch All, Instant Hatch, countdown Timer, Ready corner.
- Final atlas crop rectangles: x = 0, 512, 1024, 1536; y = 0; each 512 × 512. Full machine-readable measurements: `hatch-icons-v1.crops.json`.
- Selected original: `hatch-icons-v1-original.png`, 2172 × 724. The original first attempt had no full-height gutter between the first two icons and was rejected for rectangular cropping. The selected spacing edit has measurable transparent quarter boundaries.
- Measured significant bounds (alpha≥8 plus 1px safety), not guessed native quarter crops. Each icon aspect-preserved and centred with a 430px longest side (~84%), at least 41px margin on that longest side. Hourglass is intentionally slender; it is not stretched to match a round pod.
- All corner and exterior edge alpha: 0, for the atlas and all 512px/32px/24px variants. Every 512px icon's outer32px margin was independently verified alpha0.
- Colours and silhouettes not repainted during export. Style interpretation retained: hatch has four burst ticks rather than the brief's three; the hourglass cap has two leaves rather than one. Ready has six yellow rays; both pod action symbols share the same golden-green shell design.

## Native measured crops and fitted content

- hatch: native x75, y119, 432 × 475; fitted content x60, y41, 391 × 430 in its 512px cell.
- instant-hatch: native x609, y169, 407 × 402; fitted content x41, y44, 430 × 425 in its 512px cell.
- hatch-timer: native x1197, y114, 293 × 472; fitted content x122, y41, 267 × 430 in its 512px cell.
- hatch-ready: native x1666, y140, 411 × 453; fitted content x61, y41, 390 × 430 in its 512px cell.

## Small-size QA

Both 32px and 24px PNGs are included. The combined preview also shows 64px samples on grass/sky colours. Broad hatch sprout, bolt, timer and check silhouettes remain the intended reading; tiny shading/studs naturally reduce at small size. Inspect the actual in-game buttons after owner upload; no engine texture-load check has been performed.

Generated using the built-in image tool; no CLI/API fallback. Exact prompts in `hatch-rebirth-extras-v1.used-prompts.md`; owner brief `hatch-rebirth-extras-v1.prompt.md` is unchanged. Originals preserved. No uploads/IDs, IsLoaded or Play test, game code, products/prices or publish changes.
