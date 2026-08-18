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
  @State var model: ChoiceScreenModel
  @Environment(PendingDeeplinkStore.self) private var pendingDeeplink
  @Environment(TabSelectionStore.self) private var tabSelection

  var body: some View {
    content
      .routerContext(ChoiceReset.self) { _ in model.example = nil }
      .onOpenURL { url in
        guard let identifier = model.handleOpenURL(url) else { return }
        if case let .tabView(target) = identifier {
          tabSelection.tab = target.tab
        }
        pendingDeeplink.identifier = identifier
      }
  }

  @ViewBuilder private var content: some View {
    switch model.example {
    case .none: choiceView
    case .navigationStack: navigationStack
    case .tabView: TabScreen(type: .tabView)
    case .routingTabView: TabScreen(type: .routingTabView)
    case .splitView: SplitScreen()
    }
  }

  private var choiceView: some View {
    VStack {
      Button("Navigation Stack") { model.example = .navigationStack }
      Button("TabView") { model.example = .tabView }
      Button("RoutingTabView") { model.example = .routingTabView }
      Button("SplitView") { model.example = .splitView }
    }
  }

  private var navigationStack: some View {
    RoutingView(destination: AppRoute.self, root: .home(name: "John")) {
      HomeScreen(model: HomeScreenModel(name: "John"))
        .modifier(PendingDeeplinkConsumer())
    }
  }
}

@Observable @MainActor
final class ChoiceScreenModel {
  var example: Example?

  init() {}

  // Select whichever paradigm this identifier targets, then hand the identifier back to
  // the view so it can pass it to PendingDeeplinkConsumer once that paradigm's real
  // Router has mounted.
  func handleOpenURL(_ url: URL) -> AppDeeplinkID? {
    guard let identifier = try? appDeeplinkRouter.match(url: url) else {
      print("Deeplink: no match for", url)
      return nil
    }
    switch identifier {
    case .navigationStack:
      example = .navigationStack
    case .tabView:
      example = .tabView
    }
    return identifier
  }
}
