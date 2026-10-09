# Hatch + rebirth extras v1 — image prompts (2026-10-09)

New pictures for the two builds the owner approved on 2026-10-09:

- **Phase 1, "More stealing, less waiting":** pods now hatch in the Bag, with HATCH / HATCH ALL
  buttons, a countdown on growing pods, a READY state and an Instant Hatch button.
- **The rebirth celebration:** a REBORN! popup with turning rays behind it.

Until the uploads arrive, the game draws stand-ins in their place. It never uses anyone else's
upload. Every slot is an id in GameConfig, "" until the owner sends it.

Three generations: A is required, B is recommended, C is optional.

---

## A. Hatch icons — `hatch-icons-v1.png` (REQUIRED)

One sheet of four icons, cropped into four afterwards, like the rebirth icons. Write a sibling
`hatch-icons-v1.crops.json` with the measured rectangles, and export each icon as its own
512 x 512 PNG.

> Style: clean, colourful, friendly premium Roblox cartoon HUD illustrations for
> Podnappers, a botanical Roblox plant-monster game whose menus are bright studded
> LEGO-like panels. Bold near-black ink outlines of even thickness, broad simple shapes,
> subtle bevel shading with one light from the upper left, crisp edge highlights,
> saturated cheerful colours. Readable at 24 to 64 pixels. No photorealism, no fussy
> detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
> numbers, no watermark, no drawn grid lines, no cell backgrounds.
>
> Asset: ONE transparent PNG icon atlas, exactly 2048 x 512: four invisible 512 x 512
> cells in one row, one icon per cell, each centred and FILLING about 85% of its cell
> (roughly 430 x 430), with at least 32 pixels of transparent margin. Same perceived
> size and the same outline weight across all four. Real alpha transparency, not white
> and not a painted checkerboard.
>
> Left to right:
> 1. HATCH: a round golden-green seed pod cracking open across its middle, the top half
>    tipping back, a bright green two-leaf sprout popping out, three short bold burst
>    lines around the crack. Joyful.
> 2. INSTANT HATCH: the same seed pod, closed, with a bold bright yellow lightning bolt
>    in front of it, slanting across, and two short speed lines behind. Premium and fast.
> 3. TIMER: a chunky little hourglass with a warm wooden frame, its glass half full of
>    bright green sand running down, one small leaf on the top cap.
> 4. READY: a round bright green badge with a thick white check mark, ringed with six
>    short bold yellow burst lines. Celebratory.
>
> Exactly four icons, nothing else.

**Used for:**
1. the HATCH button on a ready pod, and HATCH ALL in the Bag;
2. the Instant Hatch button on a growing pod (the 99 R$ product);
3. beside a growing pod's countdown in the Bag and on the hotbar;
4. the corner of a ready pod's tile.

---

## B. Sunburst rays — `sunburst-rays-v1.png` (RECOMMENDED)

They turn slowly behind the REBORN! popup. They can also sit behind any big reward later: a rare
hatch, a wheel jackpot, an event reward. The game tints them, so draw them in white only.

> Style: clean bright cartoon game VFX, smooth soft-edged, no outlines, no texture, no
> text, no watermark.
>
> Asset: ONE transparent PNG, exactly 1024 x 1024: a radial sunburst centred on the
> exact centre of the image. 16 straight, evenly spaced rays alternating wide and
> narrow, each a long thin wedge starting a little out from the centre and tapering to
> a point near the edge. Pure WHITE only, brightest near the centre and fading smoothly
> to fully transparent before the edge, the brightest part about 80% opaque. A soft
> round white glow in the very centre about 15% of the image wide. The rays must be
> perfectly rotationally even so it can spin with no visible seam or wobble. Real
> alpha transparency; every edge pixel fully transparent.

---

## C. "REBORN!" logo — `reborn-logo-v1.png` (OPTIONAL)

A word logo for the top of the popup. Without it, the game draws REBORN! in the LuckiestGuy font
with a gold gradient, which already looks fine. Image generators often garble letters, so check
the spelling letter by letter, and drop it rather than ship a wrong one.

> Style: bold chunky bubbly Roblox game title lettering, cartoon, glossy.
>
> Asset: ONE transparent PNG, exactly 1024 x 384: the single word "REBORN!" in fat
> rounded capital letters, slightly arched upward in the middle, glossy gold-yellow
> fill with a lighter highlight along the top of each letter, a thick magenta-pink
> (#FF358F) outline, and a second thinner dark brown outer outline. Two small green
> leaves sprouting from the top of the letter O. The word fills about 90% of the
> width. Nothing else: no background, no sparkles, no shadow on the ground. Real alpha
> transparency.

---

## After generating

1. **Transparency:** a corner pixel's alpha is 0, and there is no white or black box. Report each
   real size.
2. **Sheet A:** each icon fills its cell evenly. Tight crops matter here: a wide transparent margin
   draws the icon small in the game.
3. **Sheet B:** spin a copy to check there is no seam.
4. **Upload:** the owner uploads each PNG as an **Image** to the CrazyCozy Games group and sends the
   ids. Claude checks them (economy details, Edit IsLoaded, alpha), then the terminal Claude wires
   them.
