//
//  DeeplinkHandler.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 13/02/2025.
//

/// A protocol for converting an external deeplink input into a `DeeplinkRoute`
/// that can be handled by the `Router`.
///
/// This protocol allows defining how specific routes should be translated
/// into a valid deeplink navigation path.
/// Handlers can be composed by feature and delegated from a top-level handler
/// to mirror nested route architecture.
///
/// ## Example
/// ```swift
/// struct HomeDeeplink: DeeplinkHandler {
///   typealias R = DeeplinkIdentifier
///   typealias D = HomeRoute
///
///   func deeplink(from route: DeeplinkIdentifier) async throws -> DeeplinkRoute<HomeRoute>? {
///     switch route {
///     case .profile(let userId):
///       return DeeplinkRoute(type: .push, route: .profile(userId: userId))
///     default:
///       return nil
///     }
///   }
/// }
/// ```
///
/// ## Composed Example (Nested Feature Logic)
/// ```swift
/// struct AppDeeplinkHandler: DeeplinkHandler {
///   typealias R = AppDeeplinkID
///   typealias D = AppRoute
///
///   private let profileHandler = ProfileDeeplinkHandler()
///
///   func deeplink(from route: AppDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
///     switch route {
///     case .home:
///       return DeeplinkRoute(type: .push, route: .home)
///     case .profile(let profileID):
///       return try await profileHandler.deeplink(from: profileID)
///     }
///   }
/// }
/// ```
public protocol DeeplinkHandler {
  /// The type of route that will be processed.
  associatedtype R: Hashable & Sendable

  /// The type of route that will be returned in the deeplink structure.
  associatedtype D: Route

  /// Converts a given route into a `DeeplinkRoute` that can be handled by the `Router`.
  ///
  /// - Parameter route: The incoming route to process.
  /// - Returns: A `DeeplinkRoute` that defines how the navigation should be handled, or `nil` if the route is not supported.
  func deeplink(from route: R) async throws -> DeeplinkRoute<D>?
}
