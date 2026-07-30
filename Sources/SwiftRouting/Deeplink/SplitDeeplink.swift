//
//  SplitDeeplink.swift
//  swift-routing
//

/// A structure representing a deep link into a `RoutingSplitView`'s columns.
///
/// `SplitDeeplink` allows deep linking directly into the content and/or detail column
/// of a split-view router, optionally providing a `DeeplinkRoute` to navigate further
/// within the detail column's own navigation stack.
///
/// ## Example
/// ```swift
/// let splitDeeplink = SplitDeeplink(
///   content: PlayerType.forward,
///   detail: Player(id: "42"),
///   deeplink: DeeplinkRoute.push(.playerStats(id: "42"))
/// )
/// ```
///
/// `Router.handle(splitDeeplink:)` applies this in order:
/// 1. Selects `content` (3-column layout only; no-op if the router has no content column)
/// 2. Selects `detail`
/// 3. Applies `deeplink` (if present) within the detail column's navigation stack
///
/// > Note:
/// > The content column has no navigation stack of its own — `deeplink` only ever
/// > pushes within the detail column, regardless of which selection it follows.
///
/// > Note:
/// > Stored properties are internal by design and consumed by the router.
/// > Build split deeplinks through the public initializer.
///
/// - Parameters:
///   - ContentData: The `Hashable & Sendable` type of the content column selection.
///   - DetailData: The `Hashable & Sendable` type of the detail column selection.
///   - R: The route type, conforming to `Route`, used for the optional detail-column deeplink.
public struct SplitDeeplink<ContentData: Hashable & Sendable, DetailData: Hashable & Sendable, R: Route> {

  /// The value to select in the content column (3-column layout only).
  /// This can be `nil` if no content selection is required.
  let content: ContentData?

  /// The value to select in the detail column.
  /// This can be `nil` if no detail selection is required.
  let detail: DetailData?

  /// An optional deep link to apply within the detail column's navigation stack, after selection.
  let deeplink: DeeplinkRoute<R>?

  /// Initializes a `SplitDeeplink` with optional column selections and an optional deep link.
  ///
  /// - Parameters:
  ///   - content: The value to select in the content column (3-column layout only).
  ///   - detail: The value to select in the detail column.
  ///   - deeplink: An optional deep link to apply within the detail column's navigation stack.
  public init(content: ContentData? = nil, detail: DetailData? = nil, deeplink: DeeplinkRoute<R>? = nil) {
    self.content = content
    self.detail = detail
    self.deeplink = deeplink
  }
}
