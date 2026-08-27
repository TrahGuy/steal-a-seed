---
name: plant-art-bible
description: The Greenhollow visual system for Steal a Seed - species forms, the two rarity vocabularies, the colour table, the size curves, the counted part budget, the face, and what may hang over a plant. Use when touching how a plant, pod, sprout or creature LOOKS - silhouette, colour, rarity readout, growth-stage visuals, part counts, billboards, or adding a species.
---

# Greenhollow art bible

Source of truth: `src/ReplicatedStorage/SeedGame/Shared/SeedData.luau` and
`src/ServerScriptService/SeedGameServer/CreatureModel.luau`. Sheets: `KB/biome1-plants.png`,
`KB/biome1-pods.png`. **Greenhollow only.** Biomes 2-5 have no art; do not invent species for them.

## Species is SHAPE. Weight is the prize.

Every pod rolls its own weight, 1..10,000 kg, on one curve shared by all five species
(`SeedData.RollKg`, `MaxKg ^ (u ^ 2.2)`). A 10,000 kg Nubkin is legal. A 12 kg Bellchime is legal.

- `1 kg = $1/s`. `SeedData.IncomePerSecond(kg) = kg * GameConfig.Carry.CashPerKg`, CashPerKg = 1.
- **`species.Kg` is the old-save fallback only.** Paying from it, sizing from it, or measuring from
  it is a bug. `CreatureModel` may not read it at all.

## Two rarity vocabularies. They share four words. Do not mix them.

| | what it means | who uses it |
| --- | --- | --- |
| **Form rarity** (`species.Rarity`) | how often that SHAPE drops | the Index, `SeedData.FormColor`, hatched ToolTip |
| **Weight band** (`SeedData.RarityForKg`) | what THIS pod is worth | pod shell colour, `ColorForKg`, grown Garden name tint |

Form rarity: Nubkin Common, Petalpip Common, Spiretip Uncommon, Toadcap Rare, Bellchime Epic.
Drop weights are `SeedData.RarityWeight` (Common 1000 .. Divine 0.004).

Weight bands, floor to name: `0 Common, 10 Uncommon, 30 Rare, 100 Epic, 400 Legendary, 1500 Mythic,
5000 Secret, 9000 Divine`.

Which surface takes which:

```
form word            Index, hatched ToolTip          species.Rarity / SeedData.FormColor
weight-band colour   pod shell, grown Garden name    SeedData.ColorForKg
```

**The Index must never be tinted by kg.** It lists shapes, and a shape's colour is how often that
shape drops. Two Commons still share a form tier - kg is what makes two pods look different, and the
Index is the one place that difference does not belong.

An unhatched pod gets neither word: Epic means Bellchime in Greenhollow, so printing the form rarity
names the species through the back door on the one item that has to stay `???`.

Band colours are `GameConfig.RarityColor`. The first five were sampled off the pod artwork.

## Colour: the biome is what is shared

Stem, leaf and soil are **identical on all five and must stay so** - that family resemblance is what
makes the fifth read as a Greenhollow creature rather than a stray. The HEAD is where a species gets
to be itself.

```
Leaf 86,150,66    Stem 124,182,92    Soil 124,76,50    Blush 238,150,138 (shared cheeks)
```

```
Nubkin     leaf green         Body 146,196,106  Crown 176,214,128  Accent 242,238,206
Petalpip   pale yellow-green  Body 206,224,132  Crown 250,246,226  Accent 232,132,106
Spiretip   deep pine          Body  94,152,104  Crown 236,242,206  Accent 242,246,220
Toadcap    warm cream         Body 240,228,198  Crown 216,112,100  Accent 250,246,226
Bellchime  cool porcelain     Body 214,226,242  Crown 240,150,168  Accent = Leaf
```

Spiretip is the only dark and the only cool green. Toadcap is warm cream against Bellchime's cool
one. **Still all greens and creams, deliberately** - spending saturated colour in the first biome
leaves Emberroot and Starbloom nothing to be. Copy exact Color3s from SeedData, never eyeball.

Soil is pitched a shade darker and browner than MapService's bed (158,82,52) so the heap reads as
the same dirt shovelled up. It was 74,54,44 and read as coal.

## Size: two scalars that MULTIPLY. Never uniform-scale.

- `Height` on the sheet is the **frame** height at the reference weight, not the finished
  silhouette. 2.4 / 3.0 / 3.2 / 3.6 / 4.0.
- `SizeScale(kg)` = `(kg/7.5) ^ 0.20` - tallness. Reference 7.5 kg is the median roll, so a median
  pod stands at exactly its sheet size.
- `Girth(kg)` = `(kg/14) ^ 0.12`, clamped 0.70..2.40 - fatness, a proportion not a size. Reference
  14 kg returns exactly 1.00.
- H and G stay separate arguments through the whole builder. Scaling the model uniformly collapses
  the width spread the girth curve exists to create.
- `SPROUT_SCALE = 0.45` is leftover for a stage that still builds but never appears in a bed. It is
  not a third size to design against - a plant is a pod or it is grown.

A Nubkin stays shorter than a Bellchime at **every** weight - that is what keeps the form readable
while the weight decides how much of it there is. Finished heights, soil to crown:

```
kg        Nubkin  Petalpip  Spiretip  Toadcap  Bellchime
     1       1.2      1.6       2.5      2.4       2.5
   110       4.0      5.6       8.1      9.0       9.2
10,000      14.1     19.9      27.7     33.4      33.8
```

DECIDED, do not re-open: `Height` stays a frame height, and the four written size targets cannot all
hold at once - `SIZE_EXP` is a least-squares fit to all of them. The reasoning is in SeedData; read
it before proposing a better exponent.

**Pod diameter follows weight too**: `1.2 * kg^0.23`, clamp 1.3..10.5. Heavy must look heavy from
across the nest with no UI - the pod tells you what the carry will cost before you commit to the
hold. The clamp is a rail, not a limiter.

## Forms, and the shapes the engine does not have

Block, Ball, Cylinder and Wedge only. Roblox has no cone, no egg, no dome:

```
teardrop   Ball + two mirrored Wedges above it
dome cap   Cylinder disc + Ball resting on it
bell       FIVE stacked Cylinders widening downward, the fifth a shallow ridge at the hem
egg (pod)  two overlapping Balls, the upper smaller
```

**A Ball takes its diameter from its SMALLEST axis.** Setting a Ball to (4,1,4) gives a sphere of
diameter 1, not a squashed one. This catches everyone once.

Silhouette-first: cube / orb / teardrop / mushroom / bell is what a player recognises in a crowded
bed, including backlit and off-axis. The name is not available at distance.

Per-form sculpture exists to fix a specific failure - do not strip it: Nubkin's brow and corner
nubs, Petalpip's cupped petals and three sepals, Spiretip's banded collar, Toadcap's gills,
Bellchime's hem ridge and scalloped collar, and every species' offset leaflet (two blades at the
same height and angle read as a rotor from above).

## The face is nine parts

Two Eyes, two Glints, two Cheeks, three Smile bars.

- Eyes are dark **balls centred ON the surface** so half stands proud. The radius IS the proudness;
  no fudge factor. They are lumps of the same moulded plastic, not stickers on it.
- **One shared light**: the glint sits upper-LEFT on BOTH eyes, not mirrored. That is what makes two
  spheres read as one lit face instead of two googly eyes.
- Cheeks at 1.45 gaps and 0.88 of `front`. `front` is the surface distance at the CENTRE of the face
  and four of five heads are spheres, so the surface falls away outboard - further out and a cheek
  hangs in the air beside the head.
- Smile is three blocks, ends lifted 0.030. One bar reads as a grimace.
- `front` is per-form: the widest part of a head is not always the part the face sits on. The bell
  proved it with a smile inside its own skirt.

**Studs on everything except the face and the soil clods.** Glints and smile are smooth; a glint is
the one thing on a creature meant to look wet. Studs go on all six surfaces, not just the top.

## The part budget, counted

```
shared body 13 (base 1, soil 7, stem 1, leaves 4) + face 9 = 22

Nubkin     cube       head  7  ->  29
Petalpip   orb        head 10  ->  32
Spiretip   teardrop   head 10  ->  32
Toadcap    mushroom   head 17  ->  39
Bellchime  bell       head 18  ->  40
```

A tier-1 bed of twelve at the worst form is **480 parts**. Target band is 25-40 per grown plant.
Budget against the grown plant - it is the only built stage a bed ever shows.

When a head needs parts, pay for them below eye level or behind something: soil clods went 9 to 7,
buds 7 to 4, collar petals 8 to 5, gills 6 to 4, spots 5 to 4. Mobile first, no per-frame allocation.

Decorations are literal tables, never random - two servers must build the same creature, and a bug
report saying "the third one looked wrong" has to mean something.

## Nothing hangs over a grown plant

A grown plant carries **no billboard at all**. Twelve three-line cards over one patch of dirt is a
wall, and the owner cut it. What it earns is the `+$N` popping off it every second; what it IS lives
in GardenUI and the Index.

Pods may show `HATCHING` + `m:ss` - the one case where the world has nothing to say for itself.
Those billboards are born disabled and only enabled by `refresh()`, and they drop the moment the
`Ready` attribute appears, because a 0:00 clock beside a HATCH prompt is two things saying the same
thing. (`GROWING` is the sprout string; PlantUI still carries it, but nothing in a bed is ever a
sprout - see plant-authoring.)

No weight billboard anywhere. The shell is coloured by its band and sized by its weight; a label
would be the same fact a third time, and on a creature it measured wrong.

## Nothing is placed by hand

Every plant is built by `CreatureModel.Build` and parented into the plot's `Plants` folder, which
`PlotService` owns (`Runtime` is its sibling; both are cleared on release). There is no prefab in
the place file. The CFrame handed to both builders is the **BASE**, where it meets the ground - the
same contract in `BuildCreature` and `BuildPod`.

`BuildPod` does not tag itself `SeedPod`. Whether a pod is loot is a gameplay claim and the caller
makes it - a pod hatching in somebody's plot is not loot, and tagging it there once ran the whole
raid alarm inside the safe zone.
