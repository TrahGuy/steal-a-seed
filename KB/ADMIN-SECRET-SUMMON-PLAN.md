# SUMMON A SECRET (the admin console) — the plan (2026-10-16)

**Status: APPROVED 2026-10-16**, built by Claude (desktop).

The owner: "suggest what to add more in admin console", then "ask a lot of questions". Of four areas offered
(secret tools, player tools, world and nests, boosts and events) they picked **secret tools**, and of those
only **spawn a secret now**.

## The owner's answers

| Question | Answer |
| --- | --- |
| Which secret tools? | **Spawn a secret now** (not: end the one out, a secret hunt, where is it). |
| Who? | **Every admin account** (the console's allowlist). |
| The game's rules? | **Same rules**: refused while a secret is out (in this server) or a POD RUSH runs. |
| What players see? | **The usual toast plus the admin's line**: "{admin} summoned a SECRET!", in the admin announcement style. |
| Which servers? | **THIS SERVER or ALL SERVERS, each time**, like the console's events. |
| The biome? | **Pick one, or RANDOM.** |
| Where? | **The Events page.** |
| After ALL SERVERS? | **"Sent", then this server's own result**; other servers apply their own rules silently. |
| A refusal? | **The reason**: "A secret is already out (Mirehydra in Tanglemire)", "A POD RUSH is on". |
| What's New? | **No** (players cannot use it). |
| Testing? | **Specs and one guarded Play.** |

## How it works

- The console's Events page gets a SECRET card. It has five biome choices and RANDOM, THIS SERVER or ALL SERVERS, and SUMMON. ALL SERVERS asks YES, ALL SERVERS first.
- The server summons by the game's own spawn (NestService.SummonSecret: the secret's pod on its cradle, its toast). RANDOM picks a biome as the dawn roll does.
- Where it spawned, everybody also reads the admin's line.
- ALL SERVERS summons here first, then sends one MessagingService message (an id, the biome, the admin's name and badge, when).
  - Every server summons under its own rules and shows the admin's line where it spawned.
  - An id is never acted on twice; one older than a minute is dropped.
- In Studio nothing is published: it would reach the live game's servers, as AnnouncementService already knows.
- Every summon is in the console's audit.
