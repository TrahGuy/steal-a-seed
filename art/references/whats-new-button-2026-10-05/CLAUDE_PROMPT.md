# Claude follow-up prompt: a small "WHAT'S NEW" button and panel

You are the Claude session that works inside Roblox Studio for Podnappers (Steal a Seed), project
`D:\KAPE\Steal an Artifact`. This follows the top-creatures board brief
(`art/references/plot-top-creatures-board-2026-10-05/CLAUDE_PROMPT.md`). Read `AGENTS.md` and the
top of `KB/HANDOFF.md` first. The checkout is shared and full of uncommitted work: preserve every
unrelated change. Nothing like this exists in the game yet: no changelog, update log or "what's new".

## What the owner wants

A **small button** players can press to see the game's **recent changes**, opening a panel that
lists the latest updates, newest first.

## The parts

### 1. The words: one owner-editable data module

- A pure Shared module, for example `Shared/UpdateLog.luau`, holding a list of entries, newest first.
  Each entry has:
  - an id;
  - a date (written as the owner should read it, e.g. "5 Oct 2026");
  - a short title;
  - 2–5 one-line bullets in plain player language.
- No remote and no server: the words ship with a publish, like any other config.
- Show at most the last ~6 entries.
- **Seed it with a DRAFT** written from what `KB/HANDOFF.md` says actually shipped in recent publishes:
  - the new menu look;
  - the Walk Mode switch;
  - the day/night icons;
  - the colourful studded cards;
  - the top-creatures board, only if it really landed.

  List nothing that isn't in the game. No numbers you can't check, no promises of future features.
  Mark the draft clearly in the handoff so the owner rewrites or approves the wording before publishing.

### 2. The button: small, but a real touch target

- Placed by `HudLayout` on desktop, compact (a small desktop window), phone and TV. No hand-placed
  positions.
- At least 44×44 to press, even if the plate is drawn smaller.
- Check every listed screen with `HudLayoutSpec` and add checks for the new button.
- **Know the constraints first** (measured 2026-10-04, see the handoff and HudLayout's comments):
  - The phone's top row has NO spare width. Anything widened or added beside the dock broke two-boost
    rows on 640-px phones.
  - The compact row pushes TELEPORT off the clock's centre if it grows.
  - EVENTS sits under the Bag, and Walk Mode's switch sits under EVENTS on a phone.
- Look for room in the right-hand column or near EVENTS before squeezing any centre band. If no spot
  passes every listed screen, report what you measured and propose the best alternative: for example,
  an "UPDATES" tab inside the EVENTS panel, or a "WHAT'S NEW" row in Settings. Don't force a collision
  through by loosening a spec.
- **Look:** the HUD family (`UIKit.hudPlate` / rail button styling).
  - The icon is native-drawn, like `UIKit.calendarIcon`, e.g. a scroll or note with lines. There is no
    upload; never invent an asset id, and list the missing icon as an asset gap.
  - Hover, press and the controller ring come from the shared `pressPop` / PadFocus.
- **A NEW dot without touching saves:** show a small dot while the newest entry is fewer than N days
  old (say 3, in config), and hide it once the player opens the panel this session.
  - A "seen" flag that survives rejoining would need a profile field. That is a SAVE change: do not add
    one. Note it as an option for the owner.

### 3. The panel: a normal menu

- `MenuKit.modal` with `MenuKit.rimTheme()`: the white studded header, title "WHAT'S NEW" (or
  "UPDATES"), the icon beside it, and the red studded close.
- Laid out by `MenuLayout` for desktop and phone (`covers` on a phone).
- `UIKit.coverRail` / `OpenPanel` behaviour like the other centre panels, so EVENTS and the Walk
  switch step aside off desktop.
- Each entry is a light card:
  - date and title in the label font;
  - bullets in plain dark body text, no outline (the readability rules);
  - newest entry highlighted subtly (e.g. a gold "NEW" tag);
  - scrolls when long.
- Controller: reachable with PadFocus; B closes. Esc / back closes on desktop.
- Reduced motion respected.

## Verify (report honestly)

- Compile and do the unknown-global scan on every touched file.
- Add specs:
  - `UpdateLog` shape: ids unique, newest first, bullet count and length limits;
  - the NEW-dot rule by date;
  - HudLayout placement on every listed screen (desktop sizes, compact windows, all phones including
    notched ones, TV).
- Run the existing specs: `HudLayoutSpec`, `CompactMenusSpec`, `ControllerSpec`, `EventsPanelSpec`,
  `UsabilityAudioSpec`.
- At most one focused automated Play, ONLY by `AGENTS.md`'s throwaway-store procedure: `test_store_on`
  in Edit, `store_guard` SAFE right before the start, confirm the `STUDIO TEST STORE` Ready line, and
  finish with the marker removed and the probe at 0 differ / 0 ZZ.
- In that Play:
  - open and close the panel by click;
  - capture the HUD with the button and the open panel.
- Desktop only unless the owner turns the emulator on; never call a half-scale canvas a phone check.
- Don't foreground, resize or restore the owner's Studio window. Don't stop a Play you didn't start.

## Deliver

- Update `KB/HANDOFF.md` (top entry): files, where the button went and why, the DRAFT changelog text
  for the owner to approve, the asset gap (icon), and what was and wasn't verified.
- No gameplay, economy, price or save changes.
- **Do not commit, push or publish.**
