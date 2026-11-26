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
  ///
  /// This property is updated when the user selects a tab or when
  /// `change(tab:)` is called programmatically.
  @Published var tab: AnyTabRoute

  /// All child routers managed by this tab router.
  ///
  /// Returns an array of `BaseRouter` instances, one for each tab that has been
  /// initialized. Use this to inspect or iterate over all tab routers.
  ///
  /// ```swift
  /// for router in tabRouter.routers {
  ///   print("Tab router: \(router)")
  /// }
  /// ```
  public var routers: [BaseRouter] {
    children.map(\.value.value).compactMap { $0 }
  }

  /// The currently selected tab.
  ///
  /// Overrides ``BaseRouter/currentRoute`` (which would otherwise return `root`, frozen to
  /// whichever tab this router was created for) so it reflects the live selection instead --
  /// used by ``SwiftUICore/View/printRouterOnChange()`` to print the active tab, not the
  /// router's initial one.
  override public var currentRoute: AnyRoute {
    AnyRoute(wrapped: tab.wrapped)
  }

  /// The tab type name, captured once so the restoration segment never reads the mutable `tab`.
  private let tabTypeName: String

  override var restorationSegment: String {
    "tabRouter(\(tabTypeName))"
  }

  /// What this router knows about the tab type, to save and restore the selected tab.
  let restorationSchema: RestorationSchema

  /// The tab this router was seeded with, `nil` when nothing was restored.
  ///
  /// `RoutingTabView` shows it from the first frame, until the caller's binding has caught up.
  let restoredTab: AnyTabRoute?

  /// Initializes a `TabRouter` for a given tab.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with this router.
  ///   - parent: The parent `Router` managing this tab.
  init<Tab: TabRoute>(tab: Tab, parent: BaseRouter) {
    let tabTypeName = String(describing: Tab.self)
    let schema = RestorationSchema(route: Tab.self)
    // Seeding is silent: the selection is set through the initial values, so there is no `change(tab:)`
    // log, no `popToRoot` and no `tabReselected`. A saved tab that no longer decodes is a default tab.
    let path = parent.restorationPath + ["tabRouter(\(tabTypeName))"]
    var restoration = NavigationRestorationStore.Restoration.unrestored
    if let store = parent.restorationStore {
      if store.allowsSeeding(under: parent) {
        restoration = store.restore(at: path, schema: schema, crashOnNotCodable: parent.configuration.shouldCrashOnRouteNotFound)
      } else {
        // The screen that builds this router is no longer the one it was saved under.
        store.discard(at: path)
      }
    }
    let restoredTab = (restoration.state?.tab?.wrapped as? any TabRoute).map { AnyTabRoute(wrapped: $0) }
    self.tab = restoredTab ?? AnyTabRoute(wrapped: tab)
    self.restoredTab = restoredTab
    self.tabTypeName = tabTypeName
    self.restorationSchema = schema
    super.init(configuration: parent.configuration, root: AnyRoute(wrapped: tab), parent: parent)
    /// To avoid having more thant instance of the TabRoute, we remove the previous from the parent
    if let tabRouter = parent.tabRouter(for: tab) {
      parent.removeChild(tabRouter)
    }
    parent.addChild(self)

    restoration.reasons.forEach { log(.error(.restoration($0))) }
    restoration.crash?()
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
  /// If `tab` is provided, this method first switches the active tab
  /// (`change(tab:)`), then updates that tab's root route.
  /// If `tab` is `nil`, it updates the currently selected tab.
  ///
  /// - Parameters:
  ///   - destination: The new root `Route` for the tab.
  ///   - tab: The `TabRoute` to update.
  @MainActor public func update(root destination: some Route, in tab: (any TabRoute)?) {
    if let tab {
      change(tab: tab)
    }
    find(tab: tab ?? self.tab.wrapped)?.update(root: destination)
  }

  /// Pushes a new route onto the navigation stack in a specified tab.
  ///
  /// If `tab` is provided, this method first switches the active tab
  /// (`change(tab:)`), then pushes in that tab.
  /// If `tab` is `nil`, it pushes in the currently selected tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to push onto the stack.
  ///   - tab: The `TabRoute` where the route should be pushed.
  @MainActor public func push(_ destination: some Route, in tab: (any TabRoute)?) {
    if let tab {
      change(tab: tab)
    }
    find(tab: tab ?? self.tab.wrapped)?.push(destination)
  }

  /// Presents a route as a modal sheet within a given tab.
  ///
  /// If `tab` is provided, this method first switches the active tab
  /// (`change(tab:)`), then presents in that tab.
  /// If `tab` is `nil`, it presents in the currently selected tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present.
  ///   - tab: The `TabRoute` where the modal should be displayed.
  @MainActor public func present(_ destination: some Route, in tab: (any TabRoute)?) {
    if let tab {
      change(tab: tab)
    }
    find(tab: tab ?? self.tab.wrapped)?.present(destination)
  }

  /// Presents a route as a full-screen cover within a given tab.
  ///
  /// If `tab` is provided, this method first switches the active tab
  /// (`change(tab:)`), then presents in that tab.
  /// If `tab` is `nil`, it presents in the currently selected tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present as a cover.
  ///   - tab: The `TabRoute` where the cover should be displayed.
  @MainActor public func cover(_ destination: some Route, in tab: (any TabRoute)?) {
    if let tab {
      change(tab: tab)
    }
    find(tab: tab ?? self.tab.wrapped)?.cover(destination)
  }

  @MainActor public func popToRoot(in tab: (any TabRoute)?) {
    find(tab: tab ?? self.tab.wrapped)?.popToRoot()
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
