# Illustrated plant cards — art briefs

Source briefs for the Index/Almanac and Garden card illustrations. One file per
species, named `<speciesId>.prompt.md`, following the convention already set by
`output/imagegen/*.prompt.md` (a render plus the prompt that made it).

## What a brief is for

The cards are **static illustrations**. No 3D model goes on the finished card —
the production model is a *reference*, not the content. Each brief carries the
identity a drawing is not allowed to lose, taken off the built model and the
species sheet rather than off a screenshot, because several things that decide
whether a drawing is right are invisible in a photograph:

* **Supernovus has six legs.** In a three-quarter reference render it reads as a
  quadruped. The model carries `FrontLeft / FrontRight / MidLeft / MidRight /
  RearLeft / RearRight`, each with a thigh, hock, heel, pad and two toes.
* **Suncrown's rays are two rings**, nine `Ray` + nine `RayTip` over eight
  `SunRay`, not one sunflower corolla.
* **Nubkin's face is nine parts** and its pupils are doubled (`LeftPupil x2`) —
  a pupil and a glint, one shared light, upper-left on both eyes.

Colours are exact `Color3` values from `SeedData`. Copy them; do not eyeball
them off a render, which is lit and will read warmer than the material.

## Rules that apply to every card

* Animation-film / cartoon **illustration** style. Not a render, not a
  photograph, not a 3D screenshot.
* The plant occupies roughly **75–85% of the artwork height**, adjusted for
  silhouette. Close and expressive. No pedestal, no tiny specimen in empty space.
* Cropping minor extremities is allowed and encouraged; identifying horns,
  petals, mouths, root systems and limb counts are not croppable.
* The background is a **distinct illustrated environment per species**, lit and
  angled to match the plant. It frames the plant; it never competes with it.
* **No text of any kind in the artwork.** Names, rarity and statistics are drawn
  by the UI over the top. An illustration with a name baked in cannot be
  re-used by the Garden card or survive a rename.
* Deliver at **1024 x 1024** (Index) — see `layout` in each brief for the safe
  area the Garden crop takes.

## Pipeline

1. Produce the PNG into `art/cards/<speciesId>.png`.
2. Serve the folder over HTTP and upload it (see KB/HANDOFF.md for the verified
   command shape); the uploader returns a real `rbxassetid://`.
3. Record the id in the species→art manifest in `GameConfig.Card`.

**Do not hand-write an asset id into the manifest that did not come out of an
upload.** A wrong id fails silently as a blank card.
