# Recommended mobile HUD mockup — 2026-10-05

Owner corrections supersede the generated image: top action gaps tighter; TELEPORT TO PLOT caption becomes exactly "plot" without emoji or icon, retaining the same teleport action; x2 buff icon belongs beside cash with a fully transparent background, NOT in the right action grid; both switches visibly smaller with comfortable tap targets. See `CLAUDE_FOLLOWUP.md` for the implementation brief. The image-editing prompt below is a historical record, not the revised instruction.

Local design proposal only. No game UI implementation, Studio changes, publishing or data changes.

## Deliverables

- `mobile-hud-recommended-v1.png`: full-resolution annotated recommended layout, generated with the built-in image editor.
- `mobile-hud-current-reference.png`: untouched copy of the owner's screenshot.
- `*-preview.jpg`: compressed display-only previews for the before/after comparison; full PNGs preserved.

## Recommended changes

1. Keep Biomes / plot / Obby in one equal-height top row with compact gaps (initially about 4–6 logical pixels); plot is the exact new caption with no emoji/icon, same teleport action and reduced excess width. Timer at top right. Do not reposition Roblox-owned toolbar controls. Move the separate Admin HUD entry into Settings, still restricted to authorized admins. In-world ADMIN name tag is not a HUD button and stays.
2. Keep Index / Shop / Settings on a compact equal-tile left rail, with existing badges and collapse behavior. Currency goes beneath it, above the movement control area.
3. Reflow My Plants / Bag / Events as compact right-side actions, preserving notification counts and bag capacity. Put the x2 buff icon beside the cash amount with transparent surrounding background, no tile/backplate; preserve its existing behavior and visible artwork.
4. Put Other Plants and Walk Mode in a smaller compact two-row panel below those actions, labels left and switches right. Initial visible switches about 48–52 by 22–26 logical pixels, with separate non-overlapping 44–48-pixel-high tappable rows. ON/OFF states stay visible. Use device safe-area/notch insets rather than fixed screen-edge offsets.
5. Narrow hotbar overall about 15%, retaining five equipment slots plus the existing bag shortcut, counts and selected state. Center it with bottom inset and leave both lower thumb zones available to actual Roblox movement/jump controls.

Target approximately 56–60 logical-pixel icon tiles, 8-pixel gaps, and at least 44–48 logical-pixel interactive targets; these are proposed starting sizes, NOT measurements verified from this generated mockup. Do not shrink touch targets to make the visual fit. Collapse secondary actions on smaller phones instead. Preserve permissions, business logic, hotbar indices and preference state when later implementing.

The colored dashed outlines, numbered markers, MOVE AREA/JUMP AREA rectangles and legend are design annotations only. Do not implement them as game UI or create extra movement/jump buttons. The screenshot was edited by AI, not rendered from an implemented layout, so dimensions/icon details are approximate. Actual mobile notch/rotation/touch testing remains necessary.

## Exact image-editing prompt

Use case: ui-mockup / screenshot compositing.
Create an annotated MOBILE HUD LAYOUT RECOMMENDATION from the attached landscape phone screenshot of a Roblox game. This is a design mockup, NOT a thumbnail, and NOT an actual implemented screenshot.

Preserve the phone's black rounded landscape bezel and RIGHT-HAND NOTCH, gameplay scene, green studded ground, sky, garden structures, camera and small central player character. Preserve the actual Roblox system toolbar at TOP LEFT (Roblox/menu/chat/microphone) untouched; never replace it with game controls. Preserve the in-world ADMIN name tag as part of the world, but remove the separate large floating ADMIN HUD button from the center/top row and make Admin accessible as a small submenu entry inside Settings instead.

Rework ONLY game HUD button positions, spacing and scale, matching the screenshot's outlined colorful studded/rounded Roblox UI styling and real icons as closely as possible. No extra products or imagined gameplay.

RECOMMENDED LAYOUT:
1. TOP ACTION STRIP: to the right of the Roblox toolbar, one aligned compact row: blue BIOMES, wider green TELEPORT TO PLOT, dark OBBY. Same consistent height, about 15% less bulky than the original, comfortable gaps. Keep moon logo + NIGHT IN 6:32 as a compact dark status badge at the TOP RIGHT. No second ADMIN row.
2. LEFT NAV RAIL: Index (with red 15 notification badge), Shop, Settings, a slim vertical stack below Roblox toolbar with equal square buttons, consistent gaps and a small collapse handle. Make each button approximately 56–60 logical pixels with a legible label, NOT tiny. Keep this rail out of the central gameplay field.
3. RIGHT ACTION GRID: under the timer, an aligned two-column by two-row group: x2 cash icon and My Plants icon (red 1 badge), then Bag (capacity 21/24 badge) and purple Events. Use consistent approximately 56–60 logical-pixel tiles and 8-pixel gaps. Keep the grid inset from the physical right notch and screen edge. No labels crossing other buttons.
4. RIGHT SWITCH PANEL: directly BELOW that action grid, a single compact dark translucent panel, two aligned rows:
    OTHER PLANTS  [green ON switch]
    WALK MODE     [red OFF switch]
Labels are left-aligned, each switch is right-aligned in the same column. Put ON/OFF INSIDE or immediately beside its own switch, not in a long floating label above it. Both switch rows have roomy touch targets, at least ~44 logical pixels high. Entire panel ends ABOVE the bottom-right thumb/jump area and stays left of the right notch; the notch must never cover any control.
5. BOTTOM CENTER HOTBAR: six consistent compact slots, five equipment thumbnails from the original screenshot plus the backpack/capacity shortcut. Retain gold selection border on slot 5 and count badges, but reduce overall row width/bulk about 15%, evenly space and align the slots. Keep a safe gap above the bottom bezel. Center it between, NOT inside, the bottom-left and bottom-right thumb zones.
CURRENCY: move the blue 9.42T and green $110B display to a compact stacked badge under the left nav rail, ABOVE the lower-left thumb zone. Keep values readable, not enormous. No overlap with hotbar.
Leave the central gameplay/aim area free of game HUD panels. Leave bottom-left movement and bottom-right jump regions EMPTY, shown only with faint dashed reserved-zone outlines labeled "MOVE AREA" and "JUMP AREA" as mockup annotations, not new live buttons. No invented joystick activation, no giant modal.

PRESENTATION:
Show ONE recommended screen in the same landscape phone frame on a clean neutral light background. Expand the board outside the phone only as needed for annotations. Above the device, a small heading "RECOMMENDED MOBILE HUD".
Below the phone, exactly five neat annotated legend items linked by small numbered markers 1–5 at their corresponding HUD groups. The five legend texts:
"1  Top actions — one row"
"2  Left navigation — equal tiles"
"3  Right actions — 2 × 2 grid"
"4  Switches — aligned, notch-safe"
"5  Hotbar — smaller, thumb-safe"
Do not fill the gameplay center with callout arrows or explanatory paragraphs. Markers and reserved-zone outlines are design annotations only, clearly distinct from game UI.
Use clean UPRIGHT readable annotation typography, no italic, no thick comic bubble callouts. Avoid duplicated icons, clipped text, inconsistent icon sizing, switch overlaps, controls behind the notch or adding unrequested features.
Keep the mockup crisp and legible, with faithful real green studded gameplay background, not a newly rendered cinematic world.

## Review

Viewed generated output: all five legend labels/groups present, both switch states readable, no central Admin HUD button, in-world name tag remains, input zones reserved, right group inset from visible notch. Original values/equipment remain visually recognizable. Final source and generated PNGs preserved. Before/after inline comparison contains only embedded image previews, no network requests or game interactions.

