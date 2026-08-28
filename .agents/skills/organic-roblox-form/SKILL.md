---
name: organic-roblox-form
description: Design or revise primitive-built Roblox plants, pods, and biome guardians so they read as appealing organic characters instead of noisy geometric assemblies. Use for concepts, mockups, Studio previews, silhouette or colour critique, movement planning, and approval passes before live implementation.
---

# Organic Roblox form

Create a character with a clear living form, not a collection of available primitives. The player
should recognize its species, mood, and main action from the silhouette before noticing individual
parts.

This skill supplies design judgment. Read `plant-art-bible` for the project's exact biome palette,
surface rules, size curves, faces, and part budgets. Read `plant-authoring` only when an approved
design is moving into live game data or code.

## Start with one sentence and three masses

Write the visual idea as one sentence: creature type, posture, signature feature, and mood. If the
sentence needs a list of decorations, the idea is not resolved.

Block the design with this hierarchy before adding detail:

1. **Dominant mass** — the part seen first, such as a cup, shell, crown, or hunched torso.
2. **Supporting mass** — the body, stem, limbs, or base that explains how it stands and moves.
3. **Signature shape** — one memorable feature that distinguishes it from the rest of the biome.

The dominant mass must remain dominant from the front, three-quarter view, side, and above. Do not
let several equal-sized plates, petals, spikes, or panels compete for attention.

## Use primitives as sculpture, not decoration

Use the project's allowed primitive vocabulary. Do not add MeshParts, unions, or imported geometry
to rescue a weak form.

### Freeform is the finish

Primitive-only describes the construction method, not the intended appearance. Never leave one
untouched Ball, Block, Wedge, or Cylinder reading as a finished head, torso, muzzle, hand, or foot.
Build each major anatomical mass from a small cluster of intersecting, rotated, scaled, or tapered
forms, hide their attachment lines, and judge the combined outer contour. The result must look
sculpted and organic at gameplay distance even though it is made entirely from primitives.

- Use spheres sparingly for eyes, glints, dew, buds, knuckles, or other small secondary details.
  Do not stack large balls into the main body plan.
- Give limbs a continuous anatomical transition: shoulder into arm into hand, and hip or ankle into
  foot. Hide the primitive attachment points inside the adjoining masses.
- Shape hands and feet with a palm or sole plus a few tapered digits. Do not finish them as a ball
  or plain rectangular pad.
- Make a carved mouth as genuine negative space. Split the head shell into brow, cheek, and jaw
  masses around a recessed cavity, so the opening changes the silhouette and has visible depth.
  A black or emissive plate placed on the surface is paint, not a carving.
- Inspect front, three-quarter, and side views. If a major body region is most naturally described
  as “the sphere,” “the box,” or “the cylinder,” rework it before adding decoration.

Freeforming does not authorize MeshParts, unions, terrain, imported models, or extra technology.
The approved project vocabulary stays unchanged; the craft is in how those pieces combine.

Every visible part must do at least one job:

- change the outer silhouette;
- explain anatomy or construction;
- form an intentional colour region;
- support an animation seam; or
- create one close-range focal detail.

If removing a part does not weaken one of those jobs, remove it. Prefer a few broad overlapping
forms over many small wedges. Tiny repeated pieces usually create visual static on mobile and make
the creature look mechanical.

Avoid these common failures:

- rings of identical parts placed at even angles unless the approved concept is explicitly radial;
- a fence of plates with equal height, spacing, and colour;
- spikes on every available edge;
- several layers that trace the same outline without changing its read;
- exposed gaps between pieces that should feel attached;
- straight symmetry in every feature; and
- detail added to compensate for an unclear silhouette.

Use controlled asymmetry: one chipped toe, one longer petal, an offset plate, a delayed leaf, or an
uneven tooth. Keep the dominant mass balanced enough that the creature still feels stable.

## Build colour in zones

Choose a dominant body family, a supporting family, one structural accent, and at most one focal or
warning colour. Treat proportions such as 50/30/15/5 as a guide, not a formula.

- Put colour on coherent masses, not alternating individual parts.
- Reserve the most saturated colour for the face, core, flower center, particle, or a reveal during
  movement.
- Let the biome palette create family resemblance while the head or signature mass gives the
  species its identity.
- Check the design in grayscale. If colour is the only thing separating the forms, revise the
  geometry.
- Do not cover the entire creature with one middle-value colour. Create a readable light/dark
  hierarchy without turning it into colour confetti.

Concealed colour is valuable. A bright underside revealed by opening petals or lifting armor adds
life without making the resting silhouette noisy.

## Design movement before final detail

Decide which masses move independently before spending the part budget. Put pivots where the form
actually bends or attaches; a floating pivot creates sliding parts no amount of easing can hide.

For a plant, normally use three to five meaningful cosmetic groups: for example head tilt, petal
pair, root spread, leaf lag, and a small particle pulse. A parent guardian may keep its required rig
seams and add three to five cosmetic groups. More groups are justified only when each produces a
visible, different action.

Motion should express weight:

- large masses move slowly and with small amplitude;
- tips, leaves, petals, and bristles lag or overshoot;
- paired pieces use slight phase differences instead of perfect synchronization;
- roots and feet react to contact rather than waving continuously;
- particles punctuate an event instead of running as constant fog; and
- reduced-motion mode retains the important pose change while dropping secondary flutter.

Measure combined motion after parent carry. Several small rotations can add into an excessive sweep.
Test the actual peak in Studio rather than trusting the amplitude written for one joint.

## Studio approval preview

During design approval, build only a temporary comparison preview:

- Put it in one clearly named Workspace folder and destroy/rebuild that folder on rerun.
- Set the folder and every descendant to `Archivable = false`.
- Use deterministic geometry; never randomize decoration positions.
- Guard Edit-mode animation loops with a generation value so rerunning cannot stack Heartbeat work.
- Show the minimum useful views or states: usually front/three-quarter, motion, and minimum/maximum
  scale or sleep/wake state.
- Point the viewport at the result. Do not create external artifact sheets or disposable links unless
  the user asks for them.
- Do not edit live data, production builders, or repository art during the preview phase.

Present one creature at a time and stop. Continue only after the user replies with an explicit
approval or revision. Approval of a concept authorizes the Studio mockup; approval of the Studio
mockup is a separate decision from live implementation.

## The anti-overgeometry review

Before presenting the model, inspect it at gameplay distance and answer these questions with direct
Studio evidence:

1. Can the species be named from a solid-black silhouette in front, side, and three-quarter view?
2. Is there one dominant mass, one supporting mass, and one signature shape?
3. Would deleting the weakest 15–20 percent of decorative parts change the identity? If not, delete
   them now.
4. Do repeated parts form a clear cluster or rhythm, rather than wallpaper?
5. Are the face and action readable at mobile scale?
6. Are colour accents concentrated where the eye should look?
7. Do all animated groups visibly bend from an attachment point without separating or clipping?
8. Does the smallest version retain the form, and does the largest become fuller rather than merely
   uniformly scaled?

If the answer to any of the first six is no, revise before presenting. A high part count is not
automatically detailed, and a low part count is not automatically elegant; clarity per part is the
measure.

## Brambleback as a project example

Brambleback succeeded because the broad head, hunched torso, long arms, five large back plates, and
three crown bristles create separate readable layers. Brown establishes the body, sage defines the
armor, pale husk frames the face, cyan is confined to the eyes, and coral appears mainly beneath
moving plates. The 83 parts support anatomy, five armor forms, claws, face construction, and eleven
motion groups; they are not 83 independent decorations.

Treat those counts and colours as an example of the method, not universal requirements. A smaller
plant should solve the same design problem with far fewer parts.
