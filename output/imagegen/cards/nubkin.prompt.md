# Nubkin — illustrated card art

    species    nubkin
    rarity     Common (form rarity; static label, no animation)
    biome      greenhollow
    role       THE COMPACT SAMPLE — smallest, simplest silhouette in the game
    output     art/cards/nubkin.png, 1024 x 1024

## Identity, off the built model — none of this is optional

    Body    146,196,106   leaf green, the cube itself
    Crown   176,214,128   the pair of sprout leaves on top
    Accent  242,238,206   pale cream, the sprout tips
    Leaf     86,150,66    the four blades at the base
    Stem    124,182,92
    Soil    124, 76, 50   the heap it sits in

    parts   Head x1 (a CUBE, not a ball), Brow x1, Nub x2 (the two corner
            bumps on the top edge), Sprout x2 + SproutTip x1, Stem x1,
            Leaf x4, Soil x7, Base x1 (invisible)
    face    LeftEye/RightEye x1 each, LeftPupil/RightPupil x2 each
            (pupil + glint), Cheek x2, Smile x3, LeftLid/RightLid x1 each

**The head is a cube.** Rounded-off corners are fine as illustration; a sphere
is not. The two `Nub` bumps sit on the top edge and are part of the silhouette.

**One shared light.** The glint sits upper-LEFT on both eyes, not mirrored. That
is what makes two dark eyes read as one lit face instead of two googly eyes.

**Three-bar smile**, ends lifted. A single curve reads as a grimace.

## Pose

Cheerful, planted, leaning very slightly toward the viewer as if just noticed.
Sprout leaves catching the light. Cropped at the soil line or just below —
the soil heap may leave the frame, the head and both sprouts may not.

## Scene

Sunlit Greenhollow woodland floor, close in. Oversized leaves arching overhead
and out of frame, dappled light falling through them, moss over a fallen log,
a few small pale flowers. Warm mid-morning light from the upper left, matching
the glint on the eyes. Depth by haze, not by clutter — three planes at most:
the leaf canopy above, the plant, and a soft green fall-off behind.

Keep the greens differentiated from the plant's own: the background sits
cooler and darker so a leaf-green cube reads against it.

## Layout

    artwork height   plant fills ~78%, sitting low, headroom above for the
                     canopy so the crop has somewhere to breathe
    garden crop      the Garden card takes a centre-weighted crop; keep the
                     head and both sprouts inside the middle 70% of the frame
    no text          none, anywhere
