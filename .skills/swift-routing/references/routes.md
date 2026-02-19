# Defining Routes

Use this guide to define route types and map them to views in SwiftRouting.

## Route Requirements

Each route type should:
- conform to `Route`
- be `Hashable` and `Sendable` (through `Route`)
- provide a readable `name` for logging and diagnostics

## Recommended Pattern

Prefer a single enum per feature or flow:

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
```

## Map Routes To Views

Conform the same type to `RouteDestination`:

```swift
extension HomeRoute: RouteDestination {
  static func view(for route: HomeRoute) -> some View {
    switch route {
    case .home:
      HomeView()
    case .detail(let id):
      DetailView(id: id)
    case .settings:
      SettingsView()
    }
  }
}
```

## Using Environment Values In RouteDestination

When you need `@Environment`, `@EnvironmentObject`, or dependency injection, return a dedicated destination view instead of switching directly inside `view(for:)`.

```swift
extension HomeRoute: RouteDestination {
  static func view(for route: HomeRoute) -> some View {
    HomeRouteDestination(route: route)
  }
}

struct HomeRouteDestination: View {
  @Environment(\.router) private var router
  @EnvironmentObject private var appState: AppState
  let route: HomeRoute

  var body: some View {
    switch route {
    case .home:
      HomeView()
    case .detail(let id):
      DetailView(viewModel: DetailsViewModel(id: id, router: router))
    case .settings:
      SettingsView(isLoggedIn: appState.isLoggedIn)
    }
  }
}
```

Use this pattern when route rendering needs runtime environment dependencies.

Notes:
- In SwiftUI views, prefer reading `router` directly from `@Environment(\.router)`.
- Passing `router` as an argument is usually only needed for ViewModel injection (`any RouterModel`).
- Keep ViewModel internals out of this guide; document them in a dedicated skill/reference.

## Where To Put presentationDetents / presentationDragIndicator

Apply sheet modifiers directly on the destination view returned by `RouteDestination`:

```swift
extension HomeRoute: RouteDestination {
  static func view(for route: HomeRoute) -> some View {
    switch route {
    case .settings:
      SettingsView()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    default:
      HomeView()
    }
  }
}
```

This requires presenting the sheet with:

```swift
router.present(HomeRoute.settings, withStack: false)
// or
var routingType: RoutingType { .sheet(withStack: false) }
```

## Nested Routes

For larger features, you can model subflows with nested route enums and expose them through a parent route.

```swift
enum AppRoute: Route {
  case home
  case profile(ProfileRoute)

  var name: String {
    switch self {
    case .home:
      return "home"
    case .profile(let child):
      return "profile.\(child.name)"
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

You can then resolve nested cases in the parent destination mapping:

```swift
extension AppRoute: RouteDestination {
  static func view(for route: AppRoute) -> some View {
    switch route {
    case .home:
      HomeView()
    case .profile(let child):
      ProfileRouteDestination(route: child)
    }
  }
}

struct ProfileRouteDestination: View {
  let route: ProfileRoute

  var body: some View {
    switch route {
    case .overview:
      ProfileOverviewView()
    case .edit(let userId):
      ProfileEditView(userId: userId)
    }
  }
}
```

Note:
- Only the top-level route used by `RoutingView` (for example `AppRoute`) needs to conform to `RouteDestination`.
- Child route enums (for example `ProfileRoute`) can stay plain `Route` types and be rendered by dedicated destination views.

Nested routes are useful to keep route definitions modular while preserving type safety.

## Naming Guidance

For associated values, include enough context in `name` to make logs actionable.

Good examples:
- `detail(42)`
- `profile(user_123)`

Avoid generic names that hide runtime context:
- `detail`
- `profile`

## Routing Type (Optional)

If needed, customize route presentation behavior via `routingType`:
- `.push`
- `.sheet`
- `.cover`
- `.root`

Use this only when a route has a clear default presentation policy.

If a sheet route needs direct presentation modifiers (`presentationDetents`, `presentationDragIndicator`), prefer:

```swift
var routingType: RoutingType { .sheet(withStack: false) }
```

## Best Practices

- Keep route enums focused and cohesive.
- Keep `RouteDestination` mapping deterministic and side-effect free.
- Avoid business logic inside the route-to-view switch.
- Prefer explicit route cases over stringly-typed navigation.
