# SwiftRouting

## Overview

This skill provides practical guidance for implementing and troubleshooting navigation with SwiftRouting in SwiftUI apps.

Primary focus areas:
- `Route` and `RouteDestination`
- `Router` and `RouterModel`
- `TabRouter` and tab-based flows
- Deep links
- Route context patterns

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

- Need to define destinations and route enums?
  - Use `references/routes.md`
- Need push/present/cover/back/pop behaviors?
  - Use `references/router.md`
- Need tab orchestration and per-tab routing?
  - Use `references/tab-router.md`
- Need external URL/app link routing?
  - Use `references/deeplinks.md`
- Need child-to-parent data passing?
  - Use `references/route-context.md`
- Need declarative row/button navigation?
  - Use `references/navigation-link.md`
- Debugging odd lifecycle or routing behavior?
  - Use `references/troubleshooting.md`

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
