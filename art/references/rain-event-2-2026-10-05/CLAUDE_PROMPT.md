# Implement Rain Event 2 creatures and daytime Colossal lightning

UPDATE: the owner has now supplied SEVEN tier-specific pods. Read `SUPPLIED_PODS_FOLLOWUP.md` in this folder before acting; it supersedes the original generic Pod/single-shell scaling instruction below. Updated reference: `rain-event-2-seven-pods-studio.png`. Map by size name (Mega is tier 4, Giant is tier 5), preserve supplied per-tier pod dimensions, and do not apply creature scaling to the already-sized pods a second time. All other requested creature/income/lightning behavior remains in scope.

Work in `D:\KAPE\Steal an Artifact`. Implement these TWO requests together: integrate the owner's four supplied Rain Event 2 creatures with all seven sizes, and make Colossal lightning visible during daytime as well as nighttime. Do not implement the separate tap-to-show other-player label brief in this task.

Read current AGENTS.md and KB/HANDOFF.md, inspect repository status, and use the applicable canonical project skills before editing. This is a shared, very dirty checkout: preserve unrelated/concurrent changes, including the five weather/toast/visibility/trap features just completed. Do not commit, push, publish, wipe saves or restart live servers. Update both project and root handoffs with actual evidence and remaining limitations.

The supplied screenshot is in this folder as `rain-event-2-studio-models.png`. It identifies a Studio folder named `Rain Event 2` with these exact source models:

- `Monsoad (Legendary) (tiny)` -> Monsoad, Legendary.
- `Squallsnapper (epic) (Tiny)` -> Squallsnapper, Epic.
- `Thundershell (tiny)(Legendary)` -> Thundershell, Legendary.
- `Torrentacle (tiny)(Mythic)` -> Torrentacle, Mythic.
- `Pod` -> their supplied pod art.

Codex has only seen this Explorer screenshot, not the actual hierarchy/geometry. First locate the real folder read-only in the correct Podnappers Studio place. Inspect and inventory all four models and the pod, dimensions/pivots, parts, joints, attachments, authored effects and asset dependencies. If a model is missing or cannot be read faithfully, identify exactly what is missing and ask; do not invent a replacement. Back up supplied models before any conversion. Leave original source models/folder intact.

## 1. Preserve the supplied creatures; generate Tiny through Colossal

Treat the supplied models as the Tiny reference. Preserve their silhouette, colours, face, materials/studs, topology and authored proportions. Integrate deterministic repo-backed form data using the existing supplied-rig pipeline (RainForms / PlantForms / SecretModel / CreatureModel as appropriate), so runtime construction does not depend on the owner retaining a hand-placed Workspace folder. Do not redesign them or add a competing plant/pod service.

Expose the seven existing size names in order: Tiny, Big, Huge, Mega, Giant, Titan, Colossal. Reuse the CURRENT approved supplied-model scaling approach: current SeedData size multipliers are 1, 1.38, 1.9, 2.65, 3.7, 5.1 and 7.6. Keep the supplied Tiny reference as the baseline; if actual inspection shows it needs normalization to the game's Tiny footprint, show measured dimensions and propose that adjustment before changing its reference size. Do not reuse the older kg/girth examples in the plant skills; the current tier/supplied-rig implementation takes precedence.

Scale the whole rig consistently, including part offsets and sizes, joints C0/C1, attachments, accessory offsets, supported effects and animation scale metadata. Ground/base/pivot, carry framing, tool grip, collision/reach proxies and label/pickup anchors must remain correct at every tier. Do not merely enlarge BasePart.Size while leaving joints, FX or offsets at Tiny. Preserve current ownership/physics and rig/animation contracts; do not invent a rig or movement style without inspecting the supplied one. Existing unsized Secrets, older Rain forms and the Thunderstorm guardian/forms must keep their authored sizes and behavior unchanged.

Use the owner's supplied Pod for these new creatures, scaled/readable by size using the existing pod presentation policy. Do not reveal which creature or its species rarity before hatching. Keep the pod->grown stage/manual hatch contract; do not reintroduce the obsolete sprout stage. Do not attach a new duplicate label: reuse current PlantLabel and current rarity/size lettering, including Colossal styling and correct owner income. No kg labels.

## 2. Earnings: exact unboosted values, independent of geometry

The owner asked to proceed after Codex's proposal. Use these proposed rates as the requested income configuration; keep them in SeedData, not in client scripts. Values below are dollars per second in size order Tiny / Big / Huge / Mega / Giant / Titan / Colossal:

- Squallsnapper (Epic): 20000 / 23000 / 26000 / 30000 / 36000 / 43000 / 50000.
- Monsoad (Legendary): 30000 / 34500 / 39000 / 45000 / 54000 / 64500 / 75000.
- Thundershell (Legendary): 35000 / 40250 / 45500 / 52500 / 63000 / 75250 / 87500.
- Torrentacle (Mythic): 60000 / 69000 / 78000 / 90000 / 108000 / 129000 / 150000.

These are EVENT-specific per-tier base incomes (earning ladder 1 / 1.15 / 1.3 / 1.5 / 1.8 / 2.15 / 2.5), NOT the physical size multipliers, ordinary tier.value ratios, or a new rarity multiplier. Existing x2 pass, weather +25%, chest/sacrifice and other applicable boosts compose once through EconomyService. Do not multiply these rates again by rarity, biome, size or ordinary tier value. Test both base rates and boosted rates. Sale/value displays must derive through existing contracts, not a second payout path.

Existing Rain's single FixedIncome/Unsized flags are not already a seven-tier income mechanism. Add the smallest explicit data/API extension for these new forms and preserve old FixedIncome semantics. Keep stable item identity and the saved tier throughout nest roll -> carry/drop -> banking -> planting -> hatch -> pickup -> hotbar/Bag -> rejoin. Check all consumers and validators that currently assume every Rain pod has a single tier, identical species rarity and only Colossal can be sized. Do not globally weaken validation or set new Tiny-through-Titan forms Unsized to make old assertions pass. Do not put event-only creatures into road biome pools, wheel/reward pools or Almanac/harvest shelves unless the owner separately authorizes that expansion.

## 3. Rain-only acquisition and balance boundary

Acquire these creatures through the existing Rain event nest/pod lifecycle, for BOTH manually triggered and natural Rain. Preserve one batch of THREE eggs, no restocking on theft/banking/guardian recovery/repeated START, and the recently approved TOTAL Colossal chance of 10% per Rain egg (90% non-Colossal). Do not independently add a second Colossal roll that makes the effective rate higher. Keep all seven new sizes reachable while preserving that aggregate cap. Thunderstorm still lays exactly one existing Pod 3 with its existing two Divine creatures and their 250000/265000 income; leave its odds, 9-hour grow time, carry penalty and special-egg toast unchanged. Plain Rain remains plain Rain: a new Mythic/Colossal spawn is not automatically a Secret egg announcement.

Default scope is ADDITIVE: keep existing Rain creatures, IDs, pod mappings, fixed rates, grow times and saved items working. The owner was asked whether to add versus replace; honor a subsequent explicit reply. Do not silently remove old content. Reuse current WeatherService/NestService rather than a parallel spawner. New Rain pod family and size/species draws are server-owned, rolled once per actual laid pod and persisted; no reroll while carried, on hatch, rejoin or recovery.

New-versus-old family share, per-creature odds and new hatch times were NOT decided in the income proposal. Inspect current architecture, then present a short proposed distribution and hatch schedule for approval BEFORE applying those new balance choices. It is fine to proceed with faithful asset import, seven-tier model/income support and the lightning fix while that choice is pending. Sensible starting proposal: preserve existing Rain 3-hour non-Colossal / 6-hour Colossal timing for this new family; use existing relative size weights normalized across Tiny..Titan within the 90% non-Colossal bucket; make Epic more common than Legendary, and Mythic least common. State the resulting unconditional probabilities including old/new family share. Do not change global tier weights, existing 90/10, auto-weather settings, old Rain hatch times, old species odds or Thunderstorm to solve the new-family configuration. If owner approves replacing future ordinary Rain spawns instead, preserve legacy IDs/assets/save loading and do not alter Thunderstorm.

## 4. Fix daytime Colossal lightning for ALL eligible Colossal plants

Also apply `D:\KAPE\Steal an Artifact\art\references\other-plants-switch-2026-10-05\COLOSSAL_DAYTIME_LIGHTNING_FOLLOWUP.md` in full. Scope is the existing Colossal crackle effect, including new Colossal Rain creatures and existing eligible Colossals, not only the new four.

Current cause is explicit night gating in Shared/PlantAura.luau: SetNight(false) ends active pulses and Tick refuses daytime starts. PlantSway currently passes phase to both PlantGlow and PlantAura. Fix eligibility and day/night transitions, not just brightness. Keep ordinary PlantGlow's existing night-only behavior. Visible pooled lightning segments may run all day; optional PointLight flashes can stay night-only or restrained by day. Do not change global Lighting, exposure, bloom, time of day or weather.

Preserve pooled jagged Neon segments, current pulse pacing, Colossal-only filtering, quality/reduced-motion/Off settings, distance culling and concurrency/part budgets. No continuous bolts, per-arc lights, extra whole-world scans or new per-frame loops. If daytime arcs wash out against bright studded ground or pale bodies, make a small targeted contrast/opacity/width adjustment and verify it. Keep the approved nighttime appearance. Dawn/dusk must not permanently silence the effect, queue a burst, leak state or duplicate segments.

Honor the already implemented PlantVisibility local marker: OTHER PLANTS OFF hides other owners' grown plants AND their bolts/lights; own plants and unhatched pods stay visible. Removal/pickup, streaming, ownership changes and quality changes must cleanly stop/restart/return the correct pooled effects. Do not add a conflicting visibility flag.

## 5. Verification and handoff

Before runtime tests, note Claude's prior report of a leftover EDIT-only mutant listener. Use a clean test context; do not close/restart Studio and discard unsaved owner models/work. If a restart is necessary, preserve work and coordinate it with the owner.

Run focused deterministic Edit specs first: all 28 income answers and one-time boosts; size/rig attachment integrity across tiers; new species lookup and pod metadata; server-only Rain roll and 90/10 aggregate distribution with scripted RNG; manual/natural same path, no restock; hatch secrecy; old Rain/Secret/Thunderstorm IDs and old saves unchanged; save roundtrip retaining new species/tier; Bag/My Plants/labels/carry/pickup metadata; daytime/night/transition lightning; Off, hidden plants, removal and pool budget/leaks. Update stale night-only tests to reflect the new requested behavior. Keep test listeners/fixtures isolated and fully clean them; do not leave a second watcher behind.

Capture each supplied Tiny beside its integrated Tiny and a seven-size lineup with an avatar for scale; verify big models ground/carry/pickup correctly, not just a code multiplier. Capture matched day/night Colossal arcs under real lighting, including a new Rain Colossal and an existing Colossal. Prefer ONE guarded throwaway-store Play for the needed runtime checks. Immediately before EVERY agent Play follow AGENTS.md's SeedTestStore marker + store_guard SAFE procedure, check the Ready line says STUDIO TEST STORE, never touch the real save, and finish test-store/host/fixture cleanup. Reuse existing Studio test/grant seams only on that throwaway profile. A test-only grant must not widen live admin access or acquisition pools. Report honestly if mobile, controller, low graphics or true multiplayer were not actually tested.

In your completion report give actual imported source/model dimensions, seven-size evidence, configured earnings, approved spawning/growth decisions and exact odds, daytime/night screenshots, tests/results/regressions, old-item compatibility, cleanup evidence and anything blocked or unverified. Do not call incomplete spawn balance approved, claim a clean full suite with known failures, or publish automatically.

Status: this file is the owner-requested combined CLAUDE IMPLEMENTATION BRIEF. Codex has not edited game source or Studio models; geometry and unspecified spawn/growth balance still require inspection/approval as described.
