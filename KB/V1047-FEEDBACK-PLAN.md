# MICHAEL'S v1047 REPORT — three fixes now, seven owner calls (plan, 2026-10-10)

**Status: APPROVED 2026-10-10** (the owner: "approve all your picks, start batch 1, terminal will
still work"). Every recommendation was taken:

1. Batch 1 (fixes 1-3): go, now.
2. Hotbar items also show in the Bag, framed with their slot number. This reverses the 2026-10-03 rule.
3. The size word on pod cards.
4. HOLD TO HATCH for a held READY pod; no Instant Hatch on a held growing pod.
5. ~~Tapping a bed with a READY pod hatches it there.~~ **Replaced the same day** (the owner: "i think
   we also need to make the pods placeable on plots again too"): **pods can be planted in a bed again**,
   as before 10-09, or left to hatch in the Bag. The defaults, told to the owner:
   - planting keeps the time the pod has left (its Bag row's HatchAt; before 10-09 the timer restarted);
   - in the bed: its countdown, INSTANT HATCH while growing, the hold-E Hatch when ready;
   - it takes a bed like a plant, and thieves can't take it.
   The nursery shelf stays a later idea.
6. Carriers have full hands: the bat is put away, and there are no swings and no traps while carrying.
7. No ground drop.
8. Signs: REBIRTH x1.5, BAT SHOP! x1.1 where it hangs, Pod Guide boards x1.5 with the stands 3.5 studs further in.

Batch 1 is being built first.

## Why

Michael's first report on v1047 (published 2026-10-09 16:31 UTC), passed on by the owner on
2026-10-10. In his words, shortened:

> The new signs look good! But I think you should scale up the size on them 50% maybe.
> When using the spin wheel on console it deselects the wheel and goes up to the teleport options
> after each spin.
> Eggs in the hotbar don't have a put away prompt. I had to buy a bat to stop carrying my massive egg.
> In the rain biome I got hit right at the timer and wasn't teleported out. Not sure if you can just
> stand in there after nightfall but def can get ragdolled and skip the teleport.
> No way on console to swap items from hotbar to your bag.
> Players are confused by not being able to place the pods in their pen.
> No way to view the size of eggs in the hotbar. Maybe they should appear in the bag as well but with
> a frame and icon for the hotbar number.
> Also no way to hatch the egg in your hotbar without navigating to bag and hatch all.
> Should we have a drop option when holding an egg?
> If you have the bat equipped when you pick up an egg you still hold the bat and you can still
> swing. Don't know if it hits anyone or not.

"Eggs" are pods. Four read-only code investigations traced each point; the key lines were checked
again by hand.

## What we found (code facts)

| # | Michael's point | What is going on | Where |
|---|---|---|---|
| 1 | No "put away" for a held pod | **A bug this update brought in.** With a pod in hand, the put-away controls are switched off: Q, the touch PUT AWAY button and B on a controller. Pressing the slot again still works on PC and touch. A controller with only one filled slot has no way to empty its hands: LB/RB land on the same pod. | `PlantPlace.client.luau:721-725` (from aad1639) |
| 2 | The console wheel loses its selection after each spin | SPIN stops being selectable while the wheel turns, so the engine moves the selection out of the panel, to TELEPORT / BIOMES / OBBY. Nothing puts it back after the spin. **The next A press then asks for a teleport.** The CLAIM button does the same when it hides. | `WheelUI.client.luau:1391`, `2494-2496`, `2726-2727`; `PlotTeleportUI.client.luau:181-194` |
| 3 | Ragdolled at the rain's end: not teleported out | The evacuation has no ragdoll check. A knocked-down body is moved by the player's own computer, which keeps pinning it where it landed for up to 1.5 s, so the server's teleport is undone. A guardian throw still in flight can also set a body down at the nest entrance, inside the biome. The rain can then finish while that player is down. **Nobody can stay, though.** When the rain finishes, the biome is removed and anyone still there falls and respawns. Being in the rain biome at night while the rain still runs is intended. | `WeatherService.luau:339-397, 418-429`; `ThrowFX.client.luau:1667-1760`; `NestService.luau:4551-4587` |
| 4 | No way on console to move items from the hotbar to the Bag | Items on the hotbar are left out of the Bag's grid (the owner's 2026-10-03 rule). "Remove from hotbar" lives only in a slot's menu: right-click, or a long hold on touch. A controller reaches a hotbar slot only through the View button, and nothing binds a button to a slot's menu. | `InventoryModel.luau:493-494`; `LoadoutUI.client.luau:517-583, 2237-2277` |
| 5 | Players can't place pods in their pen | **Designed that way.** Beds hold plants only, and tapping a bed with a pod shows "HATCH IT IN YOUR BAG" (KB/STEAL-MORE-PLAN.md). The starter pod still grows in a bed, so a new player's first pod sits in the pen and every later one can't. | `PlantService.luau:2185-2186, 3307-3330`; `ActionRefusal.luau:175, 255-259` |
| 6 | A pod's size isn't visible on the hotbar | The card fills the slot with the picture, so every size looks alike. It shows only the slot number and READY or a countdown. The hover name is "Greenhollow pod". The size appears only on Bag tiles, which hotbar items never reach, and in the slot's hidden menu. | `UIKit.luau:4421-4438`; `HotbarCard.luau:436-442`; `LoadoutUI.client.luau:984` |
| 7 | No way to hatch a hotbar pod without the Bag's HATCH ALL | Activating a held pod does nothing, and tapping a bed is refused. The only hotbar-side hatch is the slot's hidden menu (right-click, or a 0.45 s hold on touch). The server's single-pod hatch (`BagHatch`) already finds a pod held in the hand. | `LoadoutUI.client.luau:517-525`; `PlantService.luau:2323-2334, 3210-3236` |
| 8 | Should there be a drop? | There is no player drop today. A pod you drop would lose its owner and its timer. Any visitor standing in your field could pick it up and bank it within 0.2 s, a free transfer. | `CarryService.luau:1241-1309, 1411` |
| 9 | The bat stays in hand when you pick up a pod, and still swings | A carried pod is a welded model, not a Tool, so the bat stays equipped. **The server accepts the swings and the hits**: the victim is knocked down and drops their pod. Placing a trap works too. This is **deliberate today**: "whether a carrier may swing one is a combat rule this does not get to change", and CarryHandsSpec §3 and §5 require it. | `CarryService.luau:773-774`; `CombatService.luau:1252-1322, 1395-1515, 1860-1864` |
| 10 | Scale the new signs up 50% | New signs in v1047: **BAT SHOP!** (Marigold's stall), **REBIRTH** (the shrine) and the **five Pod Guide boards**. Marigold's counter word also changed from SELL to SHOP. BAT SHOP! and REBIRTH are the only new signs in the hub, a pair, seen on joining. The Pod Guide boards have the smallest print. | `MarigoldSign.client.luau:38-54`; `RebirthUI.client.luau:70-90`; `PodGuideStand.luau`; `GameConfig.luau:802-811, 6009-6017` |

## The plan

### Batch 1: fix now (bugs; no design change)

1. **Put away a held pod again.**
   - Q, the touch PUT AWAY button and B on a controller work for a held pod, as they did before 10-09.
   - The placement disc, the reticle and RT stay plant-only.
   - About 5 lines in PlantPlace; a ControllerSpec check.
2. **The wheel keeps the controller on SPIN.**
   - SPIN stays selectable during a spin. Presses mid-spin are already ignored.
   - After a spin, and when CLAIM hides, the selection returns to the panel's first button, the way the confirm sheet already does it.
   - This also ends the accidental teleport on the next A.
   - About 6 lines in WheelUI's `paint()`; a WheelSpec check.
3. **The rain's evacuation waits out a ragdoll.**
   - Players who are down are skipped until they stand. Then they are moved on the next tick.
   - The biome stays up while anyone inside is down, for 15 s at most (a guardian throw lasts about 12 s).
   - "Evacuated" is told once, after the move has really happened.
   - Carried pods banking on evacuation stays as it is (the owner deferred that).
   - About 30 lines in WeatherService; new RainEventSpec cases.

### Batch 2: needs the owner's yes (recommendations in bold)

4. **Hotbar items also show in the Bag.** This is Michael's idea.
   - Each shows with a frame and its slot number: the badge phones already use for slots 6-0.
   - It fixes three of his points at once:
     - on a controller, A or RT on that tile opens its menu, with **Remove from hotbar**;
     - pod sizes show on the Bag tiles;
     - a hotbar pod gets HOLD TO HATCH in the Bag.
   - The 0/24 count does not change; it already counts them.
   - It reverses the owner's 2026-10-03 rule that hotbar items are not repeated in the Bag.
   - If no: RT on a selected hotbar slot opens its menu instead. That works, but on a controller a slot can only be selected through the View button, which players don't find.
5. **Pod size on the hotbar card.**
   - A pod's card shows its size word (TINY to COLOSSAL) across the top, in its tier colour.
   - The hover name reads "Greenhollow pod · Titan".
   - Pods stay out of the coming rarity edges, as already planned.
6. **Hatch from the hand.**
   - Holding a READY pod shows a **HOLD TO HATCH** button by the hotbar: the same 1.1 s hold as the Bag's, and RT on a controller.
   - Holding a growing pod shows "READY IN 2:13".
   - It uses the same server hatch as the Bag. The plant goes to a free bed, else the Bag.
   - Instant Hatch (the Robux product) for a held growing pod is left out unless the owner wants it.
7. **Pods in the pen.**
   - Tapping one of your beds while holding a **READY** pod hatches it into that bed. It feels like placing it, and beds still never hold pods.
   - With a growing pod, the message says when it will be ready ("READY IN 2:13 — then tap a bed").
   - This also matches the starter pod's lesson, where the first pod goes in a bed.
   - A nursery shelf that shows growing pods on the plot stays a later idea.
8. **Hands full while carrying.**
   - Picking up a pod puts the bat away. A carrier cannot swing or place traps, checked on the server.
   - The thief runs; the chaser hunts.
   - Today this is deliberately allowed; CarryHandsSpec §3 and §5 flip, and BatHitSpec gets a case.
   - If the owner prefers carriers to keep self-defence, nothing changes and Michael is told it is intended.
9. **No ground drop.**
   - Put away (fix 1) solves "I can't get rid of it".
   - A ground drop would let a visitor take and bank your pod in your own field, and the pod would lose its timer.
10. **Signs:** which ones did Michael mean? Most likely BAT SHOP! and REBIRTH.
    - **REBIRTH x1.5:** a config change; nothing stands near it.
    - **BAT SHOP! x1.1:** the most it can grow where it hangs, between Marigold's prompt panel and SPIN THE WHEEL! above it (FloatingSignSpec's clearances). A true x1.5 needs a new spot: the owner picks it, or the wheel's own words move up too.
    - **Pod Guide boards x1.5:** config, plus moving the five stands 3.5 studs further in from each arch (PodGuideSpec's inset), with the props by each arch measured again.

### After these

Yesterday's queue, unchanged: the tutorial's world hand clear of the HUD, the minigame button left of
the column, rarity edges, then the 100 rebirth titles.

## Testing (the owner's lean rules)

- **Specs** for each item. HudLayoutSpec only if a HUD element moves. The full suite runs once, before the push.
- **One guarded Play** for Batch 1:
  - a guardian throw at the rain's close, then the teleport once the player stands;
  - put-away of a held pod on desktop;
  - the wheel with controller mode forced.
- **Controller buttons can't be pressed from here.** The wheel fix, B put-away and Bag-on-controller are proven by specs and a forced-controller look. Michael confirms on his Xbox after the next publish.
- Each batch is its own commit on wip, pushed. Nothing is published by an agent.

## Decisions for the owner

1. Batch 1 (fixes 1-3): go?
2. Hotbar items also shown in the Bag (Michael's idea), or keep the 2026-10-03 rule and bind RT on a hotbar slot?
3. The size word on pod cards: yes?
4. HOLD TO HATCH for a held READY pod: yes? Add Instant Hatch for a held growing pod?
5. Tap a bed with a READY pod to hatch it there: yes? Nursery shelf later: yes or no?
6. Carriers: hands full (bat away, no swings, no traps), or keep self-defence?
7. No ground drop: agreed?
8. Signs: which ones, and are REBIRTH x1.5, BAT SHOP! x1.1 (or a new spot) and Pod Guide x1.5 right?
