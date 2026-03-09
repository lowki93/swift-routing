# Migrating from NavigationStack

Adopt SwiftRouting in an existing SwiftUI app with minimal disruption.

## Overview

If your app already uses `NavigationStack`, `NavigationLink`, or native sheet/cover modifiers, you can migrate to SwiftRouting incrementally. This guide walks through each common pattern and shows the equivalent SwiftRouting code.

## NavigationStack → RoutingView

### Before

```swift
@State private var path = NavigationPath()

var body: some View {
    NavigationStack(path: $path) {
        HomeView()
            .navigationDestination(for: String.self) { value in
                if value == "detail" {
                    DetailView()
                } else if value == "settings" {
                    SettingsView()
                }
            }
    }
}
```

### After

Define your routes as a Swift enum, then replace the stack with ``RoutingView``:

```swift
enum HomeRoute: Route {
    case home
    case detail(id: Int)
    case settings

    var name: String {
        switch self {
        case .home: "home"
        case .detail(let id): "detail(\(id))"
        case .settings: "settings"
        }
    }
}

extension HomeRoute: RouteDestination {
    static func view(for route: HomeRoute) -> some View {
        switch route {
        case .home: HomeView()
        case .detail(let id): DetailView(id: id)
        case .settings: SettingsView()
        }
    }
}

var body: some View {
    RoutingView(destination: HomeRoute.self, root: .home)
}
```

All `navigationDestination` registrations are replaced by a single `RouteDestination` conformance.

## NavigationLink → router.push

### Before

```swift
NavigationLink("View Details", value: "detail")

// Or with a destination view
NavigationLink("View Details") {
    DetailView(id: 42)
}
```

### After

Use `router.push(_:)` or the SwiftRouting `NavigationLink(route:)` extension:

```swift
// Programmatic push
Button("View Details") {
    router.push(HomeRoute.detail(id: 42))
}

// Declarative NavigationLink
NavigationLink("View Details", route: HomeRoute.detail(id: 42))
```

> Important: `NavigationLink(route:)` performs push navigation only. For modal presentation, use `router.present(_:)` or `router.cover(_:)`.

## Sheets → router.present

### Before

```swift
@State private var showSettings = false

var body: some View {
    Button("Open Settings") {
        showSettings = true
    }
    .sheet(isPresented: $showSettings) {
        SettingsView()
    }
}
```

### After

```swift
@Environment(\.router) private var router

Button("Open Settings") {
    router.present(HomeRoute.settings)
}
```

If you need sheet presentation modifiers such as `presentationDetents`, present without a navigation stack:

```swift
// In your route definition
var routingType: RoutingType { .sheet(withStack: false) }

// Or inline
router.present(HomeRoute.settings, withStack: false)
```

## Full-Screen Cover → router.cover

### Before

```swift
@State private var showOnboarding = false

var body: some View {
    Button("Start Onboarding") {
        showOnboarding = true
    }
    .fullScreenCover(isPresented: $showOnboarding) {
        OnboardingView()
    }
}
```

### After

```swift
Button("Start Onboarding") {
    router.cover(HomeRoute.onboarding)
}
```

## TabView → RoutingTabView

### Before

```swift
@State private var selectedTab = 0

TabView(selection: $selectedTab) {
    HomeView()
        .tabItem { Label("Home", systemImage: "house") }
        .tag(0)

    SearchView()
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
        .tag(1)

    ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
        .tag(2)
}
```

### After — Option 1: RoutingTabView (recommended)

Use `RoutingTabView` when you need programmatic cross-tab navigation via ``TabRouter``:

```swift
enum HomeTab: TabRoute {
    case home
    case search
    case profile

    var name: String {
        switch self {
        case .home: "home"
        case .search: "search"
        case .profile: "profile"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: HomeTab = .home

    var body: some View {
        RoutingTabView(tab: $selectedTab, destination: HomeRoute.self) { destination in
            RoutingView(tab: .home, destination: destination, root: .home)
                .tabItem { Label("Home", systemImage: "house") }

            RoutingView(tab: .search, destination: destination, root: .search)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            RoutingView(tab: .profile, destination: destination, root: .profile)
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

### After — Option 2: Native TabView with .tabToRoot

For simpler cases without programmatic tab control:

```swift
struct ContentView: View {
    @Environment(\.router) private var router
    @State private var selectedTab: HomeTab = .home

    var body: some View {
        TabView(selection: .tabToRoot(for: $selectedTab, in: router)) {
            RoutingView(tab: .home, destination: HomeRoute.self, root: .home)
                .tabItem { Label("Home", systemImage: "house") }

            RoutingView(tab: .search, destination: HomeRoute.self, root: .search)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            RoutingView(tab: .profile, destination: HomeRoute.self, root: .profile)
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

The `.tabToRoot` binding automatically pops to root when the user taps the already-selected tab.

> Important: This option does **not** provide `@Environment(\.tabRouter)`. Use `RoutingTabView` when cross-tab programmatic navigation is needed.

## Deep Links

### Before

Deep link handling typically required parsing URLs and manually mutating `NavigationPath`:

```swift
.onOpenURL { url in
    if url.path == "/detail" {
        path.append("detail")
    }
}
```

### After

Define a typed identifier enum (`Hashable & Sendable`) to represent your deep link inputs, then implement ``DeeplinkHandler`` to map it to a ``DeeplinkRoute``:

```swift
enum AppDeeplinkIdentifier: Hashable, Sendable {
    case detail(id: Int)
}

extension AppDeeplinkIdentifier {
    init?(url: URL) {
        switch url.path {
        case "/detail":
            guard let id = Int(url.lastPathComponent) else { return nil }
            self = .detail(id: id)
        default:
            return nil
        }
    }
}

struct HomeDeeplinkHandler: DeeplinkHandler {
    typealias R = AppDeeplinkIdentifier
    typealias D = HomeRoute

    func deeplink(from route: AppDeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
        switch route {
        case .detail(let id):
            return .push(.detail(id: id))
        }
    }
}
```

Parse the URL into the identifier inside `.onOpenURL`, then pass it to the handler:

```swift
struct HomeRootView: View {
    @Environment(\.router) private var router
    let handler = HomeDeeplinkHandler()

    var body: some View {
        HomeView()
            .onOpenURL { url in
                Task {
                    guard let identifier = AppDeeplinkIdentifier(url: url) else { return }
                    guard let deeplink = try? await handler.deeplink(from: identifier) else { return }
                    router.handle(deeplink: deeplink)
                }
            }
    }
}
```

See <doc:Deeplinks> for advanced patterns including path building, async data fetching, and tab-aware deep linking.

## Dismissing Modals

### Before

```swift
@Environment(\.dismiss) private var dismiss

Button("Close") {
    dismiss()
}
```

### After

```swift
@Environment(\.router) private var router

Button("Close") {
    router.close()
}
```

`router.close()` dismisses the current presented modal. It is a no-op if the router is not presented.

## Topics

### Related

- <doc:GettingStarted>
- <doc:NavigationBasics>
- <doc:Deeplinks>
- ``RoutingView``
- ``RouterModel``
- ``DeeplinkHandler``
