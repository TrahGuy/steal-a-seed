# Wheel jackpot burst v1 — image/export notes

- Final upload PNG: `wheel-jackpot-burst-v1.png`, exactly1024 ×1024, genuine RGBA.
- Grid:4 ×4,16 frames of256 ×256, row-major (left to right, top row first).
- One-shot intended playback, approximately1.3 seconds at12.5fps. No baked JACKPOT text, wheel/prize icon, sprout emblem or pink palette.
- Baked white-gold flash/gold ring/pollen and green confetti leaves; not a neutral white tintable sheet.
- Every frame's outer32px is fully transparent; all four sheet corners and exterior edges have alpha0.
- Native1254 ×1254 original is unchanged, copied byte-for-byte to `wheel-jackpot-burst-v1-original.png`. SHA-256: `ae27d25645a4c7ecd8acf44b3b0750648e611ac6cc74afa2a9ecf5a1dd9a1db2`.
- Exact-size export: full source uniformly resampled to1024 square; each256px cell is isolated, then uniformly rendered into its centred192px square (32px spacing). Same scale/anchor across all16 frames, no pose rearrangement, per-frame repositioning or silhouette repainting. This is per-cell export spacing, not a claim that the raw generation had clean gutters.
- End opacity multipliers for frames13–16:0.80,0.55,0.30,0.12; frames1–12unchanged. No RGB normalization/recolouring.
- Final frame16: peak alpha28/255, mean alpha0.027191/255, only269 nontransparent pixels; nearly empty/faint as intended.
- Final PNG SHA-256: `ffa5d48d2bdf0ce3a12910a5ee392f4b106f511491eba9e28f341e7ce0258ac2`.
- `wheel-jackpot-burst-v1-preview.gif`:256 ×256,16 frames,80ms/frame, repeats for review. Runtime must still play ONCE.
- `wheel-jackpot-burst-v1-preview.png`: selected-frame/64px/32px composited contact sheet, not an upload texture.

## Per-frame alpha checks

- Frame1:32pxmargin alpha0; peak253/255; mean9.1920/255; 10053 nontransparent pixels.
- Frame2:32pxmargin alpha0; peak253/255; mean19.0806/255; 14064 nontransparent pixels.
- Frame3:32pxmargin alpha0; peak255/255; mean36.0671/255; 19347 nontransparent pixels.
- Frame4:32pxmargin alpha0; peak255/255; mean42.4514/255; 23158 nontransparent pixels.
- Frame5:32pxmargin alpha0; peak255/255; mean43.2940/255; 25972 nontransparent pixels.
- Frame6:32pxmargin alpha0; peak255/255; mean48.0559/255; 28353 nontransparent pixels.
- Frame7:32pxmargin alpha0; peak255/255; mean45.3086/255; 29042 nontransparent pixels.
- Frame8:32pxmargin alpha0; peak255/255; mean44.7926/255; 27528 nontransparent pixels.
- Frame9:32pxmargin alpha0; peak255/255; mean37.7531/255; 27885 nontransparent pixels.
- Frame10:32pxmargin alpha0; peak255/255; mean26.4570/255; 23685 nontransparent pixels.
- Frame11:32pxmargin alpha0; peak255/255; mean23.2103/255; 22095 nontransparent pixels.
- Frame12:32pxmargin alpha0; peak255/255; mean16.1976/255; 21317 nontransparent pixels.
- Frame13:32pxmargin alpha0; peak211/255; mean7.1685/255; 14339 nontransparent pixels.
- Frame14:32pxmargin alpha0; peak144/255; mean3.0691/255; 10718 nontransparent pixels.
- Frame15:32pxmargin alpha0; peak79/255; mean0.6894/255; 1650 nontransparent pixels.
- Frame16:32pxmargin alpha0; peak28/255; mean0.0272/255; 269 nontransparent pixels.

## Provenance and use boundary

Built-in image generation, one call. The existing `../rebirth/rebirth-burst-v1.png` was a style reference only and remains untouched. Exact final generation prompt: `wheel-jackpot-burst-v1.prompt.md`. Export helper: `export-wheel-jackpot-v1.ps1`; read-only alpha/grid checks and preview renderer: `preview-wheel-jackpot-v1.py`. No CLI/API generation fallback.

Generated animation poses/centres are an artistic approximation; exact motion interpolation, leaf/pollen counts, visual registration and runtime feel are not certified. Preview stills were visually inspected; all frame margins and the tail fade were pixel-checked. The GIF is composited on dark green and repeats for convenient review; use the transparent PNG for the actual effect.

No Roblox uploads/IDs, actual wheel jackpot trigger/reward rules, game code, economy/products/purchases, IsLoaded, Studio/Play, Reduced FX wiring or publish were changed. An implementing session should trigger this only after a real reward is confirmed, use one-shot playback, verify the actual UI/particle scale, and suppress it under Reduced FX. No implementation is performed or implied here.

## Pack

`wheel-jackpot-burst-v1-pack.zip` contains the finalPNG, animatedGIF, contactpreview, these notes and the exact prompt. Native original and helpers remain in the project folder outside the pack.
