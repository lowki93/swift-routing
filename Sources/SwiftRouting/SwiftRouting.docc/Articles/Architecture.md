# Architecture

Understand the design principles and structure behind SwiftRouting.

## Overview

SwiftRouting is built around a few core principles: **separation of concerns**, **type safety**, and **testability**. This guide explains how these principles shape the framework's architecture.

## Design Principles

### Routes Are Data, Not Views

In SwiftRouting, routes are simple Swift enums that describe *what* destination to navigate to, not *how* to display it:

```swift
enum AppRoute: Route {
    case home
    case profile(userId: String)
    case settings
}
```

The view mapping is handled separately through `RouteDestination`:

```swift
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

**Why this separation?**

| Benefit | Explanation |
|---------|-------------|
| **Reusability** | Routes can be used in navigation, deep links, analytics, and tests without view dependencies |
| **Testability** | Test navigation logic by asserting on route values, not view hierarchies |
| **Flexibility** | Change view implementations without touching route definitions |
| **Modularity** | Routes can live in a shared module; views in feature modules |

### Protocol-Based Router

The ``Router`` class implements the ``RouterModel`` protocol, which defines all navigation operations:

```swift
public protocol RouterModel {
    func push(_ route: some Route)
    func present(_ route: some Route, withStack: Bool)
    func cover(_ route: some Route)
    func back()
    func popToRoot()
    func close()
    // ...
}
```

This protocol-based design enables:

- **Dependency injection** in ViewModels
- **Mocking** for unit tests
- **Abstraction** over concrete router implementations

### Hierarchical Router Structure

SwiftRouting creates a hierarchy of routers that mirrors your navigation structure:

```
App
└── TabRouter (manages tab selection)
    ├── Router [Home Tab]
    │   └── Router [Presented Sheet]
    ├── Router [Search Tab]
    └── Router [Profile Tab]
```

Each ``RoutingView`` creates its own ``Router``. When you present a sheet or cover, a new child router is created. This hierarchy enables:

- **Scoped navigation**: Each router manages its own stack
- **Context propagation**: `RouteContext` flows up through the hierarchy
- **Coordinated dismissal**: `closeChildren()` dismisses all descendants

## Component Relationships

### RoutingView

``RoutingView`` is the entry point that creates a `NavigationStack` with an associated ``Router``:

```swift
RoutingView(destination: AppRoute.self, root: .home)
```

It:
1. Creates a ``Router`` instance
2. Injects it into the environment via `@Environment(\.router)`
3. Registers the `RouteDestination` for navigation
4. Manages sheet and cover presentations

### Router

The ``Router`` manages:

- **Navigation path**: The stack of pushed routes
- **Root route**: The initial route displayed
- **Presentations**: Sheet and cover modals
- **Context observers**: Registered `RouteContext` handlers
- **Child routers**: Routers created by presented modals

### TabRouter

``TabRouter`` coordinates navigation across tabs:

- Manages the selected tab
- Provides access to each tab's ``Router``
- Enables cross-tab navigation (`push(_:in:)`, `popToRoot(in:)`)
- Handles tab-aware deep links

## Data Flow

### Navigation Flow

```
User Action → Router Method → State Update → SwiftUI Renders
     │              │              │
     │              │              └── @Published properties trigger view updates
     │              └── push(), present(), back(), etc.
     └── Button tap, deep link, programmatic call
```

### Context Flow

`RouteContext` flows upward through the router hierarchy:

```
Child Router                    Parent Router
     │                               │
     │ router.terminate(context) ────▶│ .routerContext handler executes
     │                               │
     │◀──── Navigation completes ────│
```

### Deep Link Flow

```
URL/Identifier → DeeplinkHandler → DeeplinkRoute → Router.handle(deeplink:)
                      │                  │                   │
                      │                  │                   └── Executes navigation sequence
                      │                  └── Factory creates navigation instructions
                      └── Async conversion with optional data fetching
```

## Memory Management

### Router Lifecycle

Routers are retained by their parent `RoutingView`. When a view is dismissed:

1. The router is deallocated
2. Context observers are automatically cleaned up
3. Child routers are released

### Context Cleanup

Context observers registered on a route are automatically removed when that route is popped from the stack. This prevents memory leaks and stale callbacks.

```swift
// Observer registered on .list route
router.push(.list)
router.add(context: SelectionContext.self) { ... }

// When .list is popped, the observer is automatically removed
router.back()
```

## Best Practices

### Keep Routes Focused

One route enum per feature or navigation context:

```swift
// Good: Focused route enums
enum HomeRoute: Route { ... }
enum ProfileRoute: Route { ... }
enum SettingsRoute: Route { ... }

// Avoid: One massive enum for everything
enum AppRoute: Route {
    case home, homeDetail, homeSettings, profile, profileEdit, ...
}
```

### Use Nested Routes for Complex Hierarchies

```swift
enum AppRoute: Route {
    case home
    case profile(ProfileRoute)
    case settings(SettingsRoute)
}
```

### Inject RouterModel, Not Router

In ViewModels, depend on the protocol for testability:

```swift
class MyViewModel {
    private let router: any RouterModel
    
    init(router: any RouterModel) {
        self.router = router
    }
}
```

### Prefer terminate() Over Manual Navigation

When completing a flow with context, use `terminate()` instead of manual `back()` or `close()`:

```swift
// Good: Let the framework handle navigation
router.terminate(SelectionContext(item: selectedItem))

// Avoid: Manual navigation after context
router.context(SelectionContext(item: selectedItem))
router.back() // or router.close()
```

## Topics

### Related

- ``Router``
- ``RouterModel``
- ``TabRouter``
- ``RoutingView``
