//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  var body: some View {
    RoutingSplitView(destination: AppRoute.self, root: .home(name: "John")) {
      SplitSidebarView()
    }
  }
}

private struct SplitSidebarView: View {

  @Environment(\.router) private var router
  @Environment(\.splitRouter) private var splitRouter

  var body: some View {
    List {
      Section("Navigation") {
        Button("Home: John") { router.push(AppRoute.home(name: "John")) }
        Button("Home: Alexia") { router.push(AppRoute.home(name: "Alexia")) }
        Button("Notifications") { router.push(AppRoute.notifications) }
      }

      Section("Split-level") {
        Button("Settings (sheet)") { splitRouter?.present(AppRoute.settings) }
        Button("Search (cover)") { splitRouter?.cover(AppRoute.settings) }
      }
    }
    .navigationTitle("Sidebar")
  }
}
