---
name: colossal-titan-sculpting
description: Sculpt colossal quadruped behemoths, mammoth titans, and horned apex creatures from primitive Roblox geometry. Use for heavy-set silhouettes, sweeping curved tusks, segmented trunks, glowing fissure mantles, and planted pillar leg construction in Steal a Seed.
---

# Colossal Titan & Mammoth Sculpting

Build colossal quadruped titans, mammoth behemoths, and apex horned guardians out of pure Roblox primitives (`Part`, `WedgePart`, `CornerWedgePart`, `Cylinder`).

This skill translates the visual language of the **Cosmic King Mammoth** reference (`references/cosmic-mammoth-reference.png`) into production-ready Steal a Seed Luau procedural forms.

---

## 1. Reference Analysis: The Cosmic King Mammoth

Inspect `references/cosmic-mammoth-reference.png` before building:

* **Observed**:
  * **Silhouette**: Immense, low-slung, forward-leaning quadruped posture. Massive shoulder vault that slopes down to shorter rear hips.
  * **Signature Headgear**: Two massive crescent tusks that sweep wide outward and upward, glowing brilliantly (ivory to cyan neon).
  * **Trunk & Brow**: A stepped, downward-curving trunk flanked by deep-set brow plates and angled ears.
  * **Crest & Mane**: Multi-layered faceted neon cyan spikes/mane running along the crown and upper spine.
  * **Surfaces**: Tactile Roblox studs on the dark obsidian/slate body plates, contrasted with smooth neon fissure accents.
  * **Overhead Badge**: 3-line `BillboardGui` indicating Rarity ("Cosmic" in purple), Species Name, and Rate.

---

## 2. The 3-Mass Hierarchy for Behemoths

1. **Dominant Mass (The Vaulted Carapace)**
   * The torso must read as an arched, impenetrable bunker, not a generic box.
   * Combine a central core block with two angled shoulder mantle wedges (`Pitch = -15°`, `Roll = ±20°`) to create a wide, intimidating wedge-shaped chest taper.
   * Inset glowing neon accent channels between the shoulder mantle and spine plates.

2. **Supporting Mass (Four Pillar Legs)**
   * **Never use bare rectangular columns.** Each leg consists of:
     * *Thigh / Shoulder Mantle*: Overlaps deep inside the torso mass.
     * *Ankle Collar*: Thickened transitional block angled slightly inward.
     * *Footpad & Toes*: Wide sole grounded firmly at `Y = 0` (no floating daylight) with 2–3 proud stepped wedge toes.
   * **Stance**: Front legs set wider and slightly forward (`Yaw = ±14°`); rear legs angled back to ground the stance.

3. **Signature Shape (Sweeping Curved Tusks & Trunk)**
   * A single straight wedge looks like a tooth, not a tusk.
   * Construct tusks as a **chained arc of 3 to 4 tapering wedges**:
     * Segment 1 (Root): Extends forward from the jaw (`Yaw = ±30°`).
     * Segment 2 (Mid Curve): Pitches upward and rolls outward (`Pitch = 25°`, `Roll = ±35°`).
     * Segment 3 (Tip): Curves up and inward (`Pitch = 40°`, `Yaw = ∓15°`, tapering to a sharp edge).
   * Material transitions from smooth ivory (`C.StarIvory`) to radiant cyan `Neon` (`C.NebulaCyanGlow`).

---

## 3. Luau Implementation Patterns

### Chained Tusk Geometry Function
```luau
local function buildCurvedTusk(parent: Instance, rootCF: CFrame, side: number): Model
    local tusk = Instance.new("Model")
    tusk.Name = if side < 0 then "LeftTusk" else "RightTusk"
    tusk.Parent = parent

    -- Segment 1: Base flare
    local seg1CF = rootCF * CFrame.Angles(math.rad(10), math.rad(side * 28), math.rad(side * 15))
    local p1 = Instance.new("WedgePart")
    p1.Name = "TuskBase"
    p1.Size = Vector3.new(0.9, 1.8, 0.9)
    p1.CFrame = seg1CF * CFrame.new(0, 0.8, 0)
    p1.Color = Color3.fromRGB(240, 240, 245)
    p1.Material = Enum.Material.SmoothPlastic
    p1.Parent = tusk

    -- Segment 2: Mid upward sweep
    local seg2CF = seg1CF * CFrame.new(0, 1.6, 0) 
        * CFrame.Angles(math.rad(30), math.rad(side * 12), math.rad(side * 20))
    local p2 = Instance.new("WedgePart")
    p2.Name = "TuskMid"
    p2.Size = Vector3.new(0.7, 1.6, 0.7)
    p2.CFrame = seg2CF * CFrame.new(0, 0.7, 0)
    p2.Color = Color3.fromRGB(180, 245, 255)
    p2.Material = Enum.Material.Neon
    p2.Parent = tusk

    -- Segment 3: Sharp luminous tip
    local seg3CF = seg2CF * CFrame.new(0, 1.4, 0) 
        * CFrame.Angles(math.rad(35), math.rad(-side * 10), 0)
    local p3 = Instance.new("WedgePart")
    p3.Name = "TuskTip"
    p3.Size = Vector3.new(0.45, 1.4, 0.45)
    p3.CFrame = seg3CF * CFrame.new(0, 0.6, 0)
    p3.Color = Color3.fromRGB(0, 230, 255)
    p3.Material = Enum.Material.Neon
    p3.Parent = tusk

    return tusk
end
```

### Downward Segmented Trunk
```luau
local function buildTrunk(parent: Instance, headCF: CFrame): ()
    local currentCF = headCF * CFrame.new(0, -0.2, -1.2) * CFrame.Angles(math.rad(-30), 0, 0)
    local segments = {
        { size = Vector3.new(1.1, 1.2, 1.0), pitch = -15 },
        { size = Vector3.new(0.9, 1.1, 0.8), pitch = -20 },
        { size = Vector3.new(0.7, 0.9, 0.6), pitch =  15 },
    }
    for i, seg in ipairs(segments) do
        currentCF = currentCF * CFrame.Angles(math.rad(seg.pitch), 0, 0)
        local part = Instance.new("Part")
        part.Name = "TrunkSegment" .. i
        part.Size = seg.size
        part.CFrame = currentCF * CFrame.new(0, -seg.size.Y * 0.5, 0)
        part.TopSurface = Enum.SurfaceType.Studs
        part.Color = Color3.fromRGB(30, 25, 42)
        part.Parent = parent
        currentCF = currentCF * CFrame.new(0, -seg.size.Y, 0)
    end
end
```

---

## 4. Rigging & PlantSway Compatibility

All behemoths must adhere to the `PlantSway` rig naming convention so idle breathing and walking cycles animate cleanly:
* `FrontLeft_TitanThigh`, `FrontLeft_TitanFootPad`
* `FrontRight_TitanThigh`, `FrontRight_TitanFootPad`
* `RearLeft_TitanThigh`, `RearLeft_TitanFootPad`
* `RearRight_TitanThigh`, `RearRight_TitanFootPad`
* `TitanSkull` (head root)
* `TitanCarapace` (primary root part)

---

## 5. Lighting & Particle Budgets

* **PointLight**: Maximum 1 per behemoth, placed inside the primary focal point (e.g. the Supernova Core or Skull Maw). Range: 14–18, Brightness: 2.0–3.0.
* **ParticleEmitter**: Maximum 1 attachment. Use `rbxasset://textures/particles/sparkles_main.dds` for cosmic star-dust or starlight motes. Keep rate <= 24 to preserve mobile 60 FPS performance.
* **Total Part Budget**: 70 to 90 primitive parts for an Apex Mythic / Colossus.
