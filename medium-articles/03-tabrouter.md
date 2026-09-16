# Tab Navigation in SwiftUI: Taming Cross-Tab Routing with TabRouter

*Part 3 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270) and [Part 2: The RouteContext Pattern](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407).*

Every app with a tab bar eventually needs to do something SwiftUI's `TabView` was never designed for: switch to a different tab *and* push a screen inside it, from a single button tap somewhere else entirely. A push notification lands on the Profile tab while you're browsing Home. A "View order" button in a confirmation sheet needs to land three levels deep in the Orders tab. The already-selected tab needs to pop to root when tapped again — but only sometimes.

`TabView` alone gives you none of this. `swift-routing` gives you `TabRouter`.

---

## The Problem: TabView Has No Memory of Its Own Structure

A plain `TabView` only knows one thing: which tab is currently selected.

```swift
struct ContentView: View {
  @State private var selectedTab: HomeTab = .home

  var body: some View {
    TabView(selection: $selectedTab) {
      HomeView().tabItem { Label("Home", systemImage: "house") }
      SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }
      ProfileView().tabItem { Label("Profile", systemImage: "person") }
    }
  }
}
```

That's it. There's no API for "push a screen in the Profile tab while I'm on Home." Each tab manages its own `NavigationStack` in isolation, and nothing outside that tab can reach into it. If `HomeView` needs to react to a notification tap by opening a specific order inside the Orders tab, you're on your own — usually some combination of `@State` hoisted to a shared ancestor, a `PassthroughSubject`, and a prayer that the timing works out once the tab has actually mounted.

Tapping the currently-selected tab again is its own separate problem: SwiftUI gives you no hook for it at all.

---

## RoutingTabView + TabRouter: One Router Per Tab

`RoutingTabView` gives every tab its own `Router`, all coordinated by a parent `TabRouter`:

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

From any view inside that hierarchy, `@Environment(\.tabRouter)` gives you a handle that can reach *any* tab, not just the current one:

```swift
struct SomeView: View {
  @Environment(\.tabRouter) private var tabRouter

  var body: some View {
    Button("Go to Profile") {
      tabRouter?.push(HomeRoute.settings, in: HomeTab.profile)
    }
  }
}
```

`tabRouter` is optional by design — it's only available inside a `RoutingTabView`. A view that might be reused outside a tab context (or in a plain push/present flow) still compiles; it just no-ops if there's no tab router around.

---

## Cross-Tab Actions, Concretely

Every mutating method on `TabRouter` takes an optional tab:

| Method | Effect |
|--------|--------|
| `change(tab:)` | Switch to a different tab |
| `push(_:in:)` | Push a route in a specific tab |
| `present(_:in:)` | Present a sheet in a specific tab |
| `cover(_:in:)` | Present a full-screen cover in a specific tab |
| `update(root:in:)` | Replace the root of a specific tab |
| `popToRoot(in:)` | Pop a specific tab back to its root |

Pass `nil` for `tab` to target whichever tab is currently selected. Pass an explicit tab, and — for every method except `popToRoot(in:)` — `TabRouter` switches to it first, then performs the action:

```swift
// Switches to .profile, THEN pushes — the user sees the tab change and land on settings.
tabRouter.push(AppRoute.user(name: "Joseph"), in: HomeTab.profile)

// Presents a sheet in the notifications tab without leaving the current tab.
tabRouter.present(AppRoute.search, in: HomeTab.notifications)

// Resets the home tab's stack WITHOUT switching to it — you stay exactly where you are.
tabRouter.popToRoot(in: HomeTab.home)
```

That last one is a deliberate exception, not an oversight. `popToRoot(in:)` is the one method that never calls `change(tab:)` — resetting a tab you're not looking at (say, clearing the Home stack when a session expires) shouldn't yank the user away from what they're doing.

The swift-routing demo app's `ProfileScreen` exercises four of these side by side, injecting `any TabRouterModel` into a view model instead of reading `@Environment(\.tabRouter)` straight from the view — the same pattern the rest of the series leans on, and one that keeps navigation testable without mounting a single view:

```swift
struct ProfileScreen: View {
  let viewModel: ProfileViewModel

  var body: some View {
    VStack {
      Button("Present search (current tab)") { viewModel.presentSearch() }
      Button("Cover about (current tab)") { viewModel.coverAbout() }
      Button("Present search in notifications tab") { viewModel.presentSearchInNotifications() }
      // popToRoot(in:) does NOT call change(tab:) -- unlike push/present/cover/update,
      // this resets the home tab's stack without switching you to it.
      Button("Reset home tab (stays on profile)") { viewModel.resetHomeTab() }
    }
    .navigationTitle("Profile")
  }
}

@MainActor
final class ProfileViewModel {
  private let tabRouter: (any TabRouterModel)?

  init(tabRouter: (any TabRouterModel)?) {
    self.tabRouter = tabRouter
  }

  func presentSearch() {
    tabRouter?.present(AppRoute.search)                              // current tab
  }

  func coverAbout() {
    tabRouter?.cover(AppRoute.about)                                 // current tab
  }

  func presentSearchInNotifications() {
    tabRouter?.present(AppRoute.search, in: HomeTab.notifications)   // switches tab first
  }

  func resetHomeTab() {
    tabRouter?.popToRoot(in: HomeTab.home)                           // never switches tab
  }
}
```

Four buttons, four distinct tab behaviors, and not one of them needed a `NavigationStack` binding threaded in from outside.

---

## Reacting to Tab Reselection

Tapping the already-selected tab is a UX convention users expect to do *something* — usually scroll to top, sometimes reset a filter. SwiftUI's `TabView` doesn't expose this as an event at all.

`onTabReselected(_:perform:)` does, without touching the default pop-to-root behavior:

```swift
struct HomeView: View {
  @ScrollViewProxy var scrollProxy

  var body: some View {
    ScrollView {
      // ...
    }
    .onTabReselected(HomeTab.home) {
      scrollProxy.scrollTo("top", anchor: .top)
    }
  }
}
```

The handler fires *after* the stack has already popped to root, and only when the reselected tab matches the one you passed. It works identically whether you're using `RoutingTabView` or the native `TabView` + `.tabToRoot` binding described below — same modifier, same guarantee, wherever the tab bar lives.

---

## Don't Need Cross-Tab Actions? Use Native TabView

Not every tabbed app needs a `TabRouter`. If tabs never need to talk to each other — no cross-tab push, no cross-tab present — SwiftUI's own `TabView` works fine, with one addition: the `.tabToRoot` binding.

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

`.tabToRoot` gives you the reselect-to-reset behavior for free, and each `RoutingView(tab:destination:root:)` still gets its own independent `Router` and `NavigationStack`. What you lose is `@Environment(\.tabRouter)` — there's no `TabRouter` instance published into the environment, because there's no shared coordinator to publish. Reach for `RoutingTabView` the moment any of your tabs need to act on another one; stick with native `TabView` for everything else.

---

## Before and After

Here's a common trigger for cross-tab navigation: a "View order" button inside a confirmation sheet needs to dismiss, switch to the Orders tab, and land straight on that order's detail screen — three actions from one tap, in a tab the sheet itself knows nothing about.

**Before — a shared flag and a race with `onAppear`:**

```swift
// Somewhere shared, injected into both the confirmation sheet and OrdersView
@Observable
final class PendingOrderNavigation {
  var orderId: String?
}

// ConfirmationSheet
Button("View order") {
  selectedTab = .orders
  pendingNavigation.orderId = order.id   // OrdersView may not even be mounted yet
  dismiss()
}

// OrdersView — has to guess whether it mounted before or after the flag was set
struct OrdersView: View {
  @State private var path = NavigationPath()

  var body: some View {
    NavigationStack(path: $path) {
      // ...
    }
    .onAppear { applyPendingNavigationIfNeeded() }
    .onChange(of: pendingNavigation.orderId) { applyPendingNavigationIfNeeded() }
  }

  private func applyPendingNavigationIfNeeded() {
    guard let orderId = pendingNavigation.orderId else { return }
    path.append(orderId)
    pendingNavigation.orderId = nil
  }
}
```

**After — one call, no mounting order to reason about:**

```swift
Button("View order") {
  tabRouter.push(AppRoute.order(id: order.id), in: HomeTab.orders)
  dismiss()
}
```

`TabRouter` already knows how to switch tabs and push into a tab that hasn't been visited yet — that's exactly what `push(_:in:)` does internally, every time. No flag to clear, no `onAppear`/`onChange` race, no `OrdersView`-specific code required to make it work, and no extra type needed just to hold a `tabRouter` reference for this one call — the button's own action closure is enough.

This is deliberately a plain in-app trigger, not an external one. If the *same* navigation needs to happen from a push notification or a URL instead of a button tap, that's `TabDeeplinkHandler`'s job, not something to reinvent by hand — its own article is coming up later in the series.

---

## Why This Matters

None of this is exotic. Cross-tab navigation and reselect-to-reset are things almost every non-trivial tabbed app eventually needs. What's missing from SwiftUI isn't the *possibility* of building them — it's a consistent, typed way to do it that doesn't turn into a pile of `@State` and `NotificationCenter` posts the third time a new cross-tab flow shows up.

`TabRouter` is the same idea as the rest of swift-routing, applied to tabs: routes as values, and a router that knows how to apply them across tab boundaries. One less category of navigation code that has to be reinvented per app.

*Testing cross-tab navigation with `TabRouterSpy` is its own topic — coming up later in this series.*

The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
