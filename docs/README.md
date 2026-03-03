# DailyOS Documentation

This folder is the canonical home for project documentation.

## Reading Paths

### First 30 minutes (new contributors)
1. [Quickstart](getting-started/quickstart.md)
2. [Repository Map](getting-started/repo-map.md)
3. [System Design](architecture/system-design.md)
4. [Developer Workflow](contributing/dev-workflow.md)

### Performance and tracing
1. [Profiling Guide](performance/profiling-guide.md)
2. [Performance Baseline](performance/perf-baseline.md)

## Feature Backlog (GitHub Issues)

### MVP
1. [#4 - Add automated unit/UI/performance guardrails with seeded datasets](https://github.com/akamugin/DailyOS/issues/4)
2. [#5 - Upgrade reminders with lead-time options, snooze, and missed-block recovery](https://github.com/akamugin/DailyOS/issues/5)
3. [#6 - Add overlap conflict detection and smart reschedule options](https://github.com/akamugin/DailyOS/issues/6)
4. [#7 - Add Quick Add natural input parser for one-step block creation](https://github.com/akamugin/DailyOS/issues/7)
5. [#8 - Add undo/redo for add, edit, delete, toggle, and reorder actions](https://github.com/akamugin/DailyOS/issues/8)
6. [#9 - Add sync status and conflict transparency in the UI](https://github.com/akamugin/DailyOS/issues/9)

### Phase 2
1. [#10 - Add recurring routines with per-day exceptions](https://github.com/akamugin/DailyOS/issues/10)
2. [#11 - Add day templates (save/apply) with merge or replace modes](https://github.com/akamugin/DailyOS/issues/11)
3. [#12 - Add weekly strip view with day summary metrics](https://github.com/akamugin/DailyOS/issues/12)
4. [#13 - Add weekly review insights (completion rate, streaks, focus breakdown)](https://github.com/akamugin/DailyOS/issues/13)

## Documentation Structure
- `getting-started/`: onboarding and orientation
- `architecture/`: system and layering decisions
- `performance/`: profiling workflows and baseline data
- `contributing/`: day-to-day engineering workflow

## Maintenance Rules
1. Keep root `README.md` concise and link outward to docs pages.
2. Add deep technical content under `docs/` instead of repo root.
3. Prefer updating existing pages over creating duplicate docs for the same topic.
4. When changing app architecture or profiling flows, update docs in the same PR.
