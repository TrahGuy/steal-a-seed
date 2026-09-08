# Static plant-card backgrounds

Five illustrated background plates, one per biome, supplied 2026-09-08 and used
behind every species that lives on that road.

Background scenery ONLY. The real static ViewportFrame plant is drawn in front
of these -- there is no creature, name, rarity, statistic, border or animation
baked into any of them.

    biome1.png  greenhollow  sunlit woodland, moss, oversized leaves, white flowers
    biome2.png  dustbowl     dunes, cracked clay, sandstone mesas, warm dusty light
    biome3.png  tanglemire   swamp water, reeds, hanging roots, layered mist
    biome4.png  emberroot    basalt, charred ground, restrained magma light
    biome5.png  starbloom    alien garden, luminous flora, nebula sky

`<biome>-bg.png` beside each master is the 512px runtime copy that was uploaded.
512 because a card is 116-151 pixels wide; the 1254px masters are kept as the
source and are not what the game loads.

Asset ids live in `GameConfig.Card.Art`, which maps all 25 species onto these
five. Every id there came back from an upload -- never hand-write one.

Hidden Index species and unrevealed Garden pods get the neutral dusk gradient
instead: a backdrop is identity, and naming the biome narrows the species to
five.

## Superseded, not deleted

Five bespoke Greenhollow backdrops drawn by `tools/art/card_backdrops.py` were
used here before. Their ids are recorded in the comment above `GameConfig.Card`
and the script still exists. They were dropped for cohesion, not for quality --
two art styles in one collection reads as a bug.

## Note on the previous README

The file that stood here described a Dustbowl per-species batch
(`dunebud-background-v1.png` and four siblings). Those files are not in this
folder; their prompts are still at
`output/imagegen/cards/backgrounds/`. The description did not match the
contents and has been replaced.
