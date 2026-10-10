# Codex brief: three more studded card textures (Mythic, Secret) — 2026-10-10

The owner: "how abt secret, i think we need codex to generate more cards textures for them and add shine effect".
Claude builds the shine and the wiring in code. This brief is the art only.

## What the cards are

The six textures in `art/textures/colorful-studs-2026-10-04/` (lime, sky, purple, gold, coral, rainbow) are the
rarity cards behind Bag tiles, MY PLANTS cards and the plot's TOP CREATURES board. The planned ladder:
Uncommon lime, Rare sky, Epic purple, Legendary gold, **Mythic white** (the owner: "their background must be
white"), **Secret dark**, Divine rainbow. Common keeps its plain card. Bats and traps get the same ladder.

## Make these three, one image_gen call each

| File | For | Palette line for the prompt |
|---|---|---|
| `studs-pearl-white-v1.png` | Mythic | clean pearl white upper area softly transitioning to cool silver-white below; the studs read through soft cool-grey bevel shadows and faint pearly highlights; the card as a whole stays WHITE, never a grey card |
| `studs-obsidian-silver-v1.png` | Secret, option A | deep charcoal upper area softly transitioning to near-black obsidian below; stud bevel highlights in cool silver with a faint cyan tint |
| `studs-midnight-holo-v1.png` | Secret, option B | deep midnight navy-black base; the stud tops carry a subtle holographic tint shifting cyan to violet to pink across the canvas; no stars, no sparkles |

The owner picks one Secret option after seeing both.

Use the prompt in `art/textures/colorful-studs-2026-10-04/generation-prompts.md` word for word and change only
its `Palette:` line. Reference image: `art/textures/colorful-studs-2026-10-04/studs-coral-red-v1.png`, for stud
size, spacing and bevel only, so the new cards match the six (about 12 x 12 square studs). Keep
"no large gloss, no white glare": the game adds its own moving shine on top, and a baked one would double it.

## Hard requirements

- 1254 x 1254, opaque RGB PNG, edge to edge. No border, no rounded corners, no text, no icons.
- About 12 columns x 12 rows of raised SQUARE studs, regular grid, like the coral texture.
- Restrained contrast. Dark words must read on the white one; light words and silver outlines must read on the
  two dark ones.
- Not seamless; the game crops a centred window, as with the six.

## Deliver

- The three PNGs in this folder, plus a `generation-prompts.md` with the exact prompts used and a 512-px
  preview of each.
- A short `KB/HANDOFF.md` entry: files, sizes, what you checked.
- Do not upload, wire, change code or GameConfig, or publish. The owner uploads the PNGs. Claude wires the ids
  and commits the art with the wiring. Never `git add -A`.
