"""Standard approval renders for a creature study: plain form, black silhouette and colour.

Open the study read-only and render it; this script never saves the .blend:

  blender -b study.blend --python review_renders.py -- --out DIR
      [--collection NAME] [--passes plain,silhouette,color] [--studs-per-unit 1.0]
      [--view-res 384] [--game-distance 30] [--game-pitch 20] [--game-yaw 35]
      [--game-fov 70] [--game-res 704x338] [--figure-height 5] [--title TEXT]

Conventions (see references/blender-environment.md): 1 Blender unit = --studs-per-unit studs,
the creature faces -Y, its right is -X, the ground is z = 0.

Writes into DIR: one PNG per pass and view, sheet_<pass>.png contact sheets, and
review_manifest.json with the measured dimensions, the camera set-up and every file written.
The gameplay tile is rendered at --game-res and never rescaled, so it shows the real
on-screen size at that distance and field of view.
"""
from __future__ import annotations

import argparse
import math
import os
import sys

import bpy
from mathutils import Vector

sys.dont_write_bytecode = True  # never leave __pycache__ inside the repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bca_lib as L  # noqa: E402

PLAIN_GREY = (0.72, 0.72, 0.72, 1.0)
GROUND_TONE = (0.88, 0.88, 0.84, 1.0)
FIGURE_BLUE = (0.30, 0.45, 0.85, 1.0)


def parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="review_renders.py")
    p.add_argument("--out", required=True)
    p.add_argument("--collection")
    p.add_argument("--passes", default="plain,silhouette,color")
    p.add_argument("--studs-per-unit", type=float, default=1.0)
    p.add_argument("--view-res", type=int, default=384)
    p.add_argument("--game-distance", type=float, default=30.0, help="studs from camera to the creature's centre")
    p.add_argument("--game-pitch", type=float, default=20.0, help="degrees the camera looks down")
    p.add_argument("--game-yaw", type=float, default=35.0, help="degrees from the creature's front toward its right")
    p.add_argument("--game-fov", type=float, default=70.0, help="vertical field of view; Roblox's Camera.FieldOfView")
    p.add_argument("--game-res", default="704x338", help="the viewport measured on the owner's emulated phone")
    p.add_argument("--figure-height", type=float, default=5.0, help="studs; a size stand-in, not an avatar")
    p.add_argument("--title", default="")
    return L.parse_args(p)


def configure_plain(scene):
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.light = "STUDIO"
    sh.color_type = "OBJECT"
    sh.show_cavity = True
    sh.cavity_type = "BOTH"
    sh.show_object_outline = True
    sh.object_outline_color = (0.05, 0.05, 0.05)
    sh.show_shadows = False
    scene.display.render_aa = "8"


def configure_silhouette(scene):
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.light = "FLAT"
    sh.color_type = "SINGLE"
    sh.single_color = (0.0, 0.0, 0.0)
    sh.show_cavity = False
    sh.show_object_outline = False
    sh.show_shadows = False
    scene.display.render_aa = "8"


def configure_color(scene, sun):
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = 16
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    world = scene.world or bpy.data.worlds.new("BCA_World")
    scene.world = world
    bg = world.node_tree.nodes.get("Background") if world.node_tree else None
    if bg is not None:
        bg.inputs["Color"].default_value = (0.55, 0.58, 0.62, 1.0)
        bg.inputs["Strength"].default_value = 1.0
    sun.hide_render = False


def main() -> None:
    args = parse()
    out = L.ensure_out_dir(args.out)
    spu = args.studs_per_unit
    passes = [p.strip() for p in args.passes.split(",") if p.strip()]
    scene = bpy.context.scene

    subject = L.subject_objects(args.collection)
    lo, hi = L.world_bounds(subject)
    size = hi - lo
    centre = (lo + hi) / 2
    biggest = max(size.x, size.y, size.z)

    # Large enough to read as a floor to the horizon in the gameplay view, not a floating tile.
    ground = L.add_ground(max(biggest * 8, args.game_distance / spu * 8))
    ground.color = GROUND_TONE
    ground.data.materials.append(L.flat_material("BCA_GroundMat", (224, 224, 214), roughness=0.9))
    fig_height_bu = args.figure_height / spu
    fig_width_bu = 4.0 * (args.figure_height / 5.0) / spu
    fig_at = Vector((hi.x + biggest * 0.15 + fig_width_bu / 2, centre.y, 0.0))
    figure = L.add_scale_figure(args.figure_height, spu, fig_at)
    figure.color = FIGURE_BLUE
    figure.data.materials.append(L.flat_material("BCA_FigureMat", (80, 120, 220)))
    sun_data = bpy.data.lights.new("BCA_Sun", type="SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("BCA_Sun", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50), 0.0, math.radians(35))
    sun.hide_render = True

    # Every orthographic view shares one scale, so the views compare 1:1.
    ortho = biggest * 1.25
    far = biggest * 6 + 10
    mid = Vector((centre.x, centre.y, centre.z))
    persp_dist = (biggest * 0.62) / math.tan(math.radians(15)) + biggest * 0.5
    yaw = math.radians(35)
    three_quarter = mid + Vector((-math.sin(yaw), -math.cos(yaw), 0.35)).normalized() * persp_dist
    scale_lo_x = lo.x
    scale_hi_x = fig_at.x + fig_width_bu / 2
    scale_mid = Vector(((scale_lo_x + scale_hi_x) / 2, centre.y, max(hi.z, fig_height_bu) / 2))
    scale_ortho = max(scale_hi_x - scale_lo_x, max(hi.z, fig_height_bu)) * 1.2

    gd = args.game_distance / spu
    gp, gy = math.radians(args.game_pitch), math.radians(args.game_yaw)
    game_loc = mid + Vector((-math.sin(gy) * math.cos(gp), -math.cos(gy) * math.cos(gp), math.sin(gp))) * gd
    gw, gh = (int(v) for v in args.game_res.lower().split("x"))

    cams = {
        "front": L.add_camera("CamFront", mid + Vector((0, -far, 0)), mid, ortho_scale=ortho),
        "right": L.add_camera("CamRight", mid + Vector((-far, 0, 0)), mid, ortho_scale=ortho),
        "rear": L.add_camera("CamRear", mid + Vector((0, far, 0)), mid, ortho_scale=ortho),
        "top": L.add_camera("CamTop", mid + Vector((0, 0, far)), mid, ortho_scale=ortho, top_down=True),
        "three_quarter": L.add_camera("Cam34", three_quarter, mid, vertical_fov_deg=30),
        "scale": L.add_camera("CamScale", scale_mid + Vector((0, -far, 0)), scale_mid, ortho_scale=scale_ortho),
        "gameplay": L.add_camera("CamGame", game_loc, mid, vertical_fov_deg=args.game_fov),
    }
    labels = {
        "front": "FRONT", "right": "RIGHT SIDE", "rear": "REAR", "top": "TOP (FRONT DOWN)",
        "three_quarter": "3/4 FRONT-RIGHT",
        "scale": f"SCALE: {args.figure_height:g}-STUD FIGURE",
        "gameplay": f"GAMEPLAY {args.game_distance:g} STUDS FOV {args.game_fov:g} {gw}X{gh}",
    }
    views_for = {
        "plain": ["front", "right", "rear", "three_quarter", "top", "scale", "gameplay"],
        "silhouette": ["front", "right", "three_quarter", "top"],
        "color": ["front", "three_quarter", "gameplay"],
    }

    saved_colors = {o.name: tuple(o.color) for o in subject}
    # Only the subject is rendered: another collection standing in the same place (a Route A
    # translation, a reference import) would otherwise z-fight through it. Restored afterwards.
    helpers = {ground.name, figure.name}
    others = [o for o in scene.objects if o.type in L.SUBJECT_TYPES
              and o not in subject and o.name not in helpers]
    saved_hidden = {o.name: o.hide_render for o in others}
    for o in others:
        o.hide_render = True
    written: dict[str, dict[str, str]] = {}
    try:
        for pas in passes:
            if pas not in views_for:
                raise SystemExit(f"unknown pass {pas!r}; use plain, silhouette or color")
            if pas == "plain":
                configure_plain(scene)
                for o in subject:
                    o.color = PLAIN_GREY
            elif pas == "silhouette":
                configure_silhouette(scene)
            else:
                configure_color(scene, sun)
            ground.hide_render = pas == "silhouette"
            written[pas] = {}
            for view in views_for[pas]:
                figure.hide_render = view != "scale"
                res = (gw, gh) if view == "gameplay" else (args.view_res, args.view_res)
                path = os.path.join(out, f"{pas}_{view}.png")
                L.render_still(cams[view], path, res)
                written[pas][view] = path
            sun.hide_render = True
            rows = [[(labels[v], written[pas][v]) for v in views_for[pas] if v != "gameplay"]]
            if "gameplay" in written[pas]:
                rows.append([(labels["gameplay"], written[pas]["gameplay"])])
            sheet = os.path.join(out, f"sheet_{pas}.png")
            title = (args.title + "  " if args.title else "") + pas.upper() + " PASS"
            L.contact_sheet(rows, sheet, title=title)
            written[pas]["sheet"] = sheet
    finally:
        for o in subject:
            o.color = saved_colors[o.name]
        for o in others:
            o.hide_render = saved_hidden[o.name]

    manifest = {
        "blend": bpy.data.filepath,
        "blender": bpy.app.version_string,
        "studs_per_unit": spu,
        "subjects": [o.name for o in subject],
        "dimensions_studs": {"width_x": size.x * spu, "depth_y": size.y * spu, "height_z": size.z * spu},
        "lowest_point_studs": lo.z * spu,
        "highest_point_studs": hi.z * spu,
        "ground_contact_note": "lowest point should be ~0 when the origin is the ground base",
        "orthographic_scale_bu": ortho,
        "gameplay_camera": {"distance_studs": args.game_distance, "pitch_deg": args.game_pitch,
                            "yaw_deg": args.game_yaw, "fov_deg": args.game_fov, "res": [gw, gh]},
        "files": written,
    }
    L.write_json(manifest, os.path.join(out, "review_manifest.json"))
    print("BCA_REVIEW_OK", os.path.join(out, "review_manifest.json"))


if __name__ == "__main__":
    main()
