# Steal a Seed

A multiplayer PvP extraction game for Roblox. Steal seeds from wild patches down a long dangerous
road, run them home past everyone else running the same road, and plant them. Plants pay forever.

> Design source of truth: [KB/BLUEPRINT.md](KB/BLUEPRINT.md)
> Session state: [KB/HANDOFF.md](KB/HANDOFF.md)
> Working rules: [CLAUDE.md](CLAUDE.md)

## The loop

```
Steal a seed → run it home → plant it → it pays forever → buy Speed → reach a rarer biome
```

Cash buys Speed. Speed opens biomes. Biomes hold rarer seeds. Rarer seeds pay more.

## The map is ONE ROAD

```
FIELD ══ GREENHOLLOW ─── DUSTBOWL ─── TANGLEMIRE ─── EMBERROOT ─── STARBLOOM
(safe)       300            600           900            1200          1500
  ▲                                                          studs from safety
the red line
```

The five biomes are **segments of a single corridor**, not separate areas — and that one decision is
the entire risk curve expressed as geometry:

- **Distance is difficulty.** Nothing needs explaining. The rarer seed is visibly further away, and
  you can see how far.
- **The run home gets longer as the prize gets better.** A Starbloom seed is 1,500 studs from safety
  *through every other biome*. That costs nothing to implement — it is just where the walls are.
- **Everyone shares one road**, so PvP happens on the way past rather than having to be arranged.
  Parallel lanes would let players miss each other entirely.
- Standing at the safe line you can see all five biomes receding into the distance. That is the whole
  progression display, with no UI.

Seed pods sit **along the walls, never in the middle**, so taking one costs you the racing line —
a real decision when somebody is behind you. There is a build-time check that fails loudly if a pod
ends up near the centre.

The safe zone is a **red stripe painted flat on the grass** with SAFE ZONE written on it. No dome, no
forcefield, no billboard — a floor decal is readable at thirty studs while sprinting, which is the
entire requirement.

## Plots ring a hub

Six plots around a central market square, gates all facing in, road leaving through a gap in the
ring. A ring rather than a row because of expansion: plots grow **outward**, so their inner edges
never move and every gate stays the same distance from the shop, while the arc at their outer edge
gets longer as the radius does. A row can only expand into space reserved up front.

A plot is plain dirt in a wooden frame behind a non-collidable fence — non-collidable because a
player sprinting home at WalkSpeed 120 who clips a fence post and stops dead has been robbed by the
scenery.

## Status

It boots and runs. A single-player Play session assigns a plot, places the character on it, and returns them there on respawn. Nothing has been tested with two or more players yet.

| Phase | State |
| --- | --- |
| **A — the loop** | **in progress** — map and plot ownership built and running; seeds, carrying, planting, economy and HUD not started |
| B — the theft | not started |
| C — the progression | not started |
| D — the numbers | not started |
| E — retention | not started |

Built so far:

| | |
| --- | --- |
| `MapService` | the whole world and its lighting, from code |
| `PlotService` | who owns which plot, and puts them on it |
| `FairyService` | walks Marigold, who runs the shop |

Phase A is done when a player can steal a seed, get it home, plant it, and watch it pay.

## The map is code

There is no hand-placed geometry in this project and there never will be. `MapService` builds all
**1,204 parts in 0.12 seconds** on every boot, from `GameConfig.Map` and `BiomeData`.

Fifteen of those parts are unanchored, and all fifteen are Marigold — a Humanoid cannot walk
anchored. Everything else in the world is fixed.

Both predecessor projects on this machine still carry "the map is not in version control" as an open
item. This one is diffable, identical on every server, and survives losing the place file. The cost
is that the place looks like an empty baseplate in Edit, which is correct: press Play and the world
appears.

## Running it

```
rojo serve --port 34872
```

34872 is the Rojo plugin's default, and three projects on this machine share it. What keeps this one
safe is not the port but the pin: `servePlaceIds` in the project file means the plugin **refuses** to
sync it into any place except the one below, so a wrong connection fails loudly instead of quietly.
See [CLAUDE.md](CLAUDE.md) for the incident that earned that pin.

Place: `Steal a Seed`, placeId `114075467877655`.

## Design rules

1. Never rebuild an existing system — check the repo first.
2. Adding a service is dropping a `*Service.luau` file in `SeedGameServer`. The bootstrap finds it,
   orders it by `Priority`, runs `Init()` then `Start()`. There is no registry to update and
   therefore no way to add a service and forget to start it.
3. The server owns economy and ownership. A client never picks, claims or pays.
4. Validate every RemoteEvent argument. The sender is engine-stamped and cannot be forged; every
   other argument came off the wire and is a lie until checked.
5. Nothing is placed by hand.
6. One faucet — cash mints in `EconomyService` and nowhere else.
7. Numbers live in data files. `GameConfig` holds names, structure and the speed curve, never
   balance.
8. Mobile first: blocky studded plastic, low part counts, no per-frame allocation.
9. `--!strict` on every file.
10. Scripts must be safe to re-run. Services destroy and rebuild rather than patching.
