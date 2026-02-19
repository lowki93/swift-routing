# Tab Router

Use this guide for tab-based navigation with `TabRoute`, `RoutingTabView`, and `TabRouter`.

## Prerequisites

Before using `TabRouter`, make sure you already have:
1. Route definitions (`Route` + `RouteDestination`)
2. `RoutingView` basics

Recommended order:
- `references/routes.md`
- `references/routing-view.md`
- `references/router.md`

## Define Tabs

Create a tab enum conforming to `TabRoute`:

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
```

Optional: hide the tab bar on push for specific tabs:

```swift
extension HomeTab {
  var hideTabBarOnPush: Bool {
    switch self {
    case .profile: true
    default: false
    }
  }
}
```

## Build a Tab Container

Use `RoutingTabView` to create a `TabRouter` scope and one `RoutingView` per tab:

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

## Native TabView vs RoutingTabView

You can also use native `TabView` with `.tabToRoot(...)` for simple tab behavior:

```swift
@Environment(\.router) private var router
@State private var selectedTab: HomeTab = .home

TabView(selection: .tabToRoot(for: $selectedTab, in: router)) {
  RoutingView(tab: HomeTab.home, destination: HomeRoute.self, root: .home)
  RoutingView(tab: HomeTab.search, destination: HomeRoute.self, root: .search)
}
```

Key difference:
- `TabView + tabToRoot`: no `TabRouter` environment value.
- `RoutingTabView`: provides `@Environment(\.tabRouter)` and cross-tab programmatic control.

## Access TabRouter

Read `TabRouter` from environment:

```swift
@Environment(\.tabRouter) private var tabRouter
```

Then navigate across tabs:

```swift
tabRouter?.change(tab: HomeTab.profile)
tabRouter?.push(HomeRoute.detail(id: 42), in: HomeTab.profile)
tabRouter?.present(HomeRoute.settings, in: HomeTab.profile)
tabRouter?.cover(HomeRoute.onboarding, in: HomeTab.profile)
tabRouter?.update(root: HomeRoute.profile, in: HomeTab.profile)
tabRouter?.popToRoot(in: HomeTab.profile)
```

## Automatic Tab Switch Behavior

For these methods:
- `update(root:in:)`
- `push(_:in:)`
- `present(_:in:)`
- `cover(_:in:)`

if `in tab` is non-`nil`, `TabRouter` automatically calls `change(tab:)` first, then executes the action in that tab.

If `in tab` is `nil`, the action runs in the currently selected tab.

## Current Tab Behavior

Pass `nil` for the tab parameter to target the currently selected tab:

```swift
tabRouter?.push(HomeRoute.detail(id: 42), in: nil)
tabRouter?.present(HomeRoute.settings, in: nil)
tabRouter?.cover(HomeRoute.onboarding, in: nil)
tabRouter?.popToRoot(in: nil)
```

## ViewModel Injection

For ViewModels, inject `any TabRouterModel` (protocol), not concrete `TabRouter`:

```swift
@MainActor
final class ProfileCoordinatorViewModel: ObservableObject {
  private let tabRouter: any TabRouterModel

  init(tabRouter: any TabRouterModel) {
    self.tabRouter = tabRouter
  }

  func openProfileSettings() {
    tabRouter.change(tab: HomeTab.profile)
    tabRouter.push(HomeRoute.settings, in: HomeTab.profile)
  }
}
```

## App-Level Convenience Overloads (Optional)

If your app has a main route enum (for example `HomeRoute`) and you want concise calls,
add overloads on `TabRouterModel`:

```swift
public extension TabRouterModel {
  @_disfavoredOverload
  func push(_ homeRoute: HomeRoute) {
    push(homeRoute, in: nil)
  }

  @_disfavoredOverload
  func update(root homeRoute: HomeRoute) {
    update(root: homeRoute, in: nil)
  }
}
```

Before:

```swift
tabRouter.push(HomeRoute.profile, in: nil)
tabRouter.present(HomeRoute.settings, in: nil)
tabRouter.update(root: HomeRoute.home, in: nil)
```

After:

```swift
tabRouter.push(.profile)
tabRouter.present(.settings)
tabRouter.update(root: .home)
```

Recommendation:
- add this pattern only for the main app route type to keep overload resolution clear.

You can apply the same pattern for your main tab enum as well:

```swift
public extension TabRouterModel {
  @_disfavoredOverload
  func push(_ homeRoute: HomeRoute, in tab: HomeTab?) {
    push(homeRoute, in: tab as (any TabRoute)?)
  }

  @_disfavoredOverload
  func popToRoot(in tab: HomeTab?) {
    popToRoot(in: tab as (any TabRoute)?)
  }
}
```

Before:

```swift
tabRouter.push(HomeRoute.profile, in: HomeTab.profile)
tabRouter.popToRoot(in: HomeTab.profile)
```

After:

```swift
tabRouter.push(.profile, in: .profile)
tabRouter.popToRoot(in: .profile)
```

## Best Practices

- Keep one `RoutingView` per tab.
- Use `change(tab:)` before cross-tab navigation when intent is explicit.
- Use `in: nil` for "current tab" actions.
- Prefer protocol injection in ViewModels (`TabRouterModel`).
- Keep tab selection logic simple; route details belong to tab-local stacks.
