---
name: swift-routing-migration
description: Step-by-step guidance for migrating an existing SwiftUI app from native NavigationStack to SwiftRouting.
---

# SwiftRouting Migration

## Dependencies

Always load `swift-routing` alongside this skill:

```
npx openskills read swift-routing
npx openskills read swift-routing-migration
```

This skill covers the migration path (before → after). The `swift-routing` skill covers the complete SwiftRouting API reference, patterns, and troubleshooting.

## When To Use This Skill

Load this skill when:
- An existing app uses `NavigationStack`, `NavigationLink(value:)`, or `.sheet(isPresented:)` and needs to adopt SwiftRouting
- The task involves replacing native navigation with SwiftRouting APIs
- A user asks how to migrate from native SwiftUI navigation

Do not use this skill for:
- New projects starting fresh with SwiftRouting (use `swift-routing` instead)
- Ongoing navigation feature work on an already-migrated app

## Core Replacements

| Native SwiftUI | SwiftRouting |
|---|---|
| `NavigationStack(path:)` + `navigationDestination` | `RoutingView(destination:root:)` + `RouteDestination` |
| `NavigationLink(value:)` | `router.push(_:)` or `NavigationLink(route:)` |
| `.sheet(isPresented:)` | `router.present(_:)` |
| `.fullScreenCover(isPresented:)` | `router.cover(_:)` |
| `@Environment(\.dismiss)` | `router.close()` |
| Native `TabView` with `@State` int selection | `RoutingTabView` or `TabView` + `.tabToRoot` |
| Manual `NavigationPath` mutation in `.onOpenURL` | `DeeplinkHandler` + `router.handle(deeplink:)` |

## Key Constraints

- `NavigationLink(route:)` is push-only — use `router.present` for modals.
- `router.close()` only works on presented (modal) routers.
- `DeeplinkHandler.R` must be `Hashable & Sendable` — never pass `URL` directly.
- `DeeplinkHandler.D` must match the `RoutingView(destination:root:)` route type.
- Handle deeplinks from a view **inside** `RoutingView` so `@Environment(\.router)` points to the correct router scope.

## References

See `references/_index.md`.
