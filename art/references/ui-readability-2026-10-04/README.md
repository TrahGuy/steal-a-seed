# UI readability follow-up references

Owner-provided current problem screenshots, saved 2026-10-04. All PNGs are byte-equal copies verified using SHA-256; originals remain untouched.

Folder: D:\KAPE\Steal an Artifact\art\references\ui-readability-2026-10-04

- 01-shop-passes-readability.png — category labels, pass title/benefit and Owned action.
- 02-shop-speed-cards-readability.png — Speed product titles, cramped benefits, price buttons.
- 03-shop-cash-cards-readability.png — cash product titles/benefits and card/button separation.
- 04-shop-ticket-cards-readability.png — ticket cards, captions, prices and secondary header action.
- 05-bag-categories-and-tiles-readability.png — muddy sidebar type, gray-green tiles, rarity/size text and footer.

Read CLAUDE_PROMPT.md for the visual-only implementation brief. Current source inspection finds MenuKit.text still adds an ink stroke to dark labels and Shop benefit text uses 13px decorative type. These can contribute to crowding; this pack is not an implemented fix or runtime test. Do not remove outline effects from all rarity/HUD text indiscriminately.

Readability target reference: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html

