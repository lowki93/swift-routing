
# SwiftRouting

&#x20;

A lightweight, flexible navigation framework built on top of `NavigationStack` for SwiftUI.

## 🚀 Overview

SwiftRouting simplifies navigation in SwiftUI by introducing a decoupled routing system based on enums and deep links.

### ✨ Features

- Declarative navigation using simple `Route` enums
- Seamless integration with SwiftUI’s `NavigationStack`
- Deep linking support
- Full control over tab-based navigation
- Clean separation between routes and views
- Compatible with iOS 17+

---

## 🛍️ How It Works

### 1. Define a Route

Create an enum conforming to `Route` that represents all navigation paths:

```swift
enum HomeRoute: Route {
  case page1
  case page2(Int)
  case page3(String)

  public var name: String {
    switch self {
    case .page1: "page1"
    case let .page2(int): "page2(\(int))"
    case let .page3(string): "page3(\(string))"
    }
  }
}
```

Then, associate each route with a view:

```swift
extension HomeRoute: @retroactive RouteDestination {
  public static func view(for route: HomeRoute) -> some View {
    switch route {
    case .page1: Page1View()
    case let .page2(value): Page2View(value: value)
    case let .page3(value): Page3View(value: value)
    }
  }
}
```

> 💡 Keep your views and routing logic decoupled for better modularity and reuse.

---

### 2. Use a Router

A `Router` is automatically created by `RoutingNavigationStack`.

```swift
RoutingNavigationStack(stack: "Page", destination: HomeRoute.self, route: .page1)
```

This creates a `.stack("Page")` router that manages navigation for the `HomeRoute` enum.

---

### 3. Perform Navigation

All routers are available via the SwiftUI `Environment`.

```swift
@Environment(\.router) private var router

// Push a view in the stack
router.push(HomeRoute.page2(2))

// Present a view as a modal sheet
router.present(HomeRoute.page2(2))

// Present as a full-screen cover
router.cover(HomeRoute.page2(2))
```

---

### 4. Deep Linking

Use `DeeplinkRoute<Route>` to handle complex deep links.

```swift
struct HomeDeeplink: DeeplinkHandler {
  func deeplink(route: SubRoute) -> DeeplinkRoute<HomeRoute>? {
    ...
  }
}
```

Trigger navigation via:

```swift
@Environment(\.router) private var router

let result = HomeDeeplink().deeplink(...)
router.handle(deeplink: result)
```

This will:

- Dismiss any modals
- Reset the navigation stack
- Navigate through intermediate routes
- Reach the target destination

---

## 🧪 Advanced Use: Dependency Injection

For views needing `@Environment` or injected dependencies:

```swift
extension HomeRoute: @retroactive RouteDestination {
  public static func view(for route: HomeRoute) -> some View {
    HomeRouteDestination(route: route)
  }
}

struct HomeRouteDestination: View {
  @Environment(\.router) private var router
  let route: HomeRoute

  var body: some View {
    switch route {
    case .page1: Page1View()
    case let .page2(value): Page2View(value: value, router: router)
    case let .page3(value): Page3View(value: value)
    }
  }
}
```

---

## 🛍️ Tab Navigation

Define your tabs with `TabRoute`:

```swift
enum HomeTab: TabRoute {
  case tab1, tab2, tab3

  var name: String {
    switch self {
    case .tab1: "Tab 1"
    case .tab2: "Tab 2"
    case .tab3: "Tab 3"
    }
  }
}
```

### Option 1: Native `TabView`

```swift
TabView(selection: .tabToRoot(for: $tab, in: router)) {
  RoutingNavigationStack(tab: .tab1, destination: HomeRoute.self, root: .page1)
  RoutingNavigationStack(tab: .tab2, destination: HomeRoute.self, root: .page2)
  RoutingNavigationStack(tab: .tab3, destination: HomeRoute.self, root: .page3)
}
```

Use `.tabToRoot` to reset the stack when the selected tab is tapped again.

### Option 2: `RoutingTabView` with `TabRouter`

This gives you programmatic control over tabs:

```swift
RoutingTabView(tab: $tab, destination: HomeRoute.self) { destination in
  RoutingNavigationStack(tab: .tab1, destination: destination, root: .page1)
  RoutingNavigationStack(tab: .tab2, destination: destination, root: .page2)
  RoutingNavigationStack(tab: .tab3, destination: destination, root: .page3)
}
```

Inside the tab views:

```swift
@Environment(\.tabRouter) private var tabRouter

tabRouter.push(HomeRoute.page1, in: HomeTab.tab2)
tabRouter.present(HomeRoute.page3, in: HomeTab.tab1)
tabRouter.update(root: HomeRoute.page2, in: HomeTab.tab3)
```

Like `DeeplinkRoute`, you can use `TabDeeplink` to trigger deep linking inside a specific tab.

```swift
struct HomeDeeplink: DeeplinkHandler {
  func deeplink(route: SubRoute) -> TabDeeplink<HomeTab, HomeRoute>? {
    // Return a TabDeeplink with the target tab and a DeeplinkRoute
    ...
  }
}
```

Trigger the navigation using the `TabRouter`:

```swift
@Environment(\.tabRouter) private var tabRouter

let result = HomeDeeplink().deeplink(...)
tabRouter.handle(tabDeeplink: result)
```

This will:
- Switch to the specified tab.
- Trigger the associated `DeeplinkRoute` within that tab’s navigation stack.


---

## 📦 Installation

Install via **Swift Package Manager**:

```swift
dependencies: [
  .package(url: "https://github.com/lowki93/swift-routing.git", .upToNextMajor(from: "0.0.1"))
]
```

Then include:

```swift
.product(name: "SwiftRouting", package: "swift-routing")
```

---

## ✅ Summary

SwiftRouting brings structure, flexibility, and deep linking to SwiftUI apps:

- ✔️ Declarative and modular
- ✔️ Supports `NavigationStack`, `sheet`, and `cover`
- ✔️ Tab routing with `TabRouter`
- ✔️ Deep link handling with `DeeplinkRoute`

> 💡 Ideal for scalable SwiftUI apps targeting iOS 17 and up.

