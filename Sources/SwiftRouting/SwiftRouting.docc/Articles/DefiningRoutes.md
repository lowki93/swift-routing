# Defining Routes

Learn how to define and customize routes for your navigation system.

## Overview

Routes are the foundation of SwiftRouting. They define all possible navigation destinations in your app as type-safe Swift enums.

## Creating a Route Enum

A route is any enum that conforms to the ``Route`` protocol. Each case represents a distinct screen or destination.

```swift
enum HomeRoute: Route {
    case home
    case profile(userId: String)
    case settings
    case detail(item: Item)
    
    var name: String {
        switch self {
        case .home: "home"
        case .profile(let userId): "profile(\(userId))"
        case .settings: "settings"
        case .detail(let item): "detail(\(item.id))"
        }
    }
}
```

### The name Property

The `name` property provides a human-readable identifier used for:
- Logging and debugging
- Router identification
- Analytics tracking

Include relevant associated values in the name to make logs more informative.

## Mapping Routes to Views

Conform your route to ``RouteDestination`` to define which view each route displays:

```swift
extension HomeRoute: RouteDestination {
    static func view(for route: HomeRoute) -> some View {
        switch route {
        case .home:
            HomeView()
        case .profile(let userId):
            ProfileView(userId: userId)
        case .settings:
            SettingsView()
        case .detail(let item):
            DetailView(item: item)
        }
    }
}
```

## Nested Routes and Nested Destinations

For larger apps, you can model feature subflows as nested routes.
Keep the top-level route as the destination entry point, and render child routes through dedicated destination views.

```swift
enum AppRoute: Route {
    case home
    case profile(ProfileRoute)

    var name: String {
        switch self {
        case .home:
            "home"
        case .profile(let child):
            "profile.\(child.name)"
        }
    }
}

enum ProfileRoute: Route {
    case overview
    case edit(userId: String)

    var name: String {
        switch self {
        case .overview:
            "overview"
        case .edit(let userId):
            "edit(\(userId))"
        }
    }
}
```

Map from the top-level destination:

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

> Note:
> Only the route type used by `RoutingView(destination:root:)` (for example `AppRoute`) needs to conform to `RouteDestination`.
> Child route enums (for example `ProfileRoute`) can remain plain `Route` types.

## Customizing Routing Type

By default, routes use push navigation. Override `routingType` to change this:

```swift
enum HomeRoute: Route {
    case home
    case settings
    case fullScreenModal
    
    var name: String { /* ... */ }
    
    var routingType: RoutingType {
        switch self {
        case .fullScreenModal:
            return .cover
        case .settings:
            return .sheet()
        default:
            return .push
        }
    }
}
```

### Available Routing Types

| Type | Description |
|------|-------------|
| `.push` | Standard navigation stack push (default) |
| `.sheet()` | Modal sheet presentation |
| `.sheet(withStack: false)` | Sheet without navigation stack |
| `.cover` | Full-screen cover presentation |
| `.root` | Replace the current root |

## Using Environment in Route Views

If your views need access to environment values or the router itself, create an intermediate view:

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
            HomeView(appState: appState)
        case .profile(let userId):
            ProfileView(userId: userId, router: router)
        case .settings:
            SettingsView()
        case .detail(let item):
            DetailView(item: item)
        }
    }
}
```

## Route Requirements

Routes must conform to:
- `Hashable` - For identity comparison
- `Sendable` - For thread-safety
- `CustomStringConvertible` - Provided by default via `name`

Associated values in your routes must also be `Hashable` and `Sendable`.

## Best Practices

1. **Keep routes focused**: One route enum per feature or navigation context
2. **Use meaningful names**: Include relevant IDs or identifiers in the `name`
3. **Avoid heavy objects**: Pass IDs rather than full model objects when possible
4. **Group related routes**: Use nested enums for complex navigation hierarchies
