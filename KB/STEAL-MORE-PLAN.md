# More stealing, less waiting — plan for the owner's approval (2026-10-09)

**Status: PHASE 1 BUILT 2026-10-09** by the terminal Claude: uncommitted and not published; see the
HANDOFF entry "MORE STEALING, LESS WAITING (Phase 1)". The owner approved it ("approve, let terminal
work") with every recommendation taken:

1. pods hatch in the Bag;
2. a 60-pod cap, with plants staying at 24;
3. the hatch ladder is kept as it is;
4. a hatched plant goes straight into a free bed (else to the Bag).

**Phase 2 is NOT approved.** Each of its items needs its own yes later. None of it is built.

## Why

Michael (playtester and fellow developer) on the first 30 minutes:

> In your game the biggest limit i hit at least in the first 30 minutes is:
> - egg hatching time
> - number of eggs i can steal/hatch being limited
>
> I dont think you need a full overhaul like my game needed

So this is **not an overhaul**. It removes the two limits and keeps the steal-run-bank loop exactly
as it is.

## How it works today (facts from the code)

| What | Today | Where |
|---|---|---|
| Banking | The pod goes into the Bag as a Tool (`SpeciesId`, tier, `Hatched=false`), saved as a `profile.Held` row | `CarryService.luau:1877, 1916-1927, 2320-2326` |
| The Bag | `MaxHeld = 24`. It counts **pods and plants together**, plus 1 for a pod in the arms. When full, a steal at the nest, a bank, a hatch, a pickup, Equip Best and `GivePod` are all refused. Nothing is lost | `GameConfig.luau:10431`, `CarryService.luau:2721-2737` |
| Growing | A pod must be **planted in a garden bed** to grow. **Beds are shared** by growing pods and earning plants | `PlantService.luau:2059, 2136-2138` |
| Beds | Capacity 5 / 7 / 10 / 15 / 20 / 25 / 30 by plot tier. Costs 0 / 25K / 250K / 2.5M / 25M / 250M / 2.5B | `GameConfig.PlotTiers` (687-695) |
| Grow time | Tiny 30 s, Big 1 m, Huge 2 m 30, Mega 6 m, Giant 15 m, Titan 35 m, Colossal 1 h 15. This is the owner's ladder from 2026-09-17, asserted at load | `SeedData.luau:2170` |
| Odds | Tiny 53%, Big 16%, Huge 10%, Mega 8%, Giant 6%, Titan 6%, Colossal 0.5%. The average pod takes about **4.7 min**, but **1 pod in 8 takes 15 min or more**, holding one of your 5 beds the whole time | `SeedData.Tiers` (890-898) |
| Hatching | Hold 1.1 s on the bed. The plant goes **into the Bag** and the bed empties, so the player has to **place the plant again** to earn. The starter pod is the one exception: it hatches in place | `PlantService.luau:1681-1772` |
| Earning | Only planted, grown plants earn. Offline earnings pay grown plants at 50%, after 20 min away, capped at 8 h | `EconomyService.luau:136-158`, `OfflineEarnings.luau` |
| Instant Hatch | 99 R$ (product 3713212811). It skips the wait on one planted, growing pod. Unused purchases are saved as credits (`InstantCredits`) | `PlantService.luau:1278`, `GameConfig.luau:7011-7014` |
| Selling | Income per second × 30. SELL ALL takes pods and plants, except favourites and invite plants | `EconomyService.luau:403-560` |

**What that means in play:** each pod costs a bed for its whole wait, plus two placements (the pod,
then the plant) and a hatch. With 5 beds, one Titan holds a fifth of your garden for 35 minutes.
Stealing more than your free beds is pointless, and a full Bag of 24 (pods and plants together)
stops stealing altogether.

## Phase 1 — the two limits (the core)

### 1. Pods hatch in the Bag, not in garden beds

- **The timer starts when the pod is banked.** The deadline is saved on its Bag row as absolute time,
  so it keeps running offline, as planting does today.
- **Pods never take a bed. Beds hold plants only.** Those beds are the pen Michael means: the limit on
  how many hatched plants you keep earning.
- **Ready pods:** a ready pod shows **READY** in the Bag and on the hotbar. Pressing **HATCH** (the
  same 1.1 s hold) hatches it. **HATCH ALL** in the Bag hatches every ready pod. The same hatch moment
  plays: rattle, crack and the rarity reveal sound.
- **Where the plant goes:** straight into a **free bed** (auto-planted, with the hatch effect playing
  at that bed). If no bed is free, it goes to the Bag.
- **Instant Hatch** moves with the pod. It is offered on a growing pod in the Bag: same product, same
  price, same saved credits.
- **Old saves:** pods already planted keep growing and hatch where they stand, exactly as today. Pods
  already in the Bag get their timer stamped when the save loads (now + their grow time).
- **Placing a pod** in a bed is refused with "Pods hatch in your Bag now". There is one path, so
  nobody is confused.
- **Effect:** every stolen pod grows at the same time. A Titan no longer blocks a bed. Each pod costs
  one press (hatch), not three steps.

### 2. Pods get their own room in the Bag

- **Pods stop counting toward the 24.** Plants keep their 24.
- **Pods get their own cap: 60** (suggested). Stealing is refused only when you hold 60 pods.
- **Why a cap at all:** every pod is a saved row and a Tool in the Backpack. 60 keeps saves small and
  the Bag and hotbar responsive. With pods hatching in about 5 minutes on average, nobody should reach it.

### 3. The hatch ladder: keep it for now (owner decides)

- With every pod growing at once, the waits mostly stop mattering. The recommendation is to **keep the
  owner's ladder** for Phase 1, playtest, then decide.
- **Option, if testers still feel the wait:** trim only the top two rungs: Titan 35 m to 20 m, Colossal
  1 h 15 to 45 m.
- The ladder is asserted at load (`SeedData.luau:2170`), so any change is a deliberate owner call.

### 4. The guide and analytics follow the new order

- **Guide:** steal, bank, hatch (in the Bag), place the plant. The words change; the steps stay the
  same seven.
- **Onboarding funnel:** step 4 becomes "First Plant Hatched" and step 5 "First Plant Placed"
  (swapped). Before and after the update cannot be compared at those two steps.
  `KB/ANALYTICS.md` is updated to match.

### 5. Balance: no numbers change in Phase 1

- **Income** still comes only from planted plants, and beds still cap it (5 at the start). So income
  per second does not jump.
- **What rises:** how fast players find better plants to keep, and how many spares they sell (each
  sells for 30 s of its income).
- **Watch:** Instant Hatch sales. They should drop for small pods and hold for Titan, Colossal and the
  Rain pods (3 to 9 h).

### What players notice

- Steal as much as you like (60 pods).
- All your pods grow at once, in your Bag.
- One press hatches them, and plants go straight into your garden.
- Beds are for plants. Bigger plots mean more earning plants, not more waiting room.

### What the build touches

- `CarryService`: stamp the hatch deadline at bank; split the Bag room into pods and plants.
- `PlantService`: hatch from the Bag; auto-place; refuse pods in beds; Instant Hatch on a Bag pod;
  grandfather planted pods.
- `ProfileSchema`: a deadline on pod rows; migrate old pod rows.
- `GameConfig`: `MaxPods`; the words.
- `LoadoutUI` / `InventoryPanel` / `InventoryModel`: timers, READY, HATCH and HATCH ALL.
- `GardenUI` / `GardenPlan`: Equip Best no longer subtracts growing pods.
- `StoreService`: the Instant Hatch target.
- `TutorialService` / `TutorialUI`: the order.
- `Metrics` and `KB/ANALYTICS.md`: the funnel.
- `HatchFX` / `HatchBonusUI`: where the hatch moment plays.
- **Unchanged and checked:** `EconomyService` selling and `SacrificeService` (it already takes pods from
  the Bag).
- **Specs:** a new `HatchInBagSpec`; the carry, plant, garden, store, tutorial and analytics specs
  updated.
- **One guarded Play on the phone:**
  - steal 3 pods and watch the timers;
  - HATCH ALL, with plants landing in beds;
  - a full garden sends plants to the Bag;
  - the 60-pod refusal;
  - an old save with planted pods;
  - Instant Hatch on a Bag pod, using a credit only (no real purchase).

### Costs and risks

- **Plots stop showing growing pods.** Only plants stand there. If the owner misses the look, a small
  nursery shelf of the next ready pods could come later.
- **Save migration:** old pod rows have no deadline, so they get one at load. Planted pods keep theirs.
- **Instant Hatch** income may dip for small pods.

## Phase 2 — make stealing pay directly (optional; each item needs its own yes)

| Item | What | Today | Note |
|---|---|---|---|
| a. **+SPEED per banked pod** (Michael's "+1 style") | Each banked pod gives Speed worth N seconds of your current mill, more for rarer pods, with a big "+SPEED" pop | Speed only from the mill, shop, wheel, obby and Harvest | Michael: the treadmill should stay the higher rate, so keep N small (30 s suggested) |
| b. **Sacrifice for permanent upgrades** (Michael's active path) | Feed spare plants or pods to the pedestal for permanent upgrade points (Speed, income) | One pod gives ×1.5 income for 45 s, then a 3 min wait; nothing permanent (`SeedData.Sacrifice`) | Needs its own design and plan |
| c. **The mill trains while you are offline** (Michael: "afk is when i log off") | Offline training at a share of your mill rate, capped like offline earnings | None. The old Training Rush was removed 2026-10-05 | Same claim card as offline earnings |

## Decisions for the owner

1. **Pods hatch in the Bag:** yes / no. (Recommended: yes.)
2. **Pod cap:** 60? Plants stay at 24.
3. **Hatch ladder:** keep it for now (recommended), trim Titan and Colossal, or halve the early rungs.
4. **Hatched plant:** auto-placed in a free bed (recommended), or always to the Bag.
5. **Phase 2:** which of a / b / c, now or later. Each gets its own plan.
