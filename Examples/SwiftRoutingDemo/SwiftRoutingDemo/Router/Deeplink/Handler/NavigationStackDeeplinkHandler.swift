//
//  NavigationStackDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import SwiftRouting

// Delegates to the per-identifier handlers (UserDeeplinkHandler/NotificationsDeeplinkHandler/
// ProfileDeeplinkHandler) instead of rebuilding their AppRoute-construction logic here --
// DeeplinkHandlers compose the same way TabDeeplinkHandler's own doc example does.
struct NavigationStackDeeplinkHandler: DeeplinkHandler {
  typealias R = NavigationStackDeeplinkID
  typealias D = AppRoute

  private let userHandler = UserDeeplinkHandler()
  private let notificationsHandler = NotificationsDeeplinkHandler()
  private let profileHandler = ProfileDeeplinkHandler()

  func deeplink(from route: NavigationStackDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    switch route {
    case let .user(userID):
      try await userHandler.deeplink(from: userID)
    case let .notifications(notification):
      try await notificationsHandler.deeplink(from: notification)
    case let .profile(profileID):
      try await profileHandler.deeplink(from: profileID)
    }
  }
}
