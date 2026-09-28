# Scripts

All Blender scripts run headless on the installed Blender 5.2.0 LTS, take their arguments after a
bare `--`, write only under `--out`, refuse a Rojo `src/` folder, never save over an existing
`.blend` (review, audit, comparison and export never save at all), name their helper objects
`BCA_*`, and set `sys.dont_write_bytecode` so no `__pycache__` lands in the repository.
Conventions: 1 Blender unit = 1 stud, the creature faces -Y, its right is -X, ground z = 0.

```powershell
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$skill   = "D:\KAPE\Steal an Artifact\.agents\skills\blender-assisted-creature-art\scripts"
$out     = "D:\KAPE\output\blender-creature-skill\smoke-test"
```

| script | command | writes |
| --- | --- | --- |
| [selftest_blockout.py](selftest_blockout.py) | `& $blender -b --factory-startup --python "$skill\selftest_blockout.py" -- --out $out --overwrite` | `smoke_source.blend` (collections Study, Primitive, Cutters), `partlist_translation.json` |
| [review_renders.py](review_renders.py) | `& $blender -b "$out\smoke_source.blend" --python "$skill\review_renders.py" -- --out "$out\review-study" --collection Study --title "..."` | `sheet_plain.png`, `sheet_silhouette.png`, `sheet_color.png`, per-view PNGs, `review_manifest.json` |
| [silhouette_compare.py](silhouette_compare.py) | `& $blender -b "$out\smoke_source.blend" --python "$skill\silhouette_compare.py" -- --a Study --b Primitive --out "$out\fidelity"` | `sheet_fidelity.png`, `overlay_<view>.png`, `fidelity.json` |
| [mesh_audit.py](mesh_audit.py) | `& $blender -b "$out\smoke_source.blend" --python "$skill\mesh_audit.py" -- --collection Study --out "$out\audit" --closed Body,Head --self-intersections` | `audit.json`, `audit.txt` (exit 1 with `--strict` on errors) |
| [export_roundtrip.py](export_roundtrip.py) | `& $blender -b "$out\smoke_source.blend" --python "$skill\export_roundtrip.py" -- --collection Study --out "$out\export" --name burrowbud_study --formats fbx,obj,gltf --front-marker Snout --right-marker Marker_RightBud` | the exports and `<name>_export_report.json` |
| [export_roundtrip.py](export_roundtrip.py) (calibration) | `& $blender -b --factory-startup --python "$skill\export_roundtrip.py" -- --out "$out\calibration" --calibration --formats fbx,obj,gltf` | `calibration.fbx/.obj/.glb`, `calibration_export_report.json` |
| [partspec_bridge.py](partspec_bridge.py) (export) | `& $blender -b "$out\smoke_source.blend" --python "$skill\partspec_bridge.py" -- --export "$out\bridge\partlist_roundtrip.json" --collection Primitive --luau "$out\bridge\partlist_roundtrip.luau"` | a `bca-partlist/1` JSON and a Luau PartSpec review snippet |
| [partspec_bridge.py](partspec_bridge.py) (import) | `& $blender -b --factory-startup --python "$skill\partspec_bridge.py" -- --import parts.json --collection Primitive --save "$out\study.blend"` | a NEW `.blend` holding the primitives |
| [validate_skill.py](validate_skill.py) | `python "$skill\validate_skill.py"` | nothing; PASS/FAIL lines, exit 1 on any failure |

[bca_lib.py](bca_lib.py) holds the shared pieces: argument parsing, the output-folder guard, the
Roblox/Blender change of basis (`R2B`), colour conversion, bounds, cameras, the scale figure, and
the contact-sheet writer with its 5 x 7 label font.

## Reading the results

- **review_renders**: open every sheet ([visual review](../references/visual-review.md)). The
  manifest's `lowest_point_studs` should be about 0 for a creature standing on its base.
- **silhouette_compare**: IoU per view, plus the share of the study lost (red) and of the
  translation added (blue). Coverage only -- judge appeal from the translation's own renders
  ([Route A](../references/route-a-primitive-production.md)).
- **mesh_audit**: ERROR lines block a Route B export; WARN lines need a look. Open surfaces are
  only errors for objects listed in `--closed`.
- **export_roundtrip**: `stored_height_over_studs` should be 1.0 and `orientation_verdict` should
  read "matches the Roblox convention". `reimported.same_shape_and_orientation` checks Blender's
  own re-import. Nothing here verifies Roblox's importer
  ([Route B](../references/route-b-custom-mesh.md)).
