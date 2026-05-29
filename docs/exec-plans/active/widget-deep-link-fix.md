# Widget Deep Link Fix

Status: active
Owner: repository
Updated: 2026-05-29

## Goal

Make the existing BeanTracker widget usable as a quick entry point into the brewing flow.

## Findings

- The app target registers the `beantracker` URL scheme.
- The widget target is embedded in the app and exposes `QuickLogWidget` as a small WidgetKit widget.
- The widget linked to `beantracker://brew`, but the app root view and reducer did not handle incoming URLs.
- The widget view did not use the iOS 17 `containerBackground(for: .widget)` modifier.

## Slices

### Slice 1: Routing

Status: Completed

- Add app-level URL handling from `AppView`.
- Parse `beantracker://brew` in `AppFeature`.
- Route completed users to the brewing tab.
- Preserve the deep link while bootstrapping so launch timing does not drop the widget tap.

### Slice 2: Widget Tap Surface

Status: Completed

- Make the whole small widget open the brew deep link.
- Remove the force-unwrapped URL from the widget view.
- Add a WidgetKit container background aligned with the current warm app palette.
- Keep the widget preview available without the SwiftUI `#Preview` macro so agent builds do not depend on the preview macro server.

### Slice 3: Documentation And Validation

Status: Completed

- Update architecture notes for widget deep-link routing.
- Run harness and app build validation.

## Current Checkpoint

Implementation and focused validation are complete. Stop here so the maintainer can review and commit before expanding widget behavior beyond deep linking.

Validation:

- `scripts/check-harness` passed.
- `git diff --check` passed.
- `scripts/build-app` passed.
