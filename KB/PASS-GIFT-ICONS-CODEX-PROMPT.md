# Codex brief: GIFT icons for the four Game Passes (2026-10-13)

The owner is making the Shop's four Game Passes giftable (backlog item 6). Roblox can't gift a Game Pass, so each
pass gets a **GIFT developer product** at the same price. Each of the four products needs its own icon. Roblox shows
the icon in the purchase prompt and on the product's page. Art only: no code, no uploads.

Read `AGENTS.md` first. Work only in `art/icons/pass-gifts-2026-10-13/` (create it) and `art/icons/tight/`.

## Each icon is its pass's icon, wrapped as a gift

Start from the pass's own icon, the one the owner already uploaded. Keep the object exactly as it is: the same
shape, colours, pose and sticker outline. Then add the gift wrapping.

| File | The pass's own icon (edit target) |
|---|---|
| `gift_x2_money.png` | `art/icons/x2_money_buff.png` |
| `gift_bag_slots.png` | `art/icons/products-2026-10-11/bag_slots.png` |
| `gift_faster_hatch.png` | `art/icons/products-2026-10-11/faster_hatch.png` |
| `gift_vip.png` | `art/icons/products-2026-10-11/vip.png` |

The gift wrapping matches the approved Mysterious Pod gift twins exactly:

- `art/icons/mysterious-pod-bundles-2026-10-12/gift_mysterious_pod_x1.png`: the approved ribbon, bow and tag.
- `art/icons/products-2026-10-11/gift.png`: the original gift colours.

What that means:

- glossy scarlet-red ribbon with deep red folds and fine warm gold edge piping;
- the ribbon crosses or encircles the object, but the object stays recognisable;
- a large twin-loop bow on top, with two pointed tails;
- one small blank cream gift tag near the bow, with no text or number on it.

Don't hide the object inside a box, and don't replace it with a generic present.

## Style

Match the Shop's icon family:

- a glossy, chunky cartoon object with soft plastic shading;
- a thick pale "sticker" outline round the whole silhouette;
- lit from the upper left;
- readable at 64 px.

## Rules for every icon

- **Canvas:** 512 × 512 PNG with a genuinely transparent background. No checkerboard baked in, no plate, no border
  box.
- **Square, not a circle.** These are developer products, not passes, so Roblox does not crop them to a circle. The
  object and its bow fill about 80% of the canvas, with modest padding, and nothing touches an edge.
- **No new text.** No numbers, "x2", prices, Robux symbols, logos or watermarks. The one exception is the "VIP"
  ribbon already on `vip.png`; keep it as it is.
- **No real brand marks.**
- **Easy to tell apart side by side**, and each one clearly the gift twin of its pass.

## Deliver

1. The four PNGs (512 × 512, transparent corners) in `art/icons/pass-gifts-2026-10-13/`.
2. A **tight-cropped** copy of each in `art/icons/tight/`: the object plus about 2% padding, square and transparent.
3. `sheet.png`: each gift icon next to its pass's own icon, at 512, 128 and 64 px, on a light background and on the
   Shop's green (`#4BE015`).
4. `README.md`: each file, the prompt used, the generated original's path, and these checks for each icon:
   - corner alpha is 0;
   - the size;
   - nothing touches an edge;
   - it reads at 64 px as "this pass, as a gift".

Don't upload anything and don't touch the game's source.

## What the owner does after (not Codex)

1. Upload the approved icons to the group.
2. Create four developer products at the passes' prices, unless the owner chooses others:
   - "Gift: ×2 MONEY", R$199;
   - "Gift: +12 BAG SLOTS", R$149;
   - "Gift: FASTER HATCH", R$129;
   - "Gift: VIP", R$249.
3. Send the four product ids to Claude. Claude fills them into `GameConfig.Store.PassGifts`. Until then the passes
   show no GIFT button.
