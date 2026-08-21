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

## Still open

  * ~~The cash cap.~~ **Settled at 1e15** — see SAVING below.
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
