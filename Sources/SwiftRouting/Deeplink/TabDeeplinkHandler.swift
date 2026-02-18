//
//  TabDeeplinkHandler.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/18/26.
//

/// A protocol for converting a given `Route` into a `TabDeeplink`
/// that can be handled by the `TabRouter`.
///
/// This protocol allows defining how specific routes should be translated
/// into a tab target with an optional deeplink navigation path.
///
/// ## Example
/// ```swift
/// struct HomeTabDeeplinkHandler: TabDeeplinkHandler {
///   func deeplink(from route: DeeplinkIdentifier) async throws -> TabDeeplink<HomeTab, HomeRoute>? {
///     switch route {
///     case .userProfile(let userId):
///       return TabDeeplink(
///         tab: .profile,
///         deeplink: DeeplinkRoute(type: .push, route: .profile(userId: userId))
///       )
///     default:
///       return nil
///     }
///   }
/// }
/// ```
public protocol TabDeeplinkHandler {
  /// The type of route that will be processed.
  associatedtype R: Hashable & Sendable

  /// The tab type where the deeplink should be handled.
  associatedtype T: TabRoute

  /// The type of route that will be returned in the deeplink structure.
  associatedtype D: Route

  /// Converts a given route into a `TabDeeplink` that can be handled by the `TabRouter`.
  ///
  /// - Parameter route: The incoming route to process.
  /// - Returns: A `TabDeeplink` defining the target tab and optional navigation path, or `nil` if the route is not supported.
  func deeplink(from route: R) async throws -> TabDeeplink<T, D>?
}
