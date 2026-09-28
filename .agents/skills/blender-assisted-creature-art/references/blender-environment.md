# The Blender environment on this PC, verified

Probed 2026-09-24 with read-only scripts run headless (probe output kept in
`D:\KAPE\output\blender-creature-skill\env-probe\`). Re-probe after any Blender upgrade.

## What is installed

- **Blender 5.2.0 LTS** (build fbe6228777e7, 2026-07-14) at
  `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`. It is **not on PATH**, so the
  `blender ...` commands in [blender-to-roblox](../../blender-to-roblox/SKILL.md) fail as written;
  use the full path. Do not change the system PATH on the owner's behalf.
- Enabled add-ons: `io_scene_fbx`, `io_scene_gltf2`, `cycles`, `io_anim_bvh`, `io_curve_svg`,
  `io_mesh_uv_layout`, `pose_library`, `bl_pkg`. Present but disabled: Rigify, Node Wrangler.
- **Not available:** the 3D-Print Toolbox (`mesh.print3d_*` is not registered -- `mesh_audit.py`
  does its checks with bmesh instead), any Blender MCP add-on, any marketplace add-on. Nothing was
  installed and nothing should be.
- Also on this PC: ffmpeg 9.0 (WinGet) for reference-video frames, Python 3.13 for
  `validate_skill.py`. No Node.js (AGENTS.md).

## Running it

```powershell
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
& $blender --background --factory-startup --python script.py -- --out D:\some\folder   # scripted build
& $blender --background study.blend --python review_renders.py -- --out D:\some\folder   # read-only review
```

Arguments after the bare `--` belong to the script. `--factory-startup` makes scripted builds
independent of user preferences and add-ons. The GPU module is uninitialised in background mode,
yet rendering works.

## Verified capabilities

| area | verified on 5.2.0 |
| --- | --- |
| render engines (headless) | `BLENDER_WORKBENCH`, `BLENDER_EEVEE`, `CYCLES`; a 64 px test took 1.6 s, 8.9 s (EEVEE compiles shaders on its first render), 0.3 s |
| view transforms | Standard, ACES 1.3, ACES 2.0, Khronos PBR Neutral, AgX, Filmic, Filmic Log, False Color, Raw |
| export / import | FBX, glTF, OBJ, STL, PLY (`wm.obj_export` etc.); `io_scene_fbx.parse_fbx` importable for reading FBX back |
| FBX exporter options | `axis_forward`, `axis_up`, `global_scale`, `apply_unit_scale`, `apply_scale_options`, `bake_space_transform`, `use_selection`, `collection`, `add_leaf_bones`, `bake_anim`, `mesh_smooth_type` ... (defaults: forward -Z, up Y, scale 1.0, leaf bones on) |
| modelling | voxel and QuadriFlow remesh; Subdivision, Boolean, Solidify, Skin, Remesh, Decimate, Shrinkwrap, Mirror, Weighted Normal, Lattice, Simple Deform, Geometry Nodes |
| scripting | bmesh ops (triangulate, recalc normals, dissolve degenerate, remove doubles, holes fill), `BVHTree.overlap`, `Mesh.corner_normals`, `Mesh.set_sharp_from_angle`, `Mesh.validate` |

API changes that break older scripts are listed in [Blender techniques](blender-techniques.md#blender-5x-api-facts-that-bite-scripts-verified-on-520).

## Conventions this skill uses

- 1 Blender unit = 1 stud (the scripts take `--studs-per-unit` when a file differs).
- The creature faces **-Y**, its right is **-X**, it stands on **z = 0**, origin at the ground base.
- Roblox (x, y, z) <-> Blender (-x, z, y): a proper rotation, its own inverse.

## Export facts, verified on the Blender side (2026-09-24)

`export_roundtrip.py` exported the calibration set and the smoke-test creature, parsed the files
back, and re-imported them:

- **FBX** (`axis_forward="Z"`, `axis_up="Y"`, `apply_unit_scale=True`, `global_scale` = studs per
  unit / 100, `bake_space_transform=True`): stored geometry equals studs (height ratio 1.0); the
  header declares UnitScaleFactor 1.0 (centimetres), UpAxis Y, FrontAxis Z with sign -1, CoordAxis
  X with sign -1; the FRONT marker lands at file -Z and the RIGHT marker at file +X. Blender's own
  importer brings it back at 1/100 in metres (it honours the centimetre header) in the same
  orientation.
- **FBX with the exporter's default** `axis_forward="-Z"`: the creature arrives facing file +Z --
  turned 180 degrees for a -Z-forward reader (tested on the calibration set).
- **OBJ** (forward Z, up Y, scale = studs per unit): the same stored values and orientation;
  re-imports 1:1.
- **glTF**: stored height equals studs, but the front lands at +Z (the glTF convention) -- turned
  180 degrees relative to Roblox's -Z forward.

## The Roblox side is NOT verified here

From `KB/HANDOFF.md` (2026-09-11): a Blender FBX whose header said centimetres came through the 3D
Importer with its centimetre values as studs, decimated to the 20,000-triangle ceiling, unanchored,
facing -Z. Whether the importer reads the FBX axis metadata or the raw values, and what it does
with glTF, is unknown. Settle it once with the calibration file in a scratch place before the first
approved Route B import ([Route B](route-b-custom-mesh.md)).

## The existing preview scripts on 5.2 (read, not run)

`tools/blender/plants_biome1.py` and `parent_biome1.py` were written for Blender 4.x.
`material.use_nodes = False` is now a no-op but harmless (Workbench still uses `diffuse_color`);
`plants_biome1.py` still carries the old kg curves; the axis notes are covered in
[reference analysis](reference-analysis.md#claims-in-sibling-skills-that-are-not-established).
They were not run in this session and were not changed.
