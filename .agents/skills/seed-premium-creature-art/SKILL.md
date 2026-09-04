---
name: seed-premium-creature-art
description: Design and critique premium Steal a Seed plants and pods, including proposed Divine and Secret creatures, from visual references. Use for distinctive anatomy, carved mouths, layered studded surfaces, rarity presentation, effects, and animation-ready approval mockups. Not for economy changes or an automatic redesign of approved species.
---

# Premium creature art for Steal a Seed

Build a creature worth collecting before adding the effects that announce it. This is the shared
instruction source for Claude and Codex; the Claude entry is a pointer, not a second art bible.

## Scope and current truth

- Read the project's `AGENTS.md` and the relevant current `KB/HANDOFF.md` entries. Preserve approved
  artwork and in-progress work outside the requested creature.
- Read [organic-roblox-form](../organic-roblox-form/SKILL.md) for the underlying freeform method.
  This skill adds premium reference interpretation and presentation, not a competing builder.
- Historical skills contain kilogram curves, old biome availability, and old face conventions.
  Do not restore those from prose: current source and later approved handoff decisions govern.
  Before implementation, inspect the actual species, size-tier, palette, and builder contracts.
- Divine and Secret are intended content directions, not permission to add rarity rows, change
  their ordering, alter roll odds/income, or add a size above Colossal. Confirm their data meaning
  when a task actually reaches registration. An art request does not authorize economy edits.
- The current project allows primitive-built sculpture. A reference is not authorization for
  MeshParts, unions, external model downloads, asset publication, or rig changes. If the desired
  finish cannot fit the allowed construction and budget, explain the tradeoff and ask first.

## Interpret the reference before designing

Read [reference-study.md](references/reference-study.md) and inspect its two images when working
from this reference family. For a new user reference, inspect that image as well; the newest
explicit direction wins. Do not claim an image was inspected if only its description is available.

Separate three things in a short design note:

1. **Observed:** visible proportions, pose, contour, color regions, mouth opening, surface rhythm.
2. **Inferred:** plausible anatomy or construction, marked as an inference.
3. **Proposed:** how to translate those qualities into an original plant and pod for this game.

Screenshots do not establish part counts, topology, hidden anatomy, joint names, effect ownership,
collision, performance, or animation quality. Do not import the reference's money labels, giant
scale, surrounding scenery, or excessive bloom as design requirements.

Define the concept in one sentence: botanical identity + body plan + signature feature + mood.
The creature must still read as a living plant: establish bark, roots, foliage, petals, a seed
organ, or another structural botanical feature rather than decorating a generic animal with a bud.

## Premium shape hierarchy

Resolve these layers in order, testing without effects:

- **Primary silhouette:** body, head, stance, tail or crown. Pick a clear length/height/width bias;
  do not make every species the same round body with different accessories.
- **Secondary anatomy:** brow, jaws, cheeks, shoulder/hip masses, overlapping plates and petal
  clusters. These explain how the animal stands, opens its mouth, and moves.
- **Tertiary detail:** studs, chips, veins, teeth, small markings and localized emissive accents.
  Keep quieter surfaces between clusters. Detail density is not a substitute for a silhouette.

The supplied references suggest different body plans, not a requirement to put horns on every
plant: a long-mawed creature, a floral quadruped, and a broad crouching horned beast. Explore that
range while respecting any explicit requirement for hands, feet, or a particular stance.

Rounded volume is welcome; a naked sphere as the finished skull or torso is not. Combine a few
broad intersecting forms into a shaped contour. Avoid ball chains, uniform extruded boxes, repeated
radial spokes, and hundreds of tiny wedges approximating a curve. Controlled facets and studded
plastic can remain visible without making the anatomy read as a pile of bricks.

## Carved faces and attached limbs

- Build the mouth as a volume bounded by brow/upper jaw, cheeks, and a distinct lower jaw.
  Set its interior behind the lip planes, with a visible recess in three-quarter and side views.
  A black or Neon rectangle attached to the front is not a carved mouth.
- Give teeth roots within gum/jaw material. Use a readable rhythm and limited unevenness; do not
  line every edge with identical spikes. Keep tongue/throat accents inside the cavity, not floating.
- Let brow slope and lid shape carry expression. Reserve high contrast for the eyes or mouth;
  there should not be five equally bright focal points competing with the face.
- Run shoulder to upper limb to joint to palm/sole continuously. Hide construction joins with
  overlap, but keep intentional mouth, elbow, and leg negative spaces open. Check the side view:
  a limb that appears connected from the front may still float behind the shoulder.
- Feet must have a support surface and purposeful toes/claws, not a square platform beneath the
  creature. Test neutral contact and the moving stance, not just one static endpoint.

For a long mouth, use perspective to inspect depth rather than accepting one front screenshot.
For a floral mane, vary a few large petal masses along its direction of growth; do not wallpaper
the body with same-size petals. Decorative plates follow anatomical flow and taper toward tips.

## Color and premium identity

Choose a dominant body family, a contrasting structural family, and one concentrated focal accent.
Use light/dark separation so mouth, face, and limbs remain readable in grayscale. Sample color
when exact reference matching is requested; do not claim guessed RGB values are sampled values.

The following are **starting proposals**, not locked palettes or universal definitions:

- **Divine:** deliberate, majestic forms; a crown or opening bloom; restrained luminous seams;
  ivory/gold is one option, not a mandatory recolor of every biome.
- **Secret:** an unexpected body plan or reveal; displaced symmetry, an unusual maw, hidden
  underside, or impossible-looking crown. It need not be black/purple or covered in extra spikes.

Give each an identifiable unlit silhouette. If disabling glow or removing the rarity label makes
two designs indistinguishable, change the anatomy before adding more particles.

## Effects that serve the creature

State the job and attachment point of every effect. Prefer one signature ambient behavior plus
an event accent: for example a contained core pulse and a brief petal release on waking. These are
examples, not a required effect count.

- Keep the face readable with effects enabled. Avoid opaque lightning curtains and white bloom
  that destroys the mouth/eye colors.
- Test under the actual biome lighting and in a crowded garden, not only a dark showcase.
- Do not use per-frame particle spawning, large particle fields, or a PointLight on every accent.
  Agree and measure live emitter/light budgets; reduce or cull cosmetic work at distance.
- Bind effects to existing lifecycle/state signals. Disconnect and remove them on destruction,
  stream-out, or preview rebuild; avoid duplicate update loops.
- Screenshot brightness is not proof of Neon material or a particular particle implementation.

## Pod and plant relationship

A pod should foreshadow the approved visual family through shell structure, seam direction, or
motifs. Preserve existing hidden-species rules: do not reveal an unknown hatch result through a
unique exact-species silhouette unless the user explicitly approves that change.

Reuse the current pod builder and approved comparison stage. Never create a second `PodStages`.
Inspect the current tier overlays before changing shell geometry; preserve their required names,
attachments and behavior. Greenhollow is locked unless explicitly placed in scope.

The pod CFrame is its ground base. No new part may extend below it; decorations must contribute
visible surface or outline rather than hide fully inside the shell. Use the current footprint
limit (approximately 1.3 times diameter unless superseded). Test carried and pedestal placement.
Resolve an oversized crown/maw/halo within that envelope rather than silently widening the pod.

## Motion and budget before polish

Before rig implementation read [character-rigging](../character-rigging/SKILL.md); before motion
implementation read [character-animation](../character-animation/SKILL.md). Inspect the actual
target builder and animation consumer instead of assuming all plants or parents share a rig.
For live species registration read [plant-authoring](../plant-authoring/SKILL.md), checking its
historical claims against current source before using them.

Plan the bending points, moving groups, neutral contact, and peak poses during blockout. Preserve
load-bearing names and rest poses. A cosmetic jaw or halo should not require replacing the root
physics or shared rig contract without approval. A rig with attractive stills is not animation
verified: inspect idle, locomotion, and any requested open/close or hatch motion through the blend.

Premium does not waive mobile budgets. Establish the current target's budget before adding detail.
Count BaseParts, moving transforms, joints, emitters, lights, and live copies, including a full
garden scenario. Do not turn a guardian's budget into a per-plant allowance. Ask before exceeding
the agreed budget; do not infer hidden costs from the screenshots.

Check Tiny, one intermediate tier, and Colossal through the actual production scaling path. Report
oversized bodies, mismatched limb scales, and footprint violations without silently rewriting the
shared size curve or shrinking only the preview. Reference size is not a world-space target.

## Approval and evidence

For concept-only requests, give a compact design brief, not Studio edits. When a mockup is
authorized, reuse the existing appropriate preview and builder; isolate any genuinely new preview,
mark it PreviewOnly/non-archivable, and make rebuilds deterministic and cleanup complete.
Do not open live nests or register species merely to preview art.

Present one requested creature/pod pair at a time unless the user asks for a collection. Include:

- Front, side, and three-quarter views, with a player/planting cell for scale.
- Effects-off and effects-on views, plus a mobile/gameplay-distance read.
- The relevant moving poses and at least one continuous transition if motion is in scope.
- Measured dimensions, contact/gap checks, part/effect cost, and explicitly untested behavior.

Inspect the real output. Zero spheres, a favorable aspect ratio, or successful compilation cannot
prove that a creature looks premium. If Studio/visual access is unavailable, say what could not be
verified. User appearance approval and technical verification are separate; live integration needs
the authority appropriate to the user's task. Record accepted decisions in the shared handoff.
