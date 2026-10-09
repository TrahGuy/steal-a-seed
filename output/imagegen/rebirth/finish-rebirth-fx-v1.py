"""Approved alpha/RGB export cleanup; no generation, crop, pad or grid changes."""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
SPECS = (
    ("rebirth-burst-v1", 1024, 4, "colour", 8, 70),
    ("rebirth-leaf-v1", 512, 2, "leaf", 8, 150),
    ("rebirth-sparkle-v1", 512, 2, "glow", 16, 150),
    ("rebirth-aura-v1", 1024, 4, "aura", 8, 100),
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def edge_weight(cell, clear):
    yy, xx = np.indices((cell, cell))
    distance = np.minimum.reduce((xx, yy, cell - 1 - xx, cell - 1 - yy))
    t = np.clip((distance - clear) / 8.0, 0, 1)
    return t * t * (3.0 - 2.0 * t)


def rgba_metrics(rgba, grid, clear):
    cell = rgba.shape[0] // grid
    records = []
    masks = np.ones((cell, cell), dtype=bool)
    masks[clear:cell-clear, clear:cell-clear] = False
    alphas = []
    for row in range(grid):
        for col in range(grid):
            frame = rgba[row*cell:(row+1)*cell, col*cell:(col+1)*cell]
            a = frame[:, :, 3]
            ys, xs = np.nonzero(a)
            bounds = None if not len(xs) else {
                "x": int(xs.min()), "y": int(ys.min()),
                "width": int(xs.max()-xs.min()+1),
                "height": int(ys.max()-ys.min()+1),
            }
            records.append({
                "frame": len(records)+1,
                "marginPixels": clear,
                "marginMaxAlpha": int(a[masks].max()),
                "maxAlpha": int(a.max()),
                "meanAlpha": round(float(a.mean()), 4),
                "nontransparentPixels": int(np.count_nonzero(a)),
                "bounds": bounds,
            })
            alphas.append(a.astype(np.float32))
    differences = [float(np.abs(alphas[i+1]-alphas[i]).mean()) for i in range(len(alphas)-1)]
    seam = float(np.abs(alphas[-1]-alphas[0]).mean())
    active = rgba[:, :, 3] > 0
    rgb = rgba[:, :, :3].astype(np.int16)
    spread = rgb.max(axis=2)-rgb.min(axis=2)
    return {
        "width": int(rgba.shape[1]), "height": int(rgba.shape[0]),
        "grid": [grid, grid], "cellSize": cell, "frameCount": grid*grid,
        "cornerAlpha": [int(rgba[y, x, 3]) for y, x in ((0, 0), (0, -1), (-1, 0), (-1, -1))],
        "maxAlpha": int(rgba[:, :, 3].max()),
        "maxRGBChannelSpread": int(spread[active].max()) if active.any() else 0,
        "minimumActiveRGB": int(rgb[active].min()) if active.any() else 0,
        "frames": records,
        "loopAlphaMeanAbsoluteDifference": round(seam, 4),
        "adjacentAlphaMeanAbsoluteDifferences": [round(x, 4) for x in differences],
        "maxAdjacentAlphaMeanAbsoluteDifference": round(max(differences), 4),
    }


def preview(image, grid, duration, output):
    # Extract frames in memory only, like the runtime; never crop final sheets.
    cell = image.width // grid
    background = (25, 37, 30)
    frames = []
    for row in range(grid):
        for col in range(grid):
            frame = image.crop((col*cell, row*cell, (col+1)*cell, (row+1)*cell))
            frame = frame.resize((192, 192), Image.Resampling.LANCZOS)
            canvas = Image.new("RGB", (192, 192), background)
            canvas.paste(frame, (0, 0), frame.getchannel("A"))
            frames.append(canvas)
    frames[0].save(output, save_all=True, append_images=frames[1:], duration=duration,
                   loop=0, disposal=2, optimize=False)


for stem, *_ in SPECS:
    for suffix in (".png", "-preview.gif"):
        target = ROOT / (stem+suffix)
        if target.exists():
            raise RuntimeError(f"Refusing to overwrite {target}")

all_results = []
for stem, size, grid, kind, clear, duration in SPECS:
    draft = ROOT / (stem+"-draft.png")
    original = ROOT / (stem+"-original.png")
    hashes_before = {draft.name: digest(draft), original.name: digest(original)}
    with Image.open(draft) as loaded:
        image = loaded.convert("RGBA")
    assert image.size == (size, size)
    rgba = np.array(image, dtype=np.uint8)
    rgb = rgba[:, :, :3].astype(np.float32)
    alpha = rgba[:, :, 3].astype(np.float32)
    luminance = rgb[:, :, 0]*0.2126 + rgb[:, :, 1]*0.7152 + rgb[:, :, 2]*0.0722
    if kind == "leaf":
        # White/light-grey only, preserving the existing leaf/vein silhouettes.
        neutral = np.clip(np.rint(luminance), 180, 255).astype(np.uint8)
        rgba[:, :, :3] = neutral[:, :, None]
    elif kind in ("glow", "aura"):
        # Preserve premultiplied light intensity while moving grey into alpha.
        # Pure-white texels eliminate a dark RGB matte when the runtime tints.
        alpha *= luminance / 255.0
        rgba[:, :, :3] = 255
        if kind == "aura":
            alpha *= 0.70
    cell = size // grid
    weights = edge_weight(cell, clear)
    for row in range(grid):
        for col in range(grid):
            region = alpha[row*cell:(row+1)*cell, col*cell:(col+1)*cell]
            region *= weights
            if kind == "colour":
                fade = {12: 0.70, 13: 0.55, 14: 0.40, 15: 0.25}.get(row*grid+col, 1.0)
                region *= fade
    alpha = np.rint(alpha)
    if kind == "aura":
        alpha = np.minimum(alpha, 178)  # 178/255 = 69.80%, never above70%.
    alpha[alpha < 4] = 0  # Remove imperceptible extraction specks, not geometry.
    rgba[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    rgba[rgba[:, :, 3] == 0] = 0
    result = rgba_metrics(rgba, grid, clear)
    assert result["cornerAlpha"] == [0, 0, 0, 0]
    assert all(frame["marginMaxAlpha"] == 0 for frame in result["frames"])
    assert result["width"] == size and result["height"] == size
    if kind != "colour":
        assert result["maxRGBChannelSpread"] == 0
        assert result["minimumActiveRGB"] >= 180
    if kind == "aura":
        assert result["maxAlpha"] <= 178
    clean = Image.fromarray(rgba)
    output = ROOT / (stem+".png")
    clean.save(output)
    gif = ROOT / (stem+"-preview.gif")
    preview(clean, grid, duration, gif)
    with Image.open(output) as reopened:
        assert np.array_equal(np.array(reopened.convert("RGBA")), rgba)
    for name, before in hashes_before.items():
        assert digest(ROOT/name) == before
    result.update({"stem": stem, "file": output.name, "preview": gif.name,
                   "sourceSHA256": hashes_before, "noCropOrPadding": True,
                   "cleanup": kind, "originalsUnchanged": True,
                   "pngSHA256": digest(output)})
    all_results.append(result)

print(json.dumps(all_results, separators=(",", ":")))
