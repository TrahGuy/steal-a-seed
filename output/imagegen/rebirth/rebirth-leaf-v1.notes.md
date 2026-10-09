# Tintable tumbling leaf — v1 final export notes

Status: image export complete on 2026-10-09 after the owner's “proceed to the images” approval. Upload, animation acceptance and runtime testing remain separate.

- Final PNG: `rebirth-leaf-v1.png` — 512 × 512, RGBA.
- Grid: 2 × 2, 4 frames of 256 × 256.
- Frame order: left to right, top row first.
- All four sheet corners have alpha 0.
- Every frame stays inside its own cell: all 4 frames have fully transparent outer 8px margins. Borders feather inward rather than cropping or padding the sheet.
- Tintable: RGB channels match exactly at every nontransparent pixel; neutral grey/white, active RGB 180–255.
- Peak alpha: 255/255.
- Native original `rebirth-leaf-v1-original.png` (1254 × 1254) and exact-size `rebirth-leaf-v1-draft.png` remain unchanged; verified by SHA-256.
- No cropping, padding, grid repacking, cell reordering, per-frame registration or scaling during final cleanup. Exact visual centring is not pixel-certified.
- Final PNG SHA-256: `2c77fd73c974b3777e395f7ed722a9c1713a640eb36c68bd4ed9227f234c511a`.

## Animation and visual review

Intended looping flat / narrow / edge-on / narrow sequence. The final-to-first alpha difference is 61.2658/255, versus a largest adjacent-frame difference of 44.4258/255. This is a diagnostic, not a perceptual smoothness test: the wrap can look more abrupt than the middle poses. Four original poses are preserved; no interpolated frames, per-cell shifts or pose repainting. Check the loop in Studio before treating it as a seamless production animation.

`rebirth-leaf-v1-preview.gif` is a 192 × 192 dark-background animation preview. GIF colours/alpha are composited for display; the PNG is the real transparent upload asset. The GIF repeats for convenient inspection even when runtime playback must be one-shot.

## Per-frame alpha checks

- Frame 1: outer 8px alpha 0; peak 255/255; mean 79.3657/255; 20880 nontransparent pixels.
- Frame 2: outer 8px alpha 0; peak 255/255; mean 40.9677/255; 10908 nontransparent pixels.
- Frame 3: outer 8px alpha 0; peak 255/255; mean 14.5878/255; 4058 nontransparent pixels.
- Frame 4: outer 8px alpha 0; peak 255/255; mean 30.0266/255; 8066 nontransparent pixels.

## Provenance and integration boundary

Built-in image generation, followed by owner-approved offline alpha/RGB export cleanup in `finish-rebirth-fx-v1.py`. Exact generation/edit prompts: `rebirth-fx-v1.used-prompts.md`. Original brief: `rebirth-fx-v1.prompt.md`. No crops.json is needed; the consumer cuts the even grid.

No Roblox upload/ID, Edit IsLoaded check, live ParticleEmitter/Play test, title/economy changes, Reduced FX wiring or game-code edits were performed. The owner/implementing session must confirm image loading, frame order, loop appearance, tinting and visibility before shipping.

