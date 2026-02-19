//
//  TabDeeplinkHandler.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/18/26.
//

/// A protocol for converting an external deeplink input into a `TabDeeplink`
/// that can be handled by the `TabRouter`.
///
/// This protocol allows defining how specific routes should be translated
/// into a tab target with an optional deeplink navigation path.
/// Handlers can be composed by feature and delegated from a top-level handler
/// to mirror nested route architecture.
///
/// ## Example
/// ```swift
/// struct HomeTabDeeplinkHandler: TabDeeplinkHandler {
///   typealias R = DeeplinkIdentifier
///   typealias T = HomeTab
///   typealias D = HomeRoute
///
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
///
/// ## Composed Example (Nested Feature Logic)
/// ```swift
/// struct AppTabDeeplinkHandler: TabDeeplinkHandler {
///   typealias R = AppDeeplinkID
///   typealias T = HomeTab
///   typealias D = HomeRoute
///
///   private let profileHandler = ProfileTabDeeplinkHandler()
///
///   func deeplink(from route: AppDeeplinkID) async throws -> TabDeeplink<HomeTab, HomeRoute>? {
///     switch route {
///     case .home:
///       return TabDeeplink(tab: .home, deeplink: DeeplinkRoute(type: .push, route: .home))
///     case .profile(let profileID):
///       return try await profileHandler.deeplink(from: profileID)
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
