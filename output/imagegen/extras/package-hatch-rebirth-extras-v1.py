"""Package task-owned deliverables only; verify original-copy identity and ZIP members."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parent
CACHE = Path("C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713")
source_pairs = (
    ("hatch-icons-v1-original.png", "exec-962162b5-653f-4ed3-9904-40258aed8aca.png"),
    ("sunburst-rays-v1-original.png", "exec-6a0b49d4-baeb-49ce-b1bf-6b9115e53cd1.png"),
    ("reborn-logo-v1-original.png", "exec-8e04fd32-86da-44dc-ac6e-2fee5a0747b2.png"),
)
originals = {}
for copied, source in source_pairs:
    assert (ROOT/copied).read_bytes() == (CACHE/source).read_bytes()
    originals[copied] = hashlib.sha256((ROOT/copied).read_bytes()).hexdigest()
names = ("hatch", "instant-hatch", "hatch-timer", "hatch-ready")
files = [f"{n}-v1-{size}.png" for n in names for size in (512, 32, 24)]
files += ["hatch-icons-v1.png", "sunburst-rays-v1.png", "reborn-logo-v1.png",
          "hatch-icons-v1.crops.json", "hatch-icons-v1.notes.md",
          "sunburst-rays-v1.notes.md", "reborn-logo-v1.notes.md",
          "hatch-rebirth-extras-v1.prompt.md", "hatch-rebirth-extras-v1.used-prompts.md",
          "HATCH_REBIRTH_EXTRAS_V1_DELIVERABLES.md",
          "hatch-rebirth-extras-v1-preview.png", "sunburst-rays-v1-spin-preview.gif"]
assert len(files) == 24 and len(set(files)) == 24
manifest = json.loads((ROOT/"hatch-icons-v1.crops.json").read_text(encoding="utf-8"))
assert manifest["width"] == 2048 and manifest["height"] == 512
for i, rect in enumerate(manifest["rectangles"]):
    assert (rect["x"], rect["y"], rect["width"], rect["height"]) == (i*512, 0, 512, 512)
    assert rect["file"] == names[i]+"-v1-512.png"
for name in files:
    path = ROOT/name
    assert path.is_file() and path.parent.resolve() == ROOT.resolve()
pack = ROOT/"hatch-rebirth-extras-v1-pack.zip"
with zipfile.ZipFile(pack, "x", compression=zipfile.ZIP_DEFLATED) as archive:
    for name in files:
        archive.write(ROOT/name, name)
with zipfile.ZipFile(pack, "r") as archive:
    assert archive.testzip() is None
    assert set(archive.namelist()) == set(files)
    for name in files:
        assert archive.read(name) == (ROOT/name).read_bytes()
print(json.dumps({"pack": str(pack), "entries": len(files), "bytes": pack.stat().st_size,
                  "originalsVerified": originals, "zipMembersVerified": True}, separators=(",", ":")))
