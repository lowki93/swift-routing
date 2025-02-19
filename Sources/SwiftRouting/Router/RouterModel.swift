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
  /// Pushes a new route onto the navigation stack.
  ///
  /// This method adds the specified route to the navigation path, allowing for a push-style transition.
  /// - Parameter destination: The `Route` to be pushed onto the stack.
  func push(_ destination: some Route)

  /// Presents a route as a modal sheet.
  ///
  /// This method displays the specified route as a sheet, overlaying the current view.
  /// - Parameter destination: The `Route` to be presented as a sheet.
  func present(_ destination: some Route)

  /// Presents a route as a full-screen cover.
  ///
  /// This method presents the specified route as a cover, taking over the entire screen.
  /// - Parameter destination: The `Route` to be presented as a cover.
  func cover(_ destination: some Route)
}
