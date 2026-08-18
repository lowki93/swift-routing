//
//  PendingTabRouterDeeplinkConsumer.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting
import SwiftUI

// Single instance, attached to just one tab (.home) of the RoutingTabView. Unlike
// PendingTabDeeplinkConsumer (plain TabView, no TabRouter, so each of the 3 mounted tabs
// needs its own tab-matching consumer), RoutingTabView exposes a real TabRouter via
// \.tabRouter, and TabRouter.handle(tabDeeplink:) performs the tab switch AND the in-tab
// navigation in one call. So we register exactly once; attaching it to every tab would let
// all 3 .task(id:) instances fire concurrently for the same identifier and double-apply it.
struct PendingTabRouterDeeplinkConsumer: ViewModifier {
  @Environment(\.tabRouter) private var tabRouter
  @Environment(PendingDeeplinkStore.self) private var pendingDeeplink

  func body(content: Content) -> some View {
    content
      .task(id: pendingDeeplink.identifier) {
        guard case let .tabRouter(target) = pendingDeeplink.identifier else { return }
        guard let tabDeeplink = try? await TabRouterDeeplinkHandler().deeplink(from: target) else {
          pendingDeeplink.identifier = nil
          return
        }
        tabRouter?.handle(tabDeeplink: tabDeeplink)
        pendingDeeplink.identifier = nil
      }
  }
}
