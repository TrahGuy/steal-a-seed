# Podnappers Shop / Index button assets — 2026-10-05

Generated with the built-in image editor from the owner's two small screenshot crops. No CLI/API fallback. Originals preserved. Codex prepared local assets only; the owner subsequently supplied uploaded Roblox image IDs (see below). No live UI changes were made by Codex.

## Owner-supplied upload IDs

- Shop lime-studded: `rbxassetid://82894505272456`
- Index sky-blue: `rbxassetid://91015160762668`

Transcribed from the owner's upload-list screenshot on 2026-10-05; loadability and permissions have not been independently tested. `CLAUDE_INTEGRATION_FOLLOWUP.md` is the current integration brief, including the requested studded left HUD sidepanel. Claude should adapt the layout to these supplied mixed-aspect images rather than require another upload or distort them.

## Files

- shop-lime-studded-v1.png — 2094 × 751, wide green/lime Shop button, red/pink basket icon and upright white outlined Shop text.
- index-sky-blue-studded-v1.png — 1254 × 1254, square cyan/blue Index tile, blue book/red bookmark and upright white outlined Index text.
- reference-original-shop.png / reference-original-index.png — unmodified supplied reference copies.

## Verification

Viewed both actual generated outputs: labels correct, studs/icon silhouettes legible, no surrounding game scenery. Read PNG alpha with System.Drawing: all four corners and left/right edge midpoint have alpha 0 for both assets. Center alpha is 254 (Shop) / 252 (Index), nearly opaque. Original generated alpha preserved, not replaced with black/white matte; a black preview background is not embedded in the file.

## Usage guidance for Claude

Use the PNG alpha with a transparent surrounding ImageButton/ImageLabel background. Text and icons are baked into the assets, so do not render duplicate labels over them. Preserve existing click behavior, badges and permissions. Keep aspect ratios: Shop is horizontal like the owner's reference; Index is square. Do not squash the wide Shop asset into a square HUD tile or stretch the Index tile horizontally. If using the existing equal-square mobile navigation, request a square Shop variant or use a different placement rather than distorting this asset. Transparent margins are intentional. Maintain comfortable real touch targets independently of visual dimensions. Upload/integration are separate owner-authorized steps.

## Exact Shop editing prompt

Use case: precise-object-edit / background-extraction.
Asset: one finished transparent PNG UI button for Roblox game Podnappers.
Input image is the edit/reference target: pink studded horizontal Shop button with a red/pink open basket/crate icon at left and white outlined "Shop" at right. Remove ALL surrounding screenshot scenery.

Rebuild/enhance this same button sharply at high resolution while retaining its recognizable shape and layout: one wide rounded rectangle, roughly 2.8:1 button aspect, basket/crate icon on the left, exact label "Shop" on the right.
Change ONLY its main button panel palette from pink to a bright lime-to-leaf-green vertical gradient, matching a colorful studded garden game. Add clean small evenly spaced raised square Roblox studs on the panel with restrained highlights/shadows; subtle inner top bevel and narrow darker green bottom bevel. Crisp dark outer border, smooth modest corner radius, no oversized extruded frame.
Preserve and sharpen the small red/pink open basket/crate icon from the reference, with its dark outline, strong simple silhouette and highlights. Do not substitute a cart or coin pile. Keep the icon entirely inside the button.
Text must be exactly "Shop", upright NON-ITALIC white rounded sans-serif, medium-to-semibold weight, clean narrow black outline, readable at small HUD size. No enormous inflated bubble letters or overly thick outline. Comfortable padding and consistent icon/text spacing.
Front-on flat 2D game UI illustration, clean toy-plastic/studded Roblox style, crisp antialiasing, vivid but not photorealistic. No gameplay background, characters, other buttons, marketing text, watermarks or logos.
OUTPUT: one standalone horizontal button, fully visible with a slim transparent margin, NOT a sheet or mockup. Genuine transparent alpha outside the rounded button silhouette, including corner cutouts. No white/grey/checkerboard backdrop painted into the image. Keep the panel itself opaque. Wide composition.

## Exact Index editing prompt

Use case: precise-object-edit / background-extraction.
Asset: one finished transparent PNG UI button for Roblox game Podnappers.
Input image is the edit/reference target: cyan-blue studded near-square Index button with an upright blue book icon above the white outlined word "Index". Remove ALL surrounding screenshot scenery and neighboring UI fragments.

Rebuild/enhance this same button sharply at high resolution while retaining its recognizable compact square layout: one rounded square tile, simple blue book icon centered in the upper area, exact label "Index" centered beneath it within the tile.
Keep a bright sky-blue-to-cyan/medium-blue vertical gradient panel, matching a colorful studded Roblox garden game. Add clean small evenly spaced raised square Roblox studs with restrained highlights/shadows; subtle inner top bevel and slightly darker blue bottom edge. Crisp dark outer border, modest corner radius, no oversized extruded frame.
Preserve and sharpen the reference's upright cyan/blue closed book silhouette with darker blue cover outline, lighter page/spine details and a small red bookmark tab at bottom. It is a simple blue book, NOT a purple open spellbook, phone or tablet. No text or logos on the book.
Text must be exactly "Index", upright NON-ITALIC white rounded sans-serif, medium-to-semibold weight, clean narrow black outline, readable at small HUD size. Match the visual treatment of the Shop asset described above: restrained outline, crisp studs and simple plastic bevels. No enormous inflated bubble lettering. Comfortable padding and spacing, no clipping of icon/bookmark/label.
Front-on flat 2D game UI illustration, crisp antialiasing, vivid but not photorealistic. No gameplay background, characters, other buttons, marketing text, watermarks or extra labels.
OUTPUT: one standalone near-square tile, fully visible with a slim transparent margin, NOT a sheet or mockup. Genuine transparent alpha outside the rounded button silhouette, including corner cutouts. No white/grey/checkerboard backdrop painted into the image. Keep the panel itself opaque.

