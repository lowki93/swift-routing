//
//  TabScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 07/03/2025.
//

import SwiftRouting
import SwiftUI

struct TabScreen: View {
  enum TabType {
    case tabView
    case routingTabView
  }
  
  @Environment(\.router) private var router
  @State private var tab: HomeTab = .home
  var type: TabType


  var body: some View {
    switch type {
    case .tabView: tabView
    case .routingTabView: routingTabView
    }
  }

  private var routingTabView: some View {
    RoutingTabView(tab: $tab, destination: AppRoute.self) { destination in
      tab(.home, destination: destination, root: .home(name: "John"))
      tab(.notifications, destination: destination, root: .notifications)
    }
  }

  private var tabView: some View {
    TabView(selection: .tabToRoot(for: $tab, in: router)) {
      tab(.home, destination: AppRoute.self, root: .home(name: "John"))
      tab(.notifications, destination: AppRoute.self, root: .notifications)
    }
  }

  private func tab(_ tab: HomeTab, destination: AppRoute.Type, root: AppRoute) -> some View {
    RoutingView(tab: tab, destination: destination, root: root)
      .tabItem { Text(tab.name) }
      .tag(tab)
  }
}
