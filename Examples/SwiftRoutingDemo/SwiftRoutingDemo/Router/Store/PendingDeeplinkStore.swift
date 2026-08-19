//
//  PendingDeeplinkStore.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 17/08/2026.
//

import Observation

// Holds a deeplink identifier from `.onOpenURL` until the paradigm it targets has actually
// mounted and published its real Router -- see PendingNavigationStackDeeplinkConsumer,
// PendingTabDeeplinkConsumer, and PendingTabRouterDeeplinkConsumer.
@Observable @MainActor
final class PendingDeeplinkStore {
  var identifier: AppDeeplinkID?
}
