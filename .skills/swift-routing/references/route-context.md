# Route Context

Use this guide to pass data from child flows to parent flows with `RouteContext`.

## What Is RouteContext

`RouteContext` is a typealias for `Hashable & Sendable`.
Any type conforming to these constraints can be dispatched through router context APIs.

```swift
struct UserSelectionContext: RouteContext {
  let selectedUser: User
}
```

## Registering Observers

### Option A (Preferred in Views): `routerContext(...)`

```swift
struct ParentView: View {
  @State private var selectedUser: User?

  var body: some View {
    ContentView()
      .routerContext(UserSelectionContext.self) { context in
        selectedUser = context.selectedUser
      }
  }
}
```

Use this for simple view-level handling.

### Option B (ViewModel Flow): `add/remove` via `any RouterModel`

Use this when context handling belongs to presentation/business logic in a ViewModel.

```swift
@MainActor
final class ParentViewModel: ObservableObject {
  @Published var selectedUser: User?
  private let router: any RouterModel
  private var isObservingContext = false

  init(router: any RouterModel) {
    self.router = router
  }

  func startObservingContext() {
    guard !isObservingContext else { return }
    isObservingContext = true
    router.add(context: UserSelectionContext.self) { [weak self] context in
      self?.selectedUser = context.selectedUser
    }
  }

  func stopObservingContext() {
    guard isObservingContext else { return }
    isObservingContext = false
    router.remove(context: UserSelectionContext.self)
  }
}
```

Notes:
- Avoid side effects in `init` for SwiftUI-driven lifecycles.
- Trigger `startObservingContext()`/`stopObservingContext()` explicitly from the view lifecycle.

## Sending Context

### `context(_:)`

Dispatches context to matching observers without changing navigation:

```swift
router.context(UserSelectionContext(selectedUser: user))
```

### `terminate(_:)`

Dispatches context, then completes navigation based on router state:

```swift
router.terminate(UserSelectionContext(selectedUser: user))
```

Behavior:
1. Executes matching context observers
2. If a matching local context anchor is found, pops back to that point in the current stack
3. Otherwise, closes the modal if the router is presented
4. Otherwise, performs a single back navigation

## Hierarchy Behavior

`context(_:)` searches and executes observers across the router hierarchy (parents + current router).

This enables child-to-parent communication across nested stacks and modal boundaries.

## Memory Safety

Use weak captures when closures reference class instances:

```swift
router.add(context: UserSelectionContext.self) { [weak self] context in
  self?.handleSelection(context)
}
```

Use `[weak viewModel]` in view modifiers when needed:

```swift
.routerContext(UserSelectionContext.self) { [weak viewModel] context in
  viewModel?.handleSelection(context)
}
```

## Best Practices

- Prefer `.routerContext(...)` in views for straightforward UI reactions.
- Use `any RouterModel` in ViewModels for coordinator/business flows.
- Keep context types focused and explicit.
- Always remove manual observers when no longer needed.
