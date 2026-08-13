//
//  NotificationsScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 09/03/2025.
//

import SwiftRouting
import SwiftUI

struct NotificationsScreen: View {

  @Environment(\.tabRouter) private var tabRouter

  var body: some View {
    VStack {
      if let tabRouter {
        Button("To home tab") { tabRouter.change(tab: HomeTab.home) }
        Button("To home tab + update Root") { tabRouter.update(root: AppRoute.home(name: "Joseph"), in: HomeTab.home) }
        Button("To home tab + push user") { tabRouter.push(AppRoute.user(name: "Joseph"), in: HomeTab.home) }
      }
    }
    .navigationTitle("Notifications")
  }
}
