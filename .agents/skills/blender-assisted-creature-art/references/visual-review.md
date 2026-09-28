# Visual review: render it, then look at it

A script that exits cleanly proves nothing about how a creature looks. Render with
`scripts/review_renders.py`, open every sheet, and write down what you see. In the smoke test the
first plain sheet looked plausible from the script's output but was covered in brown and green
patches: a second collection standing in the same place was z-fighting through the study. Only
opening the image caught it (the script now hides everything but the subject).

## The standard set

`review_renders.py` renders the same cameras every time, so revisions compare 1:1:

| view | camera | answers |
| --- | --- | --- |
| front, right side, rear | orthographic, one shared scale | proportions, symmetry, limb connection, ground contact |
| top (front at the bottom) | orthographic | the read from above, where the player's camera sits |
| 3/4 front-right | perspective, 30 degrees | the mouth recess, depth, overlap of layers |
| scale | orthographic, with a 5-stud blocky figure | size against a player-sized stand-in |
| gameplay | perspective at a player's distance and field of view, at true pixel size | readability on a phone |

The gameplay defaults are 30 studs away, 20 degrees down, 35 degrees round toward the right, a
70-degree vertical field of view (Roblox's `Camera.FieldOfView` default) and 704 x 338 pixels (the
viewport measured on the owner's emulated phone). The tile is never rescaled. Calibrate the
distance against a Studio screenshot of the real bed or nest the creature lives in, and pass the
creature's actual tier height; a Tiny plant at 30 studs is correctly only a few dozen pixels tall.

## Pass 1 -- plain form (Workbench grey, cavity, outline; no colour, no glow)

- Is the silhouette recognisable at small size?
- Does the body read as one coherent creature, not a stack of parts?
- Are the important facial features visible -- brow, eyes, a mouth with real depth?
- Are joints and ground contact believable? Is the lowest point on the ground?
- Does it still work from behind, from above and from the player's camera angle?

## Pass 2 -- silhouette (solid black on white)

Name the creature from each tile alone. If front, side, 3/4 and top do not each say what it is,
revise the primary forms before anything else.

## Pass 3 -- colour (EEVEE, Standard view transform, emission without bloom)

- One dominant body family, a supporting family, one structural accent, one focal accent.
- Light/dark separation keeps the face and limbs readable; check it against the silhouette pass.
- Biome constants copied from source, not eyeballed.
- Emission shows WHERE glow will be, never how Roblox will render it.

## Effects belong to Studio

Neon with bloom, particles, lights and billboards are judged in Studio, in the biome's own
lighting and a crowded garden, after the geometry is approved. Blender cannot reproduce Roblox's
bloom or particles, so a glowing Blender render is not evidence of anything.

## Checkpoints

- **Blockout approval.** For a new creature or a substantial redesign, stop after the plain and
  silhouette sheets of the blockout and wait for the owner. Do not spend detail on an unapproved
  direction.
- **Inside an approved direction,** iterate without asking about each small adjustment.
- **Focused revisions.** Change one thing, re-render with the same flags into a new folder
  (`rev01/`, `rev02/`), and show before and after side by side. Never regenerate the whole creature
  to fix one feature, and never add detail to make it look more advanced.

## What to hand over

The sheets (plain, silhouette, colour), `review_manifest.json` (dimensions in studs, lowest point,
camera set-up), the brief, and a plain list of what you did not verify: Studio lighting and bloom,
motion, a real phone, the live builder's scaling at Tiny and Colossal.
