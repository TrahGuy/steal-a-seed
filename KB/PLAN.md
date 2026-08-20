# Steal a Seed — Build Plan

Agreed 2026-08-20. Supersedes the artifact design entirely. The reference design document is
[BLUEPRINT.md](BLUEPRINT.md); this file is what we are actually building and in what order.

---

## The theme

Steal seeds from guarded wild patches, run them home while other players try to take them off you,
plant them, and watch what grows. Plants generate cash forever. Cash buys Speed. Speed opens
biomes. Biomes hold rarer seeds.

| Reference game | Ours |
| --- | --- |
| Egg | **Seed** |
| Nest | **Wild Patch** |
| Incubator | **Planter** |
| Hatching | **Growing** |
| Pet | **Plant** |
| Pet Index | **Almanac** |

Biomes are unchanged — Forest, Desert, Jungle, Volcano, Cosmic — and gain from the reskin: ferns,
cacti, orchids, ember-blooms, starflowers. A plant rooted on your base earning money is a more
natural image than a pet standing next to one.

---

## Three decisions that everything else depends on

### 1. Speed is a SCORE. WalkSpeed is a curve.

```lua
WalkSpeed = 16 + (150 - 16) * (1 - math.exp(-Speed / 20000))
```

| Speed | 0 | 2,000 | 10,000 | 30,000 | 100,000 |
| --- | --- | --- | --- | --- | --- |
| WalkSpeed | 16.0 | 28.7 | 68.7 | 120.1 | 149.1 |

**This is not a balance preference, it is a hard engine constraint.** Roblox character physics
degrades badly past roughly 200 studs/second: characters tunnel through thin geometry, network
ownership thrashes as the humanoid outruns its own replication, and the camera cannot track. A
design where Speed gates a biome at 10,000 and Rebirth wants 100,000 CANNOT feed that number to
`Humanoid.WalkSpeed`.

The curve keeps both halves honest: the player watches a number climb without limit, and the
simulation never sees past 150. Early gains feel large in relative terms (16 -> 29 is nearly
double); late gains are prestige rather than mobility, which is correct, because by then Speed's job
is unlocking biomes rather than making you faster.

Carry penalty multiplies the RESULT, so a fast player carrying a rare seed is still slowed
proportionally and can still be caught.

### 2. Cash is hard-capped at 1e15. No big-number library.

Luau numbers are IEEE doubles: exact for integers up to 2^53 (about 9.007e15) and silently
approximate above it. Silently is the problem — no error, just cash that stops adding up correctly
and a save that round-trips to a different value than it left as.

The cap is **1e15**, displayed as "1Qa", a comfortable margin inside the exact range.

A big-number representation was considered and rejected. It infects every arithmetic operation,
every comparison, every sort, every UI format and every save field, permanently, to buy digits no
player reads. If progression ever genuinely runs into the cap, that is a rebirth-scaling problem to
solve in the multipliers, not a number-format problem.

**The cap must exist before the save schema does.** Adding it later means migrating every profile.

### 3. The foundation is wiped, and that was the owner's call.

The Phase 1 artifact foundation had roughly 70% overlap with what this design needs — the service
bootstrap, base claiming, profiles, save, and an 8-base ring around a central hub. The
recommendation was to keep the plumbing and replace the content layer.

The owner chose a clean wipe. Recorded here because it is a real cost and should be a deliberate
one, not something discovered later: it is a rebuild of base claiming, profile loading, autosave and
the boot sequence.

**Nothing is lost.** The whole of it is recoverable from git at commit `b08dd8e`, and the four files
worth re-reading before rewriting their replacements are:

  * `ServerMain.server.luau` — the drop-a-file service bootstrap, worth reproducing exactly
  * `BaseService.luau` — 8 bases round a hub, with the join-ordered waiting queue
  * `PlayerDataService.luau` — the read-only-on-failed-load rule, which is not optional
  * `SaveService.luau` — session locking, throttle awareness, forward-only versioning

---

## What is deliberately NOT in v1

Every item below is from the reference design and every one is worth building **eventually**. None
of them is worth building before the core sixty seconds is proven fun, and each is cheap to add
afterwards.

| Deferred | Why |
| --- | --- |
| Gems | a second currency with no sink until there is a shop worth spending in |
| Rebirth | meta-progression on top of progression that does not exist yet |
| Almanac | a completion tracker for a collection that is not yet collectable |
| Boosts | accelerators for a loop with no measured pace |
| Mutations / sizes | multipliers on an income model that is not tuned |
| Guards / patrolling NPCs | **the single most expensive item in the document** |
| Multi-seed backpack | great tension, but it multiplies every carry-state edge case |
| Offline income | doubles save complexity; the top source of "my cash reset" reports |

**On guards specifically:** pathfinding NPCs across five biomes is months of work and the tension
they create is largely reproducible with lava, moving platforms, narrow bridges and long sightlines.
Environmental hazards are static geometry with a `Touched` handler. Build the loop with hazards, add
guards to Forest only once it is fun, and never build twenty-five patrol routes on spec.

---

## Phases

### Phase A — the loop

**Hub, eight bases, all five biomes as geometry, Forest live.**

```
claim base -> walk to a Wild Patch -> take a seed -> carry it home slowed
           -> drop it in a Planter -> it grows -> a Plant appears -> cash ticks up
```

Done when: **you steal a seed and watch your cash counter start moving.**

This phase is the entire bet. If it is not fun with placeholder cubes, nothing in Phases B–E fixes
it. Everything else in this document is scaffolding around this sixty seconds.

Five biomes are built as GEOMETRY in Phase A because the map is code and the hub-and-spoke layout
has to be right from the start — but only Forest has live Wild Patches. The other four are visible,
walkable, and gated.

### Phase B — the theft

PvP seed stealing, safe zones, carrier vulnerability, the server-wide "somebody has a Legendary
seed" alert.

Done when: **two players can fight over one seed.**

Steal is a server-side proximity check plus a deliberate input, **not** a raw `Touched` handler —
two characters at WalkSpeed 100 brushing past each other fires `Touched` unpredictably, and an
accidental transfer is indistinguishable from a griefed one. A 1.5s immunity window after any
transfer stops instant steal-backs.

### Phase C — the progression

Speed, the treadmill, biome gates, and Desert / Jungle / Volcano / Cosmic going live.

Done when: **Speed is the reason you log in tomorrow.**

### Phase D — the numbers

Shop, plant inventory, equip slots, upgrades, and a shared UI kit so panels five through nine are
cheap.

Done when: **cash has somewhere to go.**

**Equipped plants need a slot cap from the first line of this phase.** Without one, income scales
with collection size forever and the economy is unbounded on day one.

### Phase E — retention

Almanac, boosts, mutations, Rebirth, Gems, leaderboards.

---

## Open questions

  * **The place is still named "Steal an Artifact"** (`114075467877655`). Only the owner can rename
    a Roblox place; the repo and code are renamed here.
  * **Biome geometry in code has a ceiling.** Forest and Desert are comfortably blocky. Jungle
    bridges and Volcano lava flows may be the point where hand-built `.rbxmx` committed to the repo
    beats generating it. Revisit at Jungle rather than deciding now.
  * **Server size.** Eight bases means eight players. Third-party data reports the reference game
    caps at seven. `MaxBases` and `MaxPlayers` must be one number, and the boot warning that catches
    a mismatch is worth reproducing.
