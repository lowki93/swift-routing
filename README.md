# SwiftRouting

A lightweight, flexible navigation framework built on top of `NavigationStack` for SwiftUI.

[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://lowki93.github.io/swift-routing/documentation/swiftrouting/)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17+-lightgrey)](https://developer.apple.com/ios/)
[![macOS 13+](https://img.shields.io/badge/macOS-13+-lightgrey)](https://developer.apple.com/macos/)

## Overview

SwiftRouting simplifies navigation in SwiftUI by introducing a decoupled routing system based on enums and deep links.

### Features

- Declarative navigation using simple `Route` enums
- Seamless integration with SwiftUI's `NavigationStack`
- Deep linking support
- Full control over tab-based navigation
- Route context for passing data between routes
- Clean separation between routes and views

## Quick Start

### 1. Define a Route

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

### 2. Map Routes to Views

```swift
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

### 3. Create a RoutingView

```swift
RoutingView(destination: HomeRoute.self, root: .home)
```

### 4. Navigate

```swift
@Environment(\.router) private var router

// Push
router.push(HomeRoute.detail(id: 42))

// Present as sheet
router.present(HomeRoute.settings)

// Present as full-screen cover
router.cover(HomeRoute.settings)
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

For comprehensive documentation, tutorials, and API reference, visit the **[full documentation](https://lowki93.github.io/swift-routing/documentation/swiftrouting/)**.

### Topics Covered

- [Getting Started](https://lowki93.github.io/swift-routing/documentation/swiftrouting/gettingstarted) - Installation and basic setup
- [Defining Routes](https://lowki93.github.io/swift-routing/documentation/swiftrouting/definingroutes) - Route customization and routing types
- [Navigation Basics](https://lowki93.github.io/swift-routing/documentation/swiftrouting/navigationbasics) - Push, present, cover, and more
- [Tab Navigation](https://lowki93.github.io/swift-routing/documentation/swiftrouting/tabnavigation) - Tab-based navigation with `TabRouter`
- [Deep Linking](https://lowki93.github.io/swift-routing/documentation/swiftrouting/deeplinks) - Handle deep links in your app
- [Route Context](https://lowki93.github.io/swift-routing/documentation/swiftrouting/routecontext) - Pass data between routes

## License

SwiftRouting is available under the MIT license.
