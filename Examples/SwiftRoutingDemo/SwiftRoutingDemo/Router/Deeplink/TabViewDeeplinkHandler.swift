//
//  TabViewDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import SwiftRouting

struct TabViewDeeplinkHandler: DeeplinkHandler {
  typealias R = TabViewDeeplinkID
  typealias D = AppRoute

  func deeplink(from route: TabViewDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case let .user(userID):
      switch userID {
      case let .user(name):
        .push(AppRoute.user(name: name))
      }
    case let .notifications(notification):
      switch notification {
      case .list:
        // Selecting the Notifications tab already puts this on screen.
        nil
      case let .detail(id):
        .push(AppRoute.notifications(.detail(id: id)))
      }
    case .profile:
      // Selecting the Profile tab already puts this on screen.
      nil
    }
  }
}
