//
//  PendingTabDeeplinkConsumer.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting
import SwiftUI

// Tab-scoped sibling of PendingDeeplinkConsumer: TabView keeps all 3 tabs mounted at once,
// so every tab's instance observes the same PendingDeeplinkStore -- only the one whose
// `tab` matches the identifier's implied tab actually applies it, the others no-op.
struct PendingTabDeeplinkConsumer: ViewModifier {
  let tab: HomeTab
  @Environment(\.router) private var router
  @Environment(PendingDeeplinkStore.self) private var pendingDeeplink

  func body(content: Content) -> some View {
    content
      .task(id: pendingDeeplink.identifier) {
        guard case let .tabView(target) = pendingDeeplink.identifier, target.tab == tab else { return }
        guard let identifier = pendingDeeplink.identifier,
              let deeplink = try? await AppDeeplinkHandler().deeplink(from: identifier) else {
          pendingDeeplink.identifier = nil
          return
        }
        router.handle(deeplink: deeplink)
        pendingDeeplink.identifier = nil
      }
  }
}
