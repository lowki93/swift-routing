# Macros

Use this guide to generate `name`, `routingType` and `hideTabBarOnPush` with the opt-in `@Routable` / `@TabRoutable` macros instead of hand-writing them.

The official documentation is the DocC article "Macros".

## Availability Check (Do This First)

The macros ship in the opt-in `SwiftRoutingMacros` product, available from swift-routing 1.1.0.

Detect it in the project:
- `.product(name: "SwiftRoutingMacros", package: "swift-routing")` in `Package.swift`
- `SwiftRoutingMacros` in `*.xcodeproj/project.pbxproj`
- an existing `import SwiftRoutingMacros`
- a resolved swift-routing version of 1.1.0 or later in `Package.resolved`

Then decide:
- Present: prefer the macros for NEW `Route` / `TabRoute` enums.
- Absent: hand-write `name` (see `routes.md` and `tab-router.md`). You may suggest adding the product, but never add it unasked: the target then builds swift-syntax.
- Don't convert existing hand-written enums unless asked (see "Adopting Macros On An Existing Enum").

`import SwiftRoutingMacros` re-exports `SwiftRouting`, so one import is enough. Keeping `import SwiftRouting` as well still compiles.

## What Gets Generated

| Macro | Generated members | Conformance added |
|---|---|---|
| `@Routable(nameStyle:)` | `name`, plus `routingType` only if a case has `@Sheet` / `@Cover` | `: Route` |
| `@TabRoutable(nameStyle:)` | `name`, plus `hideTabBarOnPush` only if a case has `@HideTabBarOnPush` | `: TabRoute` |

- Writing `: Route` / `: TabRoute` explicitly still compiles.
- Generated members use the enum's access level (`public`, `package`, or no modifier otherwise).
- Still hand-written: the `RouteDestination` mapping and deep links.

## Names

The default name is the case name formatted by `nameStyle`. Associated values are NOT included: `case detail(id: Int)` is named `"detail"`.

| `nameStyle` | `.profile` becomes |
|---|---|
| `.verbatim` (default) | `"profile"` |
| `.capitalized` | `"Profile"` (only the first character is uppercased) |

`nameStyle` must be a literal (`.verbatim` or `.capitalized`).

Choosing a style:
- Match the names the project already reports (name switches in other enums, analytics).
- No convention: use `.verbatim`.
- The style also sets the prefix written by `@RouteName(.delegate)` (`"Notifications."` vs `"notifications."`).

### When `@RouteName` Is Mandatory

Rule: whenever the wanted name differs from the default (the formatted case name).

| Wanted name | What to write |
|---|---|
| The formatted case name | Nothing |
| Includes values, e.g. `detail(42)` | `@RouteName(#"detail(\(id))"#)` |
| A different constant (case `flow` named `FormFlow`) | `@RouteName(#"FormFlow"#)` |
| Casing different from the style | A constant template |
| `<formatted case>.<child.name>` | `@RouteName(.delegate)` |
| Composition with another prefix | `@RouteName(#"Notifications.\(arg0.name)"#)` |

Never leave a composition case (one wrapping another `Route`) on the default name: it drops the child's name.

### Names Available In A Template

| Case | Names |
|---|---|
| `detail(id: Int)` | `id` |
| `list(PlayerType)` | `arg0` |
| `detail(_ id: Int)` | `arg0` (`id` is an error) |
| `detail(id: String, OrderTab)` | `id`, `arg1` (no `arg0`) |

- A labeled value uses its label. An unlabeled or `_` value uses `argN`, where N is its position among ALL the values.
- `.delegate` uses the single associated value, whatever its name.
- The template must be a raw string `#"..."#`. In a regular string, `\(id)` doesn't compile.
- Member access works (`\(arg0.name)`), but the macro only checks the first identifier.
- `case a, b` gets default names. `@RouteName` on it is an error: split the cases.

## Presentation Style (routingType)

| Marker | Generated `routingType` |
|---|---|
| none | `.push` |
| `@Sheet` / `@Sheet()` | `.sheet(withStack: true)` |
| `@Sheet(withStack: false)` | `.sheet(withStack: false)` |
| `@Cover` | `.cover` |

- `withStack` must be a literal `true` or `false`.
- No markers in the enum: nothing is generated. The protocol default `.push` applies, or a hand-written `routingType` keeps working.
- `.root` has no marker: keep a hand-written `routingType` and use no markers in that enum.
- With `.delegate`, the parent's marker decides: `@Sheet @RouteName(.delegate) case form(FormRoute)` gives `.sheet(withStack: true)` and a name like `"form.FormFlow"` (verbatim style).
- A marker on `case a, b` applies to both.
- `routingType` is read only by `router.route(_:)`. `push`, `present` and `cover` ignore it.
- Use `@Sheet(withStack: false)` when the destination applies `presentationDetents` (see `routes.md`).

## Tabs

Use `@TabRoutable` on a `TabRoute` enum, not `@Routable`. (`@HideTabBarOnPush` is an error in a `@Routable` enum.)

```swift
@TabRoutable
enum HomeTab {
  @HideTabBarOnPush
  case home
  case notifications
  case profile
}
// HomeTab.home.hideTabBarOnPush == true
// HomeTab.profile.hideTabBarOnPush == false
```

| Marked cases | Generated `hideTabBarOnPush` |
|---|---|
| none | nothing (default `false`) |
| some | a `switch` with `true` for marked cases |
| all | a constant `true` |

`@Sheet` / `@Cover` in a `@TabRoutable` enum are errors.

## Syntax Cheatsheet

```swift
import SwiftRoutingMacros

@Routable(nameStyle: .capitalized)
enum AppRoute {
  case profile                                        // "Profile"
  @RouteName(#"Home(\(name))"#)
  case home(name: String)                             // "Home(Kevin)"
  @RouteName(.delegate)
  case notifications(NotificationsRoute)              // "Notifications.Notification(1)"
  @RouteName(.delegate)
  case players(PlayersRoute)                          // "Players.Player(Mbappé)"
  @Sheet(withStack: false)
  case filters                                        // routingType.description == "sheet(withStack: false)"
  @Cover
  case onboarding                                     // routingType.description == "cover"
  @Sheet
  @RouteName(.delegate)
  case form(FormRoute)                                // "Form.FormFlow", sheet(withStack: true)
}

@Routable(nameStyle: .capitalized)
enum NotificationsRoute {
  @RouteName(#"Notifications"#)
  case list
  @RouteName(#"Notification(\(id))"#)
  case detail(id: Int)
}

@Routable
enum PlayersRoute {
  @RouteName(#"Player(\(arg0.name))"#)
  case detail(Player)
}

@Routable
enum FormRoute {
  @RouteName(#"FormFlow"#)
  case flow
}

@Routable
enum OrderRoute {
  @RouteName(#"Order(\(id), \(arg1))"#)
  case detail(id: String, OrderTab)                   // detail(id: "42", .shipping) -> "Order(42, shipping)"
}
```

## Adopting Macros On An Existing Enum

Only when asked.

1. Record the names the enum reports today.
2. Pick the `nameStyle` that matches them.
3. Delete `var name`: the macro always emits `name`, so keeping it is a redeclaration error.
4. Add `@RouteName` on every case whose output differs.
5. `routingType`: if the cases only use push / sheet / cover, add markers and delete the property, including copies in extensions. If any case uses `.root`, keep it hand-written and add no markers. The same applies to `hideTabBarOnPush`.
6. Add a parity test:

```swift
@Test(arguments: [
  (AppRoute.profile, "Profile"),
  (AppRoute.notifications(.detail(id: 1)), "Notifications.Notification(1)"),
])
func appRouteCases_name_matchPreviousSwitch(route: AppRoute, expected: String) {
  #expect(route.name == expected)
}
```

For `routingType`, compare `route.routingType.description`.

## Compile Errors -> Fix

| Message | Fix |
|---|---|
| `'@Routable' can only be applied to an enum` (same for `@TabRoutable`) | Attach the macro to an enum. |
| `` 'nameStyle' must be a literal `.verbatim` or `.capitalized` `` | Write the style literally, not through a variable. |
| `` '@RouteName' cannot be applied to a case declaration with multiple elements (`case a, b`) -- split them into separate cases `` | One case per declaration. |
| `` '@RouteName' expects a raw string literal (`#"..."#`) or `.delegate` `` | Use `#"..."#` or `.delegate`. |
| `'x' is not an associated value of this case. Available: …` | Use a name from the list (label, or `argN` by position). |
| `'@RouteName(.delegate)' requires exactly one associated value on this case` | Wrap exactly one child route, or use a template. |
| `'@Cover' conflicts with '@Sheet' on the same case -- a case can have only one routing type marker` | Keep one marker per case. |
| `'@Sheet' is applied more than once to this case` | Remove the duplicate. |
| `` 'withStack' must be a literal `true` or `false` `` | Write `true` or `false`. |
| `'@Sheet' cannot be combined with a hand-written 'routingType' -- remove the marker or the property` | Keep only the markers, or only the property (required for `.root`). |
| `'@HideTabBarOnPush' can only be applied to a case of a '@TabRoutable' enum` | Move it into a `@TabRoutable` enum. |
| `'@Sheet' cannot be used in a '@TabRoutable' enum -- a tab is selected, never presented` | Remove it. |
| `'@Sheet' can only be applied to an enum case` | Put the marker on a case. |

The marker name in a message follows the marker used (`@Sheet`, `@Cover`, `@HideTabBarOnPush`). A hand-written `hideTabBarOnPush` next to `@HideTabBarOnPush` reports the same "cannot be combined" message.

Compiler-level errors:

| Error | Fix |
|---|---|
| `unknown attribute 'Routable'` (or "cannot find macro") | Add `import SwiftRoutingMacros`; check the target depends on the `SwiftRoutingMacros` product (see Availability Check). |
| `invalid redeclaration of 'name'` / `'routingType'` / `'hideTabBarOnPush'` | Delete the hand-written copy (in the body or an extension). Also happens with both `@Routable` and `@TabRoutable` on one enum: keep one. |
| Error inside generated code from an `argN` label collision, or a bad member in `\(arg0.title)` | Avoid `argN` labels; check the member exists on the value. |

## Don't

- Don't expect `@Sheet` / `@Cover` / `@RouteName` to work in an enum without `@Routable` (or `@TabRoutable` for `@RouteName`): they are silently ignored (`routingType` stays `.push`, the name stays hand-written). `@HideTabBarOnPush` outside `@TabRoutable` is a compile error. `@SwiftRoutingMacros.RouteName` is silently ignored too; the markers accept the qualified spelling.
- Don't keep a hand-written `name` in an enum with `@Routable` / `@TabRoutable`.
- Don't mix markers with a hand-written `routingType` / `hideTabBarOnPush`, in the body or in an extension.
- Don't use non-raw templates.
- Don't use `argN` labels.
- Don't use `@HideTabBarOnPush` outside `@TabRoutable`.
- Don't use `@Sheet` / `@Cover` in `@TabRoutable`.
- Don't put two markers on a case.
- Don't pass a non-literal `nameStyle` or `withStack`.
- Don't expect the macros to write `RouteDestination` or deep links.
- Don't change existing route names when adopting the macros.
