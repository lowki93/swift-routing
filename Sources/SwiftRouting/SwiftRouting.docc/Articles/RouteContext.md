# Route Context

Learn how to pass data between routes using RouteContext.

## Overview

``RouteContext`` enables communication from child routes back to parent routes. Use it to pass selection results, form data, or completion signals up the navigation hierarchy.

## What is RouteContext?

A `RouteContext` is any type conforming to `Hashable & Sendable`. It acts as a message that can be sent from a child route and received by any ancestor route that registered an observer.

```swift
struct UserSelectionContext: RouteContext {
    let selectedUser: User
}

struct FormCompletionContext: RouteContext {
    let formData: FormData
    let success: Bool
}
```

## Registering Context Observers

### Using the View Modifier

The simplest way to observe contexts is with the `routerContext` modifier:

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

### Using Router Directly

For ViewModel-driven architectures, register observers via `any RouterModel`:

```swift
struct ParentView: View {
    @Environment(\.router) private var router
    @State private var viewModel: ParentViewModel?
    
    var body: some View {
        ContentView(viewModel: viewModel)
            .onAppear {
                guard viewModel == nil else { return }
                let vm = ParentViewModel(router: router)
                vm.startObservingContext()
                viewModel = vm
            }
            .onDisappear {
                viewModel?.stopObservingContext()
            }
    }
}

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

    deinit {
        stopObservingContext()
    }
}
```

> Note: In views, prefer `.routerContext(...)` for simple cases.
> Use `any RouterModel` in ViewModels when context handling belongs to presentation/business logic.
>
> Warning: Use weak captures for class references (for example view models) to prevent retain cycles.

## Sending Context

From a child route, send context using `context(_:)` or `terminate(_:)`:

### context(_:) - Send Without Navigation

Sends the context to all observers without affecting navigation:

```swift
struct UserPickerView: View {
    @Environment(\.router) private var router
    let users: [User]
    
    var body: some View {
        List(users) { user in
            Button(user.name) {
                // Send context but stay on this screen
                router.context(UserSelectionContext(selectedUser: user))
            }
        }
    }
}
```

### terminate(_:) - Send and Complete Navigation

Sends the context, then completes navigation based on router state:

```swift
struct UserPickerView: View {
    @Environment(\.router) private var router
    let users: [User]
    
    var body: some View {
        List(users) { user in
            Button(user.name) {
                // Send context and complete the current flow
                router.terminate(UserSelectionContext(selectedUser: user))
            }
        }
    }
}
```

`terminate(_:)` will:
1. Execute all matching context observers
2. If a matching local context anchor is found, pop back to that point in the current stack
3. Otherwise, close the modal if the router is presented
4. Otherwise, go back one step

## Context Hierarchy

Contexts propagate up through the entire router hierarchy:

```
App Router
    └── Tab Router
            └── Home Router (observer registered here)
                    └── List Router
                            └── Detail Router (context sent from here)
```

When context is sent from Detail Router, it reaches the observer in Home Router.

## Removing Observers

Observers are automatically removed when their route is popped. You can also remove them manually:

```swift
router.remove(context: UserSelectionContext.self)
```

## Common Patterns

### Selection Flow

```swift
// Parent: Start selection
router.push(HomeRoute.userPicker)

// Parent: Receive selection
.routerContext(UserSelectionContext.self) { context in
    selectedUser = context.selectedUser
}

// Child: Complete selection
router.terminate(UserSelectionContext(selectedUser: user))
```

### Form Completion

```swift
// Parent
.routerContext(FormCompletionContext.self) { context in
    if context.success {
        showSuccessMessage()
    }
}

// Child (form view)
func submitForm() async {
    let success = await api.submit(formData)
    router.terminate(FormCompletionContext(formData: formData, success: success))
}
```

### Multi-Step Wizard

```swift
struct WizardContext: RouteContext {
    let step: Int
    let data: WizardData
}

// Each step sends progress
router.context(WizardContext(step: currentStep, data: collectedData))

// Final step terminates
router.terminate(WizardContext(step: finalStep, data: completeData))
```

## Memory Management

Context closures can cause retain cycles. Always use weak references:

```swift
// ✅ Correct
router.add(context: MyContext.self) { [weak self] context in
    self?.handleContext(context)
}

// ✅ Correct with view model
.routerContext(MyContext.self) { [weak viewModel] context in
    viewModel?.process(context)
}

// ❌ Wrong for class references - causes retain cycle
router.add(context: MyContext.self) { context in
    self.handleContext(context)  // Strong reference to self
}
```
