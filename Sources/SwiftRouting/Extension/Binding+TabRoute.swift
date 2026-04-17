//
//  Binding+TabRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public extension Binding where Value: TabRoute {

  /// Clears the navigation path of the specified tab, with optional reselection handling.
  ///
  /// This function locates the router associated with the current tab and resets its navigation path.
  /// - If the selected tab matches the new value, it triggers `popToRoot()` then calls `onReselected` if provided.
  /// - Otherwise, it updates the tab selection.
  ///
  /// - Parameters:
  ///   - tab: A binding to the current tab.
  ///   - router: The router managing the tabview.
  ///   - onReselected: An optional closure invoked when the user taps the already-selected tab.
  ///     When provided, replaces the default `popToRoot()` behavior. Always called on the main actor.
  /// - Returns: A binding that updates the tab and clears its navigation stack when reselected.
  ///
  /// ## Usage
  /// ```swift
  /// TabView(selection: .tabToRoot(for: $tab, in: router, onReselected: { tab in
  ///   scrollToTop(for: tab)
  /// })) {
  ///   // tab content
  /// }
  /// ```
  @MainActor static func tabToRoot(
    for tab: Binding<Value>,
    in router: BaseRouter,
    onReselected: ((Value) -> Void)? = nil
  ) -> Binding<Value> {
    Binding(
      get: { tab.wrappedValue },
      set: {
        if tab.wrappedValue == $0 {
          router.find(tab: $0)?.popToRoot()
          onReselected?($0)
        } else {
          tab.wrappedValue = $0
          if let tabRouter = router as? TabRouter {
            tabRouter.change(tab: $0)
          }
        }
      }
    )
  }
}
