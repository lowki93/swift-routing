//
//  Binding+TabRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public extension Binding where Value: TabRoute {

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
