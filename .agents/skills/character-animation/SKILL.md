---
name: character-animation
description: Author and integrate procedural Roblox character animation for approved rigs, including sleep and wake blends, locomotion, breathing, blinking, secondary motion, and gameplay-state transitions. Use when changing character motion, animation profiles, state blending, or the client/server ownership of animated joints. Do not use for visual redesign.
---

# Character animation

Make motion reveal weight, anatomy, and gameplay state without changing the approved appearance.
Read [`../character-rigging/SKILL.md`](../character-rigging/SKILL.md) before adding seams or changing
the physical assembly. Read [`../organic-roblox-form/SKILL.md`](../organic-roblox-form/SKILL.md) only
when the motion concept itself is still unapproved.

For Steal a Seed nest guardians, inspect `ParentAnim.client.luau`, `NestService.luau`, the relevant
parent builder, and `SoundCues.client.luau`. The existing runtime contracts outrank a preview loop.

## Translate the approved performance

Write a state-and-channel map before coding. For each approved action, identify:

- the gameplay signal that requests it;
- the joints or cosmetic groups it drives;
- the asleep and awake endpoints;
- the blend duration or response rate;
- the clock source; and
- whether server or client owns the property.

An autonomous approval cycle must not ship as the gameplay controller. Map its poses onto real
replicated state. For a nest parent, sleeping, waking, chasing, returning, and settling come from the
nest lifecycle; the preview's timeline only supplies poses and motion quality.

## One owner per property

The server owns authoritative root translation, Humanoid movement, chase decisions, and collision.
Clients own cosmetic `Motor6D.C0` animation when it does not affect gameplay. Do not let both sides
write the same CFrame or joint.

Use `Motor6D.C0`, not `Motor6D.Transform`, for this project's procedural parents. Capture the rest
pose once and compose every frame from it:

```luau
local rest = motor.C0
motor.C0 = rest * poseDelta
```

Never accumulate from the previous frame. Never replace a rest socket with an absolute animation
CFrame. If collision must follow a whole-body pose, move ownership of that entire seam to the server
and stop writing it on clients.

## Drive motion from the right signal

- Use distance travelled for legs and planted locomotion. Clock-driven feet slide.
- Use actual horizontal velocity, not `Humanoid.MoveDirection`, to decide whether the body is moving.
- Use wall-clock time for breathing, blinking, jaw motion, glow pulses, and other unplanted details.
- Seed a stable phase from the model or nest position so multiple creatures do not move in lockstep.
- Use replicated attributes for gameplay state. Do not infer a server-private state from timing.

If the available attribute cannot distinguish a required transition, add the smallest explicit
replicated signal rather than guessing. Keep state ownership in the existing gameplay service.

## Blend the complete pose

Maintain a scalar such as `wake`, normally 0 asleep and 1 awake, and ease it toward the replicated
target. Drive every sleep/wake channel from that same scalar so the body, head, arms, lids, hood,
throat, light, and secondary forms arrive together.

Author every value between the endpoints. A pose that works only at exactly 0 and 1 will clip or
detach during the transition. Avoid snaps in visibility, light intensity, size, or particles as well
as joints.

Keep species-specific values in profiles. Adding a new guardian must not change the fallback profile
or the numbers of an existing one. Declare profile tables before any tracking code that reads them;
Luau local declaration order can otherwise leave startup tracking with nil profiles.

## Express weight and life

Use a few distinct channels rather than constant motion everywhere:

- large masses move slowly with restrained amplitude;
- arms and legs bend from their sockets and respond to contact or travel;
- head, hood, leaves, fronds, or bristles may lag the body by a small phase;
- breathing moves a connected chest/shoulder/head relationship, not a floating detail;
- sleeping eyes remain closed, while awake blinking is brief and irregular-looking;
- lights and particles support a focal action and do not become permanent fog; and
- paired parts use small amplitude or phase differences when perfect symmetry looks mechanical.

Measure the combined peak after all parent and child motion is applied. Several safe-looking angles
can add into a large sweep or floor strike.

## Track replicated rigs robustly

Use one client update loop over a tracked set, not one unguarded loop per creature. Avoid per-frame
tables, Instances, connections, tweens, raycasts, or other allocation.

A tag may replicate before `PrimaryPart` or the Motor6Ds. If required pieces are missing, wait or
retry for a bounded time instead of abandoning the model permanently. Remove dead models from the
tracked set when the tag or root disappears. Optional cosmetic joints may be absent; required
contract joints should fail loudly during verification.

Edit-mode approval loops must use a generation guard so rerunning a preview stops the old loop.
Production animation belongs in the existing tracked runtime animator rather than in builder-spawned
Heartbeat connections.

## Steal a Seed nest acceptance

Test the parent created by the real `NestService` path in Play:

1. It begins in its approved sleeping pose at the nest and continues breathing or other approved
   sleep motion.
2. Taking a real pod causes a continuous wake transition with no detached details or snap.
3. Awake locomotion follows distance and stops when the parent stops.
4. Chase, throw, return, and reset behavior remain server-authoritative.
5. Returning home reverses the complete blend and settles into sleep.
6. Eyes, lights, particles, sounds, and secondary groups agree with the replicated state.
7. A second instance uses a different stable phase.
8. Removing and recreating the model does not stack animation work.
9. Low frame rate and intermediate blend values do not expose clipping or floor strikes.
10. Existing parents retain their exact appearance and animation profiles.

Capture evidence from the live nest parent. A moving approval mockup or isolated production builder
does not prove lifecycle integration.
