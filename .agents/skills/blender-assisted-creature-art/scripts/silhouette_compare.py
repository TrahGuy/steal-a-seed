"""Route A fidelity check: how much of a smooth study a primitive translation really covers.

  blender -b study.blend --python silhouette_compare.py -- --a Study --b Primitive --out DIR
      [--views front,right,three_quarter,top] [--view-res 384] [--title TEXT]

Both collections are rendered as black silhouettes from IDENTICAL cameras framed on their
combined bounds. Per view the report gives IoU (intersection over union), the share of the
study the translation misses ("lost") and the share of the translation outside the study
("added"), and an overlay: grey = both, red = study only (lost), blue = translation only
(added). A translation is never "the same shape"; these numbers and the overlay ARE the
fidelity tradeoff to show the owner. Silhouettes say nothing about faces, colour or surface.

Writes fidelity.json, overlay_<view>.png and sheet_fidelity.png. Never saves the .blend.
"""
from __future__ import annotations

import argparse
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

sys.dont_write_bytecode = True  # never leave __pycache__ inside the repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bca_lib as L  # noqa: E402

BOTH = (0.35, 0.35, 0.35)
LOST = (0.85, 0.15, 0.15)
ADDED = (0.15, 0.35, 0.90)


def parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="silhouette_compare.py")
    p.add_argument("--a", required=True, help="collection of the reference study")
    p.add_argument("--b", required=True, help="collection of the primitive translation")
    p.add_argument("--out", required=True)
    p.add_argument("--views", default="front,right,three_quarter,top")
    p.add_argument("--view-res", type=int, default=384)
    p.add_argument("--title", default="")
    return L.parse_args(p)


def main() -> None:
    args = parse()
    out = L.ensure_out_dir(args.out)
    scene = bpy.context.scene
    a_objs, b_objs = L.subject_objects(args.a), L.subject_objects(args.b)
    if not a_objs or not b_objs:
        raise SystemExit("both collections need renderable objects")
    lo_a, hi_a = L.world_bounds(a_objs)
    lo_b, hi_b = L.world_bounds(b_objs)
    lo = Vector((min(lo_a.x, lo_b.x), min(lo_a.y, lo_b.y), min(lo_a.z, lo_b.z)))
    hi = Vector((max(hi_a.x, hi_b.x), max(hi_a.y, hi_b.y), max(hi_a.z, hi_b.z)))
    size = hi - lo
    mid = (lo + hi) / 2
    biggest = max(size)
    far = biggest * 6 + 10
    ortho = biggest * 1.25
    yaw = math.radians(35)
    dist = (biggest * 0.62) / math.tan(math.radians(15)) + biggest * 0.5
    cams = {
        "front": L.add_camera("CmpFront", mid + Vector((0, -far, 0)), mid, ortho_scale=ortho),
        "right": L.add_camera("CmpRight", mid + Vector((-far, 0, 0)), mid, ortho_scale=ortho),
        "rear": L.add_camera("CmpRear", mid + Vector((0, far, 0)), mid, ortho_scale=ortho),
        "top": L.add_camera("CmpTop", mid + Vector((0, 0, far)), mid, ortho_scale=ortho, top_down=True),
        "three_quarter": L.add_camera("Cmp34", mid + Vector((-math.sin(yaw), -math.cos(yaw), 0.35)).normalized() * dist,
                                      mid, vertical_fov_deg=30),
    }
    views = [v.strip() for v in args.views.split(",") if v.strip()]
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.light, sh.color_type, sh.single_color = "FLAT", "SINGLE", (0.0, 0.0, 0.0)
    sh.show_cavity = sh.show_object_outline = sh.show_shadows = False
    scene.display.render_aa = "8"

    everything = [o for o in scene.objects if o.type in L.SUBJECT_TYPES]
    saved = {o.name: o.hide_render for o in everything}

    def render_set(objs, path, cam):
        keep = {o.name for o in objs}
        for o in everything:
            o.hide_render = o.name not in keep
        L.render_still(cam, path, (args.view_res, args.view_res))
        return L.alpha_mask(path)

    results, rows = {}, []
    try:
        for view in views:
            if view not in cams:
                raise SystemExit(f"unknown view {view!r}")
            ma = render_set(a_objs, os.path.join(out, f"a_{view}.png"), cams[view])
            mb = render_set(b_objs, os.path.join(out, f"b_{view}.png"), cams[view])
            inter, union = np.logical_and(ma, mb).sum(), np.logical_or(ma, mb).sum()
            lost, added = np.logical_and(ma, ~mb).sum(), np.logical_and(mb, ~ma).sum()
            results[view] = {
                "iou": float(inter / union) if union else None,
                "lost_share_of_study": float(lost / ma.sum()) if ma.sum() else None,
                "added_share_of_translation": float(added / mb.sum()) if mb.sum() else None,
                "study_pixels": int(ma.sum()), "translation_pixels": int(mb.sum()),
            }
            img = np.ones((*ma.shape, 4), dtype=np.float32)
            img[np.logical_and(ma, mb), :3] = BOTH
            img[np.logical_and(ma, ~mb), :3] = LOST
            img[np.logical_and(mb, ~ma), :3] = ADDED
            path = os.path.join(out, f"overlay_{view}.png")
            L.save_rgba(img, path)
            r = results[view]
            rows.append((f"{view.replace('_', ' ').upper()} IOU {r['iou']:.2f}", path))
    finally:
        for o in everything:
            o.hide_render = saved[o.name]

    title = (args.title + "  " if args.title else "") + "GREY BOTH  RED STUDY ONLY  BLUE PRIMITIVES ONLY"
    sheet = L.contact_sheet([rows], os.path.join(out, "sheet_fidelity.png"), title=title)
    L.write_json({"study": args.a, "translation": args.b, "blender": bpy.app.version_string,
                  "study_objects": [o.name for o in a_objs], "translation_objects": [o.name for o in b_objs],
                  "views": results, "sheet": sheet}, os.path.join(out, "fidelity.json"))
    for view, r in results.items():
        print(f"{view}: IoU {r['iou']:.3f}  lost {r['lost_share_of_study']:.3f}  added {r['added_share_of_translation']:.3f}")
    print("BCA_FIDELITY_OK", os.path.join(out, "fidelity.json"))


if __name__ == "__main__":
    main()
