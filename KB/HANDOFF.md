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

## Still open

  * ~~The cash cap.~~ **Settled at 1e15** — see SAVING below.
  * **RecommendedSpeed** is advisory: Greenhollow 0, Dustbowl 167M, Tanglemire 800M, Emberroot 3B,
    Starbloom 10B. These numbers tune chase readiness and progression milestones; they do not
    restrict daytime entry.
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
