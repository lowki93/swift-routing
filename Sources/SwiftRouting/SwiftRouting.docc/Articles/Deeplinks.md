# Deep Linking

Learn how to handle deep links and navigate to specific routes.

## Overview

SwiftRouting provides a flexible deep linking system through ``DeeplinkHandler``, ``TabDeeplinkHandler``, ``DeeplinkRoute``, and ``TabDeeplink``.

## Creating a Deeplink Handler

Implement ``DeeplinkHandler`` to convert incoming URLs or identifiers into navigation routes:

```swift
struct AppDeeplinkHandler: DeeplinkHandler {
    typealias R = DeeplinkIdentifier  // Your input type
    typealias D = HomeRoute           // Your route type
    
    func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
        switch route {
        case .home:
            return .push(.home)
            
        case .userProfile(let userId):
            return .push(.profile(userId: userId))
            
        case .settings:
            return .present(.settings)
            
        case .reset:
            return .popToRoot()
            
        default:
            return nil
        }
    }
}
```

### Choosing the Right Factory

| Scenario | Factory |
|----------|---------|
| Navigate to a screen in the stack | `.push(_:)` |
| Show a modal sheet | `.present(_:)` |
| Show a full-screen modal | `.cover(_:)` |
| Reset navigation (logout, clear state) | `.popToRoot()` |
| Change root without clearing stack | `.updateRoot(_:)` |

## DeeplinkRoute Structure

``DeeplinkRoute`` defines how to navigate to a destination. Use factory methods for common scenarios:

```swift
// Push a route onto the navigation stack
.push(.detail(id: 1))

// Push with intermediate routes (builds navigation hierarchy)
.push(.detail(id: 1), path: [.list, .category(id: 5)])

// Push with a new root
.push(.detail(id: 1), root: .home, path: [.list])

// Present as a sheet
.present(.settings)
.present(.settings, withStack: false)  // Without navigation stack

// Present as a full-screen cover
.cover(.onboarding)

// Reset navigation without navigating to a new route
.popToRoot()
.popToRoot(root: .home)  // Reset and update root

// Update root without additional navigation
.updateRoot(.dashboard)
```

### Factory Methods

| Factory | Description |
|---------|-------------|
| `.push(_:root:path:)` | Push a route onto the navigation stack |
| `.present(_:withStack:root:path:)` | Present as a sheet |
| `.cover(_:root:path:)` | Present as a full-screen cover |
| `.popToRoot(root:)` | Reset navigation to root (no final route) |
| `.updateRoot(_:)` | Replace the root route only |

### Parameters

| Parameter | Description |
|-----------|-------------|
| `root` | Optional route to set as the new root (default: `nil`) |
| `type` | Presentation type for the final route: `.push`, `.sheet(withStack:)`, or `.cover` |
| `route` | Optional final destination route (default: `nil` for reset scenarios) |
| `path` | Array of intermediate routes to push first (default: `[]`) |

> Note: When `route` is `nil` (e.g., with `.popToRoot()`), the final navigation step is skipped. The `type` parameter is set automatically by factory methods.

## Handling Deep Links

Use the router's `handle(deeplink:)` method:

```swift
struct ContentView: View {
    var body: some View {
        RoutingView(destination: HomeRoute.self, root: .home) {
            HomeRootView()
        }
    }
}

struct HomeRootView: View {
    @Environment(\.router) private var router
    let handler = AppDeeplinkHandler()

    var body: some View {
        HomeView()
            .onOpenURL { url in
                Task {
                    guard let identifier = DeeplinkIdentifier(url: url) else { return }
                    guard let deeplink = try await handler.deeplink(from: identifier) else { return }
                    router.handle(deeplink: deeplink)
                }
            }
    }
}
```

> Note:
> The route type returned by `DeeplinkHandler` (`D`) must match the route type used by `RoutingView(destination:root:)`.

### What handle(deeplink:) Does

1. Closes all presented modals (`closeChildren()`)
2. Pops to the root (`popToRoot()`)
3. Optionally updates the root route (if `root` is set)
4. Pushes intermediate routes from `path`
5. Navigates to the final route with the specified type (only if `route` is not `nil`)

> Note: Step 5 is skipped when `route` is `nil`, making `.popToRoot()` and `.updateRoot(_:)` useful for reset scenarios without a final destination.

### Complete Example

```swift
// Deep link: reset to dashboard, build path, then push detail as sheet
.present(
    .orderDetail(id: orderId),
    root: .dashboard,
    path: [.orders, .orderList]
)
```

This will:
1. Close any presented modals
2. Pop to root
3. Set `.dashboard` as the new root
4. Push `.orders` then `.orderList` onto the stack
5. Present `.orderDetail(id:)` as a sheet

## Async Deep Link Handling

The `deeplink(from:)` method is `async`, allowing you to fetch data before navigation:

```swift
func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
    switch route {
    case .product(let productId):
        // Fetch product details before navigating
        let product = try await productService.fetch(id: productId)
        return .push(.productDetail(product))
        
    case .user(let userId):
        // Validate user exists
        guard await userService.exists(id: userId) else {
            return nil  // Return nil to ignore invalid deep links
        }
        return .push(.profile(userId: userId))
        
    default:
        return nil
    }
}
```

## Composing Deeplink Handlers (Nested Route Logic)

For larger apps, compose deep link handling by feature instead of keeping all cases in one switch.
This works well with nested route structures.

```swift
enum AppRoute: Route {
    case home
    case profile(ProfileRoute)

    var name: String {
        switch self {
        case .home: "home"
        case .profile(let child): "profile.\(child.name)"
        }
    }
}

enum ProfileRoute: Route {
    case overview
    case edit(userId: String)

    var name: String {
        switch self {
        case .overview: "overview"
        case .edit(let userId): "edit(\(userId))"
        }
    }
}
```

Create feature-level handlers:

```swift
enum ProfileDeeplinkID: Hashable, Sendable {
    case profile(userId: String)
    case editProfile(userId: String)
}

struct ProfileDeeplinkHandler: DeeplinkHandler {
    typealias R = ProfileDeeplinkID
    typealias D = AppRoute

    func deeplink(from route: ProfileDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
        switch route {
        case .profile(let userId):
            return .push(.profile(.overview), path: [.home])
        case .editProfile(let userId):
            return .push(.profile(.edit(userId: userId)))
        }
    }
}
```

Then compose at the app level:

```swift
enum AppDeeplinkID: Hashable, Sendable {
    case home
    case profile(ProfileDeeplinkID)
    case reset
}

struct AppDeeplinkHandler: DeeplinkHandler {
    typealias R = AppDeeplinkID
    typealias D = AppRoute

    private let profileHandler = ProfileDeeplinkHandler()

    func deeplink(from route: AppDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
        switch route {
        case .home:
            return .push(.home)
        case .profile(let profileID):
            return try await profileHandler.deeplink(from: profileID)
        case .reset:
            return .popToRoot()
        }
    }
}
```

Benefits:
- keeps handlers small and feature-focused
- mirrors your nested route architecture
- makes deeplink behavior easier to test

## Tab-Based Deep Links

For apps with tab navigation, implement ``TabDeeplinkHandler`` and return a ``TabDeeplink``. The `deeplink` property accepts any ``DeeplinkRoute``, including reset scenarios with `.popToRoot()`:

```swift
struct AppTabDeeplinkHandler: TabDeeplinkHandler {
    typealias R = DeeplinkIdentifier
    typealias T = HomeTab
    typealias D = HomeRoute

    func deeplink(from route: DeeplinkIdentifier) async throws -> TabDeeplink<HomeTab, HomeRoute>? {
        switch route {
        case .profile(let userId):
            return TabDeeplink(
                tab: .profile,
                deeplink: .push(.profile(userId: userId))
            )
            
        case .search(let query):
            return TabDeeplink(
                tab: .search,
                deeplink: .push(.searchResults(query: query), path: [.search])
            )
            
        case .resetHome:
            return TabDeeplink(tab: .home, deeplink: .popToRoot())
            
        default:
            return nil
        }
    }
}
```

The `handle(tabDeeplink:)` method switches to the specified tab, then delegates to `handle(deeplink:)` on that tab's router. This means all ``DeeplinkRoute`` factories work seamlessly within tabs, including `.popToRoot()` for resetting a specific tab's navigation.

Handle with TabRouter:

```swift
@Environment(\.router) private var router

func handleDeeplink(_ url: URL) async throws {
    guard let identifier = DeeplinkIdentifier(url: url) else { return }
    guard let tabDeeplink = try await handler.deeplink(from: identifier) else { return }
    router.tabRouter?.handle(tabDeeplink: tabDeeplink)
}
```

> Note:
> `tabRouter` is injected inside `RoutingTabView` descendants.
> If deeplink handling is implemented in a parent container that owns `RoutingTabView`,
> use `@Environment(\.router)` and then `router.tabRouter` to access the tab router.

## Building Navigation Paths

For complex deep links, build a path of intermediate routes:

```swift
// Deep link to: Home → Category → Subcategory → Product
.push(
    .product(id: productId),
    path: [
        .category(id: categoryId),
        .subcategory(id: subcategoryId)
    ]
)
```

This ensures the back button works correctly through the entire hierarchy.

## Resetting Navigation

Use `.popToRoot()` to reset navigation without navigating to a specific route:

```swift
// Simply reset to root
.popToRoot()

// Reset and change the root route
.popToRoot(root: .dashboard)

// Update root only (no popToRoot, no path navigation)
.updateRoot(.newHome)
```

These are useful for logout flows, session resets, or returning users to a clean state.

## Error Handling

Return `nil` from `deeplink(from:)` to ignore invalid deep links:

```swift
func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
    guard isValidRoute(route) else {
        return nil  // Silently ignore
    }
    
    // Or throw for error handling
    guard let data = try await fetchData(for: route) else {
        throw DeeplinkError.notFound
    }
    
    return .push(.detail(data))
}
```

## Topics

### Related

- <doc:DeeplinkRoute>
- ``DeeplinkHandler``
- ``TabDeeplinkHandler``
- ``DeeplinkRoute``
- ``TabDeeplink``
