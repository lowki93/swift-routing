//
//  ChoiceScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kévin Budain on 3/16/25.
//

import SwiftRouting
import SwiftUI
import URLRouting

struct ChoiceScreen: View {
  @State private var example: Example?
  @Environment(PendingDeeplinkStore.self) private var pendingDeeplink

  var body: some View {
    content
      .routerContext(ChoiceReset.self) { _ in example = nil }
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

  @ViewBuilder private var content: some View {
    switch example {
    case .none: choiceView
    case .navigationStack:
      RoutingView(destination: AppRoute.self, root: .home(name: "John")) {
        HomeScreen(model: HomeScreenModel(name: "John"))
          .modifier(PendingDeeplinkConsumer())
      }
    case .tabView: TabScreen(type: .tabView)
    case .routingTabView: TabScreen(type: .routingTabView)
    case .splitView: SplitScreen()
    }
  }

  private var choiceView: some View {
    VStack {
      Button("Navigation Stack") { example = .navigationStack }
      Button("TabView") { example = .tabView }
      Button("RoutingTabView") { example = .routingTabView }
      Button("SplitView") { example = .splitView }
    }
  }
}
