//
//  LifecycleModifier.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

struct LifecycleModifier: ViewModifier {

  @Environment(\.router) private var router
  @Environment(\.currentRouter) private var currentRouter
  @State private var lastDateLog: Date?
  let route: any Route

  func body(content: Content) -> some View {
    content
      .onAppear {
        guard shouldLog() else { return }
        (currentRouter ?? router).log(.onAppear(route))
      }
      .onDisappear {
        guard shouldLog() else { return }
        (currentRouter ?? router).log(.onDisappear(route))
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
