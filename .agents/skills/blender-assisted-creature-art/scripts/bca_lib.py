"""Shared helpers for the blender-assisted-creature-art scripts.

Runs inside Blender (verified on Blender 5.2.0 LTS). Uses only bpy, bmesh, mathutils and
the numpy that ships with Blender.

House rules every script follows:
  * arguments come after a bare `--` on the Blender command line;
  * output goes only under the folder given by --out, never into a Rojo `src/` tree;
  * an existing .blend is never saved over (review/audit scripts never save at all);
  * helper objects the scripts add are named with the BCA_ prefix and ignored by audits.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

HELPER_PREFIX = "BCA_"
SUBJECT_TYPES = {"MESH", "CURVE", "SURFACE", "META", "FONT"}

# ----------------------------------------------------------------------------------- arguments


def script_argv() -> list[str]:
    argv = sys.argv
    return argv[argv.index("--") + 1:] if "--" in argv else []


def parse_args(parser: argparse.ArgumentParser) -> argparse.Namespace:
    return parser.parse_args(script_argv())


# ------------------------------------------------------------------------------ output safety


def ensure_out_dir(path: str) -> str:
    """Create `path` and return it absolute; refuse any folder inside a Rojo project's src/."""
    target = os.path.abspath(path)
    probe = target
    while True:
        if os.path.isfile(os.path.join(probe, "default.project.json")):
            src = os.path.join(probe, "src")
            if target == src or target.startswith(src + os.sep):
                raise SystemExit(f"refusing to write into a Rojo source tree: {target}")
        parent = os.path.dirname(probe)
        if parent == probe:
            break
        probe = parent
    os.makedirs(target, exist_ok=True)
    return target


def save_new_blend(path: str, overwrite: bool = False) -> str:
    """Save the current session as a NEW .blend. Refuses to replace an existing file unless
    `overwrite` is set, which callers only pass for files inside their own --out folder."""
    target = os.path.abspath(path)
    if not target.lower().endswith(".blend"):
        raise SystemExit(f"expected a .blend path, got {target}")
    ensure_out_dir(os.path.dirname(target))
    if os.path.exists(target) and not overwrite:
        raise SystemExit(f"refusing to overwrite an existing .blend: {target}")
    bpy.ops.wm.save_as_mainfile(filepath=target, check_existing=False, compress=True)
    return target


def write_json(data, path: str) -> str:
    ensure_out_dir(os.path.dirname(os.path.abspath(path)))
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=1, default=str)
    return path


# ------------------------------------------------------------------------- axes and units
#
# Roblox: Y up; an unrotated part looks down -Z (its LookVector) and +X is its right.
# Blender, in this skill: Z up; the creature faces -Y (toward Blender's Front view) and its
# right-hand side is -X.
#
# The change of basis is the PROPER rotation  Roblox (x, y, z) -> Blender (-x, z, y).
# It is its own inverse. Swapping two axes instead -- (x, y, z) -> (x, z, y) -- is a mirror
# (determinant -1): symmetric forms survive it, but every asymmetric detail lands on the
# wrong side.

R2B = Matrix(((-1.0, 0.0, 0.0, 0.0),
              (0.0, 0.0, 1.0, 0.0),
              (0.0, 1.0, 0.0, 0.0),
              (0.0, 0.0, 0.0, 1.0)))
B2R = R2B.copy()  # its own inverse


def roblox_to_blender_vec(v) -> Vector:
    return Vector((-v[0], v[2], v[1]))


def blender_to_roblox_vec(v) -> Vector:
    return Vector((-v[0], v[2], v[1]))


def cframe_to_matrix(components) -> Matrix:
    """CFrame:GetComponents() order: x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22."""
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = components
    return Matrix(((r00, r01, r02, x), (r10, r11, r12, y), (r20, r21, r22, z), (0, 0, 0, 1)))


def matrix_to_cframe(m: Matrix) -> list[float]:
    return [m[0][3], m[1][3], m[2][3],
            m[0][0], m[0][1], m[0][2],
            m[1][0], m[1][1], m[1][2],
            m[2][0], m[2][1], m[2][2]]


def srgb_to_linear(c: float) -> float:
    c = max(0.0, min(1.0, c))
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgb255_to_linear(rgb) -> tuple[float, float, float, float]:
    return (srgb_to_linear(rgb[0] / 255), srgb_to_linear(rgb[1] / 255), srgb_to_linear(rgb[2] / 255), 1.0)


# ---------------------------------------------------------------------------- scene queries


def subject_objects(collection: str | None = None) -> list[bpy.types.Object]:
    """The objects under review: a named collection's, or every visible renderable object that is
    not a BCA_ helper."""
    if collection:
        coll = bpy.data.collections.get(collection)
        if coll is None:
            raise SystemExit(f"no collection named {collection!r}")
        objs = list(coll.all_objects)
    else:
        objs = list(bpy.context.scene.objects)
    return [o for o in objs
            if o.type in SUBJECT_TYPES and not o.name.startswith(HELPER_PREFIX)
            and not o.hide_render and o.visible_get()]


def world_bounds(objs) -> tuple[Vector, Vector]:
    """World AABB of the objects' evaluated bounding boxes."""
    lo = Vector((math.inf,) * 3)
    hi = Vector((-math.inf,) * 3)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        ev = o.evaluated_get(depsgraph)
        for corner in ev.bound_box:
            w = ev.matrix_world @ Vector(corner)
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
    if lo.x == math.inf:
        raise SystemExit("nothing to measure: no subject objects")
    return lo, hi


def evaluated_mesh_stats(obj) -> dict:
    """Triangle and vertex counts of the object as it would export (modifiers applied)."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(depsgraph)
    mesh = ev.to_mesh()
    try:
        mesh.calc_loop_triangles()
        return {"verts": len(mesh.vertices), "faces": len(mesh.polygons), "tris": len(mesh.loop_triangles)}
    finally:
        ev.to_mesh_clear()


# ------------------------------------------------------------------------------ mesh helpers


def mesh_object(name: str, bm: bmesh.types.BMesh, collection=None) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    (collection or bpy.context.scene.collection).objects.link(obj)
    return obj


def box_bmesh(size, center=(0.0, 0.0, 0.0)) -> bmesh.types.BMesh:
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0] + center[0], v.co.y * size[1] + center[1], v.co.z * size[2] + center[2]))
    return bm


def flat_material(name: str, rgb255, emission: float = 0.0, roughness: float = 0.6) -> bpy.types.Material:
    """A Principled material whose viewport colour matches, so Workbench MATERIAL mode and EEVEE
    agree. Blender 5.x materials always use nodes (setting use_nodes = False is ignored)."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    lin = rgb255_to_linear(rgb255)
    mat.diffuse_color = lin
    bsdf = mat.node_tree.nodes.get("Principled BSDF") if mat.node_tree else None
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = lin
        bsdf.inputs["Roughness"].default_value = roughness
        if emission > 0:
            bsdf.inputs["Emission Color"].default_value = lin
            bsdf.inputs["Emission Strength"].default_value = emission
    return mat


# --------------------------------------------------------------------------- the scale figure


def add_scale_figure(height_studs: float, studs_per_unit: float, at: Vector) -> bpy.types.Object:
    """A plain blocky 5-stud avatar stand-in (legs 2, torso 2, head 1 at the default height),
    standing on z = 0 at `at`. Not a Roblox character, only a size reference."""
    k = (height_studs / 5.0) / studs_per_unit
    bm = bmesh.new()
    parts = [
        ((0.9, 0.9, 2.0), (-0.5, 0.0, 1.0)),   # legs
        ((0.9, 0.9, 2.0), (0.5, 0.0, 1.0)),
        ((2.0, 1.0, 2.0), (0.0, 0.0, 3.0)),    # torso
        ((0.9, 0.9, 2.0), (-1.5, 0.0, 3.0)),   # arms
        ((0.9, 0.9, 2.0), (1.5, 0.0, 3.0)),
        ((1.1, 1.1, 1.0), (0.0, 0.0, 4.5)),    # head
    ]
    for size, center in parts:
        part = box_bmesh([s * k for s in size], [c * k for c in center])
        tmp = bpy.data.meshes.new("tmp")
        part.to_mesh(tmp)
        part.free()
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
    obj = mesh_object(HELPER_PREFIX + "ScaleFigure", bm)
    obj.location = at
    return obj


def add_ground(size: float) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=size / 2)
    return mesh_object(HELPER_PREFIX + "Ground", bm)


# ------------------------------------------------------------------------------ cameras


def add_camera(name: str, location: Vector, target: Vector, ortho_scale: float | None = None,
               vertical_fov_deg: float | None = None, top_down: bool = False) -> bpy.types.Object:
    data = bpy.data.cameras.new(HELPER_PREFIX + name)
    cam = bpy.data.objects.new(HELPER_PREFIX + name, data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = location
    if top_down:
        cam.rotation_euler = (0.0, 0.0, 0.0)  # looks down -Z; image top is +Y (the creature's rear)
    else:
        cam.rotation_euler = (target - location).to_track_quat("-Z", "Y").to_euler()
    if ortho_scale is not None:
        data.type = "ORTHO"
        data.ortho_scale = ortho_scale
    else:
        data.type = "PERSP"
        data.sensor_fit = "VERTICAL"
        data.angle_y = math.radians(vertical_fov_deg or 40.0)
    data.clip_start = 0.01
    data.clip_end = 10000.0
    return cam


def render_still(camera, path: str, resolution: tuple[int, int]) -> str:
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


# ------------------------------------------------------------------- images and contact sheets


def load_rgba(path: str) -> np.ndarray:
    """(h, w, 4) float32, rows top to bottom."""
    img = bpy.data.images.load(path, check_existing=False)
    try:
        w, h = img.size
        arr = np.empty(w * h * 4, dtype=np.float32)
        img.pixels.foreach_get(arr)
    finally:
        bpy.data.images.remove(img)
    return arr.reshape(h, w, 4)[::-1].copy()


def save_rgba(arr: np.ndarray, path: str) -> str:
    h, w, _ = arr.shape
    img = bpy.data.images.new("BCA_sheet", w, h, alpha=True)
    try:
        img.pixels.foreach_set(np.ascontiguousarray(arr[::-1], dtype=np.float32).ravel())
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
    finally:
        bpy.data.images.remove(img)
    return path


def over_background(rgba: np.ndarray, bg=(1.0, 1.0, 1.0)) -> np.ndarray:
    out = rgba.copy()
    a = rgba[..., 3:4]
    out[..., :3] = rgba[..., :3] * a + np.array(bg, dtype=np.float32) * (1.0 - a)
    out[..., 3] = 1.0
    return out


def alpha_mask(path: str, threshold: float = 0.5) -> np.ndarray:
    return load_rgba(path)[..., 3] >= threshold


# 5 x 7 bitmap glyphs for labels; lower case is drawn as upper case, unknown characters as blanks.
_GLYPHS = {
    "A": ".###.#...##...#######...##...##...#", "B": "####.#...##...#####.#...##...#####.",
    "C": ".#####....#....#....#....#.....####", "D": "####.#...##...##...##...##...#####.",
    "E": "######....#....####.#....#....#####", "F": "######....#....####.#....#....#....",
    "G": ".#####....#....#.####...##...#.####", "H": "#...##...##...#######...##...##...#",
    "I": "#####..#....#....#....#....#..#####", "J": "..###...#....#....#....##..#..##...",
    "K": "#...##..#.#.#..##...#.#..#..#.#...#", "L": "#....#....#....#....#....#....#####",
    "M": "#...###.###.#.##.#.##...##...##...#", "N": "#...###..##.#.##..###...##...##...#",
    "O": ".###.#...##...##...##...##...#.###.", "P": "####.#...##...#####.#....#....#....",
    "Q": ".###.#...##...##...##.#.##..#..##.#", "R": "####.#...##...#####.#.#..#..#.#...#",
    "S": ".#####....#.....###.....#....#####.", "T": "#####..#....#....#....#....#....#..",
    "U": "#...##...##...##...##...##...#.###.", "V": "#...##...##...##...##...#.#.#...#..",
    "W": "#...##...##...##.#.##.#.###.###...#", "X": "#...##...#.#.#...#...#.#.#...##...#",
    "Y": "#...##...#.#.#...#....#....#....#..", "Z": "#####....#...#...#...#...#....#####",
    "0": ".###.#...##..###.#.###..##...#.###.", "1": "..#...##....#....#....#....#...###.",
    "2": ".###.#...#....#...#...#...#...#####", "3": "####.....#....#.###.....#....#####.",
    "4": "...#...##..#.#.#..#.#####...#....#.", "5": "######....####.....#....##...#.###.",
    "6": ".###.#....#....####.#...##...#.###.", "7": "#####....#...#...#...#....#....#...",
    "8": ".###.#...##...#.###.#...##...#.###.", "9": ".###.#...##...#.####....#....#.###.",
    " ": "...................................", "-": "...............#####...............",
    "/": "....#....#...#...#...#...#....#....", ":": "......#....#.........#....#........",
    ".": ".........................##...##...", "(": "...#...#...#....#....#.....#.....#.",
    ")": ".#.....#.....#....#....#...#...#...", "%": "##..###..#...#...#...#...#..###..##",
    "=": "..........#####.....#####..........", "+": "......#....#..#####..#....#........",
    ",": "....................##....#...#....", "#": ".#.#.#####.#.#.#####.#.#...........",
}


def draw_text(canvas: np.ndarray, text: str, x: int, y: int, scale: int = 2, color=(0.0, 0.0, 0.0)) -> int:
    """Draw `text` with its top-left at (x, y) on a (h, w, 4) top-to-bottom canvas. Returns the
    x after the last glyph."""
    h, w, _ = canvas.shape
    col = np.array((*color, 1.0), dtype=np.float32)
    for ch in text.upper():
        rows = _GLYPHS.get(ch, _GLYPHS[" "])
        for r in range(7):
            for c in range(5):
                if rows[r * 5 + c] == "#":
                    y0, x0 = y + r * scale, x + c * scale
                    if 0 <= y0 < h - scale and 0 <= x0 < w - scale:
                        canvas[y0:y0 + scale, x0:x0 + scale] = col
        x += 6 * scale
    return x


def contact_sheet(rows: list[list[tuple[str, str]]], path: str, title: str = "",
                  bg=(1.0, 1.0, 1.0), label_scale: int = 2, pad: int = 12) -> str:
    """rows: [[(label, png_path), ...], ...]. Tiles keep their own pixel size -- nothing is
    rescaled, so a gameplay-size tile shows the real on-screen size."""
    label_h = 7 * label_scale + 8
    title_h = (7 * 3 + 16) if title else 0
    loaded = [[(label, over_background(load_rgba(p), bg)) for label, p in row] for row in rows]
    width = max(sum(t.shape[1] for _, t in row) + pad * (len(row) + 1) for row in loaded)
    height = title_h + sum(max(t.shape[0] for _, t in row) + label_h + pad for row in loaded) + pad
    sheet = np.ones((height, width, 4), dtype=np.float32)
    sheet[..., :3] = np.array(bg, dtype=np.float32)
    y = pad
    if title:
        draw_text(sheet, title, pad, y, scale=3)
        y += title_h
    for row in loaded:
        x = pad
        row_h = max(t.shape[0] for _, t in row)
        for label, tile in row:
            draw_text(sheet, label, x, y, scale=label_scale)
            th, tw, _ = tile.shape
            sheet[y + label_h:y + label_h + th, x:x + tw] = tile
            # a hairline frame, so a white render on a white sheet still has an edge
            sheet[y + label_h, x:x + tw, :3] = 0.8
            sheet[y + label_h + th - 1, x:x + tw, :3] = 0.8
            sheet[y + label_h:y + label_h + th, x, :3] = 0.8
            sheet[y + label_h:y + label_h + th, x + tw - 1, :3] = 0.8
            x += tw + pad
        y += row_h + label_h + pad
    return save_rgba(sheet, path)
