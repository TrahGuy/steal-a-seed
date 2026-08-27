---
name: plant-authoring
description: The end-to-end pipeline for adding or changing a Steal a Seed species, form, growth stage or plant behaviour - art sheet, SeedData row, CreatureModel form switch, stages, Blender preview, PlantService, economy, and what to check in a playtest. Use when adding a plant, changing a form, touching growth or hatching, or wiring a new service.
---

# Adding or changing a plant

Look styling lives in `plant-art-bible`. This is the order of operations.

## 1. Art exists first

A species starts from a reference sheet - `KB/biome1-plants.png`, `KB/biome1-pods.png`. An earlier
pass invented eleven species across all five biomes with no art and was discarded. **Do not fill
biomes 2-5 from imagination.** Greenhollow is the only biome with art.

## 2. `SeedData.Species` row

`src/ReplicatedStorage/SeedGame/Shared/SeedData.luau`. Fields:

```
Id  Name  Rarity (FORM tier)  Biome  Kg (old-save fallback ONLY)
Height (frame height at reference weight)  Form  Body  Crown  Accent  Leaf  Soil
```

Leaf and Soil take the shared biome constants. Three asserts run at require and will refuse the
file: duplicate Id, a `Rarity` missing from `GameConfig.RarityTier` or `SeedData.RarityWeight`, and
a fallback `Kg` outside `0..GameConfig.Carry.MaxKg`.

## 3. `CreatureModel` form switch

`src/ServerScriptService/SeedGameServer/CreatureModel.luau`. Existing forms:
`cube | orb | teardrop | mushroom | bell`.

Reuse one, or add a form built from the **same part vocabulary** - `part()`, `upright()`, `ball()`,
`wedge()`, and the Block/Ball/Cylinder/Wedge approximations documented at the top of the file. A new
form sets `faceCF` and `faceW` if the face does not ride the widest part of the head.

`kg` is an argument, not a property of the species. Nothing in this file may read `sp.Kg`.

## 4. Stages

```
CreatureModel.STAGE_POD    = 1
CreatureModel.STAGE_SPROUT = 2
CreatureModel.STAGE_GROWN  = 3
```

**The sprout is dead in gameplay.** `STAGE_SPROUT` still exists and still builds, but nothing in a
bed is ever one - it existed to make a plot look busy halfway through a timer and it had no decision
in it. A save carrying a sprout restores as a pod. `GameConfig.Plant.SproutAt` is kept and unused so
old stage arithmetic still reads. Do not reintroduce a sprout without a decision attached.

**Nothing hatches on its own.** A pod whose timer finished an hour ago is still a pod until somebody
holds E. That is why `Stage` is saved rather than derived from the clock.

Growth time is `SeedData.GrowSeconds(kg)` = `20 + 280 * (kg/MaxKg)^0.45`, never a per-species
constant. The heaviest thing in the game takes about five minutes on purpose: the wait is a
vulnerability window, and a window nobody is awake for is not a window.

## 5. Keep the Blender preview honest

`tools/blender/plants_biome1.py` holds **inlined copies** of the SeedData numbers - `SIZE_REF_KG`,
`SIZE_EXP`, `GIRTH_REF_KG`, `GIRTH_EXP`, the colours and the forms. Change SeedData, change these to
match. See `blender-to-roblox`. The preview is a picture of the live model, never a replacement
mesh.

## 6. `PlantService`

`src/ServerScriptService/SeedGameServer/PlantService.luau` owns place-by-click, hatch-by-hand and
pick-back-up. Attributes the rest of the game reads:

```
CreatureModel   SpeciesId  Rarity (FORM tier)  Kg  Stage
PlantService    PlacementId  PlantedAt  Ready  Hatching
tag             GameConfig.Tags.Planted
```

- **Read the `Stage` attribute, not the model name.** Names are `Pod_<id>` / `Creature_<id>` and are
  not a contract.
- `PlacementId` is identity, not position - PlantSway phases its idle off it so a bed is not a
  chorus line, and GardenUI keys its rows on it.
- The `Planted` tag is what stops a plot pod being treated as loot, and is the seam PlantUI and
  PlantSway both watch. One tag does three jobs.
- `Hatching` and `Ready` are attributes so the client animates locally; do not push CFrames per
  frame for anchored server-owned pods.
- Plants are parented into the plot's `Plants` folder (`Runtime` is its sibling). Both are cleared
  when a plot is released.

## 7. Economy

Cash mints in `EconomyService` and nowhere else. A grown plant pays `kg * CashPerKg` per second.
A new plant needs no economy code - if you are writing a payout outside EconomyService, stop.

## 8. Do not spoil the hatch

Two Commons arrive in identical shells and which one you got is not knowable until it opens. The
Garden prints `???` on a buried pod for that reason.

```
unhatched   tool.Name = "???"          ToolTip "Unhatched pod . N kg"  - no species, no rarity word
hatched     tool.Name = species.Name   ToolTip uses species.Rarity     - the Index word
```

`SpeciesId` still stamps the Tool (planting has to know what to build); the player just cannot read
it off the toolbar. The Index unlocks on hatch and nowhere else - `MarkSeen` at `render()` is only
the backfill for a garden restored from a save that finished while the player was away.

## 9. Playtest checks

- Identifiable by silhouette at distance, in a bed, off-axis and backlit.
- A grown plant is silent of plates - no billboard, only the `+$N` pop.
- Weight readable off the pod alone: shell colour is the band, diameter is the weight.
- Plot part count still sane - see the counted budget in `plant-art-bible`.
- Form rarity vs weight band used in the right place: Index and hatched ToolTip take the form word;
  pod shell, `ColorForKg` and the grown Garden row take the band colour.

## Adding a service

Drop a `*Service.luau` in `src/ServerScriptService/SeedGameServer/`. `ServerMain` finds it, orders
it by `Priority`, runs `Init()` then `Start()`. There is no registry to update.

`CreatureModel`, `ParentModel`, `MapDecor`, `HubFairy` and `ProfileSchema` are deliberately **not**
`*Service` - no lifecycle, just geometry or types.

**Never rebuild an existing system.** PlantService, PlotService and EconomyService already exist;
check the repo before adding code.
