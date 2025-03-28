//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

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
public class Router: ObservableObject, Identifiable, @unchecked Sendable {

  internal static let defaultRouter: Router = Router(configuration: .default)

  public let id: UUID = UUID()
  internal var rootID: UUID = UUID()

  // MARK: Navigation
  @Published internal var root: AnyRoute?
  @Published internal var path = NavigationPath()
  @Published internal var sheet: AnyRoute?
  @Published internal var cover: AnyRoute?
  @Published internal var triggerClose: Bool = false
  public var isPresented: Bool {
    type.isPresented
  }
  internal var present: Bool {
    sheet != nil || cover != nil
  }

  // MARK: Configuration
  internal let type: RouterType
  internal let configuration: Configuration
  // TODO: [TabBarRouter] Not expose parent -> Create a TabRouter accessible in the Environment
  public var hideTabBar: Bool
  public weak var parent: Router?

  internal var children: [UUID: WeakContainer<Router>] = [:]

  // MARK: Initialization
  /// Initializes a `Router` with a custom configuration.
  ///
  /// This initializer sets up the router with a specified `Configuration`, defining behaviors such as logging.
  /// By default, the router type is set to `.app`, and an initialization log entry is created.
  ///
  /// - Parameter configuration: The configuration used to customize the router's behavior.
  public init(configuration: Configuration) {
    self.type = .app
    // TODO: [TabBarRouter] Move in tabarRouter
    self.hideTabBar = false
    self.configuration = configuration
    log(.routerLifecycle, message: "init")
  }

  init(root: AnyRoute?, type: RouterType, parent: Router, hideTabBar: Bool) {
    self.root = root
    self.type = type
    self.configuration = parent.configuration
    self.parent = parent
    // TODO: [TabBarRouter] Move in tabarRouter
    self.hideTabBar = hideTabBar
    parent.addChild(self)
    log(.routerLifecycle, message: "init", metadata: ["from": parent.type])
  }

  deinit {
    parent?.removeChild(self)
    log(.routerLifecycle, message: "deinit")
  }
}

// MARK: - Navigation

extension Router: @preconcurrency RouterModel {
  @MainActor
  public func update(root destination: some Route) {
    route(to: destination, type: .root)
  }

  @MainActor
  public func push(_ destination: some Route) {
    route(to: destination, type: .push)
  }

  @MainActor
  public func present(_ destination: some Route) {
    route(to: destination, type: .sheet)
  }

  @MainActor
  public func cover(_ destination: some Route) {
    route(to: destination, type: .cover)
  }

  @MainActor
  public func popToRoot() {
    path.popToRoot()
    log(.action, message: "popToRoot")
  }

  @MainActor
  public func close() {
    if type.isPresented {
      triggerClose = true
      log(.action, message: "close")
    }
  }

  @MainActor
  public func back() {
    path.removeLast()
    log(.action, message: "back")
  }

  @MainActor
  public func closeChildren() {
    for router in children.values.compactMap(\.value) where router.isPresented {
      sheet = nil
      cover = nil
      log(.action, message: "closeChildren", metadata: ["router": router.type])
    }
  }
}

private extension Router  {
  @MainActor
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
  @MainActor
  func handle(deeplink: DeeplinkRoute<some Route>) {
    // Dismiss all presented child routers
    closeChildren()

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

public extension Router {
  /// Finds the corresponding router for a given tab.
  ///
  /// This method searches among the child routers to find the one associated with the specified tab.
  ///
  /// - Parameter tab: The `TabRoute` to search for.
  @discardableResult func find(tab: some TabRoute) -> Router? {
    children.values.compactMap(\.value).first(where: { $0.type == tab.type })
  }
}

// MARK: - Child

internal extension Router {
  func addChild(_ child: Router) {
    children[child.id] = WeakContainer(value: child)
  }

  func removeChild(_ child: Router) {
    children.removeValue(forKey: child.id)
  }
}

// MARK: - Log

extension Router {
  func log(_ type: LoggerAction, message: String? = nil, metadata: [String: Any]? = nil) {
    configuration.logger?(
      LoggerConfiguration(
        type: type,
        router: self,
        message: message,
        metadata: metadata
      )
    )
  }
}
