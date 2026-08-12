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
    let currentDate = Date()
    defer { lastDateLog = currentDate }
    return Self.shouldLog(lastDateLog: lastDateLog, currentDate: currentDate)
  }

  /// Pure debounce decision, kept separate from `@State` so it can be tested without a live view hierarchy.
  static func shouldLog(lastDateLog: Date?, currentDate: Date) -> Bool {
    guard let lastDateLog else { return true }
    return currentDate.timeIntervalSince(lastDateLog) >= 0.05
  }
}
