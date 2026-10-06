# Walk Mode and cycle-clock reference pack

Owner requests a compact sliding Walk Mode switch, a cycle icon beside the timer, white normal timer text and red only before night. Exact screenshot crops are saved locally; original pixels/background and foreign labels remain in reference files.

- source-walk-toggle.png: original supplied screenshot, including unrelated Speed/Friend Boost/taskbar context.
- reference-walk-toggle.png: 175x67 crop of label and switch only.
- source-night-timer.png: original supplied timer screenshot.
- reference-night-timer.png: 159x68 crop of timer/icon style; the red in 14s is NOT a live asset or a default color instruction.
- reference-moon-cloud-icon.png: 66x55 source-icon crop with green background, reference only.
- cycle-moon-cloud-v1.png: clean transparent 1254x1254 generated night/countdown icon.
- cycle-sun-cloud-v1.png: clean transparent 1254x1254 generated dawn/countdown icon.
- generation.prompts.md and icons-manifest.json: exact icon generation prompts, provenance, dimensions, alpha checks and hashes.
- CLAUDE_PROMPT.md: implementation follow-up for the existing global UI pass.

All seven PNGs are now together in this one folder. Cycle icon copies were verified byte-for-byte against ../../icons/hud-cycle-2026-10-04/; those originals are preserved. The Walk Mode track/thumb/text should be built as live native UI, not baked into image states. Keep our name WALK MODE and existing server-confirmed preference. Current config has a 45s warning window; use that existing window for red DAY countdown, and return to white at NIGHT/dawn. The icons still need valid Roblox upload IDs; no upload or runtime loading has been verified.

No game code, Studio action, save access, Roblox uploads or runtime tests were performed in this preparation task.

