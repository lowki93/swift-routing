//
//  Routable.swift
//  SwiftRoutingMacros
//

// Re-exported so adopters only need `import SwiftRoutingMacros`.
@_exported import SwiftRouting

/// Controls the format used for a case's `name` when it has no `@RouteName` override.
/// Used by ``Routable(nameStyle:)`` and ``TabRoutable(nameStyle:)``.
///
/// Choose the style that matches the names your routes already report, so logs and
/// analytics stay unchanged when you adopt the macro. The style also sets the prefix
/// written by `@RouteName(.delegate)`:
///
/// ```swift
/// @Routable(nameStyle: .capitalized)
/// enum AppRoute {
///   case profile // "Profile"
///   @RouteName(.delegate)
///   case notifications(NotificationsRoute) // "Notifications.<child name>"
/// }
/// ```
public enum RouteNameStyle: Sendable {
  /// The case name as written (`.profile` -> `"profile"`). Matches the convention used
  /// throughout this package's own test routes.
  case verbatim
  /// The case name with its first character uppercased (`.profile` -> `"Profile"`).
  case capitalized
}

/// The argument accepted by `@RouteName`.
///
/// Write a raw string literal for a template (`#"Profile(\(id))"#`), or `.delegate` to
/// compose with an associated value that is itself a `Route` (see ``RouteName(_:)``).
///
/// ```swift
/// @RouteName(#"Notification(\(id))"#)
/// case detail(id: Int)
/// @RouteName(.delegate)
/// case notifications(NotificationsRoute)
/// ```
///
/// `RouteNameTemplate` has no runtime behavior of its own -- `@Routable` or `@TabRoutable` reads the attribute's
/// source text directly during macro expansion, it never evaluates this type's `init`.
public struct RouteNameTemplate: ExpressibleByStringLiteral, Sendable {
  /// Creates a template from a raw string literal. The value is never used at runtime:
  /// ``Routable(nameStyle:)`` and ``TabRoutable(nameStyle:)`` read the literal from source.
  public init(stringLiteral value: String) {}

  private init() {}

  /// Delegates this case's `name` to the `.name` of its single associated value, prefixed
  /// with the case name formatted per the enclosing `@Routable` / `@TabRoutable` (`nameStyle:`).
  public static let delegate = RouteNameTemplate()
}

/// Generates `var name: String` (and, with `@Sheet` / `@Cover` markers, `var routingType`) for an enum conforming to ``Route``, from its cases.
///
/// Attach to an enum whose cases should each report a name derived from the case itself.
/// Also adds the ``Route`` conformance via an extension -- `: Route` becomes optional on the
/// annotated enum (writing it explicitly still compiles, the macro simply adds nothing in
/// that case).
///
/// ## Default formatting
///
/// A case without `@RouteName` gets its name from `nameStyle`:
///
/// ```swift
/// @Routable(nameStyle: .capitalized)
/// enum AppRoute {
///   case profile
///   case search
/// }
/// // AppRoute.profile.name == "Profile"
/// // AppRoute.search.name == "Search"
/// ```
///
/// ## Overriding a case's name
///
/// Use `@RouteName` with a raw string literal. A labeled associated value is available by
/// its label (and has no `argN` name). An unlabeled one is available as `arg` followed by
/// its zero-based position among all the associated values, labeled or not. A `_` label
/// counts as unlabeled. Using any other name is a compile-time error listing the available
/// names:
///
/// ```swift
/// @Routable
/// enum NotificationsRoute {
///   @RouteName(#"Notifications"#)
///   case list
///   @RouteName(#"Notification(\(id))"#)
///   case detail(id: Int)
/// }
///
/// @Routable
/// enum PlayersRoute {
///   @RouteName(#"Players(\(arg0))"#)
///   case list(PlayerType)
///   @RouteName(#"Player(\(arg0.name))"#)
///   case detail(Player)
/// }
/// ```
///
/// A case mixing both keeps the label and counts the position across all values:
///
/// ```swift
/// @Routable
/// enum OrderRoute {
///   // arg0 doesn't exist here: the first value is labeled, so it's id.
///   @RouteName(#"Order(\(id), \(arg1))"#)
///   case detail(id: String, OrderTab)
/// }
/// // OrderRoute.detail(id: "42", .shipping).name == "Order(42, shipping)"
/// ```
///
/// A template must be a raw string literal (`#"..."#`) -- a plain string with real
/// interpolation (`"\(id)"`) fails to compile before the macro even runs, since `id` isn't in
/// scope at the attribute's position. The raw string's text is reinjected verbatim into the
/// generated `switch`, where the associated value genuinely is in scope.
///
/// ## Composing with a child route
///
/// A case whose single associated value is itself a ``Route`` can delegate instead of
/// repeating `.name` by hand:
///
/// ```swift
/// @Routable(nameStyle: .capitalized)
/// enum AppRoute {
///   @RouteName(.delegate)
///   case notifications(NotificationsRoute)
/// }
/// // AppRoute.notifications(.detail(id: 1)).name == "Notifications.Notification(1)"
/// ```
///
/// `.delegate` requires the case to have exactly one associated value.
///
/// ## Presentation style
///
/// Mark cases with ``Sheet(withStack:)`` or ``Cover()`` to also generate `routingType`:
///
/// ```swift
/// @Routable
/// enum AppRoute {
///   case home
///   @Sheet(withStack: true)
///   case settings
///   @Cover
///   case onboarding
/// }
/// // AppRoute.home.routingType == .push
/// // AppRoute.settings.routingType == .sheet(withStack: true)
/// // AppRoute.onboarding.routingType == .cover
/// ```
///
/// Unmarked cases are `.push`. `routingType` is generated only when at least one case has a
/// marker; without markers nothing is generated and the ``Route`` default applies. Markers
/// cannot be combined with a hand-written `routingType` in the enum body, and there is no
/// marker for `.root` -- write `routingType` by hand for that.
///
/// - Parameter nameStyle: The format of names for cases without ``RouteName(_:)``.
///   Defaults to ``RouteNameStyle/verbatim``. Must be written as a literal.
@attached(member, names: named(name), named(routingType))
@attached(extension, conformances: Route)
public macro Routable(nameStyle: RouteNameStyle = .verbatim) = #externalMacro(module: "SwiftRoutingMacrosPlugin", type: "RoutableMacro")

/// Overrides the `name` generated by ``Routable(nameStyle:)`` or ``TabRoutable(nameStyle:)``
/// for a single enum case.
///
/// ```swift
/// @RouteName(#"Notification(\(id))"#)   // labeled value, by label
/// case detail(id: Int)
/// @RouteName(#"Player(\(arg0.name))"#)  // unlabeled value, by position
/// case player(Player)
/// @RouteName(.delegate)                  // single child Route
/// case notifications(NotificationsRoute)
/// ```
///
/// See ``Routable(nameStyle:)`` for how associated values are named.
///
/// - Parameter template: A raw string literal (`#"..."#`) or `.delegate`.
@attached(peer)
public macro RouteName(_ template: RouteNameTemplate) = #externalMacro(module: "SwiftRoutingMacrosPlugin", type: "RouteNameMacro")

/// Marks an enum case as presented in a sheet, so `@Routable` generates `routingType` for it.
///
/// ```swift
/// @Routable
/// enum AppRoute {
///   case home
///   @Sheet
///   case settings
///   @Sheet(withStack: false)
///   case filters
/// }
/// // AppRoute.settings.routingType -> .sheet(withStack: true)
/// ```
///
/// See ``Routable(nameStyle:)`` for the full description of the generated `routingType`.
///
/// - Parameter withStack: Whether the sheet hosts its own navigation stack. Defaults to
///   `true`. Must be a literal `true` or `false`.
@attached(peer)
public macro Sheet(withStack: Bool = true) = #externalMacro(module: "SwiftRoutingMacrosPlugin", type: "SheetMacro")

/// Marks an enum case as presented as a full-screen cover, so `@Routable` generates
/// `routingType` for it.
///
/// ```swift
/// @Routable
/// enum AppRoute {
///   case home
///   @Cover
///   case onboarding
/// }
/// // AppRoute.onboarding.routingType -> .cover
/// ```
///
/// See ``Routable(nameStyle:)`` for the full description of the generated `routingType`.
@attached(peer)
public macro Cover() = #externalMacro(module: "SwiftRoutingMacrosPlugin", type: "CoverMacro")
