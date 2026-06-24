//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI

/// Manages programmatic navigation for both stack-based and split-view contexts.
///
/// Each `RoutingView` and `RoutingSplitView2` creates its own `Router`. The router type
/// is encoded in ``RouterType`` — `.stack`, `.tab`, `.presented`, or `.split`.
///
/// ## Stack navigation
/// ```swift
/// @Environment(\.router) var router
///
/// router.push(HomeRoute.page2)
/// router.present(HomeRoute.settings)
/// router.back()
/// ```
///
/// ## Split view navigation
///
/// Inside a `RoutingSplitView2`, `\(router)` is the split router. Use it to drive
/// column selections instead of push navigation:
/// ```swift
/// @Environment(\.router) var router
///
/// router.select(detail: player)          // drives the detail column
/// router.select(content: playerType)     // drives the content column (3-column only)
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

  /// The currently visible route.
  ///
  /// - For **stack** routers: the last pushed route, or the root if the stack is empty.
  /// - For **split** routers: the active detail route resolved from `detailSelection`,
  ///   or the active content route from `contentSelection`, or the sidebar root if
  ///   no column is selected yet.
  ///
  /// ```swift
  /// print(router.currentRoute.name)
  /// ```
  override public var currentRoute: AnyRoute {
    switch type {
    case .split:
      if let route = path.last { return route }
      if let details = detailSelection, let route = detailRouteFactory?(details) { return route }
      if let content = contentSelection, let route = contentRouteFactory?(content) { return route }
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

  /// Whether the split view is currently in compact (single-column) mode.
  ///
  /// `true` on iPhone at launch and whenever `horizontalSizeClass` becomes `.compact`
  /// (e.g. during iPad multitasking). Always `false` for non-split routers.
  ///
  /// Use this to adapt sidebar behaviour — e.g. skip auto-selection on iPhone so the
  /// user's first tap triggers navigation rather than a silent highlight.
  ///
  /// ```swift
  /// .onFirstAppear {
  ///   guard !router.isCompact else { return }
  ///   router.select(detail: items.first)
  /// }
  /// ```
  @Published public internal(set) var isCompact: Bool = false

  /// Whether this split router was created with a content column (3-column layout).
  ///
  /// `true` when `RoutingSplitView2` was initialised with a `content:` closure.
  /// Always `false` for 2-column layouts and non-split routers.
  ///
  /// ```swift
  /// if router.hasContentColumn {
  ///   router.select(content: playerType)
  /// } else {
  ///   router.select(detail: playerType)
  /// }
  /// ```
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

  /// Returns a typed `Binding<T?>` wired to the content column selection (3-column layout).
  ///
  /// Intended for use in the sidebar of a 3-column `RoutingSplitView2` to drive the
  /// content column via a `List` selection binding.
  /// Returns `.constant(nil)` for non-split routers.
  ///
  /// ```swift
  /// List(playerTypes, selection: router.contentBinding(as: PlayerType.self)) { type in
  ///   NavigationLink(type.label, value: type)
  /// }
  /// ```
  func contentBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    guard self.type.isSplit else { return .constant(nil) }
    return Binding(
      get: { [weak self] in self?.contentSelection as? T },
      set: { [weak self] in self?.contentSelection = $0.map(AnyHashable.init) }
    )
  }

  /// Returns a typed `Binding<T?>` wired to the detail column selection.
  ///
  /// Intended for use in the sidebar (2-column) or content column (3-column) of a
  /// `RoutingSplitView2` to drive the detail column via a `List` selection binding.
  /// Returns `.constant(nil)` for non-split routers.
  ///
  /// ```swift
  /// List(players, selection: router.detailBinding(as: Player.self)) { player in
  ///   NavigationLink(player.name, value: player)
  /// }
  /// ```
  func detailBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    guard self.type.isSplit else { return .constant(nil) }
    return Binding(
      get: { [weak self] in self?.detailSelection as? T },
      set: { [weak self] in self?.detailSelection = $0.map(AnyHashable.init) }
    )
  }

  /// Programmatically drives the content column selection (3-column layout).
  ///
  /// Equivalent to the user tapping a row in the sidebar of a 3-column split view.
  /// No-op for non-split routers or when `hasContentColumn` is `false`.
  ///
  /// ```swift
  /// .onFirstAppear {
  ///   router.select(content: playerTypes.first)
  /// }
  /// ```
  @MainActor func select<T: Hashable & Sendable>(content value: T?) {
    guard type.isSplit else { return }

    guard let content = value.map(AnyHashable.init), let route = contentRouteFactory?(content) else { return }
    log(.navigation(from: currentRoute.wrapped, to: route.wrapped, type: .push))


    contentSelection = content
  }

  /// Programmatically drives the detail column selection.
  ///
  /// Equivalent to the user tapping a row in the sidebar (2-column) or content column
  /// (3-column). No-op for non-split routers.
  ///
  /// ```swift
  /// .onFirstAppear {
  ///   guard !router.isCompact else { return }
  ///   router.select(detail: players.first)
  /// }
  /// ```
  @MainActor func select<T: Hashable & Sendable>(detail value: T?) {
    guard type.isSplit else { return }

    guard let details = value.map(AnyHashable.init), let route = detailRouteFactory?(details) else { return }
    log(.navigation(from: currentRoute.wrapped, to: route.wrapped, type: .push))

    detailSelection = details
  }
}
