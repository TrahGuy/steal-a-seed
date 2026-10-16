# PLANTS AND CREATURES BECOME SPROUTS — the plan (2026-10-16)

**Status: APPROVED 2026-10-16.** The owner: "should we change the "plants" "creatures" into sprouts? ask
me querstions". Eight answers, every recommendation taken. Built by Claude (desktop), "Build it here".

## The owner's answers

| Question | Answer |
| --- | --- |
| Which words? | **Plants and creatures:** one name, "sprout", for everything that hatches, in what players read ("MY SPROUTS", "SPROUTS 1/5", "TOP SPROUTS", "YOU HATCHED YOUR FIRST SPROUT!", the Mysterious Pod's "RANDOM SPROUT"). |
| The verb "plant"? | **Keep it.** You plant a sprout: "SELECT TO PLANT", "Plant or sell one" stay. Only the noun changes. |
| Hidden names? | **Keep them:** analytics (the funnel's "First Plant Hatched", events), code ids, saved data and asset folders. Saves load as before and Creator Hub's series stay unbroken. |
| Old What's New entries? | **Keep as written.** |
| The almanac's title? | **"Sprout Almanac".** The Index button keeps its name. |
| A What's New line about it? | **No.** |
| Testing? | **Specs follow the new words, then one guarded Play on the phone emulator** to capture the busiest screens (the plot sign, Garden, the almanac, the Bag, the guide). |
| Who builds it? | **Claude, here;** pushed on the owner's OK. |

## What changed

- **About 85 player-facing strings in 20 files** now say "sprout", "Sprout" or "SPROUT" where they said "plant" or "creature", in the same case. Among them:
  - the plot sign ("SPROUTS 1/5"), the Garden ("MY SPROUTS", "SELECT A SPROUT", "BEST SPROUTS EQUIPPED");
  - the "Sprout Almanac", the Bag ("Sprout storage: 4/24"), "SPROUT STORAGE FULL";
  - the plot boards ("TOP SPROUTS", "NO SPROUTS YET");
  - the guide ("Hatch your first sprout!", "EQUIP YOUR SPROUT", "You hatched your first sprout!");
  - the boosts and passes ("+25% SPROUT INCOME", "Every grown sprout in your garden earns ×2");
  - the wheel's "Invite Sprout", the Mysterious Pod's "A sprout from the Enchanted Mist inside", the rebirth panel's YOU KEEP chips;
  - the admin console and its broadcasts ("GROWN SPROUT", "RANDOM SPROUT · RANDOM SIZE").
- **Kept, as the owner chose:**
  - the verb ("SELECT TO PLANT", "Plant or sell one to make room.", "Plant it to earn cash!", "Nothing planted yet");
  - every log line, assert and spec label;
  - ids, attributes and saved fields (`Plants`, `plant` item kinds);
  - the asset folders ("Greenhollow Plants/...");
  - the analytics names ("First Plant Hatched" and the other funnel steps);
  - the older What's New entries.
- **Nothing in Studio outside `src/`** (hand-made signs, prompts) said either word: an Edit scan found none.
- **Outside the game, the owner's:** the Roblox page's text, badge names and store listings, if any of them say "plant" or "creature".

## Tested

- **The whole suite: 164 of 164.** Its first run after the rename had 15 specs pinning the old words; each pin followed, then all 15 green. NoticeSpec pinned the owner's own example, "Pick up a plant or upgrade your plot.", word for word: it follows the rename too.
- **One guarded Play on the phone emulator** (705 x 338, touch; the throwaway store; the first hatch's harness again, gated on that store, deleted after).
  - The guide: "Hatch your first sprout!" and "CONGRATULATIONS! YOU HATCHED YOUR FIRST SPROUT!".
  - The plot sign "SPROUTS 1/5"; every plot's "TOP SPROUTS" board.
  - The Garden: "MY SPROUTS", "SELECT A SPROUT".
  - "SPROUT ALMANAC"; the Bag's "Sprout storage: 0/36 · Pods: 1/60".
  - Each one fits.
- **Two labels the Play found, fixed after it:** the Bag's "Plants" tab (InventoryModel.Categories) and the Mist odds' "Creatures" heading. Both now say "Sprouts". Spec-checked, not seen again in Play.
- **Found by the same Play, not part of the rename:** on that phone the first hatch's card never shows. KB/HANDOFF.md has the detail.
