# Codex brief: event icons on STUDDED round badges (2026-10-12)

The owner: Enchanted Mist needs an event icon, and "this time, it has a studded background; we also do it for the
other events too". So make one family of round event badges: a studded coloured disc with the event's object on
it. Claude wires them in code; this brief covers the art only.

## Where they show

- The round event/boost icons over the hotbar (`GameConfig.BoostIcons`): drawn at **24 to 40 px**.
- The source icons on notices (`GameConfig.SourceIcons`): about **20 to 30 px**.

**Small-size readability is the main requirement.** Every badge must read at 24 px.

## The set

| File | Event | Badge colour | Object, centred on the badge |
|---|---|---|---|
| `event-enchanted-mist.png` | Enchanted Mist (NEW) | deep teal fading to dusky violet, mint stud highlights (the Mysterious Pod card's mist palette: `art/textures/mist-studs-2026-10-11/studs-enchanted-mist-v1.png`) | a plump glowing mint-green **Dewberry** with a dewy sheen and one small leaf, wrapped by one soft mint mist swirl, with a tiny pale crescent moon beside it |
| `event-rain.png` | Rain | sky blue | the existing rain cloud + drops: `art/icons/boosts/rain-256.png` |
| `event-thunderstorm.png` | Thunderstorm | deep indigo-navy | the existing storm: `art/icons/boosts/thunderstorm-256.png` |
| `event-disco.png` | Disco | hot magenta-purple | the existing disco ball + notes: `art/icons/boosts/disco-256.png` |
| `event-ticket-shower.png` | Ticket Shower | warm gold | the existing tickets: `art/icons/inventory/spin_tickets-256.png` |
| `event-pod-rush.png` | Pod Rush | bright orange | the existing pod + stopwatch event icon: find `pod-rush-v1-512.png` (see `output/imagegen/podrush/POD_RUSH_ICONS_V1_DELIVERABLES.md`) |
| `event-server-luck.png` | Server Luck (OPTIONAL; it sits in the same row) | emerald green | the existing clover: `art/icons/products-2026-10-11/server_luck.png` |

**Keep each existing object's design.** Redraw it as the same object, so players still recognise it. Only the
badge behind it is new.

## The badge, the same for all

- **Canvas:** 512 x 512 PNG with a genuinely transparent background outside the disc. No square plate, no
  checkerboard baked in.
- **Disc:** fills about 92% of the canvas width, centred.
  - A thick dark outline ring (near-black navy, like the existing icons' outline).
  - A thin lighter inner rim.
  - Inside, the event colour as a plate of raised **square studs**: the game's stud look (subtle top-left
    bevel highlight, small lower-right shadow), style reference
    `art/textures/colorful-studs-2026-10-04/studs-coral-red-v1.png`.
  - **Few, large studs:** about 5 to 6 across the disc's diameter, so they still read as studs at 30 px instead
    of noise. A soft darkening toward the centre behind the object, so the object pops.
- **Object:** about 60 to 68% of the disc's width, centred. It keeps its own thick dark outline and the existing
  glossy sticker shading, and it may overlap the inner rim slightly, never the outer outline. Lit from the upper
  left.
- **No text, numbers, logos or Robux marks.** Distinct colours, so the badges tell apart at a glance side by side.

## Deliver

In `art/icons/event-badges-2026-10-12/`:

1. Each badge at 512 x 512.
2. A **tight-cropped** copy of each in `art/icons/tight/`: the disc plus about 2% padding, square and
   transparent. The game uses ScaleType Fit.
3. `sheet.png`: every badge at 64, 40, 30 and 24 px on three backgrounds: sky blue, field green and a dark night
   HUD. Next to them, the current flat icons (rain-256, disco-256), for comparison.
4. `README.md`: each file, the prompt used, the generated original's path, and checks for each badge:
   - corner alpha 0;
   - nothing outside the disc;
   - that it reads at 24 px.

Don't upload, wire, change code or GameConfig, or publish. The owner uploads the approved badges to the
CrazyCozy Games group and sends the ids; Claude checks them and wires them. Never `git add -A`.
