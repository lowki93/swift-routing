//
//  LifecycleModifier.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

struct LifecycleModifier: ViewModifier {

  @Environment(\.router) private var router
  @State private var lastDateLog: Date?
  let route: any Route

  func body(content: Content) -> some View {
    content
      .onAppear {
        guard shouldLog() else { return }
        router.log(.onAppear(route))
      }
      .onDisappear {
        guard shouldLog() else { return }
        router.log(.onDisappear(route))
      }
  }

  func shouldLog() -> Bool {
    if let last = lastDateLog, Date().timeIntervalSince(last) < 0.05 {
      lastDateLog = Date()
      return false
    }

    lastDateLog = Date()
    return true
  }
}

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

public extension View {
  func splitRouterRouteToContent(_ route: (some Route)?) -> some View {
    self.modifier(SplitRouterContentModifier(route: route.flatMap { AnyRoute(wrapped: $0) }))
  }
}


struct SplitRouterDetailModifier: ViewModifier {

  @Environment(\.splitRouter) private var splitRouter
  let route: AnyRoute?

  func body(content: Content) -> some View {
    content
      .onChange(of: route) {
        guard let route else { return }
        splitRouter?.route(detail: route.wrapped)
      }
  }
}

public extension View {
  func splitRouterRouteToDetails(_ route: (some Route)?) -> some View {
    self.modifier(SplitRouterDetailModifier(route: route.flatMap { AnyRoute(wrapped: $0) }))
  }
}
