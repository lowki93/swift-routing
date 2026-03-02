# SwiftRouting

A lightweight, type-safe navigation framework built on top of `NavigationStack` for SwiftUI.

[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://lowki93.github.io/swift-routing/)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17+-lightgrey)](https://developer.apple.com/ios/)
[![macOS 13+](https://img.shields.io/badge/macOS-13+-lightgrey)](https://developer.apple.com/macos/)

## Why SwiftRouting?

SwiftUI's `NavigationStack` is powerful but can become hard to manage in larger apps. SwiftRouting provides a structured approach that keeps navigation logic **decoupled**, **testable**, and **scalable**.

| Benefit | Description |
|---------|-------------|
| **Type-Safe Navigation** | Routes are Swift enums with associated values — no stringly-typed paths |
| **Separation of Concerns** | Routes define *what*, views define *how* — clean architecture |
| **Bidirectional Data Flow** | Pass data back from child routes with `RouteContext` |
| **Deep Linking Ready** | Built-in support with expressive factory methods |
| **Tab Navigation** | First-class `TabRouter` for cross-tab navigation |
| **Testable** | Mock `RouterModel` protocol for unit testing navigation logic |
| **Swift 6 Ready** | Full concurrency support with `@MainActor` and `Sendable` |

## Quick Start

### 1. Define Routes

Routes are simple enums. The mapping to views is separate, keeping routes reusable across navigation, deep links, and tests.

```swift
enum AppRoute: Route {
    case home
    case profile(userId: String)
    case settings
    
    var name: String {
        switch self {
        case .home: "home"
        case .profile(let id): "profile(\(id))"
        case .settings: "settings"
        }
    }
}

extension AppRoute: RouteDestination {
    static func view(for route: AppRoute) -> some View {
        switch route {
        case .home: HomeView()
        case .profile(let userId): ProfileView(userId: userId)
        case .settings: SettingsView()
        }
    }
}
```

### 2. Create RoutingView

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RoutingView(destination: AppRoute.self, root: .home)
        }
    }
}
```

### 3. Navigate

Access the router from the environment:

```swift
struct HomeView: View {
    @Environment(\.router) private var router
    
    var body: some View {
        VStack {
            Button("View Profile") {
                router.push(AppRoute.profile(userId: "123"))
            }
            
            Button("Open Settings") {
                router.present(AppRoute.settings)
            }
        }
    }
}
```

| Method | Description |
|--------|-------------|
| `push(_:)` | Push onto the navigation stack |
| `present(_:)` | Present as a modal sheet |
| `cover(_:)` | Present as a full-screen cover |
| `back()` | Pop one level |
| `popToRoot()` | Return to root |
| `close()` | Dismiss presented modal |

## Advanced Features

### RouteContext: Bidirectional Communication

Pass data back from child routes to parents:

```swift
struct UserSelectionContext: RouteContext {
    let selectedUser: User
}

// Parent: observe the context
.routerContext(UserSelectionContext.self) { context in
    selectedUser = context.selectedUser
}

// Child: send and dismiss
router.terminate(UserSelectionContext(selectedUser: user))
```

### Deep Linking

Handle deep links with expressive factory methods:

```swift
.push(.profile(userId: "123"))
.present(.settings)
.popToRoot()
.present(.orderDetail(id: orderId), root: .dashboard, path: [.orders])
```

### Tab Navigation

`TabRouter` provides cross-tab navigation control:

```swift
@Environment(\.tabRouter) private var tabRouter

tabRouter?.push(AppRoute.profile(userId: "123"), in: .profile)
tabRouter?.popToRoot(in: .home)
```

## Installation

Add SwiftRouting via **Swift Package Manager**:

```swift
dependencies: [
    .package(url: "https://github.com/lowki93/swift-routing.git", .upToNextMajor(from: "1.0.0"))
]
```

Then add to your target:

```swift
.product(name: "SwiftRouting", package: "swift-routing")
```

## Documentation

For comprehensive documentation, tutorials, and API reference, visit the **[full documentation](https://lowki93.github.io/swift-routing/)**.

| Topic | Description |
|-------|-------------|
| [Getting Started](https://lowki93.github.io/swift-routing/documentation/swiftrouting/gettingstarted) | Installation and basic setup |
| [Defining Routes](https://lowki93.github.io/swift-routing/documentation/swiftrouting/definingroutes) | Route customization and routing types |
| [Navigation Basics](https://lowki93.github.io/swift-routing/documentation/swiftrouting/navigationbasics) | Push, present, cover, and more |
| [Tab Navigation](https://lowki93.github.io/swift-routing/documentation/swiftrouting/tabnavigation) | Tab-based navigation with `TabRouter` |
| [Deep Linking](https://lowki93.github.io/swift-routing/documentation/swiftrouting/deeplinks) | Handle deep links in your app |
| [Route Context](https://lowki93.github.io/swift-routing/documentation/swiftrouting/routecontextguide) | Pass data between routes |

## Requirements

- iOS 17.0+ / macOS 13.0+
- Swift 6.0+
- Xcode 16.0+

## License

SwiftRouting is available under the MIT license.
