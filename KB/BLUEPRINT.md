# Steal an Artifact — Master Blueprint

The project's design source of truth, as supplied by the owner on 2026-08-20. This file describes
the GAME. It is not a description of the code, and where the code has had to make a decision the
blueprint did not cover, that decision is recorded in [HANDOFF.md](HANDOFF.md) rather than by
editing this document.

---

## 1. Overview

**Genre:** multiplayer simulator / collection / PvP extraction / tycoon progression.

**Inspiration:** the simplicity of Steal An Egg and classic simulators. It must **not** become a
complicated RPG.

**The focus:** simple objective → high risk → reward → upgrade → repeat.

## 2. Core loop

```
Spawn → Explore Artifact Zone → Find Valuable Artifact → Carry Artifact
      → Escape Other Players → Return To Base → Display Artifact
      → Earn Coins → Upgrade Base → Find Better Artifacts
```

## 3. Design priorities, in order

1. Fun gameplay loop
2. Simple controls
3. Fast understanding
4. Multiplayer interaction
5. Replayability
6. Monetization potential

## 4. Visual style

Classic Roblox simulator. **Use:** studded surfaces, plastic materials, blocky geometry, low-poly
models, bright colours, simple shapes. **Avoid:** realistic textures, heavy meshes, photorealistic
environments, complex shaders. Target mobile-friendly performance.

## 5. Map

Small on purpose. 8 players initially, expandable.

```
              ARTIFACT ZONE
       BASE          BASE
BASE                         BASE
          SAFE SPAWN
BASE                         BASE
       BASE          BASE
              ARTIFACT ZONE
```

- **Spawn area** — initial spawn, tutorial, neutral zone; instructions and leaderboard.
- **Player bases** — one each: `SpawnPoint`, `ArtifactDisplay`, `CoinCollector`, `UpgradeArea`,
  `OwnerSign`, `ProtectionZone`.
- **Artifact zone** — pedestals, spawn points, rare locations, danger zones.

## 6. Systems

**Player data:** Coins, Level, Experience, ArtifactsCollected, ArtifactsOwned, BaseID, Inventory,
Equipment.

**Base claiming:** player joins → find available base → assign ownership → update sign → spawn.
Server controls owner id, access, display and upgrades. **Never trust the client.**

## 7. Artifacts

Rarity: Common, Uncommon, Rare, Epic, Legendary, Mythic, Secret.

| Rarity | Example | Value |
| --- | --- | --- |
| Common | Ancient Coin | 100 |
| Uncommon | Bronze Statue | 500 |
| Rare | Golden Mask | 5,000 |
| Epic | Pharaoh Relic | 25,000 |
| Legendary | Dragon Crown | 100,000 |
| Mythic | Void Crystal | 500,000 |
| Secret | Time Artifact | 5,000,000 |

**Carrying:** the player holds it, gets slower, appears on the map, and can be attacked. A loud
find is announced to the server.

**Extraction:** pick up → carry → avoid players → reach base → deposit → reward.

## 8. PvP (Phase 3)

Players can attack carriers, steal dropped artifacts, and defend their own. On death the artifact
drops and a nearby player can take it.

## 9. Economy and progression

Coins only, initially. Spent on upgrades, equipment, storage and base improvements.

- **Display capacity** — L1: 5 artifacts → L10: 100
- **Coin generator** — L1: 10/min → L10: 10,000/min
- **Security** — shield, alarm, trap

**Equipment:** Scanner (find nearby artifacts), Speed Boots, Shield (protect carried artifacts),
Grapple Tool (escape).

## 10. UI

Keep it simple.

```
Main HUD        💰 Coins  🏺 Artifacts  ⭐ Level
Carry UI        🏺 CARRYING / name / value / RETURN TO BASE
Upgrade UI      BASE UPGRADES / slots / level / cost / [UPGRADE]
Shop UI         Scanner 5,000 / Speed Boots 10,000 / Shield 25,000
```

## 11. Architecture

```
ReplicatedStorage/ArtifactGame/{Remotes, Shared/{GameConfig, ArtifactData, ZoneData}}
ServerScriptService/ArtifactGameServer/{ServerMain, PlayerDataService, BaseService,
                                        ArtifactService, EconomyService, SaveService}
ServerStorage/ArtifactAssets/{Artifacts, Tools, Buildings, Effects}
```

## 12. Phases

| Phase | Build | Done when |
| --- | --- | --- |
| **1 Foundation** | repo, structure, map, bases, spawning, base claiming, data | a player joins and receives a base |
| **2 Collection** | artifact spawning, interaction, carry, deposit, coin rewards | a player can collect and sell an artifact |
| **3 PvP theft** | attacks, dropping, stealing, notifications, protection zones | players can fight over artifacts |
| **4 Tycoon** | base upgrades, museum display, passive income, storage | players improve their base |
| **5 Expansion** | zones, artifacts, equipment, events, leaderboards, trading | — |

## 13. Development rules

You are the Lead Roblox Studio Architect. Build phase by phase.

1. Never rebuild existing systems.
2. Check the current repository before adding code.
3. Use modular Luau.
4. The server controls economy and ownership.
5. Validate every RemoteEvent.
6. Avoid unnecessary complexity.
7. Keep mobile performance in mind.
8. Use simple Roblox studded visuals.
9. Provide Command Bar installers where possible.
10. Explain every created object.
11. Make scripts safe to re-run.
12. Maintain compatibility with previous phases.

## 14. First playable target

```
Player joins → gets a base → walks to the artifact zone → finds an artifact
             → returns home → gets coins
```
