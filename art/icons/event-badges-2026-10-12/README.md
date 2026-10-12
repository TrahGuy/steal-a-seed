# Studded round event badges — 2026-10-12

Seven event badges, including Server Luck as expressly requested. Artwork only: no uploads, wiring, source/GameConfig changes, Studio, publication or live asset replacement.

## Files

- event-enchanted-mist.png: 512 × 512 RGBA master here; matching 512 × 512 tight copy at D:/KAPE/Steal an Artifact/art/icons/tight/event-enchanted-mist.png. Corner alpha 0 and edge alpha 0 in both. Main symbol reads at 24px in the rendered comparison sheet.
- event-rain.png: 512 × 512 RGBA master here; matching 512 × 512 tight copy at D:/KAPE/Steal an Artifact/art/icons/tight/event-rain.png. Corner alpha 0 and edge alpha 0 in both. Main symbol reads at 24px in the rendered comparison sheet.
- event-thunderstorm.png: 512 × 512 RGBA master here; matching 512 × 512 tight copy at D:/KAPE/Steal an Artifact/art/icons/tight/event-thunderstorm.png. Corner alpha 0 and edge alpha 0 in both. Main symbol reads at 24px in the rendered comparison sheet.
- event-disco.png: 512 × 512 RGBA master here; matching 512 × 512 tight copy at D:/KAPE/Steal an Artifact/art/icons/tight/event-disco.png. Corner alpha 0 and edge alpha 0 in both. Main symbol reads at 24px in the rendered comparison sheet.
- event-ticket-shower.png: 512 × 512 RGBA master here; matching 512 × 512 tight copy at D:/KAPE/Steal an Artifact/art/icons/tight/event-ticket-shower.png. Corner alpha 0 and edge alpha 0 in both. Main symbol reads at 24px in the rendered comparison sheet.
- event-pod-rush.png: 512 × 512 RGBA master here; matching 512 × 512 tight copy at D:/KAPE/Steal an Artifact/art/icons/tight/event-pod-rush.png. Corner alpha 0 and edge alpha 0 in both. Main symbol reads at 24px in the rendered comparison sheet.
- event-server-luck.png: 512 × 512 RGBA master here; matching 512 × 512 tight copy at D:/KAPE/Steal an Artifact/art/icons/tight/event-server-luck.png. Corner alpha 0 and edge alpha 0 in both. Main symbol reads at 24px in the rendered comparison sheet.

- sheet.png: 1160 × 954 RGB comparison. Every tight badge at true 64, 40, 30 and 24px on sky blue, field green and dark night backgrounds. Last two columns are the existing flat rain-256/disco-256 icons. Do not upload this sheet as an icon.
- originals/: byte-identical 1254 × 1254 RGBA native copies. Hashes and default generated-image source paths are recorded in checks.json.
- generation-manifest.json: exact prompts, reference paths, original paths and refinement provenance.
- export-badges.ps1: mechanical export/QA helper; not game code.
- checks.json: dimensions, all-alpha bounds, corner/edge alpha, fitted-disc checks and visual-readability scope.

## Small-size visual check

Inspected the full-size renders and actual 64/40/30/24px sheet. All seven primary symbols remain distinct in this local preview: mint Dewberry, white cloud/blue drops, gold lightning, mirrored disco ball, green-star ticket, yellow-green pod/red-white stopwatch and gold-edged green clover. At 24px, the smallest moon/glints, mirror tiles, notes and clock-hand details soften. The badge's colour and main silhouette carry recognition; this is not a live HUD/mobile/Studio acceptance test.

## Transparent-edge cleanup and checks

The generator left near-invisible low-alpha specks outside the discs. The owner explicitly approved mechanical exterior-only cleanup and recentering. Native originals stay unchanged. Final exports are recentered from the visible disc, then only pixels outside the centred circular boundary are cleared; illustration pixels inside that boundary are not painted or restyled. checks.json records corner/edge alpha and the strict all-alpha count outside each configured circle. All fourteen PNGs pass: zero corner/edge alpha and exactly zero nonzero-alpha pixels outside the configured circles, with no tolerance in that strict check.

## Export method

Genuine alpha requested from the built-in image generator and retained. Selected native originals preserved byte-for-byte. Proportional high-quality bicubic exports normalize the visible badge framing to approximately 92% of a 512px master and create separate Fit copies with approximately 2% padding per side relative to the disc. Framing uses the alpha>=16 visible-disc envelope rather than faint stray alpha specks; this threshold is for measurement only, not a global alpha erase. The explicitly approved circular exterior mask removes only pixels outside the intended disc. No illustration was rebuilt with code. The badges are reference-matched redraws, not pixel-identical copies of the old flat symbols or exact identical ring pixels.

Imagegen skill guided one built-in generation call per badge, alpha preservation and reference matching. Enchanted Mist had one successful refinement to enlarge its studs, plus one failed connection attempt; six additional badges used the refined Mist geometry as a family reference. Total: eight successful built-in calls, one failed call. No API/CLI fallback used.

## Exact prompts and provenance

### event-enchanted-mist.png

Selected generated original: C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-3dab2e01-f153-4e1b-b7b8-ad17ea2d17f7.png

Reference images: D:/KAPE/Steal an Artifact/art/textures/mist-studs-2026-10-11/studs-enchanted-mist-v1.png; D:/KAPE/Steal an Artifact/art/textures/colorful-studs-2026-10-04/studs-coral-red-v1.png

Prompt used:

Use case: stylized-concept. Asset type: production-ready small Roblox event HUD badge, one standalone square 512x512 transparent PNG.
Primary request: ONE circular studded event badge, no text.
Badge geometry: perfectly round disc centered on the square, diameter exactly about 92% of canvas width, with a thick solid near-black navy outer outline ring and one thin lighter inner rim. Orthographic frontal 2D sticker icon, not a perspective coin. Fill the disc with a regular aligned grid of few LARGE raised SQUARE toy-plastic studs, approximately 5 to 6 studs across its diameter. Subtle upper-left bevel light and tiny lower-right relief shadows, clearly square rather than dots. Gentle darkening behind the central object for silhouette contrast. No busy noise. Use consistent polished glossy game-icon shading.
Object layout: the whole event symbol group is centered and occupies about 64% of the disc width. It has a bold dark outline, simple recognizable silhouette and glossy upper-left highlights. Symbols can slightly overlap the thin inner rim, but EVERY shape, sparkle, mist swirl, reflection and shadow stays INSIDE the outer dark circular ring. No shape may stick out of the circular disc.
Transparency is essential: outside the perfectly circular disc, absolutely empty genuine alpha=0 pixels, no square plate, background colour, drop shadow, external glow, checkerboard, detached speckles or artwork. All four corners transparent. Disc itself opaque. Leave about 4% canvas margin on each side.
Small-scale requirement: easily distinguishable at only 24px. Prioritize big solid silhouette, thick clean outlines and strong colour contrast, keeping secondary details minimal. No letters, numbers, text, prices, UI, logos, Robux marks, watermark, border frame or collage. Make exactly one badge, not a sheet.

Reference roles: image 1 is only the event colour palette reference; image 2 is ONLY the raised square-stud geometry and toy-plastic bevel reference. Neither square reference texture is an edit target or a background outside the disc. Use far fewer, larger studs than those textures.
Disc palette: deep forest-teal at the top fading to dusky blue-violet below, with soft mint bevel highlights; match the supplied Mist palette, not vivid rainbow.
Central object: one plump round glowing mint-green Dewberry with a dewy glossy sheen, one small green leaf at the top, wrapped by ONE soft simple mint mist swirl. Place one tiny pale crescent moon beside the berry. Dewberry is a fruit, no face, no eyes or limbs. The berry is dominant; the swirl and crescent are minimal secondary identifiers.

First draft original (retained): C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-192e40a6-f7b6-406a-ab1d-2ed55d67a1b7.png

Selected source above is the refined badge. Refinement prompt (one failed connection, then successful retry):

Edit this round Enchanted Mist event badge only to improve the small-size geometry. Preserve the exact circular disc, outline ring, transparent exterior, teal-to-violet palette, mint Dewberry, one leaf, crescent moon, mist swirl, glossy shading and overall identity.
CHANGE ONLY TWO THINGS: (1) replace the background stud grid with MUCH FEWER, LARGER square studs, precisely SIX studs across the full diameter at the middle horizontal line, with the same grid pitch in both directions, about six rows. Do not use the current eight-stud grid. The spacing should be the entire disc diameter divided by six. Keep the square raised plastic bevels. (2) Scale the entire central berry/leaf/moon/swirl group slightly smaller, centered, so its total width is about 66% of the disc diameter, allowing more of the large studs to show. Do not add details.
All artwork and lighting stays INSIDE the outer perfectly circular outline. Background outside disc genuinely transparent alpha=0, no glow, shadows, dots or checkerboard outside. Keep a square canvas, centred disc about92% canvas width, no text, numbers, logos or collage. One production icon only.

### event-rain.png

Selected generated original: C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-0f492d2c-d849-493d-9ae9-f55ccd3929da.png

Reference images: D:/KAPE/Steal an Artifact/art/icons/boosts/rain-256.png; C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-3dab2e01-f153-4e1b-b7b8-ad17ea2d17f7.png

Prompt used:

Use case: stylized-concept. Asset type: production-ready small Roblox event HUD badge, one standalone square 512x512 transparent PNG.
Primary request: ONE circular studded event badge, no text.
Badge geometry: perfectly round disc centered on the square, diameter exactly about 92% of canvas width, with a thick solid near-black navy outer outline ring and one thin lighter inner rim. Orthographic frontal 2D sticker icon, not a perspective coin. Fill the disc with a regular aligned grid of few LARGE raised SQUARE toy-plastic studs, SIX large square studs across its diameter, six columns at the widest row and matching vertical pitch, not eight or twelve. Subtle upper-left bevel light and tiny lower-right relief shadows, clearly square rather than dots. Gentle darkening behind the central object for silhouette contrast. No busy noise. Use consistent polished glossy game-icon shading.
Object layout: the whole event symbol group is centered and occupies about 64% of the disc width. It has a bold dark outline, simple recognizable silhouette and glossy upper-left highlights. Symbols can slightly overlap the thin inner rim, but EVERY shape, sparkle, mist swirl, reflection and shadow stays INSIDE the outer dark circular ring. No shape may stick out of the circular disc.
Transparency is essential: outside the perfectly circular disc, absolutely empty genuine alpha=0 pixels, no square plate, background colour, drop shadow, external glow, checkerboard, detached speckles or artwork. All four corners transparent. Disc itself opaque. Leave about 4% canvas margin on each side.
Small-scale requirement: easily distinguishable at only 24px. Prioritize big solid silhouette, thick clean outlines and strong colour contrast, keeping secondary details minimal. No letters, numbers, text, prices, UI, logos, Robux marks, watermark, border frame or collage. Make exactly one badge, not a sheet.

Reference roles: image 1 is the existing Rain object identity reference; keep that event symbol's design, colours and recognizable silhouette. Image 2 is ONLY our approved round-badge geometry reference: match its outer navy outline thickness, thin inner rim, large six-across square-stud spacing and flat frontal layout. Do NOT use its Dewberry, leaf, moon, swirl or event palette. Do not copy the exterior of image1. Redraw the image1 event object centered on the image2 badge design in the following colour.
Disc palette: bright sky-blue disc with slightly lighter cyan-blue stud highlights.
Central object: the existing cream-white and pale blue soft puffy rain cloud with THREE glossy vivid blue water drops below. Keep its exact cloud silhouette, colour family, count and droplet shapes from the source reference. Add no sun, face, umbrella, lightning or new symbol.
Match the family, with no new symbols. Keep the whole symbol group at about64-68% disc width, all completely inside the circle and separated from the studs by thick dark outline.

### event-thunderstorm.png

Selected generated original: C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-e1144c30-cd42-491d-989a-61fc2aa0d9cb.png

Reference images: D:/KAPE/Steal an Artifact/art/icons/boosts/thunderstorm-256.png; C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-3dab2e01-f153-4e1b-b7b8-ad17ea2d17f7.png

Prompt used:

Use case: stylized-concept. Asset type: production-ready small Roblox event HUD badge, one standalone square 512x512 transparent PNG.
Primary request: ONE circular studded event badge, no text.
Badge geometry: perfectly round disc centered on the square, diameter exactly about 92% of canvas width, with a thick solid near-black navy outer outline ring and one thin lighter inner rim. Orthographic frontal 2D sticker icon, not a perspective coin. Fill the disc with a regular aligned grid of few LARGE raised SQUARE toy-plastic studs, SIX large square studs across its diameter, six columns at the widest row and matching vertical pitch, not eight or twelve. Subtle upper-left bevel light and tiny lower-right relief shadows, clearly square rather than dots. Gentle darkening behind the central object for silhouette contrast. No busy noise. Use consistent polished glossy game-icon shading.
Object layout: the whole event symbol group is centered and occupies about 64% of the disc width. It has a bold dark outline, simple recognizable silhouette and glossy upper-left highlights. Symbols can slightly overlap the thin inner rim, but EVERY shape, sparkle, mist swirl, reflection and shadow stays INSIDE the outer dark circular ring. No shape may stick out of the circular disc.
Transparency is essential: outside the perfectly circular disc, absolutely empty genuine alpha=0 pixels, no square plate, background colour, drop shadow, external glow, checkerboard, detached speckles or artwork. All four corners transparent. Disc itself opaque. Leave about 4% canvas margin on each side.
Small-scale requirement: easily distinguishable at only 24px. Prioritize big solid silhouette, thick clean outlines and strong colour contrast, keeping secondary details minimal. No letters, numbers, text, prices, UI, logos, Robux marks, watermark, border frame or collage. Make exactly one badge, not a sheet.

Reference roles: image 1 is the existing Thunderstorm object identity reference; keep that event symbol's design, colours and recognizable silhouette. Image 2 is ONLY our approved round-badge geometry reference: match its outer navy outline thickness, thin inner rim, large six-across square-stud spacing and flat frontal layout. Do NOT use its Dewberry, leaf, moon, swirl or event palette. Do not copy the exterior of image1. Redraw the image1 event object centered on the image2 badge design in the following colour.
Disc palette: deep indigo-navy disc with lighter cool indigo stud highlights.
Central object: the existing dark slate-lavender puffy storm cloud, large angular golden-yellow lightning bolt in front and TWO glossy bright blue rain drops beneath it. Keep the recognizable source cloud silhouette, gold bolt and droplet group. Gold bolt should dominate clearly at 24px.
Match the family, with no new symbols. Keep the whole symbol group at about64-68% disc width, all completely inside the circle and separated from the studs by thick dark outline.

### event-disco.png

Selected generated original: C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-d1e69232-5c25-4460-bed5-4d5114abfdc3.png

Reference images: D:/KAPE/Steal an Artifact/art/icons/boosts/disco-256.png; C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-3dab2e01-f153-4e1b-b7b8-ad17ea2d17f7.png

Prompt used:

Use case: stylized-concept. Asset type: production-ready small Roblox event HUD badge, one standalone square 512x512 transparent PNG.
Primary request: ONE circular studded event badge, no text.
Badge geometry: perfectly round disc centered on the square, diameter exactly about 92% of canvas width, with a thick solid near-black navy outer outline ring and one thin lighter inner rim. Orthographic frontal 2D sticker icon, not a perspective coin. Fill the disc with a regular aligned grid of few LARGE raised SQUARE toy-plastic studs, SIX large square studs across its diameter, six columns at the widest row and matching vertical pitch, not eight or twelve. Subtle upper-left bevel light and tiny lower-right relief shadows, clearly square rather than dots. Gentle darkening behind the central object for silhouette contrast. No busy noise. Use consistent polished glossy game-icon shading.
Object layout: the whole event symbol group is centered and occupies about 64% of the disc width. It has a bold dark outline, simple recognizable silhouette and glossy upper-left highlights. Symbols can slightly overlap the thin inner rim, but EVERY shape, sparkle, mist swirl, reflection and shadow stays INSIDE the outer dark circular ring. No shape may stick out of the circular disc.
Transparency is essential: outside the perfectly circular disc, absolutely empty genuine alpha=0 pixels, no square plate, background colour, drop shadow, external glow, checkerboard, detached speckles or artwork. All four corners transparent. Disc itself opaque. Leave about 4% canvas margin on each side.
Small-scale requirement: easily distinguishable at only 24px. Prioritize big solid silhouette, thick clean outlines and strong colour contrast, keeping secondary details minimal. No letters, numbers, text, prices, UI, logos, Robux marks, watermark, border frame or collage. Make exactly one badge, not a sheet.

Reference roles: image 1 is the existing Disco object identity reference; keep that event symbol's design, colours and recognizable silhouette. Image 2 is ONLY our approved round-badge geometry reference: match its outer navy outline thickness, thin inner rim, large six-across square-stud spacing and flat frontal layout. Do NOT use its Dewberry, leaf, moon, swirl or event palette. Do not copy the exterior of image1. Redraw the image1 event object centered on the image2 badge design in the following colour.
Disc palette: hot magenta fading to purple, with bright pink-violet stud highlights.
Central object: the same silver mirrored disco ball with large cyan, pink, blue and white tile reflections, small gold hanging loop/cap, pink music note lower-left and cyan music note lower-right, and the source's few simple gold glints. Preserve the recognizable ball and TWO notes. Use only a few readable broad mirror tiles, not lots of tiny noise.
Match the family, with no new symbols. Keep the whole symbol group at about64-68% disc width, all completely inside the circle and separated from the studs by thick dark outline.

### event-ticket-shower.png

Selected generated original: C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-032f6145-835b-4e85-850b-2b62be712877.png

Reference images: D:/KAPE/Steal an Artifact/art/icons/inventory/spin_tickets-256.png; C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-3dab2e01-f153-4e1b-b7b8-ad17ea2d17f7.png

Prompt used:

Use case: stylized-concept. Asset type: production-ready small Roblox event HUD badge, one standalone square 512x512 transparent PNG.
Primary request: ONE circular studded event badge, no text.
Badge geometry: perfectly round disc centered on the square, diameter exactly about 92% of canvas width, with a thick solid near-black navy outer outline ring and one thin lighter inner rim. Orthographic frontal 2D sticker icon, not a perspective coin. Fill the disc with a regular aligned grid of few LARGE raised SQUARE toy-plastic studs, SIX large square studs across its diameter, six columns at the widest row and matching vertical pitch, not eight or twelve. Subtle upper-left bevel light and tiny lower-right relief shadows, clearly square rather than dots. Gentle darkening behind the central object for silhouette contrast. No busy noise. Use consistent polished glossy game-icon shading.
Object layout: the whole event symbol group is centered and occupies about 64% of the disc width. It has a bold dark outline, simple recognizable silhouette and glossy upper-left highlights. Symbols can slightly overlap the thin inner rim, but EVERY shape, sparkle, mist swirl, reflection and shadow stays INSIDE the outer dark circular ring. No shape may stick out of the circular disc.
Transparency is essential: outside the perfectly circular disc, absolutely empty genuine alpha=0 pixels, no square plate, background colour, drop shadow, external glow, checkerboard, detached speckles or artwork. All four corners transparent. Disc itself opaque. Leave about 4% canvas margin on each side.
Small-scale requirement: easily distinguishable at only 24px. Prioritize big solid silhouette, thick clean outlines and strong colour contrast, keeping secondary details minimal. No letters, numbers, text, prices, UI, logos, Robux marks, watermark, border frame or collage. Make exactly one badge, not a sheet.

Reference roles: image 1 is the existing Ticket Shower object identity reference; keep that event symbol's design, colours and recognizable silhouette. Image 2 is ONLY our approved round-badge geometry reference: match its outer navy outline thickness, thin inner rim, large six-across square-stud spacing and flat frontal layout. Do NOT use its Dewberry, leaf, moon, swirl or event palette. Do not copy the exterior of image1. Redraw the image1 event object centered on the image2 badge design in the following colour.
Disc palette: warm golden-yellow disc with honey-orange shadows and pale gold stud highlights; keep the central ticket separate from the badge by bold dark outline.
Central object: the existing single tilted golden ticket with notched ends, orange-gold border and a bold GREEN five-point star stamped at its center. Keep that source ticket's silhouette and green star, no words or numbers. One large ticket, no currency coin, no invented lottery text.
Match the family, with no new symbols. Keep the whole symbol group at about64-68% disc width, all completely inside the circle and separated from the studs by thick dark outline.

### event-pod-rush.png

Selected generated original: C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-06e4e5ca-4165-4e42-b662-3d96a353f7d0.png

Reference images: D:/KAPE/Steal an Artifact/output/imagegen/podrush/pod-rush-v1-512.png; C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-3dab2e01-f153-4e1b-b7b8-ad17ea2d17f7.png

Prompt used:

Use case: stylized-concept. Asset type: production-ready small Roblox event HUD badge, one standalone square 512x512 transparent PNG.
Primary request: ONE circular studded event badge, no text.
Badge geometry: perfectly round disc centered on the square, diameter exactly about 92% of canvas width, with a thick solid near-black navy outer outline ring and one thin lighter inner rim. Orthographic frontal 2D sticker icon, not a perspective coin. Fill the disc with a regular aligned grid of few LARGE raised SQUARE toy-plastic studs, SIX large square studs across its diameter, six columns at the widest row and matching vertical pitch, not eight or twelve. Subtle upper-left bevel light and tiny lower-right relief shadows, clearly square rather than dots. Gentle darkening behind the central object for silhouette contrast. No busy noise. Use consistent polished glossy game-icon shading.
Object layout: the whole event symbol group is centered and occupies about 64% of the disc width. It has a bold dark outline, simple recognizable silhouette and glossy upper-left highlights. Symbols can slightly overlap the thin inner rim, but EVERY shape, sparkle, mist swirl, reflection and shadow stays INSIDE the outer dark circular ring. No shape may stick out of the circular disc.
Transparency is essential: outside the perfectly circular disc, absolutely empty genuine alpha=0 pixels, no square plate, background colour, drop shadow, external glow, checkerboard, detached speckles or artwork. All four corners transparent. Disc itself opaque. Leave about 4% canvas margin on each side.
Small-scale requirement: easily distinguishable at only 24px. Prioritize big solid silhouette, thick clean outlines and strong colour contrast, keeping secondary details minimal. No letters, numbers, text, prices, UI, logos, Robux marks, watermark, border frame or collage. Make exactly one badge, not a sheet.

Reference roles: image 1 is the existing Pod Rush object identity reference; keep that event symbol's design, colours and recognizable silhouette. Image 2 is ONLY our approved round-badge geometry reference: match its outer navy outline thickness, thin inner rim, large six-across square-stud spacing and flat frontal layout. Do NOT use its Dewberry, leaf, moon, swirl or event palette. Do not copy the exterior of image1. Redraw the image1 event object centered on the image2 badge design in the following colour.
Disc palette: bright orange disc with amber top-left stud highlights and burnt-orange relief shadows.
Central object: the same lime/yellow-green round leafy pod with large gold spots and zigzag gold seam, three yellow-gold speed streaks extending left, and bright RED stopwatch in front on the right with pale white clock face, gold edge, red top button and one simple dark clock hand. Preserve this pod-plus-stopwatch group, with no digits on the watch.
Match the family, with no new symbols. Keep the whole symbol group at about64-68% disc width, all completely inside the circle and separated from the studs by thick dark outline.

### event-server-luck.png

Selected generated original: C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-6c9a254f-cbb5-4615-bdc1-7bb04aefcf7a.png

Reference images: D:/KAPE/Steal an Artifact/art/icons/products-2026-10-11/server_luck.png; C:/Users/Maykel/.codex/generated_images/01a041d8-8273-7f31-885d-87e3bd28a713/exec-3dab2e01-f153-4e1b-b7b8-ad17ea2d17f7.png

Prompt used:

Use case: stylized-concept. Asset type: production-ready small Roblox event HUD badge, one standalone square 512x512 transparent PNG.
Primary request: ONE circular studded event badge, no text.
Badge geometry: perfectly round disc centered on the square, diameter exactly about 92% of canvas width, with a thick solid near-black navy outer outline ring and one thin lighter inner rim. Orthographic frontal 2D sticker icon, not a perspective coin. Fill the disc with a regular aligned grid of few LARGE raised SQUARE toy-plastic studs, SIX large square studs across its diameter, six columns at the widest row and matching vertical pitch, not eight or twelve. Subtle upper-left bevel light and tiny lower-right relief shadows, clearly square rather than dots. Gentle darkening behind the central object for silhouette contrast. No busy noise. Use consistent polished glossy game-icon shading.
Object layout: the whole event symbol group is centered and occupies about 64% of the disc width. It has a bold dark outline, simple recognizable silhouette and glossy upper-left highlights. Symbols can slightly overlap the thin inner rim, but EVERY shape, sparkle, mist swirl, reflection and shadow stays INSIDE the outer dark circular ring. No shape may stick out of the circular disc.
Transparency is essential: outside the perfectly circular disc, absolutely empty genuine alpha=0 pixels, no square plate, background colour, drop shadow, external glow, checkerboard, detached speckles or artwork. All four corners transparent. Disc itself opaque. Leave about 4% canvas margin on each side.
Small-scale requirement: easily distinguishable at only 24px. Prioritize big solid silhouette, thick clean outlines and strong colour contrast, keeping secondary details minimal. No letters, numbers, text, prices, UI, logos, Robux marks, watermark, border frame or collage. Make exactly one badge, not a sheet.

Reference roles: image 1 is the existing Server Luck object identity reference; keep that event symbol's design, colours and recognizable silhouette. Image 2 is ONLY our approved round-badge geometry reference: match its outer navy outline thickness, thin inner rim, large six-across square-stud spacing and flat frontal layout. Do NOT use its Dewberry, leaf, moon, swirl or event palette. Do not copy the exterior of image1. Redraw the image1 event object centered on the image2 badge design in the following colour.
Disc palette: rich emerald-green disc with cool mint-green stud highlights and dark green shadows; make the central clover pop with its gold trim and brighter leaf tops.
Central object: the existing glossy bright green FOUR-leaf clover, each leaf heart-shaped, with a curved short stem, thick gold edging and a few gold decorative glints. Preserve the source clover's silhouette, leaf count and gold trim. Use a bold navy contour around the object group instead of an external white glow so it stays readable on the green badge.
Match the family, with no new symbols. Keep the whole symbol group at about64-68% disc width, all completely inside the circle and separated from the studs by thick dark outline.

## Reproduce exports

Run export-badges.ps1 -ApprovedExteriorCleanup only for this generated family. It reads generation-manifest.json, verifies preserved native hashes and recreates this task's own seven masters, seven tight copies and sheet. It never edits other tight icons, references or game code.

## Scope

Owner uploads approved badge PNGs to CrazyCozy Games and provides the IDs; Claude checks/wires them. No game code or other agents' work was touched. No Git stage/commit/push; root repository target/scope confirmation remains unresolved.
