//
//  HideTabBarModifier.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/6/25.
//

import SwiftUI

public struct HideTabBarModifier: ViewModifier {
  @Environment(\.router) private var router

  public func body(content: Content) -> some View {
    // TODO: [TabBarRouter] check if TabBarRouter has router ihas a child
    if router.hideTabBar {
      content
        .toolbar(.hidden, for: .tabBar)
    }
  }
}
