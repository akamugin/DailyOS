# Repository Map

## Top-Level Layout
```text
DailyOS/
├── DailyOS/                    # App source
│   ├── ContentView.swift       # SwiftUI screen and presentation state
│   ├── DailyOSApp.swift        # App bootstrap and dependency wiring
│   ├── Domain/                 # Core models and formatting/storage constants
│   ├── Repositories/           # Persistence abstraction + SwiftData impl
│   ├── Services/               # Migration, reminders, tracing
│   └── ViewModels/             # Screen orchestration and intents
├── DailyOS.xcodeproj/          # Xcode project
├── scripts/                    # Trace/profile helper scripts
└── docs/                       # All project documentation
```

## Core Runtime Flow
```text
DailyOSApp
  -> constructs repository + services + view model
  -> injects ScheduleViewModel into ContentView

ContentView (UI intents)
  -> ScheduleViewModel (business orchestration)
  -> ScheduleBlockRepository (SwiftData persistence)
  -> ReminderScheduling + MigrationService (side effects)
```

## User Action Routing
| User action | UI entrypoint | View model intent | Persistence/side effects |
| --- | --- | --- | --- |
| Add block | `AddBlockView` save callback | `add(_:)` | `upsert` + `saveChanges` + reminder sync |
| Edit block | `EditBlockView` save callback | `update(_:)` | day fetch + rewrite + save + reminder sync |
| Toggle done | row check button | `toggleDone(_:)` | single upsert + save + reminder sync |
| Delete block | swipe delete / confirm dialog | `delete(_:)` | delete + save + day normalize + reminder sync |
| Reorder blocks | list move in edit mode | `move(from:to:)` | recalculate + batch upsert + save + reminder sync |
| Navigate day | drag gesture / Today button | `goToNextDay` / `goToPreviousDay` / `jumpToToday` | day-scoped fetch |

## Where to Put New Code
- UI styling/layout-only change: `ContentView.swift`
- Schedule flow behavior or intent orchestration: `ViewModels/ScheduleViewModel.swift`
- SwiftData query/write behavior: `Repositories/ScheduleBlockRepository.swift`
- Notification, migration, tracing, or external side effects: `Services/`
- Core model/value semantics: `Domain/`
