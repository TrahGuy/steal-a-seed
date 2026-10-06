# Secret egg spawn toast follow-up

Implement a server-wide toast for actual Secret egg spawns and for the special Thunderstorm Pod3, whether the Thunderstorm was started manually or by the new automatic scheduler.

Requested text:
`A SECRET EGG SPAWNED ON {BIOME NAME}!`

Use the biome's actual display name, uppercase in the headline. The user wants the existing Secret text effect on the word SECRET: silver/white italic lettering, dark outline and moving sheen, with its existing reduced-motion treatment. Keep the rest of the sentence readable and the toast in the current stack just above the hotbar, using existing desktop/phone sizing and wrapping.

Read current AGENTS.md / KB/HANDOFF.md, then inspect GameConfig.Secret.Toast, Notice's existing secret kind, ActionToastUI's SecretSpawned handler and SecretWord renderer, NestService.spawnSecret / announceSecret / OpenEventNest, and WeatherService's manual and automatic start path. Reuse these systems rather than adding another ScreenGui, remote family, renderer or scheduler.

Existing facts to account for:
- A real Secret spawn already fires SecretSpawned with a biome id; use/update the existing path without double announcements.
- The current title is SECRET POD SPAWNED IN %s!, and the renderer only effects SECRET when it is the first word. Adapt measurement/placement to support the leading A space, preserving exact centering, wrapping and readable outlines. Do not simply change the title and silently lose the animation.
- Thunderstorm's existing rainpod3 is classified Divine and is not spawned through spawnSecret. For this requested notification include that specific Thunderstorm special egg as well, using the requested SECRET EGG wording/effect; leave its real rarity, hatch pool, rewards and model unchanged. Do not relabel ordinary Rain pods or every Divine item as Secret. GameConfig.Secret.Enabled is currently false: this toast change does not enable road Secret spawning or add extra eggs.

Server decides when a spawn succeeded. Emit once per actual new egg/event spawn identity to players in that server. Use a shared successful spawn/announcement route so admin and automatic thunderstorms behave identically; do not announce solely because START was clicked or the weather roll passed. Failed/refused starts, duplicate START, guardian recovery, confiscated egg return, dropped egg pickup and player respawn must not produce another spawn toast. Include stable identity for client deduplication; biome name alone must not suppress a later distinct spawn in the same biome. Do not replay the historical spawn toast for late joiners. Resolve weather-biome names from existing data without exposing internal IDs. Integrate with current stack/queue so this and the existing weather-opening notice do not overlap unreadably.

Keep current spawn probabilities, weather durations/automatic rates, pod batches, economy, permissions and saves. Verify focused cases: ordinary Secret success/refusal, manual Thunderstorm, automatic Thunderstorm, ordinary Rain without this toast, duplicate delivery and distinct same-biome spawns, failed builds/recovery without false notice, the new leading-A Secret sheen, long names/mobile wrapping and reduced motion. Use existing fake-clock/RNG seams for automatic timing. If Play is needed, use at most one guarded throwaway-store Play and clean it up per AGENTS.md. Update handoff and report remaining unverified cases. Do not commit, push or publish.

