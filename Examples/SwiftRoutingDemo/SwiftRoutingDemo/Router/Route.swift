//
//  Route.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI
import SwiftRouting

enum AppRoute: Route {
  case home(name: String)
  case notifications
  case user(name: String)
  case search
  case settings

  var name: String {
    switch self {
    case let .home(name):  "Home(\(name))"
    case .notifications: "Notificatons"
    case let .user(name): "User(\(name))"
    case .search: "search"
    case .settings: "Settings"
    }
  }
}

extension AppRoute: RouteDestination {
  static func view(for route: AppRoute) -> some View {
    switch route {
    case let .home(name): HomeScreen(model: HomeScreenModel(name: name))
    case .notifications: NotificationsScreen()
    case let .user(name): UserScreen(model: UserScreenModel(name: name))
    case .search: Text("Search")
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
    case .settings: SettingsScreen(model: SettingsScreenModel())
    }
  }
}

enum FailedRoute: Route {
  case failed

  var name: String {
    switch self {
    case .failed: "failed"
    }
  }
}

struct Success: RouteContext {
  let value: Int
}
