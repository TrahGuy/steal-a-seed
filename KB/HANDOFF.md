# Steal a Seed — Session Handoff

## The shop sells: eleven Developer Products and the x2 Money pass are wired — 2026-09-11 (CLAUDE)

### What (`GameConfig.Store.Items`)

  * `x2money`: `pass = 1975418369`, `robux = 79`.
  * Cash: cash1 3712092213 @ 19, cash2 3712092272 @ 39, cash3 3712092458 @ 89,
    cash4 3712092533 @ 179, cash5 3712092621 @ 279.
  * Speed: speed1 3712094350 @ 29, speed2 3712094432 @ 79, speed3 3712091968 @ 149,
    speed4 3712092016 @ 299, speed5 3712092058 @ 599, speed6 3712092103 @ 799.
    speed3 and speed4 came in a follow-up: the first brief left them at 0, then the
    owner sent the full list, and every other row already matched it.
  * pod1-3 stay at `product = 0` and read SOON.
  * The Store header comment and the pass comment now say what is live, and that
    `robux` is only what a tile prints -- Roblox charges the Dashboard price.

### Prices: the owner's list, not what the lookup returned

`MarketplaceService:GetProductInfo`, run in Studio on the owner's account, confirmed
every id exists, is for sale and is the item its row sells -- "Pocket Cash ($24K)"
for cash1, "Speed Nova (+1B Speed)" for speed6, "Permanent 2× Earn" for the pass.
But for every product it returned about 0.4x of the brief's price:

    cash1 8 / 19    cash2 19 / 39    cash3 39 / 89    cash4 75 / 179    cash5 115 / 279
    speed1 12 / 29  speed2 35 / 79   speed3 59 / 149  speed4 119 / 299
    speed5 239 / 599  speed6 319 / 799

That was taken to be regional pricing on the owner's account, and the owner chose
the brief's prices for the tiles. The brief gave the pass no price; GetProductInfo
returned 79 and the owner chose 79. If a Dashboard price changes, the number here
has to change with it, or the tile and the purchase prompt disagree.

### Verified

  * Every row checked against the owner's full list, straight from the file: id,
    price and amount match for all eleven products, the pass is unchanged, and no
    id appears twice. GetProductInfo: each of the eleven ids is for sale under
    exactly the name on the owner's list.
  * Fresh-required in Edit: 12 live ids (11 products and the pass), 3 at 0, no
    duplicates; StoreService indexed 11 live / 3 pending with no DUPLICATE warning.
  * Play boot: `StoreService Ready. 11 product(s) live, 3 still waiting for an id.`
    and `PassService Ready. 1 live pass(es), 0 pending`, with no DUPLICATE warning.
    The shop showed 12 prices (79; 29, 79, 149, 299, 599, 799; 19, 39, 89, 179,
    279) and 3 SOON pills, the pods.
  * The owner's account owns x2money (`PassService: nicnicniccoal owns "x2money"`,
    CashMultiplier 2), so the owner's own plant income is doubled from here on.
  * All 17 specs pass; `rojo build` is clean.

### On the Dashboard but not in the game

`GetDeveloperProductsAsync` lists 14 products. Besides the eleven above:

  * `3712091836` "Speed Sprout (+150K Speed)" and `3712091929` "Speed Boost (+1M
    Speed" -- earlier copies of speed1 and speed2. Nothing in the game sells them.
  * `3712092145` "Permanent 2× Plant Income" -- a Developer Product named like the
    pass, listed with no price. The shop sells the Game Pass `1975418369` instead.

### Not verified

  * A purchase. No prompt was opened and nothing was bought, so ProcessReceipt has
    not handled a real product in any test run here.

## Settings: music, sound effects and reduced effects — ADDED 2026-09-11 (CLAUDE)

### What

  * `SettingsUI.client.luau`: a bare gear on the LEFT rail under Shop (12, 124,
    50 x 50) opening a centred `UIKit.modal` with three rows -- MUSIC and SOUND FX,
    each a slider and an ON/OFF, and REDUCED FX, an ON/OFF. Every target is at
    least 44 px: slider bands 44 tall, toggles 64 x 44, the modal's close 44. It
    joins the OpenPanel handshake. A keyboard or gamepad nudges a selected slider
    by 10%.
  * Icon: `art/ui/rail-icons/settings-128.png`, uploaded as
    `rbxassetid://104265736892158`, is `GameConfig.Rail.SettingsIcon`. If it ever
    fails to load, SettingsUI draws a gear out of frames instead.
  * `SoundKit`: a per-bus player level and mute (`setLevel`, `level`), multiplied
    into the bus rather than written over it. The Music bus's three writers --
    Music.client's join fade (`fadeMusic`), the chase duck and the panel -- all aim
    at `SoundKit.musicLevel()`; a level written straight onto the group would have
    been undone by the next chase.
  * SOUND FX moves Chase, UI and World together. Server one-shots from
    `SoundKit.emit` are tagged `SeedServerCue` with their bus and unbaked volume,
    and each client routes them through its own bus (`routeServerCue`, bound in
    `SoundKit.preload`). AlertUI's four alarm Sounds now ride the Chase bus; they
    were on no bus at all.
  * REDUCED FX writes `SeedAfterimageQuality = "Off"`. Switching it back restores
    the value that was there, or the device default ("Reduced" on a phone, "Full"
    otherwise). Not "High", as the brief suggested: SpeedFX and PlantAura accept
    only Full / Reduced / Off and ignore anything else, so "High" would have left
    every effect off until a rejoin.
  * Nothing is saved: the settings last for the session. No remote, no profile
    field.

### Verified

  * `SoundLevelSpec` 28/28 -- levels, mutes, clamps, the Music target through the
    fade and the duck (checked by where the tween aims, because TweenService does
    not advance in Edit), server-cue routing, and emit's server-side tagging.
  * Play, one client:
      - the gear loaded (`IsLoaded`) at (12, 124); in that slot nothing else is on
        screen but the alarm's transparent vignette frame.
      - open: rows 52 tall, toggles 64 x 44, slider bands 195 x 44, close 44 x 44.
      - the music toggle unmuted a muted bed (0 -> 0.32); dragging its slider to a
        quarter gave 0.080 and "25%".
      - SOUND FX at 50% set Chase, UI and World to 0.5; its toggle took all three
        to 0 and back to 0.5 without touching the music.
      - REDUCED FX: attribute "Off" and SpeedFX removed its streak trails from the
        character; pressed again, "Full" and the trails were back.
      - with the Music slider selected, Left gave 90% (0.288) and Right twice
        100%, the selection staying on the slider.
      - the Index button closed Settings (OpenPanel "Index"); the X closed it.
      - a server `emit` of ChaseStep reached the client tagged and was routed to
        SeedWorld at its base 0.5; the alarm's Sounds were on SeedChase.
  * Screenshot checked: the gear under Shop, and the panel's title gear, close
    and three rows.
  * The save read back after the three Play sessions: Held 2, Plants 2, lock
    released.

### Notes

  * FIXED the same day: the icon check asked `PreloadAsync` about the bare id
    string, which answered Failure for this icon AND for the Bag's while both
    ImageLabels had loaded -- so the frame gear was drawn over the real artwork.
    It now preloads the ImageLabel and trusts its own `IsLoaded`, with 10 s of
    patience. Play: the rail and title icons loaded, no fallback and no warning;
    a label on a missing id stayed `IsLoaded = false`, so a real failure still
    falls back to the drawn gear.
  * The first nudge was a ContextActionService binding. With a GUI object selected
    the engine's navigation took the arrow first and the binding never fired
    (measured), so it listens on UserInputService, and the slider is its own left
    and right neighbour.
  * The Edit datamodel's SoundService already held a `SeedWorld` SoundGroup when
    this session started. Edit reports IsClient true, so any spec that reaches a
    SoundKit bus builds one there. Harmless -- clients reuse it by name.
    SoundLevelSpec removes only what it creates.
  * The music was found muted once during the Play test, with nothing in this
    code that mutes on its own; the cursor was moving between test steps, so it
    was most likely set by hand in the same session.

### Not verified

  * A real touch device, and hearing the levels (MCP cannot listen).
  * Two players; the buses are client-local by design.

## The player list shows Speed and Cash — ADDED 2026-09-11 (CLAUDE)

### What (`PlayerDataService.luau`)

  * On profile load every Player gets a `leaderstats` Folder holding two
    StringValues, in this order: `Speed` = `GameConfig.compact(profile.Speed)` and
    `Cash` = `"$" .. GameConfig.compact(profile.Cash)`. It is built and filled
    before it is parented, and it replaces any older folder, so a re-run never
    doubles the columns.
  * `AddCash` and `AddSpeed` republish through `PlayerDataService.PublishStats`,
    which writes a value only when its spelling changes -- an unchanged string is
    never written, so nothing replicates for it.
  * Leaving destroys the folder and forgets it; `Init` clears any it holds.
  * A temporary profile (DataStores unreachable) shows its numbers too. A player
    who leaves during the load, or is kicked by a failed one, gets no columns.
  * Seams for the spec: `MountStats(holder, profile)`, `PublishStats(player)`,
    and `Join` / `Leave`, the two handlers Start connects.

### Verified

  * `LeaderstatsSpec` 28/28 -- the real join and leave handlers and the real
    AddCash / AddSpeed, with SaveService and PlotService stubbed and a stand-in
    player: order and spelling (1.25T, $3.43B), AddCash to $3.44B, a gain too
    small to respell writes nothing, AddSpeed to 1.26T, a clamp to $0, NaN
    refused, no columns without a profile, a temporary profile, a mid-load leave,
    a failed load, the folder destroyed on leave, a stale folder replaced.
  * Play, one client: after load `leaderstats` held Speed = 107B then Cash =
    $3.44B, matching the loaded profile and the corner HUD. A debug AddCash of +1B
    and then -1B moved Cash to $4.44B and back to $3.44B with exactly two Changed
    events. The save read back afterwards carries no trace of the +1B; Cash is up
    only by the plants' own income.

### Not verified

  * How Roblox's player list orders string columns, and a second player.

## Plants that stream in late sway; a plant that streams out is measured again — FIXED 2026-09-11 (CLAUDE)

This place runs StreamingEnabled. A plant on a plot outside streaming range
reaches a client as an empty Model -- container, tag and attributes, no parts,
PrimaryPart nil -- and its parts follow only when the player comes near.
`PlantSway.remember` waited five seconds for the PrimaryPart and then abandoned
the model for the rest of the session, so any garden that streamed in late
stood frozen.

### Fix (`PlantSway.client.luau`)

  * No deadline. Each Planted model is watched for as long as it is tagged and in
    the game. Its `PrimaryPart` arriving builds the sway, once the part count has
    settled (at most ten 0.15 s beats). Its `PrimaryPart` leaving forgets it, so
    the next arrival measures the parts that are there rather than animating
    references to parts that left. Property signals, no polling.
  * `release` (tag removed, or the model leaving the game) drops the sway and the
    watch together. `forget` no longer pivots a model that has no PrimaryPart.
  * The watchers are disconnected with everything else when the script re-runs.

### Verified

  * Play, one client, with a clone of the owner's grown Nubkin tagged Planted
    2,600 studs off the map on an anchored platform. The client held the empty
    container (PrimaryPart nil, 0 parts) until the player went there.
      - BEFORE the change, teleported to it over a minute after the tag: the
        parts streamed in within 0.1 s and the plant never moved -- 0.000 studs
        and 0.00 degrees of pivot change over 3 s.
      - AFTER, the same test 84 s after the tag: it swayed (25.6 degrees of pivot
        change) with its pupils, lids, leaves and stem animating.
  * A clone near the player had all 33 parts moved to ServerStorage and back:
    still animating afterwards, eyes included. That is not a real stream-out --
    measured, the client kept the very same Part instances -- so the stream-out
    branch is covered by reading, not by a live test.
  * All specs pass. PlantSway itself has no spec; it is a LocalScript.

### Not verified

  * A real stream-OUT and back in: StreamOutBehavior cannot be read or set from
    a script here, so it could not be forced.
  * Two players watching one late-streamed garden.

## Taking a pod puts the held plant away — FIXED 2026-09-11 (CLAUDE)

Holding a plant while taking a pod drew both at once: the raid pod in both arms
and the plant Tool through it. Only the pod may be in the hands during a carry.

### Fix (`CarryService.luau`, `LoadoutUI.client.luau`)

  * `TryTake`, once the pod is attached, moves every plant Tool (a Tool with a
    `SpeciesId`) from the Character to the Backpack -- `CarryService.PutPlantsAway`.
    Bats and traps stay where they are.
  * While a pod is carried, a plant Tool that lands in the Character is put back a
    frame later (a `ChildAdded` watch in the per-body watcher; seam
    `CarryService.WatchBody`).
  * The hotbar refuses a plant while `CarryingSpecies` is set: Denied cue and no
    equip, so the player never watches it bounce.

### Verified

  * `CarryHandsSpec` 16/16 -- the real TryTake, Drop, SpawnLoose and body watcher
    with a stand-in player: put away on take, an equip while carrying bounced, a
    bat untouched, plants equip again after Drop, two plants and a bat, no Backpack.
  * Play, one client, on the road at z = -205 with a debug nubkin t1 pod:
      - holding Nubkin (6 kg), take: carrying, the raid pod in both arms, the
        plant in the Backpack, no plant Tool in the hands.
      - `Humanoid:EquipTool(plant)` while carrying: back in the Backpack within
        0.1 s and still there at 1.0 s; the carry intact.
      - hotbar keys 3 and 4 (both plants) while carrying: no plant in the hands,
        both in the Backpack, still carrying, and the Denied cue built. Key 3 with
        empty arms, earlier in the same session, unequipped the plant in hand --
        so the keys were reaching the game.
      - after `DropCarry`, an equipped plant stays equipped.
  * A take INSIDE TheField banks at once (the red line is already behind you), so
    the first attempt, at the plot, put a real test pod ("???", nubkin t1) in the
    owner's bag. It was destroyed in the same session. The save read back after
    the Play sessions: Held 2 (nubkin t6 and t1, both hatched), Plants 2, lock
    released.

### Not verified

  * Two players: what another client sees of the hands.

## Held plants survive death, reset and LoadCharacter; the plot teleport works — FIXED 2026-09-11 (CLAUDE)

### Respawn wiped the bag (P0)

After `9a007b6`, dying still erased held plants. A death, reset or `LoadCharacter`
destroys the Character and the Backpack with every Tool in them, and the engine
hands over a new, empty Backpack. Its `ChildAdded`, and the new body's
`CharacterAdded`, both called `requestSync` while the gate was still open, so the
snapshot found nothing and `SetHeld` wrote nothing over the save.

### Fix (`CarryService.luau`, `NestService.luau`)

  * The gate is ARMED for one Backpack instance and one Character instance
    (`armed[player]`) -- the pair the last rebuild put the plants into. `syncHeld`
    refuses whenever either differs from what the player has now, so the order
    the engine tears things down in, and signal deferral, no longer matter.
  * `rebuildHeld` replaces `restoreHeld` and runs on join AND on every new
    Backpack and every new body. It counts the plants already in the Backpack and
    the hands (by id, tier, hatched) and builds only the saved rows that are
    missing -- nothing is built twice. A call during a pass asks for one more pass.
  * `CharacterRemoving` disarms. `CarryService.FreezeHeld` (a last snapshot, then
    disarm) is on the carry bridge, and NestService calls it right before its own
    `LoadCharacter`.
  * Consumption while alive -- planting, selling, ClearBag -- records as before,
    so a plant sold before a death does not come back after it.
  * Seams: `CarryService.WatchHeld`, `RestoreHeld` (now the rebuild), `FreezeHeld`,
    and `IsHeldRestored` (armed for the current pair).

### Plot teleport (`DebugService.luau`)

`Teleport {where = "plot"}` passed the Player to `PlotService.SpawnCFrameFor(plot:
Model)` and threw `GetPivot is not a valid member of Player`, so it never moved
anyone. It now resolves `PlotService.PlotOf(player)` first, and answers
"Teleport: no plot" when there is none. `DebugService.RunAction(player, action,
payload)` runs a handler without the remote, for specs (server-only).

### Verified

  * `HeldRestoreSpec` 31/31 -- the five join scenarios plus respawns played
    through the real watchers with real signals and real instances: the engine's
    order with a plant in hand; the new Backpack announced first; CharacterRemoving
    never heard; Tools that survive (no duplicates); partial survival; a sold plant
    not coming back; the FreezeHeld path; dying during the join load. A stray sync
    after every teardown step never wrote fewer rows.
  * `DebugTeleportSpec` 8/8, against the real `SpawnCFrameFor`.
  * All 14 specs pass; changed files compile through loadstring; `git diff
    --check` and `rojo build` clean.
  * Play, one client, with three test plants given through the real builders
    (two pods in the bag, a hatched Nubkin in hand):
      - reset (`Health = 0`): respawned after 3.5 s with a new body and a new
        Backpack; all three back as new Tools; log `restored 3 held plant(s)`.
      - `LoadCharacter()` while holding one: new body and Backpack; all three
        back; no old instances left; the same log line.
      - the test plants were then removed: 0 plants left, both weapons intact.
        Read back from the DataStore after Play stopped: current profile Held 0,
        Plants 2, lock released; the newest version (04:27:48 UTC, the leave
        save) also Held 0 -- the owner's save is exactly as it was before the test.
      - DebugCommand `Teleport plot` from the client: "at your plot", moved 129.8
        studs onto the owner's own Plot_01 spawn pad (horizontal offset 0.00).

### Not verified, and notes

  * NestService's own `LoadCharacter` (a thrown body that lost its root) was not
    reproduced live; its FreezeHeld call is covered by the spec, and the direct
    `LoadCharacter` test covers the guard without it.
  * A rebuilt HATCHED plant comes back equipped, because `restoreOne` uses
    `GiveHatched`, which equips when the hands are free. That is pre-existing and
    also happens on join.
  * A store purchase that lands in the old Backpack in the instant before a
    respawn could still be lost. Pre-existing; not addressed here.
  * Two players were not tested.

## Held plants were overwritten when a profile loaded late — FIXED 2026-09-11 (CLAUDE)

### What was lost, and the evidence

Found while verifying the Bag. The owner's bag held nine plants at the start of
the session (nubkin t1 x5, t5 x2, t3 x1, novaorb t4); every later Play session
loaded none. The owner confirmed they did not sell or plant them. Read-only
DataStore version history (`StealASeed_v1`, key `p_<userId>`):

```
02:48:10 UTC  Held 9  Plants 2  Cash 3,427,039,827   release save, end of the pre-change inspection
03:35:30 UTC  Held 0  Plants 2  Cash 3,433,356,351   a later session's claim
```

The next session logged `loaded (ok): cash 3427039827` -- exactly the 02:48 value
-- and `PlantService: restored 2 plant(s)`, but no CarryService "restored held
plant(s)" line. In a later session the first profile write landed 38 s after the
server started.

### Cause

`CarryService.restoreHeld` waited at most 20 s for the profile, then returned
without a word. PlantService waits 30 s, which is why the garden came back and the
bag did not. When the profile did arrive, the next Backpack change (the bat and
trap Tools are handed out on load) ran `syncHeld`, which snapshotted a Backpack
with no plants in it, and `SetHeld` wrote `{}` over the save. Pre-existing; the
Bag change did not touch this path.

### Fix (`CarryService.luau`)

  * `syncHeld` refuses to write until that player's restore has run (the
    `heldRestored` gate).
  * `restoreHeld` waits for the profile and for a Backpack as long as the player
    stays. `CarryService.HeldRestorePatience` (600 s) is only a backstop, and if
    it ever runs out the gate stays closed, so that session cannot overwrite the
    saved bag.
  * Once per player. It opens the gate with one snapshot, which also records
    anything banked or bought while the profile was loading. The gate is cleared
    on leave.
  * Exposed for the spec: `CarryService.RestoreHeld`, `CarryService.IsHeldRestored`.

### Verified

`HeldRestoreSpec` 12/12 -- the real CarryService with PlayerDataService's timing
stubbed and real Backpacks: a slow load with the Backpack changing wrote nothing,
then rebuilt all nine and every write carried nine rows; patience running out
left the gate closed and the save untouched; a repeated call built nothing twice;
an empty save opened the gate and the next banked plant was recorded; a player
leaving mid-load got no restore and no write. All 13 specs pass; compile, `git
diff --check`, `rojo build` clean.

Live smoke, one Play session with the gate in place: booted normally, `loaded
(ok)`, `PlantService: restored 2 plant(s)`, the equipped bat and trap handed out,
and no CarryService warning or error. That load was fast (the profile was in
before the player was seen), so it did not exercise the late-load case -- the
spec is what covers that.

### Not done

  * The owner chose NOT to restore the nine plants. They are still in the
    02:48:10 UTC DataStore version if that changes.
  * The live race was not reproduced: the owner's saved bag is now empty, and
    nothing was written to it to stage one.
  * Respawn behaviour is unchanged and was not investigated here.

## The Bag: lighter cards, a plant information panel, and room for the hotbar — 2026-09-11 (CLAUDE)

Brief: polish the existing Bag and add a compact information panel for the
selected plant, without rebuilding the inventory or adding a controller.

### Files

  * `LoadoutUI.client.luau` -- still the one controller; restyled and extended.
  * `Shared/UIKit.luau` -- new `UIKit.cardPop`: a lift under a mouse, a press
    under a thumb.
  * `Shared/PlantInfo.luau` -- new, pure: what the panel says about one Tool.
  * `tools/tests/PlantInfoSpec.luau` -- new.

### Layout, measured before and after

Before, at 1169x609: a centred 520x452 panel whose bottom sat **33 px under the
hotbar** (the last row's buttons were behind the strip), a left-aligned grid with
24-34 px of dead tray on the right, and opaque brown cards. On a 735x413 phone
the strip covered most of a card row.

`layoutBag` now fits the panel into space that is actually free: between the
rails (right of Index/Shop, left of the Garden/Bag buttons and the BAT/TRAP
column), 8 px from the top and 8 px above the hotbar. If that gap is under
420 px (a portrait phone) it drops below the rail band instead. It is centred
on the screen whenever a symmetric panel still clears both rails at >= 600 px,
otherwise in the free band. Max 780x600. Under 380 px of shell height the tabs
move onto the title row.

The plants tab puts the information column beside the grid (184-236 px) while
two card columns and the column fit, and a 118 px lower sheet under the grid
otherwise. The equipment tab gives the tray the whole body. Cards are a fixed
104x158 (76 preview, 26 name, 44 px action strip); widths change the column
count, never the card; the grid is centred.

| screen | panel | vs hotbar | arrangement |
| --- | --- | --- | --- |
| 1169x609 desktop, 10 slots | 780x449, centre 584.0 (screen 584.5) | 12 px clear | column 236, 4 card columns, gaps 29/29 |
| 735x413 emulated phone, 5 slots | 501x253 at (149,7) | 11 px clear | tabs on title row, 2 columns, compact 184 column |

### Cards

Translucent plate (0.22) on the tray, black keyline kept, soft shadow, lip and
preview well. Grown plants stand on the established biome art
(`GameConfig.Card.Art` at `ArtTint`), pods keep the plain well as in the Garden.
The preview is the same `UIKit.itemPreview` -- framed once, never rotated. Names
wear the tier colour (the Garden's convention) and fall back to a two-line
ellipsis when even 9 pt cannot hold them (`fitName`). Tabs carry counts.

### Interaction contract

  * **Plant card body** selects it: gold ring, panel shows that exact Tool.
    Selecting never equips, moves, clones or consumes anything.
  * **Plant card strip** (44 px, `HOLD` / `IN HAND`) is the old whole-card
    verb, `holdTool`, and also selects that card.
  * **Weapon cards**: body or strip equips, exactly as before. No selection, no
    panel, no drag, no double-click.
  * Dragging a plant card past 8 px is the unchanged hotbar assignment.
  * A tap is a press that stayed within 10 px and did not scroll the grid, so a
    scroll or camera drag never selects or equips.
  * Cleared by: an empty-tray tap, closing the Bag, switching tabs, and --
    re-tested against the rows on every draw -- the Tool being assigned,
    planted, sold or destroyed.
  * Identical plants now sort by key, then by the order the script first saw
    each Tool. The old tie on `tool.Name` was unstable: measured, equipping one
    Nubkin reshuffled the cards and a second HOLD press picked up a different
    copy. This also steadies hotbar auto-fill among duplicates.

### Income

`PlantInfo.Describe` -> `SeedData.IncomePerSecond(species, tier) *
GameConfig.cashMultiplier(player)`: the Garden's own figure for the player's own
plants. Sell is `SeedData.SellPrice`, pass-agnostic like the stall. A pod shows
only size and biome (`???`, "After it hatches"). No ids or tier numbers anywhere.

### Animation and performance

`UIKit.cardPop`: mouse hover 1.05 (strip 1.07, tabs 1.04, close 1.06) over
0.12 s Quad Out; touch press 0.98 (strip 0.95), released once a touch travels
10 px. One tween per property, cancelled before the next. `SeedAfterimageQuality
= "Off"` keeps scale at rest. `reset()` runs on hidden pooled cards and on close.
No RenderStepped, no loops; one panel instance; cards pooled.

### Verified in Play

Desktop and the emulated 735x413 phone, using 10 client-only fixture Tools
(never replicated or saved):

  * Hover: cell unmoved at 104x158, Face 109.2x165.9 centred, glow 0.45, no other
    card scaled; over the strip the card stays lifted and the pill pops to 1.07.
  * Panel values equal the canonical calls: Nubkin t5 `+$1.65K/s` / `$49.5K` /
    `Hotbar slot 8`; Supernovus t7 `+$66.5K/s` / `$2M`; a pod reads Unhatched pod /
    Dustbowl / ??? / Colossal / After it hatches / ??? / Hotbar slot 4.
  * Empty-tray tap cleared; scrolling the canvas 0 -> 179 selected nothing; a drag
    ending on the grid assigned nothing, left no ghost, hotbar Z back to 4.
  * HOLD then HOLD on one card equipped and put away the same Tool (after the
    sort fix).
  * Drag to slot 3: 10 -> 9 cards and the selection cleared; drag the slot back
    onto the grid: 9 -> 10, the card exactly once.
  * Close cleared; reopen -> one PlantInfo, pool still 10. Respawn -> one
    SeedLoadout, one SeedRail, one BagButton, pool 10.
  * Empty state (the real bag) and the Equipment tab (4 weapons, gaps 152/152,
    EQUIPPED rings) rendered. Weapons were hovered, not clicked: a click changes
    the saved loadout.
  * Phone: every row fits (widest value 94 px in 96), tab labels fit, strips 96x44.
  * `PlantInfoSpec` 45/45 over 350 grown combinations; the other 11 specs pass;
    changed files compile through loadstring; `git diff --check` and `rojo build`
    clean; console clean.

### Not tested

A physical phone; the portrait lower sheet (only landscape was emulated); a real
touch press (MCP drives a mouse); the hotbar double-click return through MCP --
its clicks land ~330 ms apart, past the untouched 0.30 s window, so the drag
return was used; weapon-card clicks; `SeedAfterimageQuality = "Off"`.

## Confiscating guardians leave 40% of pods behind, for good — 2026-09-11 (CLAUDE)

Brief: in Tanglemire, Emberroot and Starbloom a catch used to confiscate the pod
every time. Now the first confirmed catch of a pod rolls once: 40% the guardian
leaves it behind permanently, 60% the old confiscation / carry-home / deposit.
Greenhollow and Dustbowl are untouched (no confiscate profile, so their catch
returns before any roll).

### State transition

`GuardianCatch.Resolve` decides (pure); `CarryService.ResolveGuardianCatch`
applies it; NestService's `confiscateFrom` is the only caller, through the
carry bridge (which now carries `ResolveGuardianCatch` instead of `Confiscate`).

```
guardian already hauling   -> hauling      victim's pod not read, rolled or marked
nothing carried            -> none         plain throw
pod GuardianAbandoned      -> abandoned    NO roll; plain throw drops it again
roll <  LeaveBehindChance  -> left         pod marked for good; plain throw drops it
roll >= LeaveBehindChance  -> confiscated  unchanged haul path
```

One non-yielding call reads, rolls, marks or takes in a single resumption, so
two same-frame contacts cannot both roll or both take. `left`/`abandoned` return
false, so the unchanged throw sets PlatformStand and the ragdoll watcher makes
the one canonical `CarryService.Drop` -> one loose pod carrying the flag, and the
guardian walks home empty-handed. (NestService checks `nest.haul` before calling,
so `hauling` exists for the API and the spec.)

### Probability boundary

`GameConfig.Parent.Confiscate.LeaveBehindChance = 0.40`, asserted a number in
0..1. Server `Random:NextNumber()` in [0, 1); leave iff `roll < chance` (strict):
0.3999 leaves, 0.40 confiscates. `confiscateProfile` now returns tables only, so
that number can never be read as a biome profile.

### Attribute contract

`GameConfig.Attributes.GuardianAbandoned` (`"GuardianAbandoned"`): on the POD,
`true` or absent, never on a player. Unrelated to `keep` (lifetime).

  * Held record `guardianAbandoned`, carried like `fromNest`/`reservedFor`; TryTake
    reads it off the loose pod before destroying it.
  * Carried model: set on take and on `left` (inspection only).
  * Loose pod: `spawnLoose(..., abandoned)`; Drop (ragdoll and bat) and the
    attach-failure respawn pass it on; `CarryService.SpawnLoose(..., keep?, abandoned?)`.
  * Never on nest pods or deposited hauls, so a pod carried home and stolen
    again is a new attempt. Not on banked Tools: dropped at banking by design.
  * Abandoned pods still expire at 45 s and are cleared at dusk (WorldCycleService
    destroys every `SeedPod` regardless of attributes).

Hooks: `ResolveGuardianCatch(player, hauling, roll?)`;
`SetGuardianRollOverride(n | nil)`, [0, 1) only; DebugService
`ForceGuardianRoll {value = n}`, and `{}` clears it (Studio/owner gate).

### Verified

  * `GuardianConfiscateSpec` 88/88, Edit, fresh-require. Real TryTake /
    ResolveGuardianCatch / Drop / SpawnLoose with stand-in players on a fixture
    floor. Covers: the boundary; one counted draw per pod; a hauling guardian
    neither draws nor marks; leave -> exactly one flagged loose pod; re-pick by a
    second carrier keeps the flag and provokes the origin nest every time; catches
    at 0 / 0.3999 / 0.40 / 0.9999 on it all `abandoned`; a bat-style drop keeps the
    flag; confiscation leaves no loose pod; a deposited pod rolls afresh;
    same-frame double contact; an empty-handed catch; the override; a seeded
    20000-draw rate within 0.015 of 0.40.
  * The other ten specs pass unchanged (TutorialPod 263, Speed 332, StarbloomLimb 71,
    Cycle 31, BatSwing 93, BatClearance 939, Weapon 107, Plot 65, MillSign 8,
    Tutorial 93). The five changed modules are identical to disk in Studio and
    compile. `git diff --check` and `rojo build` are clean.
  * Play, ONE client, Tanglemire; a server sampler on guardian attributes plus
    the server log:
      - forced 0.1: take -> chase at 69 -> `keeps a 3 tier Bogbonnet: the guardian
        left it behind for good` / `left ... (left)`; exactly one loose pod
        (`GuardianAbandoned=true`, `FromNestId=Nest_tanglemire_01`); `Hauling`
        never set; guardian returning -> asleep.
      - re-take: carried model flagged; chase at 74 (+5 rage; seen 3 times);
        recatch logs `(abandoned)` with no new roll; one flagged loose pod
        again; guardian home empty-handed.
      - abandoned loose pod expired at +45.0 s (3 times).
      - re-take, then run to the plot: exactly one Tool `???` (crookreed, 1 tier,
        not hatched, no flag); BankedCount 0 -> 1; no loose pod.
      - forced 0.9: `confiscated` / `took a 4 tier bogbonnet off`; no loose pod;
        `Hauling=right`; `returned ... to Nest_tanglemire_01 (arrived)`; ring +1.

### Not verified

Two real players (only the spec's stand-in carriers). Emberroot and Starbloom in
Play (same call; profile check only). A real bat hit on an abandoned carrier
(the spec uses the same Drop). Dusk with an abandoned pod on the ground (read in
code only). The unforced live 40/60 split.

### Found, not fixed

DebugService `Teleport {where = "plot"}` throws `GetPivot is not a valid member
of Player`: it passes the Player to `PlotService.SpawnCFrameFor(plot: Model)`.
This predates this change.

### Files

`GuardianCatch.luau` (new), `CarryService.luau`, `NestService.luau`,
`GameConfig.luau`, `DebugService.luau`, `tools/tests/GuardianConfiscateSpec.luau`
(new).

## The placement disc follows the second bed — 2026-09-11 (CLAUDE)

Owner report: the placement circle would not go onto the second soil.

### Cause

`PlantPlace.soilPoint()` knew only the main `Soil` part. From Level 3 a plot has
a second Planter-tagged bed, `SoilSide`, and:

  * a ray landing on the side bed's rows/clods was accepted, but the disc was then
    clamped into the MAIN bed's rectangle, so it sat pinned on the main bed's rim;
  * a ray landing on the bare `SoilSide` slab was rejected (not named `Soil`, not in
    `BED_PARTS`), so no disc and no click was even sent.

The server was always right: `PlaceAt` picks the bed with `bedsOf` + `pickBed`.

### Fix

`PlantPlace` now mirrors those two helpers for the preview: accept a hit on any
Planter-tagged part of the plot (or a `BED_PARTS` descendant), and clamp the disc
into whichever bed the server's nearest-clamped-point rule picks. The client still
sends only the raw point; the server still decides.

### Verified, desktop

```
hover over SoilSide centre   disc visible, inside SoilSide at local (0.1, 0.0)
click there                  "planted a 1 tier Nubkin", on SoilSide,
                             0.0 studs from the hovered disc
hover over main Soil         disc inside Soil, 0.05 studs from the aimed point
```

Ten specs pass; `rojo build` and `git diff --check` clean; PlantPlace compiles;
console free of errors. Not checked on the emulated phone, where the disc tracks
the last touch through the same `soilPoint()`.

### Files

`PlantPlace.client.luau`.

## The pickup prompt rides the plant's authoritative position — 2026-09-11 (CLAUDE)

Fixes the defect recorded in the entry below: desktop `E` was silently refused
on any grown plant that had wandered, because the server never moves plant parts
and the `PickupPrompt` hung off the model's PrimaryPart at the planting spot.

### The authoritative-position contract

  * **Truth** is `wanderWorld(plot, currentOffset(entry, Workspace:GetServerTimeNow()))`
    — the same point every leg is published from and every client draws.
  * **The prompt** hangs off ONE invisible anchor Part per grown plant, at
    `plot/Runtime/PickupAnchors/<placementId>`, OUTSIDE the model. Transparency 1,
    Anchored, CanCollide/CanTouch/CanQuery false, CastShadow false, 0.2³.
  * **Updated** by `trackAnchors` on PlantService's existing 0.5 s tick, right
    after `stepWander`; skipped under 0.05 studs of movement, so a resting garden
    writes nothing. No new loop, no Heartbeat.
  * **Height** rides `anchorLift` = PrimaryPart height above the ground point at
    attach time, so the prompt sits where it always did.
  * **Lifecycle**: created in `attachPickup`; dropped by `render`, `hatch`,
    `pickUp`, `OnReleased`, `Init`, and a restore that replaces a table;
    re-seated after `RebaseTo`; `sweepAnchors` destroys any child not held by a
    live entry after restore and rebase. `Runtime` survives a resize (MapService
    keep list) and is emptied on release (PlotService.clearPlot).
  * **Client lookup** (`PlantPickUI.promptFor`): my plot → Runtime → PickupAnchors
    → `<PlacementId>` → `PickupPrompt`. Ownership stays structural.
  * **Untouched**: creature parts (still `CanQuery = false`), part counts, the
    model bounding box, client `PivotTo`, `PickUpById` (no distance check — the
    Garden panel uses it from anywhere), every other prompt.

### Measured, desktop, on real wandering plants

```
anchor vs authoritative point   walking 0.09 | rest 0.13 | mid-stride 1.40
                                end of stride 0.06 (0.26 s after arrival)
                                max over ~100 s of sampling 2.20 studs
visible plant vs anchor         client, 40 s: max 2.23 | mean 0.70 | walking 0.88
model                           44 parts, 0 queryable, 0 prompts inside
bat-style ray through
  plant + anchor                first hit the Rail beyond -- unobstructed
bounding box                    stable 4.8 x 9.4 x 5.0 across the walk
```

Error is one tick of travel (TickSeconds 0.5 × WanderSpeed ≤ 2.6 studs/s plus
scheduling), under 9% of the 26-stud range.

```
nubkin walked 40.6 studs from where it was planted
  E beside the VISIBLE plant     SERVER Triggered PickupPrompt, one
                                 "picked up" log, its anchor removed
bellchime 42-50 studs from its planting spot
  E standing ON that spot        no billboard, no trigger, still planted
```

Resize (debug SetPlotTier 5 → 1 → 5): shrink relocated one plant; after each
step 2 anchors / 2 plants / 0 orphans, 0 queryable parts, anchors within 0.39 and
0.98 studs of authoritative. Rejoin (Play restart): 2 plants restored, 2 anchors,
0 orphans, within 2.05 / 2.63 studs.

Other desktop prompts, all `E`, all server-confirmed: Marigold, sell board, mill
(Treadmill01), hatch (a planted pod after its 28.5 s), nest Take (then the
guardian threw the player, as normal).

### Mobile, emulated phone 735 × 413

```
drag starting ON the plant      no selection, no highlight
tap the plant (hands empty)     selected: button "BELLCHIME", one highlight,
                                NOT picked up
PICK UP button                  PROCESSED; one "picked up a 2 tier Bellchime",
                                its anchor gone, 0 orphans
floating touch panels           0 near the plant
```

A tap while a plant Tool was in hand was correctly ignored by PlantPickUI and
went to PlantPlace (server logged `placement refused: OUT_OF_RANGE`) — the
existing "stand down while placing" contract, not a defect.

### Test rig note

Grown plants wander fast enough to outrun a read → tap round trip. For the mobile
tap the CLIENT's picture was parked on the anchor's ground point (degenerate leg,
re-asserted on `WanderT1`); the server kept walking the real plant and
eligibility still read the anchor. No parking was used for any desktop or anchor
measurement.

### Remaining risks

  * **The desktop billboard steps** with the anchor every 0.5 s rather than gliding
    with the plant — at most ~1.3 studs per step on the lightest tier.
  * **Another player** was not tested with a second client. Guards: the prompt's
    `Triggered` → `pickUp` owner check; `PickUpById` looks only in the caller's
    plot; PlantPickUI resolves prompts only in its own plot.
  * **No physical phone**; mobile is the Studio emulator.

### Validation

Ten specs pass; `rojo build` clean; `git diff --check` clean; PlantService,
GameConfig and PlantPickUI compile; client and server console free of errors.

### Files

`PlantService.luau`, `GameConfig.luau` (`Plot.PickupAnchorsFolderName`),
`PlantPickUI.client.luau` (prompt lookup only).

## A grown plant is tapped, then picked up by a button — 2026-09-10 (CLAUDE)

On touch, the one-step pickup is gone. Tap your own grown plant and it is
SELECTED and outlined; a real `PICK UP` button appears above the hotbar and that
button is the only thing that takes it. Desktop keeps the floating prompt and `E`.

### The interaction contract

| step | rule |
| --- | --- |
| select | on touch RELEASE, never on touch-down |
| qualifies | began outside GUI (`gameProcessedEvent` false at BEGIN), moved ≤ 10 px, lifted within 0.5 s, one finger only |
| target | screen ray genuinely intersects the plant's own bounding box, nearer than any solid geometry |
| eligible | in the local player's own `Plants` folder, tagged `Planted`, has an enabled `PickupPrompt`, and within that prompt's own `MaxActivationDistance` |
| pick up | only the `PICK UP` button, debounced 0.4 s |
| at most | one plant selected, one `Highlight`, reused |

Nothing about a touch that has just landed says whether it is a tap or a camera
swing, so nothing is decided until the finger lifts. Step 1 is harmless, which is
what lets it be a guess about a fingertip at all; step 2 is a button with its own
rectangle, so it cannot be guessed wrong.

### The coordinate space, measured, so no inset can creep back in

```
InputObject.Position   below-inset   <- what a touch reports
GetMouseLocation()     window        <- 58 px higher, same tap, measured
ScreenPointToRay       below-inset   <- round-trips to 0.0000 studs
ViewportPointToRay     window        <- round-trips to 0.0000 studs
```

The wrong pairing missed a point 12.5 studs away by **2.41 studs**. So this file
does no arithmetic at all: the touch arrives below-inset and goes straight into
`ScreenPointToRay`, which wants below-inset. There is no constant to drift.

(`PlantPlace` pairs `GetMouseLocation` with `ViewportPointToRay` — the *other*
matching pair, equally correct. Only the wording of its comment is inverted.)

### Why the ray tests a box and not the parts

Every creature part is `CanQuery = false`, and that is invariant 1, not an
oversight — `CombatService` leans on it: *"a wall stops a bat, a pod does not."*
Making plants queryable so they could be tapped would start blocking bat swings
across a garden. So the ray is tested against `Model:GetBoundingBox()` instead and
the invariant is untouched. Measured on a live 2.4 × 4.2 × 2.0 plant: dead centre
hits at 72.9 studs, one stud off hits, two studs off misses.

### THE DEFECT THIS UNCOVERED — desktop `E` is broken on a wandered plant

The brief asked for the prompt to be driven through `InputHoldBegin()` /
`InputHoldEnd()`. **It cannot be, and the reason is a pre-existing bug in
something else.** Measured:

```
client draws the plant    7.5 studs from the character
SERVER has its Base      63.0 studs from the character   (prompt max 26)
```

A grown plant is animated **by the client**. `PlantService` publishes a wander leg
as four attributes and every client walks the model along it; the server never
moves the parts — measured, `Base` byte-identical for five seconds while
`WanderTo` pointed 65 studs away. That is deliberate (it is why the wander costs
no per-frame replication) and invisible until something needs both copies to agree
about where the plant *is*.

A ProximityPrompt needs exactly that. The client shows it from the position the
client drew; the server validates the trigger from the position the server kept.
Two 26-stud spheres 63 studs apart do not overlap, so **no standing position
satisfies both** and the trigger is refused in silence.

Proved from both ends, and the boundary pinned:

```
positions diverged (7.5 vs 63.0)   server's PromptTriggered never fired -- from
                                   the button, from a bare script call, and while
                                   standing at the server's own copy
positions agreed  (6.4 vs 6.9)     the prompt WORKS, plant picked up
```

**So desktop `E` works only while a plant is near where it was planted.** Verified
on desktop after aligning the two copies: prompt drawn, `E` pressed, plant taken.
Nobody has tested `E` on a plant that has walked, and by this measurement it
cannot work. That is a `PlantService` replication decision, not a mobile-UI one,
and it is the top follow-up.

### So the button uses the verb that already existed

`PickUpAction` → `PlantService.PickUpById`, which the Garden panel has used since
it was written. **Nothing was added**: no remote, no handler, no second ownership
list, no widening of what a client may ask. It is position-independent, which is
why it works where the prompt cannot.

The server checks, none of it client-side: payload must be a finite whole positive
number; the lookup happens in the **caller's own plot and nowhere else**, so a
neighbour's id is not in the table; then `pickUp` re-tests ownership, that the
entry is still live, that it is grown, and that the bag accepted it.

### Verified on the emulated phone, 735 × 413, touch

```
short tap on my grown plant     selected, outlined, NOT picked up
                                button "PICK UP" / "PETALPIP", 168 x 46
                                8 px clear above the hotbar top edge (y269)
exactly one highlight           on the tapped plant, and only that one
press the button                picked up; plants 3 -> 2, one Tool gained
four rapid presses              ONE pickup -- one server log line
tap bare ground                 cleared
tap another owned plant         selection MOVED, still exactly one highlight
tap a plant 47.7 studs away     not eligible, no button
DRAG STARTING ON THE PLANT      nothing -- this is the reported defect
drag from ground, across it,
  and ENDING on it              nothing
tap hotbar slot 1               PROCESSED; plant untouched, selection survived
open the bag                    cleared, no stale button
holding a plant for placement   selection disabled entirely
equip a plant mid-selection     cleared
walk 45 studs away              cleared
die and respawn                 cleared; zero Highlight instances left in the tree
forged ids -1 0 1e12 2.5
  999999 NaN "hello" true nil   all refused, nothing moved
Marigold's floating prompt      still drawn on touch, still opens her shop
```

The floating `PickUpPrompt` panel is not drawn on touch at all — measured 0 panels
while standing 8 studs from the plant — and every other prompt still is.

### Verified on desktop, 1065 × 609, touch off

```
SeedPromptLayer absent          PromptUI is on its unchanged billboard path
SeedPrompt billboard drawn      adorned to Creature_bellchime.Base
E pressed                       picked up once; billboard gone
mobile button                   never appeared, stayed disabled
hotbar                          10 slots -- b4faa43 intact
```

### Not verified

  * **No physical phone.** All of the above is Studio's emulator.
  * **Another player's plant** — no second player was available. The guard is
    structural in two independent places (`PickUpById` looks only in
    `PlotService.PlotOf(player)`; `pickUp` re-tests `OwnerOf`), and a neighbour's
    plants are not in the folder the ray searches, so no button can appear for
    one. Untested by a real second client.
  * **Nest Take, hatch, mill and sell prompts** were not individually re-pressed.
    Marigold was, and all five share the one code path the exclusion does not
    touch; the exclusion is a single name in a table.
  * **`E` on a plant that has wandered** — see the defect above. Expected to fail.

### Test-rig notes worth keeping

  * **Grown plants WANDER**, several studs at a time, so a scripted tap misses
    unless the plant is parked. Park it by writing a degenerate leg on the client
    — `WanderFrom == WanderTo`, `T0/T1` already past — re-asserted on
    `WanderT1` changing, which is what `PlantService.parkAt` publishes. Park it on
    the **server's** `PrimaryPart.Position` if the test needs the prompt to work.
  * `PromptHidden` fires spuriously for a wandering plant (`hidden` then `SHOWN`
    back to back while standing still 8 studs from a 26-stud prompt). Clearing the
    selection on every one of those made the tap look broken; the handler now
    re-checks real range instead of trusting the event. A ⅓-second watcher, alive
    only while something is selected, closes the case where the player leaves
    while the prompt is already hidden.
  * A `BindableFunction` parked in PlayerGui is wiped on respawn.

### Validation

Ten specs: BatClearance 939/939, BatSwing 93/93, Cycle 31, MillSign 8/0,
Plot 65/0, Speed 332, StarbloomLimb 71/0, TutorialPod 263, Tutorial 93/0,
Weapon 107/0. `rojo build` clean, `git diff --check` clean, both edited files and
the new one compile, client and server console free of errors.

### Owner checklist, on a real phone

  1. tap a grown plant — it should outline and a `PICK UP` button should appear;
  2. drag the camera *starting on* the plant — nothing should happen;
  3. drag the camera *across* the plant — nothing should happen;
  4. press the `PICK UP` button — the plant should go into your bag;
  5. hold a plant ready to place, then tap another plant — nothing should happen.

### Files

`PlantPickUI.client.luau` (new), `PromptUI.client.luau` (one exclusion),
`AGENTS.md` (structure table).

## The hotbar adapts, and an assignment claims a Tool — 2026-09-10 (CLAUDE)

Ten slots on a keyboard at width, five otherwise, and the strip is now something
the player arranges: drag a plant from the bag onto a slot and that exact copy
leaves the bag; drag it back, or double-tap it, and it returns.

`PromptUI` untouched — verified with `git diff --stat`, empty.

### The count follows the device, and the slot size never changes

Desktop needs **both** a keyboard and ≥ 900 px. Either alone is not enough: a
narrow desktop window cannot show 694 px of strip without eating the screen, and
a tablet has the width but no number row, so slots 6–10 would be reachable only
by touch — which is the fingernail problem the five-slot pass fixed in the first
place. Measured, and the "both" rule earns its keep immediately:

```
1065 x 609  keyboard  ->  10 slots, keys 1..9,0, 694 px (65% of width)
 735 x 413  keyboard  ->   5 slots, keys 1..5,   344 px (47%)
```

That second line is the point. The emulated phone reports `KeyboardEnabled =
true` in some Play runs, so a keyboard-only rule would have put ten slots on a
735 px screen. Width settles it.

**Slots never shrink.** Ten in 735 px would be ~40 px each, under Roblox's 44 px
touch guidance. Five real slots beat ten unusable ones, and a scrolling hotbar is
one nobody can hit without looking.

The tenth slot is labelled **0**, because that is the key that reaches it.

### An assignment is a Tool *and* a key, and neither alone works

The old `pinned[slot] = key` could not tell two identical plants apart, and this
feature has to: assigning one of two identical Nubkins must hide exactly one.
A Tool reference alone is no good either — a respawn destroys every Tool.

So `assigned[slot] = { key, tool, lostAt }`, where `tool` is the **claim** (this
exact copy, the one hidden from the bag) and `key` is the **lease** (what to look
for when the claim dies). Reconciled once per redraw, active slots first so a
phone's five keep the copies they already had.

**Only an assignment hides anything.** An auto-filled slot claims nothing, which
is why a bat on the strip is still in the Equipment tab.

### Measured, two identical Nubkins throughout

```
assign one of two          cards 3 -> 2, the other Nubkin stays        exactly one hidden
which copy is where        slot1 debugid 1_2816345, slot4 1_2816277    two different Tools
equip from slot1           assignment survives Backpack -> Character   claim is the instance
replace an assigned slot   displaced Nubkin reappears as a card        return by clearing
move slot1 -> slot5        one assigned slot, no duplicate             a drop is a move
drag slot -> open bag      unequip[1_3137753] logged, card returns     unequips on the way out
double-click a slot        first click equips, second returns it       no delay on the common path
single click               equips, assignment KEPT                     one tap is not two
```

Tool count never moved from 5 in any of it: nothing is cloned, and there is no
second ownership list — the bag is a filtered view of the real Tools.

### Respawn: a lease has to outlive the gap where its Tool does not exist

The first version cleared an assignment the moment its Tool went missing. That
looked right and destroyed the feature — a respawn destroys the Backpack, so for
a moment the player owns nothing, `redraw` runs inside that gap and throws the
arrangement away. Proved by destroying three Nubkins and rebuilding three
identical ones: the slot came back auto-filled with a trap.

So a lost claim is not a dead assignment. `ASSIGN_GRACE` is 5 s, which separates
the two cases by the only thing that distinguishes them — respawns come back
within a second, sold items never do. Both branches measured:

```
destroy 3 Nubkins, 0.9s gap, rebuild 3    slot 2 still assigned, bound to a NEW
                                          instance, 2 cards of 3 tools
destroy 1, no replacement                 t+1.0 .. t+5.1s  slot reserved, empty
                                          t+6.1s           released, auto-fills
```

One `task.delay` per loss, guarded by `gracePending`, so a settled hotbar costs
nothing per frame.

### Bats and traps are exempt, and it is a capability not a name list

`HOTBAR_ASSIGNABLE` is keyed on **category**, and a Tool may override with a
`CanAssignHotbar` attribute — so a future ordinary item opts in without this file
being edited. Measured:

```
drag a bat card onto a slot     no ghost ever appeared, no assignment
drag the bat's own slot         no ghost -- an unassigned slot cannot be dragged
bat + trap on the strip         both still listed in Equipment, both EQUIPPED
```

Bats and traps still appear on the hotbar — that is where you swing from — they
just are not assignable, returnable or hideable by it. Combat untouched.

### Cancel, and the drag cannot be left hanging

Cancelled by: the bag closing, character removal, a pod in both arms, the jaws
closing, ragdoll (Humanoid state — ThrowFX drives it locally, there is no
attribute), the Tool being destroyed, and the slot count changing. The hard one
measured directly, with the button still physically held down:

```
Trapped = true mid-drag   ghost destroyed, hotbar Z 60 -> 4, all slot Z -> 5
then released over slot2  assigned NOTHING -- a cancelled drag is not a placement
3 full assign->return cycles   0 leftover ghosts, Z restored, no errors
```

A destroyed Tool is detected as `Parent == nil`, not "left the Backpack" —
equipping reparents, and cancelling on that would cancel every drag the instant
the hands changed.

### The bug this nearly shipped with, and the rule it re-teaches

The assignment state was declared **below** `acquireHotSlot`, so the slot's own
handlers read `assigned` as a global — nil:

```
LoadoutUI:1198: attempt to index nil with number
LoadoutUI:1226: attempt to index nil with number      (x30 in one session)
```

Thrown inside event handlers, so each press died on its own and nothing else
broke. The card drag still worked, because that path is defined further down —
only the hotbar's own gestures were dead, which is a very good disguise. This
file already carries three forward-local banners warning about exactly this; the
state now sits with them. **Whatever else moves in here, `assigned`, `claimed`
and `liveSlots` stay above `acquireCard` and `acquireHotSlot`.**

### Shrinking the bar releases the slots it takes away

Measured over a real 1000 → 408 → 1169 round trip:

```
at 1000, slots 7 and 8 assigned      cards 2 of 4 plants
narrowed to 408                      5 slots, slots 7-10 gone,
                                     cards 2 -> 4, both items usable on the strip
widened to 1169                      10 slots -- but 7 and 8 came back EMPTY
```

Everything mandatory passed: the slots go inactive, their items become visible
and usable, nothing is stranded, nothing duplicated (4 plant tools throughout).
What did not happen is restoration — and I could not find out why. Steady state
holds those same records through equips, unequips and well past the grace, so it
is specific to the transition, and the transition cannot be reproduced from
script: `ViewportSize` is read-only (a detached Camera reports 1×1 until it
becomes current, then the engine overwrites it with the real viewport), and
toggling Studio's emulator restarts Play, which wipes session state.

Rather than ship "it usually comes back", the release is now the **definition**:
`applySlotCount` clears slots above the new count on the way down, and says so.
The brief permits this — restoring on the way back is "may", never "must" — and
nothing is lost, because the items are in the bag and auto-fill onto the five
remaining slots. Worth revisiting only alongside making assignments outlive a
rejoin, which needs a profile field, a schema version and a migration; at that
point an arrangement is a saved thing and "restore it" has a defensible answer
instead of being a timing accident.

### Not verified, honestly

  * **The number keys were never pressed.** `VirtualInput` refuses them:
    `key is permanently bound to a CoreGUI core action`. The handler was fixed —
    it indexed `liveSlots[i]` before, so pressing 1 equipped whatever was first
    alphabetically rather than what slot 1 was showing — and it now reads the
    same `slot.tool` that tapping uses, which IS verified. But nobody pressed a
    number.
  * **No physical phone**, and the mobile half of this pass ran on the emulator.
  * **Double-tap on touch** was verified on desktop as a double-click (two
    `mouseButtonClick` actions land inside the 300 ms window). On the emulated
    phone the harness could not go faster than ~466 ms between activations, so
    the touch flavour of the gesture is unproven; it is the same handler.
  * **Plant placement and pod carrying were not re-run** this session. Neither is
    touched by this change and the console is clean, but that is not a test.

### Test fixtures worth reusing

`CarryService.GiveHatched(player, SeedData.Get("nubkin"), 3)` from the **Server**
datamodel makes a genuine plant Tool — the production builder, so the fixture is
faithful. Two calls with the same species and tier give two Tools with the same
key, which is the only way to exercise the duplicate-copy rules.

Traps: a `BindableFunction` on the PlayerGui is wiped on respawn, so an inspector
parked there vanishes when the character dies. And a card's `Visible` stays true
while an ancestor dimmer is false — read `BagDimmer.Visible` before believing a
card count.

### Validation

Ten specs: BatClearance 939/939, BatSwing 93/93, Cycle 31, MillSign 8/0,
Plot 65/0, Speed 332, StarbloomLimb 71/0, TutorialPod 263, Tutorial 93/0,
Weapon 107/0. `rojo build` clean, `git diff --check` clean, `LoadoutUI` compiles
at 98,203 bytes, client and server console free of errors.

### Owner checklist

  1. On a phone: five slots, tap one to equip, double-tap an assigned plant to
     send it back.
  2. On desktop: ten slots, press 1–9 and 0 and check each equips what that slot
     shows.
  3. Own two identical plants, assign one, and confirm the other stays in the bag.
  4. Die with an arrangement set and confirm it survives.
  5. A bat and a trap stay equipped together and never leave the Equipment tab.

### Files

`LoadoutUI.client.luau` only.

## The prompt panel IS the touch target — 2026-09-10 (CLAUDE)

**Corrects the entry below it,** which computed a hit rectangle by projecting the
adornee. On a real phone the owner had to tap *below* the visible prompt. The
estimate is gone: on a touch device the panel is now a `TextButton` in a real
`ScreenGui`, so the thing that is drawn and the thing that is pressed are the
same instance and no rectangle can be wrong.

### The measured cause of that offset — never guess an offset again

`Camera:WorldToViewportPoint` returns **window space** (the 3D view fills the
whole window, topbar included). `InputObject.Position` and
`GuiObject.AbsolutePosition` are both **below-inset**. Measured on this place at
a 58 px inset, against the local character's head:

```
WorldToViewportPoint   367, 207     window space
WorldToScreenPoint     367, 149     below-inset  (= viewport - 58)
a marker drawn at y=207 in an IgnoreGuiInset=true ScreenGui
    reports AbsolutePosition y=145, centre 149
```

The old hit test compared a window-space projection against a below-inset touch,
so its rectangle sat exactly one inset — 58 px — below the panel. Confirmed again
on the live panel, which is the clearest single proof in this whole entry:

```
panel.Position        409,161     window space, what we set
AbsolutePosition      324,77      below-inset, centre 409,103
GetGuiObjectsAtPosition(409,103) -> Panel(TextButton, Active=true)   HIT
GetGuiObjectsAtPosition(409,161) -> TouchControlFrame only           MISS
```

**The coordinate contract now in the file:** the layer is `IgnoreGuiInset = true`
and positions come from `WorldToViewportPoint`, so both are window space and no
inset arithmetic appears anywhere. `AbsolutePosition` is only ever compared
against `InputObject.Position` — same space, no conversion.

### The second defect, which the rewrite did not fix and a test found

`GuiObject.InputBegan` fires for a touch that **ENTERS** the button, not only for
one that starts on it. So a finger landing on open ground and dragged across the
panel got a full `InputBegan`, started a hold and completed it. Transcript, on a
panel occupying y 4..56:

```
touch 253,140            <- UserInputService: the real landing point, outside
>PANEL saw Touch         <- the panel, ~400ms later, on entry
>HOLD SellPrompt
>***TRIG SellPrompt      <- it sold the bed
```

On a `PICK UP` panel, whose hold is zero, one camera pan that swept the prompt
would have lifted the plant instantly — the owner's original complaint by another
route. **Fixed** with an `origin` table: `UserInputService.InputBegan` fires once
per gesture at the true landing point, and a hold is refused if that point is
outside the panel. Note the signal order, which is what distinguishes the two
cases and is why the guard is written to not depend on it:

| gesture | order | `origin[input]` at panel time | verdict |
|---|---|---|---|
| lands on the panel | panel first, UIS second | nil | allowed |
| dragged onto it | UIS first, panel second | outside | refused |

A `spent` table gives each finger one hold, so a pan-cancel cannot be used to
start again without lifting.

### Verified, emulated phone, 735×413, top inset 58 (nonzero throughout)

Direct targeting, rect verified unmoved at 151,80 before **and** after the run:

```
centre 236,106      HOLD        20 above 236,60    nothing
top edge 236,81     HOLD        20 below 236,152   nothing
bottom edge 236,131 HOLD        left 121,106       nothing
                                right 351,106      nothing
                                elsewhere 520,300  nothing
```

The misses were pressed for 900 ms against a 700 ms hold — long enough to have
completed had they registered. Four cameras, rect re-read for each:

| camera | panel | centre | 25 px below |
|---|---|---|---|
| normal | 151,80 | HOLD | nothing |
| steep tilt down | 283,113 | HOLD | nothing |
| steep tilt up | 283,58 | HOLD | nothing |
| close zoom | 283,38 | HOLD | nothing |
| far zoom | 283,100 | HOLD | nothing (and left: nothing) |

Holds, on the sell board (1.10 s), post-fix:

```
short 300ms   >PANEL saw Touch >HOLD >HOLD-ENDED            no trigger
full 1400ms   >PANEL saw Touch >HOLD >HOLD-ENDED >***TRIG   sold
drag off      >HOLD then >HOLD-ENDED BEFORE the lift        no trigger, held 1.7s
begin outside >PANEL saw Touch, no HOLD at all              no trigger, held 1.9s
```

The drag-off cancel is provably caused by the drag, not the release: `HOLD-ENDED`
is logged before `lift`.

Zero-hold, the owner's exact bug class:

```
direct tap        >PANEL saw Touch >***TRIG MarigoldShopPrompt
full-screen diagonal sweep through the rect (x347..517 y185..237)  no trigger
```

Plant pickup, `PickupPrompt`, hold 0, on the owner's own plot: **13 taps that
were not on the panel** — soil, 18–25 px above/below/left/right, thumbstick,
jump, hotbar, and a drag that began outside and slid onto it — and the plant
never left the plot, the tool count never moved, and the server logged exactly
one pickup for the whole session, from the one deliberate tap:

```
[Seed/PlantService] nicnicniccoal picked up a 4 tier Spiretip. 0/20 in the bed.
```

Under the entry below, any one of those 13 would have picked it up.

The topbar clamp is engaged and reachable: at a 58 px inset the panel pins to
`y 4..56` (`inset 58 + half 26 + 4` in window space) rather than drawing under
the topbar, and a tap at its centre is `PROCESSED` and starts a hold.

A pod take still works end to end — `[Seed/CarryService] ... completed a take
hold on Pod_petalpip` — and the guardian ragdoll after it settled in 1.87 s and
stood up once, down for 2.93 s, so that path is intact.

`E` still triggers a prompt with the emulator on (`KeyboardEnabled=true`).

### Not tested, honestly

  * **No physical phone.** All of the above is Studio's device emulator, which
    emulates resolution and input but not a real touchscreen or a real GPU.
  * **The desktop billboard branch was not exercised**, because the emulator
    forces `TouchEnabled = true` and the branch is chosen off that. It is
    unchanged code and `E` is engine-handled, but nobody ran it this session.
  * **No genuine two-finger test** — the harness has one pointer. The
    second-finger rules are identity comparisons on the `InputObject`
    (`input == activeTouch`), correct by construction but unproven by touch.
  * **A second emulated viewport** was not run: the device profile is a Studio UI
    setting this session cannot change. Nothing in the placement depends on
    viewport size except off-screen culling.

### On touch the panel no longer scales with distance

Deliberate, and a change from the billboard: the button is a constant 170×52, so
a far prompt keeps a finger-sized target instead of shrinking below reach.
Desktop keeps the distance-scaled billboard.

### Four harness traps that cost most of this session

  * **`StreamingEnabled` streams the adornee out.** Every "the panel vanished
    for no reason" was this. After the guardian threw the player across the map
    there was no `TakePrompt` in the client's tree at all.
  * **Marigold is the wandering fairy** (13×4 studs) and walks out of her own
    11-stud prompt range. Stand within ~3 studs or pin her.
  * **A `Scriptable` camera accumulates stray pan** from the synthetic pointer
    and never recovers, so read-then-tap misses. `Custom` recomputes each frame
    and self-heals — use `Custom` with an anchored character. Better still,
    target `instance_path`, which now works because the panel is a real
    ScreenGui element with a true `AbsolutePosition` (a BillboardGui child
    reports 0,0 and cannot be targeted this way).
  * **Signal order lies about causation.** `GuiObject.InputBegan` and
    `PromptTriggered` both fire *before* `UserInputService.InputBegan` for a
    genuine tap, so a trigger looks like it belongs to the previous line of the
    transcript. Log the panel's rect at the instant of each touch or the
    transcript cannot be read.

### Validation

Ten specs: BatClearance 939/939, BatSwing 93/93, Cycle 31, MillSign 8/0,
Plot 65/0, Speed 332, StarbloomLimb 71/0, TutorialPod 263, Tutorial 93/0,
Weapon 107/0. `rojo build` clean, `git diff --check` clean, `PromptUI` compiles
at 28,334 bytes.

### Owner test checklist for a real phone

  1. Stand on a plant in your plot. Tap the soil, the hotbar, the thumbstick, the
     jump button, and pan the camera. The plant must stay planted.
  2. Tap the words `PICK UP`. It should lift once, first time.
  3. Pan the camera so your finger sweeps straight across a `PICK UP` prompt.
     Nothing must happen.
  4. At a nest pod, hold `TAKE` for a second — it should take. Start the hold and
     slide your finger off — it must not.
  5. The sell board must still need its full hold.

### Unchanged

Hold durations: plot pickup 0, Marigold 0, sell board 1.10, hatch 1.10, nest
Take 0.70, mill 0.35. `TAP_SLOP` 34. Server ownership validation untouched —
`CarryService.TryTake` and `PlantService` still refuse a stranger, and nothing
here invokes a server action directly or forges a trigger.

### Files

`PromptUI.client.luau` only.

## The tap has to land ON the prompt — 2026-09-09 (CLAUDE)

**Corrects the entry below it.** That one shipped a rule where *any* unprocessed
tap triggered whichever prompt was shown, on the reasoning that a prompt only
appears when you are standing at the thing. The owner found the hole immediately:
with a plant underfoot, every tap anywhere picked it back up — including the tap
meant to place a plant somewhere else, so it had to be placed again.

"You are near it" is not "you asked for it". The tap is now hit-tested.

### Where the panel is, and why it has to be computed

`PromptUI` draws each prompt inside a **BillboardGui**, and a BillboardGui is not
laid out in screen space:

  * its children report `AbsolutePosition 0,0` — measured;
  * `playerGui:GetGuiObjectsAtPosition` does not return them — measured, with the
    panel confirmed rendering 48 studs from the camera at the time;
  * and their buttons never receive touch at all, which is the defect the entry
    below fixed.

So the rect is computed the same way Roblox places the billboard: project
`adornee.Position + StudsOffset`, take `panel.AbsoluteSize` around it —
`AbsoluteSize` is the size it is really drawn at, distance included. Verified
against a live touch:

```
touch  371,201     proj 371,201     half 85,26     dx -85  dy -26     inFront true
```

The projection is exact. `TAP_PAD` is 16 anyway, because `StudsOffset` is applied
along the CAMERA's axes rather than the world's, so a steeply tilted camera moves
the panel slightly off this estimate; the nearest other prompt is metres away in
world space, so slack costs nothing.

### Verified on the emulated phone, touch only

```
Take, 0.7s hold   on-target tap -> HoldBegan, TRIGGERED,
                  server log "completed a take hold on Pod_toadcap"
                  far tap (90,322 vs prompt at 350,202), held 1.4s -> nothing
Marigold, 0 hold  on-target tap -> TRIGGERED(MarigoldShopPrompt), shop opened
                  far tap (400,300 vs prompt at 340,202) -> nothing
```

The zero-hold case is the one that matters, because an instant prompt is what
made the original bug so visible, and it is the same class as the plot pickup.

### Four traps that made this take far longer than it should have

Recorded because every one of them made a working thing look broken.

**The success signal for a stolen pod is the server log, not `CarryingSpecies`.**
Twice a tap genuinely took the pod and the guardian immediately caught the player
and threw them, which DROPS it — so the attribute read nil a second later and the
tap looked dead. `[Seed/CarryService] ... completed a take hold` is the truth.
(Those two catches also settled naturally at 3.20s and 2.87s, so the guardian path
is still intact.)

**A plot pickup's signal is a plant Tool appearing**, not `CarryingSpecies` either
— that attribute is for nest pods.

**A prompt at the screen edge is covered by the HUD.** An on-target tap at
`71,193` did nothing because the left HUD sits there and the touch arrived
`processed = true`. The same prompt at `340,202` worked. Stand so the prompt is
not against an edge before concluding anything.

**Prompts vanish while carrying.** `PromptUI.show` returns early on `carrying()`,
so after any successful pickup every prompt hides and the next tap has nothing to
hit. Bank first.

And one self-inflicted one: destroying `SeedPrompt` billboards by hand leaves
`shown` holding stale entries, so `show()` returns early and no prompt comes back
until the player leaves range and returns.

### Validation

Ten specs pass, `rojo build` clean, `git diff --check` clean, `PromptUI` compiles.

### Unchanged

The hold values from the entry below are untouched: plot pickup 0, Marigold 0,
sell board 1.1, hatch 1.1, nest Take 0.7, mill 0.35. Drag-cancellation
(`TAP_SLOP` 34) is unchanged and still verified.

### Files

`PromptUI.client.luau` only.

## The prompt tap never worked on mobile, and two prompts lost their hold — 2026-09-09 (CLAUDE)

Device emulator: 735 × 413, `TouchEnabled`, `MouseEnabled` and `KeyboardEnabled`
both false.

### The tap did not work, and it never had

Owner report: tapping a proximity prompt does nothing on mobile. It is worse than
a regression — **it has never worked.** Nobody noticed because a desktop presses
E, and E is the only reason any prompt in this game has ever fired.

`PromptUI` drew each prompt as a TextButton inside a **BillboardGui** and hung
`MouseButton1Down` / `MouseButton1Up` / `MouseLeave` on it. None of the three ever
fires from touch. Measured, two taps a few pixels apart with the camera frozen:

```
on the prompt panel          GLOBAL:Touch(processed=false)   panel silent
on a plain ScreenGui button  GLOBAL:Touch(processed=true)    button fired
```

`processed = false` is the whole story: **no GUI consumed the tap.** A BillboardGui's
buttons do not take part in touch hit-testing the way a ScreenGui's do. Setting
`BillboardGui.Active = true` was tried first and changed nothing.

**The fix does not add a keyboard affordance on mobile**, as instructed. The tap
is caught globally in `PromptUI` and routed to the shown prompt.

**It deliberately does NOT hit-test the panel.** The first attempt did — project
the adornee, build a rect from the panel's `AbsoluteSize`, require the touch
inside it — and it failed, because a BillboardGui is not laid out in screen space
at all: its children report `AbsolutePosition 0,0`, and `StudsOffset` is applied
relative to the camera rather than the world, so a projected rect is measurably in
the wrong place. Trying to be precise about where a billboard is drawn is the
wrong problem. A prompt only appears when the player is inside
`MaxActivationDistance`, and `PromptShown`/`PromptHidden` already own that: **if a
prompt is on screen, the player is standing at it.** Position is used only to
choose between two prompts that are somehow both up.

**A drag is not a tap.** The camera is panned by dragging, so a touch that travels
more than `TAP_SLOP` (34px) releases the hold. That is the one thing this had to
get right and it is verified below.

### Two prompts lost their hold; the sell board kept its

  * **Plot pickup** was borrowing `HatchHoldSeconds`, which was never a decision —
    the two actions simply shared the only number in reach. They are not the same
    thing: hatching is irreversible, while picking your own plant off your own plot
    is undoing a placement, and a hold on an undo is friction with nothing behind
    it. New `Plant.PickupHoldSeconds = 0`. Hatch keeps its 1.1.
  * **Marigold** `Weapon.PromptHold` 0.5 → 0. The old comment justifying the 0.5
    is left standing because it is still true — she does stand near the sell board
    — and what keeps the pair apart now is that **the sell board kept its 1.1s
    hold**, so the destructive one is still the one you have to mean.
  * Untouched: sell-all 1.1, hatch 1.1, nest Take 0.7, mill 0.35.

### Verified on the emulated phone, touch only

```
pod Take, 0.7s hold   tap-and-hold 1.4s -> carrying "dunebud"
                      a HELD prompt completed from touch alone, no keyboard
Marigold, 0 hold      90ms tap -> shop open
plot Pick Up, 0 hold  80ms tap -> Emberquill Tool appeared,
                      pickup prompts in world 2 -> 1
camera pan            480,130 -> 600,175 (~128px) held 1.6s over a 0.7s prompt
                      -> nothing triggered
sell board, 1.1s      90ms tap -> plant tools still held; a tap does not sell
```

### Two harness traps that cost real time, recorded so they are not re-learnt

**`moveTo instance_path` is useless for BillboardGui children.** They report
`AbsolutePosition 0,0`, so the synthetic pointer went to the screen's top-left
corner. Several early "the tap does not work" results were that, not the game.

**A prompt vanishes the moment the player carries something.** `PromptUI.show`
returns early on `carrying()`, so after a successful pickup every prompt hides and
the next tap has nothing to hit. Two failed runs were this. Bank first, then test.

Also: the success signal for a plot pickup is a **plant Tool appearing**, not
`CarryingSpecies` — that attribute is for nest pods. Checking the wrong one made a
working pickup look broken.

### Validation

Ten specs pass via the fresh-require harness (SpeedSpec 332, WeaponSpec 107,
BatClearance 939/939, BatSwing 93/93, Cycle 31, Plot 65, StarbloomLimb 71,
TutorialPod 263, Tutorial 93, MillSign clean). `rojo build` clean,
`git diff --check` clean, and all five touched or adjacent modules compile via
`loadstring`. No client errors beyond the pre-existing ShopUI "nothing is for
sale" warning.

### Not covered

  * **Desktop mouse clicking on a prompt still does nothing**, exactly as before —
    the removed handlers never fired there either. Desktop uses E, which is
    untouched. Adding mouse support was out of scope and would change desktop
    behaviour.
  * **Real finger input.** `VirtualInputManager:SendTouchEvent` is blocked in this
    sandbox; synthetic mouse is delivered as `UserInputType.Touch`, which is the
    path exercised, but two simultaneous touches and the prompt competing with the
    thumbstick are unverified.
  * Whether a 0-hold Marigold is a nuisance in play now that she opens on a tap
    near the sell board. The two are separated by the sell board's hold, but only
    real play will say whether that is enough.

### Files

`PromptUI.client.luau` — the global tap, drag cancellation, release on hide, and
the removal of the three dead BillboardGui handlers. `GameConfig.luau` —
`Plant.PickupHoldSeconds`, `Weapon.PromptHold`. `PlantService.luau` — pickup uses
the new constant.

## Two mobile UI defects fixed, and what the rest of the pass could and could not prove — 2026-09-09 (CLAUDE)

Device emulator throughout: 735 × 413 landscape, `TouchEnabled`, `MouseEnabled`
and `KeyboardEnabled` both false, top GUI inset 58.

### 1. The Bag title no longer hides behind the rail

The rail sits at DisplayOrder 40 against a panel's 30 **deliberately** — Index and
Shop stay pressable while a panel is open, which is what lets a player move
between panels without closing one first. On a desktop that costs nothing,
because a centred panel's header is hundreds of pixels below the rail. At 735 the
Bag is 520 across and its header landed under the Index button: the title read
"AG".

Fixed in `UIKit.modal`, so all five panels get it: the title bar carries a
`UIPadding` computed from `GameConfig.Rail`, stepping its contents clear of
whichever rail buttons it actually meets.

  * **Padding, not a narrower panel and not a hidden rail.** Narrowing takes
    width from cards already at their minimum touch size; hiding the rail removes
    the thing the DisplayOrder exists to protect. Padding costs a title a few
    pixels of a line it was not using.
  * **Both sides.** The left buttons are 130 wide and the right 50, and at
    narrower widths it is the CLOSE BUTTON that meets Garden and Bag. The same
    padding moves it in, because it is anchored to the bar's right edge.
  * **From config, not from the rail's instances**, because UIKit is required by
    the rail as well as by every panel and a panel must not depend on the rail
    having been built first.

**The vertical guard is what keeps desktop unchanged**, and it was tested rather
than argued: pushing the panel down so its header clears the rail band takes the
padding to zero and back.

```
header beside the rail   titleBar top  45   padLeft 27  padRight 0
header pushed below it   titleBar top 205   padLeft  0  padRight 0
restored                 titleBar top  45   padLeft 27  padRight 0
```

Measured with all five panels open, rail edges at X<142 and X>673:

```
Bag       title "Bag" at 150 clear | close 568..612 clear | pad 27/0
Index     title at 196 clear       | close 548..592 clear | pad  7/0
Shop      cart icon at 160 clear, title at 472 | close 618..662 | pad 77/0
Garden    title at 196 clear       | close 548..592 clear | pad  7/0
Marigold  title at 150 clear       | close 566..610 clear | pad 25/0
```

Shop is worth noting: `ShopUI` injects a cart icon into the title bar, and it
stepped clear with everything else because the padding is on the bar rather than
on the title. In every panel the title's right edge stays left of the close
button — no title/close collision.

### 2. The shared close X now has a 44px touch target

**First, a correction to the previous entry.** It recorded the close button
rendering at 35 × 35 and blamed a responsive `UIScale` of 0.92. That was wrong.
The 0.92 is the OPEN ANIMATION's starting value, tweening to 1 over 0.16s — the
35 was a measurement taken mid-tween. At rest it rendered **38 × 38**, so the
shortfall against Roblox's 44px guidance was 6 pixels, not 9.

The TextButton — the hit area, and what every consumer connects `Activated` to —
is now 44 × 44 and fully transparent. The red plate is a `Plate` Frame inside it
at the authored 38, carrying the gradient, corner, stroke and shade exactly as
before. **Nothing about the appearance moves.** It grows inward, because the
anchor is still the bar's right edge, so the six pixels come from the panel's
interior rather than the outline.

Verified at rest (`UIScale 1.000`) on all five panels: **close 44 × 44, plate 38**.

Two things the change had to handle:

  * **`MarigoldShopUI` was overriding the size to 34 × 34** — already the smallest
    close button in the game and the one thing that would have defeated a shared
    fix. Removed; a phone player would otherwise have found every panel
    comfortable to close except Marigold's.
  * **Its ZIndex override had to keep working.** Marigold raises
    `modal.close.ZIndex` to 8 to clear its header, and under GLOBAL
    ZIndexBehavior a child does not inherit that — the plate would have stayed at
    5 and drawn under the header the button was raised to clear. The plate, shade
    and glyph now follow the button's ZIndex. Measured: close 8, plate 9.

**All five panels close by their X**, tapped through the emulator.

### 3. Five-slot hotbar and dragging — verified, not redesigned

```
all five slots fit           spans 196..540 of 735 px
Bag opens, title clear       "Bag" at 150 vs rail edge 142
drag onto an OCCUPIED slot   plant took Slot1, bat flowed to Slot2, 1 pin
re-drag moves not copies     exactly 1 pinned slot after moving it
tap equips, no pin           tool went in hand, pin count unchanged
cancelled drag               released at 90,340 over the thumbstick corner:
                             no pin, ghost gone, hotbar ZIndex back to 4, slots 5
respawn mid-drag             ghost gone, ZIndex 4/5, TouchGui intact
bat and trap                 both equipped independently
carrying a pod               CarryingSpecies set with NO Tool in hand, so the pod
                             owns the arms uncontested; cleared after banking
```

**One gap found and closed.** `endDrag` ran only off `InputEnded`, which is enough
while a finger stays on the glass but not for the ways a drag stops mattering
without one being lifted — the bag shutting under it, or the character being
destroyed mid-air. Neither fires an input event, and both would have left a ghost
label on screen and the hotbar stuck at ZIndex 60, drawn over every panel until
the next drag tidied it. `cancelDrag` is now called from `setOpen(false)`,
`CharacterAdded` and `CharacterRemoving`. The respawn path is the one tested live.

Pins remain session-local. No profile field, no schema change, no migration.

### 4. The bat ragdoll — NOT TESTED, and deliberately not touched

**This environment cannot launch two genuine clients.** `start_stop_play` starts a
single-player Play session; `list_roblox_studios` reports one instance with one
Client datamodel; Studio's Clients-and-Servers multi-client test is a UI action
MCP cannot invoke. `VirtualInputManager:SendTouchEvent` is also blocked
(`lacking capability RobloxScript`).

So the swing-to-hit PvP matrix — Rootwood, Mirewood, Comet against standing,
running, jumping, carrying, trapped and wall-adjacent victims — **remains
unverified**. Per the brief, a direct `ThrowVictim` call is not offered as proof
of the real path and none was made this session.

**No bat, guardian or ragdoll code was changed.** `git diff --name-only` touches
no combat file. Mirewood has no confirmed defect and nothing was tuned.

One relevant real observation stands from the previous entry: a genuine in-game
guardian catch during a steal settled naturally at 2.37s and stood up once, so the
guardian path is intact — but that is a guardian, not a bat.

### 5. Night system — verified

```
DAY    barrier transparency 1.00, non-collidable, screen off
       fog: 72 streamed, 0 visible, least transparent 1.000 -> road clear
NIGHT  fog visible at 0.68 | wall "09:39" vs HUD "09:39" -> agree exactly
       stars on the writing: 0
       after touring the whole corridor: 76 streamed, 0 still invisible -> no gaps
DAWN   driven through WorldCycleService.ForcePhaseNow, the module's own test door:
       phase Day, barrier transparency 1.00, screen off, 0 fog visible
```

Fog is built per-lane, so the field and plots carry none by construction.
`BiomeGateService` also logged the night ejection correctly while the corridor was
toured.

**Honest caveat on that dawn test:** `ForcePhaseNow` was called on an MCP-fresh
module copy, so it drove the barrier and fog through the real code but its nest
restock was a no-op — the log read `DAY 1. 420s. 0 nest(s) stocked`. The
barrier/fog half is genuine; a full natural warning → closure → dawn with
restocking was not observed.

Emulator timing from the previous entry stands and is not a phone verdict: the fog
cost +0.46 ms with all 80 masses in view on a desktop GPU at phone resolution. Fog
was neither removed nor increased on the strength of it.

### Validation

Ten specs pass via the fresh-require harness (SpeedSpec 332, WeaponSpec 107,
BatClearanceSpec 939/939, BatSwingSpec 93/93, CycleSpec 31, PlotSpec 65,
StarbloomLimbSpec 71, TutorialPodSpec 263, TutorialSpec 93, MillSignSpec clean).
`rojo build` passes, `git diff --check` is clean, and all three edited modules
plus the three other modal consumers (`ShopUI`, `IndexUI`, `GardenUI`) compile via
`loadstring`. Console carries no game errors — the single error in the log is my
own harness calling `LoadCharacter` from a client.

### Not covered

  * **A second phone-sized viewport.** Studio's emulator device is a UI selection
    and cannot be changed from a script; `ViewportSize` is read-only. The
    responsive path was instead proven by moving the panel through the rail band
    and watching the padding go 27 → 0 → 27, which exercises the same branch.
    A narrower device would produce a larger left pad and a non-zero right pad;
    the right-pad branch is therefore written and reasoned but not observed.
  * **Desktop was not re-measured directly** for the same reason. The guard test
    above is the evidence that it is unchanged.
  * Real finger input, two touches at once, and a drag competing with the
    thumbstick under real hardware.

### Files

`UIKit.luau` — header clearance in `modal`, and the close button's 44px target
with the plate inside it. `MarigoldShopUI.client.luau` — dropped the 34px
override, kept the ZIndex raise. `LoadoutUI.client.luau` — `cancelDrag` and its
three call sites.

## Hotbar of five, drag to pin, and a mobile pass over the steal loop — 2026-09-09 (CLAUDE)

Still on the device emulator: 735 × 413, `TouchEnabled`, and by this point
`MouseEnabled` and `KeyboardEnabled` had both gone **false**, so this was a
genuinely keyboard-and-mouse-less device rather than the half-emulated one of the
previous pass.

### The hotbar is five slots

It was ten, on the reasoning that ten is what the number row can address. That is
a KEYBOARD's reason. On a 735-pixel phone ten 64-pixel slots are ~700 pixels of
hotbar — the entire screen width. Five measures **344 px of 735**, which a thumb
can cross without looking.

Five is also smaller than most bags, so *which* five becomes a decision worth
making — which is what the drag is for.

### Plants drag from the bag onto it

`pinned[slotIndex] = key` is the player's choice; everything unpinned fills the
gaps in the existing bat/trap/plants order, so a bag nobody has arranged behaves
exactly as it did and a new pickup still appears. Two passes, consuming each tool
as it is placed, so two slots pinned to the same key show two different plants
rather than one twice.

Keyed by `Slot.key` — `p:<species>:<tier>:<hatched>` — not by Tool instance, so a
pin survives a respawn, which destroys and rebuilds every Tool.

**Empty slots are drawn now.** They used to be hidden, which was right when the
strip was only a list; it is wrong when an empty slot is the drop target, and a
drop target nobody can see is a feature nobody finds.

**Why the drop is even possible:** the bag's dimmer is ZIndex 1 and the hotbar is
4, and these ScreenGuis run `ZIndexBehavior.Global` — so the strip already drew
over the open bag. That is lucky rather than designed. The drag lifts it further
(60/61) so it is unmistakably the target, and puts it back afterwards.

**Tap and drag are told apart by whether the finger MOVED** (8 px). `Activated`
is not the tap detector any more: it fires on release over the button, which a
drag curving back would also satisfy, so both verbs would run. The guard clears
on the next frame, not immediately, because `Activated` fires *after*
`InputEnded`.

### The measurement that fixed it

The first version subtracted `GuiService:GetGuiInset()` from `InputObject.Position`,
reasoning that input is screen-space while `AbsolutePosition` is measured below
the topbar. **That is wrong**, and it silently broke every drop: the inset is 58 px
and a slot is 68 px tall, so the hit test landed in the gap above the strip and
found nothing. Measured against a known card:

```
input.Position   526, 217
card centre      526, 218      -- delta 0, -1
```

`InputObject.Position` is already in gui space. No conversion. (Note this is the
opposite of `AbsolutePosition`, which IS inset-relative — the trap recorded in the
previous entry. The two are not in the same space and neither is obvious.)

### Verified, on the emulated device

  * **Steal → carry → bank, end to end.** Four pods taken off nests via the real
    `Take` prompt and run past the red line: `banked 4 run(s) | plant tools now: 4`.
    Repeated for three more later.
  * **The guardian still works.** A steal woke the parent, which caught and threw
    the player: `HIT received: guardian ... speed 114.4`, `held the launch
    velocity for 0.35s`, `settled after 2.37s`, `down for 3.40s`. Natural, not
    forced — a real in-game guardian catch, which the bat work had never been
    tested against.
  * **The prompt is touch-correct.** With no keyboard it renders a `TAP` keycap
    and `TAKE`, not a key name.
  * **Drag pins.** Dragging a plant onto Slot1 (which held the Rootwood Bat) put
    the plant there with the pinned stroke, and the bat and trap flowed around it
    into 2 and 3.
  * **A re-drag MOVES.** Dragging the same plant to Slot5 left exactly one pinned
    slot and returned Slot1 to auto-fill. No duplication.
  * **A tap still holds.** Tapping a card put the tool in hand and created no pin.
  * Ghost destroyed and hotbar ZIndex restored after every drag.

Ten specs still pass.

### Found, not fixed

  * **The Bag's title is unreadable at phone width.** `SeedRail` has DisplayOrder
    40 against `SeedLoadout`'s 30, so INDEX and SHOP draw over the panel, and at
    735 px the panel is wide enough to run under them — the title reads "AG". The
    rail sitting above panels is deliberate; the collision is not, and it wants
    either a narrower panel or a title that starts clear of the rail.
  * **The close X is still 35 px** against Roblox's 44 px guidance, from the
    previous pass. Unchanged.

### Not covered

  * **Real touch input is still unverified by automation.** `VirtualInputManager:
    SendTouchEvent` is blocked in this sandbox (`lacking capability RobloxScript`).
    Synthetic mouse *is* delivered as `UserInputType.Touch` — verified with a probe:
    `CARDbegan:Touch`, 20 × `UISchanged:Touch`, `UISended:Touch` — so the code path
    exercised is the touch one. What is untested is a real finger, in particular
    two at once and the drag competing with the thumbstick.
  * **Pins are session-local.** Surviving a rejoin means a profile field, a schema
    version and a migration, which should not be decided by the feature that
    needed it first.
  * Plants banked in a Studio session are lost if Play is stopped inside the 45 s
    autosave window. That is Studio, not the game.

### Files

`LoadoutUI.client.luau` — `HOTBAR_SLOTS` 10 → 5, the `pinned` table and two-pass
fill, empty slots drawn, and the drag.

## Device-emulator pass on the night work — 2026-09-09 (CLAUDE)

Studio's device emulator, 735 × 413 landscape (16:9), `TouchEnabled = true`, top
GUI inset 58. This closes the two "not verified on mobile" items left by the
night screen and the biome fog, and turned up one usability defect.

**What this emulator does and does not prove.** It emulates RESOLUTION and INPUT.
It does not emulate a mobile GPU — the frame times below are a desktop card
drawing at phone resolution, so they bound the fill cost by pixel count but not
by throughput. A phone GPU is perhaps 5–15× slower at fill, so read the fog
number as "0.46 ms here, plausibly 2–7 ms there" rather than as a verdict.

### The fog costs almost nothing to draw

Measured with all 80 masses streamed in (character parked at Z = −900 by day so
every lane loaded), frame TIME rather than fps because both cases sit on the
60 fps cap, and with 2.5 s of settling after each camera move:

```
down the whole road          fog off 16.66 ms (60) | on 17.12 ms (58) | +0.46 ms
inside a bank, looking out   fog off 16.72 ms (60) | on 16.67 ms (60) | +0.00 ms
```

**The first attempt at this measurement was wrong and is worth recording.** It
reported 14.9 fps with fog off and 15.1 with it on — a scene-independent number,
which a control caught: pointing the camera at empty sky gave 20.5 fps while the
full road gave 60. The low readings were the camera move and streaming settling,
sampled immediately. Any frame-rate number taken inside two seconds of a camera
move in this harness is noise.

### The night screen reads at phone size

The wall's timer measures **66 screen px tall, 16% of the viewport height**, from
a player's eye at the field edge — computed with `WorldToViewportPoint` against
the label's real extent, then confirmed by photograph. Caption, timer and footer
are all legible, and the HUD clock agrees with the wall to the second.

### Nothing of ours is off screen

An inset-aware audit of every drawn GuiObject across all 14 ScreenGuis found two
items outside the viewport, and both are Roblox's own `DynamicThumbstickFrame` —
which is meant to be, being an oversized touch region.

**The first version of this audit produced a false positive worth remembering.**
It flagged `SeedWorldClock` as entirely off the top of the screen. It is not:
that ScreenGui sets `IgnoreGuiInset = true`, and `AbsolutePosition` is reported
in inset-relative space, so a plate sitting 8 px below the true screen top
correctly reads as Y = 8 − 58 = −50. The legal Y band differs per ScreenGui:
`-inset .. viewportY - inset` when the inset is ignored, `0 .. viewportY - inset`
when it is not.

### The Bag is fine on touch

Opened by tapping the rail button through the emulator, so this is the real input
path, not a function call.

  * Panel 520 × 291 — 71% × 82% of the screen, with margins.
  * 17 tappable cards, smallest 64 px, all clear of Roblox's 44 px guidance.
  * Rendered text 11–26 px throughout.

### FOUND: the shared close X is under the touch-target minimum

`UIKit.modal` builds the close button at 38 px, but every panel carries a
`UIScale` — measured at **0.920** on this viewport, with a `UISizeConstraint` of
min 248 × 240 — so it renders at **35 × 35**. Roblox's own guidance is 44 px.

It is a comfort defect, not a break: tapped through the emulator at 35 px it
closed the panel correctly. But it affects **all five panels**, since the close X
was promoted into `UIKit.modal` in `f62c54f`, and the scale is viewport-derived,
so a smaller phone renders it smaller still.

**Not fixed, deliberately.** The button works, and its appearance was signed off;
enlarging it changes a shared visual across five panels, which is more than a
test pass should decide on its own. The fix, when wanted, is not simply "38 → 44":
the panel's UIScale would take 44 down to 40.5 here and further on a smaller
screen, so the size has to be compensated against the live scale — which `UIKit`
can do, since it owns both the modal and the scale. The glyph itself would not
change: `Mark` is a fixed TextSize 22 child, so only the red plate grows.

### Still not covered

  * A real phone. Everything above is a desktop GPU at phone resolution.
  * Hover behaviour on a real touch device. The emulator leaves
    `MouseEnabled = true`, so `UIKit.pointerIsMouse()` still reports a mouse and
    the rail's hover pop is NOT suppressed here the way it would be on hardware.
    That gate is unexercised by this pass.
  * The 45-second `BIOMES CLOSE IN` window with players legitimately inside the
    fogged corridor.

## Fog in the biomes at night — 2026-09-09 (CLAUDE)

At night the corridor is shut, emptied and covered by the barrier — and from
INSIDE it, looking down the road, everything was still perfectly legible.
Measured at night from Greenhollow: the Dustbowl arch, its `RECOMMENDED 167M
SPEED` plate and the decor beyond all read clearly at three hundred studs. The
world was closed and did not look closed.

Each lane now carries four banks of fog, four masses to a bank — 80 across the
whole road — which fade in with the night and out with the dawn.

### It is a look, and the wall is still the rule

The banner on `NightTransparency` is emphatic that concealment cannot depend on a
look, because a player can turn their graphics down. **Nothing here is
load-bearing.** The barrier is still opaque and collidable, `BiomeGateService`
still puts anybody past the road mouth back in the field ten times a second, and
the nests are still emptied at dusk. A client drawing none of this would be no
more able to get in, and there is nothing left in there to see.

That is also why the fade is **entirely client-side**, like the night lighting
beside it: `MapService` builds every mass at `Transparency = 1` and never touches
it again, and `WorldClock` is the only thing that makes them visible.

### Why geometry and not `FogEnd`

The one thing this map may never do is haze the road — being able to stand at the
safe line and see five biomes receding IS the progression display, which is why
`applyLighting` shuts off both `FogEnd` and the `Atmosphere` instance. Global fog
also cannot be aimed: it would grey the FIELD too, where people plant and harvest
all through the night, and `WorldCycle.Night` exists precisely to keep the plots
usable.

Banks of parts sit only where they are put. **Verified**: at day the road is clear
end to end, photographed from the safe line through the Dustbowl gate to the far
wall, with 0 of 51 streamed masses visible and the least transparent reading 1.000.

### The depth does the work

One bank is a haze; the far end of the road is behind twenty of them. That is the
shape real fog has and it falls out of stacking rather than being tuned — which
is why the per-mass number moved only from 0.72 to 0.68 to make the first gate
unreadable, since eight deep that is 0.036 of the light through against 0.072.

It rides the existing `blend`, the single number that already carries the night
lighting, so fog and darkness arrive together and a phase that flips back
mid-fade reverses both.

### Two things found by measuring rather than by looking

**`Workspace.StreamingEnabled` is TRUE here.** The first version collected the
tagged parts once and re-collected only when the first had lost its parent.
Measured in a real session, a client standing in Greenhollow at night holds only
51 of the 80 masses — Emberroot 3 of 16, Starbloom none at all. A cached list
misses everything that streams in afterwards, and a missed mass is not a dim one,
it is an **invisible** one, because the server builds them at `Transparency = 1`
and the client fade is the only thing that changes that. Running down the road
would have opened clean holes in the fog exactly where the player was heading.

It is driven by `GetInstanceAddedSignal` / `GetInstanceRemovedSignal` now, and a
mass that arrives is faded to the live blend immediately rather than waiting for
the next phase change. Verified by removing and re-adding the tag on a live part
— which is exactly what a stream-in looks like locally: `0.720 → 1.000 (as built)
→ 0.720` within a frame.

**Blocks, not Balls.** A Roblox Ball renders at the diameter of its SMALLEST axis,
so a 90 × 40 × 30 "cloud" would come out a 30-stud marble. Blocks are also right
for this game, which is blocky studded plastic everywhere else.

The first render also let masses reach above the 46-stud wall line, where they
stood against the open sky as exactly what they are — rectangles. Contained under
`wallH * 0.92` now: highest top measured at 42.3, 0 above the wall, so the strip
of night sky over the road stays clear.

### Verified

Ten specs pass, `rojo build` passes, all three files compile.

In a running session, photographed from the same camera before and after: the
Dustbowl arch went from crisply legible with a readable Speed plate to a faint
smudge with the corridor beyond it gone, while the ground and trees at the
player's feet stayed clear. Day/night both ways: 80 masses built invisible on the
server, faded to 0.68 on the client at night, back to 1.000 at dawn with the road
clear end to end.

### Not verified

  * Mobile fill rate. 80 large transparent parts is real overdraw, and looking
    down a fogged corridor is the worst case for it. It is mitigated by where a
    player can legally BE at night — from the field the opaque barrier occludes
    the lot, so it costs nothing from the only place anybody should be standing —
    but nobody has measured it on a phone.
  * A natural dusk. Night was forced by publishing the phase attributes; the
    cycle loop sleeps in one long `task.wait` and a real dusk is seven minutes
    away. The fade path exercised is the same one either way — `blend` reads the
    attribute — but the 45-second `BIOMES CLOSE IN` warning window, where players
    are still legitimately inside the corridor with the fog rolling in, has not
    been watched.

### Files

`GameConfig.luau` (`WorldCycle.Fog`, and the `BiomeFog` tag), `MapService.luau`
(`buildBiomeFog`, called from `buildSegment`), `WorldClock.client.luau` (the
streaming-safe list and `applyFog`, folded into `applyLight`).

## The night barrier is a screen now — 2026-09-09 (CLAUDE)

The wall that shuts the road at dusk was a flat dark-blue slab 164 by 60 studs.
At that size a flat slab does not read as "the road is shut for a minute", it
reads as the world having run out — and nothing on it said what had happened or
how long it would last. The only place that said either was the one-line HUD
clock at the top of the screen, which a player walking INTO the thing is not
looking at.

The face that meets the field is now a night sky with the countdown on it.

### What it is

`MapService.buildNightScreen` paints a `SurfaceGui` on the barrier: a vertical
gradient sky (darkest at the zenith, lifting to a horizon glow), 74 star Frames
scattered across the upper two-thirds, a moon with a haze around it, and three
lines of text — `THE ROAD IS CLOSED`, the timer, `PODS RETURN AT DAWN`.

  * **Built with the map**, so it is re-run safe for free: `MapService.Init`
    destroys the SeedMap folder and builds it again, which is this project's
    answer to Rule 10 everywhere else.
  * **Static on the server, countdown on the client.** The sky never changes, so
    it is made once and replicates as ordinary instances. The number is driven by
    `WorldClock` on each client from the `WorldPhaseEndsAt` attribute that was
    already there — a server writing that string thirty times a second would
    replicate it to every player to tell them something they can already work out.
  * **One `left`, two readouts.** `WorldClock` already computed the remaining
    seconds for the HUD; the wall is formatted from the same number in the same
    function, so the two can never disagree.
  * **Stars are Frames, not a texture.** This map is built entirely in code and a
    starfield would otherwise be the one image it had to own, upload and version.
    A fixed seed (`StarSeed`) means every client and every rebuild gets the same
    sky, so a screenshot today is comparable with one next month.

### It does not weaken the barrier

The banner on `NightTransparency = 0` is emphatic that concealment cannot be a
matter of degree — an 8% transparent barrier once leaked the biome arch's unlit
name plate straight through it. None of this changes that. The part stays opaque
and collidable at night; the SurfaceGui paints its near face; nothing behind it
became any more visible. `LightInfluence = 0` is the same property that caused
that old leak and is safe here for the opposite reason: it is drawn ON the opaque
face, not behind it.

`MapService.SetNightBarrier` toggles `SurfaceGui.Enabled` along with the wall,
because **a SurfaceGui is not hidden by its part's Transparency**. Leaving it on
would hang a lit night sky with a stopped clock in mid-air over the field for the
whole seven-minute day — the one failure of this feature that would be visible
from every plot at once. Verified in all three states: a fresh map is Day with
the screen off, night turns both on, dawn turns both off again.

### Two things measured rather than assumed

**The face is `Back`, not `Front`.** `NormalId.Front` is −Z and this corridor runs
toward −Z: measured in the built map, Starbloom's end wall is at Z = −1675 while
the plots are at −57.8 and the barrier at −168. Players stand at higher Z, so the
face they can see is +Z. Getting this backwards costs nothing at build time and
shows a blank wall to every player.

**The moon had to be sized in pixels.** It was `UDim2.fromScale` and rendered as a
vertical PILL: the canvas is 164 studs by 60, so equal scale on both axes is 2.7
times as many pixels across as down. A circle cannot be specified in scale on a
surface that is not square. Sized off the canvas height in offset now, and
verified square at 55 × 55.

The first render also had the caption and the timer reading as near-equals — a
headline with a subtitle rather than a countdown with a label. The timer is
0.42 of the wall height now against the caption's 0.105.

### Verified

Ten specs pass (unchanged: 939/939, 93/93, 31, clean, 65, 332, 71, 263, 93, 107).
`rojo build` passes and all three edited files compile.

The screen was built and photographed in Edit against the **real edited source**,
fetched over http and loaded with a fresh require chain — see the warning below
for why that was necessary. Sky, stars, moon, all three lines and the day/night
toggle confirmed by eye and by property.

### Verified in a running session

The Rojo plugin was reconnected and the whole thing was tested in Play, on the
map the real server built.

  * **The countdown ticks, and the two clocks agree.** Sampled once a second on
    the client: `00:45, 00:44, 00:43 ... 00:38` against a deadline falling
    `45.3s ... 38.2s`. Photographed at player eye height with the wall reading
    `00:46` while the HUD read `00:46`.
  * **The warning colour lands.** At 30s left the timer is the pale ink
    `236,242,255`; at 8s it is `255,206,120`.
  * **Dawn takes the screen with it.** `SetNightBarrier(false)` left
    `enabled false, transparency 1.00, collide false, query false`, and the
    photograph shows the Greenhollow arch and the open corridor with no floating
    sky and no ghost timer — the failure this was most at risk of.
  * The screen is built by the **running server**, not by an Edit-mode helper:
    74 stars, face `Back`, 8 px/stud, and a fresh map starts in Day with the
    screen off and the timer empty.

**One thing the first render got wrong, found by eye.** The caption read
`THE ROAD IS.CLOSED`. That is not a typo: a star had landed in the gap between
the two words, and at three pixels on a dark sky a star is a full stop. The band
could not fix it — the caption sits at 0.245 and the timer at 0.52, both well
inside the part of the sky that should have stars — so there is a keep-out box
around the text column now, with capped rejection sampling. Re-measured: 74 of
74 stars kept, 0 on the writing, and the caption reads cleanly.

**A note on reading a client-drawn label from the server.** The timer text reads
as `""` in the Server datamodel forever, because `WorldClock` writes it on the
client and a client's local write does not replicate up. That is the same lesson
as `PlatformStand` in the bat work, and it is worth remembering before anybody
concludes the countdown is broken: read it from the Client datamodel.

Still unobserved:

  * Mobile. 74 Frames plus a gradient is cheap and static, but it has not been
    looked at on a phone.
  * A natural transition. Night was driven by publishing the phase attributes and
    calling `SetNightBarrier` directly, because the cycle loop sleeps in one long
    `task.wait` and a real dusk is seven minutes away. The barrier half of
    `toNight`/`toDay` is exactly the call that was exercised; the nest emptying
    either side of it was not, and was not touched by this change.

### Files

`GameConfig.luau` (`WorldCycle.Barrier.Screen` — palette, star count and seed,
captions, the "soon" colour), `MapService.luau` (`buildNightScreen`, the call,
the `SetNightBarrier` toggle), `WorldClock.client.luau` (resolver and the big
timer, driven from the `left` it already had).

## The bat ragdoll, rejected and repaired: it falls over now — 2026-09-09 (CLAUDE)

### What was rejected

The owner tested `147535c` with two real players and rejected it. Observed: the
victim **automatically stands up**, does **not visibly fall or stay knocked
down**, and does **not look like a guardian hit**.

The authoritative requirement is the guardian's *physical language*, not its
scale: limbs go limp, the body falls or tumbles, it contacts the ground, it
remains visibly down briefly, then it gets up once.

### Two causes, and the second one was the real one

`147535c` assumed a bat "lands almost immediately -- it is a shove, not a
flight". Measuring all six bats on a live client disproved it twice over.

**1. Recovery ran on a clock, not on a landing.** `VictimLimpSeconds` was an
absolute deadline from the hit, and a deadline cannot tell whether a body has
fallen. Rootwood measured: the victim genuinely reached the ground at 0.47s and
lay flat (torso up-vector −0.12), and the deadline then stood them up at 1.14s.
**That is 0.39 seconds of lying on the floor.** The fall was real and nobody
could see it.

**2. A bat was not guaranteed to fall over at all.** The tumble is built from
`math.random(-6, 6)` -- an INTEGER draw, so both axes that tip a standing body
can come out ZERO on the same hit. A guardian never noticed because it throws
hard and high enough to rotate regardless. The Cactus Club has the lowest lift
on the shelf (0.35), and with a near-zero tipping draw it measured:

```
cactus_club   touched down 0.63s, lowest torso up 0.86, EMERGENCY at 3.02s
```

0.86 is **a body still standing**. It went limp and slid eighteen studs upright
on its feet. The old code stood it up at 1.1s and called that a hit.

A third mechanism was found, instrumented, and turned out **not** to be the
cause here: `CombatService` disables the constraints and fires the remote in the
same frame on two unordered channels, so the impulse can land on a rig the
animator still holds in its standing pose. Measured in Studio it replicates in
**0.001s**, so it was not what the owner saw -- but it is real on a network, and
the gate for it is cheap. Reported honestly rather than claimed as the fix.

### The repair

**Recovery is now four things that must have HAPPENED**, none of them a duration:

  * **touched** -- a downward ray from the *visible torso* found floor. Not the
    root: while limp the root is an invisible box that flies off on its own,
    measured once at 148 studs away, and it is not what the player watched land.
  * **fell** -- the torso's up-vector went past 0.55 (about 57° off vertical).
    Tracked as the LOWEST value reached, not sampled at the end, because a body
    can land hard, roll, and come to rest half-propped against a wall.
  * **held** -- it stayed down for `VictimKnockdownHoldSeconds`, timed from the
    CONTACT rather than the hit, because the contact is the moment the player
    sees.
  * **slow** -- still necessary, no longer sufficient.

**The topple is guaranteed.** For a bat the spin about the horizontal axes is a
random DIRECTION with a guaranteed MAGNITUDE (8–12 rad/s) instead of a draw that
can be zero. Angular velocity is not linear velocity, so the launch is
untouched. Guardians keep the integer draw.

**Tumble scale 0.55 → 1.0.** Halving the guardian's spin was the wrong half of
it to turn down; the spin *is* most of the physical language. The three things
that make a guardian a guardian are still off or down: no camera, stepped 0.6
studs clear instead of 3, launch from the power ladder.

**A readiness gate before the launch** (bat only, so guardian tuning is
untouched): wait up to 0.4s for all 15 constraints disabled AND the rig split
into separate assemblies -- a posed R15 is ONE assembly, verified live, so a
torso still sharing the root's assembly is a torso still held in its standing
pose. On timeout it launches anyway and says so; the landing loop still requires
a real fall, so a late limp still produces a real fall.

**Durations.** `VictimLimpSeconds` is gone -- a number whose meaning had
evaporated:

```
VictimMinLimpSeconds       1.4   floor from the hit (was 0.9)
VictimKnockdownHoldSeconds 0.5   from GROUND CONTACT, not from the hit
VictimEmergencySeconds     3.3   client failure containment
VictimBackstopSeconds      3.7   server failure containment
VictimPostRecoverySeconds  0.4   protection at the instant they stand
HitImmunitySeconds         1.5   unchanged
```

**The emergency exceeds the 2.5–3.0 the brief suggested, deliberately.** The
Comet throws its victim 127 studs and ~1.9s of that is FLIGHT, which is launch
speed and lift -- both locked. At 3.0 the top of the ladder had 0.38s of margin
and a victim landing off a ledge would have spent it and been emergency-recovered
on a hit that was working. 3.3 gives it 0.68s. It is not the animation: it fired
on none of the six bats.

**Post-recovery immunity.** Until now the only immunity was counted from the hit,
which is unsound once a ragdoll has no fixed length. `flying` makes a victim
untargetable for the whole tumble however long it takes, and 0.4s is applied with
`math.max` at the instant the token clears -- so there is no frame on which a
victim is both upright and free. That closes the two-attackers-standing-over-you
case.

**`147535c`'s token work is intact**: one server-minted token per launch,
exact-token acknowledgement via `WeaponData.AcceptsAck`, stale and duplicate
reports rejected, a newer client generation supersedes an older task safely, one
cleanup owner, one RagdollOn/RagdollOff pair. No bare boolean, no silent
`if throwing then return`.

### Measured — all six bats, live client, real server ordering

`RagdollOn` then `FireClient` in the same frame, exactly as `knockBack` does.

```
bat            launch  lift  ready   touched  lowest up  recovered  down    travel
rootwood        25.0   0.50  0.000s  0.74s    -0.01      natural    1.45s    16.8
cactus          35.0   0.35  0.001s  0.72s    -0.00      natural    1.47s    20.6
sunflower       47.5   1.05  0.001s  1.00s    -0.00      natural    1.60s    39.6
mirewood        62.5   0.40  0.001s  1.08s    +0.01      natural    1.65s    45.3
cindercrack     80.0   0.45  0.001s  1.15s    -0.62      natural    1.77s    55.6
comet          100.0   0.62  0.000s  1.88s    -0.35      natural    2.48s   127.0
```

Every bat toppled past horizontal. **No emergency, no slide, on any of them.**
Weakest 1.45s, strongest 2.48s; the grounded portion went from 0.39s to
**0.66–0.95s**. Travel rose ~10% (rootwood 11.8 → 16.8) because a spinning body
rolls further after it lands -- the launch impulse is byte-identical.

Cactus, the case that failed: `3.07s EMERGENCY, lowest up 0.86` → `1.47s natural,
lowest up −0.00`.

**Guardians unchanged**, both branches, same session:

```
hold=nil   stepped 6.0 (+3.0) | camera -> 12.0..128, subject Head
           "held the launch velocity for 0.35s"  (LEGACY_HOLD)  down 6.45s
hold=0     stepped 6.0 (+3.0) | camera -> 12.0..128, subject Head
           "one impulse; back on the arc 0 times" (CLEAN_GUARD) down 6.42s
```

Bats never touch the camera: `zoom 0.5..128.0 -> 0.5..128.0, subject Humanoid ->
Humanoid` on every hit.

**Respawn during ragdoll**: comet launched, `LoadCharacter()` at 0.8s mid-flight.
New character came back with 15/15 constraints enabled, 1 assembly,
PlatformStand false, WalkSpeed 96.3, Jump enabled, state Running. The abandoned
task produced no `LANDING`, no `settled`, no `done` and no error -- it returned
silently at its next await, as designed. Client log: 79 entries, 1 warning, and
that warning is the pre-existing ShopUI "nothing is for sale" notice.

### Automated

Ten specs pass; WeaponSpec 102 → 107. `rojo build` passes, `git diff --check` is
clean, all four files compile via `loadstring` in Edit, and `WeaponData` was
executed so the retuned load-time ordering asserts actually fired.

### NOT verified — the owner's acceptance test

**Everything above drives `ThrowVictim` directly from the server.** It reproduces
the real ORDERING and it is a far better test than the previous pass, but it is
still not a swing: no `trySwing`, no arc resolution, no `targetsFor`, no real
`knockBack`, and no second player watching. Per the brief it is **not acceptance
evidence**. `DebugService`'s 16 actions cannot trigger a hit and `targetsFor`
excludes the swinger, so a second client is the only way.

Still to be observed by the owner, two clients, comparable camera angles:

  * The nine-point visual checklist, and a guardian hit alongside for comparison.
  * Victim running / jumping / carrying a pod / inside a trap / beside a wall.
  * Second hit after recovery, and two attackers swinging close together.
  * That pod-drop-before-launch and trap-release-before-launch still hold (both
    are server-side and untouched by this pass, at `CombatService` lines 778 and
    onwards).

Open risks:

  * **The Comet is 2.48s**, above the brief's suggested 2.2s ceiling. Its flight
    alone is 1.9s and launch distance is locked, so the only lever is the ground
    hold. If 2.48s reads as a stun, lower `VictimKnockdownHoldSeconds` toward
    0.35 -- that is the one number to touch, and it is asserted to stay in
    0.35–0.55.
  * **Travel is ~10% further** on the weaker bats because the guaranteed spin
    makes a landed body roll. If that matters, it is the topple magnitude
    (`TOPPLE_MIN`/`TOPPLE_MAX` in ThrowFX), not the launch.
  * The readiness gate has only ever been measured at ~0.001s on localhost. Its
    behaviour under real latency is unproven; if it ever times out the log says
    so in as many words.

### Files

`WeaponData.luau` (durations, style terms, load asserts), `CombatService.luau`
(backstop retune, post-recovery immunity), `ThrowFX.client.luau` (readiness gate,
landing-based recovery, guaranteed topple, bounded slide, emergency logging),
`WeaponSpec.luau` (107). `NestService.luau` untouched.

## The bat ragdoll: a launch token, and four durations instead of two — 2026-09-09 (CLAUDE)

### The cause

`WeaponData.Combat` had ONE number, `VictimLimpSeconds = 1.1`, doing two jobs:
what the victim should feel, AND the deadline at which `CombatService.knockBack`
restored the rig. The victim's client could not answer inside it. Measured from
the code, `ThrowFX` needed:

```
0.30  CLEAN_GUARD, the ballistic guard after the impulse
0.90  minFlightTime, before it would even look at settling
0.35  SETTLE_HOLD, of continuous stillness, in 0.08 steps
----
1.55  earliest possible "I have stopped"   against a 1.10 deadline
```

So the server timed out on EVERY hit, restored the body while the client was
still flying it, and the client ran on for about another second. Two further
things fell out of that, and both were reachable in ordinary play:

  * **A stale report released a newer launch.** The acknowledgement was
    `FireServer()` with no arguments and the handler was
    `if flying[player] then flying[player] = false end` — so a report from an
    already-abandoned throw ended whatever had replaced it.
  * **A legitimate hit was silently discarded.** Immunity expires at 1.5s but the
    client held `throwing = true` until roughly 2.5s, and `if throwing then
    return end` dropped the packet. The server had already ragdolled the victim,
    taken their walk speed and dropped their pod. **That is the limp-without-fling:
    a victim who goes down and does not move.**

### The protocol

One token per accepted launch, minted server-side, carried in the style table
that no guardian sends, and quoted back by the client.

  * `flying[player]` **is** the token now, not `true`. Every `if flying[x] then`
    guard is unchanged and reads the same, and it closes a second hole: the ack
    used to write `false`, which is FALSY, so for up to 0.05s between the report
    and the backstop task waking, a victim read as not-flying while another task
    still owned their ragdoll. A second `RagdollOn` there would have taken an
    EMPTY constraint set and left them limp permanently.
  * The rule lives in `WeaponData.AcceptsAck(live, quoted)` rather than in a
    closure inside `CombatService.Start()` — **so that a spec can reach it.**
    Type-checked before compared, per AGENTS.md rule 4.
  * `WeaponData.BatThrowStyle(token, serverNow)` builds the payload. `deadline`
    is an ABSOLUTE `Workspace:GetServerTimeNow()` instant, because a duration
    would start counting after the wire time — the exact error the grace budget
    exists to absorb. `minLimp` is a duration on purpose: it is a floor on what
    the victim SEES, so it starts when their machine starts drawing it.
  * A guardian sends no style, so token, kind, minLimp and deadline are all nil
    and every one falls back to the constant that was there before. The guardian
    path is **defaulted, not branched.** Its acknowledgement carries nil, fails
    `AcceptsAck`, and can no longer end a bat launch — while `NestService`'s own
    handler, which reads no arguments and never did, is untouched. **NestService
    was not edited.**

### Four durations, and their order is the contract

```
VictimMinLimpSeconds  0.90   floor: the client will not stand before this
VictimLimpSeconds     1.10   the client's deadline (was also the backstop)
VictimBackstopSeconds 1.35   NEW. the server's safety net, and nothing else
HitImmunitySeconds    1.50   unchanged
```

Asserted at load in `WeaponData` and again in `WeaponSpec`, including the 250ms
of round-trip grace — ten milliseconds would satisfy the ordering and still be
the original bug. The backstop must also stay UNDER immunity: `targetsFor`
filters out anybody still marked flying, so a hit landing between the two would
be silently discarded.

### The client no longer drops a launch

`if throwing then return end` is replaced by a generation counter. **The newer
launch wins**: the superseded task returns at its next await without restoring
the pose, the camera or the flag. Camera zoom/mode/subject moved into a
`pristine` record captured by the first throw of a chain and restored by the
last — per-throw capture would have recorded this file's own 12-stud zoom floor
as the player's preference on a second hit. A respawn bumps the generation too;
clearing `throwing` alone never stopped the old task, which was reading the
character it had captured, not the flag.

A packet this file cannot use (malformed, or no character) now quotes the token
back rather than returning silently, so the server restores on the next tick
instead of on a timeout.

The nine-line per-100ms stand-up watch is guardian-only now. It is a diagnostic
for a throw that happens once a raid; a bat hit happens every few seconds from
every player at once.

### Verified — AUTOMATED

All ten specs pass. `WeaponSpec` went 80 → 102 assertions; the 22 new ones cover
the duration ordering, the round-trip grace, immunity against the BACKSTOP
rather than against the tumble, and `AcceptsAck` against live / stale /
duplicate / nil / number / table / empty-string reports.

```
BatClearanceSpec 939/939   MillSignSpec  clean   PlotSpec          65/65
BatSwingSpec      93/93    SpeedSpec     332     StarbloomLimbSpec 71/71
CycleSpec         31       TutorialSpec  93/93   TutorialPodSpec   263
WeaponSpec       102/102
```

`rojo build` passes, `git diff --check` is clean, and all four files compile via
`loadstring` in Edit. `WeaponData` was executed rather than only compiled, so the
new load-time ordering asserts actually fired.

### Verified — SINGLE-PLAYER PLAY, by driving the real remote

Not a simulation: `ThrowVictim` was fired at a live client with each of the three
payload shapes, and these are that client's own log lines.

```
bat                stepped 1.4 clear (+0.6 up) | camera 0.5..128 -> 0.5..128,
                   subject Humanoid -> Humanoid | one impulse across 17 parts
                   settled after 1.13s (forced) | DOWN FOR 1.14s | 21.2 studs
guardian, hold=nil stepped 6.0 clear (+3.0 up) | camera -> 12.0..128, subject
                   -> Head | held the launch velocity for 0.35s  (LEGACY_HOLD)
                   settled after 5.45s | down for 6.38s | stand-up watch present
guardian, hold=0   stepped 6.0 clear (+3.0 up) | camera -> 12.0..128, subject
   (Astralmaw)     -> Head | one impulse, back on the arc 0 times (CLEAN_GUARD)
                   settled after 5.33s | down for 6.24s
```

**All three branches select as intended, and the bat never touches the camera.**

**Preemption, proven live.** Token AAA fired, then token BBB 0.4s later while
AAA was still flying: both launched, and exactly ONE `settled` and ONE `done`
appeared — BBB's, at 1.13s. AAA's task returned silently without standing anyone
up. Under the old code BBB would have been discarded and the victim would have
gone limp without moving. Console clean, no errors, and the ack for a token no
launch held was ignored in silence.

### NOT verified — needs two players, and is the remaining risk

Everything above drives the remote directly, which exercises the whole CLIENT
half and none of the server's own path. **A real bat hit has not been observed.**
Nothing in `DebugService`'s 16 actions can trigger one and `targetsFor` excludes
the swinger, so a second client is required. Still to observe:

  * The measured PlatformStand duration for a REAL hit, which adds the server
    round trip for `RagdollOff` on top of the 1.14s measured here. Expect roughly
    1.2–1.3s against the 1.35s backstop.
  * Trap release before launch, and the pod dropping at the hit position.
  * The ten-case matrix in the brief: standing / running / jumping / carrying /
    trapped / beside a wall / repeat hit after immunity / two attackers / dying
    mid-recovery / leaving mid-recovery.
  * Travel range for the weakest and strongest bats (Rootwood measured at 21.2
    studs synthetically; Comet is 4x the launch speed and unmeasured).

One known, accepted degradation: a player whose round trip exceeds 250ms will
trip the backstop and log
`"<name> never reported landing (<token>); restored by the backstop"`. That is
benign — the client then finds the constraints already enabled and stands up
immediately — but it is the one path where the server still finishes first.

### Files

`WeaponData.luau` (durations, AcceptsAck, BatThrowStyle, load-time asserts),
`CombatService.luau` (token, payload, backstop, ack handler, cleanup),
`ThrowFX.client.luau` (generation, deadline arithmetic, settle bounds, pristine
camera, tokenised ack), `WeaponSpec.luau` (+22). `NestService.luau` untouched.

## The test suite runs clean again — 2026-09-09 (CLAUDE)

All ten specs in `tools/tests/` pass. `SpeedSpec` had been THROWING rather than
failing for a long time, and that is the whole story of this entry: a throw stops
at the first bad line, so every check below it stopped being reported while still
looking present in the file. Drift accumulated behind it invisibly, and each fix
only revealed the next piece.

Fixed, in the order they surfaced:

  * `GameConfig.overclockUnlockOrderFor` — called at 2 sites. The function never
    existed; overclock has no biome gate, which `GameConfig.Mill.Overclock` says
    outright. Removed, with a comment saying so.
  * The `O.UnlockedBy` block — 3 assertions against a table that never existed.
  * `biome.SpeedGate` → `biome.RecommendedSpeed`, 6 occurrences.
  * `GameConfig.Carry.MaxKg` → `Carry.TopTierValue`. Kilograms became size tiers,
    so `carryMultiplierFor` takes a TIER VALUE now. `for tier = 0, nil` was the
    throw that had been hiding everything below line 476. The local `maxKg` and
    the 20 `kg` loop variables were renamed with it — holding tier values in
    variables named `kg` is the same two-names-for-one-fact problem the codebase
    warns about repeatedly.
  * Sections 9 and 10 — rewritten, not patched. See below.
  * The overclock rate table — 6 expectations, every one out by a factor of
    250,000. They were written when the top mill ran at 1600/s; it runs at 400M/s
    now and the ladder is ten tiers rather than seven.
  * `SeedData.CarryMultiplier(500)` vs `carryMultiplierFor(500)` — not the same
    question. SeedData takes a tier INDEX and passes that tier's `.value` on, so
    500 meant "tier 500, clamped to Colossal" on one side and "a pod of value
    500" on the other. Asked over the whole ladder now, because the risk being
    guarded against is a SECOND carry curve appearing, and a second curve that
    agreed at one sample would have passed the old check.

### The afterimage sections tested a deleted effect

Sections 9 and 10 asserted seven tiers named "First Echo" through "Rainbow
Ascension", each rendering up to four cloned character limbs at a spacing in
studs. `GameConfig.Afterimage` drives ONE Trail per character now, ten tiers
deep, with new names, new thresholds and new columns.

Ten of the fifteen `Afterimage` fields those sections read no longer exist
(`LocalMaxGhosts`, `RemoteMaxGhosts`, `MobileMaxGhosts`, `CarryReducedGhosts`,
`CarryReducedSpacing`, `CarryReducedFade`, `MoveStudsPerSecond`, `ColourHz`,
`MobileColourHz`, `BodyHueSpread`). That is not repairable field by field, so
both sections are rewritten against the ribbon. The old expectations are NOT
kept as comments: the config's own history section already explains why the
echoes went, and a spec carrying a second account of it is a second thing to
keep true.

What the new sections assert, all of it grounded in what the config already
promises in prose:

  * The ten thresholds and names, at each threshold and one below it.
  * `Lifetime`, `WidthStuds` and `HeadTransparency` strictly monotonic 1→10 — the
    guarantee the ghost ladder could not make once its count capped at four.
    HeadTransparency runs the other way (lower is more solid), which is written
    down where somebody would otherwise "fix" it.
  * `LightEmission` climbs 1→9 and then tier 10 gives it up, asserted as a
    REQUIREMENT rather than tolerated — a Void Singularity quietly corrected back
    onto the ramp would delete the one moment the ladder is built to arrive at.
  * `Wave` and `Shimmer` are set by THEME, not by rank, so the inversions are
    asserted to EXIST. The config says in as many words not to correct them into
    a ramp; a spec that merely permitted non-monotonic values would pass just as
    happily after somebody did.
  * No tier carries a `Rainbow` flag — the deleted column must stay deleted.
  * Every tier fully dressed: palette of 2+ Color3s, complete particle emitter.
  * The carry bands at their real edges (0.92 / 0.55, not the old 0.75 / 0.50),
    and a maximum pod silent at every one of the ten tiers.

Also fixed: `CycleSpec` asserted "exactly one biome is live" where the design
allows several; it is "at least one" now and passes with 31 assertions. And
`GameConfig.luau` had a comment reading "Speed multiplier when carrying MaxKg"
directly above `MinMultiplier`, describing the current field by its old name —
the one stale `MaxKg` reference in `src/` that was actively misleading rather
than historical. The four in `SeedData.luau` are prose about the weight-roll
curve's history and were left alone.

Verified by running all ten specs through `tools/tests/run.luau` in Edit:

```
BatClearanceSpec   939/939        MillSignSpec       geometry clean, drift 0.000000
BatSwingSpec       93/93          PlotSpec           65 passed, 0 failed
CycleSpec          PASS -- 31     SpeedSpec          PASS -- 332 assertions
StarbloomLimbSpec  71 passed      TutorialPodSpec    263 checks passed
TutorialSpec       93 passed      WeaponSpec         80 passed
```

`SpeedSpec` went from throwing at line 476 to 332 passing assertions. No
production behaviour was changed by any of this: the only `src/` edit is the one
comment above.

### `Players.MaxPlayers` is set to 6 — stop re-raising it

The owner has set it. It is a place setting a script cannot change, and older
entries in this file still list it as an open action item; it is closed.

One thing to know before anybody "re-checks" it and reopens it again: the Studio
**Edit** datamodel reads `Players.MaxPlayers = 60`, because that is the local
place file's copy, not the live server configuration. The boot check at
`ServerMain.server.luau:136` compares `Players.MaxPlayers` against
`GameConfig.MaxPlayers` (6) and warns only when the two differ — so a live server
reads 6 and stays quiet, while a Studio playtest still prints the 60-against-6
warning off the stale local value. That warning is a Studio artifact now, not a
live bug.

## The close X is every panel's now — 2026-09-09 (CLAUDE)

The Bag's restyled close button moved from `LoadoutUI` into `UIKit.modal`, so
Index, Shop, Garden, Bag and Marigold's stall all draw the same one from one
place. The local copy in LoadoutUI is deleted rather than left as a second
version to drift out of step with the first.

`GameConfig.Panel.Close` -- the flat `rgb(255,0,0)` sampled off the reference
shot -- is replaced by `CloseTop` / `CloseBottom` / `CloseShade`. Nothing else
read that field, so there is no stale reference anywhere; the sampled value is
kept in the comment as the record of where the button came from.

It is now the same four things every other button in this game is made of: a lit
face, a darker foot, a shade bar and a black keyline. The X is a child label
because a UIStroke on a TextButton strokes its BORDER, and only one UIStroke per
object is honoured -- there is no way to outline the glyph while the button also
keeps its keyline.

Verified in Play: all five panels report gradient + shade + outlined mark with an
empty button Text; clicking the Index X closed it and left every other panel
closed; the Bag is visually unchanged now that it draws the shared version;
console 0 errors; rojo build clean.

## Bag panel visual polish — 2026-09-09 (CLAUDE)

Appearance only. One file, `LoadoutUI.client.luau`; no behaviour, no gameplay, no
inventory logic touched, and nothing outside the Bag.

**The cards got their backplate, and the old note explaining why they had none is
now the record of the reversal rather than a contradiction.** That note argued a
plate turns a bag into a grid of tiles when what a player scans for is the shape.
It is answered rather than ignored: the plate is a low-contrast brown and the
item stands in a WELL cut into it, so the silhouette is still the brightest thing
on the card.

Five layers per card, bottom to top: the gradient-lit plate, a one-pixel `Lip`
along the top edge (the whole difference between a rectangle and a raised
surface), a darker `PreviewWell`, an inset green `LitRing` shown only when
equipped, then the words.

**Equipped says itself three times** -- the card warms toward green, a green ring
appears inside the keyline, and the state button fills green. One alone is a
shade difference on a 104px card. The black keyline deliberately does NOT change:
it is the house edge on every surface in the game, and swapping it for green
would make an equipped card a different kind of object rather than the same card
in a state.

**Browns are steps off `GameConfig.Panel`, not new colours.** Panel fills at
(58,38,29) and shades at (38,25,19); cards sit lighter, wells sit darker, so the
three read as one surface with things set into it.

**The body became a tray.** It was a transparent hole, so four items floated over
four hundred pixels of nothing. Sunk into a dark well with a black keyline, a
faint lattice (0.93 against the panel's 0.55) and a 40px top-edge shadow, the
same space reads as a tray with room left in it. Nothing moved to achieve it.

Also: grid padding evened to all four sides (it was right and bottom only); names
use `TextScaled` with a 9pt floor so "CINDERCRACK BAT" gives up a point instead
of pushing into the button; the state pill became a real button -- gradient,
black keyline, shade bar -- matching the shop's pill language rather than
inventing a second one; tabs gained gradients and an active-only shade bar; and
the close X was restyled -- gradient red with an outlined glyph. It shipped in
LoadoutUI for one commit and has since moved into `UIKit.modal`; see the entry
above.

**One near-miss worth recording:** removing the now-unused `PICKED` gold broke
the HOTBAR, which still uses it two hundred lines down. Luau parsed clean because
an undefined local reads as a global; it would have thrown at runtime on the
first held slot. Restored with a comment saying who owns it now.

Verified in Play: both tabs, the equipped and unequipped states, the empty-state
message, card geometry with no overlap (well 74, name 30, button 20, 9px bottom
margin), console 0 errors, rojo build clean. Test clicks changed the live loadout
and it was put back to Cindercrack Bat + Bramblejaw Trap as found.

## Rarity pills, state pills, and Gloomlotus's missing aura — 2026-09-09 (CLAUDE)

**Garden rarity pills.** The card's `sub` line printed `RarityForTier`, which
despite its name returns the TIER -- "COLOSSAL", "GIANT". The weight tag in the
corner already said "7 tier", so the card spent both word slots on the same fact
and never once said whether a plant was Common or Mythic. It now carries the
SPECIES rarity in the `GameConfig.RarityColor` palette the Index already uses,
boxed by a new `setSubPill` on `UIKit.plantCard`. Nothing was lost: the tier is
still on the tag above it.

The pill tints its EDGE, not its fill -- a filled pill in Mythic pink behind pink
text is a smear. It sizes off `sub.TextBounds` so it hugs "RARE" and
"UNDISCOVERED" alike, and it is OFF by default: the sub line also carries
countdowns and instructions, and only a rarity is a label worth boxing.

**Bag state pills.** `EQUIPPED` / `TAP TO EQUIP` were 11pt muted text on a
transparent card -- the one thing a player must read to know what pressing it
does, and the quietest thing on the card. Now a pill that hugs the words, with
the rim picking up `lit` so equipped and unequipped differ by more than a shade
of grey.

**Gloomlotus had no aura, and the cause was architectural.** `SeedData` describes
it as carrying "a Neon halo, a Glass dew jewel, two emitters and a Highlight, and
that budget is the rarity". It had the halo and the jewel and NEITHER of the
other two -- measured: 0 emitters, 0 Highlight, 0 lights, identical to a Common
Nubkin, while Pyrelotus had 4 emitters and Supernovus 1.

Emberroot and Starbloom build their Mythics in CODE, so `pyrelotus(parent, at)`
can make Attachments and ParticleEmitters as it goes. Tanglemire is a DATA table
of PartSpecs replayed by `replayPart`, and a PartSpec can only become a BasePart
-- there was no way to say "emitter" in the format the approved geometry is
stored in, so the two that were designed never shipped.

`retrofitGloomAura` adds them after the replay, which is exactly what
`retrofitMireEye` beside it already does for this biome. Two emitters as
specified -- a slow wide Haze that hangs, and sparse bright Motes drifting
through it -- plus a Highlight rimming the crown alone. Both run
`LightInfluence 0` / `LightEmission 1`, because a rarity tell that only works in
good light is no use in the dim biome. About 40 live particles, an eighth of
Pyrelotus.

Verified in Play: gloomlotus now builds `AuraHaze` + `AuraMotes` (both enabled)
and one Highlight adorned to `Premium_CrownHalo`; nubkin still builds none. The
Garden showed 20 pill frames with 9 visible on the 9 grown plants -- LEGENDARY
gold, MYTHIC pink, EPIC purple, RARE blue -- with all 9 tier tags still present.
The Bag showed 4 state pills sized 87x17 and 65x17, green rim on EQUIPPED and
muted on TAP TO EQUIP. Console 0 errors; rojo build clean.

## The rail is two kinds of button — 2026-09-09 (CLAUDE)

Final shape, after the owner narrowed the previous change: **Index and Shop keep
their slabs; Garden and the Bag are bare.**

`UIKit.railButton` takes a `bare` flag. Bare builds a transparent `ImageButton`
with the artwork filling all 50px and asks for its own `UIKit.clicks`; otherwise
it builds a `UIKit.slab` exactly as it always did -- face, shade, gradient,
lattice, corner, outline, a 28px icon and the word beside it. Same footprint for
both: 130x50 and 50x50, so nothing moved and no touch target shrank.

**Garden and the Bag are FILLED artwork again**, back on their original uploads:

| icon | id | note |
| --- | --- | --- |
| Shop | `rbxassetid://90931969678136` | slab |
| Index | `rbxassetid://126806966970007` | slab |
| Garden | `rbxassetid://106268245303506` | bare, filled |
| Inventory | `rbxassetid://135554729755251` | bare, filled |

The knocked-out pair (`131355079577116`, `124800563254633`) are superseded and
unused. Knocking the fills out was right while those two sat on a plate the same
colour as themselves; with no plate there is nothing to clash with, and a hollow
icon on a bare button is just the world showing through -- which is what made
them look colourless. The SVG masters and PNGs were restored from `7540ba2`
rather than re-cut, so the drop shadows came back with them.

`RAIL.IconSize` (28, on a slab) and `RAIL.IconBare` (50, when the artwork is the
button) replace the short-lived `IconWide`/`IconSquare`.

Verified in Play: Index and Shop carry Corner+Stroke+Gradient+Lattice with 28px
icons, labels and the Index badge; Garden and Bag have none of that, background
transparency 1.00 and 50px icons; all four icons loaded; Index -> Shop -> Garden
-> Bag each opened its own panel; all four back to UIScale 1.000 after hovering
every one, one UIScale each; console 0 errors; rojo build clean.

## The rail lost its slabs — 2026-09-09 (CLAUDE)

At the owner's direction the icon IS the button now: no background, not inside a
square. `UIKit.railButton` no longer builds a `UIKit.slab` -- the coloured face,
the gradient, the lattice, the rounded corner and the black outline are all gone,
leaving a transparent `ImageButton` carrying the artwork.

**Same footprint on purpose.** 130x50 and 50x50 as before, so all four buttons sit
exactly where they were and the touch targets did not shrink -- an icon is easier
to miss than a plate, and shrinking the target too would have been two
regressions for one change. The icon grew to fill what the slab used to: 50 on a
square button, 40 on a wide one. 40 because the label needs the rest -- "Index"
measures 62px at 22pt LuckiestGuy and a 40px icon leaves it 66; 44 leaves exactly
62 and 50 clips it. Measured, not guessed.

`UIKit.slab` is NOT deleted -- the plant card's action button still uses it. Its
`UIKit.clicks` was providing the rail's click cue, so that call moved into
`railButton` rather than disappearing with the slab.

`RAIL.IndexFace`/`ShopFace`/`GardenFace` and their shades are kept though nothing
reads them: they are what each icon was drawn in, so the colour identity moved
into the artwork rather than being lost, and those values are the record of it.

The Shop and Index words survive with no plate behind them, carried by their own
2.5px black outline -- the same bet CashUI already makes with the cash and speed
numbers on grass and sky.

**Known consequence, flagged:** Garden and Inventory were knocked out to outlines
in the previous change, so with no slab behind them the game world is visible
through the planter and the satchel. Shop and Index are still solid artwork and
are unaffected. Re-filling those two is a one-word edit per path in the SVG
masters if it reads badly in motion.

Verified in Play: four transparent ImageButtons, no stroke/gradient/corner/lattice
left on any of them; icons 40/40/50/50 all loaded; Index -> Shop -> Garden -> Bag
each opened its own panel; badges still at Index 129,-1 and Garden 889,-1; all
four back to UIScale 1.000 after hovering every one; after respawn one SeedRail,
one copy of each button, one UIScale and one Icon each; console 0 errors; rojo
build clean.

## Rail button vector icons — INTEGRATED 2026-09-09 (CLAUDE)

Codex's asset note below is now complete: the four PNGs are uploaded and wired.

| button | asset | id |
| --- | --- | --- |
| Shop | `art/ui/rail-icons/shop.png` | `rbxassetid://90931969678136` |
| Index | `art/ui/rail-icons/index.png` | `rbxassetid://126806966970007` |
| Garden | `art/ui/rail-icons/garden.png` | `rbxassetid://131355079577116` |
| Inventory | `art/ui/rail-icons/inventory.png` | `rbxassetid://124800563254633` |

**Garden and Inventory were re-cut as outlines** at the owner's direction and
re-uploaded; the ids above are the second pair (the filled first pair,
`106268245303506` and `135554729755251`, is superseded). Each icon was drawn in
its own button's colour family, and for these two that collided with the button:
the planter's amber `#FFC95A..#D77B22` on a `#ECA034` button, the satchel's
leather `#D89A59..#7A4328` on a `#C4945C` one. Their bodies are now `fill="none"`
in the SVG masters so the button shows through, leaving the dark keyline, the
cream stroke and the coloured accents. Shop (cream on green) and Index (white on
blue) never had the problem and were not touched.

The drop shadow came out of those two files with the fills. `feDropShadow` paints
behind the element, so with a transparent interior it showed THROUGH the icon and
smudged the area that is meant to be reading as button colour -- confirmed by
rendering both ways before choosing. The unused `bed`/`soil`/`leather`/`flap`
gradients are left in the masters so re-applying a fill is a one-word edit.

There is no SVG rasteriser on this machine (no cairosvg, rsvg, inkscape or
ImageMagick -- `convert` on PATH is Windows' disk tool). Re-exporting the edited
masters needed one, so a small renderer covering exactly the subset these files
use lives at `scratchpad/svgrender.py`. It was validated by rendering `shop.svg`
and `index.svg` and diffing against their existing trusted PNGs: index matched to
1.31/255 mean colour and 0.33/255 mean alpha, garden and inventory matched
visually. Shop's scalloped awning is beyond it, which did not matter -- shop was
not re-exported.

Uploaded from `<name>-128.png`, 128px reductions of the 512 exports. They draw at
28 and pop to 30, so 128 covers a 3x phone with headroom at a sixteenth of the
memory. Ids live in `GameConfig.Rail` (`ShopIcon`, `IndexIcon`, `GardenIcon`,
`BagIcon`) — no literals in UI scripts.

**Rendering was confirmed before use**, not just `IsLoaded`: a throwaway proof
strip drew all four at 50px button size in Play and was screenshotted, then
destroyed.

`UIKit.railIcon` builds the ImageLabel: `ScaleType.Fit`, `Active = false`, and it
reads its own placement off the button — a wide button insets it 10px left where
`iconBox` put the drawn one, a square button centres it where `sproutIcon` did.
The slab remains the only clickable thing.

**The drawn helpers are still live and were not deleted.** `cartIcon`, `bookIcon`
and `sproutIcon` each appear twice — rail button and modal title bar — and only
the rail half was replaced. The satchel was the one icon with no second home (the
Bag modal's title bar carries no icon), so its nine inline frames are gone.

**Hover pop** is wired once inside `UIKit.railButton`, so all four get it and no
call site can double-wire it. Measured on ShopButton: ENTER -> 1.080 in ~0.09s ->
settles 1.040 in ~0.09s -> HOLDS 1.040 for 1.5s with no pulsing -> LEAVE -> 1.000
in ~0.09s. Five rapid flicks all returned to exactly 1.000, one UIScale
throughout. Gated on `MouseEnabled` AND `GetLastInputType` being a mouse, so
touch never pops; suppressed entirely when `SeedAfterimageQuality` is `Off`
(verified: scale stayed 1.000 while hovering).

Verified in a fresh Play session: all four icons render; Index -> Shop -> Garden
-> Bag each opened the right panel and closed the previous; two clicks inside an
open panel left it open; badges unmoved (Index 129,-1 top-right, Garden 785,-1
top-left, both half off the corner as designed); clicking 30ms into the tween
opened the panel at scale 1.040; after respawn exactly one `SeedRail`, one of
each button, one UIScale and one Icon each; console 0 errors; `rojo build` clean.

## Rail button vector icons — ASSETS READY 2026-09-09 (CODEX)

Four transparent, icon-only SVG masters and matching 512 x 512 PNG exports are
ready under `art/ui/rail-icons/`: Shop is a green market stall, Garden is an
amber raised bed with a sprout, Index is a blue plant almanac, and Inventory is
a brown satchel. The silhouettes, dark outline, cream separation stroke and
lighting language are shared, while each icon keeps the current rail button's
colour identity. All PNGs were rendered from the SVGs with alpha intact and
remain readable when sampled at the live 28 px icon size.

This pass is ASSET-ONLY. No Roblox UI source or Studio state changed. On
integration, upload the PNGs through the existing verified image pipeline and
record the returned asset ids in shared configuration. Replace only the rail
button icon drawings: keep the existing code-built slabs, Shop/Index labels,
Garden/Index badges, click targets, hover feedback, modal behaviour and layout.
Do not delete `UIKit` icon helpers that are still used in modal title bars, and
do not replace title-bar artwork unless separately approved. Use `ScaleType.Fit`
with transparent images so the parent button remains the interaction owner.

The original raster references in `art/rail-shop.png`, `art/rail-index.png` and
`art/rail-slab.png` were consulted only to preserve identity; the new art is not
a traced copy. Visual approval and live mobile-size integration remain pending.

## Three reported bugs — FIXED 2026-09-09 (CLAUDE)

**Every panel closed when you clicked its contents.** `UIKit.modal` set
`shell.Active = true` with a comment saying it consumed the click. It never did,
and the bug reached Index, Garden, Loadout, Marigold and Shop alike -- it only
became obvious once shop cards started popping on hover and inviting a click.

Two things combined. The ScreenGui is `ZIndexBehavior = Global`, where ZIndex is
compared as a raw number across the whole tree, and Shell sat at 1 -- the same
number as the dimmer, so it never sorted above it. And even level, an ACTIVE
FRAME does not stop a GuiButton underneath from firing `Activated`; only another
GuiButton does. Raising `Shell.ZIndex` was tried and measured: still broken.

The fix is an invisible `ClickBlocker` TextButton at ZIndex 2 inside the Shell,
with no handler -- swallowing the click is the whole job. Measured: card body
click lands on the blocker, dimmer fires only for a click outside the panel, buy
buttons and scrolling unaffected.

**Feet were buried in the soil.** Every part of a plot bed is `collide = false`,
so a player walked at FIELD level (Y 0) while the soil they stood in reached
0.68. Only the fence posts and rails were solid; nothing in the bed was.

The soil itself cannot be made solid -- frame, slab, rows and clods are four
heights, so a player would trip over furrows, and the slab is what the placement
raycast is aimed at. So MapService now builds one invisible `BedWalk` pad level
with the row tops. Measured: feet 0.680 against a 0.680 surface, zero
penetration, FloorMaterial Plastic.

**Nothing visible moved**, which matters more than it looks: PlantService anchors
every saved plant to `soil.CFrame * CFrame.new(x, soil.Size.Y * 0.5, z)`, so
shifting that surface would lift or sink every garden ever saved.

**The placement disc was buried.** It sat at slab-top + 0.06 = 0.56, but the
SoilRow strips lying on that slab stand 0.18 proud of it at 0.68 -- so the disc
was a tenth of a stud inside the soil it was meant to lie on, invisible except
over the bare furrows. Now cleared over the rows: spans 0.680-0.800, clearance
+0.000.

**One regression caught in test, not shipped.** The new pad shares its top
surface exactly with SoilRow, so the placement ray can land on either, and
`CanQuery = false` is not enough at an exact tie. `PlantPlace.BED_PARTS` did not
list `BedWalk`, so wherever the pad won the ray the bed became unclickable --
`soilPoint` returned nil, the ghost vanished and nothing reached the server to
explain why. `BedWalk` is whitelisted now. The server needed no change: it has
no part whitelist and clamps any world position into the planter.

Console clean, `rojo build` clean.

## x2 Money buff indicator — INTEGRATED 2026-09-09 (CLAUDE)

Codex's art note below is now out of date on its last paragraph: the asset is
uploaded and the indicator is built.

`art/icons/x2_money_buff.png` is live at `rbxassetid://111194752241888`, uploaded
from a tight-cropped 256 square copy (`art/icons/x2_money_buff-256.png`) — it
draws at 46px, and a 1254px texture for a 46px icon is memory nobody sees.
Recorded in `GameConfig.Pass` alongside `BuffSize`, `BuffMessage`, `BuffSeconds`
and `BuffFade`, so the words a player is shown are data rather than a literal
buried in layout code.

Built inside the existing `CashUI.client.luau`; no second HUD controller, no
remote, no poll. It listens to `GetAttributeChangedSignal("CashMultiplier")` and
shows only while `GameConfig.cashMultiplier(player) > 1`. It is COSMETIC: it
reads the attribute the server publishes and never reports or decides a payout.
`EconomyService` and `PassService` are unchanged.

The card is placed off `amount.TextBounds.X` every time the cash string changes,
so it stays beside a number whose width moves between `$1.2K` and `$914.77T`.
The Shoe, Speed and Cash lines do not move at all — measured identical before
and after at (12,439), (68,434), (12,490).

The message clamps left when it would overrun: with the card at offset 146 the
line sits at 143, and both card and message finish inside the HUD's own 340px
footprint, so this adds nothing to the existing narrow-screen overflow.

`CashUI` now tracks its connections and drops them on `gui.Destroying`. It did
not need to before — every connection wrote to something inside the GUI, where a
handler firing at a destroyed label is harmless. This one attaches to the PLAYER,
which outlives the GUI, so a second run would have left the first run's listener
attached.

Verified in Play: card absent at multiplier 1; appears 0.062s after
`DebugService.SetPass`; one click shows the exact line and four rapid clicks give
one show and one hide 2.70s after the LAST click (2.5s hold + 0.25s fade) with a
single label throughout; revoking removes card and message in 0.050s; survives
respawn as one instance; cash and speed keep updating; console clean; `rojo build`
clean.

**Shop pass card resized.** At the owner's direction it is no longer a banner
spanning the shelf (584 x 389) but one grid cell, byte-identical in size to a
SPEED tile — measured 188x161 and 158x135 at two panel widths, equal both times.
The rest of the PASSES row is deliberately empty for the passes still to come.
That also retired the banner's measuring pass; a grid cell has a definite size,
so the 3:2 artwork keeps its shape with an aspect constraint that cannot go
circular the way the old `AutomaticSize` shelf did. The keyline moved from the
cell to the artwork — on the cell it drew a box with 18 empty pixels above and
below the picture. Hover pop and click shake still measure 1.070 and 5px on it.

## x2 Money owned-buff HUD icon — 2026-09-09 (CODEX, ART ONLY)

Owner requested a small persistent buff card beside/below the bottom-left Cash
HUD so pass owners can see that x2 Money is active. Generated and inspected
`art/icons/x2_money_buff.png`: two emerald money bundles, gold bands and one
gold `x2` badge, no background/card/particles/extra decoration. It is a genuine
RGBA cutout (1254 square, corner alpha 0); copy verified by SHA256. Exact final
prompt: `output/imagegen/shop/x2-money-buff-icon-v1.prompt.md`. The first render
was rejected because its checkerboard was baked opaque and was not saved.

Pending integration belongs in existing `CashUI.client.luau`. Show a small
native clickable card only when the local player's server-published
`GameConfig.Pass.MultiplierAttribute` (`CashMultiplier`) is greater than 1.
Listen to the attribute rather than introducing a remote or polling ownership;
this visual must never be an authority for payout. On activation, show the exact
small information line `Earn x2 money permanently.` above the icon, then hide it
after a short readable interval; repeated clicks restart the one message rather
than stacking labels/connections. Preserve the current cash/speed placement,
phone safe-area readability and re-run cleanup. The image asset is not uploaded
and no UI/gameplay/entitlement code was changed in this art pass.

## x2 Money pass — INTEGRATED 2026-09-09 (CLAUDE)

Codex's note below is now out of date on one point: integration has been done.

`art/shop/x2-money-card-v2.png` is live at `rbxassetid://114365661955846`
(uploaded from a controlled 1024-wide LANCZOS copy,
`art/shop/x2-money-card-v2-1024.png`). It is a **banner** shelf — one wide 3:2
card, not a grid of tiles — sized in `relayout()` alongside the tile cells. A
`UIAspectRatioConstraint` inside an `AutomaticSize.Y` shelf was tried first and
resolved the card to 0 x 0; that cycle is documented in ShopUI.

**It is a Game Pass, not a Developer Product.** `PassService` (Priority 22) asks
`UserOwnsGamePassAsync`, caches per session, never saves ownership, refreshes on
`PromptGamePassPurchaseFinished`, and slow-re-asks non-owners every 90s to catch
website purchases. Nothing is asked while the id is 0. `StoreService` skips any
row carrying a `pass` field, so the pass can never reach the receipt ledger.

**The x2 applies to `EconomyService.RateFor` and nowhere else** — the last line
of the plant faucet. Measured live: 78,322/sec -> 156,644/sec -> 78,322/sec.
Bag sales, Robux cash packs, plot/mill/weapon refunds and debug grants all reach
`AddCash` by other routes and are unaffected.

Clients read `player:GetAttribute("CashMultiplier")` via
`GameConfig.cashMultiplier` so the garden footer, the per-plant `/s` tag and the
`+$N` pops show what is actually banked. The server never reads that attribute
back; `EconomyService` asks `PassService` directly.

**Still owner's to do:** create the Game Pass, put its id and price into
`GameConfig.Store.Items.Passes`. Until then the card reads SOON and the button
refuses (verified with three real clicks, zero errors).

`DebugService.SetPass` (Studio/owner only) toggles pretend ownership so the
entitlement path stays testable before the id exists.

Also done in this pass, as instructed: PASSES sits above SPEED, PREMIUM PODS is
now headed `???`, and the shop's PLANTS section is removed — section, item list
and `ComingSoon` entry. Garden, Index and player plants are untouched.

## x2 Money shop card artwork — 2026-09-09 (CODEX, ART ONLY)

**Superseded artwork:** use `art/shop/x2-money-card-v2.png`, not v1. At the
owner's direction, v2 removes the decorative corner foliage, coins, rays and
sparkles, reduces the hero to two broad money bundles, and uses a nearly solid
emerald field. It adds the exact permanent-benefit line
`PERMANENT • EARN ×2 MONEY` beneath the title while retaining calm lower-right
space for the native purchase control. Exact edit prompt:
`output/imagegen/shop/x2-money-card-v2.prompt.md`. The source output was copied
without replacing v1 and verified by SHA256. Integration remains unperformed.
The owner has now defined the benefit as permanent, so integration must use a
Game Pass ownership entitlement rather than the store's repeatable Developer
Product receipt path. Price and Game Pass id are still undecided/unset.

Owner requested an original x2 Money card for a new top shop section, with
Claude to perform integration later. Generated and visually inspected
`art/shop/x2-money-card-v1.png`: 3:2 emerald/gold card, sprouting money bundles,
large x2 MONEY lettering and clear lower-right space for a native price/button.
Exact built-in image-generation prompt: `output/imagegen/shop/x2-money-card-v1.prompt.md`.
Original output preserved and copied asset verified by SHA256.

Owner's pending UI instructions: put this above SPEED, rename PREMIUM PODS to
`???`, and remove the PLANTS section from this storefront only. Do not remove
Garden/Index plants or player plants. Price, entitlement type/id and multiplier
scope are not yet specified; no price or permanence claim is baked into the art.
No upload/id, shop integration, purchase logic, economy change or Studio test
was performed in this art pass. Card crop/readability in the real UI still needs
verification; Claude should use a real button, not treat painted artwork as one.

## DUSTBOWL STATIC CARD BACKGROUNDS — 2026-09-08 (CODEX, ASSETS ONLY)

Owner requested five missing Dustbowl background-only scenes for restored static
model cards. Generated with the built-in image tool and visually inspected:
`art/cards/backgrounds/<species>-background-v1.png` for dunebud (sheltered dunes),
paddlehop (cactus wash), thornwhorl (ravine), raincup (wet basin), suncrown (sunset
mesa). Quiet centres reserved for the real plant models. No creature, text or
border baked in. Exact prompts: `output/imagegen/cards/backgrounds/`.

No uploads or integration; no new asset IDs. Actual card crops and contrast
remain to be tested in integration. Existing artwork preserved. No Studio,
UI source, gameplay or save changes. Remaining three biomes/15 backgrounds
are outside this batch. Uncommitted/unpushed; shared work preserved.

> Living document. **Read this first when picking up the project. Update it before ending any
> session, then commit and push** (see the git policy in [CLAUDE.md](../CLAUDE.md)).
>
> [PLAN.md](PLAN.md) is what we are building and in what order. [BLUEPRINT.md](BLUEPRINT.md) is the
> reference design. This file is where things actually stand.

---

> **STATE, 2026-09-08.** Committed and pushed through the card work. On top of
> that, uncommitted: the plot upgrade moved out of the shop onto a board by the
> gate, and the shop became a Robux storefront.
>
> **Nothing in the shop can be bought yet.** Every `product` in
> `GameConfig.Store` is 0 because a Developer Product id can only be created in
> the Creator Dashboard. Each tile still draws, reads SOON and refuses; filling
> an id in is the only change needed to make one live. `StoreService` says so at
> boot and `ShopUI` warns as well.
>
> **The pod products are FIXED, not rolled** -- each names a species and a tier.
> That is a compliance position: a rolled pod would be a paid random item, which
> the experience questionnaire currently answers No to. Do not make them random
> without changing that answer.
>
> **Known beta blockers**, in order: shared guardian rage makes the tutorial
> theft unwinnable on a busy nest; nothing has been tested on a phone despite
> "mobile first"; `Players.MaxPlayers` is 60 against 6 plots (PlotService queues
> the overflow, so it is a bad first impression rather than a fault).
> `SpeedSpec` and `CycleSpec` still fail for reasons that pre-date all of this.

## REDESIGN INDEX / ALMANAC PLANT CARDS — 2026-09-08  (UNCOMMITTED, READY FOR REVIEW)

> Follow-up, Codex 2026-09-08: the owner rejected the animated-model cards.
> Three STATIC illustrated artwork samples are now generated with the built-in
> image tool: `output/imagegen/cards/{nubkin,suncrown,supernovus}-illustrated-sample-v1.png`,
> with exact generation prompts alongside. These are unapproved artwork, NOT
> uploaded assets and NOT wired into either UI. Existing art/cards backdrops
> are untouched. References were captured from actual built Tiny models in
> Edit; the temporary CardReferenceCapture folder was removed and camera restored.
> The samples preserve the broad identities but are stylized interpretations,
> not a certified exact anatomy match (especially Supernovus limb visibility
> and Suncrown ray counts). Review those and actual UI crop readability before
> approval. No IndexUI/GardenUI or gameplay source changed in this art pass;
> no profiles touched, no commit or push. The prior text-to-image blocker applied
> to Claude's session, not this session. Next: owner sample approval or revisions,
> then real asset upload and the static ImageLabel Index/Garden implementation.

The Index / Almanac modal plant cards have been redesigned from flat icon tiles into
rich, atmospheric collectible showcases with live 3D creature models, species-specific
biome backdrops, subtle idle floating, and animated rarity text for Legendary and
Mythic species.

### SCOPE & ISOLATION

* **Only one file modified**: `src/StarterPlayer/StarterPlayerScripts/IndexUI.client.luau`.
* **Zero changes to shared UI**: `GardenUI.client.luau` and `UIKit.luau` (`UIKit.plantCard`,
  `CARD` palettes) were untouched. The Index now uses an internal, self-contained
  `buildIndexCard` function tailored specifically for showcase cards.
* **Zero changes to gameplay or simulation**: `CreatureModel`, `SeedData`, `BiomeData`,
  `GameConfig`, economy, inventories, combat, and saves are untouched.

### 25 DISTINCT PROCEDURAL BACKDROPS

Every species in the game now has a dedicated visual identity in `SPECIES_BACKDROPS`,
combining rich sky gradients, atmospheric glowing halos, layered horizon silhouettes,
biome motifs, and floating environmental particles:

* **Greenhollow** (Meadow, Sun, Canopy, Twilight):
  * *Nubkin*: Sunny dewdrop pasture with rolling clover slopes and floating pollen motes.
  * *Petalpip*: Vibrant floral bloom garden with cherry blossom petals and warm morning mist.
  * *Bramblebite*: Thorny berry thicket with dusk twilight gradients and prickly bush silhouettes.
  * *Snapthorn*: Shadowed bramble grove with jagged thorn barriers and deep emerald hues.
  * *Bellchime*: Sunlit cathedral canopy with golden dawn halos, ancient trunks, and floating golden spores.
* **Dustbowl** (Desert, Canyon, Salt Flats, Dunes):
  * *Duneshroom*: Baked sandstone ridges with drifting dust motes.
  * *Rustleaf*: Red clay canyon cliffs with hot amber gradients.
  * *Sandspire*: Bleached salt flats with mirage shimmer and distant spire silhouettes.
  * *Thornhopper*: Weathered scrub plains with dry thistle bushes and baking heat glow.
  * *Suncrown*: Blinding solar zenith with blazing corona rays and shimmering gold heat waves.
* **Tanglemire** (Swamp, Murk, Deep Bog, Bioluminescence):
  * *Gloomspore*: Murky bayou dusk with dripping moss willows and floating neon swamp motes.
  * *Murkmoss*: Toxic bog shallows with stagnant algae layers and phosphorescent mist.
  * *Mirefang*: Mangrove swamp tangle with winding root arches and deep cypress silhouettes.
  * *Bogdrifter*: Eerie deep marsh with glowing lily pads and will-o'-the-wisp embers.
  * *Lanterncap*: Midnight swamp hollow with radiant lantern halos and rising bioluminescent spores.
* **Emberroot** (Volcanic, Cinders, Magma Chamber):
  * *Cinderpaw*: Smoking basalt ledge with crackling ember sparks and orange magma glow.
  * *Emberspit*: Flowing lava cascade with jagged obsidian crusts and rising soot motes.
  * *Ashthorn*: Volcanic ash plain with charred caldera silhouettes and drifting grey embers.
  * *Kilnhusk*: Burning furnace crevasse with radiant core glow and molten slag silhouettes.
  * *Pyrelotus*: Superheated magma vent with swirling fire spirals and incandescence.
* **Starbloom** (Astral, Cosmic Void, Nebula):
  * *Astralhorn*: Twilight starlight crest with crescent nebula curves and silver stardust motes.
  * *Cosmospire*: Void aurora night with deep ultraviolet nebulas and vertical starry spires.
  * *Pulsarling*: Pulsing violet ion storm with radiant starburst arcs and ion particles.
  * *Gloomlotus*: Velvet event horizon with dark astral lotus petals and ethereal magenta haze.
  * *Supernovus*: Cosmic singularity eruption with stellar rings, brilliant cyan/gold rays, and hyper-dense starlight.

### PRODUCTION 3D PLANT MODELS & DYNAMIC AUTO-FRAMING

* Built using the real production pipeline: `CreatureModel.Build(species, SeedData.BaseTier, CreatureModel.STAGE_GROWN, CFrame.new(), into)`.
* Each model rests upon a circular pedestal tinted to the species' canonical soil colour (`species.Soil`).
* Viewport camera uses `FieldOfView = 36` with bounding-box auto-framing:
  * `targetHeight = size.Y * 0.54 + extent * 0.38`
  * `distance = math.clamp((targetHeight / 2) / math.tan(rad(fov / 2)) * 1.05, 10, 48)`
  * Dynamically scales from 11.5 studs (Nubkin) to 34.1 studs (Supernovus), ensuring compact creatures fill the frame comfortably while massive spires never clip the edges.
  * Camera elevated at 13.5 degrees looking at `cf.Position + Vector3.new(0, size.Y * 0.44, 0)` with a subtle 3D showcase perspective.

### PREVIEW ANIMATION & PERFORMANCE

* **Subtle preview movement**: Gentle sinusoidal hovering (`math.sin(t * 1.5 + phase) * 0.04`), micro-tilt (`math.sin(t * 1.1 + phase) * math.rad(1.2)`), and floating ambient motes with pulsing transparency. Absolutely no frantic 360-degree spinning.
* **Lifecycle management**: A single `RenderStepped` loop is connected only while the Index modal is open (`setOpen(true)` connects, `setOpen(false)` disconnects and frees handles).
* **Viewport culling**: Inside `update(dt, t)`, each card tests its `AbsolutePosition.Y` against `Cards.CanvasPosition` window. Cards outside the visible scroll window skip all model CFrame and gradient calculations.

### ANIMATED RARITY TEXT

Rarity typography accurately reflects `SeedData.Rarities`:
* **Legendary** (*Suncrown, Lanterncap, Kilnhusk, Astralhorn*):
  * Polished metallic gold sheen.
  * An animated `UIGradient` sweep periodically glints across the text: runs `Offset.X = -1.0` to `+1.0` over 1.1s, then rests for 1.1s.
* **Mythic** (*Gloomlotus, Pyrelotus, Supernovus*):
  * Prismatic celestial iridescence with a 5-stop cosmic palette (rose-crimson, violet, ethereal cyan, magenta, rose).
  * Continuously shifting phase and slight angle oscillation (`math.sin(t * 1.8) * 6`).
* **Epic** (*Snapthorn, Bellchime, Thornhopper, Mirefang, Bogdrifter, Ashthorn, Pulsarling*):
  * Deep amethyst/royal purple with subtle breathing luminescence (+/- 12% brightness over 2.4s).
* **Common / Uncommon / Rare**:
  * Clean, crisp static typography with bold dark outline stroke for readability.

### DISCOVERY PRIVACY

* If `discovered == false`, the card remains a flat silhouette:
  * Model parts set to `Color = GHOST (Color3.fromRGB(155, 162, 172))` and `Material = SmoothPlastic`.
  * Title displays `"???"`, subtitle `"Undiscovered"`.
  * Backdrop replaced with neutral dusk grey gradient (`CARD.DuskTop` to `CARD.DuskBottom`).
  * All species-specific landscapes, motifs, halos, and particle motes are hidden. Zero biome clues or silhouettes are leaked.

### VERIFICATION

* **Compilation**: `rojo build -o build/StealASeed.rbxlx` succeeded cleanly (code 0).
* **Runtime**: Tested in live Studio Play mode; zero console warnings or errors.
* **Animation verification**: Verified via live Studio inspection that:
  * Production models bob gently (`math.sin(t * 1.5 + phase) * 0.04`).
  * Legendary gold glint sweeps across text every ~2.2s.
  * Mythic gradient wave oscillates smoothly.
  * Undiscovered cards render as flat grey silhouettes with neutral backgrounds.
  * Scrolling off-screen engages culling.
* **Visuals**: Confirmed visually across all 5 biomes (screenshots archived in brain directory).

---

## CARDS RESTORED, PLANTS BROUGHT CLOSER, MOTION REMOVED — 2026-09-08  (UNCOMMITTED)

**This supersedes the two sections below it.** Antigravity's Index redesign and
the illustrated-card integration are both gone. The cards are the original
shared-component design again, with three targeted changes on top.

### THE BASELINE, AND WHY IT IS HEAD

Every card change -- Antigravity's and mine -- was uncommitted, so the committed
state at **082bea0** IS the original implementation. Nothing had to be dug out of
history.

Worth knowing: the original Index used **`UIKit.plantCard`**, the same shared
component the Garden uses. Antigravity forked a private `buildIndexCard` out of
it. Restoring HEAD puts both screens back on one card component.

Three files were read out of HEAD and written back individually -- not a reset,
not a revert, not a broad checkout:

    src/StarterPlayer/StarterPlayerScripts/IndexUI.client.luau    (-982 +73)
    src/StarterPlayer/StarterPlayerScripts/GardenUI.client.luau   (-33 +6)
    src/ReplicatedStorage/SeedGame/Shared/UIKit.luau              (-69)

Checked before doing it: **none of those diffs contained anything unrelated to
the card work**, so nothing was lost. Every other modified file -- the reserved
tutorial pod, the Colossal aura, PlantSway, TutorialData, CarryService,
PlayerDataService, PromptUI, TutorialUI -- is untouched and still uncommitted.

`Shared/CardArt.luau` was deleted after confirming it had **zero consumers**.

**Preserved as unused work, not deleted:** the three approved illustrations and
their prompts in `output/imagegen/cards/`, the 512px derivatives in `art/cards/`,
and the uploaded asset ids, which are recorded in the superseded section below.
The remote assets were not archived.

### CHANGE 1 -- THE PLANTS CAME CLOSER

The old distance came off `model:GetBoundingBox().Size.Magnitude` -- the
**diagonal** of a box that includes the invisible `Base` plate every creature
carries at its feet and the card's own pedestal. Three faults at once: the wrong
geometry, the wrong axis, and a diagonal that is always longer than either the
height or the width.

Replaced with a real fit:

  1. Bounds from **drawn parts only** -- anything fully transparent is skipped,
     and so is the Pedestal, which is card furniture rather than creature.
  2. A first estimate that fits height and width separately and takes the
     further of the two, so a broad crown and a tall spire are both solved.
  3. **One corrective pass.** The camera looks in at (0.66, 0.28, -1), so a box
     is seen corner-on and its corners rotate into frame -- a fit that should
     have filled 86% actually filled 98%, and a Supernovus lost a front foot off
     the bottom. The real part corners are projected through the camera that was
     just built, the distance is scaled by the span that comes back, and the aim
     is nudged by its centre so an off-centre silhouette is not fitted as though
     it were centred.

Measured on all 25 species in the live Index:

    before   plant filled 53-79% of the frame by the old formula's own numbers
    after    82-86% on every species, 0 below 80%, ZERO parts clipped

Two wrong turns on the way, both caught by measurement rather than by eye:

  * The first pass set `modelBasePivot` to the drawn centre and then `PivotTo`'d
    the model onto it, which **translates the creature** -- a pivot is the Base
    plate at its feet, and the drawn centre is half a body above that. The camera
    then aimed at bounds that no longer described where the model was, and a
    Supernovus sat at **-0.389** in viewport space: 39% of it above the glass.
    The model is no longer moved at all.
  * The correction first read `|ndc| * 2` as the fraction of frame filled. NDC
    already spans the whole frame, so every card was measured at twice its size
    and pushed back until the plant filled a third of the card.

`GameConfig.CameraFill` (1.02) and `CameraRise` (0.08) are **left alone** -- they
still serve the other viewport helper. plantCard now uses its own `FRAME_FILL`
of 0.86 and aims at the true centre; applying an 8% rise on top of a correct aim
was spending margin that a tall creature needs for its crown.

`FRAME_NUDGE` exists for species-specific corrections and has three entries
(bell, pod, ready). It is nearly empty on purpose: a correct two-axis fit plus
the projection pass got everything else right, and every nudge is an admission
that the general rule failed.

### CHANGE 2 -- NOTHING MOVES

Removed from `UIKit`:

  * The **shared card RenderStepped** and its registry (`cardUpdaters`,
    `pumpCards`, `registerCard`, `unregisterCard`). Deleted rather than left
    idling -- a registry nothing registers with is a connection waiting to be
    re-armed by the next person who wants "just a little" motion.
  * **`idleFor`** and every per-form idle pose -- the bell's swing, the orb's
    breath, the cube's settle, the pod's drift.
  * The **click spin** (`spinVelocity = 8.5` on MouseButton1Click and again on
    selection), the **camera orbit** (`currentYaw`), the accumulated animation
    clock and the `parked` latch.
  * The two MouseEnter/MouseLeave handlers that existed only to wake the loop.

**Hover scaling is off**: `popOnHover` is called with `scale = 1`, so the card no
longer grows under the pointer. What remains is the stroke thickening and the
hover sound -- button feedback, not decoration. `popOnHover` itself is a public
helper and was not modified.

Verified in the live panel with 25 cards on screen and the panel open:

    model pivot moved <= 0.000000 studs over 2 seconds
    camera moved      <= 0.000000 studs over 2 seconds

The Garden's countdowns, income and totals still update -- those never ran on the
card loop.

### CHANGE 3 -- STATIC BIOME BACKGROUNDS, NOW COMPLETE

The original per-species backdrop system needed no code change: `setBackdrop`
reads `GameConfig.Card.Art[speciesId]` and draws it behind the ViewportFrame,
and identity is withheld wherever identity is withheld. Only the manifest was
empty for twenty of the twenty-five.

**The owner supplied five illustrated background plates on 2026-09-08**, at
`art/cards/backgrounds/biome1..5.png`, 1254x1254. They are background scenery
only -- no creature, no name, no rarity, no border, nothing animated -- and each
has an open, quieter centre for the plant to stand in.

    biome1  greenhollow  sunlit woodland, moss, oversized leaves, white flowers
    biome2  dustbowl     dunes, cracked clay, sandstone mesas, warm dusty light
    biome3  tanglemire   swamp water, reeds, hanging roots, layered mist
    biome4  emberroot    basalt, charred ground, restrained magma light
    biome5  starbloom    alien garden, luminous flora, nebula sky

**The folder's README described a different batch entirely** -- five Dustbowl
PER-SPECIES plates, `dunebud-background-v1.png` and four siblings -- and none of
those files are in the folder. The filenames were trusted over the prose after
opening all five and confirming each one against its biome. The README has been
replaced with what the folder actually holds; the orphaned Dustbowl prompts are
left at `output/imagegen/cards/backgrounds/`.

    greenhollow  rbxassetid://101119022870924
    dustbowl     rbxassetid://133554639098352
    tanglemire   rbxassetid://127784202754052
    emberroot    rbxassetid://107428058230890
    starbloom    rbxassetid://80623858180990

Every id came back from an upload. Runtime copies are the 512px `<biome>-bg.png`
beside the masters -- a card is 116-151 pixels wide and a 1254px texture for it
is four times what it can show.

`GameConfig.Card.Art` now maps **all 25 species** onto these five, generated from
`SeedData` rather than typed, so a new species cannot be silently missed.

**One judgement call worth reversing if you disagree.** Five Greenhollow species
had bespoke procedural backdrops from `tools/art/card_backdrops.py` -- Nubkin's
sunlit rows, Petalpip's meadow, Spiretip's misty pines, Toadcap's rotting log,
Bellchime's lanterns at dusk. They are **superseded, not deleted**: the script
and their five ids are recorded in the comment above `GameConfig.Card`. The
reason is cohesion -- soft procedural gradients on five cards next to painted
scenes on twenty reads as a bug rather than as variety. Say the word and
Greenhollow goes back to its bespoke set.

The trade this accepts: five species now share one plate per biome instead of
each having its own place. Per-species backgrounds remain the better end state.

### VERIFIED

    original layout       both screens back on UIKit.plantCard, pedestals,
                          name + rarity, action slab, selection behaviour
    all 25 species        every card shows its own real model
    framing               82-86% fill, 0 below 80%, 0 parts clipped, all 25
    stillness             0.000000 studs of model or camera movement over 2s
    privacy               22 concealed cards, none carrying a backdrop or a
                          rarity word; 3/25 discovery count intact
    Garden live data      3/20, tier badges "2 tier"/"5 tier"/"7 tier" (the
                          ORIGINAL presentation), BIG/GIANT/COLOSSAL sub lines,
                          +$196/s, +$11.6K/s, +$66.5K/s, plot +$78.2K/s
    layouts               3-column desktop (151px cells) and 2-column narrow
                          (116px cells) both measured; the fit is computed off
                          the viewport's own AbsoluteSize, so it follows
    repeated open/close   no duplicate previews, no growth in card count
    console               clean, no errors from either panel
    build                 clean rojo build
    background manifest   25/25 species mapped, 0 wrong biome
    background privacy    0 concealed Index cards and 0 empty Garden slots
                          showing a biome plate
    background z-order    0 backdrops drawn over a plant
    background stillness  0.000000 studs of movement with the plates in

**Not tested:** no pod was watched hatching in the live Garden (none is growing,
and planting one would change the owner's bed), and nothing was tested on a
phone. Only three of the five plates were seen behind a real card -- greenhollow
and dustbowl in the Index, starbloom in the Garden -- because the account has
three species discovered and three Starbloom plants. Tanglemire and emberroot are
verified by the manifest check, not by eye.

### UNTOUCHED

Creature models, geometry, colours, faces, materials, the size curve, the
Colossal aura, world plant animation, shop, inventory, hotbar, economy, saves,
combat, tutorials, plots and guardians. `SeedData`, `CreatureModel` and
`GameConfig` were not modified.

## ILLUSTRATED CARDS — THREE SPECIES LIVE IN BOTH SCREENS — 2026-09-08  (UNCOMMITTED)

The owner approved Codex's three sample illustrations. They are uploaded, mapped
and drawing in the Index and the Garden. **The section below this one is now
superseded on the blocker** -- the artwork arrived from outside this session;
everything it recorded about the pipeline and the identity data still stands.

### THE ASSET MAP — REAL IDS, EACH ONE CONFIRMED TO DRAW

| species | rarity | asset id | crop x |
|---|---|---|---|
| nubkin | Common (static label) | `rbxassetid://140166526412766` | 0.115 |
| suncrown | Legendary (gold shine) | `rbxassetid://124598790707157` | 0.115 |
| supernovus | Mythic (iridescent) | `rbxassetid://72987812541207` | 0.231 |

Every id came back from an actual `upload_image` call and was then put on a Decal
and photographed before being written into the manifest. **The other 22 species
have no entry and that is deliberate** -- see the interim fallback below.

    master    output/imagegen/cards/<id>-illustrated-sample-v1.png   approved, untouched
    runtime   art/cards/<id>-card.png                                512 x 512, resized

512 because a card is **116 px wide** (2 columns at 248) to **151 px** (3 columns
at 480), measured off both panels' own layout maths. A 1254 px master is four
times the texture for a card that never exceeds 151, which is the "do not upload
enormous textures for tiny cards" line. The masters are neither redrawn nor
replaced -- the runtime files are resizes and nothing else.

### THE CROP IS PER SPECIES, AND SUPERNOVUS IS WHY

The masters are square; a card is 1 : 1.30 portrait. Every card keeps a strip of
width 1/1.30 and only the horizontal offset differs.

**Supernovus is drawn prowling with its skull, jaw and brow horn in the right
third**, so a centred crop cuts exactly the features the brief forbids cropping.
Its strip starts at 0.231 instead of 0.115. Verified in the running client:
`ImageRectOffset` reads `118, 0` for Supernovus against `59, 0` for the other two,
and the head sits inside the frame at both panel widths.

### WHERE THE CODE LIVES

  * **`Shared/CardArt.luau`** -- NEW. The manifest, the crops, `Has`/`Apply`, and
    the one rarity scheduler. This is the shared presentation component: both
    screens draw the same picture with the same crop, so a species cannot end up
    illustrated in one panel and a 3D preview in the other.
  * **`Shared/UIKit.luau`** -- `plantCard` gained `setIllustration(speciesId?)`.
    **Audited first: GardenUI is `plantCard`'s only consumer**, so this cannot
    reach another screen.
  * **`StarterPlayerScripts/GardenUI.client.luau`** -- illustration on grown
    plants only; tier badge now prints the tier NAME.
  * **`StarterPlayerScripts/IndexUI.client.luau`** -- illustration gated on
    discovery, hover motion removed, Epic animation removed, per-card render loop
    deleted.

### WHAT WAS REMOVED FROM ANTIGRAVITY'S INDEX

  * **The per-card `update(dt, t)` and the RenderStepped that drove it.** It bobbed
    and swayed the 3D model, drifted the ambient motes and swept the rarity
    gradient. The first two are the card animation the owner rejected. The motes
    are still BUILT, so the 22 unillustrated backdrops look the same -- they just
    hold still.
  * **The hover scale.** A card that grew to 1.02 under the pointer is card
    animation. The border highlight stays: that is selection feedback, not
    decoration.
  * **The Epic rarity pulse.** On the real ladder Epic sits BELOW Legendary
    (weight 9 against 1.4) and five species carry it. Only Legendary and Mythic
    animate now. There is still no rarity between them, so the animated set is
    exactly two labels -- there was no third "intermediate" tier to design.

### ONE SCHEDULER, THREE WAYS TO PAUSE

`CardArt` runs a single `RenderStepped` shared by both panels, and it exists only
while a panel is open **and** a high-rarity label is registered. Panels are
reference counted, so closing the Index while the Garden is open leaves the
Garden's labels running.

Measured on the Mythic label in the live panel:

    panel OPEN, card on screen    0.268/5.1  0.299/6.5  0.290/7.7  0.243/8.7  0.164/9.4
    panel OPEN, scrolled off      0.063/9.9  0.063/9.9  0.063/9.9
    panel CLOSED                  frozen

### THE INTERIM FALLBACK, AND IT IS LABELLED AS ONE

**22 of 25 species have no approved artwork.** They keep the presentation they
already had -- their procedural backdrop and their still 3D portrait -- with the
decorative motion stopped. `CardArt.Has` answers false, `setIllustration` returns
false, and the caller falls through to the existing path untouched. Nothing is
blanked, nothing borrows another species' picture, and the collection is **not**
finished. The remaining 22 follow in a separate art pass in this approved style.

### VERIFIED

**Isolated presentation fixture** (its own ScreenGui, real `UIKit.plantCard`, real
`CardArt`, real uploaded assets -- the owner's almanac and garden were never
unlocked or written):

    desktop  panel 480px, 3 columns, cell 151x196  -- all three read clearly
    narrow   panel 248px, 2 columns, cell 116x150  -- faces still legible
    crops    nubkin/suncrown off 59,0   supernovus off 118,0   rect 394x512
    viewport visible=false, children=0 on every illustrated card

**The real Index, opened through its own rail button:**

    INDEX 3/25 -- only Dunebud, Petalpip and Supernovus are discovered
    illustrated cards           1  (Supernovus; nubkin and suncrown are concealed)
    concealed cards             22, still "???" / UNDISCOVERED, no artwork, no rarity
    rarity gradients            1  (MythicPrism), 24 labels static

Discovery privacy holds: two of the three illustrated species are undiscovered on
this account and neither shows its picture.

**The real Garden**, with three grown Supernovus at different tiers:

    GARDEN 3/20, plot income +$78.2K/s
    same artwork on all three, tier badges BIG / GIANT / COLOSSAL
    per-card income +$196/s, +$11.6K/s, +$66.5K/s

That screenshot is also the argument for the badge change: three identical
pictures, and the only thing telling a Big from a Colossal is the badge. It used
to print `compact(tier) .. " tier"` -- "1 tier", "7 tier" -- which is a bare index
on a card whose art carries no size information at all. It now prints the tier
name.

**Pod / unrevealed state**, driven directly on a fixture card because planting a
pod in the owner's bed to find out would be changing their garden:

    GROWN (illustrated)   illustration visible, viewport hidden AND emptied
    POD (unrevealed)      illustration hidden, viewport restored
    GROWN again           illustration visible again -- one label reused
    species with no art   illustration hidden, viewport restored

A pod never shows the species picture, which is the same back door the existing
backdrop rule already closes.

**No accumulation** after six Index open/close cycles and a Garden cycle:

    SeedIndex   25 cards, 1 illustration, 25 viewports (48 children = 24 x model+camera), 1 gradient
    SeedGarden  20 cards, 3 illustrations, 20 viewports holding 0 models

The Supernovus viewport is empty because `setIllustration` **empties** it rather
than merely hiding it -- a ViewportFrame with a model in it keeps rendering behind
an opaque picture, which is exactly the "hidden but still running" cost this was
meant to remove.

Console clean. `rojo build` clean. All four changed files compile.

### NOT TESTED, HONESTLY

  * **No Legendary label was observed animating in a real panel.** Suncrown is the
    only Legendary with artwork and it is undiscovered on this account, and no
    other Legendary is discovered either. The gold sweep is exercised only by the
    shared scheduler's code path, which the Mythic label proves runs. Worth a look
    once a Legendary is discovered.
  * **No pod was watched hatching in the live Garden** -- the pod path was proven
    on a fixture, not on a real growing plant.
  * Narrow layout was verified at 248 px in the fixture and by the panels' own
    layout maths, not by resizing the actual Studio window.
  * Nothing was tested on a phone.

### UNTOUCHED

Shop, inventory, hotbar, economy, rarity probabilities, growth times, saves,
combat, guardians, tutorials, plots, mill, plant geometry, the size curve and the
Colossal aura. `SeedData`, `CreatureModel` and `GameConfig` were not modified.
`GameConfig.Card.Art` -- the five old backdrop ids -- is left exactly as it was and
is still what the 22 fallback cards use.

## ILLUSTRATED PLANT CARDS — BLOCKED ON ARTWORK, PREP DONE — 2026-09-08

**No UI file was rewritten.** The owner rejected Antigravity's Index card design
and asked for illustrated collectible cards; the artwork cannot be produced in
this session, and the brief is explicit that procedural gradients and model
screenshots must not be passed off as finished illustrations. So the audit, the
references and the art briefs are done and the rewrite is not started.

### ANTIGRAVITY'S CHANGES — CLAIMS VERIFIED

Checked against the files, not taken on report:

  * **`IndexUI.client.luau` IS modified**, +917 / -74 lines. It added per-species
    procedural landscape tables with `motes` (a `BackdropMote` type and a
    `motes = { ... }` block for all 25 species), `ViewportFrame` heroes with
    per-card `Camera`s, `MouseEnter`/`MouseLeave` hover, and a `rarityMode`
    driven from **one `RunService.RenderStepped` connection** at line 1117.
  * **`GardenUI.client.luau` is UNTOUCHED.** Confirmed by `git status`.
  * Rarity animation currently runs on **Epic, Legendary and Mythic**.
  * Its `SPECIES_BACKDROPS` table **does** cover all 25 registered species
    exactly -- 0 keys that are not a species, 0 species without a key, checked
    against `SeedData`. Its own handoff section above names *Bramblebite* and
    *Snapthorn* among the Greenhollow entries and **no such species exist**; the
    prose is wrong, the code is not. Worth knowing before anyone trusts that
    section's species lists for anything.

### WHAT THE RARITY LADDER ACTUALLY SAYS

    SeedData.RarityWeight:  Common 1000, Uncommon 260, Rare 55, Epic 9,
                            Legendary 1.4, Mythic 0.22, Secret 0.03, Divine 0.004

Species actually in use: Common 2, Uncommon 3, Rare 8, **Epic 5**, Legendary 4,
Mythic 3. No species is Secret or Divine.

Two consequences for the brief:

  * **Epic is below Legendary, so its label must be static.** Antigravity's Epic
    animation is the "extra lower-rarity animation" to remove. Confirmed against
    the data rather than assumed.
  * **There is no intermediate rarity between Legendary and Mythic.** The brief
    asks for "existing intermediate rarity: a restrained distinct treatment" --
    the ladder is adjacent, so the animated set is exactly **two labels**:
    Legendary (slow gold shine) and Mythic (iridescent). Nothing to design for a
    third. Flagging rather than inventing one.

### THE BLOCKER, PRECISELY

**There is no text-to-image tool in this session.** The Roblox Studio MCP
provides `generate_mesh` and `generate_procedural_model` (3D), `generate_texture`
(re-textures an existing MeshPart from a prompt) and `generate_material`
(tileable surface materials). None of them produces a 2D illustration. The key
art in `output/imagegen/` was made on 2026-09-04 with a tool that is not
attached now; its prompts are committed, the generator is not.

**What DOES work, verified end to end today:**

    local PNG -> python -m http.server -> mcp upload_image
      -> "rbxassetid://113235703512353"  (a real id, returned by the uploader)
      -> renders in Studio

Proved by putting the fresh id on a Decal beside two backdrops that already ship
(`nubkin` 100196841981461, `bellchime` 106856602665628) and photographing all
three: **all three drew**. So the moment artwork exists, getting it into the game
is a solved, tested step.

One trap recorded: **`ImageLabel.IsLoaded` reads `false` in the Edit datamodel
even for the five backdrops that demonstrably ship.** It is not a usable probe
here -- a Decal on a Part plus a screenshot is. `ContentImageSize` cannot be read
at all from the MCP thread (`lacking capability RobloxScript`).

### THE THREE SAMPLES, CHOSEN AND PREPARED

A compact plant, a tall/broad plant and a Mythic, across three biomes and both
animated rarity tiers:

| role | species | rarity | biome | Mega h x w x d |
|---|---|---|---|---|
| compact | **nubkin** | Common (static label) | greenhollow | 18.1 x 12.3 x 10.7 |
| tall / broad | **suncrown** | Legendary (gold shine) | dustbowl | 34.9 x 40.4 x 17.8 |
| Mythic | **supernovus** | Mythic (iridescent) | starbloom | 46.0 x 36.3 x 43.2 |

Production models were built and photographed from a three-quarter and a
front-on angle, and their part inventories and exact `Color3` palettes read off
the built model. Written up as briefs an illustrator or an image tool can
execute:

    output/imagegen/cards/README.md          the rules every card obeys
    output/imagegen/cards/nubkin.prompt.md
    output/imagegen/cards/suncrown.prompt.md
    output/imagegen/cards/supernovus.prompt.md

Three identity facts in there are **invisible in a reference render** and are
exactly what "do not invent features because a reference is unclear" is about:

  * **Supernovus has six legs**, not four -- `FrontLeft / FrontRight / MidLeft /
    MidRight / RearLeft / RearRight`, each with thigh, hock, heel, pad and two
    toes. A three-quarter render reads as a quadruped.
  * **Suncrown's rays are two rings** -- nine `Ray` + nine `RayTip` outside eight
    `SunRay`, three of them coral-red -- not one symmetrical corolla.
  * **Nubkin's head is a cube** with two corner `Nub` bumps, and its pupils are
    doubled (pupil + glint) with the glint upper-left on BOTH eyes.

### WHAT THE EXISTING CARDS ALREADY ARE

Worth knowing before replacing them. `GameConfig.Card.Art` already maps five
Greenhollow species to backdrop asset ids, painted by `tools/art/card_backdrops.py`
(Pillow, 10 KB) -- Nubkin's sunlit rows, Petalpip's meadow, Spiretip's misty
pines, Toadcap's rotting log, Bellchime's lanterns at dusk. **The other 20
species have no card art at all.** Those five backdrops are soft procedural
paintings; they are not the illustrated creature cards being asked for, and
extending that script is not a route to them.

The existing privacy rule is already correct and must survive: a backdrop is
IDENTITY, so an undiscovered Index card, a Garden pod and an empty hole get the
plain dusk gradient instead. Painting Bellchime's lanterns behind a `???` names
the species through the back door.

### WHAT IS NOT DONE, AND WHY

The engineering half -- ImageLabels replacing ViewportFrames, deleting the mote
tables and hover connections, one bounded scheduler for visible high-rarity
labels, off-screen pausing, the shared Index/Garden card component, the Garden
layout -- is **not started**, deliberately.

Doing it now would swap a card that currently shows a 3D plant for a card
showing a background and nothing else, which is a visible regression the owner
has not seen or approved, and the brief gates production on three approved
sample cards that cannot be produced. It is ready to go the moment either
condition changes, and none of it depends on which PNG lands in the ImageLabel.

### TO UNBLOCK

Any one of these is enough:

  1. Attach an image-generation tool to this session; the three briefs are
     written and the upload path is tested.
  2. Drop finished PNGs into `art/cards/` and say so -- they get uploaded,
     mapped and wired.
  3. Say to proceed with the engineering half against the existing five
     backdrops plus a neutral placeholder for the other twenty, accepting that
     cards will look worse before they look better.

### UNTOUCHED

`IndexUI` and `GardenUI` are exactly as they were (IndexUI still carries
Antigravity's uncommitted work). No shop, inventory, hotbar, economy, geometry,
size curve, aura, save or plot code was touched. The only files added are the
four documents above.

## COLOSSAL PLANTS CRACKLE — 2026-09-08  (UNCOMMITTED, READY FOR VISUAL APPROVAL)

Two or three short jagged arcs snap around a Colossal's silhouette for about a
fifth of a second, then nothing for two to four seconds. Colossal only. No
sound, no shake, no gameplay, nothing replicated.

### WHERE IT LIVES

  * **`Shared/PlantAura.luau`** -- NEW. Palettes, the numbers, the pool, the
    budget and the arc geometry. It has **no connections and no lifecycle**: it
    exposes `Prepare`, `Forget` and `Tick` and nothing else runs on its own.
  * **`StarterPlayerScripts/PlantSway.client.luau`** -- six small edits. It
    already indexes every `Planted` model, waits for a PrimaryPart, drops it on
    tag removal and drives the whole bed from ONE Heartbeat on a round robin. A
    second index of the same bed is the one that leaks a plant on pickup and
    lights a bolt over empty soil, so the aura hangs off the existing one.
  * **`PlantSizeMockupRunner.luau`** -- the existing size preview gained an aura
    bench and now tags its grown specimens (see below). No second showroom.

### HOW A PLANT GETS ONE, AND HOW EVERYTHING ELSE DOES NOT

`PlantAura.Prepare` returns **nil** unless `model.Tier` equals
`SeedData.TierCount`. Tiny through Titan carry no state, are never scanned and
cannot fire. The check is made once, when the plant is remembered.

The scope gate above that is free and was already there: the `Planted` tag is
applied by **PlantService at the moment a pod becomes a plant in soil** --
`CreatureModel.Build` does not tag. So carried Tools, shop viewports, inventory
thumbnails and nest pods are never indexed by PlantSway and can never get an
aura. Nothing had to be added to exclude them.

### THE PALETTES

Keyed by **`species.Biome` from the sheet, not by an attribute.** A planted
creature carries `SpeciesId`, `Rarity`, `Tier` and `Stage` and nothing else --
`BiomeId` is stamped by NestService on a pod in a ring and never survives into a
plot. Reading it would have found nil on every plant in the game and quietly
painted all five biomes the neutral fallback, which looks exactly like "the
palettes are too similar". Caught before it shipped.

| biome | arc | core (one segment) |
|---|---|---|
| greenhollow | pale leaf-green 198,240,168 | warm gold 255,236,176 |
| dustbowl | amber 255,196,104 | sandy gold 255,232,176 |
| tanglemire | muted teal-green 126,200,178 | pale teal 196,236,220 |
| emberroot | ember-orange 255,142,62 | warm white 255,238,214 |
| starbloom | lavender 190,168,255 | pale cyan 214,248,255 |

### THE NUMBERS, AND WHY THEY ARE SMALL

    gap                 2.0 - 4.0s, randomised per plant, per pulse
    first gap           0.2 - 5.0s, so a bed streaming in does not flash together
    pulse life          0.22s
    arcs per pulse      3 near (<70) / 2 mid (<140) / 1 far (<200), minus one on Reduced
    segments per arc    4 thin Neon blocks
    arc length          measured height x 0.10, CLAMPED 1.6 .. 5.0 studs
    peak transparency   0.18 -- never fully opaque, even at the strike
    flicker             0.14, per segment, so a bolt shimmers along its length

**The length cap is the neighbour-plot guarantee.** A planting cell is 16 x 13.7
studs, so an arc that may reach five studs off the silhouette cannot cross into
the next cell no matter how wide the plant becomes -- and it holds under the
shipped 50x curve and the proposed 7.6x one alike, because the cap binds long
before the fraction does.

**No PointLight anywhere.** Neon carries the glow. A light per arc is the
difference between a crackle and a lightning storm, and 120 of them is the
difference between a game and a slideshow.

### PERFORMANCE

  * **One Heartbeat, shared.** PlantAura connects to nothing. On a frame where
    no plant is due, 120 Colossals cost 120 number comparisons.
  * **Pooled.** Segments are parked at y = -5000 and handed back out; the
    ceiling is arithmetic -- 10 concurrent x 3 arcs x 4 segments = **120 parts**.
  * **Client-wide budget of 10 concurrent pulses**, halved on Reduced. A plant
    due while the budget is full is pushed back 0.2-0.8s, not left due, so no
    queue forms and then fires as one wave.
  * **Distance bands** cut the arc count and stop entirely past 200 studs
    (140 on Reduced). Plants past the band are re-armed on the normal gap.
  * **Off-screen plants are skipped**, and the viewport test is only asked of
    plants actually due this frame -- never 120 times. Inside 40 studs the test
    is skipped, because a small camera turn brings those into frame mid-pulse.
  * **Reduced effects is the EXISTING control**, not a new one: the same
    `SeedAfterimageQuality` player attribute SpeedFX reads, the same three words,
    and the same touch-device default of Reduced. `Off` means no arcs.
  * The aura draws from its **own random stream**, not `entry.rng` -- that one
    decides where a plant walks, and sharing it would have made Colossals wander
    differently depending on how often their aura fired.

### VERIFIED IN A REAL PLAY SESSION

All of the following was measured on the client with the effect running, off the
shared `workspace.SeedPlantAura` folder rather than a second copy of the module.

**Tier gate -- a Bellchime Titan beside a Bellchime Colossal, 30 seconds:**

    lit-segment samples nearer the COLOSSAL   610
    lit-segment samples nearer the TITAN        0

**Arcs ride the moving creature.** The plants sway, so their parts move every
frame. If an arc is anchored to a part its transform RELATIVE to that part is
constant while its WORLD position changes:

    anchor Leaf        segment moved 0.01773 in world | RELATIVE drift 0.000122
    anchor PeatClod1   segment moved 0.04502 in world | RELATIVE drift 0.000123

(A third sample read 0.087 -- that is the measurement guessing the anchor by
proximity and picking the wrong part, not the arc slipping. `Lid` is on the
never-anchor list and cannot hold an arc.)

**Sparseness, which is the whole art direction:**

| scene | camera | frames with any arc lit | peak lit |
|---|---|---|---|
| aura bench, 5 Colossals spread out | ~120 studs | **11%** | 21 |
| realistic Level 5 bed, 1 Colossal among 20 plants | ~145 studs | **7%** | 4 |
| twenty-Colossal stress bed | ~126 studs | 52% | 60 |

**Stress case, 20 Colossals in one bed, 15 seconds:**

    segments pooled          72 of a 120 ceiling
    peak lit at once         60  = 5 concurrent pulses of a 10 budget
    mean lit per frame       8.2
    client frame time        16.82 ms (59 fps)

The budget was never saturated: the 2-4s gaps spread twenty plants on their own.

**Cleanup, after four build/clear cycles with clears landing mid-pulse:**

    pool                                        76 segments (ceiling 120)
    parked / returned                           76
    still lit                                    0
    lit segments with no plant within 40 studs    0

The pool did not grow per cycle, so segments are reused rather than made and
abandoned, and no mid-flight pulse was left hanging over destroyed soil.

### THE PREVIEW

The existing size stage gained two rows in front of the ladder:

  * **AURA BENCH** -- one Colossal per biome: Bellchime (greenhollow), Suncrown
    (dustbowl), Lanterncap (tanglemire), Cinderpaw (emberroot), Cosmospire
    (starbloom), each in its real planting cell with an avatar beside it.
  * **TIER GATE** -- a Bellchime Titan next to a Bellchime Colossal. If the Titan
    ever crackles, this is the view that says so.

The two Level 5 beds behind the ladder cover the mixed garden and the
twenty-Colossal stress case.

    require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Build()

**To see it crackle: press Play, get to the stage at (1200, 200, -1200), and run
Build() from there.** In Edit the stage is geometry -- the sway and the aura are
both client systems and Edit runs no client.

### TWO THINGS FOUND ALONG THE WAY

  * **The preview had to tag its own specimens.** `CreatureModel.Build` does not
    apply `Planted`; PlantService does. Without the tag the stage was inert --
    nothing swayed and no arc ever fired. The runner now tags its grown models,
    which is what makes it a preview of a planted plant rather than of a statue.
    `GardenUI` is unaffected (it only reads inside a plot's `Plants` folder) and
    `CashPop` only tracks, never pops, without a server payment.
  * **PlantSway loses a race with streaming, and this is NOT introduced here.**
    `StreamingEnabled` is on. PlantSway waits five seconds for a PrimaryPart and
    then gives up on a model **permanently**. A stage built 1,900 studs from the
    character showed **82 tagged models and zero of them swaying**: the empty
    Model containers replicated at once and their parts arrived much later. In
    normal play a plant is in your own plot and streams in with you, so this has
    probably never been hit -- but a player teleporting to a distant plot could
    see plants that never sway and never crackle. **Flagged, not fixed:** it is a
    PlantSway change with its own blast radius and it is out of scope here.

### HONEST LIMITS

  * **Not tested on a phone.** The Reduced path is exercised only by reading the
    same attribute SpeedFX uses; no touch device was involved. All frame timings
    above are Studio on this desktop.
  * **The screen captures under-represent the effect and one is staged.** A pulse
    is 0.22s and only 7-11% of frames have anything lit, so a capture usually
    catches nothing. The close-up was taken by copying ONE real pulse into a
    holding folder and leaving it standing -- real geometry, real colours, real
    positions, fade stopped. The frozen folder was deleted afterwards.
  * **No second player watched.** Nothing is replicated, so two clients see
    different arcs by design, but that has not been observed.
  * Arc colours were chosen against the biome palettes and the plant art, and
    have not been reviewed by anybody but me. That is what the bench is for.

### UNTOUCHED

Pods, guardians, geometry, sizes, income, rarity weights, growth timers, plot
capacities, saved data and the still-preview-only size curve. The aura reads
`Tier`, `SpeciesId` and the model's own parts, and writes nothing but the
transparency and CFrame of its own pooled segments.

## THE PLOT BOARD AND THE ROBUX SHOP — 2026-09-08  (UNCOMMITTED)

### THE PLOT UPGRADE IS A BOARD BY THE GATE

It was a shelf in the shop panel, which put the game's two upgrades -- the
mill's and the plot's -- in two different kinds of place for no reason a player
could see. One was a board you walked up to; the other was a menu. They are both
boards now, built by the same `MillModel.BuildSign`.

Placed beside the gate on the front fence, facing the approach. The X is
arithmetic rather than taste: the board is 6.84 wide and the gate gap is 13, so
clearing the gate edge by 1.2 puts the centre at -11.12 against a fence corner at
24. **The front edge never moves** -- PlotSpec asserts the gate holds still at
every level pair and the back edge takes the whole depth change -- so the board
is placed once and is still right at Level 5, which sidesteps the drift the mill
sign once had.

Two faults found by measuring rather than by looking:

  * **`BuildSign` tags what it makes `MillSign`.** Right for its only previous
    caller, wrong here: TreadmillService finds its boards by that tag and by
    PlotId, both of which the new board carried, so it repainted the plot's board
    with the mill's ladder. The owner's plot advertised
    `LEVEL 8 > LEVEL 9 | 12M/s > 70M/s | $10B` on a board about garden slots.
    The tag is now removed at build.
  * **A plot is handed over before its save arrives.** PlotService assigns on
    join and PlayerDataService loads asynchronously, so `LevelOf` fell back to
    the starting tier and an owner on Level 5 had a board reading
    `LEVEL 1 > LEVEL 2`. It now paints again as soon as the profile is there.

Verified live: six boards, each showing its own plot's step; the owner's reads
`LEVEL 5 | 20 SLOTS | MAX` with the prompt disabled; unowned plots read
`LEVEL 1 > LEVEL 2 | 5 > 7 SLOTS | $25K`; zero signs carry both tags.

### THE SHOP IS A ROBUX STOREFRONT

Four shelves from `GameConfig.Store`: SPEED, CASH, PREMIUM PODS, PLANTS. The
plot shelf is gone and `plotArt` went with it. There is **no remote in ShopUI any
more** -- a Robux purchase is a prompt to Roblox and a receipt to the server, so
the client's whole part is asking for the prompt.

`StoreService` owns `MarketplaceService.ProcessReceipt`, which is a single
callback for the whole experience -- assigning it twice silently replaces the
first, so nothing else may take it.

**Granted once, however many times it arrives.** Roblox re-delivers a receipt
until told PurchaseGranted, across restarts and rejoins, so the honoured
PurchaseIds live on the profile (`ProfileSchema.Receipts`, capped at
`Save.MaxReceipts` = 32) and the profile is written **before** the receipt is
acknowledged. A grant that has not reached the DataStore is deliberately left
unacknowledged: being re-delivered and refused at the ledger check is better than
losing both the item and the retry.

`CarryService.GivePod` is new -- a public wrapper over the same `restoreOne` a
rejoin uses, so a purchased pod is the same Tool with the same grip as a banked
one.

### WHAT IS NEEDED TO SELL ANYTHING

Create these in **Creator Dashboard -> Monetization -> Developer Products** and
paste each id into `GameConfig.Store`:

    Speed   +150K / +1M / +10M / +50M / +500M / +1B
    Cash    $24,000 / $200,000 / $800,000 / $4,000,000 / $8,000,000
    Pods    GIANT NUBKIN / TITAN PETALPIP / COLOSSAL BELLCHIME

The Robux prices in the manifest are the reference shots' and are the owner's to
set. **The speed and cash amounts have NOT been fitted to this economy** -- a
tier-1 mill trains at 20/sec, so +150K is about two hours of it, while the
owner's own save is past 100B speed. Expect to move them once there is a beta to
watch.

`StoreService` warns at boot about any id that is duplicated between two entries,
because a copy-pasted id charges for one tile and grants another.

### THE TILES, REDESIGNED TO THE REFERENCE

The first pass reused the old plot-shelf card and it did not look like the shots.
Four changes closed it:

  * **Landscape, not portrait.** The Index and Garden are 1.30 because a plant is
    taller than it is wide and the card is a photograph of one. A shop tile is an
    icon, a price and a button, and the reference lays those out wider than tall.
    0.86 is as flat as this panel goes and still fits the three bands.
  * **A shelf owns its colour.** Cyan speed, green cash, gold pods, violet plants
    -- a gradient face inside a bright rim, which is the thing that makes the
    reference read as shelves rather than one wall of tiles. The rim is the
    card's background with the face inset inside it, so it stays even at every
    corner radius.
  * **Two colours on one line.** RichText, so "+150K" prints in the shelf's
    accent and "SPEED" in white beside it, split at the first space. An entry
    with no space -- "$24,000" -- is all amount, which is how the reference
    prints the cash shelf too.
  * **A green pill on every shelf.** In the reference it is the same green on the
    cyan tiles and on the green ones: it is the BUY colour, not the shelf's.

Three things found by looking at it rather than by reasoning:

  * **A grey "SOON" tile made the whole shop look broken.** Draining the tile to
    slate when a product has no id is honest, and with every id at 0 it meant the
    cyan-and-green the design rests on was nowhere on screen. Only the PILL goes
    dark now -- which is also the smallest possible difference between this state
    and the live one.
  * **The label sat on the pill.** The title was 24 PIXELS tall on a card that is
    124 pixels at three columns and 93 at two -- a quarter of the tile at one
    width and a third at the other. Every band is a fraction now.
  * **"COLOSSAL BELLCHIME" came out as "COLOSSAL BELLCHI(".** The title is scaled
    with a floor of 9, so a long product name gets smaller type instead of losing
    its last word. Measured after: zero titles overflow their card.

Nothing in a shop card is rotated. A rotated child escapes ClipsDescendants and
this panel scrolls -- the note at the top of ShopUI records the half-scrolled
tile that threw its decoration 342 pixels past the list -- so every shape gets
its curves from UICorner instead.

### VERIFIED

    compiles           GameConfig, StoreService, CarryService, ProfileSchema,
                       PlotUpgradeService, MapService, ShopUI
    boot               20 services, no errors; StoreService and ShopUI both say
                       plainly that nothing is for sale
    shop               4 headings, 15 tiles in their shelf's colour, all
                       reading SOON and refusing; 0 titles overflowing
    boards             6 built, correct per-plot text, prompt disabled at MAX
    suites             TutorialPodSpec 263, TutorialSpec 93, PlotSpec 65,
                       MillSignSpec 8, WeaponSpec 80, BatSwingSpec 93

**Not tested:** no purchase has been made end to end, because no product exists
to buy -- `ProcessReceipt`, the ledger and `GivePod` are written and compile but
have never run. Nothing on a phone.

## PLANT SIZE CURVE — APPROVED AND APPLIED — 2026-09-08  (f8f6d17)

**APPLIED 2026-09-08 in f8f6d17.** `SeedData.Tiers` now carries
1 / 1.38 / 1.90 / 2.65 / 3.70 / 5.10 / 7.60. Re-measured after the change, the
Colossal heights match the approved figures below to **0.04 studs**.

`girth`, `weight`, `value`, `pod` and `color` were not touched, so rarity odds,
income, growth timers, plot capacities, pod art, guardians and player saves are
all unchanged. `PlantSizeMockupRunner` keeps the table as the record of what was
agreed, and `Build({ live = true })` still stands the stage up on whatever
SeedData currently says, so the two can be compared after any future change.

Everything below this line was written while it was still a proposal and is kept
as the reasoning and the measurements that supported it.

### WHAT IS WRONG NOW, MEASURED

Every species built at every tier through the production builders. The worst of
it, in studs, against a **46-stud corridor wall** and a **16 x 13.7 planting
cell**:

| species | Tiny h | Colossal h | Colossal foot | Colossal Base |
|---|---|---|---|---|
| nubkin | 3.1 | **217.1** | 124.6 x 119.1 | 42.07 |
| bellchime | 6.3 | **453.9** | 207.7 x 198.5 | 70.12 |
| cinderpaw | 4.3 | **214.3** | 84.6 x 73.3 | 48.97 |
| cosmospire | 7.7 | **382.5** | 177.8 x 105.8 | 83.69 |
| supernovus | 9.2 | **459.8** | 381.6 x 313.2 | 92.74 |

Bellchime at 454 studs is confirmed, and Supernovus is worse at 460. The shape
of the ladder is the other half of the problem:

    shipped  1.000  1.308  1.710  5.000  10.000  20.000  50.000
    steps        x1.31  x1.31  x2.92   x2.00   x2.00   x2.50

Three near-identical bottom tiers, then a 2.9x cliff at Huge -> Mega.

### THE PROPOSAL: ONE CURVE, UNIFORM, WITH THE FINAL JUMP INTACT

| tier | shipped | **proposed** | step | vs live |
|---|---|---|---|---|
| Tiny | 1.000 | **1.00** | -- | 100% |
| Big | 1.308 | **1.38** | x1.38 | 106% |
| Huge | 1.710 | **1.90** | x1.38 | 111% |
| Mega | 5.000 | **2.65** | x1.39 | 53% |
| Giant | 10.000 | **3.70** | x1.40 | 37% |
| Titan | 20.000 | **5.10** | x1.38 | 26% |
| Colossal | 50.000 | **7.60** | **x1.49** | 15% |

Tiny is unchanged. Big and Huge get slightly BIGGER, which fixes the three-tiers-
that-look-alike problem at the bottom. The cliff is gone. Titan -> Colossal is
deliberately the largest step on the ladder.

`girth` is untouched at 0.82 .. 1.45. It is a proportion, not a size -- broad
creatures stay broad, and changing it would be the axis-squeezing the brief
rules out.

### WHAT THAT BUILDS, BESIDE A 5.2-STUD AVATAR

Finished heights measured off the real models on the candidate curve:

| species | Tiny | Big | Huge | Mega | Giant | Titan | **Colossal** | avatars | vs wall |
|---|---|---|---|---|---|---|---|---|---|
| nubkin | 3.1 | 4.5 | 6.5 | 9.6 | 14.1 | 20.7 | **33.0** | 6.3x | 72% |
| bellchime | 6.3 | 9.1 | 13.2 | 19.5 | 28.9 | 42.9 | **69.0** | 13.3x | 150% |
| cinderpaw | 4.3 | 5.9 | 8.1 | 11.4 | 15.9 | 21.9 | **32.6** | 6.3x | 71% |
| cosmospire | 7.7 | 10.6 | 14.5 | 20.3 | 28.3 | 39.0 | **58.1** | 11.2x | 126% |
| supernovus | 9.2 | 12.7 | 17.5 | 24.4 | 34.0 | 46.9 | **69.9** | 13.4x | 152% |

Ground footprints at Colossal fall to **12.9 (cinderpaw) .. 58.0 (supernovus)**
from 84 .. 382, so most Colossals cover one to two planting cells instead of the
whole plot and its neighbours.

**Why Colossal is still worth chasing.** Tiny to Colossal is a 10.6x linear jump
in finished height -- about **1,200x in volume**. The tallest Colossals stand
half again as tall as the corridor wall and thirteen avatars high; the shortest
form still reaches six avatars. Titan -> Colossal alone adds 26 studs to a
Bellchime, which is five avatars of pure growth in one tier. It reads as a
landmark from anywhere on the plot without becoming the plot.

### IT IS A PURE UNIFORM RESCALE, AND THAT IS VERIFIED

The previous attempt shrank roots and left the body on the 50x curve, so feet
and bodies dwarfed their root systems. This changes ONE number that every
dimension already descends from -- `SeedData.Tiers[i].mul`, read through
`FrameHeight` -- so nothing can move relative to anything else.

Tested rather than asserted: every measured dimension of every proposed Colossal
as a fraction of the shipped one, expected 7.60/50 = 0.1520.

    cinderpaw   height .1521  widthX .1520  depthZ .1520  footX .1525  footZ .1514  base .1519  clearance .1516
    nubkin      height .1520  widthX .1518  depthZ .1522  footX .1517  footZ .1520  base .1521  clearance .1525
    supernovus  height .1520  widthX .1521  depthZ .1519  footX .1520  footZ .1520  base .1520  clearance .1525
    cosmospire  height .1519  widthX .1519  depthZ .1521  footX .1519  footZ .1522  base .1520  clearance .1521
    bellchime   height .1520  widthX .1520  depthZ .1519  footX .1521  footZ .1521  base .1520  clearance .1519

    worst deviation 0.00057 (0.37%, which is the rounding in the source figures)

No axis is squeezed, no part moves relative to another, and root-to-foot contact,
mouth depth, animation sockets and the approved Emberroot freeform roots are the
same geometry at a different size.

### EVERY SCALING CONSUMER, TRACED

| consumer | how it gets its size | effect of the change |
|---|---|---|
| `CreatureModel.BuildCreature` | `H = FrameHeight(sp, tier)`, `G = Girth(tier)` | the only reader of `mul`; everything below descends from H |
| invisible `Base` | `stemW * 1.2` off H | scales with it; 42-93 studs today -> 6-14 |
| `replayPart` (assembled forms) | `hs` for size, `hs * gs` for offsets | unchanged shape, smaller |
| `PlantPlace` footprint radius | `FrameHeight * 0.46 * Girth * 1.5` | follows automatically |
| `PlantSway` amplitude, bob, gait | measured world extents of the built model | follows automatically -- no constant to update |
| `PlantUI` / `CashPop` billboards | `GameConfig.topOfModel(model, anchor)` | follows automatically |
| Hatch / Pick Up prompts | parented to `model.PrimaryPart`, the ground Base | already at ground level, range 26; unaffected |
| `PlotService` wander separation | bounded logical target, not physical size | unaffected by design |
| income, rarity, timers | `tier.value`, `tier.weight`, GrowSeconds | **not touched** |

### THE PREVIEW

`src/ServerScriptService/SeedGameServer/PlantSizeMockupRunner.luau` -- new, a
module, nothing calls it. Modelled on `EmberrootRootMockupRunner`: same
`Archivable = false` scratch folder, same clear-then-build, same production
builders.

    require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Build()
    require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Build({ live = true })
    require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Curve()
    require(game.ServerScriptService.SeedGameServer.PlantSizeMockupRunner).Clear()

It stands at (1200, 200, -1200) on its own floor, and carries all seven tiers for
five species chosen to be awkward in different ways -- nubkin (the short floor),
bellchime (tall Greenhollow Epic), cinderpaw (multi-legged on freeform Emberroot
roots), cosmospire (Starbloom spire), supernovus (broadest creature in the game)
-- each with a 5.2-stud blocky avatar beside it, the real 16 x 13.7 planting cell
drawn under it, and a 46-stud wall post at the end of the row. Behind the ladder
are two real Level 5 beds on the real 48 x 96.2 plot at the real 3-column pitch:
one realistic roll (the tier weights are 53% Tiny and 0.41% Colossal, so a bed of
twenty is mostly small with a couple of trophies) and one worst case of twenty
Colossals.

`{ live = true }` builds the same stage on the SHIPPED curve for side-by-side
comparison; expect to stand well back.

### ONE SPECIES FLAGGED, NOT CHANGED

**Supernovus at Colossal is 58.0 x 47.6 studs across its own feet, and the plot
is 48 wide.** It is the only species that still overruns the bed, because it is
already the broadest creature in the game at Tiny (6.9 x 5.7). Dropping its
`Height` from 6.4 to about 5.6 would bring the footprint to roughly 51 x 42 and
the height to 61, uniformly, with no anatomy change.

It was deliberately NOT applied: it is a Mythic form at a 0.41% tier, it is the
single most spectacular thing in the game, and shrinking the trophy is the
owner's call rather than a silent tidy-up. **Decide this during approval.**

### GEOMETRY AND ANIMATION CHECKS, AND WHAT WAS NOT DONE

Done:

  * All 25 registered species x 7 tiers measured on the shipped curve, and the
    five ladder species re-measured on the candidate, off real built parts:
    finished height, ground/foot spread, max body width and depth, invisible
    Base size, and body-to-ground clearance for the multi-legged forms.
  * The uniform-rescale proof above, which is what guarantees feet stay attached
    and roots keep meeting them at every tier.
  * `PlantSway` traced and confirmed to derive amplitude, bob and gait speed from
    the model's measured extents, so no animation constant needs updating.
  * Prompts confirmed to hang off the ground-level `Base`, so interactions stay
    reachable at any size.
  * Clean `rojo build`.

**NOT done, honestly:**

  * **The preview has not been seen ANIMATED.** `PlantSway` is a client script
    keyed on the `Planted` tag, and Edit runs no client. The preview models do
    carry the tag, so building the stage inside a Play session would animate
    them -- that check is still outstanding and needs a playtest.
  * Billboard labels do not appear in MCP screen captures (a known limitation of
    the capture path, not of the preview); they are visible in Studio.
  * No camera-inside-the-body test was performed with a real character walking
    the bed. The numbers say a 33-70 stud Colossal is well clear of a 26-stud
    prompt range from the ground, but that is arithmetic, not a walkthrough.
  * Dustbowl and Tanglemire were measured on the shipped curve only; they use the
    same single multiplier, so the uniform-rescale proof covers them, but no
    Dustbowl or Tanglemire specimen is on the preview stage.

### THE OWNER'S TWO-PLAYER TEST

**OWNER-REPORTED:** the owner ran the two-player Studio test of the reserved
beginner pod and reports being satisfied with the result. That is their
acceptance, recorded as reported -- it was not a test performed or observed from
this side.

### FILES

  * `src/ServerScriptService/SeedGameServer/PlantSizeMockupRunner.luau` -- NEW,
    preview only, nothing calls it.
  * `KB/HANDOFF.md` -- this section.

No other file was touched. `SeedData.Tiers`, `CreatureModel`, `EconomyService`,
`ProfileSchema` and every save path are exactly as they were. Uncommitted and
unpushed, together with the reserved beginner pod.

## THE TWO STUDIO TEST ACCOUNTS WERE RESET — 2026-09-08  (no code change)

Documentation only. **No file in `src/` was touched by this**, and the reserved
beginner pod stays uncommitted exactly as it was.

### WHAT THE TEST ACCOUNTS ACTUALLY ARE

They are **persisted**, not in-memory. `SaveService` writes one DataStore blob
per player:

    store   StealASeed_v1          (GameConfig.Save.StoreName)
    scope   global                 -- GetDataStore(name) is called with no scope
    key     "p_" .. userId         -- SaveService.keyFor
    record  { Data = <profile>, Lock = { JobId, Stamp } | nil }

`ListKeysAsync` on that store returned **exactly three** keys, which is what
made the identification unambiguous rather than a guess:

| key | UserId | who |
|---|---|---|
| `p_-1` | **-1** | Studio local test client 1 (shown as `Player1`) |
| `p_-2` | **-2** | Studio local test client 2 (shown as `Player2`) |
| `p_4119740186` | 4119740186 | **nicnicniccoal -- the owner. Excluded.** |

A negative UserId cannot belong to a real Roblox account; Studio assigns them to
simulated test clients. The two records corroborated each other: their
`CreatedAt` stamps are **one second apart** (2026-09-04 11:53:49 and 11:53:50 --
two players joining one session) and their `LastSeen` stamps are **identical**
(2026-09-07 09:45:33 -- leaving together on one shutdown). The owner's record
has its own unrelated timestamps. Nothing else was a candidate.

Both had accumulated real progress -- cash, plants, weapons, mill and plot
levels, and grown plants -- which is precisely why they could not test the
reserved pod: `TutorialData.Sanitise` credits the whole guide from a Stage-3
plant, so both read as tutorial-complete and `PodEligible` was already false.

### THE RESET, IN ORDER

1. **No session was running.** Studio was in Edit (`RunService:IsEdit()` true,
   `IsRunning()` false), so nothing could autosave over the delete. Both records
   also read `Lock: none`, meaning the previous test session had released them
   cleanly on shutdown.
2. **Backed up outside the repository**, one file per record, carrying the
   store, scope, key, DataStore version id (plus the two prior version ids),
   UserId, identity, a SHA-256 of the exact record bytes, and the record itself:

       C:\Users\Maykel\SeedSaveBackups\2026-09-08_reserved-pod-test-reset\
         p_minus1.json
         p_minus2.json
         README.txt

3. **Backups verified by reading them back**, 16 checks each: the wrapper
   parses, the record parses, the recomputed SHA-256 matches the stored one,
   every progression field matches what the live record held, and the record
   re-encodes to an equal object -- which is the round trip a restore performs.
4. **Re-checked immediately before removal.** Newest DataStore version id still
   equalled the backed-up one and the encoded size was unchanged (799 and 615
   bytes), so nothing had been written since the backup, and neither was locked.
5. **Removed by exact key, one at a time**, with the owner's key named as a
   forbidden constant in the same script. No pattern match, no loop over a key
   listing, no store wipe, no StoreName change, no saving disabled.
   `RemoveAsync` returned records of exactly 799 and 615 bytes with the same
   cash and speed as the backups -- so what left is what was copied.
6. **Absence verified with uncached reads** after waiting past the DataStore's
   ~4s per-key read cache: `GetAsync` returns `nil` for both, and the newest
   version of each is `IsDeleted = true`. `p_4119740186` still reads back
   normally, `IsDeleted = false`.

`ListKeysAsync` still lists all three names, because by default it includes keys
whose newest version is a deletion. The read that matters is the one
`SaveService.Load` performs, and that now sees nothing -- status `new`.

Roblox keeps removed versions for **30 days**, so the DataStore's own version
history is a second recovery route alongside the files above.

### WHAT A FRESH PROFILE NOW LOOKS LIKE

Verified by running `ProfileSchema.Sanitise(nil)` -- literally what a removed key
produces -- against the current synced source rather than Studio's require
cache. All 20 checks passed:

    Cash 0   Speed 0   Plants 0   Held 0   Weapons 0   Almanac 0
    EquippedBat ""     EquippedTrap ""
    PlotTier 1   MillTier 1   MillOverclock 0   HighestBiomeOrder 1
    Tutorial: 0 milestones done, Skipped false, step 1 of 6
    first instruction: "Train your speed!"
    PodGrants 0      PodEligible false

`PodEligible false` is the correct new-player default, not a fault: entitlement
opens only once `train` **and** `speed` are both recorded, which is the
readiness bar the guide teaches. A brand-new player is owed nothing until they
have trained to 1,000.

Two checklist items could not be verified without a live session and are left
for the manual test: that each player owns a **different** plot, and that each is
guided to their **own** mill. `PlotService` assigns "the lowest-numbered free
plot the moment you join" across 6 plots, so two joiners take Plot_01 and
Plot_02 by construction.

### STARTING THE TWO-CLIENT TEST -- THIS PART IS MANUAL

`start_stop_play` over MCP only starts **Play Solo**, which runs as the owner's
own account and therefore can never show this feature. A one-client session was
NOT substituted. In Studio:

> **Test** tab -> **Clients and Servers** group -> set **Players** to `2` ->
> click **Start**.

That opens one server window and two client windows, `Player1` and `Player2`.
When finished, use **Shutdown** in that same group rather than closing the
windows by hand, so the final saves complete.

Practical notes for the run:

  * The readiness step is **~50 seconds** on a tier-1 mill (20/sec to 1,000), or
    about **12 seconds** at a full x4 rush charge.
  * The reserved pod appears within **2 seconds** of becoming eligible (the
    service polls at that interval) and only in daylight. The cycle is 420s day
    / 60s night.
  * It stands **24 studs** out from the Greenhollow nest centre, outside the
    16-stud public ring, and only its owner is offered the Take verb.
  * **F4** opens the debug console for both test clients (`isAllowed` returns
    true for anything in Studio), which has `RestockNests` and `ResetParents` if
    you want to strip the public nest first and prove the reservation still
    arrives.
  * Running the test gives both accounts progress again. A second fresh run
    needs another reset.

### ONE OBSERVATION WORTH CHECKING LATER

`SaveService` carries the comment *"Studio leaves JobId empty, so every Studio
session shares one id and cannot lock against itself."* In this Edit session
`game.JobId` returned a real GUID, not `""`. That was **Edit**, not a Play
server, so the comment may still hold where it matters -- but if a Play server
also gets a distinct JobId per session, then a test session that dies without
releasing would leave a lock that blocks the next one until
`SessionLockSeconds` expires. Not investigated, not changed, and it did not
affect this reset: both records were already unlocked.

## AN EMPTY NEST NO LONGER BLOCKS THE TUTORIAL — 2026-09-08  (UNCOMMITTED)

Greenhollow is ONE nest of FIVE pods and a taken slot does not grow back until
dawn. A beginner could finish the training steps, walk to the nest the guide is
pointing at, and find it stripped by other players -- the tutorial blocked by
somebody else's play, which is the one thing a tutorial must never be.

One extra pod now stands outside the ring with that beginner's name on it.

### IT IS ADDITIONAL SUPPLY, NOT A PUBLIC SLOT

The ring still holds five, the rolls are unchanged, and nobody else's raid is
any easier or harder. What makes that true mechanically is that the reserved pod
is spawned WITHOUT a `NestId`, which routes `CarryService.TryTake` down the
LOOSE branch -- the one that provokes by `FromNestId` and touches no slot
bookkeeping. `NestService.ClearForNight` iterates `nest.pods`, so it never sees
a reservation either; TutorialPodService takes its own back.

Live, on the built map: greenhollow **5 of 5** public slots before and after,
**16 of 16** server-wide.

### ELIGIBILITY: A PROPERTY OF THE RECORD, NOT OF THE WORLD

`TutorialData.PodEligible(progress)` is pure and says only what the saved record
thinks:

  * `Done.hatch` -> **never again**. The guide's last step is the hatch, so
    finishing it ends entitlement permanently. Existing completed players are
    therefore excluded by the same line that excludes a beginner who just
    finished.
  * `Done.train` **and** `Done.speed` -> both required. Nothing is reserved
    before a beginner has trained to 1,000, which is the readiness bar the guide
    already teaches.
  * `PodGrants < 3`.

**`Skipped` is deliberately not consulted.** Skip hides the guide; it surrenders
nothing. A player who skips, walks into an empty nest and presses Resume must
not have been quietly disinherited in between -- nor re-entitled.

Whether one should be STANDING somewhere also depends on daylight and on what
the player already has, and those are the service's business, not the record's.

### IDENTITY: POSSESSION, NOT A GUID

The obvious design gives the pod an id and follows it through nest -> carried ->
dropped -> banked -> planted -> hatched. That needs a new field in two save
whitelists, because `ProfileSchema` rebuilds `Held` and `Plants` rows field by
field on every load. **It was not done, and the reason matters:** the question
is only ever *"does this player already have a pod?"*, because what the feature
owes them is A pod, not a particular one.

So `TutorialData.HasOutstandingPod` asks about POSSESSION, across the four
places a first pod can be:

| state | how it is seen |
|---|---|
| carrying | `CarryService.IsCarrying` |
| in the world (standing **or dropped**) | server sweep of the `SeedPod` tag for `ReservedFor == UserId` |
| banked | a `Held` row with `Hatched ~= true` |
| planted, unhatched | a `Plants` row with `Stage < 3` |

**An ordinary pod counts.** A beginner who got one off the public nest does not
need a reserved one, and handing them a second is exactly the duplicate this
has to avoid.

The one piece of identity that DOES exist is the `ReservedFor` attribute on the
pod Model, and it earns its place by answering the one thing possession cannot:
telling *"their pod is lying on the ground over there"* apart from *"they have
nothing"*. A dropped pod is invisible to a save-based check and would otherwise
read as a loss.

**Streaming cannot reach any of this.** `inWorld` is answered on the SERVER,
where the model exists whether or not any client has been sent it. "The owner
cannot see their pod" and "the pod is gone" stay different questions, and only
the second buys a replacement. The service's source contains no `LocalPlayer`
and no `Stream*` -- asserted in the spec, against the code with its comments
stripped.

### THE ANTI-FARM: A BOUNDED GRANT COUNT

`EconomyService.SellHeld` destroys **every** Tool in the backpack with a valid
`SpeciesId` -- so a banked tutorial pod can be SOLD, and "give them one whenever
they have none" would mint Tiny Commons for as long as somebody kept selling
them. The bound is `Tutorial.PodGrants`, capped at `MaxPodGrants = 3`, written
only by `PlayerDataService.RecordPodGrant`.

Three rather than one, because a beginner can lose a pod to a guardian, to a
mistimed drop, or to a loose pod expiring while they run back for it -- and
being told to wait until dawn is the wall this exists to remove. Past the cap
they are not stuck: the public nest still restocks every dawn, and by then they
have been shown where it is.

**It is counted when the pod is PLACED, not when it is taken.** Counting on the
take would let somebody farm the spawn -- stand there, never take it, log out,
come back.

### NIGHT, DAWN AND RECONNECT

  * **Night** clears only the pod the service is holding a handle to, and places
    nothing while `GameConfig.isDay()` is false. Nothing stealable stands behind
    a closed barrier.
  * Anything **carried, banked or planted is untouched by night** -- the service
    never reads `Held` or `Plants` in its night branch, so it cannot reach them.
  * A pod they took and then DROPPED is on the ordinary 45-second loose timer
    and expires on its own; at dawn the possession sweep finds nothing and a
    replacement is owed. That is one of the three the cap is sized for.
  * **Dawn** restores one if and only if no copy is outstanding.
  * **Reconnect** is reconciled by one line: with no profile loaded,
    `hasOutstandingPod` answers YES, which refuses to spawn. A player rejoining
    with a banked pod cannot be handed a second in the window before their save
    arrives.
  * **A leaver's unclaimed pod goes with them** -- both the standing one and one
    they dropped. Anything they banked or planted is saved property and is none
    of the service's business.

### VISUAL PRIVACY IS A COURTESY; THE REFUSAL IS THE RULE

`CarryService.TryTake` refuses a stranger with `RESERVED`, above the line where
the world starts changing, so a refused take cannot half-destroy a pod on its
way out. That is the enforcement, and it is the only enforcement.

`PromptUI` additionally declines to DRAW the verb for a pod reserved to somebody
else. The model itself is still visible to everyone -- it is a server-built
model and hiding it per player is not something this architecture does cleanly,
so that half was not attempted.

### FILES CHANGED

| file | what |
|---|---|
| `Shared/TutorialData.luau` | `PodGrants` on `Progress`; `MaxPodGrants = 3`; `PodEligible`; `HasOutstandingPod` + its `Possessions` type; `Default` and `Sanitise` |
| `SeedGameServer/TutorialPodService.luau` | **NEW.** Priority 75. The whole policy: eligibility, possession, placement, night, leavers |
| `SeedGameServer/CarryService.luau` | `RESERVED_FOR`; `spawnLoose` marks and `keep`s; `SpawnLoose` returns the Model; `ReservedFor()`; the `RESERVED` refusal in `TryTake`; the reservation survives `Drop` |
| `SeedGameServer/PlayerDataService.luau` | `RecordPodGrant` |
| `StarterPlayerScripts/PromptUI.client.luau` | a stranger's reserved pod does not offer its verb |
| `StarterPlayerScripts/TutorialUI.client.luau` | the arrow trail prefers the player's own reservation and rules other people's out entirely |
| `tools/tests/TutorialPodSpec.luau` | **NEW.** 263 checks |

### MIGRATION

`TutorialData.Sanitise` is the migration point -- `ProfileSchema` already calls
it at line ~505. `PodGrants` is absent on every existing save and reads as
**zero**; a value off the wire is a claim, so a string, a float, NaN, a negative
or an over-cap number is clamped to `[0, MaxPodGrants]`. Nothing else about the
record changed, and the round trip was checked to preserve cash, speed, banked
pods, plants, mill level, weapons and tutorial progress.

**Completed existing players receive no reservation**, by the `Done.hatch` line
-- verified live below.

### VERIFIED

Kept in three groups on purpose, because they are worth different amounts.

**PURE + FIXTURE (`TutorialPodSpec`, 263 checks, Edit mode, no save touched).**
Covers all 11 enumerated cases at the level each can honestly be tested: the
entitlement rule, the possession rule across every state, the 50-pass
idempotence loop, the sell-loop terminating at 3, the save round trip, the
migration and its corrupted-value clamps, and the placement geometry. The world
half runs against **real Instances** in a throwaway Workspace folder tagged the
way the game tags pods -- including that a `Planted` pod is skipped, that a
destroyed one is gone, and that a model reparented out of Workspace is not found
even though it still carries the tag.

**SINGLE-CLIENT, LIVE, in a real Play session on the built map.** All of the
following went through the RUNNING server, not a separately-required copy:

    a stranger's reserved pod, real ProximityPrompt hold completed:
      [Seed/CarryService] nicnicniccoal completed a take hold on Pod_petalpip
      [Seed/CarryService] nicnicniccoal take refused: RESERVED (Pod_petalpip)
      pod still exists: true      carrying: nil

    the same pod reserved to the holder:  taken, carrying = petalpip

    prompt panels drawn for the local player:
      reserved to somebody else   0
      reserved to me              1
      an ordinary pod             1

    knocked down while carrying (the real ragdoll -> Drop path):
      Pod_nubkin  reserved=4119740186  NestId=nil  FromNestId=Nest_greenhollow_01

    placement, measured on the built map:
      24.01 studs from the nest centre (public ring is 16)
      8.45 studs clear of the nearest public pod
      10.80 studs between two beginners' reservations
      |X| 38.0 and 27.5 inside a 70-stud half-corridor
      NestId=nil, prompt attached, SeedPod tag present

    the owner, who has completed the guide:
      no reservation was ever placed, and no grant was logged

The forged-request shape is exactly what was exercised: `PromptUI` declined to
draw the verb, and the client held the prompt anyway. The server refused.

**TWO REAL CLIENTS: NOT DONE.** Everything above ran on one datamodel. The
refusal was driven with a real Player, a real prompt and the running
`CarryService`, but a second person genuinely racing for the pod has not been
observed and is not claimed. Neither has a full eligible-beginner run
(place -> take -> chase -> bank -> plant -> hatch), because the only account in
the session has already completed the guide and rewinding it was not worth the
risk. Both are covered by the recipe below.

**Regression suites:** TutorialSpec 93, PlotSpec 65, MillSignSpec 8,
WeaponSpec 80, BatSwingSpec 93, TutorialPodSpec 263. Clean `rojo build` and
`git diff --check`.

Two suites fail, **both pre-existing and neither touching any file in this
change**:

  * `SpeedSpec:280` -- calls `GameConfig.overclockUnlockOrderFor`, which does not
    exist in GameConfig (0 occurrences).
  * `CycleSpec` -- asserts "exactly one biome is live" while all five now have
    `LiveInPhaseA = true`. The spec was never updated when the road opened.

### THE RISK WORTH SOMEBODY'S DECISION: SHARED GUARDIAN RAGE

**Flagged separately, and deliberately not fixed here.** The reserved pod does
not change the chase in any way -- same guardian, same nest, same shared rage --
and a rage reset must not be buried inside a tutorial feature.

Every theft carries at least one stack, because `NestService.provoke` does
`nest.rage += 1` before the chase starts. Measured against the current numbers:

    a beginner at 1,000 Speed walks 22.00, and 21.94 carrying a Tiny pod

      rage 1: guardian 20.00  ->  ESCAPES  by +1.94
      rage 2: guardian 25.00  ->  CAUGHT   by -3.06
      rage 3: guardian 30.00  ->  CAUGHT   by -8.06
      rage 4: guardian 35.00  ->  CAUGHT   by -13.06

    rage fades after 45s, and is cleared outright at dusk (ResetParents)

So the tutorial theft is winnable **only against a calm nest**. If any other
player has raided Greenhollow in the previous 45 seconds, the beginner's run is
a guaranteed loss at the exact readiness the guide told them to reach. On a busy
server that is not a rare case.

It is survivable rather than fatal -- a caught beginner loses the pod to
confiscation, the possession sweep then finds nothing, and one of their three
grants buys another attempt. But three attempts against a nest somebody else
keeps angry is a real wall, and the honest options are all outside this feature:
lower `Parent.RageSpeedPerTake`, shorten `RageForgetSeconds`, make rage
per-thief rather than per-nest, or raise `Tutorial.SpeedTarget` so the readiness
bar clears a raged guardian. **Somebody should pick one deliberately.**

### HOW TO TEST THIS WITHOUT LOSING YOUR OWN PROGRESS

Your account has completed the guide (`Done.hatch`), so **nothing will ever be
reserved for you** -- which is correct, and also means Play Solo cannot show you
the feature. Do NOT rewind your tutorial record to see it: your profile carries
1.8B cash, 2.17B speed, mill tier 5 and two plants, and a mistake there is not
recoverable.

Use an isolated profile instead:

  * **Studio -> Test -> Start Server + 2 Players.** Player1 and Player2 are fake
    accounts with their own DataStore keys, untouched by and untouching your
    real save. Train one to 1,000 on their own mill, then walk to Greenhollow:
    the reservation appears 24 studs out. This is also the only way to do the
    two-client check and the full beginner run that are still missing above.
  * The debug console (**F4**) has `RestockNests` and `ResetParents` if you want
    to strip the public nest first and prove the reservation still arrives.
  * `TutorialPodService.Snapshot()` prints eligibility, possession and the grant
    count per player. Note that reading it through the MCP console does NOT
    work: `execute_luau` has its own require cache, so `PlayerDataService.Get`
    there returns nil for a player whose profile is loaded. Read Instance
    attributes, or fire `DebugCommand` from a client, which runs in the real
    server.

### WHAT THIS SESSION DID TO THE LIVE WORLD, AND PUT BACK

Two public greenhollow pods were consumed by the take tests and the guardians
were provoked. The nests were restocked through the real server
(`RestockNests` -> 16 of 16) and the parents sent home (`ResetParents` -> 5).
Final state before Play was stopped: 16 pods, greenhollow 5 of 5, zero pods
carrying a reservation, nothing carried, no seed Tools in the backpack. **No
profile field was written**: the guide's milestones were already complete so
`RecordTutorial` was a no-op, no grant was ever recorded, and the character
never touched a treadmill.

## THE MILL SIGN STOPPED FLOATING, AND MOVED OFF THE FRONT CORNER — 2026-09-07 (in a01c372)

### THE CAUSE, WHICH IS A PIVOT THAT DOES NOT ROUND-TRIP

`MillModel.BuildSign(cf, parent)` treats `cf` as the sign's GROUND BASE: the post
is 5.2 * Scale tall and is centred at `cf * CFrame.new(0, 2.6 * Scale, 0)`, so
its bottom lands exactly on the frame it was handed. It then sets
`model.PrimaryPart = post`.

`TreadmillService.Rebuild` rebuilt the sign from `sign:GetPivot()` -- which is
the POST, not the base. So every upgrade handed the builder a frame that was
already half a post too high, and the builder added the offset again.

    2.6 * 0.76 = 1.976 studs of rise, per rebuild, cumulative

Reproduced before touching anything, by running the exact loop:

    rebuild 1: base Y 0.0000 -> pivot Y 1.9760   post bottom 0.0000
    rebuild 2: base Y 1.9760 -> pivot Y 3.9520   post bottom 1.9760
    rebuild 3: base Y 3.9520 -> pivot Y 5.9280   post bottom 3.9520
    ...

**The mill itself never had this problem**, and the difference is the whole
lesson: `MillModel.Build` sets `PrimaryPart = deck` and builds the deck AT `cf`,
so a mill pivot round-trips exactly. Rebuild reads `existing:GetPivot()` for the
mill and that is safe. The sign is the one model in the pair whose PrimaryPart is
offset from its own construction frame.

### THE FIX: ONE PLACEMENT HELPER, DERIVED FROM THE MILL

New `MillModel.SignBase(millCF)` returns the sign's ground base from the mill's
own frame. Both callers now go through it:

  * `MapService.buildTreadmill` -- was doing the offset maths inline.
  * `TreadmillService.Rebuild` -- was reading the old sign's pivot. It no longer
    looks at the previous sign at all.

That makes placement **idempotent**: rebuilding the same tier a hundred times
puts the sign in exactly the same place, and a save that already contains a
floating sign is corrected by its next rebuild rather than inheriting the drift.
The duplicated `LADDER.Sign` offset expression in TreadmillService is gone, so
there is one place the offset is applied and no way for the two to disagree.

### THE NEW POSITION: OFF THE FRONT-LEFT CORNER

`Mill.Sign.Offset` moved from `(0, -0.6, -12.6)` to `(-5.5, -0.6, -12.6)`. Only
X changed. Measured in the mill's own frame:

  * **Y -0.6 is the ground and always was.** A ray from the mill straight down
    hits `TheField` at local -0.60, which is exactly `Offset.Y`, and BuildSign
    puts the post's bottom on that frame. So a FRESHLY built sign was always
    grounded -- the floating was purely rebuild drift. (The deck's own underside
    is at -1.13, deliberately buried; that is not the ground.)
  * **Z -12.6 is clear of every tier.** Swept all ten in one-stud slices:
    nothing any tier builds reaches past Z -11.5. Unchanged.
  * **X -5.5 is the change.** Centred, the board stood square across the front of
    your own machine. The plot is on the mill's -X side and the walk in comes
    from the spawn pad, so this puts the board beside that approach instead of
    across it.

The board is 9 * 0.76 = 6.84 wide, so it spans -8.92 to -2.08. The plot fence
stands at -10.2: **1.28 studs of daylight**. Pushing further out would read
better still and does not fit.

Artwork, text styling, size, scale, yaw and PromptRange are untouched.

### VERIFIED

**`MillSignSpec` -- new, 8 checks, 540 placements** (10 tiers x 6 rotations x 9
builds, the first plus eight rebuilds of the SAME tier):

    sign drift                0.000000 studs
    post bottom vs ground     0.000000 studs
    mill / deck / belt moved  0.000000 studs
    board to belt centre      14.50 of PromptRange 18
    tightest front clearance  1.17 studs (all ten tiers reach into the board's X span)
    fence daylight            1.28 studs

It also asserts the BUG still exists in isolation -- feed a sign its own pivot
and the 1.976 rise must still appear -- so the file cannot start passing because
the post stopped being the PrimaryPart and the other checks quietly went blind.

**Live, on the real plot, through the real `TreadmillService.Rebuild`** at the
SAME tier (no tier change, no profile write), six times:

    post world Y 1.9760 every time, drift 0.0000, belt moved 0.0000
    post bottom in mill-local Y: -0.6000 every time
    raycast under the post: TheField, 0.000 studs below its foot

Before the fix that same sequence would have lifted it 11.86 studs.

**Plot levels 1 to 5**, resized on the transient Edit map with
`MapService.ResizePlot`: the board and post overlap **zero** plot parts at every
level, nearest part the fence rail at 1.28 studs. The level 3+ wing extends the
plot to mill-local X +29.8 but sits at a different Z and never reaches the sign.

**Both board faces** render and update: Front and Back both read
`UPGRADE | LEVEL 3 > LEVEL 4 | 1K/s > 8K/s | $500K`, and the `Upgrade`
ProximityPrompt is on the Board with range 18.

Suites: MillSignSpec 8, PlotSpec 65, TutorialSpec 93, WeaponSpec 80,
BatSwingSpec 93, BatClearanceSpec 939. Clean `rojo build` and `git diff --check`.

### NOT VERIFIED, AND ONE THING WORTH SOMEBODY'S ATTENTION

  * **The upgrade was never actually purchased.** Doing so means spending cash
    and moving a saved mill level, which this task ruled out. The rebuild path it
    triggers was exercised directly instead, at a fixed tier.
  * Only plot 1 was measured live. The other five are the same model at
    different rotations, and the spec covers six rotations including this plot's
    -124.2 degrees.
  * **Tier 9's decorations already cross the fence line.** Its Astral ring reaches
    mill-local X +/-14.74 while the plot fence stands at -10.2, so about 4.5 studs
    of it overhangs the plot on every rotation. Pre-existing, nothing to do with
    the sign, and deliberately not touched here -- but somebody should decide
    whether it is intentional.

### ONE UNINTENDED SIDE EFFECT

Framing the photographs put the character on the mill's belt, which mounted it
and trained for roughly a minute: the owner's Speed went from about 62.5K to
135K. Nothing else changed, and it is normal gameplay on their own machine, but
it was not asked for. Teleporting off a belt does NOT clear `MillMounted` -- the
mount is entered by Touched and held by a region test -- so the character was
respawned to clear it, which is the same trap noted in the tutorial section.

## THE GUIDE, RUN END TO END ON A RESET ACCOUNT — 2026-09-07 (in a01c372)

The owner asked for their account to be reset and the guide retested. It was, and
the retest found a real error in the previous pass's guardian tuning.

### THE ACCOUNT

Backed up first to
`D:/KAPE/tmp/profile-reset-20260907b/nicnicniccoal-4119740186.before.json`
(outside the repository; do not commit it). 417 bytes, verified byte-for-byte
against what Studio read, and it round-trips as JSON. Contents were modest --
cash 0, speed 8,462, no plants, no held items, no weapons, tutorial 4/6.

Play was stopped first so the shutdown save completed and the session lock
released. The delete was guarded on a fingerprint of the backed-up bytes, so it
could only remove exactly what had been saved, and the read-back through a fresh
store handle confirmed absence. `StealASeed_v1` / default scope /
`p_4119740186`, and nothing else.

### THE ERROR THE RETEST FOUND: EVERY CHASE HAS A RAGE STACK

`NestService.provoke` does `nest.rage += 1` **before** the chase starts, so the
speed a first-time thief meets is the biome's stated base **plus**
`Parent.RageSpeedPerTake`. There is no rage-0 chase in the game.

The previous pass modelled the first theft as rage-free, which made every number
in it five too low:

    stated base   what the FIRST theft actually chased at
        26        31      <- the shipped formula
        20        25      <- the previous pass's "fix"
        15        20      <- now

Measured live, not inferred: a trained player carrying a pod walks 21.5-24.2, and
was run down and thrown at both 31 and 25. `GuardianChaseSpeed` is now **15**,
which is a guardian that chases at **20**.

**Greenhollow only.** No other biome sets the field, `parentWalkSpeedFor` is
untouched, `RecommendedSpeed` is still 0, and 1,000 remains the guide's readiness
target rather than any kind of gate.

`TutorialSpec` now models the rage stack explicitly -- `FIRST = base + rage`,
`SECOND = base + 2*rage` -- so this cannot be got wrong quietly again.

### THE PATHWAY IS NOW FLOWING ARROW BEAMS

At the owner's direction (note.com/robloxken/n/n4a9a11450651), the trail is drawn
with Roblox `Beam` objects carrying the standard flowing-arrow texture
`rbxassetid://18518488457` instead of static ground chevrons. Verified the asset
actually resolves with `PreloadAsync` rather than trusting the id.

**Chained, one Beam per leg of the pathfinding route**, because a single beam
from player to objective is a straight line and would run through fences, the
mill and the plot wall. A fixed pool of 24 nodes and 23 beams, built once at
login, with spacing that stretches to cover a 245-stud run home or a 30-stud walk
to the mill. The texture scrolls itself from `TextureSpeed`, so **there is no
per-frame trail work left in the file at all** -- the old transparency pulse is
gone.

**ATTACHMENT0 IS THE NODE FURTHER ALONG, WHICH IS THE OPPOSITE OF WHAT IT LOOKS
LIKE.** The arrow glyph points from Attachment1 toward Attachment0. Built the
obvious way round, the trail was a tidy line of chevrons all pointing back the
way the player had come. Caught by photographing it from the side against known
geometry, not by reasoning about it. `TextureSpeed` is then negative so the flow
travels toward the objective too: speed sets the motion, attachment order sets
which way the arrowheads face.

Width 5.0 and texture length 9 were tuned by eye down a real route home; at 3.2
the arrows read as a dotted line from any distance worth guiding over.

### THE FULL RUN, ON A GENUINELY EMPTY ACCOUNT

Every step advanced through real gameplay and real server records. No fixture
packets were used for any of this.

  * Fresh profile: `Version 2, Done {}, Skipped false`, WalkSpeed 16, guide
    showing STEP 1 / 6.
  * **train** -- dropped onto the real belt, mounted, and Speed climbed off the
    real faucet: 70 -> 192 -> 348 -> 537 -> 757 -> 1009. `train` recorded on the
    first gain.
  * **speed** -- recorded exactly as the score crossed 1,000 (at 1009).
  * **steal** -- the real `Take` prompt on `Pod_petalpip`, held for its real 0.7s.
  * **bank** -- ran 245 studs home with the guardian chasing at **20.00** and the
    gap GROWING 18.2 -> 34.8. Pod banked, `bank` recorded. This is the run that
    failed at 25 and 31.
  * **place** -- equipped from the hotbar and placed at the spot the guide was
    marking; 1 plant in the bed, `place` recorded, guide moved to STEP 6 / 6 with
    a live "Ready in 39s" from the real hatch timer.
  * **hatch** -- countdown ran down, the guide switched to "Hold the Hatch
    prompt.", the real prompt was held, and the celebration fired
    (`visible=true, scale=1.04`).
  * Final record: **6/6, COMPLETE.**
  * The optional hint then appeared exactly as designed -- "Plant it to earn
    cash!" with the pointer on the real hatchling's hotbar slot (Petalpip). The
    hatchling is a Tool and nothing auto-planted it.

Screenshots taken of steps 1-6, the celebration and the hint.

### STILL NOT VERIFIED

  * **The escape was run at WalkSpeed 24.15, not at the 1,000-Speed 21.5.** The
    account trained past the target while mounted. At 21.5 against 20 the margin
    is 1.5 studs a second and the simulation says it holds, but the exact-target
    run was not performed live.
  * **No second client**, so nothing about another player's view of the guide.
  * Phone, controller and small-screen layout untested.
  * The beacon and the soil marker still cannot be photographed (MCP
    `screen_capture` omits BillboardGui layers; see the section below).

### TWO THINGS THAT WASTED TIME AND WILL AGAIN

  * **Teleporting off the treadmill does not unmount you.** Entry is a Touched
    and occupancy is a region test; a teleport leaves `MillMounted` true, which
    pins WalkSpeed at 0 through CarryService. It looks exactly like being frozen
    for no reason. Respawning clears it. A player who walks off is fine.
  * **`ProximityPrompt:InputHoldBegin()` does nothing while the camera is
    Scriptable and parked elsewhere.** `PromptShown` never fires and the take
    silently fails. Put the camera back on `Custom` before driving a prompt.

## THE BEGINNER GUIDE IS NOW SHOWN, NOT READ — 2026-09-07 (in a01c372)

Reworked Marigold's guide from an objective card into ground arrows, highlights
and four words. Same three files -- `TutorialData`, `TutorialService`,
`TutorialUI` -- and the same server-recorded milestones; no parallel system.

### THE FLOW, AND WHAT CAME OFF THE END

    1  train   Train your speed!            own treadmill, arrow trail + highlight
    2  speed   Reach 1,000 speed!           pointer at the REAL speed readout
    3  steal   Take a pod!                  a real available Greenhollow pod
    4  bank    Bring it to your plot!       route across the actual red line
    5  place   Place your pod here!         marker over a free spot on your soil
    6  hatch   Hatch your first plant!      the pod they planted, with a countdown
       ->      CONGRATULATIONS!             one-shot fanfare, then an optional hint

**The guide ends at the hatch.** Version 1's last three steps -- plant the
hatchling, receive earnings, buy a bat -- are no longer things a beginner is HELD
in a tutorial until they do. Buying a $5,000 bat is about twenty minutes of
garden income, which is a strange thing to still call "the tutorial". **None of
those systems changed**: planting, the earnings tick and the shop are exactly as
they were, and their `RecordTutorial` hooks still fire and are now harmless
no-ops (`Record` refuses an id that is not a step, so nothing is even marked
dirty). If those steps ever come back, the hooks still work.

What replaced them at the FRONT is the part a beginner cannot guess: that the
treadmill is what makes a raid survivable.

**Hatching still returns a Tool, not a paying plant, and that is preserved.**
After the fanfare the guide shows a lightweight optional hint -- a pointer at the
hatchling's actual hotbar slot and a marker over free soil, "Plant it to earn
cash!" -- for 45 seconds. It never places anything.

### GREENHOLLOW'S GUARDIAN: 26 -> 20, AND ONLY GREENHOLLOW'S  (SUPERSEDED)

> **The arithmetic in this subsection is WRONG and the value changed again.** It
> models the first theft as rage-free; every chase in the game carries at least
> one rage stack. The corrected version is in the section above. The Greenhollow-
> only, no-new-gate design is unchanged.


The guide tells a beginner to reach 1,000 and then rob Greenhollow. That was an
instruction to do something impossible. Measured with the shipped functions and
the shipped map:

    player at 1,000 Speed              WalkSpeed 22.00   (an exact anchor row)
    ...carrying a Greenhollow pod            ~21.5   (the carry costs 2-5%)
    Greenhollow guardian, first theft         26.00
    the nest is                              245 studs from the red line

The guardian closed 4.5 studs a second, so with the 1.2s head start the player
was caught around 145 studs -- well short of 245. **The first theft was not
hard, it was unwinnable.**

`BiomeData` greenhollow now states `GuardianChaseSpeed = 20`; `NestService`
prefers a stated speed over `parentWalkSpeedFor` and rage still stacks on top.
**No other biome has the field**, `parentWalkSpeedFor` is untouched, and
`RecommendedSpeed` stays 0 -- **1,000 is the guide's readiness target and NOT a
biome gate.** Every biome is as open as it was.

20 is the LARGEST value that fixes it, chosen by simulating the real race:

    guard   trained@1000    untrained@0    2nd theft (rage +5)
      26    caught 145      caught 46      caught 82
      20    ESCAPES 245     caught 83      caught 179
      18    ESCAPES 245     caught 137     ESCAPES   <- breaks rage escalation

So the lesson survives at both ends: turning up untrained still loses the pod,
and going straight back to the same nest still loses it. Only the trained
beginner the guide just produced gets home.

**Runtime proof, not just data:** NestService's boot line now reports what the
guardians actually run at and prints
`then run at 20-92 by biome (+5 per theft)`. It used to print a flat 26 from
`parentWalkSpeedFor(0)` -- a number no guardian would have been using.

### MIGRATION

`Tutorial.Version` 1 -> 2, migrated in `Sanitise` (already called after profile
validation). Two rules:

  * **Nobody is sent backwards.** A record carrying any v1 milestone is credited
    with `train` and `speed` as well. They demonstrably got past that part of the
    game; re-teaching them the treadmill because the step list moved underneath
    them would be the update punishing them for having played.
  * **Anyone past the old hatch is finished.** hatch/plant/earn/buy in a v1
    record completes the new guide, so finished players never see it again.

Possessions still prove steps (a planted pod means it was placed; a grown plant,
a hatched Tool or an Almanac entry means it was hatched). **Speed is evidence
too** -- the treadmill is the only faucet, so a non-zero score IS proof of
training, and >= 1,000 proves readiness. Cash proves nothing, as before.

Observed on the owner's REAL record in Play: it migrated to `Version=2`,
`Done = {train, speed, steal, bank}`, next step `place`, `Skipped` still true --
credited the two new front steps off their existing `steal`, kept their progress,
and did not restart them. Their profile read back `cash 0, speed 8462, tier 1`,
unchanged.

### THE GUIDE ITSELF

`TutorialUI.client.luau`, rewritten. No panel anywhere: the instruction is
`UIKit.outlined` -- LuckiestGuy with a black stroke, transparent background --
which is CashUI's own reasoning, *"The outline IS the readability. There is no
plate behind these."*

  * **Arrow trail.** `PathfindingService` with `AgentCanJump = false`, so it goes
    through the plot gateway rather than over the fence. A fixed pool of 20
    chevrons (40 thin Neon bars) whose spacing STRETCHES to cover the whole
    route, so a 245-stud run gets the same 20 markers a short one does. Recomputed
    at most every 0.7s, and sooner only if the player has moved 9 studs. The
    per-frame half only reads a clock and writes transparencies -- no search, no
    allocation, no path rebuild. **If pathfinding fails, nothing is drawn**: a
    straight line of arrows through a wall is worse than no arrows, because the
    player trusts it.
  * **Everything is client-built**, so "visible only to the relevant player" is a
    property of where the code runs. All parts anchored, `CanCollide`/`CanQuery`/
    `CanTouch` false, `Archivable` false -- verified live: 42 pooled parts, 0
    misconfigured.
  * **UI pointers** read the real `SeedCash` "Speed" label and the real
    `SeedLoadout` hotbar slot, anchoring to `AbsolutePosition`/`AbsoluteSize` --
    and to `TextBounds` rather than the box, because that label is a 260px frame
    holding about 110px of text and the pointer was landing a finger-width away.
    It flips to the other side when the first would run off screen. No desktop
    coordinate is hard-coded.
  * **The speed counter** reads the profile packet, not an attribute: there
    deliberately is no `SpeedScore` attribute (GameConfig publishes only
    `SpeedVisualTier`). The profile replicates every 0.25s while dirty, so it
    counts live while training.
  * **Recovery** for a lost pod, an empty bed, a full plot, a streamed-out nest,
    night, no plot yet, and death. It never points at soil with nothing to place.
  * **Cleanup** on step change, death, respawn, skip, completion and teardown.

### VERIFIED, IN PLAY, ON THE ACTUAL UI

Steps driven by a **packet-only fixture** -- the server firing a guide packet the
client renders. It writes nothing and touches no profile; the owner's account was
NOT reset and no save was altered.

  * Step 1: trail drawn to the OWNER'S mill (`Treadmill01`, matched by plot id),
    highlight on the belt, aimed at the top face where a player actually stands.
  * Step 2: pointer found the real `Speed` label, aligned to **0 px** off its
    centre, and flipped to the right-hand side because the left would clip.
  * Step 3: highlighted a real pod, `Nest_greenhollow_01.Pod_nubkin`, 150 studs
    off, with a full 20-chevron trail.
  * Step 4: trail ran **Z -248 to Z -58, crossing the banking boundary at -170**.
  * Step 5 with no pod in hand: correctly refused to point at soil and said
    "Take a pod! / Your pod is gone -- grab another from Greenhollow." The free-
    spot search independently returned a point ON the soil (|x| 8.5 of 17.0,
    |z| 5.8 of 11.6) and clear of plants.
  * Completion: **CONGRATULATIONS! / You hatched your first plant!** popped,
    played `RevealLegendary` through SoundKit, and faded by itself. One-shot: a
    player who joins already finished gets no fanfare. It blocks nothing.
  * Skip and Resume through the REAL commands: `Skipped` true -> false -> true,
    milestones unchanged, and the owner's original `true` restored.
  * On death: 0 chevrons, highlight/beacon/finger/pointer all off; the guide
    survives respawn.
  * Console clean, 18 services including TutorialService.

Automated, fresh-source: **TutorialSpec 91**, PlotSpec 65, WeaponSpec 80,
BatClearanceSpec 939. TutorialSpec now also asserts the readiness race itself, so
the Greenhollow tuning is a tested fact rather than a comment that can rot -- it
checks a trained player escapes, an untrained one does not, rage still bites, and
that the OLD 26 was genuinely impossible.

### A TOOLING FINDING WORTH KEEPING

**Studio's MCP `screen_capture` does not include BillboardGui layers.** Proven by
standing next to a pod with the game's OWN `SeedPrompt` enabled and adorned and
getting a picture with no prompt in it -- and a purpose-built control billboard
was invisible too while the plain Part beside it photographed fine.

So the bouncing beacon and the soil marker are verified by STATE -- enabled,
adorned, positioned, sized -- and NOT by a picture. Do not read their absence
from a screenshot as them being broken; check the properties. They are parented
the way CashPop and PromptUI already do it, both of which ship.

*(An earlier pass in this session "fixed" them by re-parenting to the anchor
part, on the theory that a ScreenGui does not render billboards. That theory was
wrong -- CashPop parents to a ScreenGui and works -- and it was reverted.)*

### NOT VERIFIED -- READ THIS BEFORE BELIEVING THE ABOVE

  * **No true fresh-account run.** Nobody played new-player -> mill -> 1,000 ->
    pod -> bank -> soil -> hatch end to end. The owner's account was deliberately
    not reset, so the sequence was driven by fixture packets against the real UI.
    **This is the main outstanding acceptance test.**
  * **The live `place` and `hatch` steps were never exercised with a real pod**,
    because the owner holds none and creating one would change their inventory.
    Their RECOVERY paths were verified instead; the pointing marker and the
    countdown were not seen driving a real placement.
  * **The 1,000-speed escape is arithmetic**, from the shipped functions, the
    shipped nest position and a 50Hz simulation -- not a live chase. A real run
    at exactly 1,000 would mean altering the owner's Speed, which is saved
    progression. Corners, jumps and other players are not modelled.
  * **Training across 1,000 was not watched live** -- the owner is already at
    8,462, so both speed milestones are satisfied for them. The `AddSpeed` hook is
    code- and spec-verified only.
  * **No second client**, so nothing about another player's view of the guide, and
    no multiplayer tutorial isolation.
  * Phone, controller and small-screen layout are untested; the UI reads real
    viewport sizes but nobody has looked at it on a phone.

### FILES CHANGED (all uncommitted)

  * `Shared/TutorialData.luau` -- six steps, `SpeedTarget`, `Version` 2, the
    migration. `FirstBat` and the WeaponData dependency removed with the buy step.
  * `Shared/BiomeData.luau` -- optional `GuardianChaseSpeed`, set on Greenhollow.
  * `SeedGameServer/NestService.luau` -- `baseSpeedFor` honours it (and it wins
    over a species ramp too); the boot log reports the real range.
  * `SeedGameServer/PlayerDataService.luau` -- `AddSpeed` records `train` and
    `speed`. Placed here rather than in TreadmillService because this function
    owns the score, so a future faucet cannot bypass the milestone.
  * `StarterPlayerScripts/TutorialUI.client.luau` -- the rewrite.
  * `tools/tests/TutorialSpec.luau` -- rewritten for six steps, the migration
    cases and the readiness race.

`TutorialService` is UNCHANGED: still snapshot/skip/resume only, still validated
and throttled, and the spec re-confirms it refuses `train`, `speed`, `hatch` and
`complete` from a client. Nothing touches cash, inventory, plants, weapons or
plot upgrades. No commit, no push; Studio left in Play for the owner's playtest.

## OWNER'S FRESH-START RESET — 2026-09-07 (CODEX)

Owner explicitly authorized removing their data to test the beginner guide.
Verified both LocalPlayer and server roster: nicnicniccoal, UserId 4119740186,
place 114075467877655. Stopped Play to finish shutdown saves before touching
the record. Verified the released lock and backed up the exact saved record to
`D:\KAPE\tmp\profile-reset-20260907\nicnicniccoal-4119740186.before.json`
(outside this repository; do not commit the account backup).

Removed ONLY `StealASeed_v1` / scope `global` / key `p_4119740186`, after checking
its version still matched the backup. Uncached read verified absence. Restarted
Play; real boot reports loaded (new). Subsequent saved record verified Cash=0,
Speed=0, PlotTier=1, MillTier=1, MillOverclock=0; Plants/Held/Weapons/Almanac
empty; Tutorial.Done empty and Skipped=false. Actual client guide is visible at
0/7, "Steal your first pod", pointing to a real Greenhollow pod. Left Play running
for the owner's fresh playthrough. Old progress is recoverable from the local
backup; no other account was touched and no runtime source changed in this reset.
Handoff remains in the already-shared uncommitted diff; no unrelated work staged.

## MARIGOLD'S BEGINNER GUIDE — 2026-09-07 (CODEX, in a01c372)

Owner requested implementation of the beginner tutorial. The owner also reports
the earlier two-player combat test passed; this is their report, not a new
multiplayer test of this tutorial. Plant scaling remains unstarted in this pass.

### Implemented

Seven server-recorded milestones: steal a pod -> bank across the red line ->
place the pod -> hatch -> PLANT THE HATCHLING -> receive garden earnings -> buy
any bat. The extra planting step is essential: the live hatch hands the creature
back as a Tool, not as a paying plant in the bed. Earnings are automatic; the
guide does not invent a Collect button.

- `Shared/TutorialData.luau`: ordered copy and pure progression/migration rules.
- `ProfileSchema.luau`: additive `Tutorial = {Version=1, Done={}, Skipped=false}`;
  no overall save version bump, no changed existing-field validation. Sanitises
  known booleans only. Validated held pods/plants, planted pods/grown plants,
  Almanac entries and owned bats seed appropriate earlier milestones. Cash
  alone never proves garden earnings. A returning grown garden qualifies on its
  next real payout. Buying a trap does not count as buying a bat.
- `PlayerDataService.luau`: RecordTutorial / SetTutorialSkipped, dirty only on
  change. Existing full profile replication/save path carries the tiny record.
- Success-only hooks: CarryService.TryTake and bank; PlantService hatch and
  PlaceAt; EconomyService's normal garden payout; WeaponShopService.TryBuy for
  bats. No rewards, altered prices, timers, capacity, tools, save inventories,
  cash calculations, guardians or combat changes.
- `TutorialService.luau`: existing GameEvent wire, action `BeginnerGuide`;
  commands are ONLY snapshot/skip/resume. Validated and rate limited to one per
  0.5s per player; disconnects/clears on Init and cleans request state on leave.
  No client milestone, step number, finish command or reward claim is accepted.
- `TutorialUI.client.luau`: Marigold green/wood objective card; saved milestone
  counter; Hide/Guide button; confirmed Skip and Resume; local destination
  marker/highlight and distance/bearing hints. No camera takeover, control lock,
  forced purchase or new NPC prompt. Existing shop prompt stays intact. Menus
  and biome-advisory banners take priority. Existing completed players see a
  compact Garden Guide button, not the introduction again.
- Recovery guidance: lost carry, missing equipped/held pod or hatchling, hatch
  countdown, full plot, waiting for plot/character, nighttime and streamed-out
  nest targets. Search/render is throttled to 4Hz while shown; one local marker
  is noncolliding, nonqueryable, nonsavable and removed with the UI.

### Verified, with limits

- `TutorialSpec`: **61 passed** using tools/tests/run.luau fresh dependencies.
  Progress/idempotence, rejoin at each step, out-of-order purchase, skip/resume,
  malformed records, legacy held/grown inventory preservation, no invented cash
  or plants, actual starter price, and isolated request validation/throttling.
- `WeaponSpec`: **80 passed**; `PlotSpec`: **65 passed**. Changed sources compile
  in Studio, Rojo build and git diff --check clean. Initial test incorrectly used
  SpeciesId in a HELD row; corrected to the actual saved `Id` field. Production
  migration reads already-validated rows and never had that mistake.
- Live boot discovers 18 services, including TutorialService. The owner's nine
  saved plants remained nine. Observed actual profile packets with all seven
  milestones, including the real earnings tick; no direct profile replacement.
- Real mouse input opened Garden Guide. Instance-path click positioning missed
  the GUI inset; screen coordinates derived from the rendered UI worked.
- A bounded CLIENT-PACKET-ONLY fixture displayed step one on the actual UI and
  found a real Greenhollow pod 345 studs away. No saved progress was reset for
  that visual check. Fixture stopped afterward.
- Real skip/resume requests returned Skipped true/false with the same seven
  milestones. Restored false. A forged `complete` request produced no response
  or progress change. Temporary observation connection was disconnected.
- All seven default titles/instructions measured to fit the 300px-width layout
  (252px text area). This is text measurement, not a real phone playtest.
- NOT RUN: a brand-new account completing every gameplay action end-to-end,
  physical phone/controller testing, or two-client tutorial isolation. Event
  integration is success-path code plus pure/state tests, not a claimed full
  fresh-account run. These are the remaining acceptance checks.

### Pacing / scope

Rootwood remains $5,000 (read from WeaponData, not duplicated as balance). A
single Tiny Common's $4/sec would take about 21 minutes to afford it; more
plants shorten that. The guide encourages growing the garden while saving.
No free bat, tutorial cash faucet, growth acceleration or price change was added.

Original versions of the six edited server files and this handoff are under
`D:/KAPE/tmp/tutorial-20260907/`. All prior combat/clearance/shop/UI changes were
preserved. No commit/push: the tutorial touches shared dirty profile/carry files
and depends on still-untracked WeaponData/shop work, so committing it alone
would not produce an independently runnable checkout and must not sweep the
other agent's work into a task commit. Await coordinated approval/staging.

The luau-conventions skill informed server-owned milestones, the existing
replication/save path, single-faucet preservation and lifecycle cleanup.

## THE CLEARANCE PASS: THE SWING NO LONGER GOES THROUGH THE FLOOR — 2026-09-07 (in a01c372)

Both clipping defects found in the verification below are fixed. **The strike was
not touched** -- contact still lands exactly at `SwingWindup`, the two-hand grip
still locks, and the one-shot release is intact. Only the two transits either
side of the strike changed, plus a new clearance spec.

### THE ACTUAL CAUSE, WHICH WAS NOT THE WAYPOINTS

Three separate things, none of them the strike:

**1. The transits were not authored at all.** The swing held `LOAD` while the
blend weight ramped 0 -> 1, and held `FOLLOW` while it ramped back to 0. A weight
ramp interpolates JOINT ROTATIONS between the idle and the solved pose, so the
path it takes is whatever those rotations happen to sweep through -- nobody chose
it. That is where both defects lived. Measured on the live rig: the handle went
0.53 studs into the chest on the way up, the barrel 1.36 studs through the floor
on the way back. **The poses at both ends measured clean; only the journey was
wrong.**

**2. `CFrame:Lerp` between two `barrel()` frames does not keep the roll.**
`barrel()` pins roll by holding the weapon's own +X horizontal. Slerping two such
frames does not preserve that in between -- the blade rolls edge-down partway
across, and on a long weapon that excursion is what reaches the ground. The
Mirewood and the Sunflower measured clean at BOTH ends of the final move and
0.28 studs underground in the middle of it. The transits now interpolate yaw and
elevation and rebuild the frame, which keeps roll pinned throughout.

**3. The idle was hard-coded, and it is not shared.** `WeaponData.GripDroop` is
10 on the Cactus and **-7 on the Sunflower**, whose petal head rests ABOVE
horizontal. One hard-coded anchor aimed the Sunflower about 15 degrees below its
own rest and drove the head at the ground. `Motion.LowAnchor` now derives it per
weapon by forward kinematics -- at the idle the joints ARE `LOW_S` / `LOW_E` /
identity wrist, so the handle follows exactly. Verified live: it returns exactly
`-GripDroop` for all six bats.

### WHAT THE SWING DOES NOW

    idle -> LIFT -> LOAD .. HIT .. FOLLOW -> CROSS -> DROP -> idle
             up and         (untouched)      across    down and
             outboard                        in front  outboard

`CROSS` exists because one straight line cannot do the return: pulling the hand
back while crossing the chest drags the handle through the torso, and staying
forward to avoid that drops it onto the thigh. Cross first, then descend -- both
were measured, and each single-waypoint attempt traded one defect for the other.

The weight ramp now runs only while the hand target IS the idle, where the two
poses agree and the blend has nowhere wrong to go.

### MEASURED, LIVE, THROUGH THE REAL PIPELINE

Real equip path, real `tool:Activate()`, sampled on RenderStepped and Heartbeat
together. Body list excludes the arms and hands (the arms are driven BY the swing
and the hands are the grip) and `HumanoidRootPart` (never rendered):

    bat                contact    ground    deepest into body   grip lock
    rootwood_bat        7.2 deg    +0.34    0.22 UpperTorso       0.47
    cactus_club         9.3 deg    +0.46    0.19 UpperTorso       0.47
    sunflower_bonker    1.7 deg    +0.27    0.28 UpperTorso       0.48
    mirewood_paddle     2.2 deg    +0.36    0.25 UpperTorso       0.47
    cindercrack_bat     1.2 deg    +0.08    0.31 RightUpperLeg    0.47
    comet_bat           2.0 deg    +0.19    0.27 RightUpperLeg    0.47

    before this pass:   ground -0.47 to -1.36,  penetration up to 0.53

**Ground clearance is positive on all six.** Contact stays far inside the
+/-37.5 degree cone `CombatService` already used, and no hitbox was touched.
The Cindercrack's +0.08 is the thinnest and is the one to watch.

Residual penetration of 0.19-0.31 is the handle passing the chest and thigh. It
is not zero and should not be: a two-hand swing brings the handle past both by
design, and the ACCEPTED strike phase already ran 0.11-0.20 before this pass.

Joint ownership re-checked after the change. Walking 120.6 studs with a bat held:

    RightShoulder 0.0   RightElbow 0.0        held -- the pose
    LeftShoulder 107.7  LeftElbow 186.9       free
    Waist 40.5  RightHip 96.2  RightKnee 269.5  Neck 30.7   free

By value rather than sweep: mid-swing the right shoulder reads (53.9, -74.8,
-153.8); after it, (6.0, 0.0, 7.0) -- exactly `LOW_HOLD` -- and the left elbow is
back on an animator value, not pinned at identity. Unequipping releases the right
shoulder too.

*(An earlier walk reading in this session showed 0.0 studs moved and every joint
still: that was the harness failing to walk the character, not a pinned rig.
`Humanoid:Move` is overridden by the control module every frame; `MoveTo` works.
Do not read a walk result without checking the distance travelled first.)*

### THE TEST THAT WOULD HAVE CAUGHT IT

New `tools/tests/BatClearanceSpec.luau`. **939/939.** It is the half
`BatSwingSpec` does not cover: real built Tools, every part, all eight corners,
49 samples across the full swing, at three body scales, against a head/torso/legs
body and a floor. Limits are `ground >= 0.02` and `penetration <= 0.42` --
regression limits set above what the corrected motion measures and well below
what the defect measured.

**Confirmed to have teeth, not assumed.** The pre-fix trajectory was reinstalled
over the module and run through the same fixture:

    rootwood_bat      ground -0.77    caught
    mirewood_paddle   ground -1.47    caught
    sunflower_bonker  ground -1.17    caught

The fixture body is an IDEALISED STANDING one -- real measured R15 part sizes,
mirrored left/right with the idle animation's leg rotations zeroed, so the result
is deterministic instead of depending on which animation frame a capture caught.
The live avatar stays the authority; this catches the class of regression.

### FILES CHANGED

  * `src/ReplicatedStorage/SeedGame/Shared/BatSwingMotion.luau` -- waypoints,
    bearing interpolation, `Motion.LowAnchor`, and `Motion.Sample` gains three
    OPTIONAL anchor arguments so a three-argument fixture call still works.
  * `tools/tests/BatClearanceSpec.luau` -- new.

Nothing else. `WeaponFX`, `WeaponData`, `WeaponModel`, `CarryPose`,
`CombatService`, the hit window, timings, prices and models are untouched.

Suites: **BatClearanceSpec 939/939, BatSwingSpec 93/93, WeaponSpec 80/80,
PlotSpec 65/65**, clean `rojo build`.

*One Luau trap worth keeping: `Motion.Bind` seeds a rig with the default anchor
constants, and a `local` declared FURTHER DOWN the file is not in scope inside a
function defined above it -- it reads as a nil global, silently. The defaults are
declared above `Bind` for that reason.*

### STILL OPEN, AND DELIBERATELY NOT TOUCHED HERE

  * **The low-hold bearing.** Unchanged and still the owner's call -- the idle
    carries the bat pointing 26 degrees off straight ahead and within 11 degrees
    of level, which reads as presenting a lance. It is an orientation choice in
    `WeaponModel.GripFor`, not a motion bug, and it is a SEPARATE decision from
    the clipping fixed here. See the section below it.
  * **No second client.** Observer animation is still unverified and the pose is
    client-side.
  * **Two-player PvP combat has still not been run.**
  * Carrying a pod has not been re-tested against the two-hand swing.

## THE TWO-HAND SWING VERIFIED: CONTACT AND RELEASE PASS, CLEARANCE FAILS — 2026-09-07 (in a01c372)

Independent verification of the CODEX two-hand IK swing described in the next
section, run against the real equipped player in Play. **Documentation only —
nothing was changed, reverted, committed or pushed in this pass.**

The headline: the new swing is a genuine structural improvement on the two things
that were hardest to get right, and it introduces two clipping defects that the
existing test suite cannot see.

### WHAT IMPROVED, MEASURED

**Contact alignment is tighter on every bat.** Angle of the barrel off the
AVATAR'S OWN facing at the server's hit instant (`SwingAt + SwingWindup`, on
`workspace:GetServerTimeNow()`), interpolated between the two real samples that
bracket it:

    bat                two-hand IK      previous keyframe swing
    rootwood_bat           2.8                  -0.9
    cactus_club            6.8                  -1.5
    sunflower_bonker       0.3                 -10.9
    mirewood_paddle        1.4                  -7.0
    cindercrack_bat        0.9                  -2.5
    comet_bat              2.5                  -2.8

All six sit far inside the ±37.5° cone `CombatService` already used, and the
Sunflower and Mirewood outliers are gone. **No hitbox was widened.** The arc
roughly doubled: ~111° right to ~-82° left, against ~57°/-51° before.

**The two-hand grip holds.** Measured on the live rig, the palms lock at 0.47
studs apart through the whole active phase — the intended support offset is
`0.38 * scale` below the right hand — and separate to 3.00 studs at rest.

**Animation control is released correctly, and this is the part worth
protecting.** The `swingHeld` one-shot latch survived the rewrite: `Release` is
called EXACTLY ONCE when a swing ends, not every frame. Sweep over a window, in
degrees:

                        idle    walking (391 studs)   jumping
    RightShoulder        0.0          0.0               0.0    held (the pose)
    LeftShoulder         3.4        111.3             197.2    FREE
    Waist                0.7         40.8              17.4    FREE
    RightHip             1.8         99.7              37.8    never touched

A per-frame "restore to rest" here would have reproduced the CarryPose bug that
cost this project three passes. It did not happen.

### THE TWO NEW DEFECTS  (BOTH FIXED -- see the clearance pass above)

Both are present on **all six bats**, and both are in the paths either side of
the strike — the strike itself is fine.

**1. The bat passes THROUGH THE GROUND during recovery.** Lowest weapon corner
relative to the plane the character is standing on, as the barrel returns from
the leftward follow-through to the low hold. Negative is below the floor:

    cactus_club      -0.47      rootwood_bat     -0.85
    comet_bat        -1.01      sunflower_bonker -1.17
    cindercrack_bat  -1.18      mirewood_paddle  -1.36

**2. The bat passes THROUGH THE AVATAR during wind-up.** Body parts overlapped
at some point in the swing: Head, UpperTorso, LowerTorso, both upper arms, both
upper legs, RightLowerLeg. At the wind-up peak specifically, on the Rootwood:

    Head        <- Handle, Bind2
    UpperTorso  <- Handle, Bind1, Bind2, Bind3
    RightUpperArm <- Handle, Bind1, Bind2, Bind3

Visually the bat largely disappears into the character at the top of the load.

### KEEP THIS SEPARATE: THE LOW-HOLD BEARING IS A DIFFERENT, OLDER PROBLEM

**The forward-lance idle hold is NOT one of the defects above and was not
introduced by this pass.** `WeaponModel.luau` and `WeaponData.luau` are
byte-identical to before the two-hand swing landed, and the idle hold measures
the same as it did then — bearing 25.8° off straight ahead, 9.1° below
horizontal on the Rootwood. It is an ORIENTATION choice in `GripFor`, not a
motion bug, and its ceiling is geometric: hand 2.0 studs off the floor against
4.6-8.0 studs of barrel. See THE DEFECT, WHICH IS THE REASON THIS IS NOT DONE
below. **Fixing the clearance defects will not fix it, and vice versa. They
should be judged and scheduled separately.**

### WHAT BatSwingSpec DOES AND DOES NOT COVER

`BatSwingSpec` passes **93/93**, and its own summary line says it plainly:
*"Mathematical fixture only; live animation and PvP require Play."*

**Those 93 checks are ATTACHMENT MATH.** Contact direction and timing, blend
endpoints, grip and socket preservation, support-joint release, and a maximum
computed support-grip separation of 0.000237 studs across 1,098 active-arc
samples at three fixture scales. That is real coverage and it caught real things.

**It contains NO body-clearance and NO ground-clearance assertion.** That is
exactly why a suite at 93/93 and `WeaponSpec` at 80/80 sat green while the barrel
was going a stud and a third into the floor. A green suite here is not evidence
of clearance; nothing in it looks at where the weapon's geometry actually is
relative to the avatar or the world.

### TWO MEASUREMENT MISTAKES MADE IN THIS PASS — DO NOT REPEAT THEM

Both produced confidently wrong readings before being caught. They are recorded
because the next person to measure this will hit them.

**1. An overlap filter of `{character}` silently includes the Tool.** The
equipped Tool is a CHILD of the character, so
`OverlapParams.FilterDescendantsInstances = {character}` with
`FilterType = Include` makes every weapon part test against the weapon's own
parts. It reported large clash counts that were mostly the bat overlapping
itself — and the bat models have parts literally named `Head` and `Handle`, so
the output looked exactly like body collisions. **Build an explicit R15 part
list instead**, and from it exclude:

  * `HumanoidRootPart` — it lives inside the torso and is never rendered, so
    overlapping it is not visible clipping and only adds noise.
  * `RightHand`, `RightLowerArm`, `LeftHand`, `LeftLowerArm` — that contact IS
    the grip, on a two-hand swing doubly so.

**2. Firing an attack while the weapon is on cooldown yields a silent no-swing.**
A bulk sweep over all six bats returned `nan` contact angles for the Mirewood and
the Comet, which read like a defect in those two weapons. They were simply still
cooling down from the previous bat's swing, `Activate()` did nothing, and the
interpolation had no bracket to work with. **Wait on the Tool's `ReadyAt`
attribute against `workspace:GetServerTimeNow()` before every activation.** Both
bats measured normally once that wait was added (1.4° and 2.5°). A missing
sample is not a failed swing.

A third, milder note: at contact the barrel sweeps roughly 2000°/sec, so frames
either side of the hit are 12-26 ms apart and any single quoted contact angle is
an interpolation between two real samples. Sample density has to be reported
alongside the number, not assumed.

### RECOMMENDED NEXT PASS: CLEARANCE ONLY

**Keep the two-hand system. Do not revert it.** The contact alignment, the
support-grip lock and the one-shot release are the hard parts and they work.
The correction wanted is narrow:

1. **Preserve** the forward strike direction, the hit timing against
   `SwingWindup`, and the two-hand contact. Those are verified good; a rewrite
   that loses them trades a fixable problem for solved ones.
2. **Correct the WIND-UP path** so the handle clears the head, torso and upper
   arm on the way up.
3. **Correct the RECOVERY path** so the barrel returns to the low hold without
   dropping below the stance plane. The dip is in the settle, after the
   follow-through, on every bat.
4. **Then add regression coverage using the ACTUAL WEAPON GEOMETRY** — real
   built Tools, all six, corner-sampled against a body-part list and a ground
   plane, asserting a positive minimum clearance through the whole swing. A
   fixture that only checks attachment math will stay green through exactly this
   bug again. The corrected filtering rules above are what that test needs.

**Out of scope for that pass, explicitly:** reverting the two-hand system, and
plant scaling. Neither belongs in a clearance fix.

### HOW THIS WAS VERIFIED

Real equip path only — the `GameEvent` remote with `GameConfig.Weapon.EquipAction`
(the action lives on `GameConfig.Weapon`, **not** on `WeaponData`), then a real
`Humanoid:EquipTool`. Dense sampling on `RenderStepped` and `Heartbeat` together,
~65 samples/sec. Phase-parked stills were driven through WeaponFX's own
`SwingAt` reader rather than by calling the motion module directly — a separate
`BindToRenderStep` driver never won the frame against WeaponFX's `Stepped`
writer, and the parked frames were validated against the live trace
(ground -0.91 parked against -0.78 live; follow-through -81.2° against -82.0°)
before being trusted.

Still outstanding, unchanged by this pass: **no second client**, so observer
animation is unverified, and **two-player PvP combat has still not been run**.
Carrying a pod was not re-tested against the two-hand swing. Console was clean
across the session, 17 services, no errors.

## TWO-HAND SHOULDER-TO-FRONT BAT SWING — 2026-09-07 (CODEX, in a01c372)

The owner rejected the previous swing as lazy and explicitly requested a two-hand
shoulder wind-up into a forward strike. This supersedes the OLD SWING direction
below, not the low one-hand idle, approved bat geometry, or combat rules.

### Changed in this pass only

- New `src/ReplicatedStorage/SeedGame/Shared/BatSwingMotion.luau`: a shared handle
  trajectory with a shoulder-height load, accelerating forward strike, chest
  rotation, leftward follow-through and eased recovery. Both arm chains are
  solved from the avatar's actual AnimationConstraint attachments. The shared
  handle is fitted into both arms' reachable region before solving; clamping
  each arm separately had separated the support hand and was discarded.
- `WeaponFX.client.luau`: evaluates the motion through its existing single
  Stepped writer and replicated SwingAt/Windup/Recover timestamps. The old
  PREP/STRIKE/FOLLOW one-arm path is removed. An incomplete rig retries binding
  on an attack, rather than scanning every frame. An interrupted swing is tied
  to its original Tool and cancelled on unequip, suppression, or a Tool swap.
  Left elbow/wrist are now borrowed during swings and released once afterward,
  along with the previously borrowed left shoulder/waist.
- New `tools/tests/BatSwingSpec.luau`, using the existing fresh-source runner.
  No published animation asset is needed for this procedural path.

Tool.Grip, welds, sockets, limb lengths, bat models, WeaponData, CombatService,
CarryPose and other systems were NOT changed in this pass. Low one-hand idle,
power ladder, prices, hit timing, cooldowns, pod drops and trap fixes remain as
they were. Existing dirty/untracked work was preserved, not committed or pushed.
The original WeaponFX is backed up at
`D:/KAPE/tmp/bat-swing-20260907/WeaponFX.before.luau` for pass-only comparison.

### Verification and boundaries

- BatSwingSpec: **93/93**. Six bats at three fixture scales, **1,098 active-arc
  samples**, maximum computed support-grip separation **0.000237 studs**.
  Covers contact direction/timing, blend endpoints, grip/socket preservation,
  and support-joint release. This is an attachment-math fixture, not a live
  multiplayer test or proof for every possible avatar proportion.
- WeaponSpec: **80 passed, 0 failed**, using fresh-source dependencies.
- Both changed runtime sources compile in Studio; new module fresh-requires;
  Rojo build and git diff --check pass. No new console errors in final Play.
- Live Cindercrack swing through actual Tool activation/server attributes:
  **33 active-arc samples**, maximum measured supporting-hand gap
  **0.0000153 studs**. Closest contact sample was 0.004264s from the server hit
  time, barrel direction in root space **(-0.05457, 0.07772, -0.99548)**.
- Comet load and contact were visually inspected via temporary server-timestamp
  phase holds and screenshots: both hands on the handle, shoulder-side raised
  preparation and front-facing strike. Those probes and their temporary debug
  logging are removed. Do not treat a separately required module's monkeypatch
  inside an MCP command as evidence of what the actual LocalScript executed.
- Live unequip during attack left no equipped Tool; the off elbow returned to
  Animator motion. Re-equipped the same existing bat, temporarily toggled
  PlatformStand and restored it; low-hold right-shoulder magnitude returned to
  0.160842 radians. This is a suppression smoke test, NOT a guardian ragdoll or
  two-player combat test. No inventory/profile fields were directly edited.
- Final Studio state: Play, normal Custom camera restored, existing Cindercrack
  equipped. User artistic approval and a real second-client observer/PvP test
  remain outstanding. No claim of multiplayer verification.

The character-animation/rigging skills informed the single-writer, unchanged
socket and explicit release design. The pose is ready for the owner's eye;
measurements do not substitute for approval of its feel.

## THE LOW HOLD, AND WHAT VERIFYING IT ACTUALLY FOUND — 2026-09-07 (in a01c372)

### THE DIRECTION CHANGED, AND THEN THE NEW POSE FAILED ITS OWN REVIEW

The owner rejected the over-the-shoulder rest and asked for a NORMAL RELAXED
STANCE with the bat held LOW in one hand beside the body. That is built, it is
measurably correct against every number in the brief, and **on screen it still
reads wrong** — see THE DEFECT below. Both halves of that are in this section
because the second half is the part the next session needs.

### WHAT WAS ACTUALLY WRONG BEFORE — THREE LAYERS, NOT ONE

1. **`CarryPose.client.luau` pinned both shoulders every frame.** It "released"
   a joint with `if Transform ~= rest then Transform = rest` inside `Stepped`,
   which runs AFTER the animator — so the guard was true forever and the write
   landed forever. This is why three earlier passes recorded the shoulder as
   INERT and concluded a published animation asset was the only way to swing.
   Fixed with a one-shot `released` latch. **Do not reintroduce it.**
2. **The grip was being fought across two layers.** `WeaponFX` wrote
   `grip.C0 = rest * angles(pose.Grip + perWeapon)` every frame ON TOP of
   `Tool.Grip`. Once the per-weapon offsets were zeroed that write became
   `rest * identity` every frame — which is not "leave it alone", it is "pin it
   at neutral", the exact CarryPose bug a second time.
3. **The old strike landed outside the server's own hit cone.** Measured: the
   hold put the barrel 161.4° BEHIND the avatar and the strike frame sat 89.7°
   off forward with the tip beside the body. `CombatService` accepts a hit
   within ±37.5° of the root's LookVector, so the visible swing and the hit
   were unrelated events that happened to share a clock.

**There is now exactly ONE layer that decides how a weapon sits in the hand:**
`Tool.Grip`, built by `WeaponModel.GripFor(droop)`. Verified on the live avatar
that `Tool.Grip` IS the grip weld's C1 (`handle = hand.CFrame * C0 * C1:Inverse()`
to 0.0000 studs). The arm joints are the swing layer and never touch the weld.
Nothing stacks compensating rotations any more.

`GripFor` builds an explicit orthonormal frame rather than three Euler angles,
because a barrel DIRECTION pins only two degrees of freedom — roll is free, so
solving Euler angles per weapon landed six bats on six different branches with
roll disagreeing by up to 180°, and a paddle showed its edge where a bat showed
its face.

### THE DEFECT, WHICH IS THE REASON THIS IS NOT DONE

Measured on the live equipped player, all six bats, barrel taken from the
Handle's own +Y axis:

    weapon              below horizontal   bearing off straight-ahead   reach
    rootwood_bat               8.8                   25.5              5.69
    cactus_club               10.9                   25.8              4.61
    sunflower_bonker          -6.1  (ABOVE)          25.7              5.44
    mirewood_paddle            5.1                   25.8              8.03
    cindercrack_bat            6.0                   25.8              6.53
    comet_bat                  9.1                   25.7              6.18

Bearing 0 is dead ahead, 90 is the avatar's right. **Every bat is carried within
26° of straight forward and within 11° of level.** That is not a relaxed carry;
it reads as PRESENTING the weapon — a lance held out in front. The front and
side captures show it plainly, and the Sunflower is the worst because it carries
seven degrees ABOVE horizontal.

**AND IT CANNOT BE FIXED BY DROOPING FURTHER.** The hand sits 2.0 studs above
the floor at the low hold and the barrels run 4.6 to 8.0 studs, so the steepest
the barrel can hang before the tip reaches the ground is:

    cactus 25.6   sunflower 21.6   rootwood 20.7   comet 19.1
    cindercrack 17.9   mirewood 14.5      (degrees)

Current droops are already close to those ceilings. **At this weapon scale a
hanging low hold is geometrically impossible** — the only free choice is the
compass BEARING, and it is currently pointed forward. Trailing it back and
outward (bearing ~150°) is the one option that reads as a relaxed carry at this
length, but the owner has rejected a rear-pointing barrel once already in a
different context, so **that is an owner decision, not a fix to make silently.**
Changing it is one constant: `BEARING_X, BEARING_Z` in `WeaponModel.luau`.

### THE SWING IS GOOD, AND IT IS MEASURED  (SUPERSEDED — KEYFRAME SWING)

> **This subsection describes the one-arm PREP/STRIKE/FOLLOW keyframe swing,
> which NO LONGER EXISTS.** `STRIKE_LEAD` and those three pose tables were
> deleted when the two-hand IK swing landed. The numbers below are kept as the
> baseline the new swing is compared against in the top section — they are
> history, not current behaviour. **Everything else in this section (the low
> hold, joint ownership, suppression and recovery) is still current.**


`LOW HOLD -> PREP -> STRIKE -> FOLLOW -> LOW HOLD`, all in front. Contact angle
off the avatar's facing at the server's own hit instant (`SwingAt + SwingWindup`,
on `workspace:GetServerTimeNow()`), sampled at ~65/sec through the real swing:

    rootwood -0.9    cactus -1.5    sunflower -10.9
    mirewood -7.0    cindercrack -2.5    comet -2.8      (degrees)

All six inside the ±37.5° cone `CombatService` already used. **No hitbox was
widened**; the animation was moved onto the existing hit (`STRIKE_LEAD = 0.55`).
The arc runs ~57° right to ~51° left.

**Forward means the AVATAR'S facing**, verified rather than assumed — the same
swing at headings 0 / 90 / 180 / -60 / 137 lands at -1.0 / +2.8 / -0.7 / -0.7 /
-0.4 off facing. Nothing is camera-locked or pinned to a world axis.

*Honest caveat on the contact figure:* at the strike the barrel sweeps roughly
2000°/sec, so the frames bracketing contact are 12-26 ms apart and the quoted
angle is interpolated between two real samples. `cactus_club`'s bracket spans
49.0° -> -3.0°, so its -1.5° carries real uncertainty. The others bracket much
tighter.

### JOINT OWNERSHIP, WHICH IS THE THING THAT BREAKS QUIETLY

Writing `AnimationConstraint.Transform` OVERRIDES the animator for that joint, so
every joint held is a joint the walk cycle loses. Measured sweep in degrees:

                        idle    walking (391 studs)   jumping
    RightShoulder        0.0          0.0               0.0     held (the pose)
    RightElbow           0.0          0.0               0.0     held
    RightWrist           0.0          0.0               0.0     held
    LeftShoulder         3.4        111.3             197.2     FREE
    Waist                0.7         40.8              17.4     FREE
    RightHip             1.8         99.7              37.8     never touched

The off arm and the waist are borrowed for the swing and given straight back.

**A sweep of 0.0 does not prove a script is pinning a joint** — a STATIC
animation pose reads 0.0 too. Reading the VALUE separates them, and that is what
the release checks below actually do.

### SUPPRESSION AND RECOVERY, BY VALUE

LOW_HOLD commands shoulder (6, 0, 7) and elbow (5, 0, 0). Roblox's own tool-hold
animation sits the shoulder near (84, 1, -7).

    bat held        shoulder (  6.0, 0.0,  7.0)   elbow ( 5.0, 0.0, 0.0)   posed
    unequipped      shoulder ( -0.2,-0.6, -5.3)   elbow (11.3,-1.6, 7.5)   released
    holding trap    shoulder ( 83.6,12.4,  5.8)   elbow ( 8.4,-0.4, 6.6)   released
    back to the bat shoulder (  6.0, 0.0,  7.0)   elbow ( 5.0, 0.0, 0.0)   posed
    ragdolled       shoulder ( 83.6,12.4,  5.8)   elbow ( 8.4,-0.4, 6.6)   released
    recovered       shoulder (  6.0, 0.0,  7.0)   elbow ( 5.0, 0.0, 0.0)   posed

Death and respawn: the new character comes up empty-handed with animator values,
and re-equipping restores the hold exactly. `battedTool` gates on
`Category == "bat"`, which is why the trap is left alone.

### FILES CHANGED (all uncommitted)

  * `src/ReplicatedStorage/SeedGame/Shared/WeaponModel.luau` — `GripFor`, and
    `BuildTool` now sets `Tool.Grip` from it. The single holding-orientation
    layer. `LOW_HOLD_HAND` is tied to the arm pose in WeaponFX; change that pose
    and this must be re-measured, not patched around.
  * `src/ReplicatedStorage/SeedGame/Shared/WeaponData.luau` — `Grip: Vector3?`
    replaced by `GripDroop: number?`; `WeaponData.GripOffset` deleted.
  * `src/StarterPlayer/StarterPlayerScripts/WeaponFX.client.luau` — LOW_HOLD /
    PREP / STRIKE / FOLLOW; the whole procedural grip layer removed;
    `STRIKE_LEAD` puts the strike on the server's hit.
  * `src/StarterPlayer/StarterPlayerScripts/CarryPose.client.luau` — the
    one-shot `released` latch. **Load-bearing. Do not revert.**
  * `.claude/settings.json` — NEW. Allowlists the eight Roblox Studio MCP tools
    for this project, at the owner's explicit request.

Antigravity's duplicate-`Wrist`-declaration cleanup is kept.

### VERIFIED

Automated, in Edit against the on-disk source: **WeaponSpec 80/80,
PlotSpec 65/65, StarbloomLimbSpec 71/71.**

One client, in Play, through the REAL equip path (`GameEvent` +
`GameConfig.Weapon.EquipAction`, then `Humanoid:EquipTool`) — note that the
action lives on `GameConfig.Weapon`, NOT on `WeaponData`:

  * All six bats hold with **zero body clashes** beyond the gripping hand and
    forearm, ground clearance 0.42-0.49 studs.
  * Swing contact, arc, and heading-independence as tabulated above.
  * Walking (391 studs of real displacement), jumping, unequip, switching to the
    trap and back, ragdoll via `PlatformStand` and recovery, death and respawn.
  * Console clean: 17 services ready, no errors or warnings.
  * Front and side captures of all six holds, plus five-frame swing sequences
    from the side and the front. **These are FRAME SEQUENCES, not video** — the
    MCP tooling has no recorder. Each frame is the real animation parked at one
    instant by rewriting `SwingAt` to `now - t` every Heartbeat, so the pose
    shown is WeaponFX's own, not a re-creation. The strike frames carry the same
    timing jitter noted above (captured near -20° where the sampled contact is
    -1°).

### NOT VERIFIED

  * **No second client.** Nobody has watched another player's hold or swing, and
    the pose is client-side. Observer animation is UNVERIFIED.
  * **Two-player PvP combat is still unrun**, carried over from earlier passes.
  * **Carrying a pod** was not re-tested after this rewrite. Unequip, trap,
    ragdoll and respawn all exercise the same `mayPose` suppression path and all
    pass, but the pod case specifically was verified against the OLD pose only.
  * `Combat.SwingAnimation` (ToolSlash) still plays and is still a garnish.

### ONE UNINTENDED SIDE EFFECT, AND IT IS THE OWNER'S TO UNDO

During this session three grown plants moved from the plot bed into the bag —
**Cinderpaw t6, Novaorb t7, Crookreed t5** — leaving 9/20 in the bed. They are
INTACT in the Backpack with species, tier and kg unchanged, and replanting them
restores them fully (a hatched creature goes back in the ground already
earning). The only code path is an E-hold on the plant's `PickupPrompt`;
**no keyboard input was sent by this session** and the `PickUp` remote action was
never fired, so the trigger is unexplained. It is recorded here rather than
quietly fixed because putting them back is another write to a live profile.

Studio state was otherwise restored: camera to `Custom`/Humanoid/FOV 70,
`AutoRotate` true, `Lighting.Brightness`/`GlobalShadows` to MapService's authored
values, the loadout back to `mirewood_paddle`, and the `_G` helpers cleared.

## Bat Handling & Forward Swing Kinematic Solve — 2026-09-04  (SUPERSEDED)

> **The pose in this section is SUPERSEDED and was REJECTED by the owner.**
> It rests the bat over the right shoulder with the hand beside the head.
> The owner's direction is now a LOW HOLD — bat carried low in one hand
> beside the body — and the section below it is the current state.
> Its clearance tables describe a pose nothing builds any more.

Replaced the rejected ready pose and backward swing with an anatomically solved R15 kinematic solve across all 6 bats (`rootwood_bat`, `cactus_club`, `sunflower_bonker`, `mirewood_paddle`, `cindercrack_bat`, `comet_bat`) in `src/StarterPlayer/StarterPlayerScripts/WeaponFX.client.luau` and `src/ReplicatedStorage/SeedGame/Shared/WeaponData.luau`.

### Root Cause of Previous Rejection
1. **Inverted Joint Flexion**: The previous implementation wrote `Elbow = Vector3.new(-145, 0, 0)`. Negative angle on an R15 elbow hyperextends the joint backward rather than flexing naturally forward/up.
2. **Band-Aid Grip Hack**: To force the bat upright after breaking the arm kinematics, a massive rotation `Grip = Vector3.new(140, 35, -80)` was piled on top of the grip weld, pointing the barrel diagonally across the face toward the left shoulder.
3. **Inverted Swing Trajectory**: Because the ready pose rested over the left shoulder, the swing was authored sweeping from left to right, rising up and swinging *behind* the avatar's back rather than striking forward.

### Anatomical & Forward Kinematic Solution
Built and validated using the live R15 rig's attachment frames (`child.CFrame = parent.CFrame * att0.CFrame * Transform * att1.CFrame:Inverse()`):
1. **READY Pose**:
   - `Shoulder = Vector3.new(-20, 0, 40)`: Right upper arm naturally abducted away from ribs and slightly pitched back.
   - `Elbow = Vector3.new(105, 0, 0)`: True anatomical positive flexion, folding the forearm up and forward so the hand sits beside the outer right shoulder.
   - `Wrist = Vector3.new(-25, 0, 0)`: Natural slight wrist extension that aligns the bat barrel extending backward over the right shoulder at a ~20.0° upward pitch (closer to horizontal than vertical).
   - `Waist = Vector3.zero`, `Left = Vector3.zero`: Chest and off-arm remain natural, relaxed, and fully driven by the animator/walk cycle.
   - `Grip = Vector3.zero`: Zero artificial grip hack. `Tool.Grip` (`Angles(-100, 0, 0)`) sits naturally in the hand.
2. **SWING Sequence (Forward Strike Across the Front)**:
   - `READY -> WINDUP -> STRIKE -> FOLLOW -> READY`:
   - `WINDUP`: Torso coils +16° right (`Waist = (0, 16, -2)`), right shoulder draws back slightly loaded (`Shoulder = (-28, 8, 46)`, `Elbow = (112, 0, 0)`), off-arm balances (`Left = (-12, 0, -18)`). Bat barrel remains cocked behind shoulder.
   - `STRIKE`: Waist unwinds with power through neutral to -22° left (`Waist = (0, -22, 4)`), shoulder drives forward (`Shoulder = (35, -25, 10)`), elbow extends naturally (`Elbow = (70, 0, 0)`), and wrist releases forward (`Wrist = (0, 0, 55)`). The bat sweeps cleanly from right to left across the front through the frontal target area at chest-to-waist height (midpoint $Z = -0.61$ to $-1.15$, tip $Z = -1.35$ to $-2.36$, height $Y = 2.42$).
   - `FOLLOW`: Waist completes follow-through to -36° left (`Waist = (0, -36, 6)`), arm decelerates cleanly across the left hip (`Shoulder = (25, -35, 5)`, `Elbow = (85, 0, 0)`, `Wrist = (0, 0, 70)`), before smooth hermite settle back to `READY`.

### Measured Clearance Across All 6 Bats (Zero Clipping)
Tested and verified in Edit mode with live R15 dummy:
- `rootwood_bat`: READY Pitch 20.0°, HeadClr 1.98s, TorsoClr 1.59s | STRIKE TipZ -1.35, TorsoClr 0.71s
- `cactus_club`: READY Pitch 20.0°, HeadClr 1.89s, TorsoClr 1.63s | STRIKE TipZ -1.35, TorsoClr 0.45s
- `sunflower_bonker`: READY Pitch 20.0°, HeadClr 1.92s, TorsoClr 1.63s | STRIKE TipZ -1.35, TorsoClr 0.61s
- `mirewood_paddle`: READY Pitch 20.0°, HeadClr 1.99s, TorsoClr 1.59s | STRIKE TipZ -1.35, TorsoClr 0.67s
- `cindercrack_bat`: READY Pitch 20.0°, HeadClr 1.97s, TorsoClr 1.60s | STRIKE TipZ -1.35, TorsoClr 0.63s
- `comet_bat`: READY Pitch 20.0°, HeadClr 1.92s, TorsoClr 1.63s | STRIKE TipZ -1.35, TorsoClr 0.64s
- Full continuous timeline check: overall minimum head clearance is 1.83 studs, minimum torso clearance is 0.85 studs throughout the entire swing and settle.

### Status & Git Policy
- All edits left **uncommitted** in the working tree for the owner's playtest.
- `rojo build -o build/StealASeed.rbxlx` passes clean.
- `git diff --check` passes clean.
- Test dummy was destroyed after measurement; workspace is clean.

## Premium creature reference skill -- 2026-09-04

Added `seed-premium-creature-art` under `.agents/skills/`, with a matching `.claude/skills/`
compatibility pointer. Both agents use the same instructions and two saved user-supplied images.
The reference study distinguishes observed anatomy from inferred construction: a long blue maw
with a pink interior, a floral quadruped, and the earlier crouching horned green creature.

This is skill authoring only. No Divine/Secret species, pod models, live data, geometry, animation,
or Studio state were changed. Divine/Secret color and motif suggestions are proposals, not approved
palettes or new size tiers. The skill preserves primitive-only construction, current scaling and
economy, hidden hatch results, existing previews, and separate visual/runtime approval. Historical
kg-era skills are explicitly not authority to restore obsolete systems.

Skill frontmatter, local reference paths, saved reference image hashes and whitespace passed
direct checks. The bundled Python validator could not run because PyYAML is absent; this is not
reported as a validator pass. No future model quality or runtime behavior is claimed as tested. The pre-existing
shop/loadout/swing/trap changes and their handoff entries remain owned by the ongoing work. Only
this new skill/reference package, its AGENTS skill-list entry, and this handoff entry belong to
the premium-skill commit.

## Where it stands (2026-08-20)

**Phase A: the map, and who owns which piece of it.** The world exists, is dressed, and hands
itself out. Still missing: profiles, save, seeds, carrying, planting, economy, HUD.

```
src/ReplicatedStorage/SeedGame/Shared/
  GameConfig.luau     names, capacity, map geometry, the speed curve, save schema
  BiomeData.luau      the five biomes and where they sit on the road
src/ServerScriptService/SeedGameServer/
  ServerMain.server.luau   bootstrap: Init() all, then Start() all
  MapService.luau          layout, lighting
  PlotService.luau         the plot <-> player lease, and the overflow queue
  ProfileSchema.luau       what a profile is + the validator  (NOT a *Service)
  SaveService.luau         DataStore transport, session locking
  PlayerDataService.luau   profiles in memory, autosave, replication
  MapDecor.luau            dressing  (NOT a *Service -- see below)
```

**1,204 parts, built in 0.12 seconds.** Zero gaps in the road, zero solid decoration, zero tall props
inside the racing line.

**Fifteen parts are unanchored and all fifteen are Marigold** — a Humanoid cannot walk anchored.
This line used to read "zero unanchored", which was true until she existed; anything else loose in
the world is a bug.

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

## A PLOT IS PLAIN DIRT AND A WOODEN FENCE

Nothing else. The first version was a coloured deck with a planter box, a treadmill and a rim, and
six of those side by side read as a row of arcade cabinets rather than a row of gardens. Every one
of those props would have been noise behind the plants that are eventually meant to stand there.

**The whole plot is the planter.** There is no box to walk up to -- the `Planter` tag sits on the
plot's own soil, so a seed goes into the ground it was carried home to. That removes an object and a
step, and it is what "plant it in your plot" should have meant from the start.

Visible materials on a plot are exactly `Ground` and `Wood`, and there is a check for it. The only
non-soil, non-fence object is the owner sign, which earns its place: without it nobody can tell
whose garden they are standing in, and UNCLAIMED is how a new player finds a free one. The
SpawnLocation is invisible -- it is a hook for `Player.RespawnLocation`, not scenery.

Treadmills moved **off** the plots onto the grass in front of each one, which is also where the
reference game puts them. They are the one deliberately collidable thing out there, because you
stand on them.

The SELL stall moved to the **upper left of the field**. In the middle it sat on the exact line
every player runs between their plot and the road -- a shop should be somewhere you choose to go,
not something you run around twice a lap.

## A PLOT IS A LEASE ON THIS SERVER, NOT A PROPERTY OF AN ACCOUNT

**This is the decision the save schema hangs off, so settle it before writing one.** WHICH plot you
get is never saved. It is a slot in *this* server: lowest free id on arrival, handed back on
departure.

What persists is what is *on* a plot — its tier, and later its plants — restored onto whatever
ground the lease gave you this session. Saving the plot id buys nothing and costs plenty: a
returning player either waits for "their" plot while three sit empty, or is quietly given a
different one anyway — which is this behaviour with an extra field to keep in step. And a stored
plot id is a **pointer into the map**, while the map is code that moves every time the geometry
does.

**Nobody shops for a plot.** No claim prompt, no board to walk up to, no choosing. Picking is a
decision with no inputs — the plots are identical — so the only thing a player learns from choosing
is that the game made them do paperwork first.

**More players than plots is the normal case, not the error case.** `MaxPlayers` is 60 against six
plots until somebody opens Game Settings, so a joiner with no plot goes into a **join-ordered
queue** and stands on the overflow pad in the hub until one frees. Not a kick and not a random draw
— both punish a player for a setting they cannot see.

**A lease that ends returns the ground empty.** Release clears the plot's `Plants` and `Runtime`
folders, so the next player cannot inherit the last one's crop. That is the invariant PlotService
owns and nothing else can: **anything that puts something on a plot puts it in one of those two
folders and gets cleanup for free.** When tiers ship, release gains one more job — a plot left at
tier 3 is the wrong *shape* for an arriving player whose save says tier 1, so handover will have to
rebuild it.

### Two things that were nearly wrong

  * **Plots are found by TAG, not by folder children.** `Plots` holds twelve children for six plots
    — each plot has a treadmill parked beside it in the same folder. Taking every child would have
    handed somebody a treadmill and reported twice as many plots as exist. Measured: *12 children,
    6 tagged.*
  * **Telling the client is not part of the transaction.** `FireClient` sat in the middle of
    `assign`, so anything it threw left the lease half-applied — attributes stamped, tables updated,
    listeners never run. Not hypothetical: that call throws in the Edit datamodel, where
    `IsServer()` is false. It is pcall'd and runs last now, which is why assignment still completed
    in Edit while the notification failed.

**Placement is `PivotTo`, not `RespawnLocation`.** RespawnLocation is set too — one line, and the
engine then usually spawns a character roughly right rather than at the origin — but nothing relies
on it. It cannot express a queued player's destination, which is a marker Part on the hub deck
rather than a SpawnLocation; and the plot pads are deliberately `Enabled = false`, because six
enabled spawns on one field would scatter players through other people's gardens any time
RespawnLocation went unhonoured. One mechanism covering every case beats two covering half each.
The pivot runs after `HumanoidRootPart` exists, so it corrects rather than races.

## A PLOT IS ONE BED OF SOIL IN A WOODEN FRAME

Built to the owner's photo, [plot-bed-reference.png](plot-bed-reference.png). A fenced square of
studded grass with a single rust-brown soil rectangle set into it, ringed by a low wooden border.

An earlier version split it into two framed blocks divided into visible rows. The reference is one
plain rectangle and it is the better read — soil is soil, and drawing rows on it before anything
grows there is labelling an empty field. **The grid still exists, it is just invisible**: plant slots
are `Attachment`s laid out columns × rows across the surface, so a slot costs nothing until something
occupies it. A row is still a slot row, so the plant count and the bed's depth cannot drift apart.

**Elevation is 0.5.** It was 2.2, which made every plot a platform you climbed onto rather than a
bed set into the lawn.

**Beds are `Plastic`, not `Ground`.** `Ground` was the obvious material for soil and it is the wrong
one — its noise texture renders *over* the studs, so a bed set to `TopSurface = Studs` came out
smooth while the grass around it was visibly studded. `Plastic` is the material that actually shows
them.

**The border is four bars, not one slab — and this one cost a build.** A single slab looks like the
economical choice, on the reasoning that its middle is hidden under the soil anyway. It is not: the
border stands *proud* of the soil (`BedFrameLip` above `BedHeight`), so a solid slab's top face sits
ABOVE the soil and covers every stud of it. The whole plot rendered as a wooden floor with no dirt
anywhere in it, and the numbers all still checked out — soil material, colour, height and stud
setting were each individually correct while nothing could see them. **Verifying a part's properties
is not verifying that the part is visible.**

**The treadmill sits beside the plot, not in front of it.** It used to be on the ring's inner
walkway directly outside the gate — the one patch of ground every single run passes through, an
obstacle parked in your own doorway. It is now placed off the plot's own CFrame, so it swings round
with the plot and needs no angle maths of its own.

**The fence encloses all four sides, with a gap at the front for the gate.** Two taller capped
gateposts flank it. The fence is non-collidable throughout, so the gap is not what lets you in — you
could always walk through the rails — it is what *shows* you the way in. A sealed rectangle read as
a pen rather than as a garden. The opening faces the road, so you arrive at your gate rather than at
the back of a fence, and the invisible spawn sits three studs inside it.

**There is no owner sign, and there will not be one.** An UNCLAIMED board existed so a new player
could find a free plot — and nobody ever does that: `PlotService` assigns a vacant plot the moment
you spawn. Every sign in the row would just read as somebody's name. If in-world ownership is ever
wanted, it goes over the gate, seen on the way in, rather than on a board facing an empty field.

## PLOTS RING A CENTRAL HUB, AND EXPAND OUTWARD

From the owner's second sketch, [plot-ring-reference.png](plot-ring-reference.png). Six plots
around a fenced circle with the SELL stall inside it, gates facing in, road leaving through a gap in
the ring.

**A ring gives more room the further out you grow.** Plots expand outward, so their gates never move
and the gaps between them at the inner edge never change — while the arc at their outer edge gets
*longer* as the radius does. A row could only expand into space reserved up front; a ring makes room
as it goes. That is why this shape was worth the rebuild.

It also puts the hub the same distance from every plot — **every gate is at radius 100.0, verified**
— which the row never did: the end plots were 145 studs from the centre and the middle ones 29.

The stall moved from the field's upper-left corner into the hub. The corner was right for a *row*,
where it kept a shop off the one strip everybody ran down. A ring has a natural centre instead, and
nobody has to detour to a place everybody already passes through.

### What a ring costs, measured

Gate-to-red-line distance is **141 / 219 / 264 / 264 / 219 / 141** studs — a spread of **123**. The
row's spread was 116, so this is very slightly worse and not materially so. Worth knowing rather
than assuming: it is the one real price of the shape, and it is small.

### Angles avoid the road rather than hoping

Plots are spread evenly across `360 − RoadGapDegrees`, starting at the far edge of the empty arc, so
gaps between neighbours are equal AND nothing is ever placed in the road's mouth. Placing six evenly
round a full circle and hoping none lands in the way would work until `MaxPlots` changed.

`CFrame.lookAt(pos, hub)` points local −Z at the centre, and local −Z is where `buildPlot` puts the
gate — so every gate faces in and every plot grows out, with no per-plot rotation maths.

### Row-layout leftovers removed

`Plot.FrontZ` and `Plot.MaxBackZ` were the row's anchor — one world Z every front edge sat on. On a
ring the anchor is a radius, so they are gone rather than left as numbers that look authoritative
and mean nothing. `MaxReach` (hub → deepest tier) replaces `MaxBackZ`. Field decoration is placed by
radius now, outside the ring, instead of in a "strip between the plots and the red line" that no
longer exists.

## PLOTS EXPAND OUTWARD, AND THE ROOM IS ALREADY RESERVED

The expansion SYSTEM is Phase D. The SPACE it needs is reserved now, and that ordering is the whole
point: an upgrade button is a day's work whenever it is wanted, but plot geometry is baked into the
map. A plot that has to grow with no room reserved forces every other plot to move, and everybody's
saved plot id then points at a different patch of ground.

**Plots are anchored by their road-facing edge** (`Plot.FrontZ = 21`, fixed forever) and grow
backward. So expanding never moves the point an owner runs in through, and **the trip home is the
same length at tier 4 as at tier 1** — which is the property that was just bought by tightening the
field, and would have been thrown away by growing sideways.

Growing sideways would have meant a wider pitch, a wider field, and a longer diagonal from the
outermost plot to the road. **Depth is free; width is not.**

The field is asymmetric for this: `FieldFront = 85` toward the road (must never grow),
`FieldBack = 180` away from it (deliberately oversized, empty grass today).

Tiers are defined in **rows**, and depth is derived — so a tier cannot be given a size that does not
fit a whole number of beds.

| tier | rows | beds | depth | back edge |
| --- | --- | --- | --- | --- |
| 1 | 4 | 8 | 59.6 | Z=81  ← built |
| 2 | 6 | 12 | 84.0 | Z=105 |
| 3 | 8 | 16 | 108.4 | Z=129 |
| 4 | 10 | 20 | 132.8 | Z=154 |

Field back is Z=180, so tier 4 fits with 26 studs to spare — and `MapService` **warns at boot** if a
future tier stops fitting, because a reservation nobody verified is a guess.

Tier 4 was built through the real code path and photographed before being reverted: six long
allotment strips, front edges all still at Z=21, 10-stud gaps between neighbours, treadmills still in
front. Long thin strips are what an allotment actually looks like, which is a happy accident of the
constraint that keeps the run home constant.

Shipping tier 2 is changing a player's stored tier number and rebuilding their plot. No map surgery,
no repacking the row.

## MARIGOLD, THE FAIRY WHO RUNS THE STALL

A real **R6 Humanoid** with wings, 14 parts and 6 Motor6Ds, built in code — not
`CreateHumanoidModelFromDescription`, which is a web call needing API access, carries asset ids that
can 404, and has the trap the predecessor hit: a fresh `HumanoidDescription` defaults every body
colour to BLACK, and the BodyColors rides along inside a `:Clone()` and repaints the rig on parent.
The one external reference is the face, and it is `rbxasset://` — shipped in the client, not
uploaded — so it is exactly as available as the engine.

**The server walks her; every client animates her.** `FairyService` drives `Humanoid:MoveTo` around
a wander box, because a Humanoid *is* server-simulated and faking a walk per-client would put her
somewhere different for every player — fine for a hovering sprite, not for a character standing on a
floor who will one day carry a shop prompt. `Ambience.client.luau` flaps the wings and swings the
limbs. **The two never write the same property**: the server owns her root's position, each client
owns `Motor6D.C0`. That is why they cannot fight.

### Measured, not guessed — three of these were wrong first

  * **`Motor6D.Transform` does nothing here.** It is the field Roblox's own animator uses and the
    obvious choice, but it is consumed and reset by the animation step — so it cannot even be tested
    in Edit — and any Animator the Humanoid gains overwrites it every frame. Composing `C0` against
    a rest pose captured once is a plain property that stays put.
  * **Limbs swing about local Z, not X.** R6 bakes a ±90° yaw into every shoulder and hip `C0`, so
    the joint's axes are not the torso's. X slides an arm sideways (dX −0.50, dZ 0.00); Z swings it
    forward (dZ −0.35).
  * **Both sides take the SAME sign.** The left joints are already mirrored by that −90° yaw, so
    opposite signs cancel the mirroring out — she walked doing star jumps.
  * **The produce is on trays at her sides, not on a shelf behind her.** A high back shelf put the
    whole display directly above Marigold, so the thing the stall sells and the person selling it
    competed for the same patch of screen and she lost. On the counter beside her the goods are at
    the height a customer actually looks at, and she has the middle to herself.
  * **She was invisible behind her own counter**: five studs tall, head exactly level with a
    5.4-tall counter top. Fixed with a raised deck *behind* the counter rather than by shrinking the
    counter, which would have made it ankle-high for the players walking up to it. The customer side
    stays flush, so nobody has a step to climb to reach the shop.

Earlier, as a hovering sprite, she was also made entirely of `Neon` — which **clips** at Brightness
2.4 rather than glowing, turning her into a featureless white blob — with wings as flat horizontal
panels, and hair and wings offset to −Z, which is **forward** in Roblox.

## THE HUB

No fence. It had a ring of posts and rails, and **a fence around a shop says keep out** — the
opposite of what a shop is for. A low sand deck with a darker rim marks the square instead: a floor
you walk onto rather than a barrier you walk through.

The stall is dressed now — plank counter, striped awning, back shelf of jars, crates of produce,
lanterns on the posts. The jars are one part each and are the cheapest possible "somebody works
here".

## PLOTS SIT IN THE GROUND, NOT ON IT

The plot had a 2-stud grass slab, so every one was a platform you stepped up onto. The fix was
**removing** the slab, not sinking it: plots are rotated to face the hub, so their stud grid runs at
an angle to the field's, and a rotated studded patch laid on a studded field shows a seam at every
plot no matter how thin. With no slab, the field's studs run continuously under the fence and the
beds. The **fence** marks the plot now, which is what a fence is for.

A 0.2-stud invisible footprint survives as `PrimaryPart` and as the rectangle every fit check
measures. Beds sit directly on the field.

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

## SAVING, AND THE ONE RULE THAT MATTERS

**Never write a profile you did not successfully read.** Every account-wiping bug in every simulator
ever shipped is this one: a read fails for three seconds, the game hands out a fresh profile because
that is the graceful-looking thing to do, and ninety seconds later the autosave writes those
defaults over a year of progress. Nothing errored.

So `SaveService.Load` returns a **status**, not just data, and four cases stay deliberately distinct:

| status | meaning | may we write? |
| --- | --- | --- |
| `ok` | read it, here it is | yes |
| `new` | read it, genuinely nothing there | yes |
| `locked` | another live server holds it | no |
| `unavailable` | DataStores unreachable this session | **no** |
| `failed` | tried, could not | **no** |

`new` and `failed` look identical from outside — both are "no data" — and treating them the same
*is* the bug.

**`unavailable` gives a temporary profile; `failed` kicks.** Not the same. `unavailable` is the
normal state of a Studio place without API access, so kicking there would make the game untestable;
instead saving is switched off and it says so loudly. `failed` means the store exists and would not
answer after five attempts across ~15s — a real outage — and kicking is the *kind* option, because a
player bounced with an honest message rejoins in ten seconds while a player whose account is erased
does not come back. "Do not save this" is a property of the entry, checked at every write, never a
flag each call site remembers.

**The session lock** closes the classic hop: leave server A, join B before A has written, B loads
stale data, B saves over A. Load claims the profile *inside* an `UpdateAsync` — read and claim as
one atomic operation, because doing it in two is the race it exists to close — and Save refuses to
write if somebody else now holds the claim. A claim older than `SessionLockSeconds` is taken, since
servers crash without releasing and a profile locked forever by a machine that no longer exists is
worse than a little contention.

**Sanitising is the migration strategy.** A loaded profile is poured into fresh defaults field by
field; anything missing, mistyped or out of range gets the default. Adding a field therefore needs
no migration ladder — old profiles just get the default, which is what a migration would have
written. `Version` is carried so the day a field must be *reshaped* can be detected. Unknown keys
are dropped by construction, because everything copies *from* raw *into* a default.

**NaN is checked separately, and it is not pedantry.** NaN fails every comparison you would normally
write, so a plain clamp passes it straight through — verified: `math.clamp(NaN, 0, 1e15)` returns
`nan`. One NaN in Cash poisons every sum it touches, saves cleanly, and reloads as NaN forever.
`value ~= value` is the whole test.

**The cash cap is 1e15, and the rate is the real lever.** Luau doubles are exact to 2^53 (~9.007e15)
and silently approximate above — no error, just cash that stops adding up and a profile that
round-trips to a different value than it left as. The reference game's 2.7B/sec would eat 1e15 in
four days, which is not an argument for a bigger number because there isn't one: 9e15 is only 9×
further and no cap survives an unbounded rate. Plant yields get tuned so Rebirth arrives before the
ceiling does.

### Verified 2026-08-21 against the real DataStore

`ProfileSchema` passes 21 assertions — NaN, infinity, negatives, over-cap, bad types, tier
out-of-range, absent fields, unknown keys, absurd timestamps. Round-trip confirmed: a profile with
nested `Plants` data saved and reloaded identical. A save attempted while another JobId held the
lock was **refused** rather than clobbering. This place has Studio API access **on**, so all of that
ran against a live store rather than a mock; the test profile was reset to defaults afterwards.

## CARRYING, AND TWO BUGS THE ORDER OF OPERATIONS CAUSED

Both found by review rather than by play, and both are the same shape: a
mutation happening before the thing that decides whether it should.

### The thrown player kept their carry speed

`throwPlayer` captured `humanoid.WalkSpeed` **before** setting `PlatformStand`.
Setting PlatformStand is what makes `CarryService` drop the pod, and its drop
calls `RefreshWalkSpeed` — so the correct unencumbered speed only comes into
existence *after* that line. The captured value was the CARRY speed, and
restoring it after the flight left the player trudging along with empty hands
until something else happened to refresh them.

Ragdoll first, capture second. The `task.wait()` between them is load-bearing:
property-changed signals are deferred, so without it the capture still reads the
pre-drop value.

Grabbing also sets `WalkSpeed = 0`, so anything that threw between the grab and
the landing stranded a player at zero permanently. There is now **one** `restore()`
reached by every exit — success, early return, and the error path — because a
lock only one branch releases is not a lock, it is a trap.

Measured: carrying 5 kg gives 15.883; after being grabbed, thrown and landed the
player reads **16.0000**, which is `walkSpeedFor(0)` exactly, not the 15.8829 the
old code restored.

### Taking a pod could destroy the prize

`TryTake` called `NestService.TakePod` and *then* checked for a Head. `TakePod`
is not a query — it clears the nest slot, starts the wake timer and destroys the
pod. A player with no Head (mid-respawn, or dying in the same frame) left the
parent waking over an empty slot with the pod gone and nobody holding it.

Everything that can refuse is now checked before anything is touched: player
present, character alive, Humanoid with health, Head is a BasePart, pod still
parented with a PrimaryPart, and **the server measures the distance itself** —
the prompt is a courtesy drawn on a client, not a security boundary.

The one step that cannot be pre-checked is attaching to the character, so if
that fails the species goes back on the ground as a loose pod rather than
vanishing. Two players racing one pod still only ever produces one winner,
because `TakePod` checks `pods[slot] ~= pod`.

### One name per fact

`GameConfig.Attributes` said `CarryingSeed` while `CarryService` wrote
`CarryingSpecies` and `CarryingKg`. Both names now live in `GameConfig` and
every reader — server and client — takes them from there. Two names for one fact
is a bug waiting for whoever trusts the wrong one.

## THE RAID LOOP, END TO END

    take (hold E)  ->  carry, slowed by kg  ->  caught: ragdoll drops it
                                            ->  reach the red line: banked to the hotbar

**A dropped pod sits on the ground.** Pods are anchored and nothing in this game
falls, so anything placed has to be placed correctly. Dropping used the player's
ROOT position — about three studs up — and the pod hung there. It casts down now
and puts its base on whatever it finds, with the field surface as the fallback.
Measured: 0.05 studs of gap, against roughly 3 before.

**Picking a dropped pod back up wakes the same parent again.** A pod knocked out
of a thief's hands is still that nest's pod, and strolling back to collect it
must not be free — otherwise being caught once makes the rest of the raid safe.
The loose pod carries `FromNestId` (deliberately NOT `NestId`, which would route
it back through `TakePod` looking for a slot it no longer occupies), and
`NestService.Provoke` re-targets without clearing a slot or destroying anything.
One `provoke()` defines what "somebody stole from me" means, so taking and
re-taking cannot drift apart.

**Crossing the red line banks it.** The pod on your head becomes a Tool in your
hotbar: it stops being a thing that can be knocked out of your hands and becomes
a thing you own. That is what finally makes the walk home mean something —
everything between the nest and the line is at risk, everything past it is
banked. Verified: at z −140, `IsInSafeZone` true, head empty, hotbar holds
`Nubkin [nubkin, 2 kg, handle=true]`, WalkSpeed back to 16.

It is a POLL, not a `Touched` on the stripe. The stripe is a thin
non-collidable decal a player at WalkSpeed 150 can cross between two frames
without ever touching, and the safe zone is a region rather than a part.

## ONE NEST PER BIOME, AND A PARENT THAT ESCALATES

**One nest, at the far corner.** Nests used to be spread down the segment and the
first sat close enough to the safe line to be raided almost from home — which
made the length of a biome optional. You could farm the near nest forever and
never walk the rest of it. One nest at the far end means raiding Greenhollow
requires crossing Greenhollow. Sides alternate by biome order so a player running
the whole road is not hugging one wall the entire way.

**A pod is as big as it is heavy.** `1.2 * kg^0.28`, clamped 1.3–4.5. Every pod
used to be identical, which threw away the one thing a player most needs before
committing to a hold: what this will cost to carry. Now the trade is readable
from across the nest with no UI. Measured: Nubkin 2 kg → 1.46, Bellchime 110 kg
→ 4.47.

**The parent is fast.** 26 at biome 1 against a fresh player's 16 (it was 19,
which felt like a hazard you could stroll away from). 74 at Starbloom.

**And it escalates.** Every theft while it is still angry adds 5, up to 4 stacks.
Verified: take #1 chased at 31, take #2 at 36.

### Two bugs behind those, both invisible by inspection

**`AutoRotate` did nothing because the assembly root was wrong.** Every part on
the rig is `Massless` so it cannot out-weigh its own Humanoid — including the
HumanoidRootPart, which quietly made the **Torso** the assembly root, because a
massless part cannot root an assembly. Roblox rotates an assembly about its root,
so the Humanoid turned a HumanoidRootPart that was steering nothing and the
creature walked home backwards with `AutoRotate` switched on. `Humanoid.RootPart`
said `HumanoidRootPart` while `root.AssemblyRootPart` said `Torso` — **those two
disagreeing is the bug**. Giving the root mass fixed it: facing-vs-motion went
from −1.00 to +0.80.

The manual `root.CFrame` write that used to hide this is gone too. It only ran
while *chasing*, which is why the walk home was the backwards half, and it
teleported a physics assembly eight times a second while the Humanoid was trying
to move it.

**Rage reset on sleep, which made it unreachable.** A caught player is thrown
clear, the parent walks home and settles within a couple of seconds, and the pod
is still on the ground — so by the time anyone picks it back up the anger was
already gone. Measured before the fix: two thefts in a row, both at 31, when the
second should have been 36. It fades on a timer now
(`RageForgetSeconds = 45`), so coming back for a dropped pod is exactly the case
that stacks, and a nest left alone still forgives.

## Things worth not rediscovering

  * **Moving the Edit viewport takes `Camera.Focus`, not `Camera.CFrame`.** Writing `CFrame` alone
    appears to work — you can read the new value straight back — and the viewport quietly keeps
    rendering from wherever it was, so every screenshot comes out of the old camera and looks like a
    stale capture. The editor camera derives its own CFrame from `Focus`; set both and it moves.
    This is how you photograph a specific corner of the map without starting a Play session.
  * **The map is `Archivable = false`, and that is load-bearing.** A copy of it saved into the
    .rbxl is the one thing this project exists not to have — the runtime build would fight a stale
    duplicate every boot. The old guard was a human rule ("delete SeedMap before saving"), which is
    both forgettable and actively harmful: obeying it left Studio looking empty, which reads as
    breakage. The engine flag does the job unconditionally — excluded from save AND from clone, so
    Play cannot inherit an Edit-built copy either. **Do not delete the map from Edit any more.**
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

**It runs.** First real Play boot on 2026-08-21, and `start_stop_play` over MCP did **not** wedge
Studio this time — the three failures on 2026-08-20 have not recurred since Studio was restarted.

Measured in a live Play session, single player:

```
[Seed/MapService] Built SeedMap: 6 plots, 5 biomes, 1204 parts. Road is 1500 studs end to end.
[Seed/PlotService] Ready. 6 plot(s): 1, 2, 3, 4, 5, 6.
[Seed/FairyService] Ready. 1 fairy(s) walking, 13 x 4 studs of wander.
[Seed] Steal a Seed v0.1.0 (Phase 1) online -- 3 service(s): MapService, PlotService, FairyService
```

  * Plot assigned on join, `Claimed`/`OwnerUserId`/`OwnerName` all stamped, `RespawnLocation` set.
  * **`PivotTo` puts the character on its own pad to 0.00 studs.** Standing in the gate between the
    posts, on the grass margin in front of the soil rather than in it, facing the hub.
  * **Respawn returns you to your own plot.** Killed 549 studs out in Dustbowl; respawned 3.8s later
    at 0.00 studs from the pad, lease intact.
  * Marigold walks — server-simulated Humanoid, standing on the riser, wandering and pausing.
  * No client errors. `Ambience` runs clean.
  * No `FireClient` warning, unlike in Edit: on a real server `IsServer()` is true.

Verified in Edit by building the map and measuring it: part counts, road continuity, pod placement,
decoration invariants, plot fit, treadmill clearance (52.3 studs), no solid obstacle in the racing
line, and the speed curve against the reference game's real scale — **3.2 billion Speed maps to
WalkSpeed 150.0**.

### NOT verified

  * **`clearPlot` has never had anything to clear.** The handover test ran on an empty plot
    (`plantsbefore=0`), so "a lease returns the ground empty" is asserted, not demonstrated. It
    cannot be until `PlantService` exists and there are plants to leave behind.
  * The whole Phase A loop past owning ground — no seeds, carrying, planting or economy exist yet.

### The plot queue, verified 2026-08-21 with two clients

```
2state      who=Player1  plot=Plot_01  queue=0  hubdist=103  onoverflowpad=false
2state      who=Player2  plot=NONE     queue=1  hubdist=0    onoverflowpad=true
5released   who=Player1  plot=Plot_01
3assigned   who=Player2  plot=Plot_01  claimed=true  ownerattr=Player2
4settled    who=Player2  plot=Plot_01  drift=0.00
```

Player2 queued on the overflow pad, then on Player1 leaving was promoted onto Plot_01 and **moved
there** — drift 0.00 from the pad, from hubdist 0. That last number is the point: it separates a
real promotion from relabelling a plot's owner while the player stands where they were.

### Studio's multi-client server is invisible to MCP, and here is the way round it

`Start Server + N Players` runs the server in a **separate process with no MCP plugin in it**, so
`list_roblox_studios` shows only the editor and the Server datamodel reads as unavailable. Play Solo
is different — it puts the *same* window into Play, which is why that was readable. Controlling
Studio does not help either: `screen_capture` is viewport-only and both input tools are locked to
`datamodel_type: "Client"`, so they drive the game, not the ribbon.

**The way round it is to make the server report out.** A throwaway `*Service` rides
`PlotService.OnAssigned`/`OnReleased` and beacons each event to `http://127.0.0.1:8732/?...`, where a
tiny Python endpoint appends to a file. Two things that matter if this is rebuilt: set
`HttpService.HttpEnabled` **in Edit**, because it is a place-level property the spawned server
inherits; and have the endpoint `flush()` + `fsync()`, because `python -m http.server`'s own request
log never reached the task output file at all.

### Testing gotcha that will bite again

**`execute_luau` has its OWN require cache.** A module required through MCP is a fresh, empty copy —
NOT the one the running server is using. `PlotService.PlotOf(player)` came back nil in a Play session
where the player demonstrably owned Plot_01. **Read Instance attributes instead**, which are shared;
module state is not.

## PlantService — 2026-08-21

The raid pays here. A banked pod becomes a Tool in the hotbar; clicking it plants into the nearest
free slot, and it grows pod → sprout → creature in the ground.

**Planted with the Tool, not a prompt.** Twelve slots per plot times six plots is seventy-two
ProximityPrompts competing for one keypress. `Tool.Activated` is one click, works unchanged as a tap
on a phone, and the player is already holding the thing.

**Growth is absolute `os.time()`, never a countdown.** A countdown pauses when you log off, which
turns a garden into a screensaver. Measured below: it does keep running.

**Nearest FREE slot, not lowest-numbered**, so a plot fills up where you are standing.

### Three defects found and fixed on the way in

**1. Plant slots were ~100 studs off the bed, in every plot, since they were first built.**

`MapService` did:

```lua
a.WorldCFrame = cf * CFrame.new(colX, soilTop, rowZ)
a.Parent = soil                      -- <-- AFTER
```

`WorldCFrame` on an attachment with **no parent yet** is just `CFrame`. So a world coordinate went
into a local field, and parenting it then applied the soil's own CFrame on top of it. Slot 1 landed
at `(0.4, 0.75, -103.5)` when the soil is at `(-107.4, 0.25, -72.9)`.

Latent for the whole life of the project because nothing read the slots until now. Fixed by writing
the **local** offset, which does not care about assignment order at all:

```lua
a.CFrame = CFrame.new(colX, soilTop * 0.5, rowZ)   -- soil sits at cf * (0, soilTop*0.5, 0)
```

Measured after: 12 slots, all inside the bed footprint, **max Y error vs the soil top 0.000**, laid
out 4 rows x 3 columns at x = ±11.33 / 0.00 against a 17.00 half-width.

> An early check called two of them "off the bed". That was the *check* being wrong — it compared
> world X/Z against the soil centre on world axes, and plots are **rotated** around the field. In
> the soil's own frame all twelve are comfortably inside.

**2. `GameConfig.Plot.PlanterName` said `"Planter"`; the part is named `"Soil"`.**

Two names for one fact, the exact thing flagged in the CarryService review. `PlantService` only
worked because of a `or plot:FindFirstChild("Soil")` fallback papering over it. Fixed at the source:
config says `Soil`, `MapService` now *names the part from the config* rather than repeating the
literal, and the fallback is gone. One name, one writer.

**3. `hookTool`'s two connections were untracked, so `Init()` was not re-run safe.**

`Init()` clears the `hooked` set; the `Activated` connection on a Tool survived it. A re-run would
hook the same tool twice and one click would plant **twice** — the second handler still reads
`SpeciesId` fine off the just-destroyed tool. Both connections now go into `serviceConnections`.

### Measured, in a live Play session

Pods were handed to the backpack built exactly as `CarryService.bank()` builds them, then equipped
and planted through **real client input** — `Tool:Activate()` from the Client datamodel, which is
the same call the CoreScript backpack makes on a click.

```
placement     Pod_nubkin in slot 2 | offset from the slot attachment 0.000 studs
                                   | base Y vs slot Y 0.000
lifecycle     t+ 0s  slot 6  nubkin -> pod
              t+10s  slot 6  nubkin -> sprout      (expected  9s, tick is 1s)
              t+27s  slot 6  nubkin -> grown       (expected 26s, tick is 1s)
restore       6 plants back after a full server restart, slots and species intact,
              ages 88s..398s -- real elapsed wall-clock, not restarted timers
offline       slot 8 bellchime planted, server STOPPED 6s later while it was still
              a pod, restarted ~68s afterwards -> came back GROWN, age 74s against
              a 57s grow time. Two stage thresholds crossed with nothing running.
```

That last line is the one worth keeping. The restore test alone does not prove offline growth --
everything in it was already grown before the restart. Planting a pod, killing the server while it
is *still a pod*, and finding it grown on the way back in is what actually demonstrates that
`PlantedAt` is absolute and the wait does not pause when you leave.

**Read the `Stage` attribute, not the model name.** `CreatureModel.Build` names *both* the sprout
and the grown model `Creature_<id>` — sprout is the same model at `SPROUT_SCALE`. A first pass read
the name and reported a bellchime "grown" at t+20s, which was its sprout threshold. The service was
right and the measurement was wrong.

**Arm the watcher before the thing you are watching.** Three attempts at the lifecycle sampled
*after* the transitions had already happened, purely from MCP round-trip latency. What worked: spawn
the sampling loop on the server first, have it write into a `StringValue`, trigger the plant, then
read the value back — attributes and Instances are the only channel shared with a running server.

### Refusing to plant is working, and it is silent

With the player on the spawn pad, all six in-range slots full and slots 7-12 at 33-47 studs against
a `PLANT_RANGE` of 26, `Plant()` correctly returned false. You have to walk your own bed.

**But nothing tells the player why.** The tool stays in hand and no feedback fires. Left as-is
rather than half-built: it wants the HUD, which does not exist yet.

### The map plugin rebuilds on ABSENCE, not on staleness

After fixing the slot placement, the Edit map still showed 0/12 slots on the bed while the Edit copy
of `MapService` demonstrably contained the fix. Nothing was cached and nothing was wrong: stopping
Play restores Edit to its pre-Play snapshot, which still held a map built earlier in the session by
the *old* MapService — and the plugin only rebuilds when `Workspace.SeedMap` is **missing**. A
manual `require(...MapService).Init()` gave 12/12 immediately.

So: **after changing `MapService`, press Clear Map then Build Map**, or run `Init()` from the command
bar. Auto-rebuild is there so the map is never *absent*; it was never going to notice the map is out
of date, and making it diff geometry every second to find out would cost more than it saves.

## A planted pod is not loot — 2026-08-21

Taking a pod home and putting it in the ground gave it a **Take** prompt, and using that prompt ran
the entire raid alarm — RUN, then SAFE — in the middle of the safe zone, for a pod the player had
just carried home themselves.

### The cause was a geometry builder making a gameplay claim

`CreatureModel.BuildPod` tagged every pod it built `SeedPod`. `CarryService` attaches a Take prompt
to everything wearing that tag. So *every* pod in the game was loot — including the three that are
not:

| caller | is it loot? | was it tagged? |
| --- | --- | --- |
| `NestService` nest pod | yes | yes |
| `CarryService` dropped pod | yes | yes |
| `CarryService` pod welded to your head | **no** | yes — a Take prompt on your own head |
| `CarryService` pod used as a Tool handle | **no** | yes |
| `PlantService` plant | **no** | yes — **the reported bug** |

Two of five. The fix is that **the builder no longer decides**: it builds geometry, and the caller
says what the thing means. `NestService` and `spawnLoose` now tag their own pods; nothing else does.

The carried-pod case fell out for free — it had been wearing a stray Take prompt the whole time.

### What a plant is instead

`PlantService.render` tags every model it builds `Planted`. One tag, two jobs: `CarryService`
refuses it, and `PlantUI` uses it as the seam to draw a hatch timer.

`TryTake` refuses on **two independent checks**, at the top with the other refusals, above the line
where the world starts changing:

```lua
if CollectionService:HasTag(pod, GameConfig.Tags.Planted) then return false end
if pod.Parent.Name == GameConfig.Plot.PlantsFolderName then return false end
```

The tag is the fact; the folder is *where the thing lives*, which no amount of tag drift can fake.
The rule was "refuse even if a stale prompt exists", so one check was not enough.

### PlantUI — a word and a clock

`HATCHING` while it is a pod, `GROWING` as a sprout, then the species **name** and no clock. The
name is the only place a species is ever written down, and that is the point: pods are coloured by
*rarity*, so Greenhollow's two Commons arrive identical and which one you got stays hidden until it
finishes. Free content at the end of every run home.

Same three colours as `PromptUI` (ink / paper / green), no ProximityPrompt anywhere near it, drawn
for **everybody** rather than just the owner — a plot half-grown is meant to be readable by whoever
walks past deciding whether it is worth coming back to.

Two things worth keeping:

  * **The clock is `GetServerTimeNow()`, not the client's `os.time()`.** `PlantedAt` is an absolute
    server stamp; a client clock sitting a few seconds off would either hit 0:00 while the pod sat
    there or change shape with 0:04 still showing. Either reads as broken.
  * **`SproutAt` moved out of PlantService into `GameConfig.Plant`.** The client has to compute the
    same thresholds the server transitions on, and a private constant in the service would have let
    the countdown and the transition drift apart. Along with `TickSeconds` and `RangeStuds`.

### Measured in Play, on my own plot

```
plot        12 plants | SeedPod tags: 0 | ProximityPrompts: 0
nest        5 SeedPod models | 5 Take prompts   (unchanged)

stale prompt   forced SeedPod onto a plant so the REAL CarryService attached a REAL
               Take prompt, then held it to completion 5.5 studs away:
                 plant still there: true    CarryingSpecies: nil    BankedCount: nil

hatch timer    t+ 5.4s  HATCHING | 0:09 | prompts on model: 0
               t+14.0s  HATCHING | 0:01 | prompts on model: 0
               t+14.8s  GROWING  | 0:17 | prompts on model: 0
               t+30.0s  GROWING  | 0:01 | prompts on model: 0
               t+30.9s  NUBKIN   |   -  | prompts on model: 0
               (nubkin: sprout at 9s, grown at 26s -- both hit on the tick)

nest take      CarryingSpecies=petalpip, AlertUI word "RUN", pod consumed
               parent  t+0.0s Asleep=true  WalkSpeed 0.0
                       t+6.4s Asleep=false WalkSpeed 31.0   <- wake delay 1.2s
                       t+9.0s Asleep=true  WalkSpeed 0.0    <- grabbed, threw, slept
```

The alarm still belongs to the nest and only to the nest.

### Re-verified on a genuinely empty plot

The run above was done on a plot already holding eleven test plants. Re-run from zero, after
clearing `Data.Plants` in the save record, so nothing could be inherited from an earlier state:

```
t+ 4.5s  HATCHING 0:09 | prompts 0 | carry nil | banked nil | alert "Label"@1.00
t+12.0s  HATCHING 0:01 | prompts 0 | carry nil | banked nil | alert "Label"@1.00
t+13.2s  GROWING  0:17 | prompts 0 | carry nil | banked nil | alert "Label"@1.00
t+29.3s  GROWING  0:01 | prompts 0 | carry nil | banked nil | alert "Label"@1.00
t+30.1s  NUBKIN     -  | prompts 0 | carry nil | banked nil | alert "Label"@1.00
```

`"Label"@1.00` is the strongest line there. That is the **default** `Text` of an untouched
TextLabel, at full transparency — AlertUI's word has never been written to at all, so RUN and SAFE
did not merely go unseen, they never fired. Watching `CarryingSpecies` alone could not have told
those two apart.

Then the counter-check from 22 studs out, far enough that the parent has to actually run:

```
nest take   CarryingSpecies=petalpip | AlertUI "RUN" at transparency 0.00 | pod consumed
parent      t+10.5s  Asleep=true   WalkSpeed  0.0   0 studs   carrying=petalpip
            t+11.8s  Asleep=false  WalkSpeed 31.0   0 studs   <- woke, 1.3s after the theft
            t+12.4s  Asleep=false  WalkSpeed 31.0   9 studs   <- chased, grabbed, threw
            t+14.1s  Asleep=true   WalkSpeed  0.0   4 studs   <- heading home
plot        1 plant | SeedPod 0 | CarriedPod 0 | ProximityPrompts 0
```

> Clearing the save turned up a second thing: the profile lives under `record.Data`, not at the top
> level. A first attempt wrote `Plants = {}` beside `Data` instead of inside it — harmless, nothing
> reads it, but it was removed rather than left, because junk keys are how a save format rots.

> A snapshot taken *after* that sequence showed `Asleep=true` and read as "the parent never woke".
> It had woken, grabbed, thrown and gone back to sleep inside 3 seconds — the player was standing
> **inside** the nest, well within `GrabStuds`, so there was no chase to see. Arm the watcher before
> the event; a snapshot after a fast state machine is not evidence about it.

## Grown plants: size follows the species, and they move — 2026-08-21

Grown creatures read as statues of one size. Two separate things, fixed together.

### Size — the defect was BULK, not height

`BuildCreature` was already using `sp.Height`, and `SPROUT_SCALE` was already 0.45. The problem was
that every HORIZONTAL dimension was a fraction of that same height, so bulk tracked height and
**nothing tracked weight**. Across a 55x weight range:

```
before   height 1.67x     width 1.67x
```

Worse, the Bellchime came out proportionally *slimmer* than the Nubkin — 1.73 tall-to-wide against
1.30 — so weight read backwards.

Fixed with `SeedData.Girth(species)`, same curve family as `PodDiameter` and referenced against the
middle species so Spiretip is 1.00 and the curve spreads either side of something that already
looked right:

```lua
math.clamp((kg / 14) ^ 0.24, 0.70, 1.75)      -- 2kg -> 0.70   110kg -> 1.64
```

Applied in exactly **four** places — mound, stem, leaves, `headW` — because every other horizontal
measurement in the five forms is already derived from `headW` and inherits it for free.

### Measured in Play, on real slots

```
Nubkin        2 kg  grown | H 1.74  W 1.54 | base offset from slot -0.000
Petalpip      5 kg  grown | H 2.48  W 2.15 | base offset from slot +0.000
Spiretip     14 kg  grown | H 4.20  W 2.93 | base offset from slot -0.000
Toadcap      40 kg  grown | H 5.26  W 4.25 | base offset from slot -0.000
Bellchime   110 kg  grown | H 6.41  W 6.01 | base offset from slot -0.000

after    height 3.68x     width 3.90x        sprout = 0.45 of grown, exactly
```

**`Height` is a FRAME height, not the finished silhouette, and the type now says so.** Girth widens
the head, and a wider head is also a taller one, so Nubkin's `Height = 2.4` finishes at 1.74 and
Bellchime's `4.0` finishes at 6.41.

**Settled by the owner on 2026-08-21, do not re-open.** Pinning the finished height to the data
exactly would mean threading separate vertical and horizontal scalars through all five forms, and
that collapses the width spread back to 1.78x — the very thing the girth curve fixes. The ruling:
*visible weight at a glance matters more than 2.4 finishing at 2.4; frame-height in the type is
enough.* Keep girth.

> Two measurements had to be thrown away first. `Model:GetBoundingBox()` reports in the **pivot's**
> frame, and these models pivot on the mound — a cylinder rotated 90 degrees — so X and Y come back
> swapped. It read as "height 1.58 for a Height of 2.4" and "bases float by up to 1.045 studs".
> Both were artefacts. World-space extents, computed from each part's own eight corners, show the
> bases were always flush. **The bug report's "bases sink or float" was my bad instrument, not the
> models.**

### Motion — PlantSway.client.luau, and it is CLIENT ONLY

Rooted. No Humanoid, no pathfinding, nothing leaves the slot — seventy-two Humanoids running state
machines and floor raycasts to move things that are planted in the ground is a performance bug in a
costume. The motion is a **lean**: the model is pivoted about its own base, so the pivot *is* the
slot and it cannot walk off.

Server builds and tags; every client leans its own copy. Plant parts are anchored, so a CFrame
written on a client is local to it and there is nothing for the server to fight with — the same
split as Marigold's wings in `Ambience`.

It rides the **existing `Planted` tag** rather than a new one, filtered to `Stage >= SPROUT`. That
is why nest pods, carried pods and the parent can never pick it up: only `PlantService` ever applies
that tag. Verified — `Planted`-tagged models outside a `Plants` folder: **0**.

**One `PivotTo` per plant, and not every plant every frame.** A grown creature is ~19 parts; writing
each part's CFrame would be a thousand property writes a frame on a full server. The set is walked
in slices at ~20 Hz instead of 60 — the sway has a 6-to-11 second period, so each step is a fraction
of a degree and nothing looks stepped. No `Instance.new` anywhere in the loop.

```
                CLIENT                                        SERVER
Nubkin      2 kg  peak lean 6.12 deg  period ~6.4s        0.000000 deg
Petalpip    5 kg  peak lean 5.28 deg                      0.000000 deg
Spiretip   14 kg  peak lean 4.34 deg  period ~8.0s        0.000000 deg
Toadcap    40 kg  peak lean 3.55 deg                      0.000000 deg
Bellchime 110 kg  peak lean 2.85 deg  period ~10.7s       0.000000 deg

position drift, every species: 0.0000 studs     Humanoids in the Plants folder: 0
```

Heavier leans less and slower, monotonically. The server column is the proof that the sway is
client-only: same plants, same fourteen seconds, literally zero movement.

> Measuring the lean needed the same correction as the sizes. Against world up, every plant read
> "91 degrees" — the pivot's own 90-degree cylinder rotation. Measured **relative to the rest pose**
> the numbers above fall out. Twice in one change, the instrument was the thing that was wrong.

## EconomyService — the faucet, and Phase A closes — 2026-08-21

**Phase A is complete: cash moves on screen because of something you stole.** Steal a pod, run it
home past a parent that wants it back, plant it, watch the number climb. That loop now runs end to
end.

### One faucet, checked mechanically rather than by eye

Rule 6 says cash mints in `EconomyService` and nowhere else. That is now verifiable in one grep, and
it was run:

```
AddCash callers outside PlayerDataService: EconomyService
```

`PlayerDataService.AddCash` is the MECHANISM — it clamps to `MaxCash` (1e15) and marks dirty. It
does not decide what earns. If five services each paid out "just this one case", the answer to *why
does this player have eight million* would live in five files.

### What earns

Grown plants only, `SeedData.IncomePerSecond` (kg x `CashPerKg`), read from
`PlantService.GrownIn(plot)`. A pod pays nothing and a sprout pays nothing — the wait IS the cost,
and paying during it turns planting from a bet into a deposit. It also keeps the plot readable as a
balance sheet: what is standing up is what is paying.

Gated on the plot's owner *and* on `PlotService.OwnerOf`, which are separate tables — a lease that
changed hands between them is exactly the sort of thing that pays the wrong person.

**Paid for time actually elapsed, `rate * dt`, not a flat amount per tick.** A server that hitches
for three seconds still owes three seconds; a loop that pays per iteration quietly underpays exactly
when the server is struggling. The clock does not start until the profile is ready, so seconds spent
loading do not become income the moment it lands.

**No offline payout this pass, deliberately.** Growth uses an absolute `os.time()` and keeps running
while you are away; cash does not. An offline faucet needs a claim flow, a cap and an anti-abuse
story, and none of that belongs in the pass that first makes the number move.

### Measured in Play

Cash and plants cleared to zero in the save record first, so the slopes are clean.

```
ONE GROWN NUBKIN  (2 kg)
  20 ProfileUpdated packets over 19.2s
  cash 14.23 -> 52.66      measured 2.000 /sec     expected 2

ONE NUBKIN + ONE BELLCHIME  (2 kg + 110 kg)
  20 packets over 19.2s
  cash 5404.55 -> 7560.53  measured 112.100 /sec   expected 112   (+0.09%)
```

The 0.09% is sample-window boundaries, not drift. Unchanged alongside it:

```
plot plants 2 | SeedPod 0 | CarriedPod 0 | prompts 0
nest pods   5 | Take prompts 5
carry       CarryingSpecies nil, BankedCount nil
AlertUI     word "Label" at transparency 1.00 -- untouched default, never fired
sway        still running, 5.99 deg over 6s
plots       1 owned, 5 unowned and all empty
```

### The readout is one TextLabel on an EXISTING remote

`CashUI.client.luau`. `PlayerDataService` already pushes the whole profile down `ProfileUpdated`,
coalesced at 0.25s, and announces the first on `ProfileReady` — so the client draws `profile.Cash`
and **no second remote was invented**. Not a HUD: no shop, no speed, no inventory.

Two details worth keeping:

  * **It shows a dash, not a zero, until the server has spoken.** "0" and "we have not heard yet"
    are different facts, and rendering the second as the first shows a player with a real balance an
    empty wallet during a slow DataStore call — which looks exactly like being robbed. `GameConfig`
    warns about this where `ProfileReady` is declared; this is that warning obeyed.
  * **It eases toward the value rather than snapping.** Cash arrives in 0.25s batches, so the raw
    number steps visibly. Easing reads as *earning* rather than as a field being overwritten, and at
    2 cash a second that difference is the whole feeling of the thing.

> The test balance (13,130) was reset to 0 in the save afterwards. The two plants were left — a
> grown bed is a fine thing to come back to; a five-figure balance nobody played for is not.

## TreadmillService and the carry hold — 2026-08-21

### The Speed faucet, same shape as the cash one

Only `TreadmillService` calls `PlayerDataService.AddSpeed`, and **it never writes `WalkSpeed`**.
Both rules are checked mechanically now, not by eye:

```
AddCash callers:  EconomyService
AddSpeed callers: TreadmillService
writes WalkSpeed: HubFairy, ParentModel, NestService, CarryService
```

The three besides `CarryService` are NPC humanoids — the fairy, the parent rig, the nest's chase
speed — plus `NestService`'s throw, which captures and restores the PLAYER's WalkSpeed around a
ragdoll. That one stays: calling `RefreshWalkSpeed` instead would need a `NestService` ->
`CarryService` require, which is forbidden, and capture/restore is exactly why it was written that
way.

```
Speed score -> GameConfig.walkSpeedFor -> x carry multiplier -> WalkSpeed
                                          ^ CarryService owns this whole line
```

**Occupancy, not input.** Standing on the belt pays; you never hold W. Tested by transforming the
root into the belt's own frame rather than by `Touched` — a static part a player stands on for ten
minutes fires `Touched` once, and all six mills are rotated, so an axis-aligned test would be wrong
for every one of them.

**Your mill, not the nearest one**, matched on the `PlotId` the map already stamps on both the plot
and the treadmill. Six mills in a ring is a short walk between two of them.

### The carry moved from the skull to the arms

`attachToHead` and `CARRY_HEIGHT = 3.0` are gone. The pod welds to **HumanoidRootPart** — the part
that turns with the body, so it stays in front through every turn instead of swinging with a head
that looks around on its own — offset by the pod's OWN RADIUS, because pods run 1.3 to 4.5 studs
across and a fixed offset either buries a Bellchime in the ribs or leaves a Nubkin hovering clear of
the hands.

`gripFor()` and `weightTag()` are single definitions used by **both** the raid carry and the banked
Tool, so the thing in your arms looks the same either side of the red line. A Tool would otherwise
be welded to the right hand by Roblox's `RightGrip` and held out at arm's length in one fist; on
equip that weld is replaced with the same root weld the raid uses.

### Measured in Play

```
TREADMILL, standing on my own mill
  29 packets over 19.3s
  Speed 20.27 -> 58.77   measured 1.990 /sec   configured 2
  WalkSpeed 16.393  vs  walkSpeedFor(58.8) = 16.393   -> delta 0.0000
  sign on the mill reads "+2/step"

OFF the belt, in the field
  Speed +0.00 over 11.0s = 0.000 /sec      <- the gate works
  cash  +1248.8 over 11.0s = 113.20 /sec   (nubkin 2 + bellchime 110 = 112)

THE CARRY, welded to HumanoidRootPart in both cases
  Nubkin      2 kg   1.58 studs in front, 1.80 BELOW the head   tag "2Kg"
  Bellchime 110 kg   3.09 studs in front, 1.81 BELOW the head   tag "110Kg"
  (the old behaviour was 3.00 studs ABOVE the head)

UNCHANGED
  plot 2 plants | SeedPod 0 | prompts 0      nest 5 pods | 5 Take prompts
  sway still running 3.09 deg                mills 6 | signs 6
  readout "75,657" / "SPD 395"
```

### Two things that cost time, both worth writing down

**`FindFirstChild` on a replicating remote is a race.** The `Remotes` FOLDER replicates before the
`RemoteEvent`s inside it. `CashUI` used `FindFirstChild`, got nil, silently skipped the connection,
and sat on its dash for a whole session with no error anywhere — while the remote was firing
twenty-nine packets a measurement. Now `WaitForChild` with a timeout and a `warn` on the miss. A
lookup that can lose a race has to wait or complain.

**MCP's `execute_luau` require cache PERSISTS ACROSS CALLS within a Play session.** This file has
said for weeks that a module required through MCP is "a fresh, empty copy" — true relative to the
running server, but NOT fresh per invocation. A harness `CarryService.TryTake` succeeded once, left
`carried[player]` set in that copy, and every later take returned false while all twelve validation
checks passed by hand. `Init()` on the copy clears it. Destroying the model is not enough; the
module's own table is the state.

> Prompts would not show for the client at all in that session — `PromptShown` never fired even for
> a freshly built default-style prompt five studs away, with nothing modal and the humanoid running.
> Not caused by this pass: disabling both new client scripts changed nothing. The nest prompts still
> EXIST server-side (5 on 5 pods), so the carry geometry was measured by driving `TryTake` directly
> and is labelled as such above.

> Test cash/Speed (76,699 / 395) were reset to 0 afterwards; the two plants were left.

## Prompts were never broken, and the mill now looks used — 2026-08-21

### The prompt "outage" was my instrument, twice over

Last session reported `PromptShown` dead. It was not. Walking in from 30 studs with `PromptUI`
watching, the custom panel drew correctly:

```
walked 30.1 -> 7.2 studs
PromptShown seen by an execute_luau connection: NONE
custom panels drawn by PromptUI:               1  SeedPrompt key="E" action="Take"
```

**`ProximityPromptService` events do not reach connections made from `execute_luau`.** They reach a
real LocalScript perfectly well — `PromptUI` built its panel off the very event my probe said never
fired. On top of that, the first session's probe connected while the character was ALREADY inside
the radius, and `PromptShown` is an edge. Two independent measurement faults stacked into a
confident wrong conclusion.

Reading instance PROPERTIES from `execute_luau` works fine. It is only engine EVENT connections that
are dead there. That is the rule to remember.

### What is still unproven: a hand-driven take

Synthetic input reaches the client — `UserInputService:IsKeyDown(E)` returns true, and holding W
moved the character exactly 24.24 studs. But neither synthetic keyboard nor a synthetic click on the
panel begins the hold: `PromptUI`'s fill bar stayed at **0.00**, so `PromptButtonHoldBegan` never
fired, with Style Custom AND with Style flipped to Default as a control.

So the prompt path is healthy up to the point where a hold must begin, and VirtualInput does not
appear able to drive that. **A real hold-E take is still unverified by me** and wants a human at the
keyboard. The carry geometry below was measured by driving `TryTake` directly, which is a harness
and is not a take.

### The character rig has no Motor6Ds

`CarryPose` posed nothing because it was looking for joints this avatar does not have:

```
AnimationConstraint x15   BallSocketConstraint x14   Motor6D x0
```

Modern Roblox avatars are physics rigs. `RightShoulder` is an `AnimationConstraint`, not a Motor6D,
and the old code's `buildRig` found nothing and gave up silently.

`AnimationConstraint.Transform` drives fine — measured by writing it and watching the hand move
1.956 studs, then snap back 1.957 on release. Unlike `Motor6D.C0` it OVERRIDES the animation rather
than composing under it, which is right for a carry: arms holding something should not swing. It
must be written in `Stepped`, after the animation has been evaluated.

**Which axis swings an arm forward is per-rig, and was measured rather than guessed.** Right
shoulder, hand position in ROOT space:

```
rest       x +1.47  y -0.99  z -0.64
X +60 deg  x +1.26  y -0.06  z -1.63   <- FORWARD
Y +60 deg  x +1.02  y -1.02  z -0.67      barely moves
Z +60 deg  x +2.47  y +0.24  z -0.40      sideways and up
```

R15 swings on X. R6 swings on Z — the opposite — because of a 90-degree yaw baked into its shoulder
C0, which `Ambience` measured when the fairy walked doing star jumps. `CarryPose` now handles
AnimationConstraint, Motor6D R15 and Motor6D R6, and warns rather than silently doing nothing.

### `MoveDirection` is 0.00 on a moving character

The streak had two faults, not one. The gate was too high — `walkSpeedFor(0) * 1.55` = 24.8, which
this curve (Scale 20,000) does not reach until ~1,265 Speed, about twenty-one minutes of milling.
But it also tested `MoveDirection`, which read **0.00 through a 39.2 stud walk** on this rig. Now
gated on `AssemblyLinearVelocity` and on base + 1.2:

```
gate 17.20 (base 16.00), reached at ~180 Speed -- about 90 seconds on the belt
running   peak ground velocity 18.23  -> gate opens
standing  ground velocity 0.00        -> gate closed
```

Opacity now scales from a hint at the gate to a full ribbon 14 studs/sec above it, so a first
session and an hour-long grind do not draw the same streak.

### The mill

`OnTreadmill` is set on the PLAYER, so it replicates to everybody and each client can play the run
cycle on somebody else's character with no remote. The run animation id is read off the character's
own `Animate` script, so a player with a purchased run trains in THEIR run and there is no asset id
in this repo to rot.

Five chevrons per belt, two bars each, built by the server and scrolled by each client — the same
split as the fairy. Sixty parts moving on the server would be sixty parts of replication a second,
for paint.

```
standing on the mill, no key held:
  MoveDirection 0.00, WalkSpeed 16.18
  playing: Animation(pri=Action, w=1.00)      <- the run cycle
  chevron travelled 15.91 studs in 2.5s       <- belt span is 16, so a full wrap
  OnTreadmill = true, cleared to nil on stepping off
```

### Measured, unchanged

```
carry     Nubkin 1.58 studs in front, tag "2Kg"          <- settled numbers, untouched
arms      pod        x +0.00 y -0.35 z -1.58
          RightHand  x +1.05 y -0.19 z -1.52   1.06 from the pod
          LeftHand   x -1.19 y -0.30 z -1.35   1.21 from the pod
          (rest was x +-1.47 y -0.99 z -0.64)
faucets   cash 113.35/sec (112 expected)   Speed 0.000/sec off the mill
world     plot 2 plants, 0 SeedPod, 0 prompts | nest 5 pods, 5 Take prompts
          sway 1.97 deg | mills 6 | signs 6 | chevrons 60
```

> Test cash/Speed (116,324 / 279) reset to 0 afterwards; the two plants kept.

## The throw is a ragdoll now, not a hop — 2026-08-21

The old `throwPlayer` solved a parabola, fired it, waited the exact flight time, then **zeroed the
horizontal velocity on the way down**. Mathematically perfect and physically dead: the one moment a
bounce would begin was the moment the speed was set to zero. A thrown player was a crate on rails.

Now: shove, let go of the pose, and poll until the body has actually stopped. Walls and the floor
bounce it because they COLLIDE, not because anything in Lua reflects a vector.

### What was kept, deliberately

  * `PlatformStand` **first**, `task.wait()`, **then** capture WalkSpeed. That order is the whole
    reason a thrown player does not stand up at carry speed with empty hands.
  * **One `restore()` on every exit** — and the ragdoll unwind now goes through it too. First draft
    unwound at the end of the happy path, which meant an error mid-flight left a player loose-jointed
    with collision forced on, permanently. Joints and collides are as much a lock as WalkSpeed.
  * No `NestService` -> `CarryService` require. Checked: the only mentions are comments.
  * Throw toward **+Z**, small X nudge off the wall. Grab hold, range, leash, wake delay and parent
    WalkSpeed all untouched.

### The rig, again

Same lesson as `CarryPose`, and the reason a Motor6D ragdoll would have silently done nothing:

```
AnimationConstraint x15   BallSocketConstraint x14   Motor6D x0
```

The ball sockets are ALREADY holding the skeleton together. What keeps it standing in a pose is the
AnimationConstraints driving each joint — switch those off and what remains IS a ragdoll.

**Limbs had to be made to collide.** Measured before the first throw:

```
body parts 16, CanCollide: 4  (HumanoidRootPart, Head, UpperTorso, LowerTorso)
```

Twelve of sixteen parts pass through the world. A body that only collides on its torso capsule is
the hop again with extra steps. `ragdollOn` captures every part's CanCollide, forces it on, and
`ragdollOff` puts back exactly what was there — captured rather than assumed, because a character
that stands up with the wrong collision set falls through the road later. Accessories are skipped:
a hat that collides wedges the head and the body never settles.

### Stand-up had to be levelled, or the solver launches you

First measured run settled at Y 0.5 and then **popped 12.6 studs into the air** and fell again. Not
a bounce: re-enabling the joints while limbs are half inside the floor leaves the solver one way to
resolve the overlap, and that is to throw the body out of it.

So before the joints come back the body is levelled — keep where it landed, drop pitch and roll,
lift clear of the ground, zero the velocity. **This is not the old landing wipe.** That one fired on
first ground contact and is what made the throw a hop; this fires after the body has already stopped,
which is the one moment killing velocity costs nothing.

### Measured in Play

The chain below is the real code — provoke -> wake -> chase -> grab -> throw. Only the instance
driving it is a harness: an `execute_luau` copy of NestService and CarryService, `Init()` and
`Start()`ed so their own nests exist and their own ticks run.

```
 2.4s Y  1.6  +Z    0.0  vY -13.0  ragdoll   <- grabbed, pod drops here
 3.4s Y  9.3  +Z   29.9  vY  -1.3  ragdoll   <- the arc
 3.7s Y  2.2  +Z   65.7  vY +19.8  ragdoll   <- A BOUNCE off the ground
 4.0s Y  1.2  +Z   95.7  vY -32.8  ragdoll
 4.6s Y  0.5  +Z  139.7  vY  -1.6  ragdoll
 5.6s Y  0.5  +Z  161.1  vY  +0.0  ragdoll   <- settled
 5.9s Y  2.1  +Z  161.1  vY  +0.0  up        <- stands up
 6.2s Y  3.0  +Z  161.1  vY  +0.0  up

bounces 3 | +Z 161.1 | lateral 5.3 | peak Y after stand-up 3.0 | WalkSpeed 16.000
```

Pod-drop and the unencumbered stand-up, from the run before it:

```
t+0.0s  colliding  4  PlatformStand=false  WalkSpeed 16.000  carrying=nil
t+0.6s  colliding  4  PlatformStand=false  WalkSpeed 15.883  carrying=petalpip
t+2.6s  colliding  4  PlatformStand=true   WalkSpeed  0.000  carrying=nil    <- dropped
t+3.5s  colliding 16  PlatformStand=true   WalkSpeed  0.000  carrying=nil    <- ragdoll
t+6.5s  colliding  4  PlatformStand=false  WalkSpeed 16.000  carrying=nil    <- stood up
dropped pod Pod_petalpip on the ground at Y 0.99, 158 studs behind the player
```

`15.883` is the 5 kg carry multiplier; `16.000` is `walkSpeedFor(0)`. Standing up returns the
UNENCUMBERED number, which is the bug that ordering fix exists to prevent.

### The configured studs are impulse strength now

The formula and the numbers are unchanged — `sqrt(R*g / 2k)` is still the speed for a clean R-stud
arc. What changed is the promise. A body that bounces off a wall does not land where a parabola says,
so 60 studs of config produced 161 studs of travel here. Bigger biome number, harder shove; where
they end up is the world's business.

### Untouched, verified after

```
grip forward   Nubkin 1.58, Bellchime 3.09          mills 6 | signs 6 | chevrons 60
plot           2 plants | SeedPod 0 | prompts 0     nest 5 pods | 5 Take prompts
cash           110.86/sec (112 expected)            sway 1.68 deg
character      colliding 4 (as before) | AnimationConstraints 15/15 | PlatformStand false
```

> A mid-test reading of "nest 6 pods | 12 Take prompts" was the harness: two CarryService instances
> each attaching a prompt to every pod. A clean session shows 5 and 5.

> Test cash reset to 0 afterwards; the two plants kept.

## The grab is gone, and the ragdoll is finally visible — 2026-08-21

### No hold. Contact is the hit.

`GrabHoldSeconds` is deleted -- from the code and from `GameConfig`, because dead config is how a
file starts lying about itself. The parent no longer catches you, holds you for the better part of a
second and then throws; reaching you IS the hit. It read as a cutscene: the chase stopped dead, both
bodies stood still, and the moment everything had been building to was a wait.

```
contact 1.94s -> hit 1.94s   (delay 0.00s, was 0.80s)
```

`GrabStuds` is untouched at 7 -- that is contact range, not a grab.

### ~~Why the ragdoll was invisible: the body was never the server's to move~~

> **WRONG IN PLAY. Superseded — see "Never take a player's character" below.** Everything measured
> in this section is true of the server's copy of the body, which is not the copy anybody is
> looking at. Taking the assembly made the numbers good and the game worse. Left here because the
> reasoning looks convincing and somebody will try it again otherwise.

This is the important one, and it had nothing to do with the ragdoll code.

**A player's character is network-owned by that player.** Their client simulates it and tells the
server where it went. So the impulse, the tumble and the bounce were all being computed on the
server and then quietly overwritten by the owning client's version of a character that was, as far
as it knew, standing still. The ragdoll was real, correct, measurable from the server, and rendered
by nobody.

`SetNetworkOwner(nil)` for the duration fixes it -- but **only if it is claimed LAST**:

```
claimed first:  t+2.27s  SERVER      <- the claim
                t+2.32s  player      <- gone again, 0.05s later
claimed last:   server-owned for 86 of 87 ragdoll frames (99%)
```

Disabling fifteen constraints and flipping sixteen `CanCollide` flags **re-forms the assembly**, and
a freshly formed assembly reverts to auto ownership -- which for a player's character means the
player. The claim was being made and then thrown away by the next two loops. It is now made after
the shape has finished changing, and re-asserted every poll of the settle loop, because anything
that reshapes the assembly mid-flight takes it back the same way. Handed back with
`SetNetworkOwnershipAuto()` on stand-up.

### Measured on the CLIENT, which is the only place "visible" means anything

Torso tilt away from upright, and the forearm's position relative to the chest:

```
 9.5s  tilt  1.2 deg   arm rel  x+1.17 y+0.06 z-0.77
 9.7s  tilt 27.3 deg   arm rel  x+0.69 y-0.41 z+0.36
10.0s  tilt 94.2 deg   arm rel  x+1.06 y+0.41 z-0.91
10.2s  tilt 94.3 deg   arm rel  x+0.83 y+1.35 z-0.31
10.4s  tilt 94.2 deg   arm rel  x+1.09 y-0.28 z-0.53
max torso tilt while ragdolled: 94.8 deg
```

The body tips fully over, and the forearm moves relative to the chest between every sample -- a limp
limb, not a posed one. The client also reports the state arriving: `PS=true constraints on=0 off=15
collide=16`.

> `screen_capture` was no use here and returned frames of a standing character while the server
> measured 27.3 degrees of tilt at that instant -- the stale-frame problem this file already
> records. The pose measurement above is the evidence; there is no screenshot of it.

### Untouched, verified after

```
after stand-up  owner back to the player | colliding 4 | constraints 15/15 | PlatformStand false
                WalkSpeed 16.000
grip            Nubkin 1.58 / Bellchime 3.09
world           mills 6 | signs 6 | chevrons 60 | plot 2 plants, 0 prompts
```

## The sway was leaning in the wrong frame — 2026-08-22

Plants still read as statues after the sway shipped, and HANDOFF was reporting "sway 1.68 deg" the
whole time. Both were true. The motion existed, was measured, and was almost entirely invisible.

### The pivot's local X is world up

`PrimaryPart` is the Mound, and `upright()` builds that as a **cylinder rolled 90 degrees**, so the
model's pivot carries that roll. `PivotTo(rest * CFrame.Angles(ax, 0, az))` applies the rotation in
that frame. Measured on a live Bellchime:

```
pivot local X dot world up = 1.000        <- local X IS world up
6 deg about pivot-local X -> highest part moves 0.0821 studs
6 deg about pivot-local Y -> highest part moves 0.6212 studs
6 deg about pivot-local Z -> highest part moves 0.6224 studs
```

So the DOMINANT `ax` term was a twist about the stem -- invisible on a round head -- and the only
real lean was the secondary `0.62x` term, at a degree or two. A bed of plants was genuinely swaying
and genuinely still.

**Never measure this model with CFrame-angle-vs-rest again.** That instrument has now lied twice
about this exact rig: once here, and once when `GetBoundingBox` reported creature heights in the
pivot's frame and invented base offsets of a stud. Measure world displacement of a part you can see.

### The fix: lean about an upright anchor, and size the motion in studs

Each plant captures an **anchor** -- a pure translation at the centre of its base, so its axes are
the world's and tipping about X or Z is a lean with no twist available -- plus its rest pose
expressed in that frame:

```lua
anchor = CFrame.new(baseCentreX, baseY, baseCentreZ)
offset = anchor:Inverse() * model:GetPivot()
model:PivotTo(anchor * CFrame.Angles(ax, 0, az) * offset)
```

`WorldPivot` would have been the obvious way to say this and does not work here: when a model has a
`PrimaryPart`, `GetPivot()` returns that part's CFrame and `WorldPivot` is ignored. Clearing
`PrimaryPart` would have broken `PlantUI`'s billboard adornee and `PlantSway`'s own replication wait,
so the anchor is composed explicitly instead.

**Amplitude is now derived from head travel, not set as an angle.** Degrees are the wrong unit for
models running 1.7 to 6.4 studs tall -- the same angle is a twitch on one and a swing on the other.
Pick the travel, solve the angle: `travel = 2 * h * sin(amp)`, with `h` measured from the model's
own world-space extents.

### Measured: head world displacement, not degrees

```
CLIENT, over 24s (nubkin period ~6.2s, bellchime ~10.0s)
  nubkin     head at Y 1.99 | horizontal 0.658 studs | vertical 0.204 | total 0.688
  bellchime  head at Y 6.63 | horizontal 0.399 studs | vertical 0.047 | total 0.401

SERVER, same 24s
  nubkin     0.0000        bellchime  0.0000
```

Heavy still reads heavy: the Bellchime's head covers 0.399 studs to the Nubkin's 0.658, and takes
ten seconds to the Nubkin's six.

Still rooted -- the anchor is a fixed point, so nothing can drift off its slot:

```
mound travel   nubkin 0.0596 studs | bellchime 0.0143
```

That is the mound rotating about a fixed base, which is what a lean does; it is not the plant
moving. No Humanoids in the Plants folder, and no `Planted`-tagged model outside one.

### Untouched, verified after

```
girth   Nubkin 0.70 / Bellchime 1.64        grip    Nubkin 1.58 / Bellchime 3.09
mill    6 mills, 6 signs, 60 chevrons, 2/s  nest    5 pods, 5 Take prompts
ragdoll GrabStuds 7, GrabHoldSeconds nil, biome-1 throw 60
```

## Never take a player's character — 2026-08-22

The owner playtested the ragdoll: **invisible during the tumble, stuck on the parent, then a
teleport to where they landed.** The grab had already been removed, so the grab was never the cause.
The cause was the fix from the pass before.

### What SetNetworkOwner(nil) actually did

A player's character is simulated by that player. Taking the assembly moved the simulation to the
server, and the server's simulation is not what the victim's screen is drawing:

  * **Invisible** -- the victim's client had a body still standing at the point of contact, inside
    the parent. Camera inside a mesh, so Roblox's own `LocalTransparencyModifier` hid the character.
  * **Stuck on the parent** -- because from their machine, nothing had happened.
  * **Teleport** -- `SetNetworkOwnershipAuto()` plus the server-side stand-up CFrame snapped them
    a hundred and sixty studs to wherever the server's copy had ended up.

Every number in the previous section was true. None of it was on anybody's screen. **Measuring the
server's copy of a client-owned body tells you nothing about what the player sees**, and that is
the third time this rig has been measured with the wrong instrument.

### The split that actually works

```
SERVER   PlatformStand, the pod drop, WalkSpeed, limpness, collision, the nudge
         out of the parent -- all PROPERTIES, which replicate to everybody, so a
         watcher three plots away sees a limp body rather than a jogging one.

OWNER    the impulse, the tumble, the settle, and the level-in-place. Its physics
         already replicate outward, which is the same reason nobody has to be
         told where a walking player is.
```

The server sends direction and speed on a new `ThrowVictim` remote and waits; the victim's client
applies `AssemblyLinearVelocity` to a body it already owns, polls its own settle, levels in place,
and answers. The server's timeout is what actually bounds the ragdoll -- the client's answer is an
optimisation, and a client that never answers changes nothing.

`claim()`, the settle-loop re-claim and `SetNetworkOwnershipAuto()` are gone. So is the server-side
settle poll, which was reading a replica's velocity to decide when the real thing had stopped.

### Two things the rewrite had to add

**Step out of the parent before the limbs collide.** Contact happens inside a collidable torso.
Making sixteen parts collidable while they overlap another body either wedges the victim there or
has the solver fling them. `CLEAR_STUDS = 5` along the throw direction, applied while collision is
still off so nothing can block it, and while both machines still agree where the body is -- which is
what makes it a nudge and not a teleport.

**Level where the owning simulation stopped, not where the server thinks it did.** The old
stand-up wrote a CFrame at the end of the server's arc. The client now does it, in place, keeping
the overlap-pop fix (zero velocity, drop pitch and roll, lift clear of the floor) -- that fix is
still needed, because the server is about to switch the joints back on and re-enabling them through
a floor is what produced the 12.6 stud pop.

### ~~Measured on the VICTIM'S client, which is the only screen that matters~~

> **WRONG IN PLAY (583fa57).** The owner playtested this build and got the same three symptoms:
> invisible, stuck on the parent, teleport on stand-up. The numbers below came out of an
> `execute_luau` probe, which is not their screen, and they described a body that had not moved.
> `hidden 0` and `transparency 0.00` in particular are worthless -- see the LocalTransparencyModifier
> note in the section below. Superseded by "The local Humanoid was eating the throw".

```
t+0.00s  PS=false
t+13.13s PS=true
ragdoll frames 76 | hidden (camera inside mesh) 0 | inside the parent 0 | max tilt 89.5 deg

13.1s Y 4.8  tilt 48.7  transparency 0.00
13.5s Y 8.5  tilt 78.3  transparency 0.00     <- the arc
13.8s Y 3.2  tilt 86.1  transparency 0.00
14.1s Y 1.1  tilt 83.7  transparency 0.00
15.4s Y 1.0  tilt 85.5  transparency 0.00     <- settled

biggest single-frame move from the hit onward: 2.55 studs
  (one 60 fps frame at the ~114 studs/sec launch speed covers ~1.90, so that is
   physics; the old server-owned version's stand-up moved 161 studs in one frame)

server afterwards: PlatformStand false | WalkSpeed 16.000 | owner nicnicniccoal
pod: Pod_nubkin on the ground at Y 0.78
```

Zero hidden frames, zero frames inside the parent, no snap, and the body tips to 89.5 degrees --
visibly limp for the whole tumble.

> An earlier version of this probe read `GetNetworkOwner()` on the client and died silently inside
> its own `task.spawn`, leaving an empty StringValue and no error where I was looking. That API is
> server-only. The console did have it -- "Network Ownership API can only be called from the Server"
> -- which is an argument for reading the console before rewriting a probe.

### Untouched, verified after

```
character  colliding 4 | constraints 15/15        grip   Nubkin 1.58 / Bellchime 3.09
girth      Nubkin 0.70 / Bellchime 1.64           mill   6 mills, 6 signs, 60 chevrons
plot       2 plants, 0 prompts                    GrabStuds 7, GrabHoldSeconds nil
```

## The local Humanoid was eating the throw — 2026-08-22

Third attempt at this, and the first two failures had the same shape: a fix that measured clean from
the server or from an `execute_luau` probe, and produced **invisible / stuck on the parent /
teleport on stand-up** in the owner's actual playtest.

### The cause

`PlatformStand = true` set on the **server** replicates as a property. It does **not** put the
OWNER'S humanoid into the Physics state. That humanoid stayed in Running, its controller ran every
frame on the victim's machine, and it **zeroed `AssemblyLinearVelocity` the frame after the impulse
was applied**. So:

  * the body never left contact -- it was still standing inside the parent;
  * the camera was therefore inside the parent's mesh, and Roblox's own
    `LocalTransparencyModifier` hides your character when that happens;
  * the server timed out, `restore()` ran, and the character snapped.

**Stop measuring `Transparency` to decide whether a player can see themselves.** It stays 0 the whole
time. `LocalTransparencyModifier` is the one that moves, it is client-only, and it is set by the
default camera module.

### The fix, all on the owner

```lua
humanoid.PlatformStand = true                              -- locally, not just replicated
humanoid:ChangeState(Enum.HumanoidStateType.Physics)       -- the controller stops fighting
root.CFrame = root.CFrame + unit * clear                   -- step out of the parent, HERE
root.AssemblyLinearVelocity = impulse                      -- and hold it for ~0.2s of Heartbeats
```

Re-asserting the velocity for a few frames matters: the controller does not stop dead on
`ChangeState`, and one frame of it winding down is the difference between a throw and a twitch.

While the tumble runs: `CameraMinZoomDistance` is pushed to 12 so the camera cannot sit inside any
mesh, and `LocalTransparencyModifier = 0` is forced on every character part from a
`BindToRenderStep` bound at `Camera + 1` -- **above** the camera module, because that module is what
sets it and anything bound earlier just gets overwritten. Both restored on stand-up.

**The server no longer writes a CFrame on the victim at all.** The step-clear used to happen there;
it was still a server CFrame write on a client-owned body. The distance rides along with the shove
and the client applies it.

**`ragdollOn` no longer forces the Head or any invisible part to collide.** A colliding Head wedges
a ragdoll against geometry and keeps the camera inside a skull; the HumanoidRootPart is a
`Transparency = 1` box the player is not meant to touch the world with.

### What the owner's own console now prints

These come from `ThrowFX` in their PlayerScripts, so they are visible in a real playtest rather than
in a probe:

```
HIT received: dir (0.10, 0, 0.99) speed 114.4 lift 0.45 clear 5.0
ChangeState(Physics) ok=true
stepped 5.0 studs clear
first velocity applied: (11.7, 51.5, 113.8) = 125.4 studs/sec
  Y 13.69  vel 123.8  Head LTM 0.00  state Physics      <- NOT zeroed, which is the fix
  Y 19.16  vel 114.6  Head LTM 0.00  state Physics      <- apex
  Y  2.52  vel  83.6  Head LTM 0.00  state Physics
  Y  5.58  vel  75.9  Head LTM 0.00  state Physics      <- a bounce
  Y  1.00  vel   0.0  Head LTM 0.00  state Physics      <- stopped
settled and levelled at (-7.2, 2.6, -236.0)
done, told the server
```

The velocity surviving frame after frame is the whole point: in the previous build it went to zero
immediately, which is what "stuck on the parent" was.

> `ChangeState` prints `state now Running` on the line straight after the call -- the transition
> lands a frame later. Every subsequent frame reads `Physics`.

### ~~NOT CONFIRMED YET~~ — and it was not fixed

> The owner playtested that build too: **still invisible.** The Humanoid-state fix was real and
> necessary, but it was not the cause. See "A limp body is sixteen assemblies" below.

**This is not done until the owner says they can see their body leave the parent.** Two builds have
now been declared fixed on the strength of numbers gathered from the wrong machine. The prints above
are the evidence to look at during a real playtest; the per-frame line can come out once it is
confirmed.

### Untouched

```
mill 6 mills / 6 signs / 60 chevrons     grip Nubkin 1.58 / Bellchime 3.09
girth 0.70 / 1.64                        plot 2 plants, 0 prompts
GrabStuds 7, GrabHoldSeconds nil         no SetNetworkOwner anywhere
```

## A limp body is sixteen assemblies, not one — 2026-08-22

> **This fixed the flight, not the landing.** The owner playtested it and confirmed the visible
> avatar now hits the ground -- but the camera still followed something else, and they still
> teleported on stand-up. Same root part, three more places. See "The landing was still keyed off the
> box" below.

Fourth attempt, and the actual cause. Every previous fix measured clean because every previous fix
measured **the HumanoidRootPart**, which was the one part that was working.

### The measurement that ended it

A posed R15 rig is held together by `AnimationConstraint`s. Going limp disables those, and what is
left is `BallSocketConstraint`s -- which are CONSTRAINTS, not joints, and **do not merge
assemblies**. Measured on a live character the instant the fifteen constraints go off:

```
assembly roots while limp:
  Head, HumanoidRootPart, LeftFoot, LeftHand, LeftLowerArm, LeftLowerLeg,
  LeftUpperArm, LeftUpperLeg, LowerTorso, RightFoot, RightHand, RightLowerArm,
  RightLowerLeg, RightUpperArm, RightUpperLeg, UpperTorso        -- sixteen, x1 each
```

So `root.AssemblyLinearVelocity = impulse` threw the HumanoidRootPart **on its own**: a
`Transparency = 1` box, two studs by two by one, with the camera following it obediently into the
distance while the body it belonged to stood exactly where it was hit.

That is all three symptoms from one cause:

  * **invisible** -- the visible body never moved, and the camera left with the invisible box.
  * **stuck on the parent** -- because the body genuinely was still standing there.
  * **teleport** -- the joints come back on and the body snaps to wherever the box got to.

### The number that proves it, before and after

Distance from the camera to the **head** during the flight:

```
before   30.3 -> 59.2 -> 92.6 -> 148.0 studs      camera abandons the body
after    13.5 -> 13.7 -> 14.1 -> 13.7 studs       pinned at the zoom distance
```

And the gap between the invisible root and the visible head:

```
rootY 14.90  headY 15.94  gap 1.04     <- normal body geometry, held all the way up
rootY 20.72  headY 21.76  gap 1.04     <- apex
rootY  3.16  headY  4.20  gap 1.04
rootY  0.88  headY  0.61  gap 0.54     <- tumbling on the ground
```

`LTM wanted 0.00` on every frame throughout, which retires the transparency theory entirely: the
camera module never once asked to hide anything.

### What changed

Everything that used to be done to the root is now done to **all sixteen parts**:

  * the impulse, and the few frames of re-asserting it;
  * the step out of the parent -- `character:PivotTo(...)` rather than `root.CFrame = ...`, because
    stepping the root alone moved the invisible box out and left the body inside;
  * the stop at the end -- zeroing only the root left fifteen limbs drifting into the moment the
    joints came back.

### Instrumentation lessons, both paid for twice

**Never measure the HumanoidRootPart to decide whether a player can see their character.** It is
invisible by definition. `gap` -- root to head -- is the honest number, and it was 1.04 studs when
things worked and unbounded when they did not.

**A probe that reads back its own write proves nothing.** The previous build printed
`Head.LocalTransparencyModifier` from a loop while a `BindToRenderStep` forced it to 0 every frame,
and reported `0.00` as though it were evidence. `observedLTM` now records the value found BEFORE the
override, which is the camera module's actual intent.

### Untouched

```
mill 6 mills / 6 signs / 60 chevrons     grip Nubkin 1.58 / Bellchime 3.09
girth 0.70 / 1.64                        plot 2 plants, 0 prompts
GrabStuds 7, GrabHoldSeconds nil         no SetNetworkOwner anywhere
```

## The landing was still keyed off the box — 2026-08-22

The owner confirmed the landing, not the flight: **the visible avatar hits the ground.** So the
sixteen-part impulse worked. What was left was everything that happens AFTER the tumble, because
settling, levelling and the camera were all still reading the `HumanoidRootPart` -- the one part of
this character nobody can see.

Three symptoms, one root part, three separate places:

| what the owner saw | what was reading the box |
| --- | --- |
| camera follows an invisible entity | `CameraSubject` is the Humanoid, and a Humanoid tracks its root |
| tumble runs on past the landing | the settle poll read `root.AssemblyLinearVelocity` |
| teleport on stand-up | `PivotTo(r.Position + up)` pivoted the whole body onto the root |

The third one is the teleport in a single line. The body lands. The invisible box, a separate
assembly on a separate trajectory, is somewhere else. `PivotTo` then drags the body to the box, and
`restore()` re-enables the AnimationConstraints on top of that.

### The rule

**Do not yank the body to the root. Put the root under the body, then re-pose.** The box comes to
the body; never the other way round.

  * **camera** -- `CameraSubject = Head` for the duration of the tumble. A part the owner can
    actually see. Back to the Humanoid only once the root is seated, at which point the two are the
    same place and there is nothing to jump to.
  * **settle** -- on `Head` AND `UpperTorso` speed, whichever is higher. The body can be lying still
    on the road while the box is still sailing over it; that mismatch is what held the tumble open
    past the landing.
  * **landing** -- zero all sixteen assemblies, seat the root on the torso at the **measured** rest
    offset, then stand THAT pair up where the torso is.

### The two numbers that stopped being guesses

Both measured off a real R15 rig in Edit rather than picked by hand:

```
rest offset, root relative to UpperTorso    (0.000, -0.249, 0.000)
HipHeight 2.192 + root.Size.Y * 0.5         = 3.192
root centre to the bottom of LeftFoot       = 3.192      <- the same number
```

So `root.CFrame = torso.CFrame * restOffset` is where the box belongs on this body, and
`groundY + humanoid.HipHeight + root.Size.Y * 0.5` is standing height -- read off the humanoid at
runtime, because HipHeight varies by avatar. It replaces a hand-picked `+1.6`. The ground itself
comes from a downward raycast with the character excluded, not from the root's own Y.

The offset is captured on `CharacterAdded`, from a rig standing in its rest pose. **Not mid-tumble**
-- during the tumble the root and the torso have drifted apart, which is the entire bug.

### Gravity does not pause for a RemoteEvent

The pose built above is sixteen loose parts, and `ragdollOff` lives on the server. A quarter of a
second of round trip is six studs of free fall, so the body would scatter back out of the pose and
the joints would come back on the mess -- the snap all over again, from a new direction.

So the landing is **pinned every Heartbeat** -- re-pivoted and re-zeroed -- until the constraints
answer. Polled on `AnimationConstraint.Enabled` itself rather than sleeping a guessed round trip,
with a 1.5s backstop.

Order at the end, which matters: seat -> `FireServer` -> wait for the joints -> `PlatformStand =
false` / `GettingUp` -> camera back on the Humanoid. The humanoid must not be handed a controller
while the rig is still fifteen loose sockets.

### What to read in the console

```
  rootY .. headY .. gap 1.04 | body 41.2 box 41.2 | camera 13.7 away
seated the root on UpperTorso: was 8.31 studs away, now 0.25
stood up at (-7.2, 3.4, -236.0) (ground 0.20, hip 2.19)
joints back after 0.18s (true)
  standing: gap 1.04 | camera 13.7 away | moved 0.00 from the landing
```

`gap` ~1 and a flat `camera N away` through the stand-up means nothing moved. `moved N from the
landing` is the teleport meter: it is the distance the head has travelled from where the body
actually came to rest, and it must stay near zero.

### The owner's own console, and it says exactly this

The diagnostic line added in `0bbf543` did its job. This is from the owner's machine, on the build
WITHOUT the fix -- one throw, trimmed to the frames that matter:

```
rootY 14.11  headY 15.14  gap  1.04 | vel 124.1 | camera 40.5 away    the flight, correct
rootY  2.68  headY  3.61  gap  0.95 | vel 131.8 | camera 41.2 away    coming down
rootY  1.47  headY  1.51  gap  0.70 | vel  96.8 | camera 41.9 away    THE BODY LANDS
rootY  1.78  headY  3.10  gap  2.98 | vel  98.3 | camera 44.0 away    the box carries on
rootY  0.50  headY  0.96  gap 16.44 | vel  65.0 | camera 55.8 away
rootY  0.50  headY  0.96  gap 46.94 | vel   0.0 | camera 83.0 away    forty-seven studs apart
settled and levelled at (-25.96, 2.10, -178.31)                       <- the BOX's position
```

Read `headY`: after the landing it sits at 0.96 and never moves again. The body was down, at rest,
for the whole second half of that log. Meanwhile `gap` runs 0.70 -> 46.94 and `vel` -- which was the
ROOT's velocity -- is still 65 when the head has been still for half a second.

**The invisible box slid forty-seven studs along the ground after the body stopped**, the camera
went with it (40.5 -> 83.0 studs from the head), the settle poll kept waiting because it was
watching the box, and then `PivotTo` dragged the body to it. Three symptoms, one log, and every
number in it is the argument for the fix above.

### NOT CONFIRMED

The DIAGNOSIS is confirmed, from the owner's screen. The FIX is not: they tested `0bbf543`, not
`465f696` -- Rojo was down when they started, so Studio still had the old ThrowFX (checked with
`script_grep`: line 7 still read "A LIMP BODY IS SIXTEEN ASSEMBLIES"). **Before believing a ragdoll
report, check that Studio has the build being reported on.**

### Untouched

```
mill 6 mills / 6 signs / 60 chevrons     grip Nubkin 1.58 / Bellchime 3.09
girth 0.70 / 1.64                        plot 2 plants, 0 prompts
GrabStuds 7, GrabHoldSeconds nil         no SetNetworkOwner anywhere
16-part impulse, Physics state, client-side nudge -- all kept
```

## Your saved speed did nothing until you touched a pod — 2026-08-22

Reported as "as I start the game, the current speed I have doesn't work, I need to take pods to
recover". It is a join-order race, and the owner's own log has both halves of it.

### The order, from their console

```
[Seed/PlotService]       nicnicniccoal -> Plot_01.
[Seed/ThrowFX]           listening on ThrowVictim          <- a CLIENT script: the body exists
[Seed/PlayerDataService] nicnicniccoal loaded (ok): cash 1046473, speed 14454, tier 1.
```

The character is up and running two log lines before the profile lands. `PlayerDataService`
deliberately loads on a `task.spawn` off the `PlayerAdded` thread -- a fifteen-second DataStore round
trip must not hold up everything else that cares about a join -- so the body always wins that race.

`CarryService.onCharacterAdded` calls `RefreshWalkSpeed` at spawn. That reads:

```lua
local profile = PlayerDataService.Get(player)
local base = GameConfig.walkSpeedFor(if profile then profile.Speed else 0)
```

`Get` returns nil, so it takes the `else 0` branch. **Nothing ever ran it again.**

### What it cost, in their numbers

```
saved score 14454 -> walkSpeedFor = 84.95 studs/sec
nil profile       -> walkSpeedFor = 16.00 studs/sec
                     18.8% of their speed, 5.31x slower
```

`carryMultiplierFor(0)` is exactly 1, so nothing else was involved -- the fallback IS the whole
number.

### Why taking a pod fixed it

`RefreshWalkSpeed` has five callers, and after the spawn one they are all carry events: take, drop,
bank, and the treadmill award. So the first time you touched a pod the profile was long since loaded
and the speed came right. That is not pods restoring anything; it is the only other code path that
happens to recompute it.

### The fix

`CarryService.onCharacterAdded` refreshes again once the profile actually arrives, in the shape
`PlantService.restore` already uses for the same ordering problem -- `task.spawn`, wait on
`PlayerDataService.IsReady`, 30s deadline, then re-validate that the thing is still current
(`player.Character ~= character` bails, because a respawn inside thirty seconds has already started
a wait of its own).

**Not** a `PlayerDataService` -> `CarryService` call: `CarryService` already requires
`PlayerDataService`, so the hook would have been a require cycle. And still nothing new writes
`WalkSpeed` -- `RefreshWalkSpeed` stays the only writer, called one more time.

### Not fixed by this, and it cannot be

If the profile lands DURING a throw, `NestService.restore()` puts back the `WalkSpeed` it captured
at the grab, which would be the stale 16. The clean fix is for `restore()` to call
`RefreshWalkSpeed`, which is a `NestService` -> `CarryService` require -- a cycle, and explicitly
ruled out. Left alone on purpose: the window is the second or two of profile load, and the nearest
nest is 300 studs down the road, so it cannot be reached in time.

## A grown plant reads as an earner — 2026-08-22

Three things matched off a Steal a Brainrot plot clip (`reference1 .mp4` in the repo root), and
nothing else from it. No Shop, Rebirth, Growing Eggs, Grow All, egg or paw rail, hotbar, moon timer,
Friend Boost, Robux packs, Fuse or Reels overlay -- and no tigers. The species stay Nubkin,
Petalpip, Spiretip, Toadcap, Bellchime.

### ~~1. The grown plate is rarity + name + rate~~ — the plate is gone entirely

> **Superseded the same day.** The owner saw it on a real bed and cut it: *"plants name cards is
> unattractive, we should remove it"*. The arithmetic is why. A starting plot is twelve holes, so a
> full one was twelve three-line cards stacked over one patch of dirt with a `+$N` rising through
> each. One card in a screenshot looks good; twelve is a wall.
>
> A grown plant now carries **no billboard at all**. What it earns is the `+$N` popping off it every
> second; what it IS lives in the Garden panel. HATCHING / GROWING plus the m:ss clock is unchanged
> on pods and sprouts -- that is the one case where the world has nothing to say for itself.
>
> Kept below because the colours and the hierarchy are correct and will be wanted again if a plate
> ever comes back, and because this is the third shape this label took: name+rate, rate alone,
> rarity+name+rate, none.

### 1. The grown plate is rarity + name + rate

```
Common     cream (238,235,226)     Nubkin       $2/s
Common     cream                   Petalpip     $5/s
Uncommon   green (142,196, 62)     Spiretip     $14/s
Rare       blue  (108,168,214)     Toadcap      $40/s
Epic       purple(146, 62,158)     Bellchime    $110/s
```

Three lines, always, for everybody -- 140x64, rows 15 / 16 / 21 inside 5px of padding. The rate is
the tallest line and the name the smallest, which is the hierarchy the footage uses.

**This took three passes and two of them were wrong**, so the reasoning is worth keeping:

  1. name + rate, with the finished state made the loudest thing on screen;
  2. rate only -- the owner said "their name tags should be removed, we will make a sidebar to see
     them", and the clip available at the time was corrupted past 7 seconds and showed a pile of
     small overlapping labels that read as clutter;
  3. rarity + name + rate, off the uncorrupted 90-second recording, which shows the real stack:
     `Mythic / Tiger / $100K/s`, `Legendary / Axolotl / $5.9K/s`, `Uncommon / Catfish / $12/s` --
     rarity word in its own colour, name in white, rate in lime and biggest.

Read the footage before arguing from a still. A 7-second fragment of a 90-second clip made a
three-line stack look like noise.

**Rarity is now a word in TWO places**, and the old comment claiming it lived only in the Index is
retracted in both files. The rule that survived is about PODS: an unhatched pod is COLOURED by
rarity, so the word there would be a caption on a photograph -- and worse, it would spend the reveal
early, since two Commons arrive in identical shells. A GROWN creature is coloured by its SPECIES, not
its tier: a Toadcap is cream and red because it is a mushroom, and nothing about it standing in a bed
says it is the Rare one. The colour that carried rarity was on the shell, and the shell is gone.

**No fourth line.** No kg -- kg IS the rate at one cash per kilogram, and printing both prints the
same number twice. No owner, no slot, no gender, no `70,724Kg` tag.

**Pods and sprouts print no rarity and no rate.** HATCHING / GROWING plus the m:ss clock, two lines,
unchanged.

> Note: `Uncommon` in `GameConfig.RarityColor` is (142,196,62), which is ACCENT exactly -- so a grown
> Spiretip shows its rarity word in the same green as its rate. That is the rarity table as it
> stands, not a bug introduced here.

### 2. Lime `+$N` pops, off each plant

`CashPop.client.luau`. Every grown plant pops its own income once a second: accent fill, ink stroke,
GothamBlack, rising 2.5 studs with sideways jitter so twelve plants are not one column.

**Cosmetic.** Nothing here calls `AddCash`; EconomyService is still the only faucet and a player who
edits this script gets prettier numbers and not one extra coin.

**Not driven by diffing `profile.Cash`.** That is the SUM of a plot -- a Nubkin and a Petalpip
together move it by 7, and 7 cannot be aimed at either of them. The whole point is that the
Bellchime pops `+$110` and the Nubkin beside it pops `+$2`, so you can see which square of dirt is
carrying you. And no remote: one per plant per second is 72 packets a second on a full server to say
something both ends already know.

The pop starts at `topOfModel + 2.4` rather than `+ 0.5`, so it clears the three-line plate instead
of rising straight through it. **Honest limitation:** a BillboardGui's SIZE is in pixels and its
OFFSET is in studs, so no single stud value clears a fixed-pixel plate at every distance -- far away
the plate is still 64px while 2.4 studs has shrunk to nothing. Tuned for the range you actually read
a plot at.

Pooled as a FREE LIST rather than SpeedFX's round robin. Round robin is fine when pops are seconds
apart; here forty can be in flight at once and slot 1 coming round again would yank a billboard out
from under a running tween. Range-gated at 90 studs BEFORE the pool is touched, so a pop nobody can
read never takes a slot from one they can.

### 3. The Index

`IndexUI.client.luau`. One button, top-left, in PromptUI's vocabulary -- a book drawn from frames,
because most of Gotham's symbol range is tofu on this engine and SpeedFX already paid for that with a
trainer emoji. The badge is the number still undiscovered and hides at zero. **No Shop button**;
there is no shop, and an empty one is a promise the game has not made.

Cash moved to the BOTTOM-left to clear the rail -- which is where PLAN wanted the dollar figure
anyway. Still one cash number and the SPD line, not a stacked pair of currencies.

Rows are Greenhollow in `SeedData.Species` order, and the denominator is `#SPECIES` rather than a
typed 5. Unseen is a silhouette and `???` with no rate and no kg. Seen gets the name, the rarity WORD
in its rarity colour, `$N/s` and the weight -- rarity is a word only in here, because out in the
world the pod colour already carries it. A footer lists what is in your own dirt this session,
counted off the tagged models under the plot whose `OwnerUserId` is yours. No plot, empty footer,
Index still opens.

### 4. Almanac

`Profile.Almanac: { [string]: boolean }`, defaulting to `{}`. **No Version bump** -- sanitise-into-
defaults IS the migration, exactly as the schema comment always claimed.

Written in `PlantService.render()` when a plant renders as `STAGE_GROWN` on a plot with an owner.
That one line covers both the discovery and the BACKFILL, because restore() re-renders an existing
garden at whatever stage it is already at -- so a player who has been growing Bellchimes since
before this existed has them filled in the first time their plot comes back. No credit for a pod in
a nest, a pod in your hands, or a sprout: the grow-up is the reveal.

`MarkSeen` returns false for an id already known and does NOT dirty the profile in that case.
Without that it would mark the save dirty once per grown plant per stage change, forever, for a
table that had not changed.

Sanitise, measured:

```
in : nubkin=true bellchime=true tiger=true petalpip=false [7]=true spiretip='yes'
out: bellchime, nubkin
a profile with no Almanac at all -> empty table, no migration needed
```

### The bug this pass found: GetBoundingBox was hiding four labels inside plants

`Model:GetBoundingBox()` **reports in the PIVOT'S frame**, and a creature pivots on a cylinder rolled
ninety degrees -- so X and Y come back swapped and the "height" it hands you is the WIDTH. HANDOFF
has said this twice already. PlantUI was placing its name plate at `bbox.Y * 0.5 + 1.4` anyway:

```
species     true top   name plate was   now (+1.2)
Nubkin        1.61         1.95            2.81
Petalpip      2.31         2.17  <- inside  3.51
Spiretip      4.03         2.46  <- inside  5.23
Toadcap       5.06         2.93  <- inside  6.26
Bellchime     6.19         3.56  <- inside  7.39
```

**Four of five species had their label buried in their own head**, including the most valuable thing
in the biome. Only the Nubkin cleared it, and that is precisely why it survived: on the smallest
species the wrong sum lands close enough to look right.

`GameConfig.topOfModel(model, anchor)` measures in world space instead -- the vertical reach of a
rotated box is the sum of the absolute vertical components of its three half-axes, and there is no
frame to be wrong about. Both the name plate and the cash pop call it, so they cannot disagree about
where a plant ends.

### One compactor, not three

`GameConfig.compact`. Three places wanted to shorten a number -- the rate, the pop, the Index row --
and three hand-rolled versions is how the same plant reads $1.5K in one place and $2K in another.
Verified against the clip's own numbers:

```
110 -> 110      1500 -> 1.5K      2000 -> 2K       3500 -> 3.5K
39000 -> 39K    100000 -> 100K    553000000 -> 553M    1e9 -> 1B
```

### What was measured, and what still needs a playtest

Measured in Edit, not eyeballed: all eight files compile; the compactor against twelve inputs; every
species' rate string; the Almanac sanitiser against six junk keys; and the billboard geometry above.

**Not measured: the running game.** The pops rising, the Index sliding, the badge dropping on a first
grow, and a passer-by reading somebody else's plot are all Play-session facts, and `start_stop_play`
is unreliable on this machine.

### In the recording, and deliberately not built

The 90-second clip is a whole competing HUD. Only the three-line plate, the lime pops and the
left-rail Index were taken from it. Rejected on sight, so nobody re-proposes them from the same
footage:

  * **Reels / TikTok overlay** -- side arrows, likes, comments, a full-screen video panel. The owner
    opened it twice in the recording. It is not a plant UI and it is not this game.
  * **Growing Eggs** right-hand panel, `OPEN`, `Grow All`, brown wicker. That is their egg QUEUE.
    Ours hatch in the dirt and PlantUI already is that timer, so cloning the panel would be a second
    UI for a thing that already has one. No paw or egg button on the right either.
  * Shop, x2 Speed Robux, Friend Boost, offline `$553M/Day`, OFFLINE CLAIM, `Hatch! Egg Ready`,
    Upgrade Pen signs, hotbar, moon timer, event banners, SELL as HUD.
  * `+$5.9K Axolotl` -- the clip puts the species name ON the pop. Skipped: the plate two studs below
    it already says the name, and the pop is the one element that has to stay readable at a glance.

### Still not started

**Shop.** No button, no panel, no currency sink. Also still absent on purpose: paw inventory, sell,
fuse, place-from-menu. Plants stay in the dirt.

## The Garden is the clip's Active list, mapped onto dirt — 2026-08-22

`GardenUI.client.luau`, on the RIGHT rail. At 0:58 of the reference recording the owner opens a
right-docked panel: tall, a collapse chevron on its inner edge, a `7/9 Active` header, one row per
occupant with a square thumbnail and a name and a rate, and a fat footer button.

**The shape is borrowed. The idea underneath it is not.** That panel is a LOADOUT -- nine slots,
seven equipped, UNEQUIP and Equip Best and `+1 EQUIP [$75M]`. This game has no loadout. Plants go in
the ground and stay there: nothing to equip, nothing to bench, no tenth slot to sell.

So the count means something better. `GARDEN 3/12` is three things planted in twelve holes of real
dirt, and the empty rows are real empty slots you can walk over and fill. The clip's 7/9 is inventory
management; this is a window onto a place.

### What it shows

```
GARDEN  3/12                          <- planted / GameConfig.plotSlotsFor(tier rows)
  [swatch]  Bellchime   $110/s        <- name tinted by rarity once grown
  [swatch]  Nubkin      HATCHING 0:12 <- ghosted while it waits
  [swatch]  Spiretip    GROWING 1:04
  [     ]   Empty
  ... nine more holes ...
$117/s                                <- total of the GROWN ones, or empty
```

  * **Slot order, not species order.** Row 4 is hole 4 whether or not anything is in it.
  * **Slots are computed.** `plotSlotsFor(rows)` over `PlotTiers[profile.PlotTier].rows` -- 12 / 18 /
    24 / 30 across the four tiers. Never a typed 12.
  * **Badge counts what is still cooking**, hatching and growing only. A grown plant does not badge:
    it already pops `+$N` every second, and a badge that never clears is one you stop reading.
  * **No plot** (overflow queue): header `GARDEN  —`, one row saying `No plot this server`, panel
    still opens.
  * **Footer is a number, not a button.** The clip's fat footer is `Equip Best`; there is nothing to
    equip, so the space goes to what the plot earns per second. Summed on the client from the same
    tagged models EconomyService pays from -- a readout of the server's arithmetic, not a second copy
    of it, and **no remote**. Empty rather than `$0/s` when nothing has finished, because zero is a
    number and nothing-yet is an absence.

### Crown, not Body, for the swatch — measured

```
Nubkin     Body (146,196,106)   Crown (146,196,106)
Petalpip   Body (146,196,106)   Crown (242,238,206)
Spiretip   Body (132,186, 96)   Crown (168,208,122)
Toadcap    Body (242,238,206)   Crown (216,112,100)
Bellchime  Body (242,238,206)   Crown (234,158,158)

Body  -> 2 duplicate squares      Crown -> 0
```

Body would put two identical cream squares next to each other and two identical green ones: four of
five species reading as two. While a plant is still a POD the swatch is the RARITY colour instead --
that is genuinely what the thing in the ground looks like, and the species is not supposed to be
known yet.

### Stage comes from the clock, not the attribute

PlantUI decides HATCHING / GROWING / done from `PlantedAt` and `GrowSeconds`, and this does the
identical sum, so a row and the plant it names can never show different clocks. Branching on the
`Stage` attribute would be authoritative but would disagree with the world for up to a tick, and two
numbers disagreeing on screen is worse than one being a second early. The footer therefore leads
EconomyService by at most one tick on the frame a plant finishes.

### Two panels, two jobs

Opening one does not close the other. They dock on opposite rails.

| | Index (left) | Garden (right) |
| --- | --- | --- |
| answers | what is this species worth | what is in my dirt right now |
| changes | only when you discover something | every second, clocks running |
| shows | `???` until grown, rarity WORD, kg | slot rows, empty holes, live timers |

**The Index's plot footer is gone.** That one-line `Nubkin x2  Petalpip x1` was a stopgap for this
panel -- and it was never the right shape for the question anyway, since it could tell you that you
had two Nubkins and could not tell you that seven of your twelve holes were empty. Index is back to
being one thing: the almanac.

### Rejected from the same recording

Everything the right rail does in that footage, and why not here:

  * **UNEQUIP / Equip Best / +1 EQUIP [$75M]** -- there is no loadout. Plants live in the dirt.
  * **Grow All** -- skipping the grow time deletes the vulnerability window. The wait is when
    somebody can see what is nearly ready in your plot and come for it; a game where you can buy
    past that has no theft in it.
  * **Place-from-menu / drag onto the plot** -- planting is walking there with a pod in both hands.
  * Wood-plank texture, paw and egg icons, Growing Eggs / OPEN, Shop, Reels, Friend Boost, the
    offline banner.

### The rarity word now has exactly one home

Index spells it. Garden tints a finished row's NAME with the colour, which is a hint rather than a
statement. The world says it only by pod colour, on a thing that has not hatched. Three surfaces,
one word, no repetition.

## A pod you own was carried differently from one you stole — 2026-08-22

Two bugs the owner found in one sentence, and the second one had two causes.

### The Garden was naming a pod

`GardenUI` printed `species.Name` at every stage and only ghosted its COLOUR while it waited. That
spends the reveal in a list and makes the entire pod-colour design pointless: pods are coloured by
RARITY precisely so the two Commons arrive in identical shells and you cannot tell which one you got
until it opens.

A pod row now reads `???`. A SPROUT is named, because by then the model in the ground IS the creature
at `SPROUT_SCALE` -- the shape is out there being looked at, and withholding the word would be hiding
something the world has already shown.

### The hand weld was never being destroyed, because it is not where it was looked for

`bank()` builds a Tool for the pod you carry home, and a Tool gets welded to the right HAND by the
engine on equip -- one fist, arm's length, nothing like the two-handed haul the raid uses. The code
already meant to replace that with the same root weld `attachInFront` uses. It never did. Measured on
the owner's live equipped Tool:

```
joint "RightGrip" (Weld) parented to RightHand | Part0=RightHand      Part1=Handle
joint "CarryWeld" (Weld) parented to Handle    | Part0=HumanoidRootPart Part1=Handle
handle sits at (0.00, -0.35, -2.11) in the root's frame, 0.22 studs from the right hand
```

**Both of them, at once.** The engine parents its weld to the **RightHand**, and the code looked for
it with `character:FindFirstChild("RightGrip")` -- which searches DIRECT CHILDREN only. It never
found it, never destroyed it, and the pod was rigidly welded to the fist and to the root
simultaneously.

Note what the numbers do NOT say: `-2.11` is exactly `GripForward(Spiretip)`, so the POSITION was
already right. Do not chase the offset; the fault was an extra weld and the animation that comes with
it.

Two fixes, because there were two ways to lose:

  * **WHERE** -- scan the character's DESCENDANTS for any joint whose `Part1` is this handle and
    which is not ours, instead of guessing a parent.
  * **WHEN** -- the engine builds that weld asynchronously after `Equipped` fires, so a single
    deferred destroy can also simply be early. A `DescendantAdded` watch stays live while the tool is
    held and re-asserts the root weld if a hand weld turns up later. Disconnected on `Unequipped`.

### And the arms were being handed back at the red line

The other half, and the one that actually reads on screen. `CarryPose` poses both arms under the pod
while `CarryingSpecies` is set -- and `bank()` clears that attribute the instant you cross the line,
because as far as the server is concerned you have stopped carrying loot.

But the pod does not leave your hands when you bank it. It becomes a Tool in your hotbar and you walk
on with the same object. So the arms dropped and the default Roblox tool animation took over: the
same pod, held two different ways depending on whose it was.

`CarryPose` now falls back to the `SpeciesId` attribute `CarryService` already stamps on the Tool. An
equipped Tool is parented INSIDE the character, so this reads for every player on screen and not only
the local one -- the same property the attribute had. The pose still beats the tool animation, because
these are `AnimationConstraint.Transform` writes in `Stepped`, which is after the animator has run.

### The rule underneath both

**A pod is a pod.** Stolen, banked, or on its way to the dirt, it is the same object and it should
look the same in your hands. `gripFor()` was already the single definition of WHERE it rides; these
were the two places that let something else win anyway.

## The corner HUD, sampled off the reference rather than eyeballed — 2026-08-23

`money speed gui.png` in the repo root. The owner asked for the money and speed readout to look
exactly like it, so every value was taken out of the file with a pixel sampler.

**The first impression was wrong, which is the reason for sampling.** At thumbnail size the icon
reads as a blue shoe with a GREEN plus badge. Zoomed 6x it is a blue-and-white sneaker with a GOLD
badge -- `rgb(255,216,0)`, 6.5% of the icon's pixels, the single most common colour in it.

```
speed fill      rgb( 25,144,255)   glyphs 24px tall,  "3.5M"   84px wide
cash fill       rgb( 38,255,  0)   glyphs 32px tall,  "$1.8B" 105px wide
outline         rgb(  0,  0,  0)   2px on the speed line, 3px on the cash (~9% of glyph height)
badge           rgb(255,216,  0)   gold, white plus, black edge
shoe highlight  rgb(223,242,252)
```

### The font was solved, not chosen

Six heavy display faces ship with the engine. Measured aspect at TextSize 100 for `3.5M`:

```
LuckiestGuy 2.09   GothamBlack 2.06   FredokaOne 1.88   DenkOne 1.75   Bangers 1.63   Creepster 1.45
```

LuckiestGuy is the only one that is heavy AND slanted AND rounded, which is all three things the
reference is. Then `TextService:GetTextSize` was used to solve for the sizes rather than pick them:

```
"3.5M"  at TextSize 39 ->  83 x 39 px    reference  84 px wide
"$1.8B" at TextSize 47 -> 106 x 47 px    reference 105 px wide
```

Within a pixel on both, and at those sizes the cap heights land on 24 and 32 as well.

Glyph coverage was checked rather than assumed: `$ 0 8 K M B .` and the em-dash all have widths
DISTINCT from GothamBlack's, so LuckiestGuy is drawing its own glyphs and none of them is falling
back to a substitute face. That is the same class of trap as the Gotham tofu dingbats.

### What changed structurally

  * **The ink plate is gone.** Corner radius, stroke, padding, all of it. The reference is bare
    outlined text on grass, and the outline does the job the plate was doing.
  * **Speed moved to the TOP and cash to the bottom**, cash larger. Both are the reference's.
  * **No `SPD` prefix.** The shoe IS the label.
  * The shoe is drawn from six frames -- sole, heel, toe, stripe, badge, two plus bars -- for the
    same reason the Index book and the Garden sprout are. A glyph would be a tofu risk.

### This is the one place the palette does not apply

Ink / paper / accent is the vocabulary everywhere else. These four colours are not in it, on purpose,
and there is a reason past "it was asked for": a HUD number is the only element with no plate behind
it, so it has to survive grass, dirt, a nest and a treadmill on its own. Accent green (142,196,62) is
olive, and on Greenhollow grass it disappears.

The blue is deliberately NOT SpeedFX's shoe blue (96,164,232). Different element, not part of the
request, left alone.

### The cost of compact(), stated plainly

The reference reads `$1.8B`, so the readout uses `GameConfig.compact`. That is lossy in a way commas
were not:

```
the owner's save:  cash 1046473 -> "$1M"      speed 14454 -> "14K"
```

`$1M` will sit there for about eight minutes at 117/s before it becomes `$1.1M`. The ease-toward-
value animation still runs underneath, but past a million there is nothing left for it to show. Under
a thousand `compact` prints exact integers and the number moves on every payout, which is when the
movement is actually teaching something.

If ticking matters more than matching the picture, it is one line: commas, or a second decimal above
a million.

## The shop panel — 2026-08-23

`ShopUI.client.luau`, left rail, under the Index. Built from `shop ui 1.png`, `shop ui 2.png` and
`shop ui 3.png` in the repo root, sampled with a pixel reader rather than eyeballed -- the same
discipline the corner HUD needed, and for the same reason.

```
panel        rgb( 26, 28, 41)   very dark navy, black outline, lighter inner lip rgb(48,50,61)
card cyan    rgb(  0,247,237) -> rgb(  0,116,229)    vertical gradient
card green   rgb(  4,229, 17) -> rgb( 19,126,  1)    the OWNED state
buy button   rgb( 31,246,  0)   flat, rgb(22,143,0) shade under it
close        rgb(255,  0,  0)   white X, black outline
```

Every one of those is in `GameConfig.Shop`, so a restyle is a data edit.

### Studded, which the reference is not

The reference panel carries a faint diagonal lattice -- measured at about five units of luminance
spread, barely there. The owner asked for STUDDED, and it is the better call: Rule 8 is blocky
studded plastic, so a studded panel says the same thing in our own accent.

**Held at the reference's contrast on purpose.** `rgb(52,56,76)` studs on a `rgb(26,28,41)` panel at
0.82 transparency. Any louder and the texture competes with the cards sitting on it, which is the one
thing a shop panel must never do.

Drawn as 12 x 17 = 204 frames on a `UIGridLayout` rather than a tiled image, because nothing in this
repo is placed by hand and there is no asset id to rot. Built once at login, never touched again, and
not rendered at all while the panel is shut.

### The left rail now holds one panel at a time

Index and Shop dock on the same edge at the same size, so they share one rectangle:

```
Index button   y  12..58
Shop button    y  68..114
both panels    y 124..        <- IndexUI's PANEL_TOP moved 68 -> 124
```

At 68 the Index panel covered the button that would have closed it. Both panels now open below the
pair.

They coordinate through a new `OpenPanel` attribute on the player: each writes its own name when it
opens, clears it when it closes, and closes itself on seeing a name that is not its own. Neither
script has to know the other exists, only that something took the rail.

**The Garden is deliberately outside that.** It is on the RIGHT, it never overlaps either, and
reading your own dirt while looking at a price is the whole reason there are two rails.

### Nothing is buyable yet, and the buttons say SOON

This is the UI. There is no `ShopService`, no purchase remote and no cash deduction, so a price
button renders its state and does not transact.

That is deliberate rather than unfinished. Taking money needs a server that owns the decision (Rule
3), and a plot tier in particular is not buyable until `PlotService` can rebuild a bed at a new row
count -- today every plot is tier 1 and nothing changes that, which is what `PlayerDataService`'s own
"PLOT TIER GOES HERE when tiers ship" comment has always said.

A button that read a price and silently did nothing would be the lie. These read `SOON`.

### What it is stocked with, and why that is a placeholder

The references sell Robux: speed packs, cash packs, and x2 gamepasses. All three are things this
repo has explicitly rejected before, and two of them would be a second faucet -- cash mints in
EconomyService and Speed only on the treadmill.

So the first shelf is **PLOT**, selling the tiers `GameConfig.PlotTiers` already defines, priced in
cash. It is the only upgrade the codebase had already designed, and it is a cash SINK, which this
economy currently does not have at all: cash mints and never leaves.

```
tier 1   4 rows = 12 slots   where you start
tier 2   6 rows = 18 slots   $25K
tier 3   8 rows = 24 slots   $250K
tier 4  10 rows = 30 slots   $2M
```

**Those prices are first-pass and untuned.** They live in `GameConfig.PlotTiers` next to the rows,
because a shop cannot be drawn without prices and a placeholder in the data file is honest where one
buried in UI code would not be. Rough shape: ten times a tier. For scale, a starting plot of twelve
mixed plants earns somewhere around 100-400/sec.

## ~~Gold studded rail buttons~~, and one UIKit — 2026-08-23

> **The gold plate is gone.** The owner supplied `shop index.png` and asked for those buttons
> instead, cropped. The rail is artwork now; see "The rail is cropped artwork" below. UIKit survives
> and so does `studs`, which the shop panel still uses -- everything below about the stud rim, the
> clipping trap and the luminance lesson still holds for that surface.

Every HUD navigation button is now the same gold plate: Index and Shop on the left, Garden on the
right, studded, black-outlined.

### The gold is sampled

```
rgb(255,238,119)   the highlight off the reference's gold coin (shop ui 3.png)
rgb(255,216,0)     the plus-badge gold off the corner-HUD shot (money speed gui.png)
```

**No darker lip under the gradient.** The reference's own gold card has none -- its edge is the black
outline, and adding a lip would be inventing depth the source does not have. The green BUY buttons
inside the shop do have one; that is theirs, not the rail's.

### One builder, because three copies is how they drift

`Shared/UIKit.luau` is new, and it is where anything more than one client builds now lives:
`corner`, `stroke`, `gradient`, `studs` and `railButton`.

The reason is concrete rather than tidy-minded. Before this there were about to be **four**
hand-rolled stud grids and **three** hand-rolled rail buttons. Four grids is how the shop panel and
the Index button end up studded at different pitches; three buttons is how one of them quietly keeps
a green stroke after the other two go gold. Same argument as `GameConfig.compact`: the second copy is
where drift starts.

It is NOT in GameConfig. GameConfig holds names, structure and the curves and does not build
Instances; UIKit does nothing else.

### The first stud attempt was invisible, and the reason is arithmetic

> **The owner said flatly that they did not look studded, and they were right.** The studs were all
> there -- measured on a live client: 44 frames, 6x6px, a 14px pitch, 33 of them inside the button,
> none zero-sized. Not a layout bug. They simply had no contrast:
>
> ```
> plate lum 230  ->  stud lum 237     delta  7.2   at the top of the gradient
> plate lum 203  ->  stud lum 220     delta 17.3   at the bottom
> ```
>
> `rgb(255,252,214)` against `rgb(255,216,0)` differs almost **entirely in BLUE**, and blue carries
> 11% of luminance. It composited to slightly-paler gold rather than to anything with an edge.
>
> **What makes a stud read is not brightness, it is the dark ring where the cylinder meets the
> plate.** `rgb(191,132,0)` on gold is a luminance delta of 58-81 -- an order of magnitude more than
> the fill ever had. The pale fill stays as the lit top face; the rim does the work. Studs also grew
> 6 -> 8px, because a 1.5px rim on a 6px disc is most of the disc.
>
> The shop panel went the same way for the same reason: its studs measured a delta of 5.1 and are now
> 15.1. No rim there -- a dark ring on an already-dark panel is instances without contrast, and that
> texture has cards sitting on it.
>
> `UIKit.studs` takes an options table now rather than six positional arguments, which is what made
> `rim` addable without every call site growing two more nils.
>
> **The lesson, and it is the same one the corner HUD taught:** a colour difference is not a contrast
> difference. Check luminance, not RGB.

### Studs, everywhere, static

```
Index button   152 x 46   pitch 14 ->  44 studs
Shop button    152 x 46   pitch 14 ->  44
Garden button   46 x 46   pitch 14 ->  16
Shop panel     430 x 620  pitch 38 -> 204
                                      ---
                          total        308
```

All built once at login and never touched again. There is no per-frame work anywhere in it, which is
the half of Rule 8 that matters on a phone; the instance count is paid once.

A finer pitch on the buttons than on the panel on purpose: 14px with a 6px stud puts about eleven
across a 152px button, which is texture at a glance rather than a pattern you count.

### The clipping trap this hit

`railButton` does NOT set `ClipsDescendants` on the button. Both the Index and the Garden button hang
a red badge half outside their own corner deliberately, and clipping the button cuts the badge in
half. The clipping lives on an inner `Surface` frame that only the studs are inside.

### Icons needed edges

White on pale gold nearly disappears, and green on gold reads as a smudge without a border. So the
Index book, the Garden sprout's stem and leaves, and both button labels all gained a black stroke --
which is also what every readable element in the references has.

## The rail is cropped artwork — 2026-08-23

The owner supplied `shop index.png` -- a 170 x 152 screenshot of a green Shop button and a blue Index
button -- and asked for those, cropped. They replace the gold studded plates.

```
art/rail-shop.png    123 x 49   green slab, cart and "Shop" baked in
art/rail-index.png   123 x 48   blue slab, book and "Index" baked in
art/rail-slab.png     49 x 49   the same skin, blank, hue-rotated to amber
```

Sources are committed under `art/` so the crops can be redone. Uploaded with the MCP
`upload_image` tool off the local 8731 server; the ids live in `GameConfig.Rail`.

### The Index crop had a badge baked into it

The reference has a red "9" over the button's top-right corner. That count is live and cannot be
painted in, so the corner had to be rebuilt.

**The first repair mirrored HORIZONTALLY and dragged the book icon across the button** -- the icon
lives at the left and the damage is at the right, so the mirror source was the icon. Visible as a
white smear beside the word.

**Vertical mirroring is correct**, and the slab supports it: matching top and bottom borders, a
cross-hatch lattice that is symmetric, a vertically centred label, and the only glyph inside the
damaged region is the final `x` of "Index" -- which is itself symmetric top to bottom.

The crop also had to be taken at the button's TRUE rectangle. Scanning the whole band gave 132 x 51
because the badge sticks out past the button's right edge; measuring from rows the badge does not
touch gives the real 123 x 48.

### The Garden button has no reference, so it borrows the skin

Strictly clean columns of the Shop slab -- no cart, no letters -- found by luminance rather than by
eye. The first attempt used a `> 200` white test and let glyph anti-aliasing through, which put
smudges in the tile; requiring every pixel in a column to be within 14 luminance of the fill found
one honest run at x 44..55.

That patch is mirror-tiled so the diagonal lattice has no seam, bordered from the slab's own left and
right edges, then hue-rotated green to amber so three buttons read as three things and not two.

### Displayed 1:1, deliberately

The source screenshot is 170 x 152. There is no resolution to spare, so the buttons are shown at the
crops' native sizes and every pixel is the one the crop actually has. Scaling up would only blur
them. The rail is a little narrower than the old 152px plates as a result.

```
Index  y  12.. 60
Shop   y  66..115      gap 6, positioned off the Index slab's height, not typed
panels y 126..         clears the pair by 11
```

### What came out of the client scripts

IndexUI's book -- a frame, a spine and three lines -- and its "Index" TextLabel are deleted; so are
ShopUI's rail toolbox and "Shop" label. All four are painted into the artwork. ShopUI keeps the
`toolbox` function because the panel's own title bar still draws one. The badges stay: they are live
counts.

The stud defaults moved out of `GameConfig.Rail` and into UIKit beside the code that uses them, since
the shop panel is now the only studded surface left.

### Worth knowing before doing this again

These crops are another game's UI art on the Roblox asset server. That is the owner's call and it is
ordinary Roblox practice, but assets are moderated and a DMCA claim lands on the account, not on the
file. Redrawing the same look in code -- which is what the gold plate was -- carries none of that
risk and scales to any size.

## Weight is rolled per pod, and species is only the shape — 2026-08-24

Every pod that spawns now rolls its own weight, **1 to 10,000 kg, on one curve shared by all five
species**. A 10,000 kg Nubkin is legal. A 12 kg Bellchime is legal. The species decides what the
thing LOOKS like -- cube, orb, teardrop, mushroom, bell -- and nothing else.

`species.Kg` survives on the sheet as exactly one thing: what a plant saved before this gets
restored onto, once, on load. Anything that pays out or measures from it after this is a bug.

### The roll

`SeedData.RollKg(rng)` -- `kg = MaxKg ^ (u ^ 2.2)`, `u` uniform, rounded to an integer and clamped
to 1..10,000. One exponent tunes the whole economy. Measured in Studio over 10,000 real rolls:

```
<=10 kg     54.3%      most pods are pocket change
<=110 kg    73.8%      and most of the rest are ordinary
>=1,000     12.5%      uncommon
>=5,000      3.4%      rare
>=9,000      0.4%      vanishing        min 1, max 9,994, every value an integer
```

A plain log-uniform roll (exponent 1) puts a quarter of all pods over 100 kg, which is far too
generous at the top. **If 10,000 ever becomes common, or nothing exceeds 100, move `KG_CURVE`. Do
not flatten it.** ServerMain prints this histogram at every boot for that reason -- it is a number
that would otherwise drift in silence.

### Instance weight, everywhere

`CreatureModel.Build / BuildPod / BuildCreature` take `kg` and stamp it as the model's `Kg`
attribute. That attribute is the single source afterwards:

```
NestService      SeedData.Roll(biome) for the FORM, then RollKg() for the WEIGHT.
                 One rng, two independent draws.
CarryService     reads pod.Kg BEFORE TakePod destroys it; carries it through drop,
                 pick-up and banking; stamps it on the Tool.
PlantService     Plant(player, species, kg); saves { SpeciesId, Slot, PlantedAt, Kg };
                 GrownIn() yields { species, kg } so EconomyService can pay the
                 instance rate rather than the sheet's.
GardenUI         row clock, row $/s, footer total and the grown name's tint.
PlantUI          the hatch/grow clock -- weight decides it, not form.
CashPop          the +$N over a plant.
CarryPose        the arm angles, off CarryingKg rather than CarryingSpecies.
PlantSway        the idle lean.
```

**Two Nubkins at 4 kg and 900 kg show $4/s and $900/s.** That was the acceptance test and it is
what the sheet-driven version got wrong.

An old save with no `Kg` falls back to `species.Kg` **once**, on load, and the result is written
back with the plant. Re-rolling would be worse than the fallback: a garden left full of heavy
plants would be worth something different every rejoin, which is a slot machine, not a save.

### What you see is what it weighs

Pod shells are coloured by `RarityForKg`, not by the species tier:

```
1-9 Common   10-29 Uncommon   30-99 Rare   100-399 Epic
400-1,499 Legendary   1,500-4,999 Mythic   5,000-8,999 Secret   9,000+ Divine
```

A Nubkin shell glowing Divine is a 9,000 kg cube, and the only way to know is to look at the pod --
which is what makes a nest worth walking into instead of pattern-matching on shape from the road.

The sheet's `Rarity` still means what it always meant: how often that FORM turns up in the pool.
The Index spells that word and now shows **name and rarity only**. It used to print a kg and a $/s
off the sheet; both became lies the moment weights were rolled, because there is no such thing as
"what a Bellchime weighs" any more. The grown world plate stays off -- the `+$N` pop is the world
number.

### Size, and the one place the brief could not be met

`SizeScale(kg)` multiplies the species' frame height; `Girth` halved its slope (0.24 -> 0.12) and
raised its ceiling (1.75 -> 2.40) so the two do not compound into a puddle. `PodDiameter` dropped
its exponent (0.28 -> 0.23) and raised its ceiling (4.5 -> 10.5), so the whole range spans 1.3 to
10.0 studs without the clamp ever binding. `NEST_RADIUS` 13 -> 16: five pods on that ring sit 18.8
studs apart, which clears two 10-stud shells with 8.8 studs to walk between.

Finished heights, **measured off models actually built** in Studio, not read off the formula:

```
kg          Nubkin  Petalpip  Spiretip  Toadcap  Bellchime
     1        1.2      1.6       2.5      2.4       2.5
     2        1.4      1.9       2.9      2.9       3.0
    14        2.3      3.2       4.8      5.0       5.2
   110        4.0      5.6       8.1      9.0       9.2
 1,000        7.4     10.3      14.7     17.0      17.3
10,000       14.1     19.9      27.7     33.4      33.8
```

**The brief asked for 2 kg to look like today's Nubkin (1.74), 110 kg like today's Bellchime
(6.41), and 10,000 kg to land in 18..28 on every form. Those three cannot hold at once.** Worth
writing down so nobody re-opens it expecting a better exponent to exist:

  * 1.74 and 6.41 are 3.7x apart across a 55x weight range, and nearly all of that gap is the
    HEIGHT SHEET (2.4 against 4.0) plus the bell's crown -- not the weight. Pin both and the weight
    curve left over is almost flat (exponent 0.03) and 10,000 kg finishes at four studs. Pin either
    one together with the landmark and the other misses by about 40%.
  * 18..28 is a 1.56x band, but the five forms are 2.4x apart at the SAME weight, because a cube
    ends at its head while a bell carries a skirt and a ring of buds. No exponent narrows that. It
    is the sheet, not the curve.

So `SIZE_EXP` is a least-squares fit to all four written targets at once and misses each by about
the same amount rather than nailing one and abandoning the rest: 2 kg finishes at 1.4 against 1.7,
110 kg at 9.2 against 6.4, and 10,000 kg spans 14..34 against 18..28. **Raising `SIZE_EXP` trades
the small end away for the big one and lowering it does the reverse.** Pick which end matters and
move that one number. A Nubkin stays shorter than a Bellchime at every weight, which was the other
hard requirement and holds.

Plants may overflow their slots at the top of the range. `CanCollide` stays off, so they pass
through each other rather than shoving.

### Verified, and not

Verified in Studio Edit against the code on disk (localhost `http.server`, `HttpService`,
`loadstring`, and a temp module tree so nothing synced was touched):

  * all thirteen changed files compile
  * the histogram above, over 10,000 real `RollKg` calls
  * every band boundary, at both edges
  * the height table above, off real `BuildCreature` output
  * a 9,000 kg Nubkin pod: `Kg = 9000`, `Rarity = Common` (the FORM), shell painted Divine
  * `GrowSeconds` 24s at 1 kg to 300s at 10,000 -- the five-minute wait is unchanged
  * `IncomePerSecond(4) = 4`, `IncomePerSecond(900) = 900`, carry multiplier 1.00 -> 0.30

**Not verified:** nothing has been played. The nest spread, the pick-up, the garden rows and the
old-save fallback are all reasoned and compile-checked but have not been seen on screen.

## Plant where you click, and hatch it yourself — 2026-08-24

Three changes to one loop, and they only make sense together.

```
steal -> bank -> pod in the hotbar
      -> CLICK YOUR SOIL          the pod goes exactly there
      -> wait out its clock       weight decides how long, as before
      -> HOLD E                   it shakes, then bursts
      -> the creature is in your hands, equipped
      -> CLICK YOUR SOIL          the plant goes exactly there, and earns
```

You plant twice on purpose. Where an egg happened to sit is not where the thing that comes out of
it belongs, and a garden you arrange twice is a garden you arranged.

### The grid is gone as a set of positions

`MapService` still builds the invisible 3-by-N grid of `PlantSlot` attachments, and **nothing places
into it any more**. It is kept for one job: a save written before this change carries a `Slot` index
and no position, and that grid is the table saying where index N used to be. Read once on load,
written back out as offsets. Delete the attachments once no live profile can still carry a `Slot` --
not before, because what they migrate is somebody's garden.

The tier still decides HOW MANY fit (`GameConfig.plotSlotsFor`, rows x BedColumns). It no longer
decides where.

**Overlap is allowed, deliberately.** A cap and no spacing rule, so you can cluster things on
purpose. `CanCollide` is already off across the game so they pass through each other.

### The click has to come over a remote, and does not need a new one

`Tool.Activated` fires on the server with no idea where the player was pointing, and `ClickDetector`
does not carry a hit position either. A click point exists on the client and nowhere else.

`GameConfig.Remotes.GameEvent` has existed since the first boot and nothing had ever used it. The
verb is `GameConfig.Plant.PlaceAction`. Everything sent is a claim and is treated as one -- the
server re-checks the plot is theirs, pulls the point onto their own soil, and measures the distance
itself.

**Not `Tool.Activated`, on purpose.** The mobile tool button is UI in the corner, so the tap that
activates a tool is nowhere near the ground and the last known cursor position is wherever they last
touched. `PlantPlace.client.luau` listens for the touch on the WORLD instead, which behaves
identically on desktop and phone. MOBILE FIRST is a repo rule and this is what it costs.

The ray **ignores the Plants folder**, because overlap is legal -- otherwise a big Bellchime would
shadow the soil behind it and there would be a patch of your own bed you could no longer reach.

A translucent disc follows the cursor while a plantable Tool is held: sized to the thing's footprint,
tinted by its weight band, and clamped by the same rule the server clamps by. Without it "exactly
where I clicked" is a claim taken on faith, and the one place it is not exact -- the rim, where the
point is pulled inside -- would read as the click being ignored.

### Nothing hatches on its own

A planted pod counts down and then STOPS, sitting there with a `HatchPrompt` on it. `Ready` goes on
the model; PlantUI drops its countdown plate the moment that happens, because a clock frozen at 0:00
next to a prompt that says HATCH is the same fact twice and the prompt is the half you can act on.

Hold E for `HatchHoldSeconds` (1.1). `PromptButtonHoldBegan` sets `Hatching` on the model and
PlantSway does the shake -- 13 degrees at 27 Hz with a rectified hop, so it only ever leaves the soil.

**The shake is an attribute, not a server loop.** The pod is anchored and server-owned, so jittering
it from PlantService would push a CFrame down the wire per pod per frame to animate a thing one
player is looking at. PlantSway already moves every planted model on every client every frame.

Two consequences in PlantSway worth not undoing:

  * **Pods are in the set now**, with idle amplitude zero. It used to skip anything below SPROUT.
    A ready pod breathes at 35% of a full plant's lean; a hatching one overrides everything.
  * **A hatching pod is exempt from the round robin.** The slice gives each plant about 20 Hz, which
    is fine for a lean and turns a 27 Hz rattle into a slow stagger.

On trigger the shell **bursts** -- parts tweened outward and up, fading over `BurstSeconds` (0.45),
then destroyed. Tweened rather than unanchored: these parts are anchored, CanCollide is off
game-wide, and simulating a dozen shards per hatch on a mobile-first project buys nothing visible.
**The Planted tag comes off first**, so PlantUI's plate and PlantSway's idle let go before the pieces
fly -- otherwise the sway fights the burst for the same pivot and they snap back to centre.

The creature is handed over **before** the pod is destroyed. The other order loses the whole raid if
the player has no Backpack at that instant -- dying with the prompt held is enough.

### The sprout is gone

`CreatureModel.STAGE_SPROUT` still exists and is still buildable; nothing in a bed is ever one. It
existed to make a plot look busy halfway through a timer and it had no decision in it. A save that
carries a sprout restores as a pod, which is what it was.

`GameConfig.Plant.SproutAt` is kept and unused, so old stage arithmetic still reads.

### The Almanac moved to the hatch

The reveal used to be the grow-up. It is the shell breaking now -- until then you do not know which
species you have, because pods are coloured by WEIGHT and two Commons arrive identical. `render()`
keeps a MarkSeen for the one path that produces a grown plant with no hatch in front of anybody: a
garden restored from a save that was already finished.

### Save format

```
{ SpeciesId, PlantedAt, Kg, X, Z, Stage }
```

`X`/`Z` are local to the soil part, never world -- a plot is rebuilt at a different place and
rotation every time its tier changes, and a world position saved through that would put somebody's
garden in the road.

`Stage` is stored because a planted thing is no longer derivable from its clock: a pod whose timer
finished an hour ago is still a pod. Two migrations, both once-on-load then written back:

  * **no X/Z** -> look `Slot` up in the old grid.
  * **no Stage** -> under the old rules a finished clock meant a creature was already standing there
    earning, so those restore as creatures. Anything mid-clock restores as a pod still counting.

### GardenUI is a list now, not a floor plan

Rows were slot N, so an empty row meant "hole N is free". There are no holes. Rows are what you own
in placement order, empty rows at the bottom are room left, and the row count is still the tier's
capacity. Same panel, same style.

A ready pod is the only ghosted row that lights up -- it is the only line in the panel that means GO
AND DO SOMETHING. Still `???`: the name is the hatch's to give.

### Also fixed here

`PlantUI` billboards are **born disabled** and only turned on by `refresh()`. A BillboardGui defaults
to Enabled with both labels empty, so when `refresh` threw -- which it did, for a session, on the
kg signature change -- every plant in the game wore a blank dark rectangle that was never written to
and never switched off. Starting off means a plate is only visible because something put text in it.

### Verified, and not

**Not verified at all.** Written and reasoned; the syntax check could not run because Studio was in
Play (`loadstring` is Edit-only -- the Server datamodel has HttpService but no loadstring, the Client
has neither). Nothing here has been compiled or played.

Worth a hard look on the first run:

  * a 10,000 kg creature is ~34 studs tall as a held Tool. `GiveHatched` measures the model and holds
    it by the base at foot level, but the top of the weight range will still fill the screen.
  * the ghost disc estimates a creature's footprint from `FrameHeight * 0.46 * Girth * 1.5` rather
    than from the model, because the client does not build one. It is a ring, not a promise.
  * a Tool in the hotbar is not saved. Hatch, then leave, and the creature is gone. The banked pod
    has always had this and it is worse now that there are two steps.

## Grown plants walk, and you can pick them back up — 2026-08-24

### The "a plant that WALKS is a bug" comment is overridden, for grown plants only

That comment was right about what it was refusing: **seventy-two Humanoids** on a full server, each
running a state machine and a floor raycast, to move things planted in the ground. None of that is
here. What was added is one more term in the CFrame `PlantSway` was already writing.

```
no Humanoid   no pathfinding   no raycast   no server traffic
one PivotTo per plant, on the same 20 Hz slice it already used
```

Three rules hold it together, and undoing any of them breaks the design rather than the code:

  * **They never leave the bed.** Targets are chosen in the SOIL's object space and clamped to its
    rectangle with the same `EdgeMarginStuds` `PlantService` clamps a click by. A bounds test, not a
    floor test -- nothing to fall through, nothing to path around, and the road is unreachable by
    construction.
  * **They do not steer.** Each plant has its own bearing and walks sideways and backwards rather
    than turning to face where it is going. Steering would point a whole bed one way -- the thing
    free placement exists to stop -- and would spin every plant on the spot at the start of each leg.
    It does turn slowly on its own while standing; see the look-around below.
  * **Pods stay put.** An egg does not stroll. Pods are in the set only for the hatch shake.

**Targets are picked around HOME, never around where the plant currently stands.** A random walk that
steps from wherever it is drifts, and after ten minutes a bed has piled into one corner -- wrong, and
indistinguishable from a bug. Anchoring every leg to the planted offset makes it a bounded jitter
that always comes back.

Every number is a curve in kg, like everything else in this game:

```
kg        radius   speed   pause     reads as
     1      6.0     2.6     2.2s     skittering
     2      5.5     2.3     2.3s     bustling around its patch
   110      3.3     1.2     2.8s     ambling
 1,000      2.4     0.8     3.2s     lumbering
10,000      1.8     0.5     3.7s     a boulder shifting its weight
```

A tier-1 bed is 34 x 47.6 studs, so even the lightest plant's 6-stud radius is a patch it works
rather than a lap of the garden.

The walk **translates the same anchor the lean pivots about**, so the two compose instead of
fighting. Smoothstep across a leg, and a `4t(1-t)` envelope on the bob, the roll and the arm swing so
everything fades in and out with the step -- a standing plant is perfectly still apart from its
breathing, and nothing snaps on the frame a leg begins or ends.

**Two extra CFrame writes per moving plant** swing the Leaf parts as arms after the PivotTo, in
opposition by side. Skipped entirely when standing, because zero swing is exactly what PivotTo
already wrote. Two CFrames on a fifteen-part model is a rounding error next to the pivot, and it is
the difference between a plant that walks and one that slides.

`Sway` grew a per-plant `Random` seeded off `PlacementId`, so no two plants take the same walk and a
rejoin takes the same one again.

**Income does not care.** `GrownIn`, the Garden rows and CashPop all key off the planted entry; the
server never sees the wander and the saved `offset` stays the planted home.

### Every plant faces its own way, and looks around

The first pass pointed every plant at the plot gate, on the reasoning that a bed reads as a crowd
watching whoever walks in. In practice it read as a **parade** -- twelve identical bearings in a
rectangle, which is precisely the arrangement free placement exists to stop happening by accident.

Each plant now gets its own bearing, stamped by `PlantService.render` on top of the plot's rotation.
**The golden angle, not a random number:** 137.5 degrees never lands near a previous one for any
count, so plants placed one after another come out visibly scattered. Random clumps about a third of
the time and the clumps are exactly what this is for.

```
1 -> 138    2 -> 275    3 -> 53    4 -> 190    5 -> 328    6 -> 105
```

**`Facing` is saved**, not derived on load. Placement ids are handed out again on every restore, so
deriving would reshuffle every plant's bearing each time somebody rejoined. A save with no `Facing`
is scattered once on load and written back; before this change every plant in it was pointed at the
gate, and restoring that faithfully would hand the parade back.

On top of the fixed bearing, a standing plant **turns slowly through ±28° and back** -- 12 seconds a
sweep at 2 kg, 26 at 10,000, phased per plant so a bed does not sweep in unison.

`lookPhase` **accumulates** rather than being read off the clock, because it has to stop while the
plant walks and carry on from where it stopped. It advances by `1 - moveT`, which is one when
standing, zero mid-step and smooth at both ends -- so a plant eases out of its look as it sets off
and picks it up again when it arrives. Nothing ever turns and travels at once. The `dt` is real
elapsed time for that entry, not frame time, because `apply()` runs on a slice.

One trap worth not re-stepping in: `lastNow` is seeded to the current `clock`, not zero. A plant
registered ten minutes into a session would otherwise take its first `dt` as ten minutes and snap to
an arbitrary bearing instead of the one the server stamped.

### Unequip actually works now, and it was a weld

`CarryWeld` joins the Handle to the HumanoidRootPart and is **parented to the Handle**, so it went to
the Backpack with the tool and kept pointing at a root still in the workspace. Two failures:

  * **now** -- a joint between a Backpack part and a world part is not something the engine has a
    sensible answer for, and the pod could stay drawn in front of a player who had put it away.
  * **later** -- `fitToRoot` only builds a weld `if not handle:FindFirstChild("CarryWeld")`. The
    stale one survived, so it was never rebuilt, and after a respawn its `Part0` was a root that no
    longer existed. Equip, die, equip again, held by nothing.

`tool.Unequipped` now cuts the weld and the next `Equipped` rebuilds it. Nothing else about the tool
changes -- same kg, same `Hatched`, still not droppable.

A second way in for anyone not looking at the hotbar: **Q / "Put away"**, bound through
`ContextActionService` (so a phone gets the button free) and bound **only while a plantable Tool is
held**, because a touch button that does nothing is worse than no button. It cannot touch a raid
carry -- that pod is a Model welded to the root, not a Tool, and `UnequipTools` does not know it
exists. Two channels, still separate.

`GiveHatched` also **skips the auto-equip while the player is raid-carrying**, since the pod is
welded at the same grip and equipping on top would stack two objects in one place. The creature still
lands in the hotbar and waits.

### Picking a grown plant back up

Owner-only hold-E on your own grown plant -> it lifts and fades, leaves `growing`, persists, and comes
back as the **same Tool `GiveHatched` already builds** (same species, same kg, `Hatched = true`). A
plant that has been moved is indistinguishable from one never placed; there is no second kind of
creature in the hotbar.

**It is not a Take and not a Hatch.** Both words already mean something else here -- Take is what you
do to a nest and it runs the raid alarm, Hatch is what opens a shell. The prompt says **Pick Up**.

Handed over BEFORE the plant is removed, same as hatching: if the Backpack is not there at that
instant the right answer is that nothing happened, not that the plant is gone.

**Freed capacity is the point**, not bookkeeping. A full bed used to be permanent.

The owner check is server-side and is the only thing between a neighbour and your garden. A
ProximityPrompt has no per-player visibility, so a stranger can see a Pick Up on your plant and get
nothing for holding it. Worth fixing in PromptUI one day; not worth trusting the client over.

### Verified, and not

Compile-checked: all 15 touched files parse (`http.server` + `HttpService` + `loadstring` in Edit).
The wander curves in the table above were computed, not estimated.

**Not played.** Nothing in this entry has been seen moving. Specifically unverified:

  * that a plant visibly stays on the bed at the corners, where home is already near the clamp
  * that the leaf swing reads as arms rather than as a glitch
  * hold-E on a walking plant -- the prompt rides the client-local position, which should be exactly
    where the player sees it, but that is reasoning rather than observation
  * whether a 10,000 kg creature at 0.5 studs/sec reads as heavy or as broken

## The plinth is gone — plants grow out of the bed now — 2026-08-24

Every grown plant and every sprout stood on `upright("Mound", H*0.11, H*0.66*G, …)` — one brown
cylinder two thirds of the frame height across. On the bed it read as a **hockey puck**, and it
scaled with the frame, so the biggest thing you could grow was also the one that looked most like
furniture: a 10,000 kg Bellchime stood on a **24-stud dirt pancake**, wider than its own skirt.

The reference sheet (`KB/biome1-plants.png`) has no plinth. It has a loose heap of dirt shoved up
around the stem.

### The pivot and the decoration were the same part, and that was the problem

Four systems need a part at the creature's ground contact and need it to be the `PrimaryPart`:
`PlantService` places by that pivot, `PlantSway` leans and walks about it, `CarryService.GiveHatched`
welds it low in the hands, and the Hatch / Pick Up prompts hang off it. None of that requires it to
be **visible** — the mound was visible by accident, because it was both jobs at once.

Splitting them costs one invisible part:

```
Base   1.2 x 0.06 x 1.2 stem-widths, Transparency 1, PrimaryPart
Soil   nine tilted blocks, overlapping, a fifth buried
```

**A BLOCK, NOT A ROLLED CYLINDER, AND THAT IS A FIX.** `upright` builds cylinders rotated 90° about
Z so their length runs up world Y — which meant the model's pivot had its local X pointing at the
sky. Harmless planted, because `PlantSway` leans about a computed upright anchor rather than about
the pivot. **Not** harmless carried: `giveTool` sets `handle.CFrame = root.CFrame * grip` and welds
everything else to it, so a rolled handle carried the whole plant **on its side**. The Base is
axis-aligned, so a held creature stands up. Pods never had this — `BuildPod`'s PrimaryPart is a ball.

### The stem starts at the bed

`stemBase` was `moundH * 0.7`, sunk three tenths into the puck. With the puck gone that offset would
be a stem hovering, so the base goes to zero and the stem grows the difference:

```
stemH  H * 0.34  ->  H * 0.417     which is exactly moundH * 0.7 + H * 0.34
```

**Every finished height is unchanged** — measured, not asserted. The head sits where it always sat,
`SeedData`'s table still holds, and the boot report prints the same numbers:

```
kg           1     2    14   110  1000 10000
Nubkin       1.2   1.4   2.3   4.0   7.4  14.1
Bellchime    2.5   3.0   5.2   9.2  17.3  33.8
```

Leaves moved to `stemH * 0.51` so they stay at the same height above the soil on the longer stem.

### Two passes on the heap, and the first one was worse than the puck

**Six clods, spaced, sitting flat on the surface, in `sp.Soil`.** They read as separate black
BRICKS with gaps. Two things were wrong:

  * **Colour.** `sp.Soil` was 74, 54, 44 — nearly black — which nobody noticed while it was one big
    cylinder. Against MapService's bed at 158, 82, 52 those clods were lumps of coal. Now
    **124, 76, 50**: a shade darker and browner than the bed, so the heap reads as the same dirt
    shovelled up rather than as a different material.
  * **Shape.** It takes **overlap, a fifth of each clod buried, and a few degrees of tilt** before
    the eye stops counting boxes and starts seeing a heap. Nine clods, highest at the stem and
    thinning outward so it has a peak rather than being a ring of debris.

Sized off the **stem width**, not the frame — that is the whole fix. Dirt belongs to the thing
growing out of it. At 10,000 kg the widest part of a plant is its head or skirt, never a clod:

```
Nubkin    @10,000kg   extents 13.6 wide   widest part Head 10.2      widest clod 3.2
Bellchime @10,000kg   extents 22.7 wide   widest part BellTier 20.5  widest clod 5.3
```

Blocks rather than spheres because a Roblox `Ball` takes its diameter from its smallest axis, so a
squashed lump needs a mesh. Deterministic literal tables, like every other decoration in the file.

The tilt sinks the low corner up to 1.2 studs under the surface on the heaviest plant. Deliberate,
and not visible: planted it is inside the bed; carried, the base rides below foot height so the
overhang is inside the floor. PlantSway's anchor drops with it and the walk carries that same Y
through, so nothing sinks or floats.

Part count went 24 -> 34 on a Toadcap. Nine small smooth blocks against one cylinder.

### Naming

The part is `Base`, not `Mound`. **Nothing keyed off the string** — only comments did, and they are
updated. The one surviving mention of "Mound" is in PlantSway's lean block, where it is history:
it explains why the lean is computed about an anchor instead of about the pivot, and that reasoning
is why changing the pivot's orientation did not break anything.

### Verified, and not

Screenshotted in Edit against a bed the same colour and stud pattern MapService builds — Nubkin
through Bellchime, plus a sprout and a 1,000 kg Nubkin. **No round brown circles; stems meet the
studded soil.** Heights re-measured off real models. All six touched files compile.

**Not played.** Untested in a live session: that the heap still reads at gameplay camera distance
rather than only in a close-up, that a walking plant's heap does not visibly slide against the bed
(it is welded to the model and moves with it, by design), and that a carried creature now stands
upright in the hands — the sideways-carry fix is reasoned from the weld, not observed.

## Two spoilers on a stolen pod — 2026-08-24

The hatch is the reveal. Two Commons arrive in identical shells and which one you got is not knowable
until it opens — the Garden prints `???` on a buried pod for exactly that reason. Two other surfaces
were quietly giving it away.

### The hotbar named the plant before the shell opened

`giveTool` did `tool.Name = species.Name`, so crossing the red line printed **NUBKIN** in the toolbar
on a pod that had never been hatched. One slot along from a Garden row saying `???`.

```
Hatched ~= true   ->  tool.Name = "???"        a banked nest pod
Hatched == true   ->  tool.Name = species.Name  hatched, or picked back up
```

The ToolTip is `band - N kg` in both cases and carries **no species name**. The band is derived from
kg, which the shell is already wearing as its colour, so it gives nothing away — and putting the name
there instead would only move the spoiler from the slot to the hover.

`SpeciesId` still stamps the Tool. Planting has to know what to build; the player just cannot read it
off the toolbar. **Nothing about MarkSeen moved** — the Index still unlocks on hatch and nowhere else.

### The weight billboard is gone entirely

`weightTag` hung a `CarryWeight` BillboardGui reading `6110Kg` on the raid carry **and** on the banked
Tool. Both are gone, and the function with them.

  * **On a pod** it was the same fact a third time. A shell is COLOURED by its weight band and SIZED
    by its weight, so a slab of UI beside the player's head from the nest to the red line said what
    the thing in their arms was already saying, twice.
  * **On a hatched creature** it was measured wrong and could not easily be measured right. The
    offset was `PodDiameter(kg) * 0.5 + 1.1` — a SHELL's radius — which put the label inside the
    chest of a plant. Sizing it off the creature instead would hang it thirty-four studs up on a
    heavy Bellchime, off the top of the screen, which is not better.

That second point is why this went further than the brief, which only asked for pods and offered
deleting both as a simplification. Keeping it for creatures alone would have meant keeping forty
lines of billboard to render a label in the wrong place.

**Nothing functional went with it.** `CarryingKg` is still on the player and on the Tool — walk
speed, payout and planting all read it — and the weight stays legible in three places: the shell's
colour, the placement disc `PlantPlace` tints while you hold something, and the ToolTip.

### Verified, and not

Compile-checked. Every semantic claim above was grepped out of the file rather than assumed:
no `weightTag` function, no call sites, no `CarryWeight` built, `SpeciesId` and `CarryingKg` still
stamped, `bank` passing `hatched = false` and `GiveHatched` passing `true`, and no `MarkSeen`
anywhere in CarryService.

**Not played.** What a `???` slot looks like in the Roblox backpack UI has not been seen, and neither
has a raid carry without its billboard.

## Carrying a plant was not a carry — 2026-08-24

> **The carried scale in this entry was REVERTED the same day** — see "A plant is the same plant in
> your hands as in the ground" below. The drop fix and the `GripReach` fix stand; the shrinking does
> not. Left here because the measurements are still the evidence for why the drop was wrong.


`GiveHatched` handed the creature over at **full size** with its base at **foot level**. On a 2 kg
Nubkin that is fine. On anything else it stopped being a carry.

Measured against a character-sized dummy in Edit — not guessed:

```
                 finished   base y   top y     character head ~5.3
Nubkin     2kg       1.5      0.37     1.83
Bellchime 110kg      9.5      0.13     9.60
Petalpip 1937kg     13.0     -0.12    12.85    below the floor
```

What the player got was **a plant standing on the ground beside them**, taller than they are, with no
relationship to their hands at all. The heaviest in the game is 35 studs.

### Shrunk to carry, on a curve rather than a clamp

```
scale = min(1, (CarriedHeight / finished) ^ CarriedFalloff)      2.4 and 0.8
```

A **hard cap** would make every plant past the limit exactly the same size in the hands, which throws
away the one thing the player is playing for. The exponent keeps them ordered and visibly different
while compressing a 22x range into under 3x:

```
finished  1.5 ->  1.5     a 2 kg Nubkin is untouched
finished  9.5 ->  3.2     110 kg
finished 13.0 ->  3.4     a 1,937 kg Petalpip
finished 35.1 ->  4.1     the top of the range
```

**2.4 rather than 5**: the plant is held in FRONT, so matching the character's height would put it
across the camera. At these numbers the heaviest thing in the game reaches about chin height and you
can still see the road.

`Model:ScaleTo` scales about the model's pivot, which is the Base plate at its ground contact — so it
shrinks toward its own feet and the grip still means what it says.

**Nothing about the plant changes.** PlantService builds a fresh model at full size when it is
planted; the scale lives and dies with the Tool.

The numbers live in `GameConfig.Carry` beside `GripForwardBase` and `GripDrop`, not in CarryService.

### Held at the hip, not the ankle

The drop went `GripDrop - 2.2` -> `GripDrop - 1.0`. The old one put the base at roughly foot level,
which read as the plant standing on the floor — and on a small one it looked dropped. One stud below
the chest puts the base at about hip height at every size.

### CarryPose was aiming the arms with a pod's radius

`anglesFor` computed `SeedData.GripForward(kg)` for whatever was in the player's hands. That is right
for a raid pod and wrong for everything else: a hatched creature is a different shape from the shell
it came out of, and it is **scaled** on top of that, so the pod formula pointed the arms at a place
the plant was not.

CarryService now writes the real number on the Tool as **`GripReach`** when it builds the grip, from
the model it has in front of it. `carriedReach` reads it. A raid pod has no Tool, so its reach still
comes off the weight — correct there, because the thing in your arms IS the shell that formula
describes. `bank` stamps `GripReach` on a pod Tool too, so there is one source rather than two ways
to answer one question.

### Verified, and not

Screenshotted against a blocky stand-in the size of an R15 character, at 2 kg and at 10,000 kg. Both
read as held: base at hip height, plant at chest to chin, character visible past it. The scale table
above was run out of the real `GameConfig`. Three files compile.

**Not played.** The arm pose itself has not been seen — `CarryPose` needs a real rig, and the dummy
has fixed arms. The reach it now receives is correct; whether `43 + 9.2 * reach` still produces a
good angle over the new, much smaller reach range (1.3 to 2.2 rather than 1.3 to 5.9) is untested and
is the first thing to look at if the arms look wrong.

## A plant is the same plant in your hands as in the ground — 2026-08-24

The carried scale added an hour earlier is **reverted**. It was the wrong fix for a real problem, and
the owner caught it immediately: *"the size when i carry it is not the same, big plants become small
when picked up."*

**Weight is the whole game and SIZE IS HOW WEIGHT IS READ.** Shrinking a 9,000 kg plant to the same
silhouette as a 200 kg one — at the exact moment the player is deciding where to put it — takes the
number away from them at the worst possible moment. A plant you pick up must be the plant you put
down.

**Do not reintroduce a carried scale.** If a 35-stud Bellchime is unwieldy in the hands, that is the
cost of a 35-stud Bellchime, and the player chose it when they hauled a 10,000 kg pod home.

### What was actually wrong was the drop

`GripDrop - 2.2` put the base at roughly **foot level**, so the plant stood on the floor next to the
player and read as a separate object that happened to follow them around — and on a small one it
looked dropped rather than held. That is the whole of the original complaint, and it is fixed at
every size by `GripDrop - 1.0`:

```
                    height   reach    base y    top y      feet 0, head 5.3
Nubkin      2kg        1.5    1.30      1.65      3.15     chest height
Bellchime 110kg        9.5    3.54      1.65     11.15
Petalpip 1937kg       13.0    5.89      1.65     14.65
Bellchime 10000kg     35.1   12.20      1.65     36.75
```

Base at hip height at every size: a small plant is at chest level in front of you, a huge one is
visibly lifted clear of the ground rather than planted in it.

### The one consequence worth knowing

Reach is `GripForwardBase + halfWidth` — the same rule pods use, so the plant's near edge just clears
the player. At full size that means **the heaviest plants ride a long way out**: 12.2 studs on a
10,000 kg Bellchime, against 5.85 for the widest possible pod.

If that reads as detached rather than carried, the lever is the reach, not the size:

  * **cap it** (say at the pod maximum, 5.85) and heavy plants overlap the player — you stand inside
    the skirt, which reads as hugging something enormous
  * **leave it** and they float ahead of you, fully visible and never clipping

Left uncapped for now because it matches the pod rule and nothing clips. Changing it is one line.

### What survived from the reverted pass

  * **`GripReach` on the Tool.** CarryPose aimed the arms with `SeedData.GripForward(kg)` — a POD's
    radius — for whatever was in the player's hands. Right for a raid pod, wrong for a creature: a
    Bellchime's skirt is four times its pod's diameter, so the arms pointed at empty air.
    CarryService writes the measured reach on the Tool; `carriedReach` reads it. `bank` stamps it on
    pod Tools too, so there is one source rather than two ways to answer one question.
  * **The drop**, above.

### Verified, and not

The geometry table was measured off real models against a character-sized dummy before the revert and
recomputed after. Compile-checked.

**Not played,** and the screenshots for this pass were not taken — Studio was in a Play session. The
two things to look at: whether a 10,000 kg plant at 12 studs out still reads as carried, and whether
`43 + 9.2 * reach` in CarryPose gives a sane arm angle now that reach runs 1.3 to 12.2 rather than
1.3 to 5.9 (it clamps at 82 degrees, so anything past ~4.2 studs gets the same pose).

## The five plants, remodelled — 2026-08-24

Two faults, one pass. **Five species shared two colours**, and every face was a **sticker made of
parts**.

### Two colours, not five

Nubkin and Petalpip were both `GREEN`. Toadcap and Bellchime were both `CREAM`. Spiretip was fourteen
RGB points off Nubkin, which is not a difference anybody sees across a plot. A bed of five species
read as a bed of two — and GardenUI already carried a comment admitting it, because it had to swatch
by CROWN after Body gave "two identical cream squares next to each other".

```
Nubkin     leaf green         the baseline, and the ordinary one
Petalpip   pale yellow-green  sunlit, lifted off Nubkin
Spiretip   deep pine          the only dark one, the only cool green
Toadcap    warm cream         buttery, under the red cap
Bellchime  cool porcelain     blue-white, so it is not Toadcap
```

**What stays shared is the part that makes it a biome.** Stem, leaf and soil are identical on all
five and must remain so — that family resemblance is what makes the fifth one read as a Greenhollow
creature rather than a stray. The HEAD is where a species gets to be itself.

Still all greens and creams on purpose. Greenhollow is the first biome and the four after it need
somewhere to go; spending saturated colour here leaves Emberroot and Starbloom nothing to be.

### The face was a decal made of parts

Two Eye cards, two Glints, two Cheeks and three Smile bars, every one of them **0.08 studs thick and
smooth**, lying flat on the front of the head. It vanished from any angle off dead centre — and now
that plants walk and each stands on its own bearing, dead centre is exactly where the player usually
is not.

The comment that lived there said a stud on a 0.3-stud eye is a blister rather than a texture. **That
was true of a card and is not true of a ball.** A creature here is moulded plastic and its eyes are
lumps of the same plastic.

```
eyes     dark balls, centred ON the surface so half stands proud. No fudge
         factor -- the radius IS the proudness.
glints   smaller balls sitting on the eyes, smooth. Upper-LEFT on BOTH, not
         mirrored: one shared light is what makes two spheres read as one face.
cheeks   balls
smile    still three blocks -- one bar reads as a grimace -- but with depth
```

**The cheeks needed a fix the cards had hidden.** `front` is the surface distance at the CENTRE of
the face, and four of the five heads are spheres, so the real surface falls away as you move out — at
the old 1.9 gaps an orb's surface has dropped 0.19 head-widths behind `front`, and a ball placed
there hangs in the air beside the head. A card got away with it: thin enough to read as outline from
the front, invisible from the side. A sphere is visible from everywhere, floating included. 1.45 gaps
is the furthest out the error stays under a cheek's own radius on all five, with no per-form
parameter.

`addFace` no longer takes `front + 0.04`. That was the sticker being pushed clear to avoid z-fighting.

### Sculpture, per form

Silhouettes are untouched — cube, orb, teardrop, mushroom, bell.

  * **Nubkin** — a **brow** across the top of the face, standing proud, giving the eyes something to
    sit under and stopping the front reading as a flat panel; two **nubs** on the upper corners,
    which from the side are the difference between a box and a head. Plus the sprout it got earlier.
  * **Petalpip** — five petals in one plane is a paper daisy that vanishes edge-on, and it started in
    mid-air above a bald orb. Petals now **cup** (every one lifts its outer edge, turning five cards
    into a shallow bowl) and three **sepals** sit under them in the leaf colour, offset half a step so
    they show through the gaps. No extra petals.
  * **Spiretip** — a banded **collar** where the head meets the stem. Without it a teardrop is a
    balloon with sticks in the top and nothing explaining where it joins the plant. Plus the ring of
    six spikes from the earlier pass, turned as well as tilted.
  * **Toadcap** — gills under the cap, four bars at 45° giving eight spokes (a bar through the centre
    covers both sides). Spots and fronds stay.
  * **Bellchime** — a **fifth tier** at the hem so the skirt finishes on a ridge rather than just
    stopping, and the scalloped pink collar from the earlier pass.
  * **Leaves, all five** — two blades at the same height and angle read as a rotor from above. A
    smaller **leaflet** higher up and turned the other way leaves no viewpoint where the four line
    up. Both are named `Leaf`, so PlantSway swings the leaflet as an arm for free.

### The budget, and what paid for it

Asked for 25–40 parts per grown plant. Counted, not estimated:

```
shared body 13 (base 1, soil 7, stem 1, leaves 4) + face 9 = 22

Nubkin     cube       head  7  ->  29
Petalpip   orb        head 10  ->  32
Spiretip   teardrop   head 10  ->  32
Toadcap    mushroom   head 17  ->  39
Bellchime  bell       head 18  ->  40
```

A tier-1 bed of twelve at the worst form is **480 parts**.

Three things were cut to pay for the heads, all of them below eye level or behind something:

  * **soil clods 9 -> 7** — still overlaps into one heap; the two bought a brow, a collar and a set
    of sepals, which are at eye level
  * **buds 7 -> 4** — two parts each made this the most expensive decoration in the file, on the
    busiest form. The alternating lean keeps four from looking like a compass rose
  * **collar petals 8 -> 5, gills 6 -> 4, spots 5 -> 4**

Sprouts are the same function at `SPROUT_SCALE`, so every one of these scales down with `H`.

### Verified, and not

**No Studio this pass** — the brief said disk and Rojo only, so the usual `loadstring` parse could not
run. What was done instead:

  * a **block-balance check** over all five changed files (opens vs ends, handling Luau's
    expression-`if`, which takes no `end`) — all balanced, final depth 0
  * every `part()` call audited for keys outside the `Opts` type — none
  * grepped for anything outside CreatureModel reading a face part by name — nothing; PlantSway reads
    `Leaf`, which is preserved, and ParentModel's `Eye` is its own
  * the part budget above, counted off the literal tables

**Not parsed by a Luau compiler and not seen.** The balance check catches an unclosed block, which is
what splicing causes; it does not catch a typo inside an expression. First Play will say.

## The hotbar was saying a rarity it did not mean — 2026-08-24

The Tool's ToolTip printed `SeedData.RarityForKg(kg)`. **There are two rarity vocabularies in this
game and they share four words:**

```
FORM rarity    Common Uncommon Rare Epic             how often a shape turns up.
                                                     The Index spells this one.
WEIGHT band    Common .. Epic .. Mythic .. Divine    what THIS one weighs.
                                                     The pod wears this as COLOUR.
```

So the hotbar called a 1,937 kg Petalpip **Mythic** while the Index called Petalpip **Common**, and a
5 kg Bellchime **Common** while the Index called it **Epic**. Both statements true, both about
different things, and nothing on screen told the player which — so the word was wrong twice over.
Four of five sample weights disagreed.

The design had already settled who owns what: **the WORD belongs to the form, the COLOUR belongs to
the weight.** The tooltip was the one place they crossed.

```
hatched     species.Rarity      exactly what the Index says
unhatched   no rarity word      "Unhatched pod  ·  9,000 kg"
```

**No form rarity on an unhatched pod either**, and not for tidiness: Epic means Bellchime in
Greenhollow, so printing it would name the species through the back door on the one item that has to
stay `???`. Its weight band is still perfectly legible — it is the colour of the shell in the
player's hands.

Nothing else reads the band as a word. `RarityForKg` is still what colours a pod, tints a grown
Garden row and drives `ColorForKg`; only the tooltip stopped spelling it.

Block-balanced. Not parsed by a compiler and not played.

## The HUD is drawn again, not cropped — 2026-08-25

The rail was three crops of `shop index.png` for two days. They looked cropped because they were: the
black outline and the diamond lattice clipped on both sides, the Index badge mirrored out of the
artwork, and all three pinned to the source's native 123 x 48 because a 170 x 152 screenshot has no
resolution to spare. HANDOFF had already written down where that ends — *redrawing the same look in
code carries none of that risk and scales to any size* — so this is that.

`GameConfig.Rail` holds a palette and geometry now instead of three `rbxassetid`s. `art/rail-*.png`
stays on disk as a record of what the buttons used to look like; nothing loads it.

### One slab builder, three buttons

`UIKit.slab` is a rounded rect, a thick black outline, a vertical gradient and a lattice. The rail
buttons are slabs, the panels are slabs and the shop's buy buttons are slabs, so the diamonds are the
same size and the same angle wherever they turn up.

```
Index   blue    130 x 50   book icon, "Index"
Shop    green   130 x 50   cart icon, "Shop"      top at y 68, off the Index slab's height
Garden  amber    50 x 50   sprout icon, no word
```

130 x 50 was chosen rather than inherited: it puts Shop's top at exactly the 68 the old crop left it
at, so nothing below the rail moved. Icons are frames — the book, the cart and the sprout GardenUI
was already drawing. `PanelTop` is gone with the dock.

### ClipsDescendants DOES NOT CLIP A ROTATED CHILD

Worth the heading. The lattice was one long line per row — the box's diagonal plus a margin — rotated
45 degrees inside a `ClipsDescendants` holder. The holder reported `true` and clipped nothing:

```
Index button   position 12, 12   size 130 x 50
its lattice    26 lines, 176 px long, spanning x -87..241, y -40..114
```

So every surface sprayed diamonds a hundred pixels past its own border, across the sky and the grass,
and the texture read as belonging to the world rather than to the button. The panel was worse: its
lattice was built for the 480 x 540 CAP rather than the panel's real size, so it covered the screen.

**The fix is not a better clip, it is a shorter line.** Each row is drawn as the exact CHORD where its
line crosses the box, so no part of any line is ever outside and no clipping is involved. Box centred,
half-width `a`, half-height `b`, `c = sin 45`:

```
|d + t| <= a / c        and        |t - d| <= b / c
```

Intersecting those two ranges gives the visible span; a row whose span comes out empty misses the box
and is not drawn. Both diagonal families reduce to the same pair, so one piece of arithmetic does
both. Fewer instances as a result — fourteen lines on a rail button against twenty-six.

`UIKit.lattice` measures its own parent now instead of being told a size, and rebuilds on resize —
deferred 0.12s, because the open tween moves `AbsoluteSize` every frame and rebuilding forty-six
frames per frame is the per-frame allocation Rule 8 exists to prevent. A few pixels of inset keep the
chords clear of the rounded corner, where a chord cut to the plain rectangle would show outside the
stroke by about 0.3 of the radius.

### The panels open in the middle

All three slid in from an edge and docked under the rail. A docked panel covers the button that
closes it, a left panel and a right panel are two mental models of one interaction, and on a phone an
edge-docked panel is either unreadably narrow or the whole screen anyway.

`UIKit.modal` is a dimmer, a CanvasGroup and a shell: fade plus a 0.92 scale, red X, click the dimmer
to close. One `GroupTransparency` tween fades the whole subtree; the alternative is walking the
descendants and remembering what each was transparent to begin with. `fitContent` heights the panel
to what is in it — five cards in a panel sized for twelve garden rows is two thirds empty, and empty
is what a broken panel looks like.

**The Garden joined the mutex.** It was deliberately outside it on the grounds that it docked on the
RIGHT rail and could never overlap the other two. True of a docked panel, not of a modal.

### The rail is its own layer, and that was a real bug

Each button used to live in its own ScreenGui. Once panels became modals a dimmer filled the screen,
ScreenGuis stack by DisplayOrder, and the Shop's dimmer at 32 sat on top of the Garden button at 30.

**Clicking Garden while the Shop was open hit the dimmer.** The shop closed, the garden never opened,
and nothing errored anywhere — the only trace was `OpenPanel` going to nil. All three buttons now
share a `SeedRail` ScreenGui at DisplayOrder 40: above every dimmer, below SeedAlert's RUN vignette at
50, because an alarm outranks a menu. Shared rather than owned, so a script that re-runs takes out its
own button by name and leaves the other two standing.

### The Index is a grid of plants

It was five 46-pixel rows, each a coloured square beside a name. The square was the FORM RARITY
colour, so a bed of five species read as a column of five TIERS — cream, cream, green, blue, purple —
and there was no plant anywhere on the panel. An almanac whose entries are indistinguishable from a
legend is not an almanac.

Cards now, in a wrapping grid, two columns on a phone and three when there is room, measured off the
panel rather than typed. Each card is a silhouette over a name over the form rarity word.

`UIKit.plantPortrait` draws the five forms from frames — cube, orb, teardrop, mushroom, bell — with
the engine's shape rules intact: a mushroom cap is a rounded pill with a gill bar cutting its
underside, a teardrop is a circle with a rotated square behind it, a bell is tiers widening downward.
The face is the model's nine parts, glint upper-LEFT on both eyes, smile in three blocks with the ends
lifted.

**Not a ViewportFrame.** Five live creatures at 29 to 40 parts each is 170 parts of camera work behind
a panel, on a phone, for a picture that never moves.

An unseen card is the same silhouette in one flat grey with no face and no accents, `???`, and **no
tier — spelled or tinted.** The border stays grey rather than taking `FormColor`: Epic means Bellchime
in Greenhollow, so a tinted border spells the tier in another alphabet. No kg and no $/s anywhere on
this panel, and `ColorForKg` never touches it.

Two flat-drawing fixes the first render caught: Bellchime's tiers were one white lump until each step
took a shade of black — in three dimensions they separate by catching the light, and flat they do not
— and Spiretip's collar at 0.34 wide in a near-white crown read as a plank laid across the plant.

### Shop and Garden follow the same chrome

Both keep what they are. The Shop still sells plot tiers and still says SOON, because there is still
no ShopService; the Garden is still a slot list with the clocks running and still tints a grown row's
name by `ColorForKg`.

What changed is the skin. **The cards are not cyan any more** — they were sampled faithfully off the
reference shots, and a cyan-to-blue tile with a lime button is another simulator's shelf sitting two
panels away from an Index full of Greenhollow greens. Cards are green with an amber button, owned goes
slate rather than green now that available is green, and the plot art is drawn in the biome's own
stem, leaf and soil off `SeedData` — which is why `Leaf` and `Soil` are exported beside `Stem`.

**No Gotham left on any of the three panels.** Everything runs through `UIKit.outlined`, which is
CashUI's LuckiestGuy-plus-black-stroke recipe in one place. The shop's local `outlined` carried a
comment saying the reference's shop text has no slant to it; true of the reference, and wrong for a
HUD whose corner cash readout is LuckiestGuy.

The panel texture went from studs to the lattice for one reason: the rail buttons carry a lattice, and
a panel textured one way opening off a button textured another is two surfaces pretending not to be
related. `UIKit.studs` and the `GameConfig.Shop.Stud*` values are gone with it.

### Verified, and not

Played. Every claim above was clicked, not assumed:

  * all six changed files compile-checked over the localhost 8731 route
  * each button opens its panel in the centre with a dimmer, and only one is ever open
  * **a rail button pressed while another panel is open now works** — the bug this pass introduced and
    then fixed
  * containment measured on every lattice in the HUD by rotated footprint against its surface:
    nine lattices, overhang +0.0 px on all of them
  * the two-column path exercised for real by forcing the Index modal to 300 px
  * the ghost card rendered through the same `plantPortrait` call IndexUI makes for an unseen species

**The unseen state was not seen on a real save.** This account has all five discovered and `receive`
only ever adds to the almanac, so the ghost path was proved by building the cards directly rather than
by owning a fresh profile. The wiring around it — `paint` choosing ghost, the border staying grey — is
read but not watched.

**Rojo was not connected** while this was built. The sources were pushed into the Edit datamodel over
HTTP to see them run; disk is still the only source of truth and re-syncs identically.

## Dustbowl is live, and it is not Greenhollow in tan — 2026-08-27

The second biome is production content now. It landed as four reviewable commits rather than one
biome-sized lump:

```
3337b81  species data and the shared Dustbowl footing
9fb6ea0  Brambleback as the Dustbowl parent
df7784b  Dunebud, Paddlehop, Thornwhorl, Raincup and the Dust Husk pod
dc44034  Suncrown, completing the biome
```

`BiomeData.dustbowl.LiveInPhaseA` is true, with one three-pod nest. `SeedData` has exactly the five
approved forms:

```
Dunebud     Uncommon   husk
Paddlehop   Uncommon   pad
Thornwhorl  Rare       whorl
Raincup     Epic       cup
Suncrown    Legendary  crown
```

The shared body is not Greenhollow's soil mound recoloured. All five use the same Dustbowl root
footing, stem and leaves, then spend their species budget on the approved head. The live grown-part
counts are **31 / 37 / 35 / 40 / 74** in the order above. The Dust Husk is ten parts for every
species and every weight; species remains unknown until hatch, while the shell still communicates
the weight band.

`ParentModel.Build` dispatches `dustbowl` to `BramblebackModel.Build`. The runtime parent is
`Parent_dustbowl`, carries `BiomeId = dustbowl`, and reports the approved **83 visible parts** plus
its invisible `HumanoidRootPart`. Greenhollow keeps its own parent builder. Do not fold the two back
into one recoloured model.

### Verification after the owner stopped Play

Verified against the committed, Rojo-synced files rather than the approval scratchpads:

  * the Rojo endpoint identified **Steal a Seed**, server 7.6.1, pinned to place
    `114075467877655`; a full `rojo build` produced `build/StealASeed.rbxlx`
  * Play started all twelve services with no script error; `NestService` built **2 nests / 8 pods**
    — five Greenhollow and three Dustbowl — and left Tanglemire, Emberroot and Starbloom geometry-only
  * the live Dustbowl nest contained only Dustbowl species and its parent was Brambleback, not the
    Greenhollow parent
  * all five Dustbowl species built in an isolated server folder at 1 kg, 7.5 kg and 10,000 kg;
    every build preserved its `SpeciesId`, and the temporary folder was destroyed afterwards
  * grown part counts were constant across weight; every grown test model had zero MeshParts,
    unions, GUIs, unanchored parts, collidable parts, touchable parts and queryable parts
  * the ten-part Dust Husk built for all five species at all three weights; the live nest then made
    only those loot pods queryable, which keeps the geometry/gameplay boundary intact
  * `git diff --check` passed across the four integration commits, and `main` matched `origin/main`

The only startup warning was the existing `Players.MaxPlayers = 60` against six plots. It is not a
Dustbowl regression and remains open below.

## Biome Speed is guidance, not a daytime lock — 2026-08-27

Every player may enter every biome during the day. `BiomeGateService` still records the permanent
`HighestBiomeOrder` Speed milestone for treadmill overclock progression, but that record is no
longer consulted when deciding whether a player may cross a biome boundary.

The old `SpeedGate` data is now named `RecommendedSpeed`: Dustbowl 167M, Tanglemire 800M,
Emberroot 3B and Starbloom 10B. Entrance arches label those values as recommendations. When the
server observes a player entering any of those four biomes, `BiomeGuideUI` slides in a short banner
with the biome name, mood and recommended Speed, plus an explicit “everyone may enter” note.

The dusk rule did not change. At night the whole road closes, anyone already beyond the road mouth
is returned to the field, and an active carried pod is forfeited. That is a world-cycle rule, not a
Speed requirement.

Static verification passed with `git diff --check`, and a full Rojo build produced
`build/StealASeed.rbxlx`. Roblox Studio's MCP transport was closed during this pass, so one live
walk across the Greenhollow/Dustbowl boundary and one dusk ejection remain the hand-test before
publishing.

## Brambleback lies down through the shared seventh seam — 2026-08-27

Commits `d3c0eb7` and `edbe25a` completed the approved sleep pose. Brambleback first gained its
species-specific curl and breath, then both parent rigs gained a `RootJoint` between
`HumanoidRootPart` and `Torso`. The original six seam names remain unchanged and load-bearing.

The joint uses the model origin as its virtual socket. Brambleback's authored asleep pose is
`CFrame.new(0, 2.58, 2.0) * CFrame.Angles(rad(-68), rad(2), 0)` before the existing `15 / 14.9`
scale, producing the measured shipped translation `(0, 2.5973, 2.0134)`. Its wake scalar blends
continuously to identity. Greenhollow has the same seam contract but no sleep body pose, so its
appearance and 87-part count remain unchanged; Brambleback remains 83 visible parts.

The remaining live check is collision: `Torso` is the only collider while `RootJoint` is animated
locally. If the visible prone body collides at the old standing position, move only the RootJoint
blend to the server. Do not pitch the Humanoid root or alter HipHeight/AutoRotate.

## Placement refusals identify their guard — 2026-08-27

Commit `704b04b` added diagnostic-only logging to `PlantService.PlaceAt`. Its seven refusal branches
now report eight possible codes: `NO_PROFILE`, `NO_PLOT`, `NO_SOIL`, `NO_CHARACTER`, `NO_TOOL`,
`UNKNOWN_SPECIES`, `OUT_OF_RANGE`, and `BED_FULL`. The profile/plot split deliberately distinguishes
an account still loading from a ready player who has no assigned plot.

Logs include player, code and held species, and are rate-limited per player and code for three
seconds. No placement condition, RemoteEvent, or client behaviour changed. The next failed live
placement should be reproduced once and its server code used to choose the actual fix.

## Claude and Codex share one project memory — 2026-08-27

`AGENTS.md` is the single canonical project guide and `.agents/skills/` is the single canonical
seven-skill set. `CLAUDE.md` and `.claude/skills/` are compatibility pointers only. All agents read
this handoff, inspect the checkout and recent commits before editing, and record durable decisions
here with their implementing commit. Provider-specific copies of project rules must not be
reintroduced.

## Character rigging and animation are shared skills — 2026-08-28

Commit `496bf7a` adds `character-rigging` for translating an approved Studio sculpture into a
stable Motor6D/weld/Humanoid assembly, and `character-animation` for state-driven procedural
motion, joint ownership and live nest verification. Claude compatibility entries point back to
those same canonical files. Together with `organic-roblox-form`, every agent now follows the same
appearance -> rig -> animation workflow instead of treating an animated approval mockup as a
production rig.

## Tanglemire is live, and Miremaw performs at its own nest — 2026-08-27

The third biome is production content. Four commits:

```
6f2ddd1  Tanglemire species data and the approved geometry, frozen
2d5ecc7  The five Tanglemire plants and the shared Mire-Cage Pod
84baba8  Miremaw as the Tanglemire parent, and the pose it was approved in
66f32f8  Miremaw sleeps, wakes, chases and settles at its own nest
cbaa422  Tanglemire is live
```

`BiomeData.tanglemire.LiveInPhaseA` is true, with one three-pod nest as the
biome was already configured. `SeedData` has exactly the five approved forms:

```
Bogbonnet    Rare        bonnet     36 parts
Crookreed    Rare        reed       27 parts
Snapmoss     Epic        moss       29 parts
Lanterncap   Legendary   lantern    30 parts
Gloomlotus   Mythic      lotus      39 parts
```

Two Rares in one biome is a first, and they are told apart by silhouette and
palette rather than by rarity word. Gloomlotus is the game's first Mythic form
and the only plant carrying a Neon halo, a Glass dew jewel, two emitters and a
Highlight — that budget IS the rarity.

### The approval was a MOVING mockup, and that changed the method

Every earlier biome was approved as static art. Tanglemire's Miremaw was
approved as an eighteen-second loop that was **still running** when it was read:
the hood alone travels 2.28 studs across it. A single capture is therefore a
mid-blend phase nobody approved, and a rig built on one would have baked a
half-open hood in as its neutral pose.

The mockup publishes its own `PreviewState`, so both endpoints were captured
keyed to it, at the frame closest to each state's typical openness:

```
state       headY   hoodY   hoodZ
ASLEEP      3.929   5.738  +0.868    head tucked, hood drawn back over
WAKING      4.230   6.165  +0.231
SETTLING    4.268   6.223  +0.117
AWAKE       4.497   6.570  -0.573    head risen, hood opened forward
```

**If a future approval mockup animates, capture its endpoints by its own
declared state.** Averaging, eyeballing or grabbing one frame all produce a pose
that was never signed off.

### `TanglemireForms.luau` is the approval, frozen

The mockups lifted part for part: every size, CFrame, colour and material is the
number that was approved. Counts reconcile with the approval exactly — 73
creature parts for Miremaw once the mockup's own plinth is excluded, and 16 for
the pod once its preview dais is.

The pod is stored as **fractions of diameter**, which is not an assumption: 14 of
its 16 parts agree across the three approved diameters to 5.7e-5, so a
D-parametric builder is exact at every weight rather than only at the three that
were drawn. The two that disagree are the dew seal and its stem, by up to
0.021 D, because the dew pulse was running — their shipped pose is the mean of
the three captured phases, which is the rest that pulse swings about.

Plants replay through ONE conformance factor, `hs = FrameHeight / PreviewHeight`,
the same trick Suncrown already uses.

### The mockups were drawn about 1.55x oversize, and one factor fixed it

They carry no weight attribute, so nothing records what weight they were drawn
at. Taken at face value they made a Tanglemire plant about **1.6x a Dustbowl one
of the same weight** — Heights 6.07–6.81 against a ladder that had reached 4.2,
which is not a progression step, it is a different scale.

Every `Height` is now its mockup height times **0.646109**, chosen so the biome's
tallest lands on 4.4 and the top of each band still steps by two tenths:

```
greenhollow  2.40 3.00 3.20 3.60 4.00
dustbowl     2.60 3.00 3.40 3.80 4.20
tanglemire   3.92 3.99 4.35 4.21 4.40
```

**One factor rather than a per-species ladder**, because the five were approved
TOGETHER: Lanterncap is deliberately shorter than Snapmoss, and a tidy ascending
ladder would have quietly reversed that. Scaling the set preserves every such
relationship to within a thousandth.

The geometry did not move. `TanglemireForms` still holds the mockups part for
part and `PreviewHeight` still records what they were drawn at — the commit
changing this touched **zero non-comment lines** in that file. Divide the
conformance factor back out of a shipped plant and every part returns to the
mockup within 0.023 studs, with sizes matching to 3e-6.

Finished heights, soil to crown:

```
kg        Bogbonnet  Crookreed  Snapmoss  Lanterncap  Gloomlotus
     1         2.62       2.67      2.91        2.82        2.94
   7.5         3.92       3.99      4.35        4.21        4.40
10,000        16.52      16.83     18.34       17.76       18.57
```

**Known and deliberate:** Tanglemire grows with weight strictly on the shared
`SizeScale` curve (4.19x from 7.5 kg to 10,000 kg), while Greenhollow's and
Dustbowl's forms grow faster than that because their hand-authored widths
multiply H by a raw girth term. A 10,000 kg Gloomlotus is therefore 18.6 studs
where a 10,000 kg Suncrown is 43.6. Matching that would mean applying girth to
part sizes, and two thirds of Tanglemire's approved parts are rotated off-axis,
so a per-axis girth term shears them. Weights above 5,000 kg are 3.4% of rolls;
revisit only if heavy Tanglemire plants read as undersized in play.

### Girth is damped and horizontal for this biome

Two thirds of the approved parts are rotated off-axis, and scaling a rotated box
along world X and Z does not widen it, it SHEARS it. Each part therefore keeps
its approved proportions and girth spreads the parts apart instead — the same
restraint Suncrown shows. Normalised so the term is exactly 1.0 at the size
reference weight.

### Miremaw: fifteen seams, and the ones that are absent matter as much

Seven are the parent contract. The other eight exist because the two approved
poses disagree across them: four fronds that lag independently, a throat, and
three throat ribs.

The hood and the eyelids are **welded** to the head, because measured between the
two approved poses they do not move relative to it by a thousandth of a stud —
the hood "opening" is the whole head-and-hood assembly rising on the neck, and
the eyes close by transparency and lid colour. Giving either a seam would have
been articulation the approval does not contain.

The three ribs DO get seams, because the sac scales (3.13 -> 2.52) rather than
moves, and a rib welded to a shrinking sac floats a third of a stud off the
throat — nearly twice its own thickness.

The jaw and hood hang off the **Head**, not the torso. Brambleback drives all six
of its seams from the torso, which is fine for a creature whose head barely
moves; Miremaw's head rises 0.87 studs and pitches ten degrees on waking.

Three of the sleep channels are **properties, not joints**, and a joint-only
animator drops all three silently: the throat shrinks, its light dims, and the
eyes close by transparency with the lids recolouring.

### Verification, from the live nest

  * Play built **3 nests / 11 pods**; the Tanglemire nest holds three 16-part
    Mire-Cage pods and one `Parent_tanglemire` at **exactly 73 parts**. Twelve
    services started with no script error.
  * All seven contract seams present; root is the assembly root and is not
    massless; `Humanoid.RootPart` agrees; `Torso` is the only collider; the
    silhouette stands 15.00 studs with its feet on the floor to within 0.000.
  * Plants measured against the approval part for part at the median weight:
    worst position error **0.004 studs**, sizes and colours exact, zero colour
    mismatches across all five.
  * All five species build a pod with identical part names, so the species is
    not knowable before the hatch. 20,000 rolls of the biome produce those five
    ids and nothing else.
  * Sleep/wake sampled on the live client at 30Hz across a full transition
    (approved values scaled by the rig's 0.9401):

```
             head    hood     eye  throat   light
asleep      3.654   5.407   1.000   2.365   0.204
approved    3.694   5.394   1.000   2.369   0.204
awake       4.227   6.167   0.000   3.045   0.724
approved    4.227   6.176   0.000   2.944   0.659
settled     3.654   5.406   1.000   2.365   0.204
```

    Awake overshoots the approved throat and light because the waking pulse
    rides on top of them. Largest single-frame head movement across both
    transitions: **0.090 studs**, so there is no snap.
  * Gait by phase, peak degrees off rest: asleep 0.00 everywhere; awake and
    still 0.00 of swing; walking at 26 studs/sec, 24.6 on the hips.
  * Greenhollow and Dustbowl still report their own parents at 86 and 83 parts,
    and their animation profiles were not edited.
  * `git diff --check` clean; a full `rojo build` produced
    `build/StealASeed.rbxlx`.

### Two traps this pass re-confirmed

  * **Declaration order.** `mireChannels` first landed BELOW `track()`, so every
    parent tracked at startup called a nil and the animator died mid-track. That
    is `a42a12e` all over again, and it presents as "the animation is wrong"
    rather than "the animation never ran".
  * **Forking past shared code forks past its state.** Giving Miremaw its own
    animation path also skipped the STRIDE, so a chasing guardian slid down the
    road with its feet still. The stride is now computed above the fork.

### Remaining hand-tests

  * ~~A hand-driven take has never been verified.~~ **Closed** — see below.
  * **Miremaw at other weights and scales** has only been seen at the one height
    `NestService` asks for.
  * **Heavy Tanglemire plants** grow on the shared curve rather than the
    faster girth-inflated curve the first two biomes use; see above.

## A take was impossible, and the cause was debris in the place file — 2026-08-27

Commit `061a765`. Reported as "i cant take the pod", and it was real: no pod in
any biome could be picked up.

**Cause: `Workspace.SeedGameServer`** — a clone of the entire server folder,
including an ENABLED `ServerMain`, left in the EDIT datamodel by a verification
call that errored before its `:Destroy()` ran. Edit-mode debris survives a Play
session, so every Play booted a SECOND copy of the whole game. Two
`CarryService` instances each attached their own prompt, giving all eleven nest
pods **two `TakePrompt`s on the same part**. With `Exclusivity = OnePerButton`
the engine arbitrates between them and the take never completed.

The tell was in the boot log the whole time: every service printed its Ready
line **twice**. Worth knowing for next time — a doubled boot log means a second
server, not a chatty one.

Removed `SeedGameServer`, a stray `Shared` clone and a `__rig` folder from
Workspace. Immediately afterwards: 11 pods, **one prompt each**, and a take
completes.

**Do not clone `SeedGameServer` or `Shared` into Workspace in Edit to test a
module.** A clone with an enabled Script boots a whole second game the next time
anybody presses Play, and it persists in the place file. Clone into a Folder that
is destroyed in the same call, or better, test in Play.

### The take path now names its refusal

`TryTake` has ten guards and every one returned a bare `false`, so "I can't take
the pod" had ten candidate causes and no way to tell them apart. Same fix
`PlantService` got in `704b04b`: eight refusal codes, rate-limited three seconds
per player and code — `NO_PLAYER`, `NIGHT`, `ALREADY_CARRYING`, `POD_GONE`,
`IS_PLANTED`, `IN_PLOT`, `NO_ANCHOR`, `NO_CHARACTER`, `NO_HEAD`, `OUT_OF_RANGE`
— plus one unconditional line when a hold COMPLETES, which is what separates "the
server refused" from "the input never arrived". Diagnostic only; no guard, no
behaviour and no remote changed.

### The full lifecycle, verified end to end

With the debris gone, one hold on a real Tanglemire nest pod produced, in order:

```
[Seed/CarryService] nicnicniccoal completed a take hold on Pod_crookreed
[Seed/ThrowFX] HIT received: ... speed 180.8
[Seed/ThrowFX] stood up at -56.1, 3.0, -580.0
```

Pod destroyed, `CarryingSpecies = crookreed`, pod welded to the character —
then Miremaw woke, chased the thief down, caught them and threw them clear to
z = -580. Thirty seconds later it was back at z = -1011.9, `Asleep = true`,
`WalkSpeed = 0`, settled in the approved sleeping pose.

That closes criterion 5 through the real `NestService` path rather than through
the `Asleep` attribute, and it is the first hand-driven take this project has
ever confirmed.

## The stall buys your bag — 2026-08-27

Commit `796d129`. A board beside Marigold's stall: hold E, everything in the
bag becomes cash.

**Cash still mints in one file.** `EconomyService.SellHeld` does the paying, so
Rule 6 survives -- but the rule's own banner used to read "one loop, one call"
and now says "one file", because there are genuinely TWO ways to earn. Both sit
forty lines apart in `EconomyService`, which is the point of the rule: "why does
this player have eight million" still has one file to read.

**Price: `SeedData.SellSeconds = 30`.** An item sells for thirty seconds of what
the same plant would pay standing in the ground, so selling is deliberately the
worse deal and the stall is for clearing out pocket change. One number tunes it;
it is not per-species and not per-rarity, because a bag is sold in one press and
a price the player cannot work out in their head will feel wrong however fair it
is.

```
     kg     sells for   planted pays/sec   payback
      1            30                  1       30s
    110          3.3K                110       30s
  1,000           30K                 1K       30s
 10,000          300K                10K       30s
```

**The sign is its own service, not a few lines in MapService.** `SellService`
finds `StallFloor` at Start and builds beside it. That keeps the change out of
`MapService` and `ShopUI` -- the two files the shop pass is most likely to be
editing -- so this should not collide with that work. It is `Priority = 65`,
destroys its own sign before rebuilding (Rule 10), and casts down for the floor
rather than assuming the stall's, which is what stopped the post standing three
tenths of a stud inside the deck.

The raid pod welded to a player is NOT sold: it has not been banked yet, it is
still loot being carried home, and taking it out of their arms at the stall
would be taking something they never put down. Only Tools -- bag and hands both,
because equipping moves a Tool between the two.

### Verified in Play, whole loop

```
[Seed/CarryService] nicnicniccoal completed a take hold on Pod_spiretip
[Seed/CarryService] nicnicniccoal banked a Spiretip (270 kg).
[Seed/EconomyService] nicnicniccoal sold 1 item(s) at the stall for 8.1K.
[Seed/SellService] nicnicniccoal pressed sell-all: 1 item(s), 8.1K
```

8.1K is 270 kg x 30 s exactly. Thirteen services start clean; the board stands on
the deck with zero clearance and faces it dead on (dot 1.000); the hotbar
re-syncs itself because CarryService already watches both containers for
ChildRemoved.

**Not done:** `AGENTS.md`'s file list does not mention `SellService`, because
that file has another agent's uncommitted edit in the working tree and must not
be staged. Add the line when that lands.

**Worth knowing for any prompt test:** `Exclusivity = OnePerButton` means the
engine shows ONE E-prompt at a time. Driving `InputHoldBegin()` on a prompt the
engine has not shown does nothing at all, silently -- which is why a take at a
five-pod nest looked broken until the test listened for `PromptShown` and drove
whichever prompt came back.

## A developer console, and the gate that makes it safe — 2026-08-27

Commit `6b7f94e`. F4 opens a panel: Speed, Cash, spawn any pod at any weight,
teleport, mill and plot tiers, nest restock, parents home, wake the nearest,
sell/clear the bag, drop a carry, and a snapshot to the server log. Fifteen
actions.

**The gate is the feature.** This tool sets Speed and Cash, which in this game
is every exploit at once behind one RemoteEvent. Allowed: Studio, the place
owner on a live server, and anybody in `GameConfig.Debug.UserIds` (empty on
purpose). The check runs on the SERVER before the payload is read; the client
hiding the panel is a courtesy.

Proven, not assumed. With `Debug.Enabled = false`, three commands fired straight
at the remote with no panel involved:

```
[Seed/DebugService] REFUSED debug command from nicnicniccoal (4119740186)   x3
```

Zero replies, no panel built. With it true, all fifteen actions answer.

**It is exempt from Rule 6, out loud.** DebugService mints cash. That is a
deliberate exception written into its banner rather than an oversight, and it is
safe ONLY because it cannot run for a player. If the gate is ever loosened this
becomes a second faucet and Rule 6 is gone.

**Every argument is validated anyway** (Rule 4), because "only I can call it"
stops being true the moment somebody adds a UserId. `SetSpeed` with `"banana"`
answers `not a number`; an unknown action is logged and dropped.

Spawned pods go through the real builder, get the real `SeedPod` tag and are
found by the real prompt -- the same three steps CarryService takes when a pod
is dropped, so a debug pod can reproduce a bug in an ordinary one. They do not
expire, unlike dropped pods.

**A debug tool that lies is worse than none.** `RestockNests` first echoed
"restocked 11 nest(s)" against a road with three, because `NestService.StockAll`
returns `(built, wanted)` POD counts. Now reads "11 of 11 pod(s) standing".

**Not done:** `AGENTS.md`'s file list mentions neither `SellService` nor
`DebugService`, because that file has another agent's uncommitted edit and must
not be staged. Add both lines when theirs lands.

## The catch is a swipe now, and the throw actually lands — 2026-08-27

Commit `141877d`. The guardian winds up, strikes and recovers on contact, and the
victim tumbles clear instead of sliding away upright.

`NestService` stamps `AttackSwipe` on the parent at the hit; `ParentAnim` plays a
three-phase swing off it (wind-up to 28%, strike to 60%, recover to 85%) through
arm pitch/yaw/roll with head and jaw following. The throw direction is now away
from the monster biased toward safety, so being caught against a wall throws you
down the road rather than into it. `ThrowFX` throws the whole body --
`GetDescendants` picks up accessory parts the old `GetChildren` missed, 17 parts
where it used to find fewer -- and holds `PlatformStand` through the launch so
nothing damps the impulse back to a twitch.

### One line of it was a bug, and it is worth remembering the shape

The swipe stamp was written to `nest.model`. **The `Nest` type has no `model`
field** -- it is `parent: Model`, and the other three sites in the file already
used `nest.parent`. So it indexed nil and threw, and it threw *after*
`ragdollOn(character)` and *before* the `FireClient` that does the throwing:

```
loosened = ragdollOn(character)      -- you go limp
nest.model:SetAttribute(...)         -- dies here
rem:FireClient(player, dir, ...)     -- never runs
```

The victim went limp and was never flung. **It presents as a ThrowFX bug and is
not one** -- the whole client throw path is innocent, and it is where you would
look first.

Verified through a real catch at the Greenhollow nest: rise 32.7 studs, peak
150.1 studs/sec, 142.2 studs travelled, client log clean from `HIT received`
through `done, told the server`.

### Starbloom has a guardian, and a runner that must not ship

`AstralmawModel` is dispatched through `ParentModel`'s biome table, so
`starbloom` no longer falls through to the Greenhollow brute.

**`StarbloomGuardianRunner.server.luau` is an authoring aid and it runs on every
server start**, spawning `Parent_starbloom_Preview` at (0, 2, -28) -- which is in
the hub, next to the stall. It is committed so the work is not lost, but it is a
`.server.luau`, so Roblox runs it with no registry entry and no gate:

  * delete it, or
  * gate it behind `RunService:IsStudio()`, or
  * fold the preview into `DebugService` as an action

before the place is published. The same lesson the Edit-mode `SeedGameServer`
clone taught the hard way: a script that spawns things at boot does not care
whether you meant it to.

Greenhollow's guardian is also rebuilt heavier -- deeper torso on a forward
pitch, layered chest plates, bark ribs, spinal thorns, thigh armour.

## Four-biome pod art pass — 2026-08-28

`CreatureModel.BuildPod` now gives the unlocked biome rows four different silhouette regions while
leaving Greenhollow byte-identical:

  * **Dustbowl / below-wide:** five low, irregular wedge shards make a broken sunbaked pan. The old
    upright shard ring read as a wooden cog. Every shard stands on `cf` and the pan is 1.249 D wide.
  * **Tanglemire / flank:** four incomplete tangent withe segments and three tapered hanging strands,
    with dew on only two ends. It implies a crooked living wrap without completing a mechanical
    belt. `TanglemireForms.Pod` remains untouched. Width is 1.175 D, rising to 1.197 D on Colossal.
  * **Emberroot / sides:** four two-joint clinker talons use width-tapered plates, plus three angular
    neon coals resting at the foot. The 1.281 D grip is inside the width rail and no longer reads as
    four straight posts.
  * **Starbloom / diagonal:** five smooth tangent wedges form an open comet crescent with one bright
    head and one dim tail. It retains the diagonal orbit read while dropping the old full ring from
    1.31 D to at most 1.151 D.

The owner approved those outside silhouettes but rejected the shared egg underneath them: five
rows still had the same body, crown, seam, and tier-only colour. The dressing above remains
part-for-part unchanged, while the four unlocked biomes now also own the pod itself:

  * **Dustbowl:** a squat sunbaked-clay drum with a lighter rust shoulder. Its broken ground pan still
    owns the low-wide outline; the smaller crown/seam carries the tier colour.
  * **Tanglemire:** an offset two-lobed gourd in deep bog green and wet reed green. The crooked flank
    wrap still hangs outside it, while the leaf crown and diagonal scar carry the tier colour.
  * **Emberroot:** a basalt-black furnace nut with an oxidized volcanic collar, paired charcoal
    shoulder facets, a forked molten seam and three angular Neon magma inclusions breaking through
    the egg itself. Its four approved talons and three foot coals are unchanged.
  * **Starbloom:** a midnight-indigo double-orb seed with a violet upper lobe and angled crown. The
    approved comet crescent continues its diagonal through the outline.

The biome now owns the dominant body colour. Tier colour moved to the smaller crown/seam, diameter,
and the Colossal label, so value remains readable without making all five biome rows look like the
same rainbow eggs. Titan crowns and Colossal lids retain their biome-specific geometry rather than
reverting to the shared Greenhollow balls.

No second stage was created. `Workspace.PodStages` still holds five biome rows by seven tiers at
`(0, 40, 2400)`. Because `CreatureModel` is detached from Rojo, its Source was pushed directly from
the working file over localhost; the 28 unlocked pods were then rebuilt inside that same stage from
a fresh module clone, leaving the seven Greenhollow stage models in place.

Final runtime audit against all 35 staged pods: 437 BaseParts checked, zero fully inside their
primary `Shell` and zero below `y=40`; every biome's Titan has `CrownLeft`, `CrownRight`, and
`Shell.EmberVent`; every Colossal has `Core`, `CoreGlow`, `AuraAttachment`, `TierTag`,
`PickupSound=ColossalPickup`. Core proudness is `0.240 D` on Greenhollow and higher on the
four revised biomes -- Emberroot `0.360 D`, Starbloom `0.470 D`, Dustbowl `0.545 D`,
Tanglemire `0.550 D` -- because their shells are shorter than one diameter, so the same core
clears a lower crown line. It is not a regression; the earlier `0.240 D` figure was measured
before the bodies were revised and held for the shared egg only. Maximum widths are Greenhollow
1.130 D, Dustbowl 1.303 D, Tanglemire 1.175 D, Emberroot 1.281 D, and Starbloom 1.123 D.

A frozen pre-body-revision Studio clone built all seven Greenhollow tiers against the current
module: 51 parts versus 51, identical by name, CFrame, size, colour, material, and shape. The same
comparison filtered every approved outside dressing part across the other four biomes and seven
tiers; all names, positions, sizes, colours, materials and shapes were identical. The temporary
baseline and audit folders were destroyed afterward.

`rojo build -o build/StealASeed.rbxlx` passes. The pod edits share
`CreatureModel.luau` with the still-uncommitted 22-file kilogram-to-tier sweep; do not commit this
file alone and leave a broken intermediate repository snapshot. Commit the pod pass with that sweep,
or stage its hunks only after the sweep owner lands the prerequisite changes.

## Creature primitives must finish as freeform sculpture — 2026-08-28

The owner rejected visible sphere/box/cylinder construction as the finished look for Emberroot and
set this as the shared direction for all later creature work. Primitives remain the implementation
vocabulary, but large anatomy must be composed from a few overlapping, tapered and rotated masses
whose combined silhouette reads organic. Large spheres are not default heads or bodies. Hands,
feet and limb transitions must be shaped rather than attached as obvious pads or balls.

A “carved mouth” now has a specific acceptance test: brow, cheek and jaw masses must surround a
recessed cavity with real visible depth. A black or glowing panel on a round head does not pass.
Check the front, three-quarter and side silhouettes before detail. If a major region still reads as
the primitive used to make it, rework the anatomy first.

This direction is canonical in `AGENTS.md` and `.agents/skills/organic-roblox-form/SKILL.md`.
`CLAUDE.md` already points Claude to those sources; `GEMINI.md` now gives Antigravity the same
entrypoint. `.cursor/rules/organic-creature-freeform.mdc` carries the same concise always-on rule
for editors that load project rules directly.

## The Speed ladder, Starbloom, and a review of three passes at once — 2026-09-01

Four commits: `5e85c47` (balance), `cd6a799` (Starbloom, girth, leaves, gates),
`35be6d0` (services), `29c6ea3` (review fixes).

### Durable decisions

  * **Mill rates are 20 / 100 / 1K / 8K / 50K / 300K / 2M / 12M / 70M / 400M per second.** Costs
    unchanged. `GameConfig.Treadmill.SpeedPerSecond` is asserted equal to `Mill.Tiers[1].speed` at
    require time, because the two live in different tables and had already drifted.
  * **Overclock is x2 per level, not x4.** At x4 a tier-ten overclocked mill paid 4.19e14/sec and
    crossed the whole score ladder in 2.5 seconds.
  * **Training Rush**: 90s charge, 1x to 4x over 30s, restores at 0.5/s off the belt, capped at 8h
    offline. Rest is credited on the FIRST tick of a visit only — the pay loop rewrites the stamp
    every tick, so crediting it each time refunded half of every second being spent.
  * **`LiveInPhaseA` is now a real gate.** NestService reads it as the second of two conditions.
    Before this, species presence was the only gate in the game, so adding five SeedData rows
    silently opened Starbloom. Only the NESTS are gated; the road stays walkable end to end.
  * **Girth reaches all three assembled-form biomes.** Horizontal spread only — size scales by
    height alone, because scaling a rotated box along world X/Z shears it.
  * **Leaves are named `Leaf`, exactly, as direct children.** That is PlantSway's contract and
    CreatureModel documents it twice. Tanglemire, Emberroot and Starbloom did not comply and their
    plants had never fluttered. NOTE: this changes already-shipped Tanglemire animation.
  * **Showroom runners are modules, never Scripts.** A Script cannot run in Edit at all, so a
    `RunService:IsStudio()` gate can only ever pick the wrong half.

### Verified (Studio Edit, clone-require against the synced tree)

  * Every shared module loads clean; `rojo build` parses the whole project.
  * `ServerMain` is the only self-starting Script in `SeedGameServer`.
  * Nest gates resolve to: greenhollow, dustbowl, tanglemire, emberroot -> NESTS; starbloom held
    (`species=5 live=false`).
  * Girth Tiny -> Colossal, width over height: cinderpaw +6.2%, kilnhusk +5.7%, novaorb +10.8%,
    voidpetal +10.3%, supernovus +11.1%. `emberquill` and `pyrelotus` are 0% — their parts sit on
    the vertical axis and there is nothing to spread.
  * Leaf counts per plant: Greenhollow 4, Dustbowl 2-4, Tanglemire 4, Emberroot cinderpaw 10 (the
    other four have no frond parts), Starbloom 7-16.
  * Progress HUD strings are pure ASCII at every score, both MAX states reached, WalkSpeed caps 150.
  * `PrimaryPart` is set for all 25 species and the pivot sits 0.03-0.23 studs above the base.

### Corrections to HANDOFF-ADDENDUM-2026-08-31.md

  * Its **Finding 6 (no base pivot)** is a showroom artefact, not a live-plant bug.
    `CreatureModel.finish()` sets `PrimaryPart = base` on every exit. `StarbloomMockupRunner` looked
    broken because it calls `StarbloomForms.Build` directly, bypassing CreatureModel — which is also
    why it only ever displayed baseline scale.
  * Its **duplicate-name concern** (`FindFirstChild` returning one `DragonEye` of six) does not apply
    to PlantSway, which iterates rather than looks up.

### Unresolved risks

  * **Nothing here has been Play-tested.** Everything above is static or Edit-mode measurement.
  * **`voidpetal` has 16 leaves**, the most in the game — 16 CFrame writes per plant per 20 Hz slice
    while walking. Harmless while Starbloom is held; measure it before opening that biome with a
    30-plant garden.
  * **Supernovus is 86 parts.** A 30-plant Starbloom garden is ~1,500-2,600 parts per player.
  * **`AutosaveSeconds` went 90 -> 45**, doubling the DataStore write rate. Not reviewed against
    budget at player count.
  * **`LeashStuds` went 600 -> 2000** for the five-biome corridor. `NestService` still carries a
    comment calling it "two segments", which is now wrong.
  * **`StarbloomMockupRunner` still bypasses CreatureModel**, so the showroom shows no PrimaryPart,
    no girth and baseline scale only. It is Edit-only and nobody calls it.
  * **HANDOFF-ADDENDUM-2026-08-31.md sits at the repo root**, not in `KB/`.

## Starbloom opens, and the size curve becomes a live problem — 2026-09-01

Four commits: `6515a73` (plants), `adb5f4e` (guardian and pod), `16dc84b` (the walk),
and this one, which flips `BiomeData.starbloom.LiveInPhaseA` to true.

Starbloom is the fifth biome and the first this flag has actually held back. The other
four went live the moment their species rows existed, because species presence was the
only gate there was; Starbloom opened by accident the same way and was shut again
deliberately.

### Verified before the flag moved (Studio Edit, clone-require against the synced tree)

  * Nest gate passes for all five biomes. Starbloom raises 1 nest of 2 pods at
    `(-38, 0, -1615)`, 1500 studs from safety — the deepest in the game.
  * Astralmaw builds at the nest CFrame: 83 parts, 7 Motor6D, Humanoid and PrimaryPart
    both present.
  * `ParentAnim` dispatches on the `Species` attribute. Astralmaw sets `"astralmaw"`,
    which is neither `miremaw` nor `forgemaw`, so it takes the generic path — and that
    path resolves all seven seams by name, so it walks and chases.
  * Plants: 30 / 33 / 31 / 33 / 46 parts, pupil rig and lids on all five, eyes on the
    surface, girth +7.6% to +10.3% across the ladder.
  * Pods: 21 parts common, 22 Titan, 23 Colossal, nothing below the pod base.
  * Leg rig: emberroot 2 legs, novaorb 2, cosmospire/voidpetal/astralhorn 4,
    supernovus 6, all alternating. Greenhollow, Dustbowl and Tanglemire correctly
    get none.

### Unresolved, and now shipping

  * **The size curve.** `SeedData.SizeScale` returns `Tier.mul` — the VALUE multiplier
    — as a linear height scale, so a Colossal is 50x a Tiny. The orphaned comment
    directly above it still explains the ceiling clamp that was lost when tiers
    replaced kilograms, and cites the reason: the corridor walls are 46 studs.
    Measured share of a biome's pods that grow taller than the walls, weighted by that
    biome's own RarityBonus:

        greenhollow 11.7%   dustbowl 16.6%   tanglemire 25.1%
        emberroot   30.4%   starbloom 39.5%

    Four of the five Starbloom species breach at Giant, which is 20% of that biome's
    rolls on its own. RarityBonus 9.0 is doing exactly what it was designed to do; the
    size curve is what turns that into a defect. A cube root of `mul` keeps everything
    under the walls and changes how every existing save's plants look, which is why it
    is a decision and not a patch.
  * **Astralmaw has no sleep pose of its own.** `SLEEP_BY_SPECIES` in
    `ParentAnim.client.luau` carries `brambleback` and `forgemaw`; Miremaw has its own
    channel path. Astralmaw falls back to `GREENHOLLOW_SLEEP` — a mossy brute's fold on
    a cosmic behemoth. It works and it is not authored for it.
  * **Parents do not gaze.** `ParentAnim` has no eye, pupil, lid or gaze code at all.
    Astralmaw's eye parts are named to the contract so it is free to wire later, but
    nothing drives them today.
  * **Still no Play test.** Everything above is Edit-mode measurement.

## Handoff: economy multipliers, Starbloom, and the Emberroot roots — 2026-09-02

Written for whoever picks this up next, in any tool. `HEAD` is `e683b3c` and pushed;
`origin/main` matches. There is UNCOMMITTED work in the tree — see "In flight" below.

### What landed this session, newest first

  * `e683b3c` **Plant income gained rarity and biome factors.** `SeedData.IncomePerSecond`
    now takes `(species, tier)` rather than a tier alone and returns
    `floor(tier base x rarity x biome + 0.5)`. `RarityMultiplier` runs Common 1.00 to
    Divine 12.00; `BiomeMultiplier` runs greenhollow 1.00 to starbloom 1.40. `SellPrice`
    is still exactly `SellSeconds` (30) times that. All five callers pass a species
    (EconomyService x2, CashPop, GardenUI x2) — there is ONE calculation and no copy of
    the formula anywhere else. Two require-time asserts refuse the file if a species has
    a rarity or biome with no multiplier, which is what allows the runtime fallback for
    an unknown species to be a quiet 1.00x rather than a crash.
    Measured live: a bed of five paid 3,244/sec before and 6,330/sec after (6,323 predicted).
  * `d84d797` **Starbloom went live.** `LiveInPhaseA = true`. It is the first biome the
    flag has actually held back; the other four opened the moment their species rows
    existed. NestService reads the flag as the second of two gates.
  * `16dc84b` **Plants walk.** They now face their leg's heading (eased, 0.22s), and legs
    swing from the hip. Verified in a running server: a plant mid-leg turned 124.7 degrees
    where the old cap was LOOK_AMP at 28.
  * `adb5f4e` Astralmaw face + Starbloom pod; `6515a73` the Starbloom five into the art
    bible band with void eyes.

### In flight, NOT committed — awaiting owner approval of the look

  * `EmberrootForms.luau` (modified) and `EmberrootRootMockupRunner.luau` (new).
  * `CinderPad` — a flat 2.30 x 0.26 x 2.10 slab that scaled with the body — is gone from
    all five Emberroot species, replaced by a sculpted root system: a three-mass knot plus
    four or five paths of two to four overlapping tapered segments with wedge tips,
    deterministic per-segment jitter, and one or two neon fissures lying along a root.
  * Ground roots carry a `GroundRoot` attribute and scale on their OWN curve in
    `EmberrootForms.Build`: `min(hs ^ ROOT_DAMP, ROOT_MAX_SCALE)` with `ROOT_DAMP = 0.16`
    and a ceiling of 2.0, applied uniformly on all three axes so taper and path shape
    survive. The body still takes the full `hs`.
  * Measured, Tiny -> Colossal: part counts 41->59, 42->60, 43->60, 41->59, 51->70;
    14-16 root parts each; largest Colossal footprint 7.75 studs inside an 11 cell; zero
    root corners below the base plane; `Base` PrimaryPart intact; exactly two walking-leg
    clusters per species with alternating phases.
  * Preview: `require(game.ServerScriptService.SeedGameServer.EmberrootRootMockupRunner).Build()`
    — ten models in open sky at (600, 300, -600), Tiny row on a 16-stud pitch and Colossal
    row 300 studs behind on a 280-stud pitch. `Ghost(true)` fades everything that is not a
    root or a leg, because the crown completely hides the roots from directly above.
  * **Do not commit this until the owner has approved the appearance in Studio.**

#### Independently re-verified

A second pass rebuilt all ten models from fresh clones with CreatureModel's requires
repointed, changed nothing, and reproduced every figure to the decimal. Colossal:

    cinderpaw  59 parts 15 roots 4.52 x 7.75    kilnhusk   59 parts 15 roots 4.65 x 7.41
    emberquill 60 parts 15 roots 3.32 x 5.91    pyrelotus  70 parts 16 roots 5.37 x 6.66
    slagbloom  60 parts 14 roots 5.74 x 6.97

CinderPad 0 | largest footprint 7.75 | below base plane 0 | Base PrimaryPart 10/10 |
two leg clusters per species, phases 180/0.

The ART constraints were asserted in the first report but never measured. They were then
measured, and they hold:

    species      balls  cyls  wedges  segment widths   bearing gaps (deg)
    cinderpaw        0     0       4  0.12-0.41        1 6 7 14 23 33
    emberquill       0     0       4  0.08-0.28        2 4 5 7 10 10
    slagbloom        0     0       4  0.18-0.48        0 6 13 16 50 60
    kilnhusk         0     0       4  0.21-0.52        2 3 10 18 18 30
    pyrelotus        0     0       5  0.12-0.31        3 4 4 7 20 22

Zero Ball and zero Cylinder parts in any root system -- the sphere-pile tell is absent in
fact, not just in description. Widths vary three to four times within a species, so no
equal-width bars. Bearing gaps run 0 to 60 degrees, which is the numeric form of "not a
radial wheel": an evenly spaced system would show near-identical gaps.

#### The roots are NOT black

Base is burnt bark `88, 60, 48` over basalt `52, 40, 38` and char `30, 24, 23`, with one
species ember each -- Cinderpaw `198, 68, 24` through Pyrelotus `255, 128, 148`. That is
the charcoal / basalt / burnt-bark / cooling-slag direction as briefed. A summary calling
them "black" has already been written once; do not act on it and repaint a palette that is
already correct.

#### Locked, until the owner says otherwise

  * Do not restore a square CinderPad.
  * Do not turn the roots into spheres, cylinders, equal-width bars or radial wheels.
  * Do not enlarge the roots beyond the planting cell to compensate for oversized Colossal
    bodies. The roots obey their limit; the body curve is the thing that is wrong.
  * Do not redesign the five silhouettes without explicit approval.
  * Measurements establish technical compliance. They do NOT certify artistic quality --
    that needs a close three-quarter Studio orbit with `Ghost(true)`, by eye.

### Unresolved, and known

  * **The 50x size curve.** `SeedData.SizeScale` returns `Tier.mul` and uses it as a linear
    HEIGHT scale, so Colossal is fifty times Tiny. The orphaned comment directly above it
    still explains the ceiling clamp that was lost when tiers replaced kilograms, and cites
    the reason: the corridor walls are 46 studs. The game prints the evidence at every boot:
    `Bellchime finished height: Tiny 6.3 | Mega 36.9 | Colossal 453.9`.
    Share of a biome's pods that grow taller than the walls, weighted by that biome's own
    RarityBonus: greenhollow 11.7%, dustbowl 16.6%, tanglemire 25.1%, emberroot 30.4%,
    starbloom 39.5%. A Colossal Emberroot measures 210 x 233 x 373 studs.
    A cube root of `mul` keeps everything under the walls and changes how every existing
    save's plants look, which is why it is a decision and not a patch.
  * **The Emberroot roots no longer meet the feet at high tiers** — a direct consequence of
    damping the roots while the body keeps the 50x curve. On a Colossal Cinderpaw the
    `LeftRootSole` is 26 x 13 x 39 studs and the claw reaches 31 studs forward, against a
    root system spanning 4.5 x 7.75. Containing the footprint was the instruction; the
    mismatch belongs to the size curve above.
  * **`Players.MaxPlayers` is 60 against 6 plots.** Self-reported at boot. Needs Game
    Settings, not code.
  * **Guardian health is inconsistent**: greenhollow, dustbowl and starbloom parents are
    `inf`; tanglemire and emberroot are `100`.
  * **Parents do not gaze.** `ParentAnim.client.luau` has no eye, pupil, lid or gaze code at
    all. Astralmaw's eye parts are named to the contract so it is free to wire later, but
    nothing drives them. Astralmaw also has no entry in `SLEEP_BY_SPECIES`, so it falls back
    to `GREENHOLLOW_SLEEP` — a mossy brute's fold on a cosmic behemoth.
  * **One unexplained observation.** In a long Play session the cash HUD sat on its "—"
    placeholders and never updated, though profile packets were arriving. It works on a
    clean boot. Ruled out: stale source, scoping, missing remote, duplicate scripts and
    `ResetOnSpawn` (all ten HUDs pin it false). Not reproduced, cause unknown.

### Traps that cost real time — read before measuring anything in Studio

Four separate measurements this session produced confident, wrong answers. Each would have
become a false bug report.

  * **The require cache keys on the ModuleScript INSTANCE, and Rojo rewrites `Source` in
    place.** A module required earlier in a session keeps answering with its old body no
    matter how many times the file changes. Clone before requiring — and if you need
    `CreatureModel` to pick up your clone, rewrite the `WaitForChild("X")` in the clone's
    own Source too. Reading a live service this way also gives you a FRESH module with no
    game state: `PlayerDataService.Get` returned nil for a player who was plainly loaded.
  * **`StreamingEnabled = true`.** Client-side queries about distant parts are lies. Two
    biomes' pods looked completely empty from the client and were perfectly intact on the
    server. Measure world content on the SERVER.
  * **Every creature part has `CanQuery = false`.** Raycasts through them hit nothing, so a
    "is this eye occluded" test silently answers "nothing there" for all 25 species.
  * **A Ball renders as a sphere of its SMALLEST axis and a WedgePart is half its box.** A
    box-containment test therefore reports parts as buried inside geometry that does not
    exist. Nine species were flagged as having buried eyes; one actually did.
  * **`GetBoundingBox` reports in the PIVOT's frame** and these models pivot on a rolled
    cylinder, so X and Y come back swapped. Use world extents from part corners.
  * **`rojo build` only PARSES.** It never compiles Luau and never runs a module body, so a
    register-limit error, a bad assert or a wrong table reference all survive it. Require
    the module in Studio to find those.
  * **`--!strict` must be the first bytes of the file** — no BOM, no banner above it. Luau
    reads the pragma only in the leading comment block and silently drops the whole file to
    nonstrict otherwise, and the build will not catch it.
  * **A `.server.luau` Script cannot run in Edit at all.** `RunService:IsStudio()` is true in
    Play, so that gate protects the published game and leaves playtests building your
    gallery. Showroom runners are ModuleScripts with `Build()`/`Clear()`. Three were
    converted or deleted for this.

### Naming contracts the client animates on

`PlantSway.client.luau` finds rigs by name, on DIRECT CHILDREN of the plant model:

  * `Leaf` — exact match. Swung as an arm while the plant walks. Suncrown's four were
    renamed from `SupportLeaf1-4` to comply, and Tanglemire, Emberroot and Starbloom were
    all renamed for the same reason.
  * `*Eye`, `*Pupil`, `*Lid` — suffix match. A `*Pupil` upgrades the plant to the pupil rig,
    where the eyeball swings in its socket and everything mounted on it rides along.
    `LeftEyeMain` satisfies nothing.
  * Legs are matched from a vocabulary — Thigh, Femur, Haunch, Shin, Tibia, Knee, Hock,
    Foot, Hoof, Paw, Toe, Stilt, Pillar — then grouped by HIP: the parts in the upper half
    cluster one per leg, and everything else joins the nearest in plan view. A leg needs an
    upper part to exist at all, which is what separates Emberroot's root-THIGH from
    Dustbowl's root-FOOT. Parts that must travel with the body without swinging must avoid
    every one of those words.

## THE FIVE-LEVEL PLOT LADDER — 2026-09-02

Plots are bought, one rung at a time, and the bed grows outward from a gate that does
not move. Uncommitted; the Emberroot work in the tree is separate and untouched.

    level  capacity  rows  cost         depth   plantable reach from the gate
      1       5        2   free         35.2     7.6 - 27.6
      2       7        3   25,000       47.4     7.6 - 39.8
      3      10        4   250,000      59.6     7.6 - 52.0
      4      15        5   2,500,000    71.8     7.6 - 64.2
      5      20        7   25,000,000   96.2     7.6 - 88.6

### CAPACITY IS WRITTEN DOWN, NOT DERIVED

It used to be `rows * BedColumns` — the invisible planting grid doubling as the gameplay
limit — which tied how DEEP a plot looks to how MANY plants it holds. Level 5 is seven
rows for twenty plants precisely because those two had to come apart.

`GameConfig.plotCapacityForTier(level)` is the single answer. `plotSlotsFor(rows)` still
exists and is still the attachment grid; it is NOT capacity and nothing reads it as such
any more. MapService stamps `Level`, `Capacity`, `Rows`, `Depth` and `PlotCF` together in
`dressPlot`, and PlantService/GardenUI read the `Capacity` attribute rather than
recomputing.

### THE GATE IS THE FIXED POINT

A plot is placed by its CENTRE and its depth runs from the gate backwards, so a deeper
plot at the same centre would swallow the walkway and push its gate into the hub ring.
`MapService.ResizePlot` therefore recovers the gate, and rebuilds the centre from it:

    gate  = oldCF * CFrame.new(0, 0, -oldDepth/2)
    newCF = gate  * CFrame.new(0, 0,  newDepth/2)

**`oldCF` is the `PlotCF` attribute, never `GetPivot()`.** The PrimaryPart is the invisible
floor and the floor is built 0.1 studs above the centre, so a resize that used the pivot
rebuilt the plot 0.1 higher every time — measured, then fixed, then re-measured at
0.000015 studs of drift over ten consecutive resizes.

`ResizePlot` keeps the Model, its attributes, its tags, and the `Plants` and `Runtime`
folders as the SAME instances; everything else is destroyed and rebuilt. `buildPlot` was
split into itself plus `dressPlot(model, cf, level)` to make that possible.

### THE PLANTS DO NOT MOVE

Offsets are stored SOIL-LOCAL and the soil moves when the depth changes, so doing nothing
would slide a whole garden backwards by half the depth change. `PlotService` fires
`OnResizing` / `OnResized` around every rebuild and `PlantService` captures world points
and rebases offsets across them — the dependency is inverted through those two listener
lists because PlantService requires PlotService and not the other way round.

On a GROW the clamp is a no-op and not one model moves. On a SHRINK a plant can end up
behind the new back edge, and then its model is moved onto the bed to match its rebased
record — otherwise record and model disagree and the plant jumps on next login. Measured:
one pod relocated 60.64 studs, the five plants already in reach moved 0.00.

### ORDERING, WHICH IS THE WHOLE RACE

A plot is handed out the instant a player joins; the profile that says how big it should be
arrives seconds later. `PlotService.SetDesiredLevel` is the only entry point and is safe
before assignment, after leaving, and with rubbish. `assign()` sizes the plot BEFORE the
SpawnPad lookup, before `placeCharacter` and before `onAssigned` — so PlantService restores
into a correctly sized bed and the player is given their real plot in ONE build.
`release()` returns the plot to Level 1 after `clearPlot`, and forgets the desired level.

`PlayerDataService` calls `SetDesiredLevel` one line BEFORE it fires `profileReady`, so the
client never sees a packet claiming a level the world has not built yet.

### SAVE VERSION 2

`GameConfig.Save.CurrentVersion = 2`. `ProfileSchema.Sanitise` migrates v1 profiles once,
after the plants are sanitised, and two things are non-negotiable:

  * **Not one valid saved plant is ever discarded.** The level is raised to fit the garden,
    never the garden cut to fit the level. Over twenty plants is Level 5 and over capacity,
    which is legal and persists.
  * **The plants do not move.** Distance from the gate is `z + depth/2` and is independent
    of which ladder measured it, which is also what breaks the apparent circularity —
    the new depth depends on the new level, the level depends on whether the plants fit,
    and gate distance depends on neither, so it is measured once up front.

**v2's deepest level is SHALLOWER than v1's** — 96.2 against 132.8, because capacity stopped
being tied to the grid. So an old tier 3 or 4 garden has a rear section with nowhere to
stand; those plants are clamped to the back of the new bed. They keep everything else.
Anyone below old tier 3 sees nothing at all.

### PlotUpgradeService

Priority 60. A third verb on the existing `GameEvent` remote — no new remote. **The client
sends a verb and nothing else**: not a level, not a price, not a plot id. Charge, record,
build; any later failure refunds and reverts, because paid-and-not-upgraded is the one
outcome that must not stand. Per-player reentrancy guard. The purchase cue is fired by the
server at the plot, so a refused click never sounds like a purchase.

`DebugService.SetPlotTier` now writes the profile AND rebuilds the plot. It used to write
only the profile, which was harmless while the number was inert and is not now.

### Verified

`tools/tests/PlotSpec.luau` — 33 assertions, all passing, run from Edit:

    python -m http.server 8731
    local run = loadstring(game:GetService("HttpService"):GetAsync(
        "http://127.0.0.1:8731/tools/tests/run.luau", true))()
    print(run("PlotSpec"))

In a live server: gate drift 0.000000 on a real purchase and 0.000015 over ten resizes;
plant drift 0.000000; Plants and Runtime folders identical instances; PrimaryPart and
SpawnPad rebuilt and `RespawnLocation` refreshed; two clicks in one frame charged once;
a 6-plant garden in a capacity-5 plot restored **all six** across a rejoin, logging
`restored 6 plant(s) -- 1 over the level's capacity of 5, kept`.

### Concurrency, closed out

**The whole transaction is atomic, and that is why none of this can interleave.** Every step
between `busy = true` and `busy = false` was audited: `AddCash`, `SetPlotTier` and
`SetPlants` are pure table writes through `touch`; `ResizePlot`/`dressPlot` are Instance
work; `SoundKit.emit` uses `Debris` and `task.delay`. **`TryUpgrade` never yields**, so
`PlayerRemoving` cannot fire inside it. The same audit clears `assign` — `placeCharacter`'s
`WaitForChild` sits inside a `task.spawn` — so `release -> drainQueue -> assign` completes
in one frame.

That is an accident of the current implementation, not a guarantee, so the ownership
re-check was added anyway. Three defects were found and fixed:

  * **`desiredLevel` leaked for queued players.** The clear sat past `release`'s
    `if not id then ... return end`, so it never ran for a player who left while QUEUED --
    which is the player most likely to have an entry, since a queued player's profile loads
    and records their level while they wait. The table is keyed by the Player instance, so
    each miss held a Player object for the life of the server.
  * **`SetDesiredLevel` would record for a departed player.** It wrote before checking. Now
    refuses when `player.Parent ~= Players`.
  * **`TryUpgrade` used a stale plot reference** for the geometry step and the purchase
    cue. Both now re-fetch. If ownership is gone the purchase STANDS -- charged, recorded,
    geometry deferred to their next plot -- which is complete and consistent, and strictly
    better for a player who did nothing wrong than an unwind.

Measured live, all in one Play session:

    upgrade L3 -> L4, charged exactly 2,500,000, 0.27s          (no income confusion:
                                                                 a charge is ~400s of income)
    release right after it:  L4 -> L1, cap 15 -> 5, owner -> 0,
                             OwnerName -> "", Claimed -> false,
                             Plants 6 -> 0, Runtime 0
    gate drift on release            0.000004 studs
    gate drift over 5 resizes        0.000021 studs
    TREADMILL drift                  0.000000 studs   (it is a SIBLING of the plot, so
                                                       ResizePlot cannot reach it)
    Model still reusable: PrimaryPart, SpawnPad, Soil, PlotId, Plot tag all intact
    rejoin: plot rebuilt to L4 (soil span 59.80 = L4), THEN 6 plants restored, 0 off soil

**Plants cannot restore before geometry.** `restore` is a spawned thread that polls
`IsReady` every 0.25s. It becomes eligible the instant the profile lands -- but
`PlayerDataService` goes from `entries[player] = {...}` to `SetDesiredLevel` with no yield
between, so the parked thread cannot resume in the gap. The resize always wins. `restore`
also already carried the right guard for a reassigned plot:
`if PlotService.PlotOf(player) ~= plot then return end`.

**No double-assign is structural**: `drainQueue` does `table.remove(waiting, 1)` BEFORE
`assign`, and `assign` sets `ownerOf[id]` synchronously, so the next `firstFreePlotId()`
cannot return the same id.

**Observation, not a defect:** a handover currently performs TWO rebuilds in the same frame
-- down to Level 1 on release, then up to the new owner's level on assignment. The end state
is correct and no client renders the intermediate, but the Level 1 build is wasted work when
somebody is queued. Left alone deliberately; changing the release/drain ordering would be a
redesign.

### What could NOT be executed here

`Instance.new("Player")` is blocked and this Studio setup runs one client, so **filling six
plots and queueing two players was not run.** The queue assertions -- first waiting player
receives the plot, no second queued player receives the same one -- are established by the
code reading above (append-ordered `waiting`, dequeue-before-assign, yield-free `assign`)
and by section 6 of `PlotSpec`, which drives the real `MapService.ResizePlot` through the
exact release-then-assign geometry sequence on a real Model. The queue ORDERING itself is
read, not run. Worth one real two-client test before ship.


## A SECOND BED, AND CREATURES THAT WALK THE WHOLE PLOT — 2026-09-02

Built on the uncommitted plot-upgrade work; the ladder, capacities and prices are
untouched. Uncommitted. The Emberroot roots and heads were not opened.

### THE WING

From Level 3 a plot grows a rear flare on its +X local side, holding a second bed.
**It adds no capacity** — 10 / 15 / 20 whether a plot has one bed or two. It is floor
space for twenty things that walk, which a single 34-stud strip does not have.

    level  main bed     side bed    plot depth  wing
      1     34 x 23.2   --            35.2       --
      2     34 x 35.4   --            47.4       --
      3     34 x 47.6   30 x 23.2     59.6       40 wide
      4     34 x 59.8   30 x 35.4     71.8       40 wide
      5     34 x 84.2   30 x 47.6     96.2       40 wide

**REAR-ANCHORED, which is what makes it fit.** Plots sit on a ring, so the chord between
neighbouring centre lines is `0.84 * r` — 84 studs at the gate, 165 at the back of a Level 5
plot. The wing starts where that room exists. The front edge never widens, so nothing
changes at the ring radius where the plots are tightest.

**IT IS WIDE RATHER THAN LONG, AND THE TREADMILL IS WHY.** Every plot's mill sits at local
X 24.6–43.8, Z −43.4 to −19 — the same side as the wing, in the front half. The first build
reached forward past it and fenced it in at 0.93 studs. So the wing starts BEHIND the mill
(`SideBed.WingFrontZ = -15`) and takes its area back across instead. That cap is what makes
the row counts 2/3/4 rather than the 2/4/7 a plot with no mill beside it could carry.

Measured with all six plots at Level 5:

    neighbour clearance (worst of 15 pairs)   37.56 studs, no overlap
    treadmill clearance   L1/L2 (no wing)      0.15 / 0.16 studs   <- pre-existing
                          L3/L4 (wing)         0.71
                          L5    (wing)         1.30
    gate radius                               100.00, unchanged
    max reach from the hub                    207.4 vs FieldBack 265
    usable ground                             4,618 -> 7,142 sq studs  (+55%)
    soil area                                 2,863 -> 4,291 sq studs  (+50%)

**Every level with a wing has BETTER treadmill clearance than the wingless baseline.** The
0.15-stud gap at Level 1 is the plot's own fence and predates this work.

`dressPlot` builds both beds through ONE `buildBed(name, centreX, centreZ, width, rows)`, so
there is no second copy of the rustic style. The main bed is that function at centre (0,0)
with its original width, so its size and CFrame are unchanged — which matters, because every
saved plant is an offset in that part's space.

### TWO BEDS, ONE FRAME, NO SAVE CHANGE

**The save format did not change and there is no migration.** `entry.offset` has always been
an X/Z offset in the MAIN bed's object space, and the main bed is centred on the plot and
shares its rotation — so that frame is the PLOT's frame in all but name. A creature on the
side bed or on the grass between the two is stored exactly as before; the offset simply
stopped being confined to the rectangle it is measured against. `ProfileSchema` and
`Save.CurrentVersion` are untouched.

  * `bedsOf(plot)` finds every surface by the **Planter tag**, main first.
  * `pickBed(plot, worldPos)` chooses the nearest planting surface, on the SERVER. **The
    client never names a bed** — a bed id crossing the wire would be forgeable.
  * `clampToPlotRegion` is the one clamp that understands the whole plot: the main rectangle
    plus the wing, sharing an edge so the union is connected, inset from the fence and kept
    out of the gateway.
  * `clampToSoil` now exists only inside `pickBed`.

### WANDERING

**Pods do not move.** Only grown creatures walk, and they walk the whole plot.

The server owns every decision and publishes four attributes per leg — `WanderFrom`,
`WanderTo`, `WanderT0`, `WanderT1`, in world space. Clients interpolate them against
`Workspace:GetServerTimeNow()`. **No CFrame crosses the wire and nothing is chosen locally**,
which is what makes a creature appear in the same place on every screen. The version this
replaced rolled dice on each client inside a 6-stud disc around the PLANTED point — cheap,
disagreed between viewers, and the reason a bed planted in one corner stayed a pile.

  * Pacing lives in `SeedData.WanderReach/Speed/Pause`, and **the server is the only caller**.
    The client derives the speed it draws from the leg it was handed (distance / duration),
    so the gait follows the motion instead of assuming it — no second copy of the curves.
  * Destinations: several candidates a leg's reach away, each clamped into the region, scored
    on distance from other plants' positions AND their reserved destinations. The separation
    target is bounded (14 studs) on purpose — scoring against real Colossal sizes would make
    every candidate illegal at once.
  * `entry.offset` is committed **at arrival**, then persisted. A save mid-leg is at most one
    leg behind, and there is no profile write per frame.

Measured live. A garden squeezed into a Level 1 bed and then given a Level 5 plot:

    clustered:              mean pair 22.0   closest 4.3    bounding area   814
    after 63s of wandering: mean pair 32.9   closest 13.8   bounding area 1,780
    out-of-bounds samples at any point: 0

Cost: 0.06 legs per creature per second. **A full plot of 20 is 5 attribute writes/sec; six
full plots (120 creatures) is 30 writes/sec.** Client PivotTo is PlantSway's existing 20 Hz
round robin, one per plant per visit, unchanged.

### THE BUG THIS PASS FOUND, AND WHAT FIXED IT

A published leg is a pair of WORLD points, and a plot rebuild moves the ground under them.
The first version cleared the attributes on resize, which tells a client to STOP but not
where the server now thinks the creature is. On a shrink the server pulled creatures that no
longer fitted back onto the smaller plot while every client carried on drawing them at the
old spot until the next leg arrived half a second later — **72 studs of client-side
disagreement across one upgrade, 17.3 studs of server-side movement in the rebuild frame.**

Fixed by PARKING instead of clearing: `CaptureWorld` first commits each creature's
interpolated position (`currentOffset`, using the same smoothstep the client draws with),
and `RebaseTo` publishes a degenerate leg at the rebased point. Record and picture move in
the same frame. After:

    walking baseline over 0.3s      0.41 studs
    L2 -> L3                        2.38 studs
    L3 -> L5                        1.24 studs
    L5 -> L2                        3.29 studs   (the genuine relocation of creatures
                                                  that no longer fit)

### Verified live

Pods carry no leg and moved 0.0115 studs in 12s (the existing idle sway). Placement on the
side bed landed 0.7 studs from the aim point; bed routing is 4/4 on aimed points and sends a
grass click to the nearer bed. A forged click on another plot's main OR side bed created
nothing anywhere — the server resolves the plot from the sender. Pickup removes the plant, so
movement necessarily stops. Release: L5 -> L1, side bed gone, one Planter tag, wing attributes
zeroed, Plants and Runtime empty, **0 leftover wander instances**, Model reusable. Rejoin
restored all six inside the plot region.

`tools/tests/PlotSpec.luau` — **65 assertions, all passing**, including the unchanged
capacities and prices.

### Preview, awaiting a look

Edit holds Plot_01 at Level 5, Plot_02 at Level 3 and Plot_03 at Level 2, camera parked over
the Level 5 plot. **No test plants**: Edit has no path to a saved garden without a profile,
and building creatures there would be the second preview stage the brief rules out. **The
motion has not been judged by eye — only measured.**

### Still open

The real two-client queue test remains outstanding from the previous pass. Main-bed placement
was not re-run end to end through the carry flow after the bed change (the scripted
pod-pickup path is flaky); routing is verified numerically and six existing plants sit on the
main bed.

## THE STARBLOOM LIMB PASS — 2026-09-03

**Four of the five Starbloom species had their legs rebuilt.** Uncommitted, and
stacked on the uncommitted plot ladder / side-bed / wandering work, none of which
this touches. **Not approved — built, measured, and left in the showroom for a
look.**

Files: `StarbloomForms.luau`, `StarbloomMockupRunner.luau`, and a new
`tools/tests/StarbloomLimbSpec.luau`. Nothing else. Novaorb — the only one with
its feet already on its legs — was rebuilt at Tiny, Mega and Colossal and
compared part by part against the pre-change builder: **identical, property for
property.**

**IT WAS ONE FAULT, FOUR TIMES.** Every species except Novaorb positioned its
feet from the PLANT'S ORIGIN rather than from the leg that is supposed to end in
them — `baseCF * CFrame.new(leg.x * 1.05, 0.25, leg.z + 0.2)` and variations of
it. The leg was built down one frame and the foot was placed in another, so the
two only ever met by coincidence, and none of them did. It was found on
Cosmospire, and then found three more times by going and looking.

### WHAT WAS ACTUALLY WRONG, IN STUDS

    COSMOSPIRE
      knee (femur box to tibia box)      +0.0104 studs OPEN   -> 0.52 at Colossal
      claw to its own shank's tip         1.538 front / 1.660 rear
      nearest claw to a front shank tip   0.383 -- the REAR leg's
      lowest corner of the whole model   -0.2002  (the shanks stood IN the floor)
      tibia's nearest-hip margin          1.03:1 -- against the OPPOSITE hip

    ASTRALHORN
      column's lowest corner to its hoof +0.2029 front / +0.1950 rear, all four
                                         -> 10.1 and 9.8 studs of air at Colossal
      column bottom vs hoof centre        0.38 studs apart in Z, the wrong way

    VOIDPETAL
      haunch's lowest corner to its pad  +0.2777 front / +0.2527 rear, all four
                                         -> 12.6 to 13.9 studs of air at Colossal
      the haunch's own lean               AWAY from the paw it ends in

    SUPERNOVUS
      thigh's lowest corner to its pad   +0.0376 rear / +0.1493 front / +0.3474 mid
                                         -> 1.9 to 17.4 studs of air at Colossal
      the six pads in the rig             NOT PRESENT

**The Cosmospire claw was stuck to the SIDE of the shank**, forward of the hip,
while the shank reached backward past it -- which is why the 1.5-stud separation
does not show up as a box gap. And at 1.03:1 the shank was one part in thirty
from joining the opposite hip, where PlantSway would have swung it in antiphase
with its own femur.

**Voidpetal's front haunches pitch fifteen degrees BACKWARD**, so the bottom of
each one travels away from the camera as it descends -- while its pad sat 0.3
studs FORWARD of the hip. Nothing about the leg pointed at the foot it ended in.

**Supernovus's feet were never animated at all.** PlantSway matches limb parts
against an anatomy vocabulary -- Thigh, Femur, Haunch, Shin, Tibia, Knee, Hock,
Foot, Hoof, Paw, Toe, Stilt, Pillar -- and `TitanClaw` contains none of those
words. PlantSway's own comment records the consequence without naming it as a
bug: "a single-part leg (Supernovus is thighs and nothing else)". Six thighs
stepped; six pads stayed where they were.

### WHAT THEY ARE NOW

**Cosmospire: hip -> femur -> knee -> shank -> claw, four parts per leg.** Every
joint is a CFrame and every mass is built from the joint above it by one `shaft`
helper that runs each segment PAST both of its own joints, so the seam is inside
the next mass at any pose. The knuckle turns half the bend itself and is wider
than either shaft. The shank now counter-bends BACK toward vertical instead of
continuing the femur's lean, which is what puts each foot under its own hip.

**Astralhorn: column -> hoof -> toe, three parts per leg.** Three and not four,
because a PILLAR leg is meant to have no visible bend -- that is what the word
means, and it is the difference between this and the mantis. So the parts went on
the foot, where the read was actually missing. The column is extended rather than
moved, and the hoof is deep (1.44) because the stance is authored: the foot goes
where the foot went, the column arrives off-centre in it, and a hoof only 1.0
deep would have left a third of the column's cut face hanging out of the back
with daylight under it. The ground the four feet cover is the same 3.70 studs it
always was.

**Voidpetal: haunch -> shin -> pad -> claw, four parts per leg.** The shin is
AIMED rather than angled: its direction is solved from the hock at the bottom of
the haunch and from where the paw actually stands, so the shaft is built along
the line between its own joints by construction. That also buys the pose for
free -- the front haunch leans back and its shin reaches forward, the rear haunch
leans forward and its shin tucks back under the body, which is the reaching
foreleg and folded hind leg of a cat, and neither angle had to be picked.

One claw per pad rather than three. The pad is 0.68 studs across on a creature
5.6 tall; a second and third toe are two more dark pieces inside the same
outline, which the art bible calls static rather than detail. It also keeps this
species inside the band at 39 instead of pushing it to 47.

**Supernovus: thigh -> ankle -> sole -> heel -> two unequal toes, six per leg.**
The thigh is EXTENDED, not moved -- its top is exactly where it was, and its
lower end grows by however much the geometry says it takes to bury its cut face
inside the sole, computed per leg from the box's own rotated corner reach because
the six sit at three pitches and two rolls.

**The feet stand slightly out of line with the hips on purpose.** Front feet
0.45 ahead, rear feet 0.55 behind. It reads as a planted hexapod, and it is also
what keeps each foot in its own rig cluster: with 1.7 studs between neighbouring
hips, a foot placed straight under its own thigh put its HEEL 1.07:1 toward the
NEXT leg -- which walks in antiphase.

### MEASURED, AT TINY / MEGA / TITAN / COLOSSAL

`tools/tests/StarbloomLimbSpec.luau` -- **71 assertions, all passing.** It reads
PlantSway's vocabulary and swing angle out of PlantSway's own Source, mirrors its
clustering through `StarbloomMockupRunner.RigOf`, and measures joints with a full
fifteen-axis separating-axis test, which for two boxes is the exact distance.

    worst gap at any joint, any pose      -0.153 studs  (i.e. still 0.153 of OVERLAP)
    deepest overlap                       -0.886 studs  (supernovus hip, Tiny)
    lowest foot corner, every tier         0.000000
    nothing below the base plane           0.000000
    nearest-hip margin, worst part         1.31:1 cosmospire, 2.93:1 voidpetal,
                                           1.68:1 astralhorn, 1.54:1 supernovus
    leg clusters                           4, 4, 4 and 6, two alternating phases
                                           each

Rest, both gait extremes and a turn. **A turn cannot open a joint and a stride
cannot either** -- PlantSway rotates a whole leg rigidly about one hip frame, so
within a cluster the geometry is pose-invariant. What a stride CAN do is tear a
part off a leg it was never on, which is the 1.07:1 case above and what the
margin assertion exists to catch.

### THE PART COUNT, WHICH IS THE COST

    cosmospire   33 -> 37     legs 12 -> 16
    voidpetal    31 -> 39     legs  8 -> 16
    astralhorn   33 -> 37     legs  8 -> 12
    supernovus   46 -> 70     legs 12 -> 36

**Supernovus at 70 is the number worth arguing about.** Six legs multiply
everything: the ankle, sole, heel and two toes each foot needs are thirty parts
before the thighs are counted. It also quadruples what PlantSway writes while the
creature walks -- 36 leg CFrames per plant per 20 Hz slice against 6 before, plus
its 4 leaves. A twenty-plant Supernovus plot is 800 writes a slice.

Dropping the separate heel would bring it to 64 and lose the rear counterweight.
Nothing else in the foot can come out without losing something the brief asked
for by name.

### SILHOUETTE, AGAINST THE AUTHORED SHAPE

    cosmospire   3.20 -> 3.24 wide   7.85 -> 7.65 tall   4.74 -> 4.74 deep
    voidpetal    4.21 -> 4.21 wide   4.67 -> 4.67 tall   5.52 -> 5.52 deep
    astralhorn   4.15 -> 4.16 wide   7.31 -> 7.31 tall   4.76 -> 4.87 deep
    supernovus   7.06 -> 7.06 wide   9.20 -> 9.20 tall   8.20 -> 8.26 deep

**Cosmospire's height did not drop; its floor did.** The old model measured 7.85
because 0.20 of it was below the base plane. Top edge unchanged at 7.65.

The first cut ran 3.85 wide -- toe-out is paid for in width, roughly 0.8 of a
foot's length times the sine of its turn, twice over -- and was pulled back.

### THE SHOWROOM

`StarbloomMockupRunner` keeps its five plinths and gains three things:

  * `Build({1, 7})` lays extra tiers out as bare rows behind the dressed one.
  * `Pose(0)`, `Pose(0.25)`, `Pose(-0.25)` freeze every plant at rest or at
    either gait extreme, using PlantSway's own transform.
  * `Simulate(true)` now drives the LEGS as well as the body, on the same clock
    the bob runs on. It used to slide each plant round a circle with its legs
    dragged along, which is the half of the animation an anatomy review needs.
  * The gallery folder is `Archivable = false`, so it cannot reach the .rbxl.
    Verified: `gallery:Clone()` returns nil.

`RigOf` is exported so the spec measures against the SAME mirror the preview
poses with. Two copies would drift the first time either was tuned.

**Left parked on row 1 only, at Tiny.** `Build({1, 7})` works and was used for
the Colossal measurements, but a 460-stud creature 380 studs behind an 8-stud one
fills the sky and makes the showroom unreadable -- that is the size curve this
file already lists as an open defect, seen from the ground.

### THREE THINGS THE MEASUREMENTS CAUGHT THAT AN EYE WOULD NOT HAVE

**A raked shaft reaches much further below its own end than half its thickness.**
Voidpetal's rear-right shin is raked thirty-seven degrees, so its DEPTH
half-extent projects 0.56 onto world Y -- its bottom corner finished 0.0226 studs
under the base plane, which is 1.13 studs at Colossal: a leg through the floor of
somebody's plot. Raising the ankle 0.04 and trimming the overrun 0.05 clears it by
0.07 and still buries the shin 0.17 under the pad.

**A foot big enough to fix the read can become the widest thing on the creature.**
Astralhorn's enlarged toes came out 2.25 studs from the centreline against its
widest antler leaf's 2.08, so the FEET quietly became its silhouette and it
gained 8% across. Pulling the hooves 12% inboard of the columns put them back
inside the crown; the width is now 4.16 against an authored 4.15.

**The spec failed a leg that was correct.** Its "only upper-leg pieces are
anchors" check knew `Thigh` and `Femur` but not `Haunch`, which is the third word
PlantSway's own `hasUpper` test accepts -- so it failed Voidpetal's four haunches
for being haunches. Fixed in the spec, not in the art.

### Still open here

  * **The art is not approved.** Measured, screenshotted from front, side, both
    three-quarters and above, and left standing. Not judged.
  * **PlantSway's hip line caps how high Cosmospire's knee can sit.** Anything in
    the upper 45% of a leg's height becomes a hip anchor, so the knee is forced
    to y 1.06 of a 2.30-stud leg. Raising it past 1.19 merges the knee into the
    femur's hip, which moves the hip's centre far enough to collapse two rank
    bands into one -- the trot becomes a pace. The low knee is a rig constraint,
    not a drawing choice.
  * **EmberrootForms names its cinderpaw's `Sole` and `Claw` outside the leg
    vocabulary**, so those two parts per leg do not swing with it -- the same
    class of fault as Supernovus's pads. Not touched: that file is approved art
    and outside this pass.
  * **Voidpetal's claws are one value step off its pads** -- MidnightSlate on
    VoidBlack. They read close up and may not read at all across a plot. Making
    them lighter is a palette decision, not a geometry one.

## ASTRALMAW: THE CHASE, THE LIMBS, AND THE HIT — 2026-09-03

Uncommitted, stacked on the uncommitted plot / side-bed / wandering work, none
of which this touches. Five files: `GameConfig`, `AstralmawModel`, `NestService`,
`ParentAnim`, `ThrowFX`. **Every measurement below is from the real Astralmaw
`NestService` builds in Play, not from a preview.**

### THE LIMBS WERE NOT ANIMATING, AND IT WAS NEVER THE ANIMATION CODE

`ParentAnim` drops a parent from its table when the root's parts go away, which
is right — and it never asks for it back, which is not. With StreamingEnabled the
MODEL persists on the client as a two-child stub and keeps its tag, so
`GetInstanceRemovedSignal` never fires, `GetInstanceAdded` never fires again, and
the `DescendantAdded` retry `track` arms was disconnected the first time it
succeeded.

**So the first time a player walked out of range of a guardian and came back,
that guardian stopped animating for the rest of the session.** Measured from
spawn after one walk down the road:

    Parent_greenhollow   0 of  7 motors changed over 0.4s
    Parent_dustbowl      0 of  7
    Parent_tanglemire    0 of 15
    Parent_starbloom     0 of  7   <- and its LeftHip sat at -0.00 through a chase
    Parent_emberroot     3 of  7   <- the only one still alive

Emberroot survived only because it is far enough out that the whole MODEL
streams rather than just its parts, so the tag signal did fire. **Four of the
five guardians in this game have not been animating.** One deferred `track` on
stream-out fixes all five; nothing about their profiles changes.

### THE SEAMS HAD NO SOCKETS

Six of Astralmaw's seven Motor6Ds were built with `C1 = identity`, which puts the
pivot at the CENTRE of whatever part the seam drives. The rest pose looks right
and everything after it is wrong, in two opposite directions at once. Travel of
each part in the root's own frame over 2.5 seconds of running:

                      before   after
    LeftUpperLeg        1.17    2.91     6% -> 15% of a 19-stud creature
    LeftLowerLeg        2.39    5.30
    LeftToe2            3.74    6.68    19% -> 35%
    LeftUpperArm        1.77    4.46
    LeftForearm         8.24    9.05
    LeftClaw2          13.83   12.75    72% of the creature's own height
    LeftPauldronTop     5.97    5.52    now the torso's, not the arm's

A thigh turning about its own middle barely goes anywhere — the top swings back
as far as the bottom swings forward. The arm has the opposite problem: the
forearm and four claws hang eight studs BELOW the point it turns about, so the
same angle threw the claws three quarters of the creature's height. Legs that do
not read as walking under arms that read as thrashing.

**The geometry did not change.** `socketMotor` derives both joint frames from one
world socket, so the rest pose is preserved by construction — and proved:
building the old and new models side by side, 83 parts each, **worst position
difference 0.000137 studs and worst orientation 0.066 degrees**, and not one part
differing in size, colour, material, class, transparency or masslessness.
HipHeight, collider count, SleepBodyPose and all four effects identical.

The two top pauldrons moved from the arm seam to the body. They are shoulder
plates that were flying off the shoulder.

### THE STRIDE WAS A VIBRATION

`SWING_PER_STUD = 0.40` is one full cycle every 15.7 studs, tuned against
WalkSpeed 19 where it gives a comfortable 1.2 strides a second. Astralmaw runs at
a hundred and twenty. Measured before: **4.2 cycles a second, one stride every
0.24s, 13.6 frames per cycle at 57 fps and seven on a phone.**

Astralmaw now lengthens its stride instead of quickening it — `12 + 0.30 * speed`
studs per cycle, capped at 48 — which is what real animals do and the only model
that keeps a foot down at every speed. Measured after: **2.63 cycles a second,
23 frames per cycle.** Hips alternate at a clean 180 degrees (the shared gait's
deliberate 140-degree limp belongs to Greenhollow's brute), shoulders
counter-swing against them at 46 degrees to the hips' 34, trailing by 0.55 rad.

### THE CHASE, AND THE CEILING THAT CAME BACK DOWN

Opening 78, ramping squared to 96 over 3.4 seconds, plus rage and plus the
under-speed shortfall exactly as before. Walking home is 64 and the gait drops to
43% of the chase's swing. Measured live with rage cleared -- and note that every
provoke does `rage += 1`, so even a FIRST theft carries +5:

    configured WalkSpeed  0 -> 63 -> 84 -> 85 -> 87 -> 90 -> 93 -> 98 -> 101
    measured studs/sec    0 -> 39 -> 84 -> 85 -> 87 -> 91 -> 93 -> 98 -> 101
    gap to a player fleeing at 81.5   28 -> 103 (peak) -> 77 -> 44 -> contact
    hip span   68.0 degrees      shoulder span  92.0 degrees

The measured displacement tracks the configured speed within a couple of per
cent, so nothing in the movement code is a bottleneck.

**IT WAS 118 AND THAT WAS TOO MUCH, WHICH ONLY LOOKING AT THE WHOLE LADDER
SHOWED.** Simulated at 50 Hz -- 1.2s head start, contact at GrabStuds, the red
line as the finish -- for a player who has exactly met each biome's bar and taken
the lightest pod there is, the fraction of the run home they cover before being
caught goes:

    greenhollow 11%   dustbowl 28%   tanglemire 29%   emberroot 34%

Eleven is the tutorial teaching you that you get caught. The rest is a gentle
rise: the road gets slightly more forgiving per raid as the walk back gets
longer, which is what stops distance from double-counting as difficulty.

    starbloom on flat 92 (before any of this)   38%   -- continued the line
    starbloom on 118 / ramp 2.6                 28%   -- EQUAL TO DUSTBOWL
    starbloom on 96 / ramp 3.4                  43%   -- back on the line

At 118 the last biome was the least survivable ATTEMPT on the road as well as
the longest walk home. At 96 it is the most survivable attempt, which is right:
you get further before it lands, and there is far more road left when it does.

The ramp is the part that was actually wrong before any of this and it stays --
what a player feels is the acceleration, not the ceiling. The slow opening is
also what makes this row generous: the gap peaks at 103 studs before the ramp
takes hold, which is more head start than a flat 92 ever gave.

**A capped player still outruns it.** WalkSpeed caps at 150 and a trained player
measured 146.6. But a chase only ever happens against an ENCUMBERED player --
`AggroOnTheftOnly` -- and the carry curve is brutal: x0.99 for a Tiny pod, x0.51
for a Titan, x0.30 for a Colossal. A maxed player walks away with anything light
and cannot outrun anything in the game while carrying the thing that is actually
worth taking. That is the design, not a gap in it.

### THE HIT, AND THE WIND-UP THAT PLAYING IT KILLED

The first cut gave the strike 0.32 seconds of anticipation before the launch, and
measured 0.327-0.359 across six hits. **Played, it read as lag.** Contact
happened, nothing happened, and a third of a second later the victim went. The
chase is the anticipation; a pause at the end of one is a pause however good the
pose in it is. It also handed the player a dodge — 150 walk speed covers 48 studs
during the coil, past the range re-check — so charging the monster beat it.

**`WindupSeconds` is 0. Contact is the hit, measured at 0.000 seconds.** The arm
still swings: `astralStrike` carries a `coil` scalar that drops the draw-back to
22% when there is no wind-up, so the sweep opens 18 degrees back instead of 84
and there is no pop on the impact frame. The block in `NestService` that would
run a wind-up is left standing, unused, because its four re-checks are the right
ones for any wind-up somebody adds later.

`ParentState` is published as an attribute on the parent, once per change, by the
tick that owns the state machine. `Asleep` alone could not tell a chase from a
walk home.

### THE THROW, AND THE WALL

Two bugs made the launch un-tunable:

  * **The velocity was applied twice.** `ApplyImpulse` ADDS and the assignment
    SETS, and both the server and the client did both. Configured 235 and 141;
    measured **467.6 and 291.9**, exactly double, apex 237 studs.
  * **`ThrowFX` re-wrote the velocity every frame for 0.35 seconds**, which does
    not hold a throw, it cancels gravity for a third of a second.

Astralmaw now gets one write per part — a ragdolled R15 body is seventeen
separate assemblies, so it does have to be per part — and a guard that restores
the BALLISTIC velocity (`impulse - g*t`) only when the humanoid state machine
eats it. The four unprofiled parents send no hold value at all and keep the
tested 0.35-second path byte for byte.

**THE LIFT IS 0.55, NOT THE 0.45 EVERY OTHER BIOME USES, AND THAT IS A WALL.**
The Starbloom corridor is walled at x = +/-75 and those walls are 46 studs tall.
Clearing them needs `v^2/2g > 43`, which is 130 studs/second of vertical; 0.45 of
235 gives 103 and an apex of 27, half the wall. 0.55 of 300 gives 165 and an apex
of 69, and 1.7 seconds of air.

**AND IT THROWS YOU HOME.** The first cut had `away` dominating at 1.00 against
0.30 of road, and played it was backwards: the guardian aims sixty studs PAST you
while it chases -- ChaseOvershootStuds exists so it does not brake -- so by
contact it is very often level with you or in front, "away from the monster" is
"further down the corridor", and the hit fired people deeper into the biome they
were running out of. Now the road wins at 1.00 against 0.45, which `away` cannot
take past ninety degrees off it, so every hit goes up the corridor toward the
plots while `away` still picks which side of the road.

Four hits after the retune:

    position                hit lag   launch H/V     apex   flew   direction
    standing, mid-road       0.000  300.0 / 160.9    79.2   1060   HOMEWARD 1058
    running AWAY (+Z)        0.000  299.6 / 161.4    75.0   1090   HOMEWARD 1089
    running AT it (-Z)       0.000  300.0 / 164.3    44.5    127   HOMEWARD  127
    beside the LEFT wall     0.000  300.0 / 163.8    76.8    916   HOMEWARD  914  -> into the void

From the Starbloom nest at z = -1600 that lands people around z = -450 to -670,
which is two biomes closer to home, and a hit taken beside a wall still leaves
the corridor entirely: the last row ended at x = -132, y = -511, below the kill
plane. **Death and respawn were measured before the retune at 5.0-7.0 seconds to
die and 8.5-10.5 to be back**, at the normal spawn, on the existing kill plane at
y = -500. No new recovery code was needed.

Running straight at it no longer dodges -- it lands, and the victim's own -Z
momentum eats most of the throw, which is why that row only travels 127 studs.

The road direction is derived from the nest's own position toward the hub pad
rather than the hardcoded world +Z the shared throw uses, so it is still right
for a nest placed anywhere; there is an assertion and a warn if any mixture ever
resolves back through the parent. The four unprofiled parents keep the literal
`(0, 0, 0.5)` and the formula speed they shipped with.

### Verified

  * All seven Motor6Ds present; every part held by a motor or a weld, none loose,
    none anchored — so no frame rate can detach anything.
  * Full state cycle asleep -> waking -> chasing -> returning -> asleep, with the
    gait dropping from 68 degrees of hip to 29 on the way home and to zero asleep.
  * One impulse per attack; `nest.busy` still gates the whole grab, and the
    console shows exactly one launch line per hit.
  * Phase is seeded from the nest's own position (2.928 here, 5.728 sixty studs
    up-road), so two Astralmaws could never be in lockstep.
  * Greenhollow, Brambleback, Miremaw and Forgemaw: builders untouched, no
    profile, so no ramp, no wind-up, no return speed, the legacy velocity hold and
    the legacy throw direction. Emberroot measured at speed 206.2 / lift 0.45 and
    "held the launch velocity for 0.35s" during this pass.

### Still open

  * **THE FOOT STILL SLIDES.** At its most planted the foot is doing 35% of the
    body's speed and at its fastest 2.0x. That is what a leg with ONE joint can
    do: with no knee the foot travels a circular arc about the hip and can only
    match the ground instantaneously. Removing the last of it needs a `LeftKnee` /
    `RightKnee` seam, which is a change to the seven-name parent contract and was
    out of scope here.
  * **THE LIMP LASTS 3.3 TO 7.6 SECONDS NOW**, measured from the launch to the
    last frame of PlatformStand. That is a consequence of the distance: a
    thousand-stud throw is 1.7 seconds of air and then a long tumble, and the
    settle machinery waits for the body to stop. It is well past the 1.2-1.8
    seconds the brief asked for, and it is the number to cut if being helpless
    that long turns out to be worse than being thrown that far.
  * **Astralmaw does not breathe while asleep.** It has no entry in
    `SLEEP_BY_SPECIES`, so it falls back to `GREENHOLLOW_SLEEP`, whose breath is
    zero. Untouched deliberately: the brief locked the sleep pose.
  * **Nothing here has been played by a person.** Every number is instrumented.

## 2026-09-03 -- A REVIEW PASS OVER THE GUARDIAN WORK

A read-only review of `dfc0833` and `81f58cb`. Two real defects, one stale
comment, and one wrong first fix that is worth keeping written down.

### REGISTERING IS NOT ARRIVING

`ParentAnim.track` gates on the root and the `Neck` and then reads the other six
seams ONCE, and the retry disconnected the first time the entry existed. With
StreamingEnabled a rig lands in pieces, so a model whose Neck arrives before its
`LeftHip` registers with `leftLeg = nil` -- and because the entry now exists,
nothing looks again. That limb is frozen until the next stream cycle, silently.

Same shape as the stream-out bug fixed in `dfc0833` and as the PrimaryPart one
written up at the top of that file: a snapshot taken before the model finished
arriving. The retry now stays armed past registration.

### AND WAITING FOR ALL SEVEN SEAMS IS THE WRONG STOPPING CONDITION

The obvious fix -- keep looking until no seam is nil -- does not terminate, and
this is the part to remember. **Only Astralmaw, Forgemaw and the shared
ParentModel build the whole seven-seam contract.** `TanglemireForms` has no
`RootJoint`, `BramblebackModel` has three seams, `MiremawModel` has one and
drives the rest through `mireChannels`. Three of the five are never complete, so
that retry runs forever -- and it ran six full `GetDescendants()` walks per
descendant added, which is O(n^2) during the exact streaming storm it exists to
survive.

The seam is taken off the SIGNAL instead: `DescendantAdded` hands you the
Motor6D, so absorbing it is a name compare. It stops on whichever comes first,
the contract completing or a 10-second arrival window closing. Bounded for all
six builders -- three by completeness, three by the window.

### A WALL IS NOT THE STATE MACHINE

`ThrowFX`'s ballistic guard corrected on ANY deviation over 22%, every frame,
for the whole 0.30s. A collision looks exactly like interference to a magnitude
test, so a body thrown into a wall had the full launch speed written back into
it every frame -- which is how a part is pushed THROUGH geometry, and it puts
back the energy the collision just took out.

Reachable, not theoretical: a 300/165 launch is at 40.7 studs when the guard
ends and does not clear the 46-stud corridor wall until 0.353s, so anything
thrown near a wall meets it while the guard is live.

The two failures are opposites in the plane. Measured, the state machine eats
the VERTICAL and leaves the horizontal alone -- 234.7 and 6.7 out of 235 and
141. A wall takes the horizontal, because the horizontal is what drove the body
into it. So a lost horizontal with the vertical still on the arc releases the
guard outright, and gravity and the collision own the rest of the flight:

    MEASURED state-machine wipe (234.7/6.7 shape)  -> restore to arc
    full wipe to zero                              -> restore to arc
    wall, horizontal killed, vertical untouched    -> RELEASE
    wall, bounced back off it                      -> RELEASE
    clean frame already on the arc                 -> leave alone
    glancing scrape, 250 of 300 horizontal         -> leave alone

Both wipe shapes still get corrected, so the bug the guard exists for is
untouched, and the legacy hold path for the four unprofiled guardians is
byte-identical.

### THE CONFIG COMMENT DISAGREED WITH THE COMMIT THAT SET THE NUMBER

`GameConfig`'s ladder comment carried a simulation run WITHOUT the `rage += 1`
every theft carries; the commit and this file carry the run with it. Hence
11/28/29/34 here against 13/38/40/47 there -- rage makes the guardian faster, so
every figure comes down. Ordering and conclusion are identical in both runs, so
`96` / `3.4` does not move. The comment now matches, and says why a reader might
remember it reading high.

### NOT VERIFIED

Both fixes compile under `loadstring`, which is past what `rojo build` checks,
and the guard's discriminator was tested against the real profiled launch. But
**neither has been exercised in Play**: the fill path needs a real stream-out
and stream-in to confirm a late `LeftHip` actually lands, and the released guard
needs somebody thrown into the left wall to confirm the body now stops at it.

## 2026-09-03 -- GUARDIANS TAKE THE POD BACK (in a01c372)

Past Dustbowl, being caught no longer scatters the pod on the road: Miremaw,
Forgemaw and Astralmaw confiscate it and carry it home. Greenhollow and Dustbowl
are untouched and still drop it where you fell.

### THE SHAPE OF IT

One shared state transition, not three biome implementations. `Nest` gains a
`haul` record and the state machine gains `hauling`, which is `returning` that
cannot simply end -- every exit runs `depositHaul`.

    catch -> confiscateFrom -> nest.haul + weld + state "hauling"
          -> throwPlayer (unchanged)
          -> walkHome (shared with "returning")
          -> depositHaul -> slot in the ring it came off
                         -> else loose pod at that nest
                         -> else a loud warning
          -> sleep

`GameConfig.Parent.Confiscate` is keyed by BIOME and absent for the first two,
exactly the way `Guardians` is keyed by species and absent for four. It is a
SEPARATE table on purpose: adding Miremaw and Forgemaw to `Guardians` to give
them a carry point would have handed them a chase ramp, a return speed and a new
throw as a side effect. `Guardians` still has one entry.

**The dependency could not point the way the work does.** CarryService is
Priority 45 and requires NestService at 40, but the catch happens in NestService's
tick and the pod lives in CarryService. So CarryService hands over two functions
at Start -- `NestService.SetCarryBridge{Confiscate, SpawnLoose}` -- and if it
never starts, nothing is ever confiscated and every catch is the old one.

**Ordering is the feature.** The throw sets PlatformStand and CarryService turns
that into a Drop; confiscating BEFORE the throw leaves that watcher nothing to
drop. The other order produces a loose pod AND a hauled one out of one pod.

**One pod, once.** `CarryService.Confiscate` does not yield, so the read and the
clear of a player's slot happen in one resumption: two guardians reaching the
same person in the same frame cannot both come away holding something.

### WHERE THE POD SITS IS DERIVED, AND HAD TO BE

A pod is 1.66 studs across at Tiny and 9.04 at the top of the curve, on guardians
15 to 19 studs tall. Three hand-tuned offsets were written first and measured
against the live rigs:

    astralmaw  buried 2.62 studs inside its own ChestNebula
    forgemaw   hung 8.55 studs BELOW the ground it was walking on

Clearing the front of the whole bounding body was tried next and is too blunt --
Forgemaw's head reaches 8.47 studs forward, so its pod ended up 13.4 out, five
past the nose and ten from the fist it was welded to. What ships starts AT the
limb and pushes forward only as far as it takes to stop overlapping anything,
with the centre clamped above the lowest point of the body. Measured after:

    astralmaw   0.40 clear of UpperTooth3   8.89 above the feet   3 passes
    forgemaw    0.40 clear of CheekR        0.40 above the feet   6 passes
    miremaw     0.40 clear of RightHand     0.40 above the feet   4 passes

The pod is parented to the NEST FOLDER and welded across, not parented into the
guardian. That is not tidiness: `mireChannels` name-scans every descendant
BasePart of a Miremaw into one table and keeps the last of each name, so a pod
inside the model could be re-scanned on a stream-in re-track and either be
resized by the sleep pose or REPLACE a real part in the channel.

### MEASURED IN PLAY, all three guardians

    miremaw   x3   took, walked home, returned it to its own ring
    forgemaw  x2   same, 7 of 7 motors animating throughout the walk
    astralmaw x1   same, pod 3.95 studs off the jaw, 44 of 45 samples "hauling"

    caught empty-handed in a profiled biome   Hauling never set, chasing->returning
    greenhollow                               pod dropped loose on the road, no haul
    guardian DESTROYED mid-haul               pod recovered into the ring, 0 stranded
    streamed out 1400 studs and back          still animating, 7 motors

The legacy throw still logs "held the launch velocity for 0.35s" for the
unprofiled four and Astralmaw still logs "one impulse", so the two ThrowFX paths
are still separated.

### ONE BUG THIS PASS MADE AND FIXED

The state was assigned after `throwPlayer`, which YIELDS for seconds, and the
tick publishes `ParentState` before it checks `busy` -- so Forgemaw read
`chasing` for 5.5 seconds while already holding a pod. Now assigned at the
confiscation, which is safe precisely because `busy` keeps movement out.

### AND ONE CORRECTION TO THE COMMIT BEFORE IT

`736e6c7` says TanglemireForms has no RootJoint, Brambleback has three seams and
Miremaw has one. **That is wrong** -- it was grepped per file, and these rigs are
composed across several. Measured on the live guardians:

    greenhollow 7   dustbowl 7   emberroot 7   starbloom 7   tanglemire 15

All five carry the whole seven-seam contract. The fill fix is still right and
still bounded; only its justification was wrong, and the comment in
ParentAnim.client.luau has been corrected to say so.

### THE PLAYTEST FOUND A POD SHREDDER, AND IT WAS OLDER THAN THIS PASS

Reported after the first real session: *"once i steal the pods couldnt be taken
and floating, it seems like im carrying an invisible pod, the pods despawned
too"*, with

    [Seed/CarryService] could not attach emberquill:
        CarryService:507: attempt to index nil with 'CFrame'

Four symptoms, one missing line. `TryTake` guarded the Humanoid, the Head and the
range, and never the ROOT -- then built the carried pod at `root.CFrame` below
the point of no return. A nil root threw INSIDE the pcall, by which time
`NestService.TakePod` had already destroyed the pod and emptied the slot. The
failure handler then did exactly what it is written to do: put the species back
on the floor a stud in the air, as a LOOSE pod, which despawns in 45 seconds.

    pod destroyed from the ring        -> "the pods despawned"
    nothing arrives in your hands      -> "carrying an invisible pod"
    respawned a stud up, untakeable    -> "couldn't be taken and floating"
    every later attempt does it again  -> the whole nest, one press at a time

**A LIVING CHARACTER REALLY CAN HAVE NO ROOT.** A ragdolled R15 body is seventeen
separate assemblies, so a thrown root travels on its own -- ThrowFX has measured
it 780 studs from its own torso -- and `FallenPartsDestroyHeight` is -500. The
root crosses the plane alone and is destroyed while the body lands on the road.
Read off a live character in Play, before anything was touched:

    HRP = false    Head = true    Humanoid.Health = 100

All three existing guards pass in that state. `throwPlayer`'s wait loop already
broke on `not root.Parent`, so the case was known about and nothing acted on it.

Two fixes. `TryTake` now refuses with `NO_ROOT` above the line where the world
changes -- refusing rather than falling back to the Head, because a fallback
hands a pod to a body that cannot carry it. And `throwPlayer` respawns a body
that comes out of a throw alive and rootless, with `LoadCharacter` rather than
`Health = 0`: they have just been thrown across the biome and lost the pod, and a
death on top would be a second punishment for the engine's bookkeeping.

Verified in Play against a deliberately rootless body: three take attempts,
`NO_ROOT` refused each time (the third suppressed by the existing 3-second
rate limit), ring 3 -> 3, nothing carried, zero loose pods created. The recovery
condition evaluates true on a real broken body and `LoadCharacter` returns a
working one immediately. A normal Forgemaw haul cycle still runs end to end after
the fix.

**This predates the confiscation pass** -- the guard has never existed -- but the
pass is what made it easy to hit, because it puts players through the throw far
more often and Astralmaw's is the one that clears the corridor walls.

### SECOND PLAYTEST: A FREE POD, AND A THROW STILL GOING BACKWARDS

*"theres a rare chance when i ragdoll on opposite direction, as the guardian gets
back while carrying the pod, i took one again and it doesnt chase me this time"*

Two separate faults in one sentence.

**THE FREE POD WAS A DESIGN CALL, AND IT WAS THE WRONG ONE.** `provoke` refused
to retarget a guardian mid-haul, on the reasoning that dropping a haul to chase a
second thief is how one pod becomes zero. The reasoning was sound and the
behaviour was not: the walk home is ten to fifteen seconds during which the
guardian CANNOT respond, so steal, get caught, then rob the ring while it trudges
away was a free pod every single time -- precisely the safe farm `rage` exists to
prevent, and written up two functions above the code that allowed it.

The haul never needed protecting from the chase, because a haul is not a state,
it is a field. It survives a chase the way it survives anything else. What was
missing was that all four exits from `chasing` assigned `"returning"` directly;
they now go through `goHome`, which returns to `"hauling"` whenever there is
still something to carry and restarts the haul clock so a chase does not eat the
ninety seconds meant for the walk.

A guardian that catches you while already holding a pod cannot take a second one
-- `confiscateFrom` sees its hands are full -- so you keep yours until the throw
knocks it onto the road, exactly as Greenhollow's would.

**AND THE THROW WAS STILL AWAY-DOMINANT FOR EVERYONE BUT ASTRALMAW.** The legacy
weighting is away 0.70 against road 0.50, and away wins. Fine while the guardian
is behind you; wrong the moment it is not, and `ChaseOvershootStuds` aims sixty
studs PAST you, so it regularly ends up level or in front. Then the sum is -0.20
of the road and you are fired deeper into the biome. Measured on Forgemaw during
this session:

    dir (0.25, 0, -0.97)  ->  landed z -1623, y -410  ->  past Starbloom, void, dead

Only Astralmaw was ever fixed, when the same complaint was made about Starbloom.
The other two confiscators now carry `AwayWeight = 0.45, RoadWeight = 1.00` in
their `Confiscate` profile, and `throwPlayer` asks the species profile first and
the biome profile second. **This changes Miremaw's and Forgemaw's throw
direction** -- deliberately, and it is the change the report asks for.
Greenhollow and Dustbowl have no entry and keep 0.70 / 0.50 and the hardcoded +Z.

The `dir:Dot(awayDir) <= 0` fallback was also wrong and is fixed: it dropped to
`awayDir` alone, which in that exact geometry is the way the road weighting
exists to avoid. It now keeps the road and uses only the SIDEWAYS part of away,
so you go home past the guardian rather than back over its shoulder.

Verified in Play, Forgemaw, one continuous run:

    first theft, fled 600      confiscated, hauled
    upright again after 4.7s   guardian still hauling
    second theft MID-HAUL      CHASED: true, kept the pod while chasing: true
    no second confiscation     hands full, so the pod dropped on the road
    haul finished              "returned a 4 tier cinderpaw ... (arrived)"
    every throw direction      +Z homeward: (-0.54,0,0.84) (-0.02,0,1.00) (-0.54,0,0.84)

**AND THE ROOTLESS RECOVERY FIRED FOR REAL** in the same run, which was the open
item from the previous fix: `nicnicniccoal lost its HumanoidRootPart to the
throw; respawning.` The race against the kill plane is winnable after all -- it
just needed enough throws.

One consequence worth watching rather than changing: a reliable homeward throw
from Emberroot covers about 1,150 studs, which is most of the walk back. The
distance is not new -- the speed did not change, only the direction did -- but it
does mean being caught now saves you the walk it used to scatter you across. You
lost the pod, so there is nothing to carry home; if that reads as a reward rather
than a punishment, `ThrowSpeed` is the number, not the weights.

### A SECOND THIEF DURING THE THROW WAS COUNTED AND THEN THROWN AWAY

Asked rather than reported: *"what if a player take the pod and guardian is
chasing then another player will take the pod, what could happen?"* Tracing it
found one intended behaviour and one hole.

**THE INTENDED PART.** `provoke` re-targets unconditionally, so the guardian
drops the first thief and turns on the second in the same tick. The first walks
away with the pod untouched -- even stood on top of the guardian, because only
`nest.target` is measured against `GrabStuds`. That is deliberate and the comment
has always said so, but it is worth naming what it makes possible: **pulling
aggro off a partner is a real co-op tactic.** Two players can alternate stealing
to free each other. The tax is `rage`, which is per NEST and not per player, so
the second thief inherits the first one's anger -- and `chaseSince` is not reset
on a mid-chase re-target, so they also inherit the accumulated ramp and meet a
guardian already at or near `TopSpeed` instead of `OpeningSpeed`. Four thefts cap
it at +20 WalkSpeed and it only fades after 45 seconds asleep. Left alone; the
trick costs more every time it is used, which is the shape the tax should have.

**THE HOLE.** `busy` keeps the TICK out of a nest for the five-odd seconds of a
throw. It does not keep `provoke` out -- `TakePod` never looks at it -- so a
second thief inside that window did everything they normally do: stacked rage,
set the state to chasing, pointed `target` at themselves, wrote the new speed.
Then the catch's `task.spawn` ended with

    goHome(nest)
    nest.target = nil

unconditionally, and threw all of it away. The guardian walked home with the
first player's pod, past somebody who had just emptied a slot in front of it.

This is the SAME fault `provoke` was fixed for last pass, narrowed from the whole
walk back to the throw window -- rarer, and identical from the road, which is
exactly why it survived that fix. The release is now conditional on the nest
still being pointed at the person who was just thrown.

Two smaller things found in the same trace and fixed with it:

  * `lastTargetAt` was never cleared when `provoke` re-targeted -- only when the
    tick let a target go. The dropped player's sweep sample sat there until
    something else cleared it, and the next nest to want them would sweep a
    segment from wherever they were standing when the first one lost interest.
    `MAX_TICK_TRAVEL` discards the worst of it; it should not have to. Cleared in
    `provoke` and at the end of a catch, which meant moving the declaration up
    beside `nests` -- it is read eight hundred lines before where it was
    declared. Its old comment also claimed a player can only be chased by one
    parent at a time. Rob two biomes and that is not true.
  * The `hauling` branch still carried the pre-fix comment claiming `provoke`
    refuses to retarget a hauler. It has not refused since the last pass.

Verified in Play: one full Forgemaw cycle after the change -- take, confiscate,
throw, haul, `"returned a 4 tier emberquill to Nest_emberroot_01 (arrived)"`,
ring back to 3 pods, no `HauledPod` left behind, nest asleep. The release guard
does not regress the ordinary catch, and the module compiled and ran, which
`rojo build` alone would not have told us.

### NOT VERIFIED

  * **The second-thief-during-the-throw case itself.** It needs a second Player
    object and a solo Play session has one. `DebugService.WakeNearest` reaches
    the real `NestService.Provoke`, but only ever with the caller, so it cannot
    make `nest.target ~= victim` happen. Joins the two-client list below.
  * The 90-second `HaulSeconds` timeout has not been reached in play. It runs the
    same `depositHaul` the destroyed-guardian test exercised.
  * Two guardians catching one player still needs two clients.
  * Two guardians catching one player needs two clients.
  * `SpeedSpec` errors on `GameConfig.overclockUnlockOrderFor` and `CycleSpec`
    fails "exactly one biome is live" -- BOTH PRE-EXISTING, both fail identically
    at `736e6c7`, and neither file is touched by this pass. PlotSpec 65/65 and
    StarbloomLimbSpec 71/71 pass.

## MARIGOLD SELLS WEAPONS -- 2026-09-04 (in a01c372)

Six knockback bats and one reusable trap, bought off a prompt on Marigold, in a
scrolling panel of horizontal product cards. Knockback only; nothing in the
feature reads or writes Health.

### THE REFERENCE IMAGE DID NOT ARRIVE

The brief says *"Use the attached image as the visual reference"* and describes
it in detail -- warm wooden frame, green patterned header with leaves, stacked
horizontal cards, cream names, green prices with a coin, a category badge. **No
image was attached and none is in the repo** (`shop ui 1-3.png` and
`shop index.png` are August, `art/` is unchanged). Every visual number in
`MarigoldShopUI.client.luau` is a reading of the WORDS.

That matters because of what this project already knows: the corner HUD and the
first shop panel were both SAMPLED off their references with a pixel reader, and
both were wrong at first impression and right only after measuring. The palette
here is at least borrowed rather than invented -- panel from `GameConfig.Panel`
(the warm dark soil), header green from `GameConfig.Rail.ShopFace` -- so it is
wrong in the same direction as the rest of the HUD. Assume it needs a sampling
pass against the picture.

The reference's stock counts, restocking and Restock button were explicitly NOT
copied, as the brief instructs. There is no quantity anywhere: these are
permanent unlocks, saved as a set.

### WHAT LANDED

```
Shared/WeaponData.luau        seven items: ids, prices, combat values, palettes
Shared/WeaponModel.luau       ONE builder -> the Tool, the shop viewport, the world trap
SeedGameServer/WeaponShopService.luau   the prompt, buying, equipping, the Tool
SeedGameServer/CombatService.luau       swings, hits, knockback, the Bramblejaw
StarterPlayerScripts/MarigoldShopUI.client.luau   the panel
StarterPlayerScripts/WeaponFX.client.luau         the swing and the impact
tools/tests/WeaponSpec.luau   68 assertions
```

Edited, and nothing else: `GameConfig` (three verbs, `Trapped`, the `Trap` tag),
`ProfileSchema` (`Weapons` set + `Equipped`), `PlayerDataService` (`GrantWeapon`,
`SetEquipped`), `CarryService` (one `Trapped` branch in `RefreshWalkSpeed`),
`NestService` (two aliases over the existing ragdoll), `UIKit` (its dead
`frameModel` became the exported `frameViewport`), `ThrowFX` (one optional
argument), `AGENTS.md` (the file list, including SellService and DebugService
which have been missing since August).

### REUSED RATHER THAN REBUILT

  * `UIKit.modal` for the dimmer, panel, fade and close button. The header is
    dressed on top of the modal's own title bar rather than replacing it.
  * The `OpenPanel` attribute mutex, so this is the fourth panel taking turns
    with the Index, the Shop and the Garden.
  * `GameEvent`, which already carries PlantAt, PickUp, PlotUpgrade and the mill
    ladder. Three more verbs, no new remote.
  * The `ProfileUpdated` packet. No new replication: `Weapons`, `Equipped` and
    `Cash` all ride the one that arrives four times a second.
  * `ThrowVictim` and `NestService`'s ragdoll for the knockback -- the same
    pipeline a guardian uses, because everything expensive about it was learned
    the hard way and must not be relearned in a second file.
  * `CarryService.RefreshWalkSpeed` as the ONLY writer of WalkSpeed.
  * `UIKit.frameViewport`, which was a private `frameModel` nothing called.

### A WEAPON TOOL IS INVISIBLE TO THE BAG

It carries `WeaponId` and no `SpeciesId`, and that one fact keeps it out of three
services without a line added to any of them -- `EconomyService.SellHeld` prices
a Tool by its species, `CarryService.heldSnapshot` saves it by its species, and
`PlantService.PlaceAt` plants it by its species. Asserted in WeaponSpec, because
a Comet Bat sold at the stall for nothing would be a very quiet disaster.

### THE RESTRAINT IS A MODIFIER, NOT A WRITE

`CarryService` is still the only file that assigns WalkSpeed. A trap sets the
`Trapped` attribute and asks it to recompute; releasing clears it and asks
again. Nothing captures a speed and puts it back -- which is the difference
between this and the bug written up over `throwPlayer`, where a captured value
was stale by the time it was restored. Jumping is disabled with
`SetStateEnabled` at the two edges of the hold and nowhere else, deliberately
NOT inside RefreshWalkSpeed, which runs on every carry event and every respawn.
The camera is never touched.

Measured live, forcing the real service to recompute through a respawn:

    at rest          WalkSpeed 139.75
    Trapped = true   WalkSpeed   0.00
    Trapped cleared  WalkSpeed 139.75   == walkSpeedFor(saved Speed), recomputed

### PRICES AND COMBAT VALUES

```
                price      reach  fling  lift  windup  recover  cooldown  yaw
Rootwood Bat      5,000     12     22    0.45   0.18    0.30      1.10     0
Cactus Club      40,000      8.5   16    0.30   0.09    0.20      0.65    70
Sunflower Bonker 300,000    11     26    1.60   0.42    0.55      2.30     0
Mirewood Paddle  1,200,000  17     24    0.35   0.24    0.34      1.50    55
Cindercrack Bat  9,000,000  13     44    0.40   0.60    0.75      2.90     0
Comet Bat        60,000,000 14     34    0.70   0.28    0.38      1.80    25
Bramblejaw Trap  150,000    -- arm 1s, hold 2s, immunity 4s, expire 20s, cd 15s
```

Shared: victim limp 1.1s, hit immunity 1.5s, arc 75 degrees either side, reach
tolerance 7 studs vertical, line of sight required.

**The ladder sits UNDER the progression ladder at every rung.** Plot levels are
25K / 250K / 2.5M / 25M and mills are 10K / 75K / 500K / 3.5M / 25M, so nobody
ever chooses between a bat and the upgrade that earns them the next bat.
Rootwood at 5,000 is under both first upgrades and inside one good pod sale
(`SellSeconds = 30`, so a 170 kg pod pays for it).

**WeaponSpec caught the Comet Bat beating the Sunflower on reach, fling, wind-up
AND cooldown** -- the "every expensive bat is strictly better" failure the brief
names, invisible from reading the table. The Sunflower's lift went 1.10 -> 1.60,
which is the axis it is named after and the one thing the Comet cannot have:

    bat            launch v   apex    airtime
    rootwood          69.3     2.48    0.32s
    cactus            72.3     1.20    0.22s
    sunflower         39.9    10.40    0.65s   <- twice the height of anything
    mirewood          82.0     2.10    0.29s
    cindercrack      103.9     4.40    0.42s
    comet             69.0     5.95    0.49s

### THREE THINGS PLAY DISPROVED THAT READING DID NOT

**1. The legacy hold was the wrong branch, by a factor of seven.** `hold = nil`
puts a throw on the path the four unprofiled guardians use, and ThrowFX's own
banner says what that path does: it re-writes velocity every frame for 0.35s,
which does not hold a launch, it CANCELS GRAVITY. Measured: a Rootwood
configured for 22 studs carried 152. `hold = 0` is one impulse and then gravity.
This is NOT routing a bat through Astralmaw -- what is exceptional about
Astralmaw is its numbers, and none of them are here.

**2. FlingStuds is not how far they land, and the card was saying it was.**
With the arc fixed, measured travel is still 2-4x the configured number, because
a limp body is seventeen assemblies: it lands, keeps its horizontal speed, and
SKIDS. A flat fast arc skids furthest.

    rootwood     22 -> 59.5      sunflower   26 ->  31.1
    cactus       16 -> 58.7      cindercrack 44 -> 147.5

The guardians have exactly the same property and nobody has ever measured one
landing at its configured range either, so this is not a bug in the bats. The
CARD changed instead: FLING prints a bare number now, REACH keeps its studs
because reach genuinely is one -- the server measures it.

**3. The player avatar has no Motor6Ds, and `AnimationConstraint.Transform` does
not work either.** The first WeaponFX looked for a `RightShoulder` Motor6D
(there are none -- HANDOFF has said so since August and this pass did not read
it). The second used `.Transform` the way `CarryPose` does. Measured, writing
X + 0.9 rad to the right shoulder of a live character:

    RenderStepped   hand moved 0.03 studs
    Stepped         hand moved 0.03 studs      <- CarryPose's own phase
    Heartbeat       hand moved 0.01 studs

and a one-shot write read back as **-0.000 rad** on the next frame. The animator
overwrites it in every phase.

**So CarryPose's arm pose is not applying either.** That is a pre-existing
regression this pass FOUND and did not cause, and it is not fixed here -- fixing
character posing engine-wide is a different job. It is the next thing somebody
should look at, because "both arms under the pod while carrying" is currently
not happening.

The swing drives the engine's own `RightGrip` WELD instead. Rig-independent, and
it works:

    cindercrack   tip travel peak 8.02 studs, settled 0.04   (0.6s windup visible)
    cactus        tip travel peak 7.27 studs, settled 0.04

### AND ONE VALIDATION HOLE PLAY FOUND

`TryEquip` coerced any non-string payload to `""` -- and `""` is a real command
meaning "put everything away". So `FireServer(EquipAction, 99)` unequipped the
player. Harmless as exploits go and wrong as validation: Rule 4 is that an
argument off the wire is a lie until checked, and checking it by converting it
into a different valid command is not checking it. Non-strings are refused now;
`""` from the panel still works.

### VERIFIED IN PLAY

  * 17 services boot clean; both new ones report ready.
  * The prompt on Marigold opens the panel: `WeaponShop/true` arrives and the
    panel comes up. Verified from a fresh session.
  * All seven cards render with a live ViewportFrame of the REAL model, correct
    prices, correct badges, and the trap card states 2s / 1s / 15s.
  * Bought all seven; each logged exactly once. Repeat purchases of an owned
    item and three forged ids (`"excalibur"`, `42`, a table) all refused with no
    charge and no log line.
  * Equip cycles through three weapons and back to nothing; the Tool follows.
  * **A rejoin restored all seven, the equipped one, 12 plants and the cash.**
  * Cooldowns enforced: Cactus 4 swings in 3.0s (0.65s), Cindercrack 2 (2.90s).
  * Trap placement refused in the hub, refused on the plot field, refused
    standing on a nest pod, ALLOWED on the open road, refused for a second trap
    while one is down -- each with a denial packet.
  * Trap arming measured frame by frame: 6.2 -> 74.0 degrees over exactly 1.00s,
    then held. Expiry at t+20.2s against 20 configured. Placement refused every
    second from t+1 to t+19.
  * The guardian throw is UNCHANGED: a full Emberroot raid still confiscates and
    hauls (`hauling: right`), and the camera floor still goes 0.5 -> 12.0 -> 0.5,
    which is the proof the optional ThrowFX argument did not touch that path. A
    bat's payload leaves the camera at 0.5 throughout.
  * `WeaponSpec` 68/68, `PlotSpec` 65/65, `StarbloomLimbSpec` 71/71. `SpeedSpec`
    and `CycleSpec` still fail exactly as they did at `736e6c7`; neither file is
    touched by this pass.
  * `rojo build` passes, `git diff --check` clean.

### NOT VERIFIED -- AND THE FIRST TWO NEED A HUMAN

  * **NOTHING IN THE PANEL HAS EVER BEEN CLICKED.** Every transaction behind the
    buttons is verified by firing the exact payloads they send, but the click
    itself is not: MCP's mouse input does not reach the game viewport (it closed
    the panel by hitting the dimmer instead), and `VirtualInputManager` is
    refused with "lacking capability RobloxScript". Same wall HANDOFF already
    records for a hand-driven take. The buttons are built exactly like ShopUI's
    working buy buttons, in the same modal, at the same depth -- but somebody at
    the keyboard needs to press BUY, EQUIP, a filter tab and the X.
  * **NO PvP HIT HAS EVER LANDED.** A single Play session has one player, and
    every target test is `other ~= swinger`. Untested end to end: the arc and
    line-of-sight filter against a real second body, the knockback on a victim,
    one-hit-per-target, the chain-fling immunity, the trap CATCHING anybody, the
    2-second hold, the 4-second immunity, and a bat releasing a trapped player
    before launching them. The knockback PIPELINE is measured (payload, arc,
    camera, ragdoll, recovery) and the restraint MECHANISM is measured (the
    attribute path through RefreshWalkSpeed); what is missing is the two of them
    meeting a second player.
  * The 15-second placement cooldown is honoured but was never the binding
    constraint in test: an unsprung trap stands for 20s and the one-active-trap
    rule outlives the cooldown. A SPRUNG trap is removed after 0.6s, so there the
    15s binds -- reasoned, not measured, because springing one needs two clients.
  * Marigold's prompt and the SELL ALL board are ~15 studs apart and
    `Exclusivity` is `OnePerButton`, so the engine offers ONE of them. Standing
    at her offers hers; this cost half an hour of scripted tests looking like a
    broken shop before the cause was remembered.
  * The panel closes when the player walks 26 studs from Marigold. That is
    deliberate and it fired legitimately during testing when a character slid
    across the deck.

### FLAGGED FOR JUDGEMENT, NOT CHANGED

  * **Cindercrack knocks somebody about 147 studs.** That is half of Greenhollow
    and more than a biome-1 guardian's configured throw. It is the 9M hammer with
    the longest telegraph in the game, so it is probably earned -- but it is the
    one number worth watching, and `FlingStuds` is the lever.
  * Buying auto-equips. Buying the trap therefore puts your bat away, which is
    one click to undo and is what "I bought this" means everywhere else.
  * Seven ViewportFrames sit behind this panel. IndexUI refused viewports for
    five plants at 29-40 parts, on the grounds that it was 170 parts of CAMERA
    WORK on a phone -- the cost it refused was the ANIMATION. These are static:
    one camera write at build and nothing per frame, 13-19 parts each.

## BATS SWING, PODS DROP, AND THE LOADOUT BECAME TWO SLOTS -- 2026-09-04 (in a01c372)

Second pass over Marigold's stock. The shop panel itself is untouched and still
approved; everything here is what happens after you buy something.

### FILES

New: `StarterPlayerScripts/LoadoutUI.client.luau` -- the bag button, the
inventory panel, the two side equipment slots and the hotbar, in one script.

Changed: `WeaponData` (POWER replaces FlingStuds, swing animation config),
`ProfileSchema` + `PlayerDataService` (two loadout slots and the migration),
`WeaponShopService` (two slots, two Tools), `CombatService` (the pod drop, the
swing animation, a cooldown attribute), `UIKit` (`itemPreview`, `frameItem`),
`MarigoldShopUI` (reads two slots; shares the framing -- no visual change),
`WeaponSpec`, `AGENTS.md`.

### THE ANIMATION, AND THE BLOCKER

**The avatar is an R15 PHYSICS rig.** Measured on the character the game spawns:

    AnimationConstraint x15   BallSocketConstraint x14   Motor6D x0

So there is no `Motor6D.C0`. And `AnimationConstraint.Transform` is not the
channel either -- writes read back as `-0.000` the next frame in RenderStepped,
Stepped AND Heartbeat, and the animator never writes it either: it stayed at
(-0.5, -1.2, -4.5) degrees through a whole animation while the hand moved 1.19
studs. **CarryPose's arm pose is therefore not applying**, which this pass found
and did not cause, and did not fix -- it is the next thing worth looking at.

What DOES move this rig is `Animator:LoadAnimation` with a published asset,
played at Action priority. Bat-tip displacement, two runs each:

    point      507770453   4.18 studs      <- a real, readable arc
    wave       507770239   2.02
    ToolSlash  522635514   0.21            <- Roblox's own R15 tool swing
    ToolLunge  522638767   0.21

**THE BLOCKER.** The semantically right assets -- Roblox's own tool animations --
move this rig 0.21 studs, which is invisible. A readable bat swing needs a
CUSTOM PUBLISHED animation, and publishing one needs Studio's Animation Editor
(a human pressing Publish) or Open Cloud `AssetService:CreateAssetAsync` with an
API key. Neither exists in a coding session.

`KeyframeSequenceProvider:RegisterKeyframeSequence` was investigated properly and
rejected. Re-registering a FETCHED Roblox sequence unchanged reproduces its
motion exactly (point -> 1.19 studs), so the mechanism works. Hand-authored ones
did not: the root `Pose` needs `Weight = 0` and the sequence needs an
`AnimationRigData` child cloned in, and even with both, six trials gave
non-reproducible results -- five different pose axes returned byte-identical
displacement, then three different lengths did, then an amplitude sweep from 20
to 150 degrees returned 0.00 for every value including ones that had produced
0.55 minutes earlier. And the id it returns is local to the machine that
registered it, so it would never replicate.

**SO THE PIPELINE SHIPS WIRED AND THE ID LIVES IN ONE PLACE.**
`WeaponData.Combat.SwingAnimation` + `SwingAnimationLength`. Author one swing in
the Animation Editor, publish, paste the id and its length, and all six bats
animate with no code change -- the per-bat scaling already works off it. Today it
is ToolSlash: a real, supported, correctly-timed swing that is simply subtle.

Two things that cost a round each and are worth not rediscovering:

  * **`track.Length` is 0 on the SERVER.** The asset is never fetched there, so a
    speed derived from it silently never runs. The configured length is used
    instead, with the real Length preferred if it ever resolves.
  * **`AdjustSpeed` after `Play` does not replicate.** All three bats arrived on
    the client at Speed 1.00. `Play(fade, weight, speed)` carries it in the one
    message. Verified after the change:

        cactus_club       wants 0.41s -> speed 1.22, playing over 0.41s
        rootwood_bat      wants 0.60s -> speed 0.83, playing over 0.60s
        cindercrack_bat   wants 1.47s -> speed 0.34, playing over 1.47s

Played SERVER-SIDE, so it replicates to everyone with nothing to trust. Stopped
on the next swing, on unequip mid-swing, on respawn and on leaving.

`WeaponFX` still rotates the weapon in the hand -- 8 studs of tip travel. That is
the weapon's own motion layered under the arm animation, not a stand-in for it,
and it is what carries the read while the arm animation is a placeholder.

### THE POD DROP

A confirmed bat hit now drops the victim's carry BEFORE the launch, through
`CarryService.Drop` -- the same canonical call the guardian throw, the death
handler and the red-line drop all make. This supersedes the previous "bats do not
affect carried pods" rule, which was wrong twice: it made the most valuable thing
on the road immune to the only PvP verb, and it was not even reliable, because
the `PlatformStand` that fired the incidental drop is written by the victim's
CLIENT and reaching the server was a race.

  * BEFORE the launch, at the position captured before anything moves, so the
    pod lands at their feet rather than travelling with a body doing 80 studs a
    second.
  * `Drop` clears `carried[player]` first, so duplicate hits find nothing and
    return false -- and the PlatformStand watcher firing a moment later, which it
    still does, duplicates nothing.
  * Guarded by `IsCarrying`, so a miss, a blocked hit, a safe-zone hit and a hit
    refused by immunity all drop nothing -- none of them reach `knockBack`.
  * Nothing in CombatService names a species, a tier or a nest. There is no
    second pod ownership system; it calls one function.

Verified through a real guardian hit (the same `Drop` path):

    took a petalpip, tier 2 -> caught -> carrying nil
    loose pod: species=petalpip tier=2 fromNest=Nest_greenhollow_01, on the ground
    walked away, walked back, held the prompt -> carrying petalpip again

### POWER, AND WHY FlingStuds HAD TO GO

The direction changed to a climbing ladder, and the old model could not express
one. `FlingStuds` fed `sqrt(R*g / 2k)`, where raising Lift LOWERS the speed -- so
the Sunflower, whose whole identity is a lob, had the weakest shove in the shop
while sitting third on the price list. There is no assignment of that field which
makes power climb with price while lift still means anything.

POWER is its own axis now: `horizontal = Power * SpeedPerPower`, `vertical =
horizontal * Lift`. Vertical is ADDED rather than traded, so the power column and
the felt shove cannot disagree. The card prints POWER as a bare rating -- it is
deliberately not a distance, because a ragdoll skids.

    bat            price   POWER  lift   launch   travelled (3 runs)
    Rootwood        5,000    10    0.50    25.0    12.3 / 16.1 / 15.0
    Cactus         40,000    14    0.35    35.0    18.5 / 19.7 / 22.0
    Sunflower     300,000    19    1.05    47.5    44.5 / 43.2 / 44.2
    Mirewood    1,200,000    25    0.40    62.5    48.4 / 48.0 / 46.7
    Cindercrack 9,000,000    32    0.45    80.0    79.4 / 75.4 / 79.4
    Comet      60,000,000    40    0.62   100.0   149.5 / 135.4 / 119.7

Measurement conditions: same avatar, flat road at z -200, server-side ragdoll
then the exact `ThrowVictim` payload CombatService sends, head displacement
measured flat, three runs each, character respawned between runs.

Configured power and observed travel are separate numbers and both are recorded
above. Travel rises at every step; it is noisy (the Comet spans 120 to 150)
because a ragdoll's skid is.

**One thing measurement changed.** At Lift 1.55 the Sunflower travelled 71 and 77
studs against the Mirewood's 47 and 65 -- a cheaper bat visibly stronger, which
this ladder may not do. Under the new solve a big lift buys AIRTIME and airtime
buys ground. It is 1.05 now: still nearly twice the lift ratio of anything else
and still the only bat that takes somebody off the ground for half a second, but
no longer the tallest arc in absolute terms. The Comet hits twice as hard so it
throws people higher too, which under a climbing ladder is correct. WeaponSpec's
assertion moved from "highest apex" to "steepest launch angle" to match.

Prices are unchanged. The strongest bat launches at 100 against a biome-1
guardian's 114.4, so no bat out-shoves the gentlest guardian -- asserted.

### THE LOADOUT, AND THE MIGRATION

`Equipped` (one field) became `EquippedBat` and `EquippedTrap`. Both Tools live
in the Backpack at once; SELECTING one is `Humanoid:EquipTool`, a local action on
an object the server already granted, so switching weapons costs no round trip
and touches no profile.

Migration reads the old `Equipped` and places it in the slot its own CATEGORY
names, leaves the other slot EMPTY rather than guessing, and drops anything
unowned or miscategorised. No version bump: the old field was replaced, not
reshaped, and `Weapons` is untouched.

Verified against this account's real saved profile, which was written with the
old field:

    owned (7): all seven still owned
    EquippedBat="rootwood_bat"  EquippedTrap=""  legacy Equipped=nil
    plants still saved: 12   cash 92.6B

And the slots are independent:

    equip the trap    -> bat kept
    swap the bat      -> trap kept
    clear only        -> the other survives
    forged category   -> refused (a number and a bogus string, both)

### THE UI

One script owns the bag, the two side slots and the hotbar, because they show one
fact and must not disagree. There is no `selected` variable: the selected slot IS
the Tool parented to the Character, which is what the engine and the server
already believe. The two sources of truth are the profile packet and the live
Tools.

`UIKit.itemPreview` is the shared transparent preview and `UIKit.frameItem` the
one posing/camera rule -- the shop now calls it too, with its own numbers moved
across unchanged, so the approved card is unaltered. Previews have no backplate:
a ViewportFrame at `BackgroundTransparency = 1` over a faint scrim.

The hotbar replaces the CoreGui Backpack, and it is safe to because it enumerates
TOOLS rather than categories -- whatever the engine would have shown, it shows.
Number keys are rebound through ContextActionService, since turning the CoreGui
off takes its bindings with it. Cooldowns are drawn from a `ReadyAt` attribute
stamped in SERVER time, so the readout cannot show a bat as ready a frame early.

Two fixes measurement caught: the bag button sat at 1136..1186 on an 1148-wide
viewport because `UIKit.railButton` does not set an AnchorPoint (GardenUI sets
its own); and every card name ellipsed at 104px, so names wrap to two lines and
the side slots say BAT and TRAP rather than a truncated weapon name.

### VERIFIED

Automated, in Edit: `WeaponSpec` 80/80, `PlotSpec` 65/65, `StarbloomLimbSpec`
71/71. `SpeedSpec` and `CycleSpec` still fail exactly as at `736e6c7`; neither is
touched. `rojo build` passes, `git diff --check` clean, all eleven touched
modules compile.

One client, in Play: 17 services boot clean; the legacy profile migrates with
nothing lost; both loadout slots independent and forged categories refused; the
hotbar shows five real-model Tools (bat, trap, three plants) on transparent
backgrounds; the bag panel renders seven owned items at desktop and at 300px with
no overflow; swing animation replicates and scales per bat; the cooldown survives
a weapon swap and the trap keeps its own timer; a dropped pod retains species,
tier and origin nest and picks up normally; guardian confiscation and the
guardian throw are unchanged.

### NOT VERIFIED -- ALL OF IT NEEDS A SECOND PLAYER

A solo Play session has one player and every target test is `other ~= swinger`.
Untested end to end, and none of it should be described as working:

  * **A bat hit landing on anybody.** The arc, the line-of-sight filter and the
    one-hit-per-target rule have never met a second body.
  * **The pod drop from a BAT.** The `Drop` call and the re-pickup are verified
    through the guardian's path; the bat-specific ordering -- drop, then ragdoll,
    then launch -- is reasoned and unrun.
  * **A second player SEEING the swing.** It is played server-side, which is what
    makes it replicate, and this client sees its own. Nobody has watched
    somebody else's.
  * Chain-fling immunity, the trap catching anybody, the 2-second hold, the
    4-second immunity, and a bat releasing a trapped player before launching.
  * Clicking anything in the new panels. The buttons are built exactly as the
    shop's are, and the shop's are confirmed working by the owner, but MCP cannot
    click and `VirtualInputManager` is refused with "lacking capability
    RobloxScript". The bag panel in the screenshots was forced visible by
    property, not opened by a press.

### WORTH WATCHING

  * **The Comet throws people 120-150 studs.** Half of Greenhollow, from the
    60M bat with a 1.8s cooldown. It is the top of a ladder that was asked to
    climb, so it is doing what it was told; `Power` is the lever if it is too
    much.
  * **CarryPose is not applying.** Measured above. Nothing in this pass depends
    on it, and it means arms do not fold under a carried pod today.

## THE BAT IS HELD, AND THE SHOULDER WAS NEVER INERT -- 2026-09-04 (in a01c372)

### THE ONE-LINE VERSION

Three passes of notes -- in HANDOFF, `WeaponData.luau` and
`tools/animation/build_swing.luau` -- recorded the right shoulder as INERT and
concluded that a hand-published animation asset was the only way to swing a bat.
**The shoulder was never inert. `CarryPose.client.luau` was overwriting it every
frame.** With that fixed, the ready pose and the whole swing are authored in
code, in degrees, and no asset is needed by anything.

### HOW IT WAS FOUND

The old evidence was real but misread: writing `AnimationConstraint.Transform`
read back as `-0.000` on the next frame, and the joint did not move under a
PUBLISHED animation either -- which looked like a property of the rig rather
than something sitting on top of it.

What settled it was asking a different question: not "does my write survive?"
but **"which joints does the animator itself write?"** Sweeping all fifteen
during Roblox's own `wave`:

    WRITTEN (11)   LeftAnkle LeftElbow LeftHip LeftKnee Neck RightAnkle
                   RightElbow RightHip RightKnee Root Waist
    UNTOUCHED (4)  LeftShoulder LeftWrist RightShoulder RightWrist

Both shoulders, symmetrically, and nothing else that an arm-posing script would
own. Then, directly:

    CarryPose running     right shoulder swept   0.0 deg
    CarryPose disabled    right shoulder swept  17.1 deg

### THE BUG, WHICH IS WORTH RECOGNISING AGAIN

`CarryPose` released the shoulders like this:

    if side.constraint.Transform ~= side.rest then
        side.constraint.Transform = side.rest
    end

It reads as "only correct it if something moved it". What moves it is THE
ANIMATOR, every frame -- and this loop runs in `Stepped`, which is *after* the
animation is evaluated. So the guard was true forever and the write landed
forever. **Releasing an AnimationConstraint means writing to it once and then
leaving it alone.** It now writes rest once and latches (`rig.released`).

The blast radius was everything: for the whole session, on every character, both
shoulders were pinned at identity -- CarryPose's own carry pose included.

`WeaponFX` drives the same joints from the same phase, so it carries the same
latch (`posed.released`), and a comment saying why.

### WHAT THE RIG ACTUALLY DOES, MEASURED

Driven from `Stepped`, the shoulder tracks to within a degree:

    commanded X 30 -> 29.4      X 60 -> 59.4      X 90 -> 89.6

Forward kinematics was rebuilt from the rig's own attachment CFrames and agrees
with the standing character **to 0.000 studs, weapon included**, so poses could
be solved before being applied. What the axes do -- and the names mislead:

    shoulder Z   the HORIZONTAL sweep.  Z 80 -> tip left and behind (-2.1, 3.3, 3.0)
                                        Z -20 -> tip right and in front (4.3, 4.0, -1.3)
    shoulder X   the DROP, and it carries the tip backward as it falls
    shoulder Y   turns the arm across the body; moves the tip least

**The wrist is not optional.** Undriven, the bat's own weight rotates it: the
barrel fell from (-0.30, 0.91, 0.29) to (-0.46, -0.56, 0.69) within a second and
stayed there. A four-stud lever on a physics rig is a lever.

### THE POSE AND THE SWING

`READY` is the approved reference: hand beside the right shoulder at
(1.47, 0.89, 0.68) in torso space, elbow raised and folded under it, barrel up
and across the chest on axis (-0.52, 0.77, 0.36). Solved, not guessed.

The swing is `READY -> WINDUP -> STRIKE -> FOLLOW -> READY`, and it returns to
the identical ready pose -- verified frame by frame through the real system:

    t 0.31  swing starts from READY   (shoulderZ 62, elbow -145, waist 0)
    t 0.70  WIND-UP                   (Z 72, elbow -155, waist +26)  tip (-2.5, 3.8, 1.4)
    t 0.90  STRIKE                    (Z -10, waist -8.7)            tip ( 4.6, 4.0,-0.9)
    t 1.20  FOLLOW                    (Z -34, waist -40)             tip ( 6.0, 1.8, 0.5)
    t 1.70  back to READY exactly     (Z 62, elbow -145, waist 0)

**22.67 studs of bat-tip travel.** On this same rig `ToolSlash` moves it 0.21 and
`point` moves it 4.18. The strike crosses ~6 studs of the space in front of the
chest inside 0.1s, and it lands on the server's hit: Cindercrack's wind-up is
0.60s and the swing began at 0.31.

### WHICH JOINTS ARE TAKEN, AND FOR HOW LONG

Writing `Transform` OVERRIDES the animation for that joint, so every joint taken
is a joint the walk cycle loses. Measured with a bat held, character jumping:

    RightShoulder / RightElbow   swept 0.0    held -- the ready pose
    LeftShoulder / Waist         swept 5.1 / 3.3   free at rest, 63.8 / 54.7 mid-swing
    RightHip / RightKnee / Neck  swept 4.4 / 4.4 / 2.5   never touched

The off arm and the waist are **borrowed for the swing and given straight back**.
An earlier cut of this file wrote them whenever a bat was equipped -- their READY
values are zero, so that write is `identity` every frame, which is not "leave
this joint alone", it is "hold this joint at neutral". Measured at 0.0 sweep for
both, and fixed with the same one-shot latch. *The file that documents the
CarryPose bug reproduced it two hundred lines further down.*

### PER-WEAPON GRIP, AND CLEARANCE FOR ALL SIX

One arm pose carries all six bats; `WeaponData.Item.Grip` nudges each barrel so a
weapon that clears the head on the Rootwood clears it on the Comet. Measured on
the live character -- gap to the nearest body part, and a real overlap test:

    rootwood_bat      0.35     cactus_club       0.46 *
    sunflower_bonker  0.48     mirewood_paddle   0.37
    cindercrack_bat   0.41     comet_bat         0.31

    OVERLAPS WITH HEAD OR TORSO: ZERO, on all six.

\* Cactus needed the work: the fattest head on the shortest handle cleared by
0.18 at the shared grip. Six offsets were measured; the roomiest (0.57) was
rejected for laying the club too flat to match the others.

### CLEARING

Verified live, each one: switching to the TRAP, unequipping, ragdoll
(`PlatformStand`), death, and carrying a pod -- which hands the arms to
CarryPose, one writer per joint. In every case the shoulder returns to a live
animator value and comes back to (5, 34, 62) when the state clears.

**One bug found here and fixed.** Letting go used to stop the loop, and the wake
calls all hang off a Tool arriving or leaving -- neither of which happens when
somebody stands up off the floor. So a player ragdolled while holding a bat kept
the animator's tool pose at (83.8, 1.4, -6.5) until they re-equipped. The loop
now stays alive while a bat is held but suppressed; an EMPTY hand still stops it,
which is the case that matters for cost.

### VERIFIED

Automated, in Edit: **WeaponSpec 80/80, PlotSpec 65/65, StarbloomLimbSpec 71/71**,
clean `rojo build`.

`SpeedSpec` and `CycleSpec` fail, and **both are pre-existing and unrelated** --
SpeedSpec:280 calls `GameConfig.overclockUnlockOrderFor`, which does not exist in
GameConfig at all; CycleSpec asserts exactly one live biome and finds five, which
is the Dustbowl integration. Neither spec mentions weapons, neither file is
modified, and this session's GameConfig diff is +192/-0.

One client, in Play: the pose applies through the real equip path on all six
bats, the swing runs end to end and returns to the ready pose, walking and
jumping still animate underneath it, and **front and side screenshots were taken
of the Rootwood and of the Cindercrack** -- the largest of the six by bulk
(16 parts, 7.73 long; Mirewood is the longest at 8.79).

### NOT VERIFIED

  * **No second client.** Nobody has watched somebody else's pose or swing, and
    the pose is client-side, so a second machine drawing it is untested.
  * The two-player PvP regression carried over from the last pass is still unrun.
  * `Combat.SwingAnimation` (ToolSlash) still plays and is now a garnish -- the
    arm joints are overridden after it. Left wired and labelled rather than
    removed, because taking it out means touching verified playback code for no
    visible gain. **It is a cleanup candidate, not a dependency.**
  * `tools/animation/build_swing.luau` is superseded. Its header now says so; its
    KeyframeSequence findings are kept because they were expensive and are still
    true.

## THE TRAP FREEZE, THE COUNTDOWN, AND A SWING THAT WAS WAITING ON NOTHING -- 2026-09-04 (in a01c372)

> **The swing section below is SUPERSEDED.** It concludes that a
> published animation asset was the only way to move this rig's
> shoulder. That was wrong, and the next section explains why. The
> trap, countdown and playback notes in it are still current.

### FILES

New: `StarterPlayerScripts/TrapUI.client.luau` (the overhead countdown),
`tools/animation/build_swing.luau` (authors the swing, ready to publish).

Changed: `NestService` (combat bridge, and `restore()` stops replaying a
captured WalkSpeed), `CarryService` (hands `RefreshWalkSpeed` down the bridge),
`CombatService` (one identity-checked release path, the replicated expiry,
contact-frame alignment), `GameConfig` (`TrappedUntil`), `WeaponData`
(`SwingAnimationContact`, speed clamps).

### THE PERMANENT IMMOBILITY -- ROOT CAUSE

`NestService.throwPlayer` captured `humanoid.WalkSpeed` and wrote it back when
the throw ended. WalkSpeed is **0 while a Bramblejaw holds somebody**, so a
guardian landing on a trapped player captured zero and replayed it seconds
later, after the trap's own release had already restored the correct speed:

    t 0.0   trapped                      WalkSpeed 0
    t 0.5   guardian hits, captures      walk = 0
    t 2.0   trap expires, recomputes     WalkSpeed 139.75
    t 5.5   throw ends, restore()        WalkSpeed = walk = 0    <- stuck

Nothing ran afterwards to correct it, so it was permanent. It is the same
capture-and-replay shape HANDOFF recorded once before -- a thrown player keeping
their CARRY speed -- which was fixed by moving the capture rather than removing
it, so the shape survived to bite again.

**Fixed twice over, deliberately.**

  * `restore()` now asks CarryService to RECOMPUTE rather than replaying a
    number. CarryService owns WalkSpeed because it is the product of a saved
    Speed score, a carry multiplier, a mill mount and a trap, and no caller
    knows all four. The captured value survives only as a fallback for a server
    running without CarryService. Reached through the existing bridge, since
    NestService (40) cannot require CarryService (45).
  * A confirmed catch RELEASES THE TRAP FIRST, through a new `SetCombatBridge`
    -- same shape as the carry bridge, for the same dependency reason. So by the
    time the throw touches WalkSpeed there is no restraint holding it at zero.
    It sits inside the contact branch, after `distanceToSegment` accepts the
    hit, so a miss or an abandoned chase releases nothing. The release grants
    the usual four seconds of trap immunity on the way out.

Either fix alone would close the report. Both are in because the ordering one is
what the brief asks for and the recompute one is what makes the whole class of
bug impossible -- with both ends recomputing rather than replaying, the order
they happen in stops mattering.

### ONE RELEASE PATH

Expiry, a bat hit, a guardian hit, death, respawn, trap removal, the owner
leaving and a service restart all go through `releaseHold`. It takes the record
out of the table on its first line, so a second call is a no-op and returns
false -- which is also how a stale callback is neutralised.

Every hold now carries the `character` it was placed on and a monotonic `token`.
The Died and CharacterRemoving handlers pass their token and are refused if it
is not current, so a late callback from a restraint that has already ended
cannot release a newer one on a rebuilt body. The tick carries a backstop for
the case where those signals are missed entirely: a hold whose `character` is no
longer the player's is a hold about nobody.

Nothing hard-codes a speed, unanchors anything, clears another system's ragdoll,
or polls movement back on.

### THE COUNTDOWN

`CombatService` writes `TrappedUntil` once, in SERVER time, beside `Trapped`,
and clears both on release. `TrapUI.client.luau` subtracts it from
`Workspace:GetServerTimeNow()` and renders locally, so a two-second restraint
costs two replications rather than a stream, and every watcher reads one clock.

A BillboardGui on the head -- red LuckiestGuy at `TextTransparency` 0.12 over a
dark stroke, `BackgroundTransparency` 1, no plate of any kind. 3.4 studs up so it
clears the platform's own name label, `MaxDistance` 90. Parented to the head, so
a respawn destroys it without this file having to be trusted to.

The label is a rendering of an attribute rather than a timer this file started,
so a bat or a guardian ending the hold early removes it on the next attribute
change instead of running to zero. A new body rebuilds rather than re-pointing an
old label, and `CharacterAdded` re-checks so a streamed-in player picks theirs up.

### THE SWING -- **NOT FINISHED. IT NEEDS YOU TO PRESS PUBLISH.**

**What was established about the rig, by measurement.** Driving a
locally-registered copy of the authored sequence and sweeping one joint at a
time on the live avatar:

    UpperTorso      WORKS.   Y 0 / 25 / 50 / -35  ->  chest yaw 3.2 / 27.8 / 39.6 / -26.5 deg
    RightLowerArm   WORKS.   X 0..135             ->  the hand travels about 1.2 studs
    RightUpperArm   INERT.   X 0/45/90/135, and a full 0..180 sweep, both left
                             the hand at (1.49, -1.07, 0.13) to two decimals --
                             with LowerTorso at Weight 0 and at Weight 1 alike

Two things that DO matter and were found the same way: the root Pose must carry
`Weight = 0` (at 1 it pins the body and the arm moves 0.18 studs instead of a
stride), and the sequence needs an `AnimationRigData` child, which is not
constructible and is cloned from a fetched Roblox animation.

**The authored swing.** `tools/animation/build_swing.luau` builds a five-frame
`SeedBatSwing` into ServerStorage: neutral, wind-up at 0.26, contact at 0.40,
follow-through at 0.55, neutral at 0.90. Legs are absent entirely and LowerTorso
is weightless, so walking and jumping keep their joints.

Previewed on the real avatar: **1.61 studs of hand travel and 80.6 degrees of
chest rotation**, from +34 coiled right to -46 following through left.
Photographed: the WIND-UP reads properly -- torso coiled, bat drawn back across
the body, hand on the handle. The CONTACT frame does not: with the shoulder
inert the arm cannot rise, so the elbow alone carries the bat down past the leg
rather than across the front.

**Why publishing is the blocker AND the answer.** `AssetService:CreateAssetAsync`
exists in this Studio and refuses: *"CreateAssetAsync and CreateAssetVersionAsync
are not available yet"*. `RegisterKeyframeSequence` works but returns an id local
to the machine that registered it, so it never replicates -- it is a preview
tool, and nothing in `src/` uses it. A published animation goes through Roblox's
own import and retarget, which is NOT the path a locally-registered sequence
takes, and the published `point` animation demonstrably moves this rig. So
whether the shoulder wakes up is a question only the publish step answers.

**PLACE OWNER: user `4119740186`, CreatorType User (not a group).** Publish under
that account.

**What to do, and it is four steps:**

    1. Studio, EDIT mode, with `python -m http.server 8731` running at the repo root:
         local build = loadstring(game:GetService("HttpService"):GetAsync(
             "http://127.0.0.1:8731/tools/animation/build_swing.luau", true))()
         print(build())
       That puts `SeedBatSwing` in ServerStorage.
    2. Right-click it in Explorer -> Save to Roblox. Set the type to Animation.
       (Or open the Animation Editor on an R15 rig and import it, if you would
       rather scrub the timeline first -- that is also the place to see whether
       the shoulder moves.)
    3. Copy the asset id it gives back.
    4. In `WeaponData.Combat`, set
         SwingAnimation        = "rbxassetid://<the id>"
         SwingAnimationLength  = 0.90
         SwingAnimationContact = 0.444
       and nothing else changes -- the per-bat timing already scales off those.

Until then `SwingAnimation` stays on Roblox's own `ToolSlash` (522635514). That
is a real, supported, correctly-timed animation that moves this rig 0.21 studs at
the bat tip -- effectively invisible. The pipeline is exercised end to end by it;
the motion is not there yet.

### PLAYBACK: CONTACT NOW LANDS ON THE HIT

Scaling was by TOTAL length over total swing, which lines the visible strike up
with the server's hit only where a bat's wind-up is the same fraction of its
swing as the animation's contact is of its length. Across the six that fraction
runs 0.22 to 0.42, so it was right for none of them. It scales by the CONTACT
FRACTION now -- `speed = length * contact / Windup` -- clamped to 0.45..3.0 so
neither end becomes a blur or a crawl. Measured, replicated to the client:

    cactus_club       windup 0.09s   speed 2.78   visible contact 0.090s
    rootwood_bat      windup 0.18s   speed 1.39   visible contact 0.180s
    cindercrack_bat   windup 0.60s   speed 0.45   visible contact 0.556s   (clamped)

The two earlier playback fixes are preserved and still load-bearing: server-side
`track.Length` is 0 so the configured length is what is used, and the speed goes
into `Play(fade, weight, speed)` because `AdjustSpeed` after `Play` does not
replicate.

### VERIFIED

Automated, in Edit: WeaponSpec 80/80, PlotSpec 65/65, StarbloomLimbSpec 71/71,
clean `rojo build`, `git diff --check` clean, every touched module compiles.

One client, in Play:

  * **The freeze, driven as the exact race.** Trapped so WalkSpeed read **0.00
    at the moment the guardian landed** -- which is precisely the value the old
    `restore()` captured -- released mid-throw, and **139.75 after the throw
    finished**. That is the reported bug reproduced and closed.
  * Countdown appears, counts 1.4 -> 1.0 -> 0.7 -> 0.4 -> 0.1, has a fully
    transparent background, vanishes on early release, and does not duplicate
    when a second restraint starts. On a rebuilt body it rebuilds rather than
    leaving a stale one.
  * Repeated releases are harmless; movement stays correct after four.
  * Swing timing aligned for three bats; eight swings in a row leave ONE track
    playing, and unequipping leaves none.
  * Guardian confiscation, the guardian throw and the pod-drop-before-fling all
    still behave.

### NOT VERIFIED

  * **The swing itself is not finished** and cannot be until the asset is
    published. The contact pose is wrong in local preview for the reason above.
  * **No PvP.** One client means the trap has never actually caught anybody, so
    the real `holdPlayer` -> `releaseHold` cycle is unrun end to end. What IS
    verified is every piece of it: the movement integration (server-set
    `Trapped` -> the real CarryService computes 0, cleared -> 139.75), the
    guardian race, the release path's idempotence, and the countdown.
  * The exact eight-step multiplayer regression in the brief -- P2 carrying a
    pod, entering P1's trap, guardian hit before expiry -- has NOT been run.
    Its two hard parts are each verified separately and their meeting is not.
  * A second player watching somebody else's swing.
  * Client-side probes that set `Trapped` from the CLIENT exercise TrapUI only;
    the attribute never reaches the server, so those runs say nothing about the
    hold. Called out because the numbers look like a passing movement test and
    are not one.

## Still open

  * ~~The cash cap.~~ **Settled at 1e15** — see SAVING below.
  * **RecommendedSpeed**: Greenhollow 0, Dustbowl 167M, Tanglemire 800M, Emberroot 3B,
    Starbloom 10B. It does not restrict entry and never has — the road is open and looking around
    is free at any Speed. Since 2026-09-01 it decides ONE thing: whether a thief gets the wake
    delay when a pod leaves the nest. Under the recommendation the parent is up in the same tick.
  * **The repo FOLDER is still `D:\KAPE\Steal an Artifact`.** The Roblox place itself was renamed
    to "Steal a Seed" by the owner on 2026-08-21.
  * **Offline income.** Deferred in the plan; the reference advertises it in a banner across the top
    of the screen as the reason to come back tomorrow.

## Next

Phase A is closed: steal -> carry -> bank -> plant -> grow -> earn, plus the mill that buys speed.
All of it is measured in KB/HANDOFF above rather than asserted.

The two things standing between this and a playable loop:

  * **A hand-driven take has never been verified.** Everything up to the hold works; VirtualInput
    cannot begin one. Somebody at the keyboard needs to walk to a nest and hold E.
  * **`Players.MaxPlayers` is 60 against 6 plots.** Joiner 7 gets no plot. It is not settable from
    code -- Game Settings -> Places, set it to 6.

The HUD and Dustbowl are complete. Next content is Tanglemire only after its art and approval pass;
do not fill it from imagination. Phase D upgrades remain available as the next systems pass (the
mill rate is deliberately a slow FLOOR for multipliers to sit on). Offline income is still deferred
on purpose -- growth uses an absolute clock, cash does not, and an offline faucet needs a claim
flow, a cap and an anti-abuse story before it needs code.

## Astralmaw void face and Starbloom falling-star pod -- 2026-09-01

Two focused art changes are present in the working tree and intentionally uncommitted pending owner
approval. `AstralmawModel.luau` replaces `Left/RightEyeMain` and `Left/RightEyeBrow` with the shared
Starbloom void-eye contract: `LeftEye`, `LeftPupil`, `LeftLid`, `RightEye`, `RightPupil`, and
`RightLid`. The sockets are dark blocks centred on the skull surface, each has one cold Neon
pinprick, and there are no glints. The existing jaw, throat and teeth remain the expression.
Astralmaw measures 81 -> 83 BaseParts and ParentModel still returns all seven Motor6Ds:
RootJoint, Neck, JawJoint, LeftShoulder, RightShoulder, LeftHip, RightHip.

`CreatureModel.BuildPod` replaces Starbloom's five identical `OrbitArc` pieces plus the two-dot
comet with 15 biome-specific parts: four unequal accretion masses, a dark singularity framed by two
event-horizon slivers, five stretched infall shards, and a comet head with a two-step tapered wake.
The old arc spend produced one generic ring silhouette; the old tail was a second dot and did not
establish motion. The replacement keeps Starbloom's diagonal silhouette slot but makes it read as
matter being pulled into a void. No other biome branch was edited.

Edit-mode clone-require verification against the Rojo-synced instances:

  * Base-tier pod counts: Greenhollow 7, Dustbowl 9, Tanglemire 13, Emberroot 21, Starbloom 19.
    Colossal counts are respectively 8, 10, 14, 22 and 20.
  * Starbloom tier 1 -> 7 diameter is 1.66 -> 9.04. All 15 art pieces match after normalizing size
    and position by diameter (maximum errors `2.98e-8` and `7.30e-8`).
  * Starbloom maximum horizontal extent is 1.1703 D; vertical extent is 1.2934 D at tier 1 and
    1.2901 D at tier 7. No pod corner falls below the base and no Starbloom-specific art part has
    all eight bounding corners inside either shell lobe.
  * Built Astralmaw, all five current Starbloom grown plants, and both checked pods contain zero
    BaseParts whose name ends in `Glint`.
  * `--!strict` remains the first bytes of both edited modules, `git diff --check` passes, and
    `rojo build -o build/StealASeed.rbxlx` passes.

Temporary Edit-mode review models and cloned modules were destroyed after measurement. This was a
visual/static verification pass, not a Play test. Existing user-owned edits in `SeedData.luau`,
`StarbloomForms.luau`, and `StarbloomMockupRunner.luau` were not touched by this pass.
