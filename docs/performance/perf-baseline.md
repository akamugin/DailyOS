# DailyOS Performance Baseline

## Scope
Baseline captured on March 2, 2026 with simulator `iPhone 17 Pro Max (iOS 26.2)` and scheme `DailyOS`.

## Trace Artifacts
- `/tmp/dailyos-app-launch-1.trace`
- `/tmp/dailyos-time-1.trace`
- `/tmp/dailyos-data-persistence-1.trace`
- `/tmp/dailyos-sample-startup.txt`

## Launch (App Launch / dyld)
Nested launch contribution (excluding top-level 10s recording window):
- `Launch Executable`: `180.275 ms`
- `Apply Fixups`: `43.837 ms`
- `dlopen`: `18.354 ms`
- `Static Initializer`: `7.903 ms`
- `Objc Image Init`: `1.592 ms`

Largest individual `dlopen` entries in captured run:
- `EmojiFoundation`: `4.50 ms`
- `libCGInterfaces.dylib`: `4.11 ms`
- `libobjc-trampolines.dylib`: `3.69 ms`
- `libcmark-gfm.dylib`: `3.68 ms`

## Runtime Sample (Time Profiler Supplement)
`sample` output at `/tmp/dailyos-sample-startup.txt` shows the process mostly idle in runloop waits during steady state.

## Data Persistence
`Data Persistence` trace produced zero Core Data/SwiftData fetch/save rows for the sampled interval with an empty dataset.

## Script References
Use these scripts for repeatable capture and summary:
- `scripts/profile_traces.sh`
- `scripts/profile_flows.sh`
- `scripts/export_dyld_summary.sh`

## Next Baseline Pass
1. Capture using seeded small/medium/large datasets.
2. Compare signpost span timing (`query_day`, `add_block`, `edit_block`, `delete_block`, `toggle_done`, `reorder`, `day_swipe`, `reminder_sync`).
3. Export and commit result summaries under `.context/perf/<timestamp>/` during performance-focused PRs.

## Related Docs
- [Profiling Guide](profiling-guide.md)
- [System Design](../architecture/system-design.md)
