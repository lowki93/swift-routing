# NavigationLink

Use this guide for route-based `NavigationLink` in SwiftRouting.

## Purpose

SwiftRouting provides `NavigationLink` convenience initializers that accept `Route` directly.
They remove the need to manually wrap values in `AnyRoute`.

## Basic Usage

```swift
NavigationLink(route: HomeRoute.detail(id: 42)) {
  Text("Open details")
}
```

Text-based variants are also available:

```swift
NavigationLink("Open details", route: HomeRoute.detail(id: 42))
```

## Behavior (Important)

`NavigationLink(route:)` is push-only stack navigation.

Why:
- It uses `NavigationLink(value:)` under the hood.
- It pushes route values in the current `NavigationStack`.

If you need modal presentation, use router APIs:
- `router.present(...)`
- `router.cover(...)`

## Scope Requirements

`NavigationLink(route:)` must be used inside a `RoutingView` configured with a matching route destination type.

Example:

```swift
RoutingView(destination: HomeRoute.self, root: .home) {
  List {
    NavigationLink("Detail", route: HomeRoute.detail(id: 42))
  }
}
```

## NavigationLink vs Router Calls

Use `NavigationLink(route:)` when:
- navigation is user-initiated from UI elements
- push behavior is desired
- declarative list/item navigation is preferred

Use `router.push/present/cover` when:
- navigation is programmatic
- navigation depends on async results/conditions
- modal presentation is required

## Best Practices

- Keep links close to UI intent (rows, cards, inline actions).
- Prefer router APIs for orchestration/flow control.
- Do not rely on `routingType` for `NavigationLink` modal behavior.
