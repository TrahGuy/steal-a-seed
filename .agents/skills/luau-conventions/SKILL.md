---
name: luau-conventions
description: Steal a Seed's Luau and tooling rules - strict mode, server authority, remote validation, the single cash faucet, where numbers live, the map-is-code contract, the Rojo place pin on port 34872, and how to compile-check without a Play session. Use when writing or editing Luau, adding a service, touching remotes, economy, MapService, or running Rojo.
---

# Luau conventions

The full reasoning is in `AGENTS.md` and `KB/HANDOFF.md`. This is the operative set.

## Code

1. **`--!strict` on every file.**
2. **Scripts must be safe to re-run.** Destroy and rebuild rather than patching - `MapService.Init()`
   destroys any previous `SeedMap` before building, which is what makes it usable for tuning.
3. **Never rebuild an existing system.** Check the repo first. PlantService, PlotService,
   EconomyService, CarryService, MapService and SaveService all exist.
4. **Adding a service is dropping a `*Service.luau` in `src/ServerScriptService/SeedGameServer/`.**
   ServerMain finds it, orders by `Priority`, runs `Init()` then `Start()`. No registry to update.
   `CreatureModel`, `ParentModel`, `MapDecor`, `HubFairy` and `ProfileSchema` are deliberately not
   `*Service` - no lifecycle.
5. Prefer the existing module layout: shared under `src/ReplicatedStorage/SeedGame/Shared`, server
   under `src/ServerScriptService/SeedGameServer`, client under
   `src/StarterPlayer/StarterPlayerScripts`.

## Authority

- **The server owns economy and ownership.** A client never picks, claims or pays.
- **Validate every RemoteEvent argument.** The sender is engine-stamped and cannot be forged; every
  other argument came off the wire and is a lie until checked.
- **One faucet.** Cash mints in `EconomyService` and nowhere else. Speed mints in
  `TreadmillService` and nowhere else.
- Remotes are created at runtime by `ServerMain` under `SeedGame/Remotes`.

## Where numbers live

- Balance in `SeedData` (plants, weight, growth, size) and `BiomeData` (biome content).
- `GameConfig` holds **names, structure, the speed curve and save config - never balance.**
- Prefer one definition over two: `SeedData.GripForward` exists because CarryService welds with it
  and CarryPose aims the arms with it, and two copies of "how far in front" is a bug in a coat.

## The map is code

- **Nothing is placed by hand.** The map, the HUD, every instance is built in code.
- `MapService` marks the map folder `Archivable = false`, so it cannot reach the `.rbxl` and cannot
  be cloned into a Play session. You no longer have to delete `Workspace.SeedMap` before saving -
  leave it where it is.
- Preview in Edit from the Command Bar:
  `require(game.ServerScriptService.SeedGameServer.MapService).Init()`
- The Studio plugin at `tools/studio-plugin/SeedMapBuilder.server.lua` rebuilds the map whenever it
  is missing in Edit. Installed into `%LOCALAPPDATA%\Roblox\Plugins\`; restart Studio to pick up
  changes.
- **Nests are Play-only** and deliberately not built by the button - `NestService` raises Humanoids
  that would wander an Edit session forever.

## Rojo

```
rojo serve --port 34872
curl -s localhost:34872/api/rojo      # names the project and the place it will accept
```

- **The guard is the place pin, not the port.** `default.project.json` carries
  `servePlaceIds: [114075467877655]`, so the plugin refuses to sync this project into any place that
  is not *Steal a Seed*.
- Three projects on this machine default to 34872. Cloud Cafe Tycoon is on 34873; Tetris Arena /
  BlockArena also wants 34872 and has **no pin**. Only one process can bind the port, so the risk is
  sequential: stop this server, start BlockArena's, and a Studio that auto-reconnects finds the
  wrong project. That is not hypothetical - it happened on 2026-08-18 and synced 41 BlockArena
  scripts into the cafe place while the cafe's own edits reached nothing.
- Check `curl` before assuming the right project is serving.
- Rojo is the **WinGet package on PATH**. There is no Node on this machine and the npm package named
  `rojo` is unrelated - do not use it.
- Build a place file: `rojo build -o build/StealASeed.rbxlx`.

## Checking syntax without a Play session

`start_stop_play` over MCP is unreliable on this machine. To compile-check a file without running
it: serve the repo (`python -m http.server 8731`), fetch it in Studio Edit with `HttpService`, and
`require` it wrapped in `local function __check() ... end return true`. The body compiles; nothing
runs. This is the only way to check a `.server` script without its side effects firing in the Edit
datamodel.

A block-balance check (opens vs ends, allowing for expression-`if`, which takes no `end`) catches an
unclosed block from splicing. It does not catch a typo inside an expression - say so rather than
claiming a file is verified.

## Performance

**Mobile first.** Blocky studded plastic, low part counts, no per-frame allocation. Where a client
already iterates every frame (PlantSway moves every planted model), push motion there via a
replicated attribute rather than sending CFrames from the server.

## Git

The checkout is shared. Inspect `git status` and recent commits before editing. One logical change
per commit; stage only files owned by the current task with `git add -- <paths>`, then commit with
what changed and why and push `main`. Preserve unrelated or in-progress work from other agents and
never sweep it into a commit with `git add -A`.
