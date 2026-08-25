# Native Apple App Engineering

This project follows a minimal-diff, build-first approach to iOS development.

## Core rules

- Preserve working behavior and public contracts.
- Make the smallest focused change that satisfies the request.
- Prefer native SwiftUI controls and navigation.
- Verify unfamiliar APIs against current Apple documentation and the deployment target.
- Keep UI state owned by the appropriate view or model and mutate it on the main actor.
- Prefer structured concurrency and handle cancellation.
- Support Dynamic Type, VoiceOver, dark mode, Reduce Motion, and comfortable touch targets.
- Treat permissions, Info.plist keys, capabilities, cleanup, and failure states as part of feature completeness.
- Do not fake integrations: trace data from input through the owning model or callback.
- Build the real application target after meaningful changes and resolve diagnostics before handoff.

## Scope discipline

- Avoid unrelated refactors, new dependencies, and architecture layers without a concrete need.
- Keep native controls intact unless the requested behavior cannot be implemented with them.
- Preserve layout, bindings, callbacks, animations, and accessibility behavior unless the task explicitly changes them.
- Search for existing design tokens, helpers, and components before adding new ones.
- Leave sheet implementations unchanged unless a task explicitly targets them.

## SwiftUI defaults

- Use @State for local owned value state, @Binding for parent-owned state, and @FocusState for focus.
- Prefer NavigationStack, TabView, List, Form, Menu, PhotosPicker, fileImporter, sheet, alert, and confirmationDialog.
- Use semantic typography and colors; keep brand colors intentional and dark-mode safe.
- Use stable identities in ForEach and avoid generating transient IDs during rendering.
- Keep expensive work out of view bodies and off UI-critical paths.
- Use Button for button semantics rather than tap gestures.
- Keep controls accessible with labels, hints, state announcements, and adequate hit areas.

## Verification checklist

Before finishing a change, check:

1. The requested behavior works.
2. The application target builds without new errors.
3. Platform availability and deployment target are correct.
4. Existing navigation, sheets, callbacks, and layout remain intact.
5. Empty, loading, success, cancellation, and failure states are sensible.
6. Light mode, dark mode, Dynamic Type, VoiceOver, and Reduce Motion remain usable.
7. Permissions and target configuration are present for protected resources.
8. Hardware-sensitive behavior is distinguished from simulator limitations.
9. The final change is limited to the requested scope.
