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

  /// Guards `_children` -- `addChild`/`removeChild` run from `init`/`deinit`, which are not
  /// `@MainActor`-isolated, so a router's last reference can be released from any thread.
  private let childrenLock = NSLock()
  private var _children: [UUID: WeakContainer<BaseRouter>] = [:]

  /// A dictionary containing child routers, stored weakly to avoid retain cycles.
  ///
  /// Returns a locked snapshot; safe to iterate without holding any lock afterward since
  /// `Dictionary` is a value type.
  var children: [UUID: WeakContainer<BaseRouter>] {
    childrenLock.withLock { _children }
  }


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
    childrenLock.withLock { _children[child.id] = WeakContainer(value: child) }
  }

  /// Removes a child router from the current router.
  ///
  /// - Parameter child: The child `BaseRouter` to be removed.
  func removeChild(_ child: BaseRouter) {
    childrenLock.withLock { _ = _children.removeValue(forKey: child.id) }
  }

  @MainActor public func clearChildren() {
    childrenLock.withLock { _children.removeAll() }
  }

  /// Logs an event related to the router lifecycle or navigation actions.
  ///
  /// - Parameters:
  ///   - message: The type of message being logged.
  func log(_ message: LoggerMessage) {
    configuration.logger?(LoggerConfiguration(message: message, router: self))

    guard message.shouldTriggerEvent else { return }

    // Notify `events` that *something* happened, without passing `self`/`router` into the
    // escaping closure below: `log` can run from `deinit` (e.g. for `.delete`), and
    // capturing a strong reference to `self` there -- even indirectly, e.g. via a
    // `LoggerConfiguration` holding `router: self` -- would keep the router alive until
    // this deferred block runs, delaying (or in non-`.delete` cases, silently extending)
    // its deinitialization for every router in the app. `events` only needs to signal
    // "re-check the tree", so it carries no payload at all.
    //
    // Deferred rather than sent synchronously: `events` is a single PassthroughSubject
    // shared across the whole router hierarchy, and calling `send` synchronously from
    // `deinit` can reenter the same subject if a related router also logs around the same
    // time, which crashes Combine. Dispatching to the next run loop tick guarantees `send`
    // never runs nested inside another `log` call.
    nonisolated(unsafe) let events = configuration.events
    Task { @MainActor in
      events.send()
    }
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

  @MainActor public func canTerminate<R: RouteContext>(_ type: R.Type) -> Bool {
    var current: BaseRouter? = self
    while let router = current {
      if router.contexts.contains(for: type) {
        return true
      }
      current = router.parent
    }
    return false
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
    } else {
      "baseRouter"
    }
  }
}

// MARK: - Debug Tree Description

#if DEBUG
extension BaseRouter {

  /// Walks up to the top-most router in the hierarchy (the one with no `parent`).
  var rootRouter: BaseRouter {
    parent?.rootRouter ?? self
  }

  /// Builds a human-readable, indented tree of this router's full hierarchy, starting from
  /// ``rootRouter``. Each line shows ``description``, the router's current route, its full
  /// push stack (if any), and any ``RouteContext`` types registered on it along with the
  /// route each was registered for.
  func routerTreeDescription() -> String {
    rootRouter.treeLines().joined(separator: "\n")
  }

  private func treeLines(prefix: String = "", isRoot: Bool = true, isLast: Bool = true) -> [String] {
    let connector = isRoot ? "" : (isLast ? "└─ " : "├─ ")
    let line = "\(prefix)\(connector)\(description) — current: \(currentRoute.wrapped.description)"

    let childPrefix = isRoot ? "" : prefix + (isLast ? "   " : "│  ")

    // Only `Router` has a push stack at all -- `BaseRouter`/`TabRouter` have no `path`, and
    // an empty `path` means `currentRoute` already shows everything there is (the root), so
    // the line is skipped rather than printed as an uninformative `path: []`.
    let pathDescriptions = (self as? Router)?.path.map(\.wrapped.description) ?? []
    let pathLines = pathDescriptions.isEmpty ? [] : ["\(childPrefix)   path: [\(pathDescriptions.joined(separator: ", "))]"]

    // `contexts` is a Set, whose iteration order is not deterministic -- sort by type name
    // for the same reason `children` is sorted below. Printed on its own line (rather than
    // appended to `line`) so it doesn't compete for space with the route description. Each
    // context is registered against a specific route (not necessarily the router's current
    // one), which matters when a router accumulates contexts across several routes over its
    // lifetime -- so it's shown alongside the context type rather than left implicit.
    let contextDescriptions = contexts
      .map { "\($0.routerContext)(\($0.route.description))" }
      .sorted()
    let contextLines = contextDescriptions.isEmpty ? [] : ["\(childPrefix)   contexts: [\(contextDescriptions.joined(separator: ", "))]"]

    // `children` is a Dictionary, whose iteration order is not deterministic --
    // sort so the printed tree is stable across calls instead of shuffling randomly.
    let sortedChildren = children.values.compactMap(\.value).sorted { $0.id.uuidString < $1.id.uuidString }

    let childLines = sortedChildren.enumerated().flatMap { index, child in
      child.treeLines(prefix: childPrefix, isRoot: false, isLast: index == sortedChildren.count - 1)
    }

    return [line] + pathLines + contextLines + childLines
  }
}
#endif
