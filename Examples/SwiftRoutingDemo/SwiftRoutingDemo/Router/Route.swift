//
//  Route.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI
import SwiftRouting

enum PlayerType: String {
  case footballer
  case basketballPlayer
}

enum AppRoute: Route {
  case home(name: String)
  case notifications
  case user(name: String)
  case search
  case settings
  case sidebar
  case players(PlayerType)

  var name: String {
    switch self {
    case let .home(name):  "Home(\(name))"
    case .notifications: "Notificatons"
    case let .user(name): "User(\(name))"
    case .search: "Search"
    case .settings: "Settings"
    case .sidebar: "Sidebar"
    case let .players(type): "Players(\(type))"
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
    case .sidebar: SidebarView()
    case let players(type): PlayersView(type: type)
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
