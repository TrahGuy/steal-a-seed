"""Read-only alpha/grid QA plus composited animation and contact previews."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
PNG=ROOT/"wheel-jackpot-burst-v1.png"
GIF=ROOT/"wheel-jackpot-burst-v1-preview.gif"
CONTACT=ROOT/"wheel-jackpot-burst-v1-preview.png"
for path in (GIF,CONTACT):
    if path.exists():
        raise RuntimeError(f"Refusing to overwrite {path}")
with Image.open(PNG) as image:
    assert image.mode=="RGBA" and image.size==(1024,1024)
    sheet=image.copy()
rgba=np.array(sheet)
frames=[]
stats=[]
mask=np.ones((256,256),dtype=bool)
mask[32:-32,32:-32]=False
for i in range(16):
    x,y=(i%4)*256,(i//4)*256
    data=rgba[y:y+256,x:x+256]
    alpha=data[:,:,3]
    assert not alpha[mask].any()
    frame=Image.fromarray(data)
    frames.append(frame)
    stats.append({"frame":i+1,"margin32pxMaxAlpha":0,
                  "peakAlpha":int(alpha.max()),"meanAlpha":float(alpha.mean()),
                  "nontransparentPixels":int(np.count_nonzero(alpha))})
assert all(rgba[y,x,3]==0 for y,x in ((0,0),(0,-1),(-1,0),(-1,-1)))
assert stats[-1]["peakAlpha"]<=32
original=ROOT/"wheel-jackpot-burst-v1-original.png"
cached=Path("C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-fd96ad08-ec8a-40ba-9168-24609d637072.png")
assert original.read_bytes()==cached.read_bytes()

animations=[]
for frame in frames:
    item=frame.resize((256,256),Image.Resampling.LANCZOS)
    canvas=Image.new("RGB",(256,256),(25,37,30))
    canvas.paste(item,(0,0),item.getchannel("A"))
    animations.append(canvas)
animations[0].save(GIF,save_all=True,append_images=animations[1:],
                    duration=80,loop=0,disposal=2,optimize=False)
with Image.open(GIF) as gif:
    assert gif.n_frames==16 and gif.size==(256,256)
try:
    font=ImageFont.truetype("C:/Windows/Fonts/arial.ttf",15)
except OSError:
    font=ImageFont.load_default()
contact=Image.new("RGB",(640,264),(25,37,30))
draw=ImageDraw.Draw(contact)
draw.text((12,8),"WHEEL JACKPOT BURST — PREVIEW ONLY, play once in game",font=font,fill="white")
for column,index in enumerate((0,3,7,15)):
    item=frames[index].resize((128,128),Image.Resampling.LANCZOS)
    x=column*160+16
    contact.paste(item,(x,40),item.getchannel("A"))
    draw.text((x+25,176),f"Frame {index+1}",font=font,fill="white")
for i,small in enumerate((64,32)):
    frame=frames[5].resize((small,small),Image.Resampling.LANCZOS)
    contact.paste(frame,(16+i*100,198),frame.getchannel("A"))
draw.text((222,216),"64px / 32px samples. PNG sheet is transparent.",font=font,fill="white")
contact.save(CONTACT)
print(json.dumps({"file":str(PNG),"size":[1024,1024],"grid":[4,4],"frames":16,
                  "cellSize":256,"clearMargin":32,"cornerAlpha":[0,0,0,0],
                  "frameChecks":stats,"preview":str(GIF),"gifFrames":16,
                  "gifDurationPerFrameMs":80,"originalUnchanged":True,
                  "originalSHA256":hashlib.sha256(original.read_bytes()).hexdigest(),
                  "finalSHA256":hashlib.sha256(PNG.read_bytes()).hexdigest()},separators=(",",":")))
