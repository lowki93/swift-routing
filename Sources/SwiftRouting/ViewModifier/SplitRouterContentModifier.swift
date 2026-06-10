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
      .onChange(of: route) {
        guard let route else { return }
        splitRouter?.route(content: route.wrapped)
      }
  }
}

struct SplitRouterdetailsModifier: ViewModifier {

  @Environment(\.splitRouter) private var splitRouter
  @Environment(\.router) private var router
  let route: AnyRoute?
  let pushRoute: AnyRoute?

  func body(content: Content) -> some View {
    content
      .onChange(of: route) {
        guard let route else { return }
        splitRouter?.route(detail: route.wrapped)
      }
      .onChange(of: pushRoute) {
        guard let pushRoute else { return }
        router.push(pushRoute.wrapped)
      }
  }
}

public extension View {
  func splitRouterRouteToContent(_ route: (some Route)?) -> some View {
    self.modifier(SplitRouterContentModifier(route: route.flatMap { AnyRoute(wrapped: $0) }))
  }

  func splitRouterRouteToDetails(_ route: (some Route)?) -> some View {
    self.modifier(SplitRouterdetailsModifier(route: route.flatMap { AnyRoute(wrapped: $0) }, pushRoute: nil))
  }

  func splitRouterPush(_ route: (some Route)?) -> some View {
    self.modifier(SplitRouterdetailsModifier(route: nil, pushRoute: route.flatMap { AnyRoute(wrapped: $0) }))
  }
}
