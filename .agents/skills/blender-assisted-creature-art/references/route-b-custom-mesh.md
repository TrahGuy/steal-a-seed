# Route B -- custom-mesh production (approval-gated)

A genuine Blender modelling pipeline for a creature the owner has **explicitly approved** as a
mesh, naming the asset and this route. Until then it is documentation, not permission: offline
mesh studies do not authorize replacing a live creature, uploading an asset, changing a spec that
forbids meshes, or changing the pipeline. Record the approval in `KB/HANDOFF.md` before step 1.

## What the project already learned (KB/HANDOFF.md)

- **2026-09-11, the Suncrown mesh test.** A Blender 4.3.2 FBX of 121,500 triangles, Y up, in
  centimetres. Through the 3D Importer it became one MeshPart of **19,999 triangles** (the importer
  decimated it without asking), **167.58 x 189.86 x 104.32 studs** (the centimetres came in as
  studs), **unanchored** with CollisionFidelity Box, no texture, facing -Z. It was uploaded under
  the importing account, so a group-owned experience would need it shared or re-uploaded.
  PlantSway gave the single MeshPart the lean, bob and walk, but no arms, blink or steps.
- **2026-09-15 / 2026-09-17, the Dustbowl mesh pods.** Owner-requested AI meshes shipped, then were
  removed at the owner's request and the part-built pods restored. `DustbowlPodSpec` now fails if a
  pod contains a MeshPart, SpecialMesh or FileMesh.
- **2026-09-15, the boot race.** The mesh loader waited about 1.5 s in a service's Init for
  `CreateMeshPartAsync`; a player joined inside that wait and the owner's garden was overwritten.
  Never yield in a service's Init or Start to load an asset.
- `ParentModel.luau` anticipates a guardian mesh: "IF THE BLENDER MESH REPLACES THIS, keep those six
  bone names and everything that drives them keeps working."

## Files: one editable source, generated export copies

- **Source**: an editable `.blend` with live modifiers, named collections and the brief in its
  notes. Proposed home `art/creatures/<id>/blender/<id>.blend` -- binaries in git are the owner's
  call; ask before committing one.
- **Export copies**: generated from the source by `export_roundtrip.py` into
  `art/creatures/<id>/export/`, never edited by hand, regenerated after every source change.
- Previews stay out of git (`tools/blender/out/` is ignored); approval renders go to an output
  folder outside the repository.

## Modelling rules

- 1 Blender unit = 1 stud; the creature faces -Y, right is -X, stands on z = 0; the origin at the
  ground base centre (the BASE contract).
- Object names follow the contracts the creature will keep: `Base` stays the plant's pivot part;
  guardian segments align with `RootJoint`, `Neck`, `JawJoint`, `LeftShoulder`, `RightShoulder`,
  `LeftHip`, `RightHip` ([contracts](game-contracts-and-budgets.md)).
- Apply scale and rotation in the export copy; never ship negative scale.

## The pipeline

1. **Blockout, approved** -- the same checkpoint as Route A ([visual review](visual-review.md)).
2. **Sculpt** the forms ([techniques](blender-techniques.md)).
3. **Retopology** where the sculpt is too dense: quad-dominant, evenly spaced loops through
   deforming regions (jaw, shoulders, hips, root joints); Decimate or Planar dissolve for rigid
   parts. Each mesh must come in under the importer's 20,000-triangle ceiling or it is decimated
   blind -- and the budget for a garden of copies is usually far lower
   ([budgets](game-contracts-and-budgets.md)).
4. **Clean up** until `mesh_audit.py --strict` passes: no degenerates or zero-length edges, no
   inconsistent winding, no inward normals, welded caps, watertight where the asset needs it
   (`--closed`), intentional intersections only.
5. **UVs**: seams in hidden places, even texel density, one atlas per creature where possible.
6. **Materials**: plan for what the route supports -- a MeshPart colour map (`TextureID`) or a
   `SurfaceAppearance` (colour, normal, roughness, metalness). Confirm in Studio that the chosen
   material path survives the import before texturing; this skill has not verified it.
7. **Rig preparation**, one of:
   - **rigid segmentation**: separate meshes per moving group, driven by the existing Motor6D names;
     the least disruptive for guardians;
   - **skinned mesh** with bones matching the existing joint names; needs its own Studio import test
     and an owner decision, because every consumer of the rig must keep working.
8. **Collision**: simple separate parts or a Box/Hull fidelity, never the decorative mesh.
   Plants are anchored with CanCollide, CanQuery and CanTouch off (`PlantFormsSpec`).
9. **Export** with `export_roundtrip.py` and keep its report. Blender-side facts verified:
   FBX with forward Z / up Y and a global scale of studs-per-unit/100 stores studs as the file's
   values, front at file -Z, right at file +X ([environment](blender-environment.md)).
10. **Calibrate once**: import `calibration.fbx` (`export_roundtrip.py --calibration`) into a SCRATCH
    place and confirm the 1-stud cube, the 5-stud pole, FRONT toward -Z and RIGHT toward +X.
    Whether the importer honours the file's axis metadata or reads raw values is not established;
    this import settles it. Record the result in the handoff.
11. **Studio validation** (below), then the owner's approval of the live result.

## Studio validation checklist

- Triangles per mesh (the importer's report, or an EditableMesh count), bounds in studs, facing -Z.
- `Anchored`, `CanCollide` / `CanQuery` / `CanTouch`, CollisionFidelity, RenderFidelity.
- The contract: `PrimaryPart`, `Base`, names, attributes, tags; the builder's BASE placement.
- Streaming: plants are `PersistentPerPlayer` for their owner; check a walked plant stays whole.
- Load path: templates available before the first plant builds, with **no yield in Init or
  Start**.
- The consumers: PlantSway, carry, placement, the Index and Garden viewports, the hatch reveal.
- Performance in a representative scene on desktop Studio AND a phone or the device emulator; a
  desktop number is not a phone number.

## Asset ownership and permissions

Before production use, confirm who uploaded each asset, that it belongs to (or is shared with)
the experience's owner, that textures and references are the owner's to use, and that the asset
is the one the owner designated -- never a stand-in from the inventory.

## Not verified by this skill

No Studio import was performed. Material, SurfaceAppearance and skinned-mesh behaviour, the
importer's settings UI, and the Roblox side of scale and axes remain to be confirmed with the
calibration import on the first approved asset.
