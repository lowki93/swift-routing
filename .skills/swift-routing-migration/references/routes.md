# Step 1 — Routes and NavigationStack

## Define a Route Enum

Replace `navigationDestination` registrations with a `Route` enum:

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
```

One enum per feature or flow. The `name` property is used for logging and diagnostics.

## Map Routes to Views

Conform to `RouteDestination` to associate each route with a view:

```swift
extension HomeRoute: RouteDestination {
    static func view(for route: HomeRoute) -> some View {
        switch route {
        case .home: HomeView()
        case .detail(let id): DetailView(id: id)
        case .settings: SettingsView()
        }
    }
}
```

Keep this mapping deterministic and side-effect free.

## Replace NavigationStack

```swift
// Before
@State private var path = NavigationPath()

var body: some View {
    NavigationStack(path: $path) {
        HomeView()
            .navigationDestination(for: String.self) { value in
                switch value {
                case "detail": DetailView()
                case "settings": SettingsView()
                default: EmptyView()
                }
            }
    }
}

// After
var body: some View {
    RoutingView(destination: HomeRoute.self, root: .home)
}
```

All `navigationDestination` registrations are replaced by the single `RouteDestination` conformance.
