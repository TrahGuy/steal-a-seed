# POD RUSH — a 5-minute stealing event (plan, 2026-10-09)

**Status: APPROVED 2026-10-09** (the owner: "approve, let terminal work"), with every recommendation
taken:

1. levels 3 / 7 / 12;
2. the rewards as in the table;
3. no rage build-up during the rush;
4. a 15 s regrow;
5. dusk waits for the rush;
6. **admin-console start only** (no automatic schedule).

**BUILT 2026-10-09** (uncommitted, not published): see KB/HANDOFF.md, "POD RUSH: A FIVE-MINUTE STEALING
EVENT". Added since this plan: the owner's music slots (a bed and two stings, "" until uploaded), the
owner's transparency rule (no plates behind the rush GUI or the buff row), and a one-line strip for
short phones. The icon prompts are in `output/imagegen/podrush/pod-rush-icons-v1.prompt.md`.

## Why

Michael (playtester and fellow developer):

> Maybe consider an event as well. This game had one where you ran through the area and collected
> stats for 5 mins and had three reward levels based on how much you collected. Aligned with the
> core fantasy well.

Our version: **for 5 minutes, steal and bank as many pods as you can.** Three reward levels (bronze,
silver, gold) by how many you bank. It is the core loop, sped up, with a goal on screen.

## What exists today (code facts)

| What | Today | Where |
|---|---|---|
| Timed events | Four modes: TICKET DISCO, DISCO + MILL, DISCO ONLY, TICKET SHOWER. 30 to 300 s (default 90). Started **only from the admin console**, and every live event runs on **all servers at once** (DataStore record plus MessagingService). No automatic schedule. An announcement shows 2 s in; time left shows as the event's ring in the boost-icon row | `GameConfig.luau:5149-5200`, `MiniEventService.luau:1659-1913`, `AdminService:925-946` |
| Ticket Shower's rewards | One spin per pickup through `WheelService.GrantEventSpin`, capped at 3 per event on the profile (`EventClaims`) | `MiniEventService.luau:1165-1205` |
| **Nest supply** | **A taken pod does NOT regrow until dawn.** One nest per biome with 5 / 3 / 3 / 3 / 2 pods, so **16 pods per day for the whole server** | `NestService.luau:86-94, 3813-3833`, `BiomeData.luau` |
| Day and night | Day 420 s, night 15 s. **Dusk clears every pod, forfeits carries and refuses takes** | `GameConfig.luau:2423`, `WorldCycleService.luau:214-235` |
| Guardians | Each theft adds a rage stack: +5 speed, up to 4, forgotten 45 s after calm. One chase at a time; other thieves queue | `NestService.luau:1049-1076`, `GameConfig.luau:3148-3159` |
| Banking | `CarryService.bank` succeeds once `RecordPod` returns. **No bank signal** exists for other services. "From a nest" and "picked up after a drop" are told apart only inside the take | `CarryService.luau:926-958, 1877-1954` |
| Rewards available | Spin tickets (`GrantEventSpin`, with a cap); a pod (`CarryService.GivePod`); a 120 s +25% boost (`BonusChestService.GrantBoost`); speed (`TreadmillService.PayReward`); cash (`EconomyService.PayReward`, the single cash faucet) | as named |
| Progress UI | None for a timed goal. The Obby has a clock line; TreadmillFun and the invite hub have fill bars to borrow from | `ObbyUI`, `TreadmillFunUI`, `InviteHub` |
| Analytics | Nothing for timed events | `Metrics.luau:79-92` |

**What that means:** with today's nests, a 5-minute rush would be 16 pods shared by a whole server,
gone in the first minute. **The rush has to add supply.**

## The event

### How it runs

- **A fifth timed-event mode, `podrush`, POD RUSH: 300 s.** It is started from the admin console like
  the other four and runs on all servers at once.
- Announcement: **"POD RUSH! Steal and bank as many pods as you can in 5 minutes!"** It uses a new
  rush icon (one more image, below).
- **Nests regrow fast:** a taken pod regrows **15 s** later, in every biome, for the whole rush. The
  pods are normal pods: normal sizes, normal odds, and still no words on them. A golden ring of light
  under each nest says "rush on".
- **Guardians chase as usual** (that's the fun), **but don't build rage** during the rush. Four
  stacks (+20 speed) would turn a 5-minute sprint into a wall.
- **Night waits:** dusk is held off until the rush ends, so nobody loses a carried pod to the clock.
  If the day clock turns out to be shared across servers, the alternative is to start a rush only
  when at least 5.5 minutes of day are left.

### What counts

- **A pod taken from a nest during the rush and banked by the same player** counts 1. If it is still
  being carried when the rush ends, it has a **20 s grace** to be banked.
- Pods picked up after a drop don't count. That stops drop-and-re-pick farming.
- A new bank hook in `CarryService.bank` (a signal) feeds the count.
- **Your count is saved on your profile under the event's id**, so a rejoin, even on another server,
  keeps it.
- Every pod you bank is still yours, as always. The levels are a bonus on top.

### The three levels (defaults; the owner may change them)

| Level | Banked pods | Reward |
|---|---|---|
| **BRONZE** | 3 | 1 spin ticket |
| **SILVER** | 7 | 3 spin tickets + a 2-minute +25% training boost |
| **GOLD** | 12 | 5 spin tickets + a **Titan-size pod** from the highest biome you banked from during the rush |

- **Why 3 / 7 / 12:** a near Greenhollow raid takes about 20 to 30 s door to door. With pods
  regrowing, one player can bank about 10 to 12 in 5 minutes. Gold is for a strong run; bronze is
  for anyone who tries.
- Each level pays **once per player per rush** (saved, like `EventClaims`), the moment it is reached,
  with a "+1 / SILVER!" pop.

### On screen

- **A rush tracker** while it runs, placed through HudLayout so it fits every listed phone:
  - **POD RUSH 3:12**;
  - **5 banked**;
  - a 3-step bar with the bronze, silver and gold marks;
  - "2 more for SILVER".
- **"+1"** when a pod counts, and a level-up pop when you reach a level.
- **The end card:** "POD RUSH OVER: 9 pods · SILVER!" with what you got.
- **One server line** when someone reaches GOLD: "Pat hit GOLD in the Pod Rush!"
- **Reduced FX:** no pops or shimmer; the tracker and the end card stay.

### Art (one new picture)

- A **POD RUSH icon** (512, transparent) for the announcement, the tracker and the boost row: a pod
  with motion lines and a stopwatch. Optional: bronze, silver and gold medal icons for the levels.
  Until they are uploaded, drawn stand-ins.
- **UPLOADED and checked 2026-10-09** (Image, CrazyCozy Games, IsLoaded, 512x512, alpha 0):
  - icon `rbxassetid://108173602941410`;
  - bronze `rbxassetid://106320803448209`;
  - silver `rbxassetid://108448116105933`;
  - gold `rbxassetid://100048210150003`.
  - All four use the shared crop: ImageRectOffset (41,41), ImageRectSize (430,430).

### Analytics

- `PodRushEnded`, once per player per rush: the number banked and the level reached. No names and no
  ids, as the other events.

### Tests and checks

- **Specs:**
  - counting (nest thefts only, inside the window plus grace, once per pod);
  - the level thresholds and the once-per-rush rewards;
  - a rejoin keeps the count;
  - the 15 s regrow;
  - no rage during the rush;
  - dusk held;
  - admin start and end;
  - a late join;
  - the tracker and end card fit every listed phone.
- **One guarded Play:**
  - start a rush;
  - bank pods to bronze and silver;
  - a drop and re-pick does not count;
  - the grace bank after the end;
  - the end card;
  - a rejoin.

## Decisions for the owner

1. **Levels:** 3 / 7 / 12 pods? (Recommended.)
2. **Rewards:** bronze 1 ticket; silver 3 tickets + training boost; gold 5 tickets + a Titan pod? (Recommended.)
3. **Guardians:** chase as usual but no rage build-up during the rush? (Recommended.)
4. **Supply:** nests regrow every 15 s during the rush? (Recommended.)
5. **Night:** dusk waits until the rush ends? (Recommended.)
6. **Starting:** admin console only, like the other events (recommended), or also automatically every
   few hours (e.g. every 2 hours on the hour)?
