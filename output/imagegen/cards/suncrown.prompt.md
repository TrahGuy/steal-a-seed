# Suncrown — illustrated card art

    species    suncrown
    rarity     Legendary (animated label: slow gold shine)
    biome      dustbowl
    role       THE TALL / BROAD SAMPLE — widest silhouette of the three
    output     art/cards/suncrown.png, 1024 x 1024

## Identity, off the built model — none of this is optional

    Body    255,198, 38   the sun face
    Crown   239,116, 25   the orange rays
    Accent  210, 61, 45   the coral-red rays and the pendant studs
    Leaf    128,122, 78   dusty olive
    Stem    178,158,106   pale sandy stalk
    Soil    124, 76, 50

    rays    TWO RINGS, not one corolla:
              SunRay x8   the inner, shorter ring
              Ray x9 + RayTip x9   the outer, longer ring
              RayAccent x3   the three coral-red rays among them
    face    FaceCore x1, FaceRow x4, FaceBack x3, FaceNotch x2,
            SunCore x4, LeftEye/RightEye x1, LeftPupil/RightPupil x1,
            LeftLid/RightLid x1, Cheek x2, Smile x3
    body    Collar x5 (the cyan band at the throat), Neck x1, Stem x1,
            PendantRod x4, Leaf x4
    roots   CentralTaproot x1, RearHeelL x1, RearHeelR x1,
            FrontCoral x1, FrontGold x1, FrontOrange x1
            -- it stands on splayed root-feet, it does not sit in a heap

**The eyes are half-closed and content**, not wide. Dark navy lids over the
upper half of each eye. That sleepy, sunlit expression is the character.

**The collar is cyan** — the one cool colour on an otherwise hot creature, and
the thing that stops the palette going flat. Keep it.

**Nine outer rays, eight inner.** An even, symmetrical flower is the wrong
creature. Three of the outer rays are coral-red and the rest gold-to-orange.

## Pose

Head tilted slightly, rays fanned wide and asymmetrically — one or two rays
bent or nicked, as if weathered. Front root-feet planted apart, taking the
frame's full width. Outer ray tips may be cropped by the frame edge; the face,
the collar and at least one full root-foot may not.

## Scene

Dustbowl at low sun. Cracked hardpan in the near ground with the crack pattern
readable, a sandstone shelf behind, dunes receding into warm haze. Dust
suspended in the light. Long shadow thrown from the plant toward the viewer's
lower left, so the light source agrees with the highlight on the face.

Warm, dusty, high-key — but keep the background values well below the plant's
gold or the creature disappears into its own desert.

## Layout

    artwork height   plant fills ~82%; because it is WIDE, let the ray tips
                     touch or pass the left and right edges rather than
                     shrinking the whole creature to fit
    garden crop      face, collar and the inner ray ring inside the middle
                     70%; the outer ring is expendable to the crop
    no text          none, anywhere
