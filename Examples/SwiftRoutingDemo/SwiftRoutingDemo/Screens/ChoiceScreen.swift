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
  @Environment(\.router) private var router
  @Environment(PendingDeeplinkStore.self) private var pendingDeeplink
  @Environment(TabSelectionStore.self) private var tabSelection
  // The selected example is persisted per window, so a relaunch comes back on the same example
  // (the navigation inside it is restored by `.navigationRestoration()` on the root).
  @SceneStorage("SwiftRoutingDemo.example") private var example: Example?

  var body: some View {
    content
      .safeAreaInset(edge: .bottom) {
        Button("Reset saved state", role: .destructive, action: resetRestoration)
          .buttonStyle(.bordered)
          .padding(.bottom, 4)
      }
      .routerContext(ChoiceReset.self) { _ in example = nil }
      .onOpenURL { url in
        guard let identifier = model.handleOpenURL(url) else { return }
        example = Example(identifier)
        if case let .tabView(target) = identifier {
          tabSelection.tab = target.tab
        }
        pendingDeeplink.identifier = identifier
      }
  }

  // Erases the saved navigation, then unmounts the example so nothing re-saves it when the app
  // goes to the background: the next launch starts on the choice screen.
  private func resetRestoration() {
    router.clearNavigationRestoration()
    example = nil
  }

  @ViewBuilder private var content: some View {
    switch example {
    case .none: choiceView
    case .navigationStack: navigationStack
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

  private var navigationStack: some View {
    RoutingView(destination: AppRoute.self, root: .home(name: "John")) {
      HomeScreen(model: HomeScreenModel(name: "John"))
        .modifier(PendingNavigationStackDeeplinkConsumer())
    }
  }
}

@Observable @MainActor
final class ChoiceScreenModel {
  init() {}

  // Match the URL, then hand the identifier back to the view so it can select the paradigm
  // (`Example(identifier)`) and pass it to PendingNavigationStackDeeplinkConsumer once that paradigm's real
  // Router has mounted.
  func handleOpenURL(_ url: URL) -> AppDeeplinkID? {
    guard let identifier = try? appDeeplinkRouter.match(url: url) else {
      print("Deeplink: no match for", url)
      return nil
    }
    return identifier
  }
}

extension Example {
  init(_ identifier: AppDeeplinkID) {
    switch identifier {
    case .navigationStack: self = .navigationStack
    case .tabView: self = .tabView
    case .tabRouter: self = .routingTabView
    case .splitView: self = .splitView
    }
  }
}
