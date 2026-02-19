# Navigation Basics

Learn how to navigate between routes using the Router.

## Overview

The ``Router`` is your primary interface for programmatic navigation. Every ``RoutingView`` creates its own router, accessible via the SwiftUI environment.

## Accessing the Router

Use the `@Environment` property wrapper to access the router:

```swift
struct MyView: View {
    @Environment(\.router) private var router
    
    var body: some View {
        Button("Navigate") {
            router.push(HomeRoute.detail(id: 42))
        }
    }
}
```

## Push Navigation

Push adds a route to the navigation stack with a standard slide animation:

```swift
// Push a new route
router.push(HomeRoute.detail(id: 42))

// Using NavigationLink
NavigationLink(route: HomeRoute.detail(id: 42)) {
    Text("View Details")
}
```

## Modal Presentations

### Sheet

Present a route as a modal sheet:

```swift
// With navigation stack (default)
router.present(HomeRoute.settings)

// Without navigation stack
router.present(HomeRoute.settings, withStack: false)
```

Use `withStack: false` when the presented destination needs direct sheet modifiers such as:

```swift
.presentationDetents([.medium])
.presentationDragIndicator(.visible)
```

With `withStack: true` (default), the route is wrapped in a `RoutingView`/`NavigationStack`, which can make these modifiers less predictable on the final destination view.

### Full-Screen Cover

Present a route as a full-screen cover:

```swift
router.cover(HomeRoute.onboarding)
```

## Navigating Back

### Back One Step

Remove the top route from the stack:

```swift
router.back()
```

### Pop to Root

Return to the root of the navigation stack:

```swift
router.popToRoot()
```

### Close Modal

Dismiss a presented sheet or cover:

```swift
router.close()
```

> Note: `close()` only works on routers that are presented (sheets or covers).

## Updating the Root

Replace the current root route:

```swift
router.update(root: HomeRoute.dashboard)
```

This is useful for scenarios like switching between logged-in and logged-out states.

## Using routingType

Instead of calling specific methods, you can use `route(_:)` which respects the route's `routingType`:

```swift
// This will use the route's defined routingType
router.route(HomeRoute.settings)

// Equivalent to checking routingType and calling the appropriate method
switch route.routingType {
case .push: router.push(route)
case .sheet: router.present(route)
case .cover: router.cover(route)
case .root: router.update(root: route)
}
```

For routes that require sheet presentation customizations (`presentationDetents`, `presentationDragIndicator`), prefer:

```swift
var routingType: RoutingType { .sheet(withStack: false) }
```

## Router Properties

The router provides useful properties for UI decisions:

```swift
// Check if this router is presented as a modal
if router.isPresented {
    Button("Close") { router.close() }
}

// Get the current route
let current = router.currentRoute

// Check navigation depth
if router.routeCount > 1 {
    Button("Back") { router.back() }
}
```

## Injecting Router into ViewModels

For MVVM architectures, inject the router using ``RouterModel``:

```swift
class DetailViewModel: ObservableObject {
    private let router: RouterModel
    
    init(router: RouterModel) {
        self.router = router
    }
    
    func goToSettings() {
        router.present(HomeRoute.settings)
    }
}

struct DetailView: View {
    @Environment(\.router) private var router
    @StateObject private var viewModel: DetailViewModel
    
    init() {
        // Note: Initialize in onAppear or use a factory
    }
    
    var body: some View {
        // ...
    }
}
```

## Closing Child Routers

When handling deep links or resetting navigation, close all presented modals:

```swift
router.closeChildren()
```

This dismisses any sheets or covers presented from this router.
