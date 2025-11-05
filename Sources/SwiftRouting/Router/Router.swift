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
  @Published internal var root: AnyRoute
  @Published internal var path: [AnyRoute] = [] {
    willSet {
      updatePath(old: path, new: newValue)
    }
  }
    @Published internal var cover: AnyRoute? {
      didSet {
        guard oldValue != cover else { return }
        present.send((cover != nil, self))
      }
    }
  @Published internal private(set) var triggerClose: Bool = false
  public var currentRoute: AnyRoute
  public var isPresented: Bool {
    type.isPresented
  }
  /// current number of routes
  public var routeCount: Int {
    // +1 for root view
    path.count + 1
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
    let defaultRoute = AnyRoute(wrapped: DefaultRoute.main)
    self.type = .app
    self.root = defaultRoute
    self.currentRoute = defaultRoute
    super.init(configuration: configuration)
  }

  init(root: AnyRoute, type: RouterType, parent: BaseRouter) {
    self.root = root
    self.currentRoute = root
    self.type = type
    super.init(configuration: parent.configuration, parent: parent)
    parent.addChild(self)
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
    path.removeAll() //.popToRoot()
    log(.action(.popToRoot))
  }

  @MainActor public func close() {
    guard type.isPresented else { return }

    triggerClose = true
    log(.action(.close))
  }

  @MainActor public func back() {
    guard !path.isEmpty else { return }
    path.removeLast()
    log(.action(.back()))
  }

  @MainActor public func add<R: RouteContext>(context object: R.Type, perform: @escaping (R) -> Void) {
    guard let context = RouterContext(
      router: self,
      routerContext: object,
      action: { [perform] in
        guard let value = $0 as? R else { return }
        perform(value)
      }
    ) else { return }
    contexts.insert(context)
  }

  @MainActor public func remove<R: RouteContext>(context object: R.Type) {
    for element in contexts.all(for: object) {
      contexts.remove(element)
    }
  }

  @MainActor public func terminate(_ value: some RouteContext) {
    /// Execute all termination observers for the given context type (in both parent and child routers).
    context(value)

    /// Remove all routes above the matched context in the navigation path
    if let context = contexts.first(for: Swift.type(of: value), currentRoute: currentRoute.wrapped) {
      guard path.count - context.pathCount >= 0 else { return }
      let clear = path.count - context.pathCount
      path.removeLast(clear)
      log(.action(.back(count: clear)))
    /// If the context is not found and the router is presented (i.e., displayed modally)
    } else if type.isPresented {
      close()
    /// Otherwise, pops the topmost route from the stack
    } else {
      back()
    }
  }

  @MainActor public func context(_ value: some RouteContext) {
    let termination = Swift.type(of: value)

    // Execute context in all parent routers (from root to direct parent)
    var current = parent
    while let router = current {
      router.contexts.all(for: termination).forEach { $0.execute(value) }
      current = router.parent
    }

    // Execute context in current router
    contexts.all(for: termination).forEach { $0.execute(value) }
  }

  @MainActor public func closeChildren() {
    for router in children.values.compactMap({ $0.value as? Router }) where router.isPresented {
      log(.action(.closeChildren(router)))
      sheet = nil
      cover = nil
    }
  }
}

private extension Router  {

  @MainActor func route(to destination: some Route, type: RoutingType) {
    log(.navigation(from: currentRoute.wrapped, to: destination, type: type))

    switch type {
    case .push:
      path.append(AnyRoute(wrapped: destination))
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

  func updatePath(old: [AnyRoute], new: [AnyRoute]) {
    let count = old.count - new.count
    guard count > 0 else { return }

    for element in contexts.all(for: path.suffix(count).map(\.wrapped)) {
      contexts.remove(element)
      log(.context(.remove(element.route, context: element.routerContext)))
    }

    currentRoute = new.last ?? root
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

    // Override the root route
    if let root = deeplink.root {
      route(to: root, type: .root)
    }

    // Add intermediate routes to the navigation path
    for route in deeplink.path {
      push(route)
    }

    // Navigate to the target route with the specified presentation type
    route(to: deeplink.route, type: deeplink.type)
  }
}
