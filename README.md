# Steal a Seed

A multiplayer PvP extraction simulator for Roblox. Find an artifact in a dangerous zone, carry it
home slower than you walked in, and get it onto your display before somebody takes it off you.

> Design source of truth: [KB/BLUEPRINT.md](KB/BLUEPRINT.md)
> Session state: [KB/HANDOFF.md](KB/HANDOFF.md)
> Working rules: [CLAUDE.md](CLAUDE.md)

## The loop

```
Spawn → Explore Artifact Zone → Find Artifact → Carry it (slower, visible, attackable)
      → Escape → Return To Base → Display → Earn Coins → Upgrade → Find better artifacts
```

## Status

| Phase | State |
| --- | --- |
| **1 — Foundation** | **built, not yet play-tested** — map, bases, claiming, spawning, profiles, save |
| 2 — Artifact collection | not started |
| 3 — PvP theft | not started |
| 4 — Tycoon progression | not started |
| 5 — Content expansion | not started |

Phase 1 is done when a player joins and receives a base. The code for that exists and every part of
it compiles; nothing has run in a live session yet.

## Running it

```
rojo serve --port 34872
```

34872 is the Rojo plugin's default. What keeps this project safe is not the port but the pin:
`servePlaceIds` in the project file means the plugin refuses to sync it into any place except the
one below. See CLAUDE.md for why that matters on this machine.

Place: `Steal a Seed`, placeId `114075467877655`.

## The map is code

There is no hand-placed geometry in this project and there never will be. `MapService` builds all
148 parts — eight bases on an even ring, a neutral spawn island, and two artifact zones — from
`GameConfig.Map` and `ZoneData` on every boot, in about 40 milliseconds.

Both predecessor projects on this machine still carry "the map is not in version control" as an
open item. This one is diffable, identical on every server, and survives losing the place file.

## Layout

```
              THE RUINS          10 pedestals, base odds
       BASE          BASE
BASE                         BASE
          SAFE SPAWN
BASE                         BASE
       BASE          BASE
              THE VAULT          6 pedestals, slower, 2.2x rare odds
```

The base ring is rotated half a step so no base sits directly in front of a zone — otherwise one or
two players would spawn with a materially shorter run home than everybody else.

## Artifacts

Seven bands, Common (100 coins) to Secret (5,000,000). Sampled over 200,000 rolls:

| | Common | Uncommon | Rare | Epic | Legendary | Mythic | Secret |
| --- | --- | --- | --- | --- | --- | --- | --- |
| odds | 61.92% | 24.96% | 10.03% | 2.53% | 0.499% | 0.059% | 0.002% |

Bigger prizes carry slower. That single column is the whole risk curve.
