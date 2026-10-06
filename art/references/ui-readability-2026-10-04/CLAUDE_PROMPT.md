Follow-up: fix UI readability and card/button separation after the bright recolor. Keep the cheerful green/mint theme, but make every label readable at normal playing size.

Work in D:\KAPE\Steal an Artifact. Read the latest handoff and inspect all five current screenshots in:
D:\KAPE\Steal an Artifact\art\references\ui-readability-2026-10-04

These are the current problem examples: Shop Passes, Speed, Cash, Spin Tickets and the Bag. Do not ask me to upload them again.

1. Fix text treatment first
The current MenuKit.text helper still adds a dark UIStroke to dark body text. Inspect that and the Bag's separate text builders; this is contributing to the muddy, cramped letters.
- On light cards/panels: plain dark forest/charcoal text, NO dark outline or shadow around small dark letters.
- Keep the playful outlined type for large white menu headings and appropriate action labels; do not remove strokes globally from rarity FX, dark tiles or HUD text.
- Use a clean medium-weight body font for benefits, descriptions, amounts and small sidebar labels if the current decorative font remains crowded.
- Keep clear hierarchy: bold card title, smaller readable benefit, then a distinct action/price region. No shrinking all text just to force it to fit; allow wrapping and remeasure after font/stroke changes.

2. Separate cards and controls
- Keep the mint shell, but give product cards a clearer near-white surface, dark thin border and modest padding.
- Inactive categories: pale neutral surface with plain dark text. Selected category: a clearly stronger green face, readable contrasting label and the existing selection mark.
- Buy buttons: a distinct darker green or blue gradient with clear text, not the same lime used by the header. Keep the readable white Robux-price pill and actual current price.
- OWNED/completed: warm gold with plain dark text. Disabled: muted neutral, still readable and genuinely disabled.
- Keep hover, pressed and controller-focus states distinct; color alone should not be the only selection cue.
- Gradients should be restrained behind text, not busy stud textures or animated shine passing over labels.

3. Bag cards
The current gray-green tile faces look muddy against the mint frame. Keep their dark-card identity, but use a deeper, more opaque emerald/slate face and clearly legible light names.
Preserve actual rarity/size colors and existing text/border animation. If a rarity color is hard to read, adjust its backing or outline rather than changing what the rarity means.
Keep silhouettes, images, previews, icons, counters, favorites, selected rings and tooltip behavior intact. Do not change hotbar/HUD styling unintentionally through shared tokens.

4. Shared implementation and verification
Use semantic text/background styles in BagLook/MenuKit and the Bag renderer, not one-off fixes for each screenshot. Check every affected shared consumer, including My Plants, Almanac, Events and Admin if present.

Aim for at least 4.5:1 foreground/background contrast for normal text, checking the actual gradient behind the label, and visually inspect the result. This is a readability target, not a claim of full WCAG compliance.
Reference: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html

Keep existing compact layouts, discovery concealment, menu actions, prices, purchases/receipts, income, rarity, storage and gameplay unchanged. No new features or animation loops.

Compile touched code and run focused style/layout checks. At most one guarded throwaway-store Play for the representative screens; no full suite or real purchases. Check normal desktop and a genuine supported short-phone layout; a doubled-scale canvas with clipping does not count as a passing phone check.

Provide before/after captures at the same viewport and scale. If phone tooling is unavailable, state that clearly. Finish in Edit, remove helpers, turn the test store off and update the handoff. Do not commit, push or publish.

