//
//  ProfileScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 07/03/2025.
//

import SwiftRouting
import SwiftUI

struct ProfileScreen: View {

  @Environment(\.router) private var router
  @Environment(\.tabRouter) private var tabRouter
  @State private var reselectionCount = 0

  var body: some View {
    VStack {
      // .profile's hideTabBarOnPush is false, so the tab bar stays visible on push.
      Button("Push user") { router.push(AppRoute.user(name: "Me")) }

      if let tabRouter {
        // TabRouterModel is only resolvable from within `body`, so the ViewModel is built
        // here from the already-resolved environment value -- see ProfileViewModel for the
        // TabRouterModel-injection-for-testability pattern documented in Testing.md.
        let viewModel = ProfileViewModel(tabRouter: tabRouter)

        Button("Present search (current tab)") { viewModel.presentSearch() }
        Button("Cover about (current tab)") { viewModel.coverAbout() }
        Button("Present search in notifications tab") { viewModel.presentSearchInNotifications() }
        // popToRoot(in:) does NOT call change(tab:) -- unlike push/present/cover/update,
        // this resets the home tab's stack without switching you to it.
        Button("Reset home tab (stays on profile)") { viewModel.resetHomeTab() }
      }

      Text("Reselected \(reselectionCount) time(s)")
    }
    .navigationTitle("Profile")
    .onTabReselected(HomeTab.profile) {
      reselectionCount += 1
    }
  }
}

// Demonstrates injecting `any TabRouterModel` into a ViewModel (Testing.md "Strategy 2"),
// so navigation can be unit-tested with TabRouterSpy instead of exercising real UI.
@MainActor
final class ProfileViewModel {
  private let tabRouter: any TabRouterModel

  init(tabRouter: any TabRouterModel) {
    self.tabRouter = tabRouter
  }

  func presentSearch() {
    tabRouter.present(AppRoute.search)
  }

  func coverAbout() {
    tabRouter.cover(AppRoute.about)
  }

  func presentSearchInNotifications() {
    tabRouter.present(AppRoute.search, in: HomeTab.notifications)
  }

  func resetHomeTab() {
    tabRouter.popToRoot(in: HomeTab.home)
  }
}
