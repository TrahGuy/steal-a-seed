# Podnappers boost/weather icon sheet v1

Built-in image generation, 2026-10-03. One eight-icon RGBA PNG. Actual dimensions: 1774 x 887, not requested 2048 x 1024. Image inspected: exactly eight distinct icons, two rows/four columns. PNG metadata is Format32bppArgb; sampled corner/top-gutter alpha is 0. No game source edits, Roblox uploads or wiring.

Order left-to-right:
- Top: rain; thunderstorm; free bonus chest; reward wheel.
- Bottom: sacrifice; plant income; speed/training; community reward.

Crop coordinates are in the sibling `podnappers-boost-weather-icons-v1.crops.json`. Use those measured dimensions, not the prompt's requested size. Claude can crop the sheet, preserve alpha, normalize optical size/padding and preview at mobile HUD scale before upload. Keep the surrounding boost/timer UI transparent and use existing exact server-authoritative amounts and durations; don't bake text into these icons. Source icons are not new gameplay features. Use the community gift only for an appropriate existing reward, not to imply a community income buff. Art has not been tested at actual 24–32 px size.

## Exact generation prompt

Use case: stylized-concept. Asset type: ONE transparent PNG game HUD sprite atlas containing eight original coordinated illustrated icons for Podnappers, a botanical Roblox plant-monster game. The user needs one image Claude can crop, NOT separate images or a mockup.

Canvas: exact 2048 x 1024 landscape, regular 4-column by 2-row grid. Eight invisible 512 x 512 square cells. Each icon centred in its own cell and contained within the central 320 x 320 area, leaving at least 96 pixels transparent margin on all sides. Identical perceived scale, ample transparent gutters, nothing touching another cell. No drawn grid, no cell backgrounds, no labels, no text, no lettering, no numbers, no title, no watermark. Background must have actual alpha transparency, not white or a painted checkerboard.

Style: clean colourful friendly premium Roblox cartoon HUD illustrations matching a dark forest-slate botanical interface. Bold near-black ink outlines, broad simple shapes, subtle bevel shading, crisp edge highlights, restrained botanical accents. Three-quarter/front view where appropriate. Readable at 24–32 pixel HUD size. No photorealism, fussy details, excessive tiny sparkles, diffuse glow, ground shadows, decorative button plates or coloured backdrops.

EXACT ORDER left to right:
TOP ROW:
1 Rain: one rounded ivory/light-blue cloud above three large blue teardrop raindrops. Calm rain, NO lightning.
2 Thunderstorm: one darker cool blue-violet rounded cloud with ONE large vivid golden-yellow zigzag lightning bolt emerging in front and two blue raindrops. Distinct from rain, clear bolt silhouette.
3 Free bonus chest: small slightly open warm wood treasure chest with bold gold bands, a green sprout emblem and warm amber light clearly contained inside. No floating coins obscuring silhouette.
4 Reward wheel: a compact upright round prize wheel with six broad alternating botanical green/gold/coral/blue/purple sectors, gold rim and top pointer, a simple central hub and tiny dark stand. No words or letters.
BOTTOM ROW:
5 Sacrifice boost: a compact stone pedestal/bowl with one green seed pod above it and two bold golden upward energy rays. Botanical ritual, no fire, blood or skulls.
6 Plant income boost: two bold stacked gold coins bearing a SIMPLE raised green leaf emblem plus a small fresh green sprout. No currency lettering, no numbers, no arrows.
7 Speed/training boost: one bright green athletic shoe with cream sole, small leaf-like wing and two short amber speed streaks behind it. Strong simple running silhouette.
8 Community chest reward: a compact teal-blue gift chest/box with golden ribbon/bands and a clear cream heart emblem. Distinct shape/colour from the warm wooden bonus chest, no extra icons.

Constraints: exactly eight icons, one per cell. Keep all illustration pixels in their own padded cell. Visually balanced consistent ink thickness and lighting. No UI mockup, no surrounding game environment, no invented boost percentages or new gameplay features. These are static source icons; text/timers/animation will be added separately in Roblox.

