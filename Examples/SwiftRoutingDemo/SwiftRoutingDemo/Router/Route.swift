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
  case notification(id: Int)
  case profile
  case user(name: String)
  case search
  case settings
  case about
  case sidebar
  case players(PlayerType)
  case player(Player)
  case formFlow
  case form

  var name: String {
    switch self {
    case let .home(name):  "Home(\(name))"
    case .notifications: "Notificatons"
    case let .notification(id): "Notification(\(id))"
    case .profile: "Profile"
    case let .user(name): "User(\(name))"
    case .search: "Search"
    case .settings: "Settings"
    case .about: "About"
    case .sidebar: "Sidebar"
    case let .players(type): "Players(\(type))"
    case let .player(player): "Player(\(player.name))"
    case .formFlow: "FormFlow"
    case .form: "Form"
    }
  }
}

extension AppRoute: RouteDestination {
  static func view(for route: AppRoute) -> some View {
    AppRouteDestination(route: route)
  }
}

// Only `.profile` and `.user` need environment-driven dependency injection (RouterModel/
// TabRouterModel into a ViewModel -- see UserScreenModel/ProfileViewModel), so this single
// wrapper resolves `@Environment` once for the whole route enum, per the "Using Environment
// Values In RouteDestination" pattern from the swift-routing skill. Everything else just
// passes through unchanged.
struct AppRouteDestination: View {
  @Environment(\.router) private var router
  @Environment(\.tabRouter) private var tabRouter
  let route: AppRoute

  var body: some View {
    switch route {
    case let .home(name): HomeScreen(model: HomeScreenModel(name: name))
    case .notifications: NotificationsScreen()
    case .notification: NotificationScreen()
    case .profile: ProfileScreen(router: router, viewModel: ProfileViewModel(tabRouter: tabRouter))
    case let .user(name): UserScreen(model: UserScreenModel(name: name, router: router))
    case .search: Text("Search")
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
    case .settings: SettingsScreen(model: SettingsScreenModel())
    case .about: AboutScreen()
    case .sidebar: SidebarScreen()
    case let .players(type): PlayersScreen(type: type)
    case let .player(player): PlayerScreen(player: player)
    case .formFlow: FormFlowScreen(model: FormFlowScreenModel())
    case .form: FormScreen()
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
