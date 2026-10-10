# Mythic and Secret studded textures — v1

2026-10-10 · Art only, following CODEX-BRIEF.md. Built-in imagegen, three separate calls total, one per asset. No CLI/API fallback.

## Upload files

- studs-pearl-white-v1.png — Mythic; pearl-white upper area to cool silver-white lower area, cool bevel shadows. This remains a white card.
- studs-obsidian-silver-v1.png — Secret option A; charcoal/near-black base with restrained cool silver highlights.
- studs-midnight-holo-v1.png — Secret option B; dark navy base with cyan-to-violet-to-pink stud tops. The generated colour is more vivid than a strictly subtle holo tint; A is the more restrained choice.

Each file is1254×1254, fully opaque RGB PNG (PNG IHDR colour type2; alpha effectively255 at every pixel). Edge-to-edge, no border, rounded outer corners, words, icons, stars or sparkle particles. About12×12 square raised studs, visually matching the coral reference's scale/spacing/bevel; pixel-perfect geometry identity is not claimed. These are not seamless textures; use the existing centred-window crop.

## Previews and prompts

- Each upload file has a matching -preview-512.png,512×512 opaque RGB.
- generation-prompts.md records every exact prompt and native source path. The old coral prompt is word-for-word identical except its Palette sentence, verified before generation.
- export-rarity-studs-v1.ps1 is a non-overwriting mechanical save/preview helper. No recolouring or painting was performed.

## Checks

- Native sources were already1254×1254 RGB; final uploads are byte-identical copies.
- Every final and preview is opaque; source/final/preview alpha minimum255, final exterior minimum255.
- Native source/final SHA256 matches:
  - Pearl:04D7B7A3F4769BA5F969F310D97ABA8D7F02D313E91C0B485CB02666DAD5DF4F.
  - Obsidian:955B44B9138D0D3EEEB7D582D2F708B0194CD628A75108DB8926E2E47C739371.
  - Holo:66FF982D02F30BDB1BE74DE002D8A31CF1B9FEDAC108A4F84A1C9ABA47407B36.
- Full-size generations and all three512px previews visually inspected: regular square grid, white versus dark palettes, no added decoration or large glare.
- Coral reference hash unchanged:5BAD922F3C1A4D94D9759846BA7993F084A03EB65EB9F58DAC55EB2B100D621B.
- Actual overlaid title/price/selection-outline contrast in Roblox has NOT been tested. Retain the planned text bands/outlines and check the holo option with the real card UI before release.

## Handoff

The owner chooses one Secret option and uploads the PNGs. Claude handles IDs, moving shine, card/equipment/trap wiring and the art+wiring commit, as specified in the brief. No code/GameConfig/asset IDs, Studio/Play, external messages, upload or publication were changed here. CODEX-BRIEF.md and older textures remain unchanged. No Git stage/commit/push.
