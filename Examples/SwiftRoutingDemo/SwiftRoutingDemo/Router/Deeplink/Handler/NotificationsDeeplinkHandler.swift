//
//  NotificationsDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting

struct NotificationsDeeplinkHandler: DeeplinkHandler {
  typealias R = NotificationsDeeplinkID
  typealias D = AppRoute

  func deeplink(from route: NotificationsDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case .list:
      .push(AppRoute.notifications(.list))
    case let .detail(id):
      .push(AppRoute.notifications(.detail(id: id)))
    }
  }
}
