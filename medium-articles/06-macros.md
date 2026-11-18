# Killing Route Boilerplate in SwiftUI with @Routable

*Part 6 of the swift-routing series. If you're new here, start with [Part 1: Type-Safe Navigation in SwiftUI with swift-routing](https://medium.com/@budainkevin/stop-fighting-swiftui-navigation-a-type-safe-approach-with-swift-routing-7cbd328f0270), [Part 2: The RouteContext Pattern](https://medium.com/@budainkevin/two-way-navigation-in-swiftui-the-routecontext-pattern-0af28310b407), [Part 3: Tab Navigation in SwiftUI: Taming Cross-Tab Routing with TabRouter](https://medium.com/@budainkevin/tab-navigation-in-swiftui-taming-cross-tab-routing-with-tabrouter-dc7b4f595b45), [Part 4: SplitView Navigation in SwiftUI: Taming Sidebar Routing with RoutingSplitView](https://medium.com/@budainkevin/splitview-navigation-in-swiftui-taming-sidebar-routing-with-routingsplitview-b19cf97bfa9b), and [Part 5: Testing SwiftUI Navigation Without Mounting a Single View](https://medium.com/@budainkevin/testing-swiftui-navigation-without-mounting-a-single-view-43e8ef870716)*

Every `Route` needs a `name`. It shows up in logs, in debugging, and in analytics. For most enums, writing it is pure typing: one `switch`, one line per case, the case name in quotes.

That's boilerplate. And boilerplate is where bugs hide.

Swift-routing 1.1.0 ships macros that write it for you. This article walks through them on the demo app's real routes.

---

## The Problem: A Switch Nobody Wants to Write

Here is the demo app's `AppRoute`, before macros:

```swift
import SwiftRouting

enum AppRoute: Route {
  case home(name: String)
  case notifications(NotificationsRoute)
  case profile
  case search
  case settings
  case about

  var name: String {
    switch self {
    case let .home(name): "Home(\(name))"
    case let .notifications(child): "Notifications.\(child.name)"
    case .profile: "Profile"
    case .search: "Search"
    case .settings: "Settings"
    case .about: "About"
    }
  }
}
```

Six cases, six lines that repeat the case names. Add a case, and you add a line. Rename a case, and you rename it twice.

None of this is hard. It's just easy to get slightly wrong. A typo in `"Setings"` compiles fine. It only shows up later, as a new event in your analytics that nobody asked for.

It gets worse. Look at `NotificationsRoute`:

```swift
enum NotificationsRoute: Route {
  case list
  case detail(id: Int)

  var name: String {
    switch self {
    case .list: "Notifications"
    case let .detail(id): "Notification(\(id))"
    }
  }
}
```

The `list` case is named `"Notifications"`, not `"list"`. The name doesn't follow from the case. A tool that just copies case names would get it wrong.

So we need two things: free names for the mechanical cases, and an escape hatch for the others.

## Default Names with @Routable

Add the opt-in `SwiftRoutingMacros` product to your target, then attach `@Routable`:

```swift
import SwiftRoutingMacros

@Routable(nameStyle: .capitalized)
enum AppRoute {
  case profile
  case search
  case settings
  case about
}

AppRoute.profile.name // "Profile"
```

`@Routable` generates the `switch`. It also adds the `Route` conformance, so `: Route` is optional. One import is enough: `SwiftRoutingMacros` re-exports `SwiftRouting`.

The default style, `.verbatim`, uses the case name as is: `"profile"`. The demo already reported `"Profile"`, so it uses `.capitalized`. Pick the style your logs already use. Changing names silently breaks dashboards.

There's no magic behind it. In Xcode, right-click `@Routable` and choose Expand Macro. For the enum above, you'd see:

```swift
var name: String {
  switch self {
  case .profile:
    "Profile"
  case .search:
    "Search"
  case .settings:
    "Settings"
  case .about:
    "About"
  }
}
```

That's the same `switch` you would have written. The macro just writes it for you, and keeps it in sync with the cases.

## Overriding a Case with @RouteName

For cases that need a custom name, use `@RouteName` with a template:

```swift
@Routable(nameStyle: .capitalized)
enum AppRoute {
  @RouteName(#"Home(\(name))"#)
  case home(name: String)
  case profile
}

AppRoute.home(name: "Kevin").name // "Home(Kevin)"
```

Notice the `#"..."#`. It's a raw string, and that's not a style choice.

Try a normal string first:

```swift
@RouteName("Home(\(name))")
case home(name: String)
```

It doesn't compile. Swift type-checks a macro's arguments where you write them. At that point, there is no `name` value. It only exists inside a `switch`, once a case is matched. The compiler stops with:

```
instance member 'name' cannot be used on type 'AppRoute'
```

A raw string turns off interpolation. `\(name)` stays plain text, and the macro copies it into the generated `switch`. There, `name` is bound to the case's value, and the interpolation works.

The macro also catches the mistake for you, with a clearer message: `'@RouteName' expects a raw string literal`.

Labeled values are used by their label, like `name` above. Unlabeled values get positional names. In `PlayersRoute`, `arg0` is the first associated value:

```swift
@Routable
enum PlayersRoute {
  @RouteName(#"Players(\(arg0))"#)
  case list(PlayerType)
}
```

The position counts every associated value, labeled or not. In `case detail(id: String, OrderTab)`, the names are `id` and `arg1`. There is no `arg0`: the first value already has a label.

Get it wrong, and the error lists the names that do exist:

```
'arg0' is not an associated value of this case. Available: id, arg1
```

## Composing Routes with .delegate

`AppRoute` wraps `NotificationsRoute`. Its name should combine both: `"Notifications.Notification(1)"`.

```swift
@Routable(nameStyle: .capitalized)
enum AppRoute {
  @RouteName(.delegate)
  case notifications(NotificationsRoute)
}

@Routable
enum NotificationsRoute {
  @RouteName(#"Notifications"#)
  case list
  @RouteName(#"Notification(\(id))"#)
  case detail(id: Int)
}

AppRoute.notifications(.detail(id: 1)).name // "Notifications.Notification(1)"
```

`.delegate` writes the formatted case name, a dot, then the child's `name`.

Why not detect child routes automatically? Because Swift macros only see syntax. `@Routable` reads the text `NotificationsRoute`. It can't know that type conforms to `Route`, so you say it with `.delegate`. That's not a limit of this library. Every Swift macro works this way.

## Presentation Style with @Sheet and @Cover

A route can also declare how it's presented. Mark the cases:

```swift
@Routable(nameStyle: .capitalized)
enum AppRoute {
  case profile
  @Sheet(withStack: false)
  case search
  @Sheet
  case settings
  @Cover
  case about
}
```

`@Routable` now generates `routingType` too. Unmarked cases are `.push`. Call `router.route(_:)`, and each route opens the way it declared:

```swift
router.route(AppRoute.settings)
```

The call site doesn't need to know how settings open. If the design changes from a sheet to a cover, you change one marker, not every button that leads there.

This only applies to `route(_:)`. `push`, `present` and `cover` still do what they say. There's no marker for `.root`, so keep a hand-written `routingType` in that case.

A case can have only one marker. Put `@Sheet` and `@Cover` on the same case, and the build stops:

```
'@Cover' conflicts with '@Sheet' on the same case -- a case can have only one routing type marker
```

## Tabs, Too

Tab enums from Part 3 get the same treatment with `@TabRoutable`. Mark the tabs that hide the tab bar when pushing:

```swift
@TabRoutable
enum HomeTab {
  @HideTabBarOnPush
  case home
  case notifications
  case profile
}

HomeTab.home.hideTabBarOnPush // true
```

Before, `HomeTab` needed two hand-written switches: one for `name`, one for `hideTabBarOnPush`. Now it generates both, and adds the `TabRoute` conformance. Tabs without the marker keep the bar visible.

## Before and After

Before — the hand-written switch from the start of this article, repeated in every route enum.

After — the demo's `AppRoute` today:

```swift
import SwiftRoutingMacros

@Routable(nameStyle: .capitalized)
enum AppRoute {
  @RouteName(#"Home(\(name))"#)
  case home(name: String)
  @RouteName(.delegate)
  case notifications(NotificationsRoute)
  case profile
  case search
  case settings
  case about
}
```

Same names, no `switch`. Six hand-written lines became two annotations. Adding a case is one line. Most cases need no annotation at all. The ones that do carry their name right above them.

## But What About…?

### Mistakes?

They fail at compile time, on the attribute. A missing value, a normal string, two markers on one case: each one gets an error that says how to fix it.

### Build time?

Macros depend on swift-syntax. That's why they ship as a separate product. If you don't import `SwiftRoutingMacros`, you never build swift-syntax.

### Views?

`RouteDestination` stays hand-written. Building a view needs real code: models, dependencies, modifiers. Macros only generate what follows mechanically from the cases.

### Existing routes?

Nothing forces a migration. Hand-written `name` and macro-generated routes work side by side.

The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
