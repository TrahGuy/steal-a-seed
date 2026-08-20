# Steal a Seed — Session Handoff

> Living document. **Read this first when picking up the project. Update it before ending any
> session, then commit and push** (see the git policy in [CLAUDE.md](../CLAUDE.md)).

## Phase 1: a foundation built out of two projects' scar tissue (2026-08-20)

New repo, created from the owner's master blueprint. The decision that shaped everything else was
made before a line was written: **port the proven systems out of `Steal the Ore and Forge` rather
than either rebuilding them or pivoting that project in place.**

That project already had ~2,300 lines of tested Luau covering base claiming, carry, drop, steal and
deposit — the blueprint's Phases 1 through 3 under different names. But it is a different GAME: you
BUY ore off a conveyor there and you FIND artifacts in a zone here, and its 3,204-part foundry is
the wrong theme and not in version control. So: new repo, systems lifted, OreForge left intact.

`BaseService` is `PlotService` with its bugs fixed. `ServerMain` is `ServerBootstrap` verbatim in
spirit — and it earns its keep every phase from here, because **adding a service is dropping a
`*Service.luau` file in the folder.** No registry, no require list, no way to add a service and
forget to start it.

### THE MAP IS CODE, AND THAT IS THE POINT OF THE WHOLE PROJECT

Both predecessors carry the same open item in their handoffs: the map exists only inside a `.rbxl`
and cannot be reproduced. Cloud Cafe's audit calls it the thing a lost file would destroy; OreForge
still lists its foundry as "the only remaining unreproducible artifact".

`MapService` builds all **148 parts in 0.040s** from `GameConfig.Map` and `ZoneData`, every boot,
destroying and rebuilding rather than patching. Moving the entire island is one edit to `BaseY`. The
cost is that it will never look hand-crafted; for a blocky studded simulator that is the right trade
every single time.

### FOUR THINGS FIXED THAT THE PREDECESSORS STILL CARRY AS OPEN BUGS

  * **A real waiting queue.** OreForge's audit still says: *"releasePlot never offers a freed plot to
    a player already waiting, and the join-time retry gives up after 10 attempts one second apart."*
    `BaseService` keeps a join-ordered queue; a base freed at any point goes to whoever has waited
    longest. Nobody retries and nobody gives up. It costs one table.
  * **Capacity is one number.** Cloud Cafe shipped a 6-plot map on a 60-player place and nine of ten
    joiners got nothing. `MaxBases` and `MaxPlayers` sit together, and `ServerMain` **warns at boot**
    if `Players.MaxPlayers` disagrees — it is a place setting code cannot change, so the only honest
    move is to refuse to be quiet about it.
  * **A failed profile load is not a new player.** The most destructive save bug available: the
    DataStore blips, the game hands out a fresh profile, the first autosave writes it over a real
    account. A failed load is marked `readOnly` and is **never written back**. The player plays; they
    just do not overwrite anything.
  * **One coin faucet.** `EconomyService.AwardArtifact` and nothing else. Cloud Cafe's audit names
    this as the invariant that kept its economy reasonable at Phase 5.

### TWO BUGS FOUND BY LOOKING, NOT BY READING

Both were invisible to the compiler and to the arithmetic:

  1. **The bases intersected the Vault's floor.** A base reaches `BaseRingRadius + Size/2` = 178; a
     zone 160 deep centred at 250 starts at 170. Eight studs of overlap, obvious in a screenshot and
     in nothing else. `ZoneDistance` is 280 now, giving 33.4 studs of clearance —
     **and `MapService` now checks the three numbers against each other at boot and warns**, because
     a comment saying "keep these apart" is not a thing that keeps them apart.
  2. **A `require` inside the artifact roll function**, re-resolving `GameConfig` on every single
     spawn. Hoisted.

### VERIFIED

  * All 11 files compile.
  * Map: 148 parts, 8 bases, 2 zones, 16 pedestals, **0 unanchored**, ring radius identical on all
    eight (150.0 min and max), nearest base **57.4 studs** off the zone axis, **0 base/zone overlaps**.
  * Every base carries all eight blueprint components — SpawnPad, ArtifactDisplay, CoinCollector,
    UpgradeArea, OwnerSign, ProtectionZone, Base, Runtime.
  * `ArtifactData.RollRarity` over **200,000 samples** matches its documented odds: Common 61.92%,
    Uncommon 24.96%, Rare 10.03%, Epic 2.53%, Legendary 0.499%, Mythic 0.059%, Secret 0.002%.
  * Photographed from above and at base level. The layout matches the blueprint's ASCII.

### NOT VERIFIED — READ THIS BEFORE TRUSTING ANY OF IT

**Nothing has run in a Play session.** Not one line. `start_stop_play` over MCP wedged Studio three
times earlier in the day and was not attempted again here. So:

  * No player has ever been assigned a base. **That is Phase 1's entire success criterion.**
  * `SaveService` has never reached a DataStore. It will report itself unreachable in Studio until
    Game Settings → Security → *Enable Studio Access to API Services* is ticked.
  * `PlayerDataService`, `BaseService` and `MainHUD` have never been past `Init()`.

Everything above was proved by compiling each file inside a `local function __check()` wrapper and
by calling `MapService.Init()` directly in the Edit datamodel. That proves the map and the data. It
proves nothing about the lifecycle.

### FIRST THING NEXT SESSION

1. Connect Rojo (`localhost:34872`) and sync.
2. Press Play. Watch for `[Artifact] Steal a Seed v0.1.0 (Phase 1) online -- 5 service(s)`.
3. Confirm a base is claimed, the sign shows your name, and you spawn on its pad.
4. Tick API Services and confirm `SaveService` reports the store reachable.

Then Phase 2: `ArtifactService` (spawn on pedestals), carry, deposit. `CarryService`,
`DroppedOreService` and `DepositService` in `D:\KAPE\Steal the Ore and Forge` are the proven
starting points — read them before writing anything.

### HOUSEKEEPING

  * Port **34872**, the plugin default, pinned with `servePlaceIds: [114075467877655]` so the
    plugin refuses to sync it into the wrong place. `/api/rojo` confirms `expectedPlaceIds`. It
    started on 34874 to dodge the 08-18 collision; the pin turned out to be the better guard, and
    the owner's plugin was already on the default.
  * **A Rojo restart drops the plugin's connection AND leaves a stale `__Rojo_SessionLock` behind.**
    Four restarts during the rename cost a round trip: the server logged no connection at all while
    the place still held a lock with `Value=nil`. Delete the lock, reconnect.
  * **A synced place still looks like an empty baseplate in Edit.** Rojo syncs code; `MapService`
    builds the map at runtime. Check the Explorer, not the viewport. CLAUDE.md carries the Command
    Bar line for building it in Edit.
  * **Rojo project files reject unknown keys.** A `"//"` comment key is a parse error, not a
    comment. Explanations go in CLAUDE.md.
  * The place is `Steal a Seed`, placeId `114075467877655`, and it was an empty baseplate when
    this session found it. A test map was built into it and removed again; `HttpEnabled` was toggled
    on for the compile checks and set back to false.
