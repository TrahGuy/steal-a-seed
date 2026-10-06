# Claude follow-up — Shop / Index assets and studded sidepanel

Update the existing left HUD navigation sidepanel (Index, Shop and Settings) using these owner-uploaded images:

- Shop: `rbxassetid://82894505272456`
- Index: `rbxassetid://91015160762668`

Use them as the actual Shop and Index buttons, not as extra decorations. Their icons and labels are already baked in, so remove duplicate icon/text overlays. Keep surrounding ImageButton backgrounds transparent and preserve the PNG alpha. Preserve existing clicks, Index badges, hover/pressed feedback, collapse behavior and permissions.

Keep the artwork undistorted: Shop is wide (2094 × 751), Index is square (1254 × 1254). Use aspect-correct Fit/constraints and sensible visual sizes; adapt the compact panel layout as needed instead of forcing both images into identical square tiles. Keep comfortable, non-overlapping touch targets.

Give the sidepanel itself a studded texture background using the project's existing studded texture assets/helper. Use a light neutral or soft-mint tint, subtle studs, rounded corners and a clean dark border so the green Shop and blue Index remain distinct. Keep Settings readable and consistent with the panel. Do not confuse these button IDs with the separate background texture IDs.

Keep the recent mobile HUD changes intact: PLOT without an emoji, tighter top buttons, transparent x2 beside cash, and smaller Other Plants / Walk Mode switches. Avoid the Roblox toolbar, notch, movement controls and hotbar. This is a visual change only; do not change gameplay or purchase logic.

Local references: `D:\KAPE\Steal an Artifact\art\ui-buttons\shop-index-2026-10-05\`.

Check actual image loading, readability and layout on desktop and small-phone views; provide before/after captures. Follow the project's test-store safeguards for any Play testing. Report inaccessible assets rather than substituting unrelated images. Do not commit, push or publish.

## Asset provenance

The owner supplied the upload IDs in screenshot `C:\Users\Maykel\AppData\Local\Temp\codex-clipboard-a5b798b0-6a21-446c-b51a-67e7cf718e48.png`. IDs were transcribed from that screenshot; Roblox availability and permissions have not been independently tested. This follow-up is a draft for the owner to give Claude; it has not been sent and no runtime files were changed by Codex.
