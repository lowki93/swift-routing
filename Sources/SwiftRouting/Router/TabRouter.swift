//
//  TabRouter.swift
//  swift-routing
//
//  Created by Kevin Budain on 06/03/2025.
//

import Foundation
import Observation

/// A router managing navigation within a `RoutingTabView`.
///
/// `TabRouter` enables programmatic control over navigation stacks within a tabbed navigation system.
///
/// ## Usage
/// ```swift
/// Button("To page2") {
///   router.push(HomeRoute.page2(10), in: HomeTab.home)
/// }
/// ```
///
/// The `TabRouter` instance is accessible from the environment inside a `RoutingTabView`:
/// ```swift
/// @Environment(\.tabRouter) var tabRouter
/// ```
public final class TabRouter: BaseRouter, @unchecked Sendable {

  /// The currently active tab.
  @Published var tab: AnyTabRoute

  public var routers: [BaseRouter] {
    children.map(\.value.value).compactMap { $0 }
  }

  /// Initializes a `TabRouter` for a given tab.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with this router.
  ///   - parent: The parent `Router` managing this tab.
  init(tab: some TabRoute, parent: BaseRouter) {
    self.tab = AnyTabRoute(wrapped: tab)
    super.init(configuration: parent.configuration, parent: parent)
    /// To avoid having more thant instance of the TabRoute, we remove the previous from the parent
    if let tabRouter = parent.tabRouter(for: tab) {
      parent.removeChild(tabRouter)
    }
    parent.addChild(self)
  }
}

// MARK: - Navigation

extension TabRouter: @preconcurrency TabRouterModel {

  /// Changes the currently active tab.
  ///
  /// - Parameter tab: The tab to switch to.
  @MainActor public func change(tab: some TabRoute) {
    self.tab = AnyTabRoute(wrapped: tab)
    log(.action(.changeTab(tab)))
  }

  /// Updates the root route of a given tab's navigation stack.
  ///
  /// - Parameters:
  ///   - destination: The new root `Route` for the tab.
  ///   - tab: The `TabRoute` to update.
  @MainActor public func update(root destination: some Route, in tab: some TabRoute) {
    find(tab: tab)?.update(root: destination)
    change(tab: tab)
  }

  /// Pushes a new route onto the navigation stack in a specified tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to push onto the stack.
  ///   - tab: The `TabRoute` where the route should be pushed.
  @MainActor public func push(_ destination: some Route, in tab: some TabRoute) {
    change(tab: tab)
    find(tab: tab)?.push(destination)
  }

  /// Presents a route as a modal sheet within a given tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present.
  ///   - tab: The `TabRoute` where the modal should be displayed.
  @MainActor public func present(_ destination: some Route, in tab: some TabRoute) {
    change(tab: tab)
    find(tab: tab)?.present(destination)
  }

  /// Presents a route as a full-screen cover within a given tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present as a cover.
  ///   - tab: The `TabRoute` where the cover should be displayed.
  @MainActor public func cover(_ destination: some Route, in tab: some TabRoute) {
    change(tab: tab)
    find(tab: tab)?.cover(destination)
  }
}

// MARK: - Deeplink

public extension TabRouter {

  /// Handles a deep link by changing the active tab and navigating accordingly.
  ///
  /// - Parameter tabDeeplink: A `TabDeeplink` instance containing the target tab and an optional deep link.
  @MainActor func handle(tabDeeplink: TabDeeplink<some TabRoute, some Route>) {
    change(tab: tabDeeplink.tab)

    guard let deeplink = tabDeeplink.deeplink else { return }
    find(tab: tabDeeplink.tab)?.handle(deeplink: deeplink)
  }
}
