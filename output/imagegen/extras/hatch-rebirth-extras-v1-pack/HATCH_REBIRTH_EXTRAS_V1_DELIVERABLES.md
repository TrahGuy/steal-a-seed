# Hatch + rebirth extras v1 — deliverables

## Upload-ready files

Upload these six separate PNGs as Images if accepted by the owner:

- `hatch-v1-512.png` — 512 × 512, Hatch / Hatch All.
- `instant-hatch-v1-512.png` — 512 × 512, Instant Hatch.
- `hatch-timer-v1-512.png` — 512 × 512, pod countdown.
- `hatch-ready-v1-512.png` — 512 × 512, Ready marker.
- `sunburst-rays-v1.png` — 1024 × 1024, white tintable ray texture, ≤80% alpha. Generated symmetry still needs owner acceptance; see caveat below.
- `reborn-logo-v1.png` — 1024 × 384, optional REBORN! header, spelling checked.

The requested `hatch-icons-v1.png` master atlas is 2048 × 512. Its companion `hatch-icons-v1.crops.json` records the final512px cells plus measured native source crops. Prefer individual icons for upload; a platform resizing an atlas changes its pixel offsets. No new uploaded IDs were obtained.

## Verification

All finals have genuine RGBA, corner/exterior edge alpha0. Icon cells have a430px longest art side (~84%) and verified fully clear32px border; hourglass stays naturally slender. Rays are pure-white RGB, alpha maximum204/255. Source originals are preserved, and the exact user brief is unchanged. 24/32px previews plus combined64px samples and a36-frame spinning copy are included.

Art is generated, not an exact mathematical drawing. Hatch has four accent ticks instead of three and the timer cap has two leaves instead of one. Rays have sixteen sharp tips but slight generated shape/brightness asymmetry; pixel-perfect rotational equality is NOT certified. Review the supplied spin copy for subtle breathing before use. These differences are documented, not silently claimed to meet the brief perfectly.

No game implementation, Image uploads/IDs, price/product changes, receipt code, IsLoaded, Studio/Play or publish was performed. The source brief's Phase1/celebration plan is context only, not a request to implement or alter it. Existing game code and peer work are preserved.

## Files in the pack

- Seven final PNGs (six upload files plus master atlas).
- Eight small PNGs (four icons at32px and24px).
- The crop manifest, three asset notes, unchanged owner brief and exact six generation/edit prompts.
- `hatch-rebirth-extras-v1-preview.png` — labelled composited preview, not an upload asset.
- `sunburst-rays-v1-spin-preview.gif` — rotating review copy, not an upload asset.
- This README.

Native originals and helpers remain in the project folder outside the pack. Image creation used the built-in tool; requested exact-size/crop/alpha preparation uses the project PowerShell export workflow, and Python only renders QA/spinning copies and packages files. No CLI/API generation fallback.

## Selected native generation outputs

- Atlas: exec-962162b5-653f-4ed3-9904-40258aed8aca.png.
- Rays: exec-6a0b49d4-baeb-49ce-b1bf-6b9115e53cd1.png.
- Logo: exec-8e04fd32-86da-44dc-ac6e-2fee5a0747b2.png.

They were copied byte-for-byte into the three `*-original.png` workspace files. Initial rejected generations remain in the built-in generation cache; all exact prompts are recorded.
