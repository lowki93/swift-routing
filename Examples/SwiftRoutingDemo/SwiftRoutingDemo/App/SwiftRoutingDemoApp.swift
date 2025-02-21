//
//  SwiftRoutingDemoApp.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftRouting
import SwiftUI

@main
struct SwiftRoutingDemoApp: App {
  var body: some Scene {
    WindowGroup {
      RoutingNavigationStack(stack: "Home", destination: AppRoute.self, root: .home)
    }
  }
}
