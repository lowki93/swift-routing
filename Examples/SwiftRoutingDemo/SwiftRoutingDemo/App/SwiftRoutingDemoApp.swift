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
  @State private var pendingDeeplink = PendingDeeplinkStore()

  var body: some Scene {
    WindowGroup {
      ChoiceScreen()
        .printRouterOnChange()
        .environment(\.router, Router(configuration: Configuration(shouldCrashOnRouteNotFound: true)))
        .environment(pendingDeeplink)
    }
  }
}
