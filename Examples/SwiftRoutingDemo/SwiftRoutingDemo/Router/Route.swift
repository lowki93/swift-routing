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
  case user(name: String)
  case settings

  var name: String {
    switch self {
    case .home:
      "Home"
    case let .user(name):
      "User - \(name)"
    case .settings:
      "Settings"
    }
  }
}

struct AppDestination: RouteDestination {
  func view(for route: AppRoute) -> some View {
    switch route {
    case .home:
      HomeScreen()
    case let .user(name):
      UserScreen(name: name)
    case .settings:
      SettingsScreen()
    }
  }
}
