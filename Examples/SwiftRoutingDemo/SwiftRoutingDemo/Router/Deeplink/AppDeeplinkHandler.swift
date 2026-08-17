//
//  AppDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import SwiftRouting

struct AppDeeplinkHandler: DeeplinkHandler {
  typealias R = AppDeeplinkID
  typealias D = AppRoute

  func deeplink(from route: AppDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case let .navigationStack(target):
      switch target {
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
      }
    }
  }
}
