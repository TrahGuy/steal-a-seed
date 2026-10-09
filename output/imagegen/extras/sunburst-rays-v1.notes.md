# Sunburst rays v1 — export notes

- Final PNG: `sunburst-rays-v1.png`, 1024 × 1024, genuine RGBA.
- Selected fresh generated source: `sunburst-rays-v1-original.png`, 1254 × 1254. Initial and corrective attempts produced blunt petal-like light shapes; the fresh generation supplied sharper tips.
- Sixteen alternating broad/slender generated rays; no drawn outlines/text/texture or background plate.
- Full source resampled without distortion to 960 × 960 at x32,y32, ensuring completely transparent outer borders. No rays are cropped.
- Tintable final RGB is exactly 255,255,255 at every nontransparent pixel. Native grey brightness is encoded into alpha so tinting does not carry grey/dark RGB fringes.
- Peak alpha 204/255 = 80%; alpha below4 discarded as imperceptible export specks.
- Every exterior edge pixel and all four corner pixels have alpha0.
- Spin copy: `sunburst-rays-v1-spin-preview.gif`, 256 × 256, 36 frames at 10° steps, 80ms each. Fixed pivot128,128 in the preview, intended full-texture pivot512,512 in the final. The GIF is opaque/composited for review; upload the PNG, not the GIF.

## Symmetry caveat

The requested perfect rotational geometry is not certified. Generated rays have small shape/brightness differences. Measured alpha centroid is x510.897, y521.292 (ideal image-centre511.5,511.5). A 45° rotated copy has mean alpha difference 9.8661/255, so this is NOT a mathematically invariant 45° pattern. The composited preview shows sixteen distinct sharp rays and a small central glow. The spin preview lets the owner inspect any subtle breathing/wobble. Do not describe it as pixel-perfect or seamless-certified; check appearance behind the actual popup before shipping.

Generated using the built-in image tool; no CLI/API fallback. Exact prompts in `hatch-rebirth-extras-v1.used-prompts.md`; owner brief `hatch-rebirth-extras-v1.prompt.md` is unchanged. Originals preserved. No uploads/IDs, IsLoaded or Play test, game code, products/prices or publish changes.
