//
//  PendingDeeplinkConsumer.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 17/08/2026.
//

import SwiftRouting
import SwiftUI

// Applied to the root content of whichever paradigm the deeplink targets. `@Environment(\.router)`
// here resolves to that paradigm's real Router (not the WindowGroup-level placeholder), because
// this modifier is attached to content rendered *inside* RoutingView's own environment scope.
struct PendingDeeplinkConsumer: ViewModifier {
  @Environment(\.router) private var router
  @Environment(PendingDeeplinkStore.self) private var pendingDeeplink

  func body(content: Content) -> some View {
    content
      .task(id: pendingDeeplink.identifier) {
        guard case let .navigationStack(target) = pendingDeeplink.identifier else { return }
        guard let deeplink = try? await NavigationStackDeeplinkHandler().deeplink(from: target) else { return }
        router.handle(deeplink: deeplink)
        pendingDeeplink.identifier = nil
      }
  }
}
