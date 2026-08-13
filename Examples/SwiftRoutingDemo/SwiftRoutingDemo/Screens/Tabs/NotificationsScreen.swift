//
//  NotificationsScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 09/03/2025.
//

import SwiftRouting
import SwiftUI

struct NotificationsScreen: View {

  @Environment(\.router) private var router
  @Environment(\.tabRouter) private var tabRouter

  var body: some View {
    VStack {
      Button("Notification detail") { router.push(AppRoute.notification(id: 1)) }
      if let tabRouter {
        Button("To home tab") { tabRouter.change(tab: HomeTab.home) }
        Button("To home tab + update Root") { tabRouter.update(root: AppRoute.home(name: "Joseph"), in: HomeTab.home) }
        Button("To home tab + push user") { tabRouter.push(AppRoute.user(name: "Joseph"), in: HomeTab.home) }
        // .profile has never been rendered at this point (home is the default tab) --
        // this exercises the "push into an unvisited tab" case covered in the
        // Troubleshooting article (onAppear ordering).
        Button("To profile tab + push user") { tabRouter.push(AppRoute.user(name: "Zoe"), in: HomeTab.profile) }
      }
    }
    .navigationTitle("Notifications")
  }
}
