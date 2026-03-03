# Quickstart

## Prerequisites
- macOS with Xcode installed
- Xcode Command Line Tools (`xcodebuild`, `xcrun`)
- iOS Simulator runtime installed

## Build and Run in Xcode
1. Open `DailyOS.xcodeproj`.
2. Select scheme `DailyOS`.
3. Select an iPhone simulator.
4. Press Run.

## Build From Terminal
```bash
xcodebuild \
  -project DailyOS.xcodeproj \
  -scheme DailyOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

If that simulator name is unavailable, list available devices:

```bash
xcrun simctl list devices available | rg "iPhone"
```

## First-Run Sanity Checks
1. App launches to the schedule screen with current day selected.
2. Add one block, edit it, toggle done, then delete it.
3. If prompted, choose notification permission and verify no crash or stuck UI state.

## Next Reads
- [Repository Map](repo-map.md)
- [System Design](../architecture/system-design.md)
- [Profiling Guide](../performance/profiling-guide.md)
