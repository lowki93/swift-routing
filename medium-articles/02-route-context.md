# Two-Way Navigation in SwiftUI: The RouteContext Pattern

*Part 2 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](#).*

---

Navigation in SwiftUI is a one-way street by default. You push a screen, it does something, and then... you have no clean way to get the result back.

The usual workarounds — shared state, closures passed as parameters, `@Binding` threaded down the stack — work for simple cases. But they break down fast. Closures couple screens together. Shared state is hard to reason about. `@Binding` leaks presentation concerns into your view hierarchy.

swift-routing solves this with `RouteContext`: a typed, structured way for child routes to send data back to any parent in the hierarchy.

---

## The Problem: Getting Data Back from a Screen

Here's a common scenario. You have a list of users. You present a picker screen. The user selects someone. You need that selection back in the parent.

The naive approach:

```swift
// ParentView.swift
struct ParentView: View {
    @State private var selectedUser: User?
    @State private var showingPicker = false

    var body: some View {
        Button("Pick user") { showingPicker = true }
            .sheet(isPresented: $showingPicker) {
                UserPickerView(onSelect: { user in
                    selectedUser = user
                    showingPicker = false
                })
            }
    }
}

// UserPickerView.swift
struct UserPickerView: View {
    let onSelect: (User) -> Void
    // ...
}
```

This works. But `UserPickerView` now requires a closure to be injected by whoever presents it. If the picker sits three levels deep in the stack, every intermediate screen has to forward that closure down — screens that have nothing to do with the selection. And in tests, verifying the result means triggering the callback manually instead of asserting on a plain value.

---

## RouteContext: Data as a First-Class Value

`RouteContext` inverts the flow. With closures, the parent says: *"here's what to call when you're done"* — and the child has to accept it. With `RouteContext`, the parent says: *"I'm listening for this type of value"* — and the child just fires it, without knowing who's listening.

Define your context type — any `Hashable & Sendable` struct works:

```swift
struct UserSelectionContext: RouteContext {
    let user: User
}
```

In the parent, register an observer before navigating:

```swift
struct ParentView: View {
    @Environment(\.router) private var router
    @State private var selectedUser: User?

    var body: some View {
        Button("Pick user") {
            router.add(context: UserSelectionContext.self) { [weak self] context in
                self?.selectedUser = context.user  // ← capture weakly
            }
            router.present(AppRoute.userPicker)
        }
    }
}
```

In the child, fire the context when done:

```swift
struct UserPickerView: View {
    @Environment(\.router) private var router

    var body: some View {
        List(users) { user in
            Button(user.name) {
                router.terminate(UserSelectionContext(user: user))
            }
        }
    }
}
```

`terminate` does two things: it executes the context (notifying all registered observers), then navigates back — popping the screen or dismissing the sheet, whichever applies.

`UserPickerView` knows nothing about its parent. No closure. No binding. No shared state.

---

## context vs. terminate

Two methods fire a `RouteContext`. They differ in what happens after:

| Method | Fires context | Navigates back |
|--------|--------------|---------------|
| `router.context(_:)` | Yes | No |
| `router.terminate(_:)` | Yes | Yes |

Use `context` when you want to notify the parent without ending the flow — for example, updating a live preview as the user types. Use `terminate` when the flow is complete and the screen should close.

```swift
// Live update — user is still on the screen
router.context(PreviewContext(text: currentText))

// Flow complete — close and return the result
router.terminate(UserSelectionContext(user: selectedUser))
```

---

## How terminate Navigates Back

`terminate` is smarter than a simple `back()` or `close()`. It looks up the router hierarchy for the observer that registered the context, then navigates back to exactly that level.

This means it works correctly across deeply nested navigation:

```
HomeView → CategoryView → SubcategoryView → UserPickerView
  ↑ registered observer here
```

Calling `router.terminate(UserSelectionContext(...))` from `UserPickerView` pops all the way back to `HomeView` in one call — not just one level. The intermediate screens are cleared automatically.

If no registered observer is found in the stack, `terminate` falls back gracefully: it dismisses the modal if presented, or pops one level otherwise.

---

## Observers Propagate Up the Hierarchy

`context` and `terminate` don't just notify the immediate parent — they walk the entire router hierarchy upward, notifying every ancestor that has registered an observer for that context type.

This is useful when multiple parts of your app need to react to the same event. A profile update deep in a sheet can propagate back to a tab bar badge count, a list refresh, and a parent view model — all with a single call.

```swift
// In TabView root — reacts to profile updates anywhere
router.add(context: ProfileUpdatedContext.self) { [weak self] context in
    self?.refreshBadge()
}

// Deep inside a nested sheet
router.terminate(ProfileUpdatedContext(user: updatedUser))
// → notifies TabView root, any intermediate observers, and closes the sheet
```

---

## Observers Clean Up Automatically

You don't need to manually remove observers in most cases. When a route is popped from the navigation stack, its associated observers are removed automatically.

If you need to remove an observer explicitly — for example, if you want to stop listening mid-flow — use `remove(context:)`:

```swift
router.remove(context: UserSelectionContext.self)
```

This only removes observers registered at the current route. Observers registered at parent routes are not affected.

---

## Before and After

Here's what a "pick a user and return it" flow looks like before and after.

**Before — closure threading:**

```swift
// ParentView.swift
struct ParentView: View {
    @State private var selectedUser: User?

    var body: some View {
        Button("Pick") {
            // Must pass closure into navigation
        }
        .sheet(isPresented: ...) {
            UserPickerView { user in   // ← tightly coupled
                selectedUser = user
            }
        }
    }
}

// UserPickerView.swift
struct UserPickerView: View {
    let onSelect: (User) -> Void   // ← must know about parent
    // ...
}
```

**After — RouteContext:**

```swift
// ParentView.swift
struct ParentView: View {
    @Environment(\.router) private var router
    @State private var selectedUser: User?

    var body: some View {
        Button("Pick") {
            router.add(context: UserSelectionContext.self) { [weak self] context in
                self?.selectedUser = context.user
            }
            router.present(AppRoute.userPicker)
        }
    }
}

// UserPickerView.swift
struct UserPickerView: View {
    @Environment(\.router) private var router   // ← no parent knowledge needed

    var body: some View {
        List(users) { user in
            Button(user.name) {
                router.terminate(UserSelectionContext(user: user))
            }
        }
    }
}
```

`UserPickerView` is now completely self-contained. It can be presented from anywhere in the app, and any caller can choose how to handle the result.

---

## Testing Navigation Flows

Because `RouteContext` values are plain Swift types, testing a navigation flow doesn't require UI. You can verify the full round-trip at the unit level:

```swift
@Test
func userSelected_terminate_notifiesParentAndNavigatesBack() {
    let router = Router(configuration: .default)
    var received: UserSelectionContext?

    router.add(context: UserSelectionContext.self) { context in
        received = context
    }

    router.push(AppRoute.userPicker)
    router.terminate(UserSelectionContext(user: .fixture))

    #expect(received?.user == .fixture)
    #expect(router.routeCount == 1)  // back to root
}
```

No views. No `@State`. No async dance. Just a router, an observer, and a value.

---

## "But What About Shared State?"

Fair question. A shared `@Observable` model — injected via the environment — is a perfectly valid way to communicate between screens. In simple flows, it's the right choice.

The problem appears when the communication is transient. A user picker doesn't belong in your app's global state. It runs, returns a value, and disappears. Injecting an `@Observable` for that means creating something that exists only to be discarded, and whose lifetime you have to manage manually.

`RouteContext` makes the scope explicit: an observer is registered before navigating and removed when the route is popped. The value flows up, the screen closes, and there's nothing left to clean up. It's not a replacement for shared state — it's the right tool when shared state is too much.

---

## What's Next

`RouteContext` handles data flowing back up. The next piece is getting into your app from the outside: deep linking — rebuilding a navigation stack from a URL or push notification payload.

*Next: [Deep Linking in SwiftUI with swift-routing](#)*
