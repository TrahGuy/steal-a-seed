# Claude prompt — bright, gradient UI recolor

Work in D:\KAPE\Steal an Artifact. Read project instructions and the latest handoff, preserve other work, and implement a VISUAL-ONLY recolor of the current compact menus. Do not commit, push or publish.

## Local references — no manual upload needed

Open all seven PNGs under:
D:\KAPE\Steal an Artifact\art\references\ui-recolor-2026-10-04

Images 01-04 show our current My Plants (Planted and Stored), Shop and Plant Almanac. Images 05-07 show the brighter visual language I want. README.md names every picture; manifest.json preserves its source identity. Read these local pictures directly; do not ask me to upload them again.

## Visual direction

Our current forest-slate panels and muted buttons are too dark. Make the shown menus brighter, colorful and playful like the style references, while keeping our own plant-game identity and compact design.

- Light mint/cream shells with a subtle vertical gradient, not a large near-black sheet. Suggested starting colors: #F1FFF6 to #DCEEDF.
- Fresh leaf-green headers and selected tabs: #91E849 to #47B63B. Use visible selected-state contrast, not just a barely changed background.
- Main actions such as EQUIP BEST, PLANT and eligible CLAIM: lively green gradients with a bright top and darker bottom.
- Secondary/navigation controls: restrained sky-blue/teal or pale neutral gradients, with clear visual separation from main actions.
- OWNED/completed states: warm gold (#FFD96B to #E5A82E). Keep disabled controls distinctly muted and non-interactive.
- Close buttons: red/coral gradient, clear white X and dark outline. Keep UNEQUIP/RETURN semantics unchanged; a recolor is not a confirmation-flow redesign.
- Stronger clean dark borders and readable outlined titles, inspired by the screenshots without exaggerating every tiny line. Body labels on light panels should use dark forest text; do not leave pale text unreadable on pale plates.
- Add subtle, low-contrast Roblox stud details where they help, not behind every label or over creature previews. Reuse only project-owned assets; do not extract another game's textures/icons from these screenshots or invent upload IDs. If a new texture is needed, report that asset requirement.
- Item-card backgrounds may have a gentle color tint/gradient drawn from the item's actual rarity, while keeping the model readable. Preserve the existing rarity text and outline effects, approved rarity colors and separate size-tier effects. Never recolor a species into a different rarity or expose locked Almanac names/creatures.

Use native static UIGradient wherever practical. Preserve existing hover/press feedback and existing rarity animation; no new per-button infinite shimmer loops, flashing gradients or heavy animated background. Respect reduced motion.

## Shared implementation, not another UI system

Inspect the current GameConfig.BagLook, MenuKit, UIKit and the individual GardenUI, ShopUI and IndexUI renderers. Put shared colors/gradients in shared theme tokens/helpers rather than copying a new palette into each script.

Keep Bag/Inventory styling consistent where it uses the same theme. Check other consumers of shared helpers for unintended contrast changes, including Admin or Events if those queued features are present by then. List the menus affected by shared token changes; do not independently redesign unrelated HUDs or the spinwheel.

## Preserve everything that works

Keep existing compact panel sizes, card grids, sidebars/mobile dropdowns, safe areas, scrolling, responsive sizing, image icons, preview framing and controller/touch behavior. Fix only minor padding or clipping genuinely caused by the visual treatment; do not rebuild the layouts into the other game's long rows.

No changes to item data, rarity, income, storage capacity, timers, planting/pickup, Equip Best ranking, purchase/receipt handling, discovery, claim rewards, hotbar assignment or server validation. The foreign screenshots do NOT authorize adding kg, mutations, Claim All, Grow All or new cooldown mechanics.

## Only necessary checks

Compile touched code and verify shared color/state behavior. Check one desktop and one short landscape-phone layout for contrast, clipping, selected/disabled/owned states and unchanged previews. Use focused existing layout checks if layout code must change; do not run the entire suite.

If real rendering needs Play, use at most one guarded throwaway-store session. Never read/write real saves or make real purchases. If phone tooling is unavailable, report the phone check as unverified instead of claiming it passed.

Finish in Edit, remove temporary helpers, turn the test-store marker off, confirm touched scripts match disk, and update the handoff. Provide a small set of before/after captures and a concise changed/not-verified report. Nothing committed, pushed or published.

