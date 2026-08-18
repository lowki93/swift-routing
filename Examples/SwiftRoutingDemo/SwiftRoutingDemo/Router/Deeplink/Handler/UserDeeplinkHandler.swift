//
//  UserDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting

struct UserDeeplinkHandler: DeeplinkHandler {
  typealias R = UserDeeplinkID
  typealias D = AppRoute

  func deeplink(from route: UserDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case let .user(name):
      .push(AppRoute.user(name: name))
    }
  }
}
