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
  @State private var tabSelection = TabSelectionStore()

  var body: some Scene {
    WindowGroup {
      ChoiceScreen(model: ChoiceScreenModel())
        .printRouterOnChange()
        .environment(\.router, Router(configuration: Configuration(shouldCrashOnRouteNotFound: true)))
        .environment(pendingDeeplink)
        .environment(tabSelection)
    }
  }
}
