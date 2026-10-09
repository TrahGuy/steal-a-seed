# Sprout Dash — exact image prompts used, 2026-10-08

Built-in image generation/editing only; no CLI/API fallback. Owner's source brief remains `sprout-dash-sprites-v1.prompt.md`. A/B use genuine transparency; C/D opaque. Existing seed coin and gold burst were not regenerated. Selected native outputs are preserved as `*-original.png`; normalized upload sheets use the four requested `*-v1.png` names. Mechanical crop/resize/pivot alignment is separate from generation and recorded in sibling crop manifests. No game code, upload or purchase changes.

## A — initial runner generation

Use case: stylized-concept.
Style: clean, colourful, friendly premium Roblox cartoon game art for Podnappers, a
botanical Roblox plant-monster game whose menus are bright studded LEGO-like panels.
Flat 2D side-view sprites, bold near-black ink outlines of even thickness, broad simple
shapes, chunky slightly blocky Roblox proportions, subtle bevel shading with one light
from the upper left, crisp edge highlights. Saturated cheerful greens, warm browns and
golds. Readable when drawn about 64 to 128 pixels tall. No photorealism, no fussy
detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
numbers, no watermark, no drawn grid lines, no cell backgrounds.


Asset: ONE transparent PNG sprite sheet of a single original character: a small
cheerful sprout creature — a round green seed-pod body with a pale cream belly, two
big friendly eyes, a tiny smile, a bright green two-leaf sprig on top of its head,
two short stubby legs with little brown feet, and tiny arms. The SAME character, same
colours, same size and same outline weight in every frame.

Canvas: exactly 2048 x 1024, a 4-column by 2-row grid of invisible 512 x 512 cells.
Each frame centred horizontally in its cell. The character stands on one shared
invisible baseline 64 pixels above the bottom of each cell, and its body fills about
300 pixels of height. At least 64 pixels of transparent margin inside every cell; no
pixel crosses into another cell. Background must be real alpha transparency, not white
and not a painted checkerboard.

Every frame faces RIGHT (running toward the right edge), in strict side view.

TOP ROW, a 4-frame run cycle that loops smoothly:
1. right foot forward on the ground, left foot back, arms swinging opposite
2. passing pose, body slightly higher, both feet under the body
3. left foot forward on the ground, right foot back
4. passing pose again, mirrored arms, body slightly higher
The leaf sprig bounces a little through the cycle.

BOTTOM ROW:
5. hop: mid-air, knees tucked up, arms raised, sprig blown back, body lifted
   about 80 pixels above the baseline
6. hit: knocked back, leaning left with a surprised squinting face, one leaf
   drooping, still on the baseline
7. ready: standing still facing right, feet on the baseline, eager smile
8. cheer: both arms up, big happy closed-eye smile, feet on the baseline

Exactly eight frames, nothing else.

## B — props generation

Use case: stylized-concept.
Style: clean, colourful, friendly premium Roblox cartoon game art for Podnappers, a
botanical Roblox plant-monster game whose menus are bright studded LEGO-like panels.
Flat 2D side-view sprites, bold near-black ink outlines of even thickness, broad simple
shapes, chunky slightly blocky Roblox proportions, subtle bevel shading with one light
from the upper left, crisp edge highlights. Saturated cheerful greens, warm browns and
golds. Readable when drawn about 64 to 128 pixels tall. No photorealism, no fussy
detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
numbers, no watermark, no drawn grid lines, no cell backgrounds.


Asset: ONE transparent PNG sprite atlas of eight separate original game props for a
side-view runner, all sized to the same character scale as a small 300-pixel-tall
sprout creature.

Canvas: exactly 2048 x 1024, a 4-column by 2-row grid of invisible 512 x 512 cells,
one prop per cell, centred horizontally. Ground props sit on a shared invisible
baseline 64 pixels above the bottom of each cell. At least 64 pixels of transparent
margin inside every cell; nothing crosses into another cell. Real alpha transparency.

TOP ROW, obstacles (the runner hops over these; each must read instantly as "jump
over me"):
1. a chunky grey boulder with two mossy patches, about 150 pixels tall
2. a thorny purple weed clump with spiky leaves, about 170 pixels tall
3. a short fallen wooden log lying across the path, round end facing the viewer,
   about 120 pixels tall and 300 wide
4. a cracked clay flower pot tipped on its side, about 140 pixels tall

BOTTOM ROW, effects and lives:
5. a full red heart with a white highlight (a life), about 160 pixels, centred
   vertically in its cell
6. the same heart empty: dark grey interior, same outline (a lost life)
7. a small dust puff of three soft round cartoon clouds (the hop's take-off), on
   the baseline
8. a bold yellow and white star-burst impact spark (the hit), centred vertically

Exactly eight props, nothing else.

## C — initial ground generation

Use case: stylized-concept.
Style: clean, colourful, friendly premium Roblox cartoon game art for Podnappers, a
botanical Roblox plant-monster game whose menus are bright studded LEGO-like panels.
Flat 2D side-view sprites, bold near-black ink outlines of even thickness, broad simple
shapes, chunky slightly blocky Roblox proportions, subtle bevel shading with one light
from the upper left, crisp edge highlights. Saturated cheerful greens, warm browns and
golds. Readable when drawn about 64 to 128 pixels tall. No photorealism, no fussy
detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
numbers, no watermark, no drawn grid lines, no cell backgrounds.


Asset: ONE opaque PNG that tiles SEAMLESSLY left to right: the running surface for a
side-view runner game, a chunky treadmill belt seen straight from the side. A dark
charcoal rubber belt with evenly spaced raised ridges on its top surface, sitting on
a sturdy warm brown wooden frame with gold rivets, a thin green grass edge along the
very top. The left and right edges must match exactly so the strip repeats with no
visible seam; the ridges are evenly spaced so an integer number fit across.

Canvas: exactly 2048 x 512, the belt's top surface a straight horizontal line 96
pixels below the top of the image. No characters, no props, no text.

## D — initial backdrop generation

Use case: stylized-concept.
Style: clean, colourful, friendly premium Roblox cartoon game art for Podnappers, a
botanical Roblox plant-monster game whose menus are bright studded LEGO-like panels.
Flat 2D side-view sprites, bold near-black ink outlines of even thickness, broad simple
shapes, chunky slightly blocky Roblox proportions, subtle bevel shading with one light
from the upper left, crisp edge highlights. Saturated cheerful greens, warm browns and
golds. Readable when drawn about 64 to 128 pixels tall. No photorealism, no fussy
detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
numbers, no watermark, no drawn grid lines, no cell backgrounds.
Use the shared palette, but softer low-contrast outlines for this backdrop.

Asset: ONE opaque PNG backdrop that tiles SEAMLESSLY left to right, for behind a
side-view runner game: a calm sunny garden — soft blue sky with a few rounded
clouds, gentle green hills, distant rows of blocky Roblox-style garden plots and a
few round trees. Pale and low-contrast so bright sprites in front of it read clearly;
softer outlines than the sprites. Nothing in the bottom 25 percent but plain grass
colour (the treadmill strip covers it). No characters, no text.

Canvas: exactly 2048 x 1024; the left and right edges match exactly.

## A — first correction, superseded

Use case: precise-object-edit.
Edit target: the supplied Sprout Dash runner sprite sheet.
Correct ONLY the right-facing side-view poses and their consistency. Preserve this exact cheerful round green seed-pod character, pale cream belly/face patch, brown stubby feet, two-leaf sprig, colours, bold dark outline and friendly cartoon shading. Do not add or change the character's costume or identity.
Return one transparent 4-column by 2-row atlas of eight frames, ideally 2048x1024. All eight must be strict RIGHT-facing side profiles with matching torso size and outline weight, not front-facing or three-quarter views. The character has two eyes anatomically; only the nearer eye needs to be visible from the strict side profile.
In each invisible 512x512 cell, center the character horizontally, roughly 300 pixels full standing height, with at least 64 pixels transparent margin. Shared standing baseline y448 relative to each cell.
TOP ROW, four DISTINCT sequential RUN poses:
1. Near leg reaches FORWARD to the right and touches baseline; far leg reaches BACK to the left; near arm back.
2. Passing: near leg bends behind and far leg passes under torso; near arm moving forward; torso slightly lifted.
3. REVERSED stride: far leg reaches FORWARD to the right and near leg reaches BACK to the left; near arm forward. Make visibly different from frame1: foreground brown foot is behind the body, not ahead.
4. Opposite passing: far leg bends behind and near leg passes under torso; opposite arm swing. Make visibly different from frame2.
Do not reuse the same visible foreground foot placement for frames1 and3. The sprig bounces gently, but head and torso do not change size.
BOTTOM ROW:
5. Hop, knees tucked, arms lifted, right-facing, feet 80 pixels above standing baseline.
6. Hit, body tilted backwards to the left but face still looks RIGHT, surprised squeezed eye and drooping leaf, feet on baseline.
7. Ready, standing RIGHT-facing, both feet on baseline, eager small smile.
8. Cheer, same RIGHT-facing body, both arms raised, happy closed eye, feet on baseline.
No text, numerals, labels, ground, shadows, cell borders, grid lines or background colour. Genuine transparent alpha around every frame. Exactly eight separate frames, nothing else.

## C — framing/repeat correction, selected

Use case: precise-object-edit.
Edit target: the supplied treadmill belt strip for Sprout Dash.
Correct only its strip framing and horizontal repeat. Preserve its dark charcoal ridged rubber, warm brown wood, gold rivets, thin green grass top, outlined cheerful cartoon rendering and strict straight side view.
It must be one fully OPAQUE seamless scrolling tile, ideally 2048x512 (4:1). NO empty white canvas above or below. Fill the top 96px with plain pale grass-green colour and a thin grass edge; the straight running contact line must be at y96. Below that line, fill the image with the thick dark rubber belt and solid wooden frame. Use solid wood below the beam, no hanging legs and no background gaps. The entire bottom edge is the wooden frame's base.
Draw an exact integer number of identical repeat modules across the width, for example eight modules with one rubber ridge and one gold rivet per module. Both LEFT and RIGHT boundaries must cut at the SAME phase between modules. Top line, grass colour, belt grey, wood plank colours, shadows and rivet spacing must meet with continuous matching edges. No whole unique end cap on either edge.
No characters, props, letters, numbers, text, logos, grid or transparent regions. Return only this tile, not a demonstration of multiple tiles or a scene.

## A — fresh side-profile runner, selected

Use case: stylized-concept.
Style: clean, colourful, friendly premium Roblox cartoon game art for Podnappers, a
botanical Roblox plant-monster game whose menus are bright studded LEGO-like panels.
Flat 2D side-view sprites, bold near-black ink outlines of even thickness, broad simple
shapes, chunky slightly blocky Roblox proportions, subtle bevel shading with one light
from the upper left, crisp edge highlights. Saturated cheerful greens, warm browns and
golds. Readable when drawn about 64 to 128 pixels tall. No photorealism, no fussy
detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no
numbers, no watermark, no drawn grid lines, no cell backgrounds.


Asset: ONE transparent PNG sprite sheet of a single original character: a small
cheerful sprout creature — a round green seed-pod body with a pale cream belly, two
big friendly eyes, a tiny smile, a bright green two-leaf sprig on top of its head,
two short stubby legs with little brown feet, and tiny arms. The SAME character, same
colours, same size and same outline weight in every frame.

Canvas: exactly 2048 x 1024, a 4-column by 2-row grid of invisible 512 x 512 cells.
Each frame centred horizontally in its cell. The character stands on one shared
invisible baseline 64 pixels above the bottom of each cell, and its body fills about
300 pixels of height. At least 64 pixels of transparent margin inside every cell; no
pixel crosses into another cell. Background must be real alpha transparency, not white
and not a painted checkerboard.

Every frame faces RIGHT (running toward the right edge), in strict side view.

TOP ROW, a 4-frame run cycle that loops smoothly:
1. right foot forward on the ground, left foot back, arms swinging opposite
2. passing pose, body slightly higher, both feet under the body
3. left foot forward on the ground, right foot back
4. passing pose again, mirrored arms, body slightly higher
The leaf sprig bounces a little through the cycle.

BOTTOM ROW:
5. hop: mid-air, knees tucked up, arms raised, sprig blown back, body lifted
   about 80 pixels above the baseline
6. hit: knocked back, leaning left with a surprised squinting face, one leaf
   drooping, still on the baseline
7. ready: standing still facing right, feet on the baseline, eager smile
8. cheer: both arms up, big happy closed-eye smile, feet on the baseline

Exactly eight frames, nothing else.
PRODUCTION PRIORITY: this is a FUNCTIONAL ANIMATION ATLAS, not eight cute variations of one pose. Use true flat orthographic right-facing SIDE PROFILE, with only the nearer eye visible (the character still has two eyes anatomically). No three-quarter face. The torso is a green seed with pale belly, two stubby feet, two tiny arms and a two-leaf sprig, no clothing. Make the four running poses visibly DIFFERENT:
frame1: the NEAR brown foot is far FORWARD to the RIGHT, far foot BACK LEFT, NEAR arm BACK LEFT;
frame2: NEAR foot folded behind the butt, FAR foot directly under belly, NEAR arm half-forward;
frame3: NEAR brown foot far BACK to the LEFT, FAR foot far FORWARD RIGHT, NEAR arm reaches FORWARD RIGHT;
frame4: NEAR foot directly under belly, FAR foot folded behind butt, NEAR arm half-back.
The visible nearer arm and leg must clearly swing in opposite directions on frames1 and3; do not duplicate their silhouettes. Background completely transparent. Exactly 4 columns and 2 rows, eight frames, uniform torso/eye/leaf geometry and scale.

## D — repeat-edge correction, selected

Use case: precise-object-edit.
Edit target: the supplied Sprout Dash garden backdrop.
Change ONLY the outer-edge composition/lighting so it can repeat seamlessly LEFT to RIGHT. Keep the same pale, low-contrast blue sunny sky, soft rounded clouds, distant green hills, blocky garden plots, round trees, cheerful quiet style and plain green foreground. No characters or text.
Output a single opaque 2:1 backdrop, ideally 2048x1024.
LEFT and RIGHT edges must have the SAME sky colour at each height and the SAME green hill/grass heights and colours at each height. Keep the outermost 10% on each side free of clouds, trees, fences, flowers and plot boxes that could be chopped in half: those edge bands should show only the continuous sky, one gentle hill profile that enters/exits at the same height/slope, and plain grass. A single vertically graded sky/grass colour may vary TOP to BOTTOM but never from LEFT to RIGHT at the matching boundaries. Avoid a directional lighting vignette.
Keep all garden trees, plot boxes and clouds inside the middle 80% of the tile. The bottom 25% must be plain low-contrast grass with no objects.
No mirror reflection of readable objects, no drawn border, no repeated preview tiles, no grid. Return only one seamless tile. Fully opaque everywhere.
