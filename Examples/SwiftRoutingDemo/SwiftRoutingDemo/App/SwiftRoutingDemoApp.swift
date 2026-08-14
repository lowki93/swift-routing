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
  var body: some Scene {
    WindowGroup {
      ChoiceScreen()
        .printRouterOnChange()
        .environment(\.router, Router(configuration: Configuration(shouldCrashOnRouteNotFound: true)))
        .onOpenURL { url in
          print("Deeplink: received", url)
          guard let identifier = try? appDeeplinkRouter.match(url: url) else {
            print("Deeplink: no match for", url)
            return
          }
          Task {
            let deeplink = try? await AppDeeplinkHandler().deeplink(from: identifier)
            print("Deeplink:", identifier, "->", deeplink as Any)
          }
        }
    }
  }
}
