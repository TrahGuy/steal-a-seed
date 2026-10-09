# Pod Guide — what a pod can hatch, taught outside the pod (plan, 2026-10-09)

**Status: BUILT 2026-10-09 by the terminal Claude** (uncommitted, not published; KB/HANDOFF.md, "THE POD GUIDE"). Adapted to one pod per plant: each stand pairs the biome's five pods with their plants; the Bag's "Hatches one of 5" line is dropped; the Bag reaches the Almanac through its menu's WHAT'S INSIDE?. Approved 2026-10-09. The owner approved all four decisions at the bottom
as recommended:

1. "???" silhouettes for plants not yet grown;
2. exact percentages;
3. the size row with its income ratio;
4. a stand inside each biome's arch.

**Pods become one per PLANT (the owner, 2026-10-09).** The owner is modelling 25 new pods from
`output/imagegen/pods/pod-per-plant-v1.prompt.md`. That pod art is the owner's work: the build
never draws or changes a pod. The guide must read each plant's own pod through the builder, so it
shows the new pods the moment they are wired.
The owner chose option A on 2026-10-09: teach players what pods give **without putting any words on a
pod**. The 2026-09-17 rule stays: "A POD CARRIES NO WORDS AT ALL ... no species, no rarity, no
tier, no name" (`CreatureModel.luau` ~2545).

**Queue:** after the rebirth celebration and Phase 1 of "More stealing, less waiting"
(`KB/STEAL-MORE-PLAN.md`).

**The owner is remodelling the pods (2026-10-09).** This plan never draws a pod itself. Every pod
it shows comes from the game's own pod builder (`CreatureModel.BuildPod`, via `ItemArt`), so the
new models appear on the stands and in the Almanac with no extra work. If the new pods differ per
plant rather than per biome, the guide shows each plant's own pod beside it. It reads that from the
data, nothing hard-coded.

## Why

Michael, playtester and fellow developer:

> Every egg style has a RNG set of animals you can collect. So it's super clear what you can get
> from each egg shape. I still don't know what pods give me better or worse items.

## How it works today (code facts)

| What | Today | Where |
|---|---|---|
| Pod shape | **One shell per biome.** All five plants of a biome share it: Greenhollow egg and tendrils, Dustbowl urn, Tanglemire gourd, Emberroot furnace-nut, Starbloom double-star. A pod is effectively an "egg type" holding five possible plants | `SeedData.luau:2043-2053`, `CreatureModel.luau:2083-2189` |
| Exceptions | Secret pods have their own models; a nest stocks one 5% of the time. Rain pods have one shell each. The Rain second family has one shell per size | `SeedData.luau:1211-1235, 1326-1387`, `BiomeData.luau:229, 333` |
| Which plant | Rolled by rarity weight inside the biome (C 1000, U 260, R 55, E 9, L 1.4, M 0.22) | `SeedData.luau:56-65, 2429-2446` |
| Size | Shell width 1.66 to 9.04 studs, plus tier colour (the whole shell in Greenhollow, crown and seam elsewhere). Titan and Colossal add an aura; Colossal adds a glowing core | `CreatureModel.luau:2088-2637` |
| Size odds | Tiny 53%, Big 16%, Huge 10%, Mega 8%, Giant 6%, Titan 6%, Colossal 0.5%. Later biomes boost Mega and up (RarityBonus 1.0 / 1.6 / 2.6 / 4.5 / 9.0, so Colossal runs 0.52 to 1.76%) | `SeedData.luau:890-954`, `BiomeData.luau` |
| Rarity | **Invisible.** It exists only as a hidden attribute | `CreatureModel.luau:2057` |
| Almanac | 25 plant cards (locked: "???", rarity shown) and a detail page (plant, rarity, biome, Tiny yield). **No pods anywhere** | `IndexUI.client.luau:461-788`, `AlmanacView.luau:115-121` |
| Biome entrances | One arch per biome with its name and recommended speed. Nothing else | `MapService.luau:956-1030` |
| Bag | A pod tile shows a real 3D pod at its size, "Unhatched pod", and the size word in tier colour | `InventoryModel.luau:320-426` |
| 3D board pattern | The TOP CREATURES board: a PlayerGui SurfaceGui with Adornee, built within 60 studs and freed past 75. ViewportFrames never render in a Workspace SurfaceGui | `PlotShowcaseView.luau`, `PlotShowcaseUI.client.luau:148-173` |

**Plant odds per biome:**

| Biome | Plant chances |
|---|---|
| Greenhollow | Nubkin 43%, Petalpip 43%, Spiretip 11.2%, Toadcap 2.4%, Bellchime 0.39% |
| Dustbowl | 44.4 / 44.4 / 9.4 / 1.5 / 0.24% |
| Tanglemire, Emberroot, Starbloom | 45.6 / 45.6 / 7.5 / 1.2 / 0.18% each |

## The build

### 1. A POD STAND at each biome entrance (5 stands)

Beside the road, just inside each biome's arch. The arches stand at Z −170 / −470 / −770 / −1070 /
−1370.

- **The pod:** the biome's pod on a slowly turning pedestal, at Big size. It is built by the game's
  pod builder and is display only: never takeable, and **no words on the pod itself**.
- **The board** beside it, a client-built 3D board like TOP CREATURES:
  - title: **"GREENHOLLOW POD"**, and under it **"HATCHES ONE OF:"**;
  - **five plant cards**, each with the 3D plant, its rarity word in rarity colour, and its
    **chance**. The name shows once you have grown that plant; until then it is a dark silhouette
    and "???", exactly like the Almanac;
  - **a secret row:** "SECRET POD: a 5% chance a nest stocks one", with its silhouette;
  - **a size row:** the seven sizes, Tiny to Colossal, each with **this biome's chance** and its
    **income compared with Tiny** (×1, ×7, ×35, ×132, ×412, ×1,300, ×2,375). This is the "better
    or worse" answer.
- Built only within 60 studs and freed past 75, like TOP CREATURES, so at most one stand is live
  at a time.

### 2. The Plant Almanac

- Each biome heading shows **its pod** (3D) and "Pod chances".
- Each plant card adds its **chance**, e.g. 43%.
- The detail page adds "Hatches from: Greenhollow pod (43%)" with the pod's picture, and the
  plant's **income at every size**. Today it shows only the Tiny yield.
- A **POD SIZES** strip at the top: seven shells, each with its chance and its income versus Tiny.

### 3. The Bag

- A pod tile reads **"Greenhollow pod"** instead of "Unhatched pod", still with no plant and no
  rarity, plus "Hatches one of 5 Greenhollow plants".
- Tapping it opens the Almanac at that biome.

### 4. One source for every number

- A pure shared module, `PodGuide`, works out everything from SeedData and BiomeData: each biome's
  plants and chances, each size's chance per biome, and the income ratios. No number is typed in
  twice, so nothing can drift from the real rolls.
- **Specs check:**
  - the chances add up to 100%;
  - they match the real roll functions over 100,000 simulated rolls;
  - names stay hidden until grown;
  - the nest pods still carry no words (a scope guard pins the 2026-09-17 rule);
  - the stands free their viewports.
- **Play:** a guarded Play on the phone and, if the emulator is off, on desktop.

### 5. Two stale comments found on the way (comment-only fixes)

- `CreatureModel.luau` ~2556 says Colossal is the only pod with an aura. Titan has one too.
- `BiomeData.luau:59` says RarityBonus boosts Epic and above. The code boosts **sizes** Mega and up.

## Decisions for the owner

1. **Plants you haven't grown:** a silhouette with "???", rarity and chance (recommended, the same as
   the Almanac), or show every name openly.
2. **Chances as exact percentages** (recommended; that is what egg games show), or as words only
   (Common / Rare / ...).
3. **The size row with its income ratio** (recommended).
4. **Stand placement:** just inside each biome's arch, by the road (recommended). The hub deck has
   no free ground.
