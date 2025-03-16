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

  var name: String {
    switch self {
    case .home: "home"
    case .notifications: "notifications"
    }
  }
}
