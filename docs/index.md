# BeanTracker Docs

`docs/` is the system of record for repository knowledge that agents can rely on.

## Read Order

1. `../AGENTS.md`
2. `architecture.md`
3. `PRD-v2.md`
4. `Tech-Spec-v2.md`
5. `quality-score.md`
6. `references/language-policy.md`
7. `references/commands.md`
8. `exec-plans/active/`

## What Lives Here

- `architecture.md`: current implementation boundaries, invariants, and known drift.
- `PRD-v2.md`: canonical product behavior and business rules.
- `Tech-Spec-v2.md`: target technical design and implementation intent.
- `quality-score.md`: scored view of current strengths, gaps, and next moves.
- `references/language-policy.md`: baseline for when to write repo docs in English vs Korean.
- `references/commands.md`: repeatable local commands for setup, build, and tests.
- `exec-plans/active/`: work plans for multi-step tasks that may span sessions.
- `exec-plans/completed/`: archived plans and change notes worth preserving.

## Current Snapshot

- Main app flow exists across app, feature, domain, and core modules.
- The widget scaffold exists, including a quick link into the brewing flow.
- `DatabaseClient.liveValue` uses a local SwiftData-backed store with no sample seed data.
- CloudKit sync is not wired yet.
- Only `CoffeeDomain` has automated tests checked in.
- The repository now has a short `AGENTS.md` and standard scripts, but no CI yet.
- `wiki/` is intentionally non-canonical and should not be used as agent context unless the repo docs explicitly point there.

## Required Doc Updates

- Update `PRD-v2.md` when user-visible behavior or domain rules change.
- Update `Tech-Spec-v2.md` when architecture, persistence strategy, or dependency boundaries change.
- Update `quality-score.md` when a major gap is closed or a new one is introduced.
- Follow `references/language-policy.md` when creating or heavily rewriting docs.
- Add or revise an exec plan when work is too large for a single isolated change.
- Keep `references/commands.md` aligned with any new scripts or workflow changes.
