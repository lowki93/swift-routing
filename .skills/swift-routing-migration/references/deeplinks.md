# Step 3 — Deep Links

## Before

Deep link handling typically required parsing URLs and manually mutating `NavigationPath`:

```swift
.onOpenURL { url in
    if url.path == "/detail" {
        path.append("detail")
    }
}
```

## After

Deep link handling in SwiftRouting has two steps:
1. Parse the URL into a typed identifier
2. Map the identifier to a `DeeplinkRoute` via `DeeplinkHandler`

### Define a Typed Identifier

`DeeplinkHandler.R` must be `Hashable & Sendable` — never use `URL` directly.

```swift
enum AppDeeplinkIdentifier: Hashable, Sendable {
    case detail(id: Int)
}

extension AppDeeplinkIdentifier {
    init?(url: URL) {
        switch url.path {
        case "/detail":
            guard let id = Int(url.lastPathComponent) else { return nil }
            self = .detail(id: id)
        default:
            return nil
        }
    }
}
```

### Implement DeeplinkHandler

```swift
struct HomeDeeplinkHandler: DeeplinkHandler {
    typealias R = AppDeeplinkIdentifier
    typealias D = HomeRoute

    func deeplink(from route: AppDeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
        switch route {
        case .detail(let id):
            return .push(.detail(id: id))
        }
    }
}
```

`deeplink(from:)` is `async throws` — you can fetch or validate data before returning a route.

### Handle in a View

Call the handler from a view **inside** `RoutingView` so `@Environment(\.router)` resolves to the correct scope:

```swift
struct HomeRootView: View {
    @Environment(\.router) private var router
    let handler = HomeDeeplinkHandler()

    var body: some View {
        HomeView()
            .onOpenURL { url in
                Task {
                    guard let identifier = AppDeeplinkIdentifier(url: url) else { return }
                    guard let deeplink = try? await handler.deeplink(from: identifier) else { return }
                    router.handle(deeplink: deeplink)
                }
            }
    }
}
```

## Key Constraints

- `DeeplinkHandler.D` must match the `RoutingView(destination:root:)` route type.
- Return `nil` for unsupported deep links — never force-unwrap.
- For tab apps, use `TabDeeplinkHandler` and `router.tabRouter?.handle(tabDeeplink:)`.
