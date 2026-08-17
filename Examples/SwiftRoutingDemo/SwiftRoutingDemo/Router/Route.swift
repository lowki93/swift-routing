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
  case notifications(NotificationsRoute)
  case profile
  case user(name: String)
  case search
  case settings
  case about
  case sidebar
  case players(PlayersRoute)
  case form(FormRoute)

  var name: String {
    switch self {
    case let .home(name):  "Home(\(name))"
    case let .notifications(child): "Notifications.\(child.name)"
    case .profile: "Profile"
    case let .user(name): "User(\(name))"
    case .search: "Search"
    case .settings: "Settings"
    case .about: "About"
    case .sidebar: "Sidebar"
    case let .players(child): "Players.\(child.name)"
    case let .form(child): "Form.\(child.name)"
    }
  }
}

// Demonstrates the "Nested Routes and Nested Destinations" pattern from DefiningRoutes.md:
// a subflow modeled as its own Route enum, exposed through a single case of the parent
// route, rendered via a dedicated destination view (see PlayersRouteDestination below).
enum PlayersRoute: Route {
  case list(PlayerType)
  case detail(Player)

  var name: String {
    switch self {
    case let .list(type): "Players(\(type))"
    case let .detail(player): "Player(\(player.name))"
    }
  }
}

enum FormRoute: Route {
  case flow // FormFlowScreen, the coordinator
  case entry // FormScreen, the form itself

  var name: String {
    switch self {
    case .flow: "FormFlow"
    case .entry: "Form"
    }
  }
}

enum NotificationsRoute: Route {
  case list
  case detail(id: Int)

  var name: String {
    switch self {
    case .list: "Notifications"
    case let .detail(id): "Notification(\(id))"
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
    case let .notifications(child): NotificationsRouteDestination(route: child)
    case .profile: ProfileScreen(router: router, viewModel: ProfileViewModel(tabRouter: tabRouter))
    case let .user(name): UserScreen(model: UserScreenModel(name: name, router: router))
    case .search: Text("Search")
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
    case .settings: SettingsScreen(model: SettingsScreenModel())
    case .about: AboutScreen()
    case .sidebar: SidebarScreen()
    case let .players(child): PlayersRouteDestination(route: child)
    case let .form(child): FormRouteDestination(route: child)
    }
  }
}

struct PlayersRouteDestination: View {
  let route: PlayersRoute

  var body: some View {
    switch route {
    case let .list(type): PlayersScreen(type: type)
    case let .detail(player): PlayerScreen(player: player)
    }
  }
}

struct FormRouteDestination: View {
  let route: FormRoute

  var body: some View {
    switch route {
    case .flow: FormFlowScreen(model: FormFlowScreenModel())
    case .entry: FormScreen()
    }
  }
}

struct NotificationsRouteDestination: View {
  let route: NotificationsRoute

  var body: some View {
    switch route {
    case .list: NotificationsScreen()
    case .detail: NotificationScreen()
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
