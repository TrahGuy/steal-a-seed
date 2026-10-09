"""Validate and package existing final FX PNGs; no image generation or editing."""
from pathlib import Path
import hashlib
import json
import zipfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
SPECS = (
    ("burst", 1024, 4, 8, (0, 3, 9, 15)),
    ("leaf", 512, 2, 8, (0, 1, 2, 3)),
    ("sparkle", 512, 2, 16, (0, 1, 2, 3)),
    ("aura", 1024, 4, 8, (0, 4, 10, 15)),
)
TARGET = ROOT / "rebirth-fx-v1-pack.zip"
CONTACT = ROOT / "rebirth-fx-v1-preview.png"
for target in (TARGET, CONTACT):
    if target.exists():
        raise RuntimeError(f"Refusing to overwrite {target}")

try:
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 17)
    small_font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
except OSError:
    font = small_font = ImageFont.load_default()

contact = Image.new("RGB", (800, 790), (25, 37, 30))
draw = ImageDraw.Draw(contact)
draw.text((16, 12), "REBIRTH FX v1 — PREVIEW ONLY; upload the four transparent PNG sheets", font=font, fill="white")
records = []
files = []
for row, (kind, size, grid, margin, samples) in enumerate(SPECS):
    stem = f"rebirth-{kind}-v1"
    path = ROOT / f"{stem}.png"
    with Image.open(path) as loaded:
        assert loaded.format == "PNG" and loaded.mode == "RGBA"
        image = loaded.copy()
    assert image.size == (size, size)
    data = np.array(image)
    a = data[:, :, 3]
    assert all(a[y, x] == 0 for y, x in ((0, 0), (0, -1), (-1, 0), (-1, -1)))
    active = a > 0
    if kind != "burst":
        rgb = data[:, :, :3]
        assert np.all(rgb[active, 0] == rgb[active, 1])
        assert np.all(rgb[active, 1] == rgb[active, 2])
    if kind in ("sparkle", "aura"):
        assert np.all(data[:, :, :3][active] == 255)
    if kind == "aura":
        assert a.max() <= 178

    frames = []
    for index in range(grid * grid):
        x, y = (index % grid) * 256, (index // grid) * 256
        # Runtime-like frame extraction in memory only; upload sheets stay intact.
        frame = image.crop((x, y, x + 256, y + 256))
        frame_a = np.array(frame.getchannel("A"))
        assert not frame_a[:margin, :].any()
        assert not frame_a[-margin:, :].any()
        assert not frame_a[:, :margin].any()
        assert not frame_a[:, -margin:].any()
        frames.append(frame)
    preview = ROOT / f"{stem}-preview.gif"
    with Image.open(preview) as gif:
        assert gif.size == (192, 192)
        assert gif.n_frames == grid * grid

    yy = 46 + row * 150
    draw.text((16, yy + 28), kind.upper(), font=font, fill="white")
    playback = "Play once" if kind in ("burst", "sparkle") else "Loop review pending"
    draw.text((16, yy + 54), playback, font=small_font, fill=(179, 214, 184))
    draw.text((16, yy + 78), f"{size}px / {grid}x{grid}", font=small_font, fill=(179, 214, 184))
    for col, index in enumerate(samples):
        frame = frames[index].resize((128, 128), Image.Resampling.LANCZOS)
        xx = 180 + col * 150
        contact.paste(frame, (xx, yy), frame.getchannel("A"))
        draw.text((xx + 38, yy + 130), f"Frame {index + 1}", font=small_font, fill=(179, 214, 184))

    # Deliberately show one representative frame at its true 64px and 32px size.
    sample = frames[samples[1] if kind == "burst" else (2 if kind == "sparkle" else 0)]
    xx = row * 200 + 10
    for col, small in enumerate((64, 32)):
        tile = Image.new("RGB", (88, 88), (97, 185, 224))
        item = sample.resize((small, small), Image.Resampling.LANCZOS)
        offset = (88 - small) // 2
        tile.paste(item, (offset, offset), item.getchannel("A"))
        contact.paste(tile, (xx + col * 92, 674))
    draw.text((xx, 650), f"{kind}: 64px / 32px", font=small_font, fill="white")
    record = {
        "file": path.name, "size": list(image.size), "frames": grid * grid,
        "clearCellMargin": margin, "cornerAlpha": 0, "peakAlpha": int(a.max()),
        "gifFrames": grid * grid,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }
    records.append(record)
    files.extend((path, ROOT / f"{stem}.notes.md", preview))

draw.text((16, 770), "Dark background = composited alpha; blue panels = true small-size samples. Not a runtime certification.", font=small_font, fill="white")
contact.save(CONTACT)
files.extend((CONTACT, ROOT / "rebirth-fx-v1.prompt.md", ROOT / "rebirth-fx-v1.used-prompts.md", ROOT / "REBIRTH_FX_V1_DELIVERABLES.md"))
assert len(files) == 16 and len(set(files)) == 16
for path in files:
    assert path.is_file() and path.parent.resolve() == ROOT.resolve()
with zipfile.ZipFile(TARGET, "x", compression=zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, path.name)
with zipfile.ZipFile(TARGET, "r") as archive:
    assert archive.testzip() is None
    assert set(archive.namelist()) == {p.name for p in files}
    for path in files:
        assert archive.read(path.name) == path.read_bytes()
print(json.dumps({"pack": str(TARGET), "bytes": TARGET.stat().st_size, "entries": len(files), "preview": str(CONTACT), "validated": records}, separators=(",", ":")))
