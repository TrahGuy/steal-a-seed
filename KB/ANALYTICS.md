# Podnappers launch analytics

Written 2026-09-27. The code is in `src/ServerScriptService/SeedGameServer/Metrics.luau`, the
switches are in `GameConfig.Metrics`, and the proof is `tools/tests/MetricsSpec.luau` (57 checks).

**This is measurement only.** No rule, reward, price, save or purchase depends on anything here. If
every analytics call failed, the game would play exactly the same.

**Status: hooks implemented and tested against a mock sink. Live delivery has NOT been verified.**
Roblox sends no analytics from Studio, so nothing local can prove Creator Hub received an event. The
owner-run check is in "Checking delivery" below.

A separate **external traffic feed** exists too: new-player join and session-end events sent to a
webhook, for Michael's Google Sheet. It supplements this page and does not replace it. It is
**disabled** and has never been connected. See section 8 and [TRAFFIC_LOG.md](TRAFFIC_LOG.md).

## What it answers

| Question | Where to look |
| --- | --- |
| Where do first-time players stop progressing? | The onboarding funnel (Funnel page), plus `TutorialStepDone` and `TutorialSkipped` |
| Which biomes have unusually frequent captures? | `GuardianRaidEnded` broken down by biome and outcome, and the `GuardianRaid` funnel's step-2 conversion by biome and speed band |
| How often are obby runs completed or abandoned? | `ObbyRun` and `ObbyRunEnded` (on since the Floating Garden landed, 2026-09-27) |
| Are players using the Bonus Chest? | `BonusChestClaimed`, total and by reward |
| Do session length and return visits improve after updates? | Built-in Engagement and Retention pages. Nothing custom is needed |

**Analytics shows patterns, not causes.** A drop at a funnel step says where people stopped, not why.
Launch samples will be small. Don't make large balance changes from a few days of data without other
evidence, such as recordings, feedback, or a clear step change after an update.

## 1. Built-in Creator Hub analytics: no scripts involved

Open [create.roblox.com](https://create.roblox.com/dashboard/creations), choose **Creations**, pick
**Podnappers**, and use the left navigation:

| Page | Menu | What it shows |
| --- | --- | --- |
| Engagement | Analytics → Engagement | Average session time and new-user first-session retention |
| Retention | Analytics → Retention | D1, D7 and D30 retention and cohort tables. D7 and D30 fill in only after 7 and 30 days |
| Acquisition | Analytics → Acquisition | Home recommendations, search, sponsored/search/portal ads, share links and play-through rate |
| Demographics | Analytics → Demographics | Any group under 3 users is hidden |
| Monetization | Monetization → Overview | Revenue, conversion rate, paying users, ARPPU and ARPDAU |
| Performance, Error Report, Crashes | Monitoring | Client and server FPS, crash rate, memory, and a breakdown by place version |
| Custom, Funnel, Economy | Analytics | Unlock once the custom events and funnels below have arrived |

**Eligibility and activation**, from the Roblox analytics docs checked 2026-09-27:
- The dashboard needs **more than 10 daily active users and 10 play hours for 7 consecutive days**.
- The owner's account needs a verified email and two-step verification. The owner then accepts the
  terms with **Activate Analytics** on the overview page. **The owner must do this; nobody else can
  accept on their behalf.**
- Performance charts need at least 100 daily active users, as do Alerts and Insights.
- Charts usually take **up to 24 hours** to appear.
- Before the traffic thresholds are met, a page is empty or unavailable. An empty page is not a zero.

**Permissions, and Michael:**
- Podnappers is **group-owned**: place 114075467877655 and universe 10744596516 belong to CrazyCozy
  Games (group 744756221). The public asset details and Studio's `game.CreatorType` / `CreatorId`
  both say so (checked 2026-09-27).
  - An earlier version of this section said "user-owned (nicnicniccoal)". That was wrong.
- Michael's **"View analytics for experiences"** is a **group role permission**. It lets him see the
  analytics of experiences the *group* owns, without edit access.
- **So it does reach Podnappers,** provided the role he holds in CrazyCozy Games has that permission.
  The owner can confirm it under the group's Roles settings. Nothing needs moving or sharing.
- The analytics terms still have to be accepted once, for the group's experience, by an account
  entitled to accept them (**Activate Analytics**, above). Nobody else accepts on the owner's behalf.
- Nothing here grants anyone edit, publishing, spending or player-data access, and nothing should.

## 2. The custom events and funnels

Every event is sent **server-side, after the action has succeeded**, by the service that already
performs that action. The fields are `CustomField01`–`03` and only ever hold the fixed values listed
here: no names, UserIds, plant IDs, timestamps or free text. Roblox attaches the player to each event
itself, which is what "unique users" counts. These are aggregate product reports, not a claim of
anonymous processing, and no additional personal information is collected.

### Onboarding funnel (`LogOnboardingFunnelStepEvent`, once per user)

| Step | Name | Trigger (authoritative) |
| --- | --- | --- |
| 1 | Session Ready | `PlayerDataService`: a **brand-new** save loaded (`SaveService.Load` said "new") that can be saved, for a player in the cohort |
| 2 | First Pod Stolen | The guide's `steal` milestone recorded for the first time ever (`CarryService.TryTake` success) |
| 3 | First Pod Banked | `bank` recorded for the first time (`CarryService` bank at the red line) |
| 4 | First Pod Planted | `place` recorded for the first time (`PlantService.PlaceAt` success) |
| 5 | First Plant Hatched | `hatch` recorded for the first time (`PlantService` hatch) |
| 6 | First Plant Income | The first garden income payout (`EconomyService`, the one positive `AddCash`) in the session where step 5 went out |

**Why this order.** It is the guide's real order: steal → bank → place → hatch. The guide's first two
steps, train and reach 1,000 Speed, are not in the funnel. A player can steal without training, so
those two are not sequential. They are counted separately as `TutorialStepDone`. "Tutorial completed"
is separate too: it happens at the hatch and can be skipped entirely.

**The funnel can't imply something that didn't happen.** Roblox credits every earlier step when a later
one is logged. So `Metrics` walks the chain and sends a step only while every milestone up to it is
already done in that player's own saved guide record. It stops at the first gap. For example, a pod
planted before any bank is reported only once the bank catches up, and it is never reported ahead of
the bank.

**Who is in it:**
- Saves first written on or after `GameConfig.Metrics.CohortSince` (2026-09-27 00:00 UTC) are in.
- A returning player, including an older save with an unfinished guide or one reset by an admin
  (`CreatedAt` survives a reset), never enters, so the funnel can't be restarted or falsely completed.
- A rejoin continues from the saved guide record. Step 1 is never sent again.
- A step already sent in an earlier session may be re-sent. Roblox counts only a user's first instance
  of each step.
- No profile field was added and no extra save is made for analytics. The guide's own saved `Done`
  flags are the record.

### Guide events (custom)

| Event | When | Fields | Deduplication |
| --- | --- | --- | --- |
| `TutorialStepDone` | A guide step recorded for the first time | 01 = `train` / `speed` / `steal` / `bank` / `place` / `hatch` | Once per step per session; the save already guarantees "first time ever" |
| `TutorialCompleted` | The step that finishes the guide | none | Once |
| `TutorialSkipped` | The player hid the guide (Skip) | none | Once per session; Resume is not counted |

These are sent only for the new-player cohort.

### Guardian raids

A **raid** starts when a pod is taken **from a nest**. Picking a dropped pod back up doesn't start one.
The raid ends **the first time that pod leaves the thief's hands**.

| Event | When | Fields | Value |
| --- | --- | --- | --- |
| `GuardianRaid` funnel, step 1 "Pod Stolen" | The nest take succeeded (`CarryService.TryTake`) | 01 = biome, 02 = speed band | — |
| `GuardianRaid` funnel, step 2 "Pod Banked" | Banked at the red line, and only then. Not being chased any more is **never** counted as banked | — | — |
| `GuardianRaidEnded` | The raid's first ending, exactly once | 01 = biome, 02 = speed band, 03 = outcome | Seconds from theft to ending (one decimal) |

- Each raid's funnel session is a fresh GUID and contains nothing about the player. Breakdowns use the
  step-1 fields, which is how Roblox funnels work.
- **Outcomes:**
  - `banked`
  - `captured`: a guardian's swing landed. NestService reports it before the throw, so the drop that
    follows isn't also counted as a knock.
  - `died`
  - `knocked`: knocked flat another way, such as a bat or a trap, and the pod fell.
  - `night`: still in a biome at nightfall.
  - `left`: left the game holding the pod.
  - `other`: for example, an admin progress reset.
- **Speed bands** compare the player's Speed at the theft with the biome's
  `BiomeData.RecommendedSpeed`:
  - `below`: under 80% of the recommendation;
  - `near`: 80% to just under 125%;
  - `above`: 125% or more;
  - `none`: Greenhollow, which recommends nothing.
- **Biomes:** `greenhollow`, `dustbowl`, `tanglemire`, `emberroot`, `starbloom`, or `other`.
- **Edge cases:**
  - A second guardian retargeting the carrier changes nothing, because the raid follows the pod.
  - Two guardians reaching the carrier at once still produce one ending.
  - A disconnect ends the raid as `left`.
  - Recovering a dropped pod and banking it later doesn't turn a lost raid into a win. The raid was
    already decided when the pod fell. This is deliberate and keeps "success" meaning a clean run home.
- **Read it as rates:** banked ÷ stolen (funnel conversion) and the outcome mix per biome. Don't read
  a single event as a probability.

### Bonus Chest

| Event | When | Fields |
| --- | --- | --- |
| `BonusChestClaimed` | `BonusChestService.Claim` after the claim's **save succeeded**. A refused, early, repeated or failed claim is never counted | 01 = `income` / `training` |

Analytics never grants anything. It is told about a grant that already happened.

### Obby: the Floating Garden (on)

`GameConfig.Metrics.Obby = true` since the course was built and verified (2026-09-27). Each call is made
by `ObbyService` at its own server-validated moment:
- the `ObbyRun` funnel: 1 Run Started, 2 Checkpoint 1, 3 Checkpoint 2, 4 Finished;
- `ObbyCheckpoint`, where field 01 is `main1`, `main2` or `challenge`;
- `ObbyRunEnded`, once per run, with value = seconds and three fields:
  - 01: `completed`, `exited` or `left`;
  - 02: route, `main` or `challenge`;
  - 03: falls bucket, `0`, `1-2`, `3-5` or `6+`.

Where each one fires in `ObbyService`:
- **Run Started:** `Begin`, after every refusal has passed (arch prompt or Replay).
- **Checkpoints:** `advance`, when the server's gate check puts the runner on cp1 / cp2 in order;
  `challenge` when both twilight stages are passed in order.
- **Finished / `completed`:** `finish`, only for a run that is paid -- in order, not flagged by the
  movement check, and over `ObbyData.Validation.MinRunSeconds`. A run that fails validation is reported
  `exited` when the player leaves the course.
- **`exited`:** Return, the Exit button, death or a new body. **`left`:** the player left the server.

Switching the course off (`GameConfig.Obby.Enabled = false`) leaves nothing to report, so the events
stop by themselves.

### Reward wheel (2026-09-27)

Two custom events from `WheelService`, each sent only after the change it reports is on the profile:

| Event | When | Fields |
| --- | --- | --- |
| `WheelSpinEarned` | `AwardCompletion`, when an obby completion earned a spin (never for a completion that paid Speed, or one already credited) | 01 = the window's count after it, `1`..`5` |
| `WheelSpun` | `spin`, after the spin was spent, its prize recorded **and saved**. A refused spin, or one whose save failed, is never counted | 01 = the prize id paid (one of `WheelData`'s twelve; the trail's replacement is reported as `cash_jackpot`); 02 = `earned` / `bought` |

No player detail and no pod species goes into either. With the wheel off (`WheelData.Enabled = false`)
nothing is earned or spun, so both stop by themselves.

### MetricsValidation (staff only, off)

With `StaffValidation = true`, an admin's actions send only this event instead of real counts. Field 01
names what would have been sent, such as `raid banked` or `onboarding 3`.

## 3. What is excluded

- **Studio**, including automated tests and disposable test profiles. Roblox sends nothing from
  Studio, and `Metrics` uses a dry-run sink there: an in-memory list of the last 200 events that never
  leaves the machine. The test store (`ServerStorage.SeedTestStore`) only exists in Studio.
- **Staff**: the two AdminService allowlisted accounts, `ExcludeStaff = true`. Their play never
  reaches a report.
- **Temporary profiles**, when DataStores are unreachable.
- **Returning players**, from the onboarding funnel only. Their raids and chest claims still count,
  because those are about the game, not about being new.

## 4. Checking delivery (owner-run, pending)

This can't be done locally.

1. When the owner decides to publish, set `GameConfig.Metrics.StaffValidation = true` in that build if
   staff should see their own test events.
2. In a live server, as an admin, take a Greenhollow pod and bank it. Claim the chest if it's ready.
3. In Creator Hub, open **Analytics → Custom** (or **Funnel**) and click **View Events** at the top. This
   is Roblox's near-real-time list of recent events; refresh to update it. `MetricsValidation` rows
   should appear within minutes.
4. Real players' events appear in the same list. Charts can take up to 24 hours.
5. Set `StaffValidation` back to `false` for normal operation.
   `MetricsValidation` never feeds any other chart.

If nothing appears, open **Monitoring → Error Report**, which also lists event-tracking errors.
`Metrics.health()` on the server reports calls dropped by the budget and sink failures.

## 5. Limits and delays

| Item | Limit | Our use |
| --- | --- | --- |
| Custom event names | 100 per experience | 10 |
| Funnels | 10 per experience | Onboarding, `GuardianRaid`, and `ObbyRun` |
| Steps per funnel | Up to 100 | 6 onboarding, 2 raid, 4 obby |
| Custom fields | 3 per event | Biome, band and outcome at most |
| Field combinations | 8,000 before grouping as "Other" | About 170 for raids |
| Rate | 120 + 20 × concurrent players per minute | A few per raid. `Metrics` also caps each server at 60 a minute and drops, never queues, anything over |
| Onboarding | Once per user; skipped steps credited; repeats ignored | Order enforced in code |
| Recurring funnel sessions | Last 10 unique session IDs per user per funnel | One GUID per raid |
| Delay | Charts up to 24 hours; D7 and D30 need 7 and 30 days | — |
| Retention | Custom data rolls off 90 days after the last data received | — |

## 6. Turning it off

- **Everything:** set `GameConfig.Metrics.Enabled = false` and publish. Nothing is sent and nothing
  else changes.
- **The obby's events:** `GameConfig.Metrics.Obby` (on). The course itself: `GameConfig.Obby.Enabled`.
- **Staff validation:** `GameConfig.Metrics.StaffValidation`, off today.
- **One event:** remove its single call at its success point. Each is one line, listed in the tables
  above. `MetricsSpec` section 7 names them.

## 7. Launch review checklist (owner and Michael)

1. **Where do first-time players stop?** On the Funnel page, open the onboarding funnel. Find the step
   with the biggest drop, then compare `TutorialSkipped` and `TutorialStepDone` for `train` and `speed`.
2. **Which biomes catch players unusually often?** Break down `GuardianRaidEnded` by biome and
   outcome, and check the `GuardianRaid` step-2 conversion by speed band. Compare `below`, `near` and
   `above` before blaming a biome.
3. **Obby runs completed or abandoned?** On the Funnel page, open `ObbyRun`: Run Started to Checkpoint 1,
   2 and Finished shows where runs stop. Break `ObbyRunEnded` down by field 01 (`completed` / `exited` /
   `left`), 02 (route) and 03 (falls bucket); its value is the run's seconds.
4. **Is the Bonus Chest used?** Look at the `BonusChestClaimed` count and unique users, compared with
   daily active users on Engagement.
5. **Do session length and return visits improve after updates?** Use Engagement (session time) and
   Retention (D1 and D7). Performance can be broken down by place version.

## 8. The external traffic feed (separate, disabled)

`TrafficLogService` sends two events, `new_player_joined` and `new_player_session_ended`, to a webhook
held in an experience secret. Michael's Make.com scenario will write them into a shared Google Sheet.

- **Shared with Metrics:** the same verdict (`SaveService.Load` said `"new"` and the profile can be
  saved) and the same exclusions (Studio, staff, temporary and returning profiles). PlayerDataService
  calls it right after `Metrics.profileReady`.
- **Not shared:** no code, sink or budget. Nothing on this page changed for it.
- **It sends:** a random session id, timestamps, the place version, an allowlisted campaign tag or
  `unknown`, and the elapsed connection time. No names or UserIds.
- **It is not a count of every visit.** A new player who leaves before their profile loads is missed,
  and a lost ending means an unknown duration, not zero.
- **Status:** `TrafficLogConfig.Enabled = false`. No secret exists yet and HTTP requests are off.
- **The rest:** setup, receiver rules, limits and the mocked test report are in
  [TRAFFIC_LOG.md](TRAFFIC_LOG.md).
