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
    Shared/UIKit.luau           the modal, the slab, the lattice and one camera framer; coverRail
                                (a full-screen menu puts the rail layer under its dimmer while open).
                                Since 2026-10-04 (the global UI pass): the modal's studded rim theme
                                (rim, lift, studs, closeStuds), native studs (studs/paintStuds), the
                                HUD's plate button (hudPlate), the family's press (pressPop), the lit
                                face's foot (footColours), native stand-in icons where no upload
                                exists yet (calendarIcon for EVENTS, cycleIcon for the clock), and the
                                colourful studded card backgrounds (studCard: BagLook.Studs, cropped
                                with the card's aspect, never stretched or tiled, a solid fallback)
    Shared/MenuLayout.luau      the compact menus' arithmetic: panel (between the rails / the safe
                                area), one header row, card grids -- numbers only (CompactMenusSpec)
    Shared/MenuKit.luau         the compact menus' pieces in BagLook: modal, chooser, search,
                                segmented switch, buttons, press-guarded taps, B / LB / RB bindings.
                                BRIGHT since 2026-10-04 (the owner's recolor): words on a light plate
                                are Look.Text / Muted (amounts Money / Premium / Speed), never Cream --
                                Cream is for a dark plate; button faces go / sky / idle / done / on /
                                off / live; cards via cardFace + cardTint; the HUD reads MenuKit.Slate
                                (GameConfig.SlateLook), so a menu recolor never reaches it.
                                Every menu header is MenuKit.rimTheme (the global UI pass, 2026-10-04):
                                the white studded rim, the menu's icon (GameConfig.MenuIcons) beside a
                                white ink-outlined title, the red studded close. Faces by function:
                                go (buy / equip / main action), sky (secondary, navigation), claim (a
                                reward to take), done (owned / completed STATE), danger (close, remove,
                                destroy), premium, idle, on (chosen), off (cannot press). Auto-ink: a
                                light word keeps its ink line, a dark word on a light plate has none
    Shared/AlmanacView.luau     which almanac cards show and what a locked one may say (pure)
    Shared/ShopCatalog.luau     the Shop's categories and cards, from GameConfig.Store and WheelData (pure)
    Shared/EventsModel.luau     the EVENTS panel's words and cache (pure; EventsPanelSpec): SocialService's
                                ExperienceEvents normalized (string ids, Display* first, UTC dictionaries
                                checked), upcoming / live / ended, NOTIFY ME / NOTIFICATIONS ON / LIVE NOW,
                                one request at a time with bounded retries (2026-10-04)
    Shared/GardenPlan.luau      MY PLANTS' arithmetic: EQUIP BEST's ranking and ties, whole-change room
                                checks, newcomers' spots (pure; GardenPlanSpec)
    Shared/HudLayout.luau       where every HUD group sits -- desktop, compact, or a touch
                                screen's sidebars and its top row (BIOMES, PLOT, OBBY, ADMIN,
                                the clock's chip at the row's right end; the three buttons are
                                words only, each touch area as wide as its drawn plate,
                                Phone.RowGap 5 px apart, PLOT on the screen's centre line) with
                                the column under it; the active-boost icon row over the strip's
                                name band and the toast over that (2026-10-04, every screen);
                                with a trap out, the REMOVE row right over the strip, everything
                                above it stepping up (removeRow, removeButton, 2026-10-04); Walk
                                Mode's horizontal switch under Settings on a desktop, left of
                                EVENTS in compact; the OTHER PLANTS switch (`others`, 2026-10-05)
                                the rail's row under Walk Mode on a desktop, under EVENTS in
                                compact; WHAT'S NEW (`updates`, 2026-10-05) under the Bag on a
                                desktop, by EVENTS or under Index in compact, EMPTY (hidden) where
                                no spot clears everything. ON A PHONE (the owner, 2026-10-05
                                evening; THE PHONE'S SIDEBARS): Shop in the top-left corner with
                                OTHER PLANTS and WALK MODE as see-through rows under it
                                (`switchInline`, Phone.Switch); Index, Garden, the Bag on the
                                top-right row; a panel under the Bag (`dock`) with INVITE, EVENTS,
                                WHAT'S NEW and Settings down it (Phone.Panel), scrolling and shutting
                                (`dockView`, `dockCanvas`, `handle`, 2026-10-06); INVITE (`invite`)
                                in the rail's top row on a desktop, under the row in compact, its
                                "!" in `inviteBadge`; `occupied` for a passing card; the x2
                                card beside the cash (`buffMinX`, 8 px off the stick's zone: the
                                cash corner widens for it and the belt slides or drops its Bag
                                cell, x2 owners only) -- numbers only
    Shared/BoostIcons.luau      which boosts and events stand in the icon row for this player
                                (weather, disco, tickets, chest/wheel income or training,
                                sacrifice), each popover's words, the deadline and the ring --
                                pure, from a snapshot of the server's attributes (BoostIconsSpec)
    Shared/ReachPoint.luau      pod timer, stacked prompt and PICK UP placement -- numbers only
    Shared/PlantLabel.luau      a grown creature's overhead label (2026-10-04): RARITY / NAME /
                                SIZE . $INCOME/s (no kg; no size for a Secret or an unsized event
                                form; TITAN / COLOSSAL in the wheel's lettering), the owner's rate,
                                its fade by camera distance and the one billboard PlantUI drives
    Shared/PlotShowcase.luau    the TOP CREATURES board beside every plot's upgrade board (2026-10-05):
                                a planted model's row (GROWN only), the two best in EQUIP BEST's order
                                (GardenPlan.before), the plain attributes the server publishes and a
                                client reads back, and the board's post, plank and rim
                                (GameConfig.plotShowcaseBase; PlotShowcaseSpec, PlotShowcasePlacementSpec)
    Shared/PlotShowcaseView.luau  how that board is drawn: the white studded rim and TOP CREATURES,
                                MY PLANTS' two cards (the rarity's studded colour, every word
                                PlantLabel.content's at the owner's rate, RarityFX, TITAN / COLOSSAL
                                lettering), a quiet EMPTY slot, NO CREATURES YET; pictures only near
                                (Showcase.PreviewNearStuds, dropped past PreviewFarStuds). The face is
                                a SurfaceGui in the PlayerGui ADORNED to the plank: a ViewportFrame
                                under the Workspace never draws (DevForum 437055, v1027's blank board)
    Shared/UpdateLog.luau       WHAT'S NEW (2026-10-05): the owner-editable update log, newest first --
                                id, date as "5 Oct 2026", title, 2-5 short bullets -- the newest
                                GameConfig.UpdateLog.Shown shown, isNew (the button's NEW dot, under
                                NewDays) and the rules UpdateLogSpec holds every entry to. No remote,
                                no server, nothing saved
    Shared/InviteRewards.luau   INVITE A FRIEND (2026-10-06): the track's one pure answer -- the forms a
                                count earns (1 / 5 / 10 / 20), the SHOWN form (never ahead of the forms
                                given), the sign's and the panel's words, the four cards' states, the "!"
                                (InviteSeen), the reward card's words and intensity, its lowest-first
                                queue, the hub pedestal's stand frame (InviteRewardsSpec)
    Shared/InviteForms/         the owner's four invite rigs replayed (generated from the Workspace
                                originals; .rbxm backups in output/model-backups) and each form's idle
                                and walk numbers (Profiles), driven by PlantIdles' thorn idle
    Shared/InviteSend.luau      the ONE way the game asks Roblox to invite friends: CanSendGameInviteAsync
                                then PromptGameInvite; CAN'T SEND INVITES otherwise (Hooks for the spec)
    Shared/InviteSounds.luau    the owner's ten invite sounds by moment, and the rules that keep them apart
                                (an unlock wins; three ticks in a row; a refreshed +1 silent) -- pure allow
    Shared/InviteNews.luau      what InviteService tells this player, heard once and replayed to every
                                subscriber; says READY so nothing said at join is lost
    Shared/RewardMoments.luau   the reward moments a new one must not stand over (the hatch reveal,
                                the offline card -- client-local attributes) and busy() with OpenPanel
    Shared/WeaponData.luau      Marigold's shelf: six bats, five traps, prices and combat;
                                the swing's short swept hit window (SweepContact), and the
                                trap rules -- three out per player, hidden, every effect five
                                to seven seconds, five seconds of immunity (2026-10-04); no
                                placement recharge and no expiry; ONE CATCH since 2026-10-05: the
                                trap is consumed and its owner may set no trap for
                                Trap.TriggerCooldownSeconds (one deadline across every type,
                                Trap.CooldownAttribute in server time); the owner's count
                                attributes and TrapsLeft / TrapsLeftText ("3x")
    Shared/WeaponModel.luau     their geometry -- Tool, shop viewport and world trap
    Shared/ActionRefusal.luau   the headline and next step a refused action shows -- the
                                server names a reason, it never decides one
    Shared/Notice.luau          every short notification's kinds, rules, timing and sounds;
                                ActionToastUI is its one renderer (post via Notice.post); a
                                `dismissible` post gets a close button (the like reminder); the
                                Secret egg toast's pure parts (2026-10-05): readSecret /
                                secretPost (once per spawn id), wordSpan (SECRET's place in a
                                centred headline), waitAfter (a post that follows another)
    Shared/PlantVisibility.luau OTHER PLANTS: OFF on THIS screen (2026-10-05): the rule (another
                                owner's GROWN plant in a plot, owner known), the one local
                                preference attribute, the reversible hide (LocalTransparency
                                Modifier; other Enabled effects remembered) and the one watcher
                                (Planted tag + per-model/plot signals, no scans); a hidden model
                                carries the local marker every plant consumer reads
    Shared/PlantForms/          the owner's supplied plant rigs as data, built whole at a tier's
                                size: the 25 road species, and (2026-10-05) the Rain event's
                                second family -- PlantForms.Supplied, the supplied model is its
                                own Tiny, x the tier ladder
    Shared/RainForms/           the Rain event's supplied models as data: the first family's eight
                                one-size forms and three pods, Stormstrider, and (2026-10-05) the
                                second family's seven sized pods, one per tier, never scaled again
                                (which tier uses which: SeedData species PodForms / PodFormOf)
    Shared/StatusText.luau      the text-led line every lasting indicator is drawn with (chase
                                warning, boost row, obby run line) and the notices' icons;
                                placed by HudLayout (statusRows, statusLine, boostRows) -- no
                                plates, no pills; a phone's own sizes are PhoneScale
    Shared/FloatingSign.luau    words floating over a hub thing, drawn like the wheel's "SPIN
                                THE WHEEL!" (studs-sized billboard, LuckiestGuy, dark outline,
                                the wheel's SignDistance), one plain colour, made per client on
                                a local anchor: the chest's OPEN FREE CHEST! and the pedestal's
                                SACRIFICE A POD! (words in GameConfig *.FloatingWords)
    Shared/HotbarSlots.luau     pure: the freely assignable hotbar's grammar (2026-10-03; it
                                replaced HotbarRoles) -- a slot is a shortcut ref (i:<Item>,
                                w:<weapon>, ticket, a faint +bat/+trap/+ticket), what a profile
                                owns, arrivals, and the Bag cell's storage count
    Shared/TrapRemove.luau      the owner's trap count off their trap records (Placed / Capacity
                                / Newest, the server's), the trigger cooldown's deadline beside it
                                (2026-10-05), and the REMOVE button over the trap's own
                                hotbar slot -- newest first, one request per id, placed by
                                HudLayout.removeButton; LoadoutUI owns one (2026-10-04)
    Shared/HotbarCard.luau      how one hotbar slot is drawn to the owner's reference: a square
                                translucent charcoal plate, a thin light edge, a plain white number
                                top left, a big preview, a stack count, a rarity bar, a hidden Name
                                label for TutorialUI's pointer, a trap's "3x" under its picture
                                (2026-10-04), a trap's trigger cooldown (cool: dimmed, a shrinking
                                shade, the seconds over the picture; 2026-10-05); lift, bump and
                                flash (none under reduced motion).
                                Numbers in GameConfig.Hotbar
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
                                trail, SPIN hub -- for the panel and the world wheel alike;
                                the prize art (2026-10-04): coin stacks and coin backgrounds
                                on cash, the uploaded Speed icon (SourceIcons.training), real
                                pod silhouettes from each prize's own pool's biomes -- the
                                owner's uploaded picture pod by pod (GameConfig.WheelPodArt),
                                frames for a biome with none (Dustbowl) -- and the
                                TITAN / COLOSSAL lettering, whose light the caller steps
                                (WheelUI: only while the panel is open or the wheel is near)
    Shared/BloomTrail.luau      the Bloomrunner Trail's look as arithmetic: what Full / Reduced /
                                Off draw and each wearer's caps, the two ribbons' weave by road,
                                the shimmer's colour frames, petals and flowers laid by road with
                                rate caps, their flight and opening curves (pure; TrailFX draws)
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
    SafeZoneMarking.luau        the SAFE ZONE words and two shields on the grass at the entrance (2026-10-04;
                                NOT a *Service): a Top-face canvas runs along the plate's Z, so its plate is
                                turned a quarter -- presentation only, inert
    PlotService.luau            who owns which plot, puts them on it, TELEPORT TO PLOT, and
                                BIOMES' one landing (the Greenhollow entrance)
    ProfileSchema.luau          what a profile is, and the validator (NOT a *Service). It
                                drops a held row that is not a plant and never cuts the list
                                to Save.MaxHeld: a record saved with more comes back whole
    SaveService.luau            DataStore transport, session locking; an inviter's inbox (i_<userId>)
    PlayerDataService.luau      profiles in memory, autosave, replication
    CreatureModel.luau          pods and creatures (NOT a *Service)
    ParentModel.luau            Greenhollow guardian + biome dispatch (NOT a *Service)
    BramblebackModel.luau       Dustbowl guardian geometry and seventh-seam rig
    NestService.luau            nests, and the parent that sleeps beside them; the server owns
                                every guardian's physics (pinToServer), one chase at a time,
                                later thieves remembered and chased next; a lost guardian (rig
                                gone, dead, fallen) is rebuilt by the tick from its nest's own
                                recipe -- the rig only, never the nest or its pods
                                (GameConfig.Parent.Recovery; GuardianRecoverySpec)
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
                                row being added, never cuts one off. Also the ONE writer of
                                WalkSpeed (RefreshWalkSpeed), a running DISCO ONLY mini event's
                                x1.5 for everybody included (2026-10-04). DropHeldPod is the
                                one drop a hit asks for: a raid carry OR a banked pod held as
                                a Tool (its row comes off through SyncHeldNow), never a plant
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
    PlotShowcaseService.luau    each plot's TOP CREATURES (2026-10-05): its two best grown creatures,
                                written as plain attributes on its board only when the Planted tag or
                                a planted model changes -- one publish a burst, no loop, no remote
    TreadmillService.luau       THE FAUCET for Speed -- stand on your own mill; and the giant
                                shared Disco Mill a mode with a Mill builds in front of the hub
                                (TICKET DISCO, DISCO + MILL -- never the pure DISCO ONLY; its
                                riders paid their own training x10, composed once, 2026-10-04)
    SellService.luau            the sell-all board beside the stall
    InviteService.luau          INVITE A FRIEND (2026-10-06): a first-time joiner whose ReferredByPlayerId
                                names an inviter counts once for them, forever (profile.InviteIds); an
                                inviter elsewhere gets it through their inbox; forms given once through
                                CarryService.GiveHatched (InviteGranted, InviteSeen); notices held until
                                the client's READY; builds the hub pedestal; SimulateJoin is Studio-only
    DebugService.luau           Studio-only server test helpers; no UI or remote
    AdminService/               the dev console for two allowlisted UserIds, live servers
      init.luau                   every request checked here; grants, progress reset, night/day,
                                  and Announce (handed to AnnouncementService after the allowlist)
      AdminConsoleUI.client.luau  its panel -- cloned ONLY into an admin's PlayerGui, never shipped;
                                  the compact ADMIN CONSOLE (2026-10-04): BROADCAST, EVENTS, WEATHER,
                                  ITEM GRANTS, PLAYER TOOLS, ADVANCED -- a sidebar on a desktop, a
                                  dropdown on a phone (MenuKit + MenuLayout, its own gui SeedAdminPanel)
    AnnouncementService.luau    admin announcements (filtered, cooldown, THIS SERVER or ALL SERVERS
                                through MessagingService, deduped, expiring; never published from
                                Studio) and game.ServerRestartScheduled's notice, both as Workspace
                                attributes every client reads
    OwnerTitleService.luau      the cosmetic rainbow ADMIN title over the owner's head only
                                (AdminService.IsOwner, by UserId), rebuilt on every character
    WeaponShopService.luau      Marigold's counter: buying, equipping, and the one Tool
    CombatService.luau          what a bat and a trap DO -- knockback, restraint, cleanup. A
                                swing is live for a short window swept by the one Heartbeat;
                                a trap is server STATE (no model) drawn for its owner alone,
                                up to three per player; no recharge, no expiry; a catch CONSUMES
                                it (2026-10-05, consumeTrap: claimed before the effect, one victim)
                                and starts its owner's 10-s trigger cooldown, refused for every
                                type (TRAP_COOLDOWN), kept through REMOVE and a respawn; REMOVE
                                (newest first, the sender's own) is the one client request, a
                                lost floor or a departed owner clears a trap, a death never does;
                                every hit and every trap drops the held pod FIRST (2026-10-04)
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
    PlantUI.client.luau         the hatch countdown over an unhatched pod, and (2026-10-04, the
                                owner's brief, superseding "no label on a grown plant") every
                                grown creature's overhead label (PlantLabel): faded by camera
                                distance, hidden while PICK UP selects it, the OWNER's rate
    PlotShowcaseUI.client.luau  every plot's TOP CREATURES board on this screen (2026-10-05): each face
                                a SurfaceGui in the PlayerGui ADORNED to the plank -- one under the
                                Workspace draws no ViewportFrame at all (a Roblox rule; v1027 shipped
                                it that way, cards without creatures); drawn
                                from the board's attributes at the plot's published rate, hidden on
                                a free plot or a garden not yet known, its pictures and rarity light
                                only while the camera is near (freed when far); it is a sign, not a
                                plant visual, so OTHER PLANTS does not hide it
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
    PlantSway.client.luau       idle lean, the hatch shake, and the grown-plant walk; a plant hidden
                                by OTHER PLANTS is passed by and posed again when shown
    OtherPlantsUI.client.luau   the OTHER PLANTS: ON/OFF switch (2026-10-05): Walk Mode's look, no
                                remote -- it flips the local preference and starts PlantVisibility;
                                on a phone, like WalkModeUI's, a see-through 128 x 28 row under
                                Shop: the words inline, a 40 x 18 track with ON/OFF in it
                                (HudLayout `switchInline`, Phone.Switch)
    CashUI.client.luau          corner HUD: cash + speed, from the ProfileUpdated remote; the x2
                                card (MoneyBuff) beside the amount -- on a phone with no plate or
                                stroke, never left of HudLayout's `buffMinX` (2026-10-05)
    CashPop.client.luau         lime +$N rising off every grown plant (cosmetic only): the
                                OWNER's rate (GameConfig.gardenIncomeMultiplier), starting above
                                a showing overhead label (2026-10-04)
    IndexUI.client.luau         LEFT rail (on a phone the top-right row; the owner's studded picture on
                                every screen, 2026-10-05/06): the compact almanac (2026-10-04) as ONE
                                scrolling page since 2026-10-06 -- every biome in road order over the
                                studded baseplate (MenuKit.baseplate), each under its own heading (the
                                progress row: count, bar, harvest, its own CLAIM), square cards,
                                in-panel detail with Back, search + All/Grown/Missing; ??? until grown
    ShopUI.client.luau          LEFT rail (on a phone the top-left corner; the owner's wide studded
                                picture wherever its slot is wide, 2026-10-05/06): the compact shop
                                (2026-10-04) as ONE scrolling page since 2026-10-06 -- every shelf derived
                                from GameConfig.Store under its heading (+ Spin Tickets while
                                WheelPaidAllowed, bought the wheel's way through WheelBuy, REWARDS & ODDS
                                in the header) over the studded baseplate, cards with RobuxPrice prices,
                                SOON / OFF SALE / OWNED / OPENING, details with Back. Prompts only;
                                StoreService's receipt grants
    GardenUI.client.luau        RIGHT rail: MY PLANTS (2026-10-04) -- PLANTED / STORED cards, plot count,
                                garden income; PLANT, RETURN TO BAG, EQUIP BEST, UNEQUIP ALL asked of
                                PlantService (GameConfig.Plant.MyPlants); pods keep their clocks
    EventsUI.client.luau        EVENTS (2026-10-04): the owner's POSTED Roblox experience events, read on
                                the client (SocialService) when the panel opens -- rows soonest first,
                                details with Back, NOTIFY ME through Roblox's own RSVP prompt, LIVE NOW
                                while one runs. Button beside Settings (desktop), under the Bag in
                                compact, the first square of the panel under the Bag on a phone
                                (HudLayout `events`). Advertises only: it starts, stores and
                                announces nothing
    UpdateLogUI.client.luau     WHAT'S NEW (2026-10-05): the UPDATES square (native scroll icon, no
                                upload; a NEW dot while UpdateLog.isNew, off once opened THIS session --
                                never saved) where HudLayout `updates` puts it, hidden where that is
                                empty; the rim-themed panel of light cards (MenuLayout.updatesPanel,
                                engine-sized, a short log a short panel) on the OpenPanel mutex
    InviteHub.client.luau       INVITE A FRIEND: this player's own form on the hub pedestal (client-local,
                                SecretModel.BuildDisplay), its evolve moment, the sign's words and bar
                                (a PlayerGui SurfaceGui adorned to the shared plate), the prompt
    InviteUI.client.luau        the INVITE button (Rail.StuddedInviteArt), its gold "!" (Rail.InviteBadge,
                                from the server's InviteSeen), the INVITE panel (MenuLayout.invitePanel /
                                inviteBlocks: hero, studded bar, the four cards, INVITE FRIENDS) and the
                                +1 INVITE / WELCOME! / PLANT STORAGE FULL notices
    InviteRewardUI.client.luau  the reward card per form given: no dimmer, never modal, auto-closes,
                                MenuLayout.rewardPopup (tall on a desktop, wide on a phone) clear of
                                HudLayout.occupied; queued lowest first behind every reward moment
    SpeedFX.client.luau         +N pops on Speed gain, and the run streak (off on the obby course)
    BiomeGuideUI.client.luau    advisory Speed banner on biome entry
    CarryPose.client.luau       both arms under the pod while carrying
    MarigoldShopUI.client.luau  Marigold's Garden Goods -- opened by her prompt
    WeaponFX.client.luau        how a bat is HELD and SWUNG -- poses the right
                                arm, and the impact burst
    LoadoutUI.client.luau       the Bag and the hotbar. Since 2026-10-03 the hotbar is FREELY
                                ASSIGNED (HotbarSlots): ten slots on a desktop, five on a phone,
                                saved by item id; the Bag is a compact grid (InventoryModel /
                                InventoryPanel). The BAG cell counts plant storage (profile.Held
                                + a carried pod) / Save.MaxHeld. Drawn by HotbarCard; the item's
                                name pops up over the strip on an equip and under a mouse. A
                                trap slot shows its "3x" and, with a trap out, REMOVE stands over
                                the trap's own slot (TrapRemove; the Bag menu has the same
                                action) -- 2026-10-04; while the owner's trigger cooldown runs
                                EVERY trap slot is dimmed and counts it down (2026-10-05)
    RailDrawerUI.client.luau    TOUCH ONLY: the panel under the Bag (HudLayout `dock`, 2026-10-05;
                                the left edge's shutting dock before) that INVITE, EVENTS, WHAT'S NEW
                                and Settings stand down -- a scrolling viewport (`dockView`, squares
                                never under MinTile) and the handle that shuts it (2026-10-06; session
                                only, SeedDockShut), the handle wearing a square's badge while shut --
                                and the frame they stand in, hidden while a centre panel is open
    TrapUI.client.luau          the red countdown over a trapped player (amber SLOWED)
    TrapMarks.client.luau       THIS player's own placed traps, drawn locally from the records
                                CombatService puts in their PlayerGui -- nobody else is sent
                                one; the set-down and arming sounds play here (2026-10-04); a
                                consumed record is erased with its drawing (2026-10-05) -- the
                                server's public snap stands in its place
    ActionToastUI.client.luau   draws every short notification (Notice): refusals, successes,
                                warnings, information -- text-led, stacked just over the icon
                                row over the belt, on every screen (a phone's at its own size)
    BoostIconsUI.client.luau    the active-boost icon row over the hotbar and its one popover
                                (tap, DPadDown on a controller); read-only, publishes its count
                                for HudLayout (2026-10-04; replaced the rain chip, the mini line
                                and the boost row)
    HatchBonusUI.client.luau    the hatch bonus's notice after the reveal and the guide's
                                congratulations, then the once-only dismissible like reminder
    BonusChestUI.client.luau    the chest's sign and prompt; a confirmed claim's RewardSplash,
                                once per claim, flying to the boost's icon (BoostIconsUI)
    CommunityChestUI.client.luau  the community chest's glowing, drifting rainbow FREE (the wheel
                                sign's drift at twice its speed) and claimed state; the
                                step pad asks the server first, once per visit; only a
                                non-member sees GroupService:PromptJoinAsync, then a verify
    SacrificeUI.client.luau     the pedestal's confirmation (the pod, what it buys, KEEP POD /
                                SACRIFICE), its two signs' own line and its prompt
    PlotTeleportUI.client.luau  TELEPORT TO PLOT under the clock (on a phone's top row, where it
                                says just PLOT with no icon, 2026-10-05), alive and in the Safe Zone
    ObbyUI.client.luau          the obby's moving platforms (from server time), crumbles and
                                spring throws under your own feet, the run line and RETURN TO
                                PLOT (HudLayout `returnPlot`: on a phone's row over BIOMES' and
                                PLOT's span, words only); on a phone the run's clock alone, each
                                stage's name said once as a notice
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
    TrailFX.client.luau         the Bloomrunner Trail behind whoever wears it (cosmetic only):
                                two weaving mint/gold ribbons with a travelling shimmer, petals
                                and now and then a flower, from one pool built per body and one
                                Heartbeat (BloomTrail's numbers); only while the body covers
                                ground; Reduced = one still ribbon, Off = nothing; not drawn on
                                the obby course, like SpeedFX's run streak
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
13. **Plant visuals honour OTHER PLANTS** (2026-10-05). Anything a client draws for a `Planted`
    model -- a label, a pop, an idle, a glow, an arc -- reads `PlantVisibility.Marker` (or
    `PlantVisibility.isHidden`) and stands down while it is set. Hiding is PlantVisibility's
    `LocalTransparencyModifier` alone: never write Transparency or Enabled to hide a plant, and
    planted lights stay PlantGlow's switch.

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
