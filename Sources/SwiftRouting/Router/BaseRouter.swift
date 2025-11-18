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

  /// Publisher to know if a router is present or not
  let present: PassthroughSubject<Bool, Never>

  /// The parent router, if any. Used for hierarchical navigation structures.
  weak var parent: BaseRouter?

  var contexts: Set<RouterContext> = []

  /// A dictionary containing child routers, stored weakly to avoid retain cycles.
  var children: [UUID: WeakContainer<BaseRouter>] = [:]

  /// Initializes a `BaseRouter` with a given configuration and an optional parent.
  ///
  /// - Parameters:
  ///   - configuration: The configuration settings to be used by the router.
  ///   - parent: The parent `Router`, if applicable.
  init(configuration: Configuration, parent: BaseRouter? = nil) {
    self.configuration = configuration
    self.present = parent?.present ?? PassthroughSubject()
    self.parent = parent
    log(.create(from: parent))
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

// MARK: - Tab Management

public extension BaseRouter {

  /// Finds the corresponding `Router` for a given tab.
  ///
  /// This method searches among the child routers to locate the one managing the specified tab.
  ///
  /// - Parameter tab: The `TabRoute` to search for.
  /// - Returns: The `Router` managing the specified tab, if found.
  @MainActor @discardableResult func find(tab: some TabRoute) -> Router? {
    children.values.compactMap({ $0.value as? Router }).first(where: { $0.type == tab.type })
  }
}

// MARK: - TabRouter

public extension BaseRouter {

  /// Finds and returns a `TabRouter` instance associated with the given `TabRoute` type.
  ///
  /// - Parameter tabRoute: The `TabRoute` for which to find the corresponding `TabRouter`.
  /// - Returns: The `TabRouter` associated with the given tab, or `nil` if not found.
  func tabRouter(for tabRoute: some TabRoute) -> TabRouter? {
    let tabRouters = children.compactMap { $0.value.value as? TabRouter }

    return tabRouters.first { type(of: $0.tab.wrapped) == type(of: tabRoute) }
  }

  /// Finds the `Router` instance managing a specific tab within a `TabRouter`.
  ///
  /// This method first locates the `TabRouter` corresponding to the provided `TabRoute`,
  /// then searches inside it to find the `Router` managing that specific tab.
  ///
  /// - Parameter tabRoute: The `TabRoute` representing the tab to search for.
  /// - Returns: The `Router` instance managing the specified tab, or `nil` if it is not found.
  @MainActor func findRouterInTabRouter(for tabRoute: some TabRoute) -> Router? {
    tabRouter(for: tabRoute)?.find(tab: tabRoute)
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
    } else {
      "baseRouter"
    }
  }
}
