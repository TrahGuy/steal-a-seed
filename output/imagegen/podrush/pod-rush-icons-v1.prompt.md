# Pod Rush icons v1 — image prompts for Codex (2026-10-09)

Icons for **POD RUSH**, the 5-minute stealing event (`KB/POD-RUSH-PLAN.md`, approved 2026-10-09).
A is required. B is optional; the game draws bronze, silver and gold marks itself until B arrives.

Same look as the hatch icons already in the game: the golden-green pod with green dots from
`hatch-v1-512.png` and `instant-hatch-v1-512.png`. A player should see that they belong together.

---

## A. The POD RUSH icon — `pod-rush-v1-512.png` (REQUIRED)

**Where it shows:**
- in the event's announcement;
- on the rush tracker, beside the time left;
- in the round boost-icon row while the rush runs (small, about 24 to 40 px);
- on the end card.

> Style: clean, colourful, friendly premium Roblox cartoon HUD illustration for
> Podnappers, a botanical Roblox plant-monster game whose menus are bright studded
> LEGO-like panels. Bold near-black ink outlines of even thickness, broad simple shapes,
> subtle bevel shading with one light from the upper left, crisp edge highlights,
> saturated cheerful colours. Readable at 24 to 64 pixels. No photorealism, no fussy
> detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
> numbers, no watermark, no background shape behind the icon.
>
> Asset: ONE transparent PNG icon, exactly 512 x 512, centred, filling about 85% of the
> canvas (roughly 430 x 430) with at least 32 pixels of transparent margin. The overall
> silhouette should be roughly round, so it sits well inside a circular slot.
>
> The icon: a round golden-green seed pod with small raised green dots (the same pod style
> as a cartoon "hatch" icon), tilted forward as if dashing to the right, with three bold
> white-and-yellow speed lines streaming behind it to the left. In front of it, overlapping
> its lower right, a chunky bright red-and-gold stopwatch with a white face and one bold
> hand pointing up. Energetic, urgent and fun. Real alpha transparency, not white and
> not a painted checkerboard.

---

## B. Level medals — `pod-rush-medals-v1.png` (OPTIONAL)

One sheet of three, cropped afterwards. Write `pod-rush-medals-v1.crops.json` and export each medal
as its own 512 x 512 PNG.

**Where they show:**
- the three marks on the rush tracker's bar;
- the level-up pop;
- the end card.

> [Same style paragraph as A.]
>
> Asset: ONE transparent PNG icon atlas, exactly 1536 x 512: three invisible 512 x 512
> cells in one row, one medal per cell, each centred and filling about 85% of its cell
> (roughly 430 x 430) with at least 32 pixels of transparent margin. All three the SAME
> shape, size and outline weight, differing only in metal colour.
>
> The medal: a round chunky medal hanging from a short folded ribbon, with a small raised
> seed-pod emblem (a simple pod with a two-leaf sprout on top) embossed in its centre, and
> a thick raised rim.
> Left to right:
> 1. BRONZE: warm copper-brown metal (around 205,127,50), a green ribbon.
> 2. SILVER: cool bright silver (around 200,210,220), a blue ribbon.
> 3. GOLD: rich gold (around 255,200,40) with a brighter shine, a red ribbon.
>
> Exactly three medals, nothing else.

---

## After generating

1. **Transparency:** a corner pixel's alpha is 0, and there is no white or black box. Report the real
   sizes.
2. **Fill:** each icon fills its canvas evenly. A wide empty margin draws it small in the game.
3. **Small size:** look at A at 24 and 32 px. The pod and the stopwatch must both still read.
4. **Upload:** the owner uploads each final PNG as an **Image** to the CrazyCozy Games group and sends
   the ids. Claude checks them; the terminal Claude wires them.
