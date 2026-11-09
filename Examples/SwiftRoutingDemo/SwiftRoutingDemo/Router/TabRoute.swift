//
//  TabRoute.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 07/03/2025.
//

import SwiftRoutingMacros

// Deliberately not uniform: home hides the tab bar on push, the other two don't.
@TabRoutable
enum HomeTab {
  @HideTabBarOnPush
  case home
  case notifications
  case profile
}
