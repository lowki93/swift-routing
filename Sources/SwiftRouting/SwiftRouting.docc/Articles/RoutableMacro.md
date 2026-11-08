# Generating Route Names with @Routable

Generate a route's `name` from its cases instead of writing the `switch` by hand.

## Overview

Every ``Route`` needs a `name`, used for logging, debugging and analytics. For most enums this is a mechanical `switch` over the cases. The `@Routable` macro writes that `switch` for you, and `@RouteName` overrides the cases that need a custom format.

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
import SwiftRouting
import SwiftRoutingMacros
```

> Note: Both imports are needed. `SwiftRoutingMacros` doesn't re-export `SwiftRouting`: an `@_exported import` would let you write a single import, but `@_exported` isn't an official Swift API, so the package keeps the two imports explicit.

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

## Compile-Time Checks

The macros report mistakes on the attribute itself:

- `@Routable` attached to something other than an enum.
- `nameStyle` that isn't a literal `.verbatim` or `.capitalized`.
- `@RouteName` on a case declaring several elements (`case a, b`).
- `@RouteName` argument that is neither a raw string nor `.delegate`.
- A template referencing a name that isn't one of the case's associated values (for example `\(idd)` instead of `\(id)`).
- `.delegate` on a case without exactly one associated value.

Only the first identifier of each `\(...)` is checked. Errors further in the expression, such as a missing property in `\(arg0.title)`, are reported by the compiler on the generated code.

## Limits

- `@Routable` generates `name` only. Set `routingType` by hand, as described in <doc:DefiningRoutes>.
- The generated `name` uses the enum's access level (`public`, `package` or internal).
- Raw strings using `\#(...)` interpolation aren't supported.

## Topics

### Related

- <doc:DefiningRoutes>
- ``Route``
