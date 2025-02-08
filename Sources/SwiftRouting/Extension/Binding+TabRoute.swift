//
//  Binding+TabRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public extension Binding where Value: TabRoute {
  func tapToRoot(for router: Router) -> Binding<Value> {
    Binding(
      get: { wrappedValue },
      set: {
        if $0 == wrappedValue {
          router.findChild(from: .tab($0.name))?.popToRoot()
        } else {
          wrappedValue == $0
        }
      }
    )
  }
}
