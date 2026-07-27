---
name: swift-routing
description: SwiftRouting guidance for routes, routers, tabs, deeplinks, and troubleshooting.
---

# SwiftRouting

## Overview

This skill provides practical guidance for implementing and troubleshooting navigation with SwiftRouting in SwiftUI apps.

Primary focus areas:
- `Route` and `RouteDestination`
- `RoutingView` and router lifecycle
- `Router` and `RouterModel`
- `TabRouter` and tab-based flows
- `RoutingSplitView` and `SplitModel` for sidebar/split-view flows
- Deep links
- Route context patterns
- `Configuration` and route-not-found behavior

## When To Use This Skill

Use this skill when the codebase includes:
- `import SwiftRouting`
- `RoutingView`, `RoutingTabView`, or `RoutingSplitView`
- `Router`, `RouterModel`, `TabRouter`, `TabRouterModel`, or `SplitModel`
- navigation issues around stack, sheet, cover, tabs, split columns, or deep links

## When Not To Use This Skill

Do not use this skill for:
- UIKit-only navigation architectures
- backend or non-UI tasks
- generic Swift topics unrelated to routing

## Agent Behavior Contract

1. Validate existing project conventions first (`README`, DocC, and public APIs).
2. Prefer protocol-based APIs (`RouterModel`, `TabRouterModel`) in ViewModels.
3. Keep recommendations aligned with current public SwiftRouting APIs.
4. Use incremental, low-risk migration/implementation steps.
5. For context callbacks, recommend weak captures to avoid memory leaks.

## Quick Decision Tree

Recommended learning order:
1. `references/routes.md`
2. `references/routing-view.md`
3. `references/router.md`

Then continue by use case:
- Tab orchestration and per-tab routing -> `references/tab-router.md`
- Sidebar / split-view (iPad, macOS) navigation -> `references/split-router.md`
- External URL/app link routing -> `references/deeplinks.md`
- Child-to-parent data passing -> `references/route-context.md`
- Declarative row/button navigation -> `references/navigation-link.md`
- Configuring logger and route-not-found policy -> `references/configuration.md`
- Lifecycle/routing debugging -> `references/troubleshooting.md`

## Triage-First Playbook

- "onAppear/onDisappear fires multiple times"
  - Check tab preloading and root updates; use the lifecycle guidance in troubleshooting.
- "Root changed but view state did not refresh as expected"
  - Verify `update(root:)` flow and view identity assumptions.
- "Context callback causes leak"
  - Audit closure captures in `add(context:perform:)` and `.routerContext`.
- "Deep link resolves but does not navigate"
  - Validate route mapping, destination type, and target router (`router` vs `tabRouter`).
- "Need to react to tab reselection (e.g. scroll to top)"
  - Use `.onTabReselected(tab:)` from any child view; `popToRoot` fires first, then the handler.
- "Detail/content column doesn't update after selection"
  - Check the binding/select generic type matches the `RoutingSplitView` init's `ContentData`/`DetailData` type exactly; mismatched types silently no-op.
- "Split view always shows the wrong column on iPhone"
  - Check `router.isCompact` guards around programmatic auto-selection, and `preferredCompactColumn`.

## TODO (This Skill)

- [ ] Add a compact "Testing Recipes" section with 5 end-to-end scenarios (push, sheet, cover, tab switch, deep link).

## References

See `references/_index.md`.
