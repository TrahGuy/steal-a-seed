# Full Podnappers UI art pass — make the entire interface feel finished

Work in D:\KAPE\Steal an Artifact. This intentionally expands the earlier Shop-only header request: apply one coherent visual language across ALL existing player-facing UI and the Admin Console, not only the Shop. You have creative freedom on presentation within the constraints below. Implement the pass; do not stop at a proposal or leave half the interface on the old theme.

Read AGENTS.md, the applicable project skills and the latest KB/HANDOFF.md before editing. Inspect the real code, dirty working tree and existing shared components. Preserve unrelated/concurrent work and reuse existing systems.

## Local references — no re-upload needed

Read each pack's README/manifest and inspect the relevant images:

- D:\KAPE\Steal an Artifact\art\references\shop-header-2026-10-04 — white studded rim, large white outlined title, icon and red studded X.
- D:\KAPE\Steal an Artifact\art\references\shop-buy-buttons-2026-10-04 — green studded buy buttons, exact reference crops and a blank transparent green button base.
- D:\KAPE\Steal an Artifact\art\textures\ui-studs-2026-10-04 — twelve-color atlas, 4 columns x 3 rows, exact 362x362 crop rectangles.
- D:\KAPE\Steal an Artifact\art\references\ui-recolor-2026-10-04 — existing screens and bright/studded inspiration.
- D:\KAPE\Steal an Artifact\art\references\ui-readability-2026-10-04 — current text/card contrast problems that MUST be fixed, not carried into the new look.
- D:\KAPE\Steal an Artifact\art\references\walk-mode-clock-2026-10-04 — REQUIRED follow-up: replace the compact square Walk Mode UI with a red-left/green-right horizontal switch, add cycle icons, keep countdown white except DAY near-night warning; read its CLAUDE_PROMPT.md. All seven reference/crop/icon PNGs are now bundled together in this folder, with manifests and exact generation prompts.

Older briefs are context, not a conflicting scope restriction: this request now authorizes deliberate styling of the inventory, HUD controls and all menus. It does NOT authorize changing game rules.

## Scope: inventory every existing surface, then finish it

Create a brief checklist of actual UI scripts/shared renderers and use it to avoid missed legacy screens. Cover:

- Shop: all categories, product cards, details, live Robux prices, OWNED/OFF SALE/loading states and REWARDS & ODDS.
- Inventory/Bag: categories, item cards, selection/details, counters, search, favorites and storage indication; hotbar tiles, previews, slot numbers, stack counts and trap 3x/REMOVE.
- My Plants: PLANTED/STORED, capacity, growing pod timers, income, plant/equip/unequip actions and Equip Best.
- Plant Almanac: biome pictures/names, search/filters, locked silhouettes, rarity cards, progress, details and claims.
- Admin Console: the BROADCAST, EVENTS, WEATHER, ITEM GRANTS, PLAYER TOOLS and ADVANCED sections, their selectors, help/status text, inputs and action buttons.
- Posted Events: the EVENTS entry button itself, list/detail panel, thumbnails, schedule and RSVP/live/loading/error/empty states. Make the Events button visibly part of the same HUD family, not a plain leftover text control.
- All remaining existing UI: Settings, Marigold/equipment Shop, confirmations, reward screens, spinwheel surrounding controls/info, chest/community/sacrifice controls, navigation buttons, notices/toasts, boost/weather popovers, tutorial/action prompts and any existing loading/offline panels. Do not invent a missing feature just to add a new screen.

## Art direction

Aim for playful, premium-looking Roblox UI based on the reference: clean cream/white or pale mint surfaces, subtle raised square studs, dark keylines, bold headings, colorful gradient buttons and clear product/item cards.

- Major menu headers: white/pale studded rim, suitable approved project icon beside the actual menu name, large white heading with a strong dark outline, red studded rounded close button. Use each menu's own title, not the reference's Exclusive Shop! wording.
- Studs should be a quiet accent. Keep their scale consistent; do not stretch square studs into rectangles or put busy texture behind every sentence. Prefer clean backing behind dense descriptions, prices and form inputs.
- Consistent functional button colors: green primary/equip/buy, blue secondary/navigation, gold claim/owned/completed, red close/remove/destructive; muted readable disabled. Premium accents may use purple where appropriate. Use labels/icons as well as color.
- Separate hovered, pressed, selected, disabled and controller-focus states. A simple brief press response is enough; respect reduced motion. Avoid continuous shine crossing text or new per-frame animation loops.
- Inventory/item previews may retain a richer opaque charcoal/emerald backing so silhouettes and rare plants stay visible. Keep the compact approved inventory/hotbar structure. Do not turn the hotbar into a huge white panel or obscure the play area.
- Keep actual rarity/size colors and existing animated rarity/size effects. A themed card must not overwrite the item's meaning. Preserve all currently approved icons, real pod silhouettes, plant previews and the Bloomrunner artwork/effects.
- Replace generic emoji in affected controls with the project's approved icons where available. Check the real icon configuration, not remembered IDs. For a genuinely missing asset, use a simple readable temporary native control/fallback and list the asset gap; do not pretend a placeholder is the final icon.

## Readability is mandatory

Fix the existing dark-outline-on-dark-small-text problem. Dark text on light cards should be plain, readable and unoutlined. Reserve heavy outlines for large white headings and suitable button labels; do not strip rarity/HUD outlines globally. Use comfortable sizes, sane wrapping, padding and spacing. Do not solve clipping by making every label tiny. Keep amounts, benefits and state text readable against the actual gradient behind them.

## Shared implementation; mobile first

The owner's new Walk Mode/clock follow-up is mandatory: build a live horizontal switch instead of the old square compact control, preserving server-confirmed ON/OFF semantics. Use moon/cloud for countdown to night and sun/cloud for countdown to dawn. Timer text is white except when phase is DAY and left <= WorldCycle.WarnSeconds (currently 45 seconds); NIGHT countdown returns to white. Preserve server clock/boundary settling and do not change cycle durations, lighting or barrier logic. See the dedicated local follow-up for assets and collision/state checks.

Build this through shared theme tokens and explicit component variants using the existing BagLook/SlateLook/MenuKit/UIKit and inventory renderers as appropriate. HUD and menus can use different backgrounds but should share typography, icons, button states and visual polish. Do not blindly change global colors and hope every consumer still works; audit actual consumers.

Preserve responsive layout architecture, HudLayout's positions, safe insets, touch controls, camera visibility and menu stacking/input behavior. Keep touch targets around 44 logical pixels where space permits and controller focus visible. Check short/narrow phones and supported orientations, not only a desktop mockup. Reserve room for header actions such as REWARDS & ODDS and every close button. Account for ClipsDescendants if heading/icon art overlaps a rim. Keep Admin sections compact and readable, with existing permission boundaries intact.

## Assets and game behavior

Crop/upload texture variants only as genuinely required. Local PNG files are not Roblox image IDs. Do not invent IDs, silently upload under an unintended owner or stop all independent UI work for an optional missing texture. Keep a clean solid/native fallback until the selected asset has a valid verified ID; report upload requirements precisely. Raw reference crops contain foreign background, branding, quantities and prices: never use a screenshot as the live purchase interface. Use the blank button base plus our actual currency icon and live product-price UI.

This is a visual/presentation pass. Do not change economy, progression, rewards/odds, product prices or receipt logic, equipment behavior, plant storage, trap rules, guardian recovery, event modes/timing/global messaging or save schemas. No new notifications, features, forced prompts or purchases. Preserve the current icon-based boost/weather presentation and toast placement above the hotbar.

## Verification and finish

Compile touched code and run focused checks for affected shared styles/layouts and UI states. Capture representative before/after images at the same viewport/scale, including Shop, Bag, My Plants, Almanac, Events and Admin. Verify the actual small-screen layout: do not call a clipped half-scale canvas a passing phone check. Exercise representative selection/close/category/details states without real purchases, RSVP changes or other external mutations.

At most one focused automated Play, following AGENTS.md's throwaway-store procedure: marker on in Edit, store_guard SAFE immediately before starting, confirm the STUDIO TEST STORE Ready line, then clean helpers and marker and finish in Edit. Do not run the entire unrelated game suite. State exactly what phone/controller/asset loading checks could not be performed; do not imply live-device verification from arithmetic alone.

Update KB/HANDOFF.md. Summarize completed surfaces, remaining UI/asset gaps, changed files and verified results. Do not commit, push or publish. Hand off a cohesive finished visual pass, with any genuinely blocked items clearly separated.

