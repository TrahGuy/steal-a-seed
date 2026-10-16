# POD RUSH EVERY HOUR — the plan (2026-10-16)

**Status: APPROVED 2026-10-16.** The owner picked the cheaper idea from the Sprout Journey talk ("i like
that cheaper idea": put POD RUSH on a schedule), asked for "a lot of question", and took every
recommendation. Built by Claude (desktop), "Build it here".

## The owner's answers

| Question | Answer |
| --- | --- |
| How often? | **Every hour.** |
| Where in the hour? | **:30**, halfway between rains (the rain runs :00 to :03). The two never overlap. |
| How long? | **5 minutes, as now.** Night waits for it, as today. |
| Every server at once? | **Yes.** Each server reads the clock, like the rain: no messages. A player who changes server mid-rush keeps their count. |
| Rewards? | **Same as now:** BRONZE 3 pods = 1 spin; SILVER 7 = 3 spins + the training boost; GOLD 12 = 5 spins + a Titan pod. |
| Levels? | **Keep 3 / 7 / 12.** |
| An admin event running at :30? | **Skip that hour.** One mini event at a time, as today. |
| The Enchanted Mist on at :30? | **Let both run.** |
| Heads-up? | **A 1-minute warning** to everyone in the server at :29, then the usual start pop-up and sting. |
| A timer for the next rush? | **No timer.** The warning is the heads-up. |
| Players still in their first loop? | **Hold its pop-ups**, the quiet first loop's rule: no warning or start pop-up for them. The rush still runs round them, and pods they bank still count and pay. |
| Off switch? | **A config switch** (GameConfig); turning it off needs a publish. |
| What's New? | **Yes, one line.** |
| Analytics? | **Tag** PodRushEnded as scheduled or admin. |
| Who builds it? | **Claude, here.** |
| Testing? | **Specs and one guarded Play** on a throwaway store, the clock forced to :29: the warning, the start and the end, once. |

## Where it lives

- **The numbers:** GameConfig.PodRush.Auto (Enabled, PeriodSeconds 3600, OffsetSeconds 1800, WarnSeconds 60, the warning's words). The length is the mode's own (MiniEvent.Modes.podrush, 300 s).
- **The slots:** Shared/PodRush (slotAt, autoId, isAuto). A slot's rush is named "auto" and its start, so every server, and a profile's saved row, agree which rush it is.
- **The schedule:** MiniEventService.HourlyStep, run by the service's live loop before Step (never by Step itself, so a spec's own clock meets no rush).
  - The warning, once per slot, at its moment: WarnGraceSeconds late at most, so a server that comes up later sends none.
  - The rush, decided once per slot, after the first read of the shared record. An admin's event holding the slot's start (running here, or the record's) takes the hour.
  - The rush is this server's own event (`scheduled`), in no shared record: nothing is written or sent between servers.
  - While it runs, the console starts nothing and ends nothing, and a newer record of nothing running leaves it be.
  - The console's status line names the next one; an admin's start that runs past :30 says that hour has none.
- **The quiet first loop:**
  - the warning and every POD RUSH's start pop-up and sting go past a player in their first loop (MiniEventService's loudPlayers);
  - no empty end card and no one else's GOLD line for them (PodRushService);
  - their tracker waits until a pod of theirs counts, or would (PodRushUI).
- **Analytics:** PodRushEnded field 02, `scheduled` or `admin` (Metrics; KB/ANALYTICS.md).
- **What's New:** Shared/UpdateLog's newest entry, "POD RUSH every hour".
- **Off:** GameConfig.PodRush.Auto.Enabled = false, then a publish.

## Tested

- **PodRushHourlySpec 35/0 (new):**
  - the numbers and the slots;
  - one server's hour: the warning once (to all but a first-loop player), the start at :30, its pop-up past a first-loop player, nothing written to the shared store, the timer's end;
  - every server at once: two servers run one rush; a new server joins for what is left, unannounced, and starts nothing before its first read; a server up after the warning's moment sends no late one;
  - an admin's event and the hour; the off switch;
  - PodRushService's quiet rules and the tag; Metrics' field 02; the wiring; What's New.
- **27 mutants, all caught.**
- **The neighbouring specs green.** PodRushSpec followed one pin (the analytics fields). KB/HANDOFF.md has the list.
- **One guarded Play** on the throwaway store (desktop, 942 x 739), with the schedule moved rather than the clock: a temporary Studio-only harness (deleted after, never committed) put the next slot two minutes out and took the test player out of the quiet first loop.
  - The warning: "POD RUSH IN 1 MINUTE!" and its line, a minute before.
  - The start: the rush ran from the hourly schedule, with the tracker's "0 banked · 3 more for BRONZE".
  - The end: by its timer, the grace, then "POD RUSH OVER · 0 pods · no level".
  - **The start pop-up was not seen.** The fresh test profile had the guide's card up and the tracker stood under it, so the notice stack had no room above the screen's middle. The existing rule (2026-10-12) drops a notice that waits longer than it would show. Re-sent while a panel was open, it showed at the top.
  - A real player with the guide card up is either in their first loop, where the pop-up is held anyway, or on guide step 7. **Not checked with the guide hidden.**
- **Not seen on a phone. The analytics are spec-only** (the owner's account is staff).
