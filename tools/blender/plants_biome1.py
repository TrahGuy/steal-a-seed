"""Renders the five Greenhollow grown plants as CreatureModel builds them.

    blender --background --python tools/blender/plants_biome1.py -- --render

This is a PICTURE of the live models, not a replacement mesh. Every measurement
is the same one CreatureModel uses: FrameHeight * SizeScale, Girth on the
horizontal terms, mound-stem-leaves-head-crown-face. No legs -- the plants
stand on a soil mound. Walking them is a later job; this file exists so that
job has five silhouettes to look at.

Blender is Z-up. The plants face -Y, same as parent_biome1.py. Roblox (x,y,z)
maps to Blender (x, z, y): up becomes Z, facing -Z becomes facing -Y.
"""
import bpy
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
os.makedirs(OUT, exist_ok=True)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
DO_RENDER = "--render" in argv or not argv

# SeedData.SizeScale / Girth, inlined so this file does not need Luau.
SIZE_REF_KG = 7.5
SIZE_EXP = 0.20
GIRTH_REF_KG = 14.0
GIRTH_EXP = 0.12


def size_scale(kg):
    return (kg / SIZE_REF_KG) ** SIZE_EXP


def girth(kg):
    return max(0.70, min(2.40, (kg / GIRTH_REF_KG) ** GIRTH_EXP))


def rgb(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


LEAF = rgb(86, 150, 66)
STEM = rgb(124, 182, 92)
SOIL = rgb(74, 54, 44)
GREEN = rgb(146, 196, 106)
CREAM = rgb(242, 238, 206)
DARK = rgb(38, 34, 40)
WHITE = rgb(252, 252, 250)

SPECIES = [
    {
        "id": "nubkin", "name": "Nubkin", "form": "cube",
        "kg": 2, "height": 2.4,
        "body": GREEN, "crown": GREEN, "accent": CREAM,
    },
    {
        "id": "petalpip", "name": "Petalpip", "form": "orb",
        "kg": 5, "height": 3.0,
        "body": GREEN, "crown": CREAM, "accent": rgb(226, 138, 116),
    },
    {
        "id": "spiretip", "name": "Spiretip", "form": "teardrop",
        "kg": 14, "height": 3.2,
        "body": rgb(132, 186, 96), "crown": rgb(168, 208, 122), "accent": CREAM,
    },
    {
        "id": "toadcap", "name": "Toadcap", "form": "mushroom",
        "kg": 40, "height": 3.6,
        "body": CREAM, "crown": rgb(216, 112, 100), "accent": CREAM,
    },
    {
        "id": "bellchime", "name": "Bellchime", "form": "bell",
        "kg": 110, "height": 4.0,
        "body": CREAM, "crown": rgb(234, 158, 158), "accent": LEAF,
    },
]


bpy.ops.wm.read_factory_settings(use_empty=True)

MATS = {}


def mat(name, color):
    if name not in MATS:
        m = bpy.data.materials.new(name)
        m.use_nodes = False
        m.diffuse_color = (*color, 1.0)
        m.roughness = 0.88
        MATS[name] = m
    return MATS[name]


def shade_flat(ob):
    for p in ob.data.polygons:
        p.use_smooth = False


def parent_to(ob, root):
    # Parts are authored in the plant's local space. Root already sits at the
    # row offset, so parenting without Keep Transform puts (0,0,z) on the mound.
    ob.parent = root


def cube(name, loc, size, color, root, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(mat(name.split(".")[0] + "_" + str(color), color))
    shade_flat(ob)
    parent_to(ob, root)
    return ob


def ball(name, loc, diameter, color, root):
    bpy.ops.mesh.primitive_ico_sphere_add(
        location=loc, subdivisions=2, radius=diameter / 2)
    ob = bpy.context.active_object
    ob.name = name
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(mat(name.split(".")[0] + "_" + str(color), color))
    shade_flat(ob)
    parent_to(ob, root)
    return ob


def upright(name, loc, height, diameter, color, root):
    # Cylinder along Z (up), matching CreatureModel's upright helper.
    bpy.ops.mesh.primitive_cylinder_add(
        location=loc, radius=diameter / 2, depth=height, vertices=16)
    ob = bpy.context.active_object
    ob.name = name
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(mat(name.split(".")[0] + "_" + str(color), color))
    shade_flat(ob)
    parent_to(ob, root)
    return ob


def cone(name, loc, radius, depth, color, root, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(
        location=loc, rotation=rot, radius1=radius, radius2=0, depth=depth, vertices=8)
    ob = bpy.context.active_object
    ob.name = name
    bpy.ops.object.transform_apply(scale=True)
    ob.data.materials.append(mat(name.split(".")[0] + "_" + str(color), color))
    shade_flat(ob)
    parent_to(ob, root)
    return ob


def add_face(root, face_x, face_y, face_z, width, front):
    """Seven parts, same as CreatureModel.addFace. front is how far the face
    sits in front of the head centre, along -Y."""
    eye_w = width * 0.17
    eye_h = width * 0.21
    gap = width * 0.21
    for side in (-1, 1):
        ex = face_x + side * gap
        ey = face_y - front
        ez = face_z + width * 0.06
        cube("Eye", (ex, ey, ez), (eye_w, 0.08, eye_h), DARK, root)
        cube("Glint", (ex - eye_w * 0.22, ey - 0.02, ez + eye_h * 0.24),
             (eye_w * 0.34, 0.08, eye_h * 0.30), WHITE, root)
    mw = width * 0.10
    for sx, lift in ((-1, 0.030), (0, 0.0), (1, 0.030)):
        cube("Smile",
             (face_x + sx * mw * 0.92,
              face_y - front,
              face_z - width * 0.15 + lift * width),
             (mw, 0.08, width * 0.045), DARK, root)


def add_flower(root, sp, top_x, top_y, top_z, w):
    for i in range(5):
        a = i / 5 * math.pi * 2
        px = top_x + math.sin(a) * w * 0.28
        py = top_y - math.cos(a) * w * 0.28
        cube("Petal", (px, py, top_z),
             (w * 0.38, w * 0.30, w * 0.11), sp["crown"], root,
             rot=(0, 0, a))
    ball("FlowerCentre", (top_x, top_y, top_z), w * 0.24, sp["accent"], root)


def add_spikes(root, sp, top_x, top_y, top_z, w, h):
    for sx, scale, tilt in ((0, 1.0, 0), (-1, 0.68, 26), (1, 0.68, -26)):
        cube("Spike",
             (top_x + sx * w * 0.28, top_y, top_z + h * 0.13 * scale),
             (w * 0.16, w * 0.13, h * 0.30 * scale), sp["crown"], root,
             rot=(0, math.radians(tilt), 0))


def add_fronds(root, sp, top_x, top_y, top_z, w):
    for i in range(3):
        a = i / 3 * math.pi * 2
        sx = math.sin(a)
        sy = -math.cos(a)
        cube("Frond",
             (top_x + sx * w * 0.10, top_y + sy * w * 0.10, top_z + w * 0.20),
             (w * 0.09, w * 0.09, w * 0.42), LEAF, root)
        cube("FrondTip",
             (top_x + sx * w * 0.30, top_y + sy * w * 0.30, top_z + w * 0.36),
             (w * 0.22, w * 0.16, w * 0.09), LEAF, root,
             rot=(math.radians(-38) * sy, math.radians(-38) * sx, a))


def add_buds(root, sp, top_x, top_y, top_z, w):
    for i in range(7):
        a = i / 7 * math.pi * 2
        lean = 1.0 if i % 2 == 0 else 0.76
        reach = w * 0.26
        sx = math.sin(a)
        sy = -math.cos(a)
        cube("BudStalk",
             (top_x + sx * reach * 0.7, top_y + sy * reach * 0.7,
              top_z + w * 0.20 * lean),
             (w * 0.05, w * 0.05, w * 0.40 * lean), sp["accent"], root,
             rot=(math.radians(-11) * sy, math.radians(-11) * sx, 0))
        ball("Bud",
             (top_x + sx * reach, top_y + sy * reach, top_z + w * 0.42 * lean),
             w * 0.18, sp["crown"], root)


def build_plant(sp, origin_x):
    """One grown creature at sheet kg. origin_x is the mound centre on X.
    Parts are built in local space; the empty carries the row offset."""
    kg = sp["kg"]
    H = sp["height"] * size_scale(kg)
    G = girth(kg)

    root = bpy.data.objects.new("Plant_" + sp["id"], None)
    root.location = (origin_x, 0, 0)
    bpy.context.collection.objects.link(root)

    mound_h = H * 0.11
    stem_h = H * 0.34
    stem_base = mound_h * 0.7
    head_w = H * 0.46 * G
    head_z = stem_base + stem_h + head_w * 0.46
    top_z = head_z + head_w * 0.5

    upright("Mound", (0, 0, mound_h * 0.5),
            mound_h, H * 0.66 * G, SOIL, root)
    upright("Stem", (0, 0, stem_base + stem_h * 0.5),
            stem_h, H * 0.13 * G, STEM, root)

    for side in (-1, 1):
        cube("Leaf",
             (side * H * 0.16 * G, 0, stem_base + stem_h * 0.40),
             (H * 0.27 * G, H * 0.12 * G, H * 0.05), LEAF, root,
             rot=(0, side * math.radians(-13), side * math.radians(16)))

    face_x, face_y, face_z = 0.0, 0.0, head_z
    face_w = head_w
    front = head_w * 0.5
    form = sp["form"]

    if form == "cube":
        cube("Head", (0, 0, head_z),
             (head_w, head_w, head_w), sp["body"], root)

    elif form == "orb":
        ball("Head", (0, 0, head_z), head_w, sp["body"], root)
        front = head_w * 0.46
        add_flower(root, sp, 0, 0, top_z + head_w * 0.06, head_w)

    elif form == "teardrop":
        ball("Head", (0, 0, head_z), head_w, sp["body"], root)
        front = head_w * 0.46
        cone("HeadPoint", (0, 0, head_z + head_w * 0.52),
             head_w * 0.42, head_w * 0.55, sp["body"], root)
        add_spikes(root, sp, 0, 0, top_z + head_w * 0.38, head_w, H)

    elif form == "mushroom":
        ball("Head", (0, 0, head_z), head_w * 0.86, sp["body"], root)
        face_w = head_w * 0.86
        front = head_w * 0.42
        cap_z = head_z + head_w * 0.42
        upright("CapDisc", (0, 0, cap_z),
                head_w * 0.16, head_w * 1.32, sp["crown"], root)
        ball("CapDome", (0, 0, cap_z + head_w * 0.10),
             head_w * 1.10, sp["crown"], root)
        for i in range(5):
            a = i / 5 * math.pi * 2
            upright("Spot",
                    (math.sin(a) * head_w * 0.40,
                     -math.cos(a) * head_w * 0.40,
                     cap_z + head_w * 0.36),
                    head_w * 0.05, head_w * 0.24, sp["accent"], root)
        add_fronds(root, sp, 0, 0, cap_z + head_w * 0.44, head_w)

    else:  # bell
        for d, dy in ((0.50, 0.40), (0.74, 0.16), (1.00, -0.08), (1.20, -0.30)):
            upright("BellTier", (0, 0, head_z + dy * head_w),
                    head_w * 0.28, head_w * d, sp["body"], root)
        upright("Collar", (0, 0, head_z + head_w * 0.54),
                head_w * 0.16, head_w * 0.58, sp["accent"], root)
        add_buds(root, sp, 0, 0, head_z + head_w * 0.60, head_w)
        face_z = head_z - head_w * 0.10
        face_w = head_w
        front = head_w * 0.60

    add_face(root, face_x, face_y, face_z, face_w, front + 0.04)

    bpy.ops.object.text_add(location=(0, 0.4, -0.55))
    label = bpy.context.active_object
    label.name = "Label_" + sp["id"]
    label.data.body = "%s\n%d kg" % (sp["name"], sp["kg"])
    label.data.align_x = "CENTER"
    label.data.align_y = "TOP"
    label.data.size = 0.42
    label.rotation_euler = (math.radians(90), 0, 0)
    label.data.materials.append(mat("label", DARK))
    parent_to(label, root)

    finished = top_z
    if form == "teardrop":
        finished = head_z + head_w * 0.52 + head_w * 0.28
    elif form == "mushroom":
        finished = head_z + head_w * 0.42 + head_w * 0.10 + head_w * 0.55
    elif form == "bell":
        finished = head_z + head_w * 0.60 + head_w * 0.42
    print("%-9s  kg %4d  frame %.2f  girth %.2f  ~top %.1f" % (
        sp["name"], kg, H, G, finished))
    return root, H * 0.66 * G, finished


# Space them by girth so the bell's skirt does not swallow the mushroom.
halves = []
for sp in SPECIES:
    G = girth(sp["kg"])
    H = sp["height"] * size_scale(sp["kg"])
    halves.append(max(H * 0.66 * G, H * 0.46 * G * 1.32) * 0.5 + 0.55)

origins = [0.0]
for i in range(1, len(SPECIES)):
    origins.append(origins[i - 1] + halves[i - 1] + halves[i])
mid = (origins[0] + origins[-1]) * 0.5
origins = [x - mid for x in origins]

span = (origins[-1] - origins[0]) + 4.8
bpy.ops.mesh.primitive_cube_add(location=(0, 0, -0.08))
ground = bpy.context.active_object
ground.name = "Dirt"
ground.scale = (span / 2, 2.2, 0.08)
bpy.ops.object.transform_apply(scale=True)
ground.data.materials.append(mat("dirt", SOIL))
shade_flat(ground)

max_top = 0.0
for sp, ox in zip(SPECIES, origins):
    _, _, top = build_plant(sp, ox)
    max_top = max(max_top, top)


def render(name, loc, rot, ortho, res=(1600, 720)):
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
    scene.render.resolution_x = res[0]
    scene.render.resolution_y = res[1]
    scene.render.filepath = os.path.join(OUT, name)
    bpy.ops.render.render(write_still=True)
    print("RENDERED", scene.render.filepath)


if DO_RENDER:
    mid_z = max_top * 0.48
    width = (origins[-1] - origins[0]) + 3.2
    render("plants_lineup_front.png",
           (0, -22, mid_z), (math.radians(90), 0, 0),
           max(width, max_top + 1.6), res=(1800, 780))
    render("plants_lineup_quarter.png",
           (14, -16, mid_z + 1.2),
           (math.radians(72), 0, math.radians(42)),
           max(width * 0.95, max_top + 2.0), res=(1600, 900))
    print("ROW WIDTH", round(width, 2), "TALLEST", round(max_top, 2))
