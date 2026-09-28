---
name: blender-assisted-creature-art
description: Design, refine and review stylized Steal a Seed creatures (botanical guardians, premium plants and pods) with Blender as the study, blockout and approval-render tool, through two explicit production routes. Route A, the default, translates an approved Blender study into the project's Luau-built part vocabulary and reports the fidelity tradeoff; Route B is a documented custom-mesh pipeline (editable source, cleanup, UVs, rig prep, export, Studio validation) that may only be used after the owner approves a specific asset. Covers reference analysis, design briefs, primary/secondary/tertiary shape construction, plain-then-colour visual checkpoints, game contracts and measured budgets. Use for Blender-assisted creature design and refinement; not for gameplay bugs, UI, economy, or redesigning approved creatures unasked.
---

# Blender-assisted creature art

Use Blender to find a better creature faster -- proportions, poses, faces and surfaces tried and
judged from fixed cameras -- then deliver it through a route the project actually supports.
This is the shared instruction source for every agent; the Claude entry is a pointer.

## Authorization boundaries -- read before anything else

- **Production geometry is Luau part builds today.** AGENTS.md rule 11 ("does not authorize
  MeshParts, unions or imported geometry"), [blender-to-roblox](../blender-to-roblox/SKILL.md)
  ("Blender is a preview, not a pipeline") and `DustbowlPodSpec` (fails on a MeshPart in a pod)
  all say so. This skill does not change that policy.
- **Blender work is study, review and translation by default (Route A).** An offline mesh or
  sculpt study is never authorization to import, upload, or replace a live creature.
- **Route B (custom mesh) needs the owner's explicit approval naming the asset and the route**
  before any production import, asset upload, spec change or pipeline change. Record the approval
  in `KB/HANDOFF.md` first.
- **Never** upload assets, publish, touch player saves, or redesign an approved creature without
  being asked. Commit and push only as the owner directs for that task.
- **Never substitute AI mesh generation** (`generate_mesh`, marketplace generators) for Blender
  modeling unless the owner asks for it.
- **Install nothing.** No Blender, add-ons, MCP servers or paid services; report what is missing
  and finish the unaffected work ([environment](references/blender-environment.md)).
- **Footage and screenshots do not reveal how a model was built.** Keep observation, inference
  and proposal separate ([reference analysis](references/reference-analysis.md)).

## When to use it -- and when not

Use it for a new creature concept that benefits from a 3D blockout, refining the proportions or
face of an approved creature on request, approval renders, a Route A translation, or Route B work
the owner has approved. Do not use it for gameplay bugs, UI, economy or balance. For registering a
species use [plant-authoring](../plant-authoring/SKILL.md); for rig code
[character-rigging](../character-rigging/SKILL.md); for motion code
[character-animation](../character-animation/SKILL.md).

## Read alongside

- `AGENTS.md`, and the `KB/HANDOFF.md` entries for the target creature and its biome.
- [organic-roblox-form](../organic-roblox-form/SKILL.md) -- the freeform primitive method Route A
  must satisfy. [seed-premium-creature-art](../seed-premium-creature-art/SKILL.md) -- reference
  interpretation, premium presentation, pods. [plant-art-bible](../plant-art-bible/SKILL.md) --
  palette and face rules; its kg curves and 25-40 part band are Greenhollow-era, so check current
  source and specs before citing them.
- Some statements in sibling skills are unverified or wrong; they are listed, with evidence, in
  [reference analysis -- claims in sibling skills](references/reference-analysis.md#claims-in-sibling-skills-that-are-not-established).

## The workflow and its checkpoints

1. **Ground truth.** Read the target's builder, forms table or generator, its specs and handoff
   entries. List the approved traits, names and sizes that must not change
   ([contracts and budgets](references/game-contracts-and-budgets.md)).
2. **Reference analysis:** observed / inferred / proposed ([reference analysis](references/reference-analysis.md)).
3. **Design brief -- required before modeling** ([design brief](references/design-brief.md)).
4. **Choose the route.** A by default ([Route A](references/route-a-primitive-production.md));
   B only with approval ([Route B](references/route-b-custom-mesh.md)).
5. **Blockout the primary forms** in Blender ([shape construction](references/shape-construction.md),
   [Blender techniques](references/blender-techniques.md)).
6. **Plain and silhouette renders** with `review_renders.py`; open every image yourself
   ([visual review](references/visual-review.md)).
7. **STOP for owner approval of the blockout** for a new creature or a substantial redesign.
   After approval, iterate inside that scope without asking about each small change.
8. **Secondary, then tertiary forms**, in focused revisions with before/after renders from the
   same cameras.
9. **Colour pass** with `review_renders.py --passes color`. Glow, particles and lights are judged
   in Studio, not in Blender.
10. **Deliver by route.** A: `partspec_bridge.py` + `silhouette_compare.py`, then -- after
    approval -- the species' `tools/art` generator. B (approved only): `mesh_audit.py`,
    `export_roundtrip.py`, the calibration import, Studio validation.
11. **Contracts and budget** checked against the real builder, specs and a measured scene.
12. **Evidence and handoff** (below), recorded in `KB/HANDOFF.md`.

## Scripts (verified on Blender 5.2.0 LTS)

Full commands and outputs: [scripts/README.md](scripts/README.md). All run headless, write only
under `--out`, refuse a Rojo `src/` folder, and never save over an existing `.blend`.

| script | job |
| --- | --- |
| [review_renders.py](scripts/review_renders.py) | plain / silhouette / colour approval sheets: front, right, rear, 3/4, top, scale figure, true-size gameplay tile |
| [silhouette_compare.py](scripts/silhouette_compare.py) | Route A fidelity: IoU, lost and added area per view, red/blue overlay |
| [partspec_bridge.py](scripts/partspec_bridge.py) | Route A: Roblox part list JSON to Blender primitives and back, plus a Luau PartSpec review snippet |
| [mesh_audit.py](scripts/mesh_audit.py) | normals, open/non-manifold edges, degenerates, doubles, intersections, scale, UVs, budgets |
| [export_roundtrip.py](scripts/export_roundtrip.py) | FBX/OBJ/glTF export with parsed-back axes, units and markers; a calibration set |
| [selftest_blockout.py](scripts/selftest_blockout.py) | the throwaway smoke-test creature (not a design) |
| [validate_skill.py](scripts/validate_skill.py) | this skill's frontmatter, links, Claude pointer and scripts (plain Python) |
| [bca_lib.py](scripts/bca_lib.py) | shared helpers: axis change, safety rules, cameras, contact sheets |

## Evidence rules

- A script that ran is not a creature that looks right. Open the sheets and say what you saw.
- Report separately: instructions written, scripts executed, images inspected, export/import
  checks performed, and what remains unverified (Studio import, phone, TV, live servers).
- Measure instead of guessing: dimensions, part or triangle counts, IoU, marker directions.
- A desktop Blender render or frame time says nothing about mobile performance.

## References

- [reference-analysis.md](references/reference-analysis.md) -- reading footage honestly, the 2026-09-24 video study, flagged sibling-skill claims
- [design-brief.md](references/design-brief.md) -- the required brief, with a worked example
- [shape-construction.md](references/shape-construction.md) -- primary, secondary, tertiary; faces, limbs, taper, botanical layers
- [blender-techniques.md](references/blender-techniques.md) -- which Blender tool for which shape problem
- [visual-review.md](references/visual-review.md) -- the camera set, the passes, the checkpoints
- [route-a-primitive-production.md](references/route-a-primitive-production.md) -- measured part geometry, mockup space, translation, fidelity
- [route-b-custom-mesh.md](references/route-b-custom-mesh.md) -- the approval-gated mesh pipeline and Studio validation
- [game-contracts-and-budgets.md](references/game-contracts-and-budgets.md) -- what builders and consumers require; measured budgets
- [blender-environment.md](references/blender-environment.md) -- the installed Blender, verified APIs, conventions, export facts
