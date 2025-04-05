//
//  TabRouterModel.swift
//  swift-routing
//
//  Created by Kevin Budain on 05/04/2025.
//

import SwiftUI

public protocol TabRouterModel: ObservableObject{
  /// Changes the currently active tab.
  ///
  /// - Parameter tab: The tab to switch to.
  func change(tab: some TabRoute)

  /// Updates the root route of a given tab's navigation stack.
  ///
  /// - Parameters:
  ///   - destination: The new root `Route` for the tab.
  ///   - tab: The `TabRoute` to update.
  func update(root destination: some Route, in tab: some TabRoute)

  /// Pushes a new route onto the navigation stack in a specified tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to push onto the stack.
  ///   - tab: The `TabRoute` where the route should be pushed.
  func push(_ destination: some Route, in tab: some TabRoute)

  /// Presents a route as a modal sheet within a given tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present.
  ///   - tab: The `TabRoute` where the modal should be displayed.
  func present(_ destination: some Route, in tab: some TabRoute)

  /// Presents a route as a full-screen cover within a given tab.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present as a cover.
  ///   - tab: The `TabRoute` where the cover should be displayed.
  func cover(_ destination: some Route, in tab: some TabRoute)
}
