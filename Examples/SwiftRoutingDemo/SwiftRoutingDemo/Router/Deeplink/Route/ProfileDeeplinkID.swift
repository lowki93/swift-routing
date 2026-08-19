//
//  ProfileDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import URLRouting

// Same composable-per-feature pattern as UserDeeplinkID/NotificationsDeeplinkID.
enum ProfileDeeplinkID: Hashable {
  case profile
}

let profileDeeplinkRouter = OneOf {
  Route(ProfileDeeplinkID.profile) {
    Path { "profile" }
  }
}
