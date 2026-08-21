"""Builds the Greenhollow nest parent in Blender, to KB/biome1-parent-ortho.png.

    blender --background --python tools/blender/parent_biome1.py -- --render
    blender --background --python tools/blender/parent_biome1.py -- --export

WHY BLENDER AND NOT ROBLOX PARTS
    The five little creatures translate to Roblox primitives because they ARE
    primitives -- a cube on a stem, a ball under a flower. The parent is a
    faceted organic sculpt, and 87 boxes approximating it looked like 87 boxes.
    Here it gets mirror symmetry, subdivision, bevels and real proportions, and
    ships as one mesh well under Roblox's 10,000 triangle limit.

WHY WORKBENCH FOR PREVIEWS
    It shades flat from material colour, needs no GPU, and renders in a second.
    That makes the preview a fair picture of the result rather than a prettier
    one, and it is what makes iterating on this possible at all.

PROPORTIONS are measured off the orthographic sheet -- fractions of total
height, feet at 0, mane tip at 1:

    0.00 - 0.33   legs, short and thick, wide stance
    0.33 - 0.57   torso: bark trunk under green plates
    0.56          shoulders
    0.56 - 0.20   arms, hanging nearly to the knee
    0.58 - 0.83   head, jutting forward
    0.68 - 1.00   mane

The legs being only a THIRD is what makes the silhouette squat rather than
humanoid. It is the number two earlier Roblox builds got wrong.
"""
import bpy
import bmesh
import math
from mathutils import Vector
import os
import sys
import random

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)

H = 10.0  # working height in Blender units; Roblox scale is set on import

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
DO_RENDER = "--render" in argv or not argv
DO_EXPORT = "--export" in argv

random.seed(20260821)

# ---------------------------------------------------------------- materials
PALETTE = {
    "bark":      (0.145, 0.105, 0.062),
    "bark_dark": (0.092, 0.068, 0.042),
    "flesh":     (0.235, 0.300, 0.072),
    "flesh_lit": (0.330, 0.400, 0.110),
    "mane":      (0.150, 0.240, 0.070),
    "mane_dark": (0.095, 0.165, 0.052),
    "thorn":     (0.560, 0.290, 0.230),
    "tooth":     (0.880, 0.855, 0.760),
    "eye":       (0.700, 0.120, 0.110),
    "claw":      (0.420, 0.480, 0.170),
    "maw":       (0.180, 0.045, 0.050),
}


def setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats = {}
    for name, rgb in PALETTE.items():
        m = bpy.data.materials.new(name)
        m.use_nodes = False
        m.diffuse_color = (*rgb, 1.0)
        m.roughness = 0.85
        mats[name] = m
    return mats


MATS = setup()


# ---------------------------------------------------------------- helpers
def shade_flat(ob):
    for p in ob.data.polygons:
        p.use_smooth = False


def roughen(ob, amount, seed=0):
    """Nudge every vertex a little. This is what turns a primitive into
    something that reads as carved rather than as a box -- the reference is all
    irregular facets, and a perfectly regular cube never looks organic however
    well it is proportioned."""
    rng = random.Random(seed)
    me = ob.data
    for v in me.vertices:
        v.co.x += rng.uniform(-amount, amount)
        v.co.y += rng.uniform(-amount, amount)
        v.co.z += rng.uniform(-amount, amount)


def block(name, loc, size, material, rot=(0, 0, 0), rough=0.0, seed=0, subdiv=0):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    if subdiv:
        m = ob.modifiers.new("sub", "SUBSURF")
        m.levels = subdiv
        m.render_levels = subdiv
        bpy.ops.object.modifier_apply(modifier=m.name)
    if rough:
        roughen(ob, rough, seed)
    ob.data.materials.append(MATS[material])
    shade_flat(ob)
    return ob


def blob(name, loc, size, material, rough=0.0, seed=0, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(location=loc, subdivisions=subdivisions)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    if rough:
        roughen(ob, rough, seed)
    ob.data.materials.append(MATS[material])
    shade_flat(ob)
    return ob


def spike(name, loc, size, material, rot=(0, 0, 0), verts=5):
    bpy.ops.mesh.primitive_cone_add(location=loc, rotation=rot, vertices=verts)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(MATS[material])
    shade_flat(ob)
    return ob


# ---------------------------------------------------------------- body
# Blender is Z-up and the creature faces -Y, matching Roblox's -Z facing once
# the axis convention is set on export.

def build_legs():
    for side in (-1, 1):
        block("Thigh", (side * 0.115 * H, 0, 0.235 * H),
              (0.14 * H, 0.15 * H, 0.20 * H), "bark", rough=0.012 * H, seed=1 + side)
        block("Shin", (side * 0.115 * H, -0.005 * H, 0.105 * H),
              (0.125 * H, 0.14 * H, 0.15 * H), "bark", rough=0.010 * H, seed=3 + side)
        block("ThighPlate", (side * 0.115 * H, -0.075 * H, 0.25 * H),
              (0.10 * H, 0.05 * H, 0.13 * H), "flesh", rough=0.008 * H, seed=5 + side)
        # Root foot: splayed claws.
        for i in (-1, 0, 1):
            spike("RootClaw",
                  (side * 0.115 * H + i * 0.045 * H, -0.045 * H, 0.035 * H),
                  (0.055 * H, 0.13 * H, 0.075 * H), "bark_dark",
                  rot=(math.radians(74), 0, i * math.radians(20)))
        block("AnkleLeaf", (side * 0.115 * H, -0.05 * H, 0.075 * H),
              (0.12 * H, 0.07 * H, 0.05 * H), "mane",
              rot=(math.radians(24), 0, 0))


def build_torso():
    block("Torso", (0, 0, 0.45 * H), (0.30 * H, 0.22 * H, 0.25 * H),
          "bark", rough=0.014 * H, seed=11, subdiv=1)
    block("ChestPlate", (0, -0.10 * H, 0.51 * H),
          (0.21 * H, 0.08 * H, 0.12 * H), "flesh", rough=0.010 * H, seed=13)
    block("AbPlate", (0, -0.10 * H, 0.38 * H),
          (0.14 * H, 0.07 * H, 0.11 * H), "flesh_lit", rough=0.009 * H, seed=17)
    for i in range(3):
        block("BackPlate", (0, 0.10 * H, (0.53 - i * 0.08) * H),
              ((0.25 - i * 0.04) * H, 0.06 * H, 0.09 * H),
              "mane" if i % 2 == 0 else "mane_dark", rough=0.008 * H, seed=19 + i)


def build_arms():
    sy = 0.56 * H
    for side in (-1, 1):
        block("Pad", (side * 0.195 * H, 0, sy + 0.025 * H),
              (0.14 * H, 0.15 * H, 0.11 * H), "flesh_lit", rough=0.010 * H, seed=23 + side)
        block("UpperArm", (side * 0.185 * H, 0, sy - 0.09 * H),
              (0.095 * H, 0.115 * H, 0.19 * H), "flesh", rough=0.009 * H, seed=29 + side,
              rot=(0, side * math.radians(-5), 0))
        block("Forearm", (side * 0.205 * H, -0.015 * H, sy - 0.26 * H),
              (0.085 * H, 0.105 * H, 0.19 * H), "flesh_lit", rough=0.008 * H, seed=31 + side,
              rot=(0, side * math.radians(-7), 0))
        for i in range(5):
            spike("Thorn", (side * 0.255 * H, 0, sy + 0.035 * H - i * 0.075 * H),
                  (0.035 * H, 0.035 * H, 0.09 * H), "thorn",
                  rot=(0, side * math.radians(66), 0))
        for i in range(4):
            spike("Claw",
                  (side * 0.21 * H + (i - 1.5) * 0.032 * H, -0.03 * H, sy - 0.375 * H),
                  (0.030 * H, 0.045 * H, 0.115 * H), "claw",
                  rot=(math.radians(196), 0, (i - 1.5) * math.radians(8)))


def build_head():
    # BIGGER AND LOWER than the first pass. On the sheet the head is nearly as
    # wide as the shoulders and sits ON them -- the first attempt made it small
    # and perched it high, which left a hole where a neck should be and let the
    # mane swallow it.
    hz = 0.77 * H
    hy = -0.10 * H
    hw = 0.30 * H

    # A real neck, bridging torso to skull. Without it the shoulder pads sit
    # out at the sides and the middle is empty background.
    # BEHIND the jaw and below it. First placement put the neck at z 0.615 with
    # a 0.12 height, spanning 0.555 to 0.675 -- straight through the mouth. The
    # lower teeth poked out through its front face as a row of little white
    # squares, so the creature appeared to have a second set of teeth in its
    # throat.
    block("Neck", (0, 0.02 * H, 0.60 * H), (0.15 * H, 0.14 * H, 0.10 * H),
          "flesh", rough=0.008 * H, seed=39)

    block("Skull", (0, hy, hz), (hw, 0.30 * H, 0.21 * H),
          "flesh_lit", rough=0.014 * H, seed=41, subdiv=1)
    # Narrower than the skull, so it reads as a ridge rather than a shelf.
    block("Brow", (0, hy - 0.050 * H, hz + 0.055 * H),
          (hw * 0.86, 0.11 * H, 0.045 * H), "flesh", rough=0.008 * H, seed=43,
          rot=(math.radians(-14), 0, 0))
    for side in (-1, 1):
        blob("Eye", (side * 0.068 * H, hy - 0.115 * H, hz + 0.022 * H),
             (0.062 * H, 0.030 * H, 0.030 * H), "eye", subdivisions=2)
    # Recessed and narrower. At 0.80 wide and sitting proud it rendered as a
    # bright maroon band across the whole face rather than as a throat behind
    # the teeth.
    # THE MOUTH IS LAID OUT FROM THE SURFACES THE TEETH GROW OUT OF, not from
    # guessed offsets. Skull bottom is hz - 0.105; jaw top is hz - 0.20. Upper
    # teeth HANG from the first, lower teeth STAND on the second, and the dark
    # maw fills the gap between.
    #
    # The first version had the lower teeth centred at hz - 0.120 with a jaw top
    # at hz - 0.115: the teeth were inside the jaw and only their tips came
    # through its top face, so the creature had a green bar across its chin with
    # five little white squares set into it.
    skull_bottom = hz - 0.105 * H
    jaw_top = hz - 0.200 * H

    block("Maw", (0, hy + 0.01 * H, hz - 0.155 * H),
          (hw * 0.66, 0.10 * H, 0.10 * H), "maw")
    block("Jaw", (0, hy + 0.012 * H, jaw_top - 0.037 * H),
          (hw * 0.90, 0.20 * H, 0.075 * H), "flesh", rough=0.009 * H, seed=47)

    for i in range(-2, 3):
        big = i % 2 == 0
        up_h = (0.060 if big else 0.044) * H
        lo_h = (0.044 if big else 0.060) * H
        spike("ToothUpper", (i * 0.046 * H, hy - 0.080 * H, skull_bottom - up_h / 2),
              (0.032 * H, 0.032 * H, up_h), "tooth",
              rot=(math.radians(180), 0, 0))
        spike("ToothLower", (i * 0.046 * H, hy - 0.080 * H, jaw_top + lo_h / 2),
              (0.032 * H, 0.032 * H, lo_h), "tooth")
    for side in (-1, 1):
        for i in range(3):
            spike("CheekSpike",
                  (side * 0.148 * H, hy - 0.028 * H, hz + 0.028 * H - i * 0.055 * H),
                  (0.030 * H, 0.030 * H, 0.075 * H), "thorn",
                  rot=(0, side * math.radians(72), 0))
    return hz, hy


def build_mane(hz, hy):
    """TWO RINGS ON A SPHERE, not a fan.

    The side view shows a crest wrapping the whole back of the skull and
    carrying down over the shoulders, so the leaves have to radiate in PITCH as
    well as yaw. Swept through a single flat arc it comes out a mohawk -- which
    is what happened twice in the Roblox build.

    NOTHING BELOW PITCH 18, AND NOTHING PAST YAW 75. The first pass ran an
    outer ring at pitch -8 with 150 degrees of spread; those leaves pointed
    sideways and slightly forward and the whole thing read as a sombrero. A
    mane lives on the BACK of the skull -- past 75 degrees of yaw a leaf is no
    longer behind the head, it is beside it, and beside is a hat brim.
    """
    ox, oy, oz = 0.0, hy + 0.06 * H, hz + 0.02 * H
    for count, pitch, length, spread, out in (
        (7, 72, 0.30, 52, 0.08),
        (9, 48, 0.32, 72, 0.11),
        (9, 24, 0.28, 74, 0.13),
    ):
        for i in range(count):
            t = i / (count - 1)
            yaw = math.radians((t - 0.5) * 2 * spread)
            reach = 1 - 0.26 * abs((t - 0.5) * 2)
            ln = length * reach * H
            pit = math.radians(pitch)
            dx = math.sin(yaw) * math.cos(pit)
            dy = math.cos(yaw) * math.cos(pit)
            dz = math.sin(pit)
            base = (ox + dx * out * H, oy + dy * out * H, oz + dz * out * H)
            tip = (base[0] + dx * ln * 0.5, base[1] + dy * ln * 0.5, base[2] + dz * ln * 0.5)
            # DIRECTION -> ROTATION VIA to_track_quat, not hand-rolled Euler.
            # The first version used rot=(radians(90) - pitch, 0, -yaw), which
            # applied to a cone's +Z axis gives (0, -cos(pitch), sin(pitch)):
            # -Y, and -Y is the way the creature FACES. Every leaf pointed
            # forward over its own face, which is what the sombrero actually
            # was. Letting Blender solve the alignment removes a whole class of
            # sign error that is invisible until rendered.
            rot = Vector((dx, dy, dz)).to_track_quat("Z", "Y").to_euler()
            spike("ManeLeaf", tip, (0.085 * H, 0.055 * H, ln),
                  "mane" if i % 2 == 0 else "mane_dark",
                  rot=rot, verts=4)


build_legs()
build_torso()
build_arms()
hz, hy = build_head()
build_mane(hz, hy)

# ---------------------------------------------------------------- report
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
tris = 0
for o in meshes:
    o.data.calc_loop_triangles()
    tris += len(o.data.loop_triangles)

zs = [(o.matrix_world @ v.co).z for o in meshes for v in o.data.vertices]
print("PIECES", len(meshes))
print("TRIS", tris)
print("HEIGHT", round(max(zs) - min(zs), 2), "of a nominal", H)


# ---------------------------------------------------------------- preview
def render(name, loc, rot, ortho):
    scene = bpy.context.scene
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        bpy.ops.object.camera_add(location=loc, rotation=rot)
        cam = bpy.context.active_object
        cam.name = "PreviewCam"
        scene.camera = cam
    cam.location = loc
    cam.rotation_euler = rot
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ortho
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.display.shading.cavity_type = "BOTH"
    if scene.world is None:
        scene.world = bpy.data.worlds.new("W")
    scene.world.color = (0.82, 0.82, 0.82)
    scene.render.resolution_x = 620
    scene.render.resolution_y = 760
    scene.render.filepath = os.path.join(OUT, name)
    bpy.ops.render.render(write_still=True)
    print("RENDERED", scene.render.filepath)


if DO_RENDER:
    mid = 0.5 * H
    render("parent_front.png", (0, -22, mid), (math.radians(90), 0, 0), 12.5)
    render("parent_side.png", (22, 0, mid), (math.radians(90), 0, math.radians(90)), 12.5)
    render("parent_back.png", (0, 22, mid), (math.radians(90), 0, math.radians(180)), 12.5)

if DO_EXPORT:
    for o in bpy.data.objects:
        o.select_set(o.type == "MESH")
    path = os.path.join(OUT, "parent_biome1.fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True,
                             apply_scale_options="FBX_SCALE_ALL",
                             axis_forward="-Z", axis_up="Y")
    print("EXPORTED", path)
