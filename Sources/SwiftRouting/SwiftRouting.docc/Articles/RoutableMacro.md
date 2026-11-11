# Generating Route Names and Routing Types with @Routable

Generate a route's `name` (and, optionally, its `routingType`) from its cases instead of writing the `switch` by hand.

## Overview

Every ``Route`` needs a `name`, used for logging, debugging and analytics. For most enums this is a mechanical `switch` over the cases. The `@Routable` macro writes that `switch` for you, and `@RouteName` overrides the cases that need a custom format. `@Sheet` and `@Cover` mark the cases that are presented modally so `@Routable` can generate `routingType` too. Tabs get the same treatment: `@TabRoutable` generates a ``TabRoute``'s `name`, and `@HideTabBarOnPush` marks the tabs that hide the tab bar when pushing, so it can generate `hideTabBarOnPush`.

The macros ship in a separate, opt-in product so that apps which don't use them never compile swift-syntax.

## Installation

Add the `SwiftRoutingMacros` product next to `SwiftRouting`:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SwiftRouting", package: "swift-routing"),
        .product(name: "SwiftRoutingMacros", package: "swift-routing"),
    ]
)
```

Then import it where your routes are declared:

```swift
import SwiftRoutingMacros
```

`SwiftRoutingMacros` re-exports `SwiftRouting`, so this single import gives you both the macros and the rest of the library. Writing `import SwiftRouting` as well still compiles.

## Default Names

Attach `@Routable` to the enum. Each case without an override is named after itself. `nameStyle` sets the format:

```swift
@Routable(nameStyle: .capitalized)
enum AppRoute {
    case profile
    case search
}
// AppRoute.profile.name == "Profile"
// AppRoute.search.name == "Search"
```

| `nameStyle` | `.profile` becomes |
|---|---|
| `.verbatim` (default) | `"profile"` |
| `.capitalized` | `"Profile"` |

`nameStyle` must be written as a literal (`.verbatim` or `.capitalized`), since the macro reads it from source.

`@Routable` also adds the `Route` conformance, so `: Route` is optional. Writing it explicitly still compiles.

## Overriding a Case

Use `@RouteName` with a raw string literal. Associated values are available by their label, or as `arg0`, `arg1`, ... (by position) when they have no label:

```swift
@Routable
enum PlayersRoute {
    @RouteName(#"Players(\(arg0))"#)
    case list(PlayerType)

    @RouteName(#"Player(\(arg0.name))"#)
    case detail(Player)
}

@Routable
enum NotificationsRoute {
    @RouteName(#"Notifications"#)
    case list

    @RouteName(#"Notification(\(id))"#)
    case detail(id: Int)
}
```

Positions count every associated value, labeled or not. In a case mixing both, the labeled value keeps its label and the unlabeled one uses its position:

```swift
@Routable
enum OrderRoute {
    @RouteName(#"Order(\(id), \(arg1))"#)
    case detail(id: String, OrderTab)
}
// OrderRoute.detail(id: "42", .shipping).name == "Order(42, shipping)"
```

> Important: The template must be a raw string literal (`#"..."#`). A regular string with `\(id)` doesn't compile, because `id` isn't in scope where the attribute is written. In a raw string, `\(...)` is plain text that the macro copies into the generated `switch`, where the value is in scope.

## Composing Child Routes

When a case wraps another ``Route``, `@RouteName(.delegate)` appends the child's name to the case name:

```swift
@Routable(nameStyle: .capitalized)
enum AppRoute {
    @RouteName(.delegate)
    case notifications(NotificationsRoute)
}
// AppRoute.notifications(.detail(id: 1)).name == "Notifications.Notification(1)"
```

The prefix follows the enum's `nameStyle`. `.delegate` requires exactly one associated value.

## Presentation Style

Mark a case with `@Sheet` or `@Cover` and `@Routable` also generates `routingType`:

```swift
@Routable
enum AppRoute {
    case home
    @Sheet(withStack: true)
    case settings
    @Cover
    case onboarding
    case order(id: String)
}
// AppRoute.home.routingType == .push
// AppRoute.settings.routingType == .sheet(withStack: true)
// AppRoute.onboarding.routingType == .cover
// AppRoute.order(id: "1").routingType == .push
```

| Marker | Generated `routingType` |
|---|---|
| none | `.push` |
| `@Sheet` or `@Sheet()` | `.sheet(withStack: true)` |
| `@Sheet(withStack: false)` | `.sheet(withStack: false)` |
| `@Cover` | `.cover` |

- `routingType` is generated only when at least one case has a marker. Without any marker nothing is generated, so the default `.push` of ``Route`` applies and a hand-written `routingType` keeps compiling.
- Markers compose with `@RouteName(.delegate)`. `.delegate` only affects `name`; the parent's marker decides the `routingType` (the child's `routingType` is never consulted). `@Sheet @RouteName(.delegate) case form(FormRoute)` presents the child flow in a sheet and derives its name from the child.
- A marker on a case declaring several elements (`@Cover case a, b`) applies to every element.
- `withStack` must be a literal `true` or `false`.
- The generated property uses the enum's access level, like `name`.

## Tab Routes

Attach `@TabRoutable` to a ``TabRoute`` enum instead of `@Routable`. The `name` is generated exactly as above: same `nameStyle`, same `@RouteName` overrides and `.delegate` composition, same compile-time checks. `@TabRoutable` also adds the ``TabRoute`` conformance, so `: TabRoute` is optional.

Mark a case with `@HideTabBarOnPush` and `@TabRoutable` also generates `hideTabBarOnPush`:

```swift
@TabRoutable
enum HomeTab {
    @HideTabBarOnPush
    case home
    case notifications
    case profile
}
// HomeTab.home.hideTabBarOnPush == true
// HomeTab.notifications.hideTabBarOnPush == false
// HomeTab.profile.hideTabBarOnPush == false
```

| Marked cases | Generated `hideTabBarOnPush` |
|---|---|
| none | nothing, the ``TabRoute`` default (`false`) applies |
| some | a `switch` with `true` for marked cases and `false` for the others |
| all | a constant `true` |

- A marker on a case declaring several elements (`@HideTabBarOnPush case a, b`) applies to every element.
- The generated property uses the enum's access level, like `name`.
- `@TabRoutable` never generates `routingType`: tabs are selected, never presented. `@Sheet` and `@Cover` in a `@TabRoutable` enum are errors.
- `@HideTabBarOnPush` is an error anywhere other than a case of a `@TabRoutable` enum, including a hand-written ``TabRoute`` or a `@Routable` enum. Without that check the tab bar would silently stay visible.

## Compile-Time Checks

The macros report mistakes on the attribute itself:

- `@Routable` attached to something other than an enum.
- `nameStyle` that isn't a literal `.verbatim` or `.capitalized`.
- `@RouteName` on a case declaring several elements (`case a, b`).
- `@RouteName` argument that is neither a raw string nor `.delegate`.
- A template referencing a name that isn't one of the case's associated values (for example `\(idd)` instead of `\(id)`).
- `.delegate` on a case without exactly one associated value.
- `@Sheet` or `@Cover` on something other than an enum case.
- Several routing type markers on the same case (`@Sheet @Cover`, or the same marker twice). A case can carry only one.
- `withStack` that isn't a literal `true` or `false`.
- A marker combined with a hand-written `routingType` in the enum body.
- `@TabRoutable` attached to something other than an enum.
- `@HideTabBarOnPush` on something other than an enum case, or on a case outside a `@TabRoutable` enum.
- `@HideTabBarOnPush` applied twice to the same case.
- `@HideTabBarOnPush` combined with a hand-written `hideTabBarOnPush` in the enum body.
- `@Sheet` or `@Cover` in a `@TabRoutable` enum.

Only the first identifier of each `\(...)` is checked. Errors further in the expression, such as a missing property in `\(arg0.title)`, are reported by the compiler on the generated code.

## Limits

- There is no marker for `.root`. An enum that needs it keeps a hand-written `routingType` (and then uses no markers), as described in <doc:DefiningRoutes>.
- Module-qualified `@SwiftRoutingMacros.RouteName` isn't recognised, so the case keeps its default name. The markers (`@Sheet`, `@Cover`, `@HideTabBarOnPush`) are recognised in both spellings.
- A `routingType` declared in a separate extension isn't detected when combined with markers; the compiler reports a redeclaration instead. The same goes for `hideTabBarOnPush` and `@HideTabBarOnPush`.
- The generated `name` uses the enum's access level (`public`, `package` or internal).
- Raw strings using `\#(...)` interpolation aren't supported.

## Topics

### Related

- <doc:DefiningRoutes>
- <doc:TabNavigation>
- ``Route``
- ``TabRoute``
