# Claude follow-up — compact mobile HUD corrections

Read the project AGENTS.md and relevant UI conventions first. Apply the mobile HUD layout using the local screenshot/mockup references, with the owner's corrections below taking priority over anything depicted in the generated mockup.

References:
- D:/KAPE/Steal an Artifact/art/mockups/mobile-hud-2026-10-05/mobile-hud-current-reference.png
- D:/KAPE/Steal an Artifact/art/mockups/mobile-hud-2026-10-05/mobile-hud-recommended-v1.png
- D:/KAPE/Steal an Artifact/art/mockups/mobile-hud-2026-10-05/LAYOUT_BRIEF.md

## Required corrections

1. Rename the visible TELEPORT TO PLOT button label to exactly "plot" (lowercase), with no emoji or icon. Keep its existing teleport-to-own-plot action unchanged; do not rename internal actions/remotes merely to change the caption. Bring BIOMES, plot and OBBY closer together in one compact, equal-height row, in that order. Replace large gaps with about 4–6 logical pixels as an initial target, reducing container padding rather than shrinking readable labels. Reduce the plot button's excess width now that its label is shorter, while preserving a comfortable touch target and matching the other buttons' height. Respect the Roblox-owned top toolbar and safe-area insets; no collisions with timer/system controls.

2. Move the x2 buff icon beside the cash HUD, not into the right action grid. Anchor it to the cash row so it stays next to the cash amount when that amount changes width or the screen scales. Its surrounding background must be fully transparent: no opaque square/card, border, backplate or drop-shadow box. Keep the icon artwork and x2 badge visible; do not make the actual icon invisible. Use the existing asset and preserve current buff visibility, ownership, expiry and click behavior. Do not grant a new buff, duplicate the indicator or change earning calculations. Reflow My Plants / Bag / Events compactly after removing x2; no empty x2 tile or filler button.

3. Make BOTH OTHER PLANTS and WALK MODE switches smaller than the large mockup. Start around 48–52 by 22–26 logical pixels for each visible switch, keeping two aligned rows with short readable labels inline on the left and switches on the right. Keep ON/OFF readable and existing green/red state styling. Reduce panel width, padding and empty space as well as switch visuals. Retain a non-overlapping, approximately 44–48 logical-pixel-high tappable row/hit area; do not shrink usability with the artwork. Avoid transparent hit areas overlapping another control. Keep the pair above the bottom-right jump area and outside the notch safe area.

## Preserve

Reuse existing layout/UI helpers instead of creating a competing HUD. Preserve existing button actions, notification/capacity badges, equipment slots, selected/count states, preference defaults, respawn persistence and permissions. Keep the center and movement/jump areas clear. The mockup's numbered markers, dashed outlines, MOVE AREA/JUMP AREA rectangles and legend are annotation only and must never ship as runtime UI.

This is a layout/appearance task, not a gameplay or economy rebalance. Do not infer exact positions or device-safe coordinates from the AI-generated image.

## Verification / completion

Check a small landscape phone, the opposite landscape orientation/notch side, a larger phone/tablet and desktop. Verify no toolbar/notch/thumb-control overlap, readable large cash values, correct x2 adjacency/transparency, accessible ON/OFF tap targets, and unchanged actions/toggle behavior. Provide before/after captures and distinguish actual device testing from emulator/inspection-only checks. Any Play must follow the project's SAFE throwaway-test-store guard and cleanup, never real saves. Do not commit, push or publish without explicit approval.

