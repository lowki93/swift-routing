//
//  RouterError.swift
//  swift-routing
//
//  Created by Kévin Budain on 09/03/26.
//

import Foundation

/// Errors that can occur while resolving routes or saving and restoring navigation.
///
/// `RouterError` is emitted when the routing system encounters a problem resolving
/// a route to its destination, or saving or restoring the navigation state. It is surfaced through ``LoggerMessage/error(_:)``
/// so you can observe and react to routing failures in your logging configuration.
///
/// ## Observing errors
///
/// Configure a logger on ``Configuration`` to receive routing errors:
///
/// ```swift
/// let config = Configuration(
///   logger: { loggerConfiguration in
///     if case .error(let error) = loggerConfiguration.message {
///       print("Routing error: \(error)")
///     }
///   },
///   shouldCrashOnRouteNotFound: false
/// )
/// ```
///
/// ## Crash behavior
///
/// When `Configuration.shouldCrashOnRouteNotFound` is `true`, a `fatalError`
/// is triggered in addition to the log for ``routeNotFound(route:in:)`` and for
/// ``restoration(_:)`` with ``RestorationReason/notCodable(container:type:)`` only.
/// Other restoration failures never crash. This is recommended during development
/// to surface misconfigured destinations early.
public enum RouterError: Error, CustomStringConvertible {

  /// A route could not be matched to its destination.
  ///
  /// This error occurs when the internal error-rendering view receives a route whose
  /// type does not match the expected ``RouteDestination/R`` type of the current destination.
  ///
  /// - Parameters:
  ///   - route: The route that could not be resolved.
  ///   - in: The destination type that was expected to handle the route.
  case routeNotFound(route: any Route, in: any RouteDestination.Type)

  /// A container could not be saved or restored by navigation restoration.
  ///
  /// Logged as an error and never thrown: the affected container simply starts on its default state,
  /// unless the reason is ``RestorationReason/notCodable(container:type:)`` and
  /// `Configuration.shouldCrashOnRouteNotFound` is on, which crashes.
  /// Add a case for it in any exhaustive `switch` over `RouterError`.
  ///
  /// - Parameter reason: What went wrong, and for which container.
  case restoration(RestorationReason)

  /// Why navigation restoration could not save or restore a container.
  ///
  /// `container` is the router's path in the navigation tree, for example `app/stack(home)`.
  ///
  /// ```swift
  /// let config = Configuration(
  ///   logger: { loggerConfiguration in
  ///     guard case .error(.restoration(let reason)) = loggerConfiguration.message else { return }
  ///     switch reason {
  ///     case .notCodable(let container, let type):
  ///       print("\(container) is not saved: \(type) is not Codable")
  ///     case .decodingFailed(let container, let error):
  ///       print("\(container) starts on its default state: \(error)")
  ///     case .encodingFailed(let container, let error):
  ///       print("\(container) is not saved: \(error)")
  ///     case .duplicateKey(let container):
  ///       print("Several routers share \(container)")
  ///     }
  ///   },
  ///   shouldCrashOnRouteNotFound: false
  /// )
  /// ```
  public enum RestorationReason: Sendable, CustomStringConvertible {
    /// The container's route types are not `Codable`, so it starts on its default state.
    case notCodable(container: String, type: String)
    /// The saved state of the container could not be decoded (for example a renamed route case).
    /// The container and its subtree start on their default state.
    case decodingFailed(container: String, error: String)
    /// The state of the container could not be encoded, so its own state is not saved. Its children are still saved.
    case encodingFailed(container: String, error: String)
    /// Several sibling containers share the same identity, so none of them is saved.
    case duplicateKey(container: String)

    public var description: String {
      switch self {
      case let .notCodable(container, type):
        "Navigation restoration skipped '\(container)': '\(type)' does not conform to Codable"
      case let .decodingFailed(container, error):
        "Navigation restoration failed to decode '\(container)', it starts on its default state: \(error)"
      case let .encodingFailed(container, error):
        "Navigation restoration failed to encode '\(container)', it is not saved: \(error)"
      case let .duplicateKey(container):
        "Navigation restoration found several routers sharing '\(container)', none of them is saved"
      }
    }
  }

  /// A human-readable description of the error.
  ///
  /// Includes the dynamic type of the unmatched route and the name of the
  /// destination it was dispatched to.
  public var description: String {
    switch self {
    case let .routeNotFound(route, destination):
      "Route '\(type(of: route))' are not define in '\(String(describing: destination))'"
    case let .restoration(reason):
      reason.description
    }
  }
}
