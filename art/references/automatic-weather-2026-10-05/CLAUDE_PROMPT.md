# Automatic Rain / Thunderstorm

UPDATE: `LOWER_RATE_FOLLOWUP.md` in this folder supersedes this brief's 15% chance, 80/20 modes and 30-minute guarantee. The later Claude prompt requests 5% every five minutes, 90% Rain / 10% Thunderstorm and a 60-minute guarantee, keeping three-minute duration. Read that follow-up before applying balance numbers below.

Implement automatic weather in D:\KAPE\Steal an Artifact using the existing WeatherService, with these owner-approved starting settings:

- Enabled: true.
- Check every 300 seconds while at least one player is present and the weather is fully clear.
- Each eligible check has a 0.15 chance to start weather.
- When starting weather, choose rain with probability 0.80 and thunder with probability 0.20. These are conditional mode weights after a successful trigger, not separate independent event rolls.
- Automatically started weather lasts 180 seconds, including the existing opening phase.
- Guarantee a start attempt at 1800 seconds of continuously populated clear time if all earlier rolls failed. This uses the same 80/20 mode selection.
- First eligible check is 300 seconds after the first player arrives, or 300 seconds after previous weather finishes ALL cleanup. Do not roll during opening, active or closing.

These settings replace the earlier 25% and 30% proposals. With checks at 5,10,15,20,25 and a forced start at30 minutes, the expected clear wait is about20.76 minutes; starts are about24 minutes apart including3-minute weather. That is an average, not a promised regular timer.

Implementation:

Read AGENTS.md and KB/HANDOFF.md and inspect current WeatherService, GameConfig.Weather, SeedData.Rain, AdminService and RainEventSpec first. Reuse the current state machine and common start path, with one server-owned scheduler integrated into the service's existing lifecycle. Put tunable scheduling settings in GameConfig.Weather; validate them. Preserve existing manual controls and their owner permission checks. Automatic starts are internal server decisions, never a new client-triggerable remote or a fake admin player.

Weather is per server, matching the existing implementation; do not add global scheduling or MessagingService. Reset the quiet timer after any weather, automatic or manual, completely finishes closing/cleanup. If no players remain while clear, reset the scheduler; the next first arrival begins a fresh quiet window. No empty-server weather, catch-up rolls or immediate startup event. Repeated Start/Stop/Init must not duplicate loops or retain stale scheduling state. Advancing an overdue scheduler may make at most one attempt, never multiple catch-up rolls. A failed start/build must retain the existing cleanup behavior and wait until the next5-minute checkpoint before trying again, with a useful warning rather than per-tick spam.

Preserve the existing +25% online plant-income boost, Rain/Thunderstorm pod batches, guardian behavior, announcements, evacuation, fade/cleanup, world day/night timing, other event interactions, odds and saving behavior. Existing weather icons and popovers should reflect automatically started events through the same attributes/remotes as manual events. No new countdown HUD is needed.

Verification:

Use the existing fake clock/player/terrain/nest seams and inject deterministic RNG where needed. Focused tests should prove no check before5 minutes, failed rolls advance correctly, success selects the correct mode and180-second deadline, the30-minute guarantee works even with all failed draws, empty-server handling, no rolls in any occupied weather phase, manual weather resets the window, no duplicate/catch-up starts and failure retries are bounded. Run existing weather/affected income and lifecycle specs as needed. Test simulated time, not a30-minute real wait. If Play is necessary for actual UI/biome confirmation, use one guarded throwaway-store Play following AGENTS.md and clean it up. Report what you verified and what remains unverified. Update the handoff. Do not commit, push or publish.

