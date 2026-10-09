"""Read-only QA/composited preview and packaging; no creative image editing."""
from pathlib import Path
import hashlib
import json
import zipfile
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
CACHE=Path("C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713")
PREVIEW=ROOT/"pod-rush-icons-v1-preview.png"
PACK=ROOT/"pod-rush-icons-v1-pack.zip"
for path in (PREVIEW,PACK):
    if path.exists():
        raise RuntimeError(f"Refusing to overwrite {path}")
try:
    font=ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf",19)
    small_font=ImageFont.truetype("C:/Windows/Fonts/arial.ttf",14)
except OSError:
    font=small_font=ImageFont.load_default()

names=("pod-rush","pod-rush-bronze","pod-rush-silver","pod-rush-gold")
labels=("POD RUSH","BRONZE","SILVER","GOLD")
files=[f"{n}-v1-{size}.png" for n in names for size in (512,32,24)]
files+=["pod-rush-medals-v1.png","pod-rush-medals-v1.crops.json",
        "pod-rush-v1.notes.md","pod-rush-medals-v1.notes.md",
        "pod-rush-icons-v1.prompt.md","pod-rush-icons-v1.used-prompts.md",
        "POD_RUSH_ICONS_V1_DELIVERABLES.md","pod-rush-icons-v1-preview.png"]
assert len(files)==20 and len(set(files))==20
manifest=json.loads((ROOT/"pod-rush-medals-v1.crops.json").read_text(encoding="utf-8"))
for i,rect in enumerate(manifest["rectangles"]):
    assert (rect["x"],rect["y"],rect["width"],rect["height"])==(i*512,0,512,512)
    assert rect["file"]==names[i+1]+"-v1-512.png"

preview=Image.new("RGB",(1024,420),(25,37,30))
draw=ImageDraw.Draw(preview)
draw.text((16,12),"POD RUSH v1 — ASSET PREVIEW ONLY",font=font,fill="white")
records=[]
for i,(name,label) in enumerate(zip(names,labels)):
    path=ROOT/f"{name}-v1-512.png"
    with Image.open(path) as image:
        assert image.format=="PNG" and image.mode=="RGBA" and image.size==(512,512)
        data=np.array(image)
        a=data[:,:,3]
        margin=np.ones(a.shape,dtype=bool);margin[32:-32,32:-32]=False
        assert not a[margin].any()
        ys,xs=np.nonzero(a>=8)
        radius=float(np.sqrt((xs-255.5)**2+(ys-255.5)**2).max())
        records.append({"file":path.name,"size":[512,512],"cornerAlpha":[0,0,0,0],
                        "outer32pxAlphaMax":0,"maxSignificantRadius":radius,
                        "sha256":hashlib.sha256(path.read_bytes()).hexdigest()})
        item=image.resize((180,180),Image.Resampling.LANCZOS)
        preview.paste(item,(i*256+38,44),item.getchannel("A"))
        for j,(small,bg) in enumerate(((64,(115,204,84)),(32,(106,187,225)),(24,(106,187,225)))):
            sample=image.resize((small,small),Image.Resampling.LANCZOS)
            tile=Image.new("RGB",(70,70),bg)
            off=(70-small)//2;tile.paste(sample,(off,off),sample.getchannel("A"))
            preview.paste(tile,(i*256+18+j*76,286))
    draw.text((i*256+30,232),label,font=font,fill="white")
    draw.text((i*256+20,260),"64px / 32px / 24px",font=small_font,fill="white")
    for small in (32,24):
        with Image.open(ROOT/f"{name}-v1-{small}.png") as image:
            assert image.mode=="RGBA" and image.size==(small,small)
            a=np.array(image)[:,:,3]
            assert not np.concatenate((a[0],a[-1],a[:,0],a[:,-1])).any()
with Image.open(ROOT/"pod-rush-medals-v1.png") as atlas:
    assert atlas.mode=="RGBA" and atlas.size==(1536,512)
    for i in range(3):
        a=np.array(atlas)[:,i*512:(i+1)*512,3]
        mask=np.ones(a.shape,dtype=bool);mask[32:-32,32:-32]=False
        assert not a[mask].any()
draw.text((16,388),"Transparent PNGs; backgrounds and labels above are preview-only. No uploads or game wiring.",font=small_font,fill="white")
preview.save(PREVIEW)

originals={}
for native,cached in (
    ("pod-rush-v1-original.png","exec-f351f7c0-1af3-4207-b6df-64ab14ddc7a2.png"),
    ("pod-rush-medals-v1-original.png","exec-3da73c42-38ee-4a77-bce5-0d99b0bcfb89.png")):
    assert (ROOT/native).read_bytes()==(CACHE/cached).read_bytes()
    originals[native]=hashlib.sha256((ROOT/native).read_bytes()).hexdigest()
for name in files:
    assert (ROOT/name).is_file() and (ROOT/name).parent.resolve()==ROOT.resolve()
with zipfile.ZipFile(PACK,"x",compression=zipfile.ZIP_DEFLATED) as archive:
    for name in files:
        archive.write(ROOT/name,name)
with zipfile.ZipFile(PACK,"r") as archive:
    assert archive.testzip() is None and set(archive.namelist())==set(files)
    for name in files:
        assert archive.read(name)==(ROOT/name).read_bytes()
print(json.dumps({"pack":str(PACK),"bytes":PACK.stat().st_size,"entries":20,
                  "preview":str(PREVIEW),"verified":records,
                  "originalsVerified":originals,"zipMembersVerified":True},separators=(",",":")))
