//
//  Binding+TabRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public extension Binding where Value: TabRoute {

  /// Clears the navigation path of the specified tab.
  ///
  /// This function locates the router associated with the current tab and resets its navigation path.
  /// If the selected tab is the same as the new value, it triggers `popToRoot()`, otherwise, it updates the tab selection.
  ///
  /// - Parameters:
  ///   - tab: A binding to the current tab.
  ///   - router: The router managing the tabview.
  /// - Returns: A binding that updates the tab and clears its navigation stack when reselected.
  @MainActor
  static func tabToRoot(for tab: Binding<Value>, in router: Router) -> Binding<Value> {
    Binding(
      get: { tab.wrappedValue },
      set: {
        if tab.wrappedValue == $0 {
          router.find(tab: $0)?.popToRoot()
        } else {
          tab.wrappedValue = $0
        }
      }
    )
  }
}
