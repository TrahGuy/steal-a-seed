# Mobile HUD fixes and the summon's secret toast — plan (2026-10-17)

The owner's request, with two phone screenshots (2000 x 900, v1067 live):

> "this needs fixing on mobile, also after I spawn a Secret, add an additional notification like when a
> secret spawns in rainbiome with that secret text effect"

## The owner's answers

| Question | Answer |
|---|---|
| Which mobile problems to fix | All four: the PERFORMANCE MODE label breaking mid-word ("PERFORMA / NCE MODE"); the POD RUSH card mid-screen; the SERVER UPDATE restart notice drawn over the POD RUSH card; sprout labels showing through the card |
| Where the POD RUSH tracker goes on phones | **Top strip** (recommended): the one-line strip, under the top row, the middle clear |
| Did "A SECRET EGG SPAWNED ON {BIOME}!" show after a summon | **No, never saw it** |
| The summon's extra notification | **The admin line in sheen**: "{admin} summoned a SECRET!" gets the Secret word's sweep |
| The 2026-10-09 "POD RUSH GUI must be transparent" rule vs. labels showing through | **A plate on the phone strip only**; the desktop card and the end card stay transparent |
| The restart notice and the tracker want the same spot | **The notice goes below the strip**: the tracker keeps its place; the restart notice and admin announcements move under it |
| The egg toast lost under an open menu | **Wait for the menu**, for everyone: a secret egg toast waits while a menu is open and shows when it closes, up to 30 s late |
| Which screens get the strip | **Phones only**; tablets and desktops keep the full card |
| The phone's Roblox Text Size | **Default** (yet every fixed-size text on that phone draws ~3 px larger than designed: 10 -> 13 on the switches, 14 -> 17 and 13 -> 16 on the restart notice; scaled text is unchanged) |
| Tight HUD labels for a larger text size | **Words never split**: grow with the setting only while whole words still fit; otherwise the largest size that fits |

## What was found

- **The egg toast was there, then trimmed.** A summon sends the egg toast and then the admin's line. With
  a panel open (the console), the notice stack keeps to one line and the oldest gives way, so the
  admin's line put the egg toast out at once.
- **PERFORMANCE fits its room with no margin.** On a phone's row the label is 73 pt wide and
  "PERFORMANCE" measures 73.0 pt at 10 px (LuckiestGuy). Any growth breaks the word: at ~13 px the engine
  wraps it as "PERFORMA / NCE MODE".
- **Fixed-size text grows on the owner's phone.** That is the engine's preferred text size at work
  (GuiService.PreferredTextSize; TextService measures include it; TextScaled text and a
  UITextSizeConstraint's limits are exempt).
- **The restart notice and the tracker share a spot.** Both stand 8 px under the boost band
  (AnnouncementUI; PodRush.trackerRect), and neither knew of the other.

## Commits (each its own, on wip)

1. The summon's admin line in sheen.
2. The secret egg toast waits for an open menu.
3. The switch labels never split a word.
4. The POD RUSH strip on phones: at the top, on a plate; announcements under the tracker on every screen.
