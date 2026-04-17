# AGENTS.md

This file is the short entry point for Codex and other agents working in BeanTracker.

## Source Of Truth

- `docs/` is the canonical knowledge base for this repository.
- `wiki/` is a summary/export layer for humans. Do not treat it as the source of truth.
- When behavior, architecture, or commands change, update the relevant file in `docs/`.

## Read Order

1. `docs/index.md`
2. `docs/architecture.md`
3. `docs/PRD-v2.md`
4. `docs/Tech-Spec-v2.md`
5. `docs/quality-score.md`
6. `docs/references/language-policy.md`
7. `docs/references/commands.md`
8. `docs/exec-plans/active/`

## Standard Commands

- `scripts/check-harness`: verify agent-facing docs and scripts are present.
- `scripts/bootstrap`: install Tuist dependencies and regenerate projects.
- `scripts/generate`: regenerate projects after graph changes.
- `scripts/test-domain`: run `CoffeeDomainTests`.
- `scripts/build-app`: build the main app target.

Set `BEANTRACKER_SIMULATOR` if the default simulator name does not exist.
Set `BEANTRACKER_DERIVED_DATA` to override the derived data location.

## Repository Rules

- Keep dependency flow `Feature -> Domain -> Core`.
- Feature code must not access `ModelContext`, SwiftData, or CloudKit directly.
- All persistence and queries go through `DatabaseClient`.
- Keep pure calculations, aggregation rules, and fixtures in `CoffeeDomain`.
- Keep previews and tests mock-backed; do not require live persistence in previews.
- Follow `docs/references/language-policy.md`: agent-facing docs default to English, product-intent docs may stay Korean.
- For multi-step work, create or update an exec plan in `docs/exec-plans/active/`.
- Before finishing a task, run the smallest relevant validation command and report anything you could not run.

## Current Reality

- `DatabaseClient.liveValue` is still backed by the in-memory database.
- Only `CoffeeDomain` has automated tests today.
- The repository has no checked-in CI workflow yet.
- Most feature screens still need dedicated previews and reducer tests.
- Localization and platform coverage are incomplete relative to the product spec.

## Key Paths

- `docs/index.md`
- `docs/architecture.md`
- `docs/quality-score.md`
- `docs/references/language-policy.md`
- `docs/references/commands.md`
- `docs/exec-plans/active/codex-harness-followups.md`
