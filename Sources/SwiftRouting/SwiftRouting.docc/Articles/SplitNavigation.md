# Split Navigation

Learn how to implement sidebar-based split navigation with SwiftRouting.

## Overview

SwiftRouting provides first-class support for `NavigationSplitView` through ``RoutingSplitView`` and ``SplitModel``. All three columns (sidebar, content, detail) share the same split-type ``Router`` — column selection is driven by typed, `Hashable` values, and only the detail column has a navigation stack, bound directly to that shared router's `path`.

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

Use ``Router/detailBinding(as:)`` and ``Router/contentBinding(as:)`` to wire a `List` selection directly, or call ``Router/select(detail:)`` / ``Router/select(content:)`` programmatically. Both paths behave identically -- the binding calls `select(detail:)`/`select(content:)` internally, so a selection made by tapping a `List` row logs a `.navigation` event just like a programmatic call would.

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

`router.push(_:)` works like everywhere else in SwiftRouting, but since all columns share the same split ``Router``, it always pushes onto the one navigation stack — rendered only in the detail column. Pushing from the sidebar or content column doesn't open a stack there; it appears in the detail column instead.

`router.present(_:)` and `.cover(_:)` are also router-wide, not per-column: calling them from any column presents the same sheet/cover over the whole `RoutingSplitView`.

## Deep Linking

Use ``SplitDeeplinkHandler`` to convert an external input into a ``SplitDeeplink``, and ``Router/handle(splitDeeplink:)`` to apply it:

```swift
struct PlayerSplitDeeplinkHandler: SplitDeeplinkHandler {
    func deeplink(from route: DeeplinkIdentifier) async throws -> SplitDeeplink<PlayerType, Player, AppRoute>? {
        switch route {
        case .player(let player):
            SplitDeeplink(content: player.type, detail: player)
        default:
            nil
        }
    }
}

router.handle(splitDeeplink: splitDeeplink)
```

`handle(splitDeeplink:)` selects `content` (3-column layout only), then `detail`, then applies the optional `deeplink` within the detail column's own navigation stack — the content column has no stack of its own, so `deeplink` can only push into `detail`.

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
