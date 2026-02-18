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
            .routerContext(UserSelectionContext.self) { [weak self] context in
                self?.selectedUser = context.selectedUser
            }
    }
}
```

### Using Router Directly

You can also register observers directly on the router:

```swift
struct ParentView: View {
    @Environment(\.router) private var router
    @State private var selectedUser: User?
    
    var body: some View {
        ContentView()
            .onAppear {
                router.add(context: UserSelectionContext.self) { [weak self] context in
                    self?.selectedUser = context.selectedUser
                }
            }
    }
}
```

> Warning: Always capture `self` or view models with `[weak self]` to prevent memory leaks.

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

### terminate(_:) - Send and Navigate Back

Sends the context and navigates back to the observer's route:

```swift
struct UserPickerView: View {
    @Environment(\.router) private var router
    let users: [User]
    
    var body: some View {
        List(users) { user in
            Button(user.name) {
                // Send context AND navigate back
                router.terminate(UserSelectionContext(selectedUser: user))
            }
        }
    }
}
```

`terminate(_:)` will:
1. Execute all matching context observers
2. Pop routes back to where the context was registered
3. Or close the modal if presented
4. Or go back one step if no matching context is found

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

// ❌ Wrong - causes retain cycle
router.add(context: MyContext.self) { context in
    self.handleContext(context)  // Strong reference to self
}
```
