# DeeplinkRoute

Define navigation instructions for deep links using factory methods.

## Overview

``DeeplinkRoute`` encapsulates the navigation instructions for a deep link: where to go, how to present it, and optionally what intermediate routes to build along the way. Rather than constructing instances directly, use the provided factory methods for cleaner, more expressive code.

## Factory Methods

SwiftRouting provides five factory methods covering common navigation patterns:

| Factory | Description |
|---------|-------------|
| `.push(_:root:path:)` | Push a route onto the navigation stack |
| `.present(_:withStack:root:path:)` | Present a route as a sheet |
| `.cover(_:root:path:)` | Present a route as a full-screen cover |
| `.popToRoot(root:)` | Reset navigation without a final destination |
| `.updateRoot(_:)` | Replace the root route only |

### Push

Push a route onto the navigation stack:

```swift
// Simple push
.push(.detail(id: 1))

// Push with intermediate routes
.push(.detail(id: 1), path: [.list, .category(id: 5)])

// Push with a new root and path
.push(.detail(id: 1), root: .home, path: [.list])
```

### Present

Present a route as a modal sheet:

```swift
// Present with navigation stack (default)
.present(.settings)

// Present without navigation stack
.present(.settings, withStack: false)

// Present with root override
.present(.checkout, root: .cart)
```

### Cover

Present a route as a full-screen cover:

```swift
.cover(.onboarding)
.cover(.fullScreenPlayer, root: .media)
```

### Pop to Root

Reset navigation to the root without navigating to a specific route. Useful for logout flows, session resets, or returning users to a clean state:

```swift
// Simply reset
.popToRoot()

// Reset and change the root
.popToRoot(root: .dashboard)
```

### Update Root

Replace the root route without clearing the navigation stack or presenting anything:

```swift
.updateRoot(.newHome)
```

## Parameters

All factory methods share common optional parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `root` | Route to set as the new root before navigation | `nil` |
| `path` | Array of intermediate routes to push | `[]` |

The `route` parameter (the final destination) is required for `.push`, `.present`, and `.cover`, but absent for `.popToRoot` and `.updateRoot`.

## Complete Example

Here's a deep link that resets to a dashboard, builds a navigation hierarchy, then presents a detail view:

```swift
.present(
    .orderDetail(id: orderId),
    root: .dashboard,
    path: [.orders, .orderList]
)
```

When handled by the router, this will:
1. Close any presented modals
2. Pop to root
3. Set `.dashboard` as the new root
4. Push `.orders` then `.orderList` onto the stack
5. Present `.orderDetail(id:)` as a sheet

## Reset Scenarios

For scenarios where you need to reset navigation without a final destination:

```swift
// Logout: clear everything and go to login root
.popToRoot(root: .login)

// Switch context: update root to a different section
.updateRoot(.settings)

// Simple reset: just clear the stack
.popToRoot()
```

## Usage in Handlers

Use these factories in your ``DeeplinkHandler`` implementations:

```swift
struct AppDeeplinkHandler: DeeplinkHandler {
    func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<AppRoute>? {
        switch route {
        case .home:
            return .push(.home)
        case .settings:
            return .present(.settings)
        case .logout:
            return .popToRoot(root: .login)
        default:
            return nil
        }
    }
}
```

## Topics

### Related

- ``DeeplinkHandler``
- ``TabDeeplink``
