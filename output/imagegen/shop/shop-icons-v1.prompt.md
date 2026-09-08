# Shop tile icons — Gemini prompt

Fifteen icons for the Steal a Seed shop panel. They sit inside coloured tiles
that the UI already draws, so **background, border, label and price are NOT part
of the artwork** — only the object.

Reference: `shop ui 1.png`, `shop ui 2.png`, `shop ui 3.png` in the repo root.

## Why the current tiles fall short

The layout already matches the reference — landscape tiles, coloured rims, a
two-tone label, a green price pill. What does not match is the ICON: the
reference's are rendered, glossy objects with a thick white outline, and ours are
flat rectangles drawn from UI frames because no image tool was available.

## The prompt

> Create a set of game UI icons in a glossy 3D cartoon style, in the visual
> language of a mobile simulator shop. Each icon is a single object rendered in
> soft three-quarter view with a thick, even white-to-pale outline around the
> whole silhouette, smooth rounded forms, a bright specular highlight on the
> upper-left of each surface, and a soft ambient-occlusion shadow where forms
> meet. Saturated, high-contrast, cheerful. No text, no numbers, no borders, no
> frames, no background scenery.
>
> Every icon on a fully transparent background, centred, occupying about 80% of
> a square canvas with even padding on all sides. Consistent light source and
> consistent outline thickness across the entire set so they read as one family.
>
> Render these fifteen icons:
>
> **Speed set — light blue and white running shoes, escalating by quantity:**
> 1. one running shoe, side view
> 2. a pair of running shoes
> 3. three running shoes stacked
> 4. a loose pile of five or six running shoes
> 5. a drawstring sack overflowing with running shoes
> 6. an open treasure chest full of running shoes
>
> **Cash set — green banknotes, escalating by quantity:**
> 7. a small fan of three banknotes
> 8. a folded stack of banknotes
> 9. a thick banded bundle of banknotes
> 10. a drawstring money bag overflowing with banknotes
> 11. an open treasure chest full of banknotes
>
> **Pod set — smooth egg-shaped seed pods with a subtle seam and a leafy sprig
> at the top, escalating by grandeur:**
> 12. one plain pod, pale cream with a small green sprig
> 13. one ornate pod with gold banding and a fuller sprig
> 14. one large radiant pod with gold banding and a glowing aura, sprig in bloom
>
> **Plants:**
> 15. a single young green seedling with two leaves in dark soil
>
> Deliver each as a separate PNG with an alpha channel, 512 x 512.

## Constraints that matter for the game, not the picture

* **Transparent background is essential.** The tile behind each icon is a
  coloured gradient the UI draws — cyan for speed, green for cash, gold for pods,
  violet for plants. An icon with its own background would sit as a square patch
  on top of that.
* **No text of any kind.** The amount, the noun and the Robux price are drawn by
  the UI over the tile. An icon with a number baked in cannot be reused when a
  price changes, and cannot be re-labelled.
* **Light objects.** They sit on mid-tone coloured tiles, so pale shoes and pale
  notes with white outlines read; dark objects disappear.
* **One family.** These are seen three across in a grid. Inconsistent outline
  weight or light direction between two of them is obvious at that size.
* **They will be shown small.** Roughly 110 x 55 pixels of tile at three columns.
  Fine detail is lost — silhouette and colour carry the read.

## What happens to the files

Drop them in `art/shop/` named:

    speed1.png speed2.png speed3.png speed4.png speed5.png speed6.png
    cash1.png cash2.png cash3.png cash4.png cash5.png
    pod1.png pod2.png pod3.png
    plants.png

Those names are the `key` fields in `GameConfig.Store.Items`, so the mapping is
already implied. They then get resized, uploaded through the verified pipeline,
and their returned asset ids recorded in the manifest — the same route the plant
card art and the biome backgrounds took.

`storeArt` in `ShopUI.client.luau` — the function that draws the current
rectangles — is deleted at that point and replaced by an ImageLabel per tile.
