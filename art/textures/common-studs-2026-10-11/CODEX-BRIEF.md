# Codex brief: the Common card's studded texture, STONE GREY (2026-10-11)

The owner: Common plant cards are still plain white, the only rarity without its own studded texture. Mythic and
Divine already wear studded pearl WHITE, so a Common can be mistaken for a Mythic at a glance. The owner picked
**stone grey** for Common. Claude wires it in code; this brief covers the art only.

## Where it goes

The existing ladder, Bag tiles, MY PLANTS cards and the plot's TOP CREATURES board:

| Rarity | Texture |
|---|---|
| Uncommon | lime |
| Rare | sky |
| Epic | purple |
| Legendary | gold |
| Mythic / Divine | pearl white |
| Secret | midnight holo |

Bats and traps follow the same ladder. Common becomes **stone grey**: plainly the lowest rung, never mistaken for
the pearl white.

## Make this one, one image_gen call

| File | For | Palette line for the prompt |
|---|---|---|
| `studs-stone-grey-v1.png` | Common | calm warm-neutral stone grey upper area softly transitioning to a slightly deeper slate grey below; the studs read through soft light-grey bevel highlights and gentle charcoal lower-right shadows; the card as a whole stays a mid-light STONE GREY, clearly darker than a white card and clearly lighter than charcoal; no blue, green or brown cast |

Use the prompt in `art/textures/rarity-studs-2026-10-10/generation-prompts.md` (the pearl one) word for word,
and change only its `Palette:` line to the one above. Reference image:
`art/textures/colorful-studs-2026-10-04/studs-coral-red-v1.png`, for stud size, spacing and bevel only, so it
matches the others (about 12 x 12 square studs). Keep "no large gloss, no white glare": the game adds its own
moving shine, and a baked one would double it.

## Hard requirements

- 1254 x 1254, opaque RGB PNG, edge to edge. No border, no rounded corners, no text, no icons.
- About 12 columns x 12 rows of raised SQUARE studs in a regular grid, matching the coral and pearl textures'
  spacing.
- Restrained contrast. The game puts cream words on a dark ink band and a green income line over it; both must
  still read.
- Not seamless. The game crops a centred window, as with the others.
- It must sit clearly apart from `rarity-studs-2026-10-10/studs-pearl-white-v1.png` (much greyer) and
  `studs-obsidian-silver-v1.png` (much lighter).

## Deliver

- In `art/textures/common-studs-2026-10-11/`:
  - `studs-stone-grey-v1.png`;
  - a 512-px preview;
  - `generation-prompts.md` with the exact prompt used;
  - `compare.png`: 256-px crops of stone grey, pearl white, obsidian, lime and coral side by side, so the owner
    can see Common sits apart.
- A short `KB/HANDOFF.md` entry: files, sizes, what you checked. Stage only your own hunk; leave other agents'
  lines alone.
- Do not upload, wire, change code or GameConfig, or publish. The owner uploads the PNG and Claude wires the
  id. Never `git add -A`.
