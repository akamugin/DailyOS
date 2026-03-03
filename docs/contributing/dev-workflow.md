# Developer Workflow

## Branching
- Create feature branches from the active integration branch using the `codex/` prefix.
- Keep each PR focused on one concern (docs, reliability fix, refactor, performance, etc.).

## Change Placement Rules
1. Keep `ContentView` focused on presentation and user intents.
2. Put schedule business logic in `ScheduleViewModel`.
3. Put persistence in repository implementations.
4. Put notification/migration/tracing side effects in services.

## Local Verification Checklist
1. Build app successfully:

```bash
xcodebuild \
  -project DailyOS.xcodeproj \
  -scheme DailyOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

2. Run manual smoke flow in simulator:
- add block
- edit block
- toggle done
- reorder
- delete
- swipe day navigation

3. If behavior or performance-sensitive changes were made, capture traces with [Profiling Guide](../performance/profiling-guide.md).

## Documentation Expectations
- Update docs in the same PR when changing architecture, flow ownership, or profiling workflow.
- Keep root `README.md` as a high-level hub; place deep content under `docs/`.

## PR Description Template
1. Context
2. Problems solved
3. Solutions implemented
4. Technical file trace
5. Validation performed
6. Risks and follow-ups
