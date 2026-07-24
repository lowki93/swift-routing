# Split Navigation

Learn how to implement sidebar-based split navigation with SwiftRouting.

## Overview

SwiftRouting provides first-class support for `NavigationSplitView` through ``RoutingSplitView`` and ``SplitModel``. Each column (sidebar, content, detail) renders inside its own `RoutingView`, so it gets an independent navigation stack while column selection stays driven by typed, `Hashable` values.

A split-type ``Router`` is created automatically and injected into the environment via `@Environment(\.router)`. It conforms to ``SplitModel``, giving you typed bindings and programmatic selection alongside the regular `push`/`present`/`cover` API.

## 2-Column Layout (Sidebar + Detail)

The sidebar shows a fixed route; the detail column is derived from a typed selection:

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
    AppRoute.players(type)
}
```

## 3-Column Layout (Sidebar + Content + Detail)

Add a `content:` closure to introduce a middle column. The sidebar drives the content column, and the content column drives the detail column:

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
    AppRoute.players(type)
} detail: { (player: Player) in
    AppRoute.player(player)
}
```

## Driving Selections

Use ``Router/detailBinding(as:)`` and ``Router/contentBinding(as:)`` to wire a `List` selection directly, or call ``Router/select(detail:)`` / ``Router/select(content:)`` programmatically:

```swift
struct SidebarScreen: View {
    @Environment(\.router) var router
    let items: [PlayerType] = PlayerType.allCases

    var body: some View {
        List(items, selection: router.detailBinding(as: PlayerType.self)) { item in
            NavigationLink(item.label, value: item)
        }
        .onFirstAppear {
            guard !router.isCompact else { return }
            router.select(detail: items.first)
        }
    }
}
```

Use ``Router/hasContentColumn`` to branch between driving the content or the detail column from the same sidebar code path:

```swift
if router.hasContentColumn {
    router.select(content: playerType)
} else {
    router.select(detail: playerType)
}
```

## Compact Mode (iPhone)

On iPhone, `NavigationSplitView` collapses into a single-column stack. Use ``Router/isCompact`` to skip auto-selection and let the user tap to navigate instead:

```swift
.onFirstAppear {
    guard !router.isCompact else { return }
    router.select(detail: items.first)
}
```

`isCompact` reflects `horizontalSizeClass`, so it also updates during iPad multitasking.

## Navigating Within a Column

Each column is its own `RoutingView`, so `router.push(_:)`, `.present(_:)`, and `.cover(_:)` work the same way they do everywhere else in SwiftRouting — a push inside the detail column only affects the detail column's stack.

> Note:
> Split navigation does not currently integrate with ``DeeplinkHandler``. Resolve deep links to a selection value before setting it via ``Router/select(detail:)`` or a binding.

### SplitModel Reference

| Member | Description |
|--------|-------------|
| `detailSelection` | Type-erased current selection for the detail column |
| `contentSelection` | Type-erased current selection for the content column (3-column only) |
| `isCompact` | Whether the split view is currently collapsed to a single column |
| `hasContentColumn` | Whether this router was created with a `content:` closure |
| `detailBinding(as:)` | Typed `Binding<T?>` for the detail column selection |
| `contentBinding(as:)` | Typed `Binding<T?>` for the content column selection |
| `select(detail:)` | Programmatically drive the detail column selection |
| `select(content:)` | Programmatically drive the content column selection |
