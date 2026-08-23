# Steal a Seed — Roblox Place Project

Multiplayer PvP extraction / collection simulator. Rojo 7.6.1, synced to Roblox Studio.

Read [KB/HANDOFF.md](KB/HANDOFF.md) at the start of every session and update it before ending one.
[KB/BLUEPRINT.md](KB/BLUEPRINT.md) is the design source of truth — the game's direction, not its code.

## Rojo port: 34872 (the plugin default), guarded by servePlaceIds

```
rojo serve --port 34872
```

**The guard is the place pin, not the port.** `default.project.json` carries
`servePlaceIds: [114075467877655]`, so the plugin REFUSES to sync this project into any place that
is not `Steal a Seed`. A wrong connection fails loudly instead of quietly.

That matters because of what happened on 2026-08-18, before the pin existed. Three projects on this
machine all default to 34872. `D:\KAPE\Tetris Arena` was serving, the Cloud Cafe Studio was
connected to it, and Rojo cheerfully synced BlockArena's 41 scripts into the cafe place while the
cafe's own disk edits reached nothing. Whichever Studio connects last wins and neither side says a
word.

| project | port | pinned? |
| --- | --- | --- |
| **Steal a Seed** | **34872** | **yes — `114075467877655`** |
| Cloud Cafe Tycoon | 34873 | no |
| Tetris Arena / BlockArena | 34872 | no |

**Only one process can bind 34872 at a time**, so the live risk is sequential rather than
simultaneous: stop this server, start BlockArena's on the same port, and a Studio that auto-reconnects
finds the wrong project. The pin protects THIS project in that scenario; the other two are still
unguarded and should get `servePlaceIds` of their own.

Check in five seconds: `curl -s localhost:34872/api/rojo` names the project and the place it will
accept.

## Git policy

After every modification, commit and push:

```
git add -A
git commit -m "<what changed and why>"
git push origin main
```

One logical change per commit. Never end a session with uncommitted work.

## Structure

```
default.project.json          Rojo map
src/
  ReplicatedStorage/SeedGame/
    Shared/GameConfig.luau      names, capacity, map geometry, speed curve, save
    Shared/BiomeData.luau       the five biomes and where they sit on the road
    Remotes/                    created at runtime by ServerMain
  ServerScriptService/SeedGameServer/
    ServerMain.server.luau      bootstrap: Init() all, then Start() all
    MapService.luau             builds the whole map, and the lighting, from code
    PlotService.luau            who owns which plot, and puts them on it
    ProfileSchema.luau          what a profile is, and the validator (NOT a *Service)
    SaveService.luau            DataStore transport, session locking
    PlayerDataService.luau      profiles in memory, autosave, replication
    CreatureModel.luau          pods and creatures (NOT a *Service)
    ParentModel.luau            the nest guardian (NOT a *Service)
    NestService.luau            nests, and the parent that sleeps beside them
    CarryService.luau           one pod at a time, and what it costs to carry
    PlantService.luau           planting, and growing pod -> sprout -> creature
    EconomyService.luau         THE FAUCET -- grown plants pay kg/sec, nothing else mints
    TreadmillService.luau       THE FAUCET for Speed -- stand on your own mill
src/StarterPlayer/StarterPlayerScripts/
    Ambience.client.luau        wings, walk cycles -- decoration only
    ParentAnim.client.luau      the nest parent's limbs
    PromptUI.client.luau        draws every ProximityPrompt (Style = Custom)
    AlertUI.client.luau         the RUN alarm, vignette and SAFE flash
    PlantUI.client.luau         hatch/grow timer over anything tagged Planted
    PlantSway.client.luau       idle lean on planted sprouts/creatures (rooted)
    CashUI.client.luau          corner HUD: cash + speed, from the ProfileUpdated remote
    CashPop.client.luau         lime +$N rising off every grown plant (cosmetic only)
    IndexUI.client.luau         LEFT rail: the almanac, ??? until you have grown it
    GardenUI.client.luau        RIGHT rail: a row per plot slot, live clocks
    SpeedFX.client.luau         +N pops on Speed gain, and the run streak
    CarryPose.client.luau       both arms under the pod while carrying
```

**Phase A is complete**: steal -> carry -> bank -> plant -> grow -> earn, with cash moving on
screen. Still to come: the HUD, and Phase D upgrades. See [KB/PLAN.md](KB/PLAN.md).

## The map is ONE ROAD

```
FIELD ══ GREENHOLLOW ─── DUSTBOWL ─── TANGLEMIRE ─── EMBERROOT ─── STARBLOOM
(safe)       300            600           900            1200          1500
  ▲                                                          studs from safety
the red line
```

Biomes are segments of a single corridor, not separate areas. **Distance is difficulty**, the run
home gets longer as the prize gets better, everybody shares one road so PvP happens on the way past,
and standing at the safe line you can see all five biomes receding into the distance — which is the
entire progression display, with no UI.

Two consequences worth not breaking:

- **Pods sit along the walls, never in the middle.** Taking one costs you the racing line. There is
  a build-time check that fails loudly if a pod ends up near the centre.
- **Nothing may obscure the road.** `MapService` zeroes `FogEnd` *and* the `Atmosphere` instance,
  because either one alone still greys out the far end at 1,500 studs.

## Rules

From the blueprint, plus what this repo has learned:

1. **Never rebuild an existing system.** Check the repo before adding code.
2. **Adding a service is dropping a `*Service.luau` file in `SeedGameServer`.** ServerMain finds
   it, orders it by `Priority`, runs `Init()` then `Start()`. No registry to update.
3. **The server owns economy and ownership.** A client never picks, claims or pays.
4. **Validate every RemoteEvent argument.** The sender is engine-stamped and cannot be forged; every
   other argument came off the wire and is a lie until checked.
5. **Nothing is placed by hand.** The map, the HUD, every instance is built in code. Both
   predecessor projects on this machine still carry "the map is not in version control" as an open
   item; this one never will.
6. **One faucet.** Cash mints in `EconomyService` and nowhere else.
7. **Numbers live in data files.** Seed and plant balance in `SeedData`, biome content in
   `BiomeData`. `GameConfig` holds names, structure and the speed curve, never balance.
8. **Mobile first.** Blocky studded plastic, low part counts, no per-frame allocation.
9. **`--!strict` on every file.**
10. **Scripts must be safe to re-run.** `MapService` destroys and rebuilds rather than patching.

## Toolchain

- Rojo: `C:\Users\Maykel\AppData\Local\Microsoft\WinGet\Packages\Rojo.Rojo_Microsoft.Winget.Source_8wekyb3d8bbwe\rojo.exe` (on PATH)
- No Node.js on this machine. The npm package named `rojo` is unrelated — do not use it.
- Build a place file: `rojo build -o build/StealASeed.rbxlx`

### Previewing the map in Edit

**The place is an empty baseplate in Edit and that is correct.** Rojo syncs code into
ServerScriptService / ReplicatedStorage / StarterPlayerScripts; the map is not stored
anywhere, because `MapService` builds it at RUNTIME. Press Play and it appears. Stop, and it is gone
again.

That is the cost of the map being code, and it is worth paying -- but it does mean you cannot eyeball
the layout without starting a server. To build it in Edit anyway, paste this into the Command Bar:

```lua
require(game.ServerScriptService.SeedGameServer.MapService).Init()
```

`Init()` destroys any previous `SeedMap` before building, so it is safe to run repeatedly --
which is what makes it usable for tuning geometry: edit `GameConfig.Map` or `BiomeData`, let Rojo
sync, run the line again, look.

### Why the workspace is empty every time you stop Play

Two things combine, and neither is a fault:

  * The map is built at RUNTIME by `MapService`, so it has never existed in the saved place.
  * **Stopping Play discards everything Play created.** Play is a sandbox; the datamodel reverts to
    its pre-Play state, and the map the server built goes with it.

**You should never see this happen**, because the *Steal a Seed* Studio plugin rebuilds the map
automatically whenever it is missing in Edit. Plugins run in the Edit datamodel, which is suspended
for the duration of a Play session and resumes on Stop — so the first tick after you stop testing is
what puts the map back, with no input at all.

Installed from
[tools/studio-plugin/SeedMapBuilder.server.lua](tools/studio-plugin/SeedMapBuilder.server.lua) into
`%LOCALAPPDATA%\Roblox\Plugins\`; restart Studio to pick up changes to it. **Build Map** forces a
rebuild and re-enables auto-rebuild; **Clear Map** removes it and turns auto-rebuild off, because a
clear that undid itself a second later would look broken.

None of this ever makes the map savable: `MapService` marks the folder `Archivable = false` and the
plugin sets it again, so even a map built by an older `MapService` cannot reach the `.rbxl`.

Nests are deliberately NOT built by the button: `NestService` starts a tick loop and raises Humanoids
that would wander an Edit session forever with nothing to chase. Press Play for those.

**You no longer have to delete `Workspace.SeedMap` before saving.** `MapService` builds the map
folder with `Archivable = false`, which the engine honours both when the place is saved and when the
datamodel is cloned — verified, not assumed: `map:Clone()` returns nil, and cloning its parent copies
a normal child while skipping an `Archivable = false` one.

So the map can sit in Edit permanently for eyeballing, it never reaches the .rbxl, and pressing Play
cannot carry an Edit-built copy into the session either.

That used to be a human rule — *remember to delete it before saving* — and a rule you have to
remember is a rule that gets forgotten. It was worse than that: obeying it left Studio looking
**empty**, which reads as breakage and twice cost a round of "where did the map go". Leave the map
where it is.

### Checking Luau syntax without a Play session

`start_stop_play` over MCP is unreliable on this machine. To compile-check a file without running it:
serve the repo (`python -m http.server 8731`), then in Studio Edit fetch it with `HttpService` and
require it wrapped in `local function __check() ... end return true`. The body compiles; nothing runs.
This is the only way to check a `.server` script without its side effects firing in the Edit datamodel.
