# Podnappers external traffic feed

Written 2026-09-28. This is a small server-side feed that reports genuinely new players to two Make webhooks: one for joins and one for session endings. Michael's scenarios will write the events into a shared Google Sheet.

- **Code:** `src/ServerScriptService/SeedGameServer/TrafficLogService.luau`
- **Settings:** `TrafficLogConfig.luau`, beside the code. Both are server-only.
- **Proof:** `tools/tests/TrafficLogSpec.luau` (the original 98 checks plus route assertions; re-run in Studio is pending)

**Status: ENABLED IN SOURCE, NOT YET LIVE.** Michael supplied two webhook URLs on 2026-09-29, and the owner approved creating both Podnappers experience secrets. Creator Hub listed both names with the restricted `hook.us2.make.com` domain after creation. Their values are not stored in this repository. `TrafficLogConfig.Enabled = true` for the next publish, but Studio's Allow HTTP Requests setting has not been checked, no new build has been published, and no live delivery has been verified.

It **supplements** Roblox's own analytics (`Metrics`, [ANALYTICS.md](ANALYTICS.md)) and replaces nothing. It is measurement only: no reward, rule or save depends on it. If every request failed, the game would play exactly the same.

## What it sends

Exactly two event types, and only for a **new player**. A new player here means a join whose profile load returned `"new"` (no save existed) with a profile that can be saved.

| Event | Sent when | Duration |
| --- | --- | --- |
| `new_player_joined` | PlayerDataService finishes the load and the profile qualifies, usually within seconds of joining | — |
| `new_player_session_ended` | That same player leaves, or the server shuts down while they are connected | `sessionDurationSeconds`: whole seconds since their `PlayerAdded` |

Each event goes to its own URL. Both carry the same `sessionId`, so Michael can join the two Make outputs in his Sheet.

These never enter the feed:
- **returning players**: their load said `"ok"`, so a new player's second visit is not counted;
- **temporary profiles**: DataStores were unreachable, so the profile can't be saved;
- **staff**: AdminService's allowlist, the same accounts Metrics leaves out;
- **anything in Studio**: including every Play test.

Roblox `AccountAge` and in-memory UserId lists play no part in the decision.

### Payload (schema 1)

JSON, POSTed with `Content-Type: application/json`. The samples below use fake data.

```json
{
  "schemaVersion": 1,
  "eventType": "new_player_joined",
  "eventId": "00000000-0000-4000-8000-00000000e001",
  "sessionId": "00000000-0000-4000-8000-00000000d001",
  "occurredAtUtc": "2026-10-01T14:03:11Z",
  "sessionStartedAtUtc": "2026-10-01T14:03:07Z",
  "placeVersion": 412,
  "campaignTag": "spring_ads"
}
```

```json
{
  "schemaVersion": 1,
  "eventType": "new_player_session_ended",
  "eventId": "00000000-0000-4000-8000-00000000e002",
  "sessionId": "00000000-0000-4000-8000-00000000d001",
  "occurredAtUtc": "2026-10-01T14:21:40Z",
  "sessionStartedAtUtc": "2026-10-01T14:03:07Z",
  "placeVersion": 412,
  "campaignTag": "spring_ads",
  "sessionDurationSeconds": 1113
}
```

| Field | Meaning |
| --- | --- |
| `schemaVersion` | `1`. It changes only if a field changes meaning or is removed |
| `eventType` | One of the two names above |
| `eventId` | A GUID, unique per event and **identical on every retry** of that event. Deduplicate on it |
| `sessionId` | A random GUID, one per connection, shared by that session's two events. Pair on it |
| `occurredAtUtc` | When the event happened: the profile verdict or the leave. ISO 8601 UTC, whole seconds |
| `sessionStartedAtUtc` | When the player's `PlayerAdded` fired, in the same format |
| `placeVersion` | The published place version the server was running |
| `campaignTag` | An allowlisted launch-data tag, or `"unknown"`. See the campaign tags section |
| `sessionDurationSeconds` | Ending event only. Elapsed **connection** time, not verified active playtime. `0` is a real value |

**Nothing personal is sent:** no username, UserId, account age, chat, inventory or profile data. A GUID is random each session, so it does not identify a player across visits.

### Campaign tags

- Roblox Ads Manager's **Advanced join options** can attach launch data to a campaign's joins. The server reads `player:GetJoinData().LaunchData` once, when the player arrives, inside `pcall`.
- A value that exactly matches one entry in `TrafficLogConfig.CampaignTags` is sent as that tag. The match ignores case and surrounding spaces.
- Any other value becomes `"unknown"`: missing launch data, an unlisted value, JSON, anything over 40 characters, or a read that fails. The raw value is never forwarded.
- **`unknown` does not mean organic.** It means no recognised tag.
- **A tag is not verified paid-click attribution.** Launch data sits in the join URL, so a tagged link can be shared and reused.
- Tags never touch gameplay or rewards. The feed has no path into any game system.
- Allowed tag characters are lowercase letters, digits, `_` and `-`, at most 40 characters. The list is empty until Michael supplies the tags.

## Delivery and failure handling

- **Queue:** at most 64 events (`QueueCapacity`). A full queue drops the newest event and warns.
- **Concurrency:** at most 2 requests in flight (`MaxConcurrent`). Each request runs on its own thread, so joining, leaving, saving and gameplay never wait on the webhook.
- **Retries:** `408`, `429`, any `5xx`, and no response at all (a timeout or a connection failure) are retried, up to 5 tries in total (`MaxAttempts`).
  - The waits between tries are 2, 4, 8 and 16 s (±20 % jitter), so about 30 s altogether.
  - A `Retry-After` header is honoured, capped at 60 s.
  - Every retry sends the **same bytes**, so the eventId never changes.
- **Delivered:** any `2xx`.
- **Permanent refusal:** any other status (`400`, `401`, `404`, `410` …) drops the event. It is not retried.
- **Halt:** if HTTP requests are off for the experience, or the secret is missing, the server stops sending for the rest of its life, drops its queue and warns once.
- **Duplicates:** repeated PlayerAdded, profile, PlayerRemoving and shutdown calls are ignored. Each session produces at most one join and one ending.
- **Shutdown:** `BindToClose` ends every open session, then tries each queued event once more, for at most 4 s (`FlushSeconds`).
- **Diagnostics:**
  - Warnings start `[Seed/TrafficLog]`. There is at most one of each kind a minute, with a count of the ones held back.
  - They carry only fixed words and status codes: never the URL, a body, an id or a raw error.
  - One line at boot says whether the feed is on or off.
- **No saved state.** Nothing is written to a DataStore to guarantee delivery.

### What it cannot count (read this before quoting a number)

- **Players who leave before their profile is classified are missed.** The profile load usually takes a second or two, and can take up to about 15 s on a slow DataStore. Someone who leaves during it produces no events. This is **not a count of every connection attempt or every visit.**
- **New players are also missed when:**
  - their load fails and they are kicked;
  - DataStores are down and they get a temporary profile;
  - the server crashes, or is killed without `BindToClose` running.
- **Events can be lost.** A crash loses everything unsent. So do a full queue, retries that run out, and a flush that runs out of time.
- **A missing ending means the duration is unknown, not zero.** A join with no ending is a session with an unknown length.
- **The ending can arrive without its join,** if the join was dropped.
- **Make may receive an event more than once.** This happens when the webhook processed a request but the response was lost (a timeout), because the retry repeats the same eventId.
- **The ending can arrive before the join,** if the join was still waiting to retry when the player left.
- **Later sessions of the same player are never "new",** so the feed measures first sessions only. An account whose save was erased starts again as "new".
- Timestamps come from the server's clock and have one-second precision. The duration uses a monotonic clock and is rounded to whole seconds.

## Owner setup for Michael's two webhooks

Each webhook URL is a credential: anyone who has it can write into the Sheet. Keep the values out of code, GameConfig, docs and screenshots. The owner has supplied the URLs in chat; neither value belongs in the repository.

1. **Two experience secrets — DONE 2026-09-29.** Podnappers is owned by the CrazyCozy Games group.
   - In Creator Hub, open **Creations → Podnappers**, then **Secrets** in the left menu, then **Create Secret**.
   - **Join secret name:** `PodnappersTrafficJoinWebhook`; value: Michael's *player joins* URL.
   - **Duration secret name:** `PodnappersTrafficDurationWebhook`; value: Michael's *player duration after they leave* URL.
   - **Allowed domain for each:** `hook.us2.make.com` (the host of both supplied URLs).
   - The secret can only be read by server scripts through `HttpService:GetSecret`. It cannot be printed.
2. **Allow HTTP requests.** In Studio: **File → Experience Settings → Security → Allow HTTP Requests** on, then **Save**.
   - This is experience-wide; `TrafficLogService` is the only code in the game that makes requests.
   - Studio itself never sends: the feed excludes Studio by design, so no Studio local secret is needed.
3. **Fill in the tags.** Put Michael's campaign tags in `TrafficLogConfig.CampaignTags`, for example `{ "spring_ads", "yt_short_oct" }`, and use the same strings as launch data in Ads Manager.
4. **Switch — ON IN SOURCE, NOT PUBLISHED.** `TrafficLogConfig.Enabled = true`. After verifying HTTP access and the amended spec, the owner can publish.
   - Only servers started after the publish run the new code.
   - Older servers can be moved over with Creator Hub's server restart or update option for the experience.
5. **Run the live check below.**

**To turn it off**, use any one of these:
- set `Enabled = false` and publish;
- delete or rename either secret (new servers then halt with `secret-missing`);
- turn HTTP requests off.

## Receiver instructions (for Michael)

The join webhook receives only `new_player_joined`; the duration webhook receives only `new_player_session_ended`. Each gets one JSON event per request and should answer `200` once accepted. A `4xx` makes our side drop the event for good; a `429` or `5xx` makes it retry. Both scenarios must preserve the shared `sessionId` and their distinct `eventId`s in the Sheet.

1. **Deduplicate by `eventId`.** The same event can arrive twice. Before appending a row, search the events tab for that `eventId` and skip it if it's already there. In Make, a Google Sheets **Search Rows** filtered on `eventId`, then **Add a Row** only when nothing was found; or a Make Data Store keyed by `eventId`.
2. **Keep an append-only events tab.** Give it one row per unique event, with every field as its own column. Leave `sessionDurationSeconds` blank on join rows.
3. **Pair by `sessionId`** in a second tab, or with a pivot, and build it from the events tab:
   - one row per `sessionId`, with `joinedAt` from the join event;
   - `endedAt` and `durationSeconds` from the ending event;
   - `campaignTag` and `sessionStartedAtUtc` from whichever event exists, since both carry them.
4. **Expect events out of order.** The ending can arrive before the join. Never assume the first event for a session is the join: if you upsert into a sessions table instead of deriving it, create the row from whichever arrives first and fill in the rest later.
5. **Missing endings stay blank.** A session with a join and no ending has an **unknown** duration. Leave the cell empty; don't write 0. It may be a crash, or an ending that was lost. Leave it out of average-duration figures, and report how many sessions have no ending.
6. **An ending without a join is still a new player.** Count new players as distinct `sessionId`s across both event types, not as join rows.
7. **Read `campaignTag` honestly.** `unknown` means no recognised tag, not organic. A tag means the join URL carried it, not a verified ad click.
8. **Check the version.** Accept `schemaVersion` 1. Route anything else, or an unknown `eventType`, to a separate "unhandled" tab rather than dropping it.
9. **Timestamps** are UTC strings such as `2026-10-01T14:03:07Z`. In Sheets, `=DATEVALUE(LEFT(A2,10))+TIMEVALUE(MID(A2,12,8))` turns one into a date-time (UTC).
10. **If either URL leaks,** create a replacement webhook, send it to the owner privately, and update only that route's secret value.

## Test report (mocked, 2026-09-28)

**TrafficLogSpec: 98 passed, 0 failed.** It ran in Studio Edit through ZZSpecRun, against the real module with stand-in players, a fake clock and a scripted **fake sender**. No HTTP request was made, and the real sender is never installed in a spec.

| Area | Checks | What was shown |
| --- | --- | --- |
| The pair | 12 | A new, persistent profile gives exactly one join and one ending: the same `sessionId`, different GUID `eventId`s, exactly the contract's fields, schema 1, the place version, `unknown` without launch data, and no name, UserId or account age in either body. The duration runs from arrival: 3 s + 125.4 s gives 128 |
| Exclusions | 5 | Returning, temporary (even if marked new), staff (both the stand-in check and the real AdminService allowlist) and Studio send nothing |
| Leaving during the load | 3 | Leaving before the verdict, a verdict landing after PlayerRemoving, and a leave with no session all send nothing |
| Duplicates | 4 | Repeated PlayerAdded, verdict, PlayerRemoving and shutdown calls give one join and one ending, and the first arrival is the start. A verdict without a seen arrival opens the session at that moment |
| Many players | 6 | Five players (three new, one returning, one staff) give three distinct paired sessions, each timed from its own arrival. Two requests are in flight at most; a third starts only when a slot frees |
| Retries | 5 | A 503 is retried only after its backoff, with byte-identical JSON (the same `eventId`). The backoff doubles: 2 s, then 4 s |
| Failures | 18 | A timeout is retried and reported as a fixed word. A 429 waits for its Retry-After, capped at 60 s. 408, 500, 502 and 504 are retried. 400, 401, 403, 404, 410 and 413 are dropped and never retried. HTTP off or a missing secret halts sending and drops the queue |
| Bounds | 7 | A queue of 3 drops the 4th and 5th. Retries stop at MaxAttempts. Warnings are rate-limited with a held-back count, and never carry a URL, body or id |
| Shutdown | 4 | Shutdown and PlayerRemoving overlapping in any order give one ending per session. The flush retries a backing-off event at once. A webhook that never answers held a 0.25 s flush for 0.26 s, then shutdown moved on |
| Launch data | 14 | Allowlisted tags pass, whatever their case or spacing. Unlisted, empty, non-string, 300-character and JSON values, and a throwing `GetJoinData`, all read `unknown` and are never forwarded; the join still goes. A malformed allowlist entry is ignored. The tag is read once, at arrival |
| Time | 4 | Leaving in the same instant gives 0 s. A clock going backwards gives 0, never negative. Real stamps are ISO 8601 UTC |
| Isolation | 8 | Every lifecycle call returns at once while a request hangs, and a throwing sender or nonsense arguments never reach the caller. PDS calls the feed right after `Metrics.profileReady`, with the same verdict and inside `pcall`, and also requires it inside `pcall`. Metrics is untouched. The feed has no attribute, remote, DataStore, analytics or gameplay-service reference |
| Disabled and secrets | 8 | The shipped config is off with an empty allowlist. Off makes zero requests for a full lifecycle. There is exactly one `RequestAsync` and one `GetSecret` call site. No URL is written anywhere. The settings live in ServerScriptService, not GameConfig, and no client-visible script mentions the feed |

**2026-09-29 change:** join and duration now route to two named secrets. Both were saved and listed in Creator Hub later that day, and the source switch was enabled. The amended spec includes route and on-switch assertions, but Studio was closed, so those new assertions and the full suite have not been re-run. Rojo built the place successfully; that does not prove Luau runtime behavior.

**Full spec suite:** all 55 specs ran, and none threw or failed. MetricsSpec is 57/57 (native analytics unchanged), AdminSpec 79/79, and OfflineEarnings, Leaderstats, Tutorial and HeldRestore all pass.

**Play smoke test** on the throwaway test store:
- `test_store_on` → `store_guard SAFE SeedTest_20260928`, and the Ready line read `STUDIO TEST STORE`.
- The boot printed `[Seed/TrafficLog] external traffic feed off (TrafficLogConfig.Enabled is false).`
- The service started before PlayerDataService (27 services), and the profile loaded `(new)` normally.
- Stopping produced no errors.
- `test_store_off` removed the 1 test key and the marker. The real store was never opened.

## Remaining live end-to-end check (owner-authorised, not done)

None of this can be proved locally, because Studio never sends. After the setup steps and a publish:

1. **Boot line.** In a live server, an admin opens the Developer Console (F9) → Server and looks for `[Seed/TrafficLog] external traffic feed on.`
   - Warnings mentioning `http-disabled` or `secret-missing` mean step 2 or step 1 of the setup is incomplete.
   - The admin's own join sends nothing, because staff are excluded.
2. **The pair.** Join from an account that has **never played Podnappers** and is not an admin. Stay about a minute, then leave.
   - Michael should see exactly one `new_player_joined` and one `new_player_session_ended`, with the same `sessionId`.
   - `sessionDurationSeconds` should be close to the time spent, and `campaignTag` should be `unknown`.
3. **Returning.** Rejoin with the same account. Nothing new should arrive.
4. **A tag (optional).** Use a second never-played account and a link carrying an allowlisted tag: `https://www.roblox.com/games/start?placeId=114075467877655&launchData=<tag>`. Both events should show that tag.
5. **The receiver.** Michael confirms the Sheet deduplicates a replayed body and handles an ending that arrives first. He can test both by re-sending the fake sample JSON above to his own scenario.
6. Delete the test rows afterwards if the Sheet should hold only real players.
