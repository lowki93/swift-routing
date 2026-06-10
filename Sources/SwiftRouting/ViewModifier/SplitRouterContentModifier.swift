//
//  SplitRouterDetailModifier.swift
//  swift-routing
//
//  Created by Kevin Budain on 25/04/2026.
//

import SwiftUI

struct SplitRouterContentModifier: ViewModifier {

  @Environment(\.splitRouter) private var splitRouter
  let route: AnyRoute?

  func body(content: Content) -> some View {
    content
      .onChange(of: route) { newRoute in
        guard let newRoute else { return }
        splitRouter?.route(content: newRoute.wrapped)
      }
  }
}

public extension View {
  func splitRouterRouteToContent(_ route: (some Route)?) -> some View {
    self.modifier(SplitRouterContentModifier(route: route.flatMap { AnyRoute(wrapped: $0) }))
  }
}
