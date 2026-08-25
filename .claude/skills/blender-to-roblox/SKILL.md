---
name: blender-to-roblox
description: How the Steal a Seed Blender previews work - the two scripts under tools/blender, their CLI flags, the Z-up and facing conventions, and the rule that the inlined numbers are copies of SeedData. Use when the task mentions Blender, FBX, glTF, a plant or parent preview, rendering a lineup, export, or axis and scale conversion.
---

# Blender is a preview, not a pipeline

`tools/blender/` renders **pictures of models the game already builds in Luau**. The shipped
geometry is `CreatureModel` and `ParentModel`, in git, built at runtime. Nothing here becomes a live
asset.

- **Do not import an FBX from `out/` as the live creature.**
- **Do not route plants through `generate_mesh`, `generate_procedural_model` or
  `generate_material`.** Live plants are Luau part-builds.
- **Do not add `blender-mcp`** or any marketplace plugin unless asked. The CLI is the path.

## Commands

```
blender --background --python tools/blender/plants_biome1.py -- --render
blender --background --python tools/blender/parent_biome1.py -- --render
blender --background --python tools/blender/parent_biome1.py -- --export
```

Both parse argv after a bare `--`, and both default to `--render` when no flag is given
(`DO_RENDER = "--render" in argv or not argv`). Only `parent_biome1.py` has `--export`; it writes
`out/parent_biome1.fbx` with `use_selection=True`.

Output goes to `tools/blender/out/`, which the script creates and `.gitignore` excludes - these are
build artefacts, regenerate them rather than committing them. Current contents:
`plants_lineup_front.png`, `plants_lineup_quarter.png`, `parent_front.png`, `parent_side.png`,
`parent_back.png`, `parent_biome1.fbx`.

Renders use the `BLENDER_WORKBENCH` engine with STUDIO lighting, cavity on, material colour - flat
and readable, not a beauty pass.

## Which script mirrors what

| script | mirrors | notes |
| --- | --- | --- |
| `plants_biome1.py` | `CreatureModel` | the five Greenhollow grown plants, mound-stem-leaves-head-crown-face. No legs. |
| `parent_biome1.py` | `ParentModel` | the nest guardian, built from **metaballs**, not the Roblox part vocabulary. |

Keep each in sync with its counterpart. They are not interchangeable.

`parent_biome1.py` uses metaballs deliberately: elements sharing a base name blend into one surface,
so a chain of spheres becomes a tapered limb rather than a pile of segments - the same failure the
87-part Roblox build had. Two metaball objects (`MetaBark`, `MetaFlesh`) so bark and green plates
intersect without merging. Hard details - teeth, claws, thorns, eyes - stay crisp primitives on top.

## Axes and scale

- **Blender is Z-up. Roblox is Y-up.**
- Roblox `(x, y, z)` maps to Blender `(x, z, y)`: up becomes Z, and facing `-Z` becomes facing `-Y`.
- **Plants face `-Y`**, the same as the parent script.
- Origin sits at the base of the stem / soil mound - the same BASE contract `CreatureModel.Build`
  takes, so a preview and a live model agree about where the ground is.

## The numbers are copies, and Luau wins

`plants_biome1.py` inlines SeedData so it does not need a Luau runtime:

```python
SIZE_REF_KG = 7.5    SIZE_EXP = 0.20
GIRTH_REF_KG = 14.0  GIRTH_EXP = 0.12
```

plus the species colours, forms, heights and preview weights.

**If the Python and SeedData disagree, SeedData is right and the Python is the bug.** Fix the copy;
never edit SeedData to match a render.

> **They are drifted right now.** `plants_biome1.py` still carries the pre-remodel palette - Nubkin
> and Petalpip both on `GREEN`, Toadcap and Bellchime both on `CREAM`, Spiretip at 132,186,96 - and
> `SOIL = rgb(74, 54, 44)`, the near-black soil SeedData replaced with 124,76,50. Any lineup
> rendered today shows five species in two colours, which is the exact fault the remodel fixed. Sync
> the palette before trusting a render.

Preview weights in the script are the species' fallback `Kg` (2, 5, 14, 40, 110). That is fine for a
lineup - it is what the sheet was drawn at - but it is not the live weight, and a render says
nothing about how a 9,000 kg roll looks.

## Housekeeping

`tools/blender/plants_biome1.py` is **untracked** (`git ls-files` shows only `parent_biome1.py`).
Add it before relying on it.
