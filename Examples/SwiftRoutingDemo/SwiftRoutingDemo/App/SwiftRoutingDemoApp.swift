//
//  SwiftRoutingDemoApp.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftRouting
import SwiftUI
import URLRouting

@main
struct SwiftRoutingDemoApp: App {
  @AppStorage("example") private var example: Example?
  @State private var pendingDeeplink = PendingDeeplinkStore()

  var body: some Scene {
    WindowGroup {
      ChoiceScreen()
        .printRouterOnChange()
        .environment(\.router, Router(configuration: Configuration(shouldCrashOnRouteNotFound: true)))
        .environment(pendingDeeplink)
        .onOpenURL { url in
          guard let identifier = try? appDeeplinkRouter.match(url: url) else {
            print("Deeplink: no match for", url)
            return
          }
          // Select whichever paradigm this identifier targets, then hand it off to
          // PendingDeeplinkConsumer once that paradigm's real Router has mounted.
          switch identifier {
          case .navigationStack:
            example = .navigationStack
          }
          pendingDeeplink.identifier = identifier
        }
    }
  }
}
