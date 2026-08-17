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
  case user(UserDeeplinkID)
  case notifications(NotificationsDeeplinkID)
  case profile(ProfileDeeplinkID)
}

let appDeeplinkRouter = OneOf {
  Route(.case(AppDeeplinkID.navigationStack)) {
    Host("navigationStack")
    OneOf {
      Route(.case(NavigationStackDeeplinkID.user)) {
        userDeeplinkRouter
      }
      Route(.case(NavigationStackDeeplinkID.notifications)) {
        notificationsDeeplinkRouter
      }
      Route(.case(NavigationStackDeeplinkID.profile)) {
        profileDeeplinkRouter
      }
    }
  }
}
