---
name: swift-routing-migration
description: Step-by-step guidance for migrating an existing SwiftUI app from native NavigationStack to SwiftRouting.
---

# SwiftRouting Migration

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
| Manual `NavigationPath` mutation in `.onOpenURL` | `DeeplinkHandler` + `router.handle(deeplink:)` |

## Step 1 — Define Routes

Replace `navigationDestination` with a `Route` enum and `RouteDestination`:

```swift
enum HomeRoute: Route {
    case home
    case detail(id: Int)
    case settings

    var name: String {
        switch self {
        case .home: "home"
        case .detail(let id): "detail(\(id))"
        case .settings: "settings"
        }
    }
}

extension HomeRoute: RouteDestination {
    static func view(for route: HomeRoute) -> some View {
        switch route {
        case .home: HomeView()
        case .detail(let id): DetailView(id: id)
        case .settings: SettingsView()
        }
    }
}
```

## Step 2 — Replace NavigationStack

```swift
// Before
NavigationStack(path: $path) {
    HomeView()
        .navigationDestination(for: String.self) { ... }
}

// After
RoutingView(destination: HomeRoute.self, root: .home)
```

## Step 3 — Replace Navigation Calls

```swift
// Before
path.append("detail")

// After
router.push(HomeRoute.detail(id: 42))
```

Modal presentations:

```swift
router.present(HomeRoute.settings)                    // sheet (with nav stack)
router.present(HomeRoute.settings, withStack: false)  // sheet without nav stack
router.cover(HomeRoute.onboarding)                    // full-screen cover
router.close()                                        // dismiss modal
```

## Step 4 — Replace Deep Links

Define a typed identifier (`Hashable & Sendable`) — never pass `URL` directly as `R`:

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

Handle from a view inside `RoutingView`:

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

- `NavigationLink(route:)` is push-only — use `router.present` for modals.
- `router.close()` only works on presented (modal) routers.
- `DeeplinkHandler.R` must be `Hashable & Sendable` — never pass `URL` directly.
- `DeeplinkHandler.D` must match the `RoutingView(destination:root:)` route type.
- Handle deeplinks from a view **inside** `RoutingView` so `@Environment(\.router)` points to the correct router scope.
