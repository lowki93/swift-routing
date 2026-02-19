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
- Deep links
- Route context patterns
- `Configuration` and route-not-found behavior

## When To Use This Skill

Use this skill when the codebase includes:
- `import SwiftRouting`
- `RoutingView` or `RoutingTabView`
- `Router`, `RouterModel`, `TabRouter`, or `TabRouterModel`
- navigation issues around stack, sheet, cover, tabs, or deep links

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

## TODO (This Skill)

- [ ] Add a compact "Testing Recipes" section with 5 end-to-end scenarios (push, sheet, cover, tab switch, deep link).

## References

See `references/_index.md`.
