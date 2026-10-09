# Rebirth FX v1 — current export status

## Final export update — 2026-10-09

The owner resumed with “proceed to the images i requested”, approving the pending mechanical cleanup. Four bare final PNGs and four animation previews now exist. The earlier no-approval/no-final-file statements below are historical and superseded.

- `rebirth-burst-v1.png`: 1024 × 1024, 4×4, 16 frames, baked colours, one-shot.
- `rebirth-leaf-v1.png`: 512 × 512, 2×2, 4 frames, neutral tintable leaf.
- `rebirth-sparkle-v1.png`: 512 × 512, 2×2, 4 frames, pure-white tintable one-shot glow.
- `rebirth-aura-v1.png`: 1024 × 1024, 4×4, 16 frames, pure-white tintable wisp; peak alpha 177/255 (69.41%).

All sheet corners and every frame's required margin are fully transparent. Dimensions/grids remain unchanged; no crop/pad/repack or cell repositioning. All native originals and resized drafts are preserved and hash-verified unchanged. See final sibling notes and `REBIRTH_FX_V1_DELIVERABLES.md`.

Image exports are complete, not engine-certified effects. In particular the four-pose leaf wrap can be more abrupt than its adjacent poses; leaf and aura loops still need Studio acceptance. Burst contains some pink beyond the first flash; sparkle rays soften together at small sizes. No uploads/IDs, game-code changes, Studio/Play, Reduced FX integration, publish or git operations.

---

## Historical pre-approval draft record

# Rebirth FX v1 — draft handoff

Four requested sheets were generated separately with the built-in image tool. These are ParticleEmitter flipbooks, not the existing rebirth icons. The owner brief and original icon assets were not changed.

## Current files

- `rebirth-burst-v1-draft.png`: 1024 × 1024, 4×4,16 frames, coloured, one-shot.
- `rebirth-leaf-v1-draft.png`: 512 × 512,2×2,4 frames, intended tintable looping leaf.
- `rebirth-sparkle-v1-draft.png`: 512 × 512,2×2,4 frames, intended tintable one-shot twinkle.
- `rebirth-aura-v1-draft.png`: 1024 × 1024,4×4,16 frames, intended tintable loop.

All four selected native originals are 1254 ×1254 and preserved as `*-original.png`. Only complete-sheet uniform resizing was applied. No cropping, padding, cell rearrangement, alpha/RGB cleanup or art repainting. Do NOT confuse draft names with finalized production files.

## Still required before production use

The generated halos have faint cross-cell alpha; the aura has significant content on some cell borders. Burst corner alpha includes1, aura corner alpha includes1. Worst outer8px frame alpha is burst39, leaf1, sparkle1, aura100 (out of255). Tintable drafts have small non-neutral RGB contamination; the aura's peak alpha255 also exceeds its requested70% limit. The burst's final frame is nearly empty by coverage but some dots remain bright. Centers and animation/loop continuity are not pixel-perfect certified or tested in the actual ParticleEmitter.

An asynchronous question asked the owner to approve mechanical alpha/RGB export cleanup: clear gutters, remove dark fringes/neutralize tintable glows and cap aura opacity70%, preserving complete sheets and fixed grids, no cropping/padding. No answer has been received as of this handoff. Do not perform that approval-bound cleanup yet. No final bare `rebirth-burst-v1.png`, `rebirth-leaf-v1.png`, `rebirth-sparkle-v1.png` or `rebirth-aura-v1.png` exists from this task.

Each sibling `*.notes.md` records exact size/grid/order/alpha/containment caveats. Exact generation prompts and the unsuccessful burst-gutter edit are in `rebirth-fx-v1.used-prompts.md`. The correction was not selected. `export-rebirth-fx-drafts-v1.ps1` is mechanical resizing plus inspection, not a creative generator.

No Roblox uploads/IDs, game-code or economy changes, Studio/Play/IsLoaded tests, Reduced FX wiring, publication or git operations. The owner and terminal Claude still own upload/integration. These files are review drafts, not completed production textures.
