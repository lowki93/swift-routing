//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import Observation
import SwiftUI

/// Every `RoutingNavigationStack`has his own router
///
///Router enable progamatic control of their navigation stacks
/// ```swift
/// Button("To page2") {
///   router.push(HomeRoute.page2(10))
/// }
/// ```
///
/// Router are accessible from the environment inside a `RoutingNavigationStack`
/// ```swift
/// @Environment(\.router) var router
/// ```
@Observable
public final class Router: BaseRouter, @unchecked Sendable {

  internal static let defaultRouter: Router = Router(configuration: .default)

  internal var rootID: UUID = UUID()

  // MARK: Navigation
  internal var root: AnyRoute?
  internal var path = NavigationPath()
  internal var sheet: AnyRoute?
  internal var cover: AnyRoute?
  internal var triggerClose: Bool = false
  internal var present: Bool {
    sheet != nil || cover != nil
  }

  // MARK: Configuration
  internal let type: RouterType

  // MARK: Initialization
  /// Initializes a `Router` with a custom configuration.
  ///
  /// This initializer sets up the router with a specified `Configuration`, defining behaviors such as logging.
  /// By default, the router type is set to `.app`, and an initialization log entry is created.
  ///
  /// - Parameter configuration: The configuration used to customize the router's behavior.
  public init(configuration: Configuration) {
    self.type = .app
    super.init(configuration: configuration)
    log(.routerLifecycle, message: "init")
  }

  init(root: AnyRoute?, type: RouterType, parent: Router) {
    self.root = root
    self.type = type
    super.init(configuration: parent.configuration, parent: parent)
    parent.addChild(self)
    log(.routerLifecycle, message: "init", metadata: ["from": parent])
  }

  init(root: AnyRoute?, tab: some TabRoute, parent: TabRouter) {
    self.root = root
    self.type = tab.type
    super.init(configuration: parent.configuration, parent: parent)
    parent.addChild(self)
    log(.routerLifecycle, message: "init", metadata: ["from": parent])
  }
}

// MARK: - Navigation

extension Router: RouterModel {
  public func update(root destination: some Route) {
    route(to: destination, type: .root)
  }

  public func push(_ destination: some Route) {
    route(to: destination, type: .push)
  }

  public func present(_ destination: some Route) {
    route(to: destination, type: .sheet)
  }

  public func cover(_ destination: some Route) {
    route(to: destination, type: .cover)
  }
}

private extension Router  {
  func route(to destination: some Route, type: RoutingType) {
    log(.navigation, metadata: ["navigating": destination, "type": type])

    switch type {
    case .push:
      path.append(destination)
    case .sheet:
      sheet = AnyRoute(wrapped: destination)
    case .cover:
      cover = AnyRoute(wrapped: destination)
    case .root:
      root = AnyRoute(wrapped: destination)
      rootID = UUID()
    }
  }
}

// MARK: - Action

public extension Router {
  /// Clears the entire navigation path, returning to the root.
  func popToRoot() {
    path.popToRoot()
    log(.action, message: "popToRoot")
  }

  /// Closes the navigation stack.
  /// > **Warning:** This function is only available if the stack is presented.
  func close() {
    if type.isPresented {
      triggerClose = true
      log(.action, message: "close")
    }
  }

  /// Removes the last element from the navigation path, navigating back one step.
  func back() {
    path.removeLast()
    log(.action, message: "back")
  }

  /// Closes all child routers presented from the parent router.
  func closeChildren() {
    for router in children.values.compactMap({ $0.value as? Router }) where router.present {
      router.sheet = nil
      router.cover = nil
      log(.action, message: "closeChildren", metadata: ["router": router.type])
    }
  }
}

// MARK: - Deeplink

public extension Router {
  /// Handles a deeplink and navigates to the corresponding route.
  ///
  /// This method processes a deeplink by performing the following steps:
  /// 1. Closes all currently presented child routers.
  /// 2. Clears the current navigation path, returning to the root.
  /// 3. Pushes the intermediate routes defined in the deeplink's path.
  /// 4. Navigates to the final destination route with the specified presentation type.
  ///
  /// - Parameter deeplink: The `DeeplinkRoute` containing the navigation path and target route.
  func handle(deeplink: DeeplinkRoute<some Route>) {
    // Dismiss all presented child routers
    (parent as? Router)?.closeChildren()

    // Clear the current navigation path
    popToRoot()

    // Add intermediate routes to the navigation path
    for route in deeplink.path {
      push(route)
    }

    // Navigate to the target route with the specified presentation type
    route(to: deeplink.route, type: deeplink.type)
  }
}
