//
//  TabViewDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import SwiftRouting
import URLRouting

// Mirrors NavigationStackDeeplinkID's shape but stays its own type: the two paradigms may
// need different semantics later (here, .notifications/.profile imply a tab switch rather
// than a push). Reuses UserDeeplinkID/NotificationsDeeplinkID/ProfileDeeplinkID as-is.
enum TabViewDeeplinkID: Hashable {
  case user(UserDeeplinkID)
  case notifications(NotificationsDeeplinkID)
  case profile(ProfileDeeplinkID)
}

extension TabViewDeeplinkID {
  var tab: HomeTab {
    switch self {
    case .user: .home
    case .notifications: .notifications
    case .profile: .profile
    }
  }
}

let tabViewDeeplinkRouter = OneOf {
  Route(TabViewDeeplinkID.user) {
    userDeeplinkRouter
  }
  Route(TabViewDeeplinkID.notifications) {
    notificationsDeeplinkRouter
  }
  Route(TabViewDeeplinkID.profile) {
    profileDeeplinkRouter
  }
}
