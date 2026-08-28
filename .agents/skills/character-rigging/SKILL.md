---
name: character-rigging
description: Convert an approved primitive-built Roblox character or biome guardian into a production rig with stable Motor6D sockets, welded cosmetic groups, correct roots, scaling, and collision. Use before creating or changing a moving character's joint hierarchy, rig builder, root contract, or physics assembly. Do not use for static plant geometry alone.
---

# Character rigging

Build a rig that preserves the approved sculpture and gives every intended motion a real,
well-placed seam. A preview animation is evidence of the desired result; it is not automatically a
production rig.

Read [`../organic-roblox-form/SKILL.md`](../organic-roblox-form/SKILL.md) when shape or appearance is
still being designed. Read [`../luau-conventions/SKILL.md`](../luau-conventions/SKILL.md) before
writing the production Luau. For nest guardians, inspect `ParentModel.luau`, the biome-specific
parent builder, `ParentAnim.client.luau`, and `NestService.luau` before choosing the hierarchy.

## Lock the approved source

Before translating a Studio mockup, record its visible part names, classes, sizes, CFrames, colours,
materials, surfaces, effects, intended pivots, and counted part total. Preserve the approved
silhouette and proportions. Do not redesign an approved character to make the rig easier.

Treat preview-only Models and Heartbeat loops as temporary authoring aids. Production geometry must
be deterministic Luau built from the base CFrame and the requested height or scale. Never depend on
a Workspace preview, saved prefab, or its animation loop at runtime.

## Start with an articulation map

Divide the sculpture into anatomical groups before creating joints:

- one authoritative root assembly;
- one torso or body group;
- one group for each limb, head, jaw, lid, hood, frond cluster, or other mass that must move
  independently; and
- rigid cosmetic descendants welded to the group whose motion they should inherit.

Use a `Motor6D` only where relative motion is required. Use `WeldConstraint` for parts that must stay
rigid within a group. Every visible part must belong to exactly one moving group. A decorative part
welded across two groups silently defeats the seam; a part welded only to the world root ignores the
approved secondary motion.

Keep the number of seams proportional to the visible action. A guardian may retain its required
contract and add a few cosmetic seams, but do not create a joint for every plate or stud.

## Author sockets in world space

Choose the physical attachment point where the anatomy bends, then derive both joint frames from
that one world-space socket:

```luau
motor.Part0 = parentPart
motor.Part1 = childPart
motor.C0 = parentPart.CFrame:ToObjectSpace(socketCF)
motor.C1 = childPart.CFrame:ToObjectSpace(socketCF)
```

This preserves the authored rest pose exactly. Do not guess `C0` and compensate with an unrelated
`C1`. After construction, verify that the rig is unchanged when every motor is at its rest values.

The animator captures rest `C0` once and composes motion after it:

```luau
motor.C0 = restC0 * poseDelta
```

Never author animation by repeatedly multiplying onto the previous frame; drift is guaranteed.
Keep joint names stable once another script looks them up by name.

## Steal a Seed parent contract

Nest parents currently expose these load-bearing Motor6D names:

```text
RootJoint  Neck  JawJoint  LeftShoulder  RightShoulder  LeftHip  RightHip
```

`RootJoint` connects `HumanoidRootPart` to `Torso` at the model origin so a whole-body sleep pose can
blend around the point where the creature stands. `ParentAnim` finds the other six names directly.
`SoundCues` and `NestService` find the model through the `NestParent` tag and replicated attributes.
Changing those contracts requires updating every consumer and verifying the existing parents.

A biome-specific builder must set the correct model name, `BiomeId`, `Species`, initial `Asleep`
state, optional scaled `SleepBodyPose`, `PrimaryPart`, Humanoid, and `NestParent` tag before returning.
Register it through `ParentModel`'s biome dispatch. Do not fold visually different guardians into one
recoloured builder.

## Root, mass, and collision

For a Humanoid guardian:

- `HumanoidRootPart` is the `PrimaryPart` and must not be massless;
- `Humanoid.RootPart` and `HumanoidRootPart.AssemblyRootPart` must agree;
- moving cosmetic and body parts are normally massless;
- keep collision to the smallest intentional set, currently the torso for nest parents;
- keep non-colliders non-touching and non-queryable unless gameplay explicitly needs them; and
- let the Humanoid own translation and facing instead of teleporting the assembly each step.

Do not pitch the Humanoid root, change `HipHeight`, or fight `AutoRotate` to fake a pose. Put a
whole-body pose on `RootJoint`. If a client-only pose leaves the visible body and server collider in
different places, decide explicitly whether that seam needs server ownership; never have client and
server write the same joint property.

## Scaling

Author in reference units and scale geometry, socket positions, collider dimensions, HipHeight, and
any stored pose translation from the same declared reference height. Scale translation, not angles.
Keep separate height and girth parameters when the approved form uses them; uniform Model scaling
must not erase intended proportions.

At every supported scale, inspect for exposed joints, detached details, self-intersection, floor
penetration, and colliders that no longer match the visible mass.

## Production verification

Verify the built rig, not only the preview:

1. The rest pose matches the approved model from front, three-quarter, and side views.
2. Every intended moving detail follows the correct anatomical group.
3. Joint names, attributes, tags, and `PrimaryPart` exist before consumers track the model.
4. The root remains the assembly root while walking, turning, returning, and sleeping.
5. Only intended parts collide, touch, or query.
6. All intermediate joint poses stay connected and clear of the floor.
7. Existing guardians retain their appearance, part count, and behavior.
8. The real gameplay builder and spawn path create the rig successfully.

For nest parents, the final proof is the parent created by `NestService` in Play. An isolated call to
the builder proves geometry only.
