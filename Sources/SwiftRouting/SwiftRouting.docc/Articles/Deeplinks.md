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
            return DeeplinkRoute(type: .push, route: .home)
            
        case .userProfile(let userId):
            return DeeplinkRoute(type: .push, route: .profile(userId: userId))
            
        case .settings:
            return DeeplinkRoute(type: .sheet(), route: .settings)
            
        default:
            return nil
        }
    }
}
```

## DeeplinkRoute Structure

``DeeplinkRoute`` defines how to navigate to a destination:

```swift
DeeplinkRoute(
    root: .home,           // Optional: Override the root route
    type: .push,           // How to present the final route
    route: .detail(id: 1), // The destination route
    path: [.list, .category(id: 5)]  // Optional: Intermediate routes
)
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| `root` | Optional route to set as the new root |
| `type` | Presentation type (push, sheet, cover) |
| `route` | The final destination route |
| `path` | Array of intermediate routes to push first |

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
3. Optionally updates the root route
4. Pushes intermediate routes from `path`
5. Navigates to the final route with the specified type

## Async Deep Link Handling

The `deeplink(from:)` method is `async`, allowing you to fetch data before navigation:

```swift
func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
    switch route {
    case .product(let productId):
        // Fetch product details before navigating
        let product = try await productService.fetch(id: productId)
        return DeeplinkRoute(type: .push, route: .productDetail(product))
        
    case .user(let userId):
        // Validate user exists
        guard await userService.exists(id: userId) else {
            return nil  // Return nil to ignore invalid deep links
        }
        return DeeplinkRoute(type: .push, route: .profile(userId: userId))
        
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
            return DeeplinkRoute(type: .push, route: .profile(.overview), path: [.home])
        case .editProfile(let userId):
            return DeeplinkRoute(type: .push, route: .profile(.edit(userId: userId)))
        }
    }
}
```

Then compose at the app level:

```swift
enum AppDeeplinkID: Hashable, Sendable {
    case home
    case profile(ProfileDeeplinkID)
}

struct AppDeeplinkHandler: DeeplinkHandler {
    typealias R = AppDeeplinkID
    typealias D = AppRoute

    private let profileHandler = ProfileDeeplinkHandler()

    func deeplink(from route: AppDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
        switch route {
        case .home:
            return DeeplinkRoute(type: .push, route: .home)
        case .profile(let profileID):
            return try await profileHandler.deeplink(from: profileID)
        }
    }
}
```

Benefits:
- keeps handlers small and feature-focused
- mirrors your nested route architecture
- makes deeplink behavior easier to test

## Tab-Based Deep Links

For apps with tab navigation, implement ``TabDeeplinkHandler`` and return a ``TabDeeplink``:

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
                deeplink: DeeplinkRoute(type: .push, route: .profile(userId: userId))
            )
            
        case .search(let query):
            return TabDeeplink(
                tab: .search,
                deeplink: DeeplinkRoute(
                    type: .push,
                    route: .searchResults(query: query),
                    path: [.search]  // Show search screen first
                )
            )
            
        default:
            return nil
        }
    }
}
```

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
DeeplinkRoute(
    type: .push,
    route: .product(id: productId),
    path: [
        .category(id: categoryId),
        .subcategory(id: subcategoryId)
    ]
)
```

This ensures the back button works correctly through the entire hierarchy.

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
    
    return DeeplinkRoute(type: .push, route: .detail(data))
}
```
