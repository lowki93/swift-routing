//
//  NotificationsDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import URLRouting

// Deliberately its own type rather than reusing NotificationsRoute directly: the deeplink
// identifier's shape is a URL-facing concern, the Route's shape is an internal navigation
// concern -- keeping them separate means one can change without forcing the other, even
// though they happen to match today. AppDeeplinkHandler maps between the two explicitly.
enum NotificationsDeeplinkID: Hashable {
  case list
  case detail(id: Int)
}

let notificationsDeeplinkRouter = OneOf {
  Route(.case(NotificationsDeeplinkID.list)) {
    Path { "notifications" }
  }
  Route(.case(NotificationsDeeplinkID.detail)) {
    Path {
      "notifications"
      Digits()
    }
  }
}
