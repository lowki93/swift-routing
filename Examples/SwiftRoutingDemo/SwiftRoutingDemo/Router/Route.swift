//
//  Route.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI
import SwiftRouting

enum AppRoute: Route {
  case home
  case notifications
  case user(name: String)
  case settings
  case notifications

  var name: String {
    switch self {
    case .home:  "Home"
    case .notifications: "Notificatons"
    case let .user(name): "User(\(name))"
    case .settings: "Settings"
    }
  }
}

extension AppRoute: RouteDestination {
  static func view(for route: AppRoute) -> some View {
    switch route {
    case .home: HomeScreen()
    case .notifications: NotificationsScreen()
    case let .user(name): UserScreen(name: name)
    case .settings: SettingsScreen()
    }
  }
}
