//
//  RouterModel+View.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import SwiftUI

public extension View {

  func route(from model: some RouterModel, in router: Router) -> some View {
    self
      .onChange(of: model.routeTo?.route) {
        if let next = model.routeTo {
          router.route(to: next.route, type: next.type)
          model.routeTo = nil
        }
      }
  }
}
