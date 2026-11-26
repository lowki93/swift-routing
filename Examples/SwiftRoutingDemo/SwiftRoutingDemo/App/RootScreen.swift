//
//  RootScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

/// The content of one window. It owns that window's root `Router` (so two windows never share
/// one) and the per-window deeplink and tab stores.
///
/// `.navigationRestoration()` is applied before `.environment(\.router, ...)`: the modifier reads
/// the root router from the environment, so the environment must be injected outside of it.
struct RootScreen: View {
  @StateObject private var router = Router(configuration: Configuration(shouldCrashOnRouteNotFound: true))
  @State private var pendingDeeplink = PendingDeeplinkStore()
  @State private var tabSelection = TabSelectionStore()

  var body: some View {
    ChoiceScreen(model: ChoiceScreenModel())
      .printRouterOnChange()
      .navigationRestoration()
      .environment(\.router, router)
      .environment(pendingDeeplink)
      .environment(tabSelection)
  }
}
