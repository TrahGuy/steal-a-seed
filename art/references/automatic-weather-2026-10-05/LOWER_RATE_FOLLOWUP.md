# Follow-up: rarer automatic Rain and Thunderstorm

Work in `D:\KAPE\Steal an Artifact`. Lower automatic weather frequency using the existing scheduler; do not rebuild it. This follow-up supersedes the older 15%-per-five-minutes / 30-minute-guarantee automatic-weather brief AND the earlier 80/20 mode split. The owner requested lower chances and a Claude prompt after Codex proposed 5% and recommended extending the guarantee to 60 minutes, then explicitly revised the mode split to 90% Rain / 10% Thunderstorm. The source was still at Chance0.15, ModeWeights0.8/0.2 and Guarantee1800 on the latest read; Codex has not changed game code.

Set GameConfig.Weather.Auto to these values:

- Enabled remains true.
- CheckSeconds remains 300 (one check every five minutes while populated and fully clear).
- Chance becomes 0.05 (down from 0.15).
- ModeWeights becomes rain 0.9 / thunder 0.1.
- DurationSeconds stays 180 (three minutes).
- GuaranteeSeconds becomes 3600 (up from 1800).

Normal eligible checkpoints therefore have 4.5% Rain, 0.5% Thunderstorm and 95% no event. This is a TWO-STAGE draw, not a 5% chance separately for each weather mode. At the forced 60-minute checkpoint, use the same 90/10 mode draw; the 95% no-event result no longer applies there. The guarantee is populated, fully-clear elapsed time, not an unconditional wall-clock hourly storm on an empty or busy server.

Keep existing safeguards: no event at server startup; first attempt after five populated clear minutes; one event at a time; no attempts during opening/running/closing; no catch-up bursts after hitches; manual weather keeps its controls/permissions and resets the automatic window; re-arm only after complete teardown; empty servers reset the window. Preserve the existing start path for manual/natural Rain and Thunderstorm, Secret egg toast, three-egg Rain and single Pod3 Thunderstorm batch, 50/50 old/new family split, 40/25/25/10 new species, total 10% Rain Colossal odds, hatch times, earnings and all other weather/guardian behavior.

Update AutoWeatherSpec and stale comments/Ready-line descriptions to the new values. Use deterministic fake-time/RNG checks for 0.05 trigger boundaries, 90/10 mode selection (Rain below 0.9, Thunderstorm at/from 0.9 in the existing cumulative roller), no forced weather at 30 minutes when all chance draws fail, and exactly one forced start at 60 minutes with failed prior draws. Verify the forced start also uses 90/10 rather than the obsolete 80/20. Update the longer-window checkpoint/draw counts and any expected-wait assertions rather than only changing the top config assertion. Recheck startup, empty-server/manual resets, full teardown and no overlap/catch-up. No need to wait a real hour or run extra Play sessions for a data-only adjustment. Preserve unrelated shared-checkout edits; follow AGENTS.md/canonical coding skills, update project/root handoffs, and report actual tests. Do not commit, push, publish, restart servers or send announcements automatically.
