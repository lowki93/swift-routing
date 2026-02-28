//
//  Route.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import Foundation

/// Defines route types used to navigate between views.
///
/// A `Route` is typically an enum that represents all available destinations.
///
/// ## Defining a Route
/// Routes are defined as an enumeration with associated values when needed.
/// ```swift
/// enum HomeRoute: Route {
///   case page1
///   case page2(Int)
///   case page3(String)
///
///   public var name: String {
///     switch self {
///       case .page1: "page1"
///       case let .page2(int): "page2(\(int))"
///       case let .page3(string): "page3(\(string))"
///     }
///   }
/// }
/// ```
///
/// ## Associating a Route with a View
/// Use the `RouteDestination` protocol to map a route to a specific view.
/// The most common setup is to make your top-level route conform to `RouteDestination`:
/// ```swift
/// extension HomeRoute: @retroactive RouteDestination {
///   public static func view(for route: HomeRoute) -> some View {
///     switch route {
///       case .page1: Page1View()
///       case let .page2(value): Page2View(value: value)
///       case let .page3(value): Page3View(value: value)
///     }
///   }
/// }
/// ```
///
/// For environment-driven destination mapping, prefer a dedicated wrapper view.
/// See ``RouteDestination`` for a complete example.
///
/// ## Nested Routes
/// For larger features, you can compose routes by nesting a child route inside a parent route.
/// This keeps route definitions modular while preserving type safety.
/// ```swift
/// enum AppRoute: Route {
///   case home
///   case profile(ProfileRoute)
///
///   var name: String {
///     switch self {
///       case .home: "home"
///       case let .profile(child): "profile.\(child.name)"
///     }
///   }
/// }
///
/// enum ProfileRoute: Route {
///   case overview
///   case edit(userID: String)
///
///   var name: String {
///     switch self {
///       case .overview: "overview"
///       case let .edit(userID): "edit(\(userID))"
///     }
///   }
/// }
///
/// extension AppRoute: @retroactive RouteDestination {
///   public static func view(for route: AppRoute) -> some View {
///     switch route {
///       case .home:
///         HomeView()
///       case let .profile(child):
///         ProfileRouteDestination(route: child)
///     }
///   }
/// }
///
/// struct ProfileRouteDestination: View {
///   let route: ProfileRoute
///
///   var body: some View {
///     switch route {
///       case .overview:
///         ProfileOverviewView()
///       case let .edit(userID):
///         ProfileEditView(userID: userID)
///     }
///   }
/// }
/// ```
///
/// > Note:
/// > In this pattern, only the top-level route used by `RoutingView` (for example `AppRoute`)
/// > needs to conform to `RouteDestination`.
/// > Child route enums (for example `ProfileRoute`) can stay as plain `Route` types and be rendered
/// > through dedicated destination views like `ProfileRouteDestination`.
///
/// ## Using a Route for Navigation
/// You can trigger navigation using a router instance:
/// ```swift
/// Button("Go to Page 1") {
///   router.push(HomeRoute.page1)
/// }
/// ```
public protocol Route: Hashable, Sendable, CustomStringConvertible {
  /// The human-readable name of the route, used for logging and diagnostics.
  var name: String { get }

  /// The navigation style used when presenting this route.
  /// Determines how the router should navigate: via push, sheet, cover, root, etc.
  /// Default is `.push`, but you can override in your Route type.
  var routingType: RoutingType { get }

  /// A human-readable description of the route, typically used for debugging, logging, or displaying route information.
  /// By default, returns the route's name. You can override to provide more context if needed.
  var description: String { get }
}

public extension Route {
  var routingType: RoutingType {
    .push
  }

  var description: String {
    name
  }

  func isSame(as other: any Route) -> Bool {
    ObjectIdentifier(type(of: self)) == ObjectIdentifier(type(of: other))
      && self.hashValue == other.hashValue
  }
}

/// A type-erased wrapper for any `Route` type.
///
/// `AnyRoute` enables storing and manipulating routes of different concrete types
/// in a uniform way. It is used internally by the router to manage navigation paths
/// and presented routes.
///
/// ## Overview
///
/// Since Swift's `NavigationPath` and other navigation APIs require concrete types,
/// `AnyRoute` provides type erasure while preserving the route's identity through its hash value.
///
/// You typically don't create `AnyRoute` instances directly. The router creates them
/// automatically when you call navigation methods like `push(_:)` or `present(_:)`.
///
/// ## Dynamic Member Lookup
///
/// `AnyRoute` supports `@dynamicMemberLookup`, allowing you to access properties
/// of the underlying route directly:
///
/// ```swift
/// let anyRoute = AnyRoute(wrapped: HomeRoute.page1)
/// print(anyRoute.name) // Accesses HomeRoute.page1.name
/// ```
@dynamicMemberLookup
public struct AnyRoute: Identifiable, Hashable {
  /// A unique identifier derived from the wrapped route's hash value.
  ///
  /// This identifier is used by SwiftUI to track route identity in navigation stacks
  /// and determine when views should be recreated.
  public var id: Int { wrapped.hashValue }

  /// The underlying route instance.
  ///
  /// Access this property when you need to work with the concrete route type,
  /// typically by casting: `if let route = anyRoute.wrapped as? HomeRoute { ... }`
  public var wrapped: any Route

  /// Indicates whether this route should be displayed within a navigation stack.
  ///
  /// When `true` (default), the route is pushed onto a `NavigationStack`.
  /// When `false`, the route is presented without a navigation stack wrapper.
  var inStack: Bool = true

  subscript<T>(dynamicMember keyPath: KeyPath<any Route, T>) -> T {
    wrapped[keyPath: keyPath]
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(wrapped.hashValue)
  }
}
