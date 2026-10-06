# Shop buy-button assets

Prepared from the owner's attached Exclusive Shop screenshot. No Shop code, prices or purchase flow changed.

## Exact screenshot crops

- reference-buy-1099.png: 153 x 78; includes the original crossed-out discount, Robux badge, 1,099 price and 10 Eggs caption.
- reference-buy-379.png: 151 x 68; original 379 price and 3 Eggs caption.
- reference-buy-149.png: 151 x 68; original 149 price and 1 Egg caption.
- reference-robux-badge.png: 33 x 33; cropped currency badge, including its green screenshot background (not a transparent cutout).
- source-exclusive-shop.png: untouched screenshot copy.

These are direct lossless rectangular crops, with no AI repainting or upscaling. The first reference overlaps the original discount label because it is drawn over the button. Foreign prices and quantities are baked in: keep these as visual references, not as live product-price graphics.

## Reusable blank button

shop-buy-green-blank-v1.png is a clean GREEN STUDDED button background generated with the built-in image generator from the 149 reference. It contains no price, currency icon, discount or quantity. It is a generated interpretation, not an exact screenshot crop. Dimensions: 2170 x 725. Exterior transparency checked (corner alpha 0; center alpha 251).

## Claude handoff

Use the blank base if an uploaded raster button background is desired. Place the Shop's existing currency icon and actual live product price above it as separate UI elements; retain the current price loader, loading/off-sale/owned/opening states, eligibility checks and purchase handlers. Do not copy this other game's 149/379/1,099 prices, quantities, creature art or product catalogue.

Upload the selected PNG to Roblox before assigning an Image asset ID; no ID has been created here. Do not use the raw badge crop where a transparent currency icon is needed: reuse the Shop's existing currency icon. Preserve rounded corners and test the background's aspect ratio; avoid stretching the square studs into rectangles. Keep the pattern subtle enough for readable runtime text. Mobile layout and Roblox rendering are not yet tested.

The 12-color stud atlas is in ../../textures/ui-studs-2026-10-04/. Exact generation prompt and provenance are in generation.prompt.md; crop coordinates are in manifest.json. crop-reference.ps1 reproduces only the explicitly requested screenshot crops and refuses to overwrite existing files.

