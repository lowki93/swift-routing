//
//  LifecycleModifier.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

struct LifecycleModifier: ViewModifier {

  @Environment(\.router) private var envRouter
  @Environment(\.currentRouter) private var currentRouter
  @State private var lastDateLog: Date?
  let route: any Route
  var explicitRouter: BaseRouter?

  private var effectiveRouter: BaseRouter {
    explicitRouter ?? currentRouter ?? envRouter
  }

  func body(content: Content) -> some View {
    content
      .onAppear {
        guard shouldLog() else { return }
        effectiveRouter.log(.onAppear(route))
      }
      .onDisappear {
        guard shouldLog() else { return }
        effectiveRouter.log(.onDisappear(route))
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
