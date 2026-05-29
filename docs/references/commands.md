# BeanTracker Command Reference

These are the standard local commands agents should prefer over ad-hoc shell sequences.

## Setup

- `scripts/check-harness`
  - Verifies that the core agent-facing docs and scripts exist.
- `scripts/bootstrap`
  - Runs `tuist install` and `tuist generate`.
- `scripts/generate`
  - Regenerates Xcode projects after graph changes.

## Validation

- `scripts/test-domain`
  - Runs `CoffeeDomainTests` through `xcodebuild`.
- `scripts/build-app`
  - Builds `BeanTrackerApp` through `xcodebuild` with code signing disabled for local validation.

## Environment Variables

- `BEANTRACKER_SIMULATOR`
  - Overrides the simulator name used by `scripts/test-domain`.
  - Default: `iPhone 16`
- `BEANTRACKER_DERIVED_DATA`
  - Overrides the derived data root for all scripts.
  - Default: `.derivedData/codex`

## Usage Guidance

- After changing `Project.swift`, `Workspace.swift`, or Tuist package settings:
  - run `scripts/generate`
- After changing calculations, fixtures, or snapshots in `CoffeeDomain`:
  - run `scripts/test-domain`
- After changing app wiring, build settings, or target composition:
  - run `scripts/build-app`
- Before handing work back:
  - run the smallest relevant command and report anything you could not verify
