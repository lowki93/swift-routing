# Getting Started with SwiftRouting

Learn how to set up SwiftRouting and perform your first navigation.

## Overview

This guide walks you through the essential steps to integrate SwiftRouting into your SwiftUI app. You'll learn how to define routes, map them to views, and perform navigation.

## Installation

Add SwiftRouting to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/lowki93/swift-routing.git", .upToNextMajor(from: "1.0.0"))
]
```

Then add the product to your target:

```swift
.product(name: "SwiftRouting", package: "swift-routing")
```

## Step 1: Define Your Routes

Create an enum that conforms to ``Route``. Each case represents a navigable destination in your app.

```swift
import SwiftRouting

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

The `name` property provides a human-readable identifier for logging and debugging.

## Step 2: Map Routes to Views

Extend your route enum to conform to ``RouteDestination``. This protocol defines which view should be displayed for each route.

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

## Step 3: Create a RoutingView

Replace your `NavigationStack` with ``RoutingView``. This creates a navigation stack with an associated ``Router``.

```swift
import SwiftUI
import SwiftRouting

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RoutingView(destination: HomeRoute.self, root: .home)
        }
    }
}
```

## Step 4: Navigate Between Routes

Access the router from the environment and use it to navigate:

```swift
struct HomeView: View {
    @Environment(\.router) private var router
    
    var body: some View {
        VStack {
            Text("Welcome Home")
            
            // Push navigation
            Button("View Details") {
                router.push(HomeRoute.detail(id: 42))
            }
            
            // Present as sheet
            Button("Open Settings") {
                router.present(HomeRoute.settings)
            }
        }
    }
}
```

## Navigation Methods

The ``Router`` provides several navigation methods:

| Method | Description |
|--------|-------------|
| `push(_:)` | Pushes a route onto the navigation stack |
| `present(_:)` | Presents a route as a modal sheet |
| `cover(_:)` | Presents a route as a full-screen cover |
| `back()` | Navigates back one step |
| `popToRoot()` | Returns to the root of the stack |
| `close()` | Dismisses a presented modal |

## Using NavigationLink

You can also use `NavigationLink` with your routes:

```swift
NavigationLink(route: HomeRoute.detail(id: 42)) {
    Text("View Details")
}

// Or with a string label
NavigationLink("View Details", route: HomeRoute.detail(id: 42))
```

## Next Steps

Now that you have the basics, explore these topics:

- <doc:DefiningRoutes> - Learn about route customization and routing types
- <doc:NavigationBasics> - Explore all navigation methods in detail
- <doc:TabNavigation> - Set up tab-based navigation
- <doc:Deeplinks> - Handle deep links in your app
- <doc:RouteContext> - Pass data between routes
