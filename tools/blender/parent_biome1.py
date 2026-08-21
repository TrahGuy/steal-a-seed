"""Builds the Greenhollow nest parent in Blender, to KB/biome1-parent-ortho.png.

    blender --background --python tools/blender/parent_biome1.py -- --render
    blender --background --python tools/blender/parent_biome1.py -- --export

WHY METABALLS AND NOT BOXES
    The first Blender pass stacked axis-aligned cubes, and it read as a stack of
    axis-aligned cubes -- the same failure as the 87-part Roblox build, just at
    higher resolution. The reference is a continuous organic mass, and no
    arrangement of separate boxes ever becomes continuous.

    Metaballs do. Elements inside one metaball object BLEND into a single
    surface, so a chain of spheres down a limb becomes a tapered limb with real
    shoulders and joints rather than a pile of segments. Convert to mesh,
    decimate hard, shade flat, and the result is faceted low-poly organic --
    which is the reference's style exactly.

    TWO metaball objects, not one: Blender blends elements sharing a base name,
    so MetaBark and MetaFlesh stay separate surfaces that intersect without
    merging. That is what gives a bark trunk under green plates instead of one
    uniform blob.

    Hard details -- teeth, claws, thorns, mane leaves, eyes -- stay crisp
    primitives on top. Blending those would round off the only sharp things on
    the whole creature.

WHY WORKBENCH FOR PREVIEWS
    Shades flat from material colour, needs no GPU, renders in about a second.
    The preview is a fair picture of the result rather than a prettier one.

PROPORTIONS measured off the orthographic sheet -- fractions of total height,
feet at 0, mane tip at 1:

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
import math
import os
import sys
import random
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)

H = 10.0  # working height in Blender units; Roblox scale is set on import

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
DO_RENDER = "--render" in argv or not argv
DO_EXPORT = "--export" in argv

random.seed(20260821)

PALETTE = {
    "bark":      (0.150, 0.108, 0.062),
    "bark_dark": (0.092, 0.068, 0.042),
    "flesh":     (0.250, 0.315, 0.078),
    "flesh_lit": (0.345, 0.415, 0.115),
    "mane":      (0.150, 0.240, 0.070),
    "mane_dark": (0.092, 0.160, 0.050),
    "thorn":     (0.560, 0.290, 0.230),
    "tooth":     (0.880, 0.855, 0.760),
    "eye":       (0.700, 0.120, 0.110),
    "claw":      (0.430, 0.485, 0.175),
    "maw":       (0.170, 0.042, 0.048),
}

bpy.ops.wm.read_factory_settings(use_empty=True)
MATS = {}
for _name, _rgb in PALETTE.items():
    _m = bpy.data.materials.new(_name)
    _m.use_nodes = False
    _m.diffuse_color = (*_rgb, 1.0)
    _m.roughness = 0.9
    MATS[_name] = _m


# ---------------------------------------------------------------- helpers
def shade_flat(ob):
    for p in ob.data.polygons:
        p.use_smooth = False


def spike(name, loc, size, material, rot=(0, 0, 0), verts=5):
    bpy.ops.mesh.primitive_cone_add(location=loc, rotation=rot, vertices=verts)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(MATS[material])
    shade_flat(ob)
    return ob


def blob(name, loc, size, material, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(location=loc, subdivisions=subdivisions)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(MATS[material])
    shade_flat(ob)
    return ob


def wedge_block(name, loc, size, material, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(MATS[material])
    shade_flat(ob)
    return ob


# ---------------------------------------------------------------- metaballs
class Meta:
    """One blended surface. Elements added here fuse with each other and with
    nothing outside this object."""

    def __init__(self, name, material, resolution=0.16):
        mb = bpy.data.metaballs.new(name)
        mb.resolution = resolution
        mb.render_resolution = resolution
        ob = bpy.data.objects.new(name, mb)
        bpy.context.collection.objects.link(ob)
        self.ob = ob
        self.mb = mb
        self.material = material

    def ball(self, loc, r, stiffness=2.0):
        e = self.mb.elements.new()
        e.type = "BALL"
        e.co = Vector(loc)
        e.radius = r
        e.stiffness = stiffness
        return e

    def ellipsoid(self, loc, r, sx, sy, sz, stiffness=2.0):
        e = self.mb.elements.new()
        e.type = "ELLIPSOID"
        e.co = Vector(loc)
        e.radius = r
        e.size_x, e.size_y, e.size_z = sx, sy, sz
        e.stiffness = stiffness
        return e

    def limb(self, a, b, r0, r1, steps=5):
        """A chain of spheres from a to b, tapering. This is what turns two
        joints into a limb rather than into two joints."""
        for i in range(steps):
            t = i / (steps - 1)
            self.ball(
                (a[0] + (b[0] - a[0]) * t,
                 a[1] + (b[1] - a[1]) * t,
                 a[2] + (b[2] - a[2]) * t),
                r0 + (r1 - r0) * t,
            )

    def finish(self, decimate_ratio):
        """Convert to mesh and cut it down hard. The decimate is what produces
        the facets: a converted metaball is a dense smooth blob, and collapsing
        it to a few hundred triangles is what makes it read as low-poly rather
        than as a smooth toy."""
        bpy.ops.object.select_all(action="DESELECT")
        self.ob.select_set(True)
        bpy.context.view_layer.objects.active = self.ob
        bpy.ops.object.convert(target="MESH")
        ob = bpy.context.active_object
        if len(ob.data.vertices) == 0:
            print("WARNING empty metaball", self.ob.name)
            return ob
        m = ob.modifiers.new("dec", "DECIMATE")
        m.decimate_type = "COLLAPSE"
        m.ratio = decimate_ratio
        bpy.ops.object.modifier_apply(modifier=m.name)
        ob.data.materials.append(MATS[self.material])
        shade_flat(ob)
        return ob


# ---------------------------------------------------------------- landmarks
# Blender is Z-up; the creature faces -Y.
HIP_Z = 0.345 * H
KNEE_Z = 0.185 * H
ANKLE_Z = 0.065 * H
LEG_X = 0.115 * H
SHOULDER_Z = 0.565 * H
# SHOULDERS MUST OVERLAP THE TRUNK, not sit beside it. The two masses are
# different metaball objects and so cannot blend -- they only ever intersect --
# which means anything short of real overlap leaves the arms floating as
# separate green columns with daylight between them and the body.
SHOULDER_X = 0.150 * H
SHOULDER_Y = -0.040 * H
ELBOW_Z = 0.375 * H
WRIST_Z = 0.215 * H
HEAD_Z = 0.755 * H
HEAD_Y = -0.095 * H


def build_bark():
    """Trunk and legs: the brown mass under the green."""
    m = Meta("MetaBark", "bark", resolution=0.15)
    m.ellipsoid((0, -0.030 * H, 0.525 * H), 0.132 * H, 1.42, 1.30, 1.00)
    m.ellipsoid((0, -0.012 * H, 0.430 * H), 0.122 * H, 1.28, 1.22, 0.85)
    m.ellipsoid((0, 0.010 * H, HIP_Z), 0.126 * H, 1.42, 1.25, 0.78)
    for side in (-1, 1):
        m.limb((side * LEG_X, 0, HIP_Z), (side * LEG_X, -0.005 * H, KNEE_Z),
               0.082 * H, 0.070 * H, steps=4)
        m.limb((side * LEG_X, -0.005 * H, KNEE_Z), (side * LEG_X, -0.010 * H, ANKLE_Z),
               0.070 * H, 0.062 * H, steps=4)
        # Ankle spread, so a foot reads as roots gripping rather than as a peg.
        m.ellipsoid((side * LEG_X, -0.025 * H, ANKLE_Z * 0.55), 0.070 * H, 1.0, 1.5, 0.55)
    return m.finish(0.06)


def build_flesh():
    """Head, arms, shoulders and the leaf plates: the green mass."""
    m = Meta("MetaFlesh", "flesh", resolution=0.13)

    for side in (-1, 1):
        m.ellipsoid((side * SHOULDER_X, SHOULDER_Y, SHOULDER_Z),
                    0.098 * H, 1.25, 1.35, 1.0)
        m.limb((side * SHOULDER_X, SHOULDER_Y, SHOULDER_Z),
               (side * (SHOULDER_X + 0.020 * H), SHOULDER_Y - 0.015 * H, ELBOW_Z),
               0.074 * H, 0.060 * H, steps=4)
        m.limb((side * (SHOULDER_X + 0.020 * H), SHOULDER_Y - 0.015 * H, ELBOW_Z),
               (side * (SHOULDER_X + 0.034 * H), SHOULDER_Y - 0.045 * H, WRIST_Z),
               0.060 * H, 0.052 * H, steps=4)
        m.ellipsoid((side * (SHOULDER_X + 0.036 * H), SHOULDER_Y - 0.060 * H,
                     WRIST_Z - 0.020 * H), 0.058 * H, 1.0, 1.30, 0.75)

    # NECK: A CHAIN, NOT ONE ELEMENT.
    #
    # A single neck ellipsoid at 0.635 with radius 0.080 left the head floating
    # clear of the shoulders. Metaball elements only fuse where their influence
    # fields overlap, and one small element spanning a 0.19H gap between a
    # shoulder mass and a skull mass reaches neither -- it just makes a third
    # separate lump. Bridging takes overlapping links, the same way a limb does.
    m.limb((0, -0.010 * H, 0.575 * H), (0, HEAD_Y * 0.55, 0.700 * H),
           0.088 * H, 0.098 * H, steps=4)
    m.ellipsoid((0, HEAD_Y, HEAD_Z), 0.145 * H, 1.30, 1.45, 0.90)
    # Snout, pushed forward and down: what makes the head a wedge, not a ball.
    m.ellipsoid((0, HEAD_Y - 0.085 * H, HEAD_Z - 0.032 * H), 0.108 * H, 1.12, 1.00, 0.62)

    m.ellipsoid((0, -0.095 * H, 0.520 * H), 0.115 * H, 1.55, 0.40, 0.95)
    m.ellipsoid((0, -0.092 * H, 0.410 * H), 0.098 * H, 1.25, 0.38, 0.85)
    for i in range(3):
        m.ellipsoid((0, 0.090 * H, (0.550 - i * 0.078) * H), 0.100 * H,
                    1.55 - i * 0.20, 0.38, 0.62)
    for side in (-1, 1):
        m.ellipsoid((side * LEG_X, -0.062 * H, 0.275 * H), 0.062 * H, 0.95, 0.45, 1.15)
    return m.finish(0.055)


def build_jaw():
    """Its own blended mass, so the mouth is a gap between two surfaces rather
    than a hole cut in one."""
    m = Meta("MetaJaw", "flesh", resolution=0.10)
    m.ellipsoid((0, HEAD_Y - 0.020 * H, HEAD_Z - 0.150 * H), 0.098 * H, 1.20, 1.05, 0.42)
    m.ellipsoid((0, HEAD_Y - 0.080 * H, HEAD_Z - 0.145 * H), 0.078 * H, 1.00, 0.80, 0.36)
    return m.finish(0.10)


build_bark()
build_flesh()
build_jaw()


# ---------------------------------------------------------------- details
def build_face():
    hw = 0.30 * H
    blob("Maw", (0, HEAD_Y - 0.035 * H, HEAD_Z - 0.105 * H),
         (hw * 0.62, 0.10 * H, 0.075 * H), "maw")

    # Teeth grow OUT OF measured surfaces: upper hang from the skull's underside,
    # lower stand on the jaw's top. Guessed offsets buried them in the jaw and
    # left five white squares poking through a green bar.
    skull_bottom = HEAD_Z - 0.078 * H
    jaw_top = HEAD_Z - 0.132 * H
    for i in range(-2, 3):
        big = i % 2 == 0
        up_h = (0.055 if big else 0.040) * H
        lo_h = (0.040 if big else 0.055) * H
        spike("ToothUpper", (i * 0.042 * H, HEAD_Y - 0.088 * H, skull_bottom - up_h / 2),
              (0.030 * H, 0.030 * H, up_h), "tooth", rot=(math.radians(180), 0, 0))
        spike("ToothLower", (i * 0.042 * H, HEAD_Y - 0.088 * H, jaw_top + lo_h / 2),
              (0.030 * H, 0.030 * H, lo_h), "tooth")

    for side in (-1, 1):
        blob("Eye", (side * 0.062 * H, HEAD_Y - 0.105 * H, HEAD_Z + 0.030 * H),
             (0.055 * H, 0.032 * H, 0.030 * H), "eye")
        # Angry is entirely a question of which way the brows slope.
        wedge_block("Brow", (side * 0.068 * H, HEAD_Y - 0.098 * H, HEAD_Z + 0.062 * H),
                    (0.115 * H, 0.075 * H, 0.032 * H), "flesh_lit",
                    rot=(math.radians(-16), 0, side * math.radians(15)))
        for i in range(3):
            spike("CheekSpike",
                  (side * 0.135 * H, HEAD_Y - 0.030 * H,
                   HEAD_Z + 0.020 * H - i * 0.050 * H),
                  (0.028 * H, 0.028 * H, 0.070 * H), "thorn",
                  rot=(0, side * math.radians(74), 0))


def build_thorns_and_claws():
    for side in (-1, 1):
        for i in range(5):
            t = i / 4
            z = SHOULDER_Z + 0.030 * H - t * 0.32 * H
            x = side * (SHOULDER_X + 0.072 * H + t * 0.014 * H)
            spike("Thorn", (x, SHOULDER_Y - t * 0.030 * H, z),
                  (0.032 * H, 0.032 * H, 0.085 * H), "thorn",
                  rot=(0, side * math.radians(72), 0))
        for i in range(4):
            spike("Claw",
                  (side * (SHOULDER_X + 0.036 * H) + (i - 1.5) * 0.030 * H,
                   SHOULDER_Y - 0.082 * H, WRIST_Z - 0.065 * H),
                  (0.028 * H, 0.042 * H, 0.105 * H), "claw",
                  rot=(math.radians(194), 0, (i - 1.5) * math.radians(8)))
        for i in (-1, 0, 1):
            spike("RootClaw", (side * LEG_X + i * 0.042 * H, -0.050 * H, 0.030 * H),
                  (0.052 * H, 0.125 * H, 0.070 * H), "bark_dark",
                  rot=(math.radians(76), 0, i * math.radians(20)))


def build_mane():
    """RINGS ON A SPHERE, not a fan.

    NOTHING BELOW PITCH 6, NOTHING PAST YAW 76. A mane lives on the BACK of the
    skull -- past about 75 degrees a leaf is not behind the head any more, it is
    beside it, and beside is a hat brim. An early ring at pitch -8 with 150
    degrees of spread produced exactly that, twice.

    Directions become rotations via to_track_quat rather than hand-rolled Euler:
    rot=(radians(90) - pitch, 0, -yaw) applied to a cone's +Z gives
    (0, -cos(pitch), sin(pitch)), and -Y is the way the creature FACES, so every
    leaf pointed forward over its own face."""
    ox, oy, oz = 0.0, HEAD_Y + 0.055 * H, HEAD_Z + 0.020 * H
    for count, pitch, length, spread, out, forced in (
        (7, 74, 0.30, 48, 0.085, None),
        (9, 52, 0.34, 70, 0.105, None),
        (11, 28, 0.30, 76, 0.125, None),
        (9, 6, 0.22, 66, 0.135, "mane_dark"),
    ):
        for i in range(count):
            t = i / (count - 1)
            yaw = math.radians((t - 0.5) * 2 * spread)
            reach = 1 - 0.24 * abs((t - 0.5) * 2)
            ln = length * reach * H
            pit = math.radians(pitch)
            d = Vector((math.sin(yaw) * math.cos(pit),
                        math.cos(yaw) * math.cos(pit),
                        math.sin(pit)))
            base = Vector((ox, oy, oz)) + d * out * H
            tip = base + d * ln * 0.5
            spike("ManeLeaf", tip, (0.080 * H, 0.052 * H, ln),
                  forced or ("mane" if i % 2 == 0 else "mane_dark"),
                  rot=d.to_track_quat("Z", "Y").to_euler(), verts=4)


build_face()
build_thorns_and_claws()
build_mane()

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
