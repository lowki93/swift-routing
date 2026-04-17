//
//  TabReselectedModifier.swift
//  SwiftRouting
//

import Combine
import SwiftUI

private struct TabReselectedModifier<Tab: TabRoute>: ViewModifier {

  @Environment(\.tabRouter) private var tabRouter
  let tab: Tab
  let action: () -> Void

  func body(content: Content) -> some View {
    content
      .onReceive(
        tabRouter?.tabReselected.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
      ) { reselectedTab in
        guard reselectedTab.wrapped as? Tab == tab else { return }
        action()
      }
  }
}

public extension View {

  /// Adds a handler called when the user taps the already-selected tab.
  ///
  /// Use this modifier from any view inside a `RoutingTabView` to react to same-tab taps,
  /// without affecting the default `popToRoot` behavior (which still fires).
  ///
  /// The handler is only triggered when the reselected tab matches `tab`.
  /// It is always called on the main actor, after `popToRoot()` has been applied.
  ///
  /// ```swift
  /// struct HomeView: View {
  ///   @ScrollViewProxy var scrollProxy
  ///
  ///   var body: some View {
  ///     ScrollView {
  ///       // ...
  ///     }
  ///     .onTabReselected(HomeTab.home) {
  ///       scrollProxy.scrollTo("top", anchor: .top)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - tab: The tab whose reselection should trigger `action`.
  ///   - action: A closure called when `tab` is reselected. No-op if used outside a `RoutingTabView`.
  func onTabReselected<Tab: TabRoute>(_ tab: Tab, perform action: @escaping () -> Void) -> some View {
    modifier(TabReselectedModifier(tab: tab, action: action))
  }
}
