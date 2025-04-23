//
//  LifecycleModifier.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

struct LifecycleModifier: ViewModifier {

  @Environment(\.router) private var router
  let route: any Route
  let logAction: LoggerAction = .viewLifecycle

  func body(content: Content) -> some View {
    content
      .onAppear { router.log(logAction, metadata: ["OnAppear": route]) }
      .onDisappear { router.log(logAction, metadata: ["Disappear": route]) }
  }
}
