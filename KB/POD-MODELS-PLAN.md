# The owner's 25 pods in the game — plan (2026-10-09)

**Status: BUILT 2026-10-09 by the terminal Claude** (UNCOMMITTED, NOT PUBLISHED). The results, the
numbers and the open owner calls are in KB/HANDOFF.md, entry "THE OWNER'S 25 PODS IN THE GAME".

Approved 2026-10-09 (the owner: "approve but let claude terminal build"). Decisions 1-4 were approved
as recommended:

1. the size rule;
2. a seam ring for the 12 studded pods. **Dropped by the owner's change below: no ring**;
3. the lid-pod idle. **Changed by the owner: no breathing. The lid peek and the glow pulse stay**;
4. the stud textures kept as built.

Decision 5: the terminal Claude built it, right after hatch-in-Bag (Phase 1) and before the Pod Guide.

## The owner's change, mid-build (2026-10-09)

The owner: "disable breathing animation on pods, and remove the base if there is a base below the pods
for us to save time". What that became:

- **No breathing.** No pod's root bobs: not the 12 studded pods (their scripts' root bob is not
  ported), not the 13 lid pods (their breathing idle is gone). What stays: the studded pods' joint
  motions (petals, leaves, spikes, blades, digits, quill, handle) and their lamp pulses, the lid peek,
  the glow pulse, and the ready-to-hatch behaviour. Reduced FX still stops all of it.
- **No bases.** The base parts are removed at import, with every weld that joined them. Each pod's
  bottom and scale are measured after the removal.
  - Lid pods: `SeedBase` (all 13); `PlinthBevel` (Astralhorn, Bellchime, Pyrelotus, Slagbloom);
    `BasePlinth` (Cosmospire, Toadcap); `BulbPlinth` (Novaorb).
  - Studded pods: `FlatBase` (all 12); `BaseRim` (Cinderpaw); `PlinthBase` (Emberquill, Lanterncap).
  - **Kept on purpose** (the owner's list): Nubkin's `Bottom_*` parts, Lanterncap's `RoofPlinth`,
    Bellchime's `StalkBase`.
  - **Checked by eye and kept:** Raincup's `GobletFoot` (the goblet's own foot), Paddlehop's
    `RimBottom` (the fourth side of the pad's frame), Dunebud's `FrontBaseRim` (the husk's lip).
  - 35 parts in all. Each pod's data module lists its own under `Removed`.
- **No seam ring.** The 12 studded pods show their size by scale alone, plus the Titan and Colossal
  effects. The lid pods keep their own `SizeSeam` in the tier colour (Bogbonnet has none).
- The owner's Workspace models are untouched. The .rbxm backups still hold the bases.

The owner modelled one pod per plant (25), from `output/imagegen/pods/pod-per-plant-v1.prompt.md`,
and put them in Studio in five Workspace folders: `greenhollow pods`, `dustbowl pods`,
`tanglemire pods`, `emberroot pods`, `starbloom pods`. The ask: "add animation and increase size by
scaling them depending on size tier".

**Those folders are the owner's source. Never move, edit or delete them.**

## The owner's follow-ups (2026-10-09, after the build; "approve your suggestions, let terminal do it")

- **Pale pods glow softer at Colossal.** The Colossal's two lights, not the aura's halo, washed the pale pods
  white. Their strength and reach now follow the pod's own brightness (`GameConfig.PodModels.PaleGlow`): every
  Greenhollow and Dustbowl pod, Lanterncap and Gloomlotus are softer; Emberroot, Starbloom and Tanglemire's dark
  pods keep the full glow.
- **No shadows.** No light on a built pod casts shadows. Sixteen of the owner's did: ten fill lights and six of
  the pods' own.
- **The source folders are in ServerStorage**, moved intact from the Workspace, so their 25 scripts never run in
  a server and a publish keeps them out of the live map. The backups are unchanged.
- **No change:** the stud textures (switch only if a phone lags) and Cinderpaw's and Emberquill's proportions.

## What the pods are (measured in Studio, 2026-10-09)

- 25 Models, 1,207 parts in all (19 to 78 each, about 48 on average). Parts, WedgeParts and
  SpecialMesh spheres and cylinders: **no MeshParts and no uploads**. Plastic, with Neon glows and
  2 Glass parts. 27 PointLights. Nothing collides.
- **Two build styles:**

| Style | Pods | What they carry |
|---|---|---|
| **Studded, with an idle animation** | Nubkin, Petalpip, Spiretip, Dunebud, Paddlehop, Thornwhorl, Raincup, Suncrown, Crookreed, Lanterncap, Cinderpaw, Emberquill | A `PodAnimate` server Script per pod: a Heartbeat loop moving the anchored root (a breathing bob) and Motor6D C0 waves (petals, leaves, spikes, blades, digits, quill, handle). Stud Textures: 3,102 in all (Suncrown 414). No size seam |
| **Lid pods** | Toadcap, Bellchime, Bogbonnet, Snapmoss, Gloomlotus, Kilnhusk, Pyrelotus, Slagbloom, Novaorb, Cosmospire, Voidpetal, Astralhorn, Supernovus | A `PodOpening` server Script: a `LidHinge` tweened by `OpenAmount`, plus light switches. A **`SizeSeam` folder** (made for the size colour) and a `GlowAccents` folder. `ClosedWidth` / `ClosedHeight` attributes give their designed size in pod widths. **No idle motion** |

- **Proportions vary:** Emberquill is 2.7 times taller than wide; Cinderpaw is flat (0.32);
  Crookreed and Gloomlotus are tall; most are 1.1 to 1.5.

## What the game needs from a pod (the code contract)

`CreatureModel.BuildPod(species, tier, cf, parent)` is the one builder. Nests, loose pods, carrying,
banking, the Bag, hatching, guardians and debug all call it.

- **Identity:** named `Pod_<id>`, with attributes SpeciesId, Rarity, Tier and Stage = 1.
  PickupSound "ColossalPickup" at Colossal.
- **`cf` is the base:** the bottom centre.
- **The PrimaryPart is named "Shell"**, a direct child, upright, at the pod's middle. Its axes become
  the carried pose, so a rotated Shell is carried on its side.
- **All parts are anchored**, with CanCollide, CanQuery and CanTouch off. The nest turns CanQuery
  on for taking; carrying unanchors, welds and makes them massless.
- **Size D** = 1.66 / 2.59 / 3.66 / 4.87 / 6.09 / 7.94 / 9.04 (Tiny to Colossal). D drives the carry
  grip (0.85 + D/2), the guardian haul (a sphere of D/2 plus 0.4), the hatch effects and the label
  lift. The shipped pods run 1.21 to 1.46 D tall, and the nest ring is sized for 10-stud pods.
- **Tier effects:**
  - every tier: the seam in the size colour;
  - Titan: vent, trail and aura;
  - Colossal: a glowing Neon core and a stronger aura.
- **No text anywhere.**
- **Precedent:** the two Secret pods are owner models **replayed from data** (`SecretForms`, through
  `SecretModel`), never cloned from a stored model. The repo keeps no .rbxm files; the map is code.

## The build

### 1. Import, read-only and lossless

- A generator reads each pod from its Workspace folder without touching it. It writes one data module
  per pod, `Shared/PodForms/<id>.luau`, holding every part:
  - class, SpecialMesh (type, scale, offset), size, CFrame relative to the bottom centre;
  - colour, material, transparency;
  - the stud Textures per face;
  - lights, joints (Motor6D, Weld and WeldConstraint, by part index);
  - folder membership (`SizeSeam`, `GlowAccents`) and the part and model attributes.
- `.rbxm` backups go to `output/model-backups/2026-10-09-pod-originals/`, as for the Secret pods.
- **The per-pod Scripts are not imported** (see 3).
- `SecretModel`'s replay learns SpecialMesh and Texture, so the pods come back exactly as built and
  nothing becomes a block.

### 2. Building one: scaled to its size tier

- **Scale:** uniform, so the pod **fills its tier's box: at most 1.25 D wide and 1.45 D tall.** This
  is the same box the carry, haul and nest code are built for. The 13 lid pods use their own designed
  `ClosedWidth` / `ClosedHeight`, so they come out exactly as designed. Joints, lights and studs scale
  with the pod, so it looks exactly as built, only bigger.
- **The contract:** an invisible upright "Shell" PrimaryPart at the pod's middle, the identity
  attributes, everything anchored and inert, PickupSound at Colossal. **Carrying, hauling, prompts
  and labels keep working unchanged.**
- **Size colour:** the lid pods' `SizeSeam` parts take the tier colour. The 12 studded pods have no
  seam. The plan gave them a slim seam ring at the base; **the owner's change dropped it**, so they show
  their size by scale alone. Titan and Colossal keep today's aura, vent and glowing core.
- `CreatureModel.BuildPod` hands these 25 species to the new builder. Secret and Rain pods are
  unchanged.

### 3. Animation: one client script for every pod

- **Removed:** the 25 server Scripts. In a full server they would mean dozens of Heartbeat loops
  moving parts on the server and sending every move over the network.
- **Added:** one client animator, `PodMotion`, like `PlantSway` and `MillFormMotion`, which moves only
  what each player sees:
  - **the 12 studded pods:** their own idle motions, ported one to one from their scripts, without
    the root's breathing bob (the owner's change);
  - **the 13 lid pods:** a new idle: the lid peeking open a crack and closing again, and the glow
    lights pulsing. The planned breathing bob was dropped (the owner's change);
  - **ready to hatch** (planted pods from old saves): lid pods open part way; studded pods' idle runs
    twice as fast.
- **Only world pods** within about 120 studs move: nests, loose pods, planted pods and the Pod Guide
  stands. Bag and hotbar pictures stay still. **Reduced FX: no motion.**

### 4. The Bag shows the real pod

`InventoryModel` (342-355) draws a biome's representative pod for every Bag pod. With one pod per
plant it must draw the item's own species. That file belongs to the terminal Claude's Phase 1, so it
makes that one change.

### 5. Tests

- A new `PodModelsSpec`:
  - every pod matches a fingerprint of the owner's originals;
  - the contract holds at all 7 sizes;
  - every pod fits its box at every size;
  - the seam takes the colour;
  - no Scripts come in;
  - every animation recipe finds its joints.
- **Rewritten:** `DustbowlPodSpec`. Its pins describe the old pods: no SpecialMesh, a cylinder Shell,
  9 or 10 parts.
- **Updated:** ReachPointSpec, PlacementCircleSpec, PlantStreamingSpec, RainPodsSpec and the
  source-text pins.
- **One guarded Play:**
  - all 25 pods at Tiny, Mega and Colossal;
  - take, carry, guardian haul and confiscation, drop, a planted hatch, Bag tiles;
  - **performance:** parts, stud textures and frame time at the biggest nest.

## Decisions for the owner

1. **Size rule:** each pod fills its tier's box (at most 1.25 D wide and 1.45 D tall), and lid pods use
   their own designed size? (Recommended.)
2. **Size colour on the 12 studded pods:** a slim seam ring at the base (recommended), or none (size
   shown by scale only)?
3. **Lid pods' idle:** breathing, a small lid peek and a glow pulse? (Recommended.)
4. **Stud textures:** keep them as you built them (recommended). Switch to the game's own stud surface
   only if the Play shows phones struggling.
5. **Who builds it:**
   - (a) this Claude, now, in parallel. It touches only the pod files and leaves the terminal's
     hatch-in-Bag files alone (recommended: the Pod Guide needs these pods);
   - (b) queue it for the terminal Claude after hatch-in-Bag.
