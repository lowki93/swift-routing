//
//  AppTabDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting

struct AppTabDeeplinkHandler: TabDeeplinkHandler {
  typealias R = AppDeeplinkID
  typealias T = HomeTab
  typealias D = AppRoute

  func deeplink(from route: AppDeeplinkID) async throws -> TabDeeplink<HomeTab, AppRoute>? {
    switch route {
    case .navigationStack, .tabView:
      // Handled by AppDeeplinkHandler for their own paradigms; not a tab deeplink.
      nil
    case let .tabRouter(target):
      switch target {
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
}
