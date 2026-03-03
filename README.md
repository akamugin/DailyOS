# DailyOS

DailyOS is a SwiftUI + SwiftData iOS app for planning day-based schedule blocks with CloudKit-backed sync, local fallback, and notification reminders.

## Quick Start
1. Open `DailyOS.xcodeproj` in Xcode.
2. Select scheme `DailyOS` and an iOS Simulator.
3. Run the app.

Optional CLI build:

```bash
xcodebuild \
  -project DailyOS.xcodeproj \
  -scheme DailyOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

## Documentation
Start here for newcomer onboarding and architecture/performance details:

- [Documentation Index](docs/README.md)
- [Quickstart](docs/getting-started/quickstart.md)
- [Repository Map](docs/getting-started/repo-map.md)
- [System Design](docs/architecture/system-design.md)
- [Profiling Guide](docs/performance/profiling-guide.md)

## Current Project Notes
- Primary app target/scheme: `DailyOS`
- Profiling scripts live in `scripts/`
- No XCTest target is currently committed in this repository
