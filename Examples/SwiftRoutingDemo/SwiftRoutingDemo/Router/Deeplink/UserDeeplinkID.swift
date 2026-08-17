//
//  UserDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import URLRouting

// Its own type/router, composable the same way as NotificationsDeeplinkID -- reused as-is
// once the other paradigms (tabView, tabRouter, splitView) also need to deep link to a user.
enum UserDeeplinkID: Hashable {
  case user(name: String)
}

let userDeeplinkRouter = OneOf {
  Route(.case(UserDeeplinkID.user)) {
    Path {
      "user"
      Rest().map(.string)
    }
  }
}
