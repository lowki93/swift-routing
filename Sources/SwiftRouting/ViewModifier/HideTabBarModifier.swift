//
//  HideTabBarModifier.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/6/25.
//

import SwiftUI

struct HideTabBarModifier: ViewModifier {
  @Environment(\.router) private var router

  func body(content: Content) -> some View {
    #if os(iOS)
    if case let .tab(_, hideTabBarOnPush) = router.type, hideTabBarOnPush {
      content
        .toolbar(.hidden, for: .tabBar)
    } else {
      content
    }
    #else
    content
    #endif
  }
}
