# Troubleshooting

Diagnose and fix common issues encountered when using SwiftRouting.

## Overview

This article covers the most common errors and unexpected behaviors you may encounter, along with their causes and solutions.

## Route Not Found

### Symptom

A route is pushed but no view appears, or the app shows a message like:

```
Route 'DetailRoute' are not define in 'HomeRoute'
```

### Cause

This happens when a route type doesn't match the expected ``RouteDestination``. The ``ErrorView`` is displayed when the resolved route cannot be cast to the destination's associated type.

The error message comes directly from `ErrorView`:

```swift
"Route '\(type(of: route.wrapped))' are not define in '\(String(describing: destination.self))'"
```

### Solution

Ensure the pushed route belongs to the correct destination type. Each ``RoutingView`` expects routes of a specific type — mixing route types from different enums is not supported.

```swift
// ✅ Correct — route and destination match
router.push(HomeRoute.detail(id: 42))

// ❌ Wrong — pushing a route from a different enum
router.push(SettingsRoute.profile) // into a HomeRoute RoutingView
```

---

## ErrorView Behavior

``ErrorView`` is an internal view rendered when SwiftRouting cannot resolve a route to a valid destination view.

Its behavior depends on ``Configuration/shouldCrashOnRouteNotFound``:

| `shouldCrashOnRouteNotFound` | Behavior |
|---|---|
| `false` (default) | Displays an error message inline: `Text(message).padding()` |
| `true` | Calls `fatalError(message)`, crashing the app immediately |

Use `true` in debug builds to surface routing mismatches early:

```swift
#if DEBUG
let config = Configuration(shouldCrashOnRouteNotFound: true)
#else
let config = Configuration(shouldCrashOnRouteNotFound: false)
#endif

RoutingView(destination: AppRoute.self, root: .home)
    .environment(\.router, Router(configuration: config))
```

---

## Configuration: shouldCrashOnRouteNotFound

### Purpose

`shouldCrashOnRouteNotFound` controls what happens when a route cannot be matched to a destination view.

- `false` — fails silently with an inline error message. Safe for production.
- `true` — crashes the app via `fatalError`. Useful in development to catch routing mismatches at the source.

### Recommendation

Use environment-based configuration to distinguish between debug and release behavior:

```swift
extension Configuration {
    static var app: Configuration {
        #if DEBUG
        Configuration(shouldCrashOnRouteNotFound: true)
        #else
        Configuration(shouldCrashOnRouteNotFound: false)
        #endif
    }
}
```

### Default Value

``Configuration/default`` sets `shouldCrashOnRouteNotFound` to `false`.

---

## Memory Issues with Contexts

### Retain Cycles in Context Closures

When registering a context observer directly via `router.add(context:perform:)`, capturing `self` strongly creates a retain cycle that prevents deallocation.

```swift
// ❌ Retain cycle — self is captured strongly
router.add(context: MyContext.self) { context in
    self.handleContext(context)
}

// ✅ Correct — use weak capture
router.add(context: MyContext.self) { [weak self] context in
    self?.handleContext(context)
}
```

The same applies when using the `routerContext` modifier with a ViewModel:

```swift
// ✅ Correct
.routerContext(MyContext.self) { [weak viewModel] context in
    viewModel?.process(context)
}
```

### Observers Not Removed

Observers registered with `router.add(context:perform:)` are automatically removed when the associated route is popped from the navigation stack. However, if you register observers outside of a view lifecycle (e.g., in a ViewModel), remove them explicitly:

```swift
@MainActor
final class MyViewModel: ObservableObject {
    private let router: any RouterModel

    func startObserving() {
        router.add(context: MyContext.self) { [weak self] context in
            self?.handleContext(context)
        }
    }

    deinit {
        router.remove(context: MyContext.self)
    }
}
```

### Context Not Received

If a context is sent but no observer is triggered, check the following:

- The observer is registered **before** the context is sent.
- The observer is registered on the correct router (the parent, not the child).
- The context type matches exactly — `MyContext.self` must be the same type on both sides.

```swift
// Sender (child route)
router.context(UserSelectionContext(selectedUser: user))

// Observer (parent route) — must be registered before the above runs
router.add(context: UserSelectionContext.self) { context in
    // ...
}
```

---

## Topics

### Related

- ``Configuration``
- ``RouteContext``
- ``RouterModel``
