from pathlib import Path
import json
import zipfile

root=Path(__file__).resolve().parent
files=('wheel-jackpot-burst-v1.png','wheel-jackpot-burst-v1-preview.gif','wheel-jackpot-burst-v1-preview.png','wheel-jackpot-burst-v1.notes.md','wheel-jackpot-burst-v1.prompt.md')
for name in files:
    assert (root/name).is_file() and (root/name).parent.resolve()==root.resolve()
pack=root/'wheel-jackpot-burst-v1-pack.zip'
with zipfile.ZipFile(pack,'x',compression=zipfile.ZIP_DEFLATED) as z:
    for name in files:
        z.write(root/name,name)
with zipfile.ZipFile(pack,'r') as z:
    assert z.testzip() is None and set(z.namelist())==set(files)
    for name in files:
        assert z.read(name)==(root/name).read_bytes()
print(json.dumps({'pack':str(pack),'bytes':pack.stat().st_size,'entries':len(files),'verified':True}))
