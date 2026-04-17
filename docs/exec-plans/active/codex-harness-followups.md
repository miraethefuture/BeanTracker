# Codex Harness Follow-ups

Status: active
Owner: repository
Updated: 2026-04-18

## Goal

Move BeanTracker from "documented for agents" to "self-validating for agents."

## Success Criteria

- Each feature has at least one reducer test for a core user flow.
- Each feature has representative previews for empty, normal, and edge states.
- `DatabaseClient.liveValue` uses real persistence instead of the in-memory adapter.
- The repository has a repeatable UI smoke workflow for the main product loop.
- CI runs at least `scripts/check-harness` and `scripts/test-domain`.

## Priority Decision

The next task should be feature reducer tests, not SwiftData.

Reasoning:

- It increases Codex's validation surface immediately with the current architecture.
- It locks down expected feature behavior before persistence work changes the runtime path.
- It is cheaper and lower-risk than introducing live storage first.
- It creates a clearer base for previews, smoke tests, and later CI enforcement.

## Ordered Milestones

### Milestone 1: Feature Reducer Tests

Goal:

- Add `TestStore` coverage for the highest-value happy paths and edge cases in each feature.

Why this comes first:

- The repository already has domain tests, but feature behavior is still mostly unchecked.
- Reducer tests are the fastest way to make Codex self-verify non-trivial UI state transitions.
- These tests can run against the current mock/in-memory setup without waiting on SwiftData.

Definition of done:

- `OnboardingFeature`: save price happy path and invalid-input guard
- `SettingsFeature`: update price happy path and invalid-input guard
- `InventoryFeature`: save bean, delete bean, set exhausted
- `BrewingLogFeature`: defaults load, save happy path, invalid-input guard
- `DashboardFeature`: initial load and month navigation

### Milestone 2: Feature Previews

Goal:

- Add representative previews for each feature using fixture-backed mock dependencies.

Why second:

- Previews improve agent and human legibility, but they work best once feature states are already pinned down by tests.
- The preview matrix should reflect behavior already captured in reducer tests, not invent it ad hoc.

Definition of done:

- Each feature has at least empty, normal, and one edge-state preview where relevant.

### Milestone 3: SwiftData Live Adapter

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

Start with Milestone 1 and open a focused change for feature reducer tests.

Recommended first slice:

1. Add test targets for the feature modules that currently have none.
2. Implement `OnboardingFeature` and `SettingsFeature` tests first because they are small and define the repository's test pattern.
3. Extend the same pattern to `InventoryFeature`, `BrewingLogFeature`, and `DashboardFeature`.

This gives the repository a repeatable template before touching the larger persistence problem.

## Work Items

1. Add `TestStore` coverage for onboarding, inventory, brewing, dashboard, and settings reducers.
2. Add feature previews backed by mock dependencies and fixture states.
3. Implement a SwiftData-backed live `DatabaseClient`.
4. Write down CloudKit sync expectations once the live adapter exists.
5. Add a seeded smoke path covering onboarding -> bean creation -> brew log -> dashboard refresh.
6. Promote the smoke path and domain tests into CI.
7. Centralize user-facing strings and locale-sensitive formatting rules.

## Notes

- Do not block on CloudKit before establishing a local live persistence path.
- Do not start SwiftData integration until the first wave of feature reducer tests exists.
- Keep the docs current as each work item lands.
- Prefer small pull requests that close one validation gap at a time.
