# Training / milestone / catch-game assets — 2026-10-08

Plain Speed shoe added afterward: use 01-plain-speed-shoe-transparent-512.png and 01-plain-speed-shoe-transparent-32.png. These reuse the original transparent Speed artwork, without a supercharged boost/badge/background. See PLAIN_SPEED_SHOE_NOTES.md for source/export details and owner-reported upload IDs. Do not use the superseded opaque-reference export names lacking transparent.

All four assets were generated one by one with the built-in image tool; no CLI/API fallback. Final deliverables are separate 512 × 512 RGBA PNGs. No text or numbers baked into any image. Originals remain preserved beside each export and in the generated-image cache.

The user's exact-size / tight-crop requirement is handled by export-asset.ps1: alpha-bound crop, aspect-preserving high-quality resampling, longest visible dimension about 460px (90% of 512), transparent safety margins. 32px previews are QA files, not upload masters. Imperceptible alpha noise below 8/255 is cleared on the clean burst export; generated original and first burst export preserved.

## Deliverables

- 03. Boosted shoe: 03-boosted-shoe-512.png. Gold-orange glow, longer flames and four sparkles; no baked 2x/percentage.
- 04. Empty milestone badge: 04-milestone-badge-empty-512.png. Gold round/burst medal and blue ribbons, blank gold center for code-added shoe/number.
- 05. Seed coin: 05-seed-coin-512.png. Tilted gold coin with two-leaf green sprout stamp and a white glint.
- 06. Optional gold burst: 06-gold-burst-clean-512.png. Soft gold radial FX with exactly zero center-sample alpha. Clean export supersedes 06-gold-burst-512.png.

## QA / usage

Visually inspected full assets and their actual 32px previews. Shoe/wing/flame, medal/ribbons, coin/sprout and radial burst remain identifiable; fine sparkle and bevel detail is naturally reduced at 32px. Transparent exterior checked for each final. Optional burst center sample is alpha 0; badge center is intentionally blank gold (not a transparent hole). Keep PNG alpha in a transparent ImageLabel frame, preserve aspect, draw milestone numbers in code. Do not duplicate labels/badges already absent here. No golden-ticket art created because it already exists.

No Roblox uploads, asset IDs, runtime wiring, purchase logic, actual-phone Play verification, publish or git operations were performed. This is an asset pack, not a gameplay implementation.

## Source references

- Shoe identity: ../../ui-buttons/double-speed-popup-2026-10-08/reference-speed-shoe.png (original owner-supplied green winged shoe).
- Medal uses exported shoe as style-only input; coin uses exported medal as style-only input. No shoe inside medal and no ribbon on coin.
- Burst is newly generated without image input.

## Exact prompts

### 03. Boosted shoe

Use case: precise-object-edit.
Asset 3 of a sequential UI-icon set: SUPERCHARGED / BOOSTED SHOE for a 2x workout card and +25% training boost.
The supplied image is the identity reference: the same green running sneaker, dark green collar, three beige lace bands, cream sole, pale heel wing, and dark bold outline, toe pointing diagonally lower-right.
Make this SAME shoe look supercharged: preserve its recognizable green silhouette and heel wing; add warm gold-orange edge lighting and a controlled gold glow, significantly longer broader bright yellow-to-orange flame streaks sweeping left from the heel, and just 3–4 clear gold four-point sparkles near the shoe. Stronger than the original's two small speed streaks, but the shoe remains the main readable shape.
Keep a simple thick dark outline around the shoe and flames, bright saturated colours and crisp 2D toy-game icon shading. Design to remain immediately recognizable at 32 pixels. No tiny decorative texture or dense glitter.
Single isolated shoe/wing/flame/sparkles group tightly framed. Composition fills about 90% of the square without clipping any flame tips, sparkles or toe. Use a slim transparent safety margin, not a large empty canvas.
Absolutely NO text, letters, numbers, 2x badge, percentages, studded background, square panel, circle plate, frame or other objects. This is the standalone icon, not a UI tile.
Genuine transparent alpha background behind and around the entire object; no painted black/white/checkerboard/gradient backdrop. Gold glow must fade into transparency. Square PNG intended for export at 512x512. Output one asset only, not a sheet or mockup.

### 04. Empty milestone badge

Use case: stylized-concept.
Asset 4 of a sequential Roblox UI-icon set: EMPTY MILESTONE MEDAL / BADGE.
One simple round gold medal with a slightly scalloped/burst rim and two short royal-blue ribbon tails below it. Bold smooth dark outline, bright yellow-gold inner bevel and warm orange-gold edge shading. Cheerful crisp 2D toy-game icon, matching the clean outlined colour style of the supplied style reference.
The supplied image is STYLE ONLY. Do not put its shoe, flames, wing, sparkles or any symbol inside this medal.
CRITICAL: the middle of the medal is a LARGE COMPLETELY BLANK gold field, smooth and low-detail, with no text, number, symbol, star, shoe, pattern, embossing, placeholder glyph or logo. The game will overlay a shoe and dynamic milestone number later. Reserve at least 65% of the medal's diameter as this unobstructed blank center. The center is blank gold, not a pre-rendered shoe or text.
Strong simple silhouette readable at 32 pixels: round gold badge plus two visible ribbon tails. Avoid intricate filigree, tiny details or heavy perspective.
Front-facing, centered. Tight framing: the complete medal and ribbons occupy about 90% of a square canvas, all tips intact, slim transparent safety margin. No background plate, rectangle, UI frame or scenery.
Genuine fully transparent alpha outside the medal/ribbon silhouette, including gaps between ribbon tails. No painted black/white/checkerboard backdrop. PNG intended for 512x512 export. One asset only, not a sprite sheet/mockup.

### 05. Seed coin

Use case: stylized-concept.
Asset 5 of a sequential Roblox UI-icon set: SEED COIN for a belt-catching minigame.
One shiny gold coin with a small green sprout stamped prominently on its face: two simple bright-green leaves and one short curved stem, clearly a sprout, not a tree, letter or currency symbol. Make the sprout large and high-contrast enough to be recognized at 32 pixels, about half the coin-face width, with a dark-green edge.
Slight three-quarter tilt, a narrow visible orange-gold side rim for thickness, bright gold/yellow face, one clean white glint at the upper edge. Thick dark outer outline, restrained bevel highlights, simple bright 2D toy-game icon shading.
The supplied medal image is a STYLE REFERENCE ONLY for its gold palette and outlined rendering. Do not copy its scalloped medal rim, blue ribbons, empty center or medal silhouette. This object is a circular gold COIN with a green sprout stamp, not a trophy/badge.
Centered, complete coin and glint fill about 90% of the square with a small transparent safety margin. No clipping and no large empty margins. Keep the geometry simple and readable on bright green grass and blue sky. Avoid detailed engraving and realistic metallic microtextures.
Absolutely no text, numbers, letters, price, dollar sign, 2x, icons other than the sprout, ribbons, shoe, flames, golden ticket or extra objects. Only one coin and its single white glint.
Genuine fully transparent alpha background outside the coin/glint silhouette. No painted black, white, checkerboard or gradient backdrop. Square PNG intended for export at 512x512. Output one asset, not a sheet or mockup.

### 06. Optional gold burst

Use case: stylized-concept.
Asset 6, optional FX in a sequential Roblox UI-icon set: SOFT GOLD BURST overlay behind a speed shoe popup.
One clean radial gold star-burst made of approximately 12 short bright yellow/gold/orange tapered rays arranged in a ring. Vary a few ray lengths for a lively simple silhouette. Crisp simple cartoon cores with dark warm-brown edge definition to match bold game UI icons, transitioning into soft gold glow toward the tips and fading out to fully transparent outer edges. Not a realistic photograph, not intricate.
CRITICAL ALPHA: the central circular area, about 35% of the full canvas diameter, must be COMPLETELY EMPTY AND FULLY TRANSPARENT. NO center disk, no central star, no white core, no gold fill, no haze or glow covering that center hole. The rays start OUTSIDE the transparent center and point outward; only a ring of rays and their glow is visible. This is a background FX layer for a separately rendered shoe.
Only this one soft gold ray burst. NO shoe, medal, coin, flower, ribbon, text, letters, numbers, "+1", badges, frame, circular solid backplate, background scenery or other objects.
Center the radial burst and frame tightly so the longest rays/glow occupy about 90% of the square, intact with a slim transparent safety margin. Strong simple core-ray structure still readable at 32 pixels, with restrained soft glow, not washed out.
Genuine transparent PNG alpha both in the large CENTER HOLE and around the OUTER EDGES. No painted black, white, gray, checkerboard or colored square backdrop. Square PNG intended for export at 512x512. One isolated asset only, not a sheet or mockup.
