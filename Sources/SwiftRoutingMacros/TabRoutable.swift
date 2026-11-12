//
//  TabRoutable.swift
//  SwiftRoutingMacros
//

// Re-exported so adopters only need `import SwiftRoutingMacros`.
@_exported import SwiftRouting

/// Generates `var name: String` (and, with `@HideTabBarOnPush` markers, `var hideTabBarOnPush`) for an enum conforming to ``TabRoute``, from its cases.
///
/// The `name` is generated exactly like ``Routable(nameStyle:)`` does: same `nameStyle`, same
/// `@RouteName` overrides and `.delegate` composition, same compile-time checks. See
/// ``Routable(nameStyle:)`` for the full set of examples.
///
/// Also adds the ``TabRoute`` conformance via an extension -- `: TabRoute` becomes optional
/// on the annotated enum (writing it explicitly still compiles, the macro simply adds
/// nothing in that case).
///
/// ## Hiding the tab bar on push
///
/// Mark cases with `@HideTabBarOnPush` to also generate `hideTabBarOnPush`:
///
/// ```swift
/// @TabRoutable
/// enum HomeTab {
///   @HideTabBarOnPush
///   case home
///   case notifications
///   case profile
/// }
/// // HomeTab.home.hideTabBarOnPush == true
/// // HomeTab.notifications.hideTabBarOnPush == false
/// // HomeTab.profile.hideTabBarOnPush == false
/// ```
///
/// - No marked case: nothing is generated and the ``TabRoute`` default (`false`) applies.
/// - Some marked cases: a `switch` with one line per case (`true` for marked, `false` otherwise).
/// - All cases marked: a constant `true`.
///
/// A marker on a multi-element case (`@HideTabBarOnPush case a, b`) applies to every element.
/// Markers cannot be combined with a hand-written `hideTabBarOnPush` in the enum body.
///
/// ## No routing type
///
/// `@TabRoutable` never generates `routingType`: tabs are selected, never presented.
/// ``Sheet(withStack:)`` / ``Cover()`` in a `@TabRoutable` enum are rejected at compile time.
///
/// - Parameter nameStyle: The format of names for cases without ``RouteName(_:)``.
///   Defaults to ``RouteNameStyle/verbatim``. Must be written as a literal.
@attached(member, names: named(name), named(hideTabBarOnPush))
@attached(extension, conformances: TabRoute)
public macro TabRoutable(nameStyle: RouteNameStyle = .verbatim) = #externalMacro(module: "SwiftRoutingMacrosPlugin", type: "TabRoutableMacro")

/// Marks an enum case of a `@TabRoutable` enum as hiding the tab bar when views are pushed
/// onto its navigation stack, so ``TabRoutable(nameStyle:)`` generates `hideTabBarOnPush` for it.
///
/// ```swift
/// @TabRoutable
/// enum HomeTab {
///   @HideTabBarOnPush
///   case home
///   case profile
/// }
/// // HomeTab.home.hideTabBarOnPush -> true
/// ```
///
/// The enum must be annotated with `@TabRoutable`; using the marker anywhere else is a
/// compile-time error. See ``TabRoutable(nameStyle:)`` for the full description of the generated property.
@attached(peer)
public macro HideTabBarOnPush() = #externalMacro(module: "SwiftRoutingMacrosPlugin", type: "HideTabBarOnPushMacro")
