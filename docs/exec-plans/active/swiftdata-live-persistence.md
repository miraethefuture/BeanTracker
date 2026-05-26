# SwiftData Live Persistence

## Goal

Replace the sample-seeded runtime database with a real local SwiftData store while keeping preview and test fixtures available.

## Scope

- Add SwiftData-backed storage models inside `DatabaseClient`.
- Keep feature modules isolated from SwiftData and `ModelContext`.
- Start the live app with no sample beans, no sample brew logs, and incomplete onboarding.
- Avoid showing fixture-backed dashboard data during initial loading.
- Preserve `CoffeeFixtures`, `previewValue`, `testValue`, and `InMemoryDatabase` for previews and tests.
- Update docs that currently describe runtime persistence as in-memory only.

## Slices

### Slice 1: Local SwiftData Adapter

Status: Completed

- Add persistent `Bean`, `BrewLog`, and app-state records.
- Map persisted records to `CoffeeDomain` value types.
- Implement dashboard, brewing defaults, inventory, onboarding, save, delete, and exhausted-state operations through SwiftData.

### Slice 2: Live Dependency Switch

Status: Completed

- Point `DatabaseClient.liveValue` at the SwiftData adapter.
- Leave preview and test dependencies fixture-backed.

### Slice 3: Documentation

Status: Completed

- Update architecture and quality docs to reflect local live persistence.
- Clarify that CloudKit sync is still pending.

### Slice 4: Validation

Status: Completed

- Run project generation if needed.
- Run the smallest relevant app build validation.
- Report any commands that could not run.

Validation completed:

- `scripts/generate`
- `scripts/build-app`
- `scripts/check-harness`
- `git diff --check`
- `xcodebuild -workspace BeanTracker.xcworkspace -scheme BeanTrackerApp -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build`

Note:

- The first workspace build failed because the new source file was not yet included in the generated project. Regenerating the project fixed the target graph, and the follow-up workspace build succeeded.
