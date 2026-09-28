# Shape construction: forms first, decoration last

Build in three levels and finish each before starting the next. Review every level in the plain
and silhouette passes ([visual review](visual-review.md)); if a level fails, fix it there instead
of spending detail on the next.

## Level 1 -- primary forms

The overall silhouette: head-to-body proportion, the body's length/height/width bias, shoulders
and hips, where the limbs or roots leave the body, the signature feature's mass.

- Choose a clear bias (long, tall, wide, squat). Neighbouring species should differ here, not
  only in accessories.
- Build each mass from **a few intersecting, rotated, tapered forms**. A single untouched sphere,
  box or cylinder is never a finished head, torso, muzzle, hand or foot.
- Put the weight over the feet. Draw the centre of mass down to the ground in the side view; it
  must land inside the footprint.
- Leave **negative spaces** that read: between the legs, under the jaw, between a crest and the
  back. A silhouette with no holes reads as a lump.
- Check: can the creature be named from the black silhouette in front, side, three-quarter and
  top views?

## Level 2 -- secondary forms

Muzzle, jaw, cheeks and brow; limbs, joints, paws, roots; leaves, petals, horns, tusks, wings and
armour plates. These explain how it stands, eats and moves.

- **Faces have depth.** Split the head into brow, cheek and jaw masses. A mouth is a recess bounded
  by those masses, visible as a cavity in three-quarter and side views -- not a dark shape on the
  surface. Eyes sit under a brow; give the lids and brow the expression.
- **Limbs connect and articulate.** Shoulder into upper limb into joint into foot, with each
  transition overlapping the next. Check the side view: a limb that looks attached from the front
  can float behind the shoulder.
- **Feet bear weight.** A sole or pad on the ground plane with purposeful toes or root tips, not a
  square platform. The lowest point of the model is the ground (z = 0 in Blender).
- **Horns, claws, tusks and roots curve AND taper** along a deliberate direction of growth: thick
  at the root, sharper toward the tip, the curve continuing the body's flow. A straight wedge is a
  tooth, not a tusk.
- **Botanical layers follow the body underneath**: leaves and petals overlap in the direction they
  grow, bark plates follow the curvature of the mass they cover, and each layer has thickness.
  Vary a few large petals; do not wallpaper the body with same-size ones.

## Level 3 -- tertiary detail

Teeth, seams, veins, studs, knots, speckles, small accents.

- Concentrate detail at the focal points (face, signature feature, the hands or root tips) and
  keep quiet areas between clusters.
- Detail must be readable at gameplay distance or it is noise. Check the true-size gameplay tile.
- Teeth and spikes have roots in the jaw or body and an uneven rhythm; one chipped, one longer.

## Plants are not monsters

Pick the body plan from the plant's identity: rooted mound, bulb, tripod of roots, vine coil,
column, cap-and-stalk, flower head on a stem, shrub. A calm bulb with a beautiful crown can be as
premium as a horned beast. Do not force every species into a muscular quadruped.

## Anti-patterns

- a sphere body covered in spikes, or head-on-body "snowman" stacking (the smoke-test creature
  shows this failure -- see [design brief](design-brief.md));
- decorations floating off the surface, or attached only at a point;
- thin detail that disappears at gameplay distance and flickers on a phone;
- glow, particles or bloom used to hide weak geometry;
- rings of identical parts at even angles, fences of equal plates, spikes on every edge;
- every feature perfectly symmetric -- use controlled asymmetry (one longer petal, one offset
  plate) while the mass stays balanced.

## How the levels map to the two routes

| level | Route A (part vocabulary) | Route B (mesh) |
| --- | --- | --- |
| primary | 3-5 intersecting Balls/Blocks/Cylinders per mass, rotated and overlapped until the outline stops reading as a primitive | sculpted masses, then retopology |
| secondary | chained Cylinders or Wedges shrinking toward the tip; brow Wedge, cheek Balls, jaw Block around a recess with a set-back interior | modelled or sculpted, part of the retopologised surface |
| tertiary | a few parts at focal points only; studs come from the surface setting | normal/colour map detail, not geometry, where possible |

Route A always loses some of a smooth study; measure and show how much
([Route A](route-a-primitive-production.md)).
