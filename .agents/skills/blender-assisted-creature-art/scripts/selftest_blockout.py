"""Self-test fixture: an original, throwaway botanical creature blockout ("Burrowbud") that
exercises the review and validation pipeline. It is NOT a production creature, a species
proposal or an approved design; it exists so the scripts have something honest to chew on.

  blender -b --factory-startup --python selftest_blockout.py -- --out DIR [--overwrite]

Builds, in a fresh factory-startup session (it never opens an existing .blend):
  * collection Study     -- the smooth study. Each tool matches a shape problem: subdivided
                            primitives for the seed body and head masses, an exact Boolean
                            difference for the recessed mouth, bevelled Bezier curves (converted
                            to mesh) for tapered weight-bearing root legs, and a procedural cupped,
                            bent leaf with Solidify for the one signature feature.
  * collection Primitive -- a Route A translation of the same design in the Roblox part
                            vocabulary, written to DIR/partlist_translation.json and built from it
                            through partspec_bridge.import_partlist.
  * collection Cutters   -- the Boolean cutter, hidden from renders.

Saves DIR/smoke_source.blend (the editable source) and DIR/partlist_translation.json.
Conventions: faces -Y (right = -X), stands on z = 0, 1 Blender unit = 1 stud. "Snout" (front)
and "Marker_RightBud" (right shoulder) are the axis markers the export check looks for.
"""
from __future__ import annotations

import argparse
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.dont_write_bytecode = True  # never leave __pycache__ inside the repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bca_lib as L  # noqa: E402
import partspec_bridge as B  # noqa: E402

PALETTE = {
    "bark": (138, 98, 64), "head": (150, 108, 70), "brow": (96, 66, 44), "belly": (224, 206, 160),
    "cheek": (214, 182, 140), "mouth": (74, 30, 36), "eye": (32, 30, 36), "glint": (250, 250, 245),
    "root": (116, 86, 58), "leaf": (86, 150, 66), "rib": (124, 182, 92), "bud": (238, 150, 138),
}


def parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="selftest_blockout.py")
    p.add_argument("--out", required=True)
    p.add_argument("--overwrite", action="store_true")
    return L.parse_args(p)


def collection(name: str) -> bpy.types.Collection:
    coll = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(coll)
    return coll


def mat(key: str, emission: float = 0.0) -> bpy.types.Material:
    return L.flat_material("Smoke_" + key + ("_glow" if emission else ""), PALETTE[key], emission=emission)


def ellipsoid(name, coll, centre, radii, key, subsurf=0, taper_top=0.0, segments=(32, 16)) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments[0], v_segments=segments[1], radius=1.0)
    for v in bm.verts:
        squeeze = 1.0 - taper_top * max(0.0, v.co.z)  # narrower toward the top: a seed, not a ball
        v.co = Vector((v.co.x * radii[0] * squeeze, v.co.y * radii[1] * squeeze, v.co.z * radii[2]))
    obj = L.mesh_object(name, bm, coll)
    obj.location = centre
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.data.materials.append(mat(key))
    if subsurf:
        mod = obj.modifiers.new("Subdivision", "SUBSURF")
        mod.levels, mod.render_levels = subsurf, subsurf
    return obj


def tapered_curve(name, coll, points, radii, bevel, key) -> bpy.types.Object:
    """A Bezier path bevelled into a tube whose radius follows `radii` -- the right tool for
    roots, horns and claws that must curve AND taper -- converted to a mesh for export."""
    data = bpy.data.curves.new(name + "_curve", "CURVE")
    data.dimensions = "3D"
    data.bevel_depth = bevel
    data.bevel_resolution = 3
    data.use_fill_caps = True
    data.resolution_u = 10
    spline = data.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bp, co, r in zip(spline.bezier_points, points, radii):
        bp.co = co
        bp.radius = r
        bp.handle_left_type = bp.handle_right_type = "AUTO"
    curve_obj = bpy.data.objects.new(name + "_curve", data)
    coll.objects.link(curve_obj)
    bpy.context.view_layer.update()
    ev = curve_obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = bpy.data.meshes.new_from_object(ev)
    bpy.data.objects.remove(curve_obj, do_unlink=True)
    bpy.data.curves.remove(data)
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    mesh.materials.clear()
    mesh.materials.append(mat(key))
    return obj


def leaf_centre(t: float) -> Vector:
    return Vector((0.12 * math.sin(math.pi * t), -0.1 + 2.6 * t, 3.55 + 1.5 * math.sin(math.pi * t * 0.9) - 0.6 * t))


def leaf_width(t: float) -> float:
    return 1.05 * (math.sin(math.pi * min(1.0, t * 1.05)) ** 0.75) * (1.0 - 0.35 * t)


def leaf(name, coll) -> bpy.types.Object:
    """The signature feature: one broad leaf rising off the crown and curling back over the body,
    cupped (edges up), pointed, given thickness by Solidify."""
    along, across = 16, 8
    bm = bmesh.new()
    grid = []
    for i in range(along + 1):
        t = i / along
        c = leaf_centre(t)
        w = leaf_width(t)
        row = []
        for j in range(across + 1):
            u = -1.0 + 2.0 * j / across
            row.append(bm.verts.new(c + Vector((u * w, 0.0, 0.22 * u * u * (0.3 + t)))))
        grid.append(row)
    for i in range(along):
        for j in range(across):
            bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)  # the base and the tip collapse to points
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
    obj = L.mesh_object(name, bm, coll)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    obj.data.materials.append(mat("leaf"))
    mod = obj.modifiers.new("Solidify", "SOLIDIFY")
    mod.thickness = 0.06
    mod.offset = 0.0
    return obj


# ---------------------------------------------------------------------- the Route A translation


def rb(p) -> Vector:
    return L.blender_to_roblox_vec(Vector(p))


def cf_list(pos: Vector, rot: Matrix | None = None) -> list[float]:
    m = rot.to_4x4() if rot is not None else Matrix.Identity(4)
    m.translation = pos
    return [round(v, 5) for v in L.matrix_to_cframe(m)]


def basis(x: Vector, y: Vector, z: Vector) -> Matrix:
    return Matrix((x, y, z)).transposed()


def cylinder_between(name, p0, p1, diameter, key) -> dict:
    a, b = rb(p0), rb(p1)
    axis = b - a
    x = axis.normalized()
    up = Vector((0, 1, 0)) if abs(x.y) < 0.99 else Vector((0, 0, 1))
    z = x.cross(up).normalized()
    y = z.cross(x)
    return {"name": name, "shape": "Cylinder", "size": [round(axis.length, 4), diameter, diameter],
            "cf": cf_list((a + b) / 2, basis(x, y, z)), "color": list(PALETTE[key]), "material": "Plastic"}


def part(name, shape, size, pos_blender, key, rot=None, material="Plastic", studs=True) -> dict:
    return {"name": name, "shape": shape, "size": list(size), "cf": cf_list(rb(pos_blender), rot),
            "color": list(PALETTE[key]), "material": material, "studs": studs}


def translation_parts() -> list[dict]:
    rot_y90 = Matrix.Rotation(math.radians(90), 3, "Y")      # a Cylinder's axis turned to face front
    rot_z90 = Matrix.Rotation(math.radians(90), 3, "Z")      # a Cylinder's axis turned upright
    flip = Matrix.Rotation(math.radians(180), 3, "Z")        # a Wedge upside down: flat top, sloped underside
    parts = [
        part("Body", "Ball", (2.6, 2.6, 2.6), (0, 0.15, 1.45), "bark"),
        part("BodyHip", "Cylinder", (1.0, 2.7, 2.7), (0, 0.15, 1.0), "bark", rot_z90),
        part("Belly", "Cylinder", (0.4, 1.5, 1.5), (0, -1.0, 1.35), "belly", rot_y90),
        part("Head", "Ball", (1.85, 1.85, 1.85), (0, -0.35, 2.75), "head"),
        part("Brow", "Wedge", (1.3, 0.3, 0.45), (0, -1.05, 3.18), "brow", flip),
        part("CheekR", "Ball", (0.62, 0.62, 0.62), (-0.55, -1.02, 2.62), "cheek"),
        part("CheekL", "Ball", (0.62, 0.62, 0.62), (0.55, -1.02, 2.62), "cheek"),
        part("Jaw", "Block", (1.1, 0.34, 0.6), (0, -0.95, 2.05), "bark", Matrix.Rotation(math.radians(-10), 3, "X")),
        part("MouthInterior", "Block", (0.8, 0.28, 0.12), (0, -0.95, 2.4), "mouth", studs=False),
        part("Snout", "Ball", (0.34, 0.34, 0.34), (0, -1.32, 2.72), "head"),
        part("EyeR", "Ball", (0.28, 0.28, 0.28), (-0.34, -1.2, 2.98), "eye", studs=False),
        part("EyeL", "Ball", (0.28, 0.28, 0.28), (0.34, -1.2, 2.98), "eye", studs=False),
        part("Marker_RightBud", "Ball", (0.4, 0.4, 0.4), (-1.08, -0.2, 2.25), "bud", material="Neon", studs=False),
    ]
    for tag, sx, sy in (("R", -1, -1), ("L", 1, -1), ("B", 0, 1)):
        if tag == "B":
            p0, p1, p2 = (0, 0.6, 0.8), (0, 1.5, 0.55), (0, 1.85, 0.08)
        else:
            p0, p1, p2 = (sx * 0.55, sy * 0.45, 0.85), (sx * 1.3, sy * 0.95, 0.6), (sx * 1.65, sy * 1.25, 0.08)
        parts.append(cylinder_between(f"RootUpper{tag}", p0, p1, 0.42, "root"))
        parts.append(cylinder_between(f"RootLower{tag}", p1, p2, 0.3, "root"))
        parts.append(part(f"Foot{tag}", "Cylinder", (0.14, 0.62, 0.62), (p2[0], p2[1], 0.07), "root", rot_z90))
    # The leaf: two plates along the arc and a pointed tip from two mirrored Wedges.
    samples = [0.0, 0.33, 0.66, 1.0]
    for k in range(3):
        a, b = rb(leaf_centre(samples[k])), rb(leaf_centre(samples[k + 1]))
        d = (b - a).normalized()
        lat = Vector((0, 1, 0)).cross(d).normalized()
        nrm = d.cross(lat)
        width = 2 * leaf_width((samples[k] + samples[k + 1]) / 2)
        mid = (a + b) / 2
        if k < 2:
            parts.append({"name": f"LeafPlate{k + 1}", "shape": "Block",
                          "size": [round(width, 4), 0.1, round((b - a).length, 4)],
                          "cf": cf_list(mid, basis(lat, nrm, d)), "color": list(PALETTE["leaf"]), "material": "Plastic"})
        else:
            half = width / 2
            for side, sign in (("A", 1), ("B", -1)):
                ycol = lat * sign
                zcol = -d
                xcol = ycol.cross(zcol)
                parts.append({"name": f"LeafTip{side}", "shape": "Wedge",
                              "size": [0.1, round(half, 4), round((b - a).length, 4)],
                              "cf": cf_list(mid + ycol * (half / 2), basis(xcol, ycol, zcol)),
                              "color": list(PALETTE["leaf"]), "material": "Plastic"})
    return parts


def main() -> None:
    args = parse()
    out = L.ensure_out_dir(args.out)
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    study, cutters = collection("Study"), collection("Cutters")

    body = ellipsoid("Body", study, (0, 0.15, 1.45), (1.51, 1.35, 1.24), "bark", subsurf=1, taper_top=0.18)
    ellipsoid("Belly", study, (0, -0.95, 1.35), (0.85, 0.42, 0.78), "belly", subsurf=1)
    head = ellipsoid("Head", study, (0, -0.35, 2.75), (1.05, 0.95, 0.9), "head", subsurf=1)
    ellipsoid("CheekR", study, (-0.55, -1.02, 2.62), (0.34, 0.27, 0.29), "cheek")
    ellipsoid("CheekL", study, (0.55, -1.02, 2.62), (0.34, 0.27, 0.29), "cheek")
    ellipsoid("Jaw", study, (0, -0.95, 2.05), (0.69, 0.44, 0.28), "bark", subsurf=1)
    ellipsoid("Snout", study, (0, -1.32, 2.72), (0.22, 0.18, 0.15), "head")
    ellipsoid("EyeR", study, (-0.34, -1.2, 2.98), (0.14, 0.14, 0.14), "eye", segments=(16, 8))
    ellipsoid("EyeL", study, (0.34, -1.2, 2.98), (0.14, 0.14, 0.14), "eye", segments=(16, 8))
    # One shared light: both glints sit to the viewer's upper left.
    ellipsoid("GlintR", study, (-0.29, -1.33, 3.03), (0.045, 0.045, 0.045), "glint", segments=(12, 6))
    ellipsoid("GlintL", study, (0.39, -1.33, 3.03), (0.045, 0.045, 0.045), "glint", segments=(12, 6))
    tapered_curve("Brow", study, [(-0.62, -1.05, 3.12), (0, -1.22, 3.28), (0.62, -1.05, 3.12)],
                  [0.8, 1.2, 0.8], 0.13, "brow")
    for tag, sx, sy in (("R", -1, -1), ("L", 1, -1), ("B", 0, 1)):
        if tag == "B":
            pts = [(0, 0.6, 0.8), (0, 1.5, 0.55), (0, 1.85, 0.08)]
        else:
            pts = [(sx * 0.55, sy * 0.45, 0.85), (sx * 1.3, sy * 0.95, 0.6), (sx * 1.65, sy * 1.25, 0.08)]
        tapered_curve(f"Root{tag}", study, pts, [1.0, 0.75, 0.45], 0.24, "root")
        ellipsoid(f"Foot{tag}", study, (pts[2][0], pts[2][1], 0.12), (0.34, 0.34, 0.117), "root")
    leaf("LeafCrest", study)
    tapered_curve("LeafMidrib", study, [leaf_centre(t) + Vector((0, 0, 0.05)) for t in (0.02, 0.35, 0.7, 0.97)],
                  [1.0, 0.8, 0.5, 0.2], 0.04, "rib")
    bud = ellipsoid("Marker_RightBud", study, (-1.08, -0.2, 2.25), (0.2, 0.2, 0.2), "bud")
    bud.data.materials[0] = mat("bud", emission=1.5)

    # The mouth is CARVED: an exact Boolean difference, its walls taking the cutter's dark material,
    # framed by the brow above, the cheeks at the sides and the jaw below.
    cutter = ellipsoid("MouthCutter", cutters, (0, -1.12, 2.42), (0.44, 0.36, 0.2), "mouth")
    cutter.hide_render = True
    cutter.display_type = "WIRE"
    boolean = head.modifiers.new("MouthCut", "BOOLEAN")
    boolean.operation = "DIFFERENCE"
    boolean.object = cutter
    for attr, value in (("solver", "EXACT"), ("material_mode", "TRANSFER")):
        try:
            setattr(boolean, attr, value)
        except (TypeError, AttributeError):
            pass
    bpy.context.view_layer.update()

    parts = translation_parts()
    doc = {"format": "bca-partlist/1", "space": "roblox-mockup", "units": "studs",
           "note": "Route A translation of the self-test Burrowbud; throwaway, not a species", "parts": parts}
    part_path = L.write_json(doc, os.path.join(out, "partlist_translation.json"))
    B.import_partlist(part_path, "Primitive", 1.0)

    saved = L.save_new_blend(os.path.join(out, "smoke_source.blend"), overwrite=args.overwrite)
    print(f"BCA_SELFTEST_OK study objects {len(study.all_objects)}, primitive parts {len(parts)}, "
          f"body verts {len(body.data.vertices)} -> {saved}")


if __name__ == "__main__":
    main()
