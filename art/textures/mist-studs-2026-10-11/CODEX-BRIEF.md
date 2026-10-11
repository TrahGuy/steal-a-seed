# Codex brief: the Mysterious Pod card's studded texture, ENCHANTED MIST (2026-10-11)

The owner: the Mysterious Pod (Enchanted Mist's reward pod) needs its own card background. Today it shows on
Common's stone grey because its hidden placeholder rarity is Common.

The texture must say **"event item, contents unknown"**. It must never hint at the creature inside, so it can't
look like any rarity's card. Claude wires it in code; this brief covers the art only.

## Where it goes

The rarity ladder, which this texture must NOT resemble:

| Rarity | Texture |
|---|---|
| Common | stone grey |
| Uncommon | lime |
| Rare | sky |
| Epic | purple |
| Legendary | gold |
| Mythic / Divine | pearl white |
| Secret | midnight holo (navy with a cyan, violet and pink tint) |

Also taken: tickets purple, the trail rainbow. The obsidian charcoal is unused.

The Mysterious Pod gets **mist**, in the Enchanted Mist event's own colours: the mint wisps over a blue-violet
moonlit night.

## Make this one, one image_gen call

| File | For | Palette line for the prompt |
|---|---|---|
| `studs-enchanted-mist-v1.png` | the Mysterious Pod | deep forest-teal upper area softly transitioning to a dusky blue-violet below, like a misty night glade; the stud tops catch soft MINT-green highlights and the stud shadows sink into deep violet; a faint, even, soft mint haze across the whole canvas, no distinct shapes; calm and magical, clearly different from purple, sky blue, navy holo and lime |

Use the prompt in `art/textures/rarity-studs-2026-10-10/generation-prompts.md` (the pearl one) word for word,
and change only its `Palette:` line to the one above. Reference image:
`art/textures/colorful-studs-2026-10-04/studs-coral-red-v1.png`, for stud size, spacing and bevel only (about
12 x 12 square studs). Keep "no large gloss, no white glare": the game adds its own moving shine. No stars, no
sparkles, no wisps drawn as shapes, no leaves, no icons.

## Hard requirements

- 1254 x 1254, opaque RGB PNG, edge to edge. No border, no rounded corners, no text, no icons.
- About 12 columns x 12 rows of raised SQUARE studs in a regular grid, matching the pearl and stone textures'
  spacing (the game measures 86.1 stored px between studs).
- Restrained contrast. The game puts cream words on a dark ink band and a green income line over it; both must
  still read.
- Not seamless. The game crops a centred window, as with the others.
- It must sit clearly apart from purple (`colorful-studs-2026-10-04/studs-royal-purple-v1.png`), sky
  (`studs-sky-blue-v1.png`), holo (`rarity-studs-2026-10-10/studs-midnight-holo-v1.png`) and lime
  (`studs-lime-green-v1.png`).

## Deliver

- In `art/textures/mist-studs-2026-10-11/`:
  - `studs-enchanted-mist-v1.png`;
  - a 512-px preview;
  - `generation-prompts.md` with the exact prompt used;
  - `compare.png`: 256-px crops of mist, purple, sky, holo, lime and stone grey side by side.
- A short `KB/HANDOFF.md` entry: files, sizes, what you checked. Stage only your own hunk; leave other agents'
  lines alone.
- Do not upload, wire, change code or GameConfig, or publish. The owner uploads the PNG and Claude wires the
  id. Never `git add -A`.
