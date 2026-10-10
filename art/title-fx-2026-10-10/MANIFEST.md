# Rebirth title FX — upload set (2026-10-10)

Small cosmetic sprites around the rebirth titles over players' heads (`GameConfig.TitleFX`, `Shared/TitleFX.luau`, `OwnerTitleUI`). Every sprite is a white silhouette; the game tints it.

## Licences

Both packs are Kenney, **CC0 1.0** (public domain). Credit is optional.
- `LICENSE-kenney-foliage-sprites.txt`: Kenney Foliage Sprites, copied unchanged from `kenney_foliage-sprites/License.txt`.
- `LICENSE-kenney-smoke-particles.txt`: Kenney Smoke Particles, copied unchanged from `kenney_smoke-particles/license.txt`.

The originals on the Desktop were only read. `source/` holds unchanged copies of the seven files used.

## What to upload: the 8 PNGs in `upload/`

Each one is cut to its own outline and centred on a transparent square, with a 6% margin. The leaves, blossom and sprigs are scaled from 1024 to 256; the two puffs from about 380 to 256. Every corner is fully transparent.

| Upload file | Source (pack / file) | Source px | Upload px | `GameConfig.TitleFX.Art` key | Used for |
|---|---|---|---|---|---|
| `upload/leaf_round.png` | Foliage, `PNG/Flat/sprite_0030.png` | 1024 x 1024 | 256 x 256 | `LeafRound` | nature leaf; tinted pink, a bloom petal |
| `upload/leaf_point.png` | Foliage, `PNG/Flat/sprite_0031.png` | 1024 x 1024 | 256 x 256 | `LeafPoint` | nature leaf |
| `upload/leaf_serrate.png` | Foliage, `PNG/Flat/sprite_0038.png` | 1024 x 1024 | 256 x 256 | `LeafSerrate` | nature leaf; tinted gold, the loose leaves of the gold titles |
| `upload/blossom.png` | Foliage, `PNG/Flat/sprite_0040.png` | 1024 x 1024 | 256 x 256 | `Blossom` | bloom blossom |
| `upload/sprig_right.png` | Foliage, `PNG/Flat/sprite_0041.png` | 1024 x 1024 | 256 x 256 | `SprigRight` | gold sprig, right of the words |
| `upload/sprig_left.png` | Foliage, `PNG/Flat/sprite_0041.png`, mirrored | 1024 x 1024 | 256 x 256 | `SprigLeft` | gold sprig, left of the words |
| `upload/mist_a.png` | Smoke, `PNG/White puff/whitePuff00.png` | 381 x 346 | 256 x 256 | `MistA` | mystic mist, tinted lilac, faint |
| `upload/mist_b.png` | Smoke, `PNG/White puff/whitePuff04.png` | 375 x 378 | 256 x 256 | `MistB` | mystic mist, tinted lilac, faint |

`preview_day_night.png` shows each upload in its tints on a day sky and a night sky. It is a mock-up, not a game capture.

## Rules followed

- Only single leaf, blossom and sprig silhouettes. No grass clumps or bushes, and not `sprite_0036`, a seven-point leaf that reads as cannabis.
- The puffs are used as still pictures, moved by position, rotation, size and transparency. `whitePuff00`–`24` are not played as a flipbook.
- No black smoke, and no lightning (these packs have none).

## Wiring the ids

Upload the 8 PNGs as Images, then put each id into `GameConfig.TitleFX.Art` under its key, as `"rbxassetid://<id>"`. Until a profile's ids are all filled in, that profile draws nothing. Never put another upload in their place.

| Profile | Needs | Titles (current ladder) |
|---|---|---|
| `nature` | LeafRound, LeafPoint, LeafSerrate | SPROUT, SEEDLING, GARDENER, GREEN THUMB, BOTANIST, HERBALIST, THORN KNIGHT, ELDER ROOT, CANOPY LORD |
| `bloom` | LeafRound, Blossom | BLOOM WARDEN, EVERBLOOM |
| `gold` | SprigLeft, SprigRight, LeafSerrate | ANCIENT OAK, WORLD TREE |
| `mystic` | MistA, MistB | GROVE KEEPER |
| none | — | GAIA keeps its rainbow alone |
