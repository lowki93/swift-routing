//
//  ProfileDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting

struct ProfileDeeplinkHandler: DeeplinkHandler {
  typealias R = ProfileDeeplinkID
  typealias D = AppRoute

  func deeplink(from route: ProfileDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case .profile:
      .present(AppRoute.profile)
    }
  }
}
