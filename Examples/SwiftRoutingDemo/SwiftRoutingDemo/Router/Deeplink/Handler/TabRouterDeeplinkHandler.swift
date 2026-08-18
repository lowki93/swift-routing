//
//  TabRouterDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting

struct TabRouterDeeplinkHandler: TabDeeplinkHandler {
  typealias R = TabRouterDeeplinkID
  typealias T = HomeTab
  typealias D = AppRoute

  func deeplink(from route: TabRouterDeeplinkID) async throws -> TabDeeplink<HomeTab, AppRoute>? {
    switch route {
    case let .user(userID):
      switch userID {
      case let .user(name):
        TabDeeplink(tab: .home, deeplink: .push(AppRoute.user(name: name)))
      }
    case let .notifications(notification):
      switch notification {
      case .list:
        // Selecting the Notifications tab already puts the list on screen.
        TabDeeplink(tab: .notifications, deeplink: nil)
      case let .detail(id):
        TabDeeplink(tab: .notifications, deeplink: .push(AppRoute.notifications(.detail(id: id))))
      }
    case .profile:
      // Selecting the Profile tab already puts it on screen.
      TabDeeplink(tab: .profile, deeplink: nil)
    }
  }
}
