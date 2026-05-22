# Figma Design Implementation

Status: active
Owner: repository
Updated: 2026-05-22

## Goal

Bring the current SwiftUI app closer to the BeanTracker Figma design while keeping each change small enough for a human review and commit checkpoint.

## Source Design

- Figma file: `BeanTracker`
- Page: `Page 1`
- Home frame: `3:1043`
- Brewing frame: `3:1146`
- Inventory frame: `3:885`

## Guardrails

- Keep dependency flow `Feature -> Domain -> Core`.
- Do not add persistence access to Feature views.
- Keep existing TCA state and reducer behavior unless a slice explicitly calls out a behavior change.
- Prefer focused visual changes before broader architecture or project graph changes.
- Run the smallest relevant validation before each handoff.

## Review Slices

### Slice 1: Dashboard Home Visual Pass

Status: committed in `a2197a8`

Scope:

- Replace the default dashboard `Form`-like layout with the Figma home composition.
- Preserve existing `DashboardSnapshot` data inputs.
- Add only local view helpers/styles needed by `DashboardFeature`.
- Keep month navigation available even if the Figma home frame de-emphasizes it.

Definition of done:

- Home shows a warm app background, greeting header, dark cup-count hero card, current bean status card, and compact monthly flow card.
- Empty/no-active-bean states still render meaningful copy.
- Focused build validation is attempted.

### Slice 2: Brewing Visual Pass

Status: committed in `50391d0`

Scope:

- Replace the default `Form` with the centered quick-log composition from Figma.
- Preserve existing reducer actions and save behavior.
- Keep accessible controls for bean selection and used weight changes.

Definition of done:

- Brewing screen shows selected bean, large used-weight value, decrement/increment controls, and a prominent record button.
- Invalid and empty-bean states remain understandable.
- Focused build validation is attempted.

### Slice 3: Inventory Visual Pass

Status: implemented, awaiting maintainer review/commit

Scope:

- Replace the default inventory list with segmented active/exhausted sections and Figma-style bean cards.
- Preserve save, delete, and exhausted-state actions.
- Keep the new-bean entry point available.

Definition of done:

- Inventory screen shows active/exhausted counts, rounded bean cards, progress bars, purchase metadata, and status badges.
- Delete confirmation behavior remains intact.
- Focused build validation is attempted.

### Slice 4: Shared Polish

Status: pending

Scope:

- Consolidate repeated colors, card styles, and small typography helpers if duplication becomes meaningful.
- Align tab labels and navigation titles with the Figma/product language.
- Avoid a new shared module unless the duplication clearly justifies project graph changes.

Definition of done:

- The three core screens feel visually coherent.
- Any new shared helper stays within existing module boundaries or is documented if a new target is needed.
- Focused build validation is attempted.

### Slice 5: Preview And Validation Follow-Up

Status: pending

Scope:

- Add or update representative previews for the redesigned screens using mock dependencies.
- Document any residual gap that cannot be checked locally.

Definition of done:

- At least the redesigned happy path states are previewable.
- `docs/quality-score.md` or the relevant active plan is updated if the UI validation surface materially improves.

## Current Checkpoint

Slice 3 is implemented. Stop here so the maintainer can review and commit before moving to Slice 4.

Validation:

- `scripts/check-harness` passed.
- `scripts/build-app` was attempted during Slice 1, but the project-only build could not resolve workspace module dependencies.
- Equivalent workspace build passed with `CODE_SIGNING_ALLOWED=NO`:
  `xcodebuild -workspace BeanTracker.xcworkspace -scheme BeanTrackerApp -derivedDataPath .derivedData/codex/app -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build`
- Slice 2 validation passed:
  - `scripts/check-harness`
  - `git diff --check`
  - `xcodebuild -workspace BeanTracker.xcworkspace -scheme BeanTrackerApp -derivedDataPath .derivedData/codex/app -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build`
- Slice 3 validation passed:
  - `git diff --check`
  - `xcodebuild -workspace BeanTracker.xcworkspace -scheme BeanTrackerApp -derivedDataPath .derivedData/codex/app -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build`

Notes:

- Slice 3 keeps `InventoryBeanSummary` unchanged. The current card progress bar is a visual estimate based on cup count and total weight because the inventory snapshot does not yet expose exact used weight or remaining weight.
