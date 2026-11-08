import SwiftRouting
import SwiftRoutingMacros

enum MacroPlayerType: String, Hashable, Sendable {
  case footballer
  case basketballPlayer
}

struct MacroPlayer: Hashable, Sendable {
  let name: String
  let type: MacroPlayerType
}

@Routable
enum MacroPlayersRoute: Route {
  @RouteName(#"Players(\(arg0))"#)
  case list(MacroPlayerType)
  @RouteName(#"Player(\(arg0.name))"#)
  case detail(MacroPlayer)
}

@Routable
enum MacroFormRoute: Route {
  @RouteName(#"FormFlow"#)
  case flow
  @RouteName(#"Form"#)
  case entry
}

@Routable
enum MacroNotificationsRoute: Route {
  @RouteName(#"Notifications"#)
  case list
  @RouteName(#"Notification(\(id))"#)
  case detail(id: Int)
}

@Routable(nameStyle: .capitalized)
enum MacroAppRoute: Route {
  @RouteName(#"Home(\(name))"#)
  case home(name: String)
  @RouteName(.delegate)
  case notifications(MacroNotificationsRoute)
  case profile
  @RouteName(#"User(\(name))"#)
  case user(name: String)
  case search
  case settings
  case about
  case sidebar
  @RouteName(.delegate)
  case players(MacroPlayersRoute)
  @RouteName(.delegate)
  case form(MacroFormRoute)
}

enum MacroOrderTab: Hashable, Sendable {
  case shipping
}

/// Mirrors the mixed labeled/positional example in `RoutableMacro.md`.
@Routable
enum MacroOrderRoute {
  @RouteName(#"Order(\(id), \(arg1))"#)
  case detail(id: String, MacroOrderTab)
}

/// Deliberately omits `: Route` -- its conformance comes only from `@Routable`'s
/// generated extension, to prove `Hashable`/`Sendable` synthesize correctly through it.
@Routable
enum MacroSynthesizedRoute {
  @RouteName(#"d(\(id))"#)
  case detail(id: Int)
  case plain
}
