# Reference analysis: what footage can and cannot tell you

Study a reference to learn *visual principles*, then design an original Steal a Seed creature.
Never copy a reference creature, its name, its labels or its numbers.

## The rule: observed, inferred, proposed

Write three separate lists and keep them separate in every note, brief and handoff:

1. **Observed** -- what is visible: silhouette, proportions, pose, colour regions, value contrast,
   where the eye goes, surface rhythm, scale against the avatar, the camera angle.
2. **Inferred** -- plausible explanations, each marked as an inference.
3. **Proposed** -- how the principle becomes an original botanical creature in this game.

### What footage cannot establish

| question | why a screenshot or video cannot answer it |
| --- | --- |
| Parts, unions or MeshParts? | A MeshPart can carry a stud-like texture; flat shading looks like planar parts; parts can look smooth under lighting. Construction is invisible. |
| Topology, triangle or part count | Only the outline is visible, never the wiring. |
| Rig, joints, animation quality | A still shows one pose; a clip shows the result, not how it is driven. |
| Performance | Nothing about frame cost is visible, and the recorder's machine is unknown. |
| Material vs texture vs effect | Bloom, Neon, emissive textures and particles blend on screen. |
| Exact sizes and ratios | Perspective and camera distance distort every length. |

## The 2026-09-24 reference video

`C:\Users\Maykel\AppData\Local\Packages\Microsoft.ScreenSketch_8wekyb3d8bbwe\TempState\Recordings\20260924-1326-48.7721893.mp4`
-- 57.5 s, 1278 x 944, 30 fps, a screen recording of another Roblox collecting game. Frames were
extracted at one per second with ffmpeg to `D:\KAPE\output\blender-creature-skill\reference-frames\`
(contact sheets `sheet_01..05.png`, full frames `t*.jpg`); none are committed. Times below are
seconds into the clip.

### Observed

- Fenced garden plots on a bright green studded field, a third-person camera above and behind a
  small avatar, and creatures many times the avatar's height (0-47 s).
- A black winged creature with red membrane wings, pale tapered claws and a lighter chest (0-4 s).
- A creature with yellow feathered wings whose flat plates show a stud-like tile pattern (0 s).
- A white four-legged "mammoth" with long glowing cyan tusks (8-11 s, 23 s).
- Grey long-snouted reptiles built from broad flat facets with a tile-like surface pattern, open
  jaws lined with pale teeth, clawed limbs (18-22 s).
- A large blue shark-like creature with an enormous open mouth: crimson interior, big irregular
  pale teeth, a smooth faceted blue body with no visible stud pattern (30-33 s).
- A black creature with glowing orange crack lines (35-36 s).
- A desert area: nests holding stacked, tiered pods and a tan skeletal scorpion made of slender
  beams (55-56 s).
- Every creature carries billboards (rarity word, name, income per second) and floating income
  numbers; bloom, sparkles and purple auras often cover the geometry.

### Inferred (not established)

- The stud-like pattern could come from Parts with stud surfaces, a studs texture on MeshParts, or
  a SurfaceAppearance. The faceted forms are consistent with part builds *or* flat-shaded meshes;
  the shark's smooth large planes are consistent with a mesh. None of this is known.
- Part counts, triangle counts, rigs and performance are unknown.

### Principles worth transferring (proposed, adapted to botanical guardians and plants)

- **One dominant signature per creature**: a maw, wings, tusks, a tail. In this game: one crown,
  one bloom-maw, one root mantle, one seed-shell -- not all four at once.
- **Focal contrast at the face**: a dark or saturated mouth interior against the body value; pale
  teeth or claws against a darker body. The eye should land on the face first.
- **Tapered, curved claws, teeth and horns with an irregular rhythm** -- never a row of identical
  spikes.
- **Broad, chunky planes that read at distance**, with surface rhythm only on large quiet areas.
- **Scale as a reward**, but inside the project's size tiers.
- **Readable from above and behind**, because that is where the player's camera sits.

### Do not copy

The species, names, labels and income numbers; the animal identities as they are (sharks, dragons,
dinosaurs); gigantic scale beyond the tier curve; the bloom and aura density; the label clutter.
The footage is also an anti-lesson: effects and billboards regularly hide the forms, which is why
this skill reviews plain geometry before colour and effects.

## Claims in sibling skills that are not established

Listed so nobody repeats them as fact. This skill does not rewrite those files; amending them is
the owner's call.

- **`primitive-organic-sculpting`, section 1** states the reference creature is "100% built from
  Roblox native primitive parts" because "External mesh generators ... cannot map native engine
  studs". Unsupported: construction cannot be read from footage, and a MeshPart can show a
  stud-like texture. Treat it as an inference at most.
- **`colossal-titan-sculpting`, section 4** calls `FrontLeft_TitanThigh ... TitanSkull ...
  TitanCarapace` the "PlantSway rig naming convention". PlantSway's real rules
  (`src/StarterPlayer/StarterPlayerScripts/PlantSway.client.luau`, checked 2026-09-24): arms are
  direct children named exactly `Leaf`; legs are names containing Thigh, Femur, Haunch, Shin,
  Tibia, Knee, Hock, Foot, Hoof, Paw, Toe, Stilt or Pillar, and the leg rig turns on only if a
  Thigh, Femur or Haunch exists; roots are `Root<Word><n>` / `PropRoot<n>` with `RootRise<n>`.
  `TitanSkull` and `TitanCarapace` are not contracts; a plant's root is its `Base` PrimaryPart.
  Its section 5 budgets ("maximum 1" PointLight, emitter "rate <= 24 to preserve mobile 60 FPS",
  "70 to 90" parts) are not derived from any measurement in this project.
- **`blender-to-roblox`** (and the `plants_biome1.py` docstring): "Roblox (x, y, z) maps to Blender
  (x, z, y)" is a reflection (determinant -1). Symmetric forms survive it; asymmetric details land
  on the wrong side. The proper rotation is Roblox (x, y, z) -> Blender (-x, z, y), creature facing
  -Y. Separately, `parent_biome1.py` exports with `axis_forward="-Z"`, the FBX exporter's default;
  tested 2026-09-24 on this skill's calibration set, that writes a creature facing Blender -Y as
  facing file +Z -- turned 180 degrees for a -Z-forward reader. Those files never went live and the
  scripts are unchanged here.
- **`plant-art-bible`**: the kg curves and the 25-40 part band are Greenhollow-era. Current
  `PlantFormsSpec` budgets are 48 parts for leg species and 56 for root species, and weight is a
  tier. `seed-premium-creature-art` already warns about this.
