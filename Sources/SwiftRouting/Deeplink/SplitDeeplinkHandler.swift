//
//  SplitDeeplinkHandler.swift
//  swift-routing
//

/// A protocol for converting an external deeplink input into a `SplitDeeplink`
/// that can be handled by a split-view `Router`.
///
/// This protocol allows defining how specific routes should be translated
/// into content/detail column selections, with an optional deeplink navigation path.
/// Handlers can be composed by feature and delegated from a top-level handler
/// to mirror nested route architecture.
///
/// ## Example
/// ```swift
/// struct PlayerSplitDeeplinkHandler: SplitDeeplinkHandler {
///   typealias R = DeeplinkIdentifier
///   typealias ContentData = PlayerType
///   typealias DetailData = Player
///   typealias D = AppRoute
///
///   func deeplink(from route: DeeplinkIdentifier) async throws -> SplitDeeplink<PlayerType, Player, AppRoute>? {
///     switch route {
///     case .player(let player):
///       return SplitDeeplink(content: player.type, detail: player)
///     default:
///       return nil
///     }
///   }
/// }
/// ```
///
/// ## Composed Example (Nested Feature Logic)
/// ```swift
/// struct AppSplitDeeplinkHandler: SplitDeeplinkHandler {
///   typealias R = AppDeeplinkID
///   typealias ContentData = PlayerType
///   typealias DetailData = Player
///   typealias D = AppRoute
///
///   private let playerHandler = PlayerSplitDeeplinkHandler()
///
///   func deeplink(from route: AppDeeplinkID) async throws -> SplitDeeplink<PlayerType, Player, AppRoute>? {
///     switch route {
///     case .player(let playerID):
///       return try await playerHandler.deeplink(from: .player(playerID))
///     }
///   }
/// }
/// ```
public protocol SplitDeeplinkHandler {
  /// The type of route that will be processed.
  associatedtype R: Hashable & Sendable

  /// The type of the content column selection (3-column layout only).
  associatedtype ContentData: Hashable & Sendable

  /// The type of the detail column selection.
  associatedtype DetailData: Hashable & Sendable

  /// The type of route that will be returned in the split deeplink's optional deeplink.
  associatedtype D: Route

  /// Converts a given route into a `SplitDeeplink` that can be handled by a split-view `Router`.
  ///
  /// - Parameter route: The incoming route to process.
  /// - Returns: A `SplitDeeplink` defining the target column selections and optional navigation path, or `nil` if the route is not supported.
  func deeplink(from route: R) async throws -> SplitDeeplink<ContentData, DetailData, D>?
}
