# Router

Use this guide for programmatic navigation with `Router` and `RouterModel`.

## Access Router In Views

In SwiftUI views, read the router from environment:

```swift
struct HomeView: View {
  @Environment(\.router) private var router

  var body: some View {
    Button("Open detail") {
      router.push(HomeRoute.detail(id: 42))
    }
  }
}
```

## Core Navigation Methods

- `push(_:)`: push onto the stack
- `present(_:withStack:)`: present as sheet (optional nested stack)
- `cover(_:)`: present as full-screen cover
- `back()`: pop one level
- `popToRoot()`: clear stack path and return to root
- `update(root:)`: replace root route
- `close()`: dismiss current presented router
- `closeChildren()`: dismiss presented child routers

## Typical Usage

```swift
router.push(HomeRoute.detail(id: 42))
router.present(HomeRoute.settings)                 // withStack defaults to true
router.present(HomeRoute.settings, withStack: false)
router.cover(HomeRoute.onboarding)

router.back()
router.popToRoot()
router.update(root: HomeRoute.dashboard)
```

## route(_:) and routingType

`route(_:)` dispatches based on each route's `routingType`:

```swift
router.route(HomeRoute.settings)
```

Use this when route presentation policy is encoded in the route type itself.

## Useful Router Properties

- `currentRoute`: currently visible route (`AnyRoute`)
- `isPresented`: `true` if current router is shown as sheet/cover
- `routeCount`: number of routes in the stack including root

Example:

```swift
if router.isPresented {
  Button("Close") { router.close() }
}

if router.routeCount > 1 {
  Button("Back") { router.back() }
}
```

## ViewModel Injection Pattern

In ViewModels, inject `any RouterModel` (protocol), not concrete `Router`:

```swift
@MainActor
final class DetailsViewModel: ObservableObject {
  private let router: any RouterModel

  init(router: any RouterModel) {
    self.router = router
  }

  func openSettings() {
    router.present(HomeRoute.settings)
  }
}
```

## Important Notes

- In SwiftUI views, prefer `@Environment(\.router)` over passing router manually.
- Passing router as a parameter is usually for ViewModel injection.
- `close()` is effective only when the current router is presented (`isPresented == true`).
