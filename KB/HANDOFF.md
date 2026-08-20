# Steal a Seed — Session Handoff

> Living document. **Read this first when picking up the project. Update it before ending any
> session, then commit and push** (see the git policy in [CLAUDE.md](../CLAUDE.md)).
>
> [PLAN.md](PLAN.md) is what we are building and in what order. [BLUEPRINT.md](BLUEPRINT.md) is the
> reference design. This file is where things actually stand.

---

## Where it stands (2026-08-20)

**Phase A, map only.** The world exists and is dressed. Nothing else does: no plot claiming, no
profiles, no seeds, no carrying, no HUD. Four files.

```
src/ReplicatedStorage/SeedGame/Shared/
  GameConfig.luau     names, capacity, map geometry, the speed curve, save schema
  BiomeData.luau      the five biomes and where they sit on the road
src/ServerScriptService/SeedGameServer/
  ServerMain.server.luau   bootstrap: Init() all, then Start() all
  MapService.luau          layout, lighting
  MapDecor.luau            dressing  (NOT a *Service -- see below)
```

**889 parts, built in 0.14 seconds.** Zero unanchored, zero gaps in the road, zero solid decoration,
zero tall props inside the racing line.

---

## THE MAP IS ONE ROAD

```
FIELD ══ GREENHOLLOW ─── DUSTBOWL ─── TANGLEMIRE ─── EMBERROOT ─── STARBLOOM
(safe)       300            600           900            1200          1500
  ▲          🙂             😐            😟             😨            💀
the red line                                              studs from safety
```

Built it as five parallel lanes first. **That was wrong and the owner corrected it.** Biomes are
segments of a single corridor laid end to end, and that one change expresses the whole risk curve as
geometry, for free:

  * Distance IS difficulty. Nothing needs explaining -- the rarer seed is visibly further away.
  * **The run home gets longer as the prize gets better.** A Starbloom seed is 1,500 studs from
    safety, through every other biome.
  * Everybody shares one road, so PvP happens on the way past instead of having to be arranged.
    Parallel lanes let players miss each other entirely.
  * Standing at the red line you can see all five biomes receding into the distance. **That is the
    entire progression display and there is no UI in it.**

The biome names are ours. Forest/Desert/Jungle/Volcano/Cosmic is the generic simulator ladder every
game in the genre uses; these read as a garden going progressively wrong, which is the game actually
being made.

---

## FOUR INVARIANTS THAT ARE LOAD-BEARING

Each one is enforced by a check in the build that warns rather than by a comment asking nicely.

1. **Nothing decorative is collidable.** Every prop is `CanCollide`, `CanTouch` and `CanQuery`
   false. A player sprinting home at WalkSpeed 150 who catches on a mushroom has been robbed by the
   scenery, and in a game whose whole tension is a chase that is not a small bug. Same reason the
   plot fences are non-collidable.
2. **Height falls off toward the centre.** Tall props only near the walls; the middle 48 studs gets
   ground cover and nothing else. A row of trees down the middle deletes the sightline, which is the
   reason the map is a corridor at all.
3. **Pods sit along the walls, alternating sides, never in the middle.** Taking one costs you the
   racing line -- a real decision with somebody behind you.
4. **Nothing may obscure the road.** `MapService` zeroes `FogEnd` *and* the `Atmosphere` instance.
   Either one alone still greys out the far end at 1,500 studs.

### The bug that made invariant 2 real

The first decoration pass put a rock inside the racing line. Not because the rule was ignored --
because `scatter` guarded the prop's **anchor point**, and a rock carries a second block three studs
off that anchor. A prop placed exactly on the boundary spilled its far half over it.

The fix is that the margin now includes the prop's own declared `radius`, which `scatter` already
knew because it needs it for spacing. **Reusing the number the prop already declares means the
margin can never drift out of step with the prop it protects against.** And `dressSegment` now
checks the parts it ACTUALLY placed and warns, because this class of bug is invisible to reading and
only shows up in geometry.

---

## Things worth not rediscovering

  * **`MapDecor` is deliberately not named `*Service`.** `ServerMain` auto-requires and starts every
    ModuleScript in that folder ending in `Service`. `MapDecor` is a helper with no lifecycle, called
    by `MapService` during its own `Init`.
  * **Decoration placement is deterministic** -- `Random.new(seedFor(biome.Id))`, never
    `math.random`, so every server builds the identical world.
  * **`seedFor` is a mod-p polynomial hash, not FNV-1a.** FNV's `h * 16777619` exceeds the double
    mantissa in Luau and silently loses precision, which breaks reproducibility at exactly the point
    you are relying on it.
  * **Lighting is in `MapService`.** A blank place defaults to a gloomy evening and the first build
    rendered almost black -- which looks like a bug and is not one. `Lighting.Technology` is
    deliberately untouched: it is not scriptable and every read of it is wrapped.
  * **Seed pods take the biome's accent colour**, which makes them the brightest solid thing in
    every biome. That was an accident and it is correct -- they are the objective.

---

## Verified, and NOT verified

Verified in Edit, by building the map for real and measuring it: part counts, zero unanchored, road
continuity, pod placement, decoration invariants, plot-to-road distance (106 studs), and the speed
curve against the reference game's real scale — **3.2 billion Speed maps to WalkSpeed 150.0**.

**Nothing has run in a Play session.** `ServerMain` has never executed. `start_stop_play` over MCP
wedged Studio three times on 2026-08-20 and has not been retried since; restart Studio before trying
again, because the wedged state does not clear on its own.

---

## Still open

  * **The cash cap.** PLAN.md picks 1e15 and then the footage showed the reference game running at
    2.7B/sec, which reaches that in about four days of idling. Must be settled **before the save
    schema is written**.
  * **SpeedGate values are known to be wrong** — spaced correctly relative to each other, absolute
    numbers meaningless until the treadmill exists and there is a measured rate to scale against.
  * **The Roblox place is still named "Steal an Artifact"** (`114075467877655`), as is the repo
    folder. Only the owner can rename the place.
  * **Offline income.** Deferred in the plan; the reference advertises it in a banner across the top
    of the screen as the reason to come back tomorrow.

## Next

`PlotService` — claim a plot on join, name on the sign, spawn on its pad, release on leave with a
join-ordered waiting queue. Then `PlayerDataService` + `SaveService`, then the seed → carry →
planter loop that is Phase A's actual success criterion.
