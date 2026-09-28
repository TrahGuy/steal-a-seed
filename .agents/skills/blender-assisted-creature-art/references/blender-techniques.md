# Blender techniques: the tool follows the shape problem

Pick the technique that solves the problem in front of you. Do not run every modifier over every
creature, and do not sculpt detail before the blockout is approved. Commands below are for the
installed Blender 5.2 LTS ([environment](blender-environment.md)).

## Which tool for which problem

| shape problem | reach for | why | watch out for |
| --- | --- | --- | --- |
| broad soft masses (body, head, belly, seed coat) | primitives edited in Edit Mode + Subdivision Surface; metaballs for fused blobby limbs (as `tools/blender/parent_biome1.py` does) | fast, keeps masses separate and adjustable | stacked spheres read as a snowman; overlap and reshape them |
| curved AND tapered forms (horns, claws, tusks, roots, tails, vines) | a Bezier curve with Bevel depth and a per-point radius, then Object > Convert to Mesh; Skin modifier for branching roots | the curve owns the direction of growth, the radius owns the taper | converted curves leave caps unwelded -- merge by distance before any export (the smoke test's audit caught 20 doubles per root) |
| hard planar forms (armour, bark plates, facets, shell segments) | polygon modelling: extrude, inset, bevel, loop cuts; Mirror modifier; flat shading | clean planes that read at distance | keep plates thick; single faces flicker |
| cavities (mouths, eye sockets, hollows) | Boolean Difference, Exact solver, with a cutter object; material_mode Transfer to colour the walls | a real recess with measurable depth | Booleans leave slivers: the smoke test's mouth cut produced a zero-length edge and duplicate vertices; audit and clean |
| thin surfaces (leaves, petals, wings, fins) | a plane, subdivided, shaped by Simple Deform (bend/twist) or a Lattice, then Solidify | controllable curl with real thickness | Solidify self-intersects where the shape pinches to a point; check the audit |
| organic sculpt (muscle flow, bark knots, face planes) | Sculpt Mode: Draw, Clay Strips, Grab, Crease, Smooth; Voxel Remesh to refresh topology | the right tool for flowing surfaces | sculpt density is unusable in production; Route B needs retopology |
| repetition (spines, studs, scales) | Array + Curve modifiers, or instances | one change updates all | only at focal points; repetition becomes noise |
| pose and proportion tests | Lattice or Simple Deform on the whole blockout; a quick Armature | test stance and weight before detail | a pose test is not a rig; Rigify ships with Blender but is disabled here |
| retopology and reduction (Route B) | Shrinkwrap + manual quads, QuadriFlow remesh, Decimate (Collapse or Planar) | a mesh the importer and the rig can live with | the 3D Importer silently decimates anything over 20,000 triangles per mesh |

## Working rules

- **Scale:** 1 Blender unit = 1 stud. Model at the Tiny frame height of the target species, or at
  the height its generator authors in, and state which.
- **Orientation:** the creature faces -Y (Blender's Front view looks at its face), its right is
  -X, it stands on z = 0, and the origin is the ground base centre -- the same BASE contract the
  Luau builders take.
- **Names:** name objects after anatomy (`Jaw`, `RootRise1`, `Leaf`), because Route A carries
  names into Studio and several names are load-bearing there
  ([contracts](game-contracts-and-budgets.md)).
- **Collections:** keep the study, any Route A translation and helper cutters in separate
  collections, so review, comparison and export can each select exactly one.
- **Apply before export, not during design.** Keep modifiers live in the editable source; apply
  them only in an export copy (the export script evaluates them without touching the source).
- **Mirror first, break symmetry last.** Build with the Mirror modifier, apply it, then add the
  deliberate asymmetry.

## Running Blender on this PC

- Headless always: `& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background ...`.
  Use `--factory-startup` for scripted builds so user preferences and add-ons cannot change the
  result.
- Keep renders small (the review script uses 384 px tiles and a 704 x 338 gameplay tile).
  Workbench is fast; EEVEE's first render of a session compiles shaders (about 9 s measured).
  Avoid Cycles beauty renders.
- Run one Blender process at a time; the owner uses this PC during sessions.
- Never open an existing production `.blend` for writing. The scripts here load a file read-only
  and never save it; the self-test builds its own file from scratch.

## Blender 5.x API facts that bite scripts (verified on 5.2.0)

- `Mesh.use_auto_smooth` and `calc_normals_split` are gone (since 4.1): use the
  `object.shade_auto_smooth` / `object.shade_smooth_by_angle` operators or
  `Mesh.set_sharp_from_angle`; custom normals are `Mesh.corner_normals`.
- `Material.use_nodes = False` is silently ignored -- materials always use nodes. Workbench
  MATERIAL colour still comes from `Material.diffuse_color`.
- The compositor tree moved: `scene.node_tree` no longer exists; use `scene.compositing_node_group`.
- EEVEE has no `use_bloom`; glow in Blender is a compositor effect and says nothing about Roblox.
- Dynamic enums (render engines, view transforms) must be read from a live instance; the class-level
  `enum_items` listed only one engine in the probe.
