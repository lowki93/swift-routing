//
//  AppDeeplinkID.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import URLRouting

enum AppDeeplinkID: Equatable {
  case home
}

let appDeeplinkRouter = OneOf {
  Route(.case(AppDeeplinkID.home)) {
    Host("home")
  }
}
