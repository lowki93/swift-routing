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
}

extension AppRoute: RouteDestination {
  var view: some View {
    switch self {
    case .home:
      HomeScreen()
    case let .user(name):
      UserScreen(name: name)
    case .settings:
      SettingsScreen()
    }
  }
}
