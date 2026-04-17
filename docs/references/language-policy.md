# Documentation Language Policy

This file sets the default language baseline for repository documents.

## Goal

Use the language that gives the best combined outcome for:

- Codex accuracy
- maintainer speed
- low ambiguity between docs, code, tests, and commands

The baseline is not "everything in English." The baseline is "agent-facing operational docs in English, product-intent docs may stay Korean."

## Default By Document Type

### Write In English

Use English by default for repository documents that Codex will use as operating instructions or implementation control surfaces:

- `AGENTS.md`
- architecture and boundary docs
- command references
- quality score / gap tracker docs
- execution plans
- code review checklists
- test strategy and validation harness docs
- CI, release, migration, or remediation runbooks

These docs are closest to code, libraries, commands, error messages, and architectural invariants, so English usually reduces friction.

### Write In Korean

Use Korean by default for documents whose main job is to preserve product intent or UX nuance for the human maintainer:

- PRDs
- user problems and motivation
- UX rationale
- onboarding flow intent
- copywriting direction
- feature prioritization notes for local stakeholders

These docs benefit from precision in product language more than from alignment with API terminology.

## BeanTracker Baseline

### English Canonical Docs

- `AGENTS.md`
- `docs/index.md`
- `docs/architecture.md`
- `docs/quality-score.md`
- `docs/references/language-policy.md`
- `docs/references/commands.md`
- `docs/exec-plans/active/*`
- `docs/exec-plans/completed/*`

### Korean Canonical Docs

- `docs/PRD-v2.md`
- `docs/Tech-Spec-v2.md`, as long as it remains primarily a human-oriented product-to-implementation bridge
- future product strategy, UX notes, and copy docs unless there is a strong reason to make them English

## Mixed Cases

Some docs sit between product and implementation. Use these rules:

1. If the document mainly tells Codex how to act, default to English.
2. If the document mainly preserves product judgment, Korean is fine.
3. If a Korean product document introduces enforceable technical rules, restate those rules in an English agent-facing doc such as:
   - `docs/architecture.md`
   - `docs/quality-score.md`
   - an exec plan
   - `AGENTS.md`

This avoids forcing full translation while still exposing hard constraints clearly to the agent.

## Writing Rules

- Keep file names, module names, target names, API names, shell commands, and test identifiers in English.
- Do not translate code identifiers into Korean prose if the English identifier is the thing that matters.
- Prefer one primary language per document instead of line-by-line bilingual duplication.
- Avoid maintaining full Korean and English copies of the same canonical doc.
- When needed, add a short summary in the other language instead of duplicating the whole document.

## Migration Policy

- Do not mass-translate the repository just for consistency.
- Existing Korean docs are acceptable if they are still useful and maintained.
- When heavily rewriting an agent-facing operational doc, convert it to English.
- When heavily rewriting a product-intent doc, keeping it in Korean is acceptable.
- If unsure, optimize for maintainer speed first, then mirror any hard technical rule into an English agent-facing doc.

## Practical Guidance

- Good fit for English:
  - "Run `scripts/test-domain` after changing savings logic."
  - "Feature code must not import SwiftData directly."
- Good fit for Korean:
  - "사용자는 절약액 증가를 즉시 보상처럼 느껴야 한다."
  - "원두 등록 흐름은 입력 피로보다 성취감을 먼저 만들어야 한다."

## Current Decision

For BeanTracker, keep the current product docs in Korean unless there is a major rewrite, and keep all Codex operating docs in English going forward.
