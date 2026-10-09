"""Read-only QA of final PNGs; compose previews and the explicitly requested spin copy."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
CONTACT = ROOT / "hatch-rebirth-extras-v1-preview.png"
SPIN = ROOT / "sunburst-rays-v1-spin-preview.gif"
for path in (CONTACT, SPIN):
    if path.exists():
        raise RuntimeError(f"Refusing to overwrite {path}")
try:
    font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 19)
    small_font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
except OSError:
    font = small_font = ImageFont.load_default()

names = ("hatch", "instant-hatch", "hatch-timer", "hatch-ready")
labels = ("HATCH", "INSTANT HATCH", "TIMER", "READY")
specs = [(f"{n}-v1-512.png", (512, 512)) for n in names]
specs += [("hatch-icons-v1.png", (2048, 512)),
          ("sunburst-rays-v1.png", (1024, 1024)), ("reborn-logo-v1.png", (1024, 384))]
records = []
loaded = {}
for name, size in specs:
    path = ROOT / name
    with Image.open(path) as image:
        assert image.format == "PNG" and image.mode == "RGBA" and image.size == size
        loaded[name] = image.copy()
    data = np.array(loaded[name])
    a = data[:, :, 3]
    edges = np.concatenate((a[0], a[-1], a[:, 0], a[:, -1]))
    assert not edges.any()
    if name == "sunburst-rays-v1.png":
        assert a.max() <= 204
        assert np.all(data[:, :, :3][a > 0] == 255)
    if name.endswith("-512.png"):
        margin = np.ones(a.shape, dtype=bool)
        margin[32:-32, 32:-32] = False
        assert not a[margin].any()
    records.append({"file": name, "size": list(size), "corners": [0, 0, 0, 0],
                    "edgeAlphaMax": int(edges.max()), "peakAlpha": int(a.max()),
                    "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})

preview = Image.new("RGB", (1024, 720), (25, 37, 30))
draw = ImageDraw.Draw(preview)
draw.text((16, 12), "HATCH + REBIRTH EXTRAS v1 — PREVIEW ONLY", font=font, fill="white")
for i, (name, label) in enumerate(zip(names, labels)):
    icon = loaded[f"{name}-v1-512.png"].resize((180, 180), Image.Resampling.LANCZOS)
    preview.paste(icon, (i * 256 + 38, 44), icon.getchannel("A"))
    draw.text((i * 256 + 30, 232), label, font=font, fill="white")
    draw.text((i * 256 + 20, 260), "64px / 32px / 24px on grass + sky", font=small_font, fill="white")
    for j, (small, background) in enumerate(((64, (115, 204, 84)), (32, (106, 187, 225)), (24, (106, 187, 225)))):
        item = loaded[f"{name}-v1-512.png"].resize((small, small), Image.Resampling.LANCZOS)
        canvas = Image.new("RGB", (70, 70), background)
        off = (70-small)//2
        canvas.paste(item, (off, off), item.getchannel("A"))
        preview.paste(canvas, (i*256+18+j*76, 286))

rays = loaded["sunburst-rays-v1.png"]
ray_preview = rays.resize((340, 340), Image.Resampling.LANCZOS)
preview.paste(ray_preview, (6, 372), ray_preview.getchannel("A"))
word = loaded["reborn-logo-v1.png"].resize((660, 248), Image.Resampling.LANCZOS)
preview.paste(word, (358, 416), word.getchannel("A"))
draw.text((16, 376), "TINTABLE RAYS", font=font, fill="white")
draw.text((370, 384), "REBORN! — SPELLING CHECKED", font=font, fill="white")
draw.text((370, 674), "Upload PNGs, not this composited preview. No game wiring performed.", font=small_font, fill="white")
preview.save(CONTACT)

small_ray = rays.resize((256, 256), Image.Resampling.LANCZOS)
spin_frames = []
for angle in range(0, 360, 10):
    rotated = small_ray.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False, center=(128, 128))
    canvas = Image.new("RGB", (256, 256), (25, 37, 30))
    canvas.paste(rotated, (0, 0), rotated.getchannel("A"))
    spin_frames.append(canvas)
spin_frames[0].save(SPIN, save_all=True, append_images=spin_frames[1:],
                    loop=0, duration=80, disposal=2, optimize=False)
with Image.open(SPIN) as gif:
    assert gif.n_frames == 36 and gif.size == (256, 256)
rgba = np.array(rays)
alpha = rgba[:, :, 3].astype(np.float64)
yy, xx = np.indices(alpha.shape)
centre = [float((xx*alpha).sum()/alpha.sum()), float((yy*alpha).sum()/alpha.sum())]
rotated_45 = np.array(rays.rotate(45, resample=Image.Resampling.BICUBIC, expand=False))[:, :, 3].astype(np.float64)
symmetry = float(np.abs(alpha-rotated_45).mean())
print(json.dumps({"validated": records, "preview": str(CONTACT), "spin": str(SPIN),
                  "spinFrames": 36, "raysAlphaCentroid": centre,
                  "rays45DegreeAlphaMeanAbsoluteDifference": symmetry,
                  "perfectRotationalSymmetryCertified": False}, separators=(",", ":")))
