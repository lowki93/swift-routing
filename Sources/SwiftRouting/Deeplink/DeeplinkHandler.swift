//
//  DeeplinkHandler.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 13/02/2025.
//

/// A protocol for converting a given `Route` into a `DeeplinkRoute`
/// that can be handled by the `Router`.
///
/// This protocol allows defining how specific routes should be translated
/// into a valid deeplink navigation path.
///
/// ## Example
/// ```swift
/// struct HomeDeeplink: DeeplinkHandler {
///   func deeplink(route: SubRoute) -> DeeplinkRoute<HomeRoute>? {
///     // Convert the incoming route to a DeeplinkRoute<HomeRoute>
///     ...
///   }
/// }
/// ```
public protocol DeeplinkHandler {
  /// The type of route that will be processed.
  associatedtype R: Route

  /// The type of route that will be returned in the deeplink structure.
  associatedtype D: Route

  /// Converts a given route into a `DeeplinkRoute` that can be handled by the `Router`.
  ///
  /// - Parameter route: The incoming route to process.
  /// - Returns: A `DeeplinkRoute` that defines how the navigation should be handled, or `nil` if the route is not supported.
  func deeplink(route: R) -> DeeplinkRoute<D>?
}
