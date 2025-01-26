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

  func body(content: Content) -> some View {
    content
      .onAppear { router.onAppear(route) }
      .onDisappear() { router.onDisappear(route) }
  }
}
