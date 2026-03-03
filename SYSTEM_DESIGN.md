# DailyOS System Design (Incremental Refactor)

## Goals
1. Keep CloudKit-backed SwiftData with local fallback.
2. Move persistence/migration/reminder side effects out of `ContentView`.
3. Make each core flow traceable via signposts.
4. Preserve UI behavior while improving correctness and maintainability.

## Layered Architecture

### UI Layer
- `ContentView` and related SwiftUI subviews.
- Owns presentation state only (sheet/dialog/edit UI state).
- Delegates all business actions to `ScheduleViewModel`.

### Orchestration Layer
- `ScheduleViewModel` is the single state orchestrator for schedule flows:
  - Day loading and navigation.
  - Add/edit/delete/toggle/reorder operations.
  - Triggering reminder sync.
  - Error reporting to UI.

### Data Layer
- `ScheduleBlockRepository` protocol defines persistence contract.
- `SwiftDataScheduleBlockRepository` implements day-scoped and global queries using `FetchDescriptor`.
- Explicit `saveChanges()` called after mutating operations.

### Services
- `MigrationService`: one-time legacy migration with idempotent completion flag.
- `ReminderScheduling` protocol + `UserNotificationReminderScheduler` actor:
  - Authorization-gated scheduling.
  - Diff-based reminder sync (`added/updated/removed`) instead of blanket recreate.

### Diagnostics
- `PerformanceTracer` wraps `OSLog` + `os_signpost`.
- Standard events:
  - `launch`, `migration`, `query_day`, `add_block`, `edit_block`, `delete_block`, `toggle_done`, `reorder`, `day_swipe`, `reminder_sync`, `cloudkit_init`.

## Core Flow
1. `DailyOSApp` initializes `ModelContainer` (`cloudkit_init` signpost).
2. App constructs repository + services + view model and injects into `ContentView`.
3. `ScheduleViewModel.onAppear()` runs bootstrap:
   - migration,
   - selected-day load,
   - reminder authorization and sync.
4. UI actions call view model intents.
5. View model persists explicitly, updates published state, and resyncs reminders.

## Correctness Guarantees Added
1. Reminder scheduling occurs only when authorization is granted/provisional.
2. Migration runs once and persists before reminder sync.
3. Day queries are range-based (`dayStart <= day < nextDay`) instead of strict date equality.
4. Reorder path is now explicitly exposed through `EditButton`.

## Next Steps
1. Add automated XCTest UI/perf target for fully non-interactive flow profiling.
2. Add seeded dataset perf scenarios (small/medium/large schedules).
3. Add threshold-based performance CI checks from exported trace metrics.
