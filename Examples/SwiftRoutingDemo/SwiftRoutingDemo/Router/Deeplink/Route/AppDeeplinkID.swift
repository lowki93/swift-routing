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
  case tabView(TabViewDeeplinkID)
  case tabRouter(TabRouterDeeplinkID)
}

enum NavigationStackDeeplinkID: Hashable {
  case user(UserDeeplinkID)
  case notifications(NotificationsDeeplinkID)
  case profile(ProfileDeeplinkID)
}

let appDeeplinkRouter = OneOf {
  Route(AppDeeplinkID.navigationStack) {
    Host("navigationStack")
    OneOf {
      Route(NavigationStackDeeplinkID.user) {
        userDeeplinkRouter
      }
      Route(NavigationStackDeeplinkID.notifications) {
        notificationsDeeplinkRouter
      }
      Route(NavigationStackDeeplinkID.profile) {
        profileDeeplinkRouter
      }
    }
  }
  Route(AppDeeplinkID.tabView) {
    Host("tabView")
    tabViewDeeplinkRouter
  }
  Route(AppDeeplinkID.tabRouter) {
    Host("tabRouter")
    tabRouterDeeplinkRouter
  }
}
