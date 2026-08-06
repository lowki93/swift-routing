//
//  RouterSpy.swift
//  SwiftRoutingTestSupport
//

import Combine
import SwiftUI
import SwiftRouting

/// A `RouterModel` test double that records every call instead of performing real navigation.
///
/// Inject `RouterSpy` wherever your code depends on `any RouterModel` and assert on the
/// recorded arrays/counters afterwards.
///
/// ```swift
/// let spy = RouterSpy(root: AppRoute.home)
/// let viewModel = ProfileViewModel(router: spy)
///
/// viewModel.openSettings()
///
/// #expect(spy.presentedRoutes.last?.route as? AppRoute == .settings)
/// ```
///
/// > Note:
/// > `tabRouter(for:)`, `findRouterInTabRouter(for:)`, and `deepestRouter()` always return `nil` —
/// > `RouterSpy` has no real router hierarchy to search. If your code depends on these, test it
/// > against a real `Router` instead.
public final class RouterSpy: ObservableObject, RouterModel, @unchecked Sendable {

  // MARK: - State

  public var root: AnyRoute
  @Published public var currentRoute: AnyRoute
  public var pathCount: Int = 0
  public var isPresented: Bool = false
  public var tabRouter: TabRouter?
  @Published public var detailSelection: AnyHashable?
  @Published public var contentSelection: AnyHashable?
  public var isCompact: Bool = false
  public var hasContentColumn: Bool = false
  public var detailRouteFactory: ((AnyHashable) -> AnyRoute?)?
  public var contentRouteFactory: ((AnyHashable) -> AnyRoute?)?

  // MARK: - Recorded calls

  public private(set) var routedDestinations: [any Route] = []
  public private(set) var updatedRoots: [any Route] = []
  public private(set) var pushedRoutes: [any Route] = []
  public private(set) var presentedRoutes: [(route: any Route, withStack: Bool)] = []
  public private(set) var coveredRoutes: [any Route] = []
  public private(set) var popToRootCallCount = 0
  public private(set) var closeCallCount = 0
  public private(set) var closeChildrenCallCount = 0
  public private(set) var backCallCount = 0
  public private(set) var terminatedContexts: [Any] = []
  public private(set) var dispatchedContexts: [Any] = []
  public private(set) var addedContextTypes: [Any.Type] = []
  public private(set) var removedContextTypes: [Any.Type] = []
  public private(set) var contentSelections: [AnyHashable] = []
  public private(set) var detailSelections: [AnyHashable] = []

  private var contextHandlers: [ObjectIdentifier: (Any) -> Void] = [:]

  // MARK: - Init

  public init(root: some Route) {
    self.root = AnyRoute(root)
    self.currentRoute = AnyRoute(root)
  }

  // MARK: - RouterModel

  public func route(_ destination: some Route) {
    routedDestinations.append(destination)
  }

  public func update(root destination: some Route) {
    updatedRoots.append(destination)
    root = AnyRoute(destination)
    currentRoute = AnyRoute(destination)
    pathCount = 0
  }

  public func push(_ destination: some Route) {
    pushedRoutes.append(destination)
    currentRoute = AnyRoute(destination)
    pathCount += 1
  }

  public func popToRoot() {
    popToRootCallCount += 1
    currentRoute = root
    pathCount = 0
  }

  public func back() {
    backCallCount += 1
    pathCount = max(0, pathCount - 1)
  }

  public func terminate(_ value: some RouteContext) {
    terminatedContexts.append(value)
  }

  // MARK: - PresentationModel

  public func present(_ destination: some Route, withStack: Bool) {
    presentedRoutes.append((destination, withStack))
  }

  public func cover(_ destination: some Route) {
    coveredRoutes.append(destination)
  }

  public func close() {
    closeCallCount += 1
  }

  public func closeChildren() {
    closeChildrenCallCount += 1
  }

  // MARK: - ContextModel

  public func add<R: RouteContext>(context object: R.Type, perform: @escaping (R) -> Void) {
    addedContextTypes.append(object)
    contextHandlers[ObjectIdentifier(object)] = { any in
      if let value = any as? R { perform(value) }
    }
  }

  public func remove<R: RouteContext>(context object: R.Type) {
    removedContextTypes.append(object)
    contextHandlers[ObjectIdentifier(object)] = nil
  }

  public func context(_ value: some RouteContext) {
    dispatchedContexts.append(value)
    contextHandlers[ObjectIdentifier(type(of: value))]?(value)
  }

  public func canTerminate<R: RouteContext>(_ type: R.Type) -> Bool {
    contextHandlers[ObjectIdentifier(type)] != nil
  }

  // MARK: - SplitModel

  public func contentBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    Binding(
      get: { [weak self] in self?.contentSelection as? T },
      set: { [weak self] in self?.select(content: $0) }
    )
  }

  public func detailBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    Binding(
      get: { [weak self] in self?.detailSelection as? T },
      set: { [weak self] in self?.select(detail: $0) }
    )
  }

  public func select<T: Hashable & Sendable>(content value: T?) {
    guard let value else {
      contentSelection = nil
      return
    }
    contentSelections.append(AnyHashable(value))
    contentSelection = AnyHashable(value)
  }

  public func select<T: Hashable & Sendable>(detail value: T?) {
    guard let value else {
      detailSelection = nil
      return
    }
    detailSelections.append(AnyHashable(value))
    detailSelection = AnyHashable(value)
  }

  // MARK: - BaseRouterModel (unsupported without a real hierarchy)

  public func tabRouter(for tabRoute: some TabRoute) -> TabRouter? { nil }
  public func findRouterInTabRouter(for tabRoute: some TabRoute) -> Router? { nil }
  public func clearChildren() { }
  @MainActor public func deepestRouter() -> Router? { nil }
}
