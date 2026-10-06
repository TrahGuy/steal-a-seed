# Inventory category icons v1

Built-in imagegen, 2026-10-03. Single transparent PNG, measured 1536 x 1024. Exactly six icons in a 3-column/2-row grid, each cell 512 x 512. Top row: All Items, Plants, Pods. Bottom: Equipment, Spin Tickets, BAG. Crop rectangles in sibling .crops.json. The PODS replacement is a solid closed leafy seed pod, not the earlier zero-like glyph. Graphic assets only, not a change to pod models, categories, counts or inventory behaviour.

Visual inspection completed. Format32bppArgb; corner and seven sampled gaps have alpha 0. Preserve alpha even if RGB underneath transparent pixels contains colour. Actual 24–32 px rendering and Roblox upload/wiring not tested. Crop cells, balance optical size/padding and preview at real HUD sizes before using. No source or Studio changes.

## Exact generation prompt

Use case: stylized-concept. Create ONE transparent PNG sprite sheet with six original polished inventory category icons for the Roblox botanical plant-monster game Podnappers. This is a crop-ready graphic asset, NOT a screenshot or menu mockup.

Input Image 1: current inventory sidebar, reference for the six icon purposes and for what to improve. Its PODS icon looks like a lime numeral 0: completely replace that symbol with a recognisable seed pod.
Input Image 2: approved weather/boost icon sheet, STYLE reference only. Match its bold dark ink contours, colourful clean cartoon bevel shading, small crisp highlights and botanical visual identity. Do not reproduce its icons.

Layout: landscape 1536 x 1024 canvas with EXACTLY three equal columns and two equal rows. One icon centred in each invisible square cell, equal optical size, complete uncropped silhouette, generous transparent margins and gutters, no overlap. Keep each icon within central 320 x 320 of its nominal 512 x 512 cell. Genuine alpha-transparent background. No painted checkerboard, black rectangle or white background. No grid lines, frames, button plates, lettering, labels, counters, watermarks or surrounding UI.

Exact order:
TOP ROW left-to-right:
1 ALL ITEMS: three overlapping small inventory cards/tiles as one compact group, front tile green with a cream leaf silhouette, back tiles amber and cream. Clear collection/assortment symbol, NOT a paperclip or chain, keep three-card group simple at small size.
2 PLANTS: a warm terracotta pot with ONE thick small stem and two broad fresh green leaves, simple chunky sprout, no face, no elaborate flower.
3 PODS: one plump closed botanical seed pod, egg-like teardrop body, softly pointed top, bright lime and deep forest-green overlapping husk segments with THREE broad raised curved ribs, a small short golden stem and two small leaf tips at base. Solid closed three-dimensional body, NO hole, NO dark vertical slit, NO black centre stripe, NO numeral-zero appearance. Clearly a botanical egg/pod at 24px. Distinct from the potted sprout.

BOTTOM ROW left-to-right:
4 EQUIPMENT: one chunky warm wooden baseball bat angled diagonally, green cloth-wrapped handle, cream/gold end cap, small leaf detail. A recognisable bat/tool rather than an animal bat, no wings, no wrench or screwdriver.
5 SPIN TICKETS: one chunky golden-yellow admission ticket at a slight angle, notched short sides, simple green five-point star stamped in centre, clean warm highlight. No words, currency symbols, letters or numerals.
6 BAG: one compact warm tan leather satchel/backpack viewed front-three-quarter, thick top handle, green front flap, bold brass buckle, subtle cream leaf emblem, simple broad shapes.

Style constraints: clean premium friendly Roblox cartoon HUD art; strongly readable silhouettes at 24–32 pixels; near-black thick clean outlines of matching visual weight, restrained gold/cream/forest-green palette, no tiny texture noise, no excessive studs, no diffuse outer glow or shadows extending into margins. Consistent light direction, icon size and detail. No photorealism. Exactly six icons, each fully isolated on transparency. Graphic category symbols only; do not change creature/pod in-game models or invent gameplay features.

