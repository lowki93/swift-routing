//
//  TabRoute.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 07/03/2025.
//

import SwiftRouting

enum HomeTab: TabRoute {
  case home
  case notifications
  case profile

  var name: String {
    switch self {
    case .home: "home"
    case .notifications: "notifications"
    case .profile: "profile"
    }
  }

  // Deliberately not uniform: home hides the tab bar on push, the other two don't.
  var hideTabBarOnPush: Bool {
    switch self {
    case .home: true
    case .notifications, .profile: false
    }
  }
}
