//
//  BaseRouterModel.swift
//  swift-routing
//
//  Created by Kévin Budain on 6/13/25.
//

import Foundation

/// Defines the base navigation capabilities shared by all router types.
///
/// `BaseRouterModel` provides common functionality for managing tab-based navigation
/// and child router relationships. Both `RouterModel` and `TabRouterModel` inherit from this protocol.
public protocol BaseRouterModel: ObservableObject {
  /// Returns the `TabRouter` if there is exactly one `TabRouter` among the children.
  ///
  /// Use this property when you expect a single `TabRouter` in the hierarchy.
  /// Returns `nil` if there are zero or more than one `TabRouter` instances.
  var tabRouter: TabRouter? { get }

  /// Finds and returns a `TabRouter` instance associated with the given `TabRoute` type.
  ///
  /// - Parameter tabRoute: The `TabRoute` for which to find the corresponding `TabRouter`.
  /// - Returns: The `TabRouter` associated with the given tab, or `nil` if not found.
  func tabRouter(for tabRoute: some TabRoute) -> TabRouter?

  /// Finds the `Router` instance managing a specific tab within a `TabRouter`.
  ///
  /// This method first locates the `TabRouter` corresponding to the provided `TabRoute`,
  /// then searches inside it to find the `Router` managing that specific tab.
  ///
  /// - Parameter tabRoute: The `TabRoute` representing the tab to search for.
  /// - Returns: The `Router` instance managing the specified tab, or `nil` if not found.
  func findRouterInTabRouter(for tabRoute: some TabRoute) -> Router?

  /// Removes all child routers from the current router.
  ///
  /// Use this method to clear the router hierarchy when needed, such as during cleanup or reset operations.
  func clearChildren()
}
