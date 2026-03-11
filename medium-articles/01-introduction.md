# Stop Fighting SwiftUI Navigation: A Type-Safe Approach with swift-routing

A few years ago, while working at Sorare, I ran into a problem that felt minor at first — and then became unavoidable.

The app was organized into feature frameworks: one for the marketplace, one for the game, one for the user profile. Each feature owned its screens. Clean, modular, scalable. Except for one thing: to navigate from Feature A to a screen in Feature B, Feature A had to import Feature B. And Feature B sometimes imported Feature A back. Circular dependencies started appearing. The module graph turned into a tangle.

The solution wasn't a navigation library — it was a constraint: **routes had to live outside the views they represent**. Once routes became standalone values, features could navigate to each other without importing each other. The dependency problem disappeared.

That constraint became swift-routing.

---

## "But What About the Coordinator Pattern?"

Fair question. The Coordinator pattern has been around in iOS development since at least 2015, and it addresses the same root problem: views shouldn't own navigation. If you've used it with UIKit, the mental model is similar.

The difference is context. UIKit coordinators work by holding references to view controllers and pushing/presenting them imperatively. That fits UIKit's lifecycle well. In SwiftUI, the same approach fights the framework — SwiftUI wants to own the view hierarchy, and `NavigationStack` is declarative by design. Bolting a UIKit-style coordinator on top means managing two conflicting mental models at once, and you end up writing adapter code to bridge them.

swift-routing is built for SwiftUI from the ground up. Routes are values, navigation state is observable, and the router is injected via the SwiftUI environment — not passed through `init` chains or stored in a coordinator tree. Everything works with SwiftUI's rendering model rather than against it.

There are also SwiftUI-native coordinator libraries worth knowing. [FlowStacks](https://github.com/johnpatrickmorgan/FlowStacks) by John Patrick Morgan is a solid one. The main difference is philosophy: FlowStacks gives you full control over the navigation stack as a plain array of screens, which is powerful but verbose. swift-routing leans on convention — routes declare their own presentation style, routers are scoped automatically, and the common cases require almost no configuration. The flexibility is there when you need it; it just doesn't get in the way when you don't.

---

## The Problem with NavigationStack at Scale

Even without a modular setup, SwiftUI's `NavigationStack` starts showing cracks the moment your app grows. Here's what a typical multi-screen app looks like:

```swift
// In SceneDelegate or your root view...
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    HomeView()
        .navigationDestination(for: String.self) { id in
            DetailView(id: id)
        }
        .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
            case .general: GeneralSettingsView()
            case .notifications: NotificationsView()
            case .privacy: PrivacyView()
            }
        }
}
```

Now imagine five features, each with their own destinations. A few problems compound fast:

**1. Routes are stringly-typed or weakly typed.** Passing a `String` to identify a destination is fragile. There's no compiler guarantee that the destination exists or that you're passing the right data.

**2. Navigation logic leaks into views.** `HomeView` decides how to present the settings screen. `ProductView` knows that going to checkout requires a full-screen cover. Views accumulate coordination logic that has nothing to do with presentation.

**3. Features import each other.** If `FeatureA` wants to navigate to a screen in `FeatureB`, it imports `FeatureB` — and if `FeatureB` ever needs to go back the other way, you have a circular dependency.

**4. It's untestable.** Navigation state lives inside views, bound to `@State`. There's no clean way to assert that tapping a button triggered the right navigation action.

swift-routing solves all four.

---

## Routes as Data

The core idea is simple: **a route is just a value**.

You define an enum that represents every destination in your feature:

```swift
enum AppRoute: Route {
    case home
    case profile(userId: String)
    case settings

    var name: String {
        switch self {
        case .home: "home"
        case let .profile(id): "profile(\(id))"
        case .settings: "settings"
        }
    }
}
```

`AppRoute` is a plain Swift type — hashable, sendable, exhaustive. No strings. No `AnyHashable`. No ambient state. The compiler tells you immediately if you forget a case.

In a modular app, this enum lives in a shared module — a `RoutingKit` or `AppRoutes` target — that every feature can import without importing each other. Feature A says `router.push(AppRoute.checkout(...))` without knowing anything about the checkout feature's internals.

---

## Separating Routes from Views

The view mapping lives in a dedicated conformance, isolated from your views:

```swift
extension AppRoute: RouteDestination {
    static func view(for route: AppRoute) -> some View {
        switch route {
        case .home:
            HomeView()
        case let .profile(userId):
            ProfileView(userId: userId)
        case .settings:
            SettingsView()
        }
    }
}
```

This is the only place that knows which view corresponds to which route. Your views are completely unaware of the navigation structure around them. They don't know if they were pushed, presented as a sheet, or used as a full-screen cover.

This separation is what makes the modular architecture work: the `AppRoutes` module holds the enum, the `AppShell` or composition root holds the `RouteDestination` conformance, and feature modules stay isolated.

---

## Setting Up the Stack

The entry point is `RoutingView`. Drop it at the top of your scene:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RoutingView(destination: AppRoute.self, root: .home)
        }
    }
}
```

That single line:
- Creates a `NavigationStack`
- Instantiates a `Router` and injects it into the SwiftUI environment
- Renders `HomeView` as the root
- Wires up all `navigationDestination` handlers automatically

No boilerplate. No manual `NavigationPath` management.

---

## Navigating from Views

Inside any view, you access the router from the environment:

```swift
struct HomeView: View {
    @Environment(\.router) private var router

    var body: some View {
        VStack {
            Button("Open Profile") {
                router.push(AppRoute.profile(userId: "42"))
            }
            Button("Settings") {
                router.present(AppRoute.settings)
            }
        }
    }
}
```

The `Router` covers the full navigation surface:

| Method | Effect |
|--------|--------|
| `router.push(_:)` | Push onto the stack |
| `router.present(_:)` | Present as a sheet |
| `router.cover(_:)` | Full-screen cover |
| `router.back()` | Pop one level |
| `router.popToRoot()` | Clear the entire stack |
| `router.close()` | Dismiss a modal |
| `router.update(root:)` | Replace the root |

### Before and After

Here's what navigating to a profile looks like before swift-routing:

```swift
// HomeView.swift — before
struct HomeView: View {
    @Binding var path: NavigationPath

    var body: some View {
        Button("Open Profile") {
            path.append("user-42") // What is "user-42"? No one knows.
        }
    }
}
```

And after:

```swift
// HomeView.swift — after
struct HomeView: View {
    @Environment(\.router) private var router

    var body: some View {
        Button("Open Profile") {
            router.push(AppRoute.profile(userId: "user-42")) // Explicit, typed, traceable.
        }
    }
}
```

The call site is self-documenting. The compiler enforces it. And `HomeView` no longer needs a `@Binding` injected from above.

---

## One Router Per Scope, Automatically

Every `RoutingView` creates its own `Router`, scoped to that navigation context.

When you present a sheet, the sheet gets its own child `Router`. When that sheet presents another sheet, that too gets its own `Router`. The routers form a hierarchy that mirrors your navigation tree — and they clean up after themselves automatically when dismissed.

You never instantiate `Router` yourself. You just read it from the environment:

```swift
@Environment(\.router) private var router
```

The right router is always there, always scoped correctly. If you're inside a sheet, `router.close()` dismisses the sheet. If you're inside the main stack, `router.back()` pops. Same API, context-aware behavior.

---

## Routing by Convention

Routes can also declare their own presentation style. If `settings` should always open as a sheet, encode that directly in the route:

```swift
enum AppRoute: Route {
    case home
    case settings

    var routingType: RoutingType {
        switch self {
        case .settings: .sheet(withStack: true)
        default: .push
        }
    }
}
```

Then a single call handles everything:

```swift
router.route(AppRoute.settings) // Always opens as a sheet, wherever this is called.
```

This is useful for establishing conventions in your codebase — "settings is always a sheet" — without scattering that knowledge across call sites. Change your mind later? Update one place.

---

## What's Next

This is just the foundation. swift-routing has more to offer:

- **RouteContext** — a mechanism for child routes to send typed data back to parent routes, without callbacks or shared state
- **Deep linking** — expressive factory methods that rebuild your navigation stack from a URL or push notification
- **Tab navigation** — independent navigation stacks per tab, with cross-tab programmatic control
- **Testability** — a `RouterModel` protocol that makes navigation fully mockable in unit tests

---

## Getting Started

Add swift-routing via Swift Package Manager:

```swift
// Package.swift
.package(url: "https://github.com/lowki93/swift-routing", from: "1.0.0")
```

The full source, documentation, and example app are on [GitHub](https://github.com/lowki93/swift-routing).

---

*Next: [Two-Way Navigation in SwiftUI: The RouteContext Pattern](#)*
