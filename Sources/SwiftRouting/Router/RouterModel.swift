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
public protocol RouterModel: BaseRouterModel {
  /// Navigates to the given destination using its associated routingType.
  ///
  /// This method examines the `routingType` property of the route and performs the appropriate navigation action (push, sheet, cover, root, etc).
  /// - Parameter destination: The `Route` to navigate to. Its `routingType` determines how the navigation is performed.
  func route(_ destination: some Route)

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

  /// Registers a context observer for a specific `RouteContext` type.
  ///
  /// Use this method to listen for context events triggered by `context(_:)` or `terminate(_:)`.
  /// The closure will be executed whenever a matching context is dispatched, allowing you to
  /// react to navigation flow completions or pass data between routes.
  ///
  /// > **Warning:**
  /// > If you reference a class instance (e.g. a view model) inside the `perform` closure,
  /// > capture it `[weak]` or `[unowned]` to prevent memory leaks.
  ///
  /// ## Example
  /// ```swift
  /// router.add(context: UserSelectionContext.self) { [weak self] context in
  ///   self?.selectedUser = context.user
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - object: The `RouteContext` type to observe.
  ///   - perform: A closure executed when the context is triggered.
  func add<R: RouteContext>(context object: R.Type, perform: @escaping (R) -> Void)

  /// Removes all context observers for a specific `RouteContext` type.
  ///
  /// Use this method to stop listening for a particular context type, typically during cleanup
  /// or when the observer is no longer needed.
  ///
  /// - Parameter object: The `RouteContext` type to stop observing.
  func remove<R: RouteContext>(context object: R.Type)

  /// End navigation flows that depend on a specific context, ensuring all related actions are completed before navigating back or closing.
  /// - Parameter value: `RouteContext` to execute before the back or close operation.
  func terminate( _ value: some RouteContext)

  /// Executes a navigation context action across the entire router hierarchy.
  ///
  /// This method searches for matching context observers in all parent routers (from root to direct parent)
  /// and in the current router, then executes them with the provided value.
  ///
  /// - Parameter value: The `RouteContext` to execute across the router hierarchy.
  func context(_ value: some RouteContext)

  /// Closes all child routers presented from the parent router.
  func closeChildren()
}

public extension RouterModel {
  func present(_ destination: some Route) {
    present(destination, withStack: true)
  }
}
