# Step 5 — Split View (Sidebar Navigation)

## Before

```swift
@State private var selection: Player?

NavigationSplitView {
    List(players, selection: $selection) { player in
        NavigationLink(player.name, value: player)
    }
} detail: {
    if let selection {
        PlayerDetailView(player: selection)
    }
}
```

## After

```swift
enum AppRoute: Route {
    case sidebar
    case players(PlayerType)
    case player(Player)

    var name: String {
        switch self {
        case .sidebar: "sidebar"
        case .players(let type): "players(\(type))"
        case .player(let player): "player(\(player.id))"
        }
    }
}

RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (player: Player) in
    AppRoute.player(player)
}
```

```swift
struct SidebarScreen: View {
    @Environment(\.router) var router
    let players: [Player]

    var body: some View {
        List(players, selection: router.detailBinding(as: Player.self)) { player in
            NavigationLink(player.name, value: player)
        }
    }
}
```

## 3-Column Layout

Add a `content:` closure if the native version had a sidebar → content → detail chain:

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
    AppRoute.players(type)
} detail: { (player: Player) in
    AppRoute.player(player)
}
```

## Compact Mode (iPhone)

```swift
// Before
if horizontalSizeClass == .compact { /* skip auto-selection */ }

// After
guard !router.isCompact else { return }
router.select(detail: players.first)
```

## Key Constraints

- All three columns (sidebar, content, detail) share the same split `Router` — there's one shared navigation stack, rendered only in the detail column. A push from the sidebar or content column lands in the detail column, not a stack of its own.
- Use `router.detailBinding(as:)` / `router.contentBinding(as:)` for `List` selection, or `router.select(detail:)` / `router.select(content:)` programmatically.
- `router.isCompact` replaces manual `horizontalSizeClass` checks for skipping auto-selection on iPhone.
- For deep links, use `SplitDeeplinkHandler` + `router.handle(splitDeeplink:)` — see `references/split-router.md`.

See `references/split-router.md` in the `swift-routing` skill for the full API reference.
