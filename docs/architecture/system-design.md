# DailyOS System Design (Incremental Refactor)

## Goals
1. Keep CloudKit-backed SwiftData with local fallback.
2. Keep persistence, migration, and reminder side effects out of `ContentView`.
3. Keep each core flow traceable via signposts.
4. Preserve UI behavior while improving correctness and maintainability.

## Layered Architecture

### UI Layer
- Files: `ContentView.swift` and related SwiftUI views
- Responsibility: presentation state, visual composition, user intent wiring
- Constraint: no direct persistence or reminder scheduling logic

### Orchestration Layer
- Files: `ViewModels/ScheduleViewModel.swift`
- Responsibility:
  - day loading and navigation
  - add/edit/delete/toggle/reorder intents
  - sequencing repository writes and reminder sync
  - surfacing user-visible errors

### Data Layer
- Files: `Repositories/ScheduleBlockRepository.swift`
- Responsibility:
  - protocol contract (`ScheduleBlockRepository`)
  - SwiftData implementation (`SwiftDataScheduleBlockRepository`)
  - day-scoped and global fetches
  - explicit persistence boundaries via `saveChanges()`

### Services Layer
- Files: `Services/MigrationService.swift`, `Services/ReminderScheduling.swift`, `Services/PerformanceTracer.swift`
- Responsibility:
  - one-time legacy migration
  - notification authorization and reminder scheduling
  - signpost and structured diagnostics

## File Ownership and Change Routing
| Change type | Primary file(s) | Secondary file(s) |
| --- | --- | --- |
| UI-only layout/styling | `DailyOS/ContentView.swift` | related SwiftUI subviews |
| Intent sequencing or day flow behavior | `DailyOS/ViewModels/ScheduleViewModel.swift` | `DailyOS/ContentView.swift` |
| SwiftData query/write behavior | `DailyOS/Repositories/ScheduleBlockRepository.swift` | `DailyOS/Domain/ScheduleBlockEntity.swift` |
| Reminder behavior or authorization handling | `DailyOS/Services/ReminderScheduling.swift` | `DailyOS/ViewModels/ScheduleViewModel.swift` |
| Legacy data migration behavior | `DailyOS/Services/MigrationService.swift` | `DailyOS/Domain/StorageKeys.swift` |
| Profiling/tracing instrumentation | `DailyOS/Services/PerformanceTracer.swift` | call sites in app/view model/services |

## Core Runtime Flow
1. `DailyOSApp` initializes `ModelContainer` and records `cloudkit_init` tracing.
2. App wires repository + services + `ScheduleViewModel`.
3. `ContentView` forwards user intents to `ScheduleViewModel`.
4. View model mutates repository state, explicitly saves changes, and refreshes day state.
5. View model triggers reminder sync after mutations.

## Correctness Guarantees
1. Reminder scheduling is authorization-gated.
2. Migration persists before reminder sync during bootstrap.
3. Day fetches are range-based (`dayStart <= day < dayEnd`).
4. Reorder flow is explicit via list move/edit mode.

## Rules for New Code
1. Do not add persistence queries to `ContentView`.
2. Do not bypass repository writes from UI code.
3. Keep side effects isolated in services unless the effect is purely presentational.
4. Add tracer events for new performance-sensitive flows.

## Related Docs
- [Repository Map](../getting-started/repo-map.md)
- [Profiling Guide](../performance/profiling-guide.md)
- [Performance Baseline](../performance/perf-baseline.md)
