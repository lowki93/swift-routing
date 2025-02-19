# SwiftRouting
Framework for navigation in SwiftUI

## Introduction
SwiftRouting provides a simple navigation layer based on `NavigationStack`.

### Main Features:
-   Simple and decoupled navigation using `Route`
-   Deep linking handled separately from navigation
 
This framework is entirely written in Swift and SwiftUI, using `ObservableObject`, and supports iOS 17 and later.


## How It Works

### Define a Route
A `Route` is an enumeration listing all possible navigation destinations.
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
Next, associate each `Route` with a view:
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

By keeping `Route` and `RouteDestination` separate, navigation is more flexible, allowing different frameworks to remain independent without knowing each other.

 **Note**: For views requiring environment values or dependency injection, see **"Advanced Destination"**.


### Instantiate a Router
A `Router` is automatically created whenever a `RoutingNavigationStack` is instantiated.
```swift
RoutingNavigationStack(stack: "Page", destination: HomeRoute.self, route: .page1)
```
This `RoutingNavigationStack` creates a `Router` of type `.stack("Page")`, enabling navigation to all routes defined in `HomeRoute`.


### Navigation
All `Router` instances are available in the SwiftUI `Environment`. Choose between `push`, `present`, or `cover` to navigate:
```swift
@Environment(\.router) private var router

// Push route in the stack
router.push(HomeRouter.page2(2))
// Present route as a sheet
router.present(HomeRouter.page2(2))
// Present route as a full-screen cover
router.cover(HomeRouter.page2(2))
```


### Deep Linking Support
`Router` handles deep linking using the `DeeplinkRoute<Route>` object.

A `DeeplinkRoute` specifies the navigation path and final destination. It can include an optional sequence of intermediate routes before reaching the target.

The `DeeplinkHandler` protocol helps convert a `Route` into a `DeeplinkRoute`:

 `DeeplinkHandler` protocol can help you to convert a `Route` to a `Route` use by `RouteDestination`.
```swift
struct HomeDeeplink: DeeplinkHandler {
  func deeplink(route: SubRoute) -> DeeplinkRoute<HomeRoute>? {
    // Convert the incoming route to a DeeplinkRoute<HomeRoute>
    ...
  }
}
```
Next, pass the result to the `Router`:
```swift
@Environment(\.router) private var router
private let homeDeeplink = HomeDeeplink()

let result = homeDeeplink.deeplink(..)
route.handle(deeplink: result)
```
 `Router.handle(deeplink:)` Execution
- Closes all currently presented child routers.
- Clears the current navigation stack.
- Pushes intermediate routes defined in the deeplink.
- Navigates to the final destination..


### Advanced Destination
If your view requires environment objects or dependency injection, you can create a separate view:
```swift
extension HomeRoute: @retroactive RouteDestination {
  public static func view(for route: HomeRoute) -> some View {
    HomeRouteDestination(route: route)
  }
}

struct HomeRouteDestination {
  @Environment(\.router) private var router
  let route: HomeRoute

  var body: some View {
    switch route:
    case .page1: Page1View()
    case let .page2(value): Page2View(value: value, router: router)
    case let .page3(value): Page3View(value: value)
  }
}
```


### TabView and Tab-Based Navigation
SwiftRouting supports tab navigation using `TabRoute`.
Define the tabs:
```swift
public enum HomeTab: TabRoute {
  case tab1
  case tab2
  case tab3
  
  public var name: String {
    switch self {
    case .tab1: "Tab 1"
    case .tab2: "Tab 2"
    case .tab3: "Tab 3"
    }
  }
}
```
Use with native `TabView`:
```swift
struct HomeScreen: View {
  @Environment(\.router) private var router
  @State private var tab: HomeTab = .tab1

  var body: some View {
    TabView(selection: $tab) {
      RoutingNavigationStack(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1)
      RoutingNavigationStack(tab: HomeTab.tab2, destination: HomeRoute.self, root: .page2)
      RoutingNavigationStack(tab: HomeTab.tab3, destination: HomeRoute.self, root: .page3)
    }
  }
}
```
This creates three child `Router` instances:
- `.tab(page1)`
-  `.tab(page2)`
-  `.tab(page3)`
    
Find the router for a tab:
```swift
router.find(tab: HomeTab.tab1)
```
SwiftRouting handles `popToRoot` automatically for a tab. Simply use:
```swift
TabView(selection: .tabToRoot(for: $tab, in: router)) {
  ...
}
```

### Instalation
SwiftRouting can be installed via **Swift Package Manager**.
Add the following to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/lowki93/swift-routing.git", .upToNextMajor(from: "0.0.1"))
]
```
In your dependencies:
```swift
.product(name: "SwiftRouting", package: "swift-routing"),
```

## Conclusion

SwiftRouting simplifies navigation in SwiftUI by separating routing from view implementation. It supports: 
✅ `NavigationStack`-based navigation  
✅ View presentation (`sheet`, `cover`)  
✅ Deep linking  
✅ Advanced tab navigation (`TabRoute`)

🚀 **Easy to integrate and extend for your iOS 17+ projects!**
