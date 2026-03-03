# Profiling Guide

This guide defines repeatable profiling for DailyOS using the scripts in `scripts/`.

## Prerequisites
- Xcode with Instruments installed
- `xcrun xctrace` available
- iOS Simulator booted for the chosen device

## 1. Build the App
```bash
xcodebuild \
  -project DailyOS.xcodeproj \
  -scheme DailyOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath /tmp/DailyOSDerived \
  build
```

Resolve the built app path:

```bash
APP_PATH=$(find /tmp/DailyOSDerived/Build/Products -name DailyOS.app | head -n 1)
echo "$APP_PATH"
```

## 2. Capture Standard Trace Set
```bash
OUT_DIR=".context/perf/$(date +%Y%m%d-%H%M%S)"
scripts/profile_traces.sh "$OUT_DIR" "$APP_PATH"
```

Default templates captured:
- App Launch
- Time Profiler
- SwiftUI
- Animation Hitches
- Data Persistence

## 3. Capture Per-Flow Time Profiles
```bash
OUT_DIR=".context/perf/flows-$(date +%Y%m%d-%H%M%S)"
scripts/profile_flows.sh "$OUT_DIR" "$APP_PATH"
```

The script will pause for manual interaction between flows:
- launch-steady-state
- add-block
- edit-block
- toggle-done
- delete-block
- swipe-day

## 4. Export dyld Summary From Launch Trace
```bash
scripts/export_dyld_summary.sh "$OUT_DIR/app-launch.trace" > "$OUT_DIR/dyld-summary.txt"
```

## 5. Interpretation Checklist
1. Confirm signpost spans appear for:
- `launch`
- `migration`
- `query_day`
- `add_block`
- `edit_block`
- `delete_block`
- `toggle_done`
- `reorder`
- `day_swipe`
- `reminder_sync`
- `cloudkit_init`

2. Compare launch and flow traces to [Performance Baseline](perf-baseline.md).
3. Check Data Persistence traces for fetch/save activity under non-empty datasets.
4. Record findings and trace artifact paths in the PR description.
