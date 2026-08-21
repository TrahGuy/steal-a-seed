# Steal a Seed — Session Handoff

> Living document. **Read this first when picking up the project. Update it before ending any
> session, then commit and push** (see the git policy in [CLAUDE.md](../CLAUDE.md)).
>
> [PLAN.md](PLAN.md) is what we are building and in what order. [BLUEPRINT.md](BLUEPRINT.md) is the
> reference design. This file is where things actually stand.

---

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

## Still open

  * **The cash cap.** PLAN.md picks 1e15 and then the footage showed the reference game running at
    2.7B/sec, which reaches that in about four days of idling. Must be settled **before the save
    schema is written**.
  * **SpeedGate values are known to be wrong** — spaced correctly relative to each other, absolute
    numbers meaningless until the treadmill exists and there is a measured rate to scale against.
  * **The repo FOLDER is still `D:\KAPE\Steal an Artifact`.** The Roblox place itself was renamed
    to "Steal a Seed" by the owner on 2026-08-21.
  * **Offline income.** Deferred in the plan; the reference advertises it in a banner across the top
    of the screen as the reason to come back tomorrow.

## Next

`PlayerDataService` + `SaveService` — profiles, and the schema whose central question (does the
plot id persist?) PlotService has now answered: **no**. Then the seed → carry → planter loop that is
Phase A's actual success criterion.

`PlotService` is done and hooked: `OnAssigned` / `OnReleased` are the seam a profile service
restores and saves through, and `OnReleased` deliberately fires **before** the plot is cleared so
there is still something left to read.
