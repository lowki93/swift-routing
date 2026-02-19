//
//  TabRouterModel.swift
//  swift-routing
//
//  Created by Kevin Budain on 05/04/2025.
//

import SwiftUI

/// Defines navigation capabilities for tab-based navigation within a `ViewModel` or other components.
///
/// `TabRouterModel` provides methods to manage navigation across multiple tabs,
/// allowing programmatic control over tab switching and navigation within each tab's stack.
///
/// ## Example Usage
/// ```swift
/// class ViewModel {
///    private let tabRouter: TabRouterModel
///
///    init(tabRouter: TabRouterModel) {
///       self.tabRouter = tabRouter
///    }
///
///    func navigateToSettings() {
///       tabRouter.change(tab: HomeTab.settings)
///       tabRouter.push(SettingsRoute.profile, in: HomeTab.settings)
///    }
/// }
/// ```
///
/// You can retrieve the tab router from the environment and inject it into the `ViewModel`:
/// ```swift
///   @Environment(\.tabRouter) private var tabRouter
///
///   let viewModel = ViewModel(tabRouter: tabRouter)
/// ```
public protocol TabRouterModel: BaseRouterModel {
  /// Changes the currently active tab.
  ///
  /// - Parameter tab: The tab to switch to.
  func change(tab: some TabRoute)

  /// Updates the root route of a given tab's navigation stack.
  ///
  /// If `tab` is provided, this method first calls `change(tab:)`, then updates
  /// the root route in that tab's router.
  /// If `tab` is `nil`, it updates the root route in the currently active tab.
  ///
  /// - Parameters:
  ///   - destination: The new root `Route` for the tab.
  ///   - tab: The `TabRoute` to update.
  func update(root destination: some Route, in tab: (any TabRoute)?)

  /// Pushes a new route onto the navigation stack in a specified tab.
  ///
  /// If a tab is provided, it first calls `change(tab:)`, then pushes in that tab.
  /// If `nil`, the route is pushed in the currently active tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to push onto the stack.
  ///   - tab: The `TabRoute` where the route should be pushed, or `nil` for the current tab.
  func push(_ destination: some Route, in tab: (any TabRoute)?)

  /// Presents a route as a modal sheet within a given tab.
  ///
  /// If a tab is provided, it first calls `change(tab:)`, then presents in that tab.
  /// If `nil`, the sheet is presented from the currently active tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present.
  ///   - tab: The `TabRoute` where the modal should be displayed, or `nil` for the current tab.
  func present(_ destination: some Route, in tab: (any TabRoute)?)

  /// Presents a route as a full-screen cover within a given tab.
  ///
  /// If a tab is provided, it first calls `change(tab:)`, then presents in that tab.
  /// If `nil`, the cover is presented from the currently active tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present as a cover.
  ///   - tab: The `TabRoute` where the cover should be displayed, or `nil` for the current tab.
  func cover(_ destination: some Route, in tab: (any TabRoute)?)

  /// Clears the entire navigation path in a specified tab, returning to its root.
  ///
  /// If a tab is provided, it pops to root in that tab.
  /// If `nil`, it pops to root in the currently active tab.
  ///
  /// - Parameter tab: The `TabRoute` to pop to root, or `nil` for the current tab.
  func popToRoot(in tab: (any TabRoute)?)
}

public extension TabRouterModel {

  func push(_ destination: some Route) {
    push(destination, in: nil)
  }

  func present(_ destination: some Route) {
    present(destination, in: nil)
  }

  func cover(_ destination: some Route) {
    cover(destination, in: nil)
  }
}
