# Tab Navigation

Learn how to implement tab-based navigation with SwiftRouting.

## Overview

SwiftRouting provides first-class support for tab-based navigation through ``TabRoute``, ``TabRouter``, and ``RoutingTabView``.

## Defining Tabs

Create an enum conforming to ``TabRoute``:

```swift
enum HomeTab: TabRoute {
    case home
    case search
    case profile
    
    var name: String {
        switch self {
        case .home: "Home"
        case .search: "Search"
        case .profile: "Profile"
        }
    }
}
```

## Option 1: Using RoutingTabView

``RoutingTabView`` provides a `TabRouter` for programmatic tab control:

```swift
struct ContentView: View {
    @State private var selectedTab: HomeTab = .home
    
    var body: some View {
        RoutingTabView(tab: $selectedTab, destination: HomeRoute.self) { destination in
            RoutingView(tab: HomeTab.home, destination: destination, root: .home)
                .tabItem { Label("Home", systemImage: "house") }
            
            RoutingView(tab: HomeTab.search, destination: destination, root: .search)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            
            RoutingView(tab: HomeTab.profile, destination: destination, root: .profile)
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

## Option 2: Using Native TabView

For simpler cases, use SwiftUI's `TabView` with the `.tabToRoot` binding:

```swift
struct ContentView: View {
    @Environment(\.router) private var router
    @State private var selectedTab: HomeTab = .home
    
    var body: some View {
        TabView(selection: .tabToRoot(for: $selectedTab, in: router)) {
            RoutingView(tab: HomeTab.home, destination: HomeRoute.self, root: .home)
                .tabItem { Label("Home", systemImage: "house") }
            
            RoutingView(tab: HomeTab.search, destination: HomeRoute.self, root: .search)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            
            RoutingView(tab: HomeTab.profile, destination: HomeRoute.self, root: .profile)
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

The `.tabToRoot` binding automatically pops to root when the user taps the already-selected tab.

> Important:
> This native `TabView` approach does **not** provide a `TabRouter` in the environment.
> Use `RoutingTabView` when you need `@Environment(\\.tabRouter)` and cross-tab programmatic actions.

## Using TabRouter

Access the ``TabRouter`` from the environment to navigate across tabs:

```swift
struct SomeView: View {
    @Environment(\.tabRouter) private var tabRouter
    
    var body: some View {
        Button("Go to Profile") {
            // Switch to profile tab and push a route
            tabRouter?.push(HomeRoute.settings, in: HomeTab.profile)
        }
    }
}
```

### TabRouter Methods

| Method | Description |
|--------|-------------|
| `change(tab:)` | Switch to a different tab |
| `push(_:in:)` | Push a route in a specific tab |
| `present(_:in:)` | Present a sheet in a specific tab |
| `cover(_:in:)` | Present a cover in a specific tab |
| `update(root:in:)` | Update the root of a specific tab |
| `popToRoot(in:)` | Pop to root in a specific tab |

> Note:
> For `update(root:in:)`, `push(_:in:)`, `present(_:in:)`, and `cover(_:in:)`:
> if you pass a non-`nil` tab, `TabRouter` switches to that tab first (equivalent to calling `change(tab:)`), then performs the navigation action.

### Navigating in Current Tab

Pass `nil` for the tab parameter to use the currently selected tab:

```swift
// Push in the current tab
tabRouter?.push(HomeRoute.detail(id: 42), in: nil)
```

## Hiding the Tab Bar

To hide the tab bar when pushing views, override `hideTabBarOnPush`:

```swift
enum HomeTab: TabRoute {
    case home
    case immersive
    
    var name: String { /* ... */ }
    
    var hideTabBarOnPush: Bool {
        switch self {
        case .immersive: true
        default: false
        }
    }
}
```

## Deep Linking with Tabs

Use ``TabDeeplinkHandler`` to map incoming identifiers to a ``TabDeeplink``:

```swift
struct AppDeeplinkHandler: TabDeeplinkHandler {
    typealias R = DeeplinkIdentifier
    typealias T = HomeTab
    typealias D = HomeRoute

    func deeplink(from route: DeeplinkIdentifier) async throws -> TabDeeplink<HomeTab, HomeRoute>? {
        switch route {
        case .userProfile(let userId):
            return TabDeeplink(
                tab: .profile,
                deeplink: DeeplinkRoute(type: .push, route: .profile(userId: userId))
            )
        default:
            return nil
        }
    }
}
```

Handle the deep link with the TabRouter:

```swift
if let tabDeeplink = try await handler.deeplink(from: incomingRoute) {
    tabRouter?.handle(tabDeeplink: tabDeeplink)
}
```

This will:
1. Switch to the specified tab
2. Execute the associated `DeeplinkRoute` within that tab
