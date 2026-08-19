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
  @Environment(TabSelectionStore.self) private var tabSelection
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
        .modifier(PendingTabRouterDeeplinkConsumer())
      tab(.notifications, destination: destination, root: .notifications(.list))
      tab(.profile, destination: destination, root: .profile)
    }
  }

  private var tabViewSelection: Binding<HomeTab> {
    Binding(
      get: { tabSelection.tab },
      set: { tabSelection.tab = $0 }
    )
  }

  private var tabView: some View {
    TabView(selection: .tabToRoot(for: tabViewSelection, in: router)) {
      tabViewTab(.home, root: .home(name: "John"))
      tabViewTab(.notifications, root: .notifications(.list))
      tabViewTab(.profile, root: .profile)
    }
  }

  private func tab(_ tab: HomeTab, destination: AppRoute.Type, root: AppRoute) -> some View {
    RoutingView(tab: tab, destination: destination, root: root)
      .tabItem { Text(tab.name) }
      .tag(tab)
  }

  // Unlike `tab(_:destination:root:)` above, this uses the custom-content overload so
  // PendingTabDeeplinkConsumer sits inside RoutingView's own environment scope and sees
  // the real, tab-scoped Router -- required since TabView (no TabRouter) keeps all 3 tabs
  // mounted simultaneously, each needing to independently react to deep links meant for it.
  private func tabViewTab(_ tab: HomeTab, root: AppRoute) -> some View {
    RoutingView(tab: tab, destination: AppRoute.self, root: root) {
      AppRouteDestination(route: root)
        .modifier(PendingTabDeeplinkConsumer(tab: tab))
    }
    .tabItem { Text(tab.name) }
    .tag(tab)
  }
}
