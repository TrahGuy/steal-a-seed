# Steal The Artifact — Roblox Place Project

Multiplayer PvP extraction / collection simulator. Rojo 7.6.1, synced to Roblox Studio.

Read [KB/HANDOFF.md](KB/HANDOFF.md) at the start of every session and update it before ending one.
[KB/BLUEPRINT.md](KB/BLUEPRINT.md) is the design source of truth — the game's direction, not its code.

## Rojo port: 34874 — NOT the default

```
rojo serve --port 34874
```

**This is not a preference.** Three projects live on this machine and Rojo defaults all of them to
34872. On 2026-08-18 that cost a full session: `D:\KAPE\Tetris Arena` was serving, the Cloud Cafe
Studio was connected to it, and Rojo cheerfully synced BlockArena's 41 scripts into the cafe place
while the cafe's own disk edits reached nothing. Whichever Studio connects last wins and neither
side says a word.

| project | port |
| --- | --- |
| Tetris Arena / BlockArena | 34872 |
| Cloud Cafe Tycoon | 34873 |
| **Steal The Artifact** | **34874** |

Check in five seconds: `curl -s localhost:34874/api/rojo` names the project it is serving.

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
  ReplicatedStorage/ArtifactGame/
    Shared/GameConfig.luau      names, capacity, map geometry, remotes, save
    Shared/Types.luau           shared type vocabulary
    Shared/ArtifactData.luau    artifacts, odds, carry, economy
    Shared/ZoneData.luau        zone geometry and pedestal layout
    Remotes/                    created at runtime by ServerMain
  ServerScriptService/ArtifactGameServer/
    ServerMain.server.luau      bootstrap: Init() all, then Start() all
    MapService.luau             builds the whole map from code
    SaveService.luau            the only DataStore caller
    PlayerDataService.luau      owns every profile
    BaseService.luau            base ownership + spawning
    EconomyService.luau         the only coin faucet
  StarterPlayer/StarterPlayerScripts/
    MainHUD.client.luau
```

## Rules

From the blueprint, plus what this repo has learned:

1. **Never rebuild an existing system.** Check the repo before adding code.
2. **Adding a service is dropping a `*Service.luau` file in `ArtifactGameServer`.** ServerMain finds
   it, orders it by `Priority`, runs `Init()` then `Start()`. No registry to update.
3. **The server owns economy and ownership.** A client never picks, claims or pays.
4. **Validate every RemoteEvent argument.** The sender is engine-stamped and cannot be forged; every
   other argument came off the wire and is a lie until checked.
5. **Nothing is placed by hand.** The map, the HUD, every instance is built in code. Both
   predecessor projects on this machine still carry "the map is not in version control" as an open
   item; this one never will.
6. **One faucet.** Coins mint in `EconomyService.AwardArtifact` and nowhere else.
7. **Numbers live in data files.** Artifact values and odds in `ArtifactData`, zone geometry in
   `ZoneData`. `GameConfig` holds names and structure, never balance.
8. **Mobile first.** Blocky studded plastic, low part counts, no per-frame allocation.
9. **`--!strict` on every file.**
10. **Scripts must be safe to re-run.** `MapService` destroys and rebuilds rather than patching.

## Toolchain

- Rojo: `C:\Users\Maykel\AppData\Local\Microsoft\WinGet\Packages\Rojo.Rojo_Microsoft.Winget.Source_8wekyb3d8bbwe\rojo.exe` (on PATH)
- No Node.js on this machine. The npm package named `rojo` is unrelated — do not use it.
- Build a place file: `rojo build -o build/StealTheArtifact.rbxlx`

### Checking Luau syntax without a Play session

`start_stop_play` over MCP is unreliable on this machine. To compile-check a file without running it:
serve the repo (`python -m http.server 8731`), then in Studio Edit fetch it with `HttpService` and
require it wrapped in `local function __check() ... end return true`. The body compiles; nothing runs.
This is the only way to check a `.server` script without its side effects firing in the Edit datamodel.
