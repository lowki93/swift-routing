//
//  AppDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import URLRouting

// Mirrors AppRoute's own shape -- one case per paradigm, reusing AppRoute's nested Route
// types directly (e.g. NotificationsRoute) instead of duplicating parallel identifier types.
enum AppDeeplinkID: Hashable {
  case navigationStack(NavigationStackDeeplinkID)
}

enum NavigationStackDeeplinkID: Hashable {
  case user(name: String)
  case notifications(NotificationsRoute)
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
        OneOf {
          Route(.case(NotificationsRoute.list))
          Route(.case(NotificationsRoute.detail)) {
            Path { Digits() }
          }
        }
      }
    }
  }
}
