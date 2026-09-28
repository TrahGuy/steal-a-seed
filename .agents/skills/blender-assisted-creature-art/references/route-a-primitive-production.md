# Route A -- Blender-assisted primitive production (the default)

Blender is where the form is found and judged; the live creature stays a Luau part build, made the
way the project already makes creatures. Nothing in this route imports a mesh.

## The pipeline

1. **Study** the design in Blender (a smooth sculpt or blockout is fine) and get the blockout
   approved ([visual review](visual-review.md)).
2. **Translate** it into the part vocabulary as a part list -- by hand in Blender with primitives
   carrying `rbx_shape`, or built from JSON with `partspec_bridge.py --import`.
3. **Measure the fidelity** with `silhouette_compare.py` and render the translation itself with
   `review_renders.py`. Show both to the owner.
4. **After approval**, move the geometry into the species' generator under `tools/art/` (the pattern
   of `suncrown_golem.luau`, `bellchime_bloom.luau`, `gloomlotus_titan.luau`, `pyrelotus_drake.luau`:
   each returns `{ specs, build, effects, measure, serialize }`). The forms table
   (`GreenhollowForms`, `DustbowlForms`, `TanglemireForms`, `EmberrootForms`, `StarbloomForms`) is
   updated by pasting `serialize()` output -- "never the other way round". Code-built species go
   through the `PlantSculpt` kit instead.
5. **Verify in Studio**: the specs that guard the species (`PlantFormsSpec`, `StarbloomLimbSpec`,
   `DustbowlPodSpec` ...), then Play: PlantSway rigs, carry, placement, the Index card, Tiny and
   Colossal ([contracts](game-contracts-and-budgets.md)).

`partspec_bridge.py --export --luau` writes a PartSpec-shaped Luau table for REVIEW into the
output folder. It is never pasted into `src/` directly.

## The part vocabulary, measured

Measured in Roblox Studio on 2026-09-24 by raycasting scratch parts in a transient, non-archivable
WorldModel (removed in the same call), and matching `PlantSculpt.luau`'s own note:

| shape | geometry |
| --- | --- |
| Block | a box of `Size` |
| Ball | a sphere whose diameter is the **smallest** of the three size axes |
| Cylinder | runs along its local **X** (length `Size.X`); circle diameter = the smaller of `Size.Y` and `Size.Z` -- never an ellipse |
| Wedge (`WedgePart`) | full height at local **+Z**, a knife edge at **-Z**, flat along its -Y face, constant across X |
| CornerWedge | a pyramid whose apex stands over the (+X, -Z) corner; **not** in the project's replay vocabulary -- `CreatureModel.replayPart` would build it as a Block |

`partspec_bridge.py` draws Balls and Cylinders at the size Roblox renders, so Blender shows what
Studio will show; it warns on non-uniform Balls and unequal Y/Z Cylinders.

## Mockup space and the axis change

- **Mockup space** (`PlantSculpt.luau`): studs, ground at Y = 0, front toward -Z, +X is the
  creature's right. The BASE CFrame the builders take is the ground contact point.
- **Blender** in this skill: Z up, the creature faces -Y, its right is -X, ground z = 0.
- The change of basis is the proper rotation Roblox (x, y, z) <-> Blender (-x, z, y); it is its own
  inverse (`bca_lib.R2B`). Swapping two axes instead is a mirror
  ([why it matters](reference-analysis.md#claims-in-sibling-skills-that-are-not-established)).

The part-list JSON (`bca-partlist/1`) carries `TanglemireForms.PartSpec`'s fields: `name`, `shape`,
`size`, `cf` (12 numbers, `CFrame:GetComponents()` order), `color` (0-255), `material`,
`transparency`, `reflectance`, `studs`.

## How the builders scale what you translate

`CreatureModel.replayPart` places every spec at a tier with two numbers: positions scale X and Z by
height x girth and Y by height; sizes scale by height only; rotations are untouched. So:

- the sculpture must hold from Tiny to Colossal -- girth widens the stance, it does not fatten parts;
- a part that only works at one size (a hairline gap, a sliver) breaks at the other end;
- review a translation at the Tiny frame and at Colossal in Studio, not just at the study's size.

## Translating form into parts

| study feature | translation pattern | source of the pattern |
| --- | --- | --- |
| a soft body or head mass | 3-5 intersecting Balls and Blocks, rotated and overlapped until the outline stops reading as one primitive | AGENTS.md rule 11, organic-roblox-form |
| a curved, tapered horn, claw, root or tail | a chain of Cylinders or Wedges, each shorter and thinner, turning a little at each joint | the Gloomlotus stilt roots (`RootRise` / `RootArch` / `RootDescent` / `RootAnchor`) |
| a carved mouth | a brow Wedge over cheek Balls and a jaw Block, with the dark interior part set BACK behind the lip planes | seed-premium-creature-art |
| a leaf or petal | thin plates along the arc, and a pointed tip from two mirrored Wedges | the smoke test |
| an eye | a dark Ball centred ON the surface so half stands proud, glint upper-left on both eyes | plant-art-bible |

## The fidelity tradeoff -- always shown, never hidden

A handful of primitives never reproduces a smooth sculpt exactly. Do not claim it does. Report:

- `silhouette_compare.py`: IoU per view, the share of the study lost and the share added, and the
  red/blue overlay;
- `review_renders.py` on the translation: how it actually looks;
- the part count against the species' budget.

**IoU measures coverage, not appeal.** In the smoke test a naive 26-part translation scored IoU
0.83-0.89, yet its plain render read as stacked balls, a puck and cardboard leaves -- and its
colour render had lost the carved mouth entirely: the dark interior part sat behind the jaw block
and vanished from the front view. No silhouette metric can see a face loss. The numbers bound the
loss; the renders decide whether it is acceptable.

## Studying an existing creature in Blender (unverified procedure)

To bring a live creature into Blender, dump its parts to a part list and import it with
`partspec_bridge.py --import`. The snippet below was **not executed** in this session. Building a
creature in Studio has side effects, so do it in a scratch place or with the owner's say-so.
Positions come out in built studs at that tier, relative to the base; divide by the tier's scale
before comparing with a mockup table.

```lua
-- Read-only: serialise a built creature's direct-child parts relative to its base CFrame.
local HttpService = game:GetService("HttpService")
local function toPartList(model: Model, base: CFrame): string
	local parts = {}
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local shape = if p:IsA("WedgePart") then "Wedge"
				elseif p:IsA("CornerWedgePart") then "CornerWedge"
				elseif p:IsA("Part") then p.Shape.Name
				else nil
			if shape then
				local c = p.Color
				table.insert(parts, {
					name = p.Name, shape = shape, size = { p.Size.X, p.Size.Y, p.Size.Z },
					cf = { base:ToObjectSpace(p.CFrame):GetComponents() },
					color = { math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) },
					material = p.Material.Name, transparency = p.Transparency, reflectance = p.Reflectance,
					studs = p.TopSurface == Enum.SurfaceType.Studs,
				})
			end
		end
	end
	return HttpService:JSONEncode({ format = "bca-partlist/1", space = "roblox-mockup", units = "studs", parts = parts })
end
```
