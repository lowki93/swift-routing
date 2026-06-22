//
//  BaseRouter.swift
//  swift-routing
//
//  Created by Kevin Budain on 09/03/2025.
//

import Combine
import Foundation
import Observation

/// A base class for all router types, including `Router` and `TabRouter`.
///
/// `BaseRouter` manages parent-child relationships between routers and provides logging capabilities.
/// It serves as the foundation for navigation management.
public class BaseRouter: ObservableObject, Identifiable {

  /// Unique identifier for the router instance.
  public let id: UUID = UUID()

  /// The configuration settings for the router, including logging behavior.
  let configuration: Configuration

  @Published public var root: AnyRoute {
    willSet {
      for context in contexts.all(for: root.wrapped) {
        contexts.remove(context)
        log(.context(.remove(context.route, context: context.routerContext)))
      }
    }
  }

  /// Publisher to know if a router is present or not
  let present: PassthroughSubject<(Bool, BaseRouter), Never>

  /// Emits whenever the user taps the already-selected tab.
  ///
  /// Observe this publisher from any view using ``onTabReselected(_:perform:)``.
  /// On routers not managed by a `TabRouter`, this subject never emits.
  let tabReselected = PassthroughSubject<AnyTabRoute, Never>()

  /// The parent router, if any. Used for hierarchical navigation structures.
  weak var parent: BaseRouter?

  var contexts: Set<RouterContext> = []

  /// The currently visible route managed by this router.
  ///
  /// Subclasses override this to return their active route.
  /// Defaults to ``DefaultRoute/main`` for base instances.
  public var currentRoute: AnyRoute {
    root
  }

  public var pathCount: Int { 0 }

  /// A dictionary containing child routers, stored weakly to avoid retain cycles.
  var children: [UUID: WeakContainer<BaseRouter>] = [:]


  /// Initializes a `BaseRouter` with a given configuration and an optional parent.
  ///
  /// - Parameters:
  ///   - configuration: The configuration settings to be used by the router.
  ///   - parent: The parent `Router`, if applicable.
  init(configuration: Configuration, root: AnyRoute, parent: BaseRouter? = nil, first: Bool = false) {
    self.configuration = configuration
    self.root = root
    self.present = parent?.present ?? PassthroughSubject()
    self.parent = parent
    log(.create(from: parent, first ? configuration : nil))
  }

  /// Deinitializer that removes the router from its parent's children and logs its destruction.
  deinit {
    parent?.removeChild(self)
    log(.delete)
  }

  /// Adds a child router to the current router.
  ///
  /// - Parameter child: The child `BaseRouter` to be added.
  func addChild(_ child: BaseRouter) {
    children[child.id] = WeakContainer(value: child)
  }

  /// Removes a child router from the current router.
  ///
  /// - Parameter child: The child `BaseRouter` to be removed.
  func removeChild(_ child: BaseRouter) {
    children.removeValue(forKey: child.id)
  }

  @MainActor public func clearChildren() {
    children.removeAll()
  }

  /// Logs an event related to the router lifecycle or navigation actions.
  ///
  /// - Parameters:
  ///   - message: The type of message being logged.
  func log(_ message: LoggerMessage) {
    configuration.logger?(LoggerConfiguration(message: message, router: self))
  }
}

// MARK: - ContextModel

extension BaseRouter: @preconcurrency ContextModel {

  @MainActor public func add<R: RouteContext>(context object: R.Type, perform: @escaping (R) -> Void) {
    let (inserted, element) = contexts.insert(
      RouterContext(
        router: self,
        routerContext: object,
        action: { [perform] in
          guard let value = $0 as? R else { return }
          perform(value)
        }
      )
    )
    if inserted {
      log(.context(.add(element.route, context: element.routerContext)))
    }
  }

  @MainActor public func remove<R: RouteContext>(context object: R.Type) {
    for element in contexts.all(for: object, currentRoute: currentRoute.wrapped) {
      contexts.remove(element)
      log(.context(.remove(element.route, context: element.routerContext)))
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
}

// MARK: - Tab Management

public extension BaseRouter {

  /// Finds the corresponding `Router` for a given tab.
  ///
  /// This method searches among the child routers to locate the one managing the specified tab.
  ///
  /// - Parameter tab: The `TabRoute` to search for.
  /// - Returns: The `Router` managing the specified tab, if found.
  @MainActor @discardableResult func find(tab: any TabRoute) -> Router? {
    children.values.compactMap({ $0.value as? Router }).first(where: { $0.type == tab.type })
  }
}

// MARK: - BaseRouterModel

extension BaseRouter: @preconcurrency BaseRouterModel {

  public var tabRouter: TabRouter? {
    let tabRouters = children.compactMap { $0.value.value as? TabRouter }

    return tabRouters.count == 1 ? tabRouters.first : nil
  }

  public func tabRouter(for tabRoute: some TabRoute) -> TabRouter? {
    let tabRouters = children.compactMap { $0.value.value as? TabRouter }

    return tabRouters.first { type(of: $0.tab.wrapped) == type(of: tabRoute) }
  }

  @MainActor public func findRouterInTabRouter(for tabRoute: some TabRoute) -> Router? {
    tabRouter(for: tabRoute)?.find(tab: tabRoute)
  }

  @MainActor public func deepestRouter() -> Router? {
    let liveChildren = children.values.compactMap { $0.value as? Router }
    return liveChildren.last?.deepestRouter() ?? self as? Router
  }
}

/// Provides a textual representation of a `BaseRouter` instance.
extension BaseRouter: CustomStringConvertible {

  /// A string description of the router instance.
  public var description: String {
    if let router = self as? Router {
      "router(\(String(describing: router.type)))"
    } else if let tabRouter = self as? TabRouter {
      "tabRouter(\(String(describing: type(of: tabRouter.tab.wrapped)).lowercased()))"
    } else if self is SplitRouter {
      "splitRouter"
    } else {
      "baseRouter"
    }
  }
}
