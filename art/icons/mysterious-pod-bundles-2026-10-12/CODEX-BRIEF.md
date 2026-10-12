# Codex brief: Mysterious Pod BUNDLE icons, 4 for self + 4 for gifts (2026-10-12)

The owner is selling the **Mysterious Pod** (Enchanted Mist's reward pod) in the Shop, in four bundles: x1, x3,
x10 and x50, each with a "Gift" twin. Each bundle is a Roblox developer product and needs its own icon. The icon
also shows on the in-game Shop banner. Art only: no code, no uploads.

Read `AGENTS.md` first. Work only in `art/icons/mysterious-pod-bundles-2026-10-12/` and `art/icons/tight/`.

## The pod: draw THIS pod, nothing else

The Mysterious Pod is the owner's **Luckhollow** pod. Match its design exactly; don't invent another egg.

- `output/mysterious-pod-product-icon-2026-10-12/mysterious-pod-icon-512.png`: the owner's current icon, the pod
  in 3/4 view.
- `D:/KAPE/LuckhollowPod/luckhollow_pod_preview.jpg`: front, 3/4, back and open views.
- `D:/KAPE/LuckhollowPod/luckhollow_pod_paste.luau`: its builder (the header describes every part).

What it is:
- a hex-faceted dark bark shell on six root toes;
- mossy green leaf plates with lime glowing seams on the flats;
- a gold clover medallion on the front plate;
- gold vines up the corners, ending in gold buds;
- a gold rim round a leaf-green lid;
- a crown of leaf petals leaning in to a closed bud, with a small four-leaf clover on top.

Blocky and studded-toy in feel, but rendered in the Shop icons' glossy cartoon style.

**Never show what's inside:** no creature, no rarity colour, no hint.

## Style: match the Shop's icon family

Match these exactly as one family:
- `art/icons/speed_1_single_shoe.png` … `speed_6_shoe_chest.png`
- `art/icons/cash_1_banknotes_fan.png` … `cash_5_banknotes_chest.png`
- `art/icons/pod_1_plain_pod.png` … `pod_3_radiant_pod.png`
- `art/icons/products-2026-10-11/gift.png`, for the gift look

The look:
- a glossy chunky cartoon object with soft plastic shading;
- a thick pale "sticker" outline round the whole silhouette;
- lit from the upper left;
- readable at 64 px.

Not photorealistic, not flat vector. The quantity is shown by HOW MANY pods appear, like the shoes and banknotes
growing into a chest. A soft mint glow and a few small sparkles fit the Enchanted Mist.

## The eight icons

| File | Shows |
|---|---|
| `mysterious_pod_x1.png` | ONE pod, centred, 3/4 view |
| `mysterious_pod_x3.png` | THREE pods grouped: one in front, two slightly behind |
| `mysterious_pod_x10.png` | a HEAP of pods (about 6-8 visible, reading as "lots") with a soft mint glow |
| `mysterious_pod_x50.png` | an open wooden TREASURE CHEST overflowing with pods, mint sparkles |
| `gift_mysterious_pod_x1.png` | the x1 picture wrapped as a GIFT: a red ribbon crossing it, a big bow on top, a small gift tag |
| `gift_mysterious_pod_x3.png` | the x3 picture with the same ribbon and bow |
| `gift_mysterious_pod_x10.png` | the x10 picture with the same ribbon and bow |
| `gift_mysterious_pod_x50.png` | the x50 chest with the same ribbon and bow |

The gift versions must read as "a present" at a glance, but the pods stay recognisable. Use the same ribbon and
bow on all four, in the colours of `gift.png`.

## Rules for every icon

- **Canvas:** 512 x 512 PNG with a genuinely transparent background. No checkerboard baked in, no plate, no
  border box.
- **Composition:** the object fills about 80% of the canvas with modest padding.
- **No text:** no numbers, "x3"/"x10", prices, Robux symbols, logos or watermarks. The quantity is the pod count.
- **No real brand marks.** No creature shown, ever.

## Deliver

1. The eight PNGs (512 x 512, transparent corners) in `art/icons/mysterious-pod-bundles-2026-10-12/`.
2. A **tight-cropped** copy of each in `art/icons/tight/`: the object plus about 2% padding, square and
   transparent.
3. `sheet.png`: all eight at 512, 128 and 64 px, on a light background and on the Shop's green (`#4BE015`), next
   to `speed_3` and `cash_4` for comparison.
4. `README.md`: each file, the prompt used, the generated original's path, and checks for each icon:
   - corner alpha 0;
   - the size;
   - that it reads at 64 px;
   - that it shows no creature.

Don't upload, wire, change code or GameConfig, or publish. The owner uploads the icons to the products, and the
same uploads go on the Shop banner. Never `git add -A`.
