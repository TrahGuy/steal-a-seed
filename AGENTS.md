# Steal a Seed — Roblox Place Project

Multiplayer PvP extraction / collection simulator. Rojo 7.6.1, synced to Roblox Studio.

Read [KB/HANDOFF.md](KB/HANDOFF.md) at the start of every session and update it before ending one.
[KB/BLUEPRINT.md](KB/BLUEPRINT.md) is the design source of truth — the game's direction, not its code.

## One shared source for every agent

This file is the canonical project guide for Codex, Claude, and any later coding agent.
`CLAUDE.md` is only a pointer here; do not duplicate project rules in it. The canonical project
skills live under `.agents/skills/`; `.claude/skills/` contains compatibility pointers only.

At the start of work, read this file and `KB/HANDOFF.md`, then inspect `git status` and the latest
commits. Repository state and committed handoff notes outrank remembered chat context. If another
agent reports a pushed commit, verify that commit before building on it. Preserve any unrelated or
in-progress working-tree changes, and never include them in your own commit.

Record durable decisions, verification results, unresolved risks, and the implementing commit in
`KB/HANDOFF.md`. Chat is for coordination; the repository is the shared memory.

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

After every completed modification, commit and push the files owned by that task:

```
git add -- <task-owned files>
git commit -m "<what changed and why>"
git push origin main
```

One logical change per commit. Never stage unrelated work already present in the shared checkout.
If another agent has an in-progress edit, leave it unstaged and call it out in the handoff.

## Automated Play tests never load a real save

An agent-driven Play session (MCP `start_stop_play`, a runtime harness, any Play-based check) runs
against a throwaway DataStore. It never runs against `GameConfig.Save.StoreName`, which is
`StealASeed_v1`, the owner's and the players' saves.

1. **Turn the test store on, in Studio Edit:** run
   [tools/studio/test_store_on.luau](tools/studio/test_store_on.luau).
   - It sets the StringValue `ServerStorage.SeedTestStore` to a throwaway name, `SeedTest_<UTC date>`.
   - SaveService opens that store instead of the real one, but only in Studio. A live server never
     looks, and a marker that names anything else turns saves off rather than falling back.
   - `default.project.json` does not map ServerStorage, so no Rojo sync or reconnect can undo it.
     Editing GameConfig is safe.
2. **Run [tools/studio/store_guard.luau](tools/studio/store_guard.luau) in Edit immediately before
   EVERY Play start.**
   - It answers `SAFE` only when three things hold: the marker names a throwaway, Studio's SaveService
     reads the marker, and Studio's GameConfig names the same marker and pattern.
   - Start only on `SAFE`. On `UNSAFE`, fix what it names; never start Play anyway.
3. **Check the first save line after the start.** It must read
   `[Seed/SaveService] Ready. Store "<throwaway>" (STUDIO TEST STORE, ...)`. If it reads anything else,
   stop Play at once, keep the console log, and tell the owner.
4. **Finish clean:** run [tools/studio/test_store_off.luau](tools/studio/test_store_off.luau).
   - It deletes the throwaway store's keys, only when the name is a throwaway, and removes the marker.
   - Without this, the owner's own Studio playtests keep using the test store.

Never open, read, write or delete keys in the real store from a test or a tool.

This section exists because of 2026-09-26. The first method edited Studio's copy of GameConfig, a GameConfig
comment edit made Rojo put the real name back, and a Play test loaded the owner's real save. See
KB/HANDOFF.md.

## Structure

```
default.project.json          Rojo map
art/                          UI crops, uploaded to Roblox; ids in GameConfig.Rail
src/
  ReplicatedStorage/SeedGame/
    Shared/GameConfig.luau      names, capacity, map geometry, speed curve, save
    Shared/SeedData.luau        Greenhollow + Dustbowl species, and what they earn
    Shared/BiomeData.luau       the five biomes and where they sit on the road
    Shared/UIKit.luau           the modal, the slab, the lattice and one camera framer
    Shared/HudLayout.luau       where every HUD group sits -- desktop, compact, or a touch
                                screen's two sidebars and its top row (BIOMES, TELEPORT,
                                OBBY, ADMIN, the clock's chip at the row's right end) with
                                the column under it -- numbers only
    Shared/ReachPoint.luau      pod timer, stacked prompt and PICK UP placement -- numbers only
    Shared/WeaponData.luau      Marigold's shelf: six bats, one trap, prices and combat
    Shared/WeaponModel.luau     their geometry -- Tool, shop viewport and world trap
    Shared/ActionRefusal.luau   the headline and next step a refused action shows -- the
                                server names a reason, it never decides one
    Shared/Notice.luau          every short notification's kinds, rules, timing and sounds;
                                ActionToastUI is its one renderer (post via Notice.post); a
                                `dismissible` post gets a close button (the like reminder)
    Shared/StatusText.luau      the text-led line every lasting indicator is drawn with (chase
                                warning, boost row, obby run line) and the notices' icons;
                                placed by HudLayout (statusRows, statusLine, boostRows) -- no
                                plates, no pills; a phone's own sizes are PhoneScale
    Shared/FloatingSign.luau    words floating over a hub thing, drawn like the wheel's "SPIN
                                THE WHEEL!" (studs-sized billboard, LuckiestGuy, dark outline,
                                the wheel's SignDistance), one plain colour, made per client on
                                a local anchor: the chest's OPEN FREE CHEST! and the pedestal's
                                SACRIFICE A POD! (words in GameConfig *.FloatingWords)
    Shared/HotbarRoles.luau     pure: what each hotbar slot means (bat, trap, tickets, active
                                plant, previous plant), the two plant shortcuts' memory (a Tool
                                and a key, re-leased within Grace after a respawn, never replaced
                                by an arrival), and the Bag cell's storage count
    Shared/HotbarCard.luau      how one hotbar slot is drawn to the owner's reference: a square
                                translucent charcoal plate, a thin light edge, a plain white number
                                top left, a big preview, a stack count, a rarity bar, a hidden Name
                                label for TutorialUI's pointer; lift, bump and flash (none under
                                reduced motion). Numbers in GameConfig.Hotbar
    Shared/RewardSplash.luau    a granted reward made obvious: a brief card (icon, name, amount)
                                near the middle, then each icon flies to its HUD destination or
                                fades; reduced motion shows it without the flight. The Bonus
                                Chest's claim plays it (BonusChestUI), from the server's answer only
    Shared/StarbloomTeaser.luau "BEYOND THE STARS…" / "NEW BIOME · COMING SOON" over Starbloom's
                                end wall, FloatingSign's look with a steady lavender glow; words
                                in GameConfig.StarbloomTeaser. A visual teaser only (built by
                                StarbloomTeaser.client.luau, each client's own)
    Shared/ObbyData.luau        the Floating Garden obby: every position, timing, reward and
                                attribute name -- numbers only (switch: GameConfig.Obby)
    Shared/ObbyView.luau        where a runner is put down and which way the course runs from
                                there; the camera's ONE turn after a placement, as a small state
                                machine -- numbers only (ObbyCamera applies it)
    Shared/WheelData.luau       the obby reward wheel: twelve prizes, weights, pools, the daily
                                allowance, every outcome's exact odds; the two spin products
                                (+1, +10) and their ONE switch, WheelData.Paid.Enabled -- OFF
                                until the owner says so (KB/HANDOFF.md, the paid-spins entry);
                                display-only: rarity words, short names, the drawn wheel's
                                readable sectors, each pod's species odds -- numbers only
                                (switch: WheelData.Enabled)
    Shared/WheelDraw.luau       the wheel's face in frames (the owner's approved mockup) --
                                readable sectors, icons, upright words, studded rim, rainbow
                                trail, SPIN hub -- for the panel and the world wheel alike
    Shared/HatchRoll.luau       the three seconds before a hatch is shown, as arithmetic: when
                                a hatch's plant may be shown (every hatch has its own three
                                seconds; nothing queues), which silhouette stands where the
                                pod was at each moment (the last is always the plant that
                                hatched), and whether a plant's Tool is still a secret (its
                                RevealAt attribute). It decides nothing about WHAT hatched,
                                and refuses to load with a roll outside 2.5 to 3.5 seconds.
                                ONE switch, GameConfig.Plant.Hatch.Roll.Enabled -- OFF on
                                published servers until the owner says so; StudioPreview
                                shows it in Studio (KB/HANDOFF.md, the world-roll entry)
    Remotes/                    created at runtime by ServerMain
  ServerScriptService/SeedGameServer/
    ServerMain.server.luau      bootstrap: Init() all, then Start() all
    MapService.luau             builds the whole map, and the lighting, from code
    PlotService.luau            who owns which plot, puts them on it, TELEPORT TO PLOT, and
                                BIOMES' one landing (the Greenhollow entrance)
    ProfileSchema.luau          what a profile is, and the validator (NOT a *Service). It
                                drops a held row that is not a plant and never cuts the list
                                to Save.MaxHeld: a record saved with more comes back whole
    SaveService.luau            DataStore transport, session locking
    PlayerDataService.luau      profiles in memory, autosave, replication
    CreatureModel.luau          pods and creatures (NOT a *Service)
    ParentModel.luau            Greenhollow guardian + biome dispatch (NOT a *Service)
    BramblebackModel.luau       Dustbowl guardian geometry and seventh-seam rig
    NestService.luau            nests, and the parent that sleeps beside them; the server owns
                                every guardian's physics (pinToServer), one chase at a time,
                                later thieves remembered and chased next
    GuardianPursuit.luau        the chase's pure parts: the both-bodies contact sweep, the
                                sample rules, the close-range lead, the thief memory, and the
                                way home through the road's mouth (routeHome) (NOT a *Service)
    CarryService.luau           one pod at a time, and what it costs to carry; the saved record
                                of what is held (profile.Held, Save.MaxHeld = 24 plants and
                                pods) and the ONE place its room is counted, HeldRoom. A plant
                                or a pod is handed over AND recorded, or it is neither: a
                                hatch and a pickup (GiveHatched with onRecord), a pod at a nest
                                (TryTake refuses it) and a pod at the red line (bank leaves it
                                in the arms). A pod in the arms keeps its place. A pod given
                                (GivePod: a wheel prize, a paid pod) is counted and recorded
                                too, or not given; a rebuild is not counted. The limit stops a
                                row being added, never cuts one off
    PlantService.luau           place by click, hatch by hand, pick back up. A hatch or a
                                pickup the record has no room for is REFUSED: the pod or the
                                plant stays planted and the player is told PLANT STORAGE FULL
                                (the owner's decisions, 2026-09-29). Instant Hatch opens no
                                purchase dialog for a full record; a receipt that finds it
                                full MAKES ITS POD READY instead, and is answered for only
                                once the garden was written. A receipt opens only the pod that
                                was pressed, while it still grows; every other receipt (that pod
                                ready or gone, no note, no garden yet) is
                                KEPT AS A CREDIT (profile.InstantCredits, 2026-09-30), shown as
                                a price-less "Free Instant Hatch" and spent by the next Instant
                                Hatch press, only once that hatch has succeeded (KB/HANDOFF.md,
                                the plant-storage entry)
    EconomyService.luau         THE FAUCET -- grown plants pay kg/sec, nothing else mints
    TreadmillService.luau       THE FAUCET for Speed -- stand on your own mill
    SellService.luau            the sell-all board beside the stall
    DebugService.luau           Studio-only server test helpers; no UI or remote
    AdminService/               the dev console for two allowlisted UserIds, live servers
      init.luau                   every request checked here; grants, progress reset, night/day,
                                  and Announce (handed to AnnouncementService after the allowlist)
      AdminConsoleUI.client.luau  its panel -- cloned ONLY into an admin's PlayerGui, never shipped
    AnnouncementService.luau    admin announcements (filtered, cooldown, THIS SERVER or ALL SERVERS
                                through MessagingService, deduped, expiring; never published from
                                Studio) and game.ServerRestartScheduled's notice, both as Workspace
                                attributes every client reads
    OwnerTitleService.luau      the cosmetic rainbow ADMIN title over the owner's head only
                                (AdminService.IsOwner, by UserId), rebuilt on every character
    WeaponShopService.luau      Marigold's counter: buying, equipping, and the one Tool
    CombatService.luau          what a bat and a trap DO -- knockback, restraint, cleanup
    BonusChestService.luau      the free Bonus Chest in the hub: claims, cooldown, boosts
    SacrificeService.luau       the free sacrifice pedestal in the hub: one banked, unhatched
                                pod out of the hands for a short boost to ONLINE garden income;
                                quote, then yes; numbers in SeedData.Sacrifice
    Metrics.luau                launch analytics, measurement only (NOT a *Service);
                                what it sends and why: KB/ANALYTICS.md
    TrafficLogService.luau      the external new-player feed to two webhook secrets (Make ->
                                Sheet); source switch on, unpublished, server-only: KB/TRAFFIC_LOG.md
    TrafficLogConfig.luau       its switch, secret NAMES and campaign allowlist (NOT a *Service)
    ObbyService.luau            the Floating Garden: starts, 10 Hz gate/fall/validation tick,
                                the one PayReward per real run, every exit putting movement back
    ObbyCourse.luau             builds the course's walkable parts from ObbyData (NOT a *Service)
    ObbyDecor.luau              the course's art, from MapDecor.Kit/Props (NOT a *Service)
    WheelService.luau           the reward wheel: the one-time hatch bonus spin (GrantHatchBonus,
                                outside the obby's allowance); spins earned (5 per 24h window, from the obby),
                                every spin rolled, recorded, SAVED, then paid through the
                                existing faucets; owed prizes (a pod prize waits for room as
                                CarryService.HeldRoom counts it, so it never takes the place
                                kept for a pod being carried home). Spins bought (switched off):
                                it alone opens the purchase prompt, the prompt grants nothing
                                (StoreService's receipt does), and PolicyService fails closed.
                                Spin Tickets: one Tool kept equal to WheelEarned (no balance of
                                its own); GrantCommunity saves +5 and CommunityClaimed together
    WheelModel.luau             the wheel standing behind Marigold's stall (NOT a *Service)
    CommunityService.luau       the community chest by the Bonus Chest: builds it and its step
                                pad, checks group membership on the server BEFORE any join
                                prompt ("join" sends a non-member to it, "verify" after), then
                                WheelService.GrantCommunity (once per profile)
src/StarterPlayer/StarterPlayerScripts/
    Ambience.client.luau        wings, walk cycles -- decoration only
    Music.client.luau           the background bed; ids in GameConfig.Music
    ParentAnim.client.luau      parent limbs, breath and Brambleback body pose
    PromptUI.client.luau        draws every ProximityPrompt (Style = Custom)
    AlertUI.client.luau         the RUN alarm, vignette and SAFE flash
    AnnouncementUI.client.luau  the restart notice's countdown and an announcement ("Name: message",
                                one centred flowing line, rainbow name), under the top centre column
                                (under the guide's lines while they are up); no input
    OwnerTitleUI.client.luau    turns the owner title's rainbow on this screen (still for reduced
                                motion) and hides it while TrapUI's countdown is over that player
    PlantUI.client.luau         the hatch countdown over an unhatched pod
    HatchFX.client.luau         the hold's glow and dust, the burst's rings, and the
                                creature reveal -- one cosmetic event, drawn locally. While
                                a roll runs: IN THE WORLD, where the pod stood, for everybody
                                who can see it -- a disc, dark plant shapes turning over
                                (quick, then slow, one at a time) and a question mark riding
                                above them; then the plant, its label and its fanfare. The
                                roll itself has no screen gui, no camera, no input and no
                                sound; at most World.MaxShapes rolls turn shapes at once.
                                There is NO hatch card: HatchRollUI was retired 2026-09-29
                                at the owner's request, do not bring it back
    PlantPlace.client.luau      click-to-place, the ghost disc, and Put away
    PlantPickUI.client.luau     TOUCH ONLY: tap your grown plant to select it,
                                then a real button picks it up
    PlantSway.client.luau       idle lean, the hatch shake, and the grown-plant walk
    CashUI.client.luau          corner HUD: cash + speed, from the ProfileUpdated remote
    CashPop.client.luau         lime +$N rising off every grown plant (cosmetic only)
    IndexUI.client.luau         LEFT rail: the almanac, ??? until you have grown it
    ShopUI.client.luau          LEFT rail: the shop panel (UI only, nothing transacts yet); its SPIN
                                TICKETS shelf sells WheelData.Products the wheel's way (WheelBuy,
                                shown only while WheelPaidAllowed) with REWARDS & ODDS on its heading
    GardenUI.client.luau        RIGHT rail: a row per plant, live clocks
    SpeedFX.client.luau         +N pops on Speed gain, and the run streak (off on the obby course)
    BiomeGuideUI.client.luau    advisory Speed banner on biome entry
    CarryPose.client.luau       both arms under the pod while carrying
    MarigoldShopUI.client.luau  Marigold's Garden Goods -- opened by her prompt
    WeaponFX.client.luau        how a bat is HELD and SWUNG -- poses the right
                                arm, and the impact burst
    LoadoutUI.client.luau       the bag, the two equipment slots, and the hotbar. Since 2026-10-01
                                the slots are ROLES (HotbarRoles): 1 bat, 2 trap, 3 Spin Tickets
                                (xN), 4 the active plant/pod, 5 the previous one (desktop only;
                                a phone shows four + BAG). HOLD in the Bag chooses the active
                                one; every stored plant stays listed in the Bag. The BAG cell
                                counts plant storage (profile.Held + a carried pod) / Save.MaxHeld.
                                Drawn by HotbarCard; the item's name pops up over the strip on an
                                equip and under a mouse. On a touch screen BAT/TRAP also keep
                                their sidebar tiles and chooser
    RailDrawerUI.client.luau    TOUCH ONLY: the left dock's panel and handle, which
                                Index, Shop and Settings each stand their own tile in
    TrapUI.client.luau          the red countdown over a trapped player
    ActionToastUI.client.luau   draws every short notification (Notice): refusals, successes,
                                warnings, information -- text-led, stacked above the belt; on
                                a phone hung from the top of the centre column instead
    HatchBonusUI.client.luau    the hatch bonus's notice after the reveal and the guide's
                                congratulations, then the once-only dismissible like reminder
    BonusChestUI.client.luau    the chest's sign, prompt and boost timer -- and the boost row,
                                which also draws the sacrifice pedestal's line; a confirmed
                                claim's RewardSplash, once per claim, flying to the row's line
    CommunityChestUI.client.luau  the community chest's glowing, drifting rainbow FREE (the wheel
                                sign's drift at twice its speed) and claimed state; the
                                step pad asks the server first, once per visit; only a
                                non-member sees GroupService:PromptJoinAsync, then a verify
    SacrificeUI.client.luau     the pedestal's confirmation (the pod, what it buys, KEEP POD /
                                SACRIFICE), its two signs' own line and its prompt
    PlotTeleportUI.client.luau  TELEPORT TO PLOT under the clock (beside it on a phone), alive
                                and in the Safe Zone
    ObbyUI.client.luau          the obby's moving platforms (from server time), crumbles and
                                spring throws under your own feet, the run line and RETURN TO
                                PLOT; on a phone the run's clock alone, each stage's name said
                                once as a notice
    ObbyButtonUI.client.luau    OBBY beside TELEPORT TO PLOT: to the obby's entrance, Safe Zone only
    BiomesButtonUI.client.luau  BIOMES on TELEPORT's other side: to the Greenhollow entrance
                                only, Safe Zone only, TELEPORT TO PLOT's rules and cooldown
    ObbyCamera.client.luau      turns the camera down the course ONCE when a runner is put down
                                (the arch, the start, a checkpoint after a fall) and hands it
                                straight back -- ObbyView's arithmetic, nothing held
    WheelUI.client.luau         the reward wheel's panel (scrim, wheel, SPIN hub, Reward info with
                                species cards, owed prizes) and this player's copy of the world
                                wheel's face; GET SPINS and its card, shown only while the
                                server says this player may buy -- inside the panel, never on
                                the HUD
    TrailFX.client.luau         the Bloomrunner Trail behind whoever wears it (cosmetic only;
                                not drawn on the obby course, like SpeedFX's run streak)
```

**Phase A and the HUD are complete**, and Dustbowl is live production content. Tanglemire comes only
after its art and approval pass; Phase D upgrades and offline income remain later work. Current
truth and outstanding hand-tests live in [KB/HANDOFF.md](KB/HANDOFF.md).

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
11. **Primitive-built creature art must finish as a freeform silhouette.** A Ball, Block, Wedge or
    Cylinder is raw sculpting material, never a finished head, torso, hand, foot or muzzle. Overlap,
    taper and rotate a few broad masses until the outer contour reads as anatomy rather than an
    obvious primitive. Reserve spheres for small details such as eyes, buds and joints. A carved
    mouth is real recessed negative space built from brow, cheek and jaw masses, not a dark panel
    pasted onto a round head. This does not authorize MeshParts, unions or imported geometry.
12. **The HUD is placed by `HudLayout`.** Every permanent group's rect comes from
    `HudLayout.solve`, applied by the script that owns it and asked again only when its ScreenGui's
    size changes. A new HUD element gets its rect there first, and `HudLayoutSpec` proves it
    clears every other group and Roblox's touch controls on each listed phone. The desktop answer
    is the shipped layout, pixel for pixel. **On a phone nothing lasting stands in the middle of
    the screen** (2026-09-29): what used to stand under the clock is on the clock's row or in the
    slim column right under the topbar, and the guide's words are in the left column.

## Skills

The canonical project skills live under `.agents/skills/`. Every agent reads these same files;
provider-specific skill directories are compatibility pointers, never separate copies. The
reasoning stays in the Luau files and KB/HANDOFF.

| skill | read it before |
| --- | --- |
| [plant-art-bible](.agents/skills/plant-art-bible/SKILL.md) | changing how a plant, pod or creature LOOKS — silhouette, colour, rarity readout, size curves, part budget, billboards |
| [plant-authoring](.agents/skills/plant-authoring/SKILL.md) | adding or changing a species, form, growth stage, or plant behaviour — the pipeline, in order |
| [blender-to-roblox](.agents/skills/blender-to-roblox/SKILL.md) | running or editing anything in `tools/blender/` — flags, axes, and why a preview is not a mesh |
| [luau-conventions](.agents/skills/luau-conventions/SKILL.md) | writing Luau, adding a service, touching remotes or economy, or running Rojo |
| [organic-roblox-form](.agents/skills/organic-roblox-form/SKILL.md) | concepting or reviewing plants, pods and guardians so primitive geometry stays organic, readable, colourful and purposeful |
| [seed-premium-creature-art](.agents/skills/seed-premium-creature-art/SKILL.md) | designing or reviewing premium/Divine/Secret plants and pods from references: carved faces, connected limbs, layered surfaces, controlled effects and approval evidence |
| [character-rigging](.agents/skills/character-rigging/SKILL.md) | converting an approved moving character into a production Motor6D/weld rig, or changing roots, sockets, colliders or physics assembly |
| [character-animation](.agents/skills/character-animation/SKILL.md) | adding or changing procedural character motion, sleep/wake blends, gait, secondary motion or animation ownership |
| [blender-assisted-creature-art](.agents/skills/blender-assisted-creature-art/SKILL.md) | using Blender to study, block out and review a creature: design brief, plain-then-colour renders, Route A part translation with its fidelity report; Route B (custom mesh) only after the owner approves a named asset |

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
