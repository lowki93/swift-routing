# Step 4 — Tab Bar

## Before

```swift
@State private var selectedTab = 0

TabView(selection: $selectedTab) {
    HomeView()
        .tabItem { Label("Home", systemImage: "house") }
        .tag(0)

    ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
        .tag(1)
}
```

## After

### Option 1 — RoutingTabView (recommended)

Use when you need programmatic cross-tab navigation via `TabRouter`:

```swift
enum HomeTab: TabRoute {
    case home
    case profile

    var name: String {
        switch self {
        case .home: "home"
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

            RoutingView(tab: .profile, destination: destination, root: .profile)
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

### Option 2 — Native TabView with .tabToRoot

For simpler cases without cross-tab programmatic control:

```swift
struct ContentView: View {
    @Environment(\.router) private var router
    @State private var selectedTab: HomeTab = .home

    var body: some View {
        TabView(selection: .tabToRoot(for: $selectedTab, in: router)) {
            RoutingView(tab: .home, destination: HomeRoute.self, root: .home)
                .tabItem { Label("Home", systemImage: "house") }

            RoutingView(tab: .profile, destination: HomeRoute.self, root: .profile)
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

`.tabToRoot` pops to root automatically when the user taps the already-selected tab.

## Cross-Tab Navigation

With `RoutingTabView`, access `TabRouter` from the environment:

```swift
@Environment(\.tabRouter) private var tabRouter

tabRouter?.change(tab: .profile)
tabRouter?.push(HomeRoute.detail(id: 42), in: .profile)
tabRouter?.present(HomeRoute.settings, in: nil)  // current tab
```

## Key Constraints

- Use `RoutingTabView` when `@Environment(\.tabRouter)` is needed — native `TabView` does not inject it.
- One `RoutingView` per tab.
- Pass `in: nil` to target the currently selected tab.
- If `in tab` is non-`nil`, `TabRouter` automatically switches to that tab before executing the action.
