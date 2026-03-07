# FAQ

Answers to common questions about SwiftRouting usage and design decisions.

## Overview

This article addresses frequently asked questions about routing patterns, API choices, and known limitations.

---

## When should I use sheet vs cover?

Both `present(_:)` and `cover(_:)` create a child router and present a modal, but they differ in appearance and dismissal behavior:

| | `present(_:)` | `cover(_:)` |
|---|---|---|
| SwiftUI modifier | `.sheet` | `.fullScreenCover` |
| Appearance | Partial screen, card style | Full screen |
| Dismiss gesture | Swipe down | Not dismissable by gesture |
| Use case | Quick actions, pickers, forms | Onboarding, auth, immersive flows |

**Use `present(_:)` when:**
- The user needs to stay aware of the context behind (e.g. selecting an item from a list)
- The flow is short and dismissable (form, picker, confirmation)

**Use `cover(_:)` when:**
- The flow takes over the full experience (onboarding, login, camera)
- You want to prevent accidental swipe-to-dismiss

Both support navigation stacks inside them via the `withStack` parameter on `present(_:)`:

```swift
// Sheet with its own NavigationStack (default)
router.present(AppRoute.form)

// Sheet without a NavigationStack (single view only)
router.present(AppRoute.form, withStack: false)

// Full-screen cover (always has its own stack)
router.cover(AppRoute.onboarding)
```

---

## How do I share a router between views?

The router is injected via the SwiftUI environment and automatically available to any view inside a ``RoutingView``:

```swift
struct MyView: View {
    @Environment(\.router) private var router

    var body: some View {
        Button("Go to detail") {
            router.push(AppRoute.detail(id: 42))
        }
    }
}
```

You don't need to pass the router manually. Any descendant view of ``RoutingView`` can read it from the environment.

**For ViewModels**, read the router from the environment in the parent and pass it at initialization:

```swift
struct ParentView: View {
    @Environment(\.router) private var router

    var body: some View {
        MyView(viewModel: MyViewModel(router: router))
    }
}

@MainActor
final class MyViewModel {
    private let router: any RouterModel

    init(router: any RouterModel) {
        self.router = router
    }
}
```

> Important: Always type the property as `any RouterModel`, not `Router`, to keep the ViewModel testable.

---

## Why use RouteContext instead of callbacks?

Callbacks (closures passed as parameters) are a common pattern for passing data back from a child view, but they come with drawbacks in a deep navigation hierarchy:

**Callbacks:**

```swift
// Every layer must forward the closure manually
router.push(AppRoute.picker(onSelect: { user in
    self.selectedUser = user
}))
```

- Couples the route to the callback signature
- Must be threaded through every intermediate view
- Hard to refactor when the hierarchy changes

**RouteContext:**

```swift
// Parent registers once
.routerContext(UserSelectionContext.self) { context in
    selectedUser = context.selectedUser
}

// Child sends when done, regardless of depth
router.terminate(UserSelectionContext(selectedUser: user))
```

- Decoupled: sender and receiver don't reference each other
- Propagates up through the entire router hierarchy automatically
- Works the same whether the child is one or five levels deep
- Enables `terminate(_:)` to handle both data passing and navigation in one call

Use callbacks for simple, same-level communication. Use ``RouteContext`` when data needs to travel up multiple levels or when the navigation flow should complete on context delivery.

---

## Known Limitations and Unsupported Cases

### Multiple simultaneous modals

SwiftRouting supports one sheet or cover at a time per router. Presenting a second modal while one is already active is not supported and will replace the current presentation.

```swift
// ❌ Unsupported — only one modal per router at a time
router.present(AppRoute.sheet1)
router.present(AppRoute.sheet2) // replaces sheet1
```

### Mixing route types across RoutingView boundaries

Each ``RoutingView`` is bound to a single ``RouteDestination`` type. You cannot push a route from one enum into a `RoutingView` configured for another.

```swift
// ❌ Wrong — SettingsRoute pushed into a HomeRoute RoutingView
router.push(SettingsRoute.profile)
```

### Back navigation with a count greater than the stack size

Calling `back()` on an empty stack or with a count exceeding the current path length has no effect. SwiftRouting does not crash in this case, but the navigation state is unchanged.

### RouteContext across router instances

`RouteContext` propagates up through the **parent router hierarchy** only. It cannot reach observers registered on a sibling router (e.g., a different tab's router).

```swift
// ❌ Context sent from Home tab will not reach an observer on Profile tab
```

Use ``TabRouter`` cross-tab navigation methods (`push(_:in:)`, `change(tab:)`) for cross-tab coordination instead.

## Topics

### Related

- ``RouterModel``
- ``RouteContext``
- ``RoutingView``
- <doc:RouteContextGuide>
- <doc:NavigationBasics>
