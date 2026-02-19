# ``SwiftRouting``

A lightweight, flexible navigation framework built on top of NavigationStack for SwiftUI.

## Overview

SwiftRouting simplifies navigation in SwiftUI by introducing a decoupled routing system based on enums and deep links. It provides a clean separation between routes and views, making your navigation logic more maintainable and testable.

### Key Features

- **Declarative Navigation**: Define routes as simple Swift enums with associated values
- **Type-Safe**: Full compile-time safety for your navigation paths
- **Deep Linking**: Built-in support for complex deep link handling
- **Tab Navigation**: First-class support for tab-based navigation with `TabRouter`
- **Presentation Modes**: Support for push, sheet, and full-screen cover presentations
- **Context Passing**: Pass data back from child routes using `RouteContext`

### Quick Example

```swift
// 1. Define your routes
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

// 2. Map routes to views
extension HomeRoute: RouteDestination {
    static func view(for route: HomeRoute) -> some View {
        switch route {
        case .home: HomeView()
        case .detail(let id): DetailView(id: id)
        case .settings: SettingsView()
        }
    }
}

// 3. Create your navigation stack
RoutingView(destination: HomeRoute.self, root: .home)

// 4. Navigate from anywhere
@Environment(\.router) var router

Button("View Details") {
    router.push(HomeRoute.detail(id: 42))
}
```

## OpenSkills

This project includes a project-level OpenSkills skill named `swift-routing` for AI-assisted guidance.

Run:

```bash
npx openskills read swift-routing
```

If needed, you can also install it globally:

```bash
openskills install lowki93/swift-routing --global
```

## Topics

### Essentials

- <doc:GettingStarted>
- ``Route``
- ``Router``
- ``RoutingView``

### Defining Routes

- <doc:DefiningRoutes>
- ``RouteDestination``
- ``RoutingType``
- ``AnyRoute``

### Navigation

- <doc:NavigationBasics>
- ``RouterModel``
- ``BaseRouterModel``

### Tab Navigation

- <doc:TabNavigation>
- ``TabRoute``
- ``TabRouter``
- ``TabRouterModel``
- ``RoutingTabView``
- ``AnyTabRoute``

### Deep Linking

- <doc:Deeplinks>
- ``DeeplinkHandler``
- ``TabDeeplinkHandler``
- ``DeeplinkRoute``
- ``TabDeeplink``

### Route Context

- <doc:RouteContextGuide>

### Configuration

- ``Configuration``
- ``LoggerMessage``
