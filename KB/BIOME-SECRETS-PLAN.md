# A SECRET IN EVERY BIOME — the plan (2026-10-16)

**Status: APPROVED 2026-10-16**, in two steps, built by Claude (desktop).

The owner pasted a new secret pod and a secret creature for every biome into ServerStorage:

| Biome | Pod | Secret |
| --- | --- | --- |
| Greenhollow | "Secret Grenhollow Pod" (with its PodOpening script) | Grovemaw (62 joints) |
| Dustbowl | "Dustbowl Secret Pod" (SunPulse) | Scourwheel (11 joints) |
| Tanglemire | "Tanglemire Secret Pod" | Mirehydra (52 joints; MirehydraAura) |
| Emberroot | "Emberroot Secret Pod" | Cinderdrake (56 joints; CinderdrakeAura) |
| Starbloom | "Starbloom Secret Pod" (MawPulse) | Nebulisk (32 joints; NebuliskIdle) |

The owner's brief:
- one at a time, very rare (5% a cycle);
- the rain biome's secret toast;
- in the Index with their usual background, sizes kept;
- a pod too big for the nest goes on the other side;
- the guardian as fast as Storm Strider;
- "they should not spawn during pod rush";
- "they're already rigged so you animate them too".

## The owner's answers

| Question | Answer |
| --- | --- |
| The old secrets (Snarlbloom, Petalfawn)? | **The new ones replace them.** Each biome spawns only its new secret. Players who own a Snarlbloom or Petalfawn keep it. |
| One at a time, across what? | **The whole server.** While any secret pod is out (on its cradle or carried), no other biome spawns one. |
| The 5%? | **Per cycle, for the whole server:** one roll each dawn; on a hit, one random biome. About one every 2.4 hours per server. |
| How long does an unclaimed one stay? | **Until night,** like every pod. |
| When is the guardian faster? | **While the secret is carried.** |
| How fast? | **Storm Strider exactly, everywhere:** 195 studs/s at the start, 240 at the top. |
| The toast? | **Today's words:** "A SECRET EGG SPAWNED ON GREENHOLLOW!". |
| New players in their first loop? | **They see the toast.** |
| Income? | **A ladder by biome:** Grovemaw $155K/s, Scourwheel $165K, Mirehydra $172K, Cinderdrake $180K, Nebulisk $189K (doubled by x2 Money). |
| The Index? | **A 6th card on each biome's row,** the Secret background, **not counted in the row's CLAIM**. |
| Before it is owned? | **??? like every other card.** |
| Sizes? | **Full size everywhere,** as pasted: cradle, carried, planted (Cinderdrake's 78-stud wingspan overhangs a 48-stud plot), Index. |
| The see-through sphere round the Cinderdrake? | **Removed** ("if not necesarry we should remove it"), and the Mirehydra's too. Each was the model's Aura ball (90 and 61 studs), with the embers it gave off. It set the model's box and lowest point, so it stood the Cinderdrake's claws 21.5 studs off the ground and the Mirehydra 8.8. Their flares stay: the snout's flame and the lotus's spores, the lights' surge, the glow ripple and the halo. |
| Where the pod sits? | **Its cradle across the road** from the nest; never in the nest ring. |
| Anything besides POD RUSH that stops a spawn? | **No.** Rain, storms and the Mist can share a day with a secret. |
| What's New? | **Yes.** |
| Testing? | **Specs and one guarded Play** on a throwaway store, per step. |
| Body animation? | **New idles for Grovemaw, Scourwheel, Mirehydra and Cinderdrake** from their joints. The owner's aura and pod scripts are kept, and Nebulisk's idle is the owner's. |
| Where do they move? | **In the world** (cradle, carried, planted). **Still in the Index.** |
| Planted, do they walk? | **Walk like the other creatures** (the owner, asked after "scourwheel and grovemaw is idle right?"): each gets a walk cycle in step 2 -- Grovemaw's six legs, Scourwheel rolling, Mirehydra's tentacles, Cinderdrake's legs, Nebulisk slithering. |
| Can the Cinderdrake fly? | **Walk, fly sometimes** (step 2): he walks his plot like the others, and every so often takes off, flies a loop over his garden and lands. His wings are rigged (three joints and six spars a side). |
| Should a secret take more garden slots? | **Keep 1 slot** (the owner, asked after "is it essential to do this? example a secret sprout takes 10 of your garden slots"). Several on one plot overlap, which only looks crowded; plots hold 5 to 30. |
| The Greenhollow pod's lid? | **Opens when the pod is ready to hatch.** |
| How it ships? | **Two steps:** step 1, the secrets working with the owner's own scripts; step 2, the new idles. Each tested, and pushed on the owner's OK. |

## Step 1 — built 2026-10-16 (Claude, desktop)

**Where it lives**
- `Shared/BiomeSecretForms/`: the owner's ten models as data (a read-only generator; .rbxm backups in `output/model-backups/2026-10-16-biome-secrets-originals`). The Cinderdrake's and Mirehydra's Aura spheres are left out (`Removed`); each form stands on its own feet.
- `Shared/SeedData`: the five rows (`Still` until step 2), `SecretByBiome`. `Shared/BiomeData`: each biome's encounter (`SpotX` 42, `Chase = "stormstrider"`). `Shared/GameConfig`: `Secret.Enabled`, `CycleChance` 0.05, the Index's Secret background, the guide's words.
- `NestService`: one roll for the whole server at each stocking; one secret at a time; never in a POD RUSH; Storm Strider's chase (`chaseProfileOf`); `SpecRollSecret`. The debug spawn is refused the same way.
- `SecretModel`: these forms, their beams, `FormIndex` on every part, and whole-model streaming for their pods.
- `SecretIdle`: NebuliskIdle, MirehydraAura and CinderdrakeAura, ported. `SecretPodMotion` (+ client): SunPulse and MawPulse on the cradle; Grovemaw's lid swinging open in the hands once its pod is ready.
- `PlantService` (a `Still` secret never wanders), `AlmanacView` / `IndexUI` / `PodGuide` (the sixth card, its odds a dawn, one income), `InventoryModel` (a secret pod's Bag tile keyed by its own pod, so an owned Snarlbloom pod and a Grovemaw pod never share one), `FirstHatchCard` (no size word on a secret), `UpdateLog` (What's New).

**Tested**: BiomeSecretsSpec 43/0 (new); twelve specs' pins moved to the new state; the whole suite; mutants 19/19 caught. One guarded Play on a throwaway store: every cradle spot clear of decor; Cinderdrake's, Nebulisk's and Scourwheel's pods spawned on their cradles at full size; a second spawn refused while one was out; the toast on screen; MawPulse and SunPulse moving in Play; a steal met 283 studs/s (Storm Strider's formula against a 0-Speed thief); a bank into the Bag; Grovemaw's lid 70 degrees open in the hands once ready; a Bag hatch; four secrets planted, standing still, their idles playing; the Grovemaw card in the Index outside CLAIM.

**Seen in Play, for the owner**
- Four secrets on one plot overlap heavily (full size, as answered).
- A held secret pod fills the view (Grovemaw's pod is 30 studs).
- At that speed a guardian catches a slow thief within 1.5 s; the Starbloom guardian's throw sent the test player out of the world twice (put back at the gate, as the game does).

## Step 2 — built 2026-10-16 (Claude, desktop)

**Where it lives** (SecretIdle, and the `Still` flag gone from SeedData and PlantService):
- **Walks.** Grovemaw: six radial legs in an alternating tripod. Mirehydra: eight radial tentacles, every other one together; they rest within a twentieth of straight, so it takes short steps. Cinderdrake: four chain legs in the lateral sequence, through his joints' own frames. Scourwheel: its wheel rolls the ground it covers. Nebulisk: a wave down its coil as it goes.
- **Turns.** A biome secret's planted foot may stray half again as far as a turn on the spot carries it in one stance, so a wide-legged giant's feet are not set down again mid-stance.
- **New idles.** Grovemaw: trunk, canopies, boughs, leaves, vines, arms, a snapping maw. Scourwheel: chimes, ruff, pads, a clacking jaw, the rider's bob. Mirehydra: five weaving necks, heads that strike, a blinking lid, curling tentacles, over its aura. Cinderdrake: breath, an S-necked look, a jaw that opens with the flare's flame, blinks, a swaying tail, stirring wings, over his aura.
- **The Cinderdrake's flights.** Planted, every 75 s he flies for 12 s: up 26 studs in 2.2 s, a loop 22 studs across on his left, banking, and down where he rose. The timing comes from the server's clock with his placement's offset, so every viewer sees the same flight. His legs tuck and his wings beat; never when he isn't planted.

**Tested**:
- BiomeSecretsSpec 55/0. Walking 36 studs and turning a quarter, the worst planted-foot slide is Grovemaw 0.10, Mirehydra 0.53 and Cinderdrake 0.51 studs. The wheel rolled 67.9 of 68.8 degrees. The coil swings 13 degrees walking against 4 standing. The flight reaches 26 studs, and still flies while his walk goes on beneath. The new idles move.
- Mutants; the whole suite.
- One guarded Play: four planted walked 22 to 36 studs in 20 s, and the Cinderdrake flew (26 studs up, by the server's clock).
- Edit captures of each walk.
