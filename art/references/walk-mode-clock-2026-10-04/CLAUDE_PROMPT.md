# Follow-up to the full UI pass: Walk Mode switch and cycle timer

Read the global UI brief and existing WalkModeUI.client.luau, WorldClock.client.luau, HudLayout.luau and GameConfig before editing. This is an additional REQUIRED part of the full UI art pass, not a separate movement/cycle feature.

## Local reference assets

Inspect the PNGs here:
D:\KAPE\Steal an Artifact\art\references\walk-mode-clock-2026-10-04

The original reference says SLOW MODE and includes another game's Speed/Friend Boost readouts. Those are reference context only: keep our label WALK MODE and do not add the foreign readouts or change their systems.

Clean transparent companion cycle icons, generated from the reference style, are bundled in the SAME folder as the references:
D:\KAPE\Steal an Artifact\art\references\walk-mode-clock-2026-10-04

- cycle-moon-cloud-v1.png
- cycle-sun-cloud-v1.png

Read README.md, manifest.json and icons-manifest.json; inspect the actual PNG files visually, not just the filenames. All references, crops and generated icons are in this one folder; do not ask for a repeat upload if your session can access these files. If your session cannot open local files/images, state that before proceeding from guesses. The icons need real Roblox Image upload IDs before live use; do not invent IDs. Keep a suitable existing/native fallback if not yet uploaded, and list the missing uploads.

## 1. Replace the square Walk Mode presentation

Use the reference's compact horizontal switch design: WALK MODE: OFF/ON as a readable outlined label above a slim rounded light track, with a solid colored sliding thumb and a dark keyline.

- OFF: red thumb on the LEFT, WALK MODE: OFF.
- ON: green thumb on the RIGHT, WALK MODE: ON.
- Use native UI pieces/live labels rather than a screenshot or baked state image. Slightly polish proportions, gradients and edges to fit the new shared theme.
- Make the whole widget a practical touch/click target (around 44 logical pixels high), not just the tiny thumb. Preserve controller focus/activation and visible words so state is not color-only. Any brief slide animation must respect reduced motion.
- Replace the old square layout in compact mode too: update HudLayout's walk rect and related spacing/collision checks to fit a genuinely horizontal switch. Reflow nearby controls as needed through HudLayout, not hardcoded placement. Stay clear of safe insets, Events, Roblox controls and the joystick; do not hide half the label on a phone.
- Preserve the current server-confirmed behavior. Keep the existing remote/action, replicated state, saved preference, respawn/obby/menu visibility and server movement rules. ON still means the existing walking cap, OFF still means normal movement; do not flip that meaning. No optimistic authoritative state or local WalkSpeed writes.

## 2. Add an icon to the day/night countdown

Give the HUD clock a compact cycle icon next to readable WHITE countdown text, with only the backing/outline necessary for contrast. Use a moon/cloud when counting down to night and a sun/cloud when counting down to dawn. Keep the label unambiguous: NIGHT IN m:ss / DAWN IN m:ss, or equivalent concise wording that still tells players what happens next.

- The countdown stays WHITE during ordinary daytime.
- It turns RED only while the current phase is DAY and night is approaching inside the existing GameConfig.WorldCycle.WarnSeconds window (currently 45 seconds). Read the config; do not duplicate the number in several UI scripts.
- At NIGHT, show the countdown to DAWN in WHITE again. A fifteen-second night must not accidentally remain red just because its time-left is under the threshold. Reset at dawn too.
- No red baked into icon assets or timer images; no default red timer, continuous flashing or unrelated countdown recoloring.
- Use the existing server phase/deadline attributes and Workspace:GetServerTimeNow. Preserve boundary settling, late-join correctness and invalid/missing-state handling. Do not start a second countdown loop that drifts or alter the 420-second day/15-second night.
- Scope this to the HUD clock. Keep WorldClock's lighting/weather/disco ownership, barrier logic and separate world-wall timer intact. The cloud artwork is decorative, not an active weather-event indicator.

## Focused checks

Include these checks in the planned full UI verification, rather than starting an additional Play solely for asset preparation: OFF/ON labels and thumb sides, rejection/respawn state, ordinary day white, near-night red, actual night white and dawn reset, late join/phase boundary, and compact/mobile collisions. Preserve real 44-ish touch targets and controller navigation. Follow the guarded throwaway-store procedure for any Play, no real saves/purchases or external RSVP actions. Do not claim real-phone verification from a half-scale image.

Update the handoff and report asset IDs still needed. No commit, push or publish.

