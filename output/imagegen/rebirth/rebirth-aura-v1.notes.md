# Tintable title aura — v1 final export notes

Status: image export complete on 2026-10-09 after the owner's “proceed to the images” approval. Upload, animation acceptance and runtime testing remain separate.

- Final PNG: `rebirth-aura-v1.png` — 1024 × 1024, RGBA.
- Grid: 4 × 4, 16 frames of 256 × 256.
- Frame order: left to right, top row first.
- All four sheet corners have alpha 0.
- Every frame stays inside its own cell: all 16 frames have fully transparent outer 8px margins. Borders feather inward rather than cropping or padding the sheet.
- Tintable: RGB channels match exactly at every nontransparent pixel; pure white RGB 255, softness encoded in alpha.
- Peak alpha: 177/255 = 69.41%, below the requested 70% limit.
- Native original `rebirth-aura-v1-original.png` (1254 × 1254) and exact-size `rebirth-aura-v1-draft.png` remain unchanged; verified by SHA-256.
- No cropping, padding, grid repacking, cell reordering, per-frame registration or scaling during final cleanup. Exact visual centring is not pixel-certified.
- Final PNG SHA-256: `6c16bfb58aa6243130c978d0ea041581887e1745e3aaf9297bc87467e0fe8bae`.

## Animation and visual review

Intended looping slow sway. Final-to-first alpha difference is 14.4699/255, within the largest adjacent-frame change of 16.4358/255. This does not certify a seamless visual loop; runtime speed, lifetime and layering still need review. Some generated wisp details and poses vary between cells. No frame rearrangement or per-frame positioning edits.

`rebirth-aura-v1-preview.gif` is a 192 × 192 dark-background animation preview. GIF colours/alpha are composited for display; the PNG is the real transparent upload asset. The GIF repeats for convenient inspection even when runtime playback must be one-shot.

## Per-frame alpha checks

- Frame 1: outer 8px alpha 0; peak 175/255; mean 17.2365/255; 15254 nontransparent pixels.
- Frame 2: outer 8px alpha 0; peak 175/255; mean 16.9858/255; 14942 nontransparent pixels.
- Frame 3: outer 8px alpha 0; peak 176/255; mean 17.8297/255; 15316 nontransparent pixels.
- Frame 4: outer 8px alpha 0; peak 176/255; mean 16.9723/255; 15461 nontransparent pixels.
- Frame 5: outer 8px alpha 0; peak 175/255; mean 18.1707/255; 16632 nontransparent pixels.
- Frame 6: outer 8px alpha 0; peak 176/255; mean 18.9891/255; 17576 nontransparent pixels.
- Frame 7: outer 8px alpha 0; peak 176/255; mean 18.7032/255; 16795 nontransparent pixels.
- Frame 8: outer 8px alpha 0; peak 177/255; mean 16.1178/255; 15614 nontransparent pixels.
- Frame 9: outer 8px alpha 0; peak 176/255; mean 18.1798/255; 16222 nontransparent pixels.
- Frame 10: outer 8px alpha 0; peak 175/255; mean 19.1672/255; 16949 nontransparent pixels.
- Frame 11: outer 8px alpha 0; peak 176/255; mean 18.2055/255; 16386 nontransparent pixels.
- Frame 12: outer 8px alpha 0; peak 175/255; mean 17.5/255; 15947 nontransparent pixels.
- Frame 13: outer 8px alpha 0; peak 176/255; mean 17.587/255; 15515 nontransparent pixels.
- Frame 14: outer 8px alpha 0; peak 176/255; mean 17.3637/255; 15211 nontransparent pixels.
- Frame 15: outer 8px alpha 0; peak 176/255; mean 17.4103/255; 14958 nontransparent pixels.
- Frame 16: outer 8px alpha 0; peak 176/255; mean 17.7333/255; 15438 nontransparent pixels.

## Provenance and integration boundary

Built-in image generation, followed by owner-approved offline alpha/RGB export cleanup in `finish-rebirth-fx-v1.py`. Exact generation/edit prompts: `rebirth-fx-v1.used-prompts.md`. Original brief: `rebirth-fx-v1.prompt.md`. No crops.json is needed; the consumer cuts the even grid.

No Roblox upload/ID, Edit IsLoaded check, live ParticleEmitter/Play test, title/economy changes, Reduced FX wiring or game-code edits were performed. The owner/implementing session must confirm image loading, frame order, loop appearance, tinting and visibility before shipping.

