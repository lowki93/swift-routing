# Split Router

Use this guide for sidebar-based split navigation with `RoutingSplitView` and `SplitModel`.

## Prerequisites

Before using `RoutingSplitView`, make sure you already have:
1. Route definitions (`Route` + `RouteDestination`)
2. `RoutingView` basics

Recommended order:
- `references/routes.md`
- `references/routing-view.md`
- `references/router.md`

## 2-Column Layout (Sidebar + Detail)

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
  AppRoute.players(type)
}
```

The sidebar renders a fixed route. The detail column is derived from whatever `DetailData` value is currently selected.

## 3-Column Layout (Sidebar + Content + Detail)

Add a `content:` closure to introduce a middle column, driven by the sidebar:

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
  AppRoute.players(type)
} detail: { (player: Player) in
  AppRoute.player(player)
}
```

Each column (sidebar, content, detail) is its own `RoutingView` with an independent navigation stack — a `push`/`present`/`cover` in one column never affects another.

## Driving Column Selections

A split-type `Router` conforms to `SplitModel`, giving typed bindings and programmatic selection:

```swift
@Environment(\.router) var router

// Typed binding for a List selection
List(players, selection: router.detailBinding(as: Player.self)) { player in
  NavigationLink(player.name, value: player)
}

// Programmatic selection
router.select(detail: players.first)
router.select(content: playerType) // 3-column only
```

Use `hasContentColumn` to branch shared sidebar code between 2-column and 3-column layouts:

```swift
if router.hasContentColumn {
  router.select(content: playerType)
} else {
  router.select(detail: playerType)
}
```

## Compact Mode (iPhone)

`NavigationSplitView` collapses to a single column on iPhone. Use `router.isCompact` to skip auto-selection so the first tap navigates instead of silently pre-selecting a detail:

```swift
.onFirstAppear {
  guard !router.isCompact else { return }
  router.select(detail: items.first)
}
```

`isCompact` tracks `horizontalSizeClass`, so it also flips during iPad multitasking / Split View / Slide Over.

## ViewModel Injection

Inject `any SplitModel` (protocol) in ViewModels, not concrete `Router`:

```swift
@MainActor
final class SidebarViewModel: ObservableObject {
  private let router: any SplitModel

  init(router: any SplitModel) {
    self.router = router
  }

  func selectFirst(_ players: [Player]) {
    guard !router.isCompact else { return }
    router.select(detail: players.first)
  }
}
```

## Constraints

- Deep linking does not integrate with split routers today — resolve the target value first, then call `select(detail:)`/`select(content:)` or set the binding.
- `detailBinding(as:)`/`contentBinding(as:)` return `.constant(nil)` for non-split routers — safe to call unconditionally, but only meaningful inside a `RoutingSplitView`.

## Best Practices

- Keep one `RoutingView` per column.
- Guard programmatic selection with `!router.isCompact` unless you intend to force-navigate on iPhone.
- Prefer protocol injection in ViewModels (`SplitModel`).
- Use `hasContentColumn` instead of duplicating sidebar logic for 2-column vs 3-column layouts.
