//
//  TabRouterDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import URLRouting

// Mirrors TabViewDeeplinkID's shape but stays its own type: RoutingTabView resolves the
// target tab through AppTabDeeplinkHandler + TabRouter.handle(tabDeeplink:), so -- unlike
// TabViewDeeplinkID -- this type needs no `.tab` extension. Reuses UserDeeplinkID/
// NotificationsDeeplinkID/ProfileDeeplinkID as-is.
enum TabRouterDeeplinkID: Hashable {
  case user(UserDeeplinkID)
  case notifications(NotificationsDeeplinkID)
  case profile(ProfileDeeplinkID)
}

let tabRouterDeeplinkRouter = OneOf {
  Route(TabRouterDeeplinkID.user) {
    userDeeplinkRouter
  }
  Route(TabRouterDeeplinkID.notifications) {
    notificationsDeeplinkRouter
  }
  Route(TabRouterDeeplinkID.profile) {
    profileDeeplinkRouter
  }
}
