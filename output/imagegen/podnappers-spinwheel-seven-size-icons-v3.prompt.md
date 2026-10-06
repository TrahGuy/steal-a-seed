# Seven size-tier pod silhouette icons v3

Created using the built-in image-generation tool, with one targeted spacing repair. Actual game tier names/order/colour references checked in src/ReplicatedStorage/SeedGame/Shared/SeedData.luau. Owner permitted improvisation based on prior actual-pod silhouettes. Prior outputs preserved. Final raster dimensions: 1774x887. No code or live assets changed.

## Initial prompt

Use case: stylized-concept.
Asset type: ONE transparent raster sprite sheet of SEVEN Roblox pod reward icons for the game's seven SIZE TIERS.
The reference sheet is a visual/shape reference: use its actual-game pod forms, not invented glossy leafy badge shapes. Keep the dark mystery-pod silhouette treatment and big ivory question marks. The owner permits tasteful improvisation for seven distinct icons; this is reward UI art, not a redesign of the physical game models.

Layout: prefer 2048x1024 pixels, precisely FOUR columns and TWO rows of equal square cells, seven icons total. Top row has FOUR icons, bottom row has THREE icons aligned to columns 1-3. BOTTOM RIGHT CELL MUST BE EMPTY AND FULLY TRANSPARENT. Absolutely no eighth icon. Genuine transparent RGBA background everywhere. Each icon isolated and centred in its own cell with generous empty margins, no cropping or overlap, no background, panels, labels or visible grid. Count must be seven.

Order and designs:
TOP ROW left to right:
1 TINY — compact squat segmented egg based on the reference middle pod, equatorial belt and tiny bent leafy stem; small within cell, approximately 50% cell height; silver-grey outline RGB170,175,180.
2 BIG — slightly taller and broader variation of the same segmented egg, thicker belt and clearer block plates, approximately 57% cell height; soft green outline RGB120,200,110.
3 HUGE — substantial round segmented pod, wider belly and pronounced equatorial band, small angled stem, approximately 64% cell height; sky blue outline RGB90,170,240.
4 MEGA — the reference left pod's two stacked rounded lobes, top spherical bulb, angled triangular upper-right plate and little side brackets, approximately 69% cell height; violet outline RGB170,120,240.

BOTTOM ROW left to right:
5 GIANT — broader two-lobed version of the reference left pod, bigger shoulder/top bulb and robust side brackets, keep its recognizable asymmetric shape, approximately 74% cell height; orange outline RGB255,160,60.
6 TITAN — the reference right studded orb pod with angular upright antenna ending in a round bulb, diagonal crossing band and asymmetric side rods, approximately 78% cell height; coral red outline RGB240,80,70.
7 COLOSSAL — the most imposing version of the reference right antenna pod: large heavy rounded body, thicker diagonal band, robust side rods and tall angular antenna with circular tip, approximately 82% cell height; gold outline RGB255,215,90.
8 EMPTY — no drawing whatsoever in the bottom-right cell.

Rendering: all main bodies BLACK or very dark charcoal silhouettes. Minimal charcoal facets/studs identify the game's native blocky geometry. Use a crisp slightly thick tier-coloured perimeter/rim line for readability, not coloured pod bodies. One large clean ivory '?' centred on each body's face. The question marks must be visible at small UI sizes. No creature reveal. No fancy leaf crowns, stars, ribbons, wheels, feet, backgrounds or new objects. No text except the seven question marks. No numbers, tier names, captions, watermark or labels. No broad glow connecting cells. Do not generate a Jackpot Trail: the existing in-game trail is unchanged. Make the size progression and silhouettes clear, with all artwork safely inside the corresponding cell.

## Spacing repair prompt

Use case: precise-object-edit. The supplied image is the EDIT TARGET.
Keep ALL SEVEN pod icons exactly the same: same geometry, black/charcoal silhouette rendering, ivory question marks, outline colours, order and designs. Change ONLY their placement and relative scale to add safe empty cropping margins. Do not redesign, add icons, add labels, change colours or swap the order.

Return a genuinely transparent RGBA sprite sheet, 4 equal columns x 2 equal rows, preferably 2048x1024, seven icons total. Top row: silver Tiny, green Big, blue Huge, purple Mega. Bottom row: orange Giant, red Titan, gold Colossal; bottom-right cell fully empty.

CRITICAL: EACH COMPLETE ICON INCLUDING ITS ANTENNA, SIDE PROJECTIONS AND OUTLINE MUST FIT WITHIN THE INNER 76% OF ITS OWN CELL. Shrink each existing icon by roughly 22%, centre it inside its cell, preserve the relative small-to-large size progression. Keep at least 12% of the cell height clear above and below each complete icon and 12% of cell width clear left and right. This means a thick fully transparent horizontal gap between the two rows and fully transparent vertical gaps between all columns. In particular, move the gold Colossal icon DOWN into the centre of its bottom-row cell and make its antenna shorter ON THE SHEET BY UNIFORM SCALING ONLY, not by altering its anatomy. Keep the whole gold tip well below the horizontal midline. No parts, outline pixels or glow cross a cell border.

No background, scene, extra subjects, text except existing question marks, panels, captions or grid lines. Do not create a trail icon; retain the empty last cell.

