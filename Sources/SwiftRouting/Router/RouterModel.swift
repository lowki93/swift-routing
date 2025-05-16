//
//  RouterModel.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

/// Defines navigation capabilities within a `ViewModel` or other components.
///
/// If you need to handle navigation based on conditions (e.g., feature flags),
/// you can use this protocol to abstract navigation logic.
///
/// ## Example Usage
/// ```swift
/// class ViewModel {
///    private let router: RouterModel
///
///    init(router: RouterModel) {
///       self.router = router
///    }
///
///    func condition() {
///      Bool.random()
///       ? router.present(HomeRoute.page2(10))
///       : router.present(HomeRoute.page3("Router"))
///    }
/// }
/// ```
///
/// You can retrieve the router from the environment and inject it into the `ViewModel`:
/// ```swift
///   @Environment(\.router) private var router
///
///   let viewModel = ViewModel(router: router)
/// ```
public protocol RouterModel: ObservableObject {
  /// Updates the current root of the navigation stack.
  ///
  /// This method replaces the existing root with a new destination, effectively resetting navigation.
  /// - Parameter destination: The new `Route` to set as the root.
  func update(root destination: some Route)

  /// Pushes a new route onto the navigation stack.
  ///
  /// This method adds the specified route to the navigation path, allowing for a push-style transition.
  /// - Parameter destination: The `Route` to be pushed onto the stack.
  func push(_ destination: some Route)

  /// Presents a route as a modal sheet.
  ///
  /// This method displays the specified route as a sheet, overlaying the current view.
  /// - Parameter destination: The `Route` to be presented as a sheet.
  func present(_ destination: some Route, withStack: Bool)

  /// Presents a route as a full-screen cover.
  ///
  /// This method presents the specified route as a cover, taking over the entire screen.
  /// - Parameter destination: The `Route` to be presented as a cover.
  func cover(_ destination: some Route)

  /// Clears the entire navigation path, returning to the root.
  func popToRoot()

  /// Closes the navigation stack.
  /// > **Warning:** This function is only available if the stack is presented.
  func close()

  /// Removes the last element from the navigation path, navigating back one step.
  func back()

  /// Closes all child routers presented from the parent router.
  func closeChildren()
}

public extension RouterModel {
  func present(_ destination: some Route) {
    present(destination, withStack: true)
  }
}
