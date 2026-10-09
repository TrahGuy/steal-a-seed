# Pod Rush icons v1 — deliverables

## Four PNGs to upload

- `pod-rush-v1-512.png` —512 ×512; event icon, pod plus stopwatch.
- `pod-rush-bronze-v1-512.png` —512 ×512; copper/green medal.
- `pod-rush-silver-v1-512.png` —512 ×512; silver/blue medal.
- `pod-rush-gold-v1-512.png` —512 ×512; gold/red medal.

The optional medals are included. Upload individual PNGs, not the preview, native originals or a platform-resized atlas.

## Atlas and verification

`pod-rush-medals-v1.png` is the1536 ×512 master. `pod-rush-medals-v1.crops.json` gives its three512px cells and measured native source crops. Exact-size/aspect-preserving exports use430px longest art bounds (~84%) with at least32px clear exterior. All final corner/edge alpha0; real transparent RGBA, no opaque box.

Separate32px and24px versions plus64px samples in `pod-rush-icons-v1-preview.png` allow small-scale inspection. The event icon's stopwatch and pod must remain separately readable in the actual HUD. Generated medals have near-identical framing with tiny outline/shine variation; they are not exact pixel-identical colour swaps. No runtime visual acceptance/IsLoaded/Studio/Play test was performed.

## Package and provenance

`pod-rush-icons-v1-pack.zip` includes five final PNGs (four uploads plus atlas), eight32/24 PNGs, one crop manifest, two asset notes, the unchanged brief, exact prompts, this README and the composited QA preview. Native originals and export/QA/package helper scripts remain outside the pack in the project folder.

Built-in image generation using the two previously generated hatch icons as style references. Measured crop/resize preparation used the existing project PowerShell workflow; Python only composes read-only previews, verifies pixels and creates the ZIP, not creative image generation/editing.

Selected source outputs:
- Event icon: exec-f351f7c0-1af3-4207-b6df-64ab14ddc7a2.png.
- Medal atlas: exec-3da73c42-38ee-4a77-bce5-0d99b0bcfb89.png.

Their workspace `*-original.png` copies are retained unchanged. No Image uploads/IDs, external messages, event implementation/duration/rewards, products/economy, game code, purchases or publication was performed. Approval/context inside the supplied brief does not itself request those actions.
