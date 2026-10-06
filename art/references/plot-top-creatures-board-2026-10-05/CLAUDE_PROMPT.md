# Claude prompt: a "top 2 creatures" board beside each plot's upgrade sign

You are the Claude session that works inside Roblox Studio for Podnappers (Steal a Seed), project
`D:\KAPE\Steal an Artifact`. Read `AGENTS.md` completely and the top of `KB/HANDOFF.md` before
editing. The checkout is shared and full of uncommitted work: preserve every unrelated change.

## What the owner wants

Beside every plot's UPGRADE PLOT sign, a board showing that plot's **two best plant-creatures**.
For each one it shows:
- the creature itself (its real model, the same look as MY PLANTS and the Bag);
- its **rarity** (the rarity word in its own colour; Mythic, Secret and Divine keep their RarityFX light);
- its **size** (the size word in its tier colour; TITAN/COLOSSAL in the wheel lettering; none for a Secret or unsized form);
- its **earnings per second**.

Also show the creature's name: the other surfaces all show it. Everyone sees every plot's board; it
shows that plot OWNER's creatures.

## Where things already are (start here, don't reinvent)

- **The upgrade sign:** `MapService` builds it beside each plot's gate with
  `MillModel.BuildSign(GameConfig.plotSignBase(cf, GameConfig.StartingPlotTier), plots)`. It is named
  `PlotSign%02d`, tagged `GameConfig.Tags.PlotSign`, carries attribute `PlotId`, and is parented to
  `plots` (not the plot), because `ResizePlot` clears the plot's children. `PlotUpgradeService` paints it.
  Build the board the same way: parented to `plots`, placed once off the gate, never moving with plot level.
- **The words:** `PlantLabel.content(speciesId, tier, multiplier)` already gives rarity word and colour,
  name, size word, colour and style, and income per second at the OWNER's rate
  (`SeedData.IncomePerSecond` × `GameConfig.gardenIncomeMultiplier(plot)`). This is exactly what the
  overhead labels show. Use it, so the board and the labels can never disagree.
- **The picture:** `ItemArt.builder` + `UIKit.itemPreview`, the same as MY PLANTS and the Bag.
- **Planted creatures:** these are tagged `GameConfig.Tags.Planted`; PlantUI reads `SpeciesId` and tier
  off them. Ties should break the way EQUIP BEST orders things (`GardenPlan.before`).

## Rules for the design

1. **Ranking.** Grown creatures planted in that plot, highest income per second first; equal incomes
   follow `GardenPlan.before`. Pods and plants still growing don't count. With one creature, show it
   and a quiet empty slot; with none, show a friendly empty state. On an unowned plot, hide the board
   or show a neutral "no owner" face (pick one and say which).
2. **The truth is the server's.** `Workspace.StreamingEnabled` is on, so a client far from a plot may
   not have its planted models. The server works out each plot's top two and publishes plain
   attributes on the board (species id, tier, placement id, for each slot). It republishes only when
   that plot's plants, hatches, sells, pick-ups, upgrades or boosts change. No per-frame loop, no
   polling. The client draws from those attributes plus the plot's published multiplier, through
   `PlantLabel.content`.
3. **Placement.** Right beside the upgrade sign, on the side that keeps paths clear. It must stay clear
   of the gate, the walkway, the mill and its belt, every fence a plot of ANY level builds, and every
   prompt's ground (see the hub-deck prompt map rule in `AGENTS.md`/the handoff). Derive the spot from
   `plotSignBase` / the gate CFrame in `GameConfig`, never hand-placed numbers per plot. Add a spec
   that checks it the way `MillPlacementSpec` checks the mill.
4. **Look.** Match the global UI pass: a white studded header with a white ink-outlined title (for
   example "TOP CREATURES"), and each creature on its rarity's studded colour (`UIKit.studCard`,
   `BagLook.StudsByRarity`; a Common on the plain card). Use dark keylines and readable outlined words
   (Shop / MY PLANTS / Bag rules). It must be readable from a few studs away on a phone-size screen.
   Don't invent new rarity colours or meanings.
5. **Performance.** Two ViewportFrames per plot across every plot adds up. Build or activate a board's
   previews only for plots near the camera, and pause or free them when far. `LightInfluence` 0 so
   night doesn't black it out. Reduced motion stills RarityFX.
6. **Assets.** Native UI only, no new uploads. Never invent asset ids; reuse approved ones
   (`UIKit.studCard` textures, the plants' own models).

## Verify (report honestly)

- Compile and do the unknown-global scan on every touched file.
- Add specs for:
  - the ranking (ties, fewer than two, pods excluded);
  - the words matching `PlantLabel.content`;
  - placement at every plot level.
- Run the related existing specs: `MillPlacementSpec`, `PlantLabelSpec`, `CompactMenusSpec`,
  `InventorySpec`, `HudLayoutSpec`.
- At most one or two focused automated Plays, ONLY by AGENTS.md's throwaway-store procedure:
  `test_store_on` in Edit, `store_guard` SAFE right before the start, confirm the
  `STUDIO TEST STORE` Ready line, and finish with the marker removed, test files deleted and the probe at
  0 differ / 0 ZZ. Never touch the real store.
- In Play:
  - the board updates when a better creature is planted and when one is picked up;
  - capture a plot's board in day and at night.
- Capture desktop; say plainly that no phone or emulator was used, unless the owner turns the emulator on.
- Don't foreground, resize or restore the owner's Studio window. Don't stop a Play you didn't start.

## Deliver

- Update `KB/HANDOFF.md` (top entry): what changed, files, verified and not verified, and any choice
  you made for the owner (title text, unowned-plot face, empty state).
- No gameplay, economy, price or save changes.
- **Do not commit, push or publish.**
