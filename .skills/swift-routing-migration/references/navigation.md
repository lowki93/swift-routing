# Step 2 — Navigation Calls

## Push

```swift
// Before
path.append("detail")

// After
router.push(HomeRoute.detail(id: 42))
```

`NavigationLink` is also supported for user-driven push navigation:

```swift
NavigationLink("View Details", route: HomeRoute.detail(id: 42))
```

`NavigationLink(route:)` is push-only — do not use it for modal flows.

## Sheet

```swift
// Before
@State private var showSettings = false

Button("Open Settings") { showSettings = true }
    .sheet(isPresented: $showSettings) { SettingsView() }

// After
router.present(HomeRoute.settings)
```

If the sheet needs `presentationDetents` or `presentationDragIndicator`, present without a nav stack:

```swift
router.present(HomeRoute.settings, withStack: false)

// Or set it on the route
var routingType: RoutingType { .sheet(withStack: false) }
```

## Full-Screen Cover

```swift
// Before
@State private var showOnboarding = false

Button("Start") { showOnboarding = true }
    .fullScreenCover(isPresented: $showOnboarding) { OnboardingView() }

// After
router.cover(HomeRoute.onboarding)
```

## Dismiss

```swift
// Before
@Environment(\.dismiss) private var dismiss
Button("Close") { dismiss() }

// After
@Environment(\.router) private var router
Button("Close") { router.close() }
```

`router.close()` is a no-op if the router is not presented.
