//
//  HideTabBarModifier.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/6/25.
//

import SwiftUI

struct HideTabBarModifier: ViewModifier {
  @Environment(\.hideTabBar) private var hideTabBar

  func body(content: Content) -> some View {
    if hideTabBar {
      content
        .toolbar(.hidden, for: .tabBar)
    }
  }
}
