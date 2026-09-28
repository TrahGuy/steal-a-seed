"""Geometry audit for a creature study or an approved custom-mesh candidate. Never saves.

  blender -b source.blend --python mesh_audit.py -- --out DIR
      [--collection NAME] [--studs-per-unit 1.0] [--closed NAME,NAME|all]
      [--budget budget.json] [--self-intersections] [--strict]

Reports, per mesh object as it would export (modifiers applied): triangles, vertices, n-gons,
open (boundary) edges, non-manifold edges, wire edges, loose vertices, degenerate faces,
zero-length edges, duplicate vertices, winding consistency, inward normals (closed meshes),
unapplied/negative scale, UV layers, materials and missing image files; optionally
self-intersections. Scene level: total triangles, bounds in studs and the lowest point.

Watertightness is required only for the objects named in --closed (or every object with
--closed all, or a custom property bca_closed = True). Open surfaces such as leaves and petals
are legitimate and are reported, not failed.

--budget is a JSON file of limits the TEAM derived for this asset -- any of max_tris_total,
max_tris_per_mesh, max_vertices_per_mesh, max_objects, max_materials. The script ships no
performance numbers of its own. The one built-in platform check is the 3D Importer's
per-mesh ceiling, measured in this project at 20,000 triangles (KB/HANDOFF.md, 2026-09-11
and 2026-09-15).

Writes audit.json and audit.txt. Exits 1 with --strict when any ERROR is found.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

import bmesh
import bpy
from mathutils.bvhtree import BVHTree

sys.dont_write_bytecode = True  # never leave __pycache__ inside the repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bca_lib as L  # noqa: E402

IMPORTER_TRIANGLE_CEILING = 20000  # measured: the 3D Importer cut 121,500 -> 19,999 (HANDOFF 2026-09-11)
EPS_AREA = 1e-10
EPS_LEN = 1e-7
EPS_DOUBLE = 1e-5
SELF_INTERSECT_TRI_LIMIT = 60000


def parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="mesh_audit.py")
    p.add_argument("--out", required=True)
    p.add_argument("--collection")
    p.add_argument("--studs-per-unit", type=float, default=1.0)
    p.add_argument("--closed", default="", help="comma-separated object names that must be watertight, or 'all'")
    p.add_argument("--budget")
    p.add_argument("--self-intersections", action="store_true")
    p.add_argument("--strict", action="store_true")
    return L.parse_args(p)


def audit_object(obj, closed_required: bool, check_self: bool, spu: float) -> dict:
    findings: list[tuple[str, str]] = []
    depsgraph = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(depsgraph)
    mesh = ev.to_mesh()
    bm = bmesh.new()
    try:
        bm.from_mesh(mesh)
        bm.verts.ensure_lookup_table()
        bm.faces.ensure_lookup_table()
        tris = sum(len(f.verts) - 2 for f in bm.faces)
        ngons = sum(1 for f in bm.faces if len(f.verts) > 4)
        boundary = sum(1 for e in bm.edges if len(e.link_faces) == 1)
        nonmanifold = sum(1 for e in bm.edges if len(e.link_faces) > 2)
        wire = sum(1 for e in bm.edges if len(e.link_faces) == 0)
        loose = sum(1 for v in bm.verts if not v.link_edges)
        degenerate = sum(1 for f in bm.faces if f.calc_area() < EPS_AREA)
        zero_edges = sum(1 for e in bm.edges if e.calc_length() < EPS_LEN)
        doubles = bmesh.ops.find_doubles(bm, verts=bm.verts, dist=EPS_DOUBLE)["targetmap"]
        before = [f.normal.copy() for f in bm.faces]
        check = bm.copy()
        bmesh.ops.recalc_face_normals(check, faces=check.faces)
        check.faces.ensure_lookup_table()
        flipped = sum(1 for i, f in enumerate(check.faces) if f.normal.dot(before[i]) < 0)
        check.free()
        closed = boundary == 0 and nonmanifold == 0 and len(bm.faces) > 0
        volume = 0.0
        if closed:
            for tri in bm.calc_loop_triangles():
                a, b, c = (loop.vert.co for loop in tri)
                volume += a.dot(b.cross(c)) / 6.0
        self_pairs = None
        if check_self:
            if tris > SELF_INTERSECT_TRI_LIMIT:
                findings.append(("INFO", f"self-intersection check skipped above {SELF_INTERSECT_TRI_LIMIT} triangles"))
            else:
                tree = BVHTree.FromBMesh(bm)
                real = 0
                for i, j in tree.overlap(tree):
                    if i >= j:
                        continue
                    shared = {v.index for v in bm.faces[i].verts} & {v.index for v in bm.faces[j].verts}
                    if not shared:
                        real += 1
                self_pairs = real
        uv_layers = len(mesh.uv_layers)
    finally:
        bm.free()
        ev.to_mesh_clear()

    if any(s < 0 for s in obj.scale):
        findings.append(("ERROR", "negative object scale: exports with flipped normals; apply it and fix the normals"))
    elif any(abs(s - 1.0) > 1e-4 for s in obj.scale):
        findings.append(("WARN", f"unapplied object scale {tuple(round(s, 4) for s in obj.scale)}; apply before export"))
    if degenerate:
        findings.append(("ERROR", f"{degenerate} degenerate (zero-area) faces"))
    if zero_edges:
        findings.append(("ERROR", f"{zero_edges} zero-length edges"))
    if doubles:
        findings.append(("WARN", f"{len(doubles)} duplicate vertices within {EPS_DOUBLE}"))
    if nonmanifold:
        findings.append(("ERROR" if closed_required else "WARN", f"{nonmanifold} non-manifold edges (3+ faces)"))
    if boundary:
        findings.append(("ERROR" if closed_required else "INFO", f"{boundary} open boundary edges"
                         + ("" if closed_required else " (allowed: not required to be closed)")))
    if wire:
        findings.append(("WARN", f"{wire} wire edges with no faces"))
    if loose:
        findings.append(("WARN", f"{loose} loose vertices"))
    if flipped and flipped < len(before):
        if closed:
            findings.append(("ERROR", f"inconsistent winding: {flipped} faces disagree with their neighbours"))
        else:
            # An open surface has no inside, so Blender's recalculation picks a side per island;
            # a whole island facing the other way is not an error, a mixed island is.
            findings.append(("WARN", f"{flipped} faces disagree with the recalculated winding; "
                                     "check the normals overlay (open islands may simply face the other way)"))
    if closed and volume < 0:
        findings.append(("ERROR", "normals point inward (negative enclosed volume)"))
    if self_pairs:
        findings.append(("WARN", f"{self_pairs} self-intersecting face pairs"))
    if tris > IMPORTER_TRIANGLE_CEILING:
        findings.append(("ERROR", f"{tris} triangles: above the 3D Importer's measured per-mesh ceiling of "
                                  f"{IMPORTER_TRIANGLE_CEILING}; the importer would decimate it without asking"))
    return {
        "object": obj.name, "tris": tris, "ngons": ngons, "open_edges": boundary,
        "nonmanifold_edges": nonmanifold, "wire_edges": wire, "loose_verts": loose,
        "degenerate_faces": degenerate, "zero_length_edges": zero_edges,
        "duplicate_verts": len(doubles), "winding_flips": flipped, "closed": closed,
        "closed_required": closed_required,
        "enclosed_volume_studs3": volume * (spu ** 3) if closed else None,
        "self_intersecting_pairs": self_pairs, "uv_layers": uv_layers,
        "object_scale": [round(s, 5) for s in obj.scale],
        "materials": [s.material.name for s in obj.material_slots if s.material],
        "findings": [{"level": lvl, "message": msg} for lvl, msg in findings],
    }


def missing_images(objs) -> list[str]:
    missing = []
    for o in objs:
        for slot in o.material_slots:
            mat = slot.material
            if not (mat and mat.node_tree):
                continue
            for node in mat.node_tree.nodes:
                img = getattr(node, "image", None)
                if img is not None and not img.packed_file:
                    path = bpy.path.abspath(img.filepath)
                    if path and not os.path.exists(path):
                        missing.append(f"{mat.name}: {img.filepath}")
    return missing


def main() -> None:
    args = parse()
    out = L.ensure_out_dir(args.out)
    spu = args.studs_per_unit
    objs = [o for o in L.subject_objects(args.collection) if o.type == "MESH"]
    closed_names = {n.strip() for n in args.closed.split(",") if n.strip()}
    reports = []
    for o in objs:
        need_closed = "all" in closed_names or o.name in closed_names or bool(o.get("bca_closed", False))
        reports.append(audit_object(o, need_closed, args.self_intersections, spu))
    lo, hi = L.world_bounds(objs)
    total_tris = sum(r["tris"] for r in reports)
    materials = sorted({m for r in reports for m in r["materials"]})
    scene_findings: list[dict] = []
    if abs(lo.z) * spu > 0.05:
        scene_findings.append({"level": "WARN", "message": f"lowest point is {lo.z * spu:.3f} studs, not the ground (0)"})
    for m in missing_images(objs):
        scene_findings.append({"level": "ERROR", "message": f"missing image file: {m}"})
    budget = {}
    if args.budget:
        with open(args.budget, encoding="utf-8") as handle:
            budget = json.load(handle)
        actuals = {
            "max_tris_total": total_tris,
            "max_objects": len(reports),
            "max_materials": len(materials),
            "max_tris_per_mesh": max((r["tris"] for r in reports), default=0),
        }
        for key, actual in actuals.items():
            if key in budget and actual > budget[key]:
                scene_findings.append({"level": "ERROR", "message": f"{key}: {actual} > budget {budget[key]}"})
    result = {
        "blend": bpy.data.filepath, "blender": bpy.app.version_string, "studs_per_unit": spu,
        "objects": reports, "total_tris": total_tris, "object_count": len(reports), "materials": materials,
        "bounds_studs": {"min": [c * spu for c in lo], "max": [c * spu for c in hi],
                         "size": [(h - l) * spu for l, h in zip(lo, hi)]},
        "budget_file": args.budget, "budget": budget, "scene_findings": scene_findings,
        "importer_triangle_ceiling_per_mesh": IMPORTER_TRIANGLE_CEILING,
    }
    L.write_json(result, os.path.join(out, "audit.json"))
    lines = [f"mesh_audit  {bpy.data.filepath}  (Blender {bpy.app.version_string})",
             f"objects {len(reports)}  triangles {total_tris}  materials {len(materials)}",
             "size (studs) " + " x ".join(f"{v:.2f}" for v in result["bounds_studs"]["size"])
             + f"  lowest point {lo.z * spu:.3f}"]
    errors = 0
    for r in reports:
        lines.append(f"- {r['object']}: {r['tris']} tris, closed={r['closed']}"
                     + (" (required)" if r["closed_required"] else ""))
        for f in r["findings"]:
            lines.append(f"    {f['level']}: {f['message']}")
            errors += f["level"] == "ERROR"
    for f in scene_findings:
        lines.append(f"  {f['level']}: {f['message']}")
        errors += f["level"] == "ERROR"
    lines.append(f"errors {errors}")
    with open(os.path.join(out, "audit.txt"), "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    print("\n".join(lines))
    print("BCA_AUDIT_OK" if errors == 0 else "BCA_AUDIT_ERRORS", errors)
    if args.strict and errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
