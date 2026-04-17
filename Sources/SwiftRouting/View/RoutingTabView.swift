//
//  RoutingTabBar.swift
//  swift-routing
//
//  Created by Kevin Budain on 06/03/2025.
//

import Observation
import SwiftUI

/// A custom `TabView` with its own `TabRouter` for managing tab-based navigation.
///
/// `RoutingTabView` behaves like a standard `TabView` but integrates with `TabRouter`
/// to enable programmatic navigation control.
///
/// ## Usage
/// ```swift
/// @State var tab: HomeTab = .home
///
/// RoutingTabView(tab: $tab, destination: HomeRoute.self) { destination in
///   RoutingView(tab: HomeTab.home, destination: destination, root: .page1)
///   RoutingView(tab: HomeTab.user, destination: destination, root: .page2)
/// }
/// ```
///
/// ## TabToRoot Behavior
/// - If the user taps on the currently selected tab, the navigation stack is reset by default.
/// - Use ``onTabReselected(_:)`` to override this behavior with custom logic.
///
/// ## Notes
/// - You can still use `TabView` without `RoutingTabView` if `TabRouter` is not needed.
/// ```swift
/// @Environment(\.router) var router
/// @State var tab: HomeTab = .home
///
/// TabView(selection: .tabToRoot(for: $tab, in: router)) {
///     RoutingView(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1)
///     RoutingView(tab: HomeTab.tab2, destination: HomeRoute.self) { Page2View() }
/// }
/// ```
@MainActor
public struct RoutingTabView<Tab: TabRoute, Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var parent
  @Binding private var tab: Tab
  private let destination: Destination.Type
  private let content: (Destination.Type) -> Content
  private var onTabReselectedAction: ((Tab) -> Void)?

  /// Initializes a `RoutingTabView` instance.
  ///
  /// - Parameters:
  ///   - tab: A binding to the currently selected tab.
  ///   - destination: The type of the route destination.
  ///   - content: A closure that generates the tab views based on the destination type.
  public init(
    tab: Binding<Tab>,
    destination: Destination.Type,
    @ViewBuilder content: @escaping (Destination.Type) -> Content
  ) {
    self._tab = tab
    self.destination = destination
    self.content = content
  }

  /// Adds a handler called when the user taps the already-selected tab.
  ///
  /// By default, tapping the currently selected tab pops the navigation stack to its root
  /// (`popToRoot`). Use this modifier to replace that behavior with custom logic, such as
  /// scrolling to the top of a list or dismissing a presented screen.
  ///
  /// The closure receives the reselected tab as its argument and is always called on the main actor.
  ///
  /// ```swift
  /// RoutingTabView(tab: $tab, destination: HomeRoute.self) { destination in
  ///   RoutingView(tab: HomeTab.home, destination: destination, root: .page1)
  ///   RoutingView(tab: HomeTab.user, destination: destination, root: .page2)
  /// }
  /// .onTabReselected { tab in
  ///   scrollProxy.scrollTo(top, anchor: .top)
  /// }
  /// ```
  ///
  /// - Parameter action: A closure invoked with the reselected tab. Replaces the default `popToRoot()` behavior.
  /// - Returns: A `RoutingTabView` that calls `action` when the user taps the already-selected tab.
  public func onTabReselected(_ action: @escaping (Tab) -> Void) -> Self {
    var copy = self
    copy.onTabReselectedAction = action
    return copy
  }

  public var body: some View {
    Wrapped(
      tabRouter: TabRouter(tab: tab, parent: parent),
      currentTab: $tab,
      destination: destination,
      onTabReselectedAction: onTabReselectedAction,
      content: content
    )
  }

  private struct Wrapped: View {

    @StateObject var tabRouter: TabRouter
    @Binding var currentTab: Tab
    let destination: Destination.Type
    let onTabReselectedAction: ((Tab) -> Void)?
    let content: (Destination.Type) -> Content

    public var body: some View {
      TabView(selection: .tabToRoot(for: $currentTab, in: tabRouter, onReselected: onTabReselectedAction)) {
        content(destination)
        // TODO: Try to had RoutingView for each child
//        _VariadicView.Tree(TabViewContainer(currentTab: tab, destination: destination)) {
//          content(destination)
//        }
      }
      .environment(\.tabRouter, tabRouter)
      .onReceive(tabRouter.$tab) { [$currentTab] in
        if let tab = $0.wrapped as? Tab, tab != $currentTab.wrappedValue {
          $currentTab.wrappedValue = tab
        }
      }
    }
  }
}

//struct TabViewContainer<Tab: TabRoute, Destination: RouteDestination>: _VariadicView_MultiViewRoot {
//
//  let currentTab: Tab
//  let destination: Destination.Type
//
//  @ViewBuilder
//  func body(children: _VariadicView.Children) -> some View {
//    ForEach(children) { child in
//      if let tab = child.tab(as: Tab.self) {
//        RoutingView(tab: tab, destination: destination) { child }
//      }
//    }
//  }
//}
//
//
//extension View {
//  public func tab(_ tab: some TabRoute) -> some View {
//    _trait(TabTraitKey.self, AnyHashable(tab))
//  }
//}
//
//private struct TabTraitKey: @preconcurrency _ViewTraitKey {
//  @MainActor static var defaultValue: AnyHashable?
//}
//
//extension _VariadicView_Children.Element {
//  var tab: AnyHashable? {
//    self[TabTraitKey.self]
//  }
//
//  func tab<T: TabRoute>(as: T.Type) -> T? {
//    tab as? T
//  }
//}
