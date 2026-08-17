//
//  AppDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import URLRouting

// Mirrors AppRoute's own shape -- one case per paradigm.
enum AppDeeplinkID: Hashable {
  case navigationStack(NavigationStackDeeplinkID)
}

enum NavigationStackDeeplinkID: Hashable {
  case user(name: String)
  case notifications(NotificationsDeeplinkID)
}

let appDeeplinkRouter = OneOf {
  Route(.case(AppDeeplinkID.navigationStack)) {
    Host("navigationStack")
    OneOf {
      Route(.case(NavigationStackDeeplinkID.user)) {
        Path {
          "user"
          Rest().map(.string)
        }
      }
      Route(.case(NavigationStackDeeplinkID.notifications)) {
        Path { "notifications" }
        notificationsDeeplinkRouter
      }
    }
  }
}
