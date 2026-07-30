//
//  TabRouterSpy.swift
//  SwiftRoutingTestSupport
//

import Combine
import SwiftRouting

/// A `TabRouterModel` test double that records every call instead of performing real navigation.
///
/// Inject `TabRouterSpy` wherever your code depends on `any TabRouterModel` and assert on the
/// recorded arrays afterwards.
///
/// ```swift
/// let spy = TabRouterSpy(root: AppRoute.home)
/// let viewModel = ProfileViewModel(tabRouter: spy)
///
/// viewModel.openProfileSettings()
///
/// #expect(spy.changedTabs.last as? HomeTab == .profile)
/// #expect(spy.pushedRoutes.last?.route as? HomeRoute == .settings)
/// ```
///
/// > Note:
/// > `tabRouter(for:)`, `findRouterInTabRouter(for:)`, and `deepestRouter()` always return `nil` —
/// > `TabRouterSpy` has no real router hierarchy to search. If your code depends on these, test it
/// > against a real `TabRouter` instead.
public final class TabRouterSpy: ObservableObject, TabRouterModel {

  // MARK: - State

  public var root: AnyRoute
  public var tabRouter: TabRouter?

  // MARK: - Recorded calls

  public private(set) var changedTabs: [any TabRoute] = []
  public private(set) var updatedRoots: [(route: any Route, tab: (any TabRoute)?)] = []
  public private(set) var pushedRoutes: [(route: any Route, tab: (any TabRoute)?)] = []
  public private(set) var presentedRoutes: [(route: any Route, tab: (any TabRoute)?)] = []
  public private(set) var coveredRoutes: [(route: any Route, tab: (any TabRoute)?)] = []
  public private(set) var popToRootTabs: [(any TabRoute)?] = []

  // MARK: - Init

  public init(root: some Route) {
    self.root = AnyRoute(root)
  }

  // MARK: - TabRouterModel

  public func change(tab: some TabRoute) {
    changedTabs.append(tab)
  }

  public func update(root destination: some Route, in tab: (any TabRoute)?) {
    updatedRoots.append((destination, tab))
  }

  public func push(_ destination: some Route, in tab: (any TabRoute)?) {
    pushedRoutes.append((destination, tab))
  }

  public func present(_ destination: some Route, in tab: (any TabRoute)?) {
    presentedRoutes.append((destination, tab))
  }

  public func cover(_ destination: some Route, in tab: (any TabRoute)?) {
    coveredRoutes.append((destination, tab))
  }

  public func popToRoot(in tab: (any TabRoute)?) {
    popToRootTabs.append(tab)
  }

  // MARK: - BaseRouterModel (unsupported without a real hierarchy)

  public func tabRouter(for tabRoute: some TabRoute) -> TabRouter? { nil }
  public func findRouterInTabRouter(for tabRoute: some TabRoute) -> Router? { nil }
  public func clearChildren() { }
  @MainActor public func deepestRouter() -> Router? { nil }
}
