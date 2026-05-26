# BeanTracker Architecture

## Core Shape

BeanTracker is organized around a small app shell with feature modules, a pure domain module, and a storage boundary module:

- `Projects/App`: app entry point, root reducer composition, navigation, and cross-feature refresh logic.
- `Projects/Features/*`: user-facing feature reducers and views.
- `Projects/Domain/CoffeeDomain`: pure models, calculations, snapshots, and fixtures.
- `Projects/Core/DatabaseClient`: persistence boundary and dependency injection surface.

## Dependency Rules

- The intended dependency direction is `Feature -> Domain -> Core`.
- Features should depend on `DatabaseClient`, not on persistence frameworks directly.
- `CoffeeDomain` owns calculation logic such as cup counts, usage, purchase cost, and default selection rules.
- The app layer is responsible for wiring feature-to-feature refresh triggers.
- Widgets should reuse shared domain/core code instead of re-implementing product logic.

## Agent Working Invariants

- If a change affects behavior, update the matching product or tech doc in `docs/`.
- If a change affects project generation, use `scripts/generate`.
- If a change affects pure business logic, add or update domain tests and run `scripts/test-domain`.
- If a change affects app wiring or build settings, run `scripts/build-app`.
- For multi-step work, keep a repo-local execution plan under `docs/exec-plans/active/`.

## Current Implementation Reality

- `DatabaseClient.liveValue` uses a local SwiftData-backed store.
- Runtime data now starts empty and persists locally across app launches.
- `InMemoryDatabase` remains available for previews and tests.
- The root app reducer coordinates onboarding, dashboard refreshes, brewing refreshes, and inventory refreshes.
- Feature modules mostly use async client calls plus direct view state bindings.
- The widget currently provides a quick deep link and a single preview.

## Known Gaps

- No CloudKit sync implementation yet.
- No feature-level reducer tests.
- Almost no feature previews despite the tech spec calling for them.
- No checked-in UI smoke harness for onboarding -> inventory -> brew -> dashboard.
- No CI job that enforces docs, scripts, or test execution.
- The product docs target iPhone, iPad, and macOS, but the current project settings still focus on iOS destinations.

## Preferred Next Moves

1. Add reducer tests for each feature's primary happy path and edge state.
2. Add representative previews for each feature using mock dependencies.
3. Add focused persistence adapter tests for the SwiftData-backed `DatabaseClient`.
4. Add a repo-local UI smoke workflow and then promote it into CI.
