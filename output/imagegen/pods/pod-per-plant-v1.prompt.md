# A pod per plant v1 — design prompts for all 25 (2026-10-09)

The owner chose a **different pod for every plant**, so the pod's shape tells a player what grows
inside. Today every biome shares one shell for all five of its plants.

Each prompt below makes a concept picture for one pod, to model from. All 25 use the same camera
and style, so they line up as one family. The style matches the owner's own concept,
`output/pod-concepts/greenhollow-cream-petal-pod-v1.png`: chunky faceted petal plates, smooth matte
finish, soft studio light.

**Not covered here:**
- the two Secret pods (Snarlbloom, Petalfawn), which already have the owner's own models;
- the Rain event pods.

---

## Game rules every pod must keep (measured in the code)

| Rule | Why |
|---|---|
| **Fits a box about 1.25 wide × 1.2 to 1.45 tall** (in units of its own width class) | The carry grip and a guardian's haul need it. The shipped shells run 1.21 to 1.46 tall |
| **Flat base; nothing below the base** | The pod stands on the nest and the bed |
| **The main mass is in the middle**, not a husk off to one side | A carried pod sits against the chest at a fixed grip |
| **The signature shape reads from BEHIND and from ABOVE** | Nest pods face away from the hub, so a raider walking in sees the back first. Put the tell on top or all the way round |
| **One clear SEAM or BAND** (where plates meet, or a collar ring) | The game repaints it in the size colour (Tiny grey, Big green, Huge blue, Mega purple, Giant orange, Titan red, Colossal gold). Titan and Colossal also tint the shell, glow and get an aura. **Don't paint size into the model;** the game does it |
| **No words, numbers or faces** | It's still a pod: the plant is inside |
| **Rarity reads by richness**: Common has one feature, Uncommon two, Rare a pattern, Epic a small glow accent, Legendary gold trim or a crown, Mythic its own light | So a better pod looks better from across the nest |

**If you model in Blender or an AI 3D tool:** Studio's 3D Importer reads centimetres as studs, so
scale it yourself. It cuts meshes at 20,000 triangles, and it imports unanchored. Claude can measure
an import for you.

---

## Shared style (paste at the top of every prompt)

> Style: a single chunky stylised seed pod for a cute Roblox plant-monster game, sculpted
> from big faceted petal plates with softly bevelled edges, smooth matte plastic finish,
> soft even studio lighting, gentle ambient occlusion in the seams, saturated but soft
> colours, toy-like and readable at small size. Three-quarter view from the front-left,
> slightly above, the pod centred and filling about 80% of the frame, standing upright on
> a small flat base. Plain fully transparent background. No text, no letters, no numbers,
> no face, no eyes, no characters, no ground, no cast shadow, no scenery, no watermark.
> 1024 x 1024.

Every prompt below continues with **"Asset:"**.

---

## Greenhollow (biome 1): soft petal plates, fresh greens and creams, one small leaf on top

1. **NUBKIN pod** (Common, the cube plant)
   > Asset: a rounded CUBE-shaped pod made of six soft square petal plates folded shut, leaf
   > green (146,196,106) plates with paler green edges (176,214,128), and two tiny sprout
   > leaves with cream (242,238,206) tips poking out of the top seam. Simple and friendly.

2. **PETALPIP pod** (Common, the orb plant)
   > Asset: a round ORB pod wrapped in five cupped petal plates like a closed tulip bud, pale
   > yellow-green (206,224,132) plates with cream (250,246,226) rims, one coral (232,132,106)
   > petal tip just peeking out at the very top.

3. **SPIRETIP pod** (Uncommon, the teardrop plant)
   > Asset: a tall TEARDROP pod rising to a soft point, deep pine green (94,152,104) plates
   > twisting slightly upward in a spiral, a pale cream (236,242,206) banded collar ring around
   > its waist, and a pale (242,246,220) tip.

4. **TOADCAP pod** (Rare, the mushroom plant)
   > Asset: a MUSHROOM pod, a warm cream (240,228,198) body under a domed red (216,112,100) cap
   > that closes down over it, four round cream spots on the cap, and a ring of short gill
   > ridges visible under the cap's rim all the way round.

5. **BELLCHIME pod** (Epic, the bell plant)
   > Asset: a closed porcelain BELL pod, cool blue-white porcelain (214,226,242) with a pink
   > (240,150,168) scalloped collar at its hem, a small leaf-green stalk curling up from the top
   > with two pink bud tips, and a faint soft glow inside the scallops.

## Dustbowl (biome 2): sun-baked husk and clay plates, sand, rust and sage

6. **DUNEBUD pod** (Uncommon, the husk bud)
   > Asset: a sealed sand-gold (246,220,152) bud wrapped in rust (198,124,62) husk plates that
   > cross over the top and meet in a pale knot (246,228,182), one front plate lifted slightly
   > open showing shadow inside.

7. **PADDLEHOP pod** (Uncommon, the cactus pad)
   > Asset: a fat oval cactus-PAD pod, sage-olive (168,180,96) with darker olive (122,134,68)
   > rounded rims, rows of tiny pale spine dots, and one small bright red-orange (228,92,66)
   > bloom bud on top.

8. **THORNWHORL pod** (Rare, the blade whorl)
   > Asset: a pod wrapped by five curved driftwood blades spiralling round it in a WHORL, a
   > desert-tan (206,184,138) core showing between rust (172,104,68) blades, two blades darker
   > for depth, and small pale ochre (230,194,128) hooks along the blade edges.

9. **RAINCUP pod** (Epic, the rain goblet)
   > Asset: a stepped GOBLET-shaped pod, sky-blue (124,188,242) lobes closed upward like a
   > cupped flower, a gold (255,216,84) boss glinting at the top, two lobes with a pink
   > (226,100,142) throat, a single water-drop bead on the rim, and a faint glow in the gold.

10. **SUNCROWN pod** (Legendary, the solar cactus golem)
    > Asset: a golden cactus-SUN pod (255,198,38) with a crown of orange (239,116,25) radiating
    > spikes around its top like the sun's rays, red (210,61,45) spike tips, a thin gold trim
    > band, and a warm inner glow.

## Tanglemire (biome 3): mossy peat, woven reeds, swamp greens with lime moss

11. **BOGBONNET pod** (Rare, the bonnet plant)
    > Asset: a HOODED pod like a closed sun-bonnet, a dark mire-green (42,92,74) hood folded
    > down over the front, a pale sage (196,210,162) brim edge, and tufts of lime (168,214,96)
    > moss at the base.

12. **CROOKREED pod** (Rare, the crooked reed)
    > Asset: a pod made of crooked brown (144,98,68) reeds bundled tight like a sheaf, green
    > (70,128,88) reed tips bending sideways off the top, and a dark green (42,92,74) binding
    > band round the middle.

13. **SNAPMOSS pod** (Epic, the snapping moss)
    > Asset: a mossy pod shaped like a closed snapping JAW, a dark green moss shell (42,92,74),
    > a zig-zag red (204,94,88) seam across the middle like closed teeth, a lime (168,214,96)
    > moss fringe along the top, and a faint glow leaking from the seam.

14. **LANTERNCAP pod** (Legendary, the lantern plant)
    > Asset: a LANTERN-shaped pod, golden amber (238,188,78) glowing panels inside a pale bone
    > (220,218,176) cage frame, a small cap on top with a little handle loop, lime moss
    > (168,214,96) at the base, and a warm inner light.

15. **GLOOMLOTUS pod** (Mythic, the mangrove stilt titan)
    > Asset: a closed seafoam (146,232,204) lotus bud held up on curling dark MANGROVE ROOTS like
    > short stilts, lime (188,224,108) petal edges, and a glowing neon wisp jewel at the bud's
    > tip that gives off its own soft light.

## Emberroot (biome 4): cracked charcoal shells with glowing ember seams

16. **CINDERPAW pod** (Rare, the low fan)
    > Asset: a low wide pod of broad blade plates fanned out and folded shut like a closed PAW,
    > charcoal (52,40,38) plates, glowing orange (255,118,44) cracks between them, and deep
    > ember (198,68,24) plate tips.

17. **EMBERQUILL pod** (Rare, the tall quill)
    > Asset: a tall narrow pod sheathed in long upright QUILLS, umber (96,78,62) quills with
    > gold-orange (255,200,92) tips, and one central quill taller than the rest, lit at its tip
    > like a candle wick.

18. **SLAGBLOOM pod** (Epic, the drooping slag)
    > Asset: a squat heavy pod with four thick petals DROOPING down over it, near-black slag
    > (38,18,18) with dark red (168,38,30) petal edges, glowing cracks, and one molten orange
    > (255,84,26) drip hanging off the lowest petal.

19. **KILNHUSK pod** (Legendary, the tiny kiln)
    > Asset: a pod built like a tiny KILN, a squat grey fired-clay barrel (60,58,56) with
    > stacked bands and straight vertical sides, a small arched door glowing orange
    > (255,148,40) inside, and a stubby chimney on top with a wisp of glow.

20. **PYRELOTUS pod** (Mythic, the obsidian fire-drake lotus)
    > Asset: a violet-charcoal obsidian (52,32,56) pod with three RIBS arcing up and almost
    > meeting at the top to form a hollow cage, a burning coral-orange (255,140,96) core
    > floating inside the cage with its own light, and pink (255,128,148) ember flecks on the ribs.

## Starbloom (biome 5): void carapace, crystal facets, neon cosmic accents

21. **NOVAORB pod** (Rare, the moonbulb prowler)
    > Asset: a pear-shaped BULB pod leaning slightly forward, a cosmic indigo (39,37,82)
    > carapace, a lavender (158,128,255) petal brow arching over its front, and small glowing
    > cyan (110,230,255) star dots.

22. **COSMOSPIRE pod** (Rare, the crescent reedwalker)
    > Asset: a tall gently S-curved SPIRE pod, midnight slate (24,18,46), and a split lavender
    > (180,150,255) crown at the top opening around a small glowing cyan (110,230,255) seed
    > chamber.

23. **VOIDPETAL pod** (Epic, the void panther orchid)
    > Asset: an amethyst-dark (48,30,78) pod wrapped in SIX orchid petals (214,140,255) closed
    > like a mane, pink (255,140,180) petal tips, two slim leaf tails curling at the base, and a
    > soft glow between the petals.

24. **ASTRALHORN pod** (Legendary, the mooncrest stag)
    > Asset: an obsidian (28,22,54) pod with two unequal curved violet (130,100,220) ANTLERS
    > rising from its top, framing a glowing white (242,238,255) crescent moon shape, with a
    > thin silver trim band.

25. **SUPERNOVUS pod** (Mythic, the cosmic star colossus)
    > Asset: an armoured void (20,14,38) pod of overlapping obsidian mantle plates, glowing
    > ice-cyan (180,245,255) pulsar geode gems set into the plates, two gold (255,215,120)
    > crescent tusks curving up the sides, and a small galaxy halo ring floating over the top
    > with its own light.

---

## After generating

1. Check that the 25 concepts look like one family, and that each biome looks like its biome.
2. Model them. Claude can check each import: size against the rules above, triangles, the base,
   and that it carries cleanly.
3. **Nothing in the game changes until you say.** The Pod Guide (`KB/POD-GUIDE-PLAN.md`) shows each
   plant's own pod automatically once it is wired.
