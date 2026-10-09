# Rebirth FX v1 — image deliverables

Image export completed 2026-10-09 using built-in image generation and owner-approved offline alpha/RGB cleanup. No CLI/API generation fallback.

## Upload these four PNGs

- `rebirth-burst-v1.png` — 1024 × 1024; 4×4 / 16 frames; coloured burst; play once.
- `rebirth-leaf-v1.png` — 512 × 512; 2×2 / 4 frames; white/light-grey tumbling leaf; intended loop.
- `rebirth-sparkle-v1.png` — 512 × 512; 2×2 / 4 frames; pure-white pollen twinkle; play once.
- `rebirth-aura-v1.png` — 1024 × 1024; 4×4 / 16 frames; pure-white faint wisp; intended loop.

Every cell is 256 × 256; read left to right, top row first. Keep the whole sheets intact. No crops.json is required. Do not upload the draft/original PNGs or GIF previews by mistake.

## Verified export properties

- Real RGBA PNGs, all sheet corners alpha 0.
- Every frame stays inside its own cell, with clear 8px margins (16px for sparkle).
- Tintable sheets are neutral RGB; sparkle and aura are pure white, with glow carried by alpha.
- Aura peak alpha 177/255 = 69.41%, below 70%.
- Burst's final frame is nearly empty/faint.
- Exact dimensions and even grids; no crop, pad, repack, reorder, per-frame shifts or rescaling during final cleanup.
- Native 1254 × 1254 originals and exact-size drafts remain unchanged in the project folder.

## Review before shipping

These are finalized image exports, not certified runtime effects. The generated poses are approximations: the four-frame leaf's last-to-first transition can be more abrupt than the middle poses. The aura wrap has been measured but not certified seamless. Some burst pink persists after the early flash and the sparkle's rays merge into a soft twinkle at small size. Precise visual centring and the full animation feel still need runtime review.

After owner upload, the implementing session should verify Image loading/identity, transparent borders, tint colours, row-major frame order and looping in Studio. Test real 16–64px particle appearances, the one-shot fade, low aura density so it does not hide the character, nearby-player visibility and Reduced FX disable behaviour. No upload, IDs, game wiring, economy/title changes, Play or publish was done here.

## Included references and previews

- Four `*.notes.md`: exact size/grid/order and measured alpha/containment checks.
- `rebirth-fx-v1.prompt.md`: unchanged owner brief.
- `rebirth-fx-v1.used-prompts.md`: exact built-in generation/edit prompts.
- Four `*-preview.gif`: 192 × 192, opaque dark-background animation previews. They repeat for inspection; burst and sparkle must still play once in game.
- `rebirth-fx-v1-preview.png`: contact sheet and 64/32px readability preview; not an upload texture.

`rebirth-fx-v1-pack.zip` contains the above finalized exports, notes, briefs and previews only. It excludes originals, old drafts, previous rebirth UI icons and unrelated game files. Cleanup/export helpers stay in the project directory for provenance.
