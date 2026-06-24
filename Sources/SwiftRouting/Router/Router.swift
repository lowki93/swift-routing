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
public final class Router: PresentableRouter, @unchecked Sendable {

  static let defaultRouter: Router = Router(configuration: .default)

  // MARK: Navigation
  @Published internal var root: AnyRoute {
    willSet {
      for context in contexts.all(for: root.wrapped) {
        contexts.remove(context)
        log(.context(.remove(context.route, context: context.routerContext)))
      }
    }
  }

  @Published internal var path: [AnyRoute] = [] {
    willSet {
      removeContext(old: path, new: newValue)
    }
  }

  /// The currently visible route in the navigation stack.
  ///
  /// Returns the last route in the navigation path, or the root route if the path is empty.
  /// Use this property to determine which route is currently displayed.
  ///
  /// ```swift
  /// print("Current route: \(router.currentRoute.name)")
  /// ```
  override public var currentRoute: AnyRoute {
    switch type {
    case .split:
      if let sel = detailSelection, let route = detailRouteFactory?(sel) { return route }
      return root
    default:
      return path.last ?? root
    }
  }

  override public var pathCount: Int { path.count }

  /// Indicates whether this router is presented as a modal (sheet or cover).
  ///
  /// Returns `true` if the router was created via `present(_:)` or `cover(_:)`,
  /// `false` for routers created via `push(_:)` or as root/tab routers.
  ///
  /// Use this property to conditionally show close buttons or handle dismissal:
  ///
  /// ```swift
  /// if router.isPresented {
  ///   Button("Close") { router.close() }
  /// }
  /// ```
  override public var isPresented: Bool {
    type.isPresented
  }

  /// The total number of routes in the navigation stack, including the root.
  ///
  /// This count includes the root view plus all pushed routes.
  /// A value of 1 means only the root is displayed.
  ///
  /// ```swift
  /// if router.routeCount > 1 {
  ///   // Show back button
  /// }
  /// ```
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
    self.type = .app
    super.init(configuration: configuration, root: AnyRoute(wrapped: DefaultRoute.main), first: true)
  }

  // MARK: Split navigation state
  @Published internal var detailSelection: AnyHashable?
  @Published internal var contentSelection: AnyHashable?

  /// `true` when the split view is in compact mode (e.g. iPhone).
  /// Always `false` for non-split routers.
  @Published public internal(set) var isCompact: Bool = false

  /// `true` when this split router has a content column (3-column layout).
  /// Always `false` for non-split routers.
  public var hasContentColumn: Bool {
    if case .split(_, let has) = type { return has }
    return false
  }

  var detailRouteFactory: ((AnyHashable) -> AnyRoute?)?
  var contentRouteFactory: ((AnyHashable) -> AnyRoute?)?

  init(
    root: AnyRoute,
    type: RouterType,
    parent: BaseRouter,
    detailRouteFactory: ((AnyHashable) -> AnyRoute?)? = nil,
    contentRouteFactory: ((AnyHashable) -> AnyRoute?)? = nil
  ) {
    self.type = type
    self.detailRouteFactory = detailRouteFactory
    self.contentRouteFactory = contentRouteFactory
    super.init(configuration: parent.configuration, root: root, parent: parent)
    if case .split = type {
      #if os(iOS)
      isCompact = UIDevice.current.userInterfaceIdiom == .phone
      #endif
    }
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

  @MainActor public func popToRoot() {
    guard !path.isEmpty else { return }

    path.removeAll()
    log(.action(.popToRoot))
  }

  @MainActor public func back() {
    guard !path.isEmpty else { return }
    path.removeLast()
    log(.action(.back()))
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
}

private extension Router {

  @MainActor func route(to destination: some Route, type: RoutingType) {
    log(.navigation(from: currentRoute.wrapped, to: destination, type: type))

    switch type {
    case .push:
      path.append(AnyRoute(wrapped: destination))
    case let .sheet(withStack):
      sheet = AnyRoute(wrapped: destination, inStack: withStack)
    case .cover:
      cover = AnyRoute(wrapped: destination)
    case .root:
      root = AnyRoute(wrapped: destination)
    }
  }

  func removeContext(old: [AnyRoute], new: [AnyRoute]) {
    let count = old.count - new.count
    guard count > 0 else { return }

    for element in contexts.all(for: path.suffix(count).map(\.wrapped)) {
      contexts.remove(element)
      log(.context(.remove(element.route, context: element.routerContext)))
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
  /// 3. Optionally overrides the root route.
  /// 4. Pushes the intermediate routes defined in the deeplink's path.
  /// 5. Navigates to the final destination route with the specified presentation type (if provided).
  ///
  /// - Parameter deeplink: The `DeeplinkRoute` containing the navigation path and optional target route.
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
    if let targetRoute = deeplink.route {
      route(to: targetRoute, type: deeplink.type)
    }
  }
}

// MARK: - Split navigation

public extension Router {

  /// Returns a typed `Binding<T?>` wired to the content column selection.
  ///
  /// Returns `.constant(nil)` when this is not a split router.
  ///
  /// ```swift
  /// List(items, selection: router.contentBinding(as: PlayerType.self)) { ... }
  /// ```
  func contentBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    guard case .split = self.type else { return .constant(nil) }
    return Binding(
      get: { [weak self] in self?.contentSelection as? T },
      set: { [weak self] in self?.contentSelection = $0.map(AnyHashable.init) }
    )
  }

  /// Returns a typed `Binding<T?>` wired to the detail column selection.
  ///
  /// Returns `.constant(nil)` when this is not a split router.
  ///
  /// ```swift
  /// List(items, selection: router.detailBinding(as: Player.self)) { ... }
  /// ```
  func detailBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    guard case .split = self.type else { return .constant(nil) }
    return Binding(
      get: { [weak self] in self?.detailSelection as? T },
      set: { [weak self] in self?.detailSelection = $0.map(AnyHashable.init) }
    )
  }

  /// Programmatically sets the content column selection.
  ///
  /// No-op when this is not a split router.
  @MainActor func select<T: Hashable & Sendable>(content value: T?) {
    guard case .split = type else { return }
//    log(.navigation(from: currentRoute.wrapped, to: destination, type: type))
    contentSelection = value.map(AnyHashable.init)
  }

  /// Programmatically sets the detail column selection.
  ///
  /// No-op when this is not a split router.
  @MainActor func select<T: Hashable & Sendable>(detail value: T?) {
    guard case .split = type else { return }
    detailSelection = value.map(AnyHashable.init)
  }
}
