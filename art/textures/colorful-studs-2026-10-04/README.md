# Colorful studded UI backgrounds

Six separate 1254 x 1254 PNGs generated with the built-in image tool from the owner's fifth screenshot as a style reference. No text, prices, icons or borders are baked in.

- `studs-lime-green-v1.png` — vibrant lime green upper area softly transitioning to rich grass green below.
- `studs-sky-blue-v1.png` — bright cyan upper area softly transitioning to saturated sky blue below.
- `studs-royal-purple-v1.png` — bright orchid violet upper area softly transitioning to royal purple below.
- `studs-gold-v1.png` — warm lemon gold upper area softly transitioning to rich golden amber below.
- `studs-coral-red-v1.png` — bright coral red upper area softly transitioning to saturated cherry red below.
- `studs-rainbow-v1.png` — smooth horizontal spectrum from coral red through golden yellow, lime green, cyan blue and violet, vibrant but balanced.

## Notes for Claude

- Owner-supplied uploaded Image IDs are now recorded in `manifest.json` and `CLAUDE_UPLOAD_FOLLOWUP.md`. Runtime loading and permissions are not yet verified; keep fallbacks until loaded.
- Use colorful surfaces primarily behind Shop cards and selected featured panels. Preserve existing rarity/size meanings instead of arbitrarily assigning rarity colors.
- Keep the white studded outer headers, visible selected borders, and existing real icons. Do not change prices, products, gameplay, permissions or purchase logic.
- Keep the texture behind text and previews. Use a quiet solid/translucent text plate where needed; verify readability on actual phone-size UI before broad use. Rainbow suits occasional featured/event panels, not every inventory cell.
- These contain directional gradients and are NOT seamless repeating tiles. Crop with preserved aspect ratio for rectangular panels; do not stretch square studs into rectangles. A cropped panel samples only part of the gradient.
- Generation produced slight stud-density/bevel differences between colors. Normalize apparent scale when applying; these are not pixel-identical recolors.
- Visual appearance and file dimensions checked locally. Owner subsequently supplied upload IDs. No upload by this agent, runtime image-load test, mobile check or UI code integration performed.

`reference-colorful-shop.png` is the original style reference, not a runtime asset. Full exact generation prompts are in `generation-prompts.md`.

