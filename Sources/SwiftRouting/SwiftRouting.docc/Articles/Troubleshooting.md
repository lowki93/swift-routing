# Troubleshooting

Diagnose and fix common issues encountered when using SwiftRouting.

## Overview

This article covers the most common errors and unexpected behaviors you may encounter, along with their causes and solutions.

## Route Not Found

### Symptom

A route is pushed but no view appears, or an error message is displayed:

```
Route 'DetailRoute' are not define in 'HomeRoute'
```

### Cause

SwiftRouting renders an error view when the resolved route cannot be cast to the expected ``RouteDestination`` type. This typically happens when a route from one enum is pushed into a ``RoutingView`` configured for a different destination.

### Solution

Ensure the pushed route matches the destination type of the ``RoutingView`` it targets:

```swift
// ✅ Correct — route and destination match
router.push(HomeRoute.detail(id: 42))

// ❌ Wrong — route type doesn't match the active RoutingView
router.push(SettingsRoute.profile)
```

## ErrorView Behavior

When a route cannot be resolved, an error view is rendered. Its behavior depends on ``Configuration/shouldCrashOnRouteNotFound``:

| `shouldCrashOnRouteNotFound` | Behavior |
|---|---|
| `false` (default) | Displays the error message inline as `Text` |
| `true` | Crashes the app with `fatalError` |

Use `true` during development to catch routing mismatches immediately. See <doc:ConfigurationGuide> for setup details.

## Context Not Received

If a context is sent but no observer is triggered, check:

- The observer is registered **before** the context is sent.
- The observer is registered on the **parent** router, not the child.
- The context type matches exactly on both the sender and the observer side.

```swift
// Parent — register before navigation
router.add(context: UserSelectionContext.self) { [weak self] context in
    self?.selectedUser = context.selectedUser
}

// Child — send context
router.context(UserSelectionContext(selectedUser: user))
```

## Memory Leaks with Contexts

Retain cycles occur when closures capture `self` strongly. Always use `[weak self]` when referencing class instances:

```swift
// ❌ Retain cycle
router.add(context: MyContext.self) { context in
    self.handle(context)
}

// ✅ Correct
router.add(context: MyContext.self) { [weak self] context in
    self?.handle(context)
}
```

Observers registered outside of a view lifecycle (e.g., in a ViewModel) must be removed explicitly. See <doc:RouteContextGuide> for the full memory management guide.

## Visualizing the Router Hierarchy

When it's unclear which router owns which tab/sheet/cover, or what route is active where, print the whole hierarchy to the console with `printRouter()`:

```swift
struct SomeView: View {
    var body: some View {
        content
            .printRouter()
    }
}
```

This prints the tree starting from the top-most router, for example:

```
router(app) — current: home
├─ tabRouter(hometab) — current: home
│  ├─ router(tab(home)) — current: profile(userId: "42")
│  └─ router(tab(settings)) — current: settings
└─ router(presented(sheet)) — current: onboarding
```

Use `printRouter(trigger:)` to re-print automatically whenever a value changes, for example the current route:

```swift
content.printRouter(trigger: router.currentRoute)
```

Use `printRouterOnChange()` to re-print whenever *any* router in the hierarchy logs an event (push, present, context, tab change, router creation...), without picking a specific value to watch and no matter where this modifier sits — including at the very top of the app, before any child router exists yet. This is the noisiest of the three variants, since it reprints on every logged event anywhere in the tree:

```swift
content.printRouterOnChange()
```

## Topics

### Related

- <doc:ConfigurationGuide>
- <doc:RouteContextGuide>
- ``Configuration``
- ``RouteContext``
- ``RouterModel``
