//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI

/// Every `RoutingView` has his own router
///
/// Router enable progamatic control of their navigation stacks
/// ```swift
/// Button("To page2") {
///   router.push(HomeRoute.page2(10))
/// }
/// ```
///
/// Router are accessible from the environment inside a `RoutingView`
/// ```swift
/// @Environment(\.router) var router
/// ```
public final class Router: BaseRouter, @unchecked Sendable {

  static let defaultRouter: Router = Router(configuration: .default)

  // MARK: Navigation
  public var rootID: UUID = UUID()
  @Published internal var root: AnyRoute?
  @Published internal var path = NavigationPath()
  @Published internal var sheet: AnyRoute?
  @Published internal var cover: AnyRoute?
  @Published internal var triggerClose: Bool = false
  internal var currentRoute: AnyRoute?
  public var isPresented: Bool {
    type.isPresented
  }
  /// current number of routes
  public var routeCount: Int {
    // +1 for root view
    path.count + 1
  }
  internal var present: Bool {
    sheet != nil || cover != nil
  }

  // MARK: Configuration
  let type: RouterType

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

  init(root: AnyRoute?, type: RouterType, parent: BaseRouter) {
    self.root = root
    self.currentRoute = root
    self.type = type
    super.init(configuration: parent.configuration, parent: parent)
    parent.addChild(self)
    log(.routerLifecycle, message: "init", metadata: ["from": parent])
  }
}

// MARK: - Navigation

extension Router: @preconcurrency RouterModel {
  @MainActor public func route(_ destination: some Route) {
    route(to: destination, type: destination.routingType)
  }

  @MainActor public func update(root destination: some Route) {
    route(to: destination, type: .root)
  }

  @MainActor public func push(_ destination: some Route) {
    route(to: destination, type: .push)
  }

  @MainActor public func present(_ destination: some Route, withStack: Bool) {
    route(to: destination, type: .sheet(withStack: withStack))
  }

  @MainActor public func cover(_ destination: some Route) {
    route(to: destination, type: .cover)
  }

  @MainActor public func popToRoot() {
    path.popToRoot()
    log(.action, message: "popToRoot")
  }

  @MainActor public func close() {
    guard type.isPresented else { return }

    triggerClose = true
    log(.action, message: "close")
  }

  @MainActor public func back() {
    guard !path.isEmpty else { return }
    path.removeLast()
    log(.action, message: "back")
  }

  @MainActor public func close(_ value: some RouteContext) {
    guard type.isPresented else { return }

    parent?.contexts.all(for: Swift.type(of: value)).forEach { $0.execute(value) }

    close()
  }

  @MainActor public func back(_ value: some RouteContext) {
    if let context = contexts.first(for: Swift.type(of: value)) {
      context.execute(value)
      guard path.count - context.pathCount >= 0 else { return }
      path.removeLast(path.count - context.pathCount)
      log(.action, message: "back", metadata: ["clear": remove])
    } else {
      back()
    }
  }

  @MainActor public func context(_ value: some RouteContext) {
    let termination = Swift.type(of: value)
    parent?.contexts.all(for: termination).forEach { $0.execute(value) }
    contexts.all(for: termination).forEach { $0.execute(value) }
  }

  @MainActor public func closeChildren() {
    for router in children.values.compactMap({ $0.value as? Router }) where router.isPresented {
      sheet = nil
      cover = nil
      log(.action, message: "closeChildren", metadata: ["router": router.type])
    }
  }
}

private extension Router  {

  @MainActor func route(to destination: some Route, type: RoutingType) {
    log(.navigation, metadata: ["navigating": destination, "type": type])

    switch type {
    case .push:
      path.append(destination)
      currentRoute = AnyRoute(wrapped: destination)
    case let .sheet(withStack):
      sheet = AnyRoute(wrapped: destination, inStack: withStack)
    case .cover:
      cover = AnyRoute(wrapped: destination)
    case .root:
      root = AnyRoute(wrapped: destination)
      currentRoute = root
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
  @MainActor func handle(deeplink: DeeplinkRoute<some Route>) {
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
