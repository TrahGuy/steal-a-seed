# Rail button artwork — Index and Shop (2026-09-24)

The owner's approved square button art. Each picture is a whole button — thick black
outline, rim, face, icon and the bold white word — so the game draws nothing round it
(`UIKit.railButton` with `art`). Masters copied verbatim from `D:\KAPE\output\ui-icons-v1\`.

- shop.svg / shop.png — approved master and its 512px render (blue cart, "Shop")
- index.svg / index.png — approved master and its 512px render (purple book, "Index")
- shop-base.svg — shop.svg with the static `#rim` stroke removed and that band masked to
  transparent (`#rimcut`); everything else byte-identical. The cart and the word still draw
  over the band, as they did over the old rim.
- shop-base.png — its 512px render
- shop-base-256.png, index-256.png — the uploaded copies (lanczos3 reductions)
- render.cjs — renders the three derived PNGs with sharp, the renderer that made the
  approved exports (it re-renders shop.svg and index.svg pixel-identical to them)

Uploaded ids (GameConfig.Rail): `ShopArt` = rbxassetid://100314547854118,
`IndexArt` = rbxassetid://107928181966123.

The Shop's rainbow is `UIKit.rainbowRim`: a rounded frame BEHIND the picture, showing only
through the cut band. Its geometry is `GameConfig.Rail.Rim`, in the SVG's 256 units: the
band is the 7-unit stroke round the panel rect (20, 43, 216 x 192, rx 14); the frame is that
band's outer edge grown by 2.5 (14, 37, 228 x 204, radius 20), still under the black
outline. Change the band in shop-base.svg and Rim must move with it.
