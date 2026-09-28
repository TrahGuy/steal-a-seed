# The design brief -- required before modeling

No blockout starts without a brief. It is short (one screen), it is what the owner approves or
corrects first, and every later review checks the model against it. Put it in the approval
message and the handoff entry; do not create a new document folder for it.

## Template

```text
Creature        working name (not a species id until the owner registers one)
Identity        one sentence: botanical identity + body plan + signature feature + mood
Theme           biome and what makes it botanical (bark, roots, foliage, petals, seed organ ...)
Body plan       rooted / tripod / quadruped / biped / serpentine / bulb / column / cap ...
Stance, motion  how it stands and moves; which rig family it will use:
                  plant: PlantSway legs (Thigh/Femur/Haunch + Shin/Foot words), root walker
                  (Root<n>/RootRise<n>), Leaf arms, or none; guardian: the seven Motor6Ds
Size, distance  size tier(s) and frame height in studs; typical camera distance; UI viewports
                  it must frame in (Index card, Garden panel, hotbar)
Signature       ONE dominant feature
Supporting      two to four shapes that explain how it stands, eats and moves
Palette         dominant body family / supporting family / structural accent / one focal accent;
                  the biome's shared constants where they apply (copied from source, never eyeballed)
Keep unchanged  approved traits, names, sizes, attributes and contracts that must survive
Route           A (default) or B (needs the owner's approval naming this asset)
Budget          derived from the species' measured band and the simultaneous count (see
                  game-contracts-and-budgets.md) -- a number with its source, not a feeling
Out of scope    what this pass will not touch
```

## What makes a brief good enough to model from

- The identity sentence names **one** signature. If it needs a list of decorations, it is not
  resolved yet.
- The body plan follows the plant, not a monster template. A bulb, a column cactus, a vine or a
  mushroom cap can be premium without shoulders, horns or claws.
- Size and distance are numbers. "Big" is not a size; "Titan tier, about 5x the Tiny frame, seen
  from 20-40 studs" is.
- The keep-unchanged list is written from the source and the handoff, not from memory.
- The budget has a source (a spec, a measured scene) and says whether it is per creature or per
  full garden.

## Worked example: the smoke-test creature

This is the throwaway creature `scripts/selftest_blockout.py` builds to exercise the pipeline.
It is not a species proposal.

```text
Creature        "Burrowbud" (throwaway self-test fixture)
Identity        a shy germinating seed that stands on three root legs under one curling leaf
Theme           neutral; bark seed coat, pale seed belly, root legs, a first leaf
Body plan       seed body with a head mass; tripod of roots
Stance, motion  squat and planted; would suit a root-walker rig (not built)
Size, distance  about 4.9 studs tall (a Tiny-to-Big plant); read at 20-40 studs
Signature       the single leaf rising off the crown and curling back over the body
Supporting      root tripod with foot pads; brow-cheek-jaw face around a carved mouth
Palette         bark brown / pale seed / leaf green / one blush bud (right shoulder)
Keep unchanged  nothing -- not a live creature
Route           A (translated in the smoke test) and B checks (export only; nothing imported)
Budget          none set; the translation came to 26 parts
Out of scope    colour polish, motion, any live integration
```

What the smoke test's renders then showed (the review loop working as intended): the silhouette
reads from the side and above, the carved mouth reads in the colour pass, but the head and body
read as two stacked balls -- exactly the sphere-stacking this skill warns against. A real design
would fix that at the blockout checkpoint, before any detail.
