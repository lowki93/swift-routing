//
//  TabViewDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import SwiftRouting

// Delegates to UserDeeplinkHandler/NotificationsDeeplinkHandler for the cases that push the
// same route NavigationStackDeeplinkHandler does. `.notifications(.list)` and `.profile` stay
// local: selecting the tab already puts them on screen, so there's nothing to delegate to
// ProfileDeeplinkHandler for -- its `.present` behavior only makes sense for NavigationStack.
struct TabViewDeeplinkHandler: DeeplinkHandler {
  typealias R = TabViewDeeplinkID
  typealias D = AppRoute

  private let userHandler = UserDeeplinkHandler()
  private let notificationsHandler = NotificationsDeeplinkHandler()

  func deeplink(from route: TabViewDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case let .user(userID):
      try await userHandler.deeplink(from: userID)
    case let .notifications(notification):
      switch notification {
      case .list:
        // Selecting the Notifications tab already puts this on screen.
        nil
      case .detail:
        try await notificationsHandler.deeplink(from: notification)
      }
    case .profile:
      // Selecting the Profile tab already puts this on screen.
      nil
    }
  }
}
