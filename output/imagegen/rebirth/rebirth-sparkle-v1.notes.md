# Tintable pollen sparkle — v1 final export notes

Status: image export complete on 2026-10-09 after the owner's “proceed to the images” approval. Upload, animation acceptance and runtime testing remain separate.

- Final PNG: `rebirth-sparkle-v1.png` — 512 × 512, RGBA.
- Grid: 2 × 2, 4 frames of 256 × 256.
- Frame order: left to right, top row first.
- All four sheet corners have alpha 0.
- Every frame stays inside its own cell: all 4 frames have fully transparent outer 16px margins. Borders feather inward rather than cropping or padding the sheet.
- Tintable: RGB channels match exactly at every nontransparent pixel; pure white RGB 255, softness encoded in alpha.
- Peak alpha: 252/255.
- Native original `rebirth-sparkle-v1-original.png` (1254 × 1254) and exact-size `rebirth-sparkle-v1-draft.png` remain unchanged; verified by SHA-256.
- No cropping, padding, grid repacking, cell reordering, per-frame registration or scaling during final cleanup. Exact visual centring is not pixel-certified.
- Final PNG SHA-256: `dd6275abce10a6824b372bae1c08828fb06b57916915f597634f52b9b91db8f5`.

## Animation and visual review

Play ONCE: small dot, brighter short-ray twinkle, largest twinkle, small dot. Mean frame alpha is 3.3139, 12.5030, 30.2281 and 2.2502/255. The soft generated rays merge into a compact glow at small sizes; the requested eight-ray peak is not a sharply separated eight-point star. Preview in the actual particle scale.

`rebirth-sparkle-v1-preview.gif` is a 192 × 192 dark-background animation preview. GIF colours/alpha are composited for display; the PNG is the real transparent upload asset. The GIF repeats for convenient inspection even when runtime playback must be one-shot.

## Per-frame alpha checks

- Frame 1: outer 16px alpha 0; peak 250/255; mean 3.3139/255; 2961 nontransparent pixels.
- Frame 2: outer 16px alpha 0; peak 251/255; mean 12.503/255; 10771 nontransparent pixels.
- Frame 3: outer 16px alpha 0; peak 252/255; mean 30.2281/255; 22116 nontransparent pixels.
- Frame 4: outer 16px alpha 0; peak 249/255; mean 2.2502/255; 2316 nontransparent pixels.

## Provenance and integration boundary

Built-in image generation, followed by owner-approved offline alpha/RGB export cleanup in `finish-rebirth-fx-v1.py`. Exact generation/edit prompts: `rebirth-fx-v1.used-prompts.md`. Original brief: `rebirth-fx-v1.prompt.md`. No crops.json is needed; the consumer cuts the even grid.

No Roblox upload/ID, Edit IsLoaded check, live ParticleEmitter/Play test, title/economy changes, Reduced FX wiring or game-code edits were performed. The owner/implementing session must confirm image loading, frame order, loop appearance, tinting and visibility before shipping.

