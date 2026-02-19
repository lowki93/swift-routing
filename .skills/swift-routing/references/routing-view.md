# RoutingView

Use this guide to understand how `RoutingView` creates and scopes routers.

## Why RoutingView Matters

`RoutingView` is the entry point of SwiftRouting navigation.
Each `RoutingView` creates and owns a `Router` instance, then exposes it through:

```swift
@Environment(\.router) private var router
```

Without `RoutingView`, `@Environment(\.router)` is not available in child views.

## Basic Setup

`RoutingView` requires a destination type that conforms to `RouteDestination`.
That is why examples pass `HomeRoute.self` only when `HomeRoute` conforms to both:
- `Route`
- `RouteDestination`

Example:

```swift
enum HomeRoute: Route {
  case home
  var name: String { "home" }
}

extension HomeRoute: RouteDestination {
  static func view(for route: HomeRoute) -> some View {
    HomeScreen()
  }
}
```

Create a stack with a route root:

```swift
RoutingView(destination: HomeRoute.self, root: .home)
```

Or provide a custom root view:

```swift
RoutingView(destination: HomeRoute.self, root: .home) {
  HomeScreen()
}
```

## Tabs

`RoutingView` also supports tab-scoped stacks via `RoutingView(tab:destination:root:)`.
For complete tab orchestration and `TabRouter` usage, see `references/tab-router.md`.

## Presented Routers

When calling `present` or `cover`, SwiftRouting creates a presented router scope.
That is why `router.close()` should be called from the presented context.

## Relationship With RouteDestination

- `RoutingView` defines the navigation container and router scope.
- `RouteDestination` defines how each route renders a SwiftUI view.
- `Router` performs navigation actions (`push`, `present`, `cover`, etc.).

## Best Practices

- Keep one top-level `RoutingView` per navigation stack.
- In views, read `router` from environment instead of passing it manually.
- Pass router to ViewModels as `any RouterModel` only when needed.
- Use `references/tab-router.md` for tab-specific patterns and `RoutingTabView`.
