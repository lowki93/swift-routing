# Deeplinks

Use this guide to convert external inputs (URL, identifier, notification payload) into navigation actions.

## Core Idea

A deep link flow has two steps:
1. Convert external input into a routing model (`DeeplinkRoute` or `TabDeeplink`)
2. Execute that routing model with the router

## DeeplinkHandler

Implement `DeeplinkHandler` to map your input type to a `DeeplinkRoute`:

```swift
struct AppDeeplinkHandler: DeeplinkHandler {
  typealias R = DeeplinkIdentifier
  typealias D = HomeRoute

  func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
    switch route {
    case .home:
      return DeeplinkRoute(type: .push, route: .home)
    case .profile(let userId):
      return DeeplinkRoute(type: .push, route: .profile(userId: userId))
    default:
      return nil
    }
  }
}
```

## DeeplinkRoute

`DeeplinkRoute` defines:
- `root` (optional): replace current root before navigation
- `path`: intermediate pushed routes
- `route`: final destination
- `type`: presentation of final destination (`push`, `sheet`, `cover`, `root`)

Example:

```swift
let deeplink = DeeplinkRoute(
  root: .home,
  type: .push,
  route: .product(id: 42),
  path: [.catalog, .category(id: 7)]
)
```

## Handling Deeplinks

Run deeplink handling from a view inside `RoutingView` so `@Environment(\.router)` points to the correct router scope:

```swift
struct HomeRootView: View {
  @Environment(\.router) private var router
  let handler = AppDeeplinkHandler()

  var body: some View {
    HomeView()
      .onOpenURL { url in
        Task {
          guard let identifier = DeeplinkIdentifier(url: url) else { return }
          guard let deeplink = try await handler.deeplink(from: identifier) else { return }
          router.handle(deeplink: deeplink)
        }
      }
  }
}
```

Important:
- The handler route type (`D`) must match your `RoutingView(destination:root:)` route type.
- Return `nil` for unsupported deeplinks.

## Async Enrichment

`deeplink(from:)` is `async`, so you can fetch or validate data before routing:

```swift
func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
  switch route {
  case .product(let id):
    let product = try await productService.fetch(id: id)
    return DeeplinkRoute(type: .push, route: .productDetail(product))
  default:
    return nil
  }
}
```

## Compose Handlers By Feature (Nested Route Logic)

For medium/large apps, split deeplink handling by feature and compose handlers at the app level.

Example route structure:

```swift
enum AppRoute: Route {
  case home
  case profile(ProfileRoute)

  var name: String {
    switch self {
    case .home: "home"
    case .profile(let child): "profile.\(child.name)"
    }
  }
}

enum ProfileRoute: Route {
  case overview
  case edit(userId: String)

  var name: String {
    switch self {
    case .overview: "overview"
    case .edit(let userId): "edit(\(userId))"
    }
  }
}
```

Feature handler:

```swift
enum ProfileDeeplinkID: Hashable, Sendable {
  case profile(userId: String)
  case editProfile(userId: String)
}

struct ProfileDeeplinkHandler: DeeplinkHandler {
  typealias R = ProfileDeeplinkID
  typealias D = AppRoute

  func deeplink(from route: ProfileDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case .profile:
      return DeeplinkRoute(type: .push, route: .profile(.overview))
    case .editProfile(let userId):
      return DeeplinkRoute(type: .push, route: .profile(.edit(userId: userId)))
    }
  }
}
```

Composed app handler:

```swift
enum AppDeeplinkID: Hashable, Sendable {
  case home
  case profile(ProfileDeeplinkID)
}

struct AppDeeplinkHandler: DeeplinkHandler {
  typealias R = AppDeeplinkID
  typealias D = AppRoute

  private let profileHandler = ProfileDeeplinkHandler()

  func deeplink(from route: AppDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case .home:
      return DeeplinkRoute(type: .push, route: .home)
    case .profile(let profileID):
      return try await profileHandler.deeplink(from: profileID)
    }
  }
}
```

This pattern keeps deeplink logic modular and aligned with nested route architecture.

## Tab Deeplinks

For tab apps, use `TabDeeplinkHandler` and return `TabDeeplink<Tab, Route>`:

```swift
struct AppTabDeeplinkHandler: TabDeeplinkHandler {
  typealias R = DeeplinkIdentifier
  typealias T = HomeTab
  typealias D = HomeRoute

  func deeplink(from route: DeeplinkIdentifier) async throws -> TabDeeplink<HomeTab, HomeRoute>? {
    switch route {
    case .profile(let userId):
      return TabDeeplink(
        tab: .profile,
        deeplink: DeeplinkRoute(type: .push, route: .profile(userId: userId))
      )
    default:
      return nil
    }
  }
}
```

Compose `TabDeeplinkHandler` by feature (nested logic) the same way:

```swift
enum ProfileTabDeeplinkID: Hashable, Sendable {
  case profile(userId: String)
  case editProfile(userId: String)
}

struct ProfileTabDeeplinkHandler: TabDeeplinkHandler {
  typealias R = ProfileTabDeeplinkID
  typealias T = HomeTab
  typealias D = HomeRoute

  func deeplink(from route: ProfileTabDeeplinkID) async throws -> TabDeeplink<HomeTab, HomeRoute>? {
    switch route {
    case .profile(let userId):
      return TabDeeplink(
        tab: .profile,
        deeplink: DeeplinkRoute(type: .push, route: .profile(userId: userId))
      )
    case .editProfile(let userId):
      return TabDeeplink(
        tab: .profile,
        deeplink: DeeplinkRoute(type: .push, route: .profileEdit(userId: userId))
      )
    }
  }
}

enum AppTabDeeplinkID: Hashable, Sendable {
  case home
  case profile(ProfileTabDeeplinkID)
}

struct RootTabDeeplinkHandler: TabDeeplinkHandler {
  typealias R = AppTabDeeplinkID
  typealias T = HomeTab
  typealias D = HomeRoute

  private let profileHandler = ProfileTabDeeplinkHandler()

  func deeplink(from route: AppTabDeeplinkID) async throws -> TabDeeplink<HomeTab, HomeRoute>? {
    switch route {
    case .home:
      return TabDeeplink(tab: .home, deeplink: DeeplinkRoute(type: .push, route: .home))
    case .profile(let profileID):
      return try await profileHandler.deeplink(from: profileID)
    }
  }
}
```

Then execute:

```swift
@Environment(\.router) private var router

func handleTabDeeplink(_ url: URL) async throws {
  guard let identifier = DeeplinkIdentifier(url: url) else { return }
  guard let tabDeeplink = try await handler.deeplink(from: identifier) else { return }
  router.tabRouter?.handle(tabDeeplink: tabDeeplink)
}
```

`TabRouter` switches tab first, then runs the embedded deeplink (if present).

Why this pattern:
- `tabRouter` is injected inside `RoutingTabView` descendants.
- A parent container that owns `RoutingTabView` may not have direct access to `@Environment(\.tabRouter)`.
- `@Environment(\.router)` is available in that scope, and `router.tabRouter` gives access to the single tab router when present.

## Best Practices

- Keep handlers pure: input -> deeplink model.
- Keep parsing and validation explicit; return `nil` when unsupported.
- Keep tab deeplink logic in dedicated handlers for maintainability.
