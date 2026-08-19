//
//  TabRouterDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting

// Nests DeeplinkHandlers inside a TabDeeplinkHandler, same as TabDeeplinkHandler's own doc
// comment example: UserDeeplinkHandler/NotificationsDeeplinkHandler produce the DeeplinkRoute
// half of each TabDeeplink, this type only adds the `tab` half.
struct TabRouterDeeplinkHandler: TabDeeplinkHandler {
  typealias R = TabRouterDeeplinkID
  typealias T = HomeTab
  typealias D = AppRoute

  private let userHandler = UserDeeplinkHandler()
  private let notificationsHandler = NotificationsDeeplinkHandler()

  func deeplink(from route: TabRouterDeeplinkID) async throws -> TabDeeplink<HomeTab, AppRoute>? {
    switch route {
    case let .user(userID):
      TabDeeplink(tab: .home, deeplink: try await userHandler.deeplink(from: userID))
    case let .notifications(notification):
      switch notification {
      case .list:
        // Selecting the Notifications tab already puts the list on screen.
        TabDeeplink(tab: .notifications, deeplink: nil)
      case .detail:
        TabDeeplink(tab: .notifications, deeplink: try await notificationsHandler.deeplink(from: notification))
      }
    case .profile:
      // Selecting the Profile tab already puts it on screen.
      TabDeeplink(tab: .profile, deeplink: nil)
    }
  }
}
