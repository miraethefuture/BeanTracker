# Codex Harness Follow-ups

Status: active
Owner: repository
Updated: 2026-05-22

## Goal

Move BeanTracker from "documented for agents" to "self-validating for agents."

## Product Pivot Note

BeanTracker's product docs now center on active-bean cup counts and exhausted-bean total cups, not savings.

This means:

- dashboard validation should focus on current bean cup counts, monthly cup counts, and empty states
- onboarding no longer depends on standard cafe price flows
- reducer tests and previews should be updated to match the cup-count product direction
- local SwiftData persistence now exists, while CloudKit sync remains future work

## Success Criteria

- Each feature has at least one reducer test for a core user flow.
- Each feature has representative previews for empty, normal, and edge states.
- `DatabaseClient.liveValue` uses real local persistence instead of the in-memory adapter.
- The repository has a repeatable UI smoke workflow for the main product loop.
- CI runs at least `scripts/check-harness` and `scripts/test-domain`.

## Priority Decision

The next task should be feature reducer tests and focused persistence adapter tests.

Reasoning:

- Feature behavior is still mostly unchecked after the runtime path moved to SwiftData.
- Persistence adapter tests should pin the local save/fetch/delete loop before CloudKit work.
- Together they create a clearer base for previews, smoke tests, and later CI enforcement.

## Ordered Milestones

### Milestone 1: Feature Reducer Tests

Goal:

- Add `TestStore` coverage for the highest-value happy paths and edge cases in each feature.

Why this comes first:

- The repository already has domain tests, but feature behavior is still mostly unchecked.
- Reducer tests are the fastest way to make Codex self-verify non-trivial UI state transitions.
- Feature tests can still run against mock/in-memory dependencies while persistence adapter tests exercise SwiftData separately.

Definition of done:

- `OnboardingFeature`: intro flow and first-bean handoff
- `InventoryFeature`: save bean, delete bean, set exhausted
- `BrewingLogFeature`: defaults load, save happy path, invalid-input guard
- `DashboardFeature`: current bean load, no-brew empty state, and month navigation

### Milestone 2: Feature Previews

Goal:

- Add representative previews for each feature using fixture-backed mock dependencies.

Why second:

- Previews improve agent and human legibility, but they work best once feature states are already pinned down by tests.
- The preview matrix should reflect behavior already captured in reducer tests, not invent it ad hoc.

Definition of done:

- Each feature has at least empty, normal, and one edge-state preview where relevant.

### Milestone 3: SwiftData Live Adapter

Status: Completed

Goal:

- Replace `DatabaseClient.liveValue` with a real SwiftData-backed adapter while keeping feature code isolated from storage frameworks.

Why third:

- Runtime fidelity matters, but implementing it before feature validation would widen the blast radius.
- By this point the repository should already have stronger behavioral checks to catch regressions.

Definition of done:

- `DatabaseClient.liveValue` is no longer in-memory.
- Existing tests still pass.
- The architecture docs and tech spec are updated to reflect the live adapter shape.

### Milestone 4: Smoke Flow

Goal:

- Add a seeded end-to-end validation path for onboarding -> bean creation -> brew log -> dashboard refresh.

Why fourth:

- Smoke flows are most useful after feature logic and persistence have both stabilized enough to exercise the real app loop.

### Milestone 5: CI Promotion

Goal:

- Run harness checks and the most important validation commands in CI.

Why fifth:

- CI should codify a validation loop that already works locally.

Definition of done:

- CI runs at least `scripts/check-harness` and the smallest reliable automated test surface available at that time.

## Immediate Next Task

Open a focused change for reducer tests and persistence adapter tests.

Recommended first slice:

1. Add `TestStore` coverage for onboarding, inventory, brewing, and dashboard.
2. Add a small SwiftData-backed `DatabaseClient` test using an in-memory SwiftData configuration.
3. Extend the same validation pattern to the smoke flow once the reducer surface is stable.

This keeps the validation plan aligned with the product docs and the new live persistence path.

## Work Items

1. Align dashboard, onboarding, and domain docs with the cup-count product direction.
2. Add `TestStore` coverage for onboarding, inventory, brewing, and dashboard reducers.
3. Add feature previews backed by mock dependencies and fixture states.
4. Implement a SwiftData-backed live `DatabaseClient`. Completed 2026-05-22.
5. Add focused persistence adapter tests and write down CloudKit sync expectations.
6. Add a seeded smoke path covering onboarding -> bean creation -> brew log -> dashboard refresh.
7. Promote the smoke path and domain tests into CI.
8. Centralize user-facing strings and locale-sensitive formatting rules.

## Notes

- Do not block on CloudKit before establishing a local live persistence path.
- Local SwiftData integration now exists; validate it before CloudKit work.
- Keep the docs current as each work item lands.
- Prefer small pull requests that close one validation gap at a time.
