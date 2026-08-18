//
//  NavigationStackDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import SwiftRouting

struct NavigationStackDeeplinkHandler: DeeplinkHandler {
  typealias R = NavigationStackDeeplinkID
  typealias D = AppRoute

  func deeplink(from route: NavigationStackDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case let .user(userID):
      switch userID {
      case let .user(name):
        .push(AppRoute.user(name: name))
      }
    case let .notifications(notification):
      switch notification {
      case .list:
        .push(AppRoute.notifications(.list))
      case let .detail(id):
        .push(AppRoute.notifications(.detail(id: id)))
      }
    case let .profile(profileID):
      switch profileID {
      case .profile:
        .present(AppRoute.profile)
      }
    }
  }
}
