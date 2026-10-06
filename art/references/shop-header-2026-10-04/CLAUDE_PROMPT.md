Follow-up: restyle ONLY the top/header of Podnappers' Shop using these local references.

Read AGENTS.md and KB/HANDOFF.md, inspect the existing ShopUI/MenuKit/MenuLayout implementation, and preserve all unrelated in-progress work. Inspect the full image and the three detail crops in this folder:
D:\KAPE\Steal an Artifact\art\references\shop-header-2026-10-04

Requested look:
- Replace the Shop's solid green title band with a clean white/very pale cream studded header, a dark keyline and rounded upper corners, like the reference. The studs are a faint background detail, not dark visual noise.
- Keep the title SHOP. Give it large, bold white lettering with a strong dark outline, positioned at the upper-left edge of the header as in the reference. Let it visually sit on the rim, but remain inside the safe, interactive panel bounds: no clipped lettering or overlap with Roblox's top bar.
- Put a suitable approved project Shop icon to the left of the title. Reuse existing art; if no suitable approved asset exists, report that asset gap. The foreign pink chest and the words Exclusive Shop! are reference content, not a request to rename the Shop or import the other game's branding.
- Make the close control a compact red rounded studded button with a darker lower edge, strong dark keyline, and a bold white X with a dark outline. Keep the X and the actual clickable close control separate from the screenshot art.

Implementation constraints:
- Reuse the existing Shop modal, close handlers, keyboard/controller behavior, responsive menu layout and purchase flow. This is visual-only; prices, products, categories, receipts and eligibility do not change.
- Keep the existing compact category/content layout and the current body readability work. Do NOT globally restyle every menu or add thick outlines to small body text. Add an explicit Shop header variant if a shared MenuKit change is needed, leaving unrelated headers/HUD alone.
- Preserve REWARDS & ODDS on the Spin Tickets tab. Reserve clear space for title, icon, header action and close button at every width; use responsive sizing/reflow rather than overlapping or hiding an existing action.
- Aim for a 44 x 44 logical-pixel close hit target on touch. Keep it within safe insets and controller-selectable. Any title/icon overlap with the rim must account for ClipsDescendants so it actually renders.
- Use the existing pale cream stud color asset from D:\KAPE\Steal an Artifact\art\textures\ui-studs-2026-10-04 if it has been cropped/uploaded and verified. Read that pack's manifest/README. Otherwise use a clean pale fallback and report the missing image upload; do not fabricate an asset ID.
- The supplied screenshots/crops have foreign background pixels and baked lettering. Use them as references, not as a stretched screenshot ImageLabel across the header. The narrow white strip is not verified seamless. Do not add a new permanent scene blur.
- Keep stud scale consistent, gradients static and texture subtle. Avoid new per-frame animation or unnecessary large images.

Verification:
Compile/check only touched code and focused affected layout checks. Capture before/after at the same viewport and check a real compact/mobile viewport for title, REWARDS & ODDS, close target and safe-area clipping. Follow AGENTS.md's throwaway-store guard for any automated Play; at most one focused guarded Play, not the whole game test suite. State plainly if mobile/controller checks were not exercised.

Update the game handoff with files changed, upload requirements and checks. No commit, push or publish for this follow-up.

