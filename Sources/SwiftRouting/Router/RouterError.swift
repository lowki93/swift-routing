//
//  RouterError.swift
//  swift-routing
//
//  Created by Kévin Budain on 09/03/26.
//

import Foundation

/// Errors that can occur during route resolution.
///
/// `RouterError` is emitted when the routing system encounters a problem resolving
/// a route to its destination. It is surfaced through ``LoggerMessage/error(_:)``
/// so you can observe and react to routing failures in your logging configuration.
///
/// ## Observing errors
///
/// Configure a logger on ``Configuration`` to receive routing errors:
///
/// ```swift
/// let config = Configuration(logger: { message in
///   if case .error(let error) = message.message {
///     print("Routing error: \(error)")
///   }
/// })
/// ```
///
/// ## Crash behavior
///
/// When ``Configuration/shouldCrashOnRouteNotFound`` is `true`, a `fatalError`
/// is triggered in addition to the log. This is recommended during development
/// to surface misconfigured destinations early.
public enum RouterError: Error, CustomStringConvertible {

  /// A route could not be matched to its destination.
  ///
  /// This error occurs when ``ErrorView`` receives a route whose type does not
  /// match the expected ``RouteDestination/R`` type of the current destination.
  ///
  /// - Parameters:
  ///   - route: The route that could not be resolved.
  ///   - in: The destination type that was expected to handle the route.
  case routeNotFound(route: any Route, in: any RouteDestination.Type)

  /// A human-readable description of the error.
  ///
  /// Includes the dynamic type of the unmatched route and the name of the
  /// destination it was dispatched to.
  public var description: String {
    switch self {
    case let .routeNotFound(route, destination):
      "Route '\(type(of: route))' are not define in '\(String(describing: destination))'"
    }
  }
}
