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
