//
//  TabDeeplink.swift
//  swift-routing
//
//  Created by Kevin Budain on 09/03/2025.
//

/// A structure representing a deep link associated with a specific tab.
///
/// `TabDeeplink` allows for deep linking into a specific tab within the application,
/// optionally providing a `DeeplinkRoute` to navigate further within that tab.
///
/// ## Example
/// ```swift
/// let tabDeeplink = TabDeeplink(
///   tab: HomeTab.profile,
///   deeplink: DeeplinkRoute(type: .push, route: .profile(userId: "42"))
/// )
/// ```
///
/// `TabRouter.handle(tabDeeplink:)` first switches to `tab`, then executes `deeplink` (if present).
///
/// > Note:
/// > Stored properties are internal by design and consumed by the tab router.
/// > Build tab deeplinks through the public initializer.
///
/// - Parameters:
///   - Tab: The tab type, conforming to `TabRoute`.
///   - R: The route type, conforming to `Route`.
public struct TabDeeplink<Tab: TabRoute, R: Route> {

  /// The tab where the deep link should be applied.
  let tab: Tab

  /// The deep link route to navigate within the tab.
  /// This can be `nil` if no specific deep link is required.
  let deeplink: DeeplinkRoute<R>?

  /// Initializes a `TabDeeplink` with a given tab and an optional deep link route.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with the deep link.
  ///   - deeplink: An optional `DeeplinkRoute` specifying the navigation path within the tab.
  public init(tab: Tab, deeplink: DeeplinkRoute<R>?) {
    self.tab = tab
    self.deeplink = deeplink
  }
}
