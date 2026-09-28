"""Route A bridge: Roblox part lists <-> Blender primitives, in the project's mockup space.

  Import a part list as Blender primitives (optionally saving a NEW study .blend):
    blender -b --factory-startup --python partspec_bridge.py -- --import parts.json
        --collection Primitive [--save study.blend] [--overwrite] [--studs-per-unit 1.0]

  Export primitive-tagged objects back to a part list plus a Luau PartSpec snippet for review:
    blender -b study.blend --python partspec_bridge.py -- --export parts.json
        --collection Primitive [--luau parts.luau] [--studs-per-unit 1.0]

MOCKUP SPACE is PlantSculpt's (src/ReplicatedStorage/SeedGame/Shared/PlantSculpt.luau): studs,
ground at Y = 0, front toward -Z. A part list is JSON:

  {"format": "bca-partlist/1", "space": "roblox-mockup", "units": "studs",
   "parts": [{"name": "Body", "shape": "Ball", "size": [3, 3, 3],
              "cf": [x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22],
              "color": [150, 110, 80], "material": "Plastic",
              "transparency": 0, "reflectance": 0, "studs": true}]}

`cf` is CFrame:GetComponents() order and the fields are TanglemireForms.PartSpec's. The Luau
snippet is written to --luau only (never into src/): a table a tools/art generator can adopt
after the owner approves the design. It changes nothing in the game by itself.

Geometry, measured in Roblox Studio 2026-09-24 (references/route-a-primitive-production.md):
Block is a box; Ball is a sphere whose diameter is the SMALLEST size axis; Cylinder runs along
its local X with diameter = the smaller of Y and Z; Wedge is full height at local +Z with its
knife edge at -Z; CornerWedge's apex stands over the (+X, -Z) corner. Imported Balls and
Cylinders are drawn at the size Roblox renders, so what Blender shows is what Studio shows.
CornerWedge is not in the project's replay vocabulary (CreatureModel.replayPart builds any
unknown shape as a Block); the bridge draws it for studies and flags it on export.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix

sys.dont_write_bytecode = True  # never leave __pycache__ inside the repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bca_lib as L  # noqa: E402

SHAPES = ("Block", "Ball", "Cylinder", "Wedge", "CornerWedge")
PROJECT_SHAPES = ("Block", "Ball", "Cylinder", "Wedge")
_UNIT_MESHES: dict[str, bpy.types.Mesh] = {}


def parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="partspec_bridge.py")
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--import", dest="import_path")
    mode.add_argument("--export", dest="export_path")
    p.add_argument("--collection", default="Primitive")
    p.add_argument("--save")
    p.add_argument("--overwrite", action="store_true")
    p.add_argument("--luau")
    p.add_argument("--studs-per-unit", type=float, default=1.0)
    return L.parse_args(p)


# ------------------------------------------------------------------ canonical unit primitives
# Built in ROBLOX part-local coordinates (x right, y up, z back), size 1 x 1 x 1. The object's
# matrix carries the Roblox->Blender change of basis, so these stay the literal Roblox shapes.


def unit_mesh(shape: str) -> bpy.types.Mesh:
    cached = _UNIT_MESHES.get(shape)
    if cached is not None and cached.name in bpy.data.meshes:
        return cached
    bm = bmesh.new()
    h = 0.5
    if shape == "Block":
        bmesh.ops.create_cube(bm, size=1.0)
    elif shape == "Ball":
        bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=12, radius=h)
    elif shape == "Cylinder":
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=24, radius1=h, radius2=h, depth=1.0)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "Y"))
    elif shape == "Wedge":
        v = [bm.verts.new(c) for c in ((-h, -h, -h), (h, -h, -h), (-h, -h, h), (h, -h, h), (-h, h, h), (h, h, h))]
        for face in ((0, 1, 3, 2), (2, 3, 5, 4), (0, 4, 5, 1), (0, 2, 4), (1, 5, 3)):
            bm.faces.new([v[i] for i in face])
    elif shape == "CornerWedge":
        v = [bm.verts.new(c) for c in ((-h, -h, -h), (h, -h, -h), (h, -h, h), (-h, -h, h), (h, h, -h))]
        for face in ((0, 1, 2, 3), (0, 1, 4), (1, 2, 4), (0, 4, 3), (3, 4, 2)):
            bm.faces.new([v[i] for i in face])
    else:
        raise SystemExit(f"unknown shape {shape!r}; use one of {SHAPES}")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(f"BCA_Unit{shape}")
    bm.to_mesh(mesh)
    bm.free()
    if shape in ("Ball", "Cylinder"):
        for poly in mesh.polygons:
            poly.use_smooth = True
    mesh["bca_unit_primitive"] = shape
    mesh.materials.append(None)  # one slot, linked per object so shared meshes keep their own colours
    _UNIT_MESHES[shape] = mesh
    return mesh


def rendered_size(shape: str, size) -> tuple[float, float, float]:
    x, y, z = size
    if shape == "Ball":
        d = min(x, y, z)
        return (d, d, d)
    if shape == "Cylinder":
        d = min(y, z)
        return (x, d, d)
    return (x, y, z)


# ------------------------------------------------------------------------------------ import


def import_partlist(path: str, collection_name: str, spu: float) -> list[bpy.types.Object]:
    with open(path, encoding="utf-8") as handle:
        doc = json.load(handle)
    if doc.get("format") != "bca-partlist/1":
        raise SystemExit(f"{path}: not a bca-partlist/1 document")
    coll = bpy.data.collections.get(collection_name) or bpy.data.collections.new(collection_name)
    if coll.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(coll)
    objs = []
    for spec in doc["parts"]:
        shape = spec["shape"]
        size = rendered_size(shape, spec["size"])
        cf = L.cframe_to_matrix(spec["cf"])
        cf.translation = cf.translation / spu
        obj = bpy.data.objects.new(spec["name"], unit_mesh(shape))
        coll.objects.link(obj)
        obj.matrix_world = L.R2B @ cf @ Matrix.Diagonal((size[0] / spu, size[1] / spu, size[2] / spu, 1.0))
        color = spec.get("color") or [163, 162, 165]
        material = spec.get("material", "Plastic")
        obj["rbx_shape"] = shape
        obj["rbx_color"] = list(color)
        obj["rbx_material"] = material
        obj["rbx_studs"] = bool(spec.get("studs", True))
        obj["rbx_transparency"] = float(spec.get("transparency", 0) or 0)
        obj["rbx_reflectance"] = float(spec.get("reflectance", 0) or 0)
        if list(size) != list(spec["size"]):
            obj["rbx_size_as_authored"] = list(spec["size"])
        mat_name = f"RBX_{material}_{color[0]}_{color[1]}_{color[2]}"
        obj.material_slots[0].link = "OBJECT"
        obj.material_slots[0].material = L.flat_material(mat_name, color, emission=2.0 if material == "Neon" else 0.0)
        obj.color = L.rgb255_to_linear(color)
        objs.append(obj)
    return objs


# ------------------------------------------------------------------------------------ export


def linear_to_srgb255(c: float) -> int:
    c = max(0.0, min(1.0, c))
    s = c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055
    return int(round(s * 255))


def export_partlist(collection_name: str, spu: float) -> tuple[dict, list[str]]:
    coll = bpy.data.collections.get(collection_name)
    if coll is None:
        raise SystemExit(f"no collection named {collection_name!r}")
    notes: list[str] = []
    parts = []
    for obj in sorted(coll.all_objects, key=lambda o: o.name):
        shape = obj.get("rbx_shape")
        if shape is None:
            notes.append(f"SKIP {obj.name}: no rbx_shape property -- not a Roblox primitive, cannot be exported")
            continue
        if shape not in SHAPES:
            notes.append(f"ERROR {obj.name}: unknown rbx_shape {shape!r}")
            continue
        mesh = obj.data
        lo = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
        hi = [max(v.co[i] for v in mesh.vertices) for i in range(3)]
        if mesh.get("bca_unit_primitive") != shape or any(abs(a + 0.5) > 1e-4 for a in lo) \
                or any(abs(b - 0.5) > 1e-4 for b in hi):
            notes.append(f"ERROR {obj.name}: the mesh is not the unit {shape}; edited geometry has no Roblox equivalent")
            continue
        rob = L.B2R @ obj.matrix_world
        loc, rot, scale = rob.decompose()
        if any(s <= 0 for s in scale):
            notes.append(f"ERROR {obj.name}: zero or negative scale")
            continue
        rebuilt = Matrix.LocRotScale(loc, rot, scale)
        if any(abs(rebuilt[i][j] - rob[i][j]) > 1e-4 for i in range(3) for j in range(3)):
            notes.append(f"ERROR {obj.name}: sheared transform; a Roblox part cannot shear")
            continue
        size = [scale[i] * spu for i in range(3)]
        if shape == "Ball" and (max(size) - min(size)) > 1e-3:
            notes.append(f"WARN {obj.name}: a non-uniform Ball renders as a sphere of its smallest axis")
        if shape == "Cylinder" and abs(size[1] - size[2]) > 1e-3:
            notes.append(f"WARN {obj.name}: a Cylinder's circle is its smaller Y/Z; it is never an ellipse")
        if shape not in PROJECT_SHAPES:
            notes.append(f"WARN {obj.name}: {shape} is not in the project's replay vocabulary "
                         "(CreatureModel.replayPart would build a Block)")
        cf = Matrix.LocRotScale(loc * spu, rot, None)
        if "rbx_color" in obj:
            color = [int(c) for c in obj["rbx_color"]]
        else:
            mat = obj.active_material
            lin = mat.diffuse_color if mat else (0.64, 0.64, 0.64, 1)
            color = [linear_to_srgb255(lin[i]) for i in range(3)]
        name = obj.name
        base, _, suffix = name.rpartition(".")
        if base and suffix.isdigit():
            name = base  # Blender's duplicate suffix is not part of the design's name
        parts.append({
            "name": name,
            "shape": shape,
            "size": [round(s, 4) for s in size],
            "cf": [round(v, 5) for v in L.matrix_to_cframe(cf)],
            "color": color,
            "material": obj.get("rbx_material", "Plastic"),
            "transparency": float(obj.get("rbx_transparency", 0)),
            "reflectance": float(obj.get("rbx_reflectance", 0)),
            "studs": bool(obj.get("rbx_studs", True)),
        })
    doc = {"format": "bca-partlist/1", "space": "roblox-mockup", "units": "studs",
           "source": {"blend": bpy.data.filepath, "collection": collection_name, "blender": bpy.app.version_string},
           "part_count": len(parts), "parts": parts}
    return doc, notes


def luau_snippet(doc: dict) -> str:
    def num(v):
        return f"{v:.4f}".rstrip("0").rstrip(".") if v != 0 else "0"
    lines = ["-- Generated by blender-assisted-creature-art/scripts/partspec_bridge.py for REVIEW.",
             "-- Mockup space: studs, ground at Y = 0, front toward -Z (PlantSculpt).",
             "-- Not wired into the game. After the owner approves the design, adopt it through the",
             "-- species' tools/art generator and its serialize() -- never paste into a *Forms table by hand.",
             f"-- {doc['part_count']} parts from collection {doc['source']['collection']}.",
             "return {"]
    for p in doc["parts"]:
        size = ", ".join(num(v) for v in p["size"])
        cf = ", ".join(num(v) for v in p["cf"])
        r, g, b = p["color"]
        extra = ""
        if p["transparency"]:
            extra += f", transparency = {num(p['transparency'])}"
        if p["reflectance"]:
            extra += f", reflectance = {num(p['reflectance'])}"
        if not p["studs"]:
            extra += ", studs = false"
        lines.append(f'\t{{ name = "{p["name"]}", shape = "{p["shape"]}", size = Vector3.new({size}), '
                     f"cf = CFrame.new({cf}), color = Color3.fromRGB({r}, {g}, {b}), "
                     f"material = Enum.Material.{p['material']}{extra} }},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main() -> None:
    args = parse()
    spu = args.studs_per_unit
    if args.import_path:
        objs = import_partlist(args.import_path, args.collection, spu)
        print(f"BCA_BRIDGE_IMPORTED {len(objs)} parts into collection {args.collection!r}")
        if args.save:
            print("BCA_BRIDGE_SAVED", L.save_new_blend(args.save, overwrite=args.overwrite))
        return
    doc, notes = export_partlist(args.collection, spu)
    L.write_json(doc, args.export_path)
    for n in notes:
        print(n)
    if args.luau:
        L.ensure_out_dir(os.path.dirname(os.path.abspath(args.luau)))
        with open(args.luau, "w", encoding="utf-8") as handle:
            handle.write(luau_snippet(doc))
    errors = sum(1 for n in notes if n.startswith("ERROR"))
    print(f"BCA_BRIDGE_EXPORTED {doc['part_count']} parts, {errors} errors -> {args.export_path}")


if __name__ == "__main__":
    main()
