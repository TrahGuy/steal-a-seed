# Hatch + rebirth extras v1 — exact prompts used

Built-in image generation/editing only; no CLI/API/model fallback. The supplied hatch-rebirth-extras-v1.prompt.md is unchanged. Three requested asset types were generated separately. The final hatch atlas uses the corrective safe-gutter edit; rays use the fresh sharper-ray generation; the word logo uses its first generation. Native originals are retained separately from exact-size exports. The export helper uses measured, aspect-preserving icon crops and prepares white tintable rays with the requested opacity limit. No game implementation, asset uploads, IDs, prices, store prompts or publication was performed.

## A: original hatch atlas

Use case: stylized-concept.
Asset type: transparent Roblox HUD icon atlas for Podnappers / Steal a Sprout.
Style: clean, colourful, friendly premium Roblox cartoon HUD illustrations for a botanical Roblox plant-monster game whose menus are bright studded LEGO-like panels. Bold near-black ink outlines of even thickness, broad simple shapes, subtle bevel shading with one light from the upper left, crisp edge highlights, saturated cheerful colours. Readable at 24 to 64 pixels. No photorealism, no fussy detail, no tiny sparkles, no soft glows, no ground shadows, no text, no letters, no numbers, no watermark, no drawn grid lines, no cell backgrounds.
Asset: ONE transparent PNG icon atlas, exactly 2048 x 512: four invisible 512 x 512 cells in ONE horizontal row, one icon per cell, each centred and FILLING about 85% of its cell (roughly 430 x 430), with at least 32 pixels of transparent margin. Same perceived size and same outline weight across all four. Real alpha transparency, not white, not black and not a painted checkerboard. No coloured button plates behind the icons.
Left to right, exactly these FOUR symbols:
1. HATCH: a round golden-green seed pod cracking open across its middle, the top half tipping back, a bright green two-leaf sprout popping out, three short bold burst lines around the crack. Joyful.
2. INSTANT HATCH: the same seed pod, closed, with a bold bright yellow lightning bolt in front of it, slanting across, and two short speed lines behind. Premium and fast.
3. TIMER: a chunky little hourglass with a warm wooden frame, its glass half full of bright green sand running down, one small leaf on the top cap.
4. READY: a round bright green badge with a thick white check mark, ringed with exactly six short bold yellow burst lines. Celebratory.
Exactly four icons, nothing else. All forms isolated and fully inside their own invisible cells. These are generic action symbols, not new species or rarity-specific creatures.

## B: original sunburst (not selected)

Use case: stylized-concept.
Asset type: transparent tintable sunburst texture for a rotating Roblox reward popup.
Style: clean bright cartoon game VFX, smooth soft-edged, no outlines, no texture, no text, no watermark.
Asset: ONE transparent PNG, exactly 1024 x 1024: a radial sunburst centred on the exact centre of the image. Exactly 16 straight, evenly spaced rays alternating wide and narrow: EIGHT wide plus EIGHT narrow, every ray axis 22.5 degrees apart, each long thin wedge starting a little out from the centre and tapering to a point near the edge. Arrange as eight identical 45-degree sectors, each with one wide and one narrow ray. Perfect 45-degree rotational symmetry, exact central pivot, no spiral, bends or uneven ray lengths.
Pure WHITE RGB only, with ALL fading and softness in the alpha channel. Brightest near the centre and fading smoothly to fully transparent before the edge, brightest part about 80% opaque (alpha about 204/255), never fully opaque. A soft round white glow in the very centre about 15% of the image wide.
The rays must be rotationally even so it can spin with no visible seam or wobble. Real alpha transparency; every edge pixel fully transparent. No black matte, white background, grey RGB shading, colour, checkerboard, ring, extra dots or sparkles.

## C: REBORN! logo

Use case: logo-brand.
Asset type: transparent Roblox rebirth celebration word logo.
Style: bold chunky bubbly Roblox game title lettering, cartoon, glossy.
Asset: ONE transparent PNG, exactly 1024 x 384: the single word "REBORN!" in fat rounded capital letters, slightly arched upward in the middle, glossy gold-yellow fill with a lighter highlight along the top of each letter, a thick magenta-pink (#FF358F) outline, and a second thinner dark brown outer outline. Two small green leaves sprouting from the top of the letter O. The word fills about 90% of the width. Nothing else: no background, no sparkles, no ground shadow. Real alpha transparency.
Text (verbatim): "REBORN!"
Spell exactly R E B O R N followed by ONE exclamation mark. Six capital letters and one punctuation mark, no extra characters or words. Keep each letter easy to read and distinct. Do not add a leaf to any other letter. Entire word and both leaves fully visible with transparent exterior margin.

## B: sunburst corrective edit (not selected)

Use case: precise-object-edit.
Input image: the transparent white sunburst is the EDIT TARGET.
Correct this texture only. Keep a centred white 16-ray burst and real alpha, but change its chunky petal-like rays into exactly sixteen straight triangular light wedges, alternating 8 wide / 8 narrow at 22.5-degree spacing. Each ray must taper to a pointed outer tip and fade in alpha long before the square edge. The whole burst occupies about 85% of the square width, with at least 64 completely transparent pixels at every outer edge of a 1024 x 1024 square. Keep all rays equal radius, perfectly centred and rotationally even; no texture, no dark rim, no petals or surface shading.
Pure WHITE RGB rays, translucency represented only by alpha: about 80% opacity maximum at the core, much softer through the rays. Separate rays with truly transparent gaps outside the small central glow. A round central glow no more than 15% of width. No opaque white disc covering the inner two-thirds, no secondary colours, noise, painted checkerboard or background. Preserve genuine alpha. Exactly 1024 x 1024 transparent PNG, one texture, no text.

## B: fresh straight-ray generation (selected)

Use case: stylized-concept.
Create a minimalist flat GEOMETRIC sunburst reward texture as a transparent PNG, 1024 x 1024. This is a HUD overlay, NOT a flower or organic object.
Exactly sixteen straight triangle-wedge beams radiate from the same central pivot: eight wide wedges alternating with eight narrow wedges, at evenly spaced angles of 22.5 degrees, same 420px radius. Wide wedges are slender, narrow wedges even slimmer. Each widens near the centre and narrows toward one pointed outer tip. The space BETWEEN the beams is COMPLETELY TRANSPARENT. No petal curves, rounded ends, bevels, borders, rings or surface texture. Make the wedges clean, straight and mathematically even around the circle.
Pure white beams, with their brightness represented only by smoothly fading alpha. The beams start 60px from the centre and fade out radially before the outer tips. At the central pivot add one small soft round white glow, 150px diameter, no larger. Central glow 80% opacity; the beams softer. Outer 70px of the whole square entirely transparent.
Real alpha background, no opaque white or black disc, no shadows, colour, lettering, checkerboard, decoration or grain. White light rays ONLY, suitable for runtime tinting and slow rotation.

## A: safe-gutter corrective edit (selected)

Use case: precise-object-edit.
Image 1 is the EDIT TARGET: a transparent four-icon strip.
Change ONLY the spacing/size of the four icons to isolate them for rectangular cropping. Keep the same HATCH sprouting golden-green cracked pod, INSTANT HATCH closed golden-green pod/yellow bolt/two speed lines, wooden green-sand TIMER hourglass with leaf, READY green circle/white check/six yellow rays. Preserve style, colour, dark outline and broad shapes. No new icons or text.
Make each complete icon—including ALL burst lines and speed lines—15% smaller and centred in its own quarter of this single horizontal row. There must be a clean FULL-HEIGHT transparent vertical gutter at least 50 pixels wide between every neighbouring pair, with no horizontal overlap of any accents. Generous genuinely transparent exterior. Do not clip any leaf, line or ray. Four equally spaced independent icons in one row; no icon background plates and no drawn grid.
HATCH has exactly THREE yellow burst accent lines. TIMER has ONE small leaf on the top cap. READY keeps exactly SIX yellow rays.
Transparent PNG icon atlas, desired 2048 x 512. Real alpha, no white/black rectangle, checkerboard, glow, ground shadow, typography or watermark.
