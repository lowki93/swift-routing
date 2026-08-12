# SwiftRouting

A lightweight, type-safe navigation framework built on top of `NavigationStack` for SwiftUI.

[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://lowki93.github.io/swift-routing/)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17+-lightgrey)](https://developer.apple.com/ios/)
[![macOS 14+](https://img.shields.io/badge/macOS-14+-lightgrey)](https://developer.apple.com/macos/)
[![skills.sh](https://skills.sh/b/lowki93/swift-routing)](https://skills.sh/lowki93/swift-routing)

## Why SwiftRouting?

SwiftUI's `NavigationStack` is powerful but can become hard to manage in larger apps. SwiftRouting provides a structured approach that keeps navigation logic **decoupled**, **testable**, and **scalable**.

| Benefit | Description |
|---------|-------------|
| **Type-Safe Navigation** | Routes are Swift enums with associated values — no stringly-typed paths |
| **Separation of Concerns** | Routes define *what*, views define *how* — clean architecture |
| **Bidirectional Data Flow** | Pass data back from child routes with `RouteContext` |
| **Deep Linking Ready** | Built-in support with expressive factory methods |
| **Tab Navigation** | First-class `TabRouter` for cross-tab navigation |
| **Split Navigation** | `RoutingSplitView` for sidebar/content/detail layouts on iPad and macOS |
| **Testable** | `RouterSpy`/`TabRouterSpy` test doubles ship in `SwiftRoutingTestSupport` — no hand-rolled mocks |
| **Debuggable** | Print the live router tree with `printRouterOnChange()`/`printRouter(trigger:)` — see what's mounted, active, and observing at a glance |
| **Swift 6 Ready** | Full concurrency support with `@MainActor` and `Sendable` |

### Why Separate Routes From Views?

Routes are plain data (`Hashable & Sendable`); the mapping to views lives separately in `RouteDestination`. This is a deliberate trade-off, not an accident:

| Benefit | Explanation |
|---------|-------------|
| **Reusability** | Routes can be used in navigation, deep links, analytics, and tests without view dependencies |
| **Testability** | Test navigation logic by asserting on route values, not view hierarchies |
| **Flexibility** | Change view implementations without touching route definitions |
| **Modularity** | Routes can live in a shared module; views in feature modules |

See the [Architecture guide](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/architecture) for the full rationale.

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

### Split Navigation

`RoutingSplitView` wraps `NavigationSplitView` with typed, route-driven column selection:

```swift
RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
    AppRoute.players(type)
} detail: { (player: Player) in
    AppRoute.player(player)
}
```

```swift
@Environment(\.router) private var router

List(players, selection: router.detailBinding(as: Player.self)) { player in
    NavigationLink(player.name, value: player)
}
```

## Installation

Add SwiftRouting via **Swift Package Manager**:

```swift
dependencies: [
    .package(url: "https://github.com/lowki93/swift-routing.git", .upToNextMajor(from: "0.7.0"))
]
```

Then add to your target:

```swift
.product(name: "SwiftRouting", package: "swift-routing")
```

For test doubles (`RouterSpy`, `TabRouterSpy`), add `SwiftRoutingTestSupport` to your test target:

```swift
.product(name: "SwiftRoutingTestSupport", package: "swift-routing")
```

## Documentation

For comprehensive documentation, tutorials, and API reference, visit the **[full documentation](https://lowki93.github.io/swift-routing/)**.

| Topic | Description |
|-------|-------------|
| [Getting Started](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/gettingstarted) | Installation and basic setup |
| [Architecture](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/architecture) | Design principles — why routes are separate from views |
| [Defining Routes](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/definingroutes) | Route customization and routing types |
| [Navigation Basics](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/navigationbasics) | Push, present, cover, and more |
| [Tab Navigation](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/tabnavigation) | Tab-based navigation with `TabRouter` |
| [Split Navigation](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/splitnavigation) | Sidebar/content/detail layouts with `RoutingSplitView` |
| [Deep Linking](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/deeplinks) | Handle deep links in your app |
| [Route Context](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/routecontextguide) | Pass data between routes |
| [Migration](https://lowki93.github.io/swift-routing/0.7.0/documentation/swiftrouting/migration) | Migrate from native NavigationStack |

## Articles

- [Stop Fighting SwiftUI Navigation — A Type-Safe Approach with Swift Routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270)

## AI Skills

This project includes AI skills for assisted development, discoverable and installable via [skills.sh](https://skills.sh/lowki93/swift-routing).

| Skill | Description |
|-------|-------------|
| `swift-routing` | Guidance for routes, routers, tabs, deeplinks, and troubleshooting |
| `swift-routing-migration` | Step-by-step migration from native NavigationStack to SwiftRouting |

```bash
npx skills add lowki93/swift-routing --skill swift-routing
npx skills add lowki93/swift-routing --skill swift-routing-migration
```

### Contributor Setup

Cloning or forking this repo gets you the two skills above for free — they're committed under `.skills/`. `AGENTS.md` also references three global (machine-level, not repo-level) skills used for tests, concurrency, and DocC work. Install them once per machine:

```bash
npx skills add avdlee/swift-testing-agent-skill --skill swift-testing-expert -g
npx skills add avdlee/swift-concurrency-agent-skill --skill swift-concurrency -g
npx skills add nonameplum/agent-skills --skill swift-docc -g
```

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 6.0+
- Xcode 16.0+

## License

SwiftRouting is available under the MIT license.
