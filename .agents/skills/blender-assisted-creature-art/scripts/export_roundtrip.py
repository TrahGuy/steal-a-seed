"""Export a collection for a Roblox import route, then prove what the files contain. Never saves.

  blender -b source.blend --python export_roundtrip.py -- --out DIR --collection NAME
      [--name BASE] [--formats fbx,obj,gltf] [--studs-per-unit 1.0]
      [--front-marker OBJ] [--right-marker OBJ] [--fbx-global-scale S] [--no-bake-space]

  blender -b --factory-startup --python export_roundtrip.py -- --out DIR --calibration

--calibration builds, in memory, a 1x1x1-stud cube standing on the ground, a FRONT block toward
the creature's front (Roblox -Z), a RIGHT block on its right (Roblox +X) and a 5-stud UP pole,
and exports those instead. Importing that file once into a scratch place is how the Roblox side
of scale and axes gets settled.

FBX settings: selected objects only, meshes (and armatures when present), modifiers applied,
face smoothing, no leaf bones, no animation, axis_forward='Z' and axis_up='Y' -- which maps this
skill's Blender front (-Y) to file -Z and the creature's right (Blender -X) to file +X -- and
bake_space_transform so static geometry is stored in file space. OBJ: forward 'Z', up 'Y',
global_scale = studs per unit. glTF: the exporter's fixed +Y-up conversion (the glTF front is +Z).

Verification here is Blender-side only: each file is parsed (FBX through Blender's own
io_scene_fbx.parse_fbx, OBJ as text, glTF's JSON chunk), and the report gives the file's axis and
unit metadata, the stored bounds in file units after node transforms, the ratio of stored height
to the height in studs, and where the markers landed. Each file is also re-imported into the
running (never saved) session and its bounds compared with the source. What Roblox's 3D Importer
does with the file is NOT verified by this script.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import struct
import sys

import bpy
from mathutils import Euler, Matrix, Quaternion, Vector

sys.dont_write_bytecode = True  # never leave __pycache__ inside the repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bca_lib as L  # noqa: E402


def parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="export_roundtrip.py")
    p.add_argument("--out", required=True)
    p.add_argument("--collection")
    p.add_argument("--name", default="export")
    p.add_argument("--formats", default="fbx,obj")
    p.add_argument("--studs-per-unit", type=float, default=1.0)
    p.add_argument("--front-marker")
    p.add_argument("--right-marker")
    p.add_argument("--fbx-global-scale", type=float, default=None,
                   help="default: studs-per-unit / 100, which stores studs as the file's values")
    p.add_argument("--no-bake-space", action="store_true", help="keep the axis change in node transforms")
    p.add_argument("--calibration", action="store_true")
    return L.parse_args(p)


# ------------------------------------------------------------------------------ calibration


def build_calibration(spu: float) -> list[bpy.types.Object]:
    for o in list(bpy.context.scene.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    k = 1.0 / spu
    specs = [
        ("CAL_Cube", (1, 1, 1), (0, 0, 0.5)),
        ("CAL_FRONT", (0.5, 1.0, 0.5), (0, -2.0, 0.25)),   # Blender -Y: the creature's front
        ("CAL_RIGHT", (1.0, 0.5, 0.5), (-2.0, 0, 0.25)),   # Blender -X: the creature's right
        ("CAL_UP", (0.3, 0.3, 5.0), (0, 2.0, 2.5)),
    ]
    objs = []
    for name, size, centre in specs:
        bm = L.box_bmesh([s * k for s in size], [c * k for c in centre])
        objs.append(L.mesh_object(name, bm))
    return objs


# ------------------------------------------------------------------------------- file readers


def _fbx_props70(elem) -> dict:
    out = {}
    for child in elem.elems:
        if child.id == b"Properties70":
            for p in child.elems:
                if p.id == b"P" and p.props:
                    out[p.props[0].decode(errors="replace")] = list(p.props[4:])
    return out


def _fbx_name(raw) -> str:
    return raw.split(b"\x00\x01")[0].decode(errors="replace") if isinstance(raw, bytes) else str(raw)


def read_fbx(path: str) -> dict:
    from io_scene_fbx import parse_fbx  # ships with Blender; verified importable on 5.2

    root, version = parse_fbx.parse(path)
    top = {e.id: e for e in root.elems}
    settings = _fbx_props70(top[b"GlobalSettings"]) if b"GlobalSettings" in top else {}
    models, geoms, parent_of, geom_to_model = {}, {}, {}, {}
    for e in top[b"Objects"].elems:
        if e.id == b"Model":
            models[e.props[0]] = {"name": _fbx_name(e.props[1]), "p": _fbx_props70(e)}
        elif e.id == b"Geometry":
            for c in e.elems:
                if c.id == b"Vertices":
                    geoms[e.props[0]] = list(c.props[0])
    for c in top[b"Connections"].elems:
        if c.id == b"C" and c.props[0] == b"OO":
            child, parent = c.props[1], c.props[2]
            if child in geoms and parent in models:
                geom_to_model[child] = parent
            elif child in models:
                parent_of[child] = parent

    def local(mid) -> Matrix:
        p = models[mid]["p"]
        t = Vector(p.get("Lcl Translation", [0, 0, 0])[:3])
        r = [math.radians(a) for a in p.get("Lcl Rotation", [0, 0, 0])[:3]]
        pre = [math.radians(a) for a in p.get("PreRotation", [0, 0, 0])[:3]]
        s = p.get("Lcl Scaling", [1, 1, 1])[:3]
        rot = Euler(pre, "XYZ").to_matrix().to_4x4() @ Euler(r, "XYZ").to_matrix().to_4x4()
        return Matrix.Translation(t) @ rot @ Matrix.Diagonal((*s, 1.0))

    def world(mid) -> Matrix:
        m = local(mid)
        parent = parent_of.get(mid)
        while parent in models:
            m = local(parent) @ m
            parent = parent_of.get(parent)
        return m

    per_model = {}
    for gid, flat in geoms.items():
        mid = geom_to_model.get(gid)
        if mid is None:
            continue
        m = world(mid)
        pts = [m @ Vector((flat[i], flat[i + 1], flat[i + 2])) for i in range(0, len(flat), 3)]
        per_model[models[mid]["name"]] = pts
    keys = ["UpAxis", "UpAxisSign", "FrontAxis", "FrontAxisSign", "CoordAxis", "CoordAxisSign",
            "UnitScaleFactor", "OriginalUnitScaleFactor"]
    return {"version": version, "settings": {k: settings.get(k, [None])[0] for k in keys}, "points": per_model}


def read_obj(path: str) -> dict:
    per, name = {}, "object"
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if line.startswith("o "):
                name = line[2:].strip()
                per.setdefault(name, [])
            elif line.startswith("v "):
                x, y, z = (float(v) for v in line.split()[1:4])
                per.setdefault(name, []).append(Vector((x, y, z)))
    return {"settings": {"format": "OBJ (unitless)"}, "points": per}


def read_glb(path: str) -> dict:
    with open(path, "rb") as handle:
        data = handle.read()
    length = struct.unpack_from("<I", data, 12)[0]
    doc = json.loads(data[20:20 + length].decode("utf-8"))
    nodes = doc.get("nodes", [])
    parent = {c: i for i, n in enumerate(nodes) for c in n.get("children", [])}

    def local(i) -> Matrix:
        n = nodes[i]
        if "matrix" in n:
            v = n["matrix"]
            return Matrix([v[0:4], v[4:8], v[8:12], v[12:16]]).transposed()
        t = Matrix.Translation(Vector(n.get("translation", [0, 0, 0])))
        x, y, z, w = n.get("rotation", [0, 0, 0, 1])
        r = Quaternion((w, x, y, z)).to_matrix().to_4x4()
        s = Matrix.Diagonal((*n.get("scale", [1, 1, 1]), 1.0))
        return t @ r @ s

    per = {}
    for i, n in enumerate(nodes):
        if "mesh" not in n:
            continue
        m, j = local(i), parent.get(i)
        while j is not None:
            m = local(j) @ m
            j = parent.get(j)
        pts = []
        for prim in doc["meshes"][n["mesh"]]["primitives"]:
            acc = doc["accessors"][prim["attributes"]["POSITION"]]
            lo, hi = acc["min"], acc["max"]
            for cx in (lo[0], hi[0]):
                for cy in (lo[1], hi[1]):
                    for cz in (lo[2], hi[2]):
                        pts.append(m @ Vector((cx, cy, cz)))
        per[n.get("name", f"node{i}")] = pts
    return {"settings": {"asset": doc.get("asset", {}), "note": "glTF is +Y up; its front is +Z by convention"},
            "points": per}


def summarise(points: dict, height_studs: float, front: str | None, right: str | None) -> dict:
    allp = [p for pts in points.values() for p in pts]
    if not allp:
        return {"error": "no geometry read back"}
    lo = Vector((min(p.x for p in allp), min(p.y for p in allp), min(p.z for p in allp)))
    hi = Vector((max(p.x for p in allp), max(p.y for p in allp), max(p.z for p in allp)))
    centre = (lo + hi) / 2
    out = {"bounds_min": list(lo), "bounds_max": list(hi), "size": list(hi - lo),
           "stored_height_y": hi.y - lo.y,
           "stored_height_over_studs": (hi.y - lo.y) / height_studs if height_studs else None}

    def centroid(name):
        for key, pts in points.items():
            if pts and (key == name or key.startswith(name + ".") or key.startswith(name + "_")):
                return sum(pts, Vector()) / len(pts)
        return None
    front_c = centroid(front) if front else None
    right_c = centroid(right) if right else None
    if front_c is not None:
        out["front_marker"] = {"centroid": list(front_c), "toward_minus_z": front_c.z < centre.z}
    if right_c is not None:
        out["right_marker"] = {"centroid": list(right_c), "toward_plus_x": right_c.x > centre.x}
    if front_c is not None and right_c is not None:
        fwd_ok, right_ok = front_c.z < centre.z, right_c.x > centre.x
        if fwd_ok and right_ok:
            verdict = "matches the Roblox convention: front toward -Z, right toward +X"
        elif not fwd_ok and not right_ok:
            verdict = "turned 180 degrees about Y: faces +Z (the glTF convention); a -Z-forward reader sees its back"
        else:
            verdict = "MIRRORED: handedness flipped, asymmetric details land on the wrong side"
        out["orientation_verdict"] = verdict
    return out


# ------------------------------------------------------------------------------------ export


def select_only(objs):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]


def reimport_bounds(fmt: str, path: str) -> dict:
    before = set(bpy.data.objects)
    if fmt == "fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    elif fmt == "obj":
        bpy.ops.wm.obj_import(filepath=path, forward_axis="Z", up_axis="Y")
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    result = {"objects": len(new)}
    if meshes:
        lo, hi = L.world_bounds(meshes)
        result.update({"bounds_min": list(lo), "bounds_max": list(hi),
                       "tris": sum(L.evaluated_mesh_stats(o)["tris"] for o in meshes)})
    for o in new:
        bpy.data.objects.remove(o, do_unlink=True)
    return result


def main() -> None:
    args = parse()
    out = L.ensure_out_dir(args.out)
    spu = args.studs_per_unit
    if args.calibration:
        objs = build_calibration(spu)
        base = "calibration"
        front, right = "CAL_FRONT", "CAL_RIGHT"
    else:
        objs = [o for o in L.subject_objects(args.collection) if o.type == "MESH"]
        base = args.name
        front, right = args.front_marker, args.right_marker
    if not objs:
        raise SystemExit("nothing to export: the exporters here take mesh objects; convert curves first")
    lo, hi = L.world_bounds(objs)
    height_studs = (hi.z - lo.z) * spu
    source = {"bounds_min": list(lo), "bounds_max": list(hi), "height_studs": height_studs,
              "tris": sum(L.evaluated_mesh_stats(o)["tris"] for o in objs)}
    has_armature = any(o.type == "ARMATURE" for o in bpy.context.scene.objects)
    fbx_scale = args.fbx_global_scale if args.fbx_global_scale is not None else spu / 100.0
    select_only(objs)
    report = {"blender": bpy.app.version_string, "source_blend": bpy.data.filepath, "studs_per_unit": spu,
              "source": source, "files": {}}
    for fmt in [f.strip() for f in args.formats.split(",") if f.strip()]:
        if fmt == "fbx":
            path = os.path.join(out, base + ".fbx")
            settings = dict(filepath=path, use_selection=True,
                            object_types={"MESH", "ARMATURE"} if has_armature else {"MESH"},
                            use_mesh_modifiers=True, mesh_smooth_type="FACE", add_leaf_bones=False,
                            bake_anim=False, axis_forward="Z", axis_up="Y", apply_unit_scale=True,
                            apply_scale_options="FBX_SCALE_NONE", global_scale=fbx_scale,
                            bake_space_transform=not (args.no_bake_space or has_armature),
                            path_mode="COPY", embed_textures=False)
            bpy.ops.export_scene.fbx(**settings)
            read = read_fbx(path)
        elif fmt == "obj":
            path = os.path.join(out, base + ".obj")
            settings = dict(filepath=path, export_selected_objects=True, forward_axis="Z", up_axis="Y",
                            global_scale=spu, apply_modifiers=True, export_uv=True, export_normals=True,
                            export_materials=True, export_triangulated_mesh=False)
            bpy.ops.wm.obj_export(**settings)
            read = read_obj(path)
        elif fmt == "gltf":
            path = os.path.join(out, base + ".glb")
            settings = dict(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                            export_apply=True)
            bpy.ops.export_scene.gltf(**settings)
            read = read_glb(path)
        else:
            raise SystemExit(f"unknown format {fmt!r}")
        reimported = reimport_bounds(fmt, path)
        if "bounds_min" in reimported and hi.z > lo.z:
            # Blender's importers honour the file's own unit and axis metadata, so an FBX that
            # declares centimetres comes back at 1/100 in metres. The check is that it comes back
            # as the SAME shape in the SAME orientation at one uniform factor.
            ratio = (reimported["bounds_max"][2] - reimported["bounds_min"][2]) / (hi.z - lo.z)
            src = list(lo) + list(hi)
            got = reimported["bounds_min"] + reimported["bounds_max"]
            tol = 1e-3 * max(abs(v) * ratio for v in src) + 1e-6
            reimported["scale_vs_source"] = ratio
            reimported["same_shape_and_orientation"] = all(abs(a * ratio - b) <= tol for a, b in zip(src, got))
        entry = {"path": path, "bytes": os.path.getsize(path),
                 "settings": {k: (sorted(v) if isinstance(v, set) else v) for k, v in settings.items() if k != "filepath"},
                 "file_metadata": read["settings"],
                 "file_space": summarise(read["points"], height_studs, front, right),
                 "reimported": reimported}
        report["files"][fmt] = entry
        select_only(objs)
    report["roblox_side"] = ("NOT VERIFIED by this script. Settle scale and axes once with the calibration "
                             "file in a scratch place; see references/route-b-custom-mesh.md.")
    L.write_json(report, os.path.join(out, base + "_export_report.json"))
    for fmt, e in report["files"].items():
        fs = e["file_space"]
        print(f"[{fmt}] stored height {fs.get('stored_height_y', 0):.4f} (ratio to studs "
              f"{fs.get('stored_height_over_studs')}); orientation: {fs.get('orientation_verdict', 'no markers given')}")
    print("BCA_EXPORT_OK", os.path.join(out, base + "_export_report.json"))


if __name__ == "__main__":
    main()
