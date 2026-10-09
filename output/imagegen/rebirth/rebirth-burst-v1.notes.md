# Coloured rebirth burst — v1 final export notes

Status: image export complete on 2026-10-09 after the owner's “proceed to the images” approval. Upload, animation acceptance and runtime testing remain separate.

- Final PNG: `rebirth-burst-v1.png` — 1024 × 1024, RGBA.
- Grid: 4 × 4, 16 frames of 256 × 256.
- Frame order: left to right, top row first.
- All four sheet corners have alpha 0.
- Every frame stays inside its own cell: all 16 frames have fully transparent outer 8px margins. Borders feather inward rather than cropping or padding the sheet.
- Baked gold/green/pink colours; not a neutral runtime-tinted sheet.
- Peak alpha: 255/255.
- Native original `rebirth-burst-v1-original.png` (1254 × 1254) and exact-size `rebirth-burst-v1-draft.png` remain unchanged; verified by SHA-256.
- No cropping, padding, grid repacking, cell reordering, per-frame registration or scaling during final cleanup. Exact visual centring is not pixel-certified.
- Final PNG SHA-256: `c9519cfe536027c835ecaa49e821df851b823ba50cfd4686faadfac6725c9813`.

## Animation and visual review

Play ONCE. Frame 16 is nearly empty: 693 nontransparent pixels (1.06% of its cell), mean alpha 0.2064/255 and peak alpha 59/255. The export attenuates frames 13–16 progressively. Some generated pink accents persist beyond the initial flash; the art is an interpretation, not a pixel-exact match to every palette beat.

`rebirth-burst-v1-preview.gif` is a 192 × 192 dark-background animation preview. GIF colours/alpha are composited for display; the PNG is the real transparent upload asset. The GIF repeats for convenient inspection even when runtime playback must be one-shot.

## Per-frame alpha checks

- Frame 1: outer 8px alpha 0; peak 253/255; mean 25.5376/255; 11716 nontransparent pixels.
- Frame 2: outer 8px alpha 0; peak 253/255; mean 52.3741/255; 21669 nontransparent pixels.
- Frame 3: outer 8px alpha 0; peak 253/255; mean 66.4808/255; 27878 nontransparent pixels.
- Frame 4: outer 8px alpha 0; peak 255/255; mean 86.1497/255; 31724 nontransparent pixels.
- Frame 5: outer 8px alpha 0; peak 255/255; mean 98.6209/255; 35606 nontransparent pixels.
- Frame 6: outer 8px alpha 0; peak 255/255; mean 88.5626/255; 36873 nontransparent pixels.
- Frame 7: outer 8px alpha 0; peak 255/255; mean 74.7514/255; 39507 nontransparent pixels.
- Frame 8: outer 8px alpha 0; peak 253/255; mean 47.8959/255; 30182 nontransparent pixels.
- Frame 9: outer 8px alpha 0; peak 255/255; mean 58.3946/255; 32062 nontransparent pixels.
- Frame 10: outer 8px alpha 0; peak 253/255; mean 36.1545/255; 26184 nontransparent pixels.
- Frame 11: outer 8px alpha 0; peak 250/255; mean 21.5971/255; 21449 nontransparent pixels.
- Frame 12: outer 8px alpha 0; peak 247/255; mean 12.944/255; 14630 nontransparent pixels.
- Frame 13: outer 8px alpha 0; peak 176/255; mean 12.2847/255; 13438 nontransparent pixels.
- Frame 14: outer 8px alpha 0; peak 140/255; mean 7.5737/255; 10019 nontransparent pixels.
- Frame 15: outer 8px alpha 0; peak 101/255; mean 2.764/255; 4552 nontransparent pixels.
- Frame 16: outer 8px alpha 0; peak 59/255; mean 0.2064/255; 693 nontransparent pixels.

## Provenance and integration boundary

Built-in image generation, followed by owner-approved offline alpha/RGB export cleanup in `finish-rebirth-fx-v1.py`. Exact generation/edit prompts: `rebirth-fx-v1.used-prompts.md`. Original brief: `rebirth-fx-v1.prompt.md`. No crops.json is needed; the consumer cuts the even grid.

No Roblox upload/ID, Edit IsLoaded check, live ParticleEmitter/Play test, title/economy changes, Reduced FX wiring or game-code edits were performed. The owner/implementing session must confirm image loading, frame order, loop appearance, tinting and visibility before shipping.

