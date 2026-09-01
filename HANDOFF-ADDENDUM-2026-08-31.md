# HANDOFF ADDENDUM — Session of 2026-08-31

Supplement to `HANDOFF.md`. Everything in the original handoff still stands.
This records what was learned in one Claude session that had **read-only Roblox
Studio MCP access** to the running place, but **no filesystem or git access**.

**Status: PRELIMINARY.** The Codex audit (Appendix B) supersedes this document.
Where the audit report and this addendum disagree, the audit wins.

---

## Confidence key

Used throughout. Respect it — the distinctions are the point.

| Tag | Meaning |
|---|---|
| **[CONFIRMED]** | Quoted directly from a live Studio `script_grep` or `inspect_instance` result. Note the caveat below. |
| **[INFERRED]** | Reasoning from confirmed evidence. Plausible, not proven. |
| **[UNVERIFIED]** | Claimed by a source (Gemini summary, prior notes) and not checked. |
| **[NOT CHECKED]** | Known gap. Listed so it is not mistaken for absence of a problem. |

**Caveat on [CONFIRMED]:** these came from the *running Studio session*, not the
working tree. With ~878 uncommitted insertions in flight and unknown Rojo sync
state, the session may lag the repo. Treat as strong evidence, not as ground truth.

---

## 1. The tier ladder — new knowledge

**[CONFIRMED]** `SeedData.luau` lines 657–663. Seven tiers:

| # | Name | mul | weight | value | girth | pod |
|---|------|-----|--------|-------|-------|-----|
| 1 | Tiny | 1.000 | 0.5325 | 4 | 0.82 | 1.66 |
| 2 | Big | 1.308 | 0.1593 | 28 | 0.90 | 2.59 |
| 3 | Huge | 1.710 | 0.1007 | 140 | 0.98 | 3.66 |
| 4 | Mega | 5.000 | 0.0789 | 530 | 1.07 | 4.87 |
| 5 | Giant | 10.000 | 0.0592 | 1650 | 1.17 | 6.09 |
| 6 | Titan | 20.000 | 0.0642 | 5200 | 1.30 | 7.94 |
| 7 | Colossal | 50.000 | 0.0052 | 9500 | 1.45 | 9.04 |

### Two field-reading traps

**`weight` is drop probability, not mass.** The column sums to exactly 1.0000.
A prior AI summary read it as kilograms ("1 kg → 10,000 kg") and built an entire
audit section on that misreading.

**`mul` is income, not size.** A Colossal is worth fifty times a Tiny. It is
nowhere near fifty times its size — `SeedData:861` notes SizeScale is clamped to
**0.75 .. 1.30**, described there as a 1.73x spread.

### Supporting comments **[CONFIRMED]**

- `SeedData:622` — the ladder as a one-liner:
  `Tiny 1  Big 1.308  Huge 1.710 | Mega 5  Giant 10  Titan 20  Colossal 50`
- `SeedData:629` — "TINY IS THE LOCKED END, not COLOSSAL."
- `SeedData:643` — "`girth` and `pod` are the old curves sampled at each tier's own value"
- `SeedData:837` — "GIRTH IS PROPORTION, NOT SIZE"
- `SeedData:640` — a parent growing past 46 studs is a clipping bug; mentions a Colossal plant at 49
- `SeedData:872` — `function SeedData.Girth(tier: number?): number` returns `SeedData.Tier(tier).girth`

### Girth is applied by spreading parts, not by resizing **[CONFIRMED]**

`CreatureModel.luau`:

```
:876  -- WHY GIRTH IS DAMPED AND HORIZONTAL HERE
:879  -- along world X and Z does not widen it, it SHEARS it, so girth cannot be the
:884  -- and girth SPREADS THE PARTS APART horizontally.
:885  -- Suncrown already shows, folding girth into a damped `0.85 + 0.15 * gs` rather
:890  local GIRTH_REF = SeedData.Girth(SeedData.BaseTier)
:891  local GIRTH_SPREAD = 0.16
:892  local function mireGirth(G: number): number
:893      return 1 + GIRTH_SPREAD * (G - GIRTH_REF) / GIRTH_REF
:958      local G = SeedData.Girth(tier)
:1035         local gs = mireGirth(G)
```

**[INFERRED]** Because girth is a per-part horizontal operation rather than a
uniform model resize, a forms module must actively cooperate with it. A builder
that ignores girth is not merely unstyled — it is outside the scheme entirely.

### Other tier consumers **[CONFIRMED]**

- `PlantPlace:177` — `SeedData.FrameHeight(species, tier) * 0.46 * SeedData.Girth(tier) * 1.5`
- `PlantSway:141` — "go from a 6.0 .. 1.2 spread to 6.0 .. 4.7, and a Colossal would potter"
- `CreatureModel:2071` — "a Colossal is 30% speed whatever its shell looks like"
- `CreatureModel:2301` — `text.Text = "COLOSSAL"`
- `CreatureModel:2305` — `model:SetAttribute("PickupSound", "ColossalPickup")`
- `EmberrootForms:960` — "Colossal is fifty times a Tiny. Left alone, its aura would be a pinprick of"

`EmberrootForms:960` is the **precedent pattern**: that author reasoned explicitly
about tier presence and compensated for it.

---

## 2. Starbloom scaling contract

**[CONFIRMED]** `StarbloomForms.luau`:

```
:16   local StarbloomForms = {}
:17   StarbloomForms.AuthoredHeight = {
:556  --== CREATURE BODY (80%): Colossal Titan Carapace & Dragon Skull ==--
:690  function StarbloomForms.Build(model: Model, id: string, at: CFrame, hs: number): boolean
:720  return StarbloomForms
```

Note `:556` uses "Colossal" as an adjective describing the carapace. It is **not**
a tier reference.

**[CONFIRMED]** `CreatureModel.luau` dispatch:

```
:48    local StarbloomForms = require(Shared:WaitForChild("StarbloomForms"))
:1079  local authored = StarbloomForms.AuthoredHeight[sp.Id]
:1081      if StarbloomForms.Build(model, sp.Id, cf, H / authored) then
```

The design is sound in principle: author at a fixed height, scale to a
tier-derived target `H` via the ratio `H / authored`.

### The gap: girth never reaches Starbloom

**[CONFIRMED]** A `script_grep` for `girth` across the whole place returned hits
in `PlantPlace`, `CreatureModel`, and `SeedData`. **`StarbloomForms` did not
appear.** `Build` takes a single scalar `hs`.

**[INFERRED]** Starbloom creatures scale in height only. Girth runs 0.82 → 1.45
across the ladder, so other biomes' creatures get proportionally heavier at high
tiers while a Colossal Starbloom is a uniformly enlarged Tiny — same silhouette,
same proportions, no added heft.

**[NOT CHECKED]** How `hs` is consumed inside `Build`. Whether it multiplies part
*sizes*, part *offsets*, or both determines if adding a girth parameter is a
one-line signature change or a rewrite of every part placement. **This is the
single highest-value unknown.** Codex Section 2b.

**[NOT CHECKED]** `SeedData.FrameHeight` — so actual stud heights per tier per
species are unknown, and the real range of `hs` is unknown.

---

## 3. New defects found this session

### 3.1 Showroom hardcodes baseline scale — visual review gap

**[CONFIRMED]** `StarbloomMockupRunner:144`:

```lua
StarbloomForms.Build(plantModel, id, plantBaseCF, 1.0)
```

**[CONFIRMED]** `StarbloomMockupRunner:199` — the placard prints
`StarbloomForms.AuthoredHeight[id]`, i.e. baseline height, not a tier height.

**Consequence:** no Starbloom creature has ever been displayed at a non-baseline
tier. Visual approval of these designs covers **one point on a seven-point
ladder**. Tiny and Colossal appearance is entirely unreviewed.

### 3.2 No base pivot — confirms original Finding 6, and suggests a cause

**[CONFIRMED]** `inspect_instance` on
`Workspace.StarbloomSpeciesMockup.Species05_Supernovus.Plant_Supernovus`:

- No `PrimaryPart` in the returned property list
- `WorldPivot.Position` = `36, 5.6183061599731445, 68.97178649902344`
- `WorldPivot.Rotation` = identity
- Stated creature height: 8.20 studs

**[INFERRED]** Y of 5.618 on an 8.2-stud creature sits roughly four studs above
where the plinth top should be — consistent with an automatic centroid pivot
rather than a base pivot. First `PivotTo()` would sink the model by about half
its height.

**[INFERRED]** The Gemini summary describes the redesign as "eliminating static
base slabs." If the slab anchored the pivot and nothing replaced it, the
redesign **caused** Finding 6 rather than inheriting it.

**[INFERRED]** This compounds with tier scaling: sink depth scales with `hs`, so
the bug is worse at high tiers and milder at low ones.

### 3.3 Duplicate part names — likely mechanism behind Finding 8

**[CONFIRMED]** `Plant_Supernovus` children, by repeated name:

| Name | Count | Class |
|---|---|---|
| `OrbitalArc` | 12 | Part |
| `OuterPetal` | 8 | WedgePart |
| `InnerPetal` | 8 | WedgePart |
| `DragonEye` | 6 | Part |
| `AlienLeaf` | 4 | WedgePart |
| `LeafVein` | 4 | Part |
| `CometSatellite` | 4 | Part |
| `CrownSpike` | 4 | WedgePart |
| `BrowHorn` | 2 | WedgePart |

Plinth furniture repeats too: `LanternPost` ×4 and `LanternGlobe` ×4 per species.

**[INFERRED]** Any `FindFirstChild("DragonEye")` lookup returns one eye of six and
leaves the other five inert. This is a more likely explanation for Finding 8
("subparts remain fixed in live nests") than a missing feature would be.

**[NOT CHECKED]** How `PlantSway.client.luau` actually performs discovery.
Codex Section 5.

### 3.4 Part counts versus the 30-plant endgame

**[CONFIRMED]** Live child counts:

| Species | Children | Breakdown |
|---|---|---|
| Novaorb | 30 | 23 Part, 7 WedgePart |
| Cosmospire | 41 | 32 Part, 9 WedgePart |
| Voidpetal | 46 | 37 Part, 9 WedgePart |
| Astralhorn | 48 | 38 Part, 10 WedgePart |
| **Supernovus** | **85** | 59 Part, 26 WedgePart |

**[INFERRED]** `HANDOFF.md` treats a 30-plant Starbloom garden as normal endgame.
At these counts that is roughly 1,500–2,600 parts per player garden, before other
biomes or other players on the server.

### 3.5 Particles and lights may not be building

**[CONFIRMED]** `Plant_Supernovus` reports `childrenCount: 85` but
`totalDescendants: 88` — only **three** nested objects across the entire model.

**[CONFIRMED]** The four PointLights per species belong to `LanternGlobe` parts in
the plinth furniture — showroom dressing, not the creature.

**[INFERRED]** For a Mythic creature described as having "scalable particle
sequences and PointLights," three nested descendants is very thin. Either the
effects are not being built, or they exist on only a couple of parts.

### 3.6 Flat hierarchy — no rig

**[CONFIRMED]** All 85 `Plant_Supernovus` parts are direct children. No Motor6D,
no Humanoid, no AnimationController, no nested limb grouping appeared.

**[INFERRED]** "Articulated walking locomotion" must therefore be per-part CFrame
math every frame. On 30 live plants that is a substantial per-frame cost, and it
is consistent with the motion being showroom-only.

### 3.7 Showroom hierarchy explains the `Simulate()` false success

**[CONFIRMED]** `Workspace.StarbloomSpeciesMockup` contains five **Models**
(`Species01_Novaorb` … `Species05_Supernovus`). Each contains:

```
Plinth, PlinthTrim, InnerSlab,
LanternPost ×4, LanternGlobe ×4 (1 PointLight each),
Plant_<Name>          <-- the creature, one level deeper
PlacardPost, PlacardTrim, PlacardBoard (1 SurfaceGui)
```

**[INFERRED]** A `Simulate()` that iterates the folder expecting plant models as
direct children finds five species wrappers, matches nothing, connects Heartbeat,
and reports success — exactly original Finding 5's failure mode.

**[CONFIRMED]** Console output shows `[Seed/StarbloomMockupRunner]` operating on
the `StarbloomSpeciesMockup` folder, i.e. the two-runner collision is live.

---

## 4. Corrections to the Gemini summary

The Gemini document was **prose, not code**. Three specific problems:

1. **[CONFIRMED]** It read the `weight` column as kilograms ("1 kg → 10,000 kg").
   It is drop probability, summing to 1.0. An entire audit section was built on this.

2. **[CONFIRMED]** Its "Tools & Modules" list names only `StarbloomMockupRunner.luau`.
   It omits `StarbloomSpeciesMockupRunner.server.luau` entirely — one of the three
   untracked files. **[INFERRED]** This is plausibly why the two-runner duplication
   survived the rebuild: the rebuild did not know the second runner existed.

3. **[UNVERIFIED]** Its economy claim of a "$180M → 4.5B" endgame transition does
   not match `HANDOFF.md`'s figures ($100B Tier 10 mill; ~$8.122B total Overclock).
   Unresolved — Codex Section 8.

**Process lesson:** prose summaries of this codebase have been unreliable. Demand
`file:line` citations and verbatim excerpts.

**Scope lesson:** the Gemini audit request spanned ~15 files across four sections
and re-covered confirmed Findings 2, 3, 8, and 10. As a read-only audit that is
merely wasteful; handed to an agent as a *fix* task it would be exactly the
eleven-findings-in-one-pass sweep `HANDOFF.md` forbids.

---

## 5. Environment notes

**Studio MCP works and is useful.** One instance was connected:
`Steal a Seed (placeId: 114075467877655)`, in **Edit** mode. Read-only tools
(`script_grep`, `script_search`, `inspect_instance`, `search_game_tree`,
`get_console_output`, `get_studio_state`, `screen_capture`) produced every
[CONFIRMED] item above without modifying anything.

**Studio ≠ repository.** The MCP link reads the running place. It cannot read
files on disk, run `git`, or run Rojo. Never treat a Studio read as repository
verification.

**Output log is flooded. [CONFIRMED]** Hundreds of identical repetitions of:

```
AssistantCommand:87: attempt to call a nil value
```

**[INFERRED]** Possibly the MCP bridge plugin's own execution script. Two
consequences: real errors will be buried during any playtest, and
execution-style MCP calls may be unreliable in that session. Worth clearing the
log before the next playtest.

---

## 6. Unchanged from the original handoff

Restated so this addendum can be read alongside `HANDOFF.md` without drift:

- **Guardian canon:** Greenhollow → generic original parent, Dustbowl →
  Brambleback, Tanglemire → Miremaw, Emberroot → Forgemaw, Starbloom →
  Astralmaw. **No Sandcrawler.** No renames without sign-off.
- **Locked artwork:** Greenhollow pods; Greenhollow identity root pose;
  Tanglemire creatures; recent Emberroot and Starbloom work. Brambleback's
  approved sleep numbers stand.
- **Pod rules:** base-not-center CFrame; nothing below base; no fully-interior
  details; width ≤ 1.3× diameter; details proud of the surface; taper over bars;
  Neon color compensation; no dressing matching ground color; distinct silhouette
  per biome. Edit `Workspace.PodStages` — never build a second stage.
- **Blockers 1–3** repaired in focused, separately reviewable changes. Never one
  broad pass across the eleven findings.
- **Economy** is a documented warning, not a mandate. No rebalancing and no
  re-gating Overclock without an explicit decision.
- **Pod-hatching animation** is a design plan only. Not implemented.
- No duplicate preview stages, no parallel implementations, reuse existing
  modules, keep geometry and animation consistent between previews and live nests.

---

## 7. Suggested next-session order

1. **Run the Codex audit** (Appendix B). Its report supersedes this document.
2. **Reconcile.** Fold whatever survives into `HANDOFF.md`; delete what the audit
   refutes. Expect some [INFERRED] items to be wrong.
3. **Blocker 1** — legacy plant migration (Appendix A). Prompt is ready.
4. **Starbloom pivot fix** — narrowest high-value art fix. Set an explicit
   `PrimaryPart` or establish a base pivot before first positioning. Best combined
   with the duplicate-name issue, since both live in the same builder.
5. **Open decisions** — girth for Starbloom; part budget at 30-plant endgame; the
   Overclock gate ordering. All require the user's call, not an agent's.

---

## Appendix A — Blocker 1 prompt (ready to run)

Repairs the `ProfileSchema` / `PlantService` migration boundary. Read-write,
tightly scoped, working-tree-preserving.

````markdown
Implement the first release blocker in "Steal a Seed": repair the legacy plant
migration boundary. Do not touch any other system.

Repository: D:\KAPE\Steal an Artifact
Expected baseline HEAD: 353d74d

## 0. Preflight — stop conditions

Run these before reading anything else. If any check fails, STOP and report
instead of proceeding.

1. `git rev-parse --short HEAD` — must be 353d74d. If it is not, stop.
2. `git status --short` — record the full output verbatim. Expect roughly
   20 modified files and 3 untracked files. The untracked files are:
     src/ReplicatedStorage/SeedGame/Shared/StarbloomForms.luau
     src/ServerScriptService/SeedGameServer/StarbloomMockupRunner.luau
     src/ServerScriptService/SeedGameServer/StarbloomSpeciesMockupRunner.server.luau
   If nothing is modified, or the tree is clean, stop — you are not looking at
   the right working tree.
3. `git diff --stat` — record the totals. Expect roughly 878 insertions and
   188 deletions. Nothing is staged; if anything is staged, stop and report.

## 1. Working-tree safety — non-negotiable

The uncommitted work is user-authored and must survive this task intact.

Forbidden: `git reset`, `git revert`, `git clean`, `git stash`, `git checkout`
or `git restore` on tracked files, `git add`, `git commit`, `git push`, and
whole-file overwrites of any file that currently has uncommitted changes.

Make a minimal in-place patch against current file contents. Read the existing
diff for every file you intend to edit before editing it, so your change layers
onto the user's work rather than reverting it.

Leave the three untracked Starbloom files untracked. Do not stage anything.

## 2. Read first

- AGENTS.md
- HANDOFF.md
- src/ServerScriptService/SeedGameServer/ProfileSchema.luau
- src/ServerScriptService/SeedGameServer/PlantService.luau
- The current uncommitted diff for both files above.

## 3. Scope

Editable:
- src/ServerScriptService/SeedGameServer/ProfileSchema.luau
- src/ServerScriptService/SeedGameServer/PlantService.luau
- tools/tests/ (new or updated regression coverage)

Out of scope, do not touch even if you notice a defect: creature art, pods,
guardians, economy and mill pricing, Training Rush, Overclock, Studio mockups,
the Starbloom showroom, SpeedFX, TreadmillService, PlayerDataService, and the
stale specs in CycleSpec / SpeedSpec. Those are tracked separately. If you find
something, report it in prose; do not fix it.

## 4. Confirmed defect

`ProfileSchema.Sanitise()` rebuilds saved plant rows before
`PlantService.restore()` sees them. It currently:

- turns a missing `Tier` into 0 and then drops the plant;
- turns missing `X` and `Z` into 0;
- discards the legacy `Slot` field;
- turns a missing `Stage` into pod stage;
- turns a missing `Facing` into 0.

This destroys the "field was absent" signal that PlantService's existing
migration depends on:

- missing `Tier` should resolve to `SeedData.BaseTier`;
- missing X/Z should resolve via the legacy `Slot` attachment;
- missing `Stage` should derive pod-vs-grown from elapsed growth time;
- missing `Facing` should use the deterministic `facingFor(id)` fallback.

Observed consequences: legacy plants deleted, plants relocated to plot center,
mature plants reverted to pods, all plants restored at identical facing.

## 5. Required behavior

1. A valid saved plant must not be dropped solely because `Tier` is absent.
2. Preserve three distinct states: absent in a legitimate legacy save;
   present-and-validated; corrupt and untrusted.
3. Missing `Tier` reaches PlantService so it can apply `SeedData.BaseTier`.
4. Do not synthesize `(X, Z) = (0, 0)`. Preserve a valid legacy `Slot` so
   PlantService can resolve the old slot attachment.
5. Do not synthesize `Stage = 1`. Let PlantService derive grown-vs-pod from
   `PlantedAt` and `SeedData.GrowSeconds(tier)`.
6. Do not synthesize `Facing = 0`. Let PlantService use its deterministic
   fallback.
7. Keep rejecting rows that do not name a real species.
8. Keep bounding and normalizing fields that ARE present. Do not weaken the
   sanitizer into trusting whole rows.
9. Current-format saves must round-trip identically in meaning: same species,
   tier, position, stage, facing, planted time.
10. PlantService remains the single migration authority. Do not add a second
    migration implementation inside the sanitizer.

If the saved-row type currently requires every field, widen it narrowly so the
legacy fields are optional during restoration. Use explicit nil narrowing at
read sites. Do not spread `any`, do not add `--!nocheck`, do not disable
type checking for the module.

## 6. Hazards to check before you finalise — report findings either way

a. CONSUMER SWEEP. Before making fields optional, grep every reader of plant
   rows across the codebase, not just these two files. Any site that assumes
   non-nil `Tier`, `X`, `Z`, `Stage`, or `Facing` needs a nil guard or must be
   confirmed unreachable pre-migration. List what you found.

b. SLOT SURVIVAL. Confirm `Slot` actually survives the sanitizer into the shape
   PlantService reads. If the serializer or save path strips unknown fields,
   preserving `Slot` in memory is not enough — say so rather than assuming.

c. WRITE-BACK. Determine whether `PlantService.restore()` persists migrated
   values back into the profile. If it does not, migration re-runs every load
   and a save between sanitize and restore may persist a partially-migrated
   row. REPORT THIS — do not expand scope to fix it without asking first.

d. SAVE-DURING-LOAD. Confirm no autosave or save path can fire between
   sanitization and restore in a way that writes a row worse than the one it
   read. If it can, report it; do not fix it here.

## 7. Regression coverage — tools/tests/

Cover at minimum:

1. Legacy plant with no `Tier` survives sanitization and restores at
   `SeedData.BaseTier`.
2. Legacy row with `Slot` but no X/Z retains enough information for slot
   migration.
3. Mature legacy plant with no `Stage` restores grown when elapsed time exceeds
   its growth duration.
4. Legacy row with no `Facing` reaches the deterministic fallback rather than 0.
5. Fully populated current-format row survives sanitization unchanged in meaning.
6. Unknown species still rejected.
7. Invalid present numeric values remain bounded or rejected per existing policy.

TEST HONESTY RULES:

- If PlantService cannot be instantiated outside Studio, split the tests: assert
  pure sanitizer output directly, and assert migration logic through a small
  helper. Any behavior that genuinely needs Workspace — resolving the legacy
  `Slot` attachment to a real position almost certainly does — must be named
  explicitly as Studio-only, not faked. For case 2, asserting that the sanitized
  row still CARRIES `Slot` is a legitimate test; asserting a resolved world
  position without Studio is not.
- If you extract a pure helper to make derivation testable, `restore()` must
  call that same helper. An extracted copy would violate requirement 10.
- Do not report a test as passing unless you ran it and saw it pass. State the
  command and the actual output.

## 8. Validation

- Run the regression tests that can run outside Studio. Report command + output.
- `git diff --check`
- Temporary Rojo build against `default.project.json`. Build the artifact to a
  path OUTSIDE the repository (e.g. under %TEMP%) so it can never appear in
  git status. If you must build inside the repo, delete the artifact afterward
  and confirm the deletion.
- `git diff --stat` — the delta versus the preflight numbers must be accounted
  for entirely by your intended files.
- `git status --short` — must show the same 3 untracked Starbloom files as
  preflight, plus any new test files, and nothing staged.

Do not open or modify Roblox Studio for this task.

## 9. Report

- Root cause, stated precisely.
- Exact behavior changed, before and after.
- Files modified, with the reasoning for each.
- Findings from section 6 (a) through (d).
- Tests written, commands run, actual results.
- Any validation that remains Studio-only, named explicitly.
- Rojo build result and confirmation the artifact is gone.
- Final `git status --short` and `git diff --stat`.

Do not commit. Do not push. Do not stage.
````

---

## Appendix B — Full read-only audit prompt (run this first)

Writes `D:\KAPE\audit-report.md` **outside** the repository. Makes zero changes.

````markdown
READ-ONLY AUDIT of the "Steal a Seed" repository. Produce a report file.
Do NOT modify a single file in the repository.

Repository: D:\KAPE\Steal an Artifact
Expected HEAD: 353d74d

## HARD CONSTRAINTS

- This task makes ZERO changes to the repo. No edits, no new files inside the
  repo, no formatting, no "while I was here" fixes.
- Forbidden: git reset, revert, clean, stash, checkout/restore, add, commit,
  push, or any command that writes to the working tree.
- Allowed git commands: status, diff, log, rev-parse, show. Read-only only.
- There is substantial uncommitted user-owned work (~20 modified files, 3
  untracked, ~878 insertions / 188 deletions). It must be untouched at the end.
- Write the report to D:\KAPE\audit-report.md — OUTSIDE the repository folder.
  Nothing else gets written anywhere.

## EVIDENCE RULES — these matter more than coverage

1. QUOTE, DON'T PARAPHRASE. Every finding needs a `file:line` citation and a
   verbatim code excerpt. A previous AI summary of this codebase misread a
   field named `weight` (a drop probability summing to 1.0) as kilograms,
   because it described code instead of quoting it. Do not repeat that.
2. NEVER infer a field's meaning from its name. State what the code does with
   it, and cite where.
3. REPORT ABSENCE EXPLICITLY. If you searched for something and it isn't there,
   write "NOT FOUND — searched via <method>". Absence is a finding. The same
   prior summary omitted an entire module that exists in the tree.
4. Distinguish three states everywhere: CONFIRMED (quoted code),
   INFERRED (reasoning from quoted code, label the inference),
   NOT CHECKED (say so rather than guessing).
5. If a file is too long to quote whole, quote the relevant function entirely.
   Do not quote a fragment that hides control flow.

## SECTION 1 — Working tree ground truth

- `git rev-parse --short HEAD`
- `git status --short` (verbatim, complete)
- `git diff --stat` (verbatim totals)
- Confirm nothing is staged.
- List the 3 untracked files by full path.

## SECTION 2 — Starbloom tier scaling (highest priority)

Files: `StarbloomForms.luau`, `CreatureModel.luau`, `SeedData.luau`

a. Quote `StarbloomForms.AuthoredHeight` in full.
b. Quote `StarbloomForms.Build` IN FULL, including how the `hs` parameter is
   consumed. I need to know specifically: does `hs` scale part SIZES, part
   OFFSETS/positions, or both? Show the lines where it is multiplied in.
c. Quote `SeedData.FrameHeight`. Give the resulting height in studs for
   EVERY tier (Tiny through Colossal) for each of the 5 Starbloom species.
   Show the arithmetic.
d. Quote the `CreatureModel` Starbloom dispatch block (around lines 1075-1090),
   including the full `if` condition on the line above the `Build` call, and
   show where `H` is computed.
e. GIRTH: `StarbloomForms` did not appear in a grep for "girth". Confirm or
   refute. If girth is never passed to Starbloom, state that plainly. Then
   show how girth IS applied for other biomes — quote the `mireGirth` usage
   and the code that spreads parts horizontally.
f. Quote how `EmberrootForms` handles tier scale (see its ~line 960 comment
   about Colossal being fifty times a Tiny). This is the precedent pattern.
g. MINIMUM PART SIZE: Roblox clamps parts at 0.05 studs. List any part in
   `StarbloomForms` whose authored dimension, multiplied by the SMALLEST `hs`
   that can occur, falls below 0.05. Name the parts and show the numbers.

## SECTION 3 — Starbloom builder structure

a. Does `Build` set a `PrimaryPart` or otherwise establish a base pivot?
   Quote the relevant code, or state NOT FOUND.
b. Live inspection of the built showroom model showed `Plant_Supernovus` with
   no PrimaryPart and `WorldPivot.Position` Y = 5.618 on an 8.2-stud creature.
   Confirm or refute from the source.
c. Are parts created with duplicate names? Live inspection showed six children
   named `DragonEye`, plus `OuterPetal` x8, `InnerPetal` x8, `OrbitalArc` x12,
   `CometSatellite` x4, `AlienLeaf` x4. Confirm from the builder loops.
d. Count the parts each species builds. Live counts were Novaorb 30,
   Cosmospire 41, Voidpetal 46, Astralhorn 48, Supernovus 85.
e. Does `Build` create ParticleEmitters / PointLights / Beams inside the plant
   model? Live inspection showed Supernovus with 85 children but only 88 total
   descendants — only 3 nested objects. Confirm or refute.
f. Are any parts created with `Shape = Ball`? List them per species. The art
   direction bans sphere-stack construction, so I need the real count.

## SECTION 4 — The two Starbloom showroom runners

Files: `StarbloomMockupRunner.luau`, `StarbloomSpeciesMockupRunner.server.luau`

a. Quote what each writes into `Workspace`, and the exact folder/model
   hierarchy each CREATES and each EXPECTS to read.
b. Live tree shows `Workspace.StarbloomSpeciesMockup` containing five Models
   (`Species01_Novaorb` ... `Species05_Supernovus`), each holding plinth parts
   plus a nested `Plant_<Name>`. Confirm which runner produces that shape.
c. Quote `Clear()` in full. Does it disconnect its Heartbeat connection before
   destroying? Show the connection variable's lifecycle.
d. Quote `Simulate()` in full. Show exactly what it iterates. If it can connect
   Heartbeat, animate zero models, and still return success, demonstrate the
   path with quoted code.
e. Does either runner hardcode the height scale? Line 144 of
   `StarbloomMockupRunner` appeared to pass a literal `1.0`. Confirm.
f. Is there any way to preview a non-baseline tier in either showroom?

## SECTION 5 — PlantSway part discovery

File: `PlantSway.client.luau`

a. Quote every place it locates parts on a creature. For each, state whether it
   uses `FindFirstChild` (returns ONE match), `GetChildren`/`GetDescendants`
   with a name filter (returns ALL), CollectionService tags, or attributes.
b. Given duplicate part names, which lookups would silently handle only the
   first match? Name them.
c. Which of these names does it know about: `AlienEye`, `PredatorEye`,
   `DragonEye`, `AlienLeaf`, `LeafVein`, `Mote`, `CapacitorNode`,
   `CometSatellite`, `OrbitalArc`, `MawCore`, `TalonGlow`? Mark each
   HANDLED or NOT FOUND.
d. Quote the wander-bounds and stride logic, including the tier-dependent part
   (see its ~line 141 comment about a Colossal "pottering").

## SECTION 6 — The three release blockers (quote current code, do NOT fix)

a. `ProfileSchema.luau` — quote `Sanitise()` in full, specifically the plant-row
   handling. Show where missing `Tier` becomes 0 and the row is dropped, where
   `Slot` is discarded, and where `Stage`/`Facing`/`X`/`Z` are defaulted.
b. `PlantService.luau` — quote `restore()` and its migration logic. Show what it
   expects for missing `Tier`, `Slot`, `Stage`, `Facing`. Also answer: does
   `restore()` write migrated values BACK into the profile, or re-derive them
   every load?
c. `PlayerDataService.luau` — quote the load path around `SaveService.Load()`.
   Show the window where a player leaving mid-load could orphan a session lock,
   and whether any cleanup runs on `PlayerRemoving` during that window.
d. `TreadmillService.luau` — quote the Training Rush payout tick. Show the final
   partial-tick arithmetic where remaining charge is spent but a full interval
   is paid.

## SECTION 7 — Biome liveness

- Quote `BiomeData`'s `LiveInPhaseA` entries for all five biomes.
- Quote the `NestService` logic that decides which biomes get live nests.
- State plainly: does `LiveInPhaseA` actually gate anything, or does registered-
  species presence override it?

## SECTION 8 — Economy figures (verify, do not rebalance)

- Quote all ten mill tier prices.
- Quote all ten Overclock level costs and the total.
- Quote the unlock condition for Overclock.
- Quote per-species income for the 5 Starbloom species.
- A prior summary claimed an endgame transition of "$180M to 4.5B". State
  whether any figures in the code match that range, or whether it appears
  invented. Do not change any values.

## SECTION 9 — Test status

- `CycleSpec.luau`: quote the assertion about live biome count.
- `SpeedSpec.luau`: quote the `BiomeData.SpeedGate` reference.
- Quote any Speed FX test that assumes seven tiers.
- List how tests are run outside Studio (runner, command). If they cannot run
  outside Studio, say so.

## SECTION 10 — Cross-biome comparison

For each of the five `*Forms` modules, give a one-row comparison:
build function signature, whether it receives girth, whether it sets a
PrimaryPart, approximate part count for its largest species, and whether it
uses duplicate part names.

## REPORT FORMAT

Write D:\KAPE\audit-report.md with the sections above in order. Use
`file:line` citations throughout. Fenced code blocks for excerpts. Put a
CONTRADICTIONS section at the end listing every claim in this prompt that the
code REFUTED — I want to be corrected, not agreed with.

Finish by running `git status --short` again and pasting it, to prove the
working tree is unchanged.
````

---

## Appendix C — How to reuse this document

Paste this file at the start of the next session along with `HANDOFF.md`, and add:

> Treat both documents as authoritative project state. The addendum's [CONFIRMED]
> items came from a read-only Studio session, not the filesystem — the Codex audit
> report supersedes them where they disagree. Act as a planning and review partner;
> do not claim to have inspected files you cannot access.

If `audit-report.md` exists by then, paste that too and say it takes precedence.
