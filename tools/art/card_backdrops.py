"""Draws the five Greenhollow card backdrops.

    python tools/art/card_backdrops.py

Output: art/cards/<speciesId>.png, 512 x 666 (the card's 1.30 aspect).

WHY THESE ARE GENERATED RATHER THAN PAINTED
    Nothing in this repo is placed by hand, and a backdrop is no different from
    the map or the HUD: a script that draws it can be re-run at another size,
    re-tuned in one number, and diffed. The PNGs are build output. They are
    committed only because Roblox needs a file to upload, and the ids that come
    back are what the game actually loads (GameConfig.Card.Art).

WHAT THEY ARE FOR
    Scenery behind a 3D plant, and nothing else. Every one of them is
    deliberately soft and low-contrast: the plant is the subject and a backdrop
    that competes with a silhouette is a backdrop that has failed. Hence the
    blur pass on every layer, the vignette, and a top-to-bottom fade that keeps
    the busiest detail away from where the creature's head sits.

ONE PICTURE PER SPECIES, KEYED BY species.Id
    Each is that species' own habitat, taken from what SeedData says it is --
    Spiretip is the only cool, shaded green in the biome, so it gets a pine
    grove in mist; Toadcap grows under a log on a damp floor; Bellchime is the
    rarest thing in Greenhollow and gets dusk with lanterns. They are five
    different pictures, not five tints of one sky.
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

W, H = 512, 666
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art", "cards")


def canvas(top, bottom):
    """A vertical gradient, which is the sky on every one of these."""
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(
            int(round(top[i] + (bottom[i] - top[i]) * t)) for i in range(3)))
    return img


def layer():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def paste(base, over, blur=0):
    if blur:
        over = over.filter(ImageFilter.GaussianBlur(blur))
    base.paste(over, (0, 0), over)


def hill(img, cx, cy, rx, ry, colour, alpha=255):
    d = ImageDraw.Draw(img)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=colour + (alpha,))


def blob(img, cx, cy, r, colour, alpha=255):
    hill(img, cx, cy, r, r, colour, alpha)


def conifer(img, cx, base, height, width, colour, alpha=255):
    """One tapered pine: three overlapping triangles, each wider and lower.

    The first pass stacked four tiers whose apexes sat ABOVE the base of the
    tier before them, which left wedges of sky between them -- so what rendered
    was a column of pale downward arrows rather than a tree. Each tier now
    starts inside the one above it, and the trunk closes the bottom.
    """
    d = ImageDraw.Draw(img)
    tiers = 3
    for i in range(tiers):
        t = i / (tiers - 1)
        apex = base - height * (1 - 0.26 * t)
        foot = base - height * (0.42 - 0.42 * t)
        half = width * 0.5 * (0.46 + 0.54 * t)
        d.polygon([(cx, apex), (cx - half, foot), (cx + half, foot)],
                  fill=colour + (alpha,))
    d.rectangle([cx - width * 0.05, base - height * 0.06, cx + width * 0.05, base],
                fill=colour + (alpha,))


def vignette(img, strength=90):
    v = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(v)
    d.ellipse([-W * 0.28, -H * 0.22, W * 1.28, H * 1.22], fill=strength)
    v = v.filter(ImageFilter.GaussianBlur(70))
    dark = Image.new("RGBA", (W, H), (18, 14, 22, 0))
    dark.putalpha(Image.eval(v, lambda p: strength - p))
    img.paste(dark, (0, 0), dark)


def settle(img):
    """A last fade that keeps the top of the card quiet: the creature's head is
    up there and it needs clean air to read against."""
    fade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(fade)
    for y in range(int(H * 0.52)):
        a = int(70 * (1 - y / (H * 0.52)))
        d.line([(0, y), (W, y)], fill=(255, 255, 255, a))
    img.paste(fade, (0, 0), fade)


# ---------------------------------------------------------------- nubkin --
def nubkin():
    """The ordinary one. A tidy sunlit vegetable patch, furrows running back."""
    img = canvas((226, 238, 196), (150, 190, 118)).convert("RGBA")
    sky = layer()
    blob(sky, W * 0.74, H * 0.20, 78, (255, 250, 214), 150)
    paste(img, sky, blur=26)

    far = layer()
    hill(far, W * 0.24, H * 0.60, 260, 96, (150, 188, 116), 220)
    hill(far, W * 0.82, H * 0.62, 220, 84, (140, 180, 108), 210)
    paste(img, far, blur=9)

    rows = layer()
    d = ImageDraw.Draw(rows)
    for i in range(7):
        t = i / 6
        y = H * (0.66 + 0.30 * t * t)
        spread = 30 + 300 * t
        d.polygon([(W * 0.5 - spread, y), (W * 0.5 + spread, y),
                   (W * 0.5 + spread * 1.25, y + 20 + 22 * t),
                   (W * 0.5 - spread * 1.25, y + 20 + 22 * t)],
                  fill=(132, 88, 58, 190 if i % 2 == 0 else 140))
    paste(img, rows, blur=5)
    return img


# -------------------------------------------------------------- petalpip --
def petalpip():
    """Sunlit and lighter than Nubkin. A meadow under a low sun, blossoms up."""
    img = canvas((252, 246, 210), (196, 220, 140)).convert("RGBA")
    sun = layer()
    blob(sun, W * 0.5, H * 0.30, 150, (255, 248, 196), 190)
    blob(sun, W * 0.5, H * 0.30, 76, (255, 252, 226), 220)
    paste(img, sun, blur=34)

    ground = layer()
    hill(ground, W * 0.5, H * 0.96, 420, 170, (180, 208, 124), 235)
    paste(img, ground, blur=10)

    petals = layer()
    rng = random.Random(21)
    for _ in range(46):
        x = rng.uniform(0, W)
        y = rng.uniform(H * 0.22, H * 0.92)
        r = rng.uniform(4, 11) * (0.5 + y / H)
        c = rng.choice([(250, 246, 226), (240, 232, 190), (232, 150, 120)])
        blob(petals, x, y, r, c, rng.randint(90, 170))
    paste(img, petals, blur=3)
    return img


# -------------------------------------------------------------- spiretip --
def spiretip():
    """The only cool, shaded green in the biome. A pine grove in mist."""
    img = canvas((188, 210, 202), (104, 140, 124).__class__((104, 140, 124))).convert("RGBA")
    back = layer()
    for i, x in enumerate([0.08, 0.24, 0.40, 0.58, 0.74, 0.92]):
        conifer(back, W * x, H * (0.74 + 0.02 * (i % 3)), H * (0.40 + 0.07 * (i % 4)),
                W * 0.30, (96, 130, 116), 190)
    paste(img, back, blur=11)

    mist = layer()
    d = ImageDraw.Draw(mist)
    for i in range(4):
        y = H * (0.52 + 0.11 * i)
        d.ellipse([-120, y - 40, W + 120, y + 40], fill=(214, 230, 224, 92))
    paste(img, mist, blur=22)

    near = layer()
    for x in [0.02, 0.30, 0.68, 0.97]:
        conifer(near, W * x, H * 0.92, H * 0.46, W * 0.34, (68, 104, 92), 210)
    paste(img, near, blur=5)

    floor = layer()
    hill(floor, W * 0.5, H * 1.02, 400, 120, (74, 102, 82), 230)
    paste(img, floor, blur=8)
    return img


# --------------------------------------------------------------- toadcap --
def toadcap():
    """Damp forest floor under a fallen log. The darkest of the five."""
    img = canvas((150, 154, 128), (86, 84, 68)).convert("RGBA")
    dapple = layer()
    rng = random.Random(7)
    for _ in range(14):
        x, y = rng.uniform(0, W), rng.uniform(H * 0.10, H * 0.62)
        blob(dapple, x, y, rng.uniform(28, 74), (226, 228, 176), rng.randint(30, 62))
    paste(img, dapple, blur=30)

    log = layer()
    d = ImageDraw.Draw(log)
    d.rounded_rectangle([-60, H * 0.42, W + 60, H * 0.66], radius=70,
                        fill=(104, 76, 54, 240))
    d.rounded_rectangle([-60, H * 0.42, W + 60, H * 0.50], radius=52,
                        fill=(126, 94, 66, 210))
    paste(img, log, blur=5)

    moss = layer()
    rng = random.Random(11)
    for _ in range(30):
        x = rng.uniform(-20, W + 20)
        y = rng.uniform(H * 0.40, H * 0.50)
        blob(moss, x, y, rng.uniform(9, 24), (118, 146, 80), rng.randint(90, 165))
    paste(img, moss, blur=6)

    floor = layer()
    hill(floor, W * 0.5, H * 1.04, 420, 150, (74, 60, 46), 240)
    rng = random.Random(3)
    for _ in range(22):
        x = rng.uniform(0, W)
        y = rng.uniform(H * 0.72, H * 0.98)
        blob(floor, x, y, rng.uniform(8, 20), (128, 92, 58), rng.randint(70, 140))
    paste(img, floor, blur=7)
    return img


# ------------------------------------------------------------- bellchime --
def bellchime():
    """The rarest thing in Greenhollow, so it gets dusk and hanging lanterns."""
    img = canvas((196, 172, 208), (110, 106, 156)).convert("RGBA")
    glow = layer()
    blob(glow, W * 0.5, H * 0.66, 250, (238, 190, 206), 120)
    paste(img, glow, blur=46)

    hills = layer()
    hill(hills, W * 0.30, H * 0.86, 300, 120, (92, 92, 138), 225)
    hill(hills, W * 0.80, H * 0.90, 260, 104, (78, 80, 124), 230)
    paste(img, hills, blur=9)

    lantern = layer()
    d = ImageDraw.Draw(lantern)
    for x, y in [(0.16, 0.30), (0.40, 0.20), (0.63, 0.32), (0.86, 0.22)]:
        d.line([(W * x, 0), (W * x, H * y)], fill=(70, 68, 104, 150), width=3)
        blob(lantern, W * x, H * y + 16, 20, (250, 220, 168), 235)
    paste(img, lantern, blur=4)

    flies = layer()
    rng = random.Random(41)
    for _ in range(34):
        x, y = rng.uniform(0, W), rng.uniform(H * 0.30, H * 0.94)
        blob(flies, x, y, rng.uniform(3, 7), (252, 238, 190), rng.randint(120, 220))
    paste(img, flies, blur=3)
    return img


SPECIES = {
    "nubkin": nubkin,
    "petalpip": petalpip,
    "spiretip": spiretip,
    "toadcap": toadcap,
    "bellchime": bellchime,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SPECIES.items():
        img = fn()
        vignette(img)
        settle(img)
        path = os.path.normpath(os.path.join(OUT, name + ".png"))
        img.convert("RGB").save(path, "PNG", optimize=True)
        print("%-10s %s  %d KB" % (name, path, os.path.getsize(path) // 1024))


if __name__ == "__main__":
    main()
