# Pod Rush medals v1 — export notes

- Final master atlas: `pod-rush-medals-v1.png`, exactly1536 ×512, three512px cells left to right: bronze, silver, gold.
- Separate uploads: `pod-rush-bronze-v1-512.png`, `pod-rush-silver-v1-512.png`, `pod-rush-gold-v1-512.png`, each512 ×512. Prefer these to avoid platform atlas rescaling.
- Native original: `pod-rush-medals-v1-original.png`, 2172 ×724, preserved unchanged.
- Master crop map: `pod-rush-medals-v1.crops.json`. Final x offsets0/512/1024,y0, every rectangle512 ×512. Native crops are measured independently from real transparent gutters, not assumed square native cells.
- Same round raised-rim/sprouting-pod relief design. Bronze/copper with green ribbon; cool silver with blue ribbon; rich gold with red ribbon. Relief uses each metal, not a separate coloured sticker. No text or rank numbers.
- Each aspect-preserved icon has430px tallest extent and at least41px margin there. Fitted widths are 348/347/349px. The atlas is a generated coherent set, not pixel-identical colour substitutions; tiny silhouette/shine differences remain.
- Corners/exterior edge alpha0 for all finals and32/24 previews; outer32px clear per512px cell. Colours and artwork not repainted during export.

## Native source measurements

- pod-rush-bronze: crop x115, y31, 537 ×663; uniform scale0.64856712; fitted x82, y41, 348 ×430 in its own cell.
- pod-rush-silver: crop x798, y30, 536 ×664; uniform scale0.64759036; fitted x82, y41, 347 ×430 in its own cell.
- pod-rush-gold: crop x1518, y30, 538 ×663; uniform scale0.64856712; fitted x82, y41, 349 ×430 in its own cell.

Generated with the built-in image tool; no CLI/API fallback. References were the existing hatch-v1-512.png and instant-hatch-v1-512.png, used for style/pod identity, not edit targets. Exact prompts in pod-rush-icons-v1.used-prompts.md. Owner brief unchanged. No uploads/IDs, game code, event/boost/reward/economy changes, IsLoaded, Studio/Play, publish or purchases performed.
