//
//  Route.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI
import SwiftRoutingMacros

@Routable(nameStyle: .capitalized)
enum AppRoute {
  @RouteName(#"Home(\(name))"#)
  case home(name: String)
  @RouteName(.delegate)
  case notifications(NotificationsRoute)
  case profile
  @RouteName(#"User(\(name))"#)
  case user(name: String)
  case search
  case settings
  case about
  case sidebar
  @RouteName(.delegate)
  case players(PlayersRoute)
  @RouteName(.delegate)
  case form(FormRoute)
}

// Demonstrates the "Nested Routes and Nested Destinations" pattern from DefiningRoutes.md:
// a subflow modeled as its own Route enum, exposed through a single case of the parent
// route, rendered via a dedicated destination view (see PlayersRouteDestination below).
@Routable
enum PlayersRoute {
  @RouteName(#"Players(\(arg0))"#)
  case list(PlayerType)
  @RouteName(#"Player(\(arg0.name))"#)
  case detail(Player)
}

@Routable
enum FormRoute {
  @RouteName(#"FormFlow"#)
  case flow // FormFlowScreen, the coordinator
  @RouteName(#"Form"#)
  case entry // FormScreen, the form itself
}

@Routable
enum NotificationsRoute {
  @RouteName(#"Notifications"#)
  case list
  @RouteName(#"Notification(\(id))"#)
  case detail(id: Int)
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

@Routable
enum FailedRoute {
  case failed
}
